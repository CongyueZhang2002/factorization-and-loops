#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

driver = Import[FileNameJoin[{root, "Scripts",
  "family_epsform_sector.wls"}], "Text"];
recordValidator = Import[FileNameJoin[{root, "Scripts",
  "certify_family_epsform_record.wls"}], "Text"];
launchers = Import[#, "Text"] & /@ (FileNameJoin[{root, "Scripts", #}] & /@
  {"family_epsform_campaign.sh", "family_epsform_pool.sh",
   "complete_family_epsforms.sh", "tworoot_campaign.sh",
   "tworoot_parallel.sh"});

FTAssert["sector driver requires the four explicit V2 mathematical inputs",
  AllTrue[{"familyDifferentialSystemFile", "blockDecompositionFile",
      "coefficientPresentationFile", "diagonalBlockFormsDirectory"},
    StringContainsQ[driver, #] &] &&
    StringContainsQ[driver,
      "FamilyDifferentialSystemBlockDecompositionValidated"] &&
    StringContainsQ[driver,
      "FamilyDifferentialSystemBlockDecompositionQ"]];

FTAssert["sector driver refuses pre-V2 discovery and result-directory layouts",
  AllTrue[{"discoverFamilyDataDirectory", "BlockClasses",
      "block_class_assign.wl", "TransportFamilyCharts.wl", "ClassForms",
      "nnlo_de_"}, ! StringContainsQ[driver, #] &]];

FTAssert["sector result and construction state use V2 mathematical names",
  StringContainsQ[driver, "FamilyDLogEpsilonForm.wl"] &&
    StringContainsQ[driver, "FamilyDLogEpsilonFormConstructionState"] &&
    StringContainsQ[driver, "ConstructionInputReferences"]];

FTAssert["live family epsilon-form launchers contain no retired project layout",
  AllTrue[launchers, Function[text,
    AllTrue[{"ppHX_NNLO_DoubleReal", "UU_08_10_canonical",
        "FACET_FAMILY_DATA_DIRECTORY", "FACET_CLASS_FORM_DIRECTORY",
        "FACET_CHART_MANIFEST"}, ! StringContainsQ[text, #] &]]]];

FTAssert["campaign launchers pass a V2 input table",
  AllTrue[launchers, StringContainsQ[#, "v2-input-table.tsv"] &]];

FTAssert["sector driver defaults to finite-field Production checks",
  StringContainsQ[driver,
    "If[StringQ[value] && value === \"Development\", \"Development\", \"Production\"]"]];

FTAssert["standalone record validation uses the explicit V2 inputs only",
  StringContainsQ[recordValidator, "V2_SYSTEM"] &&
    StringContainsQ[recordValidator, "FamilyDifferentialSystem"] &&
    ! StringContainsQ[recordValidator, "TransportFamilyCharts"] &&
    ! StringContainsQ[recordValidator, "nnlo_de_"]];

FTReport[];
