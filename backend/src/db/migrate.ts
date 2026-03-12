import { createDb } from "./client";
import { runMigrations } from "./runMigrations";

const run = async () => {
  const db = createDb();
  try {
    await runMigrations(db);
    // eslint-disable-next-line no-console
    console.log("Migrations complete");
  } finally {
    await db.close();
  }
};

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error("Migration failed", error);
  process.exit(1);
});
