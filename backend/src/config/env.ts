import dotenv from "dotenv";

dotenv.config();

const toNumber = (value: string | undefined, fallback: number) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

export const env = {
  app: {
    port: toNumber(process.env.PORT, 8080),
    host: process.env.HOST ?? "0.0.0.0",
  },
  postgres: {
    connectionString: process.env.DATABASE_URL ?? "postgresql://soundscore:soundscore@localhost:5432/soundscore",
  },
  redis: {
    url: process.env.REDIS_URL ?? "redis://localhost:6379",
  },
  auth: {
    saltRounds: toNumber(process.env.AUTH_SALT_ROUNDS, 10),
  },
};
