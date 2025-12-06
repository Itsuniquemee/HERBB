import { Gateway, Wallets, X509Identity } from 'fabric-network';
import * as path from 'path';
import * as fs from 'fs';
import FabricCAServices from 'fabric-ca-client';
import { logger } from '../utils/logger';

export class FabricClient {
  private gateway: Gateway | null = null;
  private wallet: any = null;
  private walletInitialized: boolean = false;
  private readonly channelName: string = 'herbaltrace-channel';
  private readonly chaincodeName: string = 'herbaltrace';

  constructor() {
    // Don't call async in constructor
  }

  private async initializeWallet() {
    if (this.walletInitialized) {
      return;
    }
    try {
      const walletPath = path.resolve(__dirname, '../../../network/wallet');
      
      // Verify wallet directory exists
      if (!fs.existsSync(walletPath)) {
        throw new Error(`Wallet directory not found: ${walletPath}`);
      }
      
      this.wallet = await Wallets.newFileSystemWallet(walletPath);
      this.walletInitialized = true;
      
      // List available identities for debugging
      const identities = await this.wallet.list();
      logger.info(`✅ Wallet initialized at: ${walletPath}`);
      logger.info(`Available identities: ${identities.map((id: any) => id.label).join(', ')}`);
    } catch (error) {
      logger.error('Failed to initialize wallet:', error);
      throw error;
    }
  }

  /**
   * Connect to the Fabric gateway
   */
  async connect(userId: string, orgName: string): Promise<void> {
    try {
      logger.info(`🔍 Attempting to connect to Fabric network...`);
      logger.info(`User: ${userId}, Organization: ${orgName}`);
      
      // Ensure wallet is initialized
      await this.initializeWallet();

      // Load connection profile
      const ccpPath = this.getCCPPath(orgName);
      logger.info(`📄 Loading connection profile: ${ccpPath}`);
      const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

      // Check identity in wallet
      logger.info(`🔑 Looking for identity: ${userId}`);
      const identity = await this.wallet.get(userId);
      if (!identity) {
        const available = await this.wallet.list();
        throw new Error(`Identity '${userId}' not found. Available: ${available.map((id: any) => id.label).join(', ')}`);
      }
      logger.info(`✅ Identity found: ${userId} (MSP: ${(identity as any).mspId})`);

      // Create gateway connection (disable discovery as service may not be available)
      this.gateway = new Gateway();
      logger.info(`🌐 Connecting to gateway with discovery disabled (asLocalhost: true)...`);
      
      await this.gateway.connect(ccp, {
        wallet: this.wallet,
        identity: userId,
        discovery: { enabled: false, asLocalhost: true }
      });

      logger.info(`✅ Successfully connected to Fabric network as ${userId} from ${orgName}`);
    } catch (error) {
      logger.error('❌ Failed to connect to Fabric network:', error);
      throw error;
    }
  }

  /**
   * Get connection profile path based on organization
   */
  private getCCPPath(orgName: string): string {
    const basePath = path.resolve(__dirname, '../../../network/organizations/peerOrganizations');
    
    const orgMap: { [key: string]: { domain: string, profile: string } } = {
      'FarmersCoop': { domain: 'farmerscoop.herbaltrace.com', profile: 'farmerscoop' },
      'TestingLabs': { domain: 'testinglabs.herbaltrace.com', profile: 'testinglabs' },
      'Processors': { domain: 'processors.herbaltrace.com', profile: 'processors' },
      'Manufacturers': { domain: 'manufacturers.herbaltrace.com', profile: 'manufacturers' }
    };

    const orgConfig = orgMap[orgName];
    if (!orgConfig) {
      throw new Error(`Unknown organization: ${orgName}`);
    }

    const ccpPath = path.join(basePath, orgConfig.domain, `connection-${orgConfig.profile}.json`);
    
    // Verify file exists
    if (!fs.existsSync(ccpPath)) {
      throw new Error(`Connection profile not found: ${ccpPath}`);
    }

    logger.info(`Using connection profile: ${ccpPath}`);
    return ccpPath;
  }

  /**
   * Get network channel
   */
  private async getNetwork() {
    if (!this.gateway) {
      throw new Error('Gateway not connected');
    }
    return await this.gateway.getNetwork(this.channelName);
  }

  /**
   * Get chaincode contract
   */
  private async getContract() {
    const network = await this.getNetwork();
    return network.getContract(this.chaincodeName);
  }

  /**
   * Submit a transaction to the ledger
   * Uses endorsement from the connected organization's peers
   */
  async submitTransaction(functionName: string, ...args: string[]): Promise<any> {
    try {
      const contract = await this.getContract();
      
      // Create transaction and set endorsement to use ANY strategy
      // This allows the SDK to use whatever peers are available
      const transaction = contract.createTransaction(functionName);
      
      // Set endorsement to be more flexible - use endorsing peers from connection profile
      // The SDK will automatically select appropriate peers based on the policy
      const result = await transaction.submit(...args);
      
      logger.info(`Transaction ${functionName} submitted successfully`);
      
      // Get transaction ID from the transaction
      const txId = transaction.getTransactionId();
      
      // Parse result if it's JSON
      let parsedResult = null;
      if (result && result.length > 0) {
        try {
          parsedResult = JSON.parse(result.toString());
        } catch {
          parsedResult = result.toString();
        }
      }
      
      // Return both the result and transaction ID
      return {
        ...parsedResult,
        transactionId: txId
      };
    } catch (error) {
      logger.error(`Failed to submit transaction ${functionName}:`, error);
      throw error;
    }
  }

  /**
   * Evaluate a transaction (query)
   */
  async evaluateTransaction(functionName: string, ...args: string[]): Promise<any> {
    try {
      const contract = await this.getContract();
      const result = await contract.evaluateTransaction(functionName, ...args);
      return result.toString() ? JSON.parse(result.toString()) : null;
    } catch (error) {
      logger.error(`Failed to evaluate transaction ${functionName}:`, error);
      throw error;
    }
  }

  /**
   * Create Collection Event
   */
  async createCollectionEvent(eventData: any): Promise<any> {
    return await this.submitTransaction('CreateCollectionEvent', JSON.stringify(eventData));
  }

  /**
   * Get Collection Event by ID
   */
  async getCollectionEvent(id: string): Promise<any> {
    return await this.evaluateTransaction('GetCollectionEvent', id);
  }

  /**
   * Query collections by farmer
   */
  async queryCollectionsByFarmer(farmerId: string): Promise<any[]> {
    return await this.evaluateTransaction('QueryCollectionsByFarmer', farmerId);
  }

  /**
   * Query collections by species
   */
  async queryCollectionsBySpecies(species: string): Promise<any[]> {
    return await this.evaluateTransaction('QueryCollectionsBySpecies', species);
  }

  /**
   * Create Quality Test
   */
  async createQualityTest(testData: any): Promise<any> {
    return await this.submitTransaction('CreateQualityTest', JSON.stringify(testData));
  }

  /**
   * Get Quality Test by ID
   */
  async getQualityTest(id: string): Promise<any> {
    return await this.evaluateTransaction('GetQualityTest', id);
  }

  /**
   * Create Processing Step
   */
  async createProcessingStep(stepData: any): Promise<any> {
    return await this.submitTransaction('CreateProcessingStep', JSON.stringify(stepData));
  }

  /**
   * Get Processing Step by ID
   */
  async getProcessingStep(id: string): Promise<any> {
    return await this.evaluateTransaction('GetProcessingStep', id);
  }

  /**
   * Create Product
   */
  async createProduct(productData: any): Promise<any> {
    return await this.submitTransaction('CreateProduct', JSON.stringify(productData));
  }

  /**
   * Get Product by ID
   */
  async getProduct(id: string): Promise<any> {
    return await this.evaluateTransaction('GetProduct', id);
  }

  /**
   * Get Product by QR Code
   */
  async getProductByQRCode(qrCode: string): Promise<any> {
    return await this.evaluateTransaction('GetProductByQRCode', qrCode);
  }

  /**
   * Generate Provenance for Product
   */
  async generateProvenance(productId: string): Promise<any> {
    return await this.evaluateTransaction('GenerateProvenance', productId);
  }

  /**
   * Get Provenance by QR Code (Consumer Scanning)
   */
  async getProvenanceByQRCode(qrCode: string): Promise<any> {
    return await this.evaluateTransaction('GetProvenanceByQRCode', qrCode);
  }

  /**
   * Disconnect from gateway
   */
  async disconnect(): Promise<void> {
    if (this.gateway) {
      this.gateway.disconnect();
      this.gateway = null;
      logger.info('Disconnected from Fabric network');
    }
  }

  /**
   * Register and enroll a new user
   */
  async registerUser(userId: string, orgName: string, affiliation: string): Promise<void> {
    try {
      // Ensure wallet is initialized first
      await this.initializeWallet();
      
      // Get CA client
      const ccpPath = this.getCCPPath(orgName);
      const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));
      
      // Map organization names to CA names
      const orgToCaMap: { [key: string]: string } = {
        'farmerscoop': 'farmers',
        'labscoop': 'labs',
        'processorscoop': 'processors',
        'manufacturerscoop': 'manufacturers'
      };
      const caName = orgToCaMap[orgName.toLowerCase()] || orgName.toLowerCase();
      
      const caInfo = ccp.certificateAuthorities[`ca.${caName}.herbaltrace.com`];
      if (!caInfo) {
        throw new Error(`CA info not found for ca.${caName}.herbaltrace.com`);
      }
      
      const caTLSCACerts = caInfo.tlsCACerts.pem || fs.readFileSync(caInfo.tlsCACerts.path, 'utf8');
      const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

      // Check if user already exists
      const userIdentity = await this.wallet.get(userId);
      if (userIdentity) {
        logger.info(`User ${userId} already exists in wallet`);
        return;
      }

      // Get admin identity for the organization
      const adminIdentityName = `admin-${orgName}`;
      const adminIdentity = await this.wallet.get(adminIdentityName);
      if (!adminIdentity) {
        throw new Error(`Admin identity '${adminIdentityName}' does not exist in wallet. Enroll admin first.`);
      }

      // Build admin user object
      const provider = this.wallet.getProviderRegistry().getProvider(adminIdentity.type);
      const adminUser = await provider.getUserContext(adminIdentity, adminIdentityName);

      // Register user
      const secret = await ca.register({
        affiliation: affiliation,
        enrollmentID: userId,
        role: 'client'
      }, adminUser);

      // Enroll user
      const enrollment = await ca.enroll({
        enrollmentID: userId,
        enrollmentSecret: secret
      });

      const x509Identity: X509Identity = {
        credentials: {
          certificate: enrollment.certificate,
          privateKey: enrollment.key.toBytes()
        },
        mspId: `${orgName}MSP`,
        type: 'X.509'
      };

      await this.wallet.put(userId, x509Identity);
      logger.info(`Successfully registered and enrolled user ${userId}`);
    } catch (error) {
      logger.error(`Failed to register user ${userId}:`, error);
      throw error;
    }
  }
}

// Singleton instance
let fabricClientInstance: FabricClient | null = null;

export const getFabricClient = (): FabricClient => {
  if (!fabricClientInstance) {
    fabricClientInstance = new FabricClient();
  }
  return fabricClientInstance;
};
