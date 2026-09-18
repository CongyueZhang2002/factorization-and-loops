(* Apply actual IBP coefficients to a matched scalar library before
   propagating epsilon demands. Library providers return finite coefficients,
   so the retained result contains no deferred numerical or symbolic evaluator. *)
BeginPackage["FeynFacet`"];
ExpandScalarIntegralCombination::usage="ExpandScalarIntegralCombination[rows,values,epsilon,range,request] contracts exact scalar-integral coefficient rows with explicit finite scalar Laurent records, checking lower bounds, stored coverage and omitted terms. Scalar records have integer coefficient keys, LaurentLowerBound and KnownThroughOrder. RetainAllPoles extends each output row to every implied pole; no conjugation or physical normalization is added.";
ExpandMatchedVirtualIntegralCombination::usage="ExpandMatchedVirtualIntegralCombination[decomposition,reduction,matching,epsilon,range,evaluator,request] contracts the generated scalar density with its IBP rules and verified library maps, determines sufficient orders from the complete coefficients, and returns explicit Laurent coefficients. evaluator[name,range] returns a finite scalar Laurent vector. Request may provide Prefactor, ScalarCoefficientRules and RetainAllPoles; the latter extends the output lower order to include every pole implied by the actual coefficients and master bounds.";
Begin["`Private`"];
ExpandScalarIntegralCombination[rows_Association,values_Association,e_Symbol,
 range:{_Integer,_Integer},request_Association:<||>]:=Catch[Module[
 {labels=Keys[rows],masters,records,matrix,bounds,upper,lowers,lower,ranges,vector,
  coefficients=<||>,result,series},
 If[labels==={}||First[range]>Last[range]||!AllTrue[Values[rows],AssociationQ],
  cutFamilyFail["ScalarIntegralCoefficientRowsRequired"]];
 masters=Union[Flatten[Keys/@Values[rows],1]];
 If[masters==={}||!ContainsAll[Keys[values],masters],cutFamilyFail["CompleteScalarIntegralValuesRequired"]];
 records=Lookup[values,masters];
 If[!AllTrue[records,AssociationQ[#]&&AssociationQ[Lookup[#,"Coefficients",None]]&&
   IntegerQ[Lookup[#,"LaurentLowerBound",None]]&&IntegerQ[Lookup[#,"KnownThroughOrder",None]]&&
   Lookup[#,"DimensionalRegulator",e]===e&],cutFamilyFail["ExplicitScalarLaurentRecordsRequired"]];
 bounds=Lookup[records,"LaurentLowerBound"];upper=Lookup[records,"KnownThroughOrder"];
 Do[
  If[upper[[j]]<bounds[[j]]||!ContainsAll[Keys[records[[j]]["Coefficients"]],Range[bounds[[j]],upper[[j]]]],
   cutFamilyFail["StoredScalarLaurentOrderMissing",<|"Integral"->masters[[j]]|>]];
  Do[AssociateTo[coefficients,{j,k}->records[[j]]["Coefficients"][k]],{k,bounds[[j]],upper[[j]]}],
 {j,Length[masters]}];
 matrix=Table[Lookup[rows[label],master,0],{label,labels},{master,masters}];
 series=FeynFacet`ExpandLaurentCoefficientMatrix[matrix,e,Last[range]-bounds];
 If[!AssociationQ[series],Throw[series,"CutFamily"]];
 lowers=series["EntryLaurentLowerBounds"];
 lower=Table[Min[lowers[[i]]+bounds],{i,Length[labels]}];
 ranges=Table[{If[TrueQ[Lookup[request,"RetainAllPoles",False]],
   Min[First[range],Replace[lower[[i]],Infinity->First[range]]],First[range]],Last[range]},
   {i,Length[labels]}];
 vector=<|"DimensionalRegulator"->e,"Dimension"->Length[masters],"Coefficients"->coefficients,
   "LaurentLowerBounds"->bounds,"KnownThroughOrders"->upper,
   "ExactTails"->(TrueQ[Lookup[#,"ExactInEpsilon",False]]&/@records)|>;
 result=FeynFacet`MultiplyLaurentCoefficientMatrix[series,vector,ranges];
 If[!AssociationQ[result],Throw[result,"CutFamily"]];
 Join[result,<|"StructureFunctions"->labels,"ScalarMasterIntegrals"->masters,
   "ScalarMasterUpperOrders"->AssociationThread[masters,upper],
   "ExactScalarCoefficientMatrix"->matrix,"OutputEpsilonRanges"->ranges,
   "ConjugateInterferenceAdded"->False|>]
],"CutFamily"];
ExpandScalarIntegralCombination[___]:=Failure["ExplicitScalarIntegralCombinationRequired",<||>];
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
