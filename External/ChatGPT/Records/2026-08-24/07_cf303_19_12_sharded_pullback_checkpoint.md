# CF303 19 12 Sharded Pullback Checkpoint

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation with its full history. This is the next checkpoint in the same CF303 exact triple-root campaign. Do not treat it as a standalone inquiry.

We have now reached the nonzero sector-19-to-sector-12 Kallen23 gauge needed by the dependency-closed 21->12 recurrence. The certified chart gauge is 4x4 with 53,353 leaves and roots {1,2}.

The original monolithic exact source pullback completed and certified successfully:

- source gauge: 4x4, 1,534,219 leaves;
- source radical census: roots {1,2}, root 3 absent, constant field Q;
- accepted Kallen23 branch signs: {{1,1},{1,-1}};
- exact chart/source roundtrip and chart certificate passed;
- wall time: 1,331 s.

We also implemented a scratch-only, fail-closed row-sharded route without modifying the package:

- shard 1, rows {1,2}: 333.8 s, 496,427 source leaves;
- shard 2, row {3}: 408.8 s, 545,865 source leaves;
- shard 3, row {4}: 385.0 s, 491,929 source leaves;
- independent per-shard exact sheet/radical certificates: 68.0, 83.4, and 66.4 s;
- each certificate found roots {1,2}, no root 3 or undeclared radical, and the same accepted sheet set {{1,1},{1,-1}};
- the aggregator intersects the accepted sheet sets and unions the exhaustive row-wise radical censuses, pins all shard hashes and input hashes, and took 1.2 s;
- an independent oracle-equivalence mission imported both full outputs and found the entire source gauge structurally identical entry-for-entry (`SameQ` true), with identical chart gauge, root set, and accepted sheet set.

Thus the optimized certified wall path is about max(333.8,408.8,385.0) + max(68.0,83.4,66.4) + 1.2 = 493.4 s, versus 1,331 s monolithic, roughly 2.7x faster. Package source remains unmodified.

Three additional exact shards are now decomposing only these needed source-gauge rows into the common rank-3 eight-grade ABI. Every scalar is first classified by active root subset, decomposed only over that subset, lifted to the global little-endian mask ABI, and composed back exactly. The 21->12 census will import these pinned channels rather than serially decompose the 1.53-million-leaf gauge again.

The planned dependency-closed source-frame recurrence for the next strip is

  A_19,12^cur = A_19,12 + eps(E_19 D_19,12 - D_19,12 C_12) - dD_19,12,

  Bbase_21,12 = A_21,12
                + A_21,20 D_20,12
                + A_21,19 D_19,12
                + A_21,18 D_18,12,

  F_21,12 = Bbase_21,12
             - D_21,20 A_20,12^cur
             - D_21,19 A_19,12^cur
             - D_21,18 A_18,12^cur
             - D_21,15 A_15,12^cur
             - D_21,14 A_14,12^cur.

Here D_20,12 = D_18,12 = 0 and A_20,12^cur = A_18,12^cur = 0 exactly; D_21,17 = D_21,16 = D_21,13 = 0 exactly; D_19,13..17 = 0, while the only potentially relevant D_19,18 path multiplies A_18,12^cur = 0. The implementation nevertheless materializes/checks all these zero paths and performs local/global compose checks, a final full-rank forcing cross-check, and independent radical-classifier agreement.

Please assess concisely but technically:

A. Is the row-sharded exact source pullback/certificate construction theorem-level equivalent to the monolithic matrix check, given that matrix equality, root census, and branch roundtrip are entrywise predicates, the global accepted-sheet set is the intersection of exhaustive shard sheet sets, and we additionally obtained full structural identity with the monolithic oracle? Name any hidden global invariant we still need.

B. Confirm the 21->12 recurrence and the safety of importing pinned, exactly round-tripped D_19,12 channel shards into the global xor-grade arithmetic instead of decomposing the assembled source gauge serially again. Is the final full-rank forcing decomposition plus exact channel/expression roundtrip the smallest adequate independent acceptance check?

C. If the exact 21->12 census is the first strip whose forcing or full strip genuinely retains all three roots and no joint rational chart exists, which pilot should be attempted first to avoid a dead end: (i) direct eight-grade multiquadratic finite-field sampling/reconstruction in the identity frame, or (ii) Kallen23 pair-chart solving with the residual third root retained as a quadratic extension over the rational chart? Give the smallest decisive pilot and failure criterion before scaling to the full strip.

## Pro response

A. Row-sharded source pullback

Yes. The sharded construction is theorem-level equivalent to the monolithic matrix pullback.

Coordinate substitution, algebraic normalization, source radical decomposition, branch roundtrip, and equality of the chart/source gauge are all entrywise predicates. For a row partition

{1,2,3,4}=I
1
	​

⊔I
2
	​

⊔I
3
	​

,

certifying every entry in every I
s
	​

 certifies the complete matrix. The global valid-sheet set is correctly

Σ
global
	​

=
s
⋂
	​

Σ
s
	​

.

The subsequent full-matrix SameQ comparison with the monolithic oracle removes the remaining practical concern that the aggregator might have reordered or omitted entries.

The global invariants that must remain in the aggregate manifest are:

Exact partition: every row appears exactly once, with original row and column ordering restored.

Common algebraic ABI: identical Kallen23 chart, inverse, root order, branch-label convention, constant field, and nested-radical normalizer.

Common provenance: all shards refer to the same chart-gauge hash, source family frame, and solution hash.

Common sheet: Σ
global
	​


=∅, with one selected sheet recorded globally rather than independently per shard.

Common generic open set: the product of all shard gauge/chart denominators is not identically zero; preferably record one exact generic point avoiding the complete union of exclusions.

Differential compatibility: the same certified map must be used later for dD
19,12
	​

, not merely for entrywise value substitution.

There is no additional matrix determinant condition on D
19,12
	​

: it is an off-diagonal gauge block inside a unipotent transformation, not itself the complete change-of-basis matrix.

The row-sharded timing is therefore a valid certified optimization, not merely a heuristic parallelization.

B. The 21→12 recurrence and imported channels

The invariant recurrence should be stated using one accumulated pre-sector-21 connection 
A
:

F
21,12
	​

=
A
21,12
	​

−
k=13
∑
20
	​

D
21,k
	​

A
k,12
	​

.
	​


Your expanded expression is correct provided

B
21,12
base
	​

=
A
21,12
	​


and each displayed A
k,12
cur
	​

 equals the corresponding 
A
k,12
	​

.

The nontrivial terms then reduce to the ones you listed because of the certified zeros:

D
20,12
	​

=D
18,12
	​

=0,
D
21,17
	​

=D
21,16
	​

=D
21,13
	​

=0,

and the 19→18→12 path vanishes because

A
18,12
cur
	​

=0.
One frame condition to check explicitly

If the symbols A
21,12
	​

, A
21,15
	​

, and A
21,14
	​

 in the expanded formula are raw blocks rather than blocks in the accumulated lower-sector frame, then right-action contributions such as

A
21,15
	​

D
15,12
	​

,A
21,14
	​

D
14,12
	​

,

and any other nonzero A
21,k
	​

D
k,12
	​

 must either be added or certified zero.

The safest certificate is therefore not the expanded formula by itself, but

B
21,12
base
	​

=
exact
A
21,12
	​

.

Similarly,

A
19,12
cur
	​

=A
19,12
pre
	​

+ϵ(E
19
	​

D
19,12
	​

−D
19,12
	​

C
12
	​

)−dD
19,12
	​


is correct only when A
19,12
pre
	​

 already contains every earlier recursive contribution used when solving 19→12.

Importing the pinned channel shards

This is safe. There is no reason to decompose the 1.53-million-leaf source gauge again if every scalar shard has:

Compose
local
	​

∘Decompose
local
	​

=id,
Compose
123
	​

∘Lift
local→123
	​

∘Decompose
local
	​

=id,

with the fixed little-endian mask ABI and source hashes.

The imported artifact must additionally certify:

dLift(D
19,12
	​

)=Lift(dD
19,12
	​

),

because A
19,12
cur
	​

 uses the derivative of the gauge.

This is the same exact leafwise architecture endorsed by the earlier evidence ledger: retain the forcing as base + sum(products), decompose leaves separately, lift them into the global basis, and only then combine rational grade channels. 

codex_overnight_optimization_tr…

 The prior sidecar also required exact roundtrips before lifting each recursive product. 

codex_overnight_optimization_tr…

Smallest adequate independent check

For the census, the following is sufficient:

exhaustive, hash-bound recurrence-leaf manifest;

exact local/global roundtrip of every imported leaf;

exact XOR-grade assembly;

exact final channel composition;

exact equality to an independently assembled source recurrence, or an equivalent proof that the complete source leaf DAG maps homomorphically to the channel DAG;

independent radical-classifier agreement.

A compose/decompose roundtrip of the final channel object alone would be partly tautological. It becomes decisive only when the object being compared is the independently specified source recurrence.

For the finished gauge, add:

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

=ϵ
a
∑
	​

R
a
	​

dlogL
a
	​


exactly in the source field, plus chart/source roundtrip, dlog potentials, and the cumulative unipotent row certificate.

The monolithic direct-expression oracle is then adversarial redundancy, not a prerequisite.

C. First genuine three-root pilot

Attempt Kallen23 plus one residual quadratic root first, not the direct eight-grade identity-frame reconstruction.

The certified field isomorphism has the form

Q(x,y,ϵ)(r
1
	​

,r
2
	​

,r
3
	​

)≅Q(p,q,ϵ)(R),R
2
=F(p,q),

so this loses no possible gauge. It reduces the algebra from eight source grades to two chart grades.

Kallen23 is the natural first pair chart here because:

the large D
19,12
	​

 gauge was originally reconstructed there;

roots r
1
	​

,r
2
	​

 become rational;

only the residual r
3
	​

 grade remains;

the already imported source channels can be mapped leafwise without recreating the monolithic source expression.

Smallest decisive pilot

Do not begin with a complete reconstruction. Run this bounded pilot:

Exact field conversion

Map the unique scalar operand DAG for

E
21
	​

,C
12
	​

,F
21,12
	​


into k(R) operand-locally.

Require:

R
2
=F,

exact source/chart roundtrip, differential compatibility, no undeclared radical, and both R-branches.

Because of the confirmed Kallen23 nested-radical defect, this gate must perform operand-local algebraic normalization before source roundtrip; Together alone is not an acceptable criterion.

Transport one fixed ansatz space

Use a source-defined support/one-form space and transport it through the field isomorphism. Do not compare independently guessed rectangle supports in the two representations.

Common-image modular comparison

At one good prime and regulator value, then one independent second image:

assemble the rank-one system;

assemble a small identity-frame eight-grade oracle on the same source points;

compare equations after the exact field/sign transform;

require identical consistency, rank, nullity, and constrained normalization.

Record cost metrics

Compare:

compiled monomial counts;

unknown count;

exact expression bytes;

accepted-point rate;

one-image assembly wall.

Since the grade count drops from eight to two, the pair-chart representation can tolerate approximately a fourfold increase in chart support before losing its basic unknown-count advantage:

2N
chart
	​

≲8N
source
	​

⟺N
chart
	​

≲4N
source
	​

.

This is only a preflight metric; actual residue and alphabet counts must also be included.

Continue criterion

Scale the rank-one route when:

all exact field-map gates pass;

two independent modular images have stable rank/nullity and normalization;

the transported ansatz column space agrees with the identity-frame oracle;

and the rank-one compiled system is materially smaller or faster.

Failure criterion

There are two different failure classes.

Mathematical failure:

the claimed map is not a differential-field isomorphism;

the third root cannot be reduced to one squarefree residual generator;

or a later exact divisor/de Rham calculation proves that the required forms are not algebraic dlogs.

None is currently expected.

Implementation no-go for Kallen23:

operand-local normalization cannot be made fail-closed;

chart support or expression swell exceeds the eight-grade cost enough to remove the two-grade advantage;

or chart assembly is slower despite caching.

An inconsistent finite ansatz is not by itself a failure of the pair-chart representation. Unless the source and chart ansatz spaces are proved equivalent, it is only another support/alphabet failure.

The direct eight-grade solver should therefore remain the independent identity-frame oracle and fallback, not tonight’s first full pilot.
