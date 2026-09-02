# Root geometries and rationalizing charts as declared data (goal 4)

State measured 2026-09-02 (overhaul survey). The package already keys
every chart on ROOT SQUARES, never on a family name: `TransportRootSetChart`
matches a request's declared quadratics against the catalog exactly;
`FamilyAlgebraicRootCensus` reads the root squares out of a family's
class forms; `TransportFamilyChartRegister`/`Load` store a per-family
chart assignment as data in
`Results/UU_08_10_canonical/TransportFamilyCharts.wl`; the multiquadratic
solver takes its root frame as a list of `<|"Root", "RootSquare"|>`
records. No `CF<n>` appears in package code outside comments and chart
`Notes` strings.

What a new root geometry needs today, and where it lives after the
overhaul:

| Item | Today | After |
|---|---|---|
| the rationalizing chart record (`Name`, `Kind`, `Variables`, `Subst`, `Roots`, optional `Parents`, `InverseByRoots`, `Notes`) | built inside `TransportChartCatalog[]` in `TransportCharts.wl` | one record in the data file `Private/Geometry/ChartCatalog.wl`, loaded by the same function; schema documented at the top of that file |
| its exact licence (`root^2 == RootSquare o Subst`, nondegenerate Jacobian, `Parents` composition) | `TransportChartVerify` re-derives | unchanged; run over the whole catalog by `Tests/Multiquadratic/t_kallen_q4_chart.wls` and the chart tests |
| a chart that exists only for one family | `TransportFamilyChartRegister` (Results data) | unchanged |
| a new chart derived automatically from root squares | `RationalizeTransportChartExtension` (RationalizeRoots) | unchanged |
| branch/sign data of the roots at a base point | the transport card (`Path` with `BranchStatement`) and the certificate's root-frame records | unchanged; documented here as the third declared datum |

Declaring a geometry therefore means: (1) one catalog record OR one
per-family registration, (2) nothing else. Code paths that mention a
chart NAME (`"Kallen1"`, `"KallenQ4a"`, ...) outside the catalog file are
defects against this rule; the survey found none in package code (the
names occur in tests and in the `Parents` field of other records).

Open item recorded, not done: the joint-chart derivation by the iterated
pencil (the `KallenQ4a` construction) is documented in the catalog but
not automated as a generic "second conic through a rational point"
routine; `RationalizeTransportChartExtension` covers the automatic route
where RationalizeRoots succeeds.
