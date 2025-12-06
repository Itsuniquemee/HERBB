import { FabricClient } from './fabricClient';
import { logger } from '../utils/logger';

// Singleton instance
let fabricClientInstance: FabricClient | null = null;

/**
 * Get or create FabricClient singleton instance
 */
export function getFabricClient(): FabricClient {
  if (!fabricClientInstance) {
    fabricClientInstance = new FabricClient();
    logger.info('FabricClient singleton instance created');
  }
  return fabricClientInstance;
}

/**
 * Initialize connection for a user
 * This should be called after authentication
 */
export async function connectUser(userId: string, orgName: string): Promise<void> {
  const client = getFabricClient();
  await client.connect(userId, orgName);
}

/**
 * Disconnect from the Fabric network
 */
export async function disconnect(): Promise<void> {
  if (fabricClientInstance) {
    await fabricClientInstance.disconnect();
    fabricClientInstance = null;
  }
}

/**
 * Submit a transaction to the blockchain
 */
export async function submitTransaction(functionName: string, ...args: string[]): Promise<any> {
  const client = getFabricClient();
  return await client.submitTransaction(functionName, ...args);
}

/**
 * Query the blockchain (read-only)
 */
export async function evaluateTransaction(functionName: string, ...args: string[]): Promise<any> {
  const client = getFabricClient();
  return await client.evaluateTransaction(functionName, ...args);
}

/**
 * Check if connected
 */
export function isConnected(): boolean {
  return fabricClientInstance !== null;
}

export { FabricClient };
