
(* Quotient overlapping family systems by exact integral identities.
   An identity I_f=T_f G gives dT_f+T_f A_G=A_f T_f.  Repeated
   equations for the same integral yield further algebraic constraints.
   Rational specializations select independent rows; the stored elimination
   is exact. Different base points are handled later, not equated here. *)
Clear[ConstructGlobalMasterDifferentialSystem];
ClearAll[globalDEIndependentRows, globalDEZeroQ, globalDEIdentity];

globalDEZeroQ[x_] := Together[x] === 0;
globalDEIdentity[x_] := cutEquivalenceIntegral[x];

globalDEIndependentRows[matrix_List] := Module[{reduced},
  If[matrix === {}, Return[{}]];
  reduced = RowReduce[Transpose[matrix]];
  DeleteCases[Map[Function[row, SelectFirst[Range[Length[row]],
    row[[#]] =!= 0 &, Missing["ZeroRow"]]], reduced], _Missing]
];

Options[ConstructGlobalMasterDifferentialSystem] = {
  "PreferredMasterIntegrals" -> {}, "ValidationPoints" -> Automatic};

ConstructGlobalMasterDifferentialSystem[systems_List,
    equivalences_Association, OptionsPattern[]] := Catch@Module[
  {fail, normalized, variables, epsilon, aliases, maps, basis, indices,
   dimensions, connections = <||>, constraints = {}, familyMaps = {},
   masters, positions, embedding, matrices, localRows, row, key, difference,
   n, m, sample, samples, independent, c, support, eliminate, order,
   preferred, reduced, pivots, free, e, globalMatrices, transformed,
   residual, checks, maxResidual, tags, rowBasis, point, old, identityRules},
  fail[tag_, extra_: <||>] := Throw[Failure[tag, extra]];
  If[systems === {} || Lookup[equivalences, "DataType", None] =!=
      "CutIntegralEquivalences", fail["GlobalDifferentialSystemInputsRequired"]];
  If[!AllTrue[equivalences["Mappings"], Lookup[#, "Factor", None] === 1 &],
    fail["NonunitIntegralMapUnsupported"]];
  variables = systems[[1]]["KinematicVariables"];
  epsilon = systems[[1]]["DimensionalRegulator"];
  normalized = Map[Function[d,
    If[Length[d["KinematicVariables"]] =!= Length[variables] ||
        (SymbolName /@ d["KinematicVariables"]) =!= (SymbolName /@ variables),
      fail["KinematicCoordinatesDiffer"]];
    aliases = Join[Thread[d["KinematicVariables"] -> variables],
      {d["DimensionalRegulator"] -> epsilon}];
    <|"Family" -> d["Family"],
      "Basis" -> (globalDEIdentity /@ d["OriginalMasterIntegralBasis"]),
      "Matrices" -> ((Normal /@ If[AssociationQ[d["ConnectionMatrices"]],
        Lookup[d["ConnectionMatrices"], d["KinematicVariables"]],
        d["ConnectionMatrices"]]) /. aliases)|>], systems];
  maps = Association[(globalDEIdentity[#["Source"]] ->
    globalDEIdentity[#["Representative"]]) & /@ equivalences["Mappings"]];
  basis = DeleteDuplicates[Values[maps]]; n = Length[basis];
  indices = AssociationThread[basis, Range[n]];
  preferred = globalDEIdentity /@ OptionValue["PreferredMasterIntegrals"];
  Do[
    masters = d["Basis"]; m = Length[masters];
    If[Complement[masters, Keys[maps]] =!= {}, fail["IntegralMapsIncomplete"]];
    positions = (indices[maps[#]] & /@ masters);
    embedding = SparseArray[Thread[Transpose[{Range[m], positions}] -> 1], {m, n}];
    matrices = d["Matrices"];
    If[Length[matrices] =!= Length[variables] ||
        ! AllTrue[matrices, Dimensions[#] === {m, m} &],
      fail["FamilyConnectionDimensionsInvalid"]];
    localRows = (#.embedding & /@ matrices);
    Do[
      key = {q, positions[[j]]}; row = localRows[[q, j]];
      If[KeyExistsQ[connections, key],
        old = connections[key];
        difference = Together /@ Normal[row - old];
        If[! AllTrue[difference, # === 0 &],
          AppendTo[constraints, difference]];
        If[LeafCount[row] < LeafCount[old], AssociateTo[connections, key -> row]],
        AssociateTo[connections, key -> row]],
      {q, Length[variables]}, {j, m}];
    AppendTo[familyMaps, <|"Family" -> d["Family"],
      "OriginalMasterIntegralBasis" -> masters,
      "IntegralEmbedding" -> embedding|>],
    {d, normalized}];
  If[Length[connections] =!= n Length[variables],
    fail["GlobalDifferentialSystemNotClosed"]];
  globalMatrices = Table[SparseArray[
    Table[Normal[connections[{q, j}]], {j, n}]], {q, Length[variables]}];
  constraints = SortBy[DeleteDuplicates[constraints], LeafCount];
  samples = OptionValue["ValidationPoints"];
  If[samples === Automatic,
    samples = Table[Thread[Append[variables, epsilon] ->
      Table[1/Prime[7 k + j + 3], {j, Length[variables] + 1}]], {k, 2}]];
  If[! MatchQ[samples, {__List}], fail["RationalValidationPointsRequired"]];
  Do[
    sample = constraints /. point;
    If[! AllTrue[Flatten[sample], MatchQ[#, _Integer | _Rational] &],
      fail["SingularOrNonrationalValidationPoint", <|"Point" -> point|>]],
    {point, samples}];
  independent = If[constraints === {}, {},
    globalDEIndependentRows[constraints /. First[samples]]];
  c = If[independent === {}, {}, constraints[[independent]]];
  support = If[c === {}, {}, Select[Range[n],
    AnyTrue[c[[All, #]], # =!= 0 &] &]];
  (* Eliminate nonpreferred integrals first. This avoids solving simple
     volume integrals in terms of complicated raised-propagator integrals. *)
  eliminate = Select[support, ! MemberQ[preferred, basis[[#]]] &];
  order = Join[eliminate, Complement[support, eliminate]];
  reduced = If[c === {}, {}, RowReduce[c[[All, order]]]];
  pivots = If[c === {}, {}, Map[Function[row,
    SelectFirst[Range[Length[row]], ! globalDEZeroQ[row[[#]]] &]], reduced]];
  pivots = If[c === {}, {}, order[[pivots]]];
  free = Complement[Range[n], pivots];
  e = SparseArray[Thread[Transpose[{free, Range[Length[free]]}] -> 1],
    {n, Length[free]}];
  Do[
    row = ConstantArray[0, n]; row[[order]] = reduced[[j]];
    e[[pivots[[j]]]] = -row[[free]],
    {j, Length[pivots]}];
  (* Exact arithmetic, numeric points: cheap consistency validation of the
     full family equations and the derivative of the retained identities. *)
  checks = Table[
    sample = constraints /. point;
    maxResidual = If[constraints === {}, 0,
      Max[Abs[Flatten[sample.(Normal[e] /. point)]]]];
    If[maxResidual =!= 0, fail["ConstraintSelectionIncomplete",
      <|"Point" -> point, "Residual" -> maxResidual|>]];
    transformed = Table[
      (Normal[globalMatrices[[q]]] /. point).(Normal[e] /. point) -
        (D[Normal[e], variables[[q]]] /. point), {q, Length[variables]}];
    residual = Table[transformed[[q]] -
      (Normal[e] /. point).transformed[[q, free]], {q, Length[variables]}];
    If[! AllTrue[Flatten[Normal /@ residual], # === 0 &],
      fail["DifferentiatedIntegralRelationsRequired", <|"Point" -> point|>]];
    <|"Point" -> point, "ConstraintRank" -> Length[independent],
      "AllIdentitiesZero" -> True, "DifferentialCompatibilityZero" -> True|>,
    {point, samples}];
  (* The free rows are coordinate projections, so dE is zero there. *)
  transformed = (# [[free]].e & /@ globalMatrices);
  familyMaps = (Join[#, <|"IntegralEmbedding" ->
    (#["IntegralEmbedding"].e)|>] &) /@ familyMaps;
  identityRules = Thread[basis -> (Normal[e].basis[[free]])];
  <|"DataType" -> "GlobalMasterDifferentialSystem", "SchemaVersion" -> 1,
    "KinematicVariables" -> variables, "DimensionalRegulator" -> epsilon,
    "MasterIntegralBasis" -> basis[[free]],
    "ConnectionMatrices" -> transformed,
    "FamilyMaps" -> familyMaps, "MasterIntegralIdentities" -> identityRules,
    "UnreducedMasterIntegralBasis" -> basis,
    "IndependentIntegralConstraintMatrix" -> If[c === {}, SparseArray[{}, {0, n}], SparseArray[c]],
    "IntegralEmbedding" -> e,
    "InputFamilyCount" -> Length[systems],
    "InputMasterCount" -> Total[Length[#["Basis"]] & /@ normalized],
    "EquivalenceClassCount" -> n,
    "IndependentRelationCount" -> Length[independent],
    "GlobalSpanningMasterCount" -> Length[free],
    "MinimalMasterCountDetermined" -> False,
    "PhysicalBoundaryConditionsApplied" -> False,
    "Validation" -> <|"Method" -> "ExactRationalSpecializations",
      "Checks" -> checks,
      "Scope" -> "Selected exact identities and differential compatibility; no minimality or physical-mode claim."|>|>
];


Clear[ConstructRequestedMasterDifferentialSystem];
ConstructRequestedMasterDifferentialSystem[system_Association, requested_List] :=
 Catch@Module[{basis, masters, n, matrices, embeddings = {}, row, local, pos,
   active, next, support, sourceMap, zero},
  basis = system["MasterIntegralBasis"]; n = Length[basis];
  masters = globalDEIdentity /@ requested;
  matrices = Together /@ (Normal /@ system["ConnectionMatrices"]);
  Do[
    pos = FirstPosition[basis, master, None];
    If[pos =!= None,
      row = UnitVector[n, First[pos]],
      sourceMap = SelectFirst[Lookup[system,"FamilyMaps",{}],
        MemberQ[#["OriginalMasterIntegralBasis"], master] &, None];
      If[sourceMap === None, Throw[Failure["RequestedMasterNotMapped",
        <|"Master" -> master|>]]];
      pos = First@FirstPosition[sourceMap["OriginalMasterIntegralBasis"], master];
      row = Normal[sourceMap["IntegralEmbedding"]][[pos]]];
    AppendTo[embeddings, row], {master, masters}];
  active = Select[Range[n], Function[j, AnyTrue[embeddings,
    Function[r, !globalDEZeroQ[r[[j]]]]]]];
  While[True,
    next = Union[active, Flatten[Table[
      Select[Range[n], Function[j, AnyTrue[matrices,
        Function[m, m[[i,j]] =!= 0]]]], {i, active}]]];
    If[next === active, Break[]]; active = next];
  <|"DataType" -> "RequestedMasterDifferentialSystem", "SchemaVersion" -> 1,
    "KinematicVariables" -> system["KinematicVariables"],
    "DimensionalRegulator" -> system["DimensionalRegulator"],
    "MasterIntegralBasis" -> basis[[active]],
    "ConnectionMatrices" -> (SparseArray[#[[active,active]]] & /@ matrices),
    "SourceMasterRows" -> active, "SourceDimension" -> n,
    "RequestedMasterIntegrals" -> masters,
    "RequestedMasterEmbeddings" -> SparseArray[embeddings[[All,active]]],
    "Dimension" -> Length[active],
    "ClosureVerification" -> "Exact rational zero tests of all excluded columns in retained derivative rows."|>
];
