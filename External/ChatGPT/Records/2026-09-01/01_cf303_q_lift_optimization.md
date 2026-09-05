# CF303 q Lift Optimization

## Question

# CF303 follow-up: bypass a multi-hour cross-prime lift

Please continue the established **Assess Multiquadratic Pipeline** conversation.  We need a decisive mathematical/algorithmic optimization, not hashes, provenance machinery, or additional validation layers.

We have reduced the last unresolved CF303 coupling `(25,1)` pointwise over 61-bit primes.  The production evaluator parses a factorized 144-expression DAG, samples 129 generic `u` points on the two physical root sheets, reconstructs the rational and elliptic scalar channels, and performs modular Hermite reduction.  No Wolfram or Maple symbolic materialization remains.

Measured cost for one fixed `(q,p,epsilon)` image is:

- one native thread: 4.99 s;
- two native threads: 2.88 s;
- four native threads: 1.73 s.

At each `q`, the exact nested reconstruction currently uses 19 epsilon images (17 construction plus two complete held-out images) at each of 139 generic `p` images (135 construction plus four held-out).  There are 2,540 flattened coordinates.  At q1 every held-out image passed; maximum epsilon total degree is 16 and maximum p total degree is 127.  The q1 p-profile discovery took only 12.27 s, so essentially all wall time is the roughly 681,000 physical point/sheet evaluations.  A 16-core pool presently gives about 8.4 s per `p`, or about 19.5 minutes per fresh q.  q2 is running now.

The current exact-lift tool combines q-images by CRT, applies the conservative unique rational-reconstruction bound `|a|,|b| < sqrt(M/2)` coefficient by coefficient, and replays every reconstructed coefficient at the next disjoint accepted q-image.  Previous CF303 exceptions happened to require 8 or 12 61-bit CRT primes under conservative reconstruction, suggesting 3--4 hours if copied blindly.  We accept a probabilistic production certificate: complete equality at a fresh disjoint 61-bit prime is enough; we do not want a giant symbolic equality check.

Please assess the following possible bypasses and give a prioritized concrete recommendation:

1. Can maximal-quotient/continued-fraction rational reconstruction (Monagan-style or another early reconstruction) recover exact coefficients well outside the symmetric square-root bound, with the following q-image providing the decisive full replay?  State the candidate-selection rule, failure modes, and whether q1+q2 followed by q3 validation could often be enough.
2. Are we wasting q-height by reconstructing every normalized p/epsilon numerator and monic denominator coefficient independently?  Can shared denominator factors, the known path divisors, simultaneous/vector rational reconstruction, or a structured normalization materially reduce the modulus required without reintroducing symbolic expansion?
3. Can several q primes be evaluated in one traversal of the same factorized DAG (RNS batching, SIMD/multi-modulus arithmetic, 128-bit primes, or evaluation over a composite CRT modulus)?  Distinguish genuine arithmetic reuse from merely splitting the same work among cores.  Parsing is only about 0.23 s of a 1.44 s four-thread native image, so optimize the evaluation, not just parsing.
4. Is there a sound route that bypasses the full nested `(p,epsilon)` coefficient lift altogether--for example sparse bivariate reconstruction, reconstructing only the final path-gauge combinations, or carrying modular evaluators into the final transport and lifting only paper-facing outputs?  We ultimately need a reusable exact block-25 gauge/operator, not just one numerical point.
5. Give realistic expected q-count and wall-time reductions, and identify the smallest implementation that should be tried first.  Reject elaborate changes that buy only a few percent.

Current acceptance philosophy is fixed: the block result is accepted by complete pointwise modular replay at independent `u`, epsilon, p, and q images.  Do not recommend redundant intermediate checks.

## Pro response

Recommendation

GO now: replace the symmetric-bound-only lift by maximal-quotient reconstruction, followed by the already required disjoint-prime replay. Add shared-denominator reconstruction within each normalized polynomial pair—not across the whole block.

Do not commit to eight or twelve primes in advance. Those earlier counts are not a height bound for this coupling. Conversely, q
1
	​

+q
2
	​

 may still contain insufficient information: early reconstruction removes an unnecessarily restrictive bound; it cannot recover arbitrary large coefficients from too few bits.

The smallest implementation changes only the candidate-generation stage of the lift tool. Leave the working physical evaluator and nested interpolation intact while q
2
	​

 finishes.

Priority	Change	Judgment
1	Maximal-quotient reconstruction on existing CRT coefficients	Implement immediately
2	Shared scalar-denominator recovery within each normalized numerator/denominator pair	Implement alongside it; small extension
3	Primitive/projective or factored representation for stubborn coefficient groups	Conditional next step
4	Reduce the number of physical samples using known supports/denominators or finite Laurent jets	Potentially large, but not the first patch
5	Multi-prime SIMD, 128-bit primes, composite-modulus evaluation	Do not pursue tonight
1. Early rational reconstruction is the right first bypass

For a scalar coefficient a/b, the current symmetric rule requires approximately

M>2max(∣a∣,b)
2
.

With known separate numerator and denominator bounds A,B, the usual uniqueness condition is instead

2AB<M.

FLINT exposes both the balanced reconstruction routine and fmpq_reconstruct_fmpz_2 with separate bounds. The difficulty is that the useful asymmetric bounds are not known beforehand. 
Flint Library

Monagan’s maximal-quotient rational reconstruction addresses precisely that problem. It searches the extended Euclidean remainder sequence for the conspicuously large quotient associated with the correct rational. Its practical modulus requirement tracks ∣a∣b, rather than max(∣a∣,b)
2
, when the large quotient is distinguishable. Its improvement is heuristic; worst-case behavior is not better than conventional reconstruction. 
CECM

Concrete candidate rule

For a CRT residue xmodM, run extended Euclid with

r
0
	​

=M,r
1
	​

=x,t
0
	​

=0,t
1
	​

=1,

so that r
i
	​

≡t
i
	​

x(modM).

At each division, compute

Q
i
	​

=⌊
r
i
	​

r
i−1
	​

	​

⌋.

Save the pair (r
i
	​

,t
i
	​

) associated with the largest sufficiently large Q
i
	​

. The candidate is

a/b=r
i
	​

/t
i
	​

,

with b>0. Require b

=0, coprimality, invertibility of bmodM, and the defining congruence.

A reasonable starting threshold is the moderate FireFly choice

T=2
10
⌈log
2
	​

M⌉,

rather than a threshold designed to make reconstruction itself the final certificate. FireFly implements this maximal-quotient approach and uses that threshold scaling. 
arXiv

Return candidate or unresolved, never “exact by the reconstruction bound.” Keep the existing balanced reconstruction available when maximal-quotient reconstruction is inconclusive.

How far outside the square-root bound?

Let

h
a
	​

=log
2
	​

max(1,∣a∣),h
b
	​

=log
2
	​

b.

The useful comparison is

symmetric:
early reconstruction:
	​

log
2
	​

M≳2max(h
a
	​

,h
b
	​

)+1,
log
2
	​

M≳h
a
	​

+h
b
	​

+quotient-separation allowance.
	​


For q
1
	​

q
2
	​

, log
2
	​

M≈122. With the threshold above, the allowance is about 17 bits. Thus coefficients with, for example, a 95-bit numerator and a 5-bit denominator are plausible two-prime reconstructions despite lying far outside the symmetric numerator bound.

But a coefficient with both numerator and denominator near 150 bits is not a plausible scalar reconstruction from 122 bits.

The measured degrees 16 and 127 do not determine these integer heights. Nor do they establish that the old eight-/twelve-prime examples predict this block.

Use the next prime correctly

Try a complete candidate from q
1
	​

 alone now; q
2
	​

 can reject or accept it. Otherwise combine q
1
	​

,q
2
	​

, generate a complete candidate, and use q
3
	​

 as the independent replay.

If replay fails, absorb that prime into CRT and try again. A candidate modified using q
3
	​

 is not independently validated by q
3
	​

.

The principal failure modes are insufficient modulus, competing large Euclidean quotients, and genuinely large balanced coefficients. None requires changing the physical sampler.

2. Monic normalization can waste height—but there is a small remedy

There are two different kinds of denominator here:

Functional denominators in p,ϵ.

Integer denominators of the rational coefficients being CRT-lifted.

The immediate opportunity concerns the second.

Suppose one outer univariate rational function has a primitive integer representation

f(p)=
B(p)
A(p)
	​

,lc(B)=b
d
	​

.

Its monic-denominator representation is

B/b
d
	​

A/b
d
	​

	​

.

All normalized coefficients therefore share a scalar denominator dividing b
d
	​

. Reconstructing each ratio independently can demand much more modulus than recovering that shared scalar once.

Smallest shared-denominator algorithm

Group the coefficients belonging to one normalized numerator/denominator pair. Process simple nontrivial coefficients first—often endpoint coefficients are better seeds than central ones.

Maintain a candidate common scalar denominator D, initially one:

for each coefficient residue x_i:
    reconstruct D*x_i mod M as a_i/b_i
    coefficient candidate = a_i/(D*b_i)
    D = D*b_i

Revisit unresolved coefficients whenever D grows. Once D clears the group, reconstruct the scaled coefficients as integers.

This is the simultaneous-reconstruction strategy described by Abbott; it can recover a coefficient that fails independent reconstruction because previously recovered coefficients reveal its denominator. 
arXiv

Do not build one scalar LCM across unrelated functions or all 2,540 outputs. That can make the problem worse.

If there is no easy seed

For a stubborn group, use a small simultaneous lattice problem on perhaps 8–16 nontrivial coefficient ratios:

Λ={(d,n
1
	​

,…,n
k
	​

)∈Z
k+1
:n
i
	​

−dx
i
	​

≡0(modM)}.

A row basis is

	​

1
0
⋮
0
	​

x
1
	​

M
0
	​

⋯
⋱
	​

x
k
	​

0
M
	​

	​

.

A short primitive vector with d

=0 proposes a shared denominator. Apply it to the remaining coefficients and submit the resulting complete rational function to the same next-prime replay.

This is a candidate generator, not an unconditional short-vector theorem. It is worth attempting only for the remaining hard groups; a 2,540-dimensional lattice would be the wrong implementation.

Known functional factors can reduce height further

If a denominator is actually

B(p,ϵ)=c
j
∏
	​

f
j
	​

(p,ϵ)
m
j
	​

,

lifting the small factors and exponents avoids lifting large coefficients created only by expansion and monic normalization. The existing modular records can be converted to this representation without resampling the physical DAG.

However, the denominator of a Hermite-reduction coefficient is not determined solely by the original kernel’s pole factors. It may also contain:

pole-collision discriminants;

resultants between pole factors and the quartic;

leading coefficients used in reduction;

factors introduced by base-point normalization.

Use the actual reduced modular denominators to identify the relevant factors. Do not assume that the visible path poles alone provide a complete coefficient-denominator formula.

Priority: denominator-seeded reconstruction first; projective/factored lifting only for stragglers. All of this can operate on q
1
	​

,q
2
	​

 already obtained.

3. Multi-prime evaluation will not remove the underlying arithmetic count

A fused RNS evaluator can visit each DAG node once and carry a vector

(vmodq
1
	​

,…,vmodq
k
	​

).

It can share opcode dispatch, exponent metadata, point coordinates and memory accesses. But it still performs k modular multiplications, reductions and inversions for each required arithmetic operation. Root values and exceptional-point handling remain modulus-specific.

Your parsing number gives a useful ceiling: removing all 0.23 seconds from a 1.44-second image saves only about 16%, or 1.19×. Multi-modulus execution might improve more by reducing dispatch or exploiting suitable SIMD hardware, but there is no evidence here for the multi-fold gain needed to justify a new backend.

Specific decisions

RNS/SIMD: mathematically sound; defer unless early lifting fails and a substantial remaining prime count is demonstrated.

128-bit primes: reject as the immediate change. A 61-bit product fits in 128 bits; a 128-bit field generally requires wider multiplication and new reduction, inversion and root machinery. Twice the bits per prime is not automatically twice the throughput.

Composite CRT modulus: do not run the existing interpolation/Hermite algorithms over Z/MZ as if it were a field. Pivots, leading coefficients and denominators can be nonunits. A correct componentwise implementation is RNS again, with essentially the same arithmetic work.

There is one cheap scheduling observation in your timings. The approximate native core-seconds per image are

4.99,2(2.88)=5.76,4(1.73)=6.92.

On a fully occupied 16-core machine, more independent one- or two-thread images can therefore outperform four-thread images in total throughput. The idealized gain is about 17% for two-thread jobs or 28% for one-thread jobs, subject to available task concurrency and memory. That is worth a simple configuration choice, not a substitute for reducing the prime count.

4. Can the nested (p,ϵ) lift be bypassed?
First avoid reconstructing the validation prime unnecessarily

There are two distinct replay costs:

comparing against a fully reconstructed q
3
	​

 coefficient record;

evaluating the candidate and the native black box at the prescribed fresh (p,ϵ,u) images modulo q
3
	​

.

Under your stated pointwise production policy, the second is enough and does not require rebuilding the 139×19 nested interpolation at q
3
	​

. Evaluate all output components, not a projection or subset.

This is the same complete pointwise acceptance, executed directly rather than through an unnecessary reconstruction of the validation image. The campaign’s established acceptance already uses fresh modular points rather than symbolic expansion. 

11_reconstruct_dont_simplify

If the current operational requirement is specifically equality of every normalized coefficient against a complete q
3
	​

 record, retain that once. Do not silently substitute a different requirement. But the broader pointwise policy stated in this request permits saving almost the entire validation-prime campaign.

Sparse bivariate reconstruction: conditional, not the first rewrite

The current construction uses

135×17=2295

physical (p,ϵ) pairs per prime, before held-outs.

A support-aware bivariate rational fit could need substantially fewer if the actual numerator/denominator supports are sparse. But it does not, by itself, reduce the integer coefficient heights. Your 12.27-second profile-discovery stage is already cheap; replacing its algorithm helps only if it reduces the number of physical probes.

Inspect the existing q
1
	​

 rational functions algebraically—without new physical sampling. Pursue sparse bivariate reconstruction only if the resulting joint supports predict approximately a factor-two or better reduction in probe count. FireFly and related finite-field methods explicitly exploit sparse multivariate supports for this purpose. 
arXiv

Reconstructing only final path-gauge combinations

This is legitimate if those combinations are exactly the reusable objects required downstream, and omitted intermediate coordinates never need to be recovered separately.

But your current 2,540 coordinates are already Hermite-reduced outputs. The path-gauge recurrence also needs the primitive H for

F
25
	​

=G
25
	​

+HL.

Lifting only remainder coefficients is therefore insufficient. Lifting fully expanded paper-facing word coefficients would likely be worse: it reintroduces the word explosion already avoided by the weighted operator.

A genuine finite-depth bypass

For the agreed transport through ϵ
2
, an exact finite Laurent deck is sufficient if that is the intended reusable operator contract.

With the established incoming minimum −2 and global lower-boundary minimum −4, the safe incoming range is

−2≤r≤6.

If the curve and Hermite pole basis are epsilon-independent, expand the DAG into those nine Laurent coefficients and apply the same Hermite reduction map to all of them. You then reconstruct rational functions of p, not a full rational function of ϵ.

This removes the need to reconstruct behavior at arbitrary epsilon. It is an exact finite-order operator, not an all-orders rational-in-epsilon gauge. It is potentially valuable, but requires a series-valued evaluator and should follow—not delay—the almost-free early-lift experiment.

A modular evaluator alone is not a reusable characteristic-zero result. A lifted Laurent deck, a rational coefficient representation, or an exact arithmetic circuit over Q is.

5. Realistic savings and the smallest implementation
Do not promise three primes

Plain scalar early reconstruction can approach a factor-two reduction in required modulus bits for strongly asymmetric coefficients. It may save almost nothing for balanced coefficients. Shared normalization or factored representations can improve further, but that must be demonstrated on these records.

At your measured 19.5 minutes per complete prime image:

Total full prime images, including one full replay image	Approximate time
3	58.5 min
5	97.5 min
7	136.5 min
8	156 min
12	234 min

These are arithmetic projections from your timing, not predictions of the required count.

For example, if an old eight-prime requirement came from roughly 240-bit numerators with small denominators, early reconstruction might reduce it to around four or five construction primes. It would not generally reduce that example to two. If the current coefficients instead have numerator-plus-denominator heights below roughly 105 bits, q
1
	​

q
2
	​

 is a credible candidate modulus.

Implement this now

Run maximal-quotient reconstruction on the completed q
1
	​

 record. This costs no physical evaluations.

Apply shared-denominator propagation within each normalized polynomial pair.

If a complete candidate exists, compare it with q
2
	​

. Otherwise combine q
1
	​

q
2
	​

 and repeat.

Use the next unused prime for the existing complete replay. A failed replay becomes construction data for the next attempt.

Only for unresolved groups, try small projective/vector reconstruction or preserve already identified denominator factors unexpanded.

Stop preallocating an eight-/twelve-prime campaign. Generate the next full prime only when the current information cannot yet produce an accepted complete candidate.

No sampler changes, new word engine, symbolic equality check, or additional certification stage is required.

Bottom line

The strongest immediate bypass is early rational reconstruction plus recovery of shared scalar normalization. Both use data already paid for, and neither changes the exact function being reconstructed.

Run that lift-only experiment while q
2
	​

 completes. If it produces a complete candidate from q
1
	​

q
2
	​

, the next disjoint-prime replay is the decision. If it does not, the recovered height structure tells you whether the remaining cost is genuine coefficient information or avoidable monic/factor expansion—before spending another several hours of physical sampling.
