import type { FastifyInstance } from "fastify";

const AUTH_ROUTES = new Set([
  "/v1/auth/signup",
  "/v1/auth/login",
  "/v1/auth/refresh",
]);

const SENSITIVE_ROUTES = new Set(["/v1/account/export", "/v1/account"]);

const PROVIDER_PREFIX = "/v1/providers/";

export const applyRouteRateLimits = (app: FastifyInstance): void => {
  app.addHook("onRoute", (routeOptions) => {
    const url = routeOptions.url;
    if (!url.startsWith("/v1/")) return;

    const existing = routeOptions.config as Record<string, unknown> | undefined;
    if (existing?.rateLimit !== undefined) return;

    let rateLimit: { max: number; timeWindow: string } | undefined;

    if (AUTH_ROUTES.has(url)) {
      rateLimit = { max: 10, timeWindow: "1 minute" };
    } else if (SENSITIVE_ROUTES.has(url)) {
      rateLimit = { max: 3, timeWindow: "1 hour" };
    } else if (url.startsWith(PROVIDER_PREFIX)) {
      rateLimit = { max: 10, timeWindow: "1 minute" };
    } else {
      const methods = Array.isArray(routeOptions.method)
        ? routeOptions.method
        : [routeOptions.method];
      const isWrite = methods.some((m) => m !== "GET" && m !== "HEAD");
      if (isWrite) {
        rateLimit = { max: 30, timeWindow: "1 minute" };
      }
    }

    if (rateLimit) {
      routeOptions.config = { ...existing, rateLimit };
    }
  });
};
