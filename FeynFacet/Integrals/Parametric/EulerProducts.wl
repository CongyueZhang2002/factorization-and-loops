(* Structured Euler terms from products of positive rational factors. *)
Begin["FeynFacet`Private`"];
positiveRationalEulerTerm[variables_,factors_,constant_] := Module[
 {pref=constant,endpoint=ConstantArray[0,Length[variables]],
 upper=ConstantArray[0,Length[variables]],polynomials=<||>,nd,items,scalar,p,integer,sgn,exponent,j},
 Do[
  exponent=item[[2]];If[exponent===0,Continue[]];
  nd=NumeratorDenominator[Cancel[Together[item[[1]]]]];
  items=Join[FactorList[nd[[1]]],({First[#],-Last[#]}&/@FactorList[nd[[2]]])];
  scalar=1;
  Do[
   {p,integer}=factor;
   If[FreeQ[p,Alternatives@@variables],scalar*=p^integer;Continue[]];
   sgn=Sign[p/.Thread[variables->1/2]];
   If[!MemberQ[{1,-1},sgn],boundaryIntegrationFail["PositiveRationalFactorOrientationFailed"]];
   p=Expand[sgn p];scalar*=sgn^integer;
   j=SelectFirst[Range[Length[variables]],p===variables[[#]]&,None];
   If[j=!=None,endpoint[[j]]+=integer exponent;Continue[]];
   j=SelectFirst[Range[Length[variables]],Cancel[p-(1-variables[[#]])]===0&,None];
   If[j=!=None,upper[[j]]+=integer exponent;Continue[]];
   AssociateTo[polynomials,p->(Lookup[polynomials,Key[p],0]+integer exponent)],
  {factor,items}];
  If[!TrueQ[scalar>0],boundaryIntegrationFail["PositiveRationalProductConstantRequired"]];
  pref*=scalar^exponent,
 {item,factors}];
 <|"IntegrationVariables"->variables,"Prefactor"->pref,
 "EndpointPowers"->(Cancel/@endpoint),"UpperEndpointPowers"->(Cancel/@upper),
 "RegularFactor"->1,
 "PolynomialFactors"->KeyValueMap[<|"Polynomial"->#1,"Exponent"->Cancel[#2]|>&,Select[polynomials,Cancel[#]=!=0&]]|>
];


End[];
