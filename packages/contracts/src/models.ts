import { z } from "zod";

export const AlbumSchema = z.object({
  id: z.string(),
  title: z.string(),
  artist: z.string(),
  year: z.number().int(),
  artworkUrl: z.string().url().nullable(),
  avgRating: z.number().min(0).max(5),
  logCount: z.number().int().nonnegative(),
});

export const RatingSchema = z.object({
  id: z.string(),
  userId: z.string(),
  albumId: z.string(),
  value: z.number().min(0).max(5),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export const ReviewSchema = z.object({
  id: z.string(),
  userId: z.string(),
  albumId: z.string(),
  body: z.string(),
  revision: z.number().int().nonnegative(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export const UserProfileSchema = z.object({
  id: z.string(),
  handle: z.string(),
  bio: z.string(),
  logCount: z.number().int().nonnegative(),
  reviewCount: z.number().int().nonnegative(),
  listCount: z.number().int().nonnegative(),
  avgRating: z.number().min(0).max(5),
});

export const ListSchema = z.object({
  id: z.string(),
  ownerId: z.string(),
  title: z.string(),
  note: z.string().nullable(),
  items: z.array(
    z.object({
      albumId: z.string(),
      position: z.number().int().positive(),
      note: z.string().nullable(),
    }),
  ),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export type Album = z.infer<typeof AlbumSchema>;
export type Rating = z.infer<typeof RatingSchema>;
export type Review = z.infer<typeof ReviewSchema>;
export type UserProfile = z.infer<typeof UserProfileSchema>;
export type SoundScoreList = z.infer<typeof ListSchema>;
