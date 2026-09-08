(* Mathematical catalog data. Add formulas here; verification and system pullback live separately. *)
rationalizingParametrizationCatalogDefinitions[] := With[
  {v = $transportChartV, w = $transportChartW, x = $transportChartX,
   y = $transportChartY, s = $transportChartS, u = $transportChartU,
   p = $transportChartP, t = $transportChartT},
  Module[{k1, k2, k3, q4a, q4b, b115, k12, k13, k23, x12, x13, x23,
    k3b115k, k3b115a, k2b115, k3b115, kq4av, kq4a, kq4b},
  (* ---- single-root charts ------------------------------------------ *)
  k1 = <|"Name" -> "Kallen1", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {x, y},
    "SourceVariableSubstitution" -> {v -> x y, w -> (1 - x) (1 - y)},
    "RationalizedSquareRoots" -> {<|"RationalRoot" -> x - y, "SourceRadicand" -> transportChartLambda1[v, w]|>},
    "Notes" -> "sqrt(lambda1) = x - y, lambda1 = (1-v-w)^2 - 4 v w; Jacobian det x - y"|>;
  k2 = <|"Name" -> "Kallen2", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {x, y},
    "SourceVariableSubstitution" -> {v -> -x y, w -> (1 - x) (1 - y)},
    "RationalizedSquareRoots" -> {<|"RationalRoot" -> x - y, "SourceRadicand" -> transportChartLambda2[v, w]|>},
    "Notes" -> "lambda2(v,w) = lambda1(-v,w) = (x-y)^2"|>;
  k3 = <|"Name" -> "Kallen3", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {x, y},
    "SourceVariableSubstitution" -> {v -> x y, w -> -(1 - x) (1 - y)},
    "RationalizedSquareRoots" -> {<|"RationalRoot" -> x - y, "SourceRadicand" -> transportChartLambda3[v, w]|>},
    "Notes" -> "lambda3(v,w) = lambda1(v,-w) = (x-y)^2"|>;
  (* The Q4 charts keep the OTHER kinematic variable as a chart
     variable (v = p or w = p) and rationalize the root through the
     conic parametrization w = (p - s^2)/s (resp. v = ...), so that
     4v + w^2 = ((p + s^2)/s)^2.  MEASURED 2026-08-17: the naive
     parametrization v = (s^2 - u^2)/4, w = u turns a representative
     letter v + w - w^2 into a QUARTIC in the
     path variable (not admissible as algebraic letters); with p linear
     in the frozen variable every letter of these families is of degree
     <= 2 in s (letters quadratic in s: roots algebraic in p, admissible). *)
  q4a = <|"Name" -> "Q4a", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {p, s},
    "SourceVariableSubstitution" -> {v -> p, w -> (p - s^2)/s},
    "RationalizedSquareRoots" -> {<|"RationalRoot" -> (p + s^2)/s, "SourceRadicand" -> 4 v + w^2|>},
    "Notes" -> "4 v + w^2 = t^2 with the first kinematic variable kept, v = p: t = (p + s^2)/s; Jacobian det -(p + s^2)/s^2"|>;
  q4b = <|"Name" -> "Q4b", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {p, s},
    "SourceVariableSubstitution" -> {v -> (p - s^2)/s, w -> p},
    "RationalizedSquareRoots" -> {<|"RationalRoot" -> (p + s^2)/s, "SourceRadicand" -> v^2 + 4 w|>},
    "Notes" -> "the v<->w image, v^2 + 4 w = t^2 with w = p kept; Jacobian det (p + s^2)/s^2"|>;
  b115 = <|"Name" -> "Bilinear115", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {p, u},
    "SourceVariableSubstitution" -> {v -> p, w -> (1 - u^2)/(4 p)},
    "RationalizedSquareRoots" -> {<|"RationalRoot" -> u, "SourceRadicand" -> 1 - 4 v w|>},
    "Notes" -> "one-variable in u, u^2 = 1 - 4 v w; Jacobian det -u/(2p)"|>;
  (* ---- joint charts (derived 2026-08-17 by a rational point on the
          second conic in the base Kallen chart, verified exactly) ------ *)
  x12 = -2 (-3 y + s y + 2 y^2)/(-1 + s^2 + 4 y - 4 y^2);
  k12 = <|"Name" -> "Kallen12", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {y, s},
    "SourceVariableSubstitution" -> {v -> Together[x12 y], w -> Together[(1 - x12) (1 - y)]},
    "RationalizedSquareRoots" -> {
      <|"RationalRoot" -> Together[x12 - y], "SourceRadicand" -> transportChartLambda1[v, w]|>,
      <|"RationalRoot" -> Together[y + s x12], "SourceRadicand" -> transportChartLambda2[v, w]|>},
    "ParentParametrizationMaps" -> <|"Kallen1" -> {x -> x12, y -> y}|>,
    "Notes" -> "Kallen1 base; the line z = y + s x through the rational point \
(x, z) = (0, y) of z^2 = lambda2|_{Kallen1}; sqrt(lambda1) = x - y, \
sqrt(lambda2) = y + s x"|>;
  x13 = (1 + s) (-3 + s + 2 y)/(-1 + s^2 + 4 y - 4 y^2);
  k13 = <|"Name" -> "Kallen13", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {y, s},
    "SourceVariableSubstitution" -> {v -> Together[x13 y], w -> Together[(1 - x13) (1 - y)]},
    "RationalizedSquareRoots" -> {
      <|"RationalRoot" -> Together[x13 - y], "SourceRadicand" -> transportChartLambda1[v, w]|>,
      <|"RationalRoot" -> Together[(1 - y) + s (x13 - 1)], "SourceRadicand" -> transportChartLambda3[v, w]|>},
    "ParentParametrizationMaps" -> <|"Kallen1" -> {x -> x13, y -> y}|>,
    "Notes" -> "Kallen1 base; the line z = (1-y) + s (x-1) through the rational \
point (x, z) = (1, 1-y) of z^2 = lambda3|_{Kallen1}"|>;
  x23 = (-3 + s) (1 + s - 2 y)/(-1 + s^2);
  k23 = <|"Name" -> "Kallen23", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {y, s},
    "SourceVariableSubstitution" -> {v -> Together[-x23 y], w -> Together[(1 - x23) (1 - y)]},
    "RationalizedSquareRoots" -> {
      <|"RationalRoot" -> Together[x23 - y], "SourceRadicand" -> transportChartLambda2[v, w]|>,
      <|"RationalRoot" -> Together[(1 + y) + s (x23 - 1)], "SourceRadicand" -> transportChartLambda3[v, w]|>},
    "ParentParametrizationMaps" -> <|"Kallen2" -> {x -> x23, y -> y}|>,
    "Notes" -> "Kallen2 base; the line z = (1+y) + s (x-1) through the rational \
point (x, z) = (1, 1+y) of z^2 = lambda3|_{Kallen2}"|>;
  (* lambda3 together with the bilinear root sqrt(1-4 v w).  Begin with
     the Kallen3 parametrization v = a p, w = -(1-a)(1-p), for which
     sqrt(lambda3) = a-p.  Writing sqrt(1-4 v w) = 1 + u a makes the
     second square identity linear in a and gives

       a = (4 p (1-p) - 2 u)/(u^2 + 4 p (1-p)).

     This chart was first derived for a difficult family off-diagonal block equation, but the
     formula and lookup key are root-square data only: no family identity
     belongs in the package catalog. *)
  k3b115k = p (1 - p);
  k3b115a = Together[(4 k3b115k - 2 u)/(u^2 + 4 k3b115k)];
  (* lambda2(v,w) = lambda3(-v,-w), while 1-4 v w is invariant
     under the simultaneous sign flip.  The lambda2 joint chart is
     therefore the exact sign image of the lambda3 chart below, with
     the same chart variables and rationalized roots. *)
  k2b115 = <|
    "Name" -> "Kallen2Bilinear115", "Kind" -> "TwoVariable",
    "ParametrizingVariables" -> {p, u},
    "SourceVariableSubstitution" -> {v -> Together[-k3b115a p],
      w -> Together[(1 - k3b115a) (1 - p)]},
    "RationalizedSquareRoots" -> {
      <|"RationalRoot" -> Together[k3b115a - p],
        "SourceRadicand" -> transportChartLambda2[v, w]|>,
      <|"RationalRoot" -> Together[1 + u k3b115a],
        "SourceRadicand" -> 1 - 4 v w|>},
    "ParentParametrizationMaps" -> <|"Kallen2" -> {x -> k3b115a, y -> p}|>,
    "Notes" -> "the simultaneous source sign image of Kallen3Bilinear115: \
lambda2(v,w)=lambda3(-v,-w), while 1-4vw is invariant"|>;
  k3b115 = <|
    "Name" -> "Kallen3Bilinear115", "Kind" -> "TwoVariable",
    "ParametrizingVariables" -> {p, u},
    "SourceVariableSubstitution" -> {v -> Together[k3b115a p],
      w -> Together[-(1 - k3b115a) (1 - p)]},
    "RationalizedSquareRoots" -> {
      <|"RationalRoot" -> Together[k3b115a - p],
        "SourceRadicand" -> transportChartLambda3[v, w]|>,
      <|"RationalRoot" -> Together[1 + u k3b115a],
        "SourceRadicand" -> 1 - 4 v w|>},
    "ParentParametrizationMaps" -> <|"Kallen3" -> {x -> k3b115a, y -> p}|>,
    "Notes" -> "Kallen3 base v=a p, w=-(1-a)(1-p); imposing \
sqrt(1-4 v w)=1+u a gives a=(4 p(1-p)-2u)/(u^2+4 p(1-p))"|>;
  (* ---- joint charts for {lambda1, 4 v + w^2} and its v<->w image,
          derived 2026-08-24 by the ITERATED PENCIL and verified exactly
          (a measured production subsystem carries exactly this pair; the
          pair has no entry above, which stopped its solve with
          NeedsMultiquadraticRegulatorFactorization).

     Step 1.  4 v + w^2 is quadratic in w with leading coefficient 1, so
       the pencil sqrt(4 v + w^2) = w + t is rational:
         w = (4 v - t^2)/(2 t),   sqrt(4 v + w^2) = (4 v + t^2)/(2 t).
     Step 2.  lambda1 pulled back through step 1 is N(v,t)/(4 t^2) with
         N = 4 (t-2)^2 v^2 + 4 t (t^2 - 4 t - 4) v + t^2 (2 + t)^2,
       a quadratic in v whose leading coefficient 4 (t-2)^2 is a PERFECT
       SQUARE, so the pencil applies a second time: sqrt(N) =
       2 (t-2) v + s is LINEAR in v and solves for v rationally,
         v = (t^2 (2+t)^2 - s^2)/(4 (t-2) s - 4 t (t^2 - 4 t - 4)),
         sqrt(lambda1) = (2 (t-2) v + s)/(2 t).
     The chart is therefore an extension of Q4a along its own kept
     variable: Q4a at {p -> v(s,t), s -> t/2} reproduces Subst exactly
     (recorded as "Parents" and re-derived by TransportChartVerify).

     KallenQ4b is the v<->w image.  lambda1 is v<->w symmetric and
     v^2 + 4 w = (4 v + w^2)|_{v<->w}, so the same two pencils run with
     the roles of v and w exchanged (sqrt(v^2 + 4 w) = v + t first) and
     produce v_b = w_a, w_b = v_a with both root images unchanged. *)
  kq4av = (t^2 (2 + t)^2 - s^2)/(4 (t - 2) s - 4 t (t^2 - 4 t - 4));
  kq4a = <|"Name" -> "KallenQ4a", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {s, t},
    "SourceVariableSubstitution" -> {v -> Together[kq4av], w -> Together[(4 kq4av - t^2)/(2 t)]},
    "RationalizedSquareRoots" -> {
      <|"RationalRoot" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
        "SourceRadicand" -> transportChartLambda1[v, w]|>,
      <|"RationalRoot" -> Together[(4 kq4av + t^2)/(2 t)],
        "SourceRadicand" -> 4 v + w^2|>},
    (* Exact inverse from the two declared roots.  The generic chart
       composer validates every returned branch against Subst before it
       is used; recording the pencil inverse here avoids asking Solve to
       invert this high-degree rational presentation from scratch. *)
    "InverseParametrizationByRootValues" -> Function[{sourceValues, rootValues},
      With[{tau = rootValues[[2]] - sourceValues[[2]]},
        {Together[2 tau rootValues[[1]] -
          2 (tau - 2) sourceValues[[1]]], Together[tau]}]],
    "ParentParametrizationMaps" -> <|"Q4a" -> {p -> Together[kq4av], s -> t/2}|>,
    "Notes" -> "iterated pencil: sqrt(4 v + w^2) = w + t gives \
w = (4 v - t^2)/(2 t); lambda1 pulls back to N(v,t)/(4 t^2) with a square \
leading coefficient, and sqrt(N) = 2 (t-2) v + s solves for v linearly; \
sqrt(lambda1) = (2 (t-2) v + s)/(2 t), sqrt(4 v + w^2) = (4 v + t^2)/(2 t)"|>;
  kq4b = <|"Name" -> "KallenQ4b", "Kind" -> "TwoVariable", "ParametrizingVariables" -> {s, t},
    "SourceVariableSubstitution" -> {v -> Together[(4 kq4av - t^2)/(2 t)], w -> Together[kq4av]},
    "RationalizedSquareRoots" -> {
      <|"RationalRoot" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
        "SourceRadicand" -> transportChartLambda1[v, w]|>,
      <|"RationalRoot" -> Together[(4 kq4av + t^2)/(2 t)],
        "SourceRadicand" -> v^2 + 4 w|>},
    "InverseParametrizationByRootValues" -> Function[{sourceValues, rootValues},
      With[{tau = rootValues[[2]] - sourceValues[[1]]},
        {Together[2 tau rootValues[[1]] -
          2 (tau - 2) sourceValues[[2]]], Together[tau]}]],
    "ParentParametrizationMaps" -> <|"Q4b" -> {p -> Together[kq4av], s -> t/2}|>,
    "Notes" -> "the v<->w image of KallenQ4a: sqrt(v^2 + 4 w) = v + t \
gives v = (4 w - t^2)/(2 t), the pulled-back lambda1 is the SAME N with v \
replaced by w (lambda1 is v<->w symmetric), and sqrt(N) = 2 (t-2) w + s \
solves for w linearly; sqrt(lambda1) = (2 (t-2) w + s)/(2 t), \
sqrt(v^2 + 4 w) = (4 w + t^2)/(2 t)"|>;
  <|"Kallen1" -> k1, "Kallen2" -> k2, "Kallen3" -> k3, "Q4a" -> q4a, "Q4b" -> q4b,
    "Bilinear115" -> b115, "Kallen12" -> k12, "Kallen13" -> k13, "Kallen23" -> k23,
    "Kallen2Bilinear115" -> k2b115,
    "Kallen3Bilinear115" -> k3b115,
    "KallenQ4a" -> kq4a, "KallenQ4b" -> kq4b|>
]];

