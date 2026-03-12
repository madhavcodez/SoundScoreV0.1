import { buildServer } from "./server";
import { env } from "./config/env";

const run = async () => {
  const app = await buildServer();
  await app.listen({
    port: env.app.port,
    host: env.app.host,
  });
};

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
