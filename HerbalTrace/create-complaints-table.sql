-- Create farmer complaints table in Railway PostgreSQL

CREATE TABLE IF NOT EXISTS farmer_complaints (
  id SERIAL PRIMARY KEY,
  complaint_id TEXT UNIQUE NOT NULL,
  farmer_id TEXT NOT NULL,
  farmer_name TEXT NOT NULL,
  farmer_phone TEXT,
  farmer_email TEXT,
  complaint_type TEXT NOT NULL CHECK (complaint_type IN (
    'PAYMENT_ISSUE',
    'QUALITY_DISPUTE',
    'DELIVERY_PROBLEM',
    'PRICING_CONCERN',
    'DOCUMENTATION_ERROR',
    'SUPPORT_REQUEST',
    'TECHNICAL_ISSUE',
    'FRAUD_REPORT',
    'OTHER'
  )),
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  priority TEXT DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED')),
  related_collection_id TEXT,
  related_batch_id TEXT,
  attachments TEXT,
  location TEXT,
  submitted_by TEXT NOT NULL,
  assigned_to TEXT,
  resolution_notes TEXT,
  resolved_by TEXT,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (farmer_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_complaints_farmer ON farmer_complaints(farmer_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON farmer_complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_type ON farmer_complaints(complaint_type);
CREATE INDEX IF NOT EXISTS idx_complaints_priority ON farmer_complaints(priority);
CREATE INDEX IF NOT EXISTS idx_complaints_created ON farmer_complaints(created_at DESC);

-- Success message
SELECT 'Farmer complaints table created successfully!' AS status;
