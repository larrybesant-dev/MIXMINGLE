/**
 * Payment Cloud Functions
 * Handles payment methods, checkout, and payment processing
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Create checkout session for coin purchase
 * Called by: payment_service.dart (createCheckout method)
 *
 * Note: In production, this would integrate with Stripe, PayPal, or other payment providers
 */
export const createCheckout = onCall({ region: "us-central1", cors: true }, async (request) => {
  const authenticatedUid = request.auth?.uid;
  if (!authenticatedUid) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { uid, amount } = request.data || {};
  const targetUid = uid || authenticatedUid;

  if (targetUid !== authenticatedUid) {
    throw new HttpsError("permission-denied", "Cannot create checkout for other users");
  }

  if (typeof amount !== "number" || amount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid amount");
  }

  try {
    // Create checkout session record
    const checkoutRef = db.collection("checkout_sessions").doc();
    const sessionData = {
      userId: targetUid,
      amount,
      coinAmount: calculateCoinsForAmount(amount),
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 30 * 60 * 1000), // 30 min expiry
    };

    await checkoutRef.set(sessionData);

    // In production, this would return a payment provider URL
    // For now, return a mock checkout URL
    const checkoutUrl = `https://app.mixmingle.com/checkout/${checkoutRef.id}`;

    logger.info(`Created checkout session for user ${targetUid}`, { sessionId: checkoutRef.id });

    return {
      checkoutUrl,
      sessionId: checkoutRef.id,
      amount,
      coinAmount: sessionData.coinAmount,
    };
  } catch (error) {
    logger.error("Error creating checkout:", error);
    throw new HttpsError("internal", "Failed to create checkout session");
  }
});

/**
 * Get user's saved payment methods
 * Called by: payment_service.dart (getPaymentMethods method)
 */
export const getPaymentMethods = onCall({ region: "us-central1", cors: true }, async (request) => {
  const authenticatedUid = request.auth?.uid;
  if (!authenticatedUid) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { uid } = request.data || {};
  const targetUid = uid || authenticatedUid;

  if (targetUid !== authenticatedUid) {
    throw new HttpsError("permission-denied", "Cannot view other users' payment methods");
  }

  try {
    const methodsSnap = await db
      .collection("users")
      .doc(targetUid)
      .collection("payment_methods")
      .orderBy("createdAt", "desc")
      .get();

    const methods = methodsSnap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      // Remove sensitive data
      cardNumber: undefined,
      fullNumber: undefined,
      cvv: undefined,
    }));

    return methods;
  } catch (error) {
    logger.error("Error getting payment methods:", error);
    return [];
  }
});

/**
 * Get user's payment history
 * Called by: payment_service.dart (getPaymentHistory method)
 */
export const getPaymentHistory = onCall({ region: "us-central1", cors: true }, async (request) => {
  const authenticatedUid = request.auth?.uid;
  if (!authenticatedUid) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { uid } = request.data || {};
  const targetUid = uid || authenticatedUid;

  if (targetUid !== authenticatedUid) {
    throw new HttpsError("permission-denied", "Cannot view other users' payment history");
  }

  try {
    const historySnap = await db
      .collection("coins_transactions")
      .where("userId", "==", targetUid)
      .where("type", "in", ["purchase", "refund"])
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const history = historySnap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toMillis() || null,
    }));

    return history;
  } catch (error) {
    logger.error("Error getting payment history:", error);
    return [];
  }
});

/**
 * Process a payment using a saved payment method
 * Called by: payment_service.dart (processPayment method)
 */
export const processPayment = onCall({ region: "us-central1", cors: true }, async (request) => {
  const authenticatedUid = request.auth?.uid;
  if (!authenticatedUid) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { uid, paymentMethodId, amount } = request.data || {};
  const targetUid = uid || authenticatedUid;

  if (targetUid !== authenticatedUid) {
    throw new HttpsError("permission-denied", "Cannot process payment for other users");
  }

  if (!paymentMethodId || typeof amount !== "number" || amount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid payment parameters");
  }

  try {
    // Verify payment method exists and belongs to user
    const methodDoc = await db
      .collection("users")
      .doc(targetUid)
      .collection("payment_methods")
      .doc(paymentMethodId)
      .get();

    if (!methodDoc.exists) {
      throw new HttpsError("not-found", "Payment method not found");
    }

    // In production, this would call the payment provider API
    // For now, simulate a successful payment
    const coinAmount = calculateCoinsForAmount(amount);

    await db.runTransaction(async (transaction) => {
      const userRef = db.collection("users").doc(targetUid);
      const userDoc = await transaction.get(userRef);
      const currentBalance = userDoc.exists ? (userDoc.data()?.coinBalance ?? 0) : 0;
      const newBalance = currentBalance + coinAmount;

      transaction.set(userRef, { coinBalance: newBalance }, { merge: true });

      const txRef = db.collection("coins_transactions").doc();
      transaction.set(txRef, {
        userId: targetUid,
        amount: coinAmount,
        type: "purchase",
        usdAmount: amount,
        paymentMethodId,
        balanceBefore: currentBalance,
        balanceAfter: newBalance,
        status: "completed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    logger.info(`Processed payment for user ${targetUid}`, { amount, coinAmount });
    return { success: true, coinAmount };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Error processing payment:", error);
    throw new HttpsError("internal", "Failed to process payment");
  }
});

/**
 * Add a new payment method
 * Called by: payment_service.dart (addPaymentMethod method)
 */
export const addPaymentMethod = onCall({ region: "us-central1", cors: true }, async (request) => {
  const authenticatedUid = request.auth?.uid;
  if (!authenticatedUid) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { uid, ...paymentData } = request.data || {};
  const targetUid = uid || authenticatedUid;

  if (targetUid !== authenticatedUid) {
    throw new HttpsError("permission-denied", "Cannot add payment method for other users");
  }

  try {
    // In production, this would tokenize the card with the payment provider
    // For now, store a masked version
    const methodRef = db.collection("users").doc(targetUid).collection("payment_methods").doc();

    const maskedData = {
      type: paymentData.type || "card",
      last4: paymentData.cardNumber?.slice(-4) || "****",
      brand: detectCardBrand(paymentData.cardNumber),
      expiryMonth: paymentData.expiryMonth,
      expiryYear: paymentData.expiryYear,
      isDefault: paymentData.isDefault || false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await methodRef.set(maskedData);

    logger.info(`Added payment method for user ${targetUid}`);
    return { success: true, methodId: methodRef.id };
  } catch (error) {
    logger.error("Error adding payment method:", error);
    throw new HttpsError("internal", "Failed to add payment method");
  }
});

/**
 * Remove a payment method
 * Called by: payment_service.dart (removePaymentMethod method)
 */
export const removePaymentMethod = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const authenticatedUid = request.auth?.uid;
    if (!authenticatedUid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { uid, paymentMethodId } = request.data || {};
    const targetUid = uid || authenticatedUid;

    if (targetUid !== authenticatedUid) {
      throw new HttpsError("permission-denied", "Cannot remove payment method for other users");
    }

    if (!paymentMethodId) {
      throw new HttpsError("invalid-argument", "Payment method ID required");
    }

    try {
      const methodRef = db
        .collection("users")
        .doc(targetUid)
        .collection("payment_methods")
        .doc(paymentMethodId);

      const methodDoc = await methodRef.get();
      if (!methodDoc.exists) {
        throw new HttpsError("not-found", "Payment method not found");
      }

      await methodRef.delete();

      logger.info(`Removed payment method ${paymentMethodId} for user ${targetUid}`);
      return { success: true };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Error removing payment method:", error);
      throw new HttpsError("internal", "Failed to remove payment method");
    }
  },
);

/**
 * Refund a payment
 * Called by: payment_service.dart (refundPayment method)
 */
export const refundPayment = onCall({ region: "us-central1", cors: true }, async (request) => {
  const authenticatedUid = request.auth?.uid;
  if (!authenticatedUid) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { uid, transactionId } = request.data || {};
  const targetUid = uid || authenticatedUid;

  if (targetUid !== authenticatedUid) {
    throw new HttpsError("permission-denied", "Cannot request refund for other users");
  }

  if (!transactionId) {
    throw new HttpsError("invalid-argument", "Transaction ID required");
  }

  try {
    // Get original transaction
    const txDoc = await db.collection("coins_transactions").doc(transactionId).get();

    if (!txDoc.exists) {
      throw new HttpsError("not-found", "Transaction not found");
    }

    const txData = txDoc.data()!;

    if (txData.userId !== targetUid) {
      throw new HttpsError("permission-denied", "Transaction does not belong to user");
    }

    if (txData.type !== "purchase") {
      throw new HttpsError("failed-precondition", "Only purchases can be refunded");
    }

    if (txData.refunded) {
      throw new HttpsError("failed-precondition", "Transaction already refunded");
    }

    // Process refund
    await db.runTransaction(async (transaction) => {
      const userRef = db.collection("users").doc(targetUid);
      const userDoc = await transaction.get(userRef);
      const currentBalance = userDoc.exists ? (userDoc.data()?.coinBalance ?? 0) : 0;
      const refundAmount = txData.amount;
      const newBalance = Math.max(0, currentBalance - refundAmount);

      // Update balance
      transaction.set(userRef, { coinBalance: newBalance }, { merge: true });

      // Mark original transaction as refunded
      transaction.update(db.collection("coins_transactions").doc(transactionId), {
        refunded: true,
        refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create refund transaction record
      const refundRef = db.collection("coins_transactions").doc();
      transaction.set(refundRef, {
        userId: targetUid,
        amount: -refundAmount,
        type: "refund",
        originalTransactionId: transactionId,
        balanceBefore: currentBalance,
        balanceAfter: newBalance,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    logger.info(`Processed refund for transaction ${transactionId}`);
    return { success: true };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Error processing refund:", error);
    throw new HttpsError("internal", "Failed to process refund");
  }
});

/**
 * Validate a token (for token_service.dart)
 * Called by: token_service.dart (validateToken method)
 */
export const validateToken = onCall({ region: "us-central1", cors: true }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { token } = request.data || {};

  if (!token) {
    return { valid: false, reason: "No token provided" };
  }

  try {
    // For Firebase auth tokens, they're already validated by the SDK
    // This function is for validating Agora or other custom tokens

    // Simple validation: check if token is non-empty string
    const isValid = typeof token === "string" && token.length > 10;

    return { valid: isValid };
  } catch (error) {
    logger.error("Error validating token:", error);
    return { valid: false, reason: "Validation error" };
  }
});

// Helper functions

function calculateCoinsForAmount(usdAmount: number): number {
  // Conversion: 1 USD = 100 coins
  return Math.floor(usdAmount * 100);
}

function detectCardBrand(cardNumber?: string): string {
  if (!cardNumber) return "unknown";

  const firstDigit = cardNumber.charAt(0);
  const firstTwo = cardNumber.substring(0, 2);

  if (firstDigit === "4") return "visa";
  if (["51", "52", "53", "54", "55"].includes(firstTwo)) return "mastercard";
  if (["34", "37"].includes(firstTwo)) return "amex";
  if (firstDigit === "6") return "discover";

  return "unknown";
}
