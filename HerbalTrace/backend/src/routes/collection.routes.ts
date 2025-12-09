import { Router, Request, Response, NextFunction } from 'express';
import { getFabricClient } from '../fabric/fabricClient';
import { authenticate } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';
import { db } from '../config/database-adapter';
import validationService from '../services/ValidationService';
import imageUploadService from '../services/ImageUploadService';

const router = Router();

/**
 * @route   GET /api/collections
 * @desc    Get all collection events (with optional filters)
 * @access  Private
 */
router.get('/', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { species, syncStatus, startDate, endDate, limit = 100, offset = 0 } = req.query;
    const user = (req as any).user;

    let query = 'SELECT * FROM collection_events_cache WHERE 1=1';
    const params: any[] = [];

    // Farmers can only see their own collections
    if (user.role === 'Farmer') {
      query += ' AND farmer_id = ?';
      params.push(user.userId);
    }

    if (species) {
      query += ' AND species = ?';
      params.push(species);
    }

    if (syncStatus) {
      query += ' AND sync_status = ?';
      params.push(syncStatus);
    }

    if (startDate) {
      query += ' AND harvest_date >= ?';
      params.push(startDate);
    }

    if (endDate) {
      query += ' AND harvest_date <= ?';
      params.push(endDate);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));

    const collections = await db.prepare(query).allAsync(...params);

    // Parse JSON data
    const parsedCollections = collections.map((row: any) => ({
      ...JSON.parse(row.data_json),
      syncStatus: row.sync_status,
      blockchainTxId: row.blockchain_tx_id,
      createdAt: row.created_at,
      syncedAt: row.synced_at
    }));

    res.status(200).json({
      success: true,
      count: parsedCollections.length,
      data: parsedCollections
    });
  } catch (error: any) {
    logger.error('Error querying all collections:', error);
    next(error);
  }
});

/**
 * @route   POST /api/collections
 * @desc    Create a new collection event with full validation
 * @access  Private (Farmers only)
 */
router.post('/', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const {
      species,
      commonName,
      scientificName,
      quantity,
      unit,
      latitude,
      longitude,
      altitude,
      accuracy,
      harvestDate,
      harvestMethod,
      partCollected,
      weatherConditions,
      soilType,
      images,
      conservationStatus,
      certificationIds,
      clientTimestamp, // For offline sync
      deviceId // For offline sync
    } = req.body;

    // Validate required fields
    if (!species || !quantity || !latitude || !longitude || !harvestDate) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: species, quantity, latitude, longitude, harvestDate'
      });
    }

    // Get authenticated user
    const user = (req as any).user;
    if (user.role !== 'Farmer' && user.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only farmers can create collection events'
      });
    }

    const farmerId = user.userId;
    const farmerName = user.fullName;

    // Get farmer's location data for zoneName/region
    const farmerData: any = await db.prepare(`
      SELECT location_district, location_state 
      FROM users 
      WHERE user_id = ?
    `).getAsync(farmerId);

    const zoneName = farmerData?.location_district && farmerData?.location_state
      ? `${farmerData.location_district}, ${farmerData.location_state}`
      : 'Unknown';

    // Parse and validate numeric values
    const parsedQuantity = parseFloat(quantity);
    const parsedLatitude = parseFloat(latitude);
    const parsedLongitude = parseFloat(longitude);
    const parsedAltitude = altitude ? parseFloat(altitude) : undefined;
    const parsedAccuracy = accuracy ? parseFloat(accuracy) : undefined;

    if (isNaN(parsedQuantity) || parsedQuantity <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid quantity value'
      });
    }

    // Comprehensive validation
    const validationResult = await validationService.validateCollectionEvent(
      {
        farmerId,
        species,
        quantity: parsedQuantity,
        unit: unit || 'kg',
        latitude: parsedLatitude,
        longitude: parsedLongitude,
        altitude: parsedAltitude,
        accuracy: parsedAccuracy,
        harvestDate
      },
      db
    );

    // If validation fails, create alert and reject
    if (!validationResult.valid) {
      logger.warn(`Collection validation failed for farmer ${farmerId}:`, validationResult.violations);
      
      // Create alert for violations
      await db.prepare(`
        INSERT INTO alerts (
          alert_type, severity, entity_type, entity_id, title, message, details
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      `).runAsync(
        'SEASONAL_WINDOW_VIOLATION', // Or determine type from violations
        'HIGH',
        'collection',
        'pending',
        'Collection Event Validation Failed',
        validationResult.message || 'Validation errors detected',
        JSON.stringify({ violations: validationResult.violations })
      );

      return res.status(400).json({
        success: false,
        message: validationResult.message,
        violations: validationResult.violations,
        warnings: validationResult.warnings
      });
    }

    // Generate collection ID
    const collectionId = `COL-${Date.now()}-${uuidv4().split('-')[0]}`;

    // Prepare collection event data
    // Convert harvestDate (YYYY-MM-DD) to ISO 8601 timestamp format required by chaincode
    const harvestDateISO = new Date(harvestDate + 'T00:00:00Z').toISOString();
    
    // Normalize species name: remove parentheses portion (e.g., "Tulsi (Holy Basil)" -> "Tulsi")
    // This ensures species matches SeasonWindow records in blockchain
    const normalizedSpecies = species.split(' (')[0].trim();
    
    const collectionEvent = {
      id: collectionId,
      type: 'CollectionEvent',
      farmerId,
      farmerName,
      species: normalizedSpecies,
      commonName: commonName || species,
      scientificName,
      quantity: parsedQuantity,
      unit: unit || 'kg',
      latitude: parsedLatitude,
      longitude: parsedLongitude,
      altitude: parsedAltitude,
      accuracy: parsedAccuracy,
      harvestDate: harvestDateISO,
      zoneName, // Region for seasonal validation
      timestamp: new Date().toISOString(),
      harvestMethod: harvestMethod || 'manual',
      partCollected: partCollected || 'whole plant',
      weatherConditions,
      soilType,
      images: images || [],
      conservationStatus,
      certificationIds: certificationIds || [],
      status: 'pending',
      clientTimestamp,
      deviceId
    };

    // Store in local database cache
    await db.prepare(`
      INSERT INTO collection_events_cache (
        id, farmer_id, farmer_name, species, quantity, unit,
        latitude, longitude, altitude, harvest_date, data_json, sync_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).runAsync(
      collectionId,
      farmerId,
      farmerName,
      species,
      parsedQuantity,
      unit || 'kg',
      parsedLatitude,
      parsedLongitude,
      parsedAltitude || null,
      harvestDate,
      JSON.stringify(collectionEvent),
      'pending'
    );

    logger.info(`Collection event cached: ${collectionId} by farmer ${farmerId}`);

    // Attempt blockchain sync (async, non-blocking)
    let blockchainTxId: string | undefined;
    try {
      // Use farmerId (which is the userId) to connect to Fabric
      // The JWT contains userId, and Fabric wallet stores identities by userId
      const fabricClient = getFabricClient();
      await fabricClient.connect(farmerId, user.orgName);
      
      const result = await fabricClient.createCollectionEvent(collectionEvent);
      blockchainTxId = result?.transactionId || `tx-${Date.now()}`;
      
      // Update sync status
      await db.prepare(`
        UPDATE collection_events_cache
        SET sync_status = ?, blockchain_tx_id = ?, synced_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `).runAsync('synced', blockchainTxId, collectionId);
      
      await fabricClient.disconnect();
      logger.info(`Collection synced to blockchain: ${collectionId}, TX: ${blockchainTxId}`);
    } catch (blockchainError: any) {
      logger.error(`Blockchain sync failed for ${collectionId}:`, blockchainError);
      // Store error but don't fail the request
      await db.prepare(`
        UPDATE collection_events_cache
        SET sync_status = ?, error_message = ?
        WHERE id = ?
      `).runAsync('failed', blockchainError.message, collectionId);
    }

    res.status(201).json({
      success: true,
      message: 'Collection event created successfully',
      data: collectionEvent,
      transactionId: blockchainTxId,
      syncStatus: blockchainTxId ? 'synced' : 'pending',
      warnings: validationResult.warnings
    });

  } catch (error: any) {
    logger.error('Error creating collection event:', error);
    next(error);
  }
});

/**
 * @route   GET /api/collections/:id
 * @desc    Get collection event by ID
 * @access  Private
 */
router.get('/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const user = (req as any).user;

    // Try local database first
    const cached: any = await db.prepare(`
      SELECT * FROM collection_events_cache WHERE id = ?
    `).getAsync(id);

    if (cached) {
      const collectionData = JSON.parse(cached.data_json);
      
      // Farmers can only view their own collections
      if (user.role === 'Farmer' && collectionData.farmerId !== user.userId) {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }

      return res.status(200).json({
        success: true,
        data: {
          ...collectionData,
          syncStatus: cached.sync_status,
          blockchainTxId: cached.blockchain_tx_id,
          createdAt: cached.created_at,
          syncedAt: cached.synced_at
        }
      });
    }

    // If not in cache, try blockchain
    try {
      const fabricClient = getFabricClient();
      await fabricClient.connect(user.username, user.orgName);

      const result = await fabricClient.getCollectionEvent(id);
      await fabricClient.disconnect();

      if (!result) {
        return res.status(404).json({
          success: false,
          message: 'Collection event not found'
        });
      }

      res.status(200).json({
        success: true,
        data: result,
        source: 'blockchain'
      });
    } catch (blockchainError: any) {
      logger.error('Blockchain query failed:', blockchainError);
      return res.status(404).json({
        success: false,
        message: 'Collection event not found'
      });
    }
  } catch (error: any) {
    logger.error('Error getting collection event:', error);
    next(error);
  }
});

/**
 * @route   GET /api/collections/farmer/:farmerId
 * @desc    Get all collection events by farmer
 * @access  Private (Farmers can only access own data, Admins can access all)
 */
router.get('/farmer/:farmerId', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { farmerId } = req.params;
    const user = (req as any).user;

    // Access control: Farmers can only view own data
    if (user.role === 'Farmer' && user.userId !== farmerId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You can only view your own collections'
      });
    }

    const collections = db.prepare(`
      SELECT * FROM collection_events_cache
      WHERE farmer_id = ?
      ORDER BY created_at DESC
    `).all(farmerId);

    const parsedCollections = collections.map((row: any) => ({
      ...JSON.parse(row.data_json),
      syncStatus: row.sync_status,
      blockchainTxId: row.blockchain_tx_id,
      createdAt: row.created_at,
      syncedAt: row.synced_at
    }));

    res.status(200).json({
      success: true,
      count: parsedCollections.length,
      data: parsedCollections
    });
  } catch (error: any) {
    logger.error('Error querying collections by farmer:', error);
    next(error);
  }
});

/**
 * @route   GET /api/collections/species/:species
 * @desc    Get all collection events by species
 * @access  Private
 */
router.get('/species/:species', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { species } = req.params;
    const user = (req as any).user;

    let query = 'SELECT * FROM collection_events_cache WHERE species = ?';
    const params: any[] = [species];

    // Farmers can only see their own collections
    if (user.role === 'Farmer') {
      query += ' AND farmer_id = ?';
      params.push(user.userId);
    }

    query += ' ORDER BY created_at DESC';

    const collections = db.prepare(query).all(...params);

    const parsedCollections = collections.map((row: any) => ({
      ...JSON.parse(row.data_json),
      syncStatus: row.sync_status,
      blockchainTxId: row.blockchain_tx_id,
      createdAt: row.created_at,
      syncedAt: row.synced_at
    }));

    res.status(200).json({
      success: true,
      count: parsedCollections.length,
      data: parsedCollections
    });
  } catch (error: any) {
    logger.error('Error querying collections by species:', error);
    next(error);
  }
});

/**
 * @route   GET /api/collections/regulations/species
 * @desc    Get season windows and harvest limits for all species
 * @access  Public (needed for mobile app offline reference)
 */
router.get('/regulations/species', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const speciesInfo = validationService.getAllSpeciesInfo();
    
    res.status(200).json({
      success: true,
      count: speciesInfo.length,
      data: speciesInfo
    });
  } catch (error: any) {
    logger.error('Error getting species regulations:', error);
    next(error);
  }
});

/**
 * @route   GET /api/collections/regulations/species/:species
 * @desc    Get season window and harvest limits for specific species
 * @access  Public
 */
router.get('/regulations/species/:species', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { species } = req.params;
    
    const seasonWindow = validationService.getSeasonWindow(species);
    const harvestLimit = validationService.getHarvestLimit(species);
    
    if (!seasonWindow && !harvestLimit) {
      return res.status(404).json({
        success: false,
        message: `No regulations found for species: ${species}`
      });
    }

    res.status(200).json({
      success: true,
      data: {
        species,
        seasonWindow,
        harvestLimit
      }
    });
  } catch (error: any) {
    logger.error('Error getting species regulations:', error);
    next(error);
  }
});

/**
 * @route   POST /api/collections/sync/retry
 * @desc    Retry failed blockchain syncs
 * @access  Private (Admin only)
 */
router.post('/sync/retry', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = (req as any).user;
    
    if (user.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only admins can retry sync operations'
      });
    }

    const failedCollections = db.prepare(`
      SELECT * FROM collection_events_cache
      WHERE sync_status = 'failed'
      ORDER BY created_at DESC
      LIMIT 50
    `).all();

    const results = [];
    
    for (const row of failedCollections) {
      const collectionData = JSON.parse((row as any).data_json);
      
      try {
        const fabricClient = getFabricClient();
        await fabricClient.connect('admin-HerbalTrace', 'HerbalTrace');
        
        const result = await fabricClient.createCollectionEvent(collectionData);
        const txId = result?.transactionId || `tx-${Date.now()}`;
        
        await db.prepare(`
          UPDATE collection_events_cache
          SET sync_status = ?, blockchain_tx_id = ?, synced_at = CURRENT_TIMESTAMP, error_message = NULL
          WHERE id = ?
        `).runAsync('synced', txId, row.id);
        
        await fabricClient.disconnect();
        
        results.push({ id: (row as any).id, success: true, txId });
        logger.info(`Retry sync successful: ${(row as any).id}`);
      } catch (error: any) {
        results.push({ id: (row as any).id, success: false, error: error.message });
        logger.error(`Retry sync failed: ${(row as any).id}`, error);
      }
    }

    res.status(200).json({
      success: true,
      message: `Processed ${failedCollections.length} failed collections`,
      results
    });
  } catch (error: any) {
    logger.error('Error retrying sync:', error);
    next(error);
  }
});

export default router;
