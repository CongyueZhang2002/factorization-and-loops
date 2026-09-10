<|"Scale" -> s, "Variables" -> {v, w}, "Coupling" -> \[Alpha]s, 
 "RenormalizationScaleSquared" -> muR2, "KernelParameters" -> 
  <|"CA" -> CA, "CF" -> CF, "TR" -> 1/2, "FlavorCount" -> nD + nU|>, 
 "SplittingVariable" -> xi, "ThroughOrder" -> 0, "Leg" -> "IncomingB", 
 "Daughter" -> "g", "Parent" -> {"q", "d"}, "Spin" -> "U", 
 "Scheme" -> "MSbar", "SplittingKernel" -> <|"Variable" -> xi, 
   "DeltaCoefficient" -> 0, "PlusCoefficients" -> <||>, 
   "RegularCoefficient" -> (CF*(1 + (1 - xi)^2))/xi, "Daughter" -> "g", 
   "Parent" -> {"q", "d"}, "Spin" -> "U", "PerturbativeParameter" -> 
    "alpha_s/(2 Pi)", "KernelOrder" -> 0|>, 
 "FiniteKernel" -> <|"Variable" -> xi, "DeltaCoefficient" -> 0, 
   "PlusCoefficients" -> <||>, "RegularCoefficient" -> 0|>, 
 "Contribution" -> "PDFCounterterm", "FactorizationScaleSquared" -> muFB2, 
 "BornFile" -> "Results/Born/UU_Born02.wl"|>
