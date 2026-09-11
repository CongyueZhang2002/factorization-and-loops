$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
cfDirectory=root<>"/Projects/DrellYan_UU_NLO";
cfBorns=<||>;
Do[
 cfChannel=channel;cfDir=cfDirectory<>"/LO/"<>channel;
 cfCard=FeynFacet`ReadContributionCard[cfDir,"Born"];cfSetup=FeynFacet`ReadProcessCard[cfDir,"Born"];
 cfRequest=Join[FeynFacet`ProjectAssemblyRequest[cfCard,channel,"Born"],<|"EpsilonRange"->{0,2}|>];
 cfBorn=FeynFacet`ConstructBornResult[cfSetup,cfRequest];
 FTTest`FTAssert[channel<>" generated Drell-Yan Born has no current spin average",
  AssociationQ[cfBorn]&&cfBorn["Coefficients"][0]["DeltaCoefficient"]==={4/9}];
 FTTest`FTAssert[channel<>" retains the full-dimensional Born epsilon factor",
  AssociationQ[cfBorn]&&cfBorn["Coefficients"][1]["DeltaCoefficient"]==={-4/9}&&
  cfBorn["Coefficients"][2]["DeltaCoefficient"]==={0}];
 AssociateTo[cfBorns,channel->cfBorn],{channel,{"q-qbar","qbar-q"}}];
cfCard=FeynFacet`ReadContributionCard[cfDirectory<>"/NLO/q-qbar","Counterterm"];
cfRequest=Join[FeynFacet`ProjectAssemblyRequest[cfCard,"q-qbar","Real"],
 KeyTake[cfCard,{"Counterterms","Include","StructureFunctions","EpsilonRange"}]];
cfCT=FeynFacet`ConstructCurrentCollinearCounterterm[cfBorns,cfRequest];
cfKernel=FeynFacet`LeadingSplittingKernel[{"q","u"},{"q","u"},"U",z,cfCard["Counterterms"]["KernelParameters"]];
cfExpected=FeynFacet`Private`partonicMap[Function[value,{(4/9)FeynFacet`\[Alpha]s/Pi value}],
 KeyTake[cfKernel,{"DeltaCoefficient","PlusCoefficients","RegularCoefficient"}]];
FTTest`FTAssert["two incoming PDF poles both multiply the generated Born coefficient",
 AssociationQ[cfCT]&&FeynFacet`Private`partonicZeroTreeQ[
 FeynFacet`Private`partonicDistributionSum[{cfCT["Coefficients"][-1],
 FeynFacet`Private`partonicMap[Minus,cfExpected]},1]]];
FTTest`FTAssert["the Born epsilon coefficient contributes to the finite PDF counterterm",
 AssociationQ[cfCT]&&FeynFacet`Private`partonicZeroTreeQ[
 FeynFacet`Private`partonicMap[Factor,FeynFacet`Private`partonicDistributionSum[{cfCT["Coefficients"][0],
 FeynFacet`Private`partonicMap[Function[value,-(Log[muR2/muF2]-1)value],cfExpected]},1]]]];
cfShort=Map[Function[result,FeynFacet`CreatePartonicResult[KeyTake[result["Coefficients"],{0,1}],result]],cfBorns];
FTTest`FTAssert["epsilon-one output rejects Born dependencies truncated at epsilon one",
 FailureQ[FeynFacet`ConstructCurrentCollinearCounterterm[cfShort,cfRequest]]];
cfRealSetup=FeynFacet`ReadProcessCard[cfDirectory<>"/NLO/q-g","Real"];
FTTest`FTAssert["incoming gluon uses the other physical beam as its reference",
 cfRealSetup["SpinDensities"][[2]]["ReferenceMomentum"]===pa&&
 !MemberQ[cfRealSetup["PhysicalMomenta"],q]&&cfRealSetup["SummedGluons"]==={}];
FTTest`FTReport[];
