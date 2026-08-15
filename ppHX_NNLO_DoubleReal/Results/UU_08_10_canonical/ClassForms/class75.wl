<|"ClassID" -> 75, "RepFamily" -> "CF226", "RepRows" -> {1, 2, 3}, 
 "Dim" -> 3, "Transformation" -> {{(-1 + t)/(2*v*(-1 + 2*t - t^2 + v)), 
    (-1 + t)/(2*v*(-1 + 2*t - t^2 + v)), 0}, 
   {-((Global`eps*(-1 + t))/(t*(1 - 2*t + t^2 - v)*v)), 
    -((Global`eps*(-1 + t)^2)/((1 - 2*t + t^2 - v)*v*(-1 + t + v))), 0}, 
   {(Global`eps*(-1 + t)^2)/((1 - 2*t + t^2 - v)*v^2), 
    (Global`eps*(-1 + t)^2)/((1 - 2*t + t^2 - v)*v^2), Global`eps/v^2}}, 
 "EpsForm" -> 
  {{{(Global`eps*(-2*t^3 - t^2*(-6 + v) + 2*(-1 + v)^2 + t*(-6 + 5*v)))/
      ((1 - 2*t + t^2 - v)*v*(-1 + t + v)), (Global`eps*(-1 + t)*t)/
      ((1 - 2*t + t^2 - v)*(-1 + t + v)), 0}, 
    {(Global`eps*(-1 + t)^2)/((1 - 2*t + t^2 - v)*v), 
     (Global`eps*(-3 + 5*t - 2*t^2 + 3*v))/((1 - 2*t + t^2 - v)*
       (-1 + t + v)), Global`eps/v}, 
    {-((Global`eps*(-1 + t)^2)/((1 - 2*t + t^2 - v)*v)), 
     -((Global`eps*(-1 + t)*(2 + 2*t^2 + t*(-4 + v) - 2*v))/
       ((1 - 2*t + t^2 - v)*v*(-1 + t + v))), (Global`eps*(3 - 3*t - 2*v))/
      (v*(-1 + t + v))}}, 
   {{(Global`eps*(-2*t^4 + t^3*(8 - 3*v) - 2*(-1 + v)^2 + 4*t^2*(-3 + 2*v) + 
        t*(8 - 9*v + v^2)))/((-1 + t)*t*(1 - 2*t + t^2 - v)*(-1 + t + v)), 
     (Global`eps*(-1 - t^2 - 2*t*(-1 + v) + v))/((1 - 2*t + t^2 - v)*
       (-1 + t + v)), Global`eps/(1 - t)}, 
    {-((Global`eps*(-1 + t^2 + v))/(t*(1 - 2*t + t^2 - v))), 
     -((Global`eps*(-5*t^3 + 2*t^4 - (-1 + v)^2 + t^2*(3 + v) + 
         t*(1 - 3*v + 2*v^2)))/((-1 + t)*t*(1 - 2*t + t^2 - v)*
        (-1 + t + v))), Global`eps/(1 - t)}, 
    {(Global`eps*(1 - 4*t + 3*t^2 - v))/(t*(1 - 2*t + t^2 - v)), 
     (Global`eps*(3 + 3*t^2 + 2*t*(-3 + v) - 3*v))/((1 - 2*t + t^2 - v)*
       (-1 + t + v)), (Global`eps*(-1 + 2*t + v))/(t*(-1 + t + v))}}}, 
 "Variables" -> {v, t}, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (t - t^2 - t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 + 2*w)/2|>, "AnsatzDegree" -> 0, 
 "Validated" -> True|>
