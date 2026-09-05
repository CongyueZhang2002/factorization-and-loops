#!/usr/bin/env wolframscript
(* Adversarial checks for the isolated finite-field row-gauge oracle. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{root, "Prototypes", "FamilyRowBasisTransformationFiniteField.wl"}]];
End[];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, eps, z];
n = 5; rows = {4, 5}; columns = Range[3];
r1 = Sqrt[x]; r2 = Sqrt[y]; r3 = Sqrt[x + y];
rootsNatural = {
  <|"Root" -> r1, "RootSquare" -> x|>,
  <|"Root" -> r2, "RootSquare" -> y|>,
  <|"Root" -> r3, "RootSquare" -> x + y|>};
rootsReversed = Reverse[rootsNatural];
grades = {1, r1, r2, r1 r2, r3, r1 r3, r2 r3, r1 r2 r3};

connection = Table[
  Table[If[i < j, 0,
    grades[[1 + Mod[5 mu + 3 i + j, Length[grades]]]]
      (eps + mu + i x + j y)/(1 + x + y + i + j)],
    {i, n}, {j, n}],
  {mu, 2}];
gauge = {
  {r1/(1 + y), r2 r3/(2 + x), x/(3 + y)},
  {0, (r1 + r2)/(2 + x + y), r1 r2 r3/(4 + x)}};
identity = IdentityMatrix[n];

prep = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, gauge, {x, y}, rootsReversed];
prepNatural = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, gauge, {x, y}, rootsNatural];

FTTest`FTAssert["rank-three preparation accepted",
  AssociationQ[prep] && prep["Status"] === "Prepared" &&
    prep["RootCount"] === 3 && prep["BranchCount"] === 8];
FTTest`FTAssert["root declaration order has a canonical ABI",
  prepNatural["Status"] === "Prepared" &&
    prepNatural["CanonicalRoots"] === prep["CanonicalRoots"] &&
    prepNatural["FieldFingerprint"] === prep["FieldFingerprint"] &&
    prepNatural["Fingerprint"] === prep["Fingerprint"]];
FTTest`FTAssert["field and preparation fingerprints are SHA-256 strings",
  StringQ[prep["FieldFingerprint"]] &&
    StringLength[prep["FieldFingerprint"]] === 64 &&
    StringQ[prep["Fingerprint"]] &&
    StringLength[prep["Fingerprint"]] === 64];
FTTest`FTAssert["dD is precomputed and represented in touched records",
  prep["DerivativeMode"] === "PrecomputedExact" &&
    prep["Statistics", "DerivativeTerms"] > 0];
FTTest`FTAssert["the regulator is an explicit sample parameter",
  prep["Parameters"] === {eps}];
FTTest`FTAssert["literal sparse support skips dense products",
  prep["Statistics", "Connection", "Products"] <
      2 Length[Range[First[rows], n]] Length[columns]
        (Length[rows] + Length[columns]) &&
    prep["Statistics", "Transformation", "Touched"] <
      prep["Statistics", "Transformation", "CandidateEntries"] &&
    prep["Statistics", "Inverse", "Touched"] <
      prep["Statistics", "Inverse", "CandidateEntries"]];

prime = 101; point = {1, 4}; parameterRules = {eps -> 7};
directModSum = FeynFacet`Private`familyRowBasisTransformationFFModEvaluate[
  x + y, Association[x -> 1, y -> 4], {}, prime];
FTTest`FTAssert["recursive modular evaluator handles rational sums",
  directModSum["Status"] === "OK" && directModSum["Value"] === 5];
sample = FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
  prep, point, prime, parameterRules];
If[Lookup[sample, "Status", None] =!= "OK",
  Print["rank-three sample diagnostic: ", sample]];
sampleOK = AssociationQ[sample] && sample["Status"] === "OK";
FTTest`FTAssert["rank-three split sample accepted",
  sampleOK &&
    sample["Statistics", "Branches"] === 8 &&
    sample["HadamardRoundTrip"] === True];
FTTest`FTAssert["Tonelli--Shanks roots match all root squares",
  sampleOK && Mod[sample["CanonicalRootValues"]^2 -
      sample["RootSquareValues"], prime] === ConstantArray[0, 3]];
FTTest`FTAssert["all eight sign branches were materially exercised",
  sampleOK && sample["BranchMasks"] === Range[0, 7] &&
    AnyTrue[Flatten[Values[sample["Records"]]],
      Length[DeleteDuplicates[#1["Conjugates"]]] > 1 &]];
FTTest`FTAssert["term evaluation accounting covers every branch",
  sampleOK && sample["Statistics", "TermEvaluations"] ===
    sample["Statistics", "Branches"] sample["Statistics", "TermCount"] &&
    sample["Statistics", "TouchedEntries"] ===
      sample["Statistics", "HadamardTransforms"]];

(* Independent exact oracle: compare each sparse record with the full
   matrix gauge formula for every one of the eight sign conjugates. *)
dFull = ConstantArray[0, {n, n}];
dFull[[rows, columns]] = gauge;
t = identity + dFull; tInverse = identity - dFull;
expectedConnection = Table[
  tInverse . connection[[mu]] . t -
    tInverse . D[t, {x, y}[[mu]]], {mu, 2}];
expectedTransformation = t;
expectedInverse = tInverse;
expectedExpression[kind_, target_] := Switch[kind,
  "Connection", Extract[expectedConnection, target],
  "Transformation", Extract[expectedTransformation, target],
  "Inverse", Extract[expectedInverse, target]];

(* familyRowBasisTransformationFFReplaceRoots delegates to the package's
   transportChartApplyRootBranches since 2026-08-23, so it keys on the
   canonical ROOT RECORDS ("Root"/"RootSquare"), not on bare squares. *)
canonicalRoots = prep["CanonicalRoots"];
directBranchOracleQ[modularSample_Association, samplePoint_List,
    samplePrime_Integer, epsilonValue_Integer] := If[
  Lookup[modularSample, "Status", None] =!= "OK", False,
  Module[{sampleScalars = Association[x -> samplePoint[[1]],
      y -> samplePoint[[2]], eps -> epsilonValue]},
    And @@ Flatten[Table[
      Map[Function[entry,
        Module[{expression, template, signedRoots, value},
          expression = expectedExpression[kind, entry["Target"]];
          template = FeynFacet`Private`familyRowBasisTransformationFFReplaceRoots[
            expression, canonicalRoots];
          And @@ Table[
            signedRoots = MapIndexed[
              If[BitGet[branch, First[#2] - 1] === 1,
                Mod[-#1, samplePrime], #1] &,
              modularSample["CanonicalRootValues"]];
            value = FeynFacet`Private`familyRowBasisTransformationFFModEvaluate[
              template, sampleScalars, signedRoots, samplePrime];
            value["Status"] === "OK" &&
              value["Value"] ===
                entry["Conjugates"][[branch + 1]],
            {branch, 0,
              modularSample["Statistics", "Branches"] - 1}]]],
        Lookup[modularSample["Records"], kind, {}]],
      {kind, {"Connection", "Transformation", "Inverse"}}]]]];
FTTest`FTAssert["every touched entry and sign equals the full exact formula",
  directBranchOracleQ[sample, point, prime, 7]];
FTTest`FTAssert["every Hadamard channel recomposes to direct conjugates",
  sampleOK && AllTrue[Flatten[Values[sample["Records"]]],
    #1["Conjugates"] === #1["RecomposedConjugates"] &]];
FTTest`FTAssert["the grade-seven root channel survives projection",
  sampleOK && AnyTrue[Flatten[Values[sample["Records"]]],
    Last[#1["Channels"]] =!= 0 &]];

unseenPrime = 103; unseenPoint = {1, 8}; unseenEpsilon = 11;
unseenSample = FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
  prep, unseenPoint, unseenPrime, {eps -> unseenEpsilon}];
FTTest`FTAssert["a distinct unseen prime and split point are accepted",
  unseenSample["Status"] === "OK" &&
    unseenSample["FieldFingerprint"] === sample["FieldFingerprint"] &&
    unseenSample["PreparationFingerprint"] ===
      sample["PreparationFingerprint"] &&
    unseenSample["SampleFingerprint"] =!= sample["SampleFingerprint"]];
FTTest`FTAssert["unseen-prime signs equal the full exact formula",
  directBranchOracleQ[unseenSample, unseenPoint, unseenPrime,
    unseenEpsilon]];

(* The same evaluator must cover rational, one-root and two-root input;
   unused radicals are replaced by rational functions before preparing. *)
rankCases = Table[Module[{rules, rankConnection, rankOffDiagonalBasisTransformationBlock, rankPrep,
      rankSample},
    rules = Drop[{r1 -> x, r2 -> y, r3 -> x + y}, rank];
    rankConnection = connection /. rules;
    rankOffDiagonalBasisTransformationBlock = gauge /. rules;
    rankPrep = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
      rankConnection, identity, identity, rows, rankOffDiagonalBasisTransformationBlock, {x, y},
      Take[rootsNatural, rank]];
    rankSample = If[rankPrep["Status"] === "Prepared",
      FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
        rankPrep, point, prime, parameterRules], <||>];
    If[Lookup[rankSample, "Status", None] =!= "OK",
      Print["rank-", rank, " sample diagnostic: ", rankSample]];
    rankPrep["Status"] === "Prepared" &&
      rankPrep["BranchCount"] === 2^rank &&
      Lookup[rankSample, "Status", None] === "OK" &&
      rankSample["Statistics", "Branches"] === 2^rank],
  {rank, 0, 2}];
FTTest`FTAssert["the modular path covers ranks zero through three",
  And @@ rankCases];

unknownOffDiagonalBasisTransformationBlock = gauge;
unknownOffDiagonalBasisTransformationBlock[[1, 1]] = Sqrt[1 + x y]/(1 + y);
unknown = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, unknownOffDiagonalBasisTransformationBlock, {x, y},
  rootsNatural];
FTTest`FTAssert["undeclared radicals are rejected before sampling",
  unknown["Status"] === "UnknownRadicals"];

nonQuadraticBasisTransformationBlock = gauge;
nonQuadraticBasisTransformationBlock[[1, 1]] = (1 + x)^(1/3);
cubic = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, nonQuadraticBasisTransformationBlock, {x, y},
  rootsNatural];
FTTest`FTAssert["non-multiquadratic powers are typed",
  cubic["Status"] === "UnsupportedAlgebraicPower"];

duplicateRoots = {rootsNatural[[1]], rootsNatural[[2]],
  rootsNatural[[1]]};
duplicate = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, gauge, {x, y}, duplicateRoots];
FTTest`FTAssert["duplicate declared root squares are rejected",
  duplicate["Status"] === "DuplicateRootSquare"];

dependentRoots = {
  <|"Root" -> Sqrt[x], "RootSquare" -> x|>,
  <|"Root" -> Sqrt[y], "RootSquare" -> y|>,
  <|"Root" -> Sqrt[x y], "RootSquare" -> x y|>};
dependent = FeynFacet`Private`familyRowBasisTransformationFFCanonicalizeRoots[
  dependentRoots, {x, y}];
FTTest`FTAssert["square-class dependent radicands are rejected",
  dependent["Status"] === "DependentRootSquares" &&
    dependent["RootIndices"] === {1, 2, 3}];
trivialRoot = FeynFacet`Private`familyRowBasisTransformationFFCanonicalizeRoots[{
  <|"Root" -> Sqrt[x^2], "RootSquare" -> x^2|>}, {x, y}];
FTTest`FTAssert["trivial rational-function square extensions are rejected",
  trivialRoot["Status"] === "DependentRootSquares" &&
    trivialRoot["RootIndices"] === {1}];
nonkinematicRoot = FeynFacet`Private`familyRowBasisTransformationFFCanonicalizeRoots[{
  <|"Root" -> Sqrt[x + eps], "RootSquare" -> x + eps|>}, {x, y}];
FTTest`FTAssert["root squares cannot depend on the regulator",
  nonkinematicRoot["Status"] === "NonKinematicRootSquare" &&
    MemberQ[nonkinematicRoot["Symbols"], eps]];

badConnection = connection;
badConnection[[1, 1, First[rows]]] = 1;
badStructure = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  badConnection, identity, identity, rows, gauge, {x, y}, rootsNatural];
FTTest`FTAssert["D.A.D structural violations are rejected",
  badStructure["Status"] === "InvalidBlockStructure"];
badDimensions = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, {{1, 2}}, {x, y}, rootsNatural];
FTTest`FTAssert["malformed gauge dimensions are typed",
  badDimensions["Status"] === "InvalidOffDiagonalBasisTransformationBlockDimensions"];

badPrimeBasisTransformationBlock = gauge;
badPrimeBasisTransformationBlock[[1, 1]] = gauge[[1, 1]]/5;
badPrimePrep = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, badPrimeBasisTransformationBlock, {x, y},
  rootsNatural];
badPrime = FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
  badPrimePrep, point, 5, parameterRules];
FTTest`FTAssert["primes dividing exact coefficients are rejected",
  badPrime["Status"] === "BadPrime"];
FTTest`FTAssert["composite and over-width moduli are rejected",
  FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
      prep, point, 9, parameterRules]["Status"] === "InvalidPrime" &&
    FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
      prep, point, 2^31 + 11, parameterRules]["Status"] ===
        "InvalidPrime"];
FTTest`FTAssert["parameter denominators participate in bad-prime checks",
  FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
    prep, point, prime, {eps -> 1/101}]["Status"] === "BadPrime"];

FTTest`FTAssert["missing, duplicate and unknown parameters are typed",
  FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
      prep, point, prime, {}]["Status"] === "MissingParameters" &&
    FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
      prep, point, prime, {eps -> 1, eps -> 2}]["Status"] ===
        "DuplicateParameterRules" &&
    FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
      prep, point, prime, {eps -> 1, z -> 2}]["Status"] ===
        "UnknownParameters"];
FTTest`FTAssert["malformed points are rejected",
  FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
    prep, {1}, prime, parameterRules]["Status"] === "InvalidPoint"];
FTTest`FTAssert["ramified and nonsplit points are distinguished",
  FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
      prep, {0, 4}, prime, parameterRules]["Status"] ===
        "RamifiedPoint" &&
    FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
      prep, {2, 4}, prime, parameterRules]["Status"] ===
        "NonSplitPoint"];

singularBasisTransformationBlock = gauge;
singularBasisTransformationBlock[[1, 1]] = r1/(x - 1);
singularPrep = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, singularBasisTransformationBlock, {x, y},
  rootsNatural];
singular = FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
  singularPrep, point, prime, parameterRules];
FTTest`FTAssert["entry poles at otherwise split points are typed",
  singular["Status"] === "SingularPoint"];

tamperedTerm = Join[
  prep["Records", "Connection"][[1, "Terms", 1]],
  <|"Expression" ->
    (prep["Records", "Connection"][[1, "Terms", 1, "Expression"]]
      + 1)|>];
tamperedRecord = Join[prep["Records", "Connection"][[1]],
  <|"Terms" -> ReplacePart[
    prep["Records", "Connection"][[1, "Terms"]], 1 -> tamperedTerm]|>];
tamperedRecords = Join[prep["Records"],
  <|"Connection" -> ReplacePart[
    prep["Records", "Connection"], 1 -> tamperedRecord]|>];
tampered = Join[prep, <|"Records" -> tamperedRecords|>];
FTTest`FTAssert["record mutation is caught by the strong fingerprint",
  FeynFacet`Private`familyRowBasisTransformationFiniteFieldEvaluate[
    tampered, point, prime, parameterRules]["Status"] ===
      "PreparationFingerprintMismatch"];

changedBasisTransformationBlock = gauge;
changedBasisTransformationBlock[[1, 3]] = changedBasisTransformationBlock[[1, 3]] + 1;
changedPrep = FeynFacet`Private`familyRowBasisTransformationFiniteFieldPrepare[
  connection, identity, identity, rows, changedBasisTransformationBlock, {x, y},
  rootsNatural];
FTTest`FTAssert["field fingerprint is stable but work fingerprint is strong",
  changedPrep["Status"] === "Prepared" &&
    changedPrep["FieldFingerprint"] === prep["FieldFingerprint"] &&
    changedPrep["Fingerprint"] =!= prep["Fingerprint"]];
FTTest`FTAssert["Tonelli--Shanks covers both odd-prime congruence classes",
  Mod[FeynFacet`Private`familyRowBasisTransformationFFSquareRoot[5, 101]^2, 101]
      === 5 &&
    Mod[FeynFacet`Private`familyRowBasisTransformationFFSquareRoot[4, 103]^2, 103]
      === 4];

FTTest`FTReport[];
