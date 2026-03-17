import { z } from "zod";
import { ProviderName } from "./provider";

/** Where provider attribution must be displayed per Terms of Service. */
export const AttributionPlacement = z.enum([
  "search_results",
  "album_detail",
  "now_playing",
  "share_card",
]);
export type AttributionPlacement = z.infer<typeof AttributionPlacement>;

/** Attribution text and assets required by a provider's branding guidelines. */
export const AttributionRequirementSchema = z.object({
  provider: ProviderName,
  displayText: z.string(),
  logoUrl: z.string().url().optional(),
  linkUrl: z.string().url().optional(),
  mustDisplayIn: z.array(AttributionPlacement),
});

/** A single compliance rule violation detected during a check. */
export const ComplianceViolationSchema = z.object({
  code: z.string(),
  message: z.string(),
  severity: z.enum(["error", "warning"]),
});

/** Result of running a compliance check against a provider integration. */
export const ComplianceCheckResponseSchema = z.object({
  provider: ProviderName,
  compliant: z.boolean(),
  violations: z.array(ComplianceViolationSchema),
});

/** Data retention rules dictated by a provider's developer agreement. */
export const DataRetentionPolicySchema = z.object({
  provider: ProviderName,
  maxTokenLifetimeDays: z.number().int().positive(),
  mustDeleteOnDisconnect: z.boolean(),
  listeningDataRetentionDays: z.number().int().positive().optional(),
});

export type AttributionRequirement = z.infer<typeof AttributionRequirementSchema>;
export type ComplianceViolation = z.infer<typeof ComplianceViolationSchema>;
export type ComplianceCheckResponse = z.infer<typeof ComplianceCheckResponseSchema>;
export type DataRetentionPolicy = z.infer<typeof DataRetentionPolicySchema>;
