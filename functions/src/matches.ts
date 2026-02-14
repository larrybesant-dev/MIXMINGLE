// Match Algorithm Cloud Functions
// Handles match generation, likes, and mutual match detection

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

const db = admin.firestore();

/**
 * Compute match score between two users
 * Score ranges from 0-100+
 */
function computeMatchScore(userA: any, userB: any): number {
  let score = 0;

  // Age overlap (0-30 points)
  const ageA = userA.age;
  const ageB = userB.age;
  if (ageA && ageB) {
    const diff = Math.abs(ageA - ageB);
    if (diff <= 3) score += 30;
    else if (diff <= 7) score += 15;
    else if (diff <= 10) score += 5;
  }

  // Gender preference (20 points or disqualify)
  const genderPref = userA.preferences?.genderPreference;
  if (genderPref && genderPref !== "any") {
    if (userB.gender === genderPref) {
      score += 20;
    } else {
      return 0; // Hard disqualify
    }
  }

  // Interests overlap (0-40 points, 10 per match)
  const interestsA: string[] = userA.preferences?.interests ?? [];
  const interestsB: string[] = userB.preferences?.interests ?? [];
  const interestOverlap = interestsA.filter((i) =>
    interestsB.includes(i)
  ).length;
  score += Math.min(interestOverlap * 10, 40);

  // LookingFor overlap (20 points)
  const lookingForA: string[] = userA.preferences?.lookingFor ?? [];
  const lookingForB: string[] = userB.preferences?.lookingFor ?? [];
  if (lookingForA.some((v) => lookingForB.includes(v))) {
    score += 20;
  }

  // Distance check (apply filter, don't score)
  const distanceMax = userA.preferences?.distanceMaxKm;
  if (distanceMax && userA.location && userB.location) {
    // Simplified: if no location or distance calculation, skip check
    // In production, implement haversine distance calculation
  }

  return score;
}

/**
 * Generate matches for a specific user
 * Callable function
 */
export const generateUserMatches = onCall(
  { region: "us-central1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    try {
      console.log(`[generateUserMatches] Starting for user: ${uid}`);

      // Get user profile and preferences
      const userDoc = await db.doc(`users/${uid}`).get();
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "User profile not found");
      }

      const user = userDoc.data();
      if (!user) {
        throw new HttpsError("internal", "User data is empty");
      }

      console.log(
        `[generateUserMatches] User preferences:`,
        user.preferences
      );

      // Get already matched/liked users to exclude
      const [alreadyMatchedSnap, alreadyLikedSnap] = await Promise.all([
        db.collection(`matches/${uid}/generated`).get(),
        db.collection(`likes/${uid}/outgoing`).get(),
      ]);

      const excludeIds = new Set<string>([
        uid,
        ...alreadyMatchedSnap.docs.map((d) => d.id),
        ...alreadyLikedSnap.docs.map((d) => d.id),
      ]);

      console.log(
        `[generateUserMatches] Excluding ${excludeIds.size} users`
      );

      // Query candidate users
      // Start with basic filters
      let candidatesQuery = db.collection("users").where("isActive", "==", true);

      // Apply age filter if specified
      if (user.preferences?.ageMin) {
        candidatesQuery = candidatesQuery.where(
          "age",
          ">=",
          user.preferences.ageMin
        );
      }
      if (user.preferences?.ageMax) {
        candidatesQuery = candidatesQuery.where(
          "age",
          "<=",
          user.preferences.ageMax
        );
      }

      const candidatesSnap = await candidatesQuery.limit(200).get();
      console.log(
        `[generateUserMatches] Found ${candidatesSnap.docs.length} candidates`
      );

      // Score each candidate
      const scored = candidatesSnap.docs
        .filter((doc) => !excludeIds.has(doc.id))
        .map((doc) => {
          const other = doc.data();
          const score = computeMatchScore(user, other);
          return { uid: doc.id, score, user: other };
        })
        .filter((x) => x.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, 50); // Top 50 matches

      console.log(
        `[generateUserMatches] Generated ${scored.length} matches`
      );

      // Write to Firestore
      const batch = db.batch();
      const matchesRef = db.collection(`matches/${uid}/generated`);

      scored.forEach((m) => {
        const ref = matchesRef.doc(m.uid);
        batch.set(ref, {
          matchUserId: m.uid,
          score: m.score,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          status: "new",
          displayName: m.user.displayName || "User",
          photoUrl: m.user.photoUrl || null,
          age: m.user.age || null,
          bio: m.user.bio || "",
        });
      });

      await batch.commit();

      console.log(
        `[generateUserMatches] Completed for ${uid}: ${scored.length} matches`
      );

      return {
        success: true,
        count: scored.length,
        message: `Generated ${scored.length} matches`,
      };
    } catch (error: any) {
      console.error(`[generateUserMatches] Error:`, error);
      throw new HttpsError("internal", error.message);
    }
  }
);

/**
 * Handle user liking another user
 * Detects mutual likes and creates match
 */
export const handleLike = onCall(
  { region: "us-central1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { targetUserId } = request.data;
    if (!targetUserId || typeof targetUserId !== "string") {
      throw new HttpsError("invalid-argument", "targetUserId is required");
    }

    if (uid === targetUserId) {
      throw new HttpsError("invalid-argument", "Cannot like yourself");
    }

    try {
      console.log(`[handleLike] ${uid} -> ${targetUserId}`);

      const batch = db.batch();
      const now = admin.firestore.FieldValue.serverTimestamp();

      // Write outgoing like
      const outgoingRef = db.doc(`likes/${uid}/outgoing/${targetUserId}`);
      batch.set(outgoingRef, {
        createdAt: now,
        status: "pending",
      });

      // Write incoming like
      const incomingRef = db.doc(`likes/${targetUserId}/incoming/${uid}`);
      batch.set(incomingRef, {
        createdAt: now,
        status: "pending",
      });

      // Check if mutual like exists
      const existingLikeSnap = await db
        .doc(`likes/${uid}/incoming/${targetUserId}`)
        .get();

      const isMutualLike = existingLikeSnap.exists;

      if (isMutualLike) {
        console.log(`[handleLike] 🎉 Mutual match detected!`);

        // Get both user profiles for match history
        const [userADoc, userBDoc] = await Promise.all([
          db.doc(`users/${uid}`).get(),
          db.doc(`users/${targetUserId}`).get(),
        ]);

        const userA = userADoc.data();
        const userB = userBDoc.data();

        // Create match history for both users
        const matchA = db.doc(`matches/${uid}/history/${targetUserId}`);
        batch.set(matchA, {
          matchUserId: targetUserId,
          outcome: "mutual_like",
          createdAt: now,
          displayName: userB?.displayName || "User",
          photoUrl: userB?.photoUrl || null,
        });

        const matchB = db.doc(`matches/${targetUserId}/history/${uid}`);
        batch.set(matchB, {
          matchUserId: uid,
          outcome: "mutual_like",
          createdAt: now,
          displayName: userA?.displayName || "User",
          photoUrl: userA?.photoUrl || null,
        });

        // Update generated match status if exists
        const genMatchARef = db.doc(`matches/${uid}/generated/${targetUserId}`);
        batch.update(genMatchARef, { status: "liked" });

        const genMatchBRef = db.doc(`matches/${targetUserId}/generated/${uid}`);
        const genMatchBDoc = await genMatchBRef.get();
        if (genMatchBDoc.exists) {
          batch.update(genMatchBRef, { status: "liked" });
        }

        // Update like status
        batch.update(outgoingRef, { status: "matched" });
        batch.update(incomingRef, { status: "matched" });
      } else {
        // Update generated match status
        const genMatchRef = db.doc(`matches/${uid}/generated/${targetUserId}`);
        const genMatchDoc = await genMatchRef.get();
        if (genMatchDoc.exists) {
          batch.update(genMatchRef, { status: "liked" });
        }
      }

      await batch.commit();

      console.log(`[handleLike] Completed: ${uid} -> ${targetUserId}`);

      return {
        success: true,
        isMutualLike,
        message: isMutualLike ?
          "It's a match! 🎉" :
          "Like recorded successfully",
      };
    } catch (error: any) {
      console.error(`[handleLike] Error:`, error);
      throw new HttpsError("internal", error.message);
    }
  }
);

/**
 * Handle user passing on another user
 */
export const handlePass = onCall(
  { region: "us-central1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { targetUserId } = request.data;
    if (!targetUserId) {
      throw new HttpsError("invalid-argument", "targetUserId is required");
    }

    try {
      // Update status to passed
      await db.doc(`matches/${uid}/generated/${targetUserId}`).update({
        status: "passed",
      });

      // Move to history
      const matchDoc = await db
        .doc(`matches/${uid}/generated/${targetUserId}`)
        .get();
      if (matchDoc.exists) {
        await db.doc(`matches/${uid}/history/${targetUserId}`).set({
          ...matchDoc.data(),
          outcome: "passed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return { success: true, message: "Pass recorded" };
    } catch (error: any) {
      console.error(`[handlePass] Error:`, error);
      throw new HttpsError("internal", error.message);
    }
  }
);

/**
 * Scheduled function to refresh matches for active users
 * Runs daily at midnight
 */
export const refreshDailyMatches = onSchedule(
  {
    schedule: "0 0 * * *", // Daily at midnight
    region: "us-central1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (event) => {
    console.log("[refreshDailyMatches] Starting daily refresh");

    try {
      // Get active users
      const usersSnap = await db
        .collection("users")
        .where("isActive", "==", true)
        .limit(500) // Process in batches
        .get();

      console.log(
        `[refreshDailyMatches] Processing ${usersSnap.docs.length} users`
      );

      // Process users in parallel batches of 10
      const batchSize = 10;
      for (let i = 0; i < usersSnap.docs.length; i += batchSize) {
        const batch = usersSnap.docs.slice(i, i + batchSize);
        await Promise.all(
          batch.map(async (doc) => {
            try {
              const uid = doc.id;
              const user = doc.data();

              // Clear old generated matches (older than 7 days)
              const oldMatchesSnap = await db
                .collection(`matches/${uid}/generated`)
                .where(
                  "createdAt",
                  "<",
                  admin.firestore.Timestamp.fromMillis(
                    Date.now() - 7 * 24 * 60 * 60 * 1000
                  )
                )
                .get();

              const deleteBatch = db.batch();
              oldMatchesSnap.docs.forEach((d) => deleteBatch.delete(d.ref));
              if (oldMatchesSnap.docs.length > 0) {
                await deleteBatch.commit();
              }

              // Generate new matches
              // (Inline simplified version of generateUserMatches)
              const candidatesSnap = await db
                .collection("users")
                .where("isActive", "==", true)
                .limit(100)
                .get();

              const scored = candidatesSnap.docs
                .filter((d) => d.id !== uid)
                .map((d) => {
                  const other = d.data();
                  const score = computeMatchScore(user, other);
                  return { uid: d.id, score, user: other };
                })
                .filter((x) => x.score > 0)
                .sort((a, b) => b.score - a.score)
                .slice(0, 20);

              if (scored.length > 0) {
                const writeBatch = db.batch();
                const matchesRef = db.collection(`matches/${uid}/generated`);

                scored.forEach((m) => {
                  writeBatch.set(matchesRef.doc(m.uid), {
                    matchUserId: m.uid,
                    score: m.score,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    status: "new",
                    displayName: m.user.displayName || "User",
                    photoUrl: m.user.photoUrl || null,
                  });
                });

                await writeBatch.commit();
              }

              console.log(
                `[refreshDailyMatches] Updated ${uid}: ${scored.length} matches`
              );
            } catch (error) {
              console.error(
                `[refreshDailyMatches] Error for user ${doc.id}:`,
                error
              );
            }
          })
        );
      }

      console.log("[refreshDailyMatches] Completed");
    } catch (error) {
      console.error("[refreshDailyMatches] Fatal error:", error);
    }
  }
);
