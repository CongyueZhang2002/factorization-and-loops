# GPT-Pro reply to Consult_2026-08-17_stage2_strategy.md — received 2026-08-17 ~11:00 PDT (verbatim relay from the user)

[Session notes. USER CAUTION on receipt: "it seems to read into Planar's
literatures. So look with caution." — the reply's frame of reference is
the planar multi-leg AMPLITUDE programs (pentagon/hexagon function
spaces, the six-particle function-space calculation 2501.01847), whose
end product is numerical amplitude evaluation over a physical region.
Our end product differs: stage 4 needs UNEXPANDED endpoint modes and
distributional data at the strata, and the two-assistant setup values
master-level artifacts for cross-checking. The reply's §7 nevertheless
CONVERGES with Fable Max and Codex on the cure for the measured
bottleneck (complete the family eps-form incl. off-diagonal before
transport; do not raise by-parts timeouts; the sparse Chen
representation itself is sane). Its novel items (observable-submodule
projection, shared function basis, one-fold representations, Tier
I/II/III layering) are assessed in the decision memo beside this file
— adopted as cheap probes or deferred, not as the route. Small nits:
"342" should be 347 masters; the submodule's c-rows must be the
SUBTRACTED assembly's coefficients or the rank statement is about the
wrong object.]

Verdict
You are probably not missing a better general-purpose exact transport package. The literature suggests that the main thing FACET is missing is a layer between canonical differential equations and explicit master-by-master Chen-word expansion.
Fable has already solved the hard part that many projects never fully automate: all 173 diagonal differential-block classes have certified eps-forms. Its present transport is exact, blockwise, branch-aware, and wordwise certified. The unresolved cost comes mainly from noncanonical off-diagonal family couplings, not from the diagonal blocks or from the Chen representation itself. The measured sweep—46 of 91 families transported, with the heavy tail dominated by higher-order poles and polynomial rational prefactors—is consistent with that diagnosis.
The community usually avoids difficult symbolic transport through some combination of:

1. treating the canonical differential equation plus exact boundary values as the analytic answer;
2. constructing a shared transcendental-function basis rather than expanding every master into raw words;
3. projecting directly onto the amplitude or observable combinations that are actually needed;
4. using exact one-fold integral representations at high weight;
5. using generalized series only for evaluation and analytic continuation, not as the primary symbolic answer.

The two genuinely important ideas FACET has not yet fully exploited are therefore:
  [transport only the differential subspace visible to the hard function]
and
  [replace high-weight raw Chen expansions by a chamber-adapted function basis or exact one-fold representation].

1. What modern large calculations call an "analytic solution"
A modern canonical system is dF(x,eps) = eps Sum_a R_a dlog phi_a(x) F(x,eps), with exact boundary vector F(x0,eps) = B(eps). Then F(x,eps) = Pexp[eps Int_{gamma: x0->x} Sum_a R_a dlog phi_a] B(eps)  (1) is already an exact analytic definition once the following are fixed: the chamber; the path homotopy class; the branch of every algebraic letter; tangential prescriptions at singular endpoints; the boundary constants.
The recent complete planar six-particle function-space calculation explicitly treats the canonical differential equations and analytic boundary values as sufficient to specify all master integrals, with the answers retained as Chen iterated integrals rather than necessarily expanded into classical polylogarithms. [arXiv:2501.01847]
That means FACET should distinguish two deliverables:
Structural analytic master: (canonical DE, alphabet, exact boundary vector, physical chamber, branch record). This is already a complete analytic specification.
Expanded consumer representation: A GPL, one-fold-integral, endpoint-series, or special-function form constructed only for the particular hard-function component or phenomenological consumer that needs it.
Currently FACET is often forcing the second deliverable for every master immediately after obtaining the first. The literature increasingly does not.

2. The shared function-space approach
For complicated multi-leg systems, the community often constructs a reusable transcendental function basis—pentagon functions, hexagon functions, or an independent Chen basis—and expresses all masters and amplitudes in that basis.
For example, one-mass planar five-point integrals are expressed in a basis of algebraically independent "pentagon functions" designed directly for the physical chamber. The basis is arranged to avoid unphysical branch cuts and to support evaluation across the physical phase space. [arXiv:2110.10111]
The six-particle program similarly constructs the independent function space up to the required weight rather than treating each master's raw word expansion as an unrelated object. [arXiv:2501.01847]
FACET analogue: For each distinct alphabet and physical chamber, construct functions G^(w) = (g_1^(w), ..., g_{n_w}^(w))^T satisfying dg_alpha^(w) = Sum_{a,beta} C_{alpha a beta} g_beta^(w-1) dlog phi_a  (2), with exact values at one physical base point.
Then every canonical master coefficient at weight w is stored as F_i^(w) = Sum_alpha m_{i alpha}^(w) g_alpha^(w) + products of lower-weight functions  (3), rather than as thousands of unrelated raw words.
This produces three advantages: Deduplication across families (two families using the same alphabet and chamber reuse the same functions). Exact branch control (the function basis is defined on the physical sheet, rather than relying on later simplification of principal-branch PolyLog expressions). Hard-function assembly becomes rational linear algebra (once all masters are mapped into G, the hard function is assembled through rational coefficients multiplying a relatively small function vector).
FiniteFlow is directly relevant here: its supported applications include deriving differential equations and integrable symbols from a known alphabet, as well as reconstructing rational functions over finite fields. [arXiv:1905.08019]
What must still be retained beyond the symbol: A symbol basis alone loses zeta-valued constants; i pi terms; products of lower-weight constants and functions; exact endpoint powers; boundary normalization. Therefore the proper FACET object is not merely a symbol. It is a graded coproduct or differential basis plus exact base-point constants.

3. Exact one-fold representations are the standard escape from high-weight word explosion
Recent calculations increasingly avoid fully expanding high-weight canonical solutions into GPL words.
For two-loop six-point integrals, weight-three and weight-four results were represented as exact one-fold integrals over classical polylogarithms. [arXiv:2403.19742] At three-loop five-point kinematics, weight-six functions were represented as one-fold integrals involving lower-weight functions and kernels derived from the differential equations. [arXiv:2411.18697]
This is directly applicable to FACET's weight-five-to-seven tail.
Given a path gamma: [0,1] -> chamber, gamma(0) = x0, gamma(1) = x, write omega_a(t) = d/dt log phi_a(gamma(t)). At weight w,
  F^(w)(x) = B^(w) + Int_0^1 dt Sum_a omega_a(t) R_a F^(w-1)(gamma(t)).  (4)
The current sparse-word method recursively substitutes F^(w-1), generating all length-w words. The one-fold representation does not perform that substitution. It leaves the already constructed lower-weight functions intact.
For example, a weight-seven result may be represented as F^(7) = F^(7)(x0) + Int_0^1 dt Sum_alpha K_alpha^(3)(t) G_alpha^(4)(gamma(t))  (5), or another split suited to the available function basis.
This remains: exact; analytic; branch certified by the path; differentiable exactly; compatible with endpoint expansion. It is not a numerical quadrature merely because it is written as an integral.
Recommended use in FACET: Use raw Chen words through low weight, perhaps w <= 3 or 4. Above that, switch to one-fold representations over a retained lower-weight basis. This is likely more valuable than attempting increasingly elaborate word simplification at weights 5-7.

4. Generalized-series transport is common, but it is not the same product
When a compact global analytic form is not required, the community frequently integrates differential equations through generalized power-series patches along one-dimensional contours.
DiffExp solves systems order by order in eps using truncated one-dimensional series along lines in phase space. [arXiv:2006.05510] SeaSyde performs analogous series transport with analytic continuation in complex kinematic planes. [arXiv:2205.03345] A major planar five-point one-mass calculation used generalized power-series contours to trivialize continuation and evaluate the integrals throughout different regions. [arXiv:2005.04195]
This is how many phenomenological calculations avoid symbolic GPL transport altogether.
For FACET, these methods are appropriate as: independent evaluation engines; branch-continuation checks; base-point matching checks; diagnostics of singular paths. They should not replace the exact analytic master representation because their practical output is a truncated series.

5. The most promising missing idea: transport the observable submodule
FACET currently solves master spaces family by family. But the scientific consumer is not the entire master vector. It is a small number of hard-function combinations.
Let dI = A_mu dx^mu I, I in K^N, and let one hard-function component be H(x,eps) = c(x,eps)^T I  (6). Here K is the exact rational or algebraic coefficient field.
Define the covariant derivative acting on row vectors by nabla_mu r := partial_mu r + r A_mu  (7).
Generate the row module R_H = span_K { c^T, nabla_{mu1} c^T, nabla_{mu2} nabla_{mu1} c^T, ... }  (8).
Suppose its exact rank is r = dim_K R_H. Choose a row-basis matrix R(x,eps) in K^{r x N}. If the module is closed, partial_mu R + R A_mu = B_mu R  (9), define J = R I. Then partial_mu J = B_mu J  (10), and H is one component or rational combination of J.
If r << N, there is no reason to transport all N masters.
This is an exact differential-module projection, not a numerical approximation. It is closely aligned with the community's practical use of amplitude-level function bases, although I do not know a standard package that performs precisely this projection for a cut hard-function vector.
Why this may be especially effective here: Many of the 342 master coefficients may: vanish in a given spin/color channel; enter only through a few linear combinations; cancel after hard-function assembly; contribute only to endpoint sectors not needed at generic kinematics; be redundant under the same crossing maps used in the registry.
Finite-field sampling can determine the generic rank r cheaply before any symbolic construction.
Decisive test: For CF258 or CF230: 1. take the exact hard-coefficient rows relevant to one UU channel; 2. transform them to the assembled family frame; 3. generate the covariant row module over finite fields; 4. determine its generic rank; 5. reconstruct R and B_mu only if the rank is small; 6. prove Eq. (9) exactly.
Useful outcome: r <~ N/2. Transformative outcome: r << N. If r ~ N, the experiment is cheap and the route is discarded.

6. Transport only the physical boundary subspace
A related economy is already implicit in your boundary-nullity analysis.
Suppose a canonical block has dimension d, but exact lower-sector inheritance, regularity, and region constraints leave only q undetermined boundary coefficients. Then the physical solution space needed in production has dimension at most 1 + q: one known particular solution plus q unresolved homogeneous columns. There is no need to construct a full d x d transport matrix.
The recent six-particle function-space work explicitly focuses on the independent iterated integrals required for amplitudes rather than treating every formal word as an independent deliverable. [arXiv:2501.01847] Libra itself contains tools for determining the minimal asymptotic data needed to fix boundary conditions, although it does not perform the physical period calculation. [arXiv:2012.00279]
Therefore the order for expensive families should be: boundary nullity -> physical columns -> transport. Not: full fundamental matrix -> boundary matching.

7. What is and is not wrong with Fable's present transport
The existing sparse Chen representation is not pathological.
The current results—weights up to seven, at most roughly 10^4 words per transported family, and tens of megabytes for the largest artifacts—are within the scale encountered in modern function-space calculations. The measured problem is instead that the classwise canonical bases leave nonpure, higher-pole off-diagonal couplings after family assembly.
The literature-standard correction is exactly the one Fable has now identified: complete the full family canonical form, including off-diagonal blocks, before transport.
CANONICA is built to find rational multivariate canonical transformations, and Libra supports epsilon-form transformations, path-ordered expansions, and generalized local series. [arXiv:1802.02419]
There is no evidence that a different transport package will make noncanonical couplings cheap. Once a full family eps-form exists, Fable's own measurement shows that the transport becomes cheap; the blocked cost is basis construction, not iterated integration.

8. A practical three-tier FACET representation
I recommend formalizing three exact layers.
Tier I: canonical analytic specification. Store: {T, R_a, phi_a, B(eps), chamber, gamma, branch data}. No explicit transport required.
Tier II: common function-space coordinates. Store each master or hard combination as coordinates in a shared basis: F_i^(w) = Sum_alpha m_{i alpha}^(w) g_alpha^(w). Build this basis once per alphabet/chamber.
Tier III: consumer representation. Construct only when needed: one-fold integrals; GPLs; local Frobenius expansions; endpoint distributions; fast numerical evaluators.
This would prevent transport format decisions from being baked permanently into the scientific calculation.

9. Three decisive experiments
Experiment 1: observable-submodule rank. Use one difficult transported or blocked family. Measure: full family dimension N; row-module rank r; construction time; exact closure size; required boundary constants. Acceptance: partial_mu R + R A_mu - B_mu R = 0. If r << N, make this the default hard-function route.
Experiment 2: one-fold compression at maximum weight. Choose the transported family with the largest word artifact. Construct the terminal required coefficient in two forms: 1. current sparse Chen words; 2. one-fold integral over the weight-(w-1) or split-weight basis. Record: serialized size; construction time; differentiation-check time; branch metadata; endpoint-expansion cost. Acceptance: d F_1fold - eps Sum_a R_a dlog phi_a F_lower = 0, plus exact equality at the base point. A factor of five or more reduction in storage or verification cost would justify a production backend.
Experiment 3: function-basis compression. Take all 46 completed families and one common chamber. At each weight: 1. extract their words; 2. quotient by shuffle products and exact differential relations; 3. construct an independent basis; 4. map every existing solution into it. Record: raw word count / independent function count. This tells you whether a pentagon-function-style library is worth building before the remaining sweep.

10. Ranked recommendation
Immediate
1. Complete the off-diagonal family eps-forms for the blocked nontriple-root families. This is the established cure for the current measured bottleneck.
2. Keep Fable's exact sparse-word recursion and compositional certificate.
3. Do not increase time limits on higher-pole integration-by-parts transport.
Highest-value new experiment
4. Compute the observable differential-submodule rank for CF258 and CF230. This is the one route that could remove entire master directions rather than merely speed up their integration.
Representation improvement
5. Introduce an exact one-fold-integral output for weights above a chosen threshold.
6. Begin constructing a shared physical-chamber function basis from the 46 completed families.
Evaluation and checking only
7. Add DiffExp or SeaSyde as a high-precision independent evaluator.
8. Retain AMFlow as an independent integral-level comparison.
Opportunistic
9. Continue one-variable simplified-DE reductions when an exact invariant such as z = vw exists; the SDE method is an established route to GPL solutions, but it is not a generic solution for all families. [arXiv:1401.6057]

Final assessment
The community is not hiding a package that takes a 24x24, two-variable, branch-sensitive canonical system to a compact weight-seven exact hard function automatically.
What the community does differently is more structural: canonical system -> shared function space -> amplitude-level coefficients, rather than: canonical system -> explicit expansion of every master -> assemble the amplitude afterward.
FACET has largely solved canonicalization and exact word transport. The most likely missing breakthrough is to move the projection onto the physical hard function and the construction of a reusable function basis ahead of deep transport.
