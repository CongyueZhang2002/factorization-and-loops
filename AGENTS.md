# Repository house rules

Orientation and workflow context: **`CLAUDE.md`** (read that first).
This file holds the operational rules only.

## Workspace

Scratch scripts, intermediate Kira projects, run state, logs, staging
files, and test output belong in the session scratchpad directory
(`/tmp/claude-*/.../scratchpad`), never in the repository tree. Evidence
that a result depends on — differential systems, transformations,
certificates, expected test values — must be MOVED INTO the repository
under the relevant `Results/.../` directory before that result is
reported as established; tests must locate it by repository-relative
paths. (A 2026-08-15 Codex review correctly refused results whose inputs
existed only under `/tmp`.)

**`~/FACET` is frozen and read-only for us.** It is the legacy tree and
the parallel assistant's workspace. Never write there. Our tree is
`~/factorization-and-loops`.

## Compute budget (shared machine, shared Wolfram license)

- Never hold more than **1 main kernel + 4 subkernels** of ours. The
  license refuses a second main while 4 subkernels are seated, so the
  pool topology (`HCTMissionPool` in `Scripts/HardClassToolkit.wl`) is
  strictly better than several serial mains: submit all missions, let
  `WaitNext` hand each finished subkernel the next one.
- Total compute across our jobs <= 10 cores (`--parallel=10`,
  `--threads=10`, `taskset -c 0-9` to bring a running job under cap).
- Ownership is decided by `/proc/<pid>/cwd`, not by command line: ours
  run from the scratchpad or `~/factorization-and-loops`, the parallel
  assistant's from `~/FACET`. **Never kill by name pattern** —
  `pgrep`/`pkill -f` self-match has killed our own watchers and once
  killed the other assistant's kernel. Kill verified PIDs only.
- On license refusal: jittered 60-180 s backoff and retry; redirect
  output to files directly, never through `tee` chains that can die
  under the process.

## Long runs

Every long run emits per-item progress to a log, and its watchdog is
armed **in the same turn as the launch** (an 8-hour unmonitored
overnight run in August 2026 is the cautionary case). Check the first
output before reporting a run as healthy. Treat every progress event as
a decision point: if the evidence says the design is wrong (no
parallelism engaging, yield collapsing, cost estimate off by
multiples), stop and redesign rather than narrating "still going".

## Reporting language

Use precise terms. Call an executed calculation a `test` and report its
measured `result`. State the acceptance criterion before saying a test
passed; otherwise report observed values without `pass`. Use
`regression test` only for a repetition of a previously established test
after a code change. Never use `regression` as a generic synonym for
test, run, benchmark, or validation. Report numbers as measured or
estimated, explicitly.

## Verification

- A stored transformation or result is "OK" only after an **exact**
  reconstruction check. Structural shape checks are never success
  criteria (CANONICA returns `{False, {partial}}` on failure, which is
  shape-identical to success).
- Numerics may guide derivations but never appear in a recorded proof
  chain; they enter a ledger entry only as the independent check.
- Never pin a test to a defect's current symptom, except at a measured
  external-tool capability boundary. Our own unfinished work stays red.

## Mathematica notebook safety

Never save or rewrite a `.nb` through a hidden or offscreen FrontEnd,
and never run a headless FrontEnd while a visible Wolfram FrontEnd is
open. This can persist `Visible -> False`, oversized `WindowSize`, and
negative `WindowMargins`, breaking mouse hit testing and cell selection.

Treat every notebook save as a high-risk operation. Package, script, and
test changes must never resave an open `.nb` as a side effect. Do not
use `NotebookSave`, `NotebookPut`, notebook `Export`, or a
programmatically launched FrontEnd unless the user explicitly requested
a notebook edit.

For every requested notebook edit:

1. Back up the exact on-disk notebook first.
2. Close every FrontEnd that has the notebook open before changing it.
3. Modify only the requested cells or options; never regenerate.
4. Persist a bounded `WindowSize`, nonnegative `WindowMargins`,
   `ShowCellBracket -> True`, and no `Visible` option.
5. Do not reopen a Linux notebook from an automated FrontEnd command;
   that path can evaluate initialization cells and rewrite outputs on
   exit. Leave it closed for the user to open normally.
6. Re-read the on-disk file and verify the required options before
   completion.

Never automate notebook-window clicks, `Alt+F4`, or save-dialog
responses. If an automated launch occurs accidentally, restore the
pre-launch backup rather than retaining any FrontEnd-generated rewrite.

## Wolfram traps this repository has paid for

Regulator symbols differ per package (`eps`, `ep`, `Epsilon`,
`CANONICA\`eps`) — normalize by `SymbolName` at every boundary, never by
symbol identity. `Return` inside `Do` discards results. `Module`
initializers are not sequentially scoped. Self-assignment `v = Global\`v`
poisons iteration limits. `Missing[] =!= None` in both directions.
`Put` is not atomic — write to a temp file and `RenameFile`. `Together`
rationalizes square-root denominators and destroys algebraic-letter
words. Packages dump symbols into `Global\`` (asy ~200 of them, plus a
bare `x`; SubTropica exports `line`; PolyLogTools 1699 symbols).
