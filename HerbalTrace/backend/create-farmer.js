const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const path = require('path');

const dbPath = path.join(__dirname, 'data', 'herbaltrace.db');
console.log('Database path:', dbPath);
const db = new Database(dbPath);

const password = bcrypt.hashSync('farmer123', 10);

const stmt = db.prepare(`
  INSERT OR REPLACE INTO users (
    id, user_id, username, email, password_hash, full_name, role, 
    org_name, status, created_at, updated_at
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
`);

try {
  stmt.run(
    'farmer1',
    'USR-FARMER-001',
    'farmer1',
    'farmer1@herbaltrace.com',
    password,
    'Test Farmer',
    'Farmer',
    'Green Valley Farm',
    'active'
  );
  console.log('✅ Farmer user created successfully');
  console.log('Username: farmer1');
  console.log('Password: farmer123');
  console.log('Role: Farmer');
  console.log('Organization: Green Valley Farm');
} catch (error) {
  console.error('Error creating farmer:', error.message);
}

db.close();
