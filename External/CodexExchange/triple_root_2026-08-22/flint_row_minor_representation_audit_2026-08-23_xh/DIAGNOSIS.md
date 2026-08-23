# CF300 row-minor inverse witness audit

Date: 2026-08-23  
Scope: `RowMinorInverseWitness -> False` in the CF300 denominator-witness Q
candidate, including the Wolfram adapter, native C producer, wire decoder, and
qdiag/qwire artifacts.  
Method: read-only static and artifact audit. No Wolfram kernel or heavy job was
launched and no active source was edited.

## Verdict

This is a **Wolfram representation-equality false negative**, not a failed
inverse and not a row-major wire-layout error.

The adapter uses exact structural equality:

```text
Mod[rowMinor . rowInverse, p] === IdentityMatrix[rank]
```

For sufficiently large dimensions, `IdentityMatrix[n]` with its default
`TargetStructure -> Automatic` is a structured array rather than an ordinary
nested list. The product on the left is a dense ordinary matrix. `SameQ`/`===`
does not coerce these representations, so mathematically identical matrices can
compare false. Wolfram's official documentation explicitly states that
`Automatic` returns a dense matrix below a preset threshold and a structured
array above it, and that `Normal[IdentityMatrix[...]]` returns an ordinary
matrix:

https://reference.wolfram.com/language/ref/IdentityMatrix.html

The Q target is the first witness here whose row-minor rank is large enough to
exercise that automatic representation switch. Its nullity-sized identities
remain small, which explains the otherwise distinctive check vector:

- `RowMinorInverseWitness -> False`;
- affine/nullspace residuals and derived canonical nullspace -> `True`;
- canonical free identity and normalization-minor inverse -> `True`.

## Exact evidence chain

### qdiag artifact

`cf300_s12_denominator_witness_qdiag_xh_v3.wl` reports a structurally valid
certificate with every algebraic check true except
`RowMinorInverseWitness`. In particular:

- `PayloadShapesAndWords -> True`;
- `DerivedCanonicalNullspace -> True`;
- `NormalizationMinorInverseWitness -> True`;
- `RowMinorInverseWitness -> False`.

Artifact SHA-256:
`62f5eea3dc785adbdba34a794ceee582f90359b2dbbefe0eb04722255fb9e4c6`.

### native producer

The pinned binary SHA-256 is
`e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5`.
The adapter can reach `AffineRREFCertificateRejected` only after the process
exits zero and a response parses successfully.

Before returning zero or opening the final output, the C program:

1. reads the request matrix row-major;
2. sorts the independent original-row indices;
3. constructs `A[independent_rows,pivot_columns]` in that same sorted order;
4. calls `nmod_mat_inv`;
5. verifies both `minor.inverse == I` and `inverse.minor == I` with FLINT;
6. writes the already verified inverse row-major.

A mathematical inverse failure therefore causes native exit 6 and no accepted
response; it cannot produce the observed exit-zero/certificate-rejected path.

The current C source SHA-256 is
`11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd`.
The existing native suite records 73/73 release checks and 36/36 sanitizer
checks, including two-sided row-minor verification and a 672x625 physical-shape
case.

### wire layout

There is no producer/consumer orientation mismatch:

- C `write_nmod_matrix` loops row first, column second;
- the protocol declares all matrices row-major;
- Wolfram slices exactly `rank^2` words and uses
  `ArrayReshape[flat,{rank,rank}]`;
- `verify_wire_row_minor.py` uses NumPy
  `reshape(rank,rank)`, also row-major, with zero-based request/response indices.

The adapter adds one to all wire indices before submatrix extraction, so the
Wolfram row/pivot selection denotes the same minor as native C.

### retained qwire v6: independent wire verification passes

qwire v6 retained the rejected adapter payload at `/tmp/m00003537554061`.
The adapter again rejected **only** `RowMinorInverseWitness`; its parsed header
was `rows=1088`, `columns=1040`, `rank=1028`, `nullity=12`, `prime=10007`.

Running the independent, non-Wolfram verifier on those exact bytes with eight
Freivalds trials in both multiplication directions returned:

```json
{"columns": 1040, "independent_rows_sorted": true,
 "leading_sample_identity": true, "left_failures": [], "nullity": 12,
 "pivots_sorted": true, "prime": 10007, "rank": 1028,
 "right_failures": [], "rows": 1088, "status": "OK", "trials": 8}
```

The independent verifier also checks the leading `8 x 8` product exactly.
Combined with the native program's mandatory full, exact two-sided check before
it writes the response, this is decisive evidence that the inverse and wire
orientation are correct. The Wolfram rejection is therefore a local comparison
representation bug.

Retained hashes:

- qwire v6 result: `72275635deee18fe8f1c8768cf6eb2349afb1c07abf39d9e19735c57b61cc673`;
- qwire v6 log: `d0320f9ee80d7a120c54f119b4979992fe1b4f737291d44c104ce32fe635afd6`;
- qwire v6 failed status: `844677a5bab64968719d936e2e47f9b3cc7db2cecc7fdebe7833ab28f781ae6a`;
- request: `b7175b7644434111419f3b1e2d21763b696b2646cb24d26c8c0ca32bf1cccf2a`;
- response: `4b9611f8cd34150d9c7ca54e8e84827be5264c5fda5deeddf8525e4ab36343de`.

Earlier qwire v4/v5 attempts stopped at `PinnedLoadFailed` before the native
rank call and retained no wire pair. They neither support nor contradict the
v6 result.

## Correction review

While this audit was being finalized, the parent agent applied the core fix to
`cffrInverseWitnessQ`. I reviewed the exact active hunk. It caches
`Normal[IdentityMatrix[size]]` once and compares it by `SameQ` to both
`Normal[Mod[matrix.inverse,p]]` and `Normal[Mod[inverse.matrix,p]]`. That is
representation-safe exact equality and preserves the two-sided, fail-closed
certificate check. The reviewed adapter SHA-256 is
`d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605`.

`0001-normalize-identity-representation.patch` is retained as the independent
pre-application proposal. Its core hunk is semantically the same correction:

```text
Normal[Mod[left . right,p]] === Normal[IdentityMatrix[n]]
```

It also records two analogous hardening sites:

- the canonical free-column identity;
- the downstream native-pilot normalization check;
- the literal static regression expectations.

Those additional sites are not involved in the Q failure because its nullity is
only 12, but they can reproduce the same structural-equality problem if a future
nullity crosses the automatic representation threshold. Do not apply the old
bundle wholesale to a live/pinned mission; rebase just those follow-up hunks.
None of these changes alter field arithmetic, row/pivot ordering, wire ABI,
native code, or certificate payload.

## Required regression

1. The parent reports the patched static suites pass 117/117 and 37/37.
2. Schedule `proposed_large_identity_regression.wls` in a managed kernel after
   the active source-hashed mission is terminal. It exercises the physical
   rank 1028 and requires:
   - raw `Head[IdentityMatrix[n]]` is not assumed;
   - `cffrInverseWitnessQ[denseIdentity,denseIdentity,n,p]` is true;
   - corrupting either side of the inverse is rejected.
3. Rerun the Q witness after the patch. The already retained v6 pair has passed
   the independent verifier; at this Q image the signed-int64 bound is safe
   because `1028*10006^2 < 2^63`.
4. Require the patched Wolfram witness to pass on the same coefficient image,
   with pinned source/binary hashes, before resuming the denominator screen.

## Python verifier hardening note

`verify_wire_row_minor.py` is suitable for this Q diagnostic, but its NumPy
`int64` products can overflow for the adapter's full allowed prime range. It is
also a randomized vector check, not the production exact certificate verifier.
Before treating it as a general verifier, fail closed when
`rank*(prime-1)^2 > 2^63-1`, or use chunked/Python-integer modular products.
