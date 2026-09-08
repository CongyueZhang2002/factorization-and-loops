
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Get[root<>"/Tests/TestKit.wl"];
expansion=<|"Variable"->zz,"DimensionalRegulator"->ee,"ResidueEigenvalue"->-2ee,
 "MaximumNormalOrder"->0,"MaximumLogarithmPower"->1,
 "Coefficients"->{{IdentityMatrix[2],{{0,1},{0,0}}}}|>;
defs=Association@Table[i-><|"NormalExponent"->-2ee,"LogarithmPower"->0,"PhysicalLimitEstablished"->True,
 "VanishingLogarithmCoefficientsAtThisPower"->True,"IntegralEquivalenceKey"->{"same",ee},
 "IntegralScaleFactor"->If[i===1,2,1]|>,{i,2}];
m=FeynFacet`MatchPhysicalBoundaryCoefficients[expansion,IdentityMatrix[2],defs];
FTAssert["forbidden logarithm fixes its generalized-eigenvector amplitude",
 AssociationQ[m]&&Lookup[m["HomogeneousAmplitudeRelations"],"AmplitudeRow"]==={{0,1}}&&
 Lookup[m["LeadingCoefficientRows"],"AmplitudeRow"]===IdentityMatrix[2]];
r=FeynFacet`ReduceIdenticalBoundaryIntegrals[m,defs,ee];
FTAssert["identical integrals preserve the exact scale ratio",
 AssociationQ[r]&&First[r["AmplitudeRelations"]]["AmplitudeRow"]==={-1/2,1}];
bad=FeynFacet`MatchPhysicalBoundaryCoefficients[expansion,DiagonalMatrix[{1/zz,1}],defs];
FTAssert["insufficient normal order is rejected",FailureQ[bad]];
bad=FeynFacet`MatchPhysicalBoundaryCoefficients[expansion,IdentityMatrix[2],defs/.(-2ee)->(-3ee)];
FTAssert["different primary exponent is rejected",FailureQ[bad]];
bad=FeynFacet`MatchPhysicalBoundaryCoefficients[expansion,IdentityMatrix[2],KeyDrop[#,"PhysicalLimitEstablished"]&/@defs];
FTAssert["an integral representation alone does not establish a physical limit",FailureQ[bad]];
FTReport[];
