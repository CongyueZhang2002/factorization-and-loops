#!/usr/bin/env wolframscript
(* Dynamic graded generators and independent square-class validation for
   the family regulator factorization route.  This suite is deliberately
   algebra-only: it launches no helpers and runs no sampled factorization. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];

Clear[x, y, eps];
rootRecord[q_] := <|"Root" -> Sqrt[q], "RootSquare" -> q|>;
frame = FeynFacet`Private`familyRegulatorGradedRootFrame;
gradedRoots = FeynFacet`Private`familyRegulatorGradedRoots;
decompose = FeynFacet`Private`familyRegulatorGradedDecompose;
frameEvidence = FeynFacet`Private`familyRegulatorGradedFrameEvidence;

base = rootRecord /@ {x, 2 x};
baseFrame = frame[base];
check["two square classes whose quotient is nonsquare are independent",
  Lookup[baseFrame, "Status", None] === "StableRootFrame"];

dependent = gradedRoots[base, {2}];
check["a numeric class that closes a square relation is refused",
  AssociationQ[dependent] &&
    Lookup[dependent, "Status", None] === "DependentRootSquares" &&
    Sort[Lookup[dependent, "RootIndices", {}]] === {1, 2, 3}];

duplicate = gradedRoots[{rootRecord[2]}, {2}];
check["a numeric class cannot duplicate a declared generator",
  AssociationQ[duplicate] &&
    Lookup[duplicate, "Status", None] === "DuplicateRootSquares"];

directRefusal = FeynFacet`FactorFamilyRegulatorDependenceMultiquadratic[
  {{{0}} , {{0}}}, {x, y}, eps,
  Join[base, {rootRecord[2]}]];
check["the public graded factorizer validates a directly supplied frame",
  AssociationQ[directRefusal] &&
    Lookup[directRefusal, "Status", None] === "DependentRootSquares" &&
    ! KeyExistsQ[directRefusal, "Transformation"]];

(* Rank five is the current family-factor ceiling.  Exercising it keeps
   the ceiling a resource policy while proving generator construction is
   not tied to five named Module locals. *)
roots5 = rootRecord /@ {2, 3, 5, 7, 11};
expression5 = 1 + Sqrt[2] + 2 Sqrt[3] + 3 Sqrt[5] +
  5 Sqrt[7] + 7 Sqrt[11];
channels5 = decompose[expression5, roots5];
check["rank-five decomposition uses the full dynamic 32-grade ABI",
  ListQ[channels5] && Length[channels5] === 32 &&
    TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[
      FeynFacet`Private`multiquadraticFieldCompose[channels5, roots5] -
        expression5, roots5] === True]];

evidence5 = frameEvidence[roots5, {x, y}, eps];
check["rank-five graded frame evidence binds the producer ceiling and grade ABI",
  evidence5["Status"] === "StableRootFrame" &&
    evidence5["Schema"] === "FamilyRegulatorGradedRootFrameV1" &&
    evidence5["RootCount"] === 5 && evidence5["GradeCount"] === 32 &&
    evidence5["MaximumRank"] === 5 &&
    Length[evidence5["RootFingerprints"]] === 5 &&
    StringQ[evidence5["OrderingFingerprint"]] &&
    StringQ[evidence5["FrameFingerprint"]]];

genericNumericEvidence = frameEvidence[
  rootRecord /@ {1 + x, 3, 5}, {x, y}, eps];
check["generic independent numeric square classes are explicit graded generators",
  genericNumericEvidence["Status"] === "StableRootFrame" &&
    genericNumericEvidence["RootCount"] === 3 &&
    Sort[genericNumericEvidence["NumericRootSquares"]] === {3, 5} &&
    Length[genericNumericEvidence["NumericRootIndices"]] === 2];
check["whole-family certification resolves its Automatic ceiling from the graded producer",
  ("MultiquadraticRootRankLimit" /.
      Options[FeynFacet`ValidateFamilyDLogEpsilonForm]) === Automatic &&
    evidence5["MaximumRank"] === 5];

source = Import[FeynFacet`Private`feynFacetPrivateFile["FamilyRegulatorFactor.wl"], "Text"];
check["the implementation contains no fixed rootA through rootE locals",
  AllTrue[{"rootA", "rootB", "rootC", "rootD", "rootE"},
    ! StringContainsQ[source, #] &]];

Print["t_family_regulator_root_frame: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
