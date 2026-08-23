# Package bug and promotion-gate handoff, 2026-08-23

This note records package-facing defects and contract gaps found during the
xhigh FLINT affine-RREF and direct multiquadratic-channel audit.  The certified
implementations remain External-only until these gates are addressed.

## Existing package defects

1. **Backend strings do not fail closed.**
   `FeynFacet/Private/FiniteFieldStripSolve.wl`,
   `finiteFieldStripBackendQ` (currently lines 84--87), treats every string
   other than literal `"FLINT"` like `Automatic`.  An explicit `"FLINT"`
   request with no binary also falls through to Wolfram `LinearSolve` in the
   constrained-core block (currently lines 775--780).  This makes a requested
   backend impossible to audit from the result.  New native discovery must
   validate the option exhaustively and return a typed failure on missing
   binary, hash, protocol, process, or certificate failure; it must never use
   this fallback behavior.

2. **Elimination-plan reuse is loose and unversioned.**
   The compatibility gate around `FiniteFieldStripSolve.wl` lines 733--742
   trusts association indexing and a small set of dimensions/degrees.  It does
   not require an exact schema, range/uniqueness checks for row and column
   selectors, a version, a preparation fingerprint, or solver provenance.
   A native CFFR plan needs a strict validator and an immutable fingerprint
   before reuse.

3. **Algebraic-frame failures lose their typed diagnostic in the family
   artifact.**
   `Scripts/family_epsform_sector.wls` logs the returned solver association but
   `_unsolved.wl` stores only the strip and optional obstruction.  In
   particular, `NoRationalStripChart` is not persisted.  Store a bounded
   solver-failure summary (status and diagnostic fields, excluding large
   gauges/sample payloads).

4. **Checkpoint replay does not bind the algebraic solver route.**
   `FamilyRowGaugeResume.wl` replays algebraic strips without a backend/ABI
   configuration, while the strip summary in `family_epsform_sector.wls` does
   not retain one.  A future direct-channel checkpoint could therefore be
   silently replayed through the rational-chart route.  Add exact
   `SolverConfiguration` and implementation provenance to strip summaries and
   checkpoints; hydration must compare them and fail closed.  Old checkpoints
   may remain valid only for the historical default rational-chart route.

## External direct-channel API defects/gaps before promotion

1. `DRCAAssembleSample` accepts and records `"BranchFlipMask"`, although direct
   multiquadratic grade rows are branch invariant and the value changes no
   equation.  Require zero or remove the option from the production sampler.
   Branch flips belong only to `DRCATransformPointToSigns` and
   `DRCATransformSampleToSigns` differential/certificate APIs.

2. `TRCandidateOneFormBasis` supplies closed one-form pairs, not certified
   dlog potentials.  Package installation currently requires `Alphabet` plus
   constant residue matrices (`familyRowGaugeDLogForm` and the family
   certificate).  A direct solver must either return and verify a potential
   for every candidate (`DLog[letter] == oneForm` exactly), or introduce a
   separately certified `OneForms` solution contract and update installation,
   resume, and final certification together.  Until then it may certify
   modular affine consistency but must not claim a package-compatible
   `Solved` epsilon form.

3. The unloaded `FamilyRowGaugeFiniteField.wl` duplicates root ordering,
   square-class arithmetic, and grade-mask semantics.  Before it and a direct
   strip solver are both loaded, extract one neutral multiquadratic algebra ABI
   or require a differential test proving identical ordering, fingerprints,
   and grade multiplication.

4. **The affine-witness score includes the `List` head as column zero.**
   `External/CodexExchange/triple_root_2026-08-22/
   cf300_sector12_next_ansatz_xh/AffineInconsistencyWitness.wl` line 128
   (SHA256
   `6d2ea56523cbee20c71efc265150ebd001d701421cac08dc69bb77296dafe79f`)
   uses `Flatten[Position[scores, Except[0]]]`.  With the default
   `Heads -> True`, the `List` head contributes the impossible index zero.
   The frozen V6d artifact consequently reports `{0,...,288}` (289 active
   positions for a 288-column block), and RAD9 reports 2,913 active positions
   for 2,912 genuine gauge columns.  Use, for example,
   `Pick[Range[Length[scores]], scores, Except[0]]`, then require every index
   to lie in `1 ;; columns` and the count not to exceed the width.  Add exact
   all-zero, all-nonzero, and mixed-score regressions.  This defect does not
   weaken the recorded V6d/RAD9 inconsistencies: it forces the conservative
   full two-rank path, whose independent ranks remain `888/889` and
   `3044/3045`.  It corrupts score metadata and disables the certified
   all-zero early rejection.  A non-applied repair is staged as
   `External/CodexExchange/affine_witness_score_heads_fix_2026-08-23.patch`;
   do not apply it while the source-pinned CF300 V5 mission is active.

## Native affine-RREF promotion boundary

The new affine-RREF backend is distinct from the existing CFFA4 fixed square
multi-RHS solver.  It should use a separate option such as
`"PlanDiscoveryBackend" -> "FLINTAffineRREF"`, defaulting to the historical
Wolfram path.  Promote the strict request/parser/verifier and native backend,
not the CF300 campaign driver.  Bind adapter/source/binary/protocol hashes,
nonce, request/response hashes, verified witnesses, preparation fingerprint,
thread count, and plan fingerprint into every plan and reusable artifact.

The existing CFFA parser is not adequate for this purpose: it does not bind a
nonce or immutable source/binary hashes and does not enforce the complete CFFR
certificate protocol.  Reuse of its silent fallback semantics is forbidden.

## Persistent-pool control-flow and namespace defects

1. **A target-level `Return` can bypass `poolRun` finalization.**
   The CF303 V1 capture wrapper used an untagged top-level `Return[$Failed]`.
   Because `Scripts/KernelPool.wls` currently evaluates the target as
   `Catch[Get[file], "KernelPoolExit"]` directly inside `poolRun`, that return
   escaped the target and returned from `poolRun` before the `MISSION end`
   record and kernel completion marker were written.  The worker itself stayed
   healthy and was reused; no process was signalled.  Evaluate `Get[file]`
   inside an anonymous function boundary, for example
   `Catch[Function[Null, Get[file]][], "KernelPoolExit"]`, and add a live test
   proving that a target containing top-level `Return` still produces a typed
   terminal marker.  Do not restart the current pool merely to install this
   repair; load it with the next pool generation after source-pinned missions
   have completed.

2. **Reused kernels retain target globals and package contexts.**
   A prior test left `Global`checkpointFile` equal to a string.  The first
   contextual-denominator driver then attempted
   `checkpointFile[image_Association] := ...`, emitted `SetDelayed::write`, and
   failed before sampling.  A later no-op probe showed the terminated
   driver's package context still present on `$ContextPath`.  Long-lived pool
   targets must use a unique private context, clear their own state, restore
   `$Context`/`$ContextPath`, and avoid loading artifacts under a namespace
   contract different from the one used to create and validate them.  Static
   token checks are insufficient: require a same-kernel poison-then-hydrate
   test that validates actual artifact values before promotion.

3. **Compiled-artifact hydration is hardcoded to the `Global` context and its fingerprint is context-sensitive.**
   `DRCAReadCompiledArtifact` evaluates the artifact with `$Context =
   "Global`"` and `$ContextPath = {"System`", "Global`"}`.  The CF300 cache
   otherwise validates in a fresh dedicated context, but the stored
   `ExactChannelFormsFingerprint` changes if the same symbolic `x/y` forms are
   inspected in a different context because it is based on `InputForm` text.
   Split raw loading from value validation, accept an explicit artifact
   context, precreate the complete artifact namespace, and keep that context
   visible through validation, fingerprinting, rebind, and sampling.  A
   stronger package format should canonicalize ABI variables to context-free
   placeholders before hashing rather than making symbol context an implicit
   part of the cache key.

4. **`Quiet[Check[Get[file], $Failed]]` can discard a valid artifact.**
   `Check` returns its failure branch after any observed message, including a
   benign message hidden by `Quiet`.  In the reused-kernel hydration adversary
   this changed a valid preparation Association into `$Failed`, while the cache
   happened to load.  Use `Quiet[CheckAbort[Get[file], $Aborted]]`, collect
   `$MessageList` separately, and let the schema/ABI/fingerprint validators
   decide whether the returned value is admissible.

5. **Never test `Locked` on shared persistent-kernel symbols.**
   An adversarial test applied `{Protected, Locked}` to the symbols
   the Global-context symbols x, y, and eps on pool worker 144.  Wolfram's
   `Locked` attribute is
   irreversible for that kernel lifetime: `ClearAll`, `Remove`, inherited
   localization, and attempted attribute restoration cannot undo it.  The
   exact states were stable under all subsequent read-only probes, but the
   worker cannot safely run ordinary artifact consumers.  Such adversaries
   must use a disposable kernel or a unique private context, never the
   `Global` context
   in a shared pool.  The current run reserves worker 144 with a no-mutation,
   fingerprint-pinned heartbeat mission; no process was stopped or signalled.

6. **Several Wolfram introspection functions require explicit Hold semantics.**
   Live gates exposed three false negatives: `Context[carrier]` inspected the
   held carrier rather than its symbol value; `Names["context`*"]` returned
   short names while that context was current; and `Remove[context <> "*"]`
   held the unevaluated string concatenation.  Use held `ToExpression` access
   for definition tables, normalize `Names` by both symbol name and resolved
   context, use `Context[Evaluate[value]]` when appropriate, and pass literal
   names (or `Apply[Remove, names]`) to cleanup.  Add live reused-kernel tests;
   lexical/static checks did not catch these behaviors.

7. **A virgin-worker gate is incompatible with a preloaded pool.**
   The current `KernelPool.wls` process was launched with its third argument
   `True`; `kernelPreload` consequently loads FACET on every initial worker
   and every replacement worker.  The frozen CF300 V4 recapture correctly
   requires no relevant package names or package-list entries before its own
   controlled load.  Its read-only K146 probe therefore failed with 1,685
   relevant package names and `CANONICA`/`FeynFacet`/`FeynArts`/`FeynCalc`
   already loaded, despite exact dispatch, helper, cleanup, and output-absence
   gates.  Do not weaken this to a cosmetic `$Packages` edit: definitions and
   side effects remain.  A future pool contract must either provide an
   explicitly unpreloaded worker class, or the consumer must prove complete
   package/Global isolation and restoration on a dirty worker.  Until one of
   those contracts is validated adversarially, a `VirginWorkerRequired`
   mission must fail before writes.  No current worker should be closed merely
   to manufacture a fresh one; the present top-up path would preload it again.

8. **Generated temporary symbols need bounded cleanup and bounded failure
   diagnostics.**
   The old CF300 Galois V5 run completed its four mathematical images but
   exited 97 when its artifact-scope postcondition found thousands of
   definition-free `trRoot*` names.  Its failure log then serialized nearly a
   megabyte of full definition-state associations.  V6d supersedes this
   particular driver, but package-facing generators should track the exact
   names they intern, remove them by literal full name, prove the owned context
   empty, and report only counts plus bounded first/last samples and a hash on
   failure.  A diagnostic must not recreate names while inspecting or
   removing them.

9. **`Options` does not hold its argument; definition readers must pass an
   unevaluated symbol and must clean up after aborts.**
   A K146-only no-write gate tried to fingerprint the already-loaded FeynArts
   namespace using `Options[symbol]`.  Unlike `Messages` and `Attributes`,
   `Options` has attributes `{Protected}` and evaluates its argument.  For
   `FeynArts`M$ClassesDescription`, that evaluation enters FeynArts'
   deliberately delayed reset value, emits `M$ClassesDescription::undefinedmod`,
   and calls `Abort[]`.  A live held-reader diagnostic proved that
   `Options[Unevaluated[symbol]]` returns without an abort while the current
   reader aborts.  Use the unevaluated form in every exact definition-state
   serializer and add a regression with a delayed symbol whose own value
   aborts if evaluated.

   The abort also bypassed the probe's `End[]`/`EndPackage[]` footer, leaving
   its owned context, private names, `$ContextPath`, and `$Packages` entry on
   the persistent worker.  Any package-style gate running in a reused worker
   must wrap its body in `CheckAbort` (and its normal failure paths in the same
   cleanup discipline), restore the exact entry lifecycle, and remove only
   its sealed owned names before rethrowing or returning failure.  The current
   K146 evidence is preserved and an adjacent V5b gate, not a package-source
   edit, is being built around that rule.
