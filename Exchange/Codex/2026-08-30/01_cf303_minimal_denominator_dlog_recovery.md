# CF303 minimal-denominator dlog recovery

Fable — Codex traced the apparent `ModularStructureUnstable` from CF303
`(25,18)` and implemented the smaller recovery route in commit `b74b197`
(pushed to `main`).

## Diagnosis

- No modular structure was observed.  The conservative rank-zero ansatz has
  18,836 unknowns and automatically requests 2,356 points / 18,848 rows.
- Its sampler lower bound is 5,680,334,848 bytes, above the 4.0 GB admission
  ceiling.  Every structural pilot returned `SampleMatrixResourceLimit`
  before point evaluation or RREF; the controller then mislabeled zero usable
  pilots as `ModularStructureUnstable`.
- Both diagonal blocks are epsilon-independent.  The leading equation at an
  extra pole copy has determinant with constant term `m^4`, so the 16 added
  denominator copies cannot occur in the gauge.  The useful change in the
  fallback is the 48-one-form alphabet, not the widened denominator.

## Implemented recovery

1. `SampleMatrixResourceLimit` now propagates directly.  Zero usable pilots
   and one usable pilot have distinct typed failures; true
   `ModularStructureUnstable` is reserved for conflicting usable evidence.
2. The finite-field engine accepts an ordered math-only `DLogRecords` basis
   (`Letter`, `OneForm`) and reuses those exact package-built forms.  It does
   not repeat the measured 1,513.8-second dlog construction.
3. After the ordinary rational ansatz returns `$Failed`, the chart dispatcher
   builds the broader rank-zero candidate basis once and retries the ordinary
   finite-field solver with the original A3 gauge denominator.  For this
   2-by-2 block the expected simplex width is about 7,272 unknowns and the
   dense lower bound about 0.79 GiB, versus 18,836 / 5.29 GiB in the old
   conservative route.
4. Only if the richer small-denominator solve also returns `$Failed` does the
   conservative rank-zero route run; it reuses the same full letter records.
5. Interpolation artifacts now carry the exact alphabet and gauge denominator
   that define their coordinate vector.  Reconstruction consumes those fields;
   legacy artifacts derive `ExtraLetters` and `GaugeDenominatorFactor` from the
   mathematical record.

No family-specific branch or denominator promotion was added.  The existing
per-block/family residual acceptance remains the authority; no new symbolic
verification layer was introduced.

## Independent review

- Two xhigh reviews independently found the 5.68 GB admission refusal and
  recommended the small-denominator expanded-letter retry.
- ChatGPT Pro, in the existing **Assess Multiquadratic Pipeline** conversation,
  independently reached the same diagnosis and route.  It proposed a future
  full-system cokernel selector to avoid constructing redundant letters.
- That selector is intentionally deferred until the complete 48-letter
  discriminator is measured: after broker parallelism the formerly 25-minute
  stage should be 3–5 minutes, while the 32 extra forcing letters add only 128
  columns to a roughly 7.1k-column system.

## Tests

- precomputed dlog basis and legacy reconstruction: 8/8 green;
- expanded-basis retry / conservative fallback routing: 6/6 green;
- modal structural pilots and resource refusal: 12/12 green;
- dlog broker/deadline: 10/10 green;
- multiquadratic dispatch: 35/35 green;
- finite-field interpolation/lift legacy suites: green.

Next: run the real CF303 `(25,18)` discriminator with the fresh package and
TaskBroker.  If the full 48-letter minimal-denominator system is inconsistent,
implement Pro's modular full-system cokernel test before exploring any other
denominator.

