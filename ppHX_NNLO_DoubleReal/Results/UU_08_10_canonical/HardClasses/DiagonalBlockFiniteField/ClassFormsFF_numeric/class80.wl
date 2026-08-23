<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 80, "ContentAddress" -> None, "RepFamily" -> "CF232", 
 "RepRows" -> {9, 10, 11}, "RepBasis" -> 
  {gli["CF232", {1, 1, 0, 0, 1, 1, 1, 1, 0}], 
   gli["CF232", {1, 1, 0, 0, 1, 1, 1, 2, 0}], 
   gli["CF232", {1, 1, 0, 0, 1, 1, 2, 1, 0}]}, "Dim" -> 3, 
 "Transformation" -> {{(4*(1 + t))/(eps*v*(1 + 2*t + t^2 + v)), 
    (1 + t)/(eps*v*(1 + 2*t + t^2 + v)), 
    (2*(1 + t))/(eps*v*(1 + 2*t + t^2 + v))}, 
   {(-8*(1 + t)*(2 + 2*t + v))/((1 + t + v)*(1 + 2*t + t^2 + v)*
      (1 + 2*t + t^2 + t*v)), ((1 + t)*(1 + 4*t + 6*t^2 + 4*t^3 + t^4 + v - 
       t*v - t^2*v + t^3*v - t*v^2))/(t*v*(1 + t + v)*(1 + 2*t + t^2 + v)*
      (1 + 2*t + t^2 + t*v)), (2*(1 + t)*(-1 + t^2 - v))/
     (t*v*(1 + t + v)*(1 + 2*t + t^2 + v))}, 
   {(-8*(1 + t))/(v*(1 + t + v)*(1 + 2*t + t^2 + v)), 
    ((1 + t)*(1 + 2*t + t^2 + v - 2*t*v))/(t*v^2*(1 + t + v)*
      (1 + 2*t + t^2 + v)), (-2*(1 + t)*(1 + 2*t + t^2 + v + 2*t*v))/
     (t*v^2*(1 + t + v)*(1 + 2*t + t^2 + v))}}, 
 "EpsForm" -> {{{eps*(2/v + (1 + t + v)^(-1) - (2*t)/(1 + 2*t + t^2 + t*v)), 
     eps*(v^(-1) - t/(2*(1 + 2*t + t^2 + t*v))), eps/v}, 
    {(-8*eps)/(1 + t + v), eps*(-2/v - 2/(1 + t + v)), (-2*eps)/(1 + t + v)}, 
    {eps*(-4/(1 + 2*t + t^2 + v) + (4*t)/(1 + 2*t + t^2 + t*v)), 
     eps*(-(1 + 2*t + t^2 + v)^(-1) + t/(1 + 2*t + t^2 + t*v)), 
     eps*(-2/v + (1 + t + v)^(-1) - 2/(1 + 2*t + t^2 + v))}}, 
   {{eps*(t^(-1) - 3/(1 + t) + (1 + t + v)^(-1) - (2*(2 + 2*t + v))/
        (1 + 2*t + t^2 + t*v)), eps*(-1/2*1/(1 + t) - 
       (2 + 2*t + v)/(2*(1 + 2*t + t^2 + t*v))), (-2*eps)/(1 + t)}, 
    {eps*(8/(1 + t) - 8/(1 + t + v)), eps*(2/(1 + t) - 2/(1 + t + v)), 
     eps*(2/t + 2/(1 + t) - 2/(1 + t + v))}, 
    {eps*((-4*(2 + 2*t))/(1 + 2*t + t^2 + v) + (4*(2 + 2*t + v))/
        (1 + 2*t + t^2 + t*v)), eps*(t^(-1) - (2 + 2*t)/(1 + 2*t + t^2 + v) + 
       (2 + 2*t + v)/(1 + 2*t + t^2 + t*v)), 
     eps*(-t^(-1) + 5/(1 + t) + (1 + t + v)^(-1) - 
       (2*(2 + 2*t))/(1 + 2*t + t^2 + v))}}}, "Variables" -> {v, t}, 
 "Regulator" -> eps, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (-t - t^2 - t*v)/(1 + t), "Root" -> 2*t + v + (2 + 2*w)/2, 
   "Branch" -> "SquareCompletion"|>, "Frame" -> "Chart:Slicev", 
 "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, 1 + t + v, 1 + 2*t + t^2 + v, 1 + 2*t + t^2 + t*v, t, 
   1 + t}, "Residues" -> {{{2, 1, 1}, {0, -2, 0}, {0, 0, -2}}, 
   {{1, 0, 0}, {-8, -2, -2}, {0, 0, 1}}, {{0, 0, 0}, {0, 0, 0}, 
    {-4, -1, -2}}, {{-2, -1/2, 0}, {0, 0, 0}, {4, 1, 0}}, {{1, 0, 0}, {0, 0, 
   2}, {0, 1, -1}}, {{-3, -1/2, -2}, {8, 2, 2}, {0, 0, 5}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.143522`5.608463471195099|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear-1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.03818`5.0333809175536235|>, <|"Frame" -> "SlicewShear-1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.032062`4.957535603275557|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 4.053738`7.059400669567014|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.210585`5.774972426588392, 
   "SolveSeconds" -> 3.587155`7.006295136324808, 
   "GateSeconds" -> 0.143522`5.608463471195099, 
   "TotalSeconds" -> 4.078142`7.062007337238917|>, 
 "Seconds" -> 4.300109`7.085024457796152, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
