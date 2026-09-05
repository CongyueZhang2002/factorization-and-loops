# Manuscript E Alternative Methods

## Question

The attached file is the appendix on alternative analytic and numerical
methods. Review and rewrite this appendix only.

Return a short critique and compilable replacement LaTeX. Retain only methods
actually explored in the project and state their precise domain: global
discontinuities, direct phase-space integration, differential equations with
analytic boundary data, AMFlow numerical comparisons, and use of known master
formulas. Do not imply that numerical differential equations yield the
required analytic result. Do not repeat the main workflow or add speculative
claims. Do not rewrite another appendix or section.

## Pro response

Short critique

The global-discontinuity paragraph does not define the discontinuity normalization and does not state all conditions under which the sum over Cutkosky cuts reduces to the one oriented cut required by the observable. Cut identity, energy orientation, measurement weight, propagator powers, and normalization must all agree. 

E_alternative_methods

“Numerical differential equations” conflates two distinct methods. Exact differential equations with analytic boundary data can determine the required analytic master functions; AMFlow provides fixed-point numerical Laurent coefficients for comparison only. Numerical agreement cannot determine a branch, boundary functional, or endpoint distribution. 

E_alternative_methods

The domain of direct integration is described by vague complexity statements. Its precise requirements are an exact parameterization of the physical cycle, a verified Jacobian and branch prescription, a nonempty convergence domain, and an analytically integrable coefficient representation. Hyperlogarithmic integration additionally requires linear reducibility. 

E_alternative_methods

Reuse of a known master formula requires more than qualitative agreement of its denominator family. One needs either powered-integral equivalence or an explicit exact conversion including measure, cut normalization and orientation, propagator powers, causal prescriptions, kinematic continuation, and all induced scale factors. 

E_alternative_methods

LaTeX
\section{Methods considered and their domains of validity}
\label{app:alternative-methods}

This appendix records analytic and numerical routes that were examined in the
course of the calculation.  Direct integration, differential equations with
analytic boundary data, and exact reuse of a known master formula can provide
an analytic master integral.  A global discontinuity does so only when it
isolates the required cut exactly.  Fixed-point numerical evaluations are
independent comparisons and are not substituted for an analytic result.

\paragraph{Global discontinuities.}

For an uncut boundary-value integral depending on a real channel variable
\(\chi\), define
\begin{equation}
 \operatorname{Disc}_{\chi} I
 :=
 I(\chi+i0)-I(\chi-i0).
 \label{eq:alternative-global-discontinuity}
\end{equation}
After its normalization has been matched to the cut convention of
Appendix~\ref{app:conventions}, the Cutkosky decomposition expresses
Eq.~\eqref{eq:alternative-global-discontinuity} as a sum over the cuts
admitted in that channel.  It equals one required cut integral only if an
exact cut analysis establishes that:

\begin{enumerate}
 \item no other cut contributes, or an exact projection separates the desired
 cut from every other term;

 \item the cut momenta and their energy orientations agree with those in the
 required family;

 \item every propagator power, including a differentiated-cut power, is
 reproduced;

 \item all measurement weights and distinguished-line labels agree;

 \item the measure and cut normalization are converted exactly.
\end{enumerate}

When several physical cuts contribute to the same discontinuity,
Eq.~\eqref{eq:alternative-global-discontinuity} does not determine any one of
them separately.  It can also combine different physical regions or
measurement assignments.  For that reason, a single global discontinuity was
not used to define the designated multi-particle cut families in the present
calculation.

\paragraph{Direct physical phase-space integration.}

Direct analytic integration is applicable when the cut constraints admit an
exact parameterization of the physical integration cycle,
\begin{equation}
 \Phi:
 \mathcal D\subseteq\mathbb R^n
 \longrightarrow
 \Gamma(\mathfrak C),
 \label{eq:alternative-direct-parameterization}
\end{equation}
for which the multiplicity, Jacobian, positive-energy conditions, ordinary
causal boundary values, and analytic branches are all known.  Endpoint
singularities must admit a common nonempty convergence domain before
meromorphic continuation in \(\eps\).

After the endpoint regions have been resolved, the resulting coefficient
integrals may be evaluated by elementary Euler representations,
hypergeometric identities, or exact integration algorithms.  HyperInt-type
integration applies when the singular polynomials admit a linearly reducible
ordering after the required Laurent expansion.  \SubTropica\ is used when
its exact sector and integration procedures return a branch-certified
analytic expression.  Neither sector resolution nor the existence of a real
parameterization guarantees linear reducibility, and failure of direct
integration does not justify replacing the master by a numerical value.

\paragraph{Differential equations with analytic boundary data.}

For an exact master vector
\begin{equation}
 \boldsymbol M(\boldsymbol x,\eps)
 =
 (M_1,\ldots,M_N)^{\mathsf T},
 \label{eq:alternative-master-vector}
\end{equation}
kinematic differentiation followed by cut-aware IBP reduction gives
\begin{equation}
 \frac{\partial\boldsymbol M}{\partial x_i}
 =
 A_i(\boldsymbol x,\eps)\boldsymbol M,
 \qquad
 A_i\in
 \operatorname{Mat}_{N}
 \bigl(\mathbb Q(\boldsymbol x,\eps)\bigr).
 \label{eq:alternative-differential-system}
\end{equation}
The system is admissible only when
\begin{equation}
 \partial_{x_i}A_j
 -
 \partial_{x_j}A_i
 -
 [A_i,A_j]
 =
 0
 \label{eq:alternative-flatness}
\end{equation}
holds exactly modulo the external kinematic relations.

Equation~\eqref{eq:alternative-differential-system} determines the masters
only after the physical local modes and their analytic coefficients have
been fixed.  These data may follow from lower integrals, regularity,
symmetries, expansion by regions, or direct analytic boundary integrals with
the same normalization, cuts, causal prescriptions, chamber, and branch.
A numerical solution of the differential equation does not determine the
required exact boundary constants and is not the analytic result used in the
hard function.

\paragraph{Fixed-point comparisons with \AMFlow.}

For a specified physical point \(\boldsymbol x_\star\), \AMFlow\ provides
numerical Laurent coefficients for a declared integral family,
\begin{equation}
 M^{\rm AMF}(\boldsymbol x_\star,\eps)
 =
 \sum_{n=n_{\min}}^{N}
 m_n^{\rm AMF}(\boldsymbol x_\star)\eps^n
 +
 O(\eps^{N+1}).
 \label{eq:alternative-amflow-series}
\end{equation}
A meaningful comparison requires the same:

\begin{enumerate}
 \item normalized integration measure;
 \item denominator powers;
 \item physical cut slots and energy orientations;
 \item ordinary causal prescriptions;
 \item external invariants and physical chamber.
\end{enumerate}

The coefficients in Eq.~\eqref{eq:alternative-amflow-series} are compared
with the corresponding values of an independently derived analytic
expression.  Agreement tests the normalization, causal boundary value,
branch, and analytic continuation at that point.  It does not determine the
functional dependence, provide an analytic boundary period, or generate
\(\delta(1-w)\) and plus distributions.

\paragraph{Reuse of known exact master formulas.}

A known analytic master formula may be reused when its relation to the
required integral is established exactly.  The strongest case is
powered-integral equivalence,
\begin{equation}
 (\mathcal T,\boldsymbol\nu)
 \sim_{\rm pow}
 (\mathcal T',\boldsymbol\nu'),
 \label{eq:alternative-known-master-equivalence}
\end{equation}
as defined in Appendix~\ref{app:topology-equivalence}.  More generally, one
may prove an identity of the form
\begin{equation}
 M_{\rm req}(\boldsymbol x,\eps)
 =
 \mathcal N(\boldsymbol x,\eps)\,
 M_{\rm known}
 \bigl(\rho(\boldsymbol x),\eps\bigr),
 \label{eq:alternative-known-master-map}
\end{equation}
where the prefactor \(\mathcal N\) and kinematic map \(\rho\) account
exactly for all denominator rescalings and normalization changes.

Before Eq.~\eqref{eq:alternative-known-master-map} is used, one must verify
the integration measure, cut normalization and orientation, propagator
powers, ordinary causal prescriptions, physical chamber, analytic branch,
and any measurement or numerator insertion.  If the published expression is
given in another chamber, the required analytic continuation must be
performed explicitly.  Positive-denominator equivalence alone is
insufficient because it forgets propagator powers and numerator data.

The result entering the hard function is therefore obtained from direct
analytic integration, from an exact differential system with analytic
boundary data, or from an exactly mapped known formula.  Global
discontinuities and fixed-point numerical evaluations are used only within
the restricted roles stated above.

## Sources sent to Pro

- [manuscript_e_alternative_methods.tex](Sources/15_manuscript_e_alternative_methods/manuscript_e_alternative_methods.tex)
