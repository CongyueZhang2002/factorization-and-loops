(* Independent comparison of retained and regenerated common-format results.
   Reads and generation belong to the caller; every scalar entry is checked. *)
BeginPackage["FTCountertermComparison`"];
CompareResults::usage="CompareResults[retained,regenerated,request] compares every scalar distribution coefficient over the requested Laurent range and the exact physical conventions.";
Begin["`Private`"];
CompareResults[old_Association,new_Association,request_Association:<||>]:=Module[
 {range,fields,oldScalars,newScalars,keys,rules,conditions,seconds,checks,scalarCheck,value,oldConvention,newConvention,physicalBasis,canonicalLogs},
 range=Lookup[request,"EpsilonRange",{Min[old["LaurentLowerBound"],new["LaurentLowerBound"]],0}];
 If[FeynFacet`RequirePartonicEpsilonRange[old,range]=!=True||
  FeynFacet`RequirePartonicEpsilonRange[new,range]=!=True,
  Return[Failure["CompleteComparisonEpsilonRangeRequired",<|"Range"->range,
   "RetainedRange"->old["EpsilonRange"],"RegeneratedRange"->new["EpsilonRange"]|>]]];
 fields={"Order","Scale","Variables","DimensionalRegulator","DimensionalPrefactor","DensityConvention",
   "DistributionBasis","CurrentNormalization","StructureFunctions"};
 physicalBasis[basis_]:=If[KeyExistsQ[basis,"Axes"],
  Join[basis,<|"Axes"->(KeyDrop[#,"NormalVariable"]&/@basis["Axes"])|>],KeyDrop[basis,"NormalVariable"]];
 oldConvention=Join[KeyTake[old,fields],<|"DistributionBasis"->physicalBasis[old["DistributionBasis"]]|>];
 newConvention=Join[KeyTake[new,fields],<|"DistributionBasis"->physicalBasis[new["DistributionBasis"]]|>];
 If[oldConvention=!=newConvention,Return[Failure["CountertermComparisonConventionMismatch",<|
  "Retained"->oldConvention,"Regenerated"->newConvention|>]]];
 oldScalars=FeynFacet`PartonicScalarCoefficientRules[old];newScalars=FeynFacet`PartonicScalarCoefficientRules[new];
 If[!AssociationQ[oldScalars]||!AssociationQ[newScalars],Return[Failure["ExplicitScalarCountertermEntriesRequired",<||>]]];
 keys=Select[Union[Keys[oldScalars],Keys[newScalars]],First[range]<=First[#]<=Last[range]&];
 If[keys==={},Return[Failure["NonemptyCountertermComparisonRequired",<||>]]];
 rules=Lookup[request,"ParameterRules",{}];conditions=Lookup[request,"Assumptions",True];
 canonicalLogs[value_]:=value/.HoldPattern[Log[lnArgument:(_Integer?Positive|_Rational?Positive)]]:>
  Total[(Last[#]Log[First[#]]&)/@FactorInteger[lnArgument]];
 scalarCheck[key_]:=Module[{a=Lookup[oldScalars,Key[key],0],b=Lookup[newScalars,Key[key],0],difference},
  difference=TimeConstrained[
   Cancel[Together[TrigExpand[canonicalLogs[FeynFacet`ExpandPositiveLogarithms[(a-b)/.rules,conditions]]]]],
   Lookup[request,"SecondsPerCoefficient",30],$Aborted];
  <|"Coefficient"->key,"Passed"->TrueQ[difference===0],
    "RetainedExplicit"->KeyExistsQ[oldScalars,key],"RegeneratedExplicit"->KeyExistsQ[newScalars,key],
    "Residual"->If[TrueQ[difference===0],0,difference]|>];
 {seconds,checks}=AbsoluteTiming[scalarCheck/@keys];
 <|"Passed"->AllTrue[checks,TrueQ[#["Passed"]]&],"EpsilonRange"->range,
  "ScalarCoefficientsCompared"->Length[checks],"Checks"->checks,"Seconds"->seconds,
  "ParameterRules"->rules,"Assumptions"->conditions,
  "Method"->"Exact rational cancellation after positive-rational logarithm factorization, positive-variable logarithm identities, and trigonometric identities under declared assumptions",
  "Coverage"->"Every scalar delta, plus and regular entry in every requested epsilon coefficient; absent endpoint-basis entries denote zero only within an explicitly covered Laurent order."|>
];
CompareResults[___]:=Failure["TwoExplicitPartonicResultsRequired",<||>];
End[];EndPackage[];
