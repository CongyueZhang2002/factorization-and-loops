(* Order-by-order rational construction diagnostics for one fixed
   off-diagonal equation. The expansion starts at epsilon order zero and
   chooses one primitive at each step. This does not exhaust Laurent
   transformations, integration constants, alphabets, or diagonal bases.

   Residues measured on different roots of a polynomial can belong to
   different geometric components. Unequal constant values on those
   components do not imply a varying residue along one component.
   Failure of symbolic integration is a construction failure, not a
   nonexistence theorem. A finite successful expansion is not a proof of a
   complete rational epsilon-form transformation. *)

Clear[AnalyzeOffDiagonalBlockEpsilonFormObstructions];
ClearAll[
  epsFormObstructionResidues, epsFormObstructionPrimitive,
  epsFormObstructionPolarCurves, epsFormObstructionTotalDegree
];

AnalyzeOffDiagonalBlockEpsilonFormObstructions::record =
  "The record must contain OffDiagonalBlock -> {e, c, inhomogeneity}, two Variables and a Regulator symbol.";

Options[AnalyzeOffDiagonalBlockEpsilonFormObstructions] = {
  "Alphabet" -> Automatic,   (* Automatic: the off-diagonal block's own alphabet *)
  "MaximumOrder" -> 4,
  "ExtraLetters" -> {},
  "TransverseLines" -> 3,
  "Verbose" -> False
};

epsFormObstructionTotalDegree[p_, variables_List] :=
  If[PossibleZeroQ[p], -Infinity,
    Max[Total /@ CoefficientRules[Expand[p], variables][[All, 1]]]];

epsFormObstructionPolarCurves[forms_List, variables_List] := Module[{factors},
  factors = DeleteDuplicates[Flatten[
    Rest[FactorList[Denominator[Together[#]]]][[All, 1]] & /@ Flatten[forms]]];
  Select[factors, ! FreeQ[#, Alternatives @@ variables] &]];

(* residues of the closed form w = {w_x, w_y} along the curve L: exact
   one-variable residues on several transverse rational lines, at every
   root of L on the line; returns the list of distinct values (algebraic
   numbers reduced with RootReduce) *)
epsFormObstructionResidues[w_List, curve_, others_List, {x_, y_}, lines_Integer] := Module[
  {values = {}, samples, roots, restricted, v, tries = 0, clean},
  (* a point of the curve where another polar curve also vanishes is not
     a generic point: the one-variable residue there is not the residue
     along the curve (a measured example has x = 1 on y = 1). *)
  clean[pt_] := AllTrue[others, ! PossibleZeroQ[RootReduce[# /. pt]] &];
  samples = {};
  While[Length[samples] < lines && tries < 60,
    tries++;
    v = RandomInteger[{-97, 97}]/RandomInteger[{11, 31}];
    If[! FreeQ[curve, x],
      (* transverse variable x on the line y = v *)
      If[PossibleZeroQ[curve /. y -> v] || Exponent[curve /. y -> v, x] < 1 ||
          Exponent[curve /. y -> v, x] < Exponent[curve, x], Continue[]];
      roots = x /. Solve[(curve /. y -> v) == 0, x];
      roots = Select[roots, clean[{x -> #, y -> v}] &];
      If[roots === {}, Continue[]];
      restricted = Together[w[[1]] /. y -> v];
      If[! FreeQ[restricted, ComplexInfinity | Indeterminate], Continue[]];
      values = Join[values, RootReduce[Together[Residue[restricted, {x, #}]]] & /@ roots];
      AppendTo[samples, v],
      (* horizontal line(s) y = const: transverse variable y on x = v *)
      roots = y /. Solve[curve == 0, y];
      roots = Select[roots, clean[{x -> v, y -> #}] &];
      If[roots === {}, Continue[]];
      restricted = Together[w[[2]] /. x -> v];
      If[! FreeQ[restricted, ComplexInfinity | Indeterminate], Continue[]];
      values = Join[values, RootReduce[Together[Residue[restricted, {y, #}]]] & /@ roots];
      AppendTo[samples, v]]];
  DeleteDuplicates[values, PossibleZeroQ[RootReduce[#1 - #2]] &]];

(* rational primitive of an exact rational 1-form; $Failed when the
   result is not rational (a log or arctan survives) or does not
   differentiate back *)
epsFormObstructionPrimitive[w_List, {x_, y_}] := Module[{rx, g, r},
  rx = Integrate[w[[1]], x];
  If[! FreeQ[rx, Log | ArcTan | ArcTanh | Integrate], Return[$Failed]];
  g = Together[w[[2]] - D[rx, y]];
  If[! FreeQ[g, x], Return[$Failed]];
  r = Together[rx + Integrate[g, y]];
  If[! FreeQ[r, Log | ArcTan | ArcTanh | Integrate], Return[$Failed]];
  If[! (PossibleZeroQ[Together[D[r, x] - w[[1]]]] && PossibleZeroQ[Together[D[r, y] - w[[2]]]]),
    Return[$Failed]];
  r];

AnalyzeOffDiagonalBlockEpsilonFormObstructions[record_Association, OptionsPattern[]] := Module[
  {variables, epsilon, e, c, inhomogeneity, x, y, upper, lower, letters, dlog,
   maximumOrder, lines, verbose, log, series, order, w, curves, missing,
   residueTable, nonConstant, constants, exact, dk, result,
   offDiagonalBasisTransformationBlockSeries = {}, residueSeries = {}, missingLetters = {}, status,
   numeratorDegrees = {}, regulatorPoleResidues = False,
   eSeries, cSeries, product, closedQ, tw, tc, tr, tp, rationalInput, inputValuations, scope},
  If[! (AssociationQ[record] && KeyExistsQ[record, "OffDiagonalBlockEquation"] &&
      MatchQ[record["Variables"], {_Symbol, _Symbol}] && MatchQ[record["Regulator"], _Symbol]),
    Message[AnalyzeOffDiagonalBlockEpsilonFormObstructions::record]; Return[$Failed]];
  variables = record["Variables"]; {x, y} = variables; epsilon = record["Regulator"];
  {e, c, inhomogeneity} = record["OffDiagonalBlockEquation"];
  {upper, lower} = Dimensions[inhomogeneity[[1]]];
  maximumOrder = OptionValue["MaximumOrder"]; lines = OptionValue["TransverseLines"];
  scope=<|"FixedDiagonalConnections"->True,"FixedInhomogeneity"->True,
    "GaugeSeriesLowerOrder"->0,"GaugeSeriesIntegrationConstants"->"Zero representatives",
    "ResidueDependence"->"Kinematics independent at each epsilon order",
    "GenericNonexistenceProved"->False,"AlphabetCompletenessProved"->False,
    "Conclusion"->"Diagnostic for the selected finite expansion"|>;
  If[!IntegerQ[maximumOrder] || maximumOrder<0 || !IntegerQ[lines] || lines<1,
    Return[<|"Status"->"InvalidExpansionDiagnosticOptions","ConclusionScope"->scope|>]];
  rationalInput=Together /@ Flatten[{e,c,inhomogeneity}];
  If[!AllTrue[rationalInput,PolynomialQ[Numerator[#],Append[variables,epsilon]] &&
      PolynomialQ[Denominator[#],Append[variables,epsilon]]&],
    Return[<|"Status"->"UnsupportedCoefficientField","ConclusionScope"->scope,
      "Reason"->"This diagnostic requires rational functions of the declared variables."|>]];
  inputValuations=If[#===0,Infinity,Exponent[Numerator[#],epsilon,Min]-
    Exponent[Denominator[#],epsilon,Min]]& /@ rationalInput;
  If[Min[inputValuations]<0,
    Return[<|"Status"->"LaurentExpansionLowerOrderRequired","ConclusionScope"->scope,
      "Reason"->"Negative input orders require an explicit Laurent-series analysis."|>]];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[obstruction] ", args]];
  letters = If[OptionValue["Alphabet"] === Automatic,
    offDiagonalBlockAlphabet[{e, c, inhomogeneity}, variables, epsilon], OptionValue["Alphabet"]];
  If[letters === $Failed, Return[$Failed]];
  letters = DeleteDuplicates[Join[letters, OptionValue["ExtraLetters"]]];
  series[f_, k_] := Together[SeriesCoefficient[f, {epsilon, 0, k}]];
  (* e and c may carry the regulator (older fixtures): expand them too;
     the order-k form is w_k = Sum_m (e_m D_{k-1-m} - D_{k-1-m} c_m) + B_k
     and the basis-transformation block series starts at order 0 when the inhomogeneity has an
     eps^0 part (its residues must then vanish: no dlog is available at
     order 0) *)
  offDiagonalBasisTransformationBlockSeries = {};
  status = "NoObstructionToOrder";
  (* the order-m series of e and c are formed once (memoized per mu and m)
     and each matrix product once per (mu, m); the earlier form recomputed
     the whole product inside the entry loop, upper*lower times *)
  eSeries[mu_, m_] := eSeries[mu, m] = Map[series[#, m] &, e[[mu]], {2}];
  cSeries[mu_, m_] := cSeries[mu, m] = Map[series[#, m] &, c[[mu]], {2}];
  Do[
    {tw, w} = AbsoluteTiming[Table[
      product = Sum[With[{dd = offDiagonalBasisTransformationBlockSeries[[order - m]]},   (* D_{order-1-m} is the entry at order-m of the off-diagonal basis-transformation-block series (1-based, D_0 first) *)
        eSeries[mu, m].dd - dd.cSeries[mu, m]], {m, 0, order - 1}];
      Table[Together[If[order === 0, 0, product[[i, j]]] + series[inhomogeneity[[mu, i, j]], order]],
        {i, upper}, {j, lower}],
      {mu, 2}]];
    {tc, closedQ} = AbsoluteTiming[
      AllTrue[Flatten[Table[Together[D[w[[1, i, j]], y] - D[w[[2, i, j]], x]], {i, upper}, {j, lower}]], PossibleZeroQ]];
    If[! closedQ,
      status = "NotClosed"; log["order ", order, ": the form is not closed (integrability violated)"];
      result = <|"Status" -> status, "Order" -> order|>; Break[]];
    curves = epsFormObstructionPolarCurves[w, variables];
    dlog = Table[Together[D[Log[L], v]], {L, Join[letters, Complement[curves, letters, -letters]]}, {v, variables}];
    missing = Select[curves, ! MemberQ[letters, #] && ! MemberQ[letters, -#] &];
    (* residues along every polar curve, every entry *)
    {tr, residueTable} = AbsoluteTiming[Table[
      Module[{r = epsFormObstructionResidues[w[[All, i, j]], L, DeleteCases[curves, L], {x, y}, lines]},
        <|"Curve" -> L, "Entry" -> {i, j}, "Values" -> r|>],
      {L, curves}, {i, upper}, {j, lower}]];
    residueTable = Flatten[residueTable];
    (* nonzero constant residues at order 0 are a dlog part of the inhomogeneity
       that no rational basis-transformation block removes; the completed block then carries
       residues with a regulator pole (K_0/eps), which the sector-level
       regulator factorization absorbs in measured production blocks --
       recorded, not an obstruction. *)
    If[AnyTrue[residueTable,Lookup[#,"Values",{}]==={}&],
      status="ResidueEvaluationInconclusive";
      result=<|"Status"->status,"Order"->order|>;Break[]];
    nonConstant = Select[residueTable, Length[#["Values"]] > 1 &];
    If[order === 0 && AnyTrue[residueTable, #["Values"] =!= {} && ! PossibleZeroQ[First[#["Values"]]] &],
      regulatorPoleResidues = True];
    If[nonConstant =!= {},
      status = "ResidueComponentsNotResolved";
      log["order ", order, ": unequal residue samples on ", nonConstant[[1, "Curve"]], " entry ", nonConstant[[1, "Entry"]], ": ", N[nonConstant[[1, "Values"]], 8]];
      result = <|"Status" -> status, "Order" -> order,
        "Reason"->"Distinct geometric components may have different constant residues.",
        "ResidueSamples" -> (KeyTake[#, {"Curve", "Entry", "Values"}] & /@ nonConstant)|>;
      Break[]];
    missingLetters = DeleteDuplicates[Join[missingLetters,
      Select[missing, Function[L, AnyTrue[Select[residueTable, #["Curve"] === L &], ! PossibleZeroQ[First[#["Values"]]] &]]]]];
    If[missingLetters =!= {},
      status = "MissingLetters";
      log["order ", order, ": polar curves outside the alphabet with nonzero constant residue: ", missingLetters];
      result = <|"Status" -> status, "Order" -> order, "MissingLetters" -> missingLetters|>;
      Break[]];
    (* constant residues: c_{i,j,L}; exact part and its rational primitive *)
    constants = Association[(#["Curve"] -> Association[]) & /@ residueTable];
    Do[constants[t["Curve"], t["Entry"]] = If[t["Values"] === {}, 0, First[t["Values"]]], {t, residueTable}];
    exact = Table[Together[w[[mu, i, j]] - Sum[
        Lookup[Lookup[constants, L, <||>], Key[{i, j}], 0] Together[D[Log[L], variables[[mu]]]], {L, curves}]],
      {mu, 2}, {i, upper}, {j, lower}];
    {tp, dk} = AbsoluteTiming[Table[epsFormObstructionPrimitive[exact[[All, i, j]], {x, y}], {i, upper}, {j, lower}]];
    If[! FreeQ[dk, $Failed],
      status = "RationalPrimitiveNotConstructed";
      log["order ", order, ": a rational primitive was not constructed"];
      result = <|"Status" -> status, "Order" -> order|>; Break[]];
    AppendTo[residueSeries, <|"Order" -> order, "Residues" -> constants|>];
    AppendTo[offDiagonalBasisTransformationBlockSeries, dk];
    AppendTo[numeratorDegrees, Max[epsFormObstructionTotalDegree[Numerator[#], variables] & /@ Flatten[dk]]];
    log["order ", order, ": closed, residues constant on ", Length[curves], " curves, D_", order,
      " numerator total degree ", Last[numeratorDegrees],
      " (form ", Round[tw, 0.1], " s, closedness ", Round[tc, 0.1], " s, residues ", Round[tr, 0.1],
      " s, primitive ", Round[tp, 0.1], " s)"];
    result = <|"Status" -> status, "Order" -> order|>,
    {order, 0, maximumOrder}];
  Join[result, <|
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Alphabet" -> letters,
    "OffDiagonalBasisTransformationBlockSeries" -> offDiagonalBasisTransformationBlockSeries,
    "OffDiagonalBasisTransformationNumeratorDegrees" -> numeratorDegrees,
    "ResidueSeries" -> residueSeries,
    "RegulatorPoleResidues" -> regulatorPoleResidues,
    "MaximumOrder" -> maximumOrder,"ConclusionScope"->scope|>]
];
