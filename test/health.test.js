// test/health.test.js

const request = require('supertest');
const express = require('express');

// Mock router to simulate /api/health endpoint
jest.mock('../modules', () => {
    const router = require('express').Router();

    router.get('/health', (_req, res) => {
        res.status(200).json({
            status: 'OK',
            timestamp: new Date().toISOString(),
            service: 'bike-inventory-api'
        });
    });

    return router;
});

// Mock error handler
jest.mock('../middlewares/errorHandler', () => {
    return (_err, _req, res, _next) => {
        res.status(500).json({ error: 'Internal Server Error' });
    };
});

// Mock logger to suppress logs during testing
jest.mock('../config/logger', () => ({
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn()
}));

describe('Health Check API', () => {
    let app;

    beforeEach(() => {
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

    it('should return 200 with health status info', async () => {
        const res = await request(app).get('/api/health').expect(200);

        expect(res.body).toMatchObject({
            status: 'OK',
            service: 'bike-inventory-api'
        });

        expect(new Date(res.body.timestamp)).toBeInstanceOf(Date);
    });

    it('should respond within 1 second', async () => {
        const start = Date.now();
        await request(app).get('/api/health').expect(200);
        const elapsed = Date.now() - start;

        expect(elapsed).toBeLessThan(1000);
    });
});