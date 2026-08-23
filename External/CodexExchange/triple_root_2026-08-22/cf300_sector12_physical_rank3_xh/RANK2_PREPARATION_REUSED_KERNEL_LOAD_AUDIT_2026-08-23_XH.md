# CF300 sector-12 rank-2 preparation: reused-kernel load audit

Date: 2026-08-23 (America/Los_Angeles)  
Scope: read-only diagnosis plus adjacent Exchange-only driver hardening. No Wolfram/Mathematica launch, no active-source edit, and no process signal.

## Finding

The reused pool kernel entered `LoadFACET.wl` with an OwnValue on ``Global`n``. The loader source constructs:

```wl
FeynFacet`BuildGlobalBasis[{Global`nb, Global`n, Global`xhat, Global`yhat}]
```

The emitted message reports the already evaluated list `{nb, 5, xhat, yhat}`. Therefore `Global`n evaluated to `5` before `BuildGlobalBasis` received the vectors. This is a reused-kernel global-state collision, not an input-artifact or rank-2 algebra failure.

The V1 mission eventually succeeded after 347.853762 seconds and wrote preparation SHA-256 `6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4`, but it retained `HadMessages -> True`. The message did not block this run; it remains nondeterministic loader pollution that should not be accepted as normal operation.

## Can `LoadFACET` be skipped?

Yes, but only after a fail-closed runtime certificate passes. Merely finding a public symbol or context is insufficient.

The adjacent V2 permits reuse only when all of the following hold:

1. FeynFacet's private runtime source-file list exists and every file exists under the intended project `FeynFacet` directory.
2. The list starts with the exact current `FeynFacet.m` and contains every preparation dependency named by the driver.
3. Rehashing every runtime source file reproduces `FeynFacet`'s loaded `$feynFacetSourceHash`.
4. `FamilyArtifactRead` and `TransportFamilyChart` have definitions.
5. The stored `FamilyArtifactRead` definition visibly contains the `System`/`Global` context guard.
6. `TransportFamilyChart["CF300"]` returns an association.

If any check fails, V2 does not reuse the runtime.

## Reload strategy

The adjacent V2 uses three ordered modes:

- `ReuseValidatedFeynFacetRuntime`: skips `LoadFACET` only under the certificate above.
- `ReloadFeynFacetPublicWithExistingFeynCalc`: when FeynCalc is already present but FeynFacet is stale or incomplete, reloads `FeynFacet.m` directly and tolerates messages while requiring the same postconditions.
- `LoadFACETWithLocalizedBasisSymbols`: on a fresh kernel, or as fallback, evaluates `LoadFACET.wl` inside a `Block` that localizes ``Global`nb``, ``Global`n``, ``Global`xhat``, and ``Global`yhat``. This prevents an inherited value such as `n = 5` from reaching `BuildGlobalBasis`.

Messages are captured, recorded, and do not alone decide success. Abort is detected separately. The resulting runtime must pass the full semantic/source certificate; otherwise the driver writes `RuntimeLoadValidationFailed` and exits fail-closed.

The four triple-root Exchange modules are then re-read message-tolerantly from their hash-pinned files. Eight required algebra/strip/reconstruction definitions must exist, and their definition fingerprint is recorded.

## Preserved provenance and physics checks

V2 preserves all original gates:

- input hash before load, after context-safe read, and at completion;
- driver hash before/after load and at completion;
- every dependency hash before/after load and at completion;
- `FeynFacet`FamilyArtifactRead[inputFile]`, not raw `Get`, for the physical input;
- sidecar round trip, channel/support fingerprints, square-class independence, root order, regulator clearance, preparation ABI, unknown cap, and final atomic output.

It adds `LoadCertificate` to success and failure artifacts. The certificate records load mode, messages, full FeynFacet runtime source seal, required-definition fingerprints, and triple-root postconditions. No dependency or input check was removed or relaxed.

## Adjacent files

- `run_cf300_sector12_rank2_extension_prepare_reuse_safe_v2.wls`  
  SHA-256: `7b9aab6effbc4512c76fcf0cc11914b67c84db7bce609c749458813801a1869b`
- `test_rank2_extension_prepare_reuse_safe_v2_static.sh`  
  SHA-256: `032c68034939b43055745502a5433e5ff7ac7a95e7422ebc108104d2ebe99730`
- Original active V1 driver, unchanged:  
  SHA-256: `4389186e48d0d4c4eb1fdb10b3a849306ba9354e977dde00eb60b3a3d46e71dd`

Static result: **47 passes, 0 failures**; V2 passes the existing Wolfram delimiter checker. Runtime behavior is intentionally not claimed because no Wolfram kernel was launched.
