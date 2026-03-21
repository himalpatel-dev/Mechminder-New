const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Service = sequelize.define('Service', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER, allowNull: false },
  service_name: { type: DataTypes.STRING },
  service_date: { type: DataTypes.DATEONLY, allowNull: false },
  odometer: { type: DataTypes.INTEGER },
  total_cost: { type: DataTypes.FLOAT },
  vendor_id: { type: DataTypes.INTEGER },
  template_id: { type: DataTypes.INTEGER },
  notes: { type: DataTypes.TEXT },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'tbl_services',
  timestamps: false
});

module.exports = Service;