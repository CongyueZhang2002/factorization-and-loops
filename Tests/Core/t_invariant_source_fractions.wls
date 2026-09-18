Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
frRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];
Get[frRoot<>"/Tests/TestKit.wl"];Block[{Print},Get[frRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
frOutput=frRoot<>"/Projects/ppHX_UU/Raw/NNLO/qqp-qqp/Results/Validation/CountertermUnification_2026-09-12";
frInputs=FeynFacet`FamilyArtifactRead[frOutput<>"/NLOOnlyInputs.wl"];
frDirectory=frInputs["SourceProject"]<>"/Raw/NNLO/qqp-qqp";
frPath=frDirectory<>"/Counterterm/Work/Sources/NLO/u-d_g";
frSource=FeynFacet`ReadPartonicResult[If[FileExistsQ[frOutput<>"/NLOOnlyBareEpsilonOne.wl"],
 frOutput<>"/NLOOnlyBareEpsilonOne.wl",frPath<>"/Result.wl"]];
frConsumer=FeynFacet`BuildCountertermProjectCard[frDirectory];
frCard=FeynFacet`CompileBareSourceCard[frConsumer,"NLO","u-d_g","Real",1];
frParts=<|"State01"->FeynFacet`ReadPartonicResult[frPath<>"/Real/State01/Result.wl"]|>;
frChecked=Catch[FeynFacet`Private`projectValidateInvariantFractions[frSource,frParts,frCard],"ProjectCards"];
FTTest`FTAssert["the generated observed-gluon density passes its actual setup momentum-fraction check unchanged",
 AssociationQ[frChecked]&&frChecked["Coefficients"]===frSource["Coefficients"]&&
 frChecked["MomentumFractionIndependence"]["Status"]==="Passed"&&
 Sort[SymbolName/@frChecked["MomentumFractionIndependence"]["Variables"]]==={"xa","xb","zh"}];
frFraction=First[List@@frParts["State01"]["ProcessDefinition"]["MomentumFraction"]][[1]];
frBad=FeynFacet`CreatePartonicResult[<|0-><|"DeltaCoefficient"->frFraction,
 "PlusCoefficients"-><||>,"RegularCoefficient"->0|>|>,KeyDrop[frSource,{"Coefficients","EpsilonRange"}]];
frRejected=Catch[FeynFacet`Private`projectValidateInvariantFractions[frBad,frParts,frCard],"ProjectCards"];
FTTest`FTAssert["a scalar density with an uncancelled incoming momentum fraction is rejected",
 MatchQ[frRejected,Failure["InvariantDensityMomentumFractionDependenceRemaining",_Association]]];
If[!AssociationQ[frChecked],Print["VALID SOURCE CHECK FAILURE ",frChecked]];
If[!FailureQ[frRejected],Print["CONTAMINATED SOURCE CHECK ",frRejected]];
FTTest`FTReport[];
