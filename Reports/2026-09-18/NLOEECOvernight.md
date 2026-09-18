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
