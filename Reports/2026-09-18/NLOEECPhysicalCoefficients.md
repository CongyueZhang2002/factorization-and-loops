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


Pro24 inspectedc7cd6749 and confirmed the coefficient cancellation. Three further
repairs now compose source maps rather than union cyclic rewrite rules, retain all
candidate affine-equivalence equations for derivative searches, and select a new
bounded-search workspace when its exact definition changes. A representative-change
regression raises the closure test to4 assertions (2.866s); the5-assertion quadratic
DE test passes6.005s. The first card DE attempt stopped after588.876s because it
lacked the candidate cross-family equations. Its completed61904-row Sample001
checkpoint is retained; completed log/receipt moved to Archive/Runs/2026-09-18/
NLOEECChecks/ControlledDEAttempt1.*. A repaired permanent-card attempt is running.


The card physical-value stage now performs batch library lookup and preserves
insufficient-order donor coefficients. The library test has26 passing assertions,
18.474s. An identity-only read-only inventory of the current43 source coordinates
finds2 direct stored values; this is not an order-sufficiency or new-integral count.
Generic covered-sector maps and DE relations can provide additional reuse.

The predecessor selector now sums terms within each actual operator before its
nonzero-incidence test and avoids reconsidering accepted candidate seeds.15 seed/
scale assertions pass21.527s. The actual313-column derivative frontier selects
32133 additional seeds with this code; its saved inventory is
IdenticalQuarks/Work/ExactDerivativePredecessors.wxf. Five bounded-DE assertions
pass26.679s under the shared CPU allocation.

The common equation generator now builds each index substitution once per seed,
combines equal operator shifts before the seed loop, and caches repeated rational
coefficient factors with a4MiB bound. On128 real predecessor seeds from the largest
family, both generators return the same3842 exact equations:3.126s before versus
1.718s after, measured with Python monotonic timestamps around the calls. This
is a1.82x microbenchmark, not a full-production timing. Total supervised benchmark
including startup/input reads is30.080s; the independent polynomial-vector test
passes5 assertions in15.523s. Its launcher completion marker had a singular/plural
typo; the retained receipt explicitly records that reporting correction.

Pro25 recommends Jacobian-corrected inclusive moments as a bounded method for
remaining physical constants, with exact rank on unresolved DE modes, meromorphic
endpoint continuation and valuation-aware epsilon coverage. The complete advice
is retained; no moment-based physical constants have yet been claimed.


The bounded search now generates ordinary and compatible-vector equations in
small seed batches using the existing managed symbolic pool. Operators are built
on the caller; workers receive exact tables. At most256 seeds are in one job,
limiting transient worker memory. The card path allocates up to its Kira CPU budget
for generation; single-job searches remain serial. Two actual workers reproduce
the serial3842-equation set exactly (128 real seeds;26.618s including loading and
worker startup). The bounded quadratic-DE regression passes5 assertions15.473s.
This is an execution change, not a claim of an eightfold full-run speedup.

The preserved live derivative search has progressed to33977 seeds/1083829 rows,
reducing313 sampled remainder columns to1. Iteration3 adds121 seeds (1087863 rows).
It still requires exact rational acceptance and physical master integration.


### Exact-attempt recovery and inclusive moment constraints

The repaired identical-quark derivative search reached zero sampled remainder
columns at34,098 seeds/1,087,863 rows. Before launching the exact backend, the
kernel was OOM-killed after3116.165s. Native equations, identifiers and scale
normalization survived. The new permanent resume path directly consumes the
retained exact request; it does not repeat seed generation or sampling. The
unused full-equation fingerprint was removed from this typed path, retaining
exact workspace comparisons. Its position matches the final stopped operation;
this is a diagnosed suspect allocation, not an isolated memory benchmark.
The resumed process is recorded in STATUS.md and ControlledDEState.json.

Pro26 confirmed an explicit sufficient four-particle Gram-domination half-plane
and bounded selection of inclusive moment constraints. Pro27 inspected the
pushed moment code, confirmed its normalization/convergence argument and found
three input/metadata gaps. They are repaired using shared normalization-domain
checks, regulator agreement and context-preserving family identifiers. These
are generic operations. No measured literature hard coefficient was used.

Exploratory actual source moments:17 prepared,26 unsupported with the selected
chart;5 combinations have exact cancellation of all uncovered GLIs without new
IBPs,29.382s. They do not yet fix physical constants; inclusive values, continued
endpoint pairings and physical-constant rank remain required. Regenerate this
record after the Pro27 metadata repairs before consuming it.

Validation after repairs:11 moment assertions6.269s,18 endpoint-regularity
assertions2.966s,6 exact DE/replay assertions5.821s. Six moment-combination
assertions passed17.524s; the first attempt incorrectly demanded a particular
normalization of a null-space vector and was corrected to test its exact linear
relation. Scale-analysis caching:4096 real rows1.773s ->0.476s with identical
exact records; benchmark total19.924s and15 seed/scale assertions20.374s. All
quoted elapsed times come from Python monotonic clocks and include startup
unless explicitly identified as an internal timed section.

Pushed revision1f27a8b18ff6ba1ffda2025e8095c89491c1f563. Full conventional NLO
EEC remains incomplete: identical/gluon measured DEs and physical values,
original-source RR endpoints, complete angular pole cancellation and final
explicit result still need completion.


## Exact identical-quark DE and physical moment constraints

The controlled DE recovery has completed successfully in1426.822s including
startup, retaining earlier equation-generation work. This is a recovery-stage
time, not a cold calculation total. Both derivative searches now close exactly;
the saved DifferentialSystem.wl is the input to physical-basis/master evaluation.
The earlier OOM3116.165s and memory-guard244.556s attempts remain failed costs.
Duplicate snapshot deserialization and rebuilding were removed; no healthy
native computation was discarded for this change.

Automatic pair identification and the fixed-sign absolute measurement Jacobian
now prepare moments for all43 source coordinates. Ten exact combinations lie
in the retained source span. Their inclusive RHSs involve11 targets in3 families,
reduced to6 evaluated physical scalars. InclusiveMomentValues.wxf was produced
in37.986s including startup and exact reduction. Coefficient order demands and
omitted-tail checking are retained. Neither physical-constant rank nor sufficient
depth for inverting the eventual moment matrix is yet established.

Actual Pro28 reviewed fb974069 and confirmed the signed-cut and selector formulas.
All parsed coefficients now undergo exact rational checks, including fully reduced
images and inclusive RHSs. The accepted reduction catalogue/rules are retained
with the selector.10 assertions pass2.966s; the first test attempt15.608s failed
only because it compared association key ordering, and is retained separately.
The real43/10 moment records and nested inclusive provenance were refreshed with
exactly unchanged moment rows in15.222s. No native solve was repeated for this.

The next decision milestone is the full source-required identical-quark physical
interior, with every relevant homogeneous constant fixed and an independent
check. The gluon measured sector and original-source endpoint/contact proof remain
separate obligations. The complete NLO EEC result has not been compared with a
published measured coefficient.


## Physical coverage and finite-integration preparation

The first physical-basis/provider stage finished465.697s and intentionally
returned PhysicalMasterCoefficientsStillRequired. The42-coordinate selected
basis has12 partial/complete value records and34 unresolved source demands;
7 of41 directly needed integrals currently have sufficient depth. This is a
partial result, preserved in PartialMasterValues.wl, not a failed native DE.

A128.191s inventory retains the block structure, all required/known upper
orders and pending derivative order losses. Ten source moments also reduce
exactly into the selected DE basis. Epsilon rescaling removes negative entry
valuations; the zero-order diagonal blocks have size at most2. The existing
general finite-integration preparation succeeds in124.323s with every basis
transformation verified. Work/FiniteIntegrationPreparation.wxf retains it.
No unknown physical constants or complete interior are thereby claimed.


The existing finite-solution constructor builds U^(0) and U^(1) for all42
coordinates in10.870s including startup. Basis convolution requires connection
coefficients through order3,480 matrix coefficients; the shared planner derives
that demand. The finite integral definitions are explicitly stored in
FiniteEvolutionThroughOrder1.wxf. This demonstrates construction up to initial
constants at these fundamental-matrix orders, not sufficient original-master
orders or physically fixed coefficients. A bounded GPL conversion pass follows.


## Continuation: explicit GPL representation and partial physical orders

The successful 42-coordinate finite preparation remains unchanged. Conversion
of U^(0), U^(1) now covers418/437 integral definitions. Positive proportional
radicands are merged only after proof of a positive integration-variable-independent
ratio, with branches retained. Collecting word coefficients before applying the
unchanged size bound solves three further expressions. Latest incremental pass:
76.128194379s including startup and reuse of415 earlier GPL definitions. Remaining:
6 per-definition10s timeouts,1 rational partial-fraction refusal,12 dependencies.
The first/root-scale passes cost31.684s/55.799s separately. No complete physical
coefficient or sufficient epsilon coverage is asserted.

A separate code omission was fixed: the differential consequence constructor now
extends a master that already has partial epsilon data. It excludes the solved
column from the RHS even when that column has old data, retains accepted old
coefficients, and uses the existing omitted-tail audit.10 tests pass3.316426820s.
A replay on the actual identical-quark records took4.203063809s and found no new
sufficient orders;7 of41 source requests remain covered,34 unmet. No redundant
physical provider integrations were rerun.

Pro31 reviewed25b643f1134775fbfbd439d7c9a2ad72f496fecc and accepted positive-scale
root merging, including imaginary initial branches. Its inherited basepoint
finding is addressed by explicit chart validity conditions and assumption-aware
zero-basepoint rejection;26 tests pass1.633170317s. The reviewed algebraic-period
pole theorem requires common absolute convergence for the complete fixed-z fiber.
The existing parent distribution certificate alone does not establish the sharper
four-dimensional bound. No guessed -4 bound or deeper evolution cutoff was added.

The user's broader PSLQ proposal was tested on actual DE entries with identical
support supplied to both reconstruction methods. See PSLQBoundaryStrategy.md for
all costs and failed trials. This was a recognition benchmark with a saved-formula
oracle, not numerical IBP sampling or an end-to-end FireFly comparison. Production
finite-field reconstruction has not been replaced.


## Pro32 repairs and common rational coordinates

Pro32 statically reviewed3bbed6a74e4b986500e03be14217fca96cd7e530. The partial-tail
formula is correct for consistent physical inputs. Its overlap residuals are
now retained, including coefficients below the previously established lower
bound; the local fixture was changed to satisfy its full DE.12 assertions
pass2.817729775s. Root charts now retain assumptions, and expression integration
refuses unresolved chart validity conditions instead of dropping them.28 assertions
pass1.164938174s. Neither test supplies physical boundary constants.

Increasing per-definition time10s->30s supplied no additional old-coordinate
GPL definitions;170.116064852s actual elapsed. The partial-fraction diagnostic
found algebraically overlapping factors, so a plain factor-count assumption is
insufficient. No unverified CRT fallback was adopted.

The forward rational-map verifier and its record normalizer now allow arbitrary
matching dimension. Existing two-variable consumers retain their explicit scope.
A new conic constructor derives a common coordinate for two rational-coefficient
affine radicands using a rational point when available; failure is not a
non-rationalizability claim.7 new assertions pass2.883837078s; the12 existing
catalog assertions pass2.765783202s, and the complete old two-variable pullback
and numerical solution test passes4.603423101s. One new derivative test initially
needed Together before Cancel; no formula changed. A test receipt initially used
a completion prefix without its leading count; it was corrected against the
saved all-pass output, with the reason retained.

The actual prepared identical-quark field consists of sqrt(z),sqrt(1-z).
Pulling the entire system to a common conic coordinate and constructing U0,U1
completed11.808280876s. Retaining z*=1/3 gives an algebraic lifted basepoint;
its first GPL pass137.055290739s has new algebraic-coefficient bottlenecks and
is not an improvement. A rational lifted basepoint u*=1/2 instead gives a rational
source point and rational source roots. No physical constants have yet been
assigned, so this separate solution can choose that normalization point without
changing an accepted physical value. Inspect the rational-basepoint job receipts
before any further launch.

The parent distribution pole theorem in Pro32 is accepted mathematically only
with the stated class-membership evidence, including1/Abs[F]. No automatic
physical bound is installed yet. A compatible smooth meromorphic restriction
to an interior chamber is still required to use it for scalar DE coefficients.

## Continued physical-order work

PSLQ and numerical reconstruction are deferred at the user’s request. The current
work is exclusively completion of the measured NLO EEC calculation.

Feasible intermediate DE order extension adds four partial master records in
50.632 s. It still leaves 34 unmet full requests (7/41 sufficiently covered);
`ExtendedPhysicalMasterOrders.wxf` preserves the new records. The permanent
extension now keeps useful intermediate orders and checks both lower-bound
overlap directions; 14 assertions pass in 3.566 s.

The new polynomial-parent pole-bound module verifies all 42 original measured
masters in 16.424 s. Each has distributional lower bound -5. This is a bound on
regulator poles, not physical coefficients, a scalar restriction, endpoint
contact order, or a resolved-sector construction. Pro33 describes a separate
distributional-DE route to smooth restriction; its hypotheses must be retained
before such a claim is made. Six parent-bound assertions pass in 3.803 s.

A shared normalization verification defect rejected the regulator itself and
reciprocals of expressions whose constant term cancels. It now recognizes the
regulator and checks the true Laurent valuation of reciprocal bases. Three
assertions pass in 2.865 s; no physical normalization is changed.

Conic inverse metadata is retained (eight assertions, 2.834 s). The common
rational coordinate with lift u=1/2 maps to z=9/25 for the actual root ordering.
Fundamental evolution through order one took 11.772 s. Its GPL pass took
137.938 s and remains partial; endpoint-dependent path scaling is being inspected
as a source of unnecessary algebra. These are not physical master solutions.

No Wolfram job was running at the start of this continuation. Completed timings
include startup; input reuse and failed earlier attempts remain in their receipts.
Full measured RR, physical constants and endpoints remain incomplete.
