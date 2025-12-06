const Database = require('better-sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, 'data', 'herbaltrace.db');
console.log('Database path:', dbPath);

const db = new Database(dbPath, { readonly: true });

try {
  const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").all();
  console.log('\n=== Tables in database ===');
  tables.forEach(t => console.log('-', t.name));
  
  const hasBatches = tables.some(t => t.name === 'batches');
  console.log('\nBatches table exists:', hasBatches);
  
  if (hasBatches) {
    const columns = db.prepare("PRAGMA table_info(batches)").all();
    console.log('\n=== Batches table columns ===');
    columns.forEach(c => console.log(`- ${c.name} (${c.type})`));
  }
} finally {
  db.close();
}
