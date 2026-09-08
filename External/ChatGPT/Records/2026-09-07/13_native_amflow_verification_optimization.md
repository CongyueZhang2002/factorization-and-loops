# Native AMFlow verification optimization

## Question

Please review an immediate validation optimization in FeynFacet. User says validation is too slow and should not dominate production. Active run: 91 families, 345 masters, 2220 requested epsilon coefficients at v=1/4,w=1/5, AMFlow refs goal25 and comparison tolerance18digits. Dynamic8 family workers, one core each, no extra Wolfram licenses, generated AMFlow scripts isolated in existing subkernel. Completed 26 family timings sum: AMFlow14320s (91%), physical DE1383s (9%), prep53s. AMFlow median492s; hardest 1500s so far. Existing AMFlow is upstream2.0 with C++ DESolver source, but driver forces MMA and native link is unbuilt. I intend to build upstream native DESolver in an active local runtime copy (legacy FACET untouched), keep SAME eps sample grid, precision218digits, Taylor436 and independent boundary generation, compare native values to existing MMA refs on a few representative hard families, then useCPP for queued workers (healthy running work preserved). No reduction in tolerance or epsilon demand. Thoughts/caveats on native backend correctness, cut prescriptions, thread/process/license isolation and a proportionate benchmark? Is this the best immediate move? Other high-value small changes? Precision218 is not arbitrary: GenerateNumericalConfig uses n=ceil(2.5*order+2*loops), exp=loops/2+goal/(order+1), pre0=max(ceil((n+2loops)*exp),30), working2pre0, Taylor4pre0, extra>=50. Not planning hand-reducing that because clustered positive epsilon fitting needs guard digits. Cache symbolic setup should be reusable by new native runs. There are differing family topologies and some triple-root geometries; don't propose dropping any coefficient or using FeynFacet boundaries in AMFlow.

## Pro response

Yes—enabling the existing upstream CPP backend is the best immediate optimization to test. Keep the epsilon grid, 218-digit working precision, Taylor order 436, independent AMFlow boundaries, and all 2220 requested coefficients unchanged. The main correction is operational: build and activate a versioned runtime for newly assigned families, rather than modifying a runtime directory that healthy workers may still read.

Upstream AMFlow 2.0 already makes CPP the default backend and provides the WSTP link target specifically for its Mathematica interface. This is an intended execution path, not a new numerical method you would be introducing. The source-specific observations below concern the public upstream snapshot I inspected; check that they match your local checkout. 
GitLab

1. Important conditions before activation
Freeze the runtime path for each family

There is a concrete reason not to build the executable directly into the shared active directory: upstream SetDefaultOptions[] first selects CPP and can install its link before a generated script subsequently selects MMA. Adding the executable can therefore change the behavior of an existing MMA worker’s next script, even without changing its requested backend. 
GitLab

Build a second runtime from the same checked-out source, then assign its absolute path and CPP setting only to newly dispatched families. Existing workers retain their original paths. Avoid changing a shared symlink or dependency installation beneath either runtime. No need to touch legacy FACET, restart healthy families, or change scheduling architecture.

Require evidence of actual CPP execution

Upstream link loading can fall back to MMA when the executable is missing or installation times out. Consequently, recording only the requested "DESolver" -> "CPP" is insufficient. Assert the effective solver, a valid owned LinkObject, and a successful small native numerical call inside the actual worker environment. An unexpected fallback should fail that attempted CPP job explicitly, rather than silently contaminate the performance result. 
GitLab

Also, do not use the upstream shell installation checker as your acceptance gate. Its link test launches a separate Wolfram main kernel, and some timeout/nonzero-exit paths still report success because the executable exists. Run the smoke test inside an existing subkernel instead. 
GitLab

Cap MPSolve separately—not just OpenMP

This is the most easily missed new threading issue. The native solver launches an external MPSolve root-finding process with precision arguments but without a thread-count argument. Building DESolver with OPENMP=no therefore does not establish that the complete numerical process tree stays single-threaded. 
GitLab
+1

MPSolve supports -j 1. A runtime-local wrapper that executes the real MPSolve binary with that argument, selected through the build’s MPSOLVE path, avoids changing upstream solver source. Keep the existing Wolfram/Kira limits and, where available, inherited CPU affinity as the hard resource boundary. 
GitHub
+1

Add native-link cleanup to the script scope

The WSTP executable is a compiled external program, not another Wolfram main kernel. It can therefore serve the existing subkernel synchronously without adding a main-kernel launch. However, its native state includes a process-global system registry and numerical settings; do not share one native link among family workers. 
GitLab
+1

The minimal ownership rule is: one link owned by the isolated generated-script execution, reused during that script, then disposed of on normal completion, intercepted Quit, abort, or failure.

Crucially, execute Uninstall[ownedLink] before restoring the localized DESolver context. Uninstall removes installed function definitions as well as terminating the external program; doing it after restoration could remove definitions you just restored. Track that exact link rather than closing every link in the kernel. 
Wolfram Documentation Center

Your previous symbol-restoration tests should therefore gain one native-specific test: install, perform an operation, terminate early, and verify both context restoration and absence of a surviving owned native process. Fresh outer workers do not eliminate leaks between multiple generated scripts within one family.

2. Numerical correctness and cut prescriptions

Keep the existing AMFlow Mathematica driver and change its numerical backend—not the surrounding physical workflow. Upstream derives the auxiliary-mass continuation direction from the propagator prescription and writes it into the generated calculation. Preserve that Direction, boundary pattern, integral ordering, basis conversion, and normalization exactly. The native activation is not a reason to regenerate these using different conventions. 
GitLab

I would not combine this rollout with the standalone YAML interface, basis refinement, or the alternative "FT" recursion. In particular, the published FT discussion has different analytic-continuation qualifications; its advertised speedups should not be imported into this cut-integral decision. 
arXiv

Two qualifications matter:

The backend switch includes boundary-order determination. It is not merely replacing regular-point Taylor arithmetic. The generated boundary-order script selects the requested solver, while an existing BOrder file bypasses that calculation. Therefore, a benchmark using cached MMA boundary orders does not test the complete fresh-family CPP route. 
GitLab

For at least one representative pilot, reuse the symbolic DE/reduction setup but recompute AMFlow’s boundary orders and numerical boundary subtree using CPP. Compare the discrete boundary-order output with MMA. A difference might be a conservative overestimate rather than a wrong answer, but it needs explanation before treating the fresh route as qualified. All boundary information should still originate from AMFlow.

Equal working precision does not mean identical numerical decisions. The native implementation has its own precision-dependent chopping thresholds. Preserve your current configuration and test its actual output rather than assuming 218 nominal digits imply an equivalent error budget. 
GitLab

Your argument against hand-reducing precision is sound: with the same clustered epsilon samples, agreement of individual sampled values at 18 digits is not enough to establish agreement of the fitted Laurent coefficients. The decisive comparison must be after the complete epsilon fit and master reconstruction.

The physical DE’s “triple-root” classification is useful for selecting a diverse pilot, but it need not identify the hardest auxiliary-mass problem. Also select by the actual AMFlow block sizes, singularities, and continuation/matching workload.

3. A proportionate benchmark

I would use three already-completed families, without rerunning their MMA calculations:

Pilot	Selection purpose
Typical family	Establish ordinary correctness and launch/conversion overhead.
Numerically expensive family	Test a large coupled block or substantial continuation workload—not merely the largest aggregate AMFlow time.
Structurally different family	Cover different cut/continuation or singular-endpoint behavior; include a triple-root physical family where useful.

Run one first, then the other two concurrently in available family slots. That supplies a concurrency test without adding a separate round of duplicate family calculations.

For each pilot, perform the entire requested epsilon grid and compare every requested coefficient, including complex components and the highest requested orders, against the existing MMA references. Keep the current 18-digit acceptance rule and its existing treatment of zeros and small coefficients. Record the agreement distribution as well as pass/fail: a concentration just above 18 digits deserves investigation when references target 25 digits, but it does not justify a blanket precision increase.

When stored sampled values are available, compare them too; they help distinguish transport discrepancies from fit amplification. They do not replace the coefficient-level test.

For timing, separate at least:

AMFlow symbolic/reduction work and boundary-order setup;

numerical boundary generation, transport, and endpoint matching;

fitting, data conversion, and link overhead.

Measure elapsed time and native-child resource usage, not just the Wolfram process’s CPU time. Record peak process-tree memory before enabling eight native families.

Two benchmark traps to avoid:

Do not accidentally reuse the old final numerical answers. Give the pilot a separate numerical-output location while reusing only the intended symbolic cache. Do not share writable numerical files between MMA and CPP jobs.

Do not compare a warm CPP numerical run with a cold MMA total and call the ratio “backend speedup.” Compare matching stages where the old logs permit it, and report end-to-end family time separately.

Three families are not a proof of universal correctness. They are a proportionate rollout gate because the queued families will still undergo the unchanged independent FeynFacet–AMFlow comparison.

4. Expected benefit—and what it will not solve

Your timings make this the correct place to optimize, but the reported 14,320 seconds are AMFlow total, not necessarily native-accelerable numerical work. A useful model is

T
AMFlow,CPP
	​

=T
symbolic
	​

+
r
T
numerical,MMA
	​

	​

+T
new overhead
	​

.

The upstream paper reports roughly 2.8–3.2-fold reductions in the numerical component for its AMF-mode benchmark. That supports testing CPP, but is not a prediction for your cut families or for the entire AMFlow stage. 
arXiv

Using your completed-family totals, even the hypothetical case where all AMFlow time falls by a factor of three gives

14320/3+1383+53
14320+1383+53
	​

≃2.54

for the aggregate work reduction. AMFlow would still account for approximately 77% of that reduced total. These are sums over the completed families, not an estimate of the dynamic-eight campaign’s elapsed time or unfinished tail.

Thus, CPP is the best immediate speed optimization, but it may not by itself make reference generation non-dominant.

5. Other small changes worth making

Persist approved numerical references independently of FeynFacet production runs. At this fixed point, rerunning the physical evaluator should normally load the approved AMFlow coefficients and repeat all 2220 comparisons—not regenerate those references. Invalidate them when the integral definition, cuts/prescriptions, normalization, point, or required numerical content changes, not merely because FeynFacet’s transport implementation changed.

Keep provenance for backend/build and numerical configuration, but do not invalidate the completed MMA references simply because CPP becomes available. They remain useful approved references and backend cross-checks. This is the change most directly aligned with “validation should not dominate production” across repeated runs.

Prioritize likely expensive queued families using existing timings or cheap available size indicators. Dynamic dispatch already avoids batch barriers; starting the likely long jobs earlier can reduce the final tail without changing any calculation.

I would defer precision tuning, alternative recursions, and broader algorithm changes until the CPP timing split is available. The immediate sequence is: isolated native build, explicit CPP execution check, MPSolve thread cap, native resource cleanup, three-family qualification, then CPP only for newly assigned work.
