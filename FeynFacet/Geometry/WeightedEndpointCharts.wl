(* Positive real weighted blowup charts of the unit cube. *)
BeginPackage["FeynFacet`"];
ConstructWeightedEndpointCharts::usage="ConstructWeightedEndpointCharts[variables,weights,request] gives a complete positive-real sector cover of a unit cube. In chart j, x_j=r^w_j and x_i=r^w_i t_i. Absolute Jacobians, sector conditions, and original-variable maps are explicit; seams carry no assigned contact terms.";
WeightedEndpointTaylorIndices::usage="WeightedEndpointTaylorIndices[weights,order] lists all nonnegative Taylor multi-indices with weighted degree at most order.";

ConstructMonomialEndpointCharts::usage="ConstructMonomialEndpointCharts[variables,exponentMatrices,request] builds positive monomial charts and exactly verifies that their logarithmic cones cover the unit cube with disjoint interiors. Nonnegative integer matrices may include real ramification. Every signed and absolute Jacobian is explicit.";
Begin["`Private`"];
WeightedEndpointTaylorIndices[weights:{__Integer},order_Integer?NonNegative]/;AllTrue[weights,#>0&]:=
 SortBy[Select[Tuples[Range[0,Floor[order/#]]&/@weights],#.weights<=order&],{#.weights,#}&];
ConstructWeightedEndpointCharts[xs:{__Symbol},weights:{__Integer},request_Association:<||>]:=Module[
 {n=Length[xs],radial,angular,charts,others,images,variables,signed,absolute,sector,conditions},
 If[n<2||Length[weights]=!=n||!AllTrue[weights,#>0&]||!DuplicateFreeQ[xs],
  Return[Failure["PositiveWeightsAndDistinctEndpointVariablesRequired",<||>]]];
 radial=Lookup[request,"RadialVariable",Unique["radialDistance"]];
 angular=Lookup[request,"AngularVariables",Table[Table[Unique["ratioVariable"],{n-1}],{n}]];
 If[!MatchQ[radial,_Symbol]||!MatrixQ[angular,MatchQ[#,_Symbol]&]||Dimensions[angular]=!={n,n-1}||
   !DuplicateFreeQ[Join[xs,{radial},Flatten[angular]]],
  Return[Failure["DistinctWeightedChartCoordinatesRequired",<||>]]];
 charts=Table[
  others=DeleteCases[Range[n],j];variables=Prepend[angular[[j]],radial];
  images=radial^#&/@weights;
  Do[images[[others[[i]]]]*=angular[[j,i]],{i,n-1}];
  signed=Factor[Det[Table[D[image,v],{image,images},{v,variables}]]];
  absolute=weights[[j]]radial^(Total[weights]-1);
  If[Factor[signed-(-1)^(j-1)absolute]=!=0,
   Return[Failure["WeightedChartJacobianMismatch",<||>],Module]];
  sector=And@@Table[xs[[i]]^weights[[j]]<=xs[[j]]^weights[[i]],{i,others}];
  conditions=And@@(0<#<1&/@variables);
  <|"Format"->"FeynFacet-WeightedEndpointChart","OriginalVariables"->xs,"Weights"->weights,
   "AnchorIndex"->j,"AngularOriginalIndices"->others,"Variables"->variables,
   "ExponentMatrix"->Table[Exponent[images[[i]],variables[[k]]],{i,n},{k,n}],
   "RadialVariable"->radial,"AngularVariables"->angular[[j]],
   "SourceVariableSubstitution"->Thread[xs->images],
   "SignedJacobian"->signed,"AbsoluteJacobian"->absolute,
   "SectorConditions"->sector,"OpenChartConditions"->conditions,
   "RadialBoundary"->"The original joint corner.",
   "AngularZeroFaces"->Thread[angular[[j]]->xs[[others]]],
   "CoverArgument"->"Choose a coordinate with maximal x_i^(1/w_i). Distinct maxima give disjoint interiors; equal maxima are measure-zero seams in the common convergence domain."|>,
 {j,n}];
 <|"Format"->"FeynFacet-WeightedEndpointCharts","OriginalVariables"->xs,"Weights"->weights,
  "Charts"->charts,"Coverage"->"The positive unit cube, with seams counted only once.",
  "DistributionConvention"->"Pull back the density and the whole test function in a common convergence domain before continuation."|>
];

ConstructMonomialEndpointCharts[xs:{__Symbol},matrices:{__List},request_Association:<||>]:=Module[
 {n=Length[xs],coordinates,logVariables,cones,positive,cover,disjoint,chart,images,jacobian,signed,absolute,charts,proof},
 If[n<2||!DuplicateFreeQ[xs]||!AllTrue[matrices,
  Dimensions[#]==={n,n}&&MatrixQ[#,IntegerQ[#]&&#>=0&]&&Det[#]=!=0&],
  Return[Failure["NonsingularNonnegativeIntegerChartMatricesRequired",<||>]]];
 coordinates=Lookup[request,"ChartVariables",Table[Table[Unique["endpointCoordinate"],{n}],{Length[matrices]}]];
 If[!MatrixQ[coordinates,MatchQ[#,_Symbol]&]||Dimensions[coordinates]=!={Length[matrices],n}||
   !AllTrue[coordinates,DuplicateFreeQ[Join[xs,#]]&],
  Return[Failure["DistinctMonomialChartCoordinatesRequired",<||>]]];
 logVariables=Table[Unique["logarithmicCoordinate"],{n}];
 cones=Table[And@@Thread[Inverse[m].logVariables>=0],{m,matrices}];
 positive=And@@Thread[logVariables>=0];
 cover=With[{vv=logVariables,condition=Implies[positive,Or@@cones]},
   Resolve[ForAll[vv,condition],Reals]];
 disjoint=And@@Flatten[Table[
  With[{vv=logVariables,condition=And@@Thread[logVariables>0]&&
    And@@Thread[Inverse[matrices[[i]]].logVariables>0]&&
    And@@Thread[Inverse[matrices[[j]]].logVariables>0]},
   Resolve[Exists[vv,condition],Reals]===False],
 {i,Length[matrices]},{j,i+1,Length[matrices]}]];
 If[cover=!=True||!TrueQ[disjoint],Return[Failure["MonomialChartConesDoNotPartitionThePositiveOrthant",<||>]]];
 charts=Table[
  images=Times@@MapThread[Power,{coordinates[[j]],#}]&/@matrices[[j]];
  signed=Factor[Det[Table[D[image,v],{image,images},{v,coordinates[[j]]}]]];
  absolute=Abs[Det[matrices[[j]]]]Times@@MapThread[Power,{coordinates[[j]],Total[matrices[[j]]]-1}];
  If[Factor[signed/absolute]=!=Sign[Det[matrices[[j]]]],
   Return[Failure["MonomialChartJacobianMismatch",<||>],Module]];
  <|"Format"->"FeynFacet-MonomialEndpointChart","OriginalVariables"->xs,
   "Variables"->coordinates[[j]],"ExponentMatrix"->matrices[[j]],
   "SourceVariableSubstitution"->Thread[xs->images],
   "InverseVariableSubstitution"->Thread[coordinates[[j]]->
     (Times@@MapThread[Power,{xs,#}]&/@Inverse[matrices[[j]]])],
   "SignedJacobian"->signed,"AbsoluteJacobian"->absolute,
   "OpenChartConditions"->And@@(0<#<1&/@coordinates[[j]]),
   "LogarithmicConeMatrix"->Inverse[matrices[[j]]]|>,
 {j,Length[matrices]}];
 <|"Format"->"FeynFacet-MonomialEndpointCharts","OriginalVariables"->xs,"Charts"->charts,
  "CoverageVerified"->True,"DisjointInteriorsVerified"->True,
  "CoverArgument"->"Negative logarithms map the positive unit cube to the positive orthant. Exact linear real quantifier elimination verifies coverage by the matrix cones and excludes intersections of their interiors."|>
];
End[];EndPackage[];
