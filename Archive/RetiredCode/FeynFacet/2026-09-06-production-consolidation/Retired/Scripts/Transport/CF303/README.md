# CF303 accepted transport to physical-boundary adapter

`CF303PhysicalBoundaryCampaign.wl` imports the accepted lazy CF303 operator as
one 43+2 object.  It does not rebuild or lift dense characteristic-zero `H/K`.
The assembled inventory is:

- 43 source rows in the accepted `OriginalRows` order and final rows 44, 45;
- 287 source boundary coordinates plus six final homogeneous coordinates;
- 90 incoming entries: 76 ordinary leaves, 12 accepted exception leaves, and
  two block-1 circuit entries;
- path-gauge orders -3 through 4 and physical `T25` orders 0 through 2;
- the existing deferred point-provider ABI from the accepted circuit.

The file `cf303_final45_low_order_materialization.wl` is explicitly excluded.
It is the obsolete result made from only the first 76 entries.  The accepted
76-entry transfer remains a legitimate leaf inside the 76+12+2 circuit; it is
not used by itself as a final result.

## Physical endpoint status

The stored operator transports along the regular second-axis path
`z: 1/2 -> uFinal`.  Neither endpoint is identified as a singular physical
boundary.  Process conventions give the physical chamber
`v>0, w>0, v+w<1` and the standard soft stratum `s=1-v-w -> 0+`, but CF303 has
no record selecting that stratum over `v->0`, `w->0`, or a corner.

For the recorded `Kallen2Bilinear115` chart,

```
a = (4 p (1-p) - 2 u)/(u^2 + 4 p (1-p)),
v = -a p,
w = (1-a)(1-p),
s = 1-v-w = p+a.
```

The soft stratum has two exact chart preimages,
`u=2p` and `u=2(1-p^2)/p`.  The physical path selects `u=2p` first on
`0<p<1/Sqrt[2]`, where the continued bilinear root is `1-2p^2>0`.  With the
inward coordinate `rho=2p-u`,
`s/rho=(1-2p^2)/(2p)>0`.  The same sheet is then continued in `p` with the
physical `+i0` prescription; the root crosses zero at `p=1/Sqrt[2]` rather
than being silently replaced by its absolute value.  The alternative
preimage remains recorded for comparison.

The other missing inputs are mathematical, not implementation gaps:

- specialization of the accepted 43-row assembly map and 2x2 `T25` gauge on
  the selected singular sheet;
- CF303 Frobenius mode realizations and their valuations/log levels;
- exact or explicitly formal GPL/elliptic period series for those modes.

Until they are supplied, the adapter returns
`LazyTransportCampaignNeedsPhysicalBoundaryData` and a package-shaped
`Stage3NeedsLedger`.  Passing its incomplete mode-map record to
`BuildTransportBoundaryVector` produces the intended typed refusal while
preserving the ledger.
