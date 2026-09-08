# CF300 sector 11 V4 independent post-write validator

This bundle validates the immutable V4 continuation artifacts without loading
FACET and without writing any file.  It is deliberately independent of the V4
writer: a pinned Python parser proves the formal epsilon degree of all 968 entries
of the completed 22 by 22 prefix directly from serialized exact text, then the
Wolfram validator hydrates the input, output, and report in a clean dedicated
namespace and reconstructs every exact gauge identity.

## Pinned production artifacts

- input state SHA-256: `898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12`
- V4 output state SHA-256: `daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009`
- V4 report SHA-256: `eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e`
- V4 driver SHA-256: `369a05cfcc761b265059839365939cb06acbeb6e0bd9e67cf3f651706f5c3b6c`

The formal inspector was run read-only before freeze and passed.  It checked all
968 prefix entries: 317 nonzero epsilon-homogeneous channels and 651 exact text
zeros.  `Together` legitimately removes the input channel `{1,22,11}` using the
third-root identity, so the serialized output has 25 rather than 26 nonzero
lower-left channels.  The validator separately proves the algebraic identity for
all 26 input channels.

## Fail-closed gates

The mission requires exactly the two V4 candidate files and rejects known temp,
partial, part, or new siblings.  It independently checks source and artifact
hashes before and after validation, silent `Get` telemetry, empty symbol
definitions, unchanged `Global` symbols, dimensions, family/sector metadata,
unchanged state metadata, report provenance, and the absence of any sector-12
certificate or solver cache.

It proves the correct convention
`G=diag(I20,t I2,I2)`, `Anew=G^-1 Aold G`, with
`t=P/eps^3`, `P=(2eps-1)(3eps-1)(3eps-2)`.  It checks all A, S, and SInverse
entries, all 88 prefix-to-future zeros, the changed lower-left/diagonal/future
blocks, both matrix inverse products, and the propagation seal.  Wrong-side
lower-left and future transformations are explicit required-to-fail mutants.
It also certifies zero kinematic derivatives of `t`, Laurent-field invertibility,
pole order three at epsilon zero, and therefore the required `+3` epsilon-series
depth for downstream work.  The output remains sector 11 with no stop record, so
a fresh isolated sector-12 strip recapture is mandatory before a full resume.

## Exact launch

Use one clean main kernel with zero helper kernels; never use poisoned kernel 144.
Pass these three arguments in order:

1. `/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300/sector_state_CF300_standard.wl`
2. `/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300_direct_regulator_v4_candidate/sector_state_CF300_standard.wl`
3. `/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300_direct_regulator_v4_candidate/cf300_sector11_direct_regulator_report_v4.wl`

Driver:
`/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/validate_cf300_sector11_direct_regulator_v4_postwrite_v1.wls`
