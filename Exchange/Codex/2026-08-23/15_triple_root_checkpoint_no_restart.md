# Codex triple-root / finite-field checkpoint — stopped, do not restart

Timestamp: 2026-08-23 18:04 PDT  
Disposition: the Codex pool terminated after usage was exhausted. This file is a progress and next-action record only. **Do not restart, resubmit, relaunch, cancel, or clean any mission from this checkpoint without a new user instruction.**

## Runtime state at the stop

- The Codex pool at `/tmp/codex-triple-root-20260823c.vx654S/pool` is no longer live. Its main PIDs `3596403/3596434` and its subkernels are absent. The last `status.txt` timestamp is 2026-08-23 15:27:09 PDT and is stale.
- Fable's separate four-worker benchmark pool under `/tmp/claude-1000/.../scratchpad/bench_pool` was still live at the read-only 18:04 snapshot. It was not touched.
- No process was killed, signalled, restarted, or cleaned by Codex.
- `git diff --check` passes. The worktree remains intentionally dirty with user/Fable work and the reviewed Codex changes; do not reset it.

## Accepted progress

### Package-level finite-field and row-gauge work

The integrated work and its earlier validation remain recorded in:

- `External/CodexExchange/codex_overnight_optimization_triple_root_2026-08-23.md`
- `External/CodexExchange/codex_package_bug_handoff_2026-08-23.md`

The accepted package changes include sparse/deferred family row propagation, resume hydration and integrity replay, finite-field strip hardening, target parsing, and regulator-factor handling. The measured warm direct/rebind gains and the adversarial suites in the main report remain valid. No additional live package edit was made during this final checkpoint.

Two further optimizations were staged adjacent, not applied:

1. scalar-local root-free compilation inside rank-2/rank-3 fields, preserving the full `{q,0,...}` grade ABI and an exact `TRFieldCompose` round trip;
2. targeted epsilon-free factor census by exact epsilon-content GCD, collision deduplication, bivariate factorization, and exact factor reconstruction.

Bundle:
`External/CodexExchange/finite_field_scalar_rootfree_squeeze_2026-08-23_xh/`

- manifest SHA-256: `ad8e0eacd1875035245140435a49e66cc14f7bb79f61daaf3f69e7b5adcdf524`;
- scalar audit: 63 checks;
- content-GCD audit: 256 exact randomized cases;
- seven adversarial mutants rejected;
- both patches pass `git apply --check` and the no-kernel lexical guards.

These patches are candidates only. They still require managed Wolfram differentials and material timing wins before promotion.

### CF300 V6d and V6e

V6d remains the accepted finite-field screen:

- artifact: `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl`;
- SHA-256: `20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf`;
- all four images have coefficient/augmented ranks `888/889` and nullity `24`;
- this is a finite-field obstruction screen, not yet a characteristic-zero certificate.

V6e completed its algebra and intentionally filed `EXIT3` because performance acceptance failed, not because correctness failed:

- result SHA-256: `4b7a03067c6db5f18d036e5a91565ff84061228e677f6e187fc25afe3bfc4adb`;
- exact legacy fingerprint: `32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7`;
- two same-input trial walls: `486.911427 s` and `496.049937 s`;
- median: `491.480682 s`, versus V6d `485.843061 s`;
- observed factor: `0.9885293131419557` (no speedup);
- all repeat fingerprints, seal checks, replay rejection, and all four `888/889/24` image certificates passed;
- the exact-lift prerequisite consumer check passed in `4.022275 s`.

The exact bottleneck is now localized: `TargetABIValidation` took `420.888848/428.830242 s`, about 86.4% of each trial; canonical-leaf validation took about `36.91/37.98 s`. The suffix composition, 336 unique-leaf compile, one oracle comparison, and seal construction together took only seconds.

The exact-lift prerequisite was written and validated:

- path: `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl`;
- SHA-256: `3fab0f58e3c85cb84cd8f8b99e301039ac30f78a4261cff0b30c6e3aa9cc680a`;
- file size: `159038765` bytes;
- status: `CF300V6dExactLiftPrerequisiteV1`.

The adjacent V6f one-time exact bridge is staged but not runtime-tested:

`External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/v6f_one_time_bridge_xh/`

- manifest SHA-256: `22fe267f22bec1c9a89235a2b9aa3cbbfa89f3cc9be038e748e1ef308f694cb3`;
- every manifest entry and the Python static gate pass;
- it uses the immediate exact frozen-V6 result, 72 source-certified record seals, exact suffix comparisons, and a private same-kernel handle;
- finite-field/Merkle evidence is reject/integrity evidence only, never algebraic acceptance.

Promotion blocker: the downstream driver still calls public `DRCAAssembleSample` eight times, repeating whole-assembly validation. V6f needs a bridge-owned private validated-sample path plus held-parse, exact runtime, and adversarial tests.

### Exact Q(eps) obstruction

The V1 held-parse mission passed on K24 with helper ceiling zero and no nested kernels:

- held-parse artifact SHA-256: `c6cae856ef7095799cf3f472343edd49567d3fb1e1783ae4a6e42ab4a5dbafe1`;
- pool status: `OK`, no messages, result zero.

The V1 runtime never entered the exact algebra. It failed at the transformed-driver source pin:

- expected transformed hash: `0b71743d40da509bef35cbadbae0df5f27263ce7ff6b283e9c481a91e89a8f66`;
- observed transformed hash: `4b5766a39e87484c9ac0a91a4f8a825eae25969efc3f2440c808c663739426de`;
- no exact certificate and no admission receipt exist;
- generated wrapper SHA-256 captured before dispatch: `03a6962dd5c742b18a10d81ec650a877a06d741e658b1400081673aa9b0b92da`.

Static diagnosis: V1 reads the frozen ASCII driver using `Import[..., "Text"]`, then removes the shebang with `StringSplit`/`StringRiffle`; this loses the terminal LF that was part of the pinned transformed string. An unfinished adjacent V2 replaces this with byte-exact ASCII reading and exact shebang removal:

`External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_v2_xh/`

Only two V2 WLS files exist. They have no report, tests, manifest, central held parse, or runtime evidence. **They are incomplete and must not be launched.** Their current hashes are:

- runtime source: `92b7bbaed6df70edac7308cf156a32a0482ddb4f314ea5c028a23fefc632441d`;
- held-parse source: `24c5fe75db8c71b0ae6ea4c006d3124d3f083edab85a739fb492ec0db7f418a9`.

V1's early `Return[$Failed]` also escaped `poolRun` finalization, leaving a ghost pool job. A missing `.kernel.done` marker was added only after the exact log proved the pin failure and a later fail-closed probe proved physical K24 had already accepted another mission. The pool then filed V1 `KERNELLOST`; this bookkeeping status is not an OS/kernel loss. No process was closed.

### CF300 sector-12 recapture

The cleanup-safe V5b bundle is frozen and independently verified:

`External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/CF300_SECTOR12_RECAPTURE_FROM_V4_V5B_RECOVERED_K146.md`

- manifest SHA-256: `0fb24551ecb307ea840c1d863d8f891f4cf884b8b9bc08cc0080c7a343bc79c8`;
- static/adversarial audit: `102/102`, including 17 mutants;
- path seal: `21/21`.

The production recapture was not launched and its output is absent. Its final no-write probe was accidentally dispatched to K24 because the exact-V1 ghost made the pool's busy count disagree with the scheduler. The hard K146 gate rejected it in `0.121498 s`, with no messages and no output mutation.

Important: V5b binds the exact dirty/leaked state of the now-dead K146. It is evidence and a recovery design, but it is not valid on a future fresh worker. A future unpreloaded pool should use the virgin-worker V4 route; a future preloaded pool needs a newly captured dirty-worker contract.

### CF259 and CF303

CF259 Q4 rank-three arithmetic V2 is frozen and passed `105/105` no-kernel checks. Its driver SHA-256 is `1812ee54af7c9f560484935a0f9fabe351874ec4fd5c8c0b34a66be95730a538`. It was never dispatched; its output and pool status are absent. This is only an arithmetic transfer gate, not the physical CF259 epsilon-form solve.

CF303 identity capture was cancelled by pool termination after `17246.8 s`; it did not produce a final family certificate. Durable log evidence shows:

- sector 16's 15 strips completed and its row gauge applied blockwise in `3.5 s`;
- regulator factorization on rows 1..16 reported `ConnectionContainsUndeclaredRadicals` and was deferred;
- sector 17 strips `{17,16}`, `{17,15}`, `{17,14}`, and `{17,13}` completed their finite-field solve/held-out/unseen-prime checks;
- the log ended after `{17,13}` selected `RationalChart/Kallen2/SimultaneousFiniteFieldAffinePDE`.

No final CF303 acceptance may be inferred. Before any future resume, inspect and hash the durable state/checkpoint and resume from the last certified boundary; do not start from scratch automatically.

### Adversarial run and quarantines

The long DRC adversarial mission retained the known first nine failures caused by the `AssociateTo` harness defect, then ended `ABORTED` when the pool stopped. Its `.kernel.done` marker exists but the dead pool never collected it. It is not a package verdict. Apply the already staged harness correction only after revalidating source pins, then rerun under a future authorized pool.

K144's no-mutation quarantine likewise has a stale running entry and completion marker because the pool died before collection. There is no live K144 process. Do not reinterpret or manually recover these bookkeeping files unless specifically requested.

## Exact to-do order for a future authorized continuation

1. **Do nothing now.** Preserve this stopped snapshot and Fable's separate live pool.
2. Finish exact-admission V2 offline: byte-exact terminal-LF pin, source/held-parse manifests, static and adversarial mutants, updated post-run verifier, and a top-level `Catch`/typed-`Throw` boundary so no target `Return` can escape `poolRun` finalization.
3. Only after explicit user authorization, create a new coordinated pool. Do not revive the dead pool directory as a live scheduler.
4. On a clean designated K24, run V2 held parse, then the exact `Q(eps)` left-obstruction lift against prerequisite SHA `3fab0f58...680a`; capture the wrapper hash immediately and require the full post-run verifier.
5. For CF300 recapture, choose by pool type: V4 on a genuinely unpreloaded/virgin worker; otherwise recapture and seal a new dirty-worker census. Do not run old V5b against a new worker.
6. Finish V6f's private validated-sample path and test cold exact bridge versus warm handle resolution; require zero whole-assembly `InputForm` calls after bridge creation and identical downstream ranks/prerequisite.
7. Run the CF259 V2 arithmetic oracle, then continue the physical CF259 triple-root family.
8. Inspect CF303's durable sector state, resume from sector 17 only if hashes and source-route pins match, and address `ConnectionContainsUndeclaredRadicals` without weakening the family certificate.
9. Promote the two finite-field squeeze patches only after exact CF300 differentials: unchanged 40 channels / 12 factor dlogs / 48 union forms, identical fingerprints/ranks, and material wall-time reduction.
10. Fix and rerun the DRC adversarial harness; separately promote the affine-witness `List`-head correction, `Options[Unevaluated]` definition reader, and KernelPool return-containment fix with their regressions.

## Files to preserve

- `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl`
- `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.wl`
- `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl`
- `/tmp/codex-triple-root-20260823c.vx654S/cf300_exact_qeps_runtime_admission_held_parse_xh_v1.wl`
- the full stopped pool directory and logs under `/tmp/codex-triple-root-20260823c.vx654S/pool`
- all adjacent manifests and reports cited above.
