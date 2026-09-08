$AllowInternet = False;
$HistoryLength = 0;
scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
artifact = Get[FileNameJoin[{scriptDirectory, "..", "Artifacts",
  "CF303OwnPhysicalSoftModes.wl"}]];
residue = Import[FileNameJoin[{scriptDirectory, "..", "Artifacts",
  "CF303SoftSourceResidueQ7.json"}], "RawJSON"];

checks = {};
check[name_, condition_] := AppendTo[checks, <|"Name" -> name,
  "Passed" -> TrueQ[condition]|>];

embedding = artifact["OwnModeEmbedding"];
dimensions = embedding["Dimensions"];
triples = embedding["SparseTriples"];
vOwn = SparseArray[(Most[#] -> Last[#]) & /@ triples, dimensions];
eigenvalues = embedding["NormalizedResidueEigenvalues"];
prime = residue["prime"];
rSource = SparseArray[
  ({#[[1]], #[[2]]} -> Mod[#[[3]], prime]) & /@ residue["entries"],
  residue["dimensions"]];
image = Mod[Normal[rSource . vOwn], prime];
expected = Mod[Normal[vOwn . DiagonalMatrix[eigenvalues]], prime];

check["accepted_status",
  artifact["Status"] === "CF303OwnCanonicalSoftModesAcceptedV2"];
check["source_dimensions", dimensions === {43, 4}];
check["accepted_source_coordinates",
  artifact["OwnSourceMap"]["AcceptedSourceCoordinates"] === {34, 35, 36, 37}];
check["state_rows",
  artifact["OwnSourceMap"]["CanonicalStateRows"] === {40, 41, 42, 43}];
check["original_master_order",
  artifact["OwnSourceMap"]["OriginalMasters"] === {3, 4, 1, 2}];
check["q7_eigenrelation", image === expected];
check["q7_image_nonzeros",
  (Count[#[[All]], value_ /; value =!= 0] & /@
    Table[image[[All, column]], {column, 4}]) === {0, 2, 0, 0}];
check["raw_transformation_valuations_rejected",
  ! KeyExistsQ[artifact["OwnSourceMap"], "PhysicalCanonicalLeadingMap"] &&
  ! KeyExistsQ[artifact, "PhysicalModeLeadingMap"] &&
  artifact["PhysicalRealization"]["RawTransformationValuationsAccepted"] ===
    False];
jetRecord = artifact["PhysicalRealization"][
  "Block23Lambda0JetReconciliation"];
check["frobenius_jet_cancels_false_pole",
  Cancel[Together[jetRecord["RawPhysicalRow4RhoMinus1"] +
    jetRecord["JetPhysicalRow4RhoMinus1"]]] === 0 &&
  Cancel[Together[jetRecord["PhysicalLeadingVector"][[2]]/
    jetRecord["PhysicalLeadingVector"][[1]] -
    jetRecord["PhysicalResidueEigenvectorRatio"]]] === 0 &&
  artifact["PhysicalRealization"]["SpectrumReconciliation"][
    "PhysicalOwn"] === {0, -2 - 4*eps, 0, 0}];
check["only_state_column41_enters_final_layer",
  artifact["FinalIncomingOwnSupport"]["StateColumns"] === {41} &&
  artifact["FinalIncomingOwnSupport"]["AcceptedSourceCoordinates"] === {35}];
baseResidue = artifact["FinalIncomingOwnSupport"]["BaseChannelResidue"];
targetExtension = artifact["FinalIncomingOwnSupport"][
  "NonzeroModeTargetExtension"]["Value"];
check["exact_nonzero_mode_target_extension",
  Cancel[Together[targetExtension - baseResidue/(2*eps)]] === 0 &&
  artifact["FinalIncomingOwnSupport"]["NonzeroModeTargetExtension"][
    "TargetRows"] === {44, 45}];

failures = Select[checks, ! TrueQ[#Passed] &];
Scan[Print[If[#Passed, "PASS ", "FAIL "], #Name] &, checks];
Print["SUMMARY passed=", Count[Lookup[checks, "Passed"], True],
  " failed=", Length[failures]];
Quit[If[failures === {}, 0, 1]];
