<|
  "Coordinates" -> {x, y},
  "Epsilon" -> ep,
  "InputRules" -> {},
  "BoundaryCharts" -> {
    <|
      "Name" -> "83bb physical x=0, y=0 boundary",
      "Variables" -> {x, y},
      "Map" -> {x -> x, y -> y},
      "Point" -> {x -> 0, y -> 0},
      "EvolutionVariable" -> x,
      "KernelVariables" -> {y},
      "AllowedExponents" -> {0, -ep, -2 ep},
      "Side" -> <|x -> "FromAbove", y -> "FromAbove"|>,
      "Assumptions" ->
        Element[{x, y, ep}, Reals] &&
          x > 0 && y > 0 && x + y < 1 && -1/4 < ep < 0
    |>
  }
|>
