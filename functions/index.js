
const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const {onRequest: onRequestV1} = require("firebase-functions/v1/https");
const admin = require("firebase-admin");
const Stripe = require("stripe");
admin.initializeApp();
const stripe = new Stripe(process.env.STRIPE_SECRET || "sk_test_dummy");
const db = admin.firestore();

function getCheckoutBaseUrl() {
    const baseUrl = process.env.CHECKOUT_BASE_URL || process.env.PUBLIC_APP_URL || "http://localhost:3000";
    return baseUrl.endsWith("/") ? baseUrl.slice(0, -1) : baseUrl;
}

async function createCheckoutSessionHandler(req, res, deps = {}) {
    const stripeClient = deps.stripeClient || stripe;

    try {
        const checkoutBaseUrl = getCheckoutBaseUrl();
        const {userId} = req.body;
        if (!userId) return res.status(400).json({error: "Missing userId"});
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
    return request.auth.uid;
}

function parsePositiveAmount(value) {
    const amount = Number(value);
    if (!Number.isFinite(amount) || amount <= 0) {
        throw new HttpsError("invalid-argument", "Amount must be greater than zero.");
    }
    return amount;
}

async function createPaymentIntentHandler(request, deps = {}) {
    const senderId = requireAuth(request);
    const recipientId = request.data && request.data.recipientId;
    const currency = request.data && request.data.currency;
    const amount = parsePositiveAmount(request.data && request.data.amount);
    const stripeClient = deps.stripeClient || stripe;

    if (!recipientId || typeof recipientId !== "string") {
        throw new HttpsError("invalid-argument", "recipientId is required.");
    }

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

exports.createPaymentIntent = onCall(async (request) => createPaymentIntentHandler(request));

async function recordStripePaymentSuccessHandler(request, deps = {}) {
    const senderId = requireAuth(request);
    const recipientId = request.data && request.data.recipientId;
    const amount = parsePositiveAmount(request.data && request.data.amount);
    const firestore = deps.firestore || db;

    if (!recipientId || typeof recipientId !== "string") {
        throw new HttpsError("invalid-argument", "recipientId is required.");
    }

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

exports.recordStripePaymentSuccess = onCall(async (request) => recordStripePaymentSuccessHandler(request));

async function sendCoinTransferHandler(request, deps = {}) {
    const senderId = requireAuth(request);
    const receiverId = request.data && request.data.receiverId;
    const amount = parsePositiveAmount(request.data && request.data.amount);
    const firestore = deps.firestore || db;

    if (!receiverId || typeof receiverId !== "string") {
        throw new HttpsError("invalid-argument", "receiverId is required.");
    }
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

        const senderBalance = Number(senderSnap.data() && senderSnap.data().balance || 0);
        const receiverBalance = Number(receiverSnap.data() && receiverSnap.data().balance || 0);

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
    const targetId = request.data && request.data.targetId;
    const amount = parsePositiveAmount(request.data && request.data.amount);
    const firestore = deps.firestore || db;

    if (!targetId || typeof targetId !== "string") {
        throw new HttpsError("invalid-argument", "targetId is required.");
    }
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

exports.requestCoinTransfer = onCall(async (request) => requestCoinTransferHandler(request));

// Create Stripe Checkout Session
exports.createCheckoutSession = onRequest(async (req, res) => createCheckoutSessionHandler(req, res));

// Stripe Webhook
exports.stripeWebhook = onRequestV1(async (req, res) => {
    const sig = req.headers["stripe-signature"];
    let event;
    try {
        event = stripe.webhooks.constructEvent(req.rawBody, sig, process.env.STRIPE_WEBHOOK_SECRET);
    } catch (err) {
        console.error("Webhook signature failed:", err.message);
        // Optionally: send error to Crashlytics or monitoring service
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
    // ✅ PAYMENT SUCCESS
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
    createCheckoutSessionHandler,
    getCheckoutBaseUrl,
    requireAuth,
    parsePositiveAmount,
    ensureUserExists,
};
