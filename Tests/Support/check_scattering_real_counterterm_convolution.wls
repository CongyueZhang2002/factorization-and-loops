(* Physical non-Born convolution of a regenerated real NLO density through
   epsilon one. The saved input is a validation artifact; no accepted result
   or retained upstream reduction is modified. *)
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
rcRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[rcRoot<>"/Tests/TestKit.wl"];
rcLoad=First[AbsoluteTiming[Block[{Print},Get[rcRoot<>"/Addon/Load/LoadFACET.wl"]]]];$PrePrint=.;
rcBase=rcRoot<>"/Projects/ppHX_UU/Results/NLO/qqp-qqp/Validation/SourceOrders";
rcInput=rcBase<>"/RetainedInputAnalytic/RealResult.wl";
rcArguments=Rest[$ScriptCommandLine];
rcOutput=rcBase<>"/RealCountertermConvolution"<>
 If[rcArguments==={},"","/"<>First[rcArguments]];
If[!DirectoryQ[rcOutput],CreateDirectory[rcOutput,CreateIntermediateDirectories->True]];
rcSource=FeynFacet`ReadPartonicResult[rcInput];
rcCard=FeynFacet`ReadContributionCard[rcRoot<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp","Real"];
rcAssembly=FeynFacet`ProjectAssemblyRequest[rcCard];
FTTest`FTAssert["the realistic real source has explicit poles and positive epsilon coefficients",
 AssociationQ[rcSource]&&rcSource["Order"]==="NLO"&&rcSource["EpsilonRange"]==={-2,1}&&
 rcSource["Coefficients"][1]["RegularCoefficient"]=!=0];
rcE=rcSource["DimensionalRegulator"];
rcKernel=FeynFacet`PDFCountertermDistribution[{"q","u"},{"q","u"},
 <|"Spin"->"U","Variable"->rcXi,"DimensionalRegulator"->rcE,
 "KernelParameters"-><|"CA"->FeynCalc`CA,"CF"->FeynCalc`CF,"TR"->1/2,"FlavorCount"->Global`nU+Global`nD|>,
 "PerturbativeOrder"->1,"PoleNormalization"->1,"ScaleLog"->0,
 "Operation"->"CollinearSubtraction"|>];
rcRequest=<|"Convolution"->"InvariantSingleInclusive","Leg"->"IncomingA","Order"->"NNLO",
 "Scale"->rcSource["Scale"],"Variables"->rcSource["Variables"],
 "PerturbativeParameter"->rcAssembly["Coupling"]/(2Pi),"EpsilonRange"->{-3,0}|>;
(* Optional diagnostic records the general final coefficient collector without
   changing its expression, limits, or algebra. *)
If[MemberQ[Rest[rcArguments],"profile"],
 rcCollectionIndex=0;rcCollectionLargest=0;rcCollectionRecords={};
 DownValues[rcOriginalPartonicCollect]=DownValues[FeynFacet`Private`partonicCollect]/.
  FeynFacet`Private`partonicCollect->rcOriginalPartonicCollect;
 FeynFacet`Private`partonicCollect[value_]:=Module[{index,leaves,seconds,answer},
  index=++rcCollectionIndex;leaves=LeafCount[value];
  Print["FINAL COLLECTION START ",index," INPUT LEAVES ",leaves];
  If[leaves>rcCollectionLargest,
   rcCollectionLargest=leaves;
   FeynFacet`FamilyArtifactWrite[value,rcOutput<>"/LargestCollectionInput.wl"]];
  {seconds,answer}=AbsoluteTiming[rcOriginalPartonicCollect[value]];
  AppendTo[rcCollectionRecords,<|"Index"->index,"InputLeaves"->leaves,
   "OutputLeaves"->LeafCount[answer],"Seconds"->seconds|>];
  FeynFacet`FamilyArtifactWrite[rcCollectionRecords,rcOutput<>"/CollectionStages.wl"];
  Print["FINAL COLLECTION DONE ",index," SECONDS ",seconds,
   " OUTPUT LEAVES ",LeafCount[answer]];answer]
];
Print["STARTING PHYSICAL REAL CONVOLUTION"];
{rcSeconds,rcAudit}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ApplyCountertermDistribution[rcSource,rcKernel,rcRequest]]];
rcResult=rcAudit["Result"];
FeynFacet`FamilyArtifactWrite[rcResult,rcOutput<>"/Result.wl"];
rcReport=<|"Input"->rcInput,"Kernel"->rcKernel,"Request"->rcRequest,
 "PackageLoadSeconds"->rcLoad,"CalculationSeconds"->rcSeconds,
 "EpsilonRemainderAudit"->rcAudit["EpsilonRemainderAudit"],
 "Passed"->AssociationQ[rcResult],"Result"->rcOutput<>"/Result.wl"|>;
FeynFacet`FamilyArtifactWrite[rcReport,rcOutput<>"/Report.wl"];
If[!AssociationQ[rcResult],Print["PHYSICAL CONVOLUTION FAILURE TAGS ",
 DeleteDuplicates[Cases[rcResult,Failure[tag_,_]:>tag,{0,Infinity}]]]];
FTTest`FTAssert["the full real density convolves through the requested finite counterterm coefficient",
 AssociationQ[rcResult]&&rcResult["EpsilonRange"]==={-3,0}&&
 FreeQ[rcResult["Coefficients"],_Integrate|_NIntegrate|_Inactive|_SeriesData|_Failure|_Missing]];
FTTest`FTAssert["the physical convolution passes all nonempty epsilon remainder checks",
 rcAudit["EpsilonRemainderAudit"]["Status"]==="Passed"];
Print["PHYSICAL REAL CONVOLUTION SECONDS ",rcSeconds];
FTTest`FTReport[];
