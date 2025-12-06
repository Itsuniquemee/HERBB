/**
 * Script to manually register existing farmers in Fabric wallet
 * Run with: npx ts-node register-existing-farmer.ts
 */

import { FabricClient } from './src/fabric/fabricClient';
import Database from 'better-sqlite3';

async function registerExistingFarmers() {
  console.log('🔧 Registering existing farmers in Fabric wallet...\n');
  
  // Connect to database
  const db = new Database('./data/herbaltrace.db');
  
  // Get all farmers
  const farmers = db.prepare(`
    SELECT user_id, username, org_name 
    FROM users 
    WHERE role = 'Farmer'
  `).all();
  
  console.log(`Found ${farmers.length} farmers in database:\n`);
  
  const fabricClient = new FabricClient();
  
  for (const farmer of farmers as any[]) {
    try {
      console.log(`Registering: ${farmer.username} (${farmer.user_id})`);
      
      await fabricClient.registerUser(
        farmer.user_id,
        farmer.org_name,
        `${farmer.org_name.toLowerCase()}.department1`
      );
      
      console.log(`✅ Successfully registered: ${farmer.user_id}\n`);
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        console.log(`⚠️  Already registered: ${farmer.user_id}\n`);
      } else {
        console.error(`❌ Failed to register ${farmer.user_id}:`, error.message, '\n');
      }
    }
  }
  
  db.close();
  console.log('✅ Done!');
  process.exit(0);
}

registerExistingFarmers().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
