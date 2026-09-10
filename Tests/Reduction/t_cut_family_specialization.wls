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
mpPrescribedTop=ReplacePart[mpTop,{2,5}->FeynCalc`FCI[FeynCalc`SFAD[mpP-mpK2]]];
mpPrescribed=FeynFacet`CreateCutIntegralFamily[Join[mpFamily,<|"Topology"->mpPrescribedTop|>]];
mpRequest=<|"MeasurementVariable"->mpZ,"ReferenceMomentum"->mpP,"TaggedMomentum"->mpK1,
 "ExternalKinematicConditions"->mpQ>0&&0<mpX<1|>;
specialized=FeynFacet`SpecializeCutIntegralFamily[mpPrescribed,{mpX->mpZ},mpQ>0&&0<mpZ<1];
FTAssert["a physical interior diagonal retains the full scalar-product and cut ranks",
 AssociationQ[specialized]];
degenerate=FeynFacet`SpecializeCutIntegralFamily[mpPrescribed,{mpQ->0},0<mpX<1&&0<mpZ<1];
FTAssert["external Gram degeneration cannot be accepted as an ordinary restriction",
 FailureQ[degenerate]];
FTReport[];
