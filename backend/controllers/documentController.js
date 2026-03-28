const db = require('../models');

// GET /api/documents
exports.getAllDocuments = async (req, res) => {
    try {
        const documents = await db.Document.findAll({
            where: { user_id: req.user.id },
            include: [{ model: db.Vehicle, attributes: ['make', 'model'], required: false }]
        });
        res.json(documents);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// GET /api/vehicles/:vehicleId/documents
exports.getDocumentsForVehicle = async (req, res) => {
    try {
        const documents = await db.Document.findAll({
            where: { vehicle_id: req.params.vehicleId, user_id: req.user.id }
        });
        res.json(documents);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// GET /api/documents/:id
exports.getDocumentById = async (req, res) => {
    try {
        const document = await db.Document.findOne({
            where: { id: req.params.id, user_id: req.user.id }
        });
        if (!document) return res.status(404).json({ message: 'Document not found' });
        res.json(document);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// POST /api/documents
exports.createDocument = async (req, res) => {
    try {
        console.log('[Document Create] Body:', req.body);
        console.log('[Document Create] File:', req.file ? req.file.filename : 'MISSING');
        console.log('[Document Create] Headers (type):', req.headers['x-parent-type']);

        const data = { ...req.body, user_id: req.user.id };
        
        if (req.file) {
            // Standardize path to use forward slashes for URL compatibility
            const parentType = req.headers['x-parent-type'] || 'vehicles';
            data.file_path = `/uploads/${parentType}/${req.file.filename}`;
        }

        if (!data.file_path) {
            console.error('[Document Create] Rejected: No file uploaded');
            return res.status(400).json({ error: 'File is required' });
        }

        const document = await db.Document.create(data);
        console.log('[Document Create] SUCCESS:', document.id);
        res.status(201).json(document);
    } catch (error) {
        console.error('[Document Create ERROR]:', error.message);
        res.status(400).json({ error: error.message });
    }
};

// PUT /api/documents/:id
exports.updateDocument = async (req, res) => {
    try {
        const document = await db.Document.findOne({
            where: { id: req.params.id, user_id: req.user.id }
        });
        if (!document) return res.status(404).json({ message: 'Document not found' });

        const data = { ...req.body };
        if (req.file) {
            const parentType = req.headers['x-parent-type'] || 'vehicles';
            data.file_path = `/uploads/${parentType}/${req.file.filename}`;
        }

        await document.update(data);
        res.json(document);
    } catch (error) {
        console.error('[Document Update ERROR]:', error.message);
        res.status(400).json({ error: error.message });
    }
};

// DELETE /api/documents/:id
exports.deleteDocument = async (req, res) => {
    try {
        const document = await db.Document.findOne({
            where: { id: req.params.id, user_id: req.user.id }
        });
        if (!document) return res.status(404).json({ message: 'Document not found' });
        await document.destroy();
        res.status(204).send();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
