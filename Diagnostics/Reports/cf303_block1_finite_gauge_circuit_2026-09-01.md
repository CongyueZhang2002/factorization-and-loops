# CF303 (25,1) finite-gauge circuit handoff — 2026-09-01

## Outcome

The block-1 finite path gauge is represented exactly without expanding its
high-height bivariate coefficients.  The result is a 138-node arithmetic DAG
over the original 32,517,228-byte exact deferred input.  It exposes all 16
records (two rows, epsilon orders -3 through 4), both `delta H` and transformed
`delta K`, and a deferred `GPLFactor` kernel view of every rational remainder.

The circuit is a block-1 result, not a monolithic final-row artifact.  Its
assembly contract is:

- use the 76-entry general transfer plus the disjoint 2/11/14/18 exception
  components (2+2+4+4 entries) as a composite 88-entry baseline;
- append the two block-1 entries supplied by the circuit, giving 90 entries;
- keep `GPLFactor -> GPLPole` root expansion deferred until physical words are
  requested.

## Mathematical result

The rational correction obeys

`delta K_n = delta B_n + D delta H_(n-1) - delta H_(n-1) S11 - d delta H_n`

with `delta H_n(1/2)=0`, for `n=-3,...,4`.  The exact rationalized source
diagonal is

`S11 = -4 (u^2 + 4 p (p-1) (1+u)) /
 ((u-2p) (p u + 2 p^2 - 2) (u^2 - 4 p (p-1)))`.

The source boundary is required through order 5.  For final target order 2,
block-1 boundary demand uses `H` orders -3 through 2, while the recurrence is
run through order 4.

The elliptic source is also exact: 238 exact p profiles were isolated from the
q1/q2 reconstruction.  Both elliptic primitive channels vanish identically.
Because `D` and `S11` are rational, the channels decouple, so
`H_n^elliptic=0`, the `Y0` base constant is zero, and `K_n^elliptic` is exactly
the source elliptic remainder/cohomology channel.

## Why a circuit was necessary

At fixed q1,p=3, the full 16-record recurrence costs 0.298 seconds after input
loading and passes every Hermite identity and basepoint normalization.  The
first nontrivial record (`n=-2`, row 1) has p-degree as high as 203.  Its
q1--q6 expanded coefficient lift resolves only 6,839 of 12,643 coefficients;
5,804 remain above the 305-bit modulus.  Expanding those coefficients is thus
the wrong exact representation.  The arithmetic DAG preserves the exact AST
and performs the cancellations only when evaluated.

## Acceptance evidence

- representative 19-node circuit: 744/744 comparisons against q1--q6 profiles;
- full rational circuit: 15,024/15,024 coefficient comparisons across q1--q6
  and q7 at `p=3` plus q7 at `p=239/47`;
- exact elliptic source: 476/476 fresh-q7 coefficient comparisons at those two
  p points;
- literal full-DAG evaluation: 0.31--0.37 seconds per `(q,p)` after context
  loading;
- rational `K` sample: 318 nonzero `GPLFactor` terms at q1,p=3.

## Artifacts

- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block1_full_exact_circuit.json`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block1_full_exact_circuit_validation.json`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block1_exact_elliptic_source.json`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block1_full_circuit_q1_p3_gpl_kernels.json`

## Reproduction

```bash
python3 Diagnostics/Scripts/cf303_block1_exact_elliptic_source.py
python3 Diagnostics/Scripts/cf303_block1_full_exact_circuit.py
```

No package source was modified and no symbolic Wolfram equality was used for
production acceptance.
