<|
  "Project" -> "ppHX_TT_SpinTransfer_NLO",
  "Description" -> <|
    "Channel" -> "q qprime -> observed q + X",
    "Polarization" -> <|"Incoming" -> {"T", "U"}, "Observed" -> "T"|>,
    "Fragmentation" -> "H1",
    "Coupling" -> "Physical alpha_s powers included"
  |>,
  "Orders" -> <|"LO" -> {"qqp-qqp", "qg-qg"}, "NLO" -> {"qqp-qqp"}|>,
  "Channels" -> <|
    "qqp-qqp" -> <|"Incoming" -> {{"q", "u"}, {"q", "d"}}, "Observed" -> {"q", "u"}, "Recoil" -> {"q", "d"}|>,
    "qg-qg" -> <|"Incoming" -> {{"q", "u"}, "g"}, "Observed" -> {"q", "u"}, "Recoil" -> "g"|>
  |>,
  "SpeciesMap" -> <|
    {"q", "u"} -> F[3, {1}],
    {"q", "d"} -> F[4, {1}],
    {"qbar", "u"} -> -F[3, {1}],
    {"qbar", "d"} -> -F[4, {1}],
    "g" -> V[5],
    "ghost" -> U[5],
    "antighost" -> -U[5]
  |>,
  "IncomingMomenta" -> {ka, kb},
  "FinalMomenta" -> {kc, kd, ke, kf},
  "MasslessFinalState" -> True,
  "ProcessDefaults" -> <|
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
    "CommonAssumptions" -> s > 0 && t < 0 && u < 0 && CA > 0 && CF > 0 && \[Alpha]s > 0 && 0 < Epsilon < 1 && Element[s | t | u | ST | STh | \[Phi]a | \[Phi]h, Reals] && Element[STa | STb | phiA | phiB, Reals],
    "BornConditions" -> s > 0 && t < 0 && u < 0 && s + t + u == 0,
    "RadiativeConditions" -> s > 0 && t < 0 && u < 0 && s + t + u > 0,
    "BornRegion" -> x > 0 && y > 0 && x + y == 1 && Element[x | y, Reals],
    "RadiativeRegion" -> x > 0 && y > 0 && x + y < 1 && Element[x | y, Reals]
  |>,
  "Assembly" -> <|
    "Scale" -> s,
    "MandelstamVariables" -> {s, t, u},
    "Variables" -> {v, w},
    "Assumptions" -> s > 0 && 0 < v < 1 && muR2 > 0 && Element[nU | nD, Reals],
    "RenormalizationScaleSquared" -> muR2,
    "EndpointConditions" -> <|
      "NoInteriorSingularities" -> True,
      "UniformEpsilonExpansionOnCompactSubsets" -> True,
      "RepresentationValidOnHalfOpenInterval" -> True
    |>
  |>,
  "Counterterms" -> <|
    "Scale" -> s,
    "Variables" -> {v, w},
    "Coupling" -> \[Alpha]s,
    "RenormalizationScaleSquared" -> muR2,
    "KernelParameters" -> <|"CA" -> CA, "CF" -> CF, "TR" -> 1/2, "FlavorCount" -> nD + nU|>,
    "SplittingVariable" -> xi,
    "Schemes" -> <|"IncomingA" -> "MSbar", "IncomingB" -> "MSbar", "Observed" -> "MSbar"|>,
    "FactorizationScalesSquared" -> <|"IncomingA" -> muFA2, "IncomingB" -> muFB2, "Observed" -> muD2|>
  |>,
  "BornCouplingPower" -> 2,
  "FinalAssumptions" -> s > 0 && 0 < v < 1 && 0 < w < 1 && muR2 > 0 && muFA2 > 0 && muFB2 > 0 && muD2 > 0,
  "ColorRules" -> {CF -> (-1 + CA^2)/(2*CA)},
  "Execution" -> <|"Kernels" -> 8, "KiraThreads" -> 1, "ReconstructionThreads" -> 8, "NormalizationKernels" -> 8|>,
  "Polarization" -> <|"Incoming" -> {"T", "U"}, "Observed" -> "T"|>,
  "SpinParameters" -> <|"Helicity" -> {1, 1, 1}, "Transverse" -> {STavec, STbvec, SThvec}|>
|>
