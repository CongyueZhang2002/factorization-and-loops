<|
  "Contribution" -> "DoubleReal", "AmplitudeLoops" -> {0, 0},
  "EpsilonRange" -> {-4, 0},
  "Assembly" -> <|"Reduction" -> <|"MaximumSeedIterations" -> 16,
    "MaximumNewSeedsPerIteration" -> 10000|>|>,
  "Components" -> <|
    "Gluons" -> <|
      "UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}, "g", "g"}, "FlavorSum" -> {"u"},
      "UnobservedGluonStates" -> {
        <|"Momentum" -> k3, "Sum" -> "Physical", "ReferenceMomentum" -> k1|>,
        <|"Momentum" -> k4, "Sum" -> "Covariant"|>
      }
    |>,
    "IdenticalQuarks" -> <|
      "UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}, {"q", "u"}, {"qb", "u"}},
      "FlavorSum" -> {"u"}
    |>,
    "DifferentQuarks" -> <|
      "UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}, {"q", "c"}, {"qb", "c"}},
      "FlavorSum" -> {"u", "c"}
    |>
  |>
|>
