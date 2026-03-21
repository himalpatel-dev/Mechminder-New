const db = require('../models');

const identifyUser = async (req, res, next) => {
    const firebaseUid = req.headers['x-user-uid'] || req.headers['X-User-Uid'];

    if (!firebaseUid) {
        // For now, if no UID is provided, we can either block or allow it (optional).
        // Let's block it to ensure data separation from the start.
        return res.status(401).json({ message: 'Device/User identification (X-User-Uid) is required.' });
    }

    try {
        // Find or Create the user in our database
        const [user, created] = await db.User.findOrCreate({
            where: { firebase_uid: firebaseUid }
        });

        // Attach user information to the request
        req.user = user;
        next();
    } catch (error) {
        console.error('Identification Middleware Error:', error.message);
        res.status(500).json({ error: 'Failed to identify device/user' });
    }
};

module.exports = { identifyUser };
