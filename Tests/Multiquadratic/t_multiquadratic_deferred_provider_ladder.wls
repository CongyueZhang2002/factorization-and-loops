#!/usr/bin/env wolframscript
(* A genuine deferred bundle whose materialized Inhomogeneity is only a zero shape
   placeholder.  The exact provider inhomogeneity is d_x G = 1, d_y G = 0.  Hence
   DegreeOffset {0,0} (constant gauge support) is inconsistent, while the
   anisotropic rung {1,0} contains G=x and is consistent.  This prevents a
   square or family-specific support ladder from satisfying the test. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{inhomogeneityOf, validateBundle, solve} = mq /@ {
  "blockEquationDeferredInhomogeneity", "blockEquationDeferredBundleValidate",
  "solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators"};

Clear[dlx, dly, dle, dlcx, dlcy];
variables = {dlx, dly}; epsilon = dle;
frame = BuildSquareRootGeneratorsAndQuadraticRelations[{dlx}, variables, {dlcx, dlcy}];

(* lower block (2,1) is the exact inhomogeneity; the diagonal blocks used by the
   strip equation below are zero *)
connection = {
  {{0, 0}, {1, 0}},
  {{0, 0}, {0, 0}}
};
bundle = inhomogeneityOf[connection, {{1}, {2}}, 2, 1, <||>, variables,
  epsilon, "Output" -> "Bundle", "BundleRoots" -> {}];
FTAssert["DL0 the rational deferred bundle is valid",
  Lookup[bundle, "Status", None] === "PreparedDeferredBundle" &&
    Lookup[validateBundle[bundle], "Status", None] === "BundleValid"];

zeroPair = {{{0}}, {{0}}};
record = <|"Family" -> "DEFERRED_SUPPORT_FIXTURE", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> variables, "Regulator" -> epsilon,
  "OffDiagonalBlockEquation" -> {zeroPair, zeroPair, zeroPair},
  "DeferredBundle" -> bundle|>;

result = solve[record, frame,
  "DeferredBundle" -> bundle, "RootIndices" -> {},
  "LetterRecords" -> {}, "OffDiagonalBasisTransformationDenominator" -> 1,
  "CoefficientProvider" -> "SplitBranch",
  "DegreeOffset" -> {0, 0}, "DegreeOffsetLadder" -> {{1, 0}},
  "PlanDiscoveryBackend" -> "FLINTAffineRREF",
  "PlanDiscoveryBackendThreads" -> 2,
  "PlanDiscoveryBackendMinimumEntries" -> 0,
  "RegulatorReconstructionCheck" -> "ProviderPoints",
  "Verbose" -> False];

ladder = Lookup[result, "DeferredProviderSupportLadder", <||>];
rungs = Lookup[ladder, "LadderRungs", {}];
reconstruction = Lookup[result, "RegulatorReconstruction", <||>];
Print["DL telemetry: ", InputForm[<|
  "Result" -> KeyTake[result, {"Status", "AdoptedDegreeOffset",
    "PostReconstructionAffineSolveCount", "OffDiagonalBasisTransformationBlockScreen",
    "IntegrabilityScreen"}],
  "Ladder" -> KeyTake[ladder, {"Status", "AdoptedDegreeOffset",
    "SuccessfulPilotReuseCount"}],
  "Reconstruction" -> KeyTake[reconstruction,
    {"Status", "ReusedPilotImageCount", "FullAffineSolveCount",
      "PlanDiscoveryBackendUsed", "PlanDiscoveryBackendThreads"}]|>]];

FTAssert["DL1 the placeholder-based symbolic screens are not evaluated",
  Lookup[Lookup[result, "OffDiagonalBasisTransformationBlockScreen", <||>], "Status", None] ===
      "OffDiagonalBasisTransformationBlockScreenSkipped" &&
    Lookup[Lookup[result, "IntegrabilityScreen", <||>], "Status", None] ===
      "IntegrabilityScreenSkipped"];
FTAssert["DL2 the provider ladder adopts the first consistent higher rung",
  MemberQ[{"Solved", "ModularConsistent"}, Lookup[result, "Status", None]] &&
    Lookup[result, "AdoptedDegreeOffset", None] === {1, 0} &&
    Lookup[ladder, "Status", None] ===
      "DeferredProviderSupportLadderAdopted" &&
    Lookup[ladder, "AdoptedDegreeOffset", None] === {1, 0}];
FTAssert["DL3 both images carry exact one-RHS consistency evidence",
  Length[rungs] === 2 &&
    Lookup[rungs, "DegreeOffset", {}] === {{0, 0}, {1, 0}} &&
    Length[DeleteDuplicates[Lookup[rungs[[1]], "Images", {}][[All, 1]]]] === 2 &&
    Lookup[rungs[[1]], "Defects", {}] === {1, 1} &&
    Lookup[rungs[[2]], "Defects", {}] === {0, 0} &&
    AllTrue[Lookup[rungs[[1]], "Ranks", {}], MissingQ] &&
    AllTrue[Lookup[rungs[[1]], "AugmentedRanks", {}], MissingQ] &&
    Lookup[Lookup[rungs[[1]], "ImageEvidence", {}], "DefectEvidence", {}] ===
      ConstantArray["SingleRightHandSideAffineInconsistency", 2] &&
    Lookup[rungs[[2]], "AugmentedRanks", {}] ===
      Lookup[rungs[[2]], "Ranks", {}]];
FTAssert["DL4 support-only reprepare reuses the same coefficient provider",
  TrueQ[Lookup[rungs[[2]], "ProviderReused", False]] &&
    rungs[[1, "SupportCount"]] < rungs[[2, "SupportCount"]]];
FTAssert["DL5 the two successful pilots are not sampled or RREFed again",
  Lookup[ladder, "SuccessfulPilotReuseCount", 0] === 2 &&
    Lookup[reconstruction, "ReusedPilotImageCount", 0] === 2 &&
    Lookup[reconstruction, "StructuralPilotCacheHitCount", -1] === 2 &&
    Lookup[reconstruction, "StructuralPilotNewSampleCount", -1] === 0 &&
    Lookup[reconstruction, "StructuralPilotNewFullAffineSolveCount", -1] === 0 &&
    Count[Lookup[reconstruction, "ImagePhaseRecords", {}],
      item_ /; StringContainsQ[Lookup[item, "SolvePath", ""],
        "ProviderSupportPilot"]] === 1 &&
    Lookup[result, "PostReconstructionAffineSolveCount", -1] === 0];
FTAssert["DL6 native backend telemetry reaches the terminal record",
  Lookup[reconstruction, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF" &&
    Lookup[reconstruction, "PlanDiscoveryBackendThreads", None] === 2 &&
    NumericQ[Lookup[Lookup[reconstruction, "PlanDiscoveryTelemetry", <||>],
      "PlanDiscoveryBackendSeconds", None]]];
FTAssert["DL7 the adopted general gauge is G=x and roots use source indices",
  Together[First[Flatten[Lookup[result, "OffDiagonalBasisTransformationBlock", {{{Indeterminate}}}]]] -
      dlx] === 0 && Lookup[result, "RootIndices", Missing[]] === {}];

FTSummary[];
