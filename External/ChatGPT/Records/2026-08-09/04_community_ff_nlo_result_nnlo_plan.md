# Community Ff NLO Result NNLO Plan

## Question

The attached archive contains the complete isolated NLO UU finite-field experiment: Mathematica grammar audit and exact reference construction, Ratracer trace emission, modular comparison, exact reconstruction, and symbolic verification records. Please inspect the actual files rather than relying only on this message.

Measured NLO result:
- The input consists of 116 physical targets, 125 nonzero target-to-master entries, and 7 masters.
- The card-derived external identities are ka.kb=s/2, ka.kc=-t/2, kb.kc=-u/2.
- After removing the physical factor alpha_s^3 D1(zh) f1(xa) f1(xb)/(xa xb zh^2) and the universal analytic factor i Pi^3 2^(2 epsilon) Pi^epsilon, every target coefficient and every Kira coefficient is a rational function only of (epsilon, CA, CF, s, t, u).
- The optimized seven-output trace is 77,265 bytes.
- 140 independent finite-field comparisons (2 primes, 10 points, 7 outputs) agree with direct Mathematica evaluation.
- Ratracer/FireFly reconstructed all seven exact rational functions with 17,423 probes in 0.45 s wall time using 8 threads and 51 MB maximum RSS.
- Exact Mathematica subtraction of reconstructed minus direct expressions is zero for every master. The seven exact comparisons took 0.278 s.

I will now scale only to one NNLO master column, reading the existing streamed TargetRecords and KiraStore rather than loading the 780 MB monolithic KiraResult.wl. Proposed order:
1. select a nontrivial master column with many contributing targets, but not the largest 899 MB finished coefficient for the first experiment;
2. stream each target coefficient and the corresponding Kira entry, enforce the card-derived rational grammar, and append their product to a Ratracer trace without forming the symbolic sum in Mathematica;
3. compare the trace evaluator to direct modular arithmetic at unused points before reconstruction;
4. reconstruct the single exact rational coefficient with 8 CPU threads;
5. verify it against an independently accumulated exact expression if that accumulation fits memory, otherwise verify at additional unused prime fields plus a denominator/numerator identity check on streamed contributions.

Please answer these concrete questions after inspecting the archive:
1. Is tracing the complete sparse target-to-master composition still the right object at NNLO, or should the trace first split by rational denominator/signature while retaining one final output?
2. What exact acceptance criterion would you require when the direct symbolic NNLO sum does not fit memory?
3. Is Linac or another mature RTX/CUDA package relevant to this sparse arithmetic trace, or only to finite-field Gaussian elimination? I have an RTX 5080 (16 GB), but no nvcc installed. Ratracer and FireFly are CPU tools.
4. Which single NNLO column would be the most informative first calculation: the densest column, a medium-density column, or a column known to have difficult denominator structure? State a measurable selection rule.

The project requires exact analytic coefficients. Numerical finite-field values are only checks and interpolation data, never the final deliverable.

## Pro response

Verdict

The NLO result validates the central idea: trace the complete sparse target-to-master composition and reconstruct only the final master coefficients. The archive shows a seven-output rational trace, exact modular agreement at 140 output values, reconstruction of all seven functions, and exact zero differences against the Mathematica reference. 

NLOExactReconstructionReview

For the first NNLO column, keep the same mathematical object,

C
m
	​

(z)=
T∈T
m
	​

∑
	​

c
T
	​

(z)R
Tm
	​

(z),z=(ϵ,C
A
	​

,C
F
	​

,s,t,u)

or its exactly certified dimensionless form. Do not reconstruct the summands or denominator classes separately unless the coefficient contains genuinely independent nonrational basis elements.

Two issues should be corrected before the NNLO run:

The actual NLO archive reconstructs in

(ϵ,C
A
	​

,C
F
	​

,s,t,u),

not in dimensionless variables (x,y,ϵ,…). If the NNLO run will instead use

x=−
s
t
	​

,y=−
s
u
	​

,

first repeat the inexpensive NLO reconstruction after certifying and removing the homogeneous power of s. This tests a part of the proposed NNLO pipeline that the attached NLO calculation did not test.

The review archive is internally consistent but is not independently rerunnable. It omits NLOComposition.trace.gz, the emitted Expressions/Master_*.expr files, NLOReferenceRational.wl, the trace-construction command or script, and the raw target/Kira inputs. Its manifest also contains absolute local paths. This is a reproducibility gap, not a defect in the measured algebra.

1. Trace one complete coefficient, not denominator-separated outputs
Recommended mathematical trace

For one selected NNLO master M
m
	​

, emit one output:

C
m
	​

=
T:R
Tm
	​


=0
∑
	​

c
T
	​

R
Tm
	​

.

If there are independent analytic channels,

c
T
	​

=
α
∑
	​

A
α
	​

r
Tα
	​

,r
Tα
	​

∈Q(z),

then emit one output per genuine channel,

C
mα
	​

=
T
∑
	​

r
Tα
	​

R
Tm
	​

.

For NNLO UU, if the grammar audit establishes that the stripped coefficient is purely rational, there should again be only one channel.

Do not split the final output by denominator

A decomposition such as

C
m
	​

=
j
∑
	​

C
m
(d
j
	​

)
	​


where C
m
(d
j
	​

)
	​

 contains terms with a particular denominator would generally be counterproductive:

cancellations may occur between different denominator classes;

FireFly would reconstruct several larger intermediate functions instead of one smaller final function;

the number of probes can increase because each output has its own degree and factor structure;

a reduced final denominator may emerge only after summing all contributions.

The NLO calculation itself illustrates the advantage of final composition: the largest output receives 110 contributions, yet FireFly reconstructs the final reduced function efficiently.

Denominator grouping is useful only inside the evaluator

It is safe to use exact denominator information as an implementation optimization while retaining one final output. In particular:

canonicalize every rational function as a numerator/denominator pair;

intern identical target coefficients and Kira coefficients;

compute each distinct denominator inverse once per probe;

merge contributions with structurally identical denominators;

expose the resulting arithmetic DAG to Ratracer.

This changes the number of modular operations, not the mathematical output.

For NNLO, prefer the ratracer.h trace API or another node-based emitter over writing one enormous textual expression. The NLO script repeats

Wolfram Language
(targetCoefficient) * (reductionCoefficient)

in each output expression. That is harmless for 125 entries but may duplicate large rational subexpressions for tens of thousands of NNLO contributions. Ratracer is intended to record arbitrary rational operations and reconstruct their final outputs through FireFly, so a node-based trace is a direct match to this calculation. 
arXiv
+1

Concrete trace structure
targetNode[idT] = trace or intern c_T
kiraNode[idR]   = trace or intern R_Tm

output_m = 0
for each contributing target T:
    output_m += targetNode[idT] * kiraNode[idR]
mark output_m as the sole output

Use a hash only to locate candidate repeated expressions; certify reuse with exact structural equality.

2. Exact acceptance when the symbolic NNLO sum does not fit memory

There are four separate statements to certify.

A. The selected source data are complete

Before emitting the trace, require exact checks that are presently implicit or absent in the NLO scripts:

{selected target IDs}={selected Kira-row IDs},
every selected row remainder=0,
every terminal integral belongs to the declared master set,

and

the coefficient remainder=0.

In emit_nlo_trace_inputs.wls, add the equivalent of:

Wolfram Language
If[
  ! TrueQ[report["RemainderZero"]] ||
  ! TrueQ[Last[rationalTargets] === 0],
  fail["nonzero coefficient remainder"]
];

If[
  ! ContainsExactly[Keys[sparseReduction], Most[targetKeys]],
  fail["target and reduction-row sets differ"]
];

If[
  AnyTrue[
    Values[sparseReduction],
    ! TrueQ[Lookup[#, "Remainder", 0] === 0] &
  ],
  fail["a sparse Kira row has a nonzero remainder"]
];

If[
  ! ContainsExactly[masterSet, kira["Masters"]],
  fail["reduction terminals differ from declared masters"]
];

For a single NNLO column, the first equality applies after selecting only rows with a nonzero coefficient of that master.

B. The trace evaluates the intended source sum

Construct an independent streamed modular evaluator that does not parse the emitted trace or reuse its generated expression strings:

C
m
(p)
	​

(a)=
T
∑
	​

c
T
(p)
	​

(a)R
Tm
(p)
	​

(a)(modp).

Compare that to the Ratracer output at held-out points.

For the first NNLO column, require at least:

3 unused primes×16–32 nonsingular points.

Use primes that were not used by FireFly. Record:

the prime;

the point;

every denominator that vanished;

discarded points;

the source value;

the trace value;

the output ordering.

The NLO verifier should also explicitly require

Wolfram Language
Length[traceValues] === expectedOutputCount

and reject any Missing["SingularPoint"] rather than allowing a vector comparison merely to return False.

C. FireFly reconstructed the trace output

Run two reconstructions with different:

FireFly random seeds;

variable orders or sparse shifts;

initial primes.

Normalize both answers to primitive numerator/denominator form and require exact equality:

N
(1)
D
(2)
−N
(2)
D
(1)
=0.

Then evaluate the common candidate at additional held-out primes and points.

This is a strong reconstruction check, but by itself it is still a finite-field interpolation certificate rather than a deterministic proof that the trace emitter represented the source records correctly. The independent evaluator in part B addresses the latter.

D. Deterministic source-to-candidate identity

Let the exact streamed contributions be

f
i
	​

(z)=
d
i
	​

(z)
n
i
	​

(z)
	​

,

and let the reconstructed candidate be

R(z)=
D(z)
N(z)
	​

.

A deterministic polynomial certificate is obtained by defining

L(z)=lcm(D,d
1
	​

,…,d
M
	​

)

in the exact polynomial ring over Q, and verifying

P(z)=
i=1
∑
M
	​

n
i
	​

(z)
d
i
	​

(z)
L(z)
	​

−N(z)
D(z)
L(z)
	​

=0.
	​


Every quotient in this equation must be certified as an exact polynomial quotient. The sum can be accumulated by a disk-backed balanced tree; the original rational sum never needs to be constructed.

This certificate may itself become expensive if L contains many factors that cancel only globally. Nevertheless, it is the clean exact criterion. If this calculation is infeasible, the result should be recorded as:

exact rational reconstruction with independent held-out finite-field verification,

not yet as:

deterministically certified equality to the complete exact source sum.

For the first NNLO scaling experiment, the former is adequate to decide whether the finite-field route is computationally useful. Before using the reconstructed coefficient as the final production artifact, require either the polynomial certificate above or another exact source-DAG identity with explicit degree bounds.

Metadata equality

The rational reconstruction does not alter cuts or BMHV objects because they lie outside the rational scalar channel, but the artifact should still record and compare structurally:

process-card fingerprint;

hadronic-map fingerprint;

physical chamber;

branch registry;

dimension rule;

distribution and fraction factors;

cut indices, momenta, and orientations;

topology and master ordering;

BMHV scheme and evanescent declarations;

universal analytic factor;

rational-variable registry.

The current NLO manifest records source fingerprints and variable order but does not contain this complete physical context.

3. Linac and the RTX 5080

Linac is not the appropriate tool for the present trace. Its central operation is GPU-accelerated dense Gaussian elimination or row reduction over finite fields. It is relevant when one needs to solve a large finite-field linear system, compute a null space, fit a large linear ansatz, or perform rank factorization. Your present black box is instead a straight-line program dominated by additions, multiplications, and inversions:

C
m
	​

(a)=
T
∑
	​

c
T
	​

(a)R
Tm
	​

(a).

No Gaussian elimination occurs. Linac’s paper explicitly describes dense matrix row reduction as its central GPU algorithm; it also requires a functional CUDA development environment, including nvcc, for GPU execution. 
arXiv

Therefore:

Do not install Linac or CUDA for the first NNLO column.
	​


The NLO profile gives an average black-box probe time of approximately

1.1×10
−4
 s,

while reconstruction completes in 0.45 s. GPU launch, transfer, and compilation overhead would dominate such a workload.

A GPU could become relevant only if the NNLO trace produces a qualitatively different profile, for example:

T
total
	​

T
probe evaluation
	​

	​

>0.7

and either

T
probe
	​

≳10
−2
–10
−1
 s

or the calculation needs hundreds of thousands to millions of probes. The appropriate GPU design would then be a custom batched trace evaluator, with one GPU thread or warp evaluating the same arithmetic DAG at a different finite-field point. That is not what Linac implements.

RTX ray-tracing and tensor cores are not directly useful for modular rational arithmetic. A custom implementation would use ordinary CUDA integer instructions. I found no mature drop-in CUDA backend for a Ratracer/FireFly trace. FiniteFlow remains a more natural CPU-side next step because its dataflow graph model is designed to compose modular calculations without constructing symbolic intermediate expressions. 
arXiv

The GPU may become useful later for:

finite-field Gaussian elimination in a new IBP or ansatz-fitting stage;

a large fixed-basis linear fit;

a purpose-built batched modular evaluator.

It does not remove the immediate CPU experiment.

4. Which NNLO column to choose

Do not choose either the 93-target median example or the 38,366-target densest column first.

The 93-target column is too close to the NLO scale and is unlikely to expose trace-size, parsing, or probe-time bottlenecks.

The densest column combines every possible failure mode at once and gives little diagnostic separation if it fails.

Choose a stress-but-bounded column by a deterministic score.

For every master m, compute:

N
m
	​

=#{T:R
Tm
	​


=0},
B
m
	​

=
T:R
Tm
	​


=0
∑
	​

[ByteCount(c
T
	​

)+ByteCount(R
Tm
	​

)],
U
m
	​

=#{distinct exact rational source nodes in column m},
Q
m
	​

=#{distinct canonical denominator factors in column m},

and obtain cheap modular line scans estimating

d
m
num
	​

,d
m
den
	​

,

the largest numerator and denominator degrees seen along generic univariate slices.

Use the eligible set

E={m:P
85
	​

(B)≤B
m
	​

≤P
95
	​

(B)},

excluding the largest 1% of columns by either B
m
	​

 or N
m
	​

. Within E, select the column maximizing

S
m
	​

=pct(Q
m
	​

)+pct(d
m
num
	​

+d
m
den
	​

)+pct(U
m
	​

),

where pct is its percentile among all 342 columns.

An equivalent practical constraint, given the known densest count, is:

10
3
≲N
m
	​

≲5×10
3
,

provided such a column exists. This is large enough to test streaming and trace optimization but at most roughly 10%–15% of the densest column.

The first selected column should therefore have:

upper-decile contribution or byte count;

upper-decile denominator diversity;

nontrivial degree estimates;

no exceptional 899 MB existing coefficient;

an estimated unoptimized trace that remains comfortably below available RAM.

Before reconstruction, record:

emitted trace bytes;

optimized trace bytes;

number of arithmetic nodes before and after optimization;

first-probe time;

factor-scan degrees;

predicted FireFly probe count;

peak trace-construction RSS.

Abort the first attempt before interpolation if:

the optimized trace exceeds a predetermined disk or memory limit;

one probe already takes several seconds;

undeclared variables or analytic objects occur;

target/Kira set completeness fails.

Recommended immediate sequence

Add the four fail-closed source checks above.

Repeat the small NLO trace in the proposed dimensionless variables (x,y), because the attached archive only tests (s,t,u).

Construct the NNLO column catalogue (N
m
	​

,B
m
	​

,U
m
	​

,Q
m
	​

,d
m
	​

).

Select an 85th–95th percentile stress column, excluding the top 1%.

Emit one final Ratracer output, with exact rational-node interning and no denominator-separated reconstruction.

Compare against an independently streamed modular evaluator.

Reconstruct full rational ϵ dependence.

Run a second reconstruction with a different seed and variable order.

Perform held-out prime checks.

Attempt the exact cleared-denominator identity before promoting the result from a finite-field scaling experiment to a production analytic coefficient.

The NLO calculation establishes that Ratracer/FireFly is already fast enough that the next uncertainty is the growth of the trace and the reconstructed function, not CPU finite-field arithmetic. GPU work should wait until the selected NNLO column provides a measured profile demonstrating otherwise.

## Sources sent to Pro

- Original source reference: `../../ppHX_NLO/FiniteFieldReconstruction/Overnight_2026-08-09/NLOExactReconstructionReview.zip` (not archived with this exchange)
