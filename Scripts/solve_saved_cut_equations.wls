$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=2,Print["Usage: solve_saved_cut_equations.wls EQUATIONS.wl REQUEST.wl"];Exit[2]];
{eqFile,requestFile}=ExpandFileName/@arguments;
data=FeynFacet`FamilyArtifactRead[eqFile];request=FeynFacet`FamilyArtifactRead[requestFile];
If[!AllTrue[{data,request},AssociationQ],Print["Exact equations and request required"];Exit[1]];
path[value_String]:=If[StringStartsQ[value,"/"],value,ExpandFileName[FileNameJoin[{DirectoryName[requestFile],value}]]];
rows=data["Rows"];families=data["Families"];normalization=None;
If[KeyExistsQ[request,"EquationScale"],
 scale=request["EquationScale"];
 columns=Union[Flatten[Keys/@rows],data["Targets"],data["PreferredMasterIntegrals"]];
 weights=Lookup[request,"IntegralScaleWeights",Association[(#->(-Total[#[[2]]]))&/@columns]];
 {scaleSeconds,normalization}=AbsoluteTiming[FeynFacet`NormalizeIntegralEquationScale[rows,weights,scale]];
 If[!AssociationQ[normalization],Print[normalization];Exit[1]];
 Print["VERIFIED EXACT SCALE REMOVAL IN ",scaleSeconds," SECONDS"];
 rows=normalization["Rows"];families=families/.scale->1;
 FeynFacet`FamilyArtifactWrite[KeyDrop[normalization,"Rows"],path[request["OutputFile"]]<>".ScaleNormalization.wl",Compression->Automatic]
];
{seconds,result}=AbsoluteTiming[FeynFacet`KiraReduction[families,data["Targets"],<|
"WorkingDirectory"->path[request["WorkingDirectory"]],"SeedIntegrals"->{},"ExtraEquations"->rows,
"PreferredMasterIntegrals"->data["PreferredMasterIntegrals"],"Threads"->Lookup[request,"Threads",1]|>]];
If[!AssociationQ[result],Print[result];Exit[1]];
If[AssociationQ[normalization],
 restored=FeynFacet`RestoreIntegralEquationScale[result["Rules"],normalization];
 If[!ListQ[restored],Print[restored];Exit[1]];
 result=Join[result,<|"Rules"->restored,"Families"->data["Families"],
 "EquationScaleNormalization"->KeyDrop[normalization,"Rows"]|>]];
missing=Complement[result["Masters"],data["PreferredMasterIntegrals"]];
result=Join[result,<|"SourceEquationFile"->eqFile,
 "PreferredMasterIntegrals"->data["PreferredMasterIntegrals"],"OutsidePreferredSpan"->missing,
 "AllTargetsInPreferredSpan"->(missing==={}),"TotalSolveSeconds"->seconds,
 "CertifiedPrescriptionEquivalences"->Lookup[data,"CertifiedPrescriptionEquivalences",None],
 "ExternalEndpointUniformityEstablished"->False|>];
FeynFacet`FamilyArtifactWrite[result,path[request["OutputFile"]],Compression->Automatic];
If[missing=!={},Print["EXACT REDUCTION STILL HAS ",Length[missing]," NONPREFERRED MASTERS"];Exit[1]];
Print["COMPLETED ",path[request["OutputFile"]]," TARGETS ",Length[data["Targets"]],
" BASIS ",Length[result["Masters"]]," SECONDS ",seconds];
