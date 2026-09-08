# CF300 current `(12,9)` pair-chart solution

`solution.wxf` is the exact gauge returned on 2026-08-28 after pulling the
current authenticated deferred strip to the chart that rationalizes active
roots `{1,3}`.

The production solve took 166.90 seconds and returned a 2-by-2 gauge with 13
dlog residues.  Exact dlog reconstruction and every exact Pfaffian residual
passed.  Three construction primes passed held-out tests and the complete
residual vanished at unseen prime `2147483399`.

`summary.wl` is the compact machine-readable record.  The detailed diagnosis,
timings, package corrections, and instructions to Fable are in
`../02_fresh_points_and_active_subfield_resolution.md`.
