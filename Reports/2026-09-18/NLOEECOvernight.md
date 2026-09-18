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
