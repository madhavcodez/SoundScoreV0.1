import type {
  ActivityEvent,
  Album,
  ListeningEvent,
  Rating,
  Review,
  SoundScoreList,
  UserProfile,
} from "@soundscore/contracts";

export type UserRecord = {
  id: string;
  email: string;
  password: string;
  profile: UserProfile;
  refreshToken: string | null;
};

export type SessionRecord = {
  accessToken: string;
  userId: string;
  createdAt: string;
};

export type ExportPayload = {
  profile: UserProfile;
  ratings: Rating[];
  reviews: Review[];
  lists: SoundScoreList[];
  following: string[];
  listeningEvents: ListeningEvent[];
  activity: ActivityEvent[];
};

export type InMemoryStore = {
  users: Map<string, UserRecord>;
  usersByEmail: Map<string, string>;
  sessions: Map<string, SessionRecord>;
  albums: Map<string, Album>;
  ratings: Map<string, Rating>;
  reviews: Map<string, Review>;
  lists: Map<string, SoundScoreList>;
  follows: Map<string, Set<string>>;
  listeningEvents: ListeningEvent[];
  activity: ActivityEvent[];
  idempotency: Map<string, unknown>;
};
