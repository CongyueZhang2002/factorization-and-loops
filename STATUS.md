# Current status — 2026-09-11

Read [WORKFLOW.md](WORKFLOW.md) for execution directions and the
[ppHX NNLO channel guide](Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/README.md)
for the current result/command map. No owned scientific jobs remain running.
The existing heartbeat is paused. Code, tests and workflow documentation are
versioned together; a Git clone does not include all local Results/vendor data.

The sections below contain the latest accepted ppHX and SIDIS state.
[Superseded running notes](Archive/History/Status/BeforeWorkflowGuide_2026-09-11.md)
are retained only as history. They do not reopen completed work.

## ppHX UU NNLO scoped regeneration and automatic planning complete

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

All upstream work and coefficient reconstruction are complete. The following
are the initial regeneration timings; the subsequent eight-core finite-job
benchmark above supersedes its one-thread performance comparison:
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

## Completed SIDIS NNLO UU/LL

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

The complete collinear benchmark campaign is now complete as well.
The remaining NLO incoming-LL qg external check passes for both observed tags
against pinned public Navis: 80 qg LL coefficient comparisons at ten parameter
points. All 320 UU/LL control and target comparisons pass (maximum relative
difference below 3e-13); 128 overlapping UU comparisons also agree with original
INCNLO. No production correction or fitted normalization was needed.
This is agreement with Navis, not authentication of an original author-code
archive. Pro review 37 and process-owned validation reports record the scope.
The overnight monitor is paused; there are no active production jobs.


## Remaining scope

- ppHX: other NNLO cuts, UV renormalization, PDF/FF subtraction, global analytic
  removal of the retained higher endpoint distributions and extension beyond
  the stated domain are separate work.
- A complete-master AMFlow comparison does not imply that every independent
  boundary-only reference is available. Keep the two validation inventories
  distinct.
- Supported NLO orchestration and retained NNLO phase replay are documented.
  A single fresh card-to-full-result command for arbitrary new NNLO geometry
  is not established; new supported DE/boundary specifications may be required.
- For process-independent improvements, change the reusable framework and
  verify representative complete flows. Do not patch individual final formulas.

See [the roadmap](Goals/README.md) and the project guides. Historical references
to ~/FACET and retired project paths are not writable production destinations.

## Documentation handoff — 2026-09-11

[WORKFLOW.md](WORKFLOW.md) and the linked project/channel guides now contain the
context-free execution directions. The old contradictory running-status
sections were archived. The documented startup and standalone solution-reader
checks pass; the package layout, command examples, driver arguments and local
links were checked without regenerating physics. See
[the audit](Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/Results/Validation/Documentation_2026-09-11/Report.json).
Fresh-clone dependencies and the limits of new-process NNLO automation remain
explicit. The code and documentation are ready for the requested publication
on codex/scientific-terminology-and-math-fixes.

## Result publication and master-count audit — 2026-09-11

The accepted 76,125,796-byte ppHX double-real WXF is now included in the
project's versioned deliverables; its intermediate inputs remain local.
The 86 compact final Result.wl files were already versioned.

A fresh read-back confirms 20 masters in the shared final SIDIS double-real
DE and physical coefficient vector, after the 22-master exact IBP reduction.
The [literature comparison](Projects/SIDIS_UU_NNLO/NNLO/MasterIntegralComparison.md)
distinguishes the published counts of 21, 20 and 18. No full paper-basis
mapping or proof of minimality has been established. This audit did not
regenerate or modify physical results.
