/**
 * Import Railway data to local blockchain backend
 * This script:
 * 1. Reads JSON exports from Railway
 * 2. Imports data into local SQLite database
 * 3. Registers transactions on Hyperledger Fabric blockchain
 */

import fs from 'fs';
import path from 'path';
import { db } from './backend/src/config/database.sqlite';
import { fabricService } from './backend/src/services/FabricService';
import bcrypt from 'bcryptjs';

interface MigrationStats {
  users: { imported: number; skipped: number; errors: number };
  collections: { imported: number; skipped: number; errors: number; blockchain: number };
  qualityTests: { imported: number; skipped: number; errors: number; blockchain: number };
  batches: { imported: number; skipped: number; errors: number; blockchain: number };
  products: { imported: number; skipped: number; errors: number; blockchain: number };
}

const stats: MigrationStats = {
  users: { imported: 0, skipped: 0, errors: 0 },
  collections: { imported: 0, skipped: 0, errors: 0, blockchain: 0 },
  qualityTests: { imported: 0, skipped: 0, errors: 0, blockchain: 0 },
  batches: { imported: 0, skipped: 0, errors: 0, blockchain: 0 },
  products: { imported: 0, skipped: 0, errors: 0, blockchain: 0 },
};

async function findLatestBackup(): Promise<string> {
  const backupDirs = fs.readdirSync('.')
    .filter(name => name.startsWith('railway-backup-'))
    .sort()
    .reverse();
  
  if (backupDirs.length === 0) {
    throw new Error('No backup directory found. Run migrate-railway-to-local.sh first.');
  }
  
  return backupDirs[0];
}

async function importUsers(backupDir: string): Promise<void> {
  console.log('\n📥 Importing users...');
  const usersFile = path.join(backupDir, 'users.json');
  
  if (!fs.existsSync(usersFile)) {
    console.log('⚠️  No users.json found, skipping...');
    return;
  }
  
  const users = JSON.parse(fs.readFileSync(usersFile, 'utf-8'));
  
  for (const user of users) {
    try {
      // Check if user already exists
      const existing = db.prepare('SELECT id FROM users WHERE user_id = ?').get(user.user_id);
      
      if (existing) {
        console.log(`⏭️  User ${user.username} already exists, skipping...`);
        stats.users.skipped++;
        continue;
      }
      
      // Insert user
      db.prepare(`
        INSERT INTO users (
          id, user_id, username, email, password_hash, full_name, phone, role,
          org_name, org_msp, affiliation, location_district, location_state,
          status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        user.id, user.user_id, user.username, user.email, user.password_hash,
        user.full_name, user.phone, user.role, user.org_name, user.org_msp,
        user.affiliation, user.location_district, user.location_state,
        user.status, user.created_at
      );
      
      console.log(`✅ Imported user: ${user.username} (${user.role})`);
      stats.users.imported++;
    } catch (error: any) {
      console.error(`❌ Error importing user ${user.username}:`, error.message);
      stats.users.errors++;
    }
  }
}

async function importCollections(backupDir: string): Promise<void> {
  console.log('\n📥 Importing collection events...');
  const collectionsFile = path.join(backupDir, 'collections.json');
  
  if (!fs.existsSync(collectionsFile)) {
    console.log('⚠️  No collections.json found, skipping...');
    return;
  }
  
  const collections = JSON.parse(fs.readFileSync(collectionsFile, 'utf-8'));
  
  for (const collection of collections) {
    try {
      // Check if collection already exists
      const existing = db.prepare('SELECT id FROM collection_events_cache WHERE collection_id = ?')
        .get(collection.collection_id);
      
      if (existing) {
        console.log(`⏭️  Collection ${collection.collection_id} already exists, skipping...`);
        stats.collections.skipped++;
        continue;
      }
      
      // Insert into local database
      db.prepare(`
        INSERT INTO collection_events_cache (
          id, collection_id, farmer_id, species, scientific_name, common_name,
          quantity, unit, latitude, longitude, altitude, accuracy, harvest_date,
          harvest_method, part_collected, weather_conditions, soil_type,
          moisture_content, conservation_status, certification_ids, images,
          blockchain_tx_id, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        collection.id, collection.collection_id, collection.farmer_id,
        collection.species, collection.scientific_name, collection.common_name,
        collection.quantity, collection.unit, collection.latitude, collection.longitude,
        collection.altitude, collection.accuracy, collection.harvest_date,
        collection.harvest_method, collection.part_collected, collection.weather_conditions,
        collection.soil_type, collection.moisture_content, collection.conservation_status,
        collection.certification_ids, collection.images, collection.blockchain_tx_id,
        collection.created_at, collection.updated_at
      );
      
      stats.collections.imported++;
      console.log(`✅ Imported collection: ${collection.collection_id} (${collection.species})`);
      
      // Register on blockchain if not already registered
      if (!collection.blockchain_tx_id) {
        try {
          const txId = await fabricService.registerCollection({
            collectionId: collection.collection_id,
            farmerId: collection.farmer_id,
            species: collection.species,
            quantity: collection.quantity,
            unit: collection.unit,
            location: {
              latitude: collection.latitude,
              longitude: collection.longitude,
            },
            harvestDate: collection.harvest_date,
          });
          
          // Update with blockchain tx ID
          db.prepare('UPDATE collection_events_cache SET blockchain_tx_id = ? WHERE collection_id = ?')
            .run(txId, collection.collection_id);
          
          console.log(`  🔗 Registered on blockchain: ${txId}`);
          stats.collections.blockchain++;
        } catch (error: any) {
          console.warn(`  ⚠️  Blockchain registration failed: ${error.message}`);
        }
      }
    } catch (error: any) {
      console.error(`❌ Error importing collection ${collection.collection_id}:`, error.message);
      stats.collections.errors++;
    }
  }
}

async function importQualityTests(backupDir: string): Promise<void> {
  console.log('\n📥 Importing quality tests...');
  const testsFile = path.join(backupDir, 'quality_tests.json');
  
  if (!fs.existsSync(testsFile)) {
    console.log('⚠️  No quality_tests.json found, skipping...');
    return;
  }
  
  const tests = JSON.parse(fs.readFileSync(testsFile, 'utf-8'));
  
  for (const test of tests) {
    try {
      const existing = db.prepare('SELECT id FROM quality_tests_cache WHERE test_id = ?').get(test.test_id);
      
      if (existing) {
        stats.qualityTests.skipped++;
        continue;
      }
      
      db.prepare(`
        INSERT INTO quality_tests_cache (
          id, test_id, collection_id, tester_id, test_date, test_type,
          test_results, passed, certification_number, notes, blockchain_tx_id,
          created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        test.id, test.test_id, test.collection_id, test.tester_id,
        test.test_date, test.test_type, test.test_results, test.passed,
        test.certification_number, test.notes, test.blockchain_tx_id,
        test.created_at, test.updated_at
      );
      
      stats.qualityTests.imported++;
      console.log(`✅ Imported quality test: ${test.test_id}`);
      
      // Register on blockchain if needed
      if (!test.blockchain_tx_id) {
        try {
          const txId = await fabricService.registerQualityTest({
            testId: test.test_id,
            collectionId: test.collection_id,
            testerId: test.tester_id,
            testResults: JSON.parse(test.test_results),
            passed: test.passed === 1,
          });
          
          db.prepare('UPDATE quality_tests_cache SET blockchain_tx_id = ? WHERE test_id = ?')
            .run(txId, test.test_id);
          
          console.log(`  🔗 Registered on blockchain: ${txId}`);
          stats.qualityTests.blockchain++;
        } catch (error: any) {
          console.warn(`  ⚠️  Blockchain registration failed: ${error.message}`);
        }
      }
    } catch (error: any) {
      console.error(`❌ Error importing test ${test.test_id}:`, error.message);
      stats.qualityTests.errors++;
    }
  }
}

async function importBatches(backupDir: string): Promise<void> {
  console.log('\n📥 Importing processing batches...');
  const batchesFile = path.join(backupDir, 'batches.json');
  
  if (!fs.existsSync(batchesFile)) {
    console.log('⚠️  No batches.json found, skipping...');
    return;
  }
  
  const batches = JSON.parse(fs.readFileSync(batchesFile, 'utf-8'));
  
  for (const batch of batches) {
    try {
      const existing = db.prepare('SELECT id FROM processing_batches_cache WHERE batch_id = ?')
        .get(batch.batch_id);
      
      if (existing) {
        stats.batches.skipped++;
        continue;
      }
      
      db.prepare(`
        INSERT INTO processing_batches_cache (
          id, batch_id, processor_id, collection_ids, processing_date,
          processing_type, output_quantity, output_unit, quality_grade,
          storage_conditions, blockchain_tx_id, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        batch.id, batch.batch_id, batch.processor_id, batch.collection_ids,
        batch.processing_date, batch.processing_type, batch.output_quantity,
        batch.output_unit, batch.quality_grade, batch.storage_conditions,
        batch.blockchain_tx_id, batch.created_at, batch.updated_at
      );
      
      stats.batches.imported++;
      console.log(`✅ Imported batch: ${batch.batch_id}`);
      
      if (!batch.blockchain_tx_id) {
        try {
          const txId = await fabricService.registerBatch({
            batchId: batch.batch_id,
            processorId: batch.processor_id,
            collectionIds: JSON.parse(batch.collection_ids),
            processingType: batch.processing_type,
            outputQuantity: batch.output_quantity,
          });
          
          db.prepare('UPDATE processing_batches_cache SET blockchain_tx_id = ? WHERE batch_id = ?')
            .run(txId, batch.batch_id);
          
          console.log(`  🔗 Registered on blockchain: ${txId}`);
          stats.batches.blockchain++;
        } catch (error: any) {
          console.warn(`  ⚠️  Blockchain registration failed: ${error.message}`);
        }
      }
    } catch (error: any) {
      console.error(`❌ Error importing batch ${batch.batch_id}:`, error.message);
      stats.batches.errors++;
    }
  }
}

async function importProducts(backupDir: string): Promise<void> {
  console.log('\n📥 Importing products...');
  const productsFile = path.join(backupDir, 'products.json');
  
  if (!fs.existsSync(productsFile)) {
    console.log('⚠️  No products.json found, skipping...');
    return;
  }
  
  const products = JSON.parse(fs.readFileSync(productsFile, 'utf-8'));
  
  for (const product of products) {
    try {
      const existing = db.prepare('SELECT id FROM products_cache WHERE product_id = ?')
        .get(product.product_id);
      
      if (existing) {
        stats.products.skipped++;
        continue;
      }
      
      db.prepare(`
        INSERT INTO products_cache (
          id, product_id, manufacturer_id, batch_ids, product_name,
          product_type, packaging_date, expiry_date, certifications,
          blockchain_tx_id, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        product.id, product.product_id, product.manufacturer_id,
        product.batch_ids, product.product_name, product.product_type,
        product.packaging_date, product.expiry_date, product.certifications,
        product.blockchain_tx_id, product.created_at, product.updated_at
      );
      
      stats.products.imported++;
      console.log(`✅ Imported product: ${product.product_id}`);
      
      if (!product.blockchain_tx_id) {
        try {
          const txId = await fabricService.registerProduct({
            productId: product.product_id,
            manufacturerId: product.manufacturer_id,
            batchIds: JSON.parse(product.batch_ids),
            productName: product.product_name,
          });
          
          db.prepare('UPDATE products_cache SET blockchain_tx_id = ? WHERE product_id = ?')
            .run(txId, product.product_id);
          
          console.log(`  🔗 Registered on blockchain: ${txId}`);
          stats.products.blockchain++;
        } catch (error: any) {
          console.warn(`  ⚠️  Blockchain registration failed: ${error.message}`);
        }
      }
    } catch (error: any) {
      console.error(`❌ Error importing product ${product.product_id}:`, error.message);
      stats.products.errors++;
    }
  }
}

async function main() {
  console.log('🚀 Railway to Local Migration - Import Phase');
  console.log('============================================\n');
  
  try {
    const backupDir = await findLatestBackup();
    console.log(`📂 Using backup directory: ${backupDir}\n`);
    
    await importUsers(backupDir);
    await importCollections(backupDir);
    await importQualityTests(backupDir);
    await importBatches(backupDir);
    await importProducts(backupDir);
    
    console.log('\n\n📊 Migration Summary');
    console.log('===================');
    console.log('Users:');
    console.log(`  ✅ Imported: ${stats.users.imported}`);
    console.log(`  ⏭️  Skipped: ${stats.users.skipped}`);
    console.log(`  ❌ Errors: ${stats.users.errors}`);
    
    console.log('\nCollections:');
    console.log(`  ✅ Imported: ${stats.collections.imported}`);
    console.log(`  🔗 Blockchain: ${stats.collections.blockchain}`);
    console.log(`  ⏭️  Skipped: ${stats.collections.skipped}`);
    console.log(`  ❌ Errors: ${stats.collections.errors}`);
    
    console.log('\nQuality Tests:');
    console.log(`  ✅ Imported: ${stats.qualityTests.imported}`);
    console.log(`  🔗 Blockchain: ${stats.qualityTests.blockchain}`);
    console.log(`  ⏭️  Skipped: ${stats.qualityTests.skipped}`);
    console.log(`  ❌ Errors: ${stats.qualityTests.errors}`);
    
    console.log('\nBatches:');
    console.log(`  ✅ Imported: ${stats.batches.imported}`);
    console.log(`  🔗 Blockchain: ${stats.batches.blockchain}`);
    console.log(`  ⏭️  Skipped: ${stats.batches.skipped}`);
    console.log(`  ❌ Errors: ${stats.batches.errors}`);
    
    console.log('\nProducts:');
    console.log(`  ✅ Imported: ${stats.products.imported}`);
    console.log(`  🔗 Blockchain: ${stats.products.blockchain}`);
    console.log(`  ⏭️  Skipped: ${stats.products.skipped}`);
    console.log(`  ❌ Errors: ${stats.products.errors}`);
    
    console.log('\n✅ Migration completed successfully!');
    
  } catch (error: any) {
    console.error('\n❌ Migration failed:', error.message);
    process.exit(1);
  }
}

main();
