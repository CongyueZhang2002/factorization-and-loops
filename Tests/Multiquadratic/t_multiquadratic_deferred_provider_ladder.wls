#!/usr/bin/env wolframscript
(* A genuine deferred bundle whose materialized BBar is only a zero shape
   placeholder.  The exact provider forcing is d_x G = 1, d_y G = 0.  Hence
   DegreeOffset {0,0} (constant gauge support) is inconsistent, while the
   anisotropic rung {1,0} contains G=x and is consistent.  This prevents a
   square or family-specific support ladder from satisfying the test. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{forcingOf, validateBundle, solve} = mq /@ {
  "blockEquationDeferredForcing", "blockEquationDeferredBundleValidate",
  "solveEpsFormStripMultiquadratic"};

Clear[dlx, dly, dle, dlcx, dlcy];
variables = {dlx, dly}; epsilon = dle;
frame = BuildAlgebraicTransportFrame[{dlx}, variables, {dlcx, dlcy}];

(* lower block (2,1) is the exact forcing; the diagonal blocks used by the
   strip equation below are zero *)
connection = {
  {{0, 0}, {1, 0}},
  {{0, 0}, {0, 0}}
};
bundle = forcingOf[connection, {{1}, {2}}, 2, 1, <||>, variables,
  epsilon, "Output" -> "Bundle", "BundleRoots" -> {}];
FTAssert["DL0 the rational deferred bundle is authenticated",
  Lookup[bundle, "Status", None] === "PreparedDeferredBundle" &&
    Lookup[validateBundle[bundle], "Status", None] === "BundleValid"];

zeroPair = {{{0}}, {{0}}};
record = <|"Family" -> "DEFERRED_SUPPORT_FIXTURE", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> variables, "Regulator" -> epsilon,
  "Strip" -> {zeroPair, zeroPair, zeroPair},
  "DeferredBundle" -> bundle|>;

result = solve[record, frame,
  "DeferredBundle" -> bundle, "RootIndices" -> {},
  "LetterRecords" -> {}, "GaugeDenominator" -> 1,
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
    "PostReconstructionAffineSolveCount", "GaugeScreen",
    "IntegrabilityScreen"}],
  "Ladder" -> KeyTake[ladder, {"Status", "AdoptedDegreeOffset",
    "SuccessfulPilotReuseCount"}],
  "Reconstruction" -> KeyTake[reconstruction,
    {"Status", "ReusedPilotImageCount", "FullAffineSolveCount",
      "PlanDiscoveryBackendUsed", "PlanDiscoveryBackendThreads"}]|>]];

FTAssert["DL1 the placeholder-based symbolic screens are not evaluated",
  Lookup[Lookup[result, "GaugeScreen", <||>], "Status", None] ===
      "GaugeScreenSkipped" &&
    Lookup[Lookup[result, "IntegrabilityScreen", <||>], "Status", None] ===
      "IntegrabilityScreenSkipped"];
FTAssert["DL2 the provider ladder adopts the first consistent higher rung",
  MemberQ[{"Solved", "ModularConsistent"}, Lookup[result, "Status", None]] &&
    Lookup[result, "AdoptedDegreeOffset", None] === {1, 0} &&
    Lookup[ladder, "Status", None] ===
      "DeferredProviderSupportLadderAdopted" &&
    Lookup[ladder, "AdoptedDegreeOffset", None] === {1, 0}];
FTAssert["DL3 both images carry exact rank-versus-augmented-rank evidence",
  Length[rungs] === 2 &&
    Lookup[rungs, "DegreeOffset", {}] === {{0, 0}, {1, 0}} &&
    Length[DeleteDuplicates[Lookup[rungs[[1]], "Images", {}][[All, 1]]]] === 2 &&
    Lookup[rungs[[1]], "Defects", {}] === {1, 1} &&
    Lookup[rungs[[2]], "Defects", {}] === {0, 0} &&
    Lookup[rungs[[1]], "AugmentedRanks", {}] ===
      Lookup[rungs[[1]], "Ranks", {}] + 1 &&
    Lookup[rungs[[2]], "AugmentedRanks", {}] ===
      Lookup[rungs[[2]], "Ranks", {}]];
FTAssert["DL4 support-only reprepare reuses the authenticated provider",
  TrueQ[Lookup[rungs[[2]], "ProviderReused", False]] &&
    Lookup[rungs[[1]], "ProviderFingerprint", None] ===
      Lookup[rungs[[2]], "ProviderFingerprint", Missing[]] &&
    Lookup[rungs[[1]], "LayoutFingerprint", None] =!=
      Lookup[rungs[[2]], "LayoutFingerprint", None]];
FTAssert["DL5 the two successful pilots are not sampled or RREFed again",
  Lookup[ladder, "SuccessfulPilotReuseCount", 0] === 2 &&
    Lookup[reconstruction, "ReusedPilotImageCount", 0] === 2 &&
    Count[Lookup[reconstruction, "ImagePhaseRecords", {}],
      item_ /; StringContainsQ[Lookup[item, "SolvePath", ""],
        "ProviderSupportPilot"]] >= 2 &&
    Lookup[result, "PostReconstructionAffineSolveCount", -1] === 0];
FTAssert["DL6 native backend telemetry reaches the terminal record",
  Lookup[reconstruction, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF" &&
    Lookup[reconstruction, "PlanDiscoveryBackendThreads", None] === 2 &&
    NumericQ[Lookup[Lookup[reconstruction, "PlanDiscoveryTelemetry", <||>],
      "PlanDiscoveryBackendSeconds", None]]];
FTAssert["DL7 the adopted general gauge is G=x and roots use source indices",
  Together[First[Flatten[Lookup[result, "Gauge", {{{Indeterminate}}}]]] -
      dlx] === 0 && Lookup[result, "RootIndices", Missing[]] === {}];

FTSummary[];
