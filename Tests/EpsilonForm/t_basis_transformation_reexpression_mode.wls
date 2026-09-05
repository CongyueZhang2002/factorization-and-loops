#!/usr/bin/env wolframscript
(* Basis-transformation reexpression modes of
   SolveOffDiagonalBasisTransformationBlock (round 4, 2026-09-02).

   Acceptance criteria, stated before the run:
     (a) the default mode is "Exact";
     (b) the live allowed set is exactly {"Exact", "FiniteFieldReconstruct"}:
         "MapleCanonical" and an unknown name are BOTH refused typed, before any
         solving, with "Status" -> "InvalidBasisTransformationReexpressionMode" and the
         allowed set named in the refusal;
     (c) the option list carries no retired Maple cache directory.
   The equation is a trivially small one-generator off-diagonal block
   built from the same Kallen presentation as
   Tests/Multiquadratic/t_multiquadratic_transport_frame;
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

offDiagonalBlockEquation = {{{{0}}, {{0}}}, {{{0}}, {{0}}},
  {{{eps/(v - 1)}}, {{eps/(w - 1)}}}};

FTAssert["(a) the default basis-transformation reexpression mode is Exact",
  ("BasisTransformationReexpressionMode" /. Options[FeynFacet`SolveOffDiagonalBasisTransformationBlock]) === "Exact"];

allowed = {"Exact", "FiniteFieldReconstruct"};
refusal[mode_] := SolveOffDiagonalBasisTransformationBlock[
  offDiagonalBlockEquation, {v, w}, eps, coefficientPresentation,
  "BasisTransformationReexpressionMode" -> mode, "Verbose" -> False];

maple = refusal["MapleCanonical"];
FTAssert["(b) MapleCanonical is refused as not allowed, naming the live set",
  AssociationQ[maple] && maple["Status"] === "InvalidBasisTransformationReexpressionMode" &&
    maple["Allowed"] === allowed && maple["Actual"] === "MapleCanonical"];

unknown = refusal["NotAMode"];
FTAssert["(b) an unknown mode is refused the same way",
  AssociationQ[unknown] && unknown["Status"] === "InvalidBasisTransformationReexpressionMode" &&
    unknown["Allowed"] === allowed];

FTAssert["(c) the option list carries no retired Maple cache directory",
  FreeQ[Keys[Options[FeynFacet`SolveOffDiagonalBasisTransformationBlock]],
    "MapleCanonicalCacheDirectory"]];

FTReport[];
