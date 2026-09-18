Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
tmFamily=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|"Name"->tmTwoBody,
 "FinalMomenta"->{tmK1,tmK2},"TotalMomentum"->tmP+tmQ,"ExternalMomenta"->{tmP,tmQ},
 "ReferenceMomentum"->tmP,"TaggedMomentum"->tmK1,"MeasurementVariable"->tmZ,
 "KinematicRules"->{FeynCalc`SPD[tmP]->0,FeynCalc`SPD[tmQ]->0,FeynCalc`SPD[tmP,tmQ]->tmS/2},
 "Assumptions"->tmS>0&&0<tmZ<1|>];
tmFamily=Append[tmFamily,"ExternalKinematicConditions"->tmS>0];
tmSystem=<|"KinematicVariables"->{tmS,tmZ},"DimensionalRegulator"->tmEps,
 "MasterIntegralBasis"->{FeynCalc`GLI["tmTwoBody",{1,1,1}],FeynCalc`GLI["tmTwoBody",{1,1,2}]},
 "Families"->{tmFamily}|>;
tmDefinitions=FeynFacet`ConstructMasterIntegralDefinitions[tmSystem];
If[AssociationQ[tmDefinitions],Print["DEFINITION STATUS ",tmDefinitions["Status"],
 " ",tmDefinitions["UnresolvedIntegralDefinitions"]],Print[tmDefinitions]];
FTTest`FTAssert["one master-definition builder accepts the typed family inventory",
 AssociationQ[tmDefinitions]&&Length[tmDefinitions["MasterIntegralDefinitions"]]===2];
If[AssociationQ[tmDefinitions]&&Length[tmDefinitions["MasterIntegralDefinitions"]]===2,
 tmD1=tmDefinitions["MasterIntegralDefinitions"][1];tmD2=tmDefinitions["MasterIntegralDefinitions"][2];
 FTTest`FTAssert["a measurement delta does not change the phase-space measure",
  tmD1["PhaseSpaceLoopCount"]===1&&tmD1["MomentumConservationDeltaCount"]===1&&
  tmD1["ParticleCutIndices"]==={1,2}&&tmD1["MeasurementCutIndices"]==={3}&&
  Simplify[tmD1["MeasurePrefactor"]/(tmS(2Pi)^(-2+2tmEps))]===1];
 FTTest`FTAssert["measurement derivatives have the distributional sign and no energy theta",
  tmD2["CutDistributions"][[3,"DistributionCoefficient"]]===-1&&
  tmD2["CutDistributions"][[3,"PositiveEnergyCondition"]]===None&&
  Length[tmD2["OrientedCutMomenta"]]===2]];
tmRepresentations=FeynFacet`ConstructMasterIntegralRepresentations[tmSystem];
If[AssociationQ[tmRepresentations],Print["REPRESENTATION STATUS ",tmRepresentations["Status"],
 " ",tmRepresentations["UnresolvedIntegralDefinitions"]],Print[tmRepresentations]];
FTTest`FTAssert["typed measured masters reuse the common Baikov constructor",
 AssociationQ[tmRepresentations]&&Length[tmRepresentations["MasterIntegralRepresentations"]]===2];
If[AssociationQ[tmRepresentations]&&Length[tmRepresentations["MasterIntegralRepresentations"]]===2,
 tmR1=Join[tmD1,FeynFacet`Private`miRepBaikov[tmD1]];
 tmValue=tmR1["ParametricPrefactor"]tmR1["UnitCutRepresentation"]["Integrand"];
 tmExpected=(4Pi)^tmEps/(8Pi Gamma[1-tmEps])tmS^-tmEps(tmZ(1-tmZ))^-tmEps;
 FTTest`FTAssert["the measured two-body density agrees with independent phase-space factorization",
  tmR1["UnitCutRepresentation"]["IntegrationVariables"]==={}&&
  TrueQ[FullSimplify[FunctionExpand[tmValue/tmExpected],
   Assumptions->tmS>0&&0<tmZ<1&&Element[tmEps,Reals]]===1]];
 tmEndpoint=FeynFacet`ConstructMasterIntegralDefinitions[tmSystem,<|"PrescriptionScope"->"EndpointDistributions"|>];
 FTTest`FTAssert["measurement test-function scope is not promoted to all external endpoints",
  AssociationQ[tmEndpoint]&&tmEndpoint["MasterIntegralDefinitions"]===<||>]];

tmAtPoint=FeynFacet`ConstructMasterIntegralRepresentations[tmSystem,<|"BasePoint"->{1,1/3}|>];
FTTest`FTAssert["measured volume and measurement derivatives use explicit Gamma formulas",
 AssociationQ[tmAtPoint]&&
 AllTrue[Values[tmAtPoint["MasterIntegralRepresentations"]],#["Representation"]==="UnitCube"&]];
tmBounds=FeynFacet`DetermineIntegralLaurentBound/@tmAtPoint["MasterIntegralRepresentations"];
FTTest`FTAssert["the same bound planner sees the vanishing leading measurement derivative",
 tmBounds[1]["LowerBound"]===0&&tmBounds[2]["LowerBound"]===1];

Do[
 tmMany=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|"Name"->tmManyBody,
  "FinalMomenta"->Take[{tmK1,tmK2,tmK3,tmK4},tmCount],"TotalMomentum"->tmP+tmQ,
  "ExternalMomenta"->{tmP,tmQ},"ReferenceMomentum"->tmP,"TaggedMomentum"->tmK1,
  "MeasurementVariable"->tmZ,"KinematicRules"->{
   FeynCalc`SPD[tmP]->0,FeynCalc`SPD[tmQ]->0,FeynCalc`SPD[tmP,tmQ]->tmS/2},
  "Assumptions"->tmS>0&&0<tmZ<1|>];
 tmManyResult=FeynFacet`ConstructMasterIntegralRepresentations[<|
  "DimensionalRegulator"->tmEps,"MasterIntegralBasis"->{FeynCalc`GLI[tmManyBody,ConstantArray[1,tmCount+1]]},
  "Families"->{tmMany}|>];
 tmManyValue=tmManyResult["MasterIntegralRepresentations"][1];
 FTTest`FTAssert[ToString[tmCount]<>" particle measured volumes use the same definition/evaluation path",
  AssociationQ[tmManyValue]&&tmManyValue["Representation"]==="UnitCube"&&
  FullSimplify[tmManyValue["Terms"][[1,"Prefactor"]]/
   FeynFacet`MasslessMeasuredPhaseSpace[tmCount,tmS,tmZ,tmEps],
   Assumptions->tmS>0&&0<tmZ<1&&Element[tmEps,Reals]]===1],
 {tmCount,3,4}];
FTTest`FTReport[];
