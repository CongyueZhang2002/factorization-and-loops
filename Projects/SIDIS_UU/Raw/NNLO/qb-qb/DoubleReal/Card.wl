<|
  "Contribution" -> "DoubleReal",
  "AmplitudeLoops" -> {0, 0},
  "EpsilonRange" -> {-4, 0},
  "Components" -> <|
    "Gluons" -> <|
      "UnobservedPartons" -> {"g", "g"},
      "UnobservedGluonStates" -> {
        <|"Momentum" -> k2, "Sum" -> "Physical", "ReferenceMomentum" -> p + q|>,
        <|"Momentum" -> k3, "Sum" -> "Covariant"|>
      }
    |>,
    "SameFlavor" -> <|"UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}}|>,
    "DifferentFlavorUp" -> <|"UnobservedPartons" -> {{"q", "c"}, {"qb", "c"}}, "FlavorSum" -> {"c"}|>,
    "DifferentFlavorDown" -> <|"UnobservedPartons" -> {{"q", "d"}, {"qb", "d"}}, "FlavorSum" -> {"d"}|>
  |>
|>
