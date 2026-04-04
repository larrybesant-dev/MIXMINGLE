const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onRequest: onRequestV1} = require("firebase-functions/v1/https");
const functionsV1 = require("firebase-functions/v1");
const admin = require("firebase-admin");
const Stripe = require("stripe");
const {RtcTokenBuilder, RtcRole} = require("agora-access-token");

admin.initializeApp();

const stripe = new Stripe(process.env.STRIPE_SECRET || "sk_test_dummy");
const db = admin.firestore();

const RATE_LIMITS = {
  createPaymentIntent: {windowMs: 60 * 1000, maxRequests: 12},
  recordStripePaymentSuccess: {windowMs: 60 * 1000, maxRequests: 20},
  sendCoinTransfer: {windowMs: 60 * 1000, maxRequests: 18},
  requestCoinTransfer: {windowMs: 60 * 1000, maxRequests: 18},
  sendRoomGift: {windowMs: 60 * 1000, maxRequests: 30},
  getStripeConnectStatus: {windowMs: 60 * 1000, maxRequests: 40},
  createStripeConnectOnboardingLink: {windowMs: 60 * 1000, maxRequests: 10},
  createStripeConnectDashboardLink: {windowMs: 60 * 1000, maxRequests: 20},
  generateAgoraToken: {windowMs: 60 * 1000, maxRequests: 30},
  requestRefund: {windowMs: 60 * 1000, maxRequests: 12},
};

const rateLimitState = new Map();

const HIGH_RISK_TERMS = [
  "scam",
  "fraud",
  "chargeback",
  "threat",
  "kill",
  "blackmail",
  "extort",
  "hate",
  "violent",
  "weapon",
  "underage",
  "exploit",
  "abuse",
];

const MEDIUM_RISK_TERMS = [
  "spam",
  "harass",
  "bully",
  "nsfw",
  "bot",
  "fake",
  "impersonat",
  "offensive",
  "slur",
];

function enforceRateLimit(functionName, uid) {
  const config = RATE_LIMITS[functionName];
  if (!config) {
    return;
  }

  const now = Date.now();
  const key = `${functionName}:${uid}`;
  const entry = rateLimitState.get(key);

  if (!entry || now - entry.windowStart >= config.windowMs) {
    rateLimitState.set(key, {windowStart: now, count: 1});
    return;
  }

  if (entry.count >= config.maxRequests) {
    throw new HttpsError(
      "resource-exhausted",
      "Too many requests. Please wait a moment and try again.",
    );
  }

  entry.count += 1;
}

function parseIdField(value, fieldName) {
  const normalized = typeof value === "string" ? value.trim() : "";
  if (!normalized) {
    throw new HttpsError("invalid-argument", `${fieldName} is required.`);
  }
  if (normalized.length > 128) {
    throw new HttpsError("invalid-argument", `${fieldName} is too long.`);
  }
  return normalized;
}

function classifyModerationText(reason = "", details = "") {
  const sourceText = `${reason} ${details}`.toLowerCase();
  const matchedHigh = HIGH_RISK_TERMS.filter((term) => sourceText.includes(term));
  const matchedMedium = MEDIUM_RISK_TERMS.filter((term) => sourceText.includes(term));

  const score = matchedHigh.length * 3 + matchedMedium.length;
  let riskLevel = "low";
  if (matchedHigh.length > 0 || score >= 5) {
    riskLevel = "high";
  } else if (matchedMedium.length > 0 || score >= 2) {
    riskLevel = "medium";
  }

  return {
    riskLevel,
    score,
    matchedTerms: [...new Set([...matchedHigh, ...matchedMedium])],
    needsManualReview: riskLevel !== "low",
  };
}

function buildModerationReviewPayload(reportData = {}) {
  const reason = typeof reportData.reason === "string" ? reportData.reason : "";
  const details = typeof reportData.details === "string" ? reportData.details : "";
  const classification = classifyModerationText(reason, details);

  return {
    moderationReview: {
      riskLevel: classification.riskLevel,
      score: classification.score,
      matchedTerms: classification.matchedTerms,
      needsManualReview: classification.needsManualReview,
      classifiedAt: new Date().toISOString(),
      classifierVersion: "v1-baseline",
    },
  };
}

function getCheckoutBaseUrl() {
  const baseUrl = process.env.CHECKOUT_BASE_URL ||
    process.env.PUBLIC_APP_URL ||
    "http://localhost:3000";
  return baseUrl.endsWith("/") ? baseUrl.slice(0, -1) : baseUrl;
}

function mapStripeConnectAccount(account) {
  const chargesEnabled = !!account.charges_enabled;
  const payoutsEnabled = !!account.payouts_enabled;
  const detailsSubmitted = !!account.details_submitted;

  return {
    accountId: account.id,
    chargesEnabled,
    payoutsEnabled,
    detailsSubmitted,
    onboardingComplete: chargesEnabled && payoutsEnabled && detailsSubmitted,
    country: account.country || "US",
  };
}

async function ensureStripeConnectAccount(uid, deps = {}) {
  const firestore = deps.firestore || db;
  const stripeClient = deps.stripeClient || stripe;
  const accountRef = firestore.collection("stripe_connect_accounts").doc(uid);
  const accountSnap = await accountRef.get();

  let accountId = accountSnap.exists ? accountSnap.data().accountId : null;
  let account;

  if (accountId) {
    account = await stripeClient.accounts.retrieve(accountId);
  } else {
    account = await stripeClient.accounts.create({
      type: "express",
      country: process.env.STRIPE_CONNECT_COUNTRY || "US",
      capabilities: {
        card_payments: {requested: true},
        transfers: {requested: true},
      },
      business_type: "individual",
      metadata: {
        firebaseUid: uid,
      },
    });
    accountId = account.id;
  }

  const mapped = mapStripeConnectAccount(account);
  const payload = {
    ...mapped,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (!accountSnap.exists) {
    payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
  }

  await accountRef.set(payload, {merge: true});

  return mapped;
}

async function createCheckoutSessionHandler(req, res, deps = {}) {
  const stripeClient = deps.stripeClient || stripe;

  try {
    const checkoutBaseUrl = getCheckoutBaseUrl();
    const userId = parseIdField(req.body && req.body.userId, "userId");
    const session = await stripeClient.checkout.sessions.create({
      payment_method_types: ["card"],
      mode: "payment",
      line_items: [
        {
          price_data: {
            currency: "usd",
            product_data: {name: "MixVy Coins"},
            unit_amount: 500,
          },
          quantity: 1,
        },
      ],
      metadata: {userId},
      success_url: `${checkoutBaseUrl}/success`,
      cancel_url: `${checkoutBaseUrl}/cancel`,
    });
    return res.json({url: session.url});
  } catch (error) {
    console.error(error);
    return res.status(500).send(error.message);
  }
}

async function createCheckoutSessionCallableHandler(request, deps = {}) {
  const uid = requireAuth(request);
  const stripeClient = deps.stripeClient || stripe;

  const checkoutBaseUrl = getCheckoutBaseUrl();
  const session = await stripeClient.checkout.sessions.create({
    payment_method_types: ["card"],
    mode: "payment",
    line_items: [
      {
        price_data: {
          currency: "usd",
          product_data: {name: "MixVy Coins"},
          unit_amount: 500,
        },
        quantity: 1,
      },
    ],
    metadata: {userId: uid},
    success_url: `${checkoutBaseUrl}/success`,
    cancel_url: `${checkoutBaseUrl}/cancel`,
  });

  return {url: session.url};
}

async function ensureUserExists(uid, firestore = db, defaultBalance = 100) {
  const userRef = firestore.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    await userRef.set({
      uid,
      balance: defaultBalance,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  return userRef;
}

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  const uid = request.auth.uid;
  if (typeof uid !== "string" || uid.trim().length === 0) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return uid.trim();
}

function parsePositiveAmount(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new HttpsError("invalid-argument", "Amount must be greater than zero.");
  }
  if (amount > 50000) {
    throw new HttpsError("invalid-argument", "Amount exceeds the maximum allowed value.");
  }
  return amount;
}

function parseOptionalIdempotencyKey(value) {
  if (value == null) {
    return null;
  }
  if (typeof value !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "idempotencyKey must be a string when provided.",
    );
  }
  const normalized = value.trim();
  if (!normalized) {
    return null;
  }
  if (!/^[a-zA-Z0-9_\-:.]{8,120}$/.test(normalized)) {
    throw new HttpsError(
      "invalid-argument",
      "idempotencyKey format is invalid.",
    );
  }
  return normalized;
}

function buildIdempotentTransactionDocId(prefix, uid, idempotencyKey) {
  const raw = `${prefix}_${uid}_${idempotencyKey}`;
  return raw.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 180);
}

async function createPaymentIntentHandler(request, deps = {}) {
  const senderId = requireAuth(request);
  enforceRateLimit("createPaymentIntent", senderId);
  const recipientId = parseIdField(
    request.data && request.data.recipientId,
    "recipientId",
  );
  const currency = request.data && request.data.currency;
  const amount = parsePositiveAmount(request.data && request.data.amount);
  const idempotencyKey = parseOptionalIdempotencyKey(
    request.data && request.data.idempotencyKey,
  );
  const stripeClient = deps.stripeClient || stripe;

  const normalizedCurrency = typeof currency === "string" ? currency.toLowerCase() : "usd";
  const paymentIntentRequest = {
    amount: Math.round(amount * 100),
    currency: normalizedCurrency,
    metadata: {
      senderId,
      recipientId,
      amount: amount.toString(),
      kind: "mixvy_coin_payment",
      idempotencyKey: idempotencyKey || "",
    },
    automatic_payment_methods: {
      enabled: true,
    },
  };
  const stripeRequestOptions = idempotencyKey ? {idempotencyKey} : undefined;
  const paymentIntent = await stripeClient.paymentIntents.create(
    paymentIntentRequest,
    stripeRequestOptions,
  );

  return {
    clientSecret: paymentIntent.client_secret,
    paymentIntentId: paymentIntent.id,
    idempotencyKey,
  };
}

exports.createPaymentIntent = onCall(async (request) =>
  createPaymentIntentHandler(request),
);

function shouldSkipStripePaymentVerification(deps = {}) {
  if (deps.forceStripeVerification === true) {
    return false;
  }

  if (deps.skipStripeVerification === true) {
    return true;
  }

  const configuredSecret = process.env.STRIPE_SECRET;
  return !configuredSecret || configuredSecret === "sk_test_dummy";
}

async function validateStripePaymentIntent({
  stripeClient,
  paymentIntentId,
  senderId,
  recipientId,
  amount,
}) {
  const paymentIntent = await stripeClient.paymentIntents.retrieve(paymentIntentId);
  if (!paymentIntent || !paymentIntent.id) {
    throw new HttpsError("failed-precondition", "Payment intent not found.");
  }

  const status = String(paymentIntent.status || "");
  if (
    status !== "succeeded" &&
    status !== "processing" &&
    status !== "requires_capture"
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Payment intent is not in a payable state.",
    );
  }

  const metadata = paymentIntent.metadata || {};
  const metadataSender = typeof metadata.senderId === "string" ? metadata.senderId : "";
  const metadataRecipient =
    typeof metadata.recipientId === "string" ? metadata.recipientId : "";
  const metadataAmount = Number(metadata.amount || 0);

  if (metadataSender !== senderId || metadataRecipient !== recipientId) {
    throw new HttpsError(
      "permission-denied",
      "Payment intent participants do not match authenticated request.",
    );
  }

  if (Math.abs(metadataAmount - amount) > 0.0001) {
    throw new HttpsError(
      "failed-precondition",
      "Payment amount does not match payment intent metadata.",
    );
  }

  const expectedAmountCents = Math.round(amount * 100);
  const intentAmountCents = Number(paymentIntent.amount || 0);
  if (intentAmountCents !== expectedAmountCents) {
    throw new HttpsError(
      "failed-precondition",
      "Payment amount does not match payment intent amount.",
    );
  }
}

async function recordStripePaymentSuccessHandler(request, deps = {}) {
  const senderId = requireAuth(request);
  enforceRateLimit("recordStripePaymentSuccess", senderId);
  const recipientId = parseIdField(
    request.data && request.data.recipientId,
    "recipientId",
  );
  const amount = parsePositiveAmount(request.data && request.data.amount);
  const paymentIntentId = parseIdField(
    request.data && request.data.paymentIntentId,
    "paymentIntentId",
  );
  const idempotencyKey = parseOptionalIdempotencyKey(
    request.data && request.data.idempotencyKey,
  );
  const firestore = deps.firestore || db;
  const stripeClient = deps.stripeClient || stripe;

  const transactionRef = idempotencyKey
    ? firestore.collection("transactions").doc(
      buildIdempotentTransactionDocId("stripe", senderId, idempotencyKey),
    )
    : firestore.collection("transactions").doc();

  const existingSnap = await transactionRef.get();
  if (existingSnap.exists) {
    return {transactionId: transactionRef.id, deduplicated: true};
  }

  if (!shouldSkipStripePaymentVerification(deps)) {
    await validateStripePaymentIntent({
      stripeClient,
      paymentIntentId,
      senderId,
      recipientId,
      amount,
    });
  }

  await transactionRef.set({
    id: transactionRef.id,
    senderId,
    receiverId: recipientId,
    participants: [senderId, recipientId],
    amount,
    timestamp: new Date().toISOString(),
    status: "completed",
    source: "stripe",
    paymentIntentId,
    idempotencyKey,
  });

  return {transactionId: transactionRef.id, deduplicated: false};
}

exports.recordStripePaymentSuccess = onCall(async (request) =>
  recordStripePaymentSuccessHandler(request),
);

async function sendCoinTransferHandler(request, deps = {}) {
  const senderId = requireAuth(request);
  enforceRateLimit("sendCoinTransfer", senderId);
  const receiverId = parseIdField(
    request.data && request.data.receiverId,
    "receiverId",
  );
  const amount = parsePositiveAmount(request.data && request.data.amount);
  const idempotencyKey = parseOptionalIdempotencyKey(
    request.data && request.data.idempotencyKey,
  );
  const firestore = deps.firestore || db;

  if (receiverId === senderId) {
    throw new HttpsError("invalid-argument", "Cannot send a payment to yourself.");
  }

  await ensureUserExists(senderId, firestore);
  await ensureUserExists(receiverId, firestore);

  const transactionRef = idempotencyKey
    ? firestore.collection("transactions").doc(
      buildIdempotentTransactionDocId("balance", senderId, idempotencyKey),
    )
    : firestore.collection("transactions").doc();

  const transactionId = await firestore.runTransaction(async (txn) => {
    const senderRef = firestore.collection("users").doc(senderId);
    const receiverRef = firestore.collection("users").doc(receiverId);

    const existingTransaction = await txn.get(transactionRef);
    if (existingTransaction.exists) {
      return transactionRef.id;
    }

    const [senderSnap, receiverSnap] = await Promise.all([
      txn.get(senderRef),
      txn.get(receiverRef),
    ]);

    const senderBalance = Number((senderSnap.data() && senderSnap.data().balance) || 0);
    const receiverBalance = Number((receiverSnap.data() && receiverSnap.data().balance) || 0);

    if (senderBalance < amount) {
      throw new HttpsError("failed-precondition", "Insufficient balance.");
    }

    txn.update(senderRef, {balance: senderBalance - amount});
    txn.update(receiverRef, {balance: receiverBalance + amount});
    txn.set(transactionRef, {
      id: transactionRef.id,
      senderId,
      receiverId,
      participants: [senderId, receiverId],
      amount,
      timestamp: new Date().toISOString(),
      status: "sent",
      source: "balance",
      idempotencyKey,
    });

    return transactionRef.id;
  });

  return {transactionId};
}

exports.sendCoinTransfer = onCall(async (request) => sendCoinTransferHandler(request));

async function requestCoinTransferHandler(request, deps = {}) {
  const requesterId = requireAuth(request);
  enforceRateLimit("requestCoinTransfer", requesterId);
  const targetId = parseIdField(
    request.data && request.data.targetId,
    "targetId",
  );
  const amount = parsePositiveAmount(request.data && request.data.amount);
  const idempotencyKey = parseOptionalIdempotencyKey(
    request.data && request.data.idempotencyKey,
  );
  const firestore = deps.firestore || db;

  if (targetId === requesterId) {
    throw new HttpsError("invalid-argument", "Cannot request a payment from yourself.");
  }

  const transactionRef = idempotencyKey
    ? firestore.collection("transactions").doc(
      buildIdempotentTransactionDocId("request", requesterId, idempotencyKey),
    )
    : firestore.collection("transactions").doc();

  const existingSnap = await transactionRef.get();
  if (existingSnap.exists) {
    return {transactionId: transactionRef.id, deduplicated: true};
  }

  await transactionRef.set({
    id: transactionRef.id,
    senderId: requesterId,
    receiverId: targetId,
    participants: [requesterId, targetId],
    amount,
    timestamp: new Date().toISOString(),
    status: "requested",
    source: "request",
    idempotencyKey,
  });

  return {transactionId: transactionRef.id, deduplicated: false};
}

async function registerFcmTokenHandler(request, deps = {}) {
  const uid = requireAuth(request);
  // FCM tokens can be 150-500+ characters; parseIdField's 128-char cap is too short.
  const rawToken = request.data && request.data.token;
  const token = typeof rawToken === "string" ? rawToken.trim() : "";
  if (!token) throw new HttpsError("invalid-argument", "token is required.");
  if (token.length > 4096) throw new HttpsError("invalid-argument", "token is too long.");
  const platform =
    typeof (request.data && request.data.platform) === "string"
      ? request.data.platform.trim().slice(0, 32)
      : "unknown";
  const firestore = deps.firestore || db;

  const tokenRef = firestore
    .collection("users")
    .doc(uid)
    .collection("notification_tokens")
    .doc(token);

  await tokenRef.set({
    token,
    userId: uid,
    platform,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {ok: true};
}

exports.registerFcmToken = onCall(async (request) =>
  registerFcmTokenHandler(request),
);

async function unregisterFcmTokenHandler(request, deps = {}) {
  const uid = requireAuth(request);
  const firestore = deps.firestore || db;
  const rawToken = request.data && request.data.token;
  const token = typeof rawToken === "string" ? rawToken.trim() : "";

  const tokensRef = firestore
    .collection("users")
    .doc(uid)
    .collection("notification_tokens");

  if (token) {
    await tokensRef.doc(token).delete();
    return {ok: true, deleted: 1};
  }

  const snapshot = await tokensRef.limit(200).get();
  if (snapshot.empty) {
    return {ok: true, deleted: 0};
  }

  const batch = firestore.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();
  return {ok: true, deleted: snapshot.size};
}

exports.unregisterFcmToken = onCall(async (request) =>
  unregisterFcmTokenHandler(request),
);

async function sendPushForNotification(event, deps = {}) {
  if (!event.data) {
    return;
  }

  const firestore = deps.firestore || db;
  const messaging = deps.messaging || admin.messaging();
  const notificationData = event.data.data() || {};
  const userId = typeof notificationData.userId === "string"
    ? notificationData.userId.trim()
    : "";
  if (!userId) {
    return;
  }

  const tokenSnapshot = await firestore
    .collection("users")
    .doc(userId)
    .collection("notification_tokens")
    .limit(200)
    .get();

  const tokens = tokenSnapshot.docs
    .map((doc) => (doc.data().token || "").trim())
    .filter((value) => value.length > 0);

  if (tokens.length === 0) {
    return;
  }

  const payload = {
    notification: {
      title: "MixVy",
      body: typeof notificationData.content === "string"
        ? notificationData.content.slice(0, 180)
        : "You have a new notification.",
    },
    data: {
      type: String(notificationData.type || "in_app"),
      notificationId: event.data.id,
      userId,
    },
    tokens,
  };

  const result = await messaging.sendEachForMulticast(payload);
  const invalidTokens = [];
  result.responses.forEach((response, index) => {
    if (response.success) {
      return;
    }
    const code = response.error && response.error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-argument"
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    const batch = firestore.batch();
    invalidTokens.forEach((token) => {
      const tokenRef = firestore
        .collection("users")
        .doc(userId)
        .collection("notification_tokens")
        .doc(token);
      batch.delete(tokenRef);
    });
    await batch.commit();
  }
}

exports.sendPushForNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => sendPushForNotification(event),
);

exports.requestCoinTransfer = onCall(async (request) =>
  requestCoinTransferHandler(request),
);

async function sendRoomGiftHandler(request, deps = {}) {
  const senderId = requireAuth(request);
  enforceRateLimit("sendRoomGift", senderId);
  const roomId = parseIdField(request.data && request.data.roomId, "roomId");
  const receiverId = parseIdField(
    request.data && request.data.receiverId,
    "receiverId",
  );
  const giftId = parseIdField(request.data && request.data.giftId, "giftId");
  const coinCost = parsePositiveAmount(request.data && request.data.coinCost);
  const senderName =
    typeof (request.data && request.data.senderName) === "string"
      ? request.data.senderName.trim().slice(0, 64)
      : "";
  const firestore = deps.firestore || db;

  if (receiverId === senderId) {
    throw new HttpsError(
      "invalid-argument",
      "Cannot send a gift to yourself.",
    );
  }

  const PLATFORM_FEE = 0.15;
  const receiverAmount = Math.max(1, Math.floor(coinCost * (1 - PLATFORM_FEE)));

  const giftEventId = await firestore.runTransaction(async (txn) => {
    const senderRef = firestore.collection("users").doc(senderId);
    const receiverRef = firestore.collection("users").doc(receiverId);
    const roomRef = firestore.collection("rooms").doc(roomId);
    const senderParticipantRef = roomRef
      .collection("participants")
      .doc(senderId);
    const giftEventRef = firestore
      .collection("rooms")
      .doc(roomId)
      .collection("gift_events")
      .doc();

    const [senderSnap, receiverSnap, roomSnap, senderParticipantSnap] =
      await Promise.all([
        txn.get(senderRef),
        txn.get(receiverRef),
        txn.get(roomRef),
        txn.get(senderParticipantRef),
      ]);

    if (!roomSnap.exists || roomSnap.data().isLive === false) {
      throw new HttpsError(
        "failed-precondition",
        "The room is not currently active.",
      );
    }
    if (!senderParticipantSnap.exists ||
        senderParticipantSnap.data().isBanned === true) {
      throw new HttpsError(
        "permission-denied",
        "You must be an active participant in the room to send gifts.",
      );
    }

    const senderBalance = Number(
      (senderSnap.data() && senderSnap.data().balance) || 0,
    );
    if (senderBalance < coinCost) {
      throw new HttpsError(
        "failed-precondition",
        "Insufficient coin balance.",
      );
    }

    const receiverBalance = Number(
      (receiverSnap.data() && receiverSnap.data().balance) || 0,
    );

    txn.update(senderRef, {balance: senderBalance - coinCost});
    txn.update(receiverRef, {balance: receiverBalance + receiverAmount});
    txn.set(giftEventRef, {
      id: giftEventRef.id,
      senderId,
      senderName,
      receiverId,
      roomId,
      giftId,
      coinCost,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return giftEventRef.id;
  });

  return {giftEventId};
}

exports.sendRoomGift = onCall(async (request) => sendRoomGiftHandler(request));

// ---------------------------------------------------------------------------
// sendDirectGift — send a gift from one user to another outside of a room.
// ---------------------------------------------------------------------------
async function sendDirectGiftHandler(request, deps = {}) {
  const senderId = requireAuth(request);
  enforceRateLimit("sendRoomGift", senderId); // reuse same rate-limit bucket
  const receiverId = parseIdField(
    request.data && request.data.receiverId,
    "receiverId",
  );
  const giftId = parseIdField(request.data && request.data.giftId, "giftId");
  const coinCost = parsePositiveAmount(request.data && request.data.coinCost);
  const senderName =
    typeof (request.data && request.data.senderName) === "string"
      ? request.data.senderName.trim().slice(0, 64)
      : "";
  const firestore = deps.firestore || db;

  if (receiverId === senderId) {
    throw new HttpsError(
      "invalid-argument",
      "Cannot send a gift to yourself.",
    );
  }

  const PLATFORM_FEE = 0.15;
  const receiverAmount = Math.max(1, Math.floor(coinCost * (1 - PLATFORM_FEE)));

  const giftEventId = await firestore.runTransaction(async (txn) => {
    const senderRef = firestore.collection("users").doc(senderId);
    const receiverRef = firestore.collection("users").doc(receiverId);
    const giftEventRef = firestore.collection("gift_events").doc();

    const [senderSnap, receiverSnap] = await Promise.all([
      txn.get(senderRef),
      txn.get(receiverRef),
    ]);

    if (!receiverSnap.exists) {
      throw new HttpsError("not-found", "Recipient user not found.");
    }

    const senderBalance = Number(
      (senderSnap.data() && senderSnap.data().balance) || 0,
    );
    if (senderBalance < coinCost) {
      throw new HttpsError("failed-precondition", "Insufficient coin balance.");
    }

    const receiverBalance = Number(
      (receiverSnap.data() && receiverSnap.data().balance) || 0,
    );

    txn.update(senderRef, {balance: senderBalance - coinCost});
    txn.update(receiverRef, {balance: receiverBalance + receiverAmount});
    txn.set(giftEventRef, {
      id: giftEventRef.id,
      senderId,
      senderName,
      receiverId,
      giftId,
      coinCost,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return giftEventRef.id;
  });

  return {giftEventId};
}

exports.sendDirectGift = onCall(async (request) =>
  sendDirectGiftHandler(request),
);

async function getStripeConnectStatusHandler(request, deps = {}) {
  const uid = requireAuth(request);
  enforceRateLimit("getStripeConnectStatus", uid);
  const firestore = deps.firestore || db;
  const stripeClient = deps.stripeClient || stripe;
  const accountRef = firestore.collection("stripe_connect_accounts").doc(uid);
  const accountSnap = await accountRef.get();

  if (!accountSnap.exists || !accountSnap.data().accountId) {
    return {
      hasAccount: false,
      accountId: null,
      chargesEnabled: false,
      payoutsEnabled: false,
      detailsSubmitted: false,
      onboardingComplete: false,
      country: process.env.STRIPE_CONNECT_COUNTRY || "US",
    };
  }

  const account = await stripeClient.accounts.retrieve(accountSnap.data().accountId);
  const mapped = mapStripeConnectAccount(account);
  await accountRef.set({
    ...mapped,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {
    hasAccount: true,
    ...mapped,
  };
}

exports.getStripeConnectStatus = onCall(async (request) =>
  getStripeConnectStatusHandler(request),
);

async function createStripeConnectOnboardingLinkHandler(request, deps = {}) {
  const uid = requireAuth(request);
  enforceRateLimit("createStripeConnectOnboardingLink", uid);
  const stripeClient = deps.stripeClient || stripe;
  const publicAppUrl = deps.publicAppUrl || getCheckoutBaseUrl();

  const mapped = await ensureStripeConnectAccount(uid, deps);
  const accountLink = await stripeClient.accountLinks.create({
    account: mapped.accountId,
    refresh_url: `${publicAppUrl}/payments?connect=refresh`,
    return_url: `${publicAppUrl}/payments?connect=return`,
    type: "account_onboarding",
  });

  return {
    url: accountLink.url,
    hasAccount: true,
    ...mapped,
  };
}

exports.createStripeConnectOnboardingLink = onCall(async (request) =>
  createStripeConnectOnboardingLinkHandler(request),
);

async function createStripeConnectDashboardLinkHandler(request, deps = {}) {
  const uid = requireAuth(request);
  enforceRateLimit("createStripeConnectDashboardLink", uid);
  const stripeClient = deps.stripeClient || stripe;
  const status = await ensureStripeConnectAccount(uid, deps);

  const loginLink = await stripeClient.accounts.createLoginLink(status.accountId);
  return {
    url: loginLink.url,
  };
}

exports.createStripeConnectDashboardLink = onCall(async (request) =>
  createStripeConnectDashboardLinkHandler(request),
);

async function generateAgoraTokenHandler(request, deps = {}) {
  const authUid = requireAuth(request);
  enforceRateLimit("generateAgoraToken", authUid);
  const channelName = parseIdField(
    request.data && request.data.channelName,
    "channelName",
  );
  const rtcUidValue = request.data && request.data.rtcUid;

  const rtcUid = Number(rtcUidValue);
  if (!Number.isFinite(rtcUid) || rtcUid <= 0) {
    throw new HttpsError("invalid-argument", "rtcUid must be a positive integer.");
  }

  // Only issue a token to users who have actually joined the room as a
  // participant.  This prevents unauthenticated spectators who merely know
  // a room ID from joining the Agora channel directly.
  const firestore = deps.firestore || db;
  const participantSnap = await firestore
    .collection("rooms")
    .doc(channelName)
    .collection("participants")
    .doc(authUid)
    .get();
  if (!participantSnap.exists) {
    throw new HttpsError(
      "permission-denied",
      "You must join the room before requesting a media token.",
    );
  }
  if (participantSnap.data().isBanned === true) {
    throw new HttpsError(
      "permission-denied",
      "You are not allowed to join this room.",
    );
  }

  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;
  if (!appId || !appCertificate) {
    throw new HttpsError(
      "failed-precondition",
      "Agora server credentials are not configured.",
    );
  }

  const currentTimestamp = Math.floor(Date.now() / 1000);
  const expirationTimeInSeconds = 3600;
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    Math.floor(rtcUid),
    RtcRole.PUBLISHER,
    privilegeExpiredTs,
  );

  return {
    token,
    appId,
    expiresAt: privilegeExpiredTs,
    issuedForUid: authUid,
  };
}

exports.generateAgoraToken = onCall(async (request) => generateAgoraTokenHandler(request));

async function requestRefundHandler(request, deps = {}) {
  const requesterId = requireAuth(request);
  enforceRateLimit("requestRefund", requesterId);
  const transactionId = parseIdField(
    request.data && request.data.transactionId,
    "transactionId",
  );
  const reasonRaw = request.data && request.data.reason;
  const reason = typeof reasonRaw === "string" ? reasonRaw.trim() : "";
  const firestore = deps.firestore || db;

  if (reason.length < 10 || reason.length > 500) {
    throw new HttpsError(
      "invalid-argument",
      "reason must be between 10 and 500 characters.",
    );
  }

  const txRef = firestore.collection("transactions").doc(transactionId);
  const txSnap = await txRef.get();
  if (!txSnap.exists) {
    throw new HttpsError("not-found", "Transaction not found.");
  }

  const txData = txSnap.data() || {};
  const participants = Array.isArray(txData.participants) ? txData.participants : [];
  const senderId = typeof txData.senderId === "string" ? txData.senderId : "";
  const receiverId = typeof txData.receiverId === "string" ? txData.receiverId : "";
  const isParticipant = participants.includes(requesterId) ||
    senderId === requesterId || receiverId === requesterId;

  if (!isParticipant) {
    throw new HttpsError(
      "permission-denied",
      "You are not allowed to request a refund for this transaction.",
    );
  }

  const refundRef = firestore
      .collection("refund_requests")
      .doc(`${transactionId}_${requesterId}`);
  const refundSnap = await refundRef.get();
  const existing = refundSnap.exists ? refundSnap.data() : null;
  if (existing && (existing.status === "pending" || existing.status === "under_review")) {
    throw new HttpsError(
      "already-exists",
      "A refund request is already open for this transaction.",
    );
  }

  await refundRef.set({
    id: refundRef.id,
    transactionId,
    requesterId,
    senderId,
    receiverId,
    amount: Number(txData.amount || 0),
    status: "pending",
    reason,
    sourceStatus: txData.status || "unknown",
    sourceType: txData.source || "unknown",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {
    refundRequestId: refundRef.id,
    status: "pending",
  };
}

exports.requestRefund = onCall(async (request) => requestRefundHandler(request));

async function cleanupDeletedUserData(uid, deps = {}) {
  const firestore = deps.firestore || db;

  if (!uid || typeof uid !== "string") {
    return;
  }

  const userRef = firestore.collection("users").doc(uid);
  const connectRef = firestore.collection("stripe_connect_accounts").doc(uid);

  // Delete all FCM / notification tokens before the user doc itself so the
  // subcollection doesn't become orphaned and leak PII after account deletion.
  const tokenSnap = await userRef.collection("notification_tokens").limit(200).get();
  if (!tokenSnap.empty) {
    const batch = firestore.batch();
    tokenSnap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }

  await Promise.allSettled([
    userRef.delete(),
    connectRef.delete(),
  ]);
}

exports.cleanupDeletedUser = functionsV1.auth.user().onDelete(async (user) => {
  if (!user || !user.uid) {
    return;
  }
  await cleanupDeletedUserData(user.uid);
});

exports.classifyNewReport = onDocumentCreated("reports/{reportId}", async (event) => {
  if (!event.data) {
    return;
  }

  const snapshot = event.data;
  const reportData = snapshot.data() || {};
  if (reportData.moderationReview && reportData.moderationReview.classifiedAt) {
    return;
  }

  const payload = buildModerationReviewPayload(reportData);
  await snapshot.ref.set(payload, {merge: true});
});

// Create Stripe Checkout Session
exports.createCheckoutSession = onRequest(async (req, res) =>
  createCheckoutSessionHandler(req, res),
);

exports.createCheckoutSessionCallable = onCall(async (request) =>
  createCheckoutSessionCallableHandler(request),
);

// Stripe Webhook
exports.stripeWebhook = onRequestV1(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  let event;
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET,
    );
  } catch (err) {
    console.error("Webhook signature failed:", err.message);
    try {
      await db.collection("logs").add({
        type: "stripe_webhook_error",
        message: err.message,
        time: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (logErr) {
      console.error("Failed to log webhook error:", logErr.message);
    }
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    const userId = session.metadata && session.metadata.userId;
    if (userId) {
      await db.collection("users").doc(userId).set({
        isPremium: true,
        premiumSince: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    }
  }
  res.json({received: true});
});

exports.__testing = {
  createPaymentIntentHandler,
  recordStripePaymentSuccessHandler,
  sendCoinTransferHandler,
  requestCoinTransferHandler,
  getStripeConnectStatusHandler,
  createStripeConnectOnboardingLinkHandler,
  createStripeConnectDashboardLinkHandler,
  generateAgoraTokenHandler,
  createCheckoutSessionHandler,
  createCheckoutSessionCallableHandler,
  requestRefundHandler,
  sendRoomGiftHandler,
  cleanupDeletedUserData,
  classifyModerationText,
  buildModerationReviewPayload,
  getCheckoutBaseUrl,
  mapStripeConnectAccount,
  ensureStripeConnectAccount,
  requireAuth,
  parsePositiveAmount,
  ensureUserExists,
  enforceRateLimit,
  parseIdField,
  parseOptionalIdempotencyKey,
  buildIdempotentTransactionDocId,
  validateStripePaymentIntent,
  registerFcmTokenHandler,
  unregisterFcmTokenHandler,
  sendPushForNotification,
};
