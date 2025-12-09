/**
 * Farmer Complaints Routes
 * Allows farmers to submit and track complaints
 */

import { Router, Request, Response } from 'express';
import { db } from '../config/database-adapter';
import { logger } from '../utils/logger';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

/**
 * POST /api/v1/complaints
 * Submit a new complaint (Farmer only)
 */
router.post('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    const {
      complaintType,
      subject,
      description,
      priority,
      relatedCollectionId,
      relatedBatchId,
      attachments,
      location,
    } = req.body;

    const user = (req as any).user;

    // Validate required fields
    if (!complaintType || !subject || !description) {
      return res.status(400).json({
        success: false,
        message: 'Complaint type, subject, and description are required',
      });
    }

    // Generate complaint ID
    const complaintId = `CMPL-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`;

    // Get farmer details
    const farmer = await db.prepare(`
      SELECT user_id, full_name, phone, email
      FROM users
      WHERE user_id = ?
    `).getAsync(user.userId);

    if (!farmer) {
      return res.status(404).json({
        success: false,
        message: 'Farmer not found',
      });
    }

    // Insert complaint
    await db.prepare(`
      INSERT INTO farmer_complaints (
        complaint_id, farmer_id, farmer_name, farmer_phone, farmer_email,
        complaint_type, subject, description, priority, status,
        related_collection_id, related_batch_id, attachments, location,
        submitted_by, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'OPEN', ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    `).runAsync(
      complaintId,
      farmer.user_id,
      farmer.full_name,
      farmer.phone,
      farmer.email,
      complaintType,
      subject,
      description,
      priority || 'MEDIUM',
      relatedCollectionId,
      relatedBatchId,
      attachments ? JSON.stringify(attachments) : null,
      location,
      user.userId
    );

    logger.info(`Complaint submitted: ${complaintId} by farmer ${farmer.user_id}`);

    res.status(201).json({
      success: true,
      message: 'Complaint submitted successfully',
      data: {
        complaintId,
        status: 'OPEN',
        submittedAt: new Date().toISOString(),
      },
    });
  } catch (error: any) {
    logger.error('Error submitting complaint:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit complaint',
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/complaints
 * Get all complaints (Admin) or farmer's own complaints (Farmer)
 */
router.get('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { status, type, priority, page = 1, limit = 20 } = req.query;

    const offset = (Number(page) - 1) * Number(limit);

    let query = 'SELECT * FROM farmer_complaints WHERE 1=1';
    const params: any[] = [];

    // If not admin, only show farmer's own complaints
    if (user.role !== 'Admin') {
      query += ' AND farmer_id = ?';
      params.push(user.userId);
    }

    // Apply filters
    if (status) {
      query += ' AND status = ?';
      params.push(status);
    }

    if (type) {
      query += ' AND complaint_type = ?';
      params.push(type);
    }

    if (priority) {
      query += ' AND priority = ?';
      params.push(priority);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), offset);

    const complaints = await db.prepare(query).allAsync(...params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM farmer_complaints WHERE 1=1';
    const countParams: any[] = [];

    if (user.role !== 'Admin') {
      countQuery += ' AND farmer_id = ?';
      countParams.push(user.userId);
    }

    if (status) {
      countQuery += ' AND status = ?';
      countParams.push(status);
    }

    if (type) {
      countQuery += ' AND complaint_type = ?';
      countParams.push(type);
    }

    if (priority) {
      countQuery += ' AND priority = ?';
      countParams.push(priority);
    }

    const countResult = await db.prepare(countQuery).getAsync(...countParams);

    res.json({
      success: true,
      data: complaints,
      pagination: {
        total: countResult.total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(countResult.total / Number(limit)),
      },
    });
  } catch (error: any) {
    logger.error('Error fetching complaints:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch complaints',
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/complaints/:complaintId
 * Get specific complaint details
 */
router.get('/:complaintId', authenticateToken, async (req: Request, res: Response) => {
  try {
    const { complaintId } = req.params;
    const user = (req as any).user;

    const complaint = await db.prepare(`
      SELECT * FROM farmer_complaints WHERE complaint_id = ?
    `).getAsync(complaintId);

    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: 'Complaint not found',
      });
    }

    // Check authorization
    if (user.role !== 'Admin' && complaint.farmer_id !== user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view this complaint',
      });
    }

    res.json({
      success: true,
      data: complaint,
    });
  } catch (error: any) {
    logger.error('Error fetching complaint:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch complaint',
      error: error.message,
    });
  }
});

/**
 * PATCH /api/v1/complaints/:complaintId/status
 * Update complaint status (Admin only)
 */
router.patch('/:complaintId/status', authenticateToken, async (req: Request, res: Response) => {
  try {
    const { complaintId } = req.params;
    const { status, resolutionNotes, assignedTo } = req.body;
    const user = (req as any).user;

    // Only admins can update status
    if (user.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only admins can update complaint status',
      });
    }

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required',
      });
    }

    const validStatuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status',
      });
    }

    let updateQuery = `
      UPDATE farmer_complaints
      SET status = ?, updated_at = CURRENT_TIMESTAMP
    `;
    const params: any[] = [status];

    if (status === 'RESOLVED' || status === 'CLOSED') {
      updateQuery += `, resolved_at = CURRENT_TIMESTAMP, resolved_by = ?`;
      params.push(user.userId);
    }

    if (resolutionNotes) {
      updateQuery += `, resolution_notes = ?`;
      params.push(resolutionNotes);
    }

    if (assignedTo) {
      updateQuery += `, assigned_to = ?`;
      params.push(assignedTo);
    }

    updateQuery += ` WHERE complaint_id = ?`;
    params.push(complaintId);

    await db.prepare(updateQuery).runAsync(...params);

    logger.info(`Complaint ${complaintId} status updated to ${status} by ${user.userId}`);

    res.json({
      success: true,
      message: 'Complaint status updated successfully',
    });
  } catch (error: any) {
    logger.error('Error updating complaint status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update complaint status',
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/complaints/stats/summary
 * Get complaint statistics (Admin only)
 */
router.get('/stats/summary', authenticateToken, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;

    if (user.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only admins can view complaint statistics',
      });
    }

    // Get counts by status
    const statusCounts = await db.prepare(`
      SELECT status, COUNT(*) as count
      FROM farmer_complaints
      GROUP BY status
    `).allAsync();

    // Get counts by type
    const typeCounts = await db.prepare(`
      SELECT complaint_type, COUNT(*) as count
      FROM farmer_complaints
      GROUP BY complaint_type
    `).allAsync();

    // Get counts by priority
    const priorityCounts = await db.prepare(`
      SELECT priority, COUNT(*) as count
      FROM farmer_complaints
      GROUP BY priority
    `).allAsync();

    // Get recent complaints
    const recentComplaints = await db.prepare(`
      SELECT complaint_id, subject, complaint_type, status, priority, created_at
      FROM farmer_complaints
      ORDER BY created_at DESC
      LIMIT 10
    `).allAsync();

    res.json({
      success: true,
      data: {
        byStatus: statusCounts,
        byType: typeCounts,
        byPriority: priorityCounts,
        recentComplaints,
      },
    });
  } catch (error: any) {
    logger.error('Error fetching complaint statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch complaint statistics',
      error: error.message,
    });
  }
});

export default router;
