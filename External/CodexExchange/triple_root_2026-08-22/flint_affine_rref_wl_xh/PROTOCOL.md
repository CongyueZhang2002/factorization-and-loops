# External Wolfram harness for the FLINT affine-RREF certificate

This directory is deliberately outside the package. It does not alter the
current finite-field prototype or any CF300 physical driver. The adapter is a
fail-closed consumer for the companion `flint_affine_rref` executable.

## Wire format

Every scalar is an unsigned 64-bit little-endian word. Every matrix is
row-major. Wire indices are zero-based; the parsed Wolfram association converts
them to one-based indices.

The request begins with the eight bytes `CFFR1V1\0`, followed by nine words:

`m, n, rhs_columns=1, p, preference_count=n, flags=0, nonce_hi, nonce_lo, payload_words`.

The request payload is `A` (`m*n` words), `b` (`m` words), then a strict
permutation of the `n` column indices. Its exact word count is `m*n+m+n`.

The response begins with `CFFR1X1\0`, followed by eleven words:

`m, n, rhs_columns=1, p, rank=r, nullity=k, preference_count=n, flags=0, nonce_hi, nonce_lo, payload_words`.

The response payload order is:

1. pivot columns (`r`);
2. free columns (`k`);
3. sorted independent equation rows (`r`);
4. sorted normalization columns (`k`), selected greedily as a set in request
   preference order;
5. canonical particular solution (`n`);
6. canonical nullspace basis (`k*n`), one row per sorted free column;
7. inverse of `A[independent_rows,pivot_columns]` (`r*r`);
8. inverse of `N[:,normalization_columns]` (`k*k`).

Thus the exact response payload word count is
`3*n + k*n + r*r + k*k`. Rank-zero and nullity-zero objects occupy zero
words; no placeholder word is serialized.

## Independent acceptance checks

Parsing binds the response to the request dimensions, modulus, and 128-bit
nonce, rejects any nonzero flag, checks the formula above before allocating the
payload, and requires exact EOF. Verification then checks canonical residue
words and all index partitions, and independently proves:

- `A.p=b` and `A.N^T=0` modulo the prime;
- `N[:,free]=I`, `p[free]=0`, and the RREF pivot ordering condition;
- both products for the row-minor inverse witness;
- `p` and `N` exactly equal the objects derived from that row minor;
- both products for the normalization-minor inverse witness;
- normalization columns equal the greedy independent set induced by the
  request preference (serialized in sorted order).

Only after those checks can the adapter produce fields compatible with the
existing `CrossPrimeEliminationPlanV1` association and its stable fingerprint.

## Deferred runtime smoke

No Wolfram kernel was launched while authoring this harness. After the companion
binary is built, run the differential driver through the managed kernel pool,
not as an unmanaged standalone kernel:

```text
run_flint_affine_rref_differential_smoke.wls \
  <repository-root> <flint_affine_rref-binary> <fresh-report.wl> \
  24 2026082301
```

It compares randomized rank-deficient and full-rank systems against
`TRCanonicalAffineSolve`, includes rank-zero and nullity-zero boundaries, builds
V1 plan fields, and rejects semantic corruption plus bad magic, nonce,
payload-size, truncation, and trailing-byte cases. The driver loads and
hash-binds the same complete dependency stack as the physical drivers, captures
load and runtime messages, and fails closed if either capture is nonempty.

`run_cf300_sector12_rank2_native_pilot_benchmark.wls` is the physical
CF300 (12,9) benchmark. It revalidates the prepared artifact and scans a bounded
deterministic cross-prime/epsilon grid, retaining typed inconsistent-image
evidence. It chooses the earliest maximum-rank consistent image only after
consistent witnesses from at least two primes, runs that exact image at 1, 2,
and 4 threads, and requires identical plans and certificates modulo nonce.

`NativeAffinePilotPrime.wl` and
`run_cf300_sector12_rank2_native_prime.wls` form the external production-shaped
path. Discover natively probes a bounded prefix of the candidate epsilon pool,
classifies native exit code 5 as a typed mathematical image inconsistency, and
chooses the earliest maximum-rank consistent image for the V1 plan. All other
usable images use the existing fixed-plan FLINT solver. Failed images remain in
the artifact and are excluded only when at least `ConstructionCount+4` stable
samples remain. Reuse uses that fixed plan for every usable image. Both modes
finish through the existing `InterpolateEpsFormStripAffine` and emit
`RationalAffinePrimeInterpolated` artifacts consumable by the current
aggregate, while recording native source and binary hashes separately from the
preparation dependency manifest.
