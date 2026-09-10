# Cut-preserving symmetries and SIDIS denominator signs

Verified model: gpt-6-pro; request afe2940a-478b-44a4-9627-ef6ddc67a480; HTTP 200.

## Question

Follow-up on review09: one important generality issue before launching RR reductions.

Our new typed-family entry reuses the existing Kira exporter/execution/import/closure path. Each record distinguishes particle cuts (momentum, forward energy relative to a timelike reference) and a linear measurement cut, and preserves ordinary propagator signs. However Kira's native cut_propagators list only marks mandatory cut indices. It does not encode energy orientation, distinguish types, or attach ordinary i0 signs to each sector-symmetry map. Checking that returned masters retain every cut is not by itself a proof that all internal/inter-family symmetry relations preserve the physical period.

For the 2-body measured prototype, the actual Kira symmetry files are empty; reduction and all z identities agree with an independent Beta integral. For SIDIS RR we have p^2=0,q^2=-Q2,p.q=Q2/(2x); P=p+q future timelike, x,z in (0,1); particle momenta k1,k2,k3=P-k1-k2 and tagged linear cut G=2p.k1-zQ2/x. RV particle momenta k1,k2=P-k1 plus a separate virtual loop. All ordinary causal signs retained in records.

1. Is the usual Kira cut-aware symmetry machinery sufficient here because preserving the complete cut polynomials plus the total future timelike P forces a permutation of forward cut momenta? Please give the actual limited theorem or a counterexample, including raised cuts and possible mixing of phase and virtual loop variables.
2. What minimal generic check should our adapter perform on each allowed routing? E.g. particle q_i -> +q_perm(i), linear G -> positive/negative scale with C_n scaling, no particle/measurement exchange, causal signs for ordinary slots, and measure Jacobian. How can this be made safe if Kira does not export complete momentum maps? Is a documented setting that disables symmetry relations without disabling IBP available? run_symmetries:false appears to control an execution stage rather than prohibit all symmetry use.
3. Should we generate our own sparse IBP/LI equations and pass them to Kira's user-defined-system solver to avoid unaudited identifications? This is a bounded general linear-algebra backend, but I want to avoid unnecessary parallel production paths. We already have the inverse-propagator basis matrix, cut-zero rule, and fixed-component derivative generator.
4. Separately, is this simple sign observation correct for ordinary massless SIDIS RR denominators? For any future causal subset K of final particles, P-K is future causal, hence in the P rest frame E_K+|K|<=sqrt(P^2). Since 2E_p=sqrt(P^2)/(1-x)>sqrt(P^2), (p-K)^2=(E_K-|K|)(E_K+|K|-2E_p) if K is parallel to p at the maximizing orientation, and is <=0 generally. Pure final-subset denominators K^2 are >=0. This proves interior sign under nondegeneracy but does NOT alone prove an ordinary-i0 limit or uniform endpoint convergence. Could it be useful for a later extension of the existing single convergence certificate?

Recommend the smallest mathematically justified next step; no silent replacement of a cut and no inference of physical validity from numerical agreement alone.

## Pro response

Your concern is correct: cut_propagators alone does not certify that Kira’s identifications preserve the physical cut integral. Your denominator-sign observation is also correct. There is a useful theorem for real affine routings of your RR and RV families, but it does not automatically cover every symmetry relation that a scalar-integral program can discover.

The smallest justified change is to add a routing validator at the equation-generation boundary. When the native relations cannot be exhaustively recovered and filtered, use a small generator of your typed IBP equations with Kira’s topology-independent user-system solver. That preserves Kira as the linear-algebra backend and does not require a second reduction engine.

1. What preserving the quadratic cuts actually proves
1.1 A limited affine-routing theorem

Consider the RR momenta

q
1
	​

=k
1
	​

,q
2
	​

=k
2
	​

,q
3
	​

=P−k
1
	​

−k
2
	​

,

with fixed, nonzero external P. Allow additional unconstrained virtual loop momenta. Suppose a candidate change of variables is a real, invertible, scalar-affine routing,

ℓ
r
′
	​

=
s
∑
	​

A
rs
	​

ℓ
s
	​

+
a
∑
	​

B
ra
	​

p
a
	​

,

with coefficients depending only on external invariants.

Assume that:

The external point is fixed, or transformed by an explicitly allowed time-orientation-preserving external transformation.

The target directed particle momenta also sum identically to the same P.

Each target mass-shell polynomial pulls back to a source mass-shell polynomial, up to a nonzero scalar:

q
i
′
	​

(ℓ
′
)
2
=a
i
	​

q
π(i)
	​

(ℓ)
2
.

These are polynomial identities before imposing the cuts, at generic external kinematics.

Then, for these RR momenta,

q
i
′
	​

(ℓ
′
)=q
π(i)
	​

(ℓ).
	​


In particular, all forward-energy conditions are preserved.

Proof. Write an affine momentum as

r=u
s
	​

ℓ
s
	​

+v
a
	​

p
a
	​

.

Comparing the coefficients of ℓ
s
	​

⋅ℓ
t
	​

 in

r
2
=aq
j
2
	​


gives an equality of rank-one matrices. For a real routing, this implies that the loop-coefficient vectors are proportional. Comparing the independent ℓ
s
	​

⋅p
a
	​

 coefficients then gives the same proportionality for the external part:

r=cq
j
	​

,c
2
=a.

The nondegenerate external Gram matrix ensures that this comparison does not leave an undetected external vector.

After reordering by π, conservation requires

c
1
	​

k
1
	​

+c
2
	​

k
2
	​

+c
3
	​

(P−k
1
	​

−k
2
	​

)=P.

Because this is an identity in the independent integration vectors,

c
1
	​

=c
3
	​

,c
2
	​

=c
3
	​

,c
3
	​

P=P,

hence c
1
	​

=c
2
	​

=c
3
	​

=1.

The same proof applies to RV with

q
1
	​

=k,q
2
	​

=P−k.

Thus, a genuine real affine permutation of the complete particle-cut polynomials, together with directed momentum conservation at fixed P, is enough to establish their forward-energy preservation. One need not solve inequalities separately for each such routing.

1.2 Raised cuts do not invalidate this theorem

The conclusion is stronger than equality on the mass shells:

q
i
′
	​

∘F=q
π(i)
	​


holds off shell as an affine-vector identity. Therefore it preserves the full cut normal coordinates and their positive-energy extensions:

θ(τ
′
⋅q
i
′
	​

)C
ν
i
	​

	​

(q
i
′2
	​

)⟼θ(τ⋅q
π(i)
	​

)C
ν
i
	​

	​

(q
π(i)
2
	​

),

for every finite positive ν
i
	​

, with consistent future-timelike references and the same meromorphic cut definition.

No new massless-tip or normal-derivative argument is needed for an exact permutation of the directed momenta. By contrast, equality only modulo the cut ideal is insufficient for dotted cuts.

1.3 The RV consequence is a block-triangular restriction

In coordinates adapted to the cut momenta, preservation of the complete particle cuts forces

(
k
phase
′
	​

ℓ
virtual
′
	​

	​

)=(
A
ϕϕ
	​

A
vϕ
	​

	​

0
A
vv
	​

	​

)(
k
phase
	​

ℓ
virtual
	​

	​

)+external shifts.

A virtual loop may be shifted by a real phase-space momentum. A particle-cut momentum cannot acquire dependence on an unconstrained virtual loop while still satisfying the theorem’s polynomial identities.

This is a statement about roles, not variable names. Renaming the phase and virtual loop variables is harmless when their roles and cut definitions move with them.

1.4 Why this is not a blanket certification of Kira symmetries

First, squared polynomials by themselves forget energy orientation. For future-timelike P,

I
++
	​

=∫d
D
kδ
+
	​

(k
2
)δ
+
	​

((P−k)
2
)

is nonzero, whereas

I
+−
	​

=∫d
D
kδ
+
	​

(k
2
)δ
+
	​

((k−P)
2
)

vanishes. The two records have identical quadratic polynomials. In the P rest frame, both mass-shell equations require k
0
=
P
2
	​

/2, so k−P is past directed. The second record fails the directed-conservation hypothesis.

Second, a simultaneous reversal of external and integration momenta preserves scalar products but reverses the physical time orientation. Preserving the external Gram matrix is not, on its own, preservation of the physical external configuration.

Third, Kira’s documented symmetry machinery includes relations identified through parametric representations, including some that do not have a loop-routing representation. Such a relation needs a separate proof for the selected cut period; the affine-routing theorem does not certify it. 
arXiv

Finally, cut_propagators is documented as setting integrals with nonpositive powers of mandatory cuts to zero. That is a useful algebraic rule, not a specification of the integration cycle. 
arXiv

2. Minimal routing checks

Use an exact pullback test. For definiteness, let F map source integration variables into target variables. A routing is acceptable only when the resulting target integrand, including its distributional factors, equals the claimed source expression.

Object	Required check
External configuration	Fixed x,z,Q
2
, or an explicitly declared parameter transformation; preserve the physical time orientation
Integration variables	Real, invertible affine transformation on the actual real integration contours
Particle cuts	Exact permutation of directed momenta, or a separately supported positive rescaling
Measurement cut	Exact pullback to a nonzero scalar multiple of the target measurement polynomial
Ordinary denominators	Correct polynomial pullback and causal-sign transformation
Numerators	Transform all numerator scalar products, including auxiliary slots
Normalization	Include loop Jacobian, cut rescalings, measurement prefactor, and any family normalization
Claimed relation	Match the complete relation and its coefficient, not just the corner’s denominator set
Particle and measurement cuts must remain distinct

For this initial implementation, reject particle/measurement exchanges and non-diagonal changes of cut normal coordinates.

For a measurement transformation

G
′
∘F=aG,

where a is real, external-only, nonzero, and has a known sign throughout the chart,

C
ν
	​

(aG)=sgn(a)a
−ν
C
ν
	​

(G).
	​


In particular,

C
1
	​

(−G)=C
1
	​

(G),C
2
	​

(−G)=−C
2
	​

(G).

A scalar-propagator symmetry factor a
−ν
 alone is therefore not the correct cut factor when a<0. Compare the factor in the actual emitted relation with your typed transformation law.

Include the external measurement normalization J=Q
2
/x once. A parameter-changing relation must transform it as well.

Do not accept

G
′
∘F=aG+
i
∑
	​

b
i
	​

D
i
	​


as the same mapping merely because the extra terms vanish on the unit-cut support. Such a transformation mixes normal derivatives when cut powers are raised. It can be implemented later with the full distributional coordinate transformation; it is unnecessary for the current RR routing validator.

The tag strongly restricts the RR permutation group

At fixed generic z, the particle permutation must also preserve

G=2p⋅k
1
	​

−zQ
2
/x.

For a family whose tag is fixed to k
1
	​

, the evident RR possibilities reduce to the identity and k
2
	​

↔k
3
	​

, subject to the ordinary denominators. Cross-family maps may relabel the tagged slot, but must carry the measurement with that slot.

For the two-particle geometry,

k↦P−k

gives

G(k,z)↦−G(k,1−z).

That is generally a relation between different z-arguments, not a fixed-z sector symmetry. A sample at z=1/2 would conceal the distinction.

Ordinary causal signs require an independent check

Suppose

D
i
′
	​

∘F=a
i
	​

D
π(i)
	​

.

For the ordinary propagator,

(D
i
′
	​

+i0σ
i
′
	​

)
−ν
i
	​

∘F=a
i
−ν
i
	​

	​

(D
π(i)
	​

+i0σ
i
′
	​

sgna
i
	​

)
−ν
i
	​

.
	​


The source prescription must therefore satisfy

σ
π(i)
	​

=σ
i
′
	​

sgna
i
	​

.

An exchange of +i0 and −i0 is not made valid by retaining those signs only in metadata. The emitted equation must preserve them. A conjugation relation is an antilinear statement unless further properties have been proved; it is not automatically another rational linear symmetry equation.

For genuine real changes of integration variables preserving these factors, no separate contour deformation is involved. Complex routings or parameter continuation require additional branch information and should be outside the first implementation.

Jacobians and numerator slots

For

ℓ
′
=Aℓ+Bp,

the real integration measure transforms with

r
∏
	​

d
D
ℓ
r
′
	​

=∣detA∣
D
r
∏
	​

d
D
ℓ
r
	​

.
	​


The initial implementation can restrict to ∣detA∣=1, which covers the basic RR permutations. Do not use a signed determinant as an extra loop phase.

A map that permutes the active denominator slots may transform auxiliary numerator slots into linear combinations. Validate that complete transformation. Checking only unit-index corner integrals does not establish the relation for numerator-bearing targets.

Also separate index reordering from physical routing. Kira 3 can reorder propagators internally by default; this is a bookkeeping permutation that your cut-type and prescription arrays must follow, not evidence of a physical symmetry. 
arXiv

3. Missing momentum maps and Kira’s controls
Reconstructing a witness is enough

You do not need the exact map used internally by the finder if you can independently construct a valid routing that proves the emitted relation.

For RR this is inexpensive: enumerate the permutations of the three directed particle momenta, solve for the induced loop routing, and test the measurement and ordinary slots. There are only six initial candidates, usually fewer after tagging.

For RV, the particle-cut mapping fixes the phase-space part. Solve the remaining affine virtual-loop routing against the ordinary denominators.

If no valid witness is found, do not conclude that the scalar relation is false. Conclude that it is not authorized for this physical period by the implemented theorem.

The enforcement must occur before an unverified relation can eliminate integrals. Correcting a mapping coefficient after importing a completed reduction does not generally undo its earlier use.

run_symmetries: false is not a verified global veto

The published options describe run_symmetries as a preparation stage. The release documentation also states that symmetry and trivial-sector information is reused independently of conditional. Thus neither flag establishes a fresh reduction free of previous symmetry identifications. 
GitLab
+1

Inspect both internal-sector and inter-sector/inter-family relations, as well as any automatic zero-sector decisions. A file named “symmetries” being empty does not establish that every other identification channel is empty.

I did not verify a documented native reduce_sectors setting that globally prohibits all symmetry generation, canonicalization, and reuse while retaining only IBP/LI. That is a limitation of what I could establish from the published interfaces, not a claim that no source-level hook exists in your installed build.

Kira 3’s extra_relations option adds equations; it is not an exclusion mechanism for native relations. 
arXiv

A fresh working directory is necessary when changing these semantics, but it is not sufficient to disable native symmetry discovery.

What would justify keeping the native generator?

Keep it when you can establish that:

every identification it may use has been recovered and validated, or excluded before use;

automatic zero sectors have an applicable justification;

the emitted coefficient factors agree with your cut and prescription conventions.

An empty, comprehensively inspected relation set is a valid special case. The two-body prototype gives useful evidence for that job, but not a theorem about the RR initialization.

4. A small typed IBP generator is a reasonable fallback—not a second reduction engine

Given the infrastructure you already have, generating the basic equations is bounded work.

For L=2, E=2, use

v∈{ℓ
1
	​

,ℓ
2
	​

,p,q},r=1,2,

in

0=∫
s
∏
	​

d
D
ℓ
s
	​

∂
ℓ
r
μ
	​

	​

[v
μ
i
∏
	​

F
ν
i
	​

	​

(D
i
	​

)].

There are eight basic IBP operators per seed, as in the standard Laporta construction. 
arXiv

Your complete inverse-denominator basis gives

v⋅∂
ℓ
r
	​

	​

D
i
	​

=c
ri,v,0
	​

+
j
∑
	​

c
ri,v,j
	​

D
j
	​

.

Hence the equation is directly

0=
	​

Dδ
v,ℓ
r
	​

	​

I
ν
	​

−
i
∑
	​

ν
i
	​

[c
ri,v,0
	​

I
ν+e
i
	​

	​

+
j
∑
	​

c
ri,v,j
	​

I
ν+e
i
	​

−e
j
	​

	​

].
	​

	​


The same index-shift rule applies to ordinary denominators and your defined cut distributions. Apply the mandatory-cut zero rule, retaining the full normal information for positive powers.

This uses the cut-IBP scope established in your previous review; it does not introduce an additional theta-derivative prescription.

Start with these IBPs. LI equations can be added from the existing machinery if useful, but they need not delay the first reduction. Do not begin with a new syzygy or tangent-vector subsystem merely to avoid this symmetry issue.

The documented isolation point is user-system mode without topology configuration

Kira documents

YAML
input_system:
  files: [equations.kira]
  config: false

within its user-defined-system workflow. With config: false, the topology definitions are not used. It also supports user-assigned integer weights, allowing the unknowns to be supplied as opaque linear-system variables. 
arXiv
+1

That is the clean boundary you need:

typed, justified equations⟶Kira linear solver⟶existing import and closure checks.
	​


Keep one central identifier map back to your typed integrals. Include particle orientation, measurement definition, and ordinary prescription assignment in that identity. Different causal periods must not become the same unknown accidentally.

Use the existing solver, reconstruction, import, master-closure, and DE infrastructure. Only the equation source changes. Do not maintain two separate implementations of integral normalization or result assembly.

Two cautions:

A system exported from native Kira initialization is not automatically “IBP only”; it may already incorporate identifications. Either verify its provenance or emit the basic equations directly.

User-system mode does not turn missing equations into zeros. Increase the seed closure or retain additional masters when necessary. Do not force the expected literature master count.

If using Kira’s on-the-fly user-system solver, order equations approximately by complexity; its documentation warns that poor ordering can substantially impair runtime. 
arXiv

This fallback can be limited initially to typed measured-cut families. It does not require replacing the validated ordinary-loop workflows.

5. The SIDIS denominator-sign argument is correct—and extends to positive cut masses

Let

M=
P
2
	​

,p=(E
p
	​

,E
p
	​

n
^
)

in the P rest frame. Since

p⋅P=
2x
Q
2
	​

,P
2
=
x
Q
2
(1−x)
	​

,
2E
p
	​

=
1−x
M
	​

>M.
	​


For a future-causal subset sum

K=(E,K),R=∣K∣,

both K and P−K future causal imply

E≥R,M−E≥R,

hence

E+R≤M.

Writing cosθ=
n
^
⋅K/R,

(p−K)
2
	​

=E
2
−R
2
−2E
p
	​

(E−Rcosθ)
=
(E−R)(E+R−2E
p
	​

)−2E
p
	​

R(1−cosθ).
	​

	​


Both terms are nonpositive, so

(p−K)
2
≤0.
	​


The equality conditions matter:

If K is timelike and nonzero, the result is strictly negative.

If K is nonzero null, equality requires it to be parallel to p.

K=0 also gives zero.

Similarly,

K
2
≥0,

with strict positivity for a non-null subset sum. An empty subset or a single massless particle does not give a strictly positive ordinary denominator.

A useful immediate extension is

q−K=(P−K)−p,

so

(q−K)
2
≤0
	​


whenever P−K is the complementary future-causal subset.

This is useful for the mass-deformation certificate

The proof used future causality, not the masslessness of each final particle. It therefore survives nonnegative cut-mass deformations at fixed physical p,P, provided the deformed final momenta remain future causal and sum to P.

Restricting that domain by the measurement slice cannot spoil the pointwise inequality. This supplies a genuine reusable part of the proposed extension: the relevant subset denominators keep their weak sign on the permitted deformed domain.

It still does not establish:

a uniform nonzero lower bound at soft/collinear boundaries;

convergence uniform in the masses, regulator, or measurement variable;

equality of the two ordinary causal boundary values after integration;

validity of normal derivatives of a prescription-erased expression.

For example, the first factor E−R can approach zero, and the angular term can vanish simultaneously. The sign theorem controls the direction from which a denominator approaches zero, not the distributional contribution supported there.

It also does not classify arbitrary auxiliary denominators introduced by family completion or denominators involving an unconstrained virtual momentum. Apply it only after proving the denominator has the stated subset form.

Add this as a sign lemma in the existing certificate machinery, not as an i0-removal flag. Retaining prescriptions lets the RR reduction proceed without waiting for the stronger convergence theorem.

6. Smallest justified next step

I recommend the following order.

First, implement the exact routing validator and exercise its rejection cases. Accept the RR exchange k
2
	​

↔k
3
	​

 when the ordinary slots match. Reject a reversed recoil energy orientation, an unaccounted z↔1−z transformation, an ordinary-prescription mismatch, and a mapping that preserves cut equations only modulo other cuts. Test the measurement rescaling at powers one and two. These are algebraic tests, not numerical agreement tests.

Second, perform one RR preparation with exhaustive relation inspection. Reconstruct routing witnesses where possible. If you cannot guarantee that every native identification is either approved or disabled before use, switch the typed family’s equation source to the eight-operator IBP generator and use topology-free Kira user-system mode. Preserve the existing execution/import path and resource limits.

Third, validate that path on the measured three-body volume and a small nontrivial denominator sector, including its x,z derivatives. Then launch the amplitude and DE target closure with prescriptions retained. Add approved symmetries as sparse equations when they reduce cost.

The key distinction is that IBP relations can be shared by many physical periods, whereas symmetry identifications need not be. Your typed records already contain the information needed to enforce that distinction; the missing piece is ensuring it governs which equations enter the solver, rather than checking it only on the final masters.

The unresolved software-specific point is a complete native symmetry bypass in your installed Kira build. The documented stage flags do not establish one; the documented topology-free user-system interface provides the controlled alternative.