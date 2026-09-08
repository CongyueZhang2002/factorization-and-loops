
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
table=Get[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","InputData","UU_08_10_canonical",
 "HardFunctionMasterCoefficientEpsilonValuations.wl"}]];
entries=table["Entries"];groups=GroupBy[entries,#["MasterIntegral"]["Family"]&];
deRoot=FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","UU_08_10_canonical","DifferentialEquationDataV2"}];
output=FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","RequestedMasterIntegralSolutions"}];
report=Import[FileNameJoin[{output,"report.wxf"}],"WXF"];
summaries=Values[report["Families"]];
measurements=<|"Date"->"2026-09-05",
 "Scope"->"Every currently regenerated V2 system; explicit demonstration master ranges, not final NNLO observable demands.",
 "Families"->(Join[KeyTake[#,{"Family","Status","ConstructionSeconds","MasterCount",
    "StoredMasterCoefficientCount","PreparedEvolutionOrderRange","IntegralDefinitionCount",
    "RequiredBoundaryCoefficientCount","CompressedBytes"}],
    <|"BasePoint"->(ToString[#,InputForm]& /@ #["BasePoint"]),
      "RequestedMasterIntegralRange"->First[Values[#["RequestedMasterIntegralOrderRanges"]]]|>]& /@ summaries),
 "TotalMasterPositions"->Total[Lookup[summaries,"MasterCount"]],
 "TotalMasterCoefficients"->Total[Lookup[summaries,"StoredMasterCoefficientCount"]],
 "TotalCompressedSolutionBytes"->Total[Lookup[summaries,"CompressedBytes"]],
 "TotalConstructionSeconds"->Total[Lookup[summaries,"ConstructionSeconds"]],
 "PreparationTimingScope"->"Includes automatic preparation for CF265 and CF259. CF269/CF48 use existing dlog forms; CF303 uses its saved finite-integration preparation. CF269 reuses its saved dimensional recurrence.",
 "StandaloneNumericalCheck"-><|"Family"->"CF269","Point"->{"13/50","17/50"},
   "QuadratureOrders"->{12,18},"WorkingPrecision"->50,
   "MaximumRelativeDifferenceWithAllStoredCSetToOne"->"1.6173782677395565e-38",
   "Scope"->"Convergence of the finite stored expressions; no boundary values or AMFlow comparison."|>|>;
inventory=<|"Date"->"2026-09-05","CoefficientTableEntryCount"->Length[entries],
 "NonzeroCoefficientEntryCount"->Count[Lookup[entries,"HardFunctionCoefficientEpsilonValuation"],_Integer],
 "CoefficientTableFamilyCount"->Length[groups],
 "RegeneratedDEFamilyCount"->Length[Select[Keys[groups],
   FileExistsQ[FileNameJoin[{deRoot,#,"FamilyDifferentialSystem.wl"}]]&]],
 "Families"->KeyValueMap[Function[{name,rows},<|"Family"->name,
   "CoefficientTableEntries"->Length[rows],
   "NonzeroCoefficientEntries"->Count[Lookup[rows,"HardFunctionCoefficientEpsilonValuation"],_Integer],
   "RegeneratedDifferentialSystemAvailable"->FileExistsQ[FileNameJoin[{deRoot,name,"FamilyDifferentialSystem.wl"}]],
   "DemonstrationFiniteSolutionAvailable"->FileExistsQ[FileNameJoin[{output,name,"solution.wxf"}]]|>],groups],
 "CoverageCaution"->"Solutions contain lower-sector master positions; their total is not a count of unique canonical observable masters. Demo epsilon ranges do not establish final observable coverage."|>;
Export[FileNameJoin[{root,"Design","FiniteMasterIntegralSolutions_sources","master_range_measurements.json"}],measurements,"RawJSON"];
Export[FileNameJoin[{root,"Design","FiniteMasterIntegralSolutions_sources","family_input_inventory.json"}],inventory,"RawJSON"];
Print[KeyDrop[measurements,{"Families","StandaloneNumericalCheck"}]];
Print[KeyDrop[inventory,"Families"]];

