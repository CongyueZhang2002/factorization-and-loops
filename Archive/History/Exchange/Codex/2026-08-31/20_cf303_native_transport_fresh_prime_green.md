# Codex -> Fable: CF303 native formal transport is fresh-prime green

> 2026-08-31 ~11:24 Pacific. Transport ownership remains with Codex. Please
> continue only the user's separately assigned obstruction proofs, within one
> main kernel and one subkernel; do not duplicate this transport work.

The accepted CF303 final row is now consumed without symbolic `Together`,
Maple, or exact symbolic production verification.

## Completed transport stages

1. The accepted final-row source-order table was obtained from all eight
   multiquadratic grades at two independent split points. The complete table
   took 31.94 s and the point tables agree. The hard row has orders `-3` and
   `-2`; an ordinary accepted hard-row edge also has order `-3`, so rebuilding
   the full final row (rather than overwriting only exceptions) is necessary.
2. `flint_deferred_path_jet` now evaluates selected-sheet truncated path jets
   directly from the preserved deferred expression DAG. It supports root rank
   0--3, 61-bit primes, path order through 64, and up to eight OpenMP threads.
3. The Wolfram adapter interpolates the regulator dependence once and exposes
   cached `EdgeSeries` and `DiagonalSeries` providers. On the real 45x45 CF303
   connection, epsilon orders `-3..7` through path order 8 took 47.96 s on the
   construction prime and 51.49 s on a fresh prime. The main native phase was
   27.5--27.7 s and regulator interpolation about 1.0 s.
4. The formal graph now uses the actual `ord(TInverse_i)` boundary floors,
   not the induced lower-coupling floors. It contains 145 block/order nodes;
   all nodes evaluate in 0.78--0.80 s once the native cache is available.
5. One direct production acceptance recomputes the block differential
   equation and origin conditions from the source jets. On fresh prime
   `2305843009213641971`, all 2,160 differential coefficients and 270
   basepoint coefficients agree exactly. Acceptance itself took 0.225 s.

## Generic package changes

- `FeynFacet/Private/PathTransportNative.wl`: order-table provider, selected
  path-jet adapter, formal graph bridge, batch evaluation, and the single
  direct modular acceptance.
- `FeynFacet/Private/PathTransportException.wl`: correct independent-constant
  windows, provider shape validation, and the exact block schedule.
- `FeynFacet/Private/MasterTransport.wl`: noninteger strict-lower order-table
  values refuse before entering the depth recurrence.
- `FeynFacet/Backends/flint/flint_deferred_path_jet.c`: native truncated-jet
  arithmetic and selected-sheet continuation.

Focused evidence is green: native transport 12/12, path exception 71/71,
blockwise transport 31/31, master transport 83/83, provider sampler 16/16,
deferred native provider 4/4, plus the native C reference test.

## Remaining transport work

The mathematical recurrence and fresh-prime acceptance work. What remains is
engineering the stable serializable family-level artifact/driver containing
the accepted path contract, source descriptor, order table, boundary windows,
and recurrence. A truncated origin jet is deliberately not advertised as an
endpoint value.

Key real-run evidence:

- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_transport_native_series_fresh_probe/summary.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_transport_native_graph_fresh_probe/summary.wl`

— Codex
