<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 123, "ContentAddress" -> None, "RepFamily" -> "CF303", 
 "RepRows" -> {5, 6}, "RepBasis" -> 
  {gli["CF303", {1, 1, 1, 1, 1, 1, 1, 0, 1}], 
   gli["CF303", {1, 1, 1, 1, 1, 1, 1, 0, 2}]}, "Dim" -> 2, 
 "Transformation" -> {{((1 + t)^2*(2 + 4*t + 2*t^2 + 2*v + t*v))/
     (2*t^2*v^2*(1 + t + v)^2*(1 + 2*t + t^2 + v)), 
    (1 + t)^2/(t*v*(1 + t + v)^2*(1 + 2*t + t^2 + v))}, 
   {((1 + t)^3*(2 + 4*eps + 12*t + 22*eps*t + 30*t^2 + 50*eps*t^2 + 40*t^3 + 
       60*eps*t^3 + 30*t^4 + 40*eps*t^4 + 12*t^5 + 14*eps*t^5 + 2*t^6 + 
       2*eps*t^6 + 6*v + 12*eps*v + 24*t*v + 45*eps*t*v + 38*t^2*v + 
       65*eps*t^2*v + 30*t^3*v + 45*eps*t^3*v + 12*t^4*v + 15*eps*t^4*v + 
       2*t^5*v + 2*eps*t^5*v + 6*v^2 + 12*eps*v^2 + 12*t*v^2 + 24*eps*t*v^2 + 
       7*t^2*v^2 + 13*eps*t^2*v^2 + 2*t^3*v^2 + 3*eps*t^3*v^2 + t^4*v^2 + 
       2*eps*t^4*v^2 + 2*v^3 + 4*eps*v^3 + eps*t*v^3 - t^2*v^3 - 
       2*eps*t^2*v^3))/(2*t^3*v^2*(1 + t + v)^3*(1 + 2*t + t^2 + v)^3), 
    ((1 + t)^3*(-eps + 2*t + eps*t + 6*t^2 + 9*eps*t^2 + 6*t^3 + 11*eps*t^3 + 
       2*t^4 + 4*eps*t^4 - 2*eps*v + t*v - eps*t*v + 2*t^2*v + 3*eps*t^2*v + 
       t^3*v + 2*eps*t^3*v - eps*v^2 - t*v^2 - 2*eps*t*v^2))/
     (t^2*v*(1 + t + v)^3*(1 + 2*t + t^2 + v)^3)}}, 
 "EpsForm" -> {{{eps*(-2/v - 1/(2*(1 + t + v)) - 1/(2*(1 + 2*t + t^2 + v))), 
     eps*((1 + t + v)^(-1) - (1 + 2*t + t^2 + v)^(-1))}, 
    {eps*(3/(4*(1 + t + v)) - 3/(4*(1 + 2*t + t^2 + v))), 
     eps*(-3/(2*(1 + t + v)) - 3/(2*(1 + 2*t + t^2 + v)))}}, 
   {{eps*(-2/t + 5/(2*(1 + t)) - 1/(2*(1 + t + v)) - 
       (2 + 2*t)/(2*(1 + 2*t + t^2 + v))), 
     eps*((1 + t)^(-1) + (1 + t + v)^(-1) - (2 + 2*t)/(1 + 2*t + t^2 + v))}, 
    {eps*(3/(4*(1 + t)) + 3/(4*(1 + t + v)) - (3*(2 + 2*t))/
        (4*(1 + 2*t + t^2 + v))), eps*(3/(2*(1 + t)) - 3/(2*(1 + t + v)) - 
       (3*(2 + 2*t))/(2*(1 + 2*t + t^2 + v)))}}}, "Variables" -> {v, t}, 
 "Regulator" -> eps, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (-t - t^2 - t*v)/(1 + t), "Root" -> 2*t + v + (2 + 2*w)/2, 
   "Branch" -> "SquareCompletion"|>, "Frame" -> "Chart:Slicev", 
 "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, 1 + t + v, 1 + 2*t + t^2 + v, t, 1 + t}, 
 "Residues" -> {{{-2, 0}, {0, 0}}, {{-1/2, 1}, {3/4, -3/2}}, 
   {{-1/2, -1}, {-3/4, -3/2}}, {{-2, 0}, {0, 0}}, {{5/2, 1}, {3/4, 3/2}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.098824`5.4464074219076|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear-1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.011191`4.500413889235904|>, <|"Frame" -> "SlicewShear-1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.012227`4.538864905702376|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 6.241529`7.246835986210616|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.100763`5.454846082691741, 
   "SolveSeconds" -> 5.976739`7.228009284408337, 
   "GateSeconds" -> 0.098824`5.4464074219076, 
   "TotalSeconds" -> 6.255332`7.247795358195535|>, 
 "Seconds" -> 6.362591`7.255179000316659, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
