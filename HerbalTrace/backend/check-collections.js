const Database = require('better-sqlite3');
const path = require('path');

const db = new Database(path.join(__dirname, './data/herbaltrace.db'));

console.log('📊 Recent Collections:\n');

const collections = db.prepare(`
  SELECT 
    id, 
    farmer_id, 
    farmer_name, 
    species, 
    quantity,
    unit,
    harvest_date, 
    sync_status,
    created_at
  FROM collection_events_cache 
  ORDER BY created_at DESC 
  LIMIT 5
`).all();

if (collections.length === 0) {
  console.log('No collections found in database.');
} else {
  collections.forEach((col, idx) => {
    console.log(`\n${idx + 1}. Collection ID: ${col.id}`);
    console.log(`   Farmer: ${col.farmer_name} (${col.farmer_id})`);
    console.log(`   Species: ${col.species}`);
    console.log(`   Quantity: ${col.quantity} ${col.unit}`);
    console.log(`   Harvest Date: ${col.harvest_date}`);
    console.log(`   Blockchain Status: ${col.sync_status}`);
    console.log(`   Created: ${col.created_at}`);
  });
}

db.close();
