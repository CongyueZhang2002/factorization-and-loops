## Complete NLO qqprime campaign (2026-09-08)

The general card-driven workflow now produces complete UU and double-incoming
LL/TT NLO hard functions for single-inclusive qqprime -> observed q + X, including
real, virtual, UV, both PDF and observed FF contributions. Final explicit
Mathematica files contain no unevaluated integrals. TT is exactly zero from all
generated distinct-flavor traces; an independently generated same-flavor TT Born
control is nonzero. Full fresh generation and all 53 external checks pass:
17 exact LL coefficient identities against the supplied Mathematica reference,
32 UU comparisons against original INCNLO across eight points/scales/flavor counts,
and four TT checks. All distribution poles cancel exactly. No reference values
enter production. See [the process README](ppHX_NLO_qqprime/README.md).

End-to-end regeneration, including kernel startup, amplitudes, Kira reduction,
finite-field coefficients and analytic assembly: UU 219.41 s, LL 233.27 s, TT 41.87 s,
measured by the external monotonic timer. Final assembly uses declared required
contributions, contiguous epsilon coefficients and explicit distribution fields;
it rejects unresolved integrals and residual regulators. Custom finite schemes
retain all declared nonnegative logarithmic plus orders, beyond the usual 0 and 1.
The package has 165 registered sources; retained focused coverage: 290 assertions
across 21 files, all passing. Verified outgoing GPT-6 Pro reviews are retained in
External/ChatGPT/Records/2026-09-08. No subagents were used.

The NNLO bare double-real result now also has an exact compact color-resolved
file: 104,939,642 bytes vs 317,049,147 bytes, a 66.90% reduction, with no new generator.
It retains all domains, exclusions, branches and required finite definitions.
Fresh loading takes 22.96 s vs 71.61 s; every retained definition, full output and
metadata passed independent exact comparison after serialization. The final
endpoint driver uses this storage form by default after color collection.
[Storage details](ppHX_NNLO_DoubleReal/Results/Validation/Stage4Optimization/README.md).
This remains the bare double-real NNLO contribution; its domain exclusions and
separate incomplete stage-3 reference inventory below are unchanged.

## Stage 4 performance and saved epsilon-order audits (2026-09-08)

The general coefficient-expansion path now extracts epsilon coefficients before
restoring the large kinematic coefficient field. Independent coefficient jobs
can use 1–8 owned subkernels, with remainder audits propagated to each worker.
Per-coefficient checkpoint writes are disabled by default. A full 345-master,
2,220-coefficient interior run took 257.06 seconds including source loading,
excluding final output serialization.

Late color collection preserves color-independent shared references and supports
1–8 workers. The full eight-worker collection took 455.37 seconds versus the
previous 644 seconds, excluding loading. Its full output comparison passes
(29 structurally identical groups and one numerical comparison at generic
rational factor/kinematic values). Epsilon-dependent or endpoint-dependent
extracted factors are rejected.

The saved-order drivers are complete. The current stage-4 order audit passes
all 345 masters and 92 endpoint contributions in 0.053 seconds after loading.
The stage-3 order audit passes all 33 boundary inputs / 565 requested amplitude
coefficients in 0.102 seconds. A deliberate shortened boundary cutoff fails
with the expected omitted-coefficient contamination. These are order audits;
the separate independent boundary-value reference coverage remains incomplete.

The mathematical review was sent to verified GPT-6 Pro (outgoing
`gpt-6-pro`, HTTP 200), and retained in
[the Pro review](External/ChatGPT/Records/2026-09-08/01_stage4_color_and_epsilon_orders.md).
Performance details, scope and verification are recorded in
[Stage4Optimization](ppHX_NNLO_DoubleReal/Results/Validation/Stage4Optimization/README.md).
The overnight campaign and cleanup are complete; its heartbeat is paused.

# Status, 2026-09-07

The general production path is a closed differential system, sufficient epsilon
orders, an explicit finite solution up to initial constants, and numerical
evaluation after those constants are supplied. Full epsilon-form
canonicalization is optional.

## Implemented and stored

- The general constructor and order planner accept process and family input
  data. They write actual finite coefficient expressions and scalar integral
  definitions, with explicit dependence on kinematics-independent constants.
- The latest all-family run contains 91 closed DEs and 91 finite solutions for
  345 requested masters and 2,220 coefficients, covering the current
  coefficient-table demands. After singular-boundary matching, the family files and shared finite definitions use zero unknown boundary series after physical whole-domain and collinear coefficient determination. All 2,220 requested coefficients have explicit physical boundary data.
- That run took 31.2 minutes elapsed on eight cores, including recovery from
  failed attempts. This is the raw-DE and finite-solution run; it does not
  measure complete strict epsilon-form canonicalization.
- An optional general converter stores explicit GPL expressions and evaluates them
  through GiNaC. Complete rationalizing coordinate changes preserve root branches
  and boundary normalization. [Measured comparisons](Design/GPLImplementation_2026-09-06.md)
  support selective use; FLINT remains the automatic default.
- Standalone Wolfram and compiled FLINT evaluators read the saved expressions.
  Parallel batches and optional explicit local Taylor expansions are available.

[Production commands](Scripts/Transport/README.md),
[solution format](Design/FiniteMasterIntegralSolutions.md), and
[the full-run record](Design/Stage1And2FullCampaign_2026-09-06.md) define the
interfaces, artifact locations and measured scope.

## Validation and remaining work

Optional labelled epsilon-remainder checks now protect the instrumented
stage-2 recurrence and basis products, stage-3 boundary reductions/matching,
and stage-4 coefficient and endpoint-distribution convolutions. Deliberately
shortened expansions are rejected in all three stages. All 91 saved DE
solutions pass their separate order-coverage audit in 20.36 seconds of checking
(excluding loading), with no new integral evaluations. Exact zero identities
resolve nine initial alarms from unsimplified source coefficients. Known
boundary amplitudes now expand deeply enough for epsilon poles in the matching
matrix; the `(1+epsilon)/epsilon` regression retains its finite term. This does
not affect the stored singular matching snapshot, whose sole known amplitude
has no pole in its matching column. It does not imply regeneration or full
retrospective checking of stage-3/4 artifacts.
[Usage and limits](Design/EpsilonRemainderChecks.md).

The complete physical-master validation now **passes all 91 families, 345
requested masters and 2,220 coefficients** at v=1/4,w=1/5 against independent
AMFlow references. The final aggregate is complete, including CF20/CF21/CF23
replacement comparisons; no unfinished master checks remain. The separate
stage-3 reference inventory remains incomplete.

Further general DE optimizations preserve native complex-ball uncertainty
between steps and remember successful Taylor step sizes. Hard-family pilots
passed all 88 master coefficients and 509 boundary coefficients, with roughly
8-9 times less DE evaluation time. Final-code timings and provenance are in
ppHX_NNLO_DoubleReal/Results/Validation/FullValidation_2026-09-07/DEEvaluationOptimization.
The authorized double-real assembly phase has resolved its input identities:
the CF56/CF57 dotted-master entries are exactly zero, and all 27 ghost masters
map to the validated basis (26 cut relabelings and one exact overlap relation).
The combined physical coefficient density contains 345 masters and 375 terms,
with the two finite Laurent truncations preserved. The measure conversion,
hadronic flux and incoming color average are explicit; the source already
includes the incoming spin average. No observed-variable Jacobian is assumed.
The compressed physical table is about 40 MB in
ppHX_NNLO_DoubleReal/Results/Assembly/Stage4_2026-09-07.

The general symbolic tangential endpoint construction and physical seed
matching pass full CF198 and CF300 pilots. All 91 symbolic endpoint systems now have accepted physical matching and
uniform primary Laurent bounds. The scalar coefficient projection uses c^T T before
determining normal depth; separate primary-sector bounds retain epsilon poles
which could cancel between regulated powers. Distribution-specific order
planning and full finite interior assembly are implemented and being applied.
The full finite interior density is now stored in the self-contained
147.51 MiB FiniteMasterIntegralDensity.wxf: 345 masters, 2,220 requested
coefficients, and zero unknown boundary constants. Every convolution row and
density coefficient was independently reconstructed from the exported indices.
The only serialization difference was the internal representation of sparse
matrix arrays; their dimensions and every mathematical row agree exactly.
Retained independent references confirm cancellation of the epsilon^-5
coefficient; epsilon^-7 and epsilon^-6 are structurally zero.

All 345 coefficient contributions now have explicit physical endpoint
solutions: 84 complete ordinary-family results plus eight complementary
pieces for the remaining seven families. The final merger verifies complete
master coverage and restores every separated coefficient pole exactly once.
Four missing boundary coefficients were evaluated: inputs 26, 27 and 28
through epsilon^1, and Euler input 3 through epsilon^2. All previous overlap
orders agree exactly. There are zero unknown boundary constants.

Both moving reduction divisors have exact source-wise residue proofs, each
covering 183 source rows and 2,379 coefficients. Their complete supports embed
in the existing CF230 and CF231 systems; inverse-gauge residue relations
annihilate all 13 and 23 columns. Exact FLINT cancellation removes the moving
divisors from the complete common coefficient rows. The audit of all 15,246
denominator bases leaves no unknown coalescing factor after removing these
two poles. Analytic normalization factors are treated as coefficient-field
units with their actual endpoint values preserved.

The general native rational-series implementation expands a whole requested
normal range once, retaining all symbolic parameters. The last four endpoint
continuations took 47-68 seconds each from saved order plans and normal jets.
These are continuation times, not full family regeneration times.

The full bare double-real distribution result is stored in
ppHX_NNLO_DoubleReal/Results/Assembly/Stage4_2026-09-07/BareDoubleRealDistributions.wxf
(317,049,147 bytes, about 302.36 MiB). Its strict binary round trip passed.
It contains ten color components, all proportional to alpha_s^4, together
with the unchanged full expressions and shared definitions. Color collection
took 644 seconds, excluding reading/writing. It contains explicit delta,
plus and full F-S regular coefficients through
epsilon^0, 345 masters, and zero unknown constants. Shared definitions contain
91,352 algebraic expressions, 53,959 integrals and 510,733 kernels. Distribution
assembly took 285 seconds, excluding earlier construction and input loading.

This is currently an unreduced distribution basis: epsilon orders -8..0,
five delta-derivative records and 36 generalized plus records. All 92 endpoint
contributions evaluate at v=1/4 without DE transport. Their summed higher
endpoint powers, delta derivatives, excessive logarithms and poles cancel
numerically beyond 60 digits. No symbolic coefficient was removed on that
one-point evidence. Simplification to the familiar minimal basis is separate
from the validity of the stored generalized-distribution expression.

The domain retains explicit exclusions v=1/3,1/2,2/3,3/4 until removability is
proved, with continuation from v=1/4 and the stated physical branch. The
single-threshold distribution is defined on [0,1-v) for smooth test functions
with support away from the upper endpoint. It is the current ud -> udgg
double-real contribution including ghost subtraction, not a full finite NNLO
hard function.

Focused checks passed: endpoint orders 18; native rational arithmetic and
analytic coefficient fields 10; normal rational series 4; scalar projection
23; final merger 20; coefficient pole decomposition 9; color collection 4;
scalar driver 9; base-point evaluation 3. The package layout audit reports
152 registered sources and no errors. Full-master AMFlow validation remains
the completed 345-master, 2,220-coefficient comparison above.

General production commands are in Scripts/Coefficients/README.md. The exact
coefficient-pole method is documented in Design/CoefficientPoleCancellation.md.
The authorized scope remains Design/DistributionAssemblyPlan_2026-09-07.md.


Further reference optimization selects combined Kira master discovery for one-thread jobs: fresh native references fell from 369 to 171 s (CF308) and 612 to 403 s (CF311), with all 42 exported coefficients agreeing at 20 digits. Completed auxiliary systems are now reusable under exact input/output checks; a five-system restart passed in 64 s. See ppHX_NNLO_DoubleReal/Results/Validation/FullValidation_2026-09-07/FurtherAMFlowOptimization/README.md. Existing long Mathematica jobs were retained after an actual sample timing showed little or no remaining restart benefit.

The independent AMFlow reference driver now automatically selects a matching native C++ build. Three complete reference pilots (77 exported coefficients) agree at 20 digits, with numerical AMFlow phases 2.70–3.13 times faster. Five regenerated native boundary-order arrays match Mathematica exactly. Newly assigned reference jobs use the native backend; healthy running jobs and accepted references are retained. Details: ppHX_NNLO_DoubleReal/Results/Validation/FullValidation_2026-09-07/NativeAMFlowOptimization_2026-09-07.md.

All 91 stored solutions passed the explicit-result and requested-order audit.
CF269 and CF259 agree with independent AMFlow local-series DE calculations at
a tolerance of 10^-30 using supplied test constants. The earlier CF3 zero exports predate the AMFlow order correction and are not
accepted physical validation. CF198 now passes a nonzero physical AMFlow
comparison through epsilon^1 at v=1/4,w=1/5 (tolerance 10^-18).
The numerical evaluator now has complete 91-family physical validation at the
stated point and stored epsilon orders; general analytic continuation remains separate.

Singular-boundary matching is now symbolically applied to every family.
Its numerical evaluator now uses Frobenius initialization and compiled Taylor
continuation. Two matching-point calculations agree for 1,038 original
coefficients of the full 346-component system. Demand-driven checks also pass
for CF123, CF269 and CF300, including the reduced boundary coordinates.
A nonzero physical CF198 master agrees with an independent exact finite-angle
hypergeometric expression through epsilon^1 at v=1/4,w=1/5. The AMFlow discrepancy is resolved: both interfaces now translate the desired
upper epsilon power to the vendor expansion order measured from -2 L. The
corrected 25-digit AMFlow run agrees with the physical DE and the independent
hypergeometric expression. See [the correction and reproducible comparison](
ppHX_NNLO_DoubleReal/Results/Validation/AMFlowCF198_2026-09-07/README.md).

General continuation and the complete
endpoint/renormalization/PDF-factorization epsilon demands remain work. Ordinary-point solutions up to constants do not
complete these steps. [The current roadmap](Goals/README.md) separates these
remaining general interfaces from process data.

## Boundary reduction

The [general boundary reduction](Design/GlobalBoundaryReduction_2026-09-06.md)
now rewrites all 91 finite solutions in a shared basis. Exact cut-integral maps
and seven relations from overlapping DEs reduce 1,561 family-local positions
to a 348-integral spanning system. The requested masters have an exact
346-dimensional derivative closure.

The saved expressions now contain explicit singular-boundary substitutions:
**zero unknown Frobenius amplitude series and zero undetermined requested coefficients**, down
from 345 shared ordinary-point series and 2,192 coefficients (originally
1,556 family-local series and 8,811 coefficients). The phase-space volume fixes one additional amplitude. The complete slope -2 component is fixed by whole-domain coefficient
matching, exact integral identities and three evaluated Euler integrals.
One is known through epsilon squared and two through epsilon. The original
83-series, 565-coefficient representation remains as provenance; elimination
preserves its Laurent lower bounds. All three slope -3 directions and the zero
mode are also fixed. All 32 slope -4 directions are fixed by complete double-collinear coefficients:
Gamma formulas, classical-polylogarithm/digamma coefficients and one two-dimensional
Euler integral. Physical completeness follows from full-integral bounds,
including energy endpoints and angular complements.
Affected transport orders were extended
in 52 families using eight subkernels.

A [uniform recoil-mass scaling bound](Design/ThreeParticlePhaseSpaceBoundaryScaling.md),
symbolic residue analysis and differential observation tests prove an upper
bound of **83 unknown physical boundary series** for the requested system.
The bound is now implemented by
[explicit singular-boundary matching](Design/ExplicitSingularBoundaryMatching_2026-09-07.md).
All 91 resolved files pass format and coefficient-requirement checks; the
general campaign driver reproduces the result. The adopted computation evaluated four non-elementary Euler integral series;
other inputs have explicit Gamma or polylogarithmic formulas. This does not
claim a minimal transcendental-constant basis.

The ongoing overnight work adds reusable physical boundary constructors,
Gamma/Beta and SubTropica/HyperFLINT integration, sufficient-order propagation
and finite coefficient substitution. The current constructor handles
three-particle cuts with unit powers or one doubled cut, coalescing null
external directions, exact eikonal factors and at most two distinct final-state
pair invariants. It constructs all 346 whole-domain leading coefficients.
The single mass derivative includes the moving-domain proof. The collinear constructors and general amplitude driver now determine all
required boundary amplitudes for the stored orders.

Current results are in
[OvernightEvaluation_2026-09-07](ppHX_NNLO_DoubleReal/Results/BoundaryValues/OvernightEvaluation_2026-09-07);
the original singular-matching results and validation are in
[SingularMatching_2026-09-07](ppHX_NNLO_DoubleReal/Results/BoundaryValues/SingularMatching_2026-09-07/README.md), with earlier global-system records in GlobalReduction_2026-09-06.

The normal reader/evaluator automatically uses Frobenius boundary initialization;
no supplied constants are needed. CF198 and CF300 pass, automatically increasing
precision from 80 to 160 digits. The final shared boundary file is 11.36 MB.
See [the completed report](Design/PhysicalBoundaryResults_2026-09-07.md) for the
general driver, mathematical scope, timings and remaining limitations.

## Repository organization

[The repository guide](README.md) distinguishes active code, process inputs,
upstream workspaces, tests and historical material. Persistent results now live
inside their process folder, including reconstruction and numerical references;
Kira uses <process>/Kira. Codex holds consultation state only. Old route drivers are
preserved in Archive/RetiredCode/FeynFacet; superseded plans and correspondence
are in Archive/History. Neither is a production dependency. The former
Exchange, Prototypes and Runtime directories have been removed.

The earlier data-cleanup passes removed obsolete output while retaining the current
DE/solution artifacts, reduction inputs and numerical reference data:
[DE-result removal](Design/StaleDEResultRemoval_2026-09-06.md) and
[repository consolidation](Design/RepositoryConsolidation_2026-09-06.md).
Earlier chronological status entries are preserved as
[history](Archive/STATUS_before_repository_cleanup_2026-09-06.md).

Result ownership, stale-file removal and validation are recorded in
[the result-organization report](Design/ResultOrganization_2026-09-06.md).

Completed coefficient intermediates and coefficient Kira workspaces have now
also been removed. All 347 main NNLO UU coefficients are consolidated into a
38.5 MB self-contained file; 345 are exact and two retain their completed
Laurent expansions through epsilon^5. See
[final coefficient storage](Design/FinalCoefficientResults.md) and
[the deletion record](ppHX_NNLO_DoubleReal/Results/Validation/FinalCoefficientRetention_2026-09-06/deletions.json).

The package is reorganized by mathematical ownership. Algebraic fields,
coordinate geometry, DE transformations, local analysis, physical boundary
matching, finite solutions and numerical evaluation now have separate homes.
Epsilon-form code is explicitly optional, and the standalone reader loads
without FeynCalc. See [the package guide](FeynFacet/README.md).

## Separate boundary and complete-master validation

The general drivers in Scripts/Validation separate stage-3 integral evaluation
from comparisons of complete physical master integrals with AMFlow. The
inventories contain 33 boundary inputs/157 coefficients and 345 requested
masters/2,220 coefficients. Missing references, absent orders and unselected
masters are explicitly incomplete. Demonstrations and exact commands are in
[TwoLevelValidation_2026-09-07](ppHX_NNLO_DoubleReal/Results/Validation/TwoLevelValidation_2026-09-07/README.md).
The full run was subsequently authorized and launched with eight cores.
Its live state and separate boundary/master coverage are in
[FullValidation_2026-09-07](ppHX_NNLO_DoubleReal/Results/Validation/FullValidation_2026-09-07/README.md).
The complete-master inventory now passes in full; missing boundary references
still prevent a complete separate stage-3 validation claim.

The stage-3 demonstration exposed and fixed a general Beta-to-SubTropica
fallback bug: Return inside Do did not leave the surrounding function. An
explicit tagged exit now reaches the fallback. Four reevaluated boundary
inputs (17 coefficients) pass independent Euler comparisons; CF198 passes
seven stored coefficients in the complete-master driver. These are demonstrations,
not complete validation of either inventory.


The full physical-master audit now uses a dynamic pool of eight families on
eight cores. A concurrent first-use race in FLINT 3.0.1's complex-ball method
table was fixed by serial initialization before OpenMP. CF12 and CF18 now
pass all 21 masters/138 coefficients against retained AMFlow references.
The family runtime also passes full concurrent CF198/CF199 comparisons
(13 masters/82 coefficients). One licensed main kernel controls eight fresh
family subkernels; AMFlow's generated Wolfram scripts run inside their existing
worker. General drivers support --workers 8 --resume and preserve full order
coverage. See the live FullValidation_2026-09-07 report; the complete audit is
complete and passing; separate stage-3 reference coverage remains incomplete.


The validation follow-up found and repaired an additional precision-setting
stall: a generic script scope must not start with unlimited extra precision.
The master evaluator now bounds inherited extra precision while preserving
its explicit working-precision and accuracy controls. CF20, CF21 and CF23
pass all 25 masters/169 coefficients against their retained AMFlow references;
their repaired DE evaluations took 45.25, 35.43 and 35.56 seconds. The completed
pool aggregate has been reconciled with these accepted replacement reports.

Full master validation has passed. The user has authorized the general
double-real assembly and endpoint/distribution work in
[DistributionAssemblyPlan_2026-09-07](Design/DistributionAssemblyPlan_2026-09-07.md).
The follow-up automation remains paused. The user resumed steps 1-4 directly,
without subagents.
