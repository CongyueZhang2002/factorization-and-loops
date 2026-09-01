# CF303 hybrid final-row path gauge — 2026-09-01

## Current status

The old `cf303_hybrid90_circuit_path_gauge_operator.json` is only a provisional
composite-input manifest.  It does not run the 88-entry baseline recurrence,
build `F=G+H.L`, or apply `T25`, and it must not be cited as an accepted
operator.

The replacement components are implemented through the final lazy adapter,
but the all-at-once characteristic-zero baseline recurrence is not viable.
The exact Maple run was stopped for memory safety before serialization, so no
baseline `H/K` artifact and no accepted final operator were produced:

1. merge the exact 76-entry transfer and the accepted block 2/11/14/18
   censuses (12 entries), then add two explicit zero block-1 placeholders;
2. attempted the unchanged exact finite path-gauge recurrence on that
   90-shaped baseline;
3. add the separately accepted block-1 `delta H/delta K` circuit in column 1;
4. build lazy `G`, `F=G+H.L`, and `I=T25.F` coefficient accessors;
5. the additive merge and physical-gauge replay remain blocked on replacing
   step 2 with the deferred modular circuit described below.

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

## Modular replacement

Do not rerun or try to reconstruct the expanded characteristic-zero `H/K`
matrices.  Extend the already accepted block-1 circuit ABI to the 88-entry
baseline:

1. keep the exact 76-entry transfer, the four accepted exception censuses,
   exact `D/S`, and `T25` as provenance-bearing leaves;
2. seal the recurrence operations—addition, multiplication, derivative,
   deterministic Hermite primitive/remainder, and `H(1/2)=0`—as exact circuit
   nodes without expanding their outputs;
3. at evaluation time, specialize the leaves first at `(q,p)` and execute the
   complete sparse `2x43`, orders `-3..4` recurrence with the existing 64-bit
   modular rational/quartic Hermite machinery;
4. merge the two accepted block-1 circuit entries additively, and keep the
   GPL/E4 kernels lazy through the existing physical-word accessor;
5. accept by direct point replay at q7, `p=3` and `p=239/47`: 688 recurrence
   coordinates and 688 basepoint values per point, followed by `T25` orders
   `0..2` and target orders `-4..2`.

The exact deliverable is the provenance-sealed arithmetic circuit.  The
finite-field images are its evaluator and acceptance evidence, not a modular
oracle substituted for an exact object.  This route moves the cancellations
and Hermite reductions before coefficient growth, reuses the measured block-1
point engine (16 outputs in 0.30 seconds at one fixed point), and avoids both
the 36-GiB exact intermediate and cross-prime lifting of expanded `H/K`.

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

No package source is modified.
