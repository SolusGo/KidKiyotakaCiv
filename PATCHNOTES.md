# Patch Notes

## Version 1 — Final integration polish — 2026-09-22

- Declared Community Patch version 151+ as a hard dependency and added dependency parity validation.
- Prioritized valid in-progress unique units over later queue entries when excess queues are pruned.
- Documented the unavoidable same-city queue UI limitation while retaining hard cap enforcement.

## Version 1 — State integrity and packaging hardening — 2026-09-22

- Enabled the Community Patch callbacks used by White Room gameplay systems.
- Made the one-capital rule persistent and added a direct founding veto.
- Reworked trade-route learning to award each route instance once, including later routes over the same endpoints.
- Hardened city adaptation identity and migrated existing HP/ranged records.
- Made unique-unit caps queue-aware and added immediate creation enforcement.
- Cleared Kiyotaka's transient survival/combat state on death without touching permanent adaptation.
- Synchronized the distributable manifest with the full ModBuddy project and added package/regression validation tools.

## Version 1 — Player-only civilization selection — 2026-09-06

- Set White Room / Kiyotaka to remain human-playable while preventing the AI from selecting it.
