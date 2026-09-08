#!/usr/bin/env wolframscript

ClearAll["Global`*"];

workDirectory = "/home/maxzhang/factorization-and-loops/Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17";
Get[FileNameJoin[{workDirectory, "ExternalBaikovPackage", "BaikovPackage.m"}]];

externalRules = {
  ka^2 -> 0,
  kb^2 -> 0,
  kc^2 -> 0,
  ka kb -> 1/2,
  ka kc -> v/2,
  kb kc -> w/2
};

propagators = {
  kf^2,
  ke^2,
  (-ka + ke)^2,
  (-kc - kf)^2,
  (-kc - ke)^2,
  (-kc - ke - kf)^2,
  (ka - kc - ke - kf)^2,
  (ka + kb - kc - ke - kf)^2,
  kb ke
};

BaikovPackage`Internal = {ke, kf};
BaikovPackage`External = {ka, kb, kc};
BaikovPackage`Propagators = propagators;
BaikovPackage`PropagatorsExtra = {};
BaikovPackage`Replacements = externalRules;

components = BaikovPackage`BaikovLBL[];
If[components === 0, Print["CF199 LBL construction failed"]; Exit[1]];

cuts = {1, 2, 8};
cutRules = Thread[(BaikovPackage`x /@ cuts) -> 0];
cutPolynomials = Factor[# /. cutRules] & /@ components[[1]];
combined = Factor[BaikovPackage`BaikovCombine[components] /. cutRules];

report = <|
  "Family" -> "CF199",
  "Representation" -> "LoopByLoopBaikov",
  "LoopMomenta" -> {ke, kf},
  "Cuts" -> cuts,
  "Polynomials" -> components[[1]],
  "CutPolynomials" -> cutPolynomials,
  "Powers" -> components[[2]],
  "Prefactors" -> components[[3]],
  "Rules" -> components[[4]],
  "CutCombinedIntegrand" -> combined
|>;

Put[report, FileNameJoin[{workDirectory, "CutBaikovLBL_CF199.wl"}]];
Print["polynomial count = ", Length[cutPolynomials]];
Do[
  Print["polynomial ", i, " variables = ", Variables[cutPolynomials[[i]]]];
  Print["polynomial ", i, " bytes = ", ByteCount[cutPolynomials[[i]]]],
  {i, Length[cutPolynomials]}
];
Print["powers = ", components[[2]]];
Print["prefactors = ", components[[3]]];
Print["CUT_LBL_BAIKOV_CONSTRUCTION_EXACT = True"];
