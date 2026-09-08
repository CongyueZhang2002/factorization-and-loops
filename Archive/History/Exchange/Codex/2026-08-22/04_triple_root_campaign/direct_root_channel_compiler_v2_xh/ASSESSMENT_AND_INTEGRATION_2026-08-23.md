# Direct root-channel compiler V2 assessment and integration note

## Scope and status

This directory is an External-only prototype. It does not modify Fable's
package, the current V1 direct assembler, a physical preparation artifact, or
any running mission. No Wolfram kernel was launched while authoring it.

The target is the measured CF300 sector-12 A0 compile bottleneck: about
682 seconds in `DRCAPrepare`, compared with about 6.9 seconds for the compiled
direct point sampler. The existing V1 compiler remains the reference. V2 must
not be called faster, correct, or production-ready until the staged managed
differential and physical benchmark both pass.

## What V2 changes

`DirectRootChannelCompilerV2.wl` implements five deliberately separable
changes.

1. **Root-free fast path.** Root squares, root logarithmic derivatives, the
   rational gauge denominator, and its logarithmic derivatives bypass
   `TRFieldDecompose`/`TRFieldCompose`. Each scalar is canonicalized once and
   compiled directly as its sole grade-0 channel.

2. **Recursive multiquadratic norm inversion.** For
   `a = u + v r`, `r^2 = delta`, V2 computes
   `a^-1 = (u - v r) (u^2 - delta v^2)^-1`, recursively in the lower-rank
   tower. It never calls the dense symbolic `LinearSolve` used by
   `TRFieldInverse`. Every recursion level independently multiplies the
   proposed inverse by the original coefficient vector and requires the exact
   unit vector. A zero norm or failed exact check returns `$Failed`; there is
   no silent dense fallback.

3. **Canonical rational pairs.** Decomposition returns each exact channel and
   its expanded numerator/denominator pair together. Sparse compilation
   consumes that pair directly; it does not call `Together` again. Each
   compiled polynomial is reconstructed independently from its sparse ABI and
   compared exactly with the expanded source polynomial.

4. **Collision-checked scalar and polynomial pools.** Exact structural hashes
   only select a bucket. `SameQ` is required before reuse, so a hash collision
   cannot alias two expressions. E, C, and BBar share one scalar pool. All core
   and ansatz forms share a polynomial pool. The pool stores no compiled
   function, stream, process, or kernel-local handle.

5. **Equation-core/ansatz split.** `DRCAV2CompileCore` compiles E, C, BBar,
   root data, and the rational gauge denominator once.
   `DRCAV2InstantiateAnsatz` compiles only one-forms and binds support and
   normalizations. `DRCAV2RebindAnsatz` does no algebraic compilation for a
   support/normalization-only change. If the old one-form list is an exact
   prefix, it compiles only the appended forms. Non-prefix changes fail closed.

Pooling and core reuse are intentionally sequential. Deduplicating expensive
symbolic work is lower risk than introducing nested parallel Wolfram work, and
it leaves the managed kernel pool under the caller's control.

## Versioned compatibility contract

The native V2 statuses are:

- `PreparedDirectRootChannelCoreV2`, format version 2;
- `PreparedDirectRootChannelsV2`, format version 2.

`DRCAV2ToV1Assembly` returns a `PreparedDirectRootChannelsV1` compatibility
view. The view preserves the V1 exact-channel tree, sparse-polynomial ABI,
column order, row order, semantic fingerprints, and assembly fingerprint. It
is bound to both the V2 compiler SHA-256 and the loaded V1 assembler path and
SHA-256. Before V2 stores or returns it, the view must pass the existing public
`DRCAAssemblyPreparationValidQ` boundary. The managed differential additionally
requires exact equality with a fresh V1 compilation, not merely equal samples.

The prototype reads two V1 private symbols solely to bind the adapter source
and reproduce the V1 form-shape fingerprint. A package integration should
place the compiler beside the assembler (or expose those helpers privately
inside the same package) rather than publish those private symbols.

## Fail-closed boundaries

V2 rejects invalid dimensions, rank above three, duplicate root squares,
unsupported fractional powers, a zero/non-rational gauge denominator, failed
recursive norms, failed inverse or field round trips, failed polynomial ABI
round trips, malformed support/normalizations, non-prefix one-form rebinding,
source hash changes, polynomial-pool mutations, and a V1 compatibility view
that fails the old validator.

The declared roots still require the caller's existing square-class
independence certificate. V2 does not try to replace the physical preparation
sidecar or infer field independence from symbolic heuristics.

## Managed tests staged, not run

`run_direct_root_channel_compiler_v2_adversarial.wls` covers ranks 0 through 3
with expressions whose denominators themselves have multiquadratic channels.
For every rank it requires exact equality of the fresh V1 and V2-compatible
assemblies and exact equality of one finite-field point image. It also tests
telemetry, a recursive-norm zero divisor, an independently checked good
inverse, compile-free support rebinding, append-only one-form rebinding versus
a fresh build, non-prefix rejection, rank/fractional-power rejection, pool
corruption, and source corruption.

`run_cf300_sector12_compiler_v2_benchmark.wls` reads and validates the physical
CF300 sector-12 A0 preparation, times V2 core and ansatz compilation separately,
then times a fresh V1 reference. It requires exact V1 association equality,
not only equal fingerprints. It also compares a 56-support support-only rebind
with a fresh V2 ansatz instantiation and records all pool/inverse/round-trip
telemetry.

Both drivers require a fresh output path, hash every input before loading,
capture Wolfram messages, rehash sources at completion, never launch or close
kernels, and write atomically without overwriting. They should be submitted
through the campaign's existing managed pool, never with standalone
`wolframscript`.

Suggested managed invocations after the parent has assigned pool capacity:

```text
kpsubmit.sh <label> <driver> <project-root> <fresh-output.wl>
kpsubmit.sh <label> <physical-driver> <project-root> <prepared-a0.wl> <fresh-output.wl>
```

## Promotion gates

Do not integrate V2 into the package unless all of these gates pass:

1. both static scripts pass from a clean checkout;
2. the synthetic managed driver passes with no captured messages;
3. the physical driver reports `ExactV1AssemblyEqual -> True` and no messages;
4. V2 compile wall time is materially below V1 on the same prepared artifact;
5. core telemetry shows actual scalar/polynomial reuse and recursive inversion,
   rather than a benchmark accidentally exercising only rank-0 data;
6. the existing V1 adversarial oracle still passes unchanged using the V2
   compatibility view;
7. serialized V2 core/assembly corruption and source-relocation tests are added
   before creating a V2 cache artifact;
8. package integration uses the established failure/status conventions and
   adds an explicit backend option defaulting to V1 until the physical corpus
   passes.

## Expected bottlenecks after this prototype

V2 attacks repeated exact algebra, but two costs remain intentionally visible:

- stable `ToString[InputForm[...]]` provenance fingerprints over large exact
  trees;
- full polynomial-pool round-trip validation at public core/assembly/rebind
  boundaries.

The physical telemetry separates algebraic compilation, rational fast-path
compilation, fingerprinting, ansatz compilation, and rebinding. If V2 remains
slow, optimize only the measured residual. The first follow-up would be a
validated-token boundary or a digest-bearing immutable polynomial pool, not
removal of inverse/round-trip checks.

