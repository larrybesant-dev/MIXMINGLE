const assert = require("node:assert/strict");
const {describe, it} = require("node:test");

const {sendIncomingCallPushHandler} = require("../index").__testing;

// ── Firestore double ─────────────────────────────────────────────────────────

function createFirestore({users = {}, rooms = {}, tokens = {}} = {}) {
  // tokens: { [userId]: string[] }  — list of FCM token strings
  const usersMap = new Map(Object.entries(users));
  const roomsMap = new Map(Object.entries(rooms));
  const deletedTokens = [];

  function makeSubcollection(tokenList) {
    // tokenList items are stored with the token string as the doc ID
    // (matching how registerFcmTokenHandler stores them).
    const itemMap = new Map(tokenList.map((t) => [t, {token: t}]));

    return {
      doc(tokenId) {
        return {
          async delete() {
            deletedTokens.push(tokenId);
          },
        };
      },
      limit(n) {
        return {
          async get() {
            const docs = [...itemMap.entries()].slice(0, n).map(([k, v]) => ({
              data: () => ({token: v.token}),
              ref: {
                async delete() {
                  deletedTokens.push(k);
                },
              },
            }));
            return {docs, empty: docs.length === 0};
          },
        };
      },
    };
  }

  const fs = {
    collection(name) {
      return {
        doc(id) {
          if (name === "users") {
            const data = usersMap.get(id);
            return {
              async get() {
                return {
                  exists: data !== undefined,
                  data: () => (data ? {...data} : undefined),
                };
              },
              collection(subName) {
                if (subName === "notification_tokens") {
                  return makeSubcollection(tokens[id] || []);
                }
                throw new Error(`Unsupported subcollection ${subName}`);
              },
            };
          }
          if (name === "rooms") {
            const data = roomsMap.get(id);
            return {
              async get() {
                return {
                  exists: data !== undefined,
                  data: () => (data ? {...data} : undefined),
                };
              },
            };
          }
          throw new Error(`Unsupported collection ${name}`);
        },
      };
    },
    batch() {
      const ops = [];
      return {
        delete(ref) {
          ops.push(() => ref.delete());
          return this;
        },
        async commit() {
          for (const op of ops) await op();
        },
      };
    },
    __deletedTokens: deletedTokens,
  };

  return fs;
}

// ── Messaging double ─────────────────────────────────────────────────────────

function createMessaging(failTokens = []) {
  let lastPayload = null;
  const messaging = {
    async sendEachForMulticast(payload) {
      lastPayload = JSON.parse(JSON.stringify(payload));
      const responses = payload.tokens.map((t) => {
        if (failTokens.includes(t)) {
          return {
            success: false,
            error: {code: "messaging/registration-token-not-registered"},
          };
        }
        return {success: true};
      });
      return {responses};
    },
    getLastPayload() {
      return lastPayload;
    },
  };
  return messaging;
}

// ── Event double ─────────────────────────────────────────────────────────────

function makeEvent(roomId, data) {
  return {
    params: {roomId},
    data: data
      ? {
          data() {
            return {...data};
          },
        }
      : null,
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("sendIncomingCallPushHandler", () => {
  it("sends push to callee when isDirectCall is true", async () => {
    const firestore = createFirestore({
      users: {
        "caller-1": {displayName: "Alice"},
        "callee-2": {},
      },
      tokens: {"callee-2": ["token-abc"]},
    });
    const messaging = createMessaging();

    await sendIncomingCallPushHandler(
      makeEvent("room-1", {
        isDirectCall: true,
        ownerId: "caller-1",
        calleeId: "callee-2",
        isLive: true,
      }),
      {firestore, messaging},
    );

    const payload = messaging.getLastPayload();
    assert.ok(payload !== null, "expected push to be sent");
    assert.equal(payload.notification.title, "Incoming video call");
    assert.ok(payload.notification.body.includes("Alice"));
    assert.deepEqual(payload.tokens, ["token-abc"]);
    assert.equal(payload.data.type, "incoming_call");
    assert.equal(payload.data.roomId, "room-1");
    assert.equal(payload.data.callerId, "caller-1");
  });

  it("falls back to 'Someone' when caller has no displayName", async () => {
    const firestore = createFirestore({
      users: {"caller-1": {username: "AliceHandle"}, "callee-2": {}},
      tokens: {"callee-2": ["token-xyz"]},
    });
    const messaging = createMessaging();

    await sendIncomingCallPushHandler(
      makeEvent("room-1", {
        isDirectCall: true,
        ownerId: "caller-1",
        calleeId: "callee-2",
      }),
      {firestore, messaging},
    );

    const payload = messaging.getLastPayload();
    assert.ok(payload.notification.body.includes("AliceHandle"));
  });

  it("does nothing when isDirectCall is false", async () => {
    const firestore = createFirestore({
      users: {"caller-1": {displayName: "Bob"}, "callee-2": {}},
      tokens: {"callee-2": ["token-abc"]},
    });
    const messaging = createMessaging();

    await sendIncomingCallPushHandler(
      makeEvent("room-1", {
        isDirectCall: false,
        ownerId: "caller-1",
        calleeId: "callee-2",
      }),
      {firestore, messaging},
    );

    assert.equal(messaging.getLastPayload(), null, "push must not be sent");
  });

  it("does nothing when event.data is null", async () => {
    const firestore = createFirestore();
    const messaging = createMessaging();

    await sendIncomingCallPushHandler(makeEvent("room-1", null), {
      firestore,
      messaging,
    });

    assert.equal(messaging.getLastPayload(), null);
  });

  it("does nothing when callee has no FCM tokens", async () => {
    const firestore = createFirestore({
      users: {"caller-1": {displayName: "Charlie"}, "callee-2": {}},
      tokens: {},
    });
    const messaging = createMessaging();

    await sendIncomingCallPushHandler(
      makeEvent("room-1", {
        isDirectCall: true,
        ownerId: "caller-1",
        calleeId: "callee-2",
      }),
      {firestore, messaging},
    );

    assert.equal(messaging.getLastPayload(), null, "no push without tokens");
  });

  it("cleans up stale tokens reported by FCM", async () => {
    const firestore = createFirestore({
      users: {"caller-1": {displayName: "Dana"}, "callee-2": {}},
      tokens: {"callee-2": ["good-token", "stale-token"]},
    });
    const messaging = createMessaging(["stale-token"]);

    await sendIncomingCallPushHandler(
      makeEvent("room-1", {
        isDirectCall: true,
        ownerId: "caller-1",
        calleeId: "callee-2",
      }),
      {firestore, messaging},
    );

    assert.ok(
      firestore.__deletedTokens.includes("stale-token"),
      "stale token should be deleted",
    );
    assert.ok(
      !firestore.__deletedTokens.includes("good-token"),
      "good token must not be deleted",
    );
  });
});
