# AMFlow reduction and completed-system reuse

## Question

Follow-up after native rollout: native numerical phases improved 2.70–3.13x, all77 exported coefficients match20digits acrossCF253/240/198 and five freshly computed CPP boundary-order arrays exactly matchMMA. Pool nativeCF308 and otherspass. MPSolve-j1, actualCPP/ownedLink assertions, cleanup inside InheritedBlock and BeginPackage isolation fixed. User asks further optimization because stillslow.
New profiles: CF308 target reduction59s +auxDE construction233s +numeric78s; CF31170+278+265; CF31969+310+241; simpleCF36031+102+15. Source BlackBoxAMFlowQuadratic initial {masters,rules}=If[$SkipReduction,{jints,identity},BlackBoxReduce[jints,{},dir0]]. Even request2 genuine stored canonical masters expands into25 initialAMFlowmasters. Later AMFSystemDifferentialEquation always BlackBoxDiffeq on preferred, asserts ContainsAll returnedbasis preferred and abortsifnot; it doesn'totherwise skipauxDE reductions. All our requested inputs ARE subsetsof canonicalIBP masterbases, notarbitrarytargetintegrals.
I propose enabling upstream SkipReduction=True only for complete-master references, with one guarded fallback to False if auxiliary preferred-master closure fails. This skips redundant initialtargetreduction and mayavoid needlesslyevaluating everyAMFlowbasis element; etaDEclosurestillautomaticallyconstructed and independentboundaries. Is this mathematicallysound and bestnextstep? Any caveat for doubledcuts/numerators/basisdifference/Kira preferredmasters? We'll compare representative fresh reference againstretainedMMA25digitdata before enabling. We could alternatively set UseMaximalCut=False to avoidmany repeatedKira launches (notyetprofiled).
Also two oldMMAfamilies CF259/CF303 aretail: CF259system6 has8/17eps samplesdone after~35min, withlarger70-master system1 stillahead; CF303 juststarted63-master finalsys1. User explicitly asks furtheroptimization so preservingoldMMAindefinitely is poor. I propose migrate toCPP now, retaining complete AMFlow system solutions with verified script-generated config/epsgrid/inputfiles, and/or preserving alreadyfinishedsubsystems while recomputing currentincompleteone. No productionDEorboundaries usedinAMFlow. Could a strict on-disk cache for AMFSystemSolution use exact input equality (diffeq,basischange,boundary,boundarymi,pattern,direction,epslist,WorkingPre,XOrder etc), plus shapes/numberchecks, independentofMMA/CPPbackend? Existing completedsystems have scripts/inputfiles andsolution andcan beacceptedifdescriptorreconstructedfromtheiroriginalscripts. Needanswerfocused, notabroadredesign.

## Pro response

Yes. With your stated guarantee that the inputs are individual scalar IBP masters, SkipReduction -> True is mathematically sound and the best low-risk optimization for queued families. Migrate CF259/CF303 to CPP now, but keep their existing target lists and symbolic system trees unchanged. Treat those as separate changes: reduction avoidance for new work, backend-only migration for the existing tail.

The important limitations are that skipping the initial reduction does not eliminate necessary auxiliary-DE masters, and backend-independent solution reuse requires the actual numerical inputs—not just matching system IDs or configuration names.

1. SkipReduction: sound, with the proposed fallback

Upstream explicitly describes admissible inputs as a basis or a subset of one. You do not need to supply all 25 masters merely because the ordinary reduction returned that basis. 
GitLab

The mathematical distinction is:

requested integrals J⊆auxiliary basis M,∂
η
	​

M=A(η,ϵ)M.

Provided the independently constructed auxiliary system contains the requested integrals and supplies its own boundaries, the preliminary representation of J in another ordinary IBP basis is unnecessary. Keep the existing AMFlow endpoint extraction; this argument does not replace it with a naive η→0 limit.

Do not interpret this as a two-dimensional DE for two requested masters. Their auxiliary closure may still require 25 or more components. The potential additional saving is avoiding systems and outputs introduced solely by the initial basis expansion—not removing components needed by the actual closure.

Three implementation conditions matter:

Use the exact scalar-integral identities and conventions already established. A normalized linear combination called a “canonical master” would require its transformation; your stated individual-integral inputs avoid that issue. Preserve propagator ordering, dimension, cut conventions, and normalization.

Require containment, not equality, of the auxiliary basis. Kira can supplement a preferred list; its completeness-style check_masters facility rejects additional masters, so do not impose that against your small requested subset. Additional auxiliary masters are legitimate. 
arXiv

Fallback only for the identified preferred-master inclusion failure. Restart once with SkipReduction -> False using clean attempt-local setup. Do not convert arbitrary numerical failures, crashes, or interrupted writes into this fallback. A changed starting basis can produce a different system tree; reuse only artifacts whose actual inputs match.

Doubled cuts and numerator masters are not, by themselves, exclusions. Keep their original index vectors and cut normalization. In particular, do not “simplify” doubled cut powers to unit powers. Kira’s cut-sector convention sets integrals with a nonpositive power on a required cut propagator to zero; numerator powers in other slots are a separate matter. 
arXiv

From your four profiles, the removed initial stage represents 229/1751 ≈ 13.1% of measured time, ranging from 11.1% to 20.9% per family. That is worthwhile even without a smaller system tree, but total savings could differ because the preferred basis changes subsequent work.

For qualification, use one fresh small-subset case that previously expanded substantially, plus one structurally different case covering the relevant dotted/numerator inputs. Compare every requested fitted coefficient against the retained MMA references and record auxiliary-system sizes. No additional symbolic independence proof is needed for inputs already established as masters.

2. UseMaximalCut -> False: benchmark next, not enable blindly

The upstream Kira interface uses this option for master discovery: the maximal-cut route performs separate sector investigations, whereas the alternative discovers masters through the combined route. The subsequent derivative reduction still exists. This option is not an instruction to remove the physical cuts from your reference integral. 
GitLab
+1

At one core, repeated launches are a plausible cost, but larger combined reductions could outweigh the savings.

Test it on one representative auxiliary-DE construction in a fresh directory, keeping the preferred inputs and physical cut metadata fixed. Measure complete construction time and resulting basis, not merely launch count. Keep it separate from the first SkipReduction qualification so the performance difference remains attributable.

Your auxiliary-DE construction already accounts for 52.7% of those four profiles. Thus this deserves the next targeted benchmark; it does not yet justify a campaign-wide switch.

3. Migrate the two MMA tails now

Even discarding the incomplete current system can be advantageous. With original whole-system MMA cost T, completed fraction f, native speedup r, and restart overhead H,

T
continue
	​

≃(1−f)T,T
restart
	​

≃T/r+H.

Restart wins when

f<1−
r
1
	​

−
T
H
	​

.

Your measured r=2.70–3.13 gives a zero-overhead threshold of 63.0%–68.1%. CF259’s 8/17≈47.1% is below that threshold, assuming roughly comparable sample costs; its larger pending system strengthens the case. CF303 has just started its large final system.

Preserve completed subsystems, restart the incomplete system in CPP, and retain the original symbolic setup. Stop the old owner and its descendants before allowing the replacement to write into the same workspace. Snapshot the retained artifacts before regenerating scripts.

Do not build per-sample recovery machinery merely to save those eight samples. Reuse them only if complete, structured per-sample outputs already exist. Upstream’s generated script writes the system solution after assembling the full sample grid; progress messages alone are not checkpoints. 
GitLab

4. Backend-independent completed-system cache: yes, with four requirements

This is a valid result cache, not a claim of bitwise equivalence between MMA and CPP. A completed MMA subsystem may supply boundary values to a CPP parent. Keep its original numerical values and precision; continue the unchanged final coefficient comparison.

Match the complete ordered numerical problem

Use the exact saved inputs you listed, adding the ordered master list and output identification. Preserve ordering throughout matrices, basis transformations, boundary rules, and epsilon samples. For a conservative first implementation, also retain the original global/local integral configurations and preferred-integral mapping.

Capture effective options, including defaults—not just explicitly written settings. DESolver has numerical controls beyond WorkingPre and XOrder, including chopping, rationalization, expansion-learning/testing, and continuation settings. 
GitLab

Exclude only the approved backend choice from the compatibility comparison. Retain backend/build information as provenance. Do not discard other differences merely because both scripts call AMFlow.

“Exact equality” must include numerical representation

SameQ is not a byte-exact test for approximate numbers: Wolfram explicitly allows real numbers differing in their last binary digit to compare identical. 
reference.wolfram.com

For this migration, byte equality of the saved input files plus a resolved-options descriptor is simpler than designing a canonical numerical-expression encoding. False cache misses caused by formatting differences are acceptable. Do not introduce tolerance-based boundary matching to recover hits.

Consequently, recomputing a child with CPP may change its last digits and invalidate a cached parent under strict equality. That is expected. Preserving the completed MMA child’s original values avoids this unnecessary invalidation.

Reconstruct provenance before anything is overwritten

Importing a descriptor from original scripts and input files is acceptable when those files belong to the same successful computation as the solution.

There is a concrete hazard: upstream writes the epsilon list and regenerates numerical scripts before execution, and does not generally skip completed nontrivial systems automatically. A failed rerun can therefore leave a new script beside an old solution. 
GitLab
+1

Freeze the original files first. Require an unambiguous association with the completed run; ambiguous artifacts should miss the cache.

Preserve the disk contract and reject malformed outputs

The smallest hook is likely your existing generated-script runner: after current inputs are prepared, compare the descriptor and either restore the cached solution file or execute CPP. This avoids replacing the surrounding system orchestration.

Check exact expected keys, full grid lengths, rectangular shapes, absence of unresolved expressions, and finite numerical entries. NumberQ alone is insufficient: Wolfram documents that it can return True for Overflow[] and Underflow[]. 
Wolfram Documentation Center

Commit new entries only after successful completion and output validation, preferably by atomic publication of a completed entry. These checks establish cache integrity, not numerical accuracy; retain the existing AMFlow configuration and final comparison for the latter.

Recommended order: migrate CF259/CF303 with completed-system reuse; qualify SkipReduction for queued families; then benchmark UseMaximalCut -> False on one expensive auxiliary-DE setup. No change to precision, epsilon demand, physical prescriptions, or independent AMFlow boundary generation is warranted.

## Correction after inspecting the full cache

CF259 has 70 masters in its currently running system 6, not in system 1. Systems 1–4 and 7–9 already have complete sampled solutions. Only the incomplete system must be recomputed during migration. Pro’s comparison still favors migration at the observed 8/17 completed samples, but there is no additional unsolved 70-master system afterward.
