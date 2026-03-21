const jwt = require('jsonwebtoken');

exports.generateAnonymousToken = (req, res) => {
    // Extract a device identifier, app ID or just assign a random one.
    const { deviceId } = req.body;

    if (!deviceId) {
        return res.status(400).json({ error: 'deviceId is required to generate a token.' });
    }

    // Create token with device ID and an arbitrary "anonymous" role.
    const payload = { deviceId, role: 'anonymous' };

    // Expiration is extremely long since there's no real user base re-authentication.
    // E.g., valid for 10 years (or completely omit expiresIn to make it non-expiring)
    const token = jwt.sign(
        payload,
        process.env.JWT_SECRET || 'mechminder_secret_key',
        { expiresIn: '3650d' }
    );

    res.json({ token, deviceId });
};
