#!/usr/bin/env node

/**
 * Updates Firestore config/agora document with Agora credentials
 * Usage: node update-firestore-config.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, 'firebase-adminsdk.json');

try {
  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
  });
} catch (error) {
  console.error('❌ Error: Could not load firebase-adminsdk.json');
  console.error('Please ensure you have downloaded the service account key from Firebase Console');
  process.exit(1);
}

const db = admin.firestore();

async function updateAgoraConfig() {
  try {
    console.log('🔧 Updating Firestore config/agora with Agora credentials...');

    await db.collection('config').doc('agora').set({
      appId: 'ec1b578586d24976a89d787d9ee4d5c7',
      appCertificate: '79a3e92a657042d08c3c26a26d1e70b6',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Successfully updated Agora config in Firestore!');
    console.log('   AppId: ec1b578586d24976a89d787d9ee4d5c7');
    console.log('   AppCertificate: 79a3e92a657042d08c3c26a26d1e70b6');

    await admin.app().delete();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error updating Firestore:', error.message);
    process.exit(1);
  }
}

updateAgoraConfig();
