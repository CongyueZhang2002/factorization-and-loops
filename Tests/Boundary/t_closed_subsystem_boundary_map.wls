Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[rho,e];
prep=FeynFacet`PrepareSingularBoundarySystem[<|"Variable"->rho,"DimensionalRegulator"->e,
 "ConnectionMatrix"->{{-2e/rho,0,0},{1,0,0},{0,0,-4e/rho}}|>];
selection=FeynFacet`SelectFrobeniusModesByRegulatorSlope[prep["PrimaryDecomposition"],-2];
map=FeynFacet`ConstructClosedSubsystemBoundaryMap[prep,{1,2},selection];
FTAssert["exact local restriction separates one invisible amplitude while retaining a sourced output",
 AssociationQ[map]&&map["GenericRank"]===1&&map["ExactResidueIntertwiner"]&&
 map["NoFiniteEpsilonTruncation"]&&Dimensions[map["HomogeneousUnobservedAmplitudeBasis"]]==={2,1}];
FTAssert["a row with an external source cannot masquerade as a closed subsystem",
 MatchQ[FeynFacet`ConstructClosedSubsystemBoundaryMap[prep,{2},selection],
  Failure["OriginalCoordinateSubsystemMustBeClosed",_]]];
changed=FeynFacet`ConstructClosedSubsystemBoundaryMap[prep,{1,2},selection,
 <|"AmplitudeBasisChange"->{{1,e^-2},{0,1}}|>];
FTAssert["meromorphic amplitude changes preserve the generic rank and exact restriction",
 AssociationQ[changed]&&changed["GenericRank"]===1&&
 Simplify[changed["MatchingMatrix"]-map["MatchingMatrix"].{{1,e^-2},{0,1}}]===ConstantArray[0,{2,2}]];
nilpotent=FeynFacet`PrepareSingularBoundarySystem[<|"Variable"->rho,"DimensionalRegulator"->e,
 "ConnectionMatrix"->{{-2e/rho,0,0},{1/rho,-2e/rho,0},{0,0,-4e/rho}}|>];
nilSelection=FeynFacet`SelectFrobeniusModesByRegulatorSlope[nilpotent["PrimaryDecomposition"],-2];
nilMap=FeynFacet`ConstructClosedSubsystemBoundaryMap[nilpotent,{1,2},nilSelection];
FTAssert["the map retains both directions of a logarithmic Jordan chain",
 AssociationQ[nilMap]&&nilMap["GenericRank"]===2&&
 Max[#["Jet"]["MaximumLogarithmPower"]&/@nilMap["PrimaryJets"]]>0];
Print["CLOSED SUBSYSTEM BOUNDARY MAP TEST COMPLETE"];FTReport[];
