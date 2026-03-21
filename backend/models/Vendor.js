const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Vendor = sequelize.define('Vendor', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  phone: { type: DataTypes.STRING },
  address: { type: DataTypes.STRING },
  user_id: { type: DataTypes.INTEGER, allowNull: true } // Support multi-device isolation
}, {
  tableName: 'tbl_vendors',
  timestamps: false
});

module.exports = Vendor;