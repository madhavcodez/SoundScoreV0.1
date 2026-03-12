# Phase 2 Execution Plan (Reset)

Date: 2026-03-11  
Milestone: `M2 Provider-Limited Beta (Spotify) - Reset`  
Baseline reference: tag `phase1-complete-2026-03-11` (commit `4a60d5a`)

## 1. Mission

Deliver a provider-limited Spotify beta that layers on top of the Phase 1 stable `/v1` foundation without breaking existing contracts.

## 2. Scope boundaries

- In scope: provider connect/auth, canonical mapping, listening import/dedup, provider compliance/trust.
- Out of scope: multi-provider rollout and scale hardening (`#108`, M3), broad new social features outside provider integration.

## 3. Workstreams and issue mapping

### WS1: Provider Connect/Auth

- Epic: `#109`
- Tasks: `#110`, `#111`, `#112`
- Outcome: users can connect/disconnect Spotify with stable connection state and secure token lifecycle.

### WS2: Catalog Canonicalization + Mapping

- Epic: `#113`
- Tasks: `#114`, `#115`, `#116`
- Outcome: canonical-to-provider mapping is deterministic, auditable, and resilient to retries/conflicts.

### WS3: Listening Import + Dedup

- Epic: `#117`
- Tasks: `#118`, `#119`, `#120`
- Outcome: import worker can sync provider listening data with cursor continuity and idempotent dedup behavior.

### WS4: Provider Compliance + Trust

- Epic: `#121`
- Tasks: `#122`, `#123`, `#124`
- Outcome: attribution/policy, disconnect/delete propagation, and trust hardening are operationally ready.

## 4. Sequencing and dependencies

### Wave 0: Contracts and integration skeleton

- Start: `#110`, `#114`, `#118`, `#122`
- Exit:
  - API/contract definitions approved.
  - Error/state taxonomy locked for provider flows.
  - No breaking change against Phase 1 `/v1` endpoints.

### Wave 1: Core platform path

- Start after Wave 0: `#111`, `#115`, `#119`, `#123`
- Exit:
  - Connect UX + backend token lifecycle works.
  - Mapping pipeline core writes canonical/provider linkage.
  - Import worker core ingests + dedups baseline flow.
  - Disconnect/delete propagation path works end-to-end.

### Wave 2: Hardening and operations

- Start after Wave 1: `#112`, `#116`, `#120`, `#124`
- Exit:
  - Security/perf/reliability evidence attached to each stream.
  - Observability for auth/mapping/import/compliance paths.
  - Incident and rollback playbook for provider degradation.

### Dependency rules

- `#111` depends on `#110`.
- `#115` depends on `#114`.
- `#119` depends on `#118` and uses mapping outputs from `#115`.
- `#123` depends on `#111` for provider connection lifecycle hooks.
- Hardening tasks (`#112`, `#116`, `#120`, `#124`) depend on their corresponding core tasks.

## 5. Quality gates (required)

- Backend:
  - `npm run migrate --workspace backend`
  - `npm run typecheck`
  - `npm run test --workspace backend`
  - `npm run build`
- Android:
  - `./gradlew :app:assembleDebug`
  - `./gradlew :app:testDebugUnitTest`
- Contract integrity:
  - New provider/import endpoints have typed schemas and contract tests.
  - Existing Phase 1 `/v1` routes remain backward compatible.

## 6. Contributor model

- All reset issues are labeled `ready-for-external`.
- Suggested ownership by stream:
  - WS1: `area:backend`, `area:mobile`, `area:security`
  - WS2/WS3: `area:data`, `area:backend`
  - WS4: `area:security`, `area:backend`
- Working rule:
  - No task starts implementation before its contract task is accepted.
  - Merge requires linked evidence (tests + docs + telemetry note) in issue comments.

## 7. Risk register and mitigations

- Provider policy churn:
  - Mitigation: keep provider adapter boundaries explicit and trust checks in WS4.
- Import data quality drift:
  - Mitigation: confidence + dedup hardening (`#116`, `#120`) and replay-safe tests.
- Timeline pressure:
  - Mitigation: preserve strict order: contracts -> core -> hardening.

## 8. Definition of done for Phase 2

- All reset M2 tasks (`#110`-`#124`) are closed with evidence.
- Legacy M2 issues (`#58`, `#59`, `#60`, `#82`-`#90`, `#105`) remain closed as superseded.
- Phase 1 contract stability is preserved (no breaking API changes).
- Provider-limited beta path is executable with documented runbook and contributor-ready issue ownership.
