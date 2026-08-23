<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 122, "ContentAddress" -> None, "RepFamily" -> "CF303", 
 "RepRows" -> {1, 2}, "RepBasis" -> 
  {gli["CF303", {1, 1, 0, 1, 1, 1, 1, 0, 1}], 
   gli["CF303", {1, 1, 0, 1, 1, 1, 1, 0, 2}]}, "Dim" -> 2, 
 "Transformation" -> {{((1 + t)*(3 + 6*t + 3*t^2 + v))/
     (3*t*v*(1 + t + v)*(1 + 2*t + t^2 + v)), 
    (1 + t)/(t*(1 + t + v)*(1 + 2*t + t^2 + v))}, 
   {((1 + t)*(3 + 9*eps + 6*eps^2 + 18*t + 60*eps*t + 48*eps^2*t + 45*t^2 + 
       165*eps*t^2 + 150*eps^2*t^2 + 60*t^3 + 240*eps*t^3 + 240*eps^2*t^3 + 
       45*t^4 + 195*eps*t^4 + 210*eps^2*t^4 + 18*t^5 + 84*eps*t^5 + 
       96*eps^2*t^5 + 3*t^6 + 15*eps*t^6 + 18*eps^2*t^6 + 5*v + 15*eps*v + 
       10*eps^2*v + 24*t*v + 80*eps*t*v + 64*eps^2*t*v + 42*t^2*v + 
       150*eps*t^2*v + 132*eps^2*t^2*v + 32*t^3*v + 120*eps*t^3*v + 
       112*eps^2*t^3*v + 9*t^4*v + 35*eps*t^4*v + 34*eps^2*t^4*v + 3*v^2 + 
       11*eps*v^2 + 10*eps^2*v^2 + 6*t*v^2 + 20*eps*t*v^2 + 16*eps^2*t*v^2 + 
       3*t^2*v^2 + 9*eps*t^2*v^2 + 6*eps^2*t^2*v^2 + v^3 + 5*eps*v^3 + 
       6*eps^2*v^3))/(3*(1 + eps)*t*v*(1 + t + v)*(1 + 2*t + t^2 + v)^3), 
    -(((1 + t)*(-2 - 9*eps - 10*eps^2 - 6*t - 26*eps*t - 28*eps^2*t - 6*t^2 - 
        24*eps*t^2 - 24*eps^2*t^2 - 2*t^3 - 6*eps*t^3 - 4*eps^2*t^3 + 
        eps*t^4 + 2*eps^2*t^4 - 3*v - 14*eps*v - 16*eps^2*v - 6*t*v - 
        26*eps*t*v - 28*eps^2*t*v - 3*t^2*v - 12*eps*t^2*v - 12*eps^2*t^2*v - 
        v^2 - 5*eps*v^2 - 6*eps^2*v^2))/((1 + eps)*t*(1 + t + v)*
       (1 + 2*t + t^2 + v)^3))}}, 
 "EpsForm" -> {{{eps*(-2/v - 2/(3*(1 + 2*t + t^2 + v))), 
     eps/(1 + 2*t + t^2 + v)}, {(8*eps)/(9*(1 + 2*t + t^2 + v)), 
     eps*(v^(-1) - 4/(3*(1 + 2*t + t^2 + v)))}}, 
   {{eps*(10/(3*(1 + t)) - (2*(2 + 2*t))/(3*(1 + 2*t + t^2 + v))), 
     eps*(-2/(1 + t) + (2 + 2*t)/(1 + 2*t + t^2 + v))}, 
    {eps*(-16/(9*(1 + t)) + (8*(2 + 2*t))/(9*(1 + 2*t + t^2 + v))), 
     eps*(-4/(3*(1 + t)) - (4*(2 + 2*t))/(3*(1 + 2*t + t^2 + v)))}}}, 
 "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (-t - t^2 - t*v)/(1 + t), 
   "Root" -> 2*t + v + (2 + 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, 1 + 2*t + t^2 + v, 1 + t}, 
 "Residues" -> {{{-2, 0}, {0, 1}}, {{-2/3, 1}, {8/9, -4/3}}, 
   {{10/3, -2}, {-16/9, -4/3}}}, "Certificate" -> 
  <|"Status" -> "Certified", "GateX" -> True, "GateY" -> True, 
   "ConstantResidues" -> True, "Flat" -> True, "Invertible" -> True, 
   "Seconds" -> 0.095426`5.431211713253673|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear-1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.013179`4.571427451480956|>, <|"Frame" -> "SlicewShear-1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.012903`4.56223569076973|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 3.220444`6.959460745147369|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.05529`5.194191583434709, 
   "SolveSeconds" -> 3.002793`6.929070388280267, 
   "GateSeconds" -> 0.095426`5.431211713253673, 
   "TotalSeconds" -> 3.232222`6.961046175445027|>, 
 "Seconds" -> 3.339963`6.975286649234235, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
