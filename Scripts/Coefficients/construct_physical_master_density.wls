#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected REQUEST.wl OUTPUT.wxf"];Exit[2]];
file=ExpandFileName[Last[args]];
If[ToLowerCase[FileExtension[file]]=!="wxf",Print["Output must have .wxf extension"];Exit[2]];
request=FeynFacetRecords`ReadRecord[ExpandFileName[First[args]]];
If[!AssociationQ[request]||!ContainsAll[Keys[request],{"CoefficientFile","Request"}]||
 !StringQ[request["CoefficientFile"]]||!AssociationQ[request["Request"]]||
 !AssociationQ[Lookup[request,"DefinitionRequest",<||>]]||KeyExistsQ[request,"Definitions"],
 Print["CoefficientFile and Request required; physical definitions are derived from the coefficient table. Optional DefinitionRequest supplies explicit normalization choices."];Exit[2]];
table=FeynFacet`ReadMasterIntegralCoefficients[request["CoefficientFile"]];
If[FailureQ[table],Print[table];Exit[1]];
seconds=First[AbsoluteTiming[
 construction=FeynFacet`ConstructMasterIntegralDefinitions[
  Join[table["Definitions"],<|"OriginalMasterIntegralBasis"->Lookup[table["Masters"],"Master"],
   "DimensionalRegulator"->table["DimensionalRegulator"]|>],Lookup[request,"DefinitionRequest",<||>]];
 If[!AssociationQ[construction]||Lookup[construction,"UnresolvedIntegralDefinitions",None]=!=<||>,
  Print["Physical integral definitions failed: ",construction];Exit[1]];
 definitions=Association[(#["MasterIntegral"]->#)&/@Values[construction["MasterIntegralDefinitions"]]];
 result=FeynFacet`ConstructPhysicalMasterCoefficientDensity[
  table,definitions,Append[request["Request"],"SourceCoefficientFile"->ExpandFileName[request["CoefficientFile"]]]];
 If[AssociationQ[result],result=Append[result,"PhysicalDefinitionConstruction"->
  Join[KeyTake[construction,{"Status","FamilyCount","DimensionalRegulator"}],
   <|"Method"->"ConstructMasterIntegralDefinitions","Source"->"CoefficientTopologyAndSetup"|>]]];
]];
If[!AssociationQ[result]||Lookup[result,"Format",None]=!="FeynFacet-MasterIntegralCoefficients"||
 Lookup[result,"Status",None]=!="PhysicalMasterCoefficientDensityConstructed"||
 !TrueQ[Lookup[result,"PhysicalMasterNormalizationApplied",False]],
 Print["Physical density construction failed: ",result];Exit[1]];
file=ExpandFileName[Last[args]];temporary=file<>".partial";
If[!DirectoryQ[DirectoryName[file]],CreateDirectory[DirectoryName[file],CreateIntermediateDirectories->True]];
If[!StringQ[Quiet[Check[Export[temporary,result,"WXF",PerformanceGoal->"Size"],$Failed]]],
 Print["WXF output failed"];Exit[1]];
If[Import[temporary,"WXF"]=!=result,Print["Physical density read-back mismatch"];Exit[1]];
If[!StringQ[Quiet[Check[RenameFile[temporary,file,OverwriteTarget->True],$Failed]]],
 Print["WXF output rename failed"];Exit[1]];
summary=<|"Status"->result["Status"],"MasterCount"->Length[result["Masters"]],
 "Seconds"->seconds,"OutputBytes"->FileByteCount[file],
 "PhysicalMasterNormalizationApplied"->result["PhysicalMasterNormalizationApplied"],
 "CompleteDifferentialCrossSectionClaimed"->False|>;
Export[file<>".json",summary,"RawJSON"];Print["COMPLETED PHYSICAL DENSITY ",summary];Exit[0];
