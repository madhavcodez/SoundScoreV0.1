# SoundScore Improvement Sweep Report

**Date:** 2026-03-18
**Scope:** iOS (Swift/SwiftUI) + Android (Kotlin/Compose) mobile apps
**Commits:** 12 commits across 54 files, ~2,800 lines added, ~1,300 removed

---

## Phase 1 — Audit Findings

### iOS (47 issues found)
- **13 dead buttons** with empty action handlers across 6 screens
- **5 "coming soon" permanent placeholders** blocking real UI
- **3 missing loading/error states** on data-fetching screens
- **ReviewSheet** dismissed without saving data
- **FeedItem mapping** used first album instead of resolving from activityObject
- **Avatar colors** hardcoded to specific usernames
- **AuthManager.isAuthenticated** bypassed to `true`
- **Notification preferences** not persisted when toggled

### Android (47 issues found)
- **13+ dead buttons** with empty onClick handlers
- **5 "coming soon" placeholders**
- **Hardcoded dev credentials** in repository (email, password, device token)
- **Avatar colors** only handled 3 usernames
- **No empty search results state**
- **ProfileViewModel** didn't expose recent activity

---

## Phase 2 — iOS Changes

### ReviewSheet → API Pipeline
- Added `createReview` outbox operation type
- Wired `saveReview(albumId:reviewText:rating:)` in SoundScoreRepository
- ReviewSheet now persists review text + rating through outbox → API
- Save button disabled when no rating and no text entered

### Loading/Error States
- Added `isLoading` and `errorMessage` to SoundScoreRepository
- Propagated through all ViewModels (Feed, Log, Search, Profile)
- Added `ErrorBanner` component with retry action
- Added skeleton loading states on FeedScreen and LogScreen
- Added `.refreshable` (pull-to-refresh) to all scrollable screens

### Dead Button Wiring
- **FeedScreen Share**: Wired via `ShareLink` with review text
- **ProfileScreen Share**: Wired via `ShareLink` with profile summary
- **ProfileScreen Export**: Shows queued confirmation alert
- **ProfileScreen View Recap**: Opens deep link URL
- **ProfileScreen Recap Share**: Wired via `ShareLink`
- **SettingsScreen Export Data**: Queues outbox export operation
- **SettingsScreen Delete Account**: Confirmation dialog → API call → logout
- **SettingsScreen Sign Out**: Added sign-out button
- **LogScreen FAB**: Opens album search sheet for quick logging
- **SearchScreen Genre Cards**: Tap fills search query

### Placeholder Replacements
- **ProfileScreen Recent Activity**: Shows actual feed items (top 3)
- **ProfileScreen Achievements**: Removed permanent empty state
- **ListsScreen Popular Lists**: Removed
- **SearchScreen Friends Listening**: Removed
- **SearchScreen No Results**: Added proper empty state for failed searches

### Data Mapping Fixes
- `mapFeedItem` now resolves album from `activityObject.id`
- Added `formatTimeAgo` for human-readable relative timestamps
- Avatar colors use hash-based deterministic palette (scales to any username)
- `toggleLike` prevents negative like count with `max(0, ...)`

### Settings Improvements
- Notification toggle changes auto-persist via outbox
- Quiet Hours editable via Stepper controls
- AuthScreen: Fixed `isLoading` not reset on successful login

---

## Phase 3 — Android Changes

### Dead Button & Placeholder Fixes
- Replaced hardcoded avatar colors with hash-based palette
- Removed "Popular lists", "Friends listening", "Achievements" placeholders
- Added "No results found" empty state for search
- Wired recent activity section in ProfileScreen
- Added `recentActivity` to `ProfileUiState`
- LogScreen FAB opens ModalBottomSheet with album search

### Component Improvements
- `BlueButton` now supports `enabled` parameter with disabled styling
- List create button disabled when title is blank

### Security
- Moved hardcoded dev credentials to `System.getenv()` with fallbacks
- Added TODO for FCM token replacement

---

## Architecture Notes

### Patterns Maintained
- **ViewModel → Repository → API** layer separation
- **Outbox pattern** for optimistic mutations with retry
- **Immutable data flow**: Repository publishes, ViewModels transform, Screens render
- **Dark-mode-first** glassmorphism design language

### Known Remaining Items
- AuthManager bypass (`isAuthenticated = true`) still present for offline dev
- Quiet Hours time picker could use a proper wheel picker
- List detail/edit screen not yet implemented
- Write Later feature still shows "coming soon" (intentionally deferred)
- FCM token integration pending Firebase setup
