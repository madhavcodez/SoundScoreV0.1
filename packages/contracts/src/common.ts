import { z } from "zod";

export const CursorPageSchema = <T extends z.ZodTypeAny>(itemSchema: T) =>
  z.object({
    items: z.array(itemSchema),
    nextCursor: z.string().nullable(),
  });

export const ErrorEnvelopeSchema = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
    requestId: z.string(),
  }),
});

export const IdempotencyKeyHeaderSchema = z.object({
  "idempotency-key": z.string().min(8),
});

export type ErrorEnvelope = z.infer<typeof ErrorEnvelopeSchema>;
