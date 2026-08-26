#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{driverFile, stateFile, outdir, summaryFile, hashHex, sourceText,
    sourceLines, parseText, parseContext, parsed, state, expectedPairs,
    observedPairs, stripCertifiedQ, checks, summary},
  driverFile =
    "/mnt/c/Users/congyue zhang/Documents/ChatGPT/Agentic Loops/" <>
      "run_cf303_21_12_dependency_closed_predecomposed_channel_census_" <>
      "v2_2026-08-24.wls";
  stateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
      "cf303_resume_from_sector16_v1/" <>
      "sector_state_CF303_identity_capture_xh_v4.wl";
  outdir =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
      "cf303_21_12_v2_static_and_state_gate_v1";
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  hashHex[file_String] := FileHash[file, "SHA256", "HexString"];

  If[Rest[$ScriptCommandLine] =!= {} ||
      ! IntegerQ[$KernelID] || $KernelID <= 0 ||
      Length[Kernels[]] =!= 0 ||
      ! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 0),
    Print["CF3032112STATICGATE status=FAIL reason=worker-contract"];
    Return[$Failed]];
  If[DirectoryQ[outdir] || FileExistsQ[outdir],
    Print["CF3032112STATICGATE status=FAIL reason=output-exists"];
    Return[$Failed]];

  sourceText = Quiet[Check[Import[driverFile, "Text"], $Failed]];
  If[! StringQ[sourceText],
    Print["CF3032112STATICGATE status=FAIL reason=driver-import"];
    Return[$Failed]];
  sourceLines = StringSplit[sourceText, "\n"];
  parseText = If[sourceLines =!= {} &&
      StringStartsQ[First[sourceLines], "#!"],
    StringRiffle[Rest[sourceLines], "\n"], sourceText];
  parseContext = "CF303Sector2112StaticParse`c" <>
    StringReplace[CreateUUID[], "-" -> ""] <> "`";
  parsed = Block[{$Context = parseContext, $ContextPath = {"System`"}},
    Quiet[Check[ToExpression[parseText, InputForm, HoldComplete], $Failed]]];
  Quiet[Remove[parseContext <> "*"]];

  state = Quiet[Check[Get[stateFile], $Failed]];
  If[! AssociationQ[state],
    Print["CF3032112STATICGATE status=FAIL reason=state-import"];
    Return[$Failed]];
  expectedPairs = Flatten[
    Table[{sector, lower}, {sector, 2, 16}, {lower, 1, sector - 1}], 1];
  observedPairs = Lookup[state["StripSolvers"],
    {"Sector", "LowerSector"}, None];
  stripCertifiedQ = AllTrue[state["StripSolvers"],
    If[Lookup[#, "Method", None] === "ZeroForcing",
      TrueQ[Lookup[#, "ExactDLog", False]],
      TrueQ[Lookup[Lookup[#, "FrameCertificate", <||>],
        "Exact", False]]] &];
  checks = <|
    "DriverParsesUnderHoldComplete" -> Head[parsed] === HoldComplete,
    "PendingDerivativeHashesAreFailClosed" ->
      StringContainsQ[sourceText, "PENDING_DERIVATIVE_SHARD_1_SHA256"] &&
      StringContainsQ[sourceText, "PENDING_DERIVATIVE_SHARD_2_SHA256"] &&
      StringContainsQ[sourceText, "PENDING_DERIVATIVE_SHARD_3_SHA256"],
    "StateHashPinned" ->
      hashHex[stateFile] ===
        "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    "StateSectorExactly16" -> Lookup[state, "Sector", None] === 16,
    "StateStripPairCoverageThrough16Exact" ->
      Sort[observedPairs] === Sort[expectedPairs] &&
      Length[observedPairs] === Length[expectedPairs],
    "StateStripSummariesExactlyCertified" -> stripCertifiedQ,
    "StateSectorCertificateCoverageThrough16Exact" ->
      Lookup[state["SectorCertificates"], "Sector", None] === Range[2, 16] &&
      Length[state["SectorCertificates"]] === 15,
    "StateSectorRoutesBlockwise" ->
      Lookup[state["SectorCertificates"], "Route", None] ===
        ConstantArray["Blockwise", 15]|>;
  CreateDirectory[outdir];
  summary = <|
    "Status" -> If[And @@ Values[checks],
      "CF303Sector2112V2StaticAndStateGatePassedV1",
      "CF303Sector2112V2StaticAndStateGateFailedV1"],
    "DriverFile" -> driverFile,
    "DriverSHA256" -> hashHex[driverFile],
    "StateFile" -> stateFile,
    "StateSHA256" -> hashHex[stateFile],
    "ExpectedStripPairCount" -> Length[expectedPairs],
    "ObservedStripPairCount" -> Length[observedPairs],
    "Checks" -> checks,
    "PackageSourceModified" -> False,
    "Created" -> DateString[Now, "ISODateTime"]|>;
  Put[summary, summaryFile];
  If[! And @@ Values[checks],
    Print["CF3032112STATICGATE status=FAIL checks=", checks];
    $Failed,
    Print["CF3032112STATICGATE status=PASS pairs=", Length[observedPairs],
      " summary=", summaryFile];
    0]
]
