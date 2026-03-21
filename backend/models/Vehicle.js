const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Vehicle = sequelize.define('Vehicle', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  make: { type: DataTypes.STRING, allowNull: false },
  model: { type: DataTypes.STRING, allowNull: false },
  variant: { type: DataTypes.STRING },
  purchase_date: { type: DataTypes.DATEONLY },
  fuel_type: { type: DataTypes.STRING, allowNull: false },
  vehicle_color: { type: DataTypes.STRING },
  reg_no: { type: DataTypes.STRING },
  owner_name: { type: DataTypes.STRING, allowNull: false },
  initial_odometer: { type: DataTypes.INTEGER },
  current_odometer: { type: DataTypes.INTEGER },
  odometer_updated_at: { type: DataTypes.DATE },
  user_id: { type: DataTypes.INTEGER, allowNull: true } // Can be allowNull: true first for existing data
}, {
  tableName: 'tbl_vehicles',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Vehicle;