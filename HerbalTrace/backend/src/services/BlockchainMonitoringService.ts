import { fabricService } from './FabricService';
import { logger } from '../utils/logger';
import { db } from '../config/database';

export class BlockchainMonitoringService {
  /**
   * Get blockchain information
   */
  static async getBlockchainInfo(): Promise<any> {
    try {
      const networkInfo = await fabricService.getNetworkInfo();
      
      // Get certificate count from database
      const certCountStmt = db.prepare('SELECT COUNT(*) as count FROM qc_certificates WHERE blockchain_txid IS NOT NULL');
      const certCount: any = certCountStmt.get();

      return {
        connected: fabricService.isNetworkConnected(),
        channelName: networkInfo.channelName,
        chaincodeName: networkInfo.chaincodeName,
        mspId: networkInfo.mspId,
        identity: networkInfo.identity,
        certificatesOnChain: certCount.count || 0,
        status: fabricService.isNetworkConnected() ? 'Connected' : 'Disconnected',
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      logger.error('Failed to get blockchain info:', error);
      throw error;
    }
  }

  /**
   * Get recent blockchain transactions
   */
  static async getRecentTransactions(limit: number = 20): Promise<any[]> {
    try {
      // Get recent certificates with blockchain records
      const stmt = db.prepare(`
        SELECT 
          c.id,
          c.test_id,
          c.batch_id,
          c.certificate_number,
          c.overall_result,
          c.issued_date,
          c.issued_by,
          c.blockchain_txid,
          c.blockchain_timestamp,
          t.test_type,
          b.batch_number
        FROM qc_certificates c
        LEFT JOIN qc_tests t ON c.test_id = t.id
        LEFT JOIN batches b ON c.batch_id = b.id
        WHERE c.blockchain_txid IS NOT NULL
        ORDER BY c.blockchain_timestamp DESC
        LIMIT ?
      `);

      const transactions: any[] = stmt.all(limit);

      return transactions.map((tx) => ({
        certificateId: tx.id,
        certificateNumber: tx.certificate_number,
        testId: tx.test_id,
        batchId: tx.batch_id,
        batchNumber: tx.batch_number,
        testType: tx.test_type,
        result: tx.overall_result,
        issuedDate: tx.issued_date,
        issuedBy: tx.issued_by,
        transactionId: tx.blockchain_txid,
        timestamp: tx.blockchain_timestamp,
      }));
    } catch (error: any) {
      logger.error('Failed to get recent transactions:', error);
      throw error;
    }
  }

  /**
   * Get blockchain statistics
   */
  static async getBlockchainStats(): Promise<any> {
    try {
      // Total certificates on blockchain
      const totalStmt = db.prepare('SELECT COUNT(*) as count FROM qc_certificates WHERE blockchain_txid IS NOT NULL');
      const total: any = totalStmt.get();

      // Certificates by result
      const byResultStmt = db.prepare(`
        SELECT 
          overall_result,
          COUNT(*) as count
        FROM qc_certificates
        WHERE blockchain_txid IS NOT NULL
        GROUP BY overall_result
      `);
      const byResult: any[] = byResultStmt.all();

      // Certificates by test type
      const byTypeStmt = db.prepare(`
        SELECT 
          t.test_type,
          COUNT(c.id) as count
        FROM qc_certificates c
        LEFT JOIN qc_tests t ON c.test_id = t.id
        WHERE c.blockchain_txid IS NOT NULL
        GROUP BY t.test_type
      `);
      const byType: any[] = byTypeStmt.all();

      // Recent 24 hours
      const recent24hStmt = db.prepare(`
        SELECT COUNT(*) as count 
        FROM qc_certificates 
        WHERE blockchain_txid IS NOT NULL 
        AND blockchain_timestamp >= datetime('now', '-24 hours')
      `);
      const recent24h: any = recent24hStmt.get();

      return {
        totalCertificates: total.count || 0,
        certificatesByResult: byResult,
        certificatesByType: byType,
        last24Hours: recent24h.count || 0,
        networkStatus: fabricService.isNetworkConnected() ? 'Connected' : 'Disconnected',
      };
    } catch (error: any) {
      logger.error('Failed to get blockchain stats:', error);
      throw error;
    }
  }

  /**
   * Verify certificate on blockchain
   */
  static async verifyCertificate(certificateId: string): Promise<any> {
    try {
      // Get certificate from database
      const stmt = db.prepare('SELECT * FROM qc_certificates WHERE id = ?');
      const cert: any = stmt.get(certificateId);

      if (!cert) {
        return {
          valid: false,
          message: 'Certificate not found in database',
          certificateId,
        };
      }

      if (!cert.blockchain_txid) {
        return {
          valid: false,
          message: 'Certificate not recorded on blockchain',
          certificateId,
          certificate: cert,
        };
      }

      // Verify on blockchain
      const blockchainVerification = await fabricService.verifyCertificate(certificateId);

      return {
        ...blockchainVerification,
        certificateId,
        transactionId: cert.blockchain_txid,
        timestamp: cert.blockchain_timestamp,
        databaseRecord: {
          certificateNumber: cert.certificate_number,
          issuedDate: cert.issued_date,
          issuedBy: cert.issued_by,
          overallResult: cert.overall_result,
        },
      };
    } catch (error: any) {
      logger.error(`Failed to verify certificate ${certificateId}:`, error);
      throw error;
    }
  }

  /**
   * Get certificates by batch from blockchain
   */
  static async getCertificatesByBatch(batchId: string): Promise<any> {
    try {
      // Get from database first
      const dbStmt = db.prepare(`
        SELECT * FROM qc_certificates 
        WHERE batch_id = ? AND blockchain_txid IS NOT NULL
        ORDER BY issued_date DESC
      `);
      const dbCerts: any[] = dbStmt.all(batchId);

      // Get from blockchain
      let blockchainCerts: any[] = [];
      try {
        blockchainCerts = await fabricService.queryCertificatesByBatch(batchId);
      } catch (error) {
        logger.warn(`Could not query blockchain for batch ${batchId}:`, error);
      }

      return {
        batchId,
        databaseCount: dbCerts.length,
        blockchainCount: blockchainCerts.length,
        certificates: dbCerts.map((cert) => ({
          certificateId: cert.id,
          certificateNumber: cert.certificate_number,
          testId: cert.test_id,
          overallResult: cert.overall_result,
          issuedDate: cert.issued_date,
          issuedBy: cert.issued_by,
          transactionId: cert.blockchain_txid,
          blockchainTimestamp: cert.blockchain_timestamp,
        })),
      };
    } catch (error: any) {
      logger.error(`Failed to get certificates for batch ${batchId}:`, error);
      throw error;
    }
  }

  /**
   * Get certificate history from blockchain
   */
  static async getCertificateHistory(certificateId: string): Promise<any> {
    try {
      const history = await fabricService.getCertificateHistory(certificateId);

      return {
        certificateId,
        transactionCount: history.length,
        history: history.map((entry: any) => ({
          transactionId: entry.txId,
          timestamp: entry.timestamp,
          isDelete: entry.isDelete,
          value: entry.value ? JSON.parse(entry.value.toString()) : null,
        })),
      };
    } catch (error: any) {
      logger.error(`Failed to get history for certificate ${certificateId}:`, error);
      throw error;
    }
  }

  /**
   * Health check for blockchain connection
   */
  static async healthCheck(): Promise<any> {
    try {
      const isConnected = fabricService.isNetworkConnected();
      
      let networkInfo: any = null;
      if (isConnected) {
        networkInfo = await fabricService.getNetworkInfo();
      }

      return {
        healthy: isConnected,
        status: isConnected ? 'UP' : 'DOWN',
        network: networkInfo,
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      return {
        healthy: false,
        status: 'ERROR',
        error: error.message,
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * Reconnect to blockchain network
   */
  static async reconnect(): Promise<any> {
    try {
      await fabricService.disconnect();
      await fabricService.connect();

      return {
        success: true,
        message: 'Reconnected to blockchain network',
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      logger.error('Failed to reconnect to blockchain:', error);
      throw error;
    }
  }
}

export const blockchainMonitoringService = BlockchainMonitoringService;
export default BlockchainMonitoringService;
