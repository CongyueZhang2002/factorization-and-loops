#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Usage: publish_angular_masters.wls ANGULAR_DENSITY.wl REPORT.wl"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
data=FeynFacet`FamilyArtifactRead[args[[1]]];
If[!AssociationQ[data],Print["Readable exact angular density required"];Exit[1]];
result=FeynFacet`PublishTwoBodyAngularSeeds[data];
If[!AssociationQ[result],Print[StringTake[ToString[result,InputForm],UpTo[2000]]];Exit[1]];
result=Append[result,"SourceFile"->ExpandFileName[args[[1]]]];
written=FeynFacet`FamilyArtifactWrite[result,args[[2]]];
If[FailureQ[written],Print[written];Exit[1]];
Print[KeyTake[result,{"Status","SeedCount","StoredCount","ReusedCount","Seconds"}]];
Print["ANGULAR MASTER PUBLICATION COMPLETE"];Exit[0];
