
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
chart=<|"Variables"->{fu,ft},"OriginalVariables"->{fx,fy},"ExponentMatrix"->{{2,4},{0,2}}|>;
jets=<|"Status"->"ContractedPhysicalEndpointJetsConstructed","NormalVariable"->fu,
 "TangentialVariable"->ft,"NormalExponent"->2fa fe,"CoefficientMatrices"-><|-1->{{4ft^(4fa fe+1) fA[ft^2]}}|>|>;
mapped=FeynFacet`MapEndpointFaceCoefficientJets[chart,jets];
FTAssert["ramified ordinary face includes its regulator-dependent unit and Jacobian",
 AssociationQ[mapped]&&mapped["NormalExponent"]===fa fe&&
 Simplify[mapped["CoefficientMatrices"][-1][[1,1]],ft>0]===fA[ft^2]];
FTAssert["the positive tangential inverse is explicit",
 mapped["OutputCoordinateRules"]==={ft->Sqrt[fy]}&&mapped["NormalVariable"]===fx];
higher=Join[jets,<|"CoefficientMatrices"-><|1->{{4ft^(4(1+fa fe)+1) fA[ft^2]}}|>|>];
mappedHigher=FeynFacet`MapEndpointFaceCoefficientJets[chart,higher,<|"IntegerNormalPower"->1|>];
FTAssert["integer normal powers are converted by the full density exponent",
 Keys[mappedHigher["CoefficientMatrices"]]==={0}&&
 Simplify[mappedHigher["CoefficientMatrices"][0][[1,1]],ft>0]===fA[ft^2]];
exceptional=Join[chart,<|"ExponentMatrix"->{{2,4},{2,2}}|>];
FTAssert["an exceptional face is not treated as an original open face",
 FailureQ[FeynFacet`MapEndpointFaceCoefficientJets[exceptional,jets]]];
FTReport[];
