(* Structured Euler terms from products of positive rational factors. *)
BeginPackage["FeynFacet`"];
IntegrateUnivariateEulerProduct::usage="IntegrateUnivariateEulerProduct[rational,factors,{x,0,1},assumptions] integrates a rational numerator times powers of positive rational factors. Factoring preserves real positive branches. Endpoint powers and at most one further affine factor give explicit beta/Gauss functions by meromorphic continuation; unsupported geometry returns Failure.";
EndPackage[];
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


FeynFacet`IntegrateUnivariateEulerProduct[rational_,factors_List,{x_Symbol,0,1},assumptions_:True]:=
 Catch[Module[{r,den,num,pref=1,lo=0,hi=0,regular=<||>,factorize,insert,items,
  a,b,rows,argument,power,value,conditions,lower,upper,t},
 conditions=assumptions&&0<x<1;
 insert[polynomial_,exponent_]:=Module[{p=Expand[polynomial],c,arg,sign},
  If[exponent===0,Return[Null]];
  If[FreeQ[p,x],
   If[!IntegerQ[exponent]&&!TrueQ[FullSimplify[p>0,Assumptions->assumptions]],
    Throw[Failure["PositiveExternalEulerFactorRequired",<|"Factor"->p|>]]];
   pref*=p^exponent;Return[Null]];
  If[!PolynomialQ[p,x]||Exponent[p,x]=!=1,
   Throw[Failure["AffineUnivariateEulerFactorsRequired",<|"Factor"->p|>]]];
  If[(p/.x->0)===0,
   c=Coefficient[p,x];
   If[!IntegerQ[exponent]&&!TrueQ[FullSimplify[c>0,Assumptions->assumptions]],
    Throw[Failure["PositiveEndpointEulerCoefficientRequired",<||>]]];
   pref*=c^exponent;lo+=exponent;Return[Null]];
  c=p/.x->0;arg=Cancel[-Coefficient[p,x]/c];
  If[!IntegerQ[exponent]&&!TrueQ[FullSimplify[c>0&&1-arg x>0,Assumptions->conditions]],
   Throw[Failure["PositiveAffineEulerFactorRequired",<|"Factor"->p|>]]];
  pref*=c^exponent;
  If[arg===1,hi+=exponent,
   AssociateTo[regular,arg->(Lookup[regular,Key[arg],0]+exponent)]]
 ];
 factorize[expression_,exponent_]:=Module[{nd,ff,constant=1,p,n,oriented},
  nd=NumeratorDenominator[Cancel[Together[expression]]];
  ff=Join[FactorList[First[nd]],({First[#],-Last[#]}&/@FactorList[Last[nd]])];
  Do[{p,n}=entry;
   If[FreeQ[p,x],constant*=p^n;Continue[]];
   If[IntegerQ[exponent],insert[p,n exponent],
    oriented=Which[TrueQ[FullSimplify[p>0,Assumptions->conditions]],p,
     TrueQ[FullSimplify[p<0,Assumptions->conditions]],constant*=(-1)^n;-p,
     True,Throw[Failure["FixedSignEulerFactorRequired",<|"Factor"->p|>]]];
    insert[oriented,n exponent]],{entry,ff}];
  insert[constant,exponent]
 ];
 If[!AllTrue[factors,MatchQ[#,{_,_}]&]||!FreeQ[{rational,factors},_Real|_Failure|_Missing],
  Throw[Failure["ExactRationalEulerProductRequired",<||>]]];
 r=Cancel[Together[rational]];If[r===0,Return[<|"Value"->0,"Method"->"ZeroEulerIntegrand"|>,Module]];
 num=Numerator[r];den=Denominator[r];
 If[!PolynomialQ[num,x],Throw[Failure["PolynomialEulerNumeratorRequired",<||>]]];
 lower=Exponent[num,x,Min];t=Unique["upperEulerCoordinate$"];
 upper=Exponent[Expand[num/.x->1-t],t,Min];
 If[!IntegerQ[lower]||!IntegerQ[upper],Throw[Failure["NonzeroEulerNumeratorRequired",<||>]]];
 num=Cancel[num/(x^lower(1-x)^upper)];lo+=lower;hi+=upper;
 factorize[den,-1];Do[factorize[First[f],Last[f]],{f,factors}];
 regular=Select[regular,Cancel[#]=!=0&];
 If[Length[regular]>1,Throw[Failure["MoreThanOneNonendpointEulerFactor",<||>]]];
 rows=CoefficientRules[num,{x}];
 value=Total[Map[Function[row,a=1+lo+First[First[row]];b=1+hi;
   Last[row]Beta[a,b]If[regular===<||>,1,
    argument=First[Keys[regular]];power=First[Values[regular]];
    Hypergeometric2F1[-power,a,a+b,argument]]],rows]];
 <|"Value"->pref value,"Method"->"EulerBetaGaussIntegral",
  "EndpointPowers"->{lo,hi},"AdditionalFactors"->regular,
  "Definition"->"Positive-branch Euler integral on its convergence domain, continued meromorphically in the exponents."|>
 ]];

End[];
