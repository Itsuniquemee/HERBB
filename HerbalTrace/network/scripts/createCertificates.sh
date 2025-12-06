#!/bin/bash

# Generate crypto material using cryptogen tool
# This script creates all certificates and keys for the network

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_DIR="$SCRIPT_DIR/.."

echo "Generating certificates using cryptogen tool"

# Create cryptogen config
cat > "$NETWORK_DIR/crypto-config.yaml" << EOF
OrdererOrgs:
  - Name: Orderer
    Domain: herbaltrace.com
    EnableNodeOUs: true
    Specs:
      - Hostname: orderer
      - Hostname: orderer2
      - Hostname: orderer3

PeerOrgs:
  - Name: FarmersCoop
    Domain: farmerscoop.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 3

  - Name: TestingLabs
    Domain: testinglabs.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 3

  - Name: Processors
    Domain: processors.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 3

  - Name: Manufacturers
    Domain: manufacturers.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 3
EOF

# Generate crypto material
cryptogen generate --config="$NETWORK_DIR/crypto-config.yaml" --output="$NETWORK_DIR/organizations"

echo "Certificates generated successfully!"
