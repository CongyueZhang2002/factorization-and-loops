# NNLO Target Simplification

## Question

We implemented and regression-tested the target-before-master strategy discussed in this same thread. Please advise on the remaining exact NNLO bottleneck. The project deliverable is an exact analytic hard function; numerical evaluation or approximate reconstruction is verification only.

Current concrete state:

- A completed Kira reduction maps 44,877 target GLIs to 342 masters. The saved exact Kira artifact is 2.53 GB.
- Loading/deserializing it in Mathematica uses about 25 GB RSS before coefficient workers start.
- On the full NLO regression, simplifying each target coefficient before applying the sparse Kira map reduces target data from 40.9 MB to 16.6 MB and raw master data from 99.1 MB to 39.8 MB. It gives the same exact final result and is about 27% faster than simplifying only after master accumulation.
- Native Mathematica termwise Simplify was better in our controlled tests than Symbolica, FORM, and SymPy once Mathematica cleanup and branch-sensitive objects were included.
- Some NNLO target coefficients are pathological: an unrestricted Simplify on one coefficient can retain more than 8 GB. TimeConstrained returns the exact original coefficient, but an aborted worker retains allocator memory.
- We therefore use a bounded dynamic pool with a 60-second whole-coefficient limit. A timeout returns the original exact coefficient, closes that now-idle subkernel, and launches a fresh replacement. Forced-timeout tests and a full NLO regression pass exactly.
- Master coefficients are still simplified exactly without a timeout after sparse reduction and accumulation.

Please assess whether this is the right production strategy and propose a more effective exact symbolic method for the pathological NNLO coefficients. In particular:

1. Is target-before-master simplification optimal, or should we first use the sparse Kira map to group a bounded subset of targets that feed the same masters, expose cancellations, and only then simplify?
2. Can the coefficients be partitioned into an algebraic/transcendental basis (rational functions, Gamma functions, noninteger powers, logs, FeynCalc scalar products) so that only rational coefficients are normalized while branch-sensitive atoms remain inert?
3. Would exact finite-field reconstruction help here despite Gamma functions and noninteger powers, and if so, what precise object should be reconstructed and over which variables?
4. How can we avoid loading the entire 2.53 GB Kira artifact into a 25 GB Mathematica expression at once? Is there a sound streamed sparse-map representation and accumulation order that preserves exact cancellation?
5. Give a concrete operation order and pseudocode suitable for Mathematica/FeynCalc. It must preserve assumptions, branches, BMHV information, cut/topology identity, and exact GLI coefficients. Please identify any proposed step that can silently change analytic branches.

Please focus on changes likely to improve the 44,877-to-342 exact reduction, and distinguish expected memory reduction from expected CPU reduction.

## Pro response

Yes—with two important qualifications. Your bounded target-before-master pool is the right production default, and recycling a timed-out subkernel while returning the untouched coefficient is exact and operationally sound. But the NNLO production path still has two avoidable failure points:

the entire Kira map is materialized as one 25 GB Mathematica object;

unrestricted final Simplify merely moves the same possible memory explosion from 44,877 targets to 342 masters.

The best next step is a hybrid exact contraction:

bounded target cleanup⟶protected analytic/BMHV basis⟶streamed Kira rows⟶bounded master-local rational accumulation.

Finite fields should be a fallback for the remaining pathological rational master/basis coefficients, not for the complete expressions containing Gamma functions, powers, logs, or BMHV structures.

1. Target-before-master versus bounded master grouping

Write the Kira map as

I
t
	​

=
m=1
∑
342
	​

K
tm
	​

(z)M
m
	​

,

so the reduced master coefficient is

C
m
	​

=
t=1
∑
44877
	​

c
t
	​

K
tm
	​

.

Your NLO result is strong evidence that simplifying ordinary c
t
	​

 first should remain the default:

the work is done once per target and amortized over every nonzero entry in its Kira row;

a large unsimplified c
t
	​

 is not copied into several masters;

you measured about a 60% representation reduction and a 27% CPU improvement.

But target-local simplification cannot see cancellations between

c
t
1
	​

	​

K
t
1
	​

m
	​

+c
t
2
	​

	​

K
t
2
	​

m
	​

.

Therefore the production rule should be:

Simplify cheap targets first with the current bounded worker.

For a timed-out or preclassified pathological target, skip whole-expression Simplify and perform rational-basis normalization.

Multiply by the actual Kira coefficients.

Accumulate a bounded weighted sum separately for each master and analytic/BMHV basis signature.

Normalize those bounded partial sums exactly and merge them in a balanced tree.

Merely grouping targets because their Kira rows have the same set of masters is not algebraically useful. The weights K
tm
	​

 matter. Grouping should happen after multiplication by the row entries.

There is one exact pre-map optimization worth testing: identical or proportional Kira rows. If

K
t
2
	​

m
	​

=q(z)K
t
1
	​

m
	​

for every m,

then their combined contribution is

(c
t
1
	​

	​

+qc
t
2
	​

	​

)
m
∑
	​

K
t
1
	​

m
	​

M
m
	​

.

Exact identical-row detection is cheap after canonical row serialization. Proportional-row detection requires selecting a pivot entry and rationally normalizing all ratios, so it should be an optional offline optimization, not part of the first production patch.

2. Partition into a rational field and protected signatures

Yes. This is the most promising symbolic replacement for pathological whole-expression Simplify.

Represent each target coefficient as

c
t
	​

=
α
∑
	​

r
tα
	​

(z)A
α
	​

,

where:

r
tα
	​

∈Q(z) is an exact rational function;

A
α
	​

 is a held, exactly reversible analytic/tensor signature.

The Kira coefficients are rational, so

C
m
	​

=
α
∑
	​

[
t
∑
	​

r
tα
	​

(z)K
tm
	​

(z)]A
α
	​

.

Thus all rational cancellation for a fixed signature is exposed without allowing Mathematica to inspect or transform that signature.

This need not be a mathematically minimal transcendental basis. It is a faithful syntactic module representation. Missing an identity between two different Gamma or logarithmic signatures may make the answer less compact, but it cannot make it wrong.

Rational generators

Use only declared commuting algebraic quantities, for example:

one scalar dimension/regulator variable;

algebraically independent kinematic ratios;

masses and rational scale ratios;

N
c
	​

,N
f
	​

, if genuinely required symbolically;

residual commuting scalar products after authorized kinematic reduction;

exact rational constants.

Do not reconstruct simultaneously in D and ϵ. Given your existing operation order, the minimal-change choice is:

map Kira’s dimension symbol to a dedicated scalar symbol such as dimScalar;

reconstruct and normalize rational functions in dimScalar;

apply dimScalar -> 4 - 2 Epsilon once afterward.

If target coefficients already contain independent rational dependence on Epsilon, instead convert the Kira dimension consistently before reconstruction. The central requirement is one regulator variable, not both.

Do not apply a blanket

Wolfram Language
/. D -> 4 - 2 Epsilon

while D can also occur inside FeynCalc dimension tags.

Protected signatures

Keep at least the following inert:

Log, polylogarithms, HPLs/GPLs and hypergeometric functions;

every symbolic or noninteger Power;

Gamma, Pochhammer, harmonic sums and zeta constants;

endpoint factors, delta functions and plus distributions;

complete objects containing an explicit causal prescription or branch choice;

Piecewise and ConditionalExpression;

Dirac, tensor, Levi-Civita, spin and polarization structures;

barred, hatted and evanescent BMHV structures;

noncommutative words, with their order retained;

algebraic roots unless you deliberately use a rational parametrization or finite-field extension.

Gamma itself is single-valued, but freezing it prevents general recurrence, reflection and duplication transformations from entering the hot path. An optional audited canonicalizer may use only integer argument shifts such as

Γ(z+n)=Γ(z)
k=0
∏
n−1
	​

(z+k),

which are exact meromorphic identities. I would not start with reflection or duplication formulas.

A nonlinear subtree such as

x+Γ(1−ϵ)
1
	​


can simply be retained as one composite held signature. This gives less rational cancellation, but remains exact.

FeynCalc scalar products and BMHV

Scalar products are algebraic rather than transcendental, so they can enter the rational field after exact canonical tagging:

convert to the chosen canonical FeynCalc internal representation;

apply only setup-authorized momentum-conservation, on-shell and scalar-product rules;

replace every residual commuting scalar product with an injective tagged generator;

retain a literal reverse dictionary.

The dimension tag is part of the generator identity. FeynCalc explicitly distinguishes four-dimensional scalar products from SPD, which is D-dimensional and internally carries Momentum[..., D]. They must never be merged. FeynCalc’s SPD documentation

For example, use distinct keys corresponding schematically to

Wolfram Language
sp4[p, q]
spD[p, q]
spHat[p, q]

and never infer sp4[p,q] == spD[p,q]. In particular, an evanescent object such as your SPe must survive even when the corresponding D-dimensional momentum is on shell.

Rational normalizer

Within each basis bucket, use rational algebra only:

Wolfram Language
ratNormalize[pieces_List] := Module[
  {clean, byDenominator},

  If[! AllTrue[pieces, rationalDomainQ],
    Return[Failure["NonRationalBucket", <||>]]
  ];

  clean = Cancel /@ pieces;

  byDenominator = GroupBy[
    clean,
    Denominator,
    Numerator
  ];

  Cancel @ Together @ Total[
    KeyValueMap[
      Total[#2]/#1 &,
      byDenominator
    ]
  ]
];

Here rationalDomainQ must accept only rational numbers, declared generators, Plus, Times, and integer powers. It must reject every protected object.

Grouping identical denominators before Together is valuable because it avoids repeatedly rediscovering a common denominator. For large buckets, use a balanced pairwise ratNormalize, not a left-associated fold.

Cancel and Together on a verified rational coefficient are branch-neutral. They may remove removable singularities, so retain the original denominator/endpoint-domain certificate separately when a singular hypersurface has distributional significance.

3. Exact finite-field reconstruction

Finite fields can help substantially, but the reconstruction target should be

F
mα
	​

(z)=
t
∑
	​

r
tα
	​

(z)K
tm
	​

(z)
	​


for one master m and one held signature A
α
	​

.

Do not reconstruct:

the complete c
t
	​

;

Gamma functions or logarithms;

noninteger powers;

distributions or prescriptions;

complete BMHV/tensor expressions;

the already available exact Kira map by itself.

This master/signature organization sees all target-to-master rational cancellations and reduces the output set from 44,877 target functions to at most 342×N
signature
	​

 rational functions.

FiniteFlow was designed precisely for dataflow calculations and reconstruction of multivariate rational functions without materializing large intermediate symbolic expressions, while Kira/FireFly demonstrate the same finite-field approach for IBP coefficients. FiniteFlow paper
, Kira 2.0 and finite-field methods
, FireFly 2.0

Variables to reconstruct

Use only algebraically independent rational coordinates:

z={one regulator,x
1
	​

,…,x
n
	​

,optional color parameters}.

In particular:

eliminate one of s,t,u,q
2
 using the exact kinematic relation;

scale out an overall dimensionful invariant where homogeneity allows;

prefer dimensionless rational variables such as x=−t/s, y=−u/s;

do not sample Gram- or momentum-conservation-dependent invariants independently;

do not treat a finite-field square root as selecting a physical branch.

If all physical kinematics have already been fixed to exact rational values, reconstruction becomes univariate in D or ϵ, which is especially attractive.

Full rational versus Laurent reconstruction

There are two exact modes:

Reconstruct the full rational function F
mα
	​

(D,x,…), then substitute D=4−2ϵ.

If the required hard-function Laurent depth is already certified, perform exact truncated Laurent arithmetic in ϵ during the modular evaluation and reconstruct each rational Laurent coefficient separately.

The second can be much cheaper, but only after the required depth is derived from:

the hard-function order needed;

each master’s leading pole;

the coefficient’s ϵ-valuation;

evanescent prefactors;

Gamma and noninteger-power expansions.

It should not be inferred from numerical stability.

Making reconstruction genuinely exact

Finite-field arithmetic and rational reconstruction are exact; however, guessed support plus extra random probes is only probabilistic verification.

For an exact production certificate, construct a denominator bound. For every m,α,

L
mα
	​

=lcm
t
	​

den(r
tα
	​

K
tm
	​

).

Addition can cancel denominator factors but cannot create a new factor outside this LCM. Keep L factored rather than expanding it.

For a reconstructed candidate F
mα
	​

=N/D, require:

D divides the certified denominator bound L
mα
	​

;

an exact streamed verification of

L
mα
	​

[
t
∑
	​

r
tα
	​

K
tm
	​

−
D
N
	​

]=0

as a sparse polynomial over Q.

Independent unused primes and points should still be used, but as regression checks rather than the sole proof. Kira’s finite-field documentation likewise emphasizes that known denominators/prefactors substantially simplify reconstruction. Kira 2.0 paper

4. Streaming the 2.53 GB Kira map

Do not load it as one Mathematica expression. Store it as an indexed target-major sparse row map:

Wolfram Language
HoldComplete[
  ReductionRow[
    targetID,
    {
      {masterID1, exactRationalCoefficient1},
      {masterID2, exactRationalCoefficient2},
      ...
    }
  ]
]

Use integer target and master IDs in the rows. Keep authoritative dictionaries separately:

TargetID -> complete canonical topology/family identity and GLI index vector
MasterID -> complete physical master GLI and metadata

A hash may check integrity but must never replace the full identity.

A minimal manifest should include:

Wolfram Language
<|
  "SchemaVersion" -> 1,
  "SourceKiraArtifactHash" -> ...,
  "TargetCount" -> 44877,
  "MasterCount" -> 342,
  "CanonicalTopologyFingerprint" -> ...,
  "TopologyEquivalenceFingerprint" -> ...,
  "CutConventionFingerprint" -> ...,
  "SetupLoopSectorFingerprint" -> ...,
  "AnalyticContext" -> HoldComplete[...],
  "BMHVContext" -> HoldComplete[...],
  "KiraVariableOrder" -> ...,
  "ReverseRulesFingerprint" -> ...,
  "ScalarDimensionConvention" -> ...,
  "FeynCalcVersion" -> ...,
  "WolframVersion" -> ...
|>

This does not require introducing persisted per-propagator i0 or sign metadata for real phase-space denominators. Keep your current design: prescriptions derived from the setup loop sectors remain derived. The store needs cut/topology identity and the analytic-context fingerprint, not new causal metadata.

Storage format

Two reasonable low-risk choices are:

coarse WXF shards, each containing a bounded number of rows;

a length-prefixed WXF record stream with an offset/length/checksum index.

WXF represents arbitrary exact Wolfram expressions in a platform-independent, versioned binary format, and BinarySerialize/BinaryDeserialize provide the byte-array round trip. It can also import expressions held. WXF documentation
, Binary serialization documentation

Conceptually:

manifest.wxf
targets.wxf
masters.wxf
rows.bin
rows.idx

If the current artifact is a single WXF, MX, list or association, a partial Get is not a sound indexed-access strategy. Prefer re-exporting the retained Kira result without rerunning the reduction. Kira supports exports readable by Mathematica and FORM, as well as its user-system-compatible file format. Kira export documentation in the Kira 2.0 paper

If the native Kira result is no longer available, one high-memory migration may be necessary, but it should be a one-time conversion.

Exact out-of-core accumulation

Read matching target and Kira records in increasing TargetID; no global Dispatch is required. Process bounded batches measured by both:

number of nonzero Kira edges;

deserialized ByteCount, not merely row count.

For each batch, scatter exact contributions into keys

{MasterID, AnalyticBasisID, DenominatorSignature}

and spill normalized partials to disk.

Use a binary-counter merge per {MasterID, AnalyticBasisID}:

retain at most one partial at each level;

when a second partial arrives at level k, merge them exactly and spill at level k+1;

finalize by merging occupied levels in a fixed order.

This creates an approximately balanced addition tree. Streaming changes only the parenthesization of exact additions, so all cancellations are preserved. Never drop a term using numerical sampling, PossibleZeroQ, Chop, or a timeout.

5. Recommended production order

The helper functions below are package-level pseudocode; the important point is the data and algebra order.

Wolfram Language
prepareTargetCoefficient[expr_] := Module[
  {candidate, module},

  candidate = If[
    cheapWholeSimplifyQ[expr],
    boundedSimplifyInFreshKernel[
      expr,
      60,
      (* exact timeout fallback *)
      expr
    ],
    expr
  ];

  module = protectedModuleNormalize[
    candidate,
    $DeclaredRationalGenerators,
    $AnalyticContext,
    $BMHVContext
  ];

  If[
    ! exactModuleReconstructionQ[module, candidate],
    Return[Failure["ModuleReconstructionFailure", <||>]]
  ];

  module
];

protectedModuleNormalize returns something like

Wolfram Language
<|
  analyticSignatureID1 -> exactRationalCoefficient1,
  analyticSignatureID2 -> exactRationalCoefficient2,
  ...
|>

A nondecomposable analytic subtree is simply registered as a composite held signature.

The streamed contraction is then:

Wolfram Language
processOneTarget[
    TargetCoefficient[targetID1_, coefficient_],
    ReductionRow[targetID2_, row_List]
  ] := Module[
  {parts},

  If[targetID1 =!= targetID2,
    Return[Failure[
      "TargetRowMismatch",
      <|"TargetCoefficient" -> targetID1,
        "ReductionRow" -> targetID2|>
    ]]
  ];

  verifyExactTargetIdentity[targetID1];
  verifyCutAndTopologyIdentity[targetID1];

  parts = prepareTargetCoefficient[coefficient];

  Scan[
    Function[edge,
      Module[
        {masterID = edge[[1]], kiraCoefficient = edge[[2]]},

        If[! rationalDomainQ[kiraCoefficient],
          Return[Failure[
            "NonRationalKiraCoefficient",
            <|"Target" -> targetID1,
              "Master" -> masterID|>
          ]]
        ];

        KeyValueMap[
          Function[{signatureID, rationalCoefficient},
            insertBoundedMasterBucket[
              masterID,
              signatureID,
              Cancel[
                kiraCoefficient rationalCoefficient
              ]
            ]
          ],
          parts
        ];
      ]
    ],
    row
  ];

  flushBucketsOverBudget[];
];

The outer driver should be:

Wolfram Language
While[
  targetRecord =!= EndOfFile &&
  reductionRow =!= EndOfFile,

  processOneTarget[targetRecord, reductionRow];

  targetRecord = nextTargetRecord[];
  reductionRow = nextReductionRow[];
];

flushAllBuckets[];

Finalization is one master at a time:

Wolfram Language
finalizeMaster[masterID_] := Module[
  {moduleCoefficient, coefficient, cleaned},

  moduleCoefficient =
    balancedMergeAllSignaturePartials[masterID];

  moduleCoefficient =
    moduleCoefficient /. dimScalar -> 4 - 2 Epsilon;

  coefficient =
    rehydrateProtectedSignatures[moduleCoefficient];

  cleaned =
    boundedSimplifyInFreshKernel[
      coefficient,
      $FinalMasterTimeLimit,
      coefficient
    ];

  verifyMasterCoefficient[
    masterID,
    cleaned,
    moduleCoefficient
  ];

  writeExactMasterCoefficient[masterID, cleaned];
];

I would not leave final master Simplify unrestricted. A rational-module-normalized coefficient is already an exact production result; global Mathematica minimality is not part of exactness. If final whole-expression cleanup times out, keep the exact structured coefficient and recycle that kernel exactly as you already do for targets.

For a rational bucket that still exceeds its time or memory threshold, replace balancedMergeAllSignaturePartials with the finite-field reconstruction of F
mα
	​

, followed by the exact cleared-denominator residual.

Branch and scheme hazards
Operation	Production status
Together/Cancel on a verified rational bucket	Safe as a meromorphic rational identity
Balanced regrouping of exact sums	Safe
Literal freeze/thaw of complete analytic atoms	Safe
Integer Gamma argument shifts	Exact but optional; audit pole bookkeeping
PowerExpand	Prohibited; silently changes branches
Log expansion or contraction	Prohibited without a branch certificate
Combining or splitting noninteger powers	Prohibited
ComplexExpand	Prohibited; introduces reality assumptions
Generic FunctionExpand on protected atoms	Avoid
Simplify, FullSimplify, or Refine before atomization	Branch-risking and memory-risking
Replacing negative bases by positive cores	Unsafe unless the certified phase is retained
Finite-field evaluation of square roots to choose a sheet	Invalid
Identifying SP and SPD	Invalid; erases BMHV information
Blanket D -> 4 - 2 Epsilon inside dimension tags	Invalid
Reordering a noncommutative Dirac/BMHV word	Invalid
GLI keying without family, topology representative and cut slots	Invalid
Numerical zero detection or timeout-based dropping	Invalid
Expected resource effects
Change	Peak-memory effect	CPU effect
Keep bounded target-first simplification for ordinary targets	Already demonstrated large reduction	Already demonstrated improvement
Protected-signature rational normalization	Potentially very large reduction for pathological targets	Usually a large win; avoids general identity search
Streamed row store instead of monolithic Kira object	Removes the fixed 25 GB resident map	Small I/O cost; likely offset by avoiding giant deserialization and Dispatch
Integer target/master IDs	Moderate disk/RSS reduction	Faster comparison and lookup
Weighted master-local buckets	Large, predictable peak reduction	Conditional; improves when cancellations occur
Denominator grouping	Moderate memory reduction	Often substantial CPU reduction
Balanced external merge	Large reduction versus growing all 342 masters simultaneously	Usually better than repeated left-fold simplification
Identical/proportional-row folding	Proportional reduction when present	Direct CPU reduction
Finite fields for selected master/signature buckets	Very large memory reduction	Conditional; excellent for high swell/cancellation, wasteful for easy coefficients
Unrestricted final master Simplify	No upstream benefit; unbounded risk	Can dominate the entire run

The implementation priority I would use is:

Replace the monolithic Kira artifact with indexed target-major rows.

Add protected-signature rational normalization for timed-out or structurally large targets.

Accumulate weighted contributions in bounded {master, signature, denominator} buckets with balanced external merging.

Make final whole-master Simplify bounded and optional, with the exact module form as fallback.

Add finite-field reconstruction only for rational master/signature buckets that still cross the measured resource threshold.

Regression-test chunk-size and merge-order invariance, in addition to the existing complete NLO hard-function reconstruction test.

This preserves exact coefficients, assumptions, cuts, topology identity, BMHV distinctions and branch atoms, while attacking both dominant NNLO memory mechanisms rather than merely giving Simplify a different-sized expression.
