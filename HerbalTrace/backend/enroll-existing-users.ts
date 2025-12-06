import Database from 'better-sqlite3';
import * as path from 'path';
import { enrollUserWithAdminCert } from './src/utils/enrollUser';

const dbPath = path.join(__dirname, 'data', 'herbaltrace.db');
const db = new Database(dbPath);

async function enrollExistingUsers() {
  console.log('🔍 Finding users who need Fabric enrollment...\n');

  // Get all users except admin
  const users = db.prepare(`
    SELECT user_id, username, role, org_name
    FROM users
    WHERE role != 'Admin'
    ORDER BY created_at
  `).all() as any[];

  if (users.length === 0) {
    console.log('✅ No users found to enroll');
    return;
  }

  console.log(`Found ${users.length} users:\n`);

  let successCount = 0;
  let failCount = 0;

  for (const user of users) {
    console.log(`Enrolling: ${user.username} (${user.user_id})`);
    console.log(`  Role: ${user.role}`);
    console.log(`  Organization: ${user.org_name}`);

    try {
      const success = await enrollUserWithAdminCert(
        user.user_id,
        user.org_name,
        `${user.org_name.toLowerCase()}.department1`
      );

      if (success) {
        console.log(`  ✅ Successfully enrolled\n`);
        successCount++;
      } else {
        console.log(`  ❌ Enrollment failed\n`);
        failCount++;
      }
    } catch (error: any) {
      console.log(`  ❌ Error: ${error.message}\n`);
      failCount++;
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log('📊 Summary:');
  console.log(`   Total users: ${users.length}`);
  console.log(`   ✅ Successfully enrolled: ${successCount}`);
  console.log(`   ❌ Failed: ${failCount}`);
  console.log('='.repeat(60));

  if (successCount > 0) {
    console.log('\n🎉 Users can now submit blockchain transactions!');
    console.log('   Test by logging in as a farmer and creating a collection.');
  }
}

// Run the enrollment
enrollExistingUsers()
  .then(() => {
    console.log('\n✅ Enrollment process complete');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Enrollment failed:', error);
    process.exit(1);
  });
