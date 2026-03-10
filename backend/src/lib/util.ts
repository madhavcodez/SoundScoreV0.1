import crypto from "node:crypto";

export const nowIso = () => new Date().toISOString();

export const uid = (prefix: string) => `${prefix}_${crypto.randomUUID().replace(/-/g, "")}`;
