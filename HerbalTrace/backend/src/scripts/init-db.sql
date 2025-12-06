-- HerbalTrace Database Schema
-- PostgreSQL 14+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tables if exist (for clean setup)
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS recall_records CASCADE;
DROP TABLE IF EXISTS quality_tests_cache CASCADE;
DROP TABLE IF EXISTS processing_steps_cache CASCADE;
DROP TABLE IF EXISTS batches CASCADE;
DROP TABLE IF EXISTS collection_events_cache CASCADE;
DROP TABLE IF EXISTS registration_requests CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(100) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL CHECK (role IN ('Farmer', 'Lab', 'Processor', 'Manufacturer', 'Consumer', 'Admin', 'Regulator')),
    org_name VARCHAR(100) NOT NULL,
    org_msp VARCHAR(100), -- Fabric MSP ID
    affiliation VARCHAR(200),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    created_by VARCHAR(100)
);

-- Registration Requests Table
CREATE TABLE registration_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    location_district VARCHAR(100),
    location_state VARCHAR(100),
    location_coordinates POINT, -- GPS location
    species_interest TEXT[], -- Array of species
    farm_size_acres DECIMAL(10, 2),
    experience_years INTEGER,
    farm_photos TEXT[], -- Array of image URLs
    certifications TEXT[], -- Organic, etc.
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    approved_by VARCHAR(100),
    approved_date TIMESTAMP,
    rejection_reason TEXT
);

-- Collection Events Cache (for offline sync)
CREATE TABLE collection_events_cache (
    id VARCHAR(100) PRIMARY KEY,
    farmer_id VARCHAR(100) NOT NULL,
    farmer_name VARCHAR(255),
    species VARCHAR(100) NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(20) DEFAULT 'kg',
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    altitude DECIMAL(10, 2),
    harvest_date DATE NOT NULL,
    data_json JSONB NOT NULL, -- Complete collection event data
    sync_status VARCHAR(20) DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed')),
    blockchain_tx_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP,
    error_message TEXT
);

-- Batches Table
CREATE TABLE batches (
    id VARCHAR(100) PRIMARY KEY,
    collection_ids TEXT[] NOT NULL, -- Array of collection IDs
    assigned_processor_id VARCHAR(100),
    assigned_processor_name VARCHAR(255),
    species VARCHAR(100) NOT NULL,
    total_quantity DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(20) DEFAULT 'kg',
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    admin_notes TEXT,
    status VARCHAR(50) DEFAULT 'assigned' CHECK (status IN ('assigned', 'in_processing', 'processing_complete', 'quality_tested', 'approved', 'rejected')),
    assigned_by VARCHAR(100),
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processing_started_at TIMESTAMP,
    processing_completed_at TIMESTAMP,
    quality_tested_at TIMESTAMP,
    blockchain_tx_id VARCHAR(255)
);

-- Processing Steps Cache
CREATE TABLE processing_steps_cache (
    id VARCHAR(100) PRIMARY KEY,
    batch_id VARCHAR(100) NOT NULL REFERENCES batches(id),
    processor_id VARCHAR(100) NOT NULL,
    process_type VARCHAR(50) NOT NULL CHECK (process_type IN ('drying', 'grinding', 'storage', 'extraction', 'mixing')),
    input_quantity DECIMAL(10, 2),
    output_quantity DECIMAL(10, 2),
    loss_percentage DECIMAL(5, 2),
    temperature DECIMAL(5, 2), -- Celsius
    humidity DECIMAL(5, 2), -- Percentage
    duration DECIMAL(10, 2), -- Hours
    equipment_id VARCHAR(100),
    data_json JSONB NOT NULL,
    sync_status VARCHAR(20) DEFAULT 'pending',
    blockchain_tx_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP
);

-- Quality Tests Cache
CREATE TABLE quality_tests_cache (
    id VARCHAR(100) PRIMARY KEY,
    batch_id VARCHAR(100) NOT NULL REFERENCES batches(id),
    lab_id VARCHAR(100) NOT NULL,
    lab_name VARCHAR(255),
    test_date DATE NOT NULL,
    moisture_content DECIMAL(5, 2),
    pesticide_results JSONB,
    heavy_metals JSONB,
    dna_barcode_match BOOLEAN,
    microbial_load DECIMAL(10, 2),
    overall_result VARCHAR(20) CHECK (overall_result IN ('pass', 'fail', 'conditional')),
    grade VARCHAR(2) CHECK (grade IN ('A', 'B', 'C', 'F')),
    certificate_url TEXT,
    data_json JSONB NOT NULL,
    sync_status VARCHAR(20) DEFAULT 'pending',
    blockchain_tx_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP
);

-- Alerts Table
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN (
        'GEO_FENCE_VIOLATION',
        'HARVEST_LIMIT_EXCEEDED',
        'SEASONAL_WINDOW_VIOLATION',
        'QUALITY_TEST_FAILED',
        'PROCESSING_ALERT',
        'EXPIRED_BATCH',
        'RECALL_NOTICE',
        'SYSTEM_ALERT'
    )),
    severity VARCHAR(20) DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('collection', 'batch', 'test', 'product', 'user', 'system')),
    entity_id VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    details JSONB,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved', 'dismissed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP,
    resolved_by VARCHAR(100),
    resolved_at TIMESTAMP,
    resolution_notes TEXT
);

-- Recall Records Table
CREATE TABLE recall_records (
    id VARCHAR(100) PRIMARY KEY,
    affected_batch_ids TEXT[] NOT NULL,
    affected_product_ids TEXT[],
    reason TEXT NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'in_progress', 'completed', 'cancelled')),
    total_products_affected INTEGER DEFAULT 0,
    products_located INTEGER DEFAULT 0,
    products_returned INTEGER DEFAULT 0,
    initiated_by VARCHAR(100) NOT NULL,
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    blockchain_tx_id VARCHAR(255)
);

-- Indexes for performance
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_org_name ON users(org_name);
CREATE INDEX idx_users_status ON users(status);

CREATE INDEX idx_registration_requests_status ON registration_requests(status);
CREATE INDEX idx_registration_requests_date ON registration_requests(request_date DESC);

CREATE INDEX idx_collections_farmer ON collection_events_cache(farmer_id);
CREATE INDEX idx_collections_species ON collection_events_cache(species);
CREATE INDEX idx_collections_sync_status ON collection_events_cache(sync_status);
CREATE INDEX idx_collections_date ON collection_events_cache(harvest_date DESC);

CREATE INDEX idx_batches_processor ON batches(assigned_processor_id);
CREATE INDEX idx_batches_status ON batches(status);
CREATE INDEX idx_batches_species ON batches(species);
CREATE INDEX idx_batches_date ON batches(assigned_date DESC);

CREATE INDEX idx_processing_batch ON processing_steps_cache(batch_id);
CREATE INDEX idx_processing_type ON processing_steps_cache(process_type);

CREATE INDEX idx_quality_batch ON quality_tests_cache(batch_id);
CREATE INDEX idx_quality_lab ON quality_tests_cache(lab_id);
CREATE INDEX idx_quality_grade ON quality_tests_cache(grade);

CREATE INDEX idx_alerts_type ON alerts(alert_type);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_entity ON alerts(entity_type, entity_id);
CREATE INDEX idx_alerts_date ON alerts(created_at DESC);

CREATE INDEX idx_recalls_status ON recall_records(status);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to users table
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default admin user (password: admin123)
INSERT INTO users (user_id, username, email, password_hash, full_name, role, org_name, org_msp, affiliation)
VALUES (
    'admin-001',
    'admin',
    'admin@herbaltrace.com',
    '$2a$10$7K8JqE.YvZ0WZxJb0YZFxO.4tXc0EYZvV6vZq5C7xqJ8Z5Z5Z5Z5Z', -- hash of 'admin123'
    'System Administrator',
    'Admin',
    'HerbalTrace',
    'HerbalTraceMSP',
    'admin.department1'
);

-- Success message
SELECT 'Database schema initialized successfully!' as message;
