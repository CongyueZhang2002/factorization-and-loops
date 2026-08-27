#!/usr/bin/env wolframscript

$HistoryLength = 0;
Internal`InheritedBlock[{System`$ContextPath, System`$Packages},
BeginPackage["CodexCF300Sector12StripRescalingDiagnosticV1`"];
Begin["`Private`"];

Module[{oldFile, freshFile, dataContext, old, fresh, oldStrip,
    freshStrip, x, y, eps, rho, delta, scalar, toRho, remainder,
    cDifferences, rules, bRatios, sampleDifferences, report},
  oldFile =
    "/home/maxzhang/factorization-and-loops/External/CodexExchange/" <>
    "triple_root_2026-08-22/cf300_sector12_physical_rank3_xh/" <>
    "physical_sidecar_evidence_2026-08-23_xh_v3/CF300_12_11_input.wl";
  freshFile =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
    "cf300_sector12_recapture_from_v4_xh_v2/sector_CF300_standard/" <>
    "CF300_12_11_input.wl";
  dataContext = "CodexCF300Sector12StripRescalingDiagnosticV1`Data`";
  old = Block[{$Context = dataContext, $ContextPath = {"System`"}},
    Get[oldFile]];
  fresh = Block[{$Context = dataContext, $ContextPath = {"System`"}},
    Get[freshFile]];
  oldStrip = old["Strip"];
  freshStrip = fresh["Strip"];
  {x, y} = fresh["Variables"];
  eps = fresh["Regulator"];
  rho = Symbol[dataContext <> "rho"];
  delta = 1 - 4 x y;
  scalar = ((2 eps - 1) (3 eps - 1) (3 eps - 2))/eps^3;
  toRho[expression_] := expression /. Sqrt[delta] -> rho;
  remainder[expression_] := Module[{rational = Together[toRho[expression]]},
    <|"Rational" -> rational,
      "ResidualSqrtCount" -> Length[Cases[rational, _Sqrt, Infinity]],
      "Remainder" -> PolynomialRemainder[
        Numerator[rational], rho^2 - delta, rho]|>];
  cDifferences = remainder /@ Flatten[freshStrip[[2]] - oldStrip[[2]]];
  rules = {x -> 1/4, y -> 3/4, eps -> 2/5};
  bRatios = MapThread[
    Together[(#1 /. rules)/(#2 /. rules)] &,
    {freshStrip[[3]], oldStrip[[3]]}, 2];
  sampleDifferences = <|
    "E" -> Together /@ Flatten[(freshStrip[[1]] - oldStrip[[1]]) /. rules],
    "C" -> Together /@ Flatten[(freshStrip[[2]] - oldStrip[[2]]) /. rules],
    "BExpected" -> Together /@
      Flatten[(freshStrip[[3]] - scalar oldStrip[[3]]) /. rules],
    "BInverse" -> Together /@
      Flatten[(freshStrip[[3]] - oldStrip[[3]]/scalar) /. rules]|>;
  report = <|
    "CDifferences" -> cDifferences,
    "SampleRules" -> rules,
    "ExpectedScalarAtSample" -> Together[scalar /. rules],
    "BRatiosAtSample" -> bRatios,
    "SampleDifferences" -> sampleDifferences|>;
  Print["CF300 S12 STRIP RESCALING DIAGNOSTIC V1 ", InputForm[report]];
  CodexCF300Sector12StripRescalingDiagnosticV1`Private`finalResult = 0;
];

With[{resolved =
    CodexCF300Sector12StripRescalingDiagnosticV1`Private`finalResult},
  End[];
  EndPackage[];
  Quiet[System`Remove[
    "CodexCF300Sector12StripRescalingDiagnosticV1`Data`*"]];
  Quiet[System`Remove[
    "CodexCF300Sector12StripRescalingDiagnosticV1`Private`*"]];
  Quiet[System`Remove[
    "CodexCF300Sector12StripRescalingDiagnosticV1`*"]];
  resolved]]
