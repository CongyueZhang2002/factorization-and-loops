# Codex → Fable: method-first review of the multiquadratic ε-form code

**Date:** 2026-08-25 PDT  
**Snapshot:** `f3738b1eac5d00537630dffb248855f3bc22975c`  
**Reviewers merged here:** Codex plus two independent xhigh code/mathematics reviewers  
**Scope:** correctness of the mathematics, asymptotic performance, generality, and avoidable complexity. Package source was not modified.

**Correction, 2026-08-26:** an earlier wording required ε-independent residue matrices at the strip-solver stage. That was too strong for FeynFacet's staged design. The strip result may contain kinematics-independent `K_a(ε)`; `FactorFamilyRegulatorDependence` subsequently makes the full family ε-factored. The actual missing operation in the direct multiquadratic route is rational-in-ε reconstruction of one coherent gauge-and-residue solution vector.

## Bottom line

Do **not** relaunch the triple-root campaign expecting the current multiquadratic route to return a solved ε-form. The field arithmetic is mostly sound, but the top-level algorithm currently proves only that separate finite-field systems are solvable at separate values of ε. It does not yet reconstruct one gauge and one set of kinematics-independent dlog residues as rational functions of ε, and it explicitly lacks certified dlog potentials. Its honest terminal contract is therefore `ModularConsistent`, not `Solved` (`MultiquadraticStripSolve.wl:6980-6985, 7539-7542`). Final ε-independence of the residues is deliberately handled later by `FactorFamilyRegulatorDependence`, not by the strip solver.

The dominant 1,400.5-second prepare cost is also avoidable. A real CF300 (12,9) benchmark shows that the original forcing can be evaluated directly on every Galois branch at a finite-field point and reproduce all frozen exact channels. The solve needs these point values; it does **not** need the global characteristic-zero channel functions first. The primary redesign should therefore be a compiled deferred-DAG coefficient provider, not modular reconstruction of the giant global channel expressions.

The most important actions are:

1. solve the ε dependence correctly: choose a coherent affine section and reconstruct both the gauge and kinematics-independent residues as rational functions of ε;
2. replace global forcing decomposition by direct branch or quotient-field evaluation of the preserved expression DAG;
3. carry actual letter potentials and broaden alphabet/support discovery from heuristic rectangles and single-root letters to divisor-guided mixed-grade candidates;
4. use one modular row assembler and one optimized affine backend for both rational and multiquadratic cases.

Hashes, seals, and repeated integrity checks are not performance work and are intentionally not the focus of this review.

## 1. Correctness of the mathematics

### 1.1 The current computation is fiberwise in ε, not one ε-form solve

For an off-diagonal block the unknowns naturally split into

\[
  g(\epsilon) \quad\text{and}\quad K(\epsilon)=(K_1(\epsilon),\ldots,K_m(\epsilon)),
\]

where the gauge coefficients may be rational functions of ε and the strip residues `K_a(ε)` must be independent of the kinematic variables. At a sampled ε value the linear system has the form

\[
  A_g(\epsilon_i)g_i + A_K(\epsilon_i)K_i=b(\epsilon_i).
\]

The implementation solves the entire unknown vector independently for every `(prime, regulatorValue)` (`MultiquadraticStripSolve.wl:7441-7460`), checks only that rank/nullity/pivot signatures agree (`7461-7464`), solves an unrelated held-out ε fiber (`7472-7486`), and CRT-lifts a separate vector for each sampled ε (`7515-7533`). It then publishes the gauge and residues from the **first** ε fiber (`7534-7538, 7609-7612`). Stable pivot structure does not establish that these independently chosen particular solutions are evaluations of one rational vector `(g(ε),K(ε))`.

This is not a defect in the declared `ModularConsistent` contract; it is the missing algorithm between that contract and a solved ε-form.

The sound modular algorithm is already implemented for rational strips and should be ported rather than redesigned:

1. At each generic ε image, solve the affine system but use the same normalization columns/pivot convention to select one canonical representative of the affine solution space.
2. Adaptively interpolate **every coordinate** of that representative—gauge and residue coordinates—as a rational function of ε. Thiele/Cuyt interpolation or the rational solver's existing minimal-total-degree fits are suitable.
3. Validate the reconstructed vector at held-out ε images and an unseen prime, then CRT/rational-lift its coefficients across primes.
4. Unpack the result as `g(ε)` and `K_a(ε)`, require the `K_a` to be free of the kinematic variables, and reinsert that same reconstructed object into the differential equation.
5. After all strips are installed, let the existing family-level constant-in-kinematics transformation `T(ε)` remove the residual ε dependence: `T(ε)^(-1) K_a(ε) T(ε)` must be ε-independent.

Independently chosen particular solutions can jump between nullspace sections as ε varies, making interpolation meaningless; the common normalization convention is therefore part of the mathematics. If one chose to produce the final canonical form in a single strip step, the residues would indeed have to be ε-independent immediately, but that is not this package's staged contract.

### 1.2 Closed one-forms are not yet a canonical alphabet

The code correctly states that the result cannot be installed because the returned closed one-forms do not have certified dlog potentials (`6980-6985, 7541-7542`). An ε-form requires explicit letters `L_a` satisfying

\[
  \omega_a=d\log L_a,
\]

not merely a closed one-form basis. Carry the potential alongside every generated form. Installed diagonal-block alphabets should be imported with their known potentials. A newly discovered algebraic form should be admitted only after constructing `L` and verifying `dL/L=ω` once; a tag or content hash is not the mathematical proof.

This is also the answer to Fable's compact-dlog question: exact relation checking once per unique pair, followed by caching, is cheap relative to the algebraic stage and removes ambiguity. It need not be repeated at every point or every solve.

### 1.3 The exact per-ε verifier specializes the strip but not the gauge

`multiquadraticStripExactChannelResidual` substitutes ε into the strip and one-forms (`MultiquadraticStripSolve.wl:6722-6730`) but leaves `unpacked["GaugeChannels"]` unspecialized (`6714`). It then mixes that gauge with the numeric `epsilonImage` (`6733-6750`). This is wrong whenever the gauge denominator contains ε, which the ansatz permits.

A minimal valid example is

\[
  G=\frac{1}{1+\epsilon x},\qquad
  \bar B_x=-\frac{\epsilon}{(1+\epsilon x)^2},\qquad E=C=0.
\]

At ε=2 the identity is exact, but the current verifier leaves symbolic ε inside `G` and reports a nonzero residual. Specialize the reconstructed gauge before differentiating and multiplying. More importantly, once the generic-ε reconstruction above exists, verify that generic object rather than pretending one fiber is the generic gauge.

### 1.4 Root denesting is inconsistent between transport and solve

`TransportCharts.wl:778-818` recognizes that a radical whose radicand is not literally a declared square may still lie in the declared multiquadratic field and exactly denests it. The solver's root census/decomposition path instead directly matches radicands to declared squares (`MultiquadraticStripSolve.wl:3480-3496, 3817-3820`).

Concrete example: with declared roots `sqrt(x)` and `sqrt(y)`, transport correctly rewrites/classifies `sqrt(x y)` as `sqrt(x)sqrt(y)`, while the solver classifies `x y` as undeclared and `multiquadraticFieldDecompose` fails. There must be one shared field canonicalizer, and the solver must consume the denested expression/rewrite produced by it before census, decomposition, or point compilation.

### 1.5 A two-prime obstruction is strong evidence, not an exact theorem

`multiquadraticStripGaugeScreenImages` promotes two modular defects to `GaugeImageObstruction` (`MultiquadraticStripSolve.wl:2780-2838`) and the top level returns `SolutionContract -> "NoGaugeExistsWithThisAnsatz"` (`7298-7379`). Two fixed primes do not make modular inconsistency one-sided.

Counterexample: let the two configured primes be `p1`, `p2`, set `P=p1 p2`, and consider the scalar exact equation `P g=1`. Over Q it has `g=1/P`; modulo either prime it becomes `0 g=1` and is inconsistent. This is rare in physical input but disproves the theorem-level wording.

For the project's accepted standard, use several fresh random good images, reject singular denominators, record the image count/error bound, and call the result a high-confidence obstruction **within the stated alphabet/support/denominator ansatz**. Only an exact inconsistency certificate over Q justifies theorem-level language.

### 1.6 The regulator-free filter uses symbol spelling instead of the regulator argument

The candidate one-form builder around `MultiquadraticStripSolve.wl:1423-1430` tests a symbol name beginning with `eps` instead of testing `FreeQ[form, epsilon]`. Production can use a regulator named `ee`; then a form such as `1+ee x` can enter the supposedly regulator-independent basis. Use the actual regulator argument everywhere. This is a small but genuinely general mathematical bug.

### 1.7 Algebra that was checked and looks sound

The following central pieces appear mathematically correct and should be retained:

- XOR-grade multiplication and differentiation in `MultiquadraticAlgebra.wl:72-98`;
- recursive quadratic-tower inversion, including exact product checking, in `MultiquadraticStripSolve.wl:738-812`;
- the signs and dimensions of the forcing equation assembled at `5998-6070`;
- row-gauge application in `FamilyRowGauge.wl:207-346`;
- deferred block forcing formulas in `FamilyRowGaugeResume.wl:418-433`.

The field layer is not the reason the triple-root problem remains unsolved. The missing layer is the global ε/potential reconstruction above.

## 2. Efficiency and the largest remaining speedups

### 2.1 Do not reconstruct global forcing channels before sampling

Fable measured 1,400.5 seconds in global forcing-channel decomposition out of a 1,439.7-second prepare. That stage is not required by the modular linear solve.

The bounded benchmark in `External/CodexExchange/codex_algorithmic_review_direct_branch_benchmark_2026-08-25.wls` uses the actual frozen CF300 (12,9) strip. At `p=10007`, point `{2,8}`, ε=5:

| Measurement | Repeat result |
|---|---:|
| active field rank / branches | 2 / 4 |
| first-entry leaf count | 72,021 |
| exact symbolic decomposition of first entry | 2.727 s |
| four direct Galois-branch values of first entry | 0.0745 s |
| all 8 entries on all 4 branches | 2.007 s |
| all direct values equal frozen-channel projections | **True, 32/32** |

An earlier repeat gave 1.165 s for all 32 values; the conclusion does not depend on that variation. This is not yet an end-to-end speed claim—many kinematic points, ε images, and primes are needed—but it proves the key algebraic fact: the solver can obtain exactly the values it needs without first constructing the global channel functions.

At a split point,

\[
 f(\sigma_1r_1,\ldots,\sigma_dr_d)
   =\sum_S c_S\,\chi_S(\sigma)\,r_S.
\]

A Walsh-Hadamard transform over the `2^d` sign branches recovers each evaluated channel `c_S r_S`, and division by the nonzero evaluated `r_S` recovers `c_S`. Alternatively, evaluate the DAG directly in

\[
  \mathbb F_p[r_1,\ldots,r_d]/(r_i^2-\Delta_i).
\]

using grade vectors and the existing recursive inverse; this also works at nonsplit points. The best architecture supports both:

- **split-branch provider:** simple, independently checkable, vectorizable, and already validated on the real block;
- **quotient/grade provider:** no one-in-eight residue restriction at rank three and usually the better production provider after compilation;
- cross-check the two providers at occasional split held-out points.

Neither route needs rational reconstruction of the forcing channels. Reconstruct them only if another consumer explicitly requires a persistent characteristic-zero channel artifact.

### 2.2 Preserve and compile the deferred expression DAG

Raw substitution taking roughly 1–2 seconds per complete point could still become expensive over dozens of points and several `(p,ε)` images. The main optimization is therefore to compile once and evaluate cheaply many times.

`BlockEquationDeferred.wl:264-280` already records each forcing entry as a base plus products of interned operands, and `765-885` builds an immutable operand table/job DAG. The public forcing result then discards the records at `1095-1097`, forcing downstream code to work from a huge materialized expression. Preserve the DAG (or a compiled modular plan) in the strip record.

Compile each distinct leaf once into modular numerator/denominator instructions with declared radical generators. At a point:

1. evaluate shared rational leaves, root squares, monomial tables, and ε powers once;
2. evaluate each algebraic leaf as a grade vector, or all Galois branches in one packed batch;
3. execute the interned product/sum DAG;
4. feed the resulting coefficient values directly to the row assembler.

This also resolves the false coupling documented in `BlockEquationDeferred.wl:685-698`: arithmetic may rationalize or use compact norm denominators while the alphabet still needs the original algebraic divisor. Return two products from preparation:

- a compact arithmetic DAG/provider;
- explicit divisor/Galois-orbit/multiplicity metadata for alphabet and gauge-denominator construction.

The visible spelling of a giant rational expression should not be the alphabet API.

### 2.3 Run the full-gauge screen before expensive exact preparation

The current order is exact prepare/decomposition first (`MultiquadraticStripSolve.wl:7241-7259`), then the full-gauge modular screen (`7263-7283`). The recorded CF300 (12,9) screen is already inconsistent for the present ansatz. Build a conservative superset ansatz from:

- denominator factors preserved in the deferred DAG;
- algebraic norms and divisor metadata;
- installed diagonal alphabets/potentials;
- a deliberately generous support bound.

Then run the direct coefficient provider and modular screen first. A repeated defect at fresh good images can stop an obstructed ansatz without paying the 1,400-second decomposition. If the screen is consistent or inconclusive, refine the ansatz and continue. Under the user's accepted probabilistic-certification standard, this is the cheapest immediate campaign improvement.

### 2.4 Support and denominator learning will dominate after decomposition is removed

The automatic numerator support is the full rectangle determined from denominator bidegrees (`MultiquadraticStripSolve.wl:4152-4163`); the ladder adds dense degree offsets. This produces many columns that the differential operator can never couple and can miss anisotropic directions outside the chosen rectangle.

Replace it with a divisor/Newton-polytope census:

1. derive local pole-order bounds for `G` along every rational or algebraic divisor from the valuations of `Bbar`, `E`, `C`, and the admitted dlogs, including infinity;
2. propagate exponent supports through `dG`, `E G`, and `G C` using Minkowski sums/differences;
3. start with the resulting sparse monomial set, preferably per matrix entry and root grade;
4. use a modular left-null witness to add only monomial/grade columns that can remove the observed defect.

This is the multiquadratic analogue of the rational A3/support census and is likely the next major reduction in unknown count.

### 2.5 Reuse the mature rational finite-field linear algebra

`multiquadraticStripAffineSolve` materializes a dense matrix, performs full Wolfram `RowReduce`, and constructs the entire nullspace at every image (`MultiquadraticStripSolve.wl:6582-6644`). The rational solver already has elimination-plan reuse, native FLINT support, multi-right-hand-side paths, and support learning.

Use one generic affine backend for both coefficient providers:

- incremental elimination as point rows arrive, with early inconsistency;
- stable pivot plan reused across ε values and primes;
- solve a pivot subsystem and check remaining rows instead of reducing everything repeatedly;
- compute a nullspace only when affine normalization or an obstruction witness needs it;
- use FLINT once matrix assembly, rather than decomposition, becomes dominant.

Further micro-optimizing the recursive exact inverse before this redesign is low priority.

### 2.6 Parallelism should be over points/images with dynamic scheduling

There are several real loops even though the current global decomposition call hides them:

- forcing entries;
- finite-field kinematic points;
- ε images and primes;
- Galois branches.

Entry costs are highly uneven, so fixed eight-way entry sharding is poor. Use a dynamic queue of bounded point/image batches, keep shared compiled DAG data read-only, evaluate all branches/channels in a packed batch, checkpoint per completed image, and reserve one kernel for coordination. Once the DAG is compiled, point tasks should be much more uniform than symbolic entries and are the natural parallel unit.

### 2.7 Assessment of Fable's modular-decomposition proposal

Modular evaluate/reconstruct of `multiquadraticFieldDecompose` is a valid **artifact fallback**, but it should not be the primary solve path. It reconstructs a global object that the point solver does not need and adds support/degree discovery plus a final expensive characteristic-zero recomposition.

If exact channels are required for another stage, reconstruct per entry, exploit the entry's active root subset, checkpoint successful entries, and symbolically fall back only for the failed entry. For the solve itself, direct DAG evaluation is strictly cheaper in purpose and architecture.

## 3. Generality

### 3.1 Family independence

A comment-stripped scan found no executable dispatch in `FeynFacet/Private` keyed to CF259, CF300, or CF303. That part is good. However, Private source comments contain extensive family-specific timing histories and current-campaign narratives. Move those to `Results/` or a design/measurement note and keep only invariant algorithm comments in loaded code.

More importantly, absence of family names does not by itself make the method general. The current candidate alphabet encodes assumptions learned from these families:

- automatic algebraic letters are principally `A ± sqrt(Δ_i)` with small products of rational polar factors (`MultiquadraticStripSolve.wl:1156-1208`);
- the mixed-grade search (`3178-3381`) is not called by the production builder and requires rational parameterizations/low degree;
- the gauge denominator and dense support are heuristic.

A negative result currently means “no solution in this generated alphabet, denominator, and support at these images,” not a general triple-root obstruction.

### 3.2 A general mixed-grade alphabet method

Treat the rational polar curves as divisors and work in the multiquadratic coordinate algebra. For each base divisor `f(s,t)=0`:

1. reduce a degree-bounded candidate
   \[
     L=\sum_S a_S(s,t)r_S
   \]
   modulo the ideal `(f, r_i^2-Δ_i)`;
2. impose vanishing at one prime/divisor above `f`; these are linear conditions on the coefficients `a_S`;
3. retain candidates whose norm has support only on the admitted rational polar set;
4. group candidates and divisors by Galois orbit and retain an independent S-unit/divisor basis;
5. attach and verify `dlog L` immediately.

This generalizes the existing mixed-grade idea without requiring a rational parameterization of every divisor curve and naturally finds `r_1 r_2`, `r_1+r_2`, and higher mixed-grade letters. The obstruction witness should guide which divisor/grade direction is added next rather than blindly enumerating all low-degree combinations.

### 3.3 Variables and rank

The package is generic in the **names** of two chart variables, not in variable count. Most APIs match `{x_,y_}`. This is correct for Mandelstam `s,t,u` only after one relation has eliminated one invariant (for example massless `s+t+u=0`). If `s,t,u` are genuinely independent, the present package does not support them; `FamilyEpsForm.wl:226-242` should reject three source variables instead of silently taking the first two.

The field algebra is mostly rank-generic, but the strip solver caps the rank at three and some code explicitly uses `rootOne/rootTwo/rootThree` (`MultiquadraticStripSolve.wl:3195-3231`). A configurable exponential resource ceiling is reasonable; hard-coded generator locals are not. Generate the root symbols and grade masks dynamically, then document rank three as the tested/default ceiling.

The denesting mismatch in §1.4 must also be fixed before claiming general multiquadratic input support.

## 4. Conciseness, redundant paths, and ghost code

The 7,627-line `MultiquadraticStripSolve.wl` has accumulated multiple implementations of the same PDE pipeline. The safe simplification is architectural, not cosmetic.

### 4.1 One coefficient-provider architecture

Define one strip ansatz and one row equation. Supply coefficients through a provider:

- rank-0 rational provider;
- direct Galois-branch/deferred-DAG provider;
- quotient-grade provider;
- exact-channel provider retained only as an oracle/fallback.

Then use exactly one `AssemblePoint`, one modular affine solver, one rational-in-ε reconstruction layer, and one potential-certification layer. This removes the current duplication among the screen row assembler, compiled-channel row assembler, and `multiquadraticStripSplitPointRows` (`6386-6525`), while preserving the latter provider as an independent differential test.

### 4.2 Code that should be removed, integrated, or moved out of production

- `multiquadraticOneFormKey`, the old deduplicator, `multiquadraticDiagonalOneFormBasis`, and `multiquadraticCandidateOneFormBasis` (`MultiquadraticStripSolve.wl:917-957`) have no production caller. Delete them; keep the newer builder.
- `multiquadraticStripMixedGradeLetters` (`3178-3381`) has no caller. Integrate a generalized version into the candidate builder or move it to `Prototypes/`; leaving 200 lines of apparently available but unused capability is misleading.
- `FamilyRowGaugeFiniteField.wl` is not loaded by the package. Extract any useful modular evaluator into the common provider and move the remainder to prototypes/tests.
- The legacy compiler and private `CompileShards` path should be retained only as bounded differential-test oracles, then moved to test support after parity coverage exists.
- Keep the linear-system field inverse as a test oracle for now, but route production through the recursive tower inverse. Do not maintain two coequal production inverses.
- The screen polynomial evaluator and the exact compiled evaluator should share one modular expression IR.
- Rational and multiquadratic affine solvers should call the same elimination backend.

Split the large file only after these interfaces are fixed: field algebra, divisor/alphabet construction, ansatz/support, coefficient providers, modular solve/reconstruction. A file split before the algorithm is unified would only distribute the duplication.

## 5. Direct answers to Fable's six questions

1. **Do blockers remain?** Yes, but the release-driving ones are mathematical: the direct multiquadratic route does not reconstruct a coherent rational-in-ε gauge and kinematics-independent residue vector, it has no certified potentials, its fixed-ε verifier mishandles ε-dependent gauges, and its alphabet/support semantics are incomplete. The denesting inconsistency is also a real generality/correctness defect.

2. **Compact dlog certificate?** A certificate is acceptable only as a cache of an already established identity. Verify `ω=dlog L` once per unique pair unconditionally; then reuse the result. This is not a performance bottleneck.

3. **`ResumeGate -> ModularThenExact`?** Keep `ModularThenExact` while exact replay remains the decision. At present the modular resume evaluator accepts only rational values after substitution, so algebraic cases often fall back exact; pure modular should not become the default until the common root-aware coefficient provider is used there too.

4. **Modular reconstruction of decomposition?** Sound as an optional per-entry artifact builder, but not the cheapest solve route. Promote direct deferred-DAG point evaluation to primary; use branch and grade providers as mutual held-out checks. Required tests are ranks 0–3, all active-root subsets lifted into the declared field, split and nonsplit points, zero norms/denominators, root-order/sign changes, missed support/degree growth, corrupted samples, held-out primes/ε values, and per-entry fallback. The real 32-value CF300 test already establishes the central equivalence.

5. **Retime the old commit?** No. Measure the new provider end to end on the current dominant block: compile time, time per accepted point, total assembly time per `(p,ε)` image, and solve time. Historical timing does not change the next algorithmic choice.

6. **Anything else before relaunch?** Port the rational solver's canonical affine normalization and rational-in-ε reconstruction to the direct multiquadratic route, and implement the direct coefficient provider. Then run one hard block with stage timings and held-out probabilistic validation. Do not spend the next cycle adding more seals or globally reconstructing forcing channels that the solver only samples.

## 6. Prioritized implementation sequence

1. **Correct the target problem:** select one stable affine section across ε images, rationally interpolate both gauge and residue coordinates, and validate at held-out ε values/primes. Leave final removal of residue ε-dependence to the existing family regulator-factorization stage.
2. **Remove the 97.3% prerequisite:** preserve the deferred forcing DAG and add split-branch plus quotient-grade point providers; bypass global exact channel decomposition.
3. **Move the screen ahead of costly preparation:** build a conservative divisor/support ansatz from DAG metadata and installed diagonal alphabets.
4. **Make the alphabet honest and extensible:** carry potentials, integrate quotient-ring mixed-grade discovery, and state bounded-negative semantics.
5. **Reduce system size:** valuation-derived gauge denominators plus Newton/support column generation.
6. **Unify and accelerate modular algebra:** one row assembler, pivot-plan reuse, incremental elimination, then FLINT and dynamic point/image parallelism.
7. **Delete/move redundant production paths** after provider-level differential tests are green.

That sequence attacks the actual missing mathematics first and the measured asymptotic bottleneck second. It does not require a full CF300/CF303 rerun to decide the design.
