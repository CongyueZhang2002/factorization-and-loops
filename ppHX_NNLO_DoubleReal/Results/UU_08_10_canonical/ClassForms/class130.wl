<|"ClassID" -> 130, "RepFamily" -> "CF319", "RepRows" -> {18, 19, 20}, 
 "Dim" -> 3, "Transformation" -> 
  {{-(((1 + 6*Global`eps)*(-1 + t))/((1 - 2*t + t^2 - v)*v)), 0, 0}, 
   {(2*Global`eps*(1 + 6*Global`eps)*(-1 + t))/(t*(1 - 2*t + t^2 - v)*v), 
    -((Global`eps*(1 + 6*Global`eps)*(-1 + t))/(t*v*(-1 + t + v))), 
    ((1 + 6*Global`eps)*(Global`eps - Global`eps*t))/
     ((1 + t^2 + t*(-2 + v))*v)}, {(2*Global`eps*(1 + 6*Global`eps))/
     (v*(-1 + 2*t - t^2 + v)), (Global`eps*(1 + 6*Global`eps))/v^2, 
    (Global`eps*(1 + 6*Global`eps))/v^2}}, 
 "EpsForm" -> {{{(Global`eps*(-1 + t^2 + v))/((1 - 2*t + t^2 - v)*
       (-1 + t + v)), Global`eps/(-1 + t + v), Global`eps/v}, 
    {(2*Global`eps*(-2 + 4*t - 2*t^2 + v))/((1 - 2*t + t^2 - v)*v), 
     (-2*Global`eps*(-1 + t + 2*v))/(v*(-1 + t + v)), 
     -((Global`eps*(2 + 2*t^2 + t*(-4 + v)))/((1 + t^2 + t*(-2 + v))*v))}, 
    {(4*Global`eps)/v, (2*Global`eps)/(-1 + t + v), 
     -((Global`eps*(-1 + t^2 + t*v))/((1 + t^2 + t*(-2 + v))*
        (-1 + t + v)))}}, 
   {{-((Global`eps*(3*t^4 + t^2*(12 - 8*v) + 6*t*(-1 + v) + (-1 + v)^2 + 
         2*t^3*(-5 + 2*v)))/((-1 + t)*t*(1 - 2*t + t^2 - v)*(-1 + t + v))), 
     -((Global`eps*(1 + t^2 + 2*t*(-1 + v) - v))/((-1 + t)*t*(-1 + t + v))), 
     (-2*Global`eps)/(-1 + t)}, {(2*Global`eps*(1 - 3*t^2 + 2*t^3 - v))/
      ((-1 + t)*t*(1 - 2*t + t^2 - v)), (2*Global`eps*v)/
      ((-1 + t)*(-1 + t + v)), (Global`eps*(3 + 3*t^2 + 2*t*(-3 + v) - v))/
      ((-1 + t)*(1 + t^2 + t*(-2 + v)))}, 
    {(-4*Global`eps*(1 + t))/((-1 + t)*t), (2*Global`eps*(1 - 2*t + t^2 - v))/
      ((-1 + t)*t*(-1 + t + v)), -((Global`eps*(1 - 2*t + t^2 - v)*
        (-1 + t^2 + t*v))/((-1 + t)*t*(1 + t^2 + t*(-2 + v))*
        (-1 + t + v)))}}}, "Variables" -> {v, t}, 
 "Chart" -> <|"Fixed" -> v, "Subst" -> w -> (-t + t^2 + t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 - 2*w)/2|>, "AnsatzDegree" -> 0, 
 "Validated" -> True|>
