Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=80;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
projectDirectory=root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer";
result=FeynFacet`ReadPartonicResult[projectDirectory<>"/Results/NLO/q-q/Results.wl"];
anti=FeynFacet`ReadPartonicResult[projectDirectory<>"/Results/NLO/q-qb/Results.wl"];
FTTest`FTAssert["both hard channels have explicit coefficients and exact pole cancellation",
 AllTrue[{result,anti},AssociationQ[#]&&TrueQ[#["PoleCancellationVerified"]]&&#["PoleCancellationVerificationMethod"]==="ExactSymbolicZero"&&FeynFacet`Private`partonicExplicitCoefficientsQ[#["Coefficients"]]&]];
fixed={Q2->1,muR2->2,muF2->3,muD2->5,FeynCalc`CA->3,FeynCalc`CF->4/3,FeynCalc`TR->1/2,eU->2/3,eD->-1/3,nU->2,nD->3,FeynFacet`\[Alpha]s->1};
coefficients=FeynFacet`PartonicScalarCoefficientRules[result];
Do[
 values=Quiet[N[Values[coefficients]/.Join[{x->diagonal,z->diagonal,w->3/4},fixed],30]];
 FTTest`FTAssert["all distributions are finite on the removable diagonal "<>ToString[diagonal,InputForm],VectorQ[values,NumericQ]&&FreeQ[values,Indeterminate|_DirectedInfinity]],{diagonal,{1/3,1/2,3/5}}];
FTTest`FTAssert["diagonal values have exact two-sided cancellation evidence",
 Length[result["RemovableLimitVerification"]]===2&&AllTrue[result["RemovableLimitVerification"],#["Method"]==="ExactTwoSidedLaurentCancellation"&&TrueQ[#["PrincipalPartsVerified"]]&]];
interior=FeynFacet`PartonicResultInteriorCoefficients[result]["Coefficients"][0];
sources=Table[FeynFacet`FamilyArtifactRead[projectDirectory<>"/Raw/NLO/q-q/Real/Work/Components/"<>name<>"/Work/AngularDensity.wl"],{name,{"Gluons","SameFlavor","DifferentFlavorUp","DifferentFlavorDown"}}];
If[!AllTrue[sources,AssociationQ],Print["Exact source angular densities required"];Exit[1]];
e=First[sources]["DimensionalRegulator"];
plan=FeynFacet`PlanProjectResult[projectDirectory<>"/Results/NLO/q-q/Result_Card.wl"];
ctparts=Map[FeynFacet`ReadRawContributionResult,KeySelect[plan["RawCards"],StringContainsQ[#,"Counter-"]&]];
ct=FeynFacet`CombinePartonicResults[ctparts,<|"Contribution"->"Counterterms"|>];
ct=FeynFacet`PartonicResultInteriorCoefficients[ct]["Coefficients"];
exact=Total[Values[#["Values"]]&/@sources]+Total[KeyValueMap[#2 e^#1&,ct]];
h=10^-6;
Do[
 rules=Join[point,fixed];target=N[interior/.rules,40];
 samples=Table[N[exact/.rules/.e->epoint,60],{epoint,{h,-h,h/2,-h/2}}];
 estimate=(4(samples[[3]]+samples[[4]])-(samples[[1]]+samples[[2]]))/6;
 residual=MapThread[Abs[#1-#2]/Max[1,Abs[#2]]&,{estimate,target}];
 Print["QUARK FINITE EXTRAPOLATION ",point," ",residual];
 FTTest`FTAssert["finite interior agrees with exact real angular densities plus separately generated counterterms",
 VectorQ[residual,NumericQ]&&Max[residual]<10^-15],
 {point,{{x->1/3,z->2/5,w->3/4},{x->3/5,z->1/4,w->2/3}}}];
Print["HIGHPT HARD FUNCTION TEST COMPLETE"];FTTest`FTReport[];
