/* eslint-disable no-console */
/**
 * One-time script: set membershipLevel = 'beta' on every user document.
 *
 * Dry-run (default – shows counts, writes nothing):
 *   node functions/scripts/backfill-beta-membership.js
 *
 * Live run:
 *   node functions/scripts/backfill-beta-membership.js --apply
 */

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const BETA_LEVEL = "beta";
const PAGE_SIZE = 500;

async function runBackfill({apply = false} = {}) {
  const collection = db.collection("users");
  let updatedCount = 0;
  let skippedCount = 0;
  let scannedCount = 0;
  let lastDoc = null;

  console.log(`Mode: ${apply ? "LIVE (writing)" : "DRY-RUN (no writes)"}`);

  while (true) {
    let query = collection
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) break;

    const batch = db.batch();
    let pendingBatchUpdates = 0;

    for (const doc of snapshot.docs) {
      scannedCount += 1;
      const data = doc.data() || {};

      if (data.membershipLevel === BETA_LEVEL) {
        skippedCount += 1;
        continue;
      }

      if (apply) {
        batch.update(doc.ref, {membershipLevel: BETA_LEVEL});
        pendingBatchUpdates += 1;
      }

      updatedCount += 1;
    }

    if (apply && pendingBatchUpdates > 0) {
      await batch.commit();
    }

    console.log(
      `  Page scanned ${snapshot.size} docs | running totals → ` +
      `scanned=${scannedCount} toUpdate=${updatedCount} skipped=${skippedCount}`,
    );

    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    if (snapshot.size < PAGE_SIZE) break;
  }

  console.log("\n=== Done ===");
  console.log(`  Scanned  : ${scannedCount}`);
  console.log(`  ${apply ? "Updated" : "Would update"}: ${updatedCount}`);
  console.log(`  Skipped  : ${skippedCount} (already beta)`);
}

const apply = process.argv.includes("--apply");
runBackfill({apply}).catch((err) => {
  console.error(err);
  process.exit(1);
});
