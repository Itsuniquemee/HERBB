/**
 * Quality Control Service
 * Manages QC tests, results, and certificates for batches
 */

import Database from 'better-sqlite3';
import { db } from '../config/database';
import { logger } from '../utils/logger';
import { v4 as uuidv4 } from 'uuid';

export interface QCTestTemplate {
  id: string;
  name: string;
  description?: string;
  category: string;
  applicable_species?: string;
  test_method: string;
  parameters: string; // JSON string
  acceptance_criteria: string; // JSON string
  estimated_duration_hours?: number;
  cost?: number;
  required_equipment?: string;
  required_reagents?: string;
  reference_standard?: string;
  is_active: number;
}

export interface QCTest {
  id: string;
  test_number: string;
  batch_id: string;
  template_id?: string;
  lab_id: string;
  lab_name: string;
  test_type: string;
  species: string;
  sample_id?: string;
  sample_quantity?: number;
  sample_unit?: string;
  priority: string;
  status: string;
  requested_by: string;
  requested_at: string;
  assigned_to?: string;
  started_at?: string;
  completed_at?: string;
  due_date?: string;
  test_method?: string;
  equipment_used?: string;
  reagents_used?: string;
  environmental_conditions?: string;
  notes?: string;
  cost?: number;
}

export interface QCTestParameter {
  id?: number;
  test_id: string;
  parameter_name: string;
  parameter_type: string;
  expected_value?: string;
  expected_min?: number;
  expected_max?: number;
  unit?: string;
  description?: string;
}

export interface QCResult {
  id?: number;
  test_id: string;
  parameter_id?: number;
  parameter_name: string;
  measured_value?: string;
  measured_numeric?: number;
  unit?: string;
  pass_fail: string;
  deviation?: number;
  remarks?: string;
  measured_by?: string;
  verified_by?: string;
  verified_at?: string;
}

export interface QCCertificate {
  id: string;
  certificate_number: string;
  test_id: string;
  batch_id: string;
  overall_result: string;
  certificate_data: string; // JSON
  issued_by: string;
  issued_at: string;
  valid_until?: string;
  file_path?: string;
  digital_signature?: string;
}

export class QCService {
  /**
   * Create a new QC test template
   */
  static createTemplate(
    db: Database.Database,
    template: Omit<QCTestTemplate, 'id' | 'created_at' | 'updated_at' | 'created_by'>,
    created_by: string
  ): QCTestTemplate {
    const id = `TPL-${uuidv4()}`;

    const stmt = db.prepare(`
      INSERT INTO qc_test_templates (
        id, name, description, category, applicable_species, test_method,
        parameters, acceptance_criteria, estimated_duration_hours, cost,
        required_equipment, required_reagents, reference_standard, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      template.name,
      template.description,
      template.category,
      template.applicable_species,
      template.test_method,
      template.parameters,
      template.acceptance_criteria,
      template.estimated_duration_hours,
      template.cost,
      template.required_equipment,
      template.required_reagents,
      template.reference_standard,
      created_by
    );

    logger.info(`QC template created: ${id}`);
    return this.getTemplateById(db, id);
  }

  /**
   * Get template by ID
   */
  static getTemplateById(db: Database.Database, id: string): QCTestTemplate {
    const template = db.prepare('SELECT * FROM qc_test_templates WHERE id = ?').get(id) as QCTestTemplate;
    if (!template) {
      throw new Error('QC template not found');
    }
    return template;
  }

  /**
   * List all active templates
   */
  static listTemplates(db: Database.Database, filters?: { category?: string; species?: string }): QCTestTemplate[] {
    let query = 'SELECT * FROM qc_test_templates WHERE is_active = 1';
    const params: any[] = [];

    if (filters?.category) {
      query += ' AND category = ?';
      params.push(filters.category);
    }

    if (filters?.species) {
      query += ' AND (applicable_species IS NULL OR applicable_species LIKE ?)';
      params.push(`%${filters.species}%`);
    }

    query += ' ORDER BY category, name';

    return db.prepare(query).all(...params) as QCTestTemplate[];
  }

  /**
   * Create a new QC test for a batch
   */
  static createTest(
    db: Database.Database,
    testData: {
      batch_id: string;
      template_id?: string;
      lab_id: string;
      lab_name: string;
      test_type: string;
      species: string;
      sample_quantity?: number;
      sample_unit?: string;
      priority?: string;
      requested_by: string;
      due_date?: string;
      notes?: string;
      parameters?: QCTestParameter[];
    }
  ): QCTest {
    const id = `QCT-${uuidv4()}`;
    const testNumber = `QC-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;
    const sampleId = `SMPL-${Date.now()}-${Math.random().toString(36).substr(2, 4).toUpperCase()}`;

    // Verify batch exists
    const batch = db.prepare('SELECT id, species FROM batches WHERE id = ?').get(testData.batch_id);
    if (!batch) {
      throw new Error('Batch not found');
    }

    // Get template data if provided
    let templateData: QCTestTemplate | null = null;
    if (testData.template_id) {
      templateData = this.getTemplateById(db, testData.template_id);
    }

    const stmt = db.prepare(`
      INSERT INTO qc_tests (
        id, test_number, batch_id, template_id, lab_id, lab_name,
        test_type, species, sample_id, sample_quantity, sample_unit,
        priority, status, requested_by, due_date, notes,
        test_method, cost
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      testNumber,
      testData.batch_id,
      testData.template_id,
      testData.lab_id,
      testData.lab_name,
      testData.test_type,
      testData.species,
      sampleId,
      testData.sample_quantity,
      testData.sample_unit,
      testData.priority || 'NORMAL',
      'pending',
      testData.requested_by,
      testData.due_date,
      testData.notes,
      templateData?.test_method,
      templateData?.cost
    );

    // Add parameters
    const parameters = testData.parameters || (templateData ? JSON.parse(templateData.parameters) : []);
    if (parameters.length > 0) {
      const paramStmt = db.prepare(`
        INSERT INTO qc_test_parameters (
          test_id, parameter_name, parameter_type, expected_value,
          expected_min, expected_max, unit, description
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `);

      for (const param of parameters) {
        paramStmt.run(
          id,
          param.parameter_name,
          param.parameter_type,
          param.expected_value,
          param.expected_min,
          param.expected_max,
          param.unit,
          param.description
        );
      }
    }

    // Create alert for lab
    db.prepare(`
      INSERT INTO alerts (
        alert_type, severity, entity_type, entity_id, title, message,
        assigned_to, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      'SYSTEM_ALERT',
      'INFO',
      'test',
      id,
      'New QC Test Assigned',
      `QC test ${testNumber} for batch ${testData.batch_id} has been assigned to your lab.`,
      testData.lab_id,
      'pending'
    );

    logger.info(`QC test created: ${id} for batch ${testData.batch_id}`);
    return this.getTestById(db, id);
  }

  /**
   * Get test by ID with parameters
   */
  static getTestById(db: Database.Database, id: string): any {
    const test = db.prepare('SELECT * FROM qc_tests WHERE id = ?').get(id);
    if (!test) {
      throw new Error('QC test not found');
    }

    const parameters = db.prepare('SELECT * FROM qc_test_parameters WHERE test_id = ?').all(id);
    const results = db.prepare('SELECT * FROM qc_results WHERE test_id = ?').all(id);

    return {
      ...test,
      parameters,
      results,
    };
  }

  /**
   * List QC tests with filters
   */
  static listTests(
    db: Database.Database,
    filters?: {
      batch_id?: string;
      lab_id?: string;
      status?: string;
      test_type?: string;
      limit?: number;
      offset?: number;
    }
  ): { tests: any[]; total: number } {
    let query = 'SELECT * FROM qc_tests WHERE 1=1';
    let countQuery = 'SELECT COUNT(*) as total FROM qc_tests WHERE 1=1';
    const params: any[] = [];

    if (filters?.batch_id) {
      query += ' AND batch_id = ?';
      countQuery += ' AND batch_id = ?';
      params.push(filters.batch_id);
    }

    if (filters?.lab_id) {
      query += ' AND lab_id = ?';
      countQuery += ' AND lab_id = ?';
      params.push(filters.lab_id);
    }

    if (filters?.status) {
      query += ' AND status = ?';
      countQuery += ' AND status = ?';
      params.push(filters.status);
    }

    if (filters?.test_type) {
      query += ' AND test_type = ?';
      countQuery += ' AND test_type = ?';
      params.push(filters.test_type);
    }

    const total = (db.prepare(countQuery).get(...params) as { total: number }).total;

    query += ' ORDER BY requested_at DESC';

    if (filters?.limit) {
      query += ' LIMIT ?';
      params.push(filters.limit);
    }

    if (filters?.offset) {
      query += ' OFFSET ?';
      params.push(filters.offset);
    }

    const tests = db.prepare(query).all(...params);

    return { tests, total };
  }

  /**
   * Update test status
   */
  static updateTestStatus(
    db: Database.Database,
    testId: string,
    status: string,
    updatedBy: string,
    notes?: string
  ): QCTest {
    const test = db.prepare('SELECT * FROM qc_tests WHERE id = ?').get(testId) as QCTest;
    if (!test) {
      throw new Error('QC test not found');
    }

    const updates: string[] = ['status = ?'];
    const params: any[] = [status];

    if (status === 'in_progress' && !test.started_at) {
      updates.push('started_at = datetime("now")');
      updates.push('assigned_to = ?');
      params.push(updatedBy);
    }

    if (status === 'completed' || status === 'failed') {
      updates.push('completed_at = datetime("now")');
    }

    if (notes) {
      updates.push('notes = COALESCE(notes, "") || ? || char(10)');
      params.push(`[${new Date().toISOString()}] ${notes}\n`);
    }

    params.push(testId);

    db.prepare(`UPDATE qc_tests SET ${updates.join(', ')} WHERE id = ?`).run(...params);

    logger.info(`QC test ${testId} status updated to ${status}`);
    return this.getTestById(db, testId);
  }

  /**
   * Record test results
   */
  static recordResults(
    db: Database.Database,
    testId: string,
    results: Omit<QCResult, 'id' | 'test_id' | 'measured_at'>[],
    measuredBy: string
  ): QCResult[] {
    const test = db.prepare('SELECT * FROM qc_tests WHERE id = ?').get(testId);
    if (!test) {
      throw new Error('QC test not found');
    }

    const stmt = db.prepare(`
      INSERT INTO qc_results (
        test_id, parameter_id, parameter_name, measured_value,
        measured_numeric, unit, pass_fail, deviation, remarks, measured_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    for (const result of results) {
      stmt.run(
        testId,
        result.parameter_id,
        result.parameter_name,
        result.measured_value,
        result.measured_numeric,
        result.unit,
        result.pass_fail,
        result.deviation,
        result.remarks,
        measuredBy
      );
    }

    // Check if all parameters have results
    const parameters = db.prepare('SELECT COUNT(*) as total FROM qc_test_parameters WHERE test_id = ?').get(testId) as { total: number };
    const recordedResults = db.prepare('SELECT COUNT(DISTINCT parameter_name) as total FROM qc_results WHERE test_id = ?').get(testId) as { total: number };

    if (recordedResults.total >= parameters.total) {
      this.updateTestStatus(db, testId, 'completed', measuredBy);
    }

    logger.info(`Results recorded for QC test ${testId}`);
    return db.prepare('SELECT * FROM qc_results WHERE test_id = ?').all(testId) as QCResult[];
  }

  /**
   * Generate QC certificate (sync version for backward compatibility)
   */
  static generateCertificate(
    db: Database.Database,
    testId: string,
    issuedBy: string,
    validUntil?: string
  ): QCCertificate {
    const test = this.getTestById(db, testId);
    if (!test) {
      throw new Error('QC test not found');
    }

    if (test.status !== 'completed') {
      throw new Error('Cannot generate certificate for incomplete test');
    }

    // Determine overall result
    const failedResults = test.results.filter((r: QCResult) => r.pass_fail === 'FAIL');
    const warningResults = test.results.filter((r: QCResult) => r.pass_fail === 'WARNING');
    
    let overallResult = 'PASS';
    if (failedResults.length > 0) {
      overallResult = 'FAIL';
    } else if (warningResults.length > 0) {
      overallResult = 'CONDITIONAL';
    }

    const id = `CERT-${uuidv4()}`;
    const certificateNumber = `COA-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;

    const certificateData = JSON.stringify({
      test,
      summary: {
        total_parameters: test.parameters.length,
        passed: test.results.filter((r: QCResult) => r.pass_fail === 'PASS').length,
        failed: failedResults.length,
        warnings: warningResults.length,
      },
      issued_at: new Date().toISOString(),
    });

    db.prepare(`
      INSERT INTO qc_certificates (
        id, certificate_number, test_id, batch_id, overall_result,
        certificate_data, issued_by, valid_until
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      id,
      certificateNumber,
      testId,
      test.batch_id,
      overallResult,
      certificateData,
      issuedBy,
      validUntil
    );

    // Create alert if test failed
    if (overallResult === 'FAIL') {
      db.prepare(`
        INSERT INTO alerts (
          alert_type, severity, entity_type, entity_id, title, message, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(
        'QUALITY_TEST_FAILED',
        'HIGH',
        'test',
        testId,
        'QC Test Failed',
        `QC test ${test.test_number} for batch ${test.batch_id} has failed. Certificate: ${certificateNumber}`,
        'active'
      );
    }

    logger.info(`QC certificate generated: ${certificateNumber}`);
    return db.prepare('SELECT * FROM qc_certificates WHERE id = ?').get(id) as QCCertificate;
  }

  /**
   * Generate QC certificate and record on blockchain (async version)
   */
  static async generateCertificateWithBlockchain(
    db: Database.Database,
    testId: string,
    issuedBy: string,
    validUntil?: string
  ): Promise<QCCertificate & { blockchain?: { txid: string; timestamp: string } }> {
    // Generate certificate in database first
    const certificate = this.generateCertificate(db, testId, issuedBy, validUntil);

    try {
      // Import fabricService dynamically to avoid circular dependencies
      const { fabricService } = await import('./FabricService');

      // Get test and batch details
      const test = this.getTestById(db, testId);
      const batch = db.prepare('SELECT * FROM batches WHERE id = ?').get(test.batch_id) as any;

      // Prepare certificate data for blockchain
      const blockchainCertData = {
        certificateId: certificate.id,
        testId: test.id,
        batchId: test.batch_id,
        batchNumber: batch?.batch_number || 'UNKNOWN',
        speciesName: test.species_name,
        testType: test.test_type,
        labId: test.lab_id,
        labName: test.lab_name,
        overallResult: certificate.overall_result,
        issuedDate: certificate.issued_at,
        testedBy: issuedBy,
        results: test.results,
      };

      // Record on blockchain
      const txResponse = await fabricService.recordQCCertificate(blockchainCertData);
      const txData = JSON.parse(txResponse);

      // Update certificate with blockchain transaction ID
      const blockchainTimestamp = new Date().toISOString();
      db.prepare(`
        UPDATE qc_certificates 
        SET blockchain_txid = ?, blockchain_timestamp = ?
        WHERE id = ?
      `).run(txData.txId || 'RECORDED', blockchainTimestamp, certificate.id);

      logger.info(`Certificate ${certificate.certificate_number} recorded on blockchain: ${txData.txId}`);

      return {
        ...certificate,
        blockchain: {
          txid: txData.txId || 'RECORDED',
          timestamp: blockchainTimestamp,
        },
      };
    } catch (blockchainError: any) {
      // Log blockchain error but don't fail certificate generation
      logger.warn(`Failed to record certificate ${certificate.certificate_number} on blockchain:`, blockchainError.message);
      
      return {
        ...certificate,
        blockchain: undefined,
      };
    }
  }

  /**
   * Get test statistics
   */
  static getTestStatistics(db: Database.Database, filters?: { lab_id?: string; date_from?: string; date_to?: string }): any {
    let query = 'SELECT status, test_type, COUNT(*) as count FROM qc_tests WHERE 1=1';
    const params: any[] = [];

    if (filters?.lab_id) {
      query += ' AND lab_id = ?';
      params.push(filters.lab_id);
    }

    if (filters?.date_from) {
      query += ' AND requested_at >= ?';
      params.push(filters.date_from);
    }

    if (filters?.date_to) {
      query += ' AND requested_at <= ?';
      params.push(filters.date_to);
    }

    query += ' GROUP BY status, test_type';

    const stats = db.prepare(query).all(...params);

    // Get overall counts
    const totalQuery = 'SELECT COUNT(*) as total FROM qc_tests WHERE 1=1' + 
      (filters?.lab_id ? ' AND lab_id = ?' : '') +
      (filters?.date_from ? ' AND requested_at >= ?' : '') +
      (filters?.date_to ? ' AND requested_at <= ?' : '');
    
    const total = (db.prepare(totalQuery).get(...params) as { total: number }).total;

    return {
      total,
      by_status: stats,
    };
  }
}

export default QCService;
