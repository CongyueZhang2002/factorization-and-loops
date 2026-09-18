$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Do[
 cpProject=FeynFacet`ReadProjectCard[root<>"/Projects/"<>project];
 Do[
  cpSetup=FeynFacet`ReadProcessCard[cpProject["Directory"]<>"/Raw/LO/"<>channel,"Born"];
  cpCard=FeynFacet`ReadContributionCard[cpProject["Directory"]<>"/Raw/LO/"<>channel,"Born"];
  cpRequest=Join[FeynFacet`ProjectAssemblyRequest[cpCard,channel,"Born"],
   <|"EpsilonRange"->{0,2},"BornCouplingPower"->0|>];
  cpResult=FeynFacet`ConstructBornResult[cpSetup,cpRequest];
  cpExpected=If[project==="SIDIS_UU",{Global`eU^2,0},{Global`eU^2}];
  FTTest`FTAssert[project<>"/"<>channel<>" generated absolute current Born normalization",
   AssociationQ[cpResult]&&cpResult["Coefficients"][0]["DeltaCoefficient"]["DeltaCoefficient"]===cpExpected];
  FTTest`FTAssert[project<>"/"<>channel<>" epsilon coverage is explicit and integral free",
   AssociationQ[cpResult]&&cpResult["EpsilonRange"]==={0,2}&&
   cpResult["Coefficients"][1]["DeltaCoefficient"]["DeltaCoefficient"]===0cpExpected&&
   cpResult["Coefficients"][2]["DeltaCoefficient"]["DeltaCoefficient"]===0cpExpected&&
   FreeQ[cpResult["Coefficients"],_Integrate|_FeynCalc`GLI|_SeriesData|_SeriesCoefficient]];
  FTTest`FTAssert[project<>"/"<>channel<>" current insertion is not assigned a hadron distribution",
   !KeyExistsQ[cpSetup,"HadronMomentum"]&&Length[cpSetup["SpinDensities"]]===2],
 {channel,{"q-q","qb-qb"}}],
 {project,{"SIDIS_UU","SIDIS_LL"}}];
FTTest`FTReport[];
