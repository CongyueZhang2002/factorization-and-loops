<|"Format" -> "FeynFacet-CanonicalClassForm", "FormatVersion" -> 1, 
 "ClassID" -> 101, "ContentAddress" -> None, "RepFamily" -> "CF259", 
 "RepRows" -> {8, 9}, "RepBasis" -> 
  {gli["CF259", {1, 1, 1, 1, 1, 0, 1, 1, 1}], 
   gli["CF259", {1, 1, 1, 1, 1, 0, 1, 1, 2}]}, "Dim" -> 2, 
 "Transformation" -> {{(18963 - 37926*t + 18963*t^2 + 80*v)/
     (18963*(1 - 2*t + t^2 - v)*v^2), (-5*(49 - 98*t + 49*t^2 - 16*v))/
     (387*(1 - 2*t + t^2 - v)*v^2)}, 
   {(18963 + 18963*eps - 113778*t - 132741*eps*t + 284445*t^2 + 
      379260*eps*t^2 - 379260*t^3 - 568890*eps*t^3 + 284445*t^4 + 
      474075*eps*t^4 - 113778*t^5 - 208593*eps*t^5 + 18963*t^6 + 
      37926*eps*t^6 - 18803*v + 320*eps*v + 113298*t*v + 93935*eps*t*v - 
      227076*t^2*v - 283725*eps*t^2*v + 189470*t^3*v + 284365*eps*t^3*v - 
      56889*t^4*v - 94895*eps*t^4*v - 240*v^2 - 19443*eps*v^2 + 480*t*v^2 + 
      38806*eps*t*v^2 - 240*t^2*v^2 - 19363*eps*t^2*v^2 + 80*v^3 + 
      160*eps*v^3)/(18963*(1 - 2*t + t^2 - v)^3*v^2), 
    (-5*(49 + 49*eps - 294*t - 343*eps*t + 735*t^2 + 980*eps*t^2 - 980*t^3 - 
       1470*eps*t^3 + 735*t^4 + 1225*eps*t^4 - 294*t^5 - 539*eps*t^5 + 
       49*t^6 + 98*eps*t^6 - 81*v - 64*eps*v + 390*t*v + 421*eps*t*v - 
       684*t^2*v - 879*eps*t^2*v + 522*t^3*v + 751*eps*t^3*v - 147*t^4*v - 
       229*eps*t^4*v + 48*v^2 + 47*eps*v^2 - 96*t*v^2 - 78*eps*t*v^2 + 
       48*t^2*v^2 + 31*eps*t^2*v^2 - 16*v^3 - 32*eps*v^3))/
     (387*(1 - 2*t + t^2 - v)^3*v^2)}}, 
 "EpsForm" -> {{{eps*(1237795/(307328*(1 - 2*t + t^2 - v)) + 6579/(6272*v) + 
       (-1 + t + v)^(-1)), eps*(-10725/(6272*(1 - 2*t + t^2 - v)) - 
       85/(128*v))}, {eps*(359588969/(75295360*(1 - 2*t + t^2 - v)) + 
       7400601/(1536640*v)), eps*(-623139/(307328*(1 - 2*t + t^2 - v)) - 
       19123/(6272*v) + (-1 + t + v)^(-1))}}, 
   {{eps*(9399/(4802*(-1 + t)) + t^(-1) - (1237795*(-2 + 2*t))/
        (307328*(1 - 2*t + t^2 - v)) + (-1 + t + v)^(-1)), 
     eps*(-205/(98*(-1 + t)) + (10725*(-2 + 2*t))/
        (6272*(1 - 2*t + t^2 - v)))}, 
    {eps*(-19003/(235298*(-1 + t)) - (359588969*(-2 + 2*t))/
        (75295360*(1 - 2*t + t^2 - v))), 
     eps*(-9399/(4802*(-1 + t)) + t^(-1) + (623139*(-2 + 2*t))/
        (307328*(1 - 2*t + t^2 - v)) + (-1 + t + v)^(-1))}}}, 
 "Variables" -> {v, t}, "Regulator" -> eps, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (-t + t^2 + t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 - 2*w)/2, "Branch" -> "SquareCompletion"|>, 
 "Frame" -> "Chart:Slicev", "Method" -> "SliceResiduesFiniteFieldAffine", 
 "Letters" -> {v, -1 + t + v, 1 - 2*t + t^2 - v, -1 + t, t}, 
 "Residues" -> {{{6579/6272, -85/128}, {7400601/1536640, -19123/6272}}, 
   {{1, 0}, {0, 1}}, {{-1237795/307328, 10725/6272}, 
    {-359588969/75295360, 623139/307328}}, {{9399/4802, -205/98}, 
    {-19003/235298, -9399/4802}}, {{1, 0}, {0, 1}}}, 
 "Certificate" -> <|"Status" -> "Certified", "GateX" -> True, 
   "GateY" -> True, "ConstantResidues" -> True, "Flat" -> True, 
   "Invertible" -> True, "Seconds" -> 0.064343`5.260046299565681|>, 
 "Attempts" -> {<|"Frame" -> "SlicevShear1", "Stage" -> "Slice", 
    "Status" -> "ExponentsNotInteger", "Seconds" -> 
     0.014803`4.621894732635159|>, <|"Frame" -> "SlicewShear1", 
    "Stage" -> "Slice", "Status" -> "ExponentsNotInteger", 
    "Seconds" -> 0.015679`4.646863353608986|>, <|"Frame" -> "Slicev", 
    "Stage" -> "Gate", "Status" -> "Certified", 
    "Seconds" -> 5.35747`7.180504741316057|>}, 
 "Timing" -> <|"SliceSeconds" -> 0.249363`5.8483770076428785, 
   "SolveSeconds" -> 5.000832`7.150587258421865, 
   "GateSeconds" -> 0.064343`5.260046299565681, 
   "TotalSeconds" -> 5.3686`7.1814060405465225|>, 
 "Seconds" -> 5.47911`7.190255013024216, "Status" -> "CANONICALIZED", 
 "Validated" -> True|>
