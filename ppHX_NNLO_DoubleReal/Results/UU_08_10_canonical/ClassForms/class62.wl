<|"ClassID" -> 62, "RepFamily" -> "CF21", "RepRows" -> {7, 8, 9, 11}, 
 "Dim" -> 4, "Transformation" -> {{(1 + t)/(1 + 2*t + t^2 + v), 0, 0, 0}, 
   {0, (Global`eps*(1 + t))/(1 + t^2 + t*(2 + v)), 0, 0}, 
   {0, 0, Global`eps/v, 0}, {0, 0, 0, Global`eps/v}}, 
 "EpsForm" -> 
  {{{-((Global`eps*(5 + 5*t^3 + 2*v - 3*v^2 + 3*t*(5 + 3*v) + 
         t^2*(15 + 7*v)))/(v*(1 + t + v)*(1 + 2*t + t^2 + v))), 
     (2*Global`eps)/v, -((Global`eps*(1 + t + 2*v))/(v*(1 + t + v))), 
     Global`eps/(1 + t + v)}, {(-3*Global`eps*(2 + 2*t + v))/(v*(1 + t + v)), 
     (-2*Global`eps*(1 + 6*t^2 + 4*t^3 + t^4 + t*(4 + v^2)))/
      (v*(-1 - 2*t - t^2 + v)*(1 + t^2 + t*(2 + v))), 
     (2*Global`eps*(1 + 3*t + 3*t^2 + t^3 + v^2))/
      (v*(1 + t + v)*(-1 - 2*t - t^2 + v)), -(Global`eps/(1 + t + v))}, 
    {(3*Global`eps)/(1 + t + v), (-2*Global`eps)/(t + t^2 - v), 
     (2*Global`eps*(t + 2*t^2 + t^3 - 2*t*v - v*(2 + v)))/
      (v*(1 + t + v)*(-t - t^2 + v)), -((Global`eps*(2 + 3*t + t^2 + v))/
       ((t + t^2 - v)*(1 + t + v)))}, 
    {(3*Global`eps*(1 + t))/(v*(1 + t + v)), (-2*Global`eps*(1 + t)^2)/
      (v*(1 + t^2 + t*(2 + v))), (Global`eps*(1 + t))/(v*(1 + t + v)), 
     (-2*Global`eps*(1 + t))/(v*(1 + t + v))}}, 
   {{(2*Global`eps*(4*t^4 - (1 + v)^2 + 3*t^2*(3 + v) + t^3*(11 + 5*v) + 
        t*(1 - 4*v - 5*v^2)))/(t*(1 + t)*(1 + t + v)*(1 + 2*t + t^2 + v)), 
     (-4*Global`eps)/(1 + t), (Global`eps*(1 + 3*t^2 + v + 4*t*(1 + v)))/
      (t*(1 + t)*(1 + t + v)), -((Global`eps*(1 + t^2 + v + 2*t*(1 + v)))/
       (t*(1 + t)*(1 + t + v)))}, 
    {(3*Global`eps*(-1 + 3*t^2 - v + 2*t*(1 + v)))/(t*(1 + t)*(1 + t + v)), 
     (-2*Global`eps*(1 + 2*t + t^2 + v)*(2 + 2*t^2 - v + t*(4 + v)))/
      ((1 + t)*(1 + 2*t + t^2 - v)*(1 + t^2 + t*(2 + v))), 
     (2*Global`eps*(1 + 2*t + t^2 + v)*(1 + 2*t^2 - v + t*(3 + v)))/
      (t*(1 + t)*(1 + 2*t + t^2 - v)*(1 + t + v)), 
     -((Global`eps*(1 + 2*t + t^2 + v))/(t*(1 + t)*(1 + t + v)))}, 
    {(-3*Global`eps*(1 + t^2 + v + 2*t*(1 + v)))/(t*(1 + t)*(1 + t + v)), 
     (2*Global`eps*(1 + 2*t + t^2 + v))/((1 + t)*(t + t^2 - v)), 
     (-2*Global`eps*v*(1 + 2*t + t^2 + v))/(t*(t + t^2 - v)*(1 + t + v)), 
     (Global`eps*(1 + 2*t + t^2 + v)*(t + t^2 + v + 2*t*v))/
      (t*(1 + t)*(t + t^2 - v)*(1 + t + v))}, 
    {(-3*Global`eps*(-1 + t^2 - v))/(t*(1 + t)*(1 + t + v)), 
     (2*Global`eps*(1 + 2*t + t^2 + v))/((1 + t)*(1 + t^2 + t*(2 + v))), 
     -((Global`eps*(1 + 2*t + t^2 + v))/(t*(1 + t)*(1 + t + v))), 
     (2*Global`eps*(1 + 2*t + t^2 + v))/(t*(1 + t)*(1 + t + v))}}}, 
 "Variables" -> {v, t}, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (-t - t^2 - t*v)/(1 + t), 
   "Root" -> 2*t + v + (2 + 2*w)/2|>, "AnsatzDegree" -> 0, 
 "Validated" -> True|>
