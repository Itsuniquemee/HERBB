import { Router, Request, Response } from 'express';
import { db } from '../config/database-adapter';

const router = Router();

/**
 * @route   GET /api/v1/health
 * @desc    Overall system health check
 * @access  Public
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      services: {
        api: 'healthy',
        blockchain: 'unknown',
        database: 'unknown',
        redis: 'unknown'
      }
    };

    res.status(200).json({
      success: true,
      data: health
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   GET /api/v1/health/blockchain
 * @desc    Check blockchain connection health
 * @access  Public
 */
router.get('/blockchain', async (req: Request, res: Response) => {
  try {
    // TODO: Implement blockchain health check
    // - Try to connect to gateway
    // - Query a simple function (e.g., GetAllSpecies)
    // - Measure response time

    const health = {
      status: 'healthy',
      connected: true,
      network: process.env.FABRIC_NETWORK_PATH || 'unknown',
      channel: process.env.FABRIC_CHANNEL_NAME || 'herbaltrace-channel',
      chaincode: process.env.FABRIC_CHAINCODE_NAME || 'herbaltrace',
      mspId: process.env.FABRIC_MSP_ID || 'unknown',
      responseTime: 0,
      lastChecked: new Date().toISOString()
    };

    res.status(200).json({
      success: true,
      data: health
    });
  } catch (error: any) {
    res.status(503).json({
      success: false,
      data: {
        status: 'unhealthy',
        connected: false,
        error: error.message
      }
    });
  }
});

/**
 * @route   GET /api/v1/health/database
 * @desc    Check PostgreSQL database connection
 * @access  Public
 */
router.get('/database', async (req: Request, res: Response) => {
  try {
    const startedAt = Date.now();

    const connectionResult = await db.query(
      `
      SELECT
        current_database() AS database,
        COALESCE(inet_server_addr()::text, 'unknown') AS host,
        inet_server_port() AS port
      `
    );

    const expectedTables = [
      'users',
      'collection_events_cache',
      'quality_tests_cache',
      'processing_batches_cache',
      'products_cache',
      'qr_codes'
    ];

    const tables: Array<{ name: string; exists: boolean; count: number | null }> = [];

    for (const tableName of expectedTables) {
      const existsResult = await db.query(
        'SELECT to_regclass($1) IS NOT NULL AS exists',
        [`public.${tableName}`]
      );

      const exists = Boolean(existsResult.rows?.[0]?.exists);
      let count: number | null = null;

      if (exists) {
        // Safe because tableName comes from a hardcoded allowlist above.
        const countResult = await db.query(`SELECT COUNT(*)::int AS count FROM ${tableName}`);
        count = Number(countResult.rows?.[0]?.count ?? 0);
      }

      tables.push({ name: tableName, exists, count });
    }

    const missingTables = tables.filter((table) => !table.exists).map((table) => table.name);
    const responseTime = Date.now() - startedAt;
    const conn = connectionResult.rows?.[0] || {};

    const health = {
      status: missingTables.length === 0 ? 'healthy' : 'degraded',
      connected: true,
      host: conn.host || 'unknown',
      port: conn.port || Number(process.env.DATABASE_PORT || 5432),
      database: conn.database || process.env.DATABASE_NAME || 'unknown',
      responseTime,
      lastChecked: new Date().toISOString(),
      missingTables,
      tables
    };

    res.status(200).json({
      success: true,
      data: health
    });
  } catch (error: any) {
    res.status(503).json({
      success: false,
      data: {
        status: 'unhealthy',
        connected: false,
        error: error.message
      }
    });
  }
});

/**
 * @route   GET /api/v1/health/redis
 * @desc    Check Redis connection health
 * @access  Public
 */
router.get('/redis', async (req: Request, res: Response) => {
  try {
    // TODO: Implement Redis health check
    // - Try to connect to Redis
    // - Execute PING command
    // - Measure response time

    const health = {
      status: 'healthy',
      connected: true,
      host: process.env.REDIS_HOST || 'localhost',
      port: process.env.REDIS_PORT || 6379,
      responseTime: 0,
      lastChecked: new Date().toISOString()
    };

    res.status(200).json({
      success: true,
      data: health
    });
  } catch (error: any) {
    res.status(503).json({
      success: false,
      data: {
        status: 'unhealthy',
        connected: false,
        error: error.message
      }
    });
  }
});

/**
 * @route   GET /api/v1/health/detailed
 * @desc    Detailed health check of all services
 * @access  Admin
 */
router.get('/detailed', async (req: Request, res: Response) => {
  try {
    // TODO: Run all health checks in parallel
    // Return detailed status of each service

    const detailedHealth = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      services: {
        api: {
          status: 'healthy',
          port: process.env.PORT || 3000,
          version: '1.0.0'
        },
        blockchain: {
          status: 'unknown',
          message: 'Health check not implemented'
        },
        database: {
          status: 'unknown',
          message: 'Health check not implemented'
        },
        redis: {
          status: 'unknown',
          message: 'Health check not implemented'
        }
      }
    };

    res.status(200).json({
      success: true,
      data: detailedHealth
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;
