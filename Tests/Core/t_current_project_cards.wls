$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Do[
 cpProject=FeynFacet`ReadProjectCard[root<>"/Projects/"<>project];
 Do[
  cpSetup=FeynFacet`ReadProcessCard[cpProject["Directory"]<>"/LO/"<>channel,"Born"];
  cpCard=FeynFacet`ReadContributionCard[cpProject["Directory"]<>"/LO/"<>channel,"Born"];
  cpRequest=Join[FeynFacet`Private`projectAssemblyRequest[cpCard,channel,"Born"],
   <|"EpsilonRange"->{0,2},"BornCouplingPower"->0|>];
  cpResult=FeynFacet`ConstructBornResult[cpSetup,cpRequest];
  cpExpected=If[project==="SIDIS_UU_NNLO",{4/9,0},{4/9}];
  FTTest`FTAssert[project<>"/"<>channel<>" generated absolute current Born normalization",
   AssociationQ[cpResult]&&cpResult["Coefficients"][0]["DeltaCoefficient"]["DeltaCoefficient"]===cpExpected];
  FTTest`FTAssert[project<>"/"<>channel<>" epsilon coverage is explicit and integral free",
   AssociationQ[cpResult]&&cpResult["EpsilonRange"]==={0,2}&&
   cpResult["Coefficients"][1]["DeltaCoefficient"]["DeltaCoefficient"]===0cpExpected&&
   cpResult["Coefficients"][2]["DeltaCoefficient"]["DeltaCoefficient"]===0cpExpected&&
   FreeQ[cpResult["Coefficients"],_Integrate|_FeynCalc`GLI|_SeriesData|_SeriesCoefficient]];
  FTTest`FTAssert[project<>"/"<>channel<>" current insertion is not assigned a hadron distribution",
   !KeyExistsQ[cpSetup,"HadronMomentum"]&&Length[cpSetup["SpinDensities"]]===2],
 {channel,{"q-q","qbar-qbar"}}],
 {project,{"SIDIS_UU_NNLO","SIDIS_LL_NNLO"}}];
FTTest`FTReport[];
