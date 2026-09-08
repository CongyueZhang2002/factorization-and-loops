# CFFR1 rectangular affine RREF protocol

Status: isolated exchange prototype. It is not a package dependency and does
not share the package's `CFFA4V1`/`CFFA4X1` square-solve protocol.

The command line is:

```text
flint_affine_rref INPUT.bin OUTPUT.bin [THREADS]
```

`THREADS` is an optional decimal integer from 1 through 64. The implementation
is pinned to 64-bit FLINT 3.0.1 because it calls the version-specific internal
`_nmod_mat_rref` API.

Every numeric field is an unsigned 64-bit little-endian word. Matrix payloads
are row-major. Indices are zero-based. All field elements must already be
canonical integers in `[0,p)`.

## Request `CFFR1V1`

The request consists of:

1. Eight bytes `CFFR1V1\0`.
2. Header words:
   `rows=m, columns=n, rhs_columns=1, modulus=p, preference_count=n,
   flags=0, nonce_hi, nonce_lo, payload_words=m*n+m+n`.
3. `A`, containing `m*n` field elements.
4. `b`, containing `m` field elements.
5. `preference`, containing a permutation of the `n` column indices.

The implementation requires nonzero `m,n`, a prime `p`, an exact payload
length, a nonzero 128-bit nonce, and exact EOF. All sizes and size formulas are
overflow checked before allocation. The input and output must not resolve to
the same existing filesystem object, even through different path spellings.

## Response `CFFR1X1`

No response is written for a malformed request, inconsistent affine system,
failed internal verification, or other error. On success the response consists
of:

1. Eight bytes `CFFR1X1\0`.
2. Header words:
   `rows=m, columns=n, rhs_columns=1, modulus=p, rank=r, nullity=k,
   preference_count=n, flags=0, nonce_hi, nonce_lo,
   payload_words=3*n+k*n+r*r+k*k`, where `k=n-r`.
3. `pivot_columns`, `r` indices in increasing RREF order.
4. `free_columns`, `k` indices in increasing order.
5. `independent_rows`, the sorted first `r` original-row indices returned in
   the FLINT 3.0.1 RREF row permutation.
6. `normalization_columns`, `k` indices sorted in increasing order. The set is
   chosen greedily by RREF pivoting after the nullspace columns have been
   permuted into caller preference order.
7. `particular`, `n` field elements. Its free coordinates vanish.
8. `nullspace`, a `k` by `n` matrix whose rows are null vectors and whose
   free-column minor is the identity.
9. `row_minor_inverse`, the `r` by `r` inverse of
   `A[independent_rows,pivot_columns]`.
10. `normalization_minor_inverse`, the `k` by `k` inverse of
    `nullspace[:,normalization_columns]`.

Before opening an output temporary file, the executable verifies
`A.particular=b`, `A.Transpose[nullspace]=0`, the free-coordinate conditions,
and both left and right inverse identities for both witnesses. The nonce and
all identity fields are echoed. Output is written to a same-directory temporary
file, flushed and `fsync`ed, and then atomically renamed over the requested
output path.

## Exit status

- `0`: verified response atomically committed.
- `2`: usage or incompatible FLINT runtime.
- `3`: input/allocation I/O failure.
- `4`: malformed or noncanonical request.
- `5`: inconsistent affine system.
- `6`: internal verification failure.
- `7`: output commit failure.
