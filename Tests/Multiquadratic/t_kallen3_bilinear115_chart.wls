#!/usr/bin/env wolframscript
(* Exact catalog and inverse-composition coverage for the joint charts of
   lambda2/lambda3 and 1-4 v w.  The charts are mathematical catalog data:
   no family name or family root index participates in lookup. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[v, w, p, u, a, b];
lambda3[x_, y_] := (1 - x + y)^2 + 4 x y;
lambda2[x_, y_] := (1 + x - y)^2 + 4 x y;
bilinear[x_, y_] := 1 - 4 x y;

catalog = FeynFacet`TransportChartCatalog[];
chart = Lookup[catalog, "Kallen3Bilinear115", Missing["NotInCatalog"]];
FTAssert["A1 joint chart is present under a family-independent name",
  AssociationQ[chart] && chart["Name"] === "Kallen3Bilinear115"];

certificate = FeynFacet`TransportChartVerify[chart];
FTAssert["A2 exact chart certificate passes both roots and the parent map",
  TrueQ[certificate["OK"]] && certificate["RootIdentities"] === {True, True} &&
    TrueQ[certificate["ParentMaps", "Kallen3"]]];

matched = FeynFacet`TransportRootSetChart[
  {lambda3[v, w], bilinear[v, w]}, {v, w}];
matchedReversed = FeynFacet`TransportRootSetChart[
  {bilinear[v, w], lambda3[v, w]}, {v, w}];
matchedRenamed = FeynFacet`TransportRootSetChart[
  {lambda3[a, b], bilinear[a, b]}, {a, b}];
FTAssert["A3 root-square lookup is order independent",
  matched["Name"] === "Kallen3Bilinear115" &&
    matchedReversed["Name"] === "Kallen3Bilinear115"];
FTAssert["A4 root-square lookup is independent of source symbol names",
  matchedRenamed["Name"] === "Kallen3Bilinear115"];

(* Verify the explicit birational inverse on the exact declared branches.
   This is the inverse used to return a solved chart gauge to the source
   multiquadratic frame. *)
data = FeynFacet`Private`masterTransportChartData[chart, {v, w}];
sourceRoots = {
  <|"Root" -> Sqrt[lambda3[v, w]], "RootSquare" -> lambda3[v, w]|>,
  <|"Root" -> Sqrt[bilinear[v, w]], "RootSquare" -> bilinear[v, w]|>};
pulledRootSquares = Map[
  <|"RootSquare" -> Together[#1["RootSquare"] /. data["Subst"]]|> &,
  sourceRoots];
rootImages = Lookup[chart["Roots"], "Root"];
inverseA = Together[(1 + v + w + sourceRoots[[1, "Root"]])/2];
inverseP = Together[(1 + v + w - sourceRoots[[1, "Root"]])/2];
inverseU = Together[(sourceRoots[[2, "Root"]] - 1)/inverseA];
roundTrip = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    {inverseP, inverseU} /. data["Subst"], pulledRootSquares,
    rootImages] - chart["Variables"]];
FTAssert["A5 explicit inverse composes exactly on the declared branches",
  roundTrip === {0, 0}];

k2chart = Lookup[catalog, "Kallen2Bilinear115", Missing["NotInCatalog"]];
FTAssert["A6 the simultaneous source-sign image is catalogued generically",
  AssociationQ[k2chart] && k2chart["Name"] === "Kallen2Bilinear115"];
k2certificate = FeynFacet`TransportChartVerify[k2chart];
FTAssert["A7 the lambda2 image certifies both roots and its Kallen2 parent",
  TrueQ[k2certificate["OK"]] &&
    k2certificate["RootIdentities"] === {True, True} &&
    TrueQ[k2certificate["ParentMaps", "Kallen2"]]];
k2matched = FeynFacet`TransportRootSetChart[
  {lambda2[v, w], bilinear[v, w]}, {v, w}];
k2matchedReversed = FeynFacet`TransportRootSetChart[
  {bilinear[v, w], lambda2[v, w]}, {v, w}];
FTAssert["A8 lambda2-bilinear lookup is order independent",
  k2matched["Name"] === "Kallen2Bilinear115" &&
    k2matchedReversed["Name"] === "Kallen2Bilinear115"];

k2data = FeynFacet`Private`masterTransportChartData[k2chart, {v, w}];
k2sourceRoots = {
  <|"Root" -> Sqrt[lambda2[v, w]], "RootSquare" -> lambda2[v, w]|>,
  <|"Root" -> Sqrt[bilinear[v, w]], "RootSquare" -> bilinear[v, w]|>};
k2pulledRootSquares = Map[
  <|"RootSquare" -> Together[#1["RootSquare"] /. k2data["Subst"]]|> &,
  k2sourceRoots];
k2rootImages = Lookup[k2chart["Roots"], "Root"];
k2inverseA = Together[(1 - v - w + k2sourceRoots[[1, "Root"]])/2];
k2inverseP = Together[(1 - v - w - k2sourceRoots[[1, "Root"]])/2];
k2inverseU = Together[(k2sourceRoots[[2, "Root"]] - 1)/k2inverseA];
k2roundTrip = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    {k2inverseP, k2inverseU} /. k2data["Subst"], k2pulledRootSquares,
    k2rootImages] - k2chart["Variables"]];
FTAssert["A9 lambda2 explicit inverse composes on the declared branches",
  k2roundTrip === {0, 0}];

FTAssert["A10 every catalog chart still verifies exactly",
  AllTrue[Values[catalog],
    TrueQ[FeynFacet`TransportChartVerify[#1]["OK"]] &]];

FTReport[];
