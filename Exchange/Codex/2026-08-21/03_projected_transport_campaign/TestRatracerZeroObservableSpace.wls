#!/usr/bin/env wolframscript

(* External regression for exact closure of a demand-dual automaton whose
   next observable row space has rank zero before the requested cutoff. *)

$HistoryLength = 0;
root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Block[{$Context = "FeynFacet`Private`",
    $ContextPath = {"FeynFacet`", "System`", "Global`"}},
  Get[FileNameJoin[{bundle,
    "CodexObservableTransportRatracerCandidate.wl"}]]];

result = FeynFacet`Private`observableTransportDualObservableCertificate[
  {SparseArray[{}, {2, 2}]},
  {{1, 0}},
  IdentityMatrix[2],
  2,
  {{}},
  True
];

terminalDimensions = Dimensions /@
  Lookup[result, "TerminalContractionsByExactWeight", {}];
exact = AssociationQ[result] &&
  Lookup[result, "Status", None] === "Exact" &&
  Lookup[result, "ObservableRankByExactWeight", None] === {1, 0, 0} &&
  Lookup[result, "DemandedMapIsZero", None] === {False, True, True} &&
  Lookup[result, "DemandedNonzeroEntries", None] === {1, 0, 0} &&
  terminalDimensions === {{1, 2}, {0}, {0}} &&
  FreeQ[result, _Part];

Print["CODEX_ZERO_SPACE_REGRESSION exact=", exact,
  " ranks=", InputForm[Lookup[result,
    "ObservableRankByExactWeight", Missing[]]],
  " terminal_zero=", InputForm[Lookup[result,
    "DemandedMapIsZero", Missing[]]],
  " terminal_dimensions=", InputForm[terminalDimensions]];
If[! TrueQ[exact],
  Print[InputForm[result]];
  Exit[1]
];
