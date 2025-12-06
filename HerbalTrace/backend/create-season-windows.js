const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

// Season windows matching ValidationService.ts
const seasonWindows = [
  {
    id: 'sw-ashwagandha-noida',
    species: 'Ashwagandha',
    startMonth: 10,
    endMonth: 3,
    region: 'Greater Noida, UttarPradesh'
  },
  {
    id: 'sw-tulsi-noida',
    species: 'Tulsi',
    startMonth: 1,
    endMonth: 12, // Year-round
    region: 'Greater Noida, UttarPradesh'
  },
  {
    id: 'sw-turmeric-noida',
    species: 'Turmeric',
    startMonth: 1,
    endMonth: 3,
    region: 'Greater Noida, UttarPradesh'
  },
  {
    id: 'sw-senna-noida',
    species: 'Senna',
    startMonth: 10,
    endMonth: 2,
    region: 'Greater Noida, UttarPradesh'
  },
  {
    id: 'sw-brahmi-noida',
    species: 'Brahmi',
    startMonth: 1,
    endMonth: 12, // Year-round
    region: 'Greater Noida, UttarPradesh'
  },
  {
    id: 'sw-neem-noida',
    species: 'Neem',
    startMonth: 1,
    endMonth: 12, // Year-round
    region: 'Greater Noida, UttarPradesh'
  }
];

async function createSeasonWindows() {
  try {
    // Load connection profile
    const ccpPath = path.resolve(__dirname, '..', 'network', 'organizations', 'peerOrganizations', 'farmerscoop.herbaltrace.com', 'connection-farmerscoop.json');
    const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

    // Create wallet instance
    const walletPath = path.join(__dirname, '..', 'network', 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    // Check if admin identity exists
    const identity = await wallet.get('admin-FarmersCoop');
    if (!identity) {
      console.error('Admin identity not found. Run enrollUser.ts first.');
      process.exit(1);
    }

    // Create gateway connection
    const gateway = new Gateway();
    await gateway.connect(ccp, {
      wallet,
      identity: 'admin-FarmersCoop',
      discovery: { enabled: false, asLocalhost: true }
    });

    // Get network and contract
    const network = await gateway.getNetwork('herbaltrace-channel');
    const contract = network.getContract('herbaltrace');

    console.log('Creating season windows on blockchain...\n');

    for (const window of seasonWindows) {
      try {
        const windowJSON = JSON.stringify({
          ...window,
          createdBy: 'system',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          active: true
        });

        console.log(`Creating season window for ${window.species} (months ${window.startMonth}-${window.endMonth})...`);
        await contract.submitTransaction('CreateSeasonWindow', windowJSON);
        console.log(`✅ Created season window: ${window.id}`);
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⏭️  Season window ${window.id} already exists, skipping`);
        } else {
          console.error(`❌ Failed to create ${window.id}:`, error.message);
        }
      }
    }

    console.log('\n✅ Season windows setup complete!');
    await gateway.disconnect();

  } catch (error) {
    console.error('Failed to create season windows:', error);
    process.exit(1);
  }
}

createSeasonWindows();
