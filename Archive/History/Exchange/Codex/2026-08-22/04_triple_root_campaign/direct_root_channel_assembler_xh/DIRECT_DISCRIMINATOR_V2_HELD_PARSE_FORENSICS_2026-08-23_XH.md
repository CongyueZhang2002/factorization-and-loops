# Direct discriminator V2 held-parse failure and correction

Date: 2026-08-23 (America/Los_Angeles)  
Scope: Exchange-only, no Wolfram/Mathematica launch, no process control, and no package-source edit.

## Finding

Mission `cf300_s12_direct_discriminator_postmerge_xh_v1` failed at 10:00:47 with zero runtime because the pool wrapper's held parse returned `$Failed` before `Get` or driver execution. The wrapper imports the target as text, removes the shebang, and evaluates `ToExpression[parseText, InputForm, HoldComplete]` in a temporary context.

The exact malformed token in the frozen V2 candidate was:

```wl
CodexDirectDiscriminatorAtomicCheckpointV2`
  DDACRejectedReasonHistogram[rejectedPoints]
```

A Wolfram context backtick is part of the qualified symbol token. Ending the physical line after it leaves a bare context delimiter followed by whitespace, so the held parse fails. This was the only context token in V2 ending before its symbol. It was introduced by the V2 histogram fix and occurs in neither V1 nor the corrected integration hunk. Ordinary delimiter balance did not detect it because every bracket, brace, parenthesis, comment, and string remained balanced.

Evidence:

- failed mission log SHA-256: `f701aa87b2ebdfea7d90b08220e636adb9197ae437bef5439a96d92910be7875`;
- generated failed wrapper SHA-256: `e88ee865900f592931eae1cd8d8117f463eb69308d122348fed5012c0e137276`;
- the wrapper contains the held parse gate and records `KPSUBMIT TARGET PARSE FAILURE`;
- no driver statement ran, so this incident created no new numerical or checkpoint evidence and did not exercise the atomic writer.

## Correction

The driver and reproducible integration patch now contain the contiguous token:

```wl
CodexDirectDiscriminatorAtomicCheckpointV2`DDACRejectedReasonHistogram[rejectedPoints]
```

An adjacent no-kernel lexical preflight was added. It scans outside nested comments and strings, validates delimiter closure, and rejects every context backtick followed by whitespace or EOF. It is intentionally general over symbol names. A synthetic split-context fixture is required to fail, while equivalent text inside a string or nested comment is required to pass.

The guard is a lexical surrogate for this failure class, not a full implementation of the Wolfram grammar and not a claim of exact equivalence to held `ToExpression`. The task prohibited the only authoritative runtime parse check.

## Frozen code and test hashes

- corrected V2 driver: `346b3bfe722e1049d02a1d032a40479e19b6866b34811477c8cc12f05e676f64`;
- atomic/checkpoint helper, unchanged: `dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30`;
- corrected integration patch: `58c6fa2e6cfb6c6b5423b218ad681acf605633eb030069f2920ef45b45a520c0`;
- no-kernel lexical guard: `26e4ba7f4e871c4280fc4808db884d6bf84ebcfd6c45784c68dba4bca229de7e`;
- static suite: `536173615ef0dacb1c94c87dab5ce0dadddb5701d9bb188fb0587c4a1228ee8f`;
- immutable V1: `3a3093357f16094f311b98be305bac05f2b22b89f0fe5be586d1369cf6de29fa`.

Static result: **68 passes, 0 failures**. Both the V2 driver and helper pass the legacy delimiter checker and the new lexical guard. The preparation, input, corrected adapter, helper, and source-closure pins remain unchanged and coherent.
