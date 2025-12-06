const Database = require('better-sqlite3');
const path = require('path');

const db = new Database(path.join(__dirname, './data/herbaltrace.db'));

console.log('📊 Collections from last 2 hours:\n');

const recent = db.prepare(`
  SELECT 
    id, 
    farmer_id, 
    species, 
    quantity,
    sync_status, 
    created_at
  FROM collection_events_cache 
  WHERE created_at > datetime('now', '-2 hours')
  ORDER BY created_at DESC
`).all();

console.log(`Found ${recent.length} collections\n`);

if (recent.length === 0) {
  console.log('No collections in the last 2 hours.');
  console.log('\nMost recent collection overall:');
  const latest = db.prepare('SELECT id, created_at, sync_status FROM collection_events_cache ORDER BY created_at DESC LIMIT 1').get();
  console.log(latest);
} else {
  recent.forEach((col, idx) => {
    console.log(`${idx + 1}. ${col.id}`);
    console.log(`   Farmer: ${col.farmer_id}`);
    console.log(`   Species: ${col.species} (${col.quantity})`);
    console.log(`   Status: ${col.sync_status}`);
    console.log(`   Created: ${col.created_at}\n`);
  });
}

db.close();
