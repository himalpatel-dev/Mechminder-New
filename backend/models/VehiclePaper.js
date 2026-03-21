const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const VehiclePaper = sequelize.define('VehiclePaper', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER, allowNull: false },
  paper_type: { type: DataTypes.STRING, allowNull: false },
  reference_no: { type: DataTypes.STRING },
  provider_name: { type: DataTypes.STRING },
  description: { type: DataTypes.TEXT },
  cost: { type: DataTypes.FLOAT },
  paper_expiry_date: { type: DataTypes.DATEONLY },
  file_path: { type: DataTypes.STRING },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'tbl_vehicle_papers',
  timestamps: false
});

module.exports = VehiclePaper;