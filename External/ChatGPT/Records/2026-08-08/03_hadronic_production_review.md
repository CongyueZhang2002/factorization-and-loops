# Hadronic Production Review

## Question

Continue the same FACET coefficient-normalization discussion. I am attaching the current production Reduction.wl, not a summary of that source.

New exact observations from the 100-pair NLO UU calculation:

1. The existing production reducer never applies AnalyticContext["HadronicVariables"] to target or master coefficients; it uses only AnalyticContext["Assumptions"].
2. The historical pp-hX real-emission notebook did more than Simplify: it identified Beta/Hypergeometric2F1 objects as a functional basis, collected by that basis, and applied Factor[Cancel[Together[#]]] to each collected coefficient before an outer Simplify.
3. Applying the card's exact hadronic coordinates to the 116 summed target coefficients, then simplifying additive terms, then applying Kira, then simplifying the seven master coefficients is the best measured robust order.
4. After branch-certified half-integer radical rules, every master contains the exact common factor alpha_s^3 D1(zh) f1(xa) f1(xb)/(xa xb zh^2), and the quotient is exactly independent of xa, xb, zh.
5. Dividing that factor term by term and Simplify reduced 1.04 MB to 0.283 MB in 5.88 s. FullSimplify afterward saved only another 9 percent but cost 32.4 s.
6. The existing structural common-factor finder sees alpha_s^3 D1(zh) f1(xa) f1(xb)/zh^2 but misses 1/(xa xb), because equivalent square-root forms obscure it.
7. A generic proposed algorithm is: certify and canonicalize only half-integer powers whose bases can be decomposed into monomials of individually positive variables; extract the structural common factor; determine the missing Laurent monomial in the card's momentum fractions from the smallest nonzero coefficient; divide every coefficient by the candidate; simplify additive terms; require every quotient to be exactly free of all momentum fractions; otherwise stop with an error. No PowerExpand and no global Together on a large coefficient.
8. The current TT card exposed a separate issue: SetDistributionZero deletes a distribution head globally. TT needs h1(xa) f1(xb) H1(zh), so f1(xa) must be removable while f1(xb) remains. I plan to let SetDistributionZero accept either a head or an exact distribution object such as f1[xa], preserving the original notebook's leg distinction.

Please review the attached Reduction.wl and answer concretely:

- Is the proposed automatic Laurent-monomial certificate exact and sufficiently general for NLO UU/TT and NNLO UU? State any missing mathematical condition.
- Where precisely should the hadronic coordinate map and branch-certified radical normalization enter the current functions?
- Should the universal hard-factor normalization be derived algebraically as proposed or declared from the collinear measure in the card? Compare the failure modes.
- Is the TT leg-specific distribution correction physically and algebraically correct, or should the correlators retain an explicit leg identifier instead?
- Identify any exact simplification from the historical Collect-by-special-function method worth retaining before master-integral evaluation. Do not recommend a global Together or numerical reconstruction.

The required result is an exact analytic coefficient with explicit physical branches. Fixed-point numerics are checks only.

## Pro response

Assessment

The proposed Laurent-monomial procedure is exact as a certificate, provided the candidate monomial is treated only as a proposal and acceptance requires exact reconstruction and complete removal of the declared momentum fractions. It is not, by itself, a complete discovery algorithm for every possible coefficient grammar.

The current Reduction.wl does not use AnalyticContext["HadronicVariables"]; the exact symbol does not occur in the file. 

Reduction

 Target normalization and master normalization receive only AnalyticContext["Assumptions"]. 

Reduction +1

 Moreover, the present normalizer is essentially termwise Simplify: exactCoefficientNormalize is one call to Simplify, while parallelNormalizeCoefficients splits each coefficient into additive terms, simplifies each term, and adds them back. 

Reduction +1

The measured NLO order should therefore become the production order:

	​

sum equal target GLIs
⟶apply the exact hadronic map to each complete target coefficient
⟶canonicalize certified radicals
⟶simplify additive terms
⟶collect identical analytic-function structures
⟶apply the sparse Kira map
⟶repeat the bounded cleanup on each complete master coefficient
⟶extract and certify the universal hard factor.
	​

	​


This remains an exact analytic calculation. The project requirement that numerical values serve only as checks is unchanged. 

AGENTS

1. Exact status of the automatic Laurent-monomial certificate

Let the complete nonzero master coefficients, after the structural PDF/FF, coupling, color, and spin objects have been put in fixed bases, be

C
m
	​

(x
a
	​

,x
b
	​

,z
h
	​

;s,t,u,ϵ),m∈M
nz
	​

.

The intended factorization is

C
m
	​

=F
hard
	​

(x
a
	​

,x
b
	​

,z
h
	​

)H
m
	​

(s,t,u,ϵ,color,spin),

with, for NLO UU,

F
hard
UU
	​

=
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

D
1
	​

(z
h
	​

)f
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

)
	​

.

A proposed factor F
cand
	​

 is certified if and only if all of the following hold:

C
m
	​

=F
cand
	​

H
m
	​

exactly for every m∈M
nz
	​

,
FreeQ[H
m
	​

,{x
a
	​

,x
b
	​

,z
h
	​

}]=True,

and every branch-sensitive replacement used to construct F
cand
	​

 has been proved under the physical assumptions.

Under those conditions, the result is exact even if F
cand
	​

 was initially guessed from one small coefficient. The proposal mechanism is heuristic; the acceptance criterion is not.

Missing mathematical conditions
The momentum fractions must be algebraically independent variables

The Laurent valuation

v(C)=(v
x
a
	​

	​

(C),v
x
b
	​

	​

(C),v
z
h
	​

	​

(C))

is unambiguous only when no declared algebraic relation identifies different monomials in x
a
	​

,x
b
	​

,z
h
	​

. This is satisfied by the current partonic parametrization, where the fractions are independent variables constrained only by

0<x
a
	​

,x
b
	​

,z
h
	​

<1.

If a future card introduces a relation among fractions, ordinary componentwise Laurent valuation is no longer canonical.

Valuation must be taken after reduction to a fixed analytic basis

For a rational kernel R=P/Q, with P and Q coprime,

v
x
	​

(R)=ord
x=0
	​

P−ord
x=0
	​

Q.

But a full coefficient may contain independent color, spin, PDF/FF, Gamma-function, or hypergeometric structures. These must first be treated as exact basis objects. The common momentum-fraction valuation must hold for every nonzero basis coefficient, not merely for the unseparated sum.

For TT, this means first choosing a fixed azimuthal or transverse-tensor basis. Otherwise a fraction-dependent redefinition of the tensor basis can make the apparent Laurent monomial nonunique.

Half-integer normalization requires strictly positive generators

A safe radical rewrite has the form

B
n/2
=(c
i=1
∏
r
	​

p
i
a
i
	​

	​

)
n/2
,

where

c>0,p
i
	​

>0

throughout the open physical chamber, and all a
i
	​

,n∈Z. The identity then uses the positive real branches of the p
i
	​

.

For the present process, useful positive generators include

s,−t,−u,x
a
	​

,x
b
	​

,z
h
	​

.

Thus

s
tu
	​

	​

=
s
(−t)(−u)
	​

	​


is safe, whereas splitting it as 
t
	​

u
	​

/
s
	​

 is not.

A composite positive expression such as

Δ
h
	​

:=−(x
b
	​

t+x
a
	​

u)>0

may be used to certify

Δ
h
2
	​

	​

=Δ
h
	​

,

but Δ
h
	​

 must not be treated as an independent atom during the final FreeQ test. Its dependence on x
a
	​

,x
b
	​

 must be restored.

The candidate coefficient must be nonzero exactly

Zero coefficients have no Laurent valuation. The coefficient used to propose the monomial must be proved nonzero after the exact termwise and functional-basis cleanup.

All quotients must be checked, including the remainder

The current code includes a possible GLI-free remainder in the common-factor extraction. That remainder must either vanish exactly or satisfy the same universal factorization. It cannot be silently omitted.

The factorization is a meromorphic identity

PDFs and FFs can vanish at isolated physical points. Factoring

f
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

)D
1
	​

(z
h
	​

)

should therefore be interpreted as an exact formal or meromorphic factorization of the symbolic coefficient, not as a claim that division is pointwise valid at every zero of those functions.

Discovery versus certification

Using the smallest nonzero coefficient is acceptable as a cheap proposal:

v
proposal
	​

=v(C
m
⋆
	​

	​

),m
⋆
	​

=arg
m∈M
nz
	​

min
	​

ByteCount(C
m
	​

).

It is not a canonical discovery rule. A more deterministic proposal is:

compute the valuation of several smallest nonzero basis coefficients;

require them to agree;

use the resulting monomial;

divide every coefficient;

require every quotient to be exactly fraction-free;

reconstruct every original coefficient exactly.

If the proposed exponent fails on any coefficient, stop. Do not silently choose a weaker factor.

2. Exact insertion points in Reduction.wl

The current source first extracts result["Integrand"], maps equivalent GLIs, multiplies the sparse coefficient map by result["PreFactor"], and then sums all pair contributions into targetTerms. 

Reduction

 This is the correct place to retain pair-local expressions without hadronic expansion.

Target level

Insert the hadronic reduction after the complete targetParts association has been constructed and its target keys have been checked against the Kira target set, but before

Wolfram Language
Print["Simplifying target coefficients"];
normalizeLinearCoefficientParts[...]

That is, between the current target-set validation and the current normalization call. The relevant existing call currently passes only assumptions. 

Reduction

The patch should have the form

Wolfram Language
targetParts = canonicalizeHadronicLinearParts[
  targetParts,
  data["AnalyticContext"]
];

If[FailureQ[targetParts],
  ibpFail[
    "target hadronic reduction",
    "the exact hadronic map or radical normalization failed"
  ]
];

normalizedTargetParts = normalizeLinearCoefficientParts[
  targetParts,
  data["AnalyticContext"]
];

The helper must map coefficients and the remainder only; it must not act on GLI keys:

Wolfram Language
canonicalizeHadronicLinearParts[
    parts_Association,
    context_Association
  ] := Module[{mapped},

  mapped = linearMapCoefficients[
    parts,
    canonicalizeHadronicCoefficient[#, context] &
  ];

  If[
    FailureQ[mapped] ||
      ! linearIntegralSumStructureQ[mapped],
    Failure["HadronicCoefficientReduction", <||>],
    mapped
  ]
];

The coefficient-level helper should apply, in this order,

Wolfram Language
canonicalizeHadronicCoefficient[
    expression_,
    context_Association
  ] := Module[
  {hadronic, assumptions, result},

  hadronic = Lookup[
    context,
    "HadronicVariables",
    Missing["NotAvailable"]
  ];
  assumptions = context["Assumptions"];

  If[MissingQ[hadronic],
    Return[Failure["MissingHadronicVariables", <||>]]
  ];

  result = applyExactHadronicCoordinateMap[
    expression,
    hadronic
  ];

  result = applyCertifiedHalfIntegerRules[
    result,
    hadronic,
    assumptions
  ];

  If[
    FailureQ[result] ||
      ! exactDataQ[result] ||
      ! hadronicCoefficientFormQ[result, hadronic],
    Failure["InvalidHadronicCoefficient", <||>],
    result
  ]
];

applyExactHadronicCoordinateMap should be owned by the process/kinematics layer, not reimplemented in Reduction.wl. Reduction.wl should only call the context-aware canonicalizer.

Master level

After

Wolfram Language
physicalParts = linearComposeReduction[
  targetParts,
  sparseReduction
];

and after both dimension substitutions, but before the integrated-momentum checks and before normalizeMasterCoefficients, apply the same idempotent canonicalization:

Wolfram Language
physicalParts = linearMapCoefficients[
  physicalParts,
  Function[coefficient,
    coefficient /. $dimensionRule
  ]
];

physicalParts = canonicalizeHadronicLinearParts[
  physicalParts,
  data["AnalyticContext"]
];

If[FailureQ[physicalParts],
  ibpFail[
    "master hadronic reduction",
    "master coefficients could not be reduced to the declared hadronic basis"
  ]
];

The current source applies the Kira map, replaces D, and immediately proceeds to momentum and dimension checks. 

Reduction

 This is the precise second insertion point.

Kira coefficients are rational in D,s,t,u,…, so they should not introduce new hadronic radicals. Reapplying the canonicalizer is nevertheless useful as an idempotence and fail-closed check after different targets have been added.

Change the normalization function signatures

Currently,

Wolfram Language
normalizeLinearCoefficientParts[parts, assumptions]
normalizeMasterCoefficients[parts, label, assumptions]

should become

Wolfram Language
normalizeLinearCoefficientParts[parts, context]
normalizeMasterCoefficients[parts, label, context]

with

Wolfram Language
assumptions = context["Assumptions"];

inside. This prevents future code from again dropping the hadronic branch record while retaining only inequalities.

3. Complete-coefficient cleanup inside the worker

The current worker computes

Wolfram Language
Total[
  Simplify[term, Assumptions -> assumptions] & /@
    additiveTerms[coefficient]
]

and stops there. 

Reduction

 Preserve that fast termwise step, then apply a bounded cleanup to the complete sum:

Wolfram Language
normalizeOneCompleteCoefficient[
    coefficient_,
    context_Association
  ] := Module[
  {assumptions, canonical, termwise, collected},

  assumptions = context["Assumptions"];

  canonical = canonicalizeHadronicCoefficient[
    coefficient,
    context
  ];
  If[FailureQ[canonical], Return[$Failed]];

  termwise = Total[
    Simplify[
      #,
      Assumptions -> assumptions
    ] & /@ additiveTerms[canonical]
  ];

  collected = collectExactFunctionalBasis[
    termwise,
    context
  ];

  If[
    FailureQ[collected] || ! exactDataQ[collected],
    $Failed,
    collected
  ]
];

Then parallelNormalizeCoefficients should submit this function instead of hard-coding Simplify over terms.

A timeout may return the exact canonical input expression, as the current implementation already does. That remains mathematically safe.

4. Declared hard normalization versus algebraic inference

The strongest production design is:

declare the expected hard normalization from factorization, then derive and verify it algebraically.
	​


Do not use only one of these approaches.

What should be declared

The process card or normalized process record should contain a structured statement such as

Wolfram Language
"HardCoefficientNormalization" -> <|
  "CouplingFactor" -> FeynFacet`\[Alpha]s^3,
  "DistributionFactor" ->
    FeynFacet`D1[zh] *
    FeynFacet`f1[xa] *
    FeynFacet`f1[xb],
  "MomentumFractionPowers" -> <|
    xa -> -1,
    xb -> -1,
    zh -> -2
  |>
|>

For TT, the distribution factor would be

Wolfram Language
FeynFacet`h1[xa] *
FeynFacet`f1[xb] *
FeynFacet`H1[zh]

together with the same or separately declared fraction powers appropriate to
the chosen projector normalization.

The coupling power and collinear Jacobian powers are consequences of the
factorization formula, measure, flux, and projector conventions. They are
physics input, not something an algebraic reducer should discover anew.

What the reducer should derive

From the actual complete target or master coefficients, independently derive:

the common structural coupling and distribution product;

the fraction valuation proposal;

the exact fraction-free quotients;

exact reconstruction.

Then require exact agreement with the declaration.

Failure modes of inference alone

Algebraic inference cannot detect a systematic normalization error shared by
every coefficient. For example, if every coefficient erroneously contains

x
a
2
	​

x
b
	​

z
h
2
	​

1
	​


instead of

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

1
	​

,

the coefficients still possess a perfectly consistent common monomial.
Inference alone would certify the wrong hard-function convention.

Other failure modes are:

a projector normalization error common to all diagrams;

an incorrect fragmentation Jacobian common to all channels;

an accidentally omitted flux factor;

a vanishing or unusually simple coefficient chosen as the proposal;

channel-dependent distribution products being merged before projection.

Failure modes of declaration alone

A declared factor can become stale when:

the density-projector convention changes;

an incoming or outgoing leg is reordered;

the perturbative order changes;

the TT tensor normalization changes;

the fragmentation-variable convention changes.

Therefore the declared factor must never be divided out without exact checks.

Recommended acceptance criterion

Let F
declared
	​

 be the process-card factor. Require, for every
nonzero master coefficient,

Q
m
	​

=Simplify
exact
	​

(
F
declared
	​

C
m
	​

	​

),
FreeQ[Q
m
	​

,{x
a
	​

,x
b
	​

,z
h
	​

}]=True,

and

C
m
	​

−F
declared
	​

Q
m
	​

=0

as an exact identity in the declared analytic basis.

Also compare the independently derived valuation with

(−1,−1,−2).

A discrepancy should stop the calculation.

5. How to add the Laurent monomial to the current common-factor logic

The current code first applies structuralCommonAdditiveFactor over all
nonzero coefficients and the remainder, then extracts a local structural
factor from each coefficient. 

Reduction

 This is why it finds the literal factor

z
h
2
	​

α
s
3
	​

D
1
	​

(z
h
	​

)f
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

)
	​


but misses 1/(x
a
	​

x
b
	​

) when the latter is distributed among equivalent
radicals.

Replace the direct call

Wolfram Language
factorResult =
  structuralCommonAdditiveFactor[expressionsForFactor];

by a certified two-step extractor:

Wolfram Language
factorResult = certifiedHardCommonFactor[
  expressionsForFactor,
  context
];

with the conceptual result

Wolfram Language
<|
  "Factor" -> structuralFactor * laurentMonomial,
  "Quotients" -> quotientExpressions,
  "Certificate" -> certificate
|>

The algorithm should be:

Wolfram Language
certifiedHardCommonFactor[
    expressions_List,
    context_Association
  ] := Module[
  {
    structuralFactor, reduced,
    declared, fractions, proposalExpression,
    valuation, laurentMonomial, quotients, checks
  },

  {structuralFactor, reduced} =
    structuralCommonAdditiveFactor[expressions];

  declared = context[
    "HadronicVariables",
    "HardCoefficientNormalization"
  ];

  fractions = Keys[
    declared["MomentumFractionPowers"]
  ];

  proposalExpression = First @ SortBy[
    Select[reduced, ! exactZeroQ[#] &],
    ByteCount
  ];

  valuation = proposeFractionValuation[
    proposalExpression,
    fractions,
    context
  ];

  laurentMonomial = Times @@ Map[
    Power[#, Lookup[valuation, #]] &,
    fractions
  ];

  quotients = exactTermwiseNormalize[
    #/laurentMonomial,
    context
  ] & /@ reduced;

  checks = And[
    AllTrue[
      quotients,
      FreeQ[#, Alternatives @@ fractions] &
    ],
    exactCoefficientListEqualQ[
      reduced,
      laurentMonomial quotients,
      context
    ],
    valuation ===
      declared["MomentumFractionPowers"]
  ];

  If[
    ! TrueQ[checks],
    Failure["HardFactorCertificateFailed", <||>],
    <|
      "Factor" -> structuralFactor laurentMonomial,
      "Quotients" -> quotients,
      "Certificate" -> <|
        "DerivedMomentumFractionPowers" -> valuation,
        "DeclaredMomentumFractionPowers" ->
          declared["MomentumFractionPowers"]
      |>
    |>
  ]
];

The proposal need not be mathematically canonical because every quotient and
the complete reconstruction are checked. For deterministic artifacts, select
the proposal coefficient by a fixed ordering such as {ByteCount, InputForm}.

The universal factor should be folded into the existing overall
"PreFactor". The current per-master "PreFactor" values should remain as a
second level, as required by the artifact format.

6. Reconstruction checks need strengthening

The current final check compares

Wolfram Language
coefficientResult["Expression"]

with a second reconstruction made from the fields returned by the same
normalizeMasterCoefficients call. 

Reduction

 This
checks the storage assembly, but it does not independently prove that a new
hadronic or radical canonicalization preserved the input physicalParts.

Add two coefficient-wise checks:

Target normalization

For every target G
α
	​

,

C
α
before
	​

=C
α
after
	​


under the certified branch rules.

Master normalization

For every master M
m
	​

,

K
m
before
	​

=F
common
	​

F
m
	​

K
m
	​

.

Perform these checks after separating exact functional, distribution, color,
spin, and radical structures. Within each identical structure, compare the
rational kernels exactly. This avoids a global Together.

A suitable abstract checker is

Wolfram Language
exactCoefficientEqualQ[
    first_,
    second_,
    context_Association
  ] := Module[
  {difference, basisMap},

  difference = first - second;

  basisMap = coefficientBasisMap[
    difference,
    context
  ];

  AssociationQ[basisMap] &&
    AllTrue[
      Values[basisMap],
      exactRationalZeroQ[#, context] &
    ]
];

Every radical rule included in the context should also carry its proof
condition:

Wolfram Language
TrueQ @ FullSimplify[
  lhs == rhs,
  Assumptions -> context["Assumptions"]
]

No PowerExpand is admissible.

7. TT leg-specific distribution removal

Allowing an exact object such as

Wolfram Language
FeynFacet`f1[xa]

in SetDistributionZero is physically and algebraically correct provided
that each leg has a unique momentum-fraction symbol. Under the current
cards,

f
1
	​

(x
a
	​

)andf
1
	​

(x
b
	​

)

are distinct exact objects, so setting only f
1
	​

(x
a
	​

) to zero preserves
the unpolarized distribution of the other incoming leg.

However, the most robust long-term design is not to change the physical
distribution function to something like

f
1
	​

(leg,x).

The leg label is not an argument of the universal PDF. It belongs to the
factorization record describing which external leg the correlator is attached
to.

Recommended representation

Apply the zero selection while constructing each leg’s density projector:

Wolfram Language
"DistributionSelection" -> {
  <|
    "Leg" -> <|"Side" -> "Incoming", "Index" -> 1|>,
    "Zero" -> {FeynFacet`f1}
  |>
}

or equivalently identify the leg by its parton momentum:

Wolfram Language
<|
  "LegMomentum" -> ka,
  "Zero" -> {FeynFacet`f1}
|>

Then the incoming-a correlator omits f
1
	​

(x
a
	​

), while the
incoming-b correlator retains f
1
	​

(x
b
	​

).

This is preferable to a global replacement after all correlators have been
multiplied.

Backward-compatible minimal correction

Retain both forms:

a symbol such as f1 means “set this distribution head to zero on every
leg,” preserving old cards;

an exact object such as f1[xa] means “set only this exact distribution
contribution to zero.”

The input validator should reject ambiguous objects. In particular, exact
object selection requires:

a declared distribution head;

an argument equal to a declared leg fraction;

exactly one matching leg.

If two legs use the same fraction symbol, exact-object selection must fail and
require a leg selector.

Thus the planned correction is valid, but a leg-scoped projector selection is
the more durable representation. No explicit leg argument should be added to
the mathematical PDF or FF itself.

8. Historical collection by Beta and hypergeometric functions

The historical method contains one exact simplification that is worth
retaining:

C=
λ
∑
	​

F
λ
	​

R
λ
	​

,

where F
λ
	​

 is an exact branch-sensitive function object such
as

B(a,b),
2
	​

F
1
	​

(a,b;c;z),Γ(a),logz,Li
n
	​

(z),z
a+bϵ
,

and only the rational coefficient R
λ
	​

 is algebraically normalized.

This is exact because the special functions are not transformed. The method
does not require proving that the F
λ
	​

 are analytically
independent; it merely groups structurally identical objects.

Safe retained operation

After hadronic substitution and termwise simplification, perform

Wolfram Language
basis = exactFunctionalBasis[coefficient];

collected = Collect[
  coefficient,
  basis,
  boundedRationalCoefficientNormalize
];

where, for a sufficiently small collected coefficient,

Wolfram Language
boundedRationalCoefficientNormalize[r_] :=
  Factor[Cancel[Together[r]]];

For a larger coefficient, use:

exact equal-denominator buckets;

pairwise gcd-aware merging;

or Cancel without forcing one global denominator.

The historical

Wolfram Language
Factor[Cancel[Together[#]]]

is therefore appropriate per collected rational coefficient, not on the
full master coefficient.

Required restrictions

Before collecting:

canonicalize function arguments only with exact branch-certified rules;

do not use general hypergeometric transformations;

do not use FunctionExpand indiscriminately;

keep noninteger powers inert;

keep PDFs, FFs, distributions, color tensors, azimuthal tensors, and BMHV
structures in the same exact basis map;

reject unresolved FeynCalc objects containing loop or phase-space momenta.

The historical outer Simplify should be replaced by the measured cheaper
termwise cleanup or made bounded. Your result that FullSimplify saved only
about 9% after costing 32.4 s does not justify making it a production
stage.

Recommended final sequence

For every complete summed target coefficient:

	​

exact hadronic-coordinate substitution
→certified half-integer radical canonicalization
→termwise Simplify
→collection by exact analytic-function and tensor structures
→local rational normalization.
	​

	​


After sparse Kira composition, repeat the same cleanup on each complete
master coefficient. Then:

extract the literal structural coupling/PDF/FF factor;

propose the missing momentum-fraction Laurent monomial;

compare it with the factor declared by the process card;

divide every coefficient;

simplify additive terms;

require every quotient to be exactly free of x
a
	​

,x
b
	​

,z
h
	​

;

verify coefficient-wise exact reconstruction;

include the certified universal factor in the overall PreFactor;

retain the separate local factor for every master.

That gives the required exact hard coefficients

C
m
	​

=
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

D
1
	​

(z
h
	​

)f
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

)
	​

H
m
	​

(s,t,u,ϵ,color)

for UU, and the corresponding

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

factor with the declared physical azimuthal structures for TT, without
branch-oblivious radical transformations or a global common denominator.

## Sources sent to Pro

- Original source reference: `../../../FeynFacet/Private/Reduction.wl` (not archived with this exchange)
