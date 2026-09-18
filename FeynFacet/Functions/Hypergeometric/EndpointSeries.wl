(* Local Gauss series retain epsilon before the measured endpoint limit.
   Resonant connection formula: DLMF 15.8.10 and 15.8.12. *)
BeginPackage["FeynFacet`"];
GaussEndpointSingularTerms::usage="GaussEndpointSingularTerms[expression,{z,endpoint},epsilon,assumptions] computes every nonintegrable power/log term at endpoint 0 or 1 before epsilon expansion. Supports linear Gauss combinations with regulator-independent integer c-a-b and positive rational power prefactors. A finite local series certifies the remainder is locally integrable near epsilon=0; worse-than-simple endpoint powers are retained, never discarded.";
Begin["`Private`"];
gaussEndpointPolynomial[a_,b_,c_,x_,log_,point_,n_Integer]:=Module[{m=Cancel[c-a-b],aa=a,bb=b,shift=0,p=0},
 If[point===0,Return[Sum[Pochhammer[a,k]Pochhammer[b,k]/(k! Pochhammer[c,k])x^k,{k,0,Max[0,n]}]]];
 If[!IntegerQ[m],Throw[Failure["IntegerGaussEndpointDifferenceRequired",<|"Difference"->m|>],"GaussEndpoint"]];
 If[m<0,shift=m;aa=c-a;bb=c-b;m=-m];
 If[n-shift<0,Return[0]];
 If[m>0,p=Gamma[c]/(Gamma[aa+m]Gamma[bb+m])Sum[
   Pochhammer[aa,k]Pochhammer[bb,k](m-k-1)!/k! (-x)^k,{k,0,Min[m-1,n-shift]}]];
 If[n-shift>=m,p-=(-1)^m Gamma[c]/(Gamma[aa]Gamma[bb])x^m Sum[
  Pochhammer[aa+m,k]Pochhammer[bb+m,k]/(k!(k+m)!)x^k*
  (log-PolyGamma[0,k+1]-PolyGamma[0,k+m+1]+PolyGamma[0,aa+k+m]+PolyGamma[0,bb+k+m]),
  {k,0,n-shift-m}]];
 x^shift p
];
GaussEndpointSingularTerms[expression_,{z_Symbol,point:(0|1)},e_Symbol,assumptions_:True]:=Catch[Module[
 {x=Unique["endpointDistance$"],ll=Unique["endpointLog$"],objects,aliases,poly,coefficients,rows={},
  coefficient,powers,powerRules,beta,base,exponent,num,den,valuation,unit,rest,temporary,unitAliases,
  rational,lower,m=0,gauss,series,nmax,termRows,combined,answer,conditions,endpointCondition},
 objects=DeleteDuplicates[Cases[expression,_Hypergeometric2F1,{0,Infinity}]];
 If[!FreeQ[expression,_Hypergeometric2F1Regularized],Throw[Failure["UnregularizedGaussBasisRequired",<||>],"GaussEndpoint"]];
 If[!AllTrue[objects,#[[4]]===z&&FreeQ[Take[List@@#,3],z]&],
  Throw[Failure["UntransformedGaussArgumentRequired",<||>],"GaussEndpoint"]];
 aliases=Unique["endpointGauss$"]&/@objects;
 poly=FeynFacet`PolynomialCoefficientRules[expression/.Thread[objects->aliases],aliases];
 If[!ListQ[poly]||!AllTrue[First/@poly,Total[#]<=1&],Throw[Failure["LinearEndpointGaussCombinationRequired",<||>],"GaussEndpoint"]];
 conditions=(assumptions/.z->If[point===0,x,1-x])&&0<x<1;
 Do[
  coefficient=Last[row]/.z->If[point===0,x,1-x];beta=0;
  powers=DeleteDuplicates[Cases[coefficient,Power[b_,a_]/;!FreeQ[b,x]&&!IntegerQ[a],{0,Infinity}]];
  powerRules=Table[
   {base,exponent}=List@@power;{num,den}=NumeratorDenominator[Together[base]];
   If[!PolynomialQ[num,x]||!PolynomialQ[den,x],Throw[Failure["RationalEndpointPowerBaseRequired",<||>],"GaussEndpoint"]];
   valuation=Exponent[num,x,Min]-Exponent[den,x,Min];unit=Cancel[base/x^valuation];
   If[!TrueQ[FullSimplify[base>0&&unit>0,Assumptions->conditions]],
    Throw[Failure["PositiveEndpointPowerBranchRequired",<|"Base"->base|>],"GaussEndpoint"]];
   beta+=valuation exponent;power->unit^exponent,{power,powers}];
  rest=coefficient/.powerRules;
  If[!PolynomialQ[beta,e]||Exponent[beta,e]>1||!IntegerQ[beta/.e->0],
   Throw[Failure["IntegerAffineRegulatorEndpointPowerRequired",<|"Power"->beta|>],"GaussEndpoint"]];
  temporary=DeleteDuplicates[Cases[rest,Power[b_,a_]/;!FreeQ[b,x]&&!IntegerQ[a],{0,Infinity}]];
  unitAliases=Unique["endpointUnit$"]&/@temporary;
  rational=Together[rest/.Thread[temporary->unitAliases]];
  {num,den}=NumeratorDenominator[rational];
  If[!PolynomialQ[num,x]||!PolynomialQ[den,x],Throw[Failure["MeromorphicEndpointPrefactorRequired",<||>],"GaussEndpoint"]];
  lower=Exponent[num,x,Min]-Exponent[den,x,Min];nmax=-1-(beta/.e->0);
  gauss=If[Total[First[row]]===0,1,
   With[{obj=objects[[First@FirstPosition[First[row],1]]]},
    gaussEndpointPolynomial[obj[[1]],obj[[2]],obj[[3]],x,ll,point,nmax-lower]]];
  series=Expand[Normal[Series[rest gauss,{x,0,nmax}]]];
  If[!FreeQ[series,_Series|_SeriesData|Indeterminate|_DirectedInfinity],
   Throw[Failure["ExplicitGaussEndpointSeriesRequired",<|"Series"->series|>],"GaussEndpoint"]];
  If[series=!=0,
   valuation=Exponent[series,x,Min];
   termRows=CoefficientRules[Expand[series x^-valuation],{x,ll}];
   Do[AppendTo[rows,{Expand[beta+valuation+part[[1,1]]],part[[1,2]]}->part[[2]]],{part,termRows}]],
 {row,poly}];
 combined=Merge[Association/@({#}&/@rows),Total];
 combined=Map[FullSimplify[FunctionExpand[#],Assumptions->assumptions]&,combined];
 combined=Select[combined,#=!=0&];
 answer=KeyValueMap[<|"Power"->First[#1],"LogPower"->Last[#1],"Coefficient"->#2|>&,combined];
 <|"Variable"->z,"Endpoint"->point,"DimensionalRegulator"->e,"Terms"->answer,
  "RemainderLocallyIntegrable"->True,"MaxContactDerivativeOrder"->If[answer==={},0,
   Max[0,Max[-1-(#["Power"]/.e->0)&/@answer]]],
  "Method"->"Gauss Taylor series and resonant connection formula before epsilon expansion"|>
],"GaussEndpoint"];
End[];EndPackage[];
