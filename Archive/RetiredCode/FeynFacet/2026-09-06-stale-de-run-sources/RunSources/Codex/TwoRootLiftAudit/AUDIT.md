# CF254 modular interpolation and rational-lift audit

Date: 2026-08-19

## Scope

This audit reads the saved CF254 `(9,8)` finite-field samples and epsilon
interpolations in `Codex/TwoRootSharpSimultaneous`. It does not regenerate a
sampled differential system and does not compose the strip result into the
complete family.

The reconstructed vector contains 977 coordinates:

- 968 coefficients of the entries of a `4 x 2` gauge matrix,
  with ordering `(i,j,p_x,p_y)` and `p_x,p_y=0,...,10`;
- 9 affine residue parameters.

The sampled affine solution has nullity eight. The normalization sets residue
coordinates 969 through 976 to zero and leaves coordinate 977 determined by
the two differential equations.

## Mathematical reconstruction

For each coordinate, epsilon interpolation produces

```text
f(epsilon) = N(epsilon)/D(epsilon),
```

where the coefficient lists are stored from constant term to highest power.
The denominator is monic and `gcd(N,D)=1` over every finite field. Coefficients
at distinct primes are combined coefficient by coefficient using the Chinese
remainder theorem. FiniteFlow's `FFRatRec` then reconstructs each integer
residue modulo the combined modulus as a rational number.

If a reduced rational coefficient is `a/b`, Wang reconstruction has the
standard sufficient uniqueness range

```text
max(|a|,|b|) < floor(sqrt(M/2)),
```

where `M` is the combined modulus. A returned rational outside the true
coefficient's uniqueness range is merely one fraction congruent to the modular
data; `FFRatRec` does not certify that it is the intended rational number.

## Checks executed

The audit obtained the following exact results.

1. All five moduli are prime and pairwise coprime.
2. The coordinate map is a bijection from `(i,j,p_x,p_y)` to `1,...,968`.
3. `FromDigits[Reverse[coefficients], epsilon]` correctly interprets the stored
   low-to-high coefficient order.
4. The same eight residue coordinates define the affine normalization at every
   saved prime. They vanish in every normalized sample.
5. The three original interpolation artifacts reproduce all their saved
   samples: 33 samples at `1000003` and 11 samples at each large prime.
6. Every interpolated numerator-denominator pair is reduced and has monic
   denominator.
7. CRT residues reduce back to every input prime exactly.
8. Independent synthetic fractions, including negative and nontrivial
   numerators and denominators, are reconstructed exactly by `FFRatRec`.
9. An independent fourth-prime interpolation made only from already saved
   samples is entrywise identical to the stored fourth-prime interpolation.
10. The four-prime candidate satisfies the sampled finite-field equation at a
    point used in construction and at a fresh chart point, but fails exact
    characteristic-zero substitution. Thus the failure occurs in rational
    lifting, not in the finite-field matrix equation or coordinate ordering.
11. The saved five-prime result has all three rational-point checks zero and
    all 16 symbolic Pfaffian residuals zero.

The epsilon degree pattern is identical at every prime:

| degree `(deg N, deg D)` | coordinates |
|---|---:|
| zero | 348 |
| `(2,2)` | 540 |
| `(1,1)` | 88 |
| `(0,1)` | 1 |

## Why four primes were insufficient

There are 4,291 raw rational coefficients across all interpolated numerator
and denominator polynomials. The five-prime result determines their actual
heights. The cumulative reconstruction history is:

| primes used | combined modulus | Wang bound | true coefficients outside bound | coefficients reconstructed differently from five-prime value |
|---:|---:|---:|---:|---:|
| 1 | `1000003` | `707` | 1429 | 1429 |
| 2 | `2147490089450941` | `32768049` | 1429 | 1429 |
| 3 | `4611699810535641396144889` | `1518502520665` | 1197 | 1145 |
| 4 | `9903549651296299576738914201436843` | `70368848403595108` | 464 | 401 |
| 5 | `21267710091513184983770675390052891325111609` | `3260959221725502119113` | 0 | 0 |

The largest true numerator magnitude is `807163402367857`, while the largest
true denominator is `57828238570065196800`. The latter is about 822 times the
four-prime Wang bound. Every coefficient that changed when the fifth prime was
added lies outside the four-prime bound. The 401 incorrect raw coefficients
occur in 198 of the 977 reconstructed coordinate functions. Seven coefficients
even violate `2 |a| |b| < M_4`.

Therefore the failed one-, two-, three-, and four-prime exact checks arose from
insufficient modulus. The CRT ordering, coefficient ordering, polynomial
normalization, and `FFRatRec` call are correct for the saved data.

## Remaining correctness risks

The current five-prime CF254 result is certified by exact symbolic substitution.
The following implementation risks remain for reuse on another strip.

1. `lift_and_check_cf254.wls` loads every matching interpolation file. It does
   not explicitly require distinct prime moduli, primality, or pairwise
   coprimality before calling `ChineseRemainder`.
2. `FFRatRec` can return a plausible but wrong rational below the required
   modulus, as happened for one through four primes. A successful function
   return is not a certificate. Exact symbolic residuals must remain mandatory.
3. A held-out prime should be used before the expensive symbolic check. The
   candidate reconstructed from a chosen prime set should reduce to the full
   interpolation at a prime excluded from that set. This would have rejected
   the four-prime candidate immediately.
4. The lift script checks degree equality but not exact coefficient-list
   lengths, monic denominator normalization, or polynomial coprimality.
   `PadRight` can conceal a malformed list. These conditions should be checked
   before CRT.
5. The gauge coefficient count and residue slice `969 ;; 977` are hard-coded.
   They should be derived from matrix dimensions, polynomial degrees, and the
   recorded residue list.
6. A candidate file is written before either rational-point or symbolic
   verification. A failed lift can therefore look like a finished result.
   Write the final candidate atomically only after exact residuals vanish, or
   include an explicit certified-status field.
7. The epsilon interpolator assumes that a basis vector of the modular
   nullspace gives the rational function. This is harmless here because the
   first admissible degree has one-dimensional nullspace and held-out samples
   agree. A general implementation should require nullity one at the selected
   degree or solve a monic inhomogeneous system directly.
8. The seven-factor gauge denominator is duplicated by hand between scripts.
   It should be retained once with the strip record to prevent inconsistent
   edits.

## Retained audit files

- `audit_cf254_lift.wls`: normalization, ordering, interpolation, CRT, synthetic
  reconstruction, fourth-prime interpolation, and exact-point checks.
- `analyze_modulus_threshold.wls`: coefficient-height and cumulative-modulus
  analysis.
- `audit_result.wl`: machine-readable result of the first audit.
- `modulus_threshold_result.wl`: machine-readable coefficient-height result.
- `largest_changed_raw_coefficients.wl`: the twenty largest changed raw
  coefficients.
- `CF254_9_8_epsilon_interpolation_mod_2147483587_from_saved_samples.wl`:
  independently reconstructed fourth-prime artifact.

No file in `Codex/TwoRootSharpSimultaneous` was modified by this audit.
