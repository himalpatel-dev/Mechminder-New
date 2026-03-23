const db = require('../models');

exports.createService = async (req, res) => {
  try {
    const service = await db.Service.create(req.body, { include: [db.ServiceItem] });
    res.status(201).json(service);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateService = async (req, res) => {
  const t = await db.sequelize.transaction();
  try {
    const service = await db.Service.findByPk(req.params.id, { transaction: t });
    if (!service) {
      await t.rollback();
      return res.status(404).json({ message: 'Service not found' });
    }

    await service.update(req.body, { transaction: t });

    if (req.body.ServiceItems && Array.isArray(req.body.ServiceItems)) {
      // Delete existing items
      await db.ServiceItem.destroy({
        where: { service_id: req.params.id },
        transaction: t
      });

      // Create new items
      for (const item of req.body.ServiceItems) {
        await db.ServiceItem.create(
          { ...item, service_id: req.params.id },
          { transaction: t }
        );
      }
    }

    await t.commit();
    res.json(service);
  } catch (error) {
    await t.rollback();
    res.status(400).json({ error: error.message });
  }
};

exports.deleteService = async (req, res) => {
  try {
    const service = await db.Service.findByPk(req.params.id);
    if (!service) return res.status(404).json({ message: 'Service not found' });
    await service.destroy();
    res.json({ message: 'Service deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
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
      include: [db.Vendor, db.ServiceItem, { model: db.Photo, as: 'Photos' }]
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