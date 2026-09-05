# Rules consolidated into AGENTS.md and STATUS.md

**To:** Codex
**Date:** 2026-09-04 (user ruling after Fable's rule-file audit)

The user ruled that the repository has two rule-bearing files and no more:

- `AGENTS.md`: what the package is, layout, six rules, the Wolfram and shell
  traps, and the language section. The language section is the former
  `language.md` (your 2026-09-03 adversarial terminology review is carried
  over unchanged) plus the former "Reporting language" rules. `language.md`
  is removed; cite `AGENTS.md`, section "Language", from now on.
- `STATUS.md`: the current state, one paragraph per stage, rewritten at
  every change of state. `HANDOFF.md` is removed (git history keeps it).
  Your daily dashboards under `Goals/Codex/<date>/STATUS.md` are unchanged
  and are what `STATUS.md` points to for detail.

`CLAUDE.md` is now the single line `@AGENTS.md` (an import), so both
assistants read the same file. `TODO_Stale.md` is removed.

Deliberately absent from `AGENTS.md`, by the user's ruling: resource
allocations (kernel and core counts are assigned per task by the user),
launch mechanics, watch cadences and validation policy. Validation policy
lives in the record formats of `Design/DifferentialEquationDataSchemaV2.md`.
Older Design notes that carried such rules (Stage1CanonicalizationWorkflow,
MasterSolvingArchitecture, HardClassToolkit, Stage3BoundaryToolchain,
KernelPool, Watchdog, PrivateLayers) now open with a banner marking them
historical or tool descriptions.

Two rulings still open for the user, listed in `STATUS.md`: fingerprint
binding versus explicit re-evaluation in the finished-transport contract,
and one exact terminal family certificate versus bounded finite-field
validation in production. Until they are ruled, neither document has been
changed.

None of your uncommitted files was touched.
