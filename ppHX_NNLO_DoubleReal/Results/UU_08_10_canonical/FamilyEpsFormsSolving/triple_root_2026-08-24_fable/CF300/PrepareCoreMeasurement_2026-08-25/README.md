# CF300 (12,9) prepare/compile measurement — serial-phase wave, 2026-08-25

Evidence for the serial-phase agent's headline measurement on the real
CF300 off-diagonal block (12,9) (strip leaf count 1,133,532; root rank 2;
52 letters after norm filtering).

## Measured result (`cf300_prepare_result.wl`, schema CF300PrepareCoreMeasurementV1)

Two end-to-end runs of preparation + compilation on identical inputs,
differing only in the `"CompileCore"` option:

| run                  | prepare (s) | compile (s) | total (s) | peak RSS (MB) |
|----------------------|-------------|-------------|-----------|----------------|
| HEAD (CompileCore off) | 2710.9      | 91.3        | 2802.2    | 1795           |
| NEW  (CompileCore on)  | 2810.7      | 89.8        | 2900.5    | 2020           |

Both runs reach `CompiledMultiquadraticStripV1`; `PreparationEquivalent ->
True` and the assembly fingerprints agree exactly
(`c5fa06a1995118f21819498922a8ae747b3d6cefa7cbf32fe72e7713528f529d`).

Interpretation recorded at the time: the compile's core stage costs only
0.16 s, so letting prepare consume the compiled core cannot pay — the
option ships DEFAULT OFF. Preparation's own 2710.9 s is the remaining
cost target for this block; `cf300_attribute.wls` is the attribution
driver written to decompose that 2710.9 s into its stages (NOT yet run —
scheduled for the hardening wave).

## Files

- `cf300_prepare.wls` — the measurement driver (both runs + equivalence
  and fingerprint comparison).
- `cf300_prepare_result.wl` — the measured record quoted above.
- `cf300_prepare.log` — run log.
- `cf300_attribute.wls` — prepare-cost attribution driver, unrun.
- `suite/`, `suite2/` — the serial-phase agent's full test-suite logs
  (all suites green) taken with the wave applied, before commit.
