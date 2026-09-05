# Materialization Speed Followup

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation and your
materialization review. We ran the decisive real-operand pilots while you were
reviewing. Please update the recommendation using these results and choose the
next implementation, not another profiling/check layer.

Physical evidence from preserved production payloads:

- CF303 `{25,18}` largest transformed operand: 54.7 MB, 1.79M leaves,
  59,478 negative-power nodes but only 39 distinct denominator bases; current
  `Together` task is in the several-minute class.
- CF259 `{27,15}` known 300.9-second operand #48 has the same pathology.
- A pure recursive rational-DAG collector `{numerator, denominator-base map}`
  finished in 7.06 s on CF303 and 6.69 s on CF259.
- But postponing reduction is not viable: CF259 then had a 73.2 MB numerator
  and 38 structural denominator bases, versus the accepted canonical operand's
  4.1 MB numerator and 16 irreducible factors. One final `Cancel[num/den]`
  timed out at 60.1 s. Factoring the 38 bases took only 1.26 s (29 irreducible
  factors), but both `Cancel[num/factor]` and polynomial quotient against the
  first factor exceeded 30 s. Global/factorwise reduction is therefore too
  late.
- Naive finite-field reconstruction is also ruled out: one node-wise modular
  evaluation of the largest CF303 operand took 27.49 s per point.
- Kallen2Bilinear115 has a detected shared chart denominator. With
  `K=p(1-p)`, `H=u^2+4K`, `A_n=4K-2u`, all four source generators map to
  numerators over the same `H`:
  `{-p A_n, (H-A_n)(1-p), A_n-p H, H+u A_n}/H`.
  This supports exact homogenized composition before eager substitution.

Two remaining exact routes:

1. A locally reduced recursive fraction DAG. Every child is reduced. At an
   n-ary Plus, form the LCM map; a denominator factor can cancel only when its
   maximum exponent is attained by at least two children. Form one candidate
   product from just those factors, compute one local `PolynomialGCD[N,C]`,
   divide once, and subtract `FactorList[gcd]`. At Times, structurally cancel
   exact keys then at most one local cross-child GCD. Pure polynomial subtrees
   are leaves. Thus reductions occur before numerators swell.
2. Source-first homogenized chart composition using the common denominator
   when present, and generic multidegree clearing otherwise; reuse the same
   recursive pair logic on the smaller source expression, cache image powers,
   and never create the 723 MB transformed payload.

Please answer concretely:

- Which should be implemented first now, given the failed late-cancellation
  pilot? Is the stated local-GCD invariant mathematically sufficient to keep
  every recursive pair reduced?
- Give the simplest safe Wolfram algorithm for the local GCD/division,
  including how to choose variables and avoid treating another chart variable
  as a coefficient field.
- Could source-first common-H homogenization avoid the hard cancellation
  entirely, or will the composed numerator/denominator still require the same
  local GCD machinery?
- What single timing/size threshold should decide whether to commit the local
  prototype or jump directly to homogenized composition/FLINT?

Do not recommend new hashes, duplicate production checks, or more queue tuning.
Existing per-block modular acceptance remains the only production identity
check.

## Pro response

Verdict

Implement source-first homogenized composition first, backed by a locally reduced fraction-pair kernel. Do not first build a generic reduced-DAG canonicalizer for the already transformed 54.7 MB expression.

The two routes are not truly alternatives:

source-first homogenization removes the largest avoidable source of swell;

local reduction is still required for genuine numerator/denominator cancellations;

the generic transformed-expression DAG should become a fallback for charts without a useful common denominator.

The new measurements settle the issue. Tree traversal and denominator discovery are cheap—about 7 seconds and 1.26 seconds, respectively—while cancellation becomes intractable only after the numerator has already swollen. This agrees with the earlier diagnosis that the composed source expression is a cheap function in a pathological symbolic representation. 

11_reconstruct_dont_simplify

 It also directly targets the dominant normalization bottleneck that replaced finite-field solving. 

08_three_root_slowdown_and_reco…

1. Correct implementation order

Use this path:

source DAG⟶common-denominator homogenization⟶locally reduced channel fractions⟶final ordinary expression
	​


For the common-H chart, store each source generator as

z
i
	​

=
H
Z
i
	​

	​

,

with

H=u
2
+4p(1−p)

and the supplied Z
i
	​

.

For a polynomial source subtree

P(z
1
	​

,…,z
m
	​

)=
α
∑
	​

c
α
	​

z
α
,

let

d=
α
max
	​

∣α∣.

Evaluate it directly as

P(z)=
H
d
∑
α
	​

c
α
	​

H
d−∣α∣
∏
i
	​

Z
i
α
i
	​

	​

	​

.

For a rational source expression P/Q, homogenize the numerator and denominator separately:

Q(z)
P(z)
	​

=H
d
Q
	​

−d
P
	​

Q
	​

(Z,H)
P
(Z,H)
	​

.

The explicit power H
d
Q
	​

−d
P
	​

 should be cancelled by integer exponent bookkeeping before any polynomial GCD is attempted.

For charts without one common denominator, use the multidegree form. If

z
i
	​

=
H
i
	​

Z
i
	​

	​

,m
i
	​

=
α∈suppP
max
	​

α
i
	​

,

then

P(z)=
∏
i
	​

H
i
m
i
	​

	​

∑
α
	​

c
α
	​

∏
i
	​

Z
i
α
i
	​

	​

H
i
m
i
	​

−α
i
	​

	​

	​

.

This remains exact, although it can over-clear when several H
i
	​

 share factors. Local reduction handles that.

Cache:

H
n
 and Z
i
n
	​

;

homogenized pure-polynomial subtrees;

normalized denominator-factor maps;

repeated source DAG nodes.

Do not generate expr /. inverseMap as an ordinary Wolfram expression.

2. The local-GCD invariant
Addition

Let the children be reduced fractions

f
i
	​

=
d
i
	​

n
i
	​

	​

,

over the UFD

R=Q[p,u,ϵ]

or the corresponding declared target polynomial ring. Denominators must be represented as maps of primitive irreducible, pairwise nonassociate factors:

d
i
	​

=
π
∏
	​

π
e
i,π
	​

.

Set

e
π
	​

=
i
max
	​

e
i,π
	​

,D=lcm(d
1
	​

,…,d
n
	​

),
N=
i
∑
	​

n
i
	​

d
i
	​

D
	​

.

If exactly one child j attains the maximum exponent of an irreducible factor π, then modulo π,

N≡n
j
	​

d
j
	​

D
	​


≡0(modπ),

because:

n
j
	​

 and d
j
	​

 are coprime;

D/d
j
	​

 is not divisible by π;

every other term is divisible by π.

Therefore:

π can cancel only if its maximum denominator exponent is attained by at least two children.
	​


That part of the proposed invariant is correct.

The candidate divisor must, however, include the full possible multiplicity:

C=
π
#{i:e
i,π
	​

=e
π
	​

}≥2
	​

∏
	​

π
e
π
	​

.
	​


Using each factor only to the first power would miss repeated cancellation.

For a root-basis numerator

N=N
0
	​

+N
1
	​

r
1
	​

+N
2
	​

r
2
	​

+N
12
	​

r
1
	​

r
2
	​

,

a rational factor cancels only if it divides every channel. Compute

g=gcd(C,N
0
	​

,N
1
	​

,N
2
	​

,N
12
	​

),

ignoring zero channels. If every channel vanishes, canonicalize immediately to zero with denominator one.

Then divide every channel and subtract the factorization of g from the denominator map. This produces a reduced result.

Use binary balanced addition

Do not implement this as one giant n-ary numerator followed by one GCD. That can reproduce the 73 MB numerator pathology.

Group children by denominator signature, sum identical-denominator groups first, and combine groups through a balanced binary tree. Apply the candidate-GCD rule at every binary merge.

This is the same successful structural principle already used elsewhere in the campaign: retain exact additive/product structure and combine reduced channels rather than normalize a complete swollen expression. 

codex_overnight_optimization_tr…

Multiplication

For scalar rational numerators, pairwise cross-cancellation is sufficient:

d
1
	​

n
1
	​

	​

d
2
	​

n
2
	​

	​

.

Before multiplication compute

g
1
	​

=gcd(n
1
	​

,d
2
	​

),g
2
	​

=gcd(n
2
	​

,d
1
	​

),

divide, and then multiply the reduced pieces.

For a multiquadratic channel numerator, that is not by itself sufficient. Root-basis multiplication can create a new common base-field factor through cancellations such as a norm:

(A+Br)(A−Br)=A
2
−B
2
Δ.

Therefore the safe multiplication is:

perform structural and cross-child cancellation before multiplying;

multiply channel vectors using the XOR/root-square law;

perform one post-product content GCD against the remaining denominator.

Thus the proposed “at most one local cross-child GCD” is sufficient only if it includes the post-product reduction for algebraic channel products. It is unnecessary for a purely scalar polynomial product.

Use balanced pairwise multiplication for large Times.

Inversion and negative powers

Every recursive normal form should maintain:

numerator in the finite root basis,denominator in the base polynomial ring.

Do not retain a root-containing denominator as merely another structural denominator base.

For a rank-two numerator

z=a
0
	​

+a
1
	​

r
1
	​

+a
2
	​

r
2
	​

+a
12
	​

r
1
	​

r
2
	​

,

invert it locally by recursive conjugation/norm arithmetic:

z
−1
=
Norm(z)
z
#
	​

.

Then locally reduce the resulting channel numerator against the rational norm denominator. Negative integer powers should use this inversion followed by binary exponentiation.

This is required for the addition proof above to apply: its denominator map must live in a UFD of rational polynomials.

3. Simplest safe Wolfram polynomial kernel

Use an explicit ring variable list from the chart/materialization context, for example

Wolfram Language
vars = {p, u, eps};

or {x,y,eps} in the source variables. Do not select one “main variable.”

In particular, avoid:

Wolfram Language
PolynomialQuotient[num, factor, p]

because that treats u and ϵ as coefficient-field objects.

Use multivariate exact division through PolynomialReduce:

Wolfram Language
exactPolynomialDivide[poly_, divisor_, vars_List] := Module[{qr},
  qr = PolynomialReduce[poly, {divisor}, vars];
  If[! TrueQ[qr[[2]] === 0], Return[$Failed]];
  First[qr[[1]]]
];

Before invoking PolynomialGCD, enforce the polynomial-ring contract:

Wolfram Language
basePolynomialQ[poly_, vars_List] :=
  PolynomialQ[poly, vars] &&
  And @@ (RationalQ /@ Last /@ CoefficientRules[Expand[poly], vars]) &&
  FreeQ[poly, Alternatives @@ rootSymbols];

PolynomialGCD has no explicit variable-list argument, so the guard matters. It prevents an undeclared chart variable or algebraic generator from silently appearing inside coefficients.

For channel content:

Wolfram Language
channelCandidateGCD[numerators_List, candidate_, vars_List] := Module[
  {nonzero, g},
  nonzero = DeleteCases[numerators, 0];
  If[nonzero === {}, Return[candidate]];
  If[! And @@ (basePolynomialQ[#, vars] & /@
        Join[nonzero, {candidate}]), Return[$Failed]];
  g = Fold[PolynomialGCD, candidate, nonzero];
  primitiveNormalize[g, vars]
];

Normalize every irreducible denominator key by:

removing rational content;

choosing a fixed associate/sign from a fixed monomial ordering;

factoring the base once with FactorList;

merging equal normalized factors.

The observed 1.26-second cost for factoring all 38 bases means irreducible denominator maps should be mandatory, not optional.

When dividing by the computed GCD, use PolynomialReduce with the full vars list for every channel. Factor the GCD once and subtract its multiplicities from the denominator map.

For the initial Wolfram implementation, retain expanded sparse polynomials only at local nodes. Do not call Cancel, Together, or univariate PolynomialQuotient.

4. Can common-H composition avoid cancellation entirely?

It avoids the largest artificial cancellation, but not all genuine cancellation.

It removes:

repeated rediscovery of the same H;

LCM construction across tens of thousands of negative-power nodes;

artificial powers of H produced independently in separate monomials;

creation and subsequent destruction of the 54.7 MB/723 MB transformed payload.

Powers of H arising solely from homogenization cancel exactly by exponent arithmetic.

It cannot guarantee coprimality of the final numerator and denominator. A birational substitution can make originally coprime source polynomials share factors on:

exceptional divisors;

chart base loci;

branch or discriminant divisors;

pulled-back source denominator components.

Channel multiplication can also generate norm factors not visible in the input factorization.

Therefore common-H composition still needs the local reduced-pair arithmetic above, but the GCDs occur on much smaller intermediate polynomials. It should greatly reduce both their degree and density.

The implementation should therefore be:

common-H homogenizer as the front end, locally reduced fraction/channel arithmetic as the kernel.

A generic reduced-DAG evaluator of the already substituted expression should be retained only for unsupported source nodes or charts where no useful denominator structure can be detected.

5. The next implementation
Implement now

Build a source-first materializer with three paths:

Pure polynomial subtree: common-H or generic multidegree homogenization.

Rational arithmetic node: locally reduced pair operation.

Unsupported node: existing Together materializer as a fallback for that operand only.

This is smaller and more likely to remove the bottleneck than first generalizing the 7-second structural collector over the 1.79-million-leaf transformed expression.

Do not yet build a native backend. The new evidence suggests the algorithm, not polynomial factorization, was the dominant error: factorization of all structural denominator bases was only 1.26 seconds.

Single commit/abort gate

Use both preserved hard operands:

CF259 operand 48;

the largest CF303 {25,18} operand.

Commit the Wolfram implementation only if each satisfies:

wall≤60 sandpeak live polynomial payload≤32 MiB.
	​


Crossing either bound is the abort condition.

Why this gate:

60 seconds gives at least a 5× improvement over the known 300.9-second CF259 operand;

32 MiB is less than half the failed 73.2 MB postponed-reduction numerator while leaving substantial room above the accepted 4.1 MB canonical numerator;

a smaller gain does not justify hardening a second symbolic canonicalization architecture.

If the source-first Wolfram kernel crosses that gate, preserve the representation and move only these operations to FLINT:

sparse polynomial multiplication;

multivariate GCD;

exact division;

content normalization.

Do not revert to transformed-expression Together, and do not port the entire materializer or broker layer.

Final ranking
Route	Decision	Reason
Source-first common-H homogenization plus local reduction	Implement first	Avoids payload creation and performs cancellation while objects remain small
Generic locally reduced transformed-expression DAG	Fallback/deeper generalization	Mathematically sound, but begins from the unnecessarily large tree
Late global or factorwise cancellation	Reject	Physically failed despite cheap denominator factorization
Naive pointwise finite-field reconstruction	Reject for this materializer	Measured 27.49 seconds per point
FLINT local polynomial kernel	Conditional second step	Appropriate only if the source-first WL representation passes mathematically but misses the 60 s/32 MiB gate

The failed late-cancellation pilot does not invalidate recursive fractions. It shows that reduction must happen before both numerator swell and eager chart substitution.
