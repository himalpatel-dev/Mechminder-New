const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const TodoList = sequelize.define('TodoList', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER, allowNull: false },
  part_name: { type: DataTypes.STRING, allowNull: false },
  notes: { type: DataTypes.TEXT },
  status: { type: DataTypes.STRING, allowNull: false, defaultValue: 'pending' },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updated_at: { type: DataTypes.DATE }
}, {
  tableName: 'tbl_todolist',
  timestamps: false
});

module.exports = TodoList;