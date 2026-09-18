# NLO EEC: physical scalar coefficients and first RR interior

The complete alpha_s^2 result is still unfinished. No published measured NLO
EEC hard coefficient has been opened or used. Accepted RV, Virtual and UV raw
results remain unchanged.

DifferentQuarks now has16 physical master records sufficient for every nonzero
source column of its18-coordinate DE. The other two have identically zero source
coefficients and remain unsolved. The explicit `Work/Interior.wl` starts at
epsilon^-1 and includes the finite GPL coefficient. It is not endpoint complete.

Actual6Pro review19 confirmed the independently derived universal complement-mass
periods, normalization, fixed-interior convergence and radial pole subtraction.
Its derivation is retained in
`External/ChatGPT/Records/2026-09-18/19_complement_mass_physical_periods.md`.
Review20 completed against pushed revision
`3e81ca9f7c774e356fc5b601147c84ae40805f44`, reviewing the coefficient code and a
general inclusive/endpoint route. No measured hard-function reference was requested.

The library's Gauss expansion now preserves all lower Laurent coefficients even
when only a higher order is requested. A regression includes a hidden lower pole.
MasslessPhaseSpaceVolume now evaluates at a literal zero regulator; formerly
that call remained unevaluated. Relative scalar checks had cancelled this wrapper
on both sides and therefore established shape only. New absolute checks use an
independent C0=1/(2048 Pi^5). Storage rejects unevaluated volume calls.

Actual supervised wall seconds, including startup:

| Stage/check | Seconds |
|---|---:|
| Complement scalar provider |23.123|
| Finite DE consequences and publication |26.494|
| GPL total derivative,5 assertions |0.852|
| Audited DE coefficients,7 assertions |14.211|
| Gauss/library lower coverage,3 assertions |13.325|
| Explicit phase volumes,11 assertions |14.641|
| Absolute scalar periods,9 assertions |19.876|
| Final interior assembly with library reuse |41.543|
|20 stored coefficients and fully numerical interior audit |17.975|
| Sparse residual IBP regression,20 assertions |35.104|

These are stage/reuse times, not a cold full-NLO total. Failed/superseded assembly
attempts40.026 and42.754 seconds remain separately recorded. No such attempt is
accepted as completed physics.

Pro20 found a same-pass dependency bug: a finite DE consequence could omit a
newly determined master when subtracting the known terms. The permanent repair
passes eight assertions (15.216s). Actual basis16 changed; basis14/17 did not.
The old value is quarantined, the corresponding shared library entry corrected,
and permanent card stages regenerated MasterValues.wl and Interior.wl.
The corrected result passes20 stored coefficient comparisons and numerical
derivative checks against original DE rows10,11,13 (residuals below4e-29).
The final audit took18.480s. Corrected masters/interior stages took38.384s/33.736s.
These supersede the earlier generated values, not the normalization derivation.

IdenticalQuarks initial import failed after992.693s; the structural sparse parser
repair retained the native reconstruction. The first derivative recovery later
exhausted memory (about46GiB plus swap); it was stopped after3833.674s, a failed
attempt. Structural scale normalization now proves homogeneity without expanding
or retaining every large rational coefficient;13 tests pass in20.324s. The active
restart reuses initial native results. Read STATUS.md and inspect actual processes.

Inclusive sources have now been generated for all three components:
DifferentQuarks27 targets/1family, IdenticalQuarks164/3, Gluons574/15.
Preparation took162.762s including startup. Exact initial inclusive reductions
took25.218s,27.416s,43.993s respectively and leave3,17,93 spanning integrals.
These are not claims of master minimality; cut-dot descendants still require
additional exact reduction for the last two components.

DifferentQuarks' inclusive scalar evaluation and rate contraction completed in
18.180s. Three required scalar geometries are evaluated: phase volume through
epsilon^3, R6 through epsilon^1, and a squared complementary mass through epsilon^0.
The latter two orders follow the actual reduction coefficient valuations.
The omitted-tail matrix audit passes; raw poles and automatically derived moment
weights are retained in InclusiveTreeRate.wl. This does not complete endpoints.

The generic inclusive scalar provider separately identifies its universal input:
Gehrmann-De Ridder, Gehrmann and Heinrich, hep-ph/0311276. Its R6/R8 Laurent
coefficients are scalar phase-space integrals, not EEC hard coefficients.
Derived phase-volume/complement formulas and independent convergent Euler
quadrature checks are retained. The initial six assertions passed in31.987s;
expanded geometry tests are recorded separately.

Remaining work is the other measured RR components, further inclusive reduction,
measurement-aware endpoint subtraction and its contact-order proof, then the
complete raw sum and pole cancellation. No full alpha_s^2 comparison has begun.
