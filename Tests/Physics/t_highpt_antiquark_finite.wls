Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=80;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
projectDirectory=root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer";
result=FeynFacet`ReadPartonicResult[projectDirectory<>"/Results/NLO/q-qb/Results.wl"];
source=FeynFacet`FamilyArtifactRead[projectDirectory<>"/Raw/NLO/q-qb/Real/Work/AngularDensity.wl"];
If[!AssociationQ[result]||!AssociationQ[source],Print["Completed antiquark result required"];Exit[1]];
FTTest`FTAssert["the new antiquark channel passes exact cancellation",TrueQ[result["PoleCancellationVerified"]]&&result["PoleCancellationVerificationMethod"]==="ExactSymbolicZero"];
FTTest`FTAssert["a channel first appearing at this order has no explicit scale logarithm",FreeQ[result["Coefficients"],muR2|muF2|muD2]];
interior=FeynFacet`PartonicResultInteriorCoefficients[result]["Coefficients"][0];
e=source["DimensionalRegulator"];h=10^-6;
points={{x->1/3,z->2/5,w->3/4},{x->2/5,z->2/5,w->999/1000}};
fixed={Q2->1,muR2->1,muF2->1,muD2->1,FeynCalc`CA->3,FeynCalc`CF->4/3,FeynCalc`TR->1/2,
 eU->2/3,eD->-1/3,nU->2,nD->3,FeynFacet`\[Alpha]s->1};
Do[
 rules=Join[point,fixed];expected=N[interior/.rules,40];
 exact=Values[source["Values"]]/.rules;
 samples=Table[N[exact/.e->epsPoint,50],{epsPoint,{h,-h,h/2,-h/2}}];
 estimate=(4(samples[[3]]+samples[[4]])-(samples[[1]]+samples[[2]]))/6;
 residual=MapThread[Abs[#1-#2]/Max[1,Abs[#2]]&,{estimate,expected}];
 Print["FINITE ANGULAR EXTRAPOLATION RESIDUALS ",residual];
 FTTest`FTAssert["finite result agrees with unexpanded exact angular expression including near diagonal threshold",
 VectorQ[residual,NumericQ]&&Max[residual]<10^-16],{point,points}];
Print["HIGHPT ANTIQUARK FINITE TEST COMPLETE"];FTTest`FTReport[];
