# Existing cut-mass deformation proof audit

Verified outgoing gpt-6-pro, HTTP 200; uploaded CutIntegrals.wl.

## Question

Important new evidence while auditing old code: an OLDER general pole-bound method already establishes denominator-zero containment THROUGH independent nonnegative cut-mass deformations. I initially overlooked this because the new i0 certificate is narrower. User asks whether any unjustified removal occurred; must not call missing new metadata a proof gap if old method already supplies it.

I attach FeynFacet/Integrals/PoleBounds/CutIntegrals.wl for exact review. For each saved master, at the actual rational AMFlow comparison point, it:
1) Builds cone of future cut momenta (allowed future causal, not assumed null under deformation) and proved future external vectors, with only FIXED EXTERNAL null anchors.
2) For each active ordinary quadratic/massless core, gives either a future-causal sum proof or both-energy-sign null-decomposition proofs. Rank intersection proves any zero forces the actual INTEGRAL Gram boundary. Bilinear future-causal products similarly handled. Fallback quantifier elimination uses PSD domain, positive cut energies, G>0, independently nonnegative cut inverse polynomials, and ordinary core=0; only explicit False accepted.
3) Keeps all original off-shell inverse polynomials; reduces only unused external directions, recomputing actual Wishart prefactor/Gram exponent.
4) Differentiates full Gram density the required finite number of cut-normal times, then sets cuts on shell. Claim in code/docs: uniform semialgebraic domination at sufficiently large Re D makes full domain and its required mass derivatives integrable; moving Gram and energy boundaries vanish there. This was originally used to prove Laurent lower bounds, not named an i0 certificate.

My proposed inference (please critically verify): if the stronger zero containment really holds on a compact joint domain of small independent NONNEGATIVE cut masses, it also controls any finite derivatives of products (Q+i sigma eta)^-nu, since differentiating only raises integer powers and |Q+i sigma eta|^-p <= |Q|^-p. Cut constraints are affine in scalar products with constant Jacobian. Extend Gram^alpha times rational integrand by zero outside PSD/positive-energy domain. By selecting Re alpha sufficiently large after all finite derivatives, its derivatives vanish on all domain boundaries (using Lojasiewicz for raised ordinary powers). Thus the eta->0 limit commutes with the finite one-sided cut-mass derivatives; the dotted master in zero-prescription convention equals the physical chosen-prescription dotted distribution. Meromorphic continuation then identifies them. A proof about the massless surface alone would not suffice, but this older method explicitly checks the MASS-DEFORMED domain.

Actual master inventory now verified: NLO UU/LL real each6 masters all unit cuts (one volume+five angular); virtual5 each (3bubbles2boxes) +i0 retained; TTzero. NNLO final345=259unit+86single-doubled-cut. New undotted proof passes91templates covering259 in3.6s, over whole generic physical region v>0,w>0,v+w<1. I am testing the older mass-deformed pole-bound path on all86 with their saved exact off-shell polynomials at v=1/4,w=1/5. If they all pass AND you agree with the finite-eta derivative inference, the correct conclusion could be that none of these computed masters has an identified unjustified removal; the new i0 checker was simply overly narrow and not connected to the older stronger proof.

Please inspect code for any unsound causal-cone/Gram zero-containment guard, and distinguish actual missing mathematical ingredient from absence of a new API label. No need to discuss implementation naming.


## Pro response

Yes: the older mass-deformed method supplies the mathematical ingredient that was missing from the narrower argument. For the stated exact rational, massless master inputs, I find no false-acceptance in the attached causal-cone/Gram containment tests. The finite-η, finite-normal-derivative inference is valid once the boundary argument is stated precisely.

If the 86 saved dotted masters pass this method with their actual off-shell definitions, they should not remain classified as having an unproved causal identification at the comparison point merely because the newer checker excludes dotted cuts. I reviewed the attachment and its pinned representation-building dependency; I have not seen the outcomes of those 86 runs.

1. The code really checks the stronger domain
The cone arguments survive nonnegative cut-mass deformation

The code includes oriented cut momenta as future-causal rays, but selects its null anchors only from fixed external rays. It does not select a massless cut momentum as an anchor that must remain null after deformation. The external-ray tests r
2
≥0 and r⋅P>0, with timelike P, establish the needed future-causal character. 

CutIntegrals +1

Both quadratic proof routes are sound:

For a nonnegative sum of future-causal vectors, a null result forces all nonzero summands to be null and collinear. Increasing a cut mass cannot invalidate this implication; it can only make the null result impossible.

For the two-energy-sign route, the decomposition

p
ext
	​

=±q+
r
∑
	​

c
r
	​

r,c
r
	​

≥0,

is used with p
ext
	​

 fixed, future null, and the sign chosen so that the hypothesized null q is future-directed. That again forces collinearity or excludes the zero. Both signs are required before acceptance. The comment referring to “future null vectors” in the sum proof is therefore not an illicit assumption that the deformed cuts remain null: their nullness follows conditional on the sum being null. 

CutIntegrals

The rank test concerns the actual integral Gram

Let V be the formal coefficient space generated by the vectors forced to become collinear, and I the integral momentum subspace. The code computes

dim(V∩I)=rankV+dimI−rank(V+I).

If this is at least two, physical evaluation maps a space of dimension at least two into one physical line. There is consequently a nonzero linear dependence inside I, forcing its Gram determinant to vanish.

This is the right test when unused external directions have been removed. A dependence involving only discarded external directions would not suffice, and the intersection test excludes that mistake. The bilinear proof uses the same valid argument: two future-causal vectors with zero scalar product are collinear or one is zero. 

CutIntegrals +1

The zero-vector branch’s assertion that q∈I also follows for an active loop-dependent quadratic. Writing

q=
i
∑
	​

a
i
	​

ℓ
i
	​

+e,

some a
i
	​


=0, and the corresponding loop–external coupling row of q
2
 is proportional to the coefficient vector of e. Thus the effective external span contains e. Purely external cores are handled separately.

The fallback does not set cut masses to zero

The fallback tests the actual off-shell domain together with

G>0,σ
c
	​

z
c
	​

≥0for every cut,z
j
	​

=0

for the ordinary denominator under examination. The cut variables remain independent existential variables. Only literal False from Resolve is accepted; a timeout or unresolved condition is not promoted to a certificate. 

CutIntegrals

Here the preceding extraction establishes

q
c
2
	​

=m
c,0
2
	​

+σ
c
	​

z
c
	​

.

Accordingly, σ
c
	​

z
c
	​

≥0 means an independently nonnegative increase of physical cut mass squared, including a negatively normalized cut polynomial. 

CutIntegrals

The inspected miRepBaikov dependency supplies all transverse principal-minor inequalities, positive cut energies, an affine scalar-product change of variables, and its constant Jacobian. It does not secretly impose the massless slice in DomainConditions.

2. The finite-η derivative argument closes the dotted-cut identification

Let μ
c
	​

≥0 denote the independent cut-mass-squared increments, and let y denote the remaining scalar-product coordinates. On a sufficiently small compact mass box, consider

J
η,σ
	​

(D,μ)=C(D)∫
K
μ
	​

	​

G(μ,y)
α(D)
P(μ,y)
j
∏
	​

(Q
j
	​

(μ,y)+iσ
j
	​

η
j
	​

)
−ν
j
	​

dy.

The ordinary inverse polynomials are held fixed as off-shell polynomials; only the cut constraints are displaced.

Your compactness argument is uniform in this mass box: future-causal cut energies sum to a fixed timelike total, so all cut components are bounded, and the invertible affine routing bounds the loop coordinates. The above-threshold check guarantees an admissible small mass neighbourhood. 

CutIntegrals

Let r be the total normal-derivative order. Every derivative of order at most r produces finitely many terms with a polynomial numerator, finitely lowered Gram power, and finitely raised ordinary denominator powers. The existing zero-containment proof applies to those raised powers without any new geometric hypothesis: raising a positive integer power does not change its zero set.

On the compact joint domain, Łojasiewicz therefore provides a finite N
r
	​

 controlling all these products. The relevant theorem requires precisely closed bounded semialgebraic domains and zero-set containment; it does not require an explicit numerical exponent. 
Cambridge University Press

Using

∣Q
j
	​

+iσ
j
	​

η
j
	​

∣
−p
≤∣Q
j
	​

∣
−p
,

one obtains bounds of the form

	​

∂
μ
β
	​

(G
α(D)
P
j
∏
	​

(Q
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

)
	​

≤C
B
	​

G
Reα(D)−r−N
r
	​

,∣β∣≤r,
	​


uniformly in positive η
j
	​

, with D in compact subsets of a sufficiently far-right half-plane.

Choosing

Reα(D)>r+N
r
	​


makes all the required boundary traces vanish, not merely become integrable.

Why the moving boundaries cause no surviving terms

A boundary of the positive-semidefinite transverse domain has G=0. On a cut-energy boundary, nonnegative mass squared and zero energy imply that the corresponding cut momentum is the zero vector. Since the cut momenta lie in the actual integral momentum subspace, this also forces its Gram determinant to vanish.

Although the fallback uses strictly positive energies, this observation extends its containment result to the closed physical domain needed for Łojasiewicz. The external reduction explicitly checks that all cut momenta remain in the retained subspace. 

CutIntegrals

At sufficiently large ReD, the required traces of the differentiated density vanish on these boundaries. Differentiating the moving integration domain therefore contributes no surviving surface term.

There is one important precision in the wording:

Zero-extend across the boundaries of the integration fibre, not across the artificial parameter boundary μ
c
	​

=0. Multiplying the mass family by an extra θ(μ
c
	​

) and differentiating would introduce irrelevant mass-parameter contact terms. The mass derivatives here are one-sided derivatives of the physical family.

A two-sided sign theorem for negative cut masses is not required. At finite η, take the prescribed cut normal derivatives; the positive-mass estimates then justify their η→0 limit. The potentially troublesome positive-energy boundary contributions at the massless point are suppressed by the same Gram vanishing.

This yields

η↓0
lim
	​

∂
μ
β
	​

J
η,σ
	​

(D,0
+
)=∂
μ
β
	​

J
0
	​

(D,0
+
)

in an open convergence domain. Their common meromorphic continuation establishes the equality of the dotted definitions. For your 86 masters, r=1, so only the first-order version is needed.

3. The normal-derivative implementation is consistent with this argument

cutOrderNormalDerivatives differentiates the Gram power before setting the cuts to zero. Its recurrence implements

∂
c
	​

(N
s
	​

G
α−s
)=(∂
c
	​

N
s
	​

)G
α−s
+(α−s)N
s
	​

(∂
c
	​

G)G
α−s−1
.

It also includes the factorials required by the cut-power convention. 

CutIntegrals

Differentiating only the Gram-dependent density here is not a missing ordinary-denominator derivative. In these Baikov coordinates, each active ordinary inverse propagator is its own coordinate z
j
	​

, held fixed when differentiating a cut coordinate. Numerator powers represented by nonpositive ordinary indices are likewise independent of the cut coordinates. The more general raised-power estimate above is needed only when expressing the derivatives in another coordinate system.

Nor is a minus sign missing. With the declared cut convention,

r!
(−1)
r
	​

δ
(r)
(z
c
	​

),

integration by parts produces +∂
z
c
	​

r
	​

/r! on the density. The defining representation stores that convention explicitly.

When translating to physical mass increments, retain

μ
c
	​

=σ
c
	​

z
c
	​

,∂
z
c
	​

r
	​

=σ
c
r
	​

∂
μ
c
	​

r
	​

.

The code’s use of the original cut coordinate already keeps this distinction.

The external reduction also preserves the full off-shell polynomials and rebuilds the Baikov representation afterward. It is not replacing a polynomial by an on-shell-equivalent expression before differentiation. 

CutIntegrals

4. What the successful runs would establish—and their scope

There is one concrete scope trap in the file: the NonzeroKinematicConstant branch accepts a loop-independent core when it is not identified as zero. At a fully specialized exact rational point, that is appropriate. For symbolic kinematics, “not identically zero” would not prove nonvanishing throughout a domain. This does not invalidate your stated rational-point tests, but it prevents automatically relabeling their results as global certificates. 

CutIntegrals

Similarly, a numerical-kinematics Resolve[..., Reals] === False certifies that point. The causal-cone witnesses may extend much further: their linear identities can often be reused throughout the physical region once their fixed external nullness, causal signs, ranks, and nonzero factors are established there. A point-specialized QE result alone has no such automatic extension.

The audit conclusion should therefore be:

NLO: Your reported inventory removes the earlier uncertainty about whether its six real masters have dotted cuts: they do not. The undotted justification applies, while the virtual causal phases remain retained. There is no identified unjustified removal in that inventory.

NNLO at v=1/4,w=1/5: If all 86 actual saved dotted definitions pass the attached mass-deformed method, the argument above justifies their zero-ordinary-prescription identification as well as the 259 undotted ones. The former “unproved dotted-master identification” classification would then be obsolete at that point.

Full kinematic functions and endpoint distributions: Retain the scope of whichever witnesses have actually been established. A pointwise dotted-master certificate is not, by itself, a distributional certificate in the observed endpoint variable. That is a scope distinction, not evidence that a causal term was lost.

AMFlow agreement: It remains a comparison between two zero-prescription evaluations. The mass-deformed proof—not their numerical agreement—is what identifies those evaluations with the prescribed physical master.

The new evidence changes the audit materially. No new API label is needed for an older valid proof to count. Successful coverage of the 86 saved off-shell definitions would close the dotted-master causal identification at the comparison point; it should not be described as an unresolved removal merely because the newer certificate is narrower.