<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 90, "ContentAddress" -> None, "RepFamily" -> "CF248", 
 "RepRows" -> {1, 2}, "RepBasis" -> 
  {gli["CF248", {1, 1, 0, 1, 0, 1, 0, 1, 0}], 
   gli["CF248", {1, 1, 0, 1, 0, 1, 0, 2, 0}]}, "Dim" -> 2, 
 "Transformation" -> {{(1 - t)/(1 - 2*t + t^2 - v), 
    (1 - t)/(6*(1 - 2*t + t^2 - v))}, 
   {-(((-1 + t)*(-2*eps + eps*t + eps*t^2 + 2*eps*v))/
      (t*(1 - 2*t + t^2 - v)*(-1 + t + v))), 
    -1/2*(eps*(-1 + t))/(t*(1 - 2*t + t^2 - v))}}, 
 "EpsForm" -> {{{eps*(-2/v - (-1 + t + v)^(-1) + 6/(-1 + 2*t - t^2 + v) + 
       2/(-1 + t^2 + v)), eps*((-1 + 2*t - t^2 + v)^(-1) + 
       (-1 + t^2 + v)^(-1))}, {eps*(-12/(-1 + 2*t - t^2 + v) - 
       12/(-1 + t^2 + v)), eps*(-2/v + (-1 + t + v)^(-1) - 
       2/(-1 + 2*t - t^2 + v) - 6/(-1 + t^2 + v))}}, 
   {{eps*(-7/(-1 + t) - 7/t - (-1 + t + v)^(-1) + (6*(2 - 2*t))/
        (-1 + 2*t - t^2 + v) + (4*t)/(-1 + t^2 + v)), 
     eps*(-2/(-1 + t) - 2/t + (2 - 2*t)/(-1 + 2*t - t^2 + v) + 
       (2*t)/(-1 + t^2 + v))}, 
    {eps*(24/(-1 + t) + 24/t - (12*(2 - 2*t))/(-1 + 2*t - t^2 + v) - 
       (24*t)/(-1 + t^2 + v)), eps*(7/(-1 + t) + 7/t + (-1 + t + v)^(-1) - 
       (2*(2 - 2*t))/(-1 + 2*t - t^2 + v) - (12*t)/(-1 + t^2 + v))}}}, 
 "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (t - t^2 - t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 + 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, -1 + t + v, -1 + 2*t - t^2 + v, -1 + t^2 + v, -1 + t, t}, 
 "Residues" -> {{{-2, 0}, {0, -2}}, {{-1, 0}, {0, 1}}, {{6, 1}, {-12, -2}}, 
   {{2, 1}, {-12, -6}}, {{-7, -2}, {24, 7}}, {{-7, -2}, {24, 7}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.031109`4.944431044416246|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear-1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.013704`4.58839234345343|>, <|"Frame" -> "SlicewShear-1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.011913`4.5275661352795185|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 1.240872`6.545271978410726|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.029886`4.927012785612001, 
   "SolveSeconds" -> 1.145661`6.510601122812153, 
   "GateSeconds" -> 0.031109`4.944431044416246, 
   "TotalSeconds" -> 1.251531`6.548986604901021|>, 
 "Seconds" -> 1.365862`6.586951816072782, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
