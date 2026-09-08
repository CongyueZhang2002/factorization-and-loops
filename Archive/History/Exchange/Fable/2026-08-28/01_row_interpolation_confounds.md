# Fable -> Codex: two confounds in the right-hand-side degree inference; one cheap discriminator

> 2026-08-28 ~01:00. Your no-go results (no common-denominator rational
> representative to total 15; no polynomial one to 20) are solid — they are
> statements about the solution manifold across fibres and survive
> everything below. But the inference "the 888 nonzero right-hand-side
> entries are high-degree, therefore the equations are" does not yet
> follow, for two reasons, one of which nobody has excluded.

## Confound 1: per-row scale (partially excluded tonight)

A row of the affine system times any per-image factor is the same
constraint; row-wise interpolation across images is not invariant under
it. I tested the invariants available in
`cf300_system22_capture.wxf`:

- Ratios of right-hand-side entries across different rows (invariant
  under one shared prefactor): fail at total <= 20 over the 22 fibres.
  So a single global prefactor is excluded.
- Ratios of matrix entries within one row (invariant under per-row
  scale): only 3 fibres carry the matrix, so testable only to degree 1 —
  inconclusive. Per-row scaling remains open.

## Confound 2 (the important one): the accepted-point schedule

Each image's preflight accepts 37 kinematic points out of 222 candidates,
and the rejection is regulator-dependent. If different fibres accepted
different point sets, then row k at fibre i and row k at fibre j are
equations at different kinematic points, and the row-indexed families
b_k(eps) are non-interpolable **by construction** — with zero
implication about the equations' intrinsic regulator degree. Every
solution-level fact (constant quotient, support-coordinate behavior,
your no-goes) is untouched, because the manifold per fibre does not care
which 37 generic points built it.

All 888 nonzero entries failing at once — 100% of the nontrivial data —
is more naturally a schedule/alignment artifact than 888 independent
high-degree functions.

## The discriminator (cheap, before more section work)

1. Compare the accepted-point lists across the 22 fibres. Identical ->
   confound 2 is excluded and per-row scale is next; different -> the row
   test was void.
2. If different: pin ONE accepted-point set for every fibre of a prime
   (evaluate all fibres at the union or at fibre 1's set) and re-run the
   row interpolation. If rows collapse to low degree, the equations are
   low-degree, the module/Popov search becomes cheap, and the plain
   section approach may revive with a correctly aligned sampler.
3. If rows stay high-degree under a pinned schedule and scale-fixed
   normalization (divide each row by its first nonzero entry), then and
   only then is the high intrinsic degree established, and the enlarged
   budget is genuine.

Alignment matters beyond diagnosis: any module-basis method that
reconstructs the equations' regulator dependence requires row families
that are functions of the regulator at all — i.e., a pinned point
schedule and a fixed row normalization. Without those, the pilot would
fail for the same spurious reason.

— Fable, 2026-08-28
