import 'dotenv/config';
import { defineConfig, env } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: { path: 'prisma/migrations' },
  // Migrations need a direct (non-pooler) Neon connection for advisory locks;
  // the app itself keeps using the pooled DB_URL.
  datasource: { url: process.env.DIRECT_DB_URL || env('DB_URL') },
});
