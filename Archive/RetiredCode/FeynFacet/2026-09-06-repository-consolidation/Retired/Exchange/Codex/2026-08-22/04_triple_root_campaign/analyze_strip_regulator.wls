#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[arguments === {}, Exit[64]];
record = Get[ExpandFileName[First[arguments]]];
{e, c, bbar} = record["Strip"];
{x, y} = record["Variables"];
epsilon = record["Regulator"];

polynomialOrder[0] := Infinity;
polynomialOrder[polynomial_] := Min[
  First /@ (First /@ CoefficientRules[Expand[polynomial], {epsilon}])];
rationalValuation[expression_] := Module[{q = Together[expression]},
  polynomialOrder[Numerator[q]] - polynomialOrder[Denominator[q]]];

valuations = rationalValuation /@ Flatten[bbar];
compatibility = D[bbar[[2]], x] - D[bbar[[1]], y] -
  epsilon (e[[1]] . bbar[[2]] - bbar[[2]] . c[[1]]) +
  epsilon (e[[2]] . bbar[[1]] - bbar[[1]] . c[[2]]);
sampleRules = {x -> 2/7, y -> 3/11, epsilon -> 5/13};
sampleResidual = Map[Together[#1 /. sampleRules] &, compatibility, {2}];

Print["TRREGULATOR strip=", {record["Sector"], record["LowerSector"]},
  " diagonal_eps_free=", FreeQ[{e, c}, epsilon],
  " forcing_valuations=", InputForm[valuations],
  " min=", Min[valuations], " max=", Max[valuations],
  " compatibility_sample_zero=",
  AllTrue[Flatten[sampleResidual], TrueQ[#1 === 0] &],
  " nonzero_sample_entries=",
  Count[Flatten[sampleResidual], Except[0]]];
