<|"ClassID" -> 92, "RepFamily" -> "CF249", "RepRows" -> {1, 2, 3}, 
 "Dim" -> 3, "Transformation" -> {{(-1 + t)/(2*v*(-1 + 2*t - t^2 + v)), 
    (-1 + t)/(2*v*(-1 + 2*t - t^2 + v)), 0}, 
   {-((Global`eps*(-1 + t))/(t*(1 - 2*t + t^2 - v)*v)), 
    -((Global`eps*(-1 + t)^2)/((1 - 2*t + t^2 - v)*v*(-1 + t + v))), 0}, 
   {-((Global`eps*(-1 + t)^2)/(t*(1 - 2*t + t^2 - v)*v^2)), 
    -((Global`eps*(-1 + t)^2)/(t*(1 - 2*t + t^2 - v)*v^2)), 
    (Global`eps*(-1 + t))/(t*v^2*(-1 + t + v))}}, 
 "EpsForm" -> {{{(Global`eps*(-1 + t)*t)/((1 - 2*t + t^2 - v)*(-1 + t + v)), 
     (Global`eps*(-1 + t)^2)/((1 - 2*t + t^2 - v)*v), 
     -((Global`eps*(-1 + t))/(v*(-1 + t + v)))}, 
    {Global`eps/(1 - 2*t + t^2 - v), (Global`eps*(-2 + 4*t - 2*t^2 + 3*v))/
      ((1 - 2*t + t^2 - v)*v), 0}, {(Global`eps*(2 - 4*t + 2*t^2 - v))/
      ((1 - 2*t + t^2 - v)*v), (Global`eps*(-1 + t)^2)/
      ((1 - 2*t + t^2 - v)*v), (-3*Global`eps)/v}}, 
   {{(Global`eps*(3 - 3*t^3 + t^2*(9 - 4*v) + 9*t*(-1 + v) - 5*v + 2*v^2))/
      ((-1 + t)*(1 - 2*t + t^2 - v)*(-1 + t + v)), (-2*Global`eps*(-1 + t))/
      (1 - 2*t + t^2 - v), Global`eps/(-1 + t + v)}, 
    {(Global`eps*(-1 - t^2 - 2*t*(-1 + v) + v))/
      ((-1 + t)*t*(1 - 2*t + t^2 - v)), 
     (2*Global`eps*(-1 - 3*t^2 + t^3 + t*(3 - 2*v) + v))/
      ((-1 + t)*t*(1 - 2*t + t^2 - v)), Global`eps/((-1 + t)*t)}, 
    {(Global`eps*(-1 + 3*t^2 - 2*t^3 + v))/((-1 + t)*t*(1 - 2*t + t^2 - v)), 
     (-2*Global`eps*(-1 + t + v))/(t*(1 - 2*t + t^2 - v)), 
     Global`eps/((-1 + t)*t)}}}, "Variables" -> {v, t}, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (t - t^2 - t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 + 2*w)/2|>, "AnsatzDegree" -> 0, 
 "Validated" -> True|>
