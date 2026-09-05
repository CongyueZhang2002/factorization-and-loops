# Community Ff NNLO Stress Result

## Question

The attached archive contains the complete measured NNLO stress-column experiment. Please inspect the source scripts, manifests, exact reconstructed expression, and independent verification records rather than relying only on this message.

The selected coefficient is master 64,
GLI[TopologyF10C25N1,{1,1,2,0,0,1,0,1,0}], chosen because it receives 1,129 original target contributions and lies at the 95th percentile of source-product byte count among the 342 masters.

Measured result:
- The scan reads all 44,877 physical targets and all 44,648 Kira rows from their streamed stores. Every Kira remainder is zero and every terminal integral belongs to the declared set of 342 masters.
- Exactly 1,129 contributions enter this coefficient, agreeing with the independently generated master-column catalogue.
- The complete sparse source composition was normalized and emitted in 116.8 s with about 111 MB maximum resident memory. Its rational source size is 12,843,616 Mathematica bytes; the expression file is 809,367 bytes and the optimized trace is 591,062 bytes with 208,472 instructions.
- Ratracer/FireFly reconstructed the exact analytic coefficient with 479,832 probes in 63.2 s using 8 threads and about 167 MB maximum resident memory.
- A second reconstruction used a different FireFly random seed and 4 threads. It took 109.9 s and 479,628 probes. The two reconstructed files are byte-identical, with SHA-256 dba43c3fad192b0ff10a161e59614bc56302f528f4e0781e19c2dc32bb62afb2.
- An independent Mathematica verifier does not read the composed expression or trace. It rescans the original target and Kira records, normalizes and evaluates every one of the 1,129 contributions separately, and accumulates them modulo three unused primes. All 48 held-out comparisons (3 primes times 16 points) equal the reconstructed formula exactly.
- The reconstructed coefficient factors exactly as
  q2^4 qp^2 s/(ya^2 yb^2 yh^4) times a rational function of (CA,CF,epsilon,x,y).
- The old monolithic symbolic route formed a 140,317,024-byte physical coefficient and then exceeded 600 s while extracting the distribution factor. The streamed exact route avoids that obstruction.

Please assess, from the attached files:
1. Are the two independently seeded reconstructions plus the 48 direct source-record comparisons a sufficient exact certificate for this NNLO coefficient? If not, name the additional exact identity and the cheapest way to compute it without forming the monolithic symbolic sum.
2. Since the analytic/root/scale monomial has now been proved independently, should the production trace eliminate q2, qp, s, ya, yb, yh before FireFly interpolation and reconstruct only the rational function of (CA,CF,epsilon,x,y)? Give a method that retains an explicit exact check of the removed homogeneity.
3. Does this measured 208,472-instruction sparse trace reveal any exact-arithmetic task for which the RTX 5080 is likely to beat Ratracer/FireFly on CPU? Distinguish finite-field Gaussian elimination from sparse trace evaluation and multivariate reconstruction, and name a mature usable package only if one actually exists.
4. Identify any mathematical or software dead end before we scale this method to all 342 NNLO master coefficients.

The project requires exact analytic coefficients. Modular values are interpolation and verification data, not the final result.

## Pro response

I inspected the archive’s two Mathematica scripts, manifests, candidate catalogue, optimized trace, reconstructed rational expression, dimensionless expression, and four run logs. The included primary reconstructed file has the stated SHA-256 hash. The logs record distinct FireFly seeds, thread counts, and probe histories. The second reconstructed text file is not bundled, however, so its byte identity with the included file cannot be independently recomputed from this archive alone. The emitted .expr source is also referenced by hash but not included. 

NNLOMaster0064ExactReconstructi…

The measured result is strong: the finite-field route has produced an exact rational formula and removed the symbolic-memory obstruction. The remaining distinction is between an exact reconstructed expression and a deterministic proof that it equals the complete source sum. FACET’s final artifact should eventually include both, since fixed-field evaluations are verification data rather than the requested analytic result. 

AGENTS

1. Status of the present certificate

The current evidence establishes four different facts.

Statement	Current status
The emitted Ratracer program represents one rational function	Established structurally by the trace
FireFly returned an exact rational function over Q	Established
Two independently seeded reconstructions returned the same rational expression	Established by the recorded runs; only one output file is bundled
The rational expression equals the original 1,129-term source composition identically	Extremely strong finite-field evidence, but not yet a deterministic symbolic identity

The independent verifier is well designed in one important sense: it does not read the composed .expr file or the trace. It rereads all physical target records and Kira rows, normalizes every nonzero contribution separately, and accumulates the values directly in three unused fields. Thus the 48 comparisons test the trace emission, target selection, Kira indexing, and reconstruction together.

There are two limitations:

Both emission and verification use essentially the same physical-normalization code, including canonicalNumericPowers, positive-root lifting, the hadronic substitutions, and division by the declared distribution and analytic factors. The verifier is independent of the trace, but not independent of the normalization map.

Two FireFly runs and 48 field evaluations are finite-field identity tests. They do not constitute a deterministic polynomial proof, even though the reconstructed output itself has exact rational coefficients.

This is sufficient to continue scaling the method. It is not yet sufficient to label the coefficient as deterministically certified against the complete exact source composition.

The additional exact identity

After removing the certified monomial, let the streamed source contributions be

g
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

,z=(C
A
	​

,C
F
	​

,ϵ,x,y),

and let the reconstructed result be

G(z)=
D(z)
N(z)
	​

.

All quantities now lie in the ordinary rational function field

Q(C
A
	​

,C
F
	​

,ϵ,x,y),

with no branches, roots, distributions, cuts, or BMHV tensors inside the scalar algebra.

The exact identity to prove is

i=1
∑
1129
	​

d
i
	​

n
i
	​

	​

−
D
N
	​

=0.
	​


The cheapest deterministic implementation should proceed in two stages.

First test whether the reconstructed denominator is already sufficient

Group structurally identical source denominators and sum their numerators:

i
∑
	​

d
i
	​

n
i
	​

	​

=
a=1
∑
r
	​

d
a
	​

n
a
	​

	​

.

Normalize every denominator to a primitive polynomial with a fixed leading-sign convention. Then test exact polynomial divisibility

d
a
	​

∣Dfor every a.

If this holds, the certificate reduces to the sparse polynomial identity

P(z)=−N(z)+
a=1
∑
r
	​

n
a
	​

(z)
d
a
	​

(z)
D(z)
	​

=0.
	​


No rational sum and no global Together are needed. Every quotient is first required to be an exact polynomial quotient, and P can be accumulated in a disk-backed sparse coefficient map.

If some source denominators do not divide D

Compute only the residual denominator needed beyond the reconstructed denominator:

r
a
	​

=
gcd(
d
a
	​

,D)
d
a
	​

	​

,E=lcm(r
1
	​

,…,r
r
	​

),L=DE.

Then certify

P(z)=−N(z)E(z)+
a=1
∑
r
	​

n
a
	​

(z)
d
a
	​

(z)
L(z)
	​

=0.
	​


Again, require every division to be exact before using the quotient. Accumulate P by balanced sparse merges and accept the certificate only when every polynomial coefficient is exactly zero.

This is preferable to forming

Together[
i
∑
	​

d
i
	​

n
i
	​

	​

−
D
N
	​

]

as one Mathematica expression. It never constructs the monolithic rational sum.

The reconstructed denominator is already stored in a visibly factorized form, so the preliminary divisibility test may be inexpensive for this column. If it is not, the source denominators can be catalogued by exact primitive factor profiles before constructing E.

Recommended artifact status

Until that identity is computed, call this coefficient:

Exact rational reconstruction with two independent interpolation runs and 48 held-out source-record evaluations.

After the polynomial identity vanishes exactly, call it:

Deterministically certified exact source composition.

2. Remove the six monomial variables before production reconstruction

Yes. The production calculation should reconstruct only

G(C
A
	​

,C
F
	​

,ϵ,x,y)

rather than treating

q
2
	​

, q
π
	​

, s, y
a
	​

, y
b
	​

, y
h
	​


as six additional interpolation variables.

The reconstructed coefficient has the exact form

C
64
	​

=U
64
	​

G
64
	​

(C
A
	​

,C
F
	​

,ϵ,x,y),

with

U
64
	​

=
y
a
2
	​

y
b
2
	​

y
h
4
	​

q
2
4
	​

q
π
2
	​

s
	​

.
	​


Here q
2
	​

 and q
π
	​

 represent the separately retained analytic factors generated from powers of 2
ϵ
 and π
ϵ
. They should be analytic normalization labels, not FireFly variables.

The included reconstructed text confirms that each of

q
2
4
	​

,q
π
2
	​

,s,y
a
−2
	​

,y
b
−2
	​

,y
h
−4
	​


occurs exactly as this single monomial. The saved dimensionless candidate depends only on

(C
A
	​

,C
F
	​

,ϵ,x,y).
Required exact monomial certificate

Do not infer the same scale power for all 342 masters from master 64. The distribution and momentum-fraction factors may be universal, but the scale power generally depends on the mass dimension of the individual master.

For each nonzero master coefficient, generate a record

C
m
	​

=(U
m
	​

,source fingerprints,root certificate,scale-degree certificate,analytic-factor certificate).

The following parts can be certified separately.

Analytic powers

Require that the complete coefficient has exactly the declared powers

q
2
a
m
	​

	​

q
π
b
m
	​

	​

.

When those powers are already common to every source contribution, record this termwise. Otherwise prove the complete-column factorization before removing them.

Momentum-fraction roots

Use the existing positive-root polynomial certificate to prove

C
m
	​

=y
a
v
a,m
	​

	​

y
b
v
b,m
	​

	​

y
h
v
h,m
	​

	​

C
m
	​


with 
C
m
	​

 independent of the three roots. This preserves the branch choice because

x
a
	​

=y
a
2
	​

,x
b
	​

=y
b
2
	​

,z
h
	​

=y
h
2
	​

,y
a
	​

,y
b
	​

,y
h
	​

>0

was certified before finite-field arithmetic.

Scale power

After

t=−sx,u=−sy,

prove exact homogeneity

C
m
	​

(s,x,y,…)=s
d
m
	​

C
m
	​

(x,y,…).

The exponent d
m
	​

 should be checked against the mass dimension of that master and coefficient, not copied from master 64.

Reduced production trace

Once C
m
	​

 is exact, construct the black box

G
m
	​

=
U
m
	​

C
m
	​

	​


and reconstruct it only in

(C
A
	​

,C
F
	​

,ϵ,x,y).

There are two safe implementations:

Trace already certified root-free and scale-free source records.

Divide the complete trace by U
m
	​

, then specialize the eliminated variables to nonsingular exact constants after their absence has been proved.

The first is stronger because it directly traces the certified scalar object. The second is mathematically valid once independence has been proved.

After reconstruction, restore U
m
	​

 and repeat held-out evaluations with arbitrary nonzero values of all six omitted placeholders:

U
m
	​

G
m
	​

=
?
T
∑
	​

c
T
	​

R
Tm
	​

(modp).

Those comparisons test the implementation of monomial removal but do not replace the exact monomial certificate.

Expected performance effect

FireFly reconstructed the present object in eleven variables and found total numerator and denominator degrees 49 and 18. Six variables were then discovered to occur only through monomial factors. FireFly’s factor scan handled them correctly, but eliminating them beforehand will:

reduce factor scans;

simplify variable-order optimization;

reduce the interpolation dimension from eleven to five;

produce the physically meaningful output directly;

avoid treating branch-qualified analytic normalization factors as ordinary rational variables.

The speedup should be measured rather than assumed because the current factor scan already recognized those simple factors. The semantic simplification is justified even if the wall-time reduction is only moderate.

3. The RTX 5080 is not useful for this measured task

The optimized trace contains 208,472 rational instructions. FireFly reports a first-probe time near 8.3×10
−4
s and an average probe time near 8.1×10
−4
s. The full eight-thread reconstruction finishes in about 63 seconds.

This is a straight-line arithmetic problem:

z⟼
T
∑
	​

c
T
	​

(z)R
T64
	​

(z),

evaluated at many finite-field points. It is not a finite-field Gaussian-elimination problem.

Linac implements CUDA Gaussian elimination and row reduction over finite fields. It is intended for large matrix systems arising in amplitude reconstruction, not for evaluating a Ratracer arithmetic DAG. 
arXiv

Ratracer is specifically designed to record arbitrary rational operations and evaluate the resulting trace during FireFly reconstruction, which is exactly the present calculation. 
arXiv
 FireFly reconstructs multivariate rational functions from finite-field black-box evaluations and is already the reconstruction engine being used here. 
GitLab
+1

I found no mature drop-in CUDA package that accepts a Ratracer-style straight-line rational program and performs adaptive FireFly-compatible multivariate reconstruction on an NVIDIA GPU. Libraries for CUDA polynomial or matrix arithmetic solve different subproblems and would require a custom evaluator and reconstruction interface.

A custom GPU evaluator could, in principle, evaluate the same trace at many field points in parallel. That would require:

a CUDA implementation of the required 64-bit prime-field arithmetic;

batched modular inversion;

a compiled representation of the trace;

coordination with FireFly’s adaptive requests;

installation of a CUDA toolchain compatible with the RTX 5080.

That development is not justified by a 63-second reconstruction.

Reconsider a GPU only if the complete production profile shows both:

T
probes
	​

/T
total
	​

≳0.7

and either individual probes become much more expensive or the required probe count reaches many millions per output. The next large gain is much more likely to come from:

removing the six monomial variables;

sharing rational nodes across masters;

reconstructing several master outputs from one probe;

avoiding repeated Mathematica preprocessing.

4. Dead ends to remove before scaling to 342 masters
P0 — do not run the present script independently 342 times

The Mathematica emitter spends roughly 111 seconds rescanning and normalizing the target and Kira stores for one column. Repeating this for 342 columns would spend more than ten hours merely rebuilding related source expressions, before interpolation.

Create one reusable exact representation:

{c
T
	​

}
T=1
44877
	​

,{R
Tm
	​

}
R
Tm
	​


=0
	​

,

where each distinct rational expression has a stable node ID.

Persist:

target ID -> normalized target node
Kira edge (target, master) -> normalized Kira node
master -> list of contributing target/Kira node pairs

The physical target should be normalized once, not once per master containing that target.

P0 — normalize the two factors separately

The current emitter calls

Wolfram Language
processSource[coefficient imageCoefficient, target]

and only then performs distribution removal, root lifting, analytic-factor extraction, and rational normalization.

That multiplication can recreate the large-expression problem already observed for difficult NNLO contributions. The correct exact map is multiplicative:

ϕ(c
T
	​

R
Tm
	​

)=ϕ(c
T
	​

)ϕ(R
Tm
	​

),

provided each noninteger power has already received its positive-root certificate.

Use:

strip the distribution factor from c
T
	​

;

root-lift and normalize c
T
	​

;

root-lift and normalize R
Tm
	​

 separately;

multiply the two rational trace nodes inside Ratracer.

The Kira image can depend on x
a
	​

,x
b
	​

,z
h
	​

, so it cannot be treated as a fraction-independent scalar. It must receive its own certified lift.

P0 — add a global Kira-row key audit

readRuleShard detects duplicate targets inside one shard. The emitter checks that a rule target belongs to the physical target association of that shard. It does not maintain a global set of rule keys across all 256 shards.

Add

Wolfram Language
seenRuleTargets = <||>;

and reject:

the same Kira rule target appearing in two shards;

two different rows for one target;

a missing nonmaster target row;

a rule key outside the global target set.

At the end require exact set equality

{Kira-row targets}={nontrivial reduced targets}.

The independent verifier should repeat this check. It currently omits the emitter’s per-shard UnexpectedRuleTarget test and does not reread the coefficient remainder record.

P1 — stop emitting duplicated textual expressions

The trace optimizer found 106,523 duplicated instructions and removed 106,385 dead instructions. This is a direct measurement that the textual source repeats substantial rational subgraphs.

For several masters, use the ratracer.h API or another explicit node emitter:

targetNode[T] = intern(normalizedTarget[T])
kiraNode[e]   = intern(normalizedKiraCoefficient[e])

masterNode[m] = 0
for edge e = (T,m):
    masterNode[m] += targetNode[T] * kiraNode[e]

Hashing may locate candidate repeated expressions, but structural equality should certify node reuse.

P1 — reconstruct master batches, not isolated columns

A finite-field probe can return several master coefficients at once. The normalized target nodes and Kira edge nodes are then evaluated once per field point and reused by all outputs.

Do not necessarily begin with all 342 outputs in one reconstruction. Instead benchmark batches of

8,16,32

masters, grouped by:

overlap of contributing target sets;

common topology family;

similar degree estimates in (C
A
	​

,C
F
	​

,ϵ,x,y);

similar denominator-factor alphabets.

The acceptance criterion for batching should compare:

∑
m
	​

probes for isolated outputs
total probes for the batch
	​


and total black-box evaluation time.

A multi-output trace is the most likely route to a substantial gain beyond the successful single-column experiment.

P1 — use interpolation complexity, not source bytes alone

Master 64 was selected from the 95th percentile of source-product bytes, but reconstruction cost is governed more directly by:

numerator and denominator degrees;

sparsity;

denominator factors;

variable count;

coefficient height;

cancellation after composition.

Before reconstructing all columns, run inexpensive univariate degree and factor scans for every output. Use those measurements to schedule batches and identify exceptional columns.

P1 — decide the deterministic certificate format now

The source-to-candidate polynomial identity should be part of the production format before 342 coefficients are generated. Otherwise the calculation will end with hundreds of exact reconstructed expressions and no scalable way to upgrade their status from finite-field verified to deterministically certified.

Store for each coefficient:

normalized source denominator groups;

candidate numerator and denominator;

exact factor profiles;

monomial certificate;

cleared-denominator polynomial-certificate result;

source and trace fingerprints.

P2 — improve the experiment manifest

The archive does not include:

NNLOMaster0064SourceComposition.expr;

the independently reconstructed .txt file;

the Ratracer input/output listings;

the raw store manifests or process card;

a unified record of tool versions, seeds, commands, and output hashes.

The primary reconstructed file’s stated SHA-256 is correct, but the archive itself cannot establish the byte identity of both reconstructed files because only one is present.

A durable result record should include:

process-card hash
FeynFacet source hash
physical-target-store hash
Kira-store hash
variable and basis registries
monomial certificate
trace hash
Ratracer version
FireFly version
random seed
prime sequence
command line
reconstructed-output hash
independent-output hash
held-out comparison record
deterministic polynomial certificate

Absolute local paths should be supplementary rather than the only way files are identified.

Recommended next calculation

Before scaling broadly:

Compute the deterministic cleared-denominator identity for master 64.

Emit a second trace for the certified five-variable function

G
64
	​

(C
A
	​

,C
F
	​

,ϵ,x,y).

Measure the new probe count and wall time.

Precompute normalized target and Kira nodes separately.

Construct one shared trace for an 8-master batch with substantial target overlap.

Compare isolated versus batched reconstruction.

Only then choose the production batch size for all nonzero master coefficients.

The present result demonstrates that exact finite-field composition is viable: the 140 MB symbolic obstruction has been replaced by a sub-megabyte trace and a completed exact rational reconstruction. The next risk is no longer whether the method works; it is avoiding 342-fold duplication of source normalization, trace construction, and finite-field probes.

## Sources sent to Pro

- [nnlomaster0064exactreconstructionreview.zip](Sources/05_community_ff_nnlo_stress_result/nnlomaster0064exactreconstructionreview.zip)
