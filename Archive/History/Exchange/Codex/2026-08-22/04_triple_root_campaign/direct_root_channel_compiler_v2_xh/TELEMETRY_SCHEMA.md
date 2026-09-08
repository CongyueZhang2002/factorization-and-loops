# Compiler V2 telemetry schema

All timings are Wolfram `AbsoluteTiming`/`AbsoluteTime` wall seconds. Runtime
numbers are emitted only by managed drivers; this directory contains no
author-time runtime claim.

## Core telemetry

- `AlgebraicBundleSeconds`: E/C/BBar pooling, decomposition, inversion,
  round-trip checking, and sparse compilation.
- `RationalFastPathBundleSeconds`: root squares, root dlogs, gauge denominator,
  and gauge dlogs through the rank-0 path.
- `FingerprintSeconds`: exact/compiled/pool/core stable fingerprints.
- `TotalSeconds`: entire core call, including validation and construction.
- `FinalUniquePolynomialCount`: canonical polynomials retained in the core
  seed.
- `AlgebraicBundle`, `RationalBundle`: counters described below.

## Bundle counters

- `ScalarOccurrences`, `UniqueScalars`, `ScalarPoolHits`,
  `ScalarCollisionChecks`;
- `PolynomialPoolHitsThisBundle`, `PolynomialPoolMissesThisBundle`,
  `PolynomialCollisionChecksThisBundle`;
- `RootFreeFastPathCount`, `AlgebraicPathCount`;
- `RecursiveInverseCalls`, `MaximumInverseRank`;
- `IndependentInverseChecks`, `IndependentRoundTripChecks`.

Hash bucket probes count as collision checks even when `SameQ` confirms a true
duplicate. This makes adversarial hash-collision work visible without treating
it as a correctness failure.

## Ansatz and rebind telemetry

Fresh ansatz mode records `OneFormCompileSeconds`, its bundle counters, and
total time. Rebind mode is one of:

- `SupportOrNormalizationOnly`: zero algebraic compilation;
- `OneFormPrefixExtension`: only the exact appended suffix is compiled.

Rebind records old/new/appended one-form counts and appended compile seconds.

## Physical benchmark fields

The physical driver reports `LegacyCompileSeconds`, `V2CoreCompileSeconds`,
`V2AnsatzCompileSeconds`, `V2TotalCompileSeconds`,
`LegacyOverV2Speedup`, `SupportRebindSeconds`, and `SupportFreshSeconds`.
`ExactV1AssemblyEqual`, `SupportRebindExact`, empty captured messages, and
stable source hashes are correctness gates, not telemetry annotations.
