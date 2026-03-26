const admin = require('firebase-admin');
const path = require('path');

try {
    const serviceAccount = require('./mechminder-serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized successfully.');
} catch (error) {
    console.error('Firebase Admin initialization failed. Please ensure config/serviceAccountKey.json exists.');
    console.error('Error details:', error.message);
}

module.exports = admin;
