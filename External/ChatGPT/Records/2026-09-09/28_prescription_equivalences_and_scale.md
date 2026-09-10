# Certified prescription equivalences and exact scale removal

Verified outgoing model gpt-6-pro; conversation 6aa0f5dd-de10-83e8-b032-74f47d77da2a; message 37906ca9-0cfa-4d9b-bded-af97213fb178.

## Question

Please review a concrete remaining reduction issue. Full corrected SIDIS UU/LL NNLO RR input is now 75 typed families and 6610 targets. Initial targeted6733 seeds plus498 inverse-incidence seeds, 78361 exact equations including110 old DE relations and powered-integral equivalences. Finite-field target remainder rank62 ->25 ->24 at two points. No unseeded direct predecessors remain. Of remaining24 integrals,23 are unit seven-denominator products (4 cuts +3 ordinary), one has a squared ordinary denominator and rank2 numerator. Many families differ in ordinary +i0 versus -i0 labels retained from conjugate amplitudes. We already prove ordinary-prescription removal for every original whole source product BEFORE rational partial fractions using our compact-cut convergence theorem, but typed family equivalence deliberately still preserves etas. So conservative metadata may be creating artificial duplicates.

Existing measured certificate: strip measurement cut delta(2p.k1 - z*2p.P), positive Jacobian2p.P, p future null, P future timelike; ordinary inverse propagators and measure/J independent of z. Parent compact massless3body integral certifies dominated prescription limit for finite positive powers, including cut derivatives from nonnegative mass deformations, in sufficiently large Re D; polynomial numerator/smooth measurement test insertions supported. Equality holds meromorphically at fixed x<1, as a distribution on entire z line. Explicitly ExternalEndpointUniformityEstablished=False: x->1 is not covered. Original prescribed product is always retained for external endpoint analysis.

Proposed remedy: for each actual finite requested typed integral, independently call that same existing certificate with its cut and ordinary powers (not only transfer the source certificate to a partial fraction term). Only if certified, replace ordinary eta with the common rational-algebra placeholder +1 while keeping cuts and all other typed definitions unchanged. Find exact affine powered-integral equivalences after this normalization, and add witnessed Source - factor*Representative equations to original unmodified IBP system. Each row retains both individual certificates; no global endpoint-distribution claim. Dotted cut candidates rechecked if used. This should identify prescription-only duplicates if present. Do you agree this is sound for generic meromorphic master reduction? What additional data or guard is needed before using this reduced basis for full joint x,z distributions? Particularly warn against inferring absence of delta(1-x) from a generic-x identity. We will still derive external endpoint distribution from original prescribed density and prove uniform convergence/analytic continuation or face data. Please also suggest whether any other cheap exact relation is missing for23 full-rank denominator products with no numerator slots. No coefficient importing/fitting, no claim24 extra masters.

Separate possible exact performance optimization: all seven inverse propagators, including unnormalized measurement cut, are homogeneous degree1 in mass-squared, and measure prefactor Q2*(2Pi)^(3-2D)/x. Thus I_nu scales as (Q2)^(D+1-sum nu). To reduce field Q(D,x,z,Q2) to Q(D,x,z), verify every exact equation has common Q2 degree after these weights, solve at Q2=1, then restore coefficients (Q2)^(degree(target)-degree(master)). Can this be implemented generally with explicit homogeneity checks and kept separate from numerical specialization? No final decision made yet.


## Pro response

Yes. Your proposed prescription-normalized equivalences are valid for generic meromorphic master reduction, provided the certificate applies to each actual powered integral being identified. The Q
2
=1 reduction is also exact after the homogeneity checks you describe. Neither operation establishes the missing joint x,z endpoint extension.

I would apply both optimizations before enlarging the seed set again. The present pattern—23 unresolved unit top-sector products, with many prescription variants—makes redundant physical definitions a plausible explanation, but the certificates and exact routing witnesses must decide it.

1. Prescription normalization: valid as a certified quotient of integral definitions

Write the original typed integral as

I
ν,σ
	​

(x,z,D),

where σ contains the ordinary i0 signs. The particle-cut orientations, measurement normal, powers, numerator, and normalization are separate data.

Under your stated certificate, for fixed generic 0<x<1 and every ϕ∈C
c
∞
	​

(R
z
	​

),

η→0
+
lim
	​

⟨I
ν,σ,η
	​

(x,⋅,D),ϕ⟩=⟨I
ν
alg
	​

(x,⋅,D),ϕ⟩

in a common convergence domain, independently of the allowed ordinary prescription choices. Continuing that identity gives

I
ν,σ
	​

=I
ν,τ
	​

as meromorphic families in D
′
(R
z
	​

).
	​

(1)

The relevant meaning of convergence here is precisely convergence after pairing with test functions, not pointwise convergence of regulated densities. 
DLMF

Now suppose the normalized integrals admit an exact allowed affine routing F, including their powers and normalization:

I
ν,A
alg
	​

=f(D,x,z,Q
2
)I
μ,B
alg
	​

.

Combining the two individual certificates with that routing proves

I
ν,A,σ
	​

−fI
μ,B,τ
	​

=0.
	​

(2)

This is exactly the kind of equation that can be appended to your original system. There is no need to regenerate the existing IBPs.

The proposed per-integral check is the essential improvement

Certification of an original whole source product does not automatically certify each partial-fraction term, an increased ordinary power, or a dotted-cut descendant. Rechecking the actual integral avoids that unsupported inference.

The certificate attached to (2) should cover:

every positive ordinary power actually present, and any increases needed by the specified cut-normal derivatives;

the actual polynomial numerator or the theorem’s established polynomial-numerator class;

the same forward-tip meromorphic convention and measurement normalization on both sides;

the precise allowed external domain;

a common nonempty convergence domain for the two sides.

For a finite collection of integrals, different sufficiently-large-ℜD thresholds are harmless: use a common domain contained in all the required convergence domains. A proof only at a few integer values of D would not suffice.

If domination is established using

∣(D
j
	​

+iσ
j
	​

η
j
	​

)
−ν
j
	​

∣≤∣D
j
	​

∣
−ν
j
	​

,

with the required derivative powers included, it also controls independently vanishing positive η
j
	​

. Otherwise retain the particular correlated regulator limit actually proved; do not silently broaden it.

Treat +1 as an equivalence marker, not a mutation of the original integral

Using +1 in a temporary canonical signature is acceptable. I would name its semantic status something like certified prescription-independent internally, even if its serialized value is +1.

Keep the solver unknown tied to an actual original typed representative. Then add (2) between original IDs. Do not overwrite all family prescriptions and later assume that every integral in the family—including untested dots—has been certified.

The existing affine validator must still check:

directed particle momenta and forward support,
exact measurement polynomial and derivative power,
ordinary polynomials and numerator transformation,
∣detA∣
D
,all explicit normalization factors.
	​


Ordinary prescription independence does not erase particle orientation or measurement-normal information.

If an ordinary polynomial is rescaled, its algebraic power factor remains. For example, D
′
∘F=−D produces (−1)
−ν
 for an integer ordinary power. Removing the ordinary prescription does not remove that factor.

Keep this inexpensive

Do not certify thousands of objects merely to discover that their prescription-free signatures never collide.

First form candidate signatures with ordinary signs ignored, but use them only for grouping—not for equality. Compare the live residual integrals, known preferred integrals, and their immediate relevant equivalence classes. Run the certificate only for candidate identifications that could reduce the target remainder space.

Cache proofs by the geometric denominator set and certified power/normal-derivative budget. A theorem proved for a finite power envelope can cover its members; this is different from transferring a certificate from an unrelated source product.

2. Preserve two distinct endpoint limitations
2.1 A generic-x identity does not exclude an x=1 contact term

Let ρ=1−x. Even if (2) holds for every 0<x<1, two extensions to the closed physical region can differ locally by

Δ(ρ,z,D)=
j=0
∑
J
∗
	​

	​

δ
(j)
(ρ)A
j
	​

(z,D),
	​

(3)

where the A
j
	​

 can themselves be distributions in z, including edge or corner deltas. Distributions supported on a submanifold are precisely the possible ambiguity when extending a distribution known only off that submanifold, subject to the applicable order/scaling restrictions. 
arXiv

Thus:

Meromorphic continuation in D of an identity established only on x<1 does not, by itself, determine its extension through x=1.

Neither zero interior residuals nor matching ordinary Frobenius functions exclude (3). A supported term has no ordinary interior germ to detect.

Your plan to derive external endpoint distributions from the original prescribed density is therefore necessary and consistent.

Two sufficient ways to complete the endpoint justification

Joint continuation from a convergence domain. Show equality after pairing the original and reduced expressions with arbitrary smooth test functions in both x,z, in a common open regulator domain. Then continue that distributional identity.

The required bound need not be a bounded supremum in x. An integrable x-dependent majorant controlling the relevant z-test-function seminorms is sufficient. What is missing from the current certificate is that control as x→1.

This can be proved for the complete physical combination rather than every partial-fraction term separately, if that is cheaper and the complete combination is better behaved.

Original-prescription face data. Establish an upper bound J
∗
	​

 on the possible normal contact order and determine the coefficients in (3) using the original definition. With χ(ρ)=1 near zero,

⟨Δ,χ(ρ)
j!
ρ
j
	​

ϕ(z)⟩=(−1)
j
⟨A
j
	​

,ϕ⟩.
(4)

Vanishing of these functionals for the required finite normal jet, and for the needed z-distribution data, excludes the contact terms.

The upper bound on J
∗
	​

 must come from the original distributional scaling/order analysis, not from the desired exported delta/plus format.

2.2 Rational reduction can also lose full-z information

Your individual certificate is stronger in z: it proves equality on the entire z-line. Preserve that strength where it genuinely survives.

But linear algebra over Q(D,x,z) permits division by polynomials that vanish on endpoint support. Such division is not an injective operation on distributions:

(1−z)δ(1−z)=0

⇒δ(1−z)=0.
	​

(5)

Multiplication of a distribution by a smooth function is defined; inversion of a function vanishing on its support is not automatic. 
DLMF

Consequently:

A factor-one prescription/routing identity retains its full-z distributional meaning.

Multiplying it by a coefficient smooth in z also does.

Solving a larger system by dividing by z, 1−z, or another vanishing polynomial generally yields a localized generic-kinematics reduction unless its distributional lift is separately established.

For a relation qI−pJ=0, preserve that polynomial equation even when the generic solver outputs I=(p/q)J. The former may have a global distributional meaning that the latter does not possess without an extension rule.

This is not a reason to avoid rational IBP reduction. It is a reason to attach the right scope to its output and perform endpoint assembly from a consistently continued regulated representation.

A compact relation record should retain the original typed IDs, routing and factor, certificate references, ordinary-domain restrictions, any denominators inverted during localization, and

ExternalEndpointUniformityEstablished=False.
3. The best cheap additions for the 23 unit corner integrals

There is no theorem that a seven-denominator unit product must reduce to your preferred span. Seven independent inverse-propagator coordinates mean there is no irreducible numerator coordinate in that sector. They do not mean that the integral is fully localized: only four of those denominators are mandatory cuts, leaving three integration variables.

I would try the following operations in order.

3.1 Add the certified prescription identifications first

This directly addresses the observed duplication pattern and costs no new IBPs. Recompute the target remainder rank, not merely the number of listed free integrals.

Then close the new exact relations under your existing derivatives. If

RI=0,∂
t
	​

I=A
t
	​

I,

then

(∂
t
	​

R+RA
t
	​

)I=0.
	​

(6)

Use the actual derivative generator where the current vector is not yet DE-closed.

A derivative of a certified relation is a valid relation within its differentiability domain. It does not certify each dotted descendant separately as prescription-independent. Those two operations must remain distinct.

3.2 Test small groups for unit-cut rational integrand identities

After permitted routing to a common cut definition, the 23 objects have unit particle and measurement cuts. Their scalar rational densities can therefore be compared on the common affine cut slice.

For a small group, place their densities over a common denominator and check whether a linear combination’s numerator vanishes modulo the four independent cut polynomials. Where the ordinary denominators are nonzero, that is a pointwise equality on the unit-cut support. The individual high-D convergence certificates then justify integrating the equality and continuing it.

This can detect relations missed by a signature that insists on exact off-shell equality of every ordinary factor.

The scope is narrow:

it proves an identity of the specified unit-cut integrals;

it does not redefine their off-shell families or dotted descendants;

it must preserve the common physical cut component and normalization;

it should be attempted on small groups with overlapping denominator factors, not with one enormous common denominator for every family.

With a genuinely invertible seven-coordinate basis there is no nontrivial affine relation among its own seven coordinates. Thus ordinary partial fractions within a single such basis will not supply a missing identity by themselves. Cross-family combinations can still do so.

3.3 Add the one LI equation per residual seed, if absent

For E=2, there is one independent external Lorentz-invariance contraction:

(p
μ
	​

q
ν
	​

−p
ν
	​

q
μ
	​

)
a
∑
	​

(p
a
μ
	​

∂p
aν
	​

∂
	​

−p
a
ν
	​

∂p
aμ
	​

∂
	​

)I=0.
(7)

Generate it using the same typed scalar definition and transform any reference direction consistently.

LI identities add no information to the complete IBP ideal, but can add useful equations to a finite seed system. This redundancy has been proved explicitly; it should not be interpreted as saying that LI can never help a truncated reduction. 
arXiv

3.4 Only then add a narrow harder-dot shell

“No unseeded direct predecessor remains” proves that a particular one-hop search is exhausted. It does not prove that harder auxiliary equations cannot eliminate those predecessors.

For a true seven-positive-index corner, increasing only the numerator bound does not create a new top-sector ISP. A small next bundle is the previously unseeded one-dot integrals

1+e
i
	​

,i=1,…,7,

in the affected representative sectors.

Before prescription merging, 23 such corners would give at most 161 new seeds and 1,288 momentum-IBP equations. Generate only missing seeds, and inspect the target-rank gain. If needed, a selected two-dot bundle remains small compared with the previous global rectangle.

Keep every resulting auxiliary integral column. Do not delete out-of-envelope terms. Kira’s efficient-seeding analysis likewise distinguishes dot limits from numerator limits and recommends sector-specific enlargement when extra unresolved directions remain. 
arXiv

Treat the squared-denominator/rank-two-numerator survivor separately in its actual sector.

None of these steps establishes minimality. In related measured SIDIS reductions, additional relations have been established only after combining DE information with exact physical boundary data; that is evidence against interpreting a finite-seed remainder count as an irreducible-master count. 
arXiv

4. The scale-removal proposal is exact

Let q
0
	​

≡Q
2
>0, and define the scale transformation

q
0
	​

↦λq
0
	​

,p,q,k
1
	​

,k
2
	​

↦
λ
	​

(p,q,k
1
	​

,k
2
	​

),λ>0,

with x,z,D fixed.

For two integrations,

d
D
k
1
	​

d
D
k
2
	​

↦λ
D
d
D
k
1
	​

d
D
k
2
	​

.

Each inverse propagator, including the unnormalized measurement polynomial, scales as

D
i
	​

↦λD
i
	​

.

For positive λ,

C
ν
i
	​

	​

(λD
i
	​

)=λ
−ν
i
	​

C
ν
i
	​

	​

(D
i
	​

).

The forward-energy conditions are unchanged. Negative ordinary indices contribute the corresponding positive numerator powers automatically.

Finally, your prefactor

x
Q
2
	​

(2π)
3−2D

has degree one in Q
2
. Hence

I
ν
	​

(λQ
2
)=λ
ω
ν
	​

(D)
I
ν
	​

(Q
2
),ω
ν
	​

(D)=D+1−
i
∑
	​

ν
i
	​

.
	​

(8)

Two useful checks are

four unit cuts, no ordinary factors:
seven unit factors:
	​

ω=D−3=1−2ϵ,
ω=D−6=−2−2ϵ.
	​


The first agrees with the measured three-body volume’s scale power.

This scaling is valid with the original prescriptions retained. At finite ordinary regulator,

I(λQ
2
,η)=λ
ω
I(Q
2
,η/λ);

taking the prescribed boundary value preserves its sign. Scale removal does not depend on prescription removal.

Row normalization and restoration

For an exact row

j
∑
	​

c
j
	​

(D,x,z,Q
2
)I
ν
j
	​

	​

(Q
2
)=0,

verify that every nonzero summand has one common degree:

deg
Q
2
	​

c
j
	​

+ω
ν
j
	​

	​

=Ω
row
	​

.
	​

(9)

Equivalently, after defining

I
ν
	​

=(Q
2
)
−ω
ν
	​

I
ν
	​

,

the coefficients

(Q
2
)
ω
ν
j
	​

	​

−Ω
row
	​

c
j
	​


must be exactly independent of Q
2
.

Then solve over Q(D,x,z). If the result at unit scale is

I
T
	​

=
j
∑
	​

r
j
	​

(D,x,z)
I
M
j
	​

	​

,

restore

I
T
	​

(Q
2
)=
j
∑
	​

r
j
	​

(D,x,z)(Q
2
)
ω
T
	​

−ω
M
j
	​

	​

I
M
j
	​

	​

(Q
2
).
	​

(10)

With your common measure,

ω
T
	​

−ω
M
j
	​

	​

=
i
∑
	​

ν
M
j
	​

,i
	​

−
i
∑
	​

ν
T,i
	​

,

so the restored reduction coefficients contain integer powers of Q
2
, even though the integrals themselves have D-dependent scale powers.

This is an analytic quotient by positive dilation, not numerical specialization of a physical degree of freedom. It is safe because the eliminated scale dependence has first been proved exactly.

Generalize by declared weights, not a hardcoded exponent

For a more general definition,

ω
ν
	​

=
2
LD
	​

+ω
pref
	​

+ω
explicit numerator
	​

−
i
∑
	​

w
i
	​

ν
i
	​

,
	​

(11)

where D
i
	​

 has degree w
i
	​

 in the chosen mass-squared scale.

This handles normalized dimensionless measurement cuts, explicit mass powers, and alternative prefactors. Multiple physical scales require retaining their ratios; they cannot all be removed.

Three guards are particularly important:

Keep independent mass increments as μ
i
	​

/Q
2
 when checking mass-deformed definitions. Each mass-squared derivative lowers the homogeneity degree by one.

Keep μ
R
	​

-dependent factors outside this bare master normalization, or retain their ratios explicitly.

Restore exact powers before Laurent expansion. The factor (Q
2
)
cϵ
 generates scale logarithms when multiplied by poles.

A good derivative regression is

∂
z
	​

I
ν
	​

=ν
m
	​

JI
ν+e
m
	​

	​

+⋯.

Raising the measurement cut lowers ω by one; J raises it by one. The row must therefore be homogeneous. This catches a lost measurement Jacobian immediately.

Homogeneity is not an additional relation eliminating a master and does not imply scalelessness. It removes a redundant scale variable from the algebra.

5. Recommended next pass

I would perform the following bounded sequence:

Normalize the overall scale exactly, with row-by-row checks and a reversible restoration map.

Group live residuals and preferred masters by candidate prescription-free signatures.

Certify only useful candidate identifications, add their exact witnessed equations to the original signed system, and recompute target remainder rank.

Close the new relations under available derivatives, then test small unit-cut rational identities and the missing LI rows.

Add a narrow harder-dot bundle only if needed.

For final acceptance, require exact target-to-span relations, with their endpoint scope retained. Fresh finite-field points are useful for selection and detecting exceptional pivots; they do not replace the individual convergence certificates or the exact affine/algebraic witnesses.

The prescription quotient should reduce artificial duplication without weakening the physical definitions. The scale quotient should reduce the rational-function field without specializing D,x,z. The original prescribed density remains the authority for joint endpoint distributions until an additional joint continuation or complete face-data argument excludes terms supported at x=1.