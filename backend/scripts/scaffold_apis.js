const fs = require('fs');
const path = require('path');

const controllersDir = path.join(__dirname, '..', 'controllers');
const routesDir = path.join(__dirname, '..', 'routes');

if (!fs.existsSync(controllersDir)) fs.mkdirSync(controllersDir);
if (!fs.existsSync(routesDir)) fs.mkdirSync(routesDir);

const files = {
    'controllers/vehicleController.js': `
const db = require('../models');

exports.createVehicle = async (req, res) => {
  try {
    const vehicle = await db.Vehicle.create(req.body);
    res.status(201).json(vehicle);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getAllVehicles = async (req, res) => {
  try {
    const vehicles = await db.Vehicle.findAll({
      include: [
        { model: db.Reminder, where: { status: 'pending' }, limit: 1, order: [['due_date', 'ASC']] },
        { model: db.Photo, limit: 1 }
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
    const vehicle = await db.Vehicle.findByPk(req.params.id);
    if (!vehicle) return res.status(404).json({ message: 'Vehicle not found' });
    res.json(vehicle);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateVehicleOdometer = async (req, res) => {
  try {
    const { current_odometer } = req.body;
    await db.Vehicle.update(
      { current_odometer, odometer_updated_at: new Date() },
      { where: { id: req.params.id } }
    );
    res.json({ message: 'Odometer updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateVehicle = async (req, res) => {
  try {
    await db.Vehicle.update(req.body, { where: { id: req.params.id } });
    res.json({ message: 'Vehicle updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteVehicle = async (req, res) => {
  try {
    await db.Vehicle.destroy({ where: { id: req.params.id } });
    res.json({ message: 'Vehicle deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
`,
    'controllers/vendorController.js': `
const db = require('../models');

exports.createVendor = async (req, res) => {
  try {
    const vendor = await db.Vendor.create(req.body);
    res.status(201).json(vendor);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getAllVendors = async (req, res) => {
  try {
    const vendors = await db.Vendor.findAll({ order: [['name', 'ASC']] });
    res.json(vendors);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
`,
    'controllers/serviceController.js': `
const db = require('../models');

exports.createService = async (req, res) => {
  try {
    const service = await db.Service.create(req.body);
    res.status(201).json(service);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getServicesForVehicle = async (req, res) => {
  try {
    const services = await db.Service.findAll({
      where: { vehicle_id: req.params.vehicleId },
      include: [db.Vendor, db.ServiceItem],
      order: [['created_at', 'DESC']]
    });
    res.json(services);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getServiceById = async (req, res) => {
  try {
    const service = await db.Service.findByPk(req.params.id, {
      include: [db.Vendor, db.ServiceItem]
    });
    if (!service) return res.status(404).json({ message: 'Service not found' });
    res.json(service);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createServiceItem = async (req, res) => {
  try {
    const item = await db.ServiceItem.create({ ...req.body, service_id: req.params.id });
    res.status(201).json(item);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
`,
    'controllers/reminderController.js': `
const db = require('../models');

exports.createReminder = async (req, res) => {
  try {
    const reminder = await db.Reminder.create(req.body);
    res.status(201).json(reminder);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getRemindersForVehicle = async (req, res) => {
  try {
    const reminders = await db.Reminder.findAll({
      where: { vehicle_id: req.params.vehicleId, status: 'pending' },
      include: [db.ServiceTemplate],
      order: [['due_date', 'ASC']]
    });
    res.json(reminders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteReminder = async (req, res) => {
  try {
    await db.Reminder.destroy({ where: { id: req.params.id } });
    res.json({ message: 'Reminder deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
`,
    'controllers/expenseController.js': `
const db = require('../models');

exports.createExpense = async (req, res) => {
  try {
    const expense = await db.Expense.create(req.body);
    res.status(201).json(expense);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getExpensesForVehicle = async (req, res) => {
  try {
    const expenses = await db.Expense.findAll({
      where: { vehicle_id: req.params.vehicleId },
      order: [['service_date', 'DESC']]
    });
    res.json(expenses);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
`,
    'routes/index.js': `
const express = require('express');
const router = express.Router();

const vehicleController = require('../controllers/vehicleController');
const vendorController = require('../controllers/vendorController');
const serviceController = require('../controllers/serviceController');
const reminderController = require('../controllers/reminderController');
const expenseController = require('../controllers/expenseController');

// Vehicles
router.post('/vehicles', vehicleController.createVehicle);
router.get('/vehicles', vehicleController.getAllVehicles);
router.get('/vehicles/:id', vehicleController.getVehicleById);
router.put('/vehicles/:id', vehicleController.updateVehicle);
router.put('/vehicles/:id/odometer', vehicleController.updateVehicleOdometer);
router.delete('/vehicles/:id', vehicleController.deleteVehicle);

// Vendors
router.post('/vendors', vendorController.createVendor);
router.get('/vendors', vendorController.getAllVendors);

// Services
router.post('/services', serviceController.createService);
router.get('/services/:id', serviceController.getServiceById);
router.post('/services/:id/items', serviceController.createServiceItem);
router.get('/vehicles/:vehicleId/services', serviceController.getServicesForVehicle);

// Reminders
router.post('/reminders', reminderController.createReminder);
router.get('/vehicles/:vehicleId/reminders', reminderController.getRemindersForVehicle);
router.delete('/reminders/:id', reminderController.deleteReminder);

// Expenses
router.post('/expenses', expenseController.createExpense);
router.get('/vehicles/:vehicleId/expenses', expenseController.getExpensesForVehicle);

module.exports = router;
`
};

for (const [filename, content] of Object.entries(files)) {
    fs.writeFileSync(path.join(__dirname, '..', filename), content.trim());
}

console.log('APIs generated successfully!');
