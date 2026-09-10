<|
  "Contribution" -> "Counterterm",
  "EpsilonRange" -> {-4, 0},
  "BareOperatorSchemes" -> <|"Incoming" -> "MSbar", "Observed" -> "MSbar"|>,
  "Include" -> {"UV", "Incoming", "Observed"},
  "LowerOrderFlavorCovariance" -> "SingleMasslessQuarkLine",
  "MinimumChannelOrders" -> <|"q-q" -> 0, "q-g" -> 1, "qbar-qbar" -> 0, "qbar-g" -> 1, "g-q" -> 1, "g-qbar" -> 1, "q-qbar" -> 2, "qbar-q" -> 2, "q-qp" -> 2, "q-qpbar" -> 2, "qbar-qp" -> 2, "qbar-qpbar" -> 2, "g-g" -> 2|>,
  "LowerOrderResults" -> <|
    "LO" -> <|
      "q-q" -> <|"Contributions" -> <|"Born" -> "../../../LO/q-q/Results/Result.wl"|>, "EpsilonRange" -> {0, 2}|>,
      "qbar-qbar" -> <|"Contributions" -> <|"Born" -> "../../../LO/qbar-qbar/Results/Result.wl"|>, "EpsilonRange" -> {0, 2}|>
    |>,
    "NLO" -> <|
      "q-q" -> <|"Contributions" -> <|"Real" -> "../../../NLO/q-q/Results/Real/Result.wl", "Virtual" -> "../../../NLO/q-q/Results/Virtual/Result.wl"|>, "EpsilonRange" -> {-2, 1}|>,
      "q-g" -> <|"Contributions" -> <|"Real" -> "../../../NLO/q-g/Results/Real/Result.wl"|>, "EpsilonRange" -> {-1, 1}|>,
      "qbar-qbar" -> <|"Contributions" -> <|"Real" -> "../../../NLO/qbar-qbar/Results/Real/Result.wl", "Virtual" -> "../../../NLO/qbar-qbar/Results/Virtual/Result.wl"|>, "EpsilonRange" -> {-2, 1}|>,
      "qbar-g" -> <|"Contributions" -> <|"Real" -> "../../../NLO/qbar-g/Results/Real/Result.wl"|>, "EpsilonRange" -> {-1, 1}|>,
      "g-q" -> <|"Contributions" -> <|"Real" -> "../../../NLO/g-q/Results/Real/Result.wl"|>, "EpsilonRange" -> {-1, 1}|>,
      "g-qbar" -> <|"Contributions" -> <|"Real" -> "../../../NLO/g-qbar/Results/Real/Result.wl"|>, "EpsilonRange" -> {-1, 1}|>
    |>
  |>
|>
