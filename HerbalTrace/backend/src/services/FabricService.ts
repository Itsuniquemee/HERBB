import { Gateway, Wallets, Network, Contract, X509Identity } from 'fabric-network';
import * as fs from 'fs';
import * as path from 'path';
import { logger } from '../utils/logger';

export interface FabricConfig {
  channelName: string;
  chaincodeName: string;
  walletPath: string;
  connectionProfilePath: string;
  mspId: string;
  identity: string;
}

export class FabricService {
  private gateway: Gateway | null = null;
  private network: Network | null = null;
  private contract: Contract | null = null;
  private config: FabricConfig;
  private isConnected: boolean = false;

  constructor(config: Partial<FabricConfig> = {}) {
    // Default configuration
    this.config = {
      channelName: config.channelName || 'herbaltrace-channel',
      chaincodeName: config.chaincodeName || 'herbaltrace',
      walletPath: config.walletPath || path.resolve(__dirname, '../../../network/wallet'),
      connectionProfilePath: config.connectionProfilePath || path.resolve(__dirname, '../../../network/organizations/peerOrganizations/farmerscoop.herbaltrace.com/connection-farmerscoop.json'),
      mspId: config.mspId || 'FarmersCoopMSP',
      identity: config.identity || 'admin-FarmersCoop',
    };
  }

  /**
   * Connect to Hyperledger Fabric network
   */
  async connect(): Promise<void> {
    try {
      if (this.isConnected) {
        logger.info('Already connected to Fabric network');
        return;
      }

      logger.info('Connecting to Hyperledger Fabric network...');

      // Load connection profile
      const ccpPath = this.config.connectionProfilePath;
      if (!fs.existsSync(ccpPath)) {
        throw new Error(`Connection profile not found at: ${ccpPath}`);
      }

      const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
      const ccp = JSON.parse(ccpJSON);

      // Create a new file system based wallet for managing identities
      const walletPath = this.config.walletPath;
      if (!fs.existsSync(walletPath)) {
        throw new Error(`Wallet not found at: ${walletPath}`);
      }

      const wallet = await Wallets.newFileSystemWallet(walletPath);

      // Check if identity exists in wallet
      const identity = await wallet.get(this.config.identity);
      if (!identity) {
        throw new Error(`Identity "${this.config.identity}" not found in wallet. Please enroll the identity first.`);
      }

      logger.info(`Using identity: ${this.config.identity} (${this.config.mspId})`);

      // Create a new gateway for connecting to our peer node
      this.gateway = new Gateway();
      await this.gateway.connect(ccp, {
        wallet,
        identity: this.config.identity,
        discovery: { enabled: false },
      });

      // Get the network (channel) our contract is deployed to
      this.network = await this.gateway.getNetwork(this.config.channelName);

      // Get the contract from the network
      this.contract = this.network.getContract(this.config.chaincodeName);

      this.isConnected = true;
      logger.info(`✅ Connected to Fabric network (Channel: ${this.config.channelName}, Chaincode: ${this.config.chaincodeName})`);
    } catch (error: any) {
      logger.error('Failed to connect to Fabric network:', error);
      this.isConnected = false;
      throw new Error(`Fabric connection failed: ${error.message}`);
    }
  }

  /**
   * Disconnect from Fabric network
   */
  async disconnect(): Promise<void> {
    if (this.gateway) {
      await this.gateway.disconnect();
      this.gateway = null;
      this.network = null;
      this.contract = null;
      this.isConnected = false;
      logger.info('Disconnected from Fabric network');
    }
  }

  /**
   * Check if connected to Fabric network
   */
  isNetworkConnected(): boolean {
    return this.isConnected;
  }

  /**
   * Get the contract instance (ensures connection)
   */
  private async getContract(): Promise<Contract> {
    if (!this.isConnected || !this.contract) {
      await this.connect();
    }

    if (!this.contract) {
      throw new Error('Failed to get contract. Network not connected.');
    }

    return this.contract;
  }

  /**
   * Submit a transaction to the ledger
   */
  async submitTransaction(functionName: string, ...args: string[]): Promise<string> {
    try {
      const contract = await this.getContract();
      logger.info(`Submitting transaction: ${functionName}`, { args });

      const result = await contract.submitTransaction(functionName, ...args);
      const response = result.toString();

      logger.info(`Transaction ${functionName} submitted successfully`);
      return response;
    } catch (error: any) {
      logger.error(`Failed to submit transaction ${functionName}:`, error);
      throw new Error(`Transaction failed: ${error.message}`);
    }
  }

  /**
   * Evaluate a transaction (query, read-only)
   */
  async evaluateTransaction(functionName: string, ...args: string[]): Promise<string> {
    try {
      const contract = await this.getContract();
      logger.info(`Evaluating transaction: ${functionName}`, { args });

      const result = await contract.evaluateTransaction(functionName, ...args);
      const response = result.toString();

      logger.info(`Transaction ${functionName} evaluated successfully`);
      return response;
    } catch (error: any) {
      logger.error(`Failed to evaluate transaction ${functionName}:`, error);
      throw new Error(`Query failed: ${error.message}`);
    }
  }

  /**
   * Record QC Certificate on blockchain
   */
  async recordQCCertificate(certificateData: {
    certificateId: string;
    testId: string;
    batchId: string;
    batchNumber: string;
    speciesName: string;
    testType: string;
    labId: string;
    labName: string;
    overallResult: string;
    issuedDate: string;
    testedBy: string;
    results: any[];
  }): Promise<string> {
    const args = [
      certificateData.certificateId,
      certificateData.testId,
      certificateData.batchId,
      certificateData.batchNumber,
      certificateData.speciesName,
      certificateData.testType,
      certificateData.labId,
      certificateData.labName,
      certificateData.overallResult,
      certificateData.issuedDate,
      certificateData.testedBy,
      JSON.stringify(certificateData.results),
    ];

    return await this.submitTransaction('RecordQCCertificate', ...args);
  }

  /**
   * Query QC Certificate from blockchain
   */
  async queryQCCertificate(certificateId: string): Promise<any> {
    const result = await this.evaluateTransaction('QueryQCCertificate', certificateId);
    return JSON.parse(result);
  }

  /**
   * Get certificate history from blockchain
   */
  async getCertificateHistory(certificateId: string): Promise<any[]> {
    const result = await this.evaluateTransaction('GetCertificateHistory', certificateId);
    return JSON.parse(result);
  }

  /**
   * Query certificates by batch
   */
  async queryCertificatesByBatch(batchId: string): Promise<any[]> {
    const result = await this.evaluateTransaction('QueryCertificatesByBatch', batchId);
    return JSON.parse(result);
  }

  /**
   * Get all certificates (paginated)
   */
  async getAllCertificates(pageSize: number = 10, bookmark: string = ''): Promise<any> {
    const result = await this.evaluateTransaction('GetAllCertificates', pageSize.toString(), bookmark);
    return JSON.parse(result);
  }

  /**
   * Verify certificate authenticity
   */
  async verifyCertificate(certificateId: string): Promise<{ valid: boolean; message: string; certificate?: any }> {
    try {
      const certificate = await this.queryQCCertificate(certificateId);
      
      if (!certificate) {
        return {
          valid: false,
          message: 'Certificate not found on blockchain',
        };
      }

      // Check if certificate has been tampered with
      const history = await this.getCertificateHistory(certificateId);
      
      return {
        valid: true,
        message: 'Certificate is authentic and recorded on blockchain',
        certificate: {
          ...certificate,
          recordedAt: history[0]?.timestamp || 'Unknown',
          transactionCount: history.length,
        },
      };
    } catch (error: any) {
      return {
        valid: false,
        message: `Verification failed: ${error.message}`,
      };
    }
  }

  /**
   * Get blockchain network info
   */
  async getNetworkInfo(): Promise<any> {
    try {
      if (!this.network) {
        await this.connect();
      }

      return {
        channelName: this.config.channelName,
        chaincodeName: this.config.chaincodeName,
        mspId: this.config.mspId,
        identity: this.config.identity,
        connected: this.isConnected,
      };
    } catch (error: any) {
      logger.error('Failed to get network info:', error);
      throw error;
    }
  }
}

// Singleton instance
export const fabricService = new FabricService();

export default FabricService;
