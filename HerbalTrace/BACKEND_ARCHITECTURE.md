# 🏗️ HerbalTrace Backend Architecture & Implementation Guide

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Implementation Phases](#implementation-phases)
5. [API Design](#api-design)
6. [Security & Authentication](#security--authentication)
7. [Integration with Blockchain](#integration-with-blockchain)
8. [Database Design](#database-design)
9. [File Storage](#file-storage)
10. [External Services](#external-services)
11. [Testing Strategy](#testing-strategy)
12. [Deployment](#deployment)

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  Mobile App (Flutter)  │  Web Portal (React)  │  Admin Dashboard │
└────────────┬────────────┴──────────┬───────────┴─────────────────┘
             │                       │
             │    REST API / GraphQL │
             │                       │
┌────────────▼───────────────────────▼──────────────────────────────┐
│                     API GATEWAY LAYER                             │
│  - Authentication (JWT)                                           │
│  - Rate Limiting                                                  │
│  - Request Validation                                             │
│  - API Documentation (Swagger)                                    │
└────────────┬──────────────────────────────────────────────────────┘
             │
┌────────────▼──────────────────────────────────────────────────────┐
│                   BACKEND SERVICE LAYER                           │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  Auth Service   │  │  User Service   │  │  Notification   │  │
│  │  - Login/Signup │  │  - Profile Mgmt │  │  - Push/SMS     │  │
│  │  - Role-based   │  │  - KYC/Verify   │  │  - Email Alerts │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Collection Svc  │  │   Batch Service │  │  Quality Service│  │
│  │ - Harvest Track │  │  - Grouping     │  │  - Lab Tests    │  │
│  │ - GPS Capture   │  │  - Assignment   │  │  - Certificates │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Processing Svc  │  │  Product Service│  │  Provenance Svc │  │
│  │ - Manufacturing │  │  - QR Generator │  │  - Traceability │  │
│  │ - Tracking      │  │  - Inventory    │  │  - Consumer View│  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  Alert Service  │  │ Analytics Svc   │  │  Blockchain Svc │  │
│  │ - Violations    │  │  - Reports      │  │  - Fabric SDK   │  │
│  │ - Thresholds    │  │  - Dashboards   │  │  - Transaction  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                                                                   │
└────────────┬──────────────────────────────────────────────────────┘
             │
┌────────────▼──────────────────────────────────────────────────────┐
│                   DATA PERSISTENCE LAYER                          │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │  PostgreSQL      │  │  Redis Cache     │  │  IPFS/S3       │ │
│  │  - User data     │  │  - Sessions      │  │  - Images      │ │
│  │  - Off-chain     │  │  - API cache     │  │  - Documents   │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
│                                                                   │
└────────────┬──────────────────────────────────────────────────────┘
             │
┌────────────▼──────────────────────────────────────────────────────┐
│                   BLOCKCHAIN LAYER                                │
├───────────────────────────────────────────────────────────────────┤
│  Hyperledger Fabric Network (Already Deployed ✅)                 │
│  - 3 Orderers (Raft Consensus)                                    │
│  - 8 Peers (4 Organizations)                                      │
│  - Chaincode v2.1 (38 Functions)                                  │
│  - CouchDB State Database (7 Indexes)                             │
└───────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│                   EXTERNAL SERVICES                                │
├────────────────────────────────────────────────────────────────────┤
│  Weather API │ SMS Gateway │ Email Service │ Payment Gateway      │
└────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Core Framework
```json
{
  "runtime": "Node.js 20.x LTS",
  "framework": "NestJS 10.x",
  "language": "TypeScript 5.x",
  "packageManager": "npm / pnpm"
}
```

**Why NestJS?**
- ✅ Built-in dependency injection
- ✅ Modular architecture (perfect for microservices)
- ✅ TypeScript first-class support
- ✅ Extensive middleware & guards
- ✅ Built-in validation (class-validator)
- ✅ Swagger integration
- ✅ WebSocket support
- ✅ Excellent testing tools

### Database & Cache
```yaml
Primary Database: PostgreSQL 15.x
  - User accounts, profiles, KYC data
  - Off-chain data (images URLs, cached blockchain data)
  - Analytics, reporting data
  - Session storage

Cache: Redis 7.x
  - Session management
  - API response caching
  - Rate limiting
  - Real-time data

Search: Elasticsearch (Optional)
  - Full-text search
  - Log aggregation
  - Analytics queries
```

### Blockchain Integration
```yaml
Hyperledger Fabric SDK: fabric-network 2.5.x
Connection Management:
  - Gateway pattern
  - Connection pooling
  - Wallet management
  - Identity management
```

### File Storage
```yaml
Primary: AWS S3 / MinIO
  - Product images
  - Quality certificates (PDFs)
  - Farmer documents
  - Lab reports

Alternative: IPFS (Decentralized)
  - Immutable document storage
  - Content-addressable storage
  - Integration with blockchain
```

### Authentication & Security
```yaml
Auth: JWT (JSON Web Tokens)
Encryption: bcrypt for passwords
API Security:
  - Helmet.js (HTTP headers)
  - CORS configuration
  - Rate limiting (express-rate-limit)
  - Input validation (class-validator)
  - SQL injection prevention (TypeORM)
```

### External APIs
```yaml
Weather: OpenWeatherMap API
SMS: Twilio / AWS SNS
Email: SendGrid / AWS SES
Push Notifications: Firebase Cloud Messaging
Maps: Google Maps API (geocoding)
Payment: Razorpay / Stripe (future)
```

### DevOps & Monitoring
```yaml
Containerization: Docker
Orchestration: Docker Compose / Kubernetes
Logging: Winston + ELK Stack
Monitoring: Prometheus + Grafana
API Docs: Swagger/OpenAPI 3.0
Testing: Jest + Supertest
CI/CD: GitHub Actions
```

---

## 📁 Project Structure

```
backend/
├── src/
│   ├── main.ts                          # Application entry point
│   ├── app.module.ts                    # Root module
│   │
│   ├── config/                          # Configuration files
│   │   ├── database.config.ts
│   │   ├── blockchain.config.ts
│   │   ├── jwt.config.ts
│   │   ├── redis.config.ts
│   │   └── storage.config.ts
│   │
│   ├── common/                          # Shared utilities
│   │   ├── decorators/
│   │   │   ├── roles.decorator.ts       # @Roles('farmer', 'lab')
│   │   │   ├── current-user.decorator.ts
│   │   │   └── api-response.decorator.ts
│   │   ├── guards/
│   │   │   ├── auth.guard.ts
│   │   │   ├── roles.guard.ts
│   │   │   └── throttle.guard.ts
│   │   ├── interceptors/
│   │   │   ├── logging.interceptor.ts
│   │   │   ├── cache.interceptor.ts
│   │   │   └── transform.interceptor.ts
│   │   ├── filters/
│   │   │   ├── http-exception.filter.ts
│   │   │   └── fabric-exception.filter.ts
│   │   ├── pipes/
│   │   │   └── validation.pipe.ts
│   │   ├── constants/
│   │   │   ├── roles.enum.ts
│   │   │   ├── status.enum.ts
│   │   │   └── error-codes.ts
│   │   └── utils/
│   │       ├── id-generator.util.ts
│   │       ├── date-formatter.util.ts
│   │       └── coordinate-validator.util.ts
│   │
│   ├── blockchain/                      # Fabric SDK integration
│   │   ├── blockchain.module.ts
│   │   ├── blockchain.service.ts        # Gateway, wallet, connection
│   │   ├── transaction.service.ts       # Submit/evaluate transactions
│   │   ├── wallet.service.ts            # Identity management
│   │   ├── connection-profile.service.ts
│   │   └── dto/
│   │       ├── transaction-result.dto.ts
│   │       └── fabric-error.dto.ts
│   │
│   ├── auth/                            # Authentication module
│   │   ├── auth.module.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── strategies/
│   │   │   ├── jwt.strategy.ts
│   │   │   └── local.strategy.ts
│   │   └── dto/
│   │       ├── login.dto.ts
│   │       ├── register.dto.ts
│   │       └── token-response.dto.ts
│   │
│   ├── users/                           # User management
│   │   ├── users.module.ts
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── entities/
│   │   │   └── user.entity.ts
│   │   └── dto/
│   │       ├── create-user.dto.ts
│   │       ├── update-profile.dto.ts
│   │       └── user-response.dto.ts
│   │
│   ├── farmers/                         # Farmer-specific operations
│   │   ├── farmers.module.ts
│   │   ├── farmers.controller.ts
│   │   ├── farmers.service.ts
│   │   └── dto/
│   │       ├── farmer-profile.dto.ts
│   │       └── farmer-stats.dto.ts
│   │
│   ├── collection-events/               # Harvest tracking
│   │   ├── collection-events.module.ts
│   │   ├── collection-events.controller.ts
│   │   ├── collection-events.service.ts
│   │   ├── entities/
│   │   │   └── collection-event.entity.ts  # Off-chain cache
│   │   └── dto/
│   │       ├── create-collection-event.dto.ts
│   │       ├── collection-event-response.dto.ts
│   │       └── harvest-location.dto.ts
│   │
│   ├── batches/                         # Batch management
│   │   ├── batches.module.ts
│   │   ├── batches.controller.ts
│   │   ├── batches.service.ts
│   │   ├── entities/
│   │   │   └── batch.entity.ts
│   │   └── dto/
│   │       ├── create-batch.dto.ts
│   │       ├── assign-processor.dto.ts
│   │       └── batch-status.dto.ts
│   │
│   ├── quality-tests/                   # Lab testing
│   │   ├── quality-tests.module.ts
│   │   ├── quality-tests.controller.ts
│   │   ├── quality-tests.service.ts
│   │   ├── entities/
│   │   │   └── quality-test.entity.ts
│   │   └── dto/
│   │       ├── create-quality-test.dto.ts
│   │       ├── test-results.dto.ts
│   │       └── certificate-upload.dto.ts
│   │
│   ├── processing/                      # Manufacturing steps
│   │   ├── processing.module.ts
│   │   ├── processing.controller.ts
│   │   ├── processing.service.ts
│   │   └── dto/
│   │       ├── create-processing-step.dto.ts
│   │       └── processing-params.dto.ts
│   │
│   ├── products/                        # Final products
│   │   ├── products.module.ts
│   │   ├── products.controller.ts
│   │   ├── products.service.ts
│   │   ├── qr-generator.service.ts      # QR code generation
│   │   └── dto/
│   │       ├── create-product.dto.ts
│   │       ├── product-response.dto.ts
│   │       └── qr-code.dto.ts
│   │
│   ├── provenance/                      # Consumer traceability
│   │   ├── provenance.module.ts
│   │   ├── provenance.controller.ts
│   │   ├── provenance.service.ts
│   │   └── dto/
│   │       ├── provenance-bundle.dto.ts
│   │       └── qr-scan.dto.ts
│   │
│   ├── season-windows/                  # Season management
│   │   ├── season-windows.module.ts
│   │   ├── season-windows.controller.ts
│   │   ├── season-windows.service.ts
│   │   └── dto/
│   │       ├── create-season-window.dto.ts
│   │       └── season-validation.dto.ts
│   │
│   ├── harvest-limits/                  # Quota management
│   │   ├── harvest-limits.module.ts
│   │   ├── harvest-limits.controller.ts
│   │   ├── harvest-limits.service.ts
│   │   └── dto/
│   │       ├── create-harvest-limit.dto.ts
│   │       └── harvest-statistics.dto.ts
│   │
│   ├── alerts/                          # Alert system
│   │   ├── alerts.module.ts
│   │   ├── alerts.controller.ts
│   │   ├── alerts.service.ts
│   │   └── dto/
│   │       ├── create-alert.dto.ts
│   │       ├── acknowledge-alert.dto.ts
│   │       └── alert-statistics.dto.ts
│   │
│   ├── notifications/                   # Push/SMS/Email
│   │   ├── notifications.module.ts
│   │   ├── notifications.service.ts
│   │   ├── email.service.ts
│   │   ├── sms.service.ts
│   │   └── push.service.ts
│   │
│   ├── analytics/                       # Reports & dashboards
│   │   ├── analytics.module.ts
│   │   ├── analytics.controller.ts
│   │   ├── analytics.service.ts
│   │   └── dto/
│   │       ├── dashboard-stats.dto.ts
│   │       └── report-query.dto.ts
│   │
│   ├── storage/                         # File uploads
│   │   ├── storage.module.ts
│   │   ├── storage.service.ts
│   │   ├── s3.service.ts
│   │   └── ipfs.service.ts
│   │
│   ├── weather/                         # Weather integration
│   │   ├── weather.module.ts
│   │   └── weather.service.ts
│   │
│   └── health/                          # Health checks
│       ├── health.module.ts
│       ├── health.controller.ts
│       └── health.service.ts
│
├── test/                                # E2E tests
│   ├── app.e2e-spec.ts
│   └── ...
│
├── .env.example                         # Environment variables template
├── .env                                 # Environment variables (gitignored)
├── docker-compose.yml                   # Local development
├── Dockerfile                           # Production container
├── nest-cli.json                        # NestJS configuration
├── package.json
├── tsconfig.json
└── README.md
```

---

## 🚀 Implementation Phases

### **Phase 1: Foundation Setup (Week 1)**

#### 1.1 Project Initialization
```bash
# Create NestJS project
npm i -g @nestjs/cli
nest new herbaltrace-backend

# Install core dependencies
npm install --save \
  @nestjs/config \
  @nestjs/typeorm \
  typeorm \
  pg \
  @nestjs/jwt \
  @nestjs/passport \
  passport \
  passport-jwt \
  passport-local \
  bcrypt \
  class-validator \
  class-transformer \
  @nestjs/swagger \
  swagger-ui-express

# Install Fabric SDK
npm install --save fabric-network fabric-ca-client

# Install additional utilities
npm install --save \
  redis \
  @nestjs/cache-manager \
  cache-manager \
  cache-manager-redis-store \
  axios \
  qrcode \
  uuid \
  winston \
  helmet \
  compression
```

#### 1.2 Environment Configuration
```typescript
// .env
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=herbaltrace
DB_PASSWORD=secure_password
DB_NAME=herbaltrace_db

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your_super_secure_secret_key
JWT_EXPIRATION=24h
JWT_REFRESH_EXPIRATION=7d

# Blockchain
FABRIC_NETWORK_PATH=/path/to/network
FABRIC_CHANNEL_NAME=herbaltrace-channel
FABRIC_CHAINCODE_NAME=herbaltrace
FABRIC_WALLET_PATH=/path/to/wallet

# AWS S3 / MinIO
STORAGE_TYPE=s3
S3_BUCKET=herbaltrace-storage
S3_REGION=us-east-1
S3_ACCESS_KEY=your_access_key
S3_SECRET_KEY=your_secret_key

# External APIs
WEATHER_API_KEY=your_openweathermap_key
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
SENDGRID_API_KEY=your_sendgrid_key
```

#### 1.3 Database Setup
```sql
-- Create database
CREATE DATABASE herbaltrace_db;

-- User roles enum
CREATE TYPE user_role AS ENUM (
  'farmer', 
  'testing_lab', 
  'processor', 
  'manufacturer', 
  'consumer', 
  'admin'
);

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role user_role NOT NULL,
  org_name VARCHAR(255),
  org_id VARCHAR(100),
  full_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP
);

-- Farmer profiles
CREATE TABLE farmer_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  farm_name VARCHAR(255),
  farm_location VARCHAR(255),
  farm_latitude DECIMAL(10, 8),
  farm_longitude DECIMAL(11, 8),
  farm_size DECIMAL(10, 2),
  farm_size_unit VARCHAR(20),
  certifications TEXT[],
  specialization TEXT[],
  kyc_document_url TEXT,
  kyc_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Collection events cache (off-chain)
CREATE TABLE collection_events_cache (
  id VARCHAR(100) PRIMARY KEY,
  blockchain_tx_id VARCHAR(255),
  farmer_id UUID REFERENCES users(id),
  species VARCHAR(255),
  quantity DECIMAL(10, 2),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  harvest_date TIMESTAMP,
  status VARCHAR(50),
  image_urls TEXT[],
  weather_data JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  synced_to_blockchain BOOLEAN DEFAULT FALSE
);

-- Batches cache
CREATE TABLE batches_cache (
  id VARCHAR(100) PRIMARY KEY,
  blockchain_tx_id VARCHAR(255),
  species VARCHAR(255),
  total_quantity DECIMAL(10, 2),
  status VARCHAR(50),
  assigned_processor_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quality tests cache
CREATE TABLE quality_tests_cache (
  id VARCHAR(100) PRIMARY KEY,
  blockchain_tx_id VARCHAR(255),
  batch_id VARCHAR(100),
  lab_id UUID REFERENCES users(id),
  test_date TIMESTAMP,
  overall_result VARCHAR(50),
  certificate_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_collection_farmer ON collection_events_cache(farmer_id);
CREATE INDEX idx_batches_status ON batches_cache(status);
CREATE INDEX idx_batches_processor ON batches_cache(assigned_processor_id);
```

---

### **Phase 2: Core Modules (Week 2-3)**

#### 2.1 Blockchain Service Implementation
```typescript
// src/blockchain/blockchain.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { Gateway, Network, Contract } from 'fabric-network';
import { WalletService } from './wallet.service';

@Injectable()
export class BlockchainService {
  private readonly logger = new Logger(BlockchainService.name);
  private gateway: Gateway;
  private network: Network;
  private contract: Contract;

  constructor(private walletService: WalletService) {}

  async connect(userId: string, orgName: string): Promise<void> {
    const wallet = await this.walletService.getWallet();
    const identity = await wallet.get(userId);
    
    if (!identity) {
      throw new Error(`Identity not found: ${userId}`);
    }

    this.gateway = new Gateway();
    
    const connectionProfile = await this.getConnectionProfile(orgName);
    
    await this.gateway.connect(connectionProfile, {
      wallet,
      identity: userId,
      discovery: { enabled: true, asLocalhost: false }
    });

    this.network = await this.gateway.getNetwork('herbaltrace-channel');
    this.contract = this.network.getContract('herbaltrace');
    
    this.logger.log(`Connected to blockchain as ${userId}`);
  }

  async submitTransaction(
    functionName: string, 
    ...args: string[]
  ): Promise<any> {
    try {
      this.logger.debug(`Submitting: ${functionName}(${args.join(', ')})`);
      
      const result = await this.contract.submitTransaction(
        functionName, 
        ...args
      );
      
      return JSON.parse(result.toString());
    } catch (error) {
      this.logger.error(`Transaction failed: ${error.message}`);
      throw error;
    }
  }

  async evaluateTransaction(
    functionName: string, 
    ...args: string[]
  ): Promise<any> {
    try {
      const result = await this.contract.evaluateTransaction(
        functionName, 
        ...args
      );
      
      return JSON.parse(result.toString());
    } catch (error) {
      this.logger.error(`Query failed: ${error.message}`);
      throw error;
    }
  }

  async disconnect(): Promise<void> {
    if (this.gateway) {
      this.gateway.disconnect();
      this.logger.log('Disconnected from blockchain');
    }
  }

  private async getConnectionProfile(orgName: string) {
    // Load connection profile from filesystem
    // network/organizations/peerOrganizations/farmers.herbaltrace.com/connection-farmers.json
    const fs = require('fs');
    const path = require('path');
    
    const profilePath = path.join(
      process.env.FABRIC_NETWORK_PATH,
      'organizations',
      'peerOrganizations',
      `${orgName}.herbaltrace.com`,
      `connection-${orgName}.json`
    );
    
    return JSON.parse(fs.readFileSync(profilePath, 'utf8'));
  }
}
```

#### 2.2 Authentication Module
```typescript
// src/auth/auth.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.usersService.findByEmail(email);
    
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const { passwordHash, ...result } = user;
    return result;
  }

  async login(user: any) {
    const payload = { 
      email: user.email, 
      sub: user.id, 
      role: user.role,
      orgId: user.orgId 
    };
    
    return {
      accessToken: this.jwtService.sign(payload),
      refreshToken: this.jwtService.sign(payload, { expiresIn: '7d' }),
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        orgName: user.orgName,
        fullName: user.fullName
      }
    };
  }

  async register(registerDto: RegisterDto) {
    const hashedPassword = await bcrypt.hash(registerDto.password, 10);
    
    const user = await this.usersService.create({
      ...registerDto,
      passwordHash: hashedPassword
    });

    // Register identity in Fabric wallet
    await this.registerFabricIdentity(user);

    return this.login(user);
  }

  private async registerFabricIdentity(user: any) {
    // Register user with Fabric CA
    // Create wallet identity
    // Store credentials
  }
}
```

#### 2.3 Collection Events Service
```typescript
// src/collection-events/collection-events.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BlockchainService } from '../blockchain/blockchain.service';
import { WeatherService } from '../weather/weather.service';
import { StorageService } from '../storage/storage.service';
import { CreateCollectionEventDto } from './dto/create-collection-event.dto';
import { CollectionEventCache } from './entities/collection-event.entity';

@Injectable()
export class CollectionEventsService {
  private readonly logger = new Logger(CollectionEventsService.name);

  constructor(
    @InjectRepository(CollectionEventCache)
    private collectionRepo: Repository<CollectionEventCache>,
    private blockchainService: BlockchainService,
    private weatherService: WeatherService,
    private storageService: StorageService,
  ) {}

  async create(
    farmerId: string, 
    dto: CreateCollectionEventDto,
    images: Express.Multer.File[]
  ) {
    // Step 1: Upload images to S3/IPFS
    const imageUrls = await Promise.all(
      images.map(img => this.storageService.uploadImage(img))
    );

    // Step 2: Fetch weather data
    const weatherData = await this.weatherService.getWeatherData(
      dto.latitude,
      dto.longitude,
      new Date(dto.harvestDate)
    );

    // Step 3: Generate unique ID
    const eventId = this.generateCollectionEventId(farmerId);

    // Step 4: Prepare blockchain payload
    const blockchainPayload = {
      id: eventId,
      type: 'CollectionEvent',
      farmerId: farmerId,
      farmerName: dto.farmerName,
      species: dto.species,
      commonName: dto.commonName,
      scientificName: dto.scientificName,
      quantity: dto.quantity,
      unit: dto.unit,
      latitude: dto.latitude,
      longitude: dto.longitude,
      altitude: dto.altitude,
      accuracy: dto.accuracy,
      harvestDate: new Date(dto.harvestDate).toISOString(),
      timestamp: new Date().toISOString(),
      harvestMethod: dto.harvestMethod,
      partCollected: dto.partCollected,
      weatherConditions: weatherData.description,
      temperature: weatherData.temperature,
      humidity: weatherData.humidity,
      soilType: dto.soilType,
      approvedZone: dto.approvedZone,
      zoneName: dto.zoneName,
      conservationStatus: dto.conservationStatus,
      certificationIds: dto.certificationIds || [],
      imageUrls: imageUrls,
      status: 'pending'
    };

    // Step 5: Submit to blockchain
    try {
      const txResult = await this.blockchainService.submitTransaction(
        'CreateCollectionEvent',
        JSON.stringify(blockchainPayload)
      );

      // Step 6: Cache in PostgreSQL
      const cacheEntry = this.collectionRepo.create({
        id: eventId,
        blockchainTxId: txResult.txId,
        farmerId: farmerId,
        species: dto.species,
        quantity: dto.quantity,
        latitude: dto.latitude,
        longitude: dto.longitude,
        harvestDate: new Date(dto.harvestDate),
        status: 'pending',
        imageUrls: imageUrls,
        weatherData: weatherData,
        syncedToBlockchain: true
      });

      await this.collectionRepo.save(cacheEntry);

      this.logger.log(`Collection event created: ${eventId}`);

      return {
        success: true,
        collectionEventId: eventId,
        transactionId: txResult.txId,
        imageUrls: imageUrls,
        weatherData: weatherData
      };
      
    } catch (error) {
      this.logger.error(`Blockchain submission failed: ${error.message}`);
      
      // Fallback: Save to database for retry
      const cacheEntry = this.collectionRepo.create({
        id: eventId,
        farmerId: farmerId,
        species: dto.species,
        quantity: dto.quantity,
        latitude: dto.latitude,
        longitude: dto.longitude,
        harvestDate: new Date(dto.harvestDate),
        status: 'pending_sync',
        imageUrls: imageUrls,
        weatherData: weatherData,
        syncedToBlockchain: false
      });

      await this.collectionRepo.save(cacheEntry);

      throw error;
    }
  }

  async findByFarmer(farmerId: string) {
    // Query from blockchain
    const blockchainEvents = await this.blockchainService.evaluateTransaction(
      'QueryCollectionsByFarmer',
      farmerId
    );

    return blockchainEvents;
  }

  async findById(eventId: string) {
    return await this.blockchainService.evaluateTransaction(
      'GetCollectionEvent',
      eventId
    );
  }

  private generateCollectionEventId(farmerId: string): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `CE-${farmerId}-${timestamp}-${random}`;
  }
}
```

---

### **Phase 3: Business Logic Modules (Week 4-5)**

#### 3.1 Batch Service
```typescript
// src/batches/batches.service.ts
@Injectable()
export class BatchesService {
  async createBatch(dto: CreateBatchDto) {
    const batchId = this.generateBatchId();
    
    const payload = {
      id: batchId,
      type: 'Batch',
      collectionEventIds: dto.collectionEventIds,
      farmerId: dto.farmerId,
      species: dto.species,
      totalQuantity: dto.totalQuantity,
      unit: dto.unit,
      status: 'collected',
      createdDate: new Date().toISOString()
    };

    await this.blockchainService.submitTransaction(
      'CreateBatch',
      JSON.stringify(payload)
    );

    return { success: true, batchId };
  }

  async assignToProcessor(batchId: string, processorId: string) {
    await this.blockchainService.submitTransaction(
      'AssignBatchToProcessor',
      batchId,
      processorId
    );

    // Send notification to processor
    await this.notificationService.notifyProcessor(processorId, batchId);

    return { success: true };
  }

  async updateStatus(batchId: string, status: string) {
    await this.blockchainService.submitTransaction(
      'UpdateBatchStatus',
      batchId,
      status
    );

    return { success: true };
  }

  async findByStatus(status: string) {
    return await this.blockchainService.evaluateTransaction(
      'QueryBatchesByStatus',
      status
    );
  }
}
```

#### 3.2 Quality Test Service
```typescript
// src/quality-tests/quality-tests.service.ts
@Injectable()
export class QualityTestsService {
  async createQualityTest(
    dto: CreateQualityTestDto,
    certificate: Express.Multer.File
  ) {
    // Upload certificate to S3
    const certificateUrl = await this.storageService.uploadPDF(certificate);

    const testId = this.generateTestId();
    
    const payload = {
      id: testId,
      type: 'QualityTest',
      batchId: dto.batchId,
      collectionEventId: dto.collectionEventId,
      labId: dto.labId,
      labName: dto.labName,
      testDate: new Date(dto.testDate).toISOString(),
      activeCompound: dto.activeCompound,
      activeCompoundPercent: dto.activeCompoundPercent,
      moistureContent: dto.moistureContent,
      heavyMetals: dto.heavyMetals,
      pesticides: dto.pesticides,
      dnaBarcodeMatch: dto.dnaBarcodeMatch,
      overallResult: dto.overallResult,
      certificateId: dto.certificateId,
      certificateUrl: certificateUrl,
      testerName: dto.testerName,
      status: 'approved'
    };

    await this.blockchainService.submitTransaction(
      'CreateQualityTest',
      JSON.stringify(payload)
    );

    // Auto-update batch status
    await this.batchesService.updateStatus(dto.batchId, 'testing_complete');

    return { success: true, testId, certificateUrl };
  }
}
```

#### 3.3 Product Service with QR Generation
```typescript
// src/products/products.service.ts
import * as QRCode from 'qrcode';

@Injectable()
export class ProductsService {
  async createProduct(dto: CreateProductDto) {
    const productId = this.generateProductId();
    const qrCode = this.generateQRCode(productId);

    // Generate QR code image
    const qrCodeDataUrl = await QRCode.toDataURL(qrCode, {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    const payload = {
      id: productId,
      type: 'Product',
      name: dto.name,
      batchId: dto.batchId,
      manufacturerId: dto.manufacturerId,
      manufacturerName: dto.manufacturerName,
      collectionEventIds: dto.collectionEventIds,
      qualityTestIds: dto.qualityTestIds,
      processingStepIds: dto.processingStepIds,
      quantity: dto.quantity,
      unit: dto.unit,
      qrCode: qrCode,
      manufacturingDate: new Date(dto.manufacturingDate).toISOString(),
      expiryDate: new Date(dto.expiryDate).toISOString(),
      certificationIds: dto.certificationIds,
      sustainabilityScore: dto.sustainabilityScore
    };

    await this.blockchainService.submitTransaction(
      'CreateProduct',
      JSON.stringify(payload)
    );

    return { 
      success: true, 
      productId, 
      qrCode,
      qrCodeImage: qrCodeDataUrl 
    };
  }

  private generateQRCode(productId: string): string {
    return `HERBAL-${productId}-${Date.now()}`;
  }
}
```

#### 3.4 Provenance Service (Consumer QR Scan)
```typescript
// src/provenance/provenance.service.ts
@Injectable()
export class ProvenanceService {
  async getProvenanceByQRCode(qrCode: string) {
    // Query blockchain for complete supply chain data
    const provenance = await this.blockchainService.evaluateTransaction(
      'GetProvenanceByQRCode',
      qrCode
    );

    // Enhance with additional metadata
    return {
      ...provenance,
      scanTimestamp: new Date().toISOString(),
      consumerMessage: this.generateConsumerMessage(provenance)
    };
  }

  private generateConsumerMessage(provenance: any): string {
    return `
      This product contains ${provenance.product.name} sourced from 
      ${provenance.collectionEvents.length} farmer(s) and tested by 
      ${provenance.qualityTests.length} lab(s). Sustainability score: 
      ${provenance.sustainabilityScore}/100.
    `;
  }
}
```

---

### **Phase 4: Supporting Services (Week 6)**

#### 4.1 Season Window Management
```typescript
// src/season-windows/season-windows.service.ts
@Injectable()
export class SeasonWindowsService {
  async initializeSeasonWindows() {
    // Pre-populate season windows during system initialization
    const windows = [
      {
        id: 'SW-ASH-001',
        species: 'Ashwagandha',
        startMonth: 11,
        endMonth: 2,
        region: 'Madhya Pradesh',
        active: true
      },
      {
        id: 'SW-TUL-001',
        species: 'Tulsi',
        startMonth: 9,
        endMonth: 3,
        region: 'Maharashtra',
        active: true
      },
      // ... more windows
    ];

    for (const window of windows) {
      await this.blockchainService.submitTransaction(
        'CreateSeasonWindow',
        JSON.stringify(window)
      );
      
      // Wait 15 seconds for CouchDB indexing
      await new Promise(resolve => setTimeout(resolve, 15000));
    }
  }

  async validateHarvestSeason(
    species: string, 
    region: string, 
    harvestDate: Date
  ) {
    // Check if harvest is within allowed season window
    const windows = await this.blockchainService.evaluateTransaction(
      'GetSeasonWindows',
      species
    );

    const validWindow = windows.find(w => 
      w.region === region && this.isDateInWindow(harvestDate, w)
    );

    return {
      isValid: !!validWindow,
      window: validWindow,
      message: validWindow 
        ? 'Harvest is within allowed season'
        : 'Harvest outside allowed season window'
    };
  }
}
```

#### 4.2 Alert Service
```typescript
// src/alerts/alerts.service.ts
@Injectable()
export class AlertsService {
  async createAlert(dto: CreateAlertDto) {
    const alertId = this.generateAlertId();
    
    const payload = {
      id: alertId,
      type: 'Alert',
      alertType: dto.alertType,
      severity: dto.severity,
      entityId: dto.entityId,
      entityType: dto.entityType,
      message: dto.message,
      details: dto.details,
      status: 'active',
      createdDate: new Date().toISOString()
    };

    await this.blockchainService.submitTransaction(
      'CreateAlert',
      JSON.stringify(payload)
    );

    // Send real-time notification
    await this.sendAlertNotification(dto);

    return { success: true, alertId };
  }

  async getActiveAlerts() {
    return await this.blockchainService.evaluateTransaction(
      'GetActiveAlerts'
    );
  }

  async getCriticalAlerts() {
    return await this.blockchainService.evaluateTransaction(
      'GetCriticalAlerts'
    );
  }

  private async sendAlertNotification(dto: CreateAlertDto) {
    if (dto.severity === 'critical') {
      // Send SMS + Email + Push
      await Promise.all([
        this.notificationService.sendSMS(dto.recipientPhone, dto.message),
        this.notificationService.sendEmail(dto.recipientEmail, dto.message),
        this.notificationService.sendPush(dto.recipientId, dto.message)
      ]);
    } else if (dto.severity === 'high') {
      // Send Email + Push
      await Promise.all([
        this.notificationService.sendEmail(dto.recipientEmail, dto.message),
        this.notificationService.sendPush(dto.recipientId, dto.message)
      ]);
    } else {
      // Send Push only
      await this.notificationService.sendPush(dto.recipientId, dto.message);
    }
  }
}
```

#### 4.3 Analytics Service
```typescript
// src/analytics/analytics.service.ts
@Injectable()
export class AnalyticsService {
  async getDashboardStats(userId: string, role: string) {
    switch (role) {
      case 'farmer':
        return this.getFarmerDashboard(userId);
      case 'testing_lab':
        return this.getLabDashboard(userId);
      case 'processor':
        return this.getProcessorDashboard(userId);
      case 'manufacturer':
        return this.getManufacturerDashboard(userId);
      default:
        return this.getAdminDashboard();
    }
  }

  private async getFarmerDashboard(farmerId: string) {
    const [collections, statistics, alerts] = await Promise.all([
      this.blockchainService.evaluateTransaction(
        'QueryCollectionsByFarmer',
        farmerId
      ),
      this.blockchainService.evaluateTransaction(
        'GetHarvestStatistics',
        farmerId,
        'Ashwagandha',
        '2025-Winter'
      ),
      this.alertsService.getActiveAlerts()
    ]);

    return {
      totalCollections: collections.length,
      totalQuantity: collections.reduce((sum, c) => sum + c.quantity, 0),
      harvestLimit: statistics.maxQuantity,
      remainingQuota: statistics.remainingQuantity,
      activeAlerts: alerts.filter(a => a.farmerId === farmerId).length,
      recentCollections: collections.slice(0, 5)
    };
  }

  private async getLabDashboard(labId: string) {
    const tests = await this.blockchainService.evaluateTransaction(
      'QueryQualityTestsByLab',
      labId
    );

    return {
      totalTests: tests.length,
      passRate: this.calculatePassRate(tests),
      pendingTests: tests.filter(t => t.status === 'pending').length,
      recentTests: tests.slice(0, 5)
    };
  }
}
```

---

### **Phase 5: API Endpoints (Week 7)**

#### Complete REST API Design

```typescript
// Auth Endpoints
POST   /api/v1/auth/register         # Register new user
POST   /api/v1/auth/login            # Login
POST   /api/v1/auth/refresh          # Refresh token
POST   /api/v1/auth/logout           # Logout

// User Management
GET    /api/v1/users/profile         # Get user profile
PUT    /api/v1/users/profile         # Update profile
POST   /api/v1/users/verify-kyc      # Submit KYC documents
GET    /api/v1/users/stats           # User statistics

// Collection Events (Farmer)
POST   /api/v1/collections           # Create collection event
GET    /api/v1/collections           # Get all collections
GET    /api/v1/collections/:id       # Get collection by ID
GET    /api/v1/collections/farmer/:farmerId  # By farmer
POST   /api/v1/collections/:id/images  # Upload additional images

// Batches
POST   /api/v1/batches               # Create batch
GET    /api/v1/batches               # Get all batches
GET    /api/v1/batches/:id           # Get batch by ID
PUT    /api/v1/batches/:id/assign    # Assign to processor
PUT    /api/v1/batches/:id/status    # Update status
GET    /api/v1/batches/status/:status  # By status
GET    /api/v1/batches/processor/:processorId  # By processor
GET    /api/v1/batches/pending       # Pending batches

// Quality Tests (Lab)
POST   /api/v1/quality-tests         # Create quality test
GET    /api/v1/quality-tests/:id     # Get test by ID
GET    /api/v1/quality-tests/batch/:batchId  # Tests for batch
GET    /api/v1/quality-tests/lab/:labId  # Tests by lab
POST   /api/v1/quality-tests/:id/certificate  # Upload certificate

// Processing Steps (Processor)
POST   /api/v1/processing            # Create processing step
GET    /api/v1/processing/:id        # Get step by ID
GET    /api/v1/processing/batch/:batchId  # Steps for batch

// Products (Manufacturer)
POST   /api/v1/products              # Create product
GET    /api/v1/products/:id          # Get product by ID
GET    /api/v1/products/qr/:qrCode   # Get by QR code
GET    /api/v1/products/:id/qr-image # Download QR image

// Provenance (Consumer)
GET    /api/v1/provenance/qr/:qrCode # Scan QR code
GET    /api/v1/provenance/product/:productId  # By product ID

// Season Windows (Admin)
POST   /api/v1/season-windows        # Create season window
GET    /api/v1/season-windows        # Get all windows
GET    /api/v1/season-windows/species/:species  # By species
PUT    /api/v1/season-windows/:id    # Update window
POST   /api/v1/season-windows/validate  # Validate harvest date

// Harvest Limits (Admin)
POST   /api/v1/harvest-limits        # Create harvest limit
GET    /api/v1/harvest-limits/:id    # Get limit by ID
GET    /api/v1/harvest-limits/farmer/:farmerId  # By farmer
GET    /api/v1/harvest-limits/stats  # Statistics

// Alerts
GET    /api/v1/alerts                # Get all alerts
GET    /api/v1/alerts/active         # Active alerts
GET    /api/v1/alerts/critical       # Critical alerts
PUT    /api/v1/alerts/:id/acknowledge  # Acknowledge alert
PUT    /api/v1/alerts/:id/resolve    # Resolve alert
GET    /api/v1/alerts/stats          # Alert statistics

// Analytics
GET    /api/v1/analytics/dashboard   # Dashboard stats
GET    /api/v1/analytics/reports     # Generate reports
GET    /api/v1/analytics/export      # Export data

// Notifications
POST   /api/v1/notifications/subscribe  # Subscribe to push
GET    /api/v1/notifications         # Get notifications
PUT    /api/v1/notifications/:id/read  # Mark as read

// Health & Monitoring
GET    /api/v1/health                # Health check
GET    /api/v1/health/blockchain     # Blockchain status
GET    /api/v1/health/database       # Database status
```

---

### **Phase 6: Testing & Documentation (Week 8)**

#### 6.1 Unit Tests
```typescript
// collection-events.service.spec.ts
describe('CollectionEventsService', () => {
  it('should create collection event successfully', async () => {
    const dto: CreateCollectionEventDto = {
      species: 'Ashwagandha',
      quantity: 50.5,
      // ...
    };

    const result = await service.create('FARM001', dto, []);
    
    expect(result.success).toBe(true);
    expect(result.collectionEventId).toBeDefined();
  });
});
```

#### 6.2 E2E Tests
```typescript
// app.e2e-spec.ts
describe('Collection Events (e2e)', () => {
  it('/POST collections', () => {
    return request(app.getHttpServer())
      .post('/api/v1/collections')
      .set('Authorization', `Bearer ${token}`)
      .send(dto)
      .expect(201)
      .expect((res) => {
        expect(res.body.collectionEventId).toBeDefined();
      });
  });
});
```

#### 6.3 Swagger Documentation
```typescript
// main.ts
const config = new DocumentBuilder()
  .setTitle('HerbalTrace API')
  .setDescription('Blockchain-based herbal supply chain traceability')
  .setVersion('1.0')
  .addBearerAuth()
  .build();

const document = SwaggerModule.createDocument(app, config);
SwaggerModule.setup('api/docs', app, document);
```

---

### **Phase 7: Deployment (Week 9)**

#### Docker Compose for Local Development
```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - postgres
      - redis
    volumes:
      - ./network:/app/network
      
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: herbaltrace_db
      POSTGRES_USER: herbaltrace
      POSTGRES_PASSWORD: secure_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
      
  minio:
    image: minio/minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data

volumes:
  postgres_data:
  minio_data:
```

---

## 🔐 Security Checklist

- [x] JWT authentication with refresh tokens
- [x] Password hashing with bcrypt (10 rounds)
- [x] Role-based access control (RBAC)
- [x] API rate limiting (100 req/min per IP)
- [x] Input validation (class-validator)
- [x] SQL injection prevention (TypeORM parameterized queries)
- [x] XSS protection (Helmet.js)
- [x] CORS configuration
- [x] HTTPS in production
- [x] File upload size limits (10MB)
- [x] Blockchain transaction signing

---

## 📊 Performance Optimization

1. **Caching Strategy**
   - Redis for session storage
   - Cache blockchain queries (TTL: 60s)
   - Cache dashboard stats (TTL: 5 min)

2. **Database Optimization**
   - Index on frequently queried fields
   - Connection pooling (max 20 connections)
   - Query optimization

3. **API Optimization**
   - Response compression (gzip)
   - Pagination (default 20 items)
   - Lazy loading for large datasets

---

## 🚀 Go-Live Checklist

- [ ] All unit tests passing
- [ ] E2E tests passing
- [ ] Load testing completed (100 concurrent users)
- [ ] Security audit completed
- [ ] API documentation complete
- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] Monitoring dashboards configured
- [ ] Backup strategy implemented
- [ ] Disaster recovery plan documented

---

## 📞 Support & Maintenance

- **API Documentation:** https://api.herbaltrace.com/docs
- **Status Page:** https://status.herbaltrace.com
- **Issue Tracker:** GitHub Issues
- **Support Email:** support@herbaltrace.com

---

**BACKEND READY FOR DEVELOPMENT ✅**

Next Steps:
1. Run `npm install` to install dependencies
2. Configure `.env` file
3. Run migrations: `npm run migration:run`
4. Initialize season windows: `npm run seed:seasons`
5. Start development server: `npm run start:dev`
6. Access Swagger docs: http://localhost:3000/api/docs
