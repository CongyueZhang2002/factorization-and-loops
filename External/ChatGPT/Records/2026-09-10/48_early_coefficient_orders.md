# Sufficient coefficient orders before reconstruction

Verified model: gpt-6-pro.
Request: 077fe72a-00c9-408f-8663-b928d72f28e9.

## Question

Follow-up with decisive local Git history, recovered after your last response. Please review the mathematical route to early coefficient truncation; focus on a general sufficient-order contract rather than proposing another long full-rational pilot.

Old WORKLOG (commit 4b822e5e, Aug13) records entrywise exact Together compaction: largest column 462.6MB ->88.8MB in109s; second267.6->46.1MB; six biggest compacted. Full-rational largest had prime1=2,721,256 probes and total>3.48M. Color-grid splitting was measured and worse: 1.7x NLO,4x ghost,6x projected largest. Epsilon-series route succeeded: 345 exact outputs3.4h, largest through epsilon5 in18.1min/345682probes and second in5.3min/198027probes. Historical depth5 was a safety margin. Final result has347entries, two exactzeros and two finite series.

New normalized columns345,852MB. The two largest378MB and201MB are precisely those old finite-series masters, GLI[CF1,{1,1,0,0,1,0,0,0,0}] and GLI[CF1,{1,1,1,0,1,0,0,0,0}]. Third69MB. General production driver bypassed compaction and scheduled reconstruction, an actual regression. Native shared full-rational worker is paused with live state. We are restoring generic exact compaction, bounded per input summand, cost-selected rather than family-selected, before native trace construction.

Actual trace aliases map epsilon to FACETffeaed3b5ev3. Seven analytic signatures are 2^(4epsilon) Pi^(3+2epsilon) alpha_s^4 times s^k (k=-2..4), so epsilon valuation0. Physical factor D1[zh]f1[xa]f1[xb]/(xa xb zh^2). We already have saved physical DE solutions, boundary data and endpoint systems; fresh integral definitions can be matched before coefficients.

For a rational coefficient sum of N_t/D_t, can generic separability of each input denominator divisor in epsilon and endpoint variables provide a practical sufficient condition for safe fixed-epsilon truncation, together with existing endpoint master Taylor/moment order machinery? For example D_t decomposes as epsilon^a times epsilon-only factors nonzero at0 and kinematic-only factors. This seems to exclude moving divisors like z+epsilon a(v) structurally, without reconstructing any full denominator. Then bound the epsilon tail termwise through rational kinematic jets times the saved physical master's distribution-valued germ. Need also handle mixed factors that are units on the closed endpoint neighborhood with exact domain proof, or conservatively require full epsilon for those.

What exact bound/data must be computed before interpolation to avoid relying on old epsilon5, and can we restrict finite-series mode to columns for which such a separability/endpoint bound is proved, retaining exact epsilon otherwise? Please flag subtle issues with retained higher delta derivatives/generalized plus terms, cancellations among summands, and series internals. We will not claim a sampled rational check proves endpoint uniformity. Please give a concise implementable sufficient criterion, not necessity. No need to revisit color-grid splitting.


## Pro response

Yes. Denominator separability, extended to rigorously established joint analytic units, gives a practical sufficient criterion—but only when paired with a pole bound for the appropriately weighted master distribution. This supports selective finite-series reconstruction without reconstructing a whole-column denominator or adopting the historical ϵ
5
 margin.

The recovered history favors restoring exact compaction and this certified series route, rather than another full-rational pilot.

1. A sufficient denominator-and-tail certificate

For each input summand, after the exact coordinate/normalization substitutions used in production, require a verified representation

R
t
	​

(ϵ,x)=
ϵ
a
t
	​

d
t
	​

(ϵ)k
t
	​

(x)u
t
	​

(ϵ,x)
N
t
	​

(ϵ,x)
	​

,

where x denotes the relevant kinematics.

Require N
t
	​

 to be polynomial—or otherwise certified jointly analytic—and:

d
t
	​

(0)

=0.

k
t
	​

 is epsilon-independent, with its zeros accounted for by the existing endpoint charts or excluded domain.

u
t
	​

 is jointly analytic and nonzero near ϵ=0 on the closed normal neighborhood over each permitted tangential compact.

For polynomial u
t
	​

, an exact proof that u
t
	​

(0,x)

=0 throughout that compact neighborhood suffices: compactness gives a common smaller complex epsilon disc without zeros. Generic nonvanishing, or positivity only for positive epsilon, does not suffice.

Pure separability is the special case u
t
	​

=1. A divisor z+ϵa(v) fails this test at z=ϵ=0; writing it as z(1+ϵa(v)/z) does not turn the second factor into an analytic unit.

You need only inspect the distinct divisors in the input summands, with their multiplicities and exact factorization identities. Irreducible factorization of the enormous combined denominator is unnecessary.

This certificate implies, for truncation through U,

R
t
	​

−Trunc
ϵ≤U
	​

R
t
	​

=ϵ
U+1
k
t
	​

(x)
h
t,U
	​

(ϵ,x)
	​

,

where h
t,U
	​

 is jointly analytic, including the finitely many normal derivatives required by endpoint subtraction. This is the coefficient-tail property you need; fixed-z Laurent agreement alone is weaker.

2. The order bound must belong to the weighted distribution

Let A
t
	​

 contain the remaining normalization, analytic signature, exact integral-relation factors and matched master contribution. Establish the meromorphic distribution

T
t
	​

(ϵ)=Cont[
k
t
	​

(x)
A
t
	​

(ϵ,x)
	​

]

using the already established physical continuation.

Put 1/k
t
	​

 into the regulated germ before continuation. It is generally invalid to multiply an already-expanded delta/plus record by an endpoint-singular 1/k
t
	​

.

The planner must certify an integer lower bound β
t
	​

 such that

ϵ
−β
t
	​

T
t
	​

(ϵ)

is holomorphic as a distribution, with a finite distribution-order bound controlling multiplication by the smooth remainder h
t,U
	​

. Then

ν
ϵ
	​

(ϵ
U+1
h
t,U
	​

T
t
	​

)≥U+1+β
t
	​

.

Therefore, for a physical result through ϵ
N
,

U
t
	​

≥N−β
t
	​

.
	​


For one reconstructed column containing several summands, use

U
column
	​

=
t
max
	​

(N−β
t
	​

),L
column
	​

=
t
min
	​

(
ν
	​

ϵ
	​

N
t
	​

−a
t
	​

).
	​


These are conservative bounds; no cancellation between summands is needed.

Your seven stated signatures and physical factor contribute zero epsilon valuation, so they introduce no additional pole loss. Their higher Taylor coefficients still enter the final convolution. Physical-master conversion, basis relations, boundary amplitudes and endpoint moments may introduce losses and must be counted exactly once.

The checkpoint already retains the master, signature, symbol-alias and output associations needed to attach this plan before interpolation. 

pending_coefficient_reconstruct…

3. What the endpoint planner must supply

Apply the saved endpoint machinery to the fixed-denominator-weighted germ, not just the original master’s bulk lower bound. It must cover every populated epsilon-slope/Jordan-log class, the required faces/corners, and the uniformly integrable remainder. Resolving fixed singular factors and Taylor-subtracting the smooth remainder is the standard constructive mechanism for meromorphic continuation. 
arXiv

For example, a weighted mode

z
−p+bϵ
(logz)
m
F(z,ϵ),p≥1,

needs Taylor coefficients through normal order p−1, with a uniform O(z
p
) remainder. Its subtraction moments are

∂
λ
m
	​

λ
Z
λ
	​

,λ=n−p+1+bϵ.

For b

=0, the resonant moment n=p−1 can lose m+1 epsilon orders. Other moments can contribute nonzero contact terms and must remain.

Higher delta-derivative order increases the required normal jet depth; it does not automatically add that many epsilon poles. A zero-slope resonance requires its existing continuation or exact cancellation certificate—not an invented 1/ϵ.

A useful adversarial case is

ϵz
+
−2−ϵ
	​

=δ
′
(z)+O(ϵ).

Thus a coefficient tail invisible at fixed z>0 can affect the finite contact term. The bound above correctly requires the extra coefficient order.

Propagate the complementary demands into the saved data as well. If a product has lower bounds ℓ
C
	​

,ℓ
A
	​

,ℓ
M
	​

 and an additional endpoint-moment loss p
end
	​

, a conservative master requirement is

U
M
	​

=N−ℓ
C
	​

−ℓ
A
	​

+p
end
	​

.

Apply the analogous rule to boundary constants, normal jets and prefactors. Exact epsilon dependence in the coefficient cannot compensate for insufficient master/boundary orders.

4. Cancellations and series internals

Summand cancellations only improve conservative bounds—provided each summand admits the stipulated continuation. If artificial singularities cancel only after combining terms, certify that exact group first. Failure of the termwise test is inconclusive, not evidence of a physical problem. Exact compaction can expose such cancellations without changing the calculation.

For mixed analytic units, higher epsilon coefficients can have larger powers of u
t
	​

(0,x)
−1
. This is harmless on a certified compact where that factor never vanishes. It is not harmless merely because it is nonzero at the matching point.

Output depth is not a universal internal truncation depth. For A/B with exact valuations a,b, computing through absolute order U generally needs A through U+b and B through U−a+2b. Factor explicit epsilon powers and propagate order demands through multiplication/division; a zero truncated denominator is not a zero exact denominator. Ratracer’s to-series transforms intermediate trace values, so pole/cancellation regressions must exercise that path. 
GitHub

Retain analytic signatures outside rational Laurent coefficients, or convolve them explicitly to the planned depth. Every finite column needs its own certified lower bound, upper order and unknown-tail marker; an all-zero known prefix is not an exact-zero column.

Recommended implementation

Create a small pre-interpolation certificate per output containing:

bound master/normalization identity; endpoint domain and denominator classes; coefficient lower bound; weighted-distribution lower bound and normal-jet demands; required upper order; saved-data coverage.

Enable finite-series mode only when all required certificates pass. Otherwise retain exact epsilon for that column—or for a separately certified summand group. Full epsilon is a fallback representation, not a substitute for eventual endpoint validity.

The existing scheduled path already invokes to-series with an explicit alias and order; supply the certified order rather than its default. 

pending_coefficient_reconstruct…

 No numerical depth for the two large columns follows from the history alone: the missing inputs are their divisor inventories and the resulting weighted-germ bounds.

This route preserves all completed production work and all generalized endpoint terms. It needs exact local denominator/order analysis, not another global rational reconstruction or an endpoint-cancellation proof.