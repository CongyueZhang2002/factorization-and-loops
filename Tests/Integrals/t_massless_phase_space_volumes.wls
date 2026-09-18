Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
pvTwo=FeynFacet`ConstructTwoParticleMeasurement[<|"ReferenceMomentum"->pvp,"TotalMomentum"->pvP,
 "FinalMomenta"->{pvk,pvr},"InvariantMassSquared"->pvs,"ReferenceProjection"->pvrho,
 "MeasurementVariable"->pvz,"EvanescentSquare"->pvKappa,"DimensionalRegulator"->pve,
 "Assumptions"->pvs>0&&pvrho>0&&0<pvz<1|>];
FTTest`FTAssert["the recursive density starts with the measured two-body normalization",
 FullSimplify[FeynFacet`MasslessMeasuredPhaseSpace[2,pvs,pvz,pve]-pvTwo["PhaseSpaceDensity"],
 Assumptions->pvs>0&&0<pvz<1]===0];
FTTest`FTAssert["four-dimensional three- and four-body volumes have absolute normalization",
 (FeynFacet`MasslessPhaseSpaceVolume[3,pvs,pve]/.pve->0)===pvs/(256Pi^3)&&
 (FeynFacet`MasslessPhaseSpaceVolume[4,pvs,pve]/.pve->0)===pvs^2/(24576Pi^5)];
FTTest`FTAssert["literal zero regulator evaluates the absolute volume and measured density",
 FeynFacet`MasslessPhaseSpaceVolume[2,1,0]===1/(8Pi)&&
 FeynFacet`MasslessPhaseSpaceVolume[4,pvs,0]===pvs^2/(24576Pi^5)&&
 Factor[FeynFacet`MasslessMeasuredPhaseSpace[3,pvs,pvz,0]-pvs(1-pvz)/(128Pi^3)]===0];
FTTest`FTAssert["measured three-body phase space has the proper support density",
 Factor[(FeynFacet`MasslessMeasuredPhaseSpace[3,pvs,pvz,pve]/.pve->0)-pvs(1-pvz)/(128Pi^3)]===0];
Do[
 pvDensity=FeynFacet`MasslessMeasuredPhaseSpace[particles,pvs,pvz,pve]/.pve->-1;
 pvVolume=FeynFacet`MasslessPhaseSpaceVolume[particles,pvs,pve]/.pve->-1;
 FTTest`FTAssert[ToString[particles]<>"-body measured density integrates to its six-dimensional volume",
 Factor[Integrate[pvDensity,{pvz,0,1}]-pvVolume]===0];
 FTTest`FTAssert[ToString[particles]<>"-body first energy-fraction moment respects permutation symmetry",
 Factor[Integrate[pvz pvDensity,{pvz,0,1}]-pvVolume/particles]===0],
 {particles,2,4}];
(* Direct cluster factorization checks the measured three-body recurrence.
   Integrate the physical cluster mass before integrating the observed fraction. *)
pvFirst=FeynFacet`ConstructTwoParticleMeasurement[<|"ReferenceMomentum"->pvp,"TotalMomentum"->pvP,
 "FinalMomenta"->{pvk,pvCluster},"InvariantMassSquared"->pvs,"ReferenceProjection"->pvrho,
 "MassesSquared"->{0,pvu pvs},"MeasurementVariable"->pvy,"EvanescentSquare"->pvKappa,
 "DimensionalRegulator"->pve,"Assumptions"->pvs>0&&pvrho>0&&0<pvu<1&&0<pvy<1|>];
pvNested=FullSimplify[(pvs/(2Pi)/(1-pvu)*(pvFirst["PhaseSpaceDensity"]/.pvy->pvz/(1-pvu))*
 FeynFacet`MasslessPhaseSpaceVolume[2,pvu pvs,pve])/.pve->-1,
 Assumptions->pvs>0&&0<pvz<1&&0<pvu<1-pvz];
FTTest`FTAssert["direct massive-cluster integration reproduces the measured three-body density",
 Factor[Integrate[pvNested,{pvu,0,1-pvz}]-
 (FeynFacet`MasslessMeasuredPhaseSpace[3,pvs,pvz,pve]/.pve->-1)]===0];
Print["MASSLESS PHASE SPACE VOLUMES TEST COMPLETE"];FTTest`FTReport[];
