(* Apply actual IBP coefficients to a matched scalar library before
   propagating epsilon demands. Library providers return finite coefficients,
   so the retained result contains no deferred numerical or symbolic evaluator. *)
BeginPackage["FeynFacet`"];
ExpandMatchedVirtualIntegralCombination::usage="ExpandMatchedVirtualIntegralCombination[decomposition,reduction,matching,epsilon,range,evaluator,request] contracts the generated scalar density with its IBP rules and verified library maps, determines sufficient orders from the complete coefficients, and returns explicit Laurent coefficients. evaluator[name,range] returns a finite scalar Laurent vector. Request may provide Prefactor, ScalarCoefficientRules and RetainAllPoles; the latter extends the output lower order to include every pole implied by the actual coefficients and master bounds.";
Begin["`Private`"];
ExpandMatchedVirtualIntegralCombination[source_Association,reduction_Association,matching_Association,
 e_Symbol,range:{_Integer,_Integer},evaluator_Function,request_Association:<||>]:=
 Catch[Module[
 {names,aliases,map,expressions,labels,rows,matrix,lowers,upper,bounds,records,
  library,masterRecords,vector,coefficients=<||>,integral,result,items,record,lower,outputRanges,
  started=AbsoluteTime[],progress},
 progress[label_]:=If[TrueQ[Lookup[request,"PrintTimings",False]],
   Print["VIRTUAL LAURENT ",label," SECONDS ",AbsoluteTime[]-started]];
 If[Lookup[matching,"Status",None]=!="AllMastersMatched"||
  Lookup[source,"Format",None]=!="FeynFacet-VirtualIntegralFamilies",
  cutFamilyFail["CompleteVirtualReductionAndLibraryMatchingRequired"]];
 names=DeleteDuplicates[Last/@matching["MasterLabels"]];
 aliases=Table[Unique["scalarMaster"],{Length[names]}];
 map=matching["MasterLabels"]/.Thread[names->aliases];
 labels=Keys[source["CoefficientRules"]];
 expressions=KeyValueMap[Function[{label,row},
  Total[KeyValueMap[#2(#1/.Dispatch[reduction["Rules"]]/.Dispatch[map])&,row]]],source["CoefficientRules"]];
 expressions=Map[Function[value,
  Expand[FeynFacet`SubstituteScalarPowers[Lookup[request,"Prefactor",1]value,Lookup[request,"ScalarCoefficientRules",{}]]/.D->4-2e]],expressions];
 If[!FreeQ[expressions,_FeynCalc`GLI|_FeynCalc`Pair|_FeynCalc`SMP|_FeynCalc`FeynAmpDenominator],
  cutFamilyFail["ExplicitVirtualScalarMasterCoefficientsRequired",<|"RemainingObjects"->DeleteDuplicates[Cases[expressions,_FeynCalc`GLI|_FeynCalc`Pair|_FeynCalc`SMP|_FeynCalc`FeynAmpDenominator,Infinity]]|>]];
 matrix=Table[Factor[Coefficient[expression,alias]],{expression,expressions},{alias,aliases}];
 If[!AllTrue[MapThread[Factor[#1-#2.aliases]&,{expressions,matrix}],#===0&],
  cutFamilyFail["LinearVirtualMasterCombinationRequired"]];
 lowers=Map[FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&,matrix,{2}];
 If[!AllTrue[Flatten[lowers],IntegerQ[#]||#===Infinity&],cutFamilyFail["VirtualCoefficientLaurentBoundsRequired"]];
 upper=Table[Max[Table[If[lowers[[i,j]]===Infinity,-Infinity,Last[range]-lowers[[i,j]]],
  {i,Length[labels]}]],{j,Length[names]}];
 library=matching["Library"];
 masterRecords=Table[SelectFirst[library,Lookup[#,"ScalarMasterName",#["Name"]]===name&],{name,names}];
 bounds=Lookup[masterRecords,"LaurentLowerBound"];
 If[!VectorQ[bounds,IntegerQ],cutFamilyFail["ScalarLibraryLaurentBoundsRequired"]];
 upper=MapThread[Max,{upper,bounds}];
 progress["ORDERS DETERMINED "<>ToString[AssociationThread[names,upper],InputForm]];
 Do[
  record=evaluator[names[[j]],{bounds[[j]],upper[[j]]}];
  If[!AssociationQ[record],Throw[record,"CutFamily"]];
  KeyValueMap[AssociateTo[coefficients,{j,Last[#1]}->#2]&,record["Coefficients"]],
 {j,Length[names]}];
 progress["SCALAR MASTERS EXPANDED"];
 vector=<|"DimensionalRegulator"->e,"Dimension"->Length[names],"Coefficients"->coefficients,
  "LaurentLowerBounds"->bounds,"KnownThroughOrders"->upper,"ExactTails"->ConstantArray[False,Length[names]]|>;
 lower=Table[Min[Table[lowers[[i,j]]+bounds[[j]],{j,Length[names]}]],{i,Length[labels]}];
 outputRanges=Table[{If[TrueQ[Lookup[request,"RetainAllPoles",False]],
   Min[First[range],Replace[lower[[i]],Infinity->First[range]]],First[range]],Last[range]},
   {i,Length[labels]}];
 integral=FeynFacet`ExpandLaurentCoefficientMatrix[matrix,e,Last[range]-bounds];
 progress["COEFFICIENT MATRIX EXPANDED"];
 result=FeynFacet`MultiplyLaurentCoefficientMatrix[integral,vector,outputRanges];
 progress["PRODUCT CONTRACTED"];
 If[!AssociationQ[result],Throw[result,"CutFamily"]];
 Join[result,<|"StructureFunctions"->labels,"ScalarMasterNames"->names,
  "ScalarMasterUpperOrders"->AssociationThread[names,upper],
  "ExactScalarCoefficientMatrix"->matrix,"CoefficientEntryLaurentLowerBounds"->lowers,
  "OutputEpsilonRanges"->outputRanges,
  "ConjugateInterferenceAdded"->False|>]
],"CutFamily"];
End[];EndPackage[];
