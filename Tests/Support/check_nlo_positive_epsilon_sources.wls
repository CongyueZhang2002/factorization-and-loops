(* Retained reduced coefficients isolate analytic epsilon-order propagation
   from upstream diagram generation and Kira. Accepted results are read-only. *)
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
peRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];
Get[peRoot<>"/Tests/TestKit.wl"];
peLoadSeconds=First[AbsoluteTiming[Block[{Print},Get[peRoot<>"/Addon/Load/LoadFACET.wl"]]]];$PrePrint=.;
Get[peRoot<>"/Tests/Support/CountertermComparison.wl"];
peArguments=Rest[$ScriptCommandLine];
peKinds=If[peArguments==={},{"Real","Virtual"},peArguments];
If[!SubsetQ[{"Real","Virtual"},peKinds]||!DuplicateFreeQ[peKinds],
 Print["Usage: check_nlo_positive_epsilon_sources.wls [Real|Virtual ...]"];Exit[2]];
peChannel=peRoot<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp";
peOutput=peRoot<>"/Projects/ppHX_UU/Results/NLO/qqp-qqp/Validation/SourceOrders/RetainedInputAnalytic";
If[!DirectoryQ[peOutput],CreateDirectory[peOutput,CreateIntermediateDirectories->True]];
peReports=<||>;
Do[
 peCard=FeynFacet`ReadContributionCard[peChannel,peKind];
 peInput=peCard["WorkDirectory"]<>"/Reduction/CoefficientResult.wl";
 peTable=FeynFacet`ReadMasterIntegralCoefficients[peInput];
 FTTest`FTAssert[peKind<>" retained coefficients are exact reduced amplitudes",
  AssociationQ[peTable]&&Length[peTable["Masters"]]>0&&peTable["RemainderTerms"]==={}&&
  AllTrue[Flatten[Lookup[peTable["Masters"],"Terms"]],#["Representation"]==="Exact"&]];
 If[!AssociationQ[peTable]||!AssociationQ[peCard],Print["FAILED INPUT ",System`Short[{peCard,peTable},5]];FTTest`FTReport[]];
 peRequest=Join[FeynFacet`ProjectAssemblyRequest[peCard],<|"EpsilonRange"->{-2,1}|>];
 peFunction=If[peKind==="Real",FeynFacet`ConstructNLORealContribution,FeynFacet`ConstructNLOVirtualContribution];
 FTTest`FTAssert[peKind<>" rejects conflicting epsilon upper-order declarations",
  FailureQ[peFunction[peTable,Join[peRequest,<|"ThroughOrder"->0|>]]]];
 {peSeconds,peResult}=AbsoluteTiming[peFunction[peTable,peRequest]];
 FTTest`FTAssert[peKind<>" propagates the requested positive epsilon order",
  AssociationQ[peResult]&&peResult["EpsilonRange"]==={-2,1}&&KeyExistsQ[peResult["Coefficients"],1]];
 If[!AssociationQ[peResult],Print["FAILED ANALYTIC ",System`Short[peResult,10]];
  FeynFacet`FamilyArtifactWrite[peResult,peOutput<>"/"<>peKind<>"Failure.wl"];FTTest`FTReport[]];
 peEpsilon=peResult["DimensionalRegulator"];
 FTTest`FTAssert[peKind<>" epsilon-one coefficients are explicit and regulator independent",
  FreeQ[peResult["Coefficients"],_Integrate|_SeriesData|_SeriesCoefficient|_FeynCalc`GLI|_Failure|_Missing]&&
  FreeQ[peResult["Coefficients"],peEpsilon]];
 peSymbols=DeleteDuplicates[Cases[peResult["Coefficients"][1],x_Symbol/;MemberQ[{"CA","CF","nU","nD"},SymbolName[x]],Infinity]];
 peColorValues=<|"CA"->3,"CF"->4/3,"nU"->2,"nD"->3|>;
 pePoint=Join[Thread[peRequest["Variables"]->{1/3,2/5}],
  {peRequest["Scale"]->5,peRequest["RenormalizationScaleSquared"]->7,peRequest["Coupling"]->1},
  (#->peColorValues[SymbolName[#]]&/@peSymbols)];
 peSample=N[peResult["Coefficients"][1]["DeltaCoefficient"]/.pePoint,30];
 FTTest`FTAssert[peKind<>" has a nonzero newly calculated epsilon-one coefficient",
  NumberQ[peSample]&&Abs[peSample]>10^-20];
 peScalars=FeynFacet`PartonicScalarCoefficientRules[peResult];
 pePositiveKeys=Select[Keys[peScalars],First[#]===1&];
 peMu=peRequest["RenormalizationScaleSquared"];
 peScaleResiduals=Association@Table[key->Cancel[Together[FeynFacet`ExpandPositiveLogarithms[
  peMu D[peScalars[[Key[key]]],peMu]-Lookup[peScalars,Key[ReplacePart[key,1->0]],0],
  peRequest["Assumptions"]]]],{key,pePositiveKeys}];
 FTTest`FTAssert[peKind<>" epsilon-one scale derivative equals its finite coefficient",
  Length[pePositiveKeys]>0&&AllTrue[Values[peScaleResiduals],#===0&]];
 peOld=FeynFacet`ReadPartonicResult[peCard["ResultFile"]];
 peComparison=FTCountertermComparison`CompareResults[peOld,peResult,<|"EpsilonRange"->{-2,0},
  "ParameterRules"->peRequest["ColorRules"],"Assumptions"->peRequest["Assumptions"]&&
    0<Last[peRequest["Variables"]]<1|>];
 FTTest`FTAssert[peKind<>" agrees exactly with every retained pole and finite scalar",
  AssociationQ[peComparison]&&TrueQ[peComparison["Passed"]]];
 FeynFacet`FamilyArtifactWrite[peResult,peOutput<>"/"<>peKind<>"Result.wl"];
 peEntry=<|"Input"->peInput,"Retained"->peCard["ResultFile"],
  "Result"->peOutput<>"/"<>peKind<>"Result.wl","CalculationSeconds"->peSeconds,
  "PackageLoadSeconds"->peLoadSeconds,"RequestedEpsilonRange"->{-2,1},
  "PositiveEpsilonSample"->peSample,"SamplePoint"->pePoint,
  "ScaleDerivativeResiduals"->peScaleResiduals,"Comparison"->peComparison|>;
 FeynFacet`FamilyArtifactWrite[peEntry,peOutput<>"/"<>peKind<>"Comparison.wl"];
 AssociateTo[peReports,peKind->peEntry];Print["POSITIVE EPSILON ",peKind," SECONDS ",peSeconds,
  " SAMPLE ",peSample," RETAINED SCALARS ",Lookup[peComparison,"ScalarCoefficientsCompared",0]],
 {peKind,peKinds}];
FeynFacet`FamilyArtifactWrite[<|"Contributions"->peReports,"PackageLoadSeconds"->peLoadSeconds,
 "AcceptedResultsModified"->False,"UpstreamRegenerated"->False|>,peOutput<>"/Report.wl"];
Print["COMPLETED NLO POSITIVE EPSILON SOURCE CHECKS"];
FTTest`FTReport[];
