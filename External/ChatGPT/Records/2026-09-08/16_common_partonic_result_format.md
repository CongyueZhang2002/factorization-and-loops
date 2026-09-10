# Common partonic result: normalization review

Model: verified gpt-6-pro. Conversation: https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4

## Request

The user added: no backward compatibility; regenerate. Also Counterterm.wl must explicitly name lower-order result paths and epsilon ranges, and LO/NLO/NNLO should write one common result schema directly.
We implemented one common FeynFacet-PartonicResult with Order, Contribution, Project/Channel/physical channel, Scale s, Variables {v,w}, DimensionalRegulator, explicit contiguous EpsilonRange and Coefficients[epsilonPower] = {DeltaCoefficient, PlusCoefficients, RegularCoefficient}, density E_c d sigma/d^(D-1)p_c. No LO+NLO combined file: each order/channel has Results/Result.wl. NLO Real/Virtual/Counterterm write the same shape under their result subdirectories.
Question for mathematical review: LO computes the generated invariant density b(s,t,u;eps)*delta(s+t+u), maps to w=1 and stores B(s,v;eps)=b(s,s(v-1),-s*v;eps)/(s*v) as the delta(1-w) coefficient. Counterterm convolution consumes the common LO epsilon coefficients directly and reconstructs b_on_shell(s,t;eps) = s*v*B(s,v;eps) at v=1+t/s before applying the EXISTING physical incoming-A/B/FF invariant maps and Jacobians. This only evaluates b on its Born support; no off-shell extension is required. It checks LO availability through target+1 because the NLO kernels/UV have simple epsilon poles. Current finite NLO requests Born {0,1}; standalone LO cards may request {0,2} etc, generated explicitly. Coupling power is derived from the generated Born (declared Born power only for the identically zero case). Known LO coefficients must have zero regular/plus fields.
Is there any subtle normalization / epsilon / support error in this common-format consumption? Preserve the existing AMFlow normalization, physical powers of alpha_s, FF D-dimensional Jacobian and deferred common dimensional scale convention. We are doing fresh NLO UU/LL/TT and exact/reference checks. Please keep response brief and focused on any blocker, rather than another broad design review.

## Response

The conversion is correct, and I see no blocker in consuming the LO result this way. For s>0, 0<v<1,

s+t+u=sv(1−w),δ(s+t+u)=
sv
δ(1−w)
	​

.

Thus your B=b
on
	​

/(sv) is exactly the delta coefficient. No additional dvdw Jacobian belongs here: you are re-expressing the invariant density, not changing its definition into dσ/(dvdw).

Reconstruct using the mapped Born invariants. Inside each convolution, the identity is

b
on
	​

(s
′
,t
′
;ϵ)=s
′
v
′
B(s
′
,v
′
;ϵ),v
′
=1+t
′
/s
′
,

not the original target’s sv. Retain the existing constraint Jacobian separately and exactly once. Because the mapped Born delta imposes u
′
=−s
′
−t
′
, no off-shell extension of b is needed.

The epsilon demand is sufficient for these counterterms. For a complete mapped counterterm operator

T(ϵ)=ϵ
−1
T
−1
	​

+T
0
	​

+⋯,

its finite coefficient is

[TB]
ϵ
0
	​

=T
−1
	​

B
1
	​

+T
0
	​

B
0
	​

.

Therefore Born {0,1} suffices for finite output, provided all prefactors and mapped weights are included in that simple-pole counting. The standard incoming and FF counterterms have precisely this pole structure; the FF weight remains ξ
−2+2ϵ
, whose expansion contributes finitely. 
arXiv
+1
 Missing Born orders must fail, not become zeros. This depth rule is for counterterm consumption, not automatically for a separate virtual representation containing double poles.

The main normalization trap is a deferred scale factor. If a stored coefficient omits a factor depending on the Born invariant s, evaluate that factor at s
′
 before returning to the common convention. For example, a deferred s
−ϵ
 produces

(s
′
/s)
−ϵ
=1−ϵln(s
′
/s)+⋯,

which changes the finite counterterm when multiplied by 1/ϵ. A genuinely common, map-independent μ
R
	​

 factor can remain deferred. Restore neither factor twice.

Finally, since B already contains its physical α
s
	​

 power, counterterms multiply it only by the additional perturbative factor. Determine the Born power from the untruncated generated expression and verify homogeneity; use the declared fallback only for an exactly zero Born. The zero LO regular/plus requirement is correct.