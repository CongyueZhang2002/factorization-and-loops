$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
hsParameters=<|"CA"->hsCA,"CF"->hsCF,"TR"->hsTR,"FlavorCount"->hsNF|>;
hsSpecies={{"q","u"},{"qb","u"},{"q","d"},{"qb","d"},"g"};
hsKernel[a_,b_,n_]:=FeynFacet`FactorizationSchemeKernel["HelicityMSbar",a,b,"L",hsX,hsParameters,n];
hsValue[a_,b_,n_]:=hsKernel[a,b,n]["RegularCoefficient"];
hsH=hsValue[{"q","u"},{"q","u"},1];
hsSea=hsValue[{"q","d"},{"q","u"},2];
hsV=hsValue[{"q","u"},{"q","u"},2]-hsSea;
hsVbar=hsValue[{"qb","u"},{"q","u"},2]-hsSea;
FTTest`FTAssert["order-zero matrix includes the gluon identity",
 And@@Flatten[Table[hsKernel[a,b,0]["DeltaCoefficient"]===If[a===b,1,0],{a,hsSpecies},{b,hsSpecies}]]];
FTTest`FTAssert["the first finite kernel has the conserved nonsinglet moment",
 Integrate[hsH,{hsX,0,1}]===-2hsCF];
FTTest`FTAssert["the sea is per flavor and independent of the number of flavors",
 FreeQ[hsSea,hsNF]&&FullSimplify[Integrate[hsSea,{hsX,0,1}]-3hsCF hsTR/8]===0];
FTTest`FTAssert["quark-antiquark conjugation and flavor-exchange symmetry",
 And@@Flatten[Table[hsValue[a,b,2]===hsValue[b,a,2],{a,hsSpecies},{b,hsSpecies}]]&&
 hsValue[{"qb","d"},{"q","u"},2]===hsSea&&
 hsValue[{"qb","d"},{"qb","d"},2]===hsV+hsSea];
FTTest`FTAssert["gluon finite mixing is zero through second order",
 And@@Flatten[Table[hsValue["g",a,n]===0&&hsValue[a,"g",n]===0,{a,hsSpecies},{n,1,2}]]];
(* Independent 1409.5131 A.2 in its HPL form, divided by four to
   convert alpha_s/(4 Pi) to alpha_s/(2 Pi). *)
hsH10=-PolyLog[2,hsX]-Log[hsX]Log[1-hsX];hsH2=PolyLog[2,hsX];
hsHm10=Log[hsX]Log[1+hsX]+PolyLog[2,-hsX];hsH00=Log[hsX]^2/2;
hsIndependentNS=2hsCF^2((1-hsX)(5-2hsH10-2hsH2)-
 2(1+hsX)(2hsHm10-hsH00+Zeta[2])+(1+2hsX)Log[hsX])+
 hsCF hsCA(4(1+hsX)hsHm10-4(hsH00-Zeta[2])-
 (29+7hsX)Log[hsX]/3-211(1-hsX)/9)+
 2hsCF hsNF(1-hsX)(3Log[hsX]+5)/9;
FTTest`FTAssert["full flavor kernels reproduce the independent nonsinglet expression",
 Expand[((hsV+hsVbar)/.hsTR->1/2)-hsIndependentNS]===0];
(* Keep substitution precedence explicit. *)
FTTest`FTAssert["independent pure-singlet expression has the required 2 nf multiplicity",
 Expand[(2hsNF hsSea/.hsTR->1/2)-
 hsCF hsNF((2+hsX)hsH00+(3-hsX)Log[hsX]+2(1-hsX))]===0];
hsMoment=NIntegrate[Evaluate[(hsV+hsVbar)/.{hsCF->4/3,hsCA->3,hsTR->1/2,hsNF->4}],
 {hsX,0,1},WorkingPrecision->50,AccuracyGoal->35,PrecisionGoal->35];
hsExpectedMoment=(11hsCF^2/2-107hsCF hsCA/36+hsCF hsNF/18)/.{hsCF->4/3,hsCA->3,hsNF->4};
FTTest`FTAssert["first nonsinglet NNLO moment matches the axial-operator normalization",
 Abs[hsMoment-hsExpectedMoment]<10^-32];
hsExplicit=<|"Variable"->hsX,"DeltaCoefficient"->0,"PlusCoefficients"-><||>,"RegularCoefficient"->hsX|>;
hsScheme=<|"FiniteKernelsByOrder"-><|2-><|{{"q","u"},{"q","u"},"L"}->hsExplicit|>|>|>;
FTTest`FTAssert["a card can override a single finite coefficient at an explicit order",
 FeynFacet`FactorizationSchemeKernel[hsScheme,{"q","u"},{"q","u"},"L",hsX,hsParameters,2]["RegularCoefficient"]===hsX&&
 FeynFacet`FactorizationSchemeKernel[hsScheme,{"q","u"},{"q","u"},"L",hsX,hsParameters,1]["RegularCoefficient"]===0];
FTTest`FTAssert["an unlabelled first-order kernel cannot silently be reused at NNLO",
 FailureQ[FeynFacet`FactorizationSchemeKernel[hsExplicit,{"q","u"},{"q","u"},"L",hsX,hsParameters,2]]];
FTTest`FTAssert["unknown helicity orders are not padded with zero",
 FailureQ[hsKernel[{"q","u"},{"q","u"},3]]];
FTTest`FTReport[];
