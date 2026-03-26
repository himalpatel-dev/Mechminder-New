const db = require('../models');
const { Op } = require('sequelize');


exports.backupData = async (req, res) => {
    try {
        const { vehicles, services, service_items, expenses, vendors, service_templates, reminders, photos, vehicle_papers, documents, todolist } = req.body;
        const user_id = req.user.id;

        await db.sequelize.transaction(async (t) => {
            // Overwrite strategy: Clear all user-specific data first
            // Note: Cascade should handle most deletions if associations are set up correctly.
            await db.Vehicle.destroy({ where: { user_id }, transaction: t });
            
            // Map for storing old local IDs to new backend IDs
            const vehicleMap = {};
            const serviceMap = {};
            const vendorMap = {};
            const templateMap = {};

            // 1. Vendors
            if (vendors) {
                for (let v of vendors) {
                    const oldId = v._id;
                    delete v._id;
                    const vendor = await db.Vendor.create({ ...v }, { transaction: t });
                    vendorMap[oldId] = vendor.id;
                }
            }

            // 2. Templates
            if (service_templates) {
                for (let st of service_templates) {
                    const oldId = st._id;
                    delete st._id;
                    const template = await db.ServiceTemplate.create({ ...st }, { transaction: t });
                    templateMap[oldId] = template.id;
                }
            }

            // 3. Vehicles
            if (vehicles) {
                for (let v of vehicles) {
                    const oldId = v._id;
                    delete v._id;
                    const vehicle = await db.Vehicle.create({ ...v, user_id }, { transaction: t });
                    vehicleMap[oldId] = vehicle.id;
                }
            }

            // 4. Services
            if (services) {
                for (let s of services) {
                    const oldId = s._id;
                    delete s._id;
                    s.vehicle_id = vehicleMap[s.vehicle_id];
                    if (s.vendor_id) s.vendor_id = vendorMap[s.vendor_id];
                    if (s.template_id) s.template_id = templateMap[s.template_id];
                    const service = await db.Service.create({ ...s }, { transaction: t });
                    serviceMap[oldId] = service.id;
                }
            }

            // 5. Service Items
            if (service_items) {
                for (let si of service_items) {
                    delete si._id;
                    si.service_id = serviceMap[si.service_id];
                    await db.ServiceItem.create({ ...si }, { transaction: t });
                }
            }

            // 6. Expenses
            if (expenses) {
                for (let e of expenses) {
                    delete e._id;
                    e.vehicle_id = vehicleMap[e.vehicle_id];
                    await db.Expense.create({ ...e }, { transaction: t });
                }
            }

            // 7. Reminders
            if (reminders) {
                for (let r of reminders) {
                    delete r._id;
                    r.vehicle_id = vehicleMap[r.vehicle_id];
                    if (r.template_id) r.template_id = templateMap[r.template_id];
                    if (r.service_id) r.service_id = serviceMap[r.service_id];
                    await db.Reminder.create({ ...r }, { transaction: t });
                }
            }

            // 8. TodoList
            if (todolist) {
                for (let td of todolist) {
                    delete td._id;
                    td.vehicle_id = vehicleMap[td.vehicle_id];
                    await db.TodoList.create({ ...td }, { transaction: t });
                }
            }

            // 9. Photos
            if (photos) {
                for (let p of photos) {
                    delete p._id;
                    // Note: Photos might link to vehicles, services, or expenses
                    if (p.parent_type === 'vehicle') p.parent_id = vehicleMap[p.parent_id];
                    else if (p.parent_type === 'service') p.parent_id = serviceMap[p.parent_id];
                    // Add other types if needed
                    await db.Photo.create({ ...p }, { transaction: t });
                }
            }

            // 10. Vehicle Papers
            if (vehicle_papers) {
                for (let vp of vehicle_papers) {
                    delete vp._id;
                    vp.vehicle_id = vehicleMap[vp.vehicle_id];
                    await db.VehiclePaper.create({ ...vp }, { transaction: t });
                }
            }

            // 11. Documents
            if (documents) {
                for (let doc of documents) {
                    delete doc._id;
                    if (doc.vehicle_id) doc.vehicle_id = vehicleMap[doc.vehicle_id];
                    await db.Document.create({ ...doc }, { transaction: t });
                }
            }
        });

        res.json({ success: true, message: 'Backup successfully saved to cloud' });
    } catch (error) {
        console.error('Backup Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.restoreData = async (req, res) => {
    try {
        const user_id = req.user.id;

        // Fetch everything for the user
        const vehicles = await db.Vehicle.findAll({ where: { user_id } });
        const vehicleIds = vehicles.map(v => v.id);

        const services = await db.Service.findAll({ where: { vehicle_id: vehicleIds } });
        const serviceIds = services.map(s => s.id);
        
        const service_items = await db.ServiceItem.findAll({ where: { service_id: serviceIds } });
        const expenses = await db.Expense.findAll({ where: { vehicle_id: vehicleIds } });
        const reminders = await db.Reminder.findAll({ where: { vehicle_id: vehicleIds } });
        const todolist = await db.TodoList.findAll({ where: { vehicle_id: vehicleIds } });
        const vehicle_papers = await db.VehiclePaper.findAll({ where: { vehicle_id: vehicleIds } });
        const documents = await db.Document.findAll({ where: { user_id } });
        const photos = await db.Photo.findAll({ 
            where: { 
                [Op.or]: [
                    { parent_type: 'vehicle', parent_id: vehicleIds },
                    { parent_type: 'service', parent_id: serviceIds }
                ]
            } 
        });


        // We also need shared/user-specific vendors and templates if they are linked
        const vendors = await db.Vendor.findAll({ /* determine if specific to user */ });
        const service_templates = await db.ServiceTemplate.findAll(); // Usually these are global/predefined

        const backup = {
            vehicles,
            services,
            service_items,
            expenses,
            vendors,
            service_templates,
            reminders,
            photos,
            vehicle_papers,
            documents,
            todolist
        };

        res.json(backup);
    } catch (error) {
        console.error('Restore Error:', error);
        res.status(500).json({ error: error.message });
    }
};

