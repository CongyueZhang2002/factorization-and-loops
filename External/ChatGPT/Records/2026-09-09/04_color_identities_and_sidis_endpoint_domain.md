# Color identities and SIDIS endpoint domain

Verified outgoing model gpt-6-pro; standard thinking effort; HTTP 200.
Request: 01958017-8a06-4091-b0a6-255b3992c600.
Conversation: 6aa0f5dd-de10-83e8-b032-74f47d77da2a.

## Question

Follow-up in the same FeynFacet benchmark campaign (repo github.com/CongyueZhang2002/factorization-and-loops; current local changes are not pushed). The unwanted fractions in qg -> observed g + X have now been diagnosed: all seven common reconstructed master coefficients retain xa/xb with CF and CA treated algebraically independent, but applying the root card's declared SU(N) identity CF=(CA^2-1)/(2 CA) and rational cancellation removes every fraction. Merely applying this identity to one unreduced target had not done so. We are propagating ColorRules as a late coefficient declaration, combining the complete rational coefficient before fraction checks, and normalizing -I, I, 3I analytic prefactors to the same I class before future finite-field traces. No production fraction is assigned a numerical value. We retain the original gauge calculation and will require full INCNLO checks.

The card-driven integrated SIDIS Born results now give e_q^2 * (C_T,C_L)=(e_q^2,0), DeltaC=e_q^2 for q and qbar, with exact epsilon^1,^2 coefficients explicitly zero. A generated q gamma* -> qg real tensor contracts in ~1 second and the exact two-body measure and evanescent averages pass tests. Next the general real-current producer will multiply 1/(4pi), the exact measured phase space, and g_s0^2=4pi alpha_s mu_R^(2eps) (4pi)^(-eps) exp(gamma_E eps), then expand the two endpoint factors (1-x)^(-1-eps)(1-z)^(-1-eps), keeping the resulting smooth numerator and any ordinary small-x/small-z poles. The common result is a recursive delta/plus/regular association over x and z.

Please review two nontrivial points only:
1. Does the observed SU(N) cancellation sufficiently resolve the earlier fraction diagnostic without requiring a separate ref-choice regeneration, subject to full independent hard-function comparison? Any caveat in collapsing imaginary rational constants into the rational coefficient (I remains the common analytic prefactor)?
2. For SIDIS coefficient distributions, the real numerator includes 1/z or x^eps; it is smooth near x=z=1 but not globally smooth on the entire closed rectangle. We intend to make the endpoint API's test-function domain explicit: support bounded away from x=0,z=0, as in physical PDF/FF convolutions with positive lower limits, with standard plus definitions at x,z=1. No invented plus or deltas at x,z=0. Is that a sound local endpoint subtraction formulation, including mixed edge terms and the energy-weighted inclusive DIS moment where the small-z cutoff is subsequently taken to zero only if that weighted integral converges? Please identify any missing Jacobian or MSbar normalization issue in the stated real producer. Do not provide a hard function to import; production must remain generated.


## Pro response

Yes. The exact SU(N) cancellation you report resolves the earlier fraction diagnostic for the complete reconstructed coefficients; a separate reference-choice regeneration is not required for that purpose. The proposed local endpoint formulation is also sound. Its main implementation caveat is to distinguish multiplication by a small-z-singular function from putting that function inside a globally defined plus prescription.

1. Color cancellation and imaginary-prefactor normalization
The fraction check must use the declared color algebra

For fundamental quarks in the stated SU(N) convention,

C
A
	​

=N,C
F
	​

=
2N
N
2
−1
	​

.

These are related parameters of the theory, not two algebraically independent variables. Imposing their relation is an exact color identity, not a physical normalization adjustment. 
FeynCalc

The appropriate object to validate is therefore

C
j
phys
	​

=Cancel[(
A
∑
	​

c
A
	​

R
Aj
	​

)
	​

C
F
	​

=(C
A
2
	​

−1)/(2C
A
	​

)
	​

].
	​


If all seven complete common-master coefficients satisfy

∂
x
a
	​

	​

C
j
phys
	​

=∂
x
b
	​

	​

C
j
phys
	​

=0

as exact rational identities at fixed partonic invariants and generic D, then the unwanted dependence has been removed mathematically—not merely hidden by a gauge choice or numerical specialization.

The earlier failure on one unreduced target is entirely consistent with this result: both integral relations and color relations were needed before the physical coefficient became manifest. Testing arbitrary independent C
F
	​

,C
A
	​

 demanded an identity outside the card’s declared theory.

Your revised ordering is appropriate:

common-master assembly⟶declared color specialization and rational cancellation⟶fraction check.

For rational functions, ensure the specialization is well defined: a separately specialized numerator and denominator giving 0/0 is not a cancellation certificate.

No reference regeneration is necessary to resolve this diagnostic. Retaining the original calculation and proceeding to the full independent INCNLO comparison is reasonable. The distinction remains that exact fraction independence certifies this property of the reconstructed result, not the completeness or correctness of every finite hard-function term.

In future finite-field evaluations, either reconstruct before imposing ColorRules and specialize exactly afterward, or evaluate on the declared color locus from the outset. Do not require physical cancellations to hold at independent random values of C
F
	​

,C
A
	​

.

Moving rational multiples of i into coefficients is safe

The proposed normalization is simply

(−i)R
1
	​

+iR
2
	​

+(3i)R
3
	​

=i(−R
1
	​

+R
2
	​

+3R
3
	​

),

with rational R
j
	​

. It is the correct way to prevent equivalent analytic-prefactor classes from obstructing cancellation.

Preserve the following distinctions:

Complex conjugation still sends i↦−i. Moving the sign into the rational coefficient must commute with the stored forward/conjugate convention.

Normalize only exact rational multiples. A branch-dependent factor such as (−s−i0)
−ϵ
, or a phase e
iπϵ
, is not interchangeable with a rational multiple of i.

A general Gaussian-rational coefficient a+ib is not a rational multiple of i unless a=0. Retain separate real/imaginary classes or an explicitly supported coefficient field.

In particular, this normalization must not change the loop/cut measure convention. FeynCalc distinguishes several integral normalizations, including conventions with additional e
γ
E
	​

ϵ
 and r
Γ
	​

 factors; those differences are substantive at the regulator orders you retain. 
FeynCalc

A common i in an intermediate integral representation is acceptable. It does not excuse an uncanceled imaginary part in the final physical coefficient.

2. Local endpoint distributions and the real-producer normalization
The proposed test-function domain is sufficient

A precise domain is

T={ϕ∈C
∞
((0,1]
2
):suppϕ⊂[η
x
	​

,1]×[η
z
	​

,1] for some η
x
	​

,η
z
	​

>0},

where smoothness includes smooth extension to the upper faces.

On this domain, 1/z, 1/x, x
ϵ
, z
−ϵ
, and their Laurent coefficients are legitimate smooth multipliers. They need not extend smoothly to the excluded lower faces. This matches the positive partonic lower limits in the standard SIDIS PDF/FF convolutions. 
arXiv

One qualification is important: smoothness only near the corner (1,1) is insufficient for the whole recursive API. Require the numerator to be smooth up to both upper faces on every rectangle bounded away from zero. Thus H(1,z) must exist for every z>0, and H(x,1) for every x>0. Your 1/z and x
ϵ
 examples satisfy this condition.

For such an H
ϵ
	​

, the distributional expansion

(1−x)
−1−ϵ
=−
ϵ
δ(1−x)
	​

+
m≥0
∑
	​

m!
(−ϵ)
m
	​

D
m
	​

(x),D
m
	​

(x)=[
1−x
ln
m
(1−x)
	​

]
+
	​

,

is valid locally, and similarly in z.

Apply endpoint restrictions to the multiplier–test-function product

For example, set

h
m
	​

(x)=
1−x
ln
m
(1−x)
	​

,Ψ(x,z)=H(x,z)ϕ(x,z).

Then

⟨HD
m
	​

(x)D
n
	​

(z),ϕ⟩=
	​

∫
0
1
	​

dx∫
0
1
	​

dzh
m
	​

(x)h
n
	​

(z)
×[Ψ(x,z)−Ψ(1,z)−Ψ(x,1)+Ψ(1,1)].
	​

	​


This defines the product even though H is singular at an excluded lower face. The two endpoint restrictions commute, and the corner is subtracted exactly once.

Mixed terms such as

δ(1−x)
z
1
	​

D
n
	​

(z)

are consequently legitimate. “Regular” in the recursive association must mean regular at the endpoint being resolved—not globally integrable on the closed rectangle.

Do not replace multiplication by a singular coefficient with a new whole-kernel plus prescription. On the stated domain,

z
1
	​

D
0
	​

(z)=D
0
	​

(z)+
z
1
	​

.
	​


This follows by applying D
0
	​

 to ϕ(z)/z.

By contrast, the naive notation

[
z(1−z)
1
	​

]
+
	​

defined through∫
0
1
	​

dz
z(1−z)
ϕ(z)−ϕ(1)
	​


is generally undefined: although ϕ vanishes near zero, the subtraction leaves −ϕ(1)/z there. Your API should retain the first, well-defined multiplication semantics.

Positive convolution limits do not redefine the plus prescription

Keep the standard plus distributions referenced to [0,1]. Their restriction to an integral starting at a>0 is

∫
a
1
	​

dzD
n
	​

(z)ϕ(z)=
	​

∫
a
1
	​

dz
1−z
ln
n
(1−z)
	​

[ϕ(z)−ϕ(1)]
+
n+1
ϕ(1)
	​

ln
n+1
(1−a).
	​

	​


For example,

∫
a
1
	​

dzD
0
	​

(z)=ln(1−a),

not zero.

Defining a new plus distribution normalized on [a,1] and omitting this boundary term would change the answer. In two variables, recursive use of this identity produces the necessary edge and corner boundary terms. They are consequences of restricting the existing distribution, not additional production delta coefficients.

The energy-weighted inclusive moment needs a controlled extension

Your proposed cutoff procedure is correct. With a smooth cutoff χ
η
	​

(z) vanishing near zero, define the moment by

η→0
+
lim
	​

b
∑
	​

⟨C
ba
	​

(x,z),ψ(x)zχ
η
	​

(z)⟩.
	​


The limit must exist as a distribution in x after assembling the relevant contributions and tag/flavor sums. Convergence at fixed ordinary x<1 alone does not establish convergence of terms supported at x=1.

For ordinary behavior

C(x,z)∼
z
ln
m
z
	​

,

the energy weight produces ln
m
z, which is integrable at zero. At finite regulator, weighted factors such as z
−ϵ
ln
m
z also admit an integrable bound in a sufficiently small strip around ϵ=0. Such bounds justify interchanging cutoff removal and the required Laurent expansion; do not assume that interchange for more singular terms.

The underlying bare phase-space identity is

t∈F
∑
	​

p⋅q
p⋅k
t
	​

	​

=1.

Thus the complete energy-weighted tag sum recovers the inclusive current tensor. Compare factorized coefficients in matching incoming schemes, with the final-state factorization treated consistently. No distribution at z=0 is needed to force this identity: a divergent weighted limit should be reported as such or resolved by the genuine contribution sum.

The stated real prefactors are consistent

Multiplying precisely the three factors you specify gives

N
R
	​

	​

=
4π
1
	​

8πΓ(1−ϵ)
(4π)
ϵ
	​

s
X
−ϵ
	​

[z(1−z)]
−ϵ
×4πα
s
	​

μ
R
2ϵ
	​

(4π)
−ϵ
e
γ
E
	​

ϵ
=
8π
α
s
	​

	​

Γ(1−ϵ)
e
γ
E
	​

ϵ
	​

(
Q
2
μ
R
2
	​

	​

)
ϵ
x
ϵ
(1−x)
−ϵ
z
−ϵ
(1−z)
−ϵ
.
	​

	​


This multiplies the g
s
2
	​

-stripped generated scalar, including its existing spin/color normalization. For your coefficient convention, that scalar must contain 2P
T
	​

, 2P
L
	​

, or 2P
A
	​

, rather than merely the tensor projection P
i
	​

.

If the exported perturbative series is

C=C
(0)
+
2π
α
s
	​

	​

C
(1)
+⋯,

strip α
s
	​

/(2π) exactly once: the displayed α
s
	​

/(8π) then leaves 1/4 multiplying the projected scalar and regulator factors. This is the conventional coupling expansion used in the SIDIS reference definitions. 
arXiv

There is no missing additional Jacobian in this product. The measured dΦ
2
	​

/dz already incorporates

δ(z−
p⋅q
p⋅k
	​

)=
x
Q
2
	​

δ(2p⋅k−
x
zQ
2
	​

).

Do not insert Q
2
/x again. Nor is there a ds
X
	​

/dx factor: x labels the fixed external invariant, rather than replacing an integration over s
X
	​

. There is no extra measurement 1/z or outgoing FF spin average.

Retain both x
ϵ
 and z
−ϵ
 in the smooth multiplier and expand them only to the depth required by the endpoint planner. Also retain

Γ(1−ϵ)
e
γ
E
	​

ϵ
	​

=1−
2
ζ
2
	​

	​

ϵ
2
−
3
ζ
3
	​

	​

ϵ
3
+O(ϵ
4
).

The absence of a linear term does not make this factor dispensable: its ϵ
2
 and ϵ
3
 terms contribute through a double-endpoint pole. For an NLO result through ϵ
1
, a smooth multiplier accompanying 1/ϵ
2
 is needed through ϵ
3
, absent further prefactor poles.

Finally, the full bare-coupling relation contains Z
α
s
	​

	​

. Setting it to one is correct for this O(α
s
	​

) real contribution; its correction first enters the present coefficient expansion at NNLO. Ordinary PDF/FF mass factorization and the universal incoming helicity-scheme transformation remain separate operations. Neither this local endpoint definition nor the D-dimensional unpolarized tagged sum requires an additional finite FF factor. 
arXiv
+1

The revised workflow is therefore consistent: impose the declared color algebra on complete coefficients, and treat the SIDIS result as a distribution on the upper-endpoint domain with ordinary small-x,z singular functions retained. The essential safeguards are correct multiplication of plus distributions, their lower-limit boundary terms, and controlled cutoff removal for inclusive moments.