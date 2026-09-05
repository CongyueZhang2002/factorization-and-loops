# Community Coefficient Simplification Review

## Question

FACET needs exact analytic hard-scattering coefficients, including the full
Epsilon expansion, endpoint powers, plus distributions, physical branches,
causal prescriptions, and BMHV information. Numerical values may only verify
the analytic result.

The attached archive contains the current coefficient-simplification source,
the reduction interface that calls it, the exact card contract, synthetic and
stored-physics test logs, the NLO end-to-end reduction log, and the current
LaTeX/PDF calculation record.

Please assess this against the methods actually used in modern multiloop
amplitude and IBP calculations. In particular:

1. Are we using Mathematica symbolic simplification at a stage where the
   standard approach is finite-field evaluation and rational reconstruction?
2. After branch-sensitive Gamma, logarithm, noninteger-power, BMHV, and cut
   objects are frozen as algebraically independent atoms, are the remaining
   coefficients suitable for FiniteFlow, FireFly, FORM, Singular,
   MultivariateApart, or another established exact tool?
3. Should simplification happen before applying IBP rules, during finite-field
   IBP reconstruction, after collecting each master, or in more than one of
   these stages? Give a concrete data flow and state what algebra is performed
   at each stage.
4. How do large-loop calculations normally prevent expression swell when many
   diagram contributions map to the same master? Discuss denominator
   prediction, sparse interpolation, balanced accumulation, common master
   bases, and multivariate partial fractions where relevant.
5. Which parts of our current Simplification.wl should remain because they
   encode physical information, and which should be replaced by established
   algebraic machinery?
6. Recommend the smallest realistic experiment on our stored NLO UU and NNLO
   target data that can demonstrate a substantial size or time improvement
   while preserving exact reconstruction.

Do not recommend a fixed-kinematics numerical result as the final answer. Name
concrete packages, algorithms, limitations, and primary references. Distinguish
what is established community practice from your proposed FACET adaptation.

## Pro response

Assessment

The current FACET separation between physical normalization and rational algebra is conceptually correct. The misallocation occurs later: for the full NNLO problem, FACET still constructs and simplifies large exact Mathematica expressions at precisely the stage where modern multiscale amplitude calculations commonly use exact finite-field evaluation followed by rational reconstruction.

This does not mean replacing the analytic result by fixed-kinematics numerics. Arithmetic in a finite field is exact, and the final output is a reconstructed rational function over Q. FACET’s required output remains the exact hard function with its ϵ, endpoint, distributional, branch, causal, and BMHV data. 

AGENTS

The recommended division is:

Mathematica/FeynCalc for physical semantics+finite fields for large rational composition+Mathematica for final restoration and certification.
	​

1. Is FACET using Mathematica where finite fields are standard?
NLO: no serious mismatch

For the measured NLO UU and TT calculations, the current Mathematica route is reasonable:

form each complete target coefficient;

apply the exact hadronic map;

certify positive-root identities;

remove the twist-two distribution product and fraction Laurent monomial;

simplify the remaining rational shell;

apply the sparse Kira map;

perform a bounded final cleanup.

The archive’s measurements show that target-level simplification exposes cancellations efficiently and that the resulting NLO calculation is manageable. There is no strong reason to replace a 48-second, exactly reconstructed six-master NLO calculation merely because finite-field methods exist.

Full NNLO: yes, at the post-target composition stage

The mismatch appears in the present Reduction.wl sequence:

normalizeLinearCoefficientParts applies Mathematica simplification to target coefficients;

compileSparseReduction constructs the sparse Kira images;

linearComposeReduction performs exact symbolic target-to-master composition;

normalizeMasterCoefficients then calls an unrestricted

Wolfram Language
parallelNormalizeCoefficients[coefficients, assumptions]

before invoking SimplifyHardCoefficients.

For 44,877 targets and 342 masters, the archive records that whole-master Simplify jobs reached 1800 seconds and about 4 GiB per job without retained results. That is the stage that should be replaced.

For frontier multiscale calculations, it is established practice to evaluate the rational calculation at many exact finite-field points and reconstruct the final rational coefficients, rather than constructing all intermediate analytic expressions. FiniteFlow was designed specifically to compose algebraic stages into dataflow graphs, avoid large intermediate expressions, and reconstruct the final multivariate rational functions. It explicitly includes amplitude-to-master reduction, IBP reduction, differential equations, and Laurent expansion among its applications. 
arXiv
 Kira and FIRE likewise introduced finite-field reconstruction to reduce the memory and algebraic cost of IBP coefficients. 
alphaXiv
+1
 Analytic two-loop five-parton QCD amplitudes have been reconstructed from finite-field evaluations and then compacted using multivariate partial fractions. 
arXiv
+1

The key distinction is:

Do not replace BuildSimplificationContext, branch certification, distribution extraction, BMHV reduction, or cut validation by finite-field evaluation.

Do replace the construction and generic simplification of the enormous rational master coefficients.

2. What exactly is suitable for finite fields?

After physical normalization, write each target coefficient as

c
T
	​

(z,ϵ)=P
phys
	​

α
∑
	​

A
α
	​

r
Tα
	​

(z,ϵ),

where:

P
phys
	​

 is the certified distribution, momentum-fraction, scale, and coupling prefactor;

A
α
	​

 is an exact analytic or tensor basis element;

r
Tα
	​

∈Q(z,ϵ) is a rational function;

z should normally be a dimensionless kinematic coordinate set, such as

x=−
s
t
	​

,y=−
s
u
	​

,

together with any genuinely independent color variables.

The Kira reduction has the form

T=
m
∑
	​

R
Tm
	​

(z,ϵ)M
m
	​

,R
Tm
	​

∈Q(z,ϵ).

The coefficient of A
α
	​

M
m
	​

 is therefore

C
mα
	​

(z,ϵ)=
T
∑
	​

r
Tα
	​

(z,ϵ)R
Tm
	​

(z,ϵ).

This C
mα
	​

 is the object that should be evaluated over finite fields and reconstructed.

Objects that must remain outside the finite-field scalar ring

The following should be retained as exact basis labels or metadata:

Gamma, Beta, Pochhammer, logarithmic, polylogarithmic, and hypergeometric objects;

noninteger powers with a specified physical branch;

endpoint factors such as z
a+bϵ
;

plus distributions and delta distributions;

TT angular structures;

BMHV tensors and evanescent structures;

cut identity and positive-energy orientation;

causal-prescription and physical-chamber data;

master-integral identities.

FACET already treats cut or ordinary type and positive-energy or causal labels as part of the integral data rather than as disposable scalar coefficients. 

BOUNDARY_FAMILY_INVENTORY

These objects must not simply be assigned random finite-field values if relations among them may matter. Instead, first choose a finite exact basis and reconstruct each scalar rational coefficient separately.

For example,

H=r
1
	​

(x,y,ϵ)Γ(1−ϵ)+r
2
	​

(x,y,ϵ)log(1−x)

should be represented as two channels:

{Γ(1−ϵ)↦r
1
	​

,log(1−x)↦r
2
	​

}.

It should not be treated as one black box obtained by assigning arbitrary modular values to Γ(1−ϵ) and log(1−x).

A necessary basis condition

Before splitting into channels, FACET must choose the identities that define the basis. For example:

decide whether Beta[a,b] is retained as a basis object or rewritten in terms of Gamma functions;

canonicalize Gamma recurrences that the calculation is allowed to use;

decide whether a composite Beta * Hypergeometric2F1 is a basis object;

reduce TT tensors to the fixed angular basis;

reduce color factors to an independent color basis;

canonicalize only branch-safe power relations.

After this step, two different basis labels must never later be identified by a functional identity. Otherwise independent finite-field reconstruction of their coefficients could miss a cancellation.

The current coefficientSimplifyWithFrozenBranches is conservative, but its Unique atoms are local to one call. A finite-field backend needs a global deterministic registry:

HoldComplete[A
α
	​

]⟷α,

shared by all targets and masters.

3. Which tools fit which part?
Tool	Appropriate FACET role	Main limitation
FiniteFlow	Preferred long-term engine for the composed target → Kira → master graph. Reconstruct the final C
mα
	​

, not each intermediate expression. It has a Mathematica interface and was designed for multistage finite-field calculations.	Requires constructing an efficient modular evaluator/dataflow graph.
FireFly	Reconstruct each final rational channel from a black-box evaluator. Its later version combines dense and sparse interpolation, removes univariate factors, and supports MPI. 
arXiv
+1
	It needs an efficient evaluator; it does not provide the physical basis decomposition.
Rational Tracer	Probably the smallest proof-of-principle for FACET. Trace the rational additions, multiplications, substitutions, and sparse Kira composition, then evaluate that trace modularly. It supports arbitrary rational-operation sequences and optional series expansion. 
arXiv
+1
	FACET must translate its frozen rational channels into a trace; branch objects cannot be part of the traced scalar algebra.
FORM	Disk-backed term streaming, large sums, color/Dirac algebra, exact collection by basis labels, and efficient sorting. FORM is specifically designed for very large expressions and has parallel implementations. 
arXiv
+1
	FORM by itself is not a general multivariate rational reconstruction engine. Much of FACET’s FeynCalc/BMHV tensor work is already complete before this stage.
Singular	Polynomial factorization, Gröbner calculations, ideal relations, and the algebraic backend of multivariate partial-fraction algorithms.	It does not understand branches, distributions, cuts, or BMHV semantics.
MultivariateApart	Post-reconstruction generalized partial fractions. It avoids spurious denominator factors and can give a unique termwise representation, with Mathematica, FORM, and Singular interfaces. 
arXiv
+1
	It is a representation/compaction tool, not a replacement for finite-field reconstruction. Its output is not guaranteed to be smaller for every FACET coefficient.
pfd-parallel	Large-scale partial fractioning if hundreds of reconstructed master coefficients remain large. It parallelizes both across rational functions and within a function. 
arXiv
	It is worthwhile only after a denominator alphabet and reconstructed rational functions exist.
FIRE6/Kira finite fields	Established precedent for modular IBP reduction. Kira can divide known prefactors before FireFly interpolation, reducing rational reconstruction to polynomial reconstruction in favorable bases. 
alphaXiv
+1
	FACET’s immediate bottleneck is after the already completed Kira reduction; switching reduction programs is unnecessary for the first experiment.
Recommended first choice

Production architecture: FiniteFlow.

Lowest-friction experiment: Rational Tracer or a small FiniteFlow graph.

Reconstruction-only alternative: FireFly.

Final compaction: MultivariateApart, benchmarked rather than assumed.

FORM: useful when term streaming or basis collection, rather than rational reconstruction, is the bottleneck.

4. Where should simplification occur?

More than one stage is appropriate, but each stage has a different purpose.

Stage A — before IBP insertion: physical and local algebra

For each complete GLI target:

perform FeynCalc/BMHV tensor and Dirac reduction;

apply the exact hadronic map;

impose the declared physical chamber;

extract or verify the twist-two distribution product;

extract or verify the universal momentum-fraction Laurent monomial;

certify positive-root transformations;

reduce color and angular structures to a fixed basis;

carry out inexpensive local rational cancellation.

This is close to the current measured target-first strategy. It is valuable because it reduces the cost of every subsequent modular probe. It should remain available as a preconditioner, but the finite-field graph should not depend on an unrestricted Mathematica Simplify succeeding.

Stage B — IBP reduction

Kira should solve or reconstruct its reduction coefficients using finite-field methods where beneficial. This is already established in Kira with FireFly, and denominator prefactors can be inserted when known. 
alphaXiv
+1

For the immediate FACET experiment, the existing exact Kira artifact can be reused. There is no need to rerun the 44,877-target reduction. Its rational coefficients can be read and evaluated modulo primes.

Stage C — compose before reconstructing

For every modular point (z,ϵ)∈F
p
n+1
	​

:

evaluate each rational target channel r
Tα
	​

;

evaluate each nonzero sparse Kira row entry R
Tm
	​

;

accumulate

C
mα
	​

=
T
∑
	​

r
Tα
	​

R
Tm
	​

(modp);

return only the final master-channel vector.

This is the important change. Do not reconstruct all target functions and all Kira images separately merely to multiply them later. Large cancellations often occur at the last stage, and FiniteFlow explicitly motivates reconstructing the final composed result rather than inefficient intermediates. 
arXiv

A hybrid is reasonable when target evaluation is expensive:

reconstruct reusable compressed target channels once;

retain Kira rows as modular evaluators;

reconstruct only the composed master coefficients.

Stage D — rational reconstruction

Reconstruct

C
mα
	​

(x,y,ϵ,…)

using one of:

dense or sparse multivariate reconstruction;

known-denominator reconstruction;

denominator-first reconstruction followed by sparse numerator interpolation;

balanced/Zippel reconstruction for sparse functions.

Recent IBP work combines balanced reconstruction and Zippel interpolation specifically to exploit sparsity in large multivariate rational functions. 
arXiv

Keep ϵ as a formal reconstruction variable if the full rational ϵ-dependence is needed. Series reconstruction should be used only when the required Laurent depth and pole bounds are already known. Endpoint powers such as z
a+bϵ
 remain basis labels, not finite-field functions.

Stage E — after reconstruction

For each reconstructed rational function:

cancel polynomial gcds;

restore known scale factors;

optionally apply MultivariateApart;

restore the analytic basis objects;

reconstruct the twist-two and fraction prefactors;

verify forbidden variables are absent;

verify the physical branch registry is unchanged;

verify exact scale and coordinate reconstruction;

attach cut, causal, endpoint, and BMHV metadata.

A final bounded Mathematica Simplify is appropriate here because the expression is already compact. It should not be the engine that discovers the result.

5. How large calculations prevent expression swell
Reconstruct the final object, not every intermediate

The most important practice is to combine diagrams, projections, and reduction coefficients at modular points and reconstruct only the final rational coefficients. FiniteFlow’s dataflow-graph model was introduced precisely because reconstructing intermediate linear-system solutions before later substitutions can be highly inefficient. 
arXiv

Predict denominators

If

C
mα
	​

(z)=
∏
j
	​

q
j
	​

(z)
e
mj
	​

N
mα
	​

(z)
	​

,

and the q
j
	​

 and exponents are known, only N
mα
	​

 must be interpolated. Kira documents that known coefficient denominators or prefactors can be divided out before FireFly interpolation, simplifying rational interpolation to polynomial interpolation; the useful factorization can depend on the chosen master basis. 
alphaXiv
+1

FACET already has unusually good information for this:

exact denominators from Kira rows;

exact denominators from physicalized targets;

a dimensionless x,y representation;

the report’s observed small denominator-factor alphabet;

exact homogeneous scale powers.

The factor dictionary was not a useful storage format in the measured test, but it may be highly valuable as a reconstruction ansatz.

Do not predict denominators solely from physical poles. Spurious poles can occur in individual master coefficients and cancel only after a basis change or a later sum. The candidate alphabet should initially include all certified factors observed in Kira rows and target coefficients.

Use a common master basis

Every diagram must be mapped into one certified common master basis before reconstruction. FACET already does much of this through topology equivalence and sparse Kira rules.

The chosen master basis affects denominator complexity. Kira’s prefactor documentation explicitly notes that denominator factorization may work only in a specific preferred basis. 
alphaXiv
 A future optimization can compare candidate master bases by modular probe degree and denominator complexity, but that is separate from the immediate coefficient-backend change.

Exploit sparsity and overlap

Modern reconstructions use:

sparse monomial interpolation;

dense/sparse hybrid strategies;

univariate factor scans;

common coefficient sets across helicity or partonic channels;

multiple modular probes per run.

FireFly 2.0 includes a hybrid dense/sparse algorithm and univariate-factor removal. 
arXiv
 Recent amplitude work also exploits overlaps among rational coefficients in different processes to reduce the reconstruction burden. 
INSPIRE
+1

Balanced accumulation remains useful, but at modular level

FACET’s balanced disk-backed accumulation is the correct fallback for exact symbolic expressions. In a finite field, however, each intermediate coefficient is a machine-sized field element, so accumulation order no longer causes expression swell. Balanced scheduling is then mostly about load balance, I/O, and common-subexpression reuse rather than algebraic size.

Partial fractions after reconstruction

Analytic five-parton amplitude calculations commonly reconstruct rational coefficients first and apply multivariate partial fractions afterward to obtain compact results. 
arXiv
+1
 MultivariateApart is particularly relevant because its decomposition avoids spurious factors and can be applied consistently term by term. 
arXiv

6. What should remain in Simplification.wl?
Keep as the physical certificate layer

The following logic should remain in Mathematica/FeynCalc:

BuildSimplificationContext;

normalizeCoefficientKinematics;

physical-chamber and coordinate-map validation;

mass-dimension and scale-homogeneity checks;

coefficientNormalizeDistributionGroups;

declared or derived Laurent-valuation verification;

validateCoefficientBranchGrammar;

coefficientPositiveRootLift;

exact fraction-root proportionality certification;

forbidden-variable checks;

coefficientDimensionlessNormalize;

exact branch registry and reconstruction records;

all cut, causal, and BMHV metadata handling.

These functions encode physics, not merely computer algebra.

The positive-root machinery is particularly valuable because it converts a branch-qualified algebra into a rational ring before any modular work. No general finite-field package knows that x
a
	​

,x
b
	​

,z
h
	​

>0 or which square-root identities are physically permitted.

Retain as bounded small-expression tools

Keep, but do not use as the full NNLO engine:

coefficientSimplifyWithFrozenBranches;

coefficientBalancedExactSum;

coefficientCanonicalRational;

exact local Cancel/Together;

structural common-factor extraction.

They remain useful for:

NLO;

target preconditioning;

small reconstructed functions;

exact final restoration;

independent checks.

Replace in the full NNLO path

The following should no longer be responsible for producing all 342 NNLO master coefficients:

normalizeLinearCoefficientParts as a mandatory generic target Simplify;

exact symbolic linearComposeReduction for the entire reduction;

the unrestricted first call to parallelNormalizeCoefficients in normalizeMasterCoefficients;

coefficientCommonFractionDenominator across large master columns;

repeated giant Cancel[Together] zero tests over the full coefficient field;

global exact denominator multiplication in coefficientAssembleRootColumn.

A new backend should conceptually implement

PhysicalTargetChannels
    -> ModularTargetEvaluator
    -> SparseKiraEvaluator
    -> FinalMasterChannelEvaluator
    -> RationalReconstruction
    -> RestoreAndCertify

The old Mathematica backend should remain available for NLO and as an exact comparison implementation.

7. Exactness and reconstruction certificates

Finite-field probes are exact modular arithmetic, but the usual stopping criterion—agreement at additional unused primes and points—is a very strong probabilistic certificate, not by itself a formal deterministic proof. FiniteFlow describes reconstructing over several primes and checking the result at finite-field points not used in reconstruction. 
arXiv

FACET can use two certificate levels.

Established community certificate

Persist:

all primes and points used in reconstruction;

all rejected singular points;

reconstructed numerator and denominator degrees;

unused-prime verification points;

agreement of the reconstructed result at those points;

source, card, basis-registry, and Kira fingerprints.

This is standard and normally considered sufficient in large amplitude calculations.

Stronger FACET certificate

Where the denominator alphabet and degree bounds are known:

predict a common denominator D
mα
	​

;

reconstruct the polynomial numerator N
mα
	​

;

establish explicit multidegree bounds;

evaluate

D
mα
	​

C
mα
source
	​

−N
mα
	​


on an interpolation grid sufficient for those degree bounds;

reconstruct every grid coefficient over Q;

require the resulting polynomial to be identically zero.

For the full NLO UU test, additionally require the ordinary Mathematica identity

Cancel[C
mα
FF
	​

−C
mα
Mathematica
	​

]=0

for all six masters.

If no denominator/degree/height bound is available and a deterministic proof is mandatory, an exact symbolic replay of the compact reconstructed result against the source DAG remains necessary. That may reduce, but does not erase, the performance advantage. This distinction should be explicit in FACET’s artifact status.

8. Smallest realistic experiment

The archive contains the source, test logs, and measured report, but not the raw 44,877-target store, so I did not execute this benchmark here. The following is the smallest experiment that tests the relevant algebra rather than an artificially isolated function.

Experiment 1 — full stored NLO UU

Use the complete stored NLO UU reduction as the exact reference.

Run the existing physical frontend through:

hadronic substitution;

distribution and fraction extraction;

positive-root certification;

dimensionless normalization.

Choose deterministic basis channels for:

color;

any remaining angular or analytic objects.

Construct a modular evaluator for

C
mα
	​

=
T
∑
	​

r
Tα
	​

R
Tm
	​


for all six masters.

Reconstruct in (x,y,ϵ); either hold color as basis labels or use one independent color variable.

Restore all physical factors.

Require exact Mathematica equality to the existing six coefficients.

Record wall time, peak RSS, number of probes, reconstructed degrees, and output size.

For the first implementation, Rational Tracer is likely the least invasive because the calculation after freezing is already a sequence of rational operations. FiniteFlow is the better long-term choice if the pilot confirms the scaling.

Experiment 2 — one representative NNLO master fibre

Do not begin with all 342 masters. Select:

one medium-fanout master column;

a deterministic 1/16 or 1/32 subset of the largest master column;

contributions spanning the largest target sizes and Kira fanouts.

For that fibre:

use the existing certified target-level physical normalization;

evaluate the target channels and Kira row entries modularly;

sum the master channel at each point;

first reconstruct with no denominator ansatz;

repeat using the observed denominator-factor dictionary;

compare with the existing exact fraction-list representation.

The test should be rejected unless:

every reconstructed channel is an exact rational function;

the distribution product and Laurent valuation equal the card declarations;

no momentum fraction, temporary root, hadronic vector, loop momentum, D, GLI, or BMHV remainder survives unexpectedly;

the analytic basis registry is identical;

all branch and cut metadata are unchanged;

exact equality to the existing subset is established;

unused-prime checks succeed.

A practical performance criterion should be stated before running. A reasonable migration threshold is either:

peak RSS reduction≥4

or

wall-time reduction≥2

on the NNLO fibre, with no increase in the final exact output size by more than a small controlled amount. Failure to meet this threshold would mean retaining the existing NLO path and reconsidering the modular evaluator before a full NNLO run.

Recommended decision

Do not replace Simplification.wl. It is the physical and branch-certification frontend.

Remove unrestricted whole-master Mathematica simplification from the NNLO production path.

Keep measured target-level compression as an optional modular-probe preconditioner.

Compose target coefficients with Kira rows over finite fields and reconstruct final master coefficients by analytic basis channel.

Pilot Rational Tracer or FiniteFlow on full NLO UU, then on one NNLO master fibre.

Use denominator prediction aggressively; the observed small x,y factor alphabet is more valuable as a reconstruction ansatz than as a storage dictionary.

Apply MultivariateApart only after reconstruction and retain it only when the measured representation becomes smaller or structurally more useful.

Restore and certify all physical factors, branches, cuts, endpoint objects, distributions, and BMHV structures in Mathematica.

This is a direct adaptation of established finite-field amplitude technology to FACET. The established part is exact modular evaluation and reconstruction of rational coefficients. The FACET-specific part is the preceding physical normalization and the subsequent restoration of branch-, cut-, distribution-, endpoint-, and BMHV-sensitive objects.

## Sources sent to Pro

- [community_coefficient_simplification_review.zip](Sources/02_community_coefficient_simplification_review/community_coefficient_simplification_review.zip)
