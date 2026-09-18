Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
tmp=CreateDirectory[];input=CreateDirectory[tmp<>"/Input"];out=tmp<>"/Canonical";
Get[root<>"/Tests/Support/GeneratedPairRecords.wl"];
rows=FeynFacetTestPairs`GeneratePairTestRecords[root,tmp<>"/Generated"];
If[!MatchQ[rows,{_Association,_Association}],Print["PAIR FIXTURE GENERATION FAILED"];Exit[1]];
setContext[row_,ctx_]:=Join[row,<|"AnalyticContext"->ctx,
 "Topologies"->(Append[#,"AnalyticContext"->ctx]&/@row["Topologies"])|>];
ctx=Join[KeyDrop[rows[[2]]["AnalyticContext"],"Fingerprint"],<|"FeynFacetSourceHash"->"another-producer-version"|>];
ctx=Append[ctx,"Fingerprint"->FeynFacet`Private`reductionFingerprint[ctx]];
rows[[2]]=setContext[rows[[2]],ctx];
rows=Append[#,"ResultDirectory"->input]&/@rows;
FTTest`FTAssert["distinct producer versions preserve valid explicit pair artifacts",
 AllTrue[rows,FeynFacet`Private`validPreIBPResultQ]];
files=MapIndexed[Function[{row,index},file=input<>"/F1_C"<>ToString[First[index]]<>".wl";
 FeynFacet`FamilyArtifactWrite[row,file];file],rows];
canonical=FeynFacet`Private`CanonicalizePairArtifacts[files,out];
FTTest`FTAssert["canonicalization accepts equal physics from different producer versions",AssociationQ[canonical]];
saved=FeynFacet`FamilyArtifactRead/@canonical["Files"];
FTTest`FTAssert["canonical artifacts identify this producer and preserve original contexts",
 AllTrue[saved,#[ "AnalyticContext"]["FeynFacetSourceHash"]===FeynFacet`Private`$feynFacetSourceHash&]&&
 Lookup[saved,"OriginalAnalyticContext"]===Lookup[rows,"AnalyticContext"]];
FTTest`FTAssert["all canonical topology records share the actual derived context",
 AllTrue[saved,Function[row,AllTrue[row["Topologies"],#["AnalyticContext"]===row["AnalyticContext"]&]]]];
memory=FeynFacet`Private`CanonicalizePairArtifacts[Reverse[rows],tmp<>"/Memory","ReturnRecords"->True];
memoryRows=FeynFacet`FamilyArtifactRead/@memory["Files"];
FTTest`FTAssert["in-memory input has the same deterministic physical canonicalization",
 AssociationQ[memory]&&memory["Fingerprint"]===canonical["Fingerprint"]&&
 Lookup[memoryRows,{"Integrand","PreFactor","PhaseSpace","FractionMeasure","AnalyticContext","OriginalAnalyticContext"}]===
 Lookup[saved,{"Integrand","PreFactor","PhaseSpace","FractionMeasure","AnalyticContext","OriginalAnalyticContext"}]];
FTTest`FTAssert["canonical records are opt-in and identical to their checked files",
 !KeyExistsQ[canonical,"Records"]&&memory["Records"]===memoryRows];
memoryData=Catch[FeynFacet`Private`ibpInputData[memory["Records"],True],FeynFacet`Private`$ibpFailure];
fileData=Catch[FeynFacet`Private`ibpInputData[memory["Files"],True],FeynFacet`Private`$ibpFailure];
FTTest`FTAssert["in-memory Kira inputs retain exactly the file-based physical data",
 AssociationQ[memoryData]&&AssociationQ[fileData]&&
 KeyDrop[memoryData,"Sources"]===KeyDrop[fileData,"Sources"]];
FTTest`FTAssert["in-memory input does not claim source files it has not read",memory["SourceFiles"]==={}];
FTTest`FTAssert["duplicate pair identities fail before creating output",
 Quiet[FeynFacet`Private`CanonicalizePairArtifacts[{First[rows],First[rows]},tmp<>"/Duplicate"]]===$Failed&&
 !DirectoryQ[tmp<>"/Duplicate"]];
FTTest`FTAssert["mixed records and filenames are rejected",
 Quiet[FeynFacet`Private`CanonicalizePairArtifacts[{First[rows],First[files]},tmp<>"/Mixed"]]===$Failed];
collision=CreateDirectory[tmp<>"/CollisionInputs"];
CreateDirectory[collision<>"/a"];CreateDirectory[collision<>"/b"];
collisionFiles={collision<>"/a/pair.wl",collision<>"/b/pair.wl"};
MapThread[FeynFacet`FamilyArtifactWrite,{rows,collisionFiles}];
FTTest`FTAssert["different input pairs cannot overwrite one output basename",
 Quiet[FeynFacet`Private`CanonicalizePairArtifacts[collisionFiles,tmp<>"/CollisionOutput","ReturnRecords"->True]]===$Failed&&
 !FileExistsQ[tmp<>"/CollisionOutput/CanonicalRegistry.wl"]];
(* Intercept the actual raw driver handoff, before any solver work. *)
component=First@Values@FeynFacet`Private`projectContributionComponents[
 FeynFacet`ReadContributionCard[root<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp","Real"]];
captureHandoff[]:=Internal`InheritedBlock[
 {FeynFacet`GenerateContributionPairArtifacts,FeynFacet`Private`projectAmplitudeInputs,
  FeynFacet`ConstructZeroAmplitudeContribution,FeynFacet`Private`CanonicalizePairArtifacts,FeynFacet`Private`KiraSolve},
 Clear[FeynFacet`GenerateContributionPairArtifacts,FeynFacet`Private`projectAmplitudeInputs,
  FeynFacet`ConstructZeroAmplitudeContribution,FeynFacet`Private`CanonicalizePairArtifacts,FeynFacet`Private`KiraSolve];
 FeynFacet`GenerateContributionPairArtifacts[___]:=<|"Status"->"Fixture"|>;
 FeynFacet`Private`projectAmplitudeInputs[___]:=rows;
 FeynFacet`ConstructZeroAmplitudeContribution[___]:=$Failed;
 FeynFacet`Private`CanonicalizePairArtifacts[___]:=memory;
 FeynFacet`Private`KiraSolve[input_,___]:=Throw[input,"CapturedKiraInput"];
 Quiet@Catch[Catch[FeynFacet`Private`projectBareScalarContribution[component,"all"],"ProjectCards"],"CapturedKiraInput"]];
FTTest`FTAssert["the raw driver passes checked Associations to the actual Kira call",
 captureHandoff[]===memory["Records"]];
extra=memory["PairDirectory"]<>"/F99_C99.wl";
FeynFacet`FamilyArtifactWrite[First[memoryRows],extra];
FTTest`FTAssert["an extra canonical file is rejected before Kira and coefficient inventories diverge",
 FailureQ[captureHandoff[]]];
FeynFacet`FamilyArtifactDelete[extra];
Scan[Function[item,With[{index=First[item],failure=Last[item]},
 rejected=Internal`InheritedBlock[{FeynFacet`Private`canonicalPutArtifact},
   Clear[FeynFacet`Private`canonicalPutArtifact];
   FeynFacet`Private`canonicalPutArtifact[___]:=failure;
   Quiet[FeynFacet`Private`CanonicalizePairArtifacts[rows,tmp<>"/FailedWrite"<>ToString[index],"ReturnRecords"->True]]];
 FTTest`FTAssert["failed canonical write result "<>ToString[index]<>" cannot publish a manifest",
  rejected===$Failed&&!FileExistsQ[tmp<>"/FailedWrite"<>ToString[index]<>"/CanonicalRegistry.wl"]]
 ]],{{1,$Aborted},{2,Failure["WriteFailure",<||>]}}];
data=Catch[FeynFacet`Private`ibpInputData[canonical["Files"],True],FeynFacet`Private`$ibpFailure];
FTTest`FTAssert["Kira input validation accepts the resumed common context",AssociationQ[data]];
bad=Last[saved];ctx=Join[KeyDrop[bad["AnalyticContext"],"Fingerprint"],
 <|"Assumptions"->(bad["AnalyticContext"]["Assumptions"]&&Global`contextTestVariable>0)|>];
ctx=Append[ctx,"Fingerprint"->FeynFacet`Private`reductionFingerprint[ctx]];
bad=setContext[bad,ctx];
rejected=Quiet@Catch[FeynFacet`Private`ibpInputData[{First[saved],bad},False],FeynFacet`Private`$ibpFailure];
FTTest`FTAssert["a genuine difference in physical assumptions remains rejected",rejected===$Failed];

damaged=rows[[1]];ctx=Append[damaged["AnalyticContext"],"Fingerprint"->"damaged"];
damaged=setContext[damaged,ctx];badFile=input<>"/Damaged.wl";FeynFacet`FamilyArtifactWrite[damaged,badFile];
FTTest`FTAssert["a damaged original fingerprint is rejected before a new stamp can be written",
 Quiet[FeynFacet`Private`CanonicalizePairArtifacts[{badFile},tmp<>"/Rejected"]]===$Failed];
again=FeynFacet`Private`CanonicalizePairArtifacts[canonical["Files"],tmp<>"/Again"];
againRows=FeynFacet`FamilyArtifactRead/@again["Files"];
FTTest`FTAssert["repeated canonicalization preserves the derived and original contexts",
 Lookup[againRows,"AnalyticContext"]===Lookup[saved,"AnalyticContext"]&&
 Lookup[againRows,"OriginalAnalyticContext"]===Lookup[saved,"OriginalAnalyticContext"]];
next=Block[{FeynFacet`Private`$feynFacetSourceHash="next-canonicalizer-version"},
 FeynFacet`Private`CanonicalizePairArtifacts[again["Files"],tmp<>"/Next"]];
nextRows=FeynFacet`FamilyArtifactRead/@next["Files"];
FTTest`FTAssert["a later canonicalizer updates only its producer and keeps the original producer",
 AllTrue[nextRows,#["AnalyticContext"]["FeynFacetSourceHash"]==="next-canonicalizer-version"&]&&
 Lookup[nextRows,"OriginalAnalyticContext"]===Lookup[saved,"OriginalAnalyticContext"]];
before=FeynFacet`Private`coefficientInputFileFingerprint[files];
changed=Append[First[rows],"PreFactor"->2First[rows]["PreFactor"]];
FeynFacet`FamilyArtifactWrite[changed,First[files]];
FTTest`FTAssert["explicit coefficient input identity distinguishes changed pair weights",
 FeynFacet`Private`coefficientInputFileFingerprint[files]=!=before];

DeleteDirectory[tmp,DeleteContents->True];
FTTest`FTReport[];
