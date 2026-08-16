# Hard classes 97, 77, 79 — eps-graded route artifacts

All three remaining connection classes (97 = CF258_B9, 77 = CF230_B1,
79 = CF231_B1) are order-4 irreducible at generic epsilon (two-point
ore_algebra factorization verdicts + exact symbolic order-1 Beke
exhaustion for 97; Design/HardClassToolkit.md records the method), so
no epsilon-form or factorization ladder exists.  Their eps=0
degenerations factor COMPLETELY into first-order pieces, which makes
the epsilon-graded scalar recursion (Scripts/EpsilonGraded.wl) the
forced route: L = L0 + eps L1 + ..., L0^{-1} by four exact quadratures
per order through the verified factor chain.

## Files

- `eps0_c97_factored.wl`, `eps0_c77_factored.wl`, `eps0_c79_factored.wl`
  — the symbolic eps=0 first-order factor chains with the operator
  coefficient lists (symbolic eps).  Every chain carries an exact
  recomposition certificate, re-checked by Tests/t_epsilon_graded.wls
  from the stored data (stored status is never trusted).
  Chain provenance: 97 by constructive peel over the DSolve kernel
  (rational-dlog span extraction); 77/79 first two factors by
  forced-degree integer-exponent Beke peel, third factor by
  ore_algebra sampling at 24 rational w-points + adaptive rational
  interpolation in w, certified by exact symbolic right-division
  (interpolation is a candidate generator only), fourth factor by the
  final division quotient.
- `c97_egsolve.wl` — class-97 particular solution continued from the
  rational kernel element through eps^3 in the x-direction, each order
  carrying an exact residual certificate (all True; 0.15 s / 94 s /
  785 s per order).  Letters: the 5-letter x-alphabet plus one
  apparent letter 2/(y-1) from the chain's stage weights (gauge
  artifact, linear in x, harmless to the word algebra).

## Open

- y-direction pinning of the per-order homogeneous functions (four
  functions of y per order, to be fixed by the A_y equation up to true
  constants; the constants are stage-3 boundary data).
- 77/79 epsilon-graded solves: their reconstructed third factors carry
  an apparent SEXTIC in the stage weights, which the quadrature engine
  does not accept; a broadened gauge scan (random cyclic covectors,
  letter-only weight acceptance) is the active route to clean chains.
- Cross-check of the 97 solution against Codex's independent
  sparse-GPL recursion (different scalar gauge, so system-level
  comparison after reconstruction).
