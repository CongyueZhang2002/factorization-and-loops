Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
base=root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer/Raw/";
born=FeynFacet`ReadPartonicResult[base<>"LO/q-q/Born/Results.wl"];
virt=FeynFacet`ReadPartonicResult[base<>"NLO/q-q/Virtual/Results.wl"];
If[!AssociationQ[born]||!AssociationQ[virt],Print["Generated Born and virtual results required"];Exit[1]];
bs=born["Coefficients"][0]["DeltaCoefficient"];
vs=virt["Coefficients"][-2]["DeltaCoefficient"];
expected=FeynFacet`\[Alpha]s/(2Pi)(2FeynCalc`CF+FeynCalc`CA)bs;
residual=FeynFacet`CancelRationalCoefficients[(vs+expected)/.FeynCalc`CF->(FeynCalc`CA^2-1)/(2FeynCalc`CA)];
FTTest`FTAssert["the double pole is the sum of the two quark and one gluon Casimirs",
 ListQ[residual]&&AllTrue[residual,#===0&]];
l=virt["Coefficients"][-1]["DeltaCoefficient"][[2]];
l=FeynFacetSolution`ExpandPositiveLogarithms[l,Q2>0&&0<x<1&&0<z<1];
FTTest`FTAssert["the longitudinal moment has no single infrared pole when its Born projection vanishes",
 First[FeynFacet`CancelRationalCoefficients[{l}/.FeynCalc`CF->(FeynCalc`CA^2-1)/(2FeynCalc`CA)]]===0];
Print["FIXED OBSERVED VIRTUAL POLES TEST COMPLETE"];FTTest`FTReport[];
