const assert = require("node:assert/strict");
const {describe, it} = require("node:test");

const paymentFunctions = require("../index");

const {
  createPaymentIntentHandler,
  recordStripePaymentSuccessHandler,
  sendCoinTransferHandler,
  requestCoinTransferHandler,
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

  function storeFor(name) {
    switch (name) {
      case "users":
        return users;
      case "transactions":
        return transactions;
      case "logs":
        return logs;
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
    },
  };

  return firestore;
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
    assert.equal(recorded.status, "requested");
  });
});