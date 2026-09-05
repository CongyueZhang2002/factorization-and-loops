# NNLO Hadronic Update

## Question

Continue the existing FACET discussion. Here are measured results from the exact hadronic-variable simplification study.

NLO UU: exact hadronic map -> complete-target rational merge -> Kira -> complete-master Simplify gives 6 masters in 48.55 s. Every final hard coefficient is free of xa, xb, zh and hadronic vectors after extracting the universal convolution prefactor.

NLO TT: the same ordering, with a final split only into the independent angular basis Cos[phi_a] Cos[phi_h] and Sin[phi_a] Sin[phi_h], gives 6 masters. The complete target stage shrinks 139,298,664 to 10,562,384 bytes in 52.0 s on 4 kernels; the complete master stage takes 30.4 s. Mixed angular structures vanish exactly. Every accepted transformation has an exact algebraic certificate and the final coefficients are free of xa, xb, zh.

NNLO UU: all 44,877 targets were catalogued. A stratified exact sample of 125 targets, selected by size, additive-term count, Kira fanout, pair-batch count, and median size, shrank 52,630,888 to 559,984 bytes in 30.45 s on 4 kernels with no timeouts or failures. The only noninteger fraction dependence consists of explicit Laurent half-powers xa^(n/2), xb^(n/2); there are no fraction-dependent logs, Gamma functions, or hypergeometric functions. A full 256-shard physical-target store is now running. Completed shards show zero timeouts/failures and roughly 20-30x expression-size reduction.

Please advise on a concrete exact complete-master algorithm under these facts. In particular:

1. Is the most robust representation a Laurent polynomial on the exponent lattice (1/2) Z^3 in xa, xb, zh, after a common rational denominator is formed separately for each master?
2. Give a precise fail-closed certificate for proving that a complete master coefficient factors as U(xa,xb,zh) H(s,t,u,Epsilon,...) where U is the expected universal convolution factor and H is fraction-independent.
3. How should we compare target-first compression against unmerged accumulation for a selected complete master without building both full 342-master stores? Please give a streaming algorithm for one master column.
4. Are there exact canonical transformations, beyond Cancel/Together on rational pieces and the historical Beta/Hypergeometric collection used only after master insertion, that are likely to improve the NNLO expressions without hiding fraction dependence?

Keep the answer at QFT/QCD analytic-calculation level, with implementable Mathematica details but not a software-engineering report.

## Pro response

The measured NLO and NNLO target results justify making certified complete-target compression the default pre-Kira transformation. It is an exact change of representation, so it cannot remove cancellations that would otherwise occur between different targets. The cancellation of x
a
	​

,x
b
	​

,z
h
	​

, however, should be certified only after all targets contributing to a given master have been accumulated.

The project contract requires an exact analytic function with explicit ϵ, endpoint, distributional, cut, branch, and BMHV information; fixed-kinematics values are checks rather than the calculation. 

AGENTS

 

AGENTS

 The corrected double-real basis contains 342 masters. 

BOUNDARY_FAMILY_INVENTORY

 

boundary_equivalence_draft

 

BOUNDARY_FAMILY_INVENTORY

1. Master representation in the momentum fractions

A Laurent expansion on

2
1
	​

Z
3

is the correct mathematical description, but the most robust implementation is to lift it to an ordinary integer exponent lattice.

In the physical chamber,

x
a
	​

>0,x
b
	​

>0,z
h
	​

>0,

introduce fixed positive variables

y
a
	​

=
x
a
	​

	​

,y
b
	​

=
x
b
	​

	​

,y
h
	​

=
z
h
	​

	​

.

Then every certified half-power becomes an integer power:

x
a
n/2
	​

=y
a
n
	​

,x
b
n/2
	​

=y
b
n
	​

,z
h
n/2
	​

=y
h
n
	​

,n∈Z.

The NNLO scan must fail if it encounters any other fraction-dependent noninteger object, such as

(ux
a
	​

+tx
b
	​

)
−ϵ
,log(ux
a
	​

+tx
b
	​

),Γ(x
a
	​

+ϵ).

Your current observation—that all noninteger fraction dependence consists only of explicit Laurent half-powers—places every pre-master coefficient in

K(y
a
	​

,y
b
	​

,y
h
	​

),

where

K=FracQ[s,t,u,ϵ,color variables,frozen fraction-independent analytic atoms].

Treating the frozen atoms as algebraically independent gives a sufficient exact equality test. A nonzero result in that formal ring can still be marked unresolved if an unimplemented identity between analytic atoms might exist.

Do not form a full common denominator in all variables

For master M
m
	​

, write each target contribution as

f
αm
	​

=R
αm
	​

C
α
	​

=
d
αm
(y)
	​

(y;θ)d
αm
(0)
	​

(θ)
n
αm
	​

(y;θ)
	​

,

where

y=(y
a
	​

,y
b
	​

,y
h
	​

)

and

FreeQ[d
αm
(0)
	​

,{y
a
	​

,y
b
	​

,y
h
	​

}]=True.

Here θ denotes s,t,u,ϵ, color variables, and the frozen analytic atoms.

Construct a common denominator only for the momentum-fraction dependence:

L
m
	​

(y;θ)=lcm
α:R
αm
	​


=0
	​

d
αm
(y)
	​

.

Do not place all fraction-independent denominators in s,t,u,ϵ over one denominator. Leave those inside the coefficients of the y-polynomial. This is the main protection against master-level expression growth.

The exact master is then

K
m
	​

=
L
m
	​

(y;θ)
N
m
	​

(y;θ)
	​

,

with

N
m
	​

=
α
∑
	​

d
αm
(0)
	​

n
αm
	​

(L
m
	​

/d
αm
(y)
	​

)
	​

.

Represent N
m
	​

 as a sparse coefficient map,

N
m
	​

=
ν∈Z
≥0
3
	​

∑
	​

n
m,ν
	​

(θ)y
a
ν
a
	​

	​

y
b
ν
b
	​

	​

y
h
ν
h
	​

	​

.

Any overall negative powers are stored as one separate Laurent shift vector rather than repeated in every term.

A suitable record is conceptually

Wolfram Language
<|
  "LaurentShift" -> {ra, rb, rh},
  "FractionDenominatorFactors" -> factorMultiset,
  "FractionDenominatorPolynomial" -> sparseYPolynomial,
  "NumeratorCoefficients" -> <|
    {na, nb, nh} -> exactThetaCoefficient,
    ...
  |>
|>

The denominator should remain factorized or stored as a sparse polynomial map. It need not be expanded into a large Plus.

2. Fail-closed certificate for the universal factor

Let the declared convolution factor be

U(x
a
	​

,x
b
	​

,z
h
	​

)=U
dist
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

)x
a
u
a
	​

/2
	​

x
b
u
b
	​

/2
	​

z
h
u
h
	​

/2
	​

.

Here U
dist
	​

 contains the exact PDF/FF product and any coupling factor that has already been certified common to all pair contributions. Its extraction is understood as a formal or meromorphic factorization, not pointwise division at zeros of a PDF or FF.

After the structural distribution factor has been removed, define

U
y
	​

(y)=y
a
u
a
	​

	​

y
b
u
b
	​

	​

y
h
u
h
	​

	​

.

The desired statement is

K
m
	​

(y;θ)=U
y
	​

(y)H
m
	​

(θ).

Using

K
m
	​

=
L
m
	​

N
m
	​

	​

,

this is equivalent to

N
m
	​

=H
m
	​

U
y
	​

L
m
	​

.

Choose one common monomial shift δ
m
	​

 so that both

N
m
	​

=y
δ
m
	​

N
m
	​


and

V
m
	​

=y
δ
m
	​

U
y
	​

L
m
	​


are ordinary polynomials in y
a
	​

,y
b
	​

,y
h
	​

. Write

N
m
	​

=
ν
∑
	​

n
ν
	​

y
ν
,V
m
	​

=
ν
∑
	​

v
ν
	​

y
ν
.

Choose an exponent ν
0
	​

 with

v
ν
0
	​

	​


=0.

A fail-closed exact certificate is

n
ν
	​

v
ν
0
	​

	​

−n
ν
0
	​

	​

v
ν
	​

=0for every ν∈keys(N
m
	​

)∪keys(V
m
	​

).
	​


When all these identities hold,

H
m
	​

=
v
ν
0
	​

	​

n
ν
0
	​

	​

	​


is exactly independent of x
a
	​

,x
b
	​

,z
h
	​

.

This is stronger and cheaper than constructing

K
m
	​

−UH
m
	​


as one complete expression.

Required conditions

The certificate is accepted only if:

Positive-root lift is certified

x
i
n/2
	​

=y
i
n
	​


is used only with x
i
	​

>0 and y
i
	​

=
x
i
	​

	​

>0.

All frozen atoms are fraction-free

Wolfram Language
FreeQ[atom, xa | xb | zh | ya | yb | yh]

must be True.

Kira coefficients are fraction-free

FreeQ[R
αm
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

}]=True.

Every denominator decomposition is certified

d
αm
	​

−d
αm
(y)
	​

d
αm
(0)
	​

=0.

Every common-denominator quotient is certified polynomial

L
m
	​

/d
αm
(y)
	​

∈K[y
a
	​

,y
b
	​

,y
h
	​

].

Every sparse polynomial map reconstructs its source exactly.

Every coefficient identity is exact
A timeout gives "Unresolved"; it is not accepted as zero and is not reported as inequality.

The structural factor is independently reconstructed

C
m
	​

=U
dist
	​

U
y
	​

H
m
	​

.
Mathematica form
Wolfram Language
certifyUniversalFactor[
    numeratorMap_Association,
    denominatorMap_Association,
    universalExponent_List,
    exactZeroFunction_
  ] := Module[
  {universalMap, keys, pivot, n0, v0, checks},

  universalMap = multiplySparsePolynomials[
    denominatorMap,
    <|universalExponent -> 1|>
  ];

  keys = Union[Keys[numeratorMap], Keys[universalMap]];

  pivot = FirstCase[
    keys,
    key_ /;
      ! TrueQ[
        exactZeroFunction[
          Lookup[universalMap, key, 0]
        ]
      ],
    Missing["NoPivot"]
  ];

  If[MissingQ[pivot],
    Return[Failure["ZeroUniversalPolynomial", <||>]]
  ];

  n0 = Lookup[numeratorMap, pivot, 0];
  v0 = Lookup[universalMap, pivot, 0];

  checks = AssociationMap[
    exactZeroFunction[
      Lookup[numeratorMap, #, 0] v0 -
      n0 Lookup[universalMap, #, 0]
    ] &,
    keys
  ];

  If[
    AllTrue[Values[checks], TrueQ],
    <|
      "Verified" -> True,
      "HardCoefficient" -> Cancel[n0/v0],
      "Checks" -> checks
    |>,
    <|
      "Verified" -> False,
      "Status" -> "UnresolvedOrNonzero",
      "Checks" -> checks
    |>
  ]
];

For a very large coefficient in K, exactZeroFunction should itself use numerator equality after exact cancellation, rather than a broad Simplify.

3. Streaming comparison for one complete master column

No additional 342-master store is required.

Choose one master M
m
∗
	​

	​

, preferably the one maximizing a deterministic estimate such as

α:R
αm
∗
	​

	​


=0
∑
	​

ByteCount(
C
α
	​

)

and the number of distinct fraction-dependent denominator factors.

Define its exact target set

T
m
∗
	​

	​

={α:R
αm
∗
	​

	​


=0}.

Run two independent streaming constructions.

Route T: target-first compression

For every α∈T
m
∗
	​

	​

:

read the complete target;

use the saved certified whole-target result 
C
α
	​

;

multiply by R
αm
∗
	​

	​

;

cancel only that local product;

lift x
i
n/2
	​

→y
i
n
	​

;

extract d
αm
∗
	​

(y)
	​

 and d
αm
∗
	​

(0)
	​

;

append the exact leaf to the m
∗
	​

 accumulator.

Route U: unmerged accumulation

For the same target α:

read all exact leaves that formed the complete target before its whole-target merge;

apply the same hadronic map, branch registry, and positive-root lift;

multiply each leaf by the same R
αm
∗
	​

	​

;

append every unmerged leaf to a separate m
∗
	​

 accumulator.

This route must include all contributions to each target and all targets in the master column. It is not a sampled or truncated master.

Use the same final representation

Construct

K
m
∗
	​

(T)
	​

=
L
T
	​

N
T
	​

	​

,K
m
∗
	​

(U)
	​

=
L
U
	​

N
U
	​

	​

,

as sparse y-polynomial maps. The denominators L
T
	​

 and L
U
	​

 need not be syntactically equal because target compression may cancel factors.

Compare them by the exact identity

N
T
	​

L
U
	​

−N
U
	​

L
T
	​

=0
	​


coefficient by coefficient in y
a
	​

,y
b
	​

,y
h
	​

.

In sparse form:

Wolfram Language
differenceMap = subtractSparsePolynomials[
  multiplySparsePolynomials[numT, denU],
  multiplySparsePolynomials[numU, denT]
];

routeEquality =
  AllTrue[
    Values[differenceMap],
    exactThetaZeroQ
  ];

Then independently run the universal-factor certificate on both routes and require

H
m
∗
	​

(T)
	​

=H
m
∗
	​

(U)
	​


by exact cross multiplication in K.

Measurements to retain

For each route record:

bytes read;

bytes written;

wall time;

peak RSS;

number of target records;

number of input leaves;

number of distinct y-denominator factors;

maximum polynomial degree in y
a
	​

,y
b
	​

,y
h
	​

;

number and maximum size of coefficient buckets;

timeouts and unchanged fallbacks;

exact route-equality status;

universal-factor certificate status.

Given the 20–30-fold completed-shard compression and the 125-target sample reduction, target-first is strongly favored. The one-column comparison should quantify the gain and verify that the compressed representation remains favorable after Kira fan-out.

4. Additional exact canonical transformations

The current measurements do not justify broad special-function transformations at the target stage. The NNLO pre-master grammar is already unusually favorable: rational functions and explicit half-powers only.

The following exact transformations are likely useful.

Positive-root lifting

Use

x
i
n/2
	​

↦y
i
n
	​


under x
i
	​

>0. This removes all fractional exponents from the computational ring and makes CoefficientRules, polynomial gcds, and denominator divisibility exact and direct.

Do not use PowerExpand.

Primitive denominator normalization

For each y-dependent denominator polynomial q(y;θ), normalize it up to multiplication by a nonzero element of K. Choose one fixed monomial order and divide by its leading coefficient in y:

q⟼
LC
y
	​

(q)
q
	​

.

The removed leading coefficient belongs in d
(0)
. This ensures that proportional denominator polynomials receive identical keys.

Polynomial gcd/lcm instead of mandatory full factorization

A common denominator can be built recursively as

L
new
	​

=
gcd
K[y]
	​

(L
old
	​

,d)
L
old
	​

d
	​

.

This can be cheaper and more robust than completely factoring every denominator.

If the polynomial gcd cannot be established within a bound, the fail-closed fallback is

L
new
	​

=L
old
	​

d.

That is a valid common multiple, although not minimal.

Square-free denominator decomposition

Exact square-free decomposition can identify repeated factors without requiring a full irreducible factorization:

d(y)=
j
∏
	​

q
j
	​

(y)
j
.

This is useful for predicting denominator powers and master-column complexity.

Sparse polynomial arithmetic in the fraction variables

Once L
m
	​

 has been formed, do not call Expand on a large master expression. Represent every polynomial as

Wolfram Language
<|{na, nb, nh} -> coefficient, ...|>

and use:

Merge[..., Total] for addition;

exponent-vector convolution for multiplication;

coefficientwise exact cancellation in K.

This is exact and exposes fraction independence directly.

Exact reduction by declared kinematic relations

If the analytic context contains polynomial relations among the remaining kinematic variables, reduce numerator and denominator polynomials with one fixed PolynomialReduce basis before comparing or factoring them.

This is useful only for declared exact relations. Inequalities such as s>0, t<0, and u<0 are not polynomial reduction rules.

Fixed color basis

Reduce every color coefficient to one exact basis before the final K-arithmetic. This can expose cancellations without interacting with the fraction variables.

Bounded final simplification after fraction elimination

Once

H
m
	​

(s,t,u,ϵ,…)

has been certified fraction-independent and is much smaller, apply a bounded

Wolfram Language
Simplify[H_m, Assumptions -> physicalAssumptions]

and accept the changed result only after an exact assumption-aware equality check.

This is where the NLO UU and TT measurements show that Simplify becomes effective.

Transformations not justified at this stage

Do not add as production defaults:

global FunctionExpand;

Gamma reflection or duplication;

Euler or Pfaff hypergeometric transformations;

contiguous hypergeometric relations;

global Apart;

PowerExpand;

a global Together over a complete master coefficient in all variables;

pre-Together separation by syntactic Gamma, Beta, or hypergeometric signatures.

The historical Beta–hypergeometric collection remains useful after exact master functions have been inserted, when those functions actually occur. It should not drive the pre-master NNLO coefficient representation.

Recommended next NNLO experiment

Use the completed physical-target shards to select three complete master columns:

largest predicted byte input;

largest number of distinct fraction-denominator polynomials;

median column.

For each, perform the Route T/Route U comparison above. The acceptance criteria are:

	​

N
T
	​

L
U
	​

−N
U
	​

L
T
	​

=0,
K
m
	​

=UH
m
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

,y
a
	​

,y
b
	​

,y
h
	​

}]=True,
	​


with every changed local object carrying an exact certificate and every timeout recorded as unresolved with the original exact input retained.

If target-first reduces disk traffic and coefficient-map sizes materially on these complete columns—as the NLO and 125-target results predict—then the full NNLO sequence should be:

certified complete targets→sparse Kira fan-out→per-master positive-root rational representation→coefficientwise universal-factor certificate→bounded fraction-free cleanup.
	​
