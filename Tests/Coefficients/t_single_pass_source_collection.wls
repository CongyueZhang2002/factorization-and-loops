
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
owner=root<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp";
setup=FeynFacet`ReadProcessCard[owner,"Real"];
setup=Append[FeynFacet`Private`interferencePairSetup[setup,{1,1}],"CardName"->"Real"];
value=FeynFacet`CollinearFactorizePreIBP[setup];
work=owner<>"/Real/Work/CoefficientSimplification/TestSinglePass-"<>CreateUUID[];
CreateDirectory[work,CreateIntermediateDirectories->True];
record=FeynFacet`GenerateCollinearFactorizePreIBPResult[setup,Sequence@@value,work];
source=work<>"/Pair.wl";FeynFacet`FamilyArtifactWrite[record,source];
data=FeynFacet`Private`ibpInputData[{source},True];
metadata=Join[KeyTake[data,{"CardName","Pairs","AnalyticContext","ResultDirectory"}],<|"TopologyEquivalence"-><||>,"Targets"->data["RawTargets"],
 "SourceInputFingerprint"->FeynFacet`Private`reductionFingerprint[
  FeynFacet`Private`sourceInputPayload[data["Records"],data["RawTargets"],data["AnalyticContext"]]]|>];
twoPass=FeynFacet`Private`coefficientInputData[{source},work<>"/OldStore"];
manifest=FeynFacet`Private`coefficientCollectTargetRecords[twoPass,metadata,work<>"/OldTargets",1];
readCount=0;
Attributes[countedRead]=Attributes[FeynFacet`FamilyArtifactRead];
Options[countedRead]=Options[FeynFacet`FamilyArtifactRead];
DownValues[countedRead]=DownValues[FeynFacet`FamilyArtifactRead]/.FeynFacet`FamilyArtifactRead->countedRead;
single=Internal`InheritedBlock[{FeynFacet`FamilyArtifactRead},
 Clear[FeynFacet`FamilyArtifactRead];
 FeynFacet`FamilyArtifactRead[file_,args___]:=(If[file===source,readCount++];countedRead[file,args]);
 FeynFacet`Private`coefficientPrepareInputRecords[{source},metadata,work<>"/NewStore",work<>"/NewTargets",1]];
FTTest`FTAssert["cold preparation reads each pair exactly once",AssociationQ[single]&&readCount===1];
FTTest`FTAssert["shared definitions equal the separate validated pass",single===twoPass];
oldTerms=FeynFacet`Private`finiteFieldMergeAssociationRecords[work<>"/OldTargets/Targets_0001.bin"];
newTerms=FeynFacet`Private`finiteFieldMergeAssociationRecords[work<>"/NewTargets/Targets_0001.bin"];
FTTest`FTAssert["collected rational coefficients are exactly unchanged",oldTerms===newTerms];
FTTest`FTAssert["a matching preparation reuses only complete target records",
 FeynFacet`Private`coefficientPrepareInputRecords[{source},metadata,work<>"/NewStore",work<>"/NewTargets",1]===single];

snapshot[directory_]:=Association@Map[
 FileNameDrop[#,FileNameDepth[directory]]->BinaryReadList[#]&,
 Sort[FileNames["*",directory,Infinity]]//Select[FileType[#]===File&]];
goodSnapshot=snapshot[work<>"/NewTargets"];
companion=source<>".meta.wxf";originalCompanion=BinaryReadList[companion];
DeleteFile[companion];
FTTest`FTAssert["a missing companion cannot reuse a valid source cache",
 FeynFacet`Private`coefficientPrepareInputRecords[{source},metadata,work<>"/NewStore",work<>"/NewTargets",1]===$Failed&&
 snapshot[work<>"/NewTargets"]===goodSnapshot];
stream=OpenWrite[companion,BinaryFormat->True];BinaryWrite[stream,originalCompanion,"Byte"];Close[stream];
originalMeta=Import[companion,"WXF"];
modifiedMeta=Append[originalMeta,"Symbols"->Append[originalMeta["Symbols"],"UnusedAlias"->HoldComplete[Global`unusedAlias]]];
Export[companion,modifiedMeta,"WXF"];
FTTest`FTAssert["companion changes invalidate both source and target caches",
 FeynFacet`Private`coefficientCachedInputData[{source},work<>"/NewStore"]===$Failed&&
 !FeynFacet`Private`coefficientTargetStoreValidQ[single,metadata,work<>"/NewTargets",1]];
stream=OpenWrite[companion,BinaryFormat->True];BinaryWrite[stream,originalCompanion,"Byte"];Close[stream];
FTTest`FTAssert["an unchanged restored companion permits reuse",
 FeynFacet`Private`coefficientCachedInputData[{source},work<>"/NewStore"]===single];

bad=Join[record,<|"Pair"-><|"Forward"->2,"Conjugate"->1|>|>];FeynFacet`FamilyArtifactWrite[bad,source];
FTTest`FTAssert["invalid pair metadata cannot reuse or rebuild a source summary",
 FeynFacet`Private`coefficientPrepareInputRecords[{source},metadata,work<>"/NewStore",work<>"/NewTargets",1]===$Failed];
FTTest`FTAssert["invalid input preserves the previous complete target store",
 snapshot[work<>"/NewTargets"]===goodSnapshot];
FeynFacet`FamilyArtifactWrite[record,source];
FTTest`FTAssert["incompatible reduction metadata is rejected before publication",
 FeynFacet`Private`coefficientPrepareInputRecords[{source},Append[metadata,"CardName"->"Different"],
 work<>"/NewStore",work<>"/NewTargets",1]===$Failed&&snapshot[work<>"/NewTargets"]===goodSnapshot];
rotated=RotateLeft[metadata["Targets"]];
changed=Append[metadata,"TopologyEquivalence"-><|"GLIRules"->Thread[metadata["Targets"]->rotated]|>];
rebuilt=FeynFacet`Private`coefficientPrepareInputRecords[{source},changed,work<>"/NewStore",work<>"/NewTargets",1];
terms=FeynFacet`Private`finiteFieldMergeAssociationRecords[work<>"/NewTargets/Targets_0001.bin"];
FTTest`FTAssert["mapping changes rebuild coefficients even with the same target labels",
 AssociationQ[rebuilt]&&And@@MapThread[
 TrueQ[Expand[Lookup[terms,#2]-Lookup[newTerms,#1]]===0]&,{metadata["Targets"],rotated}]];
goodSnapshot=snapshot[work<>"/NewTargets"];
FeynFacet`FamilyArtifactWrite[Append[record,"Integrand"->record["Integrand"]+7],source];
DownValues[originalAppend]=DownValues[FeynFacet`Private`coefficientAppendRecord]/.
 FeynFacet`Private`coefficientAppendRecord->originalAppend;
nonzeroAppendFailures=0;
remainderFailure=Internal`InheritedBlock[{FeynFacet`Private`coefficientAppendRecord},
 Clear[FeynFacet`Private`coefficientAppendRecord];
 FeynFacet`Private`coefficientAppendRecord[file_String,value_]:=
  If[FileNameTake[file]==="Remainder.bin"&&value=!=0,nonzeroAppendFailures++;$Failed,originalAppend[file,value]];
 FeynFacet`Private`coefficientPrepareInputRecords[{source},metadata,work<>"/NewStore",work<>"/NewTargets",1]];
FTTest`FTAssert["a failed nonzero remainder write cannot publish a complete store",
 remainderFailure===$Failed&&nonzeroAppendFailures===1&&snapshot[work<>"/NewTargets"]===goodSnapshot&&
 FileNames["NewTargets.building-*",work]==={}];
FeynFacet`FamilyArtifactWrite[record,source];
DownValues[originalWrite]=DownValues[FeynFacet`Private`coefficientWriteRecord]/.
 FeynFacet`Private`coefficientWriteRecord->originalWrite;
initialFailure=Internal`InheritedBlock[{FeynFacet`Private`coefficientWriteRecord},
 Clear[FeynFacet`Private`coefficientWriteRecord];
 FeynFacet`Private`coefficientWriteRecord[file_String,value_]:=
  If[FileNameTake[file]==="Remainder.bin",$Failed,originalWrite[file,value]];
 FeynFacet`Private`coefficientPrepareInputRecords[{source},metadata,work<>"/NewStore",work<>"/NewTargets",1]];
FTTest`FTAssert["failed mandatory initialization preserves the prior complete store",
 initialFailure===$Failed&&snapshot[work<>"/NewTargets"]===goodSnapshot];

FTTest`FTAssert["an empty source list cannot reset an accepted store",
 FeynFacet`Private`coefficientPrepareInputRecords[{},metadata,work<>"/NewStore",work<>"/NewTargets",1]===$Failed&&
 snapshot[work<>"/NewTargets"]===goodSnapshot];
DownValues[originalArtifactWrite]=DownValues[FeynFacet`FamilyArtifactWrite]/.
 FeynFacet`FamilyArtifactWrite->originalArtifactWrite;
Options[originalArtifactWrite]=Options[FeynFacet`FamilyArtifactWrite];
manifestWriteFailures=0;
manifestFailure=Internal`InheritedBlock[{FeynFacet`FamilyArtifactWrite},
 Clear[FeynFacet`FamilyArtifactWrite];
 FeynFacet`FamilyArtifactWrite[value_,file_String,args___]:=
  If[FileNameTake[file]==="Manifest.wl",manifestWriteFailures++;$Failed,originalArtifactWrite[value,file,args]];
 FeynFacet`Private`coefficientPrepareInputRecords[{source},metadata,work<>"/NewStore",work<>"/NewTargets",1]];
FTTest`FTAssert["a failed completion-manifest write cannot replace an accepted store",
 manifestFailure===$Failed&&manifestWriteFailures===1&&snapshot[work<>"/NewTargets"]===goodSnapshot];

traceDirectory=work<>"/Trace";CreateDirectory[traceDirectory];
definition=<|"Context"-><|"Scale"->as|>,"PhysicalFactor"->1,"MaximumTargets"->8|>;
FeynFacet`Private`finiteFieldWriteTraceManifest[traceDirectory,<|"OutputFiles"->{}|>,"source","kira",definition];
FTTest`FTAssert["an unchanged exact normalization definition permits checkpoint reuse",
 AssociationQ[FeynFacet`Private`finiteFieldRestoreTraceCheckpoint[traceDirectory,"source","kira",definition]]];
FTTest`FTAssert["changed normalization or target coverage invalidates a trace checkpoint",
 And@@(FeynFacet`Private`finiteFieldRestoreTraceCheckpoint[traceDirectory,"source","kira",#]===$Failed&/@
  {Append[definition,"PhysicalFactor"->2],Append[definition,"MaximumTargets"->4],
   Append[definition,"Context"-><|"Scale"->at|>]})];
If[FeynFacet`Private`coefficientSafeWorkPathQ[work],DeleteDirectory[work,DeleteContents->True]];
FTTest`FTReport[];
