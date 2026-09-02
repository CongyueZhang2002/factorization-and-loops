(* FeynFacet/Private/LoadOrder.wl -- the ONE list of package modules and
   their load order (overhaul 2026-09-02, goal 3).  Layers load top to
   bottom; a layer may reference only itself and the layers above it.
   FeynFacet.m reads this file; a module not listed here is not loaded.
   Superseded code lives in FeynFacet/Private_Backup/ (never loaded).

     Core            exact algebra, modular arithmetic, extension-field
                     algebra, rational-DAG materialization; since the layer
                     pass of 2026-09-02 (round 4) also the layer-neutral
                     helpers that used to sit higher up: the root/radical
                     algebra of rationalizing charts and the chart re-keying
                     (MultiquadraticAlgebra.wl, from Geometry), the chart-
                     record data and chain-rule pullbacks, the regulator/
                     variable resolution and the radical zero tests
                     (Core.wl, from Transport), the context-guarded artifact
                     reader/writer (from EpsForm) and the binary record I/O
                     (from Reduction)
     Process         process cards, diagram generation, topologies, cuts,
                     dimensional shifts, collinear factorization; the
                     pre-IBP result validator (from Reduction) and the
                     coefficient-kinematics declaration normalizer (from
                     Reduction) live here since round 4
     Reduction       Kira reduction, coefficient reconstruction and assembly,
                     numerical cross-checks
     Infrastructure  the generic kernel-pool task broker (no EpsForm
                     reference since round 4)
     EpsForm         stage 1: canonical blocks, off-diagonal completion,
                     regulator factorization, family certificates; the strip
                     sampler's broker client (FiniteFieldStripBroker.wl, from
                     Infrastructure) and the Libra loader (LibraEpsForm.wl,
                     from Transport)
     Geometry        the catalog of rationalizing charts, chart verification,
                     the per-family chart registry, the root census, the
                     record-to-chart coordinate map (from Transport) AND the
                     in-frame strip solver SolveEpsFormStripInFrame.  It
                     loads AFTER EpsForm because that solver calls the
                     EpsForm solvers and inherits Options[SolveEpsFormStrip]
                     at load time (review finding D1, 2026-09-02) -- a
                     downward reference under this order.
     Transport       stage 2: MasterTransport.wl (chart assembly of a family,
                     Libra backend for the retired route) and the observable
                     transport; the path-ordered engines, word engines and
                     exception seam are retired (Private_Backup, 2026-09-02 U1)

   TRUE DEPENDENCY GRAPH, measured by Scripts/Diagnostics-style symbol scan
   on 2026-09-02 (round 4, evidence/round4/G_layers_geometry_scripts.md):
   every layer references only itself and lower layers EXCEPT the
   following call-time references, listed by name so that nobody has to
   rediscover them:
     EpsForm -> Geometry  TransportRootSetChart (BlockEquationDeferred.wl,
                          DiagonalBlockEpsForm.wl, FamilyRegulatorFactor.wl),
                          TransportChartVerify and transportFamilyChartAlias
                          (FamilyEpsForm.wl): catalog and registry lookups.
                          The chart CATALOG conceptually sits below EpsForm;
                          it stays above only because SolveEpsFormStripInFrame
                          shares its file.  The recorded fix is to move the
                          in-frame solver and its deferred-bundle helpers
                          into EpsForm and list Geometry before EpsForm.
     EpsForm -> Transport observableTransportBlockLowerQ, observableTransport-
                          RecordChart, observableTransportZeroMatrixQ,
                          observableTransportZeroQ (FamilyEpsForm.wl ->
                          ObservableTransport.wl): four small predicates; the
                          zero tests wrap masterTransportZeroQ (now Core).
     name-only            Core.wl matches the public retired head TransportWord
                          as a pattern; Process.wl issues the message
                          BuildSimplificationContext::invalid (Reduction).
   No load-time reference crosses upward.

   SUB-FOLDERS (round 5, 2026-09-02, user ruling "substructure in
   Private").  A manifest entry is a path relative to its layer; the bare
   file name stays unique across the manifest and FeynFacet.m's
   feynFacetPrivateFile answers to either spelling.  One line per
   sub-folder, what belongs there:
     Core/Base        contexts and installation geometry, kernel counts,
                      result headers, basis and scalar declarations, exact
                      zero tests, linear integral sums, regulator/variable
                      resolution and the word collector (Core.wl)
     Core/Modular     the ONE finite-field implementation: rational
                      reconstruction, CRT, square roots, residue tests,
                      prime schedules (ModularArithmetic.wl)
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
     EpsForm/Blocks   diagonal blocks and the block decomposition: the
                      canonical-block classifier, the finite-field
                      diagonal-block route, the Libra loader, the deferred
                      block-equation DAG (CanonicalBlocks.wl,
                      DiagonalBlockEpsForm.wl, LibraEpsForm.wl,
                      BlockEquationDeferred.wl)
     EpsForm/Strip    the off-diagonal strip contract and its obstruction
                      records (EpsFormStrip.wl, EpsFormStripObstruction.wl)
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
     Infrastructure, Geometry  one file each, flat
     Transport        sub-folders follow in phase 3 of round 5
                      (Design/PrivateOverhaul_2026-09-01.md) *)
{
  "Core" -> {"Base/Core.wl", "Modular/ModularArithmetic.wl", "Algebra/MultiquadraticAlgebra.wl", "Algebra/RationalMaterialization.wl", "Algebra/Radicals.wl", "Artifacts/Artifacts.wl", "Charts/ChartData.wl"},
  "Process" -> {"Cards/Process.wl", "Diagrams/Topologies.wl", "Cards/CanonicalFamilies.wl", "Diagrams/DimensionalShift.wl", "Diagrams/Collinear.wl"},
  "Reduction" -> {"Kira/Reduction.wl", "Kira/StreamingKira.wl", "AmFlow/MasterIntegralAmFlow.wl", "Coefficients/Simplification.wl", "Coefficients/Assembly.wl", "Coefficients/CoefficientStore.wl", "Coefficients/Reconstruction.wl"},
  "Infrastructure" -> {"TaskBroker.wl"},
  "EpsForm" -> {"Blocks/CanonicalBlocks.wl", "Strip/EpsFormStrip.wl", "Blocks/BlockEquationDeferred.wl", "FiniteField/FiniteFieldEpsForm.wl", "FiniteField/FiniteFieldStripSolve.wl", "FiniteField/FiniteFieldStripBroker.wl", "Strip/EpsFormStripObstruction.wl", "Family/FamilyRegulatorFactor.wl", "Family/FamilyRowGauge.wl", "Family/FamilyRowGaugeResume.wl", "Family/FamilyCertificateModular.wl", "Multiquadratic/MultiquadraticStripSolve.wl", "Multiquadratic/MultiquadraticStripLetters.wl", "Multiquadratic/MultiquadraticStripScreens.wl", "Multiquadratic/MultiquadraticStripPrepareCompile.wl", "Multiquadratic/MultiquadraticStripSampling.wl", "Multiquadratic/MultiquadraticStripProviders.wl", "Multiquadratic/MultiquadraticStripReconstruction.wl", "Multiquadratic/MultiquadraticStripDriver.wl", "Multiquadratic/MultiquadraticInstallation.wl", "FiniteField/FiniteFieldGaugePullBack.wl", "Blocks/LibraEpsForm.wl", "Family/FamilyEpsForm.wl", "Blocks/DiagonalBlockEpsForm.wl"},
  "Geometry" -> {"TransportCharts.wl"},
  "Transport" -> {"MasterTransport.wl", "ObservableTransport.wl", "ObservableTransportFiniteField.wl"}
}
