(* Stage 2: the catalog of rationalizing charts, the per-family chart
   assignment, and the composition of a class record's own chart with a
   target chart.

   WHY (measured 2026-08-17, coordinator census over all 91 families;
   scratch chart_census / conic_census / alphabet missions, recorded in
   TransportProductionPlan.md):

     * 20 conic-chart classes and 3 two-variable classes need a SQUARE
       ROOT to have a rational eps-form; only FIVE distinct quadratics
       occur:
           lambda1 = (1-v-w)^2 - 4 v w          (Kallen; classes 26,49,95,101,
                                                  130,165,166,171; two-var 77,97)
           lambda2 = lambda1(-v, w)              (classes 33,62,80,118,122,123;
                                                  two-var 79)
           lambda3 = lambda1(v, -w)              (classes 75,90,91,92,93)
           4 v + w^2                             (class 98; v^2 + 4 w for its
                                                  v<->w members)
           1 - 4 v w                             (class 115, one-variable u)
       and a class member may carry the v<->w image of its
       representative's quadratic (measured: CF53/CF57 host classes
       90/93/91 with lambda2, CF48/CF52 host class 98 with v^2 + 4 w).
     * A family needs ONE chart in which every class form it hosts is
       rational.  Single-root families take the chart of their root;
       two-root families take a JOINT chart built on the Kallen chart by
       a rational point on the second conic (derived and verified
       exactly 2026-08-17 01:42, pool mission jcharts2); the three
       triple-root families (CF259, CF300, CF303) are not covered here
       yet.
     * Polynomial letters that are quadratic in the moving path variable
       in every rational chart (1 - w + v w in the Kallen chart is a
       (2,2)-curve on P^1 x P^1) are handled by ALGEBRAIC LETTERS
       (MasterTransport.wl, masterTransportMonicCheck), not by charts.
       Charts exist to make the block transformations rational, nothing
       else.

   Every chart in the catalog carries the exact identities that license
   it (root^2 == RootSquare o Subst, Jacobian nondegenerate) and
   TransportChartVerify re-derives them; nothing is believed from the
   record.

   Physics bookkeeping (chamber, branch, sign of the root) is NOT done
   here -- same discipline as TransportFamilyInChart: the chart and its
   Jacobian determinant are recorded so that stage 3 can choose.

   Layer position (round 7, 2026-09-02): this file IS the Geometry layer
   and loads BEFORE EpsForm.  The in-frame strip solver
   SolveEpsFormStripInFrame and the helpers only it used (stage log,
   broker-parallel Together/decompose/Jacobian tasks, deferred-bundle
   pullbacks, deadline bookkeeping, timings, the retired Maple stub)
   moved verbatim to EpsForm/Strip/EpsFormStripInFrame.wl, so nothing
   here references an EpsForm symbol; the record-to-chart resolution
   observableTransportRecordChart (with observableTransportSourceFrameQ)
   came down from Transport because FamilyEpsForm needs it. *)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[TransportChartCatalog, TransportChartVerify, ComposeTransportChartExtension, RationalizeTransportChartExtension, TransportFamilyChartRegister, TransportFamilyChartLoad, TransportFamilyChart];
ClearAll[
  masterTransportChartByName,
  masterTransportComposeTwoVariableRecord,
  masterTransportRecordCoordinateMap,
  observableTransportSourceFrameQ,
  observableTransportRecordChart,
  transportChartRationalExpressionQ,
  transportChartLoadRationalizeRoots,
  transportChartExtensionCandidates,
  transportFamilyChartEntryKind,
  transportFamilyChartAlias
];



(* the source variables and the chart variables, by NAME; callers
   re-key by SymbolName as everywhere in this module *)
$transportChartV = Symbol["Global`v"];
$transportChartW = Symbol["Global`w"];
$transportChartX = Symbol["Global`x"];
$transportChartY = Symbol["Global`y"];
$transportChartS = Symbol["Global`s"];
$transportChartU = Symbol["Global`u"];
$transportChartP = Symbol["Global`p"];
(* the second parameter of the iterated pencil (KallenQ4a/b); "tau" in
   the derivation note, kept short to match the rest of the catalog *)
$transportChartT = Symbol["Global`t"];

transportChartLambda1[v_, w_] := (1 - v - w)^2 - 4 v w;
transportChartLambda2[v_, w_] := transportChartLambda1[-v, w];
transportChartLambda3[v_, w_] := transportChartLambda1[v, -w];

TransportChartCatalog[] := With[
  {v = $transportChartV, w = $transportChartW, x = $transportChartX,
   y = $transportChartY, s = $transportChartS, u = $transportChartU,
   p = $transportChartP, t = $transportChartT},
  Module[{k1, k2, k3, q4a, q4b, b115, k12, k13, k23, x12, x13, x23,
    k3b115k, k3b115a, k2b115, k3b115, kq4av, kq4a, kq4b},
  (* ---- single-root charts ------------------------------------------ *)
  k1 = <|"Name" -> "Kallen1", "Kind" -> "TwoVariable", "Variables" -> {x, y},
    "Subst" -> {v -> x y, w -> (1 - x) (1 - y)},
    "Root" -> x - y, "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {<|"Root" -> x - y, "RootSquare" -> transportChartLambda1[v, w]|>},
    "Notes" -> "sqrt(lambda1) = x - y, lambda1 = (1-v-w)^2 - 4 v w; Jacobian det x - y"|>;
  k2 = <|"Name" -> "Kallen2", "Kind" -> "TwoVariable", "Variables" -> {x, y},
    "Subst" -> {v -> -x y, w -> (1 - x) (1 - y)},
    "Root" -> x - y, "RootSquare" -> transportChartLambda2[v, w],
    "Roots" -> {<|"Root" -> x - y, "RootSquare" -> transportChartLambda2[v, w]|>},
    "Notes" -> "lambda2(v,w) = lambda1(-v,w) = (x-y)^2"|>;
  k3 = <|"Name" -> "Kallen3", "Kind" -> "TwoVariable", "Variables" -> {x, y},
    "Subst" -> {v -> x y, w -> -(1 - x) (1 - y)},
    "Root" -> x - y, "RootSquare" -> transportChartLambda3[v, w],
    "Roots" -> {<|"Root" -> x - y, "RootSquare" -> transportChartLambda3[v, w]|>},
    "Notes" -> "lambda3(v,w) = lambda1(v,-w) = (x-y)^2"|>;
  (* The Q4 charts keep the OTHER kinematic variable as a chart
     variable (v = p or w = p) and rationalize the root through the
     conic parametrization w = (p - s^2)/s (resp. v = ...), so that
     4v + w^2 = ((p + s^2)/s)^2.  MEASURED 2026-08-17 (chart probes on
     CF48/CF232): the naive parametrization v = (s^2 - u^2)/4, w = u
     turns the letter v + w - w^2 of CF48/CF52 into a QUARTIC in the
     path variable (not admissible as algebraic letters); with p linear
     in the frozen variable every letter of these families is of degree
     <= 2 in s (letters quadratic in s: roots algebraic in p, admissible). *)
  q4a = <|"Name" -> "Q4a", "Kind" -> "TwoVariable", "Variables" -> {p, s},
    "Subst" -> {v -> p, w -> (p - s^2)/s},
    "Root" -> (p + s^2)/s, "RootSquare" -> 4 v + w^2,
    "Roots" -> {<|"Root" -> (p + s^2)/s, "RootSquare" -> 4 v + w^2|>},
    "Notes" -> "4 v + w^2 = t^2 with the first kinematic variable kept, v = p: t = (p + s^2)/s; Jacobian det -(p + s^2)/s^2"|>;
  q4b = <|"Name" -> "Q4b", "Kind" -> "TwoVariable", "Variables" -> {p, s},
    "Subst" -> {v -> (p - s^2)/s, w -> p},
    "Root" -> (p + s^2)/s, "RootSquare" -> v^2 + 4 w,
    "Roots" -> {<|"Root" -> (p + s^2)/s, "RootSquare" -> v^2 + 4 w|>},
    "Notes" -> "the v<->w image, v^2 + 4 w = t^2 with w = p kept; Jacobian det (p + s^2)/s^2"|>;
  b115 = <|"Name" -> "Bilinear115", "Kind" -> "TwoVariable", "Variables" -> {p, u},
    "Subst" -> {v -> p, w -> (1 - u^2)/(4 p)},
    "Root" -> u, "RootSquare" -> 1 - 4 v w,
    "Roots" -> {<|"Root" -> u, "RootSquare" -> 1 - 4 v w|>},
    "Notes" -> "one-variable in u, u^2 = 1 - 4 v w; Jacobian det -u/(2p)"|>;
  (* ---- joint charts (derived 2026-08-17 by a rational point on the
          second conic in the base Kallen chart, verified exactly) ------ *)
  x12 = -2 (-3 y + s y + 2 y^2)/(-1 + s^2 + 4 y - 4 y^2);
  k12 = <|"Name" -> "Kallen12", "Kind" -> "TwoVariable", "Variables" -> {y, s},
    "Subst" -> {v -> Together[x12 y], w -> Together[(1 - x12) (1 - y)]},
    "Root" -> Together[x12 - y], "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {
      <|"Root" -> Together[x12 - y], "RootSquare" -> transportChartLambda1[v, w]|>,
      <|"Root" -> Together[y + s x12], "RootSquare" -> transportChartLambda2[v, w]|>},
    "Parents" -> <|"Kallen1" -> {x -> x12, y -> y}|>,
    "Notes" -> "Kallen1 base; the line z = y + s x through the rational point \
(x, z) = (0, y) of z^2 = lambda2|_{Kallen1}; sqrt(lambda1) = x - y, \
sqrt(lambda2) = y + s x"|>;
  x13 = (1 + s) (-3 + s + 2 y)/(-1 + s^2 + 4 y - 4 y^2);
  k13 = <|"Name" -> "Kallen13", "Kind" -> "TwoVariable", "Variables" -> {y, s},
    "Subst" -> {v -> Together[x13 y], w -> Together[(1 - x13) (1 - y)]},
    "Root" -> Together[x13 - y], "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {
      <|"Root" -> Together[x13 - y], "RootSquare" -> transportChartLambda1[v, w]|>,
      <|"Root" -> Together[(1 - y) + s (x13 - 1)], "RootSquare" -> transportChartLambda3[v, w]|>},
    "Parents" -> <|"Kallen1" -> {x -> x13, y -> y}|>,
    "Notes" -> "Kallen1 base; the line z = (1-y) + s (x-1) through the rational \
point (x, z) = (1, 1-y) of z^2 = lambda3|_{Kallen1}"|>;
  x23 = (-3 + s) (1 + s - 2 y)/(-1 + s^2);
  k23 = <|"Name" -> "Kallen23", "Kind" -> "TwoVariable", "Variables" -> {y, s},
    "Subst" -> {v -> Together[-x23 y], w -> Together[(1 - x23) (1 - y)]},
    "Root" -> Together[x23 - y], "RootSquare" -> transportChartLambda2[v, w],
    "Roots" -> {
      <|"Root" -> Together[x23 - y], "RootSquare" -> transportChartLambda2[v, w]|>,
      <|"Root" -> Together[(1 + y) + s (x23 - 1)], "RootSquare" -> transportChartLambda3[v, w]|>},
    "Parents" -> <|"Kallen2" -> {x -> x23, y -> y}|>,
    "Notes" -> "Kallen2 base; the line z = (1+y) + s (x-1) through the rational \
point (x, z) = (1, 1+y) of z^2 = lambda3|_{Kallen2}"|>;
  (* lambda3 together with the bilinear root sqrt(1-4 v w).  Begin with
     the Kallen3 parametrization v = a p, w = -(1-a)(1-p), for which
     sqrt(lambda3) = a-p.  Writing sqrt(1-4 v w) = 1 + u a makes the
     second square identity linear in a and gives

       a = (4 p (1-p) - 2 u)/(u^2 + 4 p (1-p)).

     This chart was first derived for a difficult family strip, but the
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
    "Variables" -> {p, u},
    "Subst" -> {v -> Together[-k3b115a p],
      w -> Together[(1 - k3b115a) (1 - p)]},
    "Root" -> Together[k3b115a - p],
    "RootSquare" -> transportChartLambda2[v, w],
    "Roots" -> {
      <|"Root" -> Together[k3b115a - p],
        "RootSquare" -> transportChartLambda2[v, w]|>,
      <|"Root" -> Together[1 + u k3b115a],
        "RootSquare" -> 1 - 4 v w|>},
    "Parents" -> <|"Kallen2" -> {x -> k3b115a, y -> p}|>,
    "Notes" -> "the simultaneous source sign image of Kallen3Bilinear115: \
lambda2(v,w)=lambda3(-v,-w), while 1-4vw is invariant"|>;
  k3b115 = <|
    "Name" -> "Kallen3Bilinear115", "Kind" -> "TwoVariable",
    "Variables" -> {p, u},
    "Subst" -> {v -> Together[k3b115a p],
      w -> Together[-(1 - k3b115a) (1 - p)]},
    "Root" -> Together[k3b115a - p],
    "RootSquare" -> transportChartLambda3[v, w],
    "Roots" -> {
      <|"Root" -> Together[k3b115a - p],
        "RootSquare" -> transportChartLambda3[v, w]|>,
      <|"Root" -> Together[1 + u k3b115a],
        "RootSquare" -> 1 - 4 v w|>},
    "Parents" -> <|"Kallen3" -> {x -> k3b115a, y -> p}|>,
    "Notes" -> "Kallen3 base v=a p, w=-(1-a)(1-p); imposing \
sqrt(1-4 v w)=1+u a gives a=(4 p(1-p)-2u)/(u^2+4 p(1-p))"|>;
  (* ---- joint charts for {lambda1, 4 v + w^2} and its v<->w image,
          derived 2026-08-24 by the ITERATED PENCIL and verified exactly
          (CF259 rows 1..16 carry exactly this pair; the pair has no
          entry above, which is what stopped the family solve with
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
  kq4a = <|"Name" -> "KallenQ4a", "Kind" -> "TwoVariable", "Variables" -> {s, t},
    "Subst" -> {v -> Together[kq4av], w -> Together[(4 kq4av - t^2)/(2 t)]},
    "Root" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
    "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {
      <|"Root" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
        "RootSquare" -> transportChartLambda1[v, w]|>,
      <|"Root" -> Together[(4 kq4av + t^2)/(2 t)],
        "RootSquare" -> 4 v + w^2|>},
    (* Exact inverse from the two declared roots.  The generic chart
       composer validates every returned branch against Subst before it
       is used; recording the pencil inverse here avoids asking Solve to
       invert this high-degree rational presentation from scratch. *)
    "InverseByRoots" -> Function[{sourceValues, rootValues},
      With[{tau = rootValues[[2]] - sourceValues[[2]]},
        {Together[2 tau rootValues[[1]] -
          2 (tau - 2) sourceValues[[1]]], Together[tau]}]],
    "Parents" -> <|"Q4a" -> {p -> Together[kq4av], s -> t/2}|>,
    "Notes" -> "iterated pencil: sqrt(4 v + w^2) = w + t gives \
w = (4 v - t^2)/(2 t); lambda1 pulls back to N(v,t)/(4 t^2) with a square \
leading coefficient, and sqrt(N) = 2 (t-2) v + s solves for v linearly; \
sqrt(lambda1) = (2 (t-2) v + s)/(2 t), sqrt(4 v + w^2) = (4 v + t^2)/(2 t)"|>;
  kq4b = <|"Name" -> "KallenQ4b", "Kind" -> "TwoVariable", "Variables" -> {s, t},
    "Subst" -> {v -> Together[(4 kq4av - t^2)/(2 t)], w -> Together[kq4av]},
    "Root" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
    "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {
      <|"Root" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
        "RootSquare" -> transportChartLambda1[v, w]|>,
      <|"Root" -> Together[(4 kq4av + t^2)/(2 t)],
        "RootSquare" -> v^2 + 4 w|>},
    "InverseByRoots" -> Function[{sourceValues, rootValues},
      With[{tau = rootValues[[2]] - sourceValues[[1]]},
        {Together[2 tau rootValues[[1]] -
          2 (tau - 2) sourceValues[[2]]], Together[tau]}]],
    "Parents" -> <|"Q4b" -> {p -> Together[kq4av], s -> t/2}|>,
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

masterTransportChartByName[name_String] := Lookup[TransportChartCatalog[], name, None];

(* Moved verbatim from Transport/Observable/ObservableTransport.wl (round 7,
   2026-09-02): a record's chart resolved against the catalog; the source
   frame is named, never a chart.  FamilyEpsForm.wl (EpsForm) and the
   observable transport both use it. *)
observableTransportSourceFrameQ[value_] := Module[
  {name = ToLowerCase@StringReplace[ToString[value, InputForm],
      Except[LetterCharacter | DigitCharacter] -> ""]},
  MemberQ[{"sourcevw", "sourcevwx", "sourcevwy", "source"}, name]
];

observableTransportRecordChart[record_Association, Automatic] := Module[
  {chartRecord = Lookup[record, "ChartRecord", Missing["NotAvailable"]],
   chart = Lookup[record, "Chart", None],
   frame = Lookup[record, "Frame", None]},
  Which[
    AssociationQ[chartRecord], chartRecord,
    observableTransportSourceFrameQ[frame] ||
      observableTransportSourceFrameQ[chart], None,
    chart === None || MissingQ[chart], None,
    StringQ[chart], Lookup[TransportChartCatalog[], chart, $Failed],
    AssociationQ[chart], chart,
    True, $Failed
  ]
];

observableTransportRecordChart[record_Association, chart_] := chart;

(* exact re-derivation of what a chart record claims.
   The SOURCE variables are read from the record's own substitution, not
   from the package's Global v/w (generality pass 2026-08-23): a frame
   built by BuildAlgebraicTransportFrame in a caller's symbols declares
   its root squares in THOSE symbols, and verifying it against v/w
   compared two different expressions and refused a correct frame.  For
   every catalog chart the substitution keys ARE v and w, so this is the
   same computation as before. *)
TransportChartVerify[chart_Association] := Module[
  {vars, subst, sourceVariables, f, g, jac, det, roots, rootChecks, parents,
    parentCharts, parentChecks, ok},
    vars = chart["Variables"]; subst = chart["Subst"];
    sourceVariables = First /@ subst;
    {f, g} = Together /@ (Last /@ subst);
    jac = {{D[f, vars[[1]]], D[f, vars[[2]]]}, {D[g, vars[[1]]], D[g, vars[[2]]]}};
    det = Together[Det[jac]];
    roots = Lookup[chart, "Roots", {<|"Root" -> chart["Root"], "RootSquare" -> chart["RootSquare"]|>}];
    rootChecks = Table[
      TrueQ[Together[r["Root"]^2 -
        (r["RootSquare"] /. Thread[sourceVariables -> {f, g}])] === 0],
      {r, roots}];
    parents = Lookup[chart, "Parents", <||>];
    parentCharts = Lookup[chart, "ParentCharts", <||>];
    parentChecks = Association @ KeyValueMap[
      Function[{parentName, map},
        Module[{parent = Lookup[parentCharts, parentName,
            masterTransportChartByName[parentName]], pf, pg},
          If[parent === None, parentName -> False,
            {pf, pg} = Last /@ parent["Subst"];
            parentName -> (TrueQ[Together[(pf /. map) - f] === 0] &&
              TrueQ[Together[(pg /. map) - g] === 0])]]],
      parents];
    ok = AllTrue[rootChecks, TrueQ] && ! TrueQ[det === 0] &&
      AllTrue[Values[parentChecks], TrueQ];
    <|"OK" -> ok, "Name" -> Lookup[chart, "Name", "?"], "RootIdentities" -> rootChecks,
      "JacobianDet" -> Factor[det], "ParentMaps" -> parentChecks|>];

BuildAlgebraicTransportFrame[rootSquares_List,
    sourceVariables : {_Symbol, _Symbol},
    chartVariables : {_Symbol, _Symbol}] := Module[
  {substitution, pulledSquares, roots, chart, certificate, name},
  If[Length[DeleteDuplicates[SymbolName /@
        Join[sourceVariables, chartVariables]]] =!= 4,
    Return[<|"Status" -> "AlgebraicFrameVariablesCollide"|>]];
  substitution = Thread[sourceVariables -> chartVariables];
  pulledSquares = Together /@ (rootSquares /. substitution);
  roots = MapThread[
    <|"Root" -> Sqrt[#1], "RootSquare" -> #2|> &,
    {pulledSquares, rootSquares}];
  name = "Multiquadratic" <> ToString[Length[roots]];
  chart = <|
    "Name" -> name,
    "Kind" -> "TwoVariable",
    "FieldKind" -> "Multiquadratic",
    "CoefficientField" -> "Multiquadratic",
    "Variables" -> chartVariables,
    "Subst" -> substitution,
    "Root" -> If[roots === {}, None, roots[[1, "Root"]]],
    "RootSquare" -> If[roots === {}, None, roots[[1, "RootSquare"]]],
    "Roots" -> roots,
    "Notes" -> "identity change of variables with every declared square root retained exactly"
  |>;
  certificate = TransportChartVerify[chart];
  If[! TrueQ[certificate["OK"]],
    Return[<|"Status" -> "AlgebraicFrameIdentityFailed",
      "Frame" -> chart, "Certificate" -> certificate|>]];
  Join[chart, <|"Status" -> "ExactFrame",
    "ChartCertificate" -> certificate|>]
];

FamilyAlgebraicRootCensus[assembly_Association, frame_Association] := Module[
  {roots, zeroBlockQ, blocks, ranges,
   connection, records, unmatched},
  If[Lookup[assembly, "Status", None] =!= "OK" ||
      ! ListQ[Lookup[assembly, "Blocks", None]] ||
      ! ListQ[Lookup[assembly, "Ranges", None]],
    Return[<|"Status" -> "FamilyAssemblyInvalid"|>]];
  roots = Lookup[frame, "Roots", {}];
  If[! ListQ[roots], Return[<|"Status" -> "AlgebraicFrameRootsInvalid"|>]];
  zeroBlockQ[expr_] := AllTrue[Flatten[expr],
    TrueQ[Together[#] === 0] &];
  blocks = assembly["Blocks"];
  ranges = assembly["Ranges"];
  connection = {assembly["Apv"], assembly["Apw"]};
  records = Flatten[Table[
    If[i > j,
      Module[{block, classification},
        block = connection[[All, ranges[[i]], ranges[[j]]]];
        If[zeroBlockQ[block], Nothing,
          classification = transportChartRootIndices[block, roots];
          <|"BlockPair" -> {i, j},
            "FamilyRows" -> {blocks[[i]], blocks[[j]]},
            "RootIndices" -> classification["RootIndices"],
            "RootCount" -> Length[classification["RootIndices"]],
            "RadicalBases" -> classification["RadicalBases"],
            "UnclassifiedRadicalBases" ->
              classification["UnclassifiedRadicalBases"],
            "DenestedRadicalBases" ->
              Keys[Lookup[classification, "DenestedRadicalBases", <||>]],
            "NumericRadicalClasses" ->
              Lookup[classification, "NumericRadicalClasses", {}]|>]],
      Nothing],
    {i, Length[blocks]}, {j, Length[blocks]}], 1];
  unmatched = DeleteDuplicates[Flatten[
    Lookup[records, "UnclassifiedRadicalBases", {}]]];
  <|"Status" -> If[unmatched === {}, "ExactRootCensus",
      "UnclassifiedRadicals"],
    "Family" -> Lookup[assembly, "Family", None],
    "RootSquares" -> Lookup[roots, "RootSquare", {}],
    "NonzeroOffDiagonalBlocks" -> Length[records],
    "RootCountHistogram" -> Counts[Lookup[records, "RootCount", {}]],
    "MaximumRootCount" -> Max[Append[Lookup[records, "RootCount", {}], 0]],
    "ThreeRootBlocks" -> Select[records, #["RootCount"] >= 3 &],
    "UnclassifiedRadicalBases" -> unmatched,
    (* radicands accepted by exact denesting rather than by a direct
       match (2026-08-24): classified, but not literally declared *)
    "DenestedRadicalBases" -> DeleteDuplicates[Flatten[
      Lookup[records, "DenestedRadicalBases", {}]]],
    "NumericRadicalClasses" -> DeleteDuplicates[Flatten[
      Lookup[records, "NumericRadicalClasses", {}]]],
    "Blocks" -> records|>
];

TransportRootSetChart[rootSquares_List,
    sourceVariables : {_Symbol, _Symbol}] := Module[
  {wanted, candidates},
  wanted = DeleteDuplicates[Together /@
    (rootSquares /. Thread[sourceVariables ->
      {$transportChartV, $transportChartW}])];
  If[wanted === {}, Return[None]];
  candidates = Select[Values[TransportChartCatalog[]], Function[chart,
    Module[{chartRoots = Lookup[chart, "Roots", {}], chartSquares},
      If[Length[chartRoots] < Length[wanted], False,
        chartSquares = Together /@ Lookup[chartRoots, "RootSquare", {}];
        AllTrue[wanted, Function[q, AnyTrue[chartSquares,
          Function[candidate,
            TrueQ[Together[q - candidate] === 0]]]]]]]]];
  If[candidates === {},
    Missing["NoRationalChart", wanted],
    First[SortBy[candidates,
      {Function[chart, Length[Lookup[chart, "Roots", {}]]],
       Function[chart, LeafCount[Lookup[chart, "Subst", {}]]]}]]]
];

TransportRootSetChart[rootSquares_List] := TransportRootSetChart[
  rootSquares, {$transportChartV, $transportChartW}];

transportChartRationalExpressionQ[expr_, variables_List] :=
  FreeQ[Unevaluated[expr], _Root |
    Power[_, exponent_Rational /; Denominator[exponent] > 1]] &&
  PolynomialQ[Numerator[Together[expr]], variables] &&
  PolynomialQ[Denominator[Together[expr]], variables];

ComposeTransportChartExtension[baseChart_Association, rootSquare_,
    extensionRules_List, newVariables : {_Symbol, _Symbol}] := Module[
  {baseVariables, sourceVariables, baseSubst, pullBack, variableRules,
   rootRules, extensionRootRule, extensionRoot, subst, inheritedRoots,
   roots, parentName, name, chart, certificate},

  baseVariables = Lookup[baseChart, "Variables", Missing[]];
  baseSubst = Lookup[baseChart, "Subst", Missing[]];
  If[! MatchQ[baseVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[baseSubst, {_Rule, _Rule}],
    Return[<|"Status" -> "BaseChartNotWellFormed"|>]
  ];
  sourceVariables = First /@ baseSubst;
  pullBack = Together[rootSquare /. baseSubst];
  variableRules = Select[extensionRules,
    MemberQ[baseVariables, First[#]] &];
  If[Sort[First /@ variableRules] =!= Sort[baseVariables],
    Return[<|"Status" -> "ExtensionVariablesNotMapped",
      "Expected" -> baseVariables|>]
  ];
  variableRules = Table[
    variable -> (variable /. variableRules), {variable, baseVariables}];
  If[! AllTrue[Last /@ variableRules,
      transportChartRationalExpressionQ[#, newVariables] &],
    Return[<|"Status" -> "ExtensionMapNotRational"|>]
  ];

  rootRules = Select[extensionRules,
    ! MemberQ[baseVariables, First[#]] &];
  extensionRootRule = SelectFirst[rootRules,
    TrueQ[Together[(Last[#] /. variableRules)^2 -
          (pullBack /. variableRules)] === 0] &&
      transportChartRationalExpressionQ[
        Last[#] /. variableRules, newVariables] &,
    Missing["NoRootRule"]];
  If[MissingQ[extensionRootRule],
    Return[<|"Status" -> "ExtensionRootNotMapped",
      "PulledBackRootSquare" -> pullBack|>]
  ];
  extensionRoot = Together[Last[extensionRootRule] /. variableRules];

  subst = Map[
    Function[rule, First[rule] -> Together[Last[rule] /. variableRules]],
    baseSubst];
  If[! AllTrue[Last /@ subst,
      transportChartRationalExpressionQ[#, newVariables] &],
    Return[<|"Status" -> "ComposedMapNotRational"|>]
  ];
  inheritedRoots = Lookup[baseChart, "Roots",
    {<|"Root" -> baseChart["Root"],
       "RootSquare" -> baseChart["RootSquare"]|>}];
  inheritedRoots = Map[
    <|"Root" -> Together[#["Root"] /. variableRules],
      "RootSquare" -> #["RootSquare"]|> &,
    inheritedRoots];
  roots = Append[inheritedRoots,
    <|"Root" -> extensionRoot, "RootSquare" -> rootSquare|>];
  parentName = Lookup[baseChart, "Name", "BaseChart"];
  name = parentName <> "+" <>
    StringTake[IntegerString[Hash[rootSquare, "SHA256"], 16], 12];
  chart = <|
    "Status" -> "Candidate",
    "Name" -> name,
    "Kind" -> "TwoVariable",
    "Variables" -> newVariables,
    "SourceVariables" -> sourceVariables,
    "Subst" -> subst,
    "Root" -> extensionRoot,
    "RootSquare" -> rootSquare,
    "Roots" -> roots,
    "Parents" -> <|parentName -> variableRules|>,
    "ParentCharts" -> <|parentName -> baseChart|>,
    "Extension" -> <|
      "BaseChart" -> parentName,
      "PulledBackRootSquare" -> pullBack,
      "Rules" -> extensionRules|>
  |>;
  certificate = TransportChartVerify[chart];
  If[! TrueQ[certificate["OK"]],
    Return[<|"Status" -> "ExtensionIdentityFailed",
      "Chart" -> chart, "Certificate" -> certificate|>]
  ];
  Join[chart, <|"Status" -> "ExactChart",
    "ChartCertificate" -> certificate|>]
];

ComposeTransportChartExtension[___] :=
  <|"Status" -> "InvalidChartExtensionArguments"|>;

transportChartLoadRationalizeRoots[] := Module[{file, function},
  function = ToExpression["RationalizeRoots`RationalizeRoot"];
  If[DownValues[Evaluate[function]] =!= {}, Return[True]];
  file = FileNameJoin[{$feynFacetAddonRoot, "Addon", "Mathematica_Addon",
    "RationalizeRoots", "RationalizeRoots.m"}];
  If[! FileExistsQ[file], Return[False]];
  Quiet[Check[Get[file], Return[False]]];
  DownValues[Evaluate[function]] =!= {}
];

transportChartExtensionCandidates[raw_, baseVariables_List] :=
  DeleteDuplicates[Cases[raw,
    rules : {__Rule} /;
      ContainsAll[First /@ rules, baseVariables] :> rules,
    {0, Infinity}], SameTest -> SameQ];

Options[RationalizeTransportChartExtension] = {
  "Name" -> Automatic,
  "OutputVariables" -> Automatic,
  "AllCharts" -> True,
  "AllPoints" -> True,
  "TimeConstraint" -> 1800
};

RationalizeTransportChartExtension[baseChart_Association, rootSquare_,
    OptionsPattern[]] := Module[
  {baseVariables, baseSubst, pullBack, outputVariables, allCharts,
   allPoints, timeConstraint, raw, candidates, charts, exactCharts,
   selected, requestedName},

  If[! transportChartLoadRationalizeRoots[],
    Return[<|"Status" -> "RationalizeRootsUnavailable"|>]
  ];
  baseVariables = Lookup[baseChart, "Variables", Missing[]];
  baseSubst = Lookup[baseChart, "Subst", Missing[]];
  If[! MatchQ[baseVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[baseSubst, {_Rule, _Rule}],
    Return[<|"Status" -> "BaseChartNotWellFormed"|>]
  ];
  pullBack = Together[rootSquare /. baseSubst];
  (* C4 (generality pass 2026-08-23): the default output variables were
     Global`r and Global`t, which collide with any caller working in those
     symbols (and with packages that dump short names into Global`).  The
     default is now a fresh package-private pair, and an explicit choice
     that meets the base chart's own variables is refused rather than
     silently identified with them. *)
  outputVariables = Replace[OptionValue["OutputVariables"],
    Automatic :> {Unique["FeynFacet`Private`chartExtensionU"],
      Unique["FeynFacet`Private`chartExtensionV"]}];
  If[! MatchQ[outputVariables, {_Symbol, _Symbol}] ||
      ! DuplicateFreeQ[outputVariables],
    Return[<|"Status" -> "InvalidOutputVariables"|>]
  ];
  If[Intersection[outputVariables, baseVariables] =!= {},
    Return[<|"Status" -> "OutputVariablesCollideWithBaseChart",
      "OutputVariables" -> outputVariables,
      "BaseVariables" -> baseVariables|>]
  ];
  allCharts = TrueQ[OptionValue["AllCharts"]];
  allPoints = TrueQ[OptionValue["AllPoints"]];
  timeConstraint = OptionValue["TimeConstraint"];
  raw = TimeConstrained[
    RationalizeRoots`RationalizeRoot[
      Sqrt[pullBack],
      Variables -> baseVariables,
      RationalizeRoots`OutputVariables -> outputVariables,
      RationalizeRoots`RootOutput -> True,
      RationalizeRoots`MultipleSolutions -> True,
      RationalizeRoots`AllCharts -> allCharts,
      RationalizeRoots`AllPoints -> allPoints],
    timeConstraint, $TimedOut];
  If[raw === $TimedOut,
    Return[<|"Status" -> "RationalizationTimedOut",
      "Seconds" -> timeConstraint,
      "PulledBackRootSquare" -> pullBack|>]
  ];
  candidates = transportChartExtensionCandidates[raw, baseVariables];
  charts = ComposeTransportChartExtension[
      baseChart, rootSquare, #, outputVariables] & /@ candidates;
  exactCharts = Select[charts,
    Lookup[#, "Status", None] === "ExactChart" &];
  If[exactCharts === {},
    Return[<|"Status" -> "NoExactRationalExtension",
      "PulledBackRootSquare" -> pullBack,
      "CandidateCount" -> Length[candidates],
      "CandidateResults" -> charts|>]
  ];
  selected = First@MinimalBy[exactCharts,
    LeafCount[Lookup[#, "Subst", {}]] +
      LeafCount[Lookup[#, "Roots", {}]] &];
  requestedName = OptionValue["Name"];
  If[StringQ[requestedName], selected["Name"] = requestedName];
  Join[selected, <|
    "RationalizeRootsCandidateCount" -> Length[candidates],
    "ExactCandidateCount" -> Length[exactCharts]|>]
];

(* ------------------------------------------------------------------ *)
(*  The per-family chart REGISTRY                                       *)
(* ------------------------------------------------------------------ *)
(* Generality pass 2026-08-23 (user directive: the package is general,
   the inventory is project data).  The literal per-family table that
   lived here until then -- 47 entries of the ppHX NNLO double-real
   inventory, measured 2026-08-17 from the class assignment, the class
   forms and each family's raw alphabet -- was moved verbatim to
   ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/TransportFamilyCharts.wl
   after an entry-by-entry round trip (44 catalog-chart names identical
   and present in TransportChartCatalog[], 3 root-square lists
   Together-zero against the package table).  The package now ships an
   EMPTY registry; a campaign registers its own inventory.

   A registered value is one of
     "ChartName"    a key of TransportChartCatalog[];
     "RootSquares"  <|"RootSquares" -> {polynomials in the source
                    variables}|>, the exact multiquadratic identity frame
                    for a root set with no global rational chart;
     "ChartAlias"   <|"ChartAlias" -> catalog name|>, a legacy record
                    string (a descriptive substitution) that stands for a
                    catalog chart -- the table this replaces lived in
                    FamilyEpsForm.wl until 2026-08-23 (A3).
   An UNREGISTERED family is Missing["FamilyChartNotRegistered", family],
   never None: None means "root-free, transport in the source variables"
   and would silently mistransport a rooted family whose registration is
   merely absent. *)
$transportFamilyChartRegistry = <||>;

transportFamilyChartEntryKind[value_] := Module[{squares, alias},
  Which[
    StringQ[value],
      If[KeyExistsQ[TransportChartCatalog[], value], "ChartName",
        <|"Status" -> "ChartNameNotInCatalog", "Value" -> value|>],
    ! AssociationQ[value],
      <|"Status" -> "EntryNotStringOrAssociation",
        "Head" -> ToString[Head[value], InputForm]|>,
    KeyExistsQ[value, "RootSquares"],
      If[Keys[value] =!= {"RootSquares"},
        Return[<|"Status" -> "RootSquareEntryHasExtraKeys",
          "Keys" -> Keys[value]|>]];
      squares = value["RootSquares"];
      Which[
        ! ListQ[squares] || squares === {},
          <|"Status" -> "RootSquaresNotANonemptyList"|>,
        ! AllTrue[squares, FreeQ[#, _Root | Power[_, _Rational]] &],
          <|"Status" -> "RootSquareContainsRadicals"|>,
        ! AllTrue[squares, PolynomialQ[#, Variables[#]] &],
          <|"Status" -> "RootSquareNotPolynomial"|>,
        ! AllTrue[squares, Variables[#] =!= {} &],
          <|"Status" -> "RootSquareHasNoVariables"|>,
        True, "RootSquares"],
    KeyExistsQ[value, "ChartAlias"],
      alias = value["ChartAlias"];
      If[Keys[value] =!= {"ChartAlias"},
        Return[<|"Status" -> "ChartAliasEntryHasExtraKeys",
          "Keys" -> Keys[value]|>]];
      If[StringQ[alias] && KeyExistsQ[TransportChartCatalog[], alias],
        "ChartAlias",
        <|"Status" -> "ChartAliasNotInCatalog", "Value" -> alias|>],
    True,
      <|"Status" -> "EntryKeysNotRecognized", "Keys" -> Keys[value]|>]
];

(* All or nothing: a rejected entry registers nothing, so a partly
   mistyped project table cannot leave the session half configured. *)
TransportFamilyChartRegister[entries_Association] := Module[
  {kinds, invalid},
  If[! AllTrue[Keys[entries], StringQ],
    Return[<|"Status" -> "FamilyChartKeysNotStrings",
      "Keys" -> Select[Keys[entries], ! StringQ[#] &]|>]];
  kinds = Association @ KeyValueMap[
    #1 -> transportFamilyChartEntryKind[#2] &, entries];
  invalid = Select[kinds, ! StringQ[#] &];
  If[invalid =!= <||>,
    Return[<|"Status" -> "InvalidFamilyChartEntries",
      "Invalid" -> invalid|>]];
  $transportFamilyChartRegistry = Join[
    $transportFamilyChartRegistry, entries];
  <|"Status" -> "FamilyChartsRegistered",
    "Registered" -> Length[entries],
    "Families" -> Sort[Keys[entries]],
    "Kinds" -> Counts[Values[kinds]],
    "RegistrySize" -> Length[$transportFamilyChartRegistry]|>
];
TransportFamilyChartRegister[___] :=
  <|"Status" -> "InvalidFamilyChartRegistration"|>;

TransportFamilyChartLoad[file_String] := Module[{value},
  If[! FileExistsQ[file],
    Return[<|"Status" -> "FamilyChartFileMissing", "File" -> file|>]];
  value = FamilyArtifactRead[file];
  If[! AssociationQ[value],
    Return[<|"Status" -> "FamilyChartFileNotAnAssociation",
      "File" -> file|>]];
  Join[TransportFamilyChartRegister[value], <|"File" -> file|>]
];
TransportFamilyChartLoad[___] :=
  <|"Status" -> "InvalidFamilyChartRegistration"|>;

(* the catalog name a legacy record string stands for, or Missing *)
transportFamilyChartAlias[value_String] := Module[
  {entry = Lookup[$transportFamilyChartRegistry, value, Missing[]]},
  If[AssociationQ[entry] && StringQ[Lookup[entry, "ChartAlias", None]] &&
      KeyExistsQ[TransportChartCatalog[], entry["ChartAlias"]],
    entry["ChartAlias"], Missing["ChartAliasNotRegistered", value]]];
transportFamilyChartAlias[___] := Missing["ChartAliasNotRegistered"];

TransportFamilyChart[family_String] := TransportFamilyChart[family,
  {$transportChartV, $transportChartW}, Automatic];

TransportFamilyChart[family_String,
    sourceVariables : {_Symbol, _Symbol}] :=
  TransportFamilyChart[family, sourceVariables, Automatic];

TransportFamilyChart[family_String,
    sourceVariables : {_Symbol, _Symbol},
    chartVariables : ({_Symbol, _Symbol} | Automatic)] := Module[
  {entry, kind, record, targetVariables},
  entry = Lookup[$transportFamilyChartRegistry, family,
    Missing["FamilyChartNotRegistered", family]];
  If[MissingQ[entry], Return[Missing["FamilyChartNotRegistered", family]]];
  kind = transportFamilyChartEntryKind[entry];
  If[! StringQ[kind],
    Return[Join[<|"Status" -> "RegisteredFamilyChartInvalid",
      "Family" -> family|>, kind]]];
  Switch[kind,
    "RootSquares",
      targetVariables = Replace[chartVariables,
        Automatic -> {$transportChartX, $transportChartY}];
      BuildAlgebraicTransportFrame[
        entry["RootSquares"] /. Thread[
          {$transportChartV, $transportChartW} -> sourceVariables],
        sourceVariables, targetVariables],
    "ChartName" | "ChartAlias",
      record = masterTransportChartByName[
        If[kind === "ChartAlias", entry["ChartAlias"], entry]];
      (* the catalog record is written in the package's own source and
         chart variables; only a caller asking for other symbols pays the
         rekey (which drops "Parents"/"Notes" by construction) *)
      If[chartVariables === Automatic &&
          sourceVariables === {$transportChartV, $transportChartW},
        record,
        transportChartRekey[record, sourceVariables,
          Replace[chartVariables,
            Automatic -> Lookup[record, "Variables",
              {$transportChartX, $transportChartY}]]]],
    _, Missing["FamilyChartNotRegistered", family]]
];

(* Compose a class record written in ITS OWN two-variable chart with a
   TARGET two-variable chart that rationalizes the record's root:
   solve the record's substitution for the record's variables using the
   target chart's rational roots (all signs), and accept a candidate only
   if the record's Subst at that candidate reproduces the target Subst
   EXACTLY.  Charts may provide an analytic InverseByRoots; otherwise the
   kernel's Solve is the fallback.  The acceptance is always the forward
   identity, never the declared inverse or Solve's return shape.

   record chart:  <|"Variables" -> {x', y'}, "Subst" -> {v -> f(x',y'), w -> g(x',y')},
                    "Root" -> rho(x',y'), "RootSquare" -> Q(v,w)|>
   target data:   masterTransportChartData's record ("Subst", "Variables",
                  "Roots" or "Root"/"RootSquare")
   Returns <|"Status" -> "OK", "Map" -> {x' -> ..., y' -> ...}, "Images" -> {...},
             "Sign" -> +-1|> or a named refusal. *)
masterTransportComposeTwoVariableRecord[recordChart_Association,
    targetData_Association, sourceVariables_List] := Module[
  {recVars, recSubst, recRoot, recSquare, tgtVars, tf, tg, tgtRoots,
   matching, recRoots, inverseByRoots, rootMatches, declaredCandidates,
   candidates, verified, eqs, coefficientField, compositionZeroQ,
   route = "Solve"},
  recVars = Lookup[recordChart, "Variables", $Failed];
  recSubst = Lookup[recordChart, "Subst", $Failed];
  recRoot = Lookup[recordChart, "Root", None];
  recSquare = Lookup[recordChart, "RootSquare", None];
  If[! MatchQ[recVars, {_Symbol, _Symbol}] || ! MatchQ[recSubst, {_Rule, _Rule}],
    Return[<|"Status" -> "RecordChartNotWellFormed"|>]];
  tgtVars = targetData["Variables"];
  coefficientField = Lookup[targetData, "CoefficientField", "Rational"];
  {tf, tg} = Together /@ (Last /@ targetData["Subst"]);
  tgtRoots = Lookup[targetData, "Roots", None];
  If[! ListQ[tgtRoots],
    tgtRoots = If[Lookup[targetData, "Root", None] === None, {},
      {<|"Root" -> targetData["Root"], "RootSquare" -> targetData["RootSquare"]|>}]];
  recRoots = Lookup[recordChart, "Roots", {}];
  compositionZeroQ[expression_] := If[
    coefficientField === "Multiquadratic",
    TrueQ[transportChartAlgebraicZeroQ[expression, tgtRoots]],
    TrueQ[Together[expression] === 0]];
  inverseByRoots = Lookup[recordChart, "InverseByRoots", None];
  rootMatches = If[ListQ[recRoots], Table[
    SelectFirst[tgtRoots,
      TrueQ[Together[#1["RootSquare"] - recRoot["RootSquare"]] === 0] &,
      Missing["RootNotAvailable"]], {recRoot, recRoots}], {}];
  (* the target root that rationalizes the RECORD's quadratic *)
  matching = If[recSquare === None || recRoot === None, {},
    Select[tgtRoots, TrueQ[Together[#["RootSquare"] - recSquare] === 0] &]];
  (* the record's variables are renamed to FRESH symbols before solving:
     a joint chart keeps the parent's y as its own y, so the record's y
     and the target's y are the same symbol, and Solve would otherwise be
     asked to solve for a symbol that also appears on the right *)
  Module[{fresh, rename, back, fRec, gRec, rhoRec},
    fresh = Table[Unique["masterTransportChartVar"], {2}];
    rename = Thread[recVars -> fresh];
    back = Thread[fresh -> recVars];
    fRec = Last[recSubst[[1]]] /. rename;
    gRec = Last[recSubst[[2]]] /. rename;
    rhoRec = If[recRoot === None, None, recRoot /. rename];
    eqs = {fRec == tf, gRec == tg};
    declaredCandidates = If[MatchQ[inverseByRoots, _Function] &&
        recRoots =!= {} && AllTrue[rootMatches, AssociationQ],
      DeleteDuplicates[Function[signs, Module[{images},
        images = Quiet[Check[inverseByRoots[{tf, tg},
          MapThread[Times, {signs, Lookup[rootMatches, "Root"]}]], $Failed]];
        If[MatchQ[images, {_, _}], Thread[fresh -> images], Nothing]]]
        /@ Tuples[{1, -1}, Length[recRoots]]], {}];
    candidates = If[declaredCandidates =!= {},
      route = "DeclaredInverseByRoots"; declaredCandidates,
      If[matching === {},
        (* no root available: try the plain algebraic solve and keep only
           rational solutions *)
        Quiet[Solve[eqs, fresh]],
        (* Table over {root, sign} of Solve's solution LISTS: flatten two
           levels to a plain list of rule lists (one level left each
           candidate as {{rules}} and the identity check below then compared
           a LIST -- measured 2026-08-17 03:20 on class 79 in Kallen23) *)
        Flatten[Table[
          Quiet[Solve[Append[eqs, rhoRec == sign m["Root"]], fresh]],
          {m, matching}, {sign, {1, -1}}], 2]]];
    candidates = Select[candidates,
      Which[
        coefficientField === "Rational" || matching === {},
          FreeQ[#, Power[_, _Rational] | _Root],
        coefficientField === "Multiquadratic",
          FreeQ[#, _Root],
        True, False] &];
    verified = Select[candidates,
      compositionZeroQ[(fRec /. #) - tf] &&
      compositionZeroQ[(gRec /. #) - tg] &];
    If[verified === {},
      Return[<|"Status" -> "TwoVariableChartsNotComposable",
        "RecordVariables" -> recVars, "TargetVariables" -> tgtVars,
        "MatchingRoots" -> Length[matching], "Candidates" -> Length[candidates],
        "Route" -> route|>]];
    <|"Status" -> "OK",
      "Map" -> Map[Together, First[verified] /. back, {2}],
      "Images" -> Map[Together, fresh /. First[verified]],
      "Candidates" -> Length[candidates], "Verified" -> Length[verified],
      "Route" -> route|>]];

(* Moved here verbatim from Transport/MasterTransport.wl (layer pass,
   2026-09-02): the record-to-chart coordinate map composes a class
   record's own chart with the target chart, which needs
   masterTransportComposeTwoVariableRecord above.  Its callers are
   SolveEpsFormStripInFrame (this file) and the class-form pullback in
   MasterTransport.wl (Transport, loaded later). *)

(* The record's own coordinates as rational functions of the chart
   variables, plus the exact identity that licenses the composition.
   Three frames, one uniform answer {m1(x,y), m2(x,y)}:

     rational frame       {f, g}                       (identity check)
     target chart         {x, y}                       (Subst must match)
     single-conic chart   {f, tmap} or {tmap, f}       (linear root solve,
                                                        then the exact
                                                        chart identity) *)
masterTransportRecordCoordinateMap[record_Association, data_Association,
    conicRoute_] := Module[
  {sourceVariables, chartVariables, sourceNames, chartNames, recVariables,
   recNames, recChart, recSubst, f, g, fixed, parameter, fixedIndex,
   conicSubst, conicRoot, rootPulled, a, b, candidates, accepted, other,
   otherName, identity},
  sourceVariables = data["SourceVariables"];
  chartVariables = data["Variables"];
  sourceNames = SymbolName /@ sourceVariables;
  chartNames = SymbolName /@ chartVariables;
  {f, g} = Last /@ data["Subst"];
  recVariables = Lookup[record, "Variables", sourceVariables];
  (* --- frame 4: a ONE-VARIABLE root record (class 115: Variables {u},
         Chart <|"Definition" -> u^2 == 1 - 4 v w, ...|>).  Its T depends
         on u alone; in a target chart that rationalizes the same
         quadratic, u is the chart's rational root (either sign) and the
         identity root^2 == RootSquare o Subst licenses the map. ---------- *)
  If[MatchQ[recVariables, {_Symbol}] && AssociationQ[Lookup[record, "Chart", None]] &&
     MatchQ[Lookup[record["Chart"], "Definition", None], _Equal],
    Module[{u, definition, square, roots, tf, tg, matching},
      u = recVariables[[1]];
      definition = record["Chart"]["Definition"];
      (* Definition is u^2 == Q(v,w) or Q(v,w) == u^2 *)
      square = Which[
        TrueQ[Together[First[definition] - u^2] === 0], Last[definition],
        TrueQ[Together[Last[definition] - u^2] === 0], First[definition],
        True, $Failed];
      If[square === $Failed,
        Return[<|"Status" -> "ClassFormOneVariableDefinitionNotSquare"|>]];
      {tf, tg} = Last /@ data["Subst"];
      roots = Lookup[data, "Roots", {}];
      matching = Select[roots, TrueQ[Together[#["RootSquare"] - square] === 0] &&
        TrueQ[Together[#["Root"]^2 - (square /. {sourceVariables[[1]] -> tf,
          sourceVariables[[2]] -> tg})] === 0] &];
      If[matching === {},
        Return[<|"Status" -> "ClassFormOneVariableRootNotRationalized",
          "Definition" -> definition|>]];
      Return[<|"Status" -> "OK", "Frame" -> "OneVariableRoot",
        "Map" -> {u -> First[matching]["Root"]},
        "Images" -> {First[matching]["Root"]},
        "CompositionIdentity" ->
          "target root^2 equals the record's Definition square pulled back \
through the target Subst (exact); the record's single variable is that root",
        "CompositionExact" -> True|>]]];
  If[! MatchQ[recVariables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "ClassFormVariablesInvalid"|>]];
  recNames = SymbolName /@ recVariables;
  recChart = Lookup[record, "Chart", None];
  If[MissingQ[recChart], recChart = None];
  (* a bare rule list is accepted as a chart substitution, which is how
     the hard-class artifacts store it *)
  recSubst = Which[
    AssociationQ[recChart], Lookup[recChart, "Subst", None],
    MatchQ[recChart, {_Rule, _Rule}], recChart,
    True, None];

  (* --- frame 1: rational, Variables {v,w} and no chart -------------- *)
  If[recNames === sourceNames && (recChart === None || recChart === Null),
    Return[<|"Status" -> "OK", "Frame" -> "Rational",
      "Map" -> {recVariables[[1]] -> f, recVariables[[2]] -> g},
      "Images" -> {f, g},
      "CompositionIdentity" -> "by construction (record frame = source frame)",
      "CompositionExact" -> True|>]];

  (* --- frame 2: already the target chart ---------------------------- *)
  If[recNames === chartNames,
    If[! MatchQ[recSubst, {_Rule, _Rule}],
      Return[<|"Status" -> "ClassFormChartMissingSubstitution"|>]];
    (* the stored chart must be THE target chart, entry by entry and
       exactly; a record in a different two-variable chart is a different
       frame and is refused rather than used *)
    identity = And @@ Table[
      Module[{nm = SymbolName[First[recSubst[[i]]]], target},
        target = Which[
          nm === sourceNames[[1]], f,
          nm === sourceNames[[2]], g,
          True, $Failed];
        target =!= $Failed &&
          TrueQ[Together[Last[recSubst[[i]]] - target] === 0]],
      {i, Length[recSubst]}];
    If[TrueQ[identity],
      Return[<|"Status" -> "OK", "Frame" -> "TargetChart",
        "Map" -> {recVariables[[1]] -> chartVariables[[1]],
                  recVariables[[2]] -> chartVariables[[2]]},
        "Images" -> chartVariables,
        "CompositionIdentity" ->
          "stored Subst equals the target chart Subst (exact)",
        "CompositionExact" -> True|>]]];

  (* --- frame 2b: a DIFFERENT two-variable chart that the target chart
         composes with rationally (a joint chart of TransportCharts.wl
         rationalizes the record's root, or the record's chart is the
         target's parent).  The record's variables are solved for with
         the target's rational root and the result is accepted only if
         the record's Subst reproduces the target Subst EXACTLY. ------ *)
  If[MatchQ[recSubst, {_Rule, _Rule}] && AssociationQ[recChart] &&
     Lookup[recChart, "Kind", "TwoVariable"] === "TwoVariable" &&
     ! KeyExistsQ[recChart, "Fixed"],
    Module[{composed},
      composed = masterTransportComposeTwoVariableRecord[
        Join[recChart, <|"Variables" -> recVariables, "Subst" -> recSubst|>],
        data, sourceVariables];
      If[AssociationQ[composed] && composed["Status"] === "OK",
        Return[<|"Status" -> "OK", "Frame" -> "TwoVariableComposition",
          "Map" -> composed["Map"], "Images" -> composed["Images"],
          "CompositionRoute" -> Lookup[composed, "Route", "Solve"],
          "CompositionIdentity" ->
            "record Subst at the solved record variables equals the target \
chart Subst (exact); record variables obtained from the target's rational \
root of the record's RootSquare",
          "CompositionExact" -> True|>],
        Return[<|"Status" -> "ClassFormChartIsADifferentChart",
          "Composition" -> composed|>]]]];

  (* --- frame 3: single-conic chart ---------------------------------- *)
  If[AssociationQ[recChart] && ! MissingQ[Lookup[recChart, "Fixed", Missing[]]] &&
      ! MissingQ[Lookup[recChart, "Root", Missing[]]],
    If[conicRoute === False,
      Return[<|"Status" -> "ClassFormConicChartRefused"|>]];
    fixed = recChart["Fixed"];
    fixedIndex = Position[recNames, SymbolName[fixed]];
    If[Length[fixedIndex] =!= 1,
      Return[<|"Status" -> "ClassFormConicFixedVariableNotFound"|>]];
    fixedIndex = fixedIndex[[1, 1]];
    parameter = recVariables[[3 - fixedIndex]];
    other = If[SymbolName[fixed] === sourceNames[[1]], sourceVariables[[2]],
      sourceVariables[[1]]];
    otherName = SymbolName[other];
    conicSubst = Lookup[recChart, "Subst", None];
    If[! MatchQ[conicSubst, _Rule],
      Return[<|"Status" -> "ClassFormConicSubstitutionInvalid"|>]];
    If[SymbolName[First[conicSubst]] =!= otherName,
      Return[<|"Status" -> "ClassFormConicSubstitutionInvalid"|>]];
    If[data["Root"] === None && Lookup[data, "Roots", {}] === {},
      Return[<|"Status" -> "ClassFormConicChartNotPullable",
        "Reason" -> "the target chart declares no rational Root"|>]];
    (* the conic Root is the algebraic function the target chart
       rationalizes; equate and solve LINEARLY for the conic parameter *)
    conicRoot = Together[recChart["Root"] /.
      {sourceVariables[[1]] -> f, sourceVariables[[2]] -> g}];
    conicRoot = Together[conicRoot /. If[SymbolName[fixed] === sourceNames[[1]],
      fixed -> f, fixed -> g]];
    If[! PolynomialQ[conicRoot, parameter] ||
       Exponent[conicRoot, parameter] =!= 1,
      Return[<|"Status" -> "ClassFormConicChartNotPullable",
        "Reason" -> "the conic Root is not linear in the chart parameter"|>]];
    a = Together[Coefficient[conicRoot, parameter, 1]];
    b = Together[conicRoot - a parameter];
    If[TrueQ[a === 0],
      Return[<|"Status" -> "ClassFormConicChartNotPullable",
        "Reason" -> "the conic Root does not involve the chart parameter"|>]];
    (* every root the target chart declares is tried, both signs: a joint
       chart rationalizes several quadratics and the record does not say
       which one it needs -- the exact identity below decides *)
    candidates = DeleteDuplicates[Flatten[Table[
      Together[(sign r - b)/a],
      {r, DeleteDuplicates[Join[
        If[data["Root"] === None, {}, {data["Root"]}],
        (#["Root"] & /@ Lookup[data, "Roots", {}])]]},
      {sign, {1, -1}}]]];
    accepted = Select[candidates,
      TrueQ[Together[(Last[conicSubst] /.
        {parameter -> #, fixed -> If[SymbolName[fixed] === sourceNames[[1]], f, g]}) -
        If[otherName === sourceNames[[2]], g, f]] === 0] &];
    If[accepted === {},
      Return[<|"Status" -> "ClassFormConicChartNotPullable",
        "Reason" -> "neither root branch reproduces the target chart substitution",
        "Candidates" -> candidates|>]];
    Return[<|"Status" -> "OK", "Frame" -> "SingleConicChart",
      "Map" -> {fixed -> If[SymbolName[fixed] === sourceNames[[1]], f, g],
                parameter -> First[accepted]},
      "Images" -> If[fixedIndex === 1,
        {If[SymbolName[fixed] === sourceNames[[1]], f, g], First[accepted]},
        {First[accepted], If[SymbolName[fixed] === sourceNames[[1]], f, g]}],
      "Parameter" -> parameter,
      "ParameterMap" -> First[accepted],
      "Branch" -> If[First[accepted] === First[candidates], "+", "-"],
      "CompositionIdentity" ->
        "conic Subst at the solved parameter equals the target chart Subst (exact)",
      "CompositionExact" -> True|>]];

  <|"Status" -> "ClassFormFrameUnknown", "RecordVariables" -> recNames|>
];
