(* Finite limits of explicit rational/logarithmic/polylogarithmic combinations.
   Expand only the small function basis; rational Laurent rows use FLINT. *)
BeginPackage["FeynFacet`"];
RegularAnalyticLimit::usage="RegularAnalyticLimit[expression,variable->location,assumptions] verifies both real one-sided limits by exact Laurent cancellation and returns the common explicit value. Genuine poles, jumps, unresolved functions and fractional series fail. No numerical fit or kinematic exclusion is used.";
Begin["`Private`"];
regularLimitFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"RegularLimit"];
regularOneSidedLimit[expression_,variable_,location_,assumptions_,direction_]:=Module[
 {normal=Unique["limitNormal$"],value,conditions,rational,restore,aliases,rows,coefficients,
  poles,depth,variables,jets,monomial,series,total=0,collected,principal,answer,lower},
 value=expression/.variable->location+direction normal;
 conditions=(assumptions/.variable->location+direction normal)&&normal>0;
 {rational,restore}=coefficientRationalFieldReduce[value];
 aliases=Intersection[First/@restore,DeleteDuplicates[Cases[rational,_Symbol,{0,Infinity}]]];
 rows=FeynFacet`PolynomialCoefficientRules[rational,aliases];
 If[FailureQ[rows],regularLimitFail["PolynomialAnalyticFunctionBasisRequired"]];
 If[rows==={},Return[<|"Value"->0,"PoleOrder"->0,"PrincipalPartsVerified"->True|>]];
 coefficients=FeynFacet`CancelRationalCoefficients[Last/@rows];
 If[!ListQ[coefficients],regularLimitFail["RationalLimitCoefficientsRequired"]];
 poles=Map[If[#===0,0,Exponent[Denominator[#],normal,Min]-Exponent[Numerator[#],normal,Min]]&,coefficients];
 If[!VectorQ[poles,IntegerQ],regularLimitFail["IntegerRationalLimitValuationsRequired"]];
 depth=Max[0,Max[poles]];
 variables=DeleteDuplicates[Cases[coefficients,_Symbol,{0,Infinity}]];
 jets=If[FreeQ[coefficients,normal],
   Association@Table[j->If[j===0,#,0],{j,-depth,0}]&/@coefficients,
   FeynFacet`RationalLaurentCoefficients[coefficients,variables,normal,{-depth,0}]];
 If[!ListQ[jets],regularLimitFail["ExplicitRationalLimitJetsRequired"]];
 Do[
  monomial=(Times@@MapThread[Power,{aliases,First[rows[[index]]]}])/.restore;
  monomial=Refine[monomial,conditions];
  series=TimeConstrained[Series[monomial,{normal,0,depth}],30,$Aborted];
  If[!FreeQ[series,$Aborted|_Series|Indeterminate|_DirectedInfinity]||
    Cases[series,_Derivative,{0,Infinity},Heads->True]=!={},
   regularLimitFail["ExplicitAnalyticFunctionJetsRequired",<|"Function"->monomial|>]];
  If[Head[series]===SeriesData,
   If[series[[6]]=!=1||series[[4]]<0||series[[5]]<=depth,
    regularLimitFail["NonnegativeIntegerFunctionJetsRequired"]],
   If[!PolynomialQ[series,normal]&&!FreeQ[series,normal],
    regularLimitFail["BoundedFunctionSeriesRequired"]]];
  total+=Total[KeyValueMap[#2 normal^#1&,jets[[index]]]]Normal[series],
 {index,Length[rows]}];
 total=Expand[total];
 collected=Association@Table[j->Coefficient[total,normal,j],{j,-depth,0}];
 collected=Map[First[cancelCoefficientRow[{#}]]&,collected];
 principal=KeyDrop[collected,{0}];
 If[!AllTrue[Values[principal],#===0&],regularLimitFail["NonzeroLimitPrincipalPart",<|"PrincipalParts"->principal|>]];
 answer=collected[0];
 If[!FreeQ[answer,normal|Indeterminate|_DirectedInfinity|_Series|_SeriesData|_Limit],
  regularLimitFail["FiniteExplicitLimitRequired"]];
 <|"Value"->answer,"PoleOrder"->depth,"PrincipalPartsVerified"->True|>
];
(* A returned limit can itself contain an apparent rational pole at an
   isolated tangential point. Discover linear, single-variable factors in
   its denominator; extend only undefined 0/0 specializations that pass
   the same two-sided proof. This supplies iterated limits, not a theorem
   of uniform joint convergence for an arbitrary input function. *)
regularLimitRationalPoints[value_,conditions_]:=Module[
 {reduced,restore,factors,variables,variable,location,rule,out=value,records={},test,derived},
 {reduced,restore}=coefficientRationalFieldReduce[value];
 factors=First/@Rest[FactorList[Denominator[Together[reduced]]]];
 Do[
  variables=Variables[factor];
  If[Length[variables]=!=1||!MatchQ[First[variables],_Symbol],Continue[]];
  variable=First[variables];
  If[FreeQ[conditions,variable]||Exponent[factor,variable]=!=1,Continue[]];
  location=Cancel[-Coefficient[factor,variable,0]/Coefficient[factor,variable,1]];
  If[!MatchQ[location,_Integer|_Rational],Continue[]];
  rule=variable->location;
  If[TrueQ[FullSimplify[conditions/.rule]===False],Continue[]];
  test=Quiet[out/.rule];
  If[FreeQ[test,Indeterminate],Continue[]];
  derived=FeynFacet`RegularAnalyticLimit[out,rule,conditions];
  If[FailureQ[derived],regularLimitFail["TangentialRemovableLimitNotVerified",<|"Limit"->rule,"Cause"->derived|>]];
  AppendTo[records,KeyDrop[derived,{"Value"}]];
  out=Piecewise[{{derived["Value"],variable==location}},out],
 {factor,factors}];
 <|"Value"->out,"AdditionalRemovablePoints"->records|>
];
RegularAnalyticLimit[expression_,Rule[variable_Symbol,location_],assumptions_]:=Catch[Module[
 {above,below,difference,conditions,completed},
 If[!FreeQ[location,variable]||!FreeQ[expression,_Real|_Integrate|_NIntegrate|_Inactive],
  regularLimitFail["ExactExplicitLimitInputRequired"]];
 conditions=assumptions/.variable->location;
 If[TrueQ[FullSimplify[conditions]===False],regularLimitFail["LimitLocusInDomainRequired"]];
 above=regularOneSidedLimit[expression,variable,location,assumptions,1];
 below=regularOneSidedLimit[expression,variable,location,assumptions,-1];
 difference=FeynFacet`ExpandPositiveLogarithms[above["Value"]-below["Value"],conditions];
 If[FailureQ[difference],regularLimitFail["LimitBranchComparisonRequired"]];
 difference=First[cancelCoefficientRow[{difference}]];
 If[difference=!=0,regularLimitFail["UnequalOneSidedLimits"]];
 completed=regularLimitRationalPoints[above["Value"],conditions];
 <|"Value"->completed["Value"],"AdditionalRemovablePoints"->completed["AdditionalRemovablePoints"],"Variable"->variable,"Location"->location,
  "Assumptions"->conditions,"Method"->"ExactTwoSidedLaurentCancellation",
  "PoleOrder"->Max[above["PoleOrder"],below["PoleOrder"]],"PrincipalPartsVerified"->True|>
],"RegularLimit"];
RegularAnalyticLimit[___]:=Failure["ExpressionVariableLocationAndAssumptionsRequired",<||>];
End[];EndPackage[];
