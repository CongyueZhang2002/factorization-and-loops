(* Positive real weighted blowup charts of the unit cube. *)
BeginPackage["FeynFacet`"];
ConstructWeightedEndpointCharts::usage="ConstructWeightedEndpointCharts[variables,weights,request] gives a complete positive-real sector cover of a unit cube. In chart j, x_j=r^w_j and x_i=r^w_i t_i. Absolute Jacobians, sector conditions, and original-variable maps are explicit; seams carry no assigned contact terms.";
WeightedEndpointTaylorIndices::usage="WeightedEndpointTaylorIndices[weights,order] lists all nonnegative Taylor multi-indices with weighted degree at most order.";

ConstructMonomialEndpointCharts::usage="ConstructMonomialEndpointCharts[variables,exponentMatrices,request] builds positive monomial charts and exactly verifies that their logarithmic cones cover the unit cube with disjoint interiors. Nonnegative integer matrices may include real ramification. Every signed and absolute Jacobian is explicit.";
ConstructNewtonEndpointCharts::usage="ConstructNewtonEndpointCharts[variables,polynomials,request] constructs a complete two-variable monomial cover from the common Newton fan, with an exact regular subdivision and optional positive integer ramification. It proposes charts; actual unit factors, connection normalization and seam regularity must still be verified.";
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
(* The positive normal fan is only a candidate resolution. Coefficient
   signs and finite positive-ratio zeros are checked by the endpoint producer. *)
ConstructNewtonEndpointCharts[xs:{_Symbol,_Symbol},polynomials_List,request_Association:<||>]:=Module[
 {supports,rays={{1,0},{0,1}},weight,delta,pair,values,ordered,regular,refine,
  determinant,bezout,complement,middle,ramification,matrices,cover},
 If[polynomials==={}||!AllTrue[polynomials,PolynomialQ[#,xs]&],
  Return[Failure["EndpointPolynomialSupportsRequired",<||>]]];
 supports=DeleteDuplicates[(First/@CoefficientRules[#,xs])&/@polynomials];
 Do[
  Do[delta=pair[[1]]-pair[[2]];
   If[Times@@delta<0,
    weight=Abs[Reverse[delta]];weight=weight/Apply[GCD,weight];
    values=(#.weight)&/@support;
    If[pair[[1]].weight===Min[values]&&pair[[2]].weight===Min[values],AppendTo[rays,weight]]],
  {pair,Subsets[support,{2}]}],
 {support,supports}];
 ordered=SortBy[DeleteDuplicates[rays],If[First[#]===0,Infinity,Last[#]/First[#]]&];
 refine[u_,v_]:=Module[{determinant=Det[{u,v}],bezout,complement,middle},
  If[determinant===1,Return[{u,v}]];
  bezout=Last[ExtendedGCD@@u];complement={-bezout[[2]],bezout[[1]]};
  middle=complement+Ceiling[Det[{v,complement}]/determinant]u;
  If[Det[{u,middle}]=!=1||!TrueQ[0<Det[{middle,v}]<determinant],
   Return[Failure["NewtonFanRegularSubdivisionFailed",<||>]]];
  With[{tail=refine[middle,v]},If[FailureQ[tail],tail,Prepend[tail,u]]]
 ];
 regular={First[ordered]};
 Do[values=refine[ordered[[i]],ordered[[i+1]]];
  If[FailureQ[values],Return[values,Module]];
  regular=Join[regular,Rest[values]],{i,Length[ordered]-1}];
 ramification=Lookup[request,"Ramification",1];
 If[!IntegerQ[ramification]||ramification<1,Return[Failure["PositiveIntegerEndpointRamificationRequired",<||>]]];
 matrices=(ramification Transpose[#]&)/@Partition[regular,2,1];
 cover=FeynFacet`ConstructMonomialEndpointCharts[xs,matrices,KeyTake[request,{"ChartVariables"}]];
 If[FailureQ[cover],Return[cover]];
 Join[cover,<|"NewtonPolynomials"->polynomials,"NewtonSupportRays"->ordered,
  "RegularFanRays"->regular,"Ramification"->ramification,"ResolutionVerified"->False,
  "ResolutionScope"->"Exact complete candidate cover. Pulled-back factors, all retained seams, physical modes and uniform remainders require separate checks."|>]
];
End[];EndPackage[];
