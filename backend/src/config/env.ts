import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const EnvSchema = z.object({
  PORT: z.coerce.number().default(8080),
  HOST: z.string().default("0.0.0.0"),
  DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),
  REDIS_URL: z.string().min(1, "REDIS_URL is required"),
  AUTH_SALT_ROUNDS: z.coerce.number().default(10),
  SPOTIFY_CLIENT_ID: z.string().optional().default(""),
  SPOTIFY_CLIENT_SECRET: z.string().optional().default(""),
  ALLOWED_ORIGINS: z.string().default("http://localhost:3000"),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  LOG_LEVEL: z.enum(["fatal", "error", "warn", "info", "debug", "trace"]).default("info"),
});

const parsed = EnvSchema.safeParse(process.env);

if (!parsed.success) {
  console.error("Invalid environment variables:");
  for (const issue of parsed.error.issues) {
    console.error(`  ${issue.path.join(".")}: ${issue.message}`);
  }
  process.exit(1);
}

const validated = parsed.data;

if (!validated.SPOTIFY_CLIENT_ID || !validated.SPOTIFY_CLIENT_SECRET) {
  console.warn("Warning: SPOTIFY_CLIENT_ID / SPOTIFY_CLIENT_SECRET not set — provider features will be unavailable");
}

export const env = {
  app: {
    port: validated.PORT,
    host: validated.HOST,
    allowedOrigins: validated.ALLOWED_ORIGINS.split(",").map((s) => s.trim()),
    nodeEnv: validated.NODE_ENV,
    logLevel: validated.LOG_LEVEL,
  },
  postgres: {
    connectionString: validated.DATABASE_URL,
  },
  redis: {
    url: validated.REDIS_URL,
  },
  auth: {
    saltRounds: validated.AUTH_SALT_ROUNDS,
  },
  spotify: {
    clientId: validated.SPOTIFY_CLIENT_ID,
    clientSecret: validated.SPOTIFY_CLIENT_SECRET,
  },
};
