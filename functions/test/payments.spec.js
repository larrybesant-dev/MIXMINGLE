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
    __state: {
      users,
      transactions,
      logs,
      stripeConnectAccounts,
      refundRequests,
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
    const stripeClient = {
      paymentIntents: {
        create: async (payload) => {
          capturedPayload = payload;
          return {client_secret: "pi_secret_123"};
        },
      },
    };

    const response = await createPaymentIntentHandler(
        makeRequest({amount: 12.34, currency: "USD", recipientId: "user-2"}),
        {stripeClient},
    );

    assert.deepEqual(response, {clientSecret: "pi_secret_123"});
    assert.equal(capturedPayload.amount, 1234);
    assert.equal(capturedPayload.currency, "usd");
    assert.equal(capturedPayload.metadata.senderId, "user-1");
    assert.equal(capturedPayload.metadata.recipientId, "user-2");
  });

  it("recordStripePaymentSuccessHandler records a completed transaction", async () => {
    const firestore = createFirestoreDouble();

    const response = await recordStripePaymentSuccessHandler(
        makeRequest({recipientId: "user-2", amount: 7}),
        {firestore},
    );

    const recorded = firestore.__state.transactions.get(response.transactionId);
    assert.equal(recorded.senderId, "user-1");
    assert.equal(recorded.receiverId, "user-2");
    assert.deepEqual(recorded.participants, ["user-1", "user-2"]);
    assert.equal(recorded.amount, 7);
    assert.equal(recorded.status, "completed");
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

    await cleanupDeletedUserData("user-1", {firestore});

    assert.equal(firestore.__state.users.has("user-1"), false);
    assert.equal(firestore.__state.stripeConnectAccounts.has("user-1"), false);
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
});