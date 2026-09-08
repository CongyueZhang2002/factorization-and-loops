# CF303 inherited lower-family soft jets

Date: 2026-09-03

## Result

`build_cf303_inherited_lower_soft_jets.wls` constructs only the canonical
source rows that the accepted CF303 endpoint operator can see.  It does not
materialize any CF303 connection or a `2 x 43` endpoint map.  The output is

```text
Artifacts/CF303InheritedLowerSoftJets.wl
```

and contains the sparse exact coefficients in

```text
F_selected(rho,eps) = H_selected(rho,eps)
                      rho^(eps R_active) c_active(eps,p).
```

The selected rows are already the seven CF303 canonical source coordinates:
the lower-family `TTotalInverse` rows are one-sparse and agree with the
accepted CF303 source normalization on the soft chart.  Consequently no
physical-to-canonical matrix is left to apply after this artifact.

Only thirteen active canonical columns survive closure under the endpoint
residue:

| family | selected source rows | active columns | coefficient window | build |
|---|---:|---:|---:|---:|
| CF1 | `{1}` | `{1}` | `rho^0..2`, `eps^0..5` | 0.04 s |
| CF12 | `{6}` | `{1,6}` | `rho^0..2`, `eps^0..5` | 1.29 s |
| CF21 | `{4}` | `{1,4}` | `rho^0..2`, `eps^0..5` | 2.65 s |
| CF199 | `{8,9}` | `{1,7,8,9}` | `rho^0..2`, `eps^0..6` | 1.51 s |
| CF53 | `{11,12}` | `{1,10,11,12}` | `rho^0..2`, `eps^0..6` | 10.65 s |

The measured total is 16.14 seconds.  All coefficients are rational GPL
data.  The extra `eps^6` layer for CF199 and CF53 is necessary: their
boundary series begins at `eps^-1`, so source order five can receive
`H_6 c_-1`.  A `rho^2` jet is sufficient because the projected physical
operator has at most a double pole.

The builder rejects a family if the active columns differ from the stated
closure or if that closure is not invariant under the exact normal residue.
It stores the restricted residue, sparse prefactor coefficients, endpoint
chart, and column roles; the non-rational factor `rho^(eps R_active)` remains
explicit rather than being truncated or silently discarded.

## What this closes

Together with `cf303_inherited_soft_projection_point.py`, the endpoint data
needed before reconstruction are now available with the correct minimal
shape:

- 92 projected `W` epsilon coordinates rather than 860 raw coordinates;
- local powers `rho^-2`, `rho^-1`, and `rho^0` at an arbitrary accepted
  modular point in about 2.6 seconds;
- exact lower-source Frobenius prefactors through the complete demanded
  `rho` and `eps` window in about 16 seconds.

The two realization-local PID-9 zero-mode series remain honest formal
Stage-3 inputs.  They are GPL periods, not elliptic periods.

## First remaining datum

The first concrete producer gap is regular observable-order coverage, not
another endpoint matrix.  The accepted observable transports need one more
targeted physical epsilon order for:

```text
CF12 row 4 : order 2
CF199 row 1: order 2
CF199 row 2: order 3
CF53 row 4 : order 2
CF53 row 5 : order 3
```

CF1 and CF21 already cover their demanded orders.  After those extensions,
the remaining unevaluated quantities are precisely the separate CF199 and
CF53 PID-9 coefficient series recorded in the Stage-3 needs ledger; class
sharing alone does not identify them.
