/**
 * Quality Control Routes
 * REST API endpoints for QC test management, results, and certificates
 */

import { Router, Response } from 'express';
import { db } from '../config/database';
import { authenticate, AuthRequest, authorize } from '../middleware/auth';
import QCService from '../services/QCService';
import { logger } from '../utils/logger';
import QRCode from 'qrcode';
import crypto from 'crypto';

const router = Router();

/**
 * POST /api/v1/qc/templates
 * Create a new QC test template
 * 
 * Access: Admin only
 */
router.post('/templates', authenticate, authorize('Admin'), async (req: AuthRequest, res: Response) => {
  try {
    const {
      name,
      description,
      category,
      applicable_species,
      test_method,
      parameters,
      acceptance_criteria,
      estimated_duration_hours,
      cost,
      required_equipment,
      required_reagents,
      reference_standard,
    } = req.body;

    if (!name || !category || !test_method || !parameters || !acceptance_criteria) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: name, category, test_method, parameters, acceptance_criteria',
      });
    }

    const template = QCService.createTemplate(db, {
      name,
      description,
      category,
      applicable_species,
      test_method,
      parameters: typeof parameters === 'string' ? parameters : JSON.stringify(parameters),
      acceptance_criteria: typeof acceptance_criteria === 'string' ? acceptance_criteria : JSON.stringify(acceptance_criteria),
      estimated_duration_hours,
      cost,
      required_equipment,
      required_reagents,
      reference_standard,
      is_active: 1,
    } as any, req.user!.userId);

    res.status(201).json({
      success: true,
      message: 'QC template created successfully',
      data: template,
    });
  } catch (error: any) {
    logger.error('Create QC template error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to create QC template',
    });
  }
});

/**
 * GET /api/v1/qc/templates
 * List all QC test templates
 * 
 * Access: All authenticated users
 */
router.get('/templates', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { category, species } = req.query;

    const templates = QCService.listTemplates(db, {
      category: category as string,
      species: species as string,
    });

    res.json({
      success: true,
      data: templates,
      total: templates.length,
    });
  } catch (error: any) {
    logger.error('List QC templates error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to list QC templates',
    });
  }
});

/**
 * GET /api/v1/qc/templates/:id
 * Get a specific QC test template
 * 
 * Access: All authenticated users
 */
router.get('/templates/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const template = QCService.getTemplateById(db, id);

    res.json({
      success: true,
      data: template,
    });
  } catch (error: any) {
    logger.error('Get QC template error:', error);
    if (error.message === 'QC template not found') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to get QC template',
    });
  }
});

/**
 * POST /api/v1/qc/tests
 * Create a new QC test for a batch
 * 
 * Access: Admin, Lab users
 */
router.post('/tests', authenticate, authorize('Admin', 'Lab'), async (req: AuthRequest, res: Response) => {
  try {
    const {
      batch_id,
      template_id,
      lab_id,
      lab_name,
      test_type,
      species,
      sample_quantity,
      sample_unit,
      priority,
      due_date,
      notes,
      parameters,
    } = req.body;

    if (!batch_id || !lab_id || !lab_name || !test_type || !species) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: batch_id, lab_id, lab_name, test_type, species',
      });
    }

    const test = QCService.createTest(db, {
      batch_id,
      template_id,
      lab_id,
      lab_name,
      test_type,
      species,
      sample_quantity,
      sample_unit,
      priority,
      requested_by: req.user!.userId,
      due_date,
      notes,
      parameters,
    });

    res.status(201).json({
      success: true,
      message: 'QC test created successfully',
      data: test,
    });
  } catch (error: any) {
    logger.error('Create QC test error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to create QC test',
    });
  }
});

/**
 * GET /api/v1/qc/tests
 * List QC tests with filters
 * 
 * Access: Admin (all tests), Lab (their tests only)
 */
router.get('/tests', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { batch_id, lab_id, status, test_type, limit, offset } = req.query;

    let filters: any = {
      batch_id: batch_id as string,
      lab_id: lab_id as string,
      status: status as string,
      test_type: test_type as string,
      limit: limit ? parseInt(limit as string) : 50,
      offset: offset ? parseInt(offset as string) : 0,
    };

    // Lab users can only see their own tests
    if (req.user?.role === 'Lab') {
      filters.lab_id = req.user.userId;
    }

    const result = QCService.listTests(db, filters);

    res.json({
      success: true,
      data: result.tests,
      pagination: {
        total: result.total,
        limit: filters.limit,
        offset: filters.offset,
        hasMore: result.total > filters.offset + filters.limit,
      },
    });
  } catch (error: any) {
    logger.error('List QC tests error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to list QC tests',
    });
  }
});

/**
 * GET /api/v1/qc/tests/:id
 * Get a specific QC test with parameters and results
 * 
 * Access: Admin, Lab (own tests only)
 */
router.get('/tests/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const test = QCService.getTestById(db, id);

    // Authorization: Lab users can only see their own tests
    if (req.user?.role === 'Lab' && test.lab_id !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'You can only view your own tests',
      });
    }

    res.json({
      success: true,
      data: test,
    });
  } catch (error: any) {
    logger.error('Get QC test error:', error);
    if (error.message === 'QC test not found') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to get QC test',
    });
  }
});

/**
 * PATCH /api/v1/qc/tests/:id/status
 * Update QC test status
 * 
 * Access: Admin, Lab (own tests only)
 */
router.patch('/tests/:id/status', authenticate, authorize('Admin', 'Lab'), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required',
      });
    }

    const validStatuses = ['pending', 'sample_collected', 'in_progress', 'completed', 'failed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
    }

    // Get test to check authorization
    const test = QCService.getTestById(db, id);

    // Authorization: Lab users can only update their own tests
    if (req.user?.role === 'Lab' && test.lab_id !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own tests',
      });
    }

    const updatedTest = QCService.updateTestStatus(db, id, status, req.user!.userId, notes);

    res.json({
      success: true,
      message: 'Test status updated successfully',
      data: updatedTest,
    });
  } catch (error: any) {
    logger.error('Update QC test status error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to update test status',
    });
  }
});

/**
 * POST /api/v1/qc/tests/:id/results
 * Record test results
 * 
 * Access: Admin, Lab (own tests only)
 */
router.post('/tests/:id/results', authenticate, authorize('Admin', 'Lab'), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { results } = req.body;

    if (!results || !Array.isArray(results) || results.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Results array is required',
      });
    }

    // Get test to check authorization
    const test = QCService.getTestById(db, id);

    // Authorization: Lab users can only record results for their own tests
    if (req.user?.role === 'Lab' && test.lab_id !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'You can only add results to your own tests',
      });
    }

    const recordedResults = QCService.recordResults(db, id, results, req.user!.userId);

    res.status(201).json({
      success: true,
      message: 'Results recorded successfully',
      data: recordedResults,
    });
  } catch (error: any) {
    logger.error('Record QC results error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to record results',
    });
  }
});

/**
 * POST /api/v1/qc/tests/:id/certificate
 * Generate QC certificate
 * 
 * Access: Admin, Lab (own tests only)
 */
router.post('/tests/:id/certificate', authenticate, authorize('Admin', 'Lab'), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { valid_until } = req.body;

    // Get test to check authorization
    const test = QCService.getTestById(db, id);

    // Authorization: Lab users can only generate certificates for their own tests
    if (req.user?.role === 'Lab' && test.lab_id !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'You can only generate certificates for your own tests',
      });
    }

    // Generate certificate and record on blockchain
    const certificate = await QCService.generateCertificateWithBlockchain(db, id, req.user!.userId, valid_until);

    res.status(201).json({
      success: true,
      message: certificate.blockchain 
        ? 'Certificate generated and recorded on blockchain successfully'
        : 'Certificate generated successfully (blockchain recording failed)',
      data: certificate,
    });
  } catch (error: any) {
    logger.error('Generate QC certificate error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to generate certificate',
    });
  }
});

/**
 * POST /api/v1/qc/certificates/:id/qr
 * Generate signed QR code for certificate
 * 
 * Access: All authenticated users
 */
router.post('/certificates/:id/qr', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    // Get certificate from database
    const stmt = db.prepare(`
      SELECT c.*, t.batch_id, t.test_type, t.lab_name, 
             b.collection_id, b.species, b.weight_kg
      FROM qc_certificates c
      JOIN qc_tests t ON c.test_id = t.id
      JOIN batches b ON t.batch_id = b.id
      WHERE c.id = ?
    `);
    const certificate: any = stmt.get(id);

    if (!certificate) {
      return res.status(404).json({
        success: false,
        message: 'Certificate not found',
      });
    }

    // Create QR code payload with certificate data
    const qrPayload = {
      cert_id: certificate.certificate_number,
      batch_id: certificate.batch_id,
      test_type: certificate.test_type,
      result: certificate.overall_result,
      issued: certificate.issued_date,
      valid_until: certificate.valid_until,
      blockchain_tx: certificate.blockchain_txid || null,
      issued_by: certificate.lab_name,
      species: certificate.species,
    };

    // Generate HMAC signature for tamper protection
    const secret = process.env.QR_SIGNING_SECRET || 'herbaltrace-qr-secret-key-change-in-production';
    const dataToSign = JSON.stringify(qrPayload);
    const signature = crypto
      .createHmac('sha256', secret)
      .update(dataToSign)
      .digest('hex');

    // Add signature to payload
    const signedPayload = {
      ...qrPayload,
      signature,
      verified: true,
    };

    // Generate QR code as base64 PNG
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(signedPayload), {
      errorCorrectionLevel: 'H', // High error correction for better scanning
      type: 'image/png',
      width: 400,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });

    // Return QR code and metadata
    res.json({
      success: true,
      message: 'QR code generated successfully',
      data: {
        qrCode: qrCodeDataURL, // base64 data URL
        certificate_number: certificate.certificate_number,
        batch_id: certificate.batch_id,
        blockchain_tx: certificate.blockchain_txid,
        payload: signedPayload,
        verification_url: `${process.env.PUBLIC_URL || 'http://localhost:3000'}/verify/${certificate.certificate_number}`,
      },
    });
  } catch (error: any) {
    logger.error('Generate QR code error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate QR code',
    });
  }
});

/**
 * POST /api/v1/qc/certificates/verify-qr
 * Verify signed QR code data
 * 
 * Access: Public (no authentication required)
 */
router.post('/certificates/verify-qr', async (req, res: Response) => {
  try {
    const { qrData } = req.body;

    if (!qrData) {
      return res.status(400).json({
        success: false,
        message: 'QR data is required',
      });
    }

    // Parse QR data
    let payload: any;
    try {
      payload = typeof qrData === 'string' ? JSON.parse(qrData) : qrData;
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid QR code format',
      });
    }

    // Extract signature from payload
    const { signature, ...dataWithoutSignature } = payload;

    if (!signature) {
      return res.status(400).json({
        success: false,
        message: 'QR code is not signed',
        verified: false,
      });
    }

    // Verify signature
    const secret = process.env.QR_SIGNING_SECRET || 'herbaltrace-qr-secret-key-change-in-production';
    const dataToVerify = JSON.stringify(dataWithoutSignature);
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(dataToVerify)
      .digest('hex');

    const isValid = signature === expectedSignature;

    if (!isValid) {
      return res.status(400).json({
        success: false,
        message: 'QR code signature verification failed - This certificate may be tampered or counterfeit',
        verified: false,
      });
    }

    // Get certificate details from database for additional verification
    const stmt = db.prepare(`
      SELECT c.*, t.batch_id, t.test_type, b.species
      FROM qc_certificates c
      JOIN qc_tests t ON c.test_id = t.id
      JOIN batches b ON t.batch_id = b.id
      WHERE c.certificate_number = ?
    `);
    const certificate: any = stmt.get(payload.cert_id);

    if (!certificate) {
      return res.json({
        success: true,
        message: 'QR signature is valid, but certificate not found in database',
        verified: true,
        signature_valid: true,
        database_match: false,
        data: payload,
      });
    }

    // Verify data matches database
    const dataMatches = 
      certificate.batch_id === payload.batch_id &&
      certificate.overall_result === payload.result;

    // Check if certificate is still valid
    const now = new Date();
    const validUntil = payload.valid_until ? new Date(payload.valid_until) : null;
    const isExpired = validUntil && now > validUntil;

    res.json({
      success: true,
      message: 'QR code verified successfully',
      verified: true,
      signature_valid: true,
      database_match: dataMatches,
      expired: isExpired,
      data: {
        ...payload,
        certificate: {
          number: certificate.certificate_number,
          batch_id: certificate.batch_id,
          species: certificate.species,
          test_type: certificate.test_type,
          result: certificate.overall_result,
          issued: certificate.issued_date,
          blockchain_tx: certificate.blockchain_txid,
        },
      },
    });
  } catch (error: any) {
    logger.error('Verify QR code error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to verify QR code',
    });
  }
});

/**
 * GET /api/v1/qc/statistics
 * Get QC test statistics
 * 
 * Access: Admin (all stats), Lab (their stats only)
 */
router.get('/statistics', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { lab_id, date_from, date_to } = req.query;

    let filters: any = {
      lab_id: lab_id as string,
      date_from: date_from as string,
      date_to: date_to as string,
    };

    // Lab users can only see their own statistics
    if (req.user?.role === 'Lab') {
      filters.lab_id = req.user.userId;
    }

    const stats = QCService.getTestStatistics(db, filters);

    res.json({
      success: true,
      data: stats,
    });
  } catch (error: any) {
    logger.error('Get QC statistics error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to get statistics',
    });
  }
});

/**
 * GET /api/v1/qc/batch/:batchId/tests
 * Get all QC tests for a specific batch
 * 
 * Access: All authenticated users
 */
router.get('/batch/:batchId/tests', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { batchId } = req.params;

    const result = QCService.listTests(db, { batch_id: batchId });

    res.json({
      success: true,
      data: result.tests,
      total: result.total,
    });
  } catch (error: any) {
    logger.error('Get batch QC tests error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to get batch tests',
    });
  }
});

export default router;
