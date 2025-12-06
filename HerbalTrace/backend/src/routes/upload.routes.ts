import { Router, Request, Response } from 'express';
import imageUploadService from '../services/ImageUploadService';
import { authenticate } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = Router();

/**
 * @route   POST /api/v1/upload/images
 * @desc    Upload multiple images
 * @access  Private (Authenticated users)
 */
router.post('/images', authenticate, async (req: Request, res: Response) => {
  try {
    const uploadType = (req.query.type as string) || 'temp';
    const maxCount = parseInt(req.query.maxCount as string) || 10;

    // Get upload middleware
    const upload = imageUploadService.getUploadMiddleware(uploadType, maxCount);

    // Handle upload
    upload.array('images', maxCount)(req, res, async (err: any) => {
      if (err) {
        logger.error('Upload error:', err);
        return res.status(400).json({
          success: false,
          message: err.message || 'Failed to upload images'
        });
      }

      const files = req.files as Express.Multer.File[];

      if (!files || files.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No images provided'
        });
      }

      try {
        // Process uploaded files
        const processedFiles = await imageUploadService.processUploadedFiles(files, {
          compress: req.query.compress === 'true',
          generateThumbnails: req.query.thumbnails === 'true',
          baseUrl: process.env.BASE_URL || `${req.protocol}://${req.get('host')}`
        });

        logger.info(`Uploaded ${processedFiles.length} images by user: ${(req as any).user.userId}`);

        res.status(200).json({
          success: true,
          message: `Successfully uploaded ${processedFiles.length} image(s)`,
          data: {
            files: processedFiles,
            count: processedFiles.length
          }
        });
      } catch (processError: any) {
        logger.error('Process files error:', processError);
        res.status(500).json({
          success: false,
          message: 'Failed to process uploaded images'
        });
      }
    });
  } catch (error: any) {
    logger.error('Upload route error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

/**
 * @route   POST /api/v1/upload/single
 * @desc    Upload single image
 * @access  Private (Authenticated users)
 */
router.post('/single', authenticate, async (req: Request, res: Response) => {
  try {
    const uploadType = (req.query.type as string) || 'temp';
    const upload = imageUploadService.getUploadMiddleware(uploadType, 1);

    upload.single('image')(req, res, async (err: any) => {
      if (err) {
        logger.error('Upload error:', err);
        return res.status(400).json({
          success: false,
          message: err.message || 'Failed to upload image'
        });
      }

      const file = req.file as Express.Multer.File;

      if (!file) {
        return res.status(400).json({
          success: false,
          message: 'No image provided'
        });
      }

      try {
        const processedFiles = await imageUploadService.processUploadedFiles([file], {
          compress: req.query.compress !== 'false',
          generateThumbnails: req.query.thumbnails === 'true',
          baseUrl: process.env.BASE_URL || `${req.protocol}://${req.get('host')}`
        });

        logger.info(`Uploaded 1 image by user: ${(req as any).user.userId}`);

        res.status(200).json({
          success: true,
          message: 'Image uploaded successfully',
          data: processedFiles[0]
        });
      } catch (processError: any) {
        logger.error('Process file error:', processError);
        res.status(500).json({
          success: false,
          message: 'Failed to process uploaded image'
        });
      }
    });
  } catch (error: any) {
    logger.error('Upload single route error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

/**
 * @route   DELETE /api/v1/upload/image
 * @desc    Delete uploaded image
 * @access  Private (Authenticated users)
 */
router.delete('/image', authenticate, async (req: Request, res: Response) => {
  try {
    const { filePath } = req.body;

    if (!filePath) {
      return res.status(400).json({
        success: false,
        message: 'Please provide filePath'
      });
    }

    const deleted = imageUploadService.deleteFile(filePath);

    if (deleted) {
      logger.info(`Deleted image: ${filePath} by user: ${(req as any).user.userId}`);
      res.status(200).json({
        success: true,
        message: 'Image deleted successfully'
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'Image not found'
      });
    }
  } catch (error: any) {
    logger.error('Delete image error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete image'
    });
  }
});

/**
 * @route   DELETE /api/v1/upload/images
 * @desc    Delete multiple images
 * @access  Private (Authenticated users)
 */
router.delete('/images', authenticate, async (req: Request, res: Response) => {
  try {
    const { filePaths } = req.body;

    if (!filePaths || !Array.isArray(filePaths) || filePaths.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide filePaths array'
      });
    }

    const deletedCount = imageUploadService.deleteFiles(filePaths);

    logger.info(`Deleted ${deletedCount} images by user: ${(req as any).user.userId}`);

    res.status(200).json({
      success: true,
      message: `Successfully deleted ${deletedCount} image(s)`,
      data: { deletedCount }
    });
  } catch (error: any) {
    logger.error('Delete images error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete images'
    });
  }
});

/**
 * @route   POST /api/v1/upload/move
 * @desc    Move file from temp to permanent location
 * @access  Private (Authenticated users)
 */
router.post('/move', authenticate, async (req: Request, res: Response) => {
  try {
    const { tempPath, targetType, newFilename } = req.body;

    if (!tempPath || !targetType) {
      return res.status(400).json({
        success: false,
        message: 'Please provide tempPath and targetType'
      });
    }

    const newPath = imageUploadService.moveFile(tempPath, targetType, newFilename);

    logger.info(`Moved file: ${tempPath} -> ${targetType} by user: ${(req as any).user.userId}`);

    res.status(200).json({
      success: true,
      message: 'File moved successfully',
      data: { newPath }
    });
  } catch (error: any) {
    logger.error('Move file error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to move file'
    });
  }
});

/**
 * @route   GET /api/v1/upload/info
 * @desc    Get file information
 * @access  Private (Authenticated users)
 */
router.get('/info', authenticate, async (req: Request, res: Response) => {
  try {
    const { filePath } = req.query;

    if (!filePath) {
      return res.status(400).json({
        success: false,
        message: 'Please provide filePath'
      });
    }

    const fileInfo = imageUploadService.getFileInfo(filePath as string);

    if (!fileInfo) {
      return res.status(404).json({
        success: false,
        message: 'File not found'
      });
    }

    res.status(200).json({
      success: true,
      data: fileInfo
    });
  } catch (error: any) {
    logger.error('Get file info error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get file information'
    });
  }
});

export default router;
