(* Regenerate integration-test traces from retained mathematical inputs.
   Callers delete the guarded run workspace after their assertions. *)
Clear[prepareReconstructionTestTrace, removeReconstructionTestTrace];
prepareReconstructionTestTrace[resultDirectory_String] := Module[
  {kira, pairs, outcome, work, trace},
  kira = FileNameJoin[{resultDirectory, "KiraResult.wl"}];
  pairs = Sort@FileNames["F*_C*.wl", FileNameJoin[{resultDirectory, "Pairs"}]];
  If[! FileExistsQ[kira] || pairs === {}, Return[$Failed]];
  work = FeynFacet`Private`coefficientWorkDirectory[kira];
  If[! FeynFacet`Private`coefficientSafeWorkPathQ[work], Return[$Failed]];
  If[DirectoryQ[work],
    Print["Test workspace already exists; refusing to overwrite ", work];
    Return[$Failed]];
  outcome = FeynFacet`CoefficientSimplification[pairs, kira,
    "Threads" -> 8, "NormalizationKernels" -> 8, "KeepWorkingFiles" -> True];
  trace = FileNameJoin[{work, "FiniteField"}];
  If[! AssociationQ[outcome] || ! DirectoryQ[trace], Return[$Failed]];
  trace
];
removeReconstructionTestTrace[trace_String] := Module[{work = DirectoryName[trace]},
  If[FeynFacet`Private`coefficientSafeWorkPathQ[work] && DirectoryQ[work],
    DeleteDirectory[work, DeleteContents -> True]]
];
