#!/usr/bin/env wolframscript
(* INPUT.wl contains an association with Task, Data, and optionally Request.
   All process information is input data. Output is a finite WL association. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected INPUT.wl OUTPUT.wl"];Exit[2]];
input=Get[args[[1]]];
If[!AssociationQ[input],Print["Input must be an association"];Exit[2]];
task=Lookup[input,"Task",None];data=Lookup[input,"Data",None];
request=Lookup[input,"Request",<||>];
If[!AssociationQ[data] || !AssociationQ[request],Print["Data and Request must be associations"];Exit[2]];
seconds=First[AbsoluteTiming[result=Switch[task,
 "MasterIntegralExpansion",DetermineMasterIntegralExpansionOrders[data,request],
 "MasterIntegralRepresentations",ConstructMasterIntegralRepresentations[data,request],
 "MasterIntegralDimensionalRecurrence",
  ConstructMasterIntegralDimensionalRecurrence[data,Sequence@@Normal[Lookup[input,"Options",<||>]]],
 "DimensionalRecurrenceLaurentBounds",
  DetermineLaurentBoundsFromDimensionalRecurrence[data,Sequence@@Normal[Lookup[input,"Options",<||>]]],
 "Calculation",DetermineEpsilonOrders[data],
 "MasterCoefficientValuations",DetermineEpsilonOrders[data,request],
 "IntegralLaurentBound",DetermineIntegralLaurentBound[data],
 "FundamentalMatrix",DetermineFundamentalMatrixEpsilonOrders[data,request],
 "EndpointExpansion",DetermineEndpointEpsilonOrders[data,request],
 "FrobeniusLaurentBounds",DetermineFrobeniusLaurentBounds[data],
 _,Failure["UnknownOrderDeterminationTask",<|"Task"->task|>]]]];
If[!AssociationQ[result] && !FailureQ[result],
 result=Failure["OrderDeterminationDidNotReturnARecord",<||>]];
output=ExpandFileName[args[[2]]];
If[!DirectoryQ[DirectoryName[output]],CreateDirectory[DirectoryName[output],CreateIntermediateDirectories->True]];
temporary=output<>".tmp-"<>ToString[$ProcessID];
Block[{$Context="Global`",$ContextPath={"System`","Global`"}},Put[result,temporary]];
RenameFile[temporary,output,OverwriteTarget->True];
Print["Status: ",If[FailureQ[result],result[[1]],result["Status"]]];
Print["Computation seconds: ",seconds];
Print["Saved: ",output];
If[FailureQ[result],Exit[1]];
If[KeyExistsQ[result,"RequiredInputUpperOrders"],Print["Input upper orders: ",result["RequiredInputUpperOrders"]]];
If[KeyExistsQ[result,"MissingLaurentBounds"],Print["Unresolved bounds: ",result["MissingLaurentBounds"]]];
If[KeyExistsQ[result,"BoundaryCoefficientOrders"],
 Print["Boundary orders: ",result["BoundaryCoefficientOrders"]];
 Print["Maximum prepared evolution order: ",
   result["FundamentalMatrixEpsilonOrders"]["MaximumTransformedOrder"]]];
If[KeyExistsQ[result,"MissingIntegralData"],Print["Unresolved integral data: ",result["MissingIntegralData"]]];
Exit[0];
