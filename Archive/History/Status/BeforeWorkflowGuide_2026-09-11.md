# Historical status snapshot — not current instructions

This is the former chronological STATUS.md, preserved verbatim below. Its
relative links were written relative to the repository root. Current execution
directions are in WORKFLOW.md and the selected project/channel README.

# ppHX UU NNLO scoped regeneration and automatic planning complete — 2026-09-11

The regenerated two-gluon contribution with ghost subtraction is complete under
Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/Results/DoubleReal. The accepted result is
Assembly/Regeneration_2026-09-10/BareDoubleRealDistributions.wxf (76,125,796 bytes).
The user resumed the NNLO workflow after the recorded stop. The accepted
double-real artifact is preserved. Automatic derivation of the optimized
reconstruction plan from contribution-card dependencies is now complete and
tested against the accepted source. The subsequent eight-core coefficient
rerun also completed and passed: 80.20 minutes previously versus 10.49 minutes
now (7.64 times faster), including current-input verification and fresh native
reconstruction. All ten coefficient expressions match exactly and 60 modular
source comparisons pass. The common scheduler now resolves native threads
from OS CPU allocation independently of Wolfram kernel limits; one queue
passes its available budget to each pending job. Eleven focused assertions
pass. See Regeneration_2026-09-11/EightCoreReconstruction/README.md.
The accepted physics result remains preserved; no jobs remain running.
The existing heartbeat remains PAUSED. This is not all NNLO cuts or a complete
NNLO hard function.

All upstream work and coefficient reconstruction are complete:
- 666 direct gluon contractions, 1296 orientations, zero failures;
- 374 canonical families; 55,277 original reduction targets, 55,706 resolved
  integrals including dependencies, and 345 terminal masters;
- two missing cross-family reductions recovered by the general supplementary
  geometric-IBP path, preserving the original Kira database;
- 343 ordinary rational columns: 5385.33 s driver time on seven cores;
- two exact exceptional pieces: 202.9 s native job time on one core;
- two regular Laurent expansions through epsilon^1: 984.3 s and about 3913 s
  reported native-job time, each on one core. The regular driver reports
  4812.23 s elapsed; native and supervisor clocks differ slightly.

All 2,130 source-versus-reconstruction finite-field comparisons pass: three
points over each of two checked 63-bit primes. These are probabilistic identity
checks. Ghost definitions and their composed integral relations match the saved
physical master catalog.

The large columns are literal sums of a regular part and an exact exceptional
part. The regular tails have fixed normal pole bounds 6 and 4, physical master
lower bound 0 and one endpoint-distribution pole; epsilon^1 therefore suffices
through the finite distribution coefficient. Nine order assertions pass.
Moving divisors remain exact until cancellation of the complete coefficient row
in a common saved DE basis. The historical epsilon^5 choice is no longer a
default or used as an order proof.

General production code now connects scheduled rational and finite jobs to a
single exact/Laurent result assembly. Source content, definitions, normalization
and endpoint-order inputs are bound to the plan. Analytic signatures stay outside
finite Orders, and a zero known prefix retains its unknown tail. Unused legacy
per-order repair/merge code was removed.

The automatic endpoint catalog covers 91 accepted systems. Common-frame grouping
preserves fresh finite prefixes, recomputes exact pole pieces and normalized-row
cancellation, and validates emitted contribution ownership. Each input binds the
accepted endpoint, physical bounds, matching and coordinate records. Separate
contribution labels may use the same mathematical family without colliding.
GPT-6 Pro reviews 49–52 cover this construction and its integration checks.

Final-assembly profiling exposed unnecessary full multivariate Factor in the
physical-variable check: one actual two-million-leaf coefficient exceeded 45 s,
while exact FLINT cancellation took 1.807 s. The check now uses cancellation;
12 rational-arithmetic and 16 physical-variable assertions pass, including a
fixed shared imaginary-unit representation. Nine file-based assembly tests also
pass. The abandoned assembly attempt retained all completed reconstruction jobs.

Current regenerated coefficients are accepted: 343 nonzero master coefficients,
343 exact terms and two finite regular terms, 31,784,549 bytes. Two further
coefficients are identically zero; this is not a claim that their integrals
vanish. Gluon/ghost cut assembly and physical normalization pass exact read-back.
Automatic grouping produced all 92 owned contributions, with fresh exact moving
pole cancellation, in 929.48 s driver time.

The interior density is complete in 196.75 s driver time, with no unknown
constants and its epsilon-remainder audit passing. Stored leading zero master
orders are now distinguished from actual poles: only explicitly present exact
zeros may improve the lower bound; missing coefficients still fail.
All eight interior orders (-7 through 0, with -7 and -6 identically zero) pass
the retained AMFlow contraction comparison at (v,w)=(1/4,1/5), using 1,408
master coefficients from all 91 families. The check took 25.25 s, with a
relative tolerance of 10^-12; no fresh AMFlow solves were needed.

All 92 scalar endpoint contributions from 91 mathematical families completed,
with no missing orders, deferred jobs, unresolved classes or constants.
The campaign reports 595.483 s internally and 578.124 s supervisor elapsed.
The 80 nonempty singular endpoint contributions have actual passing epsilon
checks; 12 empty singular contributions report NoChecksExecuted and are recorded
separately. EndpointAuditInventory.json records each case.

Final distribution assembly completed in 524.512 s supervisor elapsed, with
exact read-back and definition-by-definition compaction checks passing.
Its epsilon range is -8 through 0, derived from the endpoint distributions
rather than the interior cutoff. Four color components retain delta derivatives
0 through 4 and generalized plus powers -5 through -1. There are no unknown
constants. The stated domain is 0<v<1/3, with smooth test functions at z=0 and
support away from w=0. The file stores explicit finite expressions and their
closed shared integral/kernel definitions, not a generator.

A wrong-context color request was corrected before acceptance. General color
collection now rejects same-name factors in different contexts; all 14 tests
pass. GPT-6 Pro acceptance review is recorded in
External/ChatGPT/Records/2026-09-11/01_double_real_acceptance.md. It confirms the
exact-leading-zero correction and the scope of the retained-reference check.

Automatic coefficient-plan preparation now selects expensive source columns by
size, derives physical normalization through the existing integral-definition
and physical-density routines, classifies denominator units with the shared
order proof, and partitions exceptional summands literally. Unsupported columns
stay exactly rational with a recorded reason. Explicit missing/invalid
dependencies fail. Contribution cards declare endpoint and normalization inputs
and their requested epsilon range, with no per-column selections or orders.

Final card-driven preparation took 109.395 s on one CPU; direct-request
preparation took 110.473 s. Both automatically selected outputs 20 and 22 and
derived epsilon^1. All four regular/exact files match the accepted partitions
byte-for-byte. The physical prefactor lower bound, active physical-sector
bound, nilpotency index and target are respectively 0, 0, 1 and 0.

GPT-6 Pro review 02 identified coordinate-composition, physical-frame,
saved-plan, per-master failure and empty-plan issues. All five were fixed.
Current physical normalization, endpoint records and source DEs are now bound
to saved-plan execution; unsupported per-master analysis remains exact, while
invalid declared inputs fail. The independent resolution and limitations are
in review-resolution record 03; no second Pro review is claimed.

Verification passed 25 automatic-planning, 12 physical-frame/coordinate,
11 order-bound and 10 mixed-assembly assertions, option forwarding, 14 Python
tests and all actual preparation comparisons. Native reconstruction and master
solving were not repeated because the accepted mathematical inputs, partitions
and sufficient orders agree. See Regeneration_2026-09-11/RunState.json and README.md.

Historical timings remain distinct: 3.4 h for the older rational-coefficient
reconstruction, plus 18.1 and 5.3 minutes for its two finite series; core counts
were not recovered. Saved DE stages 1–2 took 1871.616 s for 91 families.
The inefficient full shared attempt was stopped; diagrams, reductions and
normalized expressions were retained. Exact summand compaction reduced the total
normalized input from 852,199,720 to 314,604,875 bytes.

# Completed SIDIS NNLO UU/LL — 2026-09-10

The integrated electromagnetic SIDIS NNLO calculation is complete for all
13 UU and 13 LL channels. The final finite Mathematica results are
Projects/SIDIS_{UU,LL}_NNLO/NNLO/<channel>/Results/Result.wl.
Each project has an NNLO/README.md index with reading and replay instructions.

- RR, RV, VV, UV, PDF/FF counterterms and the LL finite helicity-scheme
  conversion are included. No published hard coefficient enters production.
- All39 structure functions and every delta/plus/regular coefficient agree
  numerically with the independent NNLO references at five exact parameter
  points, covering all four kinematic regions, unequal scales, and a second
  color/flavor/charge assignment. 2,220 finite comparisons and4,410 negative
  epsilon coefficient checks pass, with observed agreement around40 digits.
  This numerical validation is not a global symbolic identity proof.
- The finalizer independently checks882 pole coefficients at two exact
  points in5–7 seconds, matching the complete symbolic input before
  extracting epsilon^0. Every file passes semantic exact read-back checks.
- Files contain explicit rational/log/polylog/GPL expressions, no unevaluated
  integrations, unresolved master integrals or solution generators.
- Final files total5,176,150 bytes: UU3,414,061 andLL1,762,089.
  Lossless compression reduced their combined disk size from17,049,489 bytes.
- Full joint endpoint subtraction and uniform meromorphic continuation are
  established for all39 RR rows. Verified GPT-6 Pro review36 confirms the
  completed proof; the independent distributional comparisons also pass.
- General permanent additions cover endpoint profiles, epsilon-regular
  scalar germs and collars, exact physical boundary changes, one-loop
  coincidence subtraction and Hermitian completion, structural denominator
  clearing, direct typed specialization, and common finite-result assembly.
- The endpoint formatter now collects only distribution symbols, keeping
  large GPL coefficient expressions factored: RR assembly is0.1–1.5 seconds
  per channel. Generic final assembly replay is
  Scripts/finish_partonic_assembly.py, using the saved explicit profile and
  finalization manifests. This is not a claim of a newly tested one-command
  fresh diagram-to-master regeneration.
- New targeted checks pass: endpoint projection9, uniform scalar germs6,
  finite result/conjugation8, specialization2, denominator clearing6,
  and existing tensor-product result checks9. Earlier hypergeometric,
  GPL endpoint, one-loop and order-audit tests are retained.
- Endpoint manifests now retain the exact prepared-source process definitions
  and assembly cards. A complete26-output replay passed those identity checks;
  changing a card rejects stale solved inputs.
- No remaining SIDIS NNLO production or validation jobs. No subagents or
  extra kernels were used; the two-kernel/eight-core cap was respected.
  No commit or push was requested.

The complete collinear benchmark campaign is now complete as well.
The remaining NLO incoming-LL qg external check passes for both observed tags
against pinned public Navis: 80 qg LL coefficient comparisons at ten parameter
points. All 320 UU/LL control and target comparisons pass (maximum relative
difference below 3e-13); 128 overlapping UU comparisons also agree with original
INCNLO. No production correction or fitted normalization was needed.
This is agreement with Navis, not authentication of an original author-code
archive. Pro review 37 and process-owned validation reports record the scope.
The overnight monitor is paused; there are no active production jobs.

The notes below are superseded historical progress records.

---

# Current endpoint assembly state — 2026-09-10

SIDIS NNLO is still awaiting full distributional pole and literature checks.
All 26 RR, 12 RV, VV and UV/PDF/FF contributions are now assembled, including
all LL finite-scheme terms. All 26 CombinedLaurentResult.wl files exist.
These are not yet accepted final hard functions.

New completed work:
- Full joint scalar epsilon pole envelopes checked, including scalar factors
  and seeds, not only DE connections; conservative bound -3.
- All three exceptional radial collars and both ordinary open-edge collars
  are uniform and meromorphic; physical leading matrices match the same C.
- Diagonal joint chart and physical boundary matching are exact. Its u^2
  scalar numerator is uniformly meromorphic; direct specialized IBPs cancel
  all78 principal parts. The analytic quotient closes the endpoint seam.
- All60 original pre-partial-fraction source structure functions, from40
  components, satisfy the one joint prescribed-convergence certificate.
- Complete39-row endpoint projection proof saved in CompleteChannels.
- Generic manifest-driven RR endpoint assembly completes a channel in
  0.1–1.5 seconds. A previous whole-expression expansion/factorization was
  replaced by collection only in distribution symbols. Nine regressions pass.
- Current reference checker compares all delta/plus/regular strata, all
  negative epsilon powers, flavor charges and scale logs. First UU/LL point
  is running. Original FORM reference translator now supports NNLO.
- Added authors' independent single-valued ancillary results, validation-only;
  their header confirms the previously undefined FORM abbreviation rln2=Log[2].
- Pro36 review pending, verified gpt-6-pro. Request fa5c5490-efe3-43ea-9e02-7440a4aa86f9.

At most two Wolfram kernels total and eight cores; no subagents.
Frozen ~/FACET remains read-only. No final acceptance until checks pass.

---

# Latest corrected state — 2026-09-10

SIDIS NNLO is NOT complete. RR/RV endpoint distributions and final literature
comparison remain. No final NNLO hard-function Result exists yet.

Completed:
- Critical unit-argument3F2 expansion corrected via isolated HypExp2.0.
  Five tests pass, including regulated limit3/2 and independent Thomae identity.
  Corrected scalar solution13.44s and full39-row bulk contraction61.08s.
  RegularScalarSolution and PhysicalBulkCoefficients are current; older scalar
  outputs remain stale. All-D DE/boundary expressions were unaffected.
- All156 interior pole coefficients cancel at38–40 digits with2ReRV+CT at
  the recorded rational point. This is not full distributional validation.
- All physical weighted corner transfers complete, with exact full-DE checks.
  Every exceptional divisor in the verified three-chart cover matches one
  exact product C(e) rho^(-1-2e) sigma^(-1-2e). Four physical rows are nonzero.
  Corner C through e2 and both full ordinary edges through e1 are explicit GPLs
  with order audits passing. Edge wall times10.85s/15.71s.
- GPL positive rescaling includes trailing-zero corrections; local Laurent-log
  expansion has6 passing tests. Exact edge collection reduces measurement-edge
  leaves2,805,711→178,725 in10.33s, recoil314,723→159,535 in0.65s.
- All26 UV/PDF/FF counterterms and13 LL finite scheme corrections completed.
  VV and12RV interior outputs regenerated. RV stores one interference; final
  physical assembly must include its conjugate.

Current: checking every open-edge Laurent coefficient against its product
corner via explicit GPL germs. Pro34 is reviewing sufficient jointL1 proof
and edge/product-corner subtraction. The jointL1 claim is not yet established.
Source joint convergence and specialized-diagonal IBP restriction records
also remain to be completed, along with RV endpoints and final assembly.

No subagents; at most2 Wolfram kernels total and8 cores. HypExp workers count
toward the2-kernel cap. Frozen ~/FACET is read-only.

---

# Critical current correction — 2026-09-10

The previous RegularScalarSolution and PhysicalBulkCoefficients contain an
incorrect exceptional-parameter expansion of a unit-argument 3F2 constant.
They are NOT validated production results and must be regenerated. Direct
Mathematica Series substitutes the terminating value1, whereas the regulated
limit of 3F2(1,1,-e;1-2e,1-e;1) is3/2. Some higher coefficients also contain
unevaluated parameter derivatives. Generic regulator-series and explicit
contraction acceptance are being tightened; HypExp2.0 was downloaded from
the authors' UZH site to /home/maxzhang/facet-tools/hypergeometric for a general,
isolated expansion backend. Do not patch master coefficients by hand.

The all-D DE, physical all-D boundary expressions, IBP and diagonal/geometry
proofs remain separate from this epsilon-expansion error. NNLO remains incomplete.
The open-domain pole check also found RV coefficients can retain an imaginary
part; causal/conjugate handling must be inspected after fixing RR constants.
Original logs PhysicalInteriorPoles.log and HypExpCriticalUnitArgument.log.

---

# Current continuation — 2026-09-10 (supersedes notes below)

SIDIS NNLO UU/LL is still NOT complete. Full RR/RV endpoint distributions,
final pole cancellation and independent NNLO comparison remain.

New completed work:
- Regular20 explicit scalar solution is complete at its BULK orders, 562572 bytes,
  156 GPLs with maximum weight3. All omitted-order audits passed.
- All13 finite LL scheme counterterms are computed and merged. The original raw
  MS/Larin terms are preserved as UVCollinearResult.wl; combined Result.wl
  records FiniteSchemeConversionApplied. Exact-zero gluon plans are explicit.
- Specialized diagonal IBPs give two independent relations among the first5
  regular masters. All39 physical rows' x-z poles (maximum order2) cancel
  exactly at generic D. See CompleteChannels/Diagonal/PhysicalPoleCancellation.wl.
  Positive numerical base canonicalization fixed a false analytic-field residual:
  (16 Pi)^epsilon and 2^(4epsilon) Pi^epsilon are treated consistently without
  splitting unknown-sign products.
- ConstructMasterCoefficientDivisorDerivatives computes exact regular numerator
  jets through the quotient order. All5 masters with all actual derivative
  weights passed the same joint high-D convergence certificate. The Taylor
  remainder gives a uniform grouped bound on diagonal squares, including(1,1).
  Specialized-IBP restriction validity and original-source joint coverage still
  need explicit records. This is not yet a final endpoint extension claim.
- Verified GPT-6 Pro review31 retained in External/ChatGPT/Records/2026-09-10.
- Three monomial endpoint charts form an exact disjoint-interior cover:
  (rho,sigma)=(r,r^2 t), (r^2 t,r^2 t^2), (r^2 t,r^2).
  Their full rational DE normal systems passed exact checks in4.58,4.20,3.22s.
  Chart3 has a verified full logarithmic normal crossing after its tangential
  gauge: orders of r Ar and t At at both axes are nonnegative; corner residues
  commute. Normalized radial sectors are0,-2e,-4e,-8e; tangential-2e,0.
  Physical weighted-sector selection/matching is NOT yet established.
- New ContractExplicitMasterSolution uses the existing exact contraction and
  omitted-tail audit. Its first actual run timed out in the generic symbolic
  remainder Series. A direct per-factor rational exponent/analytic Series check
  now proves safe tails independently without calling the order planner.
  Ten contraction tests including deliberate insufficient orders and Gamma poles
  pass;10 refined monomial-chart/contact tests pass;7 divisor-jet tests pass.

Current jobs (verify ps):
- ContinueBulkContraction.py controller661969, CPUs0-5: tests passed, all39
  physical open-domain rows being contracted. Outputs PhysicalBulkCoefficients.wl
  under CompleteChannels, with audit wrapper. No endpoint distribution inferred.
- Weighted joint normalization finished. Chart3JointNormalization.wl is available.
- GPT-6 Pro weighted matching review pending; prompt
  Codex/General/ChatGPT/pending_weighted_matching_prompt.md. An unsent update
  pending_weighted_matching_update.md contains the exact logarithmic crossing.

Next: finish bulk contraction; justify and match physical weighted modes with
finite exact gauge jets; compute dangerous radial/angular orders and uniform
L1 remainders; construct ordinary RR/RV edges and corner moments; assemble all
pieces, cancel every pole, independently compare. Preserve general code.
No subagents; max2 main Wolfram kernels and8 CPU cores.

---

# Current running state — 2026-09-10

SIDIS NNLO UU/LL is NOT complete. Endpoint RR/RV assembly, finite LL conversion,
full pole cancellation and independent NNLO comparison remain.

Completed in this continuation:
- All symbolic-charge VV and all 12 RV interior outputs are regenerated.
  SymbolicChargeLoopSourcesContinuationReport.json is complete.
- The old55 scalar solution finished at its bulk-demanded orders: all required
  finite integrals converted to GPLs. CompleteChannels/ScalarSolution is valid
  for those individual integrals, not full endpoint distributions.
- Exact differentiation of the22 spanning identities finds two more relations.
  ReduceMasterDifferentialSystem with CloseDifferentialRelations verifies a
  20-dimensional embedding against both original DEs; no minimality claim.
- SelectMasterIntegralBasis now selects exact candidate images, using rational
  samples only for row selection and exact inverse/DE checks afterward.
  RegularDifferentialSystem.wl has20 masters, all nonnegative indices, including
  one ordinary squared denominator. Its physical boundary construction took
  4.456s: six tangential functions fixed by two evaluated constants.
  The preceding ReducedDifferentialSystem/ReducedPhysicalBoundaryValues files
  use other20-coordinate bases and are not interchangeable by row number.
- Generic DE normalization now accepts coordinate-indexed associations,
  orders their matrices by KinematicVariables, and normalizes D consistently.
  DE basis tests6 and sparse-dimension tests11 pass.
- The compact-cut certificate now has a joint external-domain specialization.
  It checks full PSD Gram geometry, constant-rank unit cuts, a uniform timelike
  frame, endpoint Gram zeros and coefficient divisors. It proves an atom-free
  joint high-D starting measure. Mixed polynomial D factors are accepted only
  with a uniform nonzero leading coefficient (Cauchy root bound).
  Joint tests7 and old measured tests pass. See Design/JointCutConvergence.md
  and verified GPT-6 Pro review29.
- IMPORTANT: termwise production joint certification still fails for x-z in
  the FIRST FIVE regular-basis coefficients. The other15 passed. Do not mark
  the whole reduction endpoint-certified. Need an independent grouped
  cancellation/smoothness proof for this apparent diagonal.
- Coefficient transformations after analytic normalization inflated expressions.
  The production driver now composes a FinalBasisReduction on raw rational
  coefficients BEFORE applying bare-coupling normalization. Most rows take
  1.4–3s; LL q-q/qbar-qbar17.5/15.9s. All39 rows are regenerated in
  RegularPhysicalMasterCoefficients.wl. Bulk upper orders are
  {2,0,0,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}.
- A common analytic-factor extraction was also added to
  CancelRationalCoefficients (FactorTerms of the numerator before restoring
  formal analytic field symbols). Its first profile attempted factoring the
  whole rational expression and failed; the corrected profile completed.
  Existing rational-coefficient regressions still need running after this edit.
- Finite operator-scheme inversion through order2 is implemented in
  Physics/CollinearRenormalization.wl and uses the common perturbative engine
  with explicitly Renormalized sources, epsilon0 only, no repeated UV step.
  Six finite-scheme tests and seven old renormalization tests pass.
- Projects/BareSources.wl now constructs a raw-scheme subtracted LO/NLO catalog,
  requires exact pole cancellation and resolves finite flavor/charge covariance.
  A color-convention mismatch was fixed by applying the declared ColorRules.
  Actual LL catalog completed in0.686s: two LO and six NLO sources, all poles
  cancel. Stored in LL NNLO q-q Results/Counterterm/SubtractedLowerOrderSources.wl
  as a WithEpsilonRemainderChecks wrapper. The finite NNLO correction constructor
  is written but has NOT been executed on the13 LL channels yet.
- Verified GPT-6 Pro review30 recommends open edges, two weighted charts for
  rho²+4(1-rho)sigma, contracted dangerous Frobenius jets and only then corner
  moments. It gives explicit tests for a hidden epsilon-suppressed corner
  contact and nonlinear delta-derivative pushforwards.
- New Geometry/WeightedEndpointCharts.wl, Coefficients/WeightedEndpointDistributions.wl,
  and PullBackRationalDifferentialSystem are written and registered. Tests are
  running/pending; these do NOT yet constitute physical corner extraction.

Live/last controllers (verify actual processes):
- Rational raw coefficient/certificate controller648439, CPUs0-5, finished
  generation and the20 termwise checks. See RationalRegularCoefficientReport.json.
- Scalar continuation controller649591, CPUs0-5, writes
  CompleteChannels/RegularScalarSolution; log RegularPhysicalScalarSolution.log.
- Weighted regression controller649592, CPUs6,7, runs weighted endpoint and
  bare-source tests after the now-completed actual LL subtraction.
- Old normalized coefficient controller646847 and waiting scalar controller646848
  were stopped intentionally. Their partial normalized-reduction work is
  superseded; retain logs for diagnosis, do not reuse its partial outputs.

Next:
1. Check/fix new weighted tests; run rational coefficient regressions and layout.
2. Finish regular-basis scalar GPL solution and its omitted-order audits.
3. Execute finite LL scheme counterterms from the verified finite catalog.
4. Resolve the apparent x-z poles of the grouped first-five scalar combination;
   no further blind basis reshuffling. Their DE/physical smoothness can supply
   a finite diagonal-jet proof, or explicit analytic scalar values can.
5. Construct both weighted rational-DE charts from the original connection,
   not by substituting a truncated ordered series. Compute ordinary edge
   profiles and dangerous radial/ratio jets, certify a uniform integrable tail.
   A finite number of exact unmeasured polynomial moments may normalize corner
   contacts; no inclusive hard coefficient is a production input.
6. Assemble RV endpoint box/triangle data, combine RR/RV/VV+UV/PDF/FF+finite
   scheme, verify every pole and compare to independent literature.

No subagents. At most two main Wolfram kernels and eight CPU cores.
All process artifacts remain under Projects. No final SIDIS NNLO Result exists.

---

# Current running state — 2026-09-09

SIDIS NNLO is still incomplete. Major completed work this continuation:

- All 40 corrected UU/LL RR source components are generated. Affine sharing
  gives 75 families and 6,610 targets. Targeted exact IBP reduction now closes
  ALL targets on 22 members of the previously solved 55-integral set.
  The search uses 7,318 seeds and 79,134 exact equations. Native exact Kira
  passes took about 21 seconds each (three selection passes), in addition to
  preparation/import. The old rectangular estimate was 1,141,275 seeds.
- The 23 prescription-only duplicate directions are identified only after
  applying the existing convergence certificate to each actual powered
  integral. Eight then ten coordinate/certificate assertions pass. Original
  definitions are retained. Joint external endpoint uniformity is NOT implied.
- Exact scale removal is verified row by row as a formal change of unknowns.
  Saved exact reductions include restored Q2 powers. A quadratic scale-restoration
  lookup and held-topology cache comparison were fixed. Ten seed/scale assertions pass.
- All 39 physical RR structure-function combinations are contracted, with
  current normalization, symmetry factors and flavor multiplicities.
  CompleteChannels/PhysicalMasterCoefficients.wl is 12.74 MB. For bulk epsilon0,
  four masters need epsilon2, three epsilon1, and the others epsilon0.
  Further endpoint-moment demands remain to be determined.
- Bare symbolic-charge LO epsilon2 and NLO epsilon1 results regenerated for
  both projects. Fresh virtual reduction installs its external Gram matrix
  locally before tensor reduction and restores caller state. Ten one-loop
  tests and six generated-current comparisons/pole tests pass.
- All 26 NNLO UV/PDF/FF counterterms are complete, with remainder audits passing.
  UU q-q took 10.02 kernel seconds; the other 25 took 239.42 total elapsed seconds
  including separate kernel startups. These are MS/Larin counterterms; the final
  finite helicity scheme conversion is still separate.
- General bare-source loading, explicit minimum channel orders, exact external
  charge factor checks, shifted harmonic-sum completion, and branch-preserving
  positive logarithm factorization are implemented. Tests: bare sources 6,
  perturbative renormalization 7, logarithms 3, Mellin logarithmic convolution 3.
  Independent direct quadrature agrees with the new closed convolutions.

Running:
- SymbolicChargeLoopSourcesContinuationManifest.json, controller 592201,
  CPUs 6,7. UU VV is regenerated and combined; RV regeneration is proceeding,
  then LL VV/RV. Report and logs under the UU q-q Validation directory.
  The general virtual driver now adapts targeted seeds until every master
  matches a verified scalar library: fresh two-loop interference closed in
  two iterations (1,713 then 2,472 seeds), 27.37 kernel seconds. The unused
  rectangular virtual search was stopped and is not production.
- SufficientPhysicalScalarSolution.log, scalar solution group 603178,
  CPUs 0-5, writes CompleteChannels/ScalarSolution using the actual bulk orders.
- Verified GPT-6 Pro joint endpoint convergence review is pending in
  Codex/General/ChatGPT/pending_joint_endpoint_convergence_*.
  Previous review 28 accepts the scoped prescription identifications and
  exact scale removal, while warning about rational localization/contact terms.

Still required: finish sufficient master orders and uniform joint RR endpoint
expansions; assemble regulated RV faces/corners and interior; complete symbolic-
charge VV/RV regeneration; apply the finite helicity scheme; combine all pieces,
prove pole cancellation and independently compare the full NNLO coefficients.
No final SIDIS NNLO hard-function result exists yet.
No subagents, at most two main Wolfram kernels and eight CPU cores.
Package layout audit: 222 sources, no errors.

---

# Latest continuation — 2026-09-09 (supersedes historical counts below)

SIDIS NNLO remains incomplete. Do not label the 55-master finite solution as
a complete hard function: corrected physical numerator coverage, RR/RV
endpoint distributions and final UV/PDF/FF assembly still need completion.

Both project cards now retain symbolic UpType/DownType electric charges and
13 ordered NNLO flavor-channel types, with 40 RR components across UU/LL.
The full source campaign regenerates diagrams, source preparation and scalar
integral decomposition. Old fixed-charge LO/NLO/RV/VV outputs are retained
benchmarks, but must be regenerated for the updated cards. A common exact
process-definition check now refuses a source generated with a different card.

The corrected numerator map initially inflated temporary coefficient tables
to 766 MB (UU) and 5.67 GB (LL). Polynomial coefficient cancellation now happens
before coordinate substitution and before combining products; large rows use
the exact native FLINT backend. On original LL source coefficients native
cancellation takes 1.29 s, with exact independent comparison in 2.19 s.
UU q-q gluons now complete in 164.36 s (2F1) + 16.87 s (FL/x), with 10 families
and 1156/568 targets; the stored result is 0.961 MB. A further permanent change
converts each original numerator once per family, reusing it across all
partial-fraction terms. Fifteen reconstruction, prescription, checkpoint and
source-consistency tests pass after this change. The running LL q-q benchmark
started before that last cache improvement; subsequent jobs use it.

Live state at this note:
- UU controller 528642, manifest CompleteRRSourcesUURestartManifest.json,
  report CompleteRRSourcesUURestartReport.json; CPUs 6,7.
  Completed q-q gluons / SameFlavor / DifferentFlavorUp / DifferentFlavorDown;
  qbar-qbar gluons underway. A temporary regression pause is finished.
- LL q-q gluon decomposition group 527881, EarlyCancellationNativeLL.log,
  CPUs 0-5. ContinueLLSources.py controller will start
  CompleteRRSourcesLLRemainingManifest.json only after successful completion.
- All manifests/reports above are in
  Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/Validation.
- At most two main Wolfram kernels, eight CPUs. No subagents.
- run_contribution_stages.py retries only the exact transient license-startup
  failure, before any computation, at bounded delays; other failures stop.

General perturbative assembly is implemented and registered:
Coefficients/PerturbativeRenormalization.wl enumerates UV shifts and one
transition matrix per physical leg through relative order two, retains
correlated flavor multiplicities and all lower poles, and propagates sufficient
source/intermediate epsilon ranges. Physics/FlavorSums.wl passes seven checks;
assembly passes six checks including independent explicit five-species matrix
multiplication, p=2 UV terms, an omitted-order audit, missing/short sources and
opposite PDF/FF orientations. PlanCollinearRenormalization supplies the actual
MS/Larin spacelike and timelike kernels from physical leg cards.
This is the common assembly engine, not yet a finished process runner.

Verified GPT-6 Pro review 26 confirms the coupling, transposition, unequal-scale
and Larin formulas. Keep each source's own dimensional prefactor. Finite
scheme conversion is a separate pass on already subtracted coefficients with
coupling renormalization disabled; its positive-epsilon continuation must be
declared rather than inferred from a four-dimensional scheme.

Endpoint order planning now retains all Taylor moments of stronger powers,
including nonresonant ones. Matrix moments include logarithmic powers and
normalization zeros; exact left/right maps are contracted before boundary
column demands. The expanded sufficient-order regression passes.
ContinuationRegressionReport.json has one historical failure in a test's
literal flavor-label selection; PerturbativeRenormalizationOrientationRetest.log
records the corrected six-pass result. Rational coefficient tests pass eleven
assertions. Package layout audit passes with 217 registered sources.

Next: finish all 40 corrected RR sources, build the CompleteChannels reduction,
verify new targets against the old 55-master solution or solve extra masters,
derive physical coefficient/face/corner demands and uniform endpoint coverage,
complete RV edge/corner assembly, regenerate symbolic-charge lower orders and
virtual inputs, and connect the assembly engine to card-driven source/charge
resolution. Pole cancellation and independent NNLO reference comparison remain
required. No final NNLO Result.wl has been produced.

---

# Current campaign — 2026-09-09

## Current continuation — SIDIS NNLO is still incomplete

The eight UU/LL q/qbar double-virtual components are now evaluated, combined,
and independently checked. The generated all-D two-loop coefficients of all
four scalar masters agree exactly with hep-ph/0507061 equation (10); the
one-loop squares agree with equation (8) squared. Longitudinal UU virtual
coefficients vanish. Signed disconnected bubble products preserve both i0
prescriptions and the loop-measure conversion. Exact family-definition and
target-coverage checks reuse the virtual reductions across these channels.

The ordinary basis builder now completes its affine scalar-product matrix
without FeynCalc's common-eta restriction. Seven virtual basis/reuse/reference
checks pass. A general integer-power substitution fixes g_s^4 under a g_s^2
card rule; all twelve RV interior outputs were regenerated and four dedicated
power-substitution checks pass.

The existing 55-master physical solution through epsilon^0 now converts all
required finite integrals to GPLs. The common GPL engine has a unit-tangent
conic chart and rational argument pullback, including trailing-zero constants.
Seven exact chart/derivative/basepoint tests pass. Pro review 24 is retained.
The three radicands belong to separate one-root dependency components.
Conversion took 114.77 s plus 74.49 s for eight expressions exceeding the
initial size limit. Sharing finite boundary coefficients before contraction
reduces the saved finite solution from 24.4 MB to 2.2 MB; the final matrix
multiplication takes 0.01 s. This does NOT establish the final hard-function
epsilon orders or endpoints.

CRITICAL CURRENT CORRECTION: the physical coefficient-demand audit found that
DecomposeMeasuredCutIntegrand reversed the stored coordinate -> scalar-product
map. Consequently its coefficients still contained free loop-coordinate
symbols instead of translating numerator powers to GLI indices. Earlier
reconstruction tests missed this because those same symbols survived on both
sides. The map direction is fixed, coefficients now reject every original
loop coordinate / inverse-propagator variable, and the strengthened twelve
measured-integrand tests pass. All sixteen retained RR sources are currently
being decomposed again (two kernels; UU CPUs 0-5, LL CPUs 6-7). The old RR
coefficient tables/reduction target coverage must not be used as complete
physical input. The old master DEs/solutions are valid for their stated
integrals and may be reused only after checking corrected target coverage.

Live correction reports:
Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/Validation/
NumeratorDecompositionUUReport.json and NumeratorDecompositionLLReport.json.
No subagents; at most two main Wolfram kernels / eight cores.

The following earlier notes describe the preceding state and remain useful
as provenance; the correction above supersedes their physical RR coverage.

The ordered physical boundary calculation for the earlier shared 55-master
system is complete. Its symbolic corner connection converts fully to GPLs;
the normal connection is finite and explicit but has unsupported auxiliary
square-root sectors. The physical amplitudes and their epsilon convolutions
are retained. This is not a completed NNLO hard function.

An upstream source simplification now removes the unnecessary gluon-reference
denominator before IBP. The general algorithm clears rational color/dimension
coefficients separately, cancels each coefficient monomial exactly on the unit
cuts, and retains unrestricted definitions and the original prescription proof.
UU q-q gluon targets fall from 88 per structure to 18 transverse / 14 longitudinal;
LL falls from 88 to 36. The LL cancellation took 167.14 s; its decomposition
took 64.29 s. Original product decompositions are retained when no kinematic
denominator is eliminated, avoiding a demonstrated partial-fraction slowdown.
Preparation is now saved before decomposition and supports independent resume.
All 16 previously generated RR sources have been prepared; a new shared reduction
is running under DoubleReal/PhysicalChannels, on CPUs 0–5 with six Kira threads.
The old shared system and physical boundaries are retained.

All 12 UU/LL real–virtual channel sources are now generated and tensor-reduced.
The common measured one-loop reducer restores caller scalar-product settings,
retains original prescribed external factors, and records their pointwise values
only on the open domain. Scalar products are stored as a Gram matrix as well as
rules so pre-existing caller values cannot erase their definitions.
The scalar provider now handles exact two-off-shell triangles, coincident limits,
triangle-to-bubble IBPs, and arbitrary-order one-off-shell boxes with physical
causal phases. The box provider passes 35 coefficient comparisons in seven
invariant-sign configurations, including the regulated on-shell limit and a
removable internal diagonal. Generic box formulas must be approached as a whole
on that diagonal; termwise substitution gives an incorrect reference.
The full-D joint loop/real-momentum covariance tests pass for spacelike and
timelike shifted bubbles. Complete loop combinations now propagate sufficient
epsilon orders and run the common omitted-order audit. Interior coefficient
evaluation has completed for all 12 channels. The first UU q-q evaluation
took 9.667225 kernel seconds; the remaining complete jobs took about 16–20
elapsed seconds each including startup. These are interior coefficients, not
regulated endpoint distributions.

Double-virtual cards now declare both two-loop interference and one-loop square.
All eight scalar source jobs completed (roughly 8–14 elapsed seconds each).
The sources retain generated two-loop interferences and one-loop squares;
their loop reduction and master evaluation are still required.
NLO tree endpoint powers and smoothness assumptions have been moved from the
shared project root into NLO Real cards, preventing NNLO from inheriting an
incorrect single pair of regulated powers.

Verified GPT-6 Pro reviews 20–23 are retained. Review 23 derives an exact
correlated-box difference that resolves all three SIDIS box corners into
normal-crossing powers, and identifies the universal two-loop vertex master
library (hep-ph/0507061, scalar integrals in section 2). Implementation of these
endpoint/virtual steps is next. The existing box provider already uses the
correct |u/(st)|^epsilon scale; the extra mass in the review question was a
transcription error, not a production normalization.

Universal NLO spacelike UU/LL and timelike UU splitting functions are implemented
in Physics/NLOSplittingFunctions.wl. The retained formulas and exact-rational
translation are reproduced from pinned APFEL++ sources. All 324 comparisons
against independently compiled upstream C++ pass. Individual-flavor, momentum
and nonsinglet axial sum rules pass, including restored symbolic TR.
Physics/CollinearRenormalization.wl constructs the complete flavor transition
kernel through a^2, unequal scales, inverse kernels and raw Larin helicity.
Its six tests pass, including gluon mixing and the noncommuting scheme change.

General Mellin convolutions now use closed formulas for Laurent polynomials and
D0 convoluted with arbitrary D_m; other kernels use the MT adapter. Ten tests
pass. Any distribution axis and structure-function vector in the common result
can be convolved without losing active-variable dependence (four tests pass).
PartonicLaurentProducts.wl propagates sufficient epsilon orders through scalar
multiplication and collinear convolution; five tests pass, including deliberate
one-order fault injection detected by the omitted-term audit.

The SMQCD adapter can now declare symbolic UpType/DownType ElectromagneticCharges
at the photon-quark model vertex, before amplitude generation. Both chiral
components change consistently. Four generated-amplitude tests pass, including
recovery of the original amplitudes and restoration for a subsequent ordinary
model calculation. Existing production cards/results have not yet been converted
to this charge basis. No SIDIS hard coefficient is a production input.

Still required: complete NNLO flavor/charge-channel inventory; final shared RR
master coefficients at coefficient-demanded orders; regulated RV endpoint limits;
VV reduction and scalar values; connecting the completed splitting/transition
kernels to full NNLO factorization, UV and finite-scheme assembly; final distributions and external
hard-coefficient comparison. No final NNLO result or completion claim is justified.

Live reports are under Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/Validation:
PhysicalRRReductionPrerequisites.json, RealVirtualReport.json,
LoopEvaluationThenDoubleVirtual.json, DoubleVirtualReport.json,
RealVirtualInteriorEvaluationReport.json, RealVirtualInteriorRemainingReport.json,
and NNLOFactorizationTests.json. The failed LL qbar-g interior attempt occurred
while a newly registered module was absent; its completed rerun is in the
remaining-channel report. All 12 interior outputs now exist.
No subagents; at most two main Wolfram kernels and eight CPUs.

Latest SIDIS boundary progress: all 42 shared q-q masters have unit cuts and
exact normalized three-particle charts. The common recoil proof gives only
rho^(integer-2 epsilon). A 14.05 s local DE construction selects a 16-dimensional
tangential sector; three additional exact onset constraints reduce it to 13.
The ordered z endpoint has seven exponent-zero directions, five -2 epsilon
directions and one -3 epsilon direction. The physical angular kernel analysis
permits only the latter two slopes; full-rank physical value matching is next.
The q-q physical matching is now complete: six constants, including one forced
zero from a forbidden lower integer power. All 50 coefficient equations agree
at two rational regulator/scale points. A general driver reproduced the whole
boundary construction in 36.35 s. This is not a completed hard function.

The general rotated chart isolates P.k2 as S z/(2 Z) times (u+(1-z)r/z).
Its Gram determinant and Jacobian pass exact checks. Eight spherical-convolution
moment assertions pass. Leading hard/endpoint coefficients for all 42 masters
have been evaluated as Gamma/3F2 expressions. Independent suppressed-branch
quadrature takes 0.68-0.73 s and has relative asymptotic error 7.3e-8.
Pro review 19 found a general sequential-valuation error for competing
sigma/u numerator powers. The code now computes a joint weighted angular jet,
retaining even azimuthal moments; both counterexamples pass. Metadata separates
the allowed slope envelope from computed coefficients and does not claim a
certified truncation error. A general Euler
cyclic-vector fallback resolves a nondiagonal Fuchsification obstruction in the
13-dimensional corner system; the full preparation takes 0.35 s.

All eight additional q-g/g-q/g-qbar/qbar-g UU/LL gluon-emission components are
generated and prepared. A generic manifest-driven shared reduction completed in 1647.03 s:
12 scalar sources, 53 exactly distinct families, 259 targets, 269 unreduced
master positions. Combining with the 42 q-q directions gives 311 positions ->
68 exact integral classes -> 55 spanning masters in 7.16 s. The SAME physical
boundary driver handles all 55 unit-cut masters: 22 physical recoil directions,
19 after onset constraints, and full-rank matching of seven corner constants
in 37.38 s. This includes the weighted-jet correction from Pro review 19. Script interfaces
now take explicit PROJECT ORDER CHANNEL, and the one-off SIDIS controller has
been replaced by the general run_contribution_stages.py manifest driver.
Pro reviews 18 and 19 (verified gpt-6-pro) are retained. No subagents are used.
The original-master epsilon requirements are now propagated through the two
boundary maps and exact Gamma constants. A q-q demonstration through epsilon
zero needs five nonzero corner columns, with evolution through {4,2,2,2,3};
its 13x5 explicit finite connection has 71 integrals and takes 0.63 s.
The corresponding shared-55 evolution is in progress. Interior initial values,
full channel inventory, RV, VV, NNLO splitting/counterterms and hard assembly
remain incomplete. The regression has 95 assertions plus the 23 new angular/
boundary assertions; the parameter-dependent Laurent-saturation check is running.


All eight active projects and computed process outputs are under Projects/.
The old ppHX bare NNLO double-real data is now in
Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/{Results,Kira,InputData}/DoubleReal.
Its self-contained compact coefficient result is 104,939,642 bytes.

The requested NLO inventory is generated: qqprime, annihilation, qg with
observed quark/gluon, inclusive UU Drell–Yan and integrated UU/LL electromagnetic
SIDIS. SIDIS passes 12 UU + 6 LL exact reference checks; Drell–Yan passes 18.
Full finite LL qg external comparison remains unperformed.

SIDIS NNLO is incomplete. For q-q, all four double-real components (Gluons,
SameFlavor, DifferentFlavorUp, DifferentFlavorDown) now have generated and
decomposed UU and LL scalar integrands. The LL gluon generation takes about
207 elapsed seconds and its optimized exact FORM output matches the older
contraction byte for byte. All 75 BMHV algebra, 12 NLO contraction and 19
correlated-angular-average assertions pass. The earlier 16:57:50 UTC stop was
caused by five test-comparison failures from equivalent epsilon argument order;
the antisymmetry-aware comparison resolved them.

The UU gluon component has 8 source ordinary denominators, 108 denominator
products and 88 GLI targets per structure. Sharing denominator subsets reduces
34 families to 14; exactly equal definitions share the same reduction between
2F1 and FL/x. The general source preparation certifies the whole prescribed
product before rationalizing it and preserves unrestricted denominators for
dotted-cut differentiation. Twelve affine-partial-fraction, six phase-space
factory and nine preparation/decomposition/merging assertions pass.

Typed IBP generation uses explicit equations and Kira config:false.
Large 8580-seed generation fell from 74-78 s to 11-13 s. The Kira adapter
automatically closes missing selected export dependencies using the retained
equations, without calling those unresolved pivots masters. All four UU q-q
RR components now have closed DEs. The resumed gluon DE took 749.24 seconds;
fresh SameFlavor/Up/Down took 551.21/78.34/78.41 elapsed seconds.

The existing exact affine cut-equivalence code now supports typed measurement
cuts as well as particle cuts. Across the four UU components, 248 basis entries
give 57 exact integral classes; differential relations reduce the shared system
to 42 spanning masters in 2.18 seconds, including exact differential relation closure. This is not a minimal-IBP-rank proof.
The ten measured-equivalence assertions and global-boundary
regression pass, including exact fallback when rational samples lose rank. All four component systems have finite-integration
preparations; these are not yet complete master solutions.

Dimension conversion is now centralized at the preparation, application,
finite-construction, order-planning and global-DE interfaces. Sparse matrix
coefficients are materialized before a declared D-to-epsilon substitution.
A broader regression also caught an essential-singularity acceptance error:
RegulatorSeries now rejects unfinished nested series and non-Laurent terms
before coefficient extraction can turn them into zeros. The 43 existing finite
solver assertions, six Laurent-series assertions and targeted sparse-dimension
checks pass (the sparse test now also exercises order planning).

The joint longitudinal PDF/current angular average is connected to generated
current contraction with eligibility checks, preserving standalone distribution
definitions. Exact NLO real comparisons pass for incoming q and g and observed
q/g; 15 projected-current assertions pass. Tensor identities and exclusions
pass 15 assertions. Full-flavor NNLO finite PDF kernels are implemented in
Counterterms.wl and pass 11 checks against 2510.00100 Appendix A and independently
1409.5131 Appendix A. Their use with real-virtual loop amplitudes still needs
the corresponding raw-operator regression; full NNLO counterterm assembly
is not complete.

Pro reviews 16 and 17 are complete and retained, both verified gpt-6-pro.
They address exact measured-cut equivalences, ordered boundary limits and
fixed-slice Laurent bounds. The latter requires uniform finite normal
derivatives on the parent mass-deformed domain. Its common implementation
passes nine measured-slice tests, including two independent measurements and
symbolic scale restoration; all existing 23-master CF269 bounds still pass.

Latest user priority: permanent general workflow fixes, including one common
interface for any number of kinematic variables, ahead of reproducing selected
processes. The finite solver itself already supports multiple variables.
Consolidate adapters and normalized integral definitions; do not build a
separate SIDIS solver. Historical ppHX reduction already used exact affine
changes: 1561 entries -> 355 classes -> 348 spanning directions; its 345
requested masters need a 346-dimensional closure. No further reduction of
that old requested set has been established in the current work.

The same master-definition and Baikov constructor now accept typed cuts and
explicit measures; 42 shared UU RR definitions/representations were generated
in 1.24/1.98 kernel seconds. Generic measured massless volume formulas support
any particle multiplicity and measurement-cut derivatives, excluding particle
dots. Common tests pass: sparse/regulator normalization 9, variable dimensions
1/2/3 9, typed definitions 10, finite solutions 43, existing workflow 27.
The last includes fresh construction of 92 CF269 coefficients.

All 42 shared UU RR masters have automatic conservative lower bounds -3 at
(x,z)=(1/4,1/3), keeping Q2 symbolic via proved homogeneity. The 42 bounds
require about seven kernel seconds. For every master through epsilon zero,
the order planner requires evolution through epsilon four and 837 transformed
matrix coefficients. This is not full hard-function endpoint coverage.

The first finite construction wrote 192 coefficients in 25.02 seconds, but
verification exposed named kernels that were exact rational zeros below the
proved entry valuations. The common constructor now verifies and materializes
those zeros before expression sharing. Numerical validation also now samples
constant symbolic parameters, including in path and initial-inverse checks;
incomplete explicit samples produce a data error rather than a false DE
mismatch. The regenerated finite result passes all coefficient checks: 192 explicit
master coefficients, 795 finite integrals and 3,208 shared scalar kernels,
about 7 MB. Construction/verification took 22.38/1.93 kernel seconds. The
existing general exporter independently reproduced and verified it from /tmp,
using relative request paths: 24.68 s construction and 2.74 s writing. The
retained expansion-order record now reports SufficientOrdersDetermined with
no assumed bounds. This is through epsilon zero at generic kinematics, not
physical boundary evaluation or complete NNLO endpoint coverage.

The final common-workflow regression report has 126 assertions, zero failures.
The package audit checks 192 manifest sources with zero errors. Standalone
test runners now reject syntax errors and missing FTReport tallies even when
wolframscript exits zero.

Physical RR boundary values, the full NNLO channel
inventory, RV, VV, NNLO splitting/scheme terms and endpoint assembly remain.
Generated integrands or a successful reduction are not a complete hard function.
See Design/MeasuredCutIntegralsAndFORM.md and the process-owned Campaign.json.
The five-minute heartbeat is active. No subagents are used.

## 2026-09-09: incoming LL observed-gluon qg complete

The remaining NLO incoming-LL qg channel (observed gluon) is complete:
generated real, virtual, UV and PDF/FF contributions cancel every pole exactly.
Its final explicit coefficient is in
Projects/ppHX_LL_NLO/NLO/u-g_g-u/Results/Result.wl.
No independent full finite LL qg comparison is claimed. The full NLO benchmark
inventory is generated; SIDIS NNLO remains in development.

The final assembly regenerated a missing pure-gluon Born dependency, taking
about 162 seconds inside the kernel. Analytic real/virtual assembly takes
3.80/0.69 seconds. A shared-projector loading-order bug introduced during
deduplication was fixed with explicit namespace resolution; ten spin-tensor
assertions pass, including the previously uncovered hadronic projector case.
Born parallelism now honors the shared kernel ceiling.

The cut-family regression passes 12 assertions in 7.1 seconds, including an
actual Kira reduction with a doubled shifted linear measurement cut and an
independent exact Beta phase-space comparison. A current-contraction change
removes repeated legacy simplification passes; six regression assertions
compare both scalar projections and all stored epsilon coefficients against
previously independently validated UU and LL NLO results. NNLO gluon
contraction is still being profiled; no speedup of that piece is claimed.

## 2026-09-09: endpoint correction, faster assembly, NNLO foundations

The incoming-LL observed-quark qg hard function is complete with exact pole
cancellation. A real bug in endpoint classification used an epsilon-specific
valuation routine on the endpoint coordinate and thereby replaced epsilon
by that coordinate. Rational endpoint valuation now keeps them independent.
The dedicated three-assertion test passes. Applying card color identities
before endpoint classification avoids spurious deeper singularities.

Completed-coefficient assembly now validates the reduction and coefficient
records before reading large amplitude files. LL qg assembly takes about
10 seconds; observed-gluon UU takes 7.69 seconds. The latter's expensive
amplitude stage remains a separate optimization target. Follow-up independent
comparisons pass 32 UU qg INCNLO checks and 36 annihilation UU/LL checks.

Joint correlated evanescent angular moments pass 18 assertions, including
geometry construction and exact preservation of full-dimensional causal
propagators. General massless phase-space volumes and measured moments pass
10 assertions. Both are mathematical providers, not a completed SIDIS NNLO
hard function. Pro reviews 07 and 08 are retained under External/ChatGPT.

The explicit unobserved-gluon projector now has seven passing tests. More
than one bare covariant sum is rejected pending ghost completion. The shared
current path can declare physical states with a non-null reference. The NNLO
linear measurement-cut and reduction interface is being implemented.

## 2026-09-09: complete inclusive Drell–Yan NLO UU

All six incoming flavor/beam channels in Projects/DrellYan_UU_NLO now contain
explicit final coefficients through epsilon one. Real, virtual and both PDF
counterterms are generated by the shared current workflow; no reference
coefficient enters production. The generated Born retains 1-epsilon.

All 18 independent checks pass: exact epsilon-zero and epsilon-one agreement
for each channel against the original arXiv:1307.6925 ancillary file, with
equal factorization/renormalization scales as in that source, and separate
finite-coefficient independence of the renormalization scale. Fresh channel
times including kernel startup and Born generation are 21.87/21.55 s for the
two annihilation orderings and 8.83/8.04/8.27/8.19 s for the Compton orderings.

The massive phase-space tests (18), external-support restriction tests (16),
two-incoming-current factorization tests (8), SIDIS Born-card tests (12), and
SIDIS full UU reference regression (12) pass. The value-only external support
restriction rejects differentiated deltas and unrelated cut constraints.

Incoming LL qg is resuming from completed amplitudes/reduction with seven
normalization workers, correcting the old single-worker card setting.
SIDIS NNLO remains in development; Pro review of joint evanescent angular
moments and the linear measurement cut is pending.

## 2026-09-09: complete SIDIS NLO UU/LL and observed-gluon qg UU

All six SIDIS NLO channels are generated independently in each polarization,
with real, virtual where applicable, and incoming PDF/observed FF counterterms.
The final common-format Mathematica results retain epsilon orders {0,1};
Born dependencies retain {0,2}. The final files total 41,738 bytes for UU and
38,452 bytes for LL. All 12 UU structure-function comparisons and all six LL
comparisons agree exactly with the original literature ancillary coefficients.
References are used only by Scripts/Validation/check_sidis_references.wls.
Full fresh per-channel times, including kernel startup and two Born dependencies,
range from 10.13 to 27.41 s for UU and 7.21 to 23.99 s for LL.

Observed-gluon qg UU also passes all 32 INCNLO checks after full assembly.
Equivalent positive constant powers in epsilon are normalized by exact rational
algebra before the final coefficient-variable check. The virtual coefficient
recovery took 19.5 s using the retained reconstruction trace. The real coefficient
stage took 872.7 s with seven workers and remains an optimization target.

Incoming LL qg production is continuing. A contribution without a double pole
exposed omitted known-zero epsilon coefficients; the real constructor now
stores the complete {-2,0} window before component combination. A regenerated
136-pair gluon state completed in 320.63 s with eight workers.

The optional massive two-particle phase-space geometry and exact endpoint Beta
integration pass 18 assertions. DrellYan_UU_NLO has six NLO channel cards under
Projects; its first full production test is pending. Shared current counterterms
now declare each PDF/FF leg and its convolution variable explicitly. Pro review
06 confirms the Drell–Yan normalization and requires the integrated photon to
remain D-dimensional. The new external-support normalization guard accepts
only an attached unit delta, not differentiated external cuts; its tests are
pending. No Drell–Yan or SIDIS NNLO result is claimed yet.

## 2026-09-09: current real/virtual contributions and resumed NLO (in progress)

All seven active project folders are under Projects. A fresh-session resume
audit exposed unevaluated path replacements in 34 relocated binary records;
the strings were repaired, the length-prefixed records rewritten, and all
17 affected reduction streams validate independently of migration variables.

The observed-gluon qg real coefficients are recovered. All seven common
master coefficients become fraction-independent after applying the root
card's SU(N) color identity. This is now a coefficient-stage operation.
Equivalent imaginary prefactors share one class: 24 reconstruction outputs
became seven, and FireFly time fell from 18.04 to 8.79 s. The whole coefficient
stage still took 872.7 s with seven workers, dominated by algebraic normalization.
Its retained coefficient file is 0.23 MB. Full observed-gluon production is
resuming from the completed real amplitude/reduction/coefficient stages;
its complete independent comparison is still pending.

The qqprime UU NLO resume regression completes in 4.52 s inside the kernel,
reuses the amplitude/reduction stages, and passes all 32 INCNLO checks.
Resume validates process identity, diagram coverage and reduction provenance,
with epsilon symbols normalized by name. Recursive distribution mapping now
preserves named pure-function parameters.

SIDIS UU/LL cards generate exact-epsilon q-q, q-g and g-q real densities.
Their quark/antiquark and tag-exchange identities pass. The q-q virtual
contributions are generated from one-loop diagrams, reduced with TID and
evaluated using shared Gamma formulas for bubbles and single-off-shell
triangles. Evanescent numerator powers are averaged in the orthogonal
complement of the physical external span before TID; they are not discarded.
UU and LL virtual coefficients agree through epsilon one. The real/virtual
double-endpoint poles cancel, and the endpoint planner requests epsilon three
for the smooth corner factor when the result is needed through epsilon one.
These generated-current tests and the Born/card/phase-space/storage regressions
pass 60 assertions across five files.

The new current counterterm constructor and command-line contribution driver
are being connected and still require their own end-to-end validation.
No complete SIDIS NLO, SIDIS NNLO, or Drell-Yan result is claimed.
See Design/CollinearBenchmarkCampaign_2026-09-08.md and the process-owned
CurrentWorkflowRegression.json. Pro review 04 approves the color identity and
local endpoint domain; review of the evanescent virtual-loop average is pending.

## 2026-09-09: Projects directory and generated current vertices (in progress)

All five active physics projects now live under Projects/. Their relative
lower-order dependencies and 34 binary reduction records were relocated;
all 17 reduction streams validate and the quark-gluon observed-quark hard
function still passes all 32 INCNLO checks. Calculation drivers resolve project
names under Projects; archived historical fixtures remain frozen.

The shared diagram converter now amputates the external electromagnetic
current before any Lorentz contraction. Generated up/down quark and antiquark
Born vertices pass absolute charge/color/helicity normalization and off-shell
Ward checks at exact D. The normalized spin-density contraction retains
integrated tagged momenta in D dimensions. Eight generated-current checks,
eight spin-tensor checks, and 22 project-card checks pass. This does not yet
constitute a complete SIDIS result.

Observed-gluon annihilation Born normalization improved from 16.63 s to
5.65 s by simplifying the complete sum once. The pure-gluon Born dependency
is still being profiled; no completed optimized gg timing is claimed.

## 2026-09-08: collinear benchmarks toward integrated SIDIS (in progress)

Distinct-flavor annihilation NLO UU and incoming LL are generated from cards
in 149 s and 161 s. All 32 UU INCNLO comparisons and four exact LL=-UU
identities pass. Quark-gluon observed-quark/gluon UU/LL runs are in progress.
The shared Born simplifier now handles the observed-gluon dependency without
the previous memory exhaustion; flavor enumeration rejects incomplete bases.

Joint normal-crossing endpoint subtraction has exact regulated-moment tests.
The current/measurement interface, tensor distribution result adapter, deeper
NLO epsilon windows and complete SIDIS NNLO RR/RV/VV and factorization are
still required. No complete SIDIS NLO or NNLO result is claimed.
See Design/CollinearBenchmarkCampaign_2026-09-08.md.

## 2026-09-08: code cleanup and five complete NLO results

- Removed 142,319,587 bytes / 2,265 old NLO result files and retired 13
  data-dependent replay tests. The audit covered all 171 manifest modules.
- Consolidated polarization declarations, distribution algebra and result
  assembly; removed the old coefficient reader and four unused definitions.
- Regenerated full qqprime NLO for UU, incoming LL/TT and LL/TT spin transfer
  from incoming A to the observed quark. Five integral-free Mathematica hard
  functions occupy 42,461 bytes total; fresh runs agree exactly with the
  previously validated results.
- Fixed finite zero-prefix tails, order bounds for analytic sums, and
  context-preserving record storage. Intermediate dimensional shifts retain
  undecided terms rather than repeatedly proving zero.
- All eight local workers now connect using small startup batches. The
  profiled hard TT interference went from over 13 minutes to 34.52 seconds.
- Checks passed: 244 unit assertions, 53 reference checks, 88 spin/scale
  checks. The full finite TT spin-transfer coefficient has no independent
  complete external reference yet. GPT-6 Pro reviewed the polarized PDF/FF
  schemes and independent helicity/soft/Born constraints.

See [the cleanup report and result files](Design/CodeCleanup_2026-09-08.md).

## 2026-09-08: project/order/channel cards and common results

- Active projects: ppHX_UU_NNLO, ppHX_LL_NLO, ppHX_TT_NLO. Root card.wl
  holds shared physics. NLO/qqp-qqp has exactly Real, Virtual, Counterterm
  cards; separate LO channel cards supply qqp and (UU/LL) qg dependencies.
- Counterterm cards name LO files relative to Cards and declare epsilon
  ranges. Effective finite schemes are resolved before channel enumeration.
  Finite NLO requires Born through epsilon one; higher Born requests are
  computed explicitly, and insufficient stored orders fail.
- Physical output uses FeynFacet-PartonicResult across orders. Coefficients
  have the same delta/plus/regular fields, explicit epsilon coverage, density
  normalization, dimensional prefactor and endpoint basis. LO files are
  consumed directly by counterterms. No old result conversion is provided.
- Fresh full NLO regeneration: UU 135.75 s, LL 150.49 s, using 8 subkernels
  for amplitude generation. TT regenerated all 25 real and 11 virtual pairs,
  then exact-zero assembly. These are complete workflow times, not DE times.
- Independent NLO checks: 53/53 (17 exact Vogelsang LL identities, 32 UU
  INCNLO values, four TT coverage/zero/control checks). GPT-6 Pro reviewed
  channel/card design and the LO support Jacobian and epsilon requirement.
- Old three project trees are in Archive/ProjectLayouts/2026-09-08.
  Historical tests explicitly reference frozen archive data. Source references
  are in External/References/ppHX_NLO; production never reads them.
- NNLO DoubleReal.wl consolidates gluon and ghost components. Geometry input
  is under NNLO/qqp-qqp/Geometry. No full NNLO regeneration was launched for
  this change, and bare double real is not a complete NNLO hard function.

See [cards and results](Design/ProjectCardsAndResults.md).


## One compact-cut convergence certificate — 2026-09-08

`Integrals/Convergence.wl` now owns the single mass-deformation convergence
proof consumed by ordinary-i0 removal, cut-integral Laurent bounds and
dimensional recurrences. The independent unit-cut prescription proof was
removed; `Prescriptions.wl` contains scope checks and the pre-IBP adapter.
Unit, doubled and higher finite positive cut powers use the same criterion.
Symbolic domains must prove the physical inequalities and nonzero external
denominators. Generic scope does not imply observed-endpoint distribution scope.
GPT-6 Pro review exposed a symbolic-coordinate exclusion and a broken affine
guard. The fallback now uses independent loop scalar products, checks real
coefficients and off-shell cut consistency, and retains redundant factors.
These cases have explicit positive and negative regression tests.

All 345 retained NNLO masters (including 86 doubled cuts), all 91 generic family
templates, and the twelve UU/LL NLO real-master entries pass. A fresh hard NNLO
pair {27,24} takes 50.18 seconds and preserves its exact coefficient expression,
topology definitions and finite-regulator propagator identities.
The shared-certificate, cut-bound, dimensional-recurrence, representation,
AMFlow-interface and package-entry tests pass 135 assertions.
See the process-owned Results/Validation/SharedConvergence_2026-09-08 reports.

## Retrospective causal audit — 2026-09-08

No unjustified ordinary-i0 removal was identified in the computed NLO inventory
or the 345 retained NNLO double-real masters. All 259 unit-cut masters pass
the new argument. All 86 doubled-cut masters pass the older cut-mass-deformation
argument already used for Laurent bounds; verified GPT-6 Pro review confirms
that its uniform finite-normal-derivative bounds justify the ordinary-i0 limit.
Their 311 witnesses are algebraic causal-cone/rank proofs, and their hypotheses
were checked across the generic physical region. Missing support in the newer
checker must not be confused with absence of this older justification.

NLO real masters all have unit cuts; virtual causal phases are retained.
A separate source-level test-function argument covers the declared recoil
endpoint and its delta/plus terms. AMFlow agreement alone remains insufficient
to establish prescription independence. No numerical masters were recomputed.
See [the inventory, proofs and limits](ppHX_NNLO_DoubleReal/Results/Validation/PrescriptionAudit_2026-09-08/README.md).
The consolidation described above replaces the narrower implementation documented
in the earlier development entries below.

## AMFlow real-emission prescription correction — 2026-09-08

AMFlow phase-space loops use Prescription -> 0; retaining an unresolved
ordinary i0 symbol is not an AMFlow evaluation fallback. The exporter now
rejects explicitly retained real-emission prescriptions in active ordinary
slots instead of silently discarding them. Bare families deliberately defined
in the no-prescription convention and dotted cuts remain supported; their
physical equivalence to a differently prescribed source is a separate question.
All 11 focused interface checks pass without numerical integrations.

## Hermitian interferences and ordinary-i0 certificates — 2026-09-08

The production queue and Born assembly now calculate independent Hermitian
interferences and reconstruct the reverse physical contraction before normalized
integral measures. Matching 36-diagram sides need 666 direct contractions,
instead of 1,296; both oriented artifacts are retained and summed once.
Complex scalar parameters, virtual-loop exchange and explicit SFAD eta reversal
are supported. Unequal diagram sets/orders retain their complete rectangle.

A whole-term undotted massless phase-space convergence certificate now checks
the actual transverse Gram measure, compact physical geometry, cut Jacobian,
polynomial numerator and all positive ordinary denominator signs. It permits
ordinary-i0 removal before generic-kinematic real-radiation partial fractions.
Source prescriptions and the source certificate remain in topology records.
Dotted masters and observed endpoint distributions are not automatically
certified. Explicit endpoint-scope requests reject the generic certificate.
Uncertified Baikov expressions retain finite eta, and fallback partial-fraction
identities must pass a finite-regulator check. This also exposed and fixed an
actual overall-sign bug in the two-body angular integral evaluator.

Fresh UU/LL/TT campaigns, all 53 external reference checks, all 25 UU
full-grid-versus-Hermitian pair comparisons and exact complete hard-function
comparisons pass. One hard NNLO pair produces both orientations in 79.03 s,
with the derived {27,24} expression exactly matching its saved independent
calculation. This is not a full NNLO regeneration or a claim that total time
halves. Verified GPT-6 Pro reviews cover the construction and the causal
fallback. See [scope and implementation](Design/HermitianInterferencesAndPrescriptions.md)
and [validation](ppHX_NLO_qqprime/Results/Validation/HermitianInterference_2026-09-08/README.md).

## Complete NLO qqprime campaign (2026-09-08)

## Pre-master optimization and denominator audit — 2026-09-08

General diagram reuse, scalar-declaration cache preservation, and closed-trace
ordering reduce two hard NNLO pre-IBP pairs from 76.98/80.41 s to 49.19/50.79 s
(one core, excluding startup). Chiral traces retain the original contraction
order after a measured regression. Fresh coefficient reconstruction improves
45.72 → 10.43 s with exact equality. Full NLO UU/LL/TT regeneration now takes
138.88/160.26/24.56 s, versus the saved 229.46/243.36/40.91 s baselines.

The massless phase-space theorem survived independent gpt-6-pro review. Fixed
an actual shifted-propagator false acceptance, retained signed scales, and
restricted the check to positive ordinary indices with integer/cut validation,
post-shift and final-master checks. Maximal Kira sectors remain separate.
This is a geometric sign criterion, not an endpoint convergence or i0-removal
certificate. Native Kira threads are configurable; NLO defaults to one.

All 109 focused assertions and 53 external NLO checks pass. The full NLO hard
functions, fresh coefficient expressions and tested NNLO pair integrands are
exactly unchanged. All 347 physical + 27 ghost stored terminal masters pass
the strengthened support check. Temporary profiling work was removed. See the
[report](ppHX_NLO_qqprime/Results/Validation/PreMasterOptimization_2026-09-08/README.md)
and [mathematical scope](Design/PhaseSpaceDenominatorSigns.md).

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


## Shared workflow cleanup — 2026-09-10

The card/request/Born-dependency code now lives in Projects/Contributions.wl.
NLO and NNLO share structural result indexing and finite finalization, with
separate exact and numerical pole evidence. Three Python entry points share
Scripts/wolfram.py for CPU allocation, completion checks and owned-process cleanup.
The resolved request uses the actual perturbative order; positive epsilon slices
retain their finite Laurent lower bound.

GPT-6 Pro reviewed the invariant boundaries in record 38. Validation passed
97 Wolfram assertions, five Python tests and the 86-file saved-result audit.
Representative ppHX and SIDIS NLO reassemblies agree exactly; SIDIS comparison
uses the charge values explicitly declared in BenchmarkParameterRules.
The saved physics results were not rewritten. These cleanup changes are local.

Details and logs:
Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/Validation/Cleanup_2026-09-10/Report.md.
