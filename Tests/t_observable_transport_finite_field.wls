#!/usr/bin/env wolframscript

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private",
  "ObservableTransportFiniteField.wl"}]];

x = Symbol["Global`coordinateVariableWithArbitraryName"];
u = Symbol["Global`firstArbitraryCoordinateVariable"];
v = Symbol["Global`secondArbitraryCoordinateVariable"];
testRoot = CreateDirectory[];
flintBinary = SelectFirst[{
    FileNameJoin[{root, "FeynFacet", "Backends", "flint", "bin",
      "flint_modular_solve"}],
    FileNameJoin[{DirectoryName[root], "factorization-and-loops",
      "FeynFacet", "Backends", "flint", "bin",
      "flint_modular_solve"}]}, FileExistsQ, $Failed];
ratracerBinary = SelectFirst[{
    FileNameJoin[{root, "Addon", "Other_Addon", "Ratracer", "bin",
      "ratracer"}],
    FileNameJoin[{DirectoryName[root], "factorization-and-loops",
      "Addon", "Other_Addon", "Ratracer", "bin", "ratracer"}]},
  FileExistsQ, $Failed];

FTAssert["the bounded backend test has the bundled Ratracer and FLINT adapters",
  StringQ[ratracerBinary] && FileExistsQ[ratracerBinary] &&
    StringQ[flintBinary] && FileExistsQ[flintBinary]];

writeCandidate[key_String, text_String] := Module[{directory},
  directory = FileNameJoin[{testRoot, key}];
  CreateDirectory[directory];
  Export[FileNameJoin[{directory, "coordinate_solution.txt"}], text, "Text"];
  directory
];

options[key_String, seed_Integer] := Sequence[
  "CoordinateBackend" -> "Ratracer",
  "CoordinateCacheDirectory" -> testRoot,
  "CoordinateKey" -> key,
  "ReconstructionThreads" -> 1,
  "ValidationPrimeCount" -> 2,
  "ValidationPointsPerPrime" -> 2,
  "RatracerExecutable" -> ratracerBinary,
  "FLINTExecutable" -> flintBinary,
  "ValidationSeed" -> seed,
  "Verbose" -> False
];

(* The first two rows are the sampled and generic basis.  The third row has
   coordinates {x,1}; the cache path exercises no external reconstruction. *)
validMatrix = {{1, 0, 0}, {0, 1, 0}, {x, 1, 0}};
validText = StringRiffle[{
  "CO[dep@1,master@1] =", "  otffx1;",
  "CO[dep@2,master@1] =", "  1;"}, "\n"];
writeCandidate["valid", validText];
valid = FeynFacet`Private`observableTransportModularRowBasis[
  validMatrix, {x}, {{x -> 0}}, options["valid", 1001]];

FTAssert["a cached traced multi-RHS candidate is accepted only modularly",
  FeynFacet`Private`observableTransportModularRowBasisAcceptedQ[valid] &&
    valid["Rank"] === 2 && valid["Pivots"] === {1, 2} &&
    valid["ModularCertificate", "CandidateSource"] === "Cache" &&
    Normal[valid["Coordinates"]] === {{1, 0}, {0, 1}, {x, 1}} &&
    TrueQ[valid["ModularCertificate", "Probabilistic"]] &&
    TrueQ[valid["ModularCertificate", "Exact"] === False] &&
    TrueQ[valid["ModularCertificate", "AllComplementaryRowsChecked"]]];

(* This is the bounded end-to-end proof: no candidate is prewritten, so the
   real bundled Ratracer must trace and reconstruct a nonconstant two-variable
   multi-RHS solve.  Fresh validation is forced through the bundled FLINT
   adapter and also checks the unused third (complementary) equation row. *)
forcedMatrix = {{1, 0, 0}, {0, 1, 0},
  {(2/9) (u + 1)/(v + 2), u - v, 0}};
forced = FeynFacet`Private`observableTransportModularRowBasis[
  forcedMatrix, {u, v}, {{u -> 0, v -> 1}},
  options["forced_real_ratracer", 1010]];
FTAssert["real Ratracer reconstruction passes fresh FLINT and full-row checks",
  FeynFacet`Private`observableTransportModularRowBasisAcceptedQ[forced] &&
    forced["ModularCertificate", "CandidateSource"] === "Reconstructed" &&
    forced["ModularCertificate", "PivotSolvers"] === {"FLINTMultiRHS"} &&
    Normal[forced["Coordinates"]][[3]] ===
      {(2/9) (u + 1)/(v + 2), u - v}];

included = FeynFacet`Private`observableTransportModularSubspaceInclusion[
  {{1, x}}, {{2, 2 x}}, {x},
  "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> 1011];
excluded = FeynFacet`Private`observableTransportModularSubspaceInclusion[
  {{1, x}}, {{0, 1}}, {x},
  "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> 1012];
FTAssert["fresh modular points accept a genuine row-space inclusion",
  Lookup[included, "Status", None] ===
      "FreshModularSubspaceInclusionAccepted" &&
    TrueQ[Lookup[included, "Accepted", False]] &&
    Length[Lookup[included, "AcceptedTrials", {}]] === 2];
FTAssert["fresh modular points reject a false row-space inclusion",
  Lookup[excluded, "Status", None] ===
    "FreshModularSubspaceInclusionRejected"];

tripleRootSquares = {1 + u, 1 + v, 1 + u + v};
tripleTemplateMatrix = {
  {Sqrt[1 + u]/(2 + v), Sqrt[1 + v] Sqrt[1 + u + v]},
  {(1 + u)/(Sqrt[1 + v] (3 + u + v)),
    1 + Sqrt[1 + u + v]}};
tripleCompiled =
  FeynFacet`Private`observableTransportFFCompileAlgebraicMatrix[
    tripleTemplateMatrix, {u, v}, tripleRootSquares];
tripleDiscovered =
  FeynFacet`Private`observableTransportFFCompileAlgebraicMatrix[
    tripleTemplateMatrix, {u, v}, Take[tripleRootSquares, 2]];
triplePrime = 1000003;
triplePoint = {3, 5};
tripleRootValues = FeynFacet`Private`multiquadraticSquareRoots[
  Mod[tripleRootSquares /. Thread[{u, v} -> triplePoint], triplePrime],
  triplePrime];
tripleCompiledSheets = Table[With[
    {sheetSigns = Table[
      If[BitGet[mask, index - 1] === 1, -1, 1], {index, 3}]},
    FeynFacet`Private`observableTransportFFAlgebraicCompiledMatrixValue[
      tripleCompiled, triplePoint, tripleRootValues, sheetSigns,
      triplePrime]],
  {mask, 0, 7}];
tripleReferenceSheets = Table[With[
    {sheetSigns = Table[
      If[BitGet[mask, index - 1] === 1, -1, 1], {index, 3}]},
    FeynFacet`Private`observableTransportFFAlgebraicMatrixValue[
      tripleTemplateMatrix, {u, v}, triplePoint, tripleCompiled["Roots"],
      tripleRootValues, sheetSigns, triplePrime]],
  {mask, 0, 7}];
tripleCompiledDualSheets = Table[With[
    {sheetSigns = Table[
      If[BitGet[mask, index - 1] === 1, -1, 1], {index, 3}]},
    FeynFacet`Private`observableTransportFFAlgebraicCompiledMatrixValueWithDerivative[
      tripleCompiled, u, triplePoint, tripleRootValues, sheetSigns,
      triplePrime]],
  {mask, 0, 7}];
tripleReferenceDerivativeSheets = Table[With[
    {sheetSigns = Table[
      If[BitGet[mask, index - 1] === 1, -1, 1], {index, 3}]},
    FeynFacet`Private`observableTransportFFAlgebraicMatrixValue[
      D[tripleTemplateMatrix, u], {u, v}, triplePoint,
      tripleCompiled["Roots"], tripleRootValues, sheetSigns, triplePrime]],
  {mask, 0, 7}];
FTAssert["compiled formal-root templates reproduce every sign sheet",
  AssociationQ[tripleCompiled] && Length[tripleCompiled["Roots"]] === 3 &&
    tripleCompiledSheets === tripleReferenceSheets];
FTAssert["compiled root tangents reproduce symbolic derivatives on every sheet",
  tripleCompiledDualSheets[[All, 1]] === tripleReferenceSheets &&
    tripleCompiledDualSheets[[All, 2]] ===
      tripleReferenceDerivativeSheets];
FTAssert["template compilation requires the complete declared-root list",
  tripleDiscovered === $Failed];

covariantBasis = {{Sqrt[1 + u], 0}};
covariantClosedConnection = ConstantArray[0, {2, 2}];
covariantOpenConnection = {{0, 1}, {0, 0}};
covariantCompiled =
  FeynFacet`Private`observableTransportFFCompileAlgebraicCovariant[
    covariantBasis, covariantClosedConnection, {u, v}, tripleRootSquares];
covariantPivots =
  FeynFacet`Private`observableTransportFFAlgebraicCovariantIndependentRowsAtSamples[
    covariantBasis, covariantOpenConnection, u, {u, v},
    {{u -> 3, v -> 5}, {u -> 8, v -> 7}}, tripleRootSquares];
covariantIncluded =
  FeynFacet`Private`observableTransportModularAlgebraicCovariantSubspaceInclusion[
    covariantCompiled, u, {u, v},
    "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
    "ValidationSeed" -> 1015];
covariantExcluded =
  FeynFacet`Private`observableTransportModularAlgebraicCovariantSubspaceInclusion[
    covariantBasis, covariantOpenConnection, u, {u, v}, tripleRootSquares,
    "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
    "ValidationSeed" -> 1016];
covariantClosure = FeynFacet`Private`observableTransportCovariantRowClosure[
  covariantBasis, covariantOpenConnection, u, {u, v},
  {{u -> 3, v -> 5}, {u -> 8, v -> 7}}, 2, 2, 1, False,
  tripleRootSquares];
FTAssert["modular covariant images find a genuine extension",
  AllTrue[covariantPivots, # === {1, 2} &] &&
    Lookup[covariantClosure, "RankHistory", {}] === {1, 2}];
FTAssert["covariant stabilization uses all root embeddings",
  Lookup[covariantIncluded, "Status", None] ===
      "FreshModularSubspaceInclusionAccepted" &&
    AllTrue[Lookup[covariantIncluded, "AcceptedTrials", {}],
      Lookup[#, "BranchesChecked", 0] === 8 &]];
FTAssert["covariant images reject a non-invariant row space",
  Lookup[covariantExcluded, "Status", None] ===
    "FreshModularSubspaceInclusionRejected"];

tripleIncluded =
  FeynFacet`Private`observableTransportModularAlgebraicSubspaceInclusion[
    {{Sqrt[1 + u], Sqrt[1 + v]}},
    {{3 Sqrt[1 + u], 3 Sqrt[1 + v]}}, {u, v}, tripleRootSquares,
    "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
    "ValidationSeed" -> 1013];
tripleExcluded =
  FeynFacet`Private`observableTransportModularAlgebraicSubspaceInclusion[
    {{Sqrt[1 + u], Sqrt[1 + v]}},
    {{Sqrt[1 + u + v], 0}}, {u, v}, tripleRootSquares,
    "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
    "ValidationSeed" -> 1014];
FTAssert["all eight embeddings certify a genuine three-root inclusion",
  Lookup[tripleIncluded, "Status", None] ===
      "FreshModularSubspaceInclusionAccepted" &&
    AllTrue[Lookup[tripleIncluded, "AcceptedTrials", {}],
      Lookup[#, "BranchesChecked", 0] === 8 &]];
FTAssert["the three-root validator rejects a false algebraic inclusion",
  Lookup[tripleExcluded, "Status", None] ===
    "FreshModularSubspaceInclusionRejected"];

(* Original names never reach Ratracer: both are mapped to stable aliases and
   mapped back by the bounded parser. *)
twoVariableMatrix = {{1, 0, 0}, {0, 1, 0}, {u + v, 1, 0}};
twoVariableText = StringRiffle[{
  "CO[dep@1,master@1] =", "  otffx1+otffx2;",
  "CO[dep@2,master@1] =", "  1;"}, "\n"];
writeCandidate["two_variables", twoVariableText];
twoVariable = FeynFacet`Private`observableTransportModularRowBasis[
  twoVariableMatrix, {u, v}, {{u -> 0, v -> 0}},
  options["two_variables", 1002]];
FTAssert["arbitrary one- and two-variable names are isolated by aliases",
  FeynFacet`Private`observableTransportModularRowBasisAcceptedQ[twoVariable] &&
    Normal[twoVariable["Coordinates"]][[3]] === {u + v, 1} &&
    Values[twoVariable["ModularCertificate", "RatracerAliases"]] ===
      {"otffx1", "otffx2"}];

(* A syntactically valid but corrupted rational candidate must not be repaired
   or sent to another reconstruction backend. *)
corruptText = StringReplace[validText, "otffx1;" -> "otffx1+1;"];
writeCandidate["corrupt", corruptText];
corrupt = FeynFacet`Private`observableTransportModularRowBasis[
  validMatrix, {x}, {{x -> 0}}, options["corrupt", 1003]];
FTAssert["a corrupted cache candidate fails the independent pivot solve",
  Lookup[corrupt, "Status", None] === "FreshModularIdentityRejected" &&
    Lookup[corrupt, "Reason", None] ===
      "IndependentPivotSolutionMismatch"];

duplicateText = validText <> "\nCO[dep@1,master@1] =\n  otffx1;\n";
writeCandidate["duplicate", duplicateText];
duplicate = FeynFacet`Private`observableTransportModularRowBasis[
  validMatrix, {x}, {{x -> 0}}, options["duplicate", 1004]];
FTAssert["duplicate Ratracer outputs are rejected while streaming",
  Lookup[duplicate, "Status", None] === "CoordinateCandidateDuplicate"];

omittedText = "CO[dep@2,master@1] =\n  1;\n";
writeCandidate["omitted", omittedText];
omitted = FeynFacet`Private`observableTransportModularRowBasis[
  validMatrix, {x}, {{x -> 0}}, options["omitted", 1005]];
FTAssert["an omitted nonzero output is treated as zero and rejected fresh",
  Lookup[omitted, "Status", None] === "FreshModularIdentityRejected" &&
    Lookup[omitted, "Reason", None] ===
      "IndependentPivotSolutionMismatch"];

(* At the rank-proposal point x=0 the third row is in the first-two-row span.
   Its pivot coordinates remain {x,1}, so a pivot-only verifier would accept;
   the last column exposes the false span at every allowed fresh point. *)
pivotOnlyFalseMatrix = {{1, 0, 0}, {0, 1, 0}, {x, 1, x}};
writeCandidate["pivot_only_false", validText];
pivotOnlyFalse = FeynFacet`Private`observableTransportModularRowBasis[
  pivotOnlyFalseMatrix, {x}, {{x -> 0}},
  options["pivot_only_false", 1006]];
FTAssert["all complementary rows are checked after the pivot solve",
  Lookup[pivotOnlyFalse, "Status", None] ===
      "FreshModularIdentityRejected" &&
    Lookup[pivotOnlyFalse, "Reason", None] ===
      "ComplementaryRowResidualNonzero"];

DeleteDirectory[testRoot, DeleteContents -> True];
FTReport[];
