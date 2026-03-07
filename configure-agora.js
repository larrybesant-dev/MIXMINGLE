const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const APP_ID = process.env.AGORA_APP_ID;
const APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;

if (!APP_ID || !APP_CERTIFICATE) {
  console.error('Missing required env vars: AGORA_APP_ID and AGORA_APP_CERTIFICATE');
  process.exit(1);
}

console.log('🔥 Configuring Agora in Firestore...');
console.log(`App ID: ${APP_ID}`);
console.log('Certificate: [REDACTED]');

db.collection('config').doc('agora').set({
  appId: APP_ID,
  appCertificate: APP_CERTIFICATE,
  updatedAt: admin.firestore.FieldValue.serverTimestamp()
})
  .then(() => {
    console.log('✅ Agora configuration saved to Firestore');
    console.log('\n📝 Next steps:');
    console.log('1. Deploy functions: firebase deploy --only functions');
    console.log('2. Build & deploy app: flutter build web --release && firebase deploy --only hosting');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
