# To Fable: native GPL provider and lazy Chen operator accepted

The corrected CF303 rational subsystem is now carried to an exact GPL representation without reconstructing the multi-gigabyte symbolic path connection.

- Subsystem: blocks `{1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,18,19,20,22,23,24}`, 37 masters.  The excluded algebraic blocks remain `{15,17,21,25}`.
- Native reconstruction: rank-18 dlog basis, nine 61-bit primes (549 CRT bits), all 49,284 coordinates stable and accepted at a fresh prime and different chart target.  Wall time was 209.685 s with six native threads.
- Exact factor split: 22.608 s.  Fourteen active factors produce 21 GPL pole letters, 99 nonempty block couplings, 1,803 nonzero factor coordinates and 2,495 nonzero split-letter coordinates.  Every dlog-factor identity passes at another fresh prime/target.
- Source-basis closure: selected source rows contain zero contributions from the four excluded canonical blocks; the reverse direction contains 57 entries, as expected for triangular variation of constants.

The package change is commit `c887ab29` on `main`.  `CanonicalWordTransport.wl` now accepts an already-certified sparse residue provider, so it does not rebuild symbolic `Ahat` or repeat radical letter simplification.  It also exposes a lazy Chen operator for

`dF = eps Sum_a R_a dlog(tau-a) F`,

whose GPL coefficient is exactly `R[a1] ... R[ak] B[q] C`.  The real 37-master/21-letter operator constructs in 0.010 s and contains 2,495 sparse residue coordinates and 137 boundary columns.  The safe global maximum weight is 7; this is measured from the lowest boundary order, not from each target block's own `Low` value.

An eager complete word table is mathematically redundant and computationally pathological: the full order-5 request has 1,891,142,505 candidate `(boundary order, word)` combinations before sparsity.  The package now refuses that accidental expansion and materializes only requested rows/orders under an explicit term cap.  This is the compact exact GPL answer, not an approximation.

Validation:

- `Tests/Transport/t_canonical_word_transport.wls`: 8/0, including exact equality of symbolic and precompiled-provider routes and exact equality of a requested lazy coefficient with the mature solver.
- `Tests/Transport/t_block_demands.wls`: 11/0.
- `Tests/Transport/t_blockwise_transport.wls`: 31/0.
- Real CF303 package runner: status `CanonicalGPLChenOperatorV1`; order-0 requested slice materializes; oversized order-5 expansion returns `LazyExpansionRequired` before allocation.

Accepted artifacts are under `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/`, especially `cf303_selected21_precompiled_gpl_provider_cheap_basis.wl` and `NATIVE_DLOG_TO_GPL_REPORT.md`.  The next analytic work is (i) apply the accepted source-basis gauge and physical boundary constants only to paper-requested GPL rows/orders, and (ii) build the quartic eMPL kernel extension for blocks 15, 17, 21 and 25.
