/**
 * @swagger
 * components:
 *   schemas:
 *     Vehicle:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         make:
 *           type: string
 *         model:
 *           type: string
 *         variant:
 *           type: string
 *         purchase_date:
 *           type: string
 *           format: date
 *         fuel_type:
 *           type: string
 *         vehicle_color:
 *           type: string
 *         reg_no:
 *           type: string
 *         owner_name:
 *           type: string
 *         initial_odometer:
 *           type: integer
 *         current_odometer:
 *           type: integer
 *
 *     Vendor:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         name:
 *           type: string
 *         phone:
 *           type: string
 *         address:
 *           type: string
 *
 *     Service:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         vehicle_id:
 *           type: integer
 *         service_name:
 *           type: string
 *         service_date:
 *           type: string
 *           format: date
 *         odometer:
 *           type: integer
 *         total_cost:
 *           type: number
 *         vendor_id:
 *           type: integer
 *         template_id:
 *           type: integer
 *         notes:
 *           type: string
 *         ServiceItems:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/ServiceItem'
 *
 *     ServiceItem:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         name:
 *           type: string
 *         qty:
 *           type: number
 *         unit_cost:
 *           type: number
 *         total_cost:
 *           type: number
 *         template_id:
 *           type: integer
 *
 *     Reminder:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         vehicle_id:
 *           type: integer
 *         template_id:
 *           type: integer
 *         title:
 *           type: string
 *         due_date:
 *           type: string
 *           format: date
 *         due_odometer:
 *           type: integer
 *         status:
 *           type: string
 *           enum: [pending, completed]
 *
 *     Expense:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         vehicle_id:
 *           type: integer
 *         expense_date:
 *           type: string
 *           format: date
 *         amount:
 *           type: number
 *         category:
 *           type: string
 *         description:
 *           type: string
 *
 *     Todo:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         task:
 *           type: string
 *         status:
 *           type: string
 *           enum: [pending, completed]
 *
 *     ServiceTemplate:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         name:
 *           type: string
 *         description:
 *           type: string
 *         interval_months:
 *           type: integer
 *         interval_km:
 *           type: integer
 *
 *     VehiclePaper:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         vehicle_id:
 *           type: integer
 *         type:
 *           type: string
 *         expiry_date:
 *           type: string
 *           format: date
 *         description:
 *           type: string
 *
 *     Document:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           readOnly: true
 *         vehicle_id:
 *           type: integer
 *         user_id:
 *           type: integer
 *           readOnly: true
 *         doc_type:
 *           type: string
 *         description:
 *           type: string
 *         file_path:
 *           type: string
 *
 * /users/fcm-token:
 *   post:
 *     summary: Update FCM token for the user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fcm_token:
 *                 type: string
 *     responses:
 *       200:
 *         description: FCM Token updated
 *
 * /users/purchase-link:
 *   post:
 *     summary: Link purchase with user account
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               purchase_id:
 *                 type: string
 *     responses:
 *       200:
 *         description: Purchase linked
 *
 * /vehicles:
 *   get:
 *     summary: Get all vehicles for current user
 *     tags: [Vehicles]
 *     responses:
 *       200:
 *         description: List of vehicles
 *   post:
 *     summary: Create a new vehicle (supports multi-part with photo)
 *     tags: [Vehicles]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               make: {type: string}
 *               model: {type: string}
 *               variant: {type: string}
 *               purchase_date: {type: string, format: date}
 *               fuel_type: {type: string}
 *               reg_no: {type: string}
 *               owner_name: {type: string}
 *               initial_odometer: {type: integer}
 *               current_odometer: {type: integer}
 *               photo: {type: string, format: binary}
 *     responses:
 *       201:
 *         description: Created
 * /vehicles/{id}:
 *   get:
 *     summary: Get vehicle details
 *     tags: [Vehicles]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       200:
 *         description: Vehicle details
 *   put:
 *     summary: Update vehicle details
 *     tags: [Vehicles]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Vehicle' }
 *     responses:
 *       200:
 *         description: Updated
 *   delete:
 *     summary: Remove vehicle
 *     tags: [Vehicles]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       204:
 *         description: Deleted
 * /vehicles/{id}/odometer:
 *   put:
 *     summary: Update only the odometer for a vehicle
 *     tags: [Vehicles]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties: { current_odometer: {type: integer} }
 *     responses:
 *       200:
 *         description: Updated
 *
 * /vendors:
 *   get:
 *     summary: Get all vendors
 *     tags: [Vendors]
 *     responses:
 *       200:
 *         description: List of vendors
 *   post:
 *     summary: Create vendor
 *     tags: [Vendors]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Vendor' }
 *     responses:
 *       201:
 *         description: Created
 * /vendors/{id}:
 *   put:
 *     summary: Update vendor
 *     tags: [Vendors]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Vendor' }
 *     responses:
 *       200:
 *         description: Updated
 *   delete:
 *     summary: Remove vendor
 *     tags: [Vendors]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       204:
 *         description: Deleted
 *
 * /services:
 *   post:
 *     summary: Create a new service record
 *     tags: [Services]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Service' }
 *     responses:
 *       201:
 *         description: Created
 * /services/{id}:
 *   get:
 *     summary: Get service record details
 *     tags: [Services]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       200:
 *         description: Service details
 * /services/{id}/items:
 *   post:
 *     summary: Add service items to a service record
 *     tags: [Services]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/ServiceItem' }
 *     responses:
 *       201:
 *         description: Item added
 * /vehicles/{vehicleId}/services:
 *   get:
 *     summary: Get service history for a vehicle
 *     tags: [Services]
 *     parameters:
 *       - in: path
 *         name: vehicleId
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       200:
 *         description: Service history
 *
 * /reminders:
 *   post:
 *     summary: Create a new reminder
 *     tags: [Reminders]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Reminder' }
 *     responses:
 *       201:
 *         description: Created
 * /reminders/{id}:
 *   put:
 *     summary: Update reminder
 *     tags: [Reminders]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Reminder' }
 *     responses:
 *       200:
 *         description: Updated
 *   delete:
 *     summary: Remove reminder
 *     tags: [Reminders]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       204:
 *         description: Deleted
 * /vehicles/{vehicleId}/reminders:
 *   get:
 *     summary: Get all reminders for a vehicle
 *     tags: [Reminders]
 *     parameters:
 *       - in: path
 *         name: vehicleId
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       200:
 *         description: Reminders list
 *
 * /expenses:
 *   post:
 *     summary: Create a new expense record
 *     tags: [Expenses]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Expense' }
 *     responses:
 *       201:
 *         description: Created
 * /expenses/{id}:
 *   put:
 *     summary: Update expense record
 *     tags: [Expenses]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Expense' }
 *     responses:
 *       200:
 *         description: Updated
 *   delete:
 *     summary: Remove expense record
 *     tags: [Expenses]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       204:
 *         description: Deleted
 * /vehicles/{vehicleId}/expenses:
 *   get:
 *     summary: Get all expenses for a vehicle
 *     tags: [Expenses]
 *     parameters:
 *       - in: path
 *         name: vehicleId
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       200:
 *         description: Expenses list
 *
 * /todos:
 *   post:
 *     summary: Create a todo item
 *     tags: [Todos]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/Todo' }
 *     responses:
 *       201:
 *         description: Created
 * /todos/{id}/status:
 *   put:
 *     summary: Update todo status (completed/pending)
 *     tags: [Todos]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties: { status: {type: string} }
 *     responses:
 *       200:
 *         description: Updated
 * /todos/pending:
 *   get:
 *     summary: Get all pending todos
 *     tags: [Todos]
 *     responses:
 *       200:
 *         description: Todos list
 * /todos/completed:
 *   get:
 *     summary: Get all completed todos
 *     tags: [Todos]
 *     responses:
 *       200:
 *         description: Todos list
 * /todos/{id}:
 *   delete:
 *     summary: Remove todo item
 *     tags: [Todos]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       204:
 *         description: Deleted
 *
 * /templates:
 *   get:
 *     summary: Get all service templates
 *     tags: [Templates]
 *     responses:
 *       200:
 *         description: Templates list
 *   post:
 *     summary: Create service template
 *     tags: [Templates]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/ServiceTemplate' }
 *     responses:
 *       201:
 *         description: Created
 * /templates/{id}:
 *   put:
 *     summary: Update template
 *     tags: [Templates]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/ServiceTemplate' }
 *     responses:
 *       200:
 *         description: Updated
 *   delete:
 *     summary: Remove template
 *     tags: [Templates]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       204:
 *         description: Deleted
 *
 * /papers:
 *   post:
 *     summary: Create a vehicle paper entry (insurance, PUC, etc.)
 *     tags: [Papers]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/VehiclePaper' }
 *     responses:
 *       201:
 *         description: Created
 * /papers/{id}:
 *   put:
 *     summary: Update paper entry
 *     tags: [Papers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/VehiclePaper' }
 *     responses:
 *       200:
 *         description: Updated
 *   delete:
 *     summary: Remove paper entry
 *     tags: [Papers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       204:
 *         description: Deleted
 * /vehicles/{vehicleId}/papers:
 *   get:
 *     summary: Get all papers for a vehicle
 *     tags: [Papers]
 *     parameters:
 *       - in: path
 *         name: vehicleId
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       200:
 *         description: Papers list
 *
 * /documents:
 *   get:
 *     summary: Get all documents for the current user
 *     tags: [Documents]
 *     responses:
 *       200:
 *         description: List of documents
 *   post:
 *     summary: Create a new document (supports multi-part with document file)
 *     tags: [Documents]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               vehicle_id: {type: integer}
 *               doc_type: {type: string}
 *               description: {type: string}
 *               document: {type: string, format: binary}
 *     responses:
 *       201:
 *         description: Created
 * /documents/{id}:
 *   get:
 *     summary: Get document details
 *     tags: [Documents]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       200:
 *         description: Document details
 *   put:
 *     summary: Update document (supports multi-part with document file)
 *     tags: [Documents]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               doc_type: {type: string}
 *               description: {type: string}
 *               document: {type: string, format: binary}
 *     responses:
 *       200:
 *         description: Updated
 *   delete:
 *     summary: Remove document
 *     tags: [Documents]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       204:
 *         description: Deleted
 * /vehicles/{vehicleId}/documents:
 *   get:
 *     summary: Get all documents for a vehicle
 *     tags: [Documents]
 *     parameters:
 *       - in: path
 *         name: vehicleId
 *         required: true
 *         schema: {type: integer}
 *     responses:
 *       200:
 *         description: Documents list
 */
