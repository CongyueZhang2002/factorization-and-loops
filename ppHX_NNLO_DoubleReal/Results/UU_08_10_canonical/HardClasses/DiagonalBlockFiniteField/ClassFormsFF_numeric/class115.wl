<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 115, "ContentAddress" -> None, "RepFamily" -> "CF299", 
 "RepRows" -> {1, 2}, "RepBasis" -> 
  {gli["CF299", {1, 1, 1, 1, 0, 1, 0, 1, 0}], 
   gli["CF299", {1, 1, 1, 1, 0, 1, 0, 2, 0}]}, "Dim" -> 2, 
 "Transformation" -> {{1/((1 + 8*eps)*t), 1/(12*(1 + 8*eps)*t)}, 
   {(1 + 8*eps - 2*eps*t)/((1 + 8*eps)*t^3), (1 + 8*eps - 4*eps*t)/
     (12*(1 + 8*eps)*t^3)}}, "EpsForm" -> {{{0, 0}, {0, 0}}, 
   {{eps*((-1 + t)^(-1) - 16/t + 9/(1 + t)), eps*(-4/(3*t) + (1 + t)^(-1))}, 
    {eps*(96/t - 72/(1 + t)), eps*(8/t - 8/(1 + t))}}}, 
 "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (1 - t^2)/(4*v), "Root" -> t, 
   "Branch" -> "LinearSolve"|>, "Frame" -> "Chart:Slicet", 
 "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {-1 + t, 1 + t, t}, "Residues" -> 
  {{{1, 0}, {0, 0}}, {{9, 1}, {-72, -8}}, {{-16, -4/3}, {96, 8}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.004428`4.0977526057026585|>, 
 "Attempts" -> {<|"Frame" -> "Slicev", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.004175`4.072201473315592|>, <|"Frame" -> "Slicew", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.004282`4.083191656454395|>, <|"Frame" -> "Slicet", "Stage" -> "Gate", 
    "Status" -> "Certified", "Seconds" -> 0.425676`6.080624158445502|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.018594`4.7209178201189, 
   "SolveSeconds" -> 0.399052`6.052574485276938, 
   "GateSeconds" -> 0.004428`4.0977526057026585, 
   "TotalSeconds" -> 0.43836`6.093375911755512|>, 
 "Seconds" -> 0.464721`6.1187372914924945, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
