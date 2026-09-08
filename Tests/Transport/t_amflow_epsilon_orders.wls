#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Block[{Print},Get[root<>"/Addon/Mathematica_Addon/AMFlow/AMFlow.m"]];
Clear[kl,ll,orderFamily];
top=FeynCalc`FCTopology[orderFamily,
 {FeynCalc`SFAD[{kl,1}],FeynCalc`SFAD[{ll,1}],FeynCalc`SFAD[kl-ll]},
 {kl,ll},{},{},{}];
data=<|"Topology"->top,"Master"->FeynCalc`GLI[orderFamily,{1,1,0}],
 "Prescription"->{1,1},"CutIndices"->{}|>;
expected=3/Global`Epsilon^2+5/Global`Epsilon+7+11Global`Epsilon;
(* Exercise the real vendor sampling, fitting and truncation. Only the
   expensive integration is replaced by exactly known Laurent samples. *)
Block[{AMFlow`BlackBoxAMFlow},
 AMFlow`BlackBoxAMFlow[targets_,samples_] := Thread[targets->
  ConstantArray[(3/#^2+5/#+7+11#+13#^2& /@ samples),Length[targets]]];
 got=FeynFacet`MasterIntegralAmFlow[data,{},"EpsilonOrder"->1,"PrecisionGoal"->25];
 FTAssert["a two-loop request through epsilon one retains every nonzero coefficient",
  Max[Abs[Table[Coefficient[got-expected,Global`Epsilon,k],{k,-2,1}]]]<10^-20];
 got=FeynFacet`MasterIntegralAmFlow[data,{},"EpsilonOrder"->-2,"PrecisionGoal"->25];
 FTAssert["negative upper orders retain the leading nonzero pole",
  Abs[Coefficient[got,Global`Epsilon,-2]-3]<10^-20 && Exponent[got,Global`Epsilon]===-2];
 got=FeynFacet`MasterIntegralAmFlow[data,{OtherRegulator`ep->1/10},
  "EpsilonOrder"->0,"PrecisionGoal"->25];
 FTAssert["fixed numerical regulators are values rather than Laurent expansions",
  Abs[got-(3/(1/10)^2+5/(1/10)+7+11/10+13/100)]<10^-20];
];
FTReport[];
