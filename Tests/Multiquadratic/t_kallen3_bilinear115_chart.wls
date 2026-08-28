#!/usr/bin/env wolframscript
(* Exact catalog and inverse-composition coverage for the joint chart of
   lambda3 and 1-4 v w.  The chart is mathematical catalog data: no family
   name or family root index participates in lookup. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[v, w, p, u, a, b];
lambda3[x_, y_] := (1 - x + y)^2 + 4 x y;
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

FTAssert["A6 every catalog chart still verifies exactly",
  AllTrue[Values[catalog],
    TrueQ[FeynFacet`TransportChartVerify[#1]["OK"]] &]];

FTReport[];
