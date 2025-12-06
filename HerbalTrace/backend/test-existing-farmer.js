const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api/v1';

async function testCollectionSubmission() {
  try {
    console.log('🔐 Step 1: Logging in as avinashverma...\n');
    
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
      username: 'avinashverma',
      password: 'HT4CAYXTEU'
    });

    console.log('✅ Login successful!');
    console.log('   Response:', JSON.stringify(loginResponse.data, null, 2));
    
    const token = loginResponse.data.token || loginResponse.data.data?.token;
    const user = loginResponse.data.user || loginResponse.data.data?.user;
    
    if (!token) {
      throw new Error('No token received from login');
    }
    
    console.log(`\n   Token received: ${token.substring(0, 20)}...\n`);

    console.log('📦 Step 2: Submitting collection event...\n');

    const collectionData = {
      species: 'Tulsi',
      commonName: 'Holy Basil',
      scientificName: 'Ocimum sanctum',
      quantity: 5.5, // Changed to avoid duplicate detection
      unit: 'kg',
      latitude: 28.5365,
      longitude: 77.3920,
      altitude: 210,
      accuracy: 10,
      harvestDate: '2025-11-20', // Changed date
      harvestMethod: 'manual',
      partCollected: 'leaves',
      weatherConditions: 'sunny',
      soilType: 'loamy'
    };

    const collectionResponse = await axios.post(
      `${BASE_URL}/collections`,
      collectionData,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Collection submitted successfully!\n');
    console.log('Response:', JSON.stringify(collectionResponse.data, null, 2));

    if (collectionResponse.data.data?.blockchainTxId) {
      console.log('\n🎉 BLOCKCHAIN SYNC SUCCESSFUL!');
      console.log(`   Transaction ID: ${collectionResponse.data.data.blockchainTxId}`);
    } else {
      console.log('\n⚠️  Collection saved but blockchain sync status unclear');
    }

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    if (error.response?.data?.details) {
      console.error('Details:', error.response.data.details);
    }
  }
}

testCollectionSubmission();
