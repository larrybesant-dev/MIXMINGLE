import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const VALID_ROLES = ["user", "admin", "superadmin"] as const;
type ValidRole = (typeof VALID_ROLES)[number];

/**
 * Callable Cloud Function — sets a Firebase Custom Claim `role` for the
 * given user UID, syncs the value to Firestore, and writes an audit log entry.
 *
 * Only users who already have the `superadmin` custom claim may call this.
 */
export const setUserRole = onCall(
  { region: "us-central1" },
  async (request) => {
    // ── Auth check ───────────────────────────────────────────────────────────
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }
    if (request.auth.token?.role !== "superadmin") {
      throw new HttpsError(
        "permission-denied",
        "Only superadmins can set roles"
      );
    }

    // ── Input validation ─────────────────────────────────────────────────────
    const { uid, role } = (request.data ?? {}) as {
      uid?: string;
      role?: string;
    };
    if (!uid || typeof uid !== "string" || uid.trim() === "") {
      throw new HttpsError("invalid-argument", "uid is required");
    }
    if (!role || !VALID_ROLES.includes(role as ValidRole)) {
      throw new HttpsError(
        "invalid-argument",
        `role must be one of: ${VALID_ROLES.join(", ")}`
      );
    }

    const callerUid = request.auth.uid;

    // ── Set Firebase Custom Claim ─────────────────────────────────────────────
    await admin.auth().setCustomUserClaims(uid, { role });

    // ── Sync role field to Firestore ──────────────────────────────────────────
    await admin.firestore().collection("users").doc(uid).update({
      role,
      roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      roleUpdatedBy: callerUid,
    });

    // ── Write immutable audit log entry ──────────────────────────────────────
    await admin.firestore().collection("admin_actions").add({
      actionType: "set_role",
      performedBy: callerUid,
      targetId: uid,
      metadata: { role },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`[setUserRole] role=${role} uid=${uid} by=${callerUid}`);
    return { success: true };
  }
);
