<|
  "Coordinates" -> {v, w},
  "Epsilon" -> eps,
  "InputRules" -> {x -> v, y -> w, ep -> eps},
  "BoundaryCharts" -> {
    <|
      "Name" -> "v=0, w=0; evolve v",
      "Variables" -> {rho, sigma},
      "Map" -> {v -> rho, w -> sigma},
      "Point" -> {rho -> 0, sigma -> 0},
      "EvolutionVariable" -> rho,
      "KernelVariables" -> {sigma},
      "Side" -> <|rho -> "FromAbove", sigma -> "FromAbove"|>,
      "Assumptions" ->
        Element[{rho, sigma, eps}, Reals] &&
          rho > 0 && sigma > 0 && rho + sigma < 1 && -1/4 < eps < 0
    |>,
    <|
      "Name" -> "v=0, w=0; evolve w",
      "Variables" -> {rho, sigma},
      "Map" -> {v -> sigma, w -> rho},
      "Point" -> {rho -> 0, sigma -> 0},
      "EvolutionVariable" -> rho,
      "KernelVariables" -> {sigma},
      "Side" -> <|rho -> "FromAbove", sigma -> "FromAbove"|>,
      "Assumptions" ->
        Element[{rho, sigma, eps}, Reals] &&
          rho > 0 && sigma > 0 && rho + sigma < 1 && -1/4 < eps < 0
    |>,
    <|
      "Name" -> "v=0, v+w=1; evolve v",
      "Variables" -> {rho, sigma},
      "Map" -> {v -> rho, w -> 1 - rho - sigma},
      "Point" -> {rho -> 0, sigma -> 0},
      "EvolutionVariable" -> rho,
      "KernelVariables" -> {sigma},
      "Side" -> <|rho -> "FromAbove", sigma -> "FromAbove"|>,
      "Assumptions" ->
        Element[{rho, sigma, eps}, Reals] &&
          rho > 0 && sigma > 0 && rho + sigma < 1 && -1/4 < eps < 0
    |>,
    <|
      "Name" -> "v=0, v+w=1; evolve 1-v-w",
      "Variables" -> {rho, sigma},
      "Map" -> {v -> sigma, w -> 1 - rho - sigma},
      "Point" -> {rho -> 0, sigma -> 0},
      "EvolutionVariable" -> rho,
      "KernelVariables" -> {sigma},
      "Side" -> <|rho -> "FromAbove", sigma -> "FromAbove"|>,
      "Assumptions" ->
        Element[{rho, sigma, eps}, Reals] &&
          rho > 0 && sigma > 0 && rho + sigma < 1 && -1/4 < eps < 0
    |>,
    <|
      "Name" -> "w=0, v+w=1; evolve w",
      "Variables" -> {rho, sigma},
      "Map" -> {v -> 1 - rho - sigma, w -> rho},
      "Point" -> {rho -> 0, sigma -> 0},
      "EvolutionVariable" -> rho,
      "KernelVariables" -> {sigma},
      "Side" -> <|rho -> "FromAbove", sigma -> "FromAbove"|>,
      "Assumptions" ->
        Element[{rho, sigma, eps}, Reals] &&
          rho > 0 && sigma > 0 && rho + sigma < 1 && -1/4 < eps < 0
    |>,
    <|
      "Name" -> "w=0, v+w=1; evolve 1-v-w",
      "Variables" -> {rho, sigma},
      "Map" -> {v -> 1 - rho - sigma, w -> sigma},
      "Point" -> {rho -> 0, sigma -> 0},
      "EvolutionVariable" -> rho,
      "KernelVariables" -> {sigma},
      "Side" -> <|rho -> "FromAbove", sigma -> "FromAbove"|>,
      "Assumptions" ->
        Element[{rho, sigma, eps}, Reals] &&
          rho > 0 && sigma > 0 && rho + sigma < 1 && -1/4 < eps < 0
    |>
  }
|>
