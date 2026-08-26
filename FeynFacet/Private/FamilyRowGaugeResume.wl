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
  familyRowGaugeStripInputSeal,
  familyRowGaugeStripInputSealFingerprint,
  familyRowGaugeStripInputSealVerdict,
  familyRowGaugeResumeModularImageValue,
  familyRowGaugeResumeModularGate,
  familyRowGaugeFamilyDeadlineDecision,
  familyRowGaugeStaleStopMigration,
  $familyRowGaugeResolvableStops,
  $familyRowGaugeStripInputSealSchema,
  $familyRowGaugeStripInputSealSchemaV1,
  $familyRowGaugeStripInputSealKeys,
  $familyRowGaugeResumeGateImages,
  familyRowGaugeSolverConfiguration,
  familyRowGaugeSolverConfigurationValidQ,
  familyRowGaugeSolverImplementationProvenance,
  familyRowGaugeProvenanceDriverPaths,
  familyRowGaugeResumeSolverConfigurationCheck,
  familyRowGaugeSolverConfigurationDifference,
  familyRowGaugeSolverFailureSummary,
  familyRowGaugeHydrateResume
];

$familyRowGaugeSolverConfigurationSchema =
  "FeynFacetStripSolverConfiguration";
(* Version 3 (generality pass 2026-08-23, B2): the implementation
   provenance hashes ONLY the package's own Private sources; a driver
   passes its own identity through the "DriverProvenance" option, which is
   carried in the sealed configuration and re-verified on resume.  A
   version-2 checkpoint carries the field "SolverConfiguration" and is
   therefore refused by familyRowGaugeSolverConfigurationValidQ (version
   mismatch) and reported as ResumeSolverConfigurationMismatch, i.e.
   recomputed rather than trusted -- the legacy branch of
   familyRowGaugeResumeSolverConfigurationCheck is reached only by
   checkpoints that have no configuration field at all. *)
$familyRowGaugeSolverConfigurationSchemaVersion = 3;
$familyRowGaugeSolverConfigurationRequiredKeys = {
  "Status", "Schema", "SchemaVersion", "Route", "CoefficientField",
  "FinalCheck", "FiniteFieldBackend", "FiniteFieldBackendThreads",
  "PlanDiscoveryBackend", "FrameFingerprint",
  "ImplementationProvenance", "BackendImplementationProvenance",
  "Fingerprint"};

Options[familyRowGaugeSolverImplementationProvenance] = {
  (* <|name -> absolute path|> of the files that make up the CALLING
     driver.  The package hashes only its own sources; a campaign script
     that participates in the solve declares itself here, so the package
     carries no knowledge of any driver's location (generality pass
     2026-08-23, B2). *)
  "DriverProvenance" -> <||>
};

familyRowGaugeSolverImplementationProvenance[route_String,
    OptionsPattern[]] := Module[
  {common, files, hashes, base, driver, driverHashes},
  driver = OptionValue["DriverProvenance"];
  If[! AssociationQ[driver] ||
      ! AllTrue[Keys[driver], StringQ] ||
      ! AllTrue[Values[driver], StringQ],
    Return[$Failed]];
  If[! AllTrue[Values[driver], FileExistsQ], Return[$Failed]];
  driverHashes = Association @ KeyValueMap[
    #1 -> <|"Path" -> #2,
      "SHA256" -> FileHash[#2, "SHA256", "HexString"]|> &, driver];
  If[! AllTrue[Values[driverHashes],
      StringQ[#["SHA256"]] && StringLength[#["SHA256"]] === 64 &],
    Return[$Failed]];
  common = <|
    "FamilyRowGaugeResume.wl" -> FileNameJoin[
      {$feynFacetPrivateDirectory, "FamilyRowGaugeResume.wl"}],
    "FamilyRowGauge.wl" -> FileNameJoin[
      {$feynFacetPrivateDirectory, "FamilyRowGauge.wl"}]|>;
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
  Join[base, <|"SourceSHA256" -> hashes,
    "DriverProvenance" -> driverHashes|>]
];
familyRowGaugeSolverImplementationProvenance[___] := $Failed;

(* the driver files a sealed provenance record names, as name -> path, so
   a resume can re-hash exactly the same set *)
familyRowGaugeProvenanceDriverPaths[provenance_] := Module[{driver},
  If[! AssociationQ[provenance], Return[$Failed]];
  driver = Lookup[provenance, "DriverProvenance", Missing[]];
  If[! AssociationQ[driver], Return[$Failed]];
  If[driver === <||>, Return[<||>]];
  If[! AllTrue[Values[driver],
      AssociationQ[#] && StringQ[Lookup[#, "Path", None]] &],
    Return[$Failed]];
  Association @ KeyValueMap[#1 -> #2["Path"] &, driver]
];

Options[familyRowGaugeSolverConfiguration] =
  Options[familyRowGaugeSolverImplementationProvenance];

familyRowGaugeSolverConfiguration[route_String,
    coefficientField_String, frame_Association, finalCheck_, backend_,
    backendThreads_, planDiscoveryBackend_, OptionsPattern[]] := Module[
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
  provenance = familyRowGaugeSolverImplementationProvenance[route,
    "DriverProvenance" -> OptionValue["DriverProvenance"]];
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
   expectedPlanDiscoveryBackend, fingerprint, driverPaths},
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
  (* the driver files the record names are re-hashed from their recorded
     paths: a changed (or vanished) driver source makes the expected
     provenance differ from the sealed one, and the checkpoint is
     recomputed rather than trusted *)
  driverPaths = familyRowGaugeProvenanceDriverPaths[
    Lookup[configuration, "ImplementationProvenance", None]];
  If[driverPaths === $Failed, Return[False]];
  expectedProvenance =
    familyRowGaugeSolverImplementationProvenance[route,
      "DriverProvenance" -> driverPaths];
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

(* WHY a resume was refused (Codex 06:30).  The refusal itself is
   correct and must never be relaxed; what was missing is the evidence
   to tell an ABI invalidation (the implementation provenance changed,
   so every stored gauge is stale) from an overly broad fingerprint (a
   diagnostic key drifted and forced a needless full-row replay).  Both
   configurations are already sealed Associations, so the difference is
   a key comparison: bounded to 16 keys, and each value is shown only if
   it is small -- a configuration carries a "DriverProvenance" map and a
   frame fingerprint that have no place in a refusal record. *)
$familyRowGaugeDifferenceValueByteCeiling = 512;
$familyRowGaugeDifferenceKeyCeiling = 16;
familyRowGaugeSolverConfigurationDifference[saved_, expected_] := Module[
  {keys, differing, boundedValue},
  If[! AssociationQ[saved] || ! AssociationQ[expected],
    Return[<|"DifferingKeys" -> Missing["ConfigurationNotAnAssociation"],
      "SavedFingerprint" -> Missing["NotAnAssociation"],
      "ExpectedFingerprint" -> Missing["NotAnAssociation"]|>]];
  keys = DeleteCases[DeleteDuplicates[Join[Keys[saved], Keys[expected]]],
    "Fingerprint"];
  differing = Select[keys, ! SameQ[Lookup[saved, #1, Missing["Absent"]],
    Lookup[expected, #1, Missing["Absent"]]] &];
  boundedValue[value_] := If[ByteCount[value] >
    $familyRowGaugeDifferenceValueByteCeiling,
    Missing["ValueTooLargeForDiagnostic"], value];
  <|"DifferingKeys" ->
      Take[differing, UpTo[$familyRowGaugeDifferenceKeyCeiling]],
    "DifferingKeyCount" -> Length[differing],
    "DifferingValues" -> Association[
      (#1 -> <|"Saved" -> boundedValue[Lookup[saved, #1, Missing["Absent"]]],
        "Expected" -> boundedValue[Lookup[expected, #1, Missing["Absent"]]]|>) & /@
        Take[differing, UpTo[$familyRowGaugeDifferenceKeyCeiling]]],
    "SavedFingerprint" -> Lookup[saved, "Fingerprint", Missing["NoFingerprint"]],
    "ExpectedFingerprint" ->
      Lookup[expected, "Fingerprint", Missing["NoFingerprint"]],
    "SavedConfigurationValid" ->
      familyRowGaugeSolverConfigurationValidQ[saved]|>
];
familyRowGaugeSolverConfigurationDifference[___] :=
  <|"DifferingKeys" -> Missing["InvalidArguments"]|>;

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
      (* Codex 06:30, operational finding: the refusal is correct and
         fails closed, but it used to expose nothing about WHY.  A
         bounded DifferingKeys list plus the two configuration
         fingerprints shows whether a full-row replay was a required ABI
         invalidation or an overly broad fingerprint -- without ever
         accepting an incompatible checkpoint. *)
      Join[<|"Status" -> "ResumeSolverConfigurationMismatch"|>,
        familyRowGaugeSolverConfigurationDifference[saved, expected]]]]];
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

(* ---- THE STRIP-INPUT SEAL AND THE MODULAR RESUME GATE --------------
   (2026-08-25; Codex 14:30 integrity layer, steps 2-4 of 4)

   Step 1 -- the sector driver writes a sidecar seal beside every strip
   input, recording the connection, the position, the solved-block
   prefix and the exact strip -- landed on 2026-08-25 and was RECORDED
   ONLY: the resume still re-derived the whole symbolic block equation
   for every banked strip to prove the same thing, which is what left
   CF303 sector 17 silent for more than 40 minutes.

   What lands here:

     step 2  the seal carries its own FINGERPRINT over every digest it
             asserts, and a resume RECOMPUTES that fingerprint from the
             hydrated record instead of comparing the digests one by
             one.  A seal whose fields were edited without re-deriving
             the fingerprint is refused; a V1 seal (no fingerprint at
             all) is refused-typed and never upgraded, exactly like the
             V1 forcing-channel seal in the strip module;

     step 3  the resumed gauge candidate is evaluated at TWO fresh
             finite-field images against the forcing recomputed from the
             current connection.  The relation checked is the same one
             the exact reconstruction checks -- the strip input on disk
             IS the block equation the current connection and the banked
             prefix imply -- but every operation is a modular evaluation
             at a point, so no symbolic normalization of a 60 MB
             connection happens at all.  The images are independent
             (different primes AND different regulator values), and an
             image at which any denominator vanishes is INADMISSIBLE and
             replaced rather than counted;

     step 4  a mismatch at an admissible image is a typed
             "ResumeRejected" naming that image; it is never repaired
             and never retried into acceptance.

   The exact reconstruction stays available and is the DEFAULT
   companion, not a replacement: "ResumeGate" -> "ModularThenExact"
   (the default) runs the gate for its evidence and still re-derives;
   "Modular" is the mode that skips re-derivation once a seal
   authenticates AND both images agree; "Exact" is the pre-2026-08-25
   behaviour.  Choosing "Modular" for a campaign is a measured decision,
   which is why it is not the default. *)
$familyRowGaugeStripInputSealSchemaV1 = "FamilyStripInputSealV1";
$familyRowGaugeStripInputSealSchema = "FamilyStripInputSealV2";

(* the digests a seal asserts, in a fixed order; the fingerprint is over
   exactly these and over nothing else, so a reader can recompute it *)
$familyRowGaugeStripInputSealKeys = {"Schema", "SchemaVersion", "Family",
  "Sector", "LowerSector", "Truncation", "ConnectionHash",
  "SolvedBlockPrefixHash", "SolvedBlockKeys", "StripHash", "VariablesHash",
  "WriterSourceSHA256"};

familyRowGaugeStripInputSealFingerprint[seal_Association] :=
  Hash[Lookup[seal, $familyRowGaugeStripInputSealKeys,
    Missing["AbsentSealField"]], "SHA256", "HexString"];
familyRowGaugeStripInputSealFingerprint[___] := $Failed;

familyRowGaugeStripInputSeal[family_String, sector_Integer,
    lowerSector_Integer, truncation_Integer, connectionHash_String,
    solvedBlocks_Association, stripHash_String, variablesHash_String,
    writerSourceSHA256_] := Module[{payload},
  payload = <|"Schema" -> $familyRowGaugeStripInputSealSchema,
    "SchemaVersion" -> 2,
    "Family" -> family, "Sector" -> sector, "LowerSector" -> lowerSector,
    "Truncation" -> truncation,
    "ConnectionHash" -> connectionHash,
    "SolvedBlockPrefixHash" -> Hash[KeySort[solvedBlocks], "SHA256",
      "HexString"],
    "SolvedBlockKeys" -> Sort[Keys[solvedBlocks]],
    "StripHash" -> stripHash,
    "VariablesHash" -> variablesHash,
    "WriterSourceSHA256" -> writerSourceSHA256|>;
  Join[payload,
    <|"Fingerprint" -> familyRowGaugeStripInputSealFingerprint[payload],
      "WrittenAt" -> DateString[]|>]
];
familyRowGaugeStripInputSeal[___] := $Failed;

(* step 2.  A single typed verdict string; the caller records it. *)
familyRowGaugeStripInputSealVerdict[seal_, family_, sector_Integer,
    lowerSector_Integer, truncation_Integer, connectionHash_,
    solvedBlocks_Association, stripHash_] := Which[
  ! AssociationQ[seal], "Unsealed",
  Lookup[seal, "Schema", None] === $familyRowGaugeStripInputSealSchemaV1,
    "SealSchemaSuperseded",
  Lookup[seal, "Schema", None] =!= $familyRowGaugeStripInputSealSchema,
    "SealSchemaUnknown",
  (* the fingerprint FIRST: it is one hash and it decides whether the
     fields below are the writer's or somebody's edit of them *)
  Lookup[seal, "Fingerprint", None] =!=
      familyRowGaugeStripInputSealFingerprint[seal], "SealFingerprintMismatch",
  Lookup[seal, "Family", None] =!= family, "SealFamilyMismatch",
  Lookup[seal, "ConnectionHash", None] =!= connectionHash,
    "SealConnectionMismatch",
  Lookup[seal, "Sector", None] =!= sector ||
    Lookup[seal, "LowerSector", None] =!= lowerSector ||
    Lookup[seal, "Truncation", None] =!= truncation, "SealPositionMismatch",
  Lookup[seal, "SolvedBlockPrefixHash", None] =!=
      Hash[KeySort[KeyTake[solvedBlocks,
        Lookup[seal, "SolvedBlockKeys", {}]]], "SHA256", "HexString"],
    "SealPrefixMismatch",
  Lookup[seal, "StripHash", None] =!= stripHash, "SealStripMismatch",
  True, "SealAuthenticated"];
familyRowGaugeStripInputSealVerdict[___] := "SealVerdictInvalidArguments";

(* step 3.  Independent images: different primes AND different regulator
   values, so a coincidence has to hold twice for unrelated reasons. *)
$familyRowGaugeResumeGateImages = {
  {2147483423, 1/13}, {2147483399, 3/17}, {2147483353, 5/19},
  {2147483323, 7/23}};

(* one modular value, or $Failed when the point is not admissible for
   this expression (a vanishing denominator, an indeterminate power) *)
familyRowGaugeResumeModularImageValue[expression_, rules_List,
    prime_Integer] := Module[{value, numerator, denominator},
  value = Quiet[Check[expression /. rules, $Failed,
    {Power::infy, Infinity::indet, Power::indet}]];
  If[value === $Failed || ! NumericQ[value] ||
      ! FreeQ[value, DirectedInfinity | Indeterminate |
        Complex], Return[$Failed]];
  If[! (IntegerQ[value] || Head[value] === Rational), Return[$Failed]];
  numerator = Numerator[value];
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

(* The relation: the strip input on disk equals the block equation the
   CURRENT connection and the banked solved-block prefix imply.  It is
   the identical statement familyRowGaugeResumeBlockEquation makes
   symbolically; here every operation is arithmetic in F_p at one
   point, so the connection is never normalized. *)
familyRowGaugeResumeModularGate[storedStrip_, connection_List,
    sector_Integer, lowerSector_Integer, solvedBlocks_Association,
    ranges_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    images_List, requiredImages_Integer] := Module[
  {rk, rj, higher, accepted = {}, inadmissible = {}, failing = None,
   attempts = 0, started = AbsoluteTime[]},
  If[! MatchQ[storedStrip, {_List, _List, _List}],
    Return[<|"Status" -> "ResumeModularGateNotApplicable",
      "Reason" -> "StoredStripMalformed"|>]];
  rk = ranges[[sector]];
  rj = ranges[[lowerSector]];
  higher = Select[Keys[solvedBlocks], lowerSector < #1 < sector &];
  Do[
    If[Length[accepted] >= requiredImages, Break[]];
    attempts++;
    Module[{prime = image[[1]], regulator = image[[2]], point, rules,
        evaluate, storedValues, impliedValues, epsilonValue, ok = True},
      point = BlockRandom[
        SeedRandom[Hash[{prime, regulator, sector, lowerSector}, "SHA256"],
          Method -> "MersenneTwister"];
        RandomInteger[{2, prime - 2}, 2]];
      rules = {variables[[1]] -> point[[1]], variables[[2]] -> point[[2]],
        epsilon -> regulator};
      epsilonValue = familyRowGaugeResumeModularImageValue[regulator, {},
        prime];
      If[epsilonValue === $Failed || epsilonValue === 0,
        AppendTo[inadmissible, <|"Prime" -> prime,
          "RegulatorValue" -> regulator, "Reason" -> "RegulatorImage"|>];
        Continue[]];
      evaluate[expr_] := familyRowGaugeResumeModularImageValue[expr, rules,
        prime];
      (* the three parts, in the order and with the arithmetic
         familyRowGaugeResumeBlockEquation uses *)
      impliedValues = Quiet[Check[{
        Table[Map[Mod[evaluate[#1] PowerMod[epsilonValue, -1, prime],
            prime] &, connection[[mu, rk, rk]], {2}], {mu, 2}],
        Table[Map[Mod[evaluate[#1] PowerMod[epsilonValue, -1, prime],
            prime] &, connection[[mu, rj, rj]], {2}], {mu, 2}],
        Table[Mod[Map[evaluate, connection[[mu, rk, rj]], {2}] -
            Sum[Map[evaluate, solvedBlocks[m], {2}] .
              Map[evaluate, connection[[mu, ranges[[m]], rj]], {2}],
              {m, higher}], prime], {mu, 2}]}, $Failed]];
      storedValues = Quiet[Check[
        Map[evaluate, storedStrip, {4}], $Failed]];
      If[impliedValues === $Failed || storedValues === $Failed ||
          ! FreeQ[impliedValues, $Failed] || ! FreeQ[storedValues, $Failed],
        AppendTo[inadmissible, <|"Prime" -> prime,
          "RegulatorValue" -> regulator, "Point" -> point,
          "Reason" -> "PointNotAdmissible"|>];
        Continue[]];
      ok = SameQ[Mod[storedValues, prime], Mod[impliedValues, prime]];
      If[ok,
        AppendTo[accepted, <|"Prime" -> prime,
          "RegulatorValue" -> regulator, "Point" -> point|>],
        (* step 4: a mismatch at an ADMISSIBLE image is a fact *)
        failing = <|"Prime" -> prime, "RegulatorValue" -> regulator,
          "Point" -> point,
          "MismatchingParts" -> Flatten[Position[
            MapThread[SameQ, {Mod[storedValues, prime],
              Mod[impliedValues, prime]}], False, {1}, Heads -> False]]|>;
        Break[]]],
    {image, images}];
  Which[
    AssociationQ[failing],
      <|"Status" -> "ResumeRejected", "Reason" -> "ModularRelationMismatch",
        "FailingImage" -> failing, "AcceptedImages" -> accepted,
        "InadmissibleImages" -> inadmissible,
        "Seconds" -> N[AbsoluteTime[] - started]|>,
    Length[accepted] >= requiredImages,
      <|"Status" -> "ResumeModularGateAccepted",
        "AcceptedImages" -> accepted, "ImageCount" -> Length[accepted],
        "InadmissibleImages" -> inadmissible,
        "Seconds" -> N[AbsoluteTime[] - started]|>,
    True,
      <|"Status" -> "ResumeModularGateInconclusive",
        "Reason" -> "TooFewAdmissibleImages",
        "AcceptedImages" -> accepted, "ImageCount" -> Length[accepted],
        "RequiredImageCount" -> requiredImages,
        "InadmissibleImages" -> inadmissible, "AttemptCount" -> attempts,
        "Seconds" -> N[AbsoluteTime[] - started]|>]
];
familyRowGaugeResumeModularGate[___] :=
  <|"Status" -> "ResumeModularGateInvalidArguments"|>;

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
  (* the calling driver's own identity, threaded into the sealed solver
     configuration (generality pass 2026-08-23, B2) *)
  "DriverProvenance" -> <||>,
  (* ---- the resume acceptance gate (2026-08-25, steps 2-4) ----------
     "ModularThenExact" (Automatic, the default) authenticates the seal,
     runs the two-image modular gate for its evidence, and STILL
     re-derives the block equation exactly -- today's guarantee plus a
     second independent check.  "Modular" skips the exact re-derivation
     when the seal authenticates AND the gate accepts, which is the mode
     that removes CF303's 40 silent minutes; it is opt-in because
     turning it on is a measured decision, not a default.  "Exact" is
     the pre-2026-08-25 behaviour.  A modular MISMATCH is a typed
     ResumeRejected in every mode: it is never repaired. *)
  "ResumeGate" -> Automatic,
  "ResumeGateImages" -> Automatic,
  "ResumeGateImageCount" -> 2,
  (* an audit run re-derives exactly no matter what the gate says *)
  "AdversarialAudit" -> False,
  (* ---- cooperative deadline (2026-08-25) ---------------------------
     Absolute AbsoluteTime[] value; Infinity (the default) leaves every
     existing caller unchanged.  The boundary is the STRIP: one strip is
     one whole-matrix block-equation reconstruction plus one replay, and
     that reconstruction is a single symbolic normalization with no
     finer boundary that does not change what is computed -- the same
     statement TransportCharts.wl makes about its own entry
     normalizations.  What removes the cost rather than bounding it is
     "ResumeGate" -> "Modular", which skips the reconstruction
     altogether once the seal authenticates and both images agree.
     NEVER TimeConstrained (CLAUDE.md). *)
  "Deadline" -> Infinity,
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
   driverProvenance = OptionValue["DriverProvenance"],
   minimumCached = OptionValue["MinimumCachedPrimeCount"],
   resumeGate = Replace[OptionValue["ResumeGate"],
     Automatic -> "ModularThenExact"],
   resumeGateImages = Replace[OptionValue["ResumeGateImages"],
     Automatic :> $familyRowGaugeResumeGateImages],
   resumeGateImageCount = OptionValue["ResumeGateImageCount"],
   adversarialAudit = TrueQ[OptionValue["AdversarialAudit"]],
   resumeDeadline = OptionValue["Deadline"],
   verbose = TrueQ[OptionValue["Verbose"]], diskCheckpoint,
   expectedConnectionHash, currentTruncation, currentConnectionHash,
   checkpointForms, lowerBlockSizes, reconstructedPrevD,
   fullCoverageQ, formsShapeQ, resultStatus, nk, coefficientField,
   algebraicFrameQ, expectedSolverConfiguration,
   solverConfigurationCheck,
   phaseTimings = <||>, phaseClock, phase, note, stripCounter = 0,
   started = AbsoluteTime[]},

  (* Telemetry only (2026-08-25).  Every check below already existed; the
     defect this closes is that NONE of them announced itself, so a
     resume that re-verifies banked strips against a large state was
     indistinguishable from a hung kernel (CF303 sector 17: more than 40
     minutes silent, five banked strips, a 61 MB state).  What is
     accepted does not change -- the phases are measured, named and
     printed, and every accept/reject test below is untouched. *)
  phaseClock = AbsoluteTime[];
  phase[name_String, data_ : <||>] := (
    phaseTimings[name] = AbsoluteTime[] - phaseClock;
    If[verbose,
      Print["  resume hydration phase ", name, ": ",
        Round[phaseTimings[name], 0.1], " s",
        If[data === <||>, "", " " <> ToString[data, InputForm]]]];
    phaseClock = AbsoluteTime[]);
  note[items___] := If[verbose, Print["  resume hydration ", items]];

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
      sector > Length[ranges] ||
      ! MemberQ[{"ModularThenExact", "Modular", "Exact"}, resumeGate] ||
      ! MatchQ[resumeGateImages,
        {{_Integer, _Integer | _Rational} ..}] ||
      ! IntegerQ[resumeGateImageCount] || resumeGateImageCount < 1 ||
      resumeGateImageCount > Length[resumeGateImages] ||
      ! (resumeDeadline === Infinity ||
        (NumericQ[resumeDeadline] && Positive[resumeDeadline])),
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

  note["start: family ", family, ", sector ", sector, ", ",
    Length[solvedBlocks], " banked strip(s) ", Sort[Keys[solvedBlocks]],
    ", truncation ", nk, ", connection ",
    Dimensions[currentConnection], ", checkpoint ",
    If[FileExistsQ[checkpointFile],
      ToString[Round[FileByteCount[checkpointFile]/1024.^2, 0.1]] <> " MB",
      "absent"], ", final check ", finalCheck];
  diskCheckpoint = If[FileExistsQ[checkpointFile],
    FeynFacet`FamilyArtifactRead[checkpointFile],
    Missing["NoCheckpoint"]];
  phase["CheckpointRead"];
  expectedConnectionHash = Lookup[checkpoint, "ConnectionHash", None];
  currentTruncation = currentConnection[[All, 1 ;; nk, 1 ;; nk]] /.
    epsilon -> CANONICA`eps;
  currentConnectionHash = Hash[currentTruncation,
    "SHA256", "HexString"];
  (* the size probe is a full traversal of a matrix that can be tens of
     megabytes: taken only when a line will actually be printed *)
  phase["ConnectionHash", <|"LeafCount" -> If[verbose,
    LeafCount[currentTruncation], Missing["NotMeasured"]]|>];
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
  phase["CheckpointIdentity", <|"Strips" -> Length[keys]|>];

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
        beforeHashes, afterHashes, gateVerdict, exactRecheckQ,
        seconds, solution, gauge, frameQ, solvedForm, existingForm,
        replayAction, extraLetters, directRecord, replayRoute,
        sealFile, seal, sealVerdict,
        stripStarted = AbsoluteTime[], stripClock = AbsoluteTime[],
        stripPhase, stripPhases = <||>},
      (* BEFORE anything this strip costs, not after it: the identity
         re-derivation below is a whole-matrix symbolic block equation
         against the current connection, and at HEAD the first line of
         this loop body was printed only once that had already run *)
      stripCounter++;
      (* BOUNDARY: between strips, before this strip costs anything *)
      If[NumericQ[resumeDeadline] && AbsoluteTime[] >= resumeDeadline,
        Throw[<|"Status" -> "ResumeHydrationBudgetExhausted",
          "Stage" -> "ResumeHydration:StripReplay",
          "Elapsed" -> N[AbsoluteTime[] - started],
          "Deadline" -> resumeDeadline,
          "Method" -> "RowGaugeResumeHydration",
          "Resumable" -> True,
          "StripsDone" -> stripCounter - 1,
          "StripCount" -> Length[keys],
          "LowerSector" -> lowerSector,
          "ReplayRecords" -> replayRecords|>, tag]];
      stripPhase[name_String, data_ : <||>] := (
        stripPhases[name] = AbsoluteTime[] - stripClock;
        If[verbose,
          Print["    strip ", {sector, lowerSector}, " ", name, ": ",
            Round[stripPhases[name], 0.1], " s",
            If[data === <||>, "", " " <> ToString[data, InputForm]]]];
        stripClock = AbsoluteTime[]);
      note["strip ", stripCounter, " of ", Length[keys], " ",
        {sector, lowerSector}, ": re-check start (",
        Round[AbsoluteTime[] - started, 0.1], " s into hydration)"];
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
      stripPhase["InputRead",
        <|"Bytes" -> FileByteCount[copiedInput],
          "StripLeafCount" -> If[verbose, LeafCount[input["Strip"]],
            Missing["NotMeasured"]]|>];
      (* THE SEAL, authenticated but NOT yet trusted (2026-08-25, Codex
         14:30 integrity layer).  The sidecar the sector driver writes
         beside each strip input records the connection, the solved-block
         prefix, the position and the exact strip the input was built
         from.  Comparing those digests costs microseconds and answers
         exactly the question the whole-matrix block-equation
         reconstruction below answers in minutes.

         What is NOT built: using that answer.  Steps 3 and 4 of the
         design -- two independent held-out modular relation evaluations,
         and exact reconstruction only on mismatch or in adversarial
         mode -- do not exist yet, so a seal that authenticates saves
         nothing today.  The exact reconstruction runs unconditionally,
         as it did before, and the seal verdict is recorded so that the
         gate can be measured against it before it is ever relied on. *)
      sealFile = StringReplace[sourceInput, "_input.wl" -> "_input_seal.wl"];
      seal = If[FileExistsQ[sealFile],
        Quiet[CheckAbort[FeynFacet`FamilyArtifactRead[sealFile], $Failed]],
        Missing["NoSeal"]];
      (* STEP 2: the seal's own fingerprint, recomputed from the hydrated
         record, decides before any field of it is believed *)
      sealVerdict = familyRowGaugeStripInputSealVerdict[seal, family, sector,
        lowerSector, nk, currentConnectionHash, solvedBlocks,
        Hash[input["Strip"], "SHA256", "HexString"]];
      stripPhase["SealCheck", <|"Verdict" -> sealVerdict|>];
      (* STEP 3: two independent held-out modular images of the SAME
         relation the exact reconstruction below checks.  Cheap: every
         operation is arithmetic in F_p at one point and the connection
         is never normalized. *)
      gateVerdict = If[resumeGate === "Exact",
        <|"Status" -> "ResumeModularGateNotRun"|>,
        familyRowGaugeResumeModularGate[input["Strip"], currentConnection,
          sector, lowerSector, solvedBlocks, ranges, variables, epsilon,
          resumeGateImages, resumeGateImageCount]];
      stripPhase["ModularGate",
        <|"Verdict" -> Lookup[gateVerdict, "Status", None],
          "Images" -> Lookup[gateVerdict, "ImageCount", 0]|>];
      (* STEP 4: a mismatch at an ADMISSIBLE image is a fact about this
         checkpoint, in every mode.  It is refused typed and named. *)
      If[Lookup[gateVerdict, "Status", None] === "ResumeRejected",
        Throw[<|"Status" -> "ResumeRejected",
          "Reason" -> Lookup[gateVerdict, "Reason", None],
          "LowerSector" -> lowerSector,
          "SealVerdict" -> sealVerdict,
          "FailingImage" -> Lookup[gateVerdict, "FailingImage", None],
          "AcceptedImages" -> Lookup[gateVerdict, "AcceptedImages", {}]|>,
          tag]];
      (* The exact re-derivation.  It is skipped ONLY in "Modular" mode,
         only when the seal authenticated AND both images agreed, and
         never in an adversarial audit.  In every other case the
         whole-matrix symbolic identity runs exactly as it did before,
         and the SameQ below decides exactly as at HEAD. *)
      exactRecheckQ = adversarialAudit || resumeGate =!= "Modular" ||
        sealVerdict =!= "SealAuthenticated" ||
        Lookup[gateVerdict, "Status", None] =!= "ResumeModularGateAccepted";
      If[exactRecheckQ,
        expectedStrip = familyRowGaugeResumeBlockEquation[
          currentConnection, sector, lowerSector, solvedBlocks, ranges,
          epsilon];
        stripPhase["BlockEquation",
          <|"LeafCount" -> If[verbose, LeafCount[expectedStrip],
            Missing["NotMeasured"]]|>];
        If[! SameQ[input["Strip"], expectedStrip],
          Throw[<|"Status" -> "ResumeHydrationInputConnectionMismatch",
            "LowerSector" -> lowerSector,
            "SealVerdict" -> sealVerdict,
            "ModularGate" -> Lookup[gateVerdict, "Status", None]|>, tag]];
        stripPhase["StripIdentity"],
        stripPhase["StripIdentity", <|"Mode" -> "ModularGateOnly"|>]];
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
          planDiscoveryBackend],
        "DriverProvenance" -> driverProvenance];
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
        ", cached=", artifactCount, ", replaying via ", solverRoute,
        " (identity checks took ",
        Round[AbsoluteTime[] - stripStarted, 0.1], " s)"]];
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
        "InputSeal" -> sealVerdict,
        "ResumeGate" -> resumeGate,
        "ModularGate" -> KeyDrop[gateVerdict, "InadmissibleImages"],
        "ExactBlockEquationRecheck" -> exactRecheckQ,
        "Seconds" -> seconds, "Method" -> solution["Method"],
        "SolverConfigurationMode" -> solverConfigurationCheck["Mode"],
        "SolverConfigurationFingerprint" ->
          expectedSolverConfiguration["Fingerprint"],
        "Certificate" -> Lookup[solution, "Certificate", None],
        "ExactDLog" -> Lookup[solution, "ExactDLog", False],
        "GaugeSameQ" -> True, "FrameCertificate" -> True,
        "CopiedArtifactsUnchanged" -> True,
        "SolvedFormDimensions" -> Dimensions[solvedForm],
        "PhaseTimings" -> stripPhases,
        "TotalSeconds" -> N[AbsoluteTime[] - stripStarted],
        "SolvedFormSHA256" -> Hash[solvedForm,
          "SHA256", "HexString"]|>];
      note["strip ", stripCounter, " of ", Length[keys], " ",
        {sector, lowerSector}, ": ", replayAction, " in ",
        Round[AbsoluteTime[] - stripStarted, 0.1], " s (replay ",
        Round[seconds, 0.1], " s)"]],
      {lowerSector, keys}];
    phase["StripReplay", <|"Strips" -> Length[keys]|>];
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
      (* the whole-state identity phases in front of the first strip, and
         the strip replay total: the breakdown a silent 40-minute resume
         gave nobody (2026-08-25) *)
      "PhaseTimings" -> phaseTimings,
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
