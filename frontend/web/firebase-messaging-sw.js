// Firebase Messaging Service Worker
// Handles background/terminated push notifications on web.

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'AIzaSyBQL1EdE7aEwRJh2SjaVsIz5XDCi-sIm4Q',
  authDomain:        'hicampus-acd31.firebaseapp.com',
  projectId:         'hicampus-acd31',
  storageBucket:     'hicampus-acd31.appspot.com',
  messagingSenderId: '771163168949',
  appId:             '1:771163168949:web:c8b7bca16d97b0a500defc',
});

const messaging = firebase.messaging();

// Background message handler — shown by the browser when the tab is hidden/closed.
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'HiCampus';
  const body  = payload.notification?.body  ?? '';
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    data: payload.data,
  });
});
