<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 101, "ContentAddress" -> None, "RepFamily" -> "CF259", 
 "RepRows" -> {8, 9}, "RepBasis" -> 
  {gli["CF259", {1, 1, 1, 1, 1, 0, 1, 1, 1}], 
   gli["CF259", {1, 1, 1, 1, 1, 0, 1, 1, 2}]}, "Dim" -> 2, 
 "Transformation" -> {{(2 - 4*t + 2*t^2 - v)/(2*(1 - 2*t + t^2 - v)*v^2), 
    -(1/((1 - 2*t + t^2 - v)*v))}, 
   {(2 + 2*eps - 12*t - 14*eps*t + 30*t^2 + 40*eps*t^2 - 40*t^3 - 
      60*eps*t^3 + 30*t^4 + 50*eps*t^4 - 12*t^5 - 22*eps*t^5 + 2*t^6 + 
      4*eps*t^6 - 4*v - 4*eps*v + 18*t*v + 21*eps*t*v - 30*t^2*v - 
      39*eps*t^2*v + 22*t^3*v + 31*eps*t^3*v - 6*t^4*v - 9*eps*t^4*v + 
      3*v^2 + 4*eps*v^2 - 6*t*v^2 - 7*eps*t*v^2 + 3*t^2*v^2 + 3*eps*t^2*v^2 - 
      v^3 - 2*eps*v^3)/(2*(1 - 2*t + t^2 - v)^3*v^2), 
    (-2 - 4*eps + 6*t + 11*eps*t - 6*t^2 - 9*eps*t^2 + 2*t^3 + eps*t^3 + 
      eps*t^4 + 3*v + 6*eps*v - 6*t*v - 11*eps*t*v + 3*t^2*v + 5*eps*t^2*v - 
      v^2 - 2*eps*v^2)/((1 - 2*t + t^2 - v)^3*v)}}, 
 "EpsForm" -> {{{eps*(1/(2*(1 - 2*t + t^2 - v)) - 2/v + (-1 + t + v)^(-1)), 
     -(eps/(1 - 2*t + t^2 - v))}, {(-3*eps)/(4*(1 - 2*t + t^2 - v)), 
     eps*(3/(2*(1 - 2*t + t^2 - v)) + (-1 + t + v)^(-1))}}, 
   {{eps*((-1 + t)^(-1) + t^(-1) - (-2 + 2*t)/(2*(1 - 2*t + t^2 - v)) + 
       (-1 + t + v)^(-1)), eps*(-2/(-1 + t) + (-2 + 2*t)/
        (1 - 2*t + t^2 - v))}, 
    {eps*(-3/(2*(-1 + t)) + (3*(-2 + 2*t))/(4*(1 - 2*t + t^2 - v))), 
     eps*(-(-1 + t)^(-1) + t^(-1) - (3*(-2 + 2*t))/(2*(1 - 2*t + t^2 - v)) + 
       (-1 + t + v)^(-1))}}}, "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (-t + t^2 + t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 - 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, -1 + t + v, 1 - 2*t + t^2 - v, -1 + t, t}, 
 "Residues" -> {{{-2, 0}, {0, 0}}, {{1, 0}, {0, 1}}, 
   {{-1/2, 1}, {3/4, -3/2}}, {{1, -2}, {-3/2, -1}}, {{1, 0}, {0, 1}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.049912`5.149749966118282|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.011109`4.49721996026508|>, <|"Frame" -> "SlicewShear1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.012255`4.539858309084072|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 2.752821`6.891322966153503|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.064768`5.26290547998364, 
   "SolveSeconds" -> 2.592981`6.8653443279956035, 
   "GateSeconds" -> 0.049912`5.149749966118282, 
   "TotalSeconds" -> 2.763884`6.893064805274447|>, 
 "Seconds" -> 2.866555`6.908905272405323, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
