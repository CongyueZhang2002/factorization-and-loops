# Manuscript D Bmhv Dimension Shift

## Question

The attached file is the BMHV and dimension-recurrence appendix. Review and
rewrite this appendix only.

Return a short critique and compilable replacement LaTeX. Check the sign and
Pochhammer factor in the one-loop identity with the normalized
d^D ell/(i pi^(D/2)) measure. State exactly which assumptions on external
vectors and the integrand are required. For several loops, do not present a
symbolic comma as an equation: give a mathematically meaningful statement of
the topology-dependent Tarasov operator for pure and mixed evanescent scalar
products. Explain how cut slots are retained and why the Dirac-algebra
coefficients remain at D=4-2 epsilon while only scalar integrals are shifted.
Do not imply that a universal replacement handles arbitrary mixed
evanescent contractions. Do not rewrite another appendix or section.

## Pro response

Short critique

The one-loop coefficient in the draft is correct:

(−ϵ)
r
	​

=
Γ(−ϵ)
Γ(r−ϵ)
	​

.

With μ
ℓ
2
	​

=−
ℓ
2
 and the normalized measure
d
D
ℓ/(iπ
D/2
), there is no additional factor of
(−1)
r
 or π
r
. The draft does not state the assumptions needed for this identity: four-dimensional external vectors, no residual explicit evanescent numerator in F, a quadratic family with a nonsingular loop Gaussian, and meromorphic continuation from a common convergence domain. 

D_bmhv_dimension_shift

The multiloop equation is not mathematically well formed:

I
F
(D)
	​

[P
2r
	​

]=D
P
2r
	​

	​

(ν,D),I
F
(D+2r)
	​

.

The comma does not define an operator action, and neither the mixed Gram moments nor the index-raising coefficients are specified. 

D_bmhv_dimension_shift

At several loops, a mixed contraction
−
ℓ
i
	​

⋅
ℓ
j
	​

 cannot be replaced by a universal number. Its dimension-shift operator depends on the inverse loop quadratic-form matrix of the chosen family. The replacement gives a source-generating formula and explicit rank-two mixed moments.

The draft does not distinguish the original Dirac-algebra dimension D from the temporary scalar-integration dimension D+2r. Factors such as D−3 produced by the BMHV trace remain evaluated at D=4−2ϵ; only the integral and its tensor projectors use D+2r.

Cut preservation needs an explicit argument. The dimension recurrence is applied to each causal boundary value before taking the oriented discontinuity. Cut identity and energy orientation remain fixed; raising may increase a cut power, while every term with a nonpositive cut index after lowering is zero in the fixed-cut family.

The lowering recurrence is valid only for a complete family at generic kinematics where the Gram or Cayley factors used by that recurrence do not vanish. Singular kinematic limits require a separately derived relation or a controlled limit.

LaTeX
\section{BMHV evanescent numerators and dimension recurrences}
\label{app:bmhv-dimension-shift}

\subsection{Evanescent scalar products and the domain of the identities}

The BMHV metric decomposition is
\begin{equation}
 g_D^{\mu\nu}
 =
 \bar g^{\mu\nu}
 +
 \widehat g^{\mu\nu},
 \qquad
 \bar g^{\mu\rho}\widehat g_{\rho}{}^\nu=0,
 \qquad
 \bar g^\mu{}_\mu=4,
 \qquad
 \widehat g^\mu{}_\mu=D-4=-2\eps.
 \label{eq:bmhv-orthogonal-metrics}
\end{equation}
For each integration momentum,
\begin{equation}
 \ell_i^\mu
 =
 \bar\ell_i^\mu+\widehat\ell_i^\mu,
 \label{eq:bmhv-loop-split-appendix}
\end{equation}
and we define the symmetric evanescent Gram variables
\begin{equation}
 \mu_{ij}
 :=
 -\widehat\ell_i\cdot\widehat\ell_j,
 \qquad
 \mu_{ij}=\mu_{ji},
 \qquad
 \mu_{ii}\equiv\mu_i^2.
 \label{eq:evanescent-gram-definition}
\end{equation}
The minus sign in Eq.~\eqref{eq:evanescent-gram-definition} makes
\(\mu_i^2\) the positive Euclidean squared length after Wick rotation.

The dimension recurrences below assume that:

\begin{enumerate}
 \item all external momenta, light-cone vectors, and physical spin vectors
 are four dimensional, so that their hatted components vanish;

 \item the denominator family is quadratic in the integration momenta and
 has a nonsingular loop quadratic-form matrix at generic Schwinger
 parameters;

 \item after the displayed polynomial in the \(\mu_{ij}\) has been removed,
 the remaining numerator contains no additional explicit hatted scalar
 product;

 \item every ordinary causal prescription and every oriented cut is fixed
 before the recurrence is applied;

 \item the identities are first established where the Schwinger integrals
 and Gaussian moments converge and are then continued meromorphically in
 \(D\), the propagator powers, and the external invariants.
\end{enumerate}

The remaining numerator may contain contractions of integration momenta with
four-dimensional external vectors.  In that case the right-hand side of the
dimension-shift identity is a tensor integral in the shifted integration
dimension and must be tensor-reduced there before dimensional lowering.

\subsection{One-loop identity}

Let
\begin{equation}
 d_\perp:=D-4=-2\eps,
 \qquad
 \beta:=\frac{d_\perp}{2}=-\eps.
 \label{eq:evanescent-dimension-beta}
\end{equation}
For a one-loop integrand \(F^{(d)}(\ell)\) satisfying the assumptions above,
the exact normalized identity is
\begin{equation}
 \boxed{
 \int\frac{\dd^D\ell}{i\pi^{D/2}}\,
 (\mu_\ell^2)^r F^{(D)}(\ell)
 =
 (-\eps)_r
 \int\frac{\dd^{D+2r}\ell}
          {i\pi^{(D+2r)/2}}\,
 F^{(D+2r)}(\ell)
 },
 \qquad
 r\in\mathbb Z_{\geq0},
 \label{eq:one-loop-dimension-shift}
\end{equation}
where
\begin{equation}
 (a)_r
 :=
 \frac{\Gamma(a+r)}{\Gamma(a)}
 =
 a(a+1)\cdots(a+r-1),
 \qquad
 (a)_0=1.
 \label{eq:pochhammer-definition-bmhv}
\end{equation}
In particular,
\begin{equation}
 (-\eps)_1=-\eps,
 \qquad
 (-\eps)_2=(-\eps)(1-\eps).
 \label{eq:first-evanescent-moments}
\end{equation}

To verify the normalization, introduce a positive Schwinger quadratic form
\(A\) after Wick rotation.  The analytically continued evanescent Gaussian
moment is
\begin{equation}
 \int
 \frac{\dd^{d_\perp}u}{\pi^{d_\perp/2}}\,
 (u^2)^r e^{-A u^2}
 =
 (\beta)_r A^{-\beta-r}.
 \label{eq:evanescent-gaussian-moment}
\end{equation}
Combining Eq.~\eqref{eq:evanescent-gaussian-moment} with the
four-dimensional Gaussian gives
\[
 A^{-2}A^{-\beta-r}
 =
 A^{-(D+2r)/2}.
\]
The normalization by \(i\pi^{d/2}\) on both sides of
Eq.~\eqref{eq:one-loop-dimension-shift} removes any additional power of
\(\pi\), and
\[
 (\beta)_r=(-\eps)_r.
\]
There is no extra factor \((-1)^r\) because the numerator is
\(\mu_\ell^2=-\widehat\ell^{\,2}\).  Had the numerator instead been written
as \((\widehat\ell^{\,2})^r\), its coefficient would be
\((-1)^r(-\eps)_r\).

The notation \(F^{(D+2r)}\) means that the same denominator polynomials,
masses, causal boundary values, and cut slots are interpreted with the
integration momentum in \(D+2r\) dimensions.  External vectors remain in
the same four-dimensional subspace.

\subsection{Multiloop Gaussian moments}

Consider an \(L\)-loop complete family with denominator powers
\begin{equation}
 \boldsymbol\nu=(\nu_1,\ldots,\nu_N).
 \label{eq:multiloop-index-vector}
\end{equation}
For a fixed choice of ordinary causal boundary values, introduce Schwinger
parameters
\begin{equation}
 \boldsymbol\alpha=(\alpha_1,\ldots,\alpha_N).
 \label{eq:schwinger-parameter-vector}
\end{equation}
After completing the square, the denominator exponent has the form
\begin{equation}
 \sum_{j=1}^{N}\alpha_j\Delta_j
 =
 \sum_{a,b=1}^{L}
 \ell_a\cdot A_{ab}(\boldsymbol\alpha)\ell_b
 +
 2\sum_{a=1}^{L}
 \ell_a\cdot B_a(\boldsymbol\alpha)
 +
 C(\boldsymbol\alpha),
 \label{eq:loop-quadratic-form}
\end{equation}
where \(A(\boldsymbol\alpha)\) is a symmetric \(L\times L\) matrix.  Since
all external vectors are four dimensional,
\begin{equation}
 \widehat B_a(\boldsymbol\alpha)=0.
 \label{eq:no-evanescent-linear-source}
\end{equation}
Define
\begin{equation}
 \mathcal U(\boldsymbol\alpha)
 :=
 \det A(\boldsymbol\alpha).
 \label{eq:U-from-loop-matrix}
\end{equation}

For formal sources \(j_{ab}=j_{ba}\), \(1\leq a\leq b\leq L\), define the
symmetric matrix
\begin{equation}
 S_{aa}(\boldsymbol j):=j_{aa},
 \qquad
 S_{ab}(\boldsymbol j)
 =
 S_{ba}(\boldsymbol j)
 :=
 \frac{j_{ab}}{2}
 \quad(a<b).
 \label{eq:evanescent-source-matrix}
\end{equation}
Then
\begin{equation}
 \sum_{a,b=1}^{L}
 u_a\cdot S_{ab}(\boldsymbol j)u_b
 =
 \sum_{a=1}^{L}j_{aa}u_a^2
 +
 \sum_{a<b}j_{ab}u_a\cdot u_b.
 \label{eq:evanescent-source-contraction}
\end{equation}
The normalized generating function for the evanescent Gaussian moments is
\begin{equation}
 \mathscr G_A(\boldsymbol j;\beta)
 :=
 \det\!\left[
  \boldsymbol 1-A^{-1}S(\boldsymbol j)
 \right]^{-\beta}.
 \label{eq:evanescent-moment-generating-function}
\end{equation}

Let \(P_r(\boldsymbol\mu)\) be homogeneous of degree \(r\) in the variables
\(\mu_{ab}\), so that it has mass dimension \(2r\).  Its normalized Gaussian
moment is
\begin{equation}
 \mathscr M_{P_r}(A;\beta)
 :=
 \left.
 P_r\!\left(
  \mu_{ab}\longmapsto
  \frac{\partial}{\partial j_{ab}}
 \right)
 \mathscr G_A(\boldsymbol j;\beta)
 \right|_{\boldsymbol j=0}.
 \label{eq:general-evanescent-gaussian-moment}
\end{equation}
Since every derivative of
Eq.~\eqref{eq:evanescent-moment-generating-function} produces one entry of
\(A^{-1}\), there is a polynomial
\(\mathcal Q_{\mathcal F,P_r}(\boldsymbol\alpha;\beta)\) such that
\begin{equation}
 \mathscr M_{P_r}(A;\beta)
 =
 \frac{
  \mathcal Q_{\mathcal F,P_r}
  (\boldsymbol\alpha;\beta)
 }{
  \mathcal U(\boldsymbol\alpha)^r
 }.
 \label{eq:evanescent-moment-cofactor-polynomial}
\end{equation}
The polynomial \(\mathcal Q_{\mathcal F,P_r}\) depends on the loop
quadratic-form matrix of the chosen family.  It is therefore
topology-dependent.

For example,
\begin{equation}
 \mathscr M_{\mu_{ij}}(A;\beta)
 =
 \beta(A^{-1})_{ij}
 =
 \beta\,
 \frac{(\operatorname{adj}A)_{ij}}{\mathcal U},
 \label{eq:single-mixed-evanescent-moment}
\end{equation}
whereas
\begin{align}
 \mathscr M_{\mu_{ij}\mu_{kl}}(A;\beta)
 ={}&
 \beta^2
 (A^{-1})_{ij}(A^{-1})_{kl}
 \notag\\
 &+
 \frac{\beta}{2}
 \left[
  (A^{-1})_{ik}(A^{-1})_{jl}
  +
  (A^{-1})_{il}(A^{-1})_{jk}
 \right].
 \label{eq:double-mixed-evanescent-moment}
\end{align}
Equations~\eqref{eq:single-mixed-evanescent-moment} and
\eqref{eq:double-mixed-evanescent-moment} show explicitly why a mixed
contraction cannot be replaced by a universal scalar.  Its recurrence
depends on the full matrix \(A(\boldsymbol\alpha)\).

For \(L=1\), Eq.~\eqref{eq:evanescent-moment-generating-function} reduces to
\begin{equation}
 \mathscr G_A(j;\beta)
 =
 \left(1-\frac{j}{A}\right)^{-\beta}.
 \label{eq:one-loop-generating-function}
\end{equation}
Hence
\begin{equation}
 \mathscr M_{(\mu^2)^r}(A;\beta)
 =
 (\beta)_r A^{-r},
 \label{eq:one-loop-moment-from-generating-function}
\end{equation}
which reproduces Eq.~\eqref{eq:one-loop-dimension-shift}.

\subsection{Topology-dependent index-raising operator}

Expand the cofactor polynomial as
\begin{equation}
 \mathcal Q_{\mathcal F,P_r}
 (\boldsymbol\alpha;\beta)
 =
 \sum_{\boldsymbol m\in\mathcal M_{P_r}}
 q_{\boldsymbol m}(\beta)\,
 \boldsymbol\alpha^{\boldsymbol m},
 \qquad
 \boldsymbol\alpha^{\boldsymbol m}
 :=
 \prod_{j=1}^{N}\alpha_j^{m_j}.
 \label{eq:cofactor-polynomial-expansion}
\end{equation}
For
\begin{equation}
 \boldsymbol m=(m_1,\ldots,m_N)
 \in\mathbb Z_{\geq0}^{N},
 \label{eq:index-raising-multiindex}
\end{equation}
define the normalized index-raising operator by
\begin{equation}
 \mathsf R_{\boldsymbol m}
 I_{\mathcal F}^{(d)}(\boldsymbol\nu)
 :=
 \left[
  \prod_{j=1}^{N}(\nu_j)_{m_j}
 \right]
 I_{\mathcal F}^{(d)}
 (\boldsymbol\nu+\boldsymbol m).
 \label{eq:normalized-index-raising-operator}
\end{equation}
This follows directly from
\begin{equation}
 \frac{1}{\Gamma(\nu_j)}
 \int_0^\infty
 \dd\alpha_j\,
 \alpha_j^{\nu_j-1+m_j}
 e^{-\alpha_j\Delta_j}
 =
 (\nu_j)_{m_j}
 \Delta_j^{-\nu_j-m_j},
 \label{eq:schwinger-index-raising}
\end{equation}
initially in a convergence domain and subsequently by analytic
continuation.

The topology-dependent operator associated with
\(P_r(\boldsymbol\mu)\) is
\begin{equation}
 \widehat{\mathcal Q}_{\mathcal F,P_r}
 (\boldsymbol\nu;\beta)
 :=
 \sum_{\boldsymbol m\in\mathcal M_{P_r}}
 q_{\boldsymbol m}(\beta)\,
 \mathsf R_{\boldsymbol m}.
 \label{eq:topology-dependent-evanescent-operator}
\end{equation}
For any remaining numerator
\(\mathcal T\) that contains no explicit hatted scalar product, the exact
multiloop identity is
\begin{equation}
 \boxed{
 I_{\mathcal F}^{(D)}
 \bigl[
  P_r(\boldsymbol\mu)\,\mathcal T;
  \boldsymbol\nu
 \bigr]
 =
 \widehat{\mathcal Q}_{\mathcal F,P_r}
 (\boldsymbol\nu;-\eps)\,
 I_{\mathcal F}^{(D+2r)}
 \bigl[
  \mathcal T;
  \boldsymbol\nu
 \bigr]
 }.
 \label{eq:multiloop-evanescent-shift}
\end{equation}
Equation~\eqref{eq:multiloop-evanescent-shift} is a family-dependent
Tarasov dimension-shift identity.  It applies equally to pure powers
\((\mu_i^2)^r\) and to mixed monomials such as
\(\mu_{ij}\mu_{kl}\), but the operator must be constructed from
Eqs.~\eqref{eq:evanescent-moment-generating-function}--
\eqref{eq:topology-dependent-evanescent-operator} for the actual family.
There is no universal replacement rule for an arbitrary mixed evanescent
monomial.

\subsection{Physical tensor numerators and dimensional lowering}

After the BMHV Dirac algebra, a projected interference may be written as
\begin{equation}
 \mathcal A
 =
 \sum_{r,\alpha}
 c_{r\alpha}
 (D,\boldsymbol p,\boldsymbol S)\,
 I_{\mathcal F}^{(D)}
 \bigl[
  P_r(\boldsymbol\mu)\,
  \mathcal T_\alpha;
  \boldsymbol\nu
 \bigr],
 \label{eq:bmhv-amplitude-before-shift}
\end{equation}
where \(c_{r\alpha}\) contains every explicit factor of
\(D=4-2\eps\) generated by the original Dirac and polarization algebra.
Using Eq.~\eqref{eq:multiloop-evanescent-shift},
\begin{equation}
 \mathcal A
 =
 \sum_{r,\alpha}
 c_{r\alpha}
 (D,\boldsymbol p,\boldsymbol S)\,
 \widehat{\mathcal Q}_{\mathcal F,P_r}
 (\boldsymbol\nu;-\eps)\,
 I_{\mathcal F}^{(D+2r)}
 \bigl[
  \mathcal T_\alpha;
  \boldsymbol\nu
 \bigr].
 \label{eq:bmhv-amplitude-after-shift}
\end{equation}

If \(\mathcal T_\alpha\) contains contractions of integration momenta with
four-dimensional vectors, it must be tensor-reduced in the shifted
integration dimension
\begin{equation}
 d_r:=D+2r.
 \label{eq:shifted-integration-dimension}
\end{equation}
Schematically,
\begin{equation}
 I_{\mathcal F}^{(d_r)}
 \bigl[
  \mathcal T_\alpha;
  \boldsymbol\nu
 \bigr]
 =
 \sum_{\gamma}
 \mathcal P_{\alpha\gamma}
 (d_r,\boldsymbol p,\boldsymbol S)\,
 I_{\mathcal F}^{(d_r)}
 (\boldsymbol\nu+\boldsymbol\rho_{\alpha\gamma}),
 \label{eq:shifted-dimensional-tensor-reduction}
\end{equation}
where the tensor projectors
\(\mathcal P_{\alpha\gamma}\) use the metric in dimension \(d_r\), while all
external momenta and physical spin vectors remain in the fixed
four-dimensional subspace.

At generic external kinematics, a complete family admits a dimensional
lowering relation of the form
\begin{equation}
 I_{\mathcal F}^{(D+2r)}(\boldsymbol\nu)
 =
 \mathscr T_{\mathcal F}^{[r]}
 (D,\boldsymbol\nu,\boldsymbol s)\,
 I_{\mathcal F}^{(D)}(\boldsymbol\nu),
 \label{eq:tarasov-lowering}
\end{equation}
where
\begin{equation}
 \mathscr T_{\mathcal F}^{[r]}
 (D,\boldsymbol\nu,\boldsymbol s)
 =
 \sum_{\boldsymbol\delta\in\Delta_r}
 T_{\boldsymbol\delta}^{[r]}
 (D,\boldsymbol\nu,\boldsymbol s)\,
 \mathsf E^{\boldsymbol\delta},
 \qquad
 \mathsf E^{\boldsymbol\delta}
 I_{\mathcal F}^{(D)}(\boldsymbol\nu)
 :=
 I_{\mathcal F}^{(D)}
 (\boldsymbol\nu+\boldsymbol\delta).
 \label{eq:tarasov-lowering-operator}
\end{equation}
The coefficients
\(T_{\boldsymbol\delta}^{[r]}\) are rational functions of \(D\), the
indices, and the external invariants
\(\boldsymbol s\).  They depend on the chosen complete family and may contain
inverse Gram or Cayley determinants.  Equations
\eqref{eq:tarasov-lowering} and
\eqref{eq:tarasov-lowering-operator} are therefore statements at generic
kinematics.  If one of the required determinants vanishes at a physical
boundary, that limit must be taken only after the generic recurrence has
been established, or a separate recurrence must be derived for that
kinematic locus.

The factors
\[
 c_{r\alpha}(D,\boldsymbol p,\boldsymbol S)
\]
in Eq.~\eqref{eq:bmhv-amplitude-after-shift} remain evaluated at
\begin{equation}
 D=4-2\eps.
 \label{eq:dirac-dimension-remains-D}
\end{equation}
They are not changed to
\(c_{r\alpha}(D+2r,\boldsymbol p,\boldsymbol S)\).
The shift \(D\to D+2r\) is an identity for the integration measure and the
scalar or tensor integral after the Dirac algebra has been completed; it is
not a repetition of the Dirac algebra in a different spacetime dimension.

\subsection{Retention of physical cuts}

The preceding identities are first applied to each fixed causal
boundary-value integral.  For a cut slot \(c\), the oriented cut is then
formed from the same difference of boundary values as in
Eq.~\eqref{eq:normalized-cut-operator}.  Since the Schwinger-parameter
operator is identical for the two causal signs, it commutes with the
oriented discontinuity:
\begin{equation}
 \widehat{\mathcal Q}_{\mathcal F,P_r}
 \left[
  \mathcal P_{-}^{(\nu_c)}
  -
  \mathcal P_{+}^{(\nu_c)}
 \right]
 =
 \widehat{\mathcal Q}_{\mathcal F,P_r}
 \mathcal P_{-}^{(\nu_c)}
 -
 \widehat{\mathcal Q}_{\mathcal F,P_r}
 \mathcal P_{+}^{(\nu_c)}.
 \label{eq:dimension-shift-commutes-with-cut}
\end{equation}
In particular, an index raising by \(m_c\) acts on a normalized cut slot as
\begin{equation}
 \mathsf R_{m_c}
 \mathcal C_{\xi_c}^{(\nu_c)}
 =
 (\nu_c)_{m_c}\,
 \mathcal C_{\xi_c}^{(\nu_c+m_c)}.
 \label{eq:cut-index-raising}
\end{equation}
The cut momentum, slot identity, and energy orientation \(\xi_c\) are
unchanged.

Dimensional lowering may shift indices in either direction.  The result is
projected back into the same fixed-cut family by
\begin{equation}
 I_{\mathcal F}^{(D)}
 (\nu_1,\ldots,\nu_N)
 =
 0
 \qquad
 \text{if}\qquad
 \nu_c\leq0
 \quad\text{for any physical cut }c.
 \label{eq:cut-positivity-after-dimensional-lowering}
\end{equation}
No recurrence is accepted if it changes the identity or energy orientation
of a physical cut.

After tensor reduction and dimensional lowering, the result must have the
form
\begin{equation}
 \mathcal A
 =
 \sum_\kappa
 C_\kappa(D,\boldsymbol p,\boldsymbol S)\,
 I_{\mathcal F,\kappa}^{(D)},
 \label{eq:final-bmhv-scalar-decomposition}
\end{equation}
where every coefficient \(C_\kappa\) is exact and contains no integration
momentum, no \(\mu_{ij}\), and no unreduced tensor contraction.  A residual
evanescent scalar product or a contraction such as
\(\ell_i\cdot S_{AT}\) in a scalar coefficient means that the tensor and
dimension recurrence has not been completed.

## Sources sent to Pro

- [manuscript_d_bmhv_dimension_shift.tex](Sources/08_manuscript_d_bmhv_dimension_shift/manuscript_d_bmhv_dimension_shift.tex)
