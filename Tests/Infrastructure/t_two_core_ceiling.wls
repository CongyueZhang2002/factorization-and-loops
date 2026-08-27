root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

SetEnvironment[{
  "FACET_KERNEL_COUNT" -> "16",
  "FACET_CPU_LIST" -> "2-31"
}];
Global`$FACETKernelLimit = 32;

tests = <|
  "AutomaticKernelCeiling" ->
    FeynFacet`Private`facetKernelCount[Automatic, 100] === 8,
  "RequestedKernelCeiling" ->
    FeynFacet`Private`facetKernelCount[32, 100] === 8,
  "WorkloadCeiling" ->
    FeynFacet`Private`facetKernelCount[32, 1] === 1,
  "ExpandedCPUList" ->
    FeynFacet`Private`facetCPUList[] ===
      StringRiffle[ToString /@ Range[2, 17], ","]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
