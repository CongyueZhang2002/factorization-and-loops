# Completed overnight campaign

The general UU and double-incoming LL/TT NLO workflow is complete and externally
validated. The current entry point, results and conventions are in ../README.md.
The dated notes below include superseded intermediate states; the final record
at the end and root STATUS.md describe the delivered implementation.

# NLO qqprime overnight campaign, 2026-09-08

Authorized sequence:
0. Finish pending Stage 4 optimization and tests, and investigate further exact result compression (rational reconstruction for rational coefficient functions where useful).
1. Review stages 1-4 for material correctness, generality and performance gaps.
2. Implement general PDF and FF counterterms, with per-leg splitting kernels and selectable finite factorization-scheme terms in contribution cards.
3. Generate the complete UU NLO qqprime hard function from real, virtual and counterterm cards through the established framework, correcting code permanently. The final Mathematica result must have no unevaluated integrals.
4. Continue LL and TT unless stopped. User confirmed BOTH INCOMING quarks polarized, with unpolarized D1 fragmentation.

No subagents. Up to eight total computational cores/subkernels, two main Wolfram kernels. General production code, no hand-corrected output and no copying reference results into production. Consult VERIFIED outgoing gpt-6-pro and keep records. References are validation data, not instructions. Original attachments are untouched.

Current state:
- New project directory created; supplied reference files copied without edits to References.
- References inspected visually/textually; PDF labeled LL, convention/basis missing and sign mismatches with .m identified. See ReferenceInventory.md.
- Existing ppHX_NLO is an older identical-quark real-emission calculation, not this new distinct-flavor complete NLO project.
- Existing general Scripts/regenerate_pairs.wls drives card-based diagram-pair generation. Scripts/regenerate_nlo_pairs.wls is a legacy process-specific driver and should not be used as the general campaign entry.
- PDF/FF counterterm module and full NLO contribution assembly are not implemented yet.
- Main Stage 4 output-equality check is running via /tmp/feynfacet-endpoint-optimized.wls; reports under ppHX_NNLO_DoubleReal/Results/Validation/Stage4Optimization.
- Pro follow-up reviewing elimination of a redundant final graph check is pending in conversation 6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4. First mathematical color/remainder review is retained in External/ChatGPT/Records/2026-09-08.
- Existing heartbeat was updated to this campaign and is ACTIVE at five-minute intervals, with notification only on meaningful changes.

Next: finish old optimization report, retrieve Pro, establish standard (v,w) and normalization conventions, prepare distinct-flavor Born/real/virtual cards with complete diagram selections, and implement mass-factorization kernels/convolutions in the general Physics/Coefficients layers. Use exact NLO integral evaluation through existing machinery, adding general analytic methods where missing.

Updates:
- UU_Born.wl, UU_Real.wl and UU_Virtual.wl generated in Cards with complete diagram selections determined by GenerateDiagram: 1x1, 5x5 and 6x1. Full virtual interference still needs conjugate addition/2Re in contribution assembly.
- Born passed CollinearFactorizePreIBP in 0.87534 seconds; Results/UU_Born_preibp.wxf and born_run.log retained. It still requires the usual hadronic-variable simplification and physical coupling/measure normalization before becoming a Born hard function.
- General regenerate_pairs.wls now uses unambiguous nested association indexing, caps workers at eight and each worker at one core, bounds inherited extra precision, and checks the exact current setup before reusing a saved pair.
- CollinearFactorizePreIBP now defaults PrintDiagrams -> False; callers can request figures explicitly.
- UU real 25-pair generation is running through Scripts/regenerate_pairs.wls with 7 workers (one core concurrently used by the prior Stage4 grammar measurement). Log Results/real_pairs.log; verify actual process before resume.
- The Stage4 full output comparison passes exactly (217.61 s vs 268.66 s), but Pro found a held-evaluation counterexample to the graph shortcut. A reference-preserving mathematical-head grammar now selects the shortcut; other inputs use the old full final check. Two Pro counterexamples are tests. Measuring grammar cost/coverage on full output is pending; GPL head FeynFacetSolution G was added to the safe mathematical heads.
- Verified GPT-6 Pro is now reviewing the NLO counterterm interface and TT helicity selection, same conversation. Prompt Codex/General/ChatGPT/pending_nlo_counterterms_prompt.md, verified outgoing gpt-6-pro HTTP200 requestMessageId 3e516547-12f5-4f34-9612-7ecb126cd710.
- Sources: hep-ph/0211007 Eq.20-23 defines subtraction Hqq and Delta fqq=-4CF(1-x) for BMHV helicity restoration; Eq.24 defines the A0/B0/... basis. Eq.9 of hep-ph/0506315 lists nonzero TT channels and excludes distinct incoming qqprime.

Further fixes:
- Initial real pair run failed all 25 pairs because the package reorganization left $feynFacetSourceHash uninitialized; analyticContextQ correctly rejected all topology records. Kernel/Loader.wl now computes the existing required source provenance once during loading. Reproducing one failed pair now gives ContextValid, TopologyValid and RecordValid all True.
- The general pair driver now exits nonzero if any pair fails and closes its owned kernels. Retry log: Results/real_pairs_retry.log.
- Stage4 mathematical-head grammar additionally admits the existing GPL G head and elementary inverse hyperbolic functions. A full-data grammar measurement remains running via /tmp/feynfacet-closure-grammar.wls.
- Main NLO counterterm Pro review is pending; do not treat the previous closure-review response as this new review.

Latest:
- Real retry completed 25/25 pre-IBP pairs with no failures. Canonicalization + Kira streaming reduction is running via Scripts/canonicalize_and_stream.wls ppHX_NLO_qqprime UU_Real UU_RealReduced solve; log Results/real_reduction.log. Default Kira limit is 8, so do not launch a competing 8-core virtual pool.
- Full Stage4 mathematical-head grammar now accepts all actual definitions, with 8.914374 s cost. The earlier 217.61 s full equality comparison preceded this grammar guard; report its added cost separately unless doing a final timing. Regression test count now 159 (25 endpoint-subtraction assertions).
- Need a small loader/provenance regression test and general pair-driver tests after fixes.
- Next virtual run: same general regenerate_pairs.wls, UU_Virtual, six forward one-loop diagrams against Born. Full hard contribution must add conjugate interference; no factor of 2 assumed before taking its real part.

Counterterm concern to establish with Pro and primary source:
For the observed outgoing q in distinct incoming qqprime, initial leg B may have a g<-qprime mixing term multiplying the Born qg->qg hard function (the final qprime becomes beam-collinear). Initial leg A has no corresponding Born g qprime -> observed q channel by flavor conservation; final observed-q FF mixing should be checked similarly. Thus a complete counterterm campaign may need an additional generated qg Born card, not just qqprime Born. The current Physics/CollinearFactorization.wl densityHead supports hadron-associated quarks/antiquarks only; if the qg Born is needed, general U/L gluon PDF projectors must be added rather than importing a hand-written qg Born formula. This is a likely substantive missing part of the general framework.

Primary sources read:
- https://arxiv.org/pdf/hep-ph/0211007, Jager et al., Phys Rev D67 054005. Eq.17 angular Beta*2F1 master; Eqs.18-19 endpoint distributions; Eq.20 incoming counterterm convolution; Eq.21 MSbar plus finite kernel; Eq.23 BMHV helicity-restoring Delta fqq=-4CF(1-x); Eq.24 full coefficient basis; v=1+t/s, w=-u/(s+t).
- https://arxiv.org/pdf/hep-ph/0506315, Mukherjee et al., Phys Rev D72 034011. Eq.9 lists nonzero TT channels, excluding distinct incoming qqprime; Eq.10 presents delta/plus/log basis.
- Aversa et al. Nucl Phys B327 (1989) 105, doi:10.1016/0550-3213(89)90288-5, INSPIRE record267909 and CERN CDS194997. Full unpolarized paper not yet obtained/read.

Current completion update:
- Real reduction finished: eight families, 77 targets, 71 rules, six masters. CoefficientResult.wl is 0.23 MB, generated in 26.6 s; finite-field reconstruction was 0.07 s.
- Virtual generation passed all six pairs.
- General DE builder now handles any positive loop count (same three-external-momentum geometry); 16/16 regression assertions pass. CF1 real one-loop DE closes in 5.79 s.
- Source provenance initialization now belongs to FeynFacet/FeynFacet.m, not standalone Kernel/Loader.wl.
- Pro reviews 02 and 03 are complete and retained. Counterterm review confirms necessary qg Born mixing, exact D-dimensional FF Jacobian, and scheme-conditional TT zero trace selection.
- Stage4 endpoint mathematical output comparison passes exactly; guarded grammar costs an additional 8.91 s, current regression count 159. Earlier running/pending entries above are historical.

2026-09-08 continued implementation (authoritative update):
- CRITICAL: six virtual topologies contain ELEVEN inserted graphs. Earlier six-pair virtual generation/reduction was INCOMPLETE. CountProcessDiagrams and CompleteProcessDiagramSelection now count deepest inserted FeynmanGraph nodes, not topology containers. Both UU and LL virtual cards select 1..11. Born/real/qg counts remain 1/5/3 on each tree side.
- An explicit SMQCD massless-flavor adapter preserves closed generation sums that FCFAConvert DropSumOver otherwise loses. New card declaration MasslessQuarkFlavors -> <|UpType->nU,DownType->nD|>; total active flavor count is nU+nD. It zeroes declared degenerate masses and replaces each scalar generation sum by its declared multiplicity. It rejects undeclared or residual generation dependence.
- Full eleven-pair UU virtual run is currently via Scripts/regenerate_pairs.wls, log virtual_pairs_full_flavors.log; inspect actual process/outcome before resuming. Do not use earlier UU_VirtualReduced five-master output as complete virtual physics.
- Virtual kinematics: eliminated declared massless recoil retains its on-shell relation outside the support delta. All family bases now include the independent process external momenta, with explicit missing scalar-product ISPs before FeynCalc completion (which otherwise ignores unused declared vectors). A first triangle pilot passes. Chained scalar-product rules are resolved into Kira invariant symbols. The old six-pair partial reduction completed in 23.82 s after these fixes.
- Canonicalization now by default retains separate identity-verified families when a common characteristic polynomial does not yield a verified equivalence. Unverified equivalence rules remain rejected. AllowCollisions -> False remains available for stricter campaigns; a candidate polynomial equality is not an identity proof.
- General Born driver Scripts/generate_born_density.wls and Physics/Born.wl produce invariant b_D multiplying delta(s+t+u), with explicit flux, observed measure, color average and removal of correlator fractions. UU/LL qqprime and qg Born results are written, without numerical integration. The gluon helicity sign was corrected to -i epsilon^{mu nu k n}/(2 k.n), independently confirmed by Pro review04. Need retained four-dimensional Born fixtures and splitting/projector check.
- Physics/Counterterms.wl now provides LO U/L/T kernels with explicit daughter<-parent species and MSbar/HelicityMSbar or explicit finite kernels, and exact PDFa/PDFb/FF convolution maps acting on invariant Born densities. Eighteen tests pass (0.5 s), including momentum sum rules and nonlinear plus-pullback test functions. Full counterterm construction/epsilon expansion and contribution-card assembly remain.
- All six real-family DEs are saved as .wl. The builder writes WL text even when given .wxf; the newly made misleading suffixes were corrected (no lost mathematical data). All associated master definitions and representations are genuine .wxf.
- Integrals/Evaluations/PhaseSpace.wl now recognizes two-body lightlike angular integrals from arbitrary propagator/cut geometry and returns exact Beta/Gauss functions. Symbolic kinematic positivity conditions are propagated to definitions. All six real families have explicit representations and pass both DE matrices at two rational points, epsilon=-6/5, residual <1e-35. Existing check N[] chases exact zeros to its bounded extra precision; do not use unlimited precision or repeat this unnecessarily.
- Functions/Hypergeometric/Gauss.wl generates explicit finite GPL/log/polylog epsilon coefficients for the angular Gauss functions, including correct exact-coincidence dimensional continuation. Eight tests pass (0.1 s), including differential equation, endpoint Gamma value and finite-order numeric check. This is not yet assembled into the final real distribution.
- Verified GPT-6 Pro review04 is retained. It verifies angular normalization, two-by-two epsilon-form and the nonlinear plus pullback; it confirms the gluon helicity sign fix. It stresses keeping rho^(-1-eps) before endpoint expansion and the analytic complement from the hypergeometric connection formula. Exact rho=0 topology is NOT the rho->0 endpoint limit. Counterterm guards for smooth Born multiplier/nondegenerate slope still need strengthening.
- Current focused test counts: source-provenance/entrypoints 11; diagram/flavor 5; counterterms 18; Gauss 8; generalized DE builder 16. External-mass-shell test extended to five assertions and needs rerun. General scheduler/regression/layout checks still to run after final source edits.


## Analytic NLO assembly, 2026-09-08 (ongoing campaign)

- Restored `(2 Pi)^(-D LoopNumber)` in the general FeynArts converter. The normalized UU virtual regeneration completed: pairs 12.73 s, complete reduction 33.67 s, coefficients 23.35 s elapsed. The complete 11-diagram virtual set includes declared nU+nD flavor sums and excludes a homogeneously scaleless tadpole exactly.
- All five UU one-loop masters independently passed Package-X through epsilon^0 at s=1,t=-2/5,u=-3/5; bubbles needed through epsilon^1 for contraction. `one_loop_packagex_checks.wxf` and log retain this check. OneLoop.wl finite-order metadata now stores a contiguous requested lower range. Bubble epsilon^1 still should get an independent deeper check if needed; Gamma formula is exact.
- Generated all ten UU/LL PDF/FF/UV counterterms. General exact-D Born maps include both incoming legs, the FF epsilon Jacobian, the g<-qprime channel requiring qg Born, and BMHV helicity restoration for each incoming polarized quark.
- LL campaign completed: real reduction 53.07 s, real coefficients 29.76 s, virtual pairs 15.38 s, virtual reduction 32.54 s, virtual coefficients 23.39 s elapsed. Both incoming quarks polarized, observed fragmentation D1.
- Shared normalization now `PartonicInvariantDensityNormalization`; exact analytic contraction `ContractAnalyticMasterCoefficients` checks all master orders and supports the independent epsilon tail audit.
- `ConstructAnalyticEndpointExpansion` uses the noncoincident Gauss connection BEFORE epsilon expansion, expands the endpoint coefficient an extra order, and subtracts it from the FULL interior expression. The analytic complement is retained. Only one branch per scalar term, pole no deeper than z^-1; mixed powers, joint epsilon/endpoint denominators and unsupported endpoint functions fail. Interior denominator/base/Gauss-domain checks added and being retested. Domain assertions remain explicit in cards. Raw interior epsilon checks are explicitly limited to the interior; endpoint checks independently include the moment pole.
- Pro review 05 retained: `External/ChatGPT/Records/2026-09-08/05_nlo_endpoint_assembly.md`. Outgoing gpt-6-pro HTTP200, request 18780247-30c9-471e-9b14-031cd243546c. Pro confirms method, no extra delta from regular complement, and gives the -Pi^2/12 delta fixture. Tests/Coefficients/t_analytic_endpoint.wls passed 14/14 including this fixture, a deliberately shortened epsilon order, branch failures and positive-log/causal real-part checks. No Pro request pending.
- `ExpandPositiveLogarithms` and `RealPartOnPhysicalDomain` in Functions/Elementary/Logarithms.wl avoid minutes of ComplexExpand/FullSimplify branch expansion; physical real part now ~0.08 s. Gauss.wl moved to the common SolutionData profile so both symbolic and standalone entry points load it.
- General package `Coefficients/NLO.wl`: ConstructNLORealContribution, ConstructNLOVirtualContribution, ConstructZeroAmplitudeContribution, AssembleNLOHardFunction. Automatic master geometry, sufficient virtual orders, analytic endpoint distributions, and exact pole cancellation. No process/family branches. General driver prototype /tmp/feynfacet-nlo-general-assembly.wls regenerated both UU and LL successfully: real 2.5 s, virtual 1.7 s, sum 1.2-1.5 s each, excluding kernel load. It now needs permanent card-driven CLI consolidation.
- `UU_HardFunction.wl`, `LL_HardFunction.wl` under Results are explicit LO+NLO Mathematica expressions, exact pole cancellation in delta/plus/regular pieces. Finite external-reference comparison still PENDING: do not claim full validation yet. Older *_candidate.wl are owned exploratory files, removable after final retention; current accepted math not reference-injected. UU candidate ~11 KB, LL ~7.5 KB.
- General counterterm closure `EnumerateNLOCollinearChannels` added to Physics/Counterterms.wl; enumerates nonzero splitting/finite kernels and possible recoil species with quark-flavor conservation. `ConstructCollinearBornProcessCards` added to Physics/Born.wl to map abstract species to model particles, update quark/gluon distributions and discover all generated diagrams. These newest functions NEED tests and driver integration.
- TT cards use two independent incoming transverse vectors STavec,STbvec with azimuths phiA,phiB; no azimuth averaging. TT Born is exactly zero from the generated trace (0.51 s). TT real 25/25 and virtual 11/11 pairs completed. `ConstructZeroAmplitudeContribution` checked complete coverage and all exact-zero integrands; TT_RealContribution.wl and TT_VirtualContribution.wl generated. TT counterterms/final assembly pending. UV zero-Born handling was just added and needs tests.
- Noncoincident angular formulas with powers other than {1,1} now conservatively fall back to other representation methods until their contiguous reduction is verified; one-direction/coincident Beta moments remain general.

Outstanding: permanent one-card-per-contribution campaign CLI/configuration; verify automatic Born-channel closure; full retained Born/soft/RG/pole/multi-point/endpoint tests; external finite UU/LL comparison against provided Vogelsang references and correct conventions; TT counterterms and nonzero same-flavor trace control; exact support/finite-order rejection tests for new APIs. Finish earlier Stage4 report corrections/compression and package/regression audits. Only then clean owned scratch/intermediates. Do not retry the earlier rejected deletion of old Stage4 checkpoints. No subagents. Scientific concurrency <=8 and max2 main Wolfram kernels. Heartbeat remains active for the full overnight campaign.


### Permanent campaign and external finite validation completed

`Scripts/run_nlo_hard_function.wls PROJECT *_Campaign [all|assemble]` is now the
permanent general card-driven path. UU/LL/TT_Campaign cards are present. The
runner automatically enumerates collinear Born channels, generates complete
Born diagram selections and one card per PDF/FF/UV contribution, handles exact
zero amplitudes before reduction, derives analytic master orders and writes
LO+finite-NLO Mathematica associations. New output layout: Results/Born and
Results/Contributions/{UU,LL,TT}. Main final files remain Results/*_HardFunction.wl.

Assemble-mode campaign timings excluding kernel startup: UU20.15s, LL16.98s,
TT0.745s. UU/LL each use two Born channels and four collinear subtractions;
TT one Born channel and three collinear subtractions. TT zero was checked in
all25real and11virtual pairs, and a generated identical-flavor TT Born control
is nonzero, retained at Results/Validation/tt_identical_flavor_control.wxf.

All17 supplied Mathematica LL coefficients now match EXACTLY. The missing
basis header was recovered from Jager et al. hep-ph/0211007 Eq24 and verified:
EE logw + F logv + G log(1-v) + H log(1-w) + L(log(1-v)-log(1-vw))/(1-w)
+ M log(1-v+vw)/(1-w) + CC. Overall invariant-density multiplier
alpha_s^3/(8 CA^2 pi s^2); matched scale coefficients A0/B0/C0,A1/B1/C1,A2,
deltaA,plusB,leading-logDD and all seven regular coefficients. PDF signs differ;
original Mathematica file matches. Nothing was copied into production formulas.

UU independently checked against original INCNLO1.4. Unchanged archive and
hadlib/cdel source under References/INCNLO, official LAPTh source URL in SOURCE.md.
Original param.f fixes AL1; FICT sets CQ0; cdel documents JMAR0 as MSbar conversion.
Fortran wrapper includes the original finite scheme terms and moves w-dependent
plus multipliers into their endpoint coefficient plus regular difference.
Tests/Support/INCNLO/evaluate_reference.py compiles original sources in owned
scratch and retains only 8points x4 coefficients; all32 comparisons pass with
varied v,w,s,scales,nf. Combined external driver
Scripts/Validation/check_nlo_qqprime_references.wls passes53/53 in~5s.
Report: Results/Validation/NLOExternalReferences.wl.

18 framework regression files rerun:256PASS,0FAIL; logs+Report.json under
Results/Validation/FrameworkTests. New counterterm workflow tests11/11 include
scheme sign, scale derivative, UV coupling power, zeroBorn and automatic closure.
Finite scheme matrices are keyed by {daughter,parent,spin}; explicit flavor mixing
adds same-flavor TT Born channels. A per-channel bare kernel cannot silently apply
to every flavor during enumeration. PhaseSpace nonunit noncoincident angular
formula conservatively falls back until separately verified.

README.md documents workflow, actual result convention, matrices and checks.
Full timed ALL-mode regeneration, remaining API coverage checks and cleanup are
still pending. A Stage4 compression investigation is active separately.

Stage4 compression findings: already-compressed 317MB WXF, loads70s. Algebraic
pool91,352 expressions, 9.50GB ByteCount, only591raw duplicates; kernelpool510,733
records,0.946GB,18,404raw duplicates after dropping Index; integralpool53,959.
10colorcomponents7.41GB vs extra duplicate uncolored views multipleGB. New
CompactFiniteSolutionDefinitions in Solutions/SharedDefinitions performs exact
K/F/a topological deduplication without bound-variable renaming, then pruning.
Eight semantic tests pass. It is currently running on the actual data in an
interactive WolframKernel session; do not start additional full campaign processes
until that kernel is closed (max2main licenses).
Pro compaction review sent gpt-6-pro HTTP200, request35f5e509-6c2f-4830-84de-a25c292e0fdf;
response not yet retrieved. Source prompt Codex/General/ChatGPT/stage4_compaction_prompt.md.

### Exact Stage 4 storage compaction and final regeneration

Verified GPT-6 Pro review 06 is complete. Its semantic-scope warning was applied:
shared definitions cannot merge across different source path scopes. No bound
variable renaming; all defining fields compared; approximate values and
reference-bearing association keys rejected. The initial unscoped pilot is
explicitly exploratory, never accepted.

Accepted compact result: Assembly/Stage4_2026-09-07/
BareDoubleRealDistributions.compact.wxf in ppHX_NNLO_DoubleReal, 104,939,642bytes
versus original317,049,147. Actual compressed WXF in both cases. Retained counts:
K431261,F34618,a79757. Compaction157.38s, independent proof+packaging73.60s,
compressedexport32.34s. The first uncompressed1.96GB export was atomically replaced;
that was a format setting, not mathematical growth. A fresh kernel independently
checked the complete output, every retained source definition, all semantic
contexts and metadata: PASS. Source load71.61s, compactload22.96s, check104.94s.
General CLI Scripts/Coefficients/compact_distribution_result.wls supports compact
and verify modes; final endpoint assembly now uses the compact form by default
when colors are collected. No numerical integral evaluation in these checks.
Seventeen compaction tests pass, including serialization/domain/index mutations.
Seven analytic-contraction tests also pass. Entry points rechecked11/11; layout
165registered sources,0errors. The earlier nine-file regression report corrected
to159assertions. The FrameworkTests batch had256; with these two new files the
retained distinct framework coverage is280assertions across20files.

Rational cancellation pilot: a236800byte expression with46formal atoms reduced
to136544bytes in0.0185s. Other samples57–106atoms exceededpilot50cap. This was
not applied to production; no interpolation of correlated numerical integrals.
Current structural compression is the accepted67%reduction.

Interactive compaction kernel closed. Fresh final full UU/LL/TT regeneration
runs via the permanent card-driven all mode, sequentially, followed by all53
external checks. Monitor session55599 and Results/Validation/*_full_regeneration.log,
FullRegeneration.json. No subagents and max8scientificcores. The external check
now generates its nonzero same-flavor TT control on every run (permanent code).
Remaining: finish fullrun, targeted guard coverage, clean owned benchmark outputs
and NLO exploratory duplicates, update final STATUS/README and pause heartbeat.
Do not retry rejected old Stage4 coefficient-checkpoint deletion.

## Final delivered state

Full all-mode campaigns passed, measured by an external monotonic timer including
startup and all stages: UU 219.41 s, LL 233.27 s, TT 41.87 s. See
Results/Validation/FullRegeneration.json and *_Campaign/CampaignReport_all.wl.
Final general assembly now preserves every declared plus logarithm order from
custom finite schemes, retains all generated real-contribution pole orders,
requires complete explicit distribution fields and contiguous epsilon data,
and rejects residual regulators by SymbolName and unresolved finite integrals.
Ten focused assembly tests pass. A broad text replacement initially affected
the real-contribution iterator; the actual campaign check detected this before
changing a final hard function. Its scope was corrected and all actual real and
virtual contributions were regenerated and rechecked afterward.

Final assemble-mode campaigns pass with exactly unchanged explicit result files:
UU 20.75 s, LL 19.15 s, TT 3.41 s, including startup. All 53 external checks pass
again in 9.16 s, including fresh generation of the nonzero identical-flavor TT
control. The final .wl sizes are UU 10,876 bytes, LL 8,041 bytes and TT 1,119 bytes.
No unevaluated integrals or source reference formulas enter these results.
The retained framework report covers 290 passing assertions across 21 files;
five edited drivers parse, and package layout passes 165 sources with no errors.

Stage 4 compact output is independently verified after serialization, preserving
all source scopes and metadata. Its 104,939,642-byte file is 66.90% smaller than
the accepted 317,049,147-byte source. The final endpoint assembler now writes
this compact representation by default after color collection; a separate
compact/verify driver is available. The source remains retained for comparison.
Owned full benchmark duplicates and temporary maps removed: 380,906,128 bytes.
Owned NLO partial virtual reduction and exploratory duplicate outputs removed:
1,301,508 bytes. Small validation reports, final values and production dependencies
remain. No rejected old coefficient-checkpoint deletion was retried.

All six required GPT-6 Pro exchanges are retained. This campaign used no
subagents. The overnight heartbeat is paused on completion. Remaining NNLO scope
is explicitly recorded in STATUS.md: this is the bare double-real contribution,
with the original domain exclusions and separate stage-3 reference inventory;
it is not a claim of a complete NNLO hard function.
