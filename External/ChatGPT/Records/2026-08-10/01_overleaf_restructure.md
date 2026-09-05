# Overleaf Restructure

## Question

The attached file is the exact current Overleaf source, main_collinear.tex.
We now need to reorganize and rewrite it as a coherent QFT/QCD paper. This
turn is only for the scientific structure. Do not yet rewrite the prose.

The present manuscript mixes five different things: the physics derivation,
a detailed NNLO master calculation, package internals, dated calculation
records, and discarded alternatives. Several numerical inventories and
software names are stale. The paper should instead follow the analytic
calculation from the factorized observable to the exact hard function.

Current facts that supersede dated statements in the attachment include:

- The required result is an exact analytic hard function with complete
  epsilon, endpoint, delta-function, and plus-distribution dependence.
- Numerical AMFlow values are independent checks, not the analytic output.
- The current exact chain is process card -> FeynArts amplitudes -> twist-2
  density traces -> cut phase space -> cut-preserving partial fractions ->
  complete integral families -> BMHV dimension shifts where needed -> Kira
  IBP -> Ratracer/FireFly reconstruction of rational master coefficients ->
  analytic master evaluation using direct physical parameterizations or exact
  differential equations with analytic boundary data -> hard-function
  reconstruction and endpoint distributions.
- NLO UU and TT hadronic-variable reduction has been checked exactly: after
  removing the declared PDF/FF and measure factor, the hard coefficients are
  independent of the momentum fractions and auxiliary hadronic vectors.
- The current NNLO double-real reduction has 342 Kira masters. After certified
  relabelings there are 130 power-aware master orbits, 82 denominator-support
  orbits, one elementary cut-only orbit, and 17 maximal nontrivial support
  families. Seventeen is a family-level count, not yet the number of free
  Frobenius constants or genuinely new boundary periods.
- One difficult NNLO master coefficient has been reconstructed exactly with
  Ratracer and FireFly and independently checked. This is a scaling study, not
  a complete NNLO coefficient reconstruction.
- The 83bb, f228, and d099 differential-equation families have analytic GPL
  solutions through epsilon squared and selected AMFlow comparisons. This is
  not a full NNLO hard function.
- Event shapes are no longer an immediate target.
- The public name is under reconsideration; do not make the structure depend
  on FACET-NLO branding.

My proposed scientific structure is:

1. Introduction
   - physical problem and why exact analytic automation matters;
   - demonstrated scope versus future scope;
   - concise list of physics results and methodological contributions.

2. Factorized observable and conventions
   2.1 Hadronic and partonic kinematics, invariants, and physical region
   2.2 Leading-twist PDF/FF density matrices and UU, LL, TT projections
   2.3 Definition, normalization, and required analytic content of the hard
       function

3. From amplitudes to cut integral families
   3.1 Ordered amplitude-conjugate pairs and spin/polarization sums
   3.2 Phase space, reverse unitarity, cut orientation, and normalization
   3.3 Cut-preserving partial fractions and complete denominator families
   3.4 BMHV evanescent numerators and normalized dimension recurrences

4. IBP reduction and exact master coefficients
   4.1 Cut-aware topology equivalence and family reuse
   4.2 Kira reduction and the precise identity of a cut master
   4.3 Ratracer/FireFly reconstruction of rational coefficients
   4.4 Removal of universal PDF/FF and momentum-fraction factors

5. Analytic evaluation of cut master integrals
   5.1 Physical parameterizations and branch certification
   5.2 Direct analytic integration with SubTropica
   5.3 Differential equations, canonical form, and analytic boundary data
   5.4 Relations among masters, boundary families, and independent periods
   5.5 Independent numerical verification with AMFlow

6. Complete NLO worked calculation
   6.1 The six physical masters and their reduction to two analytic inputs
   6.2 Exact bubble and top integrals and their differential equation
   6.3 Endpoint modes, connection formula, and the two soft branches
   6.4 Pullback to w and conversion to delta(1-w) and plus distributions
   6.5 Reconstruction of the polarized hard functions and comparison with the
       independent NLO calculation

7. NNLO double-real extension
   7.1 Diagram-pair, target, master, orbit, and maximal-support inventories
   7.2 Exact rational coefficient reconstruction
   7.3 Worked 83bb differential-equation family
   7.4 What is known and what remains: boundary periods, remaining families,
       and full hard-function reconstruction

8. Reproducibility and scientific failure conditions
   8.1 Process cards and immutable mathematical input
   8.2 Exact artifacts retained between stages
   8.3 Required identities and explicit stopping conditions
   8.4 Roles of FeynArts, FeynCalc, Kira, Ratracer, FireFly, SubTropica,
       Libra, and AMFlow

9. Conclusions and outlook

Appendices
A. Normalizations, cut conventions, and symbol table
B. Fixed-sign theorem for non-virtual phase-space propagators
C. Precise cut-aware topology equivalence and examples
D. Reproducibility details and compact software-to-physics map
E. Alternative routes that were examined but are not the present calculation

Please act as a QCD theorist editing a paper, not as a software-documentation
reviewer. Inspect the attached source and return:

1. a revised section/subsection structure;
2. for every current section, one of KEEP, MOVE, MERGE, REWRITE, or REMOVE,
   with its destination and a concrete reason;
3. material missing from the proposed structure;
4. stale, overclaimed, internally inconsistent, or insufficiently defined
   statements in the current source;
5. a recommended order for rewriting the sections in later turns.

Use physicist language. Preserve the connected derivations, especially the
complete NLO endpoint analysis and the 83bb NNLO family, but move implementation
details that do not establish a mathematical step out of the main narrative.
Do not invent references or numerical results.

## Pro response

Overall assessment

The proposed structure is directionally correct, but it needs four scientific adjustments.

First, the paper should define the partonic hard function itself—including its perturbative expansion, normalization, polarization labels, and endpoint-distribution content—before discussing the machinery used to compute it. The current manuscript gives only a schematic factorization formula and a collinear momentum map. 

main_collinear(3)

Second, a “complete NLO worked calculation” must explicitly include the virtual contribution, ultraviolet renormalization, and collinear subtraction. The current source acknowledges that reverse unitarity does not supply those terms, but does not derive their combination with the real contribution. 

main_collinear(3)

 Without that material, the paper can present a complete NLO real-emission calculation but not yet a complete NLO hard function.

Third, the causal treatment of shared phase-space denominators and amplitude/conjugate virtual loops belongs in the main physics chain. It should not be left implicit or described only through implementation metadata.

Fourth, the present two-part division into “Concepts and formulae” and “Implementation record” should be removed. The source explicitly announces this split and then devotes nearly one third of the manuscript to package ownership, notebook names, code calls, dated status tables, and test records. 

main_collinear(3)

 A QCD paper should instead follow the observable through amplitudes, cut integrals, IBP reduction, analytic masters, and the reconstructed hard function.

1. Revised section and subsection structure
1 Introduction

Physical problem: exact perturbative hard functions for single-inclusive hadron production.

Why exact ϵ, endpoint, delta-function, plus-distribution, causal, and branch information is required.

Relation to conventional diagrammatic, IBP, finite-field, and differential-equation calculations.

Demonstrated scope:

exact NLO UU and TT hadronic reduction;

complete cut-aware NLO master calculation;

exact NLO endpoint analysis;

complete NNLO double-real IBP basis with 342 masters;

one deterministically certified NNLO rational master coefficient;

analytic solutions of the three selected NNLO differential-equation families through ϵ
2
.

Explicitly uncompleted scope:

all 342 NNLO coefficients;

all independent NNLO boundary periods;

the full NNLO hard function;

evolution, convolution, uncertainty propagation, and comparison with data.

A concise results table would be appropriate here, but it should contain only current, mathematically defined quantities.

2 Factorized observable, kinematics, and hard-function definition
2.1 Hadronic cross section and perturbative expansion

Define the measured single-inclusive observable and its factorized form. Introduce the perturbative expansion of the partonic hard functions, for example

H
ab→c
	​

=
n≥0
∑
	​

(
4π
α
s
	​

	​

)
n
H
ab→c
(n)
	​

.

State exactly which normalization is used for H
(n)
.

2.2 Hadronic and partonic kinematics

Define

k
a
	​

=x
a
	​

P
a
	​

,k
b
	​

=x
b
	​

P
b
	​

,P
h
	​

=z
h
	​

k
c
	​

,

together with

s=(k
a
	​

+k
b
	​

)
2
,t=(k
a
	​

−k
c
	​

)
2
,u=(k
b
	​

−k
c
	​

)
2
,Q
2
=s+t+u.

Introduce v,w and the endpoint w→1
−
 here, rather than first introducing them in the NLO endpoint section.

2.3 Leading-twist correlators and polarization projections

PDF and FF density matrices.

Antiquark conventions.

Explicit definitions of UU, LL, and TT hard projections.

BMHV convention for γ
5
	​

 and physical transverse-spin vectors.

Spin and azimuthal basis used in the TT result.

2.4 Definition and required analytic content of the hard function

Define what has been divided out:

PDF and FF product;

convolution measure;

conventional momentum-fraction monomial;

coupling and phase-space normalization.

State the required result:

H
(n)
(s,t,u;ϵ)

with its endpoint decomposition,

H
(n)
(v,w;ϵ)=H
δ
(n)
	​

(v;ϵ)δ(1−w)+
m≥0
∑
	​

H
m
(n)
	​

(v;ϵ)D
m
	​

(w)+H
reg
(n)
	​

(v,w;ϵ).

This section should also state the exact fraction-independence criterion verified for UU and TT.

3 From amplitudes to cut integral families
3.1 Ordered amplitude–conjugate interferences

Generation of amplitudes.

Complex conjugation.

Spin and polarization sums.

Replacement by leading-twist density matrices.

Why ordered pairs are retained until their exact contributions are combined.

3.2 Phase space, reverse unitarity, and causal sectors

Physical phase-space measure and normalization.

Positive-energy cuts.

Differentiated cuts.

Independent forward and conjugate virtual-loop variables.

Phase-space, forward-virtual, and conjugate-virtual momentum sectors.

Rejection of an active denominator depending simultaneously on forward and conjugate virtual loops.

Conditions under which an ordinary phase-space-only denominator can be treated without an explicit i0.

The main text should state the fixed-sign result as a theorem or corollary; its full proof should be moved to Appendix B.

3.3 Cut-preserving partial fractions and complete integral families

Literal amplitude denominators.

Exact cut-preserving partial fractions.

Construction of complete scalar-product bases.

Auxiliary inverse propagators and irreducible scalar products.

No-pinching condition for cut indices.

3.4 BMHV tensor numerators and normalized dimension shifts

This should include the current physical ordering:

isolate powers of evanescent scalar products;

treat the remaining physical tensor numerator in the shifted dimension;

reduce rank-one and rank-two physical tensor structures;

lower the resulting scalar integrals back to D=4−2ϵ;

preserve positive cut indices after each recurrence;

only then submit scalar GLIs to IBP.

The detailed tensor-projector and Gram-moment derivations can be placed in Appendix D.

4 IBP reduction and exact rational master coefficients
4.1 Cut-decorated topology equivalence

Give a concise main-text definition sufficient to justify family reuse:

affine rational loop-momentum maps;

unit Jacobian;

strict denominator permutation;

cut identity and orientation;

loop-sector ownership;

exponent transport;

physical line labels where required.

The complete mathematical definition, proof that the relation is an equivalence relation, and examples should be in Appendix C.

4.2 Cut-aware Kira reduction

Define a master by

M=(F,ν,C,ξ,S),

or the final chosen equivalent notation. Explain:

how cuts enter the Kira family;

how cut positivity is enforced;

how the exported rules are closed transitively;

how masters.final is checked;

how equivalent families are mapped to representatives.

4.3 Finite-field reconstruction of master coefficients

This section is missing from the present manuscript.

It should distinguish:

rational master coefficient

=analytic master integral.

Present the composition

C
m
	​

(z)=
T
∑
	​

c
T
	​

(z)R
Tm
	​

(z),

with z the declared rational variables. Explain:

exact physical normalization before modular evaluation;

deterministic analytic-basis channels;

Ratracer trace of the complete sparse composition;

FireFly reconstruction;

held-out finite-field comparisons;

characteristic-zero identity verification.

The master-64 calculation belongs later in Sec. 7.2 as a measured example.

4.4 Exact removal of hadronic and convolution factors

Exact hadronic coordinate substitution.

Positive-root branch certification.

Distribution-factor extraction.

Laurent valuation in x
a
	​

,x
b
	​

,z
h
	​

.

Proof that the remaining hard coefficients are fraction independent.

Exact UU and TT checks.

TT angular decomposition and vanishing of mixed structures.

5 Exact analytic evaluation of cut master integrals
5.1 Physical parameterizations and branch certification

Conversion of a cut integral into a real-domain parametric integral.

Jacobian and inverse map.

Positivity of all noninteger-powered bases.

Phase-space normalization.

Explicit physical chamber.

5.2 Direct analytic integration

SubTropica route.

Hyperlogarithmic or Euler representations.

Laurent-depth requirement.

Endpoint-safe grouping of terms.

Exact simplification after branch selection.

Avoid describing kernels, checkpoints, hashes, or job scheduling here.

5.3 Differential equations and analytic boundary data

Exact derivatives on the constrained kinematic manifold.

IBP reduction of derivatives.

Fuchsian and canonical forms.

Frobenius/Levelt modes.

Regularity and region constraints.

Exact boundary integrals.

Ordered Chen transport.

5.4 Relations among masters, boundary systems, and periods

Define separately:

power-aware master equivalence;

positive-denominator equivalence;

denominator inclusion;

differential-equation blocks;

scalar boundary coefficients;

normalized boundary functionals;

genuinely new periods.

This distinction is required because the current exact inventory gives 342 masters, 130 power-aware classes, 82 positive-denominator classes, and 17 maximal nontrivial positive-denominator classes, while the 17 classes are not a boundary-integral count. 

BOUNDARY_FAMILY_INVENTORY

5.5 Independent numerical verification

State the role of AMFlow precisely:

analytic formula⟶independent high-precision check.

Numerical values must not determine the analytic result, consistent with the project’s stated scientific contract. 

AGENTS

6 Complete NLO worked calculation

This should become the central connected derivation of the paper.

6.1 Reduction to six physical masters

Exact NLO phase space.

One cut bubble.

Five physical top instances.

Three positive-denominator classes.

Two maximal nontrivial denominator classes.

Two analytic inputs:

elementary bubble;

one generic top endpoint.

6.2 Bubble and generic top integral

Physical angular parameterization.

Bubble normalization.

Generic top density.

Exact hypergeometric result.

Scale factors and cross ratio.

6.3 Differential system and connection formula

Normalized bubble–top basis.

Angular IBP identity.

First-order differential system.

Integrating factor.

Boundary at z=0.

Residues and local modes at z=0 and z=1.

Exact connection formula.

Mapping to all five physical top masters.

6.4 Pullback to v,w and endpoint distributions

All five z
α
	​

(x).

x
−ϵ
 phase-space factor.

Individual master modes:

x
−ϵ
,x
−1−2ϵ
.

Integer shifts from rational hard coefficients.

Resulting sectors:

x
−1−ϵ
,x
−1−2ϵ
.

Exact conversion to δ(1−w) and plus distributions.

6.5 Virtual correction, ultraviolet renormalization, and collinear subtraction

This subsection is absent from the proposed structure and is necessary if the paper claims a complete NLO hard function.

It should specify:

virtual contribution;

coupling and field renormalization convention;

factorization counterterms;

distributional combination with the real contribution;

cancellation of poles;

final δ(1−w) coefficient.

6.6 Reconstructed UU, LL, and TT hard functions

State which partonic channels are included.

Give the final hard functions or an ancillary representation.

Demonstrate exact independence from x
a
	​

,x
b
	​

,z
h
	​

.

Give the TT azimuthal decomposition.

Compare with the independent established NLO calculation.

If only some polarization or channel sectors are complete, the title of this section must say so.

7 NNLO double-real extension
7.1 Exact reduction and positive-denominator classification

Use only the current inventory:

342⟶130⟶82⟶17.

State explicitly:

342 Kira masters;

130 power-aware master classes;

82 positive-denominator classes;

one elementary cut-only class;

17 maximal nontrivial classes;

zero nontrivial classes without a maximal ancestor.

Do not present 17 as the number of differential systems, scalar boundary constants, SubTropica integrations, or new periods.

7.2 Exact reconstruction of one difficult NNLO coefficient

Present the master-64 calculation as a scaling demonstration:

1,129 target contributions;

complete sparse composition;

monomial removal;

reconstruction in five rational variables;

two independent FireFly reconstructions;

held-out modular comparisons;

exact characteristic-zero identity.

State prominently that this is one coefficient, not the full set of 342 coefficients.

7.3 Coupled eight-master differential-equation family

Rename the section descriptively, for example:

A coupled eight-master three-particle-cut family

The internal key “83bb” can appear once in parentheses or in the ancillary-data description.

Retain the connected derivation:

physical cut integral and chamber;

nine-slot family and eight-master basis;

coupled top block;

exact differential equations;

canonical form;

three boundary modes;

independent top-corner period;

ordered GPL transport;

exact result through ϵ
2
;

AMFlow comparison.

7.4 Other solved families and reused boundary periods

Discuss f228 and d099 briefly as evidence that:

one boundary integral can determine several scalar coefficients;

distinct systems can reuse one normalized period;

master count does not equal boundary-integral count.

7.5 What remains for a complete NNLO hard function

reconstruction of the remaining rational coefficients;

differential-equation classification of the remaining maximal classes;

identification of independent boundary functionals;

analytic evaluation of the remaining periods;

full hard-function reconstruction and endpoint expansion;

combination with other NNLO contributions.

8 Reproducibility and scientific failure conditions
8.1 Immutable mathematical input

process definition;

polarization;

physical chamber;

cut identities and orientations;

BMHV scheme;

normalization;

requested Laurent depth.

8.2 Exact artifacts retained between stages

Only physically meaningful artifacts should be described:

amplitudes or trace-level coefficients;

cut families;

IBP rules;

master coefficients;

analytic master expressions;

boundary data;

reconstructed hard functions.

8.3 Required identities and stopping conditions

A compact table can state:

exact partial-fraction reconstruction;

no pinched cuts;

complete family;

exact topology map;

closed IBP rules;

exact finite-field reconstruction identity;

branch-certified master evaluation;

differential-equation residual;

exact boundary condition;

sufficient Laurent depth;

absence of forbidden variables;

endpoint-distribution reconstruction.

8.4 Role of external tools

One paragraph or table is sufficient:

FeynArts: diagrams;

FeynCalc: algebra and integral-family objects;

Kira: IBP;

Ratracer/FireFly: rational coefficient reconstruction;

SubTropica: direct analytic integration;

Libra: ordered canonical transport;

AMFlow: numerical verification.

Do not organize this section around repository directories, notebooks, hashes, or package ownership.

9 Conclusions and outlook

Separate three statements:

what has been demonstrated exactly;

what remains for the complete NNLO double-real hard function;

later extensions to evolution, convolution, resummation, and theory-to-data phenomenology.

Event shapes should not appear as an immediate goal.

Appendices
Appendix A: Conventions, normalizations, and symbol table
Appendix B: Fixed-sign theorem for phase-space-only propagators
Appendix C: Exact cut-decorated topology equivalence
Appendix D: BMHV tensor projectors and dimension recurrences
Appendix E: Reproducibility map and exact artifact definitions
Appendix F: Alternative formulations considered

Appendix F is optional. If retained, it should contain only scientifically relevant alternatives. Differential equations must not appear there because they are part of the current analytic method.

2. Disposition of every current section
Current heading	Action	Destination and reason
Scope and acceptance criterion	MERGE	Merge the physical scope into Sec. 1 and the exact-output definition into Sec. 2.4. The current description of a separate implementation layer should be deleted.
Part: Concepts and formulae	REMOVE	A normal QCD article should not divide physics from implementation by \part.
Collinear factorization and density projectors	REWRITE	Expand into Sec. 2. The present material is useful but lacks complete kinematics, polarization projections, hard-function normalization, and endpoint variables.
Cut integrals and invariant reduction	REWRITE	Split among Secs. 3.2, 3.3, and 4.2. Phase space, family construction, and IBP are distinct mathematical stages.
Fixed-sign theorem for non-virtual propagators	MOVE	Move the proof to Appendix B. Retain a concise theorem and its consequence in Sec. 3.2.
Cut-aware topology equivalence and family reuse	MOVE	Keep a compact definition and consequence in Sec. 4.1; move the full definition, proof, and examples to Appendix C.
The analytic master-integral agent	REWRITE	Replace the agent-centric framing with Sec. 5, “Exact analytic evaluation of cut master integrals.”
Post-IBP input contract	MERGE	Mathematical input belongs at the beginning of Sec. 5; immutable artifact details belong in Sec. 8.1.
Exact phase-space parameterization	KEEP	Retain the mathematical content as Sec. 5.1. Remove workflow language.
Analytic integration and exact simplification	REWRITE	Use as Sec. 5.2. Retain exact integration and branch logic; remove kernel and scheduling details.
Endpoint-safe coefficient jobs	REMOVE	Remove the hashing and checkpoint discussion. Move the useful endpoint-convergence argument into Secs. 5.2–5.3.
Exact relations and differential equations	REWRITE	Divide between Secs. 5.3 and 5.4. Differential equations are a primary method, not a fallback.
Acceptance hierarchy	MOVE	Convert into physically stated identities in Sec. 8.3. AMFlow belongs in Sec. 5.5.
Analytic evaluation of an NNLO three-particle cut master	MOVE	Move to Sec. 7.3 and rename it descriptively as an eight-master family calculation.
Physical cut integral and kinematics	KEEP	Retain as Sec. 7.3.1, after auditing normalization and causal prescriptions.
Integral family, IBP closure, and genuine coupling	KEEP	Retain as Sec. 7.3.2.
Flat differential system and canonical form	KEEP	Retain as Sec. 7.3.3.
Nonuniform boundary and the independent corner period	KEEP	Retain as Sec. 7.3.4. This is one of the strongest scientific parts of the paper.
Ordered iterated-integral transport	KEEP	Retain as Sec. 7.3.5. Package-function details should move to Sec. 8.4.
Normalized analytic result	KEEP	Retain as Sec. 7.3.6. Long coefficients should remain ancillary.
Independent fixed-point validation	MOVE	Retain the AMFlow comparison at the end of Sec. 7.3; move function names and package migration details to Sec. 8.4.
BMHV sectors and reconstruction	REWRITE	Split the BMHV derivation into Sec. 3.4 and Appendix D; move endpoint distributions to Sec. 6.4; move virtual/counterterm combination to Sec. 6.5.
Part: Implementation record	REMOVE	Eliminate the part division entirely.
Software architecture and data ownership	REMOVE	Notebook names, directories, and package ownership do not belong in the main article. Replace with the compact tool map in Sec. 8.4.
Collinear-factorization front end	MERGE	Its physics belongs in Secs. 2.3 and 3.1; the process-card concept belongs in Sec. 8.1. Remove the code listing.
Reduction and agent protocol	REWRITE	Redistribute its physics among Secs. 4, 5, and 8. Remove internal association examples and old record-count tests.
NNLO structural inventory	REWRITE	Replace completely with Sec. 7.1 using the current 342→130→82→17 inventory.
Validation record	REMOVE	Do not retain a separate dated status section. Put each result next to the corresponding physics calculation.
Verified coverage	REWRITE	Use current results in the Introduction, Sec. 6, Sec. 7, and Conclusions. Remove dated “pass” tables.
AMFlow verification	MOVE	Move the general role to Sec. 5.5 and the actual comparisons to the NLO and NNLO worked sections.
Other independent checks	MERGE	Exact mathematical checks belong in Sec. 8.3. Runtime and byte-identity records should not appear in the main paper.
Fail-fast checks and current boundary	REWRITE	Convert the mathematical conditions into Sec. 8.3; move the current NNLO boundary to Sec. 7.5 and the outlook to Sec. 9.
Alternative workflows explored	MOVE	Move selected material to optional Appendix F. Delete the differential-equation paragraph because differential equations are part of the current calculation.
3. Material missing from the proposed structure
3.1 A precise perturbative definition of the hard function

The paper must define the object being computed before describing its derivation. The current factorization equation is schematic and does not state the order-by-order normalization.

3.2 The full NLO combination

The proposed NLO structure needs a separate subsection for:

virtual terms;

UV renormalization;

collinear counterterms;

cancellation of poles;

final delta-function term.

Otherwise “complete NLO hard function” is too strong.

3.3 Causal classification of ordinary denominators

The paper needs a concise statement of:

forward-loop prescription;

conjugate-loop prescription;

shared phase-space variables;

rejection of active mixed-loop denominators;

exact fixed-sign certification for phase-space-only denominators.

3.4 A complete BMHV tensor-reduction statement

The existing BMHV section is too short and no longer reflects the actual dimension-shift ordering. The rank-one and rank-two physical-spin tensor identities should be stated.

3.5 Finite-field reconstruction

Ratracer and FireFly do not appear in the current source. The distinction between exact rational coefficient reconstruction and analytic master evaluation must be explicit.

3.6 Exact hadronic-factorization tests

The exact UU and TT conclusions should be presented as physics statements:

f
a
	​

(x
a
	​

)f
b
	​

(x
b
	​

)D
c
	​

(z
h
	​

)x
a
ν
a
	​

	​

x
b
ν
b
	​

	​

z
h
ν
h
	​

	​

H
m
full
	​

	​


is independent of x
a
	​

,x
b
	​

,z
h
	​

 and of the auxiliary hadronic vectors.

3.7 The current NNLO coefficient result

The deterministically certified master-64 coefficient should appear as one controlled scaling result, with no implication that all 342 coefficients are reconstructed.

3.8 A mathematically defined relation between denominator classes and boundary tasks

The paper should not jump from 17 maximal denominator classes to any claim about the number of boundary calculations. The NLO example already demonstrates that these counts differ. 

BOUNDARY_FAMILY_INVENTORY

3.9 A clear statement of the complete partonic and polarization coverage

The manuscript must say exactly which NLO channels are complete. The present text alternates among UU, LL, and TT claims without one authoritative scope statement.

4. Stale, overclaimed, inconsistent, or insufficiently defined statements
4.1 Branding and title

The title and PDF metadata still use “FACET-NLO” and “Collider and Event-shape Theory.” 

main_collinear(3)

 Both should be treated as placeholders. Event shapes should be removed from the immediate scientific scope.

4.2 Abstract inventories are obsolete

The abstract reports:

68 denominator representatives;

4,242 family labels;

157 “support shapes”;

incomplete coverage over 666 pairs. 

main_collinear(3)

These statements are superseded by the corrected 342-master basis and its exact classification into 130 power-aware and 82 positive-denominator classes, with 17 maximal nontrivial classes. They should be removed rather than updated piecemeal.

4.3 The abstract overemphasizes an “agent”

The abstract presents a “constrained master-integral agent” as the central new stage. This makes the paper sound like software documentation. The scientific contribution is the exact chain of cut construction, reduction, rational coefficient reconstruction, analytic master evaluation, and hard-function reconstruction.

4.4 The hard function is not adequately defined

The current manuscript says that conventional momentum-fraction powers are kept outside the hard coefficient, but it does not state the complete normalization or perturbative expansion. 

main_collinear(3)

4.5 The topology-equivalence causal description is internally outdated

The mathematical topology record retains cuts and loop-sector ownership, but the implementation section later claims that original per-propagator i0 and stored η-sign information are retained and retested. 

main_collinear(3)

 That no longer matches the current setup-derived causal classification and should be rewritten consistently.

4.6 Ordinary prescriptions in the NNLO worked family cannot remain implicit

The 83bb derivation says that ordinary causal prescriptions are left implicit. 

main_collinear(3)

 For an exact analytic cut integral, the paper must state whether those denominators:

belong to a definite virtual side;

are fixed-sign phase-space denominators;

or require another causal definition.

4.7 The BMHV ordering is stale

The source says that evanescent powers are retained in a post-IBP manifest and then converted through shifted masters. 

main_collinear(3)

 The current calculation applies the normalized BMHV/Tarasov treatment before Kira reduction and tensor-reduces physical spin contractions in the shifted dimension. The manuscript must follow the actual mathematical order.

4.8 The NLO derivation is duplicated and incomplete

The bubble and top formulas currently appear in the implementation protocol rather than in a connected NLO calculation. 

main_collinear(3)

 The current manuscript does not derive the full angular IBP system, endpoint connection, pullback to w, and distributional hard function in one place.

4.9 The current NNLO inventory section is obsolete

The section beginning “The saved one-flavor double-real process…” contains dated 68/4,242/157 counts and a 2026-07-29 caption. 

main_collinear(3)

 It should be replaced completely, not edited.

4.10 The validation table is obsolete and structurally inappropriate

The table reports “three of twelve complete,” “remaining nine stress families,” and dated pass/fail status. 

main_collinear(3)

 The current exact classification has 17 maximal nontrivial denominator classes, which are not the same object as the old twelve-family stress selection.

4.11 The present milestone paragraph is stale

The source says:

one corrected NNLO pair is evaluated only at a fixed point;

the master agent is not connected to every diagram;

TT still requires full end-to-end BMHV validation;

nine stress families remain. 

main_collinear(3)

This must be replaced by the current, more precise status.

4.12 Internal identifiers drive too much of the exposition

“83bb,” “f228,” and “d099” are useful record identifiers, but the paper should refer primarily to:

the coupled eight-master family;

the doubled-cut repeated-Jordan family;

the factorized five-master family.

4.13 The exact relation C
2
	​

/C is insufficiently introduced

Equation \eqrefeq:c2−over−c appears without a complete definition of C, C
2
	​

, and W in that section. It should either be placed inside the family where those objects are defined or removed.

4.14 Differential equations are incorrectly listed as an alternative

The final “Alternative workflows” section calls differential equations a fallback. In the current calculation they are one of the two principal analytic methods and should be integrated into Sec. 5.

4.15 Software filenames and commands dominate the back half

The source lists notebook names, repository directories, public function calls, hashes, test counts, and shell commands. 

main_collinear(3)

 These should be removed from the main narrative. The repository’s own writing rules call for organizing the paper around observables, kinematics, amplitudes, integral families, singular limits, boundary conditions, and analytic results—not around software architecture. 

AGENTS

5. Recommended order for rewriting

The paper should not be rewritten from page one onward. The safest order is:

Fix the global notation and normalization.
Draft Appendix A and Sec. 2 first. Decide once on z versus z
h
	​

, D versus d, cut normalization, loop measure, hard-function normalization, and polarization labels.

Write the complete NLO worked calculation.
This is the scientific anchor. Include the six masters, angular calculation, differential system, endpoint analysis, distributions, virtual terms, counterterms, and final hard functions.

Write Sec. 3 from the NLO and NNLO formulas actually used.
Amplitude pairs, cuts, causal sectors, partial fractions, complete families, and BMHV reduction should be described only after the final notation is fixed.

Write Sec. 4 on IBP and rational coefficients.
Insert the current Kira closure and Ratracer/FireFly reconstruction, including the exact source-composition identity.

Extract the general analytic-master methodology into Sec. 5.
Generalize only what is actually demonstrated by the NLO top integral and the three solved NNLO families.

Move and edit the 83bb derivation into Sec. 7.3.
Preserve its connected calculation, but replace internal naming and implicit prescriptions.

Write Secs. 7.1, 7.2, 7.4, and 7.5 using only current NNLO facts.

Write Appendices B–D.
Move the fixed-sign proof, full topology-equivalence definition, and BMHV tensor/dimension-shift derivations out of the main flow.

Write Sec. 8 from the exact mathematical acceptance criteria.
Do not transplant the current implementation record.

Write the Introduction, Conclusions, title, and abstract last.
This prevents the scope and numerical claims from becoming stale again.

The most important sequencing principle is that the complete NLO calculation should determine the notation and narrative of the paper, while the NNLO material should demonstrate how the same exact framework extends beyond NLO without implying that the full NNLO hard function is already complete.

## Sources sent to Pro

- Original source reference: `C:\Users\congyue zhang\Desktop\Mathematica\Hard Function\Overleaf\Reverse_Unitarity_Workflow\main_collinear.tex` (not archived with this exchange)
