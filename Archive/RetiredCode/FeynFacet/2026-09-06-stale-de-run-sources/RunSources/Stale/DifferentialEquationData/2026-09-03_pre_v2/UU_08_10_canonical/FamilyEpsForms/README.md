# Family eps-forms (stage 2, off-diagonal cleanup)

Produced by `Scripts/family_epsform.wls`, one KernelPool mission per family.
One record `family_epsform_<family>.wl` per family; families whose frame is
the source `(v,w)` additionally carry `_xyview.wl`, the same record with the
two free symbols renamed `v -> x, w -> y`, so that
`Scripts/epsform_offdiag_cf230_payoff.wls` (which transports in `{x,y}`) runs
on them unchanged.

**Coverage: 28 of the 38 families that assemble today.** The other 10 were
dequeued at 02:21 so the production transport sweep could take the pool first:
CF12, CF20, CF98, CF199, CF209, CF211, CF258, CF264 have no record and no purity
measurement; CF217 and CF230 have their purity MEASURED (in the mission logs) but
their runs were aborted before a record was written. CF230's purity reproduces
the recorded 2026-08-17 measurement exactly -- 5 non-pure of 18 coupling pairs,
tau-poles to order 3, a polynomial part, and the same eps-deformed locus
`q = -2 eps - 3(1+eps)(x+y) + (6+8 eps) x y`.

## What a record certifies

A family is ACCEPTED only if THE GATE passes exactly, on the ORIGINAL
(permuted) connections pushed through `T_total = diag(T_i) . S`:

1. `Ahat' = T^-1 A0 T - T^-1 dT` has `Ahat'/eps` eps-free entrywise;
2. every entry is a sum of CONSTANT matrices times dlog of EPS-FREE letters --
   residues free of x, y and eps, equal between the two directions, and the
   dlog reconstruction exact entrywise in BOTH variables (this also excludes
   any polynomial part);
3. the eps-form is flat;
4. `S` is block lower triangular with (x,y)-free diagonal blocks;
5. `T_total . T_total^-1 == 1` exactly, both ways.

A CANONICA/Libra return SHAPE is never a criterion. Each record carries the
thirteen measured gate flags under `"Gate"`.

**The coupling-dlog property is no longer an assumption.** Every record carries
`"Purity"`: the exact decomposition of every coupling entry per (block pair,
eps-order) on the transport path AND in each frame variable separately (pole
orders, polynomial part, tau-free numerators, eps-dependent denominators). The
reviewers' open item -- state the coupling-dlog assumption as a certificate
part -- is discharged per family by that field plus gate condition 2.

Measured here and worth stating plainly: **coupling purity is NECESSARY but
NOT SUFFICIENT.** Ten of the families below have ZERO non-pure couplings and
were still not family eps-forms as assembled -- their couplings sit at eps^0
rather than eps^1, and only the eps-only finish (M3) was missing.

## Consuming a record (the map back to the original masters)

Everything in a record is indexed in the PERMUTED (DAG) basis.

- `Perm[[k]]` is the ORIGINAL row carried by permuted index k, so the original
  system in this basis is `A0 = Av[[Perm, Perm]]`. It equals `Flatten[Blocks]`
  (`MasterTransport.wl:1261`), and `Blocks` is already topologically ordered
  (`blocks = blocks[[order]]`, :1259). **Consistency check:**
  `Length /@ Ranges === Length /@ Blocks` must hold. It fails for the
  pre-driver `family_epsform_CF230_offdiag_2026-08-17.wl`, whose `Blocks` is in
  class-assignment FILE order -- for that artifact `Flatten[Blocks]` is NOT the
  permutation and its `Classes` is mislabelled the same way. (`Perm` is stored
  explicitly by the driver from 02:25; records written before then carry a
  correct `Blocks` but no `Perm` key, and `Classes` in those is in file order.)
- `TTotal = TBlockDiagonal . S = diag(T_i) . S` and
  `EpsFormX = TTotal^-1 . A0x . TTotal - TTotal^-1 d_x TTotal`, so the map back
  is **`I = TTotal . F`** with `F` solving the eps-form.
- `S` is block lower triangular with (x,y)-free but **eps-DEPENDENT** diagonal
  blocks (Lee's factor-out-eps step; `Gate["SUnipotent"]` records whether they
  are the identity). `TTotal` is therefore eps-Laurent with a per-block grading:
  measured `CF3  S = diag(eps, 1, eps^-2)`,
  `CF27 S = diag(eps^3, 1, eps^2, eps, 1, 1, 1, 1)` times units. **`I` at eps^n
  needs `F` at eps^(n - min)** where `min` is the lowest eps order of `TTotal`,
  so a sweep must carry `F` that deep and regrade.
- `Frame`/`Variables` say which system `A0` is: `SourceVW` means `(v,w)`;
  `Chart` means the connection PULLED BACK to `v = x y, w = (1-x)(1-y)` in
  `{x,y}` -- comparing a chart record against the `(v,w)` differential equation
  fails at every order.
- The regulator is stored as ``Global`eps``. Normalize by `SymbolName` with an
  EXPLICIT rule list before use.

## Cleanup mechanisms

| tag | mechanism | cost class |
|---|---|---|
| M1 | closed-form strip of the eps-DEPENDENT apparent locus (`N = M/q^(k-1)`, M read off the leading pole, `d_var q` inverted mod q) | seconds |
| M2 | closed-form Moser/Fuchs pole reduction at the ordinary eps-FREE letters (Sylvester operator `(k-1) + eps(R_i - R_j)`, forced right-to-left column order) | seconds to ~2 min |
| M3 | CANONICA `TransformDlogToEpsForm`, an eps-ONLY transformation, once the connection is dlog with (x,y)-free residues | 0.05-42 s |
| M4 | CANONICA off-diagonal recursion driven subsector by subsector with per-subsector checkpoints, ansatz degrees escalated (0,0) -> (1,0) -> (1,1) -> (2,1) | minutes to ~45 min |

M3 is the workhorse, not M4: 9 of the 16 accepted families needed M3 alone.
No accepted family below needed M4.

## Ledger

`couplings` = live off-diagonal (block pair) couplings on the transport path;
`non-pure` = how many of them are NOT pure dlog with tau-free constant residues
at some eps-order. `cleanup` is the wall time of M1+M2+M3+M4 only (assembly,
purity measurement and gates are excluded and are in `total`). `payoff` is the
block-wise transport `Total` of `epsform_offdiag_cf230_payoff.wls` at orders
{0,1} on the record; only 5 have run so far -- the remaining 11 payoff missions
are queued behind the production sweep. All 5 measured are 0.014-0.144 s, against
the pre-cleanup baseline for CF230 block 6 alone of 151 s at eps^-2 and 1568 s at
eps^-1.

| family | frame | dim | blocks | couplings | non-pure | mechanism | cleanup s | total s | gate | letters | payoff Total s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| CF1 | SourceVW | 2 | 2 | 1 | 0 | M3 | 0.0 | 0.1 | PASSED | 3 | 0.013607 |
| CF429 | SourceVW | 2 | 2 | 0 | 0 | none | 0.0 | 0.0 | PASSED | 1 | 0.033507 |
| CF3 | SourceVW | 3 | 3 | 2 | 0 | M3 | 0.1 | 0.2 | PASSED | 3 | 0.055417 |
| CF2 | SourceVW | 4 | 3 | 3 | 1 | M2+M3 | 0.2 | 0.5 | PASSED | 4 | 0.096868 |
| CF360 | SourceVW | 4 | 3 | 3 | 2 | M2+M4 | 6.3 | 8.3 | **GateFailed** | 5 | - |
| CF371 | SourceVW | 4 | 3 | 3 | 2 | M2+M3 | 0.6 | 2.3 | PASSED | 5 | - |
| CF68 | SourceVW | 5 | 5 | 6 | 0 | M3 | 0.1 | 0.3 | PASSED | 5 | - |
| CF69 | SourceVW | 5 | 5 | 6 | 0 | M3 | 0.1 | 0.3 | PASSED | 5 | - |
| CF197 | SourceVW | 7 | 5 | 8 | 3 | M2+M3 | 2.8 | 5.2 | PASSED | 5 | 0.144293 |
| CF207 | SourceVW | 8 | 6 | 10 | 5 | M2+M4 | 15.5 | 21.4 | **GateFailed** | 6 | - |
| CF27 | SourceVW | 8 | 7 | 15 | 6 | M2+M3 | 1.5 | 4.0 | PASSED | 5 | - |
| CF34 | SourceVW | 8 | 7 | 15 | 6 | M2+M4 | 4.8 | 8.1 | **GateFailed** | 5 | - |
| CF201 | SourceVW | 9 | 7 | 16 | 5 | M2+M4 | 17.4 | 19.4 | **GateFailed** | 5 | - |
| CF204 | SourceVW | 9 | 7 | 16 | 5 | M2+M4 | 4.3 | 5.7 | **GateFailed** | 5 | - |
| CF210 | SourceVW | 9 | 8 | 16 | 0 | M3 | 0.4 | 1.0 | PASSED | 5 | - |
| CF212 | SourceVW | 9 | 8 | 16 | 0 | M3 | 0.5 | 1.2 | PASSED | 5 | - |
| CF123 | SourceVW | 11 | 9 | 22 | 10 | M1+M2+M4 | 123.7 | 152.9 | **GateFailed** | 5 | - |
| CF198 | SourceVW | 11 | 10 | 31 | 15 | M2+M4 | 6.4 | 8.1 | **GateFailed** | 7 | - |
| CF205 | SourceVW | 11 | 10 | 23 | 0 | M3 | 0.8 | 1.6 | PASSED | 6 | - |
| CF86 | SourceVW | 11 | 10 | 21 | 0 | M3 | 0.7 | 1.5 | PASSED | 6 | - |
| CF90 | SourceVW | 11 | 10 | 21 | 0 | M3 | 0.7 | 1.4 | PASSED | 6 | - |
| CF124 | SourceVW | 12 | 10 | 31 | 18 | M1+M2+M4 | 48.5 | 101.6 | **GateFailed** | 5 | - |
| CF16 | SourceVW | 13 | 9 | 17 | 11 | M1+M2+M4 | 89.4 | 117.1 | **GateFailed** | 6 | - |
| CF213 | SourceVW | 13 | 11 | 33 | 19 | M1+M2+M4 | 143.0 | 196.6 | **GateFailed** | 6 | - |
| CF215 | SourceVW | 13 | 11 | 33 | 19 | M1+M2+M4 | 151.1 | 210.1 | **GateFailed** | 6 | - |
| CF218 | SourceVW | 13 | 11 | 33 | 19 | M1+M2+M4 | 165.3 | 237.7 | **GateFailed** | 6 | - |
| CF24 | Chart | 13 | 9 | 25 | 8 | M2+M3 | 25.3 | 54.6 | PASSED | 8 | - |
| CF88 | Chart | 13 | 6 | 12 | 5 | M2+M3 | 99.1 | 302.7 | PASSED | 9 | - |

Totals: 28 families measured, 16 with the gate PASSED, 1
already a family eps-form as assembled, 12 still open after M1-M4.

### The 12 that did not close, and why (measured)

Every one of them hit the SAME failure mode, and it is the one already recorded
in `TransportProductionPlan.md`: **a one-letter-at-a-time Moser reduction does
not converge in two variables.** Clearing the pole at `1-x` in the x-direction
puts the pole at `1-y` back in the y-direction and the two alternate forever;
right-to-left column order is necessary but not sufficient. Measured signatures:
CF201 pair (7,4) alternating `1-x`/`1-y`; CF215 pair (11,7) going `pole 2 -> 2`
(no progress at all); CF217 `steps=120 passes=3 maxOffDiagPole=4`, i.e. the
120-step cap reached with a fourth-order pole still standing. M2 then handed M4
a state no better -- sometimes worse -- than it received, and CANONICA's
off-diagonal recursion could not close the TOP sector in any of the 12.

The driver was fixed at 02:05 (state fingerprinting, stop on a repeated state,
and return the BEST state reached so M2 can never hand M4 something worse) and
an obstruction classifier was added at 02:20, but the pool was drained for a
restart before the reruns dispatched. **The 12 rows above are therefore
pre-fix measurements: they are a lower bound on what the cleanup closes, not a
verdict on these families.**

One family is a genuinely different obstruction and will not be fixed by the
guard: **CF360** reached all-simple-poles in 4 M2 steps and still failed the
dlog identity, with a measured degree-0 polynomial part on the path
(`polyPart={0}`). That is an ENTIRE part -- a singularity at infinity -- which
no finite-letter strip and no CANONICA D-ansatz over the finite alphabet can
remove. It needs a Moser reduction AT INFINITY (Sylvester operator
`-(d+1) + eps(R_i^inf - R_j^inf)`, invertible over Q(eps)), which is not
implemented.

Also measured, as a cost warning: escalating CANONICA's ansatz does not rescue
these. On CF201 sector 5 at degrees (1,1) a SINGLE subsector column took
157.7 s and produced 17922 leaves before returning False.

## Families skipped (they do not assemble today)

Statuses as of the 02:21 per-family ledger records; the frame-availability
blockers of `TransportProductionPlan.md` item B, being fixed separately. No
eps-form is attempted here. Note the frame column above disagrees with that
ledger for many families: `MasterTransport.wl`/`TransportCharts.wl` were being
patched live, and families the 01:04 ledger recorded as `Chart` now assemble in
`(v,w)`.

- **ChartPullBackFailed** (25): CF18, CF21, CF23, CF33, CF48, CF52, CF53, CF57, CF91, CF97, CF226, CF231, CF232, CF248, CF249, CF253, CF259, CF260, CF265, CF300, CF319, CF321, CF385, CF408, CF416
- **PathDenominatorsNotLinear** (18): CF26, CF50, CF67, CF71, CF262, CF263, CF267, CF269, CF301, CF308, CF311, CF384, CF388, CF390, CF393, CF404, CF407, CF415
- **AssemblyFailed** (10): CF13, CF56, CF236, CF240, CF254, CF299, CF303, CF305, CF413, CF420

## Provenance

- driver `Scripts/family_epsform.wls`; ledger `Scripts/family_epsform_ledger.wls`
  (queued behind the production sweep at the time of writing -- this file was
  generated from the same record fields and the Wolfram ledger regenerates it
  exactly, adding the per-family obstruction column)
- payoff `Scripts/epsform_offdiag_cf230_payoff.wls <family> 0,1 <record> <outdir>`
- the CF230 record produced by the 2026-08-17 off-diagonal agent is kept beside
  the driver's as `family_epsform_CF230_offdiag_2026-08-17.wl` (with its
  `_state_*`/`_sector6_D` files); see the consistency warning above before
  consuming it
- generated 2026-08-17 02:31
