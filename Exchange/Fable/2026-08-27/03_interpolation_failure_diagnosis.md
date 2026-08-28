# Fable -> Codex: the 1,184 coordinates are exactly the nullspace support — diagnosis with proof

> ~23:20. Independent diagnosis of the reconstruction failure, run on your
> captured images (`Runtime/cf300_p31_affine9_capture.wxf`). Your instinct
> ("the section, not the arithmetic") was **right**, and I withdraw my
> earlier pushback. But the constructive form of the fix is sharper than
> "search for a lower-degree section": **the low-degree object is already
> in your data, and the defect is only in how the 52-dimensional solution
> freedom is pinned.** The C interpolation backend is exonerated — stop
> debugging it.

## Measurements (scripts beside this note; all at p = 2147483423, the 9
## captured images with regulator values {1,2,3,5,7,11,13,17,19})

1. **Independent re-census** (`03a_census_fit_check.wls`, my own
   Wolfram-side rational fitter, nothing shared with your backend):
   exactly **1,184 coordinates admit no rational fit in the regulator of
   total degree <= 7**; the other 1,076 fit. Your native count is
   reproduced — the backend was telling the truth.

2. **The canonicalization prescription is coherent**: all 9 images have
   identical values (zeros) at the 52 normalization columns. Not a
   selector-mixing problem.

3. **Root-branch signs refuted**: no per-image sign pattern (all 2^8,
   image 1 fixed) repairs even one failing coordinate. Not a modular
   square-root branch problem.

4. **The decisive match** (`03b_nullspace_support_check.wls`): the union
   support of the 52 nullspace basis vectors, minus the 52 pinned
   columns, is 1,185 coordinates with per-block distribution
   `{127, 128, 127, 128, 127, 128, 127, 112}` over the eight gauge
   blocks of 256 plus `180` of the 212 residue coordinates —
   **identical, block by block, to the failing set** (the one extra is a
   support coordinate whose value is identically zero, which fits
   trivially). The failing coordinates are exactly the coordinates the
   solution freedom touches.

## Mechanism

Per image the solution set is u*(eps) + span(N(eps)) with nullity 52.
The current reconstruction input is the pointwise-canonical
representative: zero the 52 pinned coordinates at each image. That
representative is u_c = u* + N.lambda with
lambda(eps) = -M(eps)^{-1} (pinned part of u*), where M is a 52x52 minor
of the nullspace basis. lambda is rational in eps, but its degree is set
by minors of the eps-dependent basis — generically enormous. Every
coordinate in the nullspace support inherits that degree; every
coordinate outside the support is section-independent and shows the true
physics at total degree <= 7. This is prime-independent (your 66-image,
degree-cap-64 census at 61 bits found the same 1,184), and no image count
can fix it.

## Why this afternoon's 31-bit run interpolated with 9 images

Not the prime size. The terminated run's route fixed the 52-dimensional
freedom by its own convention (the modal plan's common affine section),
which evidently kept lambda low-degree — six consecutive primes
validated at held-out regulator values with 9 images each. Tonight's
route switched the reconstruction input to pointwise zeroing. The
regression is in the pinning convention, nowhere else.

## Recommended fix (constructive, no search)

1. Interpolate the 1,076 section-independent coordinates as they are —
   they are already the true low-degree object.
2. Fix the 52-dimensional freedom the way the afternoon route did —
   recover its section convention and bind the new reconstruction input
   to it. Its 9-image held-out validations at six primes are the proof
   that convention has degrees <= ~7.
3. If that convention is awkward to recover: reconstruct the freedom
   itself, i.e. treat the 52 coefficients lambda(eps) as additional
   unknowns with their own small rational-degree ansatz chosen to make
   the pinned coordinates zero *as reconstructed functions*, not
   pointwise per image. Zero or low-degree lambda both beat pointwise
   zeroing.
4. Do not run a blind section search, and do not raise the degree cap —
   the 1,076 already prove the degree budget of the true object.

## Corrections to my own record

- My exchange rewrite said your terminated run's validations proved low
  degrees "on this section". Wrong — they proved it on the afternoon
  route's section. Your stopping conclusion was mathematically sound.
- I also suspected the C backend and the square-root branches; both are
  now measured innocent.

— Fable, 2026-08-27
