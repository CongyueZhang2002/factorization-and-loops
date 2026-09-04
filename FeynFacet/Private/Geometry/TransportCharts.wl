(* Geometry data for the catalogued rationalizing parametrizations,
   per-family root data, and composition of forward parametrizations.

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
     * A family may use one parametrization in which every class form it
       hosts is rational.  Single-root families use the parametrization of
       their root; two-root families use a joint parametrization built on
       the Kallen parametrization by
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

   Every catalog entry carries forward square-root identities and a
   nondegenerate Jacobian.  VerifyRationalizingParametrization re-derives
   those claims and checks rationality.  It does not certify an inverse.

   Physics bookkeeping (chamber, branch, sign of the root) is NOT done
   here -- same discipline as AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks: the chart and its
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
Clear[
  FeynFacet`RationalizingParametrizationCatalog,
  FeynFacet`VerifyRationalizingParametrization,
  FeynFacet`LookupCataloguedRationalizingParametrizationForRoots,
  FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations,
  FeynFacet`ComposeRationalizingParametrizations,
  FeynFacet`ExtendRationalizingParametrization,
  FeynFacet`RegisterFamilyRootData,
  FeynFacet`LoadFamilyRootData,
  FeynFacet`FamilyRootData,
  FeynFacet`FamilySquareRootGeneratorCensus
];
ClearAll[
  rationalizingParametrizationCatalogDefinitions,
  rationalizingParametrizationCatalogRecord,
  rationalizingParametrizationNormalize,
  rationalizingParametrizationRekey,
  squareRootGeneratorDataNormalize,
  masterTransportRationalizingParametrizationByName,
  masterTransportComposeTwoVariableRecord,
  masterTransportRecordCoordinateMap,
  familyCoefficientPresentationFromRecord,
  transportChartRationalExpressionQ,
  transportChartLoadRationalizeRoots,
  transportChartExtensionCandidates,
  familyRootDataEntryNormalize,
  familyRootDataEntryKind
];

FeynFacet`RationalizingParametrizationCatalog::usage =
  "RationalizingParametrizationCatalog[] returns the catalogued forward rational parametrizations together with their displayed rationalized square roots. VerifyRationalizingParametrization re-derives the stated identities; catalog membership alone is not a birationality or nonexistence claim.";

FeynFacet`VerifyRationalizingParametrization::usage =
  "VerifyRationalizingParametrization[parametrization] verifies rationality of the forward substitution and rationalized roots, the square-root identities, a nonzero Jacobian, and declared parent compositions. It does not certify a rational inverse or birationality.";

FeynFacet`LookupCataloguedRationalizingParametrizationForRoots::usage =
  "LookupCataloguedRationalizingParametrizationForRoots[rootSquares] returns the least complicated catalogued rationalizing parametrization containing the requested radicands, or Missing[\"NoCataloguedRationalizingParametrization\",...] when the catalog has no such entry. A miss is not a nonexistence result.";

FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations::usage =
  "BuildSquareRootGeneratorsAndQuadraticRelations[rootSquares,{v,w},{x,y}] records explicit square-root generators after the identity variable substitution and verifies only their quadratic relations. It does not assert square-class independence, a function field, or Galois conjugacy.";

FeynFacet`ComposeRationalizingParametrizations::usage =
  "ComposeRationalizingParametrizations[base,rootSquare,rules,newVariables] composes a verified forward rationalizing parametrization with a rational parametrization of one additional square root and re-verifies the resulting forward map.";

FeynFacet`ExtendRationalizingParametrization::usage =
  "ExtendRationalizingParametrization[base,rootSquare] asks RationalizeRoots for forward rational parametrizations of the pulled-back root and returns the least complicated verified result. Failure to find one is not a nonexistence theorem.";



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
     4v + w^2 = ((p + s^2)/s)^2.  MEASURED 2026-08-17 (chart probes on
     CF48/CF232): the naive parametrization v = (s^2 - u^2)/4, w = u
     turns the letter v + w - w^2 of CF48/CF52 into a QUARTIC in the
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

(* Catalog definitions already use the V2 mathematical field names.  This
   constructor adds the common discriminator and source-variable data once;
   it is not a reader for historical artifacts. *)
rationalizingParametrizationCatalogRecord[definition_Association] := Join[
  <|
    "DataType" -> "RationalizingParametrization",
    "SchemaVersion" -> 2,
    "Status" -> "RationalizingParametrizationDeclared",
    "SourceVariables" ->
      First /@ definition["SourceVariableSubstitution"],
    "ParentParametrizations" -> <||>|>,
  definition];

rationalizingParametrizationNormalize[record_Association] := Module[
  {normalized = algebraCoefficientPresentationNormalize[record]},
  If[Lookup[normalized, "DataType", None] =!=
      "RationalizingParametrization",
    Return[normalized]];
  Join[normalized, KeyTake[record,
    {"ParametrizationExtensionData",
     "RationalizingParametrizationVerification"}]]
];

FeynFacet`RationalizingParametrizationCatalog[] :=
  Map[rationalizingParametrizationCatalogRecord,
    rationalizingParametrizationCatalogDefinitions[]];

masterTransportRationalizingParametrizationByName[name_String] :=
  Lookup[FeynFacet`RationalizingParametrizationCatalog[], name, None];

(* Moved verbatim from Transport/Observable/ObservableTransport.wl (round 7,
   2026-09-02): a record's chart resolved against the catalog; the source
   frame is named, never a chart.  FamilyEpsForm.wl (EpsForm) and the
   observable transport both use it. *)
familyCoefficientPresentationFromRecord[record_Association,
    Automatic] := Lookup[record, "CoefficientPresentation", None];

familyCoefficientPresentationFromRecord[record_Association,
    presentation_] := presentation;

(* Re-derive exactly what a forward rationalizing parametrization proves.
   Rationality of both the source-coordinate images and the displayed root
   images is part of the gate.  No inverse is checked here, so neither the
   result nor its status uses "change of variables", "birational", or
   "chart". *)
FeynFacet`VerifyRationalizingParametrization[input_Association] := Module[
  {parametrization, vars, subst, sourceVariables, f, g, jac, det, roots,
   substitutionRationalChecks, rootRationalChecks, rootChecks, parentMaps,
  parentParametrizations, parentChecks, verified},
  parametrization = rationalizingParametrizationNormalize[input];
  If[Lookup[parametrization, "DataType", None] =!=
      "RationalizingParametrization",
    Return[Join[parametrization, <|"Verified" -> False|>]]];
  vars = parametrization["ParametrizingVariables"];
  subst = parametrization["SourceVariableSubstitution"];
  roots = parametrization["RationalizedSquareRoots"];
  If[! MatchQ[vars, {_Symbol, _Symbol}] ||
      ! MatchQ[subst, {_Rule, _Rule}] || ! ListQ[roots],
    Return[<|"Status" -> "RationalizingParametrizationNotWellFormed",
      "Verified" -> False|>]];
  sourceVariables = First /@ subst;
  {f, g} = Together /@ (Last /@ subst);
  substitutionRationalChecks =
    transportChartRationalExpressionQ[#, vars] & /@ {f, g};
  rootRationalChecks =
    transportChartRationalExpressionQ[#1["RationalRoot"], vars] & /@ roots;
  jac = {{D[f, vars[[1]]], D[f, vars[[2]]]},
    {D[g, vars[[1]]], D[g, vars[[2]]]}};
  det = Together[Det[jac]];
  rootChecks = Table[
    TrueQ[Together[root["RationalRoot"]^2 -
      (root["SourceRadicand"] /.
        Thread[sourceVariables -> {f, g}])] === 0],
    {root, roots}];
  parentMaps = parametrization["ParentParametrizationMaps"];
  parentParametrizations = parametrization["ParentParametrizations"];
  parentChecks = Association @ KeyValueMap[
    Function[{parentName, map},
      Module[{parent = Lookup[parentParametrizations, parentName,
          masterTransportRationalizingParametrizationByName[parentName]],
        parentSubstitution, pf, pg},
        If[parent === None || ! AssociationQ[parent], parentName -> False,
          parent = rationalizingParametrizationNormalize[parent];
          parentSubstitution = parent["SourceVariableSubstitution"];
          If[! MatchQ[parentSubstitution, {_Rule, _Rule}],
            parentName -> False,
            {pf, pg} = Last /@ parentSubstitution;
            parentName ->
              (TrueQ[Together[(pf /. map) - f] === 0] &&
               TrueQ[Together[(pg /. map) - g] === 0])]]]],
    parentMaps];
  verified = AllTrue[substitutionRationalChecks, TrueQ] &&
    AllTrue[rootRationalChecks, TrueQ] &&
    AllTrue[rootChecks, TrueQ] && ! TrueQ[det === 0] &&
    AllTrue[Values[parentChecks], TrueQ];
  <|
    "DataType" -> "RationalizingParametrizationValidation",
    "SchemaVersion" -> 2,
    "Status" -> If[verified, "RationalizingParametrizationVerified",
      "RationalizingParametrizationVerificationFailed"],
    "Verified" -> verified,
    "Name" -> Lookup[parametrization, "Name", "?"],
    "SourceCoordinateImagesRational" -> substitutionRationalChecks,
    "RationalizedRootImagesRational" -> rootRationalChecks,
    "RationalizedSquareRootIdentities" -> rootChecks,
    "JacobianDeterminant" -> Factor[det],
    "ParentParametrizationIdentities" -> parentChecks,
    "RationalInverseVerified" -> False,
    "BirationalityVerified" -> False
  |>
];
FeynFacet`VerifyRationalizingParametrization[___] :=
  <|"Status" -> "InvalidRationalizingParametrizationArguments",
    "Verified" -> False|>;

FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
    rootSquares_List, sourceVariables : {_Symbol, _Symbol},
    coefficientVariables : {_Symbol, _Symbol}] := Module[
  {substitution, pulledSquares, generators, relationChecks,
   jacobianDeterminant, verified},
  If[Length[DeleteDuplicates[SymbolName /@
        Join[sourceVariables, coefficientVariables]]] =!= 4,
    Return[<|"Status" -> "SquareRootGeneratorVariablesCollide"|>]];
  substitution = Thread[sourceVariables -> coefficientVariables];
  pulledSquares = Together /@ (rootSquares /. substitution);
  generators = MapThread[
    <|
      "Generator" -> Sqrt[#1],
      "QuadraticRadicand" -> #1,
      "SourceRadicand" -> #2
    |> &,
    {pulledSquares, rootSquares}];
  relationChecks = TrueQ[Together[
      #1["Generator"]^2 - #1["QuadraticRadicand"]] === 0] & /@
    generators;
  jacobianDeterminant = Together@Det@Table[
    D[Last[substitution[[i]]], coefficientVariables[[j]]],
    {i, 2}, {j, 2}];
  verified = AllTrue[relationChecks, TrueQ] &&
    ! TrueQ[jacobianDeterminant === 0];
  <|
    "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
    "SchemaVersion" -> 2,
    "Status" -> If[verified, "SquareRootGeneratorRelationsVerified",
      "SquareRootGeneratorRelationVerificationFailed"],
    "SourceVariables" -> sourceVariables,
    "CoefficientVariables" -> coefficientVariables,
    "SourceToCoefficientVariableRules" -> substitution,
    "SquareRootGenerators" -> generators,
    "QuadraticRelationVerification" -> <|
      "Verified" -> verified,
      "PerGenerator" -> relationChecks,
      "CoordinateJacobianDeterminant" -> Factor[jacobianDeterminant]|>,
    "SquareClassIndependenceStatus" -> "NotChecked",
    "SquareClassIndependenceVerified" -> False,
    "SignChangeImageInterpretation" -> "FormalGeneratorSignChangesOnly",
    "GaloisConjugatesCertified" -> False
  |>
];
FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[___] :=
  <|"Status" -> "InvalidSquareRootGeneratorArguments"|>;

(* The family census accepts only the canonical V2 generator presentation.
   V1 records are refused typed rather than normalized into a guessed
   mathematical object. *)
squareRootGeneratorDataNormalize[data_Association] := If[
  Lookup[data, "DataType", None] ===
      "SquareRootGeneratorsAndQuadraticRelations" &&
    Lookup[data, "SchemaVersion", None] === 2 &&
    ListQ[Lookup[data, "SquareRootGenerators", $Failed]] &&
    KeyExistsQ[data, "SourceToCoefficientVariableRules"],
  algebraCoefficientPresentationNormalize[data],
  <|"Status" -> "LegacyCoefficientPresentationSchemaUnsupported"|>];

FeynFacet`FamilySquareRootGeneratorCensus[assembly_Association,
    generatorData_Association] := Module[
  {normalizedData, generatorRecords, zeroBlockQ, blocks, ranges,
   connection, records, unmatched},
  If[Lookup[assembly, "Status", None] =!= "OK" ||
      ! ListQ[Lookup[assembly, "Blocks", None]] ||
      ! ListQ[Lookup[assembly, "Ranges", None]],
    Return[<|"Status" -> "FamilyAssemblyInvalid"|>]];
  normalizedData = squareRootGeneratorDataNormalize[generatorData];
  If[Lookup[normalizedData, "Status", None] ===
      "LegacyCoefficientPresentationSchemaUnsupported",
    Return[normalizedData]];
  generatorRecords = Lookup[normalizedData, "SquareRootGenerators", $Failed];
  If[! ListQ[generatorRecords],
    Return[<|"Status" -> "SquareRootGeneratorDataInvalid"|>]];
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
          classification = transportChartRootIndices[
            block, generatorRecords];
          <|"BlockPair" -> {i, j},
            "FamilyRows" -> {blocks[[i]], blocks[[j]]},
            "SquareRootGeneratorIndices" -> classification["RootIndices"],
            "SquareRootGeneratorCount" ->
              Length[classification["RootIndices"]],
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
  <|"Status" -> If[unmatched === {},
      "ExactSquareRootGeneratorCensus",
      "UnclassifiedRadicals"],
    "Family" -> Lookup[assembly, "Family", None],
    "SourceRadicands" -> Lookup[generatorRecords, "SourceRadicand", {}],
    "NonzeroOffDiagonalBlocks" -> Length[records],
    "SquareRootGeneratorCountHistogram" ->
      Counts[Lookup[records, "SquareRootGeneratorCount", {}]],
    "MaximumSquareRootGeneratorCount" ->
      Max[Append[Lookup[records, "SquareRootGeneratorCount", {}], 0]],
    "BlocksWithAtLeastThreeSquareRootGenerators" ->
      Select[records, #["SquareRootGeneratorCount"] >= 3 &],
    "UnclassifiedRadicalBases" -> unmatched,
    (* radicands accepted by exact denesting rather than by a direct
       match (2026-08-24): classified, but not literally declared *)
    "DenestedRadicalBases" -> DeleteDuplicates[Flatten[
      Lookup[records, "DenestedRadicalBases", {}]]],
    "NumericRadicalClasses" -> DeleteDuplicates[Flatten[
      Lookup[records, "NumericRadicalClasses", {}]]],
    "Blocks" -> records|>
];

FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
    rootSquares_List,
    sourceVariables : {_Symbol, _Symbol}] := Module[
  {wanted, candidates},
  wanted = DeleteDuplicates[Together /@
    (rootSquares /. Thread[sourceVariables ->
      {$transportChartV, $transportChartW}])];
  If[wanted === {}, Return[None]];
  candidates = Select[
    Values[FeynFacet`RationalizingParametrizationCatalog[]],
    Function[parametrization,
    Module[{rationalizedRoots = Lookup[parametrization,
        "RationalizedSquareRoots", {}], cataloguedRadicands},
      If[Length[rationalizedRoots] < Length[wanted], False,
        cataloguedRadicands = Together /@
          Lookup[rationalizedRoots, "SourceRadicand", {}];
        AllTrue[wanted, Function[q, AnyTrue[cataloguedRadicands,
          Function[candidate,
            TrueQ[Together[q - candidate] === 0]]]]]]]]];
  If[candidates === {},
    Missing["NoCataloguedRationalizingParametrization", wanted],
    First[SortBy[candidates,
      {Function[parametrization,
         Length[Lookup[parametrization,
           "RationalizedSquareRoots", {}]]],
       Function[parametrization,
         LeafCount[Lookup[parametrization,
           "SourceVariableSubstitution", {}]]]}]]]
];

FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
    rootSquares_List] :=
  FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
    rootSquares, {$transportChartV, $transportChartW}];
FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[___] :=
  <|"Status" -> "InvalidRationalizingParametrizationLookupArguments"|>;

(* Input-only V1 wrapper.  A catalog miss deliberately uses the new Missing
   tag, which states absence from this finite catalog and nothing stronger. *)
transportChartRationalExpressionQ[expr_, variables_List] :=
  FreeQ[Unevaluated[expr], _Root |
    Power[_, exponent_Rational /; Denominator[exponent] > 1]] &&
  PolynomialQ[Numerator[Together[expr]], variables] &&
  PolynomialQ[Denominator[Together[expr]], variables];

FeynFacet`ComposeRationalizingParametrizations[
    baseInput_Association, rootSquare_, extensionRules_List,
    newVariables : {_Symbol, _Symbol}] := Module[
  {baseParametrization, baseVariables, sourceVariables, baseSubstitution,
   pullBack, variableRules, rootRules, extensionRootRule, extensionRoot,
   substitution, inheritedRoots, roots, parentName, name,
   parametrization, verification},

  baseParametrization = rationalizingParametrizationNormalize[baseInput];
  If[Lookup[baseParametrization, "DataType", None] =!=
      "RationalizingParametrization",
    Return[baseParametrization]];
  baseVariables = Lookup[baseParametrization,
    "ParametrizingVariables", Missing[]];
  baseSubstitution = Lookup[baseParametrization,
    "SourceVariableSubstitution", Missing[]];
  If[! MatchQ[baseVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[baseSubstitution, {_Rule, _Rule}],
    Return[<|"Status" -> "BaseRationalizingParametrizationNotWellFormed"|>]
  ];
  sourceVariables = First /@ baseSubstitution;
  pullBack = Together[rootSquare /. baseSubstitution];
  variableRules = Select[extensionRules,
    MemberQ[baseVariables, First[#]] &];
  If[Sort[First /@ variableRules] =!= Sort[baseVariables],
    Return[<|"Status" -> "BaseParametrizingVariablesNotMapped",
      "Expected" -> baseVariables|>]
  ];
  variableRules = Table[
    variable -> (variable /. variableRules), {variable, baseVariables}];
  If[! AllTrue[Last /@ variableRules,
      transportChartRationalExpressionQ[#, newVariables] &],
    Return[<|"Status" -> "ExtensionParametrizationNotRational"|>]
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
    Return[<|"Status" -> "AdditionalSquareRootNotRationalized",
      "PulledBackRadicand" -> pullBack|>]
  ];
  extensionRoot = Together[Last[extensionRootRule] /. variableRules];

  substitution = Map[
    Function[rule, First[rule] -> Together[Last[rule] /. variableRules]],
    baseSubstitution];
  If[! AllTrue[Last /@ substitution,
      transportChartRationalExpressionQ[#, newVariables] &],
    Return[<|"Status" -> "ComposedParametrizationNotRational"|>]
  ];
  inheritedRoots = Lookup[baseParametrization,
    "RationalizedSquareRoots", {}];
  inheritedRoots = Map[
    <|"RationalRoot" ->
        Together[#["RationalRoot"] /. variableRules],
      "SourceRadicand" -> #["SourceRadicand"]|> &,
    inheritedRoots];
  roots = Append[inheritedRoots,
    <|"RationalRoot" -> extensionRoot,
      "SourceRadicand" -> rootSquare|>];
  parentName = Lookup[baseParametrization, "Name",
    "BaseRationalizingParametrization"];
  name = parentName <> "+AdditionalRoot" <> ToString[Length[roots]];
  parametrization = <|
    "DataType" -> "RationalizingParametrization",
    "SchemaVersion" -> 2,
    "Status" -> "RationalizingParametrizationCandidate",
    "Name" -> name,
    "Kind" -> "TwoVariable",
    "ParametrizingVariables" -> newVariables,
    "SourceVariables" -> sourceVariables,
    "SourceVariableSubstitution" -> substitution,
    "RationalizedSquareRoots" -> roots,
    "ParentParametrizationMaps" -> <|parentName -> variableRules|>,
    "ParentParametrizations" ->
      <|parentName -> baseParametrization|>,
    "ParametrizationExtensionData" -> <|
      "BaseParametrization" -> parentName,
      "PulledBackRadicand" -> pullBack,
      "Rules" -> extensionRules|>
  |>;
  verification = FeynFacet`VerifyRationalizingParametrization[
    parametrization];
  If[! TrueQ[verification["Verified"]],
    Return[<|"Status" -> "RationalizingParametrizationExtensionFailed",
      "RationalizingParametrization" -> parametrization,
      "RationalizingParametrizationVerification" -> verification|>]
  ];
  Join[parametrization,
    <|"Status" -> "RationalizingParametrizationVerified",
      "RationalizingParametrizationVerification" -> verification|>]
];

FeynFacet`ComposeRationalizingParametrizations[___] :=
  <|"Status" -> "InvalidRationalizingParametrizationCompositionArguments"|>;

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

Options[FeynFacet`ExtendRationalizingParametrization] = {
  "Name" -> Automatic,
  "OutputVariables" -> Automatic,
  "AllCharts" -> True,
  "AllPoints" -> True,
  "TimeConstraint" -> 1800
};
FeynFacet`ExtendRationalizingParametrization[
    baseInput_Association, rootSquare_,
    OptionsPattern[]] := Module[
  {baseParametrization, baseVariables, baseSubstitution, pullBack,
   outputVariables, allCharts, allPoints, timeConstraint, raw, candidates,
   parametrizations, verifiedParametrizations,
   selected, requestedName},

  If[! transportChartLoadRationalizeRoots[],
    Return[<|"Status" -> "RationalizeRootsUnavailable"|>]
  ];
  baseParametrization = rationalizingParametrizationNormalize[baseInput];
  If[Lookup[baseParametrization, "DataType", None] =!=
      "RationalizingParametrization",
    Return[baseParametrization]];
  baseVariables = Lookup[baseParametrization,
    "ParametrizingVariables", Missing[]];
  baseSubstitution = Lookup[baseParametrization,
    "SourceVariableSubstitution", Missing[]];
  If[! MatchQ[baseVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[baseSubstitution, {_Rule, _Rule}],
    Return[<|"Status" -> "BaseRationalizingParametrizationNotWellFormed"|>]
  ];
  pullBack = Together[rootSquare /. baseSubstitution];
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
    Return[<|"Status" -> "OutputVariablesCollideWithBaseParametrization",
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
      "PulledBackRadicand" -> pullBack|>]
  ];
  candidates = transportChartExtensionCandidates[raw, baseVariables];
  parametrizations = FeynFacet`ComposeRationalizingParametrizations[
      baseParametrization, rootSquare, #, outputVariables] & /@ candidates;
  verifiedParametrizations = Select[parametrizations,
    Lookup[#, "Status", None] ===
      "RationalizingParametrizationVerified" &];
  If[verifiedParametrizations === {},
    Return[<|"Status" -> "NoVerifiedRationalizingParametrizationFound",
      "PulledBackRadicand" -> pullBack,
      "CandidateCount" -> Length[candidates],
      "CandidateResults" -> parametrizations,
      "NonexistenceProved" -> False|>]
  ];
  selected = First@MinimalBy[verifiedParametrizations,
    LeafCount[Lookup[#, "SourceVariableSubstitution", {}]] +
      LeafCount[Lookup[#, "RationalizedSquareRoots", {}]] &];
  requestedName = OptionValue["Name"];
  If[StringQ[requestedName], selected["Name"] = requestedName];
  Join[selected, <|
    "RationalizeRootsCandidateCount" -> Length[candidates],
    "VerifiedCandidateCount" -> Length[verifiedParametrizations]|>]
];

FeynFacet`ExtendRationalizingParametrization[___] :=
  <|"Status" -> "InvalidRationalizingParametrizationExtensionArguments"|>;

(* ------------------------------------------------------------------ *)
(*  Per-family root data registry                                      *)
(* ------------------------------------------------------------------ *)
(* The live registry stores either a catalogued rationalizing-parametrization
   name or source radicands for explicit square-root generators and quadratic
   relations.  Generated V1 registries are regenerated, not normalized here. *)
$familyRootDataRegistry = <||>;

familyRootDataEntryNormalize[value_] := Which[
  ! AssociationQ[value],
    <|"Status" -> "FamilyRootDataEntryNotAssociation",
      "Head" -> ToString[Head[value], InputForm]|>,
  KeyExistsQ[value, "SourceRadicands"], value,
  KeyExistsQ[value, "RationalizingParametrizationName"], value,
  AnyTrue[{"RootSquares", "ChartAlias",
      "RationalizingParametrizationAlias"}, KeyExistsQ[value, #] &],
    <|"Status" -> "LegacyFamilyRootDataSchemaUnsupported"|>,
  True,
    <|"Status" -> "FamilyRootDataEntryKeysNotRecognized",
      "Keys" -> Keys[value]|>
];

familyRootDataEntryKind[value_Association] := Module[
  {radicands, name},
  Which[
    KeyExistsQ[value, "Status"], value,
    KeyExistsQ[value, "SourceRadicands"],
      If[Keys[value] =!= {"SourceRadicands"},
        Return[<|"Status" -> "SourceRadicandEntryHasExtraKeys",
          "Keys" -> Keys[value]|>]];
      radicands = value["SourceRadicands"];
      Which[
        ! ListQ[radicands] || radicands === {},
          <|"Status" -> "SourceRadicandsNotANonemptyList"|>,
        ! AllTrue[radicands,
            FreeQ[#, _Root | Power[_, _Rational]] &],
          <|"Status" -> "SourceRadicandContainsRadicals"|>,
        ! AllTrue[radicands, PolynomialQ[#, Variables[#]] &],
          <|"Status" -> "SourceRadicandNotPolynomial"|>,
        ! AllTrue[radicands, Variables[#] =!= {} &],
          <|"Status" -> "SourceRadicandHasNoVariables"|>,
        True, "SquareRootGeneratorsAndQuadraticRelations"],
    KeyExistsQ[value, "RationalizingParametrizationName"],
      name = value["RationalizingParametrizationName"];
      If[Keys[value] =!= {"RationalizingParametrizationName"},
        Return[<|"Status" ->
          "RationalizingParametrizationNameEntryHasExtraKeys",
          "Keys" -> Keys[value]|>]];
      If[StringQ[name] &&
          KeyExistsQ[FeynFacet`RationalizingParametrizationCatalog[], name],
        "RationalizingParametrization",
        <|"Status" -> "RationalizingParametrizationNameNotInCatalog",
          "Value" -> name|>],
    True,
      <|"Status" -> "FamilyRootDataEntryKeysNotRecognized",
        "Keys" -> Keys[value]|>]
];

FeynFacet`RegisterFamilyRootData[entries_Association] := Module[
  {normalizedEntries, kinds, invalid},
  If[! AllTrue[Keys[entries], StringQ],
    Return[<|"Status" -> "FamilyRootDataKeysNotStrings",
      "Keys" -> Select[Keys[entries], ! StringQ[#] &]|>]];
  normalizedEntries = Association @ KeyValueMap[
    #1 -> familyRootDataEntryNormalize[#2] &, entries];
  kinds = Association @ KeyValueMap[
    #1 -> familyRootDataEntryKind[#2] &, normalizedEntries];
  invalid = Select[kinds, ! StringQ[#] &];
  If[invalid =!= <||>,
    Return[<|"Status" -> "InvalidFamilyRootDataEntries",
      "Invalid" -> invalid|>]];
  $familyRootDataRegistry = Join[$familyRootDataRegistry, normalizedEntries];
  <|"Status" -> "FamilyRootDataRegistered",
    "Registered" -> Length[normalizedEntries],
    "Families" -> Sort[Keys[normalizedEntries]],
    "Kinds" -> Counts[Values[kinds]],
    "RegistrySize" -> Length[$familyRootDataRegistry]|>
];
FeynFacet`RegisterFamilyRootData[___] :=
  <|"Status" -> "InvalidFamilyRootDataRegistration"|>;

FeynFacet`LoadFamilyRootData[file_String] := Module[{value},
  If[! FileExistsQ[file],
    Return[<|"Status" -> "FamilyRootDataFileMissing", "File" -> file|>]];
  value = FamilyArtifactRead[file];
  If[! AssociationQ[value],
    Return[<|"Status" -> "FamilyRootDataFileNotAnAssociation",
      "File" -> file|>]];
  Join[FeynFacet`RegisterFamilyRootData[value], <|"File" -> file|>]
];
FeynFacet`LoadFamilyRootData[___] :=
  <|"Status" -> "InvalidFamilyRootDataRegistration"|>;

rationalizingParametrizationRekey[input_Association,
    sourceVariables : {_Symbol, _Symbol},
    parametrizingVariables : {_Symbol, _Symbol}] := Module[
  {parametrization, oldSubstitution, oldSourceVariables,
   oldParametrizingVariables, sourceRules, variableRules, substitution,
   roots, result},
  parametrization = rationalizingParametrizationNormalize[input];
  If[Lookup[parametrization, "DataType", None] =!=
      "RationalizingParametrization",
    Return[parametrization]];
  oldSubstitution = parametrization["SourceVariableSubstitution"];
  oldParametrizingVariables = parametrization["ParametrizingVariables"];
  If[! MatchQ[oldSubstitution, {_Rule, _Rule}] ||
      ! MatchQ[oldParametrizingVariables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "RationalizingParametrizationNotWellFormed"|>]];
  oldSourceVariables = First /@ oldSubstitution;
  sourceRules = Thread[oldSourceVariables -> sourceVariables];
  variableRules = Thread[oldParametrizingVariables -> parametrizingVariables];
  substitution = Map[
    Function[rule, (First[rule] /. sourceRules) ->
      Together[Last[rule] /. variableRules]], oldSubstitution];
  roots = Map[
    <|"RationalRoot" -> Together[#["RationalRoot"] /. variableRules],
      "SourceRadicand" ->
        Together[#["SourceRadicand"] /. sourceRules]|> &,
    parametrization["RationalizedSquareRoots"]];
  result = <|
    "DataType" -> "RationalizingParametrization",
    "SchemaVersion" -> 2,
    "Status" -> "RationalizingParametrizationDeclared",
    "Name" -> Lookup[parametrization, "Name",
        "RationalizingParametrization"] <> "Rekeyed",
    "Kind" -> "TwoVariable",
    "SourceVariables" -> sourceVariables,
    "ParametrizingVariables" -> parametrizingVariables,
    "SourceVariableSubstitution" -> substitution,
    "RationalizedSquareRoots" -> roots,
    "ParentParametrizationMaps" -> <||>,
    "ParentParametrizations" -> <||>
  |>;
  If[KeyExistsQ[parametrization, "InverseParametrizationByRootValues"],
    result = Append[result, "InverseParametrizationByRootValues" ->
      parametrization["InverseParametrizationByRootValues"]]];
  result
];

FeynFacet`FamilyRootData[family_String] := FeynFacet`FamilyRootData[family,
  {$transportChartV, $transportChartW}, Automatic];
FeynFacet`FamilyRootData[family_String,
    sourceVariables : {_Symbol, _Symbol}] :=
  FeynFacet`FamilyRootData[family, sourceVariables, Automatic];
FeynFacet`FamilyRootData[family_String,
    sourceVariables : {_Symbol, _Symbol},
    parametrizingVariables : ({_Symbol, _Symbol} | Automatic)] := Module[
  {entry, kind, record, targetVariables, name},
  entry = Lookup[$familyRootDataRegistry, family,
    Missing["FamilyRootDataNotRegistered", family]];
  If[MissingQ[entry], Return[Missing["FamilyRootDataNotRegistered", family]]];
  kind = familyRootDataEntryKind[entry];
  If[! StringQ[kind],
    Return[Join[<|"Status" -> "RegisteredFamilyRootDataInvalid",
      "Family" -> family|>, kind]]];
  Switch[kind,
    "SquareRootGeneratorsAndQuadraticRelations",
      targetVariables = Replace[parametrizingVariables,
        Automatic -> {$transportChartX, $transportChartY}];
      FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
        entry["SourceRadicands"] /. Thread[
          {$transportChartV, $transportChartW} -> sourceVariables],
        sourceVariables, targetVariables],
    "RationalizingParametrization",
      name = entry["RationalizingParametrizationName"];
      record = masterTransportRationalizingParametrizationByName[name];
      If[parametrizingVariables === Automatic &&
          sourceVariables === {$transportChartV, $transportChartW},
        record,
        rationalizingParametrizationRekey[record, sourceVariables,
          Replace[parametrizingVariables,
            Automatic -> Lookup[record, "ParametrizingVariables",
              {$transportChartX, $transportChartY}]]]],
    _, Missing["FamilyRootDataNotRegistered", family]]
];

(* Express the parameters of one rationalizing parametrization through a
   second coefficient presentation.  Candidate inverse images are accepted
   only when forward substitution reproduces both source-coordinate images
   exactly.  A declared inverse is a candidate generator, never trusted as
   the proof. *)
masterTransportComposeTwoVariableRecord[recordParametrization_Association,
    targetData_Association, sourceVariables_List] := Module[
  {recVars, recSubst, recRoot, recSquare, tgtVars, tf, tg, tgtRoots,
   matching, recRoots, inverseByRoots, rootMatches, declaredCandidates,
   candidates, verified, eqs, presentationKind, compositionZeroQ,
   route = "Solve"},
  recVars = Lookup[recordParametrization, "ParametrizingVariables", $Failed];
  recSubst = Lookup[recordParametrization,
    "SourceVariableSubstitution", $Failed];
  recRoots = Lookup[recordParametrization, "RationalizedSquareRoots", {}];
  recRoot = If[recRoots === {}, None,
    recRoots[[1, "RationalRoot"]]];
  recSquare = If[recRoots === {}, None,
    recRoots[[1, "SourceRadicand"]]];
  If[! MatchQ[recVars, {_Symbol, _Symbol}] || ! MatchQ[recSubst, {_Rule, _Rule}],
    Return[<|"Status" -> "RecordRationalizingParametrizationNotWellFormed"|>]];
  presentationKind = Lookup[targetData, "PresentationKind", None];
  tgtVars = masterTransportPresentationVariables[targetData];
  {tf, tg} = Together /@
    (Last /@ masterTransportPresentationSubstitution[targetData]);
  tgtRoots = Switch[presentationKind,
    "RationalizingParametrization",
      <|"Expression" -> #1["RationalRoot"],
        "SourceRadicand" -> #1["SourceRadicand"]|> & /@
        Lookup[targetData, "RationalizedSquareRoots", {}],
    "SquareRootGeneratorsAndQuadraticRelations",
      <|"Expression" -> #1["Generator"],
        "SourceRadicand" -> #1["SourceRadicand"]|> & /@
        Lookup[targetData, "SquareRootGenerators", {}],
    _, {}];
  compositionZeroQ[expression_] := If[
    presentationKind === "SquareRootGeneratorsAndQuadraticRelations",
    TrueQ[transportChartAlgebraicZeroQ[expression,
      Switch[presentationKind,
        "SquareRootGeneratorsAndQuadraticRelations",
          targetData["SquareRootGenerators"],
        _, {}]]],
    TrueQ[Together[expression] === 0]];
  inverseByRoots = Lookup[recordParametrization,
    "InverseParametrizationByRootValues", None];
  rootMatches = If[ListQ[recRoots], Table[
    SelectFirst[tgtRoots,
      TrueQ[Together[#1["SourceRadicand"] -
        recRoot["SourceRadicand"]] === 0] &,
      Missing["RootNotAvailable"]], {recRoot, recRoots}], {}];
  (* the target root that rationalizes the RECORD's quadratic *)
  matching = If[recSquare === None || recRoot === None, {},
    Select[tgtRoots,
      TrueQ[Together[#["SourceRadicand"] - recSquare] === 0] &]];
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
          MapThread[Times, {signs,
            Lookup[rootMatches, "Expression"]}]], $Failed]];
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
          Quiet[Solve[Append[eqs, rhoRec == sign m["Expression"]], fresh]],
          {m, matching}, {sign, {1, -1}}], 2]]];
    candidates = Select[candidates,
      Which[
        presentationKind === "RationalizingParametrization" ||
            matching === {},
          FreeQ[#, Power[_, _Rational] | _Root],
        presentationKind ===
            "SquareRootGeneratorsAndQuadraticRelations",
          FreeQ[#, _Root],
        True, False] &];
    verified = Select[candidates,
      compositionZeroQ[(fRec /. #) - tf] &&
      compositionZeroQ[(gRec /. #) - tg] &];
    If[verified === {},
      Return[<|"Status" -> "TwoVariableParametrizationsNotComposable",
        "RecordVariables" -> recVars, "TargetVariables" -> tgtVars,
        "MatchingRoots" -> Length[matching], "Candidates" -> Length[candidates],
        "Route" -> route|>]];
    <|"Status" -> "OK",
      "CoefficientVariableRules" ->
        Map[Together, First[verified] /. back, {2}],
      "CoefficientVariableImages" ->
        Map[Together, fresh /. First[verified]],
      "CandidateCount" -> Length[candidates],
      "VerifiedCandidateCount" -> Length[verified],
      "Route" -> route|>]];

(* A diagonal-block record is either written in
   the source variables or carries one complete two-variable rationalizing
   parametrization.  Former one-variable conic records are regenerated using
   the corresponding two-variable catalog entry. *)
masterTransportRecordCoordinateMap[record_Association,
    data_Association] := Module[
  {sourceVariables, targetVariables, sourceNames, targetNames,
   targetSubstitution, targetImages, recordVariables, recordNames,
   recordParametrization, recordSubstitution, recordSourceNames,
   recordParametrizingNames, identity, composed},
  sourceVariables = data["SourceVariables"];
  targetVariables = masterTransportPresentationVariables[data];
  targetSubstitution = masterTransportPresentationSubstitution[data];
  targetImages = Together /@ (Last /@ targetSubstitution);
  sourceNames = SymbolName /@ sourceVariables;
  targetNames = SymbolName /@ targetVariables;
  recordVariables = Lookup[record, "CoefficientVariables", $Failed];
  If[! MatchQ[recordVariables, {_Symbol, _Symbol}],
    Return[<|"Status" ->
      "LegacyDiagonalBlockCoefficientVariableSchemaUnsupported"|>]];
  recordNames = SymbolName /@ recordVariables;
  recordParametrization = Lookup[record,
    "RationalizingParametrization", None];
  If[recordParametrization === None || recordParametrization === Null,
    If[recordNames =!= sourceNames,
      Return[<|"Status" ->
        "DiagonalBlockSourceVariableRepresentationMismatch",
        "Expected" -> sourceNames, "Found" -> recordNames|>]];
    Return[<|
      "Status" -> "OK",
      "CoordinateRepresentation" -> "SourceVariables",
      "CoefficientVariableRules" -> Thread[recordVariables -> targetImages],
      "CoefficientVariableImages" -> targetImages,
      "CompositionStatement" ->
        "the diagonal-block coefficients are written in the source variables",
      "CompositionVerified" -> True|>]
  ];
  If[! masterTransportRationalizingParametrizationRecordQ[
      recordParametrization],
    Return[<|"Status" ->
      "DiagonalBlockRationalizingParametrizationNotWellFormed"|>]];
  recordSubstitution =
    recordParametrization["SourceVariableSubstitution"];
  recordSourceNames = SymbolName /@ (First /@ recordSubstitution);
  recordParametrizingNames = SymbolName /@
    recordParametrization["ParametrizingVariables"];
  If[recordSourceNames =!= sourceNames ||
      recordParametrizingNames =!= recordNames,
    Return[<|"Status" ->
      "DiagonalBlockRationalizingParametrizationVariablesMismatch"|>]];
  identity = recordNames === targetNames && And @@ MapThread[
    TrueQ[Together[#1 - #2] === 0] &,
    {Last /@ recordSubstitution, targetImages}];
  If[identity,
    Return[<|
      "Status" -> "OK",
      "CoordinateRepresentation" ->
        "SelectedRationalizingParametrization",
      "CoefficientVariableRules" ->
        Thread[recordVariables -> targetVariables],
      "CoefficientVariableImages" -> targetVariables,
      "CompositionStatement" ->
        "the diagonal block and family use the same rationalizing parametrization",
      "CompositionVerified" -> True|>]
  ];
  composed = masterTransportComposeTwoVariableRecord[
    recordParametrization, data, sourceVariables];
  If[! AssociationQ[composed] || composed["Status"] =!= "OK",
    Return[<|"Status" ->
      "DiagonalBlockRationalizingParametrizationNotComposable",
      "Composition" -> composed|>]];
  <|
    "Status" -> "OK",
    "CoordinateRepresentation" ->
      "ComposedRationalizingParametrizations",
    "CoefficientVariableRules" -> composed["CoefficientVariableRules"],
    "CoefficientVariableImages" ->
      composed["CoefficientVariableImages"],
    "CompositionRoute" -> Lookup[composed, "Route", "Solve"],
    "CompositionStatement" ->
      "substitution of the solved coefficient variables reproduces the selected family parametrization",
    "CompositionVerified" -> True|>
];
