const express = require('express');
const router = express.Router();

const vehicleController = require('../controllers/vehicleController');
const vendorController = require('../controllers/vendorController');
const serviceController = require('../controllers/serviceController');
const reminderController = require('../controllers/reminderController');
const expenseController = require('../controllers/expenseController');
const authController = require('../controllers/authController');

const { identifyUser } = require('../middleware/authMiddleware');
const userController = require('../controllers/userController');
const backupController = require('../controllers/backupController');


// Apply user identification middleware to all routes
router.use(identifyUser);



// User Profile & FCM Management

router.post('/users/fcm-token', userController.updateFcmToken);
router.post('/users/purchase-link', userController.linkPurchase);
router.post('/users/test-notification', userController.sendTestNotification);

// Cloud Backup & Restore
router.post('/backup', backupController.backupData);
router.get('/restore', backupController.restoreData);




// Vehicles
const upload = require('../middleware/uploadMiddleware');
router.post('/vehicles', upload.single('photo'), vehicleController.createVehicle);
router.get('/vehicles', vehicleController.getAllVehicles);
router.get('/vehicles/:id', vehicleController.getVehicleById);
router.put('/vehicles/:id', upload.single('photo'), vehicleController.updateVehicle);
router.put('/vehicles/:id/odometer', vehicleController.updateVehicleOdometer);
router.delete('/vehicles/:id', vehicleController.deleteVehicle);
router.delete('/photos/:id', vehicleController.deletePhoto);
router.post('/photos', upload.single('photo'), vehicleController.uploadPhoto);

// Vendors
router.post('/vendors', vendorController.createVendor);
router.get('/vendors', vendorController.getAllVendors);
router.put('/vendors/:id', vendorController.updateVendor);
router.delete('/vendors/:id', vendorController.deleteVendor);

// Services
router.post('/services', serviceController.createService);
router.get('/services/:id', serviceController.getServiceById);
router.put('/services/:id', serviceController.updateService);
router.delete('/services/:id', serviceController.deleteService);
router.post('/services/:id/items', serviceController.createServiceItem);
router.get('/vehicles/:vehicleId/services', serviceController.getServicesForVehicle);

// Reminders
router.post('/reminders', reminderController.createReminder);
router.get('/vehicles/:vehicleId/reminders', reminderController.getRemindersForVehicle);
router.put('/reminders/complete-by-template', reminderController.completeRemindersByTemplate);
router.put('/reminders/:id', reminderController.updateReminder);
router.delete('/reminders/:id', reminderController.deleteReminder);

// Expenses
router.post('/expenses', expenseController.createExpense);
router.get('/vehicles/:vehicleId/expenses', expenseController.getExpensesForVehicle);
router.put('/expenses/:id', expenseController.updateExpense);
router.delete('/expenses/:id', expenseController.deleteExpense);

// Todos
const todoController = require('../controllers/todoController');
router.get('/todos/pending', todoController.getAllPendingTodos);
router.get('/todos/completed', todoController.getAllCompletedTodos);
router.post('/todos', todoController.createTodo);
router.put('/todos/:id/status', todoController.updateTodoStatus);
router.delete('/todos/:id', todoController.deleteTodo);

// Service Templates (Auto Parts)
const templateController = require('../controllers/templateController');
router.get('/templates', templateController.getAllTemplates);
router.post('/templates', templateController.createTemplate);
router.put('/templates/:id', templateController.updateTemplate);
router.delete('/templates/:id', templateController.deleteTemplate);

// Vehicle Papers
const paperController = require('../controllers/vehiclePaperController');
router.get('/vehicles/:vehicleId/papers', paperController.getPapersForVehicle);
router.post('/papers', paperController.createPaper);
router.put('/papers/:id', paperController.updatePaper);
router.delete('/papers/:id', paperController.deletePaper);

// Documents
const documentController = require('../controllers/documentController');
router.get('/documents', documentController.getAllDocuments);
router.get('/vehicles/:vehicleId/documents', documentController.getDocumentsForVehicle);
router.get('/documents/:id', documentController.getDocumentById);
router.post('/documents', upload.single('document'), documentController.createDocument);
router.put('/documents/:id', upload.single('document'), documentController.updateDocument);
router.delete('/documents/:id', documentController.deleteDocument);

module.exports = router;