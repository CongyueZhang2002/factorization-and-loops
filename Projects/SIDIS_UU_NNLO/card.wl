<|
  "Project" -> "SIDIS_UU_NNLO",
  "Observable" -> "TransverseMomentumIntegratedElectromagneticSIDIS",
  "StructureFunctions" -> {"2F1", "FL/x"},
  "Orders" -> <|"LO" -> {"q-q", "qbar-qbar"}, "NLO" -> {"q-q", "q-g", "qbar-qbar", "qbar-g", "g-q", "g-qbar"}, "NNLO" -> {"q-q", "q-g", "qbar-qbar", "qbar-g", "g-q", "g-qbar", "q-qbar", "qbar-q", "q-qp", "q-qpbar", "qbar-qp", "qbar-qpbar", "g-g"}|>,
  "Channels" -> <|
    "q-q" -> <|"Incoming" -> {{"q", "u"}}, "Observed" -> {"q", "u"}|>,
    "q-g" -> <|"Incoming" -> {{"q", "u"}}, "Observed" -> "g"|>,
    "qbar-qbar" -> <|"Incoming" -> {{"qbar", "u"}}, "Observed" -> {"qbar", "u"}|>,
    "qbar-g" -> <|"Incoming" -> {{"qbar", "u"}}, "Observed" -> "g"|>,
    "g-q" -> <|"Incoming" -> {"g"}, "Observed" -> {"q", "u"}|>,
    "g-qbar" -> <|"Incoming" -> {"g"}, "Observed" -> {"qbar", "u"}|>,
    "q-qbar" -> <|"Incoming" -> {{"q", "u"}}, "Observed" -> {"qbar", "u"}|>,
    "qbar-q" -> <|"Incoming" -> {{"qbar", "u"}}, "Observed" -> {"q", "u"}|>,
    "q-qp" -> <|"Incoming" -> {{"q", "u"}}, "Observed" -> {"q", "d"}|>,
    "q-qpbar" -> <|"Incoming" -> {{"q", "u"}}, "Observed" -> {"qbar", "d"}|>,
    "qbar-qp" -> <|"Incoming" -> {{"qbar", "u"}}, "Observed" -> {"q", "d"}|>,
    "qbar-qpbar" -> <|"Incoming" -> {{"qbar", "u"}}, "Observed" -> {"qbar", "d"}|>,
    "g-g" -> <|"Incoming" -> {"g"}, "Observed" -> "g"|>
  |>,
  "SpeciesMap" -> <|
    {"q", "u"} -> FeynArts`F[3, {1}], {"qbar", "u"} -> -FeynArts`F[3, {1}],
    {"q", "c"} -> FeynArts`F[3, {2}], {"qbar", "c"} -> -FeynArts`F[3, {2}],
    {"q", "d"} -> FeynArts`F[4, {1}], {"qbar", "d"} -> -FeynArts`F[4, {1}],
    "g" -> FeynArts`V[5], "ghost" -> FeynArts`U[5], "antighost" -> -FeynArts`U[5]
  |>,
  "Current" -> <|
    "Field" -> FeynArts`V[1], "Side" -> "Incoming", "Momentum" -> q, "MomentumSpace" -> "Physical4",
    "Indices" -> <|"Conjugate" -> mu, "Amplitude" -> nu|>, "Coupling" -> FeynCalc`SMP["e"], "Projection" -> "DIS"
  |>,
  "IncomingMomenta" -> {p},
  "FinalMomenta" -> {k1, k2, k3},
  "GluonSpinIndices" -> <|"Incoming" -> {{muGIn, nuGIn}}, "Observed" -> {muGOut, nuGOut}|>,
  "Polarization" -> <|"Incoming" -> {"U"}, "Observed" -> "U"|>,
  "SpinParameters" -> <||>,
  "ProcessDefaults" -> <|
    "Model" -> "SMQCD", "InsertionLevel" -> {FeynArts`Classes},
    "ExcludeTopologies" -> {FeynArts`Tadpoles, FeynArts`WFCorrections},
    "ExcludeParticles" -> {FeynArts`S[_], FeynArts`V[1], FeynArts`V[2], FeynArts`V[3]},
    "MasslessQuarkFlavors" -> <|"UpType" -> nU, "DownType" -> nD|>,
    "ElectromagneticCharges" -> <|"UpType" -> eU, "DownType" -> eD|>
  |>,
  "FlavorClasses" -> <|
    "UpType" -> <|"Members" -> {"u", "c"}, "Multiplicity" -> nU, "Charge" -> eU|>,
    "DownType" -> <|"Members" -> {"d"}, "Multiplicity" -> nD, "Charge" -> eD|>
  |>,
  "BenchmarkParameterRules" -> {eU -> 2/3, eD -> -1/3},
  "Kinematics" -> <|"BornConditions" -> x == 1 && z == 1, "RadiativeConditions" -> 0 < x < 1 && 0 < z < 1|>,
  "Assembly" -> <|
    "FactorizationLegs" -> <|
      "Incoming" -> <|"Role" -> "PDF", "Index" -> 1, "Variable" -> x|>,
      "Observed" -> <|"Role" -> "FF", "Variable" -> z|>
    |>,
    "Scale" -> Q2, "Variables" -> {x, z}, "Assumptions" -> Q2 > 0 && muR2 > 0,
    "Domain" -> Q2 > 0 && 0 < x <= 1 && 0 < z <= 1,
    "DensityConvention" -> "Dimensionless electromagnetic SIDIS coefficient, flavor charge included",
    "CurrentNormalization" -> 1/(4 Pi),
    "EndpointExpansion" -> <|
      "NormalVariables" -> {endpointX, endpointZ},
      "TestFunctionSupport" -> <|"ExcludedFaces" -> {endpointX -> 1, endpointZ -> 1}|>
    |>,
    "BareCouplingRules" -> {FeynCalc`SMP["g_s"]^2 -> 4 Pi FeynFacet`\[Alpha]s muR2^Global`Epsilon (4 Pi)^(-Global`Epsilon) Exp[EulerGamma Global`Epsilon]},
    "MeasuredPhaseSpace" -> <|
      "ReferenceMomentum" -> p, "MeasurementVariable" -> z,
      "ExternalKinematicConditions" -> Q2 > 0 && 0 < x < 1
    |>,
    "JointAngularAverage" -> <|
      "PhysicalMomenta" -> {p, q}, "IntegratedMomenta" -> {k1, k2},
      "MomentumRules" -> {k3 -> p + q - k1 - k2}, "TimelikeMomentum" -> p + q,
      "DimensionalRegulator" -> Global`Epsilon,
      "KinematicRules" -> {FeynCalc`SPD[p] -> 0, FeynCalc`SPD[q] -> -Q2, FeynCalc`SPD[p, q] -> Q2/(2 x)},
      "Assumptions" -> Q2 > 0 && 0 < x < 1 && 0 < z < 1
    |>,
    "TwoParticleMeasurement" -> <|
      "ReferenceMomentum" -> p, "TotalMomentum" -> pTotal, "FinalMomenta" -> {k1, k2},
      "InvariantMassSquared" -> Q2 (1 - x)/x, "ReferenceProjection" -> Q2/(2 x),
      "MeasurementVariable" -> z, "EvanescentSquare" -> kappa,
      "MomentumRules" -> {q -> pTotal - p}, "Assumptions" -> Q2 > 0 && 0 < x < 1 && 0 < z < 1
    |>,
    "BornSupportKinematicRules" -> {FeynCalc`SPD[p] -> 0, FeynCalc`SPD[q] -> -Q2, FeynCalc`SPD[p, q] -> Q2/(2 x)},
    "BornMomentumRules" -> {k1 -> p + q},
    "BornConstraints" -> {FeynCalc`SPD[p + q], z - FeynCalc`SPD[p, k1]/FeynCalc`SPD[p, q]},
    "KinematicRules" -> {
      FeynCalc`SPD[p] -> 0, FeynCalc`SPD[q] -> -Q2, FeynCalc`SPD[p, q] -> Q2/(2 x),
      FeynCalc`SP[p] -> 0, FeynCalc`SP[q] -> -Q2, FeynCalc`SP[p, q] -> Q2/(2 x)
    },
    "DistributionBasis" -> <|"Axes" -> {
      <|"Variable" -> x, "Endpoint" -> 1, "Interval" -> {0, 1}, "Distance" -> 1 - x, "NormalVariable" -> endpointX|>,
      <|"Variable" -> z, "Endpoint" -> 1, "Interval" -> {0, 1}, "Distance" -> 1 - z, "NormalVariable" -> endpointZ|>
    }|>
  |>,
  "Counterterms" -> <|
    "Coupling" -> FeynFacet`\[Alpha]s, "RenormalizationScaleSquared" -> muR2,
    "FactorizationScalesSquared" -> <|"Incoming" -> muF2, "Observed" -> muD2|>,
    "Schemes" -> <|"Incoming" -> "MSbar", "Observed" -> "MSbar"|>,
    "KernelParameters" -> <|"CA" -> FeynCalc`CA, "CF" -> FeynCalc`CF, "TR" -> 1/2, "FlavorCount" -> nU + nD|>
  |>,
  "ColorRules" -> {FeynCalc`CF -> (FeynCalc`CA^2 - 1)/(2 FeynCalc`CA)},
  "ResultEpsilonRanges" -> <|"LO" -> {0, 2}, "NLO" -> {0, 1}, "NNLO" -> {0, 0}|>,
  "BornCouplingPower" -> 0,
  "Execution" -> <|"Kernels" -> 8, "KiraThreads" -> 1, "ReconstructionThreads" -> 8|>
|>
