import { buildServer } from "./server";
import { env } from "./config/env";

const run = async () => {
  const app = await buildServer();
  await app.listen({
    port: env.app.port,
    host: env.app.host,
  });

  // Graceful shutdown: drain in-flight requests, close DB/Redis via onClose hook
  for (const signal of ["SIGINT", "SIGTERM"] as const) {
    process.on(signal, async () => {
      app.log.info({ signal }, "shutting down gracefully");
      await app.close();
      process.exit(0);
    });
  }
};

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
