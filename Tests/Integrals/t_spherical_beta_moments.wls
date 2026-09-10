$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
sbY=sbR+sbU-2sbR sbU-2Sqrt[sbR(1-sbR)sbU(1-sbU)]sbCos;
sbDirect[p_,q_,rr_] := Module[{pol,rows},
 pol=Expand[sbY^p sbU^q sbR^rr];
 pol=Sum[Coefficient[pol,sbCos,k]If[OddQ[k],0,Pochhammer[1/2,k/2]/Pochhammer[sbAlpha,k/2]],
  {k,0,p}];
 pol=Expand[pol];rows=CoefficientRules[pol,{sbR,sbU}];
 Total[(Last[#]Times@@(Pochhammer[sbAlpha,First[#]]/Pochhammer[2sbAlpha,First[#]]))&/@rows]
];
Do[
 sbIntegral=FeynFacet`EvaluateSphericalBetaMoment[sbR^powers[[3]]sbU^powers[[2]]sbV^powers[[1]],
 {sbR,sbU,sbV},sbAlpha];
 sbExpected=sbDirect@@powers;
 FTTest`FTAssert["spherical convolution agrees with direct polynomial moment "<>ToString[powers,InputForm],
  FullSimplify[FunctionExpand[sbIntegral-sbExpected]]===0],
 {powers,{{0,0,0},{1,1,0},{2,1,1},{2,2,2},{3,1,0},{4,0,1}}}];
sbComplement=FeynFacet`EvaluateSphericalBetaMoment[1/((1-sbU)sbV),{sbR,sbU,sbV},sbAlpha];
sbSame=FeynFacet`EvaluateSphericalBetaMoment[1/(sbU sbV),{sbR,sbU,sbV},sbAlpha];
FTTest`FTAssert["opposite axes have the same fully averaged two-denominator moment",
 FullSimplify[FunctionExpand[sbComplement-sbSame]]===0];
sbUnsupported=FeynFacet`EvaluateSphericalBetaMoment[1/(1+sbR sbU),{sbR,sbU,sbV},sbAlpha];
FTTest`FTAssert["an unrecognized angular denominator is rejected",FailureQ[sbUnsupported]];
FTTest`FTReport[];
