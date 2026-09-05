# Dmodule Package Review

## Question

The attached MasterAnalyticRoutePrototype.wl is the updated exact analytic-route prototype. Since your previous review, it now contains DeriveParametricPeriodAnnihilator, a Wolfram wrapper around Singular's annihilatorMultiFs and integralIdeal routines.

The wrapper has been tested exactly on four calculations:

1. Integrating x^s1 (x+b)^s2 over x gives [b d/db - s1 - s2 - 1] I = 0.
2. Integrating (x^2+b)^(-1-eps) over x gives [2 b d/db + 2 eps + 1] I = 0.
3. Integrating x^a (1-x)^b (1-z x)^c over x gives the Gauss equation
   z(1-z) I'' + [a+b+2-(a-c+2)z] I' + c(a+1) I = 0.
4. Integrating r^(-eps) z^(-eps) (s-r-z)^(-eps) over r,z gives
   [s d/ds + 3 eps - 2] I = 0.

Each identity was produced from the polynomial factors and symbolic powers, with no differential equation supplied as input. The wrapper intentionally records that the physical cut cycle, endpoint terms and boundary constants remain undetermined.

Please review this new function and answer the following focused questions.

1. Is Singular D-module direct image the right community-standard exact engine for deriving Picard-Fuchs systems from FACET's low-dimensional cut boundary densities? Identify any mathematical defect in applying annihilatorMultiFs followed by integralIdeal to open simplices and relative cycles. Distinguish an annihilator of the integrand, a homogeneous equation for a closed period, and an inhomogeneous equation caused by endpoint terms.

2. Survey public, currently obtainable exact packages beyond the tools already discussed that can automate the next stages: relative de Rham or relative D-module treatment of open integration domains; minimal Picard-Fuchs operators; factorization and Liouvillian/hypergeometric recognition; connection matrices between singular points; exact special-function or iterated-integral solutions. Consider computer-algebra systems outside high-energy physics as well. Do not recommend a fixed-point numerical solver as the analytic calculation.

3. For each serious candidate, state the exact input and output, whether it is publicly obtainable now, and one FACET test that would decide whether it is useful. In particular assess HolonomicFunctions, Macaulay2 Dmodules, OSCAR/Singular.jl, ore_algebra, Maple packages if they require a commercial license, Magma Period/PicardFuchs if they require Magma, and any better alternative we have missed.

4. Which stages are deterministic enough to become reusable functions now? Propose precise interfaces for: deriving the integration ideal; checking whether endpoint terms vanish; classifying the scalar operator; generating local Frobenius modes; matching a physical boundary record to those modes; and verifying the reconstructed analytic function against the original differential system.

5. Identify any implementation error, unsafe parsing, false exactness claim, or scaling problem in DeriveParametricPeriodAnnihilator itself. Prefer replacing local algebra with an established package when that package gives an exact certificate.

The required FACET output remains an exact analytic cut master with epsilon and physical-branch information. Numerical values are only independent checks.

## Pro response

The two attached Wolfram Language files are byte-identical, so the review below applies to both.

Main conclusion

annihilatorMultiFs followed by integralIdeal is an appropriate community-standard exact engine for the algebraic D-module part of this problem:

product of polynomial powers⟶annihilating Weyl ideal⟶direct-image/integration ideal.

It is not, by itself, a complete engine for the FACET physical period. The missing layer is

algebraic direct image+relative physical cycle+boundary-source calculation+branch and normalization data.
	​


Your wrapper already records that the physical cycle, endpoint terms, and boundary constants are undetermined. That is scientifically correct. The principal correction is terminological: the returned object should be called an exact algebraic direct-image ideal, not yet a physical-period annihilator.

The four completed tests are meaningful exact tests of the algebraic stage. They do not test:

an open-domain boundary source;

a positive-energy cut cycle;

causal branch selection;

relative homology;

minimality of the returned operator;

exceptional specializations of the exponent parameters.

1. What Singular direct image establishes

Let

ω(u,z)=
j=1
∏
m
	​

f
j
	​

(u,z)
α
j
	​

d
r
u,

where u are integration variables and z are retained kinematic variables.

Integrand annihilator

annihilatorMultiFs constructs operators in a Weyl algebra that annihilate the multivalued integrand:

Ann(ω)={P(u,z,∂
u
	​

,∂
z
	​

)∣Pω=0}.

After substituting s
j
	​

=α
j
	​

, every specialized operator obtained from the generic s
j
	​

-ideal remains an exact annihilator, away from poles introduced by the specialization.

However, specialization can enlarge the annihilator at exceptional exponent values. Therefore the specialized ideal is certainly a subideal of the full specialized annihilator, but need not equal it:

Ann(
j
∏
	​

f
j
s
j
	​

	​

)
	​

s
j
	​

=α
j
	​

	​

⊆Ann(
j
∏
	​

f
j
α
j
	​

	​

).

This means the current route is exact but can be incomplete at exceptional ϵ or integer parameter values. It cannot produce a false annihilating operator from a valid generic operator, but it can miss additional operators or return a nonminimal system.

Integration ideal

Schematically, the integration ideal eliminates the integration derivatives:

J=(Ann(ω)+
i=1
∑
r
	​

∂
u
i
	​

	​

D)∩D
z
	​

.

For every P∈J, there exist certificate operators Q
i
	​

 such that

Pω=
i=1
∑
r
	​

∂
u
i
	​

	​

(Q
i
	​

ω).

For a physical integration chain Γ,

I
Γ
	​

(z)=∫
Γ
	​

ω,

Stokes' theorem gives

PI
Γ
	​

=∫
∂Γ
	​

i=1
∑
r
	​

(−1)
i−1
Q
i
	​

ωdu
1
	​

⋯
du
i
	​

	​

⋯du
r
	​

.
	​


This distinction produces three different objects.

Closed or twisted-closed period

If ∂Γ=0 in the relevant twisted homology, then

PI
Γ
	​

=0.
Open chain with vanishing endpoint terms

If every pulled-back certificate vanishes or is integrable with zero boundary value, again

PI
Γ
	​

=0.
Open chain with nonzero endpoint terms

In general,

PI
Γ
	​

=S
∂Γ
	​

(z),

where S
∂Γ
	​

 is a lower-dimensional boundary period. The physical integral obeys an inhomogeneous equation, or a larger homogeneous system obtained by adjoining the boundary periods.

Algorithms for definite integrals over domains given by polynomial inequalities explicitly use holonomic distributions such as Heaviside functions to incorporate these boundaries. Oaku’s construction and the related inhomogeneous-equation algorithm are the appropriate mathematical framework for this extension. 
arXiv
+1

Consequence for open simplices

There is no defect in applying integralIdeal to the algebraic density on an open simplex as long as the output is interpreted as an algebraic direct-image/telescoper ideal.

It becomes incorrect only if one asserts, without an additional boundary certificate, that every returned operator annihilates the selected physical open-simplex integral homogeneously.

Your four tests do not expose this distinction because their final homogeneous equations are consistent with the chosen periods. Add the benchmark

I(z)=∫
0
1
	​

1−zx
dx
	​

=−
z
log(1−z)
	​

.

It obeys the first-order inhomogeneous equation

(1−z)[zI
′
(z)+I(z)]=1

and the derived homogeneous second-order equation

z(1−z)I
′′
(z)+(2−3z)I
′
(z)−I(z)=0.

A correct relative-cycle layer should recover the first equation and its exact endpoint source. An algebraic direct-image calculation may instead return only the second homogeneous annihilator. Both are true, but they contain different physical information.

Minimal Picard–Fuchs operator

The standard basis

singular
ideal periodAnnihilator = std(intIdeal);

is not generally:

a principal ideal;

a minimal-order scalar operator;

the minimal Picard–Fuchs operator of the selected period;

a physical branch selection.

For one surviving variable, the next stage must uncouple or eliminate to a scalar Ore operator and then minimize, factor, or desingularize it. For several variables, the result remains a Pfaffian or holonomic PDE ideal.

2. Source-level audit of DeriveParametricPeriodAnnihilator
P0: exactness grammar is currently too permissive
Lines 218–264: NumericQ is not an exact coefficient-field test

When parameters === {}, the code accepts:

Wolfram Language
NumericQ[Denominator[fraction]]

and

Wolfram Language
NumericQ[exponent]

This accepts objects such as

Wolfram Language
Pi
I
Sqrt[2]
Root[...]

and potentially other exact or numeric System expressions that are not represented in the declared Singular coefficient field.

For example,

Wolfram Language
Pi x
x/Pi
(x^2 + b)^Sqrt[2]

can pass portions of the present validation because:

System symbols are excluded from expressionSymbols;

PolynomialQ[Pi x,{x}] is True;

NumericQ[Pi] and NumericQ[Sqrt[2]] are True.

But the generated Singular string contains undeclared tokens or an algebraic coefficient extension that was never constructed.

Required correction

Replace NumericQ by an explicit exact rational-function grammar. Unless an algebraic extension is declared, admit only

Q(parameters).

A safe validator should require

Wolfram Language
Together[expr]

to have numerator and denominator polynomial in the declared parameters with rational coefficients only.

The same validation must be applied to every coefficient of every polynomial factor, not merely to the overall denominator of the factor.

Recommended states
"CoefficientField" -> RationalFunctionField[parameters]
"AlgebraicExtensions" -> {}

If algebraic coefficients are later supported, they should be represented by an explicit minimal polynomial and a declared generator, not accepted through NumericQ.

P0: InputForm is not a safe Singular serializer
Lines 98–102
Wolfram Language
singularExpressionString[expression_] := ToString[..., InputForm]

is too broad. It serializes Mathematica syntax, not a restricted Singular expression grammar.

The current prevalidation prevents many problems, but not all unsupported heads or constants. This is principally a semantic serialization risk, not a need for ToExpression.

Required correction

Implement a recursive serializer that accepts only:

Integer
Rational
declared Symbol
Plus
Times
Power[base, Integer]

and, after denominator clearing, perhaps rational functions in declared coefficient parameters.

Everything else should be rejected. The serializer should never emit a token that was not already registered in the ring record.

P0: reserved Singular names are not rejected
Lines 79–96 and 208–216

The ASCII regex is useful, but symbols can still collide with Singular or library names such as

ring
ideal
int
size
s
t
annFs
intIdeal
facetIndex

or generated derivative names.

Maintain a reserved-name registry containing:

Singular language keywords;

names introduced in the generated scripts;

library-exported symbols relied upon by the wrapper;

generated derivative names.

The Singular D-module libraries themselves warn about reserved names such as s and t in some annihilator routines. 
Debian Sources

P0: the result state overclaims the physical meaning
Lines 391–410

Current state:

Wolfram Language
"State" -> "ExactIntegrationIdealDerived"

and field:

Wolfram Language
"PeriodAnnihilatorStrings" -> periodOperators

These names are too strong.

Use:

"State" -> "ExactAlgebraicDirectImageIdealDerived"
"DirectImageOperatorStrings" -> ...
"PhysicalPeriodEquationState" -> "Undetermined"

The interpretation string is already mostly correct. It should say that the operators are candidate homogeneous operators for a selected physical period until relative-boundary terms have been checked.

P0: no telescoping certificates are retained

The integration ideal alone does not tell FACET whether a physical endpoint term vanishes.

To check the open-simplex period, the production record needs, for each operator P,

Pω=
i
∑
	​

∂
u
i
	​

	​

(Q
i
	​

ω).

The Q
i
	​

 are essential. Without them, there is no direct route to the exact boundary source.

If integralIdeal does not expose these certificates in a convenient stable form, use a creative-telescoping engine that does, or compute an augmented relative system through an Oaku/Heaviside formulation.

This is the largest mathematical gap between the current prototype and a physical-period classifier.

P0: generic exponent specialization needs an exceptional-locus record
Lines 312–317

Raw textual substitution

Wolfram Language
s(i) -> exponent

produces exact specialized annihilators generically, but:

denominators in ϵ may be introduced;

the Gröbner basis can change at exceptional values;

the holonomic rank can jump;

the full annihilator may enlarge.

Persist the product of all introduced coefficient denominators,

E
spec
	​

(ϵ,p),

and state that the ideal is certified on

E
spec
	​


=0.

If a later calculation needs ϵ=0 or an exceptional parameter value, specialize only after Laurent analysis or recompute the specialized annihilator directly.

P1: the wrapper never verifies holonomicity or rank

After direct image, it should determine:

dim
D
	​

(D/J),rank
hol
	​

(J),Σ(J),

when computationally feasible.

At minimum:

check that the ideal is nonzero;

distinguish a valid zero ideal from parse failure;

check that no eliminated variable or derivative remains;

check that every output coefficient belongs to the declared field.

Macaulay2’s Dmodules package exposes isHolonomic, holonomicRank, DsingularLocus, and derived integration modules, making it a useful independent exact check. 
Macaulay2
+2
Macaulay2
+2

P1: empty output is conflated with parse failure
Lines 303–310 and 378–389

A direct-image ideal can in principle have no printed nonzero generator under a particular representation. The current code interprets an empty marker list only as parsing failure.

Print explicit metadata:

singular
print("__FACET_COUNT_BEGIN__");
print(size(periodAnnihilator));
print("__FACET_COUNT_END__");

Then distinguish:

GeneratorCountZero
MarkerParseFailure
NonzeroGeneratorsParsed

Do the same for the integrand annihilator.

P1: raw string parsing is version-dependent and is not round-tripped
Lines 275–363

The wrapper relies on:

global annFs;

global intIdeal;

exact printed syntax;

StringReplace on printed operator strings.

This has worked in the tested Singular installation, but it is tied to library conventions.

Persist:

Singular version;

dmodideal.lib version;

dmodapp.lib version;

generated script hash;

ring definitions;

generator counts.

Each imported operator should be parsed back into a fresh Singular ring and checked for membership in the original output ideal. This is the exact round-trip certificate that the string transport did not alter the operator.

P1: constant polynomial factors should be removed

A nonzero factor independent of both integration and kinematic variables contributes only a parameter-dependent normalization:

c(ϵ)
α
.

It does not alter the differential ideal in the retained kinematic variables. Keeping such factors increases the number of symbolic s
i
	​

 parameters and the size of annihilatorMultiFs.

Separate them into

"ExternalNormalization"

before calling Singular.

P1: the input has no domain or branch record

The wrapper currently takes only factors, exponents, and variable lists. For FACET, a physical-period record also needs:

Wolfram Language
"Domain" -> ...
"Orientation" -> ...
"BoundaryFaces" -> ...
"PhysicalChamber" -> ...
"FactorBranches" -> ...
"CutRecord" -> ...
"ConvergenceAssumptions" -> ...

These should not be passed to Singular’s algebraic direct-image routine, but they must accompany its output and be consumed by the boundary-source stage.

The same differential ideal can describe several distinct physical branches.

P2: timeout and process cleanup
Lines 110–149

There are three issues.

The time bound is applied separately to the two Singular runs, so total time can approach 2T, not T.

TimeConstrained[RunProcess[...]] does not give the wrapper explicit control of the child-process lifecycle. A robust production implementation should use StartProcess, monitor it, and call KillProcess or an operating-system process-group timeout.

With "KeepTemporaryFiles" -> True, both runs retain temporary directories, but the successful final result does not include the two process records or their paths. The directories are leaked and cannot be found from the returned association.

Return both process manifests on success:

"IntegrandProcess"
"DirectImageProcess"

and either provide a cleanup function or retain no temporary files.

P2: stdout capture will become a memory bottleneck

RunProcess captures all output as one string. A large D-module Gröbner basis can be hundreds of megabytes.

For production:

write ideal generators to files;

write a small manifest to stdout;

stream or import generators one at a time;

hash each generator;

avoid embedding all output in one process association.

D-module Gröbner computation can grow very rapidly, so this route should remain targeted at low-dimensional residual boundary densities, not automatically run on every full two-loop family.

3. Status of the four current tests

The four results establish:

exact specialization of f
i
s
i
	​

	​

;

correct Weyl-algebra construction;

correct integration-variable elimination;

nontrivial recovery of first- and second-order equations;

correct scaling equations for a two-dimensional simplex density.

They do not establish:

completeness of the specialized annihilator;

minimality of the operator;

physical-cycle selection;

endpoint-source handling;

branch selection;

exact connection constants.

Add these tests before promoting the wrapper:

Endpoint-source test
I(z)=∫
0
1
	​

1−zx
dx
	​

.

Require both the certificate for

(1−z)(zI
′
+I)=1

and the homogeneous second-order consequence.

Branch test

Use

I
σ
	​

(b,ϵ)=∫
0
∞
	​

(x
2
+b+i0σ)
−1−ϵ
dx

in chambers b>0 and b<0. The differential operator is shared, while the physical branches differ. The wrapper must not claim that the operator identifies the branch.

Exceptional-exponent test

Choose an integrand whose generic holonomic rank drops or whose annihilator enlarges at an integer exponent. Verify that the generic specialized ideal is accepted as valid but marked potentially incomplete on the exceptional divisor.

Serializer rejection tests

Require rejection of:

Wolfram Language
Pi x
I x
Sqrt[2] x
Sin[x]
ConditionalExpression[...]
1.0 x

unless the corresponding coefficient extension is explicitly declared.

4. Package survey and recommended roles
4.1 Singular: retain as the primary algebraic direct-image engine

Exact input

polynomial factors f
i
	​

(u,z);

symbolic powers s
i
	​

, later specialized;

Weyl algebra and integration-variable mask.

Exact output

an annihilating left ideal for ∏
i
	​

f
i
s
i
	​

	​

;

an algebraic integration/direct-image ideal after elimination.

Physical cut or branch

Not selected. Must be supplied separately.

FACET benchmark

Retain the current four tests, then add the endpoint-source and branch tests above.

Singular’s D-module libraries are established exact implementations of annihilator and algebraic D-module algorithms. 
Debian Sources
+1

Recommendation

Keep it. Rename and strengthen the wrapper rather than replacing the engine.

4.2 HolonomicFunctions: highest-priority addition

Availability

Publicly downloadable Mathematica package from RISC.

Exact input

a holonomic integrand or annihilating Ore ideal;

integration or summation variable;

retained parameters.

Exact output

annihilating ideals;

closure constructions;

creative-telescoping operators;

coupled holonomic systems;

where exposed by the selected routine, telescoping certificates.

It is specifically designed for multivariate holonomic functions, closure properties, summation, and integration. 
RISC - Johannes Kepler University
+1

Physical cut or branch

Not automatic. Endpoint substitution and physical-cycle interpretation remain FACET responsibilities.

Decisive FACET benchmark

Use

I(z)=∫
0
1
	​

1−zx
dx
	​

.

Require the package to return a telescoper and certificate from which FACET derives the exact source 1. Then run the NLO Euler top integral and require the angular-IBP inhomogeneous equation, including its bubble term.

Recommendation

This is the best immediate candidate for the missing certificate layer. Compatibility with the current Wolfram version must be measured because the public package is longstanding.

4.3 Risa/Asir with Oaku-style interval and Heaviside methods

Availability

Risa/Asir is publicly obtainable. Its documentation includes contributed routines for integration ideals and interval/domain treatments, although the interface and documentation are older and should be treated as research software. 
Asir

Exact input

a holonomic ideal;

polynomial interval or inequality data;

Heaviside/distribution representation of the domain.

Exact output

a holonomic system for the definite integral;

in suitable routines, homogeneous or inhomogeneous equations that include boundary information.

The underlying algorithms are designed precisely for integrals over domains defined by polynomial inequalities and for inhomogeneous equations of definite integrals. 
arXiv
+1

Physical cut or branch

The semialgebraic domain can be encoded. The complex branch of polynomial powers and the positive-energy cut interpretation still need a FACET certificate.

Decisive FACET benchmark

Represent [0,1] by Heaviside factors and derive the inhomogeneous equation for

∫
0
1
	​

1−zx
dx
	​

.

Then test a two-dimensional simplex with all oriented faces and compare its face-source equations with a hand Stokes calculation.

Recommendation

Pilot this as the most direct existing relative-domain engine. Do not make it a production dependency until the interface, current build, and exact output format have been validated.

4.4 Macaulay2 Dmodules: strongest independent exact cross-check

Availability

Public and included in current Macaulay2 distributions. The documented Dmodules version is 1.4.1.1.

Exact input

a Weyl algebra;

an annihilating ideal or D-module;

a weight vector selecting integrated coordinates.

Exact output

derived integration modules and integration ideals;

holonomic rank;

characteristic ideal;

singular locus;

localization, restriction, and de Rham computations. 
Macaulay2
+2
Macaulay2
+2

Physical cut or branch

No. It computes algebraic D-module functors, not the selected relative physical cycle.

Decisive FACET benchmark

Repeat all four current Singular calculations and compare:

Weyl-ideal inclusion in both directions;

holonomic rank;

singular locus;

derived integration-module degree.

Then run the endpoint-source test and verify that ordinary Dintegration alone does not silently get interpreted as physical relative integration.

Recommendation

Adopt as an independent algebraic verifier and source of rank/singular-locus data. It need not replace Singular.

4.5 ore_algebra: production backend for scalar operators

Availability

Public GPL package, installable through Sage or through its PassageMath-based Python environment.

Exact input

A univariate differential or recurrence operator over a rational or declared algebraic differential field.

Exact output

Ore-polynomial arithmetic;

gcrd and lclm;

closure operations;

creative telescoping;

desingularization;

polynomial, rational, and generalized-series solutions. 
SageMath
+2
GitHub
+2

Physical cut or branch

No. It analyzes the operator and its local formal solutions. FACET must select the physical combination.

Decisive FACET benchmark

Export:

the class-115 second-order operator;

the NLO Gauss operator.

Require:

exact round-trip equality;

primitive and monic normalization;

singular loci;

indicial polynomials;

generalized Frobenius series;

exact substitution residuals.

Recommendation

Adopt as the preferred backend after a scalar operator has been obtained. It is more appropriate than extending local Wolfram code for factorization, desingularization, and generalized series.

Its rigorous numerical analytic continuation is useful only as an independent comparison, not as the FACET analytic result.

4.6 Maple DEtools and gfun: useful commercial reference

Availability

Requires access to Maple.

Exact input

A scalar homogeneous linear differential operator or ODE.

Exact output

Maple’s DEtools includes:

operator factorization;

desingularization;

formal local solutions;

hypergeometric solutions;

Kovacic/Liouvillian analysis;

Meijer-G and related recognized solutions. 
Maplesoft
+2
Maplesoft
+2

Physical cut or branch

No. The returned solution basis must be matched to the physical cycle.

Decisive FACET benchmark

Run the class-115 operator and require exact recovery of its second-order factor or recognized hypergeometric form. Then test the NLO Gauss equation and compare local exponent conventions with FACET.

Recommendation

Use as a high-quality optional reference if a license is available. Do not make it a required open dependency.

Exact global connection matrices should be expected only for recognized special-function classes, not for a generic holonomic operator.

4.7 OSCAR/Singular.jl: useful interface, not a new D-module engine

Availability

Open source and current. Singular.jl exposes Weyl and other noncommutative algebras; OSCAR has an expanding PBW-algebra layer. 
Oscar System
+2
GitHub
+2

Exact input/output

Typed Julia objects for Weyl algebras, ideals, modules, and Gröbner bases.

Physical cut or branch

No.

Current limitation

I did not find a documented high-level Julia wrapper for the complete annihilatorMultiFs plus D-module direct-image workflow in the current OSCAR/Singular.jl documentation. The added value would currently be a safer typed interface to the same Singular backend, not a more complete mathematical method.

Decisive FACET benchmark

Attempt a structural round trip of the current Singular annihilator and integration ideals through Singular.jl, including noncommutative ring metadata. If the D-module library calls still require raw interpreter strings, there is little immediate benefit.

Recommendation

Low priority. Improve the existing serializer first or use Sage’s Singular interpreter interface, which already exposes arbitrary Singular commands. 
SageMath

4.8 Magma and external Fanosearch code

Availability

Requires access to Magma. The current handbook is V2.29. 
Magma
+1

Core capabilities

Magma has exact differential fields, differential operators, Newton polygons, and operators for algebraic functions. It also has numerical elliptic-period routines. 
Magma
+2
Magma
+2

I did not find a documented general-purpose PicardFuchs intrinsic in the core V2.29 handbook. The documented Periods(E) functions are numerical elliptic-curve period computations, not a generic exact Picard–Fuchs direct-image engine.

External Fanosearch Magma code supplies PicardFuchsOperator for Laurent polynomials or period sequences. That library is publicly available, but it still requires Magma. 
DOI
+1

Physical cut or branch

No.

Decisive FACET benchmark

Only if Magma access is already available: feed a known exact period sequence from a FACET boundary density and require the same operator as Singular plus an exact annihilation test. This tests sequence-to-operator reconstruction, not direct integration of the cut density.

Recommendation

Not a core FACET dependency. The public open-source alternatives cover the immediately required tasks more directly.

4.9 Lairez periods / generalized Griffiths–Dwork

Availability

Lairez’s original implementation is publicly available under the CeCILL license. 
DOI
+1

Exact input

A rational projective period, typically represented by a rational differential form associated with a hypersurface.

Exact output

A Picard–Fuchs differential operator obtained through generalized Griffiths–Dwork reduction.

Physical cut or branch

No. The method treats a closed projective period/local system. A FACET open simplex or positive-energy cut must first be converted to a valid projective/relative-period representation, and the physical cycle still needs to be selected.

Decisive FACET benchmark

Choose a residual boundary period that can be projectivized without losing its relative-cycle data. Compare the resulting operator with the Singular direct-image operator and verify the operator directly on the original density.

Recommendation

Valuable escalation tool for rational projective periods. It is not a replacement for the open-simplex relative-cycle layer.

5. Exact connection matrices: present limitation

No surveyed public package supplies a general exact map

arbitrary holonomic operator⟶exact transcendental connection matrix between arbitrary singular points

for the physical branch.

What can be automated exactly is:

local Frobenius/Levelt bases;

operator factorization and desingularization;

recognized Gauss, generalized hypergeometric, Liouvillian, or algebraic solutions;

GPL/Chen transport for verified rational dlog systems;

some elliptic/modular systems after a period basis is supplied.

For a general D-finite equation, the entries of the connection matrix are themselves periods. They require an exact special-function identity, Mellin–Barnes calculation, relative-period argument, or another analytic derivation. Rigorous numerical continuation can compare them, but does not satisfy the FACET analytic deliverable.

6. Reusable exact function interfaces
6.1 Deriving the algebraic integration ideal
Wolfram Language
DeriveIntegrationIdeal[
  integrandSpec_Association,
  projectionSpec_Association,
  OptionsPattern[]
]
Input
Wolfram Language
integrandSpec = <|
  "PolynomialFactors" -> {f1, ..., fm},
  "Exponents" -> {a1, ..., am},
  "IntegrationVariables" -> {u1, ..., ur},
  "KinematicVariables" -> {z1, ..., zk},
  "Parameters" -> {Epsilon, ...},
  "CoefficientField" -> <|
    "Type" -> "RationalFunctionField",
    "Generators" -> {Epsilon, ...},
    "AlgebraicExtensions" -> {}
  |>,
  "KinematicIdeal" -> {},
  "BranchRecord" -> ...
|>;

projectionSpec = <|
  "EliminateVariables" -> {u1, ..., ur}
|>;
Output
Wolfram Language
<|
  "State" -> "ExactAlgebraicDirectImageIdealDerived",
  "IntegrandAnnihilator" -> oreIdealRecord,
  "DirectImageIdeal" -> oreIdealRecord,
  "TelescopingCertificates" -> certificates | Missing["Unavailable"],
  "ExceptionalParameterDivisor" -> polynomial,
  "Holonomic" -> True | False | "Undetermined",
  "HolonomicRank" -> integer | "Undetermined",
  "SingularLocus" -> {...},
  "PhysicalCycleEquationState" -> "Undetermined",
  "ExactProcessManifest" -> ...
|>
Exact criterion

every integrand operator annihilates the exact density;

every direct-image operator has a valid ideal-membership or telescoping certificate;

no eliminated coordinate or derivative survives;

all coefficients lie in the declared field;

every serialized operator survives an exact round trip.

6.2 Checking endpoint terms
Wolfram Language
CheckRelativeBoundaryTerms[
  directImageRecord_Association,
  cycleRecord_Association
]
Cycle input
Wolfram Language
cycleRecord = <|
  "DomainType" -> "Simplex",
  "Inequalities" -> {...},
  "Orientation" -> ...,
  "BoundaryFaces" -> {
    <|"Equation" -> g1 == 0, "OrientationSign" -> +1, ...|>,
    ...
  },
  "PhysicalChamber" -> ...,
  "FactorBranches" -> ...,
  "ConvergenceDomain" -> ...
|>;
Mathematical operation

For each telescoper P and certificate Q
i
	​

, compute

S
P
	​

=∫
∂Γ
	​

i
∑
	​

(−1)
i−1
Q
i
	​

ωd
u
i
	​

.
Output states
"HomogeneousPhysicalEquationVerified"
"ExactInhomogeneousBoundarySourceDerived"
"RelativeBoundarySystemDerived"
"BoundaryTermsUndetermined"
Exact criterion

Every face pullback is:

exactly zero;

reduced to a known lower-dimensional period;

or retained as a new exact boundary integral.

Absence of a certificate must yield Undetermined, never zero.

6.3 Classifying a scalar operator
Wolfram Language
ClassifyScalarOperator[
  operatorRecord_Association,
  OptionsPattern[]
]
Output
Wolfram Language
<|
  "PrimitiveOperator" -> L,
  "MonicOperator" -> Lmonic,
  "Order" -> n,
  "FactorizationField" -> field,
  "ExactFactors" -> {...},
  "SingularPoints" -> {...},
  "PoincareRanks" -> ...,
  "IndicialPolynomials" -> ...,
  "DesingularizedOperator" -> ...,
  "Recognition" ->
    "Algebraic" |
    "Liouvillian" |
    "GaussHypergeometric" |
    "GeneralizedHypergeometric" |
    "MPLCompatible" |
    "EllipticCandidate" |
    "Unclassified",
  "RecognitionCertificate" -> ...
|>
Exact criterion

Every claimed class must come with an exact substitution or operator-factor certificate. Failure of recognition is Unclassified, not evidence of ellipticity.

Use ore_algebra as the primary open backend, with Maple as an optional independent reference.

6.4 Generating local Frobenius modes
Wolfram Language
GenerateLocalFrobeniusModes[
  operatorRecord_Association,
  boundaryPoint_,
  seriesOrder_Integer,
  OptionsPattern[]
]
Output

A complete formal basis

e
q
j
	​

(λ
−1/r
)
λ
ρ
j
	​

k=0
∑
K
j
	​

	​

(logλ)
k
n=0
∑
N
	​

a
jkn
	​

λ
n/r
,

including:

ramification index;

exponential part;

Frobenius exponent;

logarithmic multiplicity;

coefficient recurrence;

exceptional parameter divisor.

Exact criterion

Substitution into the operator gives

Lf
j
	​

=O(λ
N+1
)

exactly, and the formal solution multiplicities sum to the operator order.

For regular-singular points the exponential parts are absent.

6.5 Matching the physical boundary record
Wolfram Language
MatchPhysicalBoundaryRecord[
  modeBasis_Association,
  physicalBoundary_Association,
  exactConstraints_List
]
Input

cut cycle and orientation;

physical chamber;

endpoint direction;

region-derived exponents;

inherited lower periods;

regularity and proven branch-absence equations;

direct boundary integrals.

Output
Wolfram Language
<|
  "ConstraintMatrix" -> C,
  "RightHandSide" -> b,
  "GenericRank" -> r,
  "ResidualNullity" -> nfree,
  "ModeCoefficients" -> solution | parameterizedSolution,
  "SelectedPhysicalModes" -> {...},
  "UnresolvedPeriods" -> {...}
|>
Exact criterion
C(ϵ)c=b(ϵ)

holds exactly, including resonant logarithmic modes. No physical mode is removed without an independent analytic equation.

This stage necessarily retains family-specific physics.

6.6 Verifying the reconstructed analytic master
Wolfram Language
VerifyAnalyticMaster[
  solutionRecord_Association,
  originalSystem_Association,
  boundaryRecord_Association,
  OptionsPattern[]
]
Required checks

Original Pfaffian residual:

∂
z
i
	​

	​

I
ana
	​

−A
i
	​

I
ana
	​

=0.

Scalar-operator residual:

LI
ana
	​

=0

or the exact inhomogeneous source equation.

Basis reconstruction:

I
ana
	​

=TJ
ana
	​

.

Boundary equations:

Cc−b=0.

Cut, normalization, branch, and chamber records unchanged.

Laurent depth sufficient after convolution with the master coefficient.

Output
"ExactAnalyticMasterVerified"

only when every displayed analytic residual is exactly zero.

AMFlow or another numerical result should be attached under a separate key:

"IndependentNumericalComparisons"

and never used to fill an unresolved analytic constraint.

7. Recommended production sequence
Cheap steps for every low-dimensional candidate boundary density

Validate exact coefficient field and branch grammar.

Remove kinematics-independent normalization factors.

Derive the s
i
	​

-parametric integrand annihilator.

Specialize exponents and record the exceptional divisor.

Compute the algebraic direct-image ideal.

Verify output field, eliminated variables, holonomicity, rank, and singular locus.

If one variable remains, construct and classify scalar operators with ore_algebra.

Generate local formal modes.

These steps are deterministic enough to package now.

Required physical step for every accepted period

Attach the physical relative-cycle record.

Compute or prove the vanishing of endpoint terms.

Match the physical mode and boundary constants.

These cannot be inferred from the algebraic ideal.

Expensive steps only when the operator remains unclassified or the boundary period is new

Holonomic creative telescoping with explicit certificates.

Oaku/Heaviside relative-domain treatment.

Generalized Griffiths–Dwork if the period has a suitable projective form.

Hypergeometric, Mellin–Barnes, recurrence, finite-basis, or geometry-specific analytic solution.

Exact connection constants from physical boundary integrals.

Independent numerical comparisons only after the analytic construction.

8. Adoption priority
Implement immediately

Harden the current Singular serializer and coefficient-field validator.

Rename the current result as an algebraic direct-image ideal.

Add round-trip, holonomicity, rank, and singular-locus checks.

Integrate ore_algebra for scalar-operator normalization and local modes.

Benchmark HolonomicFunctions on the endpoint-source example.

Pilot next

Risa/Asir for interval/simplex boundary sources.

Macaulay2 Dmodules as an independent algebraic direct-image check.

Use conditionally

Maple for exact recognition when a license is available.

Lairez’s periods for projectivizable closed rational periods.

Fanosearch/Magma only for specialized period-sequence problems.

Do not infer from the current wrapper

that an open-simplex equation is homogeneous;

that the returned operator is minimal;

that a physical branch has been selected;

that boundary constants are known;

that a failed direct image implies a nonholonomic or nonpolylogarithmic integral.

The correct durable division is:

Singular/Macaulay2/HolonomicFunctions
ore_algebra/Maple
FACET
	​

: exact differential ideals and telescopers,
: scalar-operator analysis and local modes,
: physical cuts, relative cycles, boundary sources, branches,
normalization, mode selection, and final analytic verification.
	​

	​

## Sources sent to Pro

- [masteranalyticrouteprototype_dmodule.wl](Sources/02_dmodule_package_review/masteranalyticrouteprototype_dmodule.wl)
