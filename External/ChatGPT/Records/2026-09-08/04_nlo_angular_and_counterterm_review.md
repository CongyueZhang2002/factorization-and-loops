# NLO angular integrals, distribution pullbacks, and helicity normalization

Verified outgoing gpt-6-pro, HTTP 200, requestMessageId f129be6c-6956-47d3-96bb-f502e8d43452. Conversation https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4.

## Prompt

Follow-up implementation review. Please check the concrete universal ingredients, focusing on errors rather than restating the plan. We generated all real/virtual pairs, six real master DEs, and UU/LL qg Born projectors through the framework. No literature coefficients are copied into production.

1. For a massless two-body phase space Q -> k1+k2 in D=4-2eps, define inverse propagators D_i=2 lambda_i p_i.k_(sigma_i), with p_i^2=0 and sigma_i selecting k1 or k2. Put A_i=lambda_i p_i.Q, rho0=Q^2 (p1.p2)/(2(p1.Q)(p2.Q)), rho=rho0 if same cut momentum, 1-rho0 otherwise. Proposed unit-power angular average is -(1-2eps)/(2eps A1 A2) * 2F1(1,1;1-eps;1-rho), multiplying the standard two-body phase-space volume. Coincident directions rho=0 are instead the single-direction power-two Beta moment. Please verify normalization, geometry and epsilon expansion needs; this is detected from arbitrary topology, not family names.

Euler transformation gives 2F1(1,1;1-eps;1-rho)=rho^(-1-eps) Y(1-rho), Y(z)=2F1(-eps,-eps;1-eps;z). To store genuinely solved epsilon coefficients, use d(Y,F)/dz=eps*(A0/z+A1/(z-1))*(Y,F), A0={{0,1},{0,1}}, A1={{0,0},{-1,1}}, boundary(1,0). Thus each finite order is an explicit short GPL word sum, with Y=1+eps^2 Li2(z)+... . Verify and suggest the best NLO finite-order/endpoint handling; no lazy recurrence in exported final coefficients.

2. The code derives incoming/FF collinear maps as previously advised. For a kernel [ln^k(1-xi)/(1-xi)]+ and selected xi=h(w), h(1)=1,h'>0, let A(w) be constraint Jacobian*D-dimensional measure weight*mapped Born b, r(w)=(1-h(w))/(1-w), Q1=A(1)/h'(1). The proposed output is delta coefficient Q1 ln(h'(1))^(k+1)/(k+1), plus coefficient at log power j: Q1 Binomial[k,j]ln(h'(1))^(k-j), and regular sum_j Binomial[k,j]*(A(w)/r(w)*ln(r(w))^(k-j)-Q1 ln(h'(1))^(k-j))*ln(1-w)^j/(1-w). Kernel coefficients multiply these. Three rational test functions of the nonlinear incoming-B map agree exactly with independent xi integrations. Please challenge the general formula.

3. Incoming gluon correlator after removing f_g/xi is transverse projector/(D-2) for U and +i epsilon^{mu nu k n}/(2 k.n) for helicity, where mu corresponds to Polarization[k,+I] in the amplitude, nu to -I in conjugate. Quark incoming helicity correlator is +lambda g1 gamma5 slash(P)/2. FeynCalc BMHV with its LC convention. The physical Born b multiplies delta(s+t+u) in E_c d sigma/d^(D-1)p_c: generated coefficient times xa xb zh^2/(PDFa PDFb FF) *1/(2s)*1/[2(2pi)^(D-1)]*incoming-color-average. Generated front end already contributes 2pi from the remaining recoil cut. Expected UU qg b at eps=0 is alpha_s^2/s*[(s^2+u^2)/t^2-CF/CA*(s^2+u^2)/(s u)]. Is this correct, and which independent LL qg Born/helicity fixture fixes the sign relative to Delta Pgq=CF(2-xi)?

4. Ordinary virtual families had omitted (pa+pb-pc)^2=0 after eliminating the unobserved recoil. We now derive and include that external scalar-product relation only when the eliminated momentum contains no loop momentum and all its external vectors occur in the topology. Real cut conditions are never treated as external on-shell equalities. Any subtlety to catch before ordinary one-loop evaluation?

Repository https://github.com/CongyueZhang2002/factorization-and-loops ; changes local. Please consult primary references if needed, and identify what remains uncertain. You are reviewing these supplied formulas, not claiming to have inspected inaccessible files.

## Response

Not entirely: item 3 has a relative helicity-sign error under the index order you specify. With the quark projector +γ
5
	​

\slashedP/2, FeynCalc’s trace convention, and μ on the incoming polarization in the amplitude, the gluon helicity tensor requires −iϵ
μνkn
/(2k⋅n), not +i. The angular formula and differential system are correct; the plus-pullback formula is also correct subject to the endpoint conditions below. FeynCalc documents both the polarization-conjugation ordering and tr(γ
μ
γ
ν
γ
ρ
γ
σ
γ
5
	​

)=−4iϵ
μνρσ
. 
FeynCalc
+1

1. Angular average: correct, but distinguish exact coincidence from an endpoint limit

In the rest frame of future-timelike Q,

D
i
	​

=A
i
	​

(1−e
i
	​

⋅n),

where selecting k
2
	​

 instead of k
1
	​

 reverses the effective direction e
i
	​

. Consequently,

ρ=
2
1−e
1
	​

⋅e
2
	​

	​


is precisely your ρ
0
	​

 for equal cut selections and 1−ρ
0
	​

 otherwise. Your unit-power average agrees with the massless two-denominator result in Somogyi, Eq. (49), after division by the angular volume. There is no missing factor of two in A
i
	​

=λ
i
	​

p
i
	​

⋅Q. 
arXiv

For the standard Lorentz-invariant measure, the integrated volume to multiply it by is

Φ
2
	​

(Q
2
)=
8π
(4π)
ϵ
	​

Γ(2−2ϵ)
Γ(1−ϵ)
	​

(Q
2
)
−ϵ
.

This includes neither an identical-particle symmetry factor nor an additional convention-dependent cut normalization. Integrating the differential two-body measure in Klasen et al., Eq. (3.5), gives this expression. 
arXiv

Two exact normalization fixtures follow directly from one-dimensional Beta integration:

⟨
D
1
	​

D
2
	​

1
	​

⟩
ρ=1
	​

=−
2ϵA
1
	​

A
2
	​

1−2ϵ
	​

,

and, for exactly coincident effective directions,

⟨
D
1
	​

D
2
	​

1
	​

⟩
ρ=0
	​

=
4A
1
	​

A
2
	​

B(1−ϵ,1−ϵ)
B(−1−ϵ,1−ϵ)
	​

=−
2(1+ϵ)A
1
	​

A
2
	​

1−2ϵ
	​

.

The second result is an analytically continued power-divergent moment. Its finite negative value near ϵ=0 is not a normalization error.

Do not use that coincident formula as the endpoint value of a noncoincident family approaching ρ=0. Taking the geometric limit after Laurent expansion is nonuniform. Exact coincidence should mean an identity on the topology’s relevant kinematic domain, not merely a relation holding at w=1.

Differential system and endpoint treatment

Your matrices are correct with

F(z)=
ϵ
z
	​

Y
′
(z).

Eliminating F gives

z(1−z)Y
′′
+[1−ϵ−(1−2ϵ)z]Y
′
−ϵ
2
Y=0,

the hypergeometric equation for the specified Y. Euler’s transformation is also correct. 
DLMF
+1

Specify the analytic solution at z=0, or the equivalent tangential GPL boundary. A numerical limiting value alone, without a branch condition, can admit an additional z
ϵ
 local mode for some regulator domains.

For G-functions defined with kernels dt/(t−a), a useful explicit expansion fixture is

Y(z)=1−ϵ
2
G(0,1;z)−ϵ
3
[G(0,0,1;z)+G(0,1,1;z)]+O(ϵ
4
).

Thus Y
(2)
=Li
2
	​

(z), as stated.

For endpoint extraction, a useful local ρ→0 decomposition, obtained from the hypergeometric connection formula, is

ρ
−1−ϵ
Y(1−ρ)=
C
ϵ
	​

=
	​

C
ϵ
	​

ρ
−1−ϵ
(1−ρ)
ϵ
+
1+ϵ
ϵ
	​

2
	​

F
1
	​

(1,1;2+ϵ;ρ),
Γ(1−ϵ)Γ(1+ϵ).
	​


It separates the regulated endpoint power from a term analytic in ρ near zero. Materialize the needed epsilon coefficients of both terms; do not discard the second term, which contributes finitely after multiplication by the angular 1/ϵ. 
DLMF

For finite NLO output, Y through ϵ
2
 suffices when the only order losses are the angular pole and one endpoint-moment pole. A truncation at Y=1 then misses finite dilogarithms. Additional structural coefficient poles require correspondingly deeper coefficients. Keep the combined endpoint powers unexpanded until distribution extraction.

The topology detector also needs Q
2
>0, nonzero A
i
	​

, and the actual two-body measure without angular cuts or extra angular weights. The signs of λ
i
	​

 belong in A
i
	​

; they should not independently reverse the normalized geometry.

2. Plus pullback: your formula is correct

There is no missing nonlinear-map contribution to the delta coefficient. The nonlinear dependence away from the endpoint is already in your regular term.

A direct proof uses an auxiliary regulator η, separate from dimensional ϵ:

A(w)(1−h(w))
−1+η
=A(w)r(w)
−1+η
(1−w)
−1+η
.

Writing d=h
′
(1), the delta term on the right is

η
Q
1
	​

d
η
	​

δ(1−w),Q
1
	​

=
d
A(1)
	​

.

Subtracting the pulled-back Q
1
	​

δ(1−w)/η, then comparing the coefficient of η
k
/k!, gives exactly

Q
1
	​

k+1
ln
k+1
d
	​

δ(1−w).

Expanding the remaining powers of ln[r(w)(1−w)] gives your plus and regular coefficients.

The missing guards are substantive:

Nondegenerate endpoint. Require

0<h
′
(1)<∞,

not merely h
′
(w)>0 in the open interval. The map

h(w)=1−(1−w)
2

is increasing for w<1, but has zero endpoint slope and does not satisfy your formula’s distributional assumptions.

Regular multiplier and correct support. For the stated output basis, require a sufficiently smooth finite A(w) at w=1, with the map taking the integration interval into [0,1]. A multiplier containing another (1−w)
−aϵ
 or an endpoint pole must be combined with the regulated kernel before expansion—not multiplied into an already extracted plus distribution. Different lower support limits require the corresponding distribution convention.

Kernel coefficients depending on ξ. Such coefficients must be included through

A(w)⟶A(w)c(h(w))

before computing Q
1
	​

 and the regular subtraction, or multiplied afterward using full distribution multiplication. “Kernel coefficients multiply these” is harmless only for coefficients constant in the convolution variable.

Your three tests are useful; the auxiliary-regulator identity establishes the formula for general k, rather than only those test functions.

3. Born normalization is right; the mixed quark–gluon helicity sign is not
Polarization tensors

The unpolarized factor is correct when “transverse projector” means the physical polarization sum

d
μν
(k,n)=−g
D
μν
	​

+
k⋅n
k
μ
n
ν
+n
μ
k
ν
	​

−
(k⋅n)
2
n
2
k
μ
k
ν
	​

.

The last term vanishes for null n. Divide this by D−2, but do not apply an additional gluon spin average afterward.

For your stated ordering, the helicity replacement is

Δρ
g
μν
	​

=−
2k⋅n
i
ϵ
ˉ
μναβ
k
α
	​

n
β
	​

	​

.
	​


Its denominator remains 2, not D−2. The Levi-Civita tensor is four-dimensional in BMHV. Swapping amplitude/conjugate indices, or swapping k,n, reverses this sign. Also, FeynCalc’s I and -I polarization flags encode conjugation/incoming–outgoing usage, not positive and negative helicity. 
FeynCalc
+1

I checked the relative sign with an explicit four-dimensional gamma-matrix contraction of the two Abelian Compton diagrams, using the documented FeynCalc trace convention. At

p
a
	​

=(1,0,0,1),p
b
	​

=(1,0,0,−1),p
c
	​

=(1,1,0,0),

so that (s,t,u)=(4,−2,−2), your proposed pair of projectors gives

∣M∣
UU
2
	​

/e
4
=5,∣M∣
LL
2
	​

/e
4
=−3.

Changing the gluon tensor to the boxed sign gives +3. This is a small projector fixture, independent of the real-master integration.

Physical Born density

If the stripped generated quantity is the appropriately spin-weighted and color-averaged amplitude square, your phase-space factors give

b
D
	​

=
2s
∣M∣
2
	​

	​

2(2π)
D−1
2π
	​

=
4s(2π)
D−2
∣M∣
2
	​

	​

.

Hence at D=4,

b
4
	​

=
16π
2
s
∣M∣
2
	​

	​

,

and your expected UU qg formula is correct. The averaged qg amplitude follows from Eq. (3.11) and the crossing/averaging entry in Table 3 of Klasen et al. 
arXiv
+1

The independent LL fixture is

b
LL
qg→qg
	​

=
s
α
s
2
	​

	​

[
t
2
s
2
−u
2
	​

−
C
A
	​

C
F
	​

	​

su
s
2
−u
2
	​

],
	​


or equivalently

b
UU
	​

b
LL
	​

	​

=
s
2
+u
2
s
2
−u
2
	​

.

This relation holds even at the color-connected Born-matrix level in de Florian–Vogelsang–Wagner, Eq. (B.8). At t=u=−s/2, the ratio must be +3/5. Do not extend this four-dimensional ratio to the epsilon-dependent Born terms without a separate derivation. 
arXiv

To anchor the same convention directly to the incoming counterterm, generate the quark-to-gluon helicity splitting fixture and require

ΔP
g←q
	​

(ξ)=C
F
	​

(2−ξ),

with the outgoing polarization’s conjugation order treated consistently. This is Vogelsang’s Eq. (30). A finite BMHV restoration cannot repair a wrong Born-level relative sign. 
arXiv

What remains uncertain here is the x
a
	​

x
b
	​

z
h
2
	​

 stripping factor, because its correctness depends on the precise front-end correlator normalization. In particular, z
h
2
	​

 may undo a declared correlator prefactor, but it must not be used to undo a D-dimensional invariant-density Jacobian z
h
−(D−2)
	​

. Likewise, ensure the FF insertion has not left an unintended final-spin average. The universal flux/recoil-cut multiplier above is independently fixed.

4. Recoil on-shell relation: correct, with three boundaries to protect

Its source must be a declared on-shell external leg. Loop-freeness and vector membership are eligibility conditions, not themselves a proof that a momentum combination is massless. Once that origin is established, your virtual recoil relation is legitimate.

Apply it before classifying/evaluating the scalar integrals, but not inside the support delta. For example, a massless bubble with recoil invariant q
2
=0 is scaleless; substituting q
2
=0 into an already Laurent-expanded off-shell bubble instead produces meaningless divergent logarithms. Any earlier off-shell reduction must therefore be reconsidered under the corrected kinematics. If UV and IR poles are separately tracked, preserve their bookkeeping rather than interpreting a scaleless zero as absence of either divergence. FeynCalc explicitly distinguishes these uses. 
FeynCalc

The virtual density still has the form

b(s,t)δ(s+t+u).

Use s+t+u=0 in the coefficient and integral arguments; do not globally rewrite the distribution to δ(0). Its conversion remains

δ(s+t+u)=
sv
1
	​

δ(1−w).

Keep causal continuation and scalar-integral normalization intact. The physical region has s>0, t,u<0; ln(−s−i0)=lns−iπ, and premature removal of phases can lose finite terms when double poles are present. Also check whether the one-loop backend removes r
Γ
	​

: Ellis–Zanderighi’s scalar-integral definitions do, whereas your stated d
D
k/(iπ
D/2
) normalization does not. These are normalization/continuation issues independent of the newly restored on-shell relation. 
arXiv