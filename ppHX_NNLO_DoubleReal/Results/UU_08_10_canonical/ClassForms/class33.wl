<|"ClassID" -> 33, "RepFamily" -> "CF18", "RepRows" -> {4, 5, 8}, "Dim" -> 3, 
 "Transformation" -> 
  {{-1/2*((1 + 2*Global`eps)*(1 + t))/(v*(1 + 2*t + t^2 + v)), 0, 0}, 
   {-1/2*(Global`eps*(1 + 2*Global`eps)*(1 + t)*(1 + 4*t + 3*t^2 + v))/
      (t*v*(1 + t + v)*(1 + 2*t + t^2 + v)), 
    (Global`eps*(1 + 2*Global`eps)*(1 + t))/(2*t*v*(1 + t + v)), 
    -((Global`eps*(1 + 2*Global`eps)*(1 + t)^2)/(t*v*(1 + t + v)*
       (1 + t^2 + t*(2 + v))))}, 
   {-1/2*((1 + 2*Global`eps)*((1 + t)^2*(-1 + t^2 - v)*v + 
        Global`eps*(1 + 16*t^5 + 3*t^6 - 3*v - 3*v^2 + v^3 + 5*t^4*(7 + v) + 
          4*t^3*(10 + 3*v) + t^2*(25 + 6*v - v^2) - 4*t*(-2 + v + v^2))))/
      (v^2*(1 + 2*t + t^2 + v)^3), (Global`eps*(1 + 2*Global`eps)*
      (1 + 4*t + 6*t^2 + 4*t^3 + t^4 + v^2))/(2*v^2*(1 + 2*t + t^2 + v)^2), 
    -((Global`eps*(1 + 2*Global`eps)*(1 + t)*(1 + 2*t + t^2 - v))/
      (v^2*(1 + 2*t + t^2 + v)^2))}}, 
 "EpsForm" -> {{{(-2*Global`eps*(2 + 3*t + t^2 + 2*v))/
      ((1 + t + v)*(1 + 2*t + t^2 + v)), Global`eps/(1 + t + v), 
     (2*Global`eps*(1 + t))/(v*(1 + t + v))}, 
    {(2*Global`eps*(3 + 9*t^2 + 3*t^3 + v - 2*v^2 + t*(9 + v)))/
      (v*(1 + t + v)*(1 + 2*t + t^2 + v)), (Global`eps*(-2 - 2*t + v))/
      (v*(1 + t + v)), (2*Global`eps*(1 + t)*(3 + 3*t^2 + v + 3*t*(2 + v)))/
      (v*(1 + t + v)*(1 + t^2 + t*(2 + v)))}, 
    {(Global`eps*(2 + 2*t - v))/(v*(1 + t + v)), Global`eps/(1 + t + v), 
     -((Global`eps*(1 + 3*t^2 + t*(4 + 3*v)))/((1 + t + v)*
        (1 + t^2 + t*(2 + v))))}}, 
   {{(2*Global`eps*(t^3*(1 + v) + (1 + v)^2 + 3*t*(1 + v)^2 + t^2*(3 + 5*v)))/
      (t*(1 + t)*(1 + t + v)*(1 + 2*t + t^2 + v)), 
     -((Global`eps*(1 + t^2 + v + 2*t*(1 + v)))/(t*(1 + t)*(1 + t + v))), 
     (-2*Global`eps*(-1 + t^2 - v))/(t*(1 + t)*(1 + t + v))}, 
    {(2*Global`eps*(-8*t^3 - 3*t^4 + 2*t^2*(-3 + v) + 4*t*v*(1 + v) + 
        (1 + v)^2))/(t*(1 + t)*(1 + t + v)*(1 + 2*t + t^2 + v)), 
     -((Global`eps*(1 + t^2 + v + t*(2 + 4*v)))/(t*(1 + t)*(1 + t + v))), 
     (-2*Global`eps*(3*t^4 - 2*(1 + v) + t^2*(3 + v) + t^3*(7 + 3*v) - 
        t*(3 + 4*v + v^2)))/(t*(1 + t)*(1 + t + v)*(1 + t^2 + t*(2 + v)))}, 
    {-((Global`eps*(1 + 5*t^2 + v + 2*t*(3 + v)))/(t*(1 + t)*(1 + t + v))), 
     (Global`eps*(1 + 2*t + t^2 + v))/(t*(1 + t)*(1 + t + v)), 
     -((Global`eps*(1 + 2*t + t^2 + v)*(1 + 3*t^2 + t*(4 + 3*v)))/
       (t*(1 + t)*(1 + t + v)*(1 + t^2 + t*(2 + v))))}}}, 
 "Variables" -> {v, t}, "Chart" -> <|"Fixed" -> v, 
   "Subst" -> w -> (-t - t^2 - t*v)/(1 + t), 
   "Root" -> 2*t + v + (2 + 2*w)/2|>, "AnsatzDegree" -> 0, 
 "Validated" -> True|>
