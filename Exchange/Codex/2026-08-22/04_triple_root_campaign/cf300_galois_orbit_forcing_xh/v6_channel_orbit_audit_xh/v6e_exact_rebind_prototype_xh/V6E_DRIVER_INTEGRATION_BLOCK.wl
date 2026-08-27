(* V6e drop-in integration block for the frozen V6d driver.

   This file is intentionally not a standalone driver.  It documents the
   exact source-pinning, record selection, rebind, and single-use seal gates
   required in a future V6e driver copy.  It does not modify the active V6d
   driver or Galois core.
*)

(* Add beside the existing V6d file table entry. *)
files = Append[files, "ExactChannelRebindV6e" -> FileNameJoin[{
  v6Directory, "v6e_exact_rebind_prototype_xh",
  "DirectRootChannelExactOneFormRebindV6e.wl"}]];

(* Freeze-time helper hash; the static gate requires this exact value. *)
expectedHashes = Append[expectedHashes,
  "ExactChannelRebindV6e" ->
    "2fea1e07c691ade811162f47db1d71d82a385dd01d07afd20beaa3aa0262f2e8"];

If[observedHashes["ExactChannelRebindV6e"] =!=
    expectedHashes["ExactChannelRebindV6e"],
  finish["V6eExactRebindSourceHashMismatch", <|
    "Expected" -> expectedHashes["ExactChannelRebindV6e"],
    "Observed" -> observedHashes["ExactChannelRebindV6e"]|>, 75]];
Get[files["ExactChannelRebindV6e"]];

(* Run after GCOBuildOrbitBasis has passed all V6d character, cardinality,
   provenance, and closure gates, and after maxPreparation is ABI-valid.
   The V6d orbit payload returns additional channels but not the corresponding
   records as a separate field.  Recover them by exact SameQ selection, in the
   order of AdditionalOneFormChannels.  No algebraic simplification occurs. *)
additionalLetterRecordsV6e = Map[
  Function[channel, SelectFirst[forcingLetterRecords,
    SameQ[Lookup[#1, "OneFormChannels", $Failed], channel] &,
    $Failed]], additionalOneFormChannels];
If[Length[additionalLetterRecordsV6e] =!= additionalLetterCount ||
    ! FreeQ[additionalLetterRecordsV6e, $Failed] ||
    Lookup[additionalLetterRecordsV6e, "OneFormChannels"] =!=
      additionalOneFormChannels ||
    Lookup[additionalLetterRecordsV6e, "OneForm"] =!=
      Drop[maxOneForms, Length[baseOneForms]] ||
    ! DuplicateFreeQ[Lookup[additionalLetterRecordsV6e,
      "ChannelFingerprint"]],
  finish["V6eAdditionalRecordSelectionInvalid", <|
    "ExpectedCount" -> additionalLetterCount,
    "ObservedCount" -> Length[additionalLetterRecordsV6e]|>, 79]];

{rebindSeconds, maxAssembly} = AbsoluteTiming[
  CodexDirectRootChannelExactOneFormRebindV6e`DRCARebindExactOneFormRecordsV6e[
      baseAssembly, maxPreparation, additionalLetterRecordsV6e]];
exactRebindDiagnostics = Lookup[maxAssembly,
  "ExactOneFormChannelRebindV6e", <||>];
exactRebindSeal = Lookup[maxAssembly,
  "ExactOneFormChannelRebindSealV6e", <||>];

(* The V6e helper has already run exactly one full legacy whole-result oracle.
   The driver consumes the cheaper specialized seal; it must not make another
   DRCAAssemblyPreparationValidQ[maxAssembly] call. *)
specializedSealConsumed =
  CodexDirectRootChannelExactOneFormRebindV6e`DRCAConsumeExactOneFormRebindSealV6e[
      baseAssembly, maxPreparation, maxAssembly, exactRebindSeal];
If[! TrueQ[specializedSealConsumed] ||
    maxAssembly["SourceABIFingerprint"] =!=
      maxPreparation["ABIFingerprint"] ||
    Take[maxAssembly["OneForms"], Length[baseOneForms]] =!=
      baseOneForms ||
    Lookup[exactRebindDiagnostics, "Status", None] =!=
      "ExactOneFormChannelRebindV6e" ||
    Lookup[exactRebindDiagnostics,
      "AppendedOneFormCount", -1] =!= additionalLetterCount ||
    Lookup[exactRebindDiagnostics,
      "RawLeafCount", -1] =!=
        additionalLetterCount 2 gradeCount ||
    Lookup[exactRebindDiagnostics, "RawLeafCount", -1] =!=
      Lookup[exactRebindDiagnostics,
        "UniqueCompiledLeafCount", -2] +
      Lookup[exactRebindDiagnostics, "CompileCacheReuseCount", -3] ||
    Lookup[exactRebindDiagnostics, "CompileCount", -1] =!=
      Lookup[exactRebindDiagnostics,
        "UniqueCompiledLeafCount", -2] ||
    Lookup[exactRebindDiagnostics,
      "CollisionGroupCount", -1] =!= 0 ||
    Lookup[exactRebindDiagnostics,
      "LegacyWholeResultOracleCount", -1] =!= 1 ||
    ! TrueQ[Lookup[exactRebindDiagnostics,
      "SpecializedSealPassed", False]] ||
    ! TrueQ[Lookup[exactRebindDiagnostics,
      "LegacyWholeResultOraclePassed", False]] ||
    Lookup[exactRebindDiagnostics,
      "AlgebraicFieldDecompositionCalls", -1] =!= 0 ||
    Lookup[exactRebindDiagnostics,
      "AlgebraicRootBranchSubstitutions", -1] =!= 0,
  finish["MaximalOrbitExactChannelRebindV6eInvalid", <|
    "RebindStatus" -> Lookup[maxAssembly, "Status", None],
    "ExactRebindDiagnostics" -> exactRebindDiagnostics,
    "SpecializedSealConsumed" -> specializedSealConsumed,
    "RebindSeconds" -> rebindSeconds|>, 79]];

(* Required replay gate for the driver validation fixture.  Do not execute it
   in a production run: the production nonce was consumed immediately above.
   A fixture must use a fresh rebind and verify {True,False}. *)
v6eExpectedFreshAndReplayConsumeResults = {True, False};

Print["CF300_GALOIS_ORBIT milestone=target_ready_v6e census_s=",
  censusSeconds, " rebind_s=", rebindSeconds,
  " raw_leaves=", exactRebindDiagnostics["RawLeafCount"],
  " unique_leaves=",
    exactRebindDiagnostics["UniqueCompiledLeafCount"],
  " cache_reuse=",
    exactRebindDiagnostics["CompileCacheReuseCount"],
  " legacy_oracles=",
    exactRebindDiagnostics["LegacyWholeResultOracleCount"],
  " unknowns=", unknownCount, " points=", pointCount];
