import multer from 'multer';
import sharp from 'sharp';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';

/**
 * Image Upload Service
 * Handles multi-image uploads with validation, compression, and storage
 */
class ImageUploadService {
  private uploadDir: string;
  private maxFileSize: number = 5 * 1024 * 1024; // 5MB
  private allowedMimeTypes: string[] = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  private maxFiles: number = 10;

  constructor() {
    // Set upload directory
    this.uploadDir = path.join(__dirname, '../../uploads');
    this.ensureUploadDirectory();
  }

  /**
   * Ensure upload directory exists
   */
  private ensureUploadDirectory(): void {
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
      logger.info(`Created upload directory: ${this.uploadDir}`);
    }

    // Create subdirectories for different upload types
    const subdirs = ['collections', 'batches', 'processing', 'quality-tests', 'products', 'farms', 'temp'];
    subdirs.forEach(dir => {
      const fullPath = path.join(this.uploadDir, dir);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
      }
    });
  }

  /**
   * Configure multer storage
   */
  private getStorage(uploadType: string = 'temp'): multer.StorageEngine {
    return multer.diskStorage({
      destination: (req, file, cb) => {
        const destPath = path.join(this.uploadDir, uploadType);
        cb(null, destPath);
      },
      filename: (req, file, cb) => {
        const uniqueId = uuidv4();
        const ext = path.extname(file.originalname);
        const filename = `${Date.now()}-${uniqueId}${ext}`;
        cb(null, filename);
      }
    });
  }

  /**
   * File filter for multer
   */
  private fileFilter(req: any, file: Express.Multer.File, cb: multer.FileFilterCallback): void {
    // Check mime type
    if (!this.allowedMimeTypes.includes(file.mimetype)) {
      return cb(new Error(`Invalid file type. Allowed types: ${this.allowedMimeTypes.join(', ')}`));
    }

    // Check file extension
    const ext = path.extname(file.originalname).toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowedExtensions.includes(ext)) {
      return cb(new Error('Invalid file extension. Allowed: .jpg, .jpeg, .png, .webp'));
    }

    cb(null, true);
  }

  /**
   * Get multer upload middleware for specific upload type
   */
  public getUploadMiddleware(uploadType: string = 'temp', maxCount: number = 10) {
    return multer({
      storage: this.getStorage(uploadType),
      fileFilter: this.fileFilter.bind(this),
      limits: {
        fileSize: this.maxFileSize,
        files: Math.min(maxCount, this.maxFiles)
      }
    });
  }

  /**
   * Compress and optimize image
   */
  public async compressImage(
    inputPath: string,
    outputPath?: string,
    options: {
      width?: number;
      height?: number;
      quality?: number;
      format?: 'jpeg' | 'png' | 'webp';
    } = {}
  ): Promise<string> {
    try {
      const {
        width = 1920,
        height = 1080,
        quality = 80,
        format = 'jpeg'
      } = options;

      const output = outputPath || inputPath.replace(/\.[^/.]+$/, `-optimized.${format}`);

      await sharp(inputPath)
        .resize(width, height, {
          fit: 'inside',
          withoutEnlargement: true
        })
        .toFormat(format, { quality })
        .toFile(output);

      logger.info(`Image compressed: ${path.basename(inputPath)} -> ${path.basename(output)}`);

      // Delete original if different from output
      if (inputPath !== output) {
        fs.unlinkSync(inputPath);
      }

      return output;
    } catch (error) {
      logger.error('Image compression error:', error);
      throw new Error('Failed to compress image');
    }
  }

  /**
   * Process uploaded files and return URLs
   */
  public async processUploadedFiles(
    files: Express.Multer.File[],
    options: {
      compress?: boolean;
      generateThumbnails?: boolean;
      baseUrl?: string;
    } = {}
  ): Promise<Array<{ original: string; compressed?: string; thumbnail?: string }>> {
    const {
      compress = true,
      generateThumbnails = false,
      baseUrl = process.env.BASE_URL || 'http://localhost:3000'
    } = options;

    const results = [];

    for (const file of files) {
      try {
        let compressedPath = file.path;
        let thumbnailPath;

        // Compress image
        if (compress) {
          compressedPath = await this.compressImage(file.path, undefined, {
            quality: 85,
            format: 'jpeg'
          });
        }

        // Generate thumbnail
        if (generateThumbnails) {
          const thumbnailDir = path.join(path.dirname(compressedPath), 'thumbnails');
          if (!fs.existsSync(thumbnailDir)) {
            fs.mkdirSync(thumbnailDir, { recursive: true });
          }
          
          thumbnailPath = path.join(thumbnailDir, `thumb-${path.basename(compressedPath)}`);
          await sharp(compressedPath)
            .resize(300, 300, { fit: 'cover' })
            .toFormat('jpeg', { quality: 70 })
            .toFile(thumbnailPath);
        }

        // Generate URLs
        const relativeCompressed = path.relative(this.uploadDir, compressedPath).replace(/\\/g, '/');
        const relativeThumbnail = thumbnailPath 
          ? path.relative(this.uploadDir, thumbnailPath).replace(/\\/g, '/')
          : undefined;

        results.push({
          original: `${baseUrl}/uploads/${relativeCompressed}`,
          compressed: compress ? `${baseUrl}/uploads/${relativeCompressed}` : undefined,
          thumbnail: relativeThumbnail ? `${baseUrl}/uploads/${relativeThumbnail}` : undefined,
          filename: path.basename(compressedPath),
          size: fs.statSync(compressedPath).size,
          uploadedAt: new Date().toISOString()
        });

        logger.info(`Processed image: ${file.originalname} -> ${path.basename(compressedPath)}`);
      } catch (error) {
        logger.error(`Failed to process file ${file.originalname}:`, error);
        // Clean up failed file
        if (fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      }
    }

    return results;
  }

  /**
   * Delete uploaded file(s)
   */
  public deleteFile(filePath: string): boolean {
    try {
      const fullPath = path.join(this.uploadDir, filePath);
      if (fs.existsSync(fullPath)) {
        fs.unlinkSync(fullPath);
        logger.info(`Deleted file: ${filePath}`);
        
        // Also delete thumbnail if exists
        const thumbnailPath = path.join(
          path.dirname(fullPath),
          'thumbnails',
          `thumb-${path.basename(fullPath)}`
        );
        if (fs.existsSync(thumbnailPath)) {
          fs.unlinkSync(thumbnailPath);
        }
        
        return true;
      }
      return false;
    } catch (error) {
      logger.error('Delete file error:', error);
      return false;
    }
  }

  /**
   * Delete multiple files
   */
  public deleteFiles(filePaths: string[]): number {
    let deletedCount = 0;
    filePaths.forEach(filePath => {
      if (this.deleteFile(filePath)) {
        deletedCount++;
      }
    });
    return deletedCount;
  }

  /**
   * Move file from temp to permanent location
   */
  public moveFile(tempPath: string, targetType: string, newFilename?: string): string {
    try {
      const sourcePath = path.join(this.uploadDir, tempPath);
      const targetDir = path.join(this.uploadDir, targetType);
      
      if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
      }

      const filename = newFilename || path.basename(tempPath);
      const targetPath = path.join(targetDir, filename);

      fs.renameSync(sourcePath, targetPath);
      
      logger.info(`Moved file: ${tempPath} -> ${targetType}/${filename}`);
      
      return path.relative(this.uploadDir, targetPath).replace(/\\/g, '/');
    } catch (error) {
      logger.error('Move file error:', error);
      throw new Error('Failed to move file');
    }
  }

  /**
   * Get file info
   */
  public getFileInfo(filePath: string): any {
    try {
      const fullPath = path.join(this.uploadDir, filePath);
      if (!fs.existsSync(fullPath)) {
        return null;
      }

      const stats = fs.statSync(fullPath);
      return {
        path: filePath,
        size: stats.size,
        createdAt: stats.birthtime,
        modifiedAt: stats.mtime,
        exists: true
      };
    } catch (error) {
      logger.error('Get file info error:', error);
      return null;
    }
  }

  /**
   * Clean up old temporary files (older than 24 hours)
   */
  public async cleanupTempFiles(): Promise<number> {
    try {
      const tempDir = path.join(this.uploadDir, 'temp');
      const files = fs.readdirSync(tempDir);
      const now = Date.now();
      const oneDayAgo = now - (24 * 60 * 60 * 1000);
      let deletedCount = 0;

      files.forEach(file => {
        const filePath = path.join(tempDir, file);
        const stats = fs.statSync(filePath);
        
        if (stats.birthtime.getTime() < oneDayAgo) {
          fs.unlinkSync(filePath);
          deletedCount++;
          logger.info(`Cleaned up old temp file: ${file}`);
        }
      });

      return deletedCount;
    } catch (error) {
      logger.error('Cleanup temp files error:', error);
      return 0;
    }
  }

  /**
   * Get upload directory path
   */
  public getUploadDir(): string {
    return this.uploadDir;
  }

  /**
   * Validate image dimensions
   */
  public async validateImageDimensions(
    filePath: string,
    minWidth: number = 100,
    minHeight: number = 100,
    maxWidth: number = 10000,
    maxHeight: number = 10000
  ): Promise<boolean> {
    try {
      const metadata = await sharp(filePath).metadata();
      
      if (!metadata.width || !metadata.height) {
        return false;
      }

      return (
        metadata.width >= minWidth &&
        metadata.height >= minHeight &&
        metadata.width <= maxWidth &&
        metadata.height <= maxHeight
      );
    } catch (error) {
      logger.error('Validate image dimensions error:', error);
      return false;
    }
  }
}

// Export singleton instance
export default new ImageUploadService();
