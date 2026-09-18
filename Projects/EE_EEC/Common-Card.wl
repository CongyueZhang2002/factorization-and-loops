<|
  "Project" -> "EE_EEC",
  "Observable" -> "EnergyEnergyCorrelation",
  "StructureFunctions" -> {"Scalar"},
  "Orders" -> <|"LO" -> {"q-qb"}, "NLO" -> {"q-qb"}, "NNLO" -> {"q-qb"}|>,
  "Channels" -> <|"q-qb" -> <|"Incoming" -> {}|>|>,
  "MinimumChannelOrders" -> <|"q-qb" -> 0|>, "LowerOrderFlavorCovariance" -> "Identity",
  "BareOperatorSchemes" -> <||>,
  "BareSourceContributions" -> <|
    "LO" -> <|"q-qb" -> <|"Born" -> <|
      "Contribution" -> "Born", "AmplitudeLoops" -> {0, 0},
      "UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}}, "FlavorSum" -> {"u"}
    |>|>|>,
    "NLO" -> <|"q-qb" -> <|
      "Real" -> <|
        "Contribution" -> "Real", "AmplitudeLoops" -> {0, 0},
        "UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}, "g"}, "FlavorSum" -> {"u"}
      |>,
      "Virtual" -> <|
        "Contribution" -> "Virtual", "AmplitudeLoops" -> {1, 0}, "LoopMomenta" -> {{ell}, {}},
        "UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}}, "FlavorSum" -> {"u"}
      |>
    |>|>
  |>,
  "SpeciesMap" -> <|
    {"q", "u"} -> FeynArts`F[3, {1}], {"qb", "u"} -> -FeynArts`F[3, {1}],
    {"q", "c"} -> FeynArts`F[3, {2}], {"qb", "c"} -> -FeynArts`F[3, {2}],
    "g" -> FeynArts`V[5]
  |>,
  "Current" -> <|
    "Field" -> FeynArts`V[1], "Side" -> "Incoming", "Momentum" -> q, "MomentumSpace" -> "IntegratedD",
    "Indices" -> <|"Conjugate" -> mu, "Amplitude" -> nu|>, "Coupling" -> FeynCalc`SMP["e"]
  |>,
  "IncomingMomenta" -> {}, "FinalMomenta" -> {k1, k2, k3, k4},
  "Polarization" -> <|"Incoming" -> {}, "Observed" -> "U"|>, "SpinParameters" -> <||>,
  "ProcessDefaults" -> <|
    "Model" -> "SMQCD", "InsertionLevel" -> {FeynArts`Classes},
    "ExcludeTopologies" -> {FeynArts`Tadpoles, FeynArts`WFCorrections},
    "ExcludeParticles" -> {FeynArts`S[_], FeynArts`V[1], FeynArts`V[2], FeynArts`V[3]},
    "MasslessQuarkFlavors" -> <|"UpType" -> nf, "DownType" -> 0|>,
    "ElectromagneticCharges" -> <|"UpType" -> 1, "DownType" -> 1|>
  |>,
  "Kinematics" -> <|"BornConditions" -> Q2 > 0, "RadiativeConditions" -> Q2 > 0 && 0 < z < 1|>,
  "Assembly" -> <|
    "IntegrationMethod" -> "PolynomialMeasurement", "MeasurementInterval" -> {0, 1},
    "FactorizationLegs" -> <||>,
    "DistributionBasis" -> <|"Representation" -> "UnitInterval", "Variable" -> z, "Interval" -> {0, 1}, "Endpoints" -> {0, 1}|>,
    "Variables" -> {z}, "Scale" -> Q2, "Assumptions" -> Q2 > 0 && muR2 > 0 && nf > 0 && FeynCalc`CA > 1 && FeynCalc`CF > 0,
    "CurrentProjectors" -> <|"Scalar" -> FeynFacet`VectorCurrentPolarizationSum[q, {mu, nu}]|>,
    "KinematicRules" -> {FeynCalc`SPD[q] -> Q2},
    "PhaseSpace" -> <|
      "TotalMomentum" -> q, "ExternalMomenta" -> {q},
      "KinematicRules" -> {FeynCalc`SPD[q] -> Q2}, "Assumptions" -> Q2 > 0
    |>,
    "FinalStateMeasurement" -> <|
      "Arguments" -> {pa, pb}, "Variable" -> z,
      "Observable" -> Q2 FeynCalc`SPD[pa, pb]/(2 FeynCalc`SPD[q, pa] FeynCalc`SPD[q, pb]),
      "Weight" -> FeynCalc`SPD[q, pa] FeynCalc`SPD[q, pb]/Q2^2,
      "Tuples" -> <|"Ordered" -> True, "IncludeRepeated" -> True|>
    |>,
    "DensityConvention" -> "Ordered energy-weighted final-state pairs; dSigma/dz; all final-state momenta integrated",
    "ObservableNormalization" -> <|"Tensor" -> "CutTensor", "Coefficient" -> "TensorProjection"|>
  |>,
  "Counterterms" -> <|
    "BareCouplingFactor" -> (4 Pi)^(-Global`Epsilon) Exp[EulerGamma Global`Epsilon],
    "Coupling" -> FeynFacet`\[Alpha]s, "RenormalizationScaleSquared" -> muR2,
    "FactorizationScalesSquared" -> <||>, "Schemes" -> <||>,
    "KernelParameters" -> <|"CA" -> FeynCalc`CA, "CF" -> FeynCalc`CF, "TR" -> 1/2, "FlavorCount" -> nf|>
  |>,
  "ColorRules" -> {}, "BornCouplingPower" -> 0,
  "Execution" -> <|"Kernels" -> 1, "KiraThreads" -> 8, "ReconstructionThreads" -> 8|>
|>
