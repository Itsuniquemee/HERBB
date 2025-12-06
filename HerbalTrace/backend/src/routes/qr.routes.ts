import { Router, Request, Response, NextFunction } from 'express';
import { getFabricClient } from '../fabric/fabricClient';
import { authenticate } from '../middleware/auth';
import { logger } from '../utils/logger';
import QRCode from 'qrcode';

const router = Router();

/**
 * @route   GET /api/qr/:qrCode
 * @desc    Get product provenance by QR code (Consumer scanning)
 * @access  Public
 */
router.get('/:qrCode', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { qrCode } = req.params;

    const fabricClient = getFabricClient();
    // Connect as a generic read-only user
    await fabricClient.connect('consumer-readonly', 'FarmersCoop');

    const provenance = await fabricClient.getProvenanceByQRCode(qrCode);
    await fabricClient.disconnect();

    if (!provenance) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    logger.info(`QR code scanned: ${qrCode}`);

    res.status(200).json({
      success: true,
      data: provenance
    });
  } catch (error: any) {
    logger.error('Error scanning QR code:', error);
    next(error);
  }
});

/**
 * @route   POST /api/qr/generate
 * @desc    Generate QR code image
 * @access  Private
 */
router.post('/generate', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { data, format } = req.body;

    if (!data) {
      return res.status(400).json({
        success: false,
        message: 'Data is required'
      });
    }

    const qrCodeImage = await QRCode.toDataURL(data, {
      errorCorrectionLevel: 'H',
      type: 'image/png',
      width: 300,
      margin: 2
    });

    res.status(200).json({
      success: true,
      data: {
        qrCode: data,
        image: qrCodeImage
      }
    });
  } catch (error: any) {
    logger.error('Error generating QR code:', error);
    next(error);
  }
});

export default router;
