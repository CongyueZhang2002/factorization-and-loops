<|
  "Contribution" -> "DoubleReal",
  "AmplitudeLoops" -> {0, 0},
  "EpsilonRange" -> {-4, 0},
  "CoefficientReconstruction" -> <|
    "SourceNormalization" -> <|
      "MomentumSpaceConvention" -> "AMFlow", "VirtualMeasure" -> "d^D l/(i pi^(D/2))",
      "CutMeasure" -> "Standard Lorentz-invariant phase space",
      "CutPowers" -> "theta(q^0) (-1)^(a-1) delta^(a-1)(q^2)/(a-1)!"
    |>,
    "KinematicRules" -> {
      Global`x -> Global`vEndpoint, Global`y -> 1 - Global`vEndpoint - Global`zEndpoint,
      Global`v -> Global`vEndpoint, Global`w -> 1 - Global`vEndpoint - Global`zEndpoint
    },
    "Assumptions" -> 0 < Global`vEndpoint < 1/3 && FeynCalc`CA > 1 && FeynCalc`CF > 0
  |>,
  "Components" -> <|
    "Gluons" -> <|"Radiation" -> {"g", "g"}|>,
    "Ghosts" -> <|"Radiation" -> {"ghost", "antighost"}|>
  |>
|>
