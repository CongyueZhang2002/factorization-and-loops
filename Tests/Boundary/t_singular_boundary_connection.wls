$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[z,eps];
moving=RemoveCoalescingApparentSingularities[<|"Variable"->z,
 "DimensionalRegulator"->eps,"ConnectionMatrix"->{{1/(z+eps)-2eps/z}}|>];
FTAssert["a coalescing apparent pole is removed by an exact rational gauge",
 AssociationQ[moving]&&moving["RemovedLocations"]==={-eps}&&
 moving["ConnectionMatrix"]==={{-2eps/z}}&&
 RegularSingularGaugeMatrix[moving]==={{eps+z}}];
unsafe=ConstructFrobeniusBoundaryExpansion[<|"Variable"->z,
 "DimensionalRegulator"->eps,"ConnectionMatrix"->{{1/(z+eps)-2eps/z}}|>,
 {{1}},<|"MaximumNormalOrder"->2,"EpsilonOrderRange"->{0,2}|>];
FTAssert["the joint expansion rejects a coalescing pole before interchanging limits",
 MatchQ[unsafe,Failure["NonanalyticJointLocalCoefficient",_]]];

sat=SaturateLaurentColumnBasis[{{1/eps,1/eps},{1,0}},eps];
FTAssert["Laurent saturation preserves the generic column space and full leading rank",
 AssociationQ[sat]&&sat["LeadingRank"]===2&&
 Simplify[{{1/eps,1/eps},{1,0}}.sat["BasisChangeMatrix"]-sat["Basis"]]===ConstantArray[0,{2,2}]&&
 MatrixRank[sat["Basis"]/.eps->0]===2];

kk={{0,0},{1,0}};rr=-2eps IdentityMatrix[2]+kk;
gg=IdentityMatrix[2]+z^-4 kk;bb=rr/z+eps IdentityMatrix[2]-4z^-5 kk;
cutoff=DetermineBoundaryCountertermOrder[bb,gg,{z,eps},{0,5}];
FTAssert["the sharp higher-pole example requires exactly normal order four",
 AssociationQ[cutoff]&&cutoff["MaximumNormalOrder"]===4&&
 cutoff["RemainderNormalPowerLowerBounds"]==={5,1}];

original={{-2eps/z,0,0,0},{1,(1-2eps)/z,0,0},
 {1/(1-z),0,1/z,0},{0,0,1/z,1/z}};
normal=NormalizeRegularSingularSystem[<|"Variable"->z,
 "DimensionalRegulator"->eps,"ConnectionMatrix"->original|>];
FTAssert["integer-resonant sourced blocks are normalized without discarding a direction",
 AssociationQ[normal]&&normal["Dimension"]===4&&And@@normal["Verification"]["Checks"]];
decomposition=DecomposeResidueEigenspaces[normal];
FTAssert["the retained generic-epsilon eigenspace contains both Jordan directions",
 AssociationQ[decomposition]&&Length[
  SelectFirst[decomposition["Eigenspaces"],#["Exponent"]===-2eps&]["Columns"]]===2];
a=normal["ConnectionMatrix"];g=RegularSingularGaugeMatrix[normal];
seed={{eps^2,0},{0,1},{-eps/2,0},{1/4,0}};
FTAssert["the chosen seed retains the logarithmic chain at generic epsilon",
 Simplify[MatrixPower[normal["Residue"]+2eps IdentityMatrix[4],2].seed]===
   ConstantArray[0,{4,2}]&&
 Simplify[(normal["Residue"]+2eps IdentityMatrix[4]).seed]=!=ConstantArray[0,{4,2}]];
make[depth_]:=Module[{jet},
 jet=ConstructFrobeniusBoundaryExpansion[<|"Variable"->z,"DimensionalRegulator"->eps,
  "ConnectionMatrix"->a|>,seed,<|"MaximumNormalOrder"->depth,"EpsilonOrderRange"->{0,2}|>];
 ConstructBoundaryConnection[<|"NormalizedDifferentialSystem"-><|"Variable"->z,
  "DimensionalRegulator"->eps,"ConnectionMatrix"->a|>,
  "PreparedDifferentialSystem"-><|"ConnectionMatrices"->{a},"BasisTransformationMatrix"->g|>,
  "FrobeniusExpansion"->jet,"NormalizedToPreparedGauge"->IdentityMatrix[4],
  "NormalizedToOriginalGauge"->g|>,<||>,"EndpointPower"->8,"ContourDeformation"->1/4]];
first=make[0];second=make[1];
FTAssert["the output contains finite residual integrals at both valid cutoffs",
 AssociationQ[first]&&AssociationQ[second]&&first["FiniteNormalCoordinateSolution"]&&
 second["FiniteNormalCoordinateSolution"]&&Length[first["IntegralDefinitions"]]>0];
Block[{Print},Get[root<>"/FeynFacet/Solution.m"]];
evaluate[q_]:=EvaluateMasterIntegralSolution[q,{1/3},"NumericalBackend"->"Wolfram",
 "WorkingPrecision"->50,"QuadratureOrder"->80,"CheckConvergence"->False,"PathCheck"->None];
one=evaluate[first];two=evaluate[second];
FTAssert["both finite residual solutions evaluate",
 AssociationQ[one]&&AssociationQ[two]];
If[AssociationQ[one]&&AssociationQ[two],
 expected=N[<|
  0->{{0,0},{0,1/3},{0,0},{1/12,0}},
  1->{{0,0},{0,-2Log[1/3]/3},{-1/6,0},{-Log[1/3]/6,0}},
  2->{{1,0},{Log[1/3]/3,2Log[1/3]^2/3},
       {(Log[1/3]-Log[2/3])/3,0},{Log[1/3]^2/6+PolyLog[2,1/3]/3,0}}|>,40];
 difference=Max[Abs[Flatten[Values[one["EpsilonCoefficients"]-expected]]]];
 If[!TrueQ[difference<10^-16],Print["INDEPENDENT DIFFERENCE ",N[one["EpsilonCoefficients"]-expected,12]]];
 FTAssert["the sourced Jordan solution agrees with independent logarithm and dilogarithm formulas",
  TrueQ[difference<10^-16]];
 difference=Max[Abs[Flatten[Values[one["EpsilonCoefficients"]-two["EpsilonCoefficients"]]]]];
 FTAssert["increasing the counterterm cutoff leaves the finite solution unchanged",
  TrueQ[difference<10^-16]]];

prepared=PrepareSingularBoundarySystem[<|"Variable"->z,"DimensionalRegulator"->eps,
 "ConnectionMatrix"->{{1/(z+eps)-2eps/z,0},{1/(z+eps),1/z}}|>];
FTAssert["the general preparer composes apparent-pole, normal and integration gauges",
 AssociationQ[prepared]&&prepared["ApparentSingularityRemoval"]["RemovedLocations"]==={-eps}&&
 Simplify[D[prepared["NormalizedToOriginalGauge"],z]+
  prepared["NormalizedToOriginalGauge"].prepared["NormalizedDifferentialSystem"]["ConnectionMatrix"]-
  prepared["OriginalDifferentialSystem"]["ConnectionMatrix"].prepared["NormalizedToOriginalGauge"]]===ConstantArray[0,{2,2}]];
If[AssociationQ[prepared],
 saturated=SaturateLaurentColumnBasis[prepared["PrimarySeedMatrix"],eps];
 orders=DetermineBoundaryAmplitudeOrders[prepared,saturated,{-2,-2}];
 FTAssert["amplitude bounds follow the exact inverse gauge and connection paths",
  AssociationQ[orders]&&orders["AmplitudeLaurentLowerBounds"]==={-2,-2}];
 connection=ConstructSingularBoundaryConnection[prepared,saturated["Basis"],<|"ColumnUpperOrders"->{2,2}|>];
 FTAssert["the general constructor determines the counterterm order and materializes the solution",
  AssociationQ[connection]&&connection["FiniteNormalCoordinateSolution"]&&
   connection["BoundaryDimension"]===2]];

scParameterInput={{1/scScale,1/(eps scScale)},{0,1}};
scParameterSaturation=SaturateLaurentColumnBasis[scParameterInput,eps];
FTAssert["Laurent saturation keeps symbolic coefficient-field parameters",
 AssociationQ[scParameterSaturation]&&scParameterSaturation["LeadingRank"]===2&&
 Simplify[scParameterInput.scParameterSaturation["BasisChangeMatrix"]-
 scParameterSaturation["Basis"]]===ConstantArray[0,{2,2}]];

FTReport[];

