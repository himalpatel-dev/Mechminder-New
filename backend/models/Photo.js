const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Photo = sequelize.define('Photo', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  parent_type: { type: DataTypes.STRING, allowNull: false },
  parent_id: { type: DataTypes.INTEGER, allowNull: false },
  uri: { type: DataTypes.STRING, allowNull: false }
}, {
  tableName: 'tbl_photos',
  timestamps: false
});

module.exports = Photo;