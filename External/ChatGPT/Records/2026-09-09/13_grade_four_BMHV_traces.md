# Grade-four BMHV traces

Verified outgoing gpt-6-pro, standard, HTTP200. Requestfbfb4552-b3bd-4f8b-983c-6dcdc90712e2.

## Question

The BMHV definition implementation passes 16 exact algebra checks (including64eps^2), and 12 generated NLO density/epsilon comparisons. Actual LL RR is a performance problem:64 traces with 12,10,or8 ordinary gammas plus one gamma5 (counts36,24,4). Expanding gamma5 into4 extra gammas then FORM tracen has not finished after>15min. Contracting external epsilon pairs first also>10min; TFORM4workers didnothelp that stage. FeynCalc DiracSimplify/West on64traces is expensive as well; real6-subkernel run now underway. We fixed a concrete worker-countbug: OMP_NUM_THREADS=1 also makes $ProcessorCount=1, which incorrectly capped independent subkernels. Sixworkers are now verified.

Please review this potentially much better exact BMHV trace algorithm before production:
For an even ordered list of m ordinary gamma arguments v1...vm, and exactly one gamma5 moved to the end by TRACE CYCLICITY only,
Tr(gamma(v1)...gamma(vm) gamma5)
 = -i SUM_{S subset {1..m}, |S|=4} (-1)^{sum S}
      E4(v_s1,v_s2,v_s3,v_s4) *
      Tr(product gamma(v_j) for j outside S in original order).
Tr(empty)=4. E4 physically projects every selected slot; remaining trace uses full-D Clifford contractions and any explicit P/H projections of its inputs.
This comes from the ordinary Wick/Pfaffian trace of m+4 gammas: terms pairing two gamma5 epsilon indices vanish, leaving each of its4 indices paired with4 selected original slots. Their4! permutations cancelthe1/24. The unselected gammas form the ordinary Wick trace. The selection shuffle sign is(-1)^sumS. m4 gives -4iE4. m6 should reproduce the BMHV(D-8) contraction, not NDR(-D).

Equivalent: -4i SUM_S (-1)^sumS E4(selected) Pfaffian(remaining full/mixed Gram), with antisymmetric matrix formed from upper-triangle scalarproducts. For m12 thereare C(12,4)*7!!=51,975 pairings, versus15!!=2,027,025 innaivegamma5definition:about39timesfewer beforeepsilon zeros/cancellations.
InFORM we neednot emit51,975 terms pertrace: emit495 terms E4(selected)*g_(spin,remaining8args), thentracen evaluatesonly8ordinarygammas. TheexistingtypedP4/E4 contractionlayerhandlesphysicalandhatarguments. Exactlyonegamma5 optimized; shortmultiple-gamma5 cases retain explicitdefinition untilthereis a reason tooptimize. Scalarcoefficients are pulled out and nestedDOTs flattened withoutgamma5anticommutation; cyclicrotationonly.

Is thisformula exactly valid for arbitrary BMHV mixed D/4/D-4 gammaarguments, cyclicity and arbitrary external/currenttensorcontractions? Is the sign/factorcorrect? Does it coincidewithan established grade-four projection/West identity, or is a dimension-dependent factor oradditionalterm missing? Please challenge carefully, preferably test m6,m8 atD6/D8 andtheknown4(D-8),64eps^2 checks. Ifvalid, recommend howtoavoid needless repeatedsubtraces/combinatorialgrowth while preservingonegeneralFORM production path. Literature/mastervalues are stillnotproductioninputs.


## Pro response

The formula is correct, including the −i prefactor and (−1)
∑S
 sign. No dimension-dependent normalization or additional BMHV term is missing. It is an exact grade-four projection of the ordinary Clifford product and the fully expanded form of the West recursion.

There is also a directly useful implementation result: the FORM 5.0.1 manual already demonstrates this subset construction with distrib_, including the 51,975-term result for twelve ordinary gammas. Use that mechanism with your physical E4 tensor and FeynCalc-compatible phase—not the manual’s native epsilon convention. 
Form Dev

I independently tested the mathematical identity with exact Clifford matrices in D=6,8, including mixed full/physical/evanescent arguments and the contracted BMHV tests below. These tests do not measure your FORM adapter’s runtime.

1. Exact identity and normalization

Let

Γ
i
	​

=γ(v
i
	​

),{Γ
i
	​

,Γ
j
	​

}=2b
ij
	​

1.

Here v
i
	​

 denotes the actual typed argument, possibly v
i
	​

, Pv
i
	​

, or Hv
i
	​

, and

b
ij
	​

=v
i
	​

⋅v
j
	​


uses the corresponding mixed-dimensional contraction. For example,

b(Pv,Hw)=0,b(Pv,w)=SP
4
	​

(v,w),b(v,w)=SPD(v,w)

when both arguments in the last expression are full dimensional.

Define

T
m
	​

(v
1
	​

,…,v
m
	​

)=tr(Γ
1
	​

⋯Γ
m
	​

γ
5
	​

),

and

T
0
	​

(L)=tr
	​

j∈L
∏
original order
	​

Γ
j
	​

	​

.

Then, for even m≥4,

T
m
	​

=−i
S={s
1
	​

<s
2
	​

<s
3
	​

<s
4
	​

}
S⊂{1,…,m}
	​

∑
	​

(−1)
s
1
	​

+s
2
	​

+s
3
	​

+s
4
	​

E
4
	​

(v
s
1
	​

	​

,v
s
2
	​

	​

,v
s
3
	​

	​

,v
s
4
	​

	​

)T
0
	​

(S
c
).
	​

(1)

The empty trace is T
0
	​

(∅)=4. Traces with odd m, or m<4, vanish.

The sign convention is exactly your established one:

tr(γ
μ
γ
ν
γ
ρ
γ
σ
γ
5
	​

)=−4iE
4
μνρσ
	​

,

which is FeynCalc’s documented default Levi-Civita trace convention. 
FeynCalc

Why the coefficient is exactly −i

Insert

γ
5
	​

=−
4!
i
	​

E
4,abcd
	​

γ
ˉ
	​

a
γ
ˉ
	​

b
γ
ˉ
	​

c
γ
ˉ
	​

d

into the ordinary trace.

Every pairing that contracts two of a,b,c,d together vanishes by epsilon antisymmetry. Thus each epsilon index must pair with one of four distinct original positions.

For a selected set S, the 4! pairings with those epsilon indices become identical after epsilon antisymmetry and cancel the factor 1/4!. The remaining original positions are contracted among themselves, producing the ordinary trace.

The selection shuffle has

r=1
∑
4
	​

(s
r
	​

−r)=
r=1
∑
4
	​

s
r
	​

−10

inversions. Since 10 is even, its sign is precisely

(−1)
∑S
.

This is a polynomial Clifford-algebra identity. It requires neither independent arguments nor a nonsingular momentum Gram matrix. Repeated vectors, contracted Lorentz indices, on-shell momenta, and degenerate kinematics do not invalidate it.

Pfaffian form

For the ordered complement L=S
c
, define the antisymmetric matrix

A
ij
(L)
	​

=
⎩
⎨
⎧
	​

b
ij
	​

,
−b
ij
	​

,
0,
	​

i<j,
i>j,
i=j,
	​


with indices ordered as in L. Then

T
0
	​

(L)=4PfA
(L)
,

and therefore

T
m
	​

=−4i
∣S∣=4
∑
	​

(−1)
∑S
E
4
	​

(v
S
	​

)PfA
(S
c
)
.
	​

(2)

This is an antisymmetric ordered contraction matrix, not the ordinary symmetric Gram matrix. There is no square-root-of-determinant prescription or Gram inversion to perform.

2. Relation to West’s formula—and the scheme distinction

FeynCalc’s BMHV implementation uses the recursion

T
m
	​

=
m−4
2
	​

1≤i<j≤m
∑
	​

(−1)
i+j+1
b
ij
	​

T
m−2
	​

(v
1
	​

,…,
v
i
	​

,…,
v
j
	​

,…,v
m
	​

),
	​

(3)

with the physical epsilon trace as its four-gamma base case. This is visible directly in its spur5BMHVWest implementation. 
GitHub

Set r=(m−4)/2. Unrolling (3) produces

j=1
∏
r
	​

j
1
	​

=
r!
1
	​

.

Each fixed matching of the m−4 unselected positions can be removed in r! different pair orders. Those multiplicities cancel. What remains is exactly (1).

Thus your construction removes redundant recursion histories; it does not change the trace prescription.

A closely related implicit-γ
5
	​

 subset formula also appears in the Moch–Vermaseren–Vogt discussion of efficient traces. Their application uses a dimensionally contracted epsilon prescription. Reuse the combinatorics, not that epsilon contraction convention: your result is BMHV because E
4
	​

 is physical and its pair contractions use −detP. 
arXiv

No factor such as D−4, D−8, 1/(D−4), or a finite Z
5
	​

 should be appended to (1). Dimension dependence appears through the remaining metric contractions. The D−8 tests are consequences of that algebra.

3. Scope: mixed arguments, cyclicity, and external contractions
Mixed D/4/(D−4) arguments are covered

Equation (1) holds with arbitrary typed gamma arguments because it is multilinear and the proof uses only their Clifford contractions.

For a selected slot,

E
4
	​

(…,Hv,…)=0,E
4
	​

(…,v,…)=E
4
	​

(…,Pv,…).

For an unselected slot, retain its original type. In particular, an unselected hatted argument can make a nonzero contribution by contracting with another hatted or full-dimensional argument.

Do not project the entire residual trace to four dimensions merely because its coefficient contains E
4
	​

.

The identity holds as a Lorentz tensor before contraction. Consequently, it remains valid after multiplication by arbitrary commuting current tensors, polarization projectors, scalar coefficients, or other traced tensors. It does not require an angular average, integration, or physical reference-vector choice.

Cyclicity is safe only when applied to the complete trace

Your normalization

tr(Aγ
5
	​

B)=tr(BAγ
5
	​

)

is correct and introduces no sign.

After this operation, however, the ordinary list is anchored by the final γ
5
	​

. In general,

T
m
	​

(v
1
	​

,v
2
	​

,…,v
m
	​

)

=T
m
	​

(v
2
	​

,…,v
m
	​

,v
1
	​

).

That purported equality rotates the ordinary list while leaving γ
5
	​

 fixed, which would require moving a gamma matrix through γ
5
	​

.

Do not use ordinary cyclic-word canonicalization for the cached chiral trace. The residual nonchiral traces may use their ordinary cyclicity, but preserve all external-index connections and dimensional tags.

Select positions, not distinct argument values

This is an implementation-critical detail. If the word contains repeated momentum or index arguments, generate subsets of

{1,…,m},

not subsets of the distinct argument values.

After choosing S, remove those positions while preserving the others. A value-based Complement or deletion of every occurrence of a selected argument can corrupt the trace.

Only then may epsilon antisymmetry eliminate repeated selected arguments or exact physical linear dependencies.

Grade-four projection does not mean truncating intermediate Clifford grades

Do not build a sequential Clifford product while discarding grades above four. A higher grade generated early can return to grade four through later contractions.

For example, in D≥6,

tr(
γ
ˉ
	​

0
γ
ˉ
	​

1
γ
ˉ
	​

2
γ
ˉ
	​

3
γ
^
	​

4
γ
^
	​

5
γ
^
	​

5
γ
^
	​

4
γ
5
	​

)=−4i.

The first six ordinary gammas form a grade-six object. Removing it at that intermediate point would lose the entire answer. The final subset formula already includes these contributions correctly.

4. Independent checks performed

I used explicit Minkowski Clifford matrices in D=6,8, with

γ
5
	​

=iγ
0
γ
1
γ
2
γ
3

built only from the physical directions. The matrix trace was normalized as

tr
4
	​

M=
2
D/2
4
	​

Tr
matrix
	​

M.

The evaluations used exact Gaussian-integer arithmetic, not floating-point comparisons.

Dimension	Ordinary gamma count	Mixed-argument cases	Result
D=6	6	40	Exact agreement
D=6	8	40	Exact agreement
D=8	6	40	Exact agreement
D=8	8	40	Exact agreement

These included full-dimensional vectors, explicitly physical vectors, explicitly hatted vectors, and mixtures in different positions. An additional 24 cases at lengths 10 and 12 also agreed exactly.

These finite-dimensional checks supplement the proof above; they are not substitutes for it.

Single-γ
5
	​

 contraction tests

Let

Γ
4
	​

=
γ
ˉ
	​

a
γ
ˉ
	​

b
γ
ˉ
	​

c
γ
ˉ
	​

d
,T
4
	​

=tr(Γ
4
	​

γ
5
	​

).

Define

A
6
	​

=tr(γ
μ
Γ
4
	​

γ
μ
	​

γ
5
	​

),
A
8
	​

=tr(γ
μ
γ
ν
Γ
4
	​

γ
ν
	​

γ
μ
	​

γ
5
	​

).

The subset formula gives

A
6
	​

=(D−8)T
4
	​

,A
8
	​

=(D−8)
2
T
4
	​

.
	​

(4)

I checked both contracted sums directly in the explicit matrices.

An anticommuting-γ
5
	​

 treatment instead gives

A
6
AC
	​

=−DT
4
	​

,A
8
AC
	​

=D
2
T
4
	​

.

The answers agree at D=4 but not at positive epsilon orders.

There is a useful pure single-γ
5
	​

, O(ϵ
2
) regression for the new optimized path:

A
8
	​

+2DA
6
	​

+D
2
T
4
	​

=4(D−4)
2
T
4
	​

=16ϵ
2
T
4
	​

.
	​

(5)

The anticommuting result is zero. Unlike a multiple-γ
5
	​

 test, equation (5) directly exercises only the new subset implementation.

Your existing multiple-γ
5
	​

 regressions

The known identities remain

tr(γ
5
	​

γ
μ
γ
5
	​

γ
μ
	​

)=4(D−8),
	​


and, for

X=γ
μ
	​

γ
5
	​

γ
μ
+Dγ
5
	​

,
tr(X
2
)=16(D−4)
2
=64ϵ
2
.
	​


The explicit matrix values are respectively

4(D−8)
16(D−4)
2
	​

D=6
−8
64
	​

D=8
0
256
	​

	​


and agree with evaluating one γ
5
	​

 explicitly and applying the subset formula to the remaining one.

Those tests validate the connection to your multiple-insertion fallback. They should remain, but equation (5) is a better isolated regression for the new single-insertion optimization.

5. Use FORM’s native subset distributor

The manual’s documented mechanism is exactly the useful one here: split an ordered list into four selected arguments and the ordered complement, with the shuffle sign, then trace the complement. 
Form Dev

For one isolated trace block, the core adaptation is schematically:

form
* Input T5 contains ordinary arguments only;
* the single gamma5 has already been moved to the end by cyclicity.
* Odd lengths and lengths below four are handled by the adapter.

id T5(?v) = -i_*distrib_(-1,4,Pick4,Rest,?v);
id Pick4(?v) = E4(?v);

* Apply cheap physical-projector and epsilon-zero rules here.

id Rest() = gi_(1);
id Rest(?v) = g_(1,?v);

tracen,1;

This assumes your existing typed P/H/E
4
	​

 representation and ambient-D declarations. It is not a replacement for that layer.

The empty complement must remain the identity matrix until tracing, or be replaced directly by the already traced number 4. It must not become the scalar 1 before a trace operation that can no longer see a spin line.

If other trace factors are present in the same term, allocate separate spin-line identifiers. A fixed 1 is appropriate only for an isolated trace block.

Continue to exclude native g5_, g6_, and g7_ from this path. tracen is the ordinary dimensionally continued trace engine; FORM documents that native γ
5
	​

 is not accepted there. 
GitHub

The combinatorial reduction is substantial

Before kinematic zeros and contractions, your counts give:

Ordinary gammas m	Traces	Selected quadruples per trace	Expanded terms after subset reduction	Naive (m+4)-gamma pairings
12	36	495	51,975	2,027,025
10	24	210	3,150	135,135
8	4	70	210	10,395

Across the stated 64 traces, these generic counts are

76,257,720⟶1,947,540.

Before evaluating the residual traces, only

36(495)+24(210)+4(70)=23,140

subset groups are needed.

These are algebraic expansion counts, not a prediction of a 39× wall-time speedup. Repeated-index simplification, epsilon contractions, expression sorting, and serialization can dominate the actual run. The documented FORM example is evidence that the construction is native and established, not a timing forecast for your full projected densities.

6. Avoid repeated work without adding another production engine

I recommend the following order of optimization.

First: prune the selected epsilon before tracing

After distrib_, apply cheap exact rules to the selected four arguments:

E
4
	​

(…,Hv,…)=0,

repeated projected arguments give zero, and known physical linear dependencies can be used.

This removes whole residual traces without evaluating them. Do not perform a large scalar-product expansion merely to search for such dependencies; exploit the typed argument data and already known linear relations.

Then let tracen simplify repeated gamma arguments in the residual word. Deleting four positions can expose adjacent repeated gammas that were not adjacent originally.

Second: cache complete traces and small ordinary subtraces

Cache the complete anchored chiral word with its dimensional tags. This gives reuse between diagram pairs and current projections without reconstructing its subset expansion.

For nonchiral subtraces, the largest residual word is only eight gammas. Universal templates of lengths

0,2,4,6,8

contain at most 105 pairing terms. Reuse these or native FORM evaluation rather than repeatedly constructing long chiral recursions in Wolfram.

If profiling still shows repeated subtrace work, a memoized pairing recurrence is

F(∅)=1,
F(i
1
	​

,…,i
2r
	​

)=
j=2
∑
2r
	​

(−1)
j
b
i
1
	​

i
j
	​

	​

F(i
2
	​

,…,
i
j
	​

	​

,…,i
2r
	​

),
	​


with T
0
	​

=4F.

For the residual traces of one twelve-argument parent word, an upper bound on the number of distinct positional subproblems is

(
8
12
	​

)+(
6
12
	​

)+(
4
12
	​

)+(
2
12
	​

)+1=1981.

This can be stored as a shared expression graph or table. But I would not build a separate symbolic Pfaffian engine before testing the native distrib_ plus short-tracen route. The latter is the smallest change to your current production path.

Cache canonicalization must preserve shared dummy-index connections with the epsilon coefficient and external tensors. Renaming indices independently inside the residual trace can change the surrounding contraction.

Third: contract in bounded stages

Keep large scalar coefficients and denominator factors outside the trace expansion. After the subset transformation, perform cheap projector/epsilon reductions, then short traces, then the remaining tensor contraction, with sorting at sensible stage boundaries.

Contract the selected E4 with the current-projector epsilon when this reduces the expression. Do not automatically expand every pair into a generic 24-term determinant before exploiting common indices and physical projections.

Your unsuccessful “external epsilon first” experiment does not rule out this staged version: that experiment still exposed the much larger explicit-γ
5
	​

 trace problem.

Do not multiply worker pools. With six Wolfram workers available, having each launch a four-worker TFORM job would create a different resource problem. First measure a bounded FORM batch’s generation, contraction, and sorting costs under the existing eight-core limit.

7. Recommended production decision

Replace explicit four-gamma insertion by the subset/grade-four rule for exactly one γ
5
	​

, using native distrib_ and the existing ordinary FORM trace and physical-tensor layers. Retain the short multiple-γ
5
	​

 definition path and FeynCalc/West as validation paths, not parallel production implementations.

Before the full RR rerun, require:

the exact m=6 and m=8 identities (4), plus the isolated O(ϵ
2
) test (5);

positional-subset tests with repeated, physical, and hatted arguments;

agreement of representative generated scalar tensors before joint angular averaging, followed by the positive-epsilon comparison after averaging.

The raw BMHV algebra remains unchanged. The finite polarized-PDF scheme transformation remains separate; neither a Z
5
	​

 factor nor a reference-derived correction belongs in this trace optimization. FeynCalc likewise distinguishes its BMHV algebra from user-supplied finite counterterms. 
FeynCalc

This is not a new dimensional prescription. It is an exact reorganization that avoids generating pairings already known to vanish or combine, and it directly targets the combinatorial source of the current slowdown.