(* Full compiled-card source generation in a consumer-owned project.
   The retained channel is an independent comparison input only. *)
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
fsRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];
Get[fsRoot<>"/Tests/TestKit.wl"];Block[{Print},Get[fsRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[fsRoot<>"/Tests/Support/CountertermComparison.wl"];
fsOutput=fsRoot<>"/Projects/ppHX_UU/Results/NLO/qqp-qqp/Validation/SourceOrders";
fsArguments=Rest[$ScriptCommandLine];
If[Length[fsArguments]>1,Print["Usage: check_fresh_scattering_sources.wls [owned-consumer-project]"];Exit[2]];
If[!DirectoryQ[fsOutput],CreateDirectory[fsOutput,CreateIntermediateDirectories->True]];
fsFresh=If[fsArguments==={},
 CreateDirectory[fsOutput<>"/FreshScatteringSourceProject"<>IntegerString[Round[AbsoluteTime[]]]],First[fsArguments]];
If[!StringStartsQ[fsFresh,fsOutput<>"/FreshScatteringSourceProject"],Print["FAILED CONSUMER PATH ",fsFresh];Exit[2]];
If[fsArguments==={},
 CopyFile[fsRoot<>"/Projects/ppHX_UU/Common-Card.wl",fsFresh<>"/Common-Card.wl"];
 CreateDirectory[fsFresh<>"/Raw/NNLO/qqp-qqp",CreateIntermediateDirectories->True]];
fsDirectory=fsFresh<>"/Raw/NNLO/qqp-qqp";
fsConsumer=FeynFacet`BuildCountertermProjectCard[fsDirectory];
If[!AssociationQ[fsConsumer],Print[fsConsumer];FTTest`FTAssert["source consumer compiles",False];FTTest`FTReport[]];
fsConsumer=Join[fsConsumer,<|"Execution"->Map[1&,fsConsumer["Execution"]]|>];
fsRequirements={<|"SourceOrder"->0,"SourceChannel"->"qqp-qqp","RequiredSourceThroughOrder"->2|>,
 <|"SourceOrder"->1,"SourceChannel"->"qqp-qqp","RequiredSourceThroughOrder"->1|>};
Print["FRESH SOURCE CONSUMER ",fsFresh];
FeynFacet`FamilyArtifactWrite[<|"ConsumerProject"->fsFresh,"ConsumerDirectory"->fsDirectory,
 "StartedFromEmptyResults"->(fsArguments==={}),"Requirements"->fsRequirements|>,fsOutput<>"/FreshScatteringSourcesInputs.wl"];
{fsSeconds,fsCatalog}=AbsoluteTiming[FeynFacet`GenerateBarePartonicSourceCatalog[fsConsumer,fsRequirements]];
FTTest`FTAssert["a fresh compiled-card pipeline generates the requested scattering LO and NLO sources",
 AssociationQ[fsCatalog]&&Keys[fsCatalog["Sources"]]==={0,1}&&
 Keys[fsCatalog["Sources"][0]]==={"qqp-qqp"}&&Keys[fsCatalog["Sources"][1]]==={"qqp-qqp"}];
If[!AssociationQ[fsCatalog],Print["FRESH SOURCE FAILURE ",System`Short[fsCatalog,12]];
 FeynFacet`FamilyArtifactWrite[<|"ConsumerProject"->fsFresh,"Seconds"->fsSeconds,"Failure"->fsCatalog|>,
  fsOutput<>"/FreshScatteringSourcesFailure.wl"];FTTest`FTReport[]];
fsLO=fsCatalog["Sources"][0]["qqp-qqp"];fsNLO=fsCatalog["Sources"][1]["qqp-qqp"];
FTTest`FTAssert["the generated bare sources retain LO epsilon two and NLO epsilon one",
 fsLO["EpsilonRange"]==={0,2}&&fsNLO["EpsilonRange"]==={-2,1}&&
 AllTrue[{fsLO,fsNLO},#["RenormalizationStage"]==="Bare"&]];
FTTest`FTAssert["source generation needs no sibling LO or NLO folder",
 !DirectoryQ[fsFresh<>"/LO"]&&!DirectoryQ[fsFresh<>"/NLO"]&&
 FileExistsQ[fsDirectory<>"/Counterterm/Work/Sources/LO/qqp-qqp/Results.wl"]&&
 FileExistsQ[fsDirectory<>"/Counterterm/Work/Sources/NLO/qqp-qqp/Results.wl"]];
fsComparisons=<||>;fsArtifacts=<||>;
Do[
 fsPath=fsDirectory<>"/Counterterm/Work/Sources/NLO/qqp-qqp/"<>fsKind;
 fsCard=FeynFacet`CompileBareSourceCard[fsConsumer,"NLO","qqp-qqp",fsKind,1];
 fsSetup=FeynFacet`ReadProcessCard[fsCard];
 fsPairCount=Times@@(Length/@Lookup[Lookup[fsSetup,{"ForwardAmplitudes","ConjugateAmplitudes"}],"DiagramIndices"]);
 fsPairs=FileNames["F*_C*.wl",fsPath<>"/Amplitudes/Pairs"];
 FTTest`FTAssert[fsKind<>" owns all generated interference pairs, Kira reduction and exact coefficients",
  Length[fsPairs]===fsPairCount&&fsPairCount>0&&
  FileExistsQ[fsPath<>"/Reduction/KiraStream/Manifest.wl"]&&FileExistsQ[fsPath<>"/Reduction/KiraResult.wl"]&&
  AssociationQ[FeynFacet`ReadMasterIntegralCoefficients[fsPath<>"/Reduction/CoefficientResult.wl"]]];
 fsNew=FeynFacet`ReadPartonicResult[fsPath<>"/Result.wl"];
 fsReference=FeynFacet`ReadPartonicResult[fsOutput<>"/RetainedInputAnalytic/"<>fsKind<>"Result.wl"];
 fsComparison=FTCountertermComparison`CompareResults[fsReference,fsNew,<|"EpsilonRange"->{-2,1},
  "ParameterRules"->fsConsumer["ColorRules"],"Assumptions"->fsConsumer["FinalAssumptions"]|>];
 FTTest`FTAssert[fsKind<>" fresh upstream result agrees with the independent retained-reduction calculation through epsilon one",
  AssociationQ[fsComparison]&&TrueQ[fsComparison["Passed"]]];
 AssociateTo[fsComparisons,fsKind->fsComparison];
 AssociateTo[fsArtifacts,fsKind-><|"PairFiles"->fsPairs,"Reduction"->fsPath<>"/Reduction/KiraResult.wl",
  "Coefficients"->fsPath<>"/Reduction/CoefficientResult.wl","Result"->fsPath<>"/Result.wl"|>],
 {fsKind,{"Real","Virtual"}}];
fsCombined=FeynFacet`CombinePartonicResults[Association@Table[fsKind->FeynFacet`ReadPartonicResult[
 fsDirectory<>"/Counterterm/Work/Sources/NLO/qqp-qqp/"<>fsKind<>"/Result.wl"],{fsKind,{"Real","Virtual"}}],
 <|"Contribution"->"Bare","RenormalizationStage"->"Bare"|>];
fsTotalComparison=FTCountertermComparison`CompareResults[fsCombined,fsNLO,<|"EpsilonRange"->{-2,1},
 "ParameterRules"->fsConsumer["ColorRules"],"Assumptions"->fsConsumer["FinalAssumptions"]|>];
FTTest`FTAssert["the source catalog retains the full real-plus-virtual bare Laurent density",
 AssociationQ[fsTotalComparison]&&TrueQ[fsTotalComparison["Passed"]]];
FeynFacet`FamilyArtifactWrite[<|"ConsumerProject"->fsFresh,"Seconds"->fsSeconds,
 "StageSeconds"->fsCatalog["StageSeconds"],"Artifacts"->fsArtifacts,"Comparisons"->fsComparisons,
 "BareSumComparison"->fsTotalComparison,"AcceptedResultsModified"->False|>,fsOutput<>"/FreshScatteringSources.wl"];
Print["COMPLETED FRESH SCATTERING SOURCE CHECKS ",fsFresh," SECONDS ",fsSeconds];
FTTest`FTReport[];
