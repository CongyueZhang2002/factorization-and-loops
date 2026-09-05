#!/usr/bin/env wolframscript
(* A failed rational ansatz first retries the same small denominator with the
   package-derived dlog basis, then reuses those records in the conservative
   fallback only if the richer rational ansatz also fails. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

ffOptions = Options[FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField];
candidateOptions =
  Options[FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters];

Clear[rx, ry, re];
variables = {rx, ry};
strip = {
  {{{0}}, {{0}}},
  {{{0}}, {{0}}},
  {{{1}}, {{0}}}
};
coefficientPresentation = <|
  "DataType" -> "SourceVariableRepresentation",
  "SchemaVersion" -> 2,
  "SourceVariables" -> variables,
  "CoefficientVariables" -> variables,
  "SourceVariableSubstitution" -> Thread[variables -> variables],
  "DifferentialPullbackMatrix" -> IdentityMatrix[2]|>;
letterRecords = {<|"Kind" -> "InhomogeneityDLog", "Letter" -> rx,
  "OneForm" -> {1/rx, 0}, "Potential" -> <|"Verified" -> True|>|>};
letterData = <|"Status" -> "MultiquadraticCandidateLettersV1",
  "LetterRecords" -> letterRecords, "PotentialsCertified" -> True|>;
solved = <|"Status" -> "Solved", "Method" -> "StubFiniteField",
  "ExactDLog" -> True, "OffDiagonalBasisTransformationBlock" -> {{0}}, "Alphabet" -> {rx},
  "ResidueMatrices" -> {{{0}}}|>;

ffCalls = 0; candidateCalls = 0; mqCalls = 0;
seenExpandedRecord = Missing["NotCalled"];
seenExpandedOptions = <||>;
success = Internal`InheritedBlock[{
    FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField,
    FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters,
    FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators},
  Clear[FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField,
    FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters,
    FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators];
  Options[FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField] = ffOptions;
  Options[FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters] =
    candidateOptions;
  FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[
      record_Association, opts___Rule] := Module[{},
    ffCalls++;
    If[ffCalls === 1, $Failed,
      seenExpandedRecord = record;
      seenExpandedOptions = Association[{opts}];
      solved]];
  FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters[___] :=
    (candidateCalls++; letterData);
  FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators[___] :=
    (mqCalls++; <|"Status" -> "UnexpectedMQCall"|>);
  FeynFacet`SolveOffDiagonalBasisTransformationBlock[
    strip, variables, re, coefficientPresentation,
    "MultiquadraticDispatch" -> True, "Verbose" -> False]
];

ffFallbackCalls = 0; fallbackCandidateCalls = 0; fallbackMQCalls = 0;
seenFallbackOptions = <||>;
fallback = Internal`InheritedBlock[{
    FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField,
    FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters,
    FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators},
  Clear[FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField,
    FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters,
    FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators];
  Options[FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField] = ffOptions;
  Options[FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters] =
    candidateOptions;
  FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[_Association, ___Rule] :=
    (ffFallbackCalls++; $Failed);
  FeynFacet`Private`multiquadraticOffDiagonalBlockCandidateLetters[___] :=
    (fallbackCandidateCalls++; letterData);
  FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators[
      _Association, _Association, opts___Rule] := (
    fallbackMQCalls++;
    seenFallbackOptions = Association[{opts}];
    <|"Status" -> "MQFallbackStub"|>);
  FeynFacet`SolveOffDiagonalBasisTransformationBlock[
    strip, variables, re, coefficientPresentation,
    "MultiquadraticDispatch" -> True, "Verbose" -> False]
];

checks = <|
  "ExpandedBasisRetrySolves" -> AssociationQ[success] &&
    success["Status"] === "Solved" &&
    success["AlphabetRecovery"] === "RankZeroCandidateDLogs" &&
    StringStartsQ[success["Method"], "SourceVariableRepresentation/"] &&
    success["CoefficientPresentation", "DataType"] ===
      "SourceVariableRepresentation" &&
    AssociationQ[success["Validation"]] &&
    TrueQ[success["Validation", "Passed"]],
  "ExactlyOneExpandedRetry" -> ffCalls === 2 && candidateCalls === 1 &&
    mqCalls === 0,
  "ExpandedRecordIsMathOnly" -> AssociationQ[seenExpandedRecord] &&
    seenExpandedRecord["DLogRecords"] ===
      {<|"Letter" -> rx, "OneForm" -> {1/rx, 0}|>} &&
    ! KeyExistsQ[seenExpandedRecord, "OffDiagonalBasisTransformationDenominatorFactor"],
  "ExpandedArtifactsHaveOwnPrefix" -> StringEndsQ[
    Lookup[seenExpandedOptions, "ArtifactPrefix", ""], "_dlog_basis"],
  "ConservativeFallbackRunsOnlyAfterBothFiniteFailures" ->
    ffFallbackCalls === 2 && fallbackCandidateCalls === 1 &&
      fallbackMQCalls === 1 && fallback["Status"] === "MQFallbackStub" &&
      fallback["FallbackCoefficientPresentation"] ===
        "SourceVariableRepresentationAfterRationalization",
  "ConservativeFallbackReusesRecords" ->
    Lookup[seenFallbackOptions, "LetterRecords", Missing[]] === letterRecords
|>;

Print[InputForm[checks]];
Print["failed: ", Keys[Select[checks, ! TrueQ[#1] &]]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
