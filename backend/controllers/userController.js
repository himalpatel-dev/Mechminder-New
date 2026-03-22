const User = require('../models/User');

// Update FCM Token with Change Counter
exports.updateFcmToken = async (req, res) => {
    try {
        const { firebase_uid, fcm_token } = req.body;

        if (!firebase_uid || !fcm_token) {
            return res.status(400).json({ error: 'firebase_uid and fcm_token are required' });
        }

        // Find or Create User
        let [user, created] = await User.findOrCreate({
            where: { firebase_uid },
            defaults: { fcm_token, fcm_token_change_count: 0 }
        });

        if (!created) {
            // If the token is different, update it and increment the counter
            if (user.fcm_token !== fcm_token) {
                user.fcm_token = fcm_token;
                user.fcm_token_change_count += 1;
                await user.save();
            }
        }

        res.json({ success: true, user });
    } catch (error) {
        console.error('Error updating FCM token:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Link Purchase ID to User Identity
exports.linkPurchase = async (req, res) => {
    try {
        const { firebase_uid, purchase_id, fcm_token } = req.body;

        if (!firebase_uid || !purchase_id) {
            return res.status(400).json({ error: 'firebase_uid and purchase_id are required' });
        }

        // 1. Check if this purchase_id is already assigned to someone else (Migration Case)
        let existingUserByPurchase = await User.findOne({ where: { purchase_id } });

        if (existingUserByPurchase) {
            // If it belongs to a DIFFERENT firebase_uid, we might want to "merge" or "reassign"
            // For now, let's update the existing user record with the new firebase_uid to link them
            if (existingUserByPurchase.firebase_uid !== firebase_uid) {
                // If the user already exists in DB with new UID, we might have a conflict.
                // For simplicity, we update the existing record that has the PURCHASE to use the NEW firebase_uid.
                 existingUserByPurchase.firebase_uid = firebase_uid;
                 if (fcm_token) existingUserByPurchase.fcm_token = fcm_token;
                 await existingUserByPurchase.save();
                 return res.json({ success: true, message: 'Re-linked old purchase to new device', user: existingUserByPurchase });
            }
        }

        // 2. Otherwise, update the current user with this purchase_id
        let user = await User.findOne({ where: { firebase_uid } });

        if (!user) {
            user = await User.create({ firebase_uid, purchase_id, fcm_token });
        } else {
            user.purchase_id = purchase_id;
            if (fcm_token) user.fcm_token = fcm_token;
            await user.save();
        }

        res.json({ success: true, user });
    } catch (error) {
        console.error('Error linking purchase:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
