import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * storiesCleanup — runs every hour and hard-deletes story documents
 * whose `expiresAt` timestamp is in the past.
 *
 * Also removes the associated Storage media file when a `storageRef`
 * field is present on the document.
 */
export const storiesCleanup = onSchedule(
  {
    schedule: "every 60 minutes",
    region: "us-central1",
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (_event) => {
    const db = admin.firestore();
    const storage = admin.storage();
    const now = admin.firestore.Timestamp.now();

    const snap = await db
      .collection("stories")
      .where("expiresAt", "<=", now)
      .limit(400)
      .get();

    if (snap.empty) {
      logger.info("[storiesCleanup] No expired stories found.");
      return;
    }

    logger.info(`[storiesCleanup] Deleting ${snap.size} expired stories.`);

    const batches: admin.firestore.WriteBatch[] = [];
    let current = db.batch();
    let count = 0;

    const storageDeletes: Promise<void>[] = [];

    for (const doc of snap.docs) {
      // Try to delete the Storage file
      const storageRef = doc.data().storageRef as string | undefined;
      if (storageRef) {
        storageDeletes.push(
          storage
            .bucket()
            .file(storageRef)
            .delete()
            .then(() => { /* void */ })
            .catch((err) =>
              logger.warn(
                `[storiesCleanup] Could not delete file ${storageRef}: ${err}`
              )
            )
        );
      }

      current.delete(doc.ref);
      count++;

      // Firestore batches are limited to 500 operations
      if (count % 499 === 0) {
        batches.push(current);
        current = db.batch();
      }
    }

    batches.push(current);

    await Promise.all([
      ...batches.map((b) => b.commit()),
      ...storageDeletes,
    ]);

    logger.info(`[storiesCleanup] Done — deleted ${snap.size} stories.`);
  }
);
