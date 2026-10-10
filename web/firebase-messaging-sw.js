// Firebase Cloud Messaging Service Worker for Capeonn Web

importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBqIh9rbrLk_ON5POLhSXh-D4aFKLP7YaA",
  authDomain: "ajprojects-e3b2a.firebaseapp.com",
  projectId: "ajprojects-e3b2a",
  storageBucket: "ajprojects-e3b2a.firebasestorage.app",
  messagingSenderId: "777521057911",
  appId: "1:777521057911:web:3b1874d7a865f0ef49f672",
  measurementId: "G-0PRGZ0R037"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);
  const notificationTitle = payload.notification?.title || payload.data?.title || 'Capeonn Notification';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.message || '',
    icon: '/favicon.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
