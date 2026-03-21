const db = require('../models');
const ServiceTemplate = db.ServiceTemplate;

exports.createTemplate = async (req, res) => {
    try {
        const data = { ...req.body, user_id: req.user.id };
        const template = await ServiceTemplate.create(data);
        res.status(201).json(template);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.getAllTemplates = async (req, res) => {
    try {
        const templates = await ServiceTemplate.findAll({
            where: { user_id: req.user.id }
        });
        res.json(templates);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.updateTemplate = async (req, res) => {
    try {
        const [updated] = await ServiceTemplate.update(req.body, {
            where: { id: req.params.id, user_id: req.user.id }
        });
        if (updated) {
            const updatedTemplate = await ServiceTemplate.findOne({
                where: { id: req.params.id, user_id: req.user.id }
            });
            return res.json(updatedTemplate);
        }
        res.status(404).json({ error: 'Template not found or unauthorized' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.deleteTemplate = async (req, res) => {
    try {
        const deleted = await ServiceTemplate.destroy({
            where: { id: req.params.id, user_id: req.user.id }
        });
        if (deleted) return res.status(204).send();
        res.status(404).json({ error: 'Template not found or unauthorized' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
