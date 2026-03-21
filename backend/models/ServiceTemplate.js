const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const ServiceTemplate = sequelize.define('ServiceTemplate', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  interval_days: { type: DataTypes.INTEGER },
  interval_km: { type: DataTypes.INTEGER },
  vehicle_type: { type: DataTypes.STRING },
  user_id: { type: DataTypes.INTEGER, allowNull: true } // Support multi-device isolation
}, {
  tableName: 'tbl_service_templates',
  timestamps: false
});

module.exports = ServiceTemplate;