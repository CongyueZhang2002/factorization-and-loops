# Overnight pipeline and fast incompatibility

Conversation: 6a9d1440-ba18-83e8-a2e8-f3ba1425bbf5; gpt-6-pro.

## Question

Please review the next overnight plan and propose the most valuable bounded decisions, not a huge rewrite.
Repository https://github.com/CongyueZhang2002/factorization-and-loops (the local uncommitted tree is newer).
The user authorizes a systematic workflow/data-format overhaul with no backward compatibility, but wants a GENERAL NNLO framework, explicitly solved DE coefficients through sufficient epsilon orders up to kinematics-independent constants, not a lazy generator. They prefer rational/modular/numerical checks and will eventually check masters with AMFlow. Total 8 CPU cores / 8 subkernels, 2 licensed main kernels. They want the all-family stage1+2 regeneration to take a couple of hours, not close to a day; first optimize and test hard families, then launch concurrent families and monitor/correct overnight. They specifically ask me to consult you periodically rather than pursue a speculative direction for hours.

Current concrete state:
- 91 families in current coefficient inventory, 347 entries,345 nonzero; only5 freshly regenerated V2 DEs/finite master solutions so far: CF269,CF48,CF265,CF259,CF303.
- Current V2 DE builder differentiates seed masters, Kira-reduces and closes the basis iteratively, then checks flatness. Kira can use an explicit 1..8 thread cap. Existing KernelPool (one main+8 subkernels) runs several family scripts and reserves2 helper kernels.
- Previous state-format migration left some V2 block-decomposition files with old field IrreducibleDiagonalBlocks vs current DiagonalBlocksInCurrentBasis. I recomputed the CF259 decomposition from current DE; same partition/order, no old data used.
- Production driver previously silently invoked Development checks; fixed propagation. Preserve explicit off-diagonal products instead of blanket Together: CF259 initial assembly~206s ->16.8s; completed sectors1..12~470s ->82s; S/SInverse identical and connections numerically agree. Fresh run sectors1..17(28 positions)done522s;600s family budget ends during consistent sample generation at (18,13), not obstruction. No full fresh CF259 canonicalization yet.
- Fixed zero transformation reconstruction (previously rejected across11primes), including coefficient representation for normal modular residual.
- Reuse scalar values+derivatives at all8 sign branches; small genuine-rank3 screen1.06s ->0.74s. Per-letter rank scoring opt-in.
- Stage2 already avoids repeated epsilon polynomial expansions and redundant scans; shares explicit scalar kernel expressions before path substitution. Five finite results998coefficients,174 coupled master positions,17.1MB; CF48~18.6s,CF303~190.5s. CF303 homogeneous preparation permits general non-epsilon-form DE; boundary constants remain unknown.
- Last review established that sampled curvature/residue incompatibility is fixed e,c,b,target-span evidence; NOT arbitrary-basis no-go. Corrected closedness requirement and false residue criterion dx/(1+x²) with distinct constant residues at +/-i. Refuse Taylor diagnostic on negative Laurent orders or algebraic fields; no 900s automatic diagnostic. Rational pole-degree bounds now explicitly require epsilon-independent diagonal coefficients.
- CF300(12,9) retained exact success on rank2 rationalizing chart after rectangular-support failure; degree26 simplex378monomials succeeded vsrectangle396 failed. Do not label whole CF300 noncanonical.
- Historic CF303(25,18) ranks188/189 in192residuecolumns at3images; no known exact rank-upper-bound188 proof. Formal root sign changes and permitted constant fields must be scoped.

Please answer:
1) Is there a CHEAP conservative char0 fixed-target certificate worth implementing now? Specifically full-column-rank augmented minor or known structural residue nullspaces: what exact prerequisites/data must be checked, and when should we simply keep the existing weak sampled criterion? Can the cheap checks be made basis/field-honest without symbolic witness reconstruction?
2) What concrete stopping/escalation policy will avoid hours of retrying hard canonicalizations, while preserving real finite DE solutions through requested orders? What hard-family timings would justify launching 91 families with an approximate2-4h expectation?
3) For a general resumed pipeline, recommend the MINIMUM mathematical artifacts and worker stages that improve speed substantially without hiding work or introducing many ambiguous formats. Existing V2 records plus compressed explicit finite WXF solutions already exist; don't recommend a new schema merely for elegance.
4) Flag any mathematical pitfall in deriving required master orders from current coefficient-table poles when endpoint/distribution requirements are not fully present. I will preserve explicit request scope and not claim full physical NNLO coverage.
Please give a prioritized actionable answer, distinguish proved facts from recommendations, and challenge any bad assumption.

## Pro response

Proceed, but make explicit finite-solution completion—not full canonicalization—the launch criterion. The highest-value next test is to take CF259’s valid partial transformation through the general-DE route to a completed, verified finite Laurent solution. Another long attempt to finish its canonicalization would not establish that the overnight campaign can meet its actual deliverable.

Your assembly improvements are much more consequential than the small screen improvement: roughly 189 seconds saved in one assembly, versus 0.32 seconds per measured screen invocation. Count cumulative calls before investing further in the screen. The characteristic-zero certificate below is worth a small addition, but should not become a launch blocker.

I checked the relevant pushed order-requirement and transport code at e8c62cce…; the newer implementation details and timings below are taken from your report, not an inspection of the uncommitted tree.

1. Cheap characteristic-zero certificates: implement one narrow promotion rule
The mathematical rule

Let the necessary residue equations, stacked at kinematic points, be

M(ϵ)r=v(ϵ),M has n columns.

Suppose you have a proved characteristic-zero rank upper bound

rankM(ϵ)≤n−q.

If an admissible modular specialization satisfies

rank[M
p
	​

∣v
p
	​

]>n−q,
	​


then the generic characteristic-zero system is inconsistent.

Proof: a nonzero minor modulo p cannot arise from an identically zero characteristic-zero minor under a valid reduction. The augmented matrix therefore has characteristic-zero rank exceeding the proved upper bound for M.

This requires neither a rational gauge ansatz nor reconstruction of a characteristic-zero left witness.

Case A: the full-column-rank test

With q=0, the bound rankM≤n is automatic. Thus

rankM
p
	​

=n,rank[M
p
	​

∣v
p
	​

]=n+1

is immediately usable.

Extract the augmented pivot rows/columns from the existing elimination and retain a nonzero (n+1)-minor, or equivalent replayable elimination evidence. Do not run a separate symbolic determinant computation.

This test is inexpensive but may fire infrequently because the residue system can have structural null directions.

Case B: constant block shifts give a useful structural nullspace

This is the most valuable additional check.

Suppose the fixed diagonal forms are already expressed in the supplied span:

e=
a
∑
	​

E
a
	​

w
a
	​

,c=
a
∑
	​

C
a
	​

w
a
	​

,

with kinematics-independent coefficient matrices.

For every constant matrix H, the simultaneous change

G⟼G+H,R
a
	​

⟼R
a
	​

+E
a
	​

H−HC
a
	​


preserves the block equation. Therefore, under the flatness hypotheses used to eliminate G, the residue vectors

N(H)=(vec(E
a
	​

H−HC
a
	​

))
a
	​


are structural right-null vectors of the residue-only system.

Construct N by applying this formula to matrix units H. This involves only the existing constant residue matrices; it does not require decomposition of b.

If a modular minor proves rankN≥q, and MN=0 is justified structurally in characteristic zero, then

rankM≤n−q.

You do not need to prove that these columns span the entire nullspace.

Specific bounded experiment for CF303 (25,18): with n=192 and augmented rank 189, four independent structural null directions would suffice:

rankM≤188<189.

That is worth one small calculation. The historic numerical nullity four does not itself prove that the constant-shift construction supplies four directions. If it supplies fewer, retain the sampled-only result.

Known exact relations among the supplied one-forms can provide additional structural null vectors, but do not start a new symbolic relation-discovery project tonight.

Exact prerequisites for promotion

The following must be true; otherwise the promoter declines without changing the ordinary screen’s operational value.

Prerequisite	Minimum check or inherited justification
Correct fixed equation	Exact identification of the current e,c,b, including already transformed intermediate-block contributions; no truncated surrogate silently substituted for the equation being certified.
Valid elimination	Diagonal flatness and closedness of the supplied forms are proved or inherited from a construction that establishes them. Sampled flatness alone is not a characteristic-zero proof.
Honest coefficient model	Reduction is from the actual declared field/algebraic model. Check all required root relations, allowed constant-field embeddings, and branch compatibility—not just independent formal sign flips.
Admissible image	Coefficient denominators and required root/letter denominators remain nonzero; exclude characteristic two and invalid ramified/singular evaluations.
Generic rank upper bound	The null identities hold before specialization, not merely at the sampled prime or epsilon value. Retain the structural recipe and a nonzero independence minor.

The constant-field issue has a cheap conservative resolution: promote using only a branch-safe subset of the sampled equations when the full formal all-sign action has not been justified over the permitted constants. An inconsistent subset is sufficient. There is no requirement that a certificate use every available branch.

Keep two implications separate when necessary:

The constructed residue linear system is inconsistent in characteristic zero.

Therefore the original fixed block-completion equation has no solution, conditional on the stated flatness and identification hypotheses.

This preserves a genuine arithmetic certificate without pretending sampled hypotheses have become theorems.

Regulator scope: use the upper-bound identity over k(ϵ). The resulting inconsistency then excludes even rational-in-ϵ residue assignments, and therefore excludes strict epsilon-independent residues. A nullspace found only at one exceptional ϵ does not establish that generic upper bound.

Implementation recommendation: reuse existing elimination, add the constant-shift N, and attempt promotion only on negative results. No new samples solely for promotion, no symbolic witness reconstruction, and no automatic alphabet search. Include the two tiny non-promotion regressions

Nr=1(modp)(p∣N),(ϵ−a)r=1(ϵ=a).

Both are sampled inconsistencies but must fail the generic certificate prerequisites.

2. Stopping policy: cap optional canonicalization, not the meaning of “solved”
Separate the mandatory and optional work

Treat the pipeline as:

closed DE⟶bounded representation improvement⟶explicit finite Laurent solution.

Only the middle stage is optional. A canonicalization timeout should not prevent the final stage from using the best valid current presentation.

My recommended initial policy is:

Situation	Action
Easy canonical blocks are completing	Continue and checkpoint accepted blocks.
One unresolved block consumes 90–120 seconds	Stop that attempt unless a concrete, bounded completion step is already available.
Family canonicalization reaches 300 seconds	Prefer the finite-solution route.
One justified continuation is selected	Allow it within a 600-second cumulative family cap, including earlier attempts and alternate presentations.
Residue-curvature screen rejects the fixed target	Do not enlarge the G-support for that same problem. Use another materially different presentation or proceed with the general DE.
Finite-support screen rejects, or sampling times out	Record that exact outcome; permit at most one evidence-driven alternative inside the remaining budget.

These are starting budgets, not mathematical thresholds. Calibrate them with the pilot.

A known active-rank-two chart or the retained successful simplex is an evidence-driven alternative. More random primes after a consistent sample, another arbitrary support ladder, or rerunning the same family prefix is not.

For CF259, the report at (18,13) is consistent sample generation interrupted by budget. Preserve that distinction. Do not restart sectors 1…17 merely to reach the same point again.

The general-DE fallback has a real prerequisite

After any necessary epsilon normalization, suppose

A(ϵ)=A
0
	​

+ϵA
1
	​

+⋯.

The coefficient equation is

(d−A
0
	​

)F
k
	​

=
r≥1
∑
	​

A
r
	​

F
k−r
	​

.

Variation of constants solves this once an explicit fundamental matrix of dU
0
	​

=A
0
	​

U
0
	​

 is available. This prerequisite is standard in noncanonical differential-equation integration; accepting a general connection at an interface does not supply its homogeneous solutions. 
arXiv

For completion, require that the emitted coefficient expressions contain no unresolved U
0
	​

, DE-solving node, recursive coefficient generator, or arbitrary function of another kinematic variable. A finite expression in explicitly defined iterated integrals or other supported functions is compatible with your goal; an unevaluated operator that will generate those coefficients later is not.

In particular, do not hide arbitrary-length zero-epsilon-order evolution inside a “finite coefficient” wrapper. Either the homogeneous evolution is explicitly resolved, or the family remains incomplete.

For CF303, the pilot should verify that its general homogeneous preparation actually reaches this completion criterion. For CF259, demonstrate the same using the partial canonicalization checkpoint.

What would justify a 2–4-hour expectation?

The reported prefixes and five completed outputs do not yet justify it. The missing measurement is end-to-end cost:

t
family
	​

=t
DE/closure
	​

+t
optional canonicalization
	​

+t
finite solution
	​

+t
verification/write
	​

.

The 347 coefficient-inventory entries are not a workload estimate: derivative closure can introduce additional coupled masters and deeper internal order requirements.

Use a bounded pilot covering an expensive Kira/closure family, CF259’s hard completion path, CF303’s general-DE route, a deep-order case, and ordinary families. Keep CF300 (12,9) as the positive chart/support regression; do not treat that block as a benchmark for an entire CF300 family.

Then run one actual concurrent wave using the intended pool configuration.

For illustration, if the five completed families remain current, there are 86 remaining. With six sustained family-worker lanes and a 25% scheduling/contingency allowance,

T
campaign
	​

≈1.25
6
86
t
family
	​

	​

.
Weighted mean complete-family time	Illustrative campaign time
6 minutes	1.8 hours
12 minutes	3.6 hours
15 minutes	4.5 hours

This model is valid only when the six-lane throughput is actually achieved. Multithreaded Kira jobs, serialization, memory contention, and dependency tails can invalidate it.

A credible launch gate is therefore: hard cases finish end-to-end roughly within 10–15 minutes, ordinary cases are substantially cheaper, the inventory-weighted projection fits the target with margin, and the concurrent wave shows no uncontrolled tail or resource contention. One fast hard case is not enough.

Keep the existing pool, but account for CPU consumers globally

Do not equate six family subkernels with six CPU consumers when each can launch Kira.

Enforce

active Wolfram CPU workers+Kira threads+other native compute threads≤8,

excluding genuinely idle controllers waiting for subprocesses.

For example, two three-thread Kira reductions plus two single-core stage-2 jobs use the full budget. Six Kira jobs with eight threads each do not.

Keep one main kernel as coordinator and the second available for bounded diagnosis; do not create another production pool. Test Kira thread caps for aggregate completed-family throughput, not just single-family latency.

Also avoid routing frequent algebraic work through shared functions: Wolfram documents that these execute on the main kernel and synchronize accesses there, which can serialize otherwise parallel workers. 
Wolfram Cloud

Consult at decision boundaries: after the hard finite-solution pilot, after the first concurrent wave, or before a proposed change to function class, alphabet, or order scope. A compact timing breakdown and one proposed bounded intervention are more useful than waiting through hours of retries.

3. Minimum artifacts and stages: keep V2 and explicit finite WXF

Do not introduce another format migration tonight. The existing formats are sufficient if their mathematical contracts are enforced.

Retain two primary artifact classes and a small campaign-status record:

Artifact	Minimum mathematical content
V2 closed DE	Ordered master basis; normalization and coefficient-to-basis map; all variable connections; current block decomposition; coefficient field/chart; closure and validation status. Attach any accepted partial transformation and its inverse through the existing representation.
Explicit finite solution WXF	Requested master/order coefficients; explicit shared scalar/function definitions; constant symbols and their order ranges; fixed base point/path/branch data; actual solved order coverage; reference to the exact basis/presentation being solved.
Campaign status	Current stage, cumulative costs, completed order coverage, checkpoint location, and precise incomplete/failure reason. Not another mathematical data format.

Shared expression references are acceptable when they point to already explicit definitions. They are not acceptable when they defer a solve. Compression and expression sharing do not make an otherwise explicit solution lazy.

Three worker stages are enough

DE closure. Batch derivative reductions within each closure round and reuse the family’s reduction state where supported. Save the closed DE before canonicalization. Include closure-only masters in the internal solve requirements even when their direct coefficient-table entries vanish.

Bounded representation preparation. Preserve explicit off-diagonal products, cache the active-root information and compiled evaluation plan within the job, and retain accepted partial transformations. Keep development diagnostics off the production route. Do not introduce per-letter scoring by default without aggregate timing evidence.

Finite solve, acceptance, and write. Compute all required coefficients before emitting a completed status. Validate against both kinematic equations, not only the tangent to one chosen path. Modular checks can test rational coefficient identities in the explicit representation; use numerical checks where evaluation of the actual special functions is required. Boundary constants remain symbolic but must be kinematics-independent.

The pushed transport consumer still visibly requests IrreducibleDiagonalBlocks, which supports your concern that a nominal V2 tag alone is insufficient. Fix every active producer/consumer of this semantic field together, reject stale records, and recompute the cheap decomposition from the current DE rather than providing silent aliases.

No-backward-compatibility authorization is useful here: one current contract and explicit refusal of stale data, not a new schema for organizational elegance.

Track three separate counts: closed DEs, finite solutions complete for their requested order windows, and physically matched solutions. A canonicalized-family count or a total of 998 coefficients is not a substitute for the second count.

4. Required orders: the coefficient-table rule is correct only in its declared scope

For

H=
i
∑
	​

c
i
	​

(ϵ,z)I
i
	​

(ϵ,z),

let

v
i
	​

=val
ϵ
	​

c
i
	​

,I
i
	​

=
k≥ℓ
i
	​

∑
	​

ϵ
k
I
i,k
	​

.

To obtain H through order N, a conservative individual-master upper cutoff is

K
i
	​

=N−v
i
	​

.
	​


But this means the needed coefficient range, generally from ℓ
i
	​

 through K
i
	​

, not just the single coefficient I
i,K
i
	​

	​

. The coefficients c
i
	​

 themselves may need expansion through N−ℓ
i
	​

.

The pushed requirement module implements the arithmetic N−v
i
	​

. Its arithmetic validation does not prove that the supplied coefficient valuations include all physical factors, or that downstream consumers interpret the returned orders as sufficient expansion cutoffs.

Four specific safeguards

Use the coefficients multiplying the basis actually solved. If I=SJ, order requirements come from cS, or a conservative propagation through S, not unchanged coefficients c. Epsilon poles in transformations and internal DE couplings can require deeper coefficients of intermediate masters.

Require lower-order bounds separately. Coefficient-table poles do not determine the masters’ starting orders ℓ
i
	​

, nor those of boundary constants. Preserve whether these bounds are proved, inherited, or explicitly assumed. A sampled leading coefficient can vanish and make the observed valuation too high; that can incorrectly shorten the required expansion.

Distinguish pointwise and distributional valuation. On 0≤z≤1,

z
−1−aϵ
=−
aϵ
δ(z)
	​

+
n≥0
∑
	​

n!
(−aϵ)
n
	​

[
z
log
n
z
	​

]
+
	​

.

At fixed z>0, the prefactor has epsilon valuation zero. Distributionally, it has valuation −1.

Consequently, the finite delta coefficient of

z
−1−aϵ
(f
0
	​

(z)+ϵf
1
	​

(z)+⋯)

depends on f
1
	​

(0). A pointwise coefficient-table estimate can miss that extra order. Multiple endpoints and subtraction/convolution operations mean that “add one extra order everywhere” is not a general solution.

Do not infer full physical coverage from inventory coverage. Measures, endpoint factors, normalization factors, counterterms, evanescent projectors, and later convolutions must either be included in the order calculation or explicitly excluded from its scope. Uniform endpoint behavior is additional information; pointwise finite coefficients alone do not establish distributional completeness.

For this regeneration, the honest target is:

Explicit boundary-parameterized master solutions through the orders required by the current coefficient inventory and stated additional factors, with endpoint/distribution completeness not yet asserted.

That is a substantive mathematical deliverable, not a downgrade.

Recommended overnight decision

First complete CF259’s finite solution from its valid partial checkpoint and verify CF303’s general-DE completion path. Then run the concurrent throughput pilot and launch only against its measured projection. Keep optional canonicalization cumulatively bounded and resume accepted work.

Add the characteristic-zero promoter only in the narrow form above—especially the constant-shift nullspace test for CF303’s 192-column system. Do not spend the night discovering a general no-go theory, changing formats again, or obtaining full canonicalization where an explicit finite solution already meets the requested scope.