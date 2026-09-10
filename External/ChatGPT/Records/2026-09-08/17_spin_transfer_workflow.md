# NLO spin transfer review

Verified gpt-6-pro, HTTP 200; https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4

## Request

Review extending our general FeynFacet massless NLO single-inclusive qq' -> observed q + X calculation from incoming-incoming LL/TT to incoming-A/observed-q spin transfer, plus comprehensive cleanup. We now use explicit project/order/channel cards and physical delta/plus/regular epsilon coefficients. All existing incoming LL expressions match Vogelsang exactly, UU matches INCNLO, incoming TT for distinct flavors is zero.

New transfer configurations are g1(xa) f1(xb) G1(zh), and h1(xa) f1(xb) H1(zh); observed quark is the continuation of incoming flavor u, unpolarized incoming d. Need generated Born qq' and qg channels, all real/virtual graphs, UV and collinear counterterms, no fitted factors.
Currently EnumerateNLOCollinearChannels takes IncomingSpins only and hardcodes Observed=U. I will make polarization explicit by physical legs, use Observed=L/T kernels for FF subtraction, U kernel for beam B including qg Born mixing, retain the D-dimensional FF xi^(-2+2eps) Jacobian, and record the full polarization identity in results. The LO q->q polarized timelike kernel is same as spacelike; no off-diagonal observed channel survives flavor conservation here. IncomingA/observed helicity-restoring finite Zqq=-4CF(1-xi) must be selected explicitly by scheme cards, rather than add fit terms. Please review whether this finite choice is appropriate for our BMHV projected polarized FF, and suggest independently checkable identities for the finite spin-transfer qq' hard functions. In a helicity-conserving physical scheme, is LL transfer equal to UU pointwise for a massless same-flavor fermion line? Does this remain true in presence of virtual closed-fermion loops/real radiation at NLO? For transverse transfer expect nonzero. Warn about normalization of spin projectors and incoming/outgoing crossing, provide primary references if possible. Keep review focused on mathematical blockers and tests, not generic checklists.


## Response

The extension is correct, including the proposed finite helicity restoration on the polarized FF leg—provided it defines the conventional helicity-conserving scheme rather than poles-only BMHV subtraction. The strongest independent test is that the finite longitudinal-transfer ud→uX hard function equals UU, including its delta, plus, and regular coefficients. Transverse transfer is nonzero and requires a genuinely different hard function.

1. The polarized-FF finite term is supported directly

Stratmann–Vogelsang explicitly find, for the time-like quark-to-quark splitting,

ΔP
qq
time,(0)
	​

(ξ,ϵ)−P
qq
time,(0)
	​

(ξ,ϵ)=4C
F
	​

ϵ(1−ξ),

the same BMHV helicity defect as in the space-like case. Their discussion following Eq. (47) prescribes removing this defect in polarized final-state factorization. Thus using the same restoring kernel on the incoming helicity quark and the observed helicity quark is justified—not an analogy inferred from your previous incoming–incoming calculation. 
arxiv.org

In your convention, where the contribution added to the hard function is

2π
α
s
	​

	​

L
ℓ
	​

[
ϵ
S
ϵ
	​

	​

(
μ
ℓ
2
	​

μ
R
2
	​

	​

)
ϵ
P
ℓ
	​

−Z
ℓ
	​

]B
D
	​

,

the selection

Z
qq
L,PDF
	​

(ξ)=Z
qq
L,FF
	​

(ξ)=−4C
F
	​

(1−ξ)
	​


adds the finite term +4C
F
	​

(1−ξ) on each polarized quark leg. De Florian–Sassot’s polarized-target/polarized-final-state formula explicitly contains separate initial- and final-state finite subtractions with this sign convention; see their Eqs. (14), (39), and (40). 
arXiv

The implementation-level fixture is the elementary final-state splitting q
∗
→qg with your actual polarized FF projector. Extract its polarized-minus-unpolarized kernel through O(ϵ) and require the displayed 4C
F
	​

ϵ(1−ξ). This fixes the conversion independently of the completed ud result and detects an outgoing-projector normalization error.

Keep the ξ
−2+2ϵ
 FF weight separately and intact. Its finite logarithms are not another helicity-restoring kernel. Also, this is a helicity restoration: do not automatically apply it to h
1
	​

/H
1
	​

. Any finite transversity convention change needs its own definition.

2. Longitudinal transfer equals UU for this channel at NLO

For fixed helicities and colors of all other particles, a massless vector-QCD fermion line obeys

M
λ
c
	​

,λ
a
	​

	​

=δ
λ
c
	​

λ
a
	​

	​

A
λ
a
	​

	​

,

when c is the continuation of incoming quark a. The underlying fact is chirality conservation on the connected quark line. 
arXiv

The helicity-transfer weight is λ
a
	​

λ
c
	​

. On every nonzero amplitude it equals +1, so the helicity-weighted sum equals the unpolarized sum, with the same initial averages and final-state sums. The same argument applies to the virtual/Born interference.

There is no NLO exception from real radiation or closed fermion loops. In ud→udg, the outgoing u is still uniquely connected to the incoming u. Gluon emission preserves that line’s chirality. A closed fermion loop in a virtual correction does not insert a chirality-changing interaction on the open u line; no axial-current insertion into that closed loop is involved.

Therefore, after the BMHV artifacts are removed consistently on both polarized legs,

H
LU;L
(0)
	​

=H
UU;U
(0)
	​

,H
LU;L
(1)
	​

=H
UU;U
(1)
	​

	​


for this observed-flavor channel, in matching helicity-conserving and unpolarized schemes. In your common result format, compare the complete finite delta coefficient, every plus coefficient, and the regular coefficient. The equality also covers the independent scale logarithms and the n
f
	​

-dependent terms.

This is not an equality of raw D-dimensional Born expressions or their positive epsilon coefficients: BMHV is precisely why such intermediate expressions can differ and still produce finite remnants. Keep the generated polarized B
D
	​

 through its required orders. 
arxiv.org

Nor is the identity invariant under arbitrary additional finite factorization changes. An extra kernel shifts the hard function by the corresponding Born convolution. Use the equality as a test of the declared physical scheme, not as a replacement rule or a way to choose fitted corrections. It is also an equality of partonic hard coefficients, not of the hadronic convolutions with g
1
	​

,G
1
	​

 and f
1
	​

,D
1
	​

.

3. The qg dependency changes polarization—and remains necessary for transverse transfer

For beam B, use the unpolarized splitting

P
g←d
U
	​

(ξ)=C
F
	​

ξ
1+(1−ξ)
2
	​

,

not the previous helicity kernel ΔP
g←d
	​

=C
F
	​

(2−ξ). The distinction between these space-like kernels is explicit in the splitting-function conventions used by Stratmann–Vogelsang. 
arXiv

The required reduced Born process is consequently

u
L
	​

g
U
	​

→u
L
	​

goru
T
	​

g
U
	​

→u
T
	​

g,

not the old double-incoming-helicity u
L
	​

g
L
	​

→ug Born.

The transverse-transfer calculation still needs this qg Born. There is no gluon transversity here: the gluon belongs to unpolarized beam B. The absence of gluon transversity only removes mixing on the transversity legs themselves. 
arXiv

For the two polarized quark legs, the four-dimensional LO kernels satisfy

P
qq
L,(0)
	​

=P
qq
U,(0)
	​

,P
qq
T,(0)
	​

=P
qq
U,(0)
	​

−C
F
	​

(1−ξ).

Equivalently, with D
0
	​

(ξ)=[1/(1−ξ)]
+
	​

,

P
qq
T,(0)
	​

=C
F
	​

[2D
0
	​

(ξ)−2+
2
3
	​

δ(1−ξ)].

These diagonal LO kernels agree between space-like and time-like evolution; that equality should not be extrapolated to the NLO evolution kernels. 
arXiv

Your absence of an off-diagonal observed-parent channel is correct for the standard LO kernels plus diagonal restoration: a gluon-parent subtraction would require a nonexistent two-body ud→gX Born. Preserve enumeration for custom finite flavor mixing rather than hardcoding that absence.

4. Transverse-transfer and projector tests

With both transverse spins along the same physical normal to the partonic scattering plane, the Born hard factors give

B
UU;U
(0)
	​

B
TU;T
(0)
	​

	​

=
s
2
+u
2
−2su
	​

	​


for both qq
′
→qq
′
, observed q, and qg→qg, observed q. Yuan’s Eq. (3) gives these hard factors and explicitly identifies them with transverse-spin-transfer hard factors. At t=u=−s/2, the ratio is +4/5, while longitudinal transfer gives +1. 
arXiv

This is different from the incoming–incoming distinct-flavor TT zero: the transfer process places both chiral-odd insertions on the same fermion line. No process-name zero rule may survive into this calculation.

Define the outgoing transverse axis explicitly. Do not reuse the incoming–incoming cos2ϕ projection; transfer involves the relation between an incoming spin axis and an axis transverse to the outgoing quark. The normal/in-plane conventions are spelled out in de Florian–Soffer–Stratmann–Vogelsang, Eqs. (9)–(13). 
arXiv

To fix incoming/outgoing signs and factors before integration, require the standard tree-level partonic normalization

D
1
q/q
	​

(z)=G
1
q/q
	​

(z)=H
1
q/q
	​

(z)=δ(1−z),

with aligned physical spin states. This checks the FF projector independently of a hadronic hard-function comparison. In particular, do not add a second final-spin average, or interchange γ
5
	​

\slashedp and \slashedpγ
5
	​

 without the corresponding sign. Here H
1
	​

 is the collinear transverse-spin FF, not the Collins function H
1
⊥
	​

.

For the finite NLO transverse-transfer result, two useful independent constraints are:

The leading endpoint logarithm must satisfy

Coeff
[ln(1−w)/(1−w)]
+
	​

	​

H
TU;T
(1)
	​

=
π
α
s
	​

	​

5C
F
	​

B
TU;T
(0)
	​

,

where B
(0)
 is your physical Born delta coefficient, including its α
s
2
	​

. The leading soft factors are spin-independent; the identified-parton color combination is 2C
a
	​

+2C
b
	​

+2C
c
	​

−C
d
	​

=5C
F
	​

. 
arXiv
+1

Separately, each factorization-scale derivative must equal minus its LO-kernel convolution with the appropriate transfer Born, including the unpolarized beam-B qg contribution. This checks the new FF kernel and dependency polarization without constraining the result by a fit. These identities and pole cancellation do not determine the remaining finite TT regular function; that part must still come from the generated calculation.