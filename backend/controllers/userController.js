const User = require('../models/User');
const admin = require('../config/firebase');


// Update FCM Token with Change Counter
exports.updateFcmToken = async (req, res) => {
    try {
        const { firebase_uid, fcm_token, trial_start_date, purchase_id, device_id } = req.body;

        if (!firebase_uid || !fcm_token) {
            return res.status(400).json({ error: 'firebase_uid and fcm_token are required' });
        }

        // 1. Identity Restore Stack (Prioritize persistent keys)
        // Check 1: Purchase ID (Best)
        // Check 2: Device ID (Local device context)
        let existingUser = null;
        if (purchase_id) {
            existingUser = await User.findOne({ where: { purchase_id } });
        }
        if (!existingUser && device_id) {
            existingUser = await User.findOne({ where: { device_id } });
        }

        if (existingUser) {
            // Re-link to existing account if UID matches OR it's a new UID reinstall
            if (existingUser.firebase_uid !== firebase_uid) {
                console.log(`[Identity Restore] Linking new UID ${firebase_uid} via ${purchase_id ? 'Purchase' : 'Device'} ID`);
                existingUser.firebase_uid = firebase_uid;
                existingUser.fcm_token = fcm_token;
                existingUser.fcm_token_change_count += 1;
                if (trial_start_date && !existingUser.trial_start_date) {
                    existingUser.trial_start_date = trial_start_date;
                }
                if (device_id && !existingUser.device_id) {
                    existingUser.device_id = device_id;
                }
                await existingUser.save();
                return res.json({ success: true, message: 'Account restored', user: existingUser });
            }
        }

        // 2. Standard Find or Create by UID
        let [user, created] = await User.findOrCreate({
            where: { firebase_uid },
            defaults: { fcm_token, trial_start_date, purchase_id, device_id, fcm_token_change_count: 0 }
        });

        // Update fields if they changed or were missing
        let changed = false;
        
        if (user.fcm_token !== fcm_token) {
            user.fcm_token = fcm_token;
            user.fcm_token_change_count += 1;
            changed = true;
        }

        if (trial_start_date && !user.trial_start_date) {
            user.trial_start_date = trial_start_date;
            changed = true;
        }

        // Update identity markers if they were missing
        if (purchase_id && !user.purchase_id) {
            user.purchase_id = purchase_id;
            changed = true;
        }
        if (device_id && !user.device_id) {
            user.device_id = device_id;
            changed = true;
        }

        if (changed) await user.save();

        res.json({ success: true, user });
    } catch (error) {
        console.error('Error updating FCM token:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Link Purchase ID to User Identity
exports.linkPurchase = async (req, res) => {
    try {
        const { firebase_uid, purchase_id, fcm_token, trial_start_date } = req.body;

        if (!firebase_uid || !purchase_id) {
            return res.status(400).json({ error: 'firebase_uid and purchase_id are required' });
        }

        // 1. Check if this purchase_id is already assigned to someone else (Migration Case)
        let existingUserByPurchase = await User.findOne({ where: { purchase_id } });

        if (existingUserByPurchase) {
            // If it belongs to a DIFFERENT firebase_uid, we might want to "merge" or "reassign"
            if (existingUserByPurchase.firebase_uid !== firebase_uid) {
                 existingUserByPurchase.firebase_uid = firebase_uid;
                 if (fcm_token) existingUserByPurchase.fcm_token = fcm_token;
                 if (trial_start_date && !existingUserByPurchase.trial_start_date) {
                    existingUserByPurchase.trial_start_date = trial_start_date;
                 }
                 await existingUserByPurchase.save();
                 return res.json({ success: true, message: 'Re-linked old purchase to new device', user: existingUserByPurchase });
            }
        }

        // 2. Otherwise, update the current user with this purchase_id
        let user = await User.findOne({ where: { firebase_uid } });

        if (!user) {
            user = await User.create({ firebase_uid, purchase_id, fcm_token, trial_start_date });
        } else {
            user.purchase_id = purchase_id;
            if (fcm_token) user.fcm_token = fcm_token;
            if (trial_start_date && !user.trial_start_date) {
                user.trial_start_date = trial_start_date;
            }
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

        // 4. Increment notification_count for all users who have these tokens and the send was successful
        // We can do a bulk update since we already filtered users
        const successUserIds = [];
        response.responses.forEach((res, index) => {
            if (res.success) {
                // If the message was sent successfully to this token, we count it
                successUserIds.push(users[index].id);
            }
        });

        if (successUserIds.length > 0) {
            await User.increment('notification_count', {
                where: { id: successUserIds }
            });
        }

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

// Send Daily Reminders to all users with pending tasks
exports.sendDailyReminders = async (req, res) => {
    try {
        const { User, Vehicle, Reminder, VehiclePaper, ServiceTemplate } = require('../models');
        const { Op } = require('sequelize');
        const today = new Date().toISOString().split('T')[0];

        // 1. Fetch all users who have an fcm_token
        const users = await User.findAll({
            where: {
                fcm_token: { [Op.ne]: null, [Op.ne]: '' }
            },
            include: [{
                model: Vehicle,
                include: [
                    { 
                      model: Reminder, 
                      where: { status: 'pending' }, 
                      required: false,
                      include: [{ model: ServiceTemplate }]
                    },
                    { 
                      model: VehiclePaper, 
                      required: false 
                    }
                ]
            }]
        });

        let totalNotificationsSent = 0;
        const notificationPromises = [];

        for (const user of users) {
            const notificationsForThisUser = [];

            if (!user.Vehicles) continue;

            for (const vehicle of user.Vehicles) {
                const vehicleName = `${vehicle.make} ${vehicle.model}`;

                // Check Reminders
                if (vehicle.Reminders) {
                    for (const reminder of vehicle.Reminders) {
                        let isDue = false;
                        if (reminder.due_date === today) isDue = true;
                        // Odometer check (current server data)
                        if (reminder.due_odometer && vehicle.current_odometer >= reminder.due_odometer) isDue = true;

                        if (isDue) {
                            const serviceName = reminder.ServiceTemplate ? reminder.ServiceTemplate.name : (reminder.notes || 'Service');
                            notificationsForThisUser.push({
                                title: 'Service Due!',
                                body: `Your "${serviceName}" for ${vehicleName} is due today!`,
                                data: { type: 'reminder', id: reminder.id.toString(), vehicleId: vehicle.id.toString() }
                            });
                        }
                    }
                }

                // Check Papers
                if (vehicle.VehiclePapers) {
                    for (const paper of vehicle.VehiclePapers) {
                        if (paper.paper_expiry_date === today) {
                            notificationsForThisUser.push({
                                title: 'Paper Expiring!',
                                body: `Your ${paper.paper_type} for ${vehicleName} expires today!`,
                                data: { type: 'paper', id: paper.id.toString(), vehicleId: vehicle.id.toString() }
                            });
                        }
                    }
                }
            }

            // Send actual notifications for this user
            if (notificationsForThisUser.length > 0) {
                for (const notify of notificationsForThisUser) {
                    const message = {
                        notification: { title: notify.title, body: notify.body },
                        data: notify.data,
                        token: user.fcm_token
                    };
                    
                    notificationPromises.push(
                        admin.messaging().send(message)
                            .then(async () => {
                                totalNotificationsSent++;
                                await user.increment('notification_count');
                            })
                            .catch(err => console.error(`Failed to notify user ${user.id}:`, err))
                    );
                }
            }
        }

        await Promise.all(notificationPromises);

        res.json({
            success: true,
            total_users_checked: users.length,
            total_notifications_sent: totalNotificationsSent
        });

    } catch (error) {
        console.error('Error in daily reminders:', error);
        res.status(500).json({ error: 'Failed to process daily reminders' });
    }
};

