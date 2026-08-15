<|"ClassID" -> 115, "RepFamily" -> "CF299", "RepRows" -> {1, 2}, "Dim" -> 2, 
 "Variables" -> {v, w}, "Chart" -> <|"Variable" -> "u", 
   "Definition" -> Sqrt[1 - 4*v*w], "Inverse" -> "w -> (1-u^2)/(4 v)", 
   "Real" -> 
    "1-4vw == (v-w)^2+(1-v-w)(1+v+w) > 0 in the chamber, so u in (0,1]"|>, 
 "Transformation" -> {{1/Sqrt[1 - 4*v*w], 0}, {(1 + 8*eps)/(1 - 4*v*w)^(3/2), 
    eps/(1 - 4*v*w)}}, "TransformationInverse" -> 
  {{Sqrt[1 - 4*v*w], 0}, {(-1 - 8*eps)/eps, (1 - 4*v*w)/eps}}, 
 "EpsForm" -> {{{(2*eps*(1 + 4*v*w))/(v - 4*v^2*w), 
     eps/(2*v*Sqrt[1 - 4*v*w])}, {(-4*eps)/(v*Sqrt[1 - 4*v*w]), -(eps/v)}}, 
   {{(2*eps*(1 + 4*v*w))/(w - 4*v*w^2), eps/(2*w*Sqrt[1 - 4*v*w])}, 
    {(-4*eps)/(w*Sqrt[1 - 4*v*w]), -(eps/w)}}}, "AnsatzDegree" -> None, 
 "Method" -> 
  "one-variable reduction (z=v w) -> Gauss 2F1 -> Lee balances in u", 
 "Alphabet" -> {Sqrt[1 - 4*v*w], 1 - Sqrt[1 - 4*v*w], 1 + Sqrt[1 - 4*v*w]}, 
 "ResidueMatrices" -> <|"u0" -> {{-8, 0}, {0, 0}}, 
   "u1" -> {{2, 1/2}, {-4, -1}}, "um1" -> {{2, -1/2}, {4, -1}}, 
   "Sum" -> {{-4, 0}, {0, -2}}|>, "Hypergeometric" -> 
  <|"a" -> 1 + eps, "b" -> 1/2 + 2*eps, "c" -> 1 - eps, 
   "Argument" -> 4*v*w|>, "ClosedForm" -> 
  <|"F1" -> C[1]*Hypergeometric2F1[1 + eps, 1/2 + 2*eps, 1 - eps, 4*v*w] + 
     4^eps*(v*w)^eps*C[2]*Hypergeometric2F1[1 + 2*eps, 1/2 + 3*eps, 1 + eps, 
       4*v*w], "F2" -> "F2 = 2 v D[F1, v] + (1+4 eps) F1   (equals 2 x dF1/dx \
with x = 4 v w)", "Note" -> "supersedes the earlier record's literal D[F1, 4 \
v w], which is invalid Wolfram"|>, "Certificates" -> 
  <|"C0_UinvU_identity" -> True, "C2v_vw_chart_residual_zero" -> True, 
   "C2w_vw_chart_residual_zero" -> True, "C3_detU" -> eps/(1 - 4*v*w)^(3/2), 
   "ClosedForm_F2_relation" -> True, "Independent_2F1_numeric" -> 
    "residual 0 to ~447 digits at 3 rational points, both branches", 
   "Grade" -> "exact symbolic (C0,C2v,C2w,C3) + high-precision numeric (2F1 \
substitution)"|>, "Validated" -> True, "ValidatedBy" -> 
  "HardClassToolkit 1.0 AttackClass acceptance gate, 2026-08-14"|>
