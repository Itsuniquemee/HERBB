import { Pool, PoolClient } from 'pg';
import { logger } from '../utils/logger';

// PostgreSQL connection configuration
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

logger.info('PostgreSQL pool initialized');

// Initialize database schema
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

      CREATE INDEX IF NOT EXISTS idx_collections_farmer ON collection_events_cache(farmer_id);
      CREATE INDEX IF NOT EXISTS idx_collections_sync ON collection_events_cache(sync_status);
      CREATE INDEX IF NOT EXISTS idx_collections_species ON collection_events_cache(species);
    `);

    // Batches table
    await client.query(`
      CREATE TABLE IF NOT EXISTS batches (
        id SERIAL PRIMARY KEY,
        batch_number TEXT UNIQUE NOT NULL,
        species TEXT NOT NULL,
        total_quantity REAL NOT NULL,
        unit TEXT DEFAULT 'kg',
        collection_count INTEGER NOT NULL,
        status TEXT DEFAULT 'created' CHECK (status IN ('created', 'assigned', 'in_processing', 'processing_complete', 'quality_tested', 'approved', 'rejected')),
        assigned_to TEXT,
        assigned_to_name TEXT,
        created_by TEXT NOT NULL,
        created_by_name TEXT NOT NULL,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        blockchain_tx_id TEXT
      );
    `);

    // Batch collections mapping table
    await client.query(`
      CREATE TABLE IF NOT EXISTS batch_collections (
        id SERIAL PRIMARY KEY,
        batch_id INTEGER NOT NULL,
        collection_id TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (collection_id) REFERENCES collection_events_cache(id) ON DELETE CASCADE,
        UNIQUE(batch_id, collection_id)
      );
    `);

    // Processing steps cache
    await client.query(`
      CREATE TABLE IF NOT EXISTS processing_steps_cache (
        id TEXT PRIMARY KEY,
        batch_id TEXT NOT NULL,
        processor_id TEXT NOT NULL,
        process_type TEXT NOT NULL CHECK (process_type IN ('drying', 'grinding', 'storage', 'extraction', 'mixing')),
        input_quantity REAL,
        output_quantity REAL,
        loss_percentage REAL,
        temperature REAL,
        humidity REAL,
        duration REAL,
        equipment_id TEXT,
        data_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        blockchain_tx_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        synced_at TIMESTAMP
      );
    `);

    // Quality tests cache
    await client.query(`
      CREATE TABLE IF NOT EXISTS quality_tests_cache (
        id TEXT PRIMARY KEY,
        batch_id TEXT NOT NULL,
        lab_id TEXT NOT NULL,
        lab_name TEXT,
        test_date TIMESTAMP NOT NULL,
        moisture_content REAL,
        pesticide_results TEXT,
        heavy_metals TEXT,
        dna_barcode_match INTEGER,
        microbial_load REAL,
        overall_result TEXT CHECK (overall_result IN ('pass', 'fail', 'conditional')),
        grade TEXT CHECK (grade IN ('A', 'B', 'C', 'F')),
        certificate_url TEXT,
        data_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        blockchain_tx_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        synced_at TIMESTAMP
      );
    `);

    // Alerts table
    await client.query(`
      CREATE TABLE IF NOT EXISTS alerts (
        id SERIAL PRIMARY KEY,
        alert_type TEXT NOT NULL CHECK (alert_type IN (
          'GEO_FENCE_VIOLATION',
          'HARVEST_LIMIT_EXCEEDED',
          'SEASONAL_WINDOW_VIOLATION',
          'QUALITY_TEST_FAILED',
          'PROCESSING_ALERT',
          'EXPIRED_BATCH',
          'RECALL_NOTICE',
          'SYSTEM_ALERT',
          'BATCH_ASSIGNED',
          'BATCH_STATUS_UPDATED'
        )),
        severity TEXT DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'INFO')),
        entity_type TEXT NOT NULL CHECK (entity_type IN ('collection', 'batch', 'test', 'product', 'user', 'system')),
        entity_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        details TEXT,
        status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'acknowledged', 'resolved', 'dismissed')),
        assigned_to TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        acknowledged_by TEXT,
        acknowledged_at TIMESTAMP,
        resolved_by TEXT,
        resolved_at TIMESTAMP,
        resolution_notes TEXT
      );

      CREATE INDEX IF NOT EXISTS idx_alerts_assigned ON alerts(assigned_to);
      CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
      CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts(alert_type);
    `);

    // Recall records table
    await client.query(`
      CREATE TABLE IF NOT EXISTS recall_records (
        id TEXT PRIMARY KEY,
        affected_batch_ids TEXT NOT NULL,
        affected_product_ids TEXT,
        reason TEXT NOT NULL,
        severity TEXT CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
        status TEXT DEFAULT 'active' CHECK (status IN ('active', 'in_progress', 'completed', 'cancelled')),
        total_products_affected INTEGER DEFAULT 0,
        products_located INTEGER DEFAULT 0,
        products_returned INTEGER DEFAULT 0,
        initiated_by TEXT NOT NULL,
        initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP,
        blockchain_tx_id TEXT
      );
    `);

    // QC Test Templates
    await client.query(`
      CREATE TABLE IF NOT EXISTS qc_test_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL CHECK (category IN (
          'IDENTITY', 'PURITY', 'POTENCY', 'CONTAMINATION', 'MICROBIAL', 'HEAVY_METALS', 'PESTICIDES', 'MOISTURE', 'ASH', 'EXTRACTIVES'
        )),
        applicable_species TEXT,
        test_method TEXT NOT NULL,
        parameters TEXT NOT NULL,
        acceptance_criteria TEXT NOT NULL,
        estimated_duration_hours INTEGER,
        cost REAL,
        required_equipment TEXT,
        required_reagents TEXT,
        reference_standard TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by TEXT,
        is_active BOOLEAN DEFAULT true
      );
    `);

    // QC Tests
    await client.query(`
      CREATE TABLE IF NOT EXISTS qc_tests (
        id TEXT PRIMARY KEY,
        test_number TEXT UNIQUE NOT NULL,
        batch_id TEXT NOT NULL,
        template_id TEXT,
        lab_id TEXT NOT NULL,
        lab_name TEXT NOT NULL,
        test_type TEXT NOT NULL CHECK (test_type IN (
          'IDENTITY', 'PURITY', 'POTENCY', 'CONTAMINATION', 'MICROBIAL', 'HEAVY_METALS', 'PESTICIDES', 'MOISTURE', 'ASH', 'EXTRACTIVES', 'CUSTOM'
        )),
        species TEXT NOT NULL,
        sample_id TEXT,
        sample_quantity REAL,
        sample_unit TEXT,
        priority TEXT DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
        status TEXT DEFAULT 'pending' CHECK (status IN (
          'pending', 'sample_collected', 'in_progress', 'completed', 'failed', 'cancelled'
        )),
        requested_by TEXT NOT NULL,
        requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        assigned_to TEXT,
        started_at TIMESTAMP,
        completed_at TIMESTAMP,
        due_date TIMESTAMP,
        test_method TEXT,
        equipment_used TEXT,
        reagents_used TEXT,
        environmental_conditions TEXT,
        notes TEXT,
        cost REAL,
        blockchain_tx_id TEXT,
        FOREIGN KEY (template_id) REFERENCES qc_test_templates(id)
      );
    `);

    // QC Test Parameters
    await client.query(`
      CREATE TABLE IF NOT EXISTS qc_test_parameters (
        id SERIAL PRIMARY KEY,
        test_id TEXT NOT NULL,
        parameter_name TEXT NOT NULL,
        parameter_type TEXT CHECK (parameter_type IN ('NUMERIC', 'TEXT', 'BOOLEAN', 'RANGE')),
        expected_value TEXT,
        expected_min REAL,
        expected_max REAL,
        unit TEXT,
        description TEXT,
        FOREIGN KEY (test_id) REFERENCES qc_tests(id) ON DELETE CASCADE
      );
    `);

    // QC Results
    await client.query(`
      CREATE TABLE IF NOT EXISTS qc_results (
        id SERIAL PRIMARY KEY,
        test_id TEXT NOT NULL,
        parameter_id INTEGER,
        parameter_name TEXT NOT NULL,
        measured_value TEXT,
        measured_numeric REAL,
        unit TEXT,
        pass_fail TEXT CHECK (pass_fail IN ('PASS', 'FAIL', 'WARNING', 'NA')),
        deviation REAL,
        remarks TEXT,
        measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        measured_by TEXT,
        verified_by TEXT,
        verified_at TIMESTAMP,
        FOREIGN KEY (test_id) REFERENCES qc_tests(id) ON DELETE CASCADE,
        FOREIGN KEY (parameter_id) REFERENCES qc_test_parameters(id) ON DELETE SET NULL
      );
    `);

    // QC Certificates
    await client.query(`
      CREATE TABLE IF NOT EXISTS qc_certificates (
        id TEXT PRIMARY KEY,
        certificate_number TEXT UNIQUE NOT NULL,
        test_id TEXT NOT NULL,
        batch_id TEXT NOT NULL,
        overall_result TEXT NOT NULL CHECK (overall_result IN ('PASS', 'FAIL', 'CONDITIONAL')),
        certificate_data TEXT NOT NULL,
        issued_by TEXT NOT NULL,
        issued_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        valid_until TIMESTAMP,
        file_path TEXT,
        digital_signature TEXT,
        blockchain_txid TEXT,
        blockchain_tx_id TEXT,
        blockchain_timestamp TIMESTAMP,
        FOREIGN KEY (test_id) REFERENCES qc_tests(id)
      );
    `);

    // Analytics tables
    await client.query(`
      CREATE TABLE IF NOT EXISTS analytics_metrics (
        id TEXT PRIMARY KEY,
        metric_type TEXT NOT NULL CHECK (metric_type IN (
          'QC_SUCCESS_RATE', 'LAB_PERFORMANCE', 'BATCH_QUALITY_SCORE', 
          'TEST_COMPLETION_TIME', 'COST_ANALYSIS', 'COMPLIANCE_RATE'
        )),
        entity_id TEXT,
        entity_type TEXT CHECK (entity_type IN ('BATCH', 'LAB', 'SUPPLIER', 'SPECIES', 'SYSTEM')),
        metric_value REAL NOT NULL,
        metric_unit TEXT,
        calculation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        date_from TIMESTAMP,
        date_to TIMESTAMP,
        metadata TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS analytics_reports (
        id TEXT PRIMARY KEY,
        report_name TEXT NOT NULL,
        report_type TEXT NOT NULL CHECK (report_type IN (
          'QC_SUMMARY', 'LAB_PERFORMANCE', 'BATCH_QUALITY', 
          'COMPLIANCE', 'COST_ANALYSIS', 'TREND_ANALYSIS', 'CUSTOM'
        )),
        report_format TEXT CHECK (report_format IN ('PDF', 'EXCEL', 'JSON', 'HTML')),
        parameters TEXT,
        generated_by TEXT NOT NULL,
        generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        file_path TEXT,
        file_size INTEGER,
        status TEXT DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'GENERATING', 'COMPLETED', 'FAILED')),
        error_message TEXT,
        download_count INTEGER DEFAULT 0,
        expires_at TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS scheduled_reports (
        id TEXT PRIMARY KEY,
        report_name TEXT NOT NULL,
        report_type TEXT NOT NULL,
        report_format TEXT NOT NULL,
        schedule_type TEXT NOT NULL CHECK (schedule_type IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY')),
        schedule_time TEXT NOT NULL,
        parameters TEXT,
        recipients TEXT NOT NULL,
        created_by TEXT NOT NULL,
        is_active BOOLEAN DEFAULT true,
        last_run TIMESTAMP,
        next_run TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS dashboard_cache (
        id TEXT PRIMARY KEY,
        cache_key TEXT UNIQUE NOT NULL,
        cache_data TEXT NOT NULL,
        entity_id TEXT,
        entity_type TEXT,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Create additional indexes
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
      CREATE INDEX IF NOT EXISTS idx_users_org_name ON users(org_name);
      CREATE INDEX IF NOT EXISTS idx_registration_status ON registration_requests(status);
      CREATE INDEX IF NOT EXISTS idx_batches_processor ON batches(assigned_to);
      CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
      CREATE INDEX IF NOT EXISTS idx_qc_tests_batch ON qc_tests(batch_id);
      CREATE INDEX IF NOT EXISTS idx_qc_tests_lab ON qc_tests(lab_id);
      CREATE INDEX IF NOT EXISTS idx_qc_tests_status ON qc_tests(status);
      CREATE INDEX IF NOT EXISTS idx_qc_results_test ON qc_results(test_id);
      CREATE INDEX IF NOT EXISTS idx_qc_certificates_batch ON qc_certificates(batch_id);
      CREATE INDEX IF NOT EXISTS idx_analytics_metrics_type ON analytics_metrics(metric_type);
      CREATE INDEX IF NOT EXISTS idx_analytics_metrics_entity ON analytics_metrics(entity_id, entity_type);
      CREATE INDEX IF NOT EXISTS idx_analytics_metrics_date ON analytics_metrics(calculation_date);
      CREATE INDEX IF NOT EXISTS idx_analytics_reports_type ON analytics_reports(report_type);
      CREATE INDEX IF NOT EXISTS idx_analytics_reports_generated ON analytics_reports(generated_by, generated_at);
      CREATE INDEX IF NOT EXISTS idx_scheduled_reports_active ON scheduled_reports(is_active, next_run);
      CREATE INDEX IF NOT EXISTS idx_dashboard_cache_key ON dashboard_cache(cache_key);
      CREATE INDEX IF NOT EXISTS idx_dashboard_cache_expires ON dashboard_cache(expires_at);
    `);

    // Insert default admin user
    const adminCheck = await client.query('SELECT COUNT(*) as count FROM users WHERE username = $1', ['admin']);
    
    if (adminCheck.rows[0].count === '0') {
      const bcrypt = require('bcryptjs');
      const hashedPassword = bcrypt.hashSync('admin123', 10);
      
      await client.query(`
        INSERT INTO users (id, user_id, username, email, password_hash, full_name, role, org_name, org_msp, affiliation)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      `, [
        'admin-001',
        'admin-001',
        'admin',
        'admin@herbaltrace.com',
        hashedPassword,
        'System Administrator',
        'Admin',
        'HerbalTrace',
        'HerbalTraceMSP',
        'admin.department1'
      ]);
      
      logger.info('✅ Default admin user created (username: admin, password: admin123)');
    }

    await client.query('COMMIT');
    logger.info('✅ PostgreSQL database schema initialized successfully');
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('Failed to initialize PostgreSQL database schema:', error);
    throw error;
  } finally {
    client.release();
  }
};

// Test connection function
export const testConnection = async (): Promise<boolean> => {
  try {
    const result = await pool.query('SELECT NOW() as now');
    logger.info('PostgreSQL connection successful:', result.rows[0]);
    return true;
  } catch (error) {
    logger.error('PostgreSQL connection failed:', error);
    return false;
  }
};

// Query helper function
export const query = async (text: string, params?: any[]): Promise<any> => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    logger.debug('Executed query', { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    logger.error('Query error', { text, error });
    throw error;
  }
};

// Get client for transactions
export const getClient = async (): Promise<PoolClient> => {
  return await pool.connect();
};

// Export pool
export { pool as db };
