$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
meBase=<|"FinalMomenta"->{meK1,meK2,meK3},"TotalMomentum"->meP+meQ,
 "ExternalMomenta"->{meP,meQ},"ReferenceMomentum"->meP,"TaggedMomentum"->meK1,
 "MeasurementVariable"->meZ,"KinematicRules"->{
  FeynCalc`SPD[meP]->0,FeynCalc`SPD[meQ]->0,FeynCalc`SPD[meP,meQ]->meS/2},
 "Assumptions"->meS>0&&0<meZ<1|>;
meDefinition[name_,momentum_,eta_:1,tag_:meK1]:=FeynFacet`CreateMeasuredPhaseSpaceDefinition[
 Join[meBase,<|"Name"->name,"TaggedMomentum"->tag,"OrdinaryPropagators"->{
  FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
   FeynCalc`Momentum[momentum,D],0,0,{1,eta}]]}|>]];
meA=meDefinition[meFamilyA,meP-meK2];
meB=meDefinition[meFamilyB,meP-meK3];
meIntegral[name_,powers_:{1,1,1,1,1}]:=FeynCalc`GLI[name,powers];
meCompare[a_,b_,pa_:{1,1,1,1,1},pb_:{1,1,1,1,1}]:=FeynFacet`FindCutIntegralEquivalences[
 {meIntegral[a["Topology"][[1]],pa],meIntegral[b["Topology"][[1]],pb]},
 {a,b},"Normalization"->"Declared typed measures"];
meEqual=meCompare[meA,meB];
FTTest`FTAssert["unobserved particle exchange preserves the tagged measurement",
 AssociationQ[meEqual]&&meEqual["EquivalenceClassCount"]===1];
FTTest`FTAssert["the exchange also preserves linked repeated particle cuts",
 meCompare[meA,meB,{1,2,1,1,1},{1,1,2,1,1}]["EquivalenceClassCount"]===1];
FTTest`FTAssert["a different measurement derivative is not identified",
 meCompare[meA,meB,{1,1,1,2,1},{1,1,1,1,1}]["EquivalenceClassCount"]===2];
meTagged=meDefinition[meFamilyB,meP-meK2,1,meK2];
FTTest`FTAssert["an ordinary denominator tied to the tagged leg stays distinct",
 meCompare[meA,meTagged]["EquivalenceClassCount"]===2];
meEta=meDefinition[meFamilyB,meP-meK3,-1];
FTTest`FTAssert["ordinary causal prescriptions are retained",
 meCompare[meA,meEta]["EquivalenceClassCount"]===2];
meNormalization=Append[meB,"MeasurePrefactor"->2meB["MeasurePrefactor"]];
FTTest`FTAssert["typed measure prefactors cannot be overridden by a common label",
 meCompare[meA,meNormalization]["EquivalenceClassCount"]===2];
FTTest`FTAssert["numerator powers are retained in the signature",
 meCompare[meA,meB,{1,1,1,1,-1},{1,1,1,1,-2}]["EquivalenceClassCount"]===2];

meOffShell=meB;
meTop=meOffShell["Topology"];
meModified=meTop[[2,4]]/.FeynCalc`StandardPropagatorDenominator[a_,b_,c_,power_]:>
 FeynCalc`StandardPropagatorDenominator[a,b+FeynCalc`FCI[FeynCalc`SPD[meK1]],c,power];
meOffShell["Topology"]=ReplacePart[meTop,{2,4}->meModified];
FTTest`FTAssert["equality only on unit-cut support is not a dotted-cut identity",
 meCompare[meA,meOffShell]["EquivalenceClassCount"]===2];
FTTest`FTAssert["unsupported extra boundaries are rejected rather than discarded",
 FailureQ[FeynFacet`CreateCutIntegralDefinition[Append[meA,"AdditionalAcceptanceBoundaries"->meK1]]]];
FTTest`FTAssert["a different massless-tip continuation is not silently overwritten",
 FailureQ[FeynFacet`CreateCutIntegralDefinition[Append[meA,"Definition"->"Different contact terms"]]]];
FTTest`FTReport[];
