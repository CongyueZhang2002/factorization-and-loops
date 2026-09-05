# Triple Root Maple Slowdown

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation.  Do not
restart from generic advice: the attached exchange note contains the exact
physical profile from the latest CF259/CF300/CF303 run.

The decisive new facts are these:

- CF300 `(12,6)` and CF303 `(21,12)` both solved their hard Kallen23 chart
  system.  Each had 820 candidate monomials / 6680 unknowns, learned 620
  monomials, reached rank 5080/nullity 0, used five primes, passed an exact
  unseen-prime residual, and finished the finite-field solve in 1001.4 s and
  1024.3 s respectively.
- Their pulled-back 2x4 gauges have leaf count 332,578.  The two generated
  Maple input payloads are byte-identical except for the output pathname.
- Two parallel Maple `evala(Normal)` processes therefore duplicated the same
  computation.  Each used about 8--9 GiB RSS and 2.3--2.5 CPU cores, but after
  about 18 minutes had completed only 1 of 8 entries.  This is now the dominant
  blocker.
- CF259 separately solved all 20 sector-21 strips in about 257 s, then lost
  roughly 21 minutes to entrywise `Together` while propagating `SInverse`; the
  same result is immediately canonicalized again by regulator factorization.

We have an uncommitted candidate that (a) defers that first redundant
`SInverse` `Together`, and (b) canonicalizes Maple arrays entry by entry with a
shared content cache so identical families compute each entry once and can
resume completed entries.  We will keep the existing per-off-diagonal modular
block check after Maple simplification; the user explicitly does not want a
new redundant production check.

Please give a critical, algorithm-focused recommendation on the following.

1. Is generic Maple `evala(Normal)` the wrong object here?  Once the pulled-back
   gauge is known to lie in
   `Q(x,y)[r1,r2]/(r1^2-d1, r2^2-d2)`, can we reduce directly and uniquely into
   `{1,r1,r2,r1*r2}` and normalize only the four rational coefficient
   functions?  Spell out a practical algorithm that avoids expansion blow-up,
   including how to rationalize denominators and reduce products/powers of
   radicals.  Would Maple, FLINT, Singular, or custom sparse coefficient maps
   be the best implementation level?
2. If the gauge input and output are mathematically identical up to algebraic
   normalization, is entrywise content sharing across CF300/CF303 sound?  What
   is the minimal semantic cache key?  We want the mathematical expression,
   variables/root relations, branch convention, and normal-form algorithm
   version—not process hashes, helper count, or other execution provenance.
3. Is deferring `Together` for the exact multi-term `SInverse` sum until the
   immediately following regulator factorization sound, assuming no consumer
   observes the intermediate representation?
4. The finite-field prime artifacts correspond to a fixed coordinate layout
   and affine section.  Which mathematical fields must be identical to reuse
   them safely?  Our current view is support/unknown layout, numerator and
   denominator degrees, rank/nullity, and normalization columns; row basis,
   pilot nonce, transcript, and thread count should not matter.
5. What is the highest-payoff next experiment, with a bounded pass/fail test?
   In particular, estimate whether four-basis coefficient reduction could turn
   the observed ~18 minutes per first entry into seconds/minutes, or whether
   the rational coefficient normalization will remain asymptotically just as
   hard.

Please distinguish measured conclusions from hypotheses.  Avoid recommending
more hashes or duplicated checks; focus on the algebraic normal form and the
dominant computation.

## Pro response

Recommendation

GO: replace generic Maple evala(Normal) for this path with a direct four-channel normal form in

K=Q(x,y)[r
1
	​

,r
2
	​

]/(r
1
2
	​

−d
1
	​

, r
2
2
	​

−d
2
	​

).

GO: retain simple entrywise content sharing and resumability.

GO, conditionally: defer the first SInverse Together until regulator factorization, provided no intermediate consumer inspects canonical numerator/denominator structure.

NO-GO: reuse finite-field prime artifacts based only on support dimensions, degree bounds, rank/nullity, and normalization columns. Those data do not identify an affine system.

The measurements establish that finite-field solving is no longer the blocker: the two hard chart solves completed in about 1000 seconds each, while two identical Maple jobs each consumed 8–9 GiB and reached only one of eight entries after roughly 18 minutes. 

08_three_root_slowdown_and_reco…

 CF259 separately lost about 21 minutes to a Together operation whose result is immediately canonicalized again. 

08_three_root_slowdown_and_reco…

1. evala(Normal) is mathematically valid but algorithmically too general

Maple documents evala(Normal) as computing a factored normal form over general algebraic function fields. That solves a broader problem than the fixed degree-four multiquadratic reduction needed here. 
Maplesoft

For independent square classes d
1
	​

,d
2
	​

, every element of K has a unique representation

f=c
0
	​

+c
1
	​

r
1
	​

+c
2
	​

r
2
	​

+c
12
	​

r
1
	​

r
2
	​

,c
∙
	​

∈Q(x,y).

Once each c
∙
	​

 is put into a fixed reduced rational normal form, the complete result is canonical. There is no need for a general primitive-element computation, generic algebraic factorization, or unrestricted radical normalization.

Best input level: use the chart gauge before source-expression expansion

Do not start from the 332,578-leaf pulled-back expression if the rational Kallen23 chart gauge is still available.

For one chart entry

g(p,q)=
Q(p,q)
P(p,q)
	​

,

and inverse-chart coordinates

p=p(x,y,r
1
	​

,r
2
	​

),q=q(x,y,r
1
	​

,r
2
	​

),

evaluate P and Q directly in the four-channel algebra, then perform one field inversion:

g=P(p,q)Q(p,q)
−1
.

This avoids constructing the large radical expression that Maple subsequently has to undo.

For sparse P,Q, cache powers of p and q, or use a multivariate Horner scheme. An especially useful denominator-clearing form is the following. If

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


in K, choose m,n at least the maximum p,q degrees occurring in both P and Q, and evaluate

P
=
i,j
∑
	​

P
ij
	​

P
p
i
	​

D
p
m−i
	​

P
q
j
	​

D
q
n−j
	​

,

and similarly 
Q
	​

. Common powers cancel between numerator and denominator, and the calculation requires only polynomial operations in the four-channel field followed by one inversion.

Four-channel arithmetic

Represent an element as

[a
0
	​

,a
1
	​

,a
2
	​

,a
12
	​

]⟷a
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

.

Multiplication is

c
0
	​

=
c
1
	​

=
c
2
	​

=
c
12
	​

=
	​

a
0
	​

b
0
	​

+d
1
	​

a
1
	​

b
1
	​

+d
2
	​

a
2
	​

b
2
	​

+d
1
	​

d
2
	​

a
12
	​

b
12
	​

,
a
0
	​

b
1
	​

+a
1
	​

b
0
	​

+d
2
	​

(a
2
	​

b
12
	​

+a
12
	​

b
2
	​

),
a
0
	​

b
2
	​

+a
2
	​

b
0
	​

+d
1
	​

(a
1
	​

b
12
	​

+a
12
	​

b
1
	​

),
a
0
	​

b
12
	​

+a
12
	​

b
0
	​

+a
1
	​

b
2
	​

+a
2
	​

b
1
	​

.
	​


Integer powers use binary exponentiation. A noninteger power must either be one of the declared generators, be reduced by a separately certified branch identity, or fail.

Denominator inversion without general algebraic normalization

Write

z=A+Br
2
	​

,

where

A=a
0
	​

+a
1
	​

r
1
	​

,B=a
2
	​

+a
12
	​

r
1
	​

.

First take the relative norm:

H=A
2
−d
2
	​

B
2
=h
0
	​

+h
1
	​

r
1
	​

,

with

h
0
	​

=a
0
2
	​

+d
1
	​

a
1
2
	​

−d
2
	​

(a
2
2
	​

+d
1
	​

a
12
2
	​

),
h
1
	​

=2(a
0
	​

a
1
	​

−d
2
	​

a
2
	​

a
12
	​

).

Then

H
−1
=
h
0
2
	​

−d
1
	​

h
1
2
	​

h
0
	​

−h
1
	​

r
1
	​

	​

,

and

z
−1
=(A−Br
2
	​

)H
−1
.

Explicitly, with

Δ=h
0
2
	​

−d
1
	​

h
1
2
	​

∈Q(x,y),
z
−1
=
Δ
1
	​

	​

a
0
	​

h
0
	​

−d
1
	​

a
1
	​

h
1
	​

,
a
1
	​

h
0
	​

−a
0
	​

h
1
	​

,
−a
2
	​

h
0
	​

+d
1
	​

a
12
	​

h
1
	​

,
−a
12
	​

h
0
	​

+a
2
	​

h
1
	​

	​

	​

.

This gives the unique four-channel result using only arithmetic in the base rational field.

Avoiding base-field expression swell

Do not call Together after every channel operation. Store each base coefficient as a numerator/denominator pair and use:

cross-cancellation before multiplication;

denominator gcd before addition;

memoization of repeated polynomial products and powers;

one common denominator where naturally produced by the field norm;

final canonicalization only at entry completion.

If the final four channels share a denominator D, normalize D once. Then compute

g
i
	​

=gcd(N
i
	​

,D)

for each channel and return

c
i
	​

=
D/g
i
	​

N
i
	​

/g
i
	​

	​

.

Factor D at most once if exact factor division is cheaper than four independent multivariate gcds.

Best implementation level

Custom four-channel maps with FLINT polynomial arithmetic: preferred production route. The algebraic layer is only a fixed four-component convolution and recursive norm inversion. FLINT’s documented fmpq_mpoly representation stores a rational content together with a primitive integer multivariate polynomial, which is appropriate for sparse exact base-field polynomials. 
Flint Library

Custom Wolfram or Maple prototype: suitable for validating the algorithm on one entry, but retain lazy channel objects rather than ordinary expanded sums.

Maple evala(Reduce) as a lightweight oracle: Maple states that Reduce lowers algebraic powers but deliberately does not rationalize algebraic denominators or cancel numerator/denominator gcds. That makes it closer to the desired first stage than evala(Normal), but explicit tower inversion is still needed. 
Maplesoft

Singular: useful as an independent normal-form checker. Its generic reduce computes normal forms with respect to a standard basis, but Gröbner reduction is unnecessary overhead for two monic quadratic relations whose reduction rules are known explicitly. 
Singular

The recommended architecture is therefore custom sparse channels as the mathematical representation, FLINT as the base-polynomial backend, and Maple/Singular only as oracles.

2. Entrywise sharing between CF300 and CF303 is sound

The two Maple payloads being identical except for the output pathname proves that the current two processes were duplicating the same scalar normalization work. 

08_three_root_slowdown_and_reco…

 Sharing each completed entry is mathematically sound.

Minimal semantic cache key

For one scalar entry, the key should contain only:

The input field element

preferably the role-canonicalized chart rational entry P/Q;

together with the exact inverse chart map used to place it in the source field;

alternatively, a canonical expression DAG after replacing declared roots by formal generators.

The base field

coefficient domain Q;

ordered variables, such as (x,y);

base-polynomial monomial order.

The ordered extension presentation

r
1
2
	​

=d
1
	​

(x,y),r
2
2
	​

=d
2
	​

(x,y);

generator order;

the assignment between physical square roots and r
i
	​

;

any operand-local nested-radical sign normalization.

The output normal-form convention

channel order (1,r
1
	​

,r
2
	​

,r
1
	​

r
2
	​

);

reduced numerator/denominator convention;

denominator sign or leading-coefficient normalization;

normal-form algorithm version.

Do not include:

family name;

output path;

process identity;

helper count;

thread count;

timeout;

transcript;

temporary filenames.

A practical key need not detect all algebraically equivalent syntactic inputs. Role-canonicalized content identity is sufficient to share the byte-identical CF300/CF303 entries without first solving the hard equivalence problem.

Keep the production cache simple:

one scalar entry per record;

one process computes an absent entry;

other processes wait or reuse;

completed entries are immutable;

incomplete entries are ignored and safely recomputed.

The note’s proposed entrywise cache and resumability are therefore appropriate; complex salvage of legacy combined outputs is not needed. 

08_three_root_slowdown_and_reco…

3. Deferring the first SInverse Together is mathematically sound

Yes, under the stated condition that no consumer observes the intermediate canonical representation.

An exact additive expression and its Together form represent the same rational function. If regulator factorization immediately canonicalizes the same object, doing so twice removes no additional mathematical ambiguity.

The deferral remains safe only if, before regulator factorization, no code performs a representation-sensitive operation such as:

extracting numerator or denominator factors;

deciding whether an entry is zero;

comparing entries syntactically;

constructing support or pole data;

assuming one rational denominator;

serializing a format whose reader expects canonical entries.

The clean interface is:

S
deferred
−1
	​

=exact additive DAG,

followed by a single normalization at the regulator-factorization entry point.

Any inverse identity check that requires canonical expressions should occur after that normalization, or use the existing exact modular block check. The measured diagnosis is strong; the physical speedup remains a hypothesis until CF259 is reprofiled, as the exchange note itself correctly states. 

08_three_root_slowdown_and_reco…

4. Prime-artifact reuse requires identity of the affine map, not matching dimensions

The proposed field list is insufficient.

Two unrelated systems can have identical:

support size;

unknown count;

numerator and denominator degrees;

rank;

nullity;

normalization columns.

The mathematical reuse invariant is:

A
p
	​

(ϵ)c=b
p
	​

(ϵ) is the same affine system in the same unknown coordinates.
	​


At minimum, the following must agree.

Unknown-coordinate ABI

ordered gauge matrix indices;

ordered root grades or rational-chart basis;

ordered support monomials;

gauge denominator ansatz;

ordered one-form/letter basis;

ordered residue coordinates;

derivative convention and signs.

Actual coefficient system

chart and coordinate map;

diagonal blocks E,C;

forcing block 
B
ˉ
;

gauge denominator;

one-forms;

regulator image;

prime.

Matching rank and degree metadata is not a substitute for equality of these coefficient functions.

Affine section

normalization coordinates;

normalization values;

treatment of homogeneous freedom.

Sampling data, when the artifact stores evaluated matrices

accepted kinematic points;

point ordering, unless rows are explicitly remapped;

any row scaling whose multiplier must be nonzero at those points.

What may be ignored

worker or pilot nonce;

transcript;

helper count;

native thread count;

elapsed time.

A row basis is mathematically irrelevant only when it differs by an invertible row transformation applied to both A and b. Operationally, an elimination artifact containing row indices cannot simply ignore the change: either remap its selected rows or validate the returned solution against the current complete system.

Likewise:

rank/nullity are derived checks, not identity fields;

numerator/denominator degree bounds govern reconstruction, not the underlying affine map;

support layout is necessary but not sufficient.

For CF300 and CF303, byte-identical Maple normalization payloads prove that their final gauge-normalization tasks coincide. They do not by themselves prove that every earlier finite-field prime artifact represents the same affine system. That requires equality of the chart strip and unknown-coordinate ABI listed above.

5. Highest-payoff bounded experiment
Experiment: direct four-channel normalization of one entry

Use the already completed first Maple entry as the oracle.

Stage 1 — avoid source-expression materialization

Start from its chart rational function and inverse chart map. Evaluate it directly in the four-channel field using:

cached sparse powers;

common-denominator polynomial evaluation;

one tower inversion.

Record separately:

chart-polynomial evaluation time;

field inversion time;

peak channel term counts;

memory.

Stage 2 — canonicalize four rational coefficients

Normalize the four Q(x,y) coefficients independently, sharing denominator work.

Record:

polynomial expansion time;

gcd time;

numerator/denominator term counts;

peak memory.

Stage 3 — compare

Require:

exact agreement with the completed Maple entry;

exact recomposition in the four-channel field;

the existing per-off-diagonal modular check.

No new production check is needed.

Pass/fail thresholds

Given the measured first-entry time of roughly 18 minutes:

Strong pass: at most 120 seconds and at most 2 GiB for one entry.

Usable pass: at least 5× faster than Maple, with bounded memory.

Marginal: 3–5 minutes. Entry sharing still helps the duplicate pair, but the algebraic method needs further base-field optimization.

Reject as production replacement: more than 5 minutes per entry or less than 3× improvement.

A one-entry pilot is enough to make this decision.

Expected outcome

Measured: generic Maple required roughly 18 minutes and 8–9 GiB to finish one entry. 

08_three_root_slowdown_and_reco…

Hypothesis: the four-channel algebraic reduction itself should fall to seconds or tens of seconds because:

the extension dimension is fixed at four;

root products reduce through explicit formulas;

the chart numerator and denominator can be evaluated without constructing a large radical expression;

only one algebraic inversion is required.

Remaining uncertainty: final multivariate rational normalization may still take tens of seconds or several minutes if the four coefficient numerators and denominators become dense or have expensive gcds. It should not be assumed to be cheap merely because the extension reduction is cheap.

If Stage 1 is fast but Stage 2 remains slow, the next route is not a return to evala(Normal). It is:

evaluate the source element modulo several primes and source points;

project its four sign values onto the four channels;

reconstruct the four rational coefficient functions independently;

verify exact field recomposition.

That reuses the existing finite-field machinery and avoids characteristic-zero multivariate gcds on giant expressions.

Immediate order

Keep the simple shared entry cache and resumability.

Keep the CF259 deferred-Together patch, subject to the single-consumer condition.

Run one direct four-channel entry pilot from the chart gauge, not from the 332,578-leaf source expression.

Use custom channel arithmetic with FLINT-backed base polynomials.

Retain the implementation only if it produces at least a 5× entry-level wall reduction.

Tighten finite-field artifact reuse around equality of the actual affine system; do not use rank/nullity and degree metadata as the identity criterion.

The highest-payoff mathematical change is the direct fixed-basis field reduction. Cache sharing removes the observed duplicate CF300/CF303 work, but only the four-channel normal form removes the underlying Maple bottleneck.

## Sources sent to Pro

- Original source reference: `/home/maxzhang/factorization-and-loops/Exchange/Codex/2026-08-28/08_three_root_slowdown_and_recovery.md` (not archived with this exchange)
