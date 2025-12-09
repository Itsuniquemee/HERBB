/**
 * Database Adapter - Provides SQLite-like interface for PostgreSQL
 * This allows existing SQLite code to work with PostgreSQL
 */

import { Pool, PoolClient } from 'pg';
import { logger } from '../utils/logger';

// PostgreSQL connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

pool.on('connect', () => {
  logger.info('PostgreSQL client connected to pool');
});

pool.on('error', (err) => {
  logger.error('Unexpected error on idle PostgreSQL client', err);
});

logger.info('PostgreSQL database adapter initialized');

/**
 * SQLite-compatible prepared statement class for PostgreSQL
 */
class PreparedStatement {
  private query: string;
  private pool: Pool;

  constructor(query: string, pool: Pool) {
    // Convert SQLite ? placeholders to PostgreSQL $1, $2, etc.
    let paramCount = 0;
    this.query = query.replace(/\?/g, () => `$${++paramCount}`);
    this.pool = pool;
  }

  /**
   * Execute query and return all results (SQLite .all() equivalent)
   */
  all(...params: any[]): any[] {
    // This needs to be synchronous for SQLite compatibility
    // We'll handle this in the routes by making them async
    throw new Error('Use allAsync() instead - PostgreSQL queries must be async');
  }

  /**
   * Async version of all() for PostgreSQL
   */
  async allAsync(...params: any[]): Promise<any[]> {
    try {
      const result = await this.pool.query(this.query, params);
      return result.rows;
    } catch (error) {
      logger.error('Query error:', { query: this.query, params, error });
      throw error;
    }
  }

  /**
   * Execute query and return first result (SQLite .get() equivalent)
   */
  async getAsync(...params: any[]): Promise<any | undefined> {
    try {
      const result = await this.pool.query(this.query, params);
      return result.rows[0];
    } catch (error) {
      logger.error('Query error:', { query: this.query, params, error });
      throw error;
    }
  }

  /**
   * Execute query without returning results (SQLite .run() equivalent)
   */
  async runAsync(...params: any[]): Promise<{ changes: number; lastInsertRowid?: any }> {
    try {
      const result = await this.pool.query(this.query, params);
      return {
        changes: result.rowCount || 0,
        lastInsertRowid: result.rows[0]?.id
      };
    } catch (error) {
      logger.error('Query error:', { query: this.query, params, error });
      throw error;
    }
  }
}

/**
 * Database adapter object - provides SQLite-like interface
 */
export const db = {
  /**
   * Prepare a SQL statement (SQLite-compatible)
   */
  prepare(query: string): PreparedStatement {
    return new PreparedStatement(query, pool);
  },

  /**
   * Execute a raw SQL query
   */
  async query(text: string, params?: any[]): Promise<any> {
    return await pool.query(text, params);
  },

  /**
   * Execute raw SQL (for creating tables, etc.)
   */
  async exec(sql: string): Promise<void> {
    await pool.query(sql);
  },

  /**
   * Get a client for transactions
   */
  async getClient(): Promise<PoolClient> {
    return await pool.connect();
  },

  /**
   * Close the database connection
   */
  async close(): Promise<void> {
    await pool.end();
  }
};

/**
 * Initialize database schema for PostgreSQL
 */
export const initializeDatabase = async (): Promise<void> => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Users table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        user_id TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL CHECK (role IN ('Farmer', 'Lab', 'Processor', 'Manufacturer', 'Consumer', 'Admin', 'Regulator')),
        org_name TEXT NOT NULL,
        org_msp TEXT,
        affiliation TEXT,
        location_district TEXT,
        location_state TEXT,
        location_coordinates TEXT,
        status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP,
        created_by TEXT
      );
    `);

    // Registration requests table
    await client.query(`
      CREATE TABLE IF NOT EXISTS registration_requests (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'Farmer',
        organization_name TEXT,
        location_district TEXT,
        location_state TEXT,
        location_coordinates TEXT,
        species_interest TEXT,
        farm_size_acres REAL,
        experience_years INTEGER,
        farm_photos TEXT,
        certifications TEXT,
        aadhar_number TEXT,
        request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
        admin_notes TEXT,
        approved_by TEXT,
        approved_date TIMESTAMP,
        rejection_reason TEXT
      );
    `);

    // Collection events cache
    await client.query(`
      CREATE TABLE IF NOT EXISTS collection_events_cache (
        id TEXT PRIMARY KEY,
        farmer_id TEXT NOT NULL,
        farmer_name TEXT,
        species TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT DEFAULT 'kg',
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL,
        harvest_date TIMESTAMP NOT NULL,
        data_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed')),
        blockchain_tx_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        synced_at TIMESTAMP,
        error_message TEXT
      );
    `);

    // Quality tests cache
    await client.query(`
      CREATE TABLE IF NOT EXISTS quality_tests_cache (
        id TEXT PRIMARY KEY,
        collection_id TEXT NOT NULL,
        lab_id TEXT NOT NULL,
        test_type TEXT NOT NULL,
        test_date TIMESTAMP NOT NULL,
        data_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed')),
        blockchain_tx_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        synced_at TIMESTAMP,
        error_message TEXT
      );
    `);

    // Processing batches cache
    await client.query(`
      CREATE TABLE IF NOT EXISTS processing_batches_cache (
        id TEXT PRIMARY KEY,
        processor_id TEXT NOT NULL,
        input_collections TEXT NOT NULL,
        batch_number TEXT NOT NULL,
        processing_date TIMESTAMP NOT NULL,
        data_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed')),
        blockchain_tx_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        synced_at TIMESTAMP,
        error_message TEXT
      );
    `);

    // Products cache
    await client.query(`
      CREATE TABLE IF NOT EXISTS products_cache (
        id TEXT PRIMARY KEY,
        manufacturer_id TEXT NOT NULL,
        batch_ids TEXT NOT NULL,
        product_name TEXT NOT NULL,
        manufacturing_date TIMESTAMP NOT NULL,
        data_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed')),
        blockchain_tx_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        synced_at TIMESTAMP,
        error_message TEXT
      );
    `);

    // QR codes
    await client.query(`
      CREATE TABLE IF NOT EXISTS qr_codes (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        qr_data TEXT NOT NULL,
        qr_image_path TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by TEXT
      );
    `);

    // Season windows
    await client.query(`
      CREATE TABLE IF NOT EXISTS season_windows (
        id TEXT PRIMARY KEY,
        species TEXT NOT NULL,
        region TEXT NOT NULL,
        start_month INTEGER NOT NULL,
        start_day INTEGER NOT NULL,
        end_month INTEGER NOT NULL,
        end_day INTEGER NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by TEXT
      );
    `);

    // Harvest limits
    await client.query(`
      CREATE TABLE IF NOT EXISTS harvest_limits (
        id TEXT PRIMARY KEY,
        species TEXT NOT NULL,
        farmer_id TEXT NOT NULL,
        season_year INTEGER NOT NULL,
        max_quantity REAL NOT NULL,
        current_quantity REAL DEFAULT 0,
        unit TEXT DEFAULT 'kg',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Alerts
    await client.query(`
      CREATE TABLE IF NOT EXISTS alerts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        data_json TEXT,
        read BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await client.query('COMMIT');
    logger.info('✅ PostgreSQL database schema initialized successfully');
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('Failed to initialize database schema:', error);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Test database connection
 */
export const testConnection = async (): Promise<boolean> => {
  try {
    const result = await pool.query('SELECT NOW()');
    logger.info('Database connection test successful:', result.rows[0]);
    return true;
  } catch (error) {
    logger.error('Database connection test failed:', error);
    return false;
  }
};

// Export pool for advanced usage
export { pool };
