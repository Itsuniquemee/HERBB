import Database from 'better-sqlite3';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';
import { db } from '../config/database';

/**
 * BatchService - Manages batch creation and lifecycle
 * 
 * Features:
 * - Smart grouping of collections by species, location, date
 * - Processor assignment logic
 * - Batch status tracking (assigned, in_processing, processing_complete, quality_tested, approved, rejected)
 * - Batch notifications
 */

interface CollectionForBatch {
  id: number;
  farmer_id: string;
  farmer_name: string;
  species: string;
  quantity: number;
  unit: string;
  latitude: number;
  longitude: number;
  harvest_date: string;
  created_at: string;
}

interface BatchCreationParams {
  species: string;
  collectionIds: number[];
  dateRange?: { start: string; end: string };
  locationRadius?: number; // km
  assignedTo?: string; // processor username
  notes?: string;
}

interface Batch {
  id: number;
  batch_number: string;
  species: string;
  total_quantity: number;
  unit: string;
  collection_count: number;
  status: string;
  assigned_to?: string;
  assigned_to_name?: string;
  created_by: string;
  created_by_name: string;
  notes?: string;
  created_at: string;
  updated_at: string;
  collections?: CollectionForBatch[];
}

interface SmartGroupingParams {
  species?: string;
  minQuantity?: number; // Minimum total kg to create a batch
  maxAge?: number; // Maximum age of collections in days
  locationRadius?: number; // Group collections within X km
  autoAssign?: boolean; // Auto-assign to available processors
}

class BatchService {
  /**
   * Calculate distance between two GPS coordinates using Haversine formula
   */
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth's radius in km
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(degrees: number): number {
    return (degrees * Math.PI) / 180;
  }

  /**
   * Generate unique batch number
   * Format: BATCH-SPECIES-YYYYMMDD-XXXX
   */
  generateBatchNumber(species: string): string {
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
    const random = Math.floor(1000 + Math.random() * 9000);
    return `BATCH-${species.toUpperCase()}-${dateStr}-${random}`;
  }

  /**
   * Smart grouping: Find collections that should be batched together
   * Groups by species, proximity, and date range
   */
  findCollectionsForSmartGrouping(db: Database.Database, params: SmartGroupingParams): CollectionForBatch[][] {
    const { species, minQuantity = 50, maxAge = 30, locationRadius = 50 } = params;

    // Get pending collections (synced to blockchain, not yet in a batch)
    let query = `
      SELECT c.*, u.full_name as farmer_name
      FROM collection_events_cache c
      LEFT JOIN users u ON c.farmer_id = u.username
      WHERE c.sync_status = 'synced'
        AND c.id NOT IN (SELECT collection_id FROM batch_collections)
        AND julianday('now') - julianday(c.harvest_date) <= ?
    `;
    const queryParams: any[] = [maxAge];

    if (species) {
      query += ` AND c.species = ?`;
      queryParams.push(species);
    }

    query += ` ORDER BY c.species, c.harvest_date DESC`;

    const stmt = db.prepare(query);
    const collections = stmt.all(...queryParams) as CollectionForBatch[];

    logger.info(`Found ${collections.length} pending collections for grouping`);

    // Group collections by species first
    const speciesGroups = new Map<string, CollectionForBatch[]>();
    collections.forEach((col) => {
      if (!speciesGroups.has(col.species)) {
        speciesGroups.set(col.species, []);
      }
      speciesGroups.get(col.species)!.push(col);
    });

    // For each species, create location-based groups
    const batches: CollectionForBatch[][] = [];

    speciesGroups.forEach((speciesCollections, speciesName) => {
      const locationGroups: CollectionForBatch[][] = [];
      const processed = new Set<number>();

      speciesCollections.forEach((collection) => {
        if (processed.has(collection.id)) return;

        // Start a new location group
        const group: CollectionForBatch[] = [collection];
        processed.add(collection.id);

        // Find nearby collections
        speciesCollections.forEach((other) => {
          if (processed.has(other.id)) return;

          const distance = this.calculateDistance(
            collection.latitude,
            collection.longitude,
            other.latitude,
            other.longitude
          );

          if (distance <= locationRadius) {
            group.push(other);
            processed.add(other.id);
          }
        });

        // Only create batch if meets minimum quantity
        const totalQuantity = group.reduce((sum, c) => sum + c.quantity, 0);
        if (totalQuantity >= minQuantity) {
          locationGroups.push(group);
        }
      });

      batches.push(...locationGroups);
    });

    logger.info(`Created ${batches.length} smart groups`);
    return batches;
  }

  /**
   * Create a batch from collection IDs
   */
  createBatch(
    db: Database.Database,
    params: BatchCreationParams,
    createdBy: string,
    createdByName: string
  ): Batch {
    const { species, collectionIds, assignedTo, notes } = params;

    // Validate collections exist and are synced
    const placeholders = collectionIds.map(() => '?').join(',');
    const collectionsQuery = `
      SELECT c.*, u.full_name as farmer_name
      FROM collection_events_cache c
      LEFT JOIN users u ON c.farmer_id = u.username
      WHERE c.id IN (${placeholders})
        AND c.sync_status = 'synced'
        AND c.species = ?
    `;
    const collections = db.prepare(collectionsQuery).all(...collectionIds, species) as CollectionForBatch[];

    if (collections.length === 0) {
      throw new Error('No valid collections found. Collections must be synced and match the species.');
    }

    if (collections.length !== collectionIds.length) {
      throw new Error('Some collection IDs are invalid or do not match the species.');
    }

    // Check if any collection is already in a batch
    const existingBatchQuery = `
      SELECT collection_id FROM batch_collections WHERE collection_id IN (${placeholders})
    `;
    const existing = db.prepare(existingBatchQuery).all(...collectionIds);
    if (existing.length > 0) {
      throw new Error('Some collections are already assigned to a batch.');
    }

    // Calculate totals
    const totalQuantity = collections.reduce((sum, c) => sum + c.quantity, 0);
    const unit = collections[0].unit;

    // Get assigned processor name if provided
    let assignedToName: string | undefined;
    if (assignedTo) {
      const processorQuery = db.prepare('SELECT full_name FROM users WHERE username = ? AND role = ?');
      const processor = processorQuery.get(assignedTo, 'Processor') as { full_name: string } | undefined;
      if (!processor) {
        throw new Error('Invalid processor username');
      }
      assignedToName = processor.full_name;
    }

    // Generate batch number
    const batchNumber = this.generateBatchNumber(species);

    // Create batch in transaction
    const insertBatch = db.transaction(() => {
      // Insert batch
      const batchInsert = db.prepare(`
        INSERT INTO batches (
          batch_number, species, total_quantity, unit, collection_count,
          status, assigned_to, assigned_to_name, created_by, created_by_name, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);

      const result = batchInsert.run(
        batchNumber,
        species,
        totalQuantity,
        unit,
        collections.length,
        assignedTo ? 'assigned' : 'created',
        assignedTo || null,
        assignedToName || null,
        createdBy,
        createdByName,
        notes || null
      );

      const batchId = result.lastInsertRowid as number;

      // Insert batch-collection mappings
      const mappingInsert = db.prepare(`
        INSERT INTO batch_collections (batch_id, collection_id) VALUES (?, ?)
      `);

      collectionIds.forEach((collectionId) => {
        mappingInsert.run(batchId, collectionId);
      });

      // Create notification if assigned
      if (assignedTo) {
        const alertInsert = db.prepare(`
          INSERT INTO alerts (
            alert_type, severity, entity_type, entity_id,
            title, message, details, status, assigned_to
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `);

        alertInsert.run(
          'BATCH_ASSIGNED',
          'INFO',
          'batch',
          batchId,
          'New Batch Assigned',
          `Batch ${batchNumber} (${species}) has been assigned to you`,
          JSON.stringify({
            batchNumber,
            species,
            totalQuantity,
            unit,
            collectionCount: collections.length,
          }),
          'pending',
          assignedTo
        );

        logger.info(`Created notification for processor ${assignedTo}`);
      }

      return batchId;
    });

    const batchId = insertBatch();

    // Retrieve and return complete batch
    return this.getBatchById(db, batchId);
  }

  /**
   * Get batch by ID with collections
   */
  getBatchById(db: Database.Database, batchId: number): Batch {
    const batchQuery = db.prepare(`
      SELECT * FROM batches WHERE id = ?
    `);
    const batch = batchQuery.get(batchId) as Batch | undefined;

    if (!batch) {
      throw new Error('Batch not found');
    }

    // Get collections
    const collectionsQuery = db.prepare(`
      SELECT c.*, u.full_name as farmer_name
      FROM collection_events_cache c
      LEFT JOIN users u ON c.farmer_id = u.username
      INNER JOIN batch_collections bc ON c.id = bc.collection_id
      WHERE bc.batch_id = ?
    `);
    batch.collections = collectionsQuery.all(batchId) as CollectionForBatch[];

    return batch;
  }

  /**
   * List batches with filters
   */
  listBatches(
    db: Database.Database,
    filters: {
      species?: string;
      status?: string;
      assignedTo?: string;
      createdBy?: string;
      limit?: number;
      offset?: number;
    }
  ): { batches: Batch[]; total: number } {
    const { species, status, assignedTo, createdBy, limit = 50, offset = 0 } = filters;

    let query = 'SELECT * FROM batches WHERE 1=1';
    const params: any[] = [];

    if (species) {
      query += ' AND species = ?';
      params.push(species);
    }

    if (status) {
      query += ' AND status = ?';
      params.push(status);
    }

    if (assignedTo) {
      query += ' AND assigned_to = ?';
      params.push(assignedTo);
    }

    if (createdBy) {
      query += ' AND created_by = ?';
      params.push(createdBy);
    }

    // Get total count
    const countQuery = query.replace('SELECT *', 'SELECT COUNT(*) as count');
    const countResult = db.prepare(countQuery).get(...params) as { count: number };
    const total = countResult.count;

    // Get paginated results
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const batches = db.prepare(query).all(...params) as Batch[];

    return { batches, total };
  }

  /**
   * Assign processor to batch
   */
  assignProcessor(db: Database.Database, batchId: number, processorUsername: string): Batch {
    // Validate processor exists
    const processorQuery = db.prepare('SELECT full_name FROM users WHERE username = ? AND role = ?');
    const processor = processorQuery.get(processorUsername, 'Processor') as { full_name: string } | undefined;

    if (!processor) {
      throw new Error('Invalid processor username or user is not a Processor');
    }

    // Get batch details
    const batch = this.getBatchById(db, batchId);

    if (batch.status !== 'created' && batch.status !== 'assigned') {
      throw new Error(`Cannot assign processor to batch in status: ${batch.status}`);
    }

    // Update batch
    const updateStmt = db.prepare(`
      UPDATE batches
      SET assigned_to = ?, assigned_to_name = ?, status = 'assigned', updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `);
    updateStmt.run(processorUsername, processor.full_name, batchId);

    // Create notification
    const alertInsert = db.prepare(`
      INSERT INTO alerts (
        alert_type, severity, entity_type, entity_id,
        title, message, details, status, assigned_to
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    alertInsert.run(
      'BATCH_ASSIGNED',
      'INFO',
      'batch',
      batchId,
      'New Batch Assigned',
      `Batch ${batch.batch_number} (${batch.species}) has been assigned to you`,
      JSON.stringify({
        batchNumber: batch.batch_number,
        species: batch.species,
        totalQuantity: batch.total_quantity,
        unit: batch.unit,
        collectionCount: batch.collection_count,
      }),
      'pending',
      processorUsername
    );

    logger.info(`Assigned batch ${batchId} to processor ${processorUsername}`);

    return this.getBatchById(db, batchId);
  }

  /**
   * Update batch status
   */
  updateBatchStatus(db: Database.Database, batchId: number, newStatus: string, updatedBy: string): Batch {
    const validStatuses = [
      'created',
      'assigned',
      'in_processing',
      'processing_complete',
      'quality_tested',
      'approved',
      'rejected',
    ];

    if (!validStatuses.includes(newStatus)) {
      throw new Error(`Invalid status: ${newStatus}`);
    }

    // Get current batch
    const batch = this.getBatchById(db, batchId);

    // Status transition validation
    const validTransitions: { [key: string]: string[] } = {
      created: ['assigned', 'rejected'],
      assigned: ['in_processing', 'rejected'],
      in_processing: ['processing_complete', 'rejected'],
      processing_complete: ['quality_tested', 'rejected'],
      quality_tested: ['approved', 'rejected'],
      approved: [], // Terminal state
      rejected: [], // Terminal state
    };

    if (!validTransitions[batch.status].includes(newStatus)) {
      throw new Error(`Invalid status transition from ${batch.status} to ${newStatus}`);
    }

    // Update status
    const updateStmt = db.prepare(`
      UPDATE batches SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?
    `);
    updateStmt.run(newStatus, batchId);

    // Create notification if batch has assigned processor
    if (batch.assigned_to) {
      const alertInsert = db.prepare(`
        INSERT INTO alerts (
          alert_type, severity, entity_type, entity_id,
          title, message, details, status, assigned_to
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);

      alertInsert.run(
        'BATCH_STATUS_UPDATED',
        newStatus === 'rejected' ? 'WARNING' : 'INFO',
        'batch',
        batchId,
        'Batch Status Updated',
        `Batch ${batch.batch_number} status changed to ${newStatus}`,
        JSON.stringify({
          batchNumber: batch.batch_number,
          species: batch.species,
          oldStatus: batch.status,
          newStatus,
          updatedBy,
        }),
        'pending',
        batch.assigned_to
      );
    }

    logger.info(`Updated batch ${batchId} status from ${batch.status} to ${newStatus}`);

    return this.getBatchById(db, batchId);
  }

  /**
   * Get batches by processor (for processor dashboard)
   */
  getProcessorBatches(
    db: Database.Database,
    processorUsername: string,
    status?: string
  ): { batches: Batch[]; total: number } {
    return this.listBatches(db, {
      assignedTo: processorUsername,
      status,
      limit: 100,
      offset: 0,
    });
  }

  /**
   * Get batch statistics
   */
  getBatchStatistics(db: Database.Database): any {
    const stats = {
      totalBatches: 0,
      byStatus: {} as { [key: string]: number },
      bySpecies: {} as { [key: string]: number },
      totalQuantity: 0,
    };

    // Total batches
    const totalQuery = db.prepare('SELECT COUNT(*) as count FROM batches');
    stats.totalBatches = (totalQuery.get() as { count: number }).count;

    // By status
    const statusQuery = db.prepare('SELECT status, COUNT(*) as count FROM batches GROUP BY status');
    const statusResults = statusQuery.all() as { status: string; count: number }[];
    statusResults.forEach((row) => {
      stats.byStatus[row.status] = row.count;
    });

    // By species
    const speciesQuery = db.prepare('SELECT species, COUNT(*) as count FROM batches GROUP BY species');
    const speciesResults = speciesQuery.all() as { species: string; count: number }[];
    speciesResults.forEach((row) => {
      stats.bySpecies[row.species] = row.count;
    });

    // Total quantity
    const quantityQuery = db.prepare('SELECT SUM(total_quantity) as total FROM batches');
    const quantityResult = quantityQuery.get() as { total: number | null };
    stats.totalQuantity = quantityResult.total || 0;

    return stats;
  }
}

export default new BatchService();

