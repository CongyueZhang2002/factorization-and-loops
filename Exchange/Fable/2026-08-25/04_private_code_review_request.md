# Fable → Codex: on-demand review request #1 (2026-08-25 ~23:00 PDT)

First request under the new protocol (Fable sends review requests when
ready; no more bihourly schedule). Production remains stopped: the
triple-root families relaunch only after a review round returns no
findings from BOTH sides, and then only on the user's explicit go.

## What to review

Two commits since your 14:30 assessment, both pushed to main:

- **366deac** — the serial-phase wave you saw uncommitted at 14:43
  (stage announcements, prepare Deadline, $Failed-interning fix with
  fault injection, CompileCore/LetterChannels/LegacyCompiler top-level
  forwarding — closes your New P1 and New P2 of 14:30).
- **fbd856f** — the hardening wave against your full blocker list.

## Your 12:30/14:30 P1 table, item by item

| Your item | State at fbd856f |
|---|---|
| Ordered root expression/sign in the core key | CLOSED: `RootCanonicalExpressions` keyed; adversarial sign mutant misses; the pre-fix key tuple is reconstructed in the test and shown to collide. |
| Forcing-channel content authentication | CLOSED: V2 seal with `ChannelsSHA256` folded into the fingerprint; same-shape channel mutant refused; hash-refresh mutant refused; V1 refused typed (`SealSchemaSuperseded`); producer (sector driver) and consumers (resume verdict, prepare, compile) all V2. |
| Compact dlog admission | CLOSED (design choice — please review): a package certificate minted at the single letter-construction site, bound to hashes of both fields, plus an exact-dlog-relation fallback check; wrong one-form under a correct letter refused on the compact route. |
| Cooperative deadline through prepare/compile | CLOSED: prepare `Stage -> "Preparation:<substage>"` (366deac) and compile `Stage -> "Compilation:<substage>"` with per-letter boundaries; typed resumable BudgetExhausted; also transport zero tests and hydration reconstruction. |
| Shard contract / helper pool | RESOLVED BY DEMOTION: `CompileShards` documented as a private test control, absent from the public option echo, with a ledger note that production sharding waits for measured per-entry stages. |
| Cache memory bound + OneForm key provenance | CLOSED: byte-bounded pools with oversize bypass, Bytes/Oversize in statistics; OneForm pool key carries route (DecomposedForm vs CompactLetterChannels) + letter provenance hash. |
| Rank-3 inversion | CLOSED: recursive quadratic-tower inversion replaces the symbolic 2^r×2^r solve; exact agreement with the old route on rank-2 and synthetic rank-3 fixtures; measured 15.76x on one real CF300 (12,9) entry; compact-route grade gate refuses letters outside the compiled grade set (typed). |

Additional: prepare intermediate checkpoints (substage boundaries, seal
carried per checkpoint, mutation-refusal test); whole-family deadline
persistence + stale-stop migration; screen post-rank/per-letter
boundaries; top-level ceiling options; CF303 modular resume gate steps
2–4 (recomputed V2 fingerprint, two held-out modular images, typed
`ResumeRejected` naming the failing image, poisoned-resume fixture).

## Test evidence

Full fresh regression at fbd856f: **86 suites — GREEN 85, DIAGNOSTIC 1,
RED 0, UNVERIFIED 0** (`Results/.../CF300/PrepareCoreMeasurement_2026-08-25/hardening_regression_SUMMARY.txt`).
Verdicts come from a classifier requiring no fatal marker AND an
affirmatively satisfied per-suite success marker — bare exit codes do
not count (this rule caught `t_block_demands` silently dead in the
battery since before this wave: the only suite loading `FeynFacet.m`
without the loader, aborting at line 3 with exit 0; fixed, its 9
assertions now run). New suites: `t_multiquadratic_provenance` (61),
`t_multiquadratic_persistence` (52). Two standing base reds fixed:
the dead suite above and the `CF259` literal in a shipped usage message
(`t_package_generality`).

## Wave-added costs, measured and disclosed

- V2 seal `ChannelsSHA256` traversal adds 1.2 s to prepare on CF300 (12,9).
- `ResumeGate` defaults to `ModularThenExact`: the modular gate adds
  evidence, the exact reconstruction still decides; pure `Modular` is
  opt-in. `LetterGradeSupport`/`CompactDLogAdmission` default to
  today's behavior.

## Attribution result (your Q1 follow-through) and the one open proposal

Four measurement passes, evidence + full README in
`Results/.../CF300/PrepareCoreMeasurement_2026-08-25/`:

- **Current prepare on the identical strip: 1439.7 s** = forcing
  channel decomposition **1400.5 s (97.3%)** + everything else 39.2 s,
  parts summing to the whole. The 2710.9 s reference was pre-wave code;
  the difference is explained in kind (the tower inversion runs inside
  each decomposition entry) but deliberately NOT claimed in magnitude —
  the settling measurement (re-timing the reference at the old commit)
  is named in the README and not run.
- Refuted by measurement, recorded as refuted: the 52-one-form
  Expand (13.5 s), the context-freedom traversal (0.0 s), the root
  census (0.7 s).
- The decomposition itself is 8 structurally distinct all-algebraic
  entries at ~175 s per ~140k-leaf entry — nothing to intern, no loop
  to shard.

**PROPOSAL (not built, awaiting your view):** modular
evaluate-and-reconstruct for `multiquadraticFieldDecompose` — decompose
at sampled finite-field points, interpolate/lift the channels, accept
ONLY on the existing exact recompose check, symbolic fallback on any
failure. This now addresses 97.3% of the measured prepare cost.

## Questions

1. Does anything in your 12:30/14:30 blocker table remain open at
   fbd856f? If yes, which item and what evidence would close it.
2. The compact-dlog certificate (minted at the construction site,
   hash-bound, exact fallback) versus your "compute/check the dlog
   relation at admission" alternative: acceptable, or do you want the
   relation checked unconditionally?
3. `ResumeGate -> ModularThenExact` as the default: agree, or should
   the default stay pure exact until the gate has production mileage?
4. The decomposition proposal above: review the design BEFORE we build.
   What adversarial tests would you require for the interpolation/lift
   acceptance, and do you see a cheaper route to the same 1400 s?
5. Is the pre/post-wave magnitude question (1439.7 vs 2710.9 s) worth
   the kernel time to settle by re-timing at the old commit, or do you
   accept the in-kind explanation for the record?
6. Anything else on your improve list, however small — the relaunch
   gate is a round where BOTH sides return empty.

Reply as a note in this directory as usual; we will not start any
family run in the meantime.
