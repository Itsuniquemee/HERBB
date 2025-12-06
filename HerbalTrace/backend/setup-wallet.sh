#!/bin/bash

# Setup Wallet for HerbalTrace Backend
# This script creates wallet identities from the crypto materials

WALLET_PATH="../network/wallet"
ORG_PATH="../network/organizations/peerOrganizations"

echo "Setting up HerbalTrace Fabric wallet..."

# Create wallet directory
mkdir -p "$WALLET_PATH"

# Organizations to setup
declare -A ORGS
ORGS[FarmersCoop]="farmers.herbaltrace.com"
ORGS[TestingLabs]="labs.herbaltrace.com"
ORGS[Processors]="processors.herbaltrace.com"
ORGS[Manufacturers]="manufacturers.herbaltrace.com"

# Function to create identity JSON
create_identity() {
    local org=$1
    local domain=$2
    local user_dir="$ORG_PATH/$domain/users/Admin@$domain"
    
    if [ ! -d "$user_dir" ]; then
        echo "Warning: Admin directory not found for $org ($domain)"
        return 1
    fi
    
    # Find certificate and private key
    local cert_path="$user_dir/msp/signcerts/Admin@${domain}-cert.pem"
    local key_dir="$user_dir/msp/keystore"
    
    # Find the first private key in keystore
    local key_path=$(find "$key_dir" -name "*_sk" | head -n 1)
    
    if [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
        echo "Warning: Certificate or key not found for $org"
        return 1
    fi
    
    # Read certificate and key
    local cert=$(cat "$cert_path")
    local key=$(cat "$key_path")
    
    # Create identity JSON for admin
    local identity_file="$WALLET_PATH/admin-${org}.id"
    
    cat > "$identity_file" <<EOF
{
  "credentials": {
    "certificate": $(echo "$cert" | jq -Rs .),
    "privateKey": $(echo "$key" | jq -Rs .)
  },
  "mspId": "${org}MSP",
  "type": "X.509"
}
EOF
    
    echo "✓ Created identity for admin-${org}"
}

# Create identities for each organization
for org in "${!ORGS[@]}"; do
    domain="${ORGS[$org]}"
    create_identity "$org" "$domain"
done

echo ""
echo "Wallet setup complete at: $WALLET_PATH"
echo "Admin identities created for all organizations"
echo ""
echo "You can now start the backend server with: npm start or npm run dev"
