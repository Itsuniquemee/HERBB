import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import dotenv from 'dotenv';
import path from 'path';

// Load environment variables FIRST
dotenv.config();

// Import database
import { testConnection } from './config/database-adapter';
import {
  initializeDatabase as initializeLegacyDatabase,
  testConnection as testLegacyConnection,
} from './config/database';
// import { connectRedis } from './config/redis'; // Disabled for hackathon
import { logger } from './utils/logger';

// Import routes
import authRoutes from './routes/auth.routes';
import uploadRoutes from './routes/upload.routes';
import collectionRoutes from './routes/collection.routes';
import batchRoutes from './routes/batch.routes';
import qcRoutes from './routes/qc.routes';
import qualityRoutes from './routes/quality.routes';
import processingRoutes from './routes/processing.routes';
import productRoutes from './routes/product.routes';
import provenanceRoutes from './routes/provenance.routes';
import seasonWindowRoutes from './routes/seasonWindow.routes';
import harvestLimitRoutes from './routes/harvestLimit.routes';
import alertRoutes from './routes/alert.routes';
import analyticsRoutes from './routes/analytics.routes';
import healthRoutes from './routes/health.routes';
import blockchainRoutes from './routes/blockchain.routes';
import herbSpeciesRoutes from './routes/herb-species.routes';
import complaintsRoutes from './routes/complaints.routes';

const app: Application = express();
const PORT = process.env.PORT || 3000;
const API_PREFIX = process.env.API_PREFIX || 'api/v1';

// Trust proxy (for deployment behind reverse proxy)
app.set('trust proxy', 1);

// CORS - Allow all origins for hackathon (restrict in production)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

// Security headers
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }
}));

// Compression
app.use(compression());

// Body parsing - Increased limits for image uploads
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Logging
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Static files - Serve uploaded images
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Welcome page
app.get('/', (_req: Request, res: Response) => {
  res.json({
    success: true,
    name: 'HerbalTrace API',
    version: '1.0.0',
    description: 'Blockchain-based Supply Chain Traceability for Herbal Products',
    blockchain: {
      network: 'Hyperledger Fabric',
      chaincode: process.env.FABRIC_CHAINCODE_NAME || 'herbaltrace',
      channel: process.env.FABRIC_CHANNEL_NAME || 'herbaltrace-channel'
    },
    endpoints: {
      health: '/health',
      auth: `/${API_PREFIX}/auth`,
      upload: `/${API_PREFIX}/upload`,
      collections: `/${API_PREFIX}/collections`,
      batches: `/${API_PREFIX}/batches`,
      qc: `/${API_PREFIX}/qc`,
      qualityTests: `/${API_PREFIX}/quality-tests`,
      processing: `/${API_PREFIX}/processing`,
      products: `/${API_PREFIX}/products`,
      provenance: `/${API_PREFIX}/provenance`,
      seasonWindows: `/${API_PREFIX}/season-windows`,
      harvestLimits: `/${API_PREFIX}/harvest-limits`,
      alerts: `/${API_PREFIX}/alerts`,
      analytics: `/${API_PREFIX}/analytics`,
      herbSpecies: `/${API_PREFIX}/herbs`,
      complaints: `/${API_PREFIX}/complaints`
    }
  });
});

// Health check
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API Routes - All stakeholders
app.use(`/${API_PREFIX}/auth`, authRoutes);
app.use(`/${API_PREFIX}/upload`, uploadRoutes);
app.use(`/${API_PREFIX}/collections`, collectionRoutes);
app.use(`/${API_PREFIX}/batches`, batchRoutes);
app.use(`/${API_PREFIX}/qc`, qcRoutes);
app.use(`/${API_PREFIX}/quality-tests`, qualityRoutes);
app.use(`/${API_PREFIX}/processing`, processingRoutes);
app.use(`/${API_PREFIX}/products`, productRoutes);
app.use(`/${API_PREFIX}/provenance`, provenanceRoutes);
app.use(`/${API_PREFIX}/season-windows`, seasonWindowRoutes);
app.use(`/${API_PREFIX}/harvest-limits`, harvestLimitRoutes);
app.use(`/${API_PREFIX}/alerts`, alertRoutes);
app.use(`/${API_PREFIX}/analytics`, analyticsRoutes);
app.use(`/${API_PREFIX}/health`, healthRoutes);
app.use(`/${API_PREFIX}/blockchain`, blockchainRoutes);
app.use(`/${API_PREFIX}/herbs`, herbSpeciesRoutes);
app.use(`/${API_PREFIX}/complaints`, complaintsRoutes);

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.path,
    method: req.method
  });
});

// Global error handler
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err);
  
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  
  res.status(statusCode).json({
    success: false,
    error: message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

// Start server
// Initialize database and Redis before starting server
const startServer = async () => {
  let server: any = null;
  const requireDatabase = process.env.NODE_ENV === 'production' || process.env.REQUIRE_DATABASE === 'true';
  
  try {
    // Initialize legacy SQLite database for routes still using config/database.
    // This keeps auth and other legacy endpoints functional while PostgreSQL is primary.
    let legacyDbConnected = false;
    try {
      logger.info('Initializing legacy SQLite database schema...');
      initializeLegacyDatabase();
      legacyDbConnected = await testLegacyConnection();

      if (legacyDbConnected) {
        logger.info('✅ Legacy SQLite database connected successfully');
      } else {
        logger.warn('⚠️  Legacy SQLite database connection failed (legacy endpoints may be limited)');
      }
    } catch (error: any) {
      logger.warn(`⚠️  Legacy SQLite initialization failed: ${error.message}`);
    }

    // Initialize database schema, but do not fail the whole app if the database is unavailable.
    let dbConnected = false;
    try {
      if (!process.env.DATABASE_URL) {
        throw new Error('DATABASE_URL is not set');
      }

      logger.info('Initializing database schema...');
      const { initializeDatabase } = await import('./config/database-adapter');
      await initializeDatabase();

      logger.info('Testing database connection...');
      dbConnected = await testConnection();

      if (dbConnected) {
        logger.info('✅ Database connected successfully');
      } else {
        logger.warn('⚠️  Database connection failed - continuing without database (some features may be limited)');
      }
    } catch (error: any) {
      if (requireDatabase) {
        throw error;
      }
      logger.warn(`⚠️  Database initialization failed: ${error.message}`);
      logger.warn('⚠️  Continuing without database (some features may be limited)');
    }

    // Connect to Redis (optional) - Skip for now
    // try {
    //   await connectRedis();
    //   logger.info('✅ Redis connected successfully');
    // } catch (error) {
    //   logger.warn('⚠️  Redis connection failed - continuing without cache (some features may be limited)');
    // }
    logger.info('Redis caching disabled for hackathon - using in-memory cache');

    // Initialize blockchain connection
    let blockchainConnected = false;
    try {
      logger.info('🔗 Initializing blockchain connection...');
      const { fabricService } = await import('./services/FabricService');
      await fabricService.connect();
      blockchainConnected = true;
      logger.info('✅ Blockchain connected successfully');
    } catch (error: any) {
      logger.warn(`⚠️  Blockchain connection failed: ${error.message}`);
      logger.warn('⚠️  Continuing without blockchain (features limited to database only)');
    }

    // Start HTTP server
    server = app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   🌿 HerbalTrace Backend API Server                           ║
║                                                                ║
║   Server:      http://localhost:${PORT}                            ║
║   Environment: ${process.env.NODE_ENV || 'development'}                              ║
║   Health:      http://localhost:${PORT}/health                     ║
║   API:         http://localhost:${PORT}/${API_PREFIX}                     ║
║                                                                ║
║   Blockchain:  ${process.env.FABRIC_CHAINCODE_NAME || 'herbaltrace'}                              ║
║   Channel:     ${process.env.FABRIC_CHANNEL_NAME || 'herbaltrace-channel'}                ║
║                                                                ║
║   Database:    ${dbConnected ? '✅ Connected' : '⚠️  Offline'}                        ║
║   Cache:       ${process.env.REDIS_HOST ? '✅ Ready' : '⚠️  Offline'}                           ║
║   Blockchain:  ${blockchainConnected ? '✅ Connected' : '⚠️  Offline'}                        ║
║                                                                ║
║   Ready for:   ✅ Farmers  ✅ Labs  ✅ Processors               ║
║                ✅ Manufacturers  ✅ Consumers  ✅ Admins        ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
      `);
    });

    // Graceful shutdown
    const shutdown = () => {
      if (server) {
        console.log('Shutdown signal received: closing HTTP server');
        server.close(() => {
          console.log('HTTP server closed');
          process.exit(0);
        });
      }
    };

    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();

export default app;




