<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 91, "ContentAddress" -> None, "RepFamily" -> "CF248", 
 "RepRows" -> {3, 15}, "RepBasis" -> 
  {gli["CF248", {1, 1, 1, 1, 1, 1, 0, 1, 0}], 
   gli["CF248", {1, 2, 1, 1, 1, 1, 0, 1, 0}]}, "Dim" -> 2, 
 "Transformation" -> 
  {{-(((1 + eps)*(-1 + t))/((1 + 2*eps)*v^2*(-1 + t^2 + v))), 
    ((1 + eps)*(-1 + t))/(4*(1 + 2*eps)*v^2*(-1 + t^2 + v))}, 
   {((-1 + t)*(1 + 4*eps - 2*t - 10*eps*t + 2*t^2 + 10*eps*t^2 - 2*t^3 - 
       6*eps*t^3 + t^4 + 2*eps*t^4 - 2*v - 8*eps*v + 2*t*v + 10*eps*t*v - 
       2*eps*t^2*v + v^2 + 4*eps*v^2))/(v^3*(-1 + t^2 + v)^3), 
    -1/4*((-1 + t)*(1 + 5*eps - 2*t - 12*eps*t + 2*t^2 + 10*eps*t^2 - 2*t^3 - 
        4*eps*t^3 + t^4 + eps*t^4 - 2*v - 10*eps*v + 2*t*v + 12*eps*t*v - 
        2*eps*t^2*v + v^2 + 5*eps*v^2))/(v^3*(-1 + t^2 + v)^3)}}, 
 "EpsForm" -> {{{eps*(-2/v + (-1 + t + v)^(-1) - 2/(-1 + 2*t - t^2 + v) - 
       8/(-1 + t^2 + v)), eps*((-1 + 2*t - t^2 + v)^(-1) + 
       2/(-1 + t^2 + v))}, {eps*(-8/(-1 + 2*t - t^2 + v) - 
       16/(-1 + t^2 + v)), eps*(-2/v + 4/(-1 + 2*t - t^2 + v) + 
       4/(-1 + t^2 + v))}}, 
   {{eps*(9/(-1 + t) + 9/t + (-1 + t + v)^(-1) - (2*(2 - 2*t))/
        (-1 + 2*t - t^2 + v) - (16*t)/(-1 + t^2 + v)), 
     eps*(-3/(-1 + t) - 3/t + (2 - 2*t)/(-1 + 2*t - t^2 + v) + 
       (4*t)/(-1 + t^2 + v))}, 
    {eps*(24/(-1 + t) + 24/t - (8*(2 - 2*t))/(-1 + 2*t - t^2 + v) - 
       (32*t)/(-1 + t^2 + v)), eps*(-8/(-1 + t) - 8/t + 
       (4*(2 - 2*t))/(-1 + 2*t - t^2 + v) + (8*t)/(-1 + t^2 + v))}}}, 
 "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (t - t^2 - t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 + 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, -1 + t + v, -1 + 2*t - t^2 + v, -1 + t^2 + v, -1 + t, t}, 
 "Residues" -> {{{-2, 0}, {0, -2}}, {{1, 0}, {0, 0}}, {{-2, 1}, {-8, 4}}, 
   {{-8, 2}, {-16, 4}}, {{9, -3}, {24, -8}}, {{9, -3}, {24, -8}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.052365`5.170586101365833|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear-1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.011559`4.514465257228636|>, <|"Frame" -> "SlicewShear-1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.009762`4.441083796816473|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 3.241103`6.962237826324189|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.13053`5.567255331508354, 
   "SolveSeconds" -> 2.993265`6.927690161035486, 
   "GateSeconds" -> 0.052365`5.170586101365833, 
   "TotalSeconds" -> 3.254087`6.963974153379797|>, 
 "Seconds" -> 3.36161`6.978092320483826, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
