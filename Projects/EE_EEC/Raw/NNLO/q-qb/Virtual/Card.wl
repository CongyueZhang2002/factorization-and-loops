<|
  "Contribution" -> "Virtual", "EpsilonRange" -> {-4, 0},
  "UnobservedPartons" -> {{"q", "u"}, {"qb", "u"}}, "FlavorSum" -> {"u"},
  "Components" -> <|
    "TwoLoop" -> <|"AmplitudeLoops" -> {2, 0}, "LoopMomenta" -> {{ell1, ell2}, {}}|>,
    "OneLoopSquared" -> <|"AmplitudeLoops" -> {1, 1}, "LoopMomenta" -> {{ell1}, {ell2}}|>,
    "LoopInducedGluons" -> <|
      "AmplitudeLoops" -> {1, 1}, "LoopMomenta" -> {{ell1}, {ell2}},
      "UnobservedPartons" -> {"g", "g"}, "FlavorSum" -> {},
      "UnobservedGluonStates" -> {
        <|"Momentum" -> k1, "Sum" -> "Physical", "ReferenceMomentum" -> q|>,
        <|"Momentum" -> k2, "Sum" -> "Covariant"|>
      }
    |>
  |>
|>
