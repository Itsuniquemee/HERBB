import { Router, Request, Response, NextFunction } from 'express';
import { getFabricClient } from '../fabric/fabricClient';
import { authenticate } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';

const router = Router();

/**
 * @route   GET /api/products
 * @desc    Get all products
 * @access  Public (for testing)
 */
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // TODO: Implement QueryAllProducts in chaincode
    res.status(200).json({
      success: true,
      count: 0,
      data: []
    });
  } catch (error: any) {
    logger.error('Error querying products:', error);
    next(error);
  }
});

/**
 * @route   POST /api/products
 * @desc    Create a new product
 * @access  Public (for testing - auth disabled)
 */
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const productData = {
      id: req.body.id || `PROD-${uuidv4()}`,
      type: 'Product',
      manufacturerId: 'manufacturer1',
      ...req.body,
      timestamp: new Date().toISOString()
    };

    const fabricClient = getFabricClient();
    await fabricClient.connect('admin-Manufacturers', 'Manufacturers');

    const result = await fabricClient.createProduct(productData);
    await fabricClient.disconnect();

    logger.info(`Product created: ${productData.id}`);

    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      data: productData,
      transactionId: result?.transactionId || `tx-${Date.now()}`
    });
  } catch (error: any) {
    logger.error('Error creating product:', error);
    next(error);
  }
});

/**
 * @route   GET /api/products/:id
 * @desc    Get product by ID
 * @access  Public (for testing)
 */
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    const fabricClient = getFabricClient();
    await fabricClient.connect('admin-Manufacturers', 'Manufacturers');

    const result = await fabricClient.getProduct(id);
    await fabricClient.disconnect();

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error: any) {
    logger.error('Error getting product:', error);
    next(error);
  }
});

export default router;
