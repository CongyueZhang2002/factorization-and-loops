# Finite Field Gauge Pullback Followup

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation.  The
user and Fable have now proposed replacing both Maple and characteristic-zero
four-channel simplification by finite-field reconstruction of the source-frame
gauge.  The attached Fable exchange gives the proposal.  Please assess it at
implementation level against the existing package machinery below.

## Existing reusable infrastructure

The actual code is in
`https://github.com/CongyueZhang2002/factorization-and-loops/tree/main/FeynFacet/Private`.
The local working tree is slightly ahead, but the relevant established pieces
are already in these files:

- `MultiquadraticStripSolve.wl`:
  - `multiquadraticStripModularGradeEvaluate` evaluates a raw expression DAG
    directly in `F_p[r_i]/(r_i^2-d_i)` without symbolic intermediates;
  - `multiquadraticStripSplitBranchEntry` evaluates all sign sheets and uses
    `multiquadraticProjectConjugates` for the Walsh projection;
  - modular tower inversion and integer powers are already implemented;
  - sparse root-placeholder compilation makes repeated point evaluations cheap.
- `FiniteFieldStripSolve.wl` and `FiniteFieldEpsForm.wl` already provide:
  - bivariate monomial support layouts and packed modular evaluation;
  - FLINT affine/RREF backends and multi-RHS solving;
  - held-out epsilon interpolation;
  - adaptive primes, CRT, rational lifting, and unseen-prime validation.
- The package also has a ratracer/FireFly reconstruction pipeline in
  `Simplification.wl`, but it consumes a static rational trace.  It is not yet
  clear that it can call a dynamic square-root/sign-sheet black box.

At the insertion point we have the exact rational chart gauge `G(p,q,eps)`,
its support (CF300/CF303 hard block: 620 chart monomials, support bounds roughly
`p<=25,q<=26`), its common chart gauge denominator, the two compact inverse-map
images `p(x,y,r1,r2),q(x,y,r1,r2)`, and the ordered root squares.  We can
therefore evaluate all 2x4 gauge entries and all four source grades at any
`(x,y,eps,p)` without ever constructing `G /. inverseMap`.

## Proposed known-denominator formulation

Write the inverse images as `p=Pp/Dp`, `q=Pq/Dq` in the four-channel field.
Choose `M,N` at least the maximum p/q exponents in both the chart numerator
support and chart denominator.  Homogenize:

```
A = sum c_ij(eps) Pp^i Dp^(M-i) Pq^j Dq^(N-j)
B = Q(Pp/Dp,Pq/Dq) Dp^M Dq^N
G = A/B.
```

Then `Norm(B)` is a rational polynomial in `(x,y)`, common to all four grades
and (if `Q` is regulator-free) independent of eps.  At each modular point we
can compute both `Norm(B)` and the four channel values of `G`; multiplying them
gives polynomial numerator samples.  This turns canonicalization into ordinary
polynomial fitting, followed by the package's existing rational-in-eps
interpolation and CRT/lift.  If the bound/support is too loose, a generic
rational black-box reconstruction is the fallback.

Please answer concretely:

1. Is the `Norm(B)` formulation correct and preferable to direct rational
   interpolation?  Identify any missing denominator contributions or
   cancellations caused by homogenization, grade projection, or coordinate
   denominators.
2. How should we derive a tight numerator/denominator support without symbolic
   source composition?  Can Newton polytopes/Minkowski sums of the chart
   support and the compact inverse-map channel supports give a safe and useful
   support?  Give the formulas for the norm/support growth at rank two.
3. What is the smallest decisive one-entry pilot?  Specify point count,
   prime count, epsilon images, and pass/fail timing.  We have one completed
   Maple entry as an oracle, but production acceptance remains only the
   existing eight fresh disjoint images at two primes.
4. Which existing infrastructure should be adapted rather than rewritten?
   In particular, should we:
   - use quotient-grade evaluation directly (four channels in one pass),
   - use sign sheets plus Walsh only as an independent Development oracle,
   - reuse the strip solver's support matrices/FLINT multi-RHS backend, and
   - reuse its held-out epsilon interpolation and CRT/lift unchanged?
5. Is a FireFly/ratracer route realistic here?  Static rational traces cannot
   compute modular square roots depending on the sample point.  If FireFly has
   a callback/library interface appropriate for this, state the concrete API
   and integration cost; otherwise recommend the in-package known-denominator
   fitter.
6. The two hard gauges are byte-identical after composition.  Should one
   reconstruct all 32 scalar channel outputs simultaneously from the same
   point stream and design matrix?  Explain where multi-RHS applies when all
   outputs share `Norm(B)`.

Please focus on the algebra and performance.  Do not recommend extra hashes or
duplicated production checks.

## Pro response

Verdict

GO, with one refinement: implement a known-denominator, four-grade polynomial reconstructor, but use a reduced denominator certificate BJ=D∈Q(x,y), not blindly the full field norm when obvious base-field content or subfield factors can be removed.

The proposal’s central reframing is correct: the 332,578-leaf source expression is an avoidable symbolic representation of a compact chart function, while its modular evaluation is cheap. 

11_reconstruct_dont_simplify

 The main technical risk is not correctness of reconstruction; it is that an unnecessarily large Norm(B) produces a source numerator support so large that dense polynomial fitting becomes another bottleneck.

The preferred production hierarchy is:

reduced known denominator→polynomial multi-output fit→joint rational fit only if needed→FireFly/RATRACER only as later alternatives.
	​

1. Algebra of the known-denominator formulation

For one chart-gauge entry, write

g(p,q,ϵ)=
Q(p,q)
P(p,q,ϵ)
	​

,

with

P=
(i,j)∈S
∑
	​

c
ij
	​

(ϵ)p
i
q
j
.

Assume first that Q is regulator-free and polynomial in p,q. Let

p=
D
p
	​

P
p
	​

	​

,q=
D
q
	​

P
q
	​

	​

,

where P
p
	​

,D
p
	​

,P
q
	​

,D
q
	​

 are integral elements of

O=Q[x,y][r
1
	​

,r
2
	​

]/(r
1
2
	​

−Δ
1
	​

, r
2
2
	​

−Δ
2
	​

).

For

M≥maxdeg
p
	​

(P,Q),N≥maxdeg
q
	​

(P,Q),

define

A=
i,j
∑
	​

c
ij
	​

(ϵ)P
p
i
	​

D
p
M−i
	​

P
q
j
	​

D
q
N−j
	​

,
B=D
p
M
	​

D
q
N
	​

Q(P
p
	​

/D
p
	​

,P
q
	​

/D
q
	​

).

Then exactly

g=
B
A
	​

.

Let σ
1
	​

,σ
2
	​

 be the two root-sign involutions and define

B
#
=σ
1
	​

(B)σ
2
	​

(B)σ
1
	​

σ
2
	​

(B),
D
B
	​

=BB
#
=Norm
K/Q(x,y)
	​

(B).

It follows that

D
B
	​

g=AB
#
.
	​


The right-hand side is an integral four-grade element,

AB
#
=U
0
	​

+U
1
	​

r
1
	​

+U
2
	​

r
2
	​

+U
12
	​

r
1
	​

r
2
	​

,

with polynomial U
S
	​

(x,y) and coefficients rational in ϵ. Therefore each source coefficient is

g
S
	​

(x,y,ϵ)=
D
B
	​

(x,y)
U
S
	​

(x,y,ϵ)
	​

.

This is mathematically correct.

Prefer direct numerator evaluation

At a modular source point, do not evaluate g=A/B, project it, and then multiply by D
B
	​

 unless that is the easiest first prototype.

The cleaner black box is:

Evaluate A and B as four-grade vectors.

Form the three conjugates of B.

Compute B
#
 and D
B
	​

=BB
#
.

Compute

U=AB
#
.

Return D
B
	​

 and the four channels of U.

This avoids:

extension-field inversion;

pointwise division;

avoidable denominator-zero failures;

all square-root choices;

Walsh projection in the production path.

Because B is common to all eight gauge entries, B
#
 and D
B
	​

 are computed once per point.

Important refinement: use a reduced denominator certificate

The full norm is safe but can over-clear very badly.

Suppose, after clearing base-field denominators,

B=s(x,y)B
0
	​

,

where s∈Q[x,y] is the common content of the four channels of B. Then

Norm(B)=s
4
Norm(B
0
	​

),

while

B
1
	​

=
sNorm(B
0
	​

)
B
0
#
	​

	​

.

Thus the useful denominator is

D=sNorm(B
0
	​

),
	​


not s
4
Norm(B
0
	​

).

Otherwise the fitted polynomial numerators carry a removable factor s
3
, potentially enlarging their Newton polygons substantially.

More generally, seek any exact pair

BJ=D,J∈K,D∈Q(x,y).

The full norm supplies one such pair,

J=B
#
,D=Norm(B),

but it need not be minimal.

Two inexpensive reductions should precede the fit:

Strip base-field content from the four channels of B.

Use minimal-subfield norms when B factors into pieces using fewer roots.

For example, if

B=B
1
	​

(r
1
	​

)B
2
	​

(r
2
	​

),

then the denominator

N
1
	​

(B
1
	​

)N
2
	​

(B
2
	​

)

is sufficient. Taking the full rank-two norm instead squares both factors.

The denominator fitter should therefore be formulated around a general certificate BJ=D, with the full norm as the guaranteed fallback.

Missing denominator contributions to account for

The displayed formula is complete only after checking the following.

Base-field denominators in the inverse map

If P
p
	​

,D
p
	​

,P
q
	​

,D
q
	​

 themselves have rational coefficients in x,y, first clear those denominators. Otherwise Norm(B) is a rational function, not a polynomial.

Rational root squares

The support and integrality argument assumes

Δ
1
	​

,Δ
2
	​

∈Q[x,y].

If a root square is rational rather than polynomial, either clear its denominator or rescale the root generator to an integral one.

Regulator denominators in c
ij
	​

(ϵ)

These are not included in D
B
	​

(x,y). They should be handled separately.

Since the source composition is ϵ-independent, one can derive an exact common regulator denominator directly from the known chart coefficients:

h
e
	​

(ϵ)=lcm
i,j
	​

Denominatorc
e,ij
	​

(ϵ).

Then fit

h
e
	​

(ϵ)D
B
	​

(x,y)g
e,S
	​

(x,y,ϵ)

as a polynomial in ϵ, rather than rediscovering its rational ϵ-dependence. Retaining the package’s rational-in-ϵ interpolation is also correct, but the known h
e
	​

 is cheaper and gives an exact degree bound.

Rational or Laurent chart denominators

If Q is rational, write Q=Q
N
	​

/Q
D
	​

 and replace

P/Q⟶PQ
D
	​

/Q
N
	​

.

If negative powers of p,q occur, first shift the numerator and denominator by a common Laurent monomial.

Cancellations

There are three classes:

A and B may share an algebraic factor.

D
B
	​

 and all four channels of AB
#
 may share the norm of that factor.

Each individual grade can have additional cancellation.

None invalidates the fit. After reconstruction, reduce each source coefficient separately:

h
S
	​

=gcd(U
S
	​

,D
B
	​

),g
S
	​

=
D
B
	​

/h
S
	​

U
S
	​

/h
S
	​

	​

.

Because D
B
	​

 is common and regulator-free, factor or normalize it once and reuse that work for all 32 outputs.

Grade projection creates no generic denominator

Direct four-grade arithmetic creates no extra denominators. The factors

4ρ
S
	​

1
	​


seen in a Walsh projection are only part of the split-point evaluation formula. They are not denominators of the characteristic-zero grade coefficients.

The current split implementation explicitly evaluates all branches and then applies multiquadraticProjectConjugates; retain that only as the independent development oracle. 

MultiquadraticStripSolve

Is known-denominator fitting preferable?

Yes, if the reduced numerator support is moderate.

It changes a rational reconstruction problem into polynomial interpolation with:

no denominator unknowns;

no projective normalization;

one design matrix;

many output right-hand sides;

an exact degree/support bound.

However, a grossly over-cleared norm can be worse than direct rational reconstruction. Since dense linear algebra grows superlinearly with support size, do not decide from the chart’s 620 monomials alone. First compute the source Newton support described below.

A practical rejection criterion is:

if the known-denominator source support exceeds roughly 4,000–5,000 monomials per grade, or

if its first one-prime fit exceeds about 90 seconds,

switch to sparse polynomial interpolation or a joint common-denominator rational fit rather than building a larger dense matrix.

2. Support from graded Newton polytopes

Plain Minkowski sums of ungraded supports are not sufficient, because multiplying two identical root grades introduces a factor of the corresponding radicand.

For

z=
S
∑
	​

z
S
	​

r
S
	​

,

let S
S
	​

(z)⊂Z
≥0
2
	​

 be the monomial support of coefficient z
S
	​

(x,y). For masks S,T⊆{1,2},

r
S
	​

r
T
	​

=(
i∈S∩T
∏
	​

Δ
i
	​

)r
S△T
	​

.

Therefore the safe support multiplication rule is

S
U
	​

(zw)⊆
S△T=U
⋃
	​

[S
S
	​

(z)+S
T
	​

(w)+
i∈S∩T
∑
	​

S(Δ
i
	​

)],
	​


where + denotes a Minkowski sum.

Use this rule recursively for powers of

P
p
	​

, D
p
	​

, P
q
	​

, D
q
	​

.

Then

S(A)⊆
(i,j)∈S
P
	​

⋃
	​

S(P
p
i
	​

D
p
M−i
	​

P
q
j
	​

D
q
N−j
	​

),

and similarly for B.

Conjugation changes signs only, so it does not change support.

Rank-two norm formula

Write

B=b
0
	​

+b
1
	​

r
1
	​

+b
2
	​

r
2
	​

+b
12
	​

r
1
	​

r
2
	​

.

Define

h
0
	​

=b
0
2
	​

+Δ
1
	​

b
1
2
	​

−Δ
2
	​

b
2
2
	​

−Δ
1
	​

Δ
2
	​

b
12
2
	​

,
h
1
	​

=2(b
0
	​

b
1
	​

−Δ
2
	​

b
2
	​

b
12
	​

).

Then

Norm(B)=h
0
2
	​

−Δ
1
	​

h
1
2
	​

.
	​


The corresponding Newton-polytope bounds are

P(h
0
	​

)⊆conv(2P
0
	​

,D
1
	​

+2P
1
	​

,D
2
	​

+2P
2
	​

,D
1
	​

+D
2
	​

+2P
12
	​

),
P(h
1
	​

)⊆conv(P
0
	​

+P
1
	​

,D
2
	​

+P
2
	​

+P
12
	​

),
P(NormB)⊆conv(2P(h
0
	​

),D
1
	​

+2P(h
1
	​

)).
	​


Here P
S
	​

=Newt(b
S
	​

) and
D
i
	​

=Newt(Δ
i
	​

).

A coarser but convenient bound is

Newt(NormB)⊆4P
B
	​

+2D
1
	​

+2D
2
	​

,

where P
B
	​

 contains the supports of all four b
S
	​

.

For the numerator channels

U=AB
#
,

a corresponding coarse bound is

Newt(U
S
	​

)⊆P
A
	​

+3P
B
	​

+2D
1
	​

+2D
2
	​

.
Practical support workflow

Propagate grade-indexed Newton polygons through the compact inverse-map DAG.

Enumerate lattice points in each resulting polygon.

Use that list as a safe candidate support.

At one prime, solve on the full candidate support.

Learn actual nonzero support.

Confirm the learned support at a second prime.

This uses no source symbolic composition. Cancellations can only shrink the propagated support.

If the lattice-point hull is too loose, retain exact exponent sets instead of convex hulls for the few compact inverse-map factors, or use sparse Zippel-style polynomial interpolation. Do not revert immediately to generic rational reconstruction.

3. Smallest decisive one-entry pilot

Use the completed Maple entry as a development oracle, but leave the existing production acceptance unchanged.

Let

s
g
	​

=∣S
g
	​

(U)∣,s=
g
max
	​

s
g
	​

.

If using one union support for all four grades, let s be the size of that union.

Phase 1: one-prime, one-ϵ feasibility test

At one existing good 31-bit prime:

one generic regulator image;

s+8 construction points;

8 disjoint held-out points;

four numerator channels as four RHS columns;

one denominator output reconstructed separately.

Require:

rankV=s,

where

V
km
	​

=x
k
a
m
	​

	​

y
k
b
m
	​

	​

.

Compare the result with the completed Maple entry modulo the same prime.

Pass thresholds

complete provider evaluation plus polynomial fit in at most 60 seconds;

peak memory below roughly 2 GiB;

zero held-out defect.

Stop dense known-denominator fitting if

s>5,000;

the design matrix exceeds the intended memory envelope;

or this first fit takes more than 90 seconds.

Phase 2: regulator reconstruction

Derive the exact regulator degree from the chart coefficients.

If a regulator denominator h(ϵ) is known and

h(ϵ)U
S
	​

(x,y,ϵ)

has degree d
ϵ
	​

, use:

d
ϵ
	​

+1 construction regulator values;

2 held-out regulator values.

If retaining generic rational interpolation with numerator/denominator degrees
(d
N
	​

,d
D
	​

), use at least

d
N
	​

+d
D
	​

+1

construction values plus 2 held-out values.

The kinematic design matrix is unchanged across all regulator values, so factor it once and solve all regulator fibres as multiple RHS columns.

Phase 3: lifting

Use two construction primes initially and add a third or further primes only when rational lifting remains ambiguous. The exact Maple result makes the one-entry development comparison decisive.

A useful end-to-end threshold is:

strong pass: complete one-entry reconstruction within 120 seconds;

usable pass: within 240 seconds and at least 4× faster than Maple;

reject this dense implementation: over 300 seconds or less than 3× faster.

After a one-entry pass, test all 32 outputs. Their cost should be much closer to one fit with more RHS than to eight independent fits.

Prime-width correction

The Fable note proposes “a few 61-bit primes.” 

11_reconstruct_dont_simplify

 That is not compatible with the current reusable package path: the direct provider explicitly requires

3<p<2
31
.

MultiquadraticStripSolve

Use the existing 31-bit prime pool and adaptive CRT. Moving to 61-bit primes would require a separate overflow-safe evaluator and FLINT wire protocol; it is not needed for this pilot.

4. Infrastructure to adapt
Production evaluator: quotient-grade arithmetic

Yes. Use direct four-grade evaluation in production.

The most efficient point evaluator is:

Evaluate P
p
	​

,D
p
	​

,P
q
	​

,D
q
	​

 in the rank-two grade algebra.

Cache their powers through M,N.

Evaluate common B.

Compute J=B
#
 and D=BJ.

Evaluate the eight A
e
	​

.

Return

U
e
	​

=A
e
	​

J

for all entries.

This is a thin new black-box provider around existing modular grade multiplication, integer powers, and tower arithmetic.

There is no need to construct G /. inverseMap.

Sign sheets plus Walsh

Use only as a development oracle.

The current sparse split path evaluates all branches and projects them back to channels. 

MultiquadraticStripSolve

 It is useful for checking the new quotient-grade provider at a small set of split points, but production should accept nonsplit points and avoid modular square roots entirely.

Support matrices and FLINT

Reuse:

arbitrary bivariate support lists;

packed monomial evaluation;

independent-row or constrained-core discovery;

FLINT multi-RHS solving;

full-row residual evaluation;

support learning.

Do not reuse the entire affine-PDE solver orchestration unchanged. The canonicalizer has no gauge nullspace or residue normalization problem; it needs a much thinner polynomial-fit record:

VC=Y.

A fixed full-rank interpolation core is enough.

Regulator interpolation and CRT/lift

Reuse the lower-level:

held-out regulator interpolation;

adaptive prime scheduler;

CRT;

rational lifting;

unseen-prime evaluation.

These components operate on coordinate vectors and are directly applicable.

If the exact h
e
	​

(ϵ) is derived from the chart gauge, replace rational interpolation by polynomial interpolation after multiplication by h
e
	​

. This is a small specialization, not a new reconstruction stack.

5. FireFly and RATRACER
FireFly

FireFly does provide an appropriate C++ black-box callback. Its documented interface requires a class derived from BlackBoxBase, with an evaluator of the form

C++
template<class FFIntTemp>
std::vector<FFIntTemp>
operator()(const std::vector<FFIntTemp>& values);

and reconstruction through a Reconstructor object. It also permits a prime_changed() hook. 
GitHub

Thus a native FireFly route is technically realistic:

C++
class GaugeBox : public BlackBoxBase<GaugeBox> {
public:
  template<class FF>
  std::vector<FF> operator()(const std::vector<FF>& z) {
    // z = {x,y,epsilon}
    // evaluate rank-two tuples and return 32 base-field channels
  }

  void prime_changed();
};

GaugeBox box(...);
Reconstructor<GaugeBox> rec(3, threads, box);
rec.reconstruct();

However, FireFly cannot directly call the existing Wolfram evaluator as a cheap callback. You would need to port:

compact inverse-map evaluation;

four-grade multiplication;

norm/adjugate calculation;

chart sparse-polynomial evaluation;

output ordering;

singular-point behavior;

result import.

That is an additional native backend, not a wrapper around the current package. It is justified only if the in-package known-denominator support becomes too large or if generic rational reconstruction becomes the recurring production problem.

RATRACER

RATRACER is not a dynamic callback system in the same sense. Its ratracer.h library records a fixed sequence of rational operations into a trace, and its command-line tool replays, optimizes, and reconstructs that trace. 
GitHub
+1

A sign-sheet implementation containing point-dependent modular square-root logic is not naturally a static rational trace.

A quotient-grade implementation is traceable, because every operation is addition, multiplication, inversion, and integer power in the base finite field. One could emit the four-channel tuple calculation as a RATRACER trace with 32 outputs.

That remains a new trace generator and result-import path. Given that the exchange reports millisecond-scale black-box evaluation, the likely immediate bottleneck is support fitting rather than trace replay. 

11_reconstruct_dont_simplify

Recommendation: use the in-package known-denominator fitter first. Keep FireFly as the generic-rational fallback; do not integrate RATRACER for this canonicalization pilot.

6. Reconstruct all 32 source channels together

Yes. This is the correct production organization.

There are

8 matrix entries×4 grades=32

polynomial numerator outputs, all sharing the same denominator certificate D.

At one prime and regulator image, form

Y=(
U
1,0
	​

	​

U
1,1
	​

	​

⋯
	​

U
8,12
	​

	​

)

on the common point stream and solve

VC=Y.

The expensive operation is the factorization or constrained solve of V. Adding 32 RHS columns is much cheaper than factoring 32 separate matrices.

Grade-specific supports

If the four grade supports differ materially, build four design matrices

V
0
	​

,V
1
	​

,V
2
	​

,V
12
	​

,

each with eight gauge-entry RHS columns.

If their supports are the same or nearly so, use one union support and one 32-RHS solve.

Batch regulator fibres as RHS columns

Because the denominator and kinematic support are ϵ-independent, one can concatenate regulator fibres:

Y
g
	​

=[Y
g
	​

(ϵ
1
	​

)∣Y
g
	​

(ϵ
2
	​

)∣⋯∣Y
g
	​

(ϵ
m
	​

)].

For each grade this gives 8m RHS columns. Factor the support matrix once per prime and solve all regulator fibres together, possibly in bounded chunks if memory requires it.

Afterward, interpolate each reconstructed monomial coefficient in ϵ.

Shared denominator

Reconstruct D(x,y) once. After lifting, reduce the 32 fractions independently against that one polynomial. The byte-identical CF300/CF303 gauges should consume the same reconstructed source result rather than repeat the reconstruction.

Minimal implementation sequence

Construct integral, grade-valued A
e
	​

 and common B without source substitution.

Strip obvious base-field content and active-subfield over-norming from B.

Implement the modular black box returning:

D,U
e,S
	​

=A
e
	​

J.

Propagate grade-aware Newton supports.

Run the one-entry, one-prime feasibility fit.

If it passes, reconstruct all 32 outputs through shared multi-RHS matrices and batched regulator fibres.

Reduce each lifted numerator against the common denominator.

Retain the current sign/Walsh evaluator and completed Maple entry only as development oracles.

Fall back first to a joint common-denominator rational fitter; integrate FireFly only if the known-denominator support proves unmanageably large.

The known-denominator formulation is the best immediate route, but the production object should be the reduced certificate BJ=D, not necessarily the raw degree-four field norm.

## Sources sent to Pro

- Original source reference: `/home/maxzhang/factorization-and-loops/Exchange/Fable/2026-08-28/11_reconstruct_dont_simplify.md` (not archived with this exchange)
