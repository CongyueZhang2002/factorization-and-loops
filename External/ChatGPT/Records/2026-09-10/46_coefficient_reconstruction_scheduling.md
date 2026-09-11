# Coefficient reconstruction scheduling

Model: verified `gpt-6-pro`, request `923ba345-ae1f-4b35-b82c-5a1c789249e1`, HTTP200.
Conversation: `6aa2eb2d-5588-83e8-bf9d-d35cd8d66f3b`.
Source: [attached implementation](Sources/46_coefficient_reconstruction_schedule_sources.txt).

## Question

Review a general production performance decision, continuing review45. Use GPT-6 Pro. Repo baseline https://github.com/CongyueZhang2002/factorization-and-loops/tree/8bfd19c584a5f79a2090def3043bc1f55a03ca5d ; attached live source overrides baseline. We are regenerating card-driven ppHX UU NNLO double real (two gluons minus ghosts) with at most8 CPU cores. No change to physics is allowed.

Fresh reduction complete: 55,277 targets,345 terminal masters. Wolfram normalization/emission has completed all256 input partitions in roughly an hour beyond initial input preparation. Proposed exact signature-pair memoization is queued for an identical-output benchmark; current process used unchanged baseline emission.

Native full-rational reconstruction is now running with8 threads, ~790% CPU,1GB RSS,no swap. Its exact saved trace can be reused. Trace build67s. All345 output expressions total852,199,720bytes. The largest three are377,891,991;200,724,350;69,005,090bytes. The next largest is15,776,908bytes. Shared trace after optimize/finalize:783MB instruction storage,2.78MB register/memory requirement; gzip215,471,966bytes. At8.6min FireFly had13,754 probes in current first prime field;206/345 outputs require next prime,0 fully done. We have not stopped it.

Code has TWO paths: CoefficientSimplification in Coefficients/Reconstruct.wl builds one shared trace then finiteFieldReconstructTrace; public ReconstructCoefficients in FiniteField/Reconstruction.wl already schedules output subsets, supports full rational mode SeriesVariable->None, explicit exact parser/coverage and output assembly. Its current Automatic scheduler bundles ALL individual files <16MiB into one shared group, isolates each larger file; jobs run sequentially, each with requested8threads. Thus here it would have342 shared outputs totaling~205MB and3solo jobs. Normalized expression checkpoint and metadata already exist.

Please assess:
1. Is this worth unifying permanently around the scheduled path? Shared arithmetic and common factors can make a shared trace efficient; dominant-expression size is not necessarily reconstruction complexity. What evidence can we cheaply obtain before any switch?
2. Best general automatic grouping criterion (input sizes, instruction counts, denominator/degree scans, measured per-prime timing) without turning planning/checks into dominant computation?
3. For the current running in-memory full reconstruction, when, if ever, should we stop and reuse checkpoint for subsets, given no FireFly partial state is saved? Prefer letting useful work finish unless a measured alternative is compelling.
4. Examine attached contracts for danger when reusing ReconstructCoefficients from the normal driver: exact full-D output vs epsilon truncation, signature/alias/metadata identity, same assembly normalization, completeness, output paths/checkpoint binding, finite-field verification. Identify minimal refactor and targeted validation.
Return a concise recommendation, including what NOT to infer from first-prime coverage. Do not invent speedup ratios or suggest manually correcting coefficient formulas.

## Pro response

Unify the reconstruction executor, but retain both shared and subset schedules. Do not stop the current run on the evidence given, and do not make the present 16 MiB heuristic the permanent performance policy. The attached scheduled path is useful infrastructure, but it is not yet a safe drop-in replacement because its checkpoint binding is weaker and its defaults change the mathematical output.

1. Performance decision: sharing versus independent reconstruction difficulty

The relevant tradeoff is approximately

T
plan
	​

≈
g
∑
	​

(T
build,g
	​

+N
g
	​

t
probe,g
	​

+T
interpolation,g
	​

).

Splitting can lower probe-evaluation cost for easy outputs; sharing can eliminate repeated arithmetic and reuse evaluations. Neither expression bytes nor register storage determines N
g
	​

.

There is a concrete reason to investigate subsets: upstream ratracer’s black-box callback evaluates the complete retained trace on each call, not merely outputs still requiring reconstruction. Whether this materially dominates your run requires a profile of the pinned executable. 
GitHub

Do not interpret “206 require the next prime, zero fully done” as a completion percentage, a stalled reconstruction, or evidence identifying the hard outputs. First-field interpolation and reconstruction over Q are different stages; subsequent fields can reuse learned structure but still require coefficient lifting and validation. The counters provide neither total remaining probes nor a reliable ETA. 
arXiv

Your reported CPU/RSS figures provide no memory-pressure reason to interrupt. Reassess using subsequent field transitions, probe rates and—where available—time spent evaluating traces versus interpolation. A prime boundary is an observation point, not a saved reconstruction checkpoint.

Stop only for an actual operational problem or a measured alternative whose restart-to-completion cost convincingly beats continuing. The normalized checkpoint preserves the hour of emission, but not the ongoing FireFly interpolation work.

2. Automatic grouping: cheap proposals, measurements where available

The current scheduler really does place every subthreshold file into one group, without a total bundle limit. Thus its “small” group can itself be large; this is a heuristic, not a complexity classifier. 

pending_coefficient_reconstruct…

The smallest useful improvement is a configurable total bundle budget, with coarse size bands and outlier isolation, while retaining explicit "Shared" and "Solo" overrides. Treat this as a conservative planning fallback, not an asserted optimum.

Prefer existing optimized instruction counts and measured evaluation costs over text sizes. Reuse degree/factor-scan information already produced by reconstruction when available; do not run whole-output Together, denominator factorization, or a second expensive scan solely to plan jobs. Historical per-prime timing is useful only for reasonably comparable outputs/settings—not as a universal first-prime-to-total multiplier.

Cheapest meaningful experiment: at the next idle slot, compare the saved full trace with the four proposed output projections: optimized instruction storage, evaluation cost and exact modular output agreement. Upstream ratracer exposes keep-outputs, optimize, stat, measure and evaluate-modular; verify support in your pinned binary. Preserve output names and actually remove dead code after projection. This avoids reparsing the expression files or launching disposable full reconstructions. 
GitHub

Its built-in measure is an evaluation-cost screen, not an eight-thread --inmem end-to-end benchmark. Even a favorable result does not determine the unknown probe counts. 
GitHub

3. Contract issues to fix before unification
Full rational mode must be explicit

ReconstructCoefficients defaults to "SeriesVariable" -> Automatic, resolving to epsilon, with "SeriesOrder" -> 5. Calling it with defaults would silently replace full regulator dependence by a finite expansion. The normal driver must force "SeriesVariable" -> None and reject series blocks. 

pending_coefficient_reconstruct… +1

Also avoid its default writing/cleanup behavior inside another driver: it constructs the final coefficient record, writes CoefficientResult.wl, and may delete working files. If temporarily calling the public interface, use "ResultFile" -> None and "KeepWorkingFiles" -> True, and do not run the final constructor again. 

pending_coefficient_reconstruct…

Trace/result reuse needs an actual job binding

reconstructionRunJob reuses a trace merely when the trace and output-list files are nonempty. It does not compare that output list with the requested subset. Completed-job reuse checks a DONE marker. Moreover, "Resume" -> False does not disable the independent trace-reuse test. 

pending_coefficient_reconstruct… +1

A constant job name such as "shared" can therefore refer to different subsets or changed expressions. Coverage may catch some collisions late, but unchanged filenames with changed contents can pass.

Add one bound job specification: checkpoint/content identity, exact ordered output IDs, alias mapping, full-versus-series mode and any series variable/order. Reuse only on a match; otherwise use a separate job location. Bind the executable/build as well. This also applies to the existing shared builder, whose reuse test checks only output count. 

pending_coefficient_reconstruct…

Do not rediscover physics inputs from a directory

The scheduled reader checks manifest format but omits the checkpoint version/source/Kira checks performed by finiteFieldRestoreTraceCheckpoint. It also rediscovers pair files and the card, then computes a current physical factor without comparing it to the emitted checkpoint’s factor. 

pending_coefficient_reconstruct… +2

Pass the normal driver’s already validated traceData, metadata, context and source data into the common executor. Preserve the ordered (output, master, signature) associations and full-context symbol mapping. Validate normalization-relevant context against the checkpoint; source/Kira identity alone does not bind changed late card settings.

Require both complete input-target coverage and complete output-column coverage, including remainder outputs. The existing missing-column rejection is useful and should remain; it is not a substitute for CompleteTargetSet and processed-target checks. 

pending_coefficient_reconstruct… +1

Concrete parser bug: a bare alias is not decoded

In reconstructionParseBlock, alias discovery uses

Wolfram Language
Cases[expression, ..., Infinity]

which excludes level zero. A block consisting solely of an alias symbol passes the rational grammar, but produces no reverse rule and remains an alias. Use {0, Infinity} and reject surviving aliases after decoding. The old parser scans a list of expressions, so this particular root-level regression is introduced by parsing blocks individually. 

pending_coefficient_reconstruct… +1

 
Wolfram Documentation Center

Exact parsing is not reconstruction verification

The parser/coverage checks establish admissible exact expressions and complete accounting, not equality to the input black box. Additional slice verification defaults to zero. Preserve the existing backend acceptance, and validate the refactor against the original trace at fresh nonsingular finite-field points; report such checks as probabilistic validation, not symbolic proof. 

pending_coefficient_reconstruct… +1

4. Minimal refactor and acceptance test

Extract schedule → run → parse → ordered rational columns into one executor accepting validated in-memory inputs. Let "Shared" be a one-job plan. Keep the normal driver’s existing finiteFieldAssembleResult, coefficient constructor and writer exactly once; do not inherit directory rediscovery or the scheduled path’s separate assembly-repair filter. The current parser already reads the explicit result files of its own schedule rather than globbing stale neighbors—retain that behavior. 

pending_coefficient_reconstruct… +1

Use a compact shared-versus-subset regression containing a bare alias, multiple signatures for one master, an exact-zero column and a nonzero scalar remainder. Require identical mathematical output and normalization metadata; reject duplicate/missing blocks, an incomplete target checkpoint, changed aliases/context, and stale jobs with the same name but different contents. Permit timing and per-job provenance to differ.

Recommendation: keep this reconstruction running; unify execution after those contract fixes, and let measured trace-sharing costs—not the three largest text files alone—determine the next scheduling policy.
## Subsequent local observations

A21-second single-CPU diagnostic under concurrent production load compared the
saved full trace with the342 outputs below16MiB, preserving their names and
removing dead code. Instruction storage decreased783MB to182MB. The built-in
measure reported0.6335s for one full evaluation versus0.1571s averaged over seven
subset evaluations. These noisy evaluation-cost measurements do not predict
reconstruction probe counts or end-to-end speedup; no production restart followed.
Process-owned logs are in Regeneration_2026-09-10/NativeScheduleBenchmark.

The bare-alias parser correction and the matching level-zero variable-registration
correction have been implemented; all seven regression assertions pass.
The record-merging regression also exposed and fixed a failure-valued callback
branch for malformed input; all six record-merging assertions pass.
Scheduler unification and stronger job/checkpoint bindings are not implemented
or claimed complete in this record.
