<|
  "Project" -> "ppHX_LL",
  "Description" -> <|
    "Channel" -> "q qprime -> observed q + X",
    "Polarization" -> <|"Incoming" -> {"L", "L"}, "Observed" -> "U"|>,
    "Fragmentation" -> "D1",
    "Coupling" -> "Physical alpha_s powers included"
  |>,
  "Orders" -> <|
    "LO" -> {
      "g-g_g-g",
      "g-g_u-ub",
      "qg-qg",
      "qqb-qpqpb",
      "qqp-qqp",
      "u-db_u-db",
      "u-g_g-u",
      "u-ub_g-g",
      "u-ub_u-ub",
      "u-u_u-u"
    },
    "NLO" -> {"qg-qg", "qqb-qpqpb", "qqp-qqp", "u-g_g-u"}
  |>,
  "Channels" -> <|
    "qqp-qqp" -> <|"Incoming" -> {{"q", "u"}, {"q", "d"}}, "Observed" -> {"q", "u"}, "Recoil" -> {"q", "d"}|>,
    "qg-qg" -> <|"Incoming" -> {{"q", "u"}, "g"}, "Observed" -> {"q", "u"}, "Recoil" -> "g"|>,
    "qqb-qpqpb" -> <|"Incoming" -> {{"q", "u"}, {"qb", "u"}}, "Observed" -> {"q", "d"}, "Recoil" -> {"qb", "d"}|>,
    "u-ub_g-g" -> <|"Incoming" -> {{"q", "u"}, {"qb", "u"}}, "Observed" -> "g", "Recoil" -> "g"|>,
    "g-g_u-ub" -> <|"Incoming" -> {"g", "g"}, "Observed" -> {"q", "u"}, "Recoil" -> {"qb", "u"}|>,
    "u-u_u-u" -> <|"Incoming" -> {{"q", "u"}, {"q", "u"}}, "Observed" -> {"q", "u"}, "Recoil" -> {"q", "u"}|>,
    "u-ub_u-ub" -> <|"Incoming" -> {{"q", "u"}, {"qb", "u"}}, "Observed" -> {"q", "u"}, "Recoil" -> {"qb", "u"}|>,
    "u-db_u-db" -> <|"Incoming" -> {{"q", "u"}, {"qb", "d"}}, "Observed" -> {"q", "u"}, "Recoil" -> {"qb", "d"}|>,
    "u-g_g-u" -> <|"Incoming" -> {{"q", "u"}, "g"}, "Observed" -> "g", "Recoil" -> {"q", "u"}|>,
    "g-g_g-g" -> <|"Incoming" -> {"g", "g"}, "Observed" -> "g", "Recoil" -> "g"|>
  |>,
  "SpeciesMap" -> <|
    {"q", "u"} -> F[3, {1}],
    {"q", "d"} -> F[4, {1}],
    {"qb", "u"} -> -F[3, {1}],
    {"qb", "d"} -> -F[4, {1}],
    "g" -> V[5],
    "ghost" -> U[5],
    "antighost" -> -U[5]
  |>,
  "IncomingMomenta" -> {ka, kb},
  "FinalMomenta" -> {kc, kd, ke, kf},
  "MasslessFinalState" -> True,
  "ProcessDefaults" -> <|
    "GluonPolarizationReferences" -> <|kc -> ka|>,
    "Model" -> "SMQCD",
    "InsertionLevel" -> {Classes},
    "ExcludeTopologies" -> {Tadpoles, WFCorrections},
    "ExcludeParticles" -> {S[_], V[1], V[2], V[3]},
    "MomentumFraction" -> {xa, xb} -> {zh, Missing["NotApplicable"]},
    "HadronMomentum" -> {Pa, Pb} -> {Ph, Missing["NotApplicable"]},
    "HadronLongDirection" -> {n, nb} -> {nh, Missing["NotApplicable"]},
    "HadronDualDirection" -> {nb, n} -> {nhb, Missing["NotApplicable"]},
    "HadronicVariables" -> <|
      "Coordinates" -> <|
        Pa -> {0, Sqrt[s/(xa*xb)]/Sqrt[2], 0, 0},
        Pb -> {Sqrt[s/(xa*xb)]/Sqrt[2], 0, 0, 0},
        Ph -> {-((t*Sqrt[xb/(s*xa)]*zh)/Sqrt[2]), -((u*Sqrt[xa/(s*xb)]*zh)/Sqrt[2]), Sqrt[(t*u)/s]*zh, 0},
        nh -> {(t*xb)/(u*xa + t*xb), (u*xa)/(u*xa + t*xb), -((Sqrt[2]*Sqrt[t*u*xa*xb])/(u*xa + t*xb)), 0},
        nhb -> {(u*xa)/(u*xa + t*xb), (t*xb)/(u*xa + t*xb), (Sqrt[2]*Sqrt[t*u*xa*xb])/(u*xa + t*xb), 0},
        SThvec -> {
          -((Sqrt[2]*STh*Sqrt[t*u*xa*xb]*Cos[\[Phi]h])/(u*xa + t*xb)),
          (Sqrt[2]*STh*Sqrt[t*u*xa*xb]*Cos[\[Phi]h])/(u*xa + t*xb),
          -((STh*(-(u*xa) + t*xb)*Cos[\[Phi]h])/(u*xa + t*xb)),
          STh*Sin[\[Phi]h]
        },
        STavec -> {0, 0, STa*Cos[phiA], STa*Sin[phiA]},
        STbvec -> {0, 0, STb*Cos[phiB], STb*Sin[phiB]}
      |>
    |>,
    "KinematicMassDimensions" -> <|s -> 2, t -> 2, u -> 2|>,
    "CoefficientKinematics" -> <|
      "PositiveFractions" -> Automatic,
      "LaurentValuation" -> <|xa -> -1, xb -> -1, zh -> -2|>,
      "Scale" -> s,
      "DimensionlessCoordinates" -> <|x -> -(t/s), y -> -(u/s)|>,
      "ForbiddenVariables" -> Automatic,
      "BranchGrammar" -> "PositiveMonomialRoots"
    |>,
    "SetMassZero" -> {Pa, Pb, Ph, ka, kb, kc, kd},
    "MasslessQuarkFlavors" -> <|"UpType" -> nU, "DownType" -> nD|>
  |>,
  "Kinematics" -> <|
    "CommonAssumptions" -> s > 0 && t < 0 && u < 0 && CA > 0 && CF > 0 && \[Alpha]s > 0 && 0 < Epsilon < 1 && Element[s | t | u | ST | STh | \[Phi]a | \[Phi]h, Reals],
    "BornConditions" -> s > 0 && t < 0 && u < 0 && s + t + u == 0,
    "RadiativeConditions" -> s > 0 && t < 0 && u < 0 && s + t + u > 0,
    "BornRegion" -> x > 0 && y > 0 && x + y == 1 && Element[x | y, Reals],
    "RadiativeRegion" -> x > 0 && y > 0 && x + y < 1 && Element[x | y, Reals]
  |>,
  "Assembly" -> <|
    "IntegrationMethod" -> "CutIntegralReduction",
    "CollinearConvolution" -> "InvariantSingleInclusive",
    "FactorizationLegs" -> <|
      "IncomingA" -> <|"Role" -> "PDF", "Index" -> 1, "Variable" -> xi|>,
      "IncomingB" -> <|"Role" -> "PDF", "Index" -> 2, "Variable" -> xi|>,
      "Observed" -> <|"Role" -> "FF", "Variable" -> xi|>
    |>,
    "Scale" -> s,
    "MandelstamVariables" -> {s, t, u},
    "Variables" -> {v, w},
    "Assumptions" -> s > 0 && 0 < v < 1 && muR2 > 0 && Element[nU | nD, Reals],
    "RenormalizationScaleSquared" -> muR2
  |>,
  "Counterterms" -> <|
    "BareCouplingFactor" -> 1,
    "Scale" -> s,
    "Variables" -> {v, w},
    "Coupling" -> \[Alpha]s,
    "RenormalizationScaleSquared" -> muR2,
    "KernelParameters" -> <|"CA" -> CA, "CF" -> CF, "TR" -> 1/2, "FlavorCount" -> nD + nU|>,
    "SplittingVariable" -> xi,
    "Schemes" -> <|"IncomingA" -> "HelicityMSbar", "IncomingB" -> "HelicityMSbar", "Observed" -> "MSbar"|>,
    "FactorizationScalesSquared" -> <|"IncomingA" -> muFA2, "IncomingB" -> muFB2, "Observed" -> muD2|>
  |>,
  "BornCouplingPower" -> 2,
  "FinalAssumptions" -> s > 0 && 0 < v < 1 && 0 < w < 1 && muR2 > 0 && muFA2 > 0 && muFB2 > 0 && muD2 > 0,
  "ColorRules" -> {CF -> (-1 + CA^2)/(2*CA)},
  "Execution" -> <|"Kernels" -> 8, "KiraThreads" -> 1, "ReconstructionThreads" -> 8, "NormalizationKernels" -> 8|>,
  "Polarization" -> <|"Incoming" -> {"L", "L"}, "Observed" -> "U"|>,
  "SpinParameters" -> <|"Helicity" -> {1, 1, 1}, "Transverse" -> {STavec, STbvec, SThvec}|>,
  "FlavorSummation" -> "MasslessQCD",
  "BareSourceContributions" -> <|
    "LO" -> <|
      "g-g_g-g" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "g-g_u-ub" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "qg-qg" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "qqb-qpqpb" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "qqp-qqp" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "u-db_u-db" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "u-g_g-u" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "u-u_u-u" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "u-ub_g-g" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>,
      "u-ub_u-ub" -> <|
        "Born" -> <|
          "Contribution" -> "Born",
          "AmplitudeLoops" -> {0, 0}
        |>
      |>
    |>,
    "NLO" -> <|
      "qg-qg" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "Components" -> <|
    "State01" -> <|"UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}}|>,
    "State02" -> <|
      "UnobservedPartons" -> {{"q", "d"}, {"qb", "d"}},
      "FlavorSum" -> {"d"}
    |>,
    "State03" -> <|"UnobservedPartons" -> {"g", "g"}|>,
    "Ghosts" -> <|"UnobservedPartons" -> {"ghost", "antighost"}|>
  |>
        |>,
        "Virtual" -> <|
          "Contribution" -> "Virtual",
          "AmplitudeLoops" -> {1, 0},
          "LoopMomenta" -> {{ell}, {}}
        |>
      |>,
      "qqb-qpqpb" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "Components" -> <|"State01" -> <|"UnobservedPartons" -> {"g", {"qb", "d"}}|>|>
        |>,
        "Virtual" -> <|
          "Contribution" -> "Virtual",
          "AmplitudeLoops" -> {1, 0},
          "LoopMomenta" -> {{ell}, {}}
        |>
      |>,
      "qqp-qqp" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "Radiation" -> {"g"}
        |>,
        "Virtual" -> <|
          "Contribution" -> "Virtual",
          "AmplitudeLoops" -> {1, 0},
          "LoopMomenta" -> {{ell}, {}}
        |>
      |>,
      "u-g_g-u" -> <|
        "Real" -> <|
          "Contribution" -> "Real",
          "AmplitudeLoops" -> {0, 0},
          "Components" -> <|"State01" -> <|"UnobservedPartons" -> {"g", {"q", "u"}}|>|>
        |>,
        "Virtual" -> <|
          "Contribution" -> "Virtual",
          "AmplitudeLoops" -> {1, 0},
          "LoopMomenta" -> {{ell}, {}}
        |>
      |>
    |>
  |>
|>
