export default () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  databaseUrl: process.env.DATABASE_URL,
  redisUrl: process.env.REDIS_URL ?? 'redis://localhost:6379',
  jwt: {
    secret: process.env.JWT_SECRET ?? 'dev-secret-change-me',
    accessTtl: parseInt(process.env.JWT_ACCESS_TTL ?? '900', 10),
    refreshTtl: parseInt(process.env.JWT_REFRESH_TTL ?? '2592000', 10),
    deviceTtl: parseInt(process.env.JWT_DEVICE_TTL ?? '31536000', 10),
  },
  heartbeat: {
    intervalSeconds: parseInt(process.env.HEARTBEAT_INTERVAL_SECONDS ?? '75', 10),
    missGrace: parseInt(process.env.HEARTBEAT_MISS_GRACE ?? '2', 10),
  },
  command: {
    ttlSeconds: parseInt(process.env.COMMAND_TTL_SECONDS ?? '300', 10),
  },
  fcm: {
    serviceAccountPath: process.env.FCM_SERVICE_ACCOUNT_PATH ?? '',
  },
});
