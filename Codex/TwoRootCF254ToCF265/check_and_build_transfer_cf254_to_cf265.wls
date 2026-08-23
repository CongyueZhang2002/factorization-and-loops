#!/usr/bin/env wolframscript

ClearAll[
  exactZeroQ, exactMatrixZeroQ, exactMatrixEqualQ, masterIndices,
  mapPowers254To265, require, projectRoot, facetRoot, pairDirectory,
  deDirectory, chartDirectory, sourcePair, targetPair, sourceTopologyRecord,
  targetTopologyRecord, sourceTopology, targetTopology, sourceTopologyArgs,
  targetTopologyArgs, sourcePropagators, targetPropagators, sourceLoops,
  targetLoops, sourceExternal, targetExternal, sourceKinematics,
  targetKinematics, denominatorPositionMap, sourceCutIndices,
  targetCutIndices, sourceCutDirections, targetCutDirections,
  sourceCutMomenta, targetCutMomenta, sourceDE, targetDE, sourceBasis,
  targetBasis, sourceIndexVectors, targetIndexVectors, mappedIndexVectors,
  mappedTargetPositions, extraTargetPositions, selectionMatrix,
  injectionMatrix, sourceChartRecord, targetChartRecord, sourceChart,
  targetChart, checks, failedChecks, transferRecord, outputFile
];

exactZeroQ[expr_] := TrueQ[expr === 0] || TrueQ[Cancel[Together[expr]] === 0];

exactMatrixZeroQ[matrix_] := AllTrue[Flatten[matrix], exactZeroQ];

exactMatrixEqualQ[left_, right_] :=
  Dimensions[left] === Dimensions[right] &&
   AllTrue[MapThread[Subtract, {Flatten[left], Flatten[right]}], exactZeroQ];

masterIndices[master_] := Last[List @@ master];

mapPowers254To265[indices : {_, _, _, _, _, _, _, _, 0}] :=
  Join[indices[[1 ;; 7]], {0, indices[[8]]}];
mapPowers254To265[_] := $Failed;

require[name_String, value_] := If[
  TrueQ[value],
  True,
  Print["Exact check failed: ", name];
  False
];

projectRoot = ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]];
facetRoot = Replace[Environment["FACET_ROOT"], {
    value_String /; StringLength[value] > 0 :> value,
    _ -> "/home/maxzhang/FACET"
  }];

pairDirectory = FileNameJoin[{
   projectRoot, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
   "Pairs"
}];
deDirectory = FileNameJoin[{
   projectRoot, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
   "DifferentialEquations"
}];
chartDirectory = FileNameJoin[{
   facetRoot, "Codex", "General", "LibraTwoRoot_20260819"
}];

sourcePair = Get[FileNameJoin[{pairDirectory, "F19_C26.wl"}]];
targetPair = Get[FileNameJoin[{pairDirectory, "F19_C36.wl"}]];

sourceTopologyRecord = First[sourcePair["Topologies"]];
targetTopologyRecord = First[targetPair["Topologies"]];
sourceTopology = sourceTopologyRecord["Topology"];
targetTopology = targetTopologyRecord["Topology"];
sourceTopologyArgs = List @@ sourceTopology;
targetTopologyArgs = List @@ targetTopology;

sourcePropagators = sourceTopologyArgs[[2]];
targetPropagators = targetTopologyArgs[[2]];
sourceLoops = sourceTopologyArgs[[3]];
targetLoops = targetTopologyArgs[[3]];
sourceExternal = sourceTopologyArgs[[4]];
targetExternal = targetTopologyArgs[[4]];
sourceKinematics = sourceTopologyArgs[[5]];
targetKinematics = targetTopologyArgs[[5]];

denominatorPositionMap = <|
  1 -> 1, 2 -> 2, 3 -> 3, 4 -> 4, 5 -> 5, 6 -> 6, 7 -> 7, 8 -> 9
|>;
sourceCutIndices = sourceTopologyRecord["CutIndices"];
targetCutIndices = targetTopologyRecord["CutIndices"];
sourceCutDirections = sourceTopologyRecord["CutDirections"];
targetCutDirections = targetTopologyRecord["CutDirections"];
sourceCutMomenta = sourceTopologyRecord["CutMomenta"];
targetCutMomenta = targetTopologyRecord["CutMomenta"];

sourceDE = Get[FileNameJoin[{deDirectory, "nnlo_de_CF254.wl"}]];
targetDE = Get[FileNameJoin[{deDirectory, "nnlo_de_CF265.wl"}]];
sourceBasis = sourceDE["BlockBasis"];
targetBasis = targetDE["BlockBasis"];
sourceIndexVectors = masterIndices /@ sourceBasis;
targetIndexVectors = masterIndices /@ targetBasis;
mappedIndexVectors = mapPowers254To265 /@ sourceIndexVectors;
mappedTargetPositions = FirstPosition[targetIndexVectors, #, Missing["Absent"]] & /@
  mappedIndexVectors;
mappedTargetPositions = Replace[mappedTargetPositions, {position_List :> First[position]}, {1}];
extraTargetPositions = Complement[Range[Length[targetBasis]], mappedTargetPositions];

selectionMatrix = SparseArray[
  Thread[Transpose[{Range[Length[sourceBasis]], mappedTargetPositions}] -> 1],
  {Length[sourceBasis], Length[targetBasis]}
];
injectionMatrix = Transpose[selectionMatrix];

sourceChartRecord = Get[FileNameJoin[{chartDirectory, "family_epsform_CF254.wl"}]];
targetChartRecord = Get[FileNameJoin[{chartDirectory, "family_epsform_CF265.wl"}]];
sourceChart = sourceChartRecord["Chart"];
targetChart = targetChartRecord["Chart"];

checks = <|
  "LoopMomentaIdentity" -> SameQ[sourceLoops, targetLoops],
  "ExternalMomentaIdentity" -> SameQ[sourceExternal, targetExternal],
  "KinematicRulesIdentity" -> SameQ[sourceKinematics, targetKinematics],
  "FirstSevenDenominatorsIdentity" ->
    SameQ[sourcePropagators[[1 ;; 7]], targetPropagators[[1 ;; 7]]],
  "SourceCutDenominatorEqualsTargetNinth" ->
    SameQ[sourcePropagators[[8]], targetPropagators[[9]]],
  "SourceAuxiliaryAbsentFromMasterBasis" ->
    AllTrue[sourceIndexVectors, Last[#] === 0 &],
  "MappedMasterVectorsFoundExactlyOnce" ->
    FreeQ[mappedTargetPositions, _Missing] &&
     DuplicateFreeQ[mappedTargetPositions] &&
     Length[mappedTargetPositions] === Length[sourceBasis],
  "CutIndexMap" ->
    Lookup[denominatorPositionMap, sourceCutIndices] === targetCutIndices,
  "CutMomentumIdentity" -> SameQ[sourceCutMomenta, targetCutMomenta],
  "CutOrientationIdentity" -> SameQ[sourceCutDirections, targetCutDirections],
  "FamilyNormalizationIdentity" -> SameQ[
    sourceTopologyRecord["FamilyCoefficient"],
    targetTopologyRecord["FamilyCoefficient"]
  ],
  "AvMappedBlockIdentity" -> exactMatrixEqualQ[
    sourceDE["Av"], targetDE["Av"][[mappedTargetPositions, mappedTargetPositions]]
  ],
  "AwMappedBlockIdentity" -> exactMatrixEqualQ[
    sourceDE["Aw"], targetDE["Aw"][[mappedTargetPositions, mappedTargetPositions]]
  ],
  "AvMappedRowsClosed" -> exactMatrixZeroQ[
    targetDE["Av"][[mappedTargetPositions, extraTargetPositions]]
  ],
  "AwMappedRowsClosed" -> exactMatrixZeroQ[
    targetDE["Aw"][[mappedTargetPositions, extraTargetPositions]]
  ],
  "ChartNameIdentity" -> SameQ[sourceChart["Name"], targetChart["Name"]],
  "ChartVariablesIdentity" -> SameQ[
    sourceChart["Variables"], targetChart["Variables"]
  ],
  "ChartSourceVariablesIdentity" -> SameQ[
    sourceChart["SourceVariables"], targetChart["SourceVariables"]
  ],
  "ChartSubstitutionIdentity" -> SameQ[sourceChart["Subst"], targetChart["Subst"]],
  "ChartJacobianIdentity" -> SameQ[
    sourceChart["Jacobian"], targetChart["Jacobian"]
  ],
  "ChartRootIdentity" -> SameQ[sourceChart["Roots"], targetChart["Roots"]],
  "ChartRootsVerified" ->
    TrueQ[sourceChart["RootSquareConsistent"]] &&
     TrueQ[targetChart["RootSquareConsistent"]]
|>;

failedChecks = Keys[Select[checks, Not@*TrueQ]];
If[failedChecks =!= {},
  Print["CF254 -> CF265 transfer was not written."];
  Print["Failed exact checks: ", failedChecks];
  Exit[1]
];

transferRecord = <|
  "Type" -> "ExactPoweredIntegralSubsectorEmbedding",
  "SourceFamily" -> "CF254",
  "TargetFamily" -> "CF265",
  "Scope" -> "23-dimensional E8^0 subsector of the 32-master CF265 family",
  "LoopMomentumRules" -> {ke -> ke, kf -> kf},
  "PhysicalKinematicRules" -> {v -> v, w -> w},
  "ChartVariableRules" -> {y -> y, s -> s},
  "SourceCutIndices" -> sourceCutIndices,
  "TargetCutIndices" -> targetCutIndices,
  "CutMomenta" -> sourceCutMomenta,
  "CutDirections" -> sourceCutDirections,
  "SourcePowerPattern" -> {a1, a2, a3, a4, a5, a6, a7, a8, 0},
  "TargetPowerPattern" -> {a1, a2, a3, a4, a5, a6, a7, 0, a8},
  "ExactIdentity" -> HoldForm[
    ICF254[{a1, a2, a3, a4, a5, a6, a7, a8, 0}, v, w, eps] ==
     ICF265[{a1, a2, a3, a4, a5, a6, a7, 0, a8}, v, w, eps]
  ],
  "SourceBasis" -> sourceBasis,
  "MappedTargetBasis" -> targetBasis[[mappedTargetPositions]],
  "SourceToTargetMasterRules" -> Thread[
    sourceBasis -> targetBasis[[mappedTargetPositions]]
  ],
  "SourceToTargetPositions" -> mappedTargetPositions,
  "ComplementaryTargetPositions" -> extraTargetPositions,
  "SelectionMatrix" -> selectionMatrix,
  "InjectionMatrix" -> injectionMatrix,
  "DifferentialIdentity" -> HoldForm[
    selectionMatrix . ACF265[x] == ACF254[x] . selectionMatrix
  ],
  "Chart" -> KeyTake[sourceChart, {
    "Name", "Variables", "SourceVariables", "Subst", "Jacobian",
    "JacobianDet", "Roots"
  }],
  "ExactChecks" -> checks,
  "Limitation" ->
    "The transfer does not determine CF265 masters with nonzero eighth power."
|>;

outputFile = FileNameJoin[{DirectoryName[$InputFileName], "CF254ToCF265Transfer.wl"}];
Put[transferRecord, outputFile];

Print["Exact CF254 -> CF265 subsector identity verified."];
Print["Mapped CF265 positions: ", mappedTargetPositions];
Print["Additional CF265 positions: ", extraTargetPositions];
Print["Transfer record: ", outputFile];
