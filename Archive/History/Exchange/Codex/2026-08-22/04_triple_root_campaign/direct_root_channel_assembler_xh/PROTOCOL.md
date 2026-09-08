# Direct root-channel sample assembly protocol

This directory is an external-only prototype. It does not alter the Fable
package, the triple-root prototypes, the native FLINT adapter, or any physical
preparation artifact.

## Algebra and ordering

Write the multiquadratic basis as `r_g`, where `g` is a bit mask and
`r_a r_b = Delta_(a & b) r_(a xor b)`.  For the gauge basis function
`phi_(g,m) = x^mx y^my / Q`, the coefficient in target grade `t`, direction
`mu`, and matrix entry `(i,j)` for gauge column `(a,b,g,m)` is

```
delta(a,i) delta(b,j) D_mu phi_(g,m)
- eps delta(b,j) Delta_((t xor g) & g) E[mu,i,a,t xor g] phi_(g,m)
+ eps delta(a,i) Delta_((t xor g) & g) phi_(g,m) C[mu,b,j,t xor g].
```

The residue column `(letter,a,b)` contributes only when `(a,b)=(i,j)`, with
coefficient `eps oneForm[letter,mu,t]`.  The right-hand side is
`Bbar[mu,i,j,t]`.

Gauge columns are ordered by `(upper, lower, grade, supportIndex)`. Residue
columns follow and are ordered by `(letter, upper, lower)`. Point rows are
ordered by `(targetGrade, direction, upper, lower)`. These formulas reproduce
the existing `CrossPrimeEliminationPlanV1` column convention.

For split points, the grade-to-branch transform is

```
S[s,t] = chi_s(t) product(root_i, bit_i(t)=1).
```

It is invertible when all root squares are nonzero. Applying it independently
to every `(direction,upper,lower)` row maps the direct rows to the legacy
`TRSplitPointRows` ordering. A branch-flip mask selects row `s xor flipMask`.

## Sparse polynomial ABI and caches

Compilation happens once. Every rational channel is stored as numerator and
denominator sparse bivariate monomials; each monomial owns an exact coefficient
vector in epsilon (ragged to that monomial's actual degree and capped at 256).
The prototype scope is ranks 0 through 3. For a prime, exact rational
coefficients are reduced once.
For an epsilon image, coefficient vectors are Horner-collapsed once. A point
then needs only modular powers at the exponents actually present (gapped or
very large exponents do not allocate a dense range), sparse monomial dot
products, and dense
numeric row construction. No symbolic substitution, `Together`, or root
branch expansion occurs in the per-point assembler.

Prime forms are cached by `(assembly fingerprint, prototype hash, prime)` and
epsilon forms by `(assembly fingerprint, prime, epsilon image)`. The caches are
bounded and can be cleared explicitly. Direct grade assembly only requires
nonzero root squares; square roots and quadratic-residue points are needed only
for the differential transform to legacy sign rows.

Every preparation binds its source ABI fingerprint, root ordering, exact and
compiled form fingerprints, prototype source path, and prototype SHA-256.
Public assembly boundaries rehash the prototype, and samples rehash again at
completion.

The caller must certify that the declared root squares generate the intended
square-class rank; pairwise duplicate root squares are rejected locally. The
physical CF300 driver additionally requires the prepared artifact's
`LocalSquareClassCertificate` to be independent and of rank 2 before compiling
or sampling.

Production direct-grade points require only nonzero rational denominators and
nonzero root squares. They do not require square roots or quadratic residues.
Under independent square classes, this removes the expected `2^r` rejection
factor of split-sign sampling: about 4x fewer attempts at rank 2 and 8x at rank
3. Split-sign rows are retained as a held-out differential/certificate
transform on residue points, not as the production assembly basis.

## Managed tests

`run_direct_root_channel_adversarial_oracle.wls` is the bounded synthetic
oracle. It covers ranks 0 through 3, all eight rank-3 grades, two primes, two
epsilon values, branch flips, exact transformed-row comparison to the legacy
assembler, sign-transform invertibility, A0/AS/AL/ASL nested column
projections, cache stability, rejected pole/zero-root images, perturbation
detection, and native verified ranks of `A`, consistent `[A|b]`, and an
inconsistent `[A|b]`.

`run_cf300_sector12_a0_direct_comparison.wls` reads and fully validates the
current prepared CF300 sector-12 A0 artifact. It assembles the exact legacy
`672 x 624` image at `p=10007`, `eps=1/21`, reuses its 21 accepted points for
the direct assembler, transforms the direct rows to sign rows, compares the
full matrix and right-hand side exactly, performs an independent first-point
differential, and records compilation, assembly, transformation, and legacy
timings.

Neither driver has been launched by the authoring agent. Runtime success and
performance claims must be based on managed-pool artifacts, not static review.
