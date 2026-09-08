
(* Exact affine elimination of already established physical amplitude
   equations. A rational specialization selects pivots; identities are solved
   over the original coefficient field, never fitted numerically. *)
Begin["FeynFacet`Private`"];
FeynFacet`SolveBoundaryAmplitudeRelations::usage="SolveBoundaryAmplitudeRelations[relations,epsilon,witness] solves independent exact equations Matrix.amplitudes=Values and returns an affine map in the uneliminated amplitude indices.";
FeynFacet`SolveBoundaryAmplitudeRelations[relations_Association,eps_Symbol,witness_Rule] := Catch[Module[
 {matrix=Normal[relations["Matrix"]],values=relations["Values"],sample,reduced,pivots,
  free,n,r,lhs,constant,coeff,fullConstant,fullMatrix},
 If[!MatrixQ[matrix]||Length[matrix]=!=Length[values]||First[witness]=!=eps,
  boundaryIntegrationFail["BoundaryAmplitudeEquationsInvalid"]];
 {r,n}=Dimensions[matrix];sample=matrix/.witness;
 If[!MatrixQ[sample,NumberQ]||MatrixRank[sample]=!=r,
   boundaryIntegrationFail["IndependentBoundaryAmplitudeEquationsRequired"]];
 reduced=RowReduce[sample];
 pivots=First[First[Position[#,x_/;x=!=0,{1},Heads->False]]]&/@reduced;free=Complement[Range[n],pivots];
 lhs=matrix[[All,pivots]];
 constant=Cancel[Together[#]]&/@LinearSolve[lhs,values];
 If[Length[DeleteDuplicates[pivots]]=!=r||!AllTrue[pivots,1<=#<=n&],
   boundaryIntegrationFail["AmplitudePivotSelectionFailed"]];
 coeff=If[free==={},ConstantArray[{},r],
   Map[Cancel[Together[#]]&,LinearSolve[lhs,-matrix[[All,free]]],{2}]];
 If[!ListQ[constant]||Length[constant]=!=r||Dimensions[coeff]=!={r,Length[free]}||
   !FreeQ[{constant,coeff},_LinearSolve|$Failed|_Part],boundaryIntegrationFail["AmplitudeRelationSolveFailed"]];
 fullConstant=ConstantArray[0,n];fullConstant[[pivots]]=constant;
 fullMatrix=ConstantArray[0,{n,Length[free]}];
 fullMatrix[[pivots]]=coeff;
 Do[fullMatrix[[free[[j]],j]]=1,{j,Length[free]}];
 If[!AllTrue[Flatten[Normal[matrix.fullMatrix]],TrueQ[Cancel[Together[#]]===0]&]||
   !AllTrue[matrix.fullConstant-values,TrueQ[Cancel[Together[#]]===0]&],
   boundaryIntegrationFail["AmplitudeRelationResidualFailed"]];
 <|"DataType"->"BoundaryAmplitudeRelations","KnownAmplitudeVector"->fullConstant,
   "RemainingAmplitudeMatrix"->fullMatrix,"SolvedAmplitudeIndices"->pivots,
   "RemainingAmplitudeIndices"->free,"IndependentEquationCount"->r,
   "OriginalAmplitudeCount"->n,"RemainingAmplitudeCount"->Length[free],
   "GenericRankWitness"->witness,"SourceEquations"->relations|>
],"BoundaryIntegration"];

FeynFacet`ReduceBoundaryAmplitudeSystem::usage="ReduceBoundaryAmplitudeSystem[problem] eliminates exact amplitude equations with primitive unit pivots after scaling by the specified Laurent lower bounds. It retains the exact RHS transformation and all compatibility conditions.";
FeynFacet`ReduceBoundaryAmplitudeSystem[problem_Association] := Catch[Module[
 {eps=problem["DimensionalRegulator"],q=Normal[problem["CoefficientMatrix"]],
  rhs=Normal[problem["RightHandSideMatrix"]],bounds=problem["AmplitudeLaurentLowerBounds"],
  inputBounds=problem["BoundaryInputLaurentLowerBounds"],m,n,betaCount,original,mat,transform,
  rank=0,pivots={},free,candidates,choice,row,col,val,pivot,factor,swap,
  v,constant,homogeneous,zeroRows,regularity,valuation,clean,priorities},
 {m,n}=Dimensions[q];betaCount=If[m===0,0,Length[First[rhs]]];
 If[m<1||Length[bounds]=!=n||!VectorQ[bounds,IntegerQ]||Dimensions[rhs]=!={m,betaCount}||
   Length[inputBounds]=!=betaCount||!VectorQ[inputBounds,IntegerQ],
   boundaryIntegrationFail["BoundedAmplitudeSystemInputInvalid"]];
 clean[x_]:=Cancel[Together[x]];
 valuation[x_]:=If[x===0,Infinity,With[{nd=NumeratorDenominator[clean[x]]},
   If[!AllTrue[nd,PolynomialQ[#,eps]&],boundaryIntegrationFail["RationalAmplitudeCoefficientRequired"]];
   Exponent[nd[[1]],eps,Min]-Exponent[nd[[2]],eps,Min]]];
 original=Map[clean,q.DiagonalMatrix[eps^bounds],{2}];mat=original;
 transform=IdentityMatrix[m];free=Range[n];
 priorities=Lookup[problem,"PivotColumnPriorities",Range[n]];
 If[Length[priorities]=!=n,boundaryIntegrationFail["AmplitudePivotPrioritiesInvalid"]];
 While[rank<Min[m,n],
  Do[val=Min[valuation/@mat[[i]]];
   If[val===Infinity,Continue[]];
   mat[[i]]=clean[# eps^-val]&/@mat[[i]];
   transform[[i]]=clean[# eps^-val]&/@transform[[i]],
  {i,rank+1,m}];
  candidates=Flatten[Table[If[valuation[mat[[i,j]]]===0,{{i,j}},{}],
    {i,rank+1,m},{j,free}],2];
  If[candidates==={},Break[]];
  choice=First[SortBy[candidates,{priorities[[#[[2]]]],LeafCount[mat[[Sequence@@#]]]}&]];
  {row,col}=choice;rank++;
  If[row=!=rank,
    swap=mat[[rank]];mat[[rank]]=mat[[row]];mat[[row]]=swap;
    swap=transform[[rank]];transform[[rank]]=transform[[row]];transform[[row]]=swap];
  pivot=mat[[rank,col]];
  mat[[rank]]=clean[#/pivot]&/@mat[[rank]];
  transform[[rank]]=clean[#/pivot]&/@transform[[rank]];
  Do[If[i===rank||mat[[i,col]]===0,Continue[]];
   factor=mat[[i,col]];
   mat[[i]]=clean/@(mat[[i]]-factor mat[[rank]]);
   transform[[i]]=clean/@(transform[[i]]-factor transform[[rank]]),
  {i,m}];
  AppendTo[pivots,col];free=DeleteCases[free,col]];
 v=Map[clean,transform.rhs,{2}];
 If[!AllTrue[Flatten[Map[clean,transform.original-mat,{2}]],#===0&]||
   (rank>0&&mat[[Range[rank],pivots]]=!=IdentityMatrix[rank])||
   !AllTrue[Flatten[mat[[rank+1;;m]]],#===0&]||
   AnyTrue[Flatten[mat],valuation[#]<0&],
   boundaryIntegrationFail["PrimitiveAmplitudeEliminationResidualFailed"]];
 constant=ConstantArray[0,{n,betaCount}];homogeneous=ConstantArray[0,{n,Length[free]}];
 Do[constant[[pivots[[i]]]]=clean[eps^bounds[[pivots[[i]]]]#]&/@v[[i]];
   homogeneous[[pivots[[i]]]]=clean[-eps^bounds[[pivots[[i]]]]#]&/@mat[[i,free]],
 {i,rank}];
 Do[homogeneous[[free[[j]],j]]=eps^bounds[[free[[j]]]],{j,Length[free]}];
 If[!AllTrue[Flatten[Map[clean,q.homogeneous,{2}]],#===0&]||
   !And@@Flatten[Table[valuation[homogeneous[[i,j]]]>=bounds[[i]],{i,n},{j,Length[free]}]],
   boundaryIntegrationFail["AmplitudeLaurentBoundsNotPreserved"]];
 regularity=Table[<|"Row"->i,"RightHandSideCoefficients"->v[[i]],
   "LaurentLowerBoundFromInputs"->Min[(valuation/@v[[i]])+inputBounds],
   "AutomaticFromInputBounds"->TrueQ[Min[(valuation/@v[[i]])+inputBounds]>=0]|>,{i,rank}];
 <|"DataType"->"BoundedBoundaryAmplitudeReduction","DimensionalRegulator"->eps,
  "BoundaryInputMatrix"->constant,"FreeAmplitudeMatrix"->homogeneous,
  "AmplitudeLaurentLowerBounds"->bounds,"BoundaryInputLaurentLowerBounds"->inputBounds,
  "FreeAmplitudeOriginalIndices"->free,"FreeAmplitudeLaurentLowerBounds"->ConstantArray[0,Length[free]],
  "SolvedAmplitudeIndices"->pivots,"ExactRowTransformation"->transform,
  "TransformedCoefficientMatrix"->mat,"TransformedRightHandSideMatrix"->v,
  "RightHandSideRegularityConditions"->regularity,
  "ZeroRowRightHandSideConditions"->v[[rank+1;;m]],
  "IndependentEquationCount"->rank,"OriginalUnknownAmplitudeCount"->n,
  "RemainingUnknownAmplitudeCount"->Length[free],"SourceProblem"->problem,
  "ParticularSolutionCompatibility"->If[AllTrue[regularity,TrueQ[#["AutomaticFromInputBounds"]]&]&&
    AllTrue[Flatten[v[[rank+1;;m]]],#===0&],"AutomaticFromInputBounds","RequiresBoundaryCoefficientChecks"]|>
],"BoundaryIntegration"];

End[];
