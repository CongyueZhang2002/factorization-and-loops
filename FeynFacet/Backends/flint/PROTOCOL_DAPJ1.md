# DAPJ1: deferred-AST truncated path jets

`flint_deferred_path_jet` evaluates the complete lexicographic record rectangle
of a preserved `BlockEquationDeferredV1` preparation in

`F_p[tau] / tau^(T + 1)`.

It selects one authenticated multiquadratic path sheet.  Unlike `DAGO1V1`, it
does not enumerate deck signs or project onto the root basis.  Run it once per
desired sheet.

## Invocation

```text
flint_deferred_path_jet INPUT.wl REQUEST.txt OUTPUT.bin [--threads N]
```

`1 <= N <= 8`.  OpenMP partitions independent regulator images; it does not
parallelize coefficients within one truncated series.

## Request

The request is ASCII, line oriented, and fail closed:

```text
DeferredPathJetRequestV1
prime P
variables X Y EPS
order T
rank R
root DELTA_1_INPUTFORM
...
root DELTA_R_INPUTFORM
epsilon_count N
epsilon E_1
...
epsilon E_N
x_jet X_0 X_1 ... X_T
y_jet Y_0 Y_1 ... Y_T
delta_jet D_1,0 D_1,1 ... D_1,T
root_jet  R_1,0 R_1,1 ... R_1,T
...
delta_jet D_R,0 D_R,1 ... D_R,T
root_jet  R_R,0 R_R,1 ... R_R,T
```

Constraints:

- `P` is a prime with `3 < P < 2^63` (61-bit primes are supported).
- `0 <= T <= 64`, `0 <= R <= 3`, and `1 <= N <= 4096`.
- Every numeric field is the canonical residue in `[0,P)`.
- `X`, `Y`, and `EPS` are distinct symbol names. Qualified Wolfram contexts
  in the preserved expressions are matched by their final symbol component.
- `DELTA_i_INPUTFORM` is the exact normalized root-square expression admitted
  in `Sqrt[...]` and odd half powers.

Before evaluating any record, the executable proves in the truncated ring
that `root_jet_i^2 == delta_jet_i`, requires a nonzero root constant, and
evaluates every declared `DELTA_i_INPUTFORM` at every regulator image to prove
that it equals `delta_jet_i`.  The supplied sign therefore chooses the sheet;
no modular square-root convention is inferred.

The accepted expression grammar is the same fail-closed InputForm subset as
`flint_deferred_ast_eval`: integers, the three declared symbols, `+`, `-`, `*`,
`/`, signed integer powers, parentheses, and declared square roots/odd
half-powers. Division and negative powers require a nonzero constant term.

## Output

All integers are little-endian unsigned 64-bit values:

```text
char magic[8] = "DAPJ1V1\0"
uint64 status
uint64 prime
uint64 order
uint64 rank
uint64 epsilonCount
uint64 recordCount
uint64 termCount
uint64 uniqueExpressionCount
uint64 dimension0
uint64 dimension1
uint64 dimension2
uint64 parseNanoseconds
uint64 evaluationNanoseconds

repeat recordCount times:
  uint64 target[3]
  uint64 channel[epsilonCount][order + 1]
```

For each regulator image, coefficients are ordered by increasing power of
`tau`. On failure the magic and typed nonzero status are still written; the 12
header fields are zero except `dimension0`/`dimension1`, which carry a known
failing root/expression index and byte/image offset. Status codes are shared
with DAGO1V1 (`RequestSchema=3`, `UnsupportedExpression=8`,
`SingularImage=10`, `RootValueMismatch=11`, `RootSquareMismatch=12`, etc.).

The existing `DAGO1V1` and `DAGO2V1` request and output ABIs are not changed.
