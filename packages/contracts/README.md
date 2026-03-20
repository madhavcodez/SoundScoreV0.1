# @soundscore/contracts

> Shared TypeScript type definitions for the SoundScore API

## Purpose

Single source of truth for API request/response shapes, event schemas, and endpoint contracts shared between backend and future web client. All schemas are defined with [Zod](https://zod.dev/) and export both runtime validators and inferred TypeScript types.

## Files

| File | Description | Key Exports |
|------|-------------|-------------|
| `common.ts` | Pagination, error envelope, and idempotency primitives | `CursorPageSchema`, `ErrorEnvelopeSchema`, `IdempotencyKeyHeaderSchema` |
| `models.ts` | Core domain models (albums, ratings, reviews, lists, users, notifications) | `AlbumSchema`, `RatingSchema`, `TrackSchema`, `TrackRatingSchema`, `ReviewSchema`, `UserProfileSchema`, `ListSchema`, `WeeklyRecapSchema`, `NotificationPreferenceSchema`, `DeviceTokenSchema` |
| `endpoints.ts` | Request/response schemas for API routes (auth, ratings, reviews, lists, social, notifications) | `SignUpRequestSchema`, `LoginRequestSchema`, `RefreshRequestSchema`, `AuthResponseSchema`, `CreateRatingRequestSchema`, `CreateTrackRatingRequestSchema`, `CreateReviewRequestSchema`, `UpdateReviewRequestSchema`, `CreateListRequestSchema`, `AddListItemRequestSchema`, `ReactActivityRequestSchema`, `CommentActivityRequestSchema`, `UpsertNotificationPreferenceSchema`, `RegisterDeviceTokenRequestSchema` |
| `events.ts` | Activity feed and listening history event shapes | `ActivityTypeSchema`, `ActivityEventSchema`, `ListeningEventSchema` |
| `provider.ts` | OAuth provider connection, status, and disconnection contracts | `ProviderName`, `ProviderErrorCode`, `ConnectProviderRequestSchema`, `OAuthCallbackRequestSchema`, `ProviderConnectionSchema`, `ProviderStatusResponseSchema`, `DisconnectProviderRequestSchema` |
| `mapping.ts` | Canonical entity resolution and cross-provider ID mapping | `CanonicalEntityType`, `CanonicalArtistSchema`, `CanonicalAlbumSchema`, `MappingStatus`, `MappingProvenance`, `ProviderMappingSchema`, `MappingLookupRequestSchema`, `MappingLookupResponseSchema`, `ResolveMappingRequestSchema` |
| `compliance.ts` | Provider attribution, branding, and data-retention policies | `AttributionPlacement`, `AttributionRequirementSchema`, `ComplianceViolationSchema`, `ComplianceCheckResponseSchema`, `DataRetentionPolicySchema` |
| `sync.ts` | Sync job lifecycle, cursor bookmarks, and ingested listening events | `SyncType`, `SyncStatus`, `SyncTriggerRequestSchema`, `SyncJobSchema`, `SyncStatusResponseSchema`, `SyncCursorSchema`, `SyncListeningEventSchema`, `CancelSyncRequestSchema` |

## Type Aliases

Every Zod schema also exports a corresponding TypeScript type via `z.infer`. For example:

- `Album`, `Rating`, `Track`, `TrackRating`, `Review`, `UserProfile`, `SoundScoreList`, `WeeklyRecap`, `NotificationPreference`, `DeviceToken`
- `ActivityEvent`, `ListeningEvent`
- `ProviderConnection`, `ProviderStatusResponse`, `ConnectProviderRequest`, `OAuthCallbackRequest`, `DisconnectProviderRequest`
- `CanonicalArtist`, `CanonicalAlbum`, `ProviderMapping`, `MappingLookupRequest`, `MappingLookupResponse`, `ResolveMappingRequest`
- `AttributionRequirement`, `ComplianceViolation`, `ComplianceCheckResponse`, `DataRetentionPolicy`
- `SyncTriggerRequest`, `SyncJob`, `SyncStatusResponse`, `SyncCursor`, `SyncListeningEvent`, `CancelSyncRequest`
- `ErrorEnvelope`

## Usage

```ts
import {
  AlbumSchema,
  UserProfileSchema,
  CreateRatingRequestSchema,
  ErrorEnvelopeSchema,
  type Album,
  type UserProfile,
} from "@soundscore/contracts";

// Runtime validation
const album = AlbumSchema.parse(rawJson);

// Type-safe access
console.log(album.title, album.avgRating);
```

## Build

```bash
npm run build --workspace @soundscore/contracts
npm run typecheck --workspace @soundscore/contracts
```

## Dependencies

- **zod** `^3.24.1` -- runtime schema validation and TypeScript type inference
- **typescript** `^5.7.2` (dev) -- compilation and type checking

## Coverage Gap

Only 16 of 36 backend routes have typed contract schemas. Phase 2 routes (search, discovery, admin, moderation) lack contracts entirely. Expanding coverage is tracked as future work.

Last audited: 2026-03-19
