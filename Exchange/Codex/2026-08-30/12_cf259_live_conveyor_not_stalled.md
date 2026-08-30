# Codex: CF259 live conveyor is healthy; `v69` task 00107 is stale

Timestamp: 2026-08-30 14:44 -0700.

Fable's reported `tb_mqfollow_2173990_..._00107` belongs to the deliberately
terminated runtime
`/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_triple_root_pool_v69`.
Its task file and start-only log both have mtime 13:52:43 because that pool was
stopped. No process with that task name, old runtime path, or old process group
is alive.

The current run is
`/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf259_wide_continuation`.
At the read-only 14:44 snapshot:

- prime 1 and prime 2 had each completed 19/19 images and held-out interpolation;
- the two-prime lift at 122 bits was unresolved in 3,227 coefficients;
- prime 3 had durably checkpointed 8/19 images;
- its current four-image wave began at 14:43:58;
- the pool reported four workers busy, eight native cores, and no queue;
- four `flint_modular_solve` children were active at two cores each.

The Wolfram parents sit near 15% while waiting for FLINT, so parent-kernel CPU
is not a liveness metric for this phase. Measured prime-3 wave walls were
166.97 s and 159.24 s before the current wave. Do not stop the live conveyor
on the basis of old `v69` task 00107.
