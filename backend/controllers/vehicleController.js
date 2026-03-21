const db = require('../models');

exports.createVehicle = async (req, res) => {
  try {
    const data = { ...req.body, user_id: req.user.id };
    const vehicle = await db.Vehicle.create(data);

    if (req.file) {
      await db.Photo.create({
        parent_type: 'vehicle',
        parent_id: vehicle.id,
        uri: `/uploads/vehicles/${req.file.filename}`
      });
    }

    res.status(201).json(vehicle);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getAllVehicles = async (req, res) => {
  try {
    const vehicles = await db.Vehicle.findAll({
      where: { user_id: req.user.id },
      include: [
        {
          model: db.Reminder,
          where: { status: 'pending' },
          required: false,
          limit: 1,
          order: [['due_date', 'ASC']],
          include: [{ model: db.ServiceTemplate }]
        },
        { model: db.Photo, required: false }
      ],
      order: [['id', 'DESC']]
    });
    res.json(vehicles);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getVehicleById = async (req, res) => {
  try {
    const vehicle = await db.Vehicle.findOne({
      where: { id: req.params.id, user_id: req.user.id },
      include: [
        { model: db.Photo, required: false },
        { model: db.Reminder, required: false, include: [{ model: db.ServiceTemplate }] }
      ]
    });
    if (!vehicle) return res.status(404).json({ message: 'Vehicle not found or unauthorized' });
    res.json(vehicle);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateVehicleOdometer = async (req, res) => {
  try {
    const { current_odometer } = req.body;
    const [updated] = await db.Vehicle.update(
      { current_odometer, odometer_updated_at: new Date() },
      { where: { id: req.params.id, user_id: req.user.id } }
    );
    if (!updated) return res.status(404).json({ message: 'Vehicle not found or unauthorized' });
    res.json({ message: 'Odometer updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateVehicle = async (req, res) => {
  try {
    const [updated] = await db.Vehicle.update(req.body, {
      where: { id: req.params.id, user_id: req.user.id }
    });
    if (!updated) return res.status(404).json({ message: 'Vehicle not found or unauthorized' });
    res.json({ message: 'Vehicle updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteVehicle = async (req, res) => {
  try {
    const deleted = await db.Vehicle.destroy({
      where: { id: req.params.id, user_id: req.user.id }
    });
    if (!deleted) return res.status(404).json({ message: 'Vehicle not found or unauthorized' });
    res.json({ message: 'Vehicle deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};