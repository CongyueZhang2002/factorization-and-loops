(* Mathematical identity and state-transition helpers for family row gauges.
   Resume admission is independent of every execution choice: a checkpoint
   binds only its family/sector/connection, banked gauge prefix and the
   mathematical acceptance record of each block. *)

ClearAll[
  familyRowGaugeFamilyDeadlineDecision,
  familyRowGaugeStaleStopMigration,
  $familyRowGaugeResolvableStops,
  familyRowGaugeDirectAlphabetOptions,
  familyRowGaugeDirectAlphabetOptionsValidQ,
  familyRowGaugeSolverFailureSummary,
  familyRowGaugeHydrateResume
];

(* The direct route's materialized BBar is deliberately a zero-shape
   placeholder.  Its rational factors, Galois-orbit norms and algebraic
   factors therefore have to be recovered from the authenticated deferred
   bundle, not from BBar.  Keep that derivation in one package helper so the
   production dispatch receives the complete option payload. *)
familyRowGaugeDirectAlphabetOptionsValidQ[payload_] :=
  AssociationQ[payload] &&
    Sort[Keys[payload]] ===
      Sort[{"AdditionalLetters", "AlgebraicLetters"}] &&
    ListQ[payload["AdditionalLetters"]] &&
    (payload["AlgebraicLetters"] === Automatic ||
      ListQ[payload["AlgebraicLetters"]]) &&
    FreeQ[payload, Alternatives[_Missing, $Failed]];
familyRowGaugeDirectAlphabetOptionsValidQ[___] := False;

familyRowGaugeDirectAlphabetOptions[] := <|
  "AdditionalLetters" -> {}, "AlgebraicLetters" -> Automatic|>;
familyRowGaugeDirectAlphabetOptions[bundle_Association] := Module[
  {summary, factors, orbits, rational, algebraic, payload, safeLookup},
  summary = Lookup[bundle, "DivisorSummary", Missing["NoDivisorSummary"]];
  If[! AssociationQ[summary], Return[$Failed]];
  factors = Lookup[summary, "Factors", Missing["NoFactors"]];
  orbits = Lookup[summary, "GaloisOrbits", Missing["NoGaloisOrbits"]];
  If[! MatchQ[factors, {___Association}] ||
      ! MatchQ[orbits, {___Association}],
    Return[$Failed]];
  (* Lookup[{}, key, default] returns the bare default.  Empty factor and
     orbit lists are valid for a bundle whose active subfield is rational. *)
  safeLookup[entries_List, key_, missing_] := If[entries === {}, {},
    Lookup[entries, key, missing]];
  algebraic = safeLookup[Select[factors,
    TrueQ[Lookup[#1, "Algebraic", False]] &], "Factor",
    Missing["FactorMissing"]];
  rational = DeleteDuplicates[Join[
    safeLookup[Select[factors,
      ! TrueQ[Lookup[#1, "Algebraic", False]] &], "Factor",
      Missing["FactorMissing"]],
    safeLookup[orbits, "Norm", Missing["NormMissing"]]]];
  payload = <|"AdditionalLetters" -> rational,
    "AlgebraicLetters" -> If[algebraic === {}, Automatic, algebraic]|>;
  If[familyRowGaugeDirectAlphabetOptionsValidQ[payload], payload, $Failed]
];
familyRowGaugeDirectAlphabetOptions[___] := $Failed;

(* Persist only a fixed diagnostic whitelist, with a 4096-byte ceiling per
   value.  Gauges, samples, matrices, and inner solutions are excluded. *)
familyRowGaugeSolverFailureSummary[candidate_] := Module[
  {keys, bounded, diagnostics, status},
  keys = {"Method", "RootIndices", "RootSquares", "RadicalBases",
    "UnclassifiedRadicalBases", "CoefficientField",
    "BackendRequested", "BackendUsed", "BackendFallbackReason",
    "BackendFailure", "PlanValidationStatus",
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "StructuralFailureReasons", "Certificate",
    (* 2026-08-24: the ansatz a defect was measured in.  Without these a
       recorded failure says only that the system was inconsistent, and a
       missing letter is indistinguishable from too small a support or a
       gauge denominator that cannot carry the pole; each value is
       ByteCount-bounded by the same rule as every other field. *)
    "Prime", "MatrixDimensions", "InconsistentRows", "Rank", "Nullity",
    "UnknownCount", "GaugeDenominator", "GaugeSupport", "OneFormCount"};
  bounded[value_] := If[ByteCount[value] <= 4096, value,
    <|"Elided" -> True, "ByteCount" -> ByteCount[value],
      "SHA256" -> Hash[value, "SHA256", "HexString"]|>];
  Which[
    candidate === $Failed,
      <|"Schema" -> "FeynFacetStripSolverFailureSummary",
        "SchemaVersion" -> 1, "Status" -> "SolverReturnedFailed",
        "Diagnostics" -> <||>|>,
    ! AssociationQ[candidate],
      <|"Schema" -> "FeynFacetStripSolverFailureSummary",
        "SchemaVersion" -> 1, "Status" -> "InvalidSolverReturn",
        "ReturnHead" -> ToString[Head[candidate], InputForm],
        "Diagnostics" -> <||>|>,
    True,
      status = Lookup[candidate, "Status",
        "SolverAssociationWithoutStatus"];
      diagnostics = Association@KeyValueMap[#1 -> bounded[#2] &,
        KeyTake[candidate, keys]];
      <|"Schema" -> "FeynFacetStripSolverFailureSummary",
        "SchemaVersion" -> 1,
        "Status" -> If[StringQ[status] && StringLength[status] <= 256,
          status, "SolverAssociationWithInvalidStatus"],
        "Diagnostics" -> diagnostics|>]
];


(* ---- WHOLE-FAMILY DEADLINE PERSISTENCE (2026-08-25) ----------------
   (Codex 14:30 "whole-family deadline persistence")

   The sector driver's budget is PER SECTOR and is recomputed at every
   sector start, so a restarted family silently got a fresh allowance
   for every sector it re-entered.  A whole-family budget must survive
   the driver: its DEADLINE EPOCH belongs in the sector state file, and
   a resumed run must inherit the REMAINING budget, never a new one.

   The decision is a pure function of (state, declared budget, now) so
   that the driver contains no policy and the policy is testable without
   running a family:

     no budget declared, none stamped  -> "None"       (Infinity)
     no budget declared, one stamped   -> "Inherited"  (the stamped epoch)
     budget declared = stamped budget  -> "Inherited"  (the stamped epoch)
     budget declared, none stamped     -> "Stamped"    (now + budget)
     budget declared /= stamped budget -> "Restamped"  (now + budget)

   "Inherited" is the case that matters: a resume of a state stamped an
   hour ago with a 2-hour budget gets ONE hour, and a resume after the
   epoch gets a typed stop before it touches a sector.  "Restamped" is
   an operator deliberately re-budgeting the family; it is recorded, not
   silent. *)
familyRowGaugeFamilyDeadlineDecision[state_Association, familyBudget_,
    now_?NumericQ] := Module[
  {stamped = Lookup[state, "FamilyDeadline", Missing["NoFamilyDeadline"]],
   stampedBudget = Lookup[state, "FamilyBudgetSeconds",
     Missing["NoFamilyBudget"]]},
  Which[
    familyBudget === Infinity && ! NumericQ[stamped],
      <|"Action" -> "None", "Deadline" -> Infinity,
        "BudgetSeconds" -> Infinity, "State" -> state,
        "Persist" -> False|>,
    familyBudget === Infinity,
      <|"Action" -> "Inherited", "Deadline" -> stamped,
        "BudgetSeconds" -> stampedBudget, "State" -> state,
        "Persist" -> False|>,
    NumericQ[stamped] && stampedBudget === familyBudget,
      <|"Action" -> "Inherited", "Deadline" -> stamped,
        "BudgetSeconds" -> stampedBudget, "State" -> state,
        "Persist" -> False|>,
    True,
      Module[{deadline = now + familyBudget},
        <|"Action" -> If[NumericQ[stamped], "Restamped", "Stamped"],
          "Deadline" -> deadline, "BudgetSeconds" -> familyBudget,
          "PreviousDeadline" -> stamped,
          "PreviousBudgetSeconds" -> stampedBudget,
          "State" -> Join[state, <|"FamilyDeadline" -> deadline,
            "FamilyBudgetSeconds" -> familyBudget|>],
          "Persist" -> True|>]]
];
familyRowGaugeFamilyDeadlineDecision[___] :=
  <|"Action" -> "InvalidFamilyDeadlineArguments"|>;

(* ---- STALE-STOP MIGRATION (2026-08-25) -----------------------------
   (Codex 14:30 "stale-stop migration branch")

   Before 2026-08-25 a successful regulator factorization did NOT clear
   the typed stop that had demanded it; the fix records a "ResolvedStop"
   resolution inside the factorization record and drops the "Stop" key.
   A state file written BEFORE the fix can therefore carry a resolvable
   Stop whose factorization is ALREADY in "RegulatorFactorizations" --
   an advertised terminal for work that is finished.  Resuming such a
   state is safe only if that is recognized.

   Three conditions, all necessary:
     - the Stop's status is one this driver itself resolves;
     - a factorization record for the SAME rows exists;
     - that record carries NO "ResolvedStop" field, i.e. it predates the
       fix.  A record that already resolved something is never migrated
       a second time.

   Anything else is left exactly as found.  A Stop with no matching
   factorization is a REAL terminal and is never cleared here. *)
$familyRowGaugeResolvableStops = {
  "NeedsMultiquadraticRegulatorFactorization",
  "RegulatorPropagationRejected"};

familyRowGaugeStaleStopMigration[state_Association] := Module[
  {stop = Lookup[state, "Stop", Missing["NoStop"]], rows, factorizations,
   matching, resolved, migration},
  If[! AssociationQ[stop] ||
      ! MemberQ[$familyRowGaugeResolvableStops, Lookup[stop, "Status", None]],
    Return[<|"Status" -> "NoMigration", "Reason" -> "NoResolvableStop",
      "State" -> state|>]];
  rows = Lookup[stop, "Rows", None];
  factorizations = Lookup[state, "RegulatorFactorizations", {}];
  If[! IntegerQ[rows] || ! ListQ[factorizations],
    Return[<|"Status" -> "NoMigration", "Reason" -> "StopHasNoRows",
      "State" -> state|>]];
  matching = Select[factorizations,
    AssociationQ[#1] && Lookup[#1, "Rows", None] === rows &];
  If[matching === {},
    Return[<|"Status" -> "NoMigration",
      "Reason" -> "NoFactorizationForTheseRows", "State" -> state|>]];
  (* a record that already carries a resolution belongs to the post-fix
     world; its Stop was cleared when it was written, and a Stop
     standing beside it is a NEW one *)
  resolved = Select[matching, ! KeyExistsQ[#1, "ResolvedStop"] &];
  If[resolved === {},
    Return[<|"Status" -> "NoMigration",
      "Reason" -> "FactorizationAlreadyCarriesResolution",
      "State" -> state|>]];
  migration = <|"ClearedStatus" -> stop["Status"], "Rows" -> rows,
    "ResolvedBy" -> Lookup[Last[resolved], "Method", "Unknown"],
    "ResolvedAt" -> Missing["PreResolvedStopCheckpoint"],
    "MigratedAt" -> DateString[{"ISODateTime"}],
    "Migration" -> "StaleStopPreResolvedStopRecord"|>;
  <|"Status" -> "Migrated", "Migration" -> migration,
    "State" -> Join[KeyDrop[state, "Stop"], <|
      "RegulatorFactorizations" -> Append[
        DeleteCases[factorizations, Last[resolved]],
        Append[Last[resolved], "ResolvedStop" -> migration]],
      "StateMigrations" -> Append[Lookup[state, "StateMigrations", {}],
        migration]|>]|>
];
familyRowGaugeStaleStopMigration[___] :=
  <|"Status" -> "InvalidStaleStopMigrationArguments"|>;

Options[familyRowGaugeHydrateResume] = {
  "KernelCount" -> 1,
  "FinalCheck" -> "Numerical",
  "FiniteFieldBackend" -> Automatic,
  "FiniteFieldBackendThreads" -> 2,
  "PlanDiscoveryBackend" -> "Wolfram",
  "PlanDiscoveryBackendThreads" -> Automatic,
  "MultiquadraticImageKernelCount" -> Automatic,
  "MinimumCachedPrimeCount" -> 3,
  "ProviderKind" -> Automatic,
  "BundleABIPolicy" -> Automatic,
  "ProviderABIPolicy" -> Automatic,
  "LayoutABIPolicy" -> Automatic,
  "ReconstructionPolicy" -> Automatic,
  "FreshValidationPolicy" -> Automatic,
  "DriverProvenance" -> <||>,
  "ResumeGate" -> Automatic,
  "ResumeGateImages" -> Automatic,
  "ResumeGateImageCount" -> 2,
  "AdversarialAudit" -> False,
  "Deadline" -> Infinity,
  "Verbose" -> False
};

(* Compatibility entry point for callers predating the mathematical-only
   resume gate.  Every execution option above is intentionally ignored.
   A checkpoint is admitted solely by its family/sector/connection content,
   its exact banked block prefix and the acceptance record of each block. *)
familyRowGaugeHydrateResume[
    checkpoint_Association, checkpointFile_String,
    solvedBlocks_Association, existingForms_Association,
    family_String, sector_Integer?Positive,
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    frame_Association, ranges_List, scratch_String,
    currentConnection : {_List, _List}, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], diskCheckpoint, nk, rowSize,
   lowerBlockSizes, currentTruncation, expectedConnectionHash,
   currentConnectionHash, summaries, keys, familyIdentityQ,
   checkpointForms, reconstructedPrevD, forms, formsValidQ,
   fullCoverageQ, lowerSize, blockColumns, installedRow = Automatic,
   acceptanceRecords},

  If[! MatchQ[ranges, {{__Integer} ..}] ||
      ! MatchQ[Dimensions[currentConnection], {2, _Integer, _Integer}] ||
      Dimensions[currentConnection][[2]] =!=
        Dimensions[currentConnection][[3]] ||
      sector > Length[ranges],
    Return[<|"Status" -> "InvalidResumeHydrationRangeOrConnection",
      "ActivateInstalledRow" -> False|>]];

  nk = Last[ranges[[sector]]];
  rowSize = Length[ranges[[sector]]];
  If[! IntegerQ[nk] || nk < 1 ||
      nk > Dimensions[currentConnection][[2]] ||
      Flatten[Take[ranges, sector]] =!= Range[nk],
    Return[<|"Status" -> "InvalidResumeHydrationRangeOrConnection",
      "ActivateInstalledRow" -> False|>]];

  diskCheckpoint = If[FileExistsQ[checkpointFile],
    FeynFacet`FamilyArtifactRead[checkpointFile],
    Missing["NoCheckpoint"]];
  expectedConnectionHash = Lookup[checkpoint, "ConnectionHash", None];
  currentTruncation = currentConnection[[All, 1 ;; nk, 1 ;; nk]] /.
    epsilon -> CANONICA`eps;
  currentConnectionHash = Hash[currentTruncation, "SHA256", "HexString"];
  If[! SameQ[diskCheckpoint, checkpoint] ||
      ! StringQ[expectedConnectionHash] ||
      currentConnectionHash =!= expectedConnectionHash,
    Return[<|"Status" -> "ResumeHydrationCheckpointIdentityMismatch",
      "DiskSameQ" -> SameQ[diskCheckpoint, checkpoint],
      "CurrentConnectionHashSameQ" ->
        (currentConnectionHash === expectedConnectionHash),
      "ActivateInstalledRow" -> False|>]];

  summaries = Lookup[checkpoint, "StripSolvers", {}];
  familyIdentityQ = Lookup[checkpoint, "Family",
    Missing["LegacyCheckpoint"]];
  familyIdentityQ = If[MissingQ[familyIdentityQ],
    AllTrue[summaries, Function[summary, Module[{file, input},
      file = FileNameJoin[{scratch,
        family <> "_" <> ToString[sector] <> "_" <>
          ToString[Lookup[summary, "LowerSector", -1]] <> "_input.wl"}];
      input = If[FileExistsQ[file],
        FeynFacet`FamilyArtifactRead[file], Missing["NoInput"]];
      AssociationQ[input] &&
        Lookup[input, "Family", None] === family &&
        Lookup[input, "Sector", None] === sector &&
        Lookup[input, "LowerSector", None] ===
          Lookup[summary, "LowerSector", Missing["NoLowerSector"]]]]],
    familyIdentityQ === family];
  If[! TrueQ[familyIdentityQ],
    Return[<|"Status" -> "ResumeHydrationFamilyIdentityMismatch",
      "ActivateInstalledRow" -> False|>]];

  lowerBlockSizes = Length /@ ranges[[Range[sector - 1]]];
  If[Lookup[checkpoint, "Sector", Missing["NoSector"]] =!= sector ||
      Lookup[checkpoint, "SubSize", Missing["NoSubSize"]] =!= rowSize ||
      Lookup[checkpoint, "Truncation", Missing["NoTruncation"]] =!= nk ||
      ! familyRowGaugeCheckpointGaugeShapeQ[
        Lookup[checkpoint, "PrevD", None], rowSize, lowerBlockSizes] ||
      ! familyRowGaugeCheckpointStripSolversQ[
        summaries, Lookup[checkpoint, "PrevD", None], sector,
        lowerBlockSizes],
    Return[<|"Status" -> "ResumeHydrationCheckpointMetadataInvalid",
      "ActivateInstalledRow" -> False|>]];

  keys = Sort[Keys[solvedBlocks]];
  If[! AllTrue[keys, IntegerQ[#] && 1 <= # < sector &] ||
      (keys =!= {} && keys =!= Range[First[keys], sector - 1]) ||
      ! AllTrue[keys,
        Dimensions[Lookup[solvedBlocks, #, Missing["NoGauge"]]] ===
          {rowSize, Length[ranges[[#]]]} &],
    Return[<|"Status" -> "ResumeHydrationCheckpointPayloadInvalid",
      "ActivateInstalledRow" -> False|>]];
  reconstructedPrevD = If[keys === {}, ConstantArray[{}, rowSize],
    Transpose[Join @@ (Transpose /@ Lookup[solvedBlocks, keys])]];
  If[! SameQ[reconstructedPrevD,
      Lookup[checkpoint, "PrevD", Missing["NoPrevD"]]],
    Return[<|"Status" -> "ResumeHydrationSolvedBlocksMismatch",
      "ActivateInstalledRow" -> False|>]];

  (* SolvedForms is an optional acceleration derived from the accepted
     blocks, not part of their identity.  Ignore the caller's cached copy
     and use a well-formed checkpoint copy when present; otherwise sparse
     row propagation remains exact. *)
  checkpointForms = Lookup[checkpoint, "SolvedForms", <||>];
  If[! AssociationQ[checkpointForms], checkpointForms = <||>];
  forms = checkpointForms;
  formsValidQ = Sort[Keys[forms]] === keys && AllTrue[keys,
    Dimensions[Lookup[forms, #, Missing["NoForm"]]] ===
      {2, rowSize, Length[ranges[[#]]]} &];
  If[! formsValidQ, forms = <||>];

  fullCoverageQ = keys === Range[sector - 1];
  lowerSize = First[ranges[[sector]]] - 1;
  blockColumns = Association@Table[key -> ranges[[key]], {key, keys}];
  If[fullCoverageQ && forms =!= <||>,
    installedRow = familyRowGaugeAssembleInstalledRow[
      forms, solvedBlocks, rowSize, lowerSize, blockColumns]];

  acceptanceRecords = Map[
    <|"LowerSector" -> Lookup[#, "LowerSector", None],
      "Action" -> "TrustedMathematicalAcceptance",
      "Certificate" -> Lookup[#, "Certificate", None],
      "ValidationMode" -> Lookup[
        Lookup[#, "FrameCertificate", <||>], "ValidationMode", None]|> &,
    summaries];
  <|"Status" -> If[fullCoverageQ, "Verified", "VerifiedPartial"],
    "SolvedForms" -> forms, "InstalledRow" -> installedRow,
    "MissingLowerSectors" -> Complement[keys, Keys[forms]],
    "ActivateInstalledRow" -> ListQ[installedRow],
    "AcceptanceRecords" -> acceptanceRecords,
    "ExecutionSettingsIgnored" -> True,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

familyRowGaugeHydrateResume[___] :=
  <|"Status" -> "InvalidResumeHydrationArguments",
    "ActivateInstalledRow" -> False|>;
