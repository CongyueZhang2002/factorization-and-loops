# Direct discriminator V2 postmerge rebase manifest

Date: 2026-08-23 (America/Los_Angeles)  
Validation scope: static and delimiter checks only; no Wolfram/Mathematica launch.

## Provenance pins

- CF300 sector-12 rank-2 preparation: `6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4`
- Physical input: `274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6`
- Preparation driver: `4389186e48d0d4c4eb1fdb10b3a849306ba9354e977dde00eb60b3a3d46e71dd`
- `FiniteFieldStripSolve.wl`: `8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70`
- `DirectRootChannelAssembler.wl`: `227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6`
- `FlintAffineRREFAdapter.wl`: `d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605`
- `flint_affine_rref.c`: `11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd`
- `flint_affine_rref` binary: `e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5`
- Atomic/checkpoint helper: `dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30`

The adapter hash is present twice in V2: once as the named runtime pin and once in the executed source closure. The preparation artifact independently carries the postmerge package dependency hashes. The old preparation `a674f449...` and adapter `ec35738a...` do not occur in V2.

## Frozen implementation files

- `run_cf300_sector12_rank2_direct_ansatz_discriminator_v2.wls`: `346b3bfe722e1049d02a1d032a40479e19b6866b34811477c8cc12f05e676f64`
- `DirectDiscriminatorAtomicCheckpointV2.wl`: `dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30`
- `run_cf300_sector12_rank2_direct_ansatz_discriminator_v2.integration.patch`: `58c6fa2e6cfb6c6b5423b218ad681acf605633eb030069f2920ef45b45a520c0`
- `check_wl_no_kernel_parse_guard.pl`: `26e4ba7f4e871c4280fc4808db884d6bf84ebcfd6c45784c68dba4bca229de7e`
- `test_direct_discriminator_atomic_checkpoint_v2_static.sh`: `536173615ef0dacb1c94c87dab5ce0dadddb5701d9bb188fb0587c4a1228ee8f`
- Original V1 driver, unchanged: `3a3093357f16094f311b98be305bac05f2b22b89f0fe5be586d1369cf6de29fa`

Static result: **68 passes, 0 failures**. The helper and V2 driver both pass the existing Wolfram delimiter checker and the new comment/string-aware no-kernel lexical guard. The guard rejects any context backtick followed by whitespace or EOF outside comments and strings; its negative fixture reproduces the launch-blocking token class. It is explicitly a lexical surrogate, not a claim of full equivalence to held `ToExpression`.

## Held-parse correction

The first postmerge launch failed before execution because the qualified helper symbol was split after its context backtick:

```wl
CodexDirectDiscriminatorAtomicCheckpointV2`
  DDACRejectedReasonHistogram[rejectedPoints]
```

V2 and the integration patch now keep the context delimiter and symbol token contiguous. The ordinary delimiter checker could not see this lexical error because brackets, braces, parentheses, comments, and strings were balanced.
