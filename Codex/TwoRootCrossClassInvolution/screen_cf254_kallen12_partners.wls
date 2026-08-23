#!/usr/bin/env wolframscript

(* Necessary block-class screen for a CF254 -> Kallen12 subsystem map. *)

$HistoryLength = 0;

directory = DirectoryName[$InputFileName];
cataloguePath =
  "/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/" <>
    "NNLOInventoryAudit/ExactBlockEquivalenceCatalogue.wl";
checkpointDirectory =
  "/home/maxzhang/FACET/Codex/General/LibraTwoRootBlockwise_20260819";

sourceFamily = "CF254";
candidateFamilies = {"CF232", "CF236", "CF240", "CF319", "CF321",
  "CF385", "CF408"};

catalogue = Get[cataloguePath];
blockToClass = catalogue["BlockToClass"];

familyBlockClasses[family_String] := Module[{indices, ids},
  indices = Sort@Cases[Keys[blockToClass],
    id_String /; StringStartsQ[id, family <> "_B"] :>
      ToExpression[StringDelete[id, family <> "_B"]]];
  ids = family <> "_B" <> ToString[#] & /@ indices;
  Lookup[blockToClass, ids]
];

familyDimension[family_String] := Module[{record},
  record = Get[FileNameJoin[{checkpointDirectory,
    "blockwise_local_" <> family <> ".wl"}]];
  Length[record["SystemX"]]
];

multisetContainedQ[source_List, target_List] := Module[{counts},
  counts = Counts[target];
  AllTrue[Normal[Counts[source]], Last[#] <= Lookup[counts, First[#], 0] &]
];

sourceClasses = familyBlockClasses[sourceFamily];
sourceCounts = Counts[sourceClasses];

rows = Table[
  targetClasses = familyBlockClasses[family];
  targetCounts = Counts[targetClasses];
  missing = Association@Select[Normal[sourceCounts],
    Last[#] > Lookup[targetCounts, First[#], 0] &];
  <|
    "CandidateFamily" -> family,
    "SourceDimension" -> familyDimension[sourceFamily],
    "CandidateDimension" -> familyDimension[family],
    "SourceBlockClasses" -> sourceClasses,
    "CandidateBlockClasses" -> targetClasses,
    "MissingSourceClassMultiplicities" -> missing,
    "ExactPermutationExchangeSubsystemPossible" ->
      multisetContainedQ[sourceClasses, targetClasses]
  |>,
  {family, candidateFamilies}
];

result = <|
  "SourceFamily" -> sourceFamily,
  "Candidates" -> candidateFamilies,
  "CatalogueCriterion" -> catalogue["EquivalenceCriterion"],
  "ScreenCriterion" ->
    "Every source diagonal-block class, with multiplicity, must occur in the candidate for an exact subsystem identity made only from block permutations, within-block permutations, and v-w exchange",
  "Rows" -> rows,
  "AnyPermutationExchangeCandidate" ->
    AnyTrue[rows,
      TrueQ[#["ExactPermutationExchangeSubsystemPossible"]] &],
  "Scope" ->
    "A negative result excludes the proposed cheap permutation/exchange identity but does not exclude a nonconstant rational block gauge"
|>;

Put[result,
  FileNameJoin[{directory, "CF254_Kallen12_partner_screen.wl"}]];
Print[InputForm[KeyDrop[#, {"SourceBlockClasses",
      "CandidateBlockClasses"}]] & /@ rows];
Print["Any exact permutation/exchange candidate: ",
  result["AnyPermutationExchangeCandidate"]];
