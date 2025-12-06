# HerbalTrace Deployment Guide

## Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04/22.04 LTS or macOS
- **RAM**: Minimum 8GB, Recommended 16GB
- **Disk**: 50GB free space
- **CPU**: 4+ cores recommended

### Required Software
- Docker Engine 20.10+
- Docker Compose 2.0+
- Go 1.21+
- Node.js 20.x LTS
- Flutter 3.16+
- Git

## Quick Start (Automated Setup)

The fastest way to get HerbalTrace running:

```bash
# Clone the repository
git clone <repository-url>
cd HerbalTrace

# Run one-command setup (installs all dependencies and starts network)
chmod +x scripts/setup.sh
./scripts/setup.sh

# This script will:
# 1. Install Docker, Go, Node.js, and Hyperledger Fabric binaries
# 2. Generate cryptographic material
# 3. Start the blockchain network (3 orderers, 8 peers)
# 4. Create the channel and deploy chaincode
# 5. Start CouchDB instances
```

**Expected output**: Network running with all services healthy in ~15-20 minutes.

## Manual Deployment

If you prefer step-by-step control:

### Step 1: Generate Certificates

```bash
cd network
./scripts/createCertificates.sh
```

This creates crypto material for:
- 3 orderer nodes (RAFT consensus)
- 8 peer nodes (2 per organization)
- Admin and user identities
- TLS certificates

### Step 2: Generate Genesis Block

```bash
./scripts/createGenesisBlock.sh
```

Creates:
- System channel genesis block
- Channel configuration transaction

### Step 3: Start Network

```bash
# Start Docker containers
docker-compose -f docker/docker-compose-herbaltrace.yaml up -d

# Verify all containers are running
docker ps

# Expected: 14 containers (3 orderers, 8 peers, 1 CLI, 2 CouchDB instances)
```

### Step 4: Create Channel

```bash
./scripts/createChannel.sh
```

Actions:
- Creates `herbaltrace` channel
- Joins all 8 peers to the channel
- Sets anchor peers for each organization

### Step 5: Deploy Chaincode

```bash
# Package chaincode
cd ../chaincode/herbaltrace
GO111MODULE=on go mod vendor
cd ../../network

# Install and approve chaincode on all peers
./scripts/deployChaincode.sh
```

### Step 6: Start Backend API

```bash
cd ../backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Start API server
npm run dev

# API available at http://localhost:3000
```

### Step 7: Build Mobile App

```bash
cd ../mobile-app

# Get Flutter dependencies
flutter pub get

# For Android
flutter build apk

# For iOS (requires macOS)
flutter build ios

# For development
flutter run
```

### Step 8: Start Web Portal

```bash
cd ../web-portal

# Install dependencies
npm install

# Start development server
npm start

# Portal available at http://localhost:3001
```

## Verification & Testing

### Check Network Health

```bash
# From network directory
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check orderer logs
docker logs orderer.herbaltrace.com

# Check peer logs
docker logs peer0.farmerscoop.herbaltrace.com
```

### Test Chaincode

```bash
# From network directory
docker exec cli peer chaincode query \
  -C herbaltrace \
  -n herbaltrace \
  -c '{"Args":["GetAllCollectionEvents"]}'
```

### Seed Sample Data

```bash
cd scripts
chmod +x seed-data.sh
./seed-data.sh
```

Creates sample collection events for testing.

### Test API Endpoints

```bash
# Health check
curl http://localhost:3000/health

# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "farmer001",
    "password": "secure123",
    "organization": "FarmersCoop",
    "role": "farmer"
  }'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "farmer001",
    "password": "secure123",
    "organization": "FarmersCoop"
  }'
```

## Monitoring Setup

```bash
cd scripts
chmod +x setup-monitoring.sh
./setup-monitoring.sh

# Start monitoring stack
cd ../monitoring
docker-compose -f docker-compose-monitoring.yaml up -d
```

Access:
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090

## Common Issues & Troubleshooting

### Issue: Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :7050

# Kill the process or change port in docker-compose
```

### Issue: Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Issue: Chaincode Installation Fails

```bash
# Clean up and retry
docker-compose down -v
rm -rf organizations channel-artifacts
./deploy-network.sh all
```

### Issue: CouchDB Connection Failed

```bash
# Check CouchDB logs
docker logs couchdb0

# Restart CouchDB
docker restart couchdb0
```

## Network Topology

```
HerbalTrace Network
├── Orderers (RAFT Consensus)
│   ├── orderer.herbaltrace.com:7050
│   ├── orderer2.herbaltrace.com:8050
│   └── orderer3.herbaltrace.com:9050
├── FarmersCoopMSP
│   ├── peer0.farmerscoop.herbaltrace.com:7051
│   └── peer1.farmerscoop.herbaltrace.com:8051
├── TestingLabsMSP
│   ├── peer0.testinglabs.herbaltrace.com:9051
│   └── peer1.testinglabs.herbaltrace.com:10051
├── ProcessorsMSP
│   ├── peer0.processors.herbaltrace.com:11051
│   └── peer1.processors.herbaltrace.com:12051
└── ManufacturersMSP
    ├── peer0.manufacturers.herbaltrace.com:13051
    └── peer1.manufacturers.herbaltrace.com:14051
```

## Production Considerations

### Security Hardening
1. **Change default passwords** in .env files
2. **Enable TLS** for all client connections
3. **Use Fabric CA** instead of cryptogen for production certificates
4. **Implement rate limiting** on API endpoints
5. **Set up firewall rules** to restrict access

### Scalability
1. **Add more peers** to distribute load
2. **Use external CouchDB cluster** for better performance
3. **Deploy behind load balancer** (NGINX/HAProxy)
4. **Enable caching** with Redis for frequent queries

### High Availability
1. **Run orderers in different availability zones**
2. **Set up database replication** for CouchDB
3. **Use container orchestration** (Kubernetes) for auto-healing
4. **Implement backup strategy** for ledger data

### Monitoring
1. **Set up log aggregation** (ELK stack)
2. **Configure alerting** in Grafana
3. **Monitor blockchain metrics** (block time, transaction throughput)
4. **Track application metrics** (API response times, error rates)

## Backup & Recovery

### Backup Ledger Data

```bash
# Backup peer data
docker exec peer0.farmerscoop.herbaltrace.com tar czf - /var/hyperledger/production > backup-peer0.tar.gz

# Backup CouchDB
docker exec couchdb0 couchdb-backup -H http://localhost:5984 -d herbaltrace -f backup.json
```

### Restore from Backup

```bash
# Stop network
docker-compose down

# Restore peer data
docker run --rm -v peer0.farmerscoop.herbaltrace.com:/restore alpine tar xzf - < backup-peer0.tar.gz

# Start network
docker-compose up -d
```

## Updating Chaincode

```bash
# Update version in chaincode
# Repackage and install
./scripts/deployChaincode.sh upgrade

# Or manually:
peer lifecycle chaincode install herbaltrace-v2.tar.gz
peer lifecycle chaincode approveformyorg --version 2.0 ...
peer lifecycle chaincode commit --version 2.0 ...
```

## Decommissioning

```bash
# Stop all services
cd network
docker-compose down -v

# Remove all data
rm -rf organizations channel-artifacts

# Stop monitoring
cd ../monitoring
docker-compose down -v

# Clean Docker resources
docker system prune -a --volumes
```

## Support & Resources

- **Documentation**: See README.md for architecture details
- **Issues**: Check logs in `network/logs/` directory
- **Hyperledger Fabric Docs**: https://hyperledger-fabric.readthedocs.io/
- **Community**: Hyperledger Discord/Rocket.Chat

## Next Steps

1. **Customize chaincode** for your specific supply chain requirements
2. **Integrate IoT devices** for automated data collection
3. **Add more organizations** to the network
4. **Implement advanced features** (private data collections, events)
5. **Deploy to cloud** (AWS, Azure, GCP) using Kubernetes

---

**Need Help?** Review the logs in each component's directory or check the Troubleshooting section.
