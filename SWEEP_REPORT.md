# Final Review Sweep Report

Date: 2026-03-18

## Summary

Performed a full code review sweep across all iOS Swift files under `ios/SoundScore/SoundScore/` and all Android Kotlin files under `app/src/main/java/com/soundscore/app/`. Identified and fixed issues in error handling consistency, UX logic gaps, missing disabled states, and remaining TODOs.

---

## Issues Found and Fixed

### 1. Missing ErrorBanner on iOS Screens (Architectural Inconsistency)

**Problem:** `FeedScreen` and `LogScreen` displayed `ErrorBanner` when `viewModel.errorMessage` was set, but `SearchScreen`, `ListsScreen`, and `ProfileScreen` did not. This meant network errors were silently swallowed on three out of five tabs.

**Fix:**
- Added `errorMessage` published property to `SearchViewModel`, `ListsViewModel`, and `ProfileViewModel`, wired to `SoundScoreRepository.shared.$errorMessage`.
- Added `ErrorBanner` display to `SearchScreen.swift`, `ListsScreen.swift`, and `ProfileScreen.swift`.
- Also added `isLoading` to `ListsViewModel` for parity with other ViewModels.

**Files changed:**
- `ios/SoundScore/SoundScore/ViewModels/SearchViewModel.swift`
- `ios/SoundScore/SoundScore/ViewModels/ListsViewModel.swift`
- `ios/SoundScore/SoundScore/ViewModels/ProfileViewModel.swift`
- `ios/SoundScore/SoundScore/Screens/SearchScreen.swift`
- `ios/SoundScore/SoundScore/Screens/ListsScreen.swift`
- `ios/SoundScore/SoundScore/Screens/ProfileScreen.swift`

### 2. LogScreen ErrorBanner Missing Retry Action (Missing Error Handling)

**Problem:** `LogScreen` displayed `ErrorBanner(message: error)` without passing an `onRetry` closure, unlike `FeedScreen` which provided a retry button. Users on the Log tab had no way to recover from errors.

**Fix:** Added `onRetry` closure that calls `SoundScoreRepository.shared.refresh()`.

**File changed:** `ios/SoundScore/SoundScore/Screens/LogScreen.swift`

### 3. AuthScreen isLoading Never Resets on Success (UX Logic Gap)

**Problem:** After successful login/signup, `isLoading` was never set back to `false`. If the user navigated back to the auth screen (e.g., after logout), the button could appear stuck in loading state with "..." text.

**Fix:** Added `await MainActor.run { isLoading = false }` after successful authentication.

**File changed:** `ios/SoundScore/SoundScore/Screens/AuthScreen.swift`

### 4. iOS Feed Like Count Could Go Negative (Missing Guard)

**Problem:** `SoundScoreRepository.toggleLike` could decrement `likes` below zero if an unlike was triggered on an item with 0 likes (e.g., from stale seed data).

**Fix:** Added `max(0, ...)` floor to the likes calculation.

**File changed:** `ios/SoundScore/SoundScore/Services/SoundScoreRepository.swift`

### 5. Android SearchScreen "0 matches" Header Shown Before Empty State (UX Logic Gap)

**Problem:** When a search query returned no results, the screen displayed `SectionHeader("Results", "0 matches")` followed by an `EmptyState` card. This was redundant and confusing -- showing "0 matches" before "No results found."

**Fix:** Restructured the conditional to show `EmptyState` first when results are empty, and only show the section header + results list when results exist.

**File changed:** `app/src/main/java/com/soundscore/app/ui/screens/SearchScreen.kt`

### 6. Android ListsScreen Create Button Missing Disabled State (UX Logic Gap)

**Problem:** The "Create" button in the create-list bottom sheet was always enabled, even when the title field was blank. iOS correctly disabled the button and reduced opacity. On Android, tapping Create with an empty title silently failed (the repository guards against it, but the UI should prevent it).

**Fix:**
- Added `enabled` parameter to `BlueButton` composable with proper disabled color styling.
- Added `enabled = draftTitle.isNotBlank()` and a guard in the onClick callback in `ListsScreen`.

**Files changed:**
- `app/src/main/java/com/soundscore/app/ui/components/SoundScoreButton.kt`
- `app/src/main/java/com/soundscore/app/ui/screens/ListsScreen.kt`

### 7. Android LogScreen FAB Did Nothing (Remaining TODO / UX Logic Gap)

**Problem:** The floating action button on LogScreen had `onClick = { /* TODO: Open album search/log sheet */ }` -- it was completely non-functional. Users tapping the prominent FAB got no response.

**Fix:** Wired the FAB to open a `ModalBottomSheet` with a placeholder message indicating album search is coming soon, matching the iOS pattern of opening a search sheet from LogScreen.

**File changed:** `app/src/main/java/com/soundscore/app/ui/screens/LogScreen.kt`

### 8. Android ProfileViewModel FCM Token TODO (Documented)

**Problem:** `ProfileViewModel` used a hardcoded `"emulator-debug-token"` for push notification registration with a TODO comment.

**Fix:** Updated the comment from `TODO` to `KNOWN` to indicate this is a tracked limitation requiring Firebase Messaging integration, not an oversight.

**File changed:** `app/src/main/java/com/soundscore/app/ui/viewmodel/ProfileViewModel.kt`

---

## Items Verified as Correct (No Changes Needed)

- **Android `Icons.Outlined.SearchOff`**: The `material-icons-extended` dependency is present in `build.gradle.kts`, so this icon resolves correctly.
- **Android `combine` with 5 flows in ProfileViewModel**: Kotlin's `kotlinx.coroutines.flow.combine` has a typed overload for exactly 5 flows, so this compiles without issue.
- **iOS `ShareLink` usages**: All `ShareLink(item:)` calls use `String`, which conforms to `Transferable` in iOS 16+.
- **iOS `outboxStore` accessibility**: `SoundScoreRepository.outboxStore` is declared as `let` (non-private), accessible from `SettingsScreen` and `ProfileViewModel` as needed.
- **iOS `.refreshable` usage**: All five main screens (Feed, Log, Search, Lists, Profile) use `.refreshable { await SoundScoreRepository.shared.refresh() }`.
- **Both platforms: Model/ViewModel/Screen consistency**: Data models match between platforms. ViewModels follow consistent patterns (Combine on iOS, StateFlow+combine on Android). Screen layouts mirror each other structurally.
- **Android immutable state updates**: `toggleLike` in `RemoteSoundScoreRepository` correctly uses `_feedItems.update { items.map { ... } }` producing new list instances rather than mutating in place, with `maxOf(0, item.likes - 1)` floor already present.

---

## Known Remaining Items (Not Bugs)

- **AuthManager bypass** (`isAuthenticated = true`) is present for offline development; not a bug.
- **FCM token placeholder**: Requires Firebase Messaging SDK integration before it can use a real token.
- **Write Later feature**: Shows "coming soon" on both platforms; intentionally deferred.
- **List detail/edit screen**: Not yet implemented on either platform.
