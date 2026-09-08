(* Debug checks of omitted Laurent coefficients. No order planner is called. *)
BeginPackage["FeynFacet`"];
EpsilonRemainder::usage="EpsilonRemainder[source][epsilon,x,...] denotes an arbitrary epsilon-analytic remainder coefficient function. Different sources are independent; repeated sources retain their identity.";
CheckEpsilonTruncation::usage="CheckEpsilonTruncation[calculation,inputs,epsilon,{low,high}] supplies calculation with an association of finite expressions plus independent analytic remainders, then checks the requested output coefficients. Each input has Expression, KnownThroughOrder, optional Variables and ExactInEpsilon. calculation is a Function; it must preserve remainders rather than silently truncate its intermediate expressions.";
WithEpsilonRemainderChecks::usage="WithEpsilonRemainderChecks[calculation] enables the instrumented stage 2/3/4 order checks and returns Result plus an audit report. A possible omitted-coefficient contribution stops the calculation. TruncationOrderShift->-1 is a deliberate fault injection for testing, not a production order setting.";
Begin["`Private`"];
$epsilonRemainderChecks=False;
epsilonRemainderSources[x_]:=DeleteDuplicates@Cases[x,EpsilonRemainder[id_]:>id,{0,Infinity},Heads->True];
Options[CheckEpsilonTruncation]={"TimeLimit"->10};
CheckEpsilonTruncation[calculation_Function,inputs_Association,e_Symbol,range:{_Integer,_Integer},OptionsPattern[]]:=
 TimeConstrained[Catch[Module[{marked,output,flat,reports={},s,polynomial,coefficient,sources,m,variables,expr},
  If[First[range]>Last[range]||inputs===<||>,Throw[Failure["EpsilonTruncationInputInvalid",<||>],"EpsilonTruncation"]];
  marked=Association@KeyValueMap[Function[{id,input},
   If[!AssociationQ[input]||!KeyExistsQ[input,"Expression"],Throw[Failure["FiniteEpsilonExpressionRequired",<|"Source"->id|>],"EpsilonTruncation"]];
   expr=input["Expression"];variables=Lookup[input,"Variables",{}];
   If[!FreeQ[expr,_SeriesData|_Series|_SeriesCoefficient|_EpsilonRemainder]||!MatchQ[variables,{___Symbol}]||MemberQ[variables,e],
    Throw[Failure["ExplicitEpsilonInputRequired",<|"Source"->id|>],"EpsilonTruncation"]];
   If[TrueQ[Lookup[input,"ExactInEpsilon",False]],id->expr,
    m=Lookup[input,"KnownThroughOrder",None];
    If[!IntegerQ[m],Throw[Failure["KnownEpsilonTruncationOrderRequired",<|"Source"->id|>],"EpsilonTruncation"]];
    expr=Normal[Series[expr,{e,0,m}]];
    id->If[ListQ[expr],MapIndexed[
      #1+e^(m+1) Apply[EpsilonRemainder[{id,#2}],Prepend[variables,e]]&,expr,{ArrayDepth[expr]}],
      expr+e^(m+1) Apply[EpsilonRemainder[id],Prepend[variables,e]]]]],inputs];
  output=calculation[marked];
  If[!FreeQ[output,_Failure|$Failed|$Aborted|Indeterminate|_DirectedInfinity|_Missing]||AssociationQ[output],
   Throw[Failure["ExplicitEpsilonOutputRequired",<||>],"EpsilonTruncation"]];
  flat=If[ListQ[output],Flatten[output],{output}];
  Do[
   s=Quiet[Check[Series[flat[[i]],{e,0,Last[range]}],$Failed]];
   If[s===$Failed||!FreeQ[s,_Series|Indeterminate|_DirectedInfinity|_Failure],
    Throw[Failure["EpsilonRemainderExpansionUnresolved",<|"OutputIndex"->i|>],"EpsilonTruncation"]];
   polynomial=Expand[Normal[s],e];
   Do[coefficient=Coefficient[polynomial,e,q];
    If[!FreeQ[coefficient,e|_SeriesData|_SeriesCoefficient],
     Throw[Failure["EpsilonRemainderCoefficientUnresolved",<|"OutputIndex"->i,"Order"->q|>],"EpsilonTruncation"]];
    sources=epsilonRemainderSources[coefficient];
    If[sources=!={},AppendTo[reports,<|"OutputIndex"->i,"EpsilonOrder"->q,
      "Sources"->sources,"Coefficient"->coefficient|>]],{q,First[range],Last[range]}],
  {i,Length[flat]}];
  <|"Status"->If[reports==={},"Passed","ContaminationDetected"],"RequestedOrderRange"->range,
    "ContaminatedCoefficients"->reports,"IndependentSources"->Keys[inputs],
    "Method"->"Arbitrary analytic remainder functions propagated through the supplied calculation; only the final output is projected in epsilon."|>
 ],"EpsilonTruncation"],OptionValue["TimeLimit"],Failure["EpsilonRemainderCheckTimeLimit",<||>]];
CheckEpsilonTruncation[___]:=Failure["EpsilonTruncationInputInvalid",<||>];

SetAttributes[WithEpsilonRemainderChecks,HoldAll];
Options[WithEpsilonRemainderChecks]={"TruncationOrderShift"->0,"TimeLimitPerCheck"->10};
WithEpsilonRemainderChecks[calculation_,OptionsPattern[]]:=Module[{result,report,shift=OptionValue["TruncationOrderShift"]},
 If[!IntegerQ[shift],Return[Failure["IntegerDebugTruncationShiftRequired",<||>]]];
 Block[{$epsilonRemainderChecks=True,$epsilonRemainderShift=shift,
   $epsilonRemainderTimeLimit=OptionValue["TimeLimitPerCheck"],$epsilonRemainderCounts=<||>,
   $epsilonRemainderFailures={},$epsilonMultiplierChecks=<||>,$epsilonMultiplierCacheHits=0},
  result=Catch[calculation,"EpsilonRemainderAudit"];
  report=<|"Status"->Which[$epsilonRemainderFailures=!={},"Failed",
     FailureQ[result]||result===$Failed||result===$Aborted,"CalculationFailed",
     Total[Values[$epsilonRemainderCounts]]===0,"NoChecksExecuted",True,"Passed"],
   "ChecksByStage"->$epsilonRemainderCounts,"FailedChecks"->$epsilonRemainderFailures,
   "DistinctMultiplierChecks"->Length[$epsilonMultiplierChecks],"RepeatedMultiplierChecksReused"->$epsilonMultiplierCacheHits,
   "TruncationOrderShift"->shift,
   "Method"->"Conservative forward propagation of labelled Laurent remainders at instrumented products; exact epsilon multipliers are checked by direct series expansion.",
   "Scope"->"Declared Laurent classes and instrumented operations. Not a proof of lower bounds, uniform endpoint limits, or undocumented truncations inside external programs."|>;
  <|"Result"->result,"EpsilonRemainderAudit"->report|>]
];
epsilonAuditRecord[stage_,failure_:None]:=(
 AssociateTo[$epsilonRemainderCounts,stage->(Lookup[$epsilonRemainderCounts,stage,0]+1)];
 If[failure=!=None,AppendTo[$epsilonRemainderFailures,Join[<|"Stage"->stage|>,failure]];
  Throw[Failure["InsufficientEpsilonOrdersDetected",Last[$epsilonRemainderFailures]],"EpsilonRemainderAudit"]]);

(* Scalar products of arbitrary Laurent series can be checked without
   constructing their kinematic coefficients. Unknown tails are intervals,
   so products of two or more unknown remainders are included as well.
   Exact cancellations are deliberately not assumed in this fast check. *)
SetAttributes[epsilonAuditProduct,HoldAll];
epsilonAuditProduct[factorSpecifications_,targetOrder_,stageName_,location_:None]:=
 If[TrueQ[$epsilonRemainderChecks],Module[{factors=factorSpecifications,target=targetOrder,
  stage=stageName,lower,tail,order,upper,leaks={},spec},
  If[target===-Infinity,Return[Null]];
  If[!IntegerQ[target]||!ListQ[factors]||factors==={},
   epsilonAuditRecord[stage,<|"Reason"->"InvalidDebugProduct","Location"->location|>]];
  lower=Lookup[factors,"LowerBound"];
  If[MemberQ[lower,Infinity],epsilonAuditRecord[stage];Return[Null]];
  If[!AllTrue[lower,IntegerQ[#]||#===Infinity&],
   epsilonAuditRecord[stage,<|"Reason"->"LaurentBoundsUnavailable","Location"->location|>]];
  Do[spec=factors[[i]];If[TrueQ[Lookup[spec,"Exact",False]],Continue[]];
   upper=Lookup[spec,"ThroughOrder",None];
   If[!IntegerQ[upper]&&upper=!=-Infinity,
    epsilonAuditRecord[stage,<|"Reason"->"TruncationOrderUnavailable","Location"->location|>]];
   tail=If[upper===-Infinity,lower[[i]],Max[lower[[i]],upper+$epsilonRemainderShift+1]];
   order=tail+Total[Delete[lower,i]];
   If[order<=target,AppendTo[leaks,<|"Source"->Lookup[spec,"Source",i],
    "KnownThroughOrder"->upper,"FirstOmittedOrder"->tail,"FirstPossibleOutputOrder"->order|>]],
  {i,Length[factors]}];
  epsilonAuditRecord[stage,If[leaks==={},None,<|"Location"->location,"RequestedThroughOrder"->target,
    "ContaminatingRemainders"->leaks|>]]]];

(* This check does not ask the planner for the multiplier's pole order. *)
SetAttributes[epsilonAuditMultiplier,HoldAll];
epsilonAuditMultiplier[multiplier_,e_,lower_,upper_,target_,stage_,source_]:=
 If[TrueQ[$epsilonRemainderChecks],Module[{m=multiplier,ep=e,lo=lower,hi=upper,k=target,tail,check,key},
  If[m===0||lo===Infinity||k===-Infinity,epsilonAuditRecord[stage];Return[Null]];
  If[!IntegerQ[lo]||(!IntegerQ[hi]&&hi=!=-Infinity)||!IntegerQ[k],
   epsilonAuditRecord[stage,<|"Reason"->"ExplicitRemainderOrdersRequired","Location"->source|>]];
  tail=If[hi===-Infinity,lo,Max[lo,hi+$epsilonRemainderShift+1]];
  key={m,ep,tail,k};
  If[TrueQ[Lookup[$epsilonMultiplierChecks,Key[key],False]],
   $epsilonMultiplierCacheHits++;epsilonAuditRecord[stage];Return[Null]];
  check=CheckEpsilonTruncation[Function[values,m values["omitted"]],
   <|"omitted"-><|"Expression"->0,"KnownThroughOrder"->tail-1|>|>,ep,{k,k},
   "TimeLimit"->$epsilonRemainderTimeLimit];
  If[AssociationQ[check]&&check["Status"]==="Passed",AssociateTo[$epsilonMultiplierChecks,key->True]];
  epsilonAuditRecord[stage,If[AssociationQ[check]&&check["Status"]==="Passed",None,
    <|"Location"->source,"KnownThroughOrder"->hi,"FirstOmittedOrder"->tail,
      "RequestedOrder"->k,"RemainderCheck"->check|>]]]];

epsilonAuditSeriesLower[coefficients_Association,through_] := Module[{support},
 support=Keys@Select[coefficients,#=!=0&];If[support==={},through+1,Min[support]]];
epsilonAuditSpec[source_,lower_,upper_,exact_:False]:=
 <|"Source"->source,"LowerBound"->lower,"ThroughOrder"->upper,"Exact"->exact|>;
epsilonAuditStoredSpec[record_Association,source_]:=Module[{cs=record["Coefficients"],upper,lower,exact},
 upper=Min[record["KnownThroughOrder"],If[cs===<||>,record["LaurentLowerBound"]-1,Max[Keys[cs]]]];
 exact=TrueQ[Lookup[record,"ExactInEpsilon",False]];
 lower=If[AllTrue[Values[cs],#===0&],If[exact,Infinity,Max[record["LaurentLowerBound"],upper+1]],
   Min[Keys@Select[cs,#=!=0&]]];
 epsilonAuditSpec[source,lower,upper,exact]
];
End[];
EndPackage[];
