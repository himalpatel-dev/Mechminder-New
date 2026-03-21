const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Reminder = sequelize.define('Reminder', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER, allowNull: false },
  template_id: { type: DataTypes.INTEGER },
  service_id: { type: DataTypes.INTEGER },
  due_date: { type: DataTypes.DATEONLY },
  due_odometer: { type: DataTypes.INTEGER },
  notes: { type: DataTypes.TEXT },
  recurrence_rule: { type: DataTypes.STRING },
  lead_time_days: { type: DataTypes.INTEGER },
  lead_time_km: { type: DataTypes.INTEGER },
  last_notified_at: { type: DataTypes.DATE },
  status: { type: DataTypes.STRING, allowNull: false, defaultValue: 'pending' },
  completed_by_service_id: { type: DataTypes.INTEGER }
}, {
  tableName: 'tbl_reminders',
  timestamps: false
});

module.exports = Reminder;