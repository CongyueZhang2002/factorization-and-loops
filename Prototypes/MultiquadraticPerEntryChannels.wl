(* Prototypes/MultiquadraticPerEntryChannels.wl

   A persistent characteristic-zero forcing-channel materializer with one
   checkpoint per scalar entry.  The production multiquadratic solver no
   longer calls it: SplitBranch is the primary provider, QuotientGrade is its
   nonsplit oracle, and CompiledChannel is the explicit global-channel oracle.
   This implementation remains available for a future consumer that truly
   requires exact channel artifacts.

   Load after FeynFacet.  The definitions intentionally live in the package's
   private context because they use its grade algebra, artifact helpers,
   deadline policy, and typed failures. *)

Begin["FeynFacet`Private`"];

ClearAll[$multiquadraticStripPerEntrySchema,
  multiquadraticStripPerEntryCheckpointFile,
  multiquadraticStripDecomposeEntryLocal,
  multiquadraticStripDecomposeForcingPerEntry];

$multiquadraticStripPerEntrySchema = "MultiquadraticPerEntryChannelsV1";

multiquadraticStripPerEntryCheckpointFile[directory_, tag_String,
    index_Integer] :=
  FileNameJoin[{directory, tag <> "_entry_" <> ToString[index] <> ".wl"}];

multiquadraticStripDecomposeEntryLocal[entry_, roots_List] := Module[
  {activeIndices, localRoots, channels, lifted, rank = Length[roots]},
  activeIndices = multiquadraticStripEntryActiveRoots[entry, roots];
  localRoots = roots[[activeIndices]];
  channels = multiquadraticFieldDecompose[entry, localRoots];
  If[channels === $Failed,
    Return[<|"Status" -> "EntryDecompositionFailed",
      "ActiveRoots" -> activeIndices|>]];
  lifted = multiquadraticLiftLocalChannels[channels, activeIndices, rank];
  If[lifted === $Failed,
    Return[<|"Status" -> "LocalChannelLiftFailed",
      "ActiveRoots" -> activeIndices|>]];
  <|"Status" -> "OK", "Channels" -> lifted,
    "ActiveRoots" -> activeIndices,
    "LocalRank" -> Length[activeIndices]|>
];

Options[multiquadraticStripDecomposeForcingPerEntry] = {
  "CheckpointDirectory" -> None,
  "CheckpointTag" -> "forcing",
  "SymbolicFallback" -> True,
  "Deadline" -> Infinity
};

multiquadraticStripDecomposeForcingPerEntry[forcing_, roots_List,
    opts : OptionsPattern[]] := Module[
  {gate, startTime = AbsoluteTime[], dimensions, entries, directory, tag,
   fallback, deadline, results, records = {}, index = 0, failed = {},
   fallbacks = 0, restored = 0, rank = Length[roots], stored, file},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripDecomposeForcingPerEntry]]]];
  If[AssociationQ[gate], Return[gate]];
  dimensions = Dimensions[forcing];
  If[Length[dimensions] =!= 3,
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  directory = OptionValue["CheckpointDirectory"];
  tag = OptionValue["CheckpointTag"];
  fallback = TrueQ[OptionValue["SymbolicFallback"]];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline"]]];
  If[directory =!= None && ! DirectoryQ[directory],
    Quiet[CreateDirectory[directory, CreateIntermediateDirectories -> True]]];
  entries = Flatten[forcing];
  results = Table[
    index++;
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      Return[multiquadraticStripBudgetExhausted["PerEntryDecomposition",
        AbsoluteTime[] - startTime, deadline,
        <|"EntriesDone" -> index - 1, "Entries" -> Length[entries]|>],
        Module]];
    stored = If[directory === None, Missing["CheckpointsDisabled"],
      file = multiquadraticStripPerEntryCheckpointFile[directory, tag, index];
      If[! FileExistsQ[file], Missing["CheckpointAbsent"],
        Module[{raw = multiquadraticStripArtifactLoadRaw[file,
            "FeynFacet`MultiquadraticArtifact`"]},
          If[Lookup[raw, "Status", None] =!= "RawMultiquadraticArtifact",
            Missing["CheckpointUnreadable"],
            Module[{value = raw["Value"]},
              If[AssociationQ[value] &&
                  Lookup[value, "Schema", None] ===
                    $multiquadraticStripPerEntrySchema &&
                  Lookup[value, "EntryHash", None] ===
                    Hash[ToString[InputForm[entry]], "SHA256", "HexString"] &&
                  ListQ[Lookup[value, "Channels", None]] &&
                  Length[value["Channels"]] === 2^rank,
                value, Missing["CheckpointRefused"]]]]]]];
    If[! MissingQ[stored],
      restored++;
      AppendTo[records, <|"Index" -> index, "Source" -> "Checkpoint",
        "ActiveRoots" -> Lookup[stored, "ActiveRoots", {}]|>];
      stored["Channels"],
      Module[{result = multiquadraticStripDecomposeEntryLocal[entry, roots],
          channels},
        If[Lookup[result, "Status", None] === "OK",
          channels = result["Channels"];
          AppendTo[records, <|"Index" -> index, "Source" -> "Decomposed",
            "ActiveRoots" -> result["ActiveRoots"]|>],
          AppendTo[failed, <|"Index" -> index,
            "Status" -> Lookup[result, "Status", None]|>];
          If[! fallback, channels = $Failed,
            fallbacks++;
            channels = multiquadraticFieldDecompose[Together[entry], roots];
            AppendTo[records, <|"Index" -> index,
              "Source" -> "SymbolicFallback",
              "ActiveRoots" -> Lookup[result, "ActiveRoots", {}]|>]]];
        If[ListQ[channels] && directory =!= None,
          multiquadraticStripArtifactWrite[
            <|"Schema" -> $multiquadraticStripPerEntrySchema,
              "SourceSHA256" -> $multiquadraticStripSourceSHA256,
              "EntryHash" -> Hash[ToString[InputForm[entry]],
                "SHA256", "HexString"],
              "ActiveRoots" -> Lookup[result, "ActiveRoots", {}],
              "Rank" -> rank, "Channels" -> channels|>,
            multiquadraticStripPerEntryCheckpointFile[
              directory, tag, index]]];
        channels]],
    {entry, entries}];
  If[! ListQ[results], Return[results]];
  <|"Status" -> If[MemberQ[results, $Failed],
      "PerEntryDecompositionIncomplete", "PerEntryChannelsV1"],
    "Channels" -> ArrayReshape[results, Append[dimensions, 2^rank]] //
      Quiet[Check[#1, $Failed]] &,
    "EntryCount" -> Length[entries], "RestoredEntries" -> restored,
    "SymbolicFallbacks" -> fallbacks, "FailedEntries" -> failed,
    "Records" -> records,
    "ActiveRootHistogram" -> Counts[
      Length[Lookup[#1, "ActiveRoots", {}]] & /@ records],
    "Seconds" -> AbsoluteTime[] - startTime|>
];
multiquadraticStripDecomposeForcingPerEntry[___] :=
  multiquadraticStripFailure["InvalidPerEntryDecompositionArguments"];

End[];
