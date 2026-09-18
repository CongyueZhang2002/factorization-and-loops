Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
scRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];
Get[scRoot<>"/Tests/TestKit.wl"];Block[{Print},Get[scRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
scOutput=CreateDirectory[];
scFresh=CreateDirectory[scOutput<>"/SourceCardProject"<>IntegerString[Round[AbsoluteTime[]]]];
CopyFile[scRoot<>"/Projects/ppHX_UU/Common-Card.wl",scFresh<>"/Common-Card.wl"];
scDirectory=scFresh<>"/Raw/NNLO/qqp-qqp";CreateDirectory[scDirectory,CreateIntermediateDirectories->True];
scConsumer=FeynFacet`BuildCountertermProjectCard[scDirectory];
If[!AssociationQ[scConsumer],Print[scConsumer];FTTest`FTAssert["fresh scattering consumer compiles",False];FTTest`FTReport[]];
scConsumer=Join[scConsumer,<|"Execution"->Map[1&,scConsumer["Execution"]]|>];
scReal=FeynFacet`CompileBareSourceCard[scConsumer,"NLO","qqp-qqp","Real",1];
scVirtual=FeynFacet`CompileBareSourceCard[scConsumer,"NLO","qqp-qqp","Virtual",1];
FTTest`FTAssert["fresh scattering sources compile their positive epsilon demand from shared physics",
 AllTrue[{scReal,scVirtual},AssociationQ[#]&&#["EpsilonRange"]==={-2,1}&&
 #["SourceGeneration"]["GeneratedFromSharedPhysics"]===True&]];
FTTest`FTAssert["compiled source inputs and outputs belong to the consuming NNLO directory",
 AllTrue[{scReal,scVirtual},#["Directory"]===scDirectory&&#["ProjectDirectory"]===scFresh&&
 StringStartsQ[#["ContributionPath"],"Counterterm/Sources/NLO/qqp-qqp/"]&]];
FTTest`FTAssert["compiled sources preserve the allocated execution counts and declared integration method",
 AllTrue[{scReal,scVirtual},AllTrue[Values[#["Execution"]],#===1&]&&
 #["Assembly"]["IntegrationMethod"]==="CutIntegralReduction"&]];
scSetups=FeynFacet`ReadProcessCard/@{scReal,scVirtual};
FTTest`FTAssert["the same compiled cards supply real and virtual diagram topologies",
 AllTrue[scSetups,AssociationQ]&&
 (Length[#["PhaseSpaceMomentum"]]&/@scSetups)==={2,1}&&
 (Lookup[Lookup[#,{"ForwardAmplitudes","ConjugateAmplitudes"}],"LoopOrder"]&/@scSetups)==={{0,0},{1,0}}];
scExtra=FeynFacet`CompileBareSourceCard[scConsumer,"NLO","u-u_u-u","Real",1];
If[!AssociationQ[scExtra],Print["UNDECLARED SOURCE FAILURE ",scExtra]];
FTTest`FTAssert["a QCD source channel does not require a standalone NLO project card",
 !MemberQ[scConsumer["Orders"]["NLO"],"u-u_u-u"]&&AssociationQ[scExtra]&&
 scExtra["EpsilonRange"]==={-2,1}&&KeyExistsQ[scExtra,"Components"]];
FTTest`FTAssert["compilation requires no sibling LO or NLO folders and creates no bare result",
 !DirectoryQ[scFresh<>"/Raw/LO"]&&!DirectoryQ[scFresh<>"/Raw/NLO"]&&!DirectoryQ[scDirectory<>"/Results"]];
FeynFacet`FamilyArtifactWrite[<|"ConsumerProject"->scFresh,"ConsumerDirectory"->scDirectory,
 "Sources"->(KeyTake[#, {"Directory","ProjectDirectory","ContributionPath","EpsilonRange","Execution","SourceGeneration"}]&/@{scReal,scVirtual,scExtra})|>,
 scOutput<>"/CompiledScatteringSources.wl"];
DeleteDirectory[scOutput,DeleteContents->True];FTTest`FTReport[];
