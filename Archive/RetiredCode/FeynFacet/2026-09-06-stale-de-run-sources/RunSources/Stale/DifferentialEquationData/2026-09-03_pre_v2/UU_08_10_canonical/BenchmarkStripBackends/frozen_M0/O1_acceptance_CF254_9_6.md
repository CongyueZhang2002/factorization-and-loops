# O1 acceptance — setup hoist, CF254 (9,6), production allocation

Run 2026-08-20 23:09–23:27, 2 P-cores, KernelCount 1, fresh artifacts
(`o1_run/`), against the M0 census baseline (`census_run/`).

| | M0 baseline | O1 | 
|---|---:|---:|
| wall | 1399.5 s | **1035.5 s** (1.35x) |
| primes / samples | 7 / 122 | 7 / 122 |
| SetupSeconds total | 462.4 | 58.5 |
| PreprocessingSeconds | 120.4 | 131.6 |
| SamplingSeconds (build) | 425.9 | 398.6 |
| four eliminations | 305.4 | 312.0 |
| exact gauge / residues | — | IDENTICAL to baseline |
| exact Pfaffian check | True | True |

The remaining 58 s of setup was the per-sample fingerprint check
re-hashing the 1.5 MB strip (~0.5 s per call); the solver now passes
the fingerprint it computed once (`"ExpectedFingerprint"`), so the
per-sample setup cost is expected to fall to the lookups alone — an
estimated further ~55 s (unmeasured until the next self-instrumented
production run). Standalone callers keep the strong hash guard.

Implementation: `PrepareEpsFormStripSampling` / `finiteFieldStripPrepare`
(the former per-call setup code moved verbatim), `"Preparation"` +
`"ExpectedFingerprint"` options on `SampleEpsFormStripAffine`, one
preparation per `SolveEpsFormStripFiniteField` shared with the degree
probe and every sample. Tests: `t_finite_field_preparation` (exact
equivalence with/without preparation on the real (9,6) record, reuse
flag, stale fingerprint recomputed), plus the three existing
finite-field tests, all green.
