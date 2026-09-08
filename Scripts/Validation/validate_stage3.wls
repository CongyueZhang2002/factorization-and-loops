#!/usr/bin/env wolframscript
(* Boundary integrals only: this driver never evaluates or transports a DE. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Scripts/Validation/common.wl"];
args=Rest[$ScriptCommandLine];
If[!MemberQ[{2,3},Length[args]],Print["Expected MANIFEST.wxf OUTPUT.wxf [comma-separated input IDs]"];Exit[2]];
file=ExpandFileName[args[[1]]];base=DirectoryName[file];spec=readValidationFile[file];
If[TrueQ[Lookup[spec,"RecomputeBoundaryIntegrals",True]],Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]]];
Get[root<>"/FeynFacet/Solution.m"];
cases=spec["BoundaryIntegrals"];ids=Lookup[cases,"ID"];
If[ids==={}||!DuplicateFreeQ[ids],Print["Invalid boundary inventory"];Exit[2]];
selected=If[Length[args]===3,StringSplit[args[[3]],","],ids];
If[!ContainsAll[ids,selected]||selected==={},Print["Unknown boundary input ID"];Exit[2]];
reduction=readValidationFile[validationPath[base,spec["AmplitudeReductionFile"]]];
currentIndices=Select[Range[Length[reduction["BoundaryInputs"]]],
 reduction["InputOrderDetermination"]["BoundaryIntegralOrderRanges"][#]=!={}&];
If[Lookup[cases,"BoundaryInputIndex"]=!=currentIndices||!AllTrue[cases,
 #["RequiredOrders"]===(Range@@reduction["InputOrderDetermination"]["BoundaryIntegralOrderRanges"][#["BoundaryInputIndex"]])&&
 Lookup[#,"OriginalRow",None]===Lookup[reduction["BoundaryInputs"][[#["BoundaryInputIndex"]]],"OriginalRow",None]&],
 Print["Boundary inventory changed; regenerate validation inputs"];Exit[2]];
reports={};
Do[
 id=entry["ID"];orders=entry["RequiredOrders"];
 If[!MemberQ[selected,id],AppendTo[reports,<|"ID"->id,"Status"->"NotChecked","RequiredOrders"->orders|>];Continue[]];
 input=reduction["BoundaryInputs"][[entry["BoundaryInputIndex"]]];
 stored=validationCoefficients[input,orders,reduction["DimensionalRegulator"]];actual=stored;method="StoredCoefficients";
 reference=validationSelectedFile[base,Lookup[entry,"Reference",None]];
 expected=If[AssociationQ[reference],validationCoefficients[reference,orders,reduction["DimensionalRegulator"]],<||>];
 independent=StringQ[Lookup[entry,"IndependentReferenceDescription",None]]&&
  StringLength[entry["IndependentReferenceDescription"]]>0;
 If[!independent,expected=<||>];
 integration=None;
 If[TrueQ[Lookup[spec,"RecomputeBoundaryIntegrals",True]]&&expected=!=<||>&&KeyExistsQ[input,"IntegralDefinition"],
  Print[id," evaluating boundary integral through ",Max[orders]];
  integration=FeynFacet`IntegrateEulerBoundaryIntegral[input["IntegralDefinition"],{Min[orders],Max[orders]},
   "IntegrationBackend"->Lookup[spec,"IntegrationBackend",Automatic],
   "TimeLimit"->Lookup[spec,"TimeLimit",1800]];
  writeValidationFile[ExpandFileName[args[[2]]]<>".integrals/"<>id<>".wxf",integration];
  actual=If[AssociationQ[integration],validationCoefficients[integration,orders,reduction["DimensionalRegulator"]],<||>];
  method="RecomputedBoundaryIntegral"];
 comparison=FeynFacetSolution`CompareLaurentCoefficients[actual,expected,orders,
  Sequence@@Lookup[spec,"ComparisonOptions",{}]];
 If[FailureQ[comparison],comparison=<|"Status"->"Failed","Failure"->comparison|>];
 storedComparison=FeynFacetSolution`CompareLaurentCoefficients[actual,stored,orders,Sequence@@Lookup[spec,"ComparisonOptions",{}]];
 If[AssociationQ[storedComparison]&&storedComparison["Status"]==="Failed",comparison["Status"]="Failed"];
 If[AssociationQ[storedComparison]&&storedComparison["Status"]==="Incomplete"&&comparison["Status"]==="Passed",comparison["Status"]="Incomplete"];
 If[FailureQ[integration],comparison["Status"]="Failed"];
 AppendTo[reports,Join[<|"ID"->id,"BoundaryInputIndex"->entry["BoundaryInputIndex"],
  "OriginalRow"->Lookup[entry,"OriginalRow",None],"ComputedMethod"->method,
  "IntegrationFailure"->If[FailureQ[integration],integration,None],"StoredCoefficientComparison"->storedComparison,
  "IndependentReferenceDescription"->Lookup[entry,"IndependentReferenceDescription",None]|>,comparison]];
 Print[id," ",comparison["Status"]," compared ",Lookup[comparison,"ComparedCoefficientCount",0],
  "/",Length[orders]],{entry,cases}];
selectedReports=Select[reports,MemberQ[selected,#["ID"]]&];
passed=AllTrue[selectedReports,#["Status"]==="Passed"&];
result=<|"Test"->"Stage3BoundaryIntegrals","UsesDETransport"->False,
 "Status"->If[AllTrue[reports,#["Status"]==="Passed"&],"Passed",If[AnyTrue[reports,#["Status"]==="Failed"&],"Failed","Incomplete"]],
 "SelectedTestsPassed"->passed,"RequiredIntegralCount"->Length[cases],"SelectedIntegralCount"->Length[selected],
 "PassedIntegralCount"->Count[Lookup[reports,"Status"],"Passed"],
 "RequiredCoefficientCount"->Total[Length/@Lookup[cases,"RequiredOrders"]],
 "PassedCoefficientCount"->Total[Lookup[reports,"PassedCoefficientCount",0]],
 "PhysicalLimitCompletenessProofsChecked"->False,"Results"->reports|>;
writeValidationFile[ExpandFileName[args[[2]]],result];
Export[ExpandFileName[args[[2]]]<>".json",Join[KeyDrop[result,"Results"],
 <|"Results"->(KeyTake[#,{"ID","Status","RequiredOrders","MissingComputedOrders","MissingReferenceOrders",
   "ComparedCoefficientCount","PassedCoefficientCount","ComputedMethod"}]&/@reports)|>],"RawJSON"];
Print[KeyDrop[result,"Results"]];Exit[If[passed,0,1]];
