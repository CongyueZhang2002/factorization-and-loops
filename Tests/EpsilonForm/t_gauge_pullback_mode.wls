#!/usr/bin/env wolframscript
(* Gauge pull-back modes of SolveEpsFormStripInFrame (round 4, 2026-09-02).

   Acceptance criteria, stated before the run:
     (a) the default mode is "Exact";
     (b) the live allowed set is exactly {"Exact", "FiniteFieldReconstruct"}:
         "MapleCanonical" (retired with the Maple canonical gauge, overhaul
         goal 1) and an unknown name are BOTH refused typed, before any
         solving, with "Status" -> "InvalidGaugePullBackMode" and the
         allowed set named in the refusal;
     (c) the retired normalizer's stub stays callable and answers
         RouteRetired, so a stored record whose provenance names the
         mode remains readable and the retirement is visible by name;
     (d) the option list no longer carries the Maple cache directory.
   The strip is a trivially small one-root strip built on the same
   Kallen frame as Tests/Multiquadratic/t_multiquadratic_transport_frame;
   nothing is solved: every refusal fires in the option gate. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

v = Symbol["Global`v"];
w = Symbol["Global`w"];
x = Symbol["Global`gpmx"];
y = Symbol["Global`gpmy"];
eps = Symbol["Global`eps"];

coefficientPresentation = BuildSquareRootGeneratorsAndQuadraticRelations[
  {(1 - v - w)^2 - 4 v w}, {v, w}, {x, y}];
FTAssert["the one-generator quadratic relation is verified",
  AssociationQ[coefficientPresentation] &&
    coefficientPresentation["Status"] ===
      "SquareRootGeneratorRelationsVerified"];

strip = {{{{0}}, {{0}}}, {{{0}}, {{0}}},
  {{{eps/(v - 1)}}, {{eps/(w - 1)}}}};

FTAssert["(a) the default gauge pull-back mode is Exact",
  ("GaugePullBackMode" /. Options[FeynFacet`SolveEpsFormStripInFrame]) === "Exact"];

allowed = {"Exact", "FiniteFieldReconstruct"};
refusal[mode_] := SolveEpsFormStripInFrame[
  strip, {v, w}, eps, coefficientPresentation,
  "GaugePullBackMode" -> mode, "Verbose" -> False];

maple = refusal["MapleCanonical"];
FTAssert["(b) MapleCanonical is refused as not allowed, naming the live set",
  AssociationQ[maple] && maple["Status"] === "InvalidGaugePullBackMode" &&
    maple["Allowed"] === allowed && maple["Actual"] === "MapleCanonical"];

unknown = refusal["NotAMode"];
FTAssert["(b) an unknown mode is refused the same way",
  AssociationQ[unknown] && unknown["Status"] === "InvalidGaugePullBackMode" &&
    unknown["Allowed"] === allowed];

stub = FeynFacet`Private`transportChartMapleCanonicalGauge[
  {{1}}, {v, w}, eps, {}, "Tag" -> "probe"];
FTAssert["(c) the retired normalizer stub answers RouteRetired by name",
  AssociationQ[stub] && stub["Status"] === "RouteRetired" &&
    StringContainsQ[Lookup[stub, "Route", ""], "MapleCanonical"]];

FTAssert["(d) the option list carries no Maple cache directory",
  FreeQ[Keys[Options[FeynFacet`SolveEpsFormStripInFrame]],
    "MapleCanonicalCacheDirectory"]];

FTReport[];
