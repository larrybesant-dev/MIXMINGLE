const assert = require("node:assert/strict");
const {describe, it} = require("node:test");

const paymentFunctions = require("../index");

const {
  createPaymentIntentHandler,
  recordStripePaymentSuccessHandler,
  sendCoinTransferHandler,
  requestCoinTransferHandler,
  getStripeConnectStatusHandler,
  createStripeConnectOnboardingLinkHandler,
  createStripeConnectDashboardLinkHandler,
  generateAgoraTokenHandler,
  sendRoomGiftHandler,
  requestRefundHandler,
  cleanupDeletedUserData,
  createCheckoutSessionHandler,
  getCheckoutBaseUrl,
} = paymentFunctions.__testing;

function makeRequest(data, authUid = "user-1") {
  return {
    data,
    auth: authUid ? {uid: authUid} : null,
  };
}

function createFirestoreDouble(initialUsers = {}) {
  let idCounter = 0;
  const users = new Map(
      Object.entries(initialUsers).map(([id, value]) => [id, {...value}]),
  );
  const transactions = new Map();
  const logs = new Map();
  const stripeConnectAccounts = new Map();
  const refundRequests = new Map();
  const rooms = new Map();
  // Shared subcollection storage: "col/id/sub" → Map<subId, data>
  const subcollections = new Map();

  function storeFor(name) {
    switch (name) {
      case "users":
        return users;
      case "transactions":
        return transactions;
      case "logs":
        return logs;
      case "stripe_connect_accounts":
        return stripeConnectAccounts;
      case "refund_requests":
        return refundRequests;
      case "rooms":
        return rooms;
      default:
        throw new Error(`Unsupported collection ${name}`);
    }
  }

  function createDocRef(name, id) {
    const store = storeFor(name);
    return {
      id,
      async get() {
        const data = store.get(id);
        return {
          exists: data !== undefined,
          data: () => (data === undefined ? undefined : {...data}),
        };
      },
      async set(data, options = {}) {
        const previous = store.get(id) || {};
        store.set(id, options.merge ? {...previous, ...data} : {...data});
      },
      async update(data) {
        const previous = store.get(id);
        if (previous === undefined) {
          throw new Error(`Missing document ${name}/${id}`);
        }
        store.set(id, {...previous, ...data});
      },
      async delete() {
        store.delete(id);
      },
      collection(subName) {
        const subKey = `${name}/${id}/${subName}`;
        if (!subcollections.has(subKey)) {
          subcollections.set(subKey, new Map()); // shared across all doc() calls
        }
        const subStore = subcollections.get(subKey);
        return {
          doc(subId) {
            const resolvedId = subId || `${subName}-${++idCounter}`;
            return {
              id: resolvedId,
              async get() {
                const d = subStore.get(resolvedId);
                return {exists: d !== undefined, data: () => d && {...d}};
              },
              async set(data, opts = {}) {
                const prev = subStore.get(resolvedId) || {};
                subStore.set(resolvedId, opts.merge ? {...prev, ...data} : {...data});
              },
              async delete() { subStore.delete(resolvedId); },
            };
          },
          limit(n) {
            // Return a query-like object; .get() returns first n docs.
            return {
              async get() {
                const docs = [...subStore.entries()].slice(0, n).map(([k, v]) => ({
                  id: k,
                  ref: {async delete() { subStore.delete(k); }},
                  data: () => ({...v}),
                }));
                return {empty: docs.length === 0, docs, size: docs.length};
              },
            };
          },
          // Support chaining: .limit(n).get() by returning the snapshot directly
          async get() {
            const docs = [...subStore.entries()].map(([k, v]) => ({
              id: k,
              ref: {async delete() { subStore.delete(k); }},
              data: () => ({...v}),
            }));
            return {empty: docs.length === 0, docs, size: docs.length};
          },
          __subStore: subStore,
        };
      },
    };
  }

  const firestore = {
    collection(name) {
      return {
        doc(id) {
          return createDocRef(name, id || `${name}-${++idCounter}`);
        },
        async add(data) {
          const ref = createDocRef(name, `${name}-${++idCounter}`);
          await ref.set(data);
          return ref;
        },
      };
    },
    async runTransaction(handler) {
      const operations = [];
      const transaction = {
        get: async (ref) => ref.get(),
        update: (ref, data) => operations.push(() => ref.update(data)),
        set: (ref, data) => operations.push(() => ref.set(data)),
      };
      const result = await handler(transaction);
      for (const operation of operations) {
        await operation();
      }
      return result;
    },
    batch() {
      const ops = [];
      return {
        delete(ref) { ops.push(() => ref.delete()); return this; },
        set(ref, data, opts) { ops.push(() => ref.set(data, opts)); return this; },
        update(ref, data) { ops.push(() => ref.update(data)); return this; },
        async commit() { for (const op of ops) await op(); },
      };
    },
    __state: {
      users,
      transactions,
      logs,
      stripeConnectAccounts,
      refundRequests,
      rooms,
      subcollections,
    },
  };

  return firestore;
}

function createResponseDouble() {
  return {
    statusCode: 200,
    jsonBody: null,
    textBody: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.jsonBody = body;
      return this;
    },
    send(body) {
      this.textBody = body;
      return this;
    },
  };
}

describe("payment callable handlers", () => {
  it("createPaymentIntentHandler rejects unauthenticated calls", async () => {
    await assert.rejects(
        () => createPaymentIntentHandler(makeRequest({}, null)),
        (error) => error.code === "unauthenticated",
    );
  });

  it("createPaymentIntentHandler validates payload and creates Stripe intent", async () => {
    let capturedPayload;
    let capturedOptions;
    const stripeClient = {
      paymentIntents: {
        create: async (payload, options) => {
          capturedPayload = payload;
          capturedOptions = options;
          return {client_secret: "pi_secret_123", id: "pi_123"};
        },
      },
    };

    const response = await createPaymentIntentHandler(
        makeRequest({
          amount: 12.34,
          currency: "USD",
          recipientId: "user-2",
          idempotencyKey: "idem-key-0001",
        }),
        {stripeClient},
    );

    assert.deepEqual(response, {
      clientSecret: "pi_secret_123",
      paymentIntentId: "pi_123",
      idempotencyKey: "idem-key-0001",
    });
    assert.equal(capturedPayload.amount, 1234);
    assert.equal(capturedPayload.currency, "usd");
    assert.equal(capturedPayload.metadata.senderId, "user-1");
    assert.equal(capturedPayload.metadata.recipientId, "user-2");
    assert.equal(capturedOptions.idempotencyKey, "idem-key-0001");
  });

  it("recordStripePaymentSuccessHandler records a completed transaction", async () => {
    const firestore = createFirestoreDouble();
    const stripeClient = {
      paymentIntents: {
        retrieve: async () => ({
          id: "pi_777",
          status: "succeeded",
          amount: 700,
          metadata: {
            senderId: "user-1",
            recipientId: "user-2",
            amount: "7",
          },
        }),
      },
    };

    const response = await recordStripePaymentSuccessHandler(
        makeRequest({
          recipientId: "user-2",
          amount: 7,
          paymentIntentId: "pi_777",
        }),
        {firestore, stripeClient, forceStripeVerification: true},
    );

    const recorded = firestore.__state.transactions.get(response.transactionId);
    assert.equal(recorded.senderId, "user-1");
    assert.equal(recorded.receiverId, "user-2");
    assert.deepEqual(recorded.participants, ["user-1", "user-2"]);
    assert.equal(recorded.amount, 7);
    assert.equal(recorded.status, "completed");
    assert.equal(recorded.paymentIntentId, "pi_777");
  });

  it("recordStripePaymentSuccessHandler rejects mismatched stripe metadata", async () => {
    const firestore = createFirestoreDouble();
    const stripeClient = {
      paymentIntents: {
        retrieve: async () => ({
          id: "pi_bad",
          status: "succeeded",
          amount: 500,
          metadata: {
            senderId: "other-user",
            recipientId: "user-2",
            amount: "5",
          },
        }),
      },
    };

    await assert.rejects(
        () => recordStripePaymentSuccessHandler(
            makeRequest({
              recipientId: "user-2",
              amount: 5,
              paymentIntentId: "pi_bad",
            }),
            {firestore, stripeClient, forceStripeVerification: true},
        ),
        (error) => error.code === "permission-denied",
    );
  });

  it("sendCoinTransferHandler rejects insufficient balance", async () => {
    const firestore = createFirestoreDouble({
      "user-1": {balance: 2},
      "user-2": {balance: 4},
    });

    await assert.rejects(
        () => sendCoinTransferHandler(
            makeRequest({receiverId: "user-2", amount: 5}),
            {firestore},
        ),
        (error) => error.code === "failed-precondition",
    );
  });

  it("sendCoinTransferHandler updates balances and records transaction", async () => {
    const firestore = createFirestoreDouble({
      "user-1": {balance: 20},
      "user-2": {balance: 3},
    });

    const response = await sendCoinTransferHandler(
        makeRequest({receiverId: "user-2", amount: 5}),
        {firestore},
    );

    assert.equal(firestore.__state.users.get("user-1").balance, 15);
    assert.equal(firestore.__state.users.get("user-2").balance, 8);
    assert.equal(
        firestore.__state.transactions.get(response.transactionId).status,
        "sent",
    );
    assert.deepEqual(
      firestore.__state.transactions.get(response.transactionId).participants,
      ["user-1", "user-2"],
    );
  });

  it("requestCoinTransferHandler rejects self-targeted requests", async () => {
    const firestore = createFirestoreDouble();

    await assert.rejects(
        () => requestCoinTransferHandler(
            makeRequest({targetId: "user-1", amount: 5}),
            {firestore},
        ),
        (error) => error.code === "invalid-argument",
    );
  });

  it("requestCoinTransferHandler records requested transaction", async () => {
    const firestore = createFirestoreDouble();

    const response = await requestCoinTransferHandler(
        makeRequest({targetId: "user-3", amount: 9}),
        {firestore},
    );

    const recorded = firestore.__state.transactions.get(response.transactionId);
    assert.equal(recorded.senderId, "user-1");
    assert.equal(recorded.receiverId, "user-3");
    assert.deepEqual(recorded.participants, ["user-1", "user-3"]);
    assert.equal(recorded.status, "requested");
  });

  it("getStripeConnectStatusHandler returns not-started status without an account", async () => {
    const firestore = createFirestoreDouble();
    const response = await getStripeConnectStatusHandler(makeRequest({}), {
      firestore,
      stripeClient: {
        accounts: {
          retrieve: async () => {
            throw new Error("should not retrieve");
          },
        },
      },
    });

    assert.equal(response.hasAccount, false);
    assert.equal(response.onboardingComplete, false);
  });

  it("createStripeConnectOnboardingLinkHandler creates account, stores status, and returns link", async () => {
    const firestore = createFirestoreDouble();
    let createdAccountPayload;
    let createdLinkPayload;
    const stripeClient = {
      accounts: {
        create: async (payload) => {
          createdAccountPayload = payload;
          return {
            id: "acct_123",
            charges_enabled: false,
            payouts_enabled: false,
            details_submitted: false,
            country: "US",
          };
        },
        retrieve: async () => {
          throw new Error("should not retrieve before create");
        },
        createLoginLink: async () => ({url: "https://stripe.test/dashboard"}),
      },
      accountLinks: {
        create: async (payload) => {
          createdLinkPayload = payload;
          return {url: "https://stripe.test/onboarding"};
        },
      },
    };

    const response = await createStripeConnectOnboardingLinkHandler(makeRequest({}), {
      firestore,
      stripeClient,
      publicAppUrl: "https://mixvy.app",
    });

    assert.equal(response.url, "https://stripe.test/onboarding");
    assert.equal(response.accountId, "acct_123");
    assert.equal(createdAccountPayload.type, "express");
    assert.equal(createdLinkPayload.account, "acct_123");
    assert.equal(createdLinkPayload.refresh_url, "https://mixvy.app/payments?connect=refresh");
    assert.equal(createdLinkPayload.return_url, "https://mixvy.app/payments?connect=return");
    assert.equal(
        firestore.__state.stripeConnectAccounts.get("user-1").accountId,
        "acct_123",
    );
  });

  it("createStripeConnectDashboardLinkHandler creates a dashboard login link", async () => {
    const firestore = createFirestoreDouble();
    firestore.__state.stripeConnectAccounts.set("user-1", {accountId: "acct_saved"});
    let retrievedAccountId;
    let loginLinkAccountId;
    const stripeClient = {
      accounts: {
        retrieve: async (accountId) => {
          retrievedAccountId = accountId;
          return {
            id: accountId,
            charges_enabled: true,
            payouts_enabled: true,
            details_submitted: true,
            country: "US",
          };
        },
        create: async () => {
          throw new Error("should not create new account");
        },
        createLoginLink: async (accountId) => {
          loginLinkAccountId = accountId;
          return {url: "https://stripe.test/dashboard"};
        },
      },
    };

    const response = await createStripeConnectDashboardLinkHandler(makeRequest({}), {
      firestore,
      stripeClient,
    });

    assert.equal(response.url, "https://stripe.test/dashboard");
    assert.equal(retrievedAccountId, "acct_saved");
    assert.equal(loginLinkAccountId, "acct_saved");
  });

  it("requestRefundHandler records a pending refund request", async () => {
    const firestore = createFirestoreDouble();
    firestore.__state.transactions.set("tx_1", {
      id: "tx_1",
      senderId: "user-1",
      receiverId: "user-2",
      participants: ["user-1", "user-2"],
      amount: 14,
      status: "completed",
      source: "stripe",
    });

    const response = await requestRefundHandler(
        makeRequest({transactionId: "tx_1", reason: "Duplicate charge on checkout."}),
        {firestore},
    );

    assert.equal(response.status, "pending");
    const refund = firestore.__state.refundRequests.get("tx_1_user-1");
    assert.equal(refund.requesterId, "user-1");
    assert.equal(refund.transactionId, "tx_1");
    assert.equal(refund.status, "pending");
  });

  it("requestRefundHandler rejects non-participants", async () => {
    const firestore = createFirestoreDouble();
    firestore.__state.transactions.set("tx_2", {
      id: "tx_2",
      senderId: "user-1",
      receiverId: "user-2",
      participants: ["user-1", "user-2"],
      amount: 10,
      status: "completed",
      source: "stripe",
    });

    await assert.rejects(
        () => requestRefundHandler(
            makeRequest({transactionId: "tx_2", reason: "Charge dispute reason here."}, "user-9"),
            {firestore},
        ),
        (error) => error.code === "permission-denied",
    );
  });

  it("cleanupDeletedUserData removes user profile and stripe connect docs", async () => {
    const firestore = createFirestoreDouble({
      "user-1": {balance: 100, displayName: "User One"},
    });
    firestore.__state.stripeConnectAccounts.set("user-1", {
      accountId: "acct_123",
      chargesEnabled: true,
    });

    // Seed a notification token to verify it gets cleaned up.
    const userDocRef = firestore.collection("users").doc("user-1");
    const tokenSubcol = userDocRef.collection("notification_tokens");
    await tokenSubcol.doc("tok_abc").set({token: "tok_abc", userId: "user-1"});
    assert.equal(tokenSubcol.__subStore.has("tok_abc"), true);

    await cleanupDeletedUserData("user-1", {firestore});

    assert.equal(firestore.__state.users.has("user-1"), false);
    assert.equal(firestore.__state.stripeConnectAccounts.has("user-1"), false);
    // Notification tokens must be deleted on account deletion (privacy / GDPR).
    assert.equal(tokenSubcol.__subStore.has("tok_abc"), false);
  });

  it("getCheckoutBaseUrl prefers CHECKOUT_BASE_URL and trims trailing slash", () => {
    const previousCheckoutBaseUrl = process.env.CHECKOUT_BASE_URL;
    const previousPublicAppUrl = process.env.PUBLIC_APP_URL;

    process.env.CHECKOUT_BASE_URL = "https://beta.mixvy.app/";
    process.env.PUBLIC_APP_URL = "https://fallback.mixvy.app";

    assert.equal(getCheckoutBaseUrl(), "https://beta.mixvy.app");

    if (previousCheckoutBaseUrl === undefined) {
      delete process.env.CHECKOUT_BASE_URL;
    } else {
      process.env.CHECKOUT_BASE_URL = previousCheckoutBaseUrl;
    }
    if (previousPublicAppUrl === undefined) {
      delete process.env.PUBLIC_APP_URL;
    } else {
      process.env.PUBLIC_APP_URL = previousPublicAppUrl;
    }
  });

  it("createCheckoutSessionHandler uses resolved success/cancel URLs", async () => {
    const previousCheckoutBaseUrl = process.env.CHECKOUT_BASE_URL;
    const previousPublicAppUrl = process.env.PUBLIC_APP_URL;
    process.env.CHECKOUT_BASE_URL = "https://beta.mixvy.app";
    delete process.env.PUBLIC_APP_URL;

    let capturedPayload;
    const stripeClient = {
      checkout: {
        sessions: {
          create: async (payload) => {
            capturedPayload = payload;
            return {url: "https://checkout.stripe.test/session_123"};
          },
        },
      },
    };

    const req = {body: {userId: "user-9"}};
    const res = createResponseDouble();

    await createCheckoutSessionHandler(req, res, {stripeClient});

    assert.equal(capturedPayload.success_url, "https://beta.mixvy.app/success");
    assert.equal(capturedPayload.cancel_url, "https://beta.mixvy.app/cancel");
    assert.deepEqual(res.jsonBody, {url: "https://checkout.stripe.test/session_123"});

    if (previousCheckoutBaseUrl === undefined) {
      delete process.env.CHECKOUT_BASE_URL;
    } else {
      process.env.CHECKOUT_BASE_URL = previousCheckoutBaseUrl;
    }
    if (previousPublicAppUrl === undefined) {
      delete process.env.PUBLIC_APP_URL;
    } else {
      process.env.PUBLIC_APP_URL = previousPublicAppUrl;
    }
  });

  // sendRoomGift ------------------------------------------------------------

  it("sendRoomGiftHandler rejects sender who is not a room participant", async () => {
    const firestore = createFirestoreDouble({
      "user-1": {balance: 100},
      "user-2": {balance: 0},
    });
    // Room exists and is live, but sender has no participant doc.
    await firestore.collection("rooms").doc("room-1").set({isLive: true});

    await assert.rejects(
      () => sendRoomGiftHandler(
        makeRequest({roomId: "room-1", receiverId: "user-2", giftId: "g1", coinCost: 10}, "user-1"),
        {firestore},
      ),
      (err) => err.code === "permission-denied",
    );
  });

  it("sendRoomGiftHandler rejects gift when room is not active", async () => {
    const firestore = createFirestoreDouble({
      "user-1": {balance: 100},
      "user-2": {balance: 0},
    });
    // Room doc exists but isLive=false.
    await firestore.collection("rooms").doc("room-1").set({isLive: false});
    await firestore.collection("rooms").doc("room-1")
      .collection("participants").doc("user-1")
      .set({userId: "user-1", role: "audience", isBanned: false});

    await assert.rejects(
      () => sendRoomGiftHandler(
        makeRequest({roomId: "room-1", receiverId: "user-2", giftId: "g1", coinCost: 10}, "user-1"),
        {firestore},
      ),
      (err) => err.code === "failed-precondition",
    );
  });

  it("sendRoomGiftHandler transfers coins and creates gift event for valid participant", async () => {
    const firestore = createFirestoreDouble({
      "user-1": {balance: 100},
      "user-2": {balance: 0},
    });
    await firestore.collection("rooms").doc("room-1").set({isLive: true});
    await firestore.collection("rooms").doc("room-1")
      .collection("participants").doc("user-1")
      .set({userId: "user-1", role: "audience", isBanned: false});

    const result = await sendRoomGiftHandler(
      makeRequest({roomId: "room-1", receiverId: "user-2", giftId: "g1", coinCost: 10}, "user-1"),
      {firestore},
    );

    assert.ok(typeof result.giftEventId === "string" && result.giftEventId.length > 0);
    const senderSnap = await firestore.collection("users").doc("user-1").get();
    assert.equal(senderSnap.data().balance, 90);
    const receiverSnap = await firestore.collection("users").doc("user-2").get();
    // Receiver gets coinCost * 0.85 = 8 (floored).
    assert.equal(receiverSnap.data().balance, 8);
  });

  it("sendRoomGiftHandler rejects banned participant", async () => {
    const firestore = createFirestoreDouble({
      "user-1": {balance: 100},
      "user-2": {balance: 0},
    });
    await firestore.collection("rooms").doc("room-1").set({isLive: true});
    await firestore.collection("rooms").doc("room-1")
      .collection("participants").doc("user-1")
      .set({userId: "user-1", role: "audience", isBanned: true});

    await assert.rejects(
      () => sendRoomGiftHandler(
        makeRequest({roomId: "room-1", receiverId: "user-2", giftId: "g1", coinCost: 10}, "user-1"),
        {firestore},
      ),
      (err) => err.code === "permission-denied",
    );
  });

  // generateAgoraToken -------------------------------------------------------

  it("generateAgoraTokenHandler rejects non-participants", async () => {
    const firestore = createFirestoreDouble();
    // No participant doc → should be rejected.
    const previousAppId = process.env.AGORA_APP_ID;
    const previousCert = process.env.AGORA_APP_CERTIFICATE;
    process.env.AGORA_APP_ID = "a".repeat(32);
    process.env.AGORA_APP_CERTIFICATE = "b".repeat(32);

    await assert.rejects(
      () => generateAgoraTokenHandler(
        makeRequest({channelName: "room-1", rtcUid: 42}, "user-1"),
        {firestore},
      ),
      (error) => error.code === "permission-denied",
    );

    // Restore env vars.
    if (previousAppId === undefined) delete process.env.AGORA_APP_ID;
    else process.env.AGORA_APP_ID = previousAppId;
    if (previousCert === undefined) delete process.env.AGORA_APP_CERTIFICATE;
    else process.env.AGORA_APP_CERTIFICATE = previousCert;
  });

  it("generateAgoraTokenHandler rejects banned participants", async () => {
    const firestore = createFirestoreDouble();
    // Write a banned participant doc.
    await firestore.collection("rooms").doc("room-1")
      .collection("participants").doc("user-1")
      .set({userId: "user-1", role: "audience", isBanned: true});

    const previousAppId = process.env.AGORA_APP_ID;
    const previousCert = process.env.AGORA_APP_CERTIFICATE;
    process.env.AGORA_APP_ID = "a".repeat(32);
    process.env.AGORA_APP_CERTIFICATE = "b".repeat(32);

    await assert.rejects(
      () => generateAgoraTokenHandler(
        makeRequest({channelName: "room-1", rtcUid: 42}, "user-1"),
        {firestore},
      ),
      (error) => error.code === "permission-denied",
    );

    if (previousAppId === undefined) delete process.env.AGORA_APP_ID;
    else process.env.AGORA_APP_ID = previousAppId;
    if (previousCert === undefined) delete process.env.AGORA_APP_CERTIFICATE;
    else process.env.AGORA_APP_CERTIFICATE = previousCert;
  });

  it("generateAgoraTokenHandler issues a token for a valid participant", async () => {
    const firestore = createFirestoreDouble();
    await firestore.collection("rooms").doc("room-1")
      .collection("participants").doc("user-1")
      .set({userId: "user-1", role: "audience", isBanned: false});

    const previousAppId = process.env.AGORA_APP_ID;
    const previousCert = process.env.AGORA_APP_CERTIFICATE;
    process.env.AGORA_APP_ID = "a".repeat(32);
    process.env.AGORA_APP_CERTIFICATE = "b".repeat(32);

    const result = await generateAgoraTokenHandler(
      makeRequest({channelName: "room-1", rtcUid: 42}, "user-1"),
      {firestore},
    );

    assert.equal(typeof result.token, "string");
    assert.ok(result.token.length > 0);
    assert.equal(result.issuedForUid, "user-1");

    if (previousAppId === undefined) delete process.env.AGORA_APP_ID;
    else process.env.AGORA_APP_ID = previousAppId;
    if (previousCert === undefined) delete process.env.AGORA_APP_CERTIFICATE;
    else process.env.AGORA_APP_CERTIFICATE = previousCert;
  });
});