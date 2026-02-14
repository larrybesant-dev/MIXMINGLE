/**
 * Coin Economy Cloud Functions
 * Handles coin transactions, balances, tipping, and purchases
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Get user's current coin balance
 * Called by: tipping_service.dart, coin_economy_service.dart
 */
export const getUserBalance = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { userId } = request.data || {};
    const targetUserId = userId || uid;

    // Users can only query their own balance (or we could allow admins to query others)
    if (targetUserId !== uid) {
      throw new HttpsError("permission-denied", "Cannot query other users' balance");
    }

    try {
      const userDoc = await db.collection("users").doc(targetUserId).get();
      const balance = userDoc.exists ? (userDoc.data()?.coinBalance ?? 0) : 0;

      return { balance, userId: targetUserId };
    } catch (error) {
      logger.error("Error getting user balance:", error);
      throw new HttpsError("internal", "Failed to get user balance");
    }
  }
);

/**
 * Add coins to user balance with transaction logging
 * Called by: coin_economy_service.dart (addCoins method), tipping_service.dart
 */
export const addCoinsWithTransaction = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { userId, amount, source, description, referenceId } = request.data || {};

    if (!userId || typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("invalid-argument", "Invalid userId or amount");
    }

    // Only allow adding coins to yourself (or admin role can add to others)
    if (userId !== uid) {
      // Check if user is admin
      const callerDoc = await db.collection("users").doc(uid).get();
      const isAdmin = callerDoc.exists && callerDoc.data()?.role === "admin";
      if (!isAdmin) {
        throw new HttpsError("permission-denied", "Cannot add coins to other users");
      }
    }

    try {
      const result = await db.runTransaction(async (transaction) => {
        const userRef = db.collection("users").doc(userId);
        const userDoc = await transaction.get(userRef);

        const currentBalance = userDoc.exists ? (userDoc.data()?.coinBalance ?? 0) : 0;
        const newBalance = currentBalance + amount;

        // Update user balance
        transaction.set(userRef, { coinBalance: newBalance }, { merge: true });

        // Log transaction
        const txRef = db.collection("coins_transactions").doc();
        transaction.set(txRef, {
          userId,
          amount,
          type: "earn",
          source: source || "system",
          description: description || "Coins added",
          referenceId: referenceId || null,
          balanceBefore: currentBalance,
          balanceAfter: newBalance,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          createdBy: uid,
        });

        return { newBalance, transactionId: txRef.id };
      });

      logger.info(`Added ${amount} coins to user ${userId}`, result);
      return { success: true, ...result };
    } catch (error) {
      logger.error("Error adding coins:", error);
      throw new HttpsError("internal", "Failed to add coins");
    }
  }
);

/**
 * Simple addCoins function (for tipping_service.dart)
 * Wrapper around addCoinsWithTransaction
 */
export const addCoins = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { userId, amount } = request.data || {};

    if (!userId || typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("invalid-argument", "Invalid userId or amount");
    }

    // Only allow adding coins to yourself
    if (userId !== uid) {
      throw new HttpsError("permission-denied", "Cannot add coins to other users");
    }

    try {
      const result = await db.runTransaction(async (transaction) => {
        const userRef = db.collection("users").doc(userId);
        const userDoc = await transaction.get(userRef);

        const currentBalance = userDoc.exists ? (userDoc.data()?.coinBalance ?? 0) : 0;
        const newBalance = currentBalance + amount;

        transaction.set(userRef, { coinBalance: newBalance }, { merge: true });

        return { newBalance };
      });

      return { success: true, balance: result.newBalance };
    } catch (error) {
      logger.error("Error adding coins:", error);
      throw new HttpsError("internal", "Failed to add coins");
    }
  }
);

/**
 * Spend coins with transaction logging
 * Called by: coin_economy_service.dart (spendCoins method)
 */
export const spendCoins = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { userId, amount, purpose, referenceId } = request.data || {};
    const targetUserId = userId || uid;

    if (typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("invalid-argument", "Invalid amount");
    }

    // Users can only spend their own coins
    if (targetUserId !== uid) {
      throw new HttpsError("permission-denied", "Cannot spend other users' coins");
    }

    try {
      const result = await db.runTransaction(async (transaction) => {
        const userRef = db.collection("users").doc(targetUserId);
        const userDoc = await transaction.get(userRef);

        const currentBalance = userDoc.exists ? (userDoc.data()?.coinBalance ?? 0) : 0;

        if (currentBalance < amount) {
          throw new HttpsError("failed-precondition", "Insufficient coin balance");
        }

        const newBalance = currentBalance - amount;

        // Update user balance
        transaction.set(userRef, { coinBalance: newBalance }, { merge: true });

        // Log transaction
        const txRef = db.collection("coins_transactions").doc();
        transaction.set(txRef, {
          userId: targetUserId,
          amount: -amount,
          type: "spend",
          purpose: purpose || "purchase",
          referenceId: referenceId || null,
          balanceBefore: currentBalance,
          balanceAfter: newBalance,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { newBalance, transactionId: txRef.id };
      });

      logger.info(`User ${targetUserId} spent ${amount} coins`, result);
      return { success: true, ...result };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Error spending coins:", error);
      throw new HttpsError("internal", "Failed to spend coins");
    }
  }
);

/**
 * Purchase coins with real money
 * Called by: coin_economy_service.dart (purchaseCoins method)
 */
export const purchaseCoins = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { userId, coinAmount, usdAmount, paymentMethod, transactionId } = request.data || {};
    const targetUserId = userId || uid;

    if (typeof coinAmount !== "number" || coinAmount <= 0) {
      throw new HttpsError("invalid-argument", "Invalid coin amount");
    }

    if (targetUserId !== uid) {
      throw new HttpsError("permission-denied", "Cannot purchase for other users");
    }

    try {
      const result = await db.runTransaction(async (transaction) => {
        const userRef = db.collection("users").doc(targetUserId);
        const userDoc = await transaction.get(userRef);

        const currentBalance = userDoc.exists ? (userDoc.data()?.coinBalance ?? 0) : 0;
        const newBalance = currentBalance + coinAmount;

        // Update user balance
        transaction.set(userRef, { coinBalance: newBalance }, { merge: true });

        // Log purchase
        const purchaseRef = db.collection("coins_transactions").doc();
        transaction.set(purchaseRef, {
          userId: targetUserId,
          amount: coinAmount,
          type: "purchase",
          usdAmount: usdAmount || 0,
          paymentMethod: paymentMethod || "unknown",
          externalTransactionId: transactionId || null,
          balanceBefore: currentBalance,
          balanceAfter: newBalance,
          status: "completed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { newBalance, purchaseId: purchaseRef.id };
      });

      logger.info(`User ${targetUserId} purchased ${coinAmount} coins`, result);
      return { success: true, ...result };
    } catch (error) {
      logger.error("Error purchasing coins:", error);
      throw new HttpsError("internal", "Failed to process coin purchase");
    }
  }
);

/**
 * Send a tip to another user
 * Called by: tipping_service.dart (sendTip method)
 */
export const sendTip = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { receiverId, amount, message, roomId } = request.data || {};

    if (!receiverId || typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("invalid-argument", "Invalid receiverId or amount");
    }

    if (receiverId === uid) {
      throw new HttpsError("invalid-argument", "Cannot tip yourself");
    }

    try {
      const result = await db.runTransaction(async (transaction) => {
        // Get sender's balance
        const senderRef = db.collection("users").doc(uid);
        const senderDoc = await transaction.get(senderRef);
        const senderBalance = senderDoc.exists ? (senderDoc.data()?.coinBalance ?? 0) : 0;

        if (senderBalance < amount) {
          throw new HttpsError("failed-precondition", "Insufficient coin balance");
        }

        // Get receiver's balance
        const receiverRef = db.collection("users").doc(receiverId);
        const receiverDoc = await transaction.get(receiverRef);

        if (!receiverDoc.exists) {
          throw new HttpsError("not-found", "Recipient not found");
        }

        const receiverBalance = receiverDoc.data()?.coinBalance ?? 0;

        // Update balances
        const newSenderBalance = senderBalance - amount;
        const newReceiverBalance = receiverBalance + amount;

        transaction.set(senderRef, { coinBalance: newSenderBalance }, { merge: true });
        transaction.set(receiverRef, { coinBalance: newReceiverBalance }, { merge: true });

        // Create tip record
        const tipRef = db.collection("tips").doc();
        transaction.set(tipRef, {
          senderId: uid,
          receiverId,
          amount,
          message: message || "",
          roomId: roomId || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Log transactions for both parties
        const senderTxRef = db.collection("coins_transactions").doc();
        transaction.set(senderTxRef, {
          userId: uid,
          amount: -amount,
          type: "spend",
          purpose: "tip_sent",
          referenceId: receiverId,
          balanceBefore: senderBalance,
          balanceAfter: newSenderBalance,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const receiverTxRef = db.collection("coins_transactions").doc();
        transaction.set(receiverTxRef, {
          userId: receiverId,
          amount,
          type: "earn",
          source: "tip_received",
          referenceId: uid,
          balanceBefore: receiverBalance,
          balanceAfter: newReceiverBalance,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { tipId: tipRef.id, newBalance: newSenderBalance };
      });

      logger.info(`User ${uid} sent ${amount} coin tip to ${receiverId}`);
      return { success: true, ...result };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Error sending tip:", error);
      throw new HttpsError("internal", "Failed to send tip");
    }
  }
);

/**
 * Process tip (alias for sendTip for payment_service.dart)
 * Called by: payment_service.dart (processTip method)
 */
export const processTip = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { fromUid, toUid, amount } = request.data || {};
    const senderId = fromUid || uid;
    const receiverId = toUid;

    if (!receiverId || typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("invalid-argument", "Invalid parameters");
    }

    // Forward to sendTip logic
    try {
      const result = await db.runTransaction(async (transaction) => {
        const senderRef = db.collection("users").doc(senderId);
        const senderDoc = await transaction.get(senderRef);
        const senderBalance = senderDoc.exists ? (senderDoc.data()?.coinBalance ?? 0) : 0;

        if (senderBalance < amount) {
          throw new HttpsError("failed-precondition", "Insufficient balance");
        }

        const receiverRef = db.collection("users").doc(receiverId);
        const receiverDoc = await transaction.get(receiverRef);

        if (!receiverDoc.exists) {
          throw new HttpsError("not-found", "Recipient not found");
        }

        const receiverBalance = receiverDoc.data()?.coinBalance ?? 0;

        const newSenderBalance = senderBalance - amount;
        const newReceiverBalance = receiverBalance + amount;

        transaction.set(senderRef, { coinBalance: newSenderBalance }, { merge: true });
        transaction.set(receiverRef, { coinBalance: newReceiverBalance }, { merge: true });

        const tipRef = db.collection("tips").doc();
        transaction.set(tipRef, {
          senderId,
          receiverId,
          amount,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { tipId: tipRef.id };
      });

      return { success: true, ...result };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Error processing tip:", error);
      throw new HttpsError("internal", "Failed to process tip");
    }
  }
);
