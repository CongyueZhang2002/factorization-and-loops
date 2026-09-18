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


## Further exact reduction and Pro21

Actual Pro21 inspected pushed939a416d and confirmed the scalar normalization and
finite-DE dependency repair. It identified a cut-frame guard, removable scale-one
singularities, lower-pole retention and provenance-through-reuse gaps. These are
repaired.10 scalar/frame assertions pass16.273s;14 seed/scale assertions pass18.580s;
24 library assertions with provenance pass14.827s. The exact-source contraction
records are retained with the inclusive rate. The complete review is saved.

IdenticalQuarks inclusive refinement:15 evaluated candidate geometries,368 initial
seeds, then665 seeds. The exact final source reduction took100.532s, including
startup, and coefficient contraction/routing leaves3 physical scalar demands.
Permanent card inclusive-rate passed21.279s. This is an inclusive rate, not the
measured angular distribution. Gluons inclusive refinement is ongoing.

The next measured derivative attempt reached scale normalization, then its writer
again exhausted memory. The supervisor stopped it after2036.548s. The new writer
collects parameter symbols per distinct coefficient, bounds coefficient text
cache size and releases obsolete residual rows.20 actual native/reuse assertions
pass11.872s. This second failure is retained as failed time, not useful production.

An inspection of the initial measured IdenticalQuarks source found4424 provisional
integrals,2638 after exact routing (203.069s). The current approach therefore
establishes a unit-cut spanning basis before differentiating.946 candidates reduce
to381 affine classes; the first search has123571 equations, versus938184 in the
failed derivative attempt. Sufficiency still requires exact final target identities.
No physical master values are assigned from a sampled rank.

The general measurement-aware Taylor module has six passing assertions3.716s,
including a chain-rule derivative contact, overlapping logarithmic faces and an
independent convergent-integral comparison. It retains all regulator denominators.
These formal identities do not yet prove the original RR chart cover or weighted
L1 continuation. Pro21 explains the needed fixed-z subtraction for nonconstant
face maps and positive endpoint-weight suppression for constant endpoint maps.


## Inclusive completion and smaller measured basis search

All three inclusive RR card stages now finish with explicit scalar coefficients,
full implied lower-pole ranges and source provenance. Latest measured wall times:
Gluons711.418s, DifferentQuarks21.697s and IdenticalQuarks23.417s. The latter two
reuse completed native reductions and refresh source/provenance coverage. Gluons
contracts to6 physical scalar demands; each quark component to3. These are not
minimal master counts.

The generated inclusive sum of RR, RV, Virtual and UV cancels every negative
epsilon coefficient exactly (the raw lower bound is-4). No measured hard
coefficient was consulted. The audit took21.526s and is stored in
DoubleReal/Work/GeneratedInclusivePoleAudit.wl with its exact input coefficients.
This does not prove angular/endpoint cancellation or complete NLO EEC.

The ordinary-vector measured search hit a point-dependent export-closure issue
after282.902s. Missing exported columns are now retained as conservative formal
remainders when used for seed selection; a nonzero remainder rank then need not
be the true quotient rank. The final exact closure remains mandatory. That
restarted search grew to1531198 rows and is retained while an improved job runs.

Actual Pro22 confirmed the search's exact acceptance and the measured Taylor
algebra. It recommended sector-local numerators, trying remaining predecessor
shells before a stall, and cut-compatible polynomial momentum vectors. All are
implemented. Required scalar provenance is also enforced on cold provider results.

The new vector constructor solves a bounded polynomial nullspace in independent
full-D scalar products and verifies individual off-shell cut tangencies. It
includes coefficient derivatives in the divergence and inserts certified cut
cofactors at unchanged cut power. Five assertions pass18.012s, including an
independent comparison to ordinary total derivatives of polynomial-shifted seeds.
An actual family yields24 particle-protecting vectors and12 all-cut-protecting
vectors in45.442s including loading and artifact I/O. The internal algebra alone
was subsecond, but those internal clocks are diagnostic only.

The mixed-vector Dirichlet test needs29 rows in one search rather than114 over
three;4 assertions pass24.280s. In the actual measured IdenticalQuarks search,
1799 candidates reduce to610 exact affine classes.206491 rows leave77 formal
remainder columns;273281 leave3;275494 are currently being sampled. No exact
basis or physical-master completion is claimed from those counts.

A separate bottleneck was repeated readable serialization of large solver
definitions: one sampled input occupied90MB. Large exact solver snapshots now
use binary records and matching definitions are not rewritten. Four snapshot
checks pass17.474s;20 actual native/reuse checks pass37.134s. The active older
job retains its loaded code, while the improved job uses compact snapshots.
Physical result files remain readable. Hidden-pole rate2 assertions pass16.574s;
cold/warm provenance25 assertions pass19.676s.


## Exact rational cancellation and controlled DE construction

The mixed cut-compatible basis search used275494 equations for4234 identical-quark
source targets. A377.559s exact solve appeared to leave248 nonpreferred columns.
A coefficient-level audit proved every one had an identically zero rational
coefficient; raw transitive substitution had counted syntactically present GLIs.
The shared reduction closure now collects coefficients and cancels them exactly
before declaring terminal integrals. Three regressions pass17.925s. The actual
saved solve canonicalizes to43 unit-cut integrals, no unmatched columns, in51.746s.
This is an exact spanning set, not a master-minimality claim. Saved output:
IdenticalQuarks/Work/UnitCutTangentBasisExactCanonical.wl.
The old ordinary-vector search was stopped as superseded; its owner record
OrdinaryBasisSuperseded.json retains the reason and replacement artifact.

Actual Pro23 reviewed pushed66be3cfe and confirmed the vector mathematics. Its
operator-aware predecessor and bounded derivative-promotion recommendations are
implemented: searches use the actual selected operators, particle/all-cut
protection is explicit, and unresolved derivative symbols cannot automatically
become the next differentiated basis. The original source map is preserved;
derivative solves seed only the current basis and derivative targets.
A quadratic angular measurement independently checks the exact DE, and a
one-seed bound fails without promoting its frontier:5 assertions,5.768s.
The existing residual/native-reuse test also passes20 assertions.

The permanent measured-card path now constructs an exact unit-cut source span
before DE generation and retains it as Work/UnitCutReduction.wl. The reduce stage
is separately callable. Matching saved source definitions can be resumed; the
verified identical-quark solve is adopted only after checking identical typed
families and original target inventory. No physical constant was supplied by hand.
All stated times are Python monotonic elapsed times including startup; none is
a complete cold NLO EEC timing. The measured RR endpoints and full EEC remain open.
