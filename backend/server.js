const express = require('express');
const cors = require('cors');
require('dotenv').config();

const db = require('./models');
const routes = require('./routes');

const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Swagger setup
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));


// Request logger
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    if (req.headers['x-user-uid'] || req.headers['x-fcm-token']) {
        console.log(`  > UID: ${req.headers['x-user-uid']}, FCM: ${req.headers['x-fcm-token'] ? 'YES' : 'NO'}`);
    }
    next();
});

// Serve static files from the uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API Routes
app.use('/api', routes);

// Basic Route
app.get('/', (req, res) => {
    res.send('MechMinder API with Sequelize is running...');
});

// Test DB Connection Route
app.get('/api/test-db', async (req, res) => {
    try {
        await db.sequelize.authenticate();
        res.json({ success: true, message: 'Connected to PostgreSQL via Sequelize successfully!' });
    } catch (err) {
        console.error('Unable to connect to the database:', err.message);
        res.status(500).json({ success: false, message: 'Database connection failed.', error: err.message });
    }
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', async () => {
    console.log(`Server is running on port ${PORT}`);
    try {
        await db.sequelize.authenticate();
        console.log('Database connection established successfully.');
        // Sync models
        await db.sequelize.sync({ alter: true });
        console.log('All models synchronized successfully.');
    } catch (error) {
        console.error('Unable to connect to the database or sync models:', error.message);
    }
});
