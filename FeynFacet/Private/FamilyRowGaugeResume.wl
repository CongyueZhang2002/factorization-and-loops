(* Read-only verification/hydration of materialized row forms from a valid
   strip resume checkpoint.  The sector driver remains the sole checkpoint
   writer: this helper copies saved inputs/caches to an isolated directory,
   replays every recovered strip, and returns in-memory data only after exact
   gauge/form identity gates.  Rational families replay their direct finite-
   field artifacts; multiquadratic families replay each strip in its frame. *)

ClearAll[
  familyRowGaugeResumeHashDirectory,
  familyRowGaugeResumeZeroQ,
  familyRowGaugeResumeFrameCertificateQ,
  familyRowGaugeResumeBlockEquation,
  familyRowGaugeResumeInvalidatedState,
  familyRowGaugeSolverConfiguration,
  familyRowGaugeSolverConfigurationValidQ,
  familyRowGaugeSolverImplementationProvenance,
  familyRowGaugeResumeSolverConfigurationCheck,
  familyRowGaugeSolverFailureSummary,
  familyRowGaugeHydrateResume
];

$familyRowGaugeSolverConfigurationSchema =
  "FeynFacetStripSolverConfiguration";
$familyRowGaugeSolverConfigurationSchemaVersion = 2;
$familyRowGaugeSolverConfigurationRequiredKeys = {
  "Status", "Schema", "SchemaVersion", "Route", "CoefficientField",
  "FinalCheck", "FiniteFieldBackend", "FiniteFieldBackendThreads",
  "PlanDiscoveryBackend", "FrameFingerprint",
  "ImplementationProvenance", "BackendImplementationProvenance",
  "Fingerprint"};

familyRowGaugeSolverImplementationProvenance[route_String] := Module[
  {common, files, hashes, base},
  common = <|
    "FamilyRowGaugeResume.wl" -> FileNameJoin[
      {$feynFacetPrivateDirectory, "FamilyRowGaugeResume.wl"}],
    "FamilyRowGauge.wl" -> FileNameJoin[
      {$feynFacetPrivateDirectory, "FamilyRowGauge.wl"}],
    "family_epsform_sector.wls" -> FileNameJoin[
      {$feynFacetRoot, "Scripts", "family_epsform_sector.wls"}]|>;
  files = Switch[route,
    "ZeroForcing", common,
    "DirectRationalFiniteField", Join[common, <|
      "FiniteFieldStripSolve.wl" -> FileNameJoin[
        {$feynFacetPrivateDirectory, "FiniteFieldStripSolve.wl"}]|>],
    "RationalChartFiniteField", Join[common, <|
      "FiniteFieldStripSolve.wl" -> FileNameJoin[
        {$feynFacetPrivateDirectory, "FiniteFieldStripSolve.wl"}],
      "TransportCharts.wl" -> FileNameJoin[
        {$feynFacetPrivateDirectory, "TransportCharts.wl"}]|>],
    _, Return[$Failed]];
  If[! AllTrue[Values[files], FileExistsQ], Return[$Failed]];
  hashes = Association@KeyValueMap[#1 ->
    FileHash[#2, "SHA256", "HexString"] &, files];
  If[! AllTrue[Values[hashes],
      StringQ[#] && StringLength[#] === 64 &], Return[$Failed]];
  base = Switch[route,
    "ZeroForcing", <|"Solver" -> "ExactZeroGauge",
      "SolverABIVersion" -> 2, "MaterializerABIVersion" -> 1|>,
    "DirectRationalFiniteField", <|
      "Solver" -> "SolveEpsFormStripFiniteField",
      "SolverABIVersion" -> 2, "MaterializerABIVersion" -> 1,
      "EliminationPlanSchemaVersion" -> 1,
      "PlanDiscoveryBackendProtocol" -> "WolframV1",
      "FixedCoreBackendProtocol" -> "CFFA4V1OrWolfram"|>,
    "RationalChartFiniteField", <|
      "Solver" -> "SolveEpsFormStripInFrame/RationalChart",
      "SolverABIVersion" -> 2, "MaterializerABIVersion" -> 1,
      "RootOrderingABIVersion" -> 1,
      "EliminationPlanSchemaVersion" -> 1,
      "PlanDiscoveryBackendProtocol" -> "WolframV1",
      "FixedCoreBackendProtocol" -> "CFFA4V1OrWolfram"|>];
  Join[base, <|"SourceSHA256" -> hashes|>]
];
familyRowGaugeSolverImplementationProvenance[___] := $Failed;

familyRowGaugeSolverConfiguration[route_String,
    coefficientField_String, frame_Association, finalCheck_, backend_,
    backendThreads_, planDiscoveryBackend_] := Module[
  {frameFingerprint, provenance, backendProvenance, payload},
  If[! MemberQ[{"ZeroForcing", "DirectRationalFiniteField",
        "RationalChartFiniteField"}, route] ||
      ! MemberQ[{"Rational", "Multiquadratic"}, coefficientField] ||
      ! MemberQ[{None, "Numerical", "Exact"}, finalCheck] ||
      ! MemberQ[{None, Automatic, "Wolfram", "FLINT"}, backend] ||
      ! (backendThreads === None ||
        IntegerQ[backendThreads] && Between[backendThreads, {1, 4}]) ||
      ! MemberQ[{None, "Wolfram"}, planDiscoveryBackend],
    Return[<|"Status" -> "InvalidSolverConfigurationArguments"|>]];
  If[(route === "DirectRationalFiniteField" &&
        coefficientField =!= "Rational") ||
      (route === "RationalChartFiniteField" &&
        coefficientField =!= "Multiquadratic") ||
      (route === "ZeroForcing" &&
        ! SameQ[{finalCheck, backend, backendThreads,
          planDiscoveryBackend}, {None, None, None, None}]) ||
      (route =!= "ZeroForcing" &&
        (! MemberQ[{"Numerical", "Exact"}, finalCheck] ||
          ! MemberQ[{Automatic, "Wolfram", "FLINT"}, backend] ||
          ! IntegerQ[backendThreads] ||
          planDiscoveryBackend =!= "Wolfram")),
    Return[<|"Status" ->
      "InconsistentSolverConfigurationRoute"|>]];
  frameFingerprint = If[coefficientField === "Multiquadratic",
    Hash[KeySort[KeyTake[frame,
      {"Name", "CoefficientField", "Variables", "Subst", "Roots",
        "Parents"}]], "SHA256", "HexString"], None];
  provenance = familyRowGaugeSolverImplementationProvenance[route];
  If[provenance === $Failed,
    Return[<|"Status" ->
      "SolverImplementationProvenanceUnavailable"|>]];
  backendProvenance = If[route === "ZeroForcing", None,
    finiteFieldStripBackendConfiguration[backend, backendThreads]];
  If[route =!= "ZeroForcing" &&
      Lookup[backendProvenance, "Schema", None] =!=
        "FeynFacetFiniteFieldFixedCoreBackendConfiguration",
    Return[<|"Status" ->
      "BackendImplementationProvenanceUnavailable"|>]];
  payload = <|"Status" -> "OK",
    "Schema" -> $familyRowGaugeSolverConfigurationSchema,
    "SchemaVersion" -> $familyRowGaugeSolverConfigurationSchemaVersion,
    "Route" -> route, "CoefficientField" -> coefficientField,
    "FinalCheck" -> finalCheck, "FiniteFieldBackend" -> backend,
    "FiniteFieldBackendThreads" -> backendThreads,
    "PlanDiscoveryBackend" -> planDiscoveryBackend,
    "FrameFingerprint" -> frameFingerprint,
    "ImplementationProvenance" -> provenance,
    "BackendImplementationProvenance" -> backendProvenance|>;
  Join[payload, <|"Fingerprint" -> Hash[KeySort[payload],
    "SHA256", "HexString"]|>]
];
familyRowGaugeSolverConfiguration[___] :=
  <|"Status" -> "InvalidSolverConfigurationArguments"|>;

familyRowGaugeSolverConfigurationValidQ[configuration_] := Module[
  {route, field, expectedProvenance, expectedBackendProvenance,
   expectedPlanDiscoveryBackend, fingerprint},
  If[! AssociationQ[configuration] ||
      Sort[Keys[configuration]] =!=
        Sort[$familyRowGaugeSolverConfigurationRequiredKeys] ||
      Lookup[configuration, "Status", None] =!= "OK" ||
      Lookup[configuration, "Schema", None] =!=
        $familyRowGaugeSolverConfigurationSchema ||
      Lookup[configuration, "SchemaVersion", None] =!=
        $familyRowGaugeSolverConfigurationSchemaVersion,
    Return[False]];
  {route, field} = Lookup[configuration,
    {"Route", "CoefficientField"}, None];
  expectedProvenance =
    familyRowGaugeSolverImplementationProvenance[route];
  If[expectedProvenance === $Failed, Return[False]];
  expectedBackendProvenance = If[route === "ZeroForcing", None,
    finiteFieldStripBackendConfiguration[
      Lookup[configuration, "FiniteFieldBackend", None],
      Lookup[configuration, "FiniteFieldBackendThreads", None]]];
  expectedPlanDiscoveryBackend = If[route === "ZeroForcing", None,
    "Wolfram"];
  If[! SameQ[Lookup[configuration, "ImplementationProvenance", None],
      expectedProvenance] ||
      ! SameQ[Lookup[configuration,
        "BackendImplementationProvenance", Missing[]],
        expectedBackendProvenance] ||
      Lookup[configuration, "PlanDiscoveryBackend", Missing[]] =!=
        expectedPlanDiscoveryBackend ||
      ! MemberQ[{"Rational", "Multiquadratic"}, field] ||
      (route === "DirectRationalFiniteField" && field =!= "Rational") ||
      (route === "RationalChartFiniteField" &&
        field =!= "Multiquadratic") ||
      (field === "Rational" &&
        Lookup[configuration, "FrameFingerprint", Missing[]] =!= None) ||
      (field === "Multiquadratic" &&
        (! StringQ[Lookup[configuration, "FrameFingerprint", None]] ||
          StringLength[configuration["FrameFingerprint"]] =!= 64)) ||
      (route === "ZeroForcing" &&
        ! SameQ[Lookup[configuration,
          {"FinalCheck", "FiniteFieldBackend",
            "FiniteFieldBackendThreads", "PlanDiscoveryBackend"},
          Missing[]], {None, None, None, None}]) ||
      (route =!= "ZeroForcing" &&
        (! MemberQ[{"Numerical", "Exact"},
            Lookup[configuration, "FinalCheck", None]] ||
          ! MemberQ[{Automatic, "Wolfram", "FLINT"},
            Lookup[configuration, "FiniteFieldBackend", None]] ||
          ! IntegerQ[Lookup[configuration,
            "FiniteFieldBackendThreads", None]] ||
          ! Between[configuration["FiniteFieldBackendThreads"],
            {1, 4}])),
    Return[False]];
  fingerprint = Hash[KeySort[KeyDrop[configuration, "Fingerprint"]],
    "SHA256", "HexString"];
  StringQ[configuration["Fingerprint"]] &&
    StringLength[configuration["Fingerprint"]] === 64 &&
    configuration["Fingerprint"] === fingerprint
];
familyRowGaugeSolverConfigurationValidQ[___] := False;

(* Missing configurations are accepted only for computations that cannot
   select another solver (zero forcing) or for the historical in-frame
   rational-chart route.  A legacy direct-rational checkpoint is recomputed. *)
familyRowGaugeResumeSolverConfigurationCheck[summary_Association,
    expected_Association] := Module[{saved, method, route},
  If[! familyRowGaugeSolverConfigurationValidQ[expected],
    Return[<|"Status" ->
      "ExpectedSolverConfigurationInvalid"|>]];
  saved = Lookup[summary, "SolverConfiguration",
    Missing["LegacyCheckpoint"]];
  If[KeyExistsQ[summary, "SolverConfiguration"],
    If[! AssociationQ[saved],
      Return[<|"Status" ->
        "ResumeSolverConfigurationInvalid"|>]];
    Return[If[familyRowGaugeSolverConfigurationValidQ[saved] &&
        SameQ[saved, expected],
      <|"Status" -> "OK", "Mode" -> "Exact"|>,
      <|"Status" -> "ResumeSolverConfigurationMismatch"|>]]];
  method = Lookup[summary, "Method", None];
  route = expected["Route"];
  Which[
    route === "ZeroForcing" && method === "ZeroForcing",
      <|"Status" -> "OK", "Mode" -> "LegacyZeroForcing"|>,
    route === "RationalChartFiniteField" && StringQ[method] &&
      (StringStartsQ[method, "RationalChart/"] ||
        StringStartsQ[method, "RationalFrame/"]),
      <|"Status" -> "OK", "Mode" -> "LegacyRationalChart"|>,
    True, <|"Status" -> "ResumeSolverConfigurationMissing"|>]
];
familyRowGaugeResumeSolverConfigurationCheck[___] :=
  <|"Status" -> "ResumeSolverConfigurationInvalid"|>;

(* Persist only a fixed diagnostic whitelist, with a 4096-byte ceiling per
   value.  Gauges, samples, matrices, and inner solutions are excluded. *)
familyRowGaugeSolverFailureSummary[candidate_] := Module[
  {keys, bounded, diagnostics, status},
  keys = {"Method", "RootIndices", "RootSquares", "RadicalBases",
    "UnclassifiedRadicalBases", "CoefficientField",
    "BackendRequested", "BackendUsed", "BackendFallbackReason",
    "BackendFailure", "PlanValidationStatus",
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "StructuralFailureReasons", "Certificate"};
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

familyRowGaugeResumeHashDirectory[directory_] := If[DirectoryQ[directory],
  Association@Table[
    FileNameTake[file] -> FileHash[file, "SHA256", "HexString"],
    {file, Sort[FileNames["*.wl", directory]]}], <||>];

familyRowGaugeResumeZeroQ[value_] :=
  AllTrue[Flatten[value], SameQ[#, 0] &];

familyRowGaugeResumeFrameCertificateQ[solution_Association] := Module[
  {method = Lookup[solution, "Method", None], certificate},
  If[method === "ZeroForcing",
    Return[TrueQ[Lookup[solution, "ExactDLog", False]]]];
  certificate = Lookup[solution, "FrameCertificate", <||>];
  If[! AssociationQ[certificate] || ! StringQ[method], Return[False]];
  Which[
    StringStartsQ[method, "RationalFrame/"],
      Lookup[solution, "RootIndices", Missing["NoRootIndices"]] === {} &&
        Lookup[certificate, "Chart", Missing["NoChart"]] === None &&
        And @@ (TrueQ[Lookup[certificate, #, False]] & /@
          {"GaugeRoundTrip", "TransformedOneFormPullBack", "Exact"}),
    StringStartsQ[method, "RationalChart/"],
      MatchQ[Lookup[solution, "RootIndices", {}], {__Integer}] &&
        And @@ (TrueQ[Lookup[certificate, #, False]] & /@
          {"CoordinateComposition", "GaugeRoundTrip",
           "TransformedOneFormPullBack", "SourceDLog", "Exact"}),
    True, False]
];
familyRowGaugeResumeFrameCertificateQ[_] := False;

(* Source-identical semantics to the sector driver's blockEquation. *)
familyRowGaugeResumeBlockEquation[connection_List, sector_Integer,
    lowerSector_Integer, solvedBlocks_Association, ranges_List,
    epsilon_Symbol] := Module[{rk = ranges[[sector]],
    rj = ranges[[lowerSector]], higher},
  higher = Select[Keys[solvedBlocks], lowerSector < # < sector &];
  {
    Table[Map[Together[#/epsilon] &,
      connection[[mu, rk, rk]], {2}], {mu, 2}],
    Table[Map[Together[#/epsilon] &,
      connection[[mu, rj, rj]], {2}], {mu, 2}],
    Table[Map[Together,
      connection[[mu, rk, rj]] -
        Sum[solvedBlocks[m] .
          connection[[mu, ranges[[m]], rj]], {m, higher}],
      {2}], {mu, 2}]
  }
];

(* One typed replay failure invalidates the complete recovered suffix.  Keep
   this reset payload in the package so the sector driver and focused tests use
   exactly the same fail-closed state transition. *)
familyRowGaugeResumeInvalidatedState[rowSize_Integer?Positive] := <|
  "PrevD" -> ConstantArray[{}, rowSize], "SolvedBlocks" -> <||>,
  "SolvedForms" -> <||>, "StripSolvers" -> {},
  "InstalledRow" -> Automatic|>;
familyRowGaugeResumeInvalidatedState[___] := $Failed;

Options[familyRowGaugeHydrateResume] = {
  "KernelCount" -> 1,
  "FinalCheck" -> "Numerical",
  "FiniteFieldBackend" -> Automatic,
  "FiniteFieldBackendThreads" -> 2,
  "PlanDiscoveryBackend" -> "Wolfram",
  "MinimumCachedPrimeCount" -> 3,
  "Verbose" -> False
};

familyRowGaugeHydrateResume[
    checkpoint_Association, checkpointFile_String,
    solvedBlocks_Association, existingForms_Association,
    family_String, sector_Integer?Positive,
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    frame_Association, ranges_List, scratch_String,
    currentConnection : {_List, _List}, OptionsPattern[]] := Module[
  {tag = Unique["rowGaugeResume"], workRoot, result, missing,
   forms = existingForms, keys, rowSize, lowerSize, blockColumns,
   installedRow = Automatic, replayRecords = {}, stripSolvers,
   kernelCount = OptionValue["KernelCount"],
   finalCheck = OptionValue["FinalCheck"],
   finiteFieldBackend = OptionValue["FiniteFieldBackend"],
   finiteFieldBackendThreads = OptionValue["FiniteFieldBackendThreads"],
   planDiscoveryBackend = OptionValue["PlanDiscoveryBackend"],
   minimumCached = OptionValue["MinimumCachedPrimeCount"],
   verbose = TrueQ[OptionValue["Verbose"]], diskCheckpoint,
   expectedConnectionHash, currentTruncation, currentConnectionHash,
   checkpointForms, lowerBlockSizes, reconstructedPrevD,
   fullCoverageQ, formsShapeQ, resultStatus, nk, coefficientField,
   algebraicFrameQ, expectedSolverConfiguration,
   solverConfigurationCheck,
   started = AbsoluteTime[]},

  If[! IntegerQ[kernelCount] || kernelCount < 1 ||
      ! MemberQ[{"Numerical", "Exact"}, finalCheck] ||
      ! MemberQ[{Automatic, "Wolfram", "FLINT"}, finiteFieldBackend] ||
      ! IntegerQ[finiteFieldBackendThreads] ||
      ! Between[finiteFieldBackendThreads, {1, 4}] ||
      planDiscoveryBackend =!= "Wolfram" ||
      ! IntegerQ[minimumCached] || minimumCached < 1 ||
      ! MatchQ[ranges, {{__Integer} ..}] ||
      ! MatchQ[Dimensions[currentConnection], {2, _Integer, _Integer}] ||
      Dimensions[currentConnection][[2]] =!=
        Dimensions[currentConnection][[3]] ||
      sector > Length[ranges],
    Return[<|"Status" -> "InvalidResumeHydrationArguments",
      "ActivateInstalledRow" -> False|>]];
  coefficientField = Lookup[frame, "CoefficientField", "Rational"];
  If[! MemberQ[{"Rational", "Multiquadratic"}, coefficientField],
    Return[<|"Status" -> "InvalidResumeHydrationCoefficientField",
      "CoefficientField" -> coefficientField,
      "ActivateInstalledRow" -> False|>]];
  algebraicFrameQ = coefficientField === "Multiquadratic";
  nk = Last[ranges[[sector]]];
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
  currentConnectionHash = Hash[currentTruncation,
    "SHA256", "HexString"];
  If[! SameQ[diskCheckpoint, checkpoint] ||
      ! StringQ[expectedConnectionHash] ||
      currentConnectionHash =!= expectedConnectionHash,
    Return[<|"Status" -> "ResumeHydrationCheckpointIdentityMismatch",
      "DiskSameQ" -> SameQ[diskCheckpoint, checkpoint],
      "CurrentConnectionHashSameQ" ->
        (currentConnectionHash === expectedConnectionHash),
      "ActivateInstalledRow" -> False|>]];

  checkpointForms = Lookup[checkpoint, "SolvedForms", <||>];
  If[! AssociationQ[checkpointForms] ||
      ! SameQ[forms, checkpointForms],
    Return[<|"Status" -> "ResumeHydrationSolvedFormsMismatch",
      "ActivateInstalledRow" -> False|>]];
  keys = Sort[Keys[solvedBlocks]];
  rowSize = Length[ranges[[sector]]];
  lowerSize = First[ranges[[sector]]] - 1;
  blockColumns = Association@Table[key -> ranges[[key]], {key, keys}];
  stripSolvers = Lookup[checkpoint, "StripSolvers", {}];
  lowerBlockSizes = Length /@ ranges[[Range[sector - 1]]];
  If[Lookup[checkpoint, "Sector", Missing["NoSector"]] =!= sector ||
      Lookup[checkpoint, "SubSize", Missing["NoSubSize"]] =!= rowSize ||
      Lookup[checkpoint, "Truncation", Missing["NoTruncation"]] =!= nk ||
      ! familyRowGaugeCheckpointGaugeShapeQ[
        Lookup[checkpoint, "PrevD", None], rowSize, lowerBlockSizes] ||
      ! familyRowGaugeCheckpointStripSolversQ[
        stripSolvers, Lookup[checkpoint, "PrevD", None], sector,
        lowerBlockSizes],
    Return[<|"Status" -> "ResumeHydrationCheckpointMetadataInvalid",
      "ActivateInstalledRow" -> False|>]];
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

  missing = Complement[keys, Keys[forms]];
  fullCoverageQ = keys === Range[sector - 1];
  formsShapeQ[candidate_Association] :=
    Sort[Keys[candidate]] === keys && AllTrue[keys,
      Dimensions[Lookup[candidate, #, Missing["NoForm"]]] ===
          {2, rowSize, Length[ranges[[#]]]} &&
        FreeQ[Lookup[candidate, #],
          Alternatives[_Missing, Automatic, $Failed]] &];

  workRoot = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
    "FeynFacet-row-gauge-resume-" <> CreateUUID[]}]];
  result = Catch[
    Do[Module[{stripTag, sourceInput, copiedInput, sourceArtifacts,
        copiedArtifacts, input, expectedStrip, expectedGauge, dimensions,
        summary, summaryMethod, zeroQ, solverRoute, artifactCount,
        beforeHashes, afterHashes,
        seconds, solution, gauge, frameQ, solvedForm, existingForm,
        replayAction, extraLetters, directRecord, replayRoute},
      stripTag = family <> "_" <> ToString[sector] <> "_" <>
        ToString[lowerSector];
      sourceInput = FileNameJoin[{scratch, stripTag <> "_input.wl"}];
      copiedInput = FileNameJoin[{workRoot, stripTag <> "_input.wl"}];
      replayRoute = If[algebraicFrameQ, "InFrame", "DirectFiniteField"];
      sourceArtifacts = If[algebraicFrameQ,
        FileNameJoin[{scratch, stripTag <> "_finite_field"}],
        FileNameJoin[{scratch, "finite_field_" <> ToString[sector] <>
          "_" <> ToString[lowerSector]}]];
      copiedArtifacts = If[algebraicFrameQ,
        FileNameJoin[{workRoot, stripTag <> "_finite_field"}],
        FileNameJoin[{workRoot, "finite_field_" <> ToString[sector] <>
          "_" <> ToString[lowerSector]}]];
      If[! FileExistsQ[sourceInput],
        Throw[<|"Status" -> "ResumeHydrationInputMissing",
          "LowerSector" -> lowerSector|>, tag]];
      CopyFile[sourceInput, copiedInput];
      input = FeynFacet`FamilyArtifactRead[copiedInput];
      If[! AssociationQ[input] ||
          Lookup[input, "Family", None] =!= family ||
          Lookup[input, "Sector", None] =!= sector ||
          Lookup[input, "LowerSector", None] =!= lowerSector ||
          ! SameQ[Lookup[input, "Variables", None], variables] ||
          ! SameQ[Lookup[input, "Regulator", None], epsilon] ||
          ! MatchQ[Lookup[input, "Strip", None], {_List, _List, _List}],
        Throw[<|"Status" -> "ResumeHydrationInputIdentityMismatch",
          "LowerSector" -> lowerSector|>, tag]];
      expectedStrip = familyRowGaugeResumeBlockEquation[
        currentConnection, sector, lowerSector, solvedBlocks, ranges,
        epsilon];
      If[! SameQ[input["Strip"], expectedStrip],
        Throw[<|"Status" -> "ResumeHydrationInputConnectionMismatch",
          "LowerSector" -> lowerSector|>, tag]];
      expectedGauge = Lookup[solvedBlocks, lowerSector,
        Missing["MissingCheckpointGauge"]];
      dimensions = Dimensions[expectedGauge];
      summary = SelectFirst[stripSolvers,
        Lookup[#, "Sector", None] === sector &&
          Lookup[#, "LowerSector", None] === lowerSector &,
        Missing["NoStripSolverSummary"]];
      If[MissingQ[summary],
        Throw[<|"Status" -> "ResumeHydrationSummaryMissing",
          "LowerSector" -> lowerSector|>, tag]];
      (* Legacy summaries predate this field.  Their ordinary ansatz is {},
         while an obstruction-widened legacy cache will not match and the
         replay fails closed to sparse propagation in the sector driver. *)
      extraLetters = Lookup[summary, "ExtraLetters", {}];
      If[! ListQ[extraLetters],
        Throw[<|"Status" -> "ResumeHydrationSummaryExtraLettersInvalid",
          "LowerSector" -> lowerSector|>, tag]];
      zeroQ = familyRowGaugeResumeZeroQ[input["Strip"][[3]]];
      summaryMethod = Lookup[summary, "Method", None];
      solverRoute = Which[
        summaryMethod === "ZeroForcing" && zeroQ, "ZeroForcing",
        summaryMethod === "ZeroForcing",
          Throw[<|"Status" -> "ResumeZeroForcingInputMismatch",
            "LowerSector" -> lowerSector|>, tag],
        algebraicFrameQ, "RationalChartFiniteField",
        True, "DirectRationalFiniteField"];
      expectedSolverConfiguration = familyRowGaugeSolverConfiguration[
        solverRoute, coefficientField, frame,
        If[solverRoute === "ZeroForcing", None, finalCheck],
        If[solverRoute === "ZeroForcing", None, finiteFieldBackend],
        If[solverRoute === "ZeroForcing", None,
          finiteFieldBackendThreads],
        If[solverRoute === "ZeroForcing", None,
          planDiscoveryBackend]];
      solverConfigurationCheck =
        familyRowGaugeResumeSolverConfigurationCheck[
          summary, expectedSolverConfiguration];
      If[Lookup[solverConfigurationCheck, "Status", None] =!= "OK",
        Throw[<|"Status" -> solverConfigurationCheck["Status"],
          "LowerSector" -> lowerSector,
          "ExpectedSolverConfigurationFingerprint" ->
            Lookup[expectedSolverConfiguration, "Fingerprint", None],
          "SavedSolverConfigurationFingerprint" -> Lookup[
            Lookup[summary, "SolverConfiguration", <||>],
            "Fingerprint", None]|>, tag]];
      artifactCount = If[DirectoryQ[sourceArtifacts],
        Length[FileNames[stripTag <> "_mod_*.wl", sourceArtifacts]], 0];
      If[solverRoute =!= "ZeroForcing" && artifactCount < minimumCached,
        Throw[<|"Status" -> "ResumeHydrationArtifactsInsufficient",
          "LowerSector" -> lowerSector, "Count" -> artifactCount|>, tag]];
      If[DirectoryQ[sourceArtifacts],
        CopyDirectory[sourceArtifacts, copiedArtifacts]];
      beforeHashes = familyRowGaugeResumeHashDirectory[copiedArtifacts];
      If[verbose, Print["  resume hydration strip ",
        {sector, lowerSector}, ": zero=", zeroQ,
        ", cached=", artifactCount]];
      directRecord = Join[input, <|"ExtraLetters" -> extraLetters|>];
      {seconds, solution} = AbsoluteTiming[Which[
        solverRoute === "ZeroForcing",
          <|"Status" -> "Solved", "Method" -> "ZeroForcing",
            "Gauge" -> ConstantArray[0, dimensions],
            "ExactDLog" -> True|>,
        algebraicFrameQ,
          FeynFacet`SolveEpsFormStripInFrame[
            input["Strip"], variables, epsilon, frame,
            "FiniteFieldFirst" -> True,
            "FiniteFieldOptions" -> {
              "KernelCount" -> kernelCount,
              "FinalCheck" -> finalCheck,
              "Backend" -> finiteFieldBackend,
              "BackendThreads" -> finiteFieldBackendThreads,
              "PlanDiscoveryBackend" -> planDiscoveryBackend,
              "Verbose" -> verbose},
            "ScratchDirectory" -> workRoot,
            "Tag" -> stripTag, "Verbose" -> verbose],
        True,
          FeynFacet`SolveEpsFormStripFiniteField[directRecord,
            "KernelCount" -> kernelCount,
            "Backend" -> finiteFieldBackend,
            "BackendThreads" -> finiteFieldBackendThreads,
            "PlanDiscoveryBackend" -> planDiscoveryBackend,
            "ArtifactDirectory" -> copiedArtifacts,
            "ArtifactPrefix" -> stripTag,
            "FinalCheck" -> finalCheck, "Verbose" -> verbose]]];
      afterHashes = familyRowGaugeResumeHashDirectory[copiedArtifacts];
      If[! AssociationQ[solution] ||
          Lookup[solution, "Status", None] =!= "Solved" ||
          ! If[finalCheck === "Exact",
              TrueQ[Lookup[solution, "ExactDLog", False]],
              TrueQ[Lookup[solution, "ExactDLog", False]] ||
                Lookup[solution, "Certificate", None] ===
                  "NumericalResidual"],
        Throw[<|"Status" -> "ResumeHydrationSolveFailed",
          "LowerSector" -> lowerSector|>, tag]];
      gauge = Lookup[solution, "Gauge", Missing["NoGauge"]];
      frameQ = If[algebraicFrameQ,
        familyRowGaugeResumeFrameCertificateQ[solution], True];
      If[! SameQ[gauge, expectedGauge] || ! frameQ ||
          Lookup[solution, "Method", None] =!=
            Lookup[summary, "Method", None] ||
          beforeHashes =!= afterHashes,
        Throw[<|"Status" -> "ResumeHydrationReplayIdentityFailed",
          "LowerSector" -> lowerSector,
          "GaugeSameQ" -> SameQ[gauge, expectedGauge],
          "FrameCertificate" -> frameQ,
          "MethodSameQ" -> (Lookup[solution, "Method", None] ===
            Lookup[summary, "Method", None]),
          "CopiedArtifactsUnchanged" ->
            (beforeHashes === afterHashes)|>, tag]];
      solvedForm = familyRowGaugeDLogForm[
        solution, variables, epsilon, dimensions];
      If[! ListQ[solvedForm] ||
          Dimensions[solvedForm] =!= Prepend[dimensions, 2] ||
          ! FreeQ[solvedForm, Alternatives[_Missing, Automatic, $Failed]],
        Throw[<|"Status" -> "ResumeHydrationFormInvalid",
          "LowerSector" -> lowerSector|>, tag]];
      existingForm = Lookup[forms, lowerSector,
        Missing["NoExistingForm"]];
      replayAction = If[MissingQ[existingForm], "HydratedMissing",
        If[! SameQ[existingForm, solvedForm],
          Throw[<|
            "Status" -> "ResumeHydrationExistingFormReplayMismatch",
            "LowerSector" -> lowerSector,
            "ExistingFormSHA256" -> Hash[existingForm,
              "SHA256", "HexString"],
            "ReplayedFormSHA256" -> Hash[solvedForm,
              "SHA256", "HexString"]|>, tag]];
        "VerifiedExisting"];
      AssociateTo[forms, lowerSector -> solvedForm];
      AppendTo[replayRecords, <|"LowerSector" -> lowerSector,
        "Action" -> replayAction, "Route" -> replayRoute,
        "InputSHA256" -> FileHash[copiedInput, "SHA256", "HexString"],
        "CheckpointStripSameQ" -> True,
        "ZeroForcing" -> zeroQ, "CachedPrimeCount" -> artifactCount,
        "Seconds" -> seconds, "Method" -> solution["Method"],
        "SolverConfigurationMode" -> solverConfigurationCheck["Mode"],
        "SolverConfigurationFingerprint" ->
          expectedSolverConfiguration["Fingerprint"],
        "Certificate" -> Lookup[solution, "Certificate", None],
        "ExactDLog" -> Lookup[solution, "ExactDLog", False],
        "GaugeSameQ" -> True, "FrameCertificate" -> True,
        "CopiedArtifactsUnchanged" -> True,
        "SolvedFormDimensions" -> Dimensions[solvedForm],
        "SolvedFormSHA256" -> Hash[solvedForm,
          "SHA256", "HexString"]|>]],
      {lowerSector, keys}];
    If[! formsShapeQ[forms],
      Throw[<|"Status" -> "ResumeHydrationFormsInvalid"|>, tag]];
    If[fullCoverageQ,
      installedRow = familyRowGaugeAssembleInstalledRow[
        forms, solvedBlocks, rowSize, lowerSize, blockColumns];
      If[! ListQ[installedRow] ||
          Dimensions[installedRow] =!= {2, rowSize, lowerSize} ||
          ! FreeQ[installedRow,
            Alternatives[_Missing, Automatic, $Failed]],
        Throw[<|"Status" -> "ResumeHydrationAssemblyFailed"|>, tag]]];
    resultStatus = Which[
      missing === {} && fullCoverageQ, "Verified",
      missing === {}, "VerifiedPartial",
      fullCoverageQ, "Hydrated",
      True, "HydratedPartial"];
    <|"Status" -> resultStatus,
      "SolvedForms" -> forms, "InstalledRow" -> installedRow,
      "MissingLowerSectors" -> missing,
      "ActivateInstalledRow" -> fullCoverageQ,
      "ReplayRecords" -> replayRecords,
      "Seconds" -> N[AbsoluteTime[] - started]|>,
    tag, #1 &];
  If[DirectoryQ[workRoot],
    Quiet[DeleteDirectory[workRoot, DeleteContents -> True]]];
  If[AssociationQ[result] &&
      MemberQ[{"Hydrated", "HydratedPartial", "Verified",
        "VerifiedPartial"},
        Lookup[result, "Status", None]], result,
    Join[If[AssociationQ[result], result,
      <|"Status" -> "ResumeHydrationInternalFailure"|>],
      <|"ActivateInstalledRow" -> False|>]]
];

familyRowGaugeHydrateResume[___] :=
  <|"Status" -> "InvalidResumeHydrationArguments",
    "ActivateInstalledRow" -> False|>;
