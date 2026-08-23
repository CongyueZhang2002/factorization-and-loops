# Design: the persistent KernelPool (2026-08-16)

## Problem

Our Wolfram license seat is shared with the parallel assistant; house rule
is one main kernel of ours. Until 2026-08-16 every kernel job — mine,
each subagent's, every test — serialized on that one main, while
subkernels sat idle: agents waited on each other for hours during the
hard-class day. `HCTMissionPool` fans out a mission LIST given at launch
but cannot accept work afterwards.

## Solution

`Scripts/KernelPool.wls` is a server: one main kernel launches N
subkernels (default 8; measured 2026-08-16: the license accepts 8),
preloads FeynFacet in each (once, ~3 s per kernel in parallel), then loops
every 1 s (3 s before 2026-08-22) over a queue directory:

    <pool>/queue/<name>.wl     mission: a Wolfram file evaluated with Get on a free subkernel
    <pool>/running/<name>.wl   while it runs (+ <name>.kernel = subkernel id, <name>.kernel.done marker)
    <pool>/done|failed/<name>.wl + <name>.status  (Association: Mission, Status, Wall, Kernel, Result)
    <pool>/logs/<name>.log     every Print/Message of the mission ($Output/$Messages rebound in the subkernel)
    <pool>/status.txt          rewritten every loop: subkernels, busy/free, queued/done/failed, running missions + elapsed
    <pool>/control/stop | stopnow | <name>.cancel
    <pool>/pool.pid

Client: `Scripts/kpsubmit.sh <name> <script.wls> [args...]` writes the
mission wrapper (sets `$ScriptCommandLine` to {script, args...}, cd to
the script's directory, Get script); `kpwait.sh <name> [timeout]` blocks
until the status record exists and prints it (exit 0 iff Status OK);
`kpstatus.sh` prints status.txt.

Design decisions, all measured:
- Completion is signalled by a marker file the wrapper writes at the
  end (`<name>.kernel.done`), not by `Parallel`Developer`ProcessState`
  (its `finished` value never matched across contexts in the test); a
  mission whose subkernel disappears (`$KernelID` no longer in
  `Kernels[]`) is reported `KERNELLOST` and the pool relaunches kernels
  to the requested count.
- `Exit`/`Quit` are redefined in every subkernel to `Throw` a tagged exit
  code; the wrapper catches it, so TestKit scripts (`FTReport` ->
  `Exit[failed]`) run as missions and their exit code is the Status
  (`OK` for 0, `EXIT<n>` otherwise). Measured: `t_symmetry_factor` 7/7
  in 0.16 s as a mission (vs ~40 s standalone incl. package load).
- Cancel = close that subkernel and launch a replacement (no per-job
  abort exists in the Parallel Tools API). Measured 2026-08-16 23:31: an
  OS SIGINT to the subkernel does NOT abort its evaluation (it emits
  MenuPacket[1, Interrupt], which the Parallel master discards), so the
  SIGINT variant was removed. Launches are guarded (90 s TimeConstrained,
  never blocking the loop; measured 23:14: an unguarded LaunchKernels
  hung the whole server on "No valid password found" while the parallel
  assistant held the seat) and retried every 5 min toward the requested
  count. A cancel therefore costs a subkernel until the license lets it
  relaunch — cancel only what you really do not want.
- Identifying which mission a subkernel runs: NOT by cwd (all pool
  subkernels share it) — use `ls -l /proc/<pid>/fd | grep logs/` (the
  mission log is an open file descriptor) or `<pool>/running/<name>.kernel`
  (kernel id) with the server's PID map in pool.log. Measured 2026-08-16:
  a kill "verified by cwd" hit the wrong orphan (no damage by luck).
- Orphans: if the server dies, its subkernels may keep computing (they
  ignore SIGTERM mid-evaluation) and hold license seats until they
  finish or are SIGKILLed by PID; a restart then starts with fewer
  kernels and tops up as seats free.
- Trap: `Needs["Parallel`Developer`"]` exports the Protected state
  symbols `running`, `queued`, `finished` — never use them as
  variables (the first version did and silently mis-recorded state).
- Subkernels keep state between missions (this is why the package is
  loaded once): missions must not rely on a clean Global` context, must
  Clear large allocations, and must Get any package file they modified
  (the pool does not hot-reload code).

## Rules of use (CLAUDE.md, compute budget)

All kernel jobs go through the pool; no second main of ours while it
runs. Missions must print per-item progress to their log; long missions
are watched by progress, not by hard caps; a mission silent for 30 min is
cancelled and its measured state recorded. Total CPU stays under the
10-core cap because the pool process is launched under `taskset -c 0-9`
(children inherit the affinity).

## Start / stop

    POOL=/tmp/claude-1000/<session>/scratchpad/kernelpool
    taskset -c 0-9 nohup wolframscript -file Scripts/KernelPool.wls $POOL 8 True > $POOL/pool.log 2>&1 &
    touch $POOL/control/stop      # drain and exit

Production use (many agents solving eps-forms/boundaries): one pool per
box, all agents submit; the pool directory is the only shared state.
Open items: a `Tests/t_kernel_pool.wls`-style bash test (start a 2-kernel
pool, submit, wait, stop); mission priorities; a JSON status for
dashboards; per-mission memory limits (MemoryConstrained inside the
wrapper).

## Never-started missions (measured 2026-08-17 01:47-01:56; fix on next restart)

Three dispatched missions (chart_CF23, sw_CF27, an agent's acc6) sat in
`running/` with NO kernel file and NO log while counted busy: their
`ParallelSubmit` evaluation never began. Cause not root-caused (the
Parallel Tools scheduler; kernels had been closed and relaunched by cancels
shortly before). Remedy in `KernelPool.wls`: (i) the wrapper CLAIMS the
mission by writing the kernel file and returns `DUPLICATE` at once if it is
already claimed; (ii) the server resubmits a job that has not started after
`neverStartedAfter` = 90 s (new evaluation, same files; up to `maxResubmits`
= 3, then `NEVERSTARTED`). Until the running pool is restarted, the manual
remedy is `touch control/<name>.cancel` (frees the slot; kernel None, none
closed) and resubmit.

## Task broker (2026-08-22): parallelism INSIDE a mission

Wolfram forbids parallel programming in a subkernel (`LaunchKernels::subnopar`,
measured 2026-08-21) and the licence allows two main kernels on this box, so
a family mission running on a pool subkernel cannot hold helpers of its own.
`FeynFacet/Private/TaskBroker.wl` lets it use the pool's FREE subkernels
instead: when `FACET_TASK_BROKER=<pooldir>` is in the environment (set when
the pool is started; subkernels inherit it), the finite-field sampler's
per-prime sample batches and the CANONICA degree ladder (degrees > 0) are
written as small task missions into the same queue, the main dispatches
them to free kernels, and the family mission waits for their result files.
Tasks carry only references: the strip record and the options are written
once under `<pool>/data/` and each helper caches the record, its
preparation and CANONICA across tasks. A task that fails is recomputed
locally, so results are exactly those of the serial path.
Rules: at most N-2 family missions in flight (`Scripts/family_epsform_pool.sh`
enforces it), otherwise no helper is free and every family waits; a task
never brokers (`$taskBrokerInsideTask`); the sampler brokers only when the
pilot measured >= "BrokerMinimumSeconds" (1.5 s) of build per sample.
Measured 2026-08-22, CF254 (9,7), 3 helpers: wall 446 s -> 357 s, sampling
278 s -> 185 s, oracle-identical; CANONICA ladder 180 s -> 97 s.

## Fresh kernels for tests (2026-08-22)

A mission whose name starts with `fresh_` has its subkernel closed after
it finishes and relaunched with the preload (~40 s). Use it for
regression tests: they assume a clean `Global\`` context, and on
2026-08-22 two of 21 tests failed on a reused subkernel (`t_chart_transport`'s
chart symbols, `t_transport_chart_extension`'s output variables) while
passing standalone. `Scripts/run_tests_pool.sh <pooldir> <N> [tests...]`
submits every `Tests/t_*.wls` this way and prints a table.
