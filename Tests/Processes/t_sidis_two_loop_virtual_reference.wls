
(* Independent comparison only: hep-ph/0507061v3 equation (10).
   Production uses generated graphs, IBP rules and section-2 scalar values. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=root<>"/Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/DoubleVirtual/TwoLoopInterference";
a=FeynFacet`FamilyArtifactRead[dir<>"/IntegratedScalarCoefficients.wl"];
born=FeynFacet`FamilyArtifactRead[root<>"/Projects/SIDIS_UU_NNLO/LO/q-q/Results/Result.wl"];
e=Global`Epsilon;d=4-2e;n=FeynCalc`CA;nf=nU+nD;
reference=<|
 "A2Squared"->-(n^2-1)/n (d^2-7d+16)^2/(4(d-4)^2),
 "A3"->-(n (d^5-18d^4+138d^3-552d^2+1144d-980)(3d-8)/(2(d-3)(d-4)^3)+
  (9d^6-358d^5+4309d^4-24466d^3+72896d^2-110064d+66080)(3d-8)/
   (16n(d-3)(d-4)^3(2d-7)))/Q2,
 "A4"->n (3d^6-82d^5+819d^4-4030d^3+10344d^2-12824d+5632)/
   (4(d-1)(d-4)^2(3d-8))-
  (21d^6-789d^5+9422d^4-53864d^3+163200d^2-253472d+159232)/
   (16n(3d-8)(2d-7)(d-4)^2)+nf(3d^3-31d^2+110d-128)(d-2)/(2(d-1)(d-4)(3d-8)),
 "A6"->-(d^3-20d^2+104d-176)Q2^2/(32n(2d-7))|>;
(* The source uses d^Dk/(2pi)^D. Two normalized loop measures give
   -(4pi)^(-D), combined with the card's MSbar bare g^4. *)
common=-(n^2-1)/n FeynFacet`\[Alpha]s^2 Exp[2EulerGamma e]muR2^(2e)/(16Pi^2);
tree=born["Coefficients"][0]["DeltaCoefficient"]["DeltaCoefficient"][[1]];
actual=AssociationThread[a["ScalarMasterNames"],a["ExactScalarCoefficientMatrix"][[1]]];
Do[FTTest`FTAssert["generated two-loop coefficient agrees with equation (10): "<>name,
 Factor[actual[name]/(tree common)-reference[name]]===0],{name,Keys[reference]}];
FTTest`FTAssert["longitudinal virtual structure vanishes before scalar integration",
 a["ExactScalarCoefficientMatrix"][[2]]===ConstantArray[0,Length[a["ScalarMasterNames"]]]];
FTTest`FTReport[];
