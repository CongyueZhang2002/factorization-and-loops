Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
nsRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];
Get[nsRoot<>"/Tests/TestKit.wl"];Block[{Print},Get[nsRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
nsOutput=nsRoot<>"/Projects/ppHX_UU/Results/NLO/qqp-qqp/Validation/SourceOrders";
nsInputs=FeynFacet`FamilyArtifactRead[nsOutput<>"/NLOOnlyInputs.wl"];
nsProject=nsInputs["SourceProject"];nsDirectory=nsProject<>"/Raw/NNLO/qqp-qqp";
nsBarePath=nsDirectory<>"/Counterterm/Work/Sources/NLO/u-d_g/Results.wl";
nsBare=FeynFacet`ReadPartonicResult[If[FileExistsQ[nsOutput<>"/NLOOnlyBareEpsilonOne.wl"],
 nsOutput<>"/NLOOnlyBareEpsilonOne.wl",nsBarePath]];
FTTest`FTAssert["the NLO-only bare input has its previously generated positive epsilon order",
 AssociationQ[nsBare]&&nsBare["EpsilonRange"]==={-2,1}];
If[!FileExistsQ[nsOutput<>"/NLOOnlyBareEpsilonOne.wl"],
 FeynFacet`FamilyArtifactWrite[nsBare,nsOutput<>"/NLOOnlyBareEpsilonOne.wl"]];
nsCard=FeynFacet`BuildCountertermProjectCard[nsDirectory];
nsCard=Join[nsCard,<|"SourceOrder"->"NLO","SourceChannel"->"u-d_g",
 "SourceRenormalizationStage"->"Renormalized","Execution"->Map[1&,nsCard["Execution"]]|>];
{nsSeconds,nsCatalog}=AbsoluteTiming[FeynFacet`ConstructSubtractedPartonicSourceCatalog[nsCard]];
FTTest`FTAssert["raw UV and collinear subtraction cancels every NLO-only pole exactly",
 AssociationQ[nsCatalog]&&TrueQ[nsCatalog["RawSchemePoleCancellation"]]];
If[!AssociationQ[nsCatalog],Print["NLO ONLY SUBTRACTION FAILURE ",System`Short[nsCatalog,15]];
 FeynFacet`FamilyArtifactWrite[<|"Failure"->nsCatalog,"CalculationSeconds"->nsSeconds|>,nsOutput<>"/NLOOnlySubtractionFailure.wl"];
 FTTest`FTReport[]];
nsResult=nsCatalog["Sources"][1]["u-d_g"];
FTTest`FTAssert["the subtracted observed-gluon source is finite and remains in the raw operator scheme",
 nsResult["EpsilonRange"]==={0,0}&&nsResult["RenormalizationStage"]==="Renormalized"&&
 nsResult["RawSchemePoleCancellation"]===True&&nsResult["FiniteSchemeConversionApplied"]===False];
nsAuxiliary=DeleteDuplicates[Cases[nsResult["Coefficients"],q_Symbol/;MemberQ[{"xa","xb","zh"},SymbolName[q]],Infinity]];
FTTest`FTAssert["the finite NLO-only hard density is explicit and free of auxiliary fractions",
 nsAuxiliary==={}&&FreeQ[nsResult["Coefficients"],_Integrate|_SeriesData|_SeriesCoefficient|_FeynCalc`GLI|_Failure|_Missing]];
FTTest`FTAssert["subtraction generates physical Born neighbors without a nonexistent same-channel Born or virtual source",
 Length[nsCatalog["Sources"][0]]>0&&!KeyExistsQ[nsCatalog["Sources"][0],"u-d_g"]&&
 !DirectoryQ[nsProject<>"/LO"]&&!DirectoryQ[nsProject<>"/NLO"]&&
 !DirectoryQ[nsDirectory<>"/Counterterm/Work/Sources/NLO/u-d_g/Virtual"]];
FeynFacet`FamilyArtifactWrite[nsResult,nsOutput<>"/NLOOnlySubtractedResult.wl"];
FeynFacet`FamilyArtifactWrite[<|"SourceProject"->nsProject,"CalculationSeconds"->nsSeconds,
 "BornSourceChannels"->Keys[nsCatalog["Sources"][0]],"PoleCancellation"->nsCatalog["RawSchemePoleCancellation"],
 "OriginalBareEpsilonOne"->nsOutput<>"/NLOOnlyBareEpsilonOne.wl",
 "Result"->nsOutput<>"/NLOOnlySubtractedResult.wl","AcceptedResultsModified"->False|>,nsOutput<>"/NLOOnlySubtraction.wl"];
Print["COMPLETED NLO ONLY RAW SUBTRACTION CHECKS SECONDS ",nsSeconds];
FTTest`FTReport[];
