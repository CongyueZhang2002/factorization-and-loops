# CF303 Sector21 18 Checkpoint Followup

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation with its full history. This is the next checkpoint in the same CF303 campaign, not a new standalone assessment.

We completed the dependency-closed 21->18 assembly after exact source-frame solutions for 21->20 and 21->19:

- D_21,20: exact Bilinear115 source solution, active root {3}.
- D_21,19: exact Kallen2 source solution, active root {1}.
- D_20,18: exact Bilinear115 source gauge, active root {3}.
- D_19,18: exact Kallen23 chart gauge pulled exactly to the source field, roots {1,2}; root 3 absent.
- raw A_21,17 is exactly zero, so there is no omitted row-17 path.

We assembled in the current source frame

  A_20,18^cur = A_20,18 + eps(E_20 D_20,18 - D_20,18 C_18) - dD_20,18,
  A_19,18^cur = A_19,18 + eps(E_19 D_19,18 - D_19,18 C_18) - dD_19,18,

  Bbase_21,18 = A_21,18 + A_21,19 D_19,18 + A_21,20 D_20,18,

  F_21,18 = Bbase_21,18 - D_21,20 A_20,18^cur - D_21,19 A_19,18^cur.

The optimized exact implementation decomposes each leaf once into the common ordered basis

  {1,r1,r2,r1 r2,r3,r1 r3,r2 r3,r1 r2 r3}

(the package mask ABI is little-endian), performs differentiation and every matrix product in exact xor-grade arithmetic, cancels grade by grade, then composes only the final 2x2 one-form. Every input scalar decomposition has the package's exact compose check; the final forcing has both an exact channel compose/decompose roundtrip and exact radical-classifier agreement.

Certified result:

- status: CF303Sector2118DependencyClosedChannelCensusPassedV2
- forcing root indices: {1}
- full strip root indices: {1}
- nonzero grades: {0,1}
- selected minimal chart: Kallen2
- all exact checks true, including raw 21->17 zero, final channel roundtrip, final expression roundtrip, channel/classifier agreement
- leaf decomposition: 28.703 s
- current lower blocks: 0.207 s
- base: 0.560 s
- forcing: 0.823 s
- compose: 0.001 s
- roundtrip: 2.223 s
- total mission wall: 38.36 s
- census SHA-256: 84fe3ac1ce855d130d1e13c7c46dac59944a4aec1c377536202c26a63bda8570
- summary SHA-256: ae3bc5126cd2ad315ebb3c4ad3844a0335199d9706e933e6bf178a68ae853c9d
- package source was not modified.

For comparison, the independent direct source-expression implementation needed 701.3 s just to form A_20,18^cur and A_19,18^cur and is still normalizing the base/product expression. We are retaining it only as an independent oracle. The exact Kallen2 finite-field eps-form solve of the immutable grade-wise strip is now running (2x2->2x2; support census degree 17, initial 171 monomials / 724 unknowns).

Please assess concisely but technically:

A. Verify the recurrence and whether the exact grade-wise construction plus per-leaf compose checks, final compose/decompose roundtrip, and independent radical census is theorem-level sufficient for selecting the minimal field/chart before the slower direct-expression oracle finishes.

B. Recommend the smallest additional acceptance cross-check, if any, for the finished Kallen2 gauge. Is an exact source-frame strip residual from SolveEpsFormStripInFrame plus its chart/source roundtrip and dlog certificate sufficient, with the direct-expression oracle treated as adversarial redundancy rather than a prerequisite?

C. The roots from already-solved 21->20 ({3}), 21->19 ({1}), and the intermediate 19->18 gauge ({1,2}) cancel down to only {1} in the dependency-closed 21->18 forcing. Confirm that this is another concrete demonstration that roots from different paths must not be unioned before exact recurrence cancellation, and that we should continue downward strip by strip rather than promote sector 21 to a triple extension.

D. The remaining 28.7 s is leaf decomposition in the full rank-3 basis. Would it be safe and worthwhile to classify each scalar's active subset, decompose only over that subset, then use the package's exact `multiquadraticLiftLocalChannels` map into the global 8-grade ABI, provided each local and global composition is checked exactly? State the invariants needed to make this optimization fail-closed.

Also note one confirmed package gap discovered during this chain: Kallen23 inverse coordinate pullback can create a nested radical algebraically inside the declared multiquadratic field, while `Together` alone does not canonicalize it before the wrapper's source roundtrip. We recorded a generic defect report and exact CF303 evidence in Exchange; no package edit was made. If this changes any recommended chart-transition invariant, say how.

## Pro response

A. Recurrence and field selection

The recurrence is correct, provided every A
k,18
	​

 on the right-hand side is the block in the same accumulated source-variable frame, immediately before that row’s own gauge is applied—not a raw original-family block.

Let 
A
 denote the connection after the already certified sector-19 and sector-20 row transformations. Because D
20,19
	​

=0,

A
21,18
	​

=A
21,18
	​

+A
21,19
	​

D
19,18
	​

+A
21,20
	​

D
20,18
	​

,

which is your B
21,18
base
	​

. The certified current lower blocks are

A
20,18
	​

=A
20,18
cur
	​

,
A
19,18
	​

=A
19,18
cur
	​

.

After the already solved D
21,20
	​

 and D
21,19
	​

 are included, the forcing for the unknown D
21,18
	​

 is therefore

F
21,18
	​

=
A
21,18
	​

−D
21,20
	​

A
20,18
	​

−D
21,19
	​

A
19,18
	​

.
	​


There is no omitted derivative term involving D
21,20
	​

 or D
21,19
	​

: dN
21
	​

 has support only in their own columns. There is no extra NAN term because a one-row strictly lower-block transformation satisfies N
21
	​

A
N
21
	​

=0 for a lower-triangular connection.

One clarification: raw A
21,17
	​

=0 is not needed for the 21→18 formula. It becomes relevant when the recursion reaches j≤17.

Is the grade-wise construction theorem-level sufficient?

Yes. Given:

exact square-class rank three and a fixed ordered basis;

exact decomposition and composition of every scalar leaf;

exact XOR multiplication and differentiation;

a complete, hash-bound recurrence-leaf manifest with signs and matrix order;

exact final channel composition/decomposition;

agreement with an independent radical classifier;

the channel result is algebraically identical to the source recurrence. A whole-expression Together computation is not logically required.

This is exactly the architecture already identified in the overnight report: preserve the forcing as base + sum(products), decompose each leaf, lift it to the global grade basis, and only then sum rational channels. 

codex_overnight_optimization_tr…

 The physical sidecar design likewise required each base/product leaf to round-trip exactly before global lifting. 

codex_overnight_optimization_tr…

Thus the exact result

Roots(E
21
	​

,C
18
	​

,F
21,18
	​

)={1}

is sufficient to select Kallen2 before the slower direct-expression oracle finishes.

B. Acceptance of the finished Kallen2 gauge

Yes. The following is theorem-level sufficient:

Exact chart and inverse identities on the declared sheet.

Exact differential pullback.

Exact chart-space strip solution.

Exact source-frame residual from SolveEpsFormStripInFrame:

F
21,18
	​

+ϵ(E
21
	​

D
21,18
	​

−D
21,18
	​

C
18
	​

)−dD
21,18
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

.

Exact chart/source gauge round trip.

Exact dlog potentials, not merely closed forms.

Exact unipotent row-transformation inverse.

Preservation of the already certified 21→20 and 21→19 blocks after extending the sector-21 row gauge.

Hash continuity tying the gauge to the census, accumulated frame, chart, and strip input.

The direct source-expression oracle is then adversarial redundancy, not a prerequisite.

The smallest additional cheap oracle, if desired, is one unseen exact source point evaluated over all eight sign assignments of the original three roots, comparing the pre-cancellation leaf recurrence with the composed channel result. That specifically attacks mask-order, omitted-leaf, and sign mistakes. It adds assurance but is not required once the symbolic source residual passes.

C. Cancellation of historically different roots

Confirmed. This is another concrete demonstration that root sets must not be unioned across historical paths.

Individually, the ingredients involve:

D
21,20
	​

:{3},D
21,19
	​

:{1},D
19,18
	​

:{1,2},

yet after exact recurrence assembly,

F
21,18
	​

∈Q(x,y,ϵ)(r
1
	​

),

and the complete strip also uses only r
1
	​

.

The relevant field is generated by the nonzero grades of the assembled

(E
21
	​

,C
18
	​

,F
21,18
	​

),

not by the union of roots appearing in its provenance graph. The report had already warned that a raw static census cannot account for grades introduced or removed by recursively installed row gauges. 

codex_overnight_optimization_tr…

Therefore sector 21 should continue downward strip by strip. It should not be promoted to a triple extension merely because different previously solved strips used different charts or roots.

D. Local-subset decomposition and lifting

Yes. This optimization is mathematically safe and likely worthwhile for future strips. Leaf decomposition accounts for roughly 28.7/38.4 seconds of the present census, so avoiding unnecessary rank-three decomposition can materially reduce repeated row costs.

The safe algorithm is:

Propose a local active subset S for one scalar.

Canonicalize the scalar in the declared algebraic field.

Decompose it over the local basis generated by S.

Compose locally and prove exact equality to the canonical scalar.

Lift with multiquadraticLiftLocalChannels into the fixed eight-grade ABI.

Compose globally and again prove exact equality.

Perform all subsequent matrix products and differentiation in the global basis.

A proposed subset need not be minimal; it must only be sufficient. On any failure, fall back to the full global decomposition or stop with a typed algebraic-normalization error.

Required fail-closed invariants

Global ABI: fixed root order, radicands, little-endian bit convention, and multiplication table.

Local-to-global mask map: explicit mapping of each local generator to its global bit.

Rank-zero handling: a rational scalar lifts only to global grade zero.

Exact local round trip:

Compose
S
	​

(Decompose
S
	​

f)=f.

Exact global round trip:

Compose
123
	​

(Lift
S→123
	​

Decompose
S
	​

f)=f.

Differential compatibility:

Lift(df)=dLift(f).

Multiplicative compatibility:

Lift(fg)=Lift(f)Lift(g).

Exact classifier agreement: the nonzero lifted grades must agree with the independent radical classifier after canonicalization.

Cache provenance: expression hash, accumulated-frame hash, local root subset, global root order, radicand definitions, and normalizer version.

No silent unsupported radical: any cube root, unnormalized nested radical, or undeclared square class must fail closed.

Final global forcing check: exact compose/decompose and classifier agreement remain mandatory after all products and cancellations.

For additional confidence, the first accepted scalar from every local subset—rank zero, each singleton, each pair, and rank three—should also be decomposed once by the full global path and compared exactly with the lifted local result.

Effect of the Kallen23 nested-radical defect

This changes one chart-transition invariant materially:

Together equality is not an adequate source-roundtrip test for algebraic pullbacks.

The transition certificate must compare canonical elements of the declared multiquadratic field, not literal radical syntax. The required sequence is:

inverse-coordinate substitution;

operand-local normalization of known nested radicals;

exact reduction to the ordered source grade basis;

grade-wise equality.

For a normalization such as

2
λ
3
	​

H
2
	​

	​

=
2
	​

Hr
2
	​

	​

,

the manifest must bind:

the exact square identity;

the selected sheet and base-point sign;

the 
2
	​

 constant-field convention;

wrong-branch mutants;

the normalization-rule hash.

If a pullback is algebraically inside the declared field but cannot be canonicalized, the wrapper should return a typed status such as AlgebraicPullbackNeedsNormalization; it must not report chart failure or source-roundtrip failure merely because Together leaves a nested radical unevaluated.

This same canonicalization must precede the proposed local active-subset classification. Otherwise a nested expression can be incorrectly classified as a new square class or as requiring the full rank-three basis.
