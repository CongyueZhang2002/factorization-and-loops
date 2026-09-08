root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

checks = <|
  "FeynFacetContext" -> MemberQ[$Packages, "FeynFacet`"],
  "CollinearFactorize" ->
    Length[DownValues[FeynFacet`CollinearFactorize]] > 0,
  "CollinearFactorizePreIBP" ->
    Length[DownValues[FeynFacet`CollinearFactorizePreIBP]] > 0,
  "AMFlowPrescription" ->
    Length[DownValues[FeynFacet`AMFlowPrescription]] > 0,
  "PartialFraction" -> Length[DownValues[FeynFacet`PartialFraction]] > 0,
  "TopologyEquivalence" ->
    Length[DownValues[FeynFacet`TopologyEquivalence]] > 0,
  "GenerateDiagram" -> Length[DownValues[FeynFacet`GenerateDiagram]] > 0,
  "DimensionalShift" ->
    Length[DownValues[FeynFacet`DimensionalShift]] > 0,
  "FeynCalcContext" -> MemberQ[$Packages, "FeynCalc`"],
  "FeynCalcLegacyCalc" -> Length[DownValues[FeynCalc`Calc]] > 0,
  "KiraExecutable" -> FileExistsQ[$FACETKiraExecutable]
|>;

Print[checks];

If[! And @@ Values[checks], Exit[1]];
Exit[0];
