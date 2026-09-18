$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mpBilinear[a_,b_,constant_:0]:=FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[0,2FeynCalc`FCI[FeynCalc`SPD[a,b]],constant,{1,1}]];
mpTop=FeynCalc`FCTopology[MeasuredThreeParticle,{
 FeynCalc`FCI[FeynCalc`SFAD[mpK1]],FeynCalc`FCI[FeynCalc`SFAD[mpK2]],
 FeynCalc`FCI[FeynCalc`SFAD[mpP+mpR-mpK1-mpK2]],
 mpBilinear[mpP,mpK1,-mpZ mpQ/mpX],mpBilinear[mpP,mpK2],
 mpBilinear[mpR,mpK1],mpBilinear[mpR,mpK2]},
 {mpK1,mpK2},{mpP,mpR},FeynCalc`FCI[{FeynCalc`SPD[mpP]->0,
 FeynCalc`SPD[mpR]->-mpQ,FeynCalc`SPD[mpP,mpR]->mpQ/(2mpX)}],{}];
mpFamily=FeynFacet`CreateCutIntegralFamily[<|"Topology"->mpTop,
 "Cuts"->{<|"Index"->1,"Type"->"Particle","Momentum"->mpK1|>,
  <|"Index"->2,"Type"->"Particle","Momentum"->mpK2|>,
  <|"Index"->3,"Type"->"Particle","Momentum"->mpP+mpR-mpK1-mpK2|>,
  <|"Index"->4,"Type"->"Measurement"|>},
 "TimeDirection"->mpP+mpR,"Assumptions"->mpQ>0&&0<mpX<1&&0<mpZ<1,
 "Dimension"->D,"MeasurePrefactor"->(2Pi)^(3-2D)mpQ/mpX|>];
FTTest`FTAssert["the three-particle family retains three energy cuts and one linear measurement",
 AssociationQ[mpFamily]&&mpFamily["ParticleCutIndices"]==={1,2,3}&&
 mpFamily["MeasurementCutIndices"]==={4}];
If[!AssociationQ[mpFamily],Print[mpFamily];FTTest`FTReport[]];
mpUnit=FeynCalc`GLI[MeasuredThreeParticle,{1,1,1,1,0,0,0}];
mpWeighted=FeynCalc`GLI[MeasuredThreeParticle,{1,1,1,1,-1,0,0}];
mpSparse=<|"MomentumDerivatives"-><|mpP->-mpP/mpX,mpR->0|>|>;
mpDX=FeynFacet`DifferentiateCutIntegral[mpFamily,mpUnit,mpX,mpSparse];
mpDXSymmetric=FeynFacet`DifferentiateCutIntegral[mpFamily,mpUnit,mpX];
mpDZ=FeynFacet`DifferentiateCutIntegral[mpFamily,mpUnit,mpZ];
mpDQ=FeynFacet`DifferentiateCutIntegral[mpFamily,mpUnit,mpQ];
mpDW=FeynFacet`DifferentiateCutIntegral[mpFamily,mpWeighted,mpX,mpSparse];
mpTargets=Union[{mpUnit,mpWeighted},Cases[{mpDX,mpDXSymmetric,mpDZ,mpDQ,mpDW},_FeynCalc`GLI,Infinity]];
Print["THREE_PARTICLE_TARGETS ",Length[mpTargets]];
mpWork=root<>"/Projects/SIDIS_UU/NNLO/q-q/Kira/TypedMeasuredThreeParticleRegression";
mpReduction=FeynFacet`KiraReduction[{mpFamily},mpTargets,
 <|"WorkingDirectory"->mpWork,"MassDimensions"->{mpQ->2,mpX->0,mpZ->0},"Threads"->1|>];
FTTest`FTAssert["all three-particle volume and first-derivative targets reduce to one master",
 AssociationQ[mpReduction]&&mpReduction["Masters"]==={mpUnit}];
If[!AssociationQ[mpReduction],Print[mpReduction];FTTest`FTReport[]];
mpRatio[expression_]:=Factor[(expression/.mpReduction["Rules"])/mpUnit];
FTTest`FTAssert["the x equation agrees with independently integrated three-body phase space",
 Factor[mpRatio[mpDX]+(D-3)/(mpX(1-mpX))]===0];
FTTest`FTAssert["the z equation agrees with the independent tagged angular beta density",
 Factor[mpRatio[mpDZ]-(D-4)/(2mpZ)+(D-3)/(1-mpZ)]===0];
FTTest`FTAssert["three-body external derivative lifts agree after reduction",
 mpRatio[mpDX-mpDXSymmetric]===0];
FTTest`FTAssert["the three-body virtuality derivative has the correct homogeneous power",
 Factor[mpRatio[mpDQ]-(D-3)/mpQ]===0];
FTTest`FTAssert["the unobserved momentum moment equals half the remaining tagged fraction",
 Factor[mpRatio[mpWeighted]-mpQ(1-mpZ)/(2mpX)]===0];
FTTest`FTAssert["differentiation also acts on an ordinary numerator represented by a negative index",
 Factor[mpRatio[mpDW]-mpQ(1-mpZ)/(2mpX)(-1/mpX-(D-3)/(mpX(1-mpX)))]===0];
FTTest`FTAssert["the reduced two-variable scalar equations have commuting mixed partials",
 Factor[D[mpRatio[mpDZ],mpX]-D[mpRatio[mpDX],mpZ]]===0];
FeynFacet`FamilyArtifactWrite[mpReduction,
 root<>"/Projects/SIDIS_UU/NNLO/q-q/Results/Validation/MeasuredThreeParticleReduction.wl"];
mpSystem=FeynFacet`ConstructCutDifferentialSystem[{mpFamily},{mpUnit,mpWeighted},{mpX,mpZ},
 <|"WorkingDirectory"->root<>"/Projects/SIDIS_UU/NNLO/q-q/Kira/TypedDifferentialClosureRegression",
  "Threads"->1,"MomentumDerivatives"-><|mpX->mpSparse["MomentumDerivatives"]|>|>];
FTTest`FTAssert["the general constructor automatically closes the requested measured integrals",
 AssociationQ[mpSystem]&&mpSystem["MasterIntegralBasis"]==={mpUnit}&&
 mpSystem["Validation"]["FlatnessPassed"]===True];
If[AssociationQ[mpSystem],
 FTTest`FTAssert["automatic closure stores the exact two-variable measured-volume connection",
  Factor[Normal[mpSystem["ConnectionMatrices"]]-{{{-(D-3)/(mpX(1-mpX))}},
   {{(D-4)/(2mpZ)-(D-3)/(1-mpZ)}}}]===ConstantArray[0,{2,1,1}]];
 FeynFacet`FamilyArtifactWrite[mpSystem,
  root<>"/Projects/SIDIS_UU/NNLO/q-q/Results/Validation/TypedDifferentialClosure.wl"]];
FTTest`FTReport[];
