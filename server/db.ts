import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import * as schema from "@shared/schema";

// Use PostgreSQL connection for Kubernetes environment
const connectionString = process.env.DATABASE_URL || 
  `postgresql://${process.env.POSTGRES_USER || 'devopsuser'}:${process.env.POSTGRES_PASSWORD || 'devopspass123'}@${process.env.POSTGRES_HOST || 'postgres-service'}:${process.env.POSTGRES_PORT || '5432'}/${process.env.POSTGRES_DB || 'devopsdb'}`;

export const pool = new Pool({ 
  connectionString,
  ssl: false, // Disable SSL for local PostgreSQL
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

export const db = drizzle(pool, { schema });

// Initialize database and run migrations
export async function initializeDatabase() {
  try {
    console.log('Connecting to database...');
    await pool.connect();
    console.log('Database connection established');
    
    // Run migrations to create tables
    console.log('Running database migrations...');
    await migrate(db, { migrationsFolder: './drizzle' });
    console.log('Database migrations completed');
    
    return true;
  } catch (error) {
    console.error('Database initialization failed:', error);
    // Continue without database for development
    return false;
  }
}