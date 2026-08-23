<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 130, "ContentAddress" -> None, "RepFamily" -> "CF319", 
 "RepRows" -> {18, 19, 20}, "RepBasis" -> 
  {gli["CF319", {1, 1, 1, 0, 0, 0, 1, 1, 1}], 
   gli["CF319", {1, 1, 1, 0, 0, 0, 1, 1, 2}], 
   gli["CF319", {1, 1, 1, 0, 0, 0, 1, 2, 1}]}, "Dim" -> 3, 
 "Transformation" -> {{(-1 + t)/(eps*(1 - 2*t + t^2 - v)*v), 
    (1 - t)/(2*eps*(1 - 2*t + t^2 - v)*v), 
    (1 - t)/(2*eps*(1 - 2*t + t^2 - v)*v)}, 
   {-(((-1 + t)*(-1 + t^2 + v))/(t*(1 - 2*t + t^2 - v)*v*(-1 + t + v))), 
    ((-1 + t)*(-2 + 2*t + v))/((1 - 2*t + t^2 - v)*(-1 + t + v)*
      (1 - 2*t + t^2 + t*v)), ((-1 + t)*(1 - 4*t + 6*t^2 - 4*t^3 + t^4 - v - 
       t*v + t^2*v + t^3*v + t*v^2))/(2*t*(1 - 2*t + t^2 - v)*v*(-1 + t + v)*
      (1 - 2*t + t^2 + t*v))}, 
   {(1 - 2*t + t^2 + v)/((1 - 2*t + t^2 - v)*v^2), 
    -(1/((1 - 2*t + t^2 - v)*v)), (-1 + 2*t - t^2 - v)/
     (2*(1 - 2*t + t^2 - v)*v^2)}}, 
 "EpsForm" -> {{{eps*(2/(1 - 2*t + t^2 - v) - 2/v + (-1 + t + v)^(-1)), 
     eps*(-(1 - 2*t + t^2 - v)^(-1) - t/(1 - 2*t + t^2 + t*v)), 
     eps*(-(1 - 2*t + t^2 - v)^(-1) - t/(1 - 2*t + t^2 + t*v))}, 
    {(-4*eps)/v, eps*(2/v + (-1 + t + v)^(-1) - (2*t)/(1 - 2*t + t^2 + t*v)), 
     eps*(4/v - (2*t)/(1 - 2*t + t^2 + t*v))}, {(2*eps)/(-1 + t + v), 
     (-2*eps)/(-1 + t + v), eps*(-2/v - 2/(-1 + t + v))}}, 
   {{eps*(5/(-1 + t) - t^(-1) - (2*(-2 + 2*t))/(1 - 2*t + t^2 - v) + 
       (-1 + t + v)^(-1)), eps*((-2 + 2*t)/(1 - 2*t + t^2 - v) - 
       (-2 + 2*t + v)/(1 - 2*t + t^2 + t*v)), 
     eps*(-t^(-1) + (-2 + 2*t)/(1 - 2*t + t^2 - v) - 
       (-2 + 2*t + v)/(1 - 2*t + t^2 + t*v))}, {(8*eps)/(-1 + t), 
     eps*(-3/(-1 + t) + t^(-1) + (-1 + t + v)^(-1) - (2*(-2 + 2*t + v))/
        (1 - 2*t + t^2 + t*v)), eps*(-2/(-1 + t) - (2*(-2 + 2*t + v))/
        (1 - 2*t + t^2 + t*v))}, {eps*(-2/(-1 + t) - 2/t + 2/(-1 + t + v)), 
     eps*(2/(-1 + t) - 2/(-1 + t + v)), eps*(2/(-1 + t) - 2/(-1 + t + v))}}}, 
 "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (-t + t^2 + t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 - 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {1 - 2*t + t^2 - v, v, -1 + t + v, 1 - 2*t + t^2 + t*v, -1 + t, 
   t}, "Residues" -> {{{-2, 1, 1}, {0, 0, 0}, {0, 0, 0}}, 
   {{-2, 0, 0}, {-4, 2, 4}, {0, 0, -2}}, {{1, 0, 0}, {0, 1, 0}, {2, -2, -2}}, 
   {{0, -1, -1}, {0, -2, -2}, {0, 0, 0}}, {{5, 0, 0}, {8, -3, -2}, 
    {-2, 2, 2}}, {{-1, 0, -1}, {0, 1, 0}, {-2, 0, 0}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.121558`5.5363285394933035|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.033613`4.978052268991399|>, <|"Frame" -> "SlicewShear1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.03071`4.938824809939041|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 5.548122`7.195690995887173|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.226982`5.8075364118757555, 
   "SolveSeconds" -> 5.089187`7.158193402627478, 
   "GateSeconds" -> 0.121558`5.5363285394933035, 
   "TotalSeconds" -> 5.57662`7.197916045460054|>, 
 "Seconds" -> 5.792288`7.2143951409014395, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
