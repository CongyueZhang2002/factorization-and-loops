# ppHX double-real regeneration

Verified model: gpt-6-pro; request HTTP 200.
Conversation: 6aa2eb2d-5588-83e8-bf9d-d35cd8d66f3b.

## Question

Review a scientific/regeneration decision for FeynFacet, using GPT-6 Pro. Current GitHub source baseline is https://github.com/CongyueZhang2002/factorization-and-loops/commit/8bfd19c584a5f79a2090def3043bc1f55a03ca5d; today's unpushed cleanup centralizes card/epsilon/finalization logic. User asks whether ppHX UU NNLO double-real is stale and says rerun it if so. We are restricting scope to u d -> observed u + d g g including ghost subtraction, NOT a complete NNLO hard function or extra quark-pair channels.

Evidence:
- Existing September 7 result was relocated, byte-for-byte, under Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/Results/DoubleReal. All 93 assembly inputs still exist at relocated paths; 0 original paths exist. Old compound result is self-contained.
- Existing 91 DE systems cover 345 requested master positions; full master AMFlow comparison 345 masters/2220 coefficients at simplex v=1/4,w=1/5 passed. No claim this is a globally minimal master basis.
- Existing complete bare result: epsilon -8..0, five delta derivative records, 36 generalized plus records; explicit finite algebraic/integral definitions, no unknown boundary constants. The unwanted stronger endpoint distributions/poles cancelled >60 digits at v=1/4 ONLY. They were correctly retained; no symbolic zero claim. Representation excludes v=1/3,1/2,2/3,3/4 and was only established in interval containing v=1/4.
- Current standard common PartonicResult supports only delta (derivative 0) and [log^k(z)/z]_+; its conversion refuses stronger generalized plus or delta derivatives. Thus simply relabeling this result as a current standard result is invalid.
- Old source cards carry generic spin-transfer vectors with helicity/transversity distributions disabled, current UU cards explicitly set all spins to zero. Other changed inputs include explicit Laurent valuation, typed symbol contexts, and flavor declarations. We should regenerate or prove equivalence, not silently stamp fresh identity.
- Existing pre-master path can now construct 666 independent Hermitian contractions for the 36x36 gluon grid and 28 for the 7x7 ghost grid.

Plan: regenerate current-card contributions and rational coefficients using the established pre-master code, compare/identify reusable mathematical master definitions, then regenerate DE/finite boundary/endpoint data through general code. Keep old result as a reference until a new result passes. Do not discard stronger distributions by numerical sampling, and do not use a literature result as production input.

What is the most economical mathematically justified route to the standard endpoint basis? Can an exact bound on the original summed physical phase-space integrand at the soft endpoint, plus the general distribution uniqueness argument, establish that higher delta derivatives/stronger plus coefficients in the intermediate representation vanish, avoiding massive symbolic simplification of Chen integrals? What assumptions are indispensable (all endpoint regions, epsilon uniformity, angular/collinear sectors, full physical sum vs each family, tangential domain)? We have one shared compact-cut convergence certificate, exact rational coefficient cancellation and multivariable endpoint normal-crossing/germ code from SIDIS. Prefer concrete reusable algorithms, no process-name or selected-family exceptions. Distinguish an actual theorem we can implement from a tempting but unproven power-counting assertion.


## Pro response

Your regeneration decision is correct, with one important qualification: the September 7 result is not established as a current-card standard result, but relocation and card changes do not invalidate reusable mathematical master solutions. Regenerate the current physical coefficients and the affected dependency chain; do not automatically repeat every master calculation.

The endpoint shortcut can be a theorem, not merely an expectation. A uniform endpoint bound for the complete regulated physical density, together with a proved distribution-valued identification of the stored representation, can establish that its canonically collected higher delta derivatives and stronger plus coefficients vanish—without simplifying their Chen-integral expressions. A fixed-angle bound, a bound after setting ϵ=0, or generic-kinematics equality alone cannot do this.

The local artifact and validation inventories below are taken from your supplied evidence. The code-specific observations refer to 8bfd19c, not the unpushed cleanup.

1. What actually needs regeneration

The three issues should remain separate.

Relocation is a dependency-path issue. On your inventory, the old compound result remains self-contained, and all 93 inputs remain available at their relocated locations. Zero surviving original paths does not establish that the mathematical result is wrong.

The changed cards are a semantic-equivalence issue. Explicit zero spins, the former disabled spin distributions, flavor declarations, symbol contexts, and Laurent valuations must be compared after resolving the actual physical request. They may produce equivalent mathematics, but that equivalence must be established rather than stamped onto old output. Regenerating the current-card contractions and rational coefficients is an appropriate way to resolve this.

The distribution format is a mathematical issue. The current adapter explicitly requires derivative order zero for delta records and power −1, subtraction order one for plus records. Its refusal of the old generalized basis is therefore correct, not an inconvenience to bypass.

My recommendation is therefore:

Regenerate the physical source and coefficients; reuse exactly identified integral definitions and their valid solutions; establish the endpoint reduction before invoking the standard-basis adapter.

The 345-master comparison is strong numerical validation of those requested positions at the tested point. It does not establish current-card coefficient equivalence, endpoint contact terms, or validity across the excluded tangential values. Nor does this regeneration require adding quark-pair channels or attempting a complete NNLO hard function.

2. The precise theorem you need

Let I be an open tangential interval containing v=1/4, and write the physical normal coordinate as z, with endpoint z=0. Use the actual density convention and plus interval 0≤z≤Z(v).

Define the regulated physical distribution through the original complete physical cut integral:

⟨T
ϵ
	​

,φ⟩=∫
Φ
phys
	​

	​

dΦ
ϵ
	​

W
phys
	​

(p;ϵ)φ(v(p),z(p)),

where W
phys
	​

 includes the complete gluon contribution, interference weights, ghost subtraction, and all normalization factors.

A useful sufficient theorem has three hypotheses.

A. The endpoint extension is physically anchored

There is a nonempty open regulator domain on which the defining integral and the representation being accepted have equal pairings against all smooth test functions supported in the stated tangential domain, including functions nonzero at z=0. Their common distribution-valued family admits meromorphic continuation to ϵ=0.

An equivalent independently proved construction of that same continuation is sufficient. Equality only for z>0 is not.

This matches an important distinction already present in your joint-cut design: generic identities are extended by common convergent test-function pairings, and endpoint-supported differences are excluded by that equality. The design also explicitly warns that convergence does not establish a uniform truncated endpoint expansion.

B. The physical endpoint germ is uniformly logarithmic

Uniformly on every compact K⋐I, the complete density has a regulated endpoint expansion of the form

F(v,z,ϵ)=
ℓ
∑
	​

a
ℓ
	​

(v,ϵ)z
−1+λ
ℓ
	​

(ϵ)
(logz)
m
ℓ
	​

+R(v,z,ϵ),

where λ
ℓ
	​

(0)=0, the coefficients are meromorphic with finite pole order, and the remainder has a Laurent expansion whose required coefficients are locally integrable in z.

The remainder statement must hold in an integrable norm after the necessary regulator poles and explicit powers have been extracted—not just pointwise for fixed z. A local expansion is enough; a collar cutoff can be used and subsequently reconciled with the recorded plus convention.

More generally, an endpoint expansion with all density exponents at ϵ=0 at least −1, and finite logarithmic multiplicities, suffices.

This hypothesis is the substantive endpoint bound to prove. It is not something to infer merely from the process being double-real.

C. The intermediate representation is genuinely normalized as a distribution

Before applying uniqueness:

Collect the coefficients of identical generalized distributions.

Move normal-coordinate dependence out of delta/plus coefficients using exact distribution identities and endpoint Taylor subtraction.

Require the object called the regular remainder to be genuinely locally integrable.

Keep the same interval, density Jacobian, and contact-term convention.

For example, zδ
′
(z)=−δ(z). A record containing a higher derivative is not necessarily a forbidden higher-derivative contribution until its coefficient has been normalized.

Conclusion and proof

Under these hypotheses, every required Laurent coefficient has the form

T
n
	​

(v,z)=A
n
	​

(v)δ(z)+
k=0
∑
K
n
	​

	​

B
nk
	​

(v)[
z
log
k
z
	​

]
+,Z(v)
	​

+R
n
	​

(v,z).

The elementary reason is that only one endpoint Taylor subtraction is needed:

∫
0
Z
	​

z
−1+β
φ(z)dz=
β
Z
β
	​

φ(0)+∫
0
Z
	​

z
−1+β
[φ(z)−φ(0)]dz.

Meromorphic continuation and differentiation in β generate delta and logarithmic plus distributions, but never φ
′
(0),φ
′′
(0),…. Terms integrable at ϵ=0 contribute to the regular remainder.

In scaling-degree language, the normal singularity has degree at most one. Extensions preserving that degree can differ by a delta, but not by its derivatives. Scaling degree alone does not fix the remaining delta ambiguity; the physical continuation in hypothesis A fixes it. This is the one-dimensional instance of the distribution-extension theorem. 
arXiv

Consequently, if the old or regenerated generalized representation is proved to represent this same T
ϵ
	​

, its collected forbidden coefficients are exact zero functions on I. That is a legitimate theorem-backed simplification even when their stored special-function expressions never simplify syntactically to zero.

Two limitations are crucial:

The theorem does not validate an otherwise unverified representation. “The physical answer cannot contain δ
′
” cannot repair missing endpoint terms or an invalid interchange of limits.

It does not determine the surviving delta coefficient from the bulk alone. That coefficient still requires the regulated endpoint germs or an equivalent physical moment. With the stated plus convention, when the remainder is integrable over the interval,

A
n
	​

(v)=[ϵ
n
]⟨T
ϵ
	​

(v,⋅),1⟩−∫
0
Z(v)
	​

R
n
	​

(v,z)dz.

Usually your existing regulated endpoint moments are cheaper than introducing a new inclusive integral.

3. Try the summed master-row certificate first

Given your existing infrastructure, this may be cheaper than resolving the entire original phase-space integrand afresh.

Write the regenerated scalar density as

F=c
phys
	​

(v,z,ϵ)J(v,z,ϵ),

after exact main/ghost identification and combination. In a verified endpoint frame, write schematically

J=T(v,z,ϵ)H(v,z,ϵ)z
R(v,ϵ)
a(v,ϵ),

with H normally analytic and uniformly regulator-regular after a finite meromorphic rescaling.

The first sufficient test is:

q(v,z,ϵ)=zc
phys
	​

(v,z,ϵ)T(v,z,ϵ)is jointly analytic in the normal coordinate,
	​


up to pure regulator poles and explicitly retained analytic factors. Together with the appropriate residue exponents, complete physical matching, and uniform Frobenius control, this proves that F has no power stronger than 1/z.

This uses exact rational cancellation before special-function evaluation. It asks about the physical row, not the worst behavior of every component of the master vector.

Your baseline already has relevant checks in AnalyzeNormalCrossingScalarCoefficients, VerifyUniformNormalCrossingPhysicalGerm, and VerifyRadialEndpointCollar: coefficient contraction with the gauge, joint regulator-coordinate denominator checks, nonresonance, and physical-seed conditions. The code also explicitly distinguishes a verified scalar germ from an inferred endpoint-remainder result.

There are two implementation qualifications.

First, the present verifiers use a selected physical eigenvector structure. A full result with several regulator-power classes or Jordan logarithms must include every populated physical class. Either certify the relevant classes separately and combine them, or generalize the verifier to the complete invariant physical subspace. Logarithms are allowed by the theorem; silently omitting populated modes is not.

Second, analyticity of the full row is sufficient but not necessary. If q still has poles, cancellation may occur only after contraction with the physical solution. Provided all joint analytic-unit conditions are already established, compute only the finitely many Frobenius jets needed to inspect the forbidden powers. If those projected rows vanish exactly on the complete physical boundary subspace, the remaining analytic tail cannot reintroduce a forbidden power.

Do not use this finite-jet shortcut while a divisor such as z+τ(ϵ,v) remains unresolved. Its joint regulator-normal behavior must first be cancelled or treated by a valid joint analysis.

A failed row test should return unresolved by this sufficient criterion, not force a generalized-basis result and not trigger arbitrary coefficient deletion.

4. An implementable original-integrand theorem

When the master-row route is obstructed, the original physical integrand offers a clean alternative. The reusable algorithm should certify orders along a complete resolved endpoint geometry, rather than evaluate the integrals.

After resolving the physical boundary, suppose each chart has density

dν
ϵ
	​

=a(r,y,v,ϵ)
i=1
∏
N
	​

r
i
A
i
	​

+B
i
	​

ϵ
	​

r
i
	​

dr
i
	​

	​

dy,

and measurement map

z=u(r,y,v)
i=1
∏
N
	​

r
i
m
i
	​

	​

,m
i
	​

≥0,

where u is a positive analytic unit. The factor a is smooth on the resolved chart and jointly regulator-regular after extracting finitely many pure ϵ-poles.

All measure factors, Jacobians, numerator vanishing orders, and physical normalizations are included in the A
i
	​

.

A concrete sufficient condition is

A
i
	​

≥0for every resolved boundary divisor with m
i
	​

>0.
	​


Divisors with m
i
	​

=0 still require convergence or explicit meromorphic subtraction in the fiber variables. They are not to be ignored.

Why this criterion works

Introduce a Mellin variable σ:

M(σ,ϵ)=∫z
σ
dν
ϵ
	​

.

In a chart, the powers become

r
i
A
i
	​

+B
i
	​

ϵ+m
i
	​

σ
	​

.

Taylor expansion of the smooth factors gives candidate Mellin poles

σ=−
m
i
	​

A
i
	​

+B
i
	​

ϵ+n
i
	​

	​

,n
i
	​

∈N
0
	​

,m
i
	​

>0.

At ϵ=0, the stated condition permits no positive Mellin poles. A density z
−p
, p>1, would produce a pole at σ=p−1>0. Coincident poles can produce logarithms, but do not produce a more singular power.

This is the local monomial form of the pushforward argument: resolved density exponents and the orders of the measurement map determine the endpoint index set. The pushforward theorem also makes explicit why fiber-face integrability and coverage of intersecting faces are necessary. 
Carl von Ossietzky Universität Oldenburg
+1

For an endpoint-mapped marginal face, the pole at ϵ=0 comes from the zeroth normal Taylor coefficient of the pulled-back test function. That coefficient depends on φ(0), not its derivatives. With the common meromorphic continuation, this also controls the contact terms.

How to make this economical

The algorithm should resolve the denominator/measurement geometry, then ask only for enough exact numerator information to determine the relevant orders.

Combine before taking absolute values. Work with the full physical rational sum in common coordinates, or with independently proved complete groups. Taking absolute values of individual gauge-dependent contractions can destroy precisely the cancellation that improves the endpoint bound.

Compute valuations locally. In each resolved chart, cancel rational factors and determine numerator divisibility or the required leading jets. You do not need one enormous globally expanded rational numerator, and you do not need to integrate the resulting coefficients.

Keep D, hence ϵ, symbolic. A numerator that vanishes only at D=4 has not established the regulated valuation.

Certify every exceptional divisor. Checking only the original soft and collinear coordinates misses divisors introduced by resolving their intersections.

This is closely aligned with constructive sector decomposition: isolate overlapping singularities into monomial factors before expansion. Its use here is an exact order certificate, not a replacement of your analytic production solution by numerical integration. 
arXiv

The criterion is sufficient, not necessary. Negative candidate orders may still disappear after further exact cancellation or integration. Such a chart is unresolved, not proof that the physical result really requires stronger distributions.

5. The indispensable assumptions—and useful failure tests
All endpoint regions, including energetic collinear configurations

An all-soft rescaling is not an exhaustive analysis of a recoil-invariant endpoint. The relevant cover must include energetic collinear recoil configurations, soft-collinear overlaps, strongly ordered limits, angular boundaries, and their intersections.

Tree-level double-unresolved factorization provides strong physical motivation for logarithmic endpoint behavior, but turning it into this certificate requires connecting all its limits to your measurement and covering their overlaps. The general soft/collinear factorization formulas are not themselves a coverage proof for a particular phase-space parametrization. 
arXiv

A simple adversarial example is

∫
0
1
	​

(z+x)
3
dx
	​

=
2z
2
1
	​

−
2(z+1)
2
1
	​

.

At every fixed x>0, the integrand is finite as z→0. The stronger endpoint power comes entirely from the missed region x∼z.

Thus, a “bound at generic angles” is insufficient unless its angular majorant is integrable uniformly or the singular angular sectors have been explicitly resolved.

Regulator uniformity, not merely four-dimensional power counting

There is an especially relevant counterexample. Under canonical meromorphic continuation,

ϵz
+
−2−ϵ
	​

=δ
′
(z)+O(ϵ).

Its finite bulk coefficient at every z>0 is zero. Nevertheless, the linear Taylor term of a test function gives

ϵ∫
0
Z
	​

z
−1−ϵ
φ
′
(0)dz=−Z
−ϵ
φ
′
(0),

which tends to the action of δ
′
(z).

Therefore, a bound obtained after setting ϵ=0 can miss a finite higher delta derivative. Evanescent coefficients and endpoint poles must be treated together.

Likewise, 1/(z+ϵ) shows why fixed-coordinate regulator valuations do not establish joint analyticity. The relevant denominator must be a pure regulator power times a genuine joint analytic unit, or receive a separate resolved treatment.

Even common convergence at large dimension is insufficient by itself: z
−2−ϵ
 is integrable for sufficiently negative Reϵ, yet has a stronger endpoint power at ϵ=0.

The complete physical sum—not each family

The required statement concerns the scoped ud→u+dgg physical contribution with its ghost subtraction and correct weights.

There is no requirement that every master, completed family, partial-fraction term, or Hermitian contraction separately satisfy the physical 1/z bound. Imposing that would be unnecessarily strong and often counterproductive.

Conversely, proving the bound for the gluon grid alone does not automatically establish it for a differently normalized or incompletely combined physical result. The certificate must refer to the exact sum being stored.

The same distinction matters for the convergence bridge. Your joint-cut design allows final certified terms or independently regularized combinations; it does not automatically grant joint endpoint validity to arbitrary dotted intermediates.

The tangential domain must remain explicit

Prove uniformity on every compact subset of the declared interval I, with branches and prescriptions fixed there. This establishes coefficient identities throughout that interval, not merely at v=1/4.

It does not remove the exclusions at 1/3,1/2,2/3,3/4, prove their removability, or establish the other physical intervals. Those require valid chart transitions or additional domain certificates. Physical tangential endpoints require the corresponding joint corner analysis.

The radial-collar interface is explicitly scoped to compact subsets of a declared open tangential interval; retain that qualification in the accepted result.

Endpoint-power bounds and regulator-pole bounds are different

A proof that only delta and logarithmic plus distributions occur does not, by itself, prove the disappearance of particular ϵ
−8
,… coefficients. Angular/fiber poles, endpoint poles, and dimensional prefactors determine the regulator pole order separately.

Similarly, this bare double-real contribution is not expected to pass a complete NNLO pole-cancellation/finiteness gate. Do not conflate conversion to the standard endpoint basis with finalization of a finite hard function.

6. Recommended regeneration sequence

1. Regenerate the current-card physical source. Use the 666 and 28 independent Hermitian contractions, retaining exact conjugation and off-diagonal interference weights. Include all ghost and identical-particle factors before making the physical comparison. Compare the resulting rational physical integrand or coefficient representation with the appropriately interpreted old one.

2. Match mathematical integral definitions before recomputing solutions. Reuse requires equality of the actual cut definitions, routing and kinematic map, prescriptions, normalization, and regulator convention—not equality of a family label. The changed numerator/spin request may alter coefficients and required Laurent depth without changing any scalar master definition. Recompute only unmatched definitions and invalidated or insufficient descendants.

3. Establish the standard-basis theorem for the regenerated sum. First try exact coefficient contraction in the existing uniformly verified endpoint frame. If that sufficient test fails, use the original-integrand resolved-valuation certificate or a complete physical-subspace projection. Keep the existing shared compact-cut theorem for the distribution-valued identification; do not duplicate it with a weaker ad hoc convergence assertion.

4. Assemble directly in the proved basis. Generate the allowed leading germs and the genuinely integrable remainder, propagate their epsilon demands, and determine the delta coefficient from the regulated construction. Endpoint integration can require an extra regulator order even when the corresponding bulk coefficient is already known. Only then call the standard adapter.

The old generalized result can remain a numerical and structural reference throughout. The new output need not first manufacture enormous forbidden Chen-integral coefficient expressions and then simplify them. But claiming those old expressions are exact zero additionally requires proving that the old generalized distribution is the same physically continued object.

Bottom line

Approve the scoped regeneration with mathematical reuse. Approve theorem-driven elimination of stronger distributions only after both the physical distribution-identification and uniform endpoint-order hypotheses are established.

The most economical first attempt is the exact summed-row test in your existing endpoint frame. The most concrete reusable fallback is a complete resolved phase-space valuation certificate, with nonnegative density orders on every divisor mapped to the endpoint. Neither requires evaluating or simplifying the Chen integrals.

Until one of those routes actually passes—with complete physical matching, regulator uniformity, and the declared tangential domain—the stronger records must remain. The cancellation observed at v=1/4 is valuable validation evidence, but not an acceptance rule for deleting them.
