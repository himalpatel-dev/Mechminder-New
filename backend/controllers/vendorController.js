const db = require('../models');

exports.createVendor = async (req, res) => {
  try {
    const data = { ...req.body, user_id: req.user.id };
    const vendor = await db.Vendor.create(data);
    res.status(201).json(vendor);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getAllVendors = async (req, res) => {
  try {
    const vendors = await db.Vendor.findAll({
      where: { user_id: req.user.id },
      order: [['name', 'ASC']]
    });
    res.json(vendors);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateVendor = async (req, res) => {
  try {
    const [updated] = await db.Vendor.update(req.body, {
      where: { id: req.params.id, user_id: req.user.id }
    });
    if (!updated) return res.status(404).json({ message: 'Vendor not found or unauthorized' });
    res.json({ message: 'Vendor updated successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteVendor = async (req, res) => {
  try {
    const deleted = await db.Vendor.destroy({
      where: { id: req.params.id, user_id: req.user.id }
    });
    if (!deleted) return res.status(404).json({ message: 'Vendor not found or unauthorized' });
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};