export type UserProfileRow = {
  id: string;
  handle: string;
  bio: string;
  log_count: number;
  review_count: number;
  list_count: number;
  avg_rating: number;
};

export type AuthenticatedUser = {
  id: string;
  handle: string;
};

export type NotificationPreferences = {
  socialEnabled: boolean;
  recapEnabled: boolean;
  commentEnabled: boolean;
  reactionEnabled: boolean;
  quietHoursStart: number;
  quietHoursEnd: number;
};
