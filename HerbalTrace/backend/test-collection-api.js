const https = require('https');
const http = require('http');

// Read admin token
const fs = require('fs');
const adminToken = fs.readFileSync('./admin-token.txt', 'utf8').trim();

console.log('🧪 Testing Collection Submission with Region Field\n');

// Step 1: Create a test registration request
console.log('Step 1: Creating test farmer registration...');

const registrationData = JSON.stringify({
  fullName: "Test Farmer API",
  phone: "9999999999",
  email: `testfarmer${Date.now()}@test.com`,
  role: "Farmer",
  organizationName: "Test Farm",
  locationDistrict: "Test District",
  locationState: "Test State",
  speciesInterest: "Testing",
  farmSizeAcres: 5,
  experienceYears: 10
});

const regOptions = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/v1/auth/registration-request',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': registrationData.length
  }
};

const regReq = http.request(regOptions, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    const regResponse = JSON.parse(data);
    if (regResponse.success) {
      const requestId = regResponse.request?.id || regResponse.id;
      console.log('✅ Registration request created:', requestId);
      
      // Step 2: Approve the registration
      console.log('\nStep 2: Approving registration as admin...');
      
      const approvalData = JSON.stringify({
        role: "Farmer",
        orgName: "FarmersCoop",
        orgMsp: "FarmersCoopMSP"
      });
      
      const approveOptions = {
        hostname: 'localhost',
        port: 3000,
        path: `/api/v1/auth/registration-requests/${requestId}/approve`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken.trim()}`,
          'Content-Length': approvalData.length
        }
      };
      
      const approveReq = http.request(approveOptions, (res2) => {
        let approveData = '';
        res2.on('data', (chunk) => { approveData += chunk; });
        res2.on('end', () => {
          const approveResponse = JSON.parse(approveData);
          if (approveResponse.success) {
            console.log('✅ Registration approved!');
            console.log('   Username:', approveResponse.credentials.username);
            console.log('   Password:', approveResponse.credentials.password);
            console.log('   User ID:', approveResponse.credentials.userId);
            
            // Step 3: Login as the new farmer
            console.log('\nStep 3: Logging in as farmer...');
            
            const loginData = JSON.stringify({
              username: approveResponse.credentials.username,
              password: approveResponse.credentials.password
            });
            
            const loginOptions = {
              hostname: 'localhost',
              port: 3000,
              path: '/api/v1/auth/login',
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Content-Length': loginData.length
              }
            };
            
            const loginReq = http.request(loginOptions, (res3) => {
              let loginResData = '';
              res3.on('data', (chunk) => { loginResData += chunk; });
              res3.on('end', () => {
                const loginResponse = JSON.parse(loginResData);
                if (loginResponse.success) {
                  console.log('✅ Login successful!');
                  const farmerToken = loginResponse.token;
                  
                  // Step 4: Submit a collection
                  console.log('\nStep 4: Submitting collection event...');
                  
                  const collectionData = JSON.stringify({
                    species: "Ashwagandha",
                    commonName: "Indian Ginseng",
                    scientificName: "Withania somnifera",
                    quantity: 5.5,
                    unit: "kg",
                    latitude: 28.5355,
                    longitude: 77.3910,
                    accuracy: 10,
                    harvestDate: "2025-12-06",
                    harvestMethod: "manual",
                    partCollected: "roots",
                    weatherConditions: "sunny",
                    soilType: "loamy"
                  });
                  
                  const collectionOptions = {
                    hostname: 'localhost',
                    port: 3000,
                    path: '/api/v1/collections',
                    method: 'POST',
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': `Bearer ${farmerToken}`,
                      'Content-Length': collectionData.length
                    }
                  };
                  
                  const collectionReq = http.request(collectionOptions, (res4) => {
                    let collectionResData = '';
                    res4.on('data', (chunk) => { collectionResData += chunk; });
                    res4.on('end', () => {
                      const collectionResponse = JSON.parse(collectionResData);
                      console.log('\n📊 Collection Submission Result:');
                      console.log('   Success:', collectionResponse.success);
                      console.log('   Collection ID:', collectionResponse.collection?.id);
                      console.log('   Blockchain TX ID:', collectionResponse.collection?.blockchainTxId);
                      console.log('   Blockchain Sync:', collectionResponse.collection?.blockchainTxId ? '✅ SUCCESS' : '❌ FAILED');
                      
                      if (collectionResponse.message) {
                        console.log('   Message:', collectionResponse.message);
                      }
                      
                      if (!collectionResponse.success && collectionResponse.error) {
                        console.log('   Error:', collectionResponse.error);
                      }
                    });
                  });
                  
                  collectionReq.on('error', (e) => {
                    console.error('❌ Collection submission error:', e.message);
                  });
                  
                  collectionReq.write(collectionData);
                  collectionReq.end();
                  
                } else {
                  console.log('❌ Login failed:', loginResponse.message);
                }
              });
            });
            
            loginReq.on('error', (e) => {
              console.error('❌ Login error:', e.message);
            });
            
            loginReq.write(loginData);
            loginReq.end();
            
          } else {
            console.log('❌ Approval failed:', approveResponse.message);
          }
        });
      });
      
      approveReq.on('error', (e) => {
        console.error('❌ Approval error:', e.message);
      });
      
      approveReq.write(approvalData);
      approveReq.end();
      
    } else {
      console.log('❌ Registration failed:', regResponse.message);
    }
  });
});

regReq.on('error', (e) => {
  console.error('❌ Registration error:', e.message);
});

regReq.write(registrationData);
regReq.end();
