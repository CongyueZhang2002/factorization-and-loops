# NNLO Dimensionless Result

## Question

We completed the exact dimensionless benchmark you recommended, followed by
one further size-monotone equal-denominator consolidation. Please assess the
stopping point and storage choice from these measured results.

Starting exact hard-master representation:

- 6,557 fractions with distinct denominators in the original variables s,t,u.
- in-memory fraction data: 351,559,840 bytes.
- serialized file: 99,892,985 bytes.

Exact normalization:

  t = -s x,  u = -s y,

with the physical chamber

  s > 0, x > 0, y > 0, x+y < 1.

For every fraction, a recursive homogeneity proof found integer numerator and
denominator degrees in s. All 6,557 fractions of the hard master have the same
net scale power s^(-2). We then stored only the s-free rational functions of
x,y. No PowerExpand, logarithm, square root, or noninteger-power identity was
used. Thirty stratified exact reconstructions back to s,t,u gave zero.

After normalization alone:

- 6,557 fractions.
- denominator hashes: 6,557 -> 5,974.
- in-memory fraction data: 296,802,344 bytes.
- serialized file: 92,385,524 bytes.
- wall time: 430.91 s on eight kernels.

We then reapplied the exact size-monotone equal-denominator rule. It formed raw
numerator sums and bounded Cancel candidates, retaining the smaller exact pair.

- iteration 1: 6,557 -> 5,974 fractions and 5,973 denominator hashes;
  520 raw sums, 3 cancelled forms, 5,451 unchanged forms.
- iteration 2: 5,974 -> 5,973 fractions, all denominators distinct;
  1 cancelled form and 5,972 unchanged forms.
- final in-memory data: 296,275,768 bytes.
- final serialized file: 92,241,826 bytes.
- consolidation wall time: 904.57 s on eight kernels.

Relative to the original size-monotone s,t,u representation, the final
dimensionless form reduces in-memory data by 15.7% and serialized data by 7.7%.
The reduction is real but below the 20% criterion you proposed. An independent
complete replay audit is currently running; it regenerates every exact class
from the dimensionless source and compares the complete saved fraction
multiset structurally.

Questions:

1. Should the 99.9 MB s,t,u form remain the primary computational artifact and
   the 92.2 MB x,y form remain optional because its storage improvement is only
   7.7%?
2. Or does the dimensionless form have enough downstream analytic value for
   differential equations, denominator classification, and factor dictionaries
   that it should become the primary computational form despite the modest file
   reduction?
3. Given 5,973 distinct x,y denominators, is a shared factor dictionary still
   worth measuring now, or should work stop at this exact representation?

## Pro response

No further coefficient-level consolidation is justified. The exact dimensionless representation should become the primary working form for downstream analytic calculations, while the s,t,u representation remains the physical-variable provenance artifact.

The earlier 20% threshold was a heuristic for adopting a change solely as compression. Here the transformation also separates the overall scale exactly, simplifies the physical region, and places the coefficient in the variables naturally used for differential equations and singular-locus analysis. That additional analytic value outweighs the modest 7.7% serialized-size reduction.

1. Recommended storage roles

For the hard master, the proved relation is

H
m
	​

(s,t,u,ϵ)=s
−2
H
m
	​

(x,y,ϵ),x=−
s
t
	​

,y=−
s
u
	​

,

with inverse map

t=−sx,u=−sy,

and physical chamber

s>0,x>0,y>0,x+y<1.

Use the two artifacts as follows.

Artifact	Recommended role
6,557-fraction s,t,u form, 99.9 MB	Authoritative physical-variable provenance and independent reconstruction source
5,973-fraction s
−2
H
m
	​

(x,y,ϵ) form, 92.2 MB	Primary computational artifact for differential equations, denominator analysis, boundary limits, and further analytic manipulation

The complete replay audit should be the acceptance condition for promoting the x,y artifact. The thirty stratified reconstructions are strong tests, but they do not by themselves certify all 5,973 saved fractions. Once the replay establishes exact class-by-class reconstruction and exact source coverage, the dimensionless form is fully compositional and no global difference is needed.

Retain in its metadata:

ScalePower=−2,DimensionlessVariables={x→−
s
t
	​

, y→−
s
u
	​

},
InverseMap={t→−sx, u→−sy},

and the exact physical chamber above.

The scale power must be derived separately for every other master. The measured s
−2
 result for this hard master should not be silently assigned to all 342 masters.

2. Why the dimensionless form has downstream value
Exact separation of scale and shape

The common homogeneity result is stronger than a storage optimization. It shows that the entire coefficient depends on the hard scale through one monomial:

H
m
	​

(λs,λt,λu,ϵ)=λ
−2
H
m
	​

(s,t,u,ϵ).

The nontrivial kinematic dependence is entirely contained in 
H
m
	​

(x,y,ϵ).

This removes redundant scale dependence from every subsequent calculation.

Differential equations simplify

At fixed s,

∂t
∂H
m
	​

	​

=−s
−3
∂x
∂
H
m
	​

	​

,
∂u
∂H
m
	​

	​

=−s
−3
∂y
∂
H
m
	​

	​

.

At fixed t,u,

∂s
∂H
m
	​

	​

=s
−3
(−2−x
∂x
∂
	​

−y
∂y
∂
	​

)
H
m
	​

.

Thus the scale equation is fixed by homogeneity, while the genuine differential system is two-dimensional in x,y.

Physical singular loci become clearer

Common invariant combinations reduce to dimensionless factors:

s+t=s(1−x),s+u=s(1−y),
s+t+u=s(1−x−y),t+u=−s(x+y).

The physical region becomes the open triangle

P={(x,y)∈R
2
:x>0, y>0, x+y<1}.

This is directly useful for:

identifying differential-equation singular hypersurfaces;

selecting physical boundary paths;

organizing endpoint limits such as x→0, y→0, or x+y→1;

comparing crossing-related denominator geometries;

constructing a possible differential-equation alphabet.

The rational substitution does not combine logarithms, alter noninteger powers, or require PowerExpand. It is branch-neutral under the declared s>0 chamber.

3. The second equal-denominator consolidation should be the stopping point

The dimensionless substitution produced the substantive improvement:

351,559,840⟶296,802,344bytes in memory,

and

99,892,985⟶92,385,524serialized bytes.

The subsequent two consolidation iterations changed

92,385,524⟶92,241,826

serialized bytes, a reduction of only about 0.16%, while costing 904.57 seconds. Its main benefit was reducing the number of fractions from 6,557 to 5,973, not reducing storage.

Since all 5,973 denominators are now distinct, another equal-denominator pass has nothing to merge. More generally, future iterations should stop by a size-and-cost criterion rather than merely continue until denominator hashes are distinct. In this case both criteria agree: the exact representation has reached a natural fixed point.

Do not attempt:

another consolidation iteration;

a global Together;

a global multivariate partial-fraction decomposition;

unrestricted Simplify on the complete coefficient.

4. Measure a denominator-factor dictionary, but do not implement it immediately

The fact that there are 5,973 distinct complete denominators does not determine the number of distinct irreducible factors. They may be combinations of a much smaller recurring set such as

x,y,1−x,1−y,1−x−y,x+y,

together with more complicated process-specific polynomials.

Therefore a bounded denominator-only factor census is now worthwhile. It has two possible benefits:

a smaller serialized representation through factor reuse;

an exact inventory of singular polynomials relevant to differential equations.

It should be performed as an auxiliary measurement, not as another compulsory rewrite of the coefficient.

Exact factor census

Let

K=Q(ϵ,color invariants,…)

be the exact coefficient field, with any remaining inert analytic objects treated as fixed coefficient-field elements. For each denominator D
j
	​

(x,y), seek

D
j
	​

(x,y)=c
j
	​

α=1
∏
r
	​

f
α
	​

(x,y)
e
jα
	​

,c
j
	​

∈K
×
,

where each f
α
	​

 is primitive and monic under one fixed monomial order.

Every accepted factorization must satisfy exact reconstruction:

D
j
	​

−c
j
	​

α
∏
	​

f
α
e
jα
	​

	​

=0.

If bounded factorization times out, retain D
j
	​

 as one indivisible exact factor. No result is lost.

Measure these quantities

Compute:

N
D
	​

=5973,
N
f
	​

=#{distinct certified primitive factors},
I
f
	​

=
j=1
∑
N
D
	​

	​

#{α:e
jα
	​

>0},

and the recurrence distribution

r
α
	​

=#{j:e
jα
	​

>0}.

Also measure the projected artifact size

B
dictionary
	​

=B
factor table
	​

+B
exponent profiles
	​

+B
numerator records
	​

+B
units
	​

.

Compare this directly with

B
current
	​

=92,241,826 bytes.
Adoption criterion

Promote the factor dictionary to a computational representation only when at least one of these is observed:

projected serialized size is at least 15%–20% smaller;

a small recurring factor alphabet covers most denominators;

factor profiles materially reduce the predicted cost of GCD-aware addition;

the factor inventory is directly needed as the candidate singular alphabet for the differential equations.

If most primitive factors occur only once, stop and retain the 5,973-fraction representation.

A deterministic stratified census can answer this before a complete factorization run:

all denominators below a modest byte threshold;

the 256 largest denominators;

512 denominators stratified by size and total degree;

denominators from the most populated pre-normalization classes.

If the sample shows little factor reuse, no full dictionary construction is justified.

Final recommendation

Provided the complete replay audit succeeds:

H
m
	​

(s,t,u,ϵ)=s
−2
j=1
∑
5973
	​

D
j
	​

(x,y,ϵ)
N
j
	​

(x,y,ϵ)
	​

	​


should be the primary downstream representation of the hard master, with

x=−
s
t
	​

,y=−
s
u
	​

,x>0, y>0, x+y<1.

Keep the s,t,u artifact as the independent physical-variable provenance record. Stop all further coefficient consolidation. Run only a bounded denominator-factor census next; build a shared factor dictionary only if the measured factor reuse or differential-equation analysis justifies it.

This preserves the exact analytic deliverable and its physical branch information; fixed-kinematics numerical values remain verification data rather than the calculation path. 

AGENTS

 

AGENTS

 The broader FACET records likewise distinguish exact geometric inventories from the later analytic work built on them, so downstream usefulness—not a raw count reduction alone—is the appropriate criterion for choosing the working representation. 

BOUNDARY_FAMILY_INVENTORY

 

boundary_equivalence_draft

 

BOUNDARY_FAMILY_INVENTORY
