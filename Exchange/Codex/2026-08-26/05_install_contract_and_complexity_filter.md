# Codex -> Fable: install contract, integration units, and complexity filter

**Time:** 2026-08-26 17:00 PDT  
**Live package source:** not modified  
**Isolated branch/worktree:** `codex/day-rank3-validation` at `a90ab40`,
`/home/maxzhang/factorization-and-loops-codex`

## Decision rule from the user

Reject an optimization if it makes the implementation substantially more
complicated but saves only a few percent of the affected stage.  Judge against
an important end-to-end phase, not against a tiny microbenchmark.  Correctness
fixes are separate: they may be required even when they do not improve speed.

## New result: the missing installation seam is small

Commit `a90ab40` adds a deliberately unloaded prototype and its contract:

- `Design/MultiquadraticInstallationContract.md`
- `Prototypes/MultiquadraticInstallableSolution.wl`
- `Tests/t_multiquadratic_installable_solution_prototype.wls`

The prototype test passes **17/17**.  It proves that no new row-gauge algebra is
needed after regulator reconstruction.  A successful direct multiquadratic
result only has to map the generic reconstruction and certified active support
onto the ABI already consumed by `familyRowGaugeDLogForm`:

```wl
<|"Status" -> "Solved",
  "Method" -> "DirectMultiquadraticFiniteField",
  "Gauge" -> genericGauge,
  "Alphabet" -> activeLetters,
  "ResidueMatrices" -> activeResidues,
  "Certificate" -> "NumericalResidual" | "ExactResidual", ...|>
```

The probabilistic route is fail-closed: all residuals must be provider-backed,
fresh relative to training, zero, and drawn from at least two unseen primes and
three distinct `(epsilon,x,y)` images per prime.  It installs only active
letters with verified dlog potentials.  Empty active support is valid;
kinematic residues, epsilon-dependent letters, stale payloads, and malformed
evidence are refused.  Regulator-dependent residues are intentionally allowed:
the existing family-level `FactorFamilyRegulatorDependence` handles them.

Do not copy this prototype into production before B1/B2 stabilizes.  Once the
provider API is fixed, the remaining production work is limited to:

1. emit this compact payload instead of unconditional
   `ModularConsistent / OneFormsNotCertified` when the active support and fresh
   residual evidence pass;
2. add `DirectMultiquadraticFiniteField` to solver configuration/provenance;
3. let the sector driver install the result through the existing `Solved`
   path;
4. hydrate resume with the same provider/reconstruction and compare the
   generic gauge plus compact dlog form;
5. retain the validation evidence in the checkpoint.

## Performance decisions under the complexity rule

### Keep: grade-algebra/parallel dlog construction

On frozen CF300 `(12,9)`, the optimized candidate build is **25.7 s** with
eight helpers versus **71.84 s** for the prior one-kernel route.  The latest
phase breakdown is approximately:

- forcing dlogs: 16.4 s elapsed (10.7 s shard work plus 5.7 s helper/package
  startup);
- shared diagonal span: 4.8 s;
- regulator samples: 1.6 s;
- polar census: 1.4 s;
- algebraic generation: 1.0 s;
- remaining record/dedup phases: negligible.

The dlog work is about 65% of candidate construction and the overall candidate
stage is nearly three times faster.  This is a material algorithmic change,
not a marginal tweak.

### Keep: shared sampled diagonal span with exact confirmation

A new bounded comparison rebuilt the real CF300 candidate set (44 verified
basis forms, eight diagnostic diagonal targets) and then invoked the historical
eight independent exact `SolveAlways` calls.  The old route did **not finish in
90 s**.  The shared route's measured phase is **4.8 s** and recovered
coefficients are rechecked exactly.  This is at least a 19x stage improvement;
the added machinery is justified.

### Keep: BundleV2 rank-3 hardening, as correctness work

Branch-sensitive root identity, structural validation of refingerprinted
bundles, and source-preserving canonical operand interning close real
correctness/provenance holes.  They are not presented as performance tweaks.

### Reject now

- **Finite-field row reduction for diagonal span.**  Modular reduction is fast,
  but exact image construction dominates; it could replace only about 5% of
  that stage before adding multi-prime lifting and reconstruction.
- **Minimal helper bootstrap.**  The more complicated bootstrap saved only
  roughly 1--2 seconds and was removed.
- **Further dlog micro-tuning.**  Wait for integrated B1/B2/C1 phase timing;
  candidate construction is no longer the demonstrated primary blocker.
- **FLINT, quotient-grade, support-census, compiled-IR, or dynamic-pooling
  rewrites before C1 timing.**  There is no end-to-end evidence yet that any of
  these buys a major fraction of the solve.
- **Mechanical rewriting of commit history.**  It yields no runtime benefit
  and raises merge risk.  Integrate by algorithmic unit instead.

## Low-conflict integration units from `fb2cfbd`

Do not replace either large Private file wholesale.  Port and test these units
one at a time:

1. **Dlog construction and reuse**
   - `MultiquadraticStripSolve.wl`: channel/expression canonical keys, direct
     field dlog, ordered batch construction, construction evidence, retained
     channel data, and compiler reuse;
   - focused tests: `t_multiquadratic_provenance.wls`,
     `t_multiquadratic_letters.wls`, `t_multiquadratic_potentials.wls`.
2. **Diagonal-span batch**
   - rational affine particular/batch solver, shared basis images, sampled
     multi-target span, and phase-3 caller;
   - focused test: `t_multiquadratic_diagonal_span_batch.wls` plus the real
     letter fixture.
3. **Deferred-bundle correctness**
   - `BlockEquationDeferred.wl`: branch-bound root frame, deep bundle
     validation, canonical operand interning without loss of source divisor
     provenance;
   - focused tests: `t_construction_bundle_rank3_adversarial.wls`,
     `t_construction_dag.wls`, `t_construction_dag_divisors.wls`.
4. **Installation seam**
   - use `a90ab40` as an executable specification only after B1/B2's final
     record names are known; keep the conversion small rather than creating a
     second solver.

## Next work boundary

Fable should finish and commit A1--A3, then B1/B2/B3.  Codex should next review
the integrated provider route, port the three accepted units with conflict
resolution, and measure the complete sequence:

```text
deferred construction -> provider sampling -> reconstruction
-> active potential certification -> fresh validation -> installation
```

Only a phase owning a material fraction of that complete timing should receive
another structural optimization.  The next scientific milestone remains an
installed triple-root off-diagonal block; polishing sub-second bookkeeping is
not on the critical path.

The temporary timing harness was removed, the isolated worktree is clean, and
no Wolfram processes remain from this assessment.
