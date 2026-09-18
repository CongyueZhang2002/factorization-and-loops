$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
cfDirectory=root<>"/Projects/DrellYan_UU";
cfCard=FeynFacet`BuildCountertermProjectCard[cfDirectory<>"/Raw/NLO/q-qb"];
(* Generated dependencies belong to a temporary consuming NLO directory. *)
cfTemp=CreateDirectory[];
CopyFile[cfDirectory<>"/Common-Card.wl",cfTemp<>"/Common-Card.wl"];
CreateDirectory[cfTemp<>"/Raw/NLO/q-qb",CreateIntermediateDirectories->True];
cfConsumer=FeynFacet`BuildCountertermProjectCard[cfTemp<>"/Raw/NLO/q-qb"];
cfGenerated=FeynFacet`GenerateBornPartonicSources[cfConsumer,<|"q-qb"->2,"qb-q"->2|>];
cfBorns=cfGenerated["Results"];
Do[
 cfBorn=cfBorns[channel];
 FTTest`FTAssert[channel<>" generated Drell-Yan Born has no current spin average",
  AssociationQ[cfBorn]&&cfBorn["Coefficients"][0]["DeltaCoefficient"]==={4/9}];
 FTTest`FTAssert[channel<>" retains the full-dimensional Born epsilon factor",
  AssociationQ[cfBorn]&&cfBorn["Coefficients"][1]["DeltaCoefficient"]==={-4/9}&&
  cfBorn["Coefficients"][2]["DeltaCoefficient"]==={0}],{channel,{"q-qb","qb-q"}}];
cfRequest=Join[FeynFacet`ProjectAssemblyRequest[cfCard,"q-qb","Real"],
 KeyTake[cfCard,{"Counterterms","Include","StructureFunctions","EpsilonRange"}]];
cfSpec=<|"Spin"->"U","Variable"->z,"DimensionalRegulator"->Global`Epsilon,
 "KernelParameters"->cfCard["Counterterms"]["KernelParameters"],"PerturbativeOrder"->1,
 "ScaleLog"->Log[muF2]-Log[muR2],"OperatorScheme"->"MSbar"|>;
cfPDF=FeynFacet`PDFCountertermDistribution[{"q","u"},{"q","u"},cfSpec];
cfInsertion=<|"Convolution"->"Mellin","PerturbativeParameter"->FeynFacet`\[Alpha]s/(2Pi),
 "EpsilonRange"->{-1,1}|>;
cfOneLeg=FeynFacet`ApplyCountertermDistribution[cfBorns["q-qb"],cfPDF,cfInsertion];
cfCT=FeynFacet`CreatePartonicResult[Map[
 FeynFacet`Private`partonicMap[Function[value,2value],#]&,cfOneLeg["Coefficients"]],cfOneLeg];
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
 FeynFacet`Private`partonicMap[Function[value,-(Log[muR2]-Log[muF2]-1)value],cfExpected]},1]]]];
cfShort=Map[Function[result,FeynFacet`CreatePartonicResult[KeyTake[result["Coefficients"],{0,1}],result]],cfBorns];
FTTest`FTAssert["epsilon-one output rejects Born dependencies truncated at epsilon one",
 FailureQ[FeynFacet`ApplyCountertermDistribution[cfShort["q-qb"],cfPDF,cfInsertion]]];
cfRealSetup=FeynFacet`ReadProcessCard[cfDirectory<>"/Raw/NLO/q-g","Real"];
FTTest`FTAssert["incoming gluon uses the other physical beam as its reference",
 cfRealSetup["SpinDensities"][[2]]["ReferenceMomentum"]===pa&&
 !MemberQ[cfRealSetup["PhysicalMomenta"],q]&&cfRealSetup["SummedGluons"]==={}];
DeleteDirectory[cfTemp,DeleteContents->True];
FTTest`FTReport[];
