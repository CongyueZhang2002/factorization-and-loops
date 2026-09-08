BeginPackage["FeynFacet`"] ; Begin["`Private`"];
(* Finite contraction of explicit analytic Laurent values with reconstructed
   master coefficients. No integral evaluation is deferred to the reader. *)
FeynFacet`ContractAnalyticMasterCoefficients::usage="ContractAnalyticMasterCoefficients[table,values,request] contracts exact reconstructed coefficients with explicit master Laurent values through EpsilonOrderRange. Request supplies Normalization, per-master MeasureConversions and optional KinematicRules. It checks master coverage and finite-order sufficiency, and supports WithEpsilonRemainderChecks.";
FeynFacet`ContractAnalyticMasterCoefficients[table_Association,values_Association,request_Association]:=Catch[Module[
 {e,range,low,high,norm,rules,conversions,output,contributions={},entry,master,record,cs,mlow,mhigh,
  mult,converted,coefficients,needed,valuation,expr,one,exact,source,measure},
 If[!ContainsAll[Keys[request],{"EpsilonOrderRange","Normalization","MeasureConversions"}],
  epsOrderFail["AnalyticContractionRequestIncomplete"]];
 e=table["DimensionalRegulator"];range=request["EpsilonOrderRange"];
 If[!MatchQ[range,{_Integer,_Integer}]||First[range]>Last[range],epsOrderFail["FiniteEpsilonRangeRequired"]];
 {low,high}=range;norm=table["PreFactor"]request["Normalization"];
 rules=Lookup[request,"KinematicRules",{}];conversions=request["MeasureConversions"];
 If[Lookup[table,"RemainderTerms",{}]=!={},epsOrderFail["UnreducedCoefficientRemainder"]];
 output=Association@Table[j->0,{j,low,high}];
 Do[
  If[!AllTrue[entry["Terms"],Lookup[#,"Representation",None]==="Exact"&],
   epsOrderFail["ExactReconstructedAnalyticCoefficientsRequired"]];
  master=entry["Master"];record=Select[Values[values],Lookup[#,"MasterIntegral",None]===master&];
  If[Length[record]=!=1,epsOrderFail["UniqueExplicitMasterValueRequired",<|"Master"->master|>]];record=First[record];
  If[!ContainsAll[Keys[record],{"Coefficients","KnownThroughOrder","LaurentLowerBound","DimensionalRegulator"}],
   epsOrderFail["ExplicitMasterOrderMetadataRequired",<|"Master"->master|>]];
  {mlow,mhigh}=Lookup[record,{"LaurentLowerBound","KnownThroughOrder"}];
  cs=record["Coefficients"]/.record["DimensionalRegulator"]->e;
  If[!IntegerQ[mlow]||!IntegerQ[mhigh]||Sort[Keys[cs]]=!=Range[mlow,mhigh]||!FreeQ[Values[cs],e|_SeriesData|_Series|_SeriesCoefficient|_Integrate|_Inactive|_Failure|_Missing],
   epsOrderFail["ContiguousExplicitMasterLaurentCoefficientsRequired",<|"Master"->master|>]];
  cs=cs/.rules;exact=TrueQ[Lookup[record,"ExactInEpsilon",False]];
  measure=Lookup[conversions,Key[master],Missing["MeasureConversionRequired"]];
  If[MissingQ[measure],epsOrderFail["MasterMeasureConversionRequired",<|"Master"->master|>]];
  mult=(norm measure)/.rules;
  converted=Join[entry,<|"Terms"->(Join[#,<|"PreFactor"->((#["PreFactor"]mult)/.rules),
      "Coefficient"->(#["Coefficient"]/.rules)|>]& /@ entry["Terms"])|>];
  expr=Total[(#["PreFactor"]#["Coefficient"]& /@ converted["Terms"])];
  valuation=FeynFacet`DetermineLaurentValuation[expr,e];
  If[!IntegerQ[valuation],
    If[TrueQ[expr===0],Continue[],epsOrderFail["AnalyticCoefficientLaurentValuationRequired",<|"Master"->master,"Valuation"->valuation|>]]];
  needed=high-valuation;
  If[!exact&&mhigh<needed,epsOrderFail["InsufficientAnalyticMasterOrders",<|"Master"->master,"RequiredThroughOrder"->needed,"KnownThroughOrder"->mhigh|>]];
  If[!exact,epsilonAuditMultiplier[expr,e,mlow,mhigh,high,"AnalyticMasterContraction",master]];
  coefficients=FeynFacet`ExpandMasterIntegralCoefficient[converted,e,{Min[low-mhigh,valuation],high-mlow}];
  If[FailureQ[coefficients],epsOrderFail["AnalyticCoefficientExpansionFailed",<|"Master"->master,"Cause"->coefficients|>]];
  one=Association@Table[j->Total[KeyValueMap[Function[{k,value},value Lookup[coefficients["Coefficients"],j-k,0]],cs]],{j,low,high}];
  output=Merge[{output,one},Total];AppendTo[contributions,<|"MasterIntegral"->master,"RequiredThroughOrder"->needed,
   "KnownThroughOrder"->mhigh,"Coefficients"->one|>],{entry,table["Masters"]}];
 <|"Format"->"FeynFacet-AnalyticMasterContraction","FormatVersion"->1,"DimensionalRegulator"->e,
  "EpsilonOrderRange"->range,"Coefficients"->output,"MasterContributions"->contributions,
  "PhaseSpace"->Lookup[table,"PhaseSpace",1],"MasterCount"->Length[table["Masters"]]|>
 ],"EpsilonOrders"];
End[];EndPackage[];
