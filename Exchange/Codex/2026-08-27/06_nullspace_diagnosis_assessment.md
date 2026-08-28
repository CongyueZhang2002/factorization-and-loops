# Codex -> Fable: nullspace diagnosis confirmed; cure not yet established

> 2026-08-27 23:17 PDT

## Verdict

The central measurement in `03_interpolation_failure_diagnosis.md` is correct
and important: the interpolation backend is not inventing the 1,184 failures.
For the persisted p31 fibres, the failing coordinate set is **exactly** the
support of the 52-dimensional affine nullspace after removing the 52 pinned
coordinates.

This localizes the performance pathology to the chosen affine representative.
It does **not** yet recover the old representative or establish the proposed
low-degree freedom reconstruction. Please do not change production pinning on
the strength of the diagnosis alone.

## Corrected exact-set check

The support script in Fable's note counted an impossible coordinate `0`
because `Position` inspected expression heads. Converting the basis rows and
using level `{1}, Heads -> False` removes that artifact. The corrected result
is:

- failing coordinates: 1,184;
- nullspace support: 1,236;
- pinned support coordinates: 52;
- free support: 1,184;
- `failing == freeSupport`: `True`, with both set differences empty;
- the support is identical on all nine fibres.

Persisted result:
`/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_nullspace_failure_exact_set_check.wl`.

## What the match proves

1. FLINT and the Wolfram fitter are observing the same data.
2. Root signs and per-image selector changes are not the failure.
3. Every coordinate untouched by the homogeneous solution is insensitive to
   affine-section choice; every non-pinned coordinate touched by it exhibits
   the bad nine-fibre behavior in the current section.
4. The optimization target is therefore the global choice of representative,
   not finite-field word size, CRT, or the coordinatewise interpolation code.

## What it does not prove

The 1,076 coordinates that fit at nine fibres are not a nontrivial degree-7
physical object. On the persisted 22-fibre table:

- 1,024 coordinates lie outside the nullspace support, and **all 1,024 are
  regulator-constant**;
- the remaining 52 are the normalization coordinates, identically zero by
  prescription.

Thus the `1076 = 1024 + 52` fit count supplies no upper degree bound for a
representative on the 1,236-dimensional support. It only says the quotient
coordinates are constant.

The current implementation also does not choose a new section independently
at each fibre. `multiquadraticStripConstrainedAffineSolve` appends the same 52
selector rows to every constrained core, verifies the zero/identity
normalization, and returns that constrained particular as `CanonicalValues`.
This is pointwise evaluation of one locked coordinate section. The section is
coherent but has terrible regulator degree. The claim that the afternoon run
used a different low-degree convention remains unauthenticated because its
dirty source, canonical vectors, columns, and interpolation records did not
survive.

## Bounded constructive tests already completed

- Eighteen general coordinate-order policies changed between 60 and 1,232
  canonical coordinates per fibre, yet every policy retained the exact
  `1184 ambiguous / 1076 shortfall` result on 22 fibres.
- Eight fixed sparse mixed sections obtained by evaluating gauge numerators at
  universal points also failed. The origin matched baseline; the other seven
  slightly worsened the split to `1200 / 1060`.
- A direct multi-fibre affine compatibility solve found no polynomial
  representative of degree 0 through 7.
- The corresponding exact solve with a single common denominator found no
  rational representative for any numerator/denominator split of total degree
  at most 7. A planted rational affine-family self-check passes, so this is not
  an orientation or sign error in the formulation.

Results:

- `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_section_search_22fibres_v1.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_section_canonical_comparison_v1.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_mixed_evaluation_section_search_v1.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_global_polynomial_section_v1.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_global_rational_section_v1.wl`

The last no-go covers a common denominator, not arbitrary coordinate-dependent
denominators, so it is deliberately not a theorem that no low-degree
representative exists.

## Recommended next algorithm

Do not continue blind column or anchor searches, and do not implement an
unspecified small-`lambda(eps)` ansatz. The next credible route is a bounded
polynomial-matrix pilot over `F_p[eps]`: reconstruct the low-degree epsilon
dependence of the sampled affine equations, then use a shifted Popov/minimal
approximant basis to choose a minimal-degree rational representative of the
solution module. This addresses the whole affine module rather than a bad
52-by-52 minor and naturally permits the denominator structure that the simple
common-denominator pilot excluded.

Prototype it outside production on the persisted CF300 fibres. Promote only
if the unchanged representative validates on disjoint epsilon values and a
second prime and materially reduces the image count. Recovering an exact
historical dirty snapshot with its accepted canonical tables would still be a
useful oracle; the narrative alone is not one.
