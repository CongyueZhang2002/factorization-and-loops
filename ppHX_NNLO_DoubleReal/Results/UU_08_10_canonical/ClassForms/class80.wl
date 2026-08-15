<|"ClassID" -> 80, "RepFamily" -> "CF232", "RepRows" -> {9, 10, 11}, 
 "Dim" -> 3, "Transformation" -> 
  {{((1 + 6*Global`eps)*(1 + t))/(v*(1 + 2*t + t^2 + v)), 0, 0}, 
   {(-2*Global`eps*(1 + 6*Global`eps)*(1 + t))/(t*v*(1 + 2*t + t^2 + v)), 
    (Global`eps*(1 + 6*Global`eps)*(1 + t))/(v*(1 + t^2 + t*(2 + v))), 
    (Global`eps*(1 + 6*Global`eps)*(1 + t))/(t*v*(1 + t + v))}, 
   {(-2*Global`eps*(1 + 6*Global`eps)*(1 + t)^2)/(t*v^2*(1 + 2*t + t^2 + v)), 
    0, (Global`eps*(1 + 6*Global`eps)*(1 + t))/(t*v^2*(1 + t + v))}}, 
 "EpsForm" -> 
  {{{(Global`eps*(-1 + t^2 - v))/((1 + t + v)*(1 + 2*t + t^2 + v)), 
     -(Global`eps/v), -(Global`eps/(1 + t + v))}, 
    {(-4*Global`eps)/v, -((Global`eps*(-1 + t^2 + t*v))/
       ((1 + t + v)*(1 + t^2 + t*(2 + v)))), (2*Global`eps)/(1 + t + v)}, 
    {(2*Global`eps*(2 + 4*t + 2*t^2 + v))/(v*(1 + 2*t + t^2 + v)), 
     -((Global`eps*(2 + 2*t^2 + t*(4 + v)))/(v*(1 + t^2 + t*(2 + v)))), 
     (-2*Global`eps*(1 + t + 2*v))/(v*(1 + t + v))}}, 
   {{-((Global`eps*(3*t^4 + 6*t*(1 + v) + (1 + v)^2 + 4*t^2*(3 + 2*v) + 
         2*t^3*(5 + 2*v)))/(t*(1 + t)*(1 + t + v)*(1 + 2*t + t^2 + v))), 
     (2*Global`eps)/(1 + t), (Global`eps*(1 + t^2 + v + 2*t*(1 + v)))/
      (t*(1 + t)*(1 + t + v))}, {(4*Global`eps*(-1 + t))/(t*(1 + t)), 
     -((Global`eps*(1 + 2*t + t^2 + v)*(-1 + t^2 + t*v))/
       (t*(1 + t)*(1 + t + v)*(1 + t^2 + t*(2 + v)))), 
     (2*Global`eps*(1 + 2*t + t^2 + v))/(t*(1 + t)*(1 + t + v))}, 
    {(2*Global`eps*(1 - 3*t^2 - 2*t^3 + v))/(t*(1 + t)*(1 + 2*t + t^2 + v)), 
     (Global`eps*(3 + 3*t^2 + v + 2*t*(3 + v)))/
      ((1 + t)*(1 + t^2 + t*(2 + v))), (2*Global`eps*v)/
      ((1 + t)*(1 + t + v))}}}, "Variables" -> {v, t}, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (-t - t^2 - t*v)/(1 + t), 
   "Root" -> 2*t + v + (2 + 2*w)/2|>, "AnsatzDegree" -> 0, 
 "Validated" -> True|>
