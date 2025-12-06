# HerbalTrace - Complete Implementation Guide

## 🚀 Project Overview

This guide provides complete implementation for:
1. **Backend API** - Node.js + Express + Hyperledger Fabric SDK ✅
2. **Farmer Mobile App** - React Native (Offline-first, Multilingual) 🟡 In Progress
3. **Web Portal** - React.js for Lab/Processor/Manufacturer
4. **Admin Dashboard** - React.js with Blockchain Visualization

---

## 📁 Project Structure

```
HerbalTrace/
├── backend/                          # ✅ Backend API (TypeScript)
│   ├── src/
│   │   ├── fabric/
│   │   │   └── fabricClient.ts       # Fabric SDK integration
│   │   ├── routes/
│   │   │   ├── auth.routes.ts
│   │   │   ├── collection.routes.ts
│   │   │   ├── quality.routes.ts
│   │   │   ├── processing.routes.ts
│   │   │   ├── product.routes.ts
│   │   │   ├── provenance.routes.ts
│   │   │   ├── analytics.routes.ts
│   │   │   └── qr.routes.ts
│   │   ├── middleware/
│   │   │   ├── auth.ts
│   │   │   └── errorHandler.ts
│   │   ├── utils/
│   │   │   └── logger.ts
│   │   └── index.ts
│   └── package.json
│
├── farmer-app/                       # 🟡 Farmer Mobile App (React Native + Expo)
│   ├── src/
│   │   ├── theme/
│   │   │   └── theme.ts              # Earthy color palette ✅
│   │   ├── i18n/
│   │   │   ├── i18n.ts               # Multilingual config ✅
│   │   │   └── locales/
│   │   │       ├── en.json           # English translations ✅
│   │   │       └── hi.json           # Hindi translations ✅
│   │   ├── services/
│   │   │   ├── database.service.ts   # SQLite offline database ✅
│   │   │   ├── api.service.ts        # API integration ✅
│   │   │   ├── sync.service.ts       # Offline sync ✅
│   │   │   ├── location.service.ts   # GPS auto-capture
│   │   │   └── notification.service.ts # Push notifications
│   │   ├── screens/
│   │   │   ├── HomeScreen.tsx        # Dashboard with stats
│   │   │   ├── NewHarvestScreen.tsx  # Step-by-step harvest recording
│   │   │   ├── MyHarvestsScreen.tsx  # History & pending uploads
│   │   │   ├── PaymentsScreen.tsx    # Payment status
│   │   │   ├── TrainingScreen.tsx    # Training videos
│   │   │   └── ProfileScreen.tsx     # Settings & language
│   │   ├── components/
│   │   │   ├── HarvestCard.tsx
│   │   │   ├── StatCard.tsx
│   │   │   ├── OfflineBanner.tsx
│   │   │   └── LanguageSwitcher.tsx
│   │   └── navigation/
│   │       └── AppNavigator.tsx
│   ├── App.tsx
│   ├── app.json
│   └── package.json
│
├── web-portal/                       # 🔴 Web Portal (React.js + TypeScript)
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx         # Role-based dashboard
│   │   │   ├── QualityTest.tsx       # Lab quality testing
│   │   │   ├── Processing.tsx        # Processor operations
│   │   │   ├── Manufacturing.tsx     # Product creation + QR gen
│   │   │   └── History.tsx           # Transaction history
│   │   ├── components/
│   │   │   ├── QRGenerator.tsx       # QR code generation
│   │   │   ├── BlockchainStatus.tsx
│   │   │   └── DataTable.tsx
│   │   ├── services/
│   │   │   └── api.service.ts
│   │   └── App.tsx
│   └── package.json
│
├── admin-dashboard/                  # 🔴 Admin/Regulator Dashboard
│   ├── src/
│   │   ├── pages/
│   │   │   ├── BlockchainVisualizer.tsx  # Block explorer
│   │   │   ├── NetworkHealth.tsx         # Network metrics
│   │   │   ├── Transactions.tsx          # Transaction explorer
│   │   │   └── Analytics.tsx             # Insights & reports
│   │   ├── components/
│   │   │   ├── BlockCard.tsx
│   │   │   ├── TransactionFlow.tsx
│   │   │   ├── NetworkGraph.tsx
│   │   │   └── Charts.tsx
│   │   └── App.tsx
│   └── package.json
│
├── network/                          # ✅ Hyperledger Fabric Network
├── chaincode/                        # ✅ Smart Contracts
└── NETWORK_INTEGRATION_GUIDE.md      # ✅ Complete API documentation
```

---

## 1️⃣ Backend API (✅ COMPLETE)

### Already Implemented:
- ✅ Hyperledger Fabric SDK integration
- ✅ All REST API endpoints
- ✅ Authentication middleware
- ✅ Error handling
- ✅ Logging
- ✅ Rate limiting

### Setup & Run:

```bash
cd backend

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env with your configuration

# Build TypeScript
npm run build

# Start server
npm start

# Development mode
npm run dev
```

### Environment Variables (.env):

```env
# Server
PORT=3000
NODE_ENV=development

# CORS
CORS_ORIGIN=*

# Fabric Network
FABRIC_NETWORK_PATH=../network
FABRIC_CHANNEL=herbaltrace-channel
FABRIC_CHAINCODE=herbaltrace

# Organizations
FARMERS_ORG=FarmersCoop
LABS_ORG=TestingLabs
PROCESSORS_ORG=Processors
MANUFACTURERS_ORG=Manufacturers

# JWT
JWT_SECRET=your_jwt_secret_here_change_in_production
JWT_EXPIRY=7d

# Database (optional for caching/analytics)
DATABASE_URL=postgresql://localhost:5432/herbaltrace

# Redis (optional for caching)
REDIS_URL=redis://localhost:6379
```

### API Endpoints:

**Authentication:**
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user

**Collections (Farmer):**
- `POST /api/collections` - Create harvest record
- `GET /api/collections/:id` - Get harvest by ID
- `GET /api/collections/farmer/:farmerId` - Get farmer's harvests

**Quality Tests (Lab):**
- `POST /api/quality-tests` - Record quality test
- `GET /api/quality-tests/:id` - Get test by ID
- `GET /api/quality-tests/collection/:collectionId` - Get tests for collection

**Processing (Processor):**
- `POST /api/processing` - Record processing step
- `GET /api/processing/:id` - Get processing by ID

**Products (Manufacturer):**
- `POST /api/products` - Create product with QR code
- `GET /api/products/:id` - Get product by ID
- `GET /api/products/qr/:qrCode` - Get product by QR code

**Provenance (Consumer):**
- `GET /api/provenance/:productId` - Get complete supply chain
- `GET /api/provenance/qr/:qrCode` - Get provenance by QR scan

**Analytics:**
- `GET /api/analytics/farmer/:farmerId` - Farmer statistics
- `GET /api/analytics/lab/:labId` - Lab statistics
- `GET /api/analytics/network` - Network-wide analytics

**QR Code:**
- `GET /api/qr/generate/:productId` - Generate QR code image

---

## 2️⃣ Farmer Mobile App (🟡 IN PROGRESS)

### Features Implemented:
- ✅ Organic earthy theme (greens, browns, light tones)
- ✅ Multilingual support (English, Hindi) with RTL ready
- ✅ Offline-first SQLite database
- ✅ API service for blockchain integration
- ✅ Sync service with queue management
- 🔄 **TODO: Complete UI screens**
- 🔄 **TODO: GPS auto-capture**
- 🔄 **TODO: Camera integration**
- 🔄 **TODO: Push notifications**

### Missing Dependencies:

```bash
cd farmer-app

# Install missing packages
npm install @react-native-community/netinfo
npm install uuid
npm install @types/uuid --save-dev
npm install expo-sqlite@next  # Use latest version
```

### Key Files Created:
1. **theme.ts** - Beautiful organic color palette
2. **i18n.ts** - Multilingual configuration
3. **en.json** - Complete English translations
4. **hi.json** - Complete Hindi translations
5. **database.service.ts** - Offline SQLite database
6. **api.service.ts** - Backend API integration
7. **sync.service.ts** - Offline sync with retry logic

### Next Steps for Farmer App:

#### A. Create Main App Entry Point:

```typescript
// App.tsx
import React, { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { Provider as PaperProvider } from 'react-native-paper';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import './src/i18n/i18n';
import { db } from './src/services/database.service';
import AppNavigator from './src/navigation/AppNavigator';
import { Theme } from './src/theme/theme';

export default function App() {
  useEffect(() => {
    // Initialize database
    db.init().catch((error) => {
      console.error('Failed to initialize database:', error);
    });
  }, []);

  return (
    <SafeAreaProvider>
      <PaperProvider theme={Theme}>
        <NavigationContainer>
          <AppNavigator />
        </NavigationContainer>
      </PaperProvider>
    </SafeAreaProvider>
  );
}
```

#### B. Create Navigation:

```typescript
// src/navigation/AppNavigator.tsx
import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

import HomeScreen from '../screens/HomeScreen';
import NewHarvestScreen from '../screens/NewHarvestScreen';
import MyHarvestsScreen from '../screens/MyHarvestsScreen';
import PaymentsScreen from '../screens/PaymentsScreen';
import TrainingScreen from '../screens/TrainingScreen';
import ProfileScreen from '../screens/ProfileScreen';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

const TabNavigator = () => {
  return (
    <Tab.Navigator
      screenOptions={{
        tabBarActiveTintColor: '#2D5016',
        tabBarInactiveTintColor: '#95A5A6',
        tabBarStyle: { height: 60, paddingBottom: 8 },
      }}
    >
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{
          tabBarIcon: ({ color, size }) => (
            <Icon name="home" color={color} size={size} />
          ),
        }}
      />
      <Tab.Screen
        name="New Harvest"
        component={NewHarvestScreen}
        options={{
          tabBarIcon: ({ color, size }) => (
            <Icon name="plus-circle" color={color} size={size} />
          ),
        }}
      />
      <Tab.Screen
        name="My Harvests"
        component={MyHarvestsScreen}
        options={{
          tabBarIcon: ({ color, size }) => (
            <Icon name="history" color={color} size={size} />
          ),
        }}
      />
      <Tab.Screen
        name="Payments"
        component={PaymentsScreen}
        options={{
          tabBarIcon: ({ color, size }) => (
            <Icon name="cash" color={color} size={size} />
          ),
        }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          tabBarIcon: ({ color, size }) => (
            <Icon name="account" color={color} size={size} />
          ),
        }}
      />
    </Tab.Navigator>
  );
};

export default function AppNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen
        name="Main"
        component={TabNavigator}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="Training"
        component={TrainingScreen}
        options={{ title: 'Training Videos' }}
      />
    </Stack.Navigator>
  );
}
```

#### C. Create Screens (Example - HomeScreen):

```typescript
// src/screens/HomeScreen.tsx
import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { useTranslation } from 'react-i18next';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import { db } from '../services/database.service';
import { syncService } from '../services/sync.service';
import { Colors, Spacing, Typography } from '../theme/theme';
import OfflineBanner from '../components/OfflineBanner';
import StatCard from '../components/StatCard';

export default function HomeScreen({ navigation }: any) {
  const { t } = useTranslation();
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    synced: 0,
    thisMonth: 0,
  });
  const [isOnline, setIsOnline] = useState(syncService.getOnlineStatus());
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadStats();

    // Listen to sync status
    const listener = () => {
      setIsOnline(syncService.getOnlineStatus());
      loadStats();
    };
    syncService.addSyncListener(listener);

    return () => syncService.removeSyncListener(listener);
  }, []);

  const loadStats = async () => {
    try {
      const harvestStats = await db.getHarvestStats();
      setStats(harvestStats);
    } catch (error) {
      console.error('Failed to load stats:', error);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadStats();
    if (isOnline) {
      await syncService.syncAll();
    }
    setRefreshing(false);
  };

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return t('home.morning');
    if (hour < 18) return t('home.afternoon');
    return t('home.evening');
  };

  return (
    <View style={styles.container}>
      {!isOnline && <OfflineBanner />}

      <ScrollView
        style={styles.scrollView}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.greeting}>
            {t('home.greeting', { time: getGreeting(), name: 'राजेश' })}
          </Text>
        </View>

        {/* Stats Cards */}
        <View style={styles.statsContainer}>
          <StatCard
            title={t('home.stats.totalHarvests')}
            value={stats.total}
            icon="leaf"
            color={Colors.primary}
          />
          <StatCard
            title={t('home.stats.pending')}
            value={stats.pending}
            icon="clock-outline"
            color={Colors.warning}
          />
          <StatCard
            title={t('home.stats.thisMonth')}
            value={stats.thisMonth}
            icon="calendar-month"
            color={Colors.accent}
          />
          <StatCard
            title={t('home.stats.earnings')}
            value="₹12,450"
            icon="currency-inr"
            color={Colors.success}
          />
        </View>

        {/* Quick Actions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('home.quickActions')}</Text>
          
          <TouchableOpacity
            style={[styles.actionCard, styles.primaryAction]}
            onPress={() => navigation.navigate('New Harvest')}
          >
            <Icon name="plus-circle" size={48} color={Colors.white} />
            <Text style={styles.actionTitle}>{t('home.newHarvest')}</Text>
          </TouchableOpacity>

          <View style={styles.actionRow}>
            <TouchableOpacity
              style={styles.secondaryAction}
              onPress={() => navigation.navigate('My Harvests')}
            >
              <Icon name="history" size={32} color={Colors.primary} />
              <Text style={styles.secondaryActionText}>
                {t('home.viewHistory')}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.secondaryAction}
              onPress={() => navigation.navigate('Payments')}
            >
              <Icon name="cash" size={32} color={Colors.primary} />
              <Text style={styles.secondaryActionText}>
                {t('home.payments')}
              </Text>
            </TouchableOpacity>
          </View>

          <TouchableOpacity
            style={styles.secondaryAction}
            onPress={() => navigation.navigate('Training')}
          >
            <Icon name="school" size={32} color={Colors.primary} />
            <Text style={styles.secondaryActionText}>
              {t('home.training')}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    padding: Spacing.lg,
    backgroundColor: Colors.primary,
  },
  greeting: {
    fontSize: Typography.h3,
    fontWeight: 'bold',
    color: Colors.white,
  },
  statsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    padding: Spacing.md,
    gap: Spacing.md,
  },
  section: {
    padding: Spacing.lg,
  },
  sectionTitle: {
    fontSize: Typography.h5,
    fontWeight: 'bold',
    color: Colors.text,
    marginBottom: Spacing.md,
  },
  primaryAction: {
    backgroundColor: Colors.primary,
    borderRadius: 16,
    padding: Spacing.xl,
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  actionCard: {
    // Shared action card styles
  },
  actionTitle: {
    fontSize: Typography.h5,
    fontWeight: 'bold',
    color: Colors.white,
    marginTop: Spacing.sm,
  },
  actionRow: {
    flexDirection: 'row',
    gap: Spacing.md,
    marginBottom: Spacing.md,
  },
  secondaryAction: {
    flex: 1,
    backgroundColor: Colors.surface,
    borderRadius: 12,
    padding: Spacing.lg,
    alignItems: 'center',
    ...Shadows.medium,
  },
  secondaryActionText: {
    fontSize: Typography.body2,
    color: Colors.text,
    marginTop: Spacing.sm,
    textAlign: 'center',
  },
});
```

### Run Farmer App:

```bash
cd farmer-app

# Install dependencies
npm install

# Start Expo
npx expo start

# Run on Android
npm run android

# Run on iOS (requires Mac)
npm run ios

# Run on Web
npm run web
```

---

## 3️⃣ Web Portal (🔴 TODO)

### Features Needed:
- **Lab Dashboard** - Quality testing interface
- **Processor Dashboard** - Processing records
- **Manufacturer Dashboard** - Product creation + QR generation
- **Responsive Design** - Modern UI
- **Real-time Blockchain Status**

### Tech Stack:
- React.js + TypeScript
- Material-UI or Ant Design
- React Query for API calls
- React Router for navigation
- QRCode.react for QR generation

### Setup:

```bash
cd web-portal

# Create React app
npx create-react-app . --template typescript

# Install dependencies
npm install @mui/material @emotion/react @emotion/styled
npm install react-router-dom
npm install axios react-query
npm install qrcode.react
npm install recharts  # For charts
```

---

## 4️⃣ Admin Dashboard (🔴 TODO)

### Features Needed:
- **Block Explorer** - Visualize blocks (like Hyperledger Firefly)
- **Transaction Explorer** - View all transactions
- **Network Health** - Peer status, consensus
- **Analytics** - Supply chain insights
- **Real-time Updates** - WebSocket or polling

### Tech Stack:
- React.js + TypeScript
- D3.js or React Flow for visualization
- Material-UI
- WebSocket for real-time data

### Visualization Features:
- Block timeline
- Transaction flow diagram
- Network topology graph
- Performance metrics
- Organization participation stats

---

## 🎯 Next Immediate Steps

### Priority 1: Complete Farmer App
1. Fix TypeScript compilation errors
2. Create all screen components
3. Implement GPS service
4. Add camera integration
5. Setup push notifications
6. Test offline sync

### Priority 2: Build Web Portal
1. Setup React app
2. Create role-based dashboards
3. Implement all forms
4. Add QR generation
5. Connect to backend API

### Priority 3: Build Admin Dashboard
1. Setup React app
2. Create blockchain visualizer
3. Implement block explorer
4. Add transaction viewer
5. Create analytics dashboard

### Priority 4: Integration Testing
1. Test end-to-end flow
2. Performance testing
3. Security audit
4. User acceptance testing

---

## 🛠️ Development Commands

### Start Everything:

```bash
# Terminal 1: Blockchain Network
cd network/docker
docker compose -f docker-compose-herbaltrace.yaml up -d

# Terminal 2: Backend API
cd backend
npm run dev

# Terminal 3: Farmer Mobile App
cd farmer-app
npx expo start

# Terminal 4: Web Portal (when ready)
cd web-portal
npm start

# Terminal 5: Admin Dashboard (when ready)
cd admin-dashboard
npm start
```

### Test Complete Flow:

1. **Farmer records harvest** (Mobile app offline)
2. **App syncs to blockchain** (When online)
3. **Lab tests quality** (Web portal)
4. **Processor processes** (Web portal)
5. **Manufacturer creates product** (Web portal)
6. **Consumer scans QR** (Mobile app)
7. **Admin views transaction** (Admin dashboard)

---

## 📝 Estimated Timeline

- ✅ Backend API: **COMPLETE**
- 🟡 Farmer Mobile App: **50% complete** (3-5 days remaining)
- 🔴 Web Portal: **Not started** (5-7 days)
- 🔴 Admin Dashboard: **Not started** (7-10 days)
- 🔴 Testing & Deployment: (5-7 days)

**Total Estimated Time:** 3-4 weeks for full implementation

---

## 🎨 Design System

### Farmer Mobile App Theme:
- **Primary:** Deep Forest Green (#2D5016)
- **Secondary:** Warm Earth Brown (#8B4513)
- **Accent:** Fresh Herb Green (#7CB342)
- **Background:** Light Beige (#F5F5DC)
- **Typography:** System fonts, easy-to-read
- **Rounded Cards:** 16px border radius
- **Soft Shadows:** elevation 2-8

### Web Portal Theme:
- Professional and clean
- Same color palette for brand consistency
- Data tables with clear hierarchy
- Form validation with inline errors

### Admin Dashboard Theme:
- Dark mode for better visualization
- High contrast for charts
- Interactive elements
- Real-time indicators

---

## 📚 Additional Resources

- **Backend API Docs:** See `NETWORK_INTEGRATION_GUIDE.md`
- **Quick Reference:** See `QUICK_REFERENCE.md`
- **Hyperledger Fabric Docs:** https://hyperledger-fabric.readthedocs.io
- **React Native Docs:** https://reactnative.dev
- **Expo Docs:** https://docs.expo.dev

---

## 🆘 Support & Troubleshooting

### Common Issues:

1. **Database initialization fails:**
   - Use `expo-sqlite@next` for latest version
   - Check permissions in app.json

2. **Network connection fails:**
   - Check backend URL in api.service.ts
   - For Android emulator use `10.0.2.2:3000`
   - For iOS simulator use `localhost:3000`

3. **Blockchain connection fails:**
   - Ensure network is running
   - Check connection profiles
   - Verify wallet identities

4. **Compilation errors:**
   - Install missing type definitions
   - Update tsconfig.json
   - Clear cache: `npx expo start -c`

---

**Status:** Backend ✅ | Mobile App 🟡 50% | Web Portal 🔴 | Admin Dashboard 🔴

**Next Action:** Complete Farmer Mobile App UI screens and services
