Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
noRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];
Get[noRoot<>"/Tests/TestKit.wl"];Block[{Print},Get[noRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
noOutput=noRoot<>"/Projects/ppHX_UU/Results/NLO/qqp-qqp/Validation/SourceOrders";
noReplay=Rest[$ScriptCommandLine]==={"replay"};
If[!MemberQ[{{},{"replay"}},Rest[$ScriptCommandLine]],Print["Usage: check_nlo_only_scattering_source.wls [replay]"];Exit[2]];
If[noReplay,
 noSaved=FeynFacet`FamilyArtifactRead[noOutput<>"/NLOOnlySource.wl"];
 noPlanProject=noSaved["PlanProject"];noSourceProject=noSaved["SourceProject"],
 noStamp=IntegerString[Round[AbsoluteTime[]]];
 noPlanProject=CreateDirectory[noOutput<>"/NLOOnlyPlanProject"<>noStamp];
 noSourceProject=CreateDirectory[noOutput<>"/NLOOnlySourceProject"<>noStamp];
 noRootText=Import[noRoot<>"/Projects/ppHX_UU/Common-Card.wl","Text"];
 Export[noPlanProject<>"/Common-Card.wl",StringReplace[noRootText,"\"NLO\" -> {"->"\"NLO\" -> {\"u-d_g\", "],"Text"];
 Export[noSourceProject<>"/Common-Card.wl",noRootText,"Text"]];
noNLODirectory=noPlanProject<>"/Raw/NLO/u-d_g";
If[!DirectoryQ[noNLODirectory<>"/Real"],CreateDirectory[noNLODirectory<>"/Real",CreateIntermediateDirectories->True]];
FeynFacet`FamilyArtifactWrite[<|"Contribution"->"Real","EpsilonRange"->{-2,0}|>,noNLODirectory<>"/Real/Card.wl"];
noDiscovered=Catch[FeynFacet`Private`projectAmplitudeCardNames[noNLODirectory],"ProjectCards"];
FTTest`FTAssert["an NLO-only observed-gluon channel requires only its actual real card",
 noDiscovered==={"Real"}];
noIncomplete=noPlanProject<>"/Raw/NLO/qqp-qqp";If[!DirectoryQ[noIncomplete<>"/Real"],CreateDirectory[noIncomplete<>"/Real",CreateIntermediateDirectories->True]];
FeynFacet`FamilyArtifactWrite[<|"Contribution"->"Real","EpsilonRange"->{-2,0}|>,noIncomplete<>"/Real/Card.wl"];
FTTest`FTAssert["a Born-capable channel still rejects a missing virtual amplitude card",
 FailureQ[Catch[FeynFacet`Private`projectAmplitudeCardNames[noIncomplete],"ProjectCards"]]];
noDefinitions=FeynFacet`PlanCountertermContributionCards[noNLODirectory];
FTTest`FTAssert["NLO-only counterterms do not request nonexistent same-channel Born or UV sources",
 ListQ[noDefinitions]&&noDefinitions=!={}&&FreeQ[noDefinitions,"CouplingCounterterm"]&&
 AllTrue[noDefinitions,!(Lookup[#,"SourceOrder",None]==="LO"&&Lookup[#,"SourceChannel",None]==="u-d_g")&]];
If[!ListQ[noDefinitions],Print["NLO ONLY PLAN FAILURE ",noDefinitions];FTTest`FTReport[]];
noWritten=FeynFacet`WriteCountertermCards[noNLODirectory,noDefinitions];
noPlan=FeynFacet`PlanNLOCounterterms[noNLODirectory];
FTTest`FTAssert["the ordinary NLO counterterm plan resolves all physical Born neighbors for an observed gluon",
 AssociationQ[noPlan]&&!KeyExistsQ[noPlan["BornSourceOrders"],"u-d_g"]&&
 Length[noPlan["CountertermDistributions"]]>0&&
 AllTrue[noPlan["CountertermDistributions"],#["Distribution"]["Role"]=!="Coupling"&]];

noDirectory=noSourceProject<>"/Raw/NNLO/qqp-qqp";
If[!DirectoryQ[noDirectory],CreateDirectory[noDirectory,CreateIntermediateDirectories->True]];
noConsumer=FeynFacet`BuildCountertermProjectCard[noDirectory];
noConsumer=Join[noConsumer,<|"Execution"->Map[1&,noConsumer["Execution"]]|>];
noRequirements={<|"SourceOrder"->1,"SourceChannel"->"u-d_g","RequiredSourceThroughOrder"->1|>};
Print["NLO ONLY SOURCE CONSUMER ",noSourceProject];
FeynFacet`FamilyArtifactWrite[<|"PlanProject"->noPlanProject,"SourceProject"->noSourceProject,
 "CountertermDefinitions"->noDefinitions,"Requirements"->noRequirements|>,noOutput<>"/NLOOnlyInputs.wl"];
If[noReplay,
 noSeconds=0;noCatalog=<|"Sources"-><|1-><|"u-d_g"->FeynFacet`ReadPartonicResult[If[FileExistsQ[noOutput<>"/NLOOnlyBareEpsilonOne.wl"],
    noOutput<>"/NLOOnlyBareEpsilonOne.wl",noSaved["Result"]]]|>|>,
  "StageSeconds"->noSaved["StageSeconds"]|>,
 {noSeconds,noCatalog}=AbsoluteTiming[FeynFacet`GenerateBarePartonicSourceCatalog[noConsumer,noRequirements]]];
FTTest`FTAssert["a fresh source catalog generates the real-only observed-gluon density through epsilon one",
 AssociationQ[noCatalog]&&Keys[noCatalog["Sources"]]==={1}&&
 noCatalog["Sources"][1]["u-d_g"]["EpsilonRange"]==={-2,1}];
If[!AssociationQ[noCatalog],Print["NLO ONLY SOURCE FAILURE ",System`Short[noCatalog,12]];
 FeynFacet`FamilyArtifactWrite[noCatalog,noOutput<>"/NLOOnlySourceFailure.wl"];FTTest`FTReport[]];
noSource=noCatalog["Sources"][1]["u-d_g"];noPath=noDirectory<>"/Counterterm/Work/Sources/NLO/u-d_g";
FTTest`FTAssert["the observed-gluon source is bare and has a nonzero positive-epsilon coefficient",
 noSource["RenormalizationStage"]==="Bare"&&noSource["PhysicalChannel"]["Observed"]==="g"&&
 !FeynFacet`Private`partonicZeroTreeQ[noSource["Coefficients"][1]]&&
 FreeQ[noSource["Coefficients"],_Integrate|_SeriesData|_SeriesCoefficient|_FeynCalc`GLI|_Failure|_Missing]];
noAuxiliarySymbols=DeleteDuplicates[Cases[noSource["Coefficients"],q_Symbol/;
 MemberQ[{"xa","xb","zh"},SymbolName[q]],Infinity]];
FTTest`FTAssert["the invariant source coefficients contain no auxiliary PDF or FF momentum fractions",
 noAuxiliarySymbols==={}];
FTTest`FTAssert["NLO-only generation creates no Born, virtual, or sibling lower-order result directories",
 !DirectoryQ[noSourceProject<>"/LO"]&&!DirectoryQ[noSourceProject<>"/NLO"]&&
 !DirectoryQ[noDirectory<>"/Counterterm/Work/Sources/LO/u-d_g"]&&!DirectoryQ[noPath<>"/Virtual"]&&
 FileExistsQ[noPath<>"/Real/Result.wl"]&&FileExistsQ[noPath<>"/Result.wl"]];
noPairs=Select[FileNames["F*_C*.wl",noPath<>"/Real",Infinity],StringContainsQ[#,"/Amplitudes/Pairs/"]&];
noReductionDirectories=DirectoryName/@FileNames["CoefficientResult.wl",noPath<>"/Real",Infinity];
FTTest`FTAssert["the new real-only source owns its diagram, Kira and coefficient pipeline",
 Length[noPairs]>0&&Length[noReductionDirectories]>0&&
 AllTrue[noReductionDirectories,FileExistsQ[#<>"/KiraStream/Manifest.wl"]&&FileExistsQ[#<>"/KiraResult.wl"]&]];
FeynFacet`FamilyArtifactWrite[<|"PlanProject"->noPlanProject,"SourceProject"->noSourceProject,
 "CountertermPlan"->KeyTake[noPlan,{"BornSourceOrders","CountertermDistributions"}],
 "Result"->If[FileExistsQ[noOutput<>"/NLOOnlyBareEpsilonOne.wl"],noOutput<>"/NLOOnlyBareEpsilonOne.wl",noPath<>"/Result.wl"],
 "SourceDirectory"->noPath,"PairFiles"->noPairs,"StageSeconds"->noCatalog["StageSeconds"],
 "CalculationSeconds"->noSeconds,"OriginalGenerationSeconds"->If[noReplay,Lookup[noSaved,"OriginalGenerationSeconds",noSaved["CalculationSeconds"]],noSeconds],
 "ReplayOfSavedOutputs"->noReplay,"ReductionDirectories"->noReductionDirectories,"AcceptedResultsModified"->False|>,noOutput<>"/NLOOnlySource.wl"];
Print["COMPLETED NLO ONLY SCATTERING SOURCE CHECKS SECONDS ",noSeconds];
FTTest`FTReport[];
