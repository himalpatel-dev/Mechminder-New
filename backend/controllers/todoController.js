const db = require('../models');

// GET /api/todos/pending
exports.getAllPendingTodos = async (req, res) => {
    try {
        const todos = await db.TodoList.findAll({
            where: { status: 'pending' },
            include: [{
                model: db.Vehicle,
                where: { user_id: req.user.id }
            }],
            order: [['created_at', 'DESC']]
        });
        res.json(todos);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// GET /api/todos/completed
exports.getAllCompletedTodos = async (req, res) => {
    try {
        const todos = await db.TodoList.findAll({
            where: { status: 'completed' },
            include: [{
                model: db.Vehicle,
                where: { user_id: req.user.id }
            }],
            order: [['updated_at', 'DESC'], ['created_at', 'DESC']]
        });
        res.json(todos);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// POST /api/todos
exports.createTodo = async (req, res) => {
    try {
        // Verify vehicle ownership
        const vehicle = await db.Vehicle.findOne({
            where: { id: req.body.vehicle_id, user_id: req.user.id }
        });
        if (!vehicle) return res.status(403).json({ message: 'Unauthorized vehicle access' });

        const todo = await db.TodoList.create(req.body);
        res.status(201).json(todo);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// PUT /api/todos/:id/status
exports.updateTodoStatus = async (req, res) => {
    try {
        const todo = await db.TodoList.findOne({
            where: { id: req.params.id },
            include: [{
                model: db.Vehicle,
                where: { user_id: req.user.id }
            }]
        });
        if (!todo) return res.status(404).json({ message: 'Todo not found or unauthorized' });

        todo.status = req.body.status;
        if (todo.status === 'completed') {
            todo.updated_at = new Date();
        }
        await todo.save();

        res.json(todo);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// DELETE /api/todos/:id
exports.deleteTodo = async (req, res) => {
    try {
        const todo = await db.TodoList.findOne({
            where: { id: req.params.id },
            include: [{
                model: db.Vehicle,
                where: { user_id: req.user.id }
            }]
        });
        if (!todo) return res.status(404).json({ message: 'Todo not found or unauthorized' });
        await todo.destroy();
        res.status(204).send();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
