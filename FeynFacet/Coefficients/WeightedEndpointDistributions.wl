(* Exact contact pushforwards act on nonlinear test-function compositions. *)
BeginPackage["FeynFacet`"];
PushForwardRadialEndpointDerivative::usage="PushForwardRadialEndpointDerivative[chart,n,moments] pushes forward a radial delta derivative of order n. The density Jacobian must already be included in the angular weight. moments maps angular monomial multi-indices to evaluated moments. The result contains all original-coordinate delta derivatives of weighted degree n.";

PushForwardMonomialEndpointDerivatives::usage="PushForwardMonomialEndpointDerivatives[chart,normalOrders,moments] pushes forward normal delta derivatives whose coordinate face maps to the original joint corner. It uses the full monomial exponent matrix and evaluated tangential monomial moments; no sector delta is merely renamed.";
Begin["`Private`"];
PushForwardRadialEndpointDerivative[chart_Association,n_Integer?NonNegative,moments_Association]:=Module[
 {xs,weights,others,indices,required,coefficients,expression},
 If[Lookup[chart,"Format",None]=!="FeynFacet-WeightedEndpointChart",
  Return[Failure["VerifiedWeightedEndpointChartRequired",<||>]]];
 {xs,weights,others}=Lookup[chart,{"OriginalVariables","Weights","AngularOriginalIndices"}];
 indices=Select[FeynFacet`WeightedEndpointTaylorIndices[weights,n],#.weights===n&];
 required=DeleteDuplicates[#[[others]]&/@indices];
 If[!AllTrue[required,KeyExistsQ[moments,#]&]||
   !FreeQ[Lookup[moments,Key[#]]&/@required,_Integrate|_Inactive|_Missing|_Failure|_SeriesData],
  Return[Failure["EvaluatedAngularContactMomentsRequired",<|"RequiredMonomials"->required|>]]];
 coefficients=Association@Table[index->
   ((-1)^(n-Total[index])Factorial[n]/(Times@@(Factorial/@index)))*Lookup[moments,Key[index[[others]]]],
  {index,indices}];
 expression=Total[KeyValueMap[Function[{index,value},
  value (Times@@MapThread[FeynFacet`EndpointDeltaDerivative[#1,#2,1]&,{xs,index}])],coefficients]];
 <|"Format"->"FeynFacet-WeightedEndpointContactTerms","DeltaDerivativeCoefficients"->coefficients,
  "Expression"->expression,"OriginalVariables"->xs,"RadialDerivativeOrder"->n,
  "AngularMoments"->KeyTake[moments,required],"Convention"->"Delta derivatives act on the original smooth test function with their full signs."|>
];

PushForwardMonomialEndpointDerivatives[chart_Association,normalOrders_Association,moments_Association]:=Module[
 {xs,variables,matrix,normals,tangents,orders,weights,indices,required,coefficients,expression},
 If[!MemberQ[{"FeynFacet-MonomialEndpointChart","FeynFacet-WeightedEndpointChart"},Lookup[chart,"Format",None]],
  Return[Failure["VerifiedMonomialEndpointChartRequired",<||>]]];
 {xs,variables,matrix}=Lookup[chart,{"OriginalVariables","Variables","ExponentMatrix"}];
 If[normalOrders===<||>||!ContainsAll[variables,Keys[normalOrders]]||
   !AllTrue[Values[normalOrders],IntegerQ[#]&&#>=0&],
  Return[Failure["DeclaredNonnegativeNormalDerivativeOrdersRequired",<||>]]];
 normals=First@FirstPosition[variables,#]&/@Keys[normalOrders];tangents=Complement[Range[Length[variables]],normals];
 orders=Values[normalOrders];weights=Total[Transpose[matrix[[All,normals]]]];
 If[!AllTrue[weights,#>0&],Return[Failure["NormalFaceMustCollapseEveryOriginalCoordinate",<||>]]];
 indices=Select[FeynFacet`WeightedEndpointTaylorIndices[weights,Total[orders]],
   Transpose[matrix[[All,normals]]].#===orders&];
 required=If[tangents==={},If[indices==={},{},{{}}],
  DeleteDuplicates[(Transpose[matrix[[All,tangents]]].#)&/@indices]];
 If[!AllTrue[required,KeyExistsQ[moments,#]&]||
  !FreeQ[Lookup[moments,Key[#]]&/@required,_Integrate|_Inactive|_Missing|_Failure|_SeriesData],
  Return[Failure["EvaluatedAngularContactMomentsRequired",<|"RequiredMonomials"->required|>]]];
 coefficients=Association@Table[index->
   ((-1)^(Total[orders]-Total[index]) (Times@@(Factorial/@orders))/(Times@@(Factorial/@index)))*
    Lookup[moments,Key[If[tangents==={},{},Transpose[matrix[[All,tangents]]].index]]],
  {index,indices}];
 expression=Total[KeyValueMap[Function[{index,value},
   value (Times@@MapThread[FeynFacet`EndpointDeltaDerivative[#1,#2,1]&,{xs,index}])],coefficients]];
 <|"Format"->"FeynFacet-MonomialEndpointContactTerms","DeltaDerivativeCoefficients"->coefficients,
  "Expression"->expression,"OriginalVariables"->xs,"NormalDerivativeOrders"->normalOrders,
  "AngularMoments"->KeyTake[moments,required]|>
];
End[];EndPackage[];
