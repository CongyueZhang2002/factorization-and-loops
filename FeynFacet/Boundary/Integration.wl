
(* Optional analytic integration of explicit Euler integrals. Physical cuts and
   their domains must already have been resolved by the representation layer. *)
Begin["FeynFacet`Private`"];
FeynFacet`IntegrateEulerBoundaryIntegral::usage="IntegrateEulerBoundaryIntegral[definition,{low,high},opts] evaluates a fully specified Euler boundary integral, retaining its normalization and regulator orders. It tries Gamma/Beta integration before SubTropica.";
boundaryIntegrationFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"BoundaryIntegration"];
boundaryTermExpression[term_] := Module[{xs=Lookup[term,"IntegrationVariables",{}],n},
 n=Length[xs];
 Lookup[term,"Prefactor",1] Lookup[term,"RegularFactor",1] *
  Times@@MapThread[#1^#2&,{xs,Lookup[term,"EndpointPowers",ConstantArray[0,n]]}] *
  Times@@MapThread[(1-#1)^#2&,{xs,Lookup[term,"UpperEndpointPowers",ConstantArray[0,n]]}] *
  Times@@MapThread[Log[#1]^#2&,{xs,Lookup[term,"LogPowers",ConstantArray[0,n]]}] *
  Times@@((#["Polynomial"]^#["Exponent"])&/@Lookup[term,"PolynomialFactors",{}])];
(* Remove one Beta measure only when the remaining factor is a polynomial.
   Simplification is performed inside the positive integration domain; no
   unrestricted PowerExpand is used. This includes polynomial moments. *)
boundaryBetaIntegrate[expression_,variables_,eps_] := Catch[Module[
 {value=expression,logDerivative,left,right,remainder,coefficients,next,x,assumptions},
 assumptions=Element[eps,Reals]&&And@@(0<#<1&/@variables);
 Do[
  x=variable;
  logDerivative=Quiet[Cancel[D[value,x]/value]];
  left=Quiet[Limit[x logDerivative,x->0,Direction->"FromAbove"]];
  right=Quiet[Limit[(x-1)logDerivative,x->1,Direction->"FromBelow"]];
  If[!FreeQ[{left,right},Alternatives@@variables]||
    !FreeQ[{left,right},_Limit|Indeterminate|_DirectedInfinity],Throw[None,"BoundaryBetaIntegration"]];
  remainder=TimeConstrained[FullSimplify[value/(x^left(1-x)^right),assumptions],10,None];
  If[remainder===None||!PolynomialQ[remainder,x],Throw[None,"BoundaryBetaIntegration"]];
  coefficients=CoefficientList[remainder,x];
  value=Sum[coefficients[[j]] Gamma[left+j] Gamma[right+1]/Gamma[left+right+j+1],
    {j,Length[coefficients]}],
 {variable,variables}];
 value
],"BoundaryBetaIntegration"];
Options[FeynFacet`IntegrateEulerBoundaryIntegral]={
 "IntegrationBackend"->Automatic,"SubTropicaPath"->Automatic,
 "ScratchDirectory"->Automatic,"TimeLimit"->1800,"Verbose"->False};
FeynFacet`IntegrateEulerBoundaryIntegral[definition_Association,range:{_Integer,_Integer},OptionsPattern[]] :=
 TimeConstrained[Catch[Module[
 {eps=Lookup[definition,"DimensionalRegulator",None],terms,values={},methods={},vars,expr,
 limits,value,backend=Replace[OptionValue["IntegrationBackend"],"Automatic"->Automatic],started=AbsoluteTime[],series,
 scratch=OptionValue["ScratchDirectory"],subpath=OptionValue["SubTropicaPath"],raw,remaining},
 If[!MatchQ[eps,_Symbol]||range[[1]]>range[[2]],
   boundaryIntegrationFail["BoundaryIntegralOrdersInvalid"]];
 If[Lookup[definition,"Representation",None]=!="UnitCube",
   boundaryIntegrationFail["ResolvedEulerDomainRequired",
    <|"Representation"->Lookup[definition,"Representation",None]|>]];
 If[backend===Automatic&&Lookup[definition,"DataType",None]==="BubbleDominatedDoubleCollinearBoundaryIntegral",
  value=FeynFacet`EvaluateClusterBoundaryIntegral[definition,range];
  If[AssociationQ[value],Return[value]]];
 terms=Lookup[definition,"Terms",None];
 If[!ListQ[terms]||!AllTrue[terms,AssociationQ],
   boundaryIntegrationFail["ExplicitEulerTermsRequired"]];
 Do[
  vars=Lookup[term,"IntegrationVariables",{}];expr=boundaryTermExpression[term];
  If[!VectorQ[vars,MatchQ[#,_Symbol]&]||!DuplicateFreeQ[vars]||
    !FreeQ[expr,DiracDelta|HeavisideTheta|UnitStep|_Inactive|_Integrate|_ConditionalExpression],
    boundaryIntegrationFail["UnresolvedCutOrDomainInEulerIntegrand"]];
  If[expr===0,value=0;AppendTo[methods,"Zero"],
   value=If[vars==={},expr,If[backend==="SubTropica",None,boundaryBetaIntegrate[expr,vars,eps]]];
   If[value=!=None,AppendTo[methods,If[vars==={},"ExplicitExpression","GammaBeta"]],
    If[backend==="GammaBeta",boundaryIntegrationFail["GammaBetaIntegrationNotApplicable"]];
    raw=integrateBoundaryWithSubTropica[expr,vars,eps,range[[2]],subpath,scratch,
      OptionValue["Verbose"]];
    If[FailureQ[raw],Throw[raw,"BoundaryIntegration"]];
    value=raw["Expression"];AppendTo[methods,raw["IntegrationBackend"]]]];
  If[!FreeQ[value,Alternatives@@vars],boundaryIntegrationFail["EulerIntegrationVariablesRemain"]];
  AppendTo[values,value],
 {term,terms}];
 series=Quiet[Series[Total[values],{eps,0,range[[2]]}]];
 If[!FreeQ[series,$Failed|$Aborted|_Series|Indeterminate|_DirectedInfinity],
   boundaryIntegrationFail["BoundaryLaurentExpansionFailed"]];
 <|"DataType"->"EvaluatedBoundaryIntegral","Status"->"AnalyticallyEvaluated",
   "IntegralDefinition"->definition,"DimensionalRegulator"->eps,"EpsilonOrderRange"->range,
   "LaurentCoefficients"->Association@Table[k->SeriesCoefficient[series,{eps,0,k}],
      {k,range[[1]],range[[2]]}],
   "AnalyticExpression"->If[FreeQ[values,_SeriesData],Total[values],Missing["LaurentSeriesOnly"]],
   "IntegrationMethods"->methods,"ElapsedSeconds"->AbsoluteTime[]-started,
   "NormalizationChanged"->False|>
],"BoundaryIntegration"],OptionValue["TimeLimit"],Failure["BoundaryIntegrationTimeLimit",<||>]];
End[];
