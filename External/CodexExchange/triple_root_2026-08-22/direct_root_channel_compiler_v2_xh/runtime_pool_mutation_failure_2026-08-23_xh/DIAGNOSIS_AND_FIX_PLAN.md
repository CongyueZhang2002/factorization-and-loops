# V2 managed synthetic failure: diagnosis and fix plan

Date: 2026-08-23  
Status: source-pinned diagnosis while `drcav2_adversarial_xh_v1` is live  
Constraint: no Wolfram kernel launched, no process signalled, and the active
`DirectRootChannelCompilerV2.wl`/driver were not edited.

## Root cause

The runtime failures at synthetic ranks 0, 1, and 2 have one common source:
both pool-miss paths call Wolfram's two-argument `AssociateTo` with multiple
rules as separate arguments.

The live captured message stream contains:

```text
AssociateTo::argrx: AssociateTo called with 3 arguments; 2 arguments are expected.
Part::partw: Part 1 of {} does not exist.
```

The active source has two bad calls:

- `drcav2PolynomialPoolIntern`, lines 161–164: four total arguments;
- `drcav2ScalarPoolIntern`, lines 205–207: three total arguments.

The scalar call is reached first. On the first unique scalar it computes index
1, but the invalid `AssociateTo` does not append the value or increment the
miss counter. The following valid bucket update nevertheless records index 1.
The next structurally repeated scalar finds bucket `{1}` and evaluates
`pool["Values"][[1]]` while `Values` is still `{}`, producing `Part::partw`.
Later mappings therefore contain invalid parts or empty decomposition tables,
which explains all three downstream failures for every rank:

1. the V1 exact-assembly comparison fails;
2. the point differential is forced false because V2 validation fails;
3. telemetry lookup/contract fails because there is no valid V2 core.

After the scalar call is repaired, the polynomial pool's identical arity bug
would be the next failure. Both must be fixed together.

## Exact proposed source fix

Apply `0001-fix-pool-associateto-arity.patch` only after the source-hashed live
mission is terminal. It changes each invalid multi-rule call into one
`AssociateTo[pool, <|...|>]` call. The update expressions are evaluated against
the old pool before the association update, preserving the intended atomic
miss bookkeeping.

No algebra, basis order, hash key, collision check, ABI, or telemetry field is
changed.

## Required regression sequence

1. Wait for the current source-hashed mission to become terminal. Do not stop
   or alter it.
2. Preserve its log, runtime-message file, terminal status/report, and source
   hashes as failed-run evidence.
3. Apply the two-hunk patch to the External prototype.
4. Add the top-level-arity check from `audit_associateto_arity.py` to the static
   suite. The current source is expected to report arities 4 and 3; the patched
   source must report no violation.
5. Strengthen the synthetic driver diagnostics before rerun:
   record, per rank, `LegacyStatus`, `V2Status`, `V2FailureReason`,
   `V1ViewHead`, `V2CoreStatus`, and the two validator booleans separately.
   Do not index `v2["Core", ...]` unless V2 status and assembly validation have
   passed. Include captured messages in every early failure report.
6. Rerun the synthetic driver with a fresh mission label and fresh output.
   Require ranks 0–3 exact V1 equality, point equality, telemetry, empty
   messages, and stable hashes.
7. Only after the synthetic rerun passes, schedule the CF300 physical benchmark.

## Driver diagnostic gap exposed

The current driver collapses compile, adapter, and validation failures into the
same three failed checks. The exact-assembly check only records elapsed times
and fingerprints; it omits the V2 status and failure reason. The point check is
then recorded as `CompileOrValidationFailed`, and the telemetry branch treats
any failure association as though it were a V2 assembly.

This did not cause the compiler failure, but it delayed diagnosis. The next
driver revision should fail closed with typed stage diagnostics while still
continuing across ranks to preserve the adversarial matrix.

## Relation to the earlier audit

This is a Wolfram call-arity implementation bug, not an error in the recursive
norm algebra. The independent exact rank-0 through rank-3 recursive-versus-dense
tests remain valid. The earlier no-metadata V1 fingerprint discrepancy is also
separate; this synthetic driver supplies explicit metadata.

