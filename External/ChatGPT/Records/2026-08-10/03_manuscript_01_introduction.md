# Manuscript 01 Introduction

## Question

We are continuing the calculation-first rewrite of the FACET-NLO manuscript.
The attached file is the current complete draft of Section 1, Introduction.
Review it against the manuscript structure and scientific scope already agreed
in this conversation.

Return:
1. A concise list of statements that are stale, stronger than the available
   calculation, ambiguous, or poorly placed.
2. Compilable replacement LaTeX for this section only.

Requirements:
- Write as a QCD paper, organized around the observable and analytic
  calculation rather than software.
- Keep the exact analytic hard function as the objective. Numerical values are
  independent checks only.
- Do not claim a complete NNLO result. The established NNLO facts are an exact
  342-master double-real IBP reduction, exact reconstruction of a
  representative rational coefficient, and analytic solutions of selected
  master families.
- Do not claim a complete polarized NLO hard function. The established
  fixed-order comparison is the singular UU coefficient; the NLO cut-master
  system itself is known analytically.
- Preserve the distinction among powered-integral equivalence, denominator
  equivalence, differential-equation closure, and equality of boundary
  periods.
- Do not add software detail that belongs in later sections.
- Use only citation keys already present in the manuscript bibliography.
- Avoid the words listed as discouraged in the repository policy when an
  accurate alternative exists.

Do not rewrite another section in this turn.

## Pro response

1. Required corrections

The statement that the analytic structures “cannot be reconstructed from values at isolated phase-space points” is too categorical. Rational functions can be reconstructed from sufficiently many modular evaluations once their algebraic class is fixed. The defensible statement is that ordinary numerical values alone do not specify endpoint distributions, causal boundary values, analytic branches, or BMHV terms. 

01_introduction

The calculation chain is presented as uniformly completed. Exact finite-field reconstruction is established for the NLO coefficients and for one representative NNLO double-real coefficient, not yet for all 342 NNLO master coefficients. The introduction should separate the general calculation method from the demonstrated NNLO extent. 

01_introduction

“The NLO real-emission problem provides a complete analytic example” can be misread as a complete NLO hard function. What is complete is the NLO real-emission cut-master system. The established fixed-order comparison is the singular UU coefficient; no complete polarized NLO hard function should be claimed. 

01_introduction

“Powered-integral identities” and “denominator identities” are imprecise. The manuscript must distinguish powered-integral equivalence, positive-denominator equivalence, closure or mixing under the reduced differential equations, and equality of normalized boundary periods. These relations count different objects. 

01_introduction

The NNLO summary omits the exact classification

342⟶130⟶82,N
max
	​

=17,

and does not state that 17 is not a count of differential systems, Frobenius coefficients, boundary integrations, or new periods. It also understates the completed analytic work: three selected families with eight, four, and five masters have been solved through O(\eps
2
), although only the eight-master family is developed in detail.

The introduction omits two established results that belong in its scope summary: exact removal of the hadronic momentum fractions and auxiliary hadronic vectors in the NLO UU and TT reductions, and exact characteristic-zero verification of a representative reconstructed NNLO coefficient.

The final roadmap is appropriately placed, but the introduction should first state clearly what remains unfinished: reconstruction of the remaining NNLO coefficients, analytic evaluation of the remaining master families and boundary periods, and assembly of the full NNLO hard function. 

01_introduction

2. Replacement LaTeX
LaTeX
\section{Introduction}
\label{sec:introduction}

Single-inclusive hadron production probes short-distance QCD through its
convolution with parton distributions and fragmentation functions
\cite{Collins:1989gx,Bacchetta:2006tn}.  At fixed perturbative order, the
partonic hard functions are distributions rather than ordinary functions of
the measured kinematics.  In dimensional regularization they contain Laurent
poles in
\begin{equation}
  D=4-2\eps,
\end{equation}
noninteger powers near the real-emission endpoint, coefficients multiplying
\(\delta(1-w)\) and plus distributions, and branch information inherited from
causal propagators and physical cuts.  Polarized channels additionally retain
evanescent contributions associated with the BMHV treatment of
\(\gamma_5\) and transverse-spin tensors.  Ordinary numerical values at a
finite set of phase-space points do not by themselves specify these analytic
and distributional data.  The objective of this work is therefore an exact
analytic hard function in which the \(\eps\) dependence, endpoint powers,
physical branches, delta functions, and plus distributions remain explicit.

We develop the calculation from the factorized observable to the reconstructed
partonic coefficient.  Ordered amplitude--conjugate-amplitude interferences
are projected onto leading-twist collinear density matrices.  Real-emission
phase space is represented by oriented positive-energy cuts through reverse
unitarity \cite{Anastasiou:2002yz}.  The literal propagators of each
interference are decomposed into cut-preserving partial fractions before
complete integral families are constructed.  Physical four-dimensional
spin tensors and evanescent scalar products are reduced through normalized
BMHV dimension recurrences where required, and the resulting scalar
integrals are reduced by integration-by-parts identities.  After the IBP
reduction, the rational coefficients of the master integrals are reconstructed
exactly over finite fields, with branch-sensitive and nonrational factors kept
outside the reconstructed rational functions.  The cut masters themselves are
evaluated analytically, either from direct physical parameterizations or from
differential equations with analytic boundary data.  Numerical integral
evaluations are used only as independent comparisons with the resulting
analytic formulas.

The NLO real-emission cut-master system provides a complete worked example of
this chain.  Its six physical masters consist of one elementary cut bubble and
five kinematic instances of a single generic top integral.  The master system
therefore requires two analytic inputs in total: the cut-bubble normalization
and one generic top boundary value.  Once the elementary bubble is regarded as
known, only one non-elementary boundary integration remains.  An angular
integration-by-parts identity gives a triangular differential system for the
bubble and top integrals.  Its exact connection formula separates the regular
and singular endpoint branches before expansion in \(\eps\), allowing the
noninteger powers to be converted analytically into
\(\delta(1-w)\) and plus distributions.  The resulting singular coefficient
in the unpolarized channel is compared with an independent fixed-order NLO
calculation.

The NLO calculation also provides an exact check of collinear factorization at
the level of the reconstructed coefficients.  In both the unpolarized and
transversely polarized real-emission sectors, removal of the declared PDF/FF
product, convolution measure, and universal momentum-fraction monomial leaves
hard coefficients that are independent of \(x_a\), \(x_b\), and \(z_h\), as
well as of the auxiliary hadronic basis vectors.  In the transverse channel,
the remaining spin dependence is carried only by the independent physical
azimuthal tensors.  These results establish the hadronic-variable reduction
and the analytic cut-master system, but they do not constitute a complete
polarized NLO hard function.

For the NNLO double-real sector, the corrected cut-aware IBP reduction contains
342 master integrals.  Keeping every propagator and cut power gives 130 classes
under the certified momentum relabelings.  Replacing every positive power by
one and repeating the relabeling test gives 82 positive-denominator classes,
one of which contains only the three physical cuts.  Among the remaining
classes, 17 are not contained in any larger nontrivial positive-denominator
class.  These numbers describe the reduced integral geometry.  They do not
determine the number of coupled differential systems, free Frobenius
coefficients, direct boundary integrations, or genuinely new analytic
periods.

This distinction is essential throughout the paper.  Powered-integral
equivalence retains every denominator exponent.  Positive-denominator
equivalence retains the denominator geometry and oriented cuts but forgets
positive powers.  Closure and mixing under kinematic differentiation are
properties of the reduced differential equations.  Equality of normalized
boundary periods additionally requires the same integration cycle,
normalization, physical chamber, causal prescription, branch, and selected
local mode.  The corresponding relations are defined separately below, and
no count obtained from one of them is substituted for another.

The present NNLO results establish several parts of the required calculation
without yet giving a complete NNLO hard function.  One nontrivial rational
master coefficient has been reconstructed from the full sparse
target-to-master composition and verified by an exact characteristic-zero
identity.  Three selected differential-equation families, containing eight,
four, and five masters, have analytic GPL solutions through
\(\mathcal O(\eps^2)\); the coupled eight-master family is presented as the
detailed NNLO example.  Reconstruction of the remaining rational
coefficients, determination of the remaining independent boundary periods,
analytic evaluation of the remaining master families, and assembly of the
complete NNLO hard function remain separate steps.

The paper follows this analytic calculation in order.
Section~\ref{sec:factorized-observable} defines the single-inclusive
observable, partonic kinematics, polarization projections, and hard-function
normalization.  Section~\ref{sec:cut-families} derives the cut integral
families from ordered amplitude interferences and describes the treatment of
causal sectors and BMHV numerators.
Section~\ref{sec:ibp-coefficients} presents the cut-aware IBP reduction and
the exact reconstruction of rational master coefficients.
Section~\ref{sec:analytic-masters} develops the direct-integration and
differential-equation methods for the cut masters and defines the distinct
relations among master integrals, differential systems, and boundary periods.
Section~\ref{sec:nlo-example} gives the connected NLO calculation, including
its endpoint distributions.  Section~\ref{sec:nnlo-double-real} presents the
NNLO double-real reduction, the representative coefficient reconstruction,
and the selected analytic master families.
Section~\ref{sec:reproducibility} states the exact identities and stopping
conditions required at each stage of the calculation.

## Sources sent to Pro

- [manuscript_01_introduction.tex](Sources/03_manuscript_01_introduction/manuscript_01_introduction.tex)
