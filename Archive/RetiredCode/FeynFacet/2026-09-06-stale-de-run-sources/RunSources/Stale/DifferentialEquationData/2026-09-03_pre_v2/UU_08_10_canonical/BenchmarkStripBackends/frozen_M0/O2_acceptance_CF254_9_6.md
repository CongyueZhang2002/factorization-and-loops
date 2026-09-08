# O2 acceptance — vectorized build (O2a) + per-prime preprocessing hoist (O2b)

CF254 (9,6), production allocation (1 kernel; 2-core affinity, CPU/wall
measured ~1.1), fresh artifacts, 2026-08-21 00:34–00:47. Exact gauge and
residues identical to the M0 oracle at every step; 7 primes, 122
samples throughout.

| run | wall | Setup | Preprocess | Build | Eliminations | per sample |
|---|---:|---:|---:|---:|---:|---:|
| M0 census | 1399.5 s | 462.4 | 120.4 | 425.9 | 305.4 | 10.8 s |
| O1 (setup hoist) | 1035.5 s | 58.5 | 131.6 | 398.6 | 312.0 | 8.5 s |
| O1+M1 (constrained solve) | 755.9 s | 0 | 126.8 | 446.1 | 83.4 | 5.5 s |
| +O2a (packed monomial tables, vectorized rows) | 443.6 s | 0 | ~130 | ~70 | ~83 | 3.5 s |
| +O2b (symbolic forms once per block, reduced once per prime) | **249.7 s** | 0 | 2.9 | 68.8 | 84.6 | 1.3 s |

Cumulative 5.6x on the small-block fixture. What remains in 249.7 s:
~160 s of sampling (build 69 + solve 85 + overhead) and ~90 s of
interpolation, CRT lift, and the exact both-variable check. Next levers:
A2 incremental sampling (122 -> ~65-75 samples), then the lift/exact
check, then the solve via A3 ansatz reduction or a machine-word backend.

O2a: polynomials as packed {coefficients, x-exponents, y-exponents},
evaluated from per-point monomial power tables with every intermediate
< 2^62 and reduced mod p before summing; rows assembled per gauge block
as packed vectors. O2b: each rational entry as numerator/denominator
polynomials in {x, y, eps} with exact rational coefficients in the
block preparation; `finiteFieldStripPrimeForms` reduces them once per
prime (memoized by fingerprint and prime); a sample collapses the eps
dependence by one small matrix·vector product. The former per-sample
path remains as the fallback when a preparation lacks symbolic forms.
Tests: t_finite_field_{constrained_solve,strip_solve,eps_form,
preparation,adaptive_sampling} green; the strip_solve test compares
against stored pre-O2 sample data (old-vs-new builder equivalence).
