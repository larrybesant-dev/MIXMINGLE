require("dotenv").config();
const functions = require("firebase-functions");
const Stripe = require("stripe");

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  try {
    const {amount} = req.body;
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: "usd",
    });
    res.send({clientSecret: paymentIntent.client_secret});
  } catch (error) {
    res.status(500).send(error.message);
  }
});
