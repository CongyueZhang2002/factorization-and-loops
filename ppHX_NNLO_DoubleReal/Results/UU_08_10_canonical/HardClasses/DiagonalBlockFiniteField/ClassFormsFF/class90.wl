<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 90, "ContentAddress" -> None, "RepFamily" -> "CF248", 
 "RepRows" -> {1, 2}, "RepBasis" -> 
  {gli["CF248", {1, 1, 0, 1, 0, 1, 0, 1, 0}], 
   gli["CF248", {1, 1, 0, 1, 0, 1, 0, 2, 0}]}, "Dim" -> 2, 
 "Transformation" -> {{(1 - t)/(1 - 2*t + t^2 - v), 
    (60*(-1 + t))/(427*(1 - 2*t + t^2 - v))}, 
   {(-3*(-1 + t)*(-12*eps - 37*eps*t + 49*eps*t^2 + 12*eps*v))/
     (61*t*(1 - 2*t + t^2 - v)*(-1 + t + v)), 
    (15*(-1 + t)*(37*eps - 86*eps*t + 49*eps*t^2 - 37*eps*v))/
     (427*t*(1 - 2*t + t^2 - v)*(-1 + t + v))}}, 
 "EpsForm" -> 
  {{{eps*(-2/v - 221/(49*(-1 + t + v)) + 10492/(2401*(-1 + 2*t - t^2 + v)) + 
       888/(2401*(-1 + t^2 + v))), eps*(1350/(343*(-1 + t + v)) - 
       10320/(16807*(-1 + 2*t - t^2 + v)) - 10320/(16807*(-1 + t^2 + v)))}, 
    {eps*(-172/(35*(-1 + t + v)) + 4514/(1715*(-1 + 2*t - t^2 + v)) + 
       4514/(1715*(-1 + t^2 + v))), eps*(-2/v + 221/(49*(-1 + t + v)) - 
       888/(2401*(-1 + 2*t - t^2 + v)) - 10492/(2401*(-1 + t^2 + v)))}}, 
   {{eps*(-551/(2401*(-1 + t)) - 551/(2401*t) - 221/(49*(-1 + t + v)) + 
       (10492*(2 - 2*t))/(2401*(-1 + 2*t - t^2 + v)) + 
       (1776*t)/(2401*(-1 + t^2 + v))), eps*(-45510/(16807*(-1 + t)) - 
       45510/(16807*t) + 1350/(343*(-1 + t + v)) - (10320*(2 - 2*t))/
        (16807*(-1 + 2*t - t^2 + v)) - (20640*t)/(16807*(-1 + t^2 + v)))}, 
    {eps*(-120/(343*(-1 + t)) - 120/(343*t) - 172/(35*(-1 + t + v)) + 
       (4514*(2 - 2*t))/(1715*(-1 + 2*t - t^2 + v)) + 
       (9028*t)/(1715*(-1 + t^2 + v))), eps*(551/(2401*(-1 + t)) + 
       551/(2401*t) + 221/(49*(-1 + t + v)) - (888*(2 - 2*t))/
        (2401*(-1 + 2*t - t^2 + v)) - (20984*t)/(2401*(-1 + t^2 + v)))}}}, 
 "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (t - t^2 - t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 + 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, -1 + t + v, -1 + 2*t - t^2 + v, -1 + t^2 + v, -1 + t, t}, 
 "Residues" -> {{{-2, 0}, {0, -2}}, {{-221/49, 1350/343}, {-172/35, 221/49}}, 
   {{10492/2401, -10320/16807}, {4514/1715, -888/2401}}, 
   {{888/2401, -10320/16807}, {4514/1715, -10492/2401}}, 
   {{-551/2401, -45510/16807}, {-120/343, 551/2401}}, 
   {{-551/2401, -45510/16807}, {-120/343, 551/2401}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.041453`5.069100959897317|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear-1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.014395`4.609756662710076|>, <|"Frame" -> "SlicewShear-1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.01298`4.564819685960321|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 1.296575`6.564342636964677|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.121421`5.535838798813446, 
   "SolveSeconds" -> 1.105694`6.495179946414979, 
   "GateSeconds" -> 0.041453`5.069100959897317, 
   "TotalSeconds" -> 1.308054`6.5681706667028275|>, 
 "Seconds" -> 1.431203`6.607246231397713, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
