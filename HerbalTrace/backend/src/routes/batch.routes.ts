import express, { Request, Response } from 'express';
import Database from 'better-sqlite3';
import { authenticate } from '../middleware/auth';
import BatchService from '../services/BatchService';
import { logger } from '../utils/logger';
import { db } from '../config/database';

const router = express.Router();

/**
 * Batch Routes - Manage batch creation, assignment, and tracking
 * 
 * Endpoints:
 * 1. POST /api/v1/batches - Create new batch (Admin only)
 * 2. GET /api/v1/batches - List all batches with filters (Admin, Processor)
 * 3. GET /api/v1/batches/statistics - Get batch statistics (Admin only)
 * 4. GET /api/v1/batches/smart-groups - Find smart grouping suggestions (Admin only)
 * 5. GET /api/v1/batches/:id - Get single batch details
 * 6. PUT /api/v1/batches/:id/assign - Assign processor to batch (Admin only)
 * 7. PUT /api/v1/batches/:id/status - Update batch status (Admin, Processor)
 * 8. GET /api/v1/batches/processor/:username - Get processor's batches (Processor, Admin)
 */

interface AuthRequest extends Request {
  user?: {
    username: string;
    role: string;
    fullName: string;
  };
}

/**
 * POST /api/v1/batches
 * Create a new batch from collection IDs
 * 
 * Access: Admin only
 * 
 * Body:
 * {
 *   species: string (required)
 *   collectionIds: number[] (required)
 *   assignedTo?: string (processor username)
 *   notes?: string
 * }
 */
router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    // Authorization: Admin only
    if (req.user?.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only administrators can create batches',
      });
    }

    const { species, collectionIds, assignedTo, notes } = req.body;

    // Validation
    if (!species || !collectionIds || !Array.isArray(collectionIds) || collectionIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'species and collectionIds (array) are required',
      });
    }

    const batch = BatchService.createBatch(
      db,
      { species, collectionIds, assignedTo, notes },
      req.user!.username,
      req.user!.fullName
    );

    logger.info(`Batch created: ${batch.batch_number} by ${req.user!.username}`);

    res.status(201).json({
      success: true,
      message: 'Batch created successfully',
      data: batch,
    });
  } catch (error: any) {
    logger.error('Create batch error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to create batch',
    });
  }
});

/**
 * GET /api/v1/batches
 * List batches with filters
 * 
 * Access: Admin (all batches), Processor (assigned batches only)
 * 
 * Query params:
 * - species?: string
 * - status?: string
 * - assignedTo?: string
 * - createdBy?: string
 * - limit?: number (default 50)
 * - offset?: number (default 0)
 */
router.get('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { species, status, assignedTo, createdBy, limit, offset } = req.query;

    // Authorization: Processors can only see their assigned batches
    let filters: any = {
      species: species as string,
      status: status as string,
      assignedTo: assignedTo as string,
      createdBy: createdBy as string,
      limit: limit ? parseInt(limit as string) : 50,
      offset: offset ? parseInt(offset as string) : 0,
    };

    if (req.user?.role === 'Processor') {
      // Override assignedTo to only show this processor's batches
      filters.assignedTo = req.user.username;
    }

    const result = BatchService.listBatches(db, filters);

    res.json({
      success: true,
      data: result.batches,
      pagination: {
        total: result.total,
        limit: filters.limit,
        offset: filters.offset,
        hasMore: filters.offset + result.batches.length < result.total,
      },
    });
  } catch (error: any) {
    logger.error('List batches error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to list batches',
    });
  }
});

/**
 * GET /api/v1/batches/statistics
 * Get batch statistics
 * 
 * Access: Admin only
 */
router.get('/statistics', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    // Authorization: Admin only
    if (req.user?.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only administrators can view batch statistics',
      });
    }

    const stats = BatchService.getBatchStatistics(db);

    res.json({
      success: true,
      data: stats,
    });
  } catch (error: any) {
    logger.error('Get batch statistics error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to get batch statistics',
    });
  }
});

/**
 * GET /api/v1/batches/smart-groups
 * Find smart grouping suggestions for unbatched collections
 * 
 * Access: Admin only
 * 
 * Query params:
 * - species?: string
 * - minQuantity?: number (default 50)
 * - maxAge?: number (default 30 days)
 * - locationRadius?: number (default 50 km)
 */
router.get('/smart-groups', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    // Authorization: Admin only
    if (req.user?.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only administrators can view smart grouping suggestions',
      });
    }

    const { species, minQuantity, maxAge, locationRadius } = req.query;

    const groups = BatchService.findCollectionsForSmartGrouping(db, {
      species: species as string,
      minQuantity: minQuantity ? parseInt(minQuantity as string) : 50,
      maxAge: maxAge ? parseInt(maxAge as string) : 30,
      locationRadius: locationRadius ? parseInt(locationRadius as string) : 50,
    });

    // Format response
    const suggestions = groups.map((group, index) => ({
      groupId: index + 1,
      species: group[0].species,
      collectionIds: group.map((c) => c.id),
      collectionCount: group.length,
      totalQuantity: group.reduce((sum, c) => sum + c.quantity, 0),
      unit: group[0].unit,
      dateRange: {
        earliest: group[group.length - 1].harvest_date,
        latest: group[0].harvest_date,
      },
      farmers: [...new Set(group.map((c) => c.farmer_name))],
      centerLocation: {
        latitude: group.reduce((sum, c) => sum + c.latitude, 0) / group.length,
        longitude: group.reduce((sum, c) => sum + c.longitude, 0) / group.length,
      },
    }));

    res.json({
      success: true,
      message: `Found ${suggestions.length} smart grouping suggestions`,
      data: suggestions,
    });
  } catch (error: any) {
    logger.error('Smart grouping error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to find smart groups',
    });
  }
});

/**
 * GET /api/v1/batches/:id
 * Get single batch details with collections
 * 
 * Access: Admin (all batches), Processor (assigned batches only)
 */
router.get('/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const batchId = parseInt(req.params.id);

    if (isNaN(batchId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid batch ID',
      });
    }

    const batch = BatchService.getBatchById(db, batchId);

    // Authorization: Processors can only see their assigned batches
    if (req.user?.role === 'Processor' && batch.assigned_to !== req.user.username) {
      return res.status(403).json({
        success: false,
        message: 'You can only view batches assigned to you',
      });
    }

    res.json({
      success: true,
      data: batch,
    });
  } catch (error: any) {
    logger.error('Get batch error:', error);
    if (error.message === 'Batch not found') {
      return res.status(404).json({
        success: false,
        message: 'Batch not found',
      });
    }
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to get batch',
    });
  }
});

/**
 * PUT /api/v1/batches/:id/assign
 * Assign processor to batch
 * 
 * Access: Admin only
 * 
 * Body:
 * {
 *   processorUsername: string (required)
 * }
 */
router.put('/:id/assign', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    // Authorization: Admin only
    if (req.user?.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only administrators can assign processors',
      });
    }

    const batchId = parseInt(req.params.id);
    const { processorUsername } = req.body;

    if (isNaN(batchId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid batch ID',
      });
    }

    if (!processorUsername) {
      return res.status(400).json({
        success: false,
        message: 'processorUsername is required',
      });
    }

    const batch = BatchService.assignProcessor(db, batchId, processorUsername);

    logger.info(`Batch ${batchId} assigned to processor ${processorUsername} by ${req.user!.username}`);

    res.json({
      success: true,
      message: 'Processor assigned successfully',
      data: batch,
    });
  } catch (error: any) {
    logger.error('Assign processor error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to assign processor',
    });
  }
});

/**
 * PUT /api/v1/batches/:id/status
 * Update batch status
 * 
 * Access: Admin (all status changes), Processor (limited status changes for assigned batches)
 * 
 * Body:
 * {
 *   status: string (required) - created, assigned, in_processing, processing_complete, quality_tested, approved, rejected
 * }
 */
router.put('/:id/status', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const batchId = parseInt(req.params.id);
    const { status } = req.body;

    if (isNaN(batchId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid batch ID',
      });
    }

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'status is required',
      });
    }

    // Get batch to check authorization
    const batch = BatchService.getBatchById(db, batchId);

    // Authorization
    if (req.user?.role === 'Processor') {
      // Processors can only update their assigned batches
      if (batch.assigned_to !== req.user.username) {
        return res.status(403).json({
          success: false,
          message: 'You can only update batches assigned to you',
        });
      }

      // Processors can only update to certain statuses
      const allowedStatuses = ['in_processing', 'processing_complete'];
      if (!allowedStatuses.includes(status)) {
        return res.status(403).json({
          success: false,
          message: `Processors can only update status to: ${allowedStatuses.join(', ')}`,
        });
      }
    }

    const updatedBatch = BatchService.updateBatchStatus(db, batchId, status, req.user!.username);

    logger.info(`Batch ${batchId} status updated to ${status} by ${req.user!.username}`);

    res.json({
      success: true,
      message: 'Batch status updated successfully',
      data: updatedBatch,
    });
  } catch (error: any) {
    logger.error('Update batch status error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to update batch status',
    });
  }
});

/**
 * GET /api/v1/batches/processor/:username
 * Get all batches assigned to a specific processor
 * 
 * Access: Admin (any processor), Processor (own batches only)
 * 
 * Query params:
 * - status?: string
 */
router.get('/processor/:username', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { username } = req.params;
    const { status } = req.query;

    // Authorization: Processors can only view their own batches
    if (req.user?.role === 'Processor' && req.user.username !== username) {
      return res.status(403).json({
        success: false,
        message: 'You can only view your own batches',
      });
    }

    const result = BatchService.getProcessorBatches(db, username, status as string);

    res.json({
      success: true,
      data: result.batches,
      pagination: {
        total: result.total,
      },
    });
  } catch (error: any) {
    logger.error('Get processor batches error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to get processor batches',
    });
  }
});

export default router;
