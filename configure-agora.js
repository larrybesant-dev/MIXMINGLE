const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const APP_ID = 'ec1b578586d24976a89d787d9ee4d5c7';
const APP_CERTIFICATE = '79a3e92a657042d08c3c26a26d1e70b6';

console.log('🔥 Configuring Agora in Firestore...');
console.log(`App ID: ${APP_ID}`);
console.log(`Certificate: ${APP_CERTIFICATE}`);

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
