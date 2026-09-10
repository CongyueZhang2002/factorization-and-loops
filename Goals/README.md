# Current roadmap

The deliverable is general NNLO code. Process cards, integral definitions,
coefficient tables, boundary values and numerical comparison points are inputs;
individual families test the general code.

The latest requested SIDIS NNLO UU/LL campaign is complete. All26 channel
hard coefficients are stored as explicit finite Mathematica results and
validated against independent NNLO expressions in all four kinematic regions.
See [UU](../Projects/SIDIS_UU_NNLO/NNLO/README.md) and
[LL](../Projects/SIDIS_LL_NNLO/NNLO/README.md) for the results and replay commands.

The general framework remains the deliverable: endpoint profiles and their
joint uniformity, finite epsilon-order propagation, symbolic special functions,
counterterms and the shared result format are reusable package code. No
reference hard coefficient enters production.

## Earlier ppHX campaign scope

The user authorized the following sequence on 2026-09-07. These records
describe that earlier campaign; they are not outstanding SIDIS prerequisites.

1. Complete: all 91 families, 345 requested masters and 2,220 coefficients
   pass the independent AMFlow comparison at v=1/4,w=1/5. The aggregate
   includes every repaired comparison. Preserve these accepted references.
2. Implemented on the declared single-threshold domain: steps 1-4 of the
   double-real distribution assembly:
   combine physical coefficients and finite master solutions; construct the
   recoil-mass endpoint functions with the scattering variable symbolic;
   propagate sufficient epsilon orders for the actual endpoint projections;
   store explicit delta/plus-distribution coefficients and the locally
   integrable remainder. The general code is the main deliverable. The current
   302.36 MiB result covers 345 masters with zero unknown constants and ten
   color components through epsilon^0. Its distribution basis is unreduced;
   excess terms cancel numerically at the base point but have not been
   removed as symbolic identities. See the process Stage4_2026-09-07 README.
3. Later complete the other NNLO contributions, UV renormalization and PDF/
   fragmentation-function mass factorization, then validate assembled finite
   quantities across structurally different processes. This is outside the
   current explicit steps 1-4 instruction.

The [authorized assembly plan](../Design/DistributionAssemblyPlan_2026-09-07.md)
specifies inputs, scope and acceptance. The live validation and recovery records
are under
ppHX_NNLO_DoubleReal/Results/Validation/FullValidation_2026-09-07.
[STATUS.md](../STATUS.md) records the stored DE/solution scope.

The separate stage-3 test tracks 33 boundary inputs and 157 demanded
coefficients. Most independent references remain missing, and one supplied
reference lacks its highest required order. This is still incomplete and must
be reported as such. It is not an additional prerequisite invented after the
user authorized the above sequence. Region-completeness proofs remain
mathematical inputs.

Controlled analytic continuation, endpoint expansions and final counterterm/
convolution demands must be treated explicitly when each operation needs
them. Canonicalization and familiar special-function forms may simplify
specific results but are not prerequisites for all finite DE solutions.

Checks should be proportionate: cheap rational/numerical comparisons where
suitable and independent AMFlow comparisons for physical masters. The finite
solution is stored explicitly; missing orders must never be delegated to an
unexpanded generator.

[Earlier objectives](../Archive/History/Goals/README.md) are historical.
