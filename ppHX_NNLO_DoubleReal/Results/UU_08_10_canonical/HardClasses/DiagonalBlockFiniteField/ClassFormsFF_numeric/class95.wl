<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 95, "ContentAddress" -> None, "RepFamily" -> "CF258", 
 "RepRows" -> {1, 2}, "RepBasis" -> 
  {gli["CF258", {1, 1, 0, 1, 1, 1, 0, 1, 1}], 
   gli["CF258", {1, 1, 0, 1, 1, 1, 0, 1, 2}]}, "Dim" -> 2, 
 "Transformation" -> {{((-1 + t)*(3 - 6*t + 3*t^2 - 3*v + 2*t*v))/
     (3*t*(1 - 2*t + t^2 - v)*v*(-1 + t + v)), 
    (-1 + t)/((1 - 2*t + t^2 - v)*(-1 + t + v))}, 
   {-1/3*((-1 + t)^2*(3 + 15*eps + 18*eps^2 - 18*t - 84*eps*t - 96*eps^2*t + 
        45*t^2 + 195*eps*t^2 + 210*eps^2*t^2 - 60*t^3 - 240*eps*t^3 - 
        240*eps^2*t^3 + 45*t^4 + 165*eps*t^4 + 150*eps^2*t^4 - 18*t^5 - 
        60*eps*t^5 - 48*eps^2*t^5 + 3*t^6 + 9*eps*t^6 + 6*eps^2*t^6 - 9*v - 
        45*eps*v - 54*eps^2*v + 36*t*v + 172*eps*t*v + 200*eps^2*t*v - 
        58*t^2*v - 258*eps*t^2*v - 284*eps^2*t^2*v + 48*t^3*v + 
        192*eps*t^3*v + 192*eps^2*t^3*v - 21*t^4*v - 73*eps*t^4*v - 
        62*eps^2*t^4*v + 4*t^5*v + 12*eps*t^5*v + 8*eps^2*t^5*v + 9*v^2 + 
        45*eps*v^2 + 54*eps^2*v^2 - 18*t*v^2 - 92*eps*t*v^2 - 
        112*eps^2*t*v^2 + 11*t^2*v^2 + 55*eps*t^2*v^2 + 66*eps^2*t^2*v^2 - 
        4*t^3*v^2 - 16*eps*t^3*v^2 - 16*eps^2*t^3*v^2 + 2*t^4*v^2 + 
        8*eps*t^4*v^2 + 8*eps^2*t^4*v^2 - 3*v^3 - 15*eps*v^3 - 18*eps^2*v^3 + 
        4*eps*t*v^3 + 8*eps^2*t*v^3 + 2*t^2*v^3 + 8*eps*t^2*v^3 + 
        8*eps^2*t^2*v^3))/((1 + eps)*t^2*(1 - 2*t + t^2 - v)^3*v*
       (-1 + t + v)^2), -(((-1 + t)^2*(-eps - 2*eps^2 - 2*t - 6*eps*t - 
        4*eps^2*t + 6*t^2 + 24*eps*t^2 + 24*eps^2*t^2 - 6*t^3 - 26*eps*t^3 - 
        28*eps^2*t^3 + 2*t^4 + 9*eps*t^4 + 10*eps^2*t^4 + 2*eps*v + 
        4*eps^2*v + t*v + 2*eps*t*v - 2*t^2*v - 8*eps*t^2*v - 8*eps^2*t^2*v + 
        t^3*v + 4*eps*t^3*v + 4*eps^2*t^3*v - eps*v^2 - 2*eps^2*v^2 + t*v^2 + 
        4*eps*t*v^2 + 4*eps^2*t*v^2))/((1 + eps)*t*(1 - 2*t + t^2 - v)^3*
       (-1 + t + v)^2))}}, "EpsForm" -> 
  {{{eps*(2/(3*(1 - 2*t + t^2 - v)) - 2/v + 2/(3*(-1 + t + v))), 
     eps*((1 - 2*t + t^2 - v)^(-1) + (-1 + t + v)^(-1))}, 
    {eps*(8/(9*(1 - 2*t + t^2 - v)) + 8/(9*(-1 + t + v))), 
     eps*(4/(3*(1 - 2*t + t^2 - v)) + v^(-1) - 5/(3*(-1 + t + v)))}}, 
   {{eps*(8/(3*(-1 + t)) - 2/t - (2*(-2 + 2*t))/(3*(1 - 2*t + t^2 - v)) + 
       2/(3*(-1 + t + v))), eps*((-1 + t)^(-1) - 
       (-2 + 2*t)/(1 - 2*t + t^2 - v) + (-1 + t + v)^(-1))}, 
    {eps*(8/(9*(-1 + t)) - (8*(-2 + 2*t))/(9*(1 - 2*t + t^2 - v)) + 
       8/(9*(-1 + t + v))), eps*(1/(3*(-1 + t)) + t^(-1) - 
       (4*(-2 + 2*t))/(3*(1 - 2*t + t^2 - v)) - 5/(3*(-1 + t + v)))}}}, 
 "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (-t + t^2 + t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 - 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, -1 + t + v, 1 - 2*t + t^2 - v, -1 + t, t}, 
 "Residues" -> {{{-2, 0}, {0, 1}}, {{2/3, 1}, {8/9, -5/3}}, 
   {{-2/3, -1}, {-8/9, -4/3}}, {{8/3, 1}, {8/9, 1/3}}, {{-2, 0}, {0, 1}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.09528`5.430546741970694|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.010954`4.491117730088739|>, <|"Frame" -> "SlicewShear1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.011281`4.503892592720637|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 5.497471`7.191707940565055|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.055008`5.19197084850293, 
   "SolveSeconds" -> 5.275924`7.173843524377435, 
   "GateSeconds" -> 0.09528`5.430546741970694, 
   "TotalSeconds" -> 5.510053`7.192700769751905|>, 
 "Seconds" -> 5.629339`7.202002396250382, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
