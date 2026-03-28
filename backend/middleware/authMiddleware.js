const db = require('../models');

const identifyUser = async (req, res, next) => {
    // Standardize header lookup (Express lowercases everything)
    const firebaseUid = req.headers['x-user-uid'];
    const deviceId = req.headers['x-device-id'];
    const fcmToken = req.headers['x-fcm-token'];

    if (!firebaseUid) {
        return res.status(401).json({ message: 'Device/User identification (X-User-Uid) is required.' });
    }

    try {
        let user = null;

        // 1. Identity Restore Case: Try to find by Device ID first (per request: relay on device id first)
        if (deviceId && deviceId !== '') {
            user = await db.User.findOne({ where: { device_id: deviceId } });
        }

        // 2. Try Firebase UID if device ID not found or already linked
        if (!user) {
            user = await db.User.findOne({ where: { firebase_uid: firebaseUid } });
        }

        // 3. Re-link logic (Handle re-installs on same device)
        if (user && user.firebase_uid !== firebaseUid) {
            console.log(`[Auth Restore] Re-linking UID ${firebaseUid} to record ${user.id} via Device ID`);
            user.firebase_uid = firebaseUid;
            await user.save();
        }

        // 4. Create new user if still not found
        if (!user) {
            user = await db.User.create({ 
                firebase_uid: firebaseUid,
                device_id: deviceId,
                fcm_token: fcmToken
            });
        } else {
            // 5. Update markers if they are missing (handles older users getting device_id now)
            let changed = false;
            if (fcmToken && user.fcm_token !== fcmToken) {
                user.fcm_token = fcmToken;
                changed = true;
            }
            if (deviceId && user.device_id !== deviceId) {
                user.device_id = deviceId;
                changed = true;
            }
            if (changed) await user.save();
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
