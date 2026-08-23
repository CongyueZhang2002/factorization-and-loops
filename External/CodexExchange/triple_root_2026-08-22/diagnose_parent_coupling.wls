#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2, Exit[64]];
record = Get[ExpandFileName[arguments[[1]]]];
coupling = Get[ExpandFileName[arguments[[2]]]];
variables = record["Variables"];
epsilon = record["Regulator"];
chartPair = coupling["ChartPair"];
prime = 1000003;
epsilonValue = 1/7;
point = {123457, 456791};
rules = Join[Thread[variables -> point], {epsilon -> epsilonValue}];
evaluated = chartPair /. rules;
firstValue = evaluated[[1, 1, 1]];

modNumber[value_] := Module[{q = Together[value], denominator},
  If[Cases[q, _Symbol, {0, Infinity}, Heads -> False] =!= {},
    Return[$Failed]];
  denominator = Mod[Denominator[q], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Mod[Numerator[q], prime] PowerMod[denominator, -1, prime], prime]
];

Print["TRCOUPLING variables=", InputForm[variables],
  " contexts=", InputForm[Context /@ variables]];
Print["TRCOUPLING epsilon=", InputForm[epsilon],
  " context=", InputForm[Context[epsilon]]];
Print["TRCOUPLING dimensions=", Dimensions[chartPair],
  " remaining_symbols=", InputForm[
    DeleteDuplicates[Cases[evaluated, _Symbol, Infinity]]]];
Print["TRCOUPLING denominator_zero_positions=", InputForm[
  Flatten[Position[
    Mod[Denominator[Together[#]], prime] & /@ Flatten[evaluated], 0]]]];
Print["TRCOUPLING first_value=", InputForm[firstValue],
  " free_of_symbols=", FreeQ[Together[firstValue], _Symbol],
  " numerator_mod=", Mod[Numerator[Together[firstValue]], prime],
  " denominator_mod=", Mod[Denominator[Together[firstValue]], prime],
  " inverse=", PowerMod[
    Mod[Denominator[Together[firstValue]], prime], -1, prime],
  " direct=", Mod[
    Mod[Numerator[Together[firstValue]], prime] PowerMod[
      Mod[Denominator[Together[firstValue]], prime], -1, prime], prime]];
Print["TRCOUPLING mod_number_first=", InputForm[modNumber[firstValue]],
  " definition=", InputForm[DownValues[modNumber]]];
Print["TRCOUPLING converted=", InputForm[
  Map[modNumber, evaluated, {3}]]];
