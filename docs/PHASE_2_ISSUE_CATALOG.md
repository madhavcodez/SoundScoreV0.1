# Phase 2 Issue Catalog (Reset)

Date: 2026-03-11  
Milestone: `M2 Provider-Limited Beta (Spotify) - Reset`  
Milestone ID: `4`

## 1. New issue set

| Track | Issue | Title | Labels |
|---|---:|---|---|
| Provider Connect/Auth | #109 | EPIC-P2-01 Provider Connect/Auth | `type:epic`, `area:backend`, `area:mobile`, `priority:p0`, `ready-for-external` |
| Provider Connect/Auth | #110 | TASK-P2-01.1 OAuth contract/API alignment | `type:task`, `area:backend`, `area:security`, `priority:p0`, `ready-for-external` |
| Provider Connect/Auth | #111 | TASK-P2-01.2 Connect UX + token lifecycle core | `type:task`, `area:backend`, `area:mobile`, `priority:p0`, `ready-for-external` |
| Provider Connect/Auth | #112 | TASK-P2-01.3 Auth/provider hardening | `type:task`, `area:security`, `area:backend`, `priority:p1`, `ready-for-external` |
| Catalog + Mapping | #113 | EPIC-P2-02 Catalog Canonicalization + Mapping | `type:epic`, `area:data`, `area:backend`, `priority:p0`, `ready-for-external` |
| Catalog + Mapping | #114 | TASK-P2-02.1 Canonical/provider ID contracts | `type:task`, `area:data`, `area:backend`, `priority:p0`, `ready-for-external` |
| Catalog + Mapping | #115 | TASK-P2-02.2 Mapping pipeline core | `type:task`, `area:data`, `area:backend`, `priority:p0`, `ready-for-external` |
| Catalog + Mapping | #116 | TASK-P2-02.3 Mapping hardening | `type:task`, `area:data`, `area:backend`, `priority:p1`, `ready-for-external` |
| Import + Dedup | #117 | EPIC-P2-03 Listening Import + Dedup | `type:epic`, `area:data`, `area:backend`, `priority:p0`, `ready-for-external` |
| Import + Dedup | #118 | TASK-P2-03.1 Import contract/cursor model | `type:task`, `area:data`, `area:backend`, `priority:p0`, `ready-for-external` |
| Import + Dedup | #119 | TASK-P2-03.2 Import worker core | `type:task`, `area:data`, `area:backend`, `priority:p0`, `ready-for-external` |
| Import + Dedup | #120 | TASK-P2-03.3 Import hardening | `type:task`, `area:data`, `area:backend`, `priority:p1`, `ready-for-external` |
| Compliance + Trust | #121 | EPIC-P2-04 Provider Compliance + Trust | `type:epic`, `area:security`, `area:backend`, `priority:p0`, `ready-for-external` |
| Compliance + Trust | #122 | TASK-P2-04.1 Policy/attribution compliance | `type:task`, `area:security`, `area:backend`, `priority:p0`, `ready-for-external` |
| Compliance + Trust | #123 | TASK-P2-04.2 Disconnect/delete propagation | `type:task`, `area:security`, `area:backend`, `priority:p0`, `ready-for-external` |
| Compliance + Trust | #124 | TASK-P2-04.3 Trust hardening | `type:task`, `area:security`, `area:backend`, `priority:p1`, `ready-for-external` |

## 2. Superseded legacy M2 mapping

| Legacy issue | Status | Replaced by |
|---:|---|---:|
| #58 | Closed as superseded | #109 |
| #82 | Closed as superseded | #110 |
| #83 | Closed as superseded | #111 |
| #84 | Closed as superseded | #112 |
| #59 | Closed as superseded | #113 |
| #85 | Closed as superseded | #114 |
| #86 | Closed as superseded | #115 |
| #87 | Closed as superseded | #116 |
| #60 | Closed as superseded | #117 |
| #88 | Closed as superseded | #118 |
| #89 | Closed as superseded | #119 |
| #90 | Closed as superseded | #120 |
| #105 | Closed as superseded | #124 |

## 3. Execution order

1. Contract tasks first: #110, #114, #118, #122  
2. Core implementation next: #111, #115, #119, #123  
3. Hardening last: #112, #116, #120, #124

## 4. Notes

- The reset set is the source of truth for M2 planning and execution.
- Baseline for this reset is `phase1-complete-2026-03-11`.
- M3 hardening continuation remains tracked in `#108`.
