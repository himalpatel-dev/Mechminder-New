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
        const data = { ...req.body, user_id: req.user.id };
        if (req.file) {
            data.file_path = `/uploads/vehicles/${req.file.filename}`;
        }
        const document = await db.Document.create(data);
        res.status(201).json(document);
    } catch (error) {
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
            data.file_path = `/uploads/vehicles/${req.file.filename}`;
        }

        await document.update(data);
        res.json(document);
    } catch (error) {
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
