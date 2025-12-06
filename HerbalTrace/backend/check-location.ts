import Database from 'better-sqlite3';
import path from 'path';

const db = new Database(path.join(__dirname, './data/herbaltrace.db'));

const users = db.prepare(`
  SELECT u.username, u.email, r.location_district, r.location_state
  FROM users u
  LEFT JOIN registration_requests r ON u.email = r.email
  WHERE u.role = 'Farmer'
`).all();

console.log('Farmer location data:');
console.log(JSON.stringify(users, null, 2));

db.close();
