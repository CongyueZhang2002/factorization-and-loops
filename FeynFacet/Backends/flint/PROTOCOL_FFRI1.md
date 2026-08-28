# FFRI1 finite-field regulator interpolation

`flint_regulator_interpolate` performs the coordinatewise rational
interpolation and synchronized held-out loop used by the direct modular
solver. Invocation is:

```text
flint_regulator_interpolate INPUT.bin OUTPUT.bin [THREADS]
flint_regulator_interpolate --self-test
```

`THREADS` is an integer from 1 through 8. All protocol words are unsigned
64-bit little-endian. Field elements are canonical residues in `[0,p)`, with
`5 <= p < 2^63` prime.

## FFRI1V1 request

The request contains:

1. Eight-byte magic `FFRI1V1\0`.
2. Seven words: prime `p`, sample count `S`, coordinate count `C`, initial
   construction count, held-out count, maximum total degree, mode.
3. `S` sample abscissae.
4. An `S*C` value matrix in sample-major order.
5. In fixed-profile mode, `C` degree pairs `(numerator, denominator)`.

Mode `0` discovers the minimal total degree, trying every split and retaining
all distinct reduced candidates. Mode `1` solves only the supplied split and
requires its reduced degrees to agree exactly. The pair `(UINT64_MAX,0)`
encodes the zero profile `(-Infinity,0)`.

Discovery consumes held-outs sequentially. A point is promoted into the global
construction set only when it empties at least one coordinate's candidate set;
the held-out pass count is then reset and failed coordinates are refit. A point
which leaves every candidate set nonempty remains validation evidence. The
result is accepted only when every coordinate has one survivor and those
survivors have passed the requested number of points since the last promotion.
This preserves disjoint held-out certification without overshooting
construction by a whole held-out batch. Coordinates within a point step are
independent OpenMP jobs.

For each coordinate, discovery retains the first total degree not yet ruled
out. Once every candidate through degree `d` fails a promoted point, the
growing construction set cannot admit any of those degrees later, so refits
start at `d+1` rather than rescanning from zero. This changes only search work;
candidate ordering and the response are unchanged.

## FFRI1X1 response

The response contains:

1. Eight-byte magic `FFRI1X1\0`.
2. Ten words: prime, input `S`, input `C`, mode, global status, reason,
   consumed sample count, final construction count, required additional
   sample count, actual thread count.
3. One variable-length record per coordinate: status, numerator degree,
   denominator degree, consumed sample count, numerator coefficient count,
   denominator coefficient count, then ascending numerator coefficients and
   ascending denominator coefficients.

`UINT64_MAX` encodes a numerator degree of `-Infinity`. Coefficients are emitted
only after global acceptance.

Global statuses are `0 Accepted`, `1 MoreSamplesRequired`, `2 InternalFailure`.
Reasons are `0 None`, `1 GrowRequired`, `2 HeldOutRound`, `3 Internal`,
`4 MaximumDegreeExceeded`. Reason 4 has required-additional count zero:
construction has disproved every admitted total degree, so more samples cannot
change the result without raising the configured bound.
Coordinate statuses are `0 Accepted`, `1 Unresolved`, `2 HeldOutShortfall`,
`3 Ambiguous`, `4 PeerNotTerminal`, `5 InternalFailure`.

The program prints one JSON timing line. It carries no hashes, nonces, package
records, deadlines, or persistence state.
