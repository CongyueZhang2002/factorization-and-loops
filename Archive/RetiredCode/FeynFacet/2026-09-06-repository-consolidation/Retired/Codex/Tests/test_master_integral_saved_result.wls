$HistoryLength = 0;
$IterationLimit = 10^6;

Get["/home/maxzhang/FACET/Addon/Load/LoadFACET.wl"];

result = Get[
  "/home/maxzhang/FACET/ppHX_NLO/Results/UU_08_05_10x10_1/CoefficientResult.wl"
];
master = First[result["Masters"]]["Master"];
expected = 0.0313309150055351756973853011885167079`18;

value = FeynFacet`MasterIntegralAmFlow[
  result,
  master,
  {
    FeynCalc`SPD[ka, kb] -> 5,
    FeynCalc`SPD[ka, kc] -> 3/2,
    FeynCalc`SPD[kb, kc] -> 1,
    Epsilon -> -1/10
  },
  "PrecisionGoal" -> 18,
  "EpsilonOrder" -> 0,
  "Threads" -> 1,
  "TimeConstraint" -> 1200
];

relativeDifference = Abs[value - expected]/Abs[expected];
criterion = TrueQ[relativeDifference < 10^-15];

Print["Master: ", InputForm[master]];
Print["Value: ", InputForm[value]];
Print["Relative difference: ", InputForm[relativeDifference]];
Print["Acceptance criterion relative difference < 10^-15: ", criterion];

Exit[If[criterion, 0, 1]];
