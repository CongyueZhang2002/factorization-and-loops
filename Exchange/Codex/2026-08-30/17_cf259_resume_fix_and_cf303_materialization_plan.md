# CF259 prepared resume fix; CF303 materialization replacement

Timestamp: 2026-08-30 20:08 PDT

## CF259 (27,7)

CF259 is banked through lower sector 8. `(27,9)` and `(27,8)` are complete; the next block is `(27,7)`, a consistent two-root `KallenQ4a` system, not a genuine triple-root obstruction.

The preserved preparation avoids the already-paid 1,218.3 s operand interning, 18.14 s assembly, 88.85 s Jacobian pullback and 93.74 s finite-field preparation. The accepted sparse-first recipe has 3,003 monomials and gives a `12088 x 12076` system with 109,070,024 nonzeros, rank 12072, nullity 4 and consistency. One FLINT plan discovery must be redone and persisted; the measured discovery-scale pilot was 793.62 s with 12.10 GiB peak.

A real correctness bug blocked that resume: native plan discovery discarded `ParticularSolution` and `NullspaceBasis` while sealing the reusable plan, then attempted to read them back from the sealed plan, whose ABI intentionally omits image-specific vectors. The minimal general fix now preserves those vectors before sealing.

- commit: `fd525c1` (`fix finite-field discovery image reuse`)
- pushed to `origin/main`
- existing focused suite: `Tests/FiniteField/t_finite_field_affine_rref_backend.wls`
- result: 34 OK, 0 FAIL, including native pilot and whole-block solve

No extra validation layer was added.

The prepared-resume driver still needs to consume the preserved preparation/support without re-entering the top-level preparation ladder. The intended standalone output area is `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf259_27_7_prepared_resume`; do not launch it until CF303 releases the current memory-heavy work.

## CF303 (25,11) materialization wall

The live block paid 6,011.9 s to intern 103 transformed operands. The four exact chart entries then expanded in parallel; helper walls were `2446.0`, `2550.1`, and `2650.6` seconds, with the fourth local entry completing at about the same scale. Each job read 77--84 MB of referenced operands, grew to roughly 3--5 GiB, and emitted an approximately 0.5 GiB exact expression.

The dominant operation is the global

```text
Expand[Sum(termNumerator * missingCommonDenominatorFactors)]
```

in a free polynomial ring before the inactive quadratic-root relation is imposed. It is computation, not a check, but the arithmetic ordering is pathological.

The high-value generic replacement is selected-sheet finite-field materialization of the final chart one-form: evaluate the authenticated deferred AST at chart points, Hadamard-project inactive root signs at the points, reconstruct denominator-first over independent 61-bit primes, adaptively CRT/rational-lift, accept at one unseen prime, and emit the existing exact `OneForm` ABI. A complete one-prime reconstruction already exists for this block: 66,136 coefficients, 197.90 s cold (122.24 s with denominator stages reused), and 256/256 disjoint comparisons.

Detailed plan:

`/home/maxzhang/factorization-and-loops-codex/Diagnostics/Reports/cf303_25_11_materialization_bottleneck_plan_2026-08-30.md`

Sliced phase-two payloads can halve serialized helper input and contain RSS, but cannot remove the nonlinear expansion and are therefore secondary. More helpers, shared Wolfram loading and returning an unexpanded sum do not solve the wall. A Maple comparison is worth only one bounded fixture run and adoption only above a 3x gain.

