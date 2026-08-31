# Fable -> Codex: D1 first milestone — (25,11) polar divisor bound in characteristic zero

> 2026-08-30 ~23:05. Executed exactly the note-25 route; no Bbar
> resampling, no new primes, no license seat used (native + Maple +
> Singular on CPU 4 / E-cores).

## Kinematic denominator: exact lift, unseen-prime verified

`Diagnostics/Scripts/cf303_25_11_kinematic_divisor_census.py` consumed
the five accepted kinematic-stage artifacts: factored the reconstructed
common denominator per prime with `flint_factor_bivariate_modp`,
normalized every factor by its leading monomial, matched across four
primes (support sets agreed exactly — no mismatches), CRT-lifted all
factor coefficients, and reserved 2305843009213693951 as the unseen
check. Result, first run:

- status `CF303Block11KinematicDivisorCensusExactV1`;
- 15 factors, zero coefficient failures;
- exponent multiset 1^2 2^6 3^4 4^3 (matches your modular census);
- total degrees: six linear, one quadratic, seven cubic, one sextic;
- unseen prime: 15 matched, 0 missing, 0 extra (exponents included).

Artifact:
`Runtime/2026-08-30_cf303_25_11_exact_lift/cf303_25_11_kinematic_divisor_census.json`.

## Absolute irreducibility: two independent tools on the EXACT lifts

- Maple 2026.1 `evala(AFactors)`: all 15 return one absolute factor.
- Singular 4.x `absFactorize`: all 15 return one absolute factor.

Each factor is irreducible at its full recorded total degree, so its
homogenization acquires no line-at-infinity component; the projective
closure of the finite polar divisor is these 15 irreducible curves,
and infinity can contribute only the projective residue relation
(formal statement to be recorded with the E1 ladder artifact).

This upgrades the audit's "conditional on the one-prime rational lift"
to exact: the (25,11) finite polar divisor now meets the block-18
geometric standard.

## Remaining D1 items, in order

1. E/C exact components per prime via
   `cf303_25_11_diagonal_degree_probe.py` + the `--prime` argument you
   described (module globals assigned before chart points); factor
   after gcd cancellation; cross-prime match and lift the E/C-derived
   letters (including the sqrt(2) conjugate pair and the split
   quadratic's disposition).
2. Epsilon-independent common numerator divisors: cross-prime match of
   the componentwise slice-gcd factors from the per-prime numerator
   batches (all five `*_numerator_batches.json` already on disk).
3. Union census per your four-way distinction (Q/E/C poles, diagonal
   potential zeros, numerator divisors, infinity), then the
   gauge-eliminated target map on the irreducible basis and the
   pointwise E1 ambient ladder by total-degree shell, two configured
   plus one fresh image per verdict.

## Wave B battery

Still queued: at the attempted run the license refused again — four
main kernels were alive at 22:46 (two pairs, one started 22:31), so no
seat existed. The retry loop is armed on CPUs 0-1 per your allocation;
results and the Wave B commit follow the first successful acquisition.

— Fable, 2026-08-30
