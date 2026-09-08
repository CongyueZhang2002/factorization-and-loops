# Codex response: CF300 (12,9) multiquadratic state and optimization questions

Date: 2026-08-24 23:18 PDT. This is a read-only assessment of the live
package/run and the exported evidence. No package source was changed, no
kernel was launched, and no process was stopped or signalled.

## Immediate live-run diagnosis

The current end-to-end process is alive and compute-bound, not sleeping or
waiting on the modular solver. At 23:18 PDT its Wolfram kernel (PID 1955205)
was at 114% CPU, about 2.09 GB RSS, and had been alive for 6733 s. The last
log line is still

```text
[multiquadratic] prepared: rank 2, 1576 unknowns, 32 equations per point
```

at 21:51:42. Therefore it has spent about 87 minutes in the serial
`multiquadraticStripCompile` call. It has not reached modular sampling or
`RowReduce` yet. This is consistent with the projected compile cost for the
70-letter alphabet; it is not evidence of a deadlock.

One operational correction is important: the advertised three-hour deadline
is cooperative, not a hard deadline around compilation. In
`solveEpsFormStripMultiquadratic`, the deadline is checked before preparation
and only **after** the opaque `multiquadraticStripCompile` returns. Thus this
compile can overrun the three-hour wall before the engine notices the expired
budget. Future runs need either internal compile checkpoints or separately
brokered compile tasks if the budget is meant to be real.

## Q1 — Why the old DRCA compile looked seven times faster

There is no hidden `CoefficientRules` trick in the old V1 DRCA. Static
comparison shows that its path is essentially the same as the promoted V1:

1. `Together` each rational channel;
2. `Expand` numerator and denominator;
3. `CoefficientRules[..., {x,y,eps}]`;
4. group equal `(x,y)` exponents and retain an epsilon coefficient row.

The quoted timings are not for the same compiled object, despite both being
called A0:

- the old cached DRCA object has 36 one-forms, 144 residue unknowns and 624
  total unknowns;
- the post-mortem package object has 26 one-forms, 104 residue unknowns and
  584 total unknowns;
- their preparation ABI fingerprints differ;
- the first eight diagonal forms agree, but the remaining stored one-form
  trees do not;
- the old 36-form tree occupies about 1,740,707 textual characters and has
  34,764 printed `Sqrt[...]` occurrences, while the new 26-form tree occupies
  about 2,341,990 characters and has 44,391 occurrences.

The latter is fewer forms but a substantially more expanded algebraic object,
and `Together`/field decomposition scale very nonlinearly with that expression
shape. In addition, the post-mortem `mq3_compile.wls` deliberately called the
conservative public compiler without the new `ForcingChannels` reuse option,
so it decomposed `BBar` again. The live end-to-end route does pass
`"PreparationValidated" -> True` and the prepared forcing channels, so the
4872 s post-mortem number is an upper bound, not a like-for-like prediction.

Consequently, porting the old whole-assembly cache is not the right immediate
repair. It is source- and ABI-bound to the old 36-form object and cannot
validate as the new 70-letter assembly. A cache helps only after the exact
alphabet is frozen.

The structural fix I recommend, in order, is:

1. Keep an immutable compiled **equation core** (`E`, `C`, `BBar`, root data,
   gauge denominator) separate from the ansatz. Support changes should do no
   algebraic compilation, and an exact-prefix alphabet extension should
   compile only the suffix.
2. Intern exact scalars and canonical numerator/denominator polynomials with a
   hash-bucket plus `SameQ` collision check. Decompose and compile each unique
   value once.
3. Preserve a compact algebraic letter/potential record through compilation.
   For `L=A+B r`, compile `dlog L` directly through its two grade channels and
   norm `A^2-B^2 delta`; do not first materialize a huge repeated
   `D[L]/L` expression. General multigrade letters can use the same field
   multiplication/inversion ABI.
4. Reuse the canonical rational pair returned by field decomposition; do not
   call `Together` a second time merely to feed `CoefficientRules`.
5. Only then broker the remaining unique one-form suffix into two to four
   independent compile shards. Naively parallelizing all current leaves
   multiplies both duplicated work and peak memory.

The External `DirectRootChannelCompilerV2.wl` already prototypes the
core/ansatz split, collision-checked pools, canonical rational pairs and
append-only rebind. Its long synthetic managed run never reached a promotion
verdict, and its independent audit records compatibility/provenance fixes that
are still required. Therefore reuse its design, not an unvalidated V2
artifact. The earlier, simpler cached-core `DRCARebindAnsatz` evidence is
still useful: a combined support/denominator/appended-form rebind took about
12 s versus about 691 s for a fresh old-V1 compile, with exact equality.

## Q2 — Are individual letter norms the complete gauge denominator family?

No. They are the correct first family, but not a completeness theorem.

Any denominator in a finite multiquadratic field can be rationalized to a
base-field denominator using its full field norm. For a single-root factor
`A+B r_i`, this is `A^2-B^2 delta_i`, exactly the rule now implemented. But a
gauge can have a mixed-grade polar factor such as

```text
P0 + P1 r1 + P2 r2 + P12 r1 r2
```

whose full Galois norm is a rational polynomial not required to factor into
the norms of the individual alphabet letters. Gauge poles may also be
inherited from `E`, `C`, `BBar`, root logarithmic derivatives, or infinity,
not from the final dlog alphabet alone.

For a general solver the rational denominator candidate set should be the
irreducible-factor union of:

- exact rational-channel denominators of `E`, `C` and `BBar`;
- root-square/log-derivative denominators and branch factors;
- rational alphabet factors and norms of algebraic alphabet letters;
- full recursive field norms of any mixed-grade denominator actually exposed
  by the channel/pole census.

Do not enumerate arbitrary mixed norms blindly. Start with this measured
polar set, run the modular gauge system, and enlarge only from an obstruction
or a denominator census of the failed residual. For CF300 (12,9), admitting
the four repair-letter norms is a sound low-cost attempt; a negative full
gauge solve would not prove the alphabet wrong until the broader polar set has
also been checked.

## Q3 — A principled letter-completeness criterion

The norm-factor heuristic is not complete. It preferentially finds
single-root principal letters and can miss mixed-root letters, a Galois orbit
of divisors, or a logarithmic form whose polar divisor is not represented by
one of the guessed principal functions.

The principled object for a fixed strip is the logarithmic differential space
on the normalization of the multiquadratic cover. A practical finite version
is:

1. form the complete polar divisor `D` from the exact channel denominators,
   all branch divisors and the divisor at infinity;
2. factor/pull back these divisors on the cover and close them under the
   Galois sign group;
3. compute residue vectors of candidate closed one-forms at every prime
   divisor in `D`;
4. require the candidate residue map to span the residues demanded by the
   integrability source, and require the remaining regular closed form to
   vanish (or be included explicitly);
5. then run the full affine gauge system. Its consistency is the sufficiency
   test for the chosen gauge-function space.

Equivalently, one wants a spanning set for the relevant part of
`H^0(Omega^1(log D))`, modulo exact rational differentials, with the proper
Galois grading. Computing that space globally can be expensive, but the
residue version is directly compatible with modular sampling.

For adaptive discovery, use the left obstruction witness to identify the
missing divisor/Galois orbit, then solve a low-degree **mixed-grade** potential

```text
P = Sum_g P_g(x,y) r_g
```

whose full norm is supported on `D`. This is much less blind than enumerating
all `A +/- sqrt(delta)` templates. The four discovered letters have now
removed the gauge-independent integrability defect at two images, which is
strong evidence that the missing residue orbit was found. It is necessary,
not yet a full-gauge certificate.

## Q4 — Compile brokering versus FLINT

Yes: for this engine, compilation decisively outranks FLINT. The measured
sample took 7.8 s and Wolfram affine solve 0.7 s, versus 2429 s preparation and
4872 s compilation. Replacing a 0.7 s solve cannot affect the present wall
time.

The priority should be:

1. core/ansatz split, compact letter channels and unique-scalar/polynomial
   reuse;
2. broker only the remaining unique compile work;
3. broker independent `(prime, eps)` images after the shared assembly exists;
4. wire FLINT when repaired/larger ansaetze make affine elimination material.

The live run is serial inside compilation and cannot be accelerated in place
by currently idle subkernels. Parallel modular images would also not help it
yet because it has not produced a compiled assembly. For a future 70-letter
run, two to four compile shards are safer than eight simultaneous symbolic
`Together` workloads; aggregate their immutable sparse artifacts in the main
kernel and validate the merged fingerprint once.

## Q5 — Required contract for finite-field row-gauge construction

I would require the following before replacing the symbolic construction
stage:

1. Preserve a sparse tagged term DAG for
   `A + A.D - D.A - dD`, `S + S.D`, and `SInverse - D.SInverse`.
   Differentiate `D` once. Never form `Together[Total[terms]]` during
   preparation. Even a speculative exact zero/cancellation test should not
   materialize the sum; keep the record and prune it after modular images.
2. Pin the multiquadratic ABI: canonical root ordering, grade-mask ordering,
   parameters, target indices and source fingerprint. A resumed artifact
   with any mismatch must fail closed.
3. Distinguish bad primes, denominator-zero points, ramified points and
   non-split points from mathematical inconsistency. These are sampling
   rejections, never zero equations.
4. Enforce the structural block precondition that makes the truncated row
   formula valid, and preserve untouched entries by `SameQ`.
5. For every accepted point, evaluate all required conjugates and perform the
   Hadamard grade/conjugate round trip, or use a directly compiled grade ABI
   and reserve sign branches as an independent differential oracle.
6. Separate discovery images from holdouts. Require stable rank/pivot
   signatures across at least two primes and independent regulator/point
   images before reconstruction; verify the reconstructed touched entries on
   fresh holdouts.
7. Certify the assembled transformation identities pointwise: `S.SInverse=I`
   and the transformed-connection formula, including derivative terms. The
   final family certificate remains the acceptance boundary.
8. Reconstruct only touched entries and only after their degree/denominator
   bounds are identified. Preserve checkpointed image records so a failed
   reconstruction can be widened without repeating evaluation.
9. Let the outer broker own parallelism. Workers receive immutable point or
   compile shards and acquire no nested kernels.

The existing `FamilyRowGaugeFiniteField.wl` prototype already supplies most
of the semantic oracle: sparse records, precomputed derivatives, typed point
rejections, canonical roots, all conjugates and Hadamard round trips. The
headline production change is to make its term records the construction
representation itself and add interpolation/reconstruction, rather than
using it only to check a connection that was first constructed symbolically.

## Bottom line

Fable's four-letter repair is a real advance: it removes a proven
gauge-independent obstruction. The present slowness is not finite-field
linear algebra; it is repeated symbolic materialization and compilation of a
very expanded algebraic one-form tree. The next implementation target is a
cached equation core plus compact, append-only letter-channel compilation.
FLINT and modular-image parallelism come after that shared assembly exists.
