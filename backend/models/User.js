const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const User = sequelize.define('User', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    firebase_uid: { type: DataTypes.STRING, unique: true, allowNull: false },
    fcm_token: { type: DataTypes.STRING, allowNull: true },
    purchase_id: { type: DataTypes.STRING, unique: true, allowNull: true },
    fcm_token_change_count: { type: DataTypes.INTEGER, defaultValue: 0 }
}, {
    tableName: 'tbl_users',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
});

module.exports = User;
