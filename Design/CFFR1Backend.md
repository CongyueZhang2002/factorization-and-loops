# Wolfram-side CFFR1 backend ("PlanDiscoveryBackend" -> "FLINTAffineRREF")

Binding design, 2026-08-23 (Fable).  Implements the promotion boundary of
`Exchange/Codex/2026-08-23/12_package_bug_handoff.md` for the
native affine-RREF adapter now at `FeynFacet/Backends/flint/flint_affine_rref`
(protocol `PROTOCOL_CFFR1.md`; source SHA256 11f4d337...5617cd; independently
re-verified 2026-08-23: bit-identical rebuild, 73/73 + 36/36, byte-identical
benchmark).  The CFFA4 writer/parser is NOT reused: it binds no nonce and no
immutable hashes, and its silent-fallback semantics are forbidden here.

## Where it hooks

Plan discovery in `FiniteFieldStripSolve.wl` (the constrained elimination
plan: rank/nullity, pivot/free columns, independent rows, normalization
columns) currently runs one Wolfram RowReduce/MatrixRank pass.  The stub
`finiteFieldStripPlanDiscoveryBackendDecision` already validates the option;
"FLINTAffineRREF" returns PlanDiscoveryBackendUnavailable.  The new branch
replaces exactly that discovery step; everything downstream (per-prime
follower solves, CRT, lift) is unchanged.

## Contract

1. Request writer `finiteFieldStripCFFRRequest[matrix, rhs, prime,
   preference, nonce]`: CFFR1V1 wire format per PROTOCOL_CFFR1.md
   (LE 64-bit words, row-major, zero-based; preference = the residue-first
   normalization column order the plan already computes).  The 128-bit
   nonce comes from a cryptographic RandomInteger; zero nonce is invalid.
2. Runner: binary at FeynFacet/Backends/flint/bin/flint_affine_rref,
   located by a `finiteFieldStripCFFRBinary[]` sibling of the CFFA4
   locator.  Thread argument: Min[threads, 8] (machine policy; the
   adapter accepts 1..64 but the licence box has 8 P-cores -- deliberate
   cap, recorded in the plan).  Input/output through unique files in the
   artifact directory; both deleted on success, kept on failure.
3. Response parser `finiteFieldStripCFFRResponse[bytes, request]`: parse
   CFFR1X1, REQUIRE echoed nonce == sent nonce, exact payload length,
   rank/nullity consistency, pivot/free/normalization index ranges and
   disjointness.  Any violation is a typed failure carrying the adapter
   exit code and the first divergent field.
4. Wolfram-side verification (do not trust the adapter's internal
   witnesses alone): all-row residuals A.particular == b (mod p),
   A.Transpose[nullspace] == 0, identity structure on free columns --
   the same acceptance the CFFA4 path applies.  O(m n (k+1)) mod-p dots;
   negligible against discovery cost.
5. Plan sealing: the accepted plan is sealed by the EXISTING
   `finiteFieldStripSealEliminationPlan` and additionally records
   <|"PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
     "AdapterSourceSHA256", "AdapterBinarySHA256", "Protocol" -> "CFFR1",
     "Nonce", "RequestSHA256", "ResponseSHA256", "Threads"|>.
   Hashes computed once per session and cached; a binary whose hash
   changes mid-session is a typed failure.
6. Fallback semantics: requested === "FLINTAffineRREF" NEVER falls back
   (missing binary, bad hash, nonzero exit, parse or verification failure
   are typed failures propagated to the caller).  Automatic never selects
   the native path in this pass (conservative default; flip later by
   measurement).  requested === "Wolfram" is the historical path.

## Tests (new `Tests/FiniteField/t_finite_field_affine_rref_backend.wls`)

Small dense systems with known rank/nullity: (a) agreement of the native
plan with the Wolfram plan on pivot/free/normalization columns and
rank/nullity; (b) explicit-request-with-missing-binary -> typed failure,
no fallback (point the locator at a nonexistent path via an option or
temporary rename inside the test's scratch copy -- do not touch the real
bin/); (c) truncated response file -> typed failure naming the field;
(d) nonce mismatch (flip a byte in the echoed nonce of a captured
response) -> typed failure; (e) an inconsistent system -> adapter exit 5
surfaces as a typed InconsistentModularSystem, no artifact written;
(f) the sealed plan carries every binding field of item 5; (g) follower
solves on a CFFR-discovered plan reproduce the Wolfram-plan solution
exactly at two primes.

## Non-goals

No change to the CFFA4 core-solver path or its thread cap; no Automatic
promotion of the native path; no use in the family certificate.
