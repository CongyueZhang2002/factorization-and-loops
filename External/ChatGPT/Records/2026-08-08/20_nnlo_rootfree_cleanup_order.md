# NNLO Rootfree Cleanup Order

## Question

The entrywise subdivision resolved every remaining shard exactly.

Measured final certificate:
- 256 shards.
- 38,400 exact denominator entries representing 38,460 original target-to-master leaves.
- Three representative masters with leaf counts 1, 93, and 38,366.
- 768 master-shard coefficients.
- 246 shards certified as whole shard/master fractions.
- The ten formerly difficult shards were split into 1,500 exact denominator-entry certificates; all 1,500 carried the same universal factor. Their eight-kernel wall time was 32.30 s.
- An independent eight-kernel audit reread every source and output file, checked source/output hashes, exactness, absence of xa, xb, zh and positive-root variables, distribution stripping, source-entry counts, leaf counts, and coefficient hashes. It returned Verified -> True in 51.59 s.
- The 256 output records occupy 817,748,468 serialized bytes.

Thus the exact fraction step is closed. For each selected master m we now have root-free exact shard coefficients H_(q,m), and need H_m = Sum_q H_(q,m). The coefficients contain rational functions of physical invariants and exact inert Gamma/log/power/BMHV atoms. We must preserve branches and exactness.

Please advise on the most efficient exact cleanup ordering, now focusing only on the root-free H_(q,m):

1. Apply bounded cleanup to each H_(q,m) independently, then use balanced addition?
2. Group by exact analytic signature first, accumulate rational coefficients across shards, then simplify each signature coefficient?
3. Perform balanced raw addition first, with cleanup only at bounded intermediate tree nodes?
4. What small set of measured benchmarks should decide among these orderings without attempting a full 818 MB reconstruction for every candidate?

The NLO measurements favored target-first cleanup and a bounded final master cleanup. For NNLO, do not suggest numerical fitting or PowerExpand. Give a concrete exact benchmark design and acceptance criteria for expression size, time, equality, and branch safety.

## Pro response

The next step should be a hybrid of options 1 and 2:

	​

H
q,m
	​

cheap certified local cleanup
	​

σ
∑
	​

r
q,m,σ
	​

A
σ
	​

stream over q
	​

H
m
	​

=
σ
∑
	​

(
q
∑
	​

r
q,m,σ
	​

)A
σ
	​

balanced rational cleanup per σ
	​

σ
∑
	​

R
m,σ
	​

A
σ
	​

one bounded final cleanup
	​

H
m
final
	​

.
	​

	​


A raw balanced addition of the complete H
q,m
	​

 should be retained as a benchmark and as a fallback for expressions that cannot be decomposed into the chosen analytic basis. It should not be the primary production representation.

The calculation must continue to return exact functions with explicit ϵ, endpoint, distributional, branch, cut, causal, and BMHV information; numerical values remain checks only. 

AGENTS

 

AGENTS

 The 342-master NNLO basis is exact, but it does not alter this coefficient-level algebraic requirement. 

BOUNDARY_FAMILY_INVENTORY

 

BOUNDARY_FAMILY_INVENTORY

 

boundary_equivalence_draft

1. Why independent shard cleanup alone is not sufficient

For fixed master m, the certified result is

H
m
	​

=
q=1
∑
256
	​

H
q,m
	​

,

with every H
q,m
	​

 already independent of

x
a
	​

, x
b
	​

, z
h
	​

, y
a
	​

, y
b
	​

, y
h
	​

.

Applying bounded cleanup separately to every H
q,m
	​

 is exact if every changed shard expression is certified equal to its input. It is useful because it reduces disk traffic and the sizes entering later merges.

It is not sufficient as the only cleanup because cancellations can occur between different shards:

H
q
1
	​

,m
	​

+H
q
2
	​

,m
	​

.

In particular, separately simplified representations may retain rational denominators or analytic structures that disappear only in the complete coefficient. The NLO target-first results already show the importance of allowing exact cancellation after aggregation.

Therefore the shard cleanup should be deliberately limited:

apply only the fixed branch-certified rewrite registry;

canonicalize the declared color and BMHV basis;

cancel individual rational terms;

optionally run a bounded whole-shard rational merge only when the shard is below a size threshold;

accept a changed expression only when an exact frozen-ring identity is established and the serialized size does not increase.

Do not run unrestricted Simplify independently on all 768 shard coefficients.

2. Exact master-wide analytic basis

After one globally fixed canonicalization, write each shard coefficient as

H
q,m
	​

=
σ∈Σ
m
	​

∑
	​

r
q,m,σ
	​

(s,t,u,ϵ,…)A
σ
	​

.

Here:

r
q,m,σ
	​

 is an exact rational function in the declared algebraic variables;

A
σ
	​

 is an exact product of canonical analytic or tensor objects.

A useful division is:

Rational coefficient variables

Keep in r
q,m,σ
	​

:

s,t,u,ϵ,

together with commuting color invariants such as

N
c
	​

,C
F
	​

,C
A
	​

,

when they have already been reduced to one declared algebraic basis.

Any exact polynomial relations among those variables must be imposed before coefficient comparison.

Analytic and tensor factors

Place in A
σ
	​

:

Γ-functions;

Beta functions;

Pochhammer symbols;

hypergeometric functions;

logarithms and polylogarithms;

zeta values when they are being treated as basis elements rather than rational-ring constants;

every noninteger power, including its complete base and exponent;

canonical BMHV tensor structures;

any noncommuting color tensor;

any fixed physical angular or spin structure.

For example,

Γ(1−ϵ)
2
log(
s
−t
	​

)(−u)
−2ϵ
T
BMHV
	​


is one analytic signature unless a registered exact relation decomposes it into a chosen basis.

Canonicalization before signatures

Use only one fixed, exact rewrite direction. Examples include:

B(a,b)⟶
Γ(a+b)
Γ(a)Γ(b)
	​


if Gamma functions are the selected basis, or the reverse direction if Beta functions are selected. Do not use both directions.

Integer Gamma shifts may be canonicalized through

Γ(z+n)=(z)
n
	​

Γ(z),n∈Z,

provided that the equality is interpreted meromorphically and the chosen direction is fixed globally.

Do not use:

PowerExpand;

logarithm expansion or combination;

Gamma reflection or duplication by default;

Euler or Pfaff transformations of hypergeometric functions;

branch-changing factorizations of noninteger powers;

broad FunctionExpand.

The exact arguments and exponents of logarithms and noninteger powers must remain unchanged unless an explicit branch-certified rule authorizes the rewrite.

3. Signature grouping is exact, but signatures must not be assumed independent

After canonicalization, define a deterministic key

σ=HoldComplete[A
σ
	​

].

Then

H
m
	​

=
q
∑
	​

H
q,m
	​

=
σ
∑
	​

(
q
∑
	​

r
q,m,σ
	​

)A
σ
	​

.

This regrouping is exact by associativity and distributivity. It does not require the A
σ
	​

 to be algebraically independent.

That distinction matters:

it is valid to accumulate all coefficients carrying the same exact signature;

it is not valid to conclude that a coefficient must vanish merely because no other term has the same signature, unless independence has been proved;

two different signatures may still be related by an unimplemented Gamma, hypergeometric, logarithmic, or tensor identity.

Therefore signature grouping is a storage and cancellation mechanism, not a proof of functional independence.

A conservative status for the final result is:

exact equality to the original shard sum: proved;

minimality of the analytic basis: not claimed unless separately established.

4. Recommended exact ordering
Stage A: build one master-wide atom registry

Make one preliminary streaming scan over the 256 shard coefficients for master m. After applying the fixed canonicalization rules, record every maximal branch-sensitive or tensor object:

Wolfram Language
analyticAtomKey[object_] :=
  HoldComplete[object];

Use one stable atom dictionary for every shard of that master. Do not create different Unique symbols independently in different workers and later compare those symbols.

The dictionary should retain:

Wolfram Language
<|
  atomID -> <|
    "Expression" -> HoldComplete[object],
    "Hash" -> Hash[HoldComplete[object], "SHA256", "HexString"],
    "Class" -> "Gamma" | "Log" | "Power" | "BMHV" | ...,
    "BranchRegistryFingerprint" -> branchFingerprint
  |>
|>
Stage B: cheap certified cleanup of each shard

For each H
q,m
	​

:

apply the fixed branch and basis canonicalization;

replace registered analytic objects by the global inert atoms;

expose top-level additive terms;

decompose each term into

rA
σ
	​

;

apply Cancel to r;

merge terms with identical σ;

optionally use

Wolfram Language
Factor[Cancel[Together[rationalCoefficient]]]

only for a bounded small coefficient;

verify reconstruction of the complete shard from its signature map.

Do not apply Together across different signatures.

A suitable representation is

Wolfram Language
<|
  "Master" -> master,
  "Shard" -> shard,
  "SignatureCoefficients" -> <|
    signatureHash1 -> coefficient1,
    signatureHash2 -> coefficient2,
    ...
  |>,
  "AtomDictionaryFingerprint" -> atomDictionaryHash,
  "SourceHash" -> sourceHash,
  "ReconstructionStatus" -> "Verified"
|>
Stage C: accumulate rational coefficients across shards

For every signature σ, form

R
m,σ
	​

=
q=1
∑
256
	​

r
q,m,σ
	​

.

This should be done as a disk-backed balanced tree.

Within one signature:

normalize each rational leaf with Cancel;

group exact equal denominators;

add their numerators;

merge the remaining denominator groups in a balanced tree;

use denominator gcds when cheaply available;

apply bounded

Factor∘Cancel∘Together

at intermediate nodes only when the node is below the chosen resource bound;

retain the unchanged exact children when the bound is reached.

Every changed node must carry an exact rational identity certificate.

Stage D: remove zero signatures only when proved

A signature term may be deleted only if

R
m,σ
	​

=0

has been established exactly in the declared rational coefficient field.

A timeout is recorded as unresolved and the term is retained.

Stage E: reconstruct and perform one bounded final cleanup

Reconstruct

H
m
sig
	​

=
σ
∑
	​

R
m,σ
	​

A
σ
	​

.

At this point the expression should be much smaller than the raw sum. Then apply:

the historical composite-function collection, if the relevant functions occur;

collection by individual Beta, Gamma, and hypergeometric objects;

a bounded assumption-aware Simplify;

exact acceptance testing.

This is the correct point for the historical Beta–hypergeometric procedure. It should not precede complete rational cancellation within the same analytic signature.

5. Residual expressions that do not admit the signature grammar

Some expression may contain an analytic object nonlinearly, for example

1+Γ(1−ϵ)
1
	​


or an unevaluated function of a sum of analytic atoms. Such a term cannot be represented as a rational coefficient times an analytic monomial without changing the coefficient field.

Do not force it into the signature grammar.

Store it as one residual exact object:

Wolfram Language
"ResidualTerms" -> {...}

and combine residual terms through a separate balanced raw-addition tree. The same fixed branch registry and exact equality requirements apply.

Thus option 3 remains the fallback for the part of the coefficient outside the admitted linear analytic basis.

6. Small benchmark set

The following four calculations are sufficient to choose the production order.

Benchmark 1: complete one-target master

Run the complete master with one target through all candidate routes. This is primarily a construction test:

all routes must reproduce the already certified coefficient exactly;

atom dictionaries and branch data must agree;

no route should materially enlarge it.

Benchmark 2: complete 93-target master

Run the complete median master through:

Route L: local shard cleanup, then raw balanced addition;

Route S: no whole-shard cleanup, global signature accumulation;

Route H: cheap local cleanup, then global signature accumulation;

Route R: raw balanced addition with bounded cleanup at every tree level.

Because this complete column is manageable, require exact equality among all four outputs.

This is the most important acceptance calculation before the hard master.

Benchmark 3: 16 largest hard-master shard coefficients

Choose the 16 largest H
q,m
	​

 by serialized size. This probes peak memory and the expensive tail.

Benchmark 4: two deterministic 32-shard hard-master subsets

Use:

a stratified set across size and additive-term quantiles;

a set with the largest measured overlap of canonical analytic signatures.

The second set tests whether signature accumulation captures the expected cross-shard cancellations.

There is no need to reconstruct the full 818 MB input for each candidate route.

7. Exact equality checks for the benchmarks

For routes represented by the same global signature dictionary, compare them coefficientwise:

Δ
σ
	​

=R
m,σ
(A)
	​

−R
m,σ
(B)
	​

.

Require

Δ
σ
	​

=0

for every signature in the union of both maps.

This is preferable to simplifying one giant difference.

For a route with residual raw terms, compare:

σ
∑
	​

Δ
σ
	​

A
σ
	​

+Δ
residual
	​


in the same globally frozen ring. On the 16- and 32-shard subsets, the resulting check should remain manageable.

The local transformation certificates plus identical source manifests already prove each route equals the source sum. The route-to-route comparison is an independent implementation check.

8. Branch and BMHV acceptance criteria

A candidate route is mathematically acceptable only if all of the following hold:

Exact source coverage

q
⨆
	​

A
q,m
	​

=A
m
	​


with no missing or duplicated contributions.

Exact reconstruction
Every shard signature map reconstructs its source expression.

Exact merge identities
Every changed rational coefficient or tree node has an exact equality certificate.

No hadronic fractions

Wolfram Language
FreeQ[result, xa | xb | zh | ya | yb | yh]

is True.

No unresolved integral or tensor objects

Wolfram Language
FreeQ[
  result,
  _GLI | Pair | SPE | DiracTrace | DiracGamma | DOT | System`D
]

is True, apart from any explicitly retained, canonical BMHV basis objects.

Branch registry unchanged
Every noninteger power, logarithm, and other branch-sensitive object is either:

structurally identical to a registered input atom; or

related through a recorded branch-certified rewrite.

No new conditions
No unregistered ConditionalExpression, Piecewise, Abs, Sign, or branch condition is introduced.

No inexact data
All coefficients remain exact.

Timeout semantics
A timeout retains the exact input and records "Unresolved". It is never accepted as zero or as a changed expression.

9. Performance decision criteria

Exactness and branch preservation are mandatory. Among routes satisfying those conditions, compare:

wall time;

maximum worker RSS;

maximum intermediate serialized size;

final serialized size;

number of analytic signatures;

largest rational coefficient bucket;

number of bounded-operation timeouts;

number of unchanged fallbacks.

A route should not be selected merely because its final expression is smallest if it creates an impractical intermediate node.

For the pilot calculations, require:

zero failed transformations;

zero silently accepted timeouts;

no accepted cleanup that increases ByteCount;

final size no larger than the uncleaned exact sum;

peak memory below the declared per-worker production limit.

If two exact routes differ by less than roughly 10% in final size, prefer the one with lower peak memory and lower wall time rather than adding more aggressive simplification.

Recommended choice

The most likely winner, based on both NLO measurements and the newly certified NNLO shard decomposition, is:

cheap certified cleanup per H
q,m
	​

→global analytic-signature accumulation→balanced rational cleanup per signature→one bounded complete-master cleanup.
	​


This permits every cross-shard cancellation within a common analytic structure while avoiding a raw 818 MB master expression. It also preserves the exact branch-sensitive atoms and BMHV structures as immutable parts of the analytic basis rather than exposing them to unrestricted simplification.
