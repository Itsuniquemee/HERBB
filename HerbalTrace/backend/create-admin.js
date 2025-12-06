const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const path = require('path');

const dbPath = path.join(__dirname, 'data', 'herbaltrace.db');
console.log('Database path:', dbPath);
const db = new Database(dbPath);

const password = bcrypt.hashSync('Admin@123', 10);

const stmt = db.prepare(`
  INSERT OR REPLACE INTO users (
    id, user_id, username, email, password_hash, full_name, role, 
    org_name, status, created_at, updated_at
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
`);

try {
  stmt.run(
    'admin',
    'USR-ADMIN-001',
    'admin',
    'admin@herbaltrace.com',
    password,
    'System Administrator',
    'Admin',
    'HerbalTrace',
    'active'
  );
  console.log('✅ Admin user created successfully');
  console.log('Username: admin');
  console.log('Password: Admin@123');
} catch (error) {
  console.error('Error creating admin:', error.message);
}

db.close();
