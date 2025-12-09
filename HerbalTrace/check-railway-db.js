// Script to check actual database tables via API
const fetch = require('node-fetch');

const API_URL = 'https://herbal-trace-production.up.railway.app';

async function checkDatabase() {
  try {
    // Login to get token
    console.log('🔐 Logging in...');
    const loginResponse = await fetch(`${API_URL}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'admin',
        password: 'admin123'
      })
    });
    
    const loginData = await loginResponse.json();
    if (!loginData.success) {
      throw new Error('Login failed');
    }
    
    const token = loginData.data.token;
    console.log('✅ Login successful\n');
    
    // Check various endpoints to see what data exists
    const endpoints = [
      '/api/v1/collections',
      '/api/v1/users',
      '/api/v1/batches',
      '/api/v1/products',
      '/api/v1/quality-tests'
    ];
    
    console.log('📊 Checking database tables via API:\n');
    
    for (const endpoint of endpoints) {
      try {
        const response = await fetch(`${API_URL}${endpoint}`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        
        const data = await response.json();
        
        if (data.success && Array.isArray(data.data)) {
          console.log(`✅ ${endpoint}: ${data.data.length} records`);
        } else if (data.success && typeof data.count === 'number') {
          console.log(`✅ ${endpoint}: ${data.count} records`);
        } else {
          console.log(`⚠️  ${endpoint}: ${data.message || 'No data'}`);
        }
      } catch (error) {
        console.log(`❌ ${endpoint}: Error - ${error.message}`);
      }
    }
    
    // Check database health
    console.log('\n🏥 Database Health Check:');
    const healthResponse = await fetch(`${API_URL}/api/v1/health/database`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    const healthData = await healthResponse.json();
    console.log(JSON.stringify(healthData, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkDatabase();
