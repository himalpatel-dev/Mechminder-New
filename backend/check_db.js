const { Sequelize, DataTypes } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
    process.env.DB_NAME,
    process.env.DB_USER,
    process.env.DB_PASSWORD,
    {
        host: process.env.DB_HOST,
        dialect: 'postgres',
        port: process.env.DB_PORT || 5432,
        logging: false,
    }
);

async function check() {
    try {
        const table = await sequelize.getQueryInterface().describeTable('tbl_users');
        console.log('Columns in tbl_users:', Object.keys(table));
        const users = await sequelize.query('SELECT * FROM tbl_users LIMIT 5', { type: Sequelize.QueryTypes.SELECT });
        console.log('Sample Users:', JSON.stringify(users, null, 2));
    } catch (e) {
        console.error('Error:', e.message);
    } finally {
        await sequelize.close();
    }
}

check();
