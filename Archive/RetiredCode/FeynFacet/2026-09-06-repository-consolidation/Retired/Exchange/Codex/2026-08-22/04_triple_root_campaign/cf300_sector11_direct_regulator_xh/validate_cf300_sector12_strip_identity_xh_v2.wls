#!/usr/bin/env wolframscript

(* Package-free exact comparison of the old physical sidecar and the twice
   reproduced fresh CF300 sector-12/lower-11 strip.  The sidecar already
   records the P/eps^3 regulator; therefore the correct relation is identity,
   reduced over rho^2 = 1 - 4 x y. *)

$HistoryLength = 0;
Internal`InheritedBlock[{System`$ContextPath, System`$Packages},
BeginPackage["CodexCF300Sector12StripIdentityV2`"];
Begin["`Private`"];

Module[
  {oldFile, sidecarResultFile, freshV1File, freshV2File,
   expectedOldHash, expectedSidecarResultHash, expectedFreshHash,
   expectedFreshBytes, dataContext, oldRecord, sidecarResult,
   freshV1Record, freshV2Record, oldStrip, freshStrip, variables,
   regulator, x, y, eps, rho, delta, scalar, toRho, algebraicZeroQ,
   arrayZeroQ, eExact, cExact, bExact, wrongForwardRejected,
   wrongInverseRejected, sampleRules, sampleGate, complexity, gates,
   report},

  oldFile =
    "/home/maxzhang/factorization-and-loops/External/CodexExchange/" <>
    "triple_root_2026-08-22/cf300_sector12_physical_rank3_xh/" <>
    "physical_sidecar_evidence_2026-08-23_xh_v3/CF300_12_11_input.wl";
  sidecarResultFile = FileNameJoin[
    {DirectoryName[oldFile], "sidecar_result.wl"}];
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
  expectedSidecarResultHash =
    "362e460a8bb634bb58949387c328597797267bb71ce3e53d70e8437c36f555b4";
  expectedFreshHash =
    "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976";
  expectedFreshBytes = 15667;
  dataContext = "CodexCF300Sector12StripIdentityV2`Data`";

  oldRecord = Block[{$Context = dataContext, $ContextPath = {"System`"}},
    Quiet[Check[Get[oldFile], $Failed]]];
  sidecarResult =
    Block[{$Context = dataContext, $ContextPath = {"System`"}},
      Quiet[Check[Get[sidecarResultFile], $Failed]]];
  freshV1Record =
    Block[{$Context = dataContext, $ContextPath = {"System`"}},
      Quiet[Check[Get[freshV1File], $Failed]]];
  freshV2Record =
    Block[{$Context = dataContext, $ContextPath = {"System`"}},
      Quiet[Check[Get[freshV2File], $Failed]]];

  If[! And @@ (AssociationQ /@ {oldRecord, sidecarResult,
       freshV1Record, freshV2Record}),
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
    toRho[expression_] := Replace[
      expression,
      RuleDelayed[
        Condition[Power[argument_, exponent_Rational],
          Denominator[exponent] === 2 &&
          TrueQ[Together[argument - delta] === 0]],
        rho^(2 exponent)],
      {0, Infinity}];
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
    bExact = arrayZeroQ[freshStrip[[3]] - oldStrip[[3]]];
    wrongForwardRejected =
      ! arrayZeroQ[freshStrip[[3]] - scalar oldStrip[[3]]];
    wrongInverseRejected =
      ! arrayZeroQ[freshStrip[[3]] - oldStrip[[3]]/scalar];

    sampleRules = {
      {x -> 1/4, y -> 3/4, eps -> 2/5},
      {x -> 3/4, y -> 1/4, eps -> 4/7},
      {x -> 2/3, y -> 1/3, eps -> 1/7},
      {x -> 5/12, y -> 1/3, eps -> 5/7}};
    sampleGate = AllTrue[sampleRules,
      Function[rules,
        And @@ (TrueQ[Together[#1 /. rules] === 0] & /@
          Flatten[freshStrip - oldStrip])]];

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
      "SidecarResultHashPinnedQ" ->
        FileHash[sidecarResultFile, "SHA256", "HexString"] ===
          expectedSidecarResultHash,
      "SidecarAlreadyRegulatedQ" ->
        algebraicZeroQ[
          Lookup[sidecarResult, "RegulatorFactor", $Failed] - scalar],
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
      "BBarExactQ" -> bExact,
      "WrongForwardScalingRejectedQ" -> wrongForwardRejected,
      "WrongInverseScalingRejectedQ" -> wrongInverseRejected,
      "FourExactSamplesQ" -> sampleGate|>;
    report = <|
      "Status" -> If[And @@ Values[gates],
        "CF300Sector12StripIdentityPassedV2",
        "CF300Sector12StripIdentityFailedV2"],
      "Convention" -> "Both artifacts are already in the regulated frame",
      "RecordedRegulatorScalar" -> scalar,
      "Gates" -> gates,
      "Complexity" -> complexity|>
  ];

  Print["CF300 S12 STRIP IDENTITY V2 ", InputForm[report]];
  CodexCF300Sector12StripIdentityV2`Private`finalReport = report;
];

With[{resolvedReport =
    CodexCF300Sector12StripIdentityV2`Private`finalReport},
  End[];
  EndPackage[];
  Quiet[System`Remove["CodexCF300Sector12StripIdentityV2`Data`*"]];
  Quiet[System`Remove["CodexCF300Sector12StripIdentityV2`Private`*"]];
  Quiet[System`Remove["CodexCF300Sector12StripIdentityV2`*"]];
  If[AssociationQ[resolvedReport] &&
      Lookup[resolvedReport, "Status", None] ===
        "CF300Sector12StripIdentityPassedV2", 0, $Failed]]]
