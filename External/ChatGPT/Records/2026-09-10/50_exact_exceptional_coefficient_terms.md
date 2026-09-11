# Exact exceptional coefficient terms

Verified model: gpt-6-pro.

## Question

Follow-up review49. Complete exact rational sample screens DISPROVE cancellation in both largest coefficients at eps=1/11,x=2/7,CA=3,CF=4/3 for both moving factors. Checked against full source too. Other ordinary rational columns have poles at those divisors as well. No sampled identity acceptance is being used.

I propose an even simpler conservative implementation than moving-kernel numerator truncation: literal summand partition C = Cregular + Cexceptional. Exact syntactic partition, no cancellation assumption. Only257 affected summands per coefficient involve either rejected moving factor, reducing exceptional sources to4.28MB and3.24MB; regular sources77.26MB/37.19MB have39525/21147 summands (first count actually39325). Reconstruct Cexceptional FULL rational (small enough); reconstruct Cregular as finite epsilon series only after fixed-divisor/joint-unit tail bound succeeds. Final per-master Terms list supports an exact coefficient term plus a finite Laurent coefficient term with explicit tail class. All343 other columns remain full rational. No moving factor gets approximated/truncated. This avoids implementing joint moving-kernel tail analysis in coefficient reconstruction and any proof of cross-master cancellation.

Is this mathematically sufficient for coefficient truncation, assuming global exact exceptional sector is subsequently treated correctly by endpoint assembly? I believe discarded tail lies only in fixed-divisor Cregular*J and hence bound from review48 applies irrespective of meromorphy of exceptional pieces individually.

The downstream scalar endpoint code currently expands each family density in normal z at fixed eps, obtains tangential Frobenius coefficients and endpoint-subtracted integrable remainder, then emits delta derivatives/generalized plus distributions and regular coefficients through eps0. Existing results retained higher derivatives, cancellation only numerical at v=1/4. Your review49 warns logeps and moving poles cannot simply be expanded away. Does retaining Cexceptional exact alone solve this, or must endpoint assembly first prove cancellation of those moving divisors in the sum across families (via coupled DE/master relations), or include a joint moving-kernel moment treatment? Please be precise about the minimal modification required to avoid unsound old endpoint result; general workflow more important than reproducing one process. We can also reconstruct a small exception-sector scalar density and perform joint cancellation before endpoint expansion, but endpoint onsets alone not enough.

Please review the partition strategy and exact-remaining endpoint risk. User wants permanent general fixes, computation efficient, checks not dominant, exact/rational/numerical validation acceptable when labeled. Repository https://github.com/CongyueZhang2002/factorization-and-loops (working changes unpushed).

## Pro response

Yes: the literal exact/series partition is sufficient for coefficient truncation, provided the regular-tail certificate applies to the complete downstream multiplier. No: retaining the exceptional coefficients exactly does not, by itself, validate the existing fixed-ϵ endpoint expansion. These are separate acceptance conditions.

Your partition is the appropriate next step. It avoids both full-rational reconstruction of the large regular sources and an unnecessary cancellation assumption.

1. Why the coefficient partition is valid

Write the physical density, including normalization and signature weights, as

F=
i
∑
	​

A
i
	​

(C
i,regular
	​

+C
i,exceptional
	​

)J
i
	​

.

Replace only the regular part:

F
=
i
∑
	​

A
i
	​

(C
i,regular
[≤U
i
	​

]
	​

+C
i,exceptional
	​

)J
i
	​

.

Then, before any endpoint manipulation,

F−
F
=
i
∑
	​

A
i
	​

(C
i,regular
	​

−C
i,regular
[≤U
i
	​

]
	​

)J
i
	​

.

Thus, if review48’s certificate gives the regular omitted tail a distribution-valued lower bound

ν
ϵ
	​

(Cont[A
i
	​

(C
i,regular
	​

−C
i,regular
[≤U
i
	​

]
	​

)J
i
	​

])≥U
i
	​

+1+β
i
	​

,

then U
i
	​

≥−β
i
	​

 preserves the density through ϵ
0
. The exceptional denominator introduces no additional coefficient-truncation loss, because it does not multiply this error.

The qualification about individual exceptional pieces is correct. Given a physically identified full distribution T and a separately established regular distribution T
regular
	​

, define

T
exceptional
	​

=T−T
regular
	​

.

Individual exceptional summands need not possess separate Laurent expansions. However, they must be combined using the same continuation; independently chosen principal values or prescriptions would invalidate this subtraction argument.

Keep the two terms separate throughout the coefficient pipeline. A later generic “expand the complete coefficient through U
i
	​

” operation would silently destroy the benefit.

2. Exact retention does not cure the endpoint interchange

For the moving factor,

z+τ(ϵ)
1
	​

=
n≥0
∑
	​

τ(ϵ)
n+1
(−z)
n
	​


has radius ∣τ(ϵ)∣→0. Therefore, a fixed-ϵ normal expansion and a remainder integrable at each fixed ϵ do not establish a uniform epsilon expansion of that remainder. Coalescing singularities require a uniform treatment rather than ordinary local asymptotics. 
DLMF

A simple explicit counterexample is

f
ϵ
	​

(z)=
(z+ϵ)
2
ϵ
	​

,0≤z≤1,ϵ>0.

It is integrable for every nonzero ϵ and tends to zero at every fixed z>0, but

∫
0
1
	​

f
ϵ
	​

(z)dz=
1+ϵ
1
	​

⟶1,f
ϵ
	​

⟶δ(z)

distributionally. An epsilon-expanded “regular remainder” can therefore lose a finite contact term.

Fixed-ϵ subtraction itself is not wrong. It remains valid if its remainder is kept exact and its regulated pairing is evaluated or uniformly expanded correctly. The unsupported step is expanding or discarding that remainder using only fixed-ϵ normal integrability.

Consequently, the old result is not newly certified by this partition. Retaining higher delta derivatives and generalized plus terms protects the basis, but not the correctness of their coefficients.

3. The minimum endpoint modification

Add a gate before expanding scalar coefficients or weighted normal germs:

A contribution may enter the existing endpoint-expansion path only with a uniform endpoint/epsilon remainder certificate. An unresolved moving divisor routes it to a coupled exceptional group.

Importantly, that group must include the relevant terms from all 345 columns, including the other full-rational columns carrying these divisors, and the required gluon/ghost weights. “Full rational” is not synonymous with “safe for ordinary endpoint expansion.”

There are two sufficient ways to discharge the group.

A. Remove the moving divisor in the coupled physical density

Use existing exact affine/global relations first. For a simple moving pole, cancellation concerns the weighted master combination

i
∑
	​

r
i
	​

J
i
	​

	​

M=0
	​

,

not ∑
i
	​

r
i
	​

. Higher multiplicities require all principal-part coefficients, including the relevant normal derivatives of the masters.

A successful cancellation must leave a germ whose remaining fixed factors, analytic units and epsilon pole envelope pass the uniformity check. Generic cancellation on the divisor alone is not permission to ignore its intersection with ϵ=z=0.

Your nonzero coefficient-residue screens do not disprove this coupled cancellation. But there is no reason to launch a large new identity campaign: try the already available relations, and route unresolved groups onward.

B. Retain the moving kernel in endpoint subtraction and moments

For a term of the form

K
ϵ
	​

(z)H(ϵ,v,z),K
ϵ
	​

(z)=
(z+τ)
m
z
α(ϵ)−1
log
k
z
	​

,

Taylor-subtract the smooth multiplier Hφ, not the moving denominator:

⟨KH,φ⟩=
n=0
∑
q−1
	​

n!
∂
z
n
	​

(Hφ)(0)
	​

∫
0
Z
	​

z
n
K
ϵ
	​

(z)dz+∫
0
Z
	​

K
ϵ
	​

(z)[Hφ−Taylor
q−1
	​

(Hφ)]dz.

The kernel moments have a reusable explicit representation:

∫
0
Z
	​

(z+τ)
m
z
a−1
	​

dz=τ
a−m
B
Z/(Z+τ)
	​

(a,m−a),

initially in a convergent domain and then with the inherited analytic continuation. Derivatives in a generate the logarithmic moments. This follows directly from the incomplete-beta integral by t=z/(z+τ). 
DLMF

Choose q to make the required epsilon-expanded remainder uniformly integrable after extracting its known epsilon poles, not merely integrable at fixed epsilon. Keep terms such as τ
bϵ
, hence possible logϵ, until the complete coupled group is assembled.

Products of moving factors must retain their intersections and coalescences. Partial fractions introducing (τ
1
	​

−τ
2
	​

)
−1
 need their own domain/order accounting; they are not automatically simpler. Equivalently, a regions-based implementation must include the z∼ϵ contribution and required overlaps, not just the fixed-z expansion. 
arXiv

Cancellation is therefore optional; a valid joint treatment is not. Evaluating the exact regulated remainder before expansion is also acceptable—it is another realization of that joint treatment.

4. Small implementation safeguards

Partition by a positive safety certificate. Every summand goes exactly once into the regular or exceptional set; undecidable factors go into exceptional. Recognize factor associates after the actual coordinate substitutions, rather than searching for the printed spelling of two particular polynomials.

Bind the tail to its actual multiplier. If subsequent basis relations or normalization changes introduce moving factors, preserve a certificate for the original combination or reclassify the affected product. Do not transport a per-term tail bound through an uncertified singular map.

Exact coefficients do not make finite master data exact. The exceptional path still needs sufficient epsilon and normal orders of the saved masters/boundaries under its joint kernel. Their old fixed-endpoint order demand may be insufficient.

Keep storage and endpoint eligibility separate. Retain master/signature IDs, exact versus Laurent representation, truncation and tail class. The existing checkpoint already provides the master/signature/output associations needed to split sources without changing their identity. 

pending_coefficient_reconstruct…

If the full physical family and the regular contribution are meromorphic, their exceptional difference is meromorphic. Uncancelled logϵ terms through the requested order then signal an unfinished or inconsistent assembly; they must not be deleted manually.

5. Acceptance tests that address the actual risk

Use exact partition accounting and reconstruction checks for the coefficient layer. For the endpoint layer, add the delta-producing example above, a kernel producing logϵ, a higher-multiplicity pole, and a pair whose moving singularities cancel only after summation.

Numerical validation should compare regulated test-function pairings—including tests probing the retained delta derivatives—not only values at fixed interior points. Such tests provide validation, not a universal uniformity proof; the existing reconstruction documentation already distinguishes sampled agreement from an identity certificate. 

pending_coefficient_reconstruct…

Proceed with the exact-exceptional/finite-regular reconstruction. Keep the ordinary endpoint engine unchanged for certified inputs, but prevent moving-divisor groups from reaching its fixed-epsilon remainder expansion until coupled cancellation or joint moments have supplied the missing justification.