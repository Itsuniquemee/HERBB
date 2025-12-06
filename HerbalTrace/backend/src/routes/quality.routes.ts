import { Router, Request, Response, NextFunction } from 'express';
import { getFabricClient } from '../fabric/fabricClient';
import { authenticate } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';

const router = Router();

/**
 * @route   GET /api/quality-tests
 * @desc    Get all quality tests
 * @access  Public (for testing)
 */
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // TODO: Implement QueryAllQualityTests in chaincode
    res.status(200).json({
      success: true,
      count: 0,
      data: []
    });
  } catch (error: any) {
    logger.error('Error querying quality tests:', error);
    next(error);
  }
});

/**
 * @route   POST /api/quality-tests
 * @desc    Create a new quality test
 * @access  Public (for testing - auth disabled)
 */
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const testData = {
      id: req.body.id || `TEST-${uuidv4()}`,
      type: 'QualityTest',
      labId: 'lab1',
      ...req.body,
      timestamp: new Date().toISOString()
    };

    const fabricClient = getFabricClient();
    await fabricClient.connect('admin-TestingLabs', 'TestingLabs');

    const result = await fabricClient.createQualityTest(testData);
    await fabricClient.disconnect();

    logger.info(`Quality test created: ${testData.id}`);

    res.status(201).json({
      success: true,
      message: 'Quality test created successfully',
      data: testData,
      transactionId: result?.transactionId || `tx-${Date.now()}`
    });
  } catch (error: any) {
    logger.error('Error creating quality test:', error);
    next(error);
  }
});

/**
 * @route   GET /api/quality-tests/:id
 * @desc    Get quality test by ID
 * @access  Public (for testing)
 */
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    const fabricClient = getFabricClient();
    await fabricClient.connect('admin-TestingLabs', 'TestingLabs');

    const result = await fabricClient.getQualityTest(id);
    await fabricClient.disconnect();

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Quality test not found'
      });
    }

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error: any) {
    logger.error('Error getting quality test:', error);
    next(error);
  }
});

export default router;
