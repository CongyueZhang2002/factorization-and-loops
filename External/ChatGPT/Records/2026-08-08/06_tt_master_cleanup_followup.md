# TT Master Cleanup Followup

## Question

Continue the same FACET discussion. Please inspect the attached source files rather than inferring the implementation from this summary.

Measured TT status for the exact NLO pp -> h X calculation:

- All 25 tree-amplitude/conjugate-amplitude pairs completed.
- Cut-aware IBP reduced 87 target integrals in 8 topology classes to 6 masters.
- Applying the card-defined hadronic map to the complete target coefficients took 174.01 s.
- Termwise Simplify of the complete target coefficients took 253.37 s.
- After Kira composition, master-coefficient simplification started. Five workers/jobs appear to have returned, but the largest of the six coefficients has occupied one Mathematica worker for more than 8 minutes and its RSS has grown beyond 1.2 GB. The current production function applies master-level termwise Simplify without a time bound.
- For the representative TT F1 C1 pair, exact hadronic substitution followed by termwise Simplify reduced 5.95 MB to 311 kB in 9.49 s, and a subsequent whole-expression Simplify reduced this to 16.7 kB in 5.98 s.

The attached benchmark compares five exact orderings: pair-whole, target-whole, master-only, your proposed pair-termwise -> complete-target-whole -> complete-master-whole route, and the historical notebook's Collect by Beta/Gamma/Hypergeometric/log/angular objects with Factor[Cancel[Together[coefficient]]]. It also compares the complete unstripped master coefficient maps exactly.

Please answer these concrete questions:

1. For the one hard complete TT master coefficient, give an exact Mathematica transformation sequence more controlled than unrestricted Simplify. It must preserve BMHV objects and physical branches. Specify which algebraic basis to collect in and which coefficient function to use.
2. Should the historical special-function collection be applied at complete-target level, complete-master level, or both? Explain in terms of cancellation opportunities and expression growth.
3. Inspect the benchmark for any invalid comparison or Mathematica implementation error. In particular, verify that all routes simplify the full pair coefficient including PreFactor and that equality is checked before removing the common momentum-fraction monomial.
4. Propose a bounded fallback for a coefficient that remains difficult. The fallback must return the exact unchanged coefficient on timeout, not a numerical approximation.
5. For the later NNLO UU study (44,877 targets, 342 masters, 1,296 pairs), recommend a streaming experiment that compares complete target fibres and complete master columns without constructing one monolithic expression.

Do not recommend AMFlow or fixed-point numerics as the main simplification route. The deliverable is an exact analytic hard function.

## Pro response

I inspected the exact four-file archive: Reduction.wl, TT.wl, benchmark_tt_simplification_routes.wls, and the extracted historical notebook cells. 

tt_master_cleanup_followup_2026…

The immediate production problem is concrete: normalizeMasterCoefficients calls

Wolfram Language
parallelNormalizeCoefficients[coefficients, assumptions]

with the defaults

Wolfram Language
coefficientTimeLimit -> Infinity
mode -> "Terms"

at Reduction.wl:2078–2080. The difficult master therefore has no time or memory boundary. The benchmark does not exercise that same code path: its final master stage uses bounded, whole-coefficient Simplify with a 300-second limit. Those are materially different algorithms.

1. Controlled exact cleanup for the difficult TT master coefficient

Let the six complete master coefficients after Kira composition be C
m
	​

. First perform the common normalization using the entire master vector, not the difficult coefficient in isolation:

C
m
	​

=F
TT
	​

C
m
	​

,

where the expected TT factor contains

F
TT
	​

⊃
x
a
	​

x
b
	​

z
h
2
	​

α
s
3
	​

h
1
	​

(x
a
	​

)f
1
	​

(x
b
	​

)H
1
	​

(z
h
	​

)
	​

.

The exact factor actually used should remain the result of the existing branch and Laurent-monomial certificate, checked against the factorization convention declared by the card.

The expensive cleanup should act on 
C
m
	​

, not on the unstripped C
m
	​

.

Recommended transformation sequence

For each complete 
C
m
	​

:

Apply the fixed, card-certified half-integer-power rules.

Reject unresolved BMHV or integration objects.

Reduce trigonometric dependence to one fixed harmonic basis.

Freeze branch-sensitive analytic objects and tensor structures as inert atoms.

Collect equal analytic signatures.

Normalize only the rational coefficient of each signature.

Restore the inert objects.

Verify exact reconstruction signature by signature.

Schematically,

C
m
	​

=
σ
∑
	​

A
σ
	​

R
m,σ
	​

(s,t,u,ϵ),

where A
σ
	​

 is an exact inert signature and

R
m,σ
	​

∈Q(s,t,u,ϵ).
The collection basis

Use a product signature with the following entries.

Distribution and coupling structure

After the common factor has been removed, this entry will normally be 1. Before removal, keep distinct exact objects such as

h
1
	​

(x
a
	​

),f
1
	​

(x
b
	​

),H
1
	​

(z
h
	​

),α
s
3
	​

.

Do not collect f
1
	​

(x
a
	​

) with f
1
	​

(x
b
	​

).

Color structure

First reduce to one fixed color basis, for example monomials in

C
A
	​

,C
F
	​

,T
F
	​

n
f
	​

.

Then either:

include the color monomial in A
σ
	​

; or

include C
A
	​

,C
F
	​

,T
F
	​

n
f
	​

 among the polynomial variables of R
m,σ
	​

.

For this calculation, the second choice is usually more compact because it allows exact cancellation among color terms.

Azimuthal structure

Apply TrigReduce term by term and use the resulting exact harmonics as atoms:

cos(nϕ
a
	​

+mϕ
h
	​

),sin(nϕ
a
	​

+mϕ
h
	​

),n,m∈Z.

Do not mix TrigExpand and TrigReduce representations between routes. A fixed Fourier basis is preferable to treating arbitrary products of Sin and Cos as independent.

BMHV structure

At this stage, the following must cause failure rather than become inert basis objects:

Wolfram Language
SPE
DiracTrace
DiracGamma
FeynCalc`DOT
loop-dependent SP or SPD
the temporary tensor-reduction dimension

The BMHV dependence that is allowed to remain should already be encoded in rational functions of

D=4−2ϵ

and in declared physical spin or Levi-Civita structures. A surviving physical four-dimensional pseudoscalar or Levi-Civita contraction may be treated as an inert signature, but its orientation convention must be part of that signature.

Analytic-function structure

Freeze maximal exact objects involving:

Wolfram Language
Beta
Gamma
Hypergeometric2F1
PolyLog
Log
Pochhammer
Zeta
ConditionalExpression
Piecewise

and every noninteger power.

For compatibility with the historical calculation, recognize the composite object

Beta(…)
2
	​

F
1
	​

(…)

before recognizing its individual factors. Otherwise the collection basis overlaps and the benchmark does not reproduce the historical grouping.

No FunctionExpand, PowerExpand, or hypergeometric transformation should occur here.

Rational coefficient function

For each collected rational coefficient R, use:

termwise Cancel;

exact equal-denominator bucketing;

a bounded Factor[Cancel[Together[...]]] only when the bucket is small.

A suitable structure is:

Wolfram Language
ClearAll[boundedRationalCoefficientNormalize];

boundedRationalCoefficientNormalize[
    coefficient_,
    variables_List,
    timeLimit_
  ] := Module[
  {input, termwise, bucketed, result},

  input = coefficient;

  termwise = Total[
    Cancel /@ additiveTerms[Expand[input]]
  ];

  bucketed = exactDenominatorBucketMerge[
    termwise,
    variables
  ];
  If[bucketed === $Failed, Return[$Failed]];

  result = If[
    ByteCount[bucketed] <= 2*^6 &&
      Length[additiveTerms[bucketed]] <= 200,
    TimeConstrained[
      Factor[Cancel[Together[bucketed]]],
      timeLimit,
      bucketed
    ],
    bucketed
  ];

  If[exactDataQ[result], result, $Failed]
];

The numerical thresholds are tuning parameters, not mathematical conditions. If the bounded Together call expires, bucketed remains an exact result.

Collection implementation

I would avoid Collect directly on overlapping special-function expressions. Freeze maximal objects to unique atoms, then use CoefficientRules:

Wolfram Language
ClearAll[controlledTTMasterCleanup];

controlledTTMasterCleanup[
    coefficient_,
    context_Association,
    timeLimit_
  ] := Module[
  {
    assumptions, branchData, canonical, trigCanonical,
    frozenData, frozen, atoms, inverseRules,
    coefficientRules, normalizedRules, reconstructed
  },

  assumptions = context["Assumptions"];

  branchData = canonicalizePhysicalBranches[
    {coefficient},
    assumptions
  ];
  If[branchData === $Failed, Return[$Failed]];

  canonical = First[branchData["Expressions"]];

  If[! FreeQ[canonical, forbiddenPostIBPObjects],
    Return[$Failed]
  ];

  trigCanonical = Total[
    TrigReduce /@ additiveTerms[canonical]
  ];

  frozenData = freezeCoefficientBasis[
    trigCanonical,
    context
  ];
  If[FailureQ[frozenData], Return[$Failed]];

  frozen = frozenData["Expression"];
  atoms = frozenData["Atoms"];
  inverseRules = frozenData["InverseRules"];

  If[! PolynomialQ[Expand[frozen], atoms],
    Return[$Failed]
  ];

  coefficientRules = CoefficientRules[
    Expand[frozen],
    atoms
  ];

  normalizedRules = Map[
    Function[rule,
      First[rule] ->
        boundedRationalCoefficientNormalize[
          Last[rule],
          {s, t, u, Epsilon, CA, CF},
          timeLimit
        ]
    ],
    coefficientRules
  ];
  If[MemberQ[normalizedRules, $Failed, Infinity],
    Return[$Failed]
  ];

  reconstructed = Total[
    (Times @@ MapThread[Power, {atoms, First[#]}]) Last[#] & /@
      normalizedRules
  ] /. inverseRules;

  If[
    ! exactSignatureEqualityQ[
      canonical,
      reconstructed,
      context
    ],
    $Failed,
    reconstructed
  ]
];

This captures cancellations across all additive terms with the same physical and analytic structure without placing the entire master coefficient over one common denominator.

2. Where the historical collection belongs

Use analytic-signature collection at both complete-target and complete-master level, but distinguish it from the historical Beta–hypergeometric calculation.

Complete targets

After all pair contributions to a target G
α
	​

 have been summed, collection can expose:

cancellations between different diagrams;

cancellation of radical representations;

cancellation among color and azimuthal structures;

common rational denominators.

This should occur before Kira because every reduction coefficient otherwise multiplies the larger target expression.

The target-level version should be relatively conservative:

card-certified branch normalization;

fixed color and azimuthal bases;

termwise Cancel or Simplify;

collection by exact signatures;

bounded rational cleanup.

Complete masters

Repeat the collection after Kira because different targets feed the same master:

K
m
	​

=
α
∑
	​

R
αm
	​

C
α
	​

.

Cancellations generated by the rational Kira coefficients R
αm
	​

 cannot be seen at target level.

The master-level version can use a stronger bounded coefficient function because there are only six coefficients at NLO.

After analytic master evaluation

The historical notebook’s Beta–hypergeometric collection was performed after the phase-space integrations had produced Beta and hypergeometric functions. In the extracted historical sequence, CollectSimplify follows PSIntegrate and variable substitution.

Therefore:

The exact historical Beta–hypergeometric collection is primarily an evaluated-master cleanup.
	​


Before evaluating the masters, target and master coefficients may contain Gamma factors or logarithms, but they generally do not yet contain the full

Beta(…)
2
	​

F
1
	​

(…)

basis that the historical routine was designed to collect.

The same signature machinery is useful before master evaluation, but the benchmark should not describe that pre-evaluation step as a faithful reproduction of the historical algorithm unless those objects are actually present.

3. Audit of the benchmark
Full pair coefficients do include PreFactor

This part is correct.

In benchmark_tt_simplification_routes.wls:211–220, every pair is processed as

Wolfram Language
part = linearIntegralSum[record["Integrand"]];
part = linearMapIntegrals[part, equivalenceRules];
linearScale[part, record["PreFactor"]]

Thus all routes operate on

P
p
	​

c
pα
	​

,

not on the bare coefficient extracted from Integrand.

Equality is checked before the common momentum-fraction factor is removed

This is also correct.

The benchmark never calls normalizeMasterCoefficients or
normalizeHardFractionDependence. The route outputs are the complete,
unstripped master-coefficient maps. The comparisons at
benchmark_tt_simplification_routes.wls:367–385 are therefore made before
extracting 1/(x
a
	​

x
b
	​

z
h
2
	​

).

Several other issues must be corrected.

Issue 1: the benchmark’s master cleanup is not the production cleanup

Production uses unbounded termwise simplification:

Wolfram Language
parallelNormalizeCoefficients[coefficients, assumptions]

at Reduction.wl:2078–2080.

The benchmark uses:

Wolfram Language
wholeSimplifyPart[physical, 300]

through runFinalMasterCleanup.

Thus the benchmark compares bounded whole-expression cleanup, while the live calculation is hanging in unbounded termwise cleanup. The results cannot be used as timings for the active production code without stating this distinction.

Issue 2: the “historical route” is only an incremental postprocessing step

The historical stage starts from targetFinal, which is already the output of:

target whole simplification→Kira→master whole simplification.

Its recorded "Seconds" contains only historicalSeconds, not the time needed to obtain targetFinal.

Therefore this metric cannot be ranked as a fifth independent route. It is:

TargetThenMaster+additional historical-style cleanup.

The total time should be recorded as

Wolfram Language
targetMetric["Seconds"] + historicalSeconds

with the stages listed separately.

Issue 3: the benchmark does not reproduce the historical basis

The historical notebook defined a basis containing:

Wolfram Language
Beta[...] Hypergeometric2F1[...]
Beta[...]
Hypergeometric2F1[...]

with the composite product recognized explicitly.

The benchmark uses:

Wolfram Language
_Beta | _Hypergeometric2F1 | _Gamma | _PolyLog | _Log

plus Sin and Cos, but omits the composite Beta–hypergeometric product.

It therefore uses a broader and overlapping basis and can produce different grouping and timing.

Issue 4: it applies the historical cleanup at a different mathematical stage

The historical notebook applied the collection after analytic phase-space integration. The benchmark applies it to the coefficients of unevaluated Kira masters.

This is a useful generic analytic-atom experiment, but not a direct reconstruction of the historical workflow.

Issue 5: exact equality is not enforced

exactPartEquality returns a list whose entries may be:

Wolfram Language
True
False
Missing["TimeLimit"]

The script writes that list into the summary but never requires every entry to be True.

The acceptance criterion should be:

Wolfram Language
exactPartEqualityQ[first_, second_] := Module[
  {checks = exactPartEquality[first, second]},
  ListQ[checks] && AllTrue[checks, TrueQ]
];

and the script should terminate if any route comparison returns False or Missing["TimeLimit"].

A timeout is absence of proof, not equality.

Issue 6: hadronic substitution is repeated unnecessarily

runFinalMasterCleanup calls physicalSimplify, which reapplies the hadronic map.

For routes A, B, and D, the coefficients have already been physicalized before Kira. Kira introduces only rational functions of the partonic invariants, so the second physicalization should be a no-op, but it adds timing and traversal cost.

For a fair comparison:

physicalize once at the stage prescribed by each route;

use wholeSimplifyPart directly at later stages when the input is already physical.

Issue 7: timeout counts are not retained in route metrics

parallelNormalizeCoefficients prints the timeout count but returns only:

Wolfram Language
{expressions, activeKernels, additiveTermCount}

A route may therefore appear fast because several coefficients were returned unchanged after timeout. The benchmark summary cannot distinguish this from successful simplification.

Return and record at least:

Wolfram Language
<|
  "Expressions" -> ...,
  "Kernels" -> ...,
  "AdditiveTerms" -> ...,
  "Timeouts" -> timeoutCount,
  "RecycledWorkers" -> recycledCount
|>

Route sizes and times are not fairly comparable without these fields.

Issue 8: route timings are order- and cache-dependent

All routes run sequentially in one main kernel. ClearSystemCache[] does not reproduce a fresh Wolfram process, clear all allocator history, or necessarily clear all transformation caches.

For reliable timing:

run each route in a fresh kernel process;

use the same kernel count;

use the same cold-cache or warm-cache policy;

repeat at least twice;

compare medians;

record maximum resident memory externally.

Exact equality can still be checked later in a separate process.

Issue 9: the current branch registry is derived after the routes finish

The script constructs sharedBranchRules from the union of all route outputs. The rules are individually certified, so this is not inherently algebraically wrong. A cleaner comparison uses a branch registry generated once from:

the card;

the raw physical master coefficients;

the declared chamber.

Every route then receives exactly the same registry. This makes branch handling part of the input rather than a property inferred from the outputs being compared.

Issue 10: TrigExpand is not a canonical comparison basis

The equality checker uses:

Wolfram Language
TrigExpand /@ differences

This can enlarge the coefficient and still leave equivalent trigonometric forms.

Reduce both sides to one fixed Fourier basis and compare harmonic coefficients. This gives a finite exact test.

4. Bounded fallback for the hard coefficient

The current parallelNormalizeCoefficients already has the right exact fallback semantics when a finite limit is supplied:

Wolfram Language
TimeConstrained[
  transformedExpression,
  limit,
  originalCoefficient
]

The production defect is that normalizeMasterCoefficients supplies Infinity.

Add:

Wolfram Language
masterCoefficientSimplifyTimeLimit[] := If[
  ValueQ[Global`$FACETMasterSimplifyTimeLimit] &&
    NumericQ[Global`$FACETMasterSimplifyTimeLimit] &&
    Global`$FACETMasterSimplifyTimeLimit > 0,
  Global`$FACETMasterSimplifyTimeLimit,
  120
];

Then replace the unbounded call with the controlled transform:

Wolfram Language
simplified = parallelTransformCoefficients[
  coefficients,
  Function[coefficient,
    controlledTTMasterCleanup[
      coefficient,
      context,
      masterCoefficientSimplifyTimeLimit[]
    ]
  ],
  masterCoefficientSimplifyTimeLimit[]
];

The outer wrapper should be:

Wolfram Language
boundedExactCleanup[
    coefficient_,
    context_Association,
    seconds_
  ] := Module[{result},

  result = TimeConstrained[
    controlledTTMasterCleanup[
      coefficient,
      context,
      seconds
    ],
    seconds,
    $TimedOut
  ];

  Which[
    result === $TimedOut,
      coefficient,

    result === $Failed || ! exactDataQ[result],
      $Failed,

    ! exactSignatureEqualityQ[coefficient, result, context],
      $Failed,

    True,
      result
  ]
];

On timeout, this returns the exact input coefficient, not a partial or numerical result.

Worker recycling defect

The current recycling logic contains:

Wolfram Language
If[! MemberQ[launchedKernels, kernel], Return[True]];

A timed-out pre-existing kernel is therefore not closed and can retain its large allocator state. That matters directly for the observed >1.2 GB worker.

For batch production, the coefficient normalizer should own its worker pool. The simplest policy is:

start with a clean dedicated pool;

schedule only coefficient jobs on that pool;

close and replace every worker that times out;

close the pool after the stage.

If preserving unrelated user kernels is required, the scheduler needs explicit worker ownership rather than drawing indiscriminately from Kernels[].

The serial fallback should also be avoided for difficult coefficients because a timed-out computation in the main kernel may retain memory.

5. Streaming NNLO experiment

Do not begin by processing all 44,877 targets or all 342 masters. Build two exact incidence indices first.

Metadata pass

Read each of the 1,296 pair files one at a time and record

p⟼{(α,b
pα
	​

,n
pα
	​

)},

where:

α is the canonical target GLI;

b
pα
	​

 is the stored byte count;

n
pα
	​

 is the additive-term count.

From the Kira artifact, stream the sparse rules and construct

α⟼{m:R
αm
	​


=0}

and

m⟼{α:R
αm
	​


=0}.

Do not retain coefficient expressions during this pass.

Complete target fibres

Choose a deterministic set of targets including:

the largest total input byte counts;

the largest numbers of contributing pairs;

the largest Kira fan-outs;

several median targets;

at least one target from each major topology class.

For each chosen α, load all pair contributions c
pα
	​

. Compare:

A
α
	​

B
α
	​

D
α
	​

	​

=N
whole
	​

[H(
p
∑
	​

P
p
	​

c
pα
	​

)],
=
p
∑
	​

N
whole
	​

[H(P
p
	​

c
pα
	​

)],
=N
whole
	​

[
p
∑
	​

N
terms
	​

[H(P
p
	​

c
pα
	​

)]].
	​


Each calculation should run in a fresh process and store only the resulting target coefficient and metrics.

Require exact equality before extracting the hard factor.

Complete master columns

Choose masters with:

maximum target fan-in;

maximum predicted raw byte count;

median fan-in;

small fan-in;

different topology classes.

For each selected master M
m
	​

, process the complete set

T
m
	​

={α:R
αm
	​


=0}.

Stream the target coefficients and accumulate

K
m
	​

=
α∈T
m
	​

∑
	​

R
αm
	​

C
α
	​


using an on-disk balanced merge or analytic-signature buckets.

Compare:

raw targets followed by master-only cleanup;

complete-target cleanup followed by master cleanup;

pair-termwise, complete-target, then master cleanup.

No incomplete target subset or incomplete master column gives a valid cancellation benchmark.

Measurements to retain

For every complete fibre and column, record:

wall time;

peak RSS;

input and output bytes;

additive-term count;

number of analytic signatures;

timeout count;

recycled-worker count;

exact equality result before hard-factor extraction;

exact equality result after hard-factor extraction;

surviving x
a
	​

,x
b
	​

,z
h
	​

;

surviving radicals or forbidden BMHV objects.

This experiment will identify whether pair-local compression is worth its repeated cost and how much cancellation is created specifically by target summation and by Kira composition, without constructing a monolithic NNLO expression.

## Sources sent to Pro

- [tt_master_cleanup_followup_sources.zip](Sources/06_tt_master_cleanup_followup/tt_master_cleanup_followup_sources.zip)
