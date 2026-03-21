const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Expense = sequelize.define('Expense', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER, allowNull: false },
  service_date: { type: DataTypes.DATEONLY, allowNull: false },
  category: { type: DataTypes.STRING, allowNull: false },
  total_cost: { type: DataTypes.FLOAT },
  notes: { type: DataTypes.TEXT }
}, {
  tableName: 'tbl_expenses',
  timestamps: false
});

module.exports = Expense;