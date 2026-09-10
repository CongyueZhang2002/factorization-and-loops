$HistoryLength=0;$MaxExtraPrecision=50;
prefixRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[prefixRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[prefixRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
prefixMaster=FeynCalc`GLI["prefixFamily",{1}];
prefixRaw=<|"PreFactor"->1,"Masters"->{<|"Master"->prefixMaster,"PreFactor"->1,"Coefficient"->0|>},
 "Remainder"->0,"Expression"->0,"Setup"-><||>,"FractionMeasure"->1,"PhaseSpace"->1|>;
prefixMerged=FeynFacet`Private`reconstructionMergeOrders[<|0->prefixRaw,1->prefixRaw|>,{ToString[prefixMaster,InputForm]},prefixE,1];
prefixFinal=FeynFacet`Private`coefficientResultFromReconstruction[prefixMerged];
FTTest`FTAssert["zero reconstructed finite prefix is retained",
 AssociationQ[prefixFinal]&&Length[prefixFinal["Masters"]]===1&&prefixFinal["ExactZeroMasterIntegrals"]==={}];
prefixEntry=First[prefixFinal["Masters"]];
FTTest`FTAssert["the known finite range is explicit",prefixEntry["Terms"][[1]]["Representation"]==="LaurentSeries"&&
 prefixEntry["Terms"][[1]]["Coefficient"]["Orders"]===<|0->0,1->0|>];
FTTest`FTAssert["zero prefix cannot supply an uncomputed order",
 FailureQ[FeynFacet`ExpandMasterIntegralCoefficient[prefixEntry,prefixFinal["DimensionalRegulator"],{0,2}]]];
FTTest`FTReport[];
