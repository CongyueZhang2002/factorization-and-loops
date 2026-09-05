# Differential-equation performance baselines retained before disk cleanup

These measurements are the compact permanent record of the large temporary
run directories removed in September 2026. They are performance references,
not substitutes for validating a regenerated mathematical result. A future
comparison is valid only when it uses the same family/block, coefficient
presentation, ansatz, requested epsilon orders, and validation method.

## Family differential systems and epsilon forms

| Calculation | Earlier measurement | Retained measurement | Peak Wolfram memory or output size | Qualification |
|---|---:|---:|---:|---|
| All 173 pre-V2 diagonal-class regulator factorizations | not recorded here | 204.5 s with four subkernels | not recorded | Historical throughput reference only. |
| CF269 family differential system | — | 53.99 s | 414,060,424 bytes | Regenerated V2 matrices exactly matched the archived matrices. |
| CF48 family differential system | — | 59.03 s | 442,482,448 bytes | Regenerated V2 matrices exactly matched the archived matrices. |
| CF265 family differential system | — | 46.81 s | 431,858,256 bytes | Regenerated V2 matrices exactly matched the archived matrices. |
| CF259 family differential system | — | 126.39 s | 687,429,472 bytes | Regenerated V2 matrices exactly matched the archived matrices. |
| CF48 dlog epsilon-form construction and final finite-field validation | 724.51 s total | 561 s construction plus 84 s validation; 645 s projected fresh total | not recorded | Same representative family; retain 724.51 s as the comparison value until a new fully fresh total is measured. |
| CF259 diagonal-block assembly | about 430 s | 44 s | not recorded | Duplicate diagonal symbolic work removed. |
| CF300 off-diagonal block `(12,9)` | 51.3 s | 22--27 s | not recorded | Deferred block equation evaluated directly at finite-field points. |
| CF300 off-diagonal block `(12,7)` | 245.6 s | 113--121 s | not recorded | Same deferred finite-field method. |
| CF303 `(25,18)` block-equation construction | 1,477 s for explicit symbolic construction | finite-field census in 12.5--13 s; sampler reached | not recorded | Stage comparison only; the block remained inconsistent in the tested ansatz and was not solved. |
| CF259 `(23,21)` | stopped after 1,189 s | 70 s | not recorded | Corrected three-root input, two 61-bit primes and seven regulator images per prime. |
| CF259 `(27,23)` | 878.7 s finite-field solve plus 558.1 s source-variable re-expression, 1,436.8 s combined | 523.1 s plus 428.3 s, 951.4 s combined | 1,507,192,680 bytes maximum Wolfram kernel memory in the retained run | Same saved equation, `KallenQ4a` parametrization, alphabet and degree bounds. |
| CF259 `(27,19)` complete degree-zero ansatz | unresolved after at least about 538 s | terminal inconsistency in 151.2 s | not recorded | Same 15,616 by 15,500 modular system. |

The mixed-grade `(27,19)` experiment took 203.5 s on the original complete
support and obtained the same inconsistency. It was slower than 151.2 s and
was not retained.

## Solutions along paths

These records use the historical term “transport” only when quoting an old
artifact or source filename. The mathematical operation is solving the
differential system along a specified path and composing it with the requested
master-integral map.

| Calculation | Earlier measurement | Retained measurement | Representation size | Qualification |
|---|---:|---:|---:|---|
| CF299 requested-output path solution | — | 142 s | 121 kB sparse GPL record | Pre-V2 historical reference. |
| CF407 requested-output path solution | — | 435 s | 2.6 MB sparse GPL record | Pre-V2 historical reference. |
| CF407 Wolfram composition with symbolic boundary coordinates | dense expansion exceeded 1.4 GB before termination | about 13 s | 112 MB | Sparse composition reference. |
| CF230 requested-output coefficient operator | 2,989.48 s | 3.361 s | 509,279,040 bytes before; about 2.16 MB after | Same formerly slow ordinary family; 120 weight-two maps. |
| CF230 final rational reconstruction | — | 15.16 s cached; 37.10 s fresh | compact rational maps | Fresh run includes 4.15 s tracing and reconstruction. |
| CF303 rational-in-epsilon final sublayer at `p=9/8`, epsilon window `{-2,0}` | — | 1.2 s direct construction; 168 s for the 18-prime comparison | 75 residue keys and 7,902 iterated-integral index sequences | This is only the rational sublayer, not a completed CF303 master-integral solution. |
| CF26 ordinary path-solution construction | — | 1.2 s (1.4 s process time) | not recorded | Pre-V2 campaign reference. |
| CF57 ordinary path-solution construction | — | 1.2 s (1.4 s process time) | not recorded | Pre-V2 campaign reference. |

## Permanent source records

- `Exchange/Codex/2026-09-04/18_hard_block_performance_acceptance.md`
- `Goals/Codex/2026-09-04/01_v2_physical_solutions_and_regeneration.md`
- `Design/PrivateOverhaul_2026-09-01.md`, Round 8
- `Design/PrivateOverhaul_2026-09-01_evidence/round8/M_stage1_speed.md`
- `Design/PrivateOverhaul_2026-09-01_evidence/round8/T_noneps_transport.md`
- `Design/PrivateOverhaul_2026-09-01_evidence/round9/M_transport_campaign.md`
- `Exchange/Codex/2026-09-01/01_observable_transport_optimization_completed.md`
- `Goals/Codex/2026-09-01/02_compact_finite_field_observable_transport.md`
- `Exchange/Codex/2026-08-21/03_projected_transport_campaign/codex_compact_transport_assessment_2026-08-21.md`
- `Exchange/Codex/2026-08-21/03_projected_transport_campaign/codex_projected_transport_wrapup_2026-08-21.md`
- `Exchange/Codex/2026-08-17/04_observable_transport_exact_result.md`
- `Exchange/Codex/2026-08-17/05_two_segment_observable_transport.md`

The bulky finite-field request matrices, core binaries, repeated run
directories and crash dumps are deliberately not part of the baseline. They
are reproducible implementation by-products and are not required to compare
the timings above.
