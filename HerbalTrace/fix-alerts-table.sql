-- Fix alerts table schema in Railway PostgreSQL
-- This adds the missing columns and renames 'type' to 'alert_type'

-- First, check if the table exists and drop it to recreate with correct schema
DROP TABLE IF EXISTS alerts CASCADE;

-- Recreate alerts table with correct schema
CREATE TABLE alerts (
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
  triggered_by TEXT,
  acknowledged_by TEXT,
  acknowledged_at TIMESTAMP,
  resolved_by TEXT,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on alert_type for better query performance
CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_alerts_entity ON alerts(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts(severity);
CREATE INDEX IF NOT EXISTS idx_alerts_created ON alerts(created_at);

-- Success message
SELECT 'Alerts table schema fixed successfully!' AS status;
