# Manuscript 02 Factorization

## Question

The attached file is the current complete draft of Section 2 after the
calculation-first reorganization. Review and rewrite this section only.

Return:
1. A concise list of exact notation, normalization, factorization, or
   polarization problems.
2. Compilable replacement LaTeX for the attached section only.

Check especially:
- the invariant single-inclusive observable;
- the relation between hadronic and partonic invariants;
- the declared factor 1/(x_a x_b z_h^2) and what remains in the Jacobian;
- the perturbative normalization of the hard functions;
- quark versus antiquark signs in the leading-twist PDF and fragmentation
  correlators;
- separation of hadronic transverse spins from partonic momenta;
- the definition of UU, LL, and TT scalar coefficients;
- independence of the extracted hard coefficient from x_a, x_b, z_h and
  auxiliary hadronic vectors;
- preservation of exact endpoint powers before the epsilon expansion;
- the delta and plus-distribution identity.

Do not invent a normalization absent from the available source context. State
any unresolved convention precisely. Do not claim a complete NLO or NNLO hard
function. Keep the argument at standard QCD-paper level, not as software
documentation. Do not rewrite another section in this turn.

## Pro response

1. Notation and normalization problems

The residual Jacobian is not defined precisely enough. Equation \eqref{eq:factorized-cross-section} displays 1/(x
a
	​

x
b
	​

z
h
2
	​

), while the prose says that J
h
	​

 contains “the remaining Jacobian,” but it never defines the full measure whose factorization produces these two pieces. The claim of direct equivalence to the normalization of Ref.~\cite{Aversa:1988vb} is consequently stronger than the displayed equations establish. The replacement defines

\ddΞ
h
	​

=\ddx
a
	​

\ddx
b
	​

\ddz
h
	​

J
h
	​


and treats 1/(x
a
	​

x
b
	​

z
h
2
	​

) as a declared, separately extracted monomial. Only their product enters the physical convolution. 

02_factorization

The perturbative convention is only partly fixed. The powers α
s
2
	​

,α
s
3
	​

,α
s
4
	​

 are consistent with a pure-QCD 2→2 Born process, but the text refers to a “stated normalization” for flux, spin/color averages, 2π factors, and 
MS
 factors without actually stating it. The replacement uses the displayed α
s
	​

-expansion as the definition of H
(n)
 and says explicitly that every normalization not shown elsewhere belongs to H
(n)
. Matching this convention to another published normalization remains a separate step. 

02_factorization

The factor 1/(x
a
	​

x
b
	​

z
h
2
	​

) is verified for UU and TT, not yet for LL. It may be adopted as the declared LL convention, but its exact extraction must not be reported as an LL result before the corresponding coefficient is calculated. The replacement distinguishes the convention from the demonstrated checks.

The quark/antiquark helicity signs disappear when the scalar LL coefficient is introduced. The correlators correctly attach η
q
	​

=+1 and η
q
ˉ
	​

	​

=−1 to the helicity term, but the subsequent distribution product does not state where the factor η
a
	​

η
c
	​

 goes. The replacement keeps the PDF/FF product sign-free and displays η
a
	​

η
c
	​

λ
A
	​

λ
h
	​

 explicitly in the projected partonic interference. 

02_factorization

UU, LL, and TT scalar hard coefficients are not explicitly defined. The present text lists three PDF/FF products and describes the spin contractions in prose. The replacement defines the coefficients through a displayed decomposition of the projected partonic interference. For TT, it then defines one scalar hard coefficient for each independent physical azimuthal tensor.

The BMHV convention is required before the correlators are used. Because the order γ
5
	​


n matters in BMHV, referring only to a later appendix is insufficient for the defining equations. The replacement gives the metric split, the four-dimensional definition of γ
5
	​

, and its commutation relations before the correlators.

The hard-function independence criterion must distinguish physical and auxiliary vectors. The physical transverse spins remain in the TT azimuthal tensors. What must disappear are the momentum fractions and explicit auxiliary hadronic/light-cone basis vectors after the invariants and physical spin structures are fixed. 

02_factorization

The endpoint decomposition needs a test-function definition and explicit ϵ dependence. The displayed plus-distribution identity has the correct sign, but the plus prescription is not defined, and the final coefficient functions suppress ϵ even though the paper requires their exact Laurent dependence. The replacement retains the exact noninteger powers first, defines D
m
	​

 on test functions, and keeps ϵ,μ
R
	​

,μ
F
	​

 explicit. 

02_factorization

2. Replacement LaTeX
LaTeX
\section{Factorized observable, kinematics, and hard-function definition}
\label{sec:factorized-observable}

\subsection{Hadronic observable and perturbative expansion}

We consider the single-inclusive process
\begin{equation}
 A(P_A,S_A)+B(P_B,S_B)
 \longrightarrow
 h(P_h,S_h)+X,
 \label{eq:hadronic-process}
\end{equation}
with hadron masses neglected in the short-distance calculation.  The
Lorentz-invariant one-particle cross section is
\begin{equation}
 \mathcal I_h^{\mathsf P}(P_h)
 :=
 E_h\frac{\dd^3\sigma^{\mathsf P}}{\dd^3\bm P_h},
 \qquad
 \mathsf P\in\{\mathsf{UU},\mathsf{LL},\mathsf{TT}\}.
 \label{eq:invariant-observable}
\end{equation}
Hadron \(B\) is unpolarized.  The two letters in \(\mathsf P\) refer,
respectively, to the polarization of hadron \(A\) and of the identified
hadron \(h\).

For a chosen set \(\mathcal C_{\mathsf P}\) of partonic channels
\(a+b\to c+X\), the leading-twist factorization formula is written as
\begin{equation}
 \mathcal I_h^{\mathsf P}(P_h)
 =
 \sum_{(a,b,c)\in\mathcal C_{\mathsf P}}
 \int \dd\Xi_h\,
 \mathscr F_{ab\to c}^{\mathsf P}
 (x_a,x_b,z_h;\mu_F)\,
 \mathfrak m_{\mathsf P}(x_a,x_b,z_h)\,
 \mathcal H_{ab\to c}^{\mathsf P}
 (s,t,u;\mu_R,\mu_F,\eps),
 \label{eq:factorized-cross-section}
\end{equation}
where
\begin{equation}
 \dd\Xi_h
 :=
 \dd x_a\,\dd x_b\,\dd z_h\,
 \mathcal J_h(x_a,x_b,z_h;P_h).
 \label{eq:hadronic-convolution-measure}
\end{equation}
The factor \(\mathcal J_h\) contains the residual Jacobian associated with
the chosen measured hadronic variables and any kinematic constraints that
have not already been displayed.  It contains neither the PDF/FF product
\(\mathscr F^{\mathsf P}\), nor the separately declared momentum-fraction
monomial \(\mathfrak m_{\mathsf P}\), nor the partonic hard function.
Only the product
\[
 \dd\Xi_h\,
 \mathfrak m_{\mathsf P}
\]
is part of the physical convolution measure; its separation into
\(\mathcal J_h\) and \(\mathfrak m_{\mathsf P}\) is a normalization
convention.  Once \(\mathcal J_h\) is specified for a chosen set of measured
variables, Eq.~\eqref{eq:factorized-cross-section} may be matched directly
to a conventional single-inclusive normalization such as that of
Ref.~\cite{Aversa:1988vb}.

For the quark channels and hard-coefficient normalization used in the
present calculation, we declare
\begin{equation}
 \mathfrak m_{\mathsf P}(x_a,x_b,z_h)
 =
 \frac{1}{x_ax_bz_h^2}.
 \label{eq:declared-fraction-factor}
\end{equation}
The exact extraction of this factor, followed by independence of the
remaining coefficient from \(x_a,x_b,z_h\), has been verified for the
\(\mathsf{UU}\) and \(\mathsf{TT}\) real-emission calculations.  Its use in
the \(\mathsf{LL}\) channel defines the intended normalization, but the
corresponding LL independence statement is not claimed here.

For a pure-QCD channel whose Born term begins at order \(\alpha_s^2\), we
define the perturbative coefficient functions by
\begin{equation}
 \mathcal H_{ab\to c}^{\mathsf P}
 =
 \alpha_s^2(\mu_R)
 \sum_{n=0}^{\infty}
 \alpha_s^n(\mu_R)\,
 H_{ab\to c}^{\mathsf P,(n)}
 (s,t,u;\mu_R,\mu_F,\eps).
 \label{eq:hard-perturbative-expansion}
\end{equation}
Thus
\[
 H^{(0)},\qquad H^{(1)},\qquad H^{(2)}
\]
multiply \(\alpha_s^2,\alpha_s^3,\alpha_s^4\), respectively.  Equation
\eqref{eq:hard-perturbative-expansion} is the definition of the perturbative
normalization used in this manuscript.  Flux factors, initial-state
spin/color averages, powers of \(2\pi\), and dimensional-regularization scale
factors that are not displayed separately in
Eq.~\eqref{eq:factorized-cross-section} belong to the definition of
\(H^{\mathsf P,(n)}\).  Their final convention must be held fixed when real,
virtual, ultraviolet-renormalization, and collinear-factorization terms are
combined.  This section defines the required hard coefficient but does not
claim that this complete fixed-order combination has already been obtained.

\subsection{Hadronic and partonic kinematics}

The hadronic Mandelstam invariants are
\begin{equation}
 S=(P_A+P_B)^2,
 \qquad
 T=(P_A-P_h)^2,
 \qquad
 U=(P_B-P_h)^2.
 \label{eq:hadronic-invariants}
\end{equation}
At leading power, the incoming and fragmenting parton momenta are related to
the hadronic momenta by
\begin{equation}
 k_a=x_aP_A,
 \qquad
 k_b=x_bP_B,
 \qquad
 P_h=z_hk_c,
 \qquad
 0<x_a,x_b,z_h<1.
 \label{eq:collinear-map}
\end{equation}
The corresponding massless partonic invariants are
\begin{equation}
 s=(k_a+k_b)^2,
 \qquad
 t=(k_a-k_c)^2,
 \qquad
 u=(k_b-k_c)^2.
 \label{eq:partonic-invariants}
\end{equation}
Neglecting hadron and parton masses,
Eqs.~\eqref{eq:hadronic-invariants}--\eqref{eq:partonic-invariants} imply
\begin{equation}
 s=x_ax_bS,
 \qquad
 t=\frac{x_a}{z_h}T,
 \qquad
 u=\frac{x_b}{z_h}U.
 \label{eq:hadronic-partonic-map}
\end{equation}

The total momentum carried by the unobserved partonic final state is
\begin{equation}
 q^\mu:=k_a^\mu+k_b^\mu-k_c^\mu,
 \qquad
 Q^2:=q^2=s+t+u.
 \label{eq:recoil-invariant}
\end{equation}
For the interior of the real-emission region considered below, we use the
physical chamber
\begin{equation}
 s>0,
 \qquad
 t<0,
 \qquad
 u<0,
 \qquad
 Q^2>0,
 \qquad
 s+t>0,
 \qquad
 s+u>0,
 \qquad
 t+u<0.
 \label{eq:physical-chamber}
\end{equation}
Every noninteger power of a positive quantity in this chamber is defined
with the real logarithm.  For example,
\begin{equation}
 (Q^2)^\rho
 :=
 \exp\!\bigl[\rho\log Q^2\bigr],
 \qquad
 \log Q^2\in\mathbb R,
 \qquad
 Q^2>0.
 \label{eq:positive-recoil-power}
\end{equation}

The single-inclusive variables used in the endpoint analysis are
\begin{equation}
 v:=1+\frac{t}{s},
 \qquad
 w:=-\frac{u}{s+t},
 \qquad
 x:=1-w.
 \label{eq:vw-definitions}
\end{equation}
Their inverse map is
\begin{equation}
 t=-s(1-v),
 \qquad
 u=-svw=-sv(1-x),
 \qquad
 Q^2=sv(1-w)=svx.
 \label{eq:vw-inverse}
\end{equation}
The chamber in Eq.~\eqref{eq:physical-chamber} corresponds to
\begin{equation}
 s>0,
 \qquad
 0<v<1,
 \qquad
 0<w<1.
 \label{eq:vw-physical-region}
\end{equation}
The real-emission endpoint is approached from within this region:
\begin{equation}
 w\longrightarrow1^-,
 \qquad
 x=1-w\longrightarrow0^+,
 \qquad
 v\ \text{fixed}.
 \label{eq:real-endpoint}
\end{equation}

\subsection{Leading-twist polarization projections}

For each collinear direction \(r\in\{A,B,h\}\), introduce two null vectors
\(n_r^\mu\) and \(\bar n_r^\mu\) satisfying
\begin{equation}
 n_r^2=\bar n_r^2=0,
 \qquad
 n_r\cdot\bar n_r=1.
 \label{eq:lightcone-basis-normalization}
\end{equation}
The physical hadronic transverse-spin vectors obey
\begin{equation}
 S_{AT}\cdot n_A
 =
 S_{AT}\cdot\bar n_A
 =
 0,
 \qquad
 S_{hT}\cdot n_h
 =
 S_{hT}\cdot\bar n_h
 =
 0.
 \label{eq:transverse-spin-conditions}
\end{equation}
The vectors \(S_{AT}\) and \(S_{hT}\) describe the polarization of the
external hadrons.  No independent partonic spin four-vectors are introduced;
the polarization of the active partons is selected by the leading-twist
density matrices.

We use
\begin{equation}
 D=4-2\eps
 \label{eq:dimension-convention-section2}
\end{equation}
and the BMHV decomposition
\begin{equation}
 g_D^{\mu\nu}
 =
 \bar g^{\mu\nu}
 +
 \widehat g^{\mu\nu},
 \qquad
 \bar g^\mu{}_\mu=4,
 \qquad
 \widehat g^\mu{}_\mu=D-4=-2\eps.
 \label{eq:bmhv-metric-section2}
\end{equation}
The chirality matrix is defined in the four-dimensional subspace,
\begin{equation}
 \gamma_5
 :=
 \frac{i}{4!}
 \varepsilon_{\mu\nu\rho\sigma}
 \bar\gamma^\mu
 \bar\gamma^\nu
 \bar\gamma^\rho
 \bar\gamma^\sigma,
 \qquad
 \varepsilon^{0123}=+1,
 \label{eq:bmhv-gamma5-section2}
\end{equation}
so that
\begin{equation}
 \{\gamma_5,\bar\gamma^\mu\}=0,
 \qquad
 [\gamma_5,\widehat\gamma^\mu]=0.
 \label{eq:bmhv-gamma5-algebra-section2}
\end{equation}
The external hadronic momenta, light-cone vectors, and transverse-spin
vectors are four dimensional.  Loop and unresolved phase-space momenta remain
\(D\)-dimensional until the BMHV tensor and dimension recurrences have been
applied.

For \(\chi\in\{q,\bar q\}\), define
\begin{equation}
 \eta_\chi
 :=
 \begin{cases}
  +1,&\chi=q,\\
  -1,&\chi=\bar q.
 \end{cases}
 \label{eq:quark-antiquark-sign}
\end{equation}
With
\begin{equation}
 i\sigma^{ab}:=-\frac12[\not\!a,\not\!b],
 \label{eq:sigma-convention-section2}
\end{equation}
the quark and antiquark distribution correlators used in this work are
\begin{align}
 \Phi_{\chi/H}(x;\lambda_H,S_{HT})
 =\frac12\bigl[
  &f_1^{\chi/H}(x)\not\!n_H
  +\eta_\chi\lambda_H
   g_{1L}^{\chi/H}(x)\gamma_5\not\!n_H
  \notag\\
  &+
  h_1^{\chi/H}(x)
  i\sigma^{n_HS_{HT}}\gamma_5
 \bigr],
 \label{eq:pdf-correlator}
\end{align}
while the fragmentation correlators are
\begin{align}
 \Delta_{h/\chi}(z_h;\lambda_h,S_{hT})
 =\frac12\bigl[
  &D_1^{h/\chi}(z_h)\not\!n_h
  +\eta_\chi\lambda_h
   G_{1L}^{h/\chi}(z_h)\gamma_5\not\!n_h
  \notag\\
  &+
  H_1^{h/\chi}(z_h)
  i\sigma^{n_hS_{hT}}\gamma_5
 \bigr].
 \label{eq:ff-correlator}
\end{align}
The order \(\gamma_5\not\!n\) in
Eqs.~\eqref{eq:pdf-correlator} and \eqref{eq:ff-correlator} is part of the
BMHV definition.  In the antiquark convention used here, the helicity term
changes sign, whereas the unpolarized and transversity structures do not.
The Dirac structures are the standard leading-twist collinear ones
\cite{Bacchetta:2006tn}.

The corresponding PDF/FF products are
\begin{align}
 \mathscr F^{\mathsf{UU}}_{ab\to c}
 &=
 f_1^{a/A}(x_a)
 f_1^{b/B}(x_b)
 D_1^{h/c}(z_h),
 \notag\\
 \mathscr F^{\mathsf{LL}}_{ab\to c}
 &=
 g_{1L}^{a/A}(x_a)
 f_1^{b/B}(x_b)
 G_{1L}^{h/c}(z_h),
 \notag\\
 \mathscr F^{\mathsf{TT}}_{ab\to c}
 &=
 h_1^{a/A}(x_a)
 f_1^{b/B}(x_b)
 H_1^{h/c}(z_h).
 \label{eq:polarized-distribution-products}
\end{align}

For the displayed quark and antiquark channels, let
\(\widehat{\mathcal W}_{ab\to c}\) denote the projected partonic
amplitude--conjugate-amplitude interference after the unobserved final-state
sum and phase-space integration.  Its leading-twist spin decomposition
defines the scalar UU and LL coefficients and the TT hard tensor:
\begin{align}
 \widehat{\mathcal W}_{ab\to c}
 ={}&
 \mathscr F^{\mathsf{UU}}_{ab\to c}\,
 \widehat{\mathcal C}^{\mathsf{UU}}_{ab\to c}
 \notag\\
 &+
 \eta_a\eta_c\lambda_A\lambda_h\,
 \mathscr F^{\mathsf{LL}}_{ab\to c}\,
 \widehat{\mathcal C}^{\mathsf{LL}}_{ab\to c}
 \notag\\
 &+
 \mathscr F^{\mathsf{TT}}_{ab\to c}\,
 S_{AT}^{\mu}S_{hT}^{\nu}\,
 \widehat{\mathcal C}^{\mathsf{TT}}_{ab\to c,\mu\nu}
 +\cdots .
 \label{eq:polarized-partonic-decomposition}
\end{align}
The factors \(\eta_a\eta_c\) in the second line follow directly from the
quark/antiquark helicity signs in
Eqs.~\eqref{eq:pdf-correlator} and \eqref{eq:ff-correlator}.
They are displayed separately rather than absorbed into
\(\mathscr F^{\mathsf{LL}}\).

For the transverse channel, choose a complete independent set of physical
azimuthal tensors
\(\{\mathcal T_i^{\mu\nu}\}_{i=1}^{N_{\mathsf{TT}}}\).  The TT scalar
coefficients are defined by
\begin{equation}
 S_{AT}^{\mu}S_{hT}^{\nu}
 \widehat{\mathcal C}^{\mathsf{TT}}_{ab\to c,\mu\nu}
 =
 \sum_{i=1}^{N_{\mathsf{TT}}}
 \mathcal A_i(S_{AT},S_{hT};s,t,u)\,
 \widehat{\mathcal C}^{\mathsf{TT}}_{ab\to c,i},
 \label{eq:TT-scalar-decomposition}
\end{equation}
where
\begin{equation}
 \mathcal A_i
 :=
 S_{AT}^{\mu}S_{hT}^{\nu}\mathcal T_{i,\mu\nu}
 \label{eq:TT-azimuthal-structures}
\end{equation}
contains the physical spin and azimuthal dependence.  Each
\(\widehat{\mathcal C}^{\mathsf{TT}}_{ab\to c,i}\) is a scalar hard
coefficient.  Auxiliary light-cone vectors are not counted as physical
azimuthal structures and must cancel from these scalar coefficients.

\subsection{Definition and analytic content of the hard function}

Let
\(\widehat{\mathcal C}_{ab\to c}^{\mathsf P,(n)}\) denote one of the scalar
coefficients defined above at relative perturbative order \(n\), before
removing the declared momentum-fraction factor.  The hard function is defined
by
\begin{equation}
 \widehat{\mathcal C}_{ab\to c}^{\mathsf P,(n)}
 =
 \mathfrak m_{\mathsf P}(x_a,x_b,z_h)\,
 H_{ab\to c}^{\mathsf P,(n)}
 (s,t,u;\mu_R,\mu_F,\eps).
 \label{eq:hard-coefficient-definition}
\end{equation}
The PDF/FF product and the convolution measure have already been placed
outside \(\widehat{\mathcal C}^{\mathsf P,(n)}\) in
Eq.~\eqref{eq:factorized-cross-section}.  For TT,
Eq.~\eqref{eq:hard-coefficient-definition} is applied separately to each
physical azimuthal coefficient \(i\).

A common scalar normalization may be removed temporarily during the analytic
reduction:
\begin{equation}
 H_{ab\to c}^{\mathsf P,(n)}
 =
 \mathcal N_{\rm com}^{\mathsf P,(n)}
 (s,t,u;\mu_R,\mu_F,\eps)\,
 \widetilde H_{ab\to c}^{\mathsf P,(n)}
 (s,t,u;\mu_R,\mu_F,\eps).
 \label{eq:temporary-common-normalization}
\end{equation}
The factor
\(\mathcal N_{\rm com}^{\mathsf P,(n)}\) must be stated explicitly in each
worked calculation.  It may contain common powers of \(2\), \(\pi\), \(i\),
and phase-space normalizations.  It is not permanently divided out of the
physical hard function.  In particular, an endpoint-dependent factor such as
\begin{equation}
 (Q^2)^{-\eps}
 =
 (sv)^{-\eps}(1-w)^{-\eps}
 \label{eq:recoil-phase-space-factor}
\end{equation}
must be restored before the endpoint distribution is expanded.

After the collinear substitutions have been made and the factors in
Eqs.~\eqref{eq:factorized-cross-section} and
\eqref{eq:hard-coefficient-definition} have been removed, exact collinear
factorization requires
\begin{equation}
 \left.
 \frac{\partial H_{ab\to c}^{\mathsf P,(n)}}{\partial x_a}
 \right|_{s,t,u}
 =
 \left.
 \frac{\partial H_{ab\to c}^{\mathsf P,(n)}}{\partial x_b}
 \right|_{s,t,u}
 =
 \left.
 \frac{\partial H_{ab\to c}^{\mathsf P,(n)}}{\partial z_h}
 \right|_{s,t,u}
 =0.
 \label{eq:fraction-independence}
\end{equation}
This condition has been established exactly for the UU and TT real-emission
coefficients considered in this work.

Define the set of explicit auxiliary hadronic and light-cone vectors
\begin{equation}
 \mathcal V_{\rm aux}
 :=
 \{
  P_A,P_B,P_h,
  n_A,\bar n_A,
  n_B,\bar n_B,
  n_h,\bar n_h
 \}.
 \label{eq:auxiliary-vector-set}
\end{equation}
For UU, and for LL once that channel is calculated in the same convention,
the scalar hard coefficient must satisfy
\begin{equation}
 H_{ab\to c}^{\mathsf P,(n)}
 (s,t,u;\mathcal V_{\rm aux})
 =
 H_{ab\to c}^{\mathsf P,(n)}(s,t,u),
 \qquad
 \mathsf P\in\{\mathsf{UU},\mathsf{LL}\}.
 \label{eq:auxiliary-vector-independence}
\end{equation}
For TT, the same equation applies separately to each scalar coefficient
\(H_{ab\to c,i}^{\mathsf{TT},(n)}\).  The physical spin dependence remains
only in the tensors \(\mathcal A_i\) of
Eq.~\eqref{eq:TT-scalar-decomposition}; explicit dependence on
\(\mathcal V_{\rm aux}\) is absent.

The exact noninteger endpoint powers must be identified before the Laurent
expansion in \(\eps\).  After every temporarily removed factor in
Eq.~\eqref{eq:temporary-common-normalization} has been restored, write the
singular part of a real-emission coefficient as
\begin{equation}
 H_{{\rm real},ab\to c}^{\mathsf P,(n)}(v,w,\eps)
 =
 H_{{\rm reg},ab\to c}^{\mathsf P,(n)}(v,w,\eps)
 +
 \sum_{r=1}^{N_{\rm end}}
 C_{r,ab\to c}^{\mathsf P,(n)}(v,\eps)\,
 (1-w)^{-1-a_r\eps},
 \qquad
 a_r>0.
 \label{eq:unexpanded-endpoint-form}
\end{equation}
Here \(H_{\rm reg}\) is locally integrable at \(w=1\) in the convergence
domain, and
\begin{equation}
 (1-w)^{-1-a_r\eps}
 :=
 \exp\!\left[-(1+a_r\eps)\log(1-w)\right],
 \qquad
 0<w<1,
 \label{eq:endpoint-branch-definition}
\end{equation}
uses the real logarithm.  The values of \(a_r\) and the exact coefficients
\(C_r(v,\eps)\) are determined from the analytic real-emission result, not
from a numerical endpoint fit.

For \(m\in\mathbb Z_{\geq0}\), define
\begin{equation}
 \mathcal D_m(w)
 :=
 \left[
  \frac{\log^m(1-w)}{1-w}
 \right]_+,
 \label{eq:plus-distributions}
\end{equation}
where, for every smooth test function \(\varphi\),
\begin{equation}
 \int_0^1\dd w\,\mathcal D_m(w)\varphi(w)
 =
 \int_0^1\dd w\,
 \frac{\log^m(1-w)}{1-w}
 \bigl[\varphi(w)-\varphi(1)\bigr].
 \label{eq:plus-distribution-test-function-section2}
\end{equation}
For \(a>0\), the identity
\begin{equation}
 (1-w)^{-1-a\eps}
 =
 -\frac{\delta(1-w)}{a\eps}
 +
 \sum_{m=0}^{\infty}
 \frac{(-a\eps)^m}{m!}\,
 \mathcal D_m(w)
 \label{eq:endpoint-distribution-identity}
\end{equation}
is first valid for \(\operatorname{Re}\eps<0\) and then continued
meromorphically as a distribution.  The coefficients
\(C_r(v,\eps)\) must retain their complete Laurent expansions when this
identity is applied.

After the real-emission branches have been expanded and combined with any
virtual, ultraviolet-renormalization, and collinear-factorization
contributions belonging to the same perturbative order and normalization,
the hard function has the distributional form
\begin{align}
 H_{ab\to c}^{\mathsf P,(n)}
 (v,w;\mu_R,\mu_F,\eps)
 ={}&
 H_{\delta,ab\to c}^{\mathsf P,(n)}
 (v;\mu_R,\mu_F,\eps)\,
 \delta(1-w)
 \notag\\
 &+
 \sum_{m=0}^{m_{\max}}
 H_{m,ab\to c}^{\mathsf P,(n)}
 (v;\mu_R,\mu_F,\eps)\,
 \mathcal D_m(w)
 \notag\\
 &+
 H_{{\rm reg},ab\to c}^{\mathsf P,(n)}
 (v,w;\mu_R,\mu_F,\eps).
 \label{eq:hard-distributional-form}
\end{align}
The coefficients in Eq.~\eqref{eq:hard-distributional-form} are required as
exact analytic functions.  Numerical values at selected kinematic points may
be used to test those functions, but they do not define the hard coefficient.

## Sources sent to Pro

- [manuscript_02_factorization.tex](Sources/04_manuscript_02_factorization/manuscript_02_factorization.tex)
