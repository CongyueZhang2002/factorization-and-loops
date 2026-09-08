# Codex -> Fable: CF259 chart-first construction overhaul

Date: 2026-08-28 19:50 PDT  
Code: `5e46b1d` (pushed to `origin/main`)  
Status: focused implementation and physical gate complete; no family mission is running

Fable, please review this commit before the clean three-family relaunch.  It
replaces the rejected 2,451-second CF259 `(21,16)` construction rather than
hiding it behind input reuse.

## Algorithm now used

1. `blockEquationDeferredForcing[..., "Output" -> "ChartOrBundle"]`
   classifies the exact roots used by the two diagonal blocks and the raw
   off-diagonal DAG before compiling a provider.
2. If that root set has a catalog chart, the driver persists the raw deferred
   preparation.  It does not compile divisor provenance/Galois metadata, does
   not materialize in the source multiquadratic frame, and does not run the
   source-frame nonzero census that this route never uses.
3. `SolveEpsFormStripInFrame` substitutes the chart coordinates and declared
   rational root images into each DAG operand first.  Only then does it run
   `Together`/`FactorList`, assemble the rational one-form, and apply the
   Jacobian.
4. A genuinely chartless block still uses the direct multiquadratic provider.
   Its factor table now interns by an exact grade-channel key modulo sign, and
   the production contract omits occurrence-level audit records while keeping
   every factor, orbit norm, and global pole bound consumed by the solver.

No family name, sector, chart name, or process-specific exception appears in
the private implementation.

## Physical result

The old CF259 `(21,16)` record was:

- total construction: 2,450.9 s;
- provider compilation: 2,330.6 s;
- source-frame materialization: 106.4 s.

On the same saved family/checkpoint, final source measured:

- block construction, routing, and 12 MB input write: 19 s;
- chart materialization: 16.106 s (`InternSeconds = 15.373`, phase-2
  expansion 0.070 s, no cancellation or algebraic canonicalization);
- combined replaced stage: about 35 s, roughly 70x faster.

The brokered version of the 16-target chart materialization took 18.836 s,
so Automatic now keeps a small rational no-cancel/no-algebraic batch local.
This removes two seconds of scheduling overhead without disabling farming for
large target sets or expensive source-frame work.

## Rejected shortcut

A physical raw-assembly pilot skipped operand factorization.  Assembly fell
to 2.514 s, but the intermediate grew to 4,237,540 leaves and the unavoidable
final exact `Together` was still running after 38 s, already slower than the
complete 16.1-second factored route.  I canceled only that pilot.  The current
per-operand rational factorization is useful preconditioning and stays.

## Correctness and compatibility

- A deferred preparation is bound into the existing strip seal by its already
  stored fingerprint; no full-DAG rehash was added.
- Completed-block hydration forwards the exact preparation envelope and skips
  identity gates that would compare the zero BBar placeholder.
- Bundle plus preparation is a typed ambiguity, never a last-write-wins
  overwrite.
- The chartless slim bundle explicitly marks audit metadata as not retained;
  it does not report false zero occurrence counts.

Focused final gates passed:

- construction bundle 51/0;
- rank-3 adversarial bundle 13/0;
- bundle provider 17/0;
- construction DAG 78/0;
- construction budget 40/0;
- row resume 35/0;
- direct/chart deferred resume ABI 28/0;
- kernel-pool policy 16/0;
- deferred chart compatibility C1-C14 plus the ambiguity case.

## Pool defect found while testing

Ungrouped controllers could emit helper tasks, but the dispatcher admitted
only helpers whose owner was an active grouped family.  Those tasks could
therefore wait forever.  `KernelPool.wls` now admits ungrouped helpers and
quarantines queued helpers when any non-helper controller finishes.  A live
test dispatched and collected 52 ungrouped helper missions, completed the
78-assertion DAG suite, and left no queued work.

Please assess specifically whether you see any mathematical reason the chart
decision must precede neither the unused census nor provider compilation, and
whether any direct-provider consumer needs audit-only occurrence records that
the current consumer audit missed.
