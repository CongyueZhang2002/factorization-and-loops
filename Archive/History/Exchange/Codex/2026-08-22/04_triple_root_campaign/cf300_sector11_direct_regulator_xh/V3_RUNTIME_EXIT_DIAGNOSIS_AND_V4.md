# CF300 sector 11: V3 runtime exit diagnosis and V4

## V3 terminal evidence

The centrally launched V3 mission completed its mathematics and atomic writes.  It
reported output SHA-256 `e98957...` and report SHA-256 `77399d...`, but the pool
classified the mission as failed because the final exit expression evaluated as
`EXITfinalCode`.

The defect is confined to the final status dispatch.  V3 assigned `finalCode` in
its package private context, executed `End[]; EndPackage[]`, and then evaluated an
unqualified `finalCode`.  At that point the name resolves as `Global`finalCode`,
which is unbound.  This does not invalidate the already-written artifacts, but a
failed mission is not accepted as production continuation evidence.

## V4 correction

V4 is an adjacent source.  V3 remains unchanged.  V4 uses a distinct package and
artifact context and exits through the fully qualified private symbol:

```wl
System`Exit[
  CodexCF300Sector11DirectRegulatorContinuationV4`Private`finalCode];
```

The V4 static test uses `rsplit` at the final `EndPackage[];`, requires the entire
post-package tail to equal that expression, and rejects unqualified or captured
`finalCode`/`resolvedFinalCode` status dispatch.  All mathematical gates, the
correct scalar `t=P/eps^3`, source pins, sparse propagation, seals, and atomic
write rules are otherwise unchanged.  V4 report schema version is 4.

Launch V4 only into a fresh, empty V4 candidate directory on a clean main kernel
with zero subkernels.  Do not use poisoned kernel 144.
