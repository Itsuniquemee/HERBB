import Database from 'better-sqlite3';
import { db } from '../config/database';
import { logger } from '../utils/logger';
import { v4 as uuidv4 } from 'uuid';

interface MetricFilter {
  metric_type?: string;
  entity_id?: string;
  entity_type?: string;
  date_from?: string;
  date_to?: string;
}

interface QCMetrics {
  total_tests: number;
  completed_tests: number;
  passed_tests: number;
  failed_tests: number;
  success_rate: number;
  avg_completion_time: number;
  total_cost: number;
}

interface LabPerformance {
  lab_id: string;
  lab_name: string;
  total_tests: number;
  completed_tests: number;
  avg_completion_time: number;
  success_rate: number;
  on_time_rate: number;
  total_cost: number;
}

interface BatchQualityScore {
  batch_id: string;
  quality_score: number;
  qc_tests_passed: number;
  qc_tests_total: number;
  compliance_status: string;
  risk_level: string;
}

interface TrendData {
  period: string;
  metric_value: number;
  entity_count: number;
}

export class AnalyticsService {
  /**
   * Calculate QC metrics for a given period
   */
  static calculateQCMetrics(
    db: Database.Database,
    filters: MetricFilter = {}
  ): QCMetrics {
    const { date_from, date_to, entity_id } = filters;

    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (date_from) {
      whereClause += ' AND created_at >= ?';
      params.push(date_from);
    }
    if (date_to) {
      whereClause += ' AND created_at <= ?';
      params.push(date_to);
    }
    if (entity_id) {
      whereClause += ' AND lab_id = ?';
      params.push(entity_id);
    }

    const stmt = db.prepare(`
      SELECT 
        COUNT(*) as total_tests,
        SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) as completed_tests,
        SUM(CASE WHEN t.status = 'completed' AND NOT EXISTS (
          SELECT 1 FROM qc_results r WHERE r.test_id = t.id AND r.pass_fail = 'FAIL'
        ) THEN 1 ELSE 0 END) as passed_tests,
        SUM(CASE WHEN EXISTS (
          SELECT 1 FROM qc_results r WHERE r.test_id = t.id AND r.pass_fail = 'FAIL'
        ) THEN 1 ELSE 0 END) as failed_tests,
        AVG(CASE 
          WHEN t.status = 'completed' AND t.completed_at IS NOT NULL 
          THEN (julianday(t.completed_at) - julianday(t.requested_at)) * 24 
        END) as avg_completion_time,
        SUM(t.cost) as total_cost
      FROM qc_tests t
      ${whereClause.replace(/created_at/g, 't.requested_at').replace(/lab_id/g, 't.lab_id')}
    `);

    const result: any = stmt.get(...params);
    
    const success_rate = result.completed_tests > 0 
      ? (result.passed_tests / result.completed_tests) * 100 
      : 0;

    const metrics: QCMetrics = {
      total_tests: result.total_tests || 0,
      completed_tests: result.completed_tests || 0,
      passed_tests: result.passed_tests || 0,
      failed_tests: result.failed_tests || 0,
      success_rate: Math.round(success_rate * 100) / 100,
      avg_completion_time: Math.round((result.avg_completion_time || 0) * 100) / 100,
      total_cost: result.total_cost || 0,
    };

    // Store metric in analytics_metrics table
    this.storeMetric(db, {
      metric_type: 'QC_SUCCESS_RATE',
      entity_type: entity_id ? 'LAB' : 'SYSTEM',
      entity_id: entity_id || 'SYSTEM',
      metric_value: metrics.success_rate,
      metric_unit: 'PERCENTAGE',
      date_from,
      date_to,
      metadata: JSON.stringify(metrics),
    });

    logger.info('QC metrics calculated', { metrics, filters });
    return metrics;
  }

  /**
   * Get lab performance metrics
   */
  static getLabPerformance(
    db: Database.Database,
    filters: MetricFilter = {}
  ): LabPerformance[] {
    const { date_from, date_to } = filters;

    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (date_from) {
      whereClause += ' AND t.created_at >= ?';
      params.push(date_from);
    }
    if (date_to) {
      whereClause += ' AND t.created_at <= ?';
      params.push(date_to);
    }

    const stmt = db.prepare(`
      SELECT 
        t.lab_id,
        t.lab_name,
        COUNT(*) as total_tests,
        SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) as completed_tests,
        AVG(CASE 
          WHEN t.status = 'completed' AND t.completed_at IS NOT NULL 
          THEN (julianday(t.completed_at) - julianday(t.requested_at)) * 24 
        END) as avg_completion_time,
        SUM(CASE WHEN t.status = 'completed' AND NOT EXISTS (
          SELECT 1 FROM qc_results r WHERE r.test_id = t.id AND r.pass_fail = 'FAIL'
        ) THEN 1 ELSE 0 END) as passed_tests,
        SUM(CASE 
          WHEN t.status = 'completed' AND t.completed_at <= t.due_date THEN 1 
          ELSE 0 
        END) as on_time_tests,
        SUM(t.cost) as total_cost
      FROM qc_tests t
      ${whereClause.replace(/created_at/g, 't.requested_at')}
      GROUP BY t.lab_id, t.lab_name
      ORDER BY completed_tests DESC
    `);

    const results: any[] = stmt.all(...params);

    const performance: LabPerformance[] = results.map((row) => {
      const success_rate = row.completed_tests > 0 
        ? (row.passed_tests / row.completed_tests) * 100 
        : 0;
      const on_time_rate = row.completed_tests > 0 
        ? (row.on_time_tests / row.completed_tests) * 100 
        : 0;

      const perf: LabPerformance = {
        lab_id: row.lab_id,
        lab_name: row.lab_name,
        total_tests: row.total_tests,
        completed_tests: row.completed_tests,
        avg_completion_time: Math.round((row.avg_completion_time || 0) * 100) / 100,
        success_rate: Math.round(success_rate * 100) / 100,
        on_time_rate: Math.round(on_time_rate * 100) / 100,
        total_cost: row.total_cost || 0,
      };

      // Store lab performance metric
      this.storeMetric(db, {
        metric_type: 'LAB_PERFORMANCE',
        entity_type: 'LAB',
        entity_id: row.lab_id,
        metric_value: success_rate,
        metric_unit: 'PERCENTAGE',
        date_from,
        date_to,
        metadata: JSON.stringify(perf),
      });

      return perf;
    });

    logger.info(`Lab performance calculated for ${performance.length} labs`);
    return performance;
  }

  /**
   * Calculate batch quality scores
   */
  static getBatchQualityScores(
    db: Database.Database,
    filters: { batch_id?: string; date_from?: string; date_to?: string } = {}
  ): BatchQualityScore[] {
    const { batch_id, date_from, date_to } = filters;

    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (batch_id) {
      whereClause += ' AND b.id = ?';
      params.push(batch_id);
    }
    if (date_from) {
      whereClause += ' AND b.created_at >= ?';
      params.push(date_from);
    }
    if (date_to) {
      whereClause += ' AND b.created_at <= ?';
      params.push(date_to);
    }

    const stmt = db.prepare(`
      SELECT 
        b.id as batch_id,
        b.batch_number,
        COUNT(t.id) as total_tests,
        SUM(CASE WHEN t.status = 'completed' AND NOT EXISTS (
          SELECT 1 FROM qc_results r WHERE r.test_id = t.id AND r.pass_fail = 'FAIL'
        ) THEN 1 ELSE 0 END) as passed_tests,
        SUM(CASE WHEN EXISTS (
          SELECT 1 FROM qc_results r WHERE r.test_id = t.id AND r.pass_fail = 'FAIL'
        ) THEN 1 ELSE 0 END) as failed_tests,
        SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) as completed_tests
      FROM batches b
      LEFT JOIN qc_tests t ON b.id = t.batch_id
      ${whereClause}
      GROUP BY b.id, b.batch_number
      HAVING total_tests > 0
    `);

    const results: any[] = stmt.all(...params);

    const scores: BatchQualityScore[] = results.map((row) => {
      const pass_rate = row.completed_tests > 0 
        ? (row.passed_tests / row.completed_tests) * 100 
        : 0;
      
      // Calculate quality score (0-100)
      let quality_score = pass_rate;
      
      // Determine compliance status
      let compliance_status = 'UNKNOWN';
      if (row.completed_tests === row.total_tests) {
        compliance_status = pass_rate === 100 ? 'FULLY_COMPLIANT' : 
                           pass_rate >= 80 ? 'MOSTLY_COMPLIANT' : 
                           pass_rate >= 50 ? 'PARTIALLY_COMPLIANT' : 'NON_COMPLIANT';
      } else {
        compliance_status = 'TESTING_IN_PROGRESS';
      }

      // Determine risk level
      let risk_level = 'UNKNOWN';
      if (row.completed_tests === row.total_tests) {
        risk_level = pass_rate === 100 ? 'LOW' : 
                     pass_rate >= 80 ? 'MEDIUM' : 
                     pass_rate >= 50 ? 'HIGH' : 'CRITICAL';
      }

      const score: BatchQualityScore = {
        batch_id: row.batch_id,
        quality_score: Math.round(quality_score * 100) / 100,
        qc_tests_passed: row.passed_tests,
        qc_tests_total: row.total_tests,
        compliance_status,
        risk_level,
      };

      // Store batch quality metric
      this.storeMetric(db, {
        metric_type: 'BATCH_QUALITY_SCORE',
        entity_type: 'BATCH',
        entity_id: row.batch_id,
        metric_value: quality_score,
        metric_unit: 'SCORE',
        date_from,
        date_to,
        metadata: JSON.stringify(score),
      });

      return score;
    });

    logger.info(`Batch quality scores calculated for ${scores.length} batches`);
    return scores;
  }

  /**
   * Get trend data for metrics over time
   */
  static getTrendData(
    db: Database.Database,
    metric_type: string,
    period: 'DAY' | 'WEEK' | 'MONTH' | 'QUARTER',
    filters: MetricFilter = {}
  ): TrendData[] {
    const { entity_id, entity_type, date_from, date_to } = filters;

    let whereClause = 'WHERE metric_type = ?';
    const params: any[] = [metric_type];

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

    let dateFormat = '';
    switch (period) {
      case 'DAY':
        dateFormat = "strftime('%Y-%m-%d', calculation_date)";
        break;
      case 'WEEK':
        dateFormat = "strftime('%Y-W%W', calculation_date)";
        break;
      case 'MONTH':
        dateFormat = "strftime('%Y-%m', calculation_date)";
        break;
      case 'QUARTER':
        dateFormat = "strftime('%Y', calculation_date) || '-Q' || ((CAST(strftime('%m', calculation_date) AS INTEGER) - 1) / 3 + 1)";
        break;
    }

    const stmt = db.prepare(`
      SELECT 
        ${dateFormat} as period,
        AVG(metric_value) as metric_value,
        COUNT(*) as entity_count
      FROM analytics_metrics
      ${whereClause}
      GROUP BY period
      ORDER BY period ASC
    `);

    const results: any[] = stmt.all(...params);

    const trends: TrendData[] = results.map((row) => ({
      period: row.period,
      metric_value: Math.round((row.metric_value || 0) * 100) / 100,
      entity_count: row.entity_count,
    }));

    logger.info(`Trend data calculated for ${metric_type}`, { period, count: trends.length });
    return trends;
  }

  /**
   * Get comprehensive dashboard data
   */
  static getDashboardData(
    db: Database.Database,
    filters: MetricFilter = {}
  ): any {
    const qcMetrics = this.calculateQCMetrics(db, filters);
    const labPerformance = this.getLabPerformance(db, filters);
    const batchScores = this.getBatchQualityScores(db, filters);

    // Get recent trends
    const successRateTrend = this.getTrendData(db, 'QC_SUCCESS_RATE', 'WEEK', filters);
    
    // Calculate system-wide stats
    const systemStats = {
      total_batches_tested: batchScores.length,
      avg_quality_score: batchScores.length > 0 
        ? Math.round((batchScores.reduce((sum, b) => sum + b.quality_score, 0) / batchScores.length) * 100) / 100
        : 0,
      high_risk_batches: batchScores.filter(b => b.risk_level === 'HIGH' || b.risk_level === 'CRITICAL').length,
      active_labs: labPerformance.length,
    };

    const dashboard = {
      qc_metrics: qcMetrics,
      lab_performance: labPerformance.slice(0, 10), // Top 10 labs
      batch_quality_scores: batchScores.slice(0, 20), // Top 20 recent batches
      success_rate_trend: successRateTrend,
      system_stats: systemStats,
      generated_at: new Date().toISOString(),
    };

    // Cache dashboard data
    this.cacheDashboardData(db, 'main_dashboard', dashboard, filters);

    logger.info('Dashboard data generated');
    return dashboard;
  }

  /**
   * Store a calculated metric
   */
  private static storeMetric(
    db: Database.Database,
    metric: {
      metric_type: string;
      entity_id: string;
      entity_type: string;
      metric_value: number;
      metric_unit?: string;
      date_from?: string;
      date_to?: string;
      metadata?: string;
    }
  ): void {
    const id = `METRIC-${uuidv4()}`;

    const stmt = db.prepare(`
      INSERT INTO analytics_metrics (
        id, metric_type, entity_id, entity_type, metric_value, 
        metric_unit, date_from, date_to, metadata
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      metric.metric_type,
      metric.entity_id,
      metric.entity_type,
      metric.metric_value,
      metric.metric_unit || 'UNIT',
      metric.date_from || null,
      metric.date_to || null,
      metric.metadata || null
    );
  }

  /**
   * Cache dashboard data for performance
   */
  private static cacheDashboardData(
    db: Database.Database,
    cache_key: string,
    data: any,
    filters: MetricFilter = {}
  ): void {
    const id = `CACHE-${uuidv4()}`;
    const fullKey = `${cache_key}_${JSON.stringify(filters)}`;
    
    // Cache expires in 1 hour
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();

    // Delete old cache for this key
    db.prepare('DELETE FROM dashboard_cache WHERE cache_key = ?').run(fullKey);

    // Insert new cache
    const stmt = db.prepare(`
      INSERT INTO dashboard_cache (id, cache_key, cache_data, expires_at)
      VALUES (?, ?, ?, ?)
    `);

    stmt.run(id, fullKey, JSON.stringify(data), expiresAt);
  }

  /**
   * Get cached dashboard data
   */
  static getCachedDashboardData(
    db: Database.Database,
    cache_key: string,
    filters: MetricFilter = {}
  ): any | null {
    const fullKey = `${cache_key}_${JSON.stringify(filters)}`;

    const stmt = db.prepare(`
      SELECT cache_data
      FROM dashboard_cache
      WHERE cache_key = ? AND expires_at > datetime('now')
    `);

    const result: any = stmt.get(fullKey);

    if (result) {
      logger.info('Dashboard data retrieved from cache');
      return JSON.parse(result.cache_data);
    }

    return null;
  }

  /**
   * Clean expired cache entries
   */
  static cleanExpiredCache(db: Database.Database): number {
    const stmt = db.prepare(`
      DELETE FROM dashboard_cache WHERE expires_at <= datetime('now')
    `);

    const result = stmt.run();
    const deleted = result.changes;

    logger.info(`Cleaned ${deleted} expired cache entries`);
    return deleted;
  }

  /**
   * Get cost analysis data
   */
  static getCostAnalysis(
    db: Database.Database,
    filters: { date_from?: string; date_to?: string; lab_id?: string } = {}
  ): any {
    const { date_from, date_to, lab_id } = filters;

    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (date_from) {
      whereClause += ' AND created_at >= ?';
      params.push(date_from);
    }
    if (date_to) {
      whereClause += ' AND created_at <= ?';
      params.push(date_to);
    }
    if (lab_id) {
      whereClause += ' AND lab_id = ?';
      params.push(lab_id);
    }

    const stmt = db.prepare(`
      SELECT 
        COUNT(*) as total_tests,
        SUM(cost) as total_cost,
        AVG(cost) as avg_cost_per_test,
        test_type,
        lab_id,
        lab_name
      FROM qc_tests
      ${whereClause.replace(/created_at/g, 'requested_at')}
      GROUP BY test_type, lab_id, lab_name
      ORDER BY total_cost DESC
    `);

    const results: any[] = stmt.all(...params);

    const totalCost = results.reduce((sum, row) => sum + (row.total_cost || 0), 0);
    const totalTests = results.reduce((sum, row) => sum + row.total_tests, 0);

    return {
      total_tests: totalTests,
      total_cost: Math.round(totalCost * 100) / 100,
      avg_cost_per_test: totalTests > 0 ? Math.round((totalCost / totalTests) * 100) / 100 : 0,
      breakdown: results.map(row => ({
        test_type: row.test_type,
        lab_id: row.lab_id,
        lab_name: row.lab_name,
        total_tests: row.total_tests,
        total_cost: Math.round((row.total_cost || 0) * 100) / 100,
        avg_cost: Math.round((row.avg_cost_per_test || 0) * 100) / 100,
      })),
    };
  }
}

export default AnalyticsService;
