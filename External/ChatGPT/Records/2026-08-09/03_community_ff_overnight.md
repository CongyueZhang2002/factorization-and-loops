# Community Ff Overnight

## Question

We are beginning the isolated FACET finite-field coefficient experiment you recommended. The actual FeynFacet package will remain unchanged; all scripts and results will be placed under FACET/Codex.

Planned sequence:

1. Use the complete stored NLO UU calculation as the reference. Retain FACET's physical normalization, exact hadronic map, distribution/fraction extraction, positive-root certification, BMHV and cut metadata, and deterministic analytic-basis labels.
2. For each target and basis channel, expose only the rational function in dimensionless kinematic variables and Epsilon.
3. Evaluate the complete sparse target-to-Kira-to-master composition modulo primes and reconstruct only the final six NLO master coefficients.
4. Restore the analytic labels and require exact Mathematica equality to the existing coefficients, together with unchanged branch/cut metadata and absence of forbidden variables.
5. Only after NLO equality, apply the same evaluator first to one representative NNLO master column and then broaden the run if memory and probe count are reasonable.

Before the long run starts, please identify any conceptual mistake or likely dead end. In particular:

- For the lowest-friction implementation, should we trace the already-generated exact sparse Kira rows with Ratracer, construct a FiniteFlow graph, or first use FireFly around a custom black-box evaluator?
- What is the minimal deterministic channel decomposition required before modular evaluation, and how should we guard against identities between supposedly independent analytic labels?
- Should the first NLO experiment reconstruct full rational Epsilon dependence or a bounded Laurent series? FACET ultimately needs exact Epsilon dependence sufficient for endpoint and distributional expansion.
- What data should be cached so that the NNLO probe evaluator does not repeatedly parse the multi-gigabyte exact Kira artifact?
- Which exact equality and unused-prime checks are sufficient before proceeding from NLO to NNLO?

Please give implementation-level advice focused on avoiding a dead end tonight. Do not propose replacing the required analytic result with fixed-kinematics numerical values.

## Pro response

Assessment

The proposed experiment is sound. The main conceptual risk is assuming that momentum-fraction elimination is already target-local. FACET has previously encountered physicalized Kira-image coefficients containing x
a
	​

 and x
b
	​

, with the universal factor appearing only after the complete target-to-master sum. Therefore, before restricting the reconstruction variables to (x,y,ϵ), prove that every target contribution entering the NLO pilot is already free of x
a
	​

,x
b
	​

,z
h
	​

 after the proposed normalization.

If that criterion is not satisfied, keep the certified positive-root variables in the modular calculation:

x
a
	​

=r
a
2
	​

,x
b
	​

=r
b
2
	​

,z
h
	​

=r
h
2
	​

,

and reconstruct the complete master coefficient in

Q(x,y,ϵ,r
a
	​

,r
b
	​

,r
h
	​

,…).

Only after the target-to-master composition should FACET certify

C
m
	​

=r
a
−2
	​

r
b
−2
	​

r
h
−4
	​

H
m
	​

(x,y,ϵ,…),

with H
m
	​

 independent of all fraction and root variables. Do not force a target-local factorization merely to reduce the number of reconstruction variables.

This preserves the project requirement that the final result be analytic in ϵ, endpoints, and distributions, with cuts, causal data, branches, and BMHV information retained; modular evaluations are intermediate exact arithmetic, not the deliverable. 

AGENTS

1. Which tool to use first
Recommendation for the NLO pilot: Ratracer

Use Ratracer, but trace the complete sparse target-to-master composition, not the Kira rows as independent outputs.

Ratracer records arbitrary rational operations as a straight-line trace, optimizes dead operations and common subexpressions, can retain selected outputs, streams large traces from disk, and delegates rational reconstruction to FireFly. Those properties fit the existing FACET calculation, which is already expressed as exact sparse arithmetic:

C
mα
	​

=
T
∑
	​

c
Tα
	​

R
Tm
	​

.

Ratracer is therefore the lowest-friction route provided that FACET emits this sum directly as a trace rather than first constructing the exact Mathematica expression. 
arXiv

The trace should be constructed schematically as follows:

for each target T:
    for each analytic channel alpha:
        targetNode[T, alpha] = emitRational(c[T, alpha])

    for each nonzero Kira entry (T, m):
        kiraNode[T, m] = internRational(R[T, m])

        for each channel alpha:
            output[m, alpha] +=
                targetNode[T, alpha] * kiraNode[T, m]

Mark only the six final NLO master-channel coefficients as trace outputs. Then run trace optimization, finalization, measurement, and reconstruction.

Do not use Ratracer to solve the IBP equations again. The closed Kira rules are already the exact input map.

A command-line trace-expression pilot is acceptable at NLO. For NNLO, do not create one enormous final expression file merely so Ratracer can parse it. Use the ratracer.h API or a generated straight-line trace that writes operations incrementally.

FiniteFlow: preferred longer-term engine

FiniteFlow is the cleaner production design once the pilot has established that finite-field composition is beneficial. Its dataflow graphs are explicitly intended to compose modular algorithms while avoiding intermediate symbolic expressions, and its Mathematica interface is suitable for constructing custom amplitude-to-master calculations. 
arXiv
+1

Move to FiniteFlow if any of the following occurs:

generating the Ratracer trace requires materializing large Mathematica sums;

trace parsing dominates the NLO pilot;

the NNLO calculation needs reusable target, Kira-row, and master-column graph nodes;

simultaneous reconstruction of many outputs and common subgraphs becomes important.

Do not begin with FireFly alone

FireFly is an exact multivariate rational-reconstruction library, but it expects a fast black-box evaluator. Starting with FireFly would require FACET to implement that modular evaluator, its expression parser, caching, bad-point handling, and output interface before obtaining any benefit. 
arXiv
+1

Ratracer already uses FireFly for reconstruction while supplying the missing trace and evaluator machinery. FireFly alone becomes attractive only after a compiled FACET modular evaluator already exists.

The practical order is therefore:

Ratracer pilot⟶FiniteFlow production graph if warranted.
	​

2. Rational ring and physical normalization

Before emitting any modular operation, define one exact rational ring. For the simplest NLO UU pilot, use

K=Q(x,y,ϵ,C
A
	​

,C
F
	​

,…),x=−
s
t
	​

,y=−
s
u
	​

.

The ellipsis denotes any additional independent rational color variables that actually occur.

Before setting s=1, certify exact homogeneity:

c
Tα
	​

(s,t,u,ϵ)=s
d
Tα
	​

c
Tα
	​

(x,y,ϵ).

Store d
Tα
	​

 separately. Setting s=1 without this certificate can discard a genuine scale factor.

If fractions or square-root variables survive until master accumulation, enlarge the ring:

K=Q(x,y,ϵ,C
A
	​

,C
F
	​

,r
a
	​

,r
b
	​

,r
h
	​

,r
s
	​

,…),

where each root substitution has already been justified in the physical chamber. Positivity has no meaning in a finite field; it is used only to establish the branch-safe map before modular evaluation. Once the map is certified, the root symbols are ordinary algebraic variables of the rational calculation.

All expressions admitted to the trace should satisfy a strict grammar:

exact integers and rational numbers;

declared rational variables;

Plus, Times, and integer powers;

division through negative integer powers or explicit inverses.

Reject any remaining:

noninteger power;

Log, Gamma, Beta, PolyLog, or hypergeometric object;

distribution or cut object;

Pair, SPD, SPE, Dirac or BMHV tensor;

GLI;

independent D;

unregistered symbol.

3. Minimal deterministic channel decomposition

Write each normalized target coefficient as

c
T
	​

=
α=1
∑
N
ch
	​

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

∈K.

The A
α
	​

 are exact non-rational or tensor labels. The modular calculation reconstructs only

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
For the first NLO UU experiment

Use the trivial analytic basis if possible:

N
ch
	​

=1,A
1
	​

=1.

After stripping the twist-two distribution product, universal fraction factor, coupling, and certified scale power, require that the remaining NLO UU coefficients are rational functions. Do not introduce a generic Gamma/log/BMHV basis for a calculation that does not need one.

For the first pilot, it is safer to retain C
A
	​

,C
F
	​

,… as reconstruction variables rather than to risk an incorrect color-channel decomposition. Since the NLO problem is small, the extra variables should be tolerable. If the number of probes becomes unnecessarily large, subsequently collect into a declared finite color basis.

Do not simultaneously:

treat C
A
	​

,C
F
	​

 as independent variables; and

impose a later relation such as C
A
	​

=N
c
	​

 and
C
F
	​

=(N
c
2
	​

−1)/(2N
c
	​

).

Choose one coefficient field and record it in the manifest.

If non-rational labels occur

Use a global deterministic registry. Each entry should contain

(stable ID,HoldComplete[A
α
	​

],normalization,branch key,tensor/distribution key).

Generate the stable ID from the canonical held expression, with a structural equality check against the registry entry. Do not use Unique identifiers as durable channel names.

Before channel separation:

perform every allowed Gamma/Beta recurrence or functional rewrite;

reduce color structures;

reduce TT angular tensors;

canonicalize branch-safe powers;

canonicalize endpoint and distribution objects.

After channel separation, forbid further transformations that can relate different labels.

This condition is essential. If

A
2
	​

=f(x,ϵ)A
1
	​


for a rational f∈K, then treating A
1
	​

 and A
2
	​

 as independent channels can miss cancellations. Either reduce that relation before decomposition or keep the combined object outside the finite-field pilot.

For NLO UU, the safest acceptance criterion is simply:

no non-rational analytic labels occur.
4. Reconstruct full ϵ dependence first

The first NLO calculation should reconstruct the full rational dependence on ϵ:

C
m
	​

=C
m
	​

(x,y,ϵ,C
A
	​

,C
F
	​

,…).

Do not start from a bounded Laurent series.

Reasons:

it gives a direct exact comparison with the existing NLO coefficients;

it avoids guessing how many orders are needed after multiplication by divergent master integrals;

it preserves reuse for endpoint and distributional expansions;

the six-master NLO problem is the place to test the harder full reconstruction.

Ratracer can expand traces in a selected variable before reconstruction, but that should be a later optimization after the required depth has been proved. 
arXiv

A truncated coefficient series is sufficient only after FACET has established, for every master M
m
	​

,

M
m
	​

(ϵ)=
j=−p
m
	​

∑
∞
	​

M
m,j
	​

ϵ
j
,

and has fixed the desired hard-function order K. Then the coefficient is needed at least through

ϵ
K+p
m
	​

,

with any additional depth required by endpoint distributions and prefactors included explicitly. Until those pole and depth data are certified, full rational ϵ dependence is the safe choice.

Use only ϵ in the trace:

D⟼4−2ϵ,

and reject residual D.

5. Avoid reparsing the Kira artifact

The NNLO evaluator should never parse the multi-hundred-megabyte Kira result for each prime or point. Perform one deterministic preprocessing calculation and persist the following.

Sparse reduction index

Store the closed Kira map as

T⟼{(m,R
Tm
	​

)}
R
Tm
	​


=0
	​

.

For all-master reconstruction, use a target-row representation. For a selected NNLO master experiment, also construct the transposed column

m⟼{(T,R
Tm
	​

)}
R
Tm
	​


=0
	​

.
Deduplicated rational-function pool

Assign an expression ID to every distinct target-channel coefficient and Kira coefficient. Use a hash only to locate candidates; certify identity with structural equality.

Store:

expressionID -> exact canonical rational expression

Compile or trace each unique expression once.

Physical and algebraic manifests

Persist:

source Kira artifact fingerprint;

exact closed-rule fingerprint;

target-store fingerprint;

process-card fingerprint;

hadronic-map fingerprint;

dimension rule;

variable order;

scale extraction and scale powers;

positive-root substitutions and their certificates;

analytic-basis registry;

color convention;

master ordering;

target ordering;

trace or graph fingerprint;

tool versions.

Optimized modular program

For Ratracer, the optimized and finalized trace is itself the main evaluation cache. Ratracer is designed to stream traces from disk and remove operations that do not contribute to selected outputs. 
arXiv

For the first NNLO column, generate a trace containing only that master’s contributing targets and required rational-expression nodes. Do not generate all 342 outputs and later discard 341 of them.

6. Bad points and primes

Every modular division must be checked. A probe is invalid when:

a rational-number denominator is zero modulo p;

a kinematic denominator evaluates to zero;

a chosen prime degenerates a leading coefficient;

a root or coordinate substitution becomes singular;

the evaluator encounters an undeclared operation.

An invalid probe must be discarded and regenerated. It must never return zero or a placeholder value.

Record all rejected primes and points. This is particularly important because the physical chamber

s>0,x>0,y>0,x+y<1

cannot be imposed in F
p
	​

. The chamber has already done its work by selecting branches and justifying substitutions. Modular points only need to be algebraically nonsingular.

7. Exact NLO acceptance criteria

Before attempting NNLO, require all of the following.

A. Modular evaluator check

Before reconstruction, compare the trace evaluator against direct Mathematica modular evaluation of the exact NLO composition at deterministic nonsingular points.

A useful initial set is:

two primes not used for reconstruction;

ten points for each prime;

every master and every channel.

This tests the trace emitter, variable ordering, rational-number conversion, sparse-row indexing, and output ordering.

B. Full reconstruction

Reconstruct all six master coefficients with full rational ϵ dependence.

Normalize each reconstructed rational function to a fixed form:

C
mα
FF
	​

=
D
mα
FF
	​

N
mα
FF
	​

	​

,

with primitive numerator and denominator and a fixed denominator leading-coefficient convention.

C. Exact symbolic equality

For each master and channel, compare against the existing result by the polynomial identity

N
mα
FF
	​

D
mα
ref
	​

−N
mα
ref
	​

D
mα
FF
	​

=0.

This comparison should be made in the declared rational ring, before restoring non-rational labels. It is generally cheaper and clearer than simplifying a difference of the fully restored expressions.

The acceptance criterion is exact zero for every channel of every master. This exact identity, rather than the unused-prime evaluations, is the decisive NLO proof.

D. Restored physical result

After restoring all labels and prefactors, require:

exact distribution factor equal to the reference;

exact fraction Laurent valuation equal to the reference;

exact scale power equal to the reference;

no x
a
	​

,x
b
	​

,z
h
	​

 or root placeholders in the hard coefficient;

no forbidden hadronic vectors;

no residual D, GLI, loop momentum, Pair, Dirac, or SPE object;

exact equality of the cut records;

exact equality of the BMHV context;

exact equality of branch and causal records;

exact equality of the analytic-basis registry.

Use structural equality for metadata, not only matching hashes.

E. Unused-prime reconstruction checks

In addition to the exact NLO equality, reserve at least:

2 unused primes×10 unused nonsingular points

for all reconstructed outputs.

These checks are supplementary at NLO because exact Mathematica equality is available. For a later NNLO coefficient without an independently manageable exact reference, unused-prime evaluations provide a probabilistic reconstruction check, not a deterministic symbolic proof. That distinction should be recorded explicitly.

8. Recommended sequence tonight

Run a grammar audit.
Verify that the physically normalized NLO UU target coefficients and Kira rows are rational in the declared variables. Record every rejected head.

Check fraction locality.
Determine whether the proposed per-target normalization actually removes x
a
	​

,x
b
	​

,z
h
	​

. If not, add the certified root variables to the modular ring and delay universal-factor extraction until the complete master output.

Fix the variable list.
Start with

{x,y,ϵ,C
A
	​

,C
F
	​

,…}.

Add root variables only when required.

Use one trivial analytic channel if possible.
Do not build a generic special-function registry for NLO UU unless the grammar audit shows that one is needed.

Emit one Ratracer composition trace.
Mark only the six final master coefficients as outputs. Do not reconstruct target or Kira coefficients separately.

Compare modular evaluations before reconstruction.
Use direct Mathematica modular evaluations at held-out primes and points.

Reconstruct full rational ϵ dependence.

Require exact channel-by-channel equality to all six reference coefficients.

Restore and compare all physical metadata and prefactors.

Only then construct one NNLO master-column trace.
Start with a median column, not the 38,000-target dominant column. Extract only the contributing target rows and rational-expression nodes.

Likely dead ends to avoid

calling Mathematica once per finite-field probe;

using FireFly before a compiled black-box evaluator exists;

reconstructing every Kira row before composing it with targets;

reconstructing every target coefficient as an independent final object;

setting s=1 without an exact homogeneity certificate;

assuming fraction cancellation occurs target by target;

assigning finite-field values to Gamma functions, logarithms, distributions, cuts, or tensor structures;

generating channel labels independently for each target;

using truncated ϵ series without a master-pole and endpoint-depth analysis;

treating a modular division by zero as a zero result;

letting Ratracer parse a giant NNLO expression that Mathematica first had to construct.

The most informative pilot is not merely “can FireFly reconstruct a rational function?” It is whether a trace of the full six-output sparse composition reconstructs the current NLO UU result exactly without materializing the master coefficients during evaluation.
