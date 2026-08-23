(* STAGED integration skeleton.  Insert only into a new, hash-pinned V6f
   driver copy after the held/static/adversarial gate.  Never modify V6e. *)

(* The existing driver has already fully validated baseAssembly and
   maxPreparation.  The following legacyResult must be the immediate result of
   this pinned call; do not load it from an unpinned file or caller argument. *)
{v6fLegacyOracleSeconds, v6fLegacyResult} = AbsoluteTiming[
  CodexDirectRootChannelExactOneFormRebindV6`DRCARebindExactOneFormChannels[
    baseAssembly, maxPreparation, additionalOneFormChannels]];

v6fSourceFiles = <|
  "Assembler" -> files["Assembler"],
  "OrbitCoreV6d" -> files["OrbitCoreV6d"],
  "ExactChannelRebindV6" -> files["ExactChannelRebindV6"]|>;

{v6fBridgeBuildSeconds, v6fBridgeHandle} = AbsoluteTiming[
  CodexDirectRootChannelExactOneFormBridgeV6f`
    DRCABuildExactOneFormBridgeV6f[baseAssembly, maxPreparation,
      additionalRecords, v6fLegacyResult, v6fSourceFiles,
      expectedMaximalAssemblyFingerprint]];
Clear[v6fLegacyResult];

If[Lookup[v6fBridgeHandle, "Status", None] =!=
      "ExactOneFormBridgeV6f" ||
    Lookup[v6fBridgeHandle, "ResultAssemblyFingerprint", None] =!=
      expectedMaximalAssemblyFingerprint ||
    Lookup[v6fBridgeHandle, "RecordCount", -1] =!=
      additionalLetterCount ||
    Lookup[v6fBridgeHandle, "RawLeafCount", -1] =!=
      additionalLetterCount 2 gradeCount ||
    ! TrueQ[Lookup[v6fBridgeHandle,
      "ExactLegacyOracleBridgePassed", False]],
  finish["V6fOneTimeBridgeBuildFailed", <|
    "BridgeHandle" -> v6fBridgeHandle|>, 79]];

Clear[runV6fResolveTrial];
runV6fResolveTrial[label_String] := Module[{seconds, resolved, compact},
  {seconds, resolved} = AbsoluteTiming[
    CodexDirectRootChannelExactOneFormBridgeV6f`
      DRCAResolveExactOneFormBridgeV6f[v6fBridgeHandle]];
  compact = KeyDrop[resolved, "Assembly"];
  <|"Status" -> If[
      Lookup[resolved, "Status", None] ===
        "ExactOneFormBridgeV6fResolved" &&
      Lookup[Lookup[resolved, "Handle", <||>],
        "BridgeFingerprint", None] ===
        v6fBridgeHandle["BridgeFingerprint"],
      "CF300V6fResolveTrialPassed", "CF300V6fResolveTrialFailed"],
    "Label" -> label, "Seconds" -> seconds,
    "CompactEvidence" -> compact,
    "Assembly" -> Lookup[resolved, "Assembly", $Failed]|>];

v6fTrial1Full = runV6fResolveTrial["same-bridge-1"];
v6fTrial1 = KeyDrop[v6fTrial1Full, "Assembly"];
Clear[v6fTrial1Full];
v6fTrial2Full = runV6fResolveTrial["same-bridge-2"];
screenAssembly = Lookup[v6fTrial2Full, "Assembly", $Failed];
v6fTrial2 = KeyDrop[v6fTrial2Full, "Assembly"];
Clear[v6fTrial2Full];

If[Lookup[v6fTrial1, "Status", None] =!=
      "CF300V6fResolveTrialPassed" ||
    Lookup[v6fTrial2, "Status", None] =!=
      "CF300V6fResolveTrialPassed" ||
    screenAssembly["AssemblyFingerprint"] =!=
      expectedMaximalAssemblyFingerprint,
  finish["V6fOneTimeBridgeResolveFailed", <|
    "Trial1" -> v6fTrial1, "Trial2" -> v6fTrial2|>, 80]];

(* Release only after all finite-field images and exact-lift prerequisite data
   have been derived from screenAssembly. *)
v6fReleaseAfterUse :=
  CodexDirectRootChannelExactOneFormBridgeV6f`
    DRCAReleaseExactOneFormBridgeV6f[v6fBridgeHandle];

(* Telemetry must keep cold and warm costs separate. *)
v6fTimingTelemetry = <|
  "OneTimeLegacyOracleSeconds" -> v6fLegacyOracleSeconds,
  "OneTimeBridgeBuildSeconds" -> v6fBridgeBuildSeconds,
  "WarmResolveSeconds" -> Lookup[{v6fTrial1, v6fTrial2}, "Seconds"]|>;

(* FULL-DRIVER PROMOTION BLOCKER: do not append the existing image loop to
   this skeleton unchanged.  Its public DRCAAssembleSample calls revalidate
   the whole assembly eight times.  Promotion requires a separately staged,
   source-pinned bridge-owned validated-sample internal API.  The API must
   obtain the assembly from the private bridge registry; it must not accept a
   caller assembly plus a forgeable public fingerprint option. *)
