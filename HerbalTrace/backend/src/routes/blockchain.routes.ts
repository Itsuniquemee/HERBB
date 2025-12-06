import express, { Request, Response } from 'express';
import { fabricService } from '../services/FabricService';
import { blockchainMonitoringService } from '../services/BlockchainMonitoringService';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();

/**
 * @route   GET /api/v1/blockchain/info
 * @desc    Get blockchain network information
 * @access  Private
 */
router.get('/info', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const info = await blockchainMonitoringService.getBlockchainInfo();

    res.json({
      success: true,
      data: info,
    });
  } catch (error: any) {
    logger.error('Error getting blockchain info:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get blockchain information',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/v1/blockchain/health
 * @desc    Check blockchain connection health
 * @access  Public
 */
router.get('/health', async (req: Request, res: Response) => {
  try {
    const health = await blockchainMonitoringService.healthCheck();

    const statusCode = health.healthy ? 200 : 503;
    res.status(statusCode).json({
      success: health.healthy,
      data: health,
    });
  } catch (error: any) {
    logger.error('Error checking blockchain health:', error);
    res.status(503).json({
      success: false,
      data: {
        healthy: false,
        status: 'ERROR',
        error: error.message,
        timestamp: new Date().toISOString(),
      },
    });
  }
});

/**
 * @route   GET /api/v1/blockchain/stats
 * @desc    Get blockchain statistics
 * @access  Private (Admin)
 */
router.get('/stats', authenticate, authorize('Admin'), async (req: AuthRequest, res: Response) => {
  try {
    const stats = await blockchainMonitoringService.getBlockchainStats();

    res.json({
      success: true,
      data: stats,
    });
  } catch (error: any) {
    logger.error('Error getting blockchain stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get blockchain statistics',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/v1/blockchain/transactions/recent
 * @desc    Get recent blockchain transactions
 * @access  Private
 */
router.get('/transactions/recent', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 20;
    const transactions = await blockchainMonitoringService.getRecentTransactions(limit);

    res.json({
      success: true,
      data: {
        count: transactions.length,
        transactions,
      },
    });
  } catch (error: any) {
    logger.error('Error getting recent transactions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get recent transactions',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/v1/blockchain/certificates/:certificateId
 * @desc    Query certificate from blockchain
 * @access  Public (for verification)
 */
router.get('/certificates/:certificateId', async (req: Request, res: Response) => {
  try {
    const { certificateId } = req.params;

    const certificate = await fabricService.queryQCCertificate(certificateId);

    res.json({
      success: true,
      data: certificate,
    });
  } catch (error: any) {
    logger.error(`Error querying certificate ${req.params.certificateId}:`, error);
    res.status(404).json({
      success: false,
      message: 'Certificate not found on blockchain',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/v1/blockchain/certificates/:certificateId/verify
 * @desc    Verify certificate authenticity on blockchain
 * @access  Public (for verification)
 */
router.get('/certificates/:certificateId/verify', async (req: Request, res: Response) => {
  try {
    const { certificateId } = req.params;

    const verification = await blockchainMonitoringService.verifyCertificate(certificateId);

    res.json({
      success: true,
      data: verification,
    });
  } catch (error: any) {
    logger.error(`Error verifying certificate ${req.params.certificateId}:`, error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify certificate',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/v1/blockchain/certificates/:certificateId/history
 * @desc    Get certificate history from blockchain
 * @access  Private
 */
router.get('/certificates/:certificateId/history', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { certificateId } = req.params;

    const history = await blockchainMonitoringService.getCertificateHistory(certificateId);

    res.json({
      success: true,
      data: history,
    });
  } catch (error: any) {
    logger.error(`Error getting certificate history ${req.params.certificateId}:`, error);
    res.status(500).json({
      success: false,
      message: 'Failed to get certificate history',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/v1/blockchain/batches/:batchId/certificates
 * @desc    Get all certificates for a batch from blockchain
 * @access  Private
 */
router.get('/batches/:batchId/certificates', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { batchId } = req.params;

    const certificates = await blockchainMonitoringService.getCertificatesByBatch(batchId);

    res.json({
      success: true,
      data: certificates,
    });
  } catch (error: any) {
    logger.error(`Error getting certificates for batch ${req.params.batchId}:`, error);
    res.status(500).json({
      success: false,
      message: 'Failed to get batch certificates',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/v1/blockchain/reconnect
 * @desc    Reconnect to blockchain network
 * @access  Private (Admin)
 */
router.post('/reconnect', authenticate, authorize('Admin'), async (req: AuthRequest, res: Response) => {
  try {
    const result = await blockchainMonitoringService.reconnect();

    res.json({
      success: true,
      data: result,
    });
  } catch (error: any) {
    logger.error('Error reconnecting to blockchain:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reconnect to blockchain',
      error: error.message,
    });
  }
});

export default router;
