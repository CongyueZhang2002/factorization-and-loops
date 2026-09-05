#!/usr/bin/env wolframscript

(* Build one V2 FamilyDifferentialSystemBlockDecomposition from one explicit
   V2 FamilyDifferentialSystem.  Project paths belong here, not in package
   mathematics. *)

$HistoryLength = 0;

usage = StringRiffle[{
  "wolframscript -file build_family_differential_system_block_decomposition_v2.wls",
  "  --repository-root ROOT",
  "  --family-differential-system PATH --output PATH",
  "  [--validation-method finite-field|symbolic]",
  "  [--finite-field-primes p1,p2,...] [--points-per-prime 3]",
  "  [--seed 20260904] [--maximum-attempts-per-prime 30]",
  "  [--overwrite true|false]",
  "PATH may be absolute or relative to ROOT."
}, "\n"];

fail[status_String, extra_: <||>, exitCode_: 64] := (
  Print[InputForm[Join[<|"Status" -> status|>, extra]]];
  Exit[exitCode]
);

parsePositiveInteger[text_String] /;
    StringMatchQ[text, DigitCharacter ..] := FromDigits[text];
parsePositiveInteger[_] := $Failed;

absolutePathQ[path_String] := StringStartsQ[path, "/"] ||
  StringMatchQ[path, RegularExpression["^[A-Za-z]:[\\\\/]"]];

resolvePath[root_String, path_String] := ExpandFileName[
  If[absolutePathQ[path], path, FileNameJoin[{root, path}]]];

artifactReference[root_String, file_String, family_String] := Module[
  {rootParts = FileNameSplit[root], fileParts = FileNameSplit[file], path},
  path = If[Length[fileParts] >= Length[rootParts] &&
      Take[fileParts, Length[rootParts]] === rootParts,
    <|"RelativePath" ->
      FileNameJoin[Drop[fileParts, Length[rootParts]]]|>,
    <|"ExplicitPath" -> file|>];
  Join[path, <|"DataType" -> "FamilyDifferentialSystem",
    "SchemaVersion" -> 2, "Family" -> family|>]
];

args = Rest[$ScriptCommandLine];
If[MemberQ[args, "--help"] || MemberQ[args, "-h"], Print[usage]; Exit[0]];
If[OddQ[Length[args]], fail["CommandLineArgumentsInvalid",
  <|"Usage" -> usage|>]];
pairs = Partition[args, 2];
If[! AllTrue[pairs,
    StringQ[First[#]] && StringStartsQ[First[#], "--"] &] ||
    ! DuplicateFreeQ[First /@ pairs],
  fail["CommandLineArgumentsInvalid", <|"Usage" -> usage|>]];
raw = Association[(StringDrop[First[#], 2] -> Last[#]) & /@ pairs];
known = {"repository-root", "family-differential-system", "output",
  "validation-method", "finite-field-primes", "points-per-prime",
  "seed", "maximum-attempts-per-prime", "overwrite"};
unknown = Complement[Keys[raw], known];
If[unknown =!= {}, fail["CommandLineOptionUnknown",
  <|"UnknownOptions" -> unknown|>]];
missing = Select[{"repository-root", "family-differential-system", "output"},
  ! KeyExistsQ[raw, #] &];
If[missing =!= {}, fail["CommandLineOptionsMissing",
  <|"MissingOptions" -> missing, "Usage" -> usage|>]];

repositoryRoot = ExpandFileName[raw["repository-root"]];
If[! DirectoryQ[repositoryRoot], fail["RepositoryRootNotFound",
  <|"RepositoryRoot" -> repositoryRoot|>, 66]];
inputFile = resolvePath[repositoryRoot,
  raw["family-differential-system"]];
outputFile = resolvePath[repositoryRoot, raw["output"]];
If[! FileExistsQ[inputFile], fail["FamilyDifferentialSystemFileNotFound",
  <|"FamilyDifferentialSystemFile" -> inputFile|>, 66]];
If[inputFile === outputFile, fail["InputAndOutputPathsCoincide"]];

method = Switch[Lookup[raw, "validation-method", "finite-field"],
  "finite-field", "ProbabilisticFiniteFieldSampling",
  "symbolic", "CharacteristicZeroSymbolicIdentity",
  _, $Failed];
primes = If[KeyExistsQ[raw, "finite-field-primes"],
  parsePositiveInteger /@ StringSplit[raw["finite-field-primes"], ","],
  {2147483629, 2147483587, 2147483579}];
points = parsePositiveInteger[Lookup[raw, "points-per-prime", "3"]];
seed = parsePositiveInteger[Lookup[raw, "seed", "20260904"]];
maximumAttempts = parsePositiveInteger[
  Lookup[raw, "maximum-attempts-per-prime", "30"]];
overwrite = Switch[ToLowerCase[Lookup[raw, "overwrite", "false"]],
  "true", True, "false", False, _, $Failed];
If[MemberQ[{method, points, seed, maximumAttempts, overwrite}, $Failed] ||
    MemberQ[primes, $Failed],
  fail["CommandLineOptionValueInvalid"]];
If[FileExistsQ[outputFile] && ! TrueQ[overwrite],
  fail["OutputFileAlreadyExists", <|"OutputFile" -> outputFile|>, 73]];

scriptFile = ExpandFileName[$InputFileName];
packageRoot = ParentDirectory[ParentDirectory[DirectoryName[scriptFile]]];
Get[FileNameJoin[{packageRoot, "Addon", "Load", "LoadFACET.wl"}]];

system = FeynFacet`FamilyArtifactRead[inputFile];
If[! AssociationQ[system], fail["FamilyDifferentialSystemUnreadable",
  <|"FamilyDifferentialSystemFile" -> inputFile|>, 65]];
family = Lookup[system, "Family", Missing[]];
If[! StringQ[family], fail["FamilyDifferentialSystemInvalid", <||>, 65]];
reference = artifactReference[repositoryRoot, inputFile, family];

{seconds, decomposition} = AbsoluteTiming[
  FeynFacet`BuildFamilyDifferentialSystemBlockDecomposition[
    system, reference,
    "ValidationMethod" -> method,
    "FiniteFieldPrimes" -> primes,
    "PointsPerPrime" -> points,
    "Seed" -> seed,
    "MaximumAttemptsPerPrime" -> maximumAttempts]
];
If[! AssociationQ[decomposition] ||
    Lookup[decomposition, "Status", None] =!=
      "FamilyDifferentialSystemBlockDecompositionValidated",
  Print[InputForm[decomposition]];
  Exit[2]];

FeynFacet`FamilyArtifactWrite[decomposition, outputFile];
Print["BLOCK-DECOMPOSITION family=", family,
  " blocks=", Length[decomposition["IrreducibleDiagonalBlocks"]],
  " method=", method,
  " seconds=", Round[seconds, 0.01],
  " output=", outputFile];
