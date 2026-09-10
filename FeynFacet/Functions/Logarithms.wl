(* Positive real factors may be extracted from a principal logarithm
   without changing its branch. Unknown factors stay inside one logarithm. *)
BeginPackage["FeynFacet`"];
ExpandPositiveLogarithms::usage="ExpandPositiveLogarithms[expression,assumptions] extracts provably positive rational factors from logarithm arguments. Provably negative real factors contribute their exact integer sign to the retained argument. Unproved and complex factors remain inside the same principal logarithm.";
Begin["`Private`"];
ExpandPositiveLogarithms[expression_,assumptions_]:=Module[
 {logs,rules,expand,positive,negative},
 positive[value_]:=positive[value]=TrueQ[FullSimplify[value>0,Assumptions->assumptions]];
 negative[value_]:=negative[value]=TrueQ[FullSimplify[value<0,Assumptions->assumptions]];
 expand[argument_]:=Module[{rational,num,den,factors,remainder=1,pieces={},base,power},
  rational=Together[argument];
  num=Quiet[Check[FactorList[Numerator[rational]],$Failed]];
  den=Quiet[Check[FactorList[Denominator[rational]],$Failed]];
  If[!ListQ[num]||!ListQ[den],Return[Log[argument]]];
  factors=Join[num,({First[#],-Last[#]}&/@den)];
  Do[
   {base,power}=factor;
   If[!IntegerQ[power],Return[Log[argument],Module]];
   Which[
    base===1,Null,
    positive[base],AppendTo[pieces,power Log[base]],
    negative[base],remainder*=(-1)^power;AppendTo[pieces,power Log[-base]],
    True,remainder*=base^power],
  {factor,factors}];
  Total[pieces]+Log[Factor[remainder]]
 ];
 logs=DeleteDuplicates[Cases[expression,_Log,{0,Infinity}]];
 rules=(#->expand[First[#]])&/@logs;
 expression/.Dispatch[rules]
];
End[];EndPackage[];
