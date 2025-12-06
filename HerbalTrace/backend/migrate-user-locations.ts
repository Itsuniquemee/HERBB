import Database from 'better-sqlite3';
import path from 'path';
import { logger } from './src/utils/logger';

const dbPath = path.join(__dirname, './data/herbaltrace.db');
const db = new Database(dbPath);

console.log('🔧 Adding location fields to users table...');

try {
  // Check if columns already exist
  const tableInfo = db.prepare('PRAGMA table_info(users)').all() as any[];
  const hasLocationDistrict = tableInfo.some((col: any) => col.name === 'location_district');
  const hasLocationState = tableInfo.some((col: any) => col.name === 'location_state');
  const hasLocationCoordinates = tableInfo.some((col: any) => col.name === 'location_coordinates');

  if (!hasLocationDistrict) {
    db.exec('ALTER TABLE users ADD COLUMN location_district TEXT');
    console.log('✅ Added location_district column');
  } else {
    console.log('ℹ️  location_district column already exists');
  }

  if (!hasLocationState) {
    db.exec('ALTER TABLE users ADD COLUMN location_state TEXT');
    console.log('✅ Added location_state column');
  } else {
    console.log('ℹ️  location_state column already exists');
  }

  if (!hasLocationCoordinates) {
    db.exec('ALTER TABLE users ADD COLUMN location_coordinates TEXT');
    console.log('✅ Added location_coordinates column');
  } else {
    console.log('ℹ️  location_coordinates column already exists');
  }

  // Migrate existing user location data from registration_requests
  console.log('\n🔄 Migrating location data for existing users...');
  
  const updateStmt = db.prepare(`
    UPDATE users
    SET 
      location_district = (SELECT location_district FROM registration_requests WHERE email = users.email),
      location_state = (SELECT location_state FROM registration_requests WHERE email = users.email),
      location_coordinates = (SELECT location_coordinates FROM registration_requests WHERE email = users.email)
    WHERE email IN (SELECT email FROM registration_requests)
  `);

  const result = updateStmt.run();
  console.log(`✅ Updated ${result.changes} user records with location data`);

  // Verify migration
  console.log('\n📊 Verifying farmer locations:');
  const farmers = db.prepare(`
    SELECT username, location_district, location_state 
    FROM users 
    WHERE role = 'Farmer'
  `).all();

  console.log(JSON.stringify(farmers, null, 2));

  console.log('\n✅ Migration completed successfully!');

} catch (error) {
  console.error('❌ Migration failed:', error);
  process.exit(1);
} finally {
  db.close();
}
