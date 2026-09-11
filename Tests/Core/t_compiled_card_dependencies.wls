$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Do[
 directory=root<>"/Projects/"<>project<>"/LO/"<>channel;
 card=FeynFacet`ReadContributionCard[directory,"Born"];
 setup=FeynFacet`ReadProcessCard[card];
 FTAssert[project<>" compiled and file-based process views agree",
  setup===FeynFacet`ReadProcessCard[directory,"Born"]];
 FTAssert[project<>" request selection comes from the compiled card",
  FeynFacet`ProjectAssemblyRequest[card]===FeynFacet`ProjectAssemblyRequest[card,channel,"Born"]];
 modified=card;modified["Assembly"]=Join[card["Assembly"],<|"Assumptions"->testCondition|>];
 FTAssert[project<>" in-memory contribution override is not replaced by a second disk read",
  FeynFacet`ProjectAssemblyRequest[modified]["Assumptions"]===testCondition],
 {selection,{{"SIDIS_UU_NNLO","q-q"},{"ppHX_TT_NLO","qqp-qqp"}}},
 {project,{First[selection]}},{channel,{Last[selection]}}];


nnloCard=FeynFacet`ReadContributionCard[root<>"/Projects/ppHX_UU_NNLO/NNLO/qqp-qqp","DoubleReal.Gluons"];
FTAssert["the shared request uses the actual perturbative order",
 FeynFacet`ProjectAssemblyRequest[nnloCard]["CouplingPower"]===nnloCard["BornCouplingPower"]+2&&
 FeynFacet`ProjectAssemblyRequest[card]["CouplingPower"]===card["BornCouplingPower"]];
FTAssert["a project without an explicit radiative order is not silently treated as NLO",
 FailureQ[FeynFacet`ProjectAssemblyRequest[FeynFacet`ReadProjectCard[
  root<>"/Projects/ppHX_UU_NNLO"],"qqp-qqp","Real"]]];
temp=CreateDirectory[];channel="q-q";
CopyFile[root<>"/Projects/SIDIS_UU_NNLO/card.wl",temp<>"/card.wl"];
CreateDirectory[temp<>"/LO/q-q/Cards",CreateIntermediateDirectories->True];
CopyFile[root<>"/Projects/SIDIS_UU_NNLO/LO/q-q/Cards/Born.wl",temp<>"/LO/q-q/Cards/Born.wl"];
project=FeynFacet`ReadProjectCard[temp];
card=FeynFacet`ReadContributionCard[temp<>"/LO/q-q","Born"];
setup=FeynFacet`ReadProcessCard[card];file=temp<>"/LO/q-q/Results/Result.wl";
dependency=<|"q-q"-><|"File"->file,"Order"->"LO","Channel"->"q-q",
 "EpsilonRange"->{0,2},"RequiredEpsilonRange"->{0,2}|>|>;
request=Join[FeynFacet`ProjectAssemblyRequest[card],FeynFacet`ProjectResultIdentity[card,setup],
 <|"EpsilonRange"->{0,3},"BornCouplingPower"->0|>];
born=FeynFacet`ConstructBornResult[setup,request];
FeynFacet`FamilyArtifactWrite[born,file];
generated=0;
Internal`InheritedBlock[{FeynFacet`ConstructBornResult},
 Clear[FeynFacet`ConstructBornResult];
 FeynFacet`ConstructBornResult[___]:=(generated++;Failure["UnexpectedGeneration",<||>]);
 reused=Catch[FeynFacet`Private`projectBornResults[project,dependency,"assemble"],"ProjectCards"];
 FTAssert["a richer compatible Born expansion is reused intact",
  reused["Results"]["q-q"]["EpsilonRange"]==={0,3}&&reused["StageSeconds"]===<||>&&generated===0];
 short=FeynFacet`CreatePartonicResult[KeyTake[born["Coefficients"],{0}],born];
 FeynFacet`FamilyArtifactWrite[short,file];
 rejected=Catch[FeynFacet`Private`projectBornResults[project,dependency,"assemble"],"ProjectCards"];
 FTAssert["assemble rejects insufficient Born orders without invoking generation",
  MatchQ[rejected,Failure["CompleteMatchingBornResultRequired",_]]&&generated===0];
 DeleteFile[file];
 rejected=Catch[FeynFacet`Private`projectBornResults[project,dependency,"assemble"],"ProjectCards"];
 FTAssert["assemble rejects a missing Born file without invoking generation",
  MatchQ[rejected,Failure["CompleteMatchingBornResultRequired",_]]&&generated===0];
];
regenerated=Catch[FeynFacet`Private`projectBornResults[project,dependency,"resume"],"ProjectCards"];
FTAssert["generated Borns pass the same identity and coverage check as reused Borns",
 AssociationQ[regenerated]&&regenerated["Results"]["q-q"]["EpsilonRange"]==={0,2}&&
 Keys[regenerated["StageSeconds"]]==={"LO/q-q"}];
DeleteDirectory[temp,DeleteContents->True];
FTReport[];
