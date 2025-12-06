import { createClient } from 'redis';
import { logger } from '../utils/logger';

// Redis client configuration
const redisClient = createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
  },
  password: process.env.REDIS_PASSWORD,
});

// Error handling
redisClient.on('error', (err) => {
  logger.error('Redis client error:', err);
});

redisClient.on('connect', () => {
  logger.info('Redis client connected');
});

// Connect to Redis
export const connectRedis = async (): Promise<void> => {
  try {
    await redisClient.connect();
    logger.info('Redis connection established');
  } catch (error) {
    logger.error('Redis connection failed:', error);
    // Don't exit - Redis is optional for now
  }
};

// Helper functions
export const setCache = async (key: string, value: string, expirySeconds: number = 300): Promise<void> => {
  try {
    await redisClient.setEx(key, expirySeconds, value);
  } catch (error) {
    logger.error('Redis SET error:', error);
  }
};

export const getCache = async (key: string): Promise<string | null> => {
  try {
    return await redisClient.get(key);
  } catch (error) {
    logger.error('Redis GET error:', error);
    return null;
  }
};

export const deleteCache = async (key: string): Promise<void> => {
  try {
    await redisClient.del(key);
  } catch (error) {
    logger.error('Redis DEL error:', error);
  }
};

// Token blacklist for logout
export const addToBlacklist = async (token: string, expirySeconds: number): Promise<void> => {
  await setCache(`blacklist:${token}`, '1', expirySeconds);
};

export const isTokenBlacklisted = async (token: string): Promise<boolean> => {
  const result = await getCache(`blacklist:${token}`);
  return result !== null;
};

export { redisClient };
