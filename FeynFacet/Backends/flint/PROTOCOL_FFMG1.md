# FFMG1 exact multivariate GCD/cofactor protocol

`FFMG1` is the text exchange protocol for `flint_mpoly_gcd`, pinned to FLINT
3.0.1. The command line is:

```text
flint_mpoly_gcd NUMERATOR.ffmg DIVISOR.ffmg QUOTIENT.ffmg GCD.ffmg [THREADS]
```

`THREADS` is an optional decimal integer from 1 through 64 and defaults to 1.
The quotient and GCD output paths must differ.

## Input `FFMG1P1`

Both input files encode one polynomial in `Z[x0,...,x(n-1)]`. The first line
is tab-separated:

```text
FFMG1P1<TAB>nvars<TAB>nrows
```

It is followed by exactly `nrows` lines. Each is:

```text
e0<TAB>...<TAB>e(n-1)<TAB>coefficient
```

`nvars` is from 1 through 1024. Exponents and counts are unsigned decimal integers;
coefficients are nonzero signed decimal integers. Whitespace, quoted numbers,
missing fields, extra fields, and trailing lines are rejected. Row order need
not be canonical and duplicate monomials are combined exactly. The divisor
must remain nonzero after combination. Both inputs must declare the same
variable count.

## Outputs `FFMG1Q1` and `FFMG1G1`

On success, the quotient file begins with `FFMG1Q1` and contains
`numerator/gcd`; the GCD file begins with `FFMG1G1`. Their remaining header
fields and sparse rows have the input shape. Rows are canonical FLINT lexicographic
order and coefficients are exact decimal integers. Each output is written to a
same-directory temporary file and renamed over its destination.

The GCD is FLINT's normalized `fmpz_mpoly_gcd` result. Callers that map it back
to pre-existing factor keys must preserve its possible numeric unit. The
backend performs the exact numerator cofactor division before writing output.

## Exit status

- `0`: GCD and exact numerator cofactor committed.
- `2`: usage error or incompatible FLINT runtime.
- `3`: input/allocation I/O failure.
- `4`: malformed protocol or zero divisor.
- `5`: GCD or exact cofactor division failure.
- `6`: output commit failure.

On success, stdout contains one JSON timing record. Diagnostics go to stderr.
No output is authoritative unless the exit status is zero.
