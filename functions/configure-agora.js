/**
 * One-time script to configure Agora credentials in Firestore
 * Run with: node configure-agora.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function configureAgora() {
  try {
    console.log('📝 Adding Agora credentials to Firestore...');

    await db.collection('config').doc('agora').set({
      appId: 'ec1b578586d24976a89d787d9ee4d5c7',
      appCertificate: '79a3e92a657042d08c3c26a26d1e70b6',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Agora credentials configured successfully!');
    console.log('');
    console.log('You can view them in Firebase Console:');
    console.log('https://console.firebase.google.com/project/mix-and-mingle-v2/firestore/data/config/agora');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

configureAgora();
