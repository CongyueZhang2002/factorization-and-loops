#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[tbZ,tbV,tbE];
tbR={{tbE,1},{0,2tbE}};
tbEndpoint=ConstructTangentialEndpointSystem[
 <|"NormalVariable"->tbZ,"TangentialVariable"->tbV,"DimensionalRegulator"->tbE,
 "NormalConnectionMatrix"->tbR/tbZ,"TangentialConnectionMatrix"->ConstantArray[0,{2,2}]|>,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"0<v<1",
 "BranchPrescription"->"Positive z real logarithm"|>,"NormalGaugeMatrix"->IdentityMatrix[2]];
tbReference=<|"TangentialBasePoint"->1/4,
 "NormalizedDifferentialSystem"-><|"Variable"->tbZ,"DimensionalRegulator"->tbE,
 "ConnectionMatrix"->tbR/tbZ|>,"OriginalToNormalizedGauge"->IdentityMatrix[2],
 "SeedMatrix"->IdentityMatrix[2]|>;
tbMatching=MatchTangentialEndpointBoundaryBasis[tbEndpoint,tbReference];
tbBounds=DetermineTangentialEndpointLaurentBounds[tbEndpoint,tbMatching,{0,0}];
FTAssert["the epsilon-expanded total has regular original coefficients",
 AssociationQ[tbBounds] && tbBounds["OriginalMasterIntegralLaurentLowerBounds"]==={0,0}];
FTAssert["individual generic-exponent sectors retain cancelling epsilon poles",
 AssociationQ[tbBounds] &&
 tbBounds["UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"][tbE]==={-1,Infinity} &&
 tbBounds["UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"][2tbE]==={-1,0}];
tbSelected=MatchTangentialEndpointBoundaryBasis[tbEndpoint,
 Join[tbReference,<|"SeedMatrix"->{{1},{tbE}}|>]];
tbSelectedBounds=DetermineTangentialEndpointLaurentBounds[tbEndpoint,tbSelected,{0}];
FTAssert["physical seed composition precedes primary-sector valuation",
 AssociationQ[tbSelectedBounds] &&
 tbSelectedBounds["UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"][tbE]==={Infinity,Infinity}];
FTReport[];
