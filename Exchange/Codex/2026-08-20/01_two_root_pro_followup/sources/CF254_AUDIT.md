# CF254 (9,7) finite-field affine-PDE audit

Audit date: 2026-08-19

## Scope and method

The audited calculation is the chain

1. `sample_rank_by_points_cf254_9_7.wls`
2. `run_epsilon_samples_parallel_cf254_9_7.wls`
3. `interpolate_epsilon_cf254_9_7.wls`
4. `lift_and_check_cf254_9_7.wls`
5. `install_cf254_9_7_checkpoint.wls`

`PROJECT_GOAL.md` was read first. These scripts reconstruct an exact rational
gauge as a function of `x`, `y`, and `epsilon`; their finite-field values are
intermediate verification data, not the requested hard function and not a
substitute for its endpoint or distributional dependence.

No Wolfram process was launched. Static shell inspection returns neither an
analytic function nor fixed-point field values; it exposes the exact source
equations. Independent Python calculations used exact integer modular
arithmetic and return verification values only. No notebook, production input,
residue artifact, generated point sample, or checkpoint was edited by this
audit. The five interpolation artifacts changed externally during the audit,
at 23:04-23:05 local time; the tests below use that final snapshot.

## Affine PDE and index map

Let `G(x,y,epsilon)` be the `4 x 4` off-diagonal gauge and write the residue
forcing as

```text
F_mu = F_mu^(0) + Sum_r F_(mu,r) rho_r.
```

The residue construction and the exact check use

```text
partial_mu G - epsilon E_mu G + epsilon G C_mu = F_mu.
```

For `G_ij = Sum_(px,py) g_(ij,px,py) phi_(px,py)`, one sampled row is therefore

```text
Sum_(px,py) (partial_mu phi) g_(ij,px,py)
- epsilon Sum_a E_(mu,i,a) Sum_(px,py) phi g_(aj,px,py)
+ epsilon Sum_b Sum_(px,py) phi g_(ib,px,py) C_(mu,b,j)
- Sum_r F_(mu,r,i,j) rho_r
= F_mu^(0)[i,j].
```

This is exactly the sign convention in the row builder and in
`pfaffianResidual`. The matrix products have dimensions

```text
E_mu: 4 x 4,  G: 4 x 4,  C_mu: 4 x 4,  F_mu: 4 x 4.
```

The coefficient column is

```text
((((i-1) 4 + (j-1)) (nx+1) + px) (ny+1) + py) + 1.
```

The sampler and lifter use the same formula. With `(nx,ny) = (10,10)`, this
gives `4*4*11*11 = 1936` gauge coefficients. Adding 17 free residues gives
1953 unknowns. Each point contributes `2*4*4 = 32` equations, so 64 points
give a `2048 x 1953` matrix. The derivative basis implements the quotient rule
for `phi = x^px y^py/D`, including the second inverse factor in
`-phi (partial_mu D)/D`.

The denominator ansatz is

```text
D = Product_l l(x,y,epsilon)^(m_l-1),
```

where `m_l` is the largest power of a nonnumeric `x`- or `y`-dependent factor
in a denominator of `bbar`. Its measured bidegree is `(9,10)`. The parallel
driver requests the extra numerator bidegree `(1,0)`, hence `(10,10)`.

No indexing, sign, quotient-rule, or matrix-dimension defect was found.

## Definite defects corrected

### 1. Reduced interpolants were not checked on construction points

The old interpolator formed a homogeneous relation on the construction data,
cancelled the polynomial GCD of numerator and denominator, and checked only the
held-out data. Cancellation can remove a common factor at a construction
point and reveal a wrong value there. A concrete counterexample is construction
data equal to 1 except for value 2 at `z=a`, with held-out data equal to 1.
The relation `(z-a)/(z-a)` satisfies every homogeneous construction equation,
reduces to 1, and satisfies every held-out value, but is wrong at `z=a`.

The corrected code requires:

- a one-dimensional construction nullspace;
- a nonzero reduced denominator at every construction and held-out point;
- agreement at every construction and held-out point;
- at least `2 (deg P + deg Q) + 1` total points, which makes the minimal
  total-degree rational function unique;
- a stored certificate for construction nullity, validated point count, and
  required uniqueness point count.

### 2. Affine normalization was certified only at one epsilon

For a particular solution `p` and nullspace rows `N`, the chosen residue
columns `C` impose

```text
p_C + Transpose[N[[All,C]]] alpha = 0.
```

The old code proved that `N[[All,C]]` had rank 16 only for the reference
sample, then used the same columns at every epsilon without checking rank.
It also silently discarded duplicate finite-field epsilon images even if their
canonical vectors differed.

The corrected code checks that each normalization block is `16 x 16` with
rank 16, rejects a failed canonical solve, and requires identical vectors in
every duplicate epsilon-image group before retaining one representative.

### 3. Uncertified sample artifacts could enter interpolation

The old selection required rank consistency and a particular solution but did
not require the sampler's two modular multiplication checks. It also trusted
the prime encoded in the filename. The corrected selection requires the
artifact prime, `ParticularCheckZero`, and `NullspaceCheckZero`, and checks a
common particular-vector length.

### 4. Empty or malformed sampling jobs could report success

For an empty epsilon range, `And @@ {}` yielded `True`, so the parallel batch
could record `AllConsistent -> True` with zero samples. The sampler itself also
accepted malformed direct overrides until a later finite-field operation
failed.

The corrected scripts validate the prime, epsilon range, the pole `k=-20`,
finite-field epsilon images, point count, kernel count, degree overrides, and
Boolean overrides. Batch summaries now retain both affine multiplication
checks and record `AllAffineChecksZero`.

### 5. The lifting stage did not require interpolation uniqueness metadata

The old lifter checked unresolved coordinates, denominator normalization, and
degree agreement, but not equal coordinate dimensions or an interpolation
uniqueness certificate. It now requires equal gauge/residue coordinate counts,
equal interpolation lengths, construction nullity one, all sampled values
checked, and the uniqueness point bound for every coordinate.

The old rational-lift check established modular back-images but did not state a
uniqueness bound. The corrected code requires every reconstructed coefficient
`n/d` to satisfy

```text
Abs[n] <= floor(sqrt((M-1)/2)),
d      <= floor(sqrt((M-1)/2)),
```

before modular back-substitution and the exact PDE residual calculation.

### 6. Checkpoint installation could combine mismatched certificates

The old installer trusted two independent Boolean fields. A stopped successful
run between writing the exact-check artifact and writing the candidate could
leave a new check beside an old candidate. It also identified the existing
`(9,8)` state only from `Dimensions[PrevD] == {4,2}`.

The corrected installer requires structural equality of the candidate and
check for the gauge, residue rules, primes, modulus, normalization, degrees,
rational-reconstruction bound, and source hashes. It recomputes SHA-256 hashes
of the strip record, residue data, modular interpolants, and current checkpoint.
It also requires sector 9, subsize 4, truncation 18, exactly one prior strip
solver `(9,8)`, both exact flags, and a prime list.

The existing `.before_9_7` backup has SHA-256
`30eea929cbc59225aaafa1f3d8614c633af79ebe2b44775833ea12b04d29faab`,
while the current checkpoint has
`69218acda31fe860117f5a1b57d7121efa8490345ff64e3869010dd4b3338b7f`.
The old installer would retain that stale rollback file. The corrected
installer rejects an existing backup unless its SHA-256 equals the current
pre-install checkpoint; it creates the backup only when none exists.

## Measured results from saved artifacts

The acceptance criterion for each point sample was

```text
Dimensions = {2048,1953}, rank = augmented rank = 1937,
nullity = 16, ParticularCheckZero = True,
NullspaceCheckZero = True.
```

The result satisfied this criterion for all 161 saved affine samples:

| prime | samples | matrix census |
|---:|---:|:---|
| 1000003 | 33 | all `{2048,1953}`, rank `1937`, nullity `16` |
| 2147483563 | 32 | same |
| 2147483587 | 32 | same |
| 2147483629 | 32 | same |
| 2147483647 | 32 | same |

The normalization columns are `1937` through `1952`, namely 16 of the 17
residue coordinates. An independent solve of every `16 x 16` normalization
block found zero singular blocks and zero nonzero normalized coordinates.

For every prime, all 1953 epsilon interpolants are monic in their denominator,
agree on all 24 construction samples and all 8 held-out samples (9 for prime
1000003), and have no denominator zero at a sampled epsilon. The degree census
is identical across primes:

| `(deg P,deg Q)` | coordinates |
|:---:|---:|
| `(3,3)` | 1284 |
| zero `(-Infinity,0)` | 592 |
| `(2,2)` | 60 |
| `(1,1)` | 16 |
| `(0,1)` | 1 |

Every nonzero construction relation has nullity one. The largest total degree
is 6, so the largest uniqueness requirement is 13 points; every artifact has
at least 32 distinct epsilon images.

The five primes are distinct and pairwise coprime. All 1953 degree vectors
agree. Independent CRT plus Wang reconstruction covered 11883 scalar
polynomial coefficients. Every rational coefficient maps back to every prime.
The combined modulus is

```text
21267710091513184983770675390052891325111609
```

and the uniqueness bound is `3260959221725502119113`. The largest measured
absolute numerator is `63721209361333273`; the largest denominator is
`578282385700651968000`. Four-prime reconstructions were not stable: omitting
the last prime agreed for 9961 of 11883 coefficients, while omitting the first
agreed for 11198. Thus the five-prime lift, not either four-prime subset, is the
candidate that must face the exact PDE identity.

No `CF254_9_7_lifted_exact_check.wl` or
`CF254_9_7_lifted_candidate.wl` existed at the final audit snapshot. The
acceptance criterion for the analytic lift is all 32 symbolic rational
residual numerators equal to zero. Its result was not measured because Wolfram
was not launched. The installer therefore was not run and the production
checkpoint retained its 2026-08-19 21:46:31 timestamp.

## Checkpoint composition

The production sector driver prepends each newly solved gauge row to `PrevD`.
The installer uses the algebraically identical operation

```text
MapThread[Join, {gauge, checkpoint["PrevD"]}].
```

For a certified `4 x 4` `(9,7)` gauge and the current `4 x 2` `(9,8)` block,
the result is `4 x 6`, with lower-sector order `(7,8)` in columns and solver
history order `(8,7)` in time. This agrees with the sector loop.

One provenance limitation remains. The production `CF254_9_7_input.wl`
contains the strip but no hash of the checkpoint from which `NextEquationD`
created it. The new hashes prove that the input and checkpoint do not change
between exact lifting and installation; they cannot prove that an already
stale input was originally derived from that checkpoint. A complete provenance
criterion requires the production strip-record generator to store the source
checkpoint SHA-256 in the input association and the installer to compare it.
That production generator was outside the permitted edit scope.

## Conceptual edit list

Every script edit made by this audit is listed here.

- `sample_rank_by_points_cf254_9_7.wls`: added early validation of the prime,
  epsilon image, point count, numerator-degree overrides, and Boolean options.
- `run_epsilon_samples_parallel_cf254_9_7.wls`: separated the requested kernel
  count from its cap; validated all batch inputs, the `k=-20` pole, and modular
  epsilon denominators; retained the two affine checks in summaries; added
  `AllAffineChecksZero`.
- `interpolate_epsilon_cf254_9_7.wls`: validated interpolation parameters;
  required matching prime and both sample checks; checked particular-vector
  lengths; checked every affine-normalization rank; rejected conflicting
  duplicate epsilon images; required construction nullity one; rechecked the
  reduced pair on construction and held-out points; enforced and recorded the
  uniqueness point bound.
- `lift_and_check_cf254_9_7.wls`: recorded SHA-256 source hashes; checked common
  coordinate dimensions; required every interpolation certificate; enforced
  the coefficientwise rational-reconstruction uniqueness bound; carried both
  hash and bound data into failure, check, and candidate artifacts.
- `install_cf254_9_7_checkpoint.wls`: checked artifact existence, association
  keys, exact flags, rational bounds, and candidate/check identity; recomputed
  source hashes; required the complete current `(9,8)` metadata before
  prepending the gauge; rejected a stale pre-existing rollback backup.
- `AUDIT.md`: added this audit record.

All five Wolfram Language sources have balanced strings, comments, ordinary
brackets, and association delimiters under an independent static scanner.
Kernel evaluation of the patched sampler, batch driver, lifter, and installer
was not performed under the explicit no-Wolfram constraint.

## Final exact result and independent provenance replay

After the audit snapshot, the five-prime lift was completed and checked in a
fresh Wolfram evaluation.  The acceptance criterion was that every entry of
both Pfaffian equations vanish as an exact rational function of
`{eps,x,y}`.  All 32 residual numerators are exactly zero.  The saved result is
`CF254_9_7_lifted_exact_check.wl`, with
`"AllResidualsZero" -> True` and an empty list of nonzero numerators.  The
parallel symbolic check took 70.565362 seconds.

The missing checkpoint provenance was then checked independently rather than
inferred from timestamps.  Starting from the preserved certified `(9,8)`
checkpoint, the family driver repeated `NextEquationD` and regenerated the
complete `(9,7)` strip input.  The original and regenerated files have the
identical SHA-256 digest

```text
fb20b26fd0b4a21bf7b79fe5e1ab4c31ef691d1a166571b500c4e57b13ff461f
```

Thus the exact gauge is tied to the certified predecessor strip.  It was
installed into the sector-9 checkpoint, enlarging `PrevD` from `4 x 2` to
`4 x 6`.  The checkpoint now contains the exactly checked `(9,8)` and `(9,7)`
transformations.
