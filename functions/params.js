// params.js: Exports Stripe secrets from environment variables for Firebase Functions v7+

const { defineSecret } = require("firebase-functions/params");

// Define secrets (these must be set via Firebase CLI or Console)
const STRIPE_SECRET = defineSecret("STRIPE_SECRET");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

module.exports = {
  STRIPE_SECRET,
  STRIPE_WEBHOOK_SECRET,
};
