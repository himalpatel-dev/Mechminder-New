const db = require('../models');
const fs = require('fs');
const path = require('path');

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
          attributes: ['due_date', 'due_odometer'],
          where: { status: 'pending' },
          required: false,
          limit: 1,
          order: [['due_date', 'ASC']],
          include: [{ model: db.ServiceTemplate, attributes: ['name'] }]
        },
        { model: db.Photo, required: false }
      ],
      order: [['id', 'DESC']]
    });

    // Calculate totals for dashboard view
    const enrichedVehicles = await Promise.all(vehicles.map(async (v) => {
      const vehicleJson = v.toJSON();

      const serviceTotal = await db.Service.sum('total_cost', { where: { vehicle_id: v.id } }) || 0;
      const expenseTotal = await db.Expense.sum('total_cost', { where: { vehicle_id: v.id } }) || 0;

      return {
        ...vehicleJson,
        service_total: serviceTotal,
        expense_total: expenseTotal,
        // Helper mapping for frontend which expects 'template_name', etc.
        template_name: v.Reminders?.[0]?.ServiceTemplate?.name,
        due_date: v.Reminders?.[0]?.due_date,
        due_odometer: v.Reminders?.[0]?.due_odometer,
        photo_uri: v.Photos?.[0]?.uri
      };
    }));

    res.json(enrichedVehicles);
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
    const [updatedRows] = await db.Vehicle.update(req.body, {
      where: { id: req.params.id, user_id: req.user.id }
    });

    if (req.file) {
      await db.Photo.create({
        parent_type: 'vehicle',
        parent_id: req.params.id,
        uri: `/uploads/vehicles/${req.file.filename}`
      });
    }

    if (updatedRows === 0 && !req.file) {
      return res.status(404).json({ message: 'Vehicle not found, unauthorized, or no changes detected' });
    }

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

exports.deletePhoto = async (req, res) => {
  try {
    const photo = await db.Photo.findByPk(req.params.id);
    if (!photo) return res.status(404).json({ message: 'Photo not found' });

    // Verify ownership (simplified check for photos belonging to vehicles)
    if (photo.parent_type === 'vehicle') {
      const vehicle = await db.Vehicle.findByPk(photo.parent_id);
      if (!vehicle || vehicle.user_id !== req.user.id) {
        return res.status(403).json({ message: 'Unauthorized to delete this photo' });
      }
    }

    // Delete file from disk
    const absolutePath = path.join(__dirname, '..', photo.uri);
    if (fs.existsSync(absolutePath)) {
      fs.unlinkSync(absolutePath);
    }

    await photo.destroy();
    res.json({ message: 'Photo deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.uploadPhoto = async (req, res) => {
  try {
    const { parent_id } = req.body;
    const parent_type = req.headers['x-parent-type'] || 'vehicles';
    if (!req.file) return res.status(400).json({ error: 'No photo provided' });

    const photo = await db.Photo.create({
      parent_type: parent_type,
      parent_id: parent_id,
      uri: `/uploads/${parent_type}/${req.file.filename}`
    });

    res.status(201).json(photo);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};