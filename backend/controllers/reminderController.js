const db = require('../models');

exports.createReminder = async (req, res) => {
  try {
    const reminder = await db.Reminder.create(req.body);
    res.status(201).json(reminder);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.completeRemindersByTemplate = async (req, res) => {
  try {
    const { vehicle_id, template_id, service_id } = req.body;
    await db.Reminder.update(
      { status: 'completed', completed_by_service_id: service_id },
      { where: { vehicle_id, template_id, status: 'pending' } }
    );
    res.json({ message: 'Reminders completed' });
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

exports.updateReminder = async (req, res) => {
  try {
    const reminder = await db.Reminder.findByPk(req.params.id);
    if (!reminder) return res.status(404).json({ message: 'Reminder not found' });
    await reminder.update(req.body);
    res.json(reminder);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};