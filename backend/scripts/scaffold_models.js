const fs = require('fs');
const path = require('path');

const modelsDir = path.join(__dirname, '..', 'models');
if (!fs.existsSync(modelsDir)) {
    fs.mkdirSync(modelsDir);
}

const templates = {
    'Vehicle.js': `
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Vehicle = sequelize.define('Vehicle', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  make: { type: DataTypes.STRING, allowNull: false },
  model: { type: DataTypes.STRING, allowNull: false },
  variant: { type: DataTypes.STRING },
  purchase_date: { type: DataTypes.DATEONLY },
  fuel_type: { type: DataTypes.STRING, allowNull: false },
  vehicle_color: { type: DataTypes.STRING },
  reg_no: { type: DataTypes.STRING },
  owner_name: { type: DataTypes.STRING, allowNull: false },
  initial_odometer: { type: DataTypes.INTEGER },
  current_odometer: { type: DataTypes.INTEGER },
  odometer_updated_at: { type: DataTypes.DATE }
}, {
  tableName: 'tbl_vehicles',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Vehicle;
`,
    'Vendor.js': `
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Vendor = sequelize.define('Vendor', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  phone: { type: DataTypes.STRING },
  address: { type: DataTypes.STRING }
}, {
  tableName: 'tbl_vendors',
  timestamps: false
});

module.exports = Vendor;
`,
    'Service.js': `
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Service = sequelize.define('Service', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER, allowNull: false },
  service_name: { type: DataTypes.STRING },
  service_date: { type: DataTypes.DATEONLY, allowNull: false },
  odometer: { type: DataTypes.INTEGER },
  total_cost: { type: DataTypes.FLOAT },
  vendor_id: { type: DataTypes.INTEGER },
  template_id: { type: DataTypes.INTEGER },
  notes: { type: DataTypes.TEXT },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'tbl_services',
  timestamps: false
});

module.exports = Service;
`,
    'ServiceItem.js': `
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
`,
    'ServiceTemplate.js': `
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const ServiceTemplate = sequelize.define('ServiceTemplate', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false, unique: true },
  interval_days: { type: DataTypes.INTEGER },
  interval_km: { type: DataTypes.INTEGER },
  vehicle_type: { type: DataTypes.STRING }
}, {
  tableName: 'tbl_service_templates',
  timestamps: false
});

module.exports = ServiceTemplate;
`,
    'Reminder.js': `
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Reminder = sequelize.define('Reminder', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER, allowNull: false },
  template_id: { type: DataTypes.INTEGER },
  service_id: { type: DataTypes.INTEGER },
  due_date: { type: DataTypes.DATEONLY },
  due_odometer: { type: DataTypes.INTEGER },
  notes: { type: DataTypes.TEXT },
  recurrence_rule: { type: DataTypes.STRING },
  lead_time_days: { type: DataTypes.INTEGER },
  lead_time_km: { type: DataTypes.INTEGER },
  last_notified_at: { type: DataTypes.DATE },
  status: { type: DataTypes.STRING, allowNull: false, defaultValue: 'pending' },
  completed_by_service_id: { type: DataTypes.INTEGER }
}, {
  tableName: 'tbl_reminders',
  timestamps: false
});

module.exports = Reminder;
`,
    'Expense.js': `
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
`,
    'Photo.js': `
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
`,
    'VehiclePaper.js': `
const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const VehiclePaper = sequelize.define('VehiclePaper', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  vehicle_id: { type: DataTypes.INTEGER, allowNull: false },
  paper_type: { type: DataTypes.STRING, allowNull: false },
  reference_no: { type: DataTypes.STRING },
  provider_name: { type: DataTypes.STRING },
  description: { type: DataTypes.TEXT },
  cost: { type: DataTypes.FLOAT },
  paper_expiry_date: { type: DataTypes.DATEONLY },
  file_path: { type: DataTypes.STRING },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'tbl_vehicle_papers',
  timestamps: false
});

module.exports = VehiclePaper;
`,
    'Document.js': `
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
`,
    'TodoList.js': `
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
`,
    'index.js': `
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

// Setup Associations

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
  TodoList
};
`
};

for (const [filename, content] of Object.entries(templates)) {
    fs.writeFileSync(path.join(modelsDir, filename), content.trim());
}

console.log('Models generated successfully with tbl_ prefix!');
