# Manuscript B Fixed Sign

## Question

The attached file is the fixed-sign theorem appendix for denominators built
only from two incoming massless beam momenta and future-directed massless
phase-space momenta. Review and rewrite this appendix only.

Return a short critique and compilable replacement LaTeX. Verify every
hypothesis, normalization, inequality, max-flow/min-cut statement, and claimed
attainment of the extrema. The theorem should provide a sufficient and
necessary fixed-sign test only if the displayed proof actually establishes
both directions; otherwise state its exact logical strength. Clarify that
zeros on the physical boundary are admitted and that the result does not
classify denominators containing virtual loop momenta. Do not rewrite another
appendix or section.

## Pro response

Short critique

The appendix reuses Q for the momentum flowing through the tested denominator, conflicting with the manuscript convention Q
2
=s+t+u for the inclusive recoil invariant. The replacement uses R for the tested linear combination.

The inequality

(k
b
	​

−K
A
	​

)
2
≤0

is true, but the draft merely asserts it. It requires a Sudakov decomposition of K
A
	​

 and the future-causal character of both K
A
	​

 and its complement. 

B_fixed_sign

The max-flow/min-cut argument is incomplete because the network, capacities, and cut capacities are not defined. The replacement supplies the exact network and shows that its finite-cut inequalities are precisely

z
A
	​

≤x
A
	​

.

The current conclusion is weaker than its own extremum claim. Once every μ
ij
	​

 is shown to be an attained boundary value, the conditions

μ
ij
	​

≥0 ∀i

=jorμ
ij
	​

≤0 ∀i

=j

are not merely sufficient: they are necessary and sufficient for a weak fixed sign on the full phase-space closure. 

B_fixed_sign

The original proof does not distinguish a weak fixed sign from absence of an interior zero. The replacement proves that, in the nonsoft and noncollinear interior, the flow weights may all be chosen strictly positive. Hence a weak one-sign set of μ
ij
	​

, not identically zero, gives a strict sign in the interior; any zeros are confined to the physical boundary.

The boundary attainment statement needs an explicit momentum sequence satisfying exact momentum conservation. The replacement provides one.

The theorem applies only to quadratic denominators formed from the two external beams and real on-shell final-state momenta. It does not classify denominators containing virtual loop momenta, mixed forward–conjugate loop dependence, or linear eikonal denominators.

LaTeX
\section{Exact fixed-sign test for non-virtual massless denominators}
\label{app:fixed-sign}

This appendix considers quadratic denominators whose momentum depends only on
the two physical incoming beams and on real on-shell final-state momenta.  It
does not apply to a denominator containing a virtual loop momentum.

\subsection{Physical domain and statement of the theorem}

Let \(n\geq2\), and let \(k_a\) and \(k_b\) be future-directed null incoming
momenta satisfying
\begin{equation}
 k_a^2=k_b^2=0,
 \qquad
 s:=2k_a\cdot k_b>0.
 \label{eq:sign-theorem-kinematics}
\end{equation}
Define
\begin{equation}
 P:=k_a+k_b,
 \qquad
 P^2=s.
 \label{eq:sign-theorem-total-momentum}
\end{equation}
The closure of the physical massless \(n\)-particle phase space is
\begin{equation}
 \overline{\Omega}_n(P)
 :=
 \left\{
  (p_1,\ldots,p_n)\ \middle|\
  p_i^2=0,\quad p_i^0\geq0,\quad
  \sum_{i=1}^{n}p_i=P
 \right\}.
 \label{eq:closed-massless-phase-space}
\end{equation}
Soft momenta and collinear configurations are included in
\(\overline{\Omega}_n(P)\).

The nonsoft and noncollinear interior used below is
\begin{align}
 \Omega_n^\circ(P)
 :=
 \Bigl\{
  (p_1,\ldots,p_n)\in\overline{\Omega}_n(P)
  \ \Bigm|\
  &p_i^0>0,\quad
  k_a\cdot p_i>0,\quad
  k_b\cdot p_i>0,
  \notag\\
  &p_i\cdot p_j>0
  \quad\text{for all }i\neq j
 \Bigr\}.
 \label{eq:open-massless-phase-space}
\end{align}

For real coefficients \(a,b,c_1,\ldots,c_n\), consider the momentum
\begin{equation}
 R
 :=
 ak_a+bk_b+\sum_{i=1}^{n}c_ip_i.
 \label{eq:sign-theorem-linear-combination}
\end{equation}
Momentum conservation makes the coefficient representation redundant:
\begin{equation}
 (a,b,c_1,\ldots,c_n)
 \longmapsto
 (a+\tau,b+\tau,c_1-\tau,\ldots,c_n-\tau)
 \label{eq:sign-theorem-coefficient-redundancy}
\end{equation}
leaves \(R\) unchanged for every \(\tau\in\mathbb R\).  The combinations
\begin{equation}
 A_i:=a+c_i,
 \qquad
 B_i:=b+c_i
 \label{eq:sign-theorem-invariant-coefficients}
\end{equation}
are invariant under Eq.~\eqref{eq:sign-theorem-coefficient-redundancy}.
For every ordered pair \(i\neq j\), define
\begin{equation}
 \mu_{ij}:=A_iB_j=(a+c_i)(b+c_j).
 \label{eq:sign-theorem-mu}
\end{equation}

\paragraph{Theorem.}
For every point of \(\overline{\Omega}_n(P)\),
\begin{equation}
 \min_{i\neq j}\mu_{ij}
 \leq
 \frac{R^2}{s}
 \leq
 \max_{i\neq j}\mu_{ij}.
 \label{eq:fixed-sign-bound}
\end{equation}
Both bounds are exact:
\begin{align}
 \min_{(p_1,\ldots,p_n)\in\overline{\Omega}_n(P)}
 \frac{R^2}{s}
 &=
 \min_{i\neq j}\mu_{ij},
 \notag\\
 \max_{(p_1,\ldots,p_n)\in\overline{\Omega}_n(P)}
 \frac{R^2}{s}
 &=
 \max_{i\neq j}\mu_{ij}.
 \label{eq:fixed-sign-exact-extrema}
\end{align}
Consequently,
\begin{align}
 R^2\geq0
 \quad\text{on }\overline{\Omega}_n(P)
 &\quad\Longleftrightarrow\quad
 \mu_{ij}\geq0
 \quad\text{for every }i\neq j,
 \label{eq:nonnegative-iff}\\
 R^2\leq0
 \quad\text{on }\overline{\Omega}_n(P)
 &\quad\Longleftrightarrow\quad
 \mu_{ij}\leq0
 \quad\text{for every }i\neq j.
 \label{eq:nonpositive-iff}
\end{align}
If all \(\mu_{ij}\geq0\) and at least one \(\mu_{ij}>0\), then
\begin{equation}
 R^2>0
 \qquad
 \text{throughout }\Omega_n^\circ(P).
 \label{eq:strictly-positive-interior}
\end{equation}
Similarly, if all \(\mu_{ij}\leq0\) and at least one
\(\mu_{ij}<0\), then
\begin{equation}
 R^2<0
 \qquad
 \text{throughout }\Omega_n^\circ(P).
 \label{eq:strictly-negative-interior}
\end{equation}
Thus zeros are admitted on soft or collinear boundary strata.  If every
\(\mu_{ij}=0\), then \(R^2\) vanishes identically on the whole phase space.

\subsection{Normalized scalar products}

Introduce
\begin{equation}
 x_i:=\frac{2k_b\cdot p_i}{s},
 \qquad
 y_i:=\frac{2k_a\cdot p_i}{s},
 \qquad
 z_{ij}:=\frac{2p_i\cdot p_j}{s}=z_{ji},
 \qquad
 i\neq j.
 \label{eq:sign-edge-data}
\end{equation}
Future-directedness implies
\begin{equation}
 x_i\geq0,
 \qquad
 y_i\geq0,
 \qquad
 z_{ij}\geq0.
 \label{eq:sign-edge-positivity}
\end{equation}
Using
\(\sum_i p_i=k_a+k_b\), one obtains
\begin{equation}
 \sum_{i=1}^{n}x_i
 =
 \sum_{i=1}^{n}y_i
 =
 1,
 \qquad
 x_i+y_i
 =
 \sum_{j\neq i}z_{ij},
 \qquad
 \sum_{1\leq i<j\leq n}z_{ij}=1.
 \label{eq:sign-edge-relations}
\end{equation}

For a subset
\begin{equation}
 A\subseteq\{1,\ldots,n\},
 \label{eq:sign-subset}
\end{equation}
define
\begin{equation}
 K_A:=\sum_{i\in A}p_i,
 \qquad
 x_A:=\sum_{i\in A}x_i,
 \qquad
 y_A:=\sum_{i\in A}y_i,
 \qquad
 z_A:=\sum_{\substack{i<j\\i,j\in A}}z_{ij}.
 \label{eq:sign-subset-data}
\end{equation}
The Sudakov decomposition of \(K_A\) is
\begin{equation}
 K_A
 =
 x_Ak_a+y_Ak_b+K_{A\perp},
 \qquad
 K_{A\perp}\cdot k_a
 =
 K_{A\perp}\cdot k_b
 =
 0.
 \label{eq:subset-sudakov-decomposition}
\end{equation}
Define
\begin{equation}
 \kappa_A:=-\frac{K_{A\perp}^2}{s}\geq0.
 \label{eq:subset-transverse-square}
\end{equation}
Since \(K_A^2/s=z_A\),
Eq.~\eqref{eq:subset-sudakov-decomposition} gives
\begin{equation}
 z_A=x_Ay_A-\kappa_A.
 \label{eq:subset-invariant}
\end{equation}
Because \(0\leq x_A,y_A\leq1\),
\begin{align}
 \frac{(k_b-K_A)^2}{s}
 &=
 z_A-x_A
 =
 -x_A(1-y_A)-\kappa_A
 \leq0,
 \notag\\
 \frac{(k_a-K_A)^2}{s}
 &=
 z_A-y_A
 =
 -y_A(1-x_A)-\kappa_A
 \leq0.
 \label{eq:subset-inequality}
\end{align}
Hence
\begin{equation}
 z_A\leq x_A,
 \qquad
 z_A\leq y_A
 \qquad
 \text{for every }A\subseteq\{1,\ldots,n\}.
 \label{eq:subset-flow-inequalities}
\end{equation}

For every nonempty proper subset \(A\), the inequalities are strict in
\(\Omega_n^\circ(P)\).  Indeed,
\begin{equation}
 x_A>0,
 \qquad
 1-y_A=y_{A^c}>0,
 \label{eq:strict-subset-conditions}
\end{equation}
and therefore
\begin{equation}
 x_A-z_A
 =
 x_A(1-y_A)+\kappa_A
 >0.
 \label{eq:strict-subset-inequality}
\end{equation}
The analogous statement holds with \(x\) and \(y\) interchanged.

\subsection{Flow decomposition}

Consider a directed network with:

\begin{enumerate}
 \item a source node \(s_0\);
 \item one edge node \(e_{ij}=e_{ji}\) for every unordered pair \(i<j\);
 \item one vertex node \(v_i\) for every final-state label \(i\);
 \item a sink node \(t_0\).
\end{enumerate}

Assign capacities
\begin{align}
 s_0\longrightarrow e_{ij}
 &: z_{ij},
 \notag\\
 e_{ij}\longrightarrow v_i,
 \quad
 e_{ij}\longrightarrow v_j
 &: \infty,
 \notag\\
 v_i\longrightarrow t_0
 &: x_i,
 \label{eq:sign-flow-network}
\end{align}
where \(\infty\) denotes any capacity larger than the total possible flow,
which is one.

For a fixed set \(A\) of vertex nodes on the source side of a finite cut,
the minimum cut of that form places \(e_{ij}\) on the source side exactly
when \(i,j\in A\).  Its capacity is
\begin{equation}
 \operatorname{cap}(A)
 =
 1-z_A+x_A.
 \label{eq:sign-cut-capacity}
\end{equation}
Equation~\eqref{eq:subset-flow-inequalities} implies
\begin{equation}
 \operatorname{cap}(A)\geq1
 \qquad
 \text{for every }A.
 \label{eq:sign-min-cut-bound}
\end{equation}
Since the total capacity leaving \(s_0\) is one, the max-flow/min-cut theorem
therefore gives a flow of total value one.

Let \(\lambda_{ij}\) be the flow from the edge node \(e_{ij}\) into
the vertex node \(v_i\).  Saturation of the source and sink capacities gives
nonnegative numbers satisfying
\begin{equation}
 \lambda_{ij}+\lambda_{ji}=z_{ij},
 \qquad
 \sum_{j\neq i}\lambda_{ij}=x_i,
 \qquad
 \sum_{i\neq j}\lambda_{ij}=y_j,
 \qquad
 \sum_{i\neq j}\lambda_{ij}=1.
 \label{eq:edge-orientation}
\end{equation}
The third relation follows from the first two and
Eq.~\eqref{eq:sign-edge-relations}:
\begin{equation}
 \sum_{i\neq j}\lambda_{ij}
 =
 \sum_{i\neq j}z_{ij}
 -
 \sum_{i\neq j}\lambda_{ji}
 =
 x_j+y_j-x_j
 =
 y_j.
 \label{eq:edge-column-marginal}
\end{equation}

In the open domain \(\Omega_n^\circ(P)\), the \(\lambda_{ij}\) may be chosen
strictly positive.  To see this, choose \(\delta>0\) such that
\begin{equation}
 2\delta<\min_{i<j}z_{ij},
 \qquad
 \delta<
 \min_{\varnothing\neq A\subsetneq\{1,\ldots,n\}}
 \frac{x_A-z_A}{|A|(n-|A|)}.
 \label{eq:strict-flow-delta}
\end{equation}
Define
\begin{equation}
 z_{ij}^{(\delta)}:=z_{ij}-2\delta,
 \qquad
 x_i^{(\delta)}:=x_i-(n-1)\delta.
 \label{eq:strict-flow-reduced-data}
\end{equation}
For every nonempty proper \(A\),
\begin{equation}
 x_A^{(\delta)}-z_A^{(\delta)}
 =
 x_A-z_A-|A|(n-|A|)\delta
 \geq0.
 \label{eq:strict-flow-reduced-inequality}
\end{equation}
The same flow argument therefore produces
\(\lambda_{ij}^{(\delta)}\geq0\) for the reduced data.  Then
\begin{equation}
 \lambda_{ij}:=\lambda_{ij}^{(\delta)}+\delta
 \label{eq:strict-flow-positive-solution}
\end{equation}
satisfies Eq.~\eqref{eq:edge-orientation} and obeys
\begin{equation}
 \lambda_{ij}>0
 \qquad
 \text{for every }i\neq j.
 \label{eq:strict-flow-positivity}
\end{equation}

\subsection{Convex representation and exact extrema}

Expanding Eq.~\eqref{eq:sign-theorem-linear-combination} gives
\begin{equation}
 \frac{R^2}{s}
 =
 ab
 +a\sum_{i=1}^{n}c_i y_i
 +b\sum_{i=1}^{n}c_i x_i
 +\sum_{1\leq i<j\leq n}c_ic_jz_{ij}.
 \label{eq:sign-expanded-square}
\end{equation}
Using Eq.~\eqref{eq:edge-orientation}, this becomes
\begin{align}
 \frac{R^2}{s}
 &=
 \sum_{i\neq j}
 \lambda_{ij}
 (a+c_i)(b+c_j)
 \notag\\
 &=
 \sum_{i\neq j}\lambda_{ij}\mu_{ij}.
 \label{eq:sign-convex-combination}
\end{align}
Because
\begin{equation}
 \lambda_{ij}\geq0,
 \qquad
 \sum_{i\neq j}\lambda_{ij}=1,
 \label{eq:sign-convex-weights}
\end{equation}
Eq.~\eqref{eq:sign-convex-combination} proves
Eq.~\eqref{eq:fixed-sign-bound}.

It remains to show that every \(\mu_{ij}\) is an actual boundary value.
Fix an ordered pair \(i\neq j\).  For every remaining label
\(r\neq i,j\), choose a positive number \(\varepsilon_r\) with
\begin{equation}
 \varepsilon:=\sum_{r\neq i,j}\varepsilon_r<1.
 \label{eq:boundary-soft-parameters}
\end{equation}
The boundary configuration
\begin{equation}
 p_i=(1-\varepsilon)k_a,
 \qquad
 p_j=k_b,
 \qquad
 p_r=\varepsilon_r k_a
 \quad(r\neq i,j)
 \label{eq:boundary-extremal-configuration}
\end{equation}
consists of future-directed null momenta and satisfies exact momentum
conservation.  Taking every \(\varepsilon_r\to0^+\) gives
\begin{equation}
 p_i\longrightarrow k_a,
 \qquad
 p_j\longrightarrow k_b,
 \qquad
 p_r\longrightarrow0
 \quad(r\neq i,j).
 \label{eq:boundary-extremal-limit}
\end{equation}
Along this limit,
\begin{equation}
 R
 \longrightarrow
 (a+c_i)k_a+(b+c_j)k_b,
 \qquad
 \frac{R^2}{s}
 \longrightarrow
 (a+c_i)(b+c_j)
 =
 \mu_{ij}.
 \label{eq:boundary-extremal-value}
\end{equation}
Every \(\mu_{ij}\) is therefore attained on
\(\overline{\Omega}_n(P)\), proving
Eq.~\eqref{eq:fixed-sign-exact-extrema}.

In the open domain, Eq.~\eqref{eq:strict-flow-positivity} shows that
Eq.~\eqref{eq:sign-convex-combination} is a strictly positive weighted sum
of all \(\mu_{ij}\).  This proves
Eqs.~\eqref{eq:strictly-positive-interior} and
\eqref{eq:strictly-negative-interior}.

\subsection{Use and limitations}

For a massless ordinary denominator
\begin{equation}
 \Delta_R:=R^2
 \label{eq:fixed-sign-denominator}
\end{equation}
of the form in Eq.~\eqref{eq:sign-theorem-linear-combination}, the theorem
gives an exact necessary-and-sufficient fixed-sign test:

\begin{enumerate}
 \item If every \(\mu_{ij}>0\), then
 \(\Delta_R>0\) on the full phase-space closure.

 \item If every \(\mu_{ij}<0\), then
 \(\Delta_R<0\) on the full phase-space closure.

 \item If every \(\mu_{ij}\geq0\), with at least one strict inequality, then
 \(\Delta_R>0\) in \(\Omega_n^\circ(P)\), while zeros may occur only on soft
 or collinear boundary strata.

 \item If every \(\mu_{ij}\leq0\), with at least one strict inequality, then
 \(\Delta_R<0\) in \(\Omega_n^\circ(P)\), while zeros may occur only on soft
 or collinear boundary strata.

 \item If every \(\mu_{ij}=0\), then \(\Delta_R\equiv0\), so it cannot serve
 as an ordinary propagator denominator.

 \item If
 \[
  \min_{i\neq j}\mu_{ij}<0<
  \max_{i\neq j}\mu_{ij},
 \]
 then \(\Delta_R\) takes both signs on the phase-space closure and has no
 fixed sign.
\end{enumerate}

When zeros occur only on the physical boundary, this theorem establishes
their location but does not by itself justify combining opposite source-side
\(i0\) prescriptions.  That additional step requires the endpoint
meromorphy and absolute-convergence condition stated in
Sec.~\ref{subsec:reverse-unitarity-causal}.

The theorem does not classify:

\begin{enumerate}
 \item denominators containing forward or conjugate virtual-loop momenta;
 \item denominators mixing the two virtual-loop sets;
 \item linear eikonal denominators;
 \item denominators whose coefficients depend on integration momenta;
 \item massive denominators \(R^2-m^2\) unless their shifted extrema are
 analyzed separately.
\end{enumerate}

## Sources sent to Pro

- [manuscript_b_fixed_sign.tex](Sources/07_manuscript_b_fixed_sign/manuscript_b_fixed_sign.tex)
