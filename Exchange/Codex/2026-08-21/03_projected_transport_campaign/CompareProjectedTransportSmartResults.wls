#!/usr/bin/env wolframscript

(* Exact regression comparison for the smart observable cutoff.  The number
   of unprojected forward states is deliberately excluded: after an exact
   P.Q_w==0 certificate those states are neither mathematical output nor
   constructed by the candidate.  Every demanded word map, induced kernel,
   two-segment map, and physical contract remains an exact SameQ check. *)

$HistoryLength = 0;

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["Usage: CompareProjectedTransportSmartResults.wls " <>
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
  "FirstSegmentMapCountsByWeight",
  "SecondSegmentKernels",
  "SecondSegmentKernelMatrices",
  "SecondSegmentKernelMethod",
  "TwoSegmentWordMaps",
  "TwoSegmentMapCountsByWeight",
  "MaximumWeight",
  "Demand",
  "Contract"
};

(* The first-path parameter is intentionally Unique[] inside the engine, so
   serialized runs may call the same dummy variable observablePath24 or
   observablePath25.  Alpha-normalize that dummy before SameQ. *)
canonicalizePathDummy[expression_] := expression /.
  symbol_Symbol /;
      StringStartsQ[SymbolName[Unevaluated[symbol]], "observablePath"] :>
    codexCanonicalObservablePath;

fieldChecks = Association@Table[
  field -> If[field === "FirstSegmentKernels",
    SameQ[
      canonicalizePathDummy[Lookup[baseline, field, Missing["Baseline"]]],
      canonicalizePathDummy[Lookup[candidate, field, Missing["Candidate"]]]],
    SameQ[Lookup[baseline, field, Missing["Baseline"]],
      Lookup[candidate, field, Missing["Candidate"]]]],
  {field, fields}
];

baselineCertificates = Lookup[baseline, "Certificates", <||>];
candidateCertificates = Lookup[candidate, "Certificates", <||>];
reachability = Lookup[candidate, "ObservableReachabilityCertificate", <||>];
requestedWeight = Lookup[candidate, "MaximumWeight", Missing[]];
observableWeight = Lookup[candidate,
  "ObservableMaximumFirstSegmentWeight", Missing[]];

certificateChecks = <|
  "BaselineCertificatesTrue" ->
    AssociationQ[baselineCertificates] &&
      And @@ (TrueQ /@ Values[baselineCertificates]),
  "CandidateCertificatesTrue" ->
    AssociationQ[candidateCertificates] &&
      And @@ (TrueQ /@ Values[candidateCertificates]),
  "ReachabilityStatusExact" ->
    AssociationQ[reachability] &&
      Lookup[reachability, "Status", None] === "Exact",
  "ReachableSpanIdentities" ->
    AssociationQ[reachability] &&
      And @@ (TrueQ /@ Lookup[reachability, "SpanIdentities", {False}]),
  "ObservableCutoffIdentity" ->
    AssociationQ[reachability] &&
      TrueQ[Lookup[reachability, "CutoffIdentity", False]],
  "CertificateCoversRequestedWeights" ->
    IntegerQ[requestedWeight] && AssociationQ[reachability] &&
      Length[Lookup[reachability, "DemandedMapIsZero", {}]] ===
        requestedWeight + 1,
  "NoFirstWordBeyondCutoff" ->
    IntegerQ[observableWeight] &&
      AllTrue[Lookup[candidate, "FirstSegmentWordMaps", {}],
        Length[First[#]] <= observableWeight &]
|>;

allSame = And @@ Join[Values[fieldChecks], Values[certificateChecks]];
result = <|
  "Status" -> If[allSame, "ExactSameQ", "Mismatch"],
  "Family" -> Lookup[baseline, "Family", Missing[]],
  "AllDemandedMathematicalFieldsSameQ" -> And @@ Values[fieldChecks],
  "AllSmartCertificatesTrue" -> And @@ Values[certificateChecks],
  "Checks" -> fieldChecks,
  "CertificateChecks" -> certificateChecks,
  "BaselineUnprojectedStateCounts" ->
    Lookup[baseline, "FirstSegmentStateCountsByWeight", Missing[]],
  "CandidateConstructedStateCounts" ->
    Lookup[candidate, "FirstSegmentStateCountsByWeight", Missing[]],
  "BaselineFile" -> baselineFile,
  "CandidateFile" -> candidateFile,
  "BaselineSHA256" -> FileHash[baselineFile, "SHA256", "HexString"],
  "CandidateSHA256" -> FileHash[candidateFile, "SHA256", "HexString"]
|>;

temporary = outputFile <> ".partial-" <> ToString[$ProcessID];
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print[InputForm[result]];
If[! allSame, Exit[1]];
