import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface CheckRateLimitParams {
  action: string; // e.g., 'like', 'send_message'
  limit: number; // max operations per window
  windowSeconds: number; // window size in seconds
}

export const checkRateLimit = functions.https.onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { action, limit, windowSeconds } = (request.data || {}) as CheckRateLimitParams;
  if (!action || typeof limit !== 'number' || typeof windowSeconds !== 'number') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid parameters');
  }

  const now = Date.now();
  const windowMs = windowSeconds * 1000;
  const docId = `${uid}_${action}`;
  const ref = db.collection('rateLimits').doc(docId);

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const current = snap.exists ? snap.data()! : {};
      const resetAt: number = current.resetAt ?? 0;
      let count: number = current.count ?? 0;

      // Reset window if expired
      if (now >= resetAt) {
        count = 0;
      }

      // Decide allowance
      const allowed = count < limit;
      const nextReset = now >= resetAt ? now + windowMs : resetAt;

      if (!allowed) {
        const retryAfterSeconds = Math.ceil((nextReset - now) / 1000);
        // Update doc to ensure fields exist
        tx.set(ref, { count, resetAt: nextReset, updatedAt: now }, { merge: true });
        throw new functions.https.HttpsError('resource-exhausted', 'Rate limited', {
          allowed: false,
          retryAfterSeconds,
        });
      }

      // Increment and set reset
      tx.set(ref, { count: count + 1, resetAt: nextReset, updatedAt: now }, { merge: true });
    });

    return { allowed: true, retryAfterSeconds: 0 };
  } catch (err: any) {
    if (err instanceof functions.https.HttpsError) {
      // passthrough structured error
      throw err;
    }
    throw new functions.https.HttpsError('internal', 'Failed to check rate limit');
  }
});
