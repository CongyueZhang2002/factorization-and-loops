# E1 ambient ladder design for CF303 (25,11) — checkpoint 2026-08-31 ~00:40

Target script: factorization-and-loops-codex/Diagnostics/Scripts/
cf303_25_11_e1_ambient_ladder.py (adapt cf303_25_11_rank0_affine_solve.py).

## The solve (per image prime, per shell degree d)

Row equation per point, per axis mu in {t,s}, per target row (block is
2 rows x 1 column):

  B_target,mu = sum_src [ delta * d_mu(phi_m)
                          - eps E_mu(target,src) phi_m
                          + delta * eps C_mu phi_m ] g_(src,m)
                + eps sum_i r_(i,target) dlog_mu f_i
                + eps sum_(deg m <= d) a^mu_(m,target) m(t,s)

- phi_m = m/gauge, gauge = product of Q factors^(exponent-1)
  (factor_denominator in the rank0 driver; keep its ladder of gauge
  supports OR fix support at the exhausted maximum — decide from the
  exhausted artifact's attempts).
- Letters f_i = the 17 affine curves of
  cf303_25_11_divisor_union_census.json (15 Q + root2 + s+1);
  line_at_infinity is represented by the polynomial directions.
- NEW third block of unknowns: polynomial residue directions
  a^t_(m,row) (only in mu=t rows) and a^s_(m,row) (mu=s rows),
  m = monomials t^i s^j with i+j <= d. These are the regular
  directions the alphabet-completeness audit says the exhausted
  production-alphabet ladder omitted (span-relative claim).
- Columns: 2|support| + 2*17 + 2*2*|monomials(d)|.
- RHS: forcing Bbar values.

## Two usable images (user rule; note 27/29: third image only replaces)

- Image 1, p = 2147483423: forcing from the accepted full-Bbar tensor
  (cf303_25_11_full_bbar_modp.json, bbar_values), E/C from
  strip_diagonal_selected_eval — exactly the rank0 driver path.
- Image 2, p = 2147483399: NO tensor exists at this prime — sample
  forcing pointwise with the native Sampler ("physical" contract, the
  numerator-batches route) and E/C likewise; set selected.PRIME /
  rational.PRIME module globals BEFORE chart points (diagonal-probe
  pattern), p must be 3 mod 4, 31-bit; request header carries the
  prime so no native rebuild.

## Verdict per shell

- CFFR (flint_affine_rref) solve; acceptance = exact replay at fresh
  disjoint admissible points (draw_points with forbidden set).
- Shell verdict only when BOTH images agree (both consistent-> outcome
  A candidate; both refused -> climb; disagreement -> replace the bad
  image, never add a third check).
- Outcome A at any shell: proceed to the honestly overdetermined
  functional solve; on success the (25,11) exception record is
  WITHDRAWN (note 14 outcome A).
- Ladder exhausted through declared cap (start d<=4): bounded E1
  obstruction label at the block-18 standard, now on the COMPLETE
  span (this is what upgrades the span-relative refusal to the
  impossibility bar of note 09).

## Traps already paid for
- rational.trim / selected-module PRIME are call-time globals
  (normalize mod PRIME!) — set both before every multi-prime use.
- contract() now takes prime with default 2147483423 (back-compat).
- FLINT factor order is not canonical across primes; irreducibles can
  split mod p — never pair by index (binding script pattern).
- Points must avoid zeros of gauge, ALL letters, and Q (draw_points
  already does; extend the letter list to the census).
