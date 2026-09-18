# Conventional NLO EEC campaign

Started 18 September 2026. Target: the complete massless vector-current EEC at
order alpha_s squared, including both angular endpoints and self correlations.
The project counts orders relative to the two-quark Born process, so the new
raw contributions and result belong under `Projects/EE_EEC/{Raw,Results}/NNLO`.
The accepted order-alpha_s result is conventional LO EEC and is not this target.

## Execution constraints

Use the ordinary cards and general package interfaces. Published EEC coefficients
are independent verification inputs only. Do not put a process-specific formula
or boundary constant in production. Use at most eight aggregate CPU cores and
two main Wolfram kernels. Record supervised elapsed time including startup,
and state whether reductions or library masters were reused.

The existing heartbeat checks this campaign every five minutes for up to eight
hours. Inspect actual jobs before launching anything; never duplicate a running
calculation. Update this record with launch paths, completed stages and failures.

## Initial assessment

The framework already generates current amplitudes and polynomial measurement
cuts, constructs cut IBPs and DEs, and stores physical master solutions. The
complete two/three-particle order-alpha_s EEC calculation is tested. Required
extensions include four-particle physical master boundaries, measured
three-particle one-loop integration, two-particle two-loop and one-loop-squared
terms, and coupling renormalization in the same interval-distribution format.
Flavor sums must include all current attachments without double counting.

Actual GPT-6 Pro is reviewing the mathematical strategy in
[this conversation](https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84).
Before asking implementation-specific questions, push the current code and
provide the GitHub repository plus exact commit and relevant source links.

At this initial assessment no new NLO EEC contribution has been calculated and
no computational kernel has been launched. The completed normalization tests
are documented separately in [DerivedNormalizations.md](DerivedNormalizations.md).

## Development progress

The framework baseline was pushed as `77953eca` and supplied to actual GPT-6 Pro.
Pro completed the mathematical review and then confirmed inspection of that
exact public revision. Its assessment distinguishes existing general cut
definitions from the missing physical integrations and NNLO orchestration.
See [the review summary](../../External/ChatGPT/Records/2026-09-18/02_nlo_eec_strategy.md).

The user further requires obtaining and saving our own complete coefficient
before comparing with published EEC coefficients. No such comparison has been
performed for the new order. Keep this order of work in subsequent follow-ups.

Implemented general two-, three- and four-body invariant phase-space coordinates
in `FeynFacet/Integrals/Parametric/InvariantPhaseSpace.wl`. The four-body chart uses
two cluster decays with dimensional angular measures. Fifteen checks passed,
including absolute volume and a nonconstant moment at epsilon=0 and -1/2
(84.45 s including startup). This is physical integration geometry, not a solved
measured master or a final result. High precision quadrature emitted convergence
warnings while resolving these checks beyond their required tolerance.

Tuple preparation now simplifies the common unmeasured density before attaching
each weight and cut Jacobian. It preserves original off-shell ordinary
propagators and checks their prescriptions. Rational coefficient collection
treats dimensional scale powers as coefficients, avoiding a silent failure of
the optional numerator cancellation. The existing three-body integration check
passes (18.52 s), and sixteen four-body direct/shared-density and causal checks
pass (18.94 s). These are internal checks, not published NLO coefficient tests.

Cards now enumerate the unit-charge current over nf degenerate flavors, with
qqbgg, identical four-quark and distinct four-quark state sums. Born/real/virtual
cards share that flavor definition. NNLO real-virtual and both two-body virtual
amplitude orders are declared; their new integrations are still unimplemented.
Six state-counting and card checks passed in 15.47 s, including the automatically
derived nf, nf/4 and nf(nf-1)/2 contributions before the appropriate gluon factor.

The current owned production attempt is the qqbgg preparation:
`Raw/NNLO/q-qb/DoubleReal/Work/Components/Gluons/Prepare.log` and `Prepare.json`.
It uses CPU indices 0..6, reserving CPU 7 for small independent development checks.
The driver is `Scripts/run_measured_contribution.wls`, stage `prepare`, with
compiled component `DoubleReal.Gluons`. Its actual files live in the nested
component `Work` directory. Earlier interrupted/failed attempts are retained
alongside the launch log; they are not successful production timings. Inspect
the receipt and process list before starting another attempt. No measured DE
or order-alpha_s-squared coefficient has yet completed.

The distinct-flavor four-quark component subsequently completed preparation in
222.42 s including startup on CPU 7. Its six noncontact decompositions and one
self-pair contact are saved in the component's `Work/MeasuredIntegrands.wl` pair.
Its `DifferentialSystem.log` now tracks DE construction on CPUs 4..7. The active
gluon preparation was restricted to CPUs 0..3, including its already-created
threads, before that launch. Thus the two current main kernels share eight cores.

The universal massless vertex provider now also derives timelike phases from
each connected loop component's scale degree and causal prescription. Opposite
causal disconnected bubbles retain their complex modulus and loop-measure sign;
connected mixed prescriptions are rejected by this continuation method. Eleven
internal branch and Laurent-truncation checks passed in 17.32 s. This supplies
scalar integral values, not generated two-loop form-factor coefficients and not
the missing measured virtual assembly. The four-body implementation at revision
`f126f874` has been pushed and sent to Pro for a focused static review.

The first DE attempt was then stopped after 318.80 s of preparation, before
claiming any completed reduction. The unoptimized gluon attempt was stopped
after 1206.11 s, still converting large polynomial numerators. Their receipts
record unsuccessful/interrupted attempts, not production success.

An exact polynomial-cut relation now reduces the small measurement weight times
Jacobian before multiplying it by the amplitude. In this observable its loop
scalar-product degree drops from four to two. Original unrestricted propagators
are retained for dotted-cut equations; new external divisors are recorded.
Seventeen direct/shared four-body checks pass (7.97 s), as do seven exact
three-body phase-space checks (5.32 s), with all regulator dependence retained.
Both gluon and distinct-flavor preparations are now rerunning with this reduction,
on CPUs 0..3 and 4..7 respectively. Inspect their latest Prepare logs/receipts;
the preceding records have the prefix BeforePolynomialReduction. No new DE is
currently running. Restart the DE with the new inputs after successful preparation.


The subsequent global common-denominator attempt enlarged the distinct-flavor
last measurement from a few products to 192 products and 124,976 monomials.
The general rational optimizer now rejects increases in denominator support or
positive total power, and tuple preparation reuses the common source cancellation
rather than repeating it for every weight. An intermediate guarded preparation
completed in 168.66 s. Its successor is running with the repeated work removed;
the distinct-flavor DE follows automatically with target-based downward-closed
seed sets instead of the previous rectangular dot/rank extension. The old gluon
attempt was stopped after 1122.39 s; this is an unsuccessful attempt, not a total.

Current jobs: supervised gluon preparation on CPUs 0..3, and distinct-flavor
preparation followed by DE construction on CPUs 4..7. Read component Prepare and
DifferentialSystem receipts for completion; no full NLO coefficient exists yet.

The latest checks pass: shared preparation (17 assertions, 8.32 s), physical
coordinates including angular variances and the exact Gram determinant (19,
8.41 s), state counts (6, 5.57 s), and target-based IBP seed selection (10,
6.14 s). These are internal checks, not NLO literature comparisons. Actual Pro's
static review of f126f874 is saved in External/ChatGPT/Records/2026-09-18/
03_four_body_review.md, including the remaining tests and UV source requirement.


## Current execution after the first reduction study

All three four-parton state preparations have completed at least once:
qqbgg with timelike gauge reference, 645.90 s; distinct four-quark states,
71.81 s; identical four-quark states, 302.75 s. These are preparation timings,
not solved-master or full-result timings. Their receipts include kernel startup.
The gluon card now uses a null reference momentum already present among the
external partons, to avoid an additional gauge-reference denominator. Complete
amplitude checks compare physical/covariant polarization sums, two physical sums,
and null/timelike reference choices, as well as identical-gluon exchange. The
first such check passed in 61.06 s; the new card is being checked and regenerated.

The unrevised distinct-flavor DE attempt was stopped after 2572.34 s. Its initial
exact reduction is retained, but derivative closure had expanded to 831,246
candidate equations before incorporating the subsequently developed adaptive
seed refinement. No closed four-body DE or physical master values are claimed.
Polynomial measurement propagators now participate in exact momentum-relabeling
identification. The distinct-flavor input drops from 4,637 targets in 36 families
to 2,370 targets in 32 families after combining the declared scalar structure;
this takes about 5 s in the kernel. These are integral targets, not independent
masters. More general family mappings of irreducible numerators remain useful.

The UV operator is now generated by the existing general counterterm planner
with an empty set of PDF/FF legs. It regenerates its own real and virtual NLO
sources through epsilon^1 below Counter-UV/Work/Channels/q-qb/Sources, using
shared epsilon-independent amplitude definitions in the common card. No sibling
LO/NLO result is read. Its pole normalization is the shared bare-coupling map.
Ten new checks and 25 existing Laurent/source/renormalization checks pass.

A target downset alone failed to close the three-body source DE. The general DE
constructor now adds exact predecessor seeds at newly exposed masters. It closes
the six-master three-body system, rather than differentiating to indefinitely
higher measurement-cut powers. The resulting basis requires general Gauss
functions. A two-by-two epsilon system plus finite integer contiguous relations
now gives explicit GPL coefficients for affine perturbations of positive integer
Gauss parameters. Eleven direct numerical-function checks pass; no EEC hard
coefficient is used.

The first complete UV result required 251.20 s after retained upstream work.
Endpoint assembly dominated: 156.66 s for its real source and 64.27 s for its
virtual source. Replacing unrestricted FullSimplify with exact logarithm expansion
and rational/transcendental coefficient collection reduces those two stages to
0.89 s and 0.11 s. All source coefficients agree with the preceding output at
three high-precision physical points. The source regeneration/check took 33.78 s;
reassembling UV from those newly generated sources took 3.60 s. Neither is labelled
a cold full-project run. The ordinary order-alpha_s result was regenerated from
its own cards in 67.05 s, with exact pole cancellation and generated Born
normalization, without a new literature comparison.

Pro's static review of 117012d8 confirmed the numerator reduction and timelike
phases, and identified two bounded repairs: a denominator-cleared certificate in
the original measurement generators, preserved through merging; and a guard
requiring the vertex catalog's actual kinematics to agree with its analytic
region. These are implemented and tested (25 measurement checks, 14 vertex
checks, including library-enabled timelike reuse). See review record 04.

The full order-alpha_s-squared coefficient remains unfinished: four-body master
solving and boundary data, measured real-virtual integration, two-body two-loop
and one-loop-square orchestration, and final endpoint assembly are still required.
Do not compare the published NLO EEC coefficient until our complete result is saved.

## Two-body virtual completion and family numerator maps

The null-reference qqbgg preparation completed in 385.32 s including startup,
versus 645.90 s for the previous timelike reference. This is preparation only.

The complete two-body virtual raw contribution is now saved in
Raw/NNLO/q-qb/Virtual/Results.wl (67,579 bytes of readable text, 3,177 bytes of
metadata). Its generated components are two-loop/tree interference (17 forward
diagrams), one-loop square, and a generated exact zero from the four diagrams
of the vector-current two-gluon candidate. The latter exposed commuting color
matrices inside closed Dirac traces: FCTraceFactor now separates tensor spaces
before color contraction and complex conjugation in the general algebra code.

Both nonzero components reduce to verified timelike scalar-library definitions.
The one-loop square closes its first 220-seed reduction. The two-loop term closes
after targeted refinement from 1,521 to 2,285 seeds. An unrestricted FullSimplify
of the expanded coefficients caused two stopped attempts (282.04 and 257.88 s);
this was not a master-integration cost. Exact coefficient collection and local
refinement of branch atoms replace it. Matrix Laurent expansion now computes
each distinct entry once through its greatest demand. RetainAllPoles preserves
the complete derived lower bound in raw virtual output.

With retained reductions, component integration took 6.52 s and 8.01 s. The full
raw virtual driver regenerated amplitudes and assembled all components in 12.37 s,
including startup and compatible IBP/library reuse. This is not a cold total.
The independent check uses one-loop tensor reduction and its Gamma functions,
rather than the two-loop IBP or conjugate-bubble library value: every coefficient
from epsilon^-4 through epsilon^0 agrees at two physical scale choices. Five
assertions pass in 17.81 s. No published EEC coefficient is used.

Actual Pro reviewed a023942a in 11m56s, confirming the affine Gauss expansion and
the mathematical family-map proposal. Record 05 lists the covered-sector and
causal qualifications. Fifteen Gauss checks now include coefficientwise DE
residuals through epsilon^3 and both complex sides of the argument cut (5.97 s).

The new CutFamilyMaps module identifies denominator supports once, reconstructs
and verifies the exact loop/slot maps, then uses the existing MultiplyCutIntegral
for numerator images and dotted cuts. Positive powers of unmatched auxiliary
slots are rejected. Six focused tests pass in 5.05 s. Combined with scalar
coefficient collection, the distinct four-quark source drops from 4,637 targets
in 36 families to 468 targets in 7 families (5.51 s within a 19.58 s supervised
read/transform/write run). These are pre-IBP targets, not a master count.

A new distinct-flavor DE attempt runs on CPUs 0..3, with the latest adaptive
predecessor refinement and family maps. Its receipt is the component's
DifferentialSystem.json; the old reduction tree is retained as
Work/BeforeFamilyMapsDifferentialEquations. Inspect the actual job before
relaunching. Full four-body physical masters and real-virtual integration remain
unfinished, so the complete order-alpha_s-squared result does not yet exist.

## Real-virtual preparation and rational reconstruction

The preceding unscaled distinct-flavor DE attempt timed out after 1802.16 s.
Its first derivative-seed refinement generated 563,199 equations with 475,421
integral identifiers; the exact reduction did not finish. Kira's intermediate
37-master rank diagnostic is not a verified final count or a closed DE.

Removing Q2 by a verified change of equation unknowns did not suffice: the
four-core comparison timed out after 1203.00 s, still in symbolic elimination.
The equation and identifier files are retained. The scale-removal step also
contained repeated list growth; it now preallocates the per-row degree array.
Six checks pass in 14.17 s: exact agreement with unscaled reduction, restored
cached units, the quadratic measurement's degree two, reconstruction of each
original polynomial-cut equation, and agreement between FireFly and Fermat.
The native FireFly benchmark now uses the retained scale-independent equations
in `DifferentQuarks/Work/DifferentialEquations/FireFlyDerivativeSeedRefinement1`.
This benchmark excludes equation generation and is not a cold DE solve.
Its supervised log/receipt are the component's `FireFlyRefinement.*` files.
See the final receipt before reporting completion. The method uses Kira's
documented support for user-defined systems and finite-field reconstruction:
https://arxiv.org/abs/2008.06494, sections 3.1 and 3.2.

Actual Pro's source review of a4a8b9bf is retained in record 06. It found a real
reuse defect: the virtual integration cache omitted the derived flavor and
symmetry multiplicities. Both one- and two-loop paths now include them; a
changed flavor sum regenerates the integration even if its representative
amplitude is unchanged. Seven checks pass in 33.87 s. The zero output of a
family map now retains coefficient groups and exceptional divisors; seven
numerator-map checks and six polynomial-equivalence checks pass (5.47/5.07 s),
including a nontrivial particle permutation.

The physical three-body measurement map is now shared by tree integration and
loop-first integration. Six new bubble/pushforward checks pass in 5.52 s; seven
existing exact invariant-integration checks pass in 7.04 s. A separate generated
loop-density test passes five assertions in 5.27 s, checking the Gram map, the
loop measure, causal metadata and rejection of incompatible coordinates.

The full generated real-virtual source reduces to four B0 functions, six C0
functions and three one-mass boxes. Exact triangle identities leave B0/D0
combinations. The general card-owned `loop` preparation stage generates the
source, reduces the loop, selects particle coordinates from the card's tuples,
and writes all noncontact integration densities plus separate self contacts to
`RealVirtual/Work/PreparedScalarLoopDensity.wl`. The successful ordered-chart
attempt took 42.59 s including kernel startup. A preceding attempt stopped
after 39.94 s on an unsupported root partition and wrote no accepted density.
The scalar reduction alone took 31.82 s by AbsoluteTiming. Internal stage clocks
are diagnostic and are not substituted for the supervised total.

Record 07 contains Pro's mathematical review of moment completion. Inclusive
moments can determine ordinary contacts only after a physical contact-order
bound excludes hidden delta derivatives. Finite interior behavior alone is
insufficient. The proposed bound and inclusive-master route are not implemented
or assumed here. Full RR master integration, RV scalar integration and endpoint
completion remain; no published NLO EEC coefficient has been compared.


## Explicit real-virtual energy integration

All three noncontact pair groups now have explicit GPL coefficients through
finite order in `RealVirtual/Work/IntegratedScalarLoopRow{1,2,3}.wl`, with paired
metadata. This is one causal orientation at fixed interior z. It does not yet
include self contacts, measured-angle endpoint distributions or the conjugate
interference, so it is not an accepted real-virtual result.

The successful supervised integration took 140.75 s. A separate check compares
each finite coefficient with direct integration of its generated scalar Laurent
density at z=1/3, Q2=2, muR2=3 and physical color/coupling values. All three agree
to at least 30 decimal digits; the supervised check took 33.54 s. Earlier checks
failed because their script left the coupling symbolic; no coefficient was
changed to obtain this agreement. This check verifies integration, not an
independent loop-amplitude provider or the published EEC coefficient.

The exact endpoint test now decomposes the original prescribed external products
and verifies integrability separately for each product before removing its i0.
It uses the elementary modulus bound for each real external denominator and
retains the virtual scalar functions' causal prescriptions. It only allows
coefficientwise energy integration when the resolved integer powers at both
energy endpoints are nonnegative. Harder inputs fail pending explicit regulated
subtractions. This supplies no claim about measured-angle endpoints.

Negative-real polylogarithms whose argument tends to infinity are inverted with
the complete Bernoulli-polynomial identity after proving their sign. GPL size
limits are checked after shuffle/coefficient collection: the actual RV input
otherwise exceeded the limit before its exact cancellations. All three rows
now integrate under the unchanged expression limit. Standalone GPL loading no
longer creates a Global GLI symbol that shadows FeynCalc.

Focused checks: fourteen scalar-measurement assertions (5.77 s), thirteen GPL
pullback assertions (1.46 s), seven box-endpoint assertions (5.32 s), ten resumed
DE assertions (10.32 s), and seven scale/export-closure assertions (16.77 s).
The generated source with original prescriptions took 61.89 s to prepare.
These are supervised totals; internal AbsoluteTiming diagnostics are separate.

The retained scale-normalized FireFly benchmark completed in 240.71 s including
startup and import (native solve 215.10 s), versus the symbolic timeout at
1203.00 s. Its 152 surviving integrals include targets outside the requested
source and are not a final master count. Generic DE resumption keeps all exact
relations but restricts its evolving basis to the original requested targets
and derivatives; it starts with 57 spanning integrals. The distinct-flavor
resumed run is still working toward differential closure. A full alpha_s-squared
coefficient has not been obtained and has not been compared with literature.


The production `loop-interior resume` invocation completed in 145.71 s with all
three rows newly integrated from the existing prepared density. Its subsequent
resume took 6.22 s including startup and reused all three exact row definitions.
The initial resumed four-body DE reached its 1803.36 s supervised timeout during
its second derivative-closure reconstruction. A longer supervised continuation
now reuses the verified native equation files, in addition to completed reduction
rules. The new eight-assertion native-resumption/scale/selection test passes in
19.08 s; it deliberately removes a test export and prevents equation regeneration.
The current receipt/log prefix is `DifferentQuarks/ResumedDifferentialSystemLong`.

The DE convention regression passes ten assertions in 11.09 s. One preceding
invocation had a wrong supervisor completion prefix despite ten passing assertions;
another failed earlier in input preparation. The test now diagnoses preparation
failures explicitly; the subsequent diagnostic run passed. That transient's cause
has not been established, and its receipt remains unsuccessful.


## Hermitian completion and uniform endpoint domains

Pro reviewed b9b0daf7 in 18m25s (record 09). The normalization, prescribed-product
bound, negative-real GPL inversion and native scale restoration were accepted.
Three concrete repairs now cover whole-interval regularity, consistent returned
restricted DE metadata, and exact binding of integrated rows to actual prepared
mathematical inputs. The row input lives in the existing binary companion; no
new hash or duplicate readable source formula was added.

Hermitian completion now conjugates the full scalar Laurent density on verified
branches before GPL integration. The first production invocation completed all
three groups in 378.03 s; global Factor before word collection caused excessive
cost, especially 155.82 s for the first finite coefficient. Removing that global
factorization allows the existing GPL collector to cancel matching words first.
The optimized full three-row regeneration completed in 140.24 s including startup
and the stronger domain checks (BoundHermitianInterior.*), down from 378.03 s.
Its finite-coefficient integrations took 23.20, 23.58 and 24.24 s internally.
All three preceding Hermitian coefficients independently agree with direct
quadrature to more than 30 digits; that check took 37.39 s.

Whole-energy-domain proofs passed for all actual groups in 37.02 s. The weighted
z(1-z) endpoint study uses a complete half-square/positive-sector cover and checks
both the original prescribed products and artificial seams. All 24 retained
charts passed the stronger closed-cube factor test in 22.93 s; their exploratory
resolutions took 114.52 s. This is a contact-order bound, not evaluated contacts.
The card-owned loop-contact-order stage is being run and must complete before
its result is claimed. Self-pair contacts must not be added again if the combined
endpoint contacts are subsequently obtained from the inclusive moments.

Focused checks now pass: 24 measured-loop/integration/contact-order/reuse assertions
(6.60 s), eight closed-cube regularity assertions (3.67 s), and twelve DE restriction
and convention assertions (9.77 s). The restricted-DE change postdates the running
RR kernel; reload/re-import its completed reductions through the current constructor
before accepting its final DE record. No full NLO EEC coefficient exists yet.


The card-owned ordinary-contact proof has now completed: 181.93 s including
startup, covering all 24 charts of the three prescribed tuple groups. Its saved
record is RealVirtual/Work/MeasuredContactOrder.wl with paired binary input
metadata. The common measurement-moment constructor derives the inclusive
moment weights directly from each card's tuple sum, momentum conservation and
unit massless cuts. For these cards they are 1 and 1/2; no fixed EEC factor is
inserted. Six general moment assertions pass (5.05 s), including changed tuple
ordering, two/three/four particle states and a constant observable. The production
moment-weight update reuses the proven charts and took 7.32 s. The inclusive
amplitude integral itself has not yet been evaluated.

The optimized Hermitian result now has an exact prepared-input companion, and
its subsequent full-input/coverage/proof-checked resume took 8.72 s. There remains
no complete alpha_s-squared EEC result or literature hard-coefficient comparison.


## Regulator-complete RV proof and reduction-resume diagnosis

The full prefactor and coordinate-independent scalar factors now participate
in the sufficient finite-meromorphy test. Essential regulator dependence is
rejected. The closed-cube test passes 11 assertions (5.969 s); the density,
contact and exact-input reuse test passes 27 assertions (7.471 s), including
agreement of saved tensor labels with actual branch coefficient labels.
RV Hermitian interiors were regenerated in 161.919 s and all 24 complete-domain
contact charts re-proved in 257.283 s. These remain development intermediates;
the inclusive rate and complete distribution are not yet evaluated.
Actual GPT-6 Pro reviewed the preceding pushed code and its mathematical
findings are retained in consultation record 10. No EEC NLO reference coefficient
has been used. Universal scalar inputs remain separate.

The long RR continuation was deliberately stopped after 3487.033 s when its
selection-closure stage repeated exactly the same 1000 requested identifiers,
reconstructing the same 3527 coefficients. The successful initial native export
is retained. Kira's initial and final declared master lists disagree on 16
requested identity targets; the exporter calls these initial masters but they
are absent from masters.final. Repeating identical selections cannot establish
closure. A new diagnostic (26.781 s) finds the original source closes without
undeclared terminals, while required derivatives still expose 13. No final DE
or physical result is claimed. This needs a native export/resume fix, not a
relabelling of unresolved targets as solved masters.


### Native master declarations: source-level diagnosis and permanent repair

The Kira 3.1 source (official GitLab checkout aadf067) resolves the apparent
contradiction. `record_masters` records the initial IBP-system masters and removes
them from reconstruction targets. FireFly `write_to_database` inserts every
reconstructed RHS column into its final list. Consequently `masters.final`
omits identity-only masters and can include unresolved selected-system columns.
It is not interchangeable with the initial declaration.

Typed reductions now close against the initial system declaration, first try
an export-only dependency query, then reconstruct only still-missing dependencies
while retaining existing exact rules. A no-progress condition fails explicitly.
Old saved reductions without this closure convention are re-imported from their
native workspace. No integral is promoted to a master merely because it appears
on a right-hand side. The native scale/resume/declaration test passes 9 assertions
in16.074 s, and12 DE convention assertions pass in10.520 s. A preceding run had
all12 assertions pass but a mistaken supervisor completion string; its failed
receipt is retained separately.

The retained RR solve actually has51 unresolved RHS dependencies against its
initial master declaration. The new job reconstructs925 coefficients instead of
reconstructing the preceding3527 again. It remains running; no timing speedup
or closed DE is claimed yet. The initial16 missing identities are already valid
members of the native initial declaration and require no new solve.

The freshly regenerated Hermitian RV interiors also pass all three direct
scalar-density numerical comparisons, with errors below10^-30. Mixed cut/virtual
scalar decomposition passes6 assertions (3.216 s); actual inclusive production
still needs its endpoint continuation before opposite external prescriptions
can be identified.


## Card-owned inclusive RV preparation and exact subtractions

`loop-inclusive-prepare` derives the unweighted source with the same generated
normalization, constructs all eight complete charts and proves a common
negative-epsilon convergence neighborhood for every original external-prescribed
product. It completed in115.559s. This justifies its external prescription limit
after causal loop integration; virtual phases remain. `loop-inclusive-subtract`
automatically constructs exact-in-epsilon Taylor subtractions, full face terms
and their intersections, in14.172s. Both are saved under the raw RV Work folder.
No inclusive rate has yet been evaluated and no RV Results.wl is claimed.

The shared subtraction routine supports automatically determined higher Taylor
depths, not only simple poles. Six independent Euler-moment/overlap assertions
pass in4.419s. The scalar-density/inclusive-limit tests pass29 assertions.
The parameter-domain guard now rejects both undefined reciprocal germs and
undefined coefficients in analytic exponents:13 assertions pass in5.255s.
All eight saved physical inclusive charts pass the stronger parameter-domain
proof in12.521s. The prototype and failed first card wrapper invocation are
separate receipts; the latter was a list passed to an association-only check,
repaired in the shared card wrapper before the successful run.

Pro review11 independently derives the complex universal inclusive box U8 and
its exact hypergeometric representation. A separate local Euler/hypergeometric
check at epsilon=-1/4 agrees to1.4e-21 in9.012s. This universal scalar input is
separate from the still-uncomputed EEC hard coefficient. It has not yet been
registered as a production physical master value.


###13:32UTC continuation

The51-dependency reconstruction reached the first-prime high-degree phase and
the1800s supervisor limit (1801.153s). Saved native states were retained. It is
now resumed with the SAME mathematical input on all8 CPUs and a7200s supervisor
allowance. NativeDependencyContinuation.json records the owned PID/process group;
NativeDependencyClosureResumed.log records progress. This run only completes
native reduction import, not full DE closure. No second symbolic job should
consume the8-core allocation concurrently. Source and workflow directions are
pushed at3229fdbe; a further actual Pro review of that revision is pending.

## Inclusive source reduction and review repairs (14:04 UTC)

Actual GPT-6 Pro completed the review of3229fdbe after13m11s. It inspected the
source, confirmed the exact subtraction identity and native declaration change,
and identified three general-interface gaps. Record12 retains its conclusions.
The finite-parameter guard now applies to coordinate-dependent exponents,
Gauss/Appell parameters and normal-power slopes. The inclusive driver now proves
observable support and retained-root coverage of the original energy triangle,
including unit measurement-delta normalization. Separately read scalar sources
are bound to the exact producing calculation and original amplitude. A doubled
observable that covers only part of phase space is correctly rejected.

The four targeted tests pass65 assertions: parameter-domain guards15.926s,
inclusive-chart coverage16.927s, source binding19.176s, and exact subtractions
17.476s. These were single-core tests run alongside the native reconstruction,
with its affinity temporarily restricted to the other seven cores. Timings
include startup and should not be compared as isolated kernel benchmarks.
The actual source, eight inclusive charts and their subtractions were regenerated
in252.903s, including fresh amplitude generation and scalar loop reduction.
Intermediate symbolic probing emitted division-by-zero warnings in the last two
charts; the final proofs passed, and saved charts/subtractions contain no
Indeterminate or infinity values.

The new `loop-inclusive-decompose` stage applies only nonincreasing external
partial fractions on the original unit particle cuts, after the source's
prescription limit. Virtual denominators and signs are preserved. The shared
mixed decomposer now accepts affine generic propagators as well as standard
quadratic ones. Twelve assertions pass in17.212s. A preceding17.417s failed
attempt exposed the standard-only input restriction and is retained separately.
Actual-source decomposition completed in23.078s:934 targets in18 families.

`loop-inclusive-reduce` generated16020 typed IBP equations and reduced those
targets in29.253s including startup, on two cores alongside the RR run on six.
It retained exact native rules while resolving55 then5 missing dependencies.
The result has66 spanning integrals; no minimal-master claim is made. It is
saved as RealVirtual/Work/InclusiveScalarMasterReduction.wl. Family/routing
equivalences, additional relations if needed, and physical scalar values are
still required. The existing cut-equivalence frame construction uses particle
cuts to span every loop direction; mixed real/virtual families require a
prescription-preserving completion for the uncut loop direction.

The eight-core allocation has been restored to the continuing RR native job.
No inclusive rate, accepted RV result or complete NLO EEC coefficient has been
claimed, and no measured NLO literature coefficient has been compared.

### Mixed real/virtual routing (14:15 UTC)

Candidate momentum frames now complete the span of oriented particle cuts with
uncut quadratic-propagator momenta and coordinate axes. Both uncut orientations
are considered; only exact unit-Jacobian frames are retained. The existing
comparison of full denominator polynomials, directed cuts, causal signs and
physical measures still decides equivalence. Pure-cut full-rank construction
is unchanged. Three additional mixed tests verify a virtual loop shift, reject
opposite virtual prescriptions, and map dotted cuts using off-shell identities.
All15 mixed tests,7 numerator-map tests and6 polynomial-cut equivalence tests
pass; the latter two take7.664s and10.723s including startup.

The saved native reduction is reused without a new solve. Fifty nonzero input
integrals fall into eight exact routing classes, and coefficient cancellation
leaves seven scalar integrals in the inclusive rate. The wrapper also substitutes
D=4-2epsilon in imported rational relations before coefficient collection, so
there is no second independent dimension parameter in the scalar coefficients.
This replay took17.664s; its preceding routing-only replay took17.863s and has a
separate retained receipt. The29.253s first native reduction remains separately
recorded. No minimal-basis claim or evaluated inclusive rate follows from this.

The code through217a9a9e was pushed and sent to actual Pro, including the precise
source-level prescription question and the mixed-frame completion plan. That
review is pending. The next useful mathematical step is to evaluate the remaining
scalar types with generic subloop/phase-space machinery and the independently
derived universal box, after establishing the actual required epsilon orders.
The measured NLO hard coefficient remains uncomputed and un-compared.

### Inclusive scalar values (14:43 UTC)

All seven nonzero inclusive RV scalar integrals are now evaluated. Six have
exact Gamma-function expressions from full-dimensional tensor reduction and
Dirichlet moments; the last is mapped to the independently derived causal
inclusive one-mass box. The actual coefficients require this box through
epsilon^0 and two of the bubble moments through epsilon^3. The provider checks
the actual momentum map, family measure, phase and requested expansion order.
The universal box input is documented separately in Design/InclusiveOneLoopScalars.md;
no measured NLO hard coefficient has been imported or compared. All new scalar
values are recorded in the shared master library and the card-owned
RealVirtual/Work/InclusiveScalarMasterValues.wl. This is not an inclusive rate.

Eight bubble tests pass in17.062s; seven box tests pass in17.977s. The initial
six-of-seven evaluation took37.342s. The completed seven-of-seven evaluation
took26.821s, reusing the native reduction and six library values. These are
supervisor elapsed times including kernel startup, not fresh complete RV times.
Actual Pro review13 is retained in the review records. It approves the prior
source rewrite and recommends the direct scalar moment approach. Its minimum
signature completeness caveat remains: accepted momentum maps are valid, but
some equivalent families could fail to match.

The RR continuation has progressed beyond its first51-dependency solve and is
now resolving203 further dependencies while retaining959 exact exported rows.
Main PGID335582/kernel335613 remains healthy; Kira345117 is using all8 cores.
Inspect fresh process state before starting another job. There is still no
closed RR DE or complete NLO result.

### Inclusive rate and interval finite parts (15:13 UTC)

The generated inclusive RV master combination is now explicitly contracted,
retaining all implied poles and adding the Hermitian conjugate once. Its saved
coefficients in Work/InclusiveOneLoopRate.wl are nonzero starting at epsilon^-4;
the conservative extra orders through epsilon^-7 cancel exactly. The first
contraction took28.737s including startup and prior-value reuse; the routing/
geometry replay took27.822s. Six finite-product tests pass in16.012s.

Actual Pro review14 inspected pushed9b5a0e43 and confirmed the raw-loop/PaVe
normalization, universal box phase/coverage and coefficientwise endpoint theorem.
It identified missing bubble cut-geometry/dimension guards and a cold/warm
record-shape difference. Both are fixed: actual cuts must match the standard
three-particle frame, no additional acceptance restriction is allowed, dimension
is4-2epsilon, and the shared library wrapper returns requested finite coverage
for fresh exact functions as well as stored functions. Twelve scalar assertions
pass in17.014s and23 master-library assertions in18.246s.

Mixed routing now indexes all candidate signatures of a representative and
retains a DIRECT common-frame witness, rather than requiring equal minima.
Duplicate transformations are removed before polynomial substitution. Seventeen
mixed routing tests, six polynomial routing tests and seven box tests pass in
17.231s,18.729s and18.215s respectively. The actual inclusive replay preserves
the successfully evaluated scalar coverage.

The generic endpoint constructor combines a proved weighted-integrable GPL
interior with generated zeroth/first moments. It uses the explicitly declared
linear-endpoint-interpolation finite part, not an ordinary regular coefficient.
The common partonic format supports this distinct basis, constant weighting,
addition, interior restriction and exact conversion from the standard interval
basis by original moments. Nonconstant row multipliers fail until their contact
corrections are computed. Twelve tests pass in17.177s; all28 prior final-result
assertions also pass in17.376s. That latter supervisor was initially given a
wrong completion-line prefix; the retained verified receipt checks the existing
28-assertion output without rerunning the test.

The first distribution completion regenerated all three interiors, then reached
its600s cap during the third tuple-group contact proof (605.010s including
cleanup). No completed endpoint result is claimed from that attempt. This
attempt is retained separately. Contact proofs now checkpoint each completed
tuple group with its exact density and producing definition. The raw producer
resumed at15:13UTC with cached current interiors and a1800s allowance, on CPU7;
owned PGID357308, supervisor357307, execution session67696. Its state is
RealVirtual/Work/MeasuredRawContinuation.json and log MeasuredRawCompletion.log.
The RR native job retains CPUs0..6 during this run and restores0..7 afterward.
The full NLO result is still incomplete; no new measured literature coefficient
has been read or compared.

### Accepted complete real-virtual distribution (15:48 UTC)

Actual Pro review15 is complete and retained. It confirms scalar materialization,
contraction, direct momentum witnesses and the finite-part algebra. It required
stronger exact-source links and the existing explicit-contact support guard in
the new RV path. Both are implemented and tested. Prepared densities bind the
actual scalar source; aggregate interior and proof retain the same exact density
inventory, and the inclusive rate retains the same original amplitude. The
completed distribution and raw result keep these accepted inputs in binary
companions; mutable file paths are only navigation. Contacts outside{0,1} fail.
The acceptance schema is3. All35 measured-density/binding/contact assertions pass
in20.517s. A fresh-kernel read verifies that the unchanged card can reuse the
prepared source and that its exact scalar companion survives serialization.

The complete RV raw artifact is now Raw/NNLO/q-qb/RealVirtual/Results.wl with its
paired metadata:456771 and704797 bytes. It contains explicit GPL kernels and
delta coefficients at both endpoints in the declared interpolation convention.
Eight actual-result assertions pass in19.128s: common exact inputs, generated
zeroth/first moments, the omitted-order audit, cancellation of conservative extra
poles, explicit integral-free coefficients, and prepared-source/card reuse.
The current tuple inventory has four noncontact groups containing all six
ordered unequal pairs, and a contact group containing all three self pairs.
No self term is added a second time during moment completion.

Timing receipts remain separate: first complete raw379.561s; source-binding
migration924.338s (rebuilt interiors and proofs); final acceptance replay305.374s.
These reuse already computed amplitudes, reductions and physical scalar values.
They are NOT fresh whole-RV or complete-NLO timings. The earlier605.010s timeout
remains a failed attempt. The finite-part/common-format tests12, prior final-result
tests28 and scalar/geometry/library/routing checks retain their earlier receipts.

The RR continuation reached its7200s cap and preserved native reconstruction
state. A supervised SAME-input continuation is now owned by PGID382629, kernel
382661 and Kira383276 (inspect fresh PIDs). State is DifferentQuarks/
NativeDependencyContinuation2.json, log NativeDependencyClosureResumed2.log,
supervisor session55898. It continues the203-dependency/420-coefficient step;
399 coefficients had reconstructed before the second-prime tail. The supervisor
reserves CPU7 while another main Wolfram kernel runs and otherwise restores
affinity0..7. This Kira invocation began with7 workers; the affinity change does
not claim to increase an already-running native worker count. No new equations,
selection or factor-scan option was attached to its saved state.

Pro recommends exact elimination of already accepted rows before FUTURE residual
solves and a bounded factor-scan benchmark in a NEW workspace. Those optimizations
are not implemented or benchmarked; preserve the healthy current reconstruction.
The complete NLO coefficient is still unfinished, and no measured NLO literature
coefficient has been opened or compared.

### Exact residual equations for subsequent reductions (16:14 UTC)

The running native job is preserved. Its current dependency reconstruction has
advanced from410/420 to418/420 coefficients; the remaining two still need
additional prime-field probes. No RR DE completion is inferred.

The general `EliminateKnownIntegralRules` operation substitutes accepted closed
linear identities into every equation and retains all remaining columns, even
those outside the requested target span. `KiraReduction` accepts the explicit
`KnownIntegralRules` option, binds those rules in its workspace definition,
reconstructs the residual targets, restores physical scale factors, and composes
the original target images. `ConstructCutDifferentialSystem` can select this
operation for later derivative solves with `EliminateKnownRules -> True`.
It is opt-in and has not changed the active native reconstruction.

Sparse coefficient application now batches exact cancellation across rows;
previously each row launched a separate native simplification process. The
backend still deduplicates expressions and bounds its native input chunks.
There is no new finite-field or numerical approximation in this change.
Fourteen residual-system assertions pass in34.137s including startup: agreement
with an ordinary native reduction, physical-scale restoration, all-column
retention, exact zero targets, cached/unfinished imports, empty residuals and
changed-input rejection. The earlier scale/dependency regression also passes in
38.712s. Receipts are `Archive/Runs/2026-09-18/NLOEECChecks/Residual*.json`.
This is implementation validation, not a measured RR production speedup.

The bounded sample of the actual completed parent equations used64 evenly
spaced rows and32 longest input rows (96 total) from539711 exported equations,
plus923 transitive exact native rules. Residual construction took2.539s; rows
went96->88, columns931->915, and in-memory expression bytes3457296->2836992.
The largest row grew from5178 to5798 expression leaves. This mixed sample is not
representative enough to predict the full solve time; it shows no extreme swell
in these rows and only a modest column reduction. The read-only sample and paired
report are under DoubleReal/Work/Components/DifferentQuarks/Work/
DifferentialEquations/FireFlyContinuation/ResidualBenchmark. The native equations,
selection and reconstruction state were not changed. Four existing sparse
coefficient-application assertions also pass in16.576s after batching.

Actual6Pro review16 was submitted against pushed8c92f11b5e1539f748e85b36d3f8235d7e65dcda.
It is pending at this entry. No large solve uses the new elimination option yet.

### Different-quark RR DE closed and reduced

NativeDependencyClosureResumed2 completed successfully in2224.850s measured by
the Python supervisor, including startup; the Mathematica internal stage clock
printed2433.924s and must not replace that external receipt. Earlier attempts
and their native work remain separately charged. The420-coefficient dependency
step finished, followed by3 remaining dependencies/4 coefficient functions in
DependencyReduction003. There is no native reconstruction left running.

The completed reduction covers1000targets with382 terminal spanning entries.
Its ORIGINAL468targets in7families use only37 spanning integrals. All236 required
first-derivative targets are already covered and reduce to the same37-dimensional
span. The general constructor saves a closed source DE without another Kira solve.
Coverage inspection took10.972s; the closure/materialization run23.381s, including
startup, with receipts ClosedReductionCoverage.json and
ClosedSourceDifferentialSystem.json in the component's owned directory.

The general exact-equivalence/differential-relation reduction maps37 to24 direct
classes and then18 DE coordinates. Selection from source integrals gives18
unit-cut masters; the defining DE identities are checked exactly. This took
17.094s including startup (0.881s equivalences/differential relations and1.766s
basis selection internally). Paired artifacts in the component Work directory:
EquivalentMasterDifferentialSystem.wl, PhysicalDifferentialSystem.wl,
MasterIntegralDefinitions.wl and PhysicalBasisPreparation.wl. These are not
physical master values and do not establish completion of the other RR components.

Pro16 has completed static source review, confirming residual algebra, scaling,
composition, native restart and the repaired RV input binding. It identified
retention of a caller-supplied off-target identity pool across DE iterations,
rejection of the unsupported NativeDiagnostic option, and recording residual
row counts. These repairs are under a targeted regression run. The previous
16-assertion DE/scale regression passed in35.836s. Pro17 is pending on the
independent general pair-resolved four-particle coordinate derivation recorded
in Design/PairResolvedPhaseSpace.md. No measured literature coefficient was used.

All three Pro16 implementation findings are repaired and the18-assertion
regression passes in34.387s (ResidualProReviewRepairs.json). No large production
solve has yet enabled residual elimination. The active native job completed
with the unchanged equation system; the new option was not the cause of its
completion or the subsequent37->18 exact basis reduction.

### Pair-resolved physical coordinates and first explicit RR periods

Pro17 completed its mathematical review: exact measure, dimensional angular
weights, invariant signs, Gram determinant and inclusive volume agree. The review
identifies correlated d=1-z*x and K=1-z+z*rho limits and moving angular collinear
loci; those remain endpoint work, not a normalization discrepancy.

The general coordinate constructor and unit polynomial-measurement pushforward
are implemented, with scalar parity and unit-cut restrictions explicit. Fifteen
geometry/pushforward assertions passed in15.012s. Adding the physical Euler
provider gives18 assertions, including two rational negative-epsilon comparisons
against independently integrated beta/Gauss periods. It computes actual basis
entries1 and2 of DifferentQuarks exactly in epsilon, without any ordinary causal
denominators, external measured coefficient or free DE constant. The second
period uses a different particle ordering and the independently derived absolute
Jacobian. Values are PhysicalEulerSeedValues.wl with its metadata companion.
Successful first evaluation took4.567s including startup; three earlier failed
attempts retain separate receipts. Other16 basis periods and endpoints remain.

A dependent measurement denominator is now preserved as its formal coordinate
when it is exactly the same unrestricted polynomial in the target family. Thirteen
coordinate-map/partial-reuse assertions pass in13.924s. Verified complete equations
can be retained with RequireComplete->False while all unmapped equations remain
reported. Actual reuse retains429 equations for IdenticalQuarks and356 for Gluons;
this is not a completed reduction of those components.

Independent family preparation took94.978s for IdenticalQuarks (4234targets,
32families) and113.307s for Gluons (9944targets,91families), including startup.
DifferentQuarks source contraction/profile took26.827s. Its exact coefficient
valuations require at least epsilon^1 for some masters at interior kinematics;
physical master pole bounds and endpoint requirements are still needed for the
complete order plan. None of these stage timings is a whole-NLO cold timing.

### Explicit derivative periods and recoil angular integration

The general DE consequence operation derives basis entries3 and5 from physical
seeds1 and2 without integration constants. Its five regression assertions pass
in15.573s; actual derivation and shared-library publication took20.176s. All four
values are exact in epsilon. Explicit GPL Laurent coefficients through epsilon^1
were subsequently generated in19.775s with the omitted-order audit, saved in
PhysicalSeedLaurentCoefficients.wl. These are open-interval coefficients; the full
endpoint order plan is not inferred from them.

Actual Pro18 reviewed pushed a46db76779339b4cd7d5a8896876388f8a2f0d09.
It confirmed normalization, physical-root handling and equation reuse, and found
missing dimension/analytic-branch compatibility checks. Both are repaired.
Fourteen coordinate-reuse assertions pass in15.925s;21 pair-coordinate/Euler
assertions pass in18.230s, including the tagged complement mass and the internally
collinear 1/s34 period. Positive denominators now require the shared original
prescription certificate plus a nonempty initial Euler convergence domain.

PreparePairMeasurementRecoilIntegration connects actual four-particle masters
to the existing two-body angular solver. It derives the recoil frame and keeps
propagator descriptors through the momentum change so the common prescription
proof still sees physical momenta. Converting these prematurely to anonymous
polynomials caused one rejected attempt; no proof was bypassed. Actual entries4
and13 have their recoil angles integrated exactly in21.131s, leaving two tagged
energy integrations. Their records are RecoilAngularIntegral4.wl and13.wl. These
are intermediate representations, not solved master values.

IdenticalQuarks reduction is running in DifferentialEquationsWithReuse with
429 verified extra equations. Its initial native reconstruction of74402 functions
completed in506.069s of backend time; the full supervised stage is still running
and this is not its total timing. Remaining native dependencies are being closed.
The owner state is ReductionWithReuseState.json; dynamic CPU affinity reserves
CPU7 only while the second main Wolfram kernel is active and restores all eight
otherwise. Preserve this job and inspect its actual state before further launches.


Latest continuation: see [physical coefficients and current RR status](NLOEECPhysicalCoefficients.md).
