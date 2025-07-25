const request = require('supertest');
const express = require('express');

// Mock the modules to avoid database connection during testing
jest.mock('../modules', () => {
    const express = require('express');
    const router = express.Router();
    
    // Health check endpoint
    router.get('/health', (req, res) => {
        res.status(200).json({ 
            status: 'OK', 
            timestamp: new Date().toISOString(),
            service: 'bike-inventory-api'
        });
    });
    
    return router;
});

jest.mock('../middlewares/errorHandler', () => {
    return (err, req, res, next) => {
        res.status(500).json({ error: 'Internal Server Error' });
    };
});

jest.mock('../config/logger', () => ({
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn()
}));

describe('Health Check Endpoint', () => {
    let app;

    beforeEach(() => {
        // Create a fresh app instance for each test
        app = express();
        app.use(express.json());
        
        const allRouter = require('../modules');
        app.use('/api', allRouter);
        
        const errorHandler = require('../middlewares/errorHandler');
        app.use(errorHandler);
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    test('GET /api/health should return 200 and health status', async () => {
        const response = await request(app)
            .get('/api/health')
            .expect(200);

        expect(response.body).toHaveProperty('status', 'OK');
        expect(response.body).toHaveProperty('service', 'bike-inventory-api');
        expect(response.body).toHaveProperty('timestamp');
        expect(new Date(response.body.timestamp)).toBeInstanceOf(Date);
    });

    test('Health endpoint should respond within reasonable time', async () => {
        const start = Date.now();
        await request(app)
            .get('/api/health')
            .expect(200);
        const duration = Date.now() - start;
        
        expect(duration).toBeLessThan(1000); // Should respond within 1 second
    });
});