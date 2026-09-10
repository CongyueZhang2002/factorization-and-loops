$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mcCut=FeynFacet`CutPropagator;
FTTest`FTAssert["differentiation raises a measurement-cut power with the distributional sign",
 D[mcCut[mcY-mcZ,2],mcZ]===2mcCut[mcY-mcZ,3]];
FTTest`FTAssert["pinched measurement cuts vanish",
 mcCut[mcY,0]===0&&mcCut[mcY,-2]===0];
FTTest`FTAssert["negative constraint rescaling retains odd normal-derivative signs",
 FeynFacet`NormalizeCutPropagator[mcCut[-2(mcY-mcZ),2],{mcY},Element[mcZ,Reals]]===
  -mcCut[mcY-mcZ,2]/4];
FTTest`FTAssert["positive constraint rescaling retains the Jacobian at every cut power",
 FeynFacet`NormalizeCutPropagator[mcCut[3(mcY-mcZ),3],{mcY},Element[mcZ,Reals]]===
  mcCut[mcY-mcZ,3]/27];
mcProp=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
 0,2FeynCalc`Pair[FeynCalc`Momentum[mcP,D],FeynCalc`Momentum[mcK,D]],-mcZ mcQ/mcX,{1,1}]];
mcTop=FeynCalc`FCTopology[MeasuredTwoParticle,
 {FeynCalc`FCI[FeynCalc`SFAD[mcK]],FeynCalc`FCI[FeynCalc`SFAD[mcK-mcP-mcR]],mcProp},
 {mcK},{mcP,mcR},FeynCalc`FCI[{FeynCalc`SPD[mcP]->0,FeynCalc`SPD[mcR]->-mcQ,
 FeynCalc`SPD[mcP,mcR]->mcQ/(2mcX)}],{}];
mcRequest=<|"Topology"->mcTop,"Cuts"->{
 <|"Index"->1,"Type"->"Particle","Momentum"->mcK,"EnergyDirection"->1|>,
 <|"Index"->2,"Type"->"Particle","Momentum"->mcP+mcR-mcK,"EnergyDirection"->1|>,
 <|"Index"->3,"Type"->"Measurement"|>},"TimeDirection"->mcP+mcR,
 "Assumptions"->mcQ>0&&0<mcX<1&&0<mcZ<1,
 "Dimension"->D,"MeasurePrefactor"->(2Pi)^(2-D) mcQ/mcX|>;
mcFamily=FeynFacet`CreateCutIntegralFamily[mcRequest];
FTTest`FTAssert["linear measurement cuts have no positive-energy condition",
 AssociationQ[mcFamily]&&mcFamily["ParticleCutIndices"]==={1,2}&&
 mcFamily["MeasurementCutIndices"]==={3}&&mcFamily["Cuts"][[3,"PositiveEnergyCondition"]]===None];
If[!AssociationQ[mcFamily],Print[mcFamily];FTTest`FTReport[]];
FTTest`FTAssert["particle energy directions remain explicit and prescription removal is not inferred",
 mcFamily["Cuts"][[2,"EnergyDirection"]]===1&&
 mcFamily["OrdinaryPrescriptionLimitEstablished"]===False];
mcUnit=FeynCalc`GLI[MeasuredTwoParticle,{1,1,1}];mcDotted=FeynCalc`GLI[MeasuredTwoParticle,{1,1,2}];
mcDerivative=FeynFacet`DifferentiateCutIntegral[mcFamily,mcUnit,mcZ];
FTTest`FTAssert["differentiating the measured integral raises the actual linear cut",
 Factor[mcDerivative-mcQ/mcX mcDotted]===0];
mcChanged=FeynFacet`CreateCutIntegralFamily[Join[mcRequest,<|"MeasurePrefactor"->mcZ mcRequest["MeasurePrefactor"]|>]];
FTTest`FTAssert["the derivative of a parameter-dependent measurement Jacobian is included",
 Factor[FeynFacet`DifferentiateCutIntegral[mcChanged,mcUnit,mcZ]-mcUnit/mcZ-mcQ/mcX mcDotted]===0];
mcSparse=<|"MomentumDerivatives"-><|mcP->-mcP/mcX,mcR->0|>|>;
mcDerivativeX=FeynFacet`DifferentiateCutIntegral[mcFamily,mcUnit,mcX,mcSparse];
mcDerivativeXSymmetric=FeynFacet`DifferentiateCutIntegral[mcFamily,mcUnit,mcX];
mcDerivativeScale=FeynFacet`DifferentiateCutIntegral[mcFamily,mcUnit,mcQ];
FTTest`FTAssert["an inconsistent external velocity is rejected before integral reduction",
 FailureQ[FeynFacet`DifferentiateCutIntegral[mcFamily,mcUnit,mcX,
  <|"MomentumDerivatives"-><|mcP->0,mcR->0|>|>]]];
mcTargets=Union[{mcUnit,mcDotted},Cases[
 {mcDerivativeX,mcDerivativeXSymmetric,mcDerivativeScale},_FeynCalc`GLI,Infinity]];
mcIBP=FeynFacet`GenerateCutIBPEquations[mcFamily,{mcUnit}];
mcEuler=Total[KeyValueMap[Times,First[mcIBP["Rows"]]]];
mcEulerExpected=(D-4)mcUnit+mcQ(1-mcX)/mcX FeynCalc`GLI[MeasuredTwoParticle,{1,2,1}]-
 mcZ mcQ/mcX mcDotted;
FTTest`FTAssert["the loop Euler derivative retains the denominator-degree terms",
 Factor[mcEuler-mcEulerExpected]===0];
mcWork=root<>"/Projects/SIDIS_UU_NNLO/NNLO/q-q/Kira/TypedMeasurementCutRegression";
mcReduction=FeynFacet`KiraReduction[{mcFamily},mcTargets,
 <|"WorkingDirectory"->mcWork,"MassDimensions"->{mcQ->2,mcX->0,mcZ->0},"Threads"->1|>];
FTTest`FTAssert["Kira reduces shifted linear measurement cuts without pinching them",
 AssociationQ[mcReduction]&&mcReduction["Masters"]==={mcUnit}];
If[!AssociationQ[mcReduction],Print[mcReduction];FTTest`FTReport[]];
mcDifferentRequest=FeynFacet`CreateCutIntegralFamily[Join[mcRequest,
 <|"Topology"->(mcTop/.mcZ->2mcZ)|>]];
FTTest`FTAssert["a Kira workspace cannot silently reuse tables for a changed measurement",
 FailureQ[FeynFacet`KiraReduction[{mcDifferentRequest},{mcUnit,mcDotted},
  <|"WorkingDirectory"->mcWork,"MassDimensions"->{mcQ->2,mcX->0,mcZ->0},"Threads"->1|>]]];
(* Independent exact angular integral, without reduction tables as input. *)
mcExpected=FeynFacet`MasslessMeasuredPhaseSpace[2,mcQ(1-mcX)/mcX,mcZ,mcE];
mcRatio=FullSimplify[D[mcExpected,mcZ]/mcExpected,mcQ>0&&0<mcX<1&&0<mcZ<1]/.mcE->(4-D)/2;
FTTest`FTAssert["the reduced measurement DE agrees with the exact beta-function phase space",
 Factor[(mcDerivative/.mcReduction["Rules"])-mcRatio mcUnit]===0];
FTTest`FTAssert["the sparse x derivative agrees with the exact measured two-body volume",
 Factor[(mcDerivativeX/.mcReduction["Rules"])-(4-D)/(2mcX(1-mcX))mcUnit]===0];
FTTest`FTAssert["two external Gram lifts produce the same reduced derivative",
 Factor[((mcDerivativeX-mcDerivativeXSymmetric)/.mcReduction["Rules"])]===0];
FTTest`FTAssert["homogeneous virtuality scaling includes the measurement Jacobian",
 Factor[(mcDerivativeScale/.mcReduction["Rules"])-(D-4)/(2mcQ)mcUnit]===0];
FTTest`FTAssert["the independently normalized measured density integrates to the ordinary phase space",
 FullSimplify[Integrate[mcExpected,{mcZ,0,1},Assumptions->mcE<0&&mcQ>0&&0<mcX<1]-
 FeynFacet`MasslessPhaseSpaceVolume[2,mcQ(1-mcX)/mcX,mcE],mcE<0&&mcQ>0&&0<mcX<1]===0];
FeynFacet`FamilyArtifactWrite[mcReduction,root<>"/Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/Validation/MeasurementCutReduction.wl"];
FTTest`FTReport[];
