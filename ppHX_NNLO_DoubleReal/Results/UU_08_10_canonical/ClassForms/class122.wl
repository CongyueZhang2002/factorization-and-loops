<|"ClassID" -> 122, "RepFamily" -> "CF303", "RepRows" -> {1, 2}, "Dim" -> 2, 
 "Transformation" -> {{-(((1 + 2*Global`eps)*(1 + t))/(t*v*(1 + t + v))), 
    ((1 + 2*Global`eps)*(1 + t))/(2*t*(1 + t + v)*(1 + 2*t + t^2 + v))}, 
   {-(((1 + 2*Global`eps)^2*(1 + t)*((1 + 2*t + t^2 + v)^2 + 
        Global`eps*(1 + 10*t^3 + 3*t^4 + 4*v + 3*v^2 + 6*t*(1 + v) + 
          2*t^2*(6 + v))))/((1 + Global`eps)*t*v*(1 + t + v)*
       (1 + 2*t + t^2 + v)^2)), 
    -1/2*((1 + 2*Global`eps)^2*(1 + t)*(-2 - 2*t^3 - 3*v - v^2 - 
        6*t*(1 + v) - 3*t^2*(2 + v) + Global`eps*(-5 - 2*t^3 + t^4 - 8*v - 
          3*v^2 - 14*t*(1 + v) - 6*t^2*(2 + v))))/((1 + Global`eps)*t*
       (1 + t + v)*(1 + 2*t + t^2 + v)^3)}}, 
 "EpsForm" -> {{{(-2*Global`eps)/v, -1/2*Global`eps/(1 + 2*t + t^2 + v)}, 
    {(-4*Global`eps)/v, (Global`eps*(1 + 2*t + t^2 - v))/
      (v*(1 + 2*t + t^2 + v))}}, {{(2*Global`eps)/(1 + t), 
     (Global`eps*v)/((1 + t)*(1 + 2*t + t^2 + v))}, 
    {(8*Global`eps)/(1 + t), (-4*Global`eps*(1 + t))/(1 + 2*t + t^2 + v)}}}, 
 "Variables" -> {v, t}, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (-t - t^2 - t*v)/(1 + t), 
   "Root" -> 2*t + v + (2 + 2*w)/2|>, "AnsatzDegree" -> 0, 
 "Validated" -> True|>
