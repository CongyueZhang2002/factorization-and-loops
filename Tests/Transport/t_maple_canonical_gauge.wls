#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`mapleGaugeX"];
y = Symbol["Global`mapleGaugeY"];
eps = Symbol["Global`mapleGaugeEpsilon"];
rootRecord = <|"RootSquare" -> 1 + x,
  "Root" -> Sqrt[1 + x]|>;
rawGauge = {{1/(1 + Sqrt[1 + x])}};
capturedPayload = None;
canonicalRunner = Function[payload,
  capturedPayload = payload;
  <|"OutputLines" -> {"OK", "(-1+sqrt(1+mapleGaugeX))/mapleGaugeX"}|>];

canonical = FeynFacet`Private`transportChartMapleCanonicalGauge[
  rawGauge, {x, y}, eps, {rootRecord},
  "ScratchDirectory" -> $TemporaryDirectory,
  "Tag" -> "maple_canonical_gauge_test",
  "Runner" -> canonicalRunner];

FTAssert["the Maple bridge serializes declared square roots and requests algebraic Normal",
  AssociationQ[capturedPayload] &&
    StringContainsQ[capturedPayload["MapleText"], "sqrt(1+mapleGaugeX)"] &&
    StringContainsQ[capturedPayload["MapleText"],
      "evala(Normal(feynfacetGaugeEntries[i]))"]];

FTAssert["a square-root Maple normal form is parsed without changing shape",
  AssociationQ[canonical] &&
    canonical["Status"] === "MapleCanonicalGaugePrepared" &&
    Dimensions[canonical["Result"]] === Dimensions[rawGauge] &&
    TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[
      canonical["Result"][[1, 1]] - rawGauge[[1, 1]], {rootRecord}]]];

FTDone[];
