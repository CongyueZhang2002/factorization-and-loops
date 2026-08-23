# CF300 fresh sector-12 recapture from certified V4 state

This is the first downstream mission after the independently certified sector-11
scalar regulator transformation.  It does not solve sector 12 and never mutates
the V4 candidate.  It makes two exact copies of the V4 state in a fresh isolated
output directory: one immutable pre-sector-12 snapshot and one driver state.

The wrapper pins the 69-file production source manifest, active KernelPool exit
contract, V4 state and report, V2 validator source, successful V2 pool evidence,
formal inspector source, and formal-result JSON.  It requires one pool worker,
zero nested/helper kernels, and no arguments.  It runs the production family
driver with:

- family `CF300`, tag `standard`;
- sector budget `7200`, direct-sector budget `30`;
- `FACET_KERNEL_COUNT=1`, helper ceiling `0`;
- `Production`, `FiniteFieldFirst`, resume hydration enabled;
- `FACET_RECORD_STRIP_ONLY=True`.

The family driver must emit exactly the intentional pool payload `{"EXIT",75}`.
The wrapper captures driver messages without `Check[Get]`, restores environment,
command line, protection state, and working directory before classifying the
payload, accepts only exit 75 with an empty message list, and rethrows every
other tagged exit unchanged.

After exit 75 it requires the state to remain semantically identical to the
preserved sector-11 snapshot, with no stop record, sector-12 certificate, solver,
or strip checkpoint.  It independently reconstructs sector 12/lower 11 with the
package's source-identical `familyRowGaugeResumeBlockEquation` and requires exact
`SameQ` agreement with `CF300_12_11_input.wl`.  It then rehashes all 69 sources,
the V4 candidate, and validation evidence before writing an atomic result.

## Exact launch

Source:
`/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/run_cf300_sector12_recapture_from_v4_xh_v1.wls`

Arguments: none.

Mission resources: one clean main worker, helper ceiling zero, no subkernels; do
not use poisoned kernel 144.

The fixed output
`/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v1`
must not exist before launch.  Successful completion is normal pool status `OK`
with wrapper result `0`, not pool status `EXIT75`.
