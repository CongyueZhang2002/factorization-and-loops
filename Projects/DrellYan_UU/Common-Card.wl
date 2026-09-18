<|
  "Project" -> "DrellYan_UU",
  "Observable" -> "InclusiveElectromagneticDrellYanInvariantMass",
  "StructureFunctions" -> {"C_DY"},
  "Orders" -> <|"LO" -> {"q-qb", "qb-q"}, "NLO" -> {"q-qb", "qb-q", "q-g", "g-q", "qb-g", "g-qb"}|>,
  (* Quark-antiquark annihilation is Born; a quark-gluon state needs a final quark. *)
  "MinimumChannelOrders" -> <|"q-qb" -> 0, "qb-q" -> 0, "q-g" -> 1, "g-q" -> 1, "qb-g" -> 1, "g-qb" -> 1|>,
  "Channels" -> <|
    "q-qb" -> <|"Incoming" -> {{"q", "u"}, {"qb", "u"}}|>,
    "qb-q" -> <|"Incoming" -> {{"qb", "u"}, {"q", "u"}}|>,
    "q-g" -> <|"Incoming" -> {{"q", "u"}, "g"}|>,
    "g-q" -> <|"Incoming" -> {"g", {"q", "u"}}|>,
    "qb-g" -> <|"Incoming" -> {{"qb", "u"}, "g"}|>,
    "g-qb" -> <|"Incoming" -> {"g", {"qb", "u"}}|>
  |>,
  "SpeciesMap" -> <|
    {"q", "u"} -> FeynArts`F[3, {1}], {"qb", "u"} -> -FeynArts`F[3, {1}],
    {"q", "d"} -> FeynArts`F[4, {1}], {"qb", "d"} -> -FeynArts`F[4, {1}], "g" -> FeynArts`V[5]
  |>,
  "Current" -> <|
    "Field" -> FeynArts`V[1], "Side" -> "Outgoing", "Momentum" -> q, "MomentumSpace" -> "IntegratedD",
    "Indices" -> <|"Conjugate" -> mu, "Amplitude" -> nu|>, "Coupling" -> FeynCalc`SMP["e"], "Projection" -> "DrellYan"
  |>,
  "IncomingMomenta" -> {pa, pb},
  "FinalMomenta" -> {k1, k2},
  "GluonSpinIndices" -> <|"Incoming" -> {{muGa, nuGa}, {muGb, nuGb}}|>,
  "GluonPolarizationReferences" -> <|pa -> pb, pb -> pa|>,
  "Polarization" -> <|"Incoming" -> {"U", "U"}|>,
  "SpinParameters" -> <||>,
  "ProcessDefaults" -> <|
    "Model" -> "SMQCD", "InsertionLevel" -> {FeynArts`Classes},
    "ExcludeTopologies" -> {FeynArts`Tadpoles, FeynArts`WFCorrections},
    "ExcludeParticles" -> {FeynArts`S[_], FeynArts`V[1], FeynArts`V[2], FeynArts`V[3]},
    "MasslessQuarkFlavors" -> <|"UpType" -> nU, "DownType" -> nD|>
  |>,
  "Kinematics" -> <|"BornConditions" -> z == 1, "RadiativeConditions" -> 0 < z < 1|>,
  "Assembly" -> <|
    "IntegrationMethod" -> "ProjectedCurrent",
    "CollinearConvolution" -> "Mellin",
    "Scale" -> Q2, "Variables" -> {z}, "Assumptions" -> Q2 > 0 && muR2 > 0,
    "Domain" -> Q2 > 0 && 0 < z <= 1,
    "DensityConvention" -> "d sigma_hat/d Q2 = 4 pi alpha_em^2/(3 Nc Q2 s) C_DY(z), z=Q2/s; flavor charge included",
    "LeptonicConvention" -> "The entire scalar integrated leptonic tensor is factored out in D dimensions; its physical four-dimensional normalization is restored in the cross section.",
    "ObservableNormalization" -> <|"Tensor" -> "CutTensor", "Coefficient" -> "BornNormalized",
      "ReferenceChannel" -> "q-qb", "ReferenceStructure" -> "C_DY", "ReferenceEpsilonOrder" -> 0, "ReferenceFlavorCharges" -> "Unit"|>,
    "FactorizationLegs" -> <|
      "IncomingA" -> <|"Role" -> "PDF", "Index" -> 1, "Variable" -> z|>,
      "IncomingB" -> <|"Role" -> "PDF", "Index" -> 2, "Variable" -> z|>
    |>,
    "EndpointExpansion" -> <|
      "NormalVariables" -> {endpointZ},
      "TestFunctionSupport" -> <|"ExcludedFaces" -> {endpointZ -> 1}|>
    |>,
    "IntegratedPhaseSpaceVariables" -> {angleY},
    "TwoParticleMeasurement" -> <|
      "ReferenceMomentum" -> pa, "TotalMomentum" -> pTotal, "FinalMomenta" -> {k1, q},
      "InvariantMassSquared" -> Q2/z, "ReferenceProjection" -> Q2/(2 z), "MassesSquared" -> {0, Q2},
      "MeasurementVariable" -> angleY, "EvanescentSquare" -> kappa,
      "MomentumRules" -> {pb -> pTotal - pa}, "Assumptions" -> Q2 > 0 && 0 < z < 1 && 0 < angleY < 1
    |>,
    "BornMomentumRules" -> {q -> pa + pb},
    "BornConstraints" -> {FeynCalc`SPD[pa + pb] - Q2},
    "KinematicRules" -> {
      FeynCalc`SPD[pa] -> 0, FeynCalc`SPD[pb] -> 0, FeynCalc`SPD[pa, pb] -> Q2/(2 z),
      FeynCalc`SP[pa] -> 0, FeynCalc`SP[pb] -> 0, FeynCalc`SP[pa, pb] -> Q2/(2 z)
    },
    "DistributionBasis" -> <|"Axes" -> {
      <|"Variable" -> z, "Endpoint" -> 1, "Interval" -> {0, 1}, "Distance" -> 1 - z, "NormalVariable" -> endpointZ|>
    }|>
  |>,
  "Counterterms" -> <|
    "BareCouplingFactor" -> (4 Pi)^(-Global`Epsilon) Exp[EulerGamma Global`Epsilon],
    "Coupling" -> FeynFacet`\[Alpha]s, "RenormalizationScaleSquared" -> muR2,
    "FactorizationScalesSquared" -> <|"IncomingA" -> muF2, "IncomingB" -> muF2|>,
    "Schemes" -> <|"IncomingA" -> "MSbar", "IncomingB" -> "MSbar"|>,
    "KernelParameters" -> <|"CA" -> FeynCalc`CA, "CF" -> FeynCalc`CF, "TR" -> 1/2, "FlavorCount" -> nU + nD|>
  |>,
  "ColorRules" -> {FeynCalc`CF -> (FeynCalc`CA^2 - 1)/(2 FeynCalc`CA)},
  "ResultEpsilonRanges" -> <|"LO" -> {0, 0}, "NLO" -> {0, 0}|>,
  "BornCouplingPower" -> 0,
  "Execution" -> <|"Kernels" -> 8, "KiraThreads" -> 1, "ReconstructionThreads" -> 8|>,
  "BareSourceContributions" -> <|
    "LO" -> <|
      "q-qb" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0},
          "UnobservedPartons" -> {}
        |>
      |>,
      "qb-q" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0},
          "UnobservedPartons" -> {}
        |>
      |>
    |>,
    "NLO" -> <|
      "g-q" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "UnobservedPartons" -> {{"q", "u"}}
        |>
      |>,
      "g-qb" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "UnobservedPartons" -> {{"qb", "u"}}
        |>
      |>,
      "q-g" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "UnobservedPartons" -> {{"q", "u"}}
        |>
      |>,
      "q-qb" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "UnobservedPartons" -> {"g"}
        |>,
        "Virtual" -> <|
          "Contribution" -> "Virtual",
          "AmplitudeLoops" -> {1, 0},
          "LoopMomenta" -> {{ell}, {}},
          "UnobservedPartons" -> {}
        |>
      |>,
      "qb-g" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "UnobservedPartons" -> {{"qb", "u"}}
        |>
      |>,
      "qb-q" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "UnobservedPartons" -> {"g"}
        |>,
        "Virtual" -> <|
          "Contribution" -> "Virtual",
          "AmplitudeLoops" -> {1, 0},
          "LoopMomenta" -> {{ell}, {}},
          "UnobservedPartons" -> {}
        |>
      |>
    |>
  |>
|>
