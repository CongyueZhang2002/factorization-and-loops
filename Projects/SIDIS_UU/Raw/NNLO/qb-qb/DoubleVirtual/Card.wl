<|
  "Contribution" -> "DoubleVirtual",
  "UnobservedPartons" -> {},
  "EpsilonRange" -> {-4, 0},
  "Assembly" -> <|
    "ScalarIntegralLibrary" -> <|"Name" -> "MasslessTwoLoopVertex", "NullMomenta" -> {-p, p + q}, "ScaleSquared" -> Q2|>,
    "JointAngularAverage" -> <|
      "IntegratedMomenta" -> {ell1, ell2},
      "MomentumRules" -> {k1 -> p + q},
      "TimelikeMomentum" -> 2 p + q,
      "KinematicRules" -> {FeynCalc`SPD[p] -> 0, FeynCalc`SPD[q] -> -Q2, FeynCalc`SPD[p, q] -> Q2/2},
      "Assumptions" -> Q2 > 0
    |>,
    "KinematicRules" -> {FeynCalc`SPD[p] -> 0, FeynCalc`SPD[q] -> -Q2, FeynCalc`SPD[p, q] -> Q2/2}
  |>,
  "Components" -> <|
    "TwoLoopInterference" -> <|"AmplitudeLoops" -> {2, 0}, "LoopMomenta" -> {{ell1, ell2}, {}}|>,
    "OneLoopSquared" -> <|"AmplitudeLoops" -> {1, 1}, "LoopMomenta" -> {{ell1}, {ell2}}|>
  |>
|>
