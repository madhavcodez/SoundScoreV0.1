import type { UserProfile } from "@soundscore/contracts";
import type { UserProfileRow } from "../types";

export const mapUserProfile = (row: UserProfileRow): UserProfile => ({
  id: row.id,
  handle: row.handle,
  bio: row.bio,
  logCount: row.log_count,
  reviewCount: row.review_count,
  listCount: row.list_count,
  avgRating: Number(row.avg_rating ?? 0),
});

export const tryJsonParse = <T>(value: string | null | undefined, fallback: T): T => {
  if (!value) {
    return fallback;
  }
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
};
