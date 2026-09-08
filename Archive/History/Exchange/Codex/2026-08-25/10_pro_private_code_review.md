# Independent ChatGPT Classic Pro review — mathematics and performance extract

**Date received:** 2026-08-25/26 PDT  
**Conversation:** existing `Assess Multiquadratic Pipeline` Pro chat  
**Code reviewed:** supplied archive of `f3738b1eac5d00537630dffb248855f3bc22975c`, including all 34 files under `FeynFacet/Private`  
**Independence:** this is a condensed, method-only extraction of Pro's response. Codex's conclusions and benchmark were not added. The full exchange remains at `/home/maxzhang/factorization-and-loops/External/ChatGPT/Records/2026-08-25/01_private_hardening_review.md`.

The original response also discussed persistence and deadline hardening. Those sections are omitted here because the requested review is the actual mathematics, algorithms, generality, and performance.

## Pro's method verdict

Pro found no mathematical defect in the XOR-grade multiquadratic algebra or the recursive quadratic-tower inverse. The exact product check around the tower inverse is a sound acceptance guard, and the older linear-solve inverse should remain only as an independent oracle until the tower path has more production mileage.

Pro also agreed that the current direct multiquadratic terminal contract is correctly limited to

- `Status -> ModularConsistent`;
- `SolutionContract -> OneFormsNotCertified`.

It therefore does not install the result as a solved ε-form. Closed one-forms cannot be promoted to canonical dlogs without explicit verified potentials.

## Performance conclusions

### The measured bottleneck is real, but the entries are not uniform

The attribution

\[
  1439.7\;\mathrm{s}=1400.5\;\mathrm{s}\;\text{decomposition}
  +39.2\;\mathrm{s}\;\text{everything else}
\]

is valid. Targeting `multiquadraticFieldDecompose` is therefore correct.

However, the claim that this is eight approximately equal 175-second entries is contradicted by the supplied measurement: the tested 72,021-leaf entry took about 2.7 seconds and contributed only 0.19% of the decomposition stage; the other seven contributed about 1,397.8 seconds. Linear extrapolation from leaf count is not valid. Dynamic scheduling is required.

### Recommended algorithmic order

1. **Reduce to each entry's active root subset.** Determine which generators actually occur in each scalar, decompose/evaluate only in that local subfield, then lift channels to the declared global grade ABI with `multiquadraticLiftLocalChannels`. A rank-one or rank-two scalar should not pay rank-three costs merely because the containing family declares three roots.

2. **Preserve the expression DAG.** Keep forcing entries as base plus sums of products, canonicalize/decompose distinct leaves once, perform products in grade arithmetic, and compose only when a consumer truly needs a symbolic expression. Whole-block `Together` destroys this advantage.

3. **Evaluate in the finite-field grade algebra.** At a prime, evaluate directly in
   \[
     \mathbb F_p[r_1,\ldots,r_d]/(r_i^2-\Delta_i).
   \]
   This does not require the radicands to be quadratic residues. Invert denominator elements through the recursive norm/tower algebra and reject zero-norm samples. Use all Galois sign branches at occasional split points as an independent held-out oracle.

4. **Reconstruct sparsely and per entry if global channels are needed.** Use projective/sparse support discovery, exploit shared support and denominator structure across channels and ε images, and interpolate ε separately where practical. Do not use a blind bidegree rectangle.

5. **Discover denominators structurally.** Start from rational denominator factors in the DAG and norms of algebraic denominator elements; use modular factorization/local valuations for multiplicities; black-box rational reconstruction should be the last resort. Do not expand a characteristic-zero rank-three norm merely to guess a denominator.

6. **Batch and schedule by measured cost.** Use a dynamic queue, largest estimated entries first, per-task byte/time caps, and per-entry checkpoints. Within an entry, batch all grade channels and points; share root-square values, monomial tables, denominator factors, and ε powers.

7. **Fall back per entry.** Persist every successfully reconstructed entry. If one entry fails to stabilize, symbolically process only that entry; do not discard seven modular successes and then pay the full symbolic block cost.

8. **Accept with independent evaluations.** A reconstructed object should pass held-out points, ε values, and primes; sign-branch tests at split points; zero-norm and unsupported-radical rejection; and, where a reusable exact artifact is required, coefficientwise recomposition in the multiquadratic basis rather than one giant global `Together`.

Pro ranked local active-root reduction, DAG preservation, grade-algebra evaluation, per-entry checkpoint/fallback, and dynamic scheduling ahead of further FLINT/RREF tuning. Modular elimination is not the present bottleneck once a system has been assembled.

### Retime recommendation

Do not retime the old commit. Time the eight current entries separately, identify the dominant one or two, and compare the new modular/DAG provider against the symbolic oracle on those entries. Historical timing does not affect the next design decision.

## Generality conclusions

- No executable code in `FeynFacet/Private` dispatches on CF259, CF300, CF303, or the current result directory. Family names occur in comments and measurement narratives, not runtime branches.
- The implementation is generic in variable names but intentionally bivariate. There are many explicit two-variable signatures. `CertifyFamilyEpsilonForm` should reject three independent source variables rather than silently truncating `{s,t,u}` to `{s,t}`. Using `s,t,u` is valid only after a kinematic relation reduces them to two independent coordinates.
- The strip engine's rank-three ceiling is a legitimate declared scope boundary, but it should be a documented capability/resource limit rather than an implicit assumption.
- Move dated family performance narratives out of loaded implementation files and keep short invariant comments in Private.

## Conciseness recommendations

Before another campaign:

- retire the private `CompileShards` path after equivalent tests exist on the real per-entry provider;
- unify plan/backend protocol rather than hard-coding different accepted backends in solver and resume layers;
- retain the old linear inverse only as a test oracle;
- do not spend the immediate optimization cycle splitting the 7,627-line multiquadratic file or merging all algebra implementations—first establish the coefficient-provider and reconstruction interfaces, then split along those boundaries;
- do not replace correct bounded caches with a new cache policy while decomposition dominates.

## Pro's answers relevant to Fable's proposal

1. The recursive field algebra is not the remaining blocker.
2. Explicit dlog relations must be established once; a closed-form-only result must remain non-installable.
3. `ResumeGate -> ModularThenExact` is the correct default while exact replay remains the acceptance decision; pure modular should remain explicitly probabilistic.
4. Modular evaluate/reconstruct is sound if it operates on the expression DAG/grade algebra, exploits active root subsets, reconstructs and checkpoints per entry, and falls back per entry. Pro considers these architectural changes mandatory for the proposed route.
5. Do not retime the old commit.
6. Measure the dominant current entries and the new provider rather than running another whole-family symbolic timing.

**Independent Pro conclusion:** the large remaining speedup is algorithmic—avoid global characteristic-zero field decomposition, preserve the DAG, evaluate in the finite-field algebra, and reconstruct only the objects that a downstream consumer truly needs.
