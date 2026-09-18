Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
FeynCalc`FCSetDiracGammaScheme["BMHV"];FeynCalc`$LeviCivitaSign=-1;
bmReq=<|"Momenta"->{bmP,bmQ,bmK,bmL},"PhysicalMomenta"->{bmP,bmQ},
 "Gamma5Scheme"->"BMHV"|>;
bmExamples={
 {"unit Dirac trace",FeynCalc`DiracTrace[1],4},
 {"single gamma5 trace",FeynCalc`DiracTrace[FeynCalc`GA[5]],0},
 {"epsilon trace convention",FeynCalc`DiracTrace[
   FeynCalc`GAD[bmA].FeynCalc`GAD[bmB].FeynCalc`GAD[bmC].FeynCalc`GAD[bmE].FeynCalc`GA[5]],
   -4I FeynCalc`LC[bmA,bmB,bmC,bmE]},
 {"gamma5 square",FeynCalc`DiracTrace[FeynCalc`GA[5].FeynCalc`GA[5]],4},
 {"BMHV contracted gamma5",FeynCalc`DiracTrace[FeynCalc`GA[5].FeynCalc`GAD[bmMu].FeynCalc`GA[5].FeynCalc`GAD[bmMu]],4(D-8)},
 {"physical epsilon norm",FeynCalc`LC[bmA,bmB,bmC,bmE]^2,-24},
 {"physical projector trace",FeynCalc`MT[bmMu,bmNu]FeynCalc`MTD[bmNu,bmMu],4},
 {"evanescent projector trace",FeynCalc`MTE[bmMu,bmNu]FeynCalc`MTD[bmNu,bmMu],D-4},
 {"integrated projected dot",FeynCalc`FV[bmK,bmMu]FeynCalc`FVD[bmL,bmMu],FeynCalc`SP[bmK,bmL]},
 {"integrated vector gamma5",FeynCalc`DiracTrace[FeynCalc`GA[5].FeynCalc`GSD[bmK].FeynCalc`GA[5].FeynCalc`GSD[bmL]],
 4(FeynCalc`SPD[bmK,bmL]-2FeynCalc`SP[bmK,bmL])}
};
bmExamples=Join[bmExamples,{
 {"single gamma5 contraction is BMHV, not NDR",
  FeynCalc`DiracTrace[FeynCalc`GAD[bmMu].FeynCalc`GA[bmA].FeynCalc`GA[bmB].
   FeynCalc`GA[bmC].FeynCalc`GA[bmE].FeynCalc`GAD[bmMu].FeynCalc`GA[5]],
  -4I(D-8)FeynCalc`LC[bmA,bmB,bmC,bmE]},
 {"two nonadjacent gamma5 insertions retain quadratic dimension terms",
  FeynCalc`DiracTrace[FeynCalc`GA[5].FeynCalc`GAD[bmMu].FeynCalc`GAD[bmNu].
   FeynCalc`GA[5].FeynCalc`GAD[bmMu].FeynCalc`GAD[bmNu]],4(2D-(D-8)^2)},
 {"chiral projectors include the FeynCalc factor one half",
  FeynCalc`DiracTrace[FeynCalc`GA[6].FeynCalc`GA[6]],2},
 {"opposite chiral projectors vanish",
  FeynCalc`DiracTrace[FeynCalc`GA[6].FeynCalc`GA[7]],0},
 {"physical and evanescent subspaces are orthogonal",
  FeynCalc`MT[bmA,bmB]FeynCalc`MTE[bmB,bmC],0}
}];
bmX=FeynCalc`GAD[bmMu].FeynCalc`GA[5].FeynCalc`GAD[bmMu]+D FeynCalc`GA[5];
bmY=FeynCalc`GAD[bmNu].FeynCalc`GA[5].FeynCalc`GAD[bmNu]+D FeynCalc`GA[5];
AppendTo[bmExamples,{"first nonzero epsilon squared term is preserved",
 FeynCalc`DiracTrace[bmX.bmY],16(D-4)^2}];
bmFour=FeynCalc`GA[bmA].FeynCalc`GA[bmB].FeynCalc`GA[bmC].FeynCalc`GA[bmE];
bmT4=FeynCalc`DiracTrace[bmFour.FeynCalc`GA[5]];
bmA6=FeynCalc`DiracTrace[FeynCalc`GAD[bmMu].bmFour.FeynCalc`GAD[bmMu].FeynCalc`GA[5]];
bmA8=FeynCalc`DiracTrace[FeynCalc`GAD[bmMu].FeynCalc`GAD[bmNu].bmFour.
 FeynCalc`GAD[bmNu].FeynCalc`GAD[bmMu].FeynCalc`GA[5]];
bmExamples=Join[bmExamples,{
 {"single gamma5 with eight ordinary matrices gives (D-8) squared",
  bmA8,-4I(D-8)^2 FeynCalc`LC[bmA,bmB,bmC,bmE]},
 {"single gamma5 alone retains the first nonzero epsilon squared term",
  bmA8+2D bmA6+D^2 bmT4,-16I(D-4)^2 FeynCalc`LC[bmA,bmB,bmC,bmE]},
 {"hatted unselected arguments can return from Clifford grade six",
  FeynCalc`DiracTrace[bmFour.FeynCalc`GAE[bmMu].FeynCalc`GAE[bmNu].
   FeynCalc`GAE[bmNu].FeynCalc`GAE[bmMu].FeynCalc`GA[5]],
  -4I(D-4)^2 FeynCalc`LC[bmA,bmB,bmC,bmE]}
}];
bmLinked=FeynCalc`DiracTrace[FeynCalc`GAD[bmMu].bmFour.FeynCalc`GAD[bmNu].FeynCalc`GA[5]];
bmVectorEpsilon=FeynCalc`Eps@@(FeynCalc`Momentum/@{bmP,bmQ,bmK,bmL});
bmExamples=Join[bmExamples,{
 {"a physical projector sandwich retains the BMHV physical trace",
  FeynCalc`MT[bmMu,bmNu]bmLinked,16I FeynCalc`LC[bmA,bmB,bmC,bmE]},
 {"an evanescent projector sandwich retains D minus four",
  FeynCalc`MTE[bmMu,bmNu]bmLinked,-4I(D-4)FeynCalc`LC[bmA,bmB,bmC,bmE]},
 {"three shared epsilon indices retain the sign of an odd permutation",
  FeynCalc`LC[bmMu,bmNu,bmRho,bmA]FeynCalc`LC[bmNu,bmMu,bmRho,bmB],6FeynCalc`MT[bmA,bmB]},
 {"two shared epsilon indices contract within rank four",
  FeynCalc`LC[bmMu,bmNu,bmA,bmB]FeynCalc`LC[bmMu,bmNu,bmC,bmE],
  -2(FeynCalc`MT[bmA,bmC]FeynCalc`MT[bmB,bmE]-FeynCalc`MT[bmA,bmE]FeynCalc`MT[bmB,bmC])},
 {"repeated vector arguments across epsilons are not Einstein sums",
  bmVectorEpsilon^2,-Det[Outer[FeynCalc`SP,{bmP,bmQ,bmK,bmL},{bmP,bmQ,bmK,bmL}]]},
 {"a vector component contracts directly into the ordered gamma word",
  FeynCalc`FVD[bmK,bmMu]FeynCalc`DiracTrace[FeynCalc`GAD[bmMu].FeynCalc`GSD[bmP].
   FeynCalc`GSD[bmQ].FeynCalc`GSD[bmL].FeynCalc`GA[5]],
  -4I Apply[FeynCalc`Eps,FeynCalc`Momentum/@{bmK,bmP,bmQ,bmL}]}
}];
bmCanonicalEpsilon[expression_]:=expression/.FeynCalc`Eps[args__]:>
 With[{arguments={args}},If[DuplicateFreeQ[arguments],
  Signature[Ordering[arguments]]Apply[FeynCalc`Eps,Sort[arguments]],0]];
Do[
 Print["CASE ",method," / ",row[[1]]];
 bmResult=FeynFacet`EvaluateFORMDiracExpression[row[[2]],Join[bmReq,<|"Gamma5TraceMethod"->method|>]];
 If[!AssociationQ[bmResult],Print["RESULT ",InputForm[bmResult]]];
 If[AssociationQ[bmResult]&&Factor[bmCanonicalEpsilon[bmResult["Value"]-FeynCalc`FCI[row[[3]]]]]=!=0,
  Print["DIFFERENCE ",row[[1]]," ",Factor[bmCanonicalEpsilon[bmResult["Value"]-FeynCalc`FCI[row[[3]]]]]]];
 FTTest`FTAssert[method<>" / "<>row[[1]],AssociationQ[bmResult]&&Factor[bmCanonicalEpsilon[bmResult["Value"]-FeynCalc`FCI[row[[3]]]]]===0],
 {method,{"Definition","FeynCalc","GradeFour"}},{row,bmExamples}];
FTTest`FTReport[];
