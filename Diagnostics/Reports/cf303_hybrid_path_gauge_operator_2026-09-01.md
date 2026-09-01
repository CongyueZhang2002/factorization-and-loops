# CF303 hybrid final-row path gauge — 2026-09-01

## Current status

The old `cf303_hybrid90_circuit_path_gauge_operator.json` is only a provisional
composite-input manifest.  It does not run the 88-entry baseline recurrence,
build `F=G+H.L`, or apply `T25`, and it must not be cited as an accepted
operator.

The all-at-once characteristic-zero baseline recurrence is not viable, but
its deferred exact-circuit replacement is now implemented and accepted.  The
accepted object is
`cf303_hybrid_baseline_modular_circuit_manifest.json`; it keeps the original
exact leaves and sealed Hermite/recurrence operations rather than expanded
`H/K` matrices.  It is not a materialized GPL/eMPL paper result.

The completed route is:

1. merge the exact 76-entry transfer and the accepted block 2/11/14/18
   censuses (12 entries), then add two explicit zero block-1 placeholders;
2. encode the complete `2x43`, orders `-3..4` recurrence as sealed exact
   arithmetic/Hermite nodes;
3. specialize the leaves first and execute the circuit over the minimal q7
   split field (`F_q` or `F_q2`), never expanding characteristic-zero `H/K`;
4. add the separately accepted block-1 `delta H/delta K` circuit in column 1;
5. replay the merged `H` and every demanded new cross-Hermite `K` vector
   through `T25` orders `0..2`.

## Mathematical split

In the accepted 43-master source operator, master 1 is source position 1.
The support audit finds no source-residue coordinate `{1,j}` with `j>1`, so a
`delta H` supported in column 1 remains in column 1 and its recurrence uses
only `S11`.  Conversely, column 1 of `S` has 42 nonzero source-row positions.
Therefore the baseline column 1 contains real feed-down and must be retained:

`H_full[:,1] = H_baseline[:,1] + delta H_block1[:,1]`.

Replacing the baseline column by the block-1 circuit would be wrong.

## Circuit resolver

`cf303_block1_circuit_point_resolver.py` resolves all 16 block-1 records at a
requested `(q,p)`:

- rational `H/K` comes from literal evaluation of the accepted 138-node DAG;
- rational `K` is emitted as one lazy composite kernel per `(order,row)`, which
  resolves to `Sum_i N_i GPLFactor[D,i]` only when a word is requested;
- elliptic `K` is polynomial-divided by its square-free denominator; the
  proper part becomes `E4Factor` terms, while the quotient is checked against
  the independently lifted three-component cohomology profile and mapped to
  `E4Omega0`, `E4OmegaInf`, and `E4Eta2`.

The composite-kernel encoding adds only 32 incoming circuit labels (16
rational plus 16 elliptic), instead of 384 per-power labels, so lazy word
enumeration does not branch on numerator powers prematurely.

Measured q7 resolution took 3.45 seconds at `p=3` and 3.53 seconds at
`p=239/47` (8.0 seconds total including two process startups).  Each point
matched 1,878 rational source-replay coefficients and all
16 elliptic quotient/cohomology identities.  A common nonzero rational probe
`(-2,row1)` resolves to 21 `GPLFactor` terms; a common nonzero elliptic probe
`(-1,row1)` resolves to five proper `E4Factor` terms plus two nonzero Omega
terms at each point.

## Baseline run

Preparation measurements:

- 90-shaped exact transfer merge: 1.8 seconds, 12 MB output;
- exact source/target `D/S` export: 32.25 seconds, 413 source-form records and
  4 target-form records;
- required dimensions: 43 source masters, 287 source boundary columns, 293
  final boundary columns, `H` window `-3..4`, and `T25` orders `0..2`.

The baseline command was:

```bash
python3 Diagnostics/Scripts/cf303_run_hybrid_baseline_path_gauge.py --run
```

It ran a saved generated Maple artifact bound to distinct hybrid input/output
paths and never swapped or overwrote canonical runtime files.  The wrapper ran
for 3:58:18.  The Maple kernel was still CPU-active at the last sample, but its
late exact recurrence grew from about 22.2 GiB RSS to 36.0 GiB RSS in a few
minutes; available memory fell below 9 GiB.  The coordinator issued a memory-
safety stop.  Maple then reported `fatal error, lost connection to kernel`
(Maple status 5, wrapper status 1).

This was not an OOM kill, an identity failure, or a mathematical obstruction.
It happened before the output files were opened, so neither
`cf303_hybrid_baseline_finite_path_gauge.maple` nor its Wolfram counterpart
exists.  The exact chronology and KiB samples are preserved in
`cf303_hybrid_baseline_exact_failure_telemetry.json`.

## Modular replacement — accepted

`cf303_hybrid_baseline_modular_circuit.py` implements the replacement without
starting Wolfram or Maple:

- the exact 76-entry transfer, four accepted exception censuses, `D/S`, and
  `T25` remain provenance-bearing leaves;
- the twelve very large nonzero exception primitives are parsed while their
  integer and `p` coefficients are reduced modulo q, so the expanded rational
  coefficients never exist in characteristic zero;
- source-letter `D/S` leaves are first added at their matrix coordinate.  At
  `p=239/47` their roots do not all split over q, so the evaluator uses the
  minimal `F_q2=F_q[omega]/(omega^2-2)` image.  Hermite reduction is linear in
  its two base-field components;
- the only new cross support is 14 coordinates at each order `-2..4` (zero at
  `-3`).  Each point performs 98 rational cross reductions, zero elliptic
  cross reductions, and produces 49 nonzero cross-`K` vectors.  Maximum `H`
  numerator/denominator degrees are 38/37;
- the incoming accepted residue leaves stay lazy.  The newly computed cross
  remainders are retained as `K` circuit nodes and replayed through `T25`, not
  discarded after constructing `H`.

Acceptance at each of q7 `p=3` and `p=239/47` is:

- 688/688 recurrence coordinates;
- 688/688 `H(1/2)=0` coordinates;
- 2,408 merged-`H` T25 scalar-channel comparisons;
- 672 demanded cross-`K` T25 scalar-channel comparisons.

The two-point totals are therefore 1,376 recurrence, 1,376 basepoint, and
6,160 T25 comparisons.  The exact object is the provenance-sealed circuit;
these images are its evaluator and acceptance evidence, not a modular oracle
substituted for an exact result.

Measured internal phase times were:

| p image | D/S specialization | primitive specialization | recurrence | total |
| --- | ---: | ---: | ---: | ---: |
| `3` | 21.08 s | 5.32 s | 4.05 s | 31.43 s |
| `239/47` | 27.36 s | 6.06 s | 4.32 s | 38.77 s |

The final two-point command took 76.03 s wall and peaked at 128,452 KiB RSS.
The only material remaining bottleneck is exact `D/S` parsing and conjugate-
root specialization; the actual eight-order recurrence is about four seconds
per image.  This replaces the terminated four-hour, 36-GiB exact run and
requires no cross-prime lift of expanded `H/K`.

## Stale-artifact quarantine

`cf303_final45_low_order_materialization.wl` was built from the stale
76-entry transfer.  It is not an input to the hybrid builder and must not be
used as evidence for the 90-entry result.

## New implementation files

- `Diagnostics/Scripts/cf303_prepare_hybrid_baseline_transfer.mpl`
- `Diagnostics/Scripts/cf303_export_hybrid_baseline_path_inputs.wls`
- `Diagnostics/Scripts/cf303_run_hybrid_baseline_path_gauge.py`
- `Diagnostics/Scripts/cf303_block1_circuit_point_resolver.py`
- `Diagnostics/Scripts/cf303_hybrid_circuit_path_gauge_adapter.wl`
- `Diagnostics/Scripts/cf303_build_final_hybrid_circuit_operator.wls`
- `Diagnostics/Scripts/cf303_hybrid_baseline_modular_circuit.py`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_hybrid_baseline_modular_q7_p3d1.json`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_hybrid_baseline_modular_q7_p239d47.json`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_hybrid_baseline_modular_circuit_manifest.json`

No package source is modified.
