import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { Db } from "./client";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const runMigrations = async (db: Db) => {
  await db.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  const schemaDir = path.join(__dirname, "schema");
  const entries = (await fs.readdir(schemaDir)).filter((name) => name.endsWith(".sql")).sort();

  for (const filename of entries) {
    const version = filename.replace(/\.sql$/, "");
    const existing = await db.query<{ version: string }>(
      "SELECT version FROM schema_migrations WHERE version = $1",
      [version],
    );

    if (existing.rowCount) {
      continue;
    }

    const sql = await fs.readFile(path.join(schemaDir, filename), "utf8");
    await db.query("BEGIN");
    try {
      await db.query(sql);
      await db.query("INSERT INTO schema_migrations(version) VALUES($1)", [version]);
      await db.query("COMMIT");
      // eslint-disable-next-line no-console
      console.log(`Applied migration ${version}`);
    } catch (error) {
      await db.query("ROLLBACK");
      throw error;
    }
  }
};
