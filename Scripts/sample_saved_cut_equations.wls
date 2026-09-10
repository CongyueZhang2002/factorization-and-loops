
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=2,Print["Usage: sample_saved_cut_equations.wls EQUATIONS.wl REQUEST.wl"];Exit[2]];
{ssEquationFile,ssRequestFile}=ExpandFileName/@arguments;
ssEquations=FeynFacet`FamilyArtifactRead[ssEquationFile];ssRequest=FeynFacet`FamilyArtifactRead[ssRequestFile];
If[!AllTrue[{ssEquations,ssRequest},AssociationQ],Print["Saved equations and request required"];Exit[1]];
ssPath[value_String]:=If[StringStartsQ[value,"/"],value,ExpandFileName[FileNameJoin[{DirectoryName[ssRequestFile],value}]]];
ssResult=FeynFacet`SampleCutIBPEquations[ssEquations["Rows"],ssEquations["Targets"],ssEquations["Families"],
 Join[KeyTake[ssRequest,{"Points","Prime","Threads","MaximumSelectionClosureIterations"}],<|
 "WorkingDirectory"->ssPath[ssRequest["WorkingDirectory"]],
 "PreferredMasterIntegrals"->ssEquations["PreferredMasterIntegrals"]|>]];
FeynFacet`FamilyArtifactWrite[ssResult,ssPath[ssRequest["OutputFile"]],Compression->Automatic];
If[!AssociationQ[ssResult],Print["FAILED ",If[FailureQ[ssResult],ssResult[[1]],Head[ssResult]]];Exit[1]];
Print["TARGET REMAINDER RANKS ",Lookup[ssResult["Samples"],"TargetRemainderRank"]];
Print["COMPLETED ",ssPath[ssRequest["OutputFile"]]];
