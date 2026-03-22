const swaggerJsdoc = require('swagger-jsdoc');

const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'MechMinder API',
            version: '1.0.0',
            description: 'API documentation for MechMinder backend. Use the `x-user-uid` header to authenticate.',
        },
        servers: [
            {
                url: 'http://localhost:5000/api',
                description: 'Development server',
            },
        ],
        components: {
            securitySchemes: {
                UserUID: {
                    type: 'apiKey',
                    in: 'header',
                    name: 'x-user-uid',
                    description: 'The user ID from Firebase Authentication'
                },
            },
        },
        security: [
            {
                UserUID: [],
            },
        ],
    },
    apis: ['./routes/*.js', './docs/*.js'], // Path to the API docs
};

const specs = swaggerJsdoc(options);
module.exports = specs;
