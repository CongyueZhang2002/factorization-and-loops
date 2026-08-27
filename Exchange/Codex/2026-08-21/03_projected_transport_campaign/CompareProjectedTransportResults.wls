#!/usr/bin/env wolframscript

(* Exact regression comparison for a baseline and an externally optimized
   projected-transport result.  Timing/provenance fields are intentionally
   excluded; every mathematical map and certificate is compared with SameQ. *)

$HistoryLength = 0;

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["Usage: CompareProjectedTransportResults.wls " <>
    "BASELINE.wl CANDIDATE.wl OUTPUT.wl"];
  Exit[64]
];

{baselineFile, candidateFile, outputFile} = ExpandFileName /@ arguments;
If[! And @@ (FileExistsQ /@ {baselineFile, candidateFile}), Exit[66]];

readGlobal[file_] := Block[
  {$ContextPath = {"System`", "Global`"}, $Context = "Global`"},
  Quiet[Check[Get[file], $Failed]]
];

baseline = readGlobal[baselineFile];
candidate = readGlobal[candidateFile];
If[! AssociationQ[baseline] || ! AssociationQ[candidate], Exit[65]];

fields = {
  "Family",
  "Variables",
  "Regulator",
  "PhysicalRows",
  "PhysicalDemandPairs",
  "PhysicalValuation",
  "Path",
  "BoundarySlots",
  "BoundaryConstraintMatrix",
  "BoundaryKernel",
  "BoundaryCoordinates",
  "ConstraintRank",
  "DualClosureRankHistory",
  "FirstSegmentKernelMethod",
  "FirstSegmentKernels",
  "FirstSegmentKernelMatrices",
  "DLogLetters",
  "DLogResidues",
  "FirstSegmentActiveLetters",
  "FirstSegmentWordMaps",
  "FirstSegmentStateCountsByWeight",
  "FirstSegmentMapCountsByWeight",
  "SecondSegmentKernels",
  "SecondSegmentKernelMatrices",
  "SecondSegmentKernelMethod",
  "TwoSegmentWordMaps",
  "TwoSegmentMapCountsByWeight",
  "Certificates",
  "MaximumWeight",
  "Demand",
  "Contract"
};

checks = Association@Table[
  field -> If[field === "Certificates",
    Module[{baseCertificates = Lookup[baseline, field, <||>],
      candidateCertificates = Lookup[candidate, field, <||>]},
      AssociationQ[baseCertificates] && AssociationQ[candidateCertificates] &&
      And @@ (TrueQ /@ Values[baseCertificates]) &&
      And @@ (TrueQ /@ Values[candidateCertificates])],
    SameQ[Lookup[baseline, field, Missing["Baseline"]],
      Lookup[candidate, field, Missing["Candidate"]]]],
  {field, fields}
];

result = <|
  "Status" -> If[And @@ Values[checks], "ExactSameQ", "Mismatch"],
  "Family" -> Lookup[baseline, "Family", Missing[]],
  "AllMathematicalFieldsSameQ" -> And @@ Values[checks],
  "Checks" -> checks,
  "BaselineFile" -> baselineFile,
  "CandidateFile" -> candidateFile,
  "BaselineSHA256" -> FileHash[baselineFile, "SHA256", "HexString"],
  "CandidateSHA256" -> FileHash[candidateFile, "SHA256", "HexString"]
|>;

temporary = outputFile <> ".partial-" <> ToString[$ProcessID];
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print[InputForm[result]];
If[! TrueQ[result["AllMathematicalFieldsSameQ"]], Exit[1]];
