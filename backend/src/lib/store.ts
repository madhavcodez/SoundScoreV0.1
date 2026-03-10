import type { InMemoryStore } from "../types";

export const createStore = (): InMemoryStore => ({
  users: new Map(),
  usersByEmail: new Map(),
  sessions: new Map(),
  albums: new Map(),
  ratings: new Map(),
  reviews: new Map(),
  lists: new Map(),
  follows: new Map(),
  listeningEvents: [],
  activity: [],
  idempotency: new Map(),
});
