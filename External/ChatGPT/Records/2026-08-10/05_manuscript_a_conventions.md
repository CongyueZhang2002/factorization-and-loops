# Manuscript A Conventions

## Question

The attached file is the current conventions and normalizations appendix.
Review and rewrite this appendix only.

Return:
1. A concise list of inconsistent or underdefined conventions.
2. Compilable replacement LaTeX for the appendix only.

Check the metric, BMHV gamma_5 convention, sigma convention, four-dimensional
external vectors, normalized IBP measure, conversion to the physical cut
measure, the MSbar factor, plus distributions, and the symbol table. In
particular, verify every factor of 2 pi and i in the conversion between a
physical L-loop N_C-cut integral and the normalized scalar integral. If the
conversion depends on how the cut operator is normalized, state both
definitions together rather than silently changing one. Keep notation
consistent with D=4-2 epsilon, Q^2=s+t+u, and z_h.

Do not rewrite another appendix or section in this turn.

## Pro response

1. Inconsistent or underdefined conventions

The appendix writes g
μν
=diag(1,−1,−1,−1) next to D=4−2ϵ, without distinguishing the four-dimensional BMHV metric 
g
ˉ
	​

μν
 from the D-dimensional metric g
D
μν
	​

. 

A_conventions

With the mostly-minus metric and ε
0123
=+1, tensor index lowering gives ε
0123
	​

=−1. The existing formula

γ
5
	​

=
4!
i
	​

ε
μνρσ
	​

γ
ˉ
	​

μ
γ
ˉ
	​

ν
γ
ˉ
	​

ρ
γ
ˉ
	​

σ

then has the opposite sign from
γ
5
	​

=i
γ
ˉ
	​

0
γ
ˉ
	​

1
γ
ˉ
	​

2
γ
ˉ
	​

3
.
The replacement defines γ
5
	​

 directly and gives the consistent epsilon-tensor form. 

A_conventions

“All polarization vectors are four dimensional” is too broad. The required BMHV statement concerns the hadronic momenta, collinear reference vectors, physical hadronic spins, and observed external hard momenta. Unresolved phase-space and virtual-loop momenta remain D-dimensional.

The conversion factor

(
(2π)
D
iπ
D/2
	​

)
L
(2π)
N
C
	​


is correct only when the scalar integral contains the normalized cut operator

C
ξ
(n)
	​

=
2πi
θ(ξq
0
)
	​

[(Δ−i0)
−n
−(Δ+i0)
−n
],

while the physical measure contains 2πC
ξ
(n)
	​

. The current appendix does not define C
+
	​

, so the factors of 2π and i cannot be checked from the text alone. 

A_conventions

If the IBP family instead uses the unnormalized discontinuity

C
=2πiC, the conversion is different:

I
phys
	​

=(
(2π)
D
iπ
D/2
	​

)
L
i
−N
C
	​

I
IBP
[
C
]
	​

.

Both conventions are stated below.

The conversion formula assumes that ordinary scalar denominators are identical in the physical and IBP integrands and that all Feynman-rule factors of i, overall momentum-conservation delta functions, and external prefactors are treated separately.

The stated 
MS
 factor is consistent with

S
ϵ
	​

=(4π)
ϵ
e
−γ
E
	​

ϵ
,μ
2ϵ
S
ϵ
−1
	​

=(
4π
μ
2
e
γ
E
	​

	​

)
ϵ
,

but its power is not specified. The replacement defines the factor without assuming how many copies occur in a given perturbative contribution. 

A_conventions

The current appendix gives only the test-function action of D
m
	​

, without first defining the distribution itself or stating the meromorphic endpoint identity. The symbol table is also too short to distinguish the cut orientation ξ, causal sign σ, endpoint variable x=1−w, and momentum fractions x
a
	​

,x
b
	​

. 

A_conventions

2. Replacement LaTeX
LaTeX
\section{Conventions and normalizations}
\label{app:conventions}

\subsection{Metric, Dirac algebra, and the BMHV split}
\label{app:metric-bmhv}

We use the mostly-minus metric in the physical four-dimensional subspace,
\begin{equation}
 \bar g^{\mu\nu}
 =
 \operatorname{diag}(1,-1,-1,-1),
 \qquad
 \varepsilon^{0123}=+1,
 \qquad
 \varepsilon_{0123}=-1,
 \label{eq:metric-and-dimension}
\end{equation}
and dimensional regularization in
\begin{equation}
 D=4-2\eps.
 \label{eq:appendix-dimension}
\end{equation}
The \(D\)-dimensional metric is decomposed according to the BMHV
prescription,
\begin{equation}
 g_D^{\mu\nu}
 =
 \bar g^{\mu\nu}
 +
 \widehat g^{\mu\nu},
 \qquad
 \bar g^\mu{}_\mu=4,
 \qquad
 \widehat g^\mu{}_\mu=D-4=-2\eps,
 \qquad
 \bar g^{\mu\rho}\widehat g_{\rho}{}^\nu=0.
 \label{eq:bmhv-metric-decomposition}
\end{equation}
Correspondingly,
\begin{equation}
 \gamma^\mu
 =
 \bar\gamma^\mu+\widehat\gamma^\mu,
 \label{eq:bmhv-gamma-decomposition}
\end{equation}
with
\begin{align}
 \{\bar\gamma^\mu,\bar\gamma^\nu\}
 &=2\bar g^{\mu\nu},
 &
 \{\widehat\gamma^\mu,\widehat\gamma^\nu\}
 &=2\widehat g^{\mu\nu},
 &
 \{\bar\gamma^\mu,\widehat\gamma^\nu\}
 &=0.
 \label{eq:bmhv-clifford-algebra}
\end{align}

For a vector \(a^\mu\),
\begin{equation}
 \not\!a:=\gamma_\mu a^\mu.
 \label{eq:slash-convention}
\end{equation}
For four-dimensional external vectors \(a^\mu\) and \(b^\mu\), we define
\begin{equation}
 \sigma^{\mu\nu}
 :=
 \frac{i}{2}
 [\bar\gamma^\mu,\bar\gamma^\nu],
 \qquad
 i\sigma^{ab}
 :=
 i\sigma^{\mu\nu}a_\mu b_\nu
 =
 -\frac12[\not\!a,\not\!b].
 \label{eq:sigma-convention}
\end{equation}

The BMHV chirality matrix is defined directly by
\begin{equation}
 \gamma_5
 :=
 i\bar\gamma^0\bar\gamma^1\bar\gamma^2\bar\gamma^3
 =
 -\frac{i}{4!}
 \varepsilon_{\mu\nu\rho\sigma}
 \bar\gamma^\mu
 \bar\gamma^\nu
 \bar\gamma^\rho
 \bar\gamma^\sigma.
 \label{eq:bmhv-gamma5}
\end{equation}
It satisfies
\begin{equation}
 \gamma_5^2=1,
 \qquad
 \{\gamma_5,\bar\gamma^\mu\}=0,
 \qquad
 [\gamma_5,\widehat\gamma^\mu]=0.
 \label{eq:bmhv-gamma5-algebra}
\end{equation}

The hadronic momenta, observed hard-parton momenta, recoil momentum,
collinear reference vectors, and physical hadronic spin vectors are taken to
lie entirely in the four-dimensional subspace:
\begin{equation}
 \widehat v^\mu=0,
 \qquad
 v\in
 \{
  P_A,P_B,P_h,
  k_a,k_b,k_c,q,
  n_r,\bar n_r,
  S_{AT},S_{hT}
 \},
 \qquad
 r\in\{A,B,h\}.
 \label{eq:four-dimensional-external-vectors}
\end{equation}
Virtual-loop momenta and unresolved phase-space integration momenta remain
\(D\)-dimensional:
\begin{equation}
 \ell^\mu
 =
 \bar\ell^\mu+\widehat\ell^\mu.
 \label{eq:integration-momentum-split}
\end{equation}

\subsection{Ordinary propagators and oriented cuts}
\label{app:propagator-cut-conventions}

Let \(\Delta\) denote a real scalar denominator polynomial.  An ordinary
propagator of power \(n\) and causal sign \(\sigma\) is
\begin{equation}
 \mathcal P_\sigma^{(n)}(\Delta)
 :=
 \frac{1}{(\Delta+i0\,\sigma)^n},
 \qquad
 \sigma\in\{+1,-1\},
 \qquad
 n\in\mathbb Z_{\geq1},
 \label{eq:ordinary-propagator-convention}
\end{equation}
where
\begin{equation}
 \Delta+i0\,\sigma
 :=
 \lim_{\eta\to0^+}(\Delta+i\sigma\eta).
 \label{eq:i0-limit}
\end{equation}
The sign \(\sigma=+1\) denotes the forward-amplitude prescription and
\(\sigma=-1\) the conjugate-amplitude prescription.

For a cut momentum \(q_c\), with
\begin{equation}
 \Delta_c:=q_c^2,
 \label{eq:cut-denominator}
\end{equation}
the energy orientation is denoted by
\begin{equation}
 \xi_c\in\{+1,-1\}.
 \label{eq:cut-energy-orientation}
\end{equation}
The normalized oriented cut operator is
\begin{align}
 \mathcal C_{\xi_c}^{(n)}(\Delta_c;q_c)
 :={}&
 \frac{\theta(\xi_c q_c^0)}{2\pi i}
 \left[
  \frac{1}{(\Delta_c-i0)^n}
  -
  \frac{1}{(\Delta_c+i0)^n}
 \right]
 \notag\\
 ={}&
 \theta(\xi_c q_c^0)
 \frac{(-1)^{n-1}}{(n-1)!}
 \delta^{(n-1)}(\Delta_c).
 \label{eq:normalized-cut-operator}
\end{align}
The derivative in the second line acts only on the real argument
\(\Delta_c\); the energy theta function is held fixed.  In particular,
\begin{equation}
 \mathcal C_{\xi_c}^{(1)}(\Delta_c;q_c)
 =
 \theta(\xi_c q_c^0)\delta(\Delta_c),
 \label{eq:unit-power-cut}
\end{equation}
and the physical positive-energy cut is obtained with \(\xi_c=+1\).

It is also useful to record the unnormalized discontinuity convention,
\begin{align}
 \widetilde{\mathcal C}_{\xi_c}^{(n)}(\Delta_c;q_c)
 :={}&
 \theta(\xi_c q_c^0)
 \left[
  \frac{1}{(\Delta_c-i0)^n}
  -
  \frac{1}{(\Delta_c+i0)^n}
 \right]
 \notag\\
 ={}&
 2\pi i\,
 \mathcal C_{\xi_c}^{(n)}(\Delta_c;q_c).
 \label{eq:unnormalized-cut-operator}
\end{align}
Equations~\eqref{eq:normalized-cut-operator} and
\eqref{eq:unnormalized-cut-operator} fix the relative factors of
\(2\pi\) and \(i\) used below.

\subsection{Physical and normalized scalar-integral measures}
\label{app:measure-conventions}

For each remaining integration momentum, the physical measure is
\begin{equation}
 [\dd^D\ell]_{\rm phys}
 :=
 \frac{\dd^D\ell}{(2\pi)^D},
 \label{eq:physical-measure}
\end{equation}
whereas the scalar-integral normalization used for IBP reduction and
dimension recurrences is
\begin{equation}
 [\dd^D\ell]_{\rm IBP}
 :=
 \frac{\dd^D\ell}{i\pi^{D/2}}.
 \label{eq:ibp-measure}
\end{equation}

Consider an integral over \(L\) remaining integration momenta, with
\(N_C\) cut denominators and \(N_O\) ordinary denominators.  Using the
normalized cuts of Eq.~\eqref{eq:normalized-cut-operator}, define
\begin{align}
 I_{\rm IBP}^{[\mathcal C]}
 :={}&
 \int
 \prod_{r=1}^{L}[\dd^D\ell_r]_{\rm IBP}\,
 \mathcal N(\{\ell\})
 \prod_{c=1}^{N_C}
 \mathcal C_{\xi_c}^{(n_c)}(\Delta_c;q_c)
 \prod_{j=1}^{N_O}
 \mathcal P_{\sigma_j}^{(m_j)}(\Delta_j),
 \label{eq:normalized-ibp-integral}
\end{align}
and
\begin{align}
 I_{\rm phys}
 :={}&
 \int
 \prod_{r=1}^{L}[\dd^D\ell_r]_{\rm phys}\,
 \mathcal N(\{\ell\})
 \prod_{c=1}^{N_C}
 \left[
  2\pi\,
  \mathcal C_{\xi_c}^{(n_c)}(\Delta_c;q_c)
 \right]
 \prod_{j=1}^{N_O}
 \mathcal P_{\sigma_j}^{(m_j)}(\Delta_j).
 \label{eq:physical-cut-integral}
\end{align}
For \(n_c=1\), each bracket in
Eq.~\eqref{eq:physical-cut-integral} is the usual
\(2\pi\theta(\xi_cq_c^0)\delta(q_c^2)\).  Positive higher powers define the
corresponding differentiated-cut descendants generated by reverse unitarity.

If the numerator, ordinary propagators, and all external prefactors are
identical in Eqs.~\eqref{eq:normalized-ibp-integral} and
\eqref{eq:physical-cut-integral}, their exact relation is
\begin{equation}
 I_{\rm phys}
 =
 \left(
  \frac{i\pi^{D/2}}{(2\pi)^D}
 \right)^L
 (2\pi)^{N_C}
 I_{\rm IBP}^{[\mathcal C]}.
 \label{eq:ibp-physical-conversion}
\end{equation}
Equation~\eqref{eq:ibp-physical-conversion} concerns only the integration
measure and the normalization of the cut operators.  Feynman-rule factors
of \(i\), couplings, color factors, spin averages, flux factors, and any
overall momentum-conservation delta function are contained in
\(\mathcal N\) or in a separate common prefactor and are not generated by
this conversion.

If the scalar family is instead written with the unnormalized
discontinuities of Eq.~\eqref{eq:unnormalized-cut-operator}, define
\begin{equation}
 I_{\rm IBP}^{[\widetilde{\mathcal C}]}
 :=
 I_{\rm IBP}^{[\mathcal C]}
 \bigg|_{
  \mathcal C_{\xi_c}^{(n_c)}
  \,\to\,
  \widetilde{\mathcal C}_{\xi_c}^{(n_c)}
 }.
 \label{eq:unnormalized-ibp-integral}
\end{equation}
Since
\[
 \widetilde{\mathcal C}_{\xi_c}^{(n_c)}
 =
 2\pi i\,\mathcal C_{\xi_c}^{(n_c)},
\]
the corresponding conversion is
\begin{equation}
 I_{\rm phys}
 =
 \left(
  \frac{i\pi^{D/2}}{(2\pi)^D}
 \right)^L
 i^{-N_C}
 I_{\rm IBP}^{[\widetilde{\mathcal C}]}.
 \label{eq:unnormalized-ibp-physical-conversion}
\end{equation}
The two conversion formulas are therefore equivalent once the cut
normalization has been stated.

Neither conversion changes the energy orientation \(\xi_c\), the ordinary
causal sign \(\sigma_j\), or the analytic branch of a noninteger power.

\subsection{\texorpdfstring{\(\overline{\mathrm{MS}}\)}{MSbar} scale convention}
\label{app:msbar-convention}

Define
\begin{equation}
 S_\eps
 :=
 (4\pi)^\eps e^{-\gamma_E\eps}.
 \label{eq:sepsilon-definition}
\end{equation}
The scale factor used in the existing NLO real-emission calculation is
\begin{equation}
 \mu^{2\eps}S_\eps^{-1}
 =
 \left(
  \frac{\mu^2e^{\gamma_E}}{4\pi}
 \right)^\eps.
 \label{eq:msbar-scale-factor}
\end{equation}
The power with which Eq.~\eqref{eq:msbar-scale-factor} occurs depends on the
perturbative contribution and on the normalization chosen for the coupling
and phase-space measure.  It is therefore displayed explicitly wherever
real, virtual, ultraviolet-renormalization, and collinear-factorization
terms are combined; no additional copy is implicit in
Eqs.~\eqref{eq:physical-measure} or \eqref{eq:ibp-measure}.

\subsection{Endpoint distributions}
\label{app:endpoint-distributions}

For \(m\in\mathbb Z_{\geq0}\), define
\begin{equation}
 \mathcal D_m(w)
 :=
 \left[
  \frac{\ln^m(1-w)}{1-w}
 \right]_+,
 \qquad
 0\leq w\leq1.
 \label{eq:plus-distribution-definition-appendix}
\end{equation}
Its action on a smooth test function \(\varphi\) is
\begin{equation}
 \int_0^1\dd w\,\mathcal D_m(w)\varphi(w)
 =
 \int_0^1\dd w\,
 \frac{\ln^m(1-w)}{1-w}
 \bigl[\varphi(w)-\varphi(1)\bigr].
 \label{eq:plus-test-function}
\end{equation}
For \(a>0\), one first has, in the convergence domain
\(\operatorname{Re}\eps<0\),
\begin{equation}
 (1-w)^{-1-a\eps}
 =
 -\frac{\delta(1-w)}{a\eps}
 +
 \sum_{m=0}^{\infty}
 \frac{(-a\eps)^m}{m!}\,
 \mathcal D_m(w),
 \label{eq:endpoint-distribution-identity-appendix}
\end{equation}
and then its meromorphic continuation in \(\eps\) as a distribution.  The
coefficient multiplying the left-hand side must retain its complete Laurent
series when Eq.~\eqref{eq:endpoint-distribution-identity-appendix} is used.

\subsection{Symbol table}
\label{app:symbol-table}

\begin{table}[htbp]
\centering
\small
\begin{tabularx}{\textwidth}{@{}p{0.23\textwidth}X@{}}
\toprule
Symbol & Meaning\\
\midrule
\(P_A,P_B,P_h\)
& Incoming and identified hadron momenta.\\
\(S_{AT},S_{hT}\)
& Physical transverse-spin vectors of hadron \(A\) and the identified
hadron \(h\).\\
\(k_a,k_b,k_c\)
& Incoming and identified hard-parton momenta.\\
\(x_a,x_b,z_h\)
& Collinear incoming and fragmentation momentum fractions.\\
\(S,T,U\)
& Hadronic Mandelstam invariants.\\
\(s,t,u\)
& Partonic Mandelstam invariants.\\
\(q,Q^2\)
& Recoil momentum and invariant,
\(q=k_a+k_b-k_c\) and \(Q^2=q^2=s+t+u\).\\
\(v,w\)
& Single-inclusive variables,
\(v=1+t/s\) and \(w=-u/(s+t)\).\\
\(x\)
& Endpoint variable \(x=1-w\), distinct from the fractions \(x_a,x_b\).\\
\(D,\eps\)
& Dimensional-regularization variables, \(D=4-2\eps\).\\
\(\bar g,\widehat g\)
& Four-dimensional and evanescent metric tensors in the BMHV split.\\
\(\bar\gamma,\widehat\gamma\)
& Four-dimensional and evanescent Dirac matrices.\\
\(\sigma\)
& Ordinary-propagator causal sign:
\(\sigma=+1\) for \(+i0\) and \(\sigma=-1\) for \(-i0\).\\
\(\xi\)
& Cut energy orientation:
\(\theta(\xi q^0)\), with \(\xi=+1\) for a future-directed cut.\\
\(\mathcal P_\sigma^{(n)}(\Delta)\)
& Ordinary scalar propagator
\((\Delta+i0\,\sigma)^{-n}\).\\
\(\mathcal C_\xi^{(n)}\)
& Normalized oriented cut operator, including \(1/(2\pi i)\).\\
\(\widetilde{\mathcal C}_\xi^{(n)}\)
& Unnormalized discontinuity,
\(\widetilde{\mathcal C}_\xi^{(n)}=2\pi i\,\mathcal C_\xi^{(n)}\).\\
\([\dd^D\ell]_{\rm phys}\)
& Physical integration measure \(\dd^D\ell/(2\pi)^D\).\\
\([\dd^D\ell]_{\rm IBP}\)
& Normalized scalar-integral measure
\(\dd^D\ell/(i\pi^{D/2})\).\\
\(S_\eps\)
& \((4\pi)^\eps e^{-\gamma_E\eps}\).\\
\(\mu_R,\mu_F\)
& Renormalization and collinear-factorization scales.\\
\(\mathcal D_m(w)\)
& Plus distribution
\(\bigl[\ln^m(1-w)/(1-w)\bigr]_+\).\\
\(H^{\mathsf P,(n)}\)
& Partonic hard coefficient multiplying
\(\alpha_s^{n+2}\) for the pure-QCD channels considered here.\\
\bottomrule
\end{tabularx}
\caption{Principal kinematic, dimensional, causal, cut, and distribution
symbols used in the manuscript.}
\label{tab:symbols}
\end{table}

## Sources sent to Pro

- [manuscript_a_conventions.tex](Sources/05_manuscript_a_conventions/manuscript_a_conventions.tex)
