# HerbalTrace: Blockchain-Based Ayurvedic Herbal Supply Chain Traceability

## Overview

HerbalTrace is a comprehensive blockchain-based traceability system for Ayurvedic herbal supply chains, leveraging **Hyperledger Fabric** to ensure authenticity, sustainability, and transparency from farm to consumer.

### Key Features

- 🌿 **End-to-End Traceability**: GPS-tagged collection events to finished products
- 🔒 **Permissioned Blockchain**: 4-organization network (Farmers, Labs, Processors, Manufacturers)
- 📱 **Flutter Mobile App**: Offline-capable farmer app with GPS tagging and SMS sync
- 🌐 **Consumer Portal**: QR code scanning with interactive maps and provenance bundles
- 🧪 **Smart Contracts**: Automated geo-fencing, quality gates, and NMPB compliance
- 📊 **Analytics Dashboard**: Real-time supply chain monitoring and sustainability metrics
- 🔐 **FHIR-Style Resources**: Standardized metadata for interoperability

## Architecture

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  Flutter App    │──────│   REST API       │──────│  Web Portal     │
│  (Farmers)      │      │   (Node.js)      │      │  (React)        │
└─────────────────┘      └──────────────────┘      └─────────────────┘
         │                        │                         │
         └────────────────────────┼─────────────────────────┘
                                  │
                   ┌──────────────▼──────────────┐
                   │   Hyperledger Fabric        │
                   │   (4 Orgs, RAFT Orderer)    │
                   │   - Farmers Coop            │
                   │   - Testing Labs            │
                   │   - Processing Facilities   │
                   │   - Manufacturers           │
                   └─────────────────────────────┘
```

## Technology Stack

### Blockchain Layer
- **Hyperledger Fabric 2.5.x**: Permissioned blockchain network
- **Go 1.21+**: Chaincode (smart contracts)
- **CouchDB**: State database for rich queries
- **Fabric CA**: Certificate Authority for identity management

### Backend
- **Node.js 20.x + Express**: REST API server
- **Fabric SDK for Node.js**: Blockchain interaction
- **PostgreSQL**: Off-chain data (user profiles, metadata)
- **Redis**: Caching and session management
- **JWT**: Authentication and authorization

### Mobile App
- **Flutter 3.16+**: Cross-platform mobile framework
- **Dart**: Programming language
- **GPS/Location Services**: Geo-tagging
- **Offline Storage**: Hive/SQLite
- **Camera**: QR scanning and species photo capture

### Web Portal
- **React 18.x**: Frontend framework
- **TypeScript**: Type-safe development
- **Material-UI (MUI)**: Component library
- **Leaflet/Mapbox**: Interactive mapping
- **Chart.js**: Analytics visualization
- **QR Code Scanner**: Web-based scanning

### DevOps
- **Docker & Docker Compose**: Containerization
- **Kubernetes (optional)**: Production orchestration
- **GitHub Actions**: CI/CD pipeline
- **Prometheus + Grafana**: Monitoring
- **ELK Stack**: Logging

## Quick Start

### Prerequisites

- Ubuntu 20.04/22.04 LTS
- Docker 24.x+ and Docker Compose v2
- Node.js 20.x
- Go 1.21+
- Git
- 8GB+ RAM recommended

### One-Command Setup

```bash
cd HerbalTrace
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This will:
1. Install all prerequisites
2. Download Fabric binaries and Docker images
3. Generate network artifacts (crypto materials, genesis block)
4. Start the 4-org Fabric network
5. Deploy chaincode
6. Start API server
7. Seed sample data

### Manual Setup

#### 1. Environment Setup

```bash
# Install prerequisites
./scripts/install-prereqs.sh

# Set environment variables
source scripts/env.sh
```

#### 2. Start Fabric Network

```bash
cd network
./deploy-network.sh up

# Create channel
./deploy-network.sh createChannel

# Deploy chaincode
./deploy-network.sh deployChaincode
```

#### 3. Start Backend API

```bash
cd backend
npm install
npm run build
npm start
```

API will be available at: `http://localhost:3000`

#### 4. Start Web Portal

```bash
cd web-portal
npm install
npm start
```

Web portal will be available at: `http://localhost:3001`

#### 5. Build Flutter App

```bash
cd mobile-app
flutter pub get
flutter run
```

## Project Structure

```
HerbalTrace/
├── network/                    # Hyperledger Fabric network
│   ├── organizations/          # Crypto materials for orgs
│   ├── configtx/              # Channel configuration
│   ├── docker/                # Docker compose files
│   ├── scripts/               # Network deployment scripts
│   └── deploy-network.sh      # Main deployment script
│
├── chaincode/                 # Smart contracts
│   ├── herbaltrace/          # Main chaincode
│   │   ├── collection.go     # CollectionEvent contract
│   │   ├── quality.go        # QualityTest contract
│   │   ├── processing.go     # ProcessingStep contract
│   │   ├── provenance.go     # Provenance bundle
│   │   ├── geofencing.go     # Geo-validation logic
│   │   └── main.go           # Entry point
│   └── go.mod
│
├── backend/                   # REST API server
│   ├── src/
│   │   ├── controllers/      # API endpoints
│   │   ├── services/         # Business logic
│   │   ├── models/           # Data models
│   │   ├── middleware/       # Auth, validation
│   │   ├── fabric/           # Fabric SDK integration
│   │   └── utils/            # Helpers (QR, FHIR)
│   ├── config/               # Configuration files
│   ├── tests/                # API tests
│   └── package.json
│
├── mobile-app/               # Flutter farmer app
│   ├── lib/
│   │   ├── screens/         # UI screens
│   │   ├── widgets/         # Reusable components
│   │   ├── services/        # API client, GPS
│   │   ├── models/          # Data models
│   │   └── main.dart        # Entry point
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── web-portal/              # React web dashboard
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── pages/          # Page views
│   │   ├── services/       # API client
│   │   ├── contexts/       # State management
│   │   └── App.tsx         # Entry point
│   ├── public/
│   └── package.json
│
├── scripts/                 # Automation scripts
│   ├── setup.sh            # One-command setup
│   ├── install-prereqs.sh  # Prerequisites installer
│   ├── env.sh              # Environment variables
│   ├── seed-data.sh        # Sample data seeding
│   └── cleanup.sh          # Network teardown
│
├── monitoring/             # Prometheus & Grafana
│   ├── prometheus/
│   └── grafana/
│
├── docs/                   # Documentation
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── DEPLOYMENT.md
│   └── USER_GUIDE.md
│
└── docker-compose.yml      # Full stack orchestration
```

## Network Configuration

### Organizations

1. **FarmersCoop** (farmers.herbaltrace.com)
   - 2 peers, 1 CA
   - Role: Record collection events with GPS data

2. **TestingLabs** (labs.herbaltrace.com)
   - 2 peers, 1 CA
   - Role: Record quality test results

3. **ProcessingFacilities** (processors.herbaltrace.com)
   - 2 peers, 1 CA
   - Role: Record processing steps

4. **Manufacturers** (manufacturers.herbaltrace.com)
   - 2 peers, 1 CA
   - Role: Generate final product QR codes

### Orderer

- **Type**: RAFT (3-node cluster for production)
- **Consensus**: Crash fault-tolerant

### Channel

- **Name**: `herbaltrace-channel`
- **Anchor Peers**: 1 per organization

## Smart Contract Functions

### CollectionEvent

- `CreateCollectionEvent`: Record GPS-tagged harvest
- `GetCollectionEvent`: Retrieve event by ID
- `QueryCollectionsByFarmer`: Get farmer's collections
- `QueryCollectionsBySpecies`: Filter by herb species
- `ValidateGeoFencing`: Enforce approved zones

### QualityTest

- `CreateQualityTest`: Record lab test results
- `GetQualityTest`: Retrieve test by ID
- `ValidateQualityGates`: Auto-check thresholds

### ProcessingStep

- `CreateProcessingStep`: Record processing activity
- `GetProcessingStep`: Retrieve step by ID
- `QueryProcessingByBatch`: Track batch processing

### Provenance

- `GenerateProvenance`: Create FHIR bundle for product
- `GetProvenance`: Retrieve full supply chain history
- `GenerateQRCode`: Create unique product identifier

## API Endpoints

### Authentication
- `POST /api/auth/register`: Register new user
- `POST /api/auth/login`: Login (returns JWT)

### Collection Events
- `POST /api/collections`: Create collection event
- `GET /api/collections/:id`: Get event details
- `GET /api/collections`: Query with filters

### Quality Tests
- `POST /api/quality-tests`: Submit test results
- `GET /api/quality-tests/:id`: Get test details

### Processing
- `POST /api/processing`: Record processing step
- `GET /api/processing/:batchId`: Get batch processing

### Provenance
- `GET /api/provenance/:productId`: Get full history
- `GET /api/qr/:qrCode`: Consumer scanning endpoint

### Analytics
- `GET /api/analytics/dashboard`: Supply chain metrics
- `GET /api/analytics/sustainability`: Conservation data

## Consumer Portal Features

1. **QR Code Scanning**: Scan product QR codes via web camera
2. **Interactive Map**: Visualize farm locations and collection zones
3. **Provenance Timeline**: Step-by-step supply chain journey
4. **Lab Certificates**: View and download test reports
5. **Farmer Profiles**: Community stories and sustainability practices
6. **Recall Alerts**: Real-time notifications for affected batches

## Mobile App Features

1. **Offline Collection**: Record events without internet
2. **GPS Auto-Tagging**: Automatic location capture
3. **Species Photo Capture**: Camera integration
4. **SMS Sync**: Sync via SMS gateway in low-connectivity areas
5. **Multi-Language**: Support for regional languages
6. **Voice Input**: For low-literacy users

## Security & Compliance

- **Identity Management**: X.509 certificates via Fabric CA
- **Role-Based Access Control (RBAC)**: Chaincode-level permissions
- **Data Encryption**: TLS for all communications
- **Audit Trails**: Immutable blockchain records
- **GDPR Compliance**: Personal data handling
- **NMPB Guidelines**: Automated sustainability checks

## Testing

### Run All Tests

```bash
# Chaincode tests
cd chaincode/herbaltrace
go test -v ./...

# Backend API tests
cd backend
npm test

# Integration tests
./scripts/integration-test.sh
```

### Sample Data

```bash
# Seed test data
./scripts/seed-data.sh
```

## Monitoring

### Prometheus Metrics

Access at: `http://localhost:9090`

### Grafana Dashboards

Access at: `http://localhost:3002`
- Default credentials: admin/admin

### Fabric Operations Console

```bash
# Access network metrics
curl http://localhost:9443/metrics
```

## Troubleshooting

### Network Issues

```bash
# Check Docker containers
docker ps -a

# View logs
docker logs <container_name>

# Restart network
cd network
./deploy-network.sh down
./deploy-network.sh up
```

### Chaincode Issues

```bash
# Check chaincode container logs
docker logs <chaincode_container>

# Reinstall chaincode
./deploy-network.sh deployChaincode
```

### API Connection Issues

```bash
# Verify Fabric connection
cd backend
npm run test:connection
```

## Cleanup

```bash
# Stop all services
./scripts/cleanup.sh

# Remove all Docker volumes and networks
docker system prune -a --volumes
```

## Production Deployment

For production deployment on Kubernetes, see [DEPLOYMENT.md](docs/DEPLOYMENT.md)

### Production Checklist

- [ ] Use Fabric CA (not cryptogen)
- [ ] Configure RAFT orderer cluster (3+ nodes)
- [ ] Set up TLS certificates from trusted CA
- [ ] Configure persistent volumes for peer/orderer data
- [ ] Enable backup and disaster recovery
- [ ] Set up monitoring and alerting
- [ ] Configure load balancers
- [ ] Implement rate limiting
- [ ] Enable audit logging
- [ ] Security hardening (firewall, VPN)

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

This project is licensed under the Apache License 2.0 - see [LICENSE](LICENSE) file.

## Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/HerbalTrace/issues)
- **Email**: support@herbaltrace.com

## Acknowledgments

- National Medicinal Plants Board (NMPB)
- AYUSH Ministry
- Hyperledger Fabric Community
- Open-source contributors

---

**Built with ❤️ for sustainable Ayurvedic herbal supply chains**
