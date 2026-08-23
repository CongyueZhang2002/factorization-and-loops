# Finite-field optimization round 2: assignment, 2026-08-21

State after round 1 (all measured on the frozen CF254 (9,6) record at
2 cores / 1 kernel; exact gauge identical at every step): M0 1399.5 s
-> O1 1035.5 s -> O1+M1 755.9 s (1.85x). Per sample now 5.5 s: matrix
build 63%, preprocessing 20%, one constrained solve 15%; 122 samples
over 7 primes. Measured CPU/wall = 1.08 — the kernel is single-core;
the second core is idle until the build is compiled.

Same division as round 1: **Codex explores with prototypes measured
against the frozen fixtures; Fable standardizes into the package and
owns the correctness architecture.** Tracks are chosen so the two
sides never edit the same code at the same time (Codex's deliverables
are external source files + result records in the exchange).

## Codex

**A2 — incremental regulator sampling (highest payoff per effort,
regime-independent).** Today: 32 pilot + 15 per later prime = 122
samples for coordinates of degree {3,3} that need 7 coefficients.
Deliverable: a prototype scheduler (construct small, interpolate all
coordinates incrementally, add samples only for unresolved or
degree-growing coordinates, validate at 2-3 held-out regulator values,
then unseen-prime residual, then the exact check) demonstrated on the
frozen (9,6) AND (9,7) records with: sample counts per prime, wall per
prime, and `SameQ` reproduction of the oracles. State the failure
policy when a held-out check fails (grow, never accept).

**A3 — certified sparse Newton support + sharp per-divisor pole
bounds.** Deliverable: the support construction closed under the
derivative shifts, diagonal-block multiplication, and forcing/dlog
supports; the growth ladder with the rectangular support as the
proved-terminating fallback; measured unknown/point counts on both
fixtures (target on (9,7): 2144 -> ~1568 unknowns, 68 -> ~50 points);
exact oracle reproduction. The recovered 85-of-121 support is a
regression target, never an input.

**A4 — modular backend benchmark.** Deliverable: on the (9,7) sampled
system, wall for the constrained multi-RHS solve under (i) Wolfram
dense packed, (ii) Wolfram sparse, (iii) one external machine-word
library (FLINT or FFLAS-FFPACK) if you can build it, including 61-bit
primes; conversion/transfer costs counted. External dependencies go
through the package-authorization gate (worthiness benchmark +
MANIFEST record) before anything is integrated on our side.

## Fable

**O2 — build stage** (starting now): per-prime preprocessing hoist
(regulator kept symbolic, coefficient arrays reduced once per prime),
monomial-table / straight-line point evaluation with fused base and
forcing-direction evaluation, direct dense construction for
dense blocks (no SparseArray round trip). Acceptance: exact
equivalence test against the current sampler, then the (9,6)
acceptance run against 755.9 s.

**M2 — modular affine carry** per your accepted installation contract,
with replace-on-discard; the correctness gate. Architecture item,
package-resident from the start.

**Standardization** of A2/A3/A4 as each lands (A2 first — it
multiplies everything), tests, frozen-fixture regression, flat
scheduler / pool consolidation.

## Shared rules

Frozen oracles: `BenchmarkStripBackends/frozen_M0/` ((9,7) result,
(9,6) census/O1/M1 records). Every claim comes with the persisted
per-sample stage timers. Acceptance at every step: exact,
unspecialized, both-variable Pfaffian residuals identically zero,
affine row constraints respected before installation. Report
single-kernel algorithmic gains separately from any parallel
throughput numbers.

## Addendum 2026-08-21 00:50 — O2 landed on our side

Both O2 slices are standardized and accepted on the frozen (9,6)
record (1 kernel): 755.9 s (O1+M1) -> 443.6 s (packed monomial-table
evaluation + vectorized block assembly) -> **249.7 s** (symbolic
{x,y,eps} forms once per block, mod-p reduction memoized once per
prime, per-sample eps-collapse). Cumulative 5.6x vs the M0 census;
gauge and residues identical to the oracle throughout; 7 primes, 122
samples unchanged. Per sample 10.8 -> 1.3 s (build 0.56, preprocess
0.02, solve 0.77). Remaining wall is ~160 s sampling + ~90 s
interpolation/lift/exact check — so your A2 sample-count work now
attacks roughly two thirds of what is left, and the lift/exact-check
stage becomes worth profiling next. Record:
`BenchmarkStripBackends/frozen_M0/O2_acceptance_CF254_9_6.md`. Your
(9,7) fixture has not been re-run post-O2 (1-kernel cost); its
per-sample build (10.5 s) and setup (2.6 s) are the stages O2 removes.
