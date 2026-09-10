<|
  "Contribution" -> "DoubleReal",
  "AmplitudeLoops" -> {0, 0},
  "EpsilonRange" -> {-4, 0},
  "Components" -> <|
    "Gluons" -> <|
      "UnobservedPartons" -> {"g", "g"},
      "SymmetryFactor" -> 1/2,
      "UnobservedGluonStates" -> {
        <|"Momentum" -> k2, "Sum" -> "Physical", "ReferenceMomentum" -> p + q|>,
        <|"Momentum" -> k3, "Sum" -> "Covariant"|>
      }
    |>,
    "SameFlavor" -> <|"UnobservedPartons" -> {{"q", "u"}, {"qbar", "u"}}, "SymmetryFactor" -> 1|>,
    "DifferentFlavorUp" -> <|"UnobservedPartons" -> {{"q", "c"}, {"qbar", "c"}}, "SymmetryFactor" -> 1, "FlavorMultiplicity" -> nU - 1|>,
    "DifferentFlavorDown" -> <|"UnobservedPartons" -> {{"q", "d"}, {"qbar", "d"}}, "SymmetryFactor" -> 1, "FlavorMultiplicity" -> nD|>
  |>
|>
