(* Obstruction certificate for the eps-form completion of one off-diagonal
   block (k, j).

   The block equation (conventions of VerifyEpsFormStrip) is
     dD = eps (e D - D c) + bbar - eps Sum_a K_a dlog L_a
   with e, c the eps-free residue forms of the diagonal eps-forms, bbar the
   forcing, D the gauge and K_a the residues.  Expanding D = Sum eps^k D_k,
   bbar = Sum eps^k B_k (B_0 = 0 for a block between certified eps-forms)
   gives order by order
     dD_k = w_k - Sum_a K_a^(k) dlog L_a,   w_k = e D_{k-1} - D_{k-1} c + B_k,
   where w_k is a closed rational 1-form.  A closed rational 1-form on the
   plane is d(rational) + Sum_L c_L dlog L with CONSTANT c_L if and only if
   its residue along every polar curve L is constant; then D_k exists and is
   unique up to a constant matrix, and that constant shifts w_{k+1} by
   e C - C c, whose residues are constant.  Hence:
     - a polar curve of some w_k outside the alphabet with a constant
       residue is a MISSING LETTER (extend the alphabet and re-solve);
     - a NON-CONSTANT residue of some w_k along a curve proves that no
       rational gauge D exists with the present diagonal eps-forms and
       letters, whatever the ansatz (the pair needs a basis change: the
       blockwise Libra route, balances on the local pair);
     - no obstruction up to the requested order: the failure of a rational
       solver is an ansatz or budget limitation.
   Built 2026-08-22 for CF305 block (18,15): clean to order 10, every D_k
   of numerator total degree 9, residues geometric in the order -- which
   proved the block solvable and exposed the finite-field support defect
   (bidegree rectangle instead of the certified total-degree simplex).
   A transverse line through a point where two polar curves meet gives a
   false non-constant residue; such points are excluded.
*)

Clear[EpsFormStripObstruction];
ClearAll[
  epsFormObstructionResidues, epsFormObstructionPrimitive,
  epsFormObstructionPolarCurves, epsFormObstructionTotalDegree
];

EpsFormStripObstruction::record =
  "The record must contain Strip -> {e, c, bbar}, two Variables and a Regulator symbol.";

Options[EpsFormStripObstruction] = {
  "Alphabet" -> Automatic,   (* Automatic: the block's own letters (epsFormStripAlphabet) *)
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
     along the curve (CF305 (18,15): x = 1 on y = 1) *)
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

EpsFormStripObstruction[record_Association, OptionsPattern[]] := Module[
  {variables, epsilon, e, c, bbar, x, y, upper, lower, letters, dlog,
   maximumOrder, lines, verbose, log, series, order, w, curves, missing,
   residueTable, nonConstant, constants, exact, dk, result,
   gaugeSeries = {}, residueSeries = {}, missingLetters = {}, status,
   numeratorDegrees = {}, regulatorPoleResidues = False},
  If[! (AssociationQ[record] && KeyExistsQ[record, "Strip"] &&
      MatchQ[record["Variables"], {_Symbol, _Symbol}] && MatchQ[record["Regulator"], _Symbol]),
    Message[EpsFormStripObstruction::record]; Return[$Failed]];
  variables = record["Variables"]; {x, y} = variables; epsilon = record["Regulator"];
  {e, c, bbar} = record["Strip"];
  {upper, lower} = Dimensions[bbar[[1]]];
  maximumOrder = OptionValue["MaximumOrder"]; lines = OptionValue["TransverseLines"];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[obstruction] ", args]];
  letters = If[OptionValue["Alphabet"] === Automatic,
    epsFormStripAlphabet[{e, c, bbar}, variables, epsilon], OptionValue["Alphabet"]];
  If[letters === $Failed, Return[$Failed]];
  letters = DeleteDuplicates[Join[letters, OptionValue["ExtraLetters"]]];
  series[f_, k_] := Together[SeriesCoefficient[f, {epsilon, 0, k}]];
  (* e and c may carry the regulator (older fixtures): expand them too;
     the order-k form is w_k = Sum_m (e_m D_{k-1-m} - D_{k-1-m} c_m) + B_k
     and the gauge series starts at order 0 when the forcing has an
     eps^0 part (its residues must then vanish: no dlog is available at
     order 0) *)
  gaugeSeries = {};
  status = "NoObstructionToOrder";
  Do[
    w = Table[Together[
        Sum[With[{dd = gaugeSeries[[order - m]]},   (* D_{order-1-m} is gaugeSeries[[order-m]] (1-based, D_0 first) *)
          (Map[series[#, m] &, e[[mu]], {2}].dd - dd.Map[series[#, m] &, c[[mu]], {2}])[[i, j]]],
          {m, 0, order - 1}] + series[bbar[[mu, i, j]], order]],
      {mu, 2}, {i, upper}, {j, lower}];
    If[! AllTrue[Flatten[Table[Together[D[w[[1, i, j]], y] - D[w[[2, i, j]], x]], {i, upper}, {j, lower}]], PossibleZeroQ],
      status = "NotClosed"; log["order ", order, ": the form is not closed (integrability violated)"];
      result = <|"Status" -> status, "Order" -> order|>; Break[]];
    curves = epsFormObstructionPolarCurves[w, variables];
    dlog = Table[Together[D[Log[L], v]], {L, Join[letters, Complement[curves, letters, -letters]]}, {v, variables}];
    missing = Select[curves, ! MemberQ[letters, #] && ! MemberQ[letters, -#] &];
    (* residues along every polar curve, every entry *)
    residueTable = Table[
      Module[{r = epsFormObstructionResidues[w[[All, i, j]], L, DeleteCases[curves, L], {x, y}, lines]},
        <|"Curve" -> L, "Entry" -> {i, j}, "Values" -> r|>],
      {L, curves}, {i, upper}, {j, lower}];
    residueTable = Flatten[residueTable];
    (* nonzero constant residues at order 0 are a dlog part of the forcing
       that no rational gauge removes; the completed block then carries
       residues with a regulator pole (K_0/eps), which the sector-level
       regulator factorization absorbs (CF265 (17,16); CF209/211/213/217
       2026-08-22) -- recorded, not an obstruction *)
    nonConstant = Select[residueTable, Length[#["Values"]] > 1 &];
    If[order === 0 && AnyTrue[residueTable, #["Values"] =!= {} && ! PossibleZeroQ[First[#["Values"]]] &],
      regulatorPoleResidues = True];
    If[nonConstant =!= {},
      status = "NonConstantResidue";
      log["order ", order, ": non-constant residue along ", nonConstant[[1, "Curve"]], " entry ", nonConstant[[1, "Entry"]], ": ", N[nonConstant[[1, "Values"]], 8]];
      result = <|"Status" -> status, "Order" -> order,
        "Obstructions" -> (KeyTake[#, {"Curve", "Entry", "Values"}] & /@ nonConstant)|>;
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
    dk = Table[epsFormObstructionPrimitive[exact[[All, i, j]], {x, y}], {i, upper}, {j, lower}];
    If[! FreeQ[dk, $Failed],
      status = "PrimitiveNotRational";
      log["order ", order, ": the residue-free part has no rational primitive"];
      result = <|"Status" -> status, "Order" -> order|>; Break[]];
    AppendTo[residueSeries, <|"Order" -> order, "Residues" -> constants|>];
    AppendTo[gaugeSeries, dk];
    AppendTo[numeratorDegrees, Max[epsFormObstructionTotalDegree[Numerator[#], variables] & /@ Flatten[dk]]];
    log["order ", order, ": closed, residues constant on ", Length[curves], " curves, D_", order,
      " numerator total degree ", Last[numeratorDegrees]];
    result = <|"Status" -> status, "Order" -> order|>,
    {order, 0, maximumOrder}];
  Join[result, <|
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Alphabet" -> letters,
    "GaugeSeries" -> gaugeSeries,
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "ResidueSeries" -> residueSeries,
    "RegulatorPoleResidues" -> regulatorPoleResidues,
    "MaximumOrder" -> maximumOrder|>]
];
