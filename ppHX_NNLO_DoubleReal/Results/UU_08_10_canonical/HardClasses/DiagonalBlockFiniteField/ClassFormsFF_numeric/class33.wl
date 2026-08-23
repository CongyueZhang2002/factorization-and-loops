<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 33, "ContentAddress" -> None, "RepFamily" -> "CF18", 
 "RepRows" -> {4, 5, 8}, "RepBasis" -> 
  {gli["CF18", {1, 1, 1, 0, 1, 1, 0, 1, 0}], 
   gli["CF18", {1, 1, 1, 0, 1, 1, 0, 2, 0}], 
   gli["CF18", {1, 1, 1, 0, 1, 2, 0, 1, 0}]}, "Dim" -> 3, 
 "Transformation" -> {{(4*(1 + t))/(eps*v*(1 + 2*t + t^2 + v)), 
    (1 + t)/(eps*v*(1 + 2*t + t^2 + v)), 0}, 
   {(-8*(1 + t)*(2 + 2*t + v))/((1 + t + v)*(1 + 2*t + t^2 + v)*
      (1 + 2*t + t^2 + t*v)), ((1 + t)*(1 + 4*t + 6*t^2 + 4*t^3 + t^4 + v - 
       t*v - t^2*v + t^3*v - t*v^2))/(t*v*(1 + t + v)*(1 + 2*t + t^2 + v)*
      (1 + 2*t + t^2 + t*v)), (-2*(1 + t)*(-1 + t^2 + t*v))/
     (t*v*(1 + t + v)*(1 + 2*t + t^2 + t*v))}, 
   {(-4*(1 + 6*eps + 2*t + 16*eps*t + 12*eps*t^2 - 2*t^3 - t^4 - 2*eps*t^4 + 
       v + 8*eps*v + 2*t*v + 12*eps*t*v + t^2*v + 4*eps*t^2*v + 2*eps*v^2))/
     (eps*v*(1 + 2*t + t^2 + v)^3), (eps + 6*eps*t + 15*eps*t^2 + 
      20*eps*t^3 + 15*eps*t^4 + 6*eps*t^5 + eps*t^6 - v - 5*eps*v - 2*t*v - 
      12*eps*t*v - 6*eps*t^2*v + 2*t^3*v + 4*eps*t^3*v + t^4*v + 
      3*eps*t^4*v - v^2 - 7*eps*v^2 - 2*t*v^2 - 10*eps*t*v^2 - t^2*v^2 - 
      3*eps*t^2*v^2 - eps*v^3)/(eps*v^2*(1 + 2*t + t^2 + v)^3), 
    (-2*(-1 - 2*t + 2*t^3 + t^4 + 2*v + 2*t*v + v^2))/
     (v^2*(1 + 2*t + t^2 + v)^2)}}, 
 "EpsForm" -> {{{eps*(2/v + (1 + t + v)^(-1) - 2/(1 + 2*t + t^2 + v)), 
     eps*(v^(-1) - 1/(2*(1 + 2*t + t^2 + v))), eps/v}, 
    {(-8*eps)/(1 + t + v), eps*(-2/v - 2/(1 + t + v)), (-2*eps)/(1 + t + v)}, 
    {eps*(4/(1 + 2*t + t^2 + v) - (4*t)/(1 + 2*t + t^2 + t*v)), 
     eps*((1 + 2*t + t^2 + v)^(-1) - t/(1 + 2*t + t^2 + t*v)), 
     eps*(-2/v + (1 + t + v)^(-1) - (2*t)/(1 + 2*t + t^2 + t*v))}}, 
   {{eps*(t^(-1) - 3/(1 + t) + (1 + t + v)^(-1) - (2*(2 + 2*t))/
        (1 + 2*t + t^2 + v)), eps*(1/(2*t) - 1/(2*(1 + t)) - 
       (2 + 2*t)/(2*(1 + 2*t + t^2 + v))), eps*(t^(-1) - 2/(1 + t))}, 
    {eps*(8/(1 + t) - 8/(1 + t + v)), eps*(2/(1 + t) - 2/(1 + t + v)), 
     eps*(-2/t + 2/(1 + t) - 2/(1 + t + v))}, 
    {eps*((4*(2 + 2*t))/(1 + 2*t + t^2 + v) - (4*(2 + 2*t + v))/
        (1 + 2*t + t^2 + t*v)), 
     eps*(-t^(-1) + (2 + 2*t)/(1 + 2*t + t^2 + v) - 
       (2 + 2*t + v)/(1 + 2*t + t^2 + t*v)), 
     eps*(-t^(-1) + 5/(1 + t) + (1 + t + v)^(-1) - (2*(2 + 2*t + v))/
        (1 + 2*t + t^2 + t*v))}}}, "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (-t - t^2 - t*v)/(1 + t), 
   "Root" -> 2*t + v + (2 + 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, 1 + t + v, 1 + 2*t + t^2 + t*v, 1 + 2*t + t^2 + v, 1 + t, 
   t}, "Residues" -> {{{2, 1, 1}, {0, -2, 0}, {0, 0, -2}}, 
   {{1, 0, 0}, {-8, -2, -2}, {0, 0, 1}}, {{0, 0, 0}, {0, 0, 0}, 
    {-4, -1, -2}}, {{-2, -1/2, 0}, {0, 0, 0}, {4, 1, 0}}, 
   {{-3, -1/2, -2}, {8, 2, 2}, {0, 0, 5}}, {{1, 1/2, 1}, {0, 0, -2}, 
    {0, -1, -1}}}, "Certificate" -> <|"Status" -> "Certified", 
   "GateX" -> True, "GateY" -> True, "ConstantResidues" -> True, 
   "Flat" -> True, "Invertible" -> True, 
   "Seconds" -> 0.209492`5.772712436444144|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear-1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.026203`4.869896010344682|>, <|"Frame" -> "SlicewShear-1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.023478`4.822206091780297|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 14.28317`7.606369598745843|>}, 
 "Timing" -> <|"SliceSeconds" -> 2.464322`6.84324244767282, 
   "SolveSeconds" -> 11.429752`7.509581800776647, 
   "GateSeconds" -> 0.209492`5.772712436444144, 
   "TotalSeconds" -> 14.313976`7.60730527820034|>, 
 "Seconds" -> 14.525437`7.613674200570988, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
