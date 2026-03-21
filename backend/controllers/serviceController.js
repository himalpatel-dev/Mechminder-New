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