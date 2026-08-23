<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 171, "ContentAddress" -> None, "RepFamily" -> "CF56", 
 "RepRows" -> {3, 6}, "RepBasis" -> 
  {gli["CF56", {1, 1, 1, 1, 1, 1, 0, 1, 0}], 
   gli["CF56", {1, 2, 1, 1, 1, 1, 0, 1, 0}]}, "Dim" -> 2, 
 "Transformation" -> {{(-1 + t)/(1 - 2*t + t^2 - v + 2*t*v), 0}, 
   {-1/49*((-1 + t)*(-49 + 4299*eps + 8794*eps^2 + 196*t - 17196*eps*t - 
        35176*eps^2*t - 294*t^2 + 25794*eps*t^2 + 52764*eps^2*t^2 + 196*t^3 - 
        17196*eps*t^3 - 35176*eps^2*t^3 - 49*t^4 + 4299*eps*t^4 + 
        8794*eps^2*t^4 + 98*v - 8598*eps*v - 17588*eps^2*v - 294*t*v + 
        25892*eps*t*v + 52960*eps^2*t*v + 294*t^2*v - 25990*eps*t^2*v - 
        53156*eps^2*t^2*v - 98*t^3*v + 8696*eps*t^3*v + 17784*eps^2*t^3*v - 
        49*v^2 + 4299*eps*v^2 + 8794*eps^2*v^2 + 98*t*v^2 - 8696*eps*t*v^2 - 
        17784*eps^2*t*v^2 - 98*t^2*v^2 - 392*eps*t^2*v^2 - 
        392*eps^2*t^2*v^2))/((1 + eps)*(1 - 2*t + t^2 - v + 2*t*v)^3), 
    (30*(-1 + t)*(eps + 2*eps^2 - 2*eps*t - 4*eps^2*t + eps*t^2 + 
       2*eps^2*t^2 - eps*v - 2*eps^2*v))/(49*(1 + eps)*
      (1 - 2*t + t^2 - v + 2*t*v)^2)}}, 
 "EpsForm" -> {{{eps*(-4446/(49*v) + 4642/(49*(-1 + t + v)) - 
       (4*(-1 + 2*t))/(1 - 2*t + t^2 - v + 2*t*v)), 
     eps*(30/(49*v) - 30/(49*(-1 + t + v)))}, 
    {eps*(-666159/(49*v) + 3553451/(245*(-1 + t + v)) - 
       4544/(15*(-1 + 2*t - t^2 + v)) - (9088*(-1 + 2*t))/
        (15*(1 - 2*t + t^2 - v + 2*t*v))), 
     eps*(4495/(49*v) - 4593/(49*(-1 + t + v)) + 2/(-1 + 2*t - t^2 + v))}}, 
   {{eps*(4642/(49*(-1 + t)) - 4446/(49*t) + 4642/(49*(-1 + t + v)) - 
       (4*(-2 + 2*t + 2*v))/(1 - 2*t + t^2 - v + 2*t*v)), 
     eps*(-30/(49*(-1 + t)) + 30/(49*t) - 30/(49*(-1 + t + v)))}, 
    {eps*(3553451/(245*(-1 + t)) - 666159/(49*t) + 
       3553451/(245*(-1 + t + v)) - (4544*(2 - 2*t))/
        (15*(-1 + 2*t - t^2 + v)) - (9088*(-2 + 2*t + 2*v))/
        (15*(1 - 2*t + t^2 - v + 2*t*v))), 
     eps*(-4593/(49*(-1 + t)) + 4495/(49*t) - 4593/(49*(-1 + t + v)) + 
       (2*(2 - 2*t))/(-1 + 2*t - t^2 + v))}}}, "Variables" -> {v, t}, 
 "Regulator" -> eps, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (-t + t^2 + t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 - 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, -1 + t + v, -1 + 2*t - t^2 + v, 1 - 2*t + t^2 - v + 2*t*v, 
   -1 + t, t}, "Residues" -> {{{-4446/49, 30/49}, {-666159/49, 4495/49}}, 
   {{4642/49, -30/49}, {3553451/245, -4593/49}}, {{0, 0}, {-4544/15, 2}}, 
   {{-4, 0}, {-9088/15, 0}}, {{4642/49, -30/49}, {3553451/245, -4593/49}}, 
   {{-4446/49, 30/49}, {-666159/49, 4495/49}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.038548`5.037546843807824|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.02561`4.8599545719644|>, <|"Frame" -> "SlicewShear1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.024`4.831756235207581|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 2.264567`6.806530167841438|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.201286`5.755358563048379, 
   "SolveSeconds" -> 1.997317`6.751991991979634, 
   "GateSeconds" -> 0.038548`5.037546843807824, 
   "TotalSeconds" -> 2.278464`6.809187164564601|>, 
 "Seconds" -> 2.423499`6.83598783835336, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
