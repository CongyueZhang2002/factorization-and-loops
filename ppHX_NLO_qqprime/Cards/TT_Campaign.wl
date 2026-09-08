<|"Name" -> "TT", "BornCard" -> "TT_Born", "RealCard" -> "TT_Real", 
 "VirtualCard" -> "TT_Virtual", "ReducedResults" -> 
  <|"Real" -> "TT_RealReduced", "Virtual" -> "TT_VirtualComplete"|>, 
 "Channel" -> <|"Incoming" -> {{"q", "u"}, {"q", "d"}}, 
   "Observed" -> {"q", "u"}|>, "SpeciesMap" -> <|{"q", "u"} -> F[3, {1}], 
   {"q", "d"} -> F[4, {1}], {"qbar", "u"} -> -F[3, {1}], 
   {"qbar", "d"} -> -F[4, {1}], "g" -> V[5]|>, "IncomingSpins" -> {"T", "T"}, 
 "Schemes" -> <|"IncomingA" -> "MSbar", "IncomingB" -> "MSbar", 
   "Observed" -> "MSbar"|>, "FactorizationScalesSquared" -> 
  <|"IncomingA" -> muFA2, "IncomingB" -> muFB2, "Observed" -> muD2|>, 
 "CountertermParameters" -> <|"Scale" -> s, "Variables" -> {v, w}, 
   "Coupling" -> \[Alpha]s, "RenormalizationScaleSquared" -> muR2, 
   "KernelParameters" -> <|"CA" -> CA, "CF" -> CF, "TR" -> 1/2, 
     "FlavorCount" -> nD + nU|>, "SplittingVariable" -> xi, 
   "ThroughOrder" -> 0|>, "AssemblyRequest" -> 
  <|"Scale" -> s, "MandelstamVariables" -> {s, t, u}, "Variables" -> {v, w}, 
   "KinematicConditions" -> s > 0 && t < 0 && u < 0 && s + t + u > 0, 
   "Assumptions" -> s > 0 && 0 < v < 1 && muR2 > 0 && 
     Element[nU | nD, Reals], "RenormalizationScaleSquared" -> muR2, 
   "EndpointConditions" -> <|"NoInteriorSingularities" -> True, 
     "UniformEpsilonExpansionOnCompactSubsets" -> True, 
     "RepresentationValidOnHalfOpenInterval" -> True|>|>, 
 "VirtualKinematicConditions" -> s > 0 && t < 0 && u < 0 && s + t + u == 0, 
 "FinalAssumptions" -> s > 0 && 0 < v < 1 && 0 < w < 1 && muR2 > 0 && 
   muFA2 > 0 && muFB2 > 0 && muD2 > 0, 
 "ColorRules" -> {CF -> (-1 + CA^2)/(2*CA)}, 
 "Output" -> "TT_HardFunction.wl", "Description" -> 
  <|"Channel" -> "q qprime -> observed q + X", "IncomingPolarization" -> 
    {"T", "T"}, "Fragmentation" -> "D1", "Coupling" -> 
    "Physical alpha_s powers included", "ValidationStatus" -> "Exact pole \
cancellation; external finite reference comparison separately recorded"|>|>
