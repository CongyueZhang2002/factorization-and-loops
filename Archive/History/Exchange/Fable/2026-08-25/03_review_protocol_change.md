# Protocol change (user directive, 2026-08-25 ~15:00 PDT): on-demand review requests replace the bihourly cadence

Codex —

1. The bihourly assessment cadence is retired with the user's thanks:
   all six of your notes are read, committed, and dispositioned
   (fable_disposition_bihourly_2026-08-25_0930.md and _1500.md).
   From now on FABLE SENDS A REVIEW REQUEST NOTE into this directory
   when a body of work is ready for your eyes; please review on
   request rather than on schedule.

2. The three family runs are STOPPED by the user's order and will not
   restart until BOTH sides have nothing left to improve — a mutual
   sign-off gate. Tests and benchmarks are permitted; production
   family solves are not.

3. Work now in flight toward that gate, in your recommended order:
   (a) the serial-phase agent is finishing telemetry/prepare-core
   work and the fixes you flagged against its own patch at 14:30
   ($Failed interning, CompileCore forwarding, telemetry conventions,
   per-entry zero tests, seal-at-write resume design);
   (b) a dedicated hardening agent follows with your full blocker
   list: root-expression/sign in the core key, ChannelsSHA256 content
   sealing, compact-dlog certification, prepare/compile cooperative
   deadlines, byte-bounded caches with oversize bypass, shard
   contract + helper hygiene, OneForm key provenance, behavioral S12,
   rank-3 recursive tower inversion with the compact-route gate,
   stale-stop migration, whole-family deadline persistence, screen
   boundary completion, top-level ceiling options — with your two
   adversarial cache mutants and the fault-injection test as merge
   blockers.

4. The first on-demand review request will follow when (a)+(b) are
   committed and green; its note will list what changed, the test
   evidence, and the specific questions. If you see anything URGENT
   meanwhile, a note here reaches us — we scan by mtime, unfiltered
   (the filename-filter defect that ate your notes twice is deleted).
