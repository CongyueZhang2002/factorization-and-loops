(* Finite linear combinations of explicitly expanded Gauss functions.
   Actual coefficient poles determine the order required from each function. *)
BeginPackage["FeynFacet`"];
ExpandGaussHypergeometricCombinations::usage="ExpandGaussHypergeometricCombinations[values,epsilon,range] expands a named linear combination of supported Gauss functions and meromorphic prefactors, with sufficient per-function orders and the common omitted-tail audit.";
Begin["`Private`"];
ExpandGaussHypergeometricCombinations[values_Association,e_Symbol,range:{_Integer,_Integer}]:=
 Catch[Module[{labels=Keys[values],objects,aliases,polynomials,n,m,coefficients,lower,upper,
  needed,functions=<||>,vector,matrix,result,expanded,entry},
 If[values===<||>||First[range]>Last[range],epsOrderFail["FiniteGaussCombinationRequestRequired"]];
 objects=DeleteDuplicates[Cases[Values[values],_Hypergeometric2F1,{0,Infinity}]];
 aliases=Unique["gaussFunction"]&/@objects;n=Length[labels];m=Length[objects]+1;
 polynomials=FeynFacet`PolynomialCoefficientRules[#/.Thread[objects->aliases],aliases]&/@Values[values];
 If[AnyTrue[polynomials,FailureQ]||!AllTrue[Flatten[First/@#&/@polynomials,1],Total[#]<=1&],
  epsOrderFail["LinearGaussFunctionCombinationRequired"]];
 coefficients=Table[Lookup[Association[polynomials[[i]]],
  Key[If[j===1,ConstantArray[0,m-1],UnitVector[m-1,j-1]]],0],{i,n},{j,m}];
 lower=Map[FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&,coefficients,{2}];
 If[!AllTrue[Flatten[lower],IntegerQ[#]||#===Infinity&],epsOrderFail["GaussCoefficientLaurentBoundsRequired"]];
 needed=Table[Max[0,Max[Table[If[lower[[i,j]]===Infinity,-Infinity,Last[range]-lower[[i,j]]],{i,n}]]],{j,m}];
 Do[
  expanded=If[j===1,Association@Table[k->If[k===0,1,0],{k,0,needed[[j]]}],
    FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[Take[List@@objects[[j-1]],3],objects[[j-1,4]],e,needed[[j]]]];
  If[!AssociationQ[expanded],epsOrderFail["SupportedExplicitGaussExpansionRequired",<|"Function"->objects[[j-1]],"Cause"->expanded|>]];
  KeyValueMap[AssociateTo[functions,{j,#1}->#2]&,expanded],
 {j,m}];
 matrix=FeynFacet`ExpandLaurentCoefficientMatrix[coefficients,e,ConstantArray[Last[range],m]];
 If[FailureQ[matrix],Throw[matrix,"EpsilonOrders"]];
 vector=<|"DimensionalRegulator"->e,"Dimension"->m,"Coefficients"->functions,
  "LaurentLowerBounds"->ConstantArray[0,m],"KnownThroughOrders"->needed,
  "ExactTails"->Prepend[ConstantArray[False,m-1],True]|>;
 result=FeynFacet`MultiplyLaurentCoefficientMatrix[matrix,vector,ConstantArray[range,n]];
 If[FailureQ[result],Throw[result,"EpsilonOrders"]];
 Join[result,<|"CoefficientRowLabels"->labels,"GaussFunctionBasis"->objects,
  "GaussFunctionUpperOrders"->Rest[needed],"CoefficientEntryLaurentLowerBounds"->lower|>]
],"EpsilonOrders"];
End[];EndPackage[];
