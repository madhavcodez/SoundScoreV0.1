import { z } from "zod";

export const SignUpRequestSchema = z.object({
  email: z.string().email().max(254),
  password: z.string().min(8).max(128),
  handle: z
    .string()
    .min(2)
    .max(30)
    .regex(/^[\w]+$/, "Handle must contain only alphanumeric characters and underscores"),
});

export const LoginRequestSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export const RefreshRequestSchema = z.object({
  refreshToken: z.string().min(16),
});

export const AuthResponseSchema = z.object({
  accessToken: z.string(),
  refreshToken: z.string(),
  userId: z.string(),
  handle: z.string(),
});

export const CreateRatingRequestSchema = z.object({
  albumId: z.string().max(100),
  value: z.number().min(0).max(6),
});

export const CreateTrackRatingRequestSchema = z.object({
  trackId: z.string().max(100),
  albumId: z.string().max(100),
  value: z.number().min(0).max(6),
});

export const CreateReviewRequestSchema = z.object({
  albumId: z.string().max(100),
  body: z.string().min(1).max(5000),
});

export const UpdateReviewRequestSchema = z.object({
  body: z.string().min(1).max(5000),
  expectedRevision: z.number().int().nonnegative(),
});

export const CreateListRequestSchema = z.object({
  title: z.string().min(1).max(200),
  note: z.string().max(1000).optional(),
});

export const AddListItemRequestSchema = z.object({
  albumId: z.string().max(100),
  note: z.string().max(1000).optional(),
});

export const ReactActivityRequestSchema = z.object({
  reaction: z.string().min(1).max(50),
});

export const CommentActivityRequestSchema = z.object({
  body: z.string().min(1).max(2000),
});

export const UpsertNotificationPreferenceSchema = z.object({
  socialEnabled: z.boolean(),
  recapEnabled: z.boolean(),
  commentEnabled: z.boolean(),
  reactionEnabled: z.boolean(),
  quietHoursStart: z.number().int().min(0).max(23),
  quietHoursEnd: z.number().int().min(0).max(23),
});

export const RegisterDeviceTokenRequestSchema = z.object({
  platform: z.enum(["android", "ios"]),
  deviceToken: z.string().min(8),
});
