(* FeynFacet/Private/Core/Charts/ChartData.wl -- split out of Core/Base/Core.wl in round 5
   (2026-09-02, substructure ruling): the chart-record data (masterTransportChartData)
   and the chain-rule pullbacks of one-forms and systems into a two-variable
   chart (from Transport in round 4).
   Verbatim moves of whole top-level statements; loads after Base/Core.wl
   (Private/LoadOrder.wl), inside the FeynFacet`Private` context. *)

Begin["FeynFacet`Private`"];

ClearAll[
  masterTransportFreeSymbols,
  masterTransportRationalQ,
  masterTransportChartRecordQ,
  masterTransportChartData,
  masterTransportPullBackOneForm,
  masterTransportMapTogetherSubstitute,
  masterTransportPullBackSystem
];

(* ------------------------------------------------------------------ *)
(*  Two-variable chart pullback                                         *)
(* ------------------------------------------------------------------ *)

(* Frames, continued.  Stage 1 certifies three kinds of class form:

     rational frame       Variables {v,w}, no chart;
     single-conic chart   Variables {v,t}, Chart <|Fixed, Subst, Root|>,
                          which rationalizes ONE quadratic locus;
     two-variable chart   Variables {x,y}, Chart <|"Kind" ->
                          "TwoVariable", "Subst" -> {v -> f(x,y),
                          w -> g(x,y)}, "Root" -> ...|>, which
                          rationalizes the Kallen root globally
                          (classes 97 and 77: v = x y, w = (1-x)(1-y),
                          sqrt(lambda) = x - y).

   A family whose hard block only has a form of the third kind cannot be
   transported in (v,w) at all -- no rational T exists there.  The WHOLE
   family is therefore moved into the chart (the system by the chain
   rule, every block's transformation by composition with the chart's
   coordinate map) and the EXISTING TransportFamily runs in (x,y).

   This layer does that and nothing else.  It makes no chamber, no
   branch and no sign choice; it records the chart, including the
   Jacobian determinant d(v,w)/d(x,y) -- x - y for the class-97 chart --
   under "ChartNotes", so that a later stage can.

   Everything is re-derived.  A stored "EpsForm" is read as provenance
   and COMPARED, never used: the chart epsilon-form is computed from the
   pulled-back BLOCK SYSTEM as T^-1 A T - T^-1 dT, exactly as the
   assembly does it, and a record whose frame cannot be composed with
   the target chart is refused by name rather than used in the wrong
   frame.

   Class equivalence is a basis permutation optionally composed with
   v <-> w, so the composition also TRIES that swap -- in this chart the
   involution (x,y) -> (1-x,1-y) -- and lets the exact re-derivation
   decide.  See masterTransportChartSwapData for the measured members.

   Composing a single-conic chart with the target chart needs no square
   root and is therefore done rather than refused: the conic record's
   "Root" is the same algebraic function that the target chart
   rationalizes, so setting it equal to the target chart's rational
   "Root" and solving for the conic parameter is ONE LINEAR SOLVE.  The
   solve is a candidate only; what licenses it is the exact identity
   that the conic chart's own substitution, evaluated at that parameter,
   reproduces the target chart's substitution.  Both signs of the root
   are tried and the one that satisfies the identity is recorded.  When
   neither does, the record is refused with a named status and no square
   root is ever introduced.  (Measured for the conic chart of classes
   49/95, w = (-t + t^2 + t v)/(t - 1) with Root = 2t + v - 1 - w:
   t = 1 - y in the class-97 chart, exactly.)

   Path note -- measured, and not incidental.  The pulled-back alphabet
   contains letters that are BILINEAR in (x,y): x + y - x y for class
   97, x + y - 2 x y for the pullback of 1 - v - w.  On a generic
   straight segment in (x,y) such a letter is QUADRATIC in the path
   parameter, and masterTransportMonicCheck refuses the connection
   (status PathDenominatorsNotLinear) -- correctly, because the word
   backends admit linear denominators only.  On an AXIS-ALIGNED segment,
   one chart variable held at its symbolic target value, every letter of
   the pulled-back alphabet is linear in tau again.
   TransportFamilyInChart therefore defaults to an axis-aligned path and
   says so in "ChartNotes".  The per-order check against the original
   family differential equation is then a statement about the path
   direction; the two-directional statements -- flatness of the chart
   system, and each diagonal block equalling its declared form in BOTH
   chart variables -- come from the assembly certificate as usual, and
   the pullback certificate carries the exact flatness of the chart
   system in its own right. *)

masterTransportFreeSymbols[expr_] := DeleteDuplicates @ Cases[expr,
  s_Symbol /; Context[s] =!= "System`", {0, Infinity}, Heads -> True];

masterTransportRationalQ[e_, vars_List] := Module[{x},
  x = Together[e];
  If[! FreeQ[x, Power[_, _Rational] | _Root | Log | Hypergeometric2F1],
    Return[False]];
  PolynomialQ[Numerator[x], vars] && PolynomialQ[Denominator[x], vars]
];

masterTransportChartRecordQ[chart_] :=
  AssociationQ[chart] &&
  MatchQ[Lookup[chart, "Variables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[chart, "Subst", $Failed], {_Rule, _Rule}] &&
  Lookup[chart, "Kind", "TwoVariable"] === "TwoVariable";

(* Resolve a chart record against the caller's source symbols.  The
   chart's own Subst is re-keyed onto the CALLER's symbols by
   SymbolName, so that a chart read from a file and a system read from
   another file cannot end up in different contexts and silently
   substitute nothing (trap P2, in its chart form). *)
masterTransportChartData[chart_, sourceVariables_List] := Module[
  {chartVariables, subst, substNames, sourceNames, f, g, jacobian, det,
   root, rootSquare, rootOK},
  If[! masterTransportChartRecordQ[chart],
    Return[<|"Status" -> "ChartNotWellFormed"|>]];
  chartVariables = chart["Variables"];
  sourceNames = SymbolName /@ sourceVariables[[{1, 2}]];
  subst = chart["Subst"];
  substNames = SymbolName /@ (First /@ subst);
  If[substNames =!= sourceNames,
    Return[<|"Status" -> "ChartVariablesMismatch", "Expected" -> sourceNames,
      "Found" -> substNames|>]];
  If[Length[DeleteDuplicates[Join[sourceNames, SymbolName /@ chartVariables]]] =!= 4,
    Return[<|"Status" -> "ChartVariablesCollide"|>]];
  {f, g} = Together /@ (Last /@ subst);
  If[! AllTrue[{f, g}, masterTransportRationalQ[#, chartVariables] &],
    Return[<|"Status" -> "ChartNotRational"|>]];
  If[Complement[masterTransportFreeSymbols[{f, g}], chartVariables] =!= {},
    Return[<|"Status" -> "ChartCarriesForeignSymbols",
      "Symbols" -> Complement[masterTransportFreeSymbols[{f, g}], chartVariables]|>]];
  jacobian = Map[Together, {
    {D[f, chartVariables[[1]]], D[f, chartVariables[[2]]]},
    {D[g, chartVariables[[1]]], D[g, chartVariables[[2]]]}}, {2}];
  det = Together[Det[jacobian]];
  If[TrueQ[det === 0], Return[<|"Status" -> "ChartJacobianDegenerate"|>]];
  root = Lookup[chart, "Root", None];
  rootSquare = Lookup[chart, "RootSquare", None];
  (* If the chart declares both, the rationalization statement itself is
     an exact identity and is checked here rather than believed. *)
  rootOK = If[root === None || rootSquare === None || MissingQ[root] ||
      MissingQ[rootSquare], None,
    TrueQ[Together[root^2 - (rootSquare /. {sourceVariables[[1]] -> f,
      sourceVariables[[2]] -> g})] === 0]];
  If[rootOK === False, Return[<|"Status" -> "ChartRootSquareInconsistent"|>]];
  (* A chart may rationalize SEVERAL quadratics (the joint charts of
     TransportCharts.wl): every declared root is checked against its own
     RootSquare, exactly, and carried through under "Roots" so that a
     conic record can be composed with whichever root it needs. *)
  Module[{roots, rootsOK},
    roots = Lookup[chart, "Roots", None];
    If[! ListQ[roots],
      roots = If[root === None || rootSquare === None || MissingQ[root] || MissingQ[rootSquare],
        {}, {<|"Root" -> root, "RootSquare" -> rootSquare|>}]];
    rootsOK = AllTrue[roots, TrueQ[Together[#["Root"]^2 - (#["RootSquare"] /.
      {sourceVariables[[1]] -> f, sourceVariables[[2]] -> g})] === 0] &];
    If[! rootsOK, Return[<|"Status" -> "ChartRootSquareInconsistent", "Roots" -> roots|>]];
    <|"Status" -> "OK", "Kind" -> Lookup[chart, "Kind", "TwoVariable"],
      "Name" -> Lookup[chart, "Name", None],
      "CoefficientField" -> Lookup[chart, "CoefficientField", "Rational"],
      "Variables" -> chartVariables, "SourceVariables" -> sourceVariables[[{1, 2}]],
      "Subst" -> {sourceVariables[[1]] -> f, sourceVariables[[2]] -> g},
      "Jacobian" -> jacobian, "JacobianDet" -> det,
      "Root" -> If[MissingQ[root], None, root],
      "RootSquare" -> If[MissingQ[rootSquare], None, rootSquare],
      "RootSquareConsistent" -> rootOK,
      "Roots" -> roots,
      "Parents" -> Lookup[chart, "Parents", <||>]|>]
];

(* Chain rule for a matrix-valued 1-form.  av, aw are already expressed
   in the chart variables; the tangent factors come from the chart
   Jacobian and are NOT substituted into anything (same discipline as
   masterTransportPathMatrix). *)
masterTransportPullBackOneForm[av_, aw_, jacobian_] := {
  Map[Together, av jacobian[[1, 1]] + aw jacobian[[2, 1]], {2}],
  Map[Together, av jacobian[[1, 2]] + aw jacobian[[2, 2]], {2}]};

(* Substitute and normalize only nonzero connection entries.  When the
   caller owns subkernels, largest entries enter the shared queue first;
   otherwise the identical worker runs serially.  The helper never
   launches kernels, so KernelPool remains the resource authority. *)
masterTransportMapTogetherSubstitute[tensor_List, rules_List] := Module[
  {dimensions, level, positions, entries, uniqueEntries, uniqueIndex,
   entryIndices, order, sorted, transformed, uniqueValues, values, out},
  dimensions = Dimensions[tensor];
  level = Length[dimensions];
  positions = Position[tensor, entry_ /; ! TrueQ[entry === 0], {level},
    Heads -> False];
  If[positions === {}, Return[ConstantArray[0, dimensions]]];
  entries = Extract[tensor, positions];
  (* Exact common-subexpression elimination.  Repeated connection entries
     occur throughout sector assemblies; substituting and Together-ing the
     same expression once per matrix position wastes the dominant stage. *)
  uniqueEntries = DeleteDuplicates[entries];
  uniqueIndex = AssociationThread[uniqueEntries,
    Range[Length[uniqueEntries]]];
  entryIndices = Lookup[uniqueIndex, Key[#]] & /@ entries;
  order = Ordering[ByteCount /@ uniqueEntries, All, Greater];
  sorted = uniqueEntries[[order]];
  transformed = If[$KernelCount > 1 && Length[sorted] > 1,
    ParallelMap[Together[# /. rules] &, sorted,
      Method -> "FinestGrained", DistributedContexts -> None],
    Together[# /. rules] & /@ sorted];
  uniqueValues = transformed[[Ordering[order]]];
  values = uniqueValues[[entryIndices]];
  out = ConstantArray[0, dimensions];
  MapThread[(out[[Sequence @@ #1]] = #2) &, {positions, values}];
  out];

Options[masterTransportPullBackSystem] = {
  "SourceVariables" -> Automatic,
  "FlatnessCheck" -> True
};

masterTransportPullBackSystem[system_Association, chart_,
    opts : OptionsPattern[]] := Module[
  {sourceVariables, data, av, aw, avc, awc, ax, ay, x, y, flatSource,
   flatChart, surviving},
  sourceVariables = OptionValue["SourceVariables"];
  If[sourceVariables === Automatic,
    sourceVariables = masterTransportDefaultVariables[]];
  If[! MatchQ[sourceVariables, {_Symbol, __Symbol}],
    Return[<|"Status" -> "SourceVariablesInvalid"|>]];
  data = If[AssociationQ[chart] && Lookup[chart, "Status", None] === "OK" &&
      KeyExistsQ[chart, "Jacobian"], chart,
    masterTransportChartData[chart, sourceVariables]];
  If[data["Status"] =!= "OK", Return[data]];
  {x, y} = data["Variables"];
  av = Lookup[system, "Av", $Failed];
  aw = Lookup[system, "Aw", $Failed];
  If[! (MatrixQ[av] && MatrixQ[aw] && Dimensions[av] === Dimensions[aw] &&
        Length[av] === Length[First[av]]),
    Return[<|"Status" -> "SystemNotASquareMatrixPair"|>]];
  (* Refuse a non-flat source outright: the chain rule would produce a
     chart system whose own flatness check then fails for a reason that
     has nothing to do with the chart. *)
  (* Production checks flatness once, after pullback, in the assembly
     certificate.  Building the same 41x41 curvature before substitution
     was a second full matrix-product pass and dominated CF303. *)
  flatSource = If[masterTransportCheckLevel[] === "Production",
    Missing["DeferredToAssembly"],
    masterTransportZeroMatQ[
      D[av, sourceVariables[[2]]] - D[aw, sourceVariables[[1]]] +
        av . aw - aw . av]];
  If[flatSource === False,
    Return[<|"Status" -> "SourceSystemNotFlat"|>]];
  {avc, awc} = masterTransportMapTogetherSubstitute[{av, aw}, data["Subst"]];
  surviving = Cases[{avc, awc},
    s_Symbol /; MemberQ[SymbolName /@ sourceVariables[[{1, 2}]], SymbolName[s]],
    {0, Infinity}, Heads -> True];
  If[surviving =!= {},
    Return[<|"Status" -> "SourceVariablesSurviveSubstitution",
      "Symbols" -> DeleteDuplicates[surviving]|>]];
  {ax, ay} = masterTransportPullBackOneForm[avc, awc, data["Jacobian"]];
  flatChart = If[TrueQ[OptionValue["FlatnessCheck"]],
    masterTransportZeroMatQ[D[ax, y] - D[ay, x] + ax . ay - ay . ax],
    "NotPerformed"];
  If[flatChart =!= "NotPerformed" && ! TrueQ[flatChart],
    Return[<|"Status" -> "ChartSystemNotFlat"|>]];
  <|"Status" -> "OK",
    "System" -> Join[KeyDrop[system, {"Av", "Aw"}], <|"Av" -> ax, "Aw" -> ay|>],
    "Ax" -> ax, "Ay" -> ay, "Variables" -> {x, y}, "Chart" -> data,
    "Certificate" -> <|
      "SourceFlat" -> flatSource,
      "SourceFlatRoute" -> If[MissingQ[flatSource],
        "DeferredToAssemblyCertificate", "ExactRationalFunction"],
      "ChartFlat" -> flatChart,
      "ChartRational" -> True,
      "RootSquareConsistent" -> data["RootSquareConsistent"],
      "ChainRule" ->
        "Ax = Av d_x v + Aw d_x w, Ay = Av d_y v + Aw d_y w (Together'd)",
      "JacobianDet" -> data["JacobianDet"],
      "Exact" -> True|>|>
];

End[];
