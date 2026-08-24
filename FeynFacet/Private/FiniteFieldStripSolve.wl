(* Automated finite-field reconstruction of an exact two-variable epsilon-form strip. *)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[PrepareEpsFormStripSampling, SampleEpsFormStripAffine, InterpolateEpsFormStripAffine, SolveEpsFormStripFiniteField, InstallEpsFormStripSolution];
ClearAll[
  finiteFieldStripNormalizationColumns,
  finiteFieldStripPrepare,
  finiteFieldStripSupport,
  finiteFieldStripSupportLadder,
  finiteFieldStripPrimeForms,
  $finiteFieldStripPrimeFormCache,
  finiteFieldStripFingerprint,
  finiteFieldStripIndependentRows,
  finiteFieldStripProbeOrder,
  finiteFieldStripReservePrimes,
  finiteFieldStripDiscoverPlan,
  finiteFieldStripRecordQ,
  finiteFieldStripEntryFactorList,
  finiteFieldStripIndependentColumns,
  finiteFieldStripEvaluateCoefficients,
  finiteFieldStripTrimCoefficients,
  finiteFieldStripReduceRationalPair,
  finiteFieldStripInterpolationQ,
  finiteFieldStripInterpolateCoordinate,
  finiteFieldStripCanonicalSamples,
  finiteFieldStripFitSplit,
  finiteFieldStripFitCandidates,
  finiteFieldStripHeldOutInterpolate,
  finiteFieldStripAdaptiveSamplingPlan,
  finiteFieldStripUnseenPrimeResidualQ,
  finiteFieldStripFLINTBinary,
  finiteFieldStripCFFRBinary,
  finiteFieldStripCFFRSource,
  $finiteFieldStripCFFRAdapterHashCache,
  finiteFieldStripCFFRAdapterHashes,
  finiteFieldStripCFFRFailure,
  finiteFieldStripCFFRNonce,
  finiteFieldStripCFFRRequest,
  finiteFieldStripCFFRWriteRequest,
  finiteFieldStripCFFRResponse,
  finiteFieldStripCFFRVerify,
  finiteFieldStripCFFRDirectory,
  finiteFieldStripCFFRRun,
  finiteFieldStripCFFRDiscoverPlan,
  finiteFieldStripCFFRPlanBindingValidQ,
  finiteFieldStripBackendQ,
  finiteFieldStripBackendDecision,
  finiteFieldStripBackendConfiguration,
  finiteFieldStripPlanDiscoveryBackendDecision,
  finiteFieldStripCoreSolutionQ,
  finiteFieldStripEliminationPlanFingerprint,
  finiteFieldStripSealEliminationPlan,
  finiteFieldStripValidateEliminationPlan,
  finiteFieldStripModularArtifactValidQ,
  finiteFieldStripFLINTSolve,
  finiteFieldStripPutAtomic,
  finiteFieldStripArtifactTag
];

SampleEpsFormStripAffine::record =
  "The record must contain a valid two-variable Strip, Variables, and Regulator.";
SampleEpsFormStripAffine::input =
  "The finite-field prime, regulator value, point count, or numerator-degree offset is invalid.";
SampleEpsFormStripAffine::alphabet =
  "The dlog alphabet could not be constructed from the strip.";
SampleEpsFormStripAffine::points =
  "No nonsingular finite-field sampling points could be constructed.";
SampleEpsFormStripAffine::width =
  "The prime `1` exceeds the packed-arithmetic width of the point evaluator (primes must be below 2^31).";

InterpolateEpsFormStripAffine::samples =
  "The samples do not describe one consistent affine system over the requested prime field.";
InterpolateEpsFormStripAffine::normalization =
  "The residue coordinates do not span the affine freedom at every sampled regulator value.";
InterpolateEpsFormStripAffine::count =
  "There are too few distinct regulator samples for construction and independent validation.";

SolveEpsFormStripFiniteField::failed =
  "The configured degree ladder and prime sequence did not yield an exactly verified rational gauge.";
InstallEpsFormStripSolution::state =
  "The checkpoint, strip record, solution, or sector ordering is inconsistent.";

finiteFieldStripRecordQ[record_] :=
  AssociationQ[record] &&
    And @@ (KeyExistsQ[record, #] & /@
      {"Strip", "Variables", "Regulator"}) &&
    MatchQ[record["Variables"], {_, _}] &&
    SymbolQ[record["Regulator"]] &&
    epsFormStripShapeQ[record["Strip"]];

finiteFieldStripEntryFactorList[entry_] := Module[{denominator},
  denominator = Denominator[Together[entry]];
  If[TrueQ[denominator === 1], {},
    Select[Rest[FactorList[denominator]],
      ! TrueQ[NumericQ[First[#]]] &]]
];

(* FLINT modular-solve backend: FeynFacet/Backends/flint (build.sh) *)
finiteFieldStripFLINTBinary[] := With[{file = FileNameJoin[{$feynFacetDirectory,
    "Backends", "flint", "bin", "flint_modular_solve"}]},
  If[FileExistsQ[file], file, None]];

(* CFFR1 rectangular affine-RREF adapter: FeynFacet/Backends/flint
   (build.sh, PROTOCOL_CFFR1.md), the plan-discovery backend of
   Design/CFFR1Backend.md.  A sibling of the CFFA4 locator above and
   nothing more: the two adapters share no writer, no parser and no
   fallback semantics -- CFFR1 binds a nonce and the adapter's immutable
   hashes, and an explicit request never falls back. *)
finiteFieldStripCFFRBinary[] := With[{file = FileNameJoin[{$feynFacetDirectory,
    "Backends", "flint", "bin", "flint_affine_rref"}]},
  If[FileExistsQ[file], file, None]];

finiteFieldStripCFFRSource[] := With[{file = FileNameJoin[{$feynFacetDirectory,
    "Backends", "flint", "flint_affine_rref.c"}]},
  If[FileExistsQ[file], file, None]];

finiteFieldStripCFFRFailure[status_String, data_Association: <||>] :=
  Join[<|"Status" -> status, "Protocol" -> "CFFR1"|>, data];

$finiteFieldStripCFFRAdapterHashCache = <||>;

(* item 5 of the design note: the adapter source and binary hashes are
   the plan's immutable binding.  They are computed once per session and
   cached under the binary's path, and re-checked on every discovery: a
   binary replaced mid-session is a typed failure, never a plan that
   silently belongs to another executable. *)
finiteFieldStripCFFRAdapterHashes[] := Module[{binary, source, current},
  binary = finiteFieldStripCFFRBinary[];
  source = finiteFieldStripCFFRSource[];
  If[! StringQ[binary] || ! FileExistsQ[binary],
    Return[finiteFieldStripCFFRFailure["CFFRAdapterBinaryUnavailable",
      <|"AdapterBinary" -> If[StringQ[binary], binary, None]|>]]];
  If[! StringQ[source] || ! FileExistsQ[source],
    Return[finiteFieldStripCFFRFailure["CFFRAdapterSourceUnavailable",
      <|"AdapterSource" -> If[StringQ[source], source, None]|>]]];
  current = <|"AdapterBinary" -> binary, "AdapterSource" -> source,
    "AdapterBinarySHA256" -> FileHash[binary, "SHA256", "HexString"],
    "AdapterSourceSHA256" -> FileHash[source, "SHA256", "HexString"]|>;
  If[KeyExistsQ[$finiteFieldStripCFFRAdapterHashCache, binary],
    If[$finiteFieldStripCFFRAdapterHashCache[binary] =!= current,
      Return[finiteFieldStripCFFRFailure["CFFRAdapterHashChanged",
        <|"CachedAdapterHashes" ->
            $finiteFieldStripCFFRAdapterHashCache[binary],
          "CurrentAdapterHashes" -> current|>]]],
    $finiteFieldStripCFFRAdapterHashCache[binary] = current];
  Join[<|"Status" -> "OK"|>, current]
];

(* Backend controls only the fixed constrained core.  Plan discovery is a
   separate contract below; an explicit fixed-core request never changes
   the MatrixRank/NullSpace implementation that created the plan. *)
finiteFieldStripBackendDecision[requested_, threads_,
    coreSize_Integer?NonNegative] := Module[{binary, reported},
  reported = Which[requested === Automatic, Automatic,
    StringQ[requested], requested, True,
    ToString[Head[requested], InputForm]];
  If[! MemberQ[{Automatic, "Wolfram", "FLINT"}, requested],
    Return[<|"Status" -> "InvalidBackendOption",
      "BackendRequested" -> reported,
      "AllowedBackends" -> {Automatic, "Wolfram", "FLINT"}|>]];
  If[! IntegerQ[threads] || ! Between[threads, {1, 4}],
    Return[<|"Status" -> "InvalidBackendThreads",
      "BackendRequested" -> requested,
      "BackendThreads" -> If[IntegerQ[threads], threads,
        ToString[Head[threads], InputForm]],
      "AllowedRange" -> {1, 4}|>]];
  binary = finiteFieldStripFLINTBinary[];
  Which[
    requested === "Wolfram",
      <|"Status" -> "OK", "BackendRequested" -> requested,
        "BackendThreads" -> threads, "UseBackend" -> "Wolfram",
        "FallbackAllowed" -> False|>,
    requested === "FLINT" && binary === None,
      <|"Status" -> "BackendUnavailable",
        "BackendRequested" -> requested, "BackendThreads" -> threads,
        "UseBackend" -> None, "FallbackAllowed" -> False|>,
    requested === "FLINT",
      <|"Status" -> "OK", "BackendRequested" -> requested,
        "BackendThreads" -> threads, "UseBackend" -> "FLINT",
        "FallbackAllowed" -> False|>,
    binary =!= None && coreSize >= 256,
      <|"Status" -> "OK", "BackendRequested" -> Automatic,
        "BackendThreads" -> threads, "UseBackend" -> "FLINT",
        "FallbackAllowed" -> True|>,
    True,
      <|"Status" -> "OK", "BackendRequested" -> Automatic,
        "BackendThreads" -> threads, "UseBackend" -> "Wolfram",
        "FallbackAllowed" -> True|>]
];
finiteFieldStripBackendDecision[requested_, threads_, coreSize_] :=
  <|"Status" -> "InvalidBackendDecisionArguments",
    "ArgumentHeads" -> (ToString[Head[#], InputForm] & /@
      {requested, threads, coreSize})|>;

finiteFieldStripBackendQ[requested_, coreSize_Integer] := TrueQ[
  Lookup[finiteFieldStripBackendDecision[requested, 1, coreSize],
    "UseBackend", None] === "FLINT"];

(* The plan-discovery contract, distinct from the CFFA4 fixed core above.
   "Wolfram" is the historical path.  "FLINTAffineRREF" is the native
   CFFR1 adapter (Design/CFFR1Backend.md); an explicit request with no
   adapter present is a typed failure here, which the callers propagate
   -- there is no fallback to the Wolfram discoverer.  Automatic is not
   an accepted value in this pass, so Automatic can never select the
   native path. *)
finiteFieldStripPlanDiscoveryBackendDecision[requested_] := Which[
  requested === "Wolfram",
    <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> requested,
      "PlanDiscoveryBackendUsed" -> "Wolfram"|>,
  requested === "FLINTAffineRREF" && finiteFieldStripCFFRBinary[] === None,
    <|"Status" -> "PlanDiscoveryBackendUnavailable",
      "PlanDiscoveryBackendRequested" -> requested,
      "PlanDiscoveryBackendUsed" -> None|>,
  requested === "FLINTAffineRREF",
    <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> requested,
      "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF"|>,
  True,
    <|"Status" -> "InvalidPlanDiscoveryBackendOption",
      "PlanDiscoveryBackendRequested" -> If[StringQ[requested],
        requested, ToString[Head[requested], InputForm]],
      "AllowedBackends" -> {"Wolfram", "FLINTAffineRREF"}|>
];

finiteFieldStripBackendConfiguration[requested_, threads_] := Module[
  {decision, binary, source, payload},
  decision = finiteFieldStripBackendDecision[requested, threads, 0];
  If[Lookup[decision, "Status", None] =!= "OK", Return[decision]];
  binary = finiteFieldStripFLINTBinary[];
  source = FileNameJoin[{$feynFacetPrivateDirectory,
    "FiniteFieldStripSolve.wl"}];
  If[! FileExistsQ[source],
    Return[<|"Status" -> "BackendSourceUnavailable"|>]];
  payload = <|
    "Schema" -> "FeynFacetFiniteFieldFixedCoreBackendConfiguration",
    "SchemaVersion" -> 1, "Contract" -> "FixedConstrainedCore",
    "BackendProtocol" -> "CFFA4V1/CFFA4X1OrWolfram",
    "BackendRequested" -> requested, "BackendThreads" -> threads,
    "FiniteFieldStripSolveSHA256" ->
      FileHash[source, "SHA256", "HexString"],
    "FLINTBinarySHA256" -> If[
      MemberQ[{Automatic, "FLINT"}, requested] && StringQ[binary],
      FileHash[binary, "SHA256", "HexString"], None]|>;
  Join[payload, <|"Fingerprint" ->
    Hash[KeySort[payload], "SHA256", "HexString"]|>]
];
finiteFieldStripBackendConfiguration[___] :=
  <|"Status" -> "InvalidBackendConfigurationArguments"|>;

finiteFieldStripCoreSolutionQ[core_, rhs_, solution_, prime_Integer] :=
  MatrixQ[solution, IntegerQ] &&
    Dimensions[solution] ===
      {Dimensions[core][[2]], Dimensions[rhs][[2]]} &&
    AllTrue[Flatten[solution], Between[#, {0, prime - 1}] &] &&
    AllTrue[Flatten[Mod[core . solution - rhs, prime]],
      SameQ[#, 0] &];

$finiteFieldStripEliminationPlanSchema =
  "FeynFacetFiniteFieldStripEliminationPlan";
$finiteFieldStripEliminationPlanSchemaVersion = 1;
$finiteFieldStripEliminationPlanSolverProvenance = <|
  "Discoverer" -> "WolframMatrixRankNullSpace",
  "IndependentRows" -> "WolframLeftNullspacePivots",
  "PlanDiscoveryBackend" -> "Wolfram",
  "Implementation" -> "FiniteFieldStripSolve",
  "ImplementationVersion" -> 1|>;
$finiteFieldStripEliminationPlanRequiredKeys = {
  "Status", "PlanSchema", "PlanSchemaVersion", "PlanFingerprint",
  "PreparationFingerprint", "SolverProvenance",
  "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
  "NormalizationColumns", "IndependentEquationRows", "GenericRank",
  "Nullity", "UnknownCount", "GaugeUnknownCount", "FreeResidueCount",
  "GaugeNumeratorDegrees", "GaugeDenominatorDegrees", "GaugeSupport",
  "PilotPrime"};

(* Design/CFFR1Backend.md item 5: a plan discovered by the native adapter
   carries, inside the fingerprinted payload, the adapter identity and
   the exact wire objects it was read from.  These keys are required for
   "FLINTAffineRREF" and forbidden for "Wolfram". *)
$finiteFieldStripEliminationPlanCFFRSolverProvenance = <|
  "Discoverer" -> "FLINTAffineRREFAdapterCFFR1",
  "IndependentRows" -> "FLINTRREFRowPermutation",
  "PlanDiscoveryBackend" -> "FLINTAffineRREF",
  "Implementation" -> "FiniteFieldStripSolve",
  "ImplementationVersion" -> 1|>;
$finiteFieldStripCFFRPlanBindingKeys = {
  "AdapterSourceSHA256", "AdapterBinarySHA256", "Protocol", "Nonce",
  "RequestSHA256", "ResponseSHA256", "Threads"};
$finiteFieldStripEliminationPlanCFFRRequiredKeys = Join[
  $finiteFieldStripEliminationPlanRequiredKeys,
  $finiteFieldStripCFFRPlanBindingKeys];

finiteFieldStripEliminationPlanFingerprint[plan_Association] := Hash[
  KeySort[KeyDrop[plan, "PlanFingerprint"]], "SHA256", "HexString"];

finiteFieldStripSealEliminationPlan[plan_Association,
    preparationFingerprint_String,
    planDiscoveryBackend_: "Wolfram",
    binding_Association: <||>] := Module[
  {payload, decision, used, provenance, expectedBindingKeys},
  decision = finiteFieldStripPlanDiscoveryBackendDecision[
    planDiscoveryBackend];
  If[Lookup[decision, "Status", None] =!= "OK", Return[decision]];
  used = decision["PlanDiscoveryBackendUsed"];
  provenance = If[used === "FLINTAffineRREF",
    $finiteFieldStripEliminationPlanCFFRSolverProvenance,
    $finiteFieldStripEliminationPlanSolverProvenance];
  expectedBindingKeys = If[used === "FLINTAffineRREF",
    Sort[$finiteFieldStripCFFRPlanBindingKeys], {}];
  If[Sort[Keys[binding]] =!= expectedBindingKeys,
    Return[<|"Status" -> "PlanAdapterBindingInvalid",
      "PlanDiscoveryBackendRequested" -> planDiscoveryBackend,
      "PlanDiscoveryBackendUsed" -> used,
      "BindingKeys" -> Sort[Keys[binding]],
      "ExpectedBindingKeys" -> expectedBindingKeys|>]];
  payload = Join[plan, <|
    "PlanSchema" -> $finiteFieldStripEliminationPlanSchema,
    "PlanSchemaVersion" -> $finiteFieldStripEliminationPlanSchemaVersion,
    "PreparationFingerprint" -> preparationFingerprint,
    "SolverProvenance" -> provenance,
    "PlanDiscoveryBackendRequested" -> planDiscoveryBackend,
    "PlanDiscoveryBackendUsed" -> used|>, binding];
  Join[payload, <|"PlanFingerprint" ->
    finiteFieldStripEliminationPlanFingerprint[payload]|>]
];

(* the shape of the sealed adapter binding, plus the session identity
   check: a plan sealed against a different adapter binary than the one
   this session hashed is refused rather than reused *)
finiteFieldStripCFFRPlanBindingValidQ[plan_Association] := Module[
  {cached, hexQ, nonce, threads},
  hexQ[value_] := StringQ[value] && StringLength[value] === 64 &&
    StringMatchQ[value, RegularExpression["[0-9a-f]{64}"]];
  nonce = Lookup[plan, "Nonce", None];
  threads = Lookup[plan, "Threads", None];
  cached = Lookup[$finiteFieldStripCFFRAdapterHashCache,
    Replace[finiteFieldStripCFFRBinary[], None -> Missing["NoAdapter"]],
    <||>];
  TrueQ[
    Lookup[plan, "Protocol", None] === "CFFR1" &&
    hexQ[Lookup[plan, "AdapterSourceSHA256", None]] &&
    hexQ[Lookup[plan, "AdapterBinarySHA256", None]] &&
    hexQ[Lookup[plan, "RequestSHA256", None]] &&
    hexQ[Lookup[plan, "ResponseSHA256", None]] &&
    IntegerQ[nonce] && Between[nonce, {1, 2^128 - 1}] &&
    IntegerQ[threads] && Between[threads, {1, 8}] &&
    (cached === <||> ||
      (Lookup[cached, "AdapterSourceSHA256", None] ===
         plan["AdapterSourceSHA256"] &&
       Lookup[cached, "AdapterBinarySHA256", None] ===
         plan["AdapterBinarySHA256"]))]
];
finiteFieldStripCFFRPlanBindingValidQ[___] := False;

finiteFieldStripValidateEliminationPlan[plan_,
    matrixDimensions : {equationCount_Integer?NonNegative,
      unknownCount_Integer?NonNegative}, gaugeUnknownCount_Integer,
    freeResidueCount_Integer, numeratorDegrees_List,
    denominatorDegrees_List, support_List,
    preparationFingerprint_String] := Module[
  {fail, strictIncreasingQ, rows, columns, rank, nullity, pilotPrime,
   backend, requiredKeys, provenance},
  fail[status_String] := <|"Status" -> status|>;
  strictIncreasingQ[values_] := VectorQ[values, IntegerQ] &&
    values === Sort[DeleteDuplicates[values]];
  If[plan === None, Return[fail["NoEliminationPlan"]]];
  If[! AssociationQ[plan], Return[fail["PlanNotAssociation"]]];
  (* the sealed key set and provenance depend on the discovery backend:
     the native plan carries the adapter binding of item 5 in addition to
     the historical keys, and nothing else may differ *)
  backend = Lookup[plan, "PlanDiscoveryBackendUsed", None];
  {requiredKeys, provenance} = Switch[backend,
    "Wolfram", {$finiteFieldStripEliminationPlanRequiredKeys,
      $finiteFieldStripEliminationPlanSolverProvenance},
    "FLINTAffineRREF", {$finiteFieldStripEliminationPlanCFFRRequiredKeys,
      $finiteFieldStripEliminationPlanCFFRSolverProvenance},
    _, {None, None}];
  If[requiredKeys === None,
    Return[fail["PlanSolverProvenanceMismatch"]]];
  If[Sort[Keys[plan]] =!= Sort[requiredKeys],
    Return[fail["PlanSchemaKeysMismatch"]]];
  If[Lookup[plan, "Status", None] =!= "OK" ||
      Lookup[plan, "PlanSchema", None] =!=
        $finiteFieldStripEliminationPlanSchema ||
      Lookup[plan, "PlanSchemaVersion", None] =!=
        $finiteFieldStripEliminationPlanSchemaVersion,
    Return[fail["PlanSchemaVersionMismatch"]]];
  If[! SameQ[Lookup[plan, "SolverProvenance", None], provenance] ||
      Lookup[plan, "PlanDiscoveryBackendRequested", None] =!= backend,
    Return[fail["PlanSolverProvenanceMismatch"]]];
  If[backend === "FLINTAffineRREF" &&
      ! finiteFieldStripCFFRPlanBindingValidQ[plan],
    Return[fail["PlanAdapterBindingMismatch"]]];
  If[Lookup[plan, "PreparationFingerprint", None] =!=
      preparationFingerprint,
    Return[fail["PlanPreparationFingerprintMismatch"]]];
  If[! StringQ[Lookup[plan, "PlanFingerprint", None]] ||
      StringLength[plan["PlanFingerprint"]] =!= 64 ||
      plan["PlanFingerprint"] =!=
        finiteFieldStripEliminationPlanFingerprint[plan],
    Return[fail["PlanFingerprintMismatch"]]];
  If[Lookup[plan, "UnknownCount", None] =!= unknownCount ||
      Lookup[plan, "GaugeUnknownCount", None] =!= gaugeUnknownCount ||
      Lookup[plan, "FreeResidueCount", None] =!= freeResidueCount ||
      gaugeUnknownCount + freeResidueCount =!= unknownCount,
    Return[fail["PlanUnknownLayoutMismatch"]]];
  If[Lookup[plan, "GaugeNumeratorDegrees", None] =!= numeratorDegrees ||
      Lookup[plan, "GaugeDenominatorDegrees", None] =!=
        denominatorDegrees ||
      Lookup[plan, "GaugeSupport", None] =!= support,
    Return[fail["PlanAnsatzMismatch"]]];
  {rows, columns, rank, nullity, pilotPrime} = Lookup[plan,
    {"IndependentEquationRows", "NormalizationColumns", "GenericRank",
      "Nullity", "PilotPrime"}, Missing["Absent"]];
  If[! IntegerQ[rank] || ! IntegerQ[nullity] || rank < 0 ||
      nullity < 0 || rank + nullity =!= unknownCount ||
      rank > Min[equationCount, unknownCount],
    Return[fail["PlanRankNullityInvalid"]]];
  If[! strictIncreasingQ[rows] || Length[rows] =!= rank ||
      ! AllTrue[rows, Between[#, {1, equationCount}] &],
    Return[fail["PlanEquationRowsInvalid"]]];
  If[! strictIncreasingQ[columns] || Length[columns] =!= nullity ||
      ! AllTrue[columns, Between[#, {1, unknownCount}] &],
    Return[fail["PlanNormalizationColumnsInvalid"]]];
  If[! IntegerQ[pilotPrime] || ! PrimeQ[pilotPrime] ||
      ! Between[pilotPrime, {5, 2^31 - 1}],
    Return[fail["PlanPilotPrimeInvalid"]]];
  <|"Status" -> "OK"|>
];

finiteFieldStripModularArtifactValidQ[artifact_, recordFingerprint_,
    selectedOffset_, selectedShell_, planFingerprint_,
    backendConfiguration_, planDiscoveryBackend_] :=
  AssociationQ[artifact] &&
    Lookup[artifact, "RecordFingerprint", Missing[]] ===
      recordFingerprint &&
    Lookup[artifact, "SelectedNumeratorDegreeOffset", Missing[]] ===
      selectedOffset &&
    Lookup[artifact, "SelectedSupportShell", "Rectangle"] ===
      selectedShell &&
    Lookup[artifact, "EliminationPlanFingerprint", Missing[]] ===
      planFingerprint &&
    SameQ[Lookup[artifact, "BackendConfiguration", Missing[]],
      backendConfiguration] &&
    Lookup[artifact, "PlanDiscoveryBackend", Missing[]] ===
      planDiscoveryBackend;
finiteFieldStripModularArtifactValidQ[___] := False;

(* solve core . X = rhs modulo prime through the adapter; X (a dense
   integer matrix) or $Failed.  Format CFFA4V1/CFFA4X1: unsigned 64-bit
   little-endian words, row-major. *)
finiteFieldStripFLINTSolve[core_, rhs_, prime_Integer, threads_Integer] := Module[
  {binary = finiteFieldStripFLINTBinary[], directory, input, output, stream,
   rows, columns, rhsColumns, process, magic, header, values, solution},
  If[binary === None || ! (2 <= prime < 2^63), Return[$Failed]];
  {rows, columns} = Dimensions[core];
  rhsColumns = Dimensions[rhs][[2]];
  directory = CreateDirectory[];
  input = FileNameJoin[{directory, "core.bin"}];
  output = FileNameJoin[{directory, "solution.bin"}];
  Catch[
    stream = OpenWrite[input, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["CFFA4V1\000"], "UnsignedInteger8"];
    BinaryWrite[stream, {rows, columns, rhsColumns, prime}, "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[Normal[core]], "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[Normal[rhs]], "UnsignedInteger64", ByteOrdering -> -1];
    Close[stream];
    process = RunProcess[{binary, input, output, ToString[Clip[threads, {1, 4}]]}];
    If[! AssociationQ[process] || process["ExitCode"] =!= 0, Throw[$Failed, "flint"]];
    stream = OpenRead[output, BinaryFormat -> True];
    magic = BinaryReadList[stream, "UnsignedInteger8", 8];
    header = BinaryReadList[stream, "UnsignedInteger64", 3, ByteOrdering -> -1];
    values = BinaryReadList[stream, "UnsignedInteger64", header[[1]] header[[2]], ByteOrdering -> -1];
    Close[stream];
    If[magic =!= ToCharacterCode["CFFA4X1\000"] || header =!= {columns, rhsColumns, prime} ||
        Length[values] =!= columns rhsColumns, Throw[$Failed, "flint"]];
    solution = ArrayReshape[values, {columns, rhsColumns}];
    DeleteDirectory[directory, DeleteContents -> True];
    solution,
    "flint", (DeleteDirectory[directory, DeleteContents -> True]; $Failed) &]
];

(* ---------------------------------------------------------------------
   CFFR1 plan-discovery backend (Design/CFFR1Backend.md,
   FeynFacet/Backends/flint/PROTOCOL_CFFR1.md).  Every failure below is a
   typed Association carrying the adapter exit code and the first
   divergent field; nothing here falls back to the Wolfram discoverer.
   --------------------------------------------------------------------- *)

(* A 128-bit nonce binds one response to one request: a stale or replayed
   response file cannot be mistaken for this call's answer.  Wolfram
   14.2.1 exposes no cryptographic Method for RandomInteger (checked
   2026-08-23), so the bytes come from the operating system's CSPRNG;
   the hashed RandomInteger path is used only when that device cannot be
   read.  A zero nonce is invalid on the wire. *)
finiteFieldStripCFFRNonce[] := Module[{bytes, value},
  bytes = Quiet[Check[BinaryReadList["/dev/urandom", "Byte", 16], $Failed]];
  value = If[ListQ[bytes] && Length[bytes] === 16 &&
      VectorQ[bytes, IntegerQ],
    FromDigits[Mod[bytes, 256], 256],
    Hash[{RandomInteger[{0, 2^128 - 1}], CreateUUID[], AbsoluteTime[],
      $ProcessID, $SessionID}, "SHA256"]];
  value = Mod[value, 2^128];
  If[value === 0, 1, value]
];

(* CFFR1V1 request: 8 magic bytes, 9 header words, then A row-major, b,
   and the normalization preference -- unsigned 64-bit little-endian
   words throughout, zero-based indices on the wire, canonical residues
   in [0,p).  `preference` is the residue-first normalization column
   order the plan already computes (finiteFieldStripNormalizationColumns
   uses exactly this order for its greedy), given here one-based. *)
finiteFieldStripCFFRRequest[matrix_, rightHandSide_, prime_Integer,
    preference_List, nonce_Integer] := Module[
  {dense, dimensions, rows, columns, right},
  dense = Normal[matrix];
  dimensions = Dimensions[dense];
  If[Length[dimensions] =!= 2 || ! MatrixQ[dense, IntegerQ],
    Return[finiteFieldStripCFFRFailure["CFFRRequestMatrixInvalid"]]];
  {rows, columns} = dimensions;
  right = Normal[rightHandSide];
  If[rows < 1 || columns < 1 || ! PrimeQ[prime] || ! (2 < prime < 2^63) ||
      ! VectorQ[right, IntegerQ] || Length[right] =!= rows ||
      Sort[preference] =!= Range[columns] ||
      ! Between[nonce, {1, 2^128 - 1}],
    Return[finiteFieldStripCFFRFailure["CFFRRequestInvalid",
      <|"Rows" -> rows, "Columns" -> columns, "Modulus" -> prime|>]]];
  <|"Status" -> "OK", "Protocol" -> "CFFR1", "Magic" -> "CFFR1V1",
    "Rows" -> rows, "Columns" -> columns, "RightHandSideColumns" -> 1,
    "Modulus" -> prime, "PreferenceCount" -> columns, "Flags" -> 0,
    "Nonce" -> nonce, "NonceHigh" -> Quotient[nonce, 2^64],
    "NonceLow" -> Mod[nonce, 2^64],
    "PayloadWordCount" -> rows columns + rows + columns,
    "Matrix" -> Mod[dense, prime],
    "RightHandSide" -> Mod[right, prime],
    "Preference" -> preference|>
];
finiteFieldStripCFFRRequest[___] :=
  finiteFieldStripCFFRFailure["CFFRRequestArgumentsInvalid"];

finiteFieldStripCFFRWriteRequest[request_Association, file_String] := Module[
  {stream = None, rows, columns, expected, written},
  If[Lookup[request, "Status", None] =!= "OK",
    Return[finiteFieldStripCFFRFailure["CFFRRequestInvalid"]]];
  {rows, columns} = Lookup[request, {"Rows", "Columns"}];
  expected = 8 + 8 (9 + request["PayloadWordCount"]);
  written = Quiet[Check[
    stream = OpenWrite[file, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["CFFR1V1\000"], "UnsignedInteger8"];
    BinaryWrite[stream, {rows, columns, 1, request["Modulus"], columns, 0,
        request["NonceHigh"], request["NonceLow"],
        request["PayloadWordCount"]},
      "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[request["Matrix"]], "UnsignedInteger64",
      ByteOrdering -> -1];
    BinaryWrite[stream, request["RightHandSide"], "UnsignedInteger64",
      ByteOrdering -> -1];
    BinaryWrite[stream, request["Preference"] - 1, "UnsignedInteger64",
      ByteOrdering -> -1];
    Close[stream]; stream = None;
    FileByteCount[file] === expected, $Failed]];
  If[stream =!= None, Quiet[Close[stream]]];
  If[TrueQ[written],
    <|"Status" -> "OK", "RequestFile" -> file, "ByteCount" -> expected,
      "RequestSHA256" -> FileHash[file, "SHA256", "HexString"]|>,
    finiteFieldStripCFFRFailure["CFFRRequestWriteFailed",
      <|"RequestFile" -> file|>]]
];
finiteFieldStripCFFRWriteRequest[___] :=
  finiteFieldStripCFFRFailure["CFFRRequestWriterArgumentsInvalid"];

(* CFFR1X1 response parse.  The wire bytes are read from the file the
   adapter committed (BinaryReadList, "UnsignedInteger64",
   ByteOrdering -> -1); the exact byte count, the echoed nonce, every
   echoed header field, the payload length and the index structure are
   REQUIRED, and the first field that diverges names the failure. *)
finiteFieldStripCFFRResponse[file_String, request_Association] := Module[
  {fail, exitCode, stream, magic, header, words, byteCount, rows, columns,
   rhsColumns, modulus, rank, nullity, preferenceCount, flags, nonceHigh,
   nonceLow, payloadWords, expectedWords, expectedBytes, cursor, next,
   sortedRangeQ, pivotColumns, freeColumns, independentRows,
   normalizationColumns, particular, nullspace, rowMinorInverse,
   normalizationMinorInverse},
  exitCode = Lookup[request, "AdapterExitCode", 0];
  fail[status_String, field_String, data_Association: <||>] :=
    finiteFieldStripCFFRFailure[status,
      Join[<|"DivergentField" -> field, "AdapterExitCode" -> exitCode,
        "ResponseFile" -> file|>, data]];
  If[Lookup[request, "Status", None] =!= "OK",
    Return[fail["CFFRRequestInvalid", "Request"]]];
  If[! FileExistsQ[file], Return[fail["CFFRResponseMissing", "File"]]];
  byteCount = FileByteCount[file];
  If[! IntegerQ[byteCount] || byteCount < 8 + 8*11,
    Return[fail["CFFRResponseTruncated", "Header",
      <|"ByteCount" -> byteCount|>]]];
  stream = Quiet[Check[OpenRead[file, BinaryFormat -> True], $Failed]];
  If[stream === $Failed, Return[fail["CFFRResponseUnreadable", "File"]]];
  magic = Quiet[Check[
    BinaryReadList[stream, "UnsignedInteger8", 8], $Failed]];
  header = Quiet[Check[
    BinaryReadList[stream, "UnsignedInteger64", 11, ByteOrdering -> -1],
    $Failed]];
  words = Quiet[Check[
    BinaryReadList[stream, "UnsignedInteger64", ByteOrdering -> -1],
    $Failed]];
  Quiet[Close[stream]];
  If[! ListQ[magic] || magic =!= ToCharacterCode["CFFR1X1\000"],
    Return[fail["CFFRResponseMagicMismatch", "Magic"]]];
  If[! ListQ[header] || Length[header] =!= 11,
    Return[fail["CFFRResponseTruncated", "Header"]]];
  {rows, columns, rhsColumns, modulus, rank, nullity, preferenceCount,
    flags, nonceHigh, nonceLow, payloadWords} = header;
  (* the echoed nonce first: without it nothing else in the file means
     anything for THIS request *)
  If[{nonceHigh, nonceLow} =!=
      {request["NonceHigh"], request["NonceLow"]},
    Return[fail["CFFRResponseNonceMismatch", "Nonce"]]];
  (* every other echoed header field, in wire order; the first that
     diverges names the failure *)
  If[rows =!= request["Rows"],
    Return[fail["CFFRResponseHeaderMismatch", "Rows"]]];
  If[columns =!= request["Columns"],
    Return[fail["CFFRResponseHeaderMismatch", "Columns"]]];
  If[rhsColumns =!= 1,
    Return[fail["CFFRResponseHeaderMismatch", "RightHandSideColumns"]]];
  If[modulus =!= request["Modulus"],
    Return[fail["CFFRResponseHeaderMismatch", "Modulus"]]];
  If[preferenceCount =!= request["Columns"],
    Return[fail["CFFRResponseHeaderMismatch", "PreferenceCount"]]];
  If[flags =!= 0,
    Return[fail["CFFRResponseHeaderMismatch", "Flags"]]];
  If[! (IntegerQ[rank] && IntegerQ[nullity] && rank >= 0 && nullity >= 0 &&
      rank <= Min[rows, columns] && rank + nullity === columns),
    Return[fail["CFFRResponseRankNullityInvalid", "Rank"]]];
  expectedWords = 3 columns + nullity columns + rank^2 + nullity^2;
  If[payloadWords =!= expectedWords,
    Return[fail["CFFRResponsePayloadLengthMismatch", "PayloadWords",
      <|"PayloadWordCount" -> payloadWords,
        "ExpectedPayloadWordCount" -> expectedWords|>]]];
  expectedBytes = 8 + 8 (11 + expectedWords);
  If[byteCount =!= expectedBytes || ! ListQ[words] ||
      Length[words] =!= expectedWords,
    Return[fail["CFFRResponseTruncated", "Payload",
      <|"ByteCount" -> byteCount, "ExpectedByteCount" -> expectedBytes|>]]];
  cursor = 0;
  next[count_] := (cursor += count; words[[cursor - count + 1 ;; cursor]]);
  pivotColumns = next[rank];
  freeColumns = next[nullity];
  independentRows = next[rank];
  normalizationColumns = next[nullity];
  particular = next[columns];
  nullspace = If[nullity === 0, {},
    ArrayReshape[next[nullity columns], {nullity, columns}]];
  rowMinorInverse = If[rank === 0, {},
    ArrayReshape[next[rank^2], {rank, rank}]];
  normalizationMinorInverse = If[nullity === 0, {},
    ArrayReshape[next[nullity^2], {nullity, nullity}]];
  sortedRangeQ[values_, count_, bound_] := VectorQ[values, IntegerQ] &&
    Length[values] === count && DuplicateFreeQ[values] &&
    values === Sort[values] && AllTrue[values, 0 <= # < bound &];
  If[! sortedRangeQ[pivotColumns, rank, columns],
    Return[fail["CFFRResponseIndexInvalid", "PivotColumns"]]];
  If[! sortedRangeQ[freeColumns, nullity, columns],
    Return[fail["CFFRResponseIndexInvalid", "FreeColumns"]]];
  If[Sort[Join[pivotColumns, freeColumns]] =!= Range[0, columns - 1],
    Return[fail["CFFRResponseIndexInvalid", "PivotFreePartition"]]];
  If[! sortedRangeQ[independentRows, rank, rows],
    Return[fail["CFFRResponseIndexInvalid", "IndependentRows"]]];
  If[! sortedRangeQ[normalizationColumns, nullity, columns],
    Return[fail["CFFRResponseIndexInvalid", "NormalizationColumns"]]];
  If[! AllTrue[Join[particular, Flatten[nullspace],
      Flatten[rowMinorInverse], Flatten[normalizationMinorInverse]],
      IntegerQ[#] && 0 <= # < modulus &],
    Return[fail["CFFRResponseNoncanonicalWord", "Payload"]]];
  <|"Status" -> "OK", "Protocol" -> "CFFR1", "Magic" -> "CFFR1X1",
    "Rows" -> rows, "Columns" -> columns, "Modulus" -> modulus,
    "Rank" -> rank, "Nullity" -> nullity, "Nonce" -> request["Nonce"],
    "PayloadWordCount" -> payloadWords,
    "PivotColumns" -> pivotColumns + 1,
    "FreeColumns" -> freeColumns + 1,
    "IndependentEquationRows" -> independentRows + 1,
    "NormalizationColumns" -> normalizationColumns + 1,
    "ParticularSolution" -> particular, "NullspaceBasis" -> nullspace,
    "RowMinorInverse" -> rowMinorInverse,
    "NormalizationMinorInverse" -> normalizationMinorInverse,
    "ResponseFile" -> file,
    "ResponseSHA256" -> FileHash[file, "SHA256", "HexString"]|>
];
finiteFieldStripCFFRResponse[___] :=
  finiteFieldStripCFFRFailure["CFFRResponseParserArgumentsInvalid"];

(* Item 4: the adapter's internal witnesses are not the acceptance.  This
   is the check the CFFA4 path applies to an imported solution -- the
   residual on ALL original rows, the nullspace residual, and the
   canonical structure on the free columns -- at O(m n (k+1)) mod-p dots.
   The k x k normalization minor is re-multiplied as well, because a
   nonsingular nullspace block on the normalization columns is exactly
   the precondition the constrained core needs; the r x r row minor is
   NOT re-multiplied (an O(r^3) product is outside item 4's stated cost,
   and a wrong row basis is caught by the all-row residual of every
   follower sample). *)
finiteFieldStripCFFRVerify[matrix_, rightHandSide_, prime_Integer,
    response_Association, expectedRank_] := Module[
  {fail, rows, rank, nullity, free, normalization, particular, nullspace,
   normalizationInverse, identity},
  fail[field_String] := finiteFieldStripCFFRFailure[
    "CFFRVerificationFailed", <|"DivergentField" -> field|>];
  rows = response["Rows"];
  rank = response["Rank"];
  nullity = response["Nullity"];
  free = response["FreeColumns"];
  normalization = response["NormalizationColumns"];
  particular = response["ParticularSolution"];
  nullspace = response["NullspaceBasis"];
  normalizationInverse = response["NormalizationMinorInverse"];
  identity = Normal[IdentityMatrix[Max[nullity, 1]]];
  If[IntegerQ[expectedRank] && expectedRank =!= rank,
    Return[fail["Rank"]]];
  If[Normal[Mod[matrix . particular - rightHandSide, prime]] =!=
      ConstantArray[0, rows],
    Return[fail["ParticularResidual"]]];
  If[nullity > 0 && Normal[Mod[matrix . Transpose[nullspace], prime]] =!=
      ConstantArray[0, {rows, nullity}],
    Return[fail["NullspaceResidual"]]];
  If[nullity > 0 && Normal[nullspace[[All, free]]] =!= identity,
    Return[fail["FreeColumnIdentity"]]];
  If[nullity > 0 && particular[[free]] =!= ConstantArray[0, nullity],
    Return[fail["ParticularFreeCoordinates"]]];
  If[nullity > 0 && (
      Normal[Mod[nullspace[[All, normalization]] . normalizationInverse,
        prime]] =!= identity ||
      Normal[Mod[normalizationInverse . nullspace[[All, normalization]],
        prime]] =!= identity),
    Return[fail["NormalizationMinorInverse"]]];
  <|"Status" -> "OK", "GenericRank" -> rank, "Nullity" -> nullity|>
];
finiteFieldStripCFFRVerify[___] :=
  finiteFieldStripCFFRFailure["CFFRVerificationArgumentsInvalid"];

(* the request and response files live in the caller's artifact
   directory; with no artifact directory a private temporary one is
   created and removed again with them *)
finiteFieldStripCFFRDirectory[directory_] := Which[
  StringQ[directory] && DirectoryQ[directory], {directory, False},
  StringQ[directory],
    With[{created = Quiet[Check[CreateDirectory[directory,
        CreateIntermediateDirectories -> True], $Failed]]},
      If[StringQ[created], {created, False}, {$Failed, False}]],
  True,
    With[{created = Quiet[Check[CreateDirectory[], $Failed]]},
      If[StringQ[created], {created, True}, {$Failed, False}]]];

(* One adapter call.  Unique request/response file names, both deleted on
   success and KEPT on failure (the failure record names them), thread
   argument capped at the licence box's 8 P-cores.  Exit 5 is a verdict
   on the image, not a defect, and is typed as such. *)
finiteFieldStripCFFRRun[matrix_, rightHandSide_, prime_Integer,
    preference_List, threads_Integer, directory_] := Module[
  {hashes, resolved, owned, tag, requestFile, responseFile, request,
   written, process, exitCode, parsed, threadArgument, result, cleanup},
  hashes = finiteFieldStripCFFRAdapterHashes[];
  If[Lookup[hashes, "Status", None] =!= "OK", Return[hashes]];
  {resolved, owned} = finiteFieldStripCFFRDirectory[directory];
  If[! StringQ[resolved],
    Return[finiteFieldStripCFFRFailure["CFFRArtifactDirectoryUnavailable",
      <|"ArtifactDirectory" -> directory|>]]];
  request = finiteFieldStripCFFRRequest[matrix, rightHandSide, prime,
    preference, finiteFieldStripCFFRNonce[]];
  If[Lookup[request, "Status", None] =!= "OK",
    If[owned, Quiet[DeleteDirectory[resolved]]];
    Return[request]];
  tag = "cffr1_" <> ToString[$ProcessID] <> "_" <>
    StringReplace[CreateUUID[], "-" -> ""];
  requestFile = FileNameJoin[{resolved, tag <> "_request.bin"}];
  responseFile = FileNameJoin[{resolved, tag <> "_response.bin"}];
  cleanup[] := (
    Quiet[DeleteFile[Select[{requestFile, responseFile}, FileExistsQ]]];
    If[owned && DirectoryQ[resolved] && FileNames["*", resolved] === {},
      Quiet[DeleteDirectory[resolved]]]);
  written = finiteFieldStripCFFRWriteRequest[request, requestFile];
  If[Lookup[written, "Status", None] =!= "OK",
    Return[Join[written, <|"RequestFile" -> requestFile,
      "ResponseFile" -> responseFile|>]]];
  threadArgument = Max[1, Min[threads, 8]];
  process = Quiet[Check[RunProcess[{hashes["AdapterBinary"], requestFile,
    responseFile, ToString[threadArgument]}], $Failed]];
  exitCode = If[AssociationQ[process], Lookup[process, "ExitCode", -1], -1];
  If[exitCode =!= 0,
    Return[finiteFieldStripCFFRFailure[
      If[exitCode === 5, "InconsistentModularSystem",
        "CFFRAdapterExitNonzero"],
      <|"AdapterExitCode" -> exitCode,
        "AdapterStandardError" -> If[AssociationQ[process],
          Lookup[process, "StandardError", ""], ""],
        "RequestFile" -> requestFile, "ResponseFile" -> responseFile,
        "RequestSHA256" -> written["RequestSHA256"],
        "Nonce" -> request["Nonce"], "Threads" -> threadArgument|>]]];
  parsed = finiteFieldStripCFFRResponse[responseFile,
    Append[request, "AdapterExitCode" -> exitCode]];
  If[Lookup[parsed, "Status", None] =!= "OK",
    Return[Join[parsed, <|"RequestFile" -> requestFile,
      "RequestSHA256" -> written["RequestSHA256"],
      "Nonce" -> request["Nonce"], "Threads" -> threadArgument|>]]];
  result = <|"Status" -> "OK", "Protocol" -> "CFFR1",
    "Request" -> KeyDrop[request, {"Matrix", "RightHandSide"}],
    "Response" -> KeyDrop[parsed, "ResponseFile"],
    "AdapterExitCode" -> exitCode,
    "AdapterBinary" -> hashes["AdapterBinary"],
    "AdapterBinarySHA256" -> hashes["AdapterBinarySHA256"],
    "AdapterSourceSHA256" -> hashes["AdapterSourceSHA256"],
    "Nonce" -> request["Nonce"],
    "RequestSHA256" -> written["RequestSHA256"],
    "ResponseSHA256" -> parsed["ResponseSHA256"],
    "Threads" -> threadArgument|>;
  cleanup[];
  result
];
finiteFieldStripCFFRRun[___] :=
  finiteFieldStripCFFRFailure["CFFRRunArgumentsInvalid"];

(* Plan discovery through the adapter: one call returns rank/nullity, the
   pivot/free partition, an independent row basis and the normalization
   columns.  The plan it returns is the same object
   finiteFieldStripDiscoverPlan produces, plus the "Binding" the caller
   seals with (item 5).  `expectedRank` is the discovery-side rank the
   caller already knows (Automatic to skip that cross-check). *)
finiteFieldStripCFFRDiscoverPlan[matrix_, rightHandSide_,
    gaugeUnknownCount_Integer, freeResidueCount_Integer,
    numeratorDegrees_List, denominatorDegrees_List, prime_Integer,
    threads_Integer, directory_, expectedRank_] := Module[
  {equationCount, unknownCount, preference, run, response, verification},
  {equationCount, unknownCount} = Dimensions[matrix];
  If[unknownCount =!= gaugeUnknownCount + freeResidueCount,
    Return[finiteFieldStripCFFRFailure["CFFRUnknownLayoutMismatch",
      <|"UnknownCount" -> unknownCount,
        "GaugeUnknownCount" -> gaugeUnknownCount,
        "FreeResidueCount" -> freeResidueCount|>]]];
  (* the wire preference is the residue-first order that
     finiteFieldStripNormalizationColumns greedily walks *)
  preference = Join[gaugeUnknownCount + Range[freeResidueCount],
    Range[gaugeUnknownCount]];
  run = finiteFieldStripCFFRRun[matrix, rightHandSide, prime, preference,
    threads, directory];
  If[Lookup[run, "Status", None] =!= "OK", Return[run]];
  response = run["Response"];
  verification = finiteFieldStripCFFRVerify[matrix, rightHandSide, prime,
    response, expectedRank];
  If[Lookup[verification, "Status", None] =!= "OK",
    Return[Join[verification, <|"Nonce" -> run["Nonce"],
      "RequestSHA256" -> run["RequestSHA256"],
      "ResponseSHA256" -> run["ResponseSHA256"]|>]]];
  <|"Status" -> "OK",
    "NormalizationColumns" -> response["NormalizationColumns"],
    "IndependentEquationRows" -> response["IndependentEquationRows"],
    "GenericRank" -> response["Rank"], "Nullity" -> response["Nullity"],
    "UnknownCount" -> unknownCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "FreeResidueCount" -> freeResidueCount,
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "PilotPrime" -> prime,
    "PivotColumns" -> response["PivotColumns"],
    "FreeColumns" -> response["FreeColumns"],
    "Binding" -> <|
      "AdapterSourceSHA256" -> run["AdapterSourceSHA256"],
      "AdapterBinarySHA256" -> run["AdapterBinarySHA256"],
      "Protocol" -> "CFFR1", "Nonce" -> run["Nonce"],
      "RequestSHA256" -> run["RequestSHA256"],
      "ResponseSHA256" -> run["ResponseSHA256"],
      "Threads" -> run["Threads"]|>|>
];
finiteFieldStripCFFRDiscoverPlan[___] :=
  finiteFieldStripCFFRFailure["CFFRDiscoveryArgumentsInvalid"];

$finiteFieldLearningPass = False;
$finiteFieldLastUnseenSample = <||>;

Options[SampleEpsFormStripAffine] = {
  "Support" -> Automatic,
  "SupportShell" -> 0,
  "Backend" -> Automatic,
  "BackendThreads" -> 2,
  "PlanDiscoveryBackend" -> "Wolfram",
  "PointCount" -> Automatic,
  "NumeratorDegreeOffset" -> {0, 0},
  "SolveAffineSystem" -> True,
  "RandomSeed" -> 2540908,
  "Preparation" -> Automatic,
  "ExpectedFingerprint" -> Automatic,
  "EliminationPlan" -> None,
  "DiscoverPlan" -> False,
  (* where the CFFR1 plan-discovery adapter stages its request and
     response files (Automatic: a private temporary directory) *)
  "ArtifactDirectory" -> Automatic
};

(* M1 (Codex A1, standardized 2026-08-20 after exact reproduction of the
   frozen CF254 (9,7) oracle): a pilot sample solved by the full path
   discovers a plan -- nullity normalization columns S whose nullspace
   block is nonsingular and a row basis R of the sampled system -- and
   every later sample solves the SQUARE constrained core
   [A[[R]]; E_S] once, with nullity+1 right-hand sides, giving the
   normalized particular solution and normalized nullspace basis in one
   factorization. Acceptance per sample: A.p == b on ALL original rows,
   A.N == 0, normalization block canonical; otherwise the sample is
   discarded (typed status) and never interpolated. *)
finiteFieldStripIndependentRows[matrix_, rank_Integer, prime_Integer] :=
 Module[{candidate, candidateRank, leftNullspace, reduced, pivots, rows},
  candidate = Range[rank];
  candidateRank = MatrixRank[matrix[[candidate]], Modulus -> prime];
  If[candidateRank === rank, Return[candidate]];
  leftNullspace = NullSpace[Transpose[matrix], Modulus -> prime];
  reduced = RowReduce[leftNullspace, Modulus -> prime];
  pivots = DeleteMissing[
    Function[row, FirstCase[Range[Length[row]],
      index_ /; row[[index]] =!= 0, Missing["NoPivot"]]] /@ reduced];
  rows = Complement[Range[Length[matrix]], pivots];
  If[Length[rows] =!= rank ||
      MatrixRank[matrix[[rows]], Modulus -> prime] =!= rank,
    $Failed, rows]
];

(* normalization columns of an affine solution family: independent
   columns of the nullspace, residue columns first, extended by gauge
   columns when the nullspace has pure constant-gauge directions that
   change no residue (e and c sharing eigenstructure: CF209/211/213/217,
   2026-08-22, "PlanNormalizationDiscoveryFailed" -> NormalizationInvalid) *)
finiteFieldStripNormalizationColumns[nullspace_List, gaugeUnknownCount_Integer,
    freeResidueCount_Integer, prime_Integer] := Module[{order, chosen},
  If[nullspace === {}, Return[{}]];
  order = Join[gaugeUnknownCount + Range[freeResidueCount], Range[gaugeUnknownCount]];
  chosen = finiteFieldStripIndependentColumns[nullspace[[All, order]], prime];
  Sort[order[[chosen]]]];

finiteFieldStripDiscoverPlan[matrix_, rank_Integer, nullspace_List,
    gaugeUnknownCount_Integer, freeResidueCount_Integer,
    numeratorDegrees_List, denominatorDegrees_List, prime_Integer] :=
 Module[{unknownCount, nullity, residueColumns, normalizationColumns,
   rows, selector, core, coreRank},
  unknownCount = Length[First[matrix]];
  nullity = Length[nullspace];
  residueColumns = gaugeUnknownCount + Range[freeResidueCount];
  normalizationColumns = If[nullity === 0, {},
    finiteFieldStripNormalizationColumns[nullspace, gaugeUnknownCount, freeResidueCount, prime]];
  If[Length[normalizationColumns] =!= nullity,
    Return[<|"Status" -> "PlanNormalizationDiscoveryFailed"|>]];
  rows = finiteFieldStripIndependentRows[matrix, rank, prime];
  If[rows === $Failed, Return[<|"Status" -> "PlanRowSelectionFailed"|>]];
  core = If[nullity === 0, matrix[[rows]],
    Join[matrix[[rows]], SparseArray[
      MapIndexed[{First[#2], #1} -> 1 &, normalizationColumns],
      {nullity, unknownCount}]]];
  coreRank = MatrixRank[core, Modulus -> prime];
  If[coreRank =!= unknownCount,
    Return[<|"Status" -> "PlanConstrainedCoreSingular",
      "ConstrainedCoreRank" -> coreRank|>]];
  <|"Status" -> "OK", "NormalizationColumns" -> normalizationColumns,
    "IndependentEquationRows" -> rows, "GenericRank" -> rank,
    "Nullity" -> nullity, "UnknownCount" -> unknownCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "FreeResidueCount" -> freeResidueCount,
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "PilotPrime" -> prime|>
];

(* O1 (2026-08-20): the regulator- and prime-independent setup of one
   off-diagonal block -- alphabet (a CANONICA call), dlog table,
   residue layout, forcing coefficients, denominator factor census and
   gauge denominator -- measured at 35% of the CF254 (9,6) solve when
   rebuilt on every sample. It is computed once here, fingerprinted,
   and reused by every sample of every prime. The contents are exactly
   what the per-call code computed before; nothing in the acceptance
   changes. *)
finiteFieldStripFingerprint[record_Association] := Hash[{
  record["Strip"], record["Variables"],
  SymbolName[record["Regulator"]],
  Lookup[record, "GaugeDenominatorFactor", 1],
  Lookup[record, "ExtraLetters", {}]}, "SHA256", "HexString"];

finiteFieldStripPrepare[record_Association] := Module[
  {start = AbsoluteTime[], variables, epsilon, e, c, bbar, dimensions,
   upperDimension, lowerDimension, alphabet, dlog, residueTriples,
   freeResidues, forcingConstant, forcingCoefficients, factorPairs,
   factors, factorPowers, gaugeFactorPowers, gaugeDenominator,
   denominatorDegrees, symbolicForms, supportCensus},
  variables = record["Variables"];
  epsilon = record["Regulator"];
  {e, c, bbar} = record["Strip"];
  dimensions = Dimensions[bbar[[1]]];
  {upperDimension, lowerDimension} = dimensions;
  alphabet = epsFormStripAlphabet[record["Strip"], variables, epsilon];
  If[alphabet === $Failed, Return[$Failed]];
  (* record key "ExtraLetters": letters the block's own entries do not
     show but a residue needs (EpsFormStripObstruction "MissingLetters") *)
  alphabet = DeleteDuplicates[Join[alphabet, Lookup[record, "ExtraLetters", {}]]];
  dlog = Table[
    Together[D[Log[alphabet[[a]]], variables[[mu]]]],
    {a, Length[alphabet]}, {mu, 2}];
  residueTriples = Flatten[
    Table[{a, i, j}, {a, Length[alphabet]},
      {i, upperDimension}, {j, lowerDimension}], 2];
  freeResidues = Array[Unique["rawK"] &, Length[residueTriples]];
  forcingConstant = bbar;
  forcingCoefficients = Map[
    Function[triple,
      With[{a = triple[[1]], i = triple[[2]], j = triple[[3]]},
        Table[-epsilon dlog[[a, mu]]*
          Normal[SparseArray[{{i, j} -> 1}, dimensions]],
          {mu, 2}]]],
    residueTriples];
  factorPairs = Flatten[
    finiteFieldStripEntryFactorList /@ Flatten[bbar], 1];
  factors = If[factorPairs === {}, {},
    DeleteDuplicates[factorPairs[[All, 1]], SameQ]];
  factorPowers = Table[
    {factor, Max[Cases[factorPairs,
      {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
    {factor, factors}];
  gaugeFactorPowers = Select[factorPowers,
    Last[#] > 1 && ! FreeQ[First[#], Alternatives @@ variables] &];
  gaugeDenominator = Times @@
    ((First[#]^(Last[#] - 1)) & /@ gaugeFactorPowers);
  (* optional widening of the gauge denominator (record key
     "GaugeDenominatorFactor", a polynomial in the variables): the A3
     denominator admits poles only where the forcing has a higher-order
     pole; at a regulator resonance (an eps-dependent factor in the
     forcing's denominator, e.g. 1 + 4 eps on CF305 block (18,15),
     2026-08-22) the gauge may carry simple poles at further letters *)
  gaugeDenominator = gaugeDenominator * Lookup[record, "GaugeDenominatorFactor", 1];
  denominatorDegrees = Exponent[gaugeDenominator, #] & /@ variables;
  (* A3 (Codex round 2, standardized 2026-08-21): a-priori bound on the
     gauge numerator support from valuations.  At infinity, a first-order
     Fuchsian equation allows the gauge one more order than the forcing;
     with the diagonal epsilon forms and every dlog derivative
     logarithmic at infinity (degree <= -1) and all finite poles simple,
     the numerator total degree is bounded by the denominator total
     degree plus max(0, forcing infinity degree + 1).  The closure
     certificate records which of these hypotheses hold; when one fails
     the rectangle is used. *)
  supportCensus = Module[{totalDegree, infinityDegree, finitePoleOrder,
      forcingInfinity, diagonalInfinity, dlogInfinity, diagonalPoles,
      dlogPoles, bound},
    totalDegree[0] = -Infinity;
    totalDegree[poly_] := With[{rules = CoefficientRules[Expand[poly], variables]},
      If[rules === {}, -Infinity, Max[Total /@ rules[[All, 1]]]]];
    infinityDegree[expr_] := With[{q = Cancel[Together[expr]]},
      If[TrueQ[q === 0], -Infinity,
        totalDegree[Numerator[q]] - totalDegree[Denominator[q]]]];
    finitePoleOrder[exprs_] := With[{pairs = Flatten[
        Rest[FactorList[Denominator[Cancel[Together[#]]]]] & /@ Flatten[exprs], 1]},
      If[pairs === {}, 0, Max[pairs[[All, 2]]]]];
    forcingInfinity = Max[infinityDegree /@ Flatten[bbar]];
    diagonalInfinity = Max[DeleteCases[infinityDegree /@ Flatten[{e, c}], -Infinity]];
    dlogInfinity = Max[DeleteCases[infinityDegree /@ Flatten[dlog], -Infinity]];
    diagonalPoles = finitePoleOrder[{e, c}];
    dlogPoles = finitePoleOrder[dlog];
    bound = totalDegree[gaugeDenominator] + Max[0, forcingInfinity + 1];
    <|"ForcingInfinityDegree" -> forcingInfinity,
      "DenominatorTotalDegree" -> totalDegree[gaugeDenominator],
      "NumeratorTotalDegreeBound" -> bound,
      "DiagonalInfinityLogarithmicQ" -> TrueQ[diagonalInfinity <= -1],
      "DLogInfinityLogarithmicQ" -> TrueQ[dlogInfinity <= -1],
      "DiagonalFinitePolesAtMostSimpleQ" -> diagonalPoles <= 1,
      "DLogFinitePolesAtMostSimpleQ" -> dlogPoles <= 1,
      "CertifiedQ" -> TrueQ[diagonalInfinity <= -1] && TrueQ[dlogInfinity <= -1] &&
        diagonalPoles <= 1 && dlogPoles <= 1 && forcingInfinity =!= -Infinity|>];
  (* O2b: every rational entry as numerator/denominator polynomials in
     {x, y, eps} with exact rational coefficients, computed once per
     block; reduced once per prime by finiteFieldStripPrimeForms and
     collapsed in eps per sample -- replacing Together + CoefficientRules
     at the substituted regulator on every sample *)
  symbolicForms = With[{vars = Append[variables, epsilon]},
    Module[{poly3, rational},
      poly3[polynomial_] := Module[{rules},
        rules = List @@@ CoefficientRules[polynomial, vars];
        If[rules === {}, {{}, {}, {}, {}},
          {rules[[All, 2]], rules[[All, 1, 1]], rules[[All, 1, 2]],
           rules[[All, 1, 3]]}]];
      rational[expression_] := Module[{q = Together[expression]},
        {poly3[Numerator[q]], poly3[Denominator[q]]}];
      (* 2026-08-22: the residue columns are built from the dlog forms
         (alphabet x 2) and the triple structure, not from the tensor of
         forcing coefficients that is zero everywhere except one entry
         per triple -- 6656 evaluations per point on CF254 (9,7) against 26 *)
      {Map[rational, e, {3}], Map[rational, c, {3}],
       Map[rational, forcingConstant, {3}],
       Map[rational, dlog, {2}],
       rational[gaugeDenominator],
       rational /@ (D[gaugeDenominator, #] & /@ variables)}]];
  <|"Fingerprint" -> finiteFieldStripFingerprint[record],
    "SymbolicForms" -> symbolicForms,
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions, "Alphabet" -> alphabet, "DLog" -> dlog,
    "ResidueTriples" -> residueTriples, "FreeResidues" -> freeResidues,
    "ForcingConstant" -> forcingConstant,
    "ForcingCoefficients" -> forcingCoefficients,
    "GaugeDenominator" -> gaugeDenominator,
    "DenominatorDegrees" -> denominatorDegrees,
    "SupportCensus" -> supportCensus,
    "PrepareSeconds" -> AbsoluteTime[] - start|>
];

(* the gauge numerator support for given numerator degrees: the
   bidegree rectangle in row-major order, intersected with the total-
   degree half-space when requested.  shell >= 0 widens the half-space
   by that many total degrees; the rectangle itself is the terminal
   member of the ladder. *)
finiteFieldStripSupport[preparation_Association, numeratorDegrees_List,
    kind_, shell_Integer: 0] := Module[{rectangle, census, bound},
  rectangle = Flatten[Table[{px, py}, {px, 0, numeratorDegrees[[1]]},
    {py, 0, numeratorDegrees[[2]]}], 1];
  census = Lookup[preparation, "SupportCensus", <||>];
  Which[
    ListQ[kind], kind,
    kind === "Rectangle" || ! TrueQ[Lookup[census, "CertifiedQ", False]], rectangle,
    kind === "Sparse",
      (* the bidegree rectangle cut by the total-degree bound: cheaper,
         but the rectangle (denominator degrees + offset per variable) is
         a heuristic with no certificate; CF305 block (18,15) needs
         x-degree 6 with denominator x-degree 3 and was a false negative *)
      bound = census["NumeratorTotalDegreeBound"] + shell;
      If[bound >= Total[numeratorDegrees], rectangle,
        Select[rectangle, Total[#] <= bound &]],
    True,
      (* "Simplex"/Automatic: the whole certified total-degree simplex *)
      bound = census["NumeratorTotalDegreeBound"] + shell;
      Select[Flatten[Table[{px, py}, {px, 0, bound}, {py, 0, bound}], 1],
        Total[#] <= bound &]]
];

(* probe order for one numerator-degree offset: the smallest support
   first (the usual success), then the full rectangle -- an inconsistent
   rectangle rules out every sub-support at this offset, so nothing
   else is probed -- and only when the rectangle is consistent the
   intermediate shells in ascending order (the first consistent one is
   selected, the rectangle being the fallback).  The former order walked
   every shell before the rectangle and spent seven probes on an offset
   that no support could satisfy (CF254 (9,7), 2026-08-21). *)
finiteFieldStripProbeOrder[shells_List] := Which[
  shells === {"Rectangle"}, {"Rectangle"},
  Length[shells] === 2, shells,
  True, Join[{First[shells], "Rectangle"}, shells[[2 ;; -2]]]];

finiteFieldStripSupportLadder[preparation_Association, numeratorDegrees_List, kind_: Automatic] :=
  Module[{census = Lookup[preparation, "SupportCensus", <||>], bound},
    If[! TrueQ[Lookup[census, "CertifiedQ", False]], Return[{"Rectangle"}]];
    bound = census["NumeratorTotalDegreeBound"];
    Which[
      kind === "Sparse",
        (* sub-supports of the rectangle: the rectangle itself when the
           bound already contains it *)
        If[bound >= Total[numeratorDegrees], {"Rectangle"},
          Append[Range[0, Total[numeratorDegrees] - bound - 1], "Rectangle"]],
      True,
        (* shell 0 (the certified simplex) first; it is not a subset of
           the rectangle (2026-08-22) *)
        If[bound >= Total[numeratorDegrees], {0, "Rectangle"},
          Append[Range[0, Total[numeratorDegrees] - bound - 1], "Rectangle"]]]
  ];

(* per-prime reduction of the symbolic forms, memoized by (fingerprint,
   prime): each polynomial becomes {xExponents, yExponents,
   coefficientMatrix} where row m holds the mod-p coefficients of
   eps^0..eps^K for monomial m; a sample collapses it with the powers of
   its regulator value *)
$finiteFieldStripPrimeFormCache = <||>;
finiteFieldStripPrimeForms[preparation_Association, prime_Integer] :=
 Module[{key, modNumber, reducePoly, reduceRational, forms},
  key = {preparation["Fingerprint"], prime};
  If[KeyExistsQ[$finiteFieldStripPrimeFormCache, key],
    Return[$finiteFieldStripPrimeFormCache[key]]];
  modNumber[value_] := Mod[Mod[Numerator[value], prime] PowerMod[
    Mod[Denominator[value], prime], -1, prime], prime];
  reducePoly[{coefficients_, xs_, ys_, ks_}] := Module[
    {groups, maxK, ix, iy, matrix},
    If[coefficients === {}, Return[{{}, {}, {}}]];
    maxK = Max[ks];
    groups = GatherBy[Transpose[{xs, ys, ks, modNumber /@ coefficients}],
      Most[Most[#]] &];
    ix = groups[[All, 1, 1]]; iy = groups[[All, 1, 2]];
    matrix = Table[
      Module[{row = ConstantArray[0, maxK + 1]},
        Do[row[[term[[3]] + 1]] = Mod[row[[term[[3]] + 1]] + term[[4]],
          prime], {term, group}];
        row],
      {group, groups}];
    {Developer`ToPackedArray[ix], Developer`ToPackedArray[iy],
     Developer`ToPackedArray[matrix]}];
  reduceRational[{numerator_, denominator_}] :=
    {reducePoly[numerator], reducePoly[denominator]};
  forms = preparation["SymbolicForms"];
  forms = {Map[reduceRational, forms[[1]], {3}],
    Map[reduceRational, forms[[2]], {3}],
    Map[reduceRational, forms[[3]], {3}],
    Map[reduceRational, forms[[4]], {2}],
    reduceRational[forms[[5]]], reduceRational /@ forms[[6]]};
  If[Length[$finiteFieldStripPrimeFormCache] > 16,
    $finiteFieldStripPrimeFormCache = <||>];
  $finiteFieldStripPrimeFormCache[key] = forms;
  forms
];

PrepareEpsFormStripSampling[record_Association] :=
  If[finiteFieldStripRecordQ[record], finiteFieldStripPrepare[record],
    Message[SampleEpsFormStripAffine::record]; $Failed];
PrepareEpsFormStripSampling[_] := $Failed;

SampleEpsFormStripAffine[
    record_Association, epsilonValue_, prime_Integer,
    OptionsPattern[]] := Module[
  {variables, epsilon, e, c, bbar, x, y, dimensions,
   upperDimension, lowerDimension, alphabet, dlog, residueTriples,
   freeResidues, forcingConstant, forcingCoefficients, factorPairs,
   factors, factorPowers, gaugeFactorPowers, gaugeDenominator,
   denominatorDegrees, degreeOffset, numeratorDegrees, equationCount,
   gaugeUnknownCount, unknownCount, requestedPointCount, solveAffineQ,
   randomSeed, epsilonMod, modNumber, polynomialRules, rationalForm,
   evaluatePolynomial, evaluateRational, preprocessedForms,
   preprocessingSeconds, eForms, cForms, forcingConstantForms,
   dlogForms, gaugeDenominatorForm,
   gaugeDenominatorDerivativeForms, columnIndex, buildPointRows,
   pointRows = {}, pointRightHandSides = {}, acceptedPoints = {},
   attemptCount = 0, maximumAttempts, point, pointResult, matrix,
   rightHandSide, augmented, rank, augmentedRank, rankSeconds,
   augmentedRankSeconds, affineData = <||>, linearSolveSeconds, planSeconds,
   nullspaceSeconds, particularSolution, nullspaceBasis,
   samplingSeconds, samplingResult, setupStart, setupSeconds,
   preparation, preparationReused, eliminationPlan, discoverPlanQ,
   planCompatible, selector, core, rhsMatrix, solutionMatrix,
   constrainedSeconds, normalizationOK, planResult, discard,
   maximumExponents, tableExponents, blockLength, collapsePoly,
   collapseRational, support, supportX, supportY, backendUsed = None,
   backendRequested, backendThreads, backendDecision,
   planDiscoveryBackend, planDiscoveryDecision,
   planDiscoveryBackendUsed = None, backendFallbackReason = None,
   backendFailure = None,
   planValidation = <|"Status" -> "NoEliminationPlan"|>},

  If[! finiteFieldStripRecordQ[record],
    Message[SampleEpsFormStripAffine::record]; Return[$Failed]];
  backendRequested = OptionValue["Backend"];
  backendThreads = OptionValue["BackendThreads"];
  backendDecision = finiteFieldStripBackendDecision[
    backendRequested, backendThreads, 0];
  If[Lookup[backendDecision, "Status", None] =!= "OK",
    Return[backendDecision]];
  planDiscoveryBackend = OptionValue["PlanDiscoveryBackend"];
  planDiscoveryDecision = finiteFieldStripPlanDiscoveryBackendDecision[
    planDiscoveryBackend];
  If[Lookup[planDiscoveryDecision, "Status", None] =!= "OK",
    Return[planDiscoveryDecision]];
  degreeOffset = OptionValue["NumeratorDegreeOffset"];
  requestedPointCount = OptionValue["PointCount"];
  solveAffineQ = TrueQ[OptionValue["SolveAffineSystem"]];
  randomSeed = OptionValue["RandomSeed"];
  (* O2 width guard (Codex round-2 add-on): the packed monomial
     evaluator reduces products of two residues modulo the prime and
     sums them in machine integers, which is exact only for primes
     below 2^31; a wider prime would overflow silently. *)
  If[IntegerQ[prime] && prime >= 2^31,
    Message[SampleEpsFormStripAffine::width, prime]; Return[$Failed]];
  If[! PrimeQ[prime] || prime <= 3 ||
      ! MatchQ[epsilonValue, _Integer | _Rational] ||
      Mod[Denominator[epsilonValue], prime] === 0 ||
      ! MatchQ[degreeOffset,
        {a_Integer, b_Integer} /; a >= 0 && b >= 0] ||
      ! (requestedPointCount === Automatic ||
        IntegerQ[requestedPointCount] && requestedPointCount > 0) ||
      ! IntegerQ[randomSeed],
    Message[SampleEpsFormStripAffine::input]; Return[$Failed]];

  (* M0 instrumentation: the symbolic setup (alphabet, dlog table,
     residue layout, factor census, ansatz) was untimed -- the
     2026-08-20 assessment could not see it. *)
  setupStart = AbsoluteTime[];
  preparation = OptionValue["Preparation"];
  (* the strong guard hashes the whole strip (~0.5 s on a 1.5 MB
     record, measured 2026-08-20); a caller that prepared the record
     itself passes the fingerprint it computed once instead *)
  preparationReused = AssociationQ[preparation] &&
    Lookup[preparation, "Fingerprint", None] ===
      Replace[OptionValue["ExpectedFingerprint"],
        Automatic :> finiteFieldStripFingerprint[record]];
  If[! preparationReused,
    preparation = finiteFieldStripPrepare[record];
    If[preparation === $Failed,
      Message[SampleEpsFormStripAffine::alphabet]; Return[$Failed]]];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  {x, y} = variables;
  {e, c, bbar} = record["Strip"];
  dimensions = preparation["Dimensions"];
  {upperDimension, lowerDimension} = dimensions;
  alphabet = preparation["Alphabet"];
  dlog = preparation["DLog"];
  residueTriples = preparation["ResidueTriples"];
  freeResidues = preparation["FreeResidues"];
  forcingConstant = preparation["ForcingConstant"];
  forcingCoefficients = preparation["ForcingCoefficients"];
  gaugeDenominator = preparation["GaugeDenominator"];
  denominatorDegrees = preparation["DenominatorDegrees"];
  numeratorDegrees = denominatorDegrees + degreeOffset;
  equationCount = 2 upperDimension lowerDimension;
  (* A3: the gauge numerator support (a list of {px, py}) replaces the
     full bidegree rectangle; Automatic uses the valuation bound when the
     closure certificate holds *)
  support = finiteFieldStripSupport[preparation, numeratorDegrees,
    OptionValue["Support"], OptionValue["SupportShell"]];
  If[! MatchQ[support, {{_Integer, _Integer} ..}],
    Message[SampleEpsFormStripAffine::input]; Return[$Failed]];
  gaugeUnknownCount = upperDimension lowerDimension Length[support];
  unknownCount = gaugeUnknownCount + Length[freeResidues];
  requestedPointCount = Replace[requestedPointCount,
    Automatic :> Max[16,
      Ceiling[(unknownCount + equationCount)/equationCount]]];
  maximumAttempts = 20 requestedPointCount;
  epsilonMod = Mod[
    Numerator[epsilonValue]*
      PowerMod[Mod[Denominator[epsilonValue], prime], -1, prime],
    prime];

  modNumber[value_] := Module[{numeratorValue, denominatorValue},
    If[! FreeQ[value, _Symbol], Throw[$Failed, "BadCoefficient"]];
    numeratorValue = Mod[Numerator[value], prime];
    denominatorValue = Mod[Denominator[value], prime];
    If[denominatorValue === 0, Throw[$Failed, "BadCoefficient"]];
    Mod[numeratorValue PowerMod[denominatorValue, -1, prime], prime]
  ];
  (* O2 (2026-08-21): a polynomial is stored as three packed vectors
     {coefficients mod p, x-exponents, y-exponents} and evaluated at a
     point from monomial power tables with packed machine arithmetic
     (every intermediate product < 2^62, reduced mod p before summing)
     instead of one PowerMod per monomial per point. Output values are
     identical to the former term-by-term evaluation. *)
  polynomialRules[polynomial_] := Module[{rules, nonzero},
    rules = List @@@ CoefficientRules[polynomial, variables];
    nonzero = Select[
      ({First[#], modNumber[Last[#]]} &) /@ rules, Last[#] =!= 0 &];
    If[nonzero === {}, {{}, {}, {}},
      {Developer`ToPackedArray[nonzero[[All, 2]]],
       Developer`ToPackedArray[nonzero[[All, 1, 1]]],
       Developer`ToPackedArray[nonzero[[All, 1, 2]]]}]
  ];
  rationalForm[expression_] := Module[{q = Together[expression]},
    {polynomialRules[Numerator[q]], polynomialRules[Denominator[q]]}
  ];
  evaluatePolynomial[{coefficients_, xExponents_, yExponents_},
      xPowers_, yPowers_] :=
    If[coefficients === {}, 0,
      Mod[Total[Mod[coefficients *
        Mod[xPowers[[xExponents + 1]] yPowers[[yExponents + 1]], prime],
        prime]], prime]];
  evaluateRational[form_List, xPowers_, yPowers_] := Module[
    {numeratorValue, denominatorValue},
    numeratorValue = evaluatePolynomial[form[[1]], xPowers, yPowers];
    denominatorValue = evaluatePolynomial[form[[2]], xPowers, yPowers];
    If[denominatorValue === 0, Throw[$Failed, "BadPoint"]];
    Mod[numeratorValue PowerMod[denominatorValue, -1, prime], prime]
  ];
  (* the monomial tables are the LEAVES {coefficients, xExponents,
     yExponents} (three integer vectors).  The former pattern
     {_List, _List, _List} also matched a ROW of three {numerator,
     denominator} pairs whenever a block has dimension 3, and then read
     coefficient residues as exponents: power tables of p - 1 entries per
     point (0.55 s per point on a 48-unknown strip, and a kernel death by
     memory at 31-bit primes) -- found 2026-08-22 on CF254 (12,11). *)
  maximumExponents[forms_] := Module[{polys},
    polys = Cases[forms,
      {c_, ix_, iy_} /; VectorQ[c, IntegerQ] && VectorQ[ix, IntegerQ] && VectorQ[iy, IntegerQ],
      {0, Infinity}];
    polys = Select[polys, First[#] =!= {} &];
    If[polys === {}, {0, 0},
      {Max[Max /@ polys[[All, 2]]], Max[Max /@ polys[[All, 3]]]}]
  ];

  collapsePoly[{ix_, iy_, matrix_}, epsPowers_] := Module[{coefs, keep},
    If[ix === {}, Return[{{}, {}, {}}]];
    coefs = Mod[matrix . Take[epsPowers, Length[First[matrix]]], prime];
    keep = Flatten[Position[coefs, Except[0], {1}, Heads -> False]];
    If[keep === {}, {{}, {}, {}},
      {Developer`ToPackedArray[coefs[[keep]]],
       Developer`ToPackedArray[ix[[keep]]],
       Developer`ToPackedArray[iy[[keep]]]}]];
  collapseRational[{numerator_, denominator_}, epsPowers_] :=
    {collapsePoly[numerator, epsPowers], collapsePoly[denominator, epsPowers]};
  setupSeconds = AbsoluteTime[] - setupStart;
  {preprocessingSeconds, preprocessedForms} = AbsoluteTiming[
   If[KeyExistsQ[preparation, "SymbolicForms"],
    Module[{primeForms, maxK, epsPowers},
      primeForms = finiteFieldStripPrimeForms[preparation, prime];
      maxK = Max[0, Max[Cases[primeForms,
        {_?VectorQ, _?VectorQ, m_?MatrixQ} :> Length[First[m]] - 1,
        {0, Infinity}]]];
      epsPowers = Table[PowerMod[epsilonMod, k, prime], {k, 0, maxK}];
      {Map[collapseRational[#, epsPowers] &, primeForms[[1]], {3}],
       Map[collapseRational[#, epsPowers] &, primeForms[[2]], {3}],
       Map[collapseRational[#, epsPowers] &, primeForms[[3]], {3}],
       Map[collapseRational[#, epsPowers] &, primeForms[[4]], {2}],
       collapseRational[primeForms[[5]], epsPowers],
       collapseRational[#, epsPowers] & /@ primeForms[[6]]}],
    {
    Map[rationalForm, e /. epsilon -> epsilonValue, {3}],
    Map[rationalForm, c /. epsilon -> epsilonValue, {3}],
    Map[rationalForm, forcingConstant /. epsilon -> epsilonValue, {3}],
    Map[rationalForm, dlog /. epsilon -> epsilonValue, {2}],
    rationalForm[gaugeDenominator /. epsilon -> epsilonValue],
    rationalForm[# /. epsilon -> epsilonValue] & /@
      (D[gaugeDenominator, #] & /@ variables)
    }]];
  {eForms, cForms, forcingConstantForms, dlogForms,
    gaugeDenominatorForm, gaugeDenominatorDerivativeForms} =
      preprocessedForms;
  (* power tables must cover the support's exponents, which since
     2026-08-22 (total-degree simplex) may exceed the bidegree rectangle *)
  tableExponents = MapThread[Max,
    {maximumExponents[preprocessedForms], numeratorDegrees,
     {Max[support[[All, 1]]], Max[support[[All, 2]]]}}];
  blockLength = Length[support];
  supportX = Developer`ToPackedArray[support[[All, 1]]];
  supportY = Developer`ToPackedArray[support[[All, 2]]];

  (* Row assembly is vectorized per gauge block: the (i,j) block of a
     row is a packed vector of length blockLength, the derivative and
     coupling contributions are scalar multiples of the flattened
     monomial tables, and the row is the concatenation of all blocks
     plus the residue columns -- the same entries the former scalar
     loop produced, column for column. *)
  buildPointRows[xValue_Integer, yValue_Integer] := Catch[Module[
    {xPowers, yPowers, eValue, cValue, forcing0Value, dlogValue,
     denominatorValue, derivativeDenominatorValues, inverseDenominator,
     phiFlat, derivativePhiFlat, rows, right, rowIndex = 0,
     blocks, residuePart, mu, i, j, aIndex, bIndex, residueIndex},
    xPowers = Table[PowerMod[Mod[xValue, prime], power, prime],
      {power, 0, tableExponents[[1]]}];
    yPowers = Table[PowerMod[Mod[yValue, prime], power, prime],
      {power, 0, tableExponents[[2]]}];
    eValue = Map[evaluateRational[#, xPowers, yPowers] &, eForms, {3}];
    cValue = Map[evaluateRational[#, xPowers, yPowers] &, cForms, {3}];
    forcing0Value = Map[evaluateRational[#, xPowers, yPowers] &,
      forcingConstantForms, {3}];
    (* the residue column of triple (a, i, j) in the row (mu, i, j)
       carries eps dlog_mu(phi_a): the alphabet x 2 values are evaluated
       once per point *)
    dlogValue = Map[evaluateRational[#, xPowers, yPowers] &, dlogForms, {2}];
    denominatorValue = evaluateRational[
      gaugeDenominatorForm, xPowers, yPowers];
    inverseDenominator = PowerMod[denominatorValue, -1, prime];
    derivativeDenominatorValues =
      evaluateRational[#, xPowers, yPowers] & /@
        gaugeDenominatorDerivativeForms;
    (* monomial tables over the support (row-major rectangle order
       restricted to the retained monomials) *)
    phiFlat = Mod[Mod[xPowers[[supportX + 1]] yPowers[[supportY + 1]], prime]
      inverseDenominator, prime];
    derivativePhiFlat = Table[
      Mod[
        If[mu === 1,
          Mod[supportX Mod[xPowers[[Max[#, 1] & /@ supportX]] yPowers[[supportY + 1]], prime], prime],
          Mod[supportY Mod[xPowers[[supportX + 1]] yPowers[[Max[#, 1] & /@ supportY]], prime], prime]]
          inverseDenominator -
        Mod[phiFlat derivativeDenominatorValues[[mu]], prime] inverseDenominator,
        prime],
      {mu, 2}];
    rows = ConstantArray[0, {equationCount, unknownCount}];
    right = ConstantArray[0, equationCount];
    Do[
      rowIndex++;
      blocks = ConstantArray[0, {upperDimension, lowerDimension,
        blockLength}];
      blocks[[i, j]] = derivativePhiFlat[[mu]];
      Do[
        blocks[[aIndex, j]] = Mod[blocks[[aIndex, j]] -
          Mod[epsilonMod eValue[[mu, i, aIndex]], prime] phiFlat, prime],
        {aIndex, upperDimension}];
      Do[
        blocks[[i, bIndex]] = Mod[blocks[[i, bIndex]] +
          Mod[epsilonMod cValue[[mu, bIndex, j]], prime] phiFlat, prime],
        {bIndex, lowerDimension}];
      residuePart = ConstantArray[0, Length[freeResidues]];
      Do[residuePart[[((aIndex - 1) upperDimension + (i - 1)) lowerDimension + j]] =
          Mod[epsilonMod dlogValue[[aIndex, mu]], prime],
        {aIndex, Length[dlogValue]}];
      rows[[rowIndex]] = Join[Flatten[blocks], residuePart];
      right[[rowIndex]] = forcing0Value[[mu, i, j]],
      {mu, 2}, {i, upperDimension}, {j, lowerDimension}];
    {SparseArray[rows], right}
  ], "BadPoint"];

  SeedRandom[randomSeed];
  {samplingSeconds, samplingResult} = AbsoluteTiming[
    While[Length[acceptedPoints] < requestedPointCount &&
        attemptCount < maximumAttempts,
      attemptCount++;
      point = RandomInteger[{2, prime - 2}, 2];
      pointResult = buildPointRows @@ point;
      If[pointResult =!= $Failed,
        AppendTo[acceptedPoints, point];
        AppendTo[pointRows, pointResult[[1]]];
        AppendTo[pointRightHandSides, pointResult[[2]]]]]];
  If[Length[acceptedPoints] < requestedPointCount,
    Message[SampleEpsFormStripAffine::points]; Return[$Failed]];
  matrix = Join @@ pointRows;
  rightHandSide = Join @@ pointRightHandSides;
  eliminationPlan = OptionValue["EliminationPlan"];
  discoverPlanQ = TrueQ[OptionValue["DiscoverPlan"]];
  planValidation = finiteFieldStripValidateEliminationPlan[
    eliminationPlan, Dimensions[matrix], gaugeUnknownCount,
    Length[freeResidues], numeratorDegrees, denominatorDegrees, support,
    preparation["Fingerprint"]];
  planCompatible = solveAffineQ &&
    Lookup[planValidation, "Status", None] === "OK";
  discard = None;
  If[planCompatible,
    (* M1 constrained path: one factorization, nullity+1 right-hand
       sides, then every original row checked *)
    rank = eliminationPlan["GenericRank"];
    augmentedRank = rank;
    rankSeconds = 0.; augmentedRankSeconds = 0.;
    If[eliminationPlan["Nullity"] === 0,
      core = matrix[[eliminationPlan["IndependentEquationRows"]]];
      rhsMatrix = List /@ rightHandSide[[
        eliminationPlan["IndependentEquationRows"]]],
      selector = SparseArray[
        MapIndexed[{First[#2], #1} -> 1 &,
          eliminationPlan["NormalizationColumns"]],
        {eliminationPlan["Nullity"], eliminationPlan["UnknownCount"]}];
      core = Join[matrix[[eliminationPlan["IndependentEquationRows"]]],
        selector];
      rhsMatrix = Join[
        Join[List /@ rightHandSide[[
            eliminationPlan["IndependentEquationRows"]]],
          ConstantArray[0, {rank, eliminationPlan["Nullity"]}], 2],
        Join[ConstantArray[0, {eliminationPlan["Nullity"], 1}],
          IdentityMatrix[eliminationPlan["Nullity"]], 2]]];
    (* A4 (Codex round 2, standardized 2026-08-21): the square core with
       all right-hand sides goes to FLINT's nmod_mat_solve through a
       process adapter when the backend is available and the core is
       large enough to pay for the transfer; the all-row residual checks
       below verify the imported solution exactly like the Wolfram one,
       and any adapter failure falls back to LinearSolve *)
    backendDecision = finiteFieldStripBackendDecision[
      backendRequested, backendThreads, Length[core]];
    {constrainedSeconds, solutionMatrix} = AbsoluteTiming[
      Module[{flint = $Failed},
        Which[
          Lookup[backendDecision, "Status", None] =!= "OK",
            backendFailure = backendDecision["Status"]; $Failed,
          backendDecision["UseBackend"] === "FLINT",
            flint = finiteFieldStripFLINTSolve[core, rhsMatrix, prime,
              backendThreads];
            If[finiteFieldStripCoreSolutionQ[
                core, rhsMatrix, flint, prime],
              backendUsed = "FLINT"; flint,
              backendFailure = If[flint === $Failed,
                "FLINTExecutionFailed", "FLINTCoreCertificateFailed"];
              If[TrueQ[backendDecision["FallbackAllowed"]],
                backendFallbackReason = backendFailure;
                backendFailure = None; backendUsed = "Wolfram";
                Quiet[Check[LinearSolve[core, rhsMatrix,
                  Modulus -> prime], $Failed]],
                $Failed]],
          True,
            backendUsed = "Wolfram";
            Quiet[Check[LinearSolve[core, rhsMatrix,
              Modulus -> prime], $Failed]]]]];
    If[StringQ[backendFailure],
      discard = "DiscardBackendFailure",
    If[solutionMatrix === $Failed || ! MatrixQ[solutionMatrix, IntegerQ] ||
        Dimensions[solutionMatrix] =!=
          {eliminationPlan["UnknownCount"], eliminationPlan["Nullity"] + 1},
      discard = "DiscardRankLosingSample",
      particularSolution = solutionMatrix[[All, 1]];
      nullspaceBasis = If[eliminationPlan["Nullity"] === 0, {},
        Transpose[solutionMatrix[[All, 2 ;;]]]];
      normalizationOK =
        particularSolution[[eliminationPlan["NormalizationColumns"]]] ===
          ConstantArray[0, eliminationPlan["Nullity"]] &&
        (eliminationPlan["Nullity"] === 0 ||
          nullspaceBasis[[All, eliminationPlan["NormalizationColumns"]]] ===
            IdentityMatrix[eliminationPlan["Nullity"]]);
      affineData = <|
        "LinearSolveSeconds" -> constrainedSeconds,
        "NullspaceSeconds" -> 0.,
        "ConstrainedSolveSeconds" -> constrainedSeconds,
        "ParticularSolution" -> particularSolution,
        "NullspaceBasis" -> nullspaceBasis,
        "ParticularCheckZero" ->
          AllTrue[Mod[matrix.particularSolution - rightHandSide, prime],
            # === 0 &],
        "NullspaceCheckZero" -> AllTrue[
          If[nullspaceBasis === {}, {},
            Flatten[Mod[matrix.Transpose[nullspaceBasis], prime]]],
          # === 0 &],
        "NormalizationCheck" -> normalizationOK,
        "SolvePath" -> "OneConstrainedMultiRHSFactorization",
        "Backend" -> backendUsed, "BackendRequested" -> backendRequested,
        "BackendUsed" -> backendUsed,
        "BackendFallbackReason" -> backendFallbackReason,
        "BackendFailure" -> backendFailure|>;
      If[! TrueQ[affineData["ParticularCheckZero"] &&
          affineData["NullspaceCheckZero"] && normalizationOK],
        discard = "DiscardFailedResidualCheck"]]];
    If[StringQ[discard],
      (* a discarded sample carries no solution and never reaches the
         interpolation (filtered by its non-generic rank fields) *)
      rank = -1; augmentedRank = -2;
      affineData = <|"Status" -> discard, "SolvePath" ->
        "OneConstrainedMultiRHSFactorization",
        "ConstrainedSolveSeconds" -> constrainedSeconds,
        "Backend" -> backendUsed, "BackendRequested" -> backendRequested,
        "BackendUsed" -> backendUsed,
        "BackendFallbackReason" -> backendFallbackReason,
        "BackendFailure" -> backendFailure|>],
    If[backendRequested === "FLINT" && ! discoverPlanQ,
      rank = -1; augmentedRank = -2;
      backendFailure = "FLINTRequiresValidatedEliminationPlan";
      affineData = <|"Status" -> "DiscardBackendFailure",
        "SolvePath" -> "NoValidatedEliminationPlan",
        "Backend" -> None, "BackendRequested" -> backendRequested,
        "BackendUsed" -> None, "BackendFallbackReason" -> None,
        "BackendFailure" -> backendFailure|>,
    backendUsed = "Wolfram";
    augmented = Join[
      matrix, SparseArray[List /@ rightHandSide], 2];
    {rankSeconds, rank} = AbsoluteTiming[
      MatrixRank[matrix, Modulus -> prime]];
    {augmentedRankSeconds, augmentedRank} = AbsoluteTiming[
      MatrixRank[augmented, Modulus -> prime]]]];
  If[! planCompatible && solveAffineQ && TrueQ[rank === augmentedRank],
    {linearSolveSeconds, particularSolution} = AbsoluteTiming[
      LinearSolve[matrix, rightHandSide, Modulus -> prime]];
    {nullspaceSeconds, nullspaceBasis} = AbsoluteTiming[
      NullSpace[matrix, Modulus -> prime]];
    affineData = <|
      "LinearSolveSeconds" -> linearSolveSeconds,
      "NullspaceSeconds" -> nullspaceSeconds,
      "ParticularSolution" -> particularSolution,
      "NullspaceBasis" -> nullspaceBasis,
      "ParticularCheckZero" ->
        AllTrue[Mod[matrix.particularSolution - rightHandSide, prime],
          # === 0 &],
      "NullspaceCheckZero" -> AllTrue[
        If[nullspaceBasis === {}, {},
          Flatten[Mod[matrix.Transpose[nullspaceBasis], prime]]],
        # === 0 &],
      "SolvePath" -> "PilotFourEliminations", "Backend" -> "Wolfram",
      "BackendRequested" -> backendRequested,
      "BackendUsed" -> "Wolfram", "BackendFallbackReason" -> None,
      "BackendFailure" -> None,
      "PlanDiscoveryBackendRequested" -> planDiscoveryBackend,
      "PlanDiscoveryBackendUsed" -> "Wolfram"
    |>;
    If[discoverPlanQ,
      (* the plan-discovery backend replaces exactly this step and
         nothing downstream; the Wolfram rank computed just above is
         handed to the native path as a free cross-check of the adapter's
         rank (Design/CFFR1Backend.md) *)
      If[planDiscoveryBackend === "FLINTAffineRREF",
        planDiscoveryBackendUsed = "FLINTAffineRREF";
        {planSeconds, planResult} = AbsoluteTiming[
          finiteFieldStripCFFRDiscoverPlan[matrix, rightHandSide,
            gaugeUnknownCount, Length[freeResidues], numeratorDegrees,
            denominatorDegrees, prime, backendThreads,
            OptionValue["ArtifactDirectory"], rank]];
        If[AssociationQ[planResult] && planResult["Status"] === "OK",
          planResult = finiteFieldStripSealEliminationPlan[
            Join[KeyDrop[planResult,
                {"Binding", "PivotColumns", "FreeColumns"}],
              <|"GaugeSupport" -> support|>],
            preparation["Fingerprint"], planDiscoveryBackend,
            planResult["Binding"]]],
        planDiscoveryBackendUsed = "Wolfram";
        {planSeconds, planResult} = AbsoluteTiming[finiteFieldStripDiscoverPlan[matrix, rank,
          nullspaceBasis, gaugeUnknownCount, Length[freeResidues],
          numeratorDegrees, denominatorDegrees, prime]];
        If[AssociationQ[planResult] && planResult["Status"] === "OK",
          planResult = finiteFieldStripSealEliminationPlan[
            Join[planResult, <|"GaugeSupport" -> support|>],
            preparation["Fingerprint"], planDiscoveryBackend]]];
      affineData = Join[affineData, <|"EliminationPlan" -> planResult,
        "PlanDiscoverySeconds" -> planSeconds,
        "PlanDiscoveryBackendUsed" -> planDiscoveryBackendUsed|>]]];
  Join[<|
    "EpsilonValue" -> epsilonValue,
    "Prime" -> prime,
    "AcceptedPoints" -> acceptedPoints,
    "AttemptCount" -> attemptCount,
    "MatrixDimensions" -> Dimensions[matrix],
    "GaugeDimensions" -> dimensions,
    "Alphabet" -> alphabet,
    "GaugeDenominator" -> gaugeDenominator,
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "GaugeSupport" -> support,
    "GaugeSupportCount" -> Length[support],
    "SupportMaximumDegrees" -> {Max[support[[All, 1]]], Max[support[[All, 2]]]},
    "TableExponents" -> tableExponents,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "FreeResidueCount" -> Length[freeResidues],
    "NonzeroEntries" -> Length[matrix["NonzeroValues"]],
    "Rank" -> rank,
    "AugmentedRank" -> augmentedRank,
    "Nullity" -> unknownCount - rank,
    "Consistent" -> TrueQ[rank === augmentedRank],
    "SetupSeconds" -> setupSeconds,
    "PreparationReused" -> preparationReused,
    "PreprocessingSeconds" -> preprocessingSeconds,
    "SamplingSeconds" -> samplingSeconds,
    "PeakMemoryBytes" -> MaxMemoryUsed[],
    "RankSeconds" -> rankSeconds,
    "AugmentedRankSeconds" -> augmentedRankSeconds,
    "PlanValidationStatus" -> planValidation,
    "BackendRequested" -> backendRequested,
    "BackendUsed" -> backendUsed,
    "BackendFallbackReason" -> backendFallbackReason,
    "BackendFailure" -> backendFailure,
    "PlanDiscoveryBackendRequested" -> planDiscoveryBackend,
    "PlanDiscoveryBackendUsed" -> planDiscoveryBackendUsed
  |>, affineData]
];

finiteFieldStripIndependentColumns[matrix_List, modulus_Integer] := Module[
  {columns = {}, rank = 0, trialRank},
  Do[
    trialRank = MatrixRank[matrix[[All, Append[columns, column]]],
      Modulus -> modulus];
    If[trialRank > rank,
      AppendTo[columns, column]; rank = trialRank];
    If[rank === Length[matrix], Break[]],
    {column, Length[First[matrix]]}];
  columns
];

finiteFieldStripEvaluateCoefficients[coefficients_List, value_Integer,
    prime_Integer] := Fold[Mod[#1 value + #2, prime] &, 0,
  Reverse[coefficients]];

finiteFieldStripTrimCoefficients[coefficients_List] := Module[
  {nonzeroIndices = Select[Range[Length[coefficients]],
      coefficients[[#]] =!= 0 &]},
  If[nonzeroIndices === {}, {0}, Take[coefficients, Last[nonzeroIndices]]]
];

finiteFieldStripReduceRationalPair[numeratorInput_List,
    denominatorInput_List, prime_Integer] := Module[
  {z, numerator, denominator, divisor, normalization,
   numeratorCoefficients, denominatorCoefficients},
  numerator = FromDigits[Reverse[numeratorInput], z];
  denominator = FromDigits[Reverse[denominatorInput], z];
  divisor = PolynomialGCD[numerator, denominator, Modulus -> prime];
  numerator = PolynomialQuotient[numerator, divisor, z,
    Modulus -> prime];
  denominator = PolynomialQuotient[denominator, divisor, z,
    Modulus -> prime];
  numeratorCoefficients = finiteFieldStripTrimCoefficients[
    Mod[CoefficientList[numerator, z], prime]];
  denominatorCoefficients = finiteFieldStripTrimCoefficients[
    Mod[CoefficientList[denominator, z], prime]];
  normalization = PowerMod[Last[denominatorCoefficients], -1, prime];
  {Mod[normalization numeratorCoefficients, prime],
    Mod[normalization denominatorCoefficients, prime]}
];

finiteFieldStripInterpolationQ[pair_List, data_List,
    prime_Integer] := AllTrue[data, Function[datum,
  Module[{numerator, denominator},
    numerator = finiteFieldStripEvaluateCoefficients[
      pair[[1]], datum[[1]], prime];
    denominator = finiteFieldStripEvaluateCoefficients[
      pair[[2]], datum[[1]], prime];
    denominator =!= 0 &&
      Mod[numerator - datum[[2]] denominator, prime] === 0]]];

finiteFieldStripInterpolateCoordinate[data_List, prime_Integer,
    constructionCount_Integer, maximumTotalDegree_Integer] :=
 Catch[Module[
  {construction, validation, totalDegree, numeratorDegree,
   denominatorDegree, matrix, nullspace, vector, pair,
   candidateDegrees, uniquenessPointRequirement},
  If[AllTrue[data, Last[#] === 0 &],
    Throw[<|"Numerator" -> {0}, "Denominator" -> {1},
      "Degrees" -> {-Infinity, 0}, "ConstructionNullity" -> 1,
      "ValidatedPointCount" -> Length[data],
      "UniquenessPointRequirement" -> 1|>, "Found"]];
  construction = Take[data, constructionCount];
  validation = Drop[data, constructionCount];
  Do[
    denominatorDegree = totalDegree - numeratorDegree;
    matrix = Table[Join[
      Table[PowerMod[datum[[1]], power, prime],
        {power, 0, numeratorDegree}],
      Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime],
        prime], {power, 0, denominatorDegree}]],
      {datum, construction}];
    nullspace = NullSpace[matrix, Modulus -> prime];
    If[Length[nullspace] === 1,
      vector = First[nullspace];
      If[AnyTrue[vector[[numeratorDegree + 2 ;;]], # =!= 0 &],
        pair = finiteFieldStripReduceRationalPair[
          vector[[1 ;; numeratorDegree + 1]],
          vector[[numeratorDegree + 2 ;;]], prime];
        candidateDegrees = Length[#] - 1 & /@ pair;
        uniquenessPointRequirement = 2 Total[candidateDegrees] + 1;
        If[Length[data] >= uniquenessPointRequirement &&
            finiteFieldStripInterpolationQ[pair, construction, prime] &&
            finiteFieldStripInterpolationQ[pair, validation, prime],
          Throw[<|"Numerator" -> pair[[1]],
            "Denominator" -> pair[[2]],
            "Degrees" -> candidateDegrees,
            "ConstructionNullity" -> 1,
            "ValidatedPointCount" -> Length[data],
            "UniquenessPointRequirement" ->
              uniquenessPointRequirement|>, "Found"]]]],
    {totalDegree, 0, maximumTotalDegree},
    {numeratorDegree, 0, totalDegree}];
  $Failed
], "Found"];

finiteFieldStripAdaptiveSamplingPlan[interpolation_Association,
    availableSampleCount_Integer, validationMargin_Integer] := Module[
  {degrees, maximumDegreeSum, constructionCount, sampleCount},
  degrees = Cases[
    Lookup[Lookup[interpolation, "Interpolations", {}],
      "Degrees", Missing["Degrees"]],
    {numerator_Integer, denominator_Integer} /;
      numerator >= 0 && denominator >= 0];
  maximumDegreeSum = If[degrees === {}, 0, Max[Total /@ degrees]];
  constructionCount = maximumDegreeSum + 1;
  sampleCount = Min[availableSampleCount, Max[
    2 maximumDegreeSum + 1,
    constructionCount + validationMargin]];
  <|
    "MaximumTotalDegree" -> maximumDegreeSum,
    "ConstructionCount" -> constructionCount,
    "SampleCount" -> sampleCount
  |>
];

(* shared by both interpolation modes: validate a sample set, keep the
   generic-rank samples, fix the normalization columns, and normalize
   every sample to its canonical particular solution *)
finiteFieldStripCanonicalSamples[samples_List, prime_Integer,
    normalizationColumnsInput_] := Module[
  {normalizationColumns = normalizationColumnsInput, genericRank,
   genericSamples, referenceSample, referenceNullspace, gaugeUnknownCount,
   freeResidueCount, residueColumns, epsilonMod, normalized, grouped},
  If[! PrimeQ[prime] || samples === {} ||
      ! AllTrue[samples, AssociationQ] ||
      AnyTrue[samples,
        Lookup[#, "Prime", Missing[]] =!= prime ||
          ! TrueQ[Lookup[#, "Consistent", False]] ||
          ! TrueQ[Lookup[#, "ParticularCheckZero", False]] ||
          ! TrueQ[Lookup[#, "NullspaceCheckZero", False]] &] ||
      Length[DeleteDuplicates[Lookup[samples, "GaugeUnknownCount"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[samples, "FreeResidueCount"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[samples, "GaugeNumeratorDegrees"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[samples, "GaugeSupport", Missing["GaugeSupport"]]]] =!= 1,
    Return[<|"Status" -> "SamplesInvalid"|>]];
  genericRank = Max[Lookup[samples, "Rank"]];
  genericSamples = Select[samples,
    Lookup[#, "Rank", -1] === genericRank &&
      Lookup[#, "AugmentedRank", -2] === genericRank &];
  referenceSample = First[genericSamples];
  referenceNullspace = Normal[referenceSample["NullspaceBasis"]];
  gaugeUnknownCount = referenceSample["GaugeUnknownCount"];
  freeResidueCount = referenceSample["FreeResidueCount"];
  residueColumns = gaugeUnknownCount + Range[freeResidueCount];
  If[normalizationColumns === Automatic,
    normalizationColumns = finiteFieldStripNormalizationColumns[
      referenceNullspace, gaugeUnknownCount, freeResidueCount, prime]];
  If[Length[normalizationColumns] =!= Length[referenceNullspace],
    Return[<|"Status" -> "NormalizationInvalid"|>]];
  epsilonMod[value_] := Mod[Numerator[value] PowerMod[
    Mod[Denominator[value], prime], -1, prime], prime];
  normalized = Table[
    With[{sample = sample,
      canonical = NormalizeEpsFormAffineSample[sample, normalizationColumns, prime]},
      If[canonical === $Failed, $Failed,
        <|"EpsilonValue" -> sample["EpsilonValue"],
          "EpsilonMod" -> epsilonMod[sample["EpsilonValue"]],
          "Values" -> canonical["ParticularSolution"]|>]],
    {sample, genericSamples}];
  If[MemberQ[normalized, $Failed], Return[<|"Status" -> "NormalizationInvalid"|>]];
  grouped = GatherBy[normalized, #EpsilonMod &];
  If[AnyTrue[grouped, Length[DeleteDuplicates[Lookup[#, "Values"]]] =!= 1 &],
    Return[<|"Status" -> "SamplesInvalid"|>]];
  <|"Status" -> "OK",
    "CanonicalSamples" -> (First /@ grouped),
    "NormalizationColumns" -> normalizationColumns,
    "GenericRank" -> genericRank,
    "DiscardedSingularEpsilonValues" -> Lookup[
      Complement[samples, genericSamples, SameTest -> SameQ], "EpsilonValue"],
    "ReferenceSample" -> KeyTake[referenceSample,
      {"GaugeUnknownCount", "FreeResidueCount", "GaugeNumeratorDegrees", "GaugeSupport"}]|>
];

(* A2 (Codex round 2, standardized 2026-08-21): rational interpolation of
   every coordinate from a small construction prefix, certified by fresh
   held-out regulator images instead of the deterministic 2(m+n)+1
   point count.  All minimal-total-degree Pade splits that fit the
   construction data are retained (four points cannot separate 0/3 from
   3/0); held-outs reject the wrong ones; a failed held-out is promoted
   into the construction data and only the failed coordinates are refit;
   a prime whose degree profile differs from the expected one is
   rejected.  The result carries "CertificationMode" -> "HeldOut" and the
   deterministic requirement as metadata; the terminal certificates are
   the unseen-prime residual and the exact Pfaffian check. *)
finiteFieldStripFitSplit[data_List, prime_Integer, numeratorDegree_Integer,
    denominatorDegree_Integer] := Module[{matrix, nullspace, vector, pair},
  matrix = Table[Join[
      Table[PowerMod[datum[[1]], power, prime], {power, 0, numeratorDegree}],
      Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime], prime],
        {power, 0, denominatorDegree}]],
    {datum, data}];
  nullspace = NullSpace[matrix, Modulus -> prime];
  If[Length[nullspace] =!= 1, Return[$Failed]];
  vector = First[nullspace];
  If[! AnyTrue[vector[[numeratorDegree + 2 ;;]], # =!= 0 &], Return[$Failed]];
  pair = finiteFieldStripReduceRationalPair[vector[[1 ;; numeratorDegree + 1]],
    vector[[numeratorDegree + 2 ;;]], prime];
  If[! finiteFieldStripInterpolationQ[pair, data, prime], Return[$Failed]];
  <|"Numerator" -> pair[[1]], "Denominator" -> pair[[2]],
    "Degrees" -> (Length[#] - 1 & /@ pair), "ConstructionNullity" -> 1|>
];

finiteFieldStripFitCandidates[data_List, prime_Integer, maximumTotalDegree_Integer] :=
 Module[{candidates = {}},
  If[AllTrue[data, Last[#] === 0 &],
    Return[{<|"Numerator" -> {0}, "Denominator" -> {1}, "Degrees" -> {-Infinity, 0},
      "ConstructionNullity" -> 1|>}]];
  Do[
    candidates = DeleteDuplicatesBy[DeleteCases[
      Table[finiteFieldStripFitSplit[data, prime, d, total - d], {d, 0, total}], $Failed],
      Lookup[#, {"Numerator", "Denominator"}] &];
    If[candidates =!= {}, Break[]],
    {total, 0, Min[maximumTotalDegree, Length[data] - 1]}];
  candidates
];

Options[finiteFieldStripHeldOutInterpolate] = {
  "InitialConstructionCount" -> 4,
  "HeldOutCount" -> 3,
  "MaximumTotalDegree" -> 22,
  "ExpectedDegrees" -> Automatic
};

finiteFieldStripHeldOutInterpolate[canonicalSamples_List, prime_Integer,
    OptionsPattern[]] := Module[
  {initial, heldOut, maximumTotalDegree, expected, coordinateCount,
   construction, consumed, candidateSets, active, unresolved, validation,
   survivors, failures, ambiguous, seconds = 0., fit, data, mismatches,
   interpolations, exit},
  initial = OptionValue["InitialConstructionCount"];
  heldOut = OptionValue["HeldOutCount"];
  maximumTotalDegree = OptionValue["MaximumTotalDegree"];
  expected = OptionValue["ExpectedDegrees"];
  coordinateCount = Length[First[canonicalSamples]["Values"]];
  If[Length[canonicalSamples] < initial + heldOut,
    Return[<|"Status" -> "MoreSamplesRequired",
      "RequiredAdditionalSampleCount" -> initial + heldOut - Length[canonicalSamples]|>]];
  data[coordinate_, indices_] := Table[
    {canonicalSamples[[index, "EpsilonMod"]], canonicalSamples[[index, "Values", coordinate]]},
    {index, indices}];
  construction = Range[initial]; consumed = initial;
  candidateSets = ConstantArray[$Failed, coordinateCount];
  exit = Catch[While[True,
    (* keep the candidates that still predict all construction data *)
    Do[If[ListQ[candidateSets[[c]]],
      candidateSets[[c]] = Select[candidateSets[[c]],
        finiteFieldStripInterpolationQ[{#Numerator, #Denominator}, data[c, construction], prime] &];
      If[candidateSets[[c]] === {}, candidateSets[[c]] = $Failed]],
      {c, coordinateCount}];
    active = Select[Range[coordinateCount], candidateSets[[#]] === $Failed &];
    seconds += First[AbsoluteTiming[
      Do[fit = finiteFieldStripFitCandidates[data[c, construction], prime, maximumTotalDegree];
        candidateSets[[c]] = If[fit === {}, $Failed, fit], {c, active}]]];
    unresolved = Select[Range[coordinateCount], candidateSets[[#]] === $Failed &];
    If[unresolved =!= {},
      If[consumed >= Length[canonicalSamples],
        Throw[<|"Status" -> "MoreSamplesRequired", "RequiredAdditionalSampleCount" -> 1,
          "Reason" -> "GrowRequired"|>, "heldOut"]];
      consumed++; AppendTo[construction, consumed]; Continue[]];
    If[consumed + heldOut > Length[canonicalSamples],
      Throw[<|"Status" -> "MoreSamplesRequired",
        "RequiredAdditionalSampleCount" -> consumed + heldOut - Length[canonicalSamples],
        "Reason" -> "HeldOutRound"|>, "heldOut"]];
    validation = Range[consumed + 1, consumed + heldOut];
    survivors = Table[Select[candidateSets[[c]],
      finiteFieldStripInterpolationQ[{#Numerator, #Denominator}, data[c, validation], prime] &],
      {c, coordinateCount}];
    failures = Select[Range[coordinateCount], survivors[[#]] === {} &];
    ambiguous = Select[Range[coordinateCount], Length[survivors[[#]]] > 1 &];
    consumed += heldOut;
    candidateSets = survivors;
    If[failures === {} && ambiguous === {}, Break[]];
    If[failures === {}, Continue[]];
    (* grow, never accept: failed held-outs become construction data *)
    construction = Join[construction, validation];
    candidateSets[[failures]] = ConstantArray[$Failed, Length[failures]]],
    "heldOut"];
  If[AssociationQ[exit], Return[exit]];
  interpolations = First /@ candidateSets;
  If[ListQ[expected] && Length[expected] === coordinateCount,
    mismatches = Select[Range[coordinateCount], interpolations[[#]]["Degrees"] =!= expected[[#]] &];
    If[mismatches =!= {},
      Return[<|"Status" -> "RejectPrimeDegreeProfileChanged",
        "DegreeMismatchCoordinates" -> mismatches|>]]];
  interpolations = Join[#, <|"ValidatedPointCount" -> consumed,
    "UniquenessPointRequirement" -> If[#["Degrees"][[1]] === -Infinity, 1, 2 Total[#["Degrees"]] + 1]|>] & /@
    interpolations;
  <|"Status" -> "HeldOutValidated",
    "Prime" -> prime,
    "SampleCount" -> consumed,
    "ConstructionCount" -> Length[construction],
    "ValidationCount" -> heldOut,
    "MaximumTotalDegree" -> maximumTotalDegree,
    "InterpolationSeconds" -> seconds,
    "UnresolvedCoordinates" -> {},
    "CertificationMode" -> "HeldOut",
    "DeterministicShortfallCoordinates" -> Select[Range[coordinateCount],
      consumed < interpolations[[#]]["UniquenessPointRequirement"] &],
    "DegreeHistogram" -> Counts[Lookup[interpolations, "Degrees"]],
    "Interpolations" -> interpolations|>
];

Options[InterpolateEpsFormStripAffine] = {
  "ConstructionCount" -> 24,
  "MaximumTotalDegree" -> 22,
  "NormalizationColumns" -> Automatic
};

InterpolateEpsFormStripAffine[samples_List, prime_Integer,
    OptionsPattern[]] := Module[
  {constructionCount, maximumTotalDegree, normalizationColumns,
   genericRank, discardedSingularEpsilonValues, genericSamples,
   referenceSample, referenceNullspace, gaugeUnknownCount,
   freeResidueCount, gaugeNumeratorDegrees, residueColumns,
   epsilonMod, normalized, canonicalSamples, grouped,
   coordinateCount, interpolations, seconds, unresolved},
  constructionCount = OptionValue["ConstructionCount"];
  maximumTotalDegree = OptionValue["MaximumTotalDegree"];
  normalizationColumns = OptionValue["NormalizationColumns"];
  If[! PrimeQ[prime] || samples === {} ||
      ! AllTrue[samples, AssociationQ] ||
      AnyTrue[samples,
        Lookup[#, "Prime", Missing[]] =!= prime ||
          ! TrueQ[Lookup[#, "Consistent", False]] ||
          ! TrueQ[Lookup[#, "ParticularCheckZero", False]] ||
          ! TrueQ[Lookup[#, "NullspaceCheckZero", False]] &] ||
      Length[DeleteDuplicates[Lookup[samples,
        "GaugeUnknownCount"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[samples,
        "FreeResidueCount"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[samples,
        "GaugeNumeratorDegrees"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[samples,
        "GaugeSupport", Missing["GaugeSupport"]]]] =!= 1 ||
      ! IntegerQ[constructionCount] || constructionCount <= 0 ||
      ! IntegerQ[maximumTotalDegree] || maximumTotalDegree < 0,
    Message[InterpolateEpsFormStripAffine::samples]; Return[$Failed]];
  genericRank = Max[Lookup[samples, "Rank"]];
  genericSamples = Select[samples,
    Lookup[#, "Rank", -1] === genericRank &&
      Lookup[#, "AugmentedRank", -2] === genericRank &];
  discardedSingularEpsilonValues = Lookup[
    Complement[samples, genericSamples, SameTest -> SameQ],
    "EpsilonValue"];
  If[Length[genericSamples] < constructionCount + 4,
    Message[InterpolateEpsFormStripAffine::count]; Return[$Failed]];
  referenceSample = First[genericSamples];
  referenceNullspace = Normal[referenceSample["NullspaceBasis"]];
  gaugeUnknownCount = referenceSample["GaugeUnknownCount"];
  freeResidueCount = referenceSample["FreeResidueCount"];
  gaugeNumeratorDegrees = referenceSample["GaugeNumeratorDegrees"];
  residueColumns = gaugeUnknownCount + Range[freeResidueCount];
  If[normalizationColumns === Automatic,
    normalizationColumns = finiteFieldStripNormalizationColumns[
      referenceNullspace, gaugeUnknownCount, freeResidueCount, prime]];
  If[Length[normalizationColumns] =!= Length[referenceNullspace],
    Message[InterpolateEpsFormStripAffine::normalization];
    Return[$Failed]];
  epsilonMod[value_] := Mod[
    Numerator[value] PowerMod[
      Mod[Denominator[value], prime], -1, prime], prime];
  normalized = Table[
    With[{sample = sample,
      canonical = NormalizeEpsFormAffineSample[
        sample, normalizationColumns, prime]},
      If[canonical === $Failed, $Failed,
        <|"EpsilonValue" -> sample["EpsilonValue"],
          "EpsilonMod" -> epsilonMod[sample["EpsilonValue"]],
          "Values" -> canonical["ParticularSolution"]|>]],
    {sample, genericSamples}];
  If[MemberQ[normalized, $Failed],
    Message[InterpolateEpsFormStripAffine::normalization];
    Return[$Failed]];
  grouped = GatherBy[normalized, #EpsilonMod &];
  If[AnyTrue[grouped,
      Length[DeleteDuplicates[Lookup[#, "Values"]]] =!= 1 &],
    Message[InterpolateEpsFormStripAffine::samples]; Return[$Failed]];
  canonicalSamples = First /@ grouped;
  If[Length[canonicalSamples] < constructionCount + 4,
    Message[InterpolateEpsFormStripAffine::count]; Return[$Failed]];
  coordinateCount = Length[First[canonicalSamples]["Values"]];
  {seconds, interpolations} = AbsoluteTiming[Table[
    finiteFieldStripInterpolateCoordinate[
      ({#EpsilonMod, #Values[[coordinate]]} &) /@ canonicalSamples,
      prime, constructionCount, maximumTotalDegree],
    {coordinate, coordinateCount}]];
  unresolved = Flatten[Position[interpolations, $Failed]];
  <|
    "Prime" -> prime,
    "SampleCount" -> Length[canonicalSamples],
    "ConstructionCount" -> constructionCount,
    "ValidationCount" -> Length[canonicalSamples] - constructionCount,
    "MaximumTotalDegree" -> maximumTotalDegree,
    "GenericRank" -> genericRank,
    "DiscardedSingularEpsilonValues" ->
      discardedSingularEpsilonValues,
    "NormalizationColumns" -> normalizationColumns,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "FreeResidueCount" -> freeResidueCount,
    "GaugeNumeratorDegrees" -> gaugeNumeratorDegrees,
    "GaugeSupport" -> Lookup[referenceSample, "GaugeSupport", Missing["GaugeSupport"]],
    "InterpolationSeconds" -> seconds,
    "UnresolvedCoordinates" -> unresolved,
    "DegreeHistogram" -> Counts[
      Cases[interpolations, a_Association :> a["Degrees"]]],
    "Interpolations" -> interpolations
  |>
];

finiteFieldStripPutAtomic[expression_, file_String] := Module[
  {temporary = file <> ".tmp"},
  Put[expression, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

finiteFieldStripArtifactTag[value_] := StringReplace[
  ToString[value, InputForm],
  {"/" -> "_", "-" -> "m", " " -> ""}];

(* A2 certificate: the lifted solution vector (gauge numerator
   coefficients over the support, then residues), reduced at a regulator
   value modulo a prime ABSENT from the lift, must equal the normalized
   particular solution of a fresh constrained sample at that prime. *)
finiteFieldStripUnseenPrimeResidualQ[record_Association, lifted_Association,
    preparation_Association, prime_Integer, epsilonValue_, sampleOptions_List] :=
 Module[{sample, canonical, vector, modNumber, epsilon},
  epsilon = record["Regulator"];
  $finiteFieldLastUnseenSample = <||>;
  (* the residual is taken on the lift's own numerator support (recorded
     in the modular data), not on whatever support the current options
     would select: a lift from an older support shape stays verifiable
     (2026-08-22, the certified support became the total-degree simplex) *)
  sample = SampleEpsFormStripAffine[record, epsilonValue, prime,
    Sequence @@ If[MatchQ[Lookup[lifted, "GaugeSupport", None], {{_Integer, _Integer} ..}],
      Join[{"Support" -> lifted["GaugeSupport"]}, DeleteCases[sampleOptions, "Support" -> _]],
      sampleOptions]];
  If[! AssociationQ[sample], $finiteFieldLastUnseenSample = <|"PointFailure" -> True|>; Return[False]];
  If[! TrueQ[sample["Consistent"]], Return[False]];
  canonical = NormalizeEpsFormAffineSample[sample, lifted["NormalizationColumns"], prime];
  If[canonical === $Failed, Return[False]];
  modNumber[value_] := Module[{d = Mod[Denominator[value], prime]},
    If[d === 0, Throw[False, "unseen"],
      Mod[Mod[Numerator[value], prime] PowerMod[d, -1, prime], prime]]];
  Catch[
    vector = modNumber[Together[# /. epsilon -> epsilonValue]] & /@ lifted["LiftedVector"];
    Length[vector] === Length[canonical["ParticularSolution"]] &&
      vector === canonical["ParticularSolution"],
    "unseen"]
];

(* primes absent from the lift schedule, walking down from 2147483399
   without a fixed window: the schedule is finite, so count such primes
   always exist *)
finiteFieldStripReservePrimes[primes_List, count_Integer: 3] /; count >= 1 :=
 Module[{candidate = 2147483399, reserve = {}},
  While[Length[reserve] < count,
    If[! MemberQ[primes, candidate], AppendTo[reserve, candidate]];
    candidate = NextPrime[candidate, -1]];
  reserve
];

SolveEpsFormStripFiniteField::dlog =
  "The lift passed the unseen-prime residual but is not a dlog form (`1`); more primes cannot change that.";

Options[SolveEpsFormStripFiniteField] = {
  "Primes" -> {1000003, 2147483423, 2147483477, 2147483489,
    2147483497, 2147483543, 2147483549, 2147483563,
    2147483587, 2147483629, 2147483647},
  "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[32]),
  "NumeratorDegreeOffsets" ->
    {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {2, 0}, {0, 2},
      {2, 1}, {1, 2}, {2, 2}},
  "PointCount" -> Automatic,
  "KernelCount" -> Automatic,
  "ConstructionCount" -> 24,
  "MaximumTotalDegree" -> 22,
  "ArtifactDirectory" -> Automatic,
  "ArtifactPrefix" -> "finite_field_strip",
  "MinimumPrimeCount" -> 3,
  "AdaptivePrimeSampling" -> True,
  "AdaptiveValidationMargin" -> 8,
  "Elimination" -> "Constrained",
  "Support" -> Automatic,
  (* "SimplexFirst": every probe uses the certified total-degree simplex
     (shell 0) before the bidegree rectangle; "SparseFirst": the former
     rectangle-cut supports over the offset ladder, the full simplex
     once as the terminal probe (Codex proposal 2026-08-22) *)
  "SupportStrategy" -> "SimplexFirst",
  (* after the pilot on the certified simplex, keep only the monomials
     whose normalized coefficient is nonzero at the pilot (prime, eps)
     and re-pilot on that support: the simplex guarantees existence, the
     held-out / unseen-prime checks guard the shrink (2026-08-22
     benchmark: the simplex costs +50% per prime on the (8,7) class
     against the 85-monomial rectangle; the true support is smaller) *)
  "SupportLearning" -> True,
  "RegulatorSampling" -> "HeldOut",
  "Backend" -> Automatic,
  "BackendThreads" -> 2,
  "PlanDiscoveryBackend" -> "Wolfram",
  "InitialConstructionCount" -> 4,
  "HeldOutCount" -> 3,
  "UnseenPrimeCheck" -> True,
  (* the configured primes are extended with reserve primes up to this
     count while the lift fails only because the combined modulus is too
     small for the coefficient heights (2026-08-22, CF231/CF305 block
     (8,7): coefficients above 51 digits, 11 primes of 31 bits could not
     reconstruct them; nothing else was wrong with the ansatz) *)
  "MaximumPrimeCount" -> 40,
  (* inside a KernelPool mission, farm the sample batches to the pool's
     free subkernels when the pilot measured at least this many seconds
     of build per sample (measured 2026-08-22 on CF254: (9,7) at 2.6 s per
     sample gains 1.5x on sampling with three helpers; (9,6) at 1.3 s
     breaks even) *)
  "BrokerMinimumSeconds" -> 8.0,   (* seconds per prime (full regulator schedule) on one kernel *)
  (* "Exact": the lift is accepted only after the exact both-variable
     Pfaffian identities (development and tests).  "Numerical" (production,
     user decision 2026-08-22: checks stay separate from the calculation):
     the lift is accepted on the unseen-prime residual plus the Pfaffian
     residuals evaluated exactly at random rational points plus the
     dlog-form structural conditions (~1-2 s); the record says so
     ("Certificate" -> "NumericalResidual", "ExactDLog" deferred) and the
     exact statement is made once, by the family certificate. *)
  "FinalCheck" -> "Exact",
  "Verbose" -> True
};

SolveEpsFormStripFiniteField[record_Association,
    opts : OptionsPattern[]] := Module[
  {primes, epsilonSamples, degreeOffsets, pointCount, kernelCount,
   constructionCount, maximumTotalDegree, artifactDirectory,
   artifactPrefix, minimumPrimeCount, adaptivePrimeSampling,
   adaptiveValidationMargin, verbose, log, degreeProbe,
   selectedOffset = Missing["NotFound"], prime, launched = {},
   sampleOptions, samples, interpolation, modularData = {},
   currentEpsilonSamples, currentConstructionCount,
   currentMaximumTotalDegree, adaptivePlan,
   solution = $Failed, file, seconds, loadFile, recordFingerprint,
   fullRetry, loopExit, preparation, eliminationPlan, pilotSample,
   supportKind, supportStrategy, shells, selectedShell = "Rectangle", supportOptions, probeCount = 0,
   regulatorSampling, initialConstruction, heldOutCount, unseenPrimeCheck,
   expectedDegrees = Automatic, learnedConstruction, sampleBatch, pool,
   canonical, heldOutResult, heldOutValidated, epsilonCursor, regulatorValue, need,
   reservePrimes, lifted, unseen, sampleEpsilon, unseenPrime = None,
   brokerQ = False, pilotSeconds = 0, maximumPrimeCount, loopPrimes,
   liftReason = "OK", backendDecision, backendConfiguration,
   planDiscoveryBackend, planDiscoveryDecision,
   eliminationPlanFingerprint = None},
  If[! finiteFieldStripRecordQ[record],
    Message[SampleEpsFormStripAffine::record]; Return[$Failed]];
  backendDecision = finiteFieldStripBackendDecision[
    OptionValue["Backend"], OptionValue["BackendThreads"], 0];
  If[Lookup[backendDecision, "Status", None] =!= "OK",
    Return[backendDecision]];
  backendConfiguration = finiteFieldStripBackendConfiguration[
    OptionValue["Backend"], OptionValue["BackendThreads"]];
  If[Lookup[backendConfiguration, "Schema", None] =!=
      "FeynFacetFiniteFieldFixedCoreBackendConfiguration",
    Return[backendConfiguration]];
  planDiscoveryBackend = OptionValue["PlanDiscoveryBackend"];
  planDiscoveryDecision = finiteFieldStripPlanDiscoveryBackendDecision[
    planDiscoveryBackend];
  If[Lookup[planDiscoveryDecision, "Status", None] =!= "OK",
    Return[planDiscoveryDecision]];
  (* support learning is an optimization, never a reason to fail: a
     learned support valid at the pilot point may be inconsistent at
     other regulator values (CF67 (9,1), 2026-08-22: "SamplesInvalid"
     after the shrink); the block is then repeated on the full support *)
  If[TrueQ[OptionValue["SupportLearning"]] && ! TrueQ[$finiteFieldLearningPass],
    Module[{learned},
      learned = Block[{$finiteFieldLearningPass = True},
        SolveEpsFormStripFiniteField[record, opts]];
      If[AssociationQ[learned], Return[learned]];
      If[TrueQ[OptionValue["Verbose"]],
        Print["Support-learning pass did not solve the block; repeating on the full support"]];
      Return[SolveEpsFormStripFiniteField[record, "SupportLearning" -> False, opts]]]];
  primes = DeleteDuplicates[OptionValue["Primes"]];
  epsilonSamples = DeleteDuplicates[OptionValue["EpsilonSamples"]];
  degreeOffsets = DeleteDuplicates[OptionValue[
    "NumeratorDegreeOffsets"]];
  pointCount = OptionValue["PointCount"];
  kernelCount = facetKernelCount[
    OptionValue["KernelCount"], Length[epsilonSamples]];
  constructionCount = OptionValue["ConstructionCount"];
  maximumTotalDegree = OptionValue["MaximumTotalDegree"];
  artifactDirectory = OptionValue["ArtifactDirectory"];
  artifactPrefix = OptionValue["ArtifactPrefix"];
  recordFingerprint = Hash[record, "SHA256", "HexString"];
  minimumPrimeCount = OptionValue["MinimumPrimeCount"];
  adaptivePrimeSampling = TrueQ[OptionValue["AdaptivePrimeSampling"]];
  adaptiveValidationMargin = OptionValue["AdaptiveValidationMargin"];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[arguments___] := If[verbose, Print[arguments]];
  regulatorSampling = OptionValue["RegulatorSampling"];
  initialConstruction = OptionValue["InitialConstructionCount"];
  heldOutCount = OptionValue["HeldOutCount"];
  unseenPrimeCheck = TrueQ[OptionValue["UnseenPrimeCheck"]];
  (* regulator values beyond the fixed schedule, for held-out growth *)
  regulatorValue[k_] := If[k <= Length[epsilonSamples], epsilonSamples[[k]], k/(k + 20)];
  If[AnyTrue[primes, IntegerQ[#] && # >= 2^31 &],
    Message[SampleEpsFormStripAffine::width, SelectFirst[primes, # >= 2^31 &]];
    Return[$Failed]];
  If[! AllTrue[primes, PrimeQ] || epsilonSamples === {} ||
      degreeOffsets === {} ||
      ! AllTrue[degreeOffsets,
        MatchQ[#, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &] ||
      ! IntegerQ[minimumPrimeCount] || minimumPrimeCount < 1 ||
      ! IntegerQ[adaptiveValidationMargin] ||
        adaptiveValidationMargin < 4,
    Message[SampleEpsFormStripAffine::input]; Return[$Failed]];
  If[StringQ[artifactDirectory] && ! DirectoryQ[artifactDirectory],
    CreateDirectory[artifactDirectory,
      CreateIntermediateDirectories -> True]];
  fullRetry[] := Module[{retryPrefix},
    If[launched =!= {}, Quiet[CloseKernels[launched]]; launched = {}];
    retryPrefix = If[StringQ[artifactPrefix], artifactPrefix,
      "finite_field_strip"] <> "_full";
    log["Adaptive regulator sampling did not reconstruct exactly; ",
      "repeating with the full regulator schedule"];
    SolveEpsFormStripFiniteField[
      record,
      "Primes" -> primes,
      "MaximumPrimeCount" -> maximumPrimeCount,
      "SupportStrategy" -> supportStrategy,
      "SupportLearning" -> OptionValue["SupportLearning"],
      "EpsilonSamples" -> epsilonSamples,
      "NumeratorDegreeOffsets" -> degreeOffsets,
      "PointCount" -> pointCount,
      "KernelCount" -> kernelCount,
      "ConstructionCount" -> constructionCount,
      "MaximumTotalDegree" -> maximumTotalDegree,
      "ArtifactDirectory" -> artifactDirectory,
      "ArtifactPrefix" -> retryPrefix,
      "MinimumPrimeCount" -> minimumPrimeCount,
      "AdaptivePrimeSampling" -> False,
      "AdaptiveValidationMargin" -> adaptiveValidationMargin,
      "Elimination" -> OptionValue["Elimination"],
      "Support" -> OptionValue["Support"],
      "RegulatorSampling" -> "Deterministic",
      "Backend" -> OptionValue["Backend"],
      "BackendThreads" -> OptionValue["BackendThreads"],
      "PlanDiscoveryBackend" -> planDiscoveryBackend,
      "UnseenPrimeCheck" -> OptionValue["UnseenPrimeCheck"],
      "Verbose" -> verbose]
  ];

  (* the unseen-prime residual uses primes absent from the lift; the
     schedule is finite, so the downward walk always finds them (Codex
     audit 2026-08-21: a 65-prime window could be exhausted) *)
  maximumPrimeCount = Max[Length[primes], OptionValue["MaximumPrimeCount"]];
  reservePrimes = finiteFieldStripReservePrimes[primes,
    1 + maximumPrimeCount - Length[primes]];
  (* the first reserve prime stays unseen by every lift; the rest extend
     the configured sequence when the lift is modulus-limited *)
  loopPrimes = Join[primes, Rest[reservePrimes]];
  reservePrimes = {First[reservePrimes]};
  prime = First[primes];
  preparation = finiteFieldStripPrepare[record];
  If[preparation === $Failed,
    Message[SolveEpsFormStripFiniteField::failed]; Return[$Failed]];
  log["Prepared strip sampling once in ",
    Round[preparation["PrepareSeconds"], 0.01], " s"];
  (* A3: inside every bidegree rectangle the support ladder starts at the
     valuation bound and grows one total-degree shell per inconsistent
     probe, the rectangle being its last member *)
  supportKind = OptionValue["Support"];
  supportStrategy = OptionValue["SupportStrategy"];
  If[supportKind === Automatic && supportStrategy === "SparseFirst", supportKind = "Sparse"];
  log["Support census: ", KeyTake[Lookup[preparation, "SupportCensus", <||>],
    {"CertifiedQ", "NumeratorTotalDegreeBound", "ForcingInfinityDegree"}],
    "; support strategy ", supportStrategy];
  Do[
    shells = If[supportKind === "Rectangle" || ListQ[supportKind], {"Rectangle"},
      finiteFieldStripSupportLadder[preparation,
        preparation["DenominatorDegrees"] + offset, supportKind]];
    Module[{probeOf, probes = <||>, order, rectangleOK = False, ok},
      probeOf[shell_] := (probeCount++; probes[shell] = SampleEpsFormStripAffine[
        record, First[epsilonSamples], prime,
        "PointCount" -> pointCount,
        "NumeratorDegreeOffset" -> offset,
        "Support" -> If[shell === "Rectangle", "Rectangle", supportKind],
        "SupportShell" -> If[IntegerQ[shell], shell, 0],
        "SolveAffineSystem" -> False,
        "Preparation" -> preparation,
        "ExpectedFingerprint" -> preparation["Fingerprint"]];
        ok = AssociationQ[probes[shell]] && TrueQ[probes[shell]["Consistent"]];
        log["Finite-field degree probe ", offset, " support shell ", shell,
          If[ok, ": consistent", ": inconsistent"]];
        ok);
      order = finiteFieldStripProbeOrder[shells];
      Do[
        ok = probeOf[shell];
        Which[
          ok && shell =!= "Rectangle",
            selectedOffset = offset; selectedShell = shell; Break[],
          ok,
            (* the rectangle is consistent: it is the fallback, and the
               intermediate shells (if any follow) may still be smaller *)
            rectangleOK = True;
            If[shell === Last[order],
              selectedOffset = offset; selectedShell = "Rectangle"; Break[]],
          shell === "Rectangle",
            (* an inconsistent rectangle: no sub-support at this offset *)
            Break[]],
        {shell, order}];
      If[MissingQ[selectedOffset] && rectangleOK,
        selectedOffset = offset; selectedShell = "Rectangle"];
      If[! MissingQ[selectedOffset], degreeProbe = probes[selectedShell]]];
    If[! MissingQ[selectedOffset], Break[]],
    {offset, degreeOffsets}];
  (* SparseFirst: the certified simplex once, as the terminal probe *)
  If[MissingQ[selectedOffset] && supportKind === "Sparse" &&
      TrueQ[Lookup[Lookup[preparation, "SupportCensus", <||>], "CertifiedQ", False]],
    supportKind = Automatic;
    Module[{probe},
      probeCount++;
      probe = SampleEpsFormStripAffine[record, First[epsilonSamples], prime,
        "PointCount" -> pointCount, "NumeratorDegreeOffset" -> {0, 0},
        "Support" -> Automatic, "SupportShell" -> 0, "SolveAffineSystem" -> False,
        "Preparation" -> preparation, "ExpectedFingerprint" -> preparation["Fingerprint"]];
      If[AssociationQ[probe] && TrueQ[probe["Consistent"]],
        log["Finite-field degree probe {0, 0} certified simplex: consistent"];
        selectedOffset = {0, 0}; selectedShell = 0; degreeProbe = probe,
        log["Finite-field degree probe {0, 0} certified simplex: inconsistent"]]]];
  If[MissingQ[selectedOffset],
    Message[SolveEpsFormStripFiniteField::failed]; Return[$Failed]];
  supportOptions = {
    "Support" -> If[selectedShell === "Rectangle", "Rectangle", supportKind],
    "SupportShell" -> If[IntegerQ[selectedShell], selectedShell, 0]};
  log["Selected numerator-degree offset ", selectedOffset, ", support shell ",
    selectedShell, " (", degreeProbe["GaugeSupportCount"], " monomials, ",
    degreeProbe["GaugeUnknownCount"] + degreeProbe["FreeResidueCount"], " unknowns)"];

  (* M1 pilot: one full-path sample discovers the constrained plan that
     every later sample of every prime reuses; if discovery fails the
     solve continues on the full path (typed reason logged) *)
  eliminationPlan = None;
  If[OptionValue["Elimination"] === "Constrained",
    {pilotSeconds, pilotSample} = AbsoluteTiming[SampleEpsFormStripAffine[
      record, First[epsilonSamples], prime,
      "PointCount" -> pointCount,
      "NumeratorDegreeOffset" -> selectedOffset,
      Sequence @@ supportOptions,
      "Backend" -> "Wolfram",
      "BackendThreads" -> OptionValue["BackendThreads"],
      "PlanDiscoveryBackend" -> planDiscoveryBackend,
      "SolveAffineSystem" -> True, "DiscoverPlan" -> True,
      "ArtifactDirectory" -> artifactDirectory,
      "Preparation" -> preparation,
      "ExpectedFingerprint" -> preparation["Fingerprint"]]];
    If[AssociationQ[pilotSample] &&
        AssociationQ[Lookup[pilotSample, "EliminationPlan", None]] &&
        pilotSample["EliminationPlan"]["Status"] === "OK",
      eliminationPlan = pilotSample["EliminationPlan"];
      log["Constrained elimination plan: rank ",
        eliminationPlan["GenericRank"], ", nullity ",
        eliminationPlan["Nullity"], ", normalization columns ",
        eliminationPlan["NormalizationColumns"]],
      log["Constrained plan unavailable (",
        If[AssociationQ[pilotSample],
          Lookup[Lookup[pilotSample, "EliminationPlan", <||>],
            "Status", "no pilot solution"], "pilot failed"],
        "); continuing on the full elimination path"]];
    (* Design/CFFR1Backend.md item 6: an explicit "FLINTAffineRREF"
       request NEVER falls back.  A missing plan there is the block's
       typed result, not a silent return to the Wolfram discoverer. *)
    If[planDiscoveryBackend === "FLINTAffineRREF" &&
        ! AssociationQ[eliminationPlan],
      Return[<|"Status" -> "PlanDiscoveryBackendFailed",
        "PlanDiscoveryBackendRequested" -> planDiscoveryBackend,
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryFailure" -> If[AssociationQ[pilotSample],
          Lookup[pilotSample, "EliminationPlan",
            <|"Status" -> "NoPilotSolution"|>],
          <|"Status" -> "PilotSampleFailed"|>]|>]]];

  (* support learning (see the option) *)
  If[TrueQ[OptionValue["SupportLearning"]] && AssociationQ[pilotSample] &&
      AssociationQ[eliminationPlan] && eliminationPlan["Status"] === "OK" &&
      MatchQ[Lookup[pilotSample, "GaugeSupport", None], {{_Integer, _Integer} ..}] &&
      VectorQ[Lookup[pilotSample, "ParticularSolution", None], IntegerQ],
    Module[{fullSupport = pilotSample["GaugeSupport"], blockLength, columns, nullBasis,
        particular, normalized, gaugeCount, used, learned, learnedPilot, learnedPlan, t0 = AbsoluteTime[]},
      blockLength = Length[fullSupport];
      gaugeCount = Times @@ preparation["Dimensions"] blockLength;
      columns = eliminationPlan["NormalizationColumns"];
      particular = pilotSample["ParticularSolution"];
      nullBasis = Lookup[pilotSample, "NullspaceBasis", {}];
      (* the normalized solution: normalization columns zero *)
      normalized = If[nullBasis === {} || columns === {}, particular,
        Module[{nb = Mod[Inverse[nullBasis[[All, columns]], Modulus -> prime] . nullBasis, prime]},
          Mod[particular - particular[[columns]] . nb, prime]]];
      used = Select[Range[blockLength], Function[m,
        AnyTrue[Range[0, Times @@ preparation["Dimensions"] - 1], normalized[[# blockLength + m]] =!= 0 &]]];
      learned = fullSupport[[used]];
      If[0 < Length[learned] < Floor[0.9 blockLength],
        learnedPilot = SampleEpsFormStripAffine[record, First[epsilonSamples], prime,
          "PointCount" -> pointCount, "NumeratorDegreeOffset" -> selectedOffset,
          "Support" -> learned, "SupportShell" -> 0,
          "Backend" -> "Wolfram",
          "BackendThreads" -> OptionValue["BackendThreads"],
          "PlanDiscoveryBackend" -> planDiscoveryBackend,
          "SolveAffineSystem" -> True, "DiscoverPlan" -> True,
          "ArtifactDirectory" -> artifactDirectory,
          "Preparation" -> preparation, "ExpectedFingerprint" -> preparation["Fingerprint"]];
        learnedPlan = If[AssociationQ[learnedPilot], Lookup[learnedPilot, "EliminationPlan", None], None];
        If[AssociationQ[learnedPilot] && TrueQ[learnedPilot["Consistent"]] &&
            AssociationQ[learnedPlan] && learnedPlan["Status"] === "OK",
          log["Support learned from the pilot: ", Length[learned], " of ", blockLength,
            " monomials (", Round[AbsoluteTime[] - t0, 0.1], " s); rank ", learnedPlan["GenericRank"],
            ", nullity ", learnedPlan["Nullity"]];
          supportKind = learned; selectedShell = 0;
          supportOptions = {"Support" -> learned, "SupportShell" -> 0};
          eliminationPlan = learnedPlan; pilotSample = learnedPilot; degreeProbe = learnedPilot,
          log["Support learning: the ", Length[learned], "-monomial support was not consistent; keeping the ",
            blockLength, "-monomial support"]],
        log["Support learning: pilot uses ", Length[learned], " of ", blockLength, " monomials; nothing to shrink"]]]];

  (* broker decision: a pool is serving, we own no subkernels, and the
     pilot (or the degree probe when no plan was discovered) showed the
     build is worth a pool round trip *)
  (* the quantity compared is one prime's worth of samples on one kernel:
     the pilot's whole wall time (row build + rank + modular solve) times
     the regulator schedule.  On 2026-08-22 the per-sample row-build test
     (1.5 s) kept the broker off on blocks where every prime cost 35-65 s
     and five helpers idled: after the sampler fix the build is 0.2 s and
     the modular solve dominates. *)
  (* the pilot also discovers the plan and computes a nullspace, which a
     regular sample does not: subtract those; the rest is an upper bound *)
  pilotSeconds = If[AssociationQ[pilotSample],
    Max[0, pilotSeconds - Lookup[pilotSample, "PlanDiscoverySeconds", 0] -
      Lookup[pilotSample, "NullspaceSeconds", 0]],
    Lookup[degreeProbe, "SamplingSeconds", 0]];
  brokerQ = kernelCount <= 1 && taskBrokerActiveQ[] &&
    TrueQ[pilotSeconds * Max[1, Length[epsilonSamples]] >= OptionValue["BrokerMinimumSeconds"]];
  log["Broker decision: pool active ", taskBrokerActiveQ[], ", pilot ",
    Round[pilotSeconds, 0.01], " s per sample, schedule ", Length[epsilonSamples], ", minimum ",
    OptionValue["BrokerMinimumSeconds"], " s per prime -> ", brokerQ];
  If[brokerQ, log["Sample batches go to the KernelPool helpers (",
    Round[pilotSeconds * Max[1, Length[epsilonSamples]], 0.1], " s per prime on one kernel, ",
    taskBrokerFreeKernels[], " free)"]];
  If[OptionValue["Backend"] === "FLINT" &&
      ! AssociationQ[eliminationPlan],
    Return[<|"Status" -> "FLINTRequiresValidatedEliminationPlan",
      "BackendRequested" -> "FLINT",
      "PlanDiscoveryBackendRequested" -> planDiscoveryBackend,
      "PlanDiscoveryBackendUsed" -> "Wolfram"|>]];
  If[kernelCount > 1 && Length[Kernels[]] < kernelCount,
    launched = Quiet[LaunchKernels[kernelCount - Length[Kernels[]]]]];
  (* the subkernel bootstrap goes through the installation loader
     (B3, generality pass 2026-08-23; default unchanged) *)
  loadFile = $feynFacetLoader;
  If[kernelCount > 1,
    With[{fileName = loadFile},
      ParallelEvaluate[Quiet[Get[fileName], General::shdw]]]];
  sampleOptions = {
    "PointCount" -> pointCount,
    "NumeratorDegreeOffset" -> selectedOffset,
    Sequence @@ supportOptions,
    "Backend" -> OptionValue["Backend"],
    "BackendThreads" -> OptionValue["BackendThreads"],
    "PlanDiscoveryBackend" -> planDiscoveryBackend,
    "SolveAffineSystem" -> True,
    "Preparation" -> preparation,
    "ExpectedFingerprint" -> preparation["Fingerprint"],
    "EliminationPlan" -> eliminationPlan};
  eliminationPlanFingerprint = If[AssociationQ[eliminationPlan],
    Lookup[eliminationPlan, "PlanFingerprint", None], None];
  currentEpsilonSamples = epsilonSamples;
  currentConstructionCount = constructionCount;
  currentMaximumTotalDegree = maximumTotalDegree;
  Do[
    file = If[StringQ[artifactDirectory],
      FileNameJoin[{artifactDirectory,
        artifactPrefix <> "_mod_" <> ToString[prime] <> ".wl"}],
      None];
    (* an artifact of an earlier pass of the same block is reused only
       when it belongs to this record and this ansatz; a stale one (the
       block's forcing changed after a regulator factorization of the
       rows above it -- CF265 (18,17), 2026-08-22) is ignored and
       overwritten instead of aborting the solve *)
    If[StringQ[file] && FileExistsQ[file],
      interpolation = FamilyArtifactRead[file];
      If[! finiteFieldStripModularArtifactValidQ[interpolation,
          recordFingerprint, selectedOffset, selectedShell,
          eliminationPlanFingerprint, backendConfiguration,
          planDiscoveryBackend],
        log["Stale modular interpolation for prime ", prime, " ignored (another record or ansatz)"];
        Quiet[DeleteFile[file]]]];
    If[StringQ[file] && FileExistsQ[file],
      log["Loaded modular interpolation ", prime],
      sampleBatch[values_List] := Which[
        brokerQ, taskBrokerSampleBatch[record, values, prime, sampleOptions],
        kernelCount > 1,
        ParallelMap[
          SampleEpsFormStripAffine[record, #, prime, Sequence @@ sampleOptions] &,
          values, Method -> "FinestGrained", DistributedContexts -> Automatic],
        True,
        SampleEpsFormStripAffine[record, #, prime, Sequence @@ sampleOptions] & /@ values];
      If[regulatorSampling === "HeldOut",
        (* A2: construction prefix, held-out round, grow on failure; the
           first prime starts from InitialConstructionCount, later primes
           from the learned degree profile; the deterministic schedule is
           the cap and the fallback *)
        learnedConstruction = If[expectedDegrees === Automatic, initialConstruction,
          Max[Replace[Total /@ expectedDegrees, -Infinity -> 0, {1}]] + 1];
        need = learnedConstruction + heldOutCount;
        pool = {}; epsilonCursor = 0; interpolation = $Failed;
        {seconds, heldOutResult} = AbsoluteTiming[Catch[While[True,
          (* a regulator value at which a denominator of the block vanishes
             identically (a pole of the forcing in eps, e.g. 1 - 3 eps at
             the schedule value 1/3: CF408 (7,4), 2026-08-22) yields no
             sampling point; such values are discarded and the schedule
             continues, instead of aborting the prime *)
          samples = {};
          Module[{attempts = 0, batch, want},
            While[Length[samples] < need && attempts < 4 need,
              want = need - Length[samples];
              batch = sampleBatch[Table[regulatorValue[epsilonCursor + k], {k, want}]];
              epsilonCursor += want; attempts += want;
              If[AnyTrue[batch, ! AssociationQ[#] &],
                log["Discarded ", Count[batch, Except[_Association]],
                  " regulator value(s) without a nonsingular sampling point"]];
              samples = Join[samples, Select[batch, AssociationQ]]]];
          If[Length[samples] < need, Throw["SampleFailed", "a2"]];
          pool = Join[pool, samples];
          canonical = finiteFieldStripCanonicalSamples[pool, prime, Which[
            AssociationQ[eliminationPlan], eliminationPlan["NormalizationColumns"],
            modularData === {}, Automatic,
            True, First[modularData]["NormalizationColumns"]]];
          If[canonical["Status"] =!= "OK", Throw[canonical["Status"], "a2"]];
          heldOutResult = finiteFieldStripHeldOutInterpolate[
            canonical["CanonicalSamples"], prime,
            "InitialConstructionCount" -> learnedConstruction,
            "HeldOutCount" -> heldOutCount,
            "MaximumTotalDegree" -> maximumTotalDegree,
            "ExpectedDegrees" -> expectedDegrees];
          Switch[heldOutResult["Status"],
            "HeldOutValidated", heldOutValidated = heldOutResult; Throw["Validated", "a2"],
            "RejectPrimeDegreeProfileChanged", Throw["RejectPrime", "a2"],
            "MoreSamplesRequired",
              need = Max[heldOutResult["RequiredAdditionalSampleCount"], heldOutCount];
              If[Length[pool] + need > Length[epsilonSamples] + 8, Throw["Cap", "a2"]],
            _, Throw["Failed", "a2"]]],
          "a2"]];
        log["Prime ", prime, ": held-out sampling ", Length[pool], " regulator values -> ",
          heldOutResult, " (", Round[seconds, 0.1], " s)"];
        Which[
          heldOutResult === "RejectPrime",
            log["  degree profile changed at this prime; skipping it"]; Continue[],
          heldOutResult === "Validated",
            interpolation = Join[heldOutValidated,
              <|"NormalizationColumns" -> canonical["NormalizationColumns"],
                "GenericRank" -> canonical["GenericRank"],
                "DiscardedSingularEpsilonValues" -> canonical["DiscardedSingularEpsilonValues"]|>,
              canonical["ReferenceSample"]];
            If[expectedDegrees === Automatic,
              expectedDegrees = Lookup[interpolation["Interpolations"], "Degrees"]];
            samples = pool,
          True,
            (* cap or failure: the deterministic interpolation on everything sampled so far *)
            log["  held-out mode did not certify (", heldOutResult, "); deterministic interpolation"];
            samples = pool;
            interpolation = If[samples === {} || AnyTrue[samples, ! AssociationQ[#] &], $Failed,
              InterpolateEpsFormStripAffine[samples, prime,
                "ConstructionCount" -> Min[currentConstructionCount, Max[1, Length[samples] - 4]],
                "MaximumTotalDegree" -> currentMaximumTotalDegree,
                "NormalizationColumns" -> Which[
                  AssociationQ[eliminationPlan], eliminationPlan["NormalizationColumns"],
                  modularData === {}, Automatic,
                  True, First[modularData]["NormalizationColumns"]]]]],
        (* deterministic schedule *)
        log["Sampling prime ", prime, " with ", kernelCount,
          " kernel", If[kernelCount === 1, "", "s"], " at ",
          Length[currentEpsilonSamples], " regulator values"];
        {seconds, samples} = AbsoluteTiming[sampleBatch[currentEpsilonSamples]];
        If[AnyTrue[samples, ! AssociationQ[#] &],
          (* regulator values at a pole of the forcing are replaced by
             values beyond the schedule (2026-08-22) *)
          Module[{missing = Count[samples, Except[_Association]], extra, cursor = Length[epsilonSamples] + 20},
            samples = Select[samples, AssociationQ];
            While[missing > 0 && cursor < Length[epsilonSamples] + 200,
              extra = sampleBatch[Table[regulatorValue[cursor + k], {k, missing}]];
              cursor += missing;
              samples = Join[samples, Select[extra, AssociationQ]];
              missing = Count[extra, Except[_Association]]];
            log["Regulator values at a pole of the forcing replaced; ", Length[samples], " samples"]]];
        If[Length[samples] < Length[currentEpsilonSamples],
          If[adaptivePrimeSampling, loopExit = "FullRetry"; Break[]];
          Message[SolveEpsFormStripFiniteField::failed];
          loopExit = "Failed"; Break[]];
        interpolation = InterpolateEpsFormStripAffine[
          samples, prime,
          "ConstructionCount" -> currentConstructionCount,
          "MaximumTotalDegree" -> currentMaximumTotalDegree,
          "NormalizationColumns" -> Which[
            AssociationQ[eliminationPlan],
              eliminationPlan["NormalizationColumns"],
            modularData === {}, Automatic,
            True, First[modularData]["NormalizationColumns"]]]];
      If[! AssociationQ[interpolation] ||
          interpolation["UnresolvedCoordinates"] =!= {},
        If[adaptivePrimeSampling && regulatorSampling =!= "HeldOut", loopExit = "FullRetry"; Break[]];
        Message[SolveEpsFormStripFiniteField::failed];
        loopExit = "Failed"; Break[]];
      interpolation = Join[interpolation,
        <|"SamplingSeconds" -> seconds,
          "SelectedNumeratorDegreeOffset" -> selectedOffset,
          "SelectedSupportShell" -> selectedShell,
          "RecordFingerprint" -> recordFingerprint,
          "EliminationPlanFingerprint" -> eliminationPlanFingerprint,
          "BackendConfiguration" -> backendConfiguration,
          "PlanDiscoveryBackend" -> planDiscoveryBackend,
          (* M0 census: per-sample stage timers persisted with the
             prime artifact, so every production run is self-
             instrumenting (2026-08-20). *)
          "SampleTimings" -> (KeyTake[#, {"EpsilonValue",
            "SetupSeconds", "PreprocessingSeconds", "SamplingSeconds",
            "RankSeconds", "AugmentedRankSeconds", "LinearSolveSeconds",
            "NullspaceSeconds", "MatrixDimensions", "NonzeroEntries",
            "Rank", "Nullity", "AcceptedPoints", "AttemptCount",
            "PeakMemoryBytes", "PreparationReused", "SolvePath",
            "ConstrainedSolveSeconds", "Backend", "BackendRequested",
            "BackendUsed", "BackendFallbackReason", "BackendFailure",
            "PlanValidationStatus", "PlanDiscoveryBackendRequested",
            "PlanDiscoveryBackendUsed", "Status"}] & /@ samples)|>];
      If[StringQ[file], finiteFieldStripPutAtomic[interpolation, file]]];
    AppendTo[modularData, interpolation];
    If[adaptivePrimeSampling && regulatorSampling =!= "HeldOut" && Length[modularData] === 1,
      adaptivePlan = finiteFieldStripAdaptiveSamplingPlan[
        interpolation, Length[epsilonSamples],
        adaptiveValidationMargin];
      currentEpsilonSamples = Take[
        epsilonSamples, adaptivePlan["SampleCount"]];
      currentConstructionCount = adaptivePlan["ConstructionCount"];
      currentMaximumTotalDegree = adaptivePlan["MaximumTotalDegree"];
      log["Later-prime regulator plan: ",
        Length[currentEpsilonSamples], " samples, construction count ",
        currentConstructionCount, ", maximum total degree ",
        currentMaximumTotalDegree]];
    If[Length[modularData] >= minimumPrimeCount,
      (* lift first; in held-out mode an unseen-prime residual guards the
         exact check (a lift that is merely consistent with the primes
         used is rejected by a prime absent from the lift) *)
      liftReason = "OK";
      lifted = Quiet[
        Check[
          Check[
            Check[
              ReconstructEpsFormStrip[record, modularData,
                "KernelCount" -> kernelCount, "ExactCheck" -> False],
              liftReason = "data"; $Failed, {ReconstructEpsFormStrip::data}],
            liftReason = "modulus"; $Failed, {ReconstructEpsFormStrip::modulus}],
          liftReason = "check"; $Failed, {ReconstructEpsFormStrip::check}],
        {ReconstructEpsFormStrip::data, ReconstructEpsFormStrip::modulus,
         ReconstructEpsFormStrip::check}];
      If[! AssociationQ[lifted],
        log["Lift after ", Length[modularData], " primes: ",
          Switch[liftReason,
            "modulus", StringJoin["combined modulus too small for the coefficient heights (bound ~",
              ToString[Floor[IntegerLength[Floor[Sqrt[(Times @@ Lookup[modularData, "Prime"] - 1)/2]]]]],
              " digits); continuing with more primes"],
            "data", "modular records inconsistent",
            "check", "exact check failed",
            _, "failed"]];
        If[liftReason === "modulus" && prime === Last[loopPrimes],
          log["Prime sequence exhausted at ", Length[modularData],
            " primes with a modulus-limited lift; raise \"MaximumPrimeCount\""]]];
      unseen = True;
      If[AssociationQ[lifted] && unseenPrimeCheck,
        unseenPrime = First[reservePrimes];
        (* the unseen regulator value must not sit at a pole of the forcing *)
        unseen = False;
        Do[sampleEpsilon = regulatorValue[Length[epsilonSamples] + 11 + 7 j];
          unseen = finiteFieldStripUnseenPrimeResidualQ[record, lifted, preparation,
            unseenPrime, sampleEpsilon, sampleOptions];
          If[TrueQ[unseen] || ! TrueQ[Lookup[$finiteFieldLastUnseenSample, "PointFailure", False]], Break[]],
          {j, 0, 5}];
        log["Unseen-prime residual at ", unseenPrime, ": ",
          If[TrueQ[unseen], "zero", "NONZERO -- lift rejected, more primes"]]];
      (* a lift that passes the unseen-prime residual is the rational
         solution of the ansatz; if a letter depends on the regulator or
         a residue on the kinematics, no further prime can repair it:
         stop with a typed reason (regulator-dependent residues are
         allowed -- the sector driver factorizes the regulator later) *)
      If[AssociationQ[lifted] && TrueQ[unseen] &&
          ! (TrueQ[lifted["LettersEpsFree"]] && TrueQ[lifted["ResiduesKinematicsFree"]]),
        Message[SolveEpsFormStripFiniteField::dlog, Pick[
          {"LettersDependOnRegulator", "ResiduesDependOnKinematics"},
          {! TrueQ[lifted["LettersEpsFree"]], ! TrueQ[lifted["ResiduesKinematicsFree"]]}, True]];
        loopExit = "NotDLogForm"; Break[]];
      If[AssociationQ[lifted] && TrueQ[unseen] &&
          MemberQ[{"Numerical", "Modular"}, OptionValue["FinalCheck"]] && unseenPrimeCheck,
        Module[{numerical = VerifyEpsFormStrip[record, lifted, "Method" -> "Numerical", "KernelCount" -> 1]},
          If[AssociationQ[numerical] && TrueQ[numerical["DLogFormCertified"]],
            log["Numerical Pfaffian residuals at ", numerical["Points"], " random points: zero (",
              Round[numerical["ExactCheckSeconds"], 0.1], " s); exact statement deferred to the family certificate"];
            solution = Join[KeyDrop[lifted, "LiftedVector"],
              KeyTake[numerical, {"NumericalPfaffianResidualsZero", "LettersEpsFree",
                "ResiduesKinematicsFree", "ResiduesEpsFree"}],
              <|"Status" -> "Solved", "Certificate" -> "NumericalResidual",
                "ExactDLog" -> Missing["DeferredToFamilyCertificate"],
                "DLogFormCertified" -> Missing["DeferredToFamilyCertificate"],
                "ExactPfaffianResidualsZero" -> Missing["NotRunNumericalMode"],
                "UnseenPrime" -> unseenPrime|>];
            Break[],
            log["Numerical Pfaffian residuals NONZERO or structure failed: ",
              If[AssociationQ[numerical], KeyTake[numerical, {"NumericalPfaffianResidualsZero", "StructuralFailureReasons"}], numerical],
              " -- lift rejected, more primes"]]]];
      solution = If[AssociationQ[lifted] && TrueQ[unseen],
        Quiet[Check[
          ReconstructEpsFormStrip[record, modularData, "KernelCount" -> kernelCount], $Failed,
          {ReconstructEpsFormStrip::data, ReconstructEpsFormStrip::modulus,
           ReconstructEpsFormStrip::check}],
          {ReconstructEpsFormStrip::data, ReconstructEpsFormStrip::modulus,
           ReconstructEpsFormStrip::check}],
        $Failed];
      If[AssociationQ[solution], Break[]]],
    {prime, loopPrimes}];
  (* Return inside Do only terminates the loop (2026-08-20 review: a
     successful fullRetry value was discarded here, and the full solve
     then ran a second time). The loop records its exit reason. *)
  If[loopExit === "FullRetry", Return[fullRetry[]]];
  If[launched =!= {}, Quiet[CloseKernels[launched]]; launched = {}];
  If[loopExit === "Failed" || loopExit === "NotDLogForm", Return[$Failed]];
  If[! AssociationQ[solution],
    (* a modulus-limited lift is not a sampling problem: the full
       regulator schedule would reproduce the same residues *)
    If[adaptivePrimeSampling && liftReason =!= "modulus", Return[fullRetry[]]];
    Message[SolveEpsFormStripFiniteField::failed]; Return[$Failed]];
  Join[solution, <|
    "Method" -> "SimultaneousFiniteFieldAffinePDE",
    "EliminationPlan" -> eliminationPlan,
    "EliminationPlanFingerprint" -> eliminationPlanFingerprint,
    "BackendRequested" -> OptionValue["Backend"],
    "BackendThreads" -> OptionValue["BackendThreads"],
    "BackendConfiguration" -> backendConfiguration,
    "BackendsUsed" -> DeleteDuplicates[Cases[
      Lookup[Flatten[Lookup[modularData, "SampleTimings", {}]],
        "BackendUsed", {}], _String]],
    "PlanDiscoveryBackendRequested" -> planDiscoveryBackend,
    "PlanDiscoveryBackendUsed" -> If[AssociationQ[eliminationPlan],
      Lookup[eliminationPlan, "PlanDiscoveryBackendUsed", None], None],
    "SelectedNumeratorDegreeOffset" -> selectedOffset,
    "SelectedSupportShell" -> selectedShell,
    "SupportStrategy" -> supportStrategy,
    "ProbeCount" -> probeCount,
    "DegreeProbe" -> If[AssociationQ[degreeProbe],
      KeyTake[degreeProbe, {"GaugeSupportCount", "GaugeUnknownCount", "FreeResidueCount", "Rank", "SupportMaximumDegrees"}], degreeProbe],
    "SelectedSupportKind" -> If[selectedShell === "Rectangle", "Rectangle",
      If[supportKind === "Sparse", "Sparse", "Simplex"]],
    "ModularPrimeCount" -> Length[modularData],
    "MaximumPrimeCount" -> maximumPrimeCount,
    "AdaptivePrimeSampling" -> adaptivePrimeSampling,
    "RegulatorSampling" -> regulatorSampling,
    "UnseenPrimeCheck" -> unseenPrimeCheck,
    "UnseenPrime" -> unseenPrime,
    "PrimeSampleCounts" -> Lookup[modularData, "SampleCount", {}],
    "PrimeConstructionCounts" ->
      Lookup[modularData, "ConstructionCount", {}],
    "PrimeMaximumTotalDegrees" ->
      Lookup[modularData, "MaximumTotalDegree", {}],
    "PrimeSamplingSeconds" ->
      Lookup[modularData, "SamplingSeconds", {}],
    "PrimeInterpolationSeconds" ->
      Lookup[modularData, "InterpolationSeconds", {}],
    "TotalSamplingSeconds" ->
      Total[Lookup[modularData, "SamplingSeconds", {}]],
    "TotalInterpolationSeconds" ->
      Total[Lookup[modularData, "InterpolationSeconds", {}]]
  |>]
];

InstallEpsFormStripSolution[checkpoint_Association,
    record_Association, solution_Association,
    sector_Integer, lowerSector_Integer] := Module[
  {gauge, previousSolvers, previousLowerSectors, expectedDimensions,
   newSolver, lettersEpsilonFree, residuesKinematicsFree},
  If[! finiteFieldStripRecordQ[record] ||
      ! And @@ (KeyExistsQ[solution, #] & /@
        {"Gauge", "Alphabet", "ResidueMatrices"}) ||
      ! TrueQ[Lookup[solution, "ExactPfaffianResidualsZero", False]] ||
      ! MatrixQ[Lookup[checkpoint, "PrevD", Missing[]]] ||
      ! ListQ[Lookup[checkpoint, "StripSolvers", Missing[]]] ||
      Lookup[checkpoint, "Sector", Missing[]] =!= sector,
    Message[InstallEpsFormStripSolution::state]; Return[$Failed]];
  (* the two dlog-form conditions are recomputed from the solution itself
     (never trusted from stored booleans): regulator-free letters and
     residues free of the kinematic variables; regulator-dependent
     residues are the normal product of this rung and are factorized by
     the sector driver afterwards (Codex audit 2026-08-21, scoped) *)
  lettersEpsilonFree = FreeQ[solution["Alphabet"], record["Regulator"]];
  residuesKinematicsFree = FreeQ[solution["ResidueMatrices"],
    Alternatives @@ record["Variables"]];
  If[! lettersEpsilonFree || ! residuesKinematicsFree,
    Message[InstallEpsFormStripSolution::state]; Return[$Failed]];
  gauge = solution["Gauge"];
  expectedDimensions = Rest[Dimensions[record["Strip"][[3]]]];
  previousSolvers = checkpoint["StripSolvers"];
  previousLowerSectors = Lookup[previousSolvers, "LowerSector", {}];
  If[Dimensions[gauge] =!= expectedDimensions ||
      Dimensions[checkpoint["PrevD"]][[1]] =!=
        First[expectedDimensions] ||
      MemberQ[previousLowerSectors, lowerSector] ||
      previousLowerSectors =!= ReverseSort[previousLowerSectors] ||
      AnyTrue[previousLowerSectors, # <= lowerSector &],
    Message[InstallEpsFormStripSolution::state]; Return[$Failed]];
  newSolver = <|
    "Sector" -> sector,
    "LowerSector" -> lowerSector,
    "Method" -> Lookup[solution, "Method",
      "SimultaneousFiniteFieldAffinePDE"],
    "NumeratorDegree" -> solution["GaugeNumeratorDegrees"],
    "DenominatorDegree" -> solution["GaugeDenominatorDegrees"],
    "ExactDLog" -> True,
    "TwoVariableResidualZero" -> True,
    "FiniteFieldPrimes" -> solution["Primes"]
  |>;
  Join[checkpoint, <|
    "PrevD" -> MapThread[Join, {gauge, checkpoint["PrevD"]}],
    "StripSolvers" -> Append[previousSolvers, newSolver]
  |>]
];
