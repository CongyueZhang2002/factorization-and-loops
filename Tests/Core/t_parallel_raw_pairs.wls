Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
temp=CreateDirectory[];
card=FeynFacet`ReadContributionCard[root<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp","Virtual"];
card=Join[card,<|"DiagramIndices"->{{1,2},{1}},"WorkDirectory"->temp<>"/Serial",
 "Execution"->Join[card["Execution"],<|"Kernels"->1|>]|>];
serial=FeynFacet`GenerateContributionPairArtifacts[card,"all"];
parallelCard=Join[card,<|"WorkDirectory"->temp<>"/Parallel",
 "Execution"->Join[card["Execution"],<|"Kernels"->2|>]|>];
parallel=FeynFacet`GenerateContributionPairArtifacts[parallelCard,"all"];
FTTest`FTAssert["serial and parallel evaluation produce the same requested orientations",
 AssociationQ[serial]&&AssociationQ[parallel]&&FileNameTake/@serial["PairFiles"]===FileNameTake/@parallel["PairFiles"]];
fields={"Setup","FractionMeasure","PreFactor","PhaseSpace","Integrand","Topologies"};
FTTest`FTAssert["parallel workers preserve exact physical pair records",
 And@@MapThread[Function[{a,b},
  FeynFacet`Private`projectIdentityValue[KeyTake[FeynFacet`FamilyArtifactRead[a],fields]]===
  FeynFacet`Private`projectIdentityValue[KeyTake[FeynFacet`FamilyArtifactRead[b],fields]]],
  {serial["PairFiles"],parallel["PairFiles"]}]];
DeleteFile[First[parallel["PairFiles"]]];
resumed=FeynFacet`GenerateContributionPairArtifacts[parallelCard,"resume"];
report=FeynFacet`FamilyArtifactRead[parallelCard["WorkDirectory"]<>"/Amplitudes/PairReport.wl"];
FTTest`FTAssert["partial resume regenerates only missing valid pair artifacts",
 AssociationQ[resumed]&&Sort[Lookup[report["Pairs"],"Status"]]==={"Completed","Reused"}];
Do[
 value=Internal`InheritedBlock[{FeynFacet`Private`projectGeneratePairValue},
  Clear[FeynFacet`Private`projectGeneratePairValue];
  FeynFacet`Private`projectGeneratePairValue[_]:=ReleaseHold[fault];
  FeynFacet`Private`projectGeneratePair[{1,2}]];
 FTTest`FTAssert["a failed worker always returns its pair and a failed status: "<>ToString[index],
  AssociationQ[value]&&value["Pair"]==={1,2}&&MemberQ[{"Failed","Aborted"},value["Status"]]],
 {entry,{{1,Hold[Throw[17]]},{2,Hold[Throw[17,"tag"]]},{3,Hold[Abort[]]},{4,Hold[17]}}},
 {index,{First[entry]}},{fault,{Last[entry]}}];
baseSetup=FeynFacet`ReadProcessCard[card];
expected={{1,1},{2,1}};
testRows=(<|"Setup"->FeynFacet`Private`projectPairSetup[baseSetup,card["CardName"],#],
 "Result"->{1,1,1,0,{}}|>&/@expected);
FTTest`FTAssert["the orientation validator accepts the exact expected multiset",
 FeynFacet`Private`projectReturnedPairRowsQ[testRows,
  FeynFacet`Private`projectPairSetup[baseSetup,card["CardName"],First[expected]],expected]];
FTTest`FTAssert["empty, duplicate and misrouted orientations are rejected before writes",
 And@@(!FeynFacet`Private`projectReturnedPairRowsQ[#,
  FeynFacet`Private`projectPairSetup[baseSetup,card["CardName"],First[expected]],expected]&/@
  {{},{First[testRows],First[testRows]},{Last[testRows]}})];
owned=FeynFacet`Private`facetLaunchKernels[2];
poolResult=FeynFacet`GenerateContributionPairArtifacts[parallelCard,"resume"];
FTTest`FTAssert["the queue refuses to use or mutate a caller-owned kernel pool",
 MatchQ[poolResult,Failure["ExclusivePairWorkerPoolRequired",_Association]]&&Kernels[]===owned];
CloseKernels[owned];
shrunk=Join[parallelCard,<|"DiagramIndices"->{{1},{1}}|>];
reduced=FeynFacet`GenerateContributionPairArtifacts[shrunk,"resume"];
FTTest`FTAssert["a reduced diagram inventory quarantines obsolete managed files",
 AssociationQ[reduced]&&Length[reduced["PairFiles"]]===1&&
 Length[FileNames["F*_C*.wl",shrunk["WorkDirectory"]<>"/Amplitudes/SupersededPairs",Infinity]]===1];
record=FeynFacet`FamilyArtifactRead[First[reduced["PairFiles"]]];
FeynFacet`FamilyArtifactWrite[Join[record,<|"CardName"->"OldName"|>],First[reduced["PairFiles"]]];
FTTest`FTAssert["per-pair reuse and collection use the same contribution naming policy",
 !FeynFacet`Private`projectPairArtifactValidQ[First[reduced["PairFiles"]],
 FeynFacet`Private`projectPairSetup[FeynFacet`ReadProcessCard[shrunk],shrunk["CardName"],{1,1}]]];
calls=0;
cancelled=Internal`InheritedBlock[{FeynFacet`Private`projectGeneratePair},
 Clear[FeynFacet`Private`projectGeneratePair];
 FeynFacet`Private`projectGeneratePair[pair_]:=(calls++;<|"Status"->"Aborted","Pair"->pair|>);
 CheckAbort[FeynFacet`GenerateContributionPairArtifacts[Join[card,<|"WorkDirectory"->temp<>"/Cancelled"|>],"all"],"Cancelled"]];
FTTest`FTAssert["serial cancellation stops before the next pair",cancelled==="Cancelled"&&calls===1];

DeleteDirectory[temp,DeleteContents->True];FTTest`FTReport[];
