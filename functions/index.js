
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Stripe = require("stripe");
const cors = require("cors")({ origin: true });
const { STRIPE_SECRET, STRIPE_WEBHOOK_SECRET } = require("./params");

admin.initializeApp();

// 🔥 CREATE CHECKOUT SESSION (Stripe instantiated at runtime)
exports.createCheckoutSession = functions.runWith({ secrets: [STRIPE_SECRET] }).https.onRequest((req, res) => {
    cors(req, res, async () => {
        try {
            const { userId } = req.body;
            if (!userId) {
                return res.status(400).send("Missing userId");
            }
            const stripe = new Stripe(STRIPE_SECRET.value(), {
                apiVersion: "2023-10-16"
            });
            const session = await stripe.checkout.sessions.create({
                payment_method_types: ["card"],
                mode: "payment",
                line_items: [
                    {
                        price_data: {
                            currency: "usd",
                            product_data: {
                                name: "Premium Upgrade"
                            },
                            unit_amount: 999
                        },
                        quantity: 1
                    }
                ],
                success_url: "https://yourapp.web.app/success",
                cancel_url: "https://yourapp.web.app/cancel",
                metadata: {
                    userId: userId
                }
            });
            res.json({ url: session.url });
        } catch (error) {
            console.error(error);
            res.status(500).send(error.message);
        }
    });
});

// 🔥 STRIPE WEBHOOK (Stripe instantiated at runtime)
exports.stripeWebhook = functions.runWith({ secrets: [STRIPE_SECRET, STRIPE_WEBHOOK_SECRET] }).https.onRequest(async (req, res) => {
    const sig = req.headers["stripe-signature"];
    const stripe = new Stripe(STRIPE_SECRET.value(), {
        apiVersion: "2023-10-16"
    });
    const endpointSecret = STRIPE_WEBHOOK_SECRET.value();
    let event;
    try {
        event = stripe.webhooks.constructEvent(
            req.rawBody,
            sig,
            endpointSecret
        );
    } catch (err) {
        console.error("Webhook signature failed:", err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }
    // ✅ PAYMENT SUCCESS
    if (event.type === "checkout.session.completed") {
        const session = event.data.object;
        const userId = session.metadata.userId;
        if (userId) {
            await admin.firestore().collection("users").doc(userId).update({
                isPremium: true,
                premiumSince: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    }
    res.json({ received: true });
});
