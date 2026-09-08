$stage1StartTime=AbsoluteTime[];
#!/usr/bin/env wolframscript
(* Completing the family's eps-form -- STANDARDIZED SECTOR ROUTE.
   Existing families remain on the ordinary CANONICA route.  Only a sector
   that ordinary CANONICA cannot transform is completed strip by strip.

   Per sector k = 2..nSectors, on the truncated connection A[1..nk,1..nk] whose
   diagonal blocks are certified eps-forms:
     A. Try CANONICA`TransformOffDiagonalBlock on the complete sector.
     B. If A does not finish, construct CANONICA's exact NextEquationD for
        each unresolved strip.  SolveOffDiagonalBasisTransformationBlock first recognizes an
        existing dlog strip, then searches numerator degrees 0,1,2,3 for
        120 s each on no more than eight local kernels, and only then invokes Maple's exact
        residue-compatibility construction.  If IntegrableConnections cannot
        solve the rational system, the final Maple route uses a finite
        rational ansatz whose denominator is generated from all singular
        letters of the strip.  Every returned strip gauge is checked in both
        differential variables before it is composed.  Each checked strip is
        written atomically, so an interrupted sector resumes from that gauge.
     C. Apply CANONICA`TransformDlogToEpsForm to the completed sector row.
   Family acceptance is the package family dlog epsilon-form validator. In
   Production it evaluates the defining identities at independent finite-
   field points and records a probabilistic result; in Development it uses
   characteristic-zero symbolic identities. Only the validated V2
   FamilyDLogEpsilonForm is persisted.
   Usage: family_epsform_sector.wls <family> <outdir>
          <familyDifferentialSystemFile> <blockDecompositionFile>
          <coefficientPresentationFile> <diagonalBlockFormsDirectory>
          [sectorBudget=1800] [tag] [directSectorBudget=30] *)
$HistoryLength = 0;
driverFile = ExpandFileName[$InputFileName];
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];
(* pool subkernels keep state: clear the Global` symbols CANONICA and earlier
   missions leave behind (they broke AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks on a reused
   subkernel: "assembly failed" on kernel 26, 2026-08-18) *)
Scan[Function[nm, ToExpression["Global`" <> nm, InputForm, Function[sy, Quiet[Unprotect[sy]]; ClearAll[sy], HoldAll]]], {"tau", "s", "u", "p", "x", "y", "eps"}];
(* CANONICA is loaded AFTER assembly (its Global` shadowing of x, y, eps must
   not touch the assembly step); it parallelises internally
   (ParallelizeMap[$ComputeParallel]) -- inside a pool subkernel that would
   launch sub-subkernels on the shared licence AND escape TimeConstrained
   (measured: a 300 s-constrained strip step ran 33 min) -> serial. *)
args = Rest[$ScriptCommandLine];
If[Length[args] < 6,
  Print["Usage: family_epsform_sector.wls <family> <outdir> " <>
    "<familyDifferentialSystemFile> <blockDecompositionFile> " <>
    "<coefficientPresentationFile> <diagonalBlockFormsDirectory> " <>
    "[sectorBudget=1800] [tag] [directSectorBudget=30]"];
  Exit[64]];
family = args[[1]]; outdir = args[[2]];
familyDifferentialSystemFile = ExpandFileName[args[[3]]];
blockDecompositionFile = ExpandFileName[args[[4]]];
coefficientPresentationFile = ExpandFileName[args[[5]]];
diagonalBlockFormsDirectory = ExpandFileName[args[[6]]];
sectorBudget = If[Length[args] >= 7, ToExpression[args[[7]]], 1800];
tag = If[Length[args] >= 8, args[[8]], ""];
If[StringLength[tag] > 0 && ! StringStartsQ[tag, "_"],
  tag = "_" <> tag];
directSectorBudget = If[Length[args] >= 9, ToExpression[args[[9]]], 30];
(* ---- WHOLE-FAMILY BUDGET (2026-08-25, Codex 14:30) -----------------
   sectorBudget is a PER-SECTOR wall allowance, recomputed at the start
   of every sector.  A family that is restarted therefore gets a fresh
   allowance for every sector it re-enters, and a whole-family bound
   simply did not exist: an eight-hour family could be resumed into
   another eight hours without anything noticing.
   FACET_FAMILY_BUDGET declares the family's own wall allowance in
   seconds.  Its DEADLINE EPOCH is persisted in the sector state file at
   the first sector that runs under it, so a resumed driver inherits the
   REMAINING budget rather than a new one; a resume after the epoch has
   passed stops typed before it touches a sector.  Unset (the default)
   is Infinity and every existing caller is unchanged. *)
familyBudget = Module[
  {value = Environment["FACET_FAMILY_BUDGET"], parsed},
  parsed = If[StringQ[value] && StringLength[value] > 0,
    Quiet[Check[ToExpression[value], $Failed]], $Failed];
  If[IntegerQ[parsed] && parsed > 0, parsed, Infinity]
];
familyDeadline = Infinity;
(* Per-strip route (FACET_OFF_DIAGONAL_BLOCK_ROUTE): "FiniteFieldFirst" (default since
   2026-08-22: dlog recognition -> finite-field affine solve; NO automatic
   CANONICA/Maple fallback -- those are manual tools (user decision
   2026-08-22); an unsolved block ends the family with exit 2 and the
   block record in <scratch>/<family>_<k>_<j>_unsolved.wl) or "Legacy" (CANONICA
   degrees 0-3 -> Maple -> finite field).  Measured on 20 real CF254 strips
   (BenchmarkStripBackends/StripMethods_2026-08-21): finite field 20/20 in
   872 s total; CANONICA ladder 15/20 in 2790 s; Maple 13/20, never faster. *)
(* Check level (FACET_CHECK_LEVEL): "Production" (default; blocks and the
   final family are validated at finite-field points) or "Development"
   (explicit diagnostic opt-in for exact symbolic checks on small inputs).
   A missing environment setting must never select characteristic-zero
   Together on a production family. *)
checkLevel = Module[{value = Environment["FACET_CHECK_LEVEL"]},
  If[StringQ[value] && value === "Development", "Development", "Production"]];
productionQ = checkLevel === "Production";
(* Assembly helpers and worker kernels read this same setting. The driver
   default must reach them; otherwise an unset environment selected symbolic
   Development checks despite the driver's Production branch. *)
SetEnvironment["FACET_CHECK_LEVEL"->checkLevel];
obstructionAnalysisSeconds=Module[{value=Environment["FACET_OBSTRUCTION_ANALYSIS_SECONDS"],number},
 number=If[StringQ[value],Quiet[Check[ToExpression[value],$Failed]],$Failed];
 If[NumericQ[number] && number>0,number,0]
];
offDiagonalBlockRoute = Module[{value = Environment["FACET_OFF_DIAGONAL_BLOCK_ROUTE"]},
  If[StringQ[value] && value === "Legacy", "Legacy", "FiniteFieldFirst"]];
(* Overhaul 2026-09-02: the CANONICA/Maple strip ladder (SolveOffDiagonalBasisTransformationBlock)
   is retired to FeynFacet/Private_Backup; the Legacy route would now run on
   RouteRetired records.  Refuse it loudly instead of silently degrading. *)
If[offDiagonalBlockRoute === "Legacy",
  Print["[sector-epsform] !! FACET_OFF_DIAGONAL_BLOCK_ROUTE=Legacy is retired (2026-09-02): the CANONICA/Maple strip ladder lives in FeynFacet/Private_Backup and is not loaded; use the default FiniteFieldFirst route"];
  Exit[64]];
kernelCount = Module[{value = Environment["FACET_KERNEL_COUNT"]},
  If[StringQ[value] && StringLength[value] > 0,
    Min[8, Max[1, ToExpression[value]]],
    8
  ]
];
(* Native direct-MQ RREF threads are independent of Wolfram helper kernels.
   Unset preserves the historical tuning by inheriting FACET_KERNEL_COUNT;
   an explicit value permits one main kernel with an eight-thread native
   adapter. *)
mqNativeThreadCap = Module[{value = Environment["FACET_MQ_NATIVE_THREADS"],
    parsed},
  If[! StringQ[value] || StringLength[value] === 0, Return[kernelCount]];
  parsed = Quiet[Check[ToExpression[value], $Failed]];
  If[! IntegerQ[parsed] || ! Between[parsed, {1, 8}],
    Print["[sector-epsform] FACET_MQ_NATIVE_THREADS must be an integer " <>
      "from 1 through 8"]; Exit[64]];
  parsed
];
mqNativeThreads = FeynFacet`Private`taskBrokerNativeThreadLimit[
  mqNativeThreadCap];
mqImageKernelCount = Module[{
    value = Environment["FACET_MQ_IMAGE_KERNEL_COUNT"], parsed},
  If[! StringQ[value] || StringLength[value] === 0, Return[Automatic]];
  parsed = Quiet[Check[ToExpression[value], $Failed]];
  If[! IntegerQ[parsed] || ! Between[parsed, {1, 8}],
    Print["[sector-epsform] FACET_MQ_IMAGE_KERNEL_COUNT must be an " <>
      "integer from 1 through 8"];
    Exit[64]];
  parsed
];
mqMaximumRegulatorDegree = Module[{
    value = Environment["FACET_MQ_MAX_REGULATOR_DEGREE"], parsed},
  If[! StringQ[value] || StringLength[value] === 0, Return[64]];
  parsed = Quiet[Check[ToExpression[value], $Failed]];
  If[! IntegerQ[parsed] || ! Between[parsed, {1, 256}],
    Print["[sector-epsform] FACET_MQ_MAX_REGULATOR_DEGREE must be an " <>
      "integer from 1 through 256"];
    Exit[64]];
  parsed
];
mqRegulatorReconstructionValues = DeleteDuplicates[Join[
  FeynFacet`Private`$multiquadraticOffDiagonalBlockRegulatorScheduleDefault,
  Range[1, mqMaximumRegulatorDegree + 4]]];
(* Fixed-core and plan-discovery backends are intentionally distinct.
   The caps are explicit; the pool-owned live grants choose the effective
   values at each strip boundary. *)
finiteFieldBackend = Automatic;
finiteFieldBackendThreadCap = 8;
finiteFieldBackendThreads = FeynFacet`Private`taskBrokerNativeThreadLimit[
  finiteFieldBackendThreadCap];
(* Prefer the native affine RREF whenever this installation has built it.
   It returns the complete pilot solution and plan in one pass; the solver
   verifies that answer on every original modular row.  A clone without the
   optional adapter retains the Wolfram route. *)
planDiscoveryBackend = If[
  FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRBinary[] === None,
  "Wolfram", "FLINTAffineRREF"];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
start = AbsoluteTime[];
log[a___] := Print["[sector-epsform ", family, " +", ToString[Round[AbsoluteTime[] - start]], "s] ", StringJoin[ToString[#, InputForm] & /@ {a}]];
refreshResourceAllocation[] := Module[{nextFinite, nextMQ},
  nextFinite = FeynFacet`Private`taskBrokerNativeThreadLimit[
    finiteFieldBackendThreadCap];
  nextMQ = FeynFacet`Private`taskBrokerNativeThreadLimit[mqNativeThreadCap];
  If[{nextFinite, nextMQ} =!=
      {finiteFieldBackendThreads, mqNativeThreads},
    log["resource rebalance: active families ",
      FeynFacet`Private`taskBrokerActiveFamilyCount[],
      ", fixed-core native threads ", finiteFieldBackendThreads, " -> ",
      nextFinite, ", direct-MQ native threads ", mqNativeThreads, " -> ",
      nextMQ]];
  finiteFieldBackendThreads = nextFinite;
  mqNativeThreads = nextMQ;
];
log["worker-kernel limit ", kernelCount];
log["direct-MQ native thread count ", mqNativeThreads];
log["direct-MQ follower image concurrency ", mqImageKernelCount];
ownedKernels = {};
If[kernelCount > 1 && Length[Kernels[]] < kernelCount,
  ownedKernels = Quiet[
    LaunchKernels[kernelCount - Length[Kernels[]]]]];
If[Length[Kernels[]] < kernelCount,
  log["available worker kernels ", Length[Kernels[]]]];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
(* Every live input is a V2 artifact.  Parse it through the package's
   context-guarded reader; a raw Get after CANONICA/FeynCalc have populated
   $ContextPath can bind the same printed variable name to another context.
   The former whole-expression symbol-normalization walk both duplicated
   this reader and could turn a valid V2 system into $Failed. *)
readArtifact[file_String] := FeynFacet`FamilyArtifactRead[file];
artifactReference[file_String, dataType_String] := Module[
  {absolute = ExpandFileName[file], rootParts, fileParts, pathField},
  rootParts = FileNameSplit[root];
  fileParts = FileNameSplit[absolute];
  pathField = If[Length[fileParts] >= Length[rootParts] &&
      Take[fileParts, Length[rootParts]] === rootParts,
    <|"RelativePath" -> FileNameJoin[Drop[fileParts, Length[rootParts]]]|>,
    <|"ExplicitPath" -> absolute|>];
  Join[pathField, <|"DataType" -> dataType, "SchemaVersion" -> 2,
    "Family" -> family|>]
];
artifactReferencePath[reference_Association] := Module[
  {relative = Lookup[reference, "RelativePath", None],
   explicit = Lookup[reference, "ExplicitPath", None]},
  If[! Xor[StringQ[relative], StringQ[explicit]], Return[$Failed]];
  ExpandFileName[If[StringQ[relative], FileNameJoin[{root, relative}], explicit]]
];
toC[e_] := e /. ee -> CANONICA`eps; fromC[e_] := e /. CANONICA`eps -> ee;
requiredInputFiles = {familyDifferentialSystemFile, blockDecompositionFile,
  coefficientPresentationFile};
missingInputFiles = Select[requiredInputFiles, ! FileExistsQ[#] &];
If[missingInputFiles =!= {},
  log["!! required V2 input files do not exist: ", missingInputFiles];
  Exit[66]];
If[! DirectoryQ[diagonalBlockFormsDirectory],
  log["!! diagonal-block dlog epsilon-form directory does not exist: ",
    diagonalBlockFormsDirectory];
  Exit[66]];

differentialSystem = readArtifact[familyDifferentialSystemFile];
system = FeynFacetCampaign`FamilyDifferentialSystemWorkingViewV2[
  differentialSystem];
If[Lookup[system, "Status", None] =!=
    "FamilyDifferentialSystemWorkingViewConstructed",
  log["!! V2 family differential system refused: ", system];
  Exit[2]];
{vv, ww} = differentialSystem["KinematicVariables"];
ee = system["Regulator"];
If[differentialSystem["Family"] =!= family,
  log["!! family differential-system mismatch: requested ", family,
    ", artifact contains ", differentialSystem["Family"]];
  Exit[2]];
systemReference = artifactReference[familyDifferentialSystemFile,
  "FamilyDifferentialSystem"];

blockDecomposition = readArtifact[blockDecompositionFile];
If[! AssociationQ[blockDecomposition] ||
    Lookup[blockDecomposition, "DataType", None] =!=
      "FamilyDifferentialSystemBlockDecomposition" ||
    Lookup[blockDecomposition, "SchemaVersion", None] =!= 2 ||
    Lookup[blockDecomposition, "Status", None] =!=
      "FamilyDifferentialSystemBlockDecompositionValidated",
  log["!! V2 block decomposition refused: ",
    If[AssociationQ[blockDecomposition],
      KeyTake[blockDecomposition, {"DataType", "SchemaVersion"}],
      Head[blockDecomposition]]];
  Exit[2]];
decompositionSystemReference = Lookup[blockDecomposition,
  "FamilyDifferentialSystemReference", <||>];
If[Lookup[decompositionSystemReference, "DataType", None] =!=
      "FamilyDifferentialSystem" ||
    Lookup[decompositionSystemReference, "SchemaVersion", None] =!= 2 ||
    Lookup[decompositionSystemReference, "Family", None] =!= family ||
    artifactReferencePath[decompositionSystemReference] =!=
      familyDifferentialSystemFile,
  log["!! block decomposition does not reference the supplied V2 family " <>
    "differential system"];
  Exit[2]];
If[! TrueQ[
    FeynFacet`FamilyDifferentialSystemBlockDecompositionQ[
      blockDecomposition, differentialSystem]],
  log["!! block decomposition failed re-evaluation against the supplied " <>
    "V2 family differential system"];
  Exit[2]];
decompositionBlocks = Lookup[blockDecomposition,
  "DiagonalBlocksInCurrentBasis", $Failed];
If[! ListQ[decompositionBlocks] || decompositionBlocks === {} ||
    ! AllTrue[decompositionBlocks, MatchQ[#, {__Integer}] &] ||
    Sort[Flatten[decompositionBlocks]] =!=
      Range[Length[differentialSystem["OriginalMasterIntegralBasis"]]],
  log["!! irreducible diagonal blocks do not partition the original " <>
    "master-integral basis"];
  Exit[2]];

coefficientPresentation = readArtifact[coefficientPresentationFile];
If[! AssociationQ[coefficientPresentation] ||
    Lookup[coefficientPresentation, "SchemaVersion", None] =!= 2 ||
    ! MemberQ[{"SourceVariableRepresentation",
        "RationalizingParametrization",
        "SquareRootGeneratorsAndQuadraticRelations"},
      Lookup[coefficientPresentation, "DataType", None]],
  log["!! V2 coefficient presentation is not well formed"];
  Exit[2]];

diagonalBlockFormFiles = Sort[FileNames["*.wl",
  diagonalBlockFormsDirectory]];
diagonalBlockForms = readArtifact /@ diagonalBlockFormFiles;
invalidDiagonalBlockForms = Select[diagonalBlockForms,
  ! (AssociationQ[#] && Lookup[#, "DataType", None] ===
        "DiagonalBlockDLogEpsilonForm" &&
      Lookup[#, "SchemaVersion", None] === 2 &&
      Lookup[#, "Status", None] === "DLogEpsilonFormValidated" &&
      MatchQ[Lookup[#, "BlockRows", None], {__Integer}]) &];
If[invalidDiagonalBlockForms =!= {},
  log["!! diagonal-block directory contains non-V2 or unvalidated records"];
  Exit[2]];
diagonalBlockFormRows = Lookup[diagonalBlockForms, "BlockRows", {}];
If[! DuplicateFreeQ[diagonalBlockFormRows] ||
    ! AllTrue[diagonalBlockFormRows,
      MemberQ[decompositionBlocks, #] &],
  log["!! diagonal-block dlog epsilon forms contain duplicate or unknown " <>
    "BlockRows"];
  Exit[2]];
missingNonScalarDiagonalBlockForms = Select[decompositionBlocks,
  Length[#] > 1 && ! MemberQ[diagonalBlockFormRows, #] &];
If[missingNonScalarDiagonalBlockForms =!= {},
  log["!! validated diagonal-block dlog epsilon forms are missing for rows ",
    missingNonScalarDiagonalBlockForms];
  Exit[2]];
blocks = Table[{rows,
    SelectFirst[diagonalBlockForms,
      Lookup[#, "BlockRows", None] === rows &, Automatic]},
  {rows, decompositionBlocks}];
constructionInputReferences = <|
  "FamilyDifferentialSystem" -> systemReference,
  "BlockDecomposition" -> artifactReference[blockDecompositionFile,
    "FamilyDifferentialSystemBlockDecomposition"],
  "CoefficientPresentation" -> artifactReference[
    coefficientPresentationFile, coefficientPresentation["DataType"]],
  "DiagonalBlockDLogEpsilonForms" -> MapThread[
    Join[artifactReference[#1, "DiagonalBlockDLogEpsilonForm"],
      <|"BlockRows" -> #2|>] &,
    {diagonalBlockFormFiles, diagonalBlockFormRows}]
|>;

scratch = FileNameJoin[{outdir,
  "family_dlog_epsilon_form_" <> family <> tag}];
If[! DirectoryQ[scratch], CreateDirectory[scratch]];
stateFile = FileNameJoin[{outdir,
  "FamilyDLogEpsilonFormConstructionState_" <> family <> tag <> ".wl"}];
(* State files are written by this driver in InputForm with the canonical
   Global` chart/regulator symbols.  Get already recreates unqualified symbols
   in Global`; walking an 80--210 MB cached connection a second time through
   normalizeSymbols made resume startup take minutes and changed nothing. *)
cachedState = If[FileExistsQ[stateFile], Get[stateFile],
  Missing["NotFound"]];
If[AssociationQ[cachedState] &&
    (Lookup[cachedState, "DataType", None] =!=
        "FamilyDLogEpsilonFormConstructionState" ||
      Lookup[cachedState, "SchemaVersion", None] =!= 2 ||
      ! SameQ[Lookup[cachedState, "ConstructionInputReferences",
          Missing[]], constructionInputReferences] ||
      ! AllTrue[{"Sector", "OriginalA", "Ranges", "Blocks",
          "CoefficientPresentation", "S", "SInverse", "A",
          "OffDiagonalBlockSolutions", "SectorCertificates", "TDiagonal",
          "TDiagonalInverse", "DiagonalAlphabets"},
        KeyExistsQ[cachedState, #] &]),
  log["existing construction state is not for the supplied V2 family " <>
    "differential system; starting fresh"];
  cachedState = Missing["ConstructionStateInputMismatch"]];

(* Assemble in the explicitly supplied V2 coefficient presentation; rename
   its coefficient variables to (x,y) only for the internal sector algebra. *)
chart = coefficientPresentation;
chart = FeynFacet`Private`masterTransportCoefficientPresentationData[
  chart, {vv, ww}];
If[Lookup[chart, "Status", None] =!= "OK",
  log["!! coefficient presentation validation failed: ", chart]; Exit[2]];
chartCertificate = <|
  "Method" -> "DirectSymbolicCoefficientPresentationValidation",
  "Passed" -> True,
  "JacobianDeterminant" -> chart["JacobianDeterminant"]|>;
algebraicFrameQ = Lookup[chart, "DataType", None] ===
  "SquareRootGeneratorsAndQuadraticRelations";
(* The blockwise row composition (blockEquation / applyRowBasisTransformation) and the
   per-sector regulator factorization are identities over any
   characteristic-zero coefficient field; gating them on a rational
   frame left multiquadratic families without regulator factorization
   and fed regulator-dependent residues into later rows (Codex package
   bug report 2026-08-22, CF300 (8,5)).  The finite-field-first route is
   therefore frame-independent; in a multiquadratic frame each strip is
   solved in the smallest rational chart of its own roots
   (SolveOffDiagonalBasisTransformationBlock) and the completed truncation is factored
   there as well (FactorFamilyRegulatorDependenceInCoefficientPresentation). *)
blockwiseRouteQ = offDiagonalBlockRoute === "FiniteFieldFirst";
(* Cooperative strip budget (2026-08-24).  Until today sectorBudget bound
   only the retired Maple/CANONICA routes; the
   finite-field and multiquadratic engines ran unbounded -- CF300 (12,9)
   and CF303 sector 17 each ran past two hours on the multiquadratic
   engine with no cutoff.  The engines now take an absolute "Deadline"
   and stop COOPERATIVELY at their own unit boundaries (never
   TimeConstrained: it does not bound task-broker helpers and has escaped
   in pool subkernels before).  The deadline is recomputed at the start of
   every sector as (this sector's start) + sectorBudget, so each sector
   gets the same wall allowance, and it is passed to every finite-field
   and multiquadratic strip solve of that sector.  On expiry the solver
   returns Status "BudgetExhausted" and the driver stops typed with
   exit 2; the per-prime artifacts already written stay valid for a
   resume, exactly as an interrupted mission's checkpoints do. *)
sectorDeadline = Infinity;
offDiagonalBlockBudgetExhaustedQ[s_] := AssociationQ[s] &&
  Lookup[s, "Status", None] === "BudgetExhausted";
(* STRIP CONSTRUCTION (2026-08-24, the same night, second gap).  The
   deadline above landed only INSIDE the solvers.  MEASURED in
   production: both campaign missions sat more than two hours in the
   work between the "strip {i,j}" announcement and the first solver call
   -- CANONICA NextEquationD (or the blockwise block equation), the
   strip-input write, the zero-forcing probe, the solver-configuration
   seal, and then the chart pullback and identity preparation inside
   SolveOffDiagonalBasisTransformationBlock -- where no deadline was ever checked, so
   the 7200 s sector budget passed silently on both families.
   The construction stage now checks the SAME sectorDeadline at each
   substage boundary and produces the SAME typed shape a solver stop
   has, so the OffDiagonalBlockBudgetExhausted handling below is reused verbatim
   and there is no second stop path.  The substage wall times are
   carried in the stop so a future log shows WHERE the budget went.
   Never TimeConstrained: NextEquationD is a CANONICA call and a
   TimeConstrained step has escaped its bound in pool subkernels
   (CLAUDE.md); the opaque calls are BRACKETED (check before, check
   after, wall time recorded) instead. *)
offDiagonalBlockDeadlineExpiredQ[d_] := NumericQ[d] && AbsoluteTime[] >= d;
(* the driver-side construction stop, in the shape the solvers use *)
offDiagonalBlockConstructionStop[substage_String, start_, offDiagonalBlockPair_List,
    stageTimings_Association] := <|
  "Status" -> "BudgetExhausted",
  "Stage" -> "OffDiagonalBlockConstruction:" <> substage,
  "Substage" -> substage,
  "Elapsed" -> AbsoluteTime[] - start,
  "Deadline" -> sectorDeadline,
  "Method" -> "OffDiagonalBlockConstructionDriver",
  "Resumable" -> True,
  "OffDiagonalBlockPair" -> offDiagonalBlockPair,
  "ConstructionTimings" -> stageTimings|>;
coefficientPresentationForResume = chart;
If[AssociationQ[cachedState] &&
    ! SameQ[Lookup[cachedState, "CoefficientPresentation",
      Missing["NoCoefficientPresentation"]],
      coefficientPresentationForResume],
  log["cached sector state belongs to a different coefficient presentation; " <>
    "starting from the exact input system"];
  cachedState = Missing["CoefficientPresentationMismatch"]];
{c1, c2} = FeynFacet`Private`masterTransportPresentationVariables[chart];
toXY = {c1 -> xx, c2 -> yy}; fromXY = {xx -> c1, yy -> c2};
If[AssociationQ[cachedState] &&
    KeyExistsQ[cachedState, "OriginalA"] &&
    KeyExistsQ[cachedState, "Ranges"] &&
    KeyExistsQ[cachedState, "TDiagonal"],
  A0 = cachedState["OriginalA"];
  ranges = cachedState["Ranges"];
  (* The V2 construction state stores the assembly's authoritative order;
     states without it were rejected before entering this branch. *)
  assemblyBlocks = cachedState["Blocks"];
  assembly = <|"Apv" -> (A0[[1]] /. fromXY),
    "Apw" -> (A0[[2]] /. fromXY), "Ranges" -> ranges,
    "Blocks" -> assemblyBlocks|>;
  log["using cached original connection from exact sector ",
    cachedState["Sector"]],
  rec = FeynFacet`AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[system, chart,
    "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
    "Blocks" -> blocks,"OffDiagonalSimplification"->"PreserveProducts",
    "Verbose" -> True];
  If[! (AssociationQ[rec] &&
      KeyExistsQ[rec, "FamilyDifferentialSystem"]),
    log["!! assembly failed"]; Exit[1]];
  assembly = rec["FamilyDifferentialSystem"];
  A0 = {assembly["Apv"] /. toXY, assembly["Apw"] /. toXY};
  ranges = assembly["Ranges"]
];

Export["/tmp/feynfacet-stage1-20260906/CF259-explicit-product-assembly.wxf",rec,"WXF"];
Print["ASSEMBLY_COMPLETE ",$stage1Elapsed=AbsoluteTime[]-$stage1StartTime];
Exit[0];
