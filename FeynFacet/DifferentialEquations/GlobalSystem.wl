
(* Quotient overlapping family systems by exact integral identities.
   An identity I_f=T_f G gives dT_f+T_f A_G=A_f T_f.  Repeated
   equations for the same integral yield further algebraic constraints.
   Rational specializations select independent rows; the stored elimination
   is exact. Different base points are handled later, not equated here. *)
Clear[ConstructGlobalMasterDifferentialSystem];
ClearAll[globalDEIndependentRows, globalDEZeroQ, globalDEIdentity,globalDECloseRelations,
  globalDECancelMatrix,globalDERowReduction,globalDEExactInverse,globalDEEmbeddingResidual];

globalDEZeroQ[x_] := Together[x] === 0;
globalDEIdentity[x_] := cutEquivalenceIntegral[x];

globalDEIndependentRows[matrix_List] := Module[{reduced},
  If[matrix === {}, Return[{}]];
  reduced = RowReduce[Transpose[matrix]];
  DeleteCases[Map[Function[row, SelectFirst[Range[Length[row]],
    row[[#]] =!= 0 &, Missing["ZeroRow"]]], reduced], _Missing]
];


(* Exact sparse Gaussian elimination over rational functions. Rational
   specializations choose rows elsewhere; every elimination here is exact.
   Unit pivots and low fill-in avoid the expression growth of generic RREF. *)
globalDECancelMatrix[matrix_List]:=Module[{values},
 If[matrix==={},Return[{}]];
 values=FeynFacet`CancelRationalCoefficients[Flatten[matrix]];
 If[!ListQ[values]||Length[values]=!=Times@@Dimensions[matrix],
  Return[Failure["ExactRelationCancellationFailed",<|"Cause"->values|>]]];
 Partition[values,Length[First[matrix]]]
];
globalDERowReduction[matrix_List,allowed_:Automatic]:=Module[
 {active=matrix,rows={},pivots={},columns,pivot,rowIndex,column,row,nonzero,rowCounts,
  columnCounts,affected,updated,order,n},
 If[matrix==={},Return[<|"Rows"->{},"PivotColumns"->{},"RemainingRows"->{}|>]];
 n=Length[First[matrix]];columns=Replace[allowed,Automatic->Range[n]];
 If[!MatrixQ[matrix]||!VectorQ[columns,IntegerQ[#]&&1<=#<=n&]||!DuplicateFreeQ[columns],
  Return[Failure["ExactRelationMatrixAndColumnsRequired",<||>]]];
 active=globalDECancelMatrix[active];If[FailureQ[active],Return[active]];
 While[active=!={},
  rowCounts=Count[#,_?(#=!=0&)]&/@active;
  columnCounts=Count[#,_?(#=!=0&)]&/@Transpose[active];
  nonzero=Select[Position[active,_?(#=!=0&),{2},Heads->False],MemberQ[columns,Last[#]]&];
  If[nonzero==={},Break[]];
  pivot=First@MinimalBy[nonzero,Function[position,
   {If[MemberQ[{1,-1},Extract[active,position]],0,1],
    (rowCounts[[position[[1]]]]-1)(columnCounts[[position[[2]]]]-1),
    LeafCount[Extract[active,position]],position[[2]],position[[1]]}]];
  {rowIndex,column}=pivot;
  updated=globalDECancelMatrix[{active[[rowIndex]]/active[[rowIndex,column]]}];
  If[FailureQ[updated],Return[updated,Module]];row=First[updated];
  active=Delete[active,rowIndex];
  affected=Select[Range[Length[active]],active[[#,column]]=!=0&];
  If[affected=!={},
   updated=globalDECancelMatrix[(#-#[[column]]row)&/@active[[affected]]];
   If[FailureQ[updated],Return[updated,Module]];active[[affected]]=updated];
  affected=Select[Range[Length[rows]],rows[[#,column]]=!=0&];
  If[affected=!={},
   updated=globalDECancelMatrix[(#-#[[column]]row)&/@rows[[affected]]];
   If[FailureQ[updated],Return[updated,Module]];rows[[affected]]=updated];
  AppendTo[rows,row];AppendTo[pivots,column];
  active=Select[active,!AllTrue[#,#===0&]&]];
 order=Ordering[pivots];
 <|"Rows"->rows[[order]],"PivotColumns"->pivots[[order]],"RemainingRows"->active|>
];
globalDEEmbeddingResidual[source_List,embedding_List,target_List,variables_List]:=
 Table[globalDECancelMatrix[D[embedding,variables[[j]]]+
   Normal[SparseArray[embedding].SparseArray[target[[j]]]-
     SparseArray[source[[j]]].SparseArray[embedding]]],{j,Length[variables]}];

globalDEExactInverse[matrix_List]:=Module[{n=Length[matrix],result,inverse,residual},
 If[Dimensions[matrix]=!={n,n},Return[Failure["SquareExactBasisMatrixRequired",<||>]]];
 If[matrix===IdentityMatrix[n],Return[matrix]];
 result=globalDERowReduction[Join[matrix,IdentityMatrix[n],2],Range[n]];
 If[FailureQ[result],Return[result]];
 If[result["PivotColumns"]=!=Range[n],Return[Failure["SingularExactBasisMatrix",<||>]]];
 inverse=result["Rows"][[All,n+1;;2n]];
 residual=globalDECancelMatrix[SparseArray[matrix].SparseArray[inverse]-IdentityMatrix[n]//Normal];
 If[FailureQ[residual]||!AllTrue[Flatten[residual],#===0&],
  Return[Failure["ExactBasisInverseFailed",<||>]]];
 inverse
];

(* Differential consequences of exact integral relations are relations too.
   Work at generic epsilon; rational samples only select candidate pivots.
   The retained row reduction and every final embedding are exact. *)
globalDECloseRelations[initial_,matrices_,variables_,samples_,limit_]:=Module[
 {constraints=initial,selected,rows,rank=-1,newRank,consequences,history={},n,
  closed=False,pivots={},remainder,reduced,validSamples},
 n=Length[First[matrices]];
 If[constraints==={},Return[<|"Rows"->{},"PivotColumns"->{},"History"->{},"Closed"->True|>]];
 Do[
  If[samples==={},
   (* Sampling is an optional row-selection optimization. Boundary systems
      may omit it; exact elimination still supplies the complete proof. *)
   selected=Range[Length[constraints]],
   validSamples=Select[samples,
    Quiet[AllTrue[Flatten[constraints/.#],MatchQ[#,_Integer|_Rational]&],{Power::infy,Infinity::indet}]&];
   If[validSamples==={},Return[Failure["SingularOrNonrationalRelationSample",<||>],Module]];
   selected=Union@@(globalDEIndependentRows[constraints/.#]&/@validSamples)
  ];
  reduced=globalDERowReduction[If[selected==={},{},constraints[[selected]]]];
  If[FailureQ[reduced],Return[reduced,Module]];
  rows=reduced["Rows"];pivots=reduced["PivotColumns"];
  remainder=If[rows==={},constraints,globalDECancelMatrix[
    Normal[constraints-SparseArray[constraints[[All,pivots]]].SparseArray[rows]]]];
  If[FailureQ[remainder],Return[remainder,Module]];
  remainder=Select[remainder,!AllTrue[#,globalDEZeroQ]&];
  If[remainder=!={},
   reduced=globalDERowReduction[Join[rows,remainder]];
   If[FailureQ[reduced],Return[reduced,Module]];
   rows=reduced["Rows"];pivots=reduced["PivotColumns"]];
  newRank=Length[rows];
  AppendTo[history,<|"Iteration"->iteration,"RelationRank"->newRank|>];
  If[newRank===0||newRank===rank||newRank===n,closed=True;Break[]];
  rank=newRank;
  consequences=Table[globalDECancelMatrix[
    D[rows,variables[[axis]]]+Normal[SparseArray[rows].SparseArray[matrices[[axis]]]]],
    {axis,Length[variables]}];
  If[AnyTrue[consequences,FailureQ],Return[First@Select[consequences,FailureQ],Module]];
  constraints=DeleteDuplicates[Join[rows,Flatten[consequences,1]]],
 {iteration,limit}];
 If[!closed,Return[Failure["IntegralRelationClosureIncomplete",<|"History"->history|>]]];
 <|"Rows"->rows,"PivotColumns"->pivots,"History"->history,"Closed"->True|>
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
 {s,variables,e,a,n,samples,closed,c,basis,left,connection,residual,m,pivots,free,
  normalizedRelations,check,clock=SessionTime[],times=<||>},
 check[value_]:=If[FailureQ[value],Throw[value]];
 s=solutionNormalizeDifferentialSystem[system];check[s];
 variables=s["KinematicVariables"];e=s["DimensionalRegulator"];
 a=Normal/@s["ConnectionMatrices"];n=Length[First[a]];
 If[!AllTrue[a,Dimensions[#]==={n,n}&]||
   (relations=!={}&&Dimensions[relations]=!={Length[relations],n}),
  Throw[Failure["DifferentialRelationDimensionsInvalid",<||>]]];
 samples=Lookup[request,"ValidationPoints",Table[
  Thread[Append[variables,e]->Table[1/Prime[7k+j+3],{j,Length[variables]+1}]],{k,2}]];
 samples=differentialDimensionPoint[#,system,"Regulator"]&/@samples;
 Scan[check,samples];
 normalizedRelations=relations/.Lookup[system,"DimensionRule",{}];
 closed=globalDECloseRelations[normalizedRelations,a,variables,samples,n+1];check[closed];
 AssociateTo[times,"RelationEliminationSeconds"->SessionTime[]-clock];clock=SessionTime[];
 c=closed["Rows"];pivots=closed["PivotColumns"];free=Complement[Range[n],pivots];m=Length[free];
 If[m===0,Throw[Failure["RelationsForceZeroSolution",<|"RelationClosure"->closed|>]]];
 basis=Normal[SparseArray[Thread[Transpose[{free,Range[m]}]->1],{n,m}]];
 If[pivots=!={},basis[[pivots]]=-c[[All,free]]];
 left=IdentityMatrix[n][[free]];
 connection=Table[globalDECancelMatrix[Normal[SparseArray[a[[j,free]]].SparseArray[basis]]],
   {j,Length[variables]}];Scan[check,connection];
 AssociateTo[times,"CoordinateEmbeddingSeconds"->SessionTime[]-clock];clock=SessionTime[];
 residual=globalDEEmbeddingResidual[a,basis,connection,variables];Scan[check,residual];
 If[!AllTrue[Flatten[residual],#===0&]||left.basis=!=IdentityMatrix[m],
  Throw[Failure["RestrictedConnectionEmbeddingFailed",<||>]]];
 If[c=!={},
  residual=globalDECancelMatrix[Normal[SparseArray[c].SparseArray[basis]]];check[residual];
  If[!AllTrue[Flatten[residual],#===0&],Throw[Failure["RestrictedConstraintsFailed",<||>]]]];
 Do[
  residual=globalDECancelMatrix[D[connection[[i]],variables[[j]]]-D[connection[[j]],variables[[i]]]+
    Normal[SparseArray[connection[[i]]].SparseArray[connection[[j]]]-
      SparseArray[connection[[j]]].SparseArray[connection[[i]]]]];check[residual];
  If[!AllTrue[Flatten[residual],#===0&],Throw[Failure["RestrictedConnectionNotFlat",<||>]]],
 {i,Length[variables]},{j,i+1,Length[variables]}];
 AssociateTo[times,"ExactEmbeddingAndFlatnessSeconds"->SessionTime[]-clock];
 <|"DataType"->"ConstrainedDifferentialSystem","KinematicVariables"->variables,
  "DimensionalRegulator"->e,"ConnectionMatrices"->connection,"Dimension"->m,
  "OriginalMasterIntegralBasis"->Range[m],"SourceDimension"->n,
  "FreeColumns"->free,"SolutionEmbedding"->basis,"SolutionLeftInverse"->left,
  "RelationClosure"->closed,"PhaseSeconds"->times,
  "RelationProvenance"->Lookup[request,"RelationProvenance",None],
  "Verification"-><|"DifferentialClosure"->True,"Embedding"->True,"LeftInverse"->True,
   "Flatness"->True,"Method"->"ExactRationalIdentities"|>|>
]];
