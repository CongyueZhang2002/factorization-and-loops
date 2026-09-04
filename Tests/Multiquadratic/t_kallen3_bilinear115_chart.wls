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

catalog = FeynFacet`RationalizingParametrizationCatalog[];
chart = Lookup[catalog, "Kallen3Bilinear115", Missing["NotInCatalog"]];
FTAssert["A1 joint chart is present under a family-independent name",
  AssociationQ[chart] && chart["Name"] === "Kallen3Bilinear115"];

certificate = FeynFacet`VerifyRationalizingParametrization[chart];
FTAssert["A2 exact chart certificate passes both roots and the parent map",
  TrueQ[certificate["Verified"]] &&
    certificate["RationalizedSquareRootIdentities"] === {True, True} &&
    TrueQ[certificate["ParentParametrizationIdentities", "Kallen3"]]];

matched = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
  {lambda3[v, w], bilinear[v, w]}, {v, w}];
matchedReversed = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
  {bilinear[v, w], lambda3[v, w]}, {v, w}];
matchedRenamed = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
  {lambda3[a, b], bilinear[a, b]}, {a, b}];
FTAssert["A3 root-square lookup is order independent",
  matched["Name"] === "Kallen3Bilinear115" &&
    matchedReversed["Name"] === "Kallen3Bilinear115"];
FTAssert["A4 root-square lookup is independent of source symbol names",
  matchedRenamed["Name"] === "Kallen3Bilinear115"];

(* Verify the explicit birational inverse on the exact declared branches.
   This is the inverse used to return a solved chart gauge to the source
   multiquadratic frame. *)
data = FeynFacet`Private`masterTransportCoefficientPresentationData[
  chart, {v, w}];
sourceRoots = {
  <|"Generator" -> Sqrt[lambda3[v, w]],
    "QuadraticRadicand" -> lambda3[v, w],
    "SourceRadicand" -> lambda3[v, w]|>,
  <|"Generator" -> Sqrt[bilinear[v, w]],
    "QuadraticRadicand" -> bilinear[v, w],
    "SourceRadicand" -> bilinear[v, w]|>};
pulledRootSquares = Map[
  <|"QuadraticRadicand" -> Together[
      #1["QuadraticRadicand"] /.
        data["SourceVariableSubstitution"]]|> &,
  sourceRoots];
rootImages = Lookup[chart["RationalizedSquareRoots"], "RationalRoot"];
inverseA = Together[(1 + v + w + sourceRoots[[1, "Generator"]])/2];
inverseP = Together[(1 + v + w - sourceRoots[[1, "Generator"]])/2];
inverseU = Together[(sourceRoots[[2, "Generator"]] - 1)/inverseA];
roundTrip = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    {inverseP, inverseU} /. data["SourceVariableSubstitution"],
    pulledRootSquares, rootImages] - chart["ParametrizingVariables"]];
FTAssert["A5 explicit inverse composes exactly on the declared branches",
  roundTrip === {0, 0}];

k2chart = Lookup[catalog, "Kallen2Bilinear115", Missing["NotInCatalog"]];
FTAssert["A6 the simultaneous source-sign image is catalogued generically",
  AssociationQ[k2chart] && k2chart["Name"] === "Kallen2Bilinear115"];
k2certificate = FeynFacet`VerifyRationalizingParametrization[k2chart];
FTAssert["A7 the lambda2 image certifies both roots and its Kallen2 parent",
  TrueQ[k2certificate["Verified"]] &&
    k2certificate["RationalizedSquareRootIdentities"] === {True, True} &&
    TrueQ[k2certificate[
      "ParentParametrizationIdentities", "Kallen2"]]];
k2matched = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
  {lambda2[v, w], bilinear[v, w]}, {v, w}];
k2matchedReversed = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
  {bilinear[v, w], lambda2[v, w]}, {v, w}];
FTAssert["A8 lambda2-bilinear lookup is order independent",
  k2matched["Name"] === "Kallen2Bilinear115" &&
    k2matchedReversed["Name"] === "Kallen2Bilinear115"];

k2data = FeynFacet`Private`masterTransportCoefficientPresentationData[
  k2chart, {v, w}];
k2sourceRoots = {
  <|"Generator" -> Sqrt[lambda2[v, w]],
    "QuadraticRadicand" -> lambda2[v, w],
    "SourceRadicand" -> lambda2[v, w]|>,
  <|"Generator" -> Sqrt[bilinear[v, w]],
    "QuadraticRadicand" -> bilinear[v, w],
    "SourceRadicand" -> bilinear[v, w]|>};
k2pulledRootSquares = Map[
  <|"QuadraticRadicand" -> Together[
      #1["QuadraticRadicand"] /.
        k2data["SourceVariableSubstitution"]]|> &,
  k2sourceRoots];
k2rootImages = Lookup[k2chart["RationalizedSquareRoots"], "RationalRoot"];
k2inverseA = Together[(1 - v - w + k2sourceRoots[[1, "Generator"]])/2];
k2inverseP = Together[(1 - v - w - k2sourceRoots[[1, "Generator"]])/2];
k2inverseU = Together[(k2sourceRoots[[2, "Generator"]] - 1)/k2inverseA];
k2roundTrip = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    {k2inverseP, k2inverseU} /.
      k2data["SourceVariableSubstitution"], k2pulledRootSquares,
    k2rootImages] - k2chart["ParametrizingVariables"]];
FTAssert["A9 lambda2 explicit inverse composes on the declared branches",
  k2roundTrip === {0, 0}];

FTAssert["A10 every catalog chart still verifies exactly",
  AllTrue[Values[catalog],
    TrueQ[FeynFacet`VerifyRationalizingParametrization[#1]["Verified"]] &]];

FTReport[];
