# Endpoint epsilon demands and complete flavor sums

Verified outgoing model: gpt-6-pro. Retrieved 2026-09-09.

## Question

Please review the remaining general measured-NNLO workflow, still as GPT-6 Pro.

Updates: all 8 UU/LL q/qbar VV components independently match the all-D quark form factor (four masters) and one-loop square. Your conic pullback works: all required integrals of the current 55-master RR system now convert to explicit GPLs. There are 3 separate one-root ancestor components (2 linear roots, 1 quadratic), rather than just the 2 primitive failures I mistakenly stated in review24. No component mixes roots. Retained finite solution is2.2MB, GPL version3.3MB, with shared finite boundary coefficients.

Crucial source audit caught and fixed a general numerator-coordinate map-direction bug: the old coefficients still contained loop-coordinate symbols, rather than representing powers as GLI indices. Corrected UU gluon component has1152 transverse and568 longitudinal targets; old counts18/14 were therefore NOT valid physical target counts. Strong new invariant rejects any coefficient containing loop coordinates. Exact reconstruction plus this invariant passes. We are regenerating reductions; old55-master functions remain valid integrals but coverage must be proved for new targets. Direct affine monomial composition and a bounded parallel coefficient-factor step are being optimized.

Before we spend on excessive epsilon orders, please design the general RR ENDPOINT assembly/order demand interface for n measured variables. Here the full scalar solution through epsilon0 at interior points is available, but for distributions we must not expand rho^(a+b epsilon) prematurely. We have:
- original rational coefficient matrix C(x,z,epsilon), obtained from real generated amplitudes, all loop coordinates eliminated;
- exact DEs and integer-power Fuchsian boundary normalizations at rho=1-x and sigma=1-z;
- allowed physical normal exponents/slopes (phase-space and leading-region analysis);
- exact corner constants as Gamma functions and finite tangential DE solutions in z;
- ordered physical boundary maps, epsilon entry valuations, and a checked finite Laurent matrix-vector product API;
- output common tensor-product delta/plus/regular format. General Taylor-subtracted stronger-pole distributions exist internally, but the common exported hard format currently supports simple endpoint poles; full physical density should cancel stronger powers.

Question: Is the efficient correct strategy to contract C with exact boundary/Frobenius maps FIRST, determine the integer normal jets that survive in the complete density, then propagate separate epsilon demands to interior coefficients, edges, and corners? Interior throughepsilon0, simple edge delta may need smooth coefficients throughepsilon1, corner delta-delta throughepsilon2, but C/normalization valuations and boundary poles alter this. Give an exact demand-propagation formulation that avoids demanding every full two-variable master throughepsilon2. Explain how to show cancellation of rho^-2 or stronger terms BEFORE needing explicit GPL identities: can one use coefficient vectors in the physically allowed tangential solution space, or must physical Gamma constants also be inserted? Account for resonance/logarithmic Frobenius blocks and different slopes per term. Distinguish a genuinely uniform corner expansion from iterated edge limits. We need a reusable algorithm, not SIDIS coefficient formulas.

Also confirm the minimal flavor inventory of electromagnetic integratedSIDISNNLO at the individual-flavor level: qq(same),qbarqbar(same),q-qbar(same),qbar-q(same),q-qprime,q-qprimebar,qbar-qprime,qbar-qprimebar,qg,qbarg,gq,gqbar,gg. qq/qqbar tagged-quark variants have the appropriate unobserved quark species and no multiplicity on observed flavors; gg sums unobserved qf qbarf. We intend symbolic electric charges at model vertices, with reference incoming flavoru and a distinct down-type observed representative carrying a separate charge, then exact flavor relabeling for counterterm matrices. Please flag omitted channels or a charge structure that requires an additional representative. UV and full P0/P1, raw-Larin splitting and finite scheme kernels, and the tensor-product Mellin algebra are ready as universal building blocks; the full assembly remains to be wired.


## Pro response

Yes: contract the corrected coefficient matrix with the exact boundary maps first, determine the surviving normal jets, and then propagate separate epsilon demands for the bulk, faces, and their intersections. That is the right way to avoid computing every two-variable master through ϵ
2
.

Three qualifications are essential:

“Bulk through ϵ
0
” means the complete bulk coefficient, not necessarily every master through ϵ
0
.

A delta coefficient does not always cost exactly one extra epsilon order: logarithmic Frobenius terms, residue degeneracies, and explicit coefficient poles change that requirement.

Ordered boundary maps determine the physical solution, but do not alone certify a uniform expansion at a simultaneous corner.

Your 13 ordered flavor-channel types are complete. The main charge-bookkeeping addition is that same-flavor qq contains an independent ∑
f
	​

Q
f
2
	​

 contribution, not only Q
q
2
	​

.

1. Make target coverage a prerequisite to the new demand plan

The existing 55-master solutions can be reused as integral identities, but the new coefficient matrix must first have an exact coverage map

I
new
	​

=T(x,z,ϵ)I
stored
	​

.

If additional independent integrals are needed, extend the solution space before using its boundary maps.

After that,

H(x,z,ϵ)=C
new
	​

(x,z,ϵ)T(x,z,ϵ)I
stored
	​

(x,z,ϵ)

is the relevant density. Apply the declared color and charge algebra and collect this matrix product before assigning demands.

The loop-coordinate-free invariant is necessary and valuable. It does not replace coverage, and the former physical cancellations or order requirements inferred from the erroneous coefficient matrix must be recomputed. Integral-level boundary data remain reusable; coefficient-level conclusions do not automatically survive the source correction.

2. Contract boundary maps before expanding their scalar functions

Let r
i
	​

 be endpoint coordinates, such as

r
1
	​

=ρ=1−x,r
2
	​

=σ=1−z.

For a face F⊆{1,…,n}, let y denote the remaining tangential coordinates.

Represent the master germ in that face as

I(r
F
	​

,y,ϵ)=
γ,k,m
∑
	​

r
F
k+ω
γ
	​

(ϵ)
	​

(logr
F
	​

)
m
B
F,γ,k,m
	​

(y,ϵ)b
F
	​

(y,ϵ).
	​

(1)

Here:

k records integer normal powers;

ω
γ
	​

(0)=0 retains the exact regulator-dependent exponents;

m records logarithmic powers;

B is the exact boundary/Frobenius map;

b
F
	​

 is the lower-dimensional tangential solution vector.

Integer-power Fuchsian gauges and their inverse maps belong in B, not in an informal adjustment of the physical onset. Resonant Frobenius systems can require logarithms, so a power-only representation is insufficient in general. 
DLMF

Expand the rational coefficient matrix in the normal coordinates, at generic epsilon, and contract it with B:

H=
γ,k,m
∑
	​

r
F
k+ω
γ
	​

(ϵ)
	​

(logr
F
	​

)
m
Q
F,γ,k,m
	​

(y,ϵ)b
F
	​

(y,ϵ).
	​

(2)

Compute and simplify the rows Q before evaluating tangential GPLs or expanding Gamma constants.

How many integer normal jets are needed?

For one normal variable, suppose a coefficient entry begins at r
p
 and a master mode begins at r
a+ω
. A Frobenius Taylor term of degree j can contribute to a nonintegrable normal power only when

p+a+j≤−1.

Thus the provisional upper bound is

j
max
	​

=−1−p−a.
	​

(3)

Use entrywise onsets and exact collection to reduce this bound.

This calculation is independent of the epsilon-depth calculation. The interface should have distinct fields for NormalJetOrder and EpsilonOrder; neither operation should be implemented by renaming the other’s regulator.

At multiple endpoints, use a sparse set of faces and multi-indices. A finite corner Taylor polynomial cannot replace a complete edge function: the coefficient of δ(ρ) must retain its full dependence on z, subject to its own endpoint analysis.

3. Stronger-pole cancellation can usually be proved without GPL identities

Consider a candidate forbidden term

ρ
−p+ω(ϵ)
(logρ)
m
q(z,ϵ)b(z,ϵ),p≥2.
First test: vanishing on the allowed solution space

If the physically allowed tangential modes are parametrized by

b=B
allowed
	​

c,

and

qB
allowed
	​

=0
	​

(4)

as an exact map, the term vanishes for every allowed boundary vector. No Gamma values or explicit GPL representation are needed.

Apply all exact differential relations and declared color identities before this test. Do not treat a redundant tangential vector as independent.

Second test: vanishing only for the actual physical constants

If (4) is nonzero, the term can still vanish because

qB
allowed
	​

c
phys
	​

(ϵ)=0.

Then the physical Gamma-valued constants matter. Their known relations must be applied exactly, or through a rigorously sufficient Laurent window.

Failure of the “all allowed modes” test is therefore not a physical failure. It means the cancellation is specific to the selected physical solution.

A DE-based zero test avoids explicit special-function simplification

Suppose

∂
z
	​

b=A
z
	​

b.

Starting with the rational row q, close its row space under

∇
z
	​

q=∂
z
	​

q+qA
z
	​

.
	​

(5)

For several tangential variables, close under every corresponding ∇
i
	​

.

Once the row space is stable, collect a basis into R. Then

g=Rb

satisfies a closed homogeneous system. If its complete initial data vanish, g, and hence qb, vanish throughout the connected branch.

At an ordinary basepoint, test R(z
0
	​

)b(z
0
	​

)=0. At a singular basepoint, use the normalized Frobenius amplitudes or enough jets to determine those amplitudes. A vanishing endpoint value alone is not enough: a nonzero homogeneous solution can vanish at that endpoint.

This uses rational DE algebra and physical boundary data, not GPL identities. The closure has rank at most the dimension of the tangential system.

Do not identify different regulator slopes at ϵ=0

Collect exact exponent classes, allowing integer shifts to be reconciled with Taylor indices. But

ρ
−2−ϵ
andρ
−2−2ϵ

are different normal modes at generic epsilon. Their common ϵ
0
 interior power does not authorize canceling them before distributional continuation.

A decisive regression is

ϵρ
+
−2−2ϵ
	​

=
2
1
	​

δ
′
(ρ)+O(ϵ).
	​

(6)

It vanishes at ϵ
0
 at every ordinary ρ>0, yet produces a finite delta derivative.

Accordingly, there are two acceptable ways to eliminate unsupported stronger poles:

prove that their regulated coefficients vanish exactly;

retain them internally and prove that their complete generalized-distribution contribution vanishes through the requested epsilon order.

Do not drop them because the final exported hard coefficient is expected to contain only simple plus distributions. The endpoint/epsilon order of operations is physically consequential, as the regulated box examples explicitly demonstrate. 
arXiv

4. Derive order demands from exact endpoint moment maps

Define endpoint deltas by unit mass on [0,1], and

D
j
	​

(r)=[
r
log
j
r
	​

]
+
	​

.

For an exact small exponent ω(ϵ),

r
+
−1+ω
	​

log
m
r=
ω
m+1
(−1)
m
m!
	​

δ(r)+
k=0
∑
∞
	​

k!
ω
k
	​

D
m+k
	​

(r).
	​

(7)

This follows by differentiating the analytically continued power distribution with respect to ω. 
DLMF

The formula gives the order costs directly.

For ω=βϵ, β

=0:

the delta moment has valuation −(m+1);

the k-th plus term has valuation k;

explicit factors multiplying the Frobenius logarithm retain their own valuations.

Thus a logarithmic mode can increase the apparent delta demand, but an accompanying ϵ
m
 can compensate it. Count the actual product.

Stronger-pole moment maps

For p≥1,

⟨r
−p+ω
log
m
r,ϕ⟩=
	​

j=0
∑
p−1
	​

j!
ϕ
(j)
(0)
	​

(ω+j−p+1)
m+1
(−1)
m
m!
	​

+∫
0
1
	​

drr
−p+ω
log
m
r[ϕ(r)−
j=0
∑
p−1
	​

j!
r
j
	​

ϕ
(j)
(0)].
	​

(8)

The resonant moment is j=p−1. Its epsilon pole has the same order m+1, regardless of p; its support is a higher delta derivative. The other Taylor moments also remain part of the exact prescription.

If ω≡0 for a surviving nonintegrable term, epsilon does not regulate that term. Require cancellation in the complete expression or an explicitly defined additional regulator. Do not manufacture a plus prescription as an implicit finite renormalization.

Matrix moments can be cheaper than diagonalizing resonant blocks

Where a normalized block contains r
Λ
,

∫
0
1
	​

drr
Λ−I
=Λ
−1
	​

(9)

in its convergence domain and by continuation.

For

Λ=βϵI+N,N
s
=0,
Λ
−1
=
j=0
∑
s−1
	​

(βϵ)
j+1
(−1)
j
N
j
	​

.

This retains the Jordan structure without singular eigenvector normalizations. If N=O(ϵ), its valuation is automatically included.

Use the actual compatible normal-form matrices. Do not assume separately constructed normal residues commute merely because both individual edges are Fuchsian.

The exact demand-propagation rule

After a canonical face subtraction, write an output coefficient as

A
τ
	​

(ϵ)=
j
∑
	​

K
τj
	​

(ϵ)B
j
	​

(ϵ),

where τ identifies the distribution support and plus-log indices. The matrix K includes:

the contracted amplitude/Frobenius map;

endpoint moments such as (7)–(9);

all normalization factors;

any exact basis or physical-boundary substitutions.

For output through ϵ
N
, require

d
j
	​

=
τ:K
τj
	​


=0
max
	​

[N−val
ϵ
	​

K
τj
	​

].
	​

(10)

The B
j
	​

 may be lower-dimensional functions, corner Gamma constants, or finite-solution graph nodes.

The proof is immediate: an omitted term O(ϵ
d
j
	​

+1
), multiplied by a factor of valuation v
τj
	​

, becomes

O(ϵ
d
j
	​

+1+v
τj
	​

)=O(ϵ
N+1
)

or smaller.

For a general product node, use

d(child j)=d(parent)−
k

=j
∑
	​

val
ϵ
	​

(child k).
	​

(11)

Combine identical dependencies and exact cancellations before taking these valuations.

A finite-data implementation must distinguish an exact zero from an unknown tail. A coefficient absent from the saved epsilon window is not necessarily zero.

The familiar 0,1,2 rule is a special case

For simple normal poles without extra logarithms or prefactor poles:

Contribution being produced	Needed smooth coefficient
Bulk regular remainder / plus coefficients	Through ϵ
0

One endpoint delta moment	Through ϵ
1

Two endpoint delta moments	Through ϵ
2

k endpoint delta moments	Through ϵ
k

But if the corner coefficient is

A(ϵ)=ϵ
−1
B(ϵ),

then its double-delta finite term needs B through ϵ
3
.

A delta already present in the source—such as a Born-supported contribution—does not itself incur an extra epsilon demand. The demand arises from the moment operator that produces it, not merely from its support label.

5. Implement the subtraction on the face lattice

For a normal-crossing branch

H(r,ϵ)=A(r,ϵ)
i
∏
	​

r
i
−1+ω
i
	​

(ϵ)
	​

log
m
i
	​

r
i
	​

,

let

E
i
	​

Ψ=Ψ∣
r
i
	​

=0
	​

.

The exact identity

1=
i
∏
	​

[E
i
	​

+(1−E
i
	​

)]
	​

(12)

applied to Ψ=Aϕ organizes the integral into faces and fully subtracted remainders.

For two variables,

(1−E
ρ
	​

)(1−E
σ
	​

)Ψ=Ψ(ρ,σ)−Ψ(0,σ)−Ψ(ρ,0)+Ψ(0,0).

The corner is counted once. Endpoint restrictions act on the full multiplier–test-function product, not only on the test function.

This suggests a sparse recursive implementation:

The bulk node is requested through ϵ
N
.

Applying a delta moment raises the demand on its boundary node according to (10).

That boundary node is itself a distribution in its tangential variables.

Its endpoint moments generate demands on the next intersection.

Memoize by the geometric face, not by the order in which its coordinates were restricted.

For SIDIS this normally means:

	​

two-variable bulk coefficient through 0,
one-variable edge combinations through their derived demands,
corner constants through their derived demands.
	​

	​


It does not require the entire two-variable master vector through ϵ
2
.

Higher-epsilon edge information should be obtained directly from the tangential DEs and boundary maps. Higher-epsilon corner data should come directly from the Gamma expressions and finite matching matrices.

The bulk remainder still requires sufficient interior master depth:

d(I
j
	​

)≥N−val
ϵ
	​

C
j
	​


after exact coefficient collection. If C
j
	​

 has a pole, a saved master through ϵ
0
 may be insufficient even for the bulk. Boundary-demand separation removes unnecessary global depth; it does not eliminate genuine coefficient-driven depth.

6. Ordered edge data are not a uniform corner certificate

Your ordered maps are valid tools for fixing integration constants. For distribution assembly, additionally require that the chosen corner representation covers all simultaneous approaches and has a uniformly integrable remainder after the required Taylor subtractions.

A counterexample is

H
ϵ
	​

(ρ,σ)=(ρ+σ)
−2−ϵ
.

It is regular in ρ at ρ=0 for every fixed σ>0, and conversely. Yet near the corner, setting

h=ρ+σ,v=
ρ+σ
ρ
	​


gives

dρdσ=hdhdv,

and hence

H
ϵ
	​

=−
ϵ
1
	​

δ(ρ)δ(σ)+finite distribution+O(ϵ).
	​

(13)

There is a corner pole that cannot be inferred from ordinary one-edge singularities alone.

For the native tensor-product endpoint engine, a sufficient contract is:

After removing explicit regulator powers and Frobenius logarithms, the retained coefficients have the required compatible normal jets, and the fully subtracted remainder is locally integrable uniformly in epsilon near zero after explicit meromorphic factors are separated.

A verified logarithmic connection with only the coordinate-boundary divisors, together with its convergent compatible normal form, can establish this. Two independently Fuchsified edges and flatness alone do not.

If residual divisors such as ρ+σ, or regulator-dependent divisors such as ρ+ϵa, obstruct that contract, first prove their cancellation in the complete density. Otherwise use sector charts and transform the distributions through their action on test functions, including the Jacobians. Sector decomposition provides a constructive treatment of such overlapping singularities. 
arXiv

Do not rename a sector radial delta as an original-coordinate delta without the pushforward. Nor should an artificial sector seam become a physical singular distribution.

Thus the interface should separately record:

the domain of each ordered expansion;

joint corner coverage;

remainder order and uniformity;

transformed support when nontrivial charts are used.

An interior O(ϵ
N+1
) estimate is not automatically a distributional O(ϵ
N+1
) estimate.

7. A concrete common interface

A proposed entry point could be organized as

Wolfram Language
PlanMeasuredDistribution[
  <|
    "CoefficientMatrix" -> C,
    "ExactTargetCoverage" -> targetMap,
    "BoundaryAtlas" -> boundaryMaps,
    "PhysicalBoundaryData" -> gammaData,
    "RequestedEpsilonOrder" -> 0,
    "ExportClass" -> {"Delta", "Plus", "Regular"}
  |>
]

Its output should contain separate results:

Output	Meaning
InteriorDemands	Master/function depths required for the complete bulk coefficient
FaceJetDemands	Integer normal jets and epsilon depths for each active face
CornerDemands	Required boundary-constant and matching-matrix depths
StrongPoleChecks	Exact or finite-order cancellation statements
UniformityChecks	Which charts justify distributional expansion and remainders
UnresolvedDependencies	Missing coverage, missing orders, or unsupported distributions

The execution order should be:

new target coverage
→contracted regulated boundary germs
→strong-pole cancellation and corner coverage
→exact endpoint moment maps
→backward epsilon demands
→minimal evaluations and final Laurent assembly.
	​

	​


Do not convert new high-order expressions to GPLs until the demand graph shows they are needed. Much of the extra work should remain in one-variable tangential functions and Gamma constants.

The final exporter should reject any surviving delta derivative, stronger generalized plus distribution, or genuinely joint distribution outside its declared class. It must not discard those terms because the physical answer is expected to be simpler.

Three inexpensive regressions directly exercise this architecture:

Support-sensitive epsilon order: equation (6), and its tensor product with a simple regulated pole.

Jordan demand: a block Λ=βϵI+N, tested against both the matrix inverse in (9) and the explicit logarithmic expansion.

Corner completeness: equation (13) must be rejected by a “separate edges only” certificate and accepted only after the joint chart or an equivalent exact analysis.

For an n-variable normal-crossing test, products of

r
i
−1+ω
i
	​

	​

log
m
i
	​

r
i
	​


against polynomial test functions provide exact separable moments and test every face and intersection.

8. The individual-flavor inventory is complete

Using incoming → observed notation and i

=j, your 13 ordered types are

q
i
	​

→q
i
	​

,
q
ˉ
	​

i
	​

→
q
ˉ
	​

i
	​

,q
i
	​

→
q
ˉ
	​

i
	​

,
q
ˉ
	​

i
	​

→q
i
	​

,
q
i
	​

→q
j
	​

,q
i
	​

→
q
ˉ
	​

j
	​

,
q
ˉ
	​

i
	​

→q
j
	​

,
q
ˉ
	​

i
	​

→
q
ˉ
	​

j
	​

,
q
i
	​

→g,
q
ˉ
	​

i
	​

→g,g→q
i
	​

,g→
q
ˉ
	​

i
	​

,g→g.
	​


There are seven representative channel types up to full charge conjugation, not thirteen independent coefficient functions. The electromagnetic UU and g
1
	​

 decompositions use this channel inventory. 
arXiv
+1

Required charge structures

With independent symbolic charges Q
i
	​

,Q
j
	​

, retain the following structures:

Channel	Charge dependence through NNLO
q
i
	​

→q
i
	​

	Q
i
2
	​

A+(∑
f
	​

Q
f
2
	​

)B
q
i
	​

→
q
ˉ
	​

i
	​

	Q
i
2
	​

C
q
i
	​

→q
j
	​

	Q
i
2
	​

A
ij
	​

+Q
j
2
	​

B
ij
	​

+Q
i
	​

Q
j
	​

D
ij
	​


q
i
	​

→
q
ˉ
	​

j
	​

	Q
i
2
	​

A
ij
	​

+Q
j
2
	​

B
ij
	​

−Q
i
	​

Q
j
	​

D
ij
	​


q
i
	​

→g, g→q
i
	​

	Q
i
2
	​

 times the corresponding coefficient
g→g	∑
f
	​

Q
f
2
	​

 times the corresponding coefficient

The displayed functions can themselves contain ordinary n
f
	​

 dependence from QCD. Do not identify n
f
	​

Q
i
2
	​

 with ∑
f
	​

Q
f
2
	​

. These charge structures are explicit in the independently calculated unpolarized/polarized flavor decomposition. 
arXiv
+1

The quark-initiated RR state inventory is

q
i
	​

gg,q
i
	​

q
i
	​

q
ˉ
	​

i
	​

,q
i
	​

q
j
	​

q
ˉ
	​

j
	​

(j

=i).

The last state must be available with the tag on q
i
	​

, q
j
	​

, or 
q
ˉ
	​

j
	​

. The gluon-initiated RR state is

gq
f
	​

q
ˉ
	​

f
	​

,

with the corresponding physical tag choices. No multiplicity is attached to a fixed observed flavor. For g→g, sum the unobserved flavor f, without an extra factor two for the distinguishable q
f
	​

,
q
ˉ
	​

f
	​

 pair.

For q
i
	​

q
i
	​

q
ˉ
	​

i
	​

, retain the identical-quark interference and the inclusive sum over the two eligible q
i
	​

 tags with its symmetry factor. This cannot be reconstructed merely by setting j=i in a distinct-flavor result.

Is one up/down distinct-flavor representative enough?

Yes, provided the calculation is strictly massless QCD plus the electromagnetic vector current and the current-vertex charges remain independent symbols. Then a representative u→d with symbols Q
u
	​

,Q
d
	​

 supplies all three distinct-flavor charge coefficients, including the case of two distinct flavors whose eventual physical charges happen to be equal.

No additional charge representative is needed. What remains separately necessary is:

the actual same-flavor diagram class;

the different tag choices of the distinct-flavor state;

the gluon-initiated state and its unobserved flavor sum.

Apply flavor relabeling before inserting physical charge values. Keep the same flavor charge parameter in the quark and antiquark current vertex; fermion-flow and helicity-density conventions supply their signs. Full charge conjugation gives the same electromagnetic UU and g
1
	​

 coefficients after all external roles are conjugated. The partial secondary-line conjugation is what changes the Q
i
	​

Q
j
	​

 interference sign. 
arXiv

The finite polarized scheme matrix must continue to act in the full individual-flavor space. It can assign charge-square contributions through intermediate Born flavors; that is matrix multiplication, not an additional physical channel or a reason to change the generated charge polynomial.

Recommendation

Implement the endpoint planner as a support-aware demand graph built from contracted boundary maps. Use rational tangential relations first to eliminate forbidden normal powers, and use the physical Gamma data only where the cancellation depends on the selected solution. Keep regulator powers and Jordan structure exact until the moment maps have been formed.

That should restrict the extra computation to the boundary combinations that actually contribute: bulk information through the coefficient-driven finite order, edge functions at their derived depths, and corner constants at theirs. The principal correctness gate is not “all masters known through ϵ
2
,” but complete target coverage plus a distributionally valid remainder for every retained face and corner expansion.