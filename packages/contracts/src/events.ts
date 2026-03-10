import { z } from "zod";

export const ActivityTypeSchema = z.enum([
  "RATED_ALBUM",
  "WROTE_REVIEW",
  "CREATED_LIST",
  "ADDED_LIST_ITEM",
]);

export const ActivityEventSchema = z.object({
  id: z.string(),
  actorId: z.string(),
  type: ActivityTypeSchema,
  object: z.object({
    type: z.enum(["album", "review", "list"]),
    id: z.string(),
  }),
  createdAt: z.string().datetime(),
  payload: z.record(z.unknown()),
  reactions: z.number().int().nonnegative().default(0),
  comments: z.number().int().nonnegative().default(0),
});

export const ListeningEventSchema = z.object({
  id: z.string(),
  userId: z.string(),
  albumId: z.string(),
  playedAt: z.string().datetime(),
  source: z.enum(["manual", "spotify", "apple"]),
  sourceRef: z.record(z.unknown()),
});

export type ActivityEvent = z.infer<typeof ActivityEventSchema>;
export type ListeningEvent = z.infer<typeof ListeningEventSchema>;
