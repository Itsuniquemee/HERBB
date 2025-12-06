import { Router, Request, Response, NextFunction } from 'express';
import { getFabricClient } from '../fabric/fabricClient';
import { authenticate } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';

const router = Router();

/**
 * @route   GET /api/processing
 * @desc    Get all processing steps
 * @access  Public (for testing)
 */
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // TODO: Implement QueryAllProcessingSteps in chaincode
    res.status(200).json({
      success: true,
      count: 0,
      data: []
    });
  } catch (error: any) {
    logger.error('Error querying processing steps:', error);
    next(error);
  }
});

/**
 * @route   POST /api/processing
 * @desc    Create a new processing step
 * @access  Public (for testing - auth disabled)
 */
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const processingData = {
      id: req.body.id || `PROC-${uuidv4()}`,
      type: 'ProcessingStep',
      processorId: 'processor1',
      ...req.body,
      timestamp: new Date().toISOString()
    };

    const fabricClient = getFabricClient();
    await fabricClient.connect('admin-Processors', 'Processors');

    const result = await fabricClient.createProcessingStep(processingData);
    await fabricClient.disconnect();

    logger.info(`Processing step created: ${processingData.id}`);

    res.status(201).json({
      success: true,
      message: 'Processing step created successfully',
      data: processingData,
      transactionId: result?.transactionId || `tx-${Date.now()}`
    });
  } catch (error: any) {
    logger.error('Error creating processing step:', error);
    next(error);
  }
});

/**
 * @route   GET /api/processing/:id
 * @desc    Get processing step by ID
 * @access  Public (for testing)
 */
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    const fabricClient = getFabricClient();
    await fabricClient.connect('admin-Processors', 'Processors');

    const result = await fabricClient.getProcessingStep(id);
    await fabricClient.disconnect();

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Processing step not found'
      });
    }

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error: any) {
    logger.error('Error getting processing step:', error);
    next(error);
  }
});

export default router;
