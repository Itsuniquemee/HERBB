import Database from 'better-sqlite3';
import { logger } from '../utils/logger';
import path from 'path';
import fs from 'fs';

// SQLite database configuration (faster setup for hackathon)
const dbPath = process.env.DB_PATH || path.join(__dirname, '../../data/herbaltrace.db');
const dbDir = path.dirname(dbPath);

// Ensure data directory exists
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
  logger.info(`Created database directory: ${dbDir}`);
}

// Initialize SQLite database
const db: Database.Database = new Database(dbPath, { verbose: (msg) => logger.debug(msg) });

// Enable foreign keys
db.pragma('foreign_keys = ON');
db.pragma('journal_mode = WAL');

logger.info(`SQLite database initialized at: ${dbPath}`);

// Initialize database schema
export const initializeDatabase = (): void => {
  try {
    // Users table
    db.exec(`
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
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        last_login TEXT,
        created_by TEXT
      );
    `);

    // Registration requests table
    db.exec(`
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
        request_date TEXT DEFAULT (datetime('now')),
        status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
        admin_notes TEXT,
        approved_by TEXT,
        approved_date TEXT,
        rejection_reason TEXT
      );
    `);

    // Collection events cache
    db.exec(`
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
        harvest_date TEXT NOT NULL,
        data_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed')),
        blockchain_tx_id TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced_at TEXT,
        error_message TEXT
      );

      CREATE INDEX IF NOT EXISTS idx_collections_farmer ON collection_events_cache(farmer_id);
      CREATE INDEX IF NOT EXISTS idx_collections_sync ON collection_events_cache(sync_status);
      CREATE INDEX IF NOT EXISTS idx_collections_species ON collection_events_cache(species);
    `);

    // Batches table
    db.exec(`
      CREATE TABLE IF NOT EXISTS batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        blockchain_tx_id TEXT
      );
    `);

    // Batch collections mapping table
    db.exec(`
      CREATE TABLE IF NOT EXISTS batch_collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id INTEGER NOT NULL,
        collection_id TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE,
        FOREIGN KEY (collection_id) REFERENCES collection_events_cache(id) ON DELETE CASCADE,
        UNIQUE(batch_id, collection_id)
      );
    `);

    // Processing steps cache
    db.exec(`
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
        created_at TEXT DEFAULT (datetime('now')),
        synced_at TEXT,
        FOREIGN KEY (batch_id) REFERENCES batches(id)
      );
    `);

    // Quality tests cache
    db.exec(`
      CREATE TABLE IF NOT EXISTS quality_tests_cache (
        id TEXT PRIMARY KEY,
        batch_id TEXT NOT NULL,
        lab_id TEXT NOT NULL,
        lab_name TEXT,
        test_date TEXT NOT NULL,
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
        created_at TEXT DEFAULT (datetime('now')),
        synced_at TEXT,
        FOREIGN KEY (batch_id) REFERENCES batches(id)
      );
    `);

    // Alerts table
    db.exec(`
      CREATE TABLE IF NOT EXISTS alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        created_at TEXT DEFAULT (datetime('now')),
        acknowledged_by TEXT,
        acknowledged_at TEXT,
        resolved_by TEXT,
        resolved_at TEXT,
        resolution_notes TEXT
      );

      CREATE INDEX IF NOT EXISTS idx_alerts_assigned ON alerts(assigned_to);
      CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
    `);

    // Recall records table
    db.exec(`
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
        initiated_at TEXT DEFAULT (datetime('now')),
        completed_at TEXT,
        blockchain_tx_id TEXT
      );
    `);

    // QC Test Templates - Predefined test configurations
    db.exec(`
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
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        created_by TEXT,
        is_active INTEGER DEFAULT 1
      );
    `);

    // QC Tests - Individual test records linked to batches
    db.exec(`
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
        requested_at TEXT DEFAULT (datetime('now')),
        assigned_to TEXT,
        started_at TEXT,
        completed_at TEXT,
        due_date TEXT,
        test_method TEXT,
        equipment_used TEXT,
        reagents_used TEXT,
        environmental_conditions TEXT,
        notes TEXT,
        cost REAL,
        blockchain_tx_id TEXT,
        FOREIGN KEY (batch_id) REFERENCES batches(id),
        FOREIGN KEY (template_id) REFERENCES qc_test_templates(id)
      );
    `);

    // QC Test Parameters - Specific parameters being tested
    db.exec(`
      CREATE TABLE IF NOT EXISTS qc_test_parameters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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

    // QC Results - Actual test results
    db.exec(`
      CREATE TABLE IF NOT EXISTS qc_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_id TEXT NOT NULL,
        parameter_id INTEGER,
        parameter_name TEXT NOT NULL,
        measured_value TEXT,
        measured_numeric REAL,
        unit TEXT,
        pass_fail TEXT CHECK (pass_fail IN ('PASS', 'FAIL', 'WARNING', 'NA')),
        deviation REAL,
        remarks TEXT,
        measured_at TEXT DEFAULT (datetime('now')),
        measured_by TEXT,
        verified_by TEXT,
        verified_at TEXT,
        FOREIGN KEY (test_id) REFERENCES qc_tests(id) ON DELETE CASCADE,
        FOREIGN KEY (parameter_id) REFERENCES qc_test_parameters(id) ON DELETE SET NULL
      );
    `);

    // QC Certificates - Final certificates issued after testing
    db.exec(`
      CREATE TABLE IF NOT EXISTS qc_certificates (
        id TEXT PRIMARY KEY,
        certificate_number TEXT UNIQUE NOT NULL,
        test_id TEXT NOT NULL,
        batch_id TEXT NOT NULL,
        overall_result TEXT NOT NULL CHECK (overall_result IN ('PASS', 'FAIL', 'CONDITIONAL')),
        certificate_data TEXT NOT NULL,
        issued_by TEXT NOT NULL,
        issued_date TEXT DEFAULT (datetime('now')),
        issued_at TEXT DEFAULT (datetime('now')),
        valid_until TEXT,
        file_path TEXT,
        digital_signature TEXT,
        blockchain_txid TEXT,
        blockchain_tx_id TEXT,
        blockchain_timestamp TEXT,
        FOREIGN KEY (test_id) REFERENCES qc_tests(id),
        FOREIGN KEY (batch_id) REFERENCES batches(id)
      );

      -- Phase 7: Analytics & Reporting Tables
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
        calculation_date TEXT DEFAULT (datetime('now')),
        date_from TEXT,
        date_to TEXT,
        metadata TEXT,
        created_at TEXT DEFAULT (datetime('now'))
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
        generated_at TEXT DEFAULT (datetime('now')),
        file_path TEXT,
        file_size INTEGER,
        status TEXT DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'GENERATING', 'COMPLETED', 'FAILED')),
        error_message TEXT,
        download_count INTEGER DEFAULT 0,
        expires_at TEXT
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
        is_active INTEGER DEFAULT 1,
        last_run TEXT,
        next_run TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      );

      CREATE TABLE IF NOT EXISTS dashboard_cache (
        id TEXT PRIMARY KEY,
        cache_key TEXT UNIQUE NOT NULL,
        cache_data TEXT NOT NULL,
        entity_id TEXT,
        entity_type TEXT,
        expires_at TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      );
    `);

    // Create indexes
    db.exec(`
      CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
      CREATE INDEX IF NOT EXISTS idx_users_org_name ON users(org_name);
      CREATE INDEX IF NOT EXISTS idx_registration_status ON registration_requests(status);
      CREATE INDEX IF NOT EXISTS idx_collections_farmer ON collection_events_cache(farmer_id);
      CREATE INDEX IF NOT EXISTS idx_collections_sync ON collection_events_cache(sync_status);
      CREATE INDEX IF NOT EXISTS idx_batches_processor ON batches(assigned_to);
      CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
      CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts(alert_type);
      CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
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

    // Insert default admin user (password: admin123)
    const adminExists = db.prepare('SELECT COUNT(*) as count FROM users WHERE username = ?').get('admin') as { count: number };
    
    if (adminExists.count === 0) {
      const bcrypt = require('bcryptjs');
      const hashedPassword = bcrypt.hashSync('admin123', 10);
      
      db.prepare(`
        INSERT INTO users (id, user_id, username, email, password_hash, full_name, role, org_name, org_msp, affiliation)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
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
      );
      
      logger.info('✅ Default admin user created (username: admin, password: admin123)');
    }

    // Run migrations for existing tables
    runMigrations();

    logger.info('✅ Database schema initialized successfully');
  } catch (error) {
    logger.error('Failed to initialize database schema:', error);
    throw error;
  }
};

// Run database migrations
const runMigrations = (): void => {
  try {
    // Migration: Add role column to registration_requests if it doesn't exist
    const tableInfo = db.prepare(`PRAGMA table_info(registration_requests)`).all() as any[];
    const hasRoleColumn = tableInfo.some((col: any) => col.name === 'role');
    const hasOrgNameColumn = tableInfo.some((col: any) => col.name === 'organization_name');
    const hasAadharColumn = tableInfo.some((col: any) => col.name === 'aadhar_number');

    if (!hasRoleColumn) {
      logger.info('Running migration: Adding role column to registration_requests');
      db.exec(`ALTER TABLE registration_requests ADD COLUMN role TEXT NOT NULL DEFAULT 'Farmer'`);
      logger.info('✅ Added role column');
    }

    if (!hasOrgNameColumn) {
      logger.info('Running migration: Adding organization_name column to registration_requests');
      db.exec(`ALTER TABLE registration_requests ADD COLUMN organization_name TEXT`);
      logger.info('✅ Added organization_name column');
    }

    if (!hasAadharColumn) {
      logger.info('Running migration: Adding aadhar_number column to registration_requests');
      db.exec(`ALTER TABLE registration_requests ADD COLUMN aadhar_number TEXT`);
      logger.info('✅ Added aadhar_number column');
    }
  } catch (error) {
    logger.error('Migration error:', error);
    // Don't throw - migrations should be non-fatal
  }
};

// Test connection function
export const testConnection = async (): Promise<boolean> => {
  try {
    const result = db.prepare("SELECT datetime('now') as now").get() as { now: string };
    logger.info('Database connection successful:', result);
    return true;
  } catch (error) {
    logger.error('Database connection failed:', error);
    return false;
  }
};

// Export database instance
export { db };
