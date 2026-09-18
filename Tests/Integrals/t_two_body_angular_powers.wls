Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mixed=FeynFacet`ReduceTwoBodyAngularPowers[{1,1},{{9/25,-1/10},{-1/10,1}},eps];
If[!AssociationQ[mixed],Print[mixed];Exit[1]];
series=FeynFacet`ExpandTwoBodyAngularSeeds[mixed,1];
FTTest`FTAssert["one-mass pair has the expected collinear residue",
 AssociationQ[series]&&series["Coefficients"][-1]===-5/11];
point=-1/1000;
poly[data_]:=Total[KeyValueMap[#2 eps^#1&,data["Coefficients"]]];
residual[e0_]:=N[(mixed["ExactExpression"]-poly[series])/.eps->e0,30];
a=Abs[residual[point]];b=Abs[residual[point/2]];
Print["MIXED REMAINDER RATIO ",a/b];
FTTest`FTAssert["explicit mixed seed has an epsilon-squared remainder",NumericQ[a/b]&&3.9<a/b<4.1];
one=FeynFacet`ReduceTwoBodyAngularPowers[{1},{{9/25}},eps];
oneSeries=FeynFacet`ExpandTwoBodyAngularSeeds[one,1];
FTTest`FTAssert["massive one-denominator zeroth order matches elementary polar integration",
 FullSimplify[oneSeries["Coefficients"][0]-5Log[4]/6]===0];
raised=FeynFacet`ReduceTwoBodyAngularPowers[{2,2},{{9/25,-1/10},{-1/10,1}},eps];
(* Independent Euler/Appell expression, Somogyi Eq.56, j=k=2. *)
beta=3/5;v=11/20;
exact=2^-4 Gamma[-1-eps]Gamma[2-2eps]/(Gamma[1-eps]Gamma[-2eps])*v^-2*
 AppellF1[2,-1-eps,-1-eps,-2eps,1-(1+beta)/(2v),1-(1-beta)/(2v)];
FTTest`FTAssert["raised mixed powers agree with the independent Appell representation",
 Abs[N[(raised["ExactExpression"]-exact)/.eps->N[-5/4,35],30]]<10^-24];
null=FeynFacet`ReduceTwoBodyAngularPowers[{2,3},{{1,1/5},{1/5,1}},eps];
exact=2^-5 Gamma[2-2eps]Gamma[-1-eps]Gamma[-2-eps]/
 (Gamma[1-eps]^2 Gamma[-3-2eps])*Hypergeometric2F1[2,3,1-eps,3/5];
FTTest`FTAssert["raised massless powers agree with the independent Gauss representation",
 Abs[N[(null["ExactExpression"]-exact)/.eps->N[-13/4,35],30]]<10^-24];
moment=FeynFacet`ReduceTwoBodyAngularPowers[{-2,0},{{1,0},{0,1}},eps];
FTTest`FTAssert["polynomial angular moments retain D minus one",
 Together[moment["ExactExpression"]-1-1/(3-2eps)]===0];
weighted=FeynFacet`ReduceTwoBodyAngularPowers[{-2,1},{{1,0},{0,1}},eps];
FTTest`FTAssert["a numerator normal to a null denominator retains the D minus two conditional average",
 Together[weighted["ExactExpression"]-FeynFacet`Private`angularNullMoment[1,eps]-1/(2-2eps)]===0];
FTTest`FTAssert["unimplemented higher epsilon orders fail explicitly",
 FailureQ[FeynFacet`ExpandTwoBodyAngularSeeds[mixed,2]]];
variableSeed=<|"Type"->"SingleMassive","MassInvariant"->(1-u)/4|>;
variableCoefficients=FeynFacet`Private`angularSeedCoefficients[variableSeed,eps,1];
FTTest`FTAssert["symbolic massive seed contains its explicit removable zero-velocity value",
 Quiet[Values[variableCoefficients]/.u->0]==={1,0}];
FTTest`FTAssert["small-velocity seed coefficients agree with the analytic beta-squared jets",
 Max[Abs[N[(Values[variableCoefficients]/.u->10^-8)-{1+10^-8/3+10^-16/5,2*10^-8/9+16*10^-16/75},45]]]<10^-23];
Print["TWO BODY ANGULAR POWERS TEST COMPLETE"];FTTest`FTReport[];
