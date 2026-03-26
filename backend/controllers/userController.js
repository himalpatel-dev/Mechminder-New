const User = require('../models/User');
const admin = require('../config/firebase');


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

// Send Test Notification to all users with valid FCM tokens
exports.sendTestNotification = async (req, res) => {
    try {
        const { title, body, data } = req.body;

        if (!title || !body) {
            return res.status(400).json({ error: 'title and body are required' });
        }

        // 1. Fetch all users who have an fcm_token
        const users = await User.findAll({
            where: {
                fcm_token: {
                    [require('sequelize').Op.ne]: null,
                    [require('sequelize').Op.ne]: ''
                }
            }
        });

        if (!users || users.length === 0) {
            return res.status(404).json({ message: 'No users found with FCM tokens' });
        }

        const tokens = users.map(user => user.fcm_token);
        console.log(`Sending notification to ${tokens.length} users...`);

        // 2. Prepare the multicast message
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: data || {},
            tokens: tokens,
        };

        // 3. Send Notification via Firebase Admin
        const response = await admin.messaging().sendEachForMulticast(message);

        console.log('FCM Response:', response);

        res.json({
            success: true,
            total_sent: response.successCount,
            total_failed: response.failureCount,
            responses: response.responses
        });

    } catch (error) {
        console.error('Error sending test notification:', error);
        res.status(500).json({ error: 'Failed to send notification', details: error.message });
    }
};

