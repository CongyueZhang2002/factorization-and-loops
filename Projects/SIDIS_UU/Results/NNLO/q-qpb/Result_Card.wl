<|
  "ResultType" -> "CompleteCoefficient",
  "EpsilonRange" -> {0, 0},
  "RequireFinite" -> True,
  "Inputs" -> {
    <|"Path" -> "../../../Raw/NNLO/q-qpb/DoubleReal", "Weight" -> 1|>,
    <|"Path" -> "../../../Raw/NNLO/g-qb/Counter-NLO-PDF", "OutputChannel" -> "q-qpb", "Weight" -> 1|>,
    <|"Path" -> "../../../Raw/NNLO/qb-qb/Counter-Born-PDF2", "OutputChannel" -> "q-qpb", "Weight" -> 1|>,
    <|"Path" -> "../../../Raw/NNLO/q-g/Counter-NLO-FF", "OutputChannel" -> "q-qpb", "Weight" -> 1|>,
    <|"Path" -> "../../../Raw/NNLO/q-q/Counter-Born-FF2", "OutputChannel" -> "q-qpb", "Weight" -> 1|>
  },
  "PoleCancellation" -> <|
    "Method" -> "Numerical",
    "ParameterPoints" -> {
      {
        x -> 5/11,
        z -> 3/13,
        Q2 -> 7/3,
        muR2 -> 7/3,
        muF2 -> 7/3,
        muD2 -> 7/3,
        eU -> 2/3,
        eD -> -1/3,
        nU -> 2,
        nD -> 1,
        CA -> 3,
        CF -> 4/3,
        Tf -> 1/2,
        TR -> 1/2,
        \[Alpha]s -> 1
      },
      {
        x -> 4/5,
        z -> 2/3,
        Q2 -> 7/3,
        muR2 -> 5/2,
        muF2 -> 11/5,
        muD2 -> 13/4,
        eU -> 2/3,
        eD -> -1/3,
        nU -> 2,
        nD -> 1,
        CA -> 3,
        CF -> 4/3,
        Tf -> 1/2,
        TR -> 1/2,
        \[Alpha]s -> 1
      }
    },
    "NumericalOptions" -> <|"WorkingPrecision" -> 50, "AbsoluteTolerance" -> 1/1000000000000000000000000000000, "TimeLimit" -> 120|>
  |>,
  "Metadata" -> <|
    "GPLContinuation" -> <|
      "RealLetterPrescription" -> 1,
      "Convention" -> "Continue the complete physically matched coefficient across removable seams with a common positive real-letter prescription."
    |>,
    "PhysicalTestFunctionSupport" -> "Smooth joint test functions with compact support away from x=0 and z=0; the x=1 and z=1 distributions are retained."
  |>
|>
