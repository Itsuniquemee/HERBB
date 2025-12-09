-- Create admin user in PostgreSQL
INSERT INTO users (
  id, user_id, username, email, password_hash, full_name, 
  phone, role, org_name, org_msp, affiliation, 
  location_district, location_state, status, created_at
) VALUES (
  'user-admin-001',
  'admin-001',
  'admin',
  'admin@herbaltrace.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  'System Administrator',
  '+919876543210',
  'Admin',
  'HerbalTrace',
  'HerbalTraceMSP',
  'admin',
  'Dehradun',
  'Uttarakhand',
  'active',
  CURRENT_TIMESTAMP
);

-- Create a farmer user
INSERT INTO users (
  id, user_id, username, email, password_hash, full_name, 
  phone, role, org_name, location_district, location_state, 
  status, created_at
) VALUES (
  'user-farmer-001',
  'farmer-001',
  'farmer1',
  'farmer1@herbaltrace.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  'Rajesh Kumar',
  '+919876543211',
  'Farmer',
  'Kumar Herbs Farm',
  'Dehradun',
  'Uttarakhand',
  'active',
  CURRENT_TIMESTAMP
);
