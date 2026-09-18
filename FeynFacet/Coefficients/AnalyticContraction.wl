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
  (* A structural lower bound covers analytic sums and remains sufficient
     when leading terms cancel. Reciprocals still require exact valuations. *)
  valuation=FeynFacet`DetermineMeromorphicLaurentLowerBound[expr,e];
  If[!IntegerQ[valuation],
    If[valuation===Infinity,Continue[],epsOrderFail["AnalyticCoefficientLaurentBoundRequired",<|"Master"->master,"LowerBound"->valuation|>]]];
  needed=high-valuation;
  If[!exact&&mhigh<needed,epsOrderFail["InsufficientAnalyticMasterOrders",<|"Master"->master,"RequiredThroughOrder"->needed,"KnownThroughOrder"->mhigh|>]];
  If[!exact,epsilonAuditMultiplier[expr,e,mlow,mhigh,high,"AnalyticMasterContraction",master]];
  coefficients=FeynFacet`ExpandMasterIntegralCoefficient[converted,e,{Min[low-mhigh,valuation],high-mlow}];
  If[FailureQ[coefficients],epsOrderFail["AnalyticCoefficientExpansionFailed",<|"Master"->master,"Cause"->coefficients|>]];
  one=Association@Table[j->Total[KeyValueMap[Function[{k,value},value Lookup[coefficients["Coefficients"],j-k,0]],cs]],{j,low,high}];
  output=Merge[{output,one},Total];AppendTo[contributions,<|"MasterIntegral"->master,"RequiredThroughOrder"->needed,
   "KnownThroughOrder"->mhigh,"CoefficientLaurentLowerBound"->valuation,"Coefficients"->one|>],{entry,table["Masters"]}];
 <|"Format"->"FeynFacet-AnalyticMasterContraction","FormatVersion"->1,"DimensionalRegulator"->e,
  "EpsilonOrderRange"->range,"Coefficients"->output,"MasterContributions"->contributions,
  "PhaseSpace"->Lookup[table,"PhaseSpace",1],"MasterCount"->Length[table["Masters"]]|>
 ],"EpsilonOrders"];

FeynFacet`ContractExplicitMasterSolution::usage="ContractExplicitMasterSolution[rows,solution,request] contracts sparse exact coefficient rows with a fully explicit saved master Laurent solution in the common normalization. It checks every master order and returns finite Laurent coefficients; endpoint continuation remains a separate operation.";
FeynFacet`ContractExplicitMasterSolution[rows_Association,solution_Association,request_Association]:=
 Catch[Module[{basis,e,known,low,upper,values,rules,table,result,results=<||>,progress,range,
   current,master,orders,rowLowerBounds,minimumLower},
 basis=Lookup[solution,"MasterIntegralBasis",None];e=Lookup[solution,"DimensionalRegulator",None];
 known=Lookup[solution,"Coefficients",None];low=Lookup[solution,"OriginalMasterLaurentLowerBounds",None];
 upper=Lookup[solution,"MasterIntegralUpperOrders",None];rules=Lookup[request,"MasterKinematicRules",{}];
 range=Lookup[request,"EpsilonOrderRange",None];
 If[!ListQ[basis]||!AssociationQ[known]||!MatchQ[e,_Symbol]||
  !VectorQ[low,IntegerQ]||!VectorQ[upper,IntegerQ]||Length[low]=!=Length[basis]||
  Length[upper]=!=Length[basis]||!AllTrue[Values[rows],AssociationQ[#]&&ContainsAll[basis,Keys[#]]&]||
  !MatchQ[range,{_Integer,_Integer}]||
  !TrueQ[Lookup[solution,"BoundaryValuesApplied",False]]||
  !AllTrue[Lookup[solution,{"AlgebraicDefinitions","KernelDefinitions","IntegralDefinitions"},{}],#==={}&],
  epsOrderFail["FullyExplicitMatchedMasterSolutionRequired"]];
 If[Cases[Values[known],_Derivative,{0,Infinity},Heads->True]=!={}||
  !FreeQ[Values[known],_FeynCalc`GLI|_Integrate|_Inactive|_Missing|_Failure|
    _FeynFacetSolution`F|_FeynFacetSolution`C|_FeynFacetSolution`a|_FeynFacetSolution`i],
  epsOrderFail["UnresolvedMasterSolutionDefinitions"]];
 values=Association@Table[
  master=basis[[j]];orders=Range[low[[j]],upper[[j]]];
  If[!AllTrue[orders,KeyExistsQ[known,{j,#}]&],
   epsOrderFail["ContiguousExplicitMasterLaurentCoefficientsRequired",<|"Master"->master|>]];
  j-><|"MasterIntegral"->master,"DimensionalRegulator"->e,"LaurentLowerBound"->low[[j]],
   "KnownThroughOrder"->upper[[j]],"Coefficients"->Association@Table[
    k->(known[[Key[{j,k}]]]/.rules),{k,orders}]|>,{j,Length[basis]}];
 rowLowerBounds=Association@KeyValueMap[Function[{label,row},label->Min[
  KeyValueMap[Function[{mi,c},If[c===0,Infinity,
   low[[First@FirstPosition[basis,mi]]]+FeynFacet`DetermineMeromorphicLaurentLowerBound[c,e]]],row]]],rows];
 If[!AllTrue[Values[rowLowerBounds],IntegerQ[#]||#===Infinity&],
  epsOrderFail["EstablishedBulkLaurentLowerBoundsRequired"]];
 minimumLower=Min[Values[rowLowerBounds]];
 If[TrueQ[Lookup[request,"RetainLowerLaurentOrders",False]]&&minimumLower=!=Infinity,
  range={Min[First[range],minimumLower],Last[range]}];
 progress=Lookup[request,"ProgressFunction",None];
 Do[
  If[progress=!=None,progress[label]];
  table=<|"PreFactor"->1,"DimensionalRegulator"->e,"RemainderTerms"->{},
   "Masters"->KeyValueMap[Function[{mi,c},<|"Master"->mi,
    "Terms"->{<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->c|>}|>],rows[label]]|>;
  result=FeynFacet`ContractAnalyticMasterCoefficients[table,values,
   <|"EpsilonOrderRange"->range,"Normalization"->1,
    "MeasureConversions"->AssociationThread[basis,ConstantArray[1,Length[basis]]]|>];
  If[FailureQ[result],epsOrderFail["ExplicitMasterRowContractionFailed",<|"Row"->label,"Cause"->result|>]];
  AssociateTo[results,label->KeyDrop[result,{"MasterContributions","PhaseSpace"}]],
 {label,Keys[rows]}];
 <|"Format"->"FeynFacet-ExplicitMasterCoefficientRows","DimensionalRegulator"->e,
  "EpsilonOrderRange"->range,"Rows"->results,"MasterIntegralBasis"->basis,
  "LaurentLowerBounds"->rowLowerBounds,
  "MasterKinematicRules"->rules,"EndpointDistributionsConstructed"->False,
  "DensityDefinition"-><|"CoefficientRows"->rows,"MasterIntegralBasis"->basis,
   "DimensionalRegulator"->e,"MasterKinematicRules"->rules,
   "PhysicalBoundaryDefinition"->Lookup[solution,"PhysicalBoundaryDefinition",Missing["NotAnOrderedPhysicalSolution"]]|>,
  "Scope"->"Pointwise Laurent coefficients on the open physical domain, in the already common normalization."|>
 ],"EpsilonOrders"];
End[];EndPackage[];
