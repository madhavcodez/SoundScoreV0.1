import type { Db } from "../db/client";
import { uid } from "./util";

const AUDIT_SENSITIVE_FIELDS = new Set([
  "password",
  "passwordHash",
  "token",
  "accessToken",
  "refreshToken",
  "email",
  "deviceToken",
]);

const scrubDetails = (details: Record<string, unknown>): Record<string, unknown> =>
  Object.fromEntries(
    Object.entries(details).filter(([key]) => !AUDIT_SENSITIVE_FIELDS.has(key)),
  );

export type AuditEventType =
  | "user.signup"
  | "user.login"
  | "user.logout"
  | "provider.connect"
  | "provider.disconnect"
  | "account.export"
  | "account.delete"
  | "sync.start"
  | "sync.complete"
  | "sync.fail"
  | "rating.create"
  | "review.create"
  | "review.update"
  | "review.delete"
  | "list.create"
  | "admin.mapping_override";

export async function logAuditEvent(
  db: Db,
  event: {
    userId: string;
    type: AuditEventType;
    details?: Record<string, unknown>;
    ipAddress?: string;
    userAgent?: string;
  },
): Promise<void> {
  const id = uid("aud");
  await db.query(
    `
      INSERT INTO audit_events(id, user_id, event_type, details, ip_address, user_agent)
      VALUES ($1, $2, $3, $4::jsonb, $5, $6)
    `,
    [
      id,
      event.userId,
      event.type,
      JSON.stringify(event.details ? scrubDetails(event.details) : {}),
      event.ipAddress ?? null,
      event.userAgent ?? null,
    ],
  );
}
