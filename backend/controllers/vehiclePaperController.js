const db = require('../models');

// GET /api/vehicles/:vehicleId/papers
exports.getPapersForVehicle = async (req, res) => {
    try {
        const papers = await db.VehiclePaper.findAll({
            where: { vehicle_id: req.params.vehicleId },
            order: [['paper_expiry_date', 'ASC']]
        });
        res.json(papers);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// POST /api/papers
exports.createPaper = async (req, res) => {
    try {
        const paper = await db.VehiclePaper.create(req.body);
        res.status(201).json(paper);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// PUT /api/papers/:id
exports.updatePaper = async (req, res) => {
    try {
        const paper = await db.VehiclePaper.findByPk(req.params.id);
        if (!paper) return res.status(404).json({ message: 'Paper not found' });
        await paper.update(req.body);
        res.json(paper);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// DELETE /api/papers/:id
exports.deletePaper = async (req, res) => {
    try {
        const paper = await db.VehiclePaper.findByPk(req.params.id);
        if (!paper) return res.status(404).json({ message: 'Paper not found' });
        await paper.destroy();
        res.status(204).send();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
