# GPT-6 Pro review: scheduled reconstruction and endpoint groups

Review implementation following51. One attached snapshot contains the new common scheduled reconstruction executor, literal-partition adapter, unified exact/Laurent result assembly, automatic endpoint frame grouping, and contribution labels in scalar campaigns.

Current real progress:343 ordinary columns completed in5385s driver wall on7cores; exact exceptional pieces203s on1core; first regular series984s on1core; last regular series still running.9 coefficient-order assertions (latest domain field fix) and9 Python denominator/partition tests; mixed exact/Laurent result assembly8 tests and endpoint groups8 tests pass. Existing scalar driver12 and relation adapter18 regressions pass. Full91-frame class catalog built successfully. Full real mixed assembly and automatic actual pole-group cancellation still pending.

Please find concrete correctness bugs / unnecessary expensive operations before integration. Focus:
- exact vs finite storage; Gamma signatures stay outside finite coefficient Orders; source manifest/master bindings and literal partition equality;
- ownership: unique all-exact masters move whole; shared masters or masters with finite terms leave finite regular data unchanged and subtract principal parts ONLY from exact terms; removed/added records SourceTermIndex and source recombination;
- regular gauge along divisor, candidate full-row cancellation, and actual saved physical-bound/domain binding;
- duplicate contribution labels versus mathematical family identity.
Do not design a second endpoint engine. Existing DetermineMasterCoefficientEndpointOrders still independently checks complete row times gauge, coalescing divisors, all finite source tails, sufficient orders; final merger verifies whole-master and exact-piece coverage. Its CoefficientRemainderDomainConditions reads Justification.TangentialAssumptions (new source-order module was corrected to use that key).
The supplied catalog frames are accepted source-only data from the previous run, re-matched against fresh physical integral definitions. We will not reuse old coefficient residues.
Return actionable issues in priority order, especially WL scoping/Association/Return pitfalls. Repo https://github.com/CongyueZhang2002/factorization-and-loops; working changes not pushed.

The exact/Laurent split and the exact-only pole subtraction are implemented correctly. The remaining problems are in binding, ownership validation and integration—not the common-basis mathematics. I would fix the issues below before the real mixed assembly and automatic campaign. This is a static review; I have not executed the reported regressions.

1. P1: Final coefficient checks scan proof metadata as though it were arithmetic

In finiteFieldAssembleResult, the final momentum, fraction/root and System\Dchecks inspect entireTermsrecords, includingLaurentRemainderClass.Justification. A valid justification containing a source topology, a dimension declaration D`, or the original momentum symbols can therefore reject a perfectly valid coefficient. It also makes these checks traverse potentially large provenance records. 

52_scheduled_and_endpoint_groups

Fix: construct an arithmetic view containing only each term’s PreFactor and exact coefficient or finite Orders values. Run the physical-variable checks on that view; validate and preserve the justification separately.

The preceding assembly is correct: the analytic signature multiplies PreFactor, not finite Orders. Do not “fix” the metadata problem by discarding the tail certificate or moving Gamma factors into the Laurent coefficients. 

52_scheduled_and_endpoint_groups

Test: assemble a finite term with clean rational Orders, a Gamma-valued signature, and a valid justification retaining D and source momentum definitions. It must preserve the justification and pass arithmetic validation.

2. P1: Label collisions can remove contributions before the coverage checks

There are two concrete collision paths.

Endpoint grouping: pole contributions use keys such as "PoleGroup0001", while ordinary contributions use the frame name as their key in the same inputs association. A valid saved family/frame named "PoleGroup0001" can overwrite the previously constructed pole contribution. 

52_scheduled_and_endpoint_groups +1

The local coverage checks do not detect that loss. removed and added receive the same record together, and recombination checks the residual against removed, not against the actual emitted CoefficientInputs. For whole-moved masters, remaining is simply assigned the original coefficient, making that particular recombination check tautological. 

52_scheduled_and_endpoint_groups +1

Campaign scheduling: explicit labels are checked for uniqueness, but subsequently generated missing-family jobs are not checked against them. For example, an explicit contribution with mathematical family "CF230" and label "CF17" uses output/CF17; an automatically added missing-input job for family "CF17" uses the same directory. Workers can then overwrite one another’s summaries and campaign results. 

52_scheduled_and_endpoint_groups

AssociateTo updates an existing key rather than rejecting a collision. 
Wolfram Documentation Center

Fix: enforce uniqueness at every contribution insertion, then validate the complete job list’s labels and expanded output directories, including preflight jobs. Derive added-piece and whole-owner accounting from the finalized CoefficientInputs, rather than maintaining two identical bookkeeping lists.

The independent final merger remains valuable, but it should not be the first place a dropped group is discovered.

3. P1 integration gap: An order plan is visibly bound only by path and source GLI

The executor checks the source trace-manifest hash, then accepts a regular-source order plan by status, expression-file path and source master identifier. It does not visibly compare the order plan’s source-content identity or its bound master definitions, normalization/signature and domain with the data being reconstructed. 

52_scheduled_and_endpoint_groups

A concrete failure scenario is a new valid literal partition written to the same paths: Regular + Exact still equals the original source, but the new regular part no longer satisfies the old tail certificate. The Python literal-equality check and the displayed path/master checks can both pass.

Fix: consume the existing order-plan binding, including the regular-source content identity and bound definition/normalization/domain inputs, before launching or reusing a series job. Also bind the supplied data to the manifest whose hash was checked. No reconstruction or new endpoint proof is needed.

This finding is conditional on the omitted reconstructionCollectScheduledJobs implementation: if it already performs the complete binding check, reuse that validator here rather than duplicating it. The Python verifier itself is not included in this snapshot; the displayed adapter delegates literal equality to it. 

52_scheduled_and_endpoint_groups

Separately, add a cheap range check for every OutputMetadata["MasterIndex"]. The assembler presently groups arbitrary indices, consumes only 1..Length[Masters] and 0, and supplies exact zero for an unrepresented master. An out-of-range index can therefore silently discard a parsed column. Validate metadata against the bound manifest before using this legitimate zero-by-emission fallback. 

52_scheduled_and_endpoint_groups

4. P1 integration gap: The selected accepted frame is not bound to the frame subsequently loaded

BuildEndpointCoefficientCatalog checks record types and vector lengths, but the generated coefficient input does not retain a binding to the particular accepted Endpoint, Bounds and physical matching records used for selection. It retains the basis and SourceDifferentialSystemFile, while the campaign separately chooses an endpoint directory by family name. 

52_scheduled_and_endpoint_groups +2

The independent planner can recompute cancellation against the loaded gauge, but that does not establish that a same-sized bound vector belongs to that gauge, ordered basis, physical seed or tangential domain.

Fix: carry the accepted frame-record identity—or its existing immutable references—and compare it with the actual loaded records before planning. Bind the ordered basis, coordinate/regulator convention, gauge, physical bounds/matching and domain together. This is a record-correspondence check, not a request to redo the accepted DE or gauge proof.

Also make the frame-key contract explicit. The code sets output "Family" -> name, where name is the catalog association key. Either require that key to equal the mathematical family identifier or store FrameID separately. A registry alias must not redirect the campaign to another family directory.

The apparent source/target alignment mismatch is intentional

After checking the downstream driver, I would not change aligned[[row]]=entry merely because entry["Master"] remains the source GLI. The driver aligns using the separately declared OriginalMasterIntegralBasis; the endpoint planner uses source Master identifiers for contribution ownership. Renaming that field blindly would damage coverage accounting. Preserve the explicit source-to-target embedding and validate its positional correspondence. 

52_scheduled_and_endpoint_groups

5. P2: One definite scoping error and one campaign-default mismatch

result is missing from the executor’s Module locals. Assignments at lines 74–77 therefore write the surrounding private-context symbol and retain the assembled result outside the invocation. Add result to the local list; test that a pre-existing value of that private symbol is unchanged after execution. 

52_scheduled_and_endpoint_groups +1

 A Module localizes only its declared variables. 
Wolfram Documentation Center

RequireAllAcceptedFamilies -> True is unsuitable as the default for a generated grouped campaign using the full frame catalog. Unused accepted frames are alternatives, not necessarily missing physical contributions. The current code adds missing-input jobs for every unused accepted family. For this generated workflow, use the exact generated contribution set, with final master/piece coverage enforcing physical completeness; either narrow the accepted manifest or explicitly disable this old family-enumeration requirement. 

52_scheduled_and_endpoint_groups +1

I do not find a new Return[Nothing] leak in the displayed scheduling code: it uses conditional Nothing directly.

6. Confirmed avoidable expense

Cache the coefficient-independent gauge-divisor classification per bound frame. Currently the entire gauge is rescanned for each candidate in each pole group. This is invariant under changing the coefficient row once the frame, regulator and chart are fixed. Keep fresh full-row cancellation and the final planner checks unchanged. 

52_scheduled_and_endpoint_groups

Batch rational row cancellation. endpointGroupCancel /@ row invokes the backend separately for each entry. Reduce the row into one shared rational coefficient field and call CancelRationalExpressions once on the list, preserving the same exact acceptance criterion. The existing code already exposes a list-valued backend interface. 

52_scheduled_and_endpoint_groups +1

Avoid extracting a principal part from every exact term when the divisor inventory already proves that term does not contain the selected pole. Cache that inventory by exact term/divisor identity. For shared terms spanning several groups, accumulate the exact removed parts and cancel the residual once after allocation, rather than after each subtraction. Preserve original SourceTermIndex throughout. 

52_scheduled_and_endpoint_groups

Also, FrameTimeLimit currently bounds only row cancellation—not gauge classification, principal-part extraction or earlier residual cancellations. Treat it as a cancellation limit, or bound the whole candidate attempt if that is the intended operational contract.

Integration checks still needed

The snapshot does not contain the current implementations of reconstructionRunSchedule, reconstructionCollectScheduledJobs, reconstructionMergePartitionResults or reconstructionAssembleProduction. I would not infer their behavior from the historical versions.

One small end-to-end fixture should demonstrate that the executor actually launches an exact job and a finite-series job with their respective modes, combines exactly one regular and one exceptional partition per source, preserves a zero finite prefix as an unknown-tail record, and rejects duplicated partition sources. In the displayed executor, the mode overrides are stored on individual jobs while the common options remain full-rational, so the schedule must explicitly honor those job fields. 

52_scheduled_and_endpoint_groups +2

The core ownership operation is right: only exact terms are modified, finite regular terms remain unchanged, and partial records retain the original source-term index. Fix the binding and emitted-coverage checks around that operation; neither a second endpoint engine nor new coefficient-residue mathematics is required. 

52_scheduled_and_endpoint_groups