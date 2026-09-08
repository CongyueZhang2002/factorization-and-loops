# To Fable — canonical pullback and post-prime optimization result

Date: 2026-08-29 (PDT)

## Outcome

Commit `2c8efec` is pushed on `main`.  It implements the user's rule that a
production gauge is canonical or the block fails: `CompactCompositionFallback`
is gone and no nonzero raw composition can be banked.

The reconstruction ladder is now:

1. one one-second canonical `Together` attempt for genuinely easy compact
   gauges;
2. the reduced whole-matrix common-denominator finite-field model;
3. on deterministic model refusal, independent reduced models per algebraic
   matrix entry;
4. within an entry, denominator widening from the maximum quotient-grade
   degree toward the product ceiling, with the numerator rectangle recomputed
   for every candidate;
5. kinematic caps `{12,18,24}` by default, then a typed block refusal.

The denominator search is best-first and bounded to 64 models by default, so
rank-three product ceilings cannot create an unbounded rectangular search.
Tests cover incompatible denominators between matrix entries, incompatible
denominators between quotient grades of one entry, and cap widening.

The first prime now uses two cheap source points to infer the epsilon-fibre
budget.  Full kinematic grids use the inferred requirement plus held-outs and
two safety fibres; later primes use the accepted degree profile directly.  If
the two probe points accidentally cancel a leading epsilon coefficient, the
retained full schedule is widened and the same model is retried.  The planted
double-cancellation test passes.  Typical hard-block work falls from 52 fibres
to about 18–20.

## Physical optimization decisions

- Exact CF259 sector-21 row propagation on the saved 47-master state now takes
  **3.92 s total**: A 0.73 s, S 0.001 s, S-inverse 0.21 s.  The first patch,
  which only removed final `Together`, was still running after five minutes;
  the historical complete step was about 21 minutes.  The successful path
  retains the exact block formulas and leaves the existing production family
  certificate as the acceptance test.  Production now actually selects this
  route even when legacy checkpoints lack optional saved dlog rows.

- Point brokering was measured rather than assumed.  On 400 rank-three points
  with 20 epsilon fibres, serial evaluation took 16.65 s and seven helpers
  took 15.52 s: only **1.07x**.  The broker implementation was removed under
  the project's complexity threshold.

- Native batch evaluation remains deferred.  After the fibre reduction its
  prospective campaign-wide saving is too small to justify a new backend now.

## Validation and live state

Focused and surrounding suites are green: finite-field pullback, 38 row-gauge
assertions, mathematical resume, regulator resume/in-frame, solver deadlines,
transport-chart extension, 35 rank-three finite-field assertions, and the
genuine eight-grade installed-family chain including its final certificate.

CF300's checkpoint was backed up and truncated from blocks `(12,11..6)` to the
four canonical blocks `(12,11..8)`.  `(12,7)` and its dependent `(12,6)` will
therefore be recomputed.  A clean three-family Production campaign has been
launched from the existing mathematical checkpoints for CF259, CF300, and
CF303.

