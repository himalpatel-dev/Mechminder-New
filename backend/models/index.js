const sequelize = require('../config/db');

const Vehicle = require('./Vehicle');
const Vendor = require('./Vendor');
const Service = require('./Service');
const ServiceItem = require('./ServiceItem');
const ServiceTemplate = require('./ServiceTemplate');
const Reminder = require('./Reminder');
const Expense = require('./Expense');
const Photo = require('./Photo');
const VehiclePaper = require('./VehiclePaper');
const Document = require('./Document');
const TodoList = require('./TodoList');
const User = require('./User');

// Setup Associations

User.hasMany(Vehicle, { foreignKey: 'user_id', onDelete: 'CASCADE' });
Vehicle.belongsTo(User, { foreignKey: 'user_id' });

User.hasMany(Document, { foreignKey: 'user_id', onDelete: 'CASCADE' });
Document.belongsTo(User, { foreignKey: 'user_id' });

Vehicle.hasMany(Service, { foreignKey: 'vehicle_id', onDelete: 'CASCADE' });
Service.belongsTo(Vehicle, { foreignKey: 'vehicle_id' });

Vendor.hasMany(Service, { foreignKey: 'vendor_id', onDelete: 'SET NULL' });
Service.belongsTo(Vendor, { foreignKey: 'vendor_id' });

Service.hasMany(ServiceItem, { foreignKey: 'service_id', onDelete: 'CASCADE' });
ServiceItem.belongsTo(Service, { foreignKey: 'service_id' });

Vehicle.hasMany(Reminder, { foreignKey: 'vehicle_id', onDelete: 'CASCADE' });
Reminder.belongsTo(Vehicle, { foreignKey: 'vehicle_id' });

ServiceTemplate.hasMany(Reminder, { foreignKey: 'template_id', onDelete: 'SET NULL' });
Reminder.belongsTo(ServiceTemplate, { foreignKey: 'template_id' });

Vehicle.hasMany(Expense, { foreignKey: 'vehicle_id', onDelete: 'CASCADE' });
Expense.belongsTo(Vehicle, { foreignKey: 'vehicle_id' });

Vehicle.hasMany(VehiclePaper, { foreignKey: 'vehicle_id', onDelete: 'CASCADE' });
VehiclePaper.belongsTo(Vehicle, { foreignKey: 'vehicle_id' });

Vehicle.hasMany(Document, { foreignKey: 'vehicle_id', onDelete: 'CASCADE' });
Document.belongsTo(Vehicle, { foreignKey: 'vehicle_id' });

Vehicle.hasMany(TodoList, { foreignKey: 'vehicle_id', onDelete: 'CASCADE' });
TodoList.belongsTo(Vehicle, { foreignKey: 'vehicle_id' });

// Polymorphic association for Photos
Vehicle.hasMany(Photo, { foreignKey: 'parent_id', constraints: false, scope: { parent_type: 'vehicle' } });
Photo.belongsTo(Vehicle, { foreignKey: 'parent_id', constraints: false });

Service.hasMany(Photo, { foreignKey: 'parent_id', constraints: false, as: 'Photos', scope: { parent_type: 'service' } });
Photo.belongsTo(Service, { foreignKey: 'parent_id', constraints: false });

Expense.hasMany(Photo, { foreignKey: 'parent_id', constraints: false, as: 'Photos', scope: { parent_type: 'expense' } });
Photo.belongsTo(Expense, { foreignKey: 'parent_id', constraints: false });

module.exports = {
  sequelize,
  Vehicle,
  Vendor,
  Service,
  ServiceItem,
  ServiceTemplate,
  Reminder,
  Expense,
  Photo,
  VehiclePaper,
  Document,
  TodoList,
  User
};