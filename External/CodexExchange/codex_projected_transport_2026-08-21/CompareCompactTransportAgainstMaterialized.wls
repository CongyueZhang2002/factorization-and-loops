#!/usr/bin/env wolframscript

(* Exact validation of the compact two-segment transport automaton.  The
   materialized record supplies only the word keys; every corresponding map
   is reconstructed independently from the compact quotient transitions. *)

$HistoryLength = 0;

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["Usage: CompareCompactTransportAgainstMaterialized.wls " <>
    "MATERIALIZED.wl COMPACT.wl OUTPUT.wl"];
  Exit[64]
];

{materializedFile, compactFile, outputFile} = ExpandFileName /@ arguments;
If[! And @@ (FileExistsQ /@ {materializedFile, compactFile}), Exit[66]];

root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{bundle, "CodexProjectedTransportStandard.wl"}]];

readGlobal[file_] := Block[
  {$ContextPath = {"System`", "Global`"}, $Context = "Global`"},
  Quiet[Check[Get[file], $Failed]]
];

materialized = readGlobal[materializedFile];
compact = readGlobal[compactFile];
If[! AssociationQ[materialized] || ! AssociationQ[compact], Exit[65]];

canonicalize[expression_] := expression /.
  symbol_Symbol /;
      StringStartsQ[SymbolName[Unevaluated[symbol]], "observablePath"] :>
    codexCanonicalObservablePath;

canonicalizeMap[m_] := Map[Quiet[Cancel[Together[#]]] &,
  Normal[canonicalize[m]], {2}];

exactMapSameQ[a_, b_] := TrueQ[
  FeynFacet`Private`masterTransportZeroMatQ[
    canonicalize[a] - canonicalize[b]]];

firstMaps = Lookup[materialized, "FirstSegmentWordMaps", {}];
twoMaps = Lookup[materialized, "TwoSegmentWordMaps", {}];

firstChecks = Table[
  reconstructed =
    CodexProjectedTransportStandard`CodexProjectedTransportWordMap[
      compact, entry[[1]], {}];
  AssociationQ[reconstructed] &&
    Lookup[reconstructed, "Status", None] === "ExactWordMap" &&
    exactMapSameQ[entry[[2]],
      Lookup[reconstructed, "Map", Missing[]]],
  {entry, firstMaps}
];

twoChecks = Table[
  reconstructed =
    CodexProjectedTransportStandard`CodexProjectedTransportWordMap[
      compact, entry[[1]], entry[[2]]];
  AssociationQ[reconstructed] &&
    Lookup[reconstructed, "Status", None] === "ExactWordMap" &&
    exactMapSameQ[entry[[3]],
      Lookup[reconstructed, "Map", Missing[]]],
  {entry, twoMaps}
];

structuralFields = {
  "Family", "Variables", "Regulator", "PhysicalRows",
  "PhysicalDemandPairs", "PhysicalValuation", "Path", "BoundarySlots",
  "BoundaryConstraintMatrix", "BoundaryKernel", "BoundaryCoordinates",
  "ConstraintRank", "SpectatorConstraintRank", "DualClosureRankHistory",
  "FirstSegmentKernelMethod", "FirstSegmentKernels",
  "FirstSegmentKernelMatrices", "FirstSegmentActiveLetters",
  "ObservableMaximumFirstSegmentWeight", "SecondSegmentKernels",
  "SecondSegmentKernelMatrices", "SecondSegmentKernelMethod",
  "MaximumWeight"
};
structuralChecks = Association@Table[
  field -> SameQ[
    canonicalize[Lookup[materialized, field, Missing["Materialized"]]],
    canonicalize[Lookup[compact, field, Missing["Compact"]]]],
  {field, structuralFields}
];

certificates = Lookup[compact, "Certificates", <||>];
automaton = Lookup[compact, "CompactTransportAutomaton", <||>];
certificateChecks = <|
  "CompactTerminalStatusExact" ->
    CodexProjectedTransportStandard`CodexProjectedTransportExactQ[compact],
  "AllCompactCertificatesTrue" ->
    AssociationQ[certificates] && And @@ (TrueQ /@ Values[certificates]),
  "CompactAutomatonStatusExact" ->
    AssociationQ[automaton] &&
      Lookup[automaton, "Status", None] ===
        "ExactCompactTwoSegmentAutomaton",
  "NoFirstWordsMaterialized" ->
    MissingQ[Lookup[compact, "FirstSegmentWordMaps", Missing[]]],
  "NoTwoSegmentWordsMaterialized" ->
    MissingQ[Lookup[compact, "TwoSegmentWordMaps", Missing[]]]
|>;

allSame = And @@ Join[firstChecks, twoChecks, Values[structuralChecks],
  Values[certificateChecks]];
twoMismatchPositions = Flatten[Position[twoChecks, False]];
result = <|
  "Status" -> If[allSame, "ExactCompactReconstruction", "Mismatch"],
  "Family" -> Lookup[compact, "Family", Missing[]],
  "MaterializedFirstMapsChecked" -> Length[firstChecks],
  "MaterializedTwoSegmentMapsChecked" -> Length[twoChecks],
  "AllFirstMapsSameQ" -> And @@ firstChecks,
  "AllTwoSegmentMapsSameQ" -> And @@ twoChecks,
  "FirstTwoSegmentMismatch" -> If[twoMismatchPositions === {}, None,
    With[{entry = twoMaps[[First[twoMismatchPositions]]]},
      <|"Position" -> First[twoMismatchPositions],
        "FirstWord" -> entry[[1]], "SecondWord" -> entry[[2]]|>]],
  "AllStructuralFieldsSameQ" -> And @@ Values[structuralChecks],
  "AllCompactCertificatesTrue" -> And @@ Values[certificateChecks],
  "StructuralChecks" -> structuralChecks,
  "CertificateChecks" -> certificateChecks,
  "MaterializedFile" -> materializedFile,
  "CompactFile" -> compactFile,
  "MaterializedSHA256" ->
    FileHash[materializedFile, "SHA256", "HexString"],
  "CompactSHA256" -> FileHash[compactFile, "SHA256", "HexString"]
|>;

temporary = outputFile <> ".partial-" <> ToString[$ProcessID];
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print[InputForm[result]];
If[! allSame, Exit[1]];
