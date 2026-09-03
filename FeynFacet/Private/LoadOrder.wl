(* FeynFacet/Private/LoadOrder.wl -- the ONE list of package modules and
   their load order (overhaul 2026-09-02, goal 3).  Layers load top to
   bottom; a layer may reference only itself and the layers above it.
   FeynFacet.m reads this file; a module not listed here is not loaded.
   Superseded code lives in FeynFacet/Private_Backup/ (never loaded).
   A manifest entry is a path relative to its layer; the bare file name
   stays unique across the manifest and FeynFacet.m's feynFacetPrivateFile
   answers to either spelling.

     Core            exact algebra, modular arithmetic, extension-field and
                     radical algebra, rational-DAG materialization, the
                     context-guarded artifact I/O and binary record I/O,
                     chart-record data and chain-rule pullbacks, regulator/
                     variable resolution, the radical zero tests and their
                     Boolean wrappers (observableTransportZeroQ,
                     ...ZeroMatrixQ, ...BlockLowerQ, from Transport, round 7)
     Process         process cards, diagram generation, topologies, cuts,
                     dimensional shifts, collinear factorization, the pre-IBP
                     result validator, the coefficient-kinematics normalizer
     Reduction       Kira reduction, coefficient reconstruction and assembly,
                     numerical cross-checks
     Infrastructure  the generic kernel-pool task broker
     Geometry        the catalog of rationalizing charts, chart verification,
                     the algebraic frame builder, the root census, the
                     per-family chart registry, chart extension, the
                     record-to-chart coordinate map and the record-chart
                     resolution (observableTransportRecordChart, from
                     Transport, round 7).  Loads BEFORE EpsForm since round 7
                     (2026-09-02): the in-frame strip solver that once shared
                     this file is in EpsForm/Strip/EpsFormStripInFrame.wl, so
                     nothing here references EpsForm, at load time or later.
     EpsForm         stage 1: canonical blocks, the in-frame and finite-field
                     strip solvers, deferred block equations, the
                     multiquadratic engine, gauge pull-back, regulator
                     factorization, row gauges, family records and
                     certificates, the Libra loader, the strip sampler's
                     broker client
     Transport       stage 2: MasterTransport.wl (chart assembly of a family,
                     Libra backend for the retired route) and the observable
                     transport; the path-ordered engines, word engines and
                     exception seam are retired (Private_Backup, 2026-09-02 U1)

   DEPENDENCY GRAPH, measured 2026-09-02 (round 7) by the symbol scan of
   evidence/round4/G_layers_geometry_scripts.md (definition heads per
   file, identifier references per file, a reference whose only
   definitions live in a later layer is upward): NO call-time upward
   reference remains.  What the scan still reports, by name:
     Core/Base/Core.wl matches the public retired head TransportWord
       (Transport) as a PATTERN in masterTransportZeroQ's word branch;
     Process/Cards/Process.wl issues the MESSAGE
       BuildSimplificationContext::invalid (defined in Reduction);
     Core/Algebra/RationalMaterialization.wl's `fail` is Module-local
       (scan false positive, not the Process.wl `fail`).
   History: the D1 correction of 2026-09-02 07:30 moved Geometry after
   EpsForm because TransportCharts.wl evaluated
   Options[SolveEpsFormStripInFrame] = Join[Options[SolveEpsFormStrip], ...]
   at load time; that statement now lives in EpsFormStripInFrame.wl,
   listed after EpsFormStrip.wl, and the order is the designed one again.

   SUB-FOLDERS (round 5, 2026-09-02, user ruling "substructure in
   Private").  One line per sub-folder, what belongs there:
     Core/Base        contexts and installation geometry, kernel counts,
                      result headers, basis and scalar declarations, exact
                      zero tests and their Boolean wrappers, linear integral
                      sums, regulator/variable resolution and the word
                      collector (Core.wl)
     Core/Modular     the ONE finite-field implementation: rational
                      reconstruction, CRT, square roots, residue tests,
                      prime schedules, lift-and-verify (ModularArithmetic.wl)
     Core/Algebra     extension-field and radical algebra: the neutral
                      multiquadratic grade algebra (MultiquadraticAlgebra.wl),
                      rational-DAG materialization (RationalMaterialization.wl),
                      the radicals of the spectator (Radicals.wl)
     Core/Artifacts   the context-guarded artifact reader/writer and the
                      length-prefixed binary record I/O (Artifacts.wl)
     Core/Charts      chart-record data and the chain-rule pullbacks into a
                      two-variable chart (ChartData.wl)
     Process/Cards    process cards and the canonical family registry
                      (Process.wl, CanonicalFamilies.wl)
     Process/Diagrams diagram generation, topologies and cuts, dimensional
                      shifts, collinear factorization (Topologies.wl,
                      DimensionalShift.wl, Collinear.wl)
     Reduction/Kira   the Kira driver and the streaming import
                      (Reduction.wl, StreamingKira.wl)
     Reduction/AmFlow master-integral numerics (MasterIntegralAmFlow.wl)
     Reduction/Coefficients
                      coefficient simplification, the coefficient store,
                      reconstruction and assembly (Simplification.wl,
                      CoefficientStore.wl, Reconstruction.wl, Assembly.wl)
     Geometry         one file, flat: TransportCharts.wl
     EpsForm/Blocks   diagonal blocks and the block decomposition: the
                      canonical-block classifier, the finite-field
                      diagonal-block route, the Libra loader, the deferred
                      block-equation DAG (CanonicalBlocks.wl,
                      DiagonalBlockEpsForm.wl, LibraEpsForm.wl,
                      BlockEquationDeferred.wl)
     EpsForm/Strip    the off-diagonal strip contract, the in-frame strip
                      solver SolveEpsFormStripInFrame with its stage log,
                      broker-parallel tasks, deferred-bundle pullbacks and
                      deadline bookkeeping (from Geometry, round 7), and the
                      obstruction records (EpsFormStrip.wl,
                      EpsFormStripInFrame.wl, EpsFormStripObstruction.wl)
     EpsForm/FiniteField
                      the finite-field strip solver and its lift, broker
                      client and gauge pullback (FiniteFieldEpsForm.wl,
                      FiniteFieldStripSolve.wl, FiniteFieldStripBroker.wl,
                      FiniteFieldGaugePullBack.wl)
     EpsForm/Multiquadratic
                      the multiquadratic strip solver, eight files in load
                      order (MultiquadraticStripSolve.wl first), and its
                      installation gate (MultiquadraticInstallation.wl)
     EpsForm/Family   whole-family artifacts and certificates: family eps-form
                      records, regulator factorization, the modular family
                      certificate, row gauges and their resume
                      (FamilyEpsForm.wl, FamilyRegulatorFactor.wl,
                      FamilyCertificateModular.wl, FamilyRowGauge.wl,
                      FamilyRowGaugeResume.wl)
     Transport/Assembly
                      the chart assembly of a family and the Libra backend of
                      the retired route (MasterTransport.wl)
     Transport/Observable
                      the observable transport and its finite-field compiler
                      (ObservableTransport.wl, ObservableTransportFiniteField.wl)
     Transport/Boundary
                      singular-endpoint Frobenius prefactors, physical-mode
                      normalization, and exact GPL/elliptic boundary data
                      converted to transport selectors (PhysicalBoundary.wl)
     Infrastructure   one file, flat: TaskBroker.wl *)
{
  "Core" -> {"Base/Core.wl", "Modular/ModularArithmetic.wl", "Algebra/MultiquadraticAlgebra.wl", "Algebra/RationalMaterialization.wl", "Algebra/Radicals.wl", "Artifacts/Artifacts.wl", "Charts/ChartData.wl"},
  "Process" -> {"Cards/Process.wl", "Diagrams/Topologies.wl", "Cards/CanonicalFamilies.wl", "Diagrams/DimensionalShift.wl", "Diagrams/Collinear.wl"},
  "Reduction" -> {"Kira/Reduction.wl", "Kira/StreamingKira.wl", "AmFlow/MasterIntegralAmFlow.wl", "Coefficients/Simplification.wl", "Coefficients/Assembly.wl", "Coefficients/CoefficientStore.wl", "Coefficients/Reconstruction.wl"},
  "Infrastructure" -> {"TaskBroker.wl"},
  "Geometry" -> {"TransportCharts.wl"},
  "EpsForm" -> {"Blocks/CanonicalBlocks.wl", "Strip/EpsFormStrip.wl", "Strip/EpsFormStripInFrame.wl", "Blocks/BlockEquationDeferred.wl", "FiniteField/FiniteFieldEpsForm.wl", "FiniteField/FiniteFieldStripSolve.wl", "FiniteField/FiniteFieldStripBroker.wl", "FiniteField/FiniteFieldDeferredForcing.wl", "Strip/EpsFormStripObstruction.wl", "Family/FamilyRegulatorFactor.wl", "Family/FamilyRowGauge.wl", "Family/FamilyRowGaugeResume.wl", "Family/FamilyCertificateModular.wl", "Multiquadratic/MultiquadraticStripSolve.wl", "Multiquadratic/MultiquadraticStripLetters.wl", "Multiquadratic/MultiquadraticStripScreens.wl", "Multiquadratic/MultiquadraticStripPrepareCompile.wl", "Multiquadratic/MultiquadraticStripSampling.wl", "Multiquadratic/MultiquadraticStripProviders.wl", "Multiquadratic/MultiquadraticStripReconstruction.wl", "Multiquadratic/MultiquadraticStripDriver.wl", "Multiquadratic/MultiquadraticInstallation.wl", "FiniteField/FiniteFieldGaugePullBack.wl", "Blocks/LibraEpsForm.wl", "Family/FamilyEpsForm.wl", "Blocks/DiagonalBlockEpsForm.wl"},
  "Transport" -> {"Boundary/PhysicalBoundary.wl", "Assembly/MasterTransport.wl", "Observable/ObservableTransport.wl", "Observable/ObservableTransportFiniteField.wl", "Observable/IteratedIntegralWords.wl", "Boundary/CompactEndpointResidue.wl", "Observable/RationalEpsilonLayer.wl", "Observable/RationalEpsilonLayerOperator.wl", "Observable/PhysicalTransportResult.wl"}
}
