# Manuscript 05 Analytic Masters

## Question

The attached file is the current complete draft of Section 5, on analytic cut
master integrals. Review and rewrite this section only.

Return:
1. A concise list of mathematical errors, conflated relations, unsupported
   package claims, or missing branch data.
2. Compilable replacement LaTeX for this section only.

Check:
- what an analytic master result must contain;
- physical parameterizations, contours, Jacobians, and real or causal branches;
- when direct integration, SubTropica, and HyperInt-type integration are
  applicable;
- derivation, flatness, basis changes, and analytic boundary data for
  differential equations;
- precise and distinct definitions of powered-integral equivalence,
  positive-denominator equivalence, differential-equation closure, and
  equality of normalized boundary periods;
- the exact role of AMFlow as a numerical comparison rather than the source of
  the analytic result.

Use ordinary QFT language. Do not replace precise definitions by software
terminology, and do not claim that every boundary integral can be obtained
automatically. Do not rewrite another section.

## Pro response

1. Required corrections

The required analytic output is underdefined. It must be meromorphic in ϵ, analytic as a specified boundary value in a declared kinematic chamber, normalized in the same measure as the IBP masters, and accompanied by its cut orientations, ordinary causal prescriptions, endpoint modes, branch choices, and sufficient Laurent depth. 

05_analytic_masters

The branch prescription

X
α
=exp[αlogX]

is sufficient only for a strictly positive real base. A fixed negative denominator with +i0 or −i0 requires

log(X+i0σ)=log∣X∣+iπσ.

If a singular denominator vanishes inside the contour, subdividing the real domain is not automatically sufficient; the causal contour must be nonpinched and explicitly defined. Otherwise the integral must be rejected. 

05_analytic_masters

A physical parameterization requires more than a Jacobian: it must map the declared real domain to the complete oriented integration cycle, account for multiplicity, reproduce every cut condition, and preserve the causal branch of every ordinary denominator.

The direct-integration claim is too broad. Exact sector resolution does not imply that the resulting integrals are linearly reducible. HyperInt-type integration applies only after the ϵ-expanded coefficient integrands have a linearly reducible singular-polynomial ordering. SubTropica is used where its exact sector and integration algorithms apply; it is not established that every master or boundary integral can be obtained automatically. 

05_analytic_masters

The differential system is not derived in the draft. The derivatives must be tangent to the constrained external-kinematic manifold, differentiated integrals must retain the same cuts and causal data, and the complete derivative family must be reduced by IBP. Flatness must hold exactly modulo the kinematic relations. 

05_analytic_masters

A rational basis transformation does not necessarily produce a canonical ϵ-form. Fuchsianization and canonicalization may fail, particularly for elliptic or more general sectors. The transformed connection and its branch alphabet must be stated explicitly.

“Analytic boundary data” is too vague. At a regular-singular endpoint, the local powers and logarithmic Jordan modes must be derived from the residue matrix. Their coefficients may be fixed by lower integrals, regularity, symmetries, expansion by regions, or direct analytic boundary integrals. One boundary integral can determine several scalar coefficients, and not every coefficient requires a new period.

The four relations are conflated and incompletely defined. Powered-integral equivalence and positive-denominator equivalence are equivalence relations; differential reachability is a preorder whose mutual-reachability classes are the strongly connected differential blocks; equality of normalized boundary representations additionally preserves the cycle, density, endpoint direction, selected local mode, chamber, cuts, causal prescriptions, and branches. 

05_analytic_masters

AMFlow supplies numerical Laurent coefficients at specified points. Agreement tests the normalization, branch, causal prescription, and analytic formula, but does not establish the function or replace an analytic boundary derivation. 

05_analytic_masters

LaTeX
\section{Analytic evaluation of cut master integrals}
\label{sec:analytic-masters}

The IBP reduction of Sec.~\ref{sec:ibp-coefficients} determines the exact
rational coefficients multiplying a chosen master basis.  It does not
determine the analytic values of those masters.  For each master
\(M_a\), the required result consists of:

\begin{enumerate}
 \item the normalization relative to the measure
 \(\dd^D\ell/(i\pi^{D/2})\);

 \item the identity and energy orientation of every physical cut;

 \item the causal boundary value of every ordinary propagator;

 \item the physical kinematic chamber and the path by which its boundaries
 are approached;

 \item an exact expression that is meromorphic in
 \(\eps\) and analytic, as the specified boundary value, in the interior of
 that chamber;

 \item the local endpoint powers and logarithmic modes before they are
 expanded in \(\eps\);

 \item an exact Laurent expansion through the order required by the
 reconstructed hard coefficient.
\end{enumerate}

A formula without its normalization, cycle, causal prescription, or branch
does not define the master integral used in the hard function.

\subsection{Physical parameterizations and branch data}
\label{subsec:physical-parameterizations}

Let
\begin{equation}
 M_a(\boldsymbol x,\eps)
 =
 \int_{\Gamma_a(\mathfrak C)}
 \Omega_a(\boldsymbol\ell,\boldsymbol x,\eps)
 \label{eq:master-as-period}
\end{equation}
denote a normalized cut master.  Here \(\boldsymbol x\) is a set of
independent kinematic variables, \(\mathfrak C\) is a connected physical
chamber, \(\Gamma_a(\mathfrak C)\) is the oriented integration cycle fixed by
the positive-energy cuts and the ordinary causal prescriptions, and
\(\Omega_a\) includes the normalized measure and denominator powers.

A physical parameterization is an exact map
\begin{equation}
 \Phi_a:
 \mathcal D_a
 \longrightarrow
 \Gamma_a(\mathfrak C),
 \qquad
 \boldsymbol y
 \longmapsto
 \boldsymbol\ell(\boldsymbol y,\boldsymbol x),
 \label{eq:physical-parameterization-map}
\end{equation}
where \(\mathcal D_a\subseteq\mathbb R^{n_a}\) is given by explicit
inequalities.  The map must:

\begin{enumerate}
 \item solve the momentum-conservation and on-shell constraints exactly;

 \item reproduce every positive-energy condition;

 \item cover the intended cycle with a stated multiplicity;

 \item have a nonsingular inverse in the interior, up to declared coordinate
 boundaries;

 \item provide the exact induced Jacobian;

 \item preserve the causal boundary value of each ordinary denominator.
\end{enumerate}

After eliminating the cut delta functions and pulling back the measure, the
master takes the form
\begin{equation}
 M_a(\boldsymbol x,\eps)
 =
 \mathcal N_a(\boldsymbol x,\eps)
 \int_{\mathcal D_a}
 \dd^{n_a}\boldsymbol y\,
 J_a(\boldsymbol y,\boldsymbol x)
 \prod_{\rho=1}^{R_a}
 \Bigl[
  F_{a\rho}(\boldsymbol y,\boldsymbol x)
  +i0\,\sigma_{a\rho}
 \Bigr]^{\alpha_{a\rho}+\beta_{a\rho}\eps}
 \mathcal R_a(\boldsymbol y,\boldsymbol x,\eps).
 \label{eq:parameterized-master}
\end{equation}
The factor \(\mathcal N_a\) contains every scale and normalization removed
from the dimensionless density.  The function \(J_a\) is the exact
Jacobian, and \(\mathcal R_a\) is single valued in the stated chart apart
from the displayed powered factors.

For a strictly positive real base, we define
\begin{equation}
 X^\lambda
 :=
 \exp\!\bigl[\lambda\ln X\bigr],
 \qquad
 X>0,
 \qquad
 \ln X\in\mathbb R.
 \label{eq:real-power-definition}
\end{equation}
For a strictly negative real base carrying an ordinary causal sign
\(\sigma=\pm1\),
\begin{equation}
 \Log_\sigma X
 :=
 \lim_{\eta\to0^+}\Log(X+i\sigma\eta)
 =
 \ln|X|+i\pi\sigma,
 \qquad
 X<0,
 \label{eq:causal-logarithm}
\end{equation}
and
\begin{equation}
 (X+i0\,\sigma)^\lambda
 :=
 \exp\!\bigl[\lambda\Log_\sigma X\bigr].
 \label{eq:causal-noninteger-power}
\end{equation}
Equations~\eqref{eq:real-power-definition} and
\eqref{eq:causal-noninteger-power} fix the branches before any Laurent
expansion.

If a powered base vanishes only on a soft, collinear, or other declared
boundary stratum, that boundary is resolved into local coordinates before
expanding in \(\eps\).  If an ordinary denominator vanishes on an interior
hypersurface, the real subdivision of the parameter domain is not by itself
a contour definition.  The integral is admitted only when the original
\(\pm i0\) prescription gives a nonpinched contour and its deformation or
boundary value is retained explicitly.  A pinched or otherwise undefined
interior singularity is not assigned a branch by algebraic simplification.

Analytic continuation to another kinematic chamber is a separate
calculation.  The continuation path must avoid or encircle each singular
hypersurface according to the original causal prescription; a formula
derived in one chamber is not silently reused in another.

\subsection{Direct analytic integration}
\label{subsec:direct-analytic-integration}

A physical parameterization may already reduce a master to beta functions,
Euler integrals, hypergeometric functions, or another known analytic
representation.  More generally, endpoint singularities may be resolved by
exact changes of variables into a finite set of sectors,
\begin{equation}
 M_a
 =
 \mathcal N_a
 \sum_{s=1}^{N_a^{\rm sec}}
 \int_{[0,1]^{n_a}}
 \dd^{n_a}\boldsymbol y\,
 \prod_{j=1}^{n_a}
 y_j^{A_{asj}+B_{asj}\eps}\,
 U_{as}(\boldsymbol y,\boldsymbol x,\eps),
 \label{eq:exact-sector-representation}
\end{equation}
where \(U_{as}\) is analytic and nonzero at the relevant coordinate
boundaries.  The representation must possess a nonempty convergence domain,
\begin{equation}
 \operatorname{Re}
 \bigl(A_{asj}+B_{asj}\eps\bigr)>-1
 \qquad
 \text{for every }s,j,
 \label{eq:sector-convergence-domain}
\end{equation}
before it is continued meromorphically in \(\eps\).

The monomial endpoint factors in
Eq.~\eqref{eq:exact-sector-representation} are retained until all regions
have been identified.  Expanding in \(\eps\) then gives
\begin{equation}
 M_a(\boldsymbol x,\eps)
 =
 \sum_{n=n_a^{\min}}^{N_\eps}
 \eps^n M_a^{(n)}(\boldsymbol x)
 +
 O\!\left(\eps^{N_\eps+1}\right),
 \label{eq:master-laurent-expansion}
\end{equation}
with
\begin{equation}
 M_a^{(n)}(\boldsymbol x)
 =
 \sum_s
 \int_{[0,1]^{n_a}}
 \dd^{n_a}\boldsymbol y\,
 f_{as}^{(n)}(\boldsymbol y,\boldsymbol x).
 \label{eq:laurent-coefficient-integrals}
\end{equation}

When the singular polynomials of the functions
\(f_{as}^{(n)}\) admit a linearly reducible integration ordering, the
coefficient integrals can be evaluated by hyperlogarithmic methods
\cite{Panzer:2014caa}.  We use \SubTropica\ to derive exact sector and
asymptotic representations and, where its analytic algorithms apply, to
evaluate the resulting integrals \cite{Giroux:2026tgd}.  HyperInt-type
integration is then applicable to the linearly reducible sectors.

Neither exact sector resolution nor the use of \SubTropica\ implies that an
arbitrary cut master is hyperlogarithmic.  Irreducible algebraic,
elliptic, or more general structures may remain, and some boundary
integrals require a separate analytic derivation.  Failure of a direct
integration method does not justify replacing the master by a numerical
value.

\subsection{Differential equations and analytic boundary data}
\label{subsec:master-differential-equations}

Let
\begin{equation}
 \boldsymbol M(\boldsymbol x,\eps)
 =
 \bigl(M_1,\ldots,M_{N_M}\bigr)^{\mathsf T}
 \label{eq:master-vector}
\end{equation}
be a master vector that is complete under differentiation in the chosen
kinematic variables
\begin{equation}
 \boldsymbol x=(x_1,\ldots,x_r).
 \label{eq:differential-variables}
\end{equation}
The derivatives \(\partial_{x_\rho}\) are defined as vector fields tangent to
the external-kinematic manifold: they preserve the on-shell conditions,
momentum conservation, and all algebraic relations among the invariants.
Differentiating the integral representations and reducing every resulting
integral by the same cut-aware IBP rules gives
\begin{equation}
 \frac{\partial\boldsymbol M}{\partial x_\rho}
 =
 A_\rho(\boldsymbol x,\eps)\boldsymbol M,
 \qquad
 A_\rho\in
 \operatorname{Mat}_{N_M}
 \bigl(\mathbb Q(\boldsymbol x,\eps)\bigr).
 \label{eq:master-differential-components}
\end{equation}
Equivalently,
\begin{equation}
 \dd\boldsymbol M
 =
 A(\boldsymbol x,\eps)\boldsymbol M,
 \qquad
 A
 :=
 \sum_{\rho=1}^{r}
 A_\rho(\boldsymbol x,\eps)\,\dd x_\rho.
 \label{eq:master-differential-system}
\end{equation}
Every physical cut, cut orientation, and ordinary causal prescription is the
same as in the original master family.

Consistency of mixed derivatives requires the exact flatness condition
\begin{equation}
 \dd A-A\wedge A=0,
 \label{eq:flatness-condition}
\end{equation}
or, in components,
\begin{equation}
 \partial_{x_\rho}A_\sigma
 -
 \partial_{x_\sigma}A_\rho
 -
 [A_\rho,A_\sigma]
 =
 0.
 \label{eq:flatness-components}
\end{equation}
The equality is imposed exactly modulo the external kinematic relations.
Failure of Eq.~\eqref{eq:flatness-condition} means that the derivative
reduction, the master vector, or the kinematic differentiation is
incomplete.

For an invertible basis transformation
\begin{equation}
 \boldsymbol M
 =
 T(\boldsymbol x,\eps)\boldsymbol J,
 \label{eq:master-basis-transformation}
\end{equation}
the connection becomes
\begin{equation}
 A_J
 =
 T^{-1}AT-T^{-1}\dd T,
 \qquad
 \dd\boldsymbol J=A_J\boldsymbol J.
 \label{eq:transformed-connection}
\end{equation}
A Fuchsian basis has only regular-singular poles.  A canonical
\(\eps\)-form, when it exists, has the stronger form
\begin{equation}
 A_J
 =
 \eps
 \sum_{\alpha=1}^{N_{\rm let}}
 R_\alpha\,\dd\log\phi_\alpha(\boldsymbol x),
 \label{eq:canonical-epsilon-form}
\end{equation}
where the matrices \(R_\alpha\) are independent of the kinematic variables
and the functions \(\phi_\alpha\) define the differential alphabet
\cite{Henn:2013pwa,Meyer:2017joq}.  Such a form is not assumed to exist for
every family.

Suppose a physical boundary is approached through
\begin{equation}
 \lambda\longrightarrow0^+
 \label{eq:boundary-direction}
\end{equation}
at fixed values of the remaining variables and within the declared chamber.
For a regular-singular system,
\begin{equation}
 \frac{\partial\boldsymbol J}{\partial\lambda}
 =
 \left[
  \frac{R(\eps)}{\lambda}
  +O(1)
 \right]\boldsymbol J.
 \label{eq:local-fuchsian-system}
\end{equation}
Its Levelt expansion has the form
\begin{equation}
 \boldsymbol J(\lambda,\eps)
 =
 \sum_{\rho}
 \lambda^{\rho(\eps)}
 \sum_{k=0}^{k_\rho}
 (\log\lambda)^k
 \boldsymbol J_{\rho k}(\lambda,\eps),
 \label{eq:levelt-expansion}
\end{equation}
where each
\(\boldsymbol J_{\rho k}(\lambda,\eps)\) is analytic in \(\lambda\) near
zero.  The exponents, logarithmic multiplicities, and possible resonances
are derived from the exact residue matrix \(R(\eps)\); they are not inferred
from numerical endpoint values.

The scalar coefficients in
Eq.~\eqref{eq:levelt-expansion} are fixed by some combination of:

\begin{enumerate}
 \item known lower-denominator integrals;

 \item regularity or absence of a local mode in the physical solution;

 \item exact symmetries;

 \item expansion by regions with the same cuts, causal prescriptions, and
 branch choices;

 \item direct analytic evaluation of normalized boundary integrals.
\end{enumerate}

One direct boundary integral can determine more than one scalar coefficient,
and several regions can contribute to one coefficient.  Distinct
differential systems can also contain the same normalized boundary period.
The number of scalar coefficients, direct boundary integrations, and new
periods must therefore be determined separately.

Once the boundary data have been fixed, transport from a base point
\(\boldsymbol x_0\) to \(\boldsymbol x\) is
\begin{equation}
 \boldsymbol J(\boldsymbol x,\eps)
 =
 \mathcal P
 \exp\!\left[
  \int_{\gamma:\boldsymbol x_0\to\boldsymbol x}
  A_J
 \right]
 \boldsymbol J(\boldsymbol x_0,\eps),
 \label{eq:path-ordered-transport}
\end{equation}
where \(\gamma\) lies inside the chosen chamber and avoids the singular
hypersurfaces.  Flatness makes the transport independent of deformations of
\(\gamma\) that do not cross those hypersurfaces.  In a canonical
polylogarithmic system, Eq.~\eqref{eq:path-ordered-transport} expands in
Chen iterated integrals of the letters \(\phi_\alpha\).  More general
systems require the corresponding broader class of analytic functions.

\subsection{Four distinct relations among masters and boundary data}
\label{subsec:master-relations}

The reductions in the number of integral calculations arise from four
different mathematical relations.  They must not be identified with one
another.

\paragraph{Powered-integral equivalence.}
Let
\begin{equation}
 \mathfrak I_{\rm cut}
 :=
 \left\{
  (\mathcal T,\boldsymbol\nu)
  \,\middle|\,
  \mathcal T
  \text{ is an admissible cut-decorated family and }
  \boldsymbol\nu\in\mathfrak A_{\mathcal T}
 \right\}.
 \label{eq:powered-integral-carrier-section5}
\end{equation}
For
\(I=(\mathcal T,\boldsymbol\nu)\) and
\(J=(\mathcal T',\boldsymbol\nu')\) in
\(\mathfrak I_{\rm cut}\), define
\begin{equation}
 I\sim_{\rm pow}J
 \quad\Longleftrightarrow\quad
 \begin{gathered}
  \text{there is an allowed affine momentum map, external relabeling,}\\
  \text{and slot permutation preserving the normalized measure,}\\
  \text{kinematic chamber, branches, ordinary causal classes,}\\
  \text{cut momenta and orientations, measurement labels, and}\\
  \text{every denominator exponent.}
 \end{gathered}
 \label{eq:powered-equivalence-section5}
\end{equation}
The precise map is given in
Appendix~\ref{app:topology-equivalence}.  Identity, inverse, and composition
of the allowed maps make \(\sim_{\rm pow}\) an equivalence relation.
Equivalent powered integrals are equal after the corresponding exact
kinematic substitution.

\paragraph{Positive-denominator equivalence.}
For
\(I=(\mathcal T,\boldsymbol\nu)\), define
\begin{equation}
 Z(I)
 :=
 \left\{
  d_i\ \middle|\ \nu_i>0
 \right\},
 \label{eq:positive-denominator-set-section5}
\end{equation}
where each descriptor \(d_i\) retains the denominator polynomial, cut or
ordinary type, cut orientation or causal class, and physical line label, but
not the value of a positive exponent.  Define
\begin{equation}
 I\sim_{\rm den}J
 \quad\Longleftrightarrow\quad
 \exists\,g\in\mathcal G:
 \quad
 gZ(I)=Z(J),
 \label{eq:denominator-equivalence-section5}
\end{equation}
where \(\mathcal G\) is the same group of certified physical relabelings and
affine maps.  This is an equivalence relation on
\(\mathfrak I_{\rm cut}\).  It classifies positive-denominator geometry but
does not imply equality of integrals when powers, numerator insertions, or
inactive family slots differ.

\paragraph{Differential reachability and closure.}
Fix an exact master basis
\begin{equation}
 \mathfrak M
 =
 \{M_1,\ldots,M_{N_M}\}
 \label{eq:differential-master-set}
\end{equation}
and the reduced matrices \(A_\rho\) in
Eq.~\eqref{eq:master-differential-components}.  Introduce a directed edge
\begin{equation}
 M_i\longrightarrow M_j
 \quad\Longleftrightarrow\quad
 (A_\rho)_{ij}\not\equiv0
 \quad
 \text{for at least one }\rho.
 \label{eq:differential-edge}
\end{equation}
Write
\begin{equation}
 M_i\rightsquigarrow M_j
 \label{eq:differential-reachability}
\end{equation}
when a directed path, including a path of length zero, connects \(M_i\) to
\(M_j\).  The relation \(\rightsquigarrow\) is reflexive and transitive but
not generally symmetric; it is a preorder.

For
\(S\subseteq\mathfrak M\), define its differential closure by
\begin{equation}
 \operatorname{cl}_{\rm DE}(S)
 :=
 \left\{
  M_j\in\mathfrak M
  \,\middle|\,
  M_i\rightsquigarrow M_j
  \text{ for some }M_i\in S
 \right\}.
 \label{eq:de-closure-definition}
\end{equation}
This is the smallest set containing \(S\) that is closed under all reduced
kinematic derivatives.  Mutual reachability defines the equivalence relation
\begin{equation}
 M_i\sim_{\rm DE}M_j
 \quad\Longleftrightarrow\quad
 M_i\rightsquigarrow M_j
 \ \text{and}\
 M_j\rightsquigarrow M_i.
 \label{eq:strongly-connected-de-equivalence}
\end{equation}
Its classes are the strongly connected blocks of the chosen differential
basis.  Differential coupling does not imply equality of boundary
coefficients or periods.

\paragraph{Equality of normalized boundary representations.}
Let \(\mathfrak B\) be the set of tuples
\begin{equation}
 \beta
 =
 \left(
  \Gamma_\beta(\lambda),
  \Omega_\beta(\lambda,\eps),
  \mathfrak C_\beta,
  \rho_\beta(\eps),
  k_\beta
 \right),
 \label{eq:boundary-representation-carrier}
\end{equation}
where \(\Gamma_\beta(\lambda)\) is an oriented cycle approaching the boundary
as \(\lambda\to0^+\), \(\Omega_\beta\) is the completely normalized density,
\(\mathfrak C_\beta\) includes the physical chamber, cuts, causal
prescriptions, and branches, and
\((\rho_\beta,k_\beta)\) selects one local mode.  If
\begin{equation}
 \int_{\Gamma_\beta(\lambda)}
 \Omega_\beta(\lambda,\eps)
 \sim
 \sum_{\rho,k}
 \lambda^{\rho(\eps)}
 (\log\lambda)^k
 B_{\beta;\rho k}(\eps),
 \label{eq:boundary-asymptotic-representation}
\end{equation}
define the selected normalized boundary period by
\begin{equation}
 \mathcal B_\beta(\eps)
 :=
 B_{\beta;\rho_\beta k_\beta}(\eps).
 \label{eq:normalized-boundary-period}
\end{equation}

For \(\beta,\beta'\in\mathfrak B\), define
\begin{equation}
 \beta\sim_{\rm bnd}\beta'
 \quad\Longleftrightarrow\quad
 \begin{gathered}
  \exists\ \text{an orientation-preserving analytic change of variables }
  \phi_\lambda:
  \Gamma_\beta(\lambda)\to\Gamma_{\beta'}(\lambda),
  \\
  \phi_\lambda^*
  \Omega_{\beta'}=\Omega_\beta,
  \qquad
  (\rho_\beta,k_\beta)
  =
  (\rho_{\beta'},k_{\beta'}),
  \\
  \phi_\lambda
  \text{ preserves the endpoint direction, physical chamber, cuts,}\\
  \text{causal prescriptions, measurement data, and analytic branches.}
 \end{gathered}
 \label{eq:boundary-period-equivalence}
\end{equation}
Identity, inverse, and composition show that
\(\sim_{\rm bnd}\) is an equivalence relation, and
\begin{equation}
 \beta\sim_{\rm bnd}\beta'
 \quad\Longrightarrow\quad
 \mathcal B_\beta(\eps)
 =
 \mathcal B_{\beta'}(\eps).
 \label{eq:boundary-equivalence-implies-equality}
\end{equation}
The same equality may also be established by another exact analytic
identity, but it is never inferred solely from
\(I\sim_{\rm den}J\) or from numerical agreement at selected points.

The four relations therefore answer different questions:
\begin{equation}
 \begin{array}{c|c}
 \text{relation}
 &
 \text{object identified}
 \\
 \hline
 \sim_{\rm pow}
 &
 \text{the complete powered cut integral}
 \\
 \sim_{\rm den}
 &
 \text{the positive-denominator geometry}
 \\
 \operatorname{cl}_{\rm DE},\ \sim_{\rm DE}
 &
 \text{the masters coupled by kinematic differentiation}
 \\
 \sim_{\rm bnd}
 &
 \text{the normalized analytic boundary representation}
 \end{array}
 \label{eq:four-master-relations}
\end{equation}
No count obtained from one row of
Eq.~\eqref{eq:four-master-relations} is substituted for a count from
another.

\subsection{Independent numerical comparison}
\label{subsec:amflow-comparison}

After an analytic expression has been obtained, it is compared with an
independent numerical evaluation at physical points away from singular
hypersurfaces.  For a chosen point \(\boldsymbol x_\star\), write
\begin{equation}
 M_a^{\rm ana}(\boldsymbol x_\star,\eps)
 =
 \sum_{n=n_a^{\min}}^{N_\eps}
 m_{a,n}^{\rm ana}(\boldsymbol x_\star)\eps^n
 +
 O\!\left(\eps^{N_\eps+1}\right).
 \label{eq:analytic-master-at-check-point}
\end{equation}
An \AMFlow\ evaluation is generated from the same denominator family, cut
slots, cut orientations, ordinary causal prescriptions, integration
measure, and external invariants \cite{Liu:2020kpc}.  Its numerical Laurent
coefficients
\begin{equation}
 m_{a,n}^{\rm AMF}(\boldsymbol x_\star)
 \label{eq:amflow-laurent-coefficients}
\end{equation}
are compared coefficient by coefficient with
\(m_{a,n}^{\rm ana}\) at a declared precision.

This comparison tests the normalization, causal boundary value, branch
choice, boundary matching, and differential transport of the analytic
result.  It does not determine the functional form, prove an analytic
boundary identity, or supply a missing exact period.  Numerical values are
verification data only; the result entering the hard function is the exact
analytic master expression.

## Sources sent to Pro

- [manuscript_05_analytic_masters.tex](Sources/11_manuscript_05_analytic_masters/manuscript_05_analytic_masters.tex)
