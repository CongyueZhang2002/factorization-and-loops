(* Exact-D tensor algebra and the absolute single-helicity Born sign. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
ctQuark=<|"Role"->"PDF","Species"->{"q","u"},"Polarization"->"U","Momentum"->ctp,"MomentumSpace"->"Physical4"|>;
ctU=FeynFacet`PartonicSpinDensity[ctQuark];
ctL=FeynFacet`PartonicSpinDensity[Join[ctQuark,<|"Polarization"->"L"|>]];
ctAntiL=FeynFacet`PartonicSpinDensity[Join[ctQuark,<|"Species"->{"qbar","u"},"Polarization"->"L"|>]];
ctOut=FeynFacet`PartonicSpinDensity[Join[ctQuark,<|"Role"->"FF","Momentum"->ctk,"MomentumSpace"->"IntegratedD"|>]];
FTTest`FTAssert["incoming quarks are averaged and outgoing tagged cuts are summed",
 ctU["SpinDensity"]===FeynCalc`GS[ctp]/2&&ctU["ColorAverage"]===1/FeynCalc`CA&&
 ctOut["SpinDensity"]===FeynCalc`GSD[ctk]&&ctOut["ColorAverage"]===1];
FTTest`FTAssert["opposite quark and antiquark helicity outer products remain distinct",
 ctL["SpinDensity"]===-ctAntiL["SpinDensity"]];
ctG=FeynFacet`PartonicSpinDensity[Join[ctQuark,<|"Species"->"g","ReferenceMomentum"->ctq,"Indices"->{ctm,ctn}|>]];
ctGOut=FeynFacet`PartonicSpinDensity[Join[ctQuark,<|"Role"->"FF","Species"->"g","ReferenceMomentum"->ctq,"Indices"->{ctm,ctn}|>]];
FTTest`FTAssert["a physical gluon momentum retains the declared D-2 spin average",
 Together[(D-2)ctG["SpinDensity"]-ctGOut["SpinDensity"]]===0];
FTTest`FTAssert["the early-loaded PDF and FF definitions resolve the shared physical projector",
 FreeQ[{ctG["SpinDensity"],ctGOut["SpinDensity"]},
  _FeynFacet`GluonPolarizationProjector|_FeynFacet`Private`GluonPolarizationProjector]&&
 !FreeQ[FeynCalc`FCI[ctG["SpinDensity"]],_FeynCalc`Pair]];
ctLegacyG=FeynFacet`Private`twist2GluonCorrelator[ctFraction,ctk,ctLambda,ctq,ctm,ctn,"Incoming"];
FTTest`FTAssert["the hadronic gluon correlator resolves the same projector without a private shadow",
 FreeQ[ctLegacyG,_FeynFacet`GluonPolarizationProjector|_FeynFacet`Private`GluonPolarizationProjector]&&
 !FreeQ[FeynCalc`FCI[ctLegacyG],_FeynCalc`Pair]];
ctProjectors=FeynFacet`DISCurrentProjectors[ctp,ctq,{ctm,ctn}];
ctRules=FeynCalc`FCI[{FeynCalc`SPD[ctp]->0,FeynCalc`SPD[ctq]->-ctQ2,FeynCalc`SPD[ctp,ctq]->ctQ2/2,
 FeynCalc`SP[ctp]->0,FeynCalc`SP[ctq]->-ctQ2,FeynCalc`SP[ctp,ctq]->ctQ2/2}];
ctContract[x_]:=Simplify[FeynCalc`ExpandScalarProduct[FeynCalc`Contract[
 FeynCalc`FCI[x]/.{FeynCalc`Momentum[ctp,D]->FeynCalc`Momentum[ctp],
 FeynCalc`Momentum[ctq,D]->FeynCalc`Momentum[ctq]}]]/.ctRules,ctQ2>0&&D>2];
ctBasis=Values[ctProjectors["TensorBasis"]];
ctGram=Table[ctContract[ctBasis[[i]]ctBasis[[j]]],{i,3},{j,3}];
FTTest`FTAssert["symmetric D-dimensional and BMHV antisymmetric Gram norms are exact",
 ctGram===DiagonalMatrix[{D-2,1,-2}]];
ctTrace[spin_,a_,b_]:=FeynCalc`DiracTrace[
 spin.FeynCalc`GAD[a].FeynCalc`GSD[ctp+ctq].FeynCalc`GAD[b],
 FeynCalc`DiracTraceEvaluate->True];
ctTraceU=ctTrace[ctU["SpinDensity"],ctm,ctn];
ctTraceL=ctTrace[ctL["SpinDensity"],ctm,ctn];
ctTraceAntiL=ctTrace[ctAntiL["SpinDensity"],ctn,ctm];
ctCoefficients=ctContract[# ctTraceU/(2ctQ2)]&/@ctProjectors["CoefficientProjectors"];
FTTest`FTAssert["Born current trace and one-particle phase space give C_T=1 and C_L=0 at exact D",
 ctCoefficients["2F1"]===1&&ctCoefficients["FL/x"]===0];
ctHelicity=ctContract[ctTraceL ctProjectors["CoefficientProjectors"]["2g1"]/(2ctQ2)];
ctAntiHelicity=ctContract[ctTraceAntiL ctProjectors["CoefficientProjectors"]["2g1"]/(2ctQ2)];
FTTest`FTAssert["quark and antiquark have the same positive electromagnetic g1 Born coefficient",
 ctHelicity===1&&ctAntiHelicity===1];
FTTest`FTAssert["the Born current satisfies its Ward identity",
 ctContract[ctTraceU FeynCalc`FVD[ctq,ctm]]===0];
ctGluonOnly=<|"Incoming"->{<|"HadronMomentum"->ctp,"Parton"->FeynArts`V[5],"Momentum"->ctk|>},"Outgoing"->{}|>;
FTTest`FTAssert["pure-gluon amplitudes have an empty quark spin-tag map",
 FeynFacet`Private`externalSpinTags[ctGluonOnly]===<||>];
FTTest`FTReport[];
