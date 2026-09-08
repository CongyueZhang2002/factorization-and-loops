#!/usr/bin/env wolframscript

ClearAll["Global`*"];

workDirectory = "/home/maxzhang/factorization-and-loops/Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17";
Get[FileNameJoin[{workDirectory, "ExternalBaikovPackage", "BaikovPackage.m"}]];

zeroQ[expr_] := Together[Factor[expr]] === 0;

externalRules = {
  ka^2 -> 0,
  kb^2 -> 0,
  kc^2 -> 0,
  ka kb -> 1/2,
  ka kc -> v/2,
  kb kc -> w/2
};

build[name_, propagators_, cuts_] := Module[
  {components, externalGram, baikovPolynomial, cutPolynomial, report},

  BaikovPackage`Internal = {ke, kf};
  BaikovPackage`External = {ka, kb, kc};
  BaikovPackage`Propagators = propagators;
  BaikovPackage`PropagatorsExtra = {};
  BaikovPackage`Replacements = externalRules;

  components = BaikovPackage`BaikovStandard[];
  If[components === 0, Print[name, ": construction failed"]; Exit[1]];

  externalGram = Factor[components[[1, 1]]];
  baikovPolynomial = Factor[components[[1, 2]]];
  cutPolynomial = Factor[
    baikovPolynomial /. Thread[(BaikovPackage`x /@ cuts) -> 0]
  ];

  report = <|
    "Family" -> name,
    "LoopMomenta" -> {ke, kf},
    "ExternalMomenta" -> {ka, kb, kc},
    "Propagators" -> propagators,
    "Cuts" -> cuts,
    "ExternalGram" -> externalGram,
    "BaikovPolynomial" -> baikovPolynomial,
    "CutBaikovPolynomial" -> cutPolynomial,
    "Powers" -> components[[2]],
    "Prefactors" -> components[[3]],
    "Rules" -> components[[4]],
    "CutPolynomialFreeOfCutVariables" ->
      FreeQ[cutPolynomial, Alternatives @@ (BaikovPackage`x /@ cuts)]
  |>;

  Put[report, FileNameJoin[{workDirectory, "CutBaikov_" <> name <> ".wl"}]];
  Print[name, ": external Gram = ", externalGram];
  Print[name, ": cut polynomial variables = ", Variables[cutPolynomial]];
  Print[name, ": cut polynomial bytes = ", ByteCount[cutPolynomial]];
  report
];

cf1 = build[
  "CF1",
  {
    kf^2,
    ke^2,
    (-ka + kc + kf)^2,
    (-ka - kb + kc + kf)^2,
    (ka + kb - kc - ke - kf)^2,
    ka ke,
    ka kf,
    kb ke,
    kc ke
  },
  {1, 2, 5}
];

cf199 = build[
  "CF199",
  {
    kf^2,
    ke^2,
    (-ka + ke)^2,
    (-kc - kf)^2,
    (-kc - ke)^2,
    (-kc - ke - kf)^2,
    (ka - kc - ke - kf)^2,
    (ka + kb - kc - ke - kf)^2,
    kb ke
  },
  {1, 2, 8}
];

If[! And[cf1["CutPolynomialFreeOfCutVariables"],
         cf199["CutPolynomialFreeOfCutVariables"]],
  Print["Cut residue substitution retained a cut variable."];
  Exit[1]
];

Print["CUT_BAIKOV_CONSTRUCTION_EXACT = True"];
