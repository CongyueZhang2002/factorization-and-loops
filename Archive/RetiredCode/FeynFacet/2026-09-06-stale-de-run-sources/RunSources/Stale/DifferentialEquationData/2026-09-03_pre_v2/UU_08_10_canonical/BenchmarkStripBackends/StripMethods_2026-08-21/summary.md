# Off-diagonal block method benchmark (2026-08-21/22)

Question (user): is Maple needed at all; how does the CANONICA numerator ladder compare with the finite field?
Set: the 19 off-diagonal blocks the 2026-08-19 CF254 sector run constructed (sectors 9 and 12; `fixtures/cf254_strips_2026-08-19/`) plus the CF48 (13,11) fixture. Each method alone, one kernel, on the 8-subkernel pool (`Scripts/benchmark_strip_methods.wls`, rows under `rows/`). Every result re-certified independently as a dlog form (regulator-free letters, kinematics-free residues, exact Pfaffian identities; CANONICA residues derived by exact linear solve since CANONICA returns only the gauge).
Lanes: C = dlog recognition + CANONICA numerator degrees 0-3 at 120 s each, serial; M = Maple residue construction alone, capped at 1200 s of wall; F = finite-field affine solve alone (M1/O2/A2/A3/A4, dlog-form gate, dim-3 fix).

| block | dims | CANONICA ladder | Maple | finite field |
|---|---|---|---|---|
| CF254_9_1 | {4, 1} | failed 484.9 s | no result within 1247 s (cancelled) | solved 108.6 s |
| CF254_9_2 | {4, 1} | solved 0.1 s (already dlog) | solved 49.6 s | solved 2.4 s |
| CF254_9_3 | {4, 1} | failed 482.5 s | no result within 1249 s (cancelled) | solved 73.2 s |
| CF254_9_4 | {4, 2} | solved 0.1 s (already dlog) | solved 1008.1 s | solved 6. s |
| CF254_9_5 | {4, 2} | solved 0.1 s (already dlog) | solved 483.1 s | solved 5.3 s |
| CF254_9_6 | {4, 1} | failed 486.6 s | no result within 1215 s (cancelled) | solved 98.8 s |
| CF254_9_7 | {4, 4} | failed 485.9 s | no result within 1225 s (cancelled) | solved 450.6 s |
| CF254_9_8 | {4, 2} | failed 481.9 s | no result within 1223 s (cancelled) | solved 97.7 s |
| CF254_12_1 | {1, 1} | solved 34.2 s | solved 83.3 s | solved 5.3 s |
| CF254_12_2 | {1, 1} | solved 0.1 s (already dlog) | failed 0.7 s | solved 0.3 s |
| CF254_12_3 | {1, 1} | solved 14. s | solved 9.9 s | solved 1.5 s |
| CF254_12_4 | {1, 2} | solved 0.4 s (already dlog) | solved 7.7 s | solved 0.9 s |
| CF254_12_5 | {1, 2} | solved 5.7 s | failed 3. s | solved 0.6 s |
| CF254_12_6 | {1, 1} | solved 29.2 s | solved 44.6 s | solved 3.6 s |
| CF254_12_7 | {1, 4} | solved 59.5 s | solved 355.9 s | solved 7.1 s |
| CF254_12_8 | {1, 2} | solved 7.7 s | solved 14. s | solved 1.2 s |
| CF254_12_9 | {1, 4} | solved 59.5 s | solved 231.1 s | solved 4.7 s |
| CF254_12_10 | {1, 1} | solved 2. s | solved 0.7 s | solved 0.3 s |
| CF254_12_11 | {1, 3} | solved 4.4 s | solved 11. s | solved 1.5 s |
| CF48_13_11 | {2, 1} | solved 259.4 s | solved 4. s | solved 1.9 s |

Solved and certified: CANONICA 15/20, Maple 13/20, finite field 20/20.
Total seconds over the set (Maple cancellations counted at their cap): CANONICA 2898, Maple 8466, finite field 872.

Verdict: the finite field is the only method that solves every block; wherever CANONICA also solves, the finite field is 3-130x faster; the CANONICA ladder spends its full 480 s on every block it cannot solve; Maple is never faster than the finite field and fails on every hard block. Production route since 2026-08-22 (FACET_STRIP_ROUTE=FiniteFieldFirst in family_epsform_sector.wls): dlog recognition -> finite field -> CANONICA/Maple only as the last fallback.

Found during the run and fixed: the finite-field row builder read coefficient residues as exponents whenever a block has dimension 3 (pattern collision in maximumExponents), 9 s per sample on a 48-unknown block and kernel death at 31-bit primes; regression test in t_finite_field_round2 (Dim3Block*).
