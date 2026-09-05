# Manuscript Final Manuscript

## Question

The attached archive contains the complete active LaTeX manuscript after the
section-by-section rewrite: main_collinear.tex, references.bib, and every file
under sections/ and appendices/.

Perform a final physics and notation consistency review. Do not rewrite the
manuscript wholesale and do not invent calculations, equations, or references.
Return:

1. A prioritized list of remaining contradictions, unsupported claims,
   normalization or branch inconsistencies, undefined notation, and misleading
   scope statements, with the exact file and quoted text.
2. Compilable replacement LaTeX only for passages that must change.
3. A short statement of whether the abstract, introduction, worked NLO example,
   NNLO section, reproducibility section, alternatives appendix, and conclusion
   now describe the same scientific scope.

Check especially:

- the NLO bubble--top boundary count: bubble normalization and regularity fix
  the top, with no independent non-elementary NLO boundary integration;
- the distinction between individual-master modes and endpoint sectors of the
  assembled hard coefficient;
- the limited UU fixed-order comparison and the absence of a complete
  polarized NLO hard function;
- the meanings of 342, 130, 82, and 17 in the NNLO double-real section;
- the limited scope of the one reconstructed NNLO rational coefficient and the
  selected eight-, four-, and five-master analytic families;
- the distinction between exact analytic masters and AMFlow fixed-point
  comparisons;
- consistency of cut normalization, causal prescriptions, BMHV dimension
  shifts, hard-function normalization, and endpoint-distribution conventions;
- all cross-references and notation used across files.

Do not request or perform a new integral calculation.

## Pro response

The manuscript is close to internally consistent, but several changes remain necessary before it is submission-ready. The static source audit found no duplicate labels, undefined cross-references, or missing bibliography keys. The remaining issues are physical scope, notation, formal definitions, and source completeness.

1. Prioritized remaining findings
P0 — must be corrected
1. The title and abstract still overstate the demonstrated result

File: main_collinear.tex

Current title:

\title{\FACETtitle: Exact analytic hard functions for polarized single-inclusive hadron production}

This reads as a completed polarized hard-function calculation. The manuscript establishes:

the complete NLO real-emission cut-master system;

exact UU and TT hadronic-variable reduction;

the singular UU fixed-order comparison;

the NNLO double-real 342-master IBP reduction;

one reconstructed nontrivial NNLO rational master coefficient;

selected eight-, four-, and five-master analytic families.

It does not establish a complete polarized NLO hard function or a complete NNLO hard function.

The abstract also ends with:

“The remaining task is the analytic evaluation and assembly of the full NNLO master basis.”

That omits the unreconstructed NNLO rational coefficients and, for a complete NNLO hard function, the real–virtual, double-virtual, renormalization, and factorization terms.

The FACET-NLO branding is also inconsistent with the stated decision that the public name remains under reconsideration.

2. The symbol x has two incompatible global meanings

File: sections/02_factorization.tex

x:=1-w.

File: sections/07_nnlo_double_real.tex

x:=-\frac{t}{s},

y:=-\frac{u}{s}.

File: appendices/A_conventions.tex

\(v,w,x\) & Single-inclusive variables with \(x=1-w\)

This is a genuine notation contradiction. In the NLO section, powers such as x
−1−2ϵ
 mean (1−w)
−1−2ϵ
. In the NNLO section, x means −t/s. The same manuscript must not use one symbol for both.

The least disruptive correction is to retain

x=1−w

in Sections 2 and 6 and rename the NNLO variables

X=−
s
t
	​

,Y=−
s
u
	​

.

Every x,y local to Section 7 must then be changed to X,Y, including A
x
	​

,A
y
	​

, the alphabet, GPL arguments, the reconstruction field, and the AMFlow ratio.

3. The provided archive is not currently self-contained or robustly compilable

File: main_collinear.tex

The manuscript uses:

\bm in \dd^3\bm P_h;

\mathscr throughout;

\Log in Section 5.

But the preamble does not load bm or mathrsfs, and \Log is not defined. A compile check stopped first at \bm; after supplying that package, \mathscr and \Log also required correction.

The archive also sets

\showfacetlogotrue

and references:

figures/facet_nlo_title.pdf;

figures/facet_nlo_logo.pdf;

but no figures/ directory is included. The archive also omits jheppub.sty; that may be supplied by the Overleaf project or journal template, but the two FACET image files are custom assets and cannot be assumed.

4. The noncut family factor is used but never defined

File: sections/04_ibp_coefficients.tex

\prod_{j\notin C}\mathscr P_j^{(\nu_j)}(\Delta_j)

File: appendices/C_topology_equivalence.tex

\prod_{i\,\mathrm{noncut}}\mathscr P_i^{(\nu_i)}(\Delta_i)

Appendix A defines

P
σ
(n)
	​

(Δ)=(Δ+i0σ)
−n
,

but neither \mathscr P_j nor \mathscr P_i is defined. A single piecewise object should be introduced for forward, conjugate, shared-real, absent, and numerator slots.

5. Appendix C does not yet give fully formal equivalence relations

File: appendices/C_topology_equivalence.tex

Current text:

“We write T∼
top
	​

T
′
 when …”

and later:

“We call Eq. … powered-integral equivalence …”

and:

“positive-denominator equivalence … requires …”

The appendix specifies most of the correct mapping conditions, but it does not yet:

define the carrier set of topology records;

give an explicit if-and-only-if definition of ∼
top
	​

;

define the carrier set of powered integrals;

give an if-and-only-if definition of ∼
pow
	​

;

define the positive-denominator set Z(I);

give an if-and-only-if definition of ∼
den
	​

;

define denominator inclusion in the same appendix;

establish reflexivity, symmetry, and transitivity.

Section 7 consequently introduces a second local definition using
P
+
	​

(I), rather than using one manuscript-wide relation.

There is also a notation collision:

d_i=(\Delta_i,\tau_i,\omega_i,\mathfrak m_i)

Here m
i
	​

 denotes a measurement label, while Section 2 uses
m
P
	​

 for the momentum-fraction monomial. Rename the slot annotation to a
i
	​

.

6. Appendix D contains two literal mathematical source errors

File: appendices/D_bmhv_dimension_shift.tex

Current text:

\mu_\ell^2=-\widehat\ell^{,2}

and

\sum_{a,b=1}^{L}ell_a\cdot

These must be

μ
ℓ
2
	​

=−
ℓ
2

and

a,b=1
∑
L
	​

ℓ
a
	​

⋅A
ab
	​

ℓ
b
	​

.

The one-loop Pochhammer factor and sign are otherwise consistent with the normalized measure.

P1 — scientifically important
7. The representative NNLO coefficient is not identified in the manuscript

File: sections/07_nnlo_double_real.tex

“consider one representative master M
⋆
	​

 … Its family and powered-denominator vector are retained in the accompanying reconstruction record.”

The exact calculation is for

GLI[TopologyF10C25N1,{1,1,2,0,0,1,0,1,0}].

The master should be identified explicitly in the article. “Retained in the accompanying record” is insufficient, especially because no reconstruction record is included in the archive.

8. Several NNLO claims rely on ancillary material absent from the archive

File: sections/07_nnlo_double_real.tex

“The exact matrices A
x
	​

,A
y
	​

,T, and R
a
	​

 are not reproduced in this section. Their retained calculation record satisfies …”

and:

\texttt{ancillary/NNLO_three_particle_cut_master.wl}

No ancillary/ directory or exact matrices are present in the uploaded archive. Consequently, the following cannot be independently checked from the submitted source set:

the raw differential matrices;

the canonical transformation;

the constant residue matrices;

exact flatness and dlog reconstruction;

g
−1
	​

,g
0
	​

,g
1
	​

,g
2
	​

;

the complete ϵ
2
 result;

the exact four- and five-master family expressions.

These may remain claims in the article only if the corresponding exact ancillary files accompany the final submission. Text alone cannot repair this omission.

9. The Introduction still compresses “double-real completion” into “complete NNLO hard function”

File: sections/01_introduction.tex

“Reconstruction of the remaining rational coefficients, determination of the remaining independent boundary periods, analytic evaluation of the remaining master families, and assembly of the complete NNLO hard function remain to be done.”

Those steps would complete the NNLO double-real contribution, not the complete NNLO hard function. The latter additionally requires the real–virtual, double-virtual, ultraviolet-renormalization, and collinear-factorization contributions.

10. The Section 5 boundary-period relation is underdefined and uses a second symbol

File: sections/05_analytic_masters.tex

B_i\sim_\partial B_j

The project’s rigorous relation should act on normalized boundary representations, not merely on their values. It must retain:

oriented cycle;

normalized density;

physical chamber;

causal prescriptions;

cuts;

endpoint direction;

selected local mode;

branch.

Use one symbol, preferably

∼
bnd
	​

,

throughout. The powered and positive-denominator relations should be referenced from Appendix C rather than redefined informally.

11. The Aversa comparison is not independently normalized in the manuscript

File: sections/06_nlo_example.tex

“In the normalization adopted for the unpolarized comparison …”

followed by

H
UU,i
(1)
	​

=H
UU,i
(1),Aversa
	​

.

The manuscript does not display the conversion between:

the invariant observable used here;

J
h
	​

;

flux and spin/color averages;

the coupling convention;

the Aversa variables and normalization.

The scope of the comparison is correctly limited to
D
1
	​

, D
0
	​

, and δ(1−w), but the meaning of
H
Aversa
 must be defined. Either include the exact convention map or state explicitly that the equality is after the retained conversion to the manuscript normalization.

12. One reproducibility statement should distinguish master modes from assembled sectors

File: sections/08_reproducibility.tex

“the two allowed NLO endpoint sectors (1−w)
−1−\eps
 and (1−w)
−1−2\eps
”

This is correct for the assembled singular real-emission coefficient, but not for the individual masters. The master modes are

x
−ϵ
,x
−1−2ϵ
.

The first assembled sector receives an additional integer factor x
−1
 from a rational coefficient.

P2 — source quality and typography
13. A long process-chain equation is severely overfull

File: sections/03_cut_families.tex

The display

literal propagators \longrightarrow fixed-cut partial fractions ...

produced an overfull box of roughly 207 pt in the compile check. It should be broken across two lines.

14. Standardize the permutation push-forward notation

The source uses both

π
∗
	​

andπ
∗
	​

.

Use π
∗
	​

 consistently.

2. Required replacement LaTeX
main_collinear.tex: packages, title, and abstract

Add the packages after \usepackage{array}:

LaTeX
\usepackage{mathrsfs}
\usepackage{bm}

Disable the missing branding assets unless those files are restored:

LaTeX
\showfacetlogofalse

Replace the title and PDF title by:

LaTeX
\title{Toward exact analytic hard-scattering coefficients for
single-inclusive hadron production}

\hypersetup{
  pdftitle={Toward exact analytic hard-scattering coefficients for single-inclusive hadron production},
  pdfauthor={Zhong-Bo Kang, Werner Vogelsang, Congyue Zhang}
}

Replace the abstract by:

LaTeX
\abstract{
We develop an exact analytic treatment of real-emission cut integrals and
their hard-scattering coefficients for single-inclusive hadron production.
Ordered amplitude--conjugate-amplitude interferences are projected onto
leading-twist unpolarized, helicity, and transversity correlators, represented
by oriented positive-energy cuts, decomposed into complete scalar-integral
families, and reduced by cut-aware integration-by-parts identities.
Branch-sensitive powers, ordinary causal prescriptions, BMHV evanescent
contributions, and exact dependence on \(D=4-2\eps\) are retained throughout.

At NLO, the real-emission reduction contains one cut bubble and five
kinematic instances of one generic top integral.  They form a single
triangular differential system whose physical solution is fixed by the
elementary bubble normalization and regularity, without an independent
non-elementary boundary integral.  Its pullback to the single-inclusive
endpoint gives the two assembled sectors
\((1-w)^{-1-\eps}\) and \((1-w)^{-1-2\eps}\), from which the delta and plus
distributions follow analytically.  Exact removal of the declared collinear
factors has been verified in the UU and TT real-emission coefficients, and
the singular UU coefficients multiplying
\(\mathcal D_1(w)\), \(\mathcal D_0(w)\), and \(\delta(1-w)\) agree with an
independent fixed-order calculation.  This does not constitute a complete
polarized NLO hard function.

For the NNLO double-real sector, the cut-aware reduction contains 342 Kira
master entries, organized by certified relabelings into 130 powered-integral
classes and 82 positive-denominator classes, with 17 maximal nontrivial
positive-denominator geometries.  The number 17 is not a count of
differential systems or boundary periods.  One representative nontrivial
rational master coefficient has been reconstructed from its complete sparse
composition and verified by an exact characteristic-zero identity.  Selected
eight-, four-, and five-master families have analytic solutions through
\(\mathcal O(\eps^2)\), with independent fixed-point numerical comparisons.
The remaining NNLO double-real coefficients, master families, and boundary
periods have not yet been assembled into a complete double-real contribution
or a complete NNLO hard function.
}
sections/01_introduction.tex: final NNLO scope paragraph

Replace the paragraph beginning

“Reconstruction of the remaining rational coefficients …”

with:

LaTeX
Reconstruction of the remaining rational coefficients, determination of the
remaining independent boundary periods, analytic evaluation of the remaining
master families, and assembly of the complete NNLO double-real contribution
remain to be done.  A complete NNLO hard function additionally requires the
real--virtual and double-virtual contributions, ultraviolet renormalization,
and collinear factorization in the same normalization.
sections/05_analytic_masters.tex: causal logarithm

Replace Eq. \eqref{eq:causal-noninteger-power} by:

LaTeX
For \(X<0\) with causal sign \(\sigma=\pm1\), define
\begin{equation}
 \log_\sigma X
 :=
 \lim_{\eta\to0^+}\log(X+i\sigma\eta)
 =
 \ln|X|+i\pi\sigma,
 \qquad
 (X+i0\,\sigma)^\lambda
 :=
 \exp\!\bigl[\lambda\log_\sigma X\bigr].
 \label{eq:causal-noninteger-power}
\end{equation}
sections/04_ibp_coefficients.tex: define the noncut slot factor

Replace the opening of the fixed-cut-family subsection through the sentence defining \mathscr P_j by:

LaTeX
Let \(C\) be the cut slots of a complete family \(\mathcal F\).  For a
noncut slot with causal class
\(\chi\in\{F,C,S,M\}\), define
\begin{equation}
 \mathscr D_{\chi}^{(\nu)}(\Delta)
 :=
 \begin{cases}
  \mathcal P_{+}^{(\nu)}(\Delta),
  & \nu>0,\quad \chi=F,
  \\[1mm]
  \mathcal P_{-}^{(\nu)}(\Delta),
  & \nu>0,\quad \chi=C,
  \\[1mm]
  \Delta^{-\nu},
  & \nu>0,\quad \chi=S,
  \\[1mm]
  \Delta^{-\nu},
  & \nu\leq0 .
 \end{cases}
 \label{eq:noncut-slot-factor}
\end{equation}
The case \(\nu>0,\chi=M\) is excluded from the admissible index domain.

The fixed-cut integrand is
\begin{equation}
 \mathscr I_{\mathcal F}(\boldsymbol\nu)
 :=
 \prod_{c\in C}
 \mathcal C_{\xi_c}^{(\nu_c)}(\Delta_c;q_c)
 \prod_{j\notin C}
 \mathscr D_{\chi_j}^{(\nu_j)}(\Delta_j).
 \label{eq:cut-family-integrand-section4}
\end{equation}

In Eq. \eqref{eq:powered-integral-identity-main}, use:

LaTeX
\pi_\ast\boldsymbol\nu

rather than \pi_*\boldsymbol\nu.

appendices/C_topology_equivalence.tex: slot notation and scalar integral

Replace the slot descriptor by:

LaTeX
\begin{equation}
 \boldsymbol d=(d_1,\ldots,d_N),
 \qquad
 d_i=(\Delta_i,\tau_i,\omega_i,\mathfrak a_i).
 \label{eq:topology-slot-descriptor}
\end{equation}

Replace every later \mathfrak m_i in this appendix by \mathfrak a_i.

Replace the scalar-integral definition by:

LaTeX
With the normalized measure of Appendix~\ref{app:conventions}, define
\begin{align}
 I_{\mathcal T}^{(D)}(\boldsymbol\nu;\boldsymbol p)
 :={}&
 \int
 \prod_{r=1}^{L}
 \frac{\dd^D\lambda_r}{i\pi^{D/2}}
 \prod_{c\,\mathrm{cut}}
 \mathcal C_{\xi_c}^{(\nu_c)}(\Delta_c;q_c)
 \prod_{i\,\mathrm{noncut}}
 \mathscr D_{\chi_i}^{(\nu_i)}(\Delta_i),
 \label{eq:topology-scalar-integral}
\end{align}
where \(\mathscr D_{\chi}^{(\nu)}\) is defined in
Eq.~\eqref{eq:noncut-slot-factor}.

Replace the subsection Topology and powered-integral equivalence through the paragraph ending with Eq. \eqref{eq:powered-versus-denominator-equivalence} by:

LaTeX
\subsection{Topology, powered-integral, and positive-denominator relations}

Let \(\mathfrak T\) be the set of cut-decorated records satisfying
Eqs.~\eqref{eq:cut-topology-record}--
\eqref{eq:topology-admissible-indices}, with fixed numbers of phase-space,
forward-virtual, and conjugate-virtual variables and with the normalized
measure of Appendix~\ref{app:conventions}.

For \(\mathcal T,\mathcal T'\in\mathfrak T\), define
\begin{equation}
 \mathcal T\sim_{\rm top}\mathcal T'
 \quad\Longleftrightarrow\quad
 \begin{gathered}
  \text{there exist an allowed external relabeling \(\rho\), an affine map}\\
  \text{of Eqs.~\eqref{eq:topology-affine-map} and
  \eqref{eq:topology-sector-preserving-map},}\\
  \text{and a permutation \(\pi\in S_N\) satisfying
  Eqs.~\eqref{eq:topology-denominator-map}--\eqref{eq:topology-index-permutation}.}
 \end{gathered}
 \label{eq:topology-equivalence-definition}
\end{equation}
The conditions include exact denominator equality, preservation of slot type,
ordinary causal class, cut momentum and orientation, physical annotation
\(\mathfrak a_i\), kinematic relations, physical chamber, branches, and the
admissible index domain.

The relation \(\sim_{\rm top}\) is reflexive by the identity witness.
The inverse affine map, inverse external relabeling, and \(\pi^{-1}\) give
symmetry.  Composition of two witnesses preserves the sector-triangular
form, determinant \(\pm1\), denominator identities, cut data, physical
annotations, and admissible index domains; hence the relation is transitive.

Define the carrier set of powered cut integrals by
\begin{equation}
 \mathfrak I
 :=
 \left\{
  (\mathcal T,\boldsymbol\nu)
  \,\middle|\,
  \mathcal T\in\mathfrak T,\quad
  \boldsymbol\nu\in\mathfrak A_{\mathcal T}
 \right\}.
 \label{eq:powered-integral-carrier}
\end{equation}
For \(I=(\mathcal T,\boldsymbol\nu)\) and
\(J=(\mathcal T',\boldsymbol\nu')\) in \(\mathfrak I\), define
\begin{equation}
 I\sim_{\rm pow}J
 \quad\Longleftrightarrow\quad
 \begin{gathered}
  \mathcal T\sim_{\rm top}\mathcal T'
  \text{ with a witness whose slot map is }\pi,
  \\
  \boldsymbol\nu'=\pi_\ast\boldsymbol\nu,
  \qquad
  (\pi_\ast\boldsymbol\nu)_j
  :=
  \nu_{\pi^{-1}(j)} .
 \end{gathered}
 \label{eq:powered-integral-equivalence-definition}
\end{equation}
The identity, inverse, and composition of the topology witnesses show that
\(\sim_{\rm pow}\) is an equivalence relation.  Its defining change of
variables gives
\begin{equation}
 I_{\mathcal T}^{(D)}
 \bigl(\boldsymbol\nu;\rho(\boldsymbol p')\bigr)
 =
 I_{\mathcal T'}^{(D)}
 \bigl(\pi_\ast\boldsymbol\nu;\boldsymbol p'\bigr).
 \label{eq:topology-index-map}
\end{equation}

For \(I=(\mathcal T,\boldsymbol\nu)\in\mathfrak I\), define its
positive-denominator set by
\begin{equation}
 Z(I)
 :=
 \{d_i\in\boldsymbol d\mid \nu_i>0\}.
 \label{eq:positive-denominator-set}
\end{equation}
Each \(d_i\) retains the denominator polynomial, slot type, cut orientation
or ordinary causal class, and physical annotation, but \(Z(I)\) does not
retain the numerical value of a positive power.

Define
\begin{equation}
 I\sim_{\rm den}J
 \quad\Longleftrightarrow\quad
 \exists\,g\in\mathcal G_{\rm adm}
 \ \text{such that}\
 gZ(I)=Z(J),
 \label{eq:positive-denominator-equivalence-definition}
\end{equation}
where \(\mathcal G_{\rm adm}\) is the group of the same certified affine and
external maps restricted to the active slots.  Identity, inverse, and
composition make \(\sim_{\rm den}\) an equivalence relation.

On the quotient \(\mathfrak I/{\sim_{\rm den}}\), define
\begin{equation}
 [I]_{\rm den}\preceq_{\rm den}[J]_{\rm den}
 \quad\Longleftrightarrow\quad
 \exists\,g\in\mathcal G_{\rm adm}
 \ \text{such that}\
 gZ(I)\subseteq Z(J).
 \label{eq:denominator-inclusion-order}
\end{equation}
This relation is reflexive and transitive.  If both
\([I]_{\rm den}\preceq_{\rm den}[J]_{\rm den}\) and
\([J]_{\rm den}\preceq_{\rm den}[I]_{\rm den}\), finiteness gives equal
cardinalities and both inclusions are equalities after allowed maps.
Therefore \(\preceq_{\rm den}\) is a partial order on the quotient.

Powered-integral equivalence implies positive-denominator equivalence,
\begin{equation}
 I\sim_{\rm pow}J
 \quad\Longrightarrow\quad
 I\sim_{\rm den}J,
 \label{eq:powered-versus-denominator-equivalence}
\end{equation}
but the converse fails when positive powers, numerator powers, or inactive
completion slots differ.
sections/05_analytic_masters.tex: replace “Four distinct relations”
LaTeX
\subsection{Four distinct relations}

The carrier sets and exact if-and-only-if definitions of topology,
powered-integral, and positive-denominator equivalence are given in
Appendix~\ref{app:topology-equivalence}.  In particular,
\(\sim_{\rm pow}\) identifies complete powered cut integrals, while
\(\sim_{\rm den}\) identifies only their positive-denominator geometry.
Neither relation determines which masters mix under kinematic
differentiation.

For the exact matrices in
Eq.~\eqref{eq:master-differential-components}, draw an arrow
\(M_i\to M_j\) when
\((A_r)_{ij}\not\equiv0\) for at least one variable \(x_r\).  Write
\begin{equation}
 M_i\rightsquigarrow M_j
 \quad\Longleftrightarrow\quad
 \text{a directed path, possibly of length zero, connects \(M_i\) to \(M_j\)}.
 \label{eq:differential-reachability}
\end{equation}
The relation \(\rightsquigarrow\) is a preorder.  For
\(S\subseteq\{M_1,\ldots,M_{N_M}\}\), define
\begin{equation}
 \operatorname{cl}_{\rm DE}(S)
 :=
 \{M_j\mid M_i\rightsquigarrow M_j
 \text{ for some }M_i\in S\}.
 \label{eq:de-closure-definition}
\end{equation}
Mutual reachability,
\begin{equation}
 M_i\sim_{\rm DE}M_j
 \quad\Longleftrightarrow\quad
 M_i\rightsquigarrow M_j
 \ \text{and}\
 M_j\rightsquigarrow M_i,
 \label{eq:de-block-equivalence}
\end{equation}
is an equivalence relation whose classes are the strongly connected
differential blocks.

Let \(\mathfrak B\) be the set of normalized boundary representations
\begin{equation}
 \beta
 =
 \bigl(
  \Gamma_\beta(\lambda),
  \Omega_\beta(\lambda,\eps),
  \mathfrak C_\beta,
  \rho_\beta(\eps),
  k_\beta
 \bigr),
 \label{eq:boundary-representation-carrier}
\end{equation}
where the tuple records the oriented cycle, normalized density, physical
chamber with cuts and causal branches, endpoint exponent, and selected
logarithmic mode.  Define
\begin{equation}
 \beta\sim_{\rm bnd}\beta'
 \quad\Longleftrightarrow\quad
 \begin{gathered}
  \text{there exists an orientation-preserving analytic bijection }
  \phi_\lambda:\Gamma_\beta(\lambda)\to\Gamma_{\beta'}(\lambda),
  \\
  \phi_\lambda^\ast\Omega_{\beta'}=\Omega_\beta,
  \qquad
  \rho_\beta=\rho_{\beta'},
  \qquad
  k_\beta=k_{\beta'},
  \\
  \phi_\lambda
  \text{ preserves the endpoint direction, chamber, cuts, causal
  prescriptions, and branches.}
 \end{gathered}
 \label{eq:boundary-period-equivalence}
\end{equation}
Identity, inverse, and composition make \(\sim_{\rm bnd}\) an equivalence
relation.  Equivalent representations give the same normalized boundary
period.  The same equality may follow from another exact analytic identity,
but it is never inferred solely from denominator geometry or from numerical
agreement.

Thus \(\sim_{\rm pow}\) identifies complete powered integrals,
\(\sim_{\rm den}\) identifies positive-denominator geometry,
\(\operatorname{cl}_{\rm DE}\) and \(\sim_{\rm DE}\) determine derivative
coupling, and \(\sim_{\rm bnd}\) identifies normalized analytic boundary
representations.
sections/07_nnlo_double_real.tex: use the manuscript-wide denominator order

Replace lines defining P
+
	​

(I) and the local inclusion relation by:

LaTeX
The positive-denominator partial order
\(\preceq_{\rm den}\) is defined in
Eq.~\eqref{eq:denominator-inclusion-order}.  Among the 81 nontrivial
positive-denominator classes,
\begin{equation}
 N_{\rm max,nontrivial}^{\rm NNLO}=17
 \label{eq:nnlo-maximal-class-count}
\end{equation}
are maximal under this order.  The remaining 64 nontrivial classes are
included in at least one of these 17 classes, and no nontrivial class is left
without a maximal ancestor.

Replace the unidentified representative master by:

LaTeX
As a scaling test of the post-IBP coefficient calculation, consider
\begin{equation}
 M_\star
 :=
 \operatorname{GLI}
 \!\left[
  \mathrm{TopologyF10C25N1},
  \{1,1,2,0,0,1,0,1,0\}
 \right].
 \label{eq:nnlo-reconstructed-master}
\end{equation}
Its coefficient receives
\begin{equation}
 N_{\star}^{\rm contrib}=1129.
 \label{eq:nnlo-reconstructed-contribution-count}
\end{equation}
sections/07_nnlo_double_real.tex: resolve the x-notation collision

Use X,Y throughout Section 7. Replace the defining block by:

LaTeX
Define the NNLO dimensionless variables
\begin{equation}
 q:=k_a+k_b-k_c,
 \qquad
 X:=-\frac{t}{s},
 \qquad
 Y:=-\frac{u}{s},
 \qquad
 \Delta:=1-X-Y=\frac{q^2}{s}.
 \label{eq:nnlo-worked-variables}
\end{equation}
The analytic solution is constructed in the real chamber
\begin{equation}
 0<Y<(1-X)^2<1-X<1.
 \label{eq:nnlo-worked-chamber}
\end{equation}

Apply the same notation change throughout that file:

LaTeX
x\to X,\qquad
y\to Y,\qquad
A_x\to A_X,\qquad
A_y\to A_Y,\qquad
\partial_x\to\partial_X,\qquad
\partial_y\to\partial_Y.

In particular, change the reconstruction field to

LaTeX
\mathbb Q(C_A,C_F,\eps,X,Y),

the master functions to g
n
	​

(X,Y), and the AMFlow ratio to
R(X,Y;\eps).

Add this row to the symbol table in appendices/A_conventions.tex:

LaTeX
\(X,Y\)
& NNLO double-real ratios \(X=-t/s\) and \(Y=-u/s\), used only in
Sec.~\ref{sec:nnlo-double-real}.\\

Retain the existing row x=1−w.

sections/06_nlo_example.tex: define the comparison notation conservatively

Insert before Eq. \eqref{eq:nlo-uu-singular-comparison}:

LaTeX
Here
\(H_{\mathsf{UU},i}^{(1),\mathrm{Aversa}}\)
denotes the coefficient of Ref.~\cite{Aversa:1988vb} after conversion to the
same variables, coupling convention, flux and spin/color normalization, and
collinear-factorization convention used on the left-hand side.  The explicit
normalization map must accompany the final comparison record; without that
map, Eq.~\eqref{eq:nlo-uu-singular-comparison} is not independently
reproducible from the manuscript alone.

If the normalization map is added explicitly elsewhere, the final sentence may be removed.

sections/08_reproducibility.tex: endpoint-scope wording

Replace the second item in the scope list by:

LaTeX
\item the two endpoint sectors of the assembled singular NLO real-emission
coefficient,
\((1-w)^{-1-\eps}\) and \((1-w)^{-1-2\eps}\), together with their exact
distributional expansion; the corresponding individual-master modes are
\(x^{-\eps}\) and \(x^{-1-2\eps}\);
appendices/D_bmhv_dimension_shift.tex: literal corrections

Replace:

LaTeX
is \(\mu_\ell^2=-\widehat\ell^{\,2}\); a numerator
\((\widehat\ell^{\,2})^r\) would instead give
\((-1)^r(-\eps)_r\).

Replace Eq. \eqref{eq:loop-quadratic-form} by:

LaTeX
\begin{equation}
 \sum_{j=1}^{N}\alpha_j\Delta_j
 =
 \sum_{a,b=1}^{L}
 \ell_a\cdot A_{ab}(\boldsymbol\alpha)\ell_b
 +
 2\sum_{a=1}^{L}
 \ell_a\cdot B_a(\boldsymbol\alpha)
 +
 C(\boldsymbol\alpha).
 \label{eq:loop-quadratic-form}
\end{equation}
sections/03_cut_families.tex: break the overfull construction chain
LaTeX
\begin{equation}
 \begin{aligned}
 \text{literal propagators}
 &\longrightarrow
 \text{fixed-cut partial fractions}
 \longrightarrow
 \text{independent literal subsets}
 \\
 &\longrightarrow
 \text{complete scalar-product families}.
 \end{aligned}
 \label{eq:family-construction-order}
\end{equation}
3. Scope consistency after these changes

The worked NLO section, reproducibility section, alternatives appendix, and conclusion already describe essentially the same scientific scope:

six NLO cut masters;

one distinct triangular bubble–top system;

one independent elementary normalization;

no non-elementary NLO boundary integration;

individual-master modes distinguished from the two assembled endpoint sectors;

only the singular UU fixed-order comparison;

no complete polarized NLO hard function.

The current NLO count is the one justified by the displayed differential equation. Some older retained inventory documents still state “two analytic inputs” and “one nontrivial boundary integration”; those records are obsolete relative to the final derivation and should not be used to restore the old count. 

BOUNDARY_FAMILY_INVENTORY

 

boundary_equivalence_draft

 

BOUNDARY_FAMILY_INVENTORY

The NNLO section, reproducibility section, alternatives appendix, and conclusion are also scope-consistent:

342 Kira master entries;

130 powered-integral classes;

82 positive-denominator classes;

17 maximal nontrivial positive-denominator geometries;

one exactly reconstructed representative rational coefficient;

selected eight-, four-, and five-master analytic families;

AMFlow only as a fixed-point comparison;

no claim that the full 342-master set or full NNLO hard function is solved.

Those counts and their non-equivalence to boundary-period counts agree with the retained exact inventory. 

BOUNDARY_FAMILY_INVENTORY

 

boundary_equivalence_draft

 

BOUNDARY_FAMILY_INVENTORY

The abstract and title are the remaining scope mismatch. After the replacement abstract and neutral title above, all seven requested components will state the same scientific result. The manuscript’s treatment of numerical values is otherwise consistent with the project requirement that the deliverable be an exact analytic function and that finite-field or AMFlow values be used only for reconstruction or verification. 

README

 

AGENTS

 

AGENTS

## Sources sent to Pro

- [manuscript_final_manuscript_sources.zip](Sources/17_manuscript_final_manuscript/manuscript_final_manuscript_sources.zip)
