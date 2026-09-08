# CF300 denominator-witness driver V2 proposal

Date: 2026-08-23  
Scope: adjacent External-only driver; the active V1 driver and all package,
adapter, and native sources remain untouched. No Wolfram kernel was launched.

## Outcome

`run_cf300_sector12_denominator_witness_screen_v2.wls` resolves the selector
before calling `buildTarget`. A legacy fingerprint-targeted run therefore
constructs exactly one target instead of constructing all three and discarding
two after roughly 83 seconds of symbolic work.

Legacy selector behavior is preserved:

- omitted selector or `ALL`: the three individual candidates, in the census
  artifact's original order, with the existing all-candidate success status;
- one of the three factor fingerprints: exactly that individual candidate,
  with the existing targeted success status.

The V2 mask ABI adds exactly four product selectors:

- `MASK:011`, `MASK:101`, `MASK:110`: the three pair products;
- `MASK:111`: the triple product.

Bits are ordered by ascending factor fingerprint, not by the incidental census
artifact order. The exact bit order and resolved component fingerprints are
published in every output. Products are formed from that ordered catalog and
receive their own factor fingerprint. Thus repeated runs and differently
ordered-but-contract-equivalent census data resolve the same mask.

For the pinned census the human-readable bit catalog is:

1. `2d711642...`: `x`;
2. `c799eabc...`: `1 - 2 x + x^2 + 2 y + 2 x y + y^2`;
3. `ce44a483...`: `1 - x`.

Consequently `MASK:110` is `x` times the quadratic factor, `MASK:101` is
`x (1-x)`, and `MASK:011` is the quadratic factor times `(1-x)`.

The pinned bidegree/count model predicts:

| selector | support | unknowns | points |
|---|---:|---:|---:|
| `MASK:011` | 64 | 1168 | 38 |
| `MASK:101` | 42 | 816 | 27 |
| `MASK:110` | 64 | 1168 | 38 |
| `MASK:111` | 72 | 1296 | 42 |

These follow from base denominator bidegree `(4,5)`, 16 gauge channels, and
144 residue unknowns. They are planning estimates; the driver recomputes and
ABI-validates all sizes from the exact expressions at runtime.

## Physics/algebra semantics

For a selected set of factors `S`, V2 uses

```text
new denominator = old denominator * Product[f, f in S].
```

The numerator-support containment map is built from `CoefficientRules` of the
full product, so the old ansatz embeds by polynomial convolution exactly as it
does for one factor. The support remains the dense bidegree rectangle required
by the existing ABI/rebind path. All existing common-point, right-hand-side,
pure-superset containment, left-witness, and two-rank checks are unchanged.
For singleton selections, the original census candidate association and the
original `CF300DenominatorWitnessPureSupersetV1` metadata are used verbatim;
the product metadata schema is introduced only for pair/triple targets.

## Pin and failure contract

The source hash association and preparation/cache/census SHA-256 pins are copied
unchanged from the audited V1 snapshot. Because V2 is adjacent, its two helper
paths explicitly point back to `cf300_sector12_next_ansatz_xh`; their hashes are
still checked before load and at completion. V2 also retains its own driver
self-hash gate and atomic, no-overwrite output behavior.

Selector parsing is fail-closed. Singleton mask strings are deliberately not
accepted: existing factor fingerprints remain the singleton ABI, while mask
selectors denote only the new pair/triple cases.

## Runtime recommendation

After active source-hashed V1 missions finish, first schedule one legacy
fingerprint run and compare target ABI/assembly fingerprints with its V1
counterpart. Then schedule `MASK:110` (or the pair selected by physics interest)
before the triple product; pair/triple support sizes and FLINT matrices will be
larger even though target construction no longer wastes work on unselected
catalog entries.
