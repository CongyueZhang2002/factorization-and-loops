#!/usr/bin/env wolframscript
(* A failed rational ansatz first retries the same small denominator with the
   package-derived dlog basis, then reuses those records in the conservative
   fallback only if the richer rational ansatz also fails. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

ffOptions = Options[FeynFacet`SolveEpsFormStripFiniteField];
candidateOptions =
  Options[FeynFacet`Private`multiquadraticStripCandidateLetters];

Clear[rx, ry, re];
variables = {rx, ry};
strip = {
  {{{0}}, {{0}}},
  {{{0}}, {{0}}},
  {{{1}}, {{0}}}
};
frame = <|"Variables" -> variables,
  "Subst" -> Thread[variables -> variables], "Roots" -> {}|>;
letterRecords = {<|"Kind" -> "ForcingDLog", "Letter" -> rx,
  "OneForm" -> {1/rx, 0}, "Potential" -> <|"Verified" -> True|>|>};
letterData = <|"Status" -> "MultiquadraticCandidateLettersV1",
  "LetterRecords" -> letterRecords, "PotentialsCertified" -> True|>;
solved = <|"Status" -> "Solved", "Method" -> "StubFiniteField",
  "ExactDLog" -> True, "Gauge" -> {{0}}, "Alphabet" -> {rx},
  "ResidueMatrices" -> {{{0}}}|>;

ffCalls = 0; candidateCalls = 0; mqCalls = 0;
seenExpandedRecord = Missing["NotCalled"];
seenExpandedOptions = <||>;
success = Internal`InheritedBlock[{
    FeynFacet`SolveEpsFormStripFiniteField,
    FeynFacet`Private`multiquadraticStripCandidateLetters,
    FeynFacet`Private`solveEpsFormStripMultiquadratic},
  Clear[FeynFacet`SolveEpsFormStripFiniteField,
    FeynFacet`Private`multiquadraticStripCandidateLetters,
    FeynFacet`Private`solveEpsFormStripMultiquadratic];
  Options[FeynFacet`SolveEpsFormStripFiniteField] = ffOptions;
  Options[FeynFacet`Private`multiquadraticStripCandidateLetters] =
    candidateOptions;
  FeynFacet`SolveEpsFormStripFiniteField[
      record_Association, opts___Rule] := Module[{},
    ffCalls++;
    If[ffCalls === 1, $Failed,
      seenExpandedRecord = record;
      seenExpandedOptions = Association[{opts}];
      solved]];
  FeynFacet`Private`multiquadraticStripCandidateLetters[___] :=
    (candidateCalls++; letterData);
  FeynFacet`Private`solveEpsFormStripMultiquadratic[___] :=
    (mqCalls++; <|"Status" -> "UnexpectedMQCall"|>);
  FeynFacet`SolveEpsFormStripInFrame[strip, variables, re, frame,
    "FiniteFieldFirst" -> True, "FiniteFieldFallback" -> True,
    "MultiquadraticDispatch" -> True, "Verbose" -> False]
];

ffFallbackCalls = 0; fallbackCandidateCalls = 0; fallbackMQCalls = 0;
seenFallbackOptions = <||>;
fallback = Internal`InheritedBlock[{
    FeynFacet`SolveEpsFormStripFiniteField,
    FeynFacet`Private`multiquadraticStripCandidateLetters,
    FeynFacet`Private`solveEpsFormStripMultiquadratic},
  Clear[FeynFacet`SolveEpsFormStripFiniteField,
    FeynFacet`Private`multiquadraticStripCandidateLetters,
    FeynFacet`Private`solveEpsFormStripMultiquadratic];
  Options[FeynFacet`SolveEpsFormStripFiniteField] = ffOptions;
  Options[FeynFacet`Private`multiquadraticStripCandidateLetters] =
    candidateOptions;
  FeynFacet`SolveEpsFormStripFiniteField[_Association, ___Rule] :=
    (ffFallbackCalls++; $Failed);
  FeynFacet`Private`multiquadraticStripCandidateLetters[___] :=
    (fallbackCandidateCalls++; letterData);
  FeynFacet`Private`solveEpsFormStripMultiquadratic[
      _Association, _Association, opts___Rule] := (
    fallbackMQCalls++;
    seenFallbackOptions = Association[{opts}];
    <|"Status" -> "MQFallbackStub"|>);
  FeynFacet`SolveEpsFormStripInFrame[strip, variables, re, frame,
    "FiniteFieldFirst" -> True, "FiniteFieldFallback" -> True,
    "MultiquadraticDispatch" -> True, "Verbose" -> False]
];

checks = <|
  "ExpandedBasisRetrySolves" -> AssociationQ[success] &&
    success["Status"] === "Solved" &&
    success["AlphabetRecovery"] === "RankZeroCandidateDLogs" &&
    StringStartsQ[success["Method"], "RationalFrame/"] &&
    AssociationQ[success["FrameCertificate"]],
  "ExactlyOneExpandedRetry" -> ffCalls === 2 && candidateCalls === 1 &&
    mqCalls === 0,
  "ExpandedRecordIsMathOnly" -> AssociationQ[seenExpandedRecord] &&
    seenExpandedRecord["DLogRecords"] ===
      {<|"Letter" -> rx, "OneForm" -> {1/rx, 0}|>} &&
    ! KeyExistsQ[seenExpandedRecord, "GaugeDenominatorFactor"],
  "ExpandedArtifactsHaveOwnPrefix" -> StringEndsQ[
    Lookup[seenExpandedOptions, "ArtifactPrefix", ""], "_dlog_basis"],
  "ConservativeFallbackRunsOnlyAfterBothFiniteFailures" ->
    ffFallbackCalls === 2 && fallbackCandidateCalls === 1 &&
      fallbackMQCalls === 1 && fallback["Status"] === "MQFallbackStub",
  "ConservativeFallbackReusesRecords" ->
    Lookup[seenFallbackOptions, "LetterRecords", Missing[]] === letterRecords
|>;

Print[InputForm[checks]];
Print["failed: ", Keys[Select[checks, ! TrueQ[#1] &]]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
