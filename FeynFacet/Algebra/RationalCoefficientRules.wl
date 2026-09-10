(* Sparse coefficient-field clearing. Large kinematic coefficients never
   enter the small rational cancellation in the selected variables. *)
BeginPackage["FeynFacet`"];
RationalCoefficientRules::usage=
 "RationalCoefficientRules[expressions,variables] returns one common polynomial denominator and sparse polynomial numerator coefficients for a list of rational functions in the selected variables. Other exact expressions form the coefficient field.";
CommonKinematicDenominator::usage="CommonKinematicDenominator[expressions,variables] constructs a sufficient common polynomial denominator without expanding scalar numerators. Parameters independent of the declared kinematic variables remain in the coefficient field.";
Begin["`Private`"];
RationalCoefficientRules[expressions_List,variables_List]:=Catch[Module[
 {poles,bases,aliases,rules,common,formal,polynomials,parameterRules,cache=<||>,rows,small,out},
 If[!MatchQ[variables,{_Symbol...}]||!DuplicateFreeQ[variables],
  Throw[Failure["DistinctCoefficientVariablesRequired",<||>],"RationalCoefficients"]];
 If[variables==={},Return[<|"Variables"->{},"CommonDenominator"->1,
  "NumeratorCoefficientRules"->({{}->#}&/@expressions)|>]];
 poles=DeleteDuplicates[Cases[expressions,
   Power[base_,power_Integer?Negative]/;!FreeQ[base,Alternatives@@variables]:>{base,-power},Infinity]];
 If[!AllTrue[First/@poles,PolynomialQ[#,variables]&],
  Throw[Failure["PolynomialCoefficientDenominatorsRequired",<||>],"RationalCoefficients"]];
 bases=DeleteDuplicates[First/@poles];aliases=Table[Unique["coefficientDenominator"],{Length[bases]}];
 rules=MapThread[With[{base=#1,alias=#2},HoldPattern[Power[base,power_Integer?Negative]]:>alias^-power]&,{bases,aliases}];
 common=Times@@KeyValueMap[#1^Max[#2]&,GroupBy[poles,First->Last]];
 formal=expressions/.rules;
 polynomials=FeynFacet`PolynomialCoefficientRules[#,Join[variables,aliases]]&/@formal;
 If[AnyTrue[polynomials,FailureQ],
  Throw[Failure["RationalCoefficientDependenceRequired",<||>],"RationalCoefficients"]];
 parameterRules[degrees_List]:=If[KeyExistsQ[cache,degrees],cache[[Key[degrees]]],
  small=Cancel[common Times@@(variables^Take[degrees,Length[variables]])/
    Times@@(bases^Drop[degrees,Length[variables]])];
  If[!PolynomialQ[small,variables],
   Throw[Failure["CoefficientDenominatorClearingFailed",<||>],"RationalCoefficients"]];
  small=CoefficientRules[small,variables];AssociateTo[cache,degrees->small];small];
 out=Table[
  rows=Flatten[Map[Function[row,Map[(First[#]->Last[row]Last[#])&,parameterRules[First[row]]]],polynomial],1];
  Normal[If[rows==={},<||>,Merge[rows,Total]]],
 {polynomial,polynomials}];
 <|"Variables"->variables,"CommonDenominator"->common,"NumeratorCoefficientRules"->out|>
],"RationalCoefficients"];

CommonKinematicDenominator[expressions_List,xs:{__Symbol}]:=Catch[Module[
 {denominators,visit,merge,powers,common},
 merge[records_,function_]:=If[records==={},<||>,Merge[records,function]];
 visit[value_]:=Which[
  FreeQ[value,Alternatives@@xs]||PolynomialQ[value,xs],<||>,
  Head[value]===Plus,merge[visit/@List@@value,Max],
  Head[value]===Times,merge[visit/@List@@value,Total],
  Head[value]===Power&&IntegerQ[value[[2]]]&&value[[2]]>0,
   value[[2]]#&/@visit[value[[1]]],
  Head[value]===Power&&IntegerQ[value[[2]]]&&value[[2]]<0,
   Module[{base=value[[1]],fraction,numerator,factors},
    fraction=If[PolynomialQ[base,xs],base,Cancel[Together[base]]];
    If[!PolynomialQ[Numerator[fraction],xs]||!PolynomialQ[Denominator[fraction],xs],
     Throw[Failure["RationalKinematicDenominatorRequired",<||>],"CommonDenominator"]];
    numerator=Numerator[fraction];
    If[FreeQ[numerator,Alternatives@@xs],<||>,
     factors=Select[Rest[FactorList[numerator]],!FreeQ[First[#],Alternatives@@xs]&];
     Association[(First[#]->(-value[[2]])Last[#])&/@factors]]],
  True,Throw[Failure["PolynomialKinematicCoefficientFieldRequired",<|"Expression"->value|>],"CommonDenominator"]];
 powers=merge[visit/@expressions,Max];
 common=Times@@KeyValueMap[#1^#2&,powers];
 <|"CommonDenominator"->common,"PolynomialDenominatorFactors"->powers,
  "Variables"->xs,"Method"->"Structural rational denominator clearing; products add pole multiplicities, sums take their maxima. Numerators are not expanded."|>
],"CommonDenominator"];

End[];EndPackage[];
