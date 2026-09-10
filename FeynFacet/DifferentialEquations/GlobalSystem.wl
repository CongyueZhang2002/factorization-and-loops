
(* Quotient overlapping family systems by exact integral identities.
   An identity I_f=T_f G gives dT_f+T_f A_G=A_f T_f.  Repeated
   equations for the same integral yield further algebraic constraints.
   Rational specializations select independent rows; the stored elimination
   is exact. Different base points are handled later, not equated here. *)
Clear[ConstructGlobalMasterDifferentialSystem];
ClearAll[globalDEIndependentRows, globalDEZeroQ, globalDEIdentity,globalDECloseRelations];

globalDEZeroQ[x_] := Together[x] === 0;
globalDEIdentity[x_] := cutEquivalenceIntegral[x];

globalDEIndependentRows[matrix_List] := Module[{reduced},
  If[matrix === {}, Return[{}]];
  reduced = RowReduce[Transpose[matrix]];
  DeleteCases[Map[Function[row, SelectFirst[Range[Length[row]],
    row[[#]] =!= 0 &, Missing["ZeroRow"]]], reduced], _Missing]
];


(* Differential consequences of exact integral relations are relations too.
   Work at generic epsilon; rational samples only select candidate pivots.
   The retained row reduction and every final embedding are exact. *)
globalDECloseRelations[initial_,matrices_,variables_,samples_,limit_]:=Module[
 {constraints=initial,selected,rows,rank=-1,newRank,consequences,history={},n,closed=False,pivots,remainder},
 n=Length[First[matrices]];
 If[constraints==={},Return[<|"Rows"->{},"History"->{},"Closed"->True|>]];
 Do[
  If[AnyTrue[samples,!AllTrue[Flatten[constraints/.#],MatchQ[#,_Integer|_Rational]&]&],
    Return[Failure["SingularOrNonrationalRelationSample",<||>]]];
  selected=Union@@(globalDEIndependentRows[constraints/.#]&/@samples);
  rows=If[selected==={},{},Select[RowReduce[constraints[[selected]]],
    !AllTrue[#,globalDEZeroQ]&]];
  (* A special sample may lose rank. Check the whole rational row space
     before accepting the sampled selection or declaring closure. *)
  pivots=Map[Function[row,SelectFirst[Range[n],!globalDEZeroQ[row[[#]]]&]],rows];
  remainder=If[rows==={},constraints,
    Map[Together,constraints-constraints[[All,pivots]].rows,{2}]];
  remainder=Select[remainder,!AllTrue[#,globalDEZeroQ]&];
  If[remainder=!={},rows=Select[RowReduce[Join[rows,remainder]],!AllTrue[#,globalDEZeroQ]&]];
  newRank=Length[rows];
  AppendTo[history,<|"Iteration"->iteration,"RelationRank"->newRank|>];
  If[newRank===0||newRank===rank||newRank===n,closed=True;Break[]];
  rank=newRank;
  consequences=Flatten[Table[
    Map[Together,D[rows,variables[[axis]]]+rows.Normal[matrices[[axis]]],{2}],
    {axis,Length[variables]}],1];
  constraints=DeleteDuplicates[Join[rows,consequences]],
 {iteration,limit}];
 If[!closed,Return[Failure["IntegralRelationClosureIncomplete",<|"History"->history|>]]];
 <|"Rows"->rows,"History"->history,"Closed"->True|>
];

Options[ConstructGlobalMasterDifferentialSystem] = {
  "PreferredMasterIntegrals" -> {}, "ValidationPoints" -> Automatic,
  "MaximumRelationClosureIterations"->Automatic};

ConstructGlobalMasterDifferentialSystem[systems_List,
    equivalences_Association, OptionsPattern[]] := Catch@Module[
  {fail, normalized, variables, epsilon, aliases, maps, basis, indices,
   dimensions, connections = <||>, constraints = {}, familyMaps = {},
   masters, positions, embedding, matrices, localRows, row, key, difference,
   n, m, sample, samples, independent, c, support, eliminate, order,
   preferred, reduced, pivots, free, e, globalMatrices, transformed,
   residual, checks, maxResidual, tags, rowBasis, point, old, identityRules,d,
   relationClosure,relationLimit,flatnessChecks,bi,bj},
  fail[tag_, extra_: <||>] := Throw[Failure[tag, extra]];
  If[systems === {} || Lookup[equivalences, "DataType", None] =!=
      "CutIntegralEquivalences", fail["GlobalDifferentialSystemInputsRequired"]];
  If[!AllTrue[equivalences["Mappings"], Lookup[#, "Factor", None] === 1 &],
    fail["NonunitIntegralMapUnsupported"]];
  variables = systems[[1]]["KinematicVariables"];
  epsilon = systems[[1]]["DimensionalRegulator"];
  normalized = Map[Function[input,
    d=solutionNormalizeDifferentialSystem[input];
    If[FailureQ[d],fail["GlobalConnectionDimensionNormalizationFailed",<|"Cause"->d|>]];
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
  relationLimit=Replace[OptionValue["MaximumRelationClosureIterations"],Automatic->n+1];
  If[!IntegerQ[relationLimit]||relationLimit<1,fail["PositiveRelationClosureLimitRequired"]];
  relationClosure=globalDECloseRelations[constraints,globalMatrices,variables,samples,relationLimit];
  If[FailureQ[relationClosure],Throw[relationClosure]];
  c=relationClosure["Rows"];constraints=c;independent=Range[Length[c]];
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
  flatnessChecks=Table[
    residual=Table[
      bi=Normal[transformed[[i]]]/.point;bj=Normal[transformed[[j]]]/.point;
      (D[Normal[transformed[[j]]],variables[[i]]]/.point)-
       (D[Normal[transformed[[i]]],variables[[j]]]/.point)+bj.bi-bi.bj,
      {i,Length[variables]},{j,i+1,Length[variables]}];
    If[!AllTrue[Flatten[residual],#===0&],fail["SharedConnectionNotFlat",<|"Point"->point|>]];
    <|"Point"->point,"FlatnessPassed"->True|>,{point,samples}];
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
    "RelationClosureHistory"->relationClosure["History"],
    "GlobalSpanningMasterCount" -> Length[free],
    "MinimalMasterCountDetermined" -> False,
    "PhysicalBoundaryConditionsApplied" -> False,
    "Validation" -> <|"Method" -> "ExactRationalSpecializations",
      "Checks" -> checks,"FlatnessChecks"->flatnessChecks,
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

(* Restrict a flat connection to the differential closure of independently
   established homogeneous linear relations. This is also used for physical
   asymptotic conditions; it does not supply a proof of their physical input. *)
FeynFacet`RestrictDifferentialSystemToRelations::usage =
 "RestrictDifferentialSystemToRelations[system,rows,request] closes supplied exact homogeneous relations under every kinematic derivative, constructs a basis of their common nullspace, and verifies the induced connection and full embedding identities.";
FeynFacet`RestrictDifferentialSystemToRelations[system_Association,relations_List,
 request_Association:<||>] := Catch[Module[
 {s,variables,e,a,n,samples,closed,c,basis,rows,left,selection,connection,residual,m},
 s=solutionNormalizeDifferentialSystem[system];If[FailureQ[s],Throw[s]];
 variables=s["KinematicVariables"];e=s["DimensionalRegulator"];
 a=Normal/@s["ConnectionMatrices"];n=Length[First[a]];
 If[!AllTrue[a,Dimensions[#]==={n,n}&]||
   (relations=!={}&&Dimensions[relations]=!={Length[relations],n}),
  Throw[Failure["DifferentialRelationDimensionsInvalid",<||>]]];
 samples=Lookup[request,"ValidationPoints",Table[
  Thread[Append[variables,e]->Table[1/Prime[7k+j+3],{j,Length[variables]+1}]],{k,2}]];
 closed=globalDECloseRelations[relations,a,variables,samples,n+1];
 If[FailureQ[closed],Throw[closed]];c=closed["Rows"];
 basis=If[c==={},IdentityMatrix[n],Transpose[NullSpace[c]]];
 m=If[basis==={},0,Last[Dimensions[basis]]];
 If[m===0,Throw[Failure["RelationsForceZeroSolution",<|"RelationClosure"->closed|>]]];
 rows=globalDEIndependentRows[basis];selection=IdentityMatrix[n][[rows]];
 left=Map[Cancel,Inverse[basis[[rows]]].selection,{2}];
 connection=Table[Map[Together,left.(a[[j]].basis-D[basis,variables[[j]]]),{2}],
  {j,Length[variables]}];
 residual=Flatten@Table[D[basis,variables[[j]]]+basis.connection[[j]]-a[[j]].basis,
  {j,Length[variables]}];
 If[!AllTrue[residual,globalDEZeroQ]||
   !AllTrue[Flatten[left.basis-IdentityMatrix[m]],globalDEZeroQ]||
   (c=!={}&&!AllTrue[Flatten[c.basis],globalDEZeroQ]),
  Throw[Failure["RestrictedConnectionEmbeddingFailed",<||>]]];
 If[!And@@Flatten@Table[
   AllTrue[Flatten[D[connection[[i]],variables[[j]]]-D[connection[[j]],variables[[i]]]+
    connection[[i]].connection[[j]]-connection[[j]].connection[[i]]],globalDEZeroQ],
  {i,Length[variables]},{j,i+1,Length[variables]}],
  Throw[Failure["RestrictedConnectionNotFlat",<||>]]];
 <|"DataType"->"ConstrainedDifferentialSystem","KinematicVariables"->variables,
  "DimensionalRegulator"->e,"ConnectionMatrices"->connection,"Dimension"->m,
  "OriginalMasterIntegralBasis"->Range[m],"SourceDimension"->n,
  "SolutionEmbedding"->basis,"SolutionLeftInverse"->left,
  "RelationClosure"->closed,"RelationProvenance"->Lookup[request,"RelationProvenance",None],
  "Verification"-><|"DifferentialClosure"->True,"Embedding"->True,"LeftInverse"->True,
   "Flatness"->True,"Method"->"ExactRationalIdentities"|>|>
]];
