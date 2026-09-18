Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dy=FeynFacet`ReadProjectCard[root<>"/Projects/DrellYan_UU"];
FTTest`FTAssert["DY normalization is derived from its generated unit-charge Born reference",
 AssociationQ[dy]&&Together[dy["Assembly"]["CurrentNormalization"]-FeynCalc`CA/(2Pi)]===0&&
 dy["Assembly"]["ObservableNormalizationDerivation"]["Reference"]["Source"]==="GeneratedCanonicalTreeCurrent"];
dc=FeynFacet`ReadContributionCard[root<>"/Projects/DrellYan_UU/Raw/LO/q-qb","Born"];
ds=FeynFacet`ReadProcessCard[dc];dr=Join[FeynFacet`ProjectAssemblyRequest[dc],<|"EpsilonRange"->{0,1}|>];
db=FeynFacet`ConstructCurrentBornResult[ds,dr];
FTTest`FTAssert["physical DY Born keeps its charge and epsilon dependence",
 AssociationQ[db]&&db["Coefficients"][0]["DeltaCoefficient"]==={4/9}&&db["Coefficients"][1]["DeltaCoefficient"]==={-4/9}];
(* Independent free-current Wick trace, without graph generation or generated reference. *)
trace=FeynCalc`Contract[FeynCalc`DiracSimplify[FeynCalc`DiracTrace[
 FeynCalc`GSD[ka].FeynCalc`GAD[mu].FeynCalc`GSD[kb].FeynCalc`GAD[nu]],
 DiracTraceEvaluate->True](-FeynCalc`MTD[mu,nu]+
 FeynCalc`FVD[ka+kb,mu]FeynCalc`FVD[ka+kb,nu]/s)];
trace=FeynCalc`ExpandScalarProduct[trace]/.FeynCalc`FCI[{FeynCalc`SPD[ka]->0,FeynCalc`SPD[kb]->0,FeynCalc`SPD[ka,kb]->s/2}];
canonical=Factor[trace/(4FeynCalc`CA)*2Pi/s/.D->4-2ep];
FTTest`FTAssert["free-current spin/color trace and recoil delta fix absolute normalization",
 Together[canonical-2Pi(1-ep)/FeynCalc`CA]===0];
FTTest`FTAssert["generated reference agrees with independent canonical Wick trace",
 Together[dy["Assembly"]["ObservableNormalizationDerivation"]["Reference"]["Coefficient"]-(canonical/.ep->0)]===0];
normalizedSpectral=FeynFacet`CurrentObservableNormalization[
 Join[dy["Assembly"]["ObservableNormalization"],<|"Tensor"->"HadronicTensor"|>],
 dy["Assembly"]["ObservableNormalizationDerivation"]["Reference"]];
FTTest`FTAssert["a common tensor convention cancels from a Born-normalized ratio",
 AssociationQ[normalizedSpectral]&&normalizedSpectral["Factor"]===dy["Assembly"]["CurrentNormalization"]];
FTTest`FTAssert["canonical on-shell delta measure fixes the observed density constant",
 FullSimplify[FeynFacet`OnShellInvariantDensityFactor[4-2ep]-1/(2(2Pi)^(3-2ep)),Element[ep,Reals]]===0];
FTTest`FTAssert["two incoming massless particles have flux 2s without a factorial",
 FeynFacet`LorentzInvariantIncidentFlux[s,0,0,s>0]===2s];
su=FeynFacet`ReadProjectCard[root<>"/Projects/SIDIS_UU"];
FTTest`FTAssert["SIDIS tensor convention defines the measured spectral prefactor",
 su["Assembly"]["CurrentNormalization"]===1/(4Pi)&&su["Assembly"]["ObservableNormalization"]["Tensor"]==="HadronicTensor"];
FTTest`FTAssert["bare coupling rule and counterterm normalization have one source",
 su["Assembly"]["BareCouplingRules"]===FeynFacet`BareStrongCouplingRules[su["Counterterms"],Global`Epsilon]];
m=2-2ep;
literal=Integrate[z^(-m)*(z(1-z^2)/2)*z^4,{z,0,1},Assumptions->0<ep<1];
adjoint=Integrate[z^(1-m+4),{z,0,1},Assumptions->0<ep<1]*
 Integrate[xi^(3-m+4),{xi,0,1},Assumptions->0<ep<1];
FTTest`FTAssert["nontrivial scalar replacement equals the fragmentation hard adjoint",
 FullSimplify[literal-adjoint,0<ep<1]===0&&Together[literal-1/((4+2ep)(6+2ep))]===0];
Print["OBSERVABLE NORMALIZATION TEST COMPLETE"];FTTest`FTReport[];
