import { z } from "zod";

export const SignUpRequestSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  handle: z.string().min(2).max(24),
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
  albumId: z.string(),
  value: z.number().min(0).max(5),
});

export const CreateReviewRequestSchema = z.object({
  albumId: z.string(),
  body: z.string().min(1),
});

export const UpdateReviewRequestSchema = z.object({
  body: z.string().min(1),
  expectedRevision: z.number().int().nonnegative(),
});

export const CreateListRequestSchema = z.object({
  title: z.string().min(1),
  note: z.string().optional(),
});

export const AddListItemRequestSchema = z.object({
  albumId: z.string(),
  note: z.string().optional(),
});

export const ReactActivityRequestSchema = z.object({
  reaction: z.string().min(1),
});

export const CommentActivityRequestSchema = z.object({
  body: z.string().min(1),
});
