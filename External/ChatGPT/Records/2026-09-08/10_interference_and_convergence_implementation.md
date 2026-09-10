# Interference and convergence implementation review

Verified outgoing model gpt-6-pro, HTTP 200.

## Question

User authorized implementing triangular interference and i0 certificates. Please review one concrete conservative implementation, no broad research needed.
Hermitian: at contracted scalar physical numerator (before recoil elimination, tensor/dimensional shift and i*pi^(D/2) measures), save numerator + ordinary/external propagators. Conjugate those with FeynCalc ComplexConjugate (explicit ComplexParameters card option, physical momenta/D/distributions formal-real), exchange forward and conjugate virtual loop variable lists simultaneously. Rebuild phase-space/cuts/normalization and preIBP independently for reverse. Generate direct only upper triangle when diagram sets and loop orders equal; rectangular unequal-loop blocks unchanged; NLO virtual later adds reverse once. No GLI assumed real. Materialize both pair artifacts so complete-coverage checks unchanged.
i0: want automatic undotted massless real-radiation certificate, generic fixed observed kinematics, using actual existing Baikov measure. Code constructs external Gram E from independent ext momenta spanning beams+fixed observed momenta; transverse T = projections E^-1 projections^T - loopGram, all principal minors >=0, positive cut energies, exponent (D-E-L-1)/2. Checks L+1 oriented massless cut momenta, invertible affine routing of L cuts with sum recoil independent of loops and timelike. External span Lorentzian/nondegenerate. Sign bound theorem checks each positive ordinary denominator (rational quadratic/null bilinear) on complete incoming/outgoing massless conservation domain. Z(denominator) consists only soft/beam or pair-collinear degeneracies, hence on cut-domain G=det(T)=0 provided external span includes beams+all fixed momenta. Gram exponent then suppresses all via compact semialgebraic Lojasiewicz, giving open Re D>D* (D* existential, not numerical estimated). Finite polynomial numerators. No dotted cuts, no virtual, no noninteger positive ordinary powers. Would explicit actual T/exponent plus geometry and sign witnesses constitute a sufficient certificate? Any counterexample where a signed denominator vanishes at non-Gram-degenerate physical point (in generic fixed external frame)? If G positive domain empty L > physical transverse rank at4D, construct for real D>E+L-1, not4D.
Scope explicitly only generic fixed-kinematic values, not equality as distributions including endpoint deltas. Cannot silently use this to assert stage4 causal endpoint equality. Uncertified slots retain original SFAD +-i0; cut slots retain oriented delta derivatives. Need parameterizations include those remaining eta signs rather than silently zero. Undotted elementary phase-space formulas without positive ordinary denominators need no removal.
Also could provide resolved unit-cube sector certificate for stronger distribution-smearing cases: integral exactly given as product x_i^(a_i+b_i D) times bounded smooth factors, retained positive polynomials, nonempty strict inequalities a_i+b_i ReD>-1. This proves actual explicit strip, not merely sign. Keep separate from highD geometry.
Please critically identify necessary corrections; repository github.com/CongyueZhang2002/factorization-and-loops, current changes uncommitted. Prior conversation contains sign theorem and Gram proof details.

## Pro response

The high-D certificate is sufficient for the stated undotted, generic fixed-kinematic scope, with explicit domain guards. The principal implementation correction is that FeynCalc’s ComplexConjugate must not be relied upon to flip SFAD prescription metadata. A second correction concerns the sector certificate: positivity of residual denominator polynomials only in the open cube is insufficient.

I reviewed the supplied design and the relevant conjugation implementation; I have not executed the uncommitted changes.

1. Hermitian reconstruction: correct location, but implement prescription conjugation explicitly

Saving the contracted physical scalar numerator before normalized-loop measure factors is an appropriate reconstruction point. Conjugating there, exchanging the two virtual-loop namespaces, and independently rebuilding the reverse pre-IBP artifact avoids assuming that GLIs or normalized masters are real.

However, the inspected ComplexConjugate implementation conjugates explicit complex numbers and specified parameters but contains no transformation of the stored SFAD sign σ. Its scalar-prefactor routine will leave an integer metadata field {power, sigma} unchanged.

For a real inverse core, the required transformation is

[Q+iση]
m
1
	​

⟼
[Q−iση]
m
1
	​

.

Thus the reverse-pair operation needs an explicit, exactly-once transformation

StandardPropagatorDenominator[..., {m,\sigma}]⟼StandardPropagatorDenominator[..., {m,-\sigma}],

together with conjugation of any admitted complex core parameters. This field is precisely where SFAD stores the prescription. 
FeynCalc

The card’s ComplexParameters must be translated into the actual supported conjugation operation; FeynCalc’s relevant option is Conjugate. Its documented restrictions also mean that arbitrary complex functions or explicit complex denominators should not silently enter this shortcut. At your scalar pre-integration boundary, a declared rational/algebraic expression language is sufficient. 
FeynCalc

Legacy FAD is not adequate storage for an uncertified prescription. It does not distinguish the two eta signs. Preserve or convert the side-specific information while that information is still available—not after combining the sides. 
FeynCalc

The remaining scheduling details are sound, subject to two counting rules:

Because both ordered pair artifacts are materialized, the downstream full-grid sum must not apply another off-diagonal factor of two.

A diagonal virtual/virtual integrand need not be pointwise real with its two loop arguments held fixed. Its Hermitian relation includes their exchange. Do not project such a diagonal numerator onto its real part prematurely.

Equal diagram sets must also refer to the same external-state labeling, model parameters, and Hermitian density operator—not merely matching diagram counts. Your simultaneous loop-list exchange should be a bijection between disjoint lists, leaving cuts and external momenta untouched. Rebuilding the normalization instead of conjugating an already-normalized master expression is the correct choice.

2. The Gram implication is valid on the genuinely generic domain

Let d
ext
	​

 be the dimension of the external span. After choosing the L independent oriented physical cut momenta as integration coordinates, write their transverse parts as v
1
	​

,…,v
L
	​

. Their transverse Gram matrix differs from the native-loop T by an invertible congruence, so positivity and rank agree. Conservation gives

v
L+1
	​

=−
i=1
∑
L
	​

v
i
	​

.

If G=detT>0, positive semidefiniteness makes T positive definite, and v
1
	​

,…,v
L
	​

 are linearly independent. Consequently:

A soft cut momentum, or one collinear with a beam or fixed external momentum, would give a zero transverse vector or a nontrivial relation.

Collinearity between two cut momenta would give a nontrivial relation.

The same conclusion applies when one of them is the eliminated recoil, using the displayed sum.

Therefore, provided the fixed final momenta are themselves nonsoft, non-beam-collinear, and mutually noncollinear, G>0 places the complete configuration in the strict interior of your sign theorem. Every accepted nonzero one-sign denominator is then nonzero. Thus

Z(Q
j
	​

)∩K⊆Z(G)∩K.

There is no counterexample within those assumptions.

Nondegenerate external Gram is not a substitute for “generic”

This must be an actual domain condition. For example, take a fixed observed momentum

p
c
	​

=ξk
a
	​

,0<ξ<1.

The external span of the beams remains Lorentzian and nondegenerate, and

Q
rec
	​

=(1−ξ)k
a
	​

+k
b
	​

,Q
rec
2
	​

=(1−ξ)s>0.

The residual cuts can have G>0, but

(k
a
	​

−p
c
	​

)
2
=0.

That denominator passes the global nonpositive sign classification, yet vanishes identically on this nongeneric fixed slice.

Your stated generic scope excludes this example. The implementation must not infer that exclusion solely from external-Gram nondegeneracy and timelike recoil. For multiple fixed final momenta, fixed-fixed collinearity needs the same explicit exclusion.

Also verify

oriented cuts
∑
	​

q
i
	​

=k
a
	​

+k
b
	​

−
fixed finals
∑
	​

p
c
	​

,

not merely that the cut sum is some loop-independent timelike vector.

What makes the convergence certificate sufficient

Use the closed physical domain K, with nonnegative cut energies, for compactness and Łojasiewicz. Strictly positive energy inequalities describe the integration interior but not a compact set.

In the actual scalar-product representation, the Gram exponent is

α(D)=
2
D−d
ext
	​

−L−1
	​

.

The remaining cut-coordinate Jacobian must be included. With independent cuts used as loop coordinates, the mass-shell constraints are linear in scalar products, so a constant, nonsingular elimination Jacobian can be checked directly. The standard Baikov representation supplies the stated dimension-dependent Gram power. 
arXiv

Set

f=
j
∏
	​

Q
j
ν
j
	​

	​

.

The established zero-set inclusion gives, on compact K,

G
N
≤C∣f∣

for some finite N. This is the applicable semialgebraic Łojasiewicz inequality; no numerical estimate of N is required for an existential certificate. 
Cambridge University Press

A polynomial numerator is bounded on K. Hence, relative to the finite residual coordinate measure,

	​

f
N
num
	​

G
α(D)
	​

	​

≤C
′
G
Reα(D)−N
.

Choosing Reα(D)>N provides absolute convergence and locally uniform domination in an open half-plane. The usual bound

∣Q
j
	​

+iσ
j
	​

η∣
−ν
j
	​

≤∣Q
j
	​

∣
−ν
j
	​


then proves prescription independence there, followed by the common meromorphic continuation.

This is enough for a theorem-backed certificate. It does not require a separate numerical convergence-strip estimate for each family.

For dimensional continuation, construct the full-rank Gram domain using a realization in an integer dimension D≥d
ext
	​

+L, and use the explicit Gram-power measure to define complex D. The condition D>d
ext
	​

+L−1 is not itself the denominator-dependent convergence threshold D
∗
	​

. Four-dimensional rank identities must not be imposed on this high-D domain.

3. Keep the authorization at whole-integral and fixed-kinematic scope

The sign witnesses are denominator-local; the convergence certificate is whole-integral. Every active ordinary denominator and every nonpolynomial measure factor must satisfy the admitted conditions. Certifying one slot does not independently authorize removing its prescription in a term containing an uncertified threshold or virtual factor.

Your exclusion of dotted cuts, virtual loops, and noninteger denominator powers is appropriate. Require unit powers on every cut, not just the absence of an explicit delta-derivative head.

The separation from Stage 4 must be enforced, not merely stated:

Generic fixed-kinematic equality cannot determine endpoint contact terms. Preserve the original prescriptions even when a bulk representation omits them, and require a stronger certificate before using that representation to identify the complete endpoint distribution or merge prescription-distinct definitions at that level.

Similarly, polynomial extraction must remain separate from the prescribed integration representation. At the pinned commit, topologyPropagatorCore obtains its polynomial through FeynAmpDenominatorExplicit; that is useful for constructing Q
j
	​

, but an uncertified integral must not be rebuilt solely from the resulting prescription-free polynomial.

Keeping unsupported prescriptions is therefore necessary, but not sufficient if a later parametrizer ignores them. Such a consumer must implement them or fail explicitly. Your proposed behavior is correct on this point.

4. The unit-cube certificate needs bounded reciprocal factors

The sector criterion is sufficient when the complete absolute integrand has the form

i
∏
	​

x
i
a
i
	​

+b
i
	​

D
	​

B(x,D),

with B bounded on the closed cube, locally uniformly in the proposed open D-strip.

If residual polynomials occur in denominators, “positive” must mean either a positive lower bound on the closed cube or another proved bound already absorbed into the monomial exponents.

For example,

∫
0
1
	​

∫
0
1
	​

(x+y)
2
dxdy
	​


diverges, although x+y>0 throughout the open cube and the displayed standalone powers x
0
y
0
 satisfy the proposed inequalities. Resolving the corner exposes an x
−1
 factor, which correctly fails the strict integrability test.

The strip must also be the common intersection across all sectors, with every Jacobian and denominator power included. For the stronger distribution-smearing certificate, the exact parametrization must cover the smeared observed-variable domain, including its endpoint strata—not only generic fixed slices.

Minimal decisive tests

An exact reverse-pair fixture should contain a complex coupling, different forward/conjugate loop labels, and both SFAD signs. Check the known conjugate and the involution twice, then compare one directly generated reverse pair. An involution test alone is insufficient: an operation that never flips eta is also involutive.

For the geometric certificate, test rejection of the beam-collinear fixed-observed example, acceptance of a full-rank high-D configuration that has insufficient transverse rank in four dimensions, and rejection of a dotted cut. For the sector certificate, use the (x+y)
−2
 corner example.

Approve the mirrored-pair construction with explicit prescription conjugation, and approve the high-D certificate as a bulk undotted certificate with the stated domain checks. Neither requires relaxing causal treatment outside that scope.