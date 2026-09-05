# Manuscript 04 IBP Coefficients

## Question

The attached file is the current complete draft of Section 4, on cut-aware IBP
reduction and exact rational master coefficients. Review and rewrite this
section only.

Return:
1. A concise list of imprecise definitions, overclaims, or missing conditions.
2. Compilable replacement LaTeX for this section only.

Check especially:
- the exact equivalence criterion needed before an IBP reduction can be reused;
- preservation of cut slots, cut orientation, virtual-side assignment,
  measurement labels, propagator powers, and the normalized measure;
- the form of cut-aware IBP identities;
- what Kira determines and what it does not determine;
- the separation of rational master coefficients from Gamma functions,
  branch-sensitive powers, and spin tensors;
- the exact checks appropriate for Ratracer plus FireFly reconstruction;
- the extraction of a hard coefficient independent of momentum fractions,
  integration momenta, unreduced scalar products, and auxiliary hadronic
  vectors.

Section 2 defines the projected scalar coefficient by
\(\widehat{\mathcal C}^{\mathsf P,(n)}=\mathfrak m_{\mathsf P}
H^{\mathsf P,(n)}\), after the distribution product has already been
removed.  The attached draft currently multiplies the post-IBP coefficient
by both \(\mathscr F^{\mathsf P}\) and \(1/(x_ax_bz_h^2)\); identify and
correct that inconsistency rather than introducing a second hard-function
normalization.

The established NNLO statement is exact reconstruction of one representative
nontrivial master coefficient, not all 342 coefficients. Keep process-specific
kinematics out of the method where possible. Do not rewrite another section.

## Pro response

1. Required corrections

The topology criterion is incomplete in the main text. The draft requires an affine map, a denominator permutation, cut orientations, loop-sector assignments, and measurement labels, but it does not require preservation of the external kinematic ideal, physical chamber, analytic branches, ordinary causal class, admissible index domain, or an explicit numerator insertion not encoded by negative indices. These conditions are needed for equality of the dimensionally regulated cut integrals, not merely equality of denominator polynomials. 

04_ibp_coefficients

The Jacobian condition should be written as

detA=±1,

together with the sector-preserving form of the affine map. The normalized real LD-dimensional measure is then unchanged because ∣detA∣
D
=1.

The displayed IBP identity is not cut-aware. It uses the unnormalized measure ∏
r
	​

\dd
D
ℓ
r
	​

 and ordinary powers D
j
−ν
j
	​

	​

 for every slot. The replacement uses \dd
D
λ/(iπ
D/2
), normalized oriented cuts in the designated slots, fixed cut orientations, and the rule that a nonpositive physical cut index is the zero element of the fixed-cut family. 

04_ibp_coefficients

Kira’s role is overstated by omission. Kira solves the supplied algebraic IBP system and returns a basis and rational reduction rules in the configured sectors. It does not determine the physical cut assignment, causal prescription, branch, analytic value of a master, boundary condition, endpoint expansion, or hard-function normalization. The master basis is also ordering dependent and is not unique.

The imported reduction must be checked for transitive closure: every requested target must terminate only at declared masters, every terminal must have the correct family arity, and every physical cut index must remain positive. “Zero unreduced requested integrals” alone does not prove that an exported table is self-contained.

The finite-field acceptance criterion is too weak. Agreement at unused finite-field points is a strong independent test but not a deterministic characteristic-zero identity. The final analytic coefficient should also satisfy either

C
source
−C
rec
=0in Q(ζ),

or the equivalent cleared-denominator polynomial identity. A second reconstruction with an independent seed or prime sequence is useful but does not replace that identity. 

04_ibp_coefficients

Gamma functions, noninteger powers, BMHV structures, and physical spin tensors cannot merely be “separated” syntactically. They must first be placed in a declared exact analytic-channel basis after all identities intended for that basis have been applied. If two candidate channel factors may be algebraically related, they must remain in the same channel until their relation is resolved.

Equation \eqref{eq:post-ibp-hard-coefficient} double counts the collinear factors. Section 2 has already removed the PDF/FF product and defines

C
P,(n)
=m
P
	​

H
P,(n)
.

The draft incorrectly multiplies 
C
 by both
F
P
 and 1/(x
a
	​

x
b
	​

z
h
2
	​

). The PDF/FF product must not reappear in Section 4; the declared Laurent monomial appears only in the exact factorization relating 
C
 to H. 

04_ibp_coefficients

The NNLO finite-field result must remain narrowly stated: one representative nontrivial master coefficient has been reconstructed and verified exactly. This does not establish reconstruction of all 342 NNLO master coefficients.

2. Replacement LaTeX
LaTeX
\section{Cut-aware IBP reduction and exact master coefficients}
\label{sec:ibp-coefficients}

\subsection{Reuse of cut-decorated integral families}
\label{subsec:ibp-family-reuse}

Different ordered amplitude--conjugate-amplitude interferences can generate
the same scalar integral family after a change of integration variables.
Such a reduction may be reused only when the corresponding
dimensionally regulated cut integrals are equal, including their causal and
measurement data.

Let \(\mathcal T\) and \(\mathcal T'\) be cut-decorated family records of the
form defined in Appendix~\ref{app:topology-equivalence}.  A candidate map
consists of an allowed external relabeling \(\rho\), an affine change of
integration variables,
\begin{equation}
 \boldsymbol\lambda
 =
 A\boldsymbol\lambda'
 +
 B\boldsymbol p',
 \qquad
 \boldsymbol p=\rho(\boldsymbol p'),
 \qquad
 A_{rs},B_{ra}\in\mathbb Q,
 \qquad
 \det A=\pm1,
 \label{eq:affine-loop-map-main}
\end{equation}
and a permutation \(\pi\) of the denominator slots.  The matrix \(A\) must
preserve the decomposition into real phase-space, forward-virtual, and
conjugate-virtual integration variables.  In particular, it may not mix a
forward loop with a conjugate loop, and a real phase-space variable may not
acquire virtual-loop dependence.

The exact powered-integral relation used in the reduction is
\begin{equation}
 (\mathcal T,\boldsymbol\nu)
 \sim_{\rm pow}
 (\mathcal T',\boldsymbol\nu')
 \quad\Longleftrightarrow\quad
 \begin{gathered}
  \text{the map in Eq.~\eqref{eq:affine-loop-map-main}
  satisfies all conditions of }
  \mathcal T\sim_{\rm top}\mathcal T',
  \\
  \nu'_j=\nu_{\pi^{-1}(j)}
  \quad\text{for every slot }j .
 \end{gathered}
 \label{eq:powered-equivalence-main}
\end{equation}
The topology conditions include:

\begin{enumerate}
 \item exact equality of every denominator polynomial, with no
 slot-dependent multiplicative factor;

 \item preservation of the normalized measure;

 \item preservation of ordinary, cut, and auxiliary slot type;

 \item preservation of the forward, conjugate, shared-real, or mixed causal
 class of every noncut slot;

 \item a bijection of all physical cut slots, including the cut momentum and
 its energy orientation;

 \item preservation of every observed-line, particle-species, and
 measurement label;

 \item preservation of the external kinematic ideal, physical chamber,
 causal boundary values, and analytic branches;

 \item bijection of the admissible index domains, including positivity of
 every physical cut index.
\end{enumerate}

Under these conditions the change of variables gives
\begin{equation}
 I_{\mathcal T}^{(D)}
 \bigl(\boldsymbol\nu;\rho(\boldsymbol p')\bigr)
 =
 I_{\mathcal T'}^{(D)}
 \bigl(\pi_\ast\boldsymbol\nu;\boldsymbol p'\bigr),
 \qquad
 (\pi_\ast\boldsymbol\nu)_j
 =
 \nu_{\pi^{-1}(j)}.
 \label{eq:powered-integral-identity-main}
\end{equation}
If an explicit numerator or measurement insertion is not represented
entirely by negative family indices, it must also be mapped exactly under the
same change of variables.  Equality of the scalar families alone does not
establish equality of two measured diagram contributions.

Equation~\eqref{eq:powered-integral-identity-main}, rather than equality of
uncut graphs or equality of positive-denominator sets, is the relation that
permits one IBP reduction to be transported to another family.  The weaker
positive-denominator equivalence defined in
Appendix~\ref{app:topology-equivalence} forgets positive powers and therefore
does not by itself identify powered integrals or their reduction rules.

\subsection{IBP identities in a fixed cut family}
\label{subsec:cut-aware-ibp}

Let
\begin{equation}
 \mathcal F
 =
 \bigl(
  \Delta_1,\ldots,\Delta_N;
  C,\boldsymbol\xi
 \bigr)
 \label{eq:cut-family-data-section4}
\end{equation}
be a complete family, where \(C\subseteq\{1,\ldots,N\}\) is the set of
physical cut slots and \(\xi_c\) is the energy orientation of cut \(c\).
For an admissible index vector \(\boldsymbol\nu\), define the integrand
\begin{equation}
 \mathscr I_{\mathcal F}(\boldsymbol\nu)
 :=
 \prod_{c\in C}
 \mathcal C_{\xi_c}^{(\nu_c)}
 (\Delta_c;q_c)
 \prod_{j\notin C}
 \mathscr D_j^{(\nu_j)}(\Delta_j),
 \label{eq:cut-family-integrand-section4}
\end{equation}
where \(\mathcal C_{\xi_c}^{(\nu_c)}\) is the normalized oriented cut of
Appendix~\ref{app:conventions}, and
\(\mathscr D_j^{(\nu_j)}\) carries the fixed ordinary causal class of slot
\(j\).

For each integration momentum \(\lambda_r\) and each vector
\begin{equation}
 v^\mu
 \in
 \operatorname{span}_{\mathbb K}
 \{
  \lambda_1^\mu,\ldots,\lambda_L^\mu,
  p_1^\mu,\ldots,p_E^\mu
 \},
 \qquad
 \mathbb K=\mathbb Q(D,\boldsymbol s),
 \label{eq:ibp-vector-space}
\end{equation}
the cut-aware IBP identity is
\begin{equation}
 0
 =
 \int
 \prod_{a=1}^{L}
 \frac{\dd^D\lambda_a}{i\pi^{D/2}}\,
 \frac{\partial}{\partial\lambda_r^\mu}
 \left[
  v^\mu\,
  \mathscr I_{\mathcal F}(\boldsymbol\nu)
 \right].
 \label{eq:ibp-identity}
\end{equation}
Equation~\eqref{eq:ibp-identity} is first established in a domain in which
the total derivative has no boundary contribution and is then continued
meromorphically in \(D\), the external invariants, and the propagator
powers.

Within the fixed oriented-cut algebra, the cut orientation is held fixed and
differentiation raises the cut power according to
\begin{equation}
 \frac{\partial}{\partial\lambda_r^\mu}
 \mathcal C_{\xi_c}^{(\nu_c)}
 (\Delta_c;q_c)
 =
 -\nu_c
 \frac{\partial\Delta_c}{\partial\lambda_r^\mu}
 \mathcal C_{\xi_c}^{(\nu_c+1)}
 (\Delta_c;q_c).
 \label{eq:cut-derivative-ibp}
\end{equation}
Thus a differentiated cut remains the same physical cut with the same
momentum, slot identity, and energy orientation.  The fixed-cut family is
completed by the rule
\begin{equation}
 I_{\mathcal F}^{(D)}(\boldsymbol\nu)=0
 \qquad
 \text{if}\qquad
 \nu_c\leq0
 \quad\text{for any }c\in C.
 \label{eq:cut-index-zero-rule-section4}
\end{equation}
The physical cuts are therefore present during the reduction; they are not
imposed on an uncut reduction afterward.

Solving the linear system generated by
Eq.~\eqref{eq:ibp-identity} expresses each requested target integral as
\begin{equation}
 I_{\mathcal F}^{(D)}(\boldsymbol\nu)
 =
 \sum_{a=1}^{N_M}
 R_{\boldsymbol\nu a}
 (D,\boldsymbol s)\,
 M_a^{(D)}(\boldsymbol s),
 \qquad
 R_{\boldsymbol\nu a}
 \in\mathbb Q(D,\boldsymbol s).
 \label{eq:ibp-reduction}
\end{equation}
Here \(\boldsymbol s\) denotes a complete set of external invariants for the
family.  We use \Kira\ to solve this exact rational system
\cite{Maierhofer:2017gsa,Klappert:2020nbg}.

The master basis in Eq.~\eqref{eq:ibp-reduction} is a basis chosen for the
configured families, sectors, seed bounds, and integral ordering.  It is not
unique.  \Kira\ determines the algebraic reduction rules; it does not
determine:

\begin{enumerate}
 \item the physical cut assignment or cut energy orientation;

 \item the forward or conjugate causal boundary value of an ordinary
 propagator;

 \item the analytic branch or physical chamber;

 \item the analytic value or Laurent expansion of a master integral;

 \item the differential-equation boundary data;

 \item the normalization or endpoint-distribution decomposition of the hard
 function.
\end{enumerate}

These data are fixed before or after the IBP step as appropriate.  Although
the algebraic coefficients in Eq.~\eqref{eq:ibp-reduction} do not contain an
explicit \(i0\), the rule is interpreted only in the causal and cut family
for which it was derived.

The imported reduction is accepted only when it is transitively closed on
the requested targets.  If \(\mathscr R_{\mathcal F}\) denotes repeated
application of the imported rules, the condition is
\begin{equation}
 \operatorname{GLI}
 \left[
  \mathscr R_{\mathcal F}
  \bigl(I_{\mathcal F}^{(D)}(\boldsymbol\nu)\bigr)
 \right]
 \subseteq
 \{M_1,\ldots,M_{N_M}\}
 \label{eq:ibp-transitive-closure}
\end{equation}
for every requested \(\boldsymbol\nu\).  Every terminal integral must occur
in the declared master list, have the correct number of indices for its
family, and retain a positive index in every physical cut slot.  Conflicting
rules for the same integral invalidate the reduction.

\subsection{Rational composition of master coefficients}
\label{subsec:rational-master-coefficients}

Before IBP reduction, one projected scalar coefficient can be written as
\begin{equation}
 \widehat{\mathcal C}^{\mathsf P,(n)}
 =
 \sum_{\alpha=1}^{N_{\rm ch}}
 \mathfrak e_\alpha
 \sum_{t\in\mathcal T_{\rm tar}}
 r_{t\alpha}(\boldsymbol\zeta)\,
 I_t,
 \qquad
 r_{t\alpha}\in
 \mathbb K_{\rm rec}
 :=
 \mathbb Q(\boldsymbol\zeta).
 \label{eq:pre-ibp-analytic-channel-decomposition}
\end{equation}
The variables \(\boldsymbol\zeta\) comprise the exact rational variables
needed for the coefficient, such as \(D\) or \(\eps\), independent
dimensionless kinematic variables, and symbolic color factors.  The factors
\(\mathfrak e_\alpha\) form a declared exact analytic-channel basis.  They
may contain, for example, Gamma functions, branch-certified noninteger
powers, common powers of \(2\) or \(\pi\), or independent physical
azimuthal tensors.

All exact identities intended for this basis must be applied before
Eq.~\eqref{eq:pre-ibp-analytic-channel-decomposition} is declared.  If two
candidate factors may be algebraically related, their terms remain in the
same channel until that relation has been resolved.  The decomposition is
accepted only when recombination of all channels returns the original exact
coefficient.  Branch-sensitive powers are not assigned modular numerical
values, and an unprojected spin tensor is not evaluated in a finite field.
Only the rational coefficient of each fixed analytic channel is
reconstructed.

Substituting Eq.~\eqref{eq:ibp-reduction} into
Eq.~\eqref{eq:pre-ibp-analytic-channel-decomposition} gives
\begin{equation}
 \widehat{\mathcal C}^{\mathsf P,(n)}
 =
 \sum_{\alpha=1}^{N_{\rm ch}}
 \mathfrak e_\alpha
 \sum_{a=1}^{N_M}
 C_{a\alpha}^{\mathsf P,(n)}(\boldsymbol\zeta)\,
 M_a,
 \label{eq:post-ibp-channel-decomposition}
\end{equation}
with
\begin{equation}
 C_{a\alpha}^{\mathsf P,(n)}
 (\boldsymbol\zeta)
 =
 \sum_{t\in\mathcal T_{\rm tar}}
 r_{t\alpha}(\boldsymbol\zeta)\,
 R_{ta}(\boldsymbol\zeta).
 \label{eq:master-coefficient-sum}
\end{equation}
Equation~\eqref{eq:master-coefficient-sum} is the complete sparse
target-to-master composition.  It is an identity in
\(\mathbb K_{\rm rec}\); no master integral is evaluated in forming it.

Direct symbolic addition of the terms in
Eq.~\eqref{eq:master-coefficient-sum} can generate intermediate expressions
much larger than the final rational function.  We therefore record the
rational operation graph with \Ratracer\ and evaluate it over prime fields.
\FireFly\ reconstructs a candidate rational function
\cite{Magerya:2022bcf,Klappert:2019emp},
\begin{equation}
 C_{a\alpha}^{\rm rec}
 (\boldsymbol\zeta)
 =
 \frac{
  N_{a\alpha}(\boldsymbol\zeta)
 }{
  D_{a\alpha}(\boldsymbol\zeta)
 },
 \qquad
 N_{a\alpha},D_{a\alpha}
 \in\mathbb Q[\boldsymbol\zeta],
 \qquad
 \gcd(N_{a\alpha},D_{a\alpha})=1.
 \label{eq:reconstructed-rational-coefficient}
\end{equation}
The modular values are interpolation and verification data.  The output of
this step is the exact rational function in
Eq.~\eqref{eq:reconstructed-rational-coefficient}, not a fixed-kinematics
numerical approximation.

For each reconstructed coefficient, the following conditions are imposed:

\begin{enumerate}
 \item every source contribution belongs to
 \(\mathbb K_{\rm rec}\) and contains no inexact number;

 \item every requested target and every nonzero target-to-master entry is
 represented exactly once in the rational operation graph;

 \item all Kira remainders vanish and every terminal integral is a declared
 master with positive physical cut indices;

 \item the trace evaluator agrees with an independently accumulated modular
 source sum at nonsingular points over primes not used in the reconstruction;

 \item a reconstruction with an independent random seed or prime sequence
 returns the same reduced rational function;

 \item the reconstructed function obeys the characteristic-zero identity
 \begin{equation}
  \sum_{t\in\mathcal T_{\rm tar}}
  r_{t\alpha}R_{ta}
  -
  C_{a\alpha}^{\rm rec}
  =0
  \qquad
  \text{in }\mathbb K_{\rm rec}.
  \label{eq:characteristic-zero-reconstruction-identity}
 \end{equation}
\end{enumerate}

The final condition may be checked by direct exact rational simplification
or by clearing the exact source and candidate denominators and proving that
the resulting multivariate polynomial is identically zero.  Finite-field
comparisons and repeated reconstructions are independent checks, but they do
not replace Eq.~\eqref{eq:characteristic-zero-reconstruction-identity}.

For the NNLO double-real calculation discussed later, this complete
procedure has been carried out for one representative nontrivial master
coefficient.  It has not yet been carried out for all 342 NNLO master
coefficients.

\subsection{Extraction of the partonic hard coefficient}
\label{subsec:partonic-coefficient-extraction}

The quantity
\(\widehat{\mathcal C}^{\mathsf P,(n)}\) in
Eqs.~\eqref{eq:pre-ibp-analytic-channel-decomposition} and
\eqref{eq:post-ibp-channel-decomposition} is already the projected scalar
coefficient after the PDF/FF product has been removed.  The distribution
product \(\mathscr F^{\mathsf P}\) therefore does not appear again in this
section.

Section~\ref{sec:factorized-observable} defines the partonic hard
coefficient by
\begin{equation}
 \widehat{\mathcal C}^{\mathsf P,(n)}
 =
 \mathfrak m_{\mathsf P}(x_a,x_b,z_h)\,
 H^{\mathsf P,(n)},
 \qquad
 \mathfrak m_{\mathsf P}
 =
 \frac{1}{x_ax_bz_h^2}
 \label{eq:post-ibp-hard-coefficient}
\end{equation}
for the normalization used in the demonstrated UU and TT calculations.
For a fixed master basis, the exact statement is that the complete
post-IBP coefficient factorizes as
\begin{equation}
 C_{a\alpha}^{\rm raw}
 (x_a,x_b,z_h;s,t,u,\eps)
 =
 \mathfrak m_{\mathsf P}(x_a,x_b,z_h)\,
 \overline C_{a\alpha}
 (s,t,u,\eps)
 \label{eq:master-coefficient-fraction-factorization}
\end{equation}
for every nonzero master and analytic channel after all contributions have
been summed and the exact hadronic-to-partonic relations have been imposed.
The corresponding master-integral representation of the hard coefficient is
\begin{equation}
 H_{\rm MI}^{\mathsf P,(n)}
 =
 \sum_{\alpha=1}^{N_{\rm ch}}
 \mathfrak e_\alpha
 \sum_{a=1}^{N_M}
 \overline C_{a\alpha}^{\mathsf P,(n)}
 (s,t,u,\eps)\,
 M_a(s,t,u,\eps).
 \label{eq:master-expanded-hard-coefficient}
\end{equation}
No second hard-function normalization is introduced:
Eq.~\eqref{eq:master-expanded-hard-coefficient} is simply
\(\mathfrak m_{\mathsf P}^{-1}
\widehat{\mathcal C}^{\mathsf P,(n)}\)
in the convention of Section~\ref{sec:factorized-observable}.

At fixed partonic invariants, exact collinear factorization requires
\begin{equation}
 \left.
 \frac{\partial H_{\rm MI}^{\mathsf P,(n)}}{\partial x_a}
 \right|_{s,t,u}
 =
 \left.
 \frac{\partial H_{\rm MI}^{\mathsf P,(n)}}{\partial x_b}
 \right|_{s,t,u}
 =
 \left.
 \frac{\partial H_{\rm MI}^{\mathsf P,(n)}}{\partial z_h}
 \right|_{s,t,u}
 =0.
 \label{eq:post-ibp-fraction-independence}
\end{equation}
For UU, and for each scalar TT coefficient after projection onto the physical
azimuthal basis, this condition has been established exactly in the NLO
real-emission calculation.

The coefficients
\(\overline C_{a\alpha}^{\mathsf P,(n)}\) must also contain no:

\begin{enumerate}
 \item integration momentum;
 \item evanescent scalar product;
 \item unreduced scalar product involving an integration momentum;
 \item remaining ordinary or cut denominator;
 \item Dirac matrix, open Lorentz index, or unprojected spin tensor;
 \item explicit auxiliary hadronic or light-cone vector.
\end{enumerate}

For TT, physical spin dependence is retained only in the independent
azimuthal structures already separated in Section~2.  Any residual object
from the list above means that the tensor reduction, scalar-family
construction, IBP reduction, analytic-channel decomposition, or hadronic
factorization is incomplete.

Equation~\eqref{eq:master-expanded-hard-coefficient} is the exact output of
the present stage.  The analytic values of the masters, their physical
branches, differential equations, boundary data, and endpoint expansions
are determined in the following sections.

## Sources sent to Pro

- [manuscript_04_ibp_coefficients.tex](Sources/10_manuscript_04_ibp_coefficients/manuscript_04_ibp_coefficients.tex)
