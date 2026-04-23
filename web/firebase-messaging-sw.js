/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.4/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.4/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyB8KXjs0EqnJQdbaKVkX9nwsj07RK2ffM4',
  authDomain: 'mix-and-mingle-v2.firebaseapp.com',
  projectId: 'mix-and-mingle-v2',
  storageBucket: 'mix-and-mingle-v2.firebasestorage.app',
  messagingSenderId: '980846719834',
  appId: '1:980846719834:web:fbcdf5051c55d691077963',
  measurementId: 'G-BN784E6ZJY',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  const notification = payload && payload.notification ? payload.notification : {};
  const title = notification.title || 'MixVy';
  const options = {
    body: notification.body || '',
    icon: './icons/Icon-192.png',
    data: payload && payload.data ? payload.data : {},
  };

  self.registration.showNotification(title, options);
});
