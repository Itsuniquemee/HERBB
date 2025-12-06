# 🌐 IoT Integration Design for HerbalTrace Blockchain Network

## Executive Summary

This document outlines the comprehensive IoT integration strategy for the HerbalTrace blockchain network, detailing sensor types, data collection methods, network architecture, and blockchain integration patterns.

---

## 🎯 IoT Integration Objectives

1. **Real-time Monitoring**: Continuous environmental and quality parameter tracking
2. **Cold Chain Integrity**: Temperature/humidity compliance throughout supply chain
3. **Automated Data Entry**: Reduce manual errors, increase data accuracy
4. **Predictive Alerts**: AI-powered anomaly detection and preventive actions
5. **Compliance Automation**: Automatic NMPB/AYUSH guideline enforcement
6. **Energy Efficiency**: Solar-powered sensors for remote farm locations

---

## 📡 IoT Sensor Categories & Specifications

### **1. FARM/COLLECTION STAGE SENSORS**

#### **A. Environmental Monitoring Station**
**Purpose**: Monitor growing conditions and harvest-time environmental data

**Sensors**:
- **Soil Moisture Sensor** (Capacitive)
  - Range: 0-100% VWC (Volumetric Water Content)
  - Accuracy: ±3%
  - Depth: 10cm, 30cm, 60cm (multi-layer)
  - Protocol: I2C
  - Model: DFRobot SEN0193 or Adafruit STEMMA
  
- **Soil pH Sensor**
  - Range: pH 3-10
  - Accuracy: ±0.1 pH
  - Protocol: Analog (ADC)
  - Model: Atlas Scientific pH Kit
  
- **Soil NPK Sensor** (Nitrogen, Phosphorus, Potassium)
  - Range: 0-1999 mg/kg
  - Accuracy: ±2%
  - Protocol: RS485/Modbus
  - Model: Jingxun RS-NPKPH-N01
  
- **Weather Station**
  - Temperature: -40°C to 85°C (±0.3°C)
  - Humidity: 0-100% RH (±2%)
  - Barometric Pressure: 300-1100 hPa
  - Rainfall: 0-999mm (0.2mm resolution)
  - Wind Speed: 0-30 m/s (±0.3 m/s)
  - Wind Direction: 0-360° (±3°)
  - Light Intensity: 0-200,000 Lux
  - UV Index: 0-15
  - Model: Davis Vantage Pro2 or DIY Arduino-based

**Data Collection Frequency**: Every 15 minutes  
**Power**: Solar panel (20W) + LiPo battery (6000mAh)  
**Connectivity**: LoRaWAN (for remote farms) or 4G LTE  
**Cost per Station**: $300-$800

#### **B. Harvest Event Logger (Portable)**
**Purpose**: Attach to harvest baskets/containers during collection

**Sensors**:
- **GPS Module** (High-precision)
  - Accuracy: <2.5m CEP
  - GNSS: GPS + GLONASS + Galileo + BeiDou
  - Model: u-blox NEO-M9N
  
- **Temperature Sensor**
  - Range: -20°C to 60°C (±0.2°C)
  - For immediate post-harvest cooling tracking
  
- **Load Cell** (Weight)
  - Range: 0-100kg
  - Accuracy: ±0.1%
  - Auto-log harvest quantity
  
- **Timestamp Module** (RTC)
  - Accurate time tracking with drift compensation
  
- **NFC Tag**
  - ISO 14443A (NTAG216)
  - Store harvest batch ID, farmer ID

**Data Collection**: Event-triggered (harvest start/end)  
**Power**: Rechargeable Li-ion (1 week battery life)  
**Connectivity**: Bluetooth Low Energy (BLE) → Farmer's mobile app  
**Cost per Unit**: $80-$150

#### **C. Smart Cultivation Zone Markers**
**Purpose**: Geo-fence approved cultivation zones

**Features**:
- **GPS Boundary Markers**
  - Solar-powered stake sensors
  - LoRa mesh network
  - Alert if harvesting outside approved zone
  
- **Wildlife Detection Camera**
  - Motion-activated
  - IR night vision
  - Conservation monitoring
  
**Cost per Marker**: $50-$100

---

### **2. TRANSPORTATION/COLD CHAIN SENSORS**

#### **A. Smart Container Tags (Active RFID)**
**Purpose**: Track herbs from farm to processing facility

**Sensors**:
- **Temperature & Humidity Logger**
  - Temp: -40°C to 85°C (±0.3°C)
  - Humidity: 0-100% RH (±2%)
  - Data logging: Every 5 minutes
  - 30-day memory buffer
  - Model: Elitech RC-5+ or LogTag TRIX-16
  
- **Shock/Vibration Sensor**
  - 3-axis accelerometer (±16g)
  - Detect rough handling
  
- **GPS Tracker**
  - Real-time location updates
  - Geofencing alerts
  - Model: Quectel BG96 (LTE Cat-M1/NB-IoT)
  
- **Light Exposure Sensor**
  - Detect if container opened during transit
  
- **Tamper-Evident Seal**
  - RFID seal that alerts if broken

**Data Collection**: Every 5 minutes during transit  
**Power**: Non-rechargeable lithium (1-year life)  
**Connectivity**: NB-IoT / LTE Cat-M1  
**Cost per Tag**: $40-$80 (reusable)

#### **B. Vehicle Telematics (Truck/Van)**
**Purpose**: Monitor transport vehicles carrying herbs

**Sensors**:
- **OBD-II Port Adapter**
  - Engine diagnostics
  - Fuel efficiency
  - Driver behavior (harsh braking, speeding)
  
- **Cabin Temperature Sensor**
  - Ensure cold chain compliance
  
- **Door Open/Close Sensor**
  - Magnetic reed switch
  - Track loading/unloading events

**Connectivity**: 4G LTE  
**Cost per Vehicle Unit**: $150-$300

---

### **3. STORAGE FACILITY SENSORS**

#### **A. Warehouse Environmental Monitoring**
**Purpose**: Monitor storage rooms/cold storage at labs, processors, manufacturers

**Sensors**:
- **Multi-Zone Temperature Sensors**
  - Wireless mesh network
  - 1 sensor per 100 sq ft
  - Range: -30°C to 60°C (±0.2°C)
  - Model: Monnit ALTA Wireless Sensors
  
- **Humidity Sensors**
  - 0-100% RH (±1.5%)
  - Mold/fungus prevention
  
- **CO₂ Sensors**
  - Range: 0-5000 ppm
  - Ventilation quality monitoring
  
- **Differential Pressure Sensors**
  - For cleanroom compliance (pharmaceutical manufacturing)
  
- **Air Quality (VOC) Sensor**
  - Detect contamination or fermentation

**Data Collection**: Every 10 minutes  
**Power**: AC-powered with battery backup  
**Connectivity**: Ethernet/Wi-Fi  
**Cost per Zone**: $200-$400

#### **B. Cold Room Door Sensors**
**Purpose**: Track door open/close events affecting temperature

**Sensors**:
- Magnetic contact switch
- Open duration timer
- Alert if door left open > 5 minutes

**Cost per Door**: $30-$60

#### **C. Smart Shelving System**
**Purpose**: Inventory management with FIFO enforcement

**Sensors**:
- **RFID Reader Array**
  - UHF RFID (865-868 MHz for India)
  - Auto-scan inventory on shelves
  
- **Weight Sensors**
  - Detect inventory changes

**Cost per Shelf**: $150-$300

---

### **4. PROCESSING/MANUFACTURING SENSORS**

#### **A. Drying Chamber Sensors**
**Purpose**: Monitor herb drying process (critical for quality)

**Sensors**:
- **Temperature Array** (multiple points)
  - Ensure uniform drying
  
- **Humidity Sensor**
  - Track moisture removal rate
  
- **Airflow Sensor**
  - CFM (cubic feet per minute) monitoring
  
- **Power Meter**
  - Energy consumption tracking

**Data Collection**: Every 1 minute during drying  
**Connectivity**: Industrial Ethernet (Modbus TCP)  
**Cost per Chamber**: $500-$1000

#### **B. Grinding/Milling Equipment Sensors**
**Purpose**: Process parameter logging

**Sensors**:
- **Vibration Sensor**
  - Predictive maintenance
  
- **Temperature Sensor**
  - Prevent overheating (degrades compounds)
  
- **Particle Size Analyzer** (optional)
  - Laser diffraction sensor
  
- **Load Sensor**
  - Input/output quantity verification

**Connectivity**: OPC UA (industrial protocol)  
**Cost per Machine**: $400-$800

#### **C. Extraction Equipment (for oils/extracts)**
**Purpose**: Monitor extraction parameters

**Sensors**:
- **Pressure Transducer**
  - For CO₂ supercritical extraction
  
- **Temperature Controller**
  - Precise temp control (±0.1°C)
  
- **Flow Meter**
  - Solvent flow rate
  
- **pH Meter** (for water-based extraction)

**Connectivity**: Industrial PLC integration  
**Cost per Unit**: $800-$2000

---

### **5. QUALITY TESTING LAB SENSORS**

#### **A. Automated Lab Equipment Integration**
**Purpose**: Direct data feed from testing instruments to blockchain

**Instruments with IoT Integration**:
- **HPLC (High-Performance Liquid Chromatography)**
  - Alkaloid/compound quantification
  - Protocol: Ethernet/RS-232
  - Model: Waters Alliance HPLC with ChromaFlow IoT
  
- **GC-MS (Gas Chromatography-Mass Spectrometry)**
  - Volatile compound analysis
  
- **UV-Vis Spectrophotometer**
  - Total phenolic content, antioxidant activity
  
- **Moisture Analyzer**
  - Infrared moisture balance
  - Range: 0.01-100%
  - Model: Mettler Toledo HB43-S
  
- **Heavy Metal Analyzer** (ICP-MS)
  - Inductively Coupled Plasma Mass Spectrometry
  
- **Microbial Counter** (Automated)
  - Colony-forming units (CFU) detection

**Integration Method**: LIMS (Laboratory Information Management System) → API → Blockchain  
**Cost per Lab Setup**: $5,000-$15,000 (software integration)

---

## 🏗️ IoT Network Architecture

### **1. Edge Layer (Sensors & Gateways)**

```
┌─────────────────────────────────────────────────────────────┐
│                     FARM LOCATIONS                          │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │Environmental│  │Harvest  │  │Zone     │                 │
│  │Station    │  │Logger   │  │Marker   │                  │
│  └─────┬────┘  └────┬─────┘  └────┬────┘                  │
│        │ LoRaWAN    │ BLE         │ LoRa                    │
│        └────────────┼─────────────┘                         │
│                     │                                        │
│              ┌──────▼──────┐                                │
│              │ LoRa Gateway │ (Solar-powered)               │
│              │ + 4G Modem   │                               │
│              └──────┬───────┘                               │
└─────────────────────┼─────────────────────────────────────┘
                      │ 4G/LTE
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  TRANSPORT LAYER                            │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │Smart     │  │Vehicle   │  │Container │                  │
│  │Container │  │Telematics│  │GPS       │                  │
│  │Tag       │  │          │  │Tracker   │                  │
│  └─────┬────┘  └────┬─────┘  └────┬────┘                  │
│        │ NB-IoT     │ 4G          │ Cat-M1                  │
│        └────────────┼─────────────┘                         │
└─────────────────────┼─────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              FACILITY LAYER (Labs/Processors/Manufacturers) │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │Warehouse │  │Processing│  │Lab       │                  │
│  │Sensors   │  │Equipment │  │Equipment │                  │
│  └─────┬────┘  └────┬─────┘  └────┬────┘                  │
│        │ Wi-Fi/Ethernet   │ Modbus │ LIMS API               │
│        └──────────────────┼────────┘                        │
│                           │                                  │
│                    ┌──────▼──────┐                         │
│                    │ Edge Gateway │                         │
│                    │ (Industrial  │                         │
│                    │  IoT Hub)    │                         │
│                    └──────┬───────┘                         │
└───────────────────────────┼─────────────────────────────────┘
                            │
                            ▼
```

### **2. Fog/Edge Computing Layer**

**Purpose**: Pre-process data, reduce latency, enable offline operation

**Components**:
- **Edge Gateway Devices**
  - Model: Raspberry Pi 4 (8GB) or NVIDIA Jetson Nano
  - Functions:
    - Data aggregation from multiple sensors
    - Local caching (offline resilience)
    - Anomaly detection (AI inference at edge)
    - Data compression/batching
    - Protocol translation (LoRa → MQTT)
  
- **Edge Analytics**
  - TensorFlow Lite models for:
    - Temperature anomaly prediction
    - Quality degradation alerts
    - Predictive maintenance
  
- **Local Blockchain Node** (optional)
  - Hyperledger Fabric peer at major facilities
  - Store IoT data anchors on-chain

**Cost per Gateway**: $200-$500

### **3. Cloud/Platform Layer**

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS IoT STACK (or Azure IoT)             │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ AWS IoT Core (MQTT Broker)                             │ │
│  │ - Device Management (Thing Registry)                   │ │
│  │ - Message Routing (Rules Engine)                       │ │
│  │ - Device Shadows (last known state)                    │ │
│  └───────────────────┬────────────────────────────────────┘ │
│                      │                                       │
│  ┌──────────────────┼────────────────────────────────────┐ │
│  │                  ▼                                      │ │
│  │ AWS IoT Analytics                                      │ │
│  │ - Time-series data storage                             │ │
│  │ - SQL queries on sensor data                           │ │
│  │ - Data visualization                                   │ │
│  └───────────────────┬────────────────────────────────────┘ │
│                      │                                       │
│  ┌──────────────────┼────────────────────────────────────┐ │
│  │                  ▼                                      │ │
│  │ AWS Lambda Functions                                   │ │
│  │ - Data validation                                      │ │
│  │ - Threshold alerts (SNS/Email)                         │ │
│  │ - Blockchain transaction preparation                   │ │
│  └───────────────────┬────────────────────────────────────┘ │
│                      │                                       │
│  ┌──────────────────┼────────────────────────────────────┐ │
│  │                  ▼                                      │ │
│  │ Amazon Timestream (Time-series DB)                     │ │
│  │ - Store all sensor readings                            │ │
│  │ - Retention: Hot storage 7 days, Cold storage 1 year  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              HYPERLEDGER FABRIC NETWORK                     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ IoT Data Anchoring Service (Node.js)                   │ │
│  │ - Batches IoT data (every 15 mins or 1000 records)    │ │
│  │ - Creates Merkle root hash                             │ │
│  │ - Invokes chaincode: RecordIoTDataAnchor()            │ │
│  └───────────────────┬────────────────────────────────────┘ │
│                      │                                       │
│                      ▼                                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ HerbalTrace Chaincode (main.go)                        │ │
│  │ + New Functions:                                       │ │
│  │   - RecordIoTDataAnchor()                              │ │
│  │   - GetIoTDataByBatch()                                │ │
│  │   - QueryIoTAlerts()                                   │ │
│  │   - ValidateColdChainCompliance()                      │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Flow Architecture

### **Example: Cold Chain Monitoring**

```
[Harvest] → [Smart Container Tag Applied]
                ↓
    Every 5 minutes while in transit:
                ↓
    ┌──────────────────────────────┐
    │ Temp: 8.2°C, Humidity: 45%   │
    │ GPS: 28.6139°N, 77.2090°E    │
    │ Timestamp: 2025-11-18 14:35   │
    └──────────┬───────────────────┘
               │ NB-IoT
               ▼
    ┌──────────────────────────────┐
    │ AWS IoT Core (MQTT)          │
    │ Topic: iot/transport/CON-123 │
    └──────────┬───────────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │ Lambda Function              │
    │ - Check: Temp 2-8°C?         │
    │ - If violation: SNS Alert    │
    │ - Store in Timestream        │
    └──────────┬───────────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │ Every 15 minutes:            │
    │ Batch 90 readings            │
    │ Calculate Merkle Root        │
    │ Hash: 0x3a7f8e...            │
    └──────────┬───────────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │ Blockchain Transaction       │
    │ Function: RecordIoTDataAnchor│
    │ Params:                      │
    │  - BatchID: "CON-123-B01"    │
    │  - MerkleRoot: "0x3a7f8e..." │
    │  - SensorType: "TempHumidity"│
    │  - RecordCount: 90           │
    │  - AvgTemp: 7.8°C            │
    │  - MinTemp: 6.5°C            │
    │  - MaxTemp: 9.1°C            │
    │  - Violations: 0             │
    └──────────────────────────────┘
```

### **Why Not Store All IoT Data On-Chain?**

❌ **Avoid**: Storing every sensor reading directly on blockchain  
✅ **Best Practice**: Store aggregated summaries + off-chain data anchors

**Reasons**:
1. **Cost**: Blockchain storage is expensive (thousands of readings/hour)
2. **Performance**: Transaction throughput limitations
3. **Privacy**: Raw sensor data may contain sensitive info
4. **Queryability**: Time-series databases are better for sensor data analytics

**Solution**: **Hybrid Architecture**
- **On-Chain**: Merkle root hashes, summary statistics, alerts, compliance flags
- **Off-Chain**: Full sensor data in AWS Timestream (immutable, queryable)
- **Verification**: Anyone can verify off-chain data matches on-chain hash

---

## 🔧 Smart Contract Extensions (Chaincode)

### **New Data Structures**

```go
// IoTDataAnchor represents batched IoT sensor data anchor
type IoTDataAnchor struct {
    ID            string            `json:"id"`
    Type          string            `json:"type"` // "IoTDataAnchor"
    BatchID       string            `json:"batchId"`
    LinkedEntityID string           `json:"linkedEntityId"` // CollectionEvent, QualityTest, ProcessingStep, or Product ID
    EntityType    string            `json:"entityType"` // "collection", "transport", "storage", "processing"
    SensorType    string            `json:"sensorType"` // "TempHumidity", "GPS", "Environmental", "Equipment"
    StartTime     string            `json:"startTime"`
    EndTime       string            `json:"endTime"`
    RecordCount   int               `json:"recordCount"`
    MerkleRoot    string            `json:"merkleRoot"` // SHA-256 hash of all records
    DataURL       string            `json:"dataUrl"` // S3/IPFS URL for full data
    SummaryStats  map[string]float64 `json:"summaryStats"` // avg, min, max, stddev
    Violations    int               `json:"violations"` // Number of threshold breaches
    Alerts        []IoTAlert        `json:"alerts,omitempty"`
    Timestamp     string            `json:"timestamp"`
}

// IoTAlert represents automated alerts from IoT data
type IoTAlert struct {
    AlertID       string  `json:"alertId"`
    AlertType     string  `json:"alertType"` // "TEMP_VIOLATION", "HUMIDITY_HIGH", "LOCATION_OUTSIDE_ZONE"
    Severity      string  `json:"severity"` // "critical", "warning", "info"
    SensorID      string  `json:"sensorId"`
    Value         float64 `json:"value"`
    Threshold     float64 `json:"threshold"`
    Timestamp     string  `json:"timestamp"`
    Resolution    string  `json:"resolution"` // "auto_resolved", "manual_override", "pending"
    ResolutionTime string `json:"resolutionTime,omitempty"`
}

// ColdChainCompliance represents compliance validation
type ColdChainCompliance struct {
    ID            string  `json:"id"`
    Type          string  `json:"type"` // "ColdChainCompliance"
    BatchID       string  `json:"batchId"`
    TransportID   string  `json:"transportId"`
    Species       string  `json:"species"`
    RequiredTempMin float64 `json:"requiredTempMin"` // °C
    RequiredTempMax float64 `json:"requiredTempMax"` // °C
    RequiredHumidityMin float64 `json:"requiredHumidityMin"` // %
    RequiredHumidityMax float64 `json:"requiredHumidityMax"` // %
    ActualTempMin   float64 `json:"actualTempMin"`
    ActualTempMax   float64 `json:"actualTempMax"`
    ActualHumidityMin float64 `json:"actualHumidityMin"`
    ActualHumidityMax float64 `json:"actualHumidityMax"`
    ComplianceStatus string `json:"complianceStatus"` // "compliant", "violation", "warning"
    ViolationDuration float64 `json:"violationDuration"` // minutes
    QualityImpact   string  `json:"qualityImpact"` // "none", "minor", "major", "critical"
    Timestamp       string  `json:"timestamp"`
}

// EnvironmentalData represents farm environmental conditions
type EnvironmentalData struct {
    ID            string            `json:"id"`
    Type          string            `json:"type"` // "EnvironmentalData"
    FarmerID      string            `json:"farmerId"`
    StationID     string            `json:"stationId"`
    Latitude      float64           `json:"latitude"`
    Longitude     float64           `json:"longitude"`
    DataPeriod    string            `json:"dataPeriod"` // "daily", "weekly", "monthly"
    StartDate     string            `json:"startDate"`
    EndDate       string            `json:"endDate"`
    Metrics       map[string]float64 `json:"metrics"` // soilMoisture, pH, NPK, temp, rainfall, etc.
    MerkleRoot    string            `json:"merkleRoot"`
    DataURL       string            `json:"dataUrl"`
    Timestamp     string            `json:"timestamp"`
}
```

### **New Chaincode Functions**

```go
// RecordIoTDataAnchor stores batched IoT data anchor on blockchain
func (c *HerbalTraceContract) RecordIoTDataAnchor(ctx contractapi.TransactionContextInterface, anchorJSON string) error {
    var anchor IoTDataAnchor
    err := json.Unmarshal([]byte(anchorJSON), &anchor)
    if err != nil {
        return fmt.Errorf("failed to unmarshal anchor: %v", err)
    }

    // Validate linked entity exists
    if anchor.LinkedEntityID != "" {
        if err := c.validateLinkedEntity(ctx, anchor.LinkedEntityID, anchor.EntityType); err != nil {
            return err
        }
    }

    anchorBytes, err := json.Marshal(anchor)
    if err != nil {
        return fmt.Errorf("failed to marshal anchor: %v", err)
    }

    return ctx.GetStub().PutState(anchor.ID, anchorBytes)
}

// GetIoTDataAnchor retrieves IoT data anchor by ID
func (c *HerbalTraceContract) GetIoTDataAnchor(ctx contractapi.TransactionContextInterface, id string) (*IoTDataAnchor, error) {
    anchorBytes, err := ctx.GetStub().GetState(id)
    if err != nil {
        return nil, fmt.Errorf("failed to read anchor: %v", err)
    }
    if anchorBytes == nil {
        return nil, fmt.Errorf("anchor not found: %s", id)
    }

    var anchor IoTDataAnchor
    err = json.Unmarshal(anchorBytes, &anchor)
    if err != nil {
        return nil, fmt.Errorf("failed to unmarshal anchor: %v", err)
    }

    return &anchor, nil
}

// QueryIoTDataByEntity retrieves all IoT anchors for a specific entity
func (c *HerbalTraceContract) QueryIoTDataByEntity(ctx contractapi.TransactionContextInterface, entityID string) ([]*IoTDataAnchor, error) {
    queryString := fmt.Sprintf(`{"selector":{"type":"IoTDataAnchor","linkedEntityId":"%s"}}`, entityID)
    return c.queryIoTAnchors(ctx, queryString)
}

// QueryIoTAlerts retrieves all critical alerts
func (c *HerbalTraceContract) QueryIoTAlerts(ctx contractapi.TransactionContextInterface, severity string) ([]*IoTAlert, error) {
    // Implementation: Query anchors with alerts matching severity
    // ...
}

// ValidateColdChainCompliance checks if transport maintained proper conditions
func (c *HerbalTraceContract) ValidateColdChainCompliance(ctx contractapi.TransactionContextInterface, complianceJSON string) error {
    var compliance ColdChainCompliance
    err := json.Unmarshal([]byte(complianceJSON), &compliance)
    if err != nil {
        return fmt.Errorf("failed to unmarshal compliance: %v", err)
    }

    // Check temperature compliance
    if compliance.ActualTempMin < compliance.RequiredTempMin || compliance.ActualTempMax > compliance.RequiredTempMax {
        compliance.ComplianceStatus = "violation"
        
        // Assess quality impact based on violation severity and duration
        if compliance.ViolationDuration > 60 { // > 1 hour
            compliance.QualityImpact = "critical"
        } else if compliance.ViolationDuration > 30 {
            compliance.QualityImpact = "major"
        } else {
            compliance.QualityImpact = "minor"
        }
    } else {
        compliance.ComplianceStatus = "compliant"
        compliance.QualityImpact = "none"
    }

    complianceBytes, err := json.Marshal(compliance)
    if err != nil {
        return fmt.Errorf("failed to marshal compliance: %v", err)
    }

    return ctx.GetStub().PutState(compliance.ID, complianceBytes)
}

// RecordEnvironmentalData stores farm environmental data
func (c *HerbalTraceContract) RecordEnvironmentalData(ctx contractapi.TransactionContextInterface, dataJSON string) error {
    var data EnvironmentalData
    err := json.Unmarshal([]byte(dataJSON), &data)
    if err != nil {
        return fmt.Errorf("failed to unmarshal data: %v", err)
    }

    dataBytes, err := json.Marshal(data)
    if err != nil {
        return fmt.Errorf("failed to marshal data: %v", err)
    }

    return ctx.GetStub().PutState(data.ID, dataBytes)
}
```

---

## 📱 Application Integration

### **1. Farmer Mobile App Enhancements**

**New Features**:
- **IoT Dashboard Screen**
  - Real-time view of farm environmental station data
  - Soil moisture graphs (7-day trends)
  - Weather forecast integration
  - Irrigation recommendations based on soil moisture
  
- **Harvest Logger Pairing**
  - Bluetooth pairing with portable harvest logger
  - Auto-fill harvest quantity from load cell
  - GPS coordinates auto-populated
  
- **Alert Notifications**
  - Push notifications for:
    - Soil moisture too low (irrigation needed)
    - Adverse weather warnings
    - Geo-fence violations
    - Conservation zone alerts

**Implementation**:
```dart
// New screen: IoTDashboardScreen.dart
class IoTDashboardScreen extends StatefulWidget {
  @override
  _IoTDashboardScreenState createState() => _IoTDashboardScreenState();
}

class _IoTDashboardScreenState extends State<IoTDashboardScreen> {
  Map<String, dynamic>? environmentalData;
  
  @override
  void initState() {
    super.initState();
    fetchEnvironmentalData();
    startRealtimeUpdates();
  }
  
  Future<void> fetchEnvironmentalData() async {
    // Call backend API: GET /api/iot/environmental/{farmerId}
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/iot/environmental/${farmerID}')
    );
    setState(() {
      environmentalData = json.decode(response.body);
    });
  }
  
  void startRealtimeUpdates() {
    // WebSocket or Server-Sent Events for live data
    final channel = IOWebSocketChannel.connect('wss://api.herbaltrace.com/iot/live');
    channel.stream.listen((message) {
      setState(() {
        environmentalData = json.decode(message);
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Farm Sensors')),
      body: environmentalData == null
          ? CircularProgressIndicator()
          : ListView(
              children: [
                SensorCard(
                  title: 'Soil Moisture',
                  value: '${environmentalData!['soilMoisture']}%',
                  icon: Icons.water_drop,
                  status: environmentalData!['soilMoisture'] > 30 
                      ? 'Good' : 'Low - Irrigate Soon',
                ),
                SensorCard(
                  title: 'Temperature',
                  value: '${environmentalData!['temperature']}°C',
                  icon: Icons.thermostat,
                ),
                SensorCard(
                  title: 'Soil pH',
                  value: '${environmentalData!['ph']}',
                  icon: Icons.science,
                ),
                // Line chart showing 7-day trends
                EnvironmentalChart(data: environmentalData!['history']),
              ],
            ),
    );
  }
}
```

### **2. Web Portal Enhancements**

**New Dashboards**:

#### **A. IoT Monitoring Dashboard** (All Roles)
- Real-time map showing all IoT devices
- Color-coded alerts (green/yellow/red)
- Filter by sensor type, location, status
- Historical data playback (time slider)

#### **B. Cold Chain Dashboard** (Lab/Processor/Manufacturer)
- Table of in-transit shipments
- Columns: Batch ID, Origin, Destination, Current Temp, Status, ETA
- Click to view temperature graph
- Export cold chain compliance certificate

#### **C. Quality Prediction Dashboard** (Lab)
- AI-powered quality forecasts based on:
  - Environmental conditions during growth
  - Post-harvest handling (temp excursions)
  - Storage duration
- Recommend priority testing for at-risk batches

**Implementation Example**:
```typescript
// New component: ColdChainMonitor.tsx
import React, { useState, useEffect } from 'react';
import { Line } from 'react-chartjs-2';
import axios from 'axios';

interface ColdChainData {
  batchId: string;
  containerTag: string;
  currentTemp: number;
  currentHumidity: number;
  gpsLocation: { lat: number; lng: number };
  status: 'compliant' | 'warning' | 'violation';
  history: Array<{ timestamp: string; temp: number; humidity: number }>;
}

export const ColdChainMonitor: React.FC = () => {
  const [shipments, setShipments] = useState<ColdChainData[]>([]);

  useEffect(() => {
    const fetchShipments = async () => {
      const response = await axios.get('/api/iot/cold-chain/active');
      setShipments(response.data);
    };

    fetchShipments();
    const interval = setInterval(fetchShipments, 30000); // Update every 30s
    return () => clearInterval(interval);
  }, []);

  return (
    <div>
      <h2>Active Cold Chain Shipments</h2>
      <table>
        <thead>
          <tr>
            <th>Batch ID</th>
            <th>Container</th>
            <th>Current Temp</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {shipments.map((shipment) => (
            <tr key={shipment.batchId} 
                style={{ 
                  backgroundColor: 
                    shipment.status === 'violation' ? '#ffebee' :
                    shipment.status === 'warning' ? '#fff8e1' : '#e8f5e9'
                }}>
              <td>{shipment.batchId}</td>
              <td>{shipment.containerTag}</td>
              <td>{shipment.currentTemp}°C</td>
              <td>{shipment.status.toUpperCase()}</td>
              <td>
                <button onClick={() => viewDetails(shipment.batchId)}>
                  View Graph
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
```

---

## 🤖 AI/ML Integration

### **1. Predictive Models**

#### **A. Quality Degradation Prediction**
**Model**: Random Forest Regression  
**Input Features**:
- Environmental data during growth (soil moisture, pH, NPK, weather)
- Post-harvest handling (time to cooling, temp excursions)
- Storage conditions (temp, humidity, duration)
- Species-specific decay rates

**Output**: Predicted quality score (0-100) at time T

**Deployment**: TensorFlow Lite on edge gateways

#### **B. Anomaly Detection**
**Model**: Isolation Forest / Autoencoder  
**Purpose**: Detect sensor malfunctions or tampering

**Example**: If temperature suddenly jumps from 8°C to 35°C in 1 minute, flag as sensor error (not actual violation)

#### **C. Yield Forecasting**
**Model**: LSTM (Long Short-Term Memory)  
**Input**: Time-series environmental data + historical yield data  
**Output**: Predicted harvest quantity for next season

### **2. AI-Powered Alerts**

**Smart Alert Routing**:
```yaml
Alert Type: TEMP_VIOLATION
Severity: Critical
Conditions:
  - Temperature > 10°C for > 30 minutes
  - Batch contains: Endangered species
Actions:
  - SMS to Farmer: "Urgent: Shipment CON-123 temp high. Check container!"
  - Email to Processor: "Batch at risk, priority quality test recommended"
  - Blockchain: Record violation with "critical" flag
  - Dashboard: Red alert banner
```

---

## 🔐 Security & Privacy

### **1. Device Security**
- **TLS 1.3**: All IoT device → cloud communication encrypted
- **X.509 Certificates**: Each device has unique certificate (auto-rotation every 90 days)
- **Secure Boot**: Prevent firmware tampering
- **OTA Updates**: Over-the-air security patches

### **2. Data Privacy**
- **PII Protection**: Farmer names/contact info encrypted at rest
- **Data Anonymization**: Research datasets use hashed IDs
- **Access Control**: Role-based permissions (farmers see only their data)

### **3. Anti-Tampering**
- **Tamper-Evident Seals**: Physical + RFID seals on containers
- **Sensor Integrity Checks**: Cryptographic signing of sensor data
- **Anomaly Detection**: AI flags suspicious data patterns

---

## 💰 Cost Breakdown & ROI

### **Sensor Investment (Per Farm - 5 hectares)**

| Item | Quantity | Unit Cost | Total |
|------|----------|-----------|-------|
| Environmental Station | 1 | $600 | $600 |
| Harvest Logger (Portable) | 2 | $120 | $240 |
| Zone Markers | 4 | $75 | $300 |
| **Total Farm Investment** | | | **$1,140** |

### **Transport (Per Vehicle)**

| Item | Quantity | Unit Cost | Total |
|------|----------|-----------|-------|
| Smart Container Tags | 20 | $60 | $1,200 |
| Vehicle Telematics | 1 | $250 | $250 |
| **Total Transport Investment** | | | **$1,450** |

### **Storage Facility (Medium-sized warehouse)**

| Item | Quantity | Unit Cost | Total |
|------|----------|-----------|-------|
| Warehouse Sensors | 10 zones | $300 | $3,000 |
| Cold Room Door Sensors | 4 | $45 | $180 |
| Smart Shelving | 5 | $200 | $1,000 |
| **Total Storage Investment** | | | **$4,180** |

### **ROI Analysis**

**Annual Savings/Benefits** (Per Facility):
- **Reduced Spoilage**: 15% reduction in herb waste → $50,000/year savings
- **Quality Compliance**: 30% fewer failed quality tests → $30,000/year savings
- **Insurance Discounts**: 10% premium reduction → $15,000/year
- **Regulatory Efficiency**: 50% faster audit preparation → $20,000/year labor savings
- **Premium Pricing**: Blockchain+IoT traceability → 10% price premium → $80,000/year

**Total Annual Benefit**: ~$195,000  
**Total Investment**: ~$6,770 (farm + transport + storage)  
**Payback Period**: **~1.2 months** 🎯

---

## 🚀 Phased Implementation Roadmap

### **Phase 1: Pilot (Months 1-3)**
- Deploy 10 environmental stations at select farms
- Equip 5 transport vehicles with cold chain sensors
- Install warehouse monitoring at 1 processing facility
- Integrate with existing blockchain network
- **Goal**: Prove concept, collect baseline data

### **Phase 2: Scale-Up (Months 4-8)**
- Expand to 100 farms
- Deploy transport sensors across entire fleet
- Add lab equipment integration
- Launch farmer mobile app IoT dashboard
- **Goal**: Achieve critical mass, refine AI models

### **Phase 3: Full Deployment (Months 9-12)**
- Coverage for all network participants
- Consumer-facing IoT data in QR scan results
- AI-powered quality predictions operational
- Automated compliance reporting
- **Goal**: Complete ecosystem integration

### **Phase 4: Advanced Features (Year 2+)**
- Drone-based monitoring
- Satellite imagery integration
- Blockchain-based carbon credit trading (based on IoT sustainability data)
- International export corridor monitoring
- **Goal**: Industry leadership, new revenue streams

---

## 📋 Technical Standards & Protocols

### **Communication Protocols**
- **MQTT 5.0**: Primary IoT messaging protocol
- **CoAP**: Lightweight alternative for constrained devices
- **LoRaWAN 1.1**: Long-range wireless (farm sensors)
- **NB-IoT/LTE Cat-M1**: Cellular for mobile sensors
- **Modbus TCP**: Industrial equipment integration
- **OPC UA**: Processing equipment (standard for Industry 4.0)

### **Data Formats**
- **JSON**: Application-level data exchange
- **Protocol Buffers**: Efficient binary serialization (edge devices)
- **SenML (Sensor Markup Language)**: IoT sensor data standard

### **Cloud Standards**
- **AWS IoT Core**: MQTT broker + device management
- **Azure IoT Hub**: Alternative for Azure deployments
- **ThingsBoard**: Open-source IoT platform (for on-premise)

---

## 🎓 Training & Change Management

### **For Farmers**
- 2-day workshop: IoT sensor basics, mobile app usage
- Laminated quick-reference cards (bilingual)
- 24/7 helpline for troubleshooting
- Community champion program (tech-savvy farmers as mentors)

### **For Technicians**
- 5-day training: Sensor installation, maintenance, troubleshooting
- Certification program
- Spare parts inventory management

### **For Lab/Processor/Manufacturer Staff**
- 1-day workshop: IoT dashboard, alerts, compliance reporting
- Integration with existing LIMS/ERP systems
- Best practices for IoT-driven decision making

---

## 🔬 Research Opportunities

### **Academic Partnerships**
- **IIT/IISc**: AI model development for quality prediction
- **Agricultural Universities**: Optimal growing conditions research
- **CSIR-IIIM Jammu**: Medicinal plant conservation studies

### **Data-Driven Insights**
- Correlation between environmental factors and active compound levels
- Climate change impact on herb quality/yield
- Optimal harvest timing models
- Sustainable harvesting thresholds

---

## 📊 Success Metrics (KPIs)

### **Technical KPIs**
- **Sensor Uptime**: >99.5%
- **Data Latency**: <30 seconds (farm to cloud)
- **False Alert Rate**: <5%
- **Blockchain Anchor Success Rate**: >99.9%

### **Business KPIs**
- **Cold Chain Compliance**: >95% of shipments meet temp requirements
- **Spoilage Reduction**: 15% decrease year-over-year
- **Quality Test Pass Rate**: 10% improvement
- **Farmer Adoption**: 80% of network farmers using IoT within 18 months

### **Sustainability KPIs**
- **Conservation Zone Compliance**: 100% of harvests geo-validated
- **Endangered Species Protection**: Zero illegal harvests detected
- **Carbon Footprint Tracking**: 100% of shipments with emissions data
- **Organic Compliance**: 95% of certified organic farms have verified pesticide-free data

---

This comprehensive IoT integration will transform HerbalTrace from a blockchain traceability system into a **smart, predictive, and autonomous supply chain ecosystem**! 🌿📡🔗