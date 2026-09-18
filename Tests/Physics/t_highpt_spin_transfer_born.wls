Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer/Raw/LO/q-q","Born"];
setup=FeynFacet`ReadProcessCard[card];
request=Join[FeynFacet`ProjectAssemblyRequest[card],<|"EpsilonRange"->{0,2}|>];
result=FeynFacet`ConstructFixedObservedBornResult[setup,request];
FTTest`FTAssert["physical tagged Born current is generated and integrated",AssociationQ[result]];
If[!AssociationQ[result],Print[result];FTTest`FTReport[]];
jac=Q2(1-x)(1-z)/x;
stripped=FullSimplify[result["Coefficients"][0]["DeltaCoefficient"]jac/(8 Pi^2 FeynFacet`\[Alpha]s),
 Assumptions->Q2>0&&0<x<1&&0<z<1];
(* Independent reference: corrected Eq. (A.18), hep-ph/0602188.
   The independent lepton-plane azimuth removes its two nonconstant harmonics. *)
FTTest`FTAssert["corrected literature Born moment: transverse 4 CF e_q^2, longitudinal zero",
 stripped==={4 FeynCalc`CF eU^2,0}];
FTTest`FTAssert["the independent-azimuth Born longitudinal moment also vanishes beyond epsilon zero",
 AllTrue[Values[result["Coefficients"]],#["DeltaCoefficient"][[2]]===0&]];
FTTest`FTAssert["the recoil endpoint Jacobian follows from its mass shell",
 Factor[result["BornSupportJacobian"]-jac]===0];
ward=FeynFacet`ConstructFixedObservedBornResult[setup,Join[request,<|
 "CurrentProjectors"-><|"Ward"->FeynCalc`FV[q,mu]FeynCalc`FV[q,nu]|>|>]];
FTTest`FTAssert["generated Born current obeys its electromagnetic Ward identity through epsilon squared",
 AssociationQ[ward]&&AllTrue[Values[ward["Coefficients"]],#["DeltaCoefficient"]==={0}&]];
FTTest`FTAssert["all Born coefficients are explicit mathematical functions",
 FreeQ[result["Coefficients"],_FeynCalc`Pair|_FeynCalc`SMP|_FeynCalc`FeynAmpDenominator|_Integrate|_SeriesData]];
Print["HIGHPT BORN TEST COMPLETE"];
FTTest`FTReport[];
