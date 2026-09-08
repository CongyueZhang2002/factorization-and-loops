(* Coefficient comparison shared by boundary and complete-integral validation.
   Requested coefficients, including known zeros, must be present explicitly. *)
FeynFacetSolution`CompareLaurentCoefficients::usage =
 "CompareLaurentCoefficients[computed,reference,orders,opts] compares every requested Laurent coefficient, reporting missing orders and numerical uncertainty separately.";
Options[FeynFacetSolution`CompareLaurentCoefficients] = {
 "AccuracyGoal"->18,"PrecisionGoal"->18,"WorkingPrecision"->60,
 "RealLetterPrescription"->1};
FeynFacetSolution`CompareLaurentCoefficients[a_Association,b_Association,
 orders_List,OptionsPattern[]] := Module[
 {ag=OptionValue["AccuracyGoal"],pg=OptionValue["PrecisionGoal"],wp=OptionValue["WorkingPrecision"],
 sign=OptionValue["RealLetterPrescription"],missingA,missingB,records={},x,y,u,t,ratio,k,status,evaluate},
 If[orders==={}||!VectorQ[orders,IntegerQ]||!DuplicateFreeQ[orders]||
   !IntegerQ[ag]||ag<1||!IntegerQ[pg]||pg<1||!IntegerQ[wp]||wp<Max[ag,pg]+10,
  Return[Failure["InvalidCoefficientComparisonRequest",<||>]]];
 missingA=Select[orders,!KeyExistsQ[a,#]&];missingB=Select[orders,!KeyExistsQ[b,#]&];
 evaluate[value_] := If[FreeQ[value,_FeynFacetSolution`G],N[value,wp],
  FeynFacetSolution`EvaluateGPLExpression[value,"WorkingPrecision"->wp,"RealLetterPrescription"->sign]];
 Do[
  If[MemberQ[Join[missingA,missingB],k],Continue[]];
  x=evaluate[a[k]];y=evaluate[b[k]];
  If[!NumberQ[x]||!NumberQ[y],
   AppendTo[records,<|"EpsilonOrder"->k,"Status"->"NotNumeric"|>];Continue[]];
  u=Total[numericAbsoluteUncertainty/@{x,y}];
  t=10^-ag+10^-pg Max[Abs[x],Abs[y]];ratio=(Abs[x-y]+u)/t;
  AppendTo[records,<|"EpsilonOrder"->k,"Computed"->x,"Reference"->y,
   "AbsoluteDifference"->Abs[x-y],"EstimatedNumericalUncertainty"->u,
   "ToleranceRatio"->ratio,"Nonzero"->(!TrueQ[x==0]||!TrueQ[y==0]),
   "Status"->If[TrueQ[ratio<=1],"Passed","Failed"]|>],{k,orders}];
 status=Which[AnyTrue[records,#["Status"]==="Failed"&],"Failed",
  missingA=!={}||missingB=!={}||AnyTrue[records,#["Status"]==="NotNumeric"&],"Incomplete",True,"Passed"];
 <|"Status"->status,"RequiredOrders"->orders,"MissingComputedOrders"->missingA,
  "MissingReferenceOrders"->missingB,"ComparedCoefficientCount"->Count[Lookup[records,"Status"],"Passed"|"Failed"],
  "PassedCoefficientCount"->Count[Lookup[records,"Status"],"Passed"],
  "NonzeroComparisonCount"->Count[Lookup[records,"Nonzero",False],True],
  "CoefficientComparisons"->records,"ErrorEstimateIsRigorousBound"->False|>
];
