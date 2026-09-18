# Bare fragmentation normalization and the generated hard coefficients

17 September 2026. Derivation and code audit; production coefficients unchanged.
The accompanying independent checks are
[Tests/Physics/test_fragmentation_normalization.py](../Tests/Physics/test_fragmentation_normalization.py).
This document fixes a dimensional convention explicitly. A four-dimensional
operator formula alone cannot select its continuation.

## 1. Scope and conventions

We work at leading collinear twist with massless partonic kinematics, within
ordinary collinear factorization. Establishing the factorization theorem,
its Wilson-line Ward identities and its overlap subtractions is an input.
The derivation below concerns the normalization of the external collinear
insertion and its action on the hard side. It is not a proof that arbitrary
unsubtracted graph products factorize, or a TMD factorization derivation.

Let
\[
D=4-2\epsilon,\qquad m=D-2,\qquad
\ell^2=n^2=0,\quad \ell\cdot n=1,\quad
P=P^+\ell,\quad k=\frac{P}{z}.
\]
The observed momentum and physical spin axes lie in the four-dimensional
subspace. Unobserved momenta and loop integrations remain D-dimensional.
The regulated FF is the standard bare collinear number-density definition,
with the transverse integral in m dimensions. Wilson lines are future
pointing in the fragmentation matrix. Color averaging is included in its
scalar extraction; color contractions on the hard side remain explicit.

A physical external vector is not the same operation as integrating out
evanescent observed components. The raw object to be identified with the
code is the fixed-momentum amputated cut density, evaluated at physical k.
A genuinely different regulated density requires an explicit conversion.

## 2. Cut matrix, Fourier normalization, and scalar extraction

First retain its two color indices explicitly:
\[
\mathbb M^{ab}_{ij}(q,P)=\sum_X
 \int d^Dy\,e^{iq\cdot y}
 \langle0|(W\psi_i)^a(y)|P X\rangle
 \langle P X|(\bar\psi_j W)^b(0)|0\rangle .
\]
Define the Dirac-valued matrix \({\cal M}=\operatorname{tr}_c\mathbb M/N_c\).
For a color-singlet fragmentation correlator,
\(\mathbb M^{ab}=\delta^{ab}{\cal M}\), and hence
\[
\operatorname{Tr}_{D,c}[\mathbb H\mathbb M]
=\operatorname{Tr}_D[(\operatorname{tr}_c\mathbb H){\cal M}].
\]
Below \({\cal H}=\operatorname{tr}_c\mathbb H\). This is an outgoing
color sum. The factor \(1/N_c\) divides a color trace, not a still-open
matrix, and must not become another hard outgoing average. Incoming averages
remain separate. Path and Fourier-sign translations between operator
conventions do not alter the scalar Jacobian derived here.

At fixed \(q^+=P^+/z\), define
\[
C_q(z)=\int\frac{dq^-\,d^m q_\perp}{(2\pi)^D}{\cal M}(q,P).
\]
Performing those Fourier integrals sets \(y^+=y_\perp=0\). There are D-1
integrated components, so one factor \(1/(2\pi)\) remains:
\[
C_q(z)=\frac1{N_c}\sum_X\int\frac{dy^-}{2\pi}
 e^{i(P^+/z)y^-}
 \langle0|W\psi(y^-n)|P X\rangle
 \langle P X|\bar\psi(0)W|0\rangle.
\]
Thus a leading-power hard contraction with measure \(d^Dq/(2\pi)^D\)
reduces to \(dq^+\operatorname{Tr}[{\cal H}(q^+\ell)C_q]\), with no
additional \(2\pi\) or \(P^+\) factor. There is no extra
\(dq^+/(2q^+)\): the active field is amputated, rather than integrated as
another outgoing on-shell particle.

The standard bare unpolarized extraction is
\[
D_{1,B}(z)=\frac{z^{D-3}}4
 \operatorname{Tr}[\not n\,C_q(z)].
\tag{1}
\]
Collins--Rogers, [2309.03346 Eq. (2)](https://arxiv.org/pdf/2309.03346),
states the transverse dimension and the power \(z^{1-2\epsilon}\)
explicitly. Zhongbo's older four-dimensional note gives the corresponding
\(z/4\) extraction. Its continuation follows after declaring
\(d^m p_\perp=z^m d^m q_\perp\), combined with the longitudinal \(1/z\).
This concerns a bare integral, not an integral of an arbitrary renormalized,
soft-subtracted TMD.

The leading unpolarized component obtained by inverting (1) is
\[
C_q(z)=z^{3-D}\not\ell D_{1,B}(z)
      =\frac{z^{4-D}}{P^+}\not k D_{1,B}(z).
\tag{2}
\]
The familiar stripped decomposition may remain
\[
\Delta_{\rm strip}(z)=\tfrac12\not\ell D_{1,B}(z),
\qquad C_q=2z^{3-D}\Delta_{\rm strip}.
\tag{3}
\]
Keeping (3) recognizable does not redefine the named scalar FF.

For a free tagged quark the full cut matrix is
\({\cal M}_{\rm free}=(2\pi)^D\delta^D(q-P)\not P\), with its outgoing
spin/color summed in the convention above. This provides a separate
constant-factor check:
\(C_q=\not P\,\delta(P^+/z-P^+)=\not\ell\,\delta(1-z)\).
Equation (1) returns \(\delta(1-z)\). This fixes tree normalization but,
by itself, is blind to a factor \(z^{c\epsilon}\); nontrivial-fraction
checks are required as well.

## 3. The factor follows from the cut contraction

The change of variables gives
\[
|dq^+|=\frac{P^+}{z^2}\,dz.
\]
Combining it with (2) yields the central identity
\[
\begin{split}
\int dq^+\operatorname{Tr}[{\cal H}(q^+\ell)C_q(z)]
 &=
\int_0^1 dz\,z^{-(D-2)} D_{1,B}(z)
       H_{\rm raw}(P/z),\\
H_{\rm raw}(k)&=\operatorname{Tr}[{\cal H}(k)\not k].
\end{split}
\tag{4}
\]
Physical support can equivalently be included in \(H_{\rm raw}\).
The two factors with different origins are
\[
\underbrace{\frac{dz}{z^2}}_{\text{longitudinal change of variables}}
\quad
\underbrace{z^{4-D}}_{\text{scalar extraction relative to }\not k}.
\]
Their product is \(dz/z^{2-2\epsilon}\).

**No observed momentum integration was used in (4).** Holding the observed
momentum physical and fixed does not remove this normalization. It does not
insert a measurement delta for that momentum either: the existing fixed-tag
calculation is the hard tensor on the right.

This is an identity for the chosen dimensionally completed operator and
amputated hard definition. A literal alternative finite-epsilon pairing
\(\int dz\,z^{-2}D_B(z)H(P/z)\), with no conversion factors, has a different
hard adjoint. One cannot substitute that alternative merely because the final
physical cross section is differential in \(d^3P\).

After renormalization and collinear subtraction, the finite physical result
uses its ordinary four-dimensional hadron convolution. Dimensional factors
must not be set to one in individual terms before their poles cancel.

## 4. Physical quark spin and gluon insertions

For a physical spin vector \(S\), with
\(S^2=-1,\ S\cdot k=S\cdot n=0\), use hard insertions
\[
Q_U=\not k,\qquad Q_L=\gamma_5\not k,\qquad
Q_T(S)=\gamma_5\not S\not k.
\]
Physical dual extractions are
\[
E_U[X]=\frac{\operatorname{Tr}[\not n X]}{4k\cdot n},\quad
E_L[X]=\frac{\operatorname{Tr}[\not n\gamma_5 X]}{4k\cdot n},\quad
E_T[X]=-\frac{\operatorname{Tr}[\not n\not S\gamma_5 X]}{4k\cdot n}.
\]
In the physical Clifford subspace they satisfy \(E_A[Q_B]=\delta_{AB}\),
including two orthogonal transverse directions. Consequently the scalar
normalization in (2)--(4) is common to ordinary twist-two quark spin
coefficients. It is not the additional momentum weighting of a Collins
transverse moment.

A definite transverse-spin state has density
\(\rho_\pm=(Q_U\pm Q_T)/2\); its sum/difference gives \(Q_U,Q_T\).
Neither the outgoing spin sum nor the spin analyzer receives another 1/2.

This algebra does not choose a polarized finite factorization scheme or
discard evanescent operators. Physical BMHV projectors, the specified tensor
light-ray operator, and the corresponding renormalization kernel must be
kept consistent. No anticommutation of gamma5 through hatted matrices was used.

For gluons, the field-strength correlator convention in
[2503.16119 Eq. (A14)](https://arxiv.org/pdf/2503.16119#page=43) is
\[
\Delta_F^{\mu\nu}(z)
=-z^{-2+2\epsilon}g_\perp^{\mu\nu}D_{g,B}(z).
\]
Here the light-ray direction is \(m_0=n/P^+\), so \(m_0\cdot P=1\).
In a compatible light-cone gauge, at the leading-twist attachment,
each \(F^{m_0\mu}\) supplies \(q^+/P^+=1/z\) relative to a transverse
gauge field. The two cut factors give \(1/z^2\); their Fourier phases
cancel. Changing the dimensionless light-ray coordinate to \(y^-\)
gives the factor \(P^+\). Thus
\[
\Delta_F^{\mu\nu}=\frac{P^+}{z^2}C_A^{\mu\nu},
\qquad
C_A^{\mu\nu}
=-\frac{z^{2\epsilon}}{P^+}g_\perp^{\mu\nu}D_{g,B}.
\]
Multiplication by \(dq^+\) produces the same \(dz/z^{2-2\epsilon}\)
weight times the hard polarization sum. The same bare fields, future-link
and residual-gauge prescription must be used on both sides; this is not a
rule for discarding residual gauge links.

The extraction
\[
D_{g,B}=-\frac{z^{2-2\epsilon}}{D-2}
 g_{\perp\mu\nu}\Delta_F^{\mu\nu}
\]
contains a scalar-extraction average, not an extra average of the outgoing
hard polarization sum. Incoming gluon averages and physical versus
D-dimensional gluon spin prescriptions must be specified separately.
This derivation specifically yields a D-2 polarization sum, as used by the
current unpolarized gluon insertion. A hard tensor computed with only two
gluon polarization states would require a separate tensor/scheme comparison.
The quark/gluon difference in the integer correlator power is therefore
not an extra difference in the final hard-density convolution weight.

## 5. Scalar renormalization induces the hard action

Fix flavor conventions by taking FFs as a column:
\[
D_{i,B}(z)=\sum_j\int_z^1\frac{d\xi}{\xi}
 Z_{ij}(\xi,\epsilon)D_{j,R}(z/\xi).
\tag{5}
\]
Insert (5) in (4), set \(z=y\xi\), and exchange the integrals in a
convergence domain before meromorphic continuation. The result is
\[
({\cal T}_Z H)_j(k)=
\sum_i\int_0^1d\xi\,\xi^{-(D-2)}
 Z_{ij}(\xi,\epsilon)H_i(k/\xi).
\tag{6}
\]
This derives the hard weight from the scalar operator replacement.
It agrees with the regulated counterterm in
[Catani--Seymour Eq. (6.17)](https://arxiv.org/pdf/hep-ph/9605323#page=51).

For a general declared pairing with weight \(W_\epsilon(z,P)\),
the ratio in the hard action is
\(W_\epsilon(y\xi,P)/W_\epsilon(y,P)\).
It need not be a monomial or independent of y. If the stored hard coefficient
strips \(H=N_\epsilon h\), its action also contains
\(N_\epsilon(k/\xi)/N_\epsilon(k)\).
Observable integration and coordinate changes act on this full expression,
including support and delta/plus distributions.

With the flavor-column convention in (5), the adjoint reverses composition:
\[
{\cal T}_B{\cal T}_A={\cal T}_{A\otimes B}.
\tag{7}
\]
Matrix ordering must be retained for mixing. For different external legs,
the insertions act on their separate flavor indices and momentum arguments.

For a no-flux incoming quark current, the standard forward matrix is
\(C_{\rm in}(x)=\not\ell f_B(x)/2\). Since \(dq^+=P^+dx\) and
\(p=xP\), sewing gives \(dx\,f_B(x)\not p/(2x)\).
The incoming current action is therefore \(d\xi/\xi\) with \(p\to\xi p\).
Putting the partonic flux inside the hard coefficient supplies its own
rescaling ratio. For two incoming massless partons it converts the current
pairing into the familiar \(dx_a\,dx_b\) cross-section pairing.
This explains why the incoming weight of a flux-normalized scattering
coefficient and a no-flux current need not be identical.

## 6. Independent fixed-tag real-collinear derivation

Let an unobserved massless parton r become collinear to physical observed k.
With \(\xi\) the daughter/parent longitudinal fraction,
\[
r^+=\frac{1-\xi}{\xi}k^+,\qquad
r^-=\frac{{\bf r}_\perp^2}{2r^+},\qquad
s_{kr}=\frac{\xi}{1-\xi}{\bf r}_\perp^2.
\]
The exact one-particle cut measure is
\[
d\Pi_D(r)=
\frac{d\xi\,d^m{\bf r}_\perp}
 {2(2\pi)^{D-1}\xi(1-\xi)}.
\]
Combining it with the usual final-collinear amplitude factor
\(2g_s^2P(\xi,\epsilon)/s_{kr}\) gives
\[
\frac{g_s^2}{(2\pi)^{D-1}}\frac{d\xi}{\xi^2}
 P(\xi,\epsilon)
 \frac{d^m{\bf r}_\perp}{{\bf r}_\perp^2}
 B(k/\xi).
\]
The transverse variable relative to the parent is
\({\bf l}_\perp=-\xi{\bf r}_\perp\). Hence
\[
\frac{d^m{\bf r}_\perp}{{\bf r}_\perp^2}
=\xi^{2-m}
 \frac{d^m{\bf l}_\perp}{{\bf l}_\perp^2}
=\xi^{2\epsilon}
 \frac{d^m{\bf l}_\perp}{{\bf l}_\perp^2}.
\tag{8}
\]
This independently reproduces the scalar Jacobian in (6), with k never
integrated. It does not by itself fix the entire finite subtraction:
the operator definition is required as well. A transverse cutoff or test
function must be transformed too. For example, \(s_{kr}<\Lambda^2\) gives
\[
{\bf r}_\perp^2<\frac{1-\xi}{\xi}\Lambda^2,
\qquad {\bf l}_\perp^2<\xi(1-\xi)\Lambda^2,
\]
and the two integrated weights agree exactly:
\[
\xi^{-2}\left[\frac{1-\xi}{\xi}\Lambda^2\right]^{-\epsilon}
=\xi^{-2+2\epsilon}[\xi(1-\xi)\Lambda^2]^{-\epsilon}.
\]
Spin vectors must be transported consistently under this reparametrization;
do not impose a fresh physical projection in the transformed frame.
For polarized channels retain the splitting matrix or its declared projected
angular average.
The D-dimensional real splitting expression is not the same object as
the scalar minimal-subtraction kernel; its epsilon numerator terms remain
part of the raw real calculation.

With \(g_{s,0}^2=4\pi\alpha_s\mu^{2\epsilon}\), azimuthal integration
and \(t={\bf l}_\perp^2\) give the full scalar radial normalization
\[
dH_{R,\mathrm{coll}}=
\frac{\alpha_s}{2\pi}\frac{(4\pi\mu^2)^\epsilon}{\Gamma(1-\epsilon)}
d\xi\,\xi^{-2+2\epsilon}P(\xi,\epsilon)B(k/\xi)
\,dt\,t^{-1-\epsilon}.
\]
For \(\mathrm{Re}\,\epsilon<0\), the radial integral to T is
\(-T^{-\epsilon}/\epsilon\). This fixes the negative raw collinear pole
relative to the positive added counterterm in the conventions of (10).
Other bare-coupling conventions multiply this equation by their declared
factor; the exact convention is discussed below.

For a convergent check, take \(\epsilon<0\) and a smooth ultraviolet
test factor \(\exp[-{\bf l}_\perp^2/\Lambda^2]\).
Numerically integrating separately in the two transverse frames reproduces
(8); omitting the factor fails at nontrivial fractions.

## 7. Why this applies to Born, real and virtual

The external contraction (4) is linear and independent of hard topology.
For every cut contribution \(I=B,R,V,\ldots\), define
\[
H_I(k)=
\sum_{X_I}\int d\Phi_{X_I}^{(D)}(Q-k)\,
 \operatorname{Tr}[{\cal H}_I(k,X_I)Q(k)],
\]
with loop measures where applicable, common incoming normalization and
identical-particle factors. This is a raw partonic density. Collinear
subtraction and overlap/matching definitions must remain consistent;
an infrared-finite Wilson coefficient is not obtained just by this contraction.

The normalized measures are
\[
d\Phi_N^{(D)}(Q-k)=
(2\pi)^D\delta^D(Q-k-\sum r_i)
 \prod_i\frac{d^Dr_i}{(2\pi)^{D-1}}\delta_+(r_i^2).
\tag{9}
\]
After eliminating one momentum their common factor is
\((2\pi)^{N-(N-1)D}\).
For one recoil it is exactly \(2\pi\delta_+((Q-k)^2)\),
independent of D. For two it is the dimensional two-body cut measure.
A virtual correction has the same observed/recoil normalization as Born,
with its additional loop integration.

The direct partonic external insertion is the identity FF distribution
\(\delta(1-\xi)\). Its scalar weight is unity. This does not say that
the interacting FF has no renormalization. A product of the complete
unsubtracted partonic tensor with a complete perturbative FF would double
count collinear regions. Ordinary on-shell matching in pure dimensional
regularization uses scaleless bare integrated partonic FF corrections,
with UV/IR separation retained in the renormalization kernel. A different
regulator requires the corresponding nontrivial partonic matching functions.
Nontrivial fractions arise when the operator is renormalized, or when
lower-order sources are convolved.

Writing \(Z=1+aZ_1+a^2Z_2+\cdots\), with a positive bare-to-renormalized
one-loop kernel, gives for one FF leg
\[
H_{{\rm ren},1}=H_{{\rm raw},1}+{\cal T}_{Z_1}B,
\]
\[
H_{{\rm ren},2}=H_{{\rm raw},2}
 +{\cal T}_{Z_1}H_{{\rm raw},1}+{\cal T}_{Z_2}B.
\tag{10}
\]
UV renormalization must be consistently included in the source expansion;
incoming legs add their own terms and products. The NLO source in (10)
is the appropriate un-factorized lower-order source, not an already finite
NLO hard function reused without undoing its subtraction.
If a finite NLO source were used instead, its Born correction would be
\((\mathcal T_{Z_2}-\mathcal T_{Z_1}\mathcal T_{Z_1})B\).
Adding a separate same-leg \(Z_1^2\) to (10) would double count.

Thus the specific NLO FF action multiplies Born, while its NNLO version
also multiplies real/virtual NLO sources. This does not exempt real/virtual
from a genuine change of density normalization.

If \(H'_I=R_\epsilon H_I\), then
\[
{\cal T}'_Z=R_\epsilon{\cal T}_ZR_\epsilon^{-1}.
\]
All Born, real, virtual and counterterm terms change together. For
\(R_\epsilon=1+\epsilon r_1+\epsilon^2r_2+\cdots\), a raw term with
coefficients \(h_{-2},h_{-1},h_0\) has new finite coefficient
\(h_0+r_1h_{-1}+r_2h_{-2}\).
A scalar redefinition \(D'_B=z^{c\epsilon}D_B\) is a different operation
and can induce a finite scheme change upon minimal subtraction.
Invariance of the final physical limit under \(R_\epsilon\to1\) requires
a valid multiplier on the distribution space, not just pointwise convergence
at singular endpoints.

## 8. Connection to the actual production paths

| Definition | Active implementation | Normalization found |
|---|---|---|
| Outgoing quark spin contraction | Physics/Distributions.wl, PartonicSpinDensity | slash k; physical gamma5 slash S slash k for T; no outgoing color/spin average |
| Common current integrand | Coefficients/CurrentContributions.wl, ConstructCurrentIntegrands | Generated amputated interferences contracted with those densities |
| Fixed-tag Born | Physics/Born.wl, currentBornSupport and ConstructFixedObservedBornResult | 2 pi times the recoil-delta Jacobian; observed measure omitted |
| Fixed-tag virtual | Coefficients/CurrentContributions.wl, ConstructFixedObservedVirtualContribution | The same currentBornSupport; dimensional one-loop scalar functions; conjugate included |
| Fixed-tag real | Projects/FixedObservedCurrents.wl and Integrals/CutFamilies.wl | Ambient D cuts, total momentum Q-k; factor (2 pi)^[N-(N-1)D] |
| Real angular evaluation | Integrals/Evaluations/AngularIntegrals.wl | Physical cut prefactor restored; CurrentNormalization, symmetry/flavor and coupling factors |
| ppHX Born/real/virtual | Normalization/PhaseSpace.wl (called by Physics/Born.wl and Coefficients/NLO.wl) | Shared PartonicInvariantDensityNormalization; flux1/(2s), observed factor1/[2(2pi)^(D-1)] |
| Counterterm source stage | Projects/BareSources.wl | Raw subtraction versus finite scheme transformation are distinct source stages |

In the inspected high-pT card, CurrentNormalization=1 and the observed
measure is omitted. The real and virtual paths contain no separate
observed transverse-density conversion. Their genuine loop/unobserved
phase-space powers remain part of the raw calculation. These match the
hard side in (4), with physical projectors, rather than a coefficient
rescaled by an additional arbitrary \(R_\epsilon(k)\).

The card's phrase "per physical observed d^3 k/((2 pi)^3 2 E_k)" must be
understood together with this regulated cut definition. As a statement about
the finite physical tensor it is appropriate; alone it is not the full
finite-epsilon normalization. A future schema should store the cut
definition and scalar extraction explicitly, not infer either from that label.

The existing \(d\xi/\xi^{2-2\epsilon}\) action is therefore the action to
reproduce from the shared definitions. This derivation calls for no extra
multiplication of the current raw Born/real/virtual coefficients.
It does not certify unrelated numerical errors or a different code's
complete FF/FJF matching convention.


### Fixed-current recoil Jacobians and physical spin frame

The high-pT card uses \(S=2p\cdot q,\ x=Q^2/S\) and
\[
W=(p+q-k)^2=S(1-x)(1-z)(1-w).
\]
For outgoing rescaling, \(\xi_*=z+(1-z)w=1-W/s\),
\(s=(p+q)^2=S(1-x)\).
The direct recoil constraint after rescaling is
\(W'(\xi)=s-(s-W)/\xi\), so its delta Jacobian is \(\xi_*/s\).
The card instead maps \(z'=z/\xi,\ w'=(1-z)w/(\xi-z)\).
Combining the mapped Born Jacobian
\(1/[S(1-x)(1-z/\xi_*)]\) with the delta in \(1-w'\)
gives exactly the same \(\xi_*/s\). The incoming map likewise reproduces
\(1/[S(1-z)]\). These checks retain the full Born normalization;
neither supplies a second copy of the fragmentation weight.

The spin frame normalizes the observed direction by its energy in a fixed
timelike frame. That unit direction, its scattering-plane axes and the
physical photon projectors are invariant under positive \(k\to k/\xi\).
The existing outgoing spin insertion already has its degree-one dependence
on k. The convolution must not multiply by another spin-homogeneity factor.

### Exact coupling convention and higher-order kernel availability

The normalization above does not replace the coupling convention.
Physics/CollinearRenormalization.wl defines the exact reference
\(S_\epsilon=\exp[\epsilon(\log4\pi-\gamma_E)]\).
For a supplied bare-coupling factor \(C_\epsilon\), its pole normalization
is \(S_\epsilon C_\epsilon\). The current high-pT card supplies its inverse,
so that pole normalization is exactly one.
Replacing \(S_\epsilon\) by \((4\pi)^\epsilon/\Gamma(1-\epsilon)\)
without accounting for their order-\(\epsilon^2\) difference is not
permitted under a double pole.

The NNLO identities here establish normalization and composition, not a
new two-loop polarized splitting function. The current kernel provider
explicitly refuses order-two time-like L/T requests; this derivation does
not remove that existing physics-input restriction.

## 9. Inexpensive verification and limits

The independent Python checks use SymPy exact algebra and mpmath integration:
physical U/L/T duality at a non-axis-aligned rational momentum;
longitudinal quark/gluon factors; unobserved 2pi powers; nontrivial
Mellin-monomial pairings and an incorrect-weight control; convergent
transverse-frame integrals; flavor order; NNLO kernel conjugation and
evanescent-times-pole terms; density-induced finite shifts.

They are not a new production rerun, a complete polarized splitting-kernel
derivation, or a test of a hadronic observable with arbitrary acceptance.
The actual scalar kernel scheme and evanescent-operator basis remain
independent physics inputs.

GPT-6 Pro independently reviewed the complete derivation in
[the convention-review conversation](https://chatgpt.com/c/6aac97de-ae14-83e8-b452-b6ebcfecd366).
It accepted the quark operator-to-fixed-density identity and the conclusion
that the stated raw Born/real/virtual tensors need no new scalar factor.
The review's qualifications on explicit color contraction, gluon polarization
space, transformed bounds/spin vectors, and external normalization versus
matching are incorporated above. The retained prompt and review are in
[record 06](../External/ChatGPT/Records/2026-09-17/06_fragmentation_operator_derivation.md).
The shared automatic normalization implementation remains future work;
this derivation and its independent checks changed no production coefficient.
