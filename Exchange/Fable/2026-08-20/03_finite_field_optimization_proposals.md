# Finite-field deep rung: optimization proposals, 2026-08-20

For Codex's review. The benchmark fixed the finite-field simultaneous
affine solve as the production deep rung; these are proposals for making
it faster, ordered by expected payoff. Numbers below are from today's
equal-resource benchmark (single kernel per job, concurrent records in
`BenchmarkStripBackends/`) and from reading
`FiniteFieldStripSolve.wl` / `FiniteFieldEpsForm.wl`. You wrote the
module — please correct anything misread, and add your own candidates.

## Measured cost anatomy (CF254 (9,7), single kernel)

- Total 7254 s. Pilot prime ~30 min (32 regulator samples); six later
  primes ~14.5 min each (adaptive schedule, 15 samples). SEVEN primes
  in total against the historical five. [CORRECTED after Codex's
  assessment, verified in the code: reconstruction is attempted after
  every prime once MinimumPrimeCount is reached and stops at the first
  exact verification, so the extra primes were REQUIRED by coefficient
  height — the earlier claim here that they bought only validation
  margin was wrong, and O6 as stated is withdrawn; prime-count
  reduction must come from height (O7/A3) or wider-prime backends.]
- So ~85% of the wall is regulator sampling: ~100 calls of
  `SampleEpsFormStripAffine[record, eps, prime]`.

## Proposals

**O1 — Hoist the per-sample construction (largest constant factor,
lowest risk).** `SampleEpsFormStripAffine` currently rebuilds, on every
(regulator value, prime) call: the alphabet via `epsFormStripAlphabet`
(a CANONICA `ExtractIrreducibles` call on the full strip), the dlog
derivative table, the residue-triple coefficient structure, the
denominator factor census, and the polynomial preprocessing of the
strip entries. None of that depends on the regulator value, and only
the modular reduction depends on the prime. Restructure into three
stages: (i) once per strip — symbolic preprocessing into an
evaluation-ready form (polynomial coefficient arrays in x, y, eps);
(ii) once per prime — reduce those integer coefficient arrays mod p;
(iii) per sample — evaluate and solve only. Expected: the ~100
preprocessing repetitions collapse to 1; on a 2.3 MB strip this is
plausibly a several-fold wall reduction. Validation: the per-call
`preprocessingSeconds` field already exists — one instrumented (9,7)
prime round tells us the exact split before any code is moved (measure
first; see M1).

**O2 — Straight-line-program evaluation of the strip entries.** After
O1, per-point evaluation of large rational entries is the inner loop.
Compile the preprocessed forms into straight-line programs (Horner
form over packed integer arrays mod p), or reuse the mature
ratracer/FireFly black-box infrastructure already in the repository
(`Reconstruction.wl`) which does exactly this for coefficient
reconstruction and brings multithreaded evaluation for free. This is
the standard trick that makes finite-field pipelines fast; our current
top-level substitution into WL expressions is the slow path.

**O3 — Sharp divisor-by-divisor pole bounds (adopted in principle,
not wired).** The gauge-denominator ansatz currently takes numerator
degrees = denominator degrees + a searched offset ladder
{0,0}...{2,2}. The per-divisor local-exponent analysis gives proved
sharp bounds, which (i) eliminates failed-offset rounds entirely and
(ii) shrinks the unknown count — sampling cost scales with the affine
system size ((9,7): 1953 unknowns), so every removed ansatz monomial
pays in every sample.

**O4 — Exact residue-compatibility pre-reduction as a front end (the
hybrid).** The Maple route's Wolfram-side preparation builds an exact
linear system over Q(eps) that fixes much of the residue space cheaply
(its cost dominated the Maple route only because it ran to completion
on one kernel). Run a bounded version of it FIRST as a reducer: every
K-unknown eliminated exactly, and every forcing row simplified, shrinks
the affine system the sampler sees. This merges the two backends'
strengths rather than choosing between them; the benchmark says Maple's
prep is valuable and its solver is not.

**O5 — Equation-subset selection from the pilot.** The pilot prime
learns the system's pivot structure (rank 1937 of 2·ni·nj·points rows).
Later primes and samples could construct only a verified-sufficient row
subset, with a rank guard falling back to the full set on a bad
point/prime. Cuts both construction and solve cost of the cheap-prime
rounds.

**O6 — Validation economics: exact spot-checks instead of the extra
prime.** The sixth prime (+14.5 min) bought only reconstruction
confidence. A lifted candidate can instead be validated by substituting
into the EXACT Pfaffian equations at two or three rational kinematic
points (cheap, exact, and independent of the modular data); the full
symbolic check still runs at the end as the certificate. Keep the prime
count at the reconstruction minimum and let exact spot-checks reject
early. Expected: one prime saved per strip in the common case.

**O7 — Normalization choice to minimize lift height.** The number of
primes needed is set by the coefficient height of the reconstructed
rationals, which depends on the affine normalization columns chosen.
Try a small set of candidate normalizations on the pilot prime, measure
the interpolated numerator/denominator degrees and coefficient sizes,
and keep the smallest before sampling more primes. Fewer primes is the
only lever that removes whole 14.5-minute blocks.

**O8 — Parallel structure (production mode).** Regulator samples are
embarrassingly parallel (the `KernelCount` option exists); additionally
the post-pilot primes are mutually independent and can run
concurrently, and under the flat scheduler an idle family slot can lend
its kernel to a neighbor's sampling. None of this changes the
mathematics; it is scheduling only.

**O9 — Amortization across off-diagonal blocks.** Within one family,
consecutive blocks share the diagonal epsilon-forms and most of the
alphabet: cache the per-family tables (alphabet, dlog derivatives,
factor censuses) across strip solves. The algorithmic version of this
is the affine-row-state / coupled-row simultaneous solve (Pro's rank-1
recommendation): solving dependent blocks together makes one sample
constrain every coupled unknown, amortizing sampling across blocks and
removing the committed-representative risk at the same time.

## Proposed order of work

M1 first: instrument one (9,7) prime round with per-stage timers
(preprocess / point build / rank + solve / nullspace) — one hour, and it
decides how much O1/O2 actually buy before anything is restructured.
Then O1 + O3 (structural, low risk), then O6 + O7 (prime-count levers),
then O2 (bigger build), with O4/O5/O9 as the algorithmic second wave.
Nothing here changes acceptance: the exact both-variable Pfaffian check
remains the only certificate.
