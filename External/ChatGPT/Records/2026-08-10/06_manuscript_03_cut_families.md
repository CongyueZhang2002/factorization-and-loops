# Manuscript 03 Cut Families

## Question

The attached file is the current complete draft of Section 3, from ordered
amplitude interferences to cut integral families. Review and rewrite this
section only.

Return:
1. A concise list of physical or mathematical errors and claims that need
   qualification.
2. Compilable replacement LaTeX for this section only.

Check explicitly:
- whether the ordered amplitude/conjugate-amplitude interference is defined
  with enough information to determine causal prescriptions for virtual
  momenta;
- the normalization and derivative sign of the oriented cut operator;
- the D-dimensional m-particle phase-space measure and the elimination of one
  momentum;
- the rule that a nonpositive cut index gives zero;
- when a denominator built only from external and real phase-space momenta may
  omit i0, and when it must be rejected;
- why partial fractions must preserve every physical cut;
- the ordering from literal propagators to independent subsets and complete
  scalar-product families;
- the BMHV split and the distinction between shifted-dimensional scalar
  integrals and the D-dimensional coefficients from the Dirac algebra.

Do not introduce a global-discontinuity method or numerical master evaluation
as the main route. Do not claim more multiloop causal coverage than the stated
failure condition establishes. Keep the section as a connected physics
derivation, not a software description. Do not rewrite another section.

## Pro response

1. Physical and mathematical corrections

The ordered interference does not yet determine the virtual causal prescriptions. The draft defines only M
i
	​

M
j
∗
	​

; it does not introduce disjoint amplitude-side and conjugate-side loop variables or show explicitly that their ordinary propagators carry +i0 and −i0, respectively. These data are required before topology construction. 

03_cut_families

The spin projection is stated in the wrong order. Unobserved external spins and polarizations are summed. Hadron-associated collinear fermion lines should instead remain open until they are closed with the leading-twist PDF and FF correlators; they are not first replaced by ordinary spin sums.

The m-particle phase-space formula is correct, but the elimination of one momentum is underdefined. The replacement displays the exact reduced measure, including every factor of 2π, and shows that m physical cuts remain although only m−1 phase-space momenta are integrated. 

03_cut_families

The cut derivative sign is correct, but the cut operator should retain both the denominator and the oriented cut momentum as arguments. It should also state that the derivative acts on the real denominator while the energy theta function is held fixed, and that the physical phase-space cut is 2πC
+
(1)
	​

=2πδ
+
	​

. 

03_cut_families

The nonpositive-cut-index rule needs an explicit family definition. A cut power greater than one is a differentiated cut, whereas a cut index ν
c
	​

≤0 defines the zero element of the fixed-cut family. It is not an ordinary uncut integral.

The criterion for dropping i0 from a phase-space-only denominator is too weak. Absence of an interior zero is sufficient when the denominator is nonzero throughout the closed domain. If it vanishes only on soft or collinear boundary strata, the denominator alone is not enough: the complete dimensionally regulated term must possess a nonempty absolute-convergence domain after endpoint sectorization. Only then may opposite source-side prescriptions be combined as one meromorphic integral family. An interior zero or sign change must be rejected by the present construction. 

03_cut_families

The statement about filtering partial-fraction terms is too categorical. Terms in which a designated cut index becomes nonpositive are zero in the reverse-unitarity family and may be projected out. What is forbidden is forgetting cut identity, merging a cut with an ordinary propagator having the same polynomial, changing its energy orientation, or failing to verify the exact identity after the cut-family projection. 

03_cut_families

“Complete scalar-product family” is not defined. The replacement defines the integration scalar-product space, its dimension, and the rank condition that a denominator list must satisfy. It also states the causal restrictions on auxiliary inverse propagators, especially mixed forward–conjugate completion slots. 

03_cut_families

The BMHV treatment omits ordinary physical tensor numerators. Contractions such as ℓ⋅S
AT
	​

 and ℓ⋅S
hT
	​

 cannot remain as coefficients of scalar GLIs. For each evanescent degree r, the remaining physical tensor numerator must be reduced in integration dimension D+2r before the scalar integrals are lowered to D. Explicit factors of D=4−2ϵ produced by the original Dirac algebra are not shifted to D+2r. 

03_cut_families

2. Replacement LaTeX
LaTeX
\section{From amplitudes to cut integral families}
\label{sec:cut-families}

\subsection{Ordered amplitude--conjugate-amplitude interferences}
\label{subsec:ordered-interferences}

At a fixed perturbative order, the real-emission contribution is organized
as a sum over ordered amplitude--conjugate-amplitude pairs.  Let
\begin{equation}
 \boldsymbol\ell_F
 =
 (\ell_{F,1},\ldots,\ell_{F,L_F}),
 \qquad
 \boldsymbol\ell_C
 =
 (\ell_{C,1},\ldots,\ell_{C,L_C})
 \label{eq:ordered-virtual-loop-sets}
\end{equation}
be disjoint sets of forward-amplitude and conjugate-amplitude virtual-loop
momenta.  The real final-state momenta are shared by the two sides and are
denoted by
\begin{equation}
 \boldsymbol k=(k_1,\ldots,k_m).
 \label{eq:shared-real-momenta}
\end{equation}
Even when an algebraic change of variables could make a forward and a
conjugate loop momentum look identical, they remain independent integration
variables in the squared amplitude.

At the integrand level, write the amplitude-side contribution as
\begin{equation}
 \mathfrak M_i^F
 (\boldsymbol\ell_F,\boldsymbol k)
 =
 \frac{
  \mathcal N_i^F(\boldsymbol\ell_F,\boldsymbol k)
 }{
  \displaystyle
  \prod_{a=1}^{N_i^F}
  \bigl(\Delta_{ia}^F+i0\bigr)^{n_{ia}}
 },
 \qquad
 n_{ia}\in\mathbb Z_{\geq1},
 \label{eq:forward-amplitude-integrand}
\end{equation}
and its conjugate-side partner as
\begin{equation}
 \mathfrak M_j^C
 (\boldsymbol\ell_C,\boldsymbol k)
 =
 \frac{
  \mathcal N_j^C(\boldsymbol\ell_C,\boldsymbol k)
 }{
  \displaystyle
  \prod_{b=1}^{N_j^C}
  \bigl(\Delta_{jb}^C-i0\bigr)^{n_{jb}}
 }.
 \label{eq:conjugate-amplitude-integrand}
\end{equation}
Complex conjugation acts on the numerator, couplings, color tensors, and
ordinary propagator boundary values.  Equations
\eqref{eq:forward-amplitude-integrand} and
\eqref{eq:conjugate-amplitude-integrand} therefore fix the causal sector
before any loop-momentum relabeling is considered.

Let \(\mathscr P_{\mathsf P}\) denote the leading-twist projection in the
polarization channel
\(\mathsf P\in\{\mathsf{UU},\mathsf{LL},\mathsf{TT}\}\).
It sums unobserved external spins, polarizations, and colors, while the
hadron-associated collinear fermion lines are closed with the PDF and FF
correlators of Eqs.~\eqref{eq:pdf-correlator} and
\eqref{eq:ff-correlator}.  The ordered interference is
\begin{align}
 \mathcal W_{ij}^{\mathsf P}
 ={}&
 \int\dd\Phi_m(q;\boldsymbol k)
 \prod_{a=1}^{L_F}
 \frac{\dd^D\ell_{F,a}}{(2\pi)^D}
 \prod_{b=1}^{L_C}
 \frac{\dd^D\ell_{C,b}}{(2\pi)^D}
 \notag\\
 &\times
 \mathscr P_{\mathsf P}
 \left[
  \mathfrak M_i^F(\boldsymbol\ell_F,\boldsymbol k)
  \mathfrak M_j^C(\boldsymbol\ell_C,\boldsymbol k)
 \right].
 \label{eq:ordered-interference}
\end{align}
The ordering \(i,j\) is physical whenever either side contains a virtual
loop.  The complete cross section contains the required sum over ordered
pairs; no identification of the two virtual-loop sets is made inside an
individual term.

\subsection{Phase space, reverse unitarity, and causal sectors}
\label{subsec:reverse-unitarity-causal}

For \(m\) massless unobserved final-state partons, the \(D\)-dimensional
phase-space measure is
\begin{equation}
 \dd\Phi_m(q;\boldsymbol k)
 =
 (2\pi)^D
 \delta^{(D)}
 \left(
  q-\sum_{r=1}^{m}k_r
 \right)
 \prod_{r=1}^{m}
 \frac{\dd^Dk_r}{(2\pi)^{D-1}}
 \delta_+(k_r^2),
 \label{eq:physical-m-particle-phase-space}
\end{equation}
where
\begin{equation}
 \delta_+(k^2):=\theta(k^0)\delta(k^2).
 \label{eq:positive-energy-delta-section3}
\end{equation}
Choose \(k_m\) as the dependent momentum,
\begin{equation}
 k_m
 =
 q-\sum_{r=1}^{m-1}k_r.
 \label{eq:dependent-phase-space-momentum}
\end{equation}
After using the momentum-conservation delta function,
Eq.~\eqref{eq:physical-m-particle-phase-space} becomes
\begin{align}
 \dd\Phi_m(q;\boldsymbol k)
 ={}&
 \prod_{r=1}^{m-1}
 \left[
  \frac{\dd^Dk_r}{(2\pi)^D}
  \,2\pi\delta_+(k_r^2)
 \right]
 \,
 2\pi\delta_+(k_m^2).
 \label{eq:eliminated-m-particle-phase-space}
\end{align}
Thus only \(m-1\) phase-space momenta remain as integration variables, but
all \(m\) positive-energy on-shell conditions remain as physical cuts.

For a cut momentum \(q_c\), define
\begin{equation}
 \Delta_c:=q_c^2-m_c^2,
 \qquad
 \xi_c\in\{+1,-1\},
 \label{eq:cut-denominator-orientation}
\end{equation}
where \(\xi_c\) fixes the sign of the cut energy.  The normalized oriented cut
of power \(n\) is
\begin{align}
 \mathcal C_{\xi_c}^{(n)}(\Delta_c;q_c)
 :={}&
 \frac{\theta(\xi_cq_c^0)}{2\pi i}
 \left[
  \frac{1}{(\Delta_c-i0)^n}
  -
  \frac{1}{(\Delta_c+i0)^n}
 \right]
 \notag\\
 ={}&
 \theta(\xi_cq_c^0)
 \frac{(-1)^{n-1}}{(n-1)!}
 \delta^{(n-1)}(\Delta_c),
 \qquad
 n\in\mathbb Z_{\geq1}.
 \label{eq:oriented-cut}
\end{align}
The derivative in the second line acts on the real variable \(\Delta_c\);
the energy theta function is held fixed.  In particular,
\begin{equation}
 2\pi\mathcal C_{+}^{(1)}(k^2;k)
 =
 2\pi\theta(k^0)\delta(k^2)
 =
 2\pi\delta_+(k^2).
 \label{eq:physical-unit-cut}
\end{equation}
A positive power greater than one is therefore a differentiated version of
the same on-shell condition, not an additional real particle.

Let
\begin{equation}
 \boldsymbol\lambda
 :=
 (k_1,\ldots,k_{m-1},
  \ell_{F,1},\ldots,\ell_{F,L_F},
  \ell_{C,1},\ldots,\ell_{C,L_C})
 \label{eq:complete-integration-momenta}
\end{equation}
be the complete set of remaining integration momenta.  A cut family has the
form
\begin{align}
 I_{\mathcal F}^{(D)}(\boldsymbol\nu)
 :={}&
 \int
 \prod_{\rho=1}^{L}
 \frac{\dd^D\lambda_\rho}{i\pi^{D/2}}\,
 \mathcal N(\boldsymbol\lambda)
 \prod_{c\in C}
 \mathcal C_{\xi_c}^{(\nu_c)}(\Delta_c;q_c)
 \prod_{j\in O}
 \Delta_j^{-\nu_j},
 \label{eq:cut-family-integral}
\end{align}
where
\begin{equation}
 L=(m-1)+L_F+L_C.
 \label{eq:total-integration-count}
\end{equation}
The ordinary \(i0\) labels are suppressed in the polynomial notation of
Eq.~\eqref{eq:cut-family-integral}, but remain fixed by the causal
classification below.  For an ordinary slot, a positive index denotes a
denominator and a nonpositive index denotes its absence or a numerator.
For a designated cut slot, the family is extended by the rule
\begin{equation}
 I_{\mathcal F}^{(D)}(\nu_1,\ldots,\nu_N)=0
 \qquad
 \text{if}\qquad
 \nu_c\leq0
 \quad\text{for any }c\in C.
 \label{eq:cut-family-condition}
\end{equation}
Equation~\eqref{eq:cut-family-condition} is the reverse-unitarity
no-pinching condition.  It does not identify a cut integral with the
corresponding uncut integral.

To classify an ordinary denominator \(\Delta\), let
\begin{equation}
 \mathscr L_F(\Delta)
 :=
 \{\ell_{F,a}\mid\Delta\text{ depends on }\ell_{F,a}\},
 \qquad
 \mathscr L_C(\Delta)
 :=
 \{\ell_{C,b}\mid\Delta\text{ depends on }\ell_{C,b}\}.
 \label{eq:virtual-dependence-sets}
\end{equation}
Its causal ownership is
\begin{equation}
 \chi(\Delta)
 =
 \begin{cases}
  F,
  &
  \mathscr L_F(\Delta)\neq\varnothing,
  \quad
  \mathscr L_C(\Delta)=\varnothing,
  \\[1mm]
  C,
  &
  \mathscr L_F(\Delta)=\varnothing,
  \quad
  \mathscr L_C(\Delta)\neq\varnothing,
  \\[1mm]
  S,
  &
  \mathscr L_F(\Delta)=\mathscr L_C(\Delta)=\varnothing,
  \\[1mm]
  M,
  &
  \mathscr L_F(\Delta)\neq\varnothing,
  \quad
  \mathscr L_C(\Delta)\neq\varnothing.
 \end{cases}
 \label{eq:causal-ownership}
\end{equation}
A denominator in class \(F\) carries \(+i0\), while a denominator in class
\(C\) carries \(-i0\).  The present construction does not assign a contour to
an active denominator in class \(M\).  Such a denominator is rejected unless
a separate contour derivation is supplied.  A mixed forward--conjugate scalar
product may be represented by an auxiliary family slot, but its index must
remain nonpositive in every target and physical master.

A denominator in class \(S\) depends only on external and real
phase-space momenta.  Let \(\Omega_m^\circ\) denote the open physical
phase-space domain defined by the positive-energy cuts.  If
\begin{equation}
 \Delta(\kappa)\neq0
 \qquad
 \text{for every }\kappa\in\Omega_m^\circ,
 \label{eq:no-interior-zero}
\end{equation}
then \(\Delta\) has a fixed sign on each connected physical chamber.  If it
also remains nonzero on the closure of that chamber, its \(i0\) prescription
may be omitted pointwise.

When \(\Delta\) vanishes only on declared soft or collinear boundary strata,
Eq.~\eqref{eq:no-interior-zero} is not by itself sufficient.  The complete
cut-integrand term must first be resolved into boundary charts
\(\rho_a\geq0\) in which
\begin{equation}
 \dd\Phi_m\,\mathcal I_{\rm term}
 =
 \dd^r\rho\,
 \prod_{a=1}^{r}
 \rho_a^{A_a+B_a\eps}\,
 U(\boldsymbol\rho,\eps),
 \qquad
 U(\boldsymbol0,\eps)\neq0,
 \label{eq:boundary-meromorphic-chart}
\end{equation}
with \(U\) analytic in the chart and with a nonempty domain of
\(\eps\) for which
\begin{equation}
 \operatorname{Re}(A_a+B_a\eps)>-1
 \qquad
 \text{for every }a.
 \label{eq:boundary-absolute-convergence}
\end{equation}
In that domain the integral is absolutely convergent, and its continuation
defines a unique meromorphic family in \(\eps\).  Only after this
term-level certificate may source factors with opposite prescriptions be
combined according to
\begin{equation}
 \frac{1}{(\Delta+i0)^a(\Delta-i0)^b}
 \longrightarrow
 \frac{1}{\Delta^{a+b}},
 \label{eq:shared-denominator-meromorphic-combination}
\end{equation}
where the equality is understood for the dimensionally regulated
meromorphic integral, not as an unrestricted product of distributions at
\(\Delta=0\).

If a class-\(S\) denominator vanishes on an interior hypersurface, changes
sign in the open physical domain, or lacks the endpoint certificate above,
the prescription-free family is rejected.  The present calculation does not
replace such a case by a guessed \(i0\), a global discontinuity, or a
numerical contour prescription.  Appendix~\ref{app:fixed-sign} gives the
exact no-interior-zero criterion used for the massless two-beam
kinematics considered here.

\subsection{Cut-preserving partial fractions and complete families}
\label{subsec:partial-fraction-families}

The literal propagators of one ordered interference need not be independent
as polynomials in the scalar products of
\(\boldsymbol\lambda\).  Let \(\mathbb K\) be the field of exact rational
functions of the external invariants and \(D\).  A linear dependence has the
form
\begin{equation}
 c_0+\sum_{j=1}^{N}c_j\Delta_j=0,
 \qquad
 c_j\in\mathbb K,
 \label{eq:denominator-linear-relation}
\end{equation}
with the \(c_j\) independent of all integration momenta and not all zero.
Multivariate partial fractions decompose a product containing such
denominators into terms with linearly independent denominator subsets
\cite{Feng:2012iq}.

For a cut integral, the decomposition is performed in the family defined by
Eq.~\eqref{eq:cut-family-condition}.  Every retained term satisfies
\begin{equation}
 \nu_{\alpha c}>0
 \qquad
 \text{for every physical cut }c\in C.
 \label{eq:partial-fraction-cut-positivity}
\end{equation}
A term with \(\nu_{\alpha c}\leq0\) is the zero element of the fixed-cut
family and is projected out.  Throughout this algebra, each cut retains:

\begin{enumerate}
 \item its denominator polynomial;
 \item its slot identity;
 \item its energy orientation \(\xi_c\);
 \item its positive cut power.
\end{enumerate}

A cut denominator is never merged with an ordinary propagator having the
same polynomial.  After the decomposition, the retained terms obey the exact
identity
\begin{equation}
 I_{\rm literal}
 =
 \sum_{\alpha}
 I_{\alpha}^{\rm independent}
 \qquad
 \text{within the fixed-cut family}.
 \label{eq:cut-aware-partial-fraction-identity}
\end{equation}
Thus partial fractioning changes the denominator basis but not the physical
cut content.

To define completeness, choose \(E\) independent external momenta
\begin{equation}
 \boldsymbol p=(p_1,\ldots,p_E)
 \label{eq:independent-external-basis}
\end{equation}
after all external kinematic relations have been imposed.  For the \(L\)
integration momenta in Eq.~\eqref{eq:complete-integration-momenta}, the
independent loop-dependent scalar products are
\begin{equation}
 \mathcal S_L
 =
 \{
  \lambda_r\cdot\lambda_s
  \mid 1\leq r\leq s\leq L
 \}
 \cup
 \{
  \lambda_r\cdot p_a
  \mid
  1\leq r\leq L,\ 1\leq a\leq E
 \}.
 \label{eq:integration-scalar-product-set}
\end{equation}
Their number is
\begin{equation}
 N_{\rm sp}
 =
 \frac{L(L+1)}{2}+LE.
 \label{eq:number-of-integration-scalar-products}
\end{equation}
Write
\begin{equation}
 \Delta_j
 =
 d_{j0}
 +
 \sum_{\alpha=1}^{N_{\rm sp}}
 A_{j\alpha}\,\mathcal S_{L,\alpha},
 \qquad
 d_{j0}\in\mathbb K.
 \label{eq:denominator-scalar-product-matrix}
\end{equation}
A denominator list is complete when its loop-dependent coefficient matrix
has rank
\begin{equation}
 \operatorname{rank}_{\mathbb K}A=N_{\rm sp}.
 \label{eq:complete-family-rank}
\end{equation}
After partial fractioning, each independent literal subset is extended, when
necessary, by auxiliary inverse propagators until
Eq.~\eqref{eq:complete-family-rank} holds.  The construction therefore
proceeds in the order
\begin{equation}
 \text{literal propagators}
 \longrightarrow
 \text{fixed-cut partial fractions}
 \longrightarrow
 \text{independent literal subsets}
 \longrightarrow
 \text{complete scalar-product families}.
 \label{eq:family-construction-order}
\end{equation}

The physical cuts remain fixed slots in every completed family.  An
auxiliary denominator that later acquires a positive index must satisfy the
same causal classification as a literal propagator.  In particular, an
auxiliary class-\(M\) denominator may represent a cross scalar product such
as \(\ell_F\cdot\ell_C\) only with a nonpositive index.  A class-\(S\)
auxiliary denominator may become active only after the no-interior-zero and,
where required, endpoint-meromorphy conditions have been established.

\subsection{BMHV tensor numerators and dimension recurrences}
\label{subsec:bmhv-dimension-recurrence}

Polarized traces are evaluated in the BMHV scheme
\cite{Breitenlohner:1977hr}.  The metric and each integration momentum split
as
\begin{equation}
 g_D^{\mu\nu}
 =
 \bar g^{\mu\nu}
 +
 \widehat g^{\mu\nu},
 \qquad
 \lambda_r^\mu
 =
 \bar\lambda_r^\mu
 +
 \widehat\lambda_r^\mu,
 \qquad
 \bar g^\mu{}_\mu=4,
 \qquad
 \widehat g^\mu{}_\mu=D-4.
 \label{eq:bmhv-split-main}
\end{equation}
All external hadronic momenta, observed hard-parton momenta, collinear
directions, and physical spin vectors are four dimensional.  Hence
evanescent scalar products occur only among integration momenta.  It is
convenient to define the evanescent Gram variables
\begin{equation}
 \mu_{rs}
 :=
 -\widehat\lambda_r\cdot\widehat\lambda_s.
 \label{eq:evanescent-gram-variables}
\end{equation}

After the Dirac and polarization algebra, the numerator may be decomposed as
\begin{equation}
 \mathcal N_D
 =
 \sum_{r,\alpha}
 c_{r\alpha}(D,\boldsymbol p,\boldsymbol S)\,
 \mathcal E_r(\boldsymbol\mu)\,
 \mathcal T_\alpha
 (\boldsymbol\lambda,\boldsymbol p,\boldsymbol S),
 \label{eq:bmhv-numerator-decomposition}
\end{equation}
where:

\begin{itemize}
 \item \(\mathcal E_r\) is homogeneous of degree \(r\) in the variables
 \(\mu_{rs}\), and therefore has total evanescent tensor rank \(2r\);
 \item \(\mathcal T_\alpha\) contains only ordinary scalar products and
 contractions of integration momenta with four-dimensional external vectors;
 \item \(c_{r\alpha}\) contains the explicit factors of
 \(D=4-2\eps\) generated by the original Dirac and polarization algebra.
\end{itemize}

Let \(\mathcal I_{\boldsymbol\nu}^{(d)}[\mathcal N]\) denote the normalized
scalar family with integration dimension \(d\) and numerator
\(\mathcal N\).  The normalized evanescent Gram moments have the form
\begin{equation}
 \mathcal I_{\boldsymbol\nu}^{(D)}
 \bigl[
  \mathcal E_r\,\mathcal T_\alpha
 \bigr]
 =
 \sum_{\beta}
 \mathcal G_{r\alpha\beta}(D,\boldsymbol p)\,
 \mathcal I_{\boldsymbol\nu+\boldsymbol\delta_\beta}^{(D+2r)}
 \bigl[
  \mathcal T_{\alpha,\beta}
 \bigr],
 \label{eq:evanescent-dimension-shift}
\end{equation}
where the coefficients
\(\mathcal G_{r\alpha\beta}\) are fixed by the evanescent Gram-moment
normalization.  Equation~\eqref{eq:evanescent-dimension-shift} shifts the
integration dimension of the scalar integral.  It does not replace the
explicit \(D\) appearing in \(c_{r\alpha}(D,\boldsymbol p,\boldsymbol S)\)
by \(D+2r\).

The remaining physical tensor numerator must be reduced before the shifted
scalar integrals are lowered.  For example,
\begin{equation}
 \mathcal I_{\boldsymbol\nu}^{(D+2r)}
 \bigl[
  \lambda_{a_1}^{\mu_1}\cdots
  \lambda_{a_R}^{\mu_R}
 \bigr]
 =
 \sum_{\gamma}
 \mathcal T_\gamma^{\mu_1\cdots\mu_R}
 (\boldsymbol p,g_{D+2r})\,
 I_{\gamma,\boldsymbol\nu}^{(D+2r)}.
 \label{eq:shifted-dimensional-tensor-reduction}
\end{equation}
Contractions such as
\(\lambda_r\cdot S_{AT}\) and
\(\lambda_r\cdot S_{hT}\) are therefore part of the tensor numerator in
Eq.~\eqref{eq:shifted-dimensional-tensor-reduction}; they are not scalar
coefficients multiplying a GLI.  The tensor projectors in this step use the
integration dimension \(D+2r\), while the external spin vectors remain
four dimensional.

After tensor reduction, Tarasov dimension recurrences
\cite{Tarasov:1996br} express the shifted scalar integrals in the original
dimension:
\begin{equation}
 I_{\gamma,\boldsymbol\nu}^{(D+2r)}
 =
 \sum_{\beta}
 \mathcal R_{\gamma\beta}^{(r)}
 (D,\boldsymbol p)\,
 I_{\beta}^{(D)}.
 \label{eq:tarasov-dimensional-lowering}
\end{equation}
The same physical cut slots and energy orientations are retained throughout
Eqs.~\eqref{eq:evanescent-dimension-shift}--
\eqref{eq:tarasov-dimensional-lowering}.  After each recurrence, every term
with a nonpositive physical cut index is set to zero according to
Eq.~\eqref{eq:cut-family-condition}.

The final result submitted to scalar IBP reduction has the form
\begin{equation}
 \mathcal W_{ij}^{\mathsf P}
 =
 \sum_{\beta}
 C_{ij,\beta}^{\mathsf P}
 (D,\boldsymbol p,\boldsymbol S)\,
 I_{\beta}^{(D)},
 \label{eq:final-scalar-family-decomposition}
\end{equation}
where every coefficient
\(C_{ij,\beta}^{\mathsf P}\) is exact and contains no integration momentum,
no evanescent scalar product, and no unreduced tensor contraction.  A
residual dependence on any component of
\(\boldsymbol\lambda\) means that the scalar family decomposition is
incomplete and the calculation must stop.  Appendix
\ref{app:bmhv-dimension-shift} gives the detailed normalization and the
rank-one and rank-two identities used in this reduction.

## Sources sent to Pro

- [manuscript_03_cut_families.tex](Sources/06_manuscript_03_cut_families/manuscript_03_cut_families.tex)
