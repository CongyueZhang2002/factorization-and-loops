# Assessment of Fable's optimized modular final checker

Date: 2026-08-22

Scope: review of

- `External/CodexExchange/fable_final_check_2026-08-22/fable_final_check_change_2026-08-22.md`
- `FeynFacet/Private/FamilyCertificateModular.wl`
- the modular branch of `FeynFacet/Private/FamilyEpsForm.wl`
- the repository regression `Tests/t_family_certificate_modular.wls`
- fresh adversarial and 32x32 real-family stress tests

No package source or family result was changed.  The two executable reproducers
beside this report are external diagnostics only.

## Bottom line

The speedup is real and valuable.  On two independent reruns, the full CF265
and CF305 32x32 certificates took about 17--18 seconds each; CF231 took about
10 seconds.  The compiled finite-field evaluation, inverse/gauge/flatness
checks, epsilon-linearity test, and ordinary full-rank dlog solve behave well
on the real records and on ordinary corruptions.

The present implementation is nevertheless **not sound enough to use the
`ExactEpsilonForm` verdict as a final gate**.  The stress suite found direct
false acceptances, a concrete underestimate in the advertised degree bound,
and residue evidence which is missing or wrong while the exact verdict remains
true.  These are checker issues; they do not by themselves show that CF265 or
CF305 is mathematically wrong.

My recommendation is to retain the modular engine, fix the P0 items below, and
call the result probabilistic unless an exact finishing step is added.

## Reproduced findings

### P0: a nonzero form with an empty denominator alphabet is accepted

`familyCertificateModular` initializes `DLog` and `ConstantResidues` to `True`.
The residue branch only runs when `letters =!= {}`.  If the alphabet is empty,
there is no check that both epsilon-form matrices are zero.

Minimal example:

```wl
B_x = {{eps}};
B_y = {{0}};
T = Tinv = IdentityMatrix[1];
A = B;
```

All other identities are valid, but this is not a rational dlog one-form.
Observed:

```text
modular  -> ExactEpsilonForm, DLog=True, Letters={}
symbolic -> EpsilonFormCertificationFailed
```

Relevant implementation: `FamilyCertificateModular.wl:161-162, 208-232` and
the unconditional trust/fabricated zero reconstruction residual in
`FamilyEpsForm.wl:351-357`.

### P0: the letter extractor can miss denominators of uncombined sums

`familyCertLetters` applies `Together` only when the *raw denominator* is not a
polynomial.  For an entry such as `eps (1/x + 1)`, Mathematica reports the raw
denominator as `1`, so no `Together` is applied and the `x` letter is lost.
The numerical compiler does apply `Together`, so the evaluator and alphabet
are then based on different rational representations.

Observed:

```text
eps (1/x + 1)       -> Letters={}, modular accepts, symbolic rejects
Together[that form] -> Letters={x}, modular rejects at DLog
```

Relevant implementation: `FamilyCertificateModular.wl:97-103`.  Always form
`rat = Together[entry]` before taking `Denominator[rat]` and factoring it.

The mathematical answer to the cancellation question in Fable's note is:
the pole alphabet is sufficient for a rational constant-residue dlog form
*after canonical rational combination*.  A letter which cancels completely
has zero net residue and need not be retained.  One must separately reject a
nonzero polynomial part (the pole at infinity).

### P0: the recorded dlog rank is not checked

The change note says `DlogRank == #letters` is checked.  It is only recorded at
`FamilyCertificateModular.wl:233-234`; it never affects `DLog` or
`ConstantResidues`.

I forced the prime `p=8388617` and used the characteristic-zero letters

```text
L1 = x
L2 = x + p y
```

They collide modulo `p`.  The checker reported two letters, rank one, and still
returned `ExactEpsilonForm`.  The example itself is a valid dlog form, so this
is a clean test of the gate rather than a disputed canonical form.

A rank-deficient prime should not certify.  Prefer discarding it and drawing a
new distinct prime; the simpler safe fallback is to fail with
`DlogRankDeficient`.

### P0: residue reconstruction and verification do not gate the verdict

The current code reconstructs from one 24-bit prime only.  If reconstruction
fails, `DLog` and `ConstantResidues` remain true.  If reconstruction succeeds
but disagrees at a later prime, only an informational `Verified` field changes;
the exact verdict still remains true.  The public modular branch then fabricates
a zero `ReconstructionResidual` whenever `DLog=True`.

This is not just synthetic:

```text
CF265: ExactEpsilonForm, rank 15/15 at all primes,
       ResiduesVerifiedAtOtherPrimes -> Missing
CF305: ExactEpsilonForm, rank 15/15 at all primes,
       ResiduesVerifiedAtOtherPrimes -> Missing
```

Two sharper synthetic observations:

1. With the true residue equal to the first sampled prime, the stored residue
   is zero, verification later is `False`, and the status is still exact.
2. Verification is not sticky.  For true residue `p1*p3` and sampled primes
   `{p1,p2,p3}`, the stored residue is zero, it mismatches at `p2`, matches at
   `p3`, and the final flag is reset to `True`.

Relevant implementation: `FamilyCertificateModular.wl:219-231` and
`FamilyEpsForm.wl:351-357`.

Collect the unique full-rank solution `K mod p_i` for every prime, combine each
entry with `ChineseRemainder`, rationally reconstruct against the product
modulus, and require agreement at **all** primes.  Add primes adaptively if the
product is too small.  A missing or unverified residue must make
`ConstantResidues=False` for a final certificate.

### P0: the advertised degree bound can be an underestimate

The degree expression at `FamilyCertificateModular.wl:143-155` has no separate
source-flatness term.  A one-dimensional chart-free counterexample gives:

```text
reported DegreeBound                 = 11
actual source-flat numerator degree  = 14
```

The source connection used by the reproducer is

```wl
Av = {{(x^5 + x y + y)/(x^4 + x y + y + 1)}};
Aw = {{(y^5 + x y + x)/(y^4 + x y + x + 2)}};
```

with `S=I` and `B=0`.  Differentiation squares generic denominators, and the
two derivative terms then need a common denominator.  The gauge-derived
`nA+dA+2` envelope does not cover that numerator.

Therefore the answer to degree-bound question 1 in Fable's note is **no for the
implemented aggregate bound**, even if `n^2 d_M` is a valid loose common-
denominator bound for a single matrix direction.

The safest repair is to propagate pairs `{numeratorDegree, denominatorDegree}`
through rational operations:

```text
mul({n1,d1},{n2,d2}) = {n1+n2, d1+d2}
deriv({n,d})          = {n+d-1, 2d}
add(terms)            = common-denominator bound across every term
matrix product        = add(n copies of mul(left,right))
```

Build a separate bound for inverse, gauge, transformed flatness,
epsilon-factorization, dlog reconstruction, and source flatness.  For a chart,
the source-flat numerator must also be bounded after composition with the map.

### P1: the dlog probability exponent reuses fitted points as validation

The dlog residues are fitted from all sampled rows and consistency is checked
on those same rows.  The error formula then counts every point as an independent
identity-test point.  With `L` fitted letters, those data have already consumed
at least `L` scalar row constraints.  The usual fixed-polynomial
Schwartz--Zippel exponent cannot simply be `points * primes`.

For CF305 there are 15 letters and 12 points (24 rows) per prime.  A clean
design would use about eight points to obtain a full-rank 15-column solve and
four fresh points for validation.  With the second run's
`d=148651` and `p_min=11395547`, a rough explicit-split dlog union bound is of
order

```text
2*32^2*(d/p_min)^(4*3) ~ 10^-19,
```

not the recorded `1.17e-64`.  This is still a useful safety margin, but it is a
different claim.  The current all-at-once solve has no recorded prefix rank or
held-out set from which even that split can be audited.

Fix: use a two-phase solve.  Sample training points until the dlog design has
full column rank, solve once, then test the fixed solution on `NValidation`
fresh points.  Record both sets/counts and use only validation points in the
dlog exponent.

### P1: primes are sampled with replacement and duplicate trials are overcounted

`Table[RandomPrime[...], count]` does not enforce uniqueness.  A forced
threefold duplicate produced

```text
Primes     -> {p,p,p}
PointsDone -> one record
ErrorBound -> exponent still counts three primes
```

`results[p]` is an association keyed by the prime, so duplicates also overwrite
earlier point records.  Draw until `DuplicateFreeQ[primes]`, validate that the
requested count is positive, and key results by trial index or retain a list.

### P1: bad-characteristic probability is acknowledged but not part of the bound

Fable's note correctly calls this out, but it means the stored
`IdentityErrorBound` is not the total error probability.  A reproducible form
with polynomial contamination whose integer content was the product of the
three selected primes passed modular certification and failed symbolic
certification while reporting `2.56e-144`.

At minimum rename the field to
`IdentityErrorBoundConditionalOnGoodCharacteristics` and store a separate
bad-prime term.  A cheap hybrid characteristic-zero validation point after a
modular pass is another practical guard.  Merely recording input `HeightBits`
does not yet bound the height/content of every residual polynomial.

### P2: smaller probability/accounting and reproducibility issues

- The union multiplier `8 n^2` covers inverse (2), gauge (2), transformed
  flatness (1), epsilon factorization (2), and source flatness (1), but omits
  the two dlog component identities.  Use separate `8 n^2` and `2 n^2` terms.
- Accepted points are rejection-sampled away from poles and from `{0,1,-1}`;
  the exact sampling domain is not `F_p^3`.  Condition the bound on the safe
  set or use the corresponding denominator-degree correction.
- `e2` may equal the first epsilon value, making that point's epsilon test
  vacuous.  Resample until it is distinct.
- Primes are recorded but sampled points/seed are not, so a certificate cannot
  be replayed.  Record the point triples and second epsilon values, or record a
  deterministic seed plus the algorithm version.
- Packed integer dot products and derivative coefficient multiplication have
  no monomial-count/height overflow guard.  Current 23x23/32x32 families are
  small enough, but the certificate should either assert the safe 64-bit
  envelope or fall back to modular accumulation.
- Cap any displayed probability bound at 1 and reject nonpositive/noninteger
  point and prime counts.

## Answers to the other mathematical questions

### Epsilon factorization

`e2 B(e1) = e1 B(e2)` is the right probabilistic rational-identity test for
`B/eps` being independent of `eps`, provided both regulator values are nonzero,
distinct, and away from poles.  It is not a deterministic equivalence after a
finite number of samples.  Its numerator needs its own four-variable degree
bound (or a conservative reduction to the stored bound), and the bad-prime
term still applies.

### Source flatness in source variables

The direction needed by the checker is valid: a flat source connection pulls
back to a flat chart connection under the exact chain rule.  Conversely, for
these two-variable charts, `TransportChartVerify` checks that the rational
Jacobian determinant is not identically zero, so generic equivalence also
holds.  Checking the source curvature is therefore a sensible and in fact
stronger implementation choice.

The probability calculation must, however, bound the composed source-curvature
numerator when points are first sampled in chart variables and then mapped to
source variables.  The present aggregate degree bound does not do this.

## Recommended fix order

1. Always `Together` before letter extraction; reject nonzero `B` when the
   alphabet is empty.
2. Require full dlog rank or resample the prime.
3. Split dlog fitting from fresh validation.
4. CRT-combine residue solutions across distinct primes; require successful,
   sticky all-prime verification.
5. Replace the aggregate degree formula with per-identity rational-degree
   propagation, including mapped source flatness.
6. Report separate ordinary-identity, dlog-validation, and bad-characteristic
   error terms; do not call the result exact while the total bound is nonzero.
7. Add reproducibility and arithmetic-safety guards.

For the real 15-letter families, steps 2--4 need not destroy the speedup:
eight training plus four validation points is the same current 12-point budget
when the generic prefix already has full rank.  CRT over three 24-bit primes
provides a roughly 72-bit modulus instead of the current single-prime
reconstruction window.

## Test results

Repository regression:

```text
Tests/t_family_certificate_modular.wls: 8 OK, 0 FAIL
CF231 full modular certificate: about 10 s, ExactEpsilonForm
```

Adversarial external suite:

```text
family_certificate_adversarial_stress.wls:
12 expected observations OK, 0 unexpected outcomes
```

It includes positive zero/normalized controls and reproducers for the empty
alphabet, raw-sum letter loss, rank collision, duplicate primes,
bad-characteristic alias, missing/wrong/non-sticky residues, and source-flat
degree underestimate.

Real-family external suite, second independent run:

```text
CF265 full: 17.30 s, ExactEpsilonForm, 15/15 rank at all 3 distinct primes
CF305 full: 17.74 s, ExactEpsilonForm, 15/15 rank at all 3 distinct primes
CF305 dlog-only baseline: 13.49 s, accepted
CF305 Bx + eps I: 13.04 s, rejected solely by DLog
10 expected real-family checks OK, 0 unexpected outcomes
```

The first real-family run gave the same verdicts at different random primes
(17.04 s and 17.44 s for CF265/CF305).  Both runs exposed missing residue
reconstruction/verification for both large families.

## Artifacts

- `External/CodexExchange/codex_final_checker_stress_2026-08-22/family_certificate_adversarial_stress.wls`
- `External/CodexExchange/codex_final_checker_stress_2026-08-22/family_certificate_real_stress.wls`
- this assessment

Run with:

```bash
wolframscript -file External/CodexExchange/codex_final_checker_stress_2026-08-22/family_certificate_adversarial_stress.wls
wolframscript -file External/CodexExchange/codex_final_checker_stress_2026-08-22/family_certificate_real_stress.wls
```
