#!/usr/bin/env wolframscript

(* Exact powered-integral and differential-system relation CF254 -> CF305. *)

$HistoryLength = 0;

ClearAll[
  exactZeroQ, exactMatrixEqualQ, masterIndices, mapIndices254To305,
  normalizeSymbols, readExpression, square, bilinear, gaugeConjugate,
  x13, x23, k13, k23, root13, root23, chartForward, chartInverse,
  projectRoot, pairDirectory, deDirectory, sourcePairFile, targetPairFile,
  sourceDEFile, targetDEFile, outputFile, temporaryOutputFile
];

exactZeroQ[expression_] := AllTrue[
  Flatten[{expression}],
  TrueQ[# === 0] || TrueQ[Cancel[Together[#]] === 0] &
];

exactMatrixEqualQ[left_, right_] :=
  Dimensions[left] === Dimensions[right] && exactZeroQ[left - right];

masterIndices[master_] := Last[List @@ master];

mapIndices254To305[
  {a1_, a2_, a3_, a4_, a5_, a6_, a7_, a8_, 0}
] := {a1, a2, a6, a7, a3, 0, a4, a5, a8};
mapIndices254To305[_] := $Failed;

projectRoot = ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]];
pairDirectory = FileNameJoin[{
  projectRoot, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "Pairs"
}];
deDirectory = FileNameJoin[{
  projectRoot, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "DifferentialEquations"
}];
sourcePairFile = FileNameJoin[{pairDirectory, "F19_C26.wl"}];
targetPairFile = FileNameJoin[{pairDirectory, "F21_C35.wl"}];
sourceDEFile = FileNameJoin[{deDirectory, "nnlo_de_CF254.wl"}];
targetDEFile = FileNameJoin[{deDirectory, "nnlo_de_CF305.wl"}];
outputFile = FileNameJoin[{DirectoryName[$InputFileName],
  "CF254ToCF305Transfer.wl"}];
temporaryOutputFile = outputFile <> ".tmp";

If[FileExistsQ[outputFile], DeleteFile[outputFile]];
If[FileExistsQ[temporaryOutputFile], DeleteFile[temporaryOutputFile]];

requiredFiles = {sourcePairFile, targetPairFile, sourceDEFile, targetDEFile};
If[! AllTrue[requiredFiles, FileExistsQ],
  Print["Required input files are absent: ", Select[requiredFiles, ! FileExistsQ[#] &]];
  Exit[2]
];

(* Read pair records without loading a package or starting a FrontEnd. *)
sourcePair = Get[sourcePairFile];
targetPair = Get[targetPairFile];
sourceTopologyRecord = First[sourcePair["Topologies"]];
targetTopologyRecord = First[targetPair["Topologies"]];
sourceTopology = sourceTopologyRecord["Topology"];
targetTopology = targetTopologyRecord["Topology"];
sourceTopologyArguments = List @@ sourceTopology;
targetTopologyArguments = List @@ targetTopology;
sourcePropagatorRecords = sourceTopologyArguments[[2]];
targetPropagatorRecords = targetTopologyArguments[[2]];

(* Isolate DE contexts, then identify only the physical DE symbols. *)
ClearAll[Global`eps, Global`v, Global`w];
deSymbols = AssociationMap[Symbol["Global`" <> #] &, {"eps", "v", "w"}];
normalizeSymbols[expression_] := Module[{symbols, rules},
  symbols = DeleteDuplicates@Cases[
    expression,
    symbol_Symbol /; KeyExistsQ[deSymbols, SymbolName[symbol]],
    {0, Infinity}, Heads -> True
  ];
  rules = Thread[symbols -> Lookup[deSymbols, SymbolName /@ symbols]];
  expression /. rules
];
readExpression[file_String, context_String] := normalizeSymbols@Block[
  {$Context = context, $ContextPath = {context, "System`"}},
  Get[file]
];

sourceDE = readExpression[sourceDEFile, "CF254TransferSourceDE`"];
targetDE = readExpression[targetDEFile, "CF254TransferTargetDE`"];
eps = deSymbols["eps"];
v = deSymbols["v"];
w = deSymbols["w"];

sourceBasis = sourceDE["BlockBasis"];
targetBasis = targetDE["BlockBasis"];
sourceIndexVectors = masterIndices /@ sourceBasis;
targetIndexVectors = masterIndices /@ targetBasis;
mappedIndexVectors = mapIndices254To305 /@ sourceIndexVectors;
mappedTargetPositions = Replace[
  FirstPosition[targetIndexVectors, #, Missing["Absent"]] & /@
    mappedIndexVectors,
  position : {_Integer} :> First[position],
  {1}
];

mappingStructureValid =
  Length[sourceBasis] === 23 && Length[targetBasis] === 32 &&
  FreeQ[mappedIndexVectors, $Failed] &&
  FreeQ[mappedTargetPositions, _Missing] &&
  DuplicateFreeQ[mappedTargetPositions] &&
  Length[mappedTargetPositions] === Length[sourceBasis];

If[! mappingStructureValid,
  Print["Master-map construction failed: ", mappedTargetPositions];
  Exit[3]
];

complementaryTargetPositions = Complement[
  Range[Length[targetBasis]], mappedTargetPositions
];
selectionMatrix = SparseArray[
  Thread[Transpose[{Range[Length[sourceBasis]], mappedTargetPositions}] -> 1],
  {Length[sourceBasis], Length[targetBasis]}
];
injectionMatrix = Transpose[selectionMatrix];

(* Generic scalar-product ring in the order {ka,kb,kc,ke,kf}. *)
p1 = Symbol["Global`ffecfp1"];
p2 = Symbol["Global`ffecfp2"];
p3 = Symbol["Global`ffecfp3"];
kae = Symbol["Global`kae"]; kaf = Symbol["Global`kaf"];
kbe = Symbol["Global`kbe"]; kbf = Symbol["Global`kbf"];
kce = Symbol["Global`kce"]; kcf = Symbol["Global`kcf"];
kee = Symbol["Global`kee"]; kef = Symbol["Global`kef"];
kff = Symbol["Global`kff"];
gram = {
  {0, p1/2, p2/2, kae, kaf},
  {p1/2, 0, p3/2, kbe, kbf},
  {p2/2, p3/2, 0, kce, kcf},
  {kae, kbe, kce, kee, kef},
  {kaf, kbf, kcf, kef, kff}
};
kaVector = {1, 0, 0, 0, 0};
kbVector = {0, 1, 0, 0, 0};
kcVector = {0, 0, 1, 0, 0};
keVector = {0, 0, 0, 1, 0};
kfVector = {0, 0, 0, 0, 1};
square[momentum_] := Expand[momentum . gram . momentum];
bilinear[left_, right_] := Expand[left . gram . right];

(* Unique signed-ray crossing that preserves ka+kb-kc and all three cuts. *)
sourceKa = -kcVector;
sourceKb = kbVector;
sourceKc = -kaVector;
sourceKe = keVector;
sourceKf = kfVector;
targetKa = kaVector;
targetKb = kbVector;
targetKc = kcVector;
targetKe = keVector;
targetKf = kfVector;

sourceMomenta = {
  sourceKf,
  sourceKe,
  -sourceKa + sourceKe,
  -sourceKa + sourceKe + sourceKf,
  -sourceKa + sourceKc + sourceKe + sourceKf,
  -sourceKc - sourceKf,
  sourceKa - sourceKc - sourceKf,
  sourceKa + sourceKb - sourceKc - sourceKe - sourceKf
};
targetMomenta = {
  targetKf,
  targetKe,
  -targetKa + targetKf,
  -targetKa + targetKc + targetKf,
  -targetKc - targetKe,
  -targetKa - targetKb + targetKc + targetKf,
  -targetKc - targetKe - targetKf,
  targetKa - targetKc - targetKe - targetKf,
  targetKa + targetKb - targetKc - targetKe - targetKf
};
denominatorImage = {1, 2, 5, 7, 8, 3, 4, 9};
denominatorMomentumSigns = {1, 1, -1, -1, -1, -1, -1, 1};
sourceDenominators = square /@ sourceMomenta;
targetDenominators = square /@ targetMomenta;
sourceISP = bilinear[sourceKb, sourceKe];

momentumIdentity = exactZeroQ[
  sourceMomenta -
    denominatorMomentumSigns targetMomenta[[denominatorImage]]
];
denominatorIdentity = exactZeroQ[
  sourceDenominators - targetDenominators[[denominatorImage]]
];
ispIdentity = exactZeroQ[
  2 sourceISP -
    (targetDenominators[[6]] - targetDenominators[[4]] +
      targetDenominators[[8]] - targetDenominators[[9]])
];

sourceCutIndices = sourceTopologyRecord["CutIndices"];
targetCutIndices = targetTopologyRecord["CutIndices"];
sourceCutDirections = sourceTopologyRecord["CutDirections"];
targetCutDirections = targetTopologyRecord["CutDirections"];
sourceCutMomenta = sourceTopologyRecord["CutMomenta"];
targetCutMomenta = targetTopologyRecord["CutMomenta"];
sourceCutMomentaCrossed = sourceCutMomenta /.
  {ka -> crossedKa, kc -> crossedKc} /.
  {crossedKa -> -kc, crossedKc -> -ka};

sourceCausalTags = Cases[#, tag : {_Integer, _Integer} :> tag,
    {0, Infinity}] & /@ sourcePropagatorRecords;
targetCausalTags = Cases[#, tag : {_Integer, _Integer} :> tag,
    {0, Infinity}] & /@ targetPropagatorRecords;

(* Normalized invariant map and the two-root chart lift. *)
sourceInvariantScale = -p3;
sourceNormalizedInvariants = {-p2/p3, p1/p3};
physicalVariableRules = {v254 -> -v/w, w254 -> 1/w};

lambda1[x_, y_] := (1 - x - y)^2 - 4 x y;
lambda2[x_, y_] := lambda1[-x, y];
lambda3[x_, y_] := lambda1[x, -y];

x13[y_, s_] := (1 + s) (-3 + s + 2 y)/(-1 + s^2 + 4 y - 4 y^2);
x23[y_, s_] := (-3 + s) (1 + s - 2 y)/(-1 + s^2);
k13[y_, s_] := Together /@ {x13[y, s] y, (1 - x13[y, s]) (1 - y)};
k23[y_, s_] := Together /@ {-x23[y, s] y, (1 - x23[y, s]) (1 - y)};
root13[y_, s_] := Together /@ {
  x13[y, s] - y,
  (1 - y) + s (x13[y, s] - 1)
};
root23[y_, s_] := Together /@ {
  x23[y, s] - y,
  (1 + y) + s (x23[y, s] - 1)
};
chartForward[y_, s_] := Together /@ {
  y/(y - 1),
  -(s y + s - 5 y + 3)/(s y - s - y + 1)
};
chartInverse[Y_, S_] := Together /@ {
  Y/(Y - 1),
  (S + 2 Y + 3)/(S + 2 Y - 1)
};

{sourceChartY, sourceChartS} = chartForward[y, s];
sourceChartAtTarget = k13[sourceChartY, sourceChartS];
targetChart = k23[y, s];
sourceRootsAtTarget = root13[sourceChartY, sourceChartS];
targetRoots = root23[y, s];
chartJacobian = Together@Det[
  Outer[D, chartForward[y, s], {y, s}]
];

(* Pull back the CF254 connection and apply the homogeneity gauge. *)
sourcePowers = Total /@ sourceIndexVectors;
dimension = 4 - 2 eps;
sourceAvPulled = Map[
  Cancel[Together[# /. {v -> -v/w, w -> 1/w}]] &,
  sourceDE["Av"], {2}
];
sourceAwPulled = Map[
  Cancel[Together[# /. {v -> -v/w, w -> 1/w}]] &,
  sourceDE["Aw"], {2}
];
gaugeConjugate[matrix_] := Table[
  Cancel[Together[
    (-w)^(sourcePowers[[column]] - sourcePowers[[row]]) matrix[[row, column]]
  ]],
  {row, Length[sourceBasis]}, {column, Length[sourceBasis]}
];
predictedAv = gaugeConjugate[(-1/w) sourceAvPulled];
predictedAw = DiagonalMatrix[(dimension - sourcePowers)/w] +
  gaugeConjugate[(v/w^2) sourceAvPulled - (1/w^2) sourceAwPulled];

targetSelectedAv = targetDE["Av"][[mappedTargetPositions, mappedTargetPositions]];
targetSelectedAw = targetDE["Aw"][[mappedTargetPositions, mappedTargetPositions]];
targetClosureAv = targetDE["Av"][[
  mappedTargetPositions, complementaryTargetPositions
]];
targetClosureAw = targetDE["Aw"][[
  mappedTargetPositions, complementaryTargetPositions
]];

sourceContext = sourcePair["AnalyticContext"];
targetContext = targetPair["AnalyticContext"];
contextKeys = {
  "Gamma5Scheme", "LoopDimension", "DimensionRule", "CutConvention",
  "DistributionConvention"
};

checks = <|
  "FamilyLabels" -> SameQ[sourceDE["Family"], "CF254"] &&
    SameQ[targetDE["Family"], "CF305"],
  "BasisDimensions23And32" ->
    Length[sourceBasis] === 23 && Length[targetBasis] === 32,
  "AllCF254MastersHaveZeroISPPower" ->
    AllTrue[sourceIndexVectors, Last[#] === 0 &],
  "MappedMasterVectorsFoundExactlyOnce" -> mappingStructureValid,
  "MappedTargetPositions" -> SameQ[
    mappedTargetPositions,
    {32, 6, 10, 28, 7, 11, 12, 21, 22, 23, 29, 30,
      13, 31, 15, 16, 25, 17, 18, 26, 19, 27, 20}
  ],
  "ComplementIsExactlyD6Positive" -> AllTrue[
    targetIndexVectors[[complementaryTargetPositions]], #[[6]] > 0 &
  ],
  "SelectedSectorIsExactlyD6Zero" -> AllTrue[
    targetIndexVectors[[mappedTargetPositions]], #[[6]] === 0 &
  ],
  "LoopJacobianOne" -> True,
  "MomentumMapWithSigns" -> momentumIdentity,
  "QuadraticDenominatorIdentity" -> denominatorIdentity,
  "SourceISPLinearIdentity" -> ispIdentity,
  "CutIndexImage" -> SameQ[
    sourceCutIndices /. Thread[Range[8] -> denominatorImage],
    targetCutIndices
  ],
  "CutMomentumIdentityAfterCrossing" ->
    SameQ[sourceCutMomentaCrossed, targetCutMomenta],
  "CutDirectionsPositiveAndUnchanged" ->
    SameQ[sourceCutDirections, targetCutDirections, {1, 1, 1}],
  "CutMomentumSignsPositive" ->
    SameQ[denominatorMomentumSigns[[sourceCutIndices]], {1, 1, 1}],
  "FamilyNormalizationIdentity" -> SameQ[
    sourceTopologyRecord["FamilyCoefficient"],
    targetTopologyRecord["FamilyCoefficient"]
  ],
  "PhaseSpaceMeasureIdentity" -> SameQ[
    sourcePair["PhaseSpace"], targetPair["PhaseSpace"]
  ],
  "MappedOrdinaryCausalTagsIdentity" -> SameQ[
    sourceCausalTags[[1 ;; 8]],
    targetCausalTags[[denominatorImage]]
  ],
  "MappedOrdinaryCausalTagsAreFeynman" ->
    AllTrue[sourceCausalTags[[1 ;; 8]], SameQ[#, {{1, 1}}] &] &&
    AllTrue[targetCausalTags, SameQ[#, {{1, 1}}] &],
  "AnalyticContextIdentity" -> SameQ[
    KeyTake[sourceContext, contextKeys],
    KeyTake[targetContext, contextKeys]
  ],
  "InvariantCrossing" -> exactZeroQ[
    sourceNormalizedInvariants /. {p1 -> 1, p2 -> v, p3 -> w} -
      {-v/w, 1/w}
  ],
  "KallenRootSquareCrossing" -> exactZeroQ[{
    lambda1[-v/w, 1/w] - lambda2[v, w]/w^2,
    lambda3[-v/w, 1/w] - lambda3[v, w]/w^2
  }],
  "ChartPhysicalVariableMap" -> exactZeroQ[
    sourceChartAtTarget - {-targetChart[[1]]/targetChart[[2]],
      1/targetChart[[2]]}
  ],
  "ChartForwardInverse" -> exactZeroQ[
    With[{mapped = chartForward[y, s]},
      chartInverse[mapped[[1]], mapped[[2]]] - {y, s}
    ]
  ],
  "ChartInverseForward" -> Module[{Y, S}, exactZeroQ[
    With[{mapped = chartInverse[Y, S]},
      chartForward[mapped[[1]], mapped[[2]]] - {Y, S}
    ]
  ]],
  "ChartJacobianNonzero" -> ! exactZeroQ[chartJacobian],
  "KallenRootBranches" -> exactZeroQ[{
    sourceRootsAtTarget[[1]] + targetRoots[[1]]/targetChart[[2]],
    sourceRootsAtTarget[[2]] - targetRoots[[2]]/targetChart[[2]]
  }],
  "SourceFlatnessRecorded" -> TrueQ[sourceDE["FlatnessZero"]],
  "TargetFlatnessRecorded" -> TrueQ[targetDE["FlatnessZero"]],
  "AvSelectedBlockIdentity" -> exactMatrixEqualQ[
    targetSelectedAv, predictedAv
  ],
  "AwSelectedBlockIdentity" -> exactMatrixEqualQ[
    targetSelectedAw, predictedAw
  ],
  "AvSelectedRowsClosed" -> exactZeroQ[targetClosureAv],
  "AwSelectedRowsClosed" -> exactZeroQ[targetClosureAw],
  "AvFullIntertwiner" -> exactMatrixEqualQ[
    selectionMatrix . targetDE["Av"], predictedAv . selectionMatrix
  ],
  "AwFullIntertwiner" -> exactMatrixEqualQ[
    selectionMatrix . targetDE["Aw"], predictedAw . selectionMatrix
  ]
|>;

Print[
  "Acceptance criterion: every named metadata equality is True and every " <>
  "denominator, chart, closure, and differential residual vanishes exactly."
];
failedChecks = Keys@Select[checks, ! TrueQ[#] &];
If[failedChecks =!= {},
  Print["Acceptance criterion not satisfied. Failed checks: ", failedChecks];
  Exit[1]
];

transferRecord = <|
  "Format" -> "FeynFacetExactFamilyTransfer",
  "FormatVersion" -> 1,
  "Type" -> "ExactPoweredIntegralClosedSubsectorEmbedding",
  "SourceFamily" -> "CF254",
  "TargetFamily" -> "CF305",
  "Classification" ->
    "The complete 23-master CF254 system embeds in the closed D6=0 " <>
    "subsector of the 32-master CF305 system. The two complete powered " <>
    "families are not equivalent for arbitrary CF254 ISP power.",
  "TargetPhysicalRegion" -> HoldForm[
    0 < v < 1 && 0 < w < 1 && v + w < 1
  ],
  "DimensionfulExternalRules" -> HoldForm[{
    ka254 -> -kc305, kb254 -> kb305, kc254 -> -ka305
  }],
  "LoopMomentumRules" -> HoldForm[{ke254 -> ke305, kf254 -> kf305}],
  "LoopJacobian" -> 1,
  "LoopMeasure" -> targetPair["PhaseSpace"],
  "DenominatorImage" -> Thread[Range[8] -> denominatorImage],
  "DenominatorMomentumSigns" -> denominatorMomentumSigns,
  "SourceISPIdentity" -> HoldForm[
    2 D254[9] == D305[6] - D305[4] + D305[8] - D305[9]
  ],
  "TargetAdditionalDenominator" -> 6,
  "PoweredCondition" -> HoldForm[a9 == 0],
  "PoweredIndexMap" -> HoldForm[
    {a1, a2, a3, a4, a5, a6, a7, a8, 0} ->
      {a1, a2, a6, a7, a3, 0, a4, a5, a8}
  ],
  "DimensionfulPoweredIntegralIdentity" -> HoldForm[
    ICF254[
      {a1, a2, a3, a4, a5, a6, a7, a8, 0},
      {-kc, kb, -ka}, {ke, kf}, D, FeynmanPlusI0, DeltaPlus
    ] == ICF305[
      {a1, a2, a6, a7, a3, 0, a4, a5, a8},
      {ka, kb, kc}, {ke, kf}, D, FeynmanPlusI0, DeltaPlus
    ]
  ],
  "SourceCutIndices" -> sourceCutIndices,
  "TargetCutIndices" -> targetCutIndices,
  "CutIndexMap" -> (sourceCutIndices -> targetCutIndices),
  "CutMomenta" -> targetCutMomenta,
  "CutDirections" -> targetCutDirections,
  "CutConvention" -> targetContext["CutConvention"],
  "OrdinaryCausalTag" -> {1, 1},
  "Gamma5Scheme" -> targetContext["Gamma5Scheme"],
  "DimensionRule" -> targetContext["DimensionRule"],
  "NormalizedPhysicalVariableMap" -> HoldForm[{
    v254 -> -v305/w305, w254 -> 1/w305
  }],
  "CrossedSourceRegion" -> HoldForm[v254 < 0 && w254 > 1],
  "ScaleRatio" -> HoldForm[S254/S305 == -w305],
  "NormalizedScaleGauge" -> HoldForm[
    Hii == Exp[(4 - 2 eps - Ai) CrossedFeynmanLog[-w305]]
  ],
  "ScaleBranch" ->
    "CrossedFeynmanLog is the boundary value inherited from the displayed " <>
    "dimensionful identity with unchanged +i0 tags. It is retained " <>
    "unevaluated; the rational DE identity uses only d Log(-w)=dw/w.",
  "SourceChart" -> "Kallen13",
  "TargetChart" -> "Kallen23",
  "ChartMapTargetToSource" -> HoldForm[{
    y254 -> y305/(y305 - 1),
    s254 -> -(s305 y305 + s305 - 5 y305 + 3)/
      (s305 y305 - s305 - y305 + 1)
  }],
  "ChartMapSourceToTarget" -> HoldForm[{
    y305 -> y254/(y254 - 1),
    s305 -> (s254 + 2 y254 + 3)/(s254 + 2 y254 - 1)
  }],
  "KallenRootBranchRules" -> HoldForm[{
    r1CF254 -> -r2CF305/w305,
    r3CF254 -> r3CF305/w305
  }],
  "SourceBasis" -> sourceBasis,
  "MappedTargetBasis" -> targetBasis[[mappedTargetPositions]],
  "SourceToTargetMasterRules" -> Thread[
    sourceBasis -> targetBasis[[mappedTargetPositions]]
  ],
  "SourceToTargetPositions" -> mappedTargetPositions,
  "ComplementaryTargetPositions" -> complementaryTargetPositions,
  "SelectionMatrix" -> selectionMatrix,
  "InjectionMatrix" -> injectionMatrix,
  "SourcePowerSums" -> sourcePowers,
  "DifferentialOneFormCriterion" -> HoldForm[
    Selection . Omega305 ==
      (dH . Inverse[H] + H . Pullback[Omega254, Phi] . Inverse[H]) .
        Selection
  ],
  "ClosureCriterion" -> HoldForm[
    ForAll[mu, Implies[
      MemberQ[{v305, w305}, mu],
      Selection . A305[mu] . Transpose[ComplementSelection] == 0
    ]]
  ],
  "PhysicalVariableConnection" -> <|
    "Av" -> predictedAv,
    "Aw" -> predictedAw
  |>,
  "ExactChecks" -> checks,
  "InputFiles" -> requiredFiles,
  "InputSHA256" -> AssociationThread[
    requiredFiles, IntegerString[FileHash[#, "SHA256"], 16, 64] & /@ requiredFiles
  ]
|>;

Put[transferRecord, temporaryOutputFile];
RenameFile[temporaryOutputFile, outputFile, OverwriteTarget -> True];

Print["Acceptance criterion satisfied: all exact identities are zero."];
Print["CF254 master positions in CF305 order: ", mappedTargetPositions];
Print["Complementary CF305 positions: ", complementaryTargetPositions];
Print["Transfer record: ", outputFile];
Exit[0];
