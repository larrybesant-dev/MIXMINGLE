
const {onRequest} = require("firebase-functions/v2/https");
const {onRequest: onRequestV1} = require("firebase-functions/v1");
const admin = require("firebase-admin");
const Stripe = require("stripe");
admin.initializeApp();
const stripe = new Stripe(process.env.STRIPE_SECRET);

// Create Stripe Checkout Session
exports.createCheckoutSession = onRequest(async (req, res) => {
    try {
        const {userId} = req.body;
        if (!userId) return res.status(400).json({error: "Missing userId"});
        const session = await stripe.checkout.sessions.create({
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
            success_url: "https://your-site.com/success",
            cancel_url: "https://your-site.com/cancel",
        });
        res.json({url: session.url});
    } catch (error) {
        console.error(error);
        res.status(500).send(error.message);
    }
});

// Stripe Webhook
exports.stripeWebhook = onRequestV1(async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event;
    try {
        event = stripe.webhooks.constructEvent(req.rawBody, sig, process.env.STRIPE_WEBHOOK_SECRET);
    } catch (err) {
        console.error("Webhook signature failed:", err.message);
        // Optionally: send error to Crashlytics or monitoring service
        try {
            await admin.firestore().collection('logs').add({
                type: 'stripe_webhook_error',
                message: err.message,
                time: admin.firestore.FieldValue.serverTimestamp(),
            });
        } catch (logErr) {
            console.error('Failed to log webhook error:', logErr.message);
        }
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }
    // ✅ PAYMENT SUCCESS
    if (event.type === "checkout.session.completed") {
        const session = event.data.object;
        const userId = session.metadata && session.metadata.userId;
        if (userId) {
            await admin.firestore().collection("users").doc(userId).update({
                isPremium: true,
                premiumSince: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    }
    res.json({received: true});
});
