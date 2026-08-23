# CF300 sector-12 direct discriminator EXIT98 forensics

Date: 2026-08-23 (America/Los_Angeles)  
Scope: Exchange-only forensic analysis and static hardening. No Wolfram/Mathematica launch, no package-source edit, and no process signal.

## Conclusion

The 67-minute mission did **not** fail in the direct root-channel assembler, the finite-field sampler, or FLINT rank computation. All four selected images and all rank stages completed. The terminal failure was confined to the final artifact commit path.

The exact failing commit sub-stage is not recoverable because V1 collapsed every writer failure to the same EXIT98 message and then deleted either the temporary or committed file. No output or temporary file remained when inspected. Therefore the defensible diagnosis is:

- certain: post-computation commit-path failure;
- likely failure classes: serialization/readback, pre/post source-stability callback, or rename/target validation;
- unsupported: an actual output race. The V1 text `FAIL atomic output race` is a generic label, not evidence of a competing writer.

The independent `Counts::invrp` messages are a real telemetry bug but did not cause EXIT98 or invalidate rank computation.

## Immutable evidence

- Mission: `fresh_cf300_s12_rank2_direct_discriminator_all_xh_v1`
- Kernel: 137
- Start: 08:20:48
- End: 09:28:07
- Wall: 4039.549711 s
- Status: EXIT98, result 98, `HadMessages -> True`
- V1 driver SHA-256, unchanged: `3a3093357f16094f311b98be305bac05f2b22b89f0fe5be586d1369cf6de29fa`
- Log SHA-256: `9272494994d3b612197c50982d8147ffd8f12817a94f1892a4971d9781175359`
- Status SHA-256: `2e0f91561664c7b487dc0357952efc2ed4bc5ba3a22505b962c3a2a682c944c2`
- Requested output: `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_direct_discriminator_all_xh_v1.wl`
- Output and matching `.tmp.*` files: absent at forensic inspection.

All source-closure files named by V1 still had their pinned hashes at inspection. Their mtimes precede mission launch. The live package file `FeynFacet/Private/FiniteFieldStripSolve.wl` was subsequently edited at 09:32:22, after the mission ended, so that later edit is not evidence for the 09:28 failure.

## Completed numerical stages

The log proves completion through `all_images_complete`:

| Stage | Evidence |
|---|---:|
| census complete | elapsed 1183.142064 s; 40 unique channels; 12 factor dlogs; 48 union forms |
| ASL direct compile complete | elapsed 3688.443152 s; compile 724.771765 s; 864 unknowns |
| I00 | assembly 11.243658 s; 28 attempts; 19 nonsplit; ranks complete at 3727.140542 s |
| I01 | assembly 8.603643 s; 28 attempts; 20 nonsplit; ranks complete at 3756.099678 s |
| I10 | assembly 10.944050 s; 28 attempts; 18 nonsplit; ranks complete at 3787.552211 s |
| I11 | assembly 5.492501 s; 28 attempts; 19 nonsplit; ranks complete at 3816.680631 s |
| all images complete | elapsed 3816.680702 s |
| generic writer failure | mission end about 222.9 s later |

V1 printed no per-variant ranks. Consequently, the exact direct-run rank payload cannot be reconstructed from this log alone. The separately committed legacy per-image artifacts report the stable pattern A0 612/613, AS 804/805, AL 632/633, and ASL 824/825, all inconsistent in all four images, but those are corroborating legacy artifacts rather than a replacement for the lost direct artifact.

## Why the old writer destroyed the evidence

`writeAtomic` returned only `$Failed` for all of these distinct conditions:

1. pre-existing output;
2. failed `Put` or missing temp;
3. false source-stability callback before rename;
4. failed rename or unexpected temp/target state;
5. failed committed `Get`;
6. `SameQ` round-trip failure;
7. status mismatch;
8. false source-stability callback after rename.

It deleted the temporary file for pre-rename failures and deleted the committed output for post-rename validation failures. The caller then printed the same `atomic output race` label. The 222.9-second uninstrumented gap cannot be partitioned further after deletion.

## Empty rejected-list telemetry bug

All images used exactly 28 attempts for 28 accepted points, hence `RejectedPoints -> {}`. V1 evaluated:

```wl
Counts[Lookup[directSample["RejectedPoints"], "FailureReason", None]]
```

For this empty input, `Lookup[..., ..., None]` produced the atom `None`, so `Counts[None]` emitted `Counts::invrp`. The first three images logged the message; later output was suppressed by `General::stop`. This explains `HadMessages -> True`.

The fix is to branch explicitly on `{}` and return `<||>`, while validating nonempty entries before `Counts`. It changes telemetry only; matrices, right-hand sides, and ranks were already computed before this histogram was stored.

## Staged V2 hardening

New adjacent Exchange files were created; V1 and package sources were not modified.

### Driver

`run_cf300_sector12_rank2_direct_ansatz_discriminator_v2.wls`  
SHA-256: `346b3bfe722e1049d02a1d032a40479e19b6866b34811477c8cc12f05e676f64`

Changes:

- source-pins the new helper in both named runtime hashes and executed source closure;
- fixes the empty rejected-list histogram;
- prints each variant's coefficient rank, augmented rank, nullity, and consistency immediately after that rank pair completes;
- commits an immutable sealed checkpoint after every image;
- resumes a matching checkpoint after strict driver, preparation, input, runtime, source-closure, image, assembly-fingerprint, and rank-summary validation;
- reports a typed final writer result rather than a generic race;
- marks the result `CF300Sector12Rank2DirectAnsatzDiscriminatorV2`.

### Atomic/checkpoint helper

`DirectDiscriminatorAtomicCheckpointV2.wl`  
SHA-256: `dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30`

The helper:

- captures messages under `HoldFirst`;
- seals the payload with an exact InputForm fingerprint;
- checks temp byte count, temp hash, temp readback, pre-commit callback, atomic rename, committed byte hash, committed readback, and post-commit callback;
- returns a typed stage such as `TemporaryPutFailed`, `PreCommitCheckFailed`, `AtomicRenameFailed`, `CommittedReadbackInvalid`, or `PostCommitCheckFailed`;
- never calls `DeleteFile`; failed temp or committed evidence is preserved;
- rejects an input payload that already contains the reserved integrity key;
- provides sealed checkpoint reads and compact rank summaries.

### Reproducible integration and static test

- `run_cf300_sector12_rank2_direct_ansatz_discriminator_v2.integration.patch`  
  SHA-256: `58c6fa2e6cfb6c6b5423b218ad681acf605633eb030069f2920ef45b45a520c0`
- `check_wl_no_kernel_parse_guard.pl`  
  SHA-256: `26e4ba7f4e871c4280fc4808db884d6bf84ebcfd6c45784c68dba4bca229de7e`
- `test_direct_discriminator_atomic_checkpoint_v2_static.sh`  
  SHA-256: `536173615ef0dacb1c94c87dab5ce0dadddb5701d9bb188fb0587c4a1228ee8f`
- Static result: **68 passes, 0 failures**.
- Both Wolfram files pass the existing delimiter checker and the no-kernel lexical guard.

No runtime semantics are claimed: the task prohibited a Wolfram/Mathematica launch.

### Postmerge held-parse correction

The first V2 launch failed at the pool wrapper's held `ToExpression` gate before `Get` or driver execution. The inserted histogram call had split the qualified symbol immediately after its context backtick. V2 and the integration patch now keep `CodexDirectDiscriminatorAtomicCheckpointV2`DDACRejectedReasonHistogram` contiguous.

The added lexical guard is nested-comment and string aware and rejects any context backtick followed by whitespace or EOF, rather than matching this helper name only. Its synthetic split-context negative test passes. This closes the observed lexical class; without a Wolfram parser it is not represented as a full substitute for held `ToExpression`.

## Re-run gate

V2 is now coherently rebased to the postmerge provenance set:

- preparation SHA-256 `6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4`;
- unchanged physical input SHA-256 `274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6`;
- preparation dependency `FiniteFieldStripSolve.wl` SHA-256 `8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70`;
- corrected adapter SHA-256 `d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605`, pinned in both named runtime hashes and executed source closure.

The stale preparation `a674f449...` and stale adapter `ec35738a...` are explicitly absent from V2. Run only with the postmerge preparation artifact (or an exact preserved copy with the same hash); V2 remains fail-closed for any mixed provenance set.

## Operational recommendation

Use the coherently rebased V2 for the next all-image mission. If a final commit fails again:

- the log will already contain each completed rank summary;
- every completed image will have a sealed checkpoint;
- the typed writer record will identify the exact commit stage;
- temp/target evidence will remain available;
- a rerun with the same output path can resume valid image checkpoints whenever the final output itself is absent.
