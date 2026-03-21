const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const ServiceItem = sequelize.define('ServiceItem', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  service_id: { type: DataTypes.INTEGER, allowNull: false },
  name: { type: DataTypes.STRING, allowNull: false },
  qty: { type: DataTypes.FLOAT },
  unit_cost: { type: DataTypes.FLOAT },
  total_cost: { type: DataTypes.FLOAT },
  template_id: { type: DataTypes.INTEGER }
}, {
  tableName: 'tbl_service_items',
  timestamps: false
});

module.exports = ServiceItem;