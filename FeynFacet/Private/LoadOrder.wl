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
                     coefficient-presentation data and chain-rule pullbacks, regulator/
                     variable resolution, the radical zero tests and their
                     Boolean wrappers for the requested-output coefficient
                     machinery
     Process         process cards, diagram generation, topologies, cuts,
                     dimensional shifts, collinear factorization, the pre-IBP
                     result validator, the coefficient-kinematics normalizer
     Reduction       Kira reduction, coefficient reconstruction and assembly,
                     numerical cross-checks
     Infrastructure  the generic kernel-pool task broker
     Geometry        the rationalizing-parametrization catalog and verification,
                     square-root generators, the root census, the per-family
                     coefficient-presentation registry, extension, the
                     coefficient-variable coordinate map and presentation
                     resolution (masterTransportCoefficientPresentationData).
                     Loads BEFORE EpsForm since round 7
                     (2026-09-02): the off-diagonal block solver that once shared
                     this file is in EpsForm/OffDiagonalBlocks/OffDiagonalBasisTransformationBlock.wl, so
                     nothing here references EpsForm, at load time or later.
     EpsForm         stage 1: canonical blocks, the in-frame and finite-field
                     off-diagonal block solvers, deferred block equations, the
                     square-root-component engine, coordinate re-expression,
                     regulator factorization, row basis transformations, family records and
                     certificates, the Libra loader, and the off-diagonal block sampler's
                     broker client
     Transport       family differential-system assembly, local-boundary
                     analysis and requested-output iterated-integral
                     coefficient machinery; the retired path-ordered route
                     is present only in Private_Backup

   DEPENDENCY GRAPH, measured 2026-09-02 (round 7) by the symbol scan of
   evidence/round4/G_layers_geometry_scripts.md (definition heads per
   file, identifier references per file, a reference whose only
   definitions live in a later layer is upward): NO call-time upward
   reference remains.  What the scan still reports, by name:
     Core/Base/Core.wl contains dormant private TransportWord syntax from the
       retired path-ordered route; it is not referenced by a loaded transport
       constructor;
     Process/Cards/Process.wl issues the MESSAGE
       BuildSimplificationContext::invalid (defined in Reduction);
     Core/Algebra/RationalMaterialization.wl's `fail` is Module-local
       (scan false positive, not the Process.wl `fail`).
   Geometry loads before EpsForm.  The coefficient-presentation layer is
   therefore available when SolveOffDiagonalBasisTransformationBlock is
   defined, while Geometry has no reverse dependency on that solver.

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
     Core/Charts      coefficient-presentation data and chain-rule pullbacks
                      into two parametrizing variables (ChartData.wl)
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
     EpsForm/Blocks   diagonal blocks and block decomposition: the V2
                      strongly-connected-component producer, the
                      canonical-block classifier, the finite-field
                      diagonal-block route and its V2 artifact constructor,
                      the Libra loader, the deferred block-equation DAG
                      (CanonicalBlocks.wl, DiagonalBlockEpsForm.wl,
                      DiagonalBlockDLogEpsilonForm.wl, LibraEpsForm.wl,
                      BlockEquationDeferred.wl,
                      FamilyDifferentialSystemBlockDecomposition.wl)
     EpsForm/OffDiagonalBlocks
                      the off-diagonal block-equation contract and the
                      solver SolveOffDiagonalBasisTransformationBlock with its stage log,
                      broker-parallel tasks, deferred-bundle pullbacks and
                      deadline bookkeeping (from Geometry, round 7), and the
                      obstruction analysis (OffDiagonalBlockEquation.wl,
                      OffDiagonalBasisTransformationBlock.wl,
                      OffDiagonalBlockEpsilonFormObstructions.wl)
     EpsForm/FiniteField
                      the finite-field off-diagonal block equation solver and its lift, broker
                      client and basis-transformation coordinate re-expression (FiniteFieldEpsForm.wl,
                      FiniteFieldOffDiagonalBlockSolve.wl, FiniteFieldOffDiagonalBlockBroker.wl,
                      FiniteFieldBasisTransformationReexpression.wl)
     EpsForm/Multiquadratic
                      the multiquadratic off-diagonal block equation solver, eight files in load
                      order (MultiquadraticOffDiagonalBlockSolve.wl first), and its
                      installation gate (MultiquadraticInstallation.wl)
     EpsForm/Family   whole-family artifacts and certificates: family eps-form
                      records, regulator factorization, the modular family
                      certificate, row basis transformations and their resume
                      (FamilyEpsForm.wl, FamilyRegulatorFactor.wl,
                      FamilyCertificateModular.wl, FamilyRowBasisTransformation.wl,
                      FamilyRowBasisTransformationResume.wl)
     Transport/Assembly
                      coefficient-presentation re-expression and certified
                      assembly of a family differential system with
                      epsilon-form diagonal blocks
     Transport/Observable
                      the observable transport and its finite-field compiler
                      (ObservableTransport.wl, ObservableTransportFiniteField.wl)
     Transport/Boundary
                      singular-endpoint Frobenius prefactors, physical-mode
                      normalization, induced boundary-function differential
                      systems and tangential evolution, and exact GPL/elliptic
                      boundary data converted to transport selectors
     Infrastructure   one file, flat: TaskBroker.wl *)
{
  "Core" -> {"Base/Core.wl", "Modular/ModularArithmetic.wl", "Algebra/MultiquadraticAlgebra.wl", "Algebra/RationalMaterialization.wl", "Algebra/Radicals.wl", "Artifacts/Artifacts.wl", "Charts/ChartData.wl"},
  "Process" -> {"Cards/Process.wl", "Diagrams/Topologies.wl", "Cards/CanonicalFamilies.wl", "Diagrams/DimensionalShift.wl", "Diagrams/Collinear.wl"},
  "Reduction" -> {"Kira/Reduction.wl", "Kira/StreamingKira.wl", "AmFlow/MasterIntegralAmFlow.wl", "Coefficients/Simplification.wl", "Coefficients/Assembly.wl", "Coefficients/CoefficientStore.wl", "Coefficients/Reconstruction.wl"},
  "Infrastructure" -> {"TaskBroker.wl"},
  "Geometry" -> {"TransportCharts.wl"},
  "EpsForm" -> {"Blocks/FamilyDifferentialSystemBlockDecomposition.wl", "Blocks/CanonicalBlocks.wl", "OffDiagonalBlocks/OffDiagonalBlockEquation.wl", "OffDiagonalBlocks/OffDiagonalBasisTransformationBlock.wl", "Blocks/BlockEquationDeferred.wl", "FiniteField/FiniteFieldEpsForm.wl", "FiniteField/FiniteFieldOffDiagonalBlockSolve.wl", "FiniteField/FiniteFieldOffDiagonalBlockBroker.wl", "FiniteField/FiniteFieldDeferredInhomogeneity.wl", "OffDiagonalBlocks/OffDiagonalBlockEpsilonFormObstructions.wl", "Family/FamilyRegulatorFactor.wl", "Family/FamilyRowBasisTransformation.wl", "Family/FamilyRowBasisTransformationResume.wl", "Family/FamilyCertificateModular.wl", "Multiquadratic/MultiquadraticOffDiagonalBlockSolve.wl", "Multiquadratic/MultiquadraticOffDiagonalBlockLetters.wl", "Multiquadratic/MultiquadraticOffDiagonalBlockScreens.wl", "Multiquadratic/MultiquadraticOffDiagonalBlockPrepareCompile.wl", "Multiquadratic/MultiquadraticOffDiagonalBlockSampling.wl", "Multiquadratic/MultiquadraticOffDiagonalBlockProviders.wl", "Multiquadratic/MultiquadraticOffDiagonalBlockReconstruction.wl", "Multiquadratic/MultiquadraticOffDiagonalBlockDriver.wl", "Multiquadratic/MultiquadraticInstallation.wl", "FiniteField/FiniteFieldBasisTransformationReexpression.wl", "Blocks/LibraEpsForm.wl", "Family/FamilyEpsForm.wl", "Blocks/DiagonalBlockEpsForm.wl", "Blocks/DiagonalBlockDLogEpsilonForm.wl"},
  "Transport" -> {"Boundary/PhysicalBoundary.wl", "Boundary/BoundaryFunctionDifferentialSystem.wl", "Boundary/TangentialBoundaryEvolution.wl", "Boundary/MasterIntegralEpsilonOrderRequirements.wl", "Boundary/FinishPhysicalTransport.wl", "Boundary/FactorizedFiniteFieldBoundaryComposition.wl", "Assembly/FamilyDifferentialSystemAssembly.wl", "Observable/ObservableTransport.wl", "Observable/ObservableTransportFiniteField.wl", "Observable/FormalChenIteratedIntegrals.wl", "Boundary/ConnectionResidueAtLocalExpansionPoint.wl", "Boundary/RationalEpsilonDependentBlockConnectionResidue.wl", "Observable/RationalEpsilonDependentBlock.wl", "Observable/RationalEpsilonDependentBlockIteratedIntegralCoefficientOperator.wl", "Observable/TangentialJunction.wl", "Observable/MasterIntegralEpsilonExpansionCoefficient.wl"}
}
