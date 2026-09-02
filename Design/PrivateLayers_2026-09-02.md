# FeynFacet/Private layer structure (overhaul 2026-09-02, goal 3)

The package modules live in seven subfolders of `FeynFacet/Private/`,
loaded in the order of the manifest `FeynFacet/Private/LoadOrder.wl`
(the only list of modules; `FeynFacet.m` reads it and refuses to load if
it is missing, malformed, or names an absent file). A layer may
reference only itself and the layers above it.

| order | layer | contents |
|---|---|---|
| 1 | `Core/` | `Core.wl` exact algebra, bases, metadata, installation roots; `ModularArithmetic.wl` primes, modular square roots, split points, CRT, rational reconstruction, lift-and-verify (one implementation, goal 2); `MultiquadraticAlgebra.wl` extension-field grade algebra; `RationalMaterialization.wl` rational-DAG compaction |
| 2 | `Process/` | process cards, diagram generation, topologies and cuts, dimensional shifts, collinear factorization |
| 3 | `Reduction/` | Kira reduction and streaming import, coefficient store, simplification, finite-field coefficient reconstruction, assembly, AMFlow cross-checks |
| 4 | `Infrastructure/` | `TaskBroker.wl` (pool-side parallelism) |
| 5 | `Geometry/` | `TransportCharts.wl` chart catalog, root geometry, chart extension (Design/GeometryDeclaration_2026-09-02.md) |
| 6 | `EpsForm/` | stage 1: canonical blocks and classes, diagonal-block eps-forms, off-diagonal completion (finite-field and multiquadratic solvers, deferred block equations, gauge pull-back, installation), row gauges and resume, regulator factorization, modular family certificate, family eps-form records and certifier |
| 7 | `Transport/` | stage 2: family assembly and the Libra transport entry (`MasterTransport.wl`), word engines, the CF303 exception seam, the observable transport (production) and its finite-field coordinate reconstruction |

Superseded code is kept, never loaded, under `FeynFacet/Private_Backup/`
with its evidence in `Private_Backup/EVIDENCE.md`; tests that only
exercised moved code are under `Private_Backup/Tests/`.

Tests that `Get` or `Import` a module file directly use the layered
path (`{root, "FeynFacet", "Private", "<Layer>", "<File>.wl"}`).

Known upward references left in place (each is one or two symbols; to be
moved down with the symbol when the file is next touched): `FamilyEpsForm`
(EpsForm) uses four zero-test helpers of `ObservableTransport` (Transport).
