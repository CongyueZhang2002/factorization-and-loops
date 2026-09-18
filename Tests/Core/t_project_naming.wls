Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
projects=DirectoryName/@FileNames["*/Common-Card.wl",root<>"/Projects"];
FTTest`FTAssert["physics project names are independent of perturbative order",
 Length[projects]===8&&AllTrue[projects,!StringEndsQ[#,{"_NLO","_NNLO","_LO"}]&]];
FTTest`FTAssert["old calculation archives belong outside projects",
 AllTrue[projects,!DirectoryQ[#<>"/Archive"]&]];
cards=FeynFacet`ReadProjectCard/@projects;
FTTest`FTAssert["every renamed common card compiles",
 AllTrue[cards,AssociationQ]];
FTTest`FTAssert["antiquark channels and species use qb consistently",
 AllTrue[cards,FreeQ[{#["Channels"],#["SpeciesMap"]},s_String/;StringContainsQ[s,{"qbar","qpbar","ubar","dbar"}]]&]];
ctFiles=Flatten[FileNames["Raw/NLO/*/Counter-*/Card.wl",#]&/@projects];
definitions=Get/@ctFiles;
FTTest`FTAssert["NLO cards omit the implied Born source definition",
 Length[definitions]>0&&AllTrue[definitions,
 Intersection[Keys[#],{"SourceOrder","SourceContribution","SourceRenormalizationStage"}]==={}&]];
temp=CreateDirectory[];
CopyFile[root<>"/Projects/DrellYan_UU/Common-Card.wl",temp<>"/Common-Card.wl"];
prepared=FeynFacet`PrepareProjectChannel[temp,"NLO","q-qb"];
planned=FeynFacet`PlanProjectResult[prepared["ResultCard"]];
ct=Select[planned["RawCards"],#["Contribution"]==="Counterterm"&];
FTTest`FTAssert["fresh card preparation uses physical counterterm labels",
 Sort[Keys[ct]]===Sort[{"q-qb/Counter-PDFA","q-qb/Counter-PDFB"}]];
FTTest`FTAssert["minimal NLO counterterm cards compile to bare Born sources",
 AllTrue[ct,#["SourceOrder"]==="LO"&&#["SourceContribution"]==="Born"&&#["SourceRenormalizationStage"]==="Bare"&]];
definition=Get[First[Values[ct]]["CardFile"]];
FTTest`FTAssert["an incompatible source cannot override the NLO Born requirement",
 FailureQ[FeynFacet`CompileCountertermCard[temp<>"/Raw/NLO/q-qb",
 Join[definition,<|"SourceContribution"->"Virtual"|>]]]];
arbitrary=<|"Assembly"-><|"FactorizationLegs"-><|
 "BeamLeft"-><|"Role"->"PDF","Index"->1|>,"BeamRight"-><|"Role"->"PDF","Index"->2|>,
 "TaggedJet"-><|"Role"->"FF"|>|>|>|>;
FTTest`FTAssert["counterterm labels follow declared PDF/FF roles for arbitrary leg names",
 (FeynFacet`Private`projectCountertermLegLabel[arbitrary,#]&/@{"BeamLeft","BeamRight","TaggedJet","Coupling"})===
 {"PDFA","PDFB","FF","UV"}];
DeleteDirectory[temp,DeleteContents->True];
FTTest`FTReport[];
