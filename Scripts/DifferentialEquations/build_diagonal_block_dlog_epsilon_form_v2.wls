#!/usr/bin/env wolframscript

(* Build one V2 DiagonalBlockDLogEpsilonForm from explicitly named artifacts
   and explicitly ordered family rows.  This launcher contains no family,
   class, or file-name dispatch. *)

$HistoryLength = 0;

usage = StringRiffle[{
  "wolframscript -file build_diagonal_block_dlog_epsilon_form_v2.wls",
  "  --repository-root ROOT",
  "  --family-differential-system PATH",
  "  --coefficient-presentation PATH",
  "  --block-rows i1,i2,... --output PATH",
  "  [--candidate-diagonal-block-dlog-epsilon-form PATH]",
  "  [--overwrite true|false]",
  "PATH may be absolute or relative to ROOT."
}, "\n"];

fail[status_String, extra_: <||>, exitCode_: 64] := (
  Print[InputForm[Join[<|"Status" -> status|>, extra]]];
  Exit[exitCode]
);

absolutePathQ[path_String] := StringStartsQ[path, "/"] ||
  StringMatchQ[path, RegularExpression["^[A-Za-z]:[\\\\/]"]];

resolvePath[root_String, path_String] := ExpandFileName[
  If[absolutePathQ[path], path, FileNameJoin[{root, path}]]];

parsePositiveInteger[text_String] /;
    StringMatchQ[text, DigitCharacter ..] := FromDigits[text];
parsePositiveInteger[_] := $Failed;

parseRows[text_String] := Module[{rows},
  rows = parsePositiveInteger /@ StringSplit[text, ","];
  If[rows === {} || MemberQ[rows, $Failed] || ! DuplicateFreeQ[rows],
    $Failed, rows]
];

args = Rest[$ScriptCommandLine];
If[MemberQ[args, "--help"] || MemberQ[args, "-h"],
  Print[usage]; Exit[0]];
If[OddQ[Length[args]],
  fail["CommandLineArgumentsInvalid", <|"Usage" -> usage|>]];
pairs = Partition[args, 2];
If[! AllTrue[pairs,
    StringQ[First[#]] && StringStartsQ[First[#], "--"] &] ||
    ! DuplicateFreeQ[First /@ pairs],
  fail["CommandLineArgumentsInvalid", <|"Usage" -> usage|>]];
raw = Association[(StringDrop[First[#], 2] -> Last[#]) & /@ pairs];
known = {"repository-root", "family-differential-system",
  "coefficient-presentation", "block-rows", "output",
  "candidate-diagonal-block-dlog-epsilon-form", "overwrite"};
unknown = Complement[Keys[raw], known];
If[unknown =!= {}, fail["CommandLineOptionUnknown",
  <|"UnknownOptions" -> unknown|>]];
missing = Select[{"repository-root", "family-differential-system",
    "coefficient-presentation", "block-rows", "output"},
  ! KeyExistsQ[raw, #] &];
If[missing =!= {}, fail["CommandLineOptionsMissing",
  <|"MissingOptions" -> missing, "Usage" -> usage|>]];

repositoryRoot = ExpandFileName[raw["repository-root"]];
If[! DirectoryQ[repositoryRoot], fail["RepositoryRootNotFound",
  <|"RepositoryRoot" -> repositoryRoot|>, 66]];
systemFile = resolvePath[repositoryRoot,
  raw["family-differential-system"]];
presentationFile = resolvePath[repositoryRoot,
  raw["coefficient-presentation"]];
outputFile = resolvePath[repositoryRoot, raw["output"]];
candidateFile = If[KeyExistsQ[raw,
    "candidate-diagonal-block-dlog-epsilon-form"],
  resolvePath[repositoryRoot,
    raw["candidate-diagonal-block-dlog-epsilon-form"]], None];
blockRows = parseRows[raw["block-rows"]];
overwrite = Switch[ToLowerCase[Lookup[raw, "overwrite", "false"]],
  "true", True, "false", False, _, $Failed];
If[blockRows === $Failed || overwrite === $Failed,
  fail["CommandLineOptionValueInvalid"]];
If[! FileExistsQ[systemFile], fail[
  "FamilyDifferentialSystemFileNotFound", <|
    "FamilyDifferentialSystemFile" -> systemFile|>, 66]];
If[! FileExistsQ[presentationFile], fail[
  "CoefficientPresentationFileNotFound", <|
    "CoefficientPresentationFile" -> presentationFile|>, 66]];
If[StringQ[candidateFile] && ! FileExistsQ[candidateFile], fail[
  "CandidateDiagonalBlockDLogEpsilonFormFileNotFound", <|
    "CandidateFile" -> candidateFile|>, 66]];
If[MemberQ[DeleteCases[{systemFile, presentationFile, candidateFile}, None],
    outputFile], fail["InputAndOutputPathsCoincide"]];
If[FileExistsQ[outputFile] && ! TrueQ[overwrite],
  fail["OutputFileAlreadyExists", <|"OutputFile" -> outputFile|>, 73]];

scriptFile = ExpandFileName[$InputFileName];
packageRoot = ParentDirectory[ParentDirectory[DirectoryName[scriptFile]]];
Get[FileNameJoin[{packageRoot, "Addon", "Load", "LoadFACET.wl"}]];

system = FeynFacet`FamilyArtifactRead[systemFile];
presentation = FeynFacet`FamilyArtifactRead[presentationFile];
candidate = If[candidateFile === None, Automatic,
  FeynFacet`FamilyArtifactRead[candidateFile]];
If[! AssociationQ[system] || ! AssociationQ[presentation] ||
    (candidateFile =!= None && ! AssociationQ[candidate]),
  fail["DiagonalBlockDLogEpsilonFormInputUnreadable", <|
    "FamilyDifferentialSystemFile" -> systemFile,
    "CoefficientPresentationFile" -> presentationFile,
    "CandidateFile" -> candidateFile|>, 65]];

result = FeynFacet`ConstructDiagonalBlockDLogEpsilonForm[
  system, presentation, blockRows,
  "CandidateDiagonalBlockDLogEpsilonForm" -> candidate];
If[! TrueQ[FeynFacet`DiagonalBlockDLogEpsilonFormQ[
      result, system, presentation]],
  Print[InputForm[result]];
  Exit[2]];

FeynFacet`FamilyArtifactWrite[result, outputFile];
Print["DIAGONAL-BLOCK-DLOG-EPSILON-FORM rows=",
  InputForm[blockRows], " status=", result["Status"],
  " output=", outputFile];
