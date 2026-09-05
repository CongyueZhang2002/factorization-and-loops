# TT Ordering Measured Followup

## Question

We now have measured NLO TT data for the coefficient-simplification ordering study. Please assess the mathematics and propose only changes justified by these measurements.

Exact input and invariants:
- 25 amplitude-conjugate pairs, 87 Kira targets, 6 masters.
- The hadronic-variable card gives exact physical substitutions and assumptions; there are no eta or PhT intermediate variables.
- One branch registry is derived from the complete unsimplified physical master vector and reused by every route.
- Every route must reconstruct the same exact master coefficients. A timeout or cleanup failure retains the exact canonical input and is counted.

Measured structural facts:
- Multiplying each pair PreFactor into its integrand gave a 2.35 GB physical master vector.
- The 25 recorded PreFactors have one exact common factor. Removing it before target/master formation reduced the physical master vector to 597,583,256 bytes and the prepared file to 194,495,206 bytes. The physical common factor itself is 664 bytes.
- The six master-coefficient sizes, plus zero remainder, are:
  559,590,272; 12,598,680; 6,437,920; 887,824; 14,812,672; 3,253,392; 16 bytes.
- All are free of residual Pair, DiracTrace, DiracGamma, DOT, GLI, and D objects.
- Worker initialization is now lightweight: four-worker synthetic test starts and completes in 6.1 s; coefficient algebra itself takes 0.014 s.

Controlled cleanup now does more than a single Simplify:
1. fixed physical branch rules;
2. TrigReduce to a fixed Fourier basis;
3. Expand to expose additive terms;
4. split each term into an analytic signature and a rational coefficient;
5. Cancel termwise;
6. merge exact equal-denominator buckets;
7. use bounded Factor[Cancel[Together[...]]] only for buckets <=200 kB and <=200 terms.

The first master-only attempt ran four workers with a 300 s bound. The dominant 559.6 MB coefficient resisted this cleanup; the five smaller coefficients were tractable. We have corrected failure handling so the exact input is retained and counted while other coefficients survive.

We are comparing in fresh processes:
A. pair cleanup, then targets, then masters;
B. complete-target cleanup, then masters;
C. master-only cleanup;
D. pair termwise cleanup, complete-target cleanup, then masters.

Questions:
1. Is early exact extraction of the common pair PreFactor mathematically sound for comparing these orderings? Identify any missing condition.
2. Given the one 559.6 MB master coefficient, should we expect complete-target cleanup to be superior because cancellations occur before Kira composition, or is there a better exact ordering?
3. Is the analytic-signature grammar above sufficient for Gamma/power/BMHV TT expressions? Give a concrete correction if not.
4. For NNLO streaming, define the smallest exact unit that may be simplified independently without losing cancellations: complete target coefficient, complete master column, or another precisely defined object.

Do not recommend numerical replacement for the analytic result. Keep the answer concrete and tied to the measurements above.

## Pro response

Yes—early extraction of the exact common pair prefactor is mathematically sound, provided it is treated as a common meromorphic factor and the conditions below are enforced. The measurements also rule out master-only cleanup as the primary route for NLO TT. The best justified ordering is:

common pair factor extraction→complete-target cleanup→signature-preserving Kira accumulation→bounded complete-master cleanup.
	​


The current measurements do not yet justify making complete pair-level cleanup mandatory for every pair.

1. Early extraction of the common pair prefactor

Write the contribution from pair p as

H
p
	​

=P
p
	​

(r
p
	​

+
α
∑
	​

c
pα
	​

G
α
	​

),

where G
α
	​

 is a canonical Kira target and r
p
	​

 is any GLI-free remainder. Suppose the measured prefactors satisfy the exact identities

P
p
	​

=F
com
	​

P
p
	​

for every p=1,…,25.

Then

p
∑
	​

H
p
	​

=F
com
	​

[
p
∑
	​

P
p
	​

r
p
	​

+
α
∑
	​

(
p
∑
	​

P
p
	​

c
pα
	​

)G
α
	​

].

If the Kira reduction is

G
α
	​

=
m=1
∑
6
	​

R
αm
	​

M
m
	​

,

linearity gives

p
∑
	​

H
p
	​

=F
com
	​

[
p
∑
	​

P
p
	​

r
p
	​

+
m=1
∑
6
	​

(
α,p
∑
	​

R
αm
	​

P
p
	​

c
pα
	​

)M
m
	​

].

Thus extracting F
com
	​

 before target formation cannot remove any cancellation among pairs or among Kira targets.

Required conditions

The extraction is certified only if:

Exact commonality

P
p
	​

−F
com
	​

P
p
	​

=0

for every pair under the same branch registry and physical assumptions.

Coefficient-field character
F
com
	​

 is free of GLIs, loop momenta, phase-space integration momenta, cut objects, and topology labels. It may depend on

s,t,u,ϵ,x
a
	​

,x
b
	​

,z
h
	​

,

couplings, color factors, spin variables, PDFs, and FFs.

Uniform physical channel
The same distribution and spin structure occurs in all 25 terms. A factor associated only with one flavor, polarization, or azimuthal structure cannot be extracted from the entire sum.

Branch certification
Any square root or noninteger power in F
com
	​

 must use the fixed physical branch. Structural extraction of

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

is harmless; extraction based on an unproved radical factorization is not.

Formal or meromorphic interpretation
Division by a PDF, FF, or kinematic factor is not asserted pointwise at its zeros. The identity is in the localized symbolic coefficient ring. The final expression must reconstruct without division:

H
original
	​

=F
com
	​

H
reduced
	​

.

Remainder inclusion
Any nonzero GLI-free remainder must either contain the same factor or be retained separately. Your measured remainder is zero, so this condition is currently trivial.

For comparing A–D, all routes should use the same fixed F
com
	​

, and exact equality should be checked after multiplying it back. The reduction from 2.35 GB to 597.6 MB is therefore a legitimate algebraic optimization rather than a change in the quantity being calculated.

One distinction should remain explicit: the common factor found in the pair prefactors is not automatically the complete final collinear hard-factor normalization. The final master coefficients must still be checked against the declared TT factor.

2. Ordering justified by the measured TT result

The master-only route has now supplied a decisive result:

one coefficient reaches 559.6 MB;

it remains difficult after 300 seconds;

the other five coefficients are manageable.

This rules out

raw targets→Kira→first serious cleanup at master level

as the primary NLO TT strategy.

The target-level work costs

174.01 s+253.37 s=427.38 s,

but it occurs before each target coefficient is replicated through its Kira image. Consequently, target-first cleanup should be retained.

Recommended exact ordering

Define the complete coefficient of target G
α
	​

 after removal of the common pair factor by

C
α
	​

=
p=1
∑
25
	​

P
p
	​

c
pα
	​

.

Then use

C
α
	​

hadronic map
	​

C
α
phys
	​

controlled cleanup
	​

C
α
	​

.

Only afterward form

K
m
	​

=
α=1
∑
87
	​

R
αm
	​

C
α
	​

.

This exposes all cancellations among the 25 pairs at fixed target before Kira composition.

However, target cleanup cannot expose cancellations between different targets in the same master coefficient. Therefore a final master-level operation remains necessary:

K
m
	​

bounded controlled cleanup
	​

K
m
	​

.
Better representation of the Kira step

The 559.6 MB result shows that target-first cleanup alone does not prevent a large master expression. The next justified change is not another unrestricted simplifier. It is to avoid constructing K
m
	​

 as one monolithic sum.

After each 
C
α
	​

 has been split into certified analytic structures,

C
α
	​

=
σ
∑
	​

A
σ
	​

C
α,σ
	​

(s,t,u,ϵ),

accumulate

K
m,σ
	​

=
α=1
∑
87
	​

R
αm
	​

C
α,σ
	​


separately. Then

K
m
	​

=
σ
∑
	​

A
σ
	​

K
m,σ
	​

.

Because R
αm
	​

 is rational in the dimensional regulator and kinematic invariants, it does not alter the distribution, azimuthal, BMHV, or branch signature σ. This accumulation preserves all cancellations among different targets with the same analytic structure while avoiding a single 559.6 MB expression.

The practical ordering is therefore

F
com
	​

 outside→{C
α
	​

}
α=1
87
	​

→{
C
α,σ
	​

}→{K
m,σ
	​

}→{
K
m
	​

}.
	​

What the measurements do not yet establish

The data do not yet establish that full pair-level cleanup should precede target formation for every pair. The representative F1/C1 result is favorable, but it does not measure the repeated cost over all 25 pairs or the amount of cancellation lost until target summation.

Accordingly:

keep pair-first and pair-termwise-plus-target as measured alternatives;

do not make either the default until the fresh-process A/B/D comparison is complete;

use complete-target cleanup as the current reference route;

do not use master-only as the reference route.

3. Required correction to the analytic-signature grammar

The stated grammar is sufficient for exactness only if atomization is reversible and exact reconstruction is checked. It needs one concrete ordering correction and three clarifications.

Freeze branch-sensitive objects before algebraic expansion

The safe order is

fixed branch rules→fixed TT tensor/Fourier basis→freeze analytic and BMHV atoms→Expand the rational shell.
	​


Do not apply a broad Expand before noninteger powers and special functions have been isolated. Although Expand is algebraically exact, early expansion can destroy the intended canonical analytic structure and create large, overlapping signatures.

Recommended signature

For a term

T
i
	​

=A
σ
i
	​

	​

r
i
	​

,

use

σ
i
	​

=(σ
dist
	​

,σ
az
	​

,σ
BMHV
	​

,σ
special
	​

,σ
rad
	​

),

while keeping color either in the signature or in the rational coefficient field.

Distribution structure

For the present TT channel, the expected structure is

σ
dist
	​

=α
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

).

Arguments and leg assignments are part of the key.

Fourier structure

Use a fixed basis such as

e
i(n
a
	​

ϕ
a
	​

+n
h
	​

ϕ
h
	​

)
,(n
a
	​

,n
h
	​

)∈Z
2
,

or an equivalent fixed real sine/cosine basis. Do not permit different routes to choose different trigonometric representations.

BMHV structure

Before signature extraction, require the absence of

SPE,DiracTrace,DiracGamma,DOT,D,

and every temporary tensor-reduction dimension. Your measured coefficients already satisfy this criterion.

A remaining physical Levi-Civita contraction or pseudoscalar structure must be reduced to a fixed four-dimensional basis with a fixed orientation convention. It may then be part of σ
BMHV
	​

.

Gamma and related analytic objects

Treat maximal occurrences of

Γ(z),B(x,y),(a)
n
	​

,
2
	​

F
1
	​

(a,b;c;z),logz,Li
n
	​

(z),ζ
n
	​


as inert objects, including their complete arguments.

A useful exact canonicalization is allowed for integer Gamma shifts:

Γ(z+n)=(z)
n
	​

Γ(z),n∈Z,

provided one fixed reference form is used. Reflection, duplication, and general hypergeometric transformations should not be introduced merely for simplification.

Noninteger powers

For

X
a+bϵ
,a+bϵ∈
/
Z,

the complete pair

(X,a+bϵ)

belongs to the analytic signature.

Do not use

(XY)
a+bϵ
=X
a+bϵ
Y
a+bϵ

unless positivity and the branch identity have been separately certified.

Half-integer powers may be reduced only when their bases have been expressed as monomials of individually positive generators in the physical chamber. All other algebraic powers remain inert.

Exactness versus completeness of simplification

This grammar is exact even if two structurally different Gamma or hypergeometric objects later turn out to be analytically related: failing to identify them only misses a possible cancellation.

To claim that no cancellation has been lost between different signatures, one needs either:

a proved independent basis over

K=Q(s,t,u,ϵ,color),

or

a canonicalization that places every known identity into the same signature.

For the present TT coefficient stage, the strongest independently justified sectors are:

different PDF/FF products;

different Fourier harmonics;

different fixed BMHV tensor structures;

different certified radical parities.

Gamma and noninteger-power signatures should be regarded as conservative structural sectors unless their canonical relations have been fixed explicitly.

4. Smallest exact units for NNLO streaming

There are two relevant sums.

For target α,

C
α
	​

=
p∈P
α
	​

∑
	​

P
p
	​

c
pα
	​

,

where P
α
	​

 contains all pairs contributing to G
α
	​

.

For master m,

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

,

where T
m
	​

 contains all targets contributing to M
m
	​

.

Before Kira

The smallest unit that may be simplified without forfeiting cancellations among pairs is the complete target coefficient

C
α
	​

.
	​


A single pair coefficient is not such a unit: another pair can cancel its radical, color, azimuthal, or rational terms.

Thus each NNLO target fibre should be completed from all 1,296 pair records before authoritative target normalization.

After Kira

The smallest unit that guarantees every cancellation in a fixed master basis is the complete master coefficient

K
m
	​

.
	​


But it need not be materialized as one expression.

If a certified analytic basis

{A
σ
	​

}

has been chosen such that

K
m
	​

=
σ
∑
	​

A
σ
	​

K
m,σ
	​


is a direct decomposition over the rational coefficient field, then the smallest independently simplifiable unit is

K
m,σ
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
α,σ
	​

.
	​


This block contains:

every pair contribution to each target;

every target contribution to master m;

every cancellation within analytic structure σ.

It is therefore the preferred streaming unit for the 44,877-target,
342-master NNLO calculation.

Production streaming order

For each target α:

read all pair contributions belonging to α;

remove the already certified global pair factor;

form the exact complete C
α
	​

;

apply the hadronic map and branch registry;

split C
α
	​

 into analytic structures;

normalize each C
α,σ
	​

;

stream

R
αm
	​

C
α,σ
	​


into the appropriate on-disk (m,σ) accumulator.

For each (m,σ):

combine its complete list of target contributions in a balanced tree;

merge equal denominator buckets exactly;

apply only bounded rational cleanup;

retain the exact input block on timeout.

Finally reconstruct

K
m
	​

=
σ
∑
	​

A
σ
	​

K
m,σ
	​


and verify the complete master coefficient against the declared common hard factor.

If the analytic structures are only structurally distinct and their independence has not been established, this streaming still preserves the exact answer, but it may miss cancellations between two analytically equivalent structures. In that situation, the mathematically guaranteed final unit remains the complete K
m
	​

, and the signature decomposition is a memory-safe intermediate representation rather than a proof of canonical minimality.

Concrete conclusion

The measured NLO TT data justify three changes:

retain the 664-byte common pair factor outside target and Kira formation;

use complete-target physicalization and cleanup before Kira as the reference ordering;

replace monolithic master construction by complete per-master, per-signature accumulation.

They do not yet justify making complete pair-level simplification the default. The A/B/D fresh-process measurements should decide that remaining question.
