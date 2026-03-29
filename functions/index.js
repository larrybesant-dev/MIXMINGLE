const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
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
  getStripeConnectStatus: {windowMs: 60 * 1000, maxRequests: 40},
  createStripeConnectOnboardingLink: {windowMs: 60 * 1000, maxRequests: 10},
  createStripeConnectDashboardLink: {windowMs: 60 * 1000, maxRequests: 20},
  generateAgoraToken: {windowMs: 60 * 1000, maxRequests: 30},
  requestRefund: {windowMs: 60 * 1000, maxRequests: 12},
};

const rateLimitState = new Map();

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

async function createPaymentIntentHandler(request, deps = {}) {
  const senderId = requireAuth(request);
  enforceRateLimit("createPaymentIntent", senderId);
  const recipientId = parseIdField(
    request.data && request.data.recipientId,
    "recipientId",
  );
  const currency = request.data && request.data.currency;
  const amount = parsePositiveAmount(request.data && request.data.amount);
  const stripeClient = deps.stripeClient || stripe;

  const normalizedCurrency = typeof currency === "string" ? currency.toLowerCase() : "usd";
  const paymentIntent = await stripeClient.paymentIntents.create({
    amount: Math.round(amount * 100),
    currency: normalizedCurrency,
    metadata: {
      senderId,
      recipientId,
      amount: amount.toString(),
      kind: "mixvy_coin_payment",
    },
    automatic_payment_methods: {
      enabled: true,
    },
  });

  return {
    clientSecret: paymentIntent.client_secret,
  };
}

exports.createPaymentIntent = onCall(async (request) =>
  createPaymentIntentHandler(request),
);

async function recordStripePaymentSuccessHandler(request, deps = {}) {
  const senderId = requireAuth(request);
  enforceRateLimit("recordStripePaymentSuccess", senderId);
  const recipientId = parseIdField(
    request.data && request.data.recipientId,
    "recipientId",
  );
  const amount = parsePositiveAmount(request.data && request.data.amount);
  const firestore = deps.firestore || db;

  const transactionRef = firestore.collection("transactions").doc();
  await transactionRef.set({
    id: transactionRef.id,
    senderId,
    receiverId: recipientId,
    participants: [senderId, recipientId],
    amount,
    timestamp: new Date().toISOString(),
    status: "completed",
    source: "stripe",
  });

  return {transactionId: transactionRef.id};
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
  const firestore = deps.firestore || db;

  if (receiverId === senderId) {
    throw new HttpsError("invalid-argument", "Cannot send a payment to yourself.");
  }

  await ensureUserExists(senderId, firestore);
  await ensureUserExists(receiverId, firestore);

  const transactionId = await firestore.runTransaction(async (txn) => {
    const senderRef = firestore.collection("users").doc(senderId);
    const receiverRef = firestore.collection("users").doc(receiverId);
    const transactionRef = firestore.collection("transactions").doc();

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
  const firestore = deps.firestore || db;

  if (targetId === requesterId) {
    throw new HttpsError("invalid-argument", "Cannot request a payment from yourself.");
  }

  const transactionRef = firestore.collection("transactions").doc();
  await transactionRef.set({
    id: transactionRef.id,
    senderId: requesterId,
    receiverId: targetId,
    participants: [requesterId, targetId],
    amount,
    timestamp: new Date().toISOString(),
    status: "requested",
    source: "request",
  });

  return {transactionId: transactionRef.id};
}

exports.requestCoinTransfer = onCall(async (request) =>
  requestCoinTransferHandler(request),
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

async function generateAgoraTokenHandler(request) {
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

// Create Stripe Checkout Session
exports.createCheckoutSession = onRequest(async (req, res) =>
  createCheckoutSessionHandler(req, res),
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
  requestRefundHandler,
  cleanupDeletedUserData,
  getCheckoutBaseUrl,
  mapStripeConnectAccount,
  ensureStripeConnectAccount,
  requireAuth,
  parsePositiveAmount,
  ensureUserExists,
  enforceRateLimit,
  parseIdField,
};
