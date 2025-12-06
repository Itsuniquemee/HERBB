import express, { Request, Response } from 'express';
import { authenticate, AuthRequest, authorize } from '../middleware/auth';
import AnalyticsService from '../services/AnalyticsService';
import { logger } from '../utils/logger';
import { db } from '../config/database';

const router = express.Router();

/**
 * @route   GET /api/v1/analytics/dashboard
 * @desc    Get comprehensive dashboard data
 * @access  Private (Admin, Lab, Processor)
 */
router.get(
  '/dashboard',
  authenticate,
  authorize('Admin', 'Lab', 'Processor'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { date_from, date_to, entity_id } = req.query;

      // Check cache first
      const cached = AnalyticsService.getCachedDashboardData(db, 'main_dashboard', {
        date_from: date_from as string,
        date_to: date_to as string,
        entity_id: entity_id as string,
      });

      if (cached) {
        return res.json({
          success: true,
          data: { ...cached, from_cache: true },
        });
      }

      // Generate fresh data
      const dashboard = AnalyticsService.getDashboardData(db, {
        date_from: date_from as string,
        date_to: date_to as string,
        entity_id: entity_id as string,
      });

      res.json({
        success: true,
        data: { ...dashboard, from_cache: false },
      });
    } catch (error: any) {
      logger.error('Error getting dashboard data:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get dashboard data',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/v1/analytics/qc-metrics
 * @desc    Get QC metrics (success rates, completion times, costs)
 * @access  Private (Admin, Lab, Processor)
 */
router.get(
  '/qc-metrics',
  authenticate,
  authorize('Admin', 'Lab', 'Processor'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { date_from, date_to, entity_id } = req.query;

      const metrics = AnalyticsService.calculateQCMetrics(db, {
        date_from: date_from as string,
        date_to: date_to as string,
        entity_id: entity_id as string,
      });

      res.json({
        success: true,
        data: metrics,
      });
    } catch (error: any) {
      logger.error('Error calculating QC metrics:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to calculate QC metrics',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/v1/analytics/lab-performance
 * @desc    Get lab performance metrics
 * @access  Private (Admin)
 */
router.get(
  '/lab-performance',
  authenticate,
  authorize('Admin'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { date_from, date_to } = req.query;

      const performance = AnalyticsService.getLabPerformance(db, {
        date_from: date_from as string,
        date_to: date_to as string,
      });

      res.json({
        success: true,
        data: performance,
      });
    } catch (error: any) {
      logger.error('Error getting lab performance:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get lab performance',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/v1/analytics/batch-quality
 * @desc    Get batch quality scores
 * @access  Private (Admin, Processor)
 */
router.get(
  '/batch-quality',
  authenticate,
  authorize('Admin', 'Processor'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { batch_id, date_from, date_to } = req.query;

      const scores = AnalyticsService.getBatchQualityScores(db, {
        batch_id: batch_id as string,
        date_from: date_from as string,
        date_to: date_to as string,
      });

      res.json({
        success: true,
        data: scores,
      });
    } catch (error: any) {
      logger.error('Error getting batch quality scores:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get batch quality scores',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/v1/analytics/trends/:metric_type
 * @desc    Get trend data for a specific metric
 * @access  Private (Admin, Lab, Processor)
 */
router.get(
  '/trends/:metric_type',
  authenticate,
  authorize('Admin', 'Lab', 'Processor'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { metric_type } = req.params;
      const { period, date_from, date_to, entity_id, entity_type } = req.query;

      // Validate period
      const validPeriods = ['DAY', 'WEEK', 'MONTH', 'QUARTER'];
      const selectedPeriod = (period as string)?.toUpperCase() || 'WEEK';
      
      if (!validPeriods.includes(selectedPeriod)) {
        return res.status(400).json({
          success: false,
          message: `Invalid period. Must be one of: ${validPeriods.join(', ')}`,
        });
      }

      const trends = AnalyticsService.getTrendData(
        db,
        metric_type,
        selectedPeriod as 'DAY' | 'WEEK' | 'MONTH' | 'QUARTER',
        {
          date_from: date_from as string,
          date_to: date_to as string,
          entity_id: entity_id as string,
          entity_type: entity_type as string,
        }
      );

      res.json({
        success: true,
        data: {
          metric_type,
          period: selectedPeriod,
          trends,
        },
      });
    } catch (error: any) {
      logger.error('Error getting trend data:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get trend data',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/v1/analytics/cost-analysis
 * @desc    Get cost analysis data
 * @access  Private (Admin)
 */
router.get(
  '/cost-analysis',
  authenticate,
  authorize('Admin'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { date_from, date_to, lab_id } = req.query;

      const costData = AnalyticsService.getCostAnalysis(db, {
        date_from: date_from as string,
        date_to: date_to as string,
        lab_id: lab_id as string,
      });

      res.json({
        success: true,
        data: costData,
      });
    } catch (error: any) {
      logger.error('Error getting cost analysis:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get cost analysis',
        error: error.message,
      });
    }
  }
);

/**
 * @route   POST /api/v1/analytics/cache/clean
 * @desc    Clean expired cache entries
 * @access  Private (Admin)
 */
router.post(
  '/cache/clean',
  authenticate,
  authorize('Admin'),
  async (req: AuthRequest, res: Response) => {
    try {
      const deleted = AnalyticsService.cleanExpiredCache(db);

      res.json({
        success: true,
        message: `Cleaned ${deleted} expired cache entries`,
        data: { deleted },
      });
    } catch (error: any) {
      logger.error('Error cleaning cache:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to clean cache',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/v1/analytics/metrics
 * @desc    Get stored metrics with filtering
 * @access  Private (Admin)
 */
router.get(
  '/metrics',
  authenticate,
  authorize('Admin'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { 
        metric_type, 
        entity_id, 
        entity_type, 
        date_from, 
        date_to,
        limit = '100',
        offset = '0'
      } = req.query;

      let whereClause = 'WHERE 1=1';
      const params: any[] = [];

      if (metric_type) {
        whereClause += ' AND metric_type = ?';
        params.push(metric_type);
      }
      if (entity_id) {
        whereClause += ' AND entity_id = ?';
        params.push(entity_id);
      }
      if (entity_type) {
        whereClause += ' AND entity_type = ?';
        params.push(entity_type);
      }
      if (date_from) {
        whereClause += ' AND calculation_date >= ?';
        params.push(date_from);
      }
      if (date_to) {
        whereClause += ' AND calculation_date <= ?';
        params.push(date_to);
      }

      const stmt = db.prepare(`
        SELECT *
        FROM analytics_metrics
        ${whereClause}
        ORDER BY calculation_date DESC
        LIMIT ? OFFSET ?
      `);

      const metrics = stmt.all(...params, parseInt(limit as string), parseInt(offset as string));

      const countStmt = db.prepare(`
        SELECT COUNT(*) as total
        FROM analytics_metrics
        ${whereClause}
      `);
      const { total } = countStmt.get(...params) as { total: number };

      res.json({
        success: true,
        data: metrics,
        pagination: {
          total,
          limit: parseInt(limit as string),
          offset: parseInt(offset as string),
        },
      });
    } catch (error: any) {
      logger.error('Error getting metrics:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get metrics',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/v1/analytics/export/:format
 * @desc    Export analytics data in specified format
 * @access  Private (Admin)
 */
router.get(
  '/export/:format',
  authenticate,
  authorize('Admin'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { format } = req.params;
      const { type = 'dashboard', date_from, date_to } = req.query;

      // Validate format
      const validFormats = ['json', 'csv'];
      if (!validFormats.includes(format.toLowerCase())) {
        return res.status(400).json({
          success: false,
          message: `Invalid format. Must be one of: ${validFormats.join(', ')}`,
        });
      }

      let data: any;
      
      if (type === 'dashboard') {
        data = AnalyticsService.getDashboardData(db, {
          date_from: date_from as string,
          date_to: date_to as string,
        });
      } else if (type === 'qc-metrics') {
        data = AnalyticsService.calculateQCMetrics(db, {
          date_from: date_from as string,
          date_to: date_to as string,
        });
      } else if (type === 'lab-performance') {
        data = AnalyticsService.getLabPerformance(db, {
          date_from: date_from as string,
          date_to: date_to as string,
        });
      } else {
        return res.status(400).json({
          success: false,
          message: 'Invalid export type',
        });
      }

      if (format.toLowerCase() === 'json') {
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-Disposition', `attachment; filename="analytics-${type}-${Date.now()}.json"`);
        return res.json(data);
      } else if (format.toLowerCase() === 'csv') {
        // Simple CSV conversion (for arrays of objects)
        let csvData = '';
        
        if (Array.isArray(data)) {
          if (data.length > 0) {
            const headers = Object.keys(data[0]);
            csvData = headers.join(',') + '\n';
            csvData += data.map(row => headers.map(h => JSON.stringify(row[h] || '')).join(',')).join('\n');
          }
        } else {
          // Convert object to CSV
          csvData = Object.entries(data).map(([key, value]) => `${key},${JSON.stringify(value)}`).join('\n');
        }

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename="analytics-${type}-${Date.now()}.csv"`);
        return res.send(csvData);
      }
    } catch (error: any) {
      logger.error('Error exporting data:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to export data',
        error: error.message,
      });
    }
  }
);

export default router;
