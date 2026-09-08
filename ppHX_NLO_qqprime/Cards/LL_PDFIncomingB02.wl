<|"Scale" -> s, "Variables" -> {v, w}, "Coupling" -> \[Alpha]s, 
 "RenormalizationScaleSquared" -> muR2, "KernelParameters" -> 
  <|"CA" -> CA, "CF" -> CF, "TR" -> 1/2, "FlavorCount" -> nD + nU|>, 
 "SplittingVariable" -> xi, "ThroughOrder" -> 0, "Leg" -> "IncomingB", 
 "Daughter" -> {"q", "d"}, "Parent" -> {"q", "d"}, "Spin" -> "L", 
 "Scheme" -> "HelicityMSbar", "SplittingKernel" -> 
  <|"Variable" -> xi, "DeltaCoefficient" -> (3*CF)/2, 
   "PlusCoefficients" -> <|0 -> 2*CF|>, "RegularCoefficient" -> 
    -(CF*(1 + xi)), "Daughter" -> {"q", "d"}, "Parent" -> {"q", "d"}, 
   "Spin" -> "L", "PerturbativeParameter" -> "alpha_s/(2 Pi)", 
   "KernelOrder" -> 0|>, "FiniteKernel" -> <|"Variable" -> xi, 
   "DeltaCoefficient" -> 0, "PlusCoefficients" -> <||>, 
   "RegularCoefficient" -> -4*CF*(1 - xi)|>, 
 "Contribution" -> "PDFCounterterm", "FactorizationScaleSquared" -> muFB2, 
 "BornFile" -> "Results/Born/LL_Born01.wl"|>
