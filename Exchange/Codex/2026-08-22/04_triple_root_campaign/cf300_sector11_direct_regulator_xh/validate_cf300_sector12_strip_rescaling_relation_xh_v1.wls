#!/usr/bin/env wolframscript

(* Independent, package-free comparison of the old pre-regulator CF300
   sector-12/lower-11 strip and the twice reproduced post-regulator strip.
   The only algebraic relation used is rho^2 = 1 - 4 x y. *)

$HistoryLength = 0;
Internal`InheritedBlock[{System`$ContextPath, System`$Packages},
BeginPackage["CodexCF300Sector12StripRescalingRelationV1`"];
Begin["`Private`"];

Module[
  {oldFile, freshV1File, freshV2File, expectedOldHash,
   expectedFreshHash, expectedFreshBytes, dataContext, oldRecord,
   freshV1Record, freshV2Record, oldStrip, freshStrip, variables,
   regulator, x, y, eps, rho, delta, scalar, toRho, algebraicZeroQ,
   arrayZeroQ, eExact, cExact, bScalingExact, wrongInverseRejected,
   wrongUnitRejected, sampleRules, sampleGate, complexity, gates,
   report},

  oldFile =
    "/home/maxzhang/factorization-and-loops/External/CodexExchange/" <>
    "triple_root_2026-08-22/cf300_sector12_physical_rank3_xh/" <>
    "physical_sidecar_evidence_2026-08-23_xh_v3/CF300_12_11_input.wl";
  freshV1File =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
    "cf300_sector12_recapture_from_v4_xh_v1/sector_CF300_standard/" <>
    "CF300_12_11_input.wl";
  freshV2File =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
    "cf300_sector12_recapture_from_v4_xh_v2/sector_CF300_standard/" <>
    "CF300_12_11_input.wl";
  expectedOldHash =
    "a3e459ccc9da1a38e6abfc82beb200398c4f2b96e032de0eac85765dcbb55f99";
  expectedFreshHash =
    "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976";
  expectedFreshBytes = 15667;
  dataContext = "CodexCF300Sector12StripRescalingRelationV1`Data`";

  oldRecord = Block[{$Context = dataContext, $ContextPath = {"System`"}},
    Quiet[Check[Get[oldFile], $Failed]]];
  freshV1Record =
    Block[{$Context = dataContext, $ContextPath = {"System`"}},
      Quiet[Check[Get[freshV1File], $Failed]]];
  freshV2Record =
    Block[{$Context = dataContext, $ContextPath = {"System`"}},
      Quiet[Check[Get[freshV2File], $Failed]]];

  If[! And @@ (AssociationQ /@ {oldRecord, freshV1Record,
       freshV2Record}),
    report = <|"Status" -> "InputHydrationFailed"|>,

    oldStrip = Lookup[oldRecord, "Strip", $Failed];
    freshStrip = Lookup[freshV1Record, "Strip", $Failed];
    variables = Lookup[freshV1Record, "Variables", $Failed];
    regulator = Lookup[freshV1Record, "Regulator", $Failed];
    {x, y} = variables;
    eps = regulator;
    rho = Symbol[dataContext <> "rho"];
    delta = 1 - 4 x y;
    scalar = ((2 eps - 1) (3 eps - 1) (3 eps - 2))/eps^3;
    toRho[expression_] := expression /. Sqrt[delta] -> rho;
    algebraicZeroQ[expression_] := Module[{rational, numerator,
        denominator, remainder},
      rational = Together[toRho[expression]];
      numerator = Numerator[rational];
      denominator = Denominator[rational];
      remainder = Quiet[Check[
        PolynomialRemainder[numerator, rho^2 - delta, rho], $Failed]];
      remainder =!= $Failed && ! TrueQ[denominator === 0] &&
        TrueQ[Together[remainder] === 0]
    ];
    arrayZeroQ[array_] := AllTrue[Flatten[array], algebraicZeroQ];

    eExact = arrayZeroQ[freshStrip[[1]] - oldStrip[[1]]];
    cExact = arrayZeroQ[freshStrip[[2]] - oldStrip[[2]]];
    bScalingExact =
      arrayZeroQ[freshStrip[[3]] - scalar oldStrip[[3]]];
    wrongInverseRejected =
      ! arrayZeroQ[freshStrip[[3]] - oldStrip[[3]]/scalar];
    wrongUnitRejected =
      ! arrayZeroQ[freshStrip[[3]] - oldStrip[[3]]];

    sampleRules = {
      {x -> 1/4, y -> 3/4, eps -> 2/5},
      {x -> 3/4, y -> 1/4, eps -> 4/7},
      {x -> 2/3, y -> 1/3, eps -> 1/7},
      {x -> 5/12, y -> 1/3, eps -> 5/7}};
    sampleGate = AllTrue[sampleRules,
      Function[rules,
        arrayZeroQ[(freshStrip[[1]] - oldStrip[[1]]) /. rules] &&
        arrayZeroQ[(freshStrip[[2]] - oldStrip[[2]]) /. rules] &&
        arrayZeroQ[(freshStrip[[3]] - scalar oldStrip[[3]]) /. rules]]];

    complexity = <|
      "OldBytes" -> FileByteCount[oldFile],
      "FreshBytes" -> FileByteCount[freshV1File],
      "ByteReductionFactor" ->
        N[FileByteCount[oldFile]/FileByteCount[freshV1File]],
      "OldBBarLeafCount" -> LeafCount[oldStrip[[3]]],
      "FreshBBarLeafCount" -> LeafCount[freshStrip[[3]]],
      "BBarLeafReductionFactor" ->
        N[LeafCount[oldStrip[[3]]]/LeafCount[freshStrip[[3]]]]|>;
    gates = <|
      "OldHashPinnedQ" ->
        FileHash[oldFile, "SHA256", "HexString"] === expectedOldHash,
      "FreshV1HashPinnedQ" ->
        FileHash[freshV1File, "SHA256", "HexString"] ===
          expectedFreshHash,
      "FreshV2HashPinnedQ" ->
        FileHash[freshV2File, "SHA256", "HexString"] ===
          expectedFreshHash,
      "FreshCopiesSameQ" -> SameQ[freshV1Record, freshV2Record],
      "FreshByteCountPinnedQ" ->
        FileByteCount[freshV1File] === expectedFreshBytes &&
        FileByteCount[freshV2File] === expectedFreshBytes,
      "MetadataSameQ" ->
        KeyTake[oldRecord, {"Family", "Sector", "LowerSector",
          "Variables", "Regulator"}] ===
        KeyTake[freshV1Record, {"Family", "Sector", "LowerSector",
          "Variables", "Regulator"}],
      "StripDimensionsQ" ->
        Dimensions[oldStrip] === {3, 2, 2, 2} &&
        Dimensions[freshStrip] === {3, 2, 2, 2},
      "EExactQ" -> eExact,
      "CExactQ" -> cExact,
      "BBarScalingExactQ" -> bScalingExact,
      "WrongInverseScalingRejectedQ" -> wrongInverseRejected,
      "WrongUnitScalingRejectedQ" -> wrongUnitRejected,
      "FourExactSamplesQ" -> sampleGate|>;
    report = <|
      "Status" -> If[And @@ Values[gates],
        "CF300Sector12StripRescalingRelationPassedV1",
        "CF300Sector12StripRescalingRelationFailedV1"],
      "Convention" -> "Anew = G^-1 A G",
      "ExpectedLowerSectorScalar" -> scalar,
      "Gates" -> gates,
      "Complexity" -> complexity|>
  ];

  Print["CF300 S12 STRIP RESCALING RELATION V1 ", InputForm[report]];
  CodexCF300Sector12StripRescalingRelationV1`Private`finalReport = report;
];

With[{resolvedReport =
    CodexCF300Sector12StripRescalingRelationV1`Private`finalReport},
  End[];
  EndPackage[];
  Quiet[System`Remove[
    "CodexCF300Sector12StripRescalingRelationV1`Data`*"]];
  Quiet[System`Remove[
    "CodexCF300Sector12StripRescalingRelationV1`Private`*"]];
  Quiet[System`Remove[
    "CodexCF300Sector12StripRescalingRelationV1`*"]];
  If[AssociationQ[resolvedReport] &&
      Lookup[resolvedReport, "Status", None] ===
        "CF300Sector12StripRescalingRelationPassedV1", 0, $Failed]]]
