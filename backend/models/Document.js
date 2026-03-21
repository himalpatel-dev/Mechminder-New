const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Document = sequelize.define('Document', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER },
  doc_type: { type: DataTypes.STRING },
  description: { type: DataTypes.TEXT },
  file_path: { type: DataTypes.STRING, allowNull: false }
}, {
  tableName: 'tbl_documents',
  timestamps: false
});

module.exports = Document;