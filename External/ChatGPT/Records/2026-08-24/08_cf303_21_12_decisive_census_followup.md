# CF303 21 12 Decisive Census Followup

## Question

_The question was not preserved in the local bridge record._

## Pro response

Verdict

GO, with one mandatory correction/check before installation: the strip residual must be derived from the certified transformation convention, not accepted from the displayed sign formula by inspection.

Under the convention previously established in this conversation,

B
ˉ
new
	​

=
B
ˉ
+ϵ(EG−GC)−dG,

the exact dlog residual is

F
21,12
	​

+ϵ(E
21
	​

D
21,12
	​

−D
21,12
	​

C
12
	​

)−dD
21,12
	​

−ϵ
a
∑
	​

M
a
	​

dlogL
a
	​

=0.
	​


Your displayed equation

F
21,12
	​

+dD
21,12
	​

−ϵ(E
21
	​

D
21,12
	​

−D
21,12
	​

C
12
	​

)=0

is equivalent only if the stored D is defined as −G, the forcing has the opposite sign, and the target block is zero rather than a nonzero dlog form. Bind this explicitly to the already certified sector-19 convention. The safest check is to construct U and extract the transformed block directly, avoiding any manual sign translation.

A. Treat it as an ordinary Kallen23 rational strip

There is no mathematical reason to retain root 3.

The complete dependency-closed data

E
21
	​

,C
12
	​

,F
21,12
	​


lie in

K
12
	​

=Q(x,y,ϵ)(r
1
	​

,r
2
	​

),

and Kallen23 gives a rational differential-field presentation of that field. Root 3 is absent from the operator as well as the forcing, so this is not merely a cancellation in one inhomogeneous term.

More formally, the full strip is invariant under the root-3 involution. Even if a solution were first found in the full three-root field, Galois averaging would produce a solution in K
12
	​

, provided the normalization conditions are defined over K
12
	​

. Algebraic dlog letters likewise descend through conjugate products and norms. There is therefore no intrinsic role for root 3 in this strip.

“Branch-free” should mean:

no residual radical remains in the Kallen23 coefficient field;

no undeclared square class appears;

every chart expression is rational in the chart variables.

It does not mean that the source-field gauge is invariant under r
1
	​

,r
2
	​

 sign changes. The sheet information is encoded in the chart inverse and must be restored when pushing back.

B. Pullback/solve/certify order

The proposed order is correct, subject to four exact invariants.

1. Differential-field pullback

For both one-form components, prove independently that

A
p
	​

=x
p
	​

A
x
	​

+y
p
	​

A
y
	​

,
A
q
	​

=x
q
	​

A
x
	​

+y
q
	​

A
y
	​

.

Require:

exact chart and inverse compositions;

direct-Jacobian rather than inverse-Jacobian orientation;

declared Kallen23 sheet and base-point signs;

no unresolved nested radical after operand-local canonicalization;

exact source-grade roundtrip.

Because of the confirmed Kallen23 wrapper defect, Together alone is not an acceptable inverse-roundtrip test. Equality must be checked after reduction to the ordered source basis

{1,r
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

}.
2. Fresh strip preparation

Reuse the mature rational solver, but regenerate from the 21→12 chart strip:

support;

denominator and pole data;

alphabet;

normalization columns;

finite-field preparation;

elimination plan.

Do not reuse the sector-19 ansatz or constrained plan merely because the chart is the same.

3. Direct transformation identity

Before applying the right action, construct the cumulative sector-21 transformation and verify directly

Block
21,12
	​

(U
21
−1
	​

AU
21
	​

−U
21
−1
	​

dU
21
	​

)=ϵ
a
∑
	​

M
a
	​

dlogL
a
	​

.

This is the strongest low-cost protection against:

D↔−G;

wrong derivative sign;

wrong left/right multiplication;

solving against the wrong accumulated frame;

accidentally targeting zero instead of the returned dlog block.

4. Cumulative row-state invariant

Let N
old
	​

 contain the already solved 21→k blocks and N
12
	​

 contain only D
21,12
	​

. Verify

N
old
	​

N
12
	​

=N
12
	​

N
old
	​

=0,

so that

U
21
new
	​

=I+N
old
	​

+N
12
	​

,
(U
21
new
	​

)
−1
=I−N
old
	​

−N
12
	​

.

Then verify that every previously certified 21→k, k>12, block remains unchanged after adding D
21,12
	​

.

The new state must be bound to the exact accumulated parent-state hash and written atomically. This prevents applying the right action twice or applying it to a pre-sector-16/raw frame.

C. Use the certified channel tensor

The solver should consume the certified source channel tensor, pulled directly into Kallen23.

For a source element

f=f
0
	​

+f
1
	​

r
1
	​

+f
2
	​

r
2
	​

+f
12
	​

r
1
	​

r
2
	​

,

substitute the certified rational Kallen23 images

r
1
	​

↦ρ
1
	​

(p,q),r
2
	​

↦ρ
2
	​

(p,q),

and form

f
	​

=f
0
	​

+f
1
	​

ρ
1
	​

+f
2
	​

ρ
2
	​

+f
12
	​

ρ
1
	​

ρ
2
	​

.

Then apply the one-form Jacobian componentwise.

This route is both safer and cheaper because:

the source root ABI is explicit;

root 3 grades are provably absent;

mask ordering is fixed;

no giant radical expression needs normalization;

the known nested-radical weakness of source-expression pullback is avoided;

all cancellations that selected the minimal field are preserved.

The composed source expression should remain an independent oracle, not the construction input. The report’s established production architecture likewise favors exact leaf/channel propagation and rational-grade summation over whole-expression algebraic normalization. 

codex_overnight_optimization_tr…

The required channel-input gate is:

Ψ
K23
	​

(Φ
K23
	​

(E
21
	​

,C
12
	​

,F
21,12
	​

))=(E
21
	​

,C
12
	​

,F
21,12
	​

)

exactly in all four source grades and both differential components.

D. Shortest nonredundant D
21,12
	​

 certificate

The minimal theorem-level certificate is:

Input provenance

accumulated parent-state hash;

census hash;

E
21
	​

,C
12
	​

,F
21,12
	​

 hashes;

Kallen23 chart, inverse, branch, ABI, and normalizer hashes.

Exact rational reconstruction

stable constrained normalization across construction primes;

held-out regulator values;

unseen-prime zero residual;

exact reconstructed gauge, letters, and residue matrices.

Exact chart identity

F
+ϵ(
E
D
−
D
C
)−d
D
=ϵ
a
∑
	​

M
a
	​

dlog
L
a
	​


with exact dlog potentials. Closed one-forms alone are insufficient for final strip certification under the existing contract. 

codex_overnight_optimization_tr…

Exact source-field identity
Push D and the letters back and reduce the residual coefficientwise:

R
0
	​

+R
1
	​

r
1
	​

+R
2
	​

r
2
	​

+R
12
	​

r
1
	​

r
2
	​

=0,

requiring

R
0
	​

=R
1
	​

=R
2
	​

=R
12
	​

=0.

This exact four-grade identity is stronger than evaluating finitely many sign sheets. Branch-point evaluations and wrong-sign mutants remain implementation oracles.

Unipotent installation certificate

direct transformed-block extraction;

two-sided inverse of the cumulative U
21
	​

;

preservation of all earlier 21→k blocks;

exactly one atomic application to the pinned accumulated state.

Family-level regulator factorization remains separate. If the returned residue matrices depend on ϵ, the strip is DLogFormCertified, not yet a final canonical epsilon-form family.

Exact execution sequence

Import the immutable four-grade E
21
	​

,C
12
	​

,F
21,12
	​

 tensors.

Map those tensors directly to Kallen23 and apply the direct one-form Jacobian.

Verify exact rationality and source/chart roundtrip.

Generate a fresh rational-strip preparation and constrained plan.

Reconstruct D
21,12
	​

, letters, and residues with the ordinary rational solver.

Verify the exact chart dlog identity.

Push the result back and verify the exact four-grade source residual.

Construct the cumulative U
21
	​

, extract the transformed block directly, and verify the earlier strips are unchanged.

Apply the right action once to the exact accumulated parent state and checkpoint atomically.

Assemble 21→11 from that new state.

No three-root or residual-quadratic solve is justified by the certified evidence.
