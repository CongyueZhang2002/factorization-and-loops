# FLINT rectangular affine RREF exchange prototype

Status: complete native prototype and adversarial evidence; not integrated into
the package. No Wolfram kernel was used to build or test this directory.

This is a dedicated FLINT 3.0.1 adapter for a rectangular affine system
`A.x=b`. It performs one RREF of `[A|b]`, returns a canonical particular
solution and free-coordinate nullspace basis, selects a caller-preferred
normalization minor, and returns inverse witnesses for both the independent-row
minor and normalization minor. It writes no output unless all original-row
residuals, canonical free-coordinate conditions, and both sides of both inverse
identities verify internally.

The binary protocol and failure behavior are specified in `PROTOCOL.md`. It is
deliberately separate from the package's `CFFA4` square-solve protocol.

## Build and test

```bash
cd External/CodexExchange/triple_root_2026-08-22/flint_affine_rref_xh
./build.sh release
./test_native.py bin/flint_affine_rref --result native_test_result.json
./benchmark_cf300_shape.py bin/flint_affine_rref \
  --result benchmark_cf300_shape_result.json
./build.sh sanitize
ASAN_OPTIONS=detect_leaks=0:abort_on_error=1 \
UBSAN_OPTIONS=halt_on_error=1 \
  ./test_native.py bin/flint_affine_rref_sanitize --quick \
  --result native_sanitizer_result.json
```

The build fails closed unless `pkg-config` reports FLINT 3.0.1, the headers are
exactly 3.0.1, and the binary resolves `libflint.so.18`. The executable also
checks `flint_version` at runtime.

## Native evidence

- Release adversarial suite: **73/73 passed**. Coverage includes deterministic
  and randomized rectangular systems, rank zero, nullity zero, primes 2,
  61-bit and near-64-bit prime arithmetic, framing/truncation/trailing-data and
  overflow attacks, composite moduli, noncanonical field values, malformed
  preference permutations, zero nonce, inconsistent systems, exact-output
  nonce/schema checks, same-inode protection, and failure-atomic preservation
  of an existing output.
- ASan+UBSan quick suite: **36/36 passed** with abort-on-error enabled.
- Representative structured 672x625 rank-480 test: passed in 0.2201 seconds
  end to end (one process, including binary I/O and internal witnesses).
- Requested deterministic dense CF300-shape benchmark, 672x624 coefficient
  matrix, rank 620/nullity 4, augmented width 625, prime 2147483647:
  417,949/419,328 entries are nonzero (99.6711% density).

| Threads | RREF (s) | Witness construction (s) | Internal verification (s) | Total (s) | Max RSS (KiB) |
|---:|---:|---:|---:|---:|---:|
| 1 | 0.0371 | 0.1257 | 0.1334 | 0.3176 | 24,516 |
| 2 | 0.0236 | 0.0744 | 0.0739 | 0.1966 | 25,052 |
| 4 | 0.0187 | 0.0516 | 0.0367 | 0.1307 | 24,960 |

All three thread counts produced byte-identical output with SHA-256
`1f1b5ca1609d4495d6c88ffb6af8cfd99f8ffd77f534b0a154689b9f6587f73d`.
The deterministic 3,365,072-byte request has SHA-256
`44455794aa70fb89ca609af008ba6fedb1764255a9dab15ef8a33dc04d3a52a3`.

## Pinned hashes

```text
11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd  flint_affine_rref.c
36d596eb59cff13350f3460f007750d916dbd2510381c490a7069bc26bd3ef0a  build.sh
0c66169391647ab0cb9c0e51e9a1cf38ff6a603db5e0451897f635b81a69c6e5  PROTOCOL.md
d0c55ad4c1fc8db42781b7aa7947ea420dc461ee5ddad3cf5c4af55cb735391c  test_native.py
08a68daa1a400eaaf45936c3c21a370d66ca7025ca15159463afeee7c3196f54  benchmark_cf300_shape.py
fe3c89153b7ac538ee82b0f3e3421dd085d38239baaeb8824367f2167d71e896  benchmark_cf300_shape_result.json
f755fc836e502735e6f2960aa1df5b0252aee7a86e0c96718df0fe05abdf80b2  native_test_result.json
155069b6eccd19944d626f46f908c75bc1f37a048cc331f018c64c0e0b9e6557  native_sanitizer_result.json
e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5  bin/flint_affine_rref
64e6fc6eaab1c3979c7151d52ae9f129284fd5450aec4ba95c1d29195e2fbf44  bin/flint_affine_rref_sanitize
```
