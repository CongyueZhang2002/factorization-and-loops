#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

args = Rest[$ScriptCommandLine];
If[Length[args] =!= 2,
  Print["Usage: rationalize_transport_chart_extension.wls " <>
    "<specification.wl> <output-parametrization.wl>"];
  Exit[64]
];
specificationFile = ExpandFileName[args[[1]]];
outputFile = ExpandFileName[args[[2]]];
If[! FileExistsQ[specificationFile],
  Print["Parametrization-extension specification does not exist: ",
    specificationFile];
  Exit[66]
];
specification = Get[specificationFile];
If[! AssociationQ[specification],
  Print["Parametrization-extension specification must be an Association."];
  Exit[65]
];

base = Lookup[specification, "BaseRationalizingParametrization", Missing[]];
baseParametrization = Which[
  AssociationQ[base], base,
  StringQ[base] && FileExistsQ[base], Get[base],
  StringQ[base], Lookup[FeynFacet`RationalizingParametrizationCatalog[], base, None],
  True, None
];
If[! AssociationQ[baseParametrization] ||
    ! TrueQ[FeynFacet`VerifyRationalizingParametrization[
      baseParametrization]["Verified"]],
  Print["Base rationalizing parametrization is missing or invalid."];
  Exit[2]
];
rootSquare = Lookup[specification, "RootSquare", Missing[]];
If[MissingQ[rootSquare],
  Print["Specification has no RootSquare."];
  Exit[65]
];

result = FeynFacet`ExtendRationalizingParametrization[
  baseParametrization, rootSquare,
  "Name" -> Lookup[specification, "Name", Automatic],
  "OutputVariables" -> Lookup[specification, "OutputVariables", Automatic],
  "AllCharts" -> Lookup[specification, "AllCharts", True],
  "AllPoints" -> Lookup[specification, "AllPoints", True],
  "TimeConstraint" -> Lookup[specification, "TimeConstraint", 1800]
];
If[! AssociationQ[result] ||
    Lookup[result, "Status", None] =!=
      "RationalizingParametrizationVerified" ||
    ! TrueQ[FeynFacet`VerifyRationalizingParametrization[result]["Verified"]],
  Print["No verified rationalizing parametrization was found: ",
    InputForm[KeyDrop[result, "CandidateResults"]]];
  Exit[2]
];

If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporaryFile = outputFile <> ".tmp";
Put[result, temporaryFile];
RenameFile[temporaryFile, outputFile, OverwriteTarget -> True];
Print[InputForm[<|
  "Status" -> "RationalizingParametrizationVerified",
  "Name" -> result["Name"],
  "ParametrizingVariables" -> result["ParametrizingVariables"],
  "RationalizedSquareRootCount" ->
    Length[result["RationalizedSquareRoots"]],
  "CandidateCount" -> result["RationalizeRootsCandidateCount"],
  "ExactCandidateCount" -> result["ExactCandidateCount"],
  "Output" -> outputFile|>]];
