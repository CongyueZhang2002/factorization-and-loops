<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 171, "ContentAddress" -> None, "RepFamily" -> "CF56", 
 "RepRows" -> {3, 6}, "RepBasis" -> 
  {gli["CF56", {1, 1, 1, 1, 1, 1, 0, 1, 0}], 
   gli["CF56", {1, 2, 1, 1, 1, 1, 0, 1, 0}]}, "Dim" -> 2, 
 "Transformation" -> {{(-1 + t)/(1 - 2*t + t^2 - v + 2*t*v), 
    (-1 + t)/(12*(1 - 2*t + t^2 - v + 2*t*v))}, 
   {((-1 + t)*(1 + 4*eps + 4*eps^2 - 4*t - 16*eps*t - 16*eps^2*t + 6*t^2 + 
       24*eps*t^2 + 24*eps^2*t^2 - 4*t^3 - 16*eps*t^3 - 16*eps^2*t^3 + t^4 + 
       4*eps*t^4 + 4*eps^2*t^4 - 2*v - 8*eps*v - 8*eps^2*v + 6*t*v + 
       22*eps*t*v + 20*eps^2*t*v - 6*t^2*v - 20*eps*t^2*v - 16*eps^2*t^2*v + 
       2*t^3*v + 6*eps*t^3*v + 4*eps^2*t^3*v + v^2 + 4*eps*v^2 + 
       4*eps^2*v^2 - 2*t*v^2 - 6*eps*t*v^2 - 4*eps^2*t*v^2 + 2*t^2*v^2 + 
       8*eps*t^2*v^2 + 8*eps^2*t^2*v^2))/((1 + eps)*
      (1 - 2*t + t^2 - v + 2*t*v)^3), 
    ((-1 + t)*(1 + 3*eps + 2*eps^2 - 4*t - 12*eps*t - 8*eps^2*t + 6*t^2 + 
       18*eps*t^2 + 12*eps^2*t^2 - 4*t^3 - 12*eps*t^3 - 8*eps^2*t^3 + t^4 + 
       3*eps*t^4 + 2*eps^2*t^4 - 2*v - 6*eps*v - 4*eps^2*v + 6*t*v + 
       16*eps*t*v + 8*eps^2*t*v - 6*t^2*v - 14*eps*t^2*v - 4*eps^2*t^2*v + 
       2*t^3*v + 4*eps*t^3*v + v^2 + 3*eps*v^2 + 2*eps^2*v^2 - 2*t*v^2 - 
       4*eps*t*v^2 + 2*t^2*v^2 + 8*eps*t^2*v^2 + 8*eps^2*t^2*v^2))/
     (12*(1 + eps)*(1 - 2*t + t^2 - v + 2*t*v)^3)}}, 
 "EpsForm" -> {{{eps*(v^(-1) + 9/(-1 + t + v) - 2/(-1 + 2*t - t^2 + v) - 
       (8*(-1 + 2*t))/(1 - 2*t + t^2 - v + 2*t*v)), 
     eps*((-1 + t + v)^(-1) - 1/(3*(-1 + 2*t - t^2 + v)) - 
       (2*(-1 + 2*t))/(3*(1 - 2*t + t^2 - v + 2*t*v)))}, 
    {eps*(-72/(-1 + t + v) + 24/(-1 + 2*t - t^2 + v) + 
       (48*(-1 + 2*t))/(1 - 2*t + t^2 - v + 2*t*v)), 
     eps*(-8/(-1 + t + v) + 4/(-1 + 2*t - t^2 + v) + 
       (4*(-1 + 2*t))/(1 - 2*t + t^2 - v + 2*t*v))}}, 
   {{eps*(9/(-1 + t) + t^(-1) + 9/(-1 + t + v) - (2*(2 - 2*t))/
        (-1 + 2*t - t^2 + v) - (8*(-2 + 2*t + 2*v))/(1 - 2*t + t^2 - v + 
         2*t*v)), eps*((-1 + t)^(-1) + (-1 + t + v)^(-1) - 
       (2 - 2*t)/(3*(-1 + 2*t - t^2 + v)) - (2*(-2 + 2*t + 2*v))/
        (3*(1 - 2*t + t^2 - v + 2*t*v)))}, 
    {eps*(-72/(-1 + t) - 72/(-1 + t + v) + (24*(2 - 2*t))/
        (-1 + 2*t - t^2 + v) + (48*(-2 + 2*t + 2*v))/(1 - 2*t + t^2 - v + 
         2*t*v)), eps*(-8/(-1 + t) - 8/(-1 + t + v) + 
       (4*(2 - 2*t))/(-1 + 2*t - t^2 + v) + (4*(-2 + 2*t + 2*v))/
        (1 - 2*t + t^2 - v + 2*t*v))}}}, "Variables" -> {v, t}, 
 "Regulator" -> eps, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (-t + t^2 + t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 - 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, -1 + t + v, -1 + 2*t - t^2 + v, 1 - 2*t + t^2 - v + 2*t*v, 
   -1 + t, t}, "Residues" -> {{{1, 0}, {0, 0}}, {{9, 1}, {-72, -8}}, 
   {{-2, -1/3}, {24, 4}}, {{-8, -2/3}, {48, 4}}, {{9, 1}, {-72, -8}}, 
   {{1, 0}, {0, 0}}}, "Certificate" -> <|"Status" -> "Certified", 
   "GateX" -> True, "GateY" -> True, "ConstantResidues" -> True, 
   "Flat" -> True, "Invertible" -> True, 
   "Seconds" -> 0.066238`5.272652204318736|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.01722`4.687578140613609|>, <|"Frame" -> "SlicewShear1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.018312`4.714280773162457|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 2.155355`6.785063804811119|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.034716`4.992074673191581, 
   "SolveSeconds" -> 1.999855`6.752543501668583, 
   "GateSeconds" -> 0.066238`5.272652204318736, 
   "TotalSeconds" -> 2.16934`6.787872617687151|>, 
 "Seconds" -> 2.309622`6.815085901203198, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
