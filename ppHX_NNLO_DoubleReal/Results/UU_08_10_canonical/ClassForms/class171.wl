<|"ClassID" -> 171, "RepFamily" -> "CF56", "RepRows" -> {3, 6}, "Dim" -> 2, 
 "Transformation" -> {{((1 + Global`eps)*(-1 + t))/
     (2*(1 + t^2 + 2*t*(-1 + v) - v)), 0}, 
   {((1 + 2*Global`eps)*(-1 + t)*(t^4 + (-1 + v)^2 - 
       2*t^3*(2 + (-1 + Global`eps)*v) + 2*t*(-1 + v)*
        (2 + (-1 + Global`eps)*v) + 2*t^2*(3 + (-3 + 2*Global`eps)*v + 
         (1 + 2*Global`eps)*v^2)))/(2*(1 + t^2 + 2*t*(-1 + v) - v)^3), 
    (Global`eps*(1 + 2*Global`eps)*(-1 + t)*(1 - 2*t + t^2 - v))/
     (2*(1 + t^2 + 2*t*(-1 + v) - v)^2)}}, 
 "EpsForm" -> {{{-((Global`eps*(-1 + t)*(1 + t^2 - v + t*(-2 + 6*v)))/
       ((1 + t^2 + 2*t*(-1 + v) - v)*v*(-1 + t + v))), 
     (Global`eps*(-1 + t))/(v*(-1 + t + v))}, 
    {(-2*Global`eps*(-1 + t)*(t^4 + (-1 + v)^2 + t^3*(-4 + 5*v) + 
        t*(-4 + 9*v - 5*v^2) - 6*t^2*(-1 + 2*v + v^2)))/
      ((1 - 2*t + t^2 - v)*(1 + t^2 + 2*t*(-1 + v) - v)*v*(-1 + t + v)), 
     (2*Global`eps*(-1 + t)*(1 + t^2 - v - t*(2 + v)))/
      ((1 - 2*t + t^2 - v)*v*(-1 + t + v))}}, 
   {{(Global`eps*(t^4 - (-1 + v)^2 + t^3*(-2 + 6*v) + t*(2 - 8*v + 6*v^2)))/
      ((-1 + t)*t*(1 + t^2 + 2*t*(-1 + v) - v)*(-1 + t + v)), 
     -((Global`eps*(-1 + t^2 + v))/((-1 + t)*t*(-1 + t + v)))}, 
    {(2*Global`eps*(t^6 + (-1 + v)^3 + t^5*(-4 + 5*v) - 
        t*(-1 + v)^2*(-4 + 5*v) + t^4*(5 - 11*v - 6*v^2) - 
        t^2*(5 - 16*v + 5*v^2 + 6*v^3)))/((-1 + t)*t*(1 - 2*t + t^2 - v)*
       (1 + t^2 + 2*t*(-1 + v) - v)*(-1 + t + v)), 
     (2*Global`eps*(-t^4 + (-1 + v)^2 + t^3*(2 + v) + t*(-2 + v + v^2)))/
      ((-1 + t)*t*(1 - 2*t + t^2 - v)*(-1 + t + v))}}}, 
 "Variables" -> {v, t}, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (-t + t^2 + t*v)/(-1 + t), 
   "Root" -> 2*t + v + (-2 - 2*w)/2|>, "AnsatzDegree" -> 1, 
 "Validated" -> True|>
