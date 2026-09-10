
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
directory=root<>"/Projects/SIDIS_UU_NNLO/NNLO/q-q";
setup=FeynFacet`ReadProcessCard[directory,"DoubleReal.DifferentFlavorDown"];
numeric=FeynFacet`GenerateCurrentAmplitudes[setup];
chargedSetup=Append[setup,"ElectromagneticCharges"-><|"UpType"->qa,"DownType"->qb|>];
charged=FeynFacet`GenerateCurrentAmplitudes[chargedSetup];
FTTest`FTAssert["symbolic charges enter generated current amplitudes",
 AssociationQ[charged]&&!FreeQ[charged["Amplitudes"],qa]&&!FreeQ[charged["Amplitudes"],qb]];
exprs=Values[charged["Amplitudes"]["Amplitude"]];
polynomials=FeynCalc`DotSimplify[#,Expanding->False]&/@exprs;
physical=Values[numeric["Amplitudes"]["Amplitude"]];
FTTest`FTAssert["each generated graph has exactly one current charge",
 AllTrue[polynomials,PolynomialQ[#, {qa,qb}]&&AllTrue[First/@CoefficientRules[#, {qa,qb}],Total[#]===1&]&]];
FTTest`FTAssert["standard charges recover the original generated amplitudes",
 Length[exprs]===Length[physical]&&AllTrue[
 MapThread[Expand[#1/.{qa->2/3,qb->-1/3}]-Expand[#2]&,{exprs,physical}],
 FeynCalc`Contract[#]===0&]];
restored=FeynFacet`GenerateCurrentAmplitudes[setup];
FTTest`FTAssert["subsequent standard-model calculations restore the original vertex",
 AssociationQ[restored]&&Values[restored["Amplitudes"]["Amplitude"]]===physical];
FTTest`FTReport[];
