# Assessment: standardized multiquadratic optimization and package generality

Date: 2026-08-23  
Audited HEAD: `52ce634`  
Package source was not edited by this audit.

## Verdict

The promoted multiquadratic arithmetic and strip engine are mathematically
generic and robust **for two independent differential variables and at most
three independent square roots**.  A complete synthetic rank-three solve in
`{s,t}` with `u -> 1-s-t` reached `ModularConsistent`, the same problem renamed
to `{a,b}`/`ep` produced the identical ABI hash, unrelated family/sector
metadata produced the identical ABI, and three unrelated polynomial root
triples all prepared and compiled.

It is not yet an end-to-end package feature, and the package does not yet meet
the stricter requirement that no current-project/process convention remain:

1. `SolveEpsFormStripInFrame` still returns `NoRationalStripChart` before it can
   call the promoted multiquadratic engine.  Nothing outside the engine's own
   tests calls `solveEpsFormStripMultiquadratic`.
2. `FamilyRowGaugeFiniteField.wl` is not in `$feynFacetPrivateFiles`; normal
   package loading does not define it, and there is no production caller.
3. The two latest squeeze patches (scalar-local root-free decomposition and
   epsilon-content-GCD census) remain adjacent External patches and are absent
   from the package/production path.
4. Three independent variables `{s,t,u}` are deliberately unsupported.  The
   current implementation is valid when the Mandelstam relation has first
   eliminated one variable; it refuses a true three-direction call rather than
   silently certifying two slices.
5. Executable compatibility defaults still generate `CF<n>`, select
   ``Global`v``, ``Global`w``, ``Global`eps``, and insert a `Codex` workspace path
   component.

Therefore the standardization is a sound **engine promotion**, not yet a
finished production integration or a fully process-neutral package.

## Tests run

Ten committed suites were run standalone under one main kernel, sequentially:

| Suite | Assertions | Result |
|---|---:|---|
| `t_package_generality` | 30 | PASS |
| `t_generality_renamed_variables` | 52 | PASS |
| `t_multiquadratic_algebra` | 75 | PASS |
| `t_multiquadratic_algebra_differential` | 24 | PASS |
| `t_multiquadratic_strip_solve` | 80 | PASS |
| `t_family_row_gauge_finite_field` | 35 | PASS |
| `t_family_artifact_read` | 15 | PASS |
| `t_multiquadratic_transport_frame` | 14 | PASS |
| `t_finite_field_adversarial` | 13 | PASS |
| `t_finite_field_affine_rref_backend` | 31 | PASS |
| **Total** | **369** | **PASS** |

The new adjacent red-team test is
`test_standardization_generality_adversarial.wls`.  It ran in 13 seconds
including package loading and reported **12 PASS / 7 FAIL**.  The failures are
intentional strict-contract probes and are itemized below.  It used one main
kernel, no subkernels, and started or stopped no external process.

An adjacent rank-three scalar microbenchmark then compared the package's full
decomposition with the staged grade-zero shortcut on 240 distinct rational
functions.  Both paths returned exactly the same eight-channel vectors and
the candidate independently recomposed every vector.  Median times over three
trials were **0.402831 s current vs 0.038896 s candidate: 10.36x faster**.
This is a compiler microbenchmark, not a claim of 10x whole-family speedup.

## Findings, ranked

### P1 — chartless triple-root work is not wired into the public solver

`SolveEpsFormStripInFrame` has the correct two-variable type gate and rational
finite-field fallback, but after root census it asks for a rational chart and
returns `NoRationalStripChart` immediately when none exists
(`TransportCharts.wl:487-490`).  The promoted direct multiquadratic entry point
exists at `MultiquadraticStripSolve.wl:2207`, but a source-wide caller search
finds only its definition and its direct unit test.

The red-team fixture proves the distinction on the same input:

- private promoted engine: `ModularConsistent`, rank 3, all eight sign branches;
- public `SolveEpsFormStripInFrame`: `NoRationalStripChart`.

This is the principal integration stop for the chartless triple-root families.
It should be wired as a **recorded modular candidate**, not treated as a solved
epsilon form: the engine correctly returns `OneFormsNotCertified` until an
exact dlog-potential contract is supplied.

### P1 — the standardized row-gauge finite-field implementation is not loaded

`FeynFacet.m:386-398` loads `FamilyRowGauge.wl`, the neutral multiquadratic
algebra, and the strip solver, but not `FamilyRowGaugeFiniteField.wl`.  The only
current consumers are tests that explicitly `Get` the file.  Consequently the
row-gauge oracle has been source-standardized but not package-integrated.

Either load and connect it through an explicit production dispatcher, or keep
it labelled as a prototype.  Merely adding it to the load list without a
caller would not complete the workflow.

### P2 — root declaration order fragments the canonical preparation ABI

Reversing `{s,t,1-s-t}` in the frame declaration leaves the sorted canonical
roots, equations, support, and mathematical field unchanged, but changes the
preparation fingerprint.  The test isolates the sole differing payload field:

```text
DIAGNOSTIC  differing ABI fields: {RootSourceIndices}
```

`RootSourceIndices` is inserted into the hashed payload at
`MultiquadraticStripSolve.wl:591-592`; its only other occurrence is the
diagnostic preparation field at line 711.  No evaluator/compiler consumes it.
This is not a wrong-answer bug, but it defeats artifact/cache reuse and makes
equivalent caller declarations ABI-incompatible.

Recommended fix: retain source indices as non-hashed provenance, remove them
from the canonical mathematical payload, bump the preparation schema, and add
the forward/reverse declaration regression.  The canonical root squares and
root fingerprints already protect the grade ordering.

### P2 — the implementation is two-variable, not three-variable

The exact patterns and row layout are two-dimensional throughout:

- public in-frame solver: `variables : {_Symbol,_Symbol}`;
- multiquadratic preparation: the same gate at
  `MultiquadraticStripSolve.wl:630-633`;
- support monomials `{i,j}`, two one-form components, and two derivative
  directions;
- family certificate: two transformed matrices and one flatness identity;
- diagonal class campaign: `ClassVariablesNotTwoSymbols` for any other arity.

The audit establishes both sides of the contract:

- **PASS:** a problem naturally written with Mandelstam `{s,t,u}` works after
  `u` is algebraically eliminated, and remains generic under symbol renaming;
- **safe refusal:** a true independent `{s,t,u}` call is not truncated;
- **safe refusal:** an unsampled independent `u` in a root square reaches the
  exact symbolic frame but is rejected by the context-free modular ABI.

If “anything described by `s,t,u`” means the usual two-independent-variable
Mandelstam surface, document the elimination rule at every entry point.  If it
means three independent differential variables, this is a real feature gap,
not a naming fix: direction arrays, multi-index supports, sampling, Jacobians,
and all three pairwise flatness equations must be generalized.

### P2 — executable process conventions remain

The existing generality suite intentionally preserved compatibility defaults,
so it does not test the stricter requirement in the current request.  The new
test exposes four live assumptions:

1. `$canonicalFamilyPrefix = "CF"` and generated symbols are ``Global`CF<n>``
   (`CanonicalFamilies.wl:40,49-55`).
2. An undeclared class uses ``{Global`v,Global`w}``
   (`CanonicalBlocks.wl:232-233`).
3. A regulator-free undeclared class uses ``Global`eps``
   (`DiagonalBlockEpsForm.wl:1755-1762`).
4. Kira and coefficient workspaces insert an agent-specific `Codex` component
   (`Reduction.wl:564-572`, `CoefficientStore.wl:135-136`).

These do not contaminate an explicitly declared `{s,t}` calculation, but they
violate a literal process-neutral package contract.  Prefer registry-owned
name generation, required/inferred variable metadata with a typed ambiguity,
and a configurable neutral workspace namespace.  If backward compatibility is
needed, put it behind an explicit legacy mode rather than `Automatic`.

### P2 performance — the last two squeeze changes were not promoted

The current package contains no `RootFreeFastPathCount`, and rank-positive
`multiquadraticFieldDecompose` still performs branch replacement, polynomial
field reduction, and field inversion even for a scalar that contains no root.
The staged implementation and its adversarial proof remain in:

- `finite_field_scalar_rootfree_squeeze_2026-08-23_xh/0001-scalar-local-root-free-fast-path.patch`;
- `finite_field_scalar_rootfree_squeeze_2026-08-23_xh/0002-target-epsilon-free-factor-census.patch`.

The first idea should be ported to the package's neutral decomposition routine
with full `2^rank` padding and an exact compose check.  The second currently
targets the external discriminator driver; its coefficient-GCD theorem should
be moved into whatever package API owns support/letter census before that
workflow is called standardized.  Physical same-result and timing gates from
the staged assessment still need to be run.

The adjacent neutral-engine microbenchmark confirms that the missing first
patch is material even before a physical family test: on 240 rank-three
rational scalars, current full decomposition took a median 0.402831 s and the
exactly recomposed grade-zero path took 0.038896 s (**10.36x**), with
`SameQ -> True`.  The driver is `benchmark_rank3_rootfree_scalar.wls`.

### P3 — source comments retain project provenance

The executable comment-stripped scan is clean of literal family IDs and
absolute project paths, and the family-chart registry ships empty.  However,
under the request's literal “there should not be anything specific” wording,
comments are not clean: 10 of 35 package Wolfram sources mention concrete
`CF<n>` IDs and 15 mention `Codex`.  This is provenance, not runtime coupling,
and the earlier generality plan explicitly declared it out of scope.  If the
package itself is intended for external distribution, move case-specific
measurements to `WORKLOG.md`/Design notes and keep only generic explanations in
source comments.

## What passed adversarially

- Full rank-three direct modular solve in `{s,t}`, with `u=1-s-t`.
- All eight sign branches at the held-out prime.
- Bit-identical ABI under `{s,t},eta -> {a,b},ep`.
- Bit-identical ABI after arbitrary family, sector, lower-sector, and campaign
  metadata changes; metadata may also be omitted.
- Three unrelated polynomial root triples prepared and compiled, demonstrating
  that the engine is not keyed to Kallen roots or the current family catalog.
- An independent extra symbol and a three-variable call fail closed.
- Existing rank 0-3, rectangular block, differential, corrupted-artifact,
  reserved-option, unseen-prime, and affine-RREF adversaries: all green in the
  committed suites.

## Recommended next sequence

1. Fix the root-order ABI defect and add its regression.
2. Add an explicit chartless-multiquadratic dispatch to the public/sector path,
   preserving `ModularConsistent != Solved` until dlog potentials certify.
3. Decide whether `FamilyRowGaugeFiniteField` is production code; load and wire
   it if yes, otherwise move/label it as a prototype.
4. Port and physically benchmark the scalar-local root-free fast path; then
   package the epsilon-content census at the support-discovery boundary.
5. Remove/configure `CF`, ``Global`v,w,eps``, and `Codex` compatibility defaults.
6. State the variable-arity contract explicitly: two independent Mandelstam
   variables after eliminating `u`, or undertake a genuine n-variable refactor.
7. Only after those changes rerun the 369 committed assertions plus this red
   test and promote the relevant strict checks into `Tests/`.
