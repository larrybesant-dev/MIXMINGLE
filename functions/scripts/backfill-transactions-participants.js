/* eslint-disable no-console */
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

function normalizeParticipants(senderId, receiverId, existingParticipants) {
  const values = [];

  if (Array.isArray(existingParticipants)) {
    for (const value of existingParticipants) {
      if (typeof value === "string" && value.trim()) {
        values.push(value.trim());
      }
    }
  }

  if (typeof senderId === "string" && senderId.trim()) {
    values.push(senderId.trim());
  }

  if (typeof receiverId === "string" && receiverId.trim()) {
    values.push(receiverId.trim());
  }

  return [...new Set(values)];
}

async function runBackfill({apply = false, pageSize = 500} = {}) {
  const collection = db.collection("transactions");
  let updatedCount = 0;
  let skippedCount = 0;
  let scannedCount = 0;
  let lastDoc = null;

  while (true) {
    let query = collection.orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    let pendingBatchUpdates = 0;

    for (const doc of snapshot.docs) {
      scannedCount += 1;
      const data = doc.data() || {};

      const senderId = data.senderId;
      const receiverId = data.receiverId;
      const nextParticipants = normalizeParticipants(senderId, receiverId, data.participants);

      const currentParticipants = Array.isArray(data.participants) ? data.participants : [];
      const currentNormalized = normalizeParticipants(null, null, currentParticipants);

      const isAlreadyValid =
        nextParticipants.length === currentNormalized.length &&
        nextParticipants.every((value, idx) => value === currentNormalized[idx]);

      if (isAlreadyValid || nextParticipants.length === 0) {
        skippedCount += 1;
        continue;
      }

      updatedCount += 1;
      if (apply) {
        batch.update(doc.ref, {participants: nextParticipants});
        pendingBatchUpdates += 1;
      }
    }

    if (apply && pendingBatchUpdates > 0) {
      await batch.commit();
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  return {scannedCount, updatedCount, skippedCount, apply};
}

function parseArgs(argv) {
  return {
    apply: argv.includes("--apply"),
    pageSize: (() => {
      const match = argv.find((arg) => arg.startsWith("--page-size="));
      if (!match) return 500;
      const value = Number(match.split("=")[1]);
      return Number.isFinite(value) && value > 0 ? Math.floor(value) : 500;
    })(),
  };
}

(async () => {
  try {
    const args = parseArgs(process.argv.slice(2));
    const result = await runBackfill(args);
    console.log(JSON.stringify(result, null, 2));
    if (!args.apply) {
      console.log("Dry-run completed. Re-run with --apply to persist updates.");
    }
  } catch (error) {
    console.error("Backfill failed:", error);
    process.exitCode = 1;
  }
})();
