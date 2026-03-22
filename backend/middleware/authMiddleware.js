const db = require('../models');

const identifyUser = async (req, res, next) => {
    // Standardize header lookup (Express lowercases everything)
    const firebaseUid = req.headers['x-user-uid'];
    const fcmToken = req.headers['x-fcm-token'];

    if (!firebaseUid) {
        console.log(`[Auth] FAILED: Missing UID header. Available headers: ${Object.keys(req.headers).join(', ')}`);
        return res.status(401).json({ message: 'Device/User identification (X-User-Uid) is required.' });
    }

    console.log(`[Auth] UID: ${firebaseUid}, FCM: ${fcmToken ? 'Present' : 'NULL'}`);

    try {
        // Find or Create the user in our database
        const [user, created] = await db.User.findOrCreate({
            where: { firebase_uid: firebaseUid }
        });

        // If FCM token is provided and different from the one in DB, update it
        if (fcmToken && user.fcm_token !== fcmToken) {
            console.log(`[Auth] Updating FCM token for user ${user.id}`);
            await user.update({ fcm_token: fcmToken });
        }

        // Attach user information to the request
        req.user = user;
        next();
    } catch (error) {
        console.error('Identification Middleware Error:', error.message);
        res.status(500).json({ error: 'Failed to identify device/user' });
    }
};

module.exports = { identifyUser };
