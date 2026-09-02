(* FeynFacet/Private/LoadOrder.wl -- the ONE list of package modules and
   their load order (overhaul 2026-09-02, goal 3).  Layers load top to
   bottom; a layer may reference only itself and the layers above it.
   FeynFacet.m reads this file; a module not listed here is not loaded.
   Superseded code lives in FeynFacet/Private_Backup/ (never loaded).

     Core            exact algebra, modular arithmetic, extension-field algebra,
                     rational-DAG materialization
     Process         process cards, diagram generation, topologies, cuts,
                     dimensional shifts, collinear factorization
     Reduction       Kira reduction, coefficient reconstruction and assembly,
                     numerical cross-checks
     Infrastructure  the kernel-pool task broker
     Geometry        rationalizing charts and root geometry
     EpsForm         stage 1: canonical blocks, off-diagonal completion,
                     regulator factorization, family certificates
     Transport       stage 2: assembly, word engines, exception seam,
                     observable transport *)
{
  "Core" -> {"Core.wl", "MultiquadraticAlgebra.wl", "RationalMaterialization.wl"},
  "Process" -> {"Process.wl", "Topologies.wl", "CanonicalFamilies.wl", "DimensionalShift.wl", "Collinear.wl"},
  "Reduction" -> {"Reduction.wl", "StreamingKira.wl", "MasterIntegralAmFlow.wl", "Simplification.wl", "Assembly.wl", "CoefficientStore.wl", "Reconstruction.wl"},
  "Infrastructure" -> {"TaskBroker.wl"},
  "Geometry" -> {"TransportCharts.wl"},
  "EpsForm" -> {"CanonicalBlocks.wl", "EpsFormStrip.wl", "BlockEquationDeferred.wl", "FiniteFieldEpsForm.wl", "FiniteFieldStripSolve.wl", "EpsFormStripObstruction.wl", "FamilyRegulatorFactor.wl", "FamilyRowGauge.wl", "FamilyRowGaugeResume.wl", "FamilyCertificateModular.wl", "MultiquadraticStripSolve.wl", "MultiquadraticInstallation.wl", "FiniteFieldGaugePullBack.wl", "LibraEpsForm.wl", "FamilyEpsForm.wl", "DiagonalBlockEpsForm.wl"},
  "Transport" -> {"MasterTransport.wl", "BlockwiseTransport.wl", "CanonicalWordTransport.wl", "PathTransportException.wl", "PathTransportNative.wl", "ObservableTransport.wl", "ObservableTransportFiniteField.wl"},
}
