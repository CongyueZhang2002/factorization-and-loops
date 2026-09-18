Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
directory=CreateDirectory[];m=FeynCalc`GLI["SyntheticPoleFixture",{1}];
record=<|"Coefficients"-><|-3->7,-2->0,-1->0,0->1,1->2,2->3|>,
 "LaurentLowerBound"->-3,"KnownThroughOrder"->2|>;
fixture=<|"AllMasterValuesEvaluated"->True,"MasterCoefficients"-><|"Scalar"-><|m->1/e^2|>|>,
 "Values"-><|m->record|>,"DimensionalRegulator"->e,"CalculationDefinition"-><|"TestFixture"->True|>,
 "InputCompanions"-><||>,"MeasurementMoments"-><||>|>;
result=Internal`InheritedBlock[{FeynFacet`EvaluateMeasuredCurrentInclusiveMasters},
 Clear[FeynFacet`EvaluateMeasuredCurrentInclusiveMasters];
 FeynFacet`EvaluateMeasuredCurrentInclusiveMasters[___]:=fixture;
 FeynFacet`IntegrateMeasuredCurrentInclusiveRate[<|"EpsilonRange"->{0,0},"WorkDirectory"->directory|>]];
FTTest`FTAssert["a finite-only request still retains every implied raw lower pole",
 AssociationQ[result]&&result["StoredOrderRanges"]==={{-5,0}}&&
 result["Coefficients"][[Key[{1,-5}]]]===7&&result["Coefficients"][[Key[{1,0}]]]===3];
FTTest`FTAssert["the exact scalar contraction inputs remain with the inclusive rate",
 result["ScalarContractionInputs"]["MasterValues"]===fixture["Values"]&&
 result["ScalarContractionInputs"]["MasterCoefficients"]===fixture["MasterCoefficients"]];
If[DirectoryQ[directory],DeleteDirectory[directory,DeleteContents->True]];
Print["INCLUSIVE RATE POLES TEST COMPLETE"];FTTest`FTReport[];
