#!/bin/bash

# Create peercfg with core.yaml for Fabric peers

echo "Creating peer configuration..."

NETWORK_DIR="/mnt/d/Trial/HerbalTrace/network"
mkdir -p "$NETWORK_DIR/peercfg"

cat > "$NETWORK_DIR/peercfg/core.yaml" << 'EOF'
peer:
  id: peer
  networkId: herbaltrace
  listenAddress: 0.0.0.0:7051
  address: 0.0.0.0:7051
  addressAutoDetect: false
  
  fileSystemPath: /var/hyperledger/production
  
  mspConfigPath: /etc/hyperledger/fabric/msp
  localMspId: FarmersMSP
  
  tls:
    enabled: true
    cert:
      file: /etc/hyperledger/fabric/tls/server.crt
    key:
      file: /etc/hyperledger/fabric/tls/server.key
    rootcert:
      file: /etc/hyperledger/fabric/tls/ca.crt
  
  gossip:
    bootstrap: peer0.farmers.herbaltrace.com:7051
    useLeaderElection: true
    orgLeader: false
    endpoint:
    externalEndpoint: peer0.farmers.herbaltrace.com:7051
  
  events:
    address: 0.0.0.0:7053
    
  deliv:
    client:
      connTimeout: 5s
  
vm:
  endpoint: unix:///host/var/run/docker.sock
  
chaincode:
  startuptimeout: 300s
  executetimeout: 30s
  mode: net
  
ledger:
  state:
    stateDatabase: CouchDB
    couchDBConfig:
      couchDBAddress: couchdb:5984
      username: admin
      password: adminpw
      
operations:
  listenAddress: 0.0.0.0:9443
  tls:
    enabled: false
EOF

echo "✅ Peer configuration created at $NETWORK_DIR/peercfg/core.yaml"
