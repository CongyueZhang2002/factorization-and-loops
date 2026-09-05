# CF303 Sector20 Rank One Transition

## Question

Continue the existing Assess Multiquadratic Pipeline evaluation with the full prior context. This is the first unavoidable rank-one checkpoint; please do not treat it as a new standalone problem.

New exact results:

1. CF303 sectors 17, 18, and 19 are now fully exact-dlog certified in the Kallen23 chart. Sector 19's aggregate certificate explicitly verifies A_18,17 = 0, A_19,17 = 0, the identity sector-18 gauge, and the vanishing indirect 17->18->19 path.

2. A controlled benchmark on the hardest rational strip 19->12 compared identical 136-monomial / 2,384-unknown systems. Native FLINT plan discovery returned the same rank/nullity 2368/16, learned the same 95-monomial support and rank 1728/nullity 0, and produced exactly the same gauge, alphabet, and residue matrices. End-to-end solve time was 253.5 s versus 277.0 s for Wolfram, only 1.09x faster; sampling plus interpolation remained about 128 s.

3. The exact sector-20 frontier census found the first genuine residual-root activation in Kallen23. Let R^2 = F(p,q), where F is the squarefree residual polynomial representing sqrt(1-4xy) after rationalizing lambda2 and lambda3. The sector-20 diagonal has four nonzero odd-grade entries, so the strip operator itself acts over k(R); this cannot be avoided by cancellation in a lower forcing. Direct odd-grade entries also occur in 20->18, 20->14, 20->11, 20->2, and 20->1. Raw A_20,19 = 0 and A_20,17 = 0; raw A_20,18 is nonzero, while the sector-18 row gauge is zero. Thus D_20,19 = 0 and the first nontrivial rank-one strip is 20->18.

4. The existing standardized package already has an exact direct multiquadratic grade-basis engine. It assembles every grade separately, validates held-out prime/regulator structure, all R -> -R branches, a split-sign differential check, and best-effort exact channel residuals at fixed regulator values. By contract it stops at Status ModularConsistent because it returns closed one-forms, not certified dlog potentials, and it does not reconstruct rational dependence on epsilon.

5. A scratch Exchange prototype, TripleRootReconstructionPrototype.wl, already implements cross-epsilon rational interpolation per prime, a fixed constrained elimination plan, CRT/rational reconstruction across primes, and an exact characteristic-zero channel residual. It is not in the package and may be used experimentally. We will not modify the package during this campaign.

Please assess concisely but technically:

A. Confirm that odd grade in the upper diagonal is by itself sufficient to force the 20->18 solve over k(R), even if the assembled forcing's odd grade were to cancel.

B. Is the safest next experiment to feed the exact 20->18 rank-one strip into the scratch rational-in-epsilon reconstruction prototype, reusing the package's grade arithmetic and exact residual as an independent checker? State the minimal fail-closed cross-prime/cross-epsilon invariants.

C. The remaining promotion gap is dlog potentials. Give the most practical exact method for certifying that the returned closed algebraic one-forms are dlog combinations in k(R): for example, build letters from algebraic factors and conjugate norms, solve constant residues against dlog L, and verify the full one-form exactly on both R branches. Clarify whether diagonal one-forms may be accepted using their already-certified class alphabet/potentials, rather than reintegrated.

D. For this first 2x2 -> 2x2 rank-one block, recommend a performance order among: support census/learning, fixed-plan multi-epsilon batching, FLINT for repeated modular solves, split by dependency graph, and parallel primes. We have one 8-worker Wolfram pool and must preserve exact certificates.

E. Identify any theorem-level obstruction we would encounter at this stage beyond failure to find a finite algebraic dlog alphabet; distinguish that from an implementation limitation.

## Pro response

A. Rank-one necessity

Yes, the 20→18 strip must be formulated over

K=k(R),R
2
=F(p,q),

even if the assembled forcing happens to have zero odd grade. This forces the coefficient field of the solve; it does not necessarily force the final gauge to have a nonzero odd component.

Write

E=E
0
	​

+RE
1
	​

,C=C
0
	​

+RC
1
	​

,
B
ˉ
=B
0
	​

+RB
1
	​

,G=G
0
	​

+RG
1
	​

.

Using

dR=
2F
dF
	​

R,

the strip equation

B
ˉ
+ϵ(EG−GC)−dG

has even component

B
0
	​

+ϵ(E
0
	​

G
0
	​

+FE
1
	​

G
1
	​

−G
0
	​

C
0
	​

−FG
1
	​

C
1
	​

)−dG
0
	​

,

and odd component

B
1
	​

+ϵ(E
0
	​

G
1
	​

+E
1
	​

G
0
	​

−G
0
	​

C
1
	​

−G
1
	​

C
0
	​

)−dG
1
	​

−
2F
dF
	​

G
1
	​

.

Even when B
1
	​

=0, a rational ansatz G
1
	​

=0 must satisfy the additional algebraic constraint

E
1
	​

G
0
	​

−G
0
	​

C
1
	​

=0.

Because E
1
	​


=0, the rational subspace is not generically invariant under the strip operator. A rational gauge might still emerge accidentally, but only the coupled two-grade solve can certify that.

So the exact conclusion is:

solve over K,allow the result itself to decide whether G
1
	​

=0.
	​

B. Next reconstruction experiment

Yes. Feed the immutable exact 20→18 strip to the scratch rational-in-ϵ reconstruction prototype. Use the package’s standardized grade assembler and branch machinery as one oracle, but retain an independently implemented characteristic-zero two-grade residual as the final theorem-level check.

The package’s fixed-ϵ ModularConsistent result is not enough because it does not reconstruct the ϵ-dependence. The prototype fills exactly that gap. Finite-field reconstruction is exact only after cross-prime lifting, uniqueness control, and characteristic-zero substitution; modular agreement by itself is screening evidence. 
arXiv

Minimal fail-closed invariants

Immutable field and input contract

Bind the strip, chart, F, root order, constant field, derivation convention

R
2
=F,dR=
2F
dF
	​

R,

support, one-form ordering, regulator clearance, normalization plan, and every relevant source hash.

If any 
2
	​

 constant survives from the Källén normalization, declare the constant field explicitly rather than silently treating it as Q.

Good-image conditions

Reject primes or points where:

F=0,

a chart or strip denominator vanishes, the constrained core determinant vanishes, the square class degenerates, or an ϵ-denominator vanishes.

Fixed semantic elimination plan

The same constrained columns and normalization equations must be used at every prime and every ϵ image. No pivot rediscovery is permitted in follower images.

At each image verify:

Ax=b

against all original rows, not only the constrained square core.

Stable generic structure

Across all accepted images require identical:

rank and nullity;

grade support;

learned kinematic support;

one-form basis ordering;

numerator/denominator degree profiles in ϵ;

normalization dimension.

Isolated rank-degenerate ϵ values may be rejected as bad images, but must be recorded rather than silently skipped.

Cross-ϵ reconstruction

At each construction prime, use enough ϵ samples to determine every rational function uniquely under the recorded degree bounds, followed by at least one genuinely held-out ϵ value.

Require coprime, canonically normalized numerator and denominator polynomials for every gauge and residue coefficient.

Cross-prime lifting

Continue CRT until the modulus exceeds the rational-reconstruction uniqueness bound derived from the observed coefficient heights. A fixed count such as three primes is an engineering floor, not the proof.

Independent modular oracle

At an unseen prime and unseen regulator value require:

zero full-system residual;

both R↦±R branches;

agreement between grade-basis and split-sign evaluations;

unchanged normalization.

Characteristic-zero acceptance

Verify exactly, in both differential components and both grades,

B
ˉ
+ϵ(EG−GC)−dG−
a
∑
	​

M
a
	​

(ϵ)ω
a
	​

=0.

This residual should use arithmetic independent of the interpolation and constrained-elimination code. Sharing the package grade engine for both construction and final verification would leave a correlated blind spot.

The existing report already found that modular linear algebra was not the dominant cost and that leafwise/channel assembly was the decisive architecture. 

codex_overnight_optimization_tr…

C. Exact dlog-potential closure
Certified diagonal alphabets may be inherited

Do not reintegrate diagonal one-forms whose class alphabets and potentials are already exactly certified.

For each inherited letter L
source
	​

, require only:

L
chart
	​

=Φ(L
source
	​

),

and independently verify

Φ(dlogL
source
	​

)=dlogL
chart
	​


in the two-grade field. Bind the source-letter certificate, chart, branch convention, and pullback hashes.

That is theorem-level composition of existing certificates. Reintegrating those forms would add cost without new assurance.

Practical closure algorithm for new forms

Let the solver return a finite collection of epsilon-free closed forms in K. First reduce the actual matrix connection to a minimal constant-linear form space; do not require every redundant intermediate form to be individually logarithmic.

Then proceed as follows.

1. Seed with actual algebraic factors

Collect:

pulled certified letters;

rational irreducible numerator and denominator factors;

algebraic operands L=A+BR appearing in forcing entries;

their conjugates

τ(L)=A−BR;

their norms

N(L)=A
2
−B
2
F;

ratios

τ(L)
L
	​

,

which are particularly useful for anti-invariant forms.

Normalize rational denominators separately, since multiplying a letter by a nonzero constant is irrelevant but multiplying by a rational function contributes additional rational dlogs.

2. Compute each dlog exactly

For

L=A+BR,N=A
2
−B
2
F,

use

dlogL=
2
1
	​

dlogN+
N
R
	​

(AdB−BdA+
2F
AB
	​

dF).
	​


This gives the even and odd grades directly and avoids explicit radical simplification.

Also verify the identity

dlogL+dlogτ(L)=dlogN(L).
3. Solve a constant span problem

Express every candidate and every returned closed form in the basis

{dp,dq,Rdp,Rdq}.

Solve

ω
i
	​

=
j
∑
	​

c
ij
	​

dlogL
j
	​


with c
ij
	​

 in the declared exact constant field and independent of p,q,ϵ.

The matrix residue coefficients

M
j
	​

(ϵ)

may still depend rationally on ϵ at the current DLogFormCertified stage. What must be epsilon-free are the letters, their one-forms, and the constant change of one-form basis.

4. Verify the complete connection, not only individual forms

After changing from the package’s closed-form basis to the dlog basis, verify

B
ˉ
+ϵ(EG−GC)−dG=
j
∑
	​

M
j
	​

(ϵ)dlogL
j
	​


exactly in both grades and under R↦−R.

Require for every letter:

N(L)

≡0,

and include all letter and norm denominators in the generic-open-set manifest.

If the factor-derived alphabet fails

That is a candidate-generation failure, not a theorem-level obstruction. The next exact test should inspect only the unresolved form subspace:

pole orders;

residues on the normalization of R
2
=F;

principality of the residue divisor;

any residue-free de Rham remainder.

Algorithms for algebraic integration use precisely residue divisors and principality tests to decide whether algebraic differentials reduce to rational derivatives plus logarithmic derivatives. 
DSpace at MIT
+1

The package’s refusal to promote closed one-forms without exact dlog potentials is therefore mathematically appropriate. 

codex_overnight_optimization_tr…

D. Performance order for the first 2×2→2×2 rank-one block
Structural preflight: dependency graph

Before any large solve, construct the exact bipartite graph connecting:

the eight gauge channels G
0
	​

,G
1
	​

;

residue variables;

both-grade equations;

normalization constraints.

If it splits into disconnected components, solve those components independently and retain exact embedding maps into the full system.

Do not split merely by matrix row, column, or root grade. The odd diagonal couples G
0
	​

 and G
1
	​

, as the equations in part A show.

Then use this order

Support census and support learning

This is the highest expected-value reduction. Learn support only after the constrained normalization is fixed.

If a functional nullspace remains, retain the union of support from the particular solution and every true null vector; otherwise support learning can discard legitimate homogeneous directions.

Every learned-support result must be checked against the full unreduced support equations at unseen images.

Fixed-plan multi-ϵ batching

For each prime, reduce and cache the two-grade operand DAG, monomial tables, F, derivatives, and point evaluations once. Process all ϵ images for that prime serially against the same cache.

This directly targets the measured sampling/interpolation cost.

Parallel primes

Assign one construction prime per worker, with that worker processing its full ϵ batch. This preserves prime-local caches and avoids nested kernels.

Run the unseen prime only after the construction-prime normalization and degree profiles agree.

FLINT repeated solves

Retain FLINT because it is exact, deterministic, and useful for independent rank certificates, but do not invest further optimization effort here. The measured 1.09× end-to-end gain confirms that modular elimination is no longer the limiting stage.

No blind output-row/column splitting

Use it only if the exact dependency graph proves a decomposition. Otherwise it risks dropping couplings from EG−GC or from shared residue variables.

E. Mathematical obstructions versus implementation limits
Possible theorem-level strip obstructions

There are two substantive ones.

1. No gauge in K(ϵ)

The inhomogeneous strip equation may represent a nonzero class modulo the image of the differential operator

D(G)=dG−ϵ(EG−GC)

and the allowed target one-form space. Equivalently, no G∈Mat
2×2
	​

(K(ϵ)) may solve the desired equation.

A finite support or degree failure does not prove this. A theorem-level claim requires an exact local-resonance, pole-order, or differential-module obstruction. In the rational one-variable setting, reduction algorithms can sometimes certify irreducibility to epsilon form, but that does not automatically extend to this multivariate quadratic function field. 
arXiv

Once the scratch prototype reconstructs G and the exact characteristic-zero residual vanishes, this obstruction is eliminated for the strip.

2. Closed forms outside dlogK
×

Even if an epsilon-factorized strip gauge exists, a returned closed algebraic form can have:

a nonprincipal residue divisor;

a nonzero holomorphic or second-kind component;

a genuine higher-order pole;

nonconstant divisorial residues.

Any of these can obstruct representation as a constant combination of dlogL with L∈K
×
. This is a genuine mathematical obstruction, particularly when the residual curve has positive genus.

A failed finite letter census is not such a proof; an exact divisor or de Rham obstruction is.

Separate later obstruction

Whole-family regulator factorization may still fail even after every strip is exact-dlog certified. The final family transformation must make the complete connection proportional to ϵ with an ϵ-independent kinematic matrix—the canonical-form condition. 
arXiv

That is not a 20→18 strip blocker and should remain a separately typed family-level stage.

Implementation limitations only

These do not establish mathematical obstruction:

the package reconstructs only at fixed ϵ;

Automatic returns closed forms without potentials;

the scratch support bound is too small;

normalization columns drift across images;

insufficient ϵ-degree bounds;

failure to factor candidate norms;

a shared-code exact checker;

one or several inconsistent modular ansatzes.

Immediate route

Capture and hash the exact 20→18 rank-one strip.

Run the exact dependency-graph preflight.

Use the scratch prototype with the package’s two-grade assembler, fixed normalization, cross-ϵ batching, and cross-prime reconstruction.

Require an independent characteristic-zero two-grade residual.

Pull inherited diagonal letters and attempt targeted algebraic-factor/norm closure for only the new forcing forms.

Certify DLogFormCertified externally if the full exact dlog span passes; retain family regulator factorization as a later, separate gate.
