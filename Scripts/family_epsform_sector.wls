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
root = ParentDirectory[DirectoryName[driverFile]];
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
  "IrreducibleDiagonalBlocks", $Failed];
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
   there as well (FactorFamilyRegulatorDependenceInFrame). *)
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
    "Blocks" -> blocks,
    "Verbose" -> True];
  If[! (AssociationQ[rec] &&
      KeyExistsQ[rec, "FamilyDifferentialSystem"]),
    log["!! assembly failed"]; Exit[1]];
  assembly = rec["FamilyDifferentialSystem"];
  A0 = {assembly["Apv"] /. toXY, assembly["Apw"] /. toXY};
  ranges = assembly["Ranges"]
];
(* Diagonal-block composition: the record must store the ABSOLUTE
   transformation TTotal = diag(T_class) . S against the chart-pulled-
   back source connection, not the sector gauge S alone (records
   written before 2026-08-20 stored S only, and the family certifier
   necessarily failed their gauge identity). The diagonal layer exists
   only on the fresh-assembly path; it is cached in the state so
   resumed runs keep it. *)
freshDiagonal = Module[{forms = Lookup[assembly, "Forms", Missing[]],
    inverses = Lookup[assembly, "TInverse", Missing[]], dim, td, tdi,
    alphabets},
  dim = Length[A0[[1]]];
  If[! ListQ[forms] || ! ListQ[inverses] ||
      Length[forms] =!= Length[ranges] ||
      ! AllTrue[forms, MatrixQ[Lookup[#, "T", Missing[]]] &] ||
      ! AllTrue[inverses, MatrixQ],
    log["diagonal composition guard: formsList ", ListQ[forms],
      " inversesList ", ListQ[inverses],
      " lengthMatch ", ListQ[forms] && Length[forms] === Length[ranges],
      " formTHeads ", If[ListQ[forms],
        Tally[Head[Lookup[#, "T", Missing[]]] & /@ forms], "n/a"],
      " inverseHeads ", If[ListQ[inverses],
        Tally[Head /@ inverses], "n/a"]];
    Missing["DiagonalFormsUnavailable"],
    td = ConstantArray[0, {dim, dim}];
    tdi = ConstantArray[0, {dim, dim}];
    Do[
      td[[ranges[[i]], ranges[[i]]]] = forms[[i]]["T"] /. toXY;
      tdi[[ranges[[i]], ranges[[i]]]] = inverses[[i]] /. toXY,
      {i, Length[ranges]}];
    alphabets = DeleteDuplicates[Flatten[
      Lookup[forms, "Alphabet", {}]]];
    {td, tdi, alphabets}]
];
nSectors = Length[ranges]; nMasters = Length[A0[[1]]];
bounds = Table[{First[ranges[[i]]], Last[ranges[[i]]]}, {i, nSectors}];
invariants = {xx, yy};
workingCoefficientPresentation = If[algebraicFrameQ,
  FeynFacet`Private`rekeyCoefficientPresentation[
    chart, invariants, invariants], chart];
If[algebraicFrameQ &&
    Lookup[workingCoefficientPresentation, "Status", None] =!=
      "SquareRootGeneratorRelationsVerified",
  log["!! could not re-key the square-root coefficient presentation " <>
    "to the internal variables: ", workingCoefficientPresentation];
  Exit[2]];
log["assembled ", nMasters, "x", nMasters, ", ", nSectors,
  " sectors in ", Lookup[chart, "Name", chart["DataType"]], " ",
  {c1, c2}, " -> ", {xx, yy}];
(* rational entries: Together is a canonical form, so Together === 0 is a
   complete zero test.  masterTransportZeroMatQ fell through to Simplify
   on every nonzero entry; on CF385 (44 masters) the per-sector block
   census then allocated 30 GB and took the WSL VM down twice (2026-08-22). *)
zeroQ[m_] := AllTrue[Flatten[{m}], TrueQ[Together[#] === 0] &];
epsFormQ[m_] := AllTrue[Flatten[m], TrueQ[Together[#] === 0] || FreeQ[Together[#/ee], ee] &];
badOffDiagonalBlocks[a_, upTo_] := Flatten[Table[If[i > j && ! zeroQ[a[[1, ranges[[i]], ranges[[j]]]]] &&
  ! (epsFormQ[a[[1, ranges[[i]], ranges[[j]]]]] && epsFormQ[a[[2, ranges[[i]], ranges[[j]]]]]), {i, j}, Nothing], {i, upTo}, {j, upTo}], 1];
monic[f_] := Module[{variables = Variables[f], variable, leading},
  If[variables === {}, Return[f]];
  variable = First[variables];
  leading = Coefficient[f, variable, Exponent[f, variable]];
  If[NumericQ[leading], Expand[f/leading], f]];
If[productionQ,
  log["initial whole-connection eps census deferred in Production"],
  log["initial: ", Length[badOffDiagonalBlocks[A0, nSectors]],
    " non-eps-factored strips"]];

(* ---- V2 construction state (resume) ---- *)
state = If[AssociationQ[cachedState], (log["resuming"]; cachedState),
  <|"DataType" -> "FamilyDLogEpsilonFormConstructionState",
    "SchemaVersion" -> 2,
    "ConstructionInputReferences" -> constructionInputReferences,
    "Sector" -> 1, "OriginalA" -> A0, "Ranges" -> ranges,
    "Blocks" -> assembly["Blocks"],
    "CoefficientPresentation" -> coefficientPresentationForResume,
    "S" -> IdentityMatrix[nMasters], "SInverse" -> IdentityMatrix[nMasters],
    "A" -> A0, "OffDiagonalBlockSolutions" -> {}, "SectorCertificates" -> {}|>];
If[! KeyExistsQ[state, "TDiagonal"] && ListQ[freshDiagonal],
  state["TDiagonal"] = freshDiagonal[[1]];
  state["TDiagonalInverse"] = freshDiagonal[[2]]];
If[! KeyExistsQ[state, "DiagonalAlphabets"] &&
    ListQ[freshDiagonal] && Length[freshDiagonal] >= 3,
  state["DiagonalAlphabets"] = freshDiagonal[[3]]];
log["diagonal composition state: fresh ", Head[freshDiagonal],
  " attached ", KeyExistsQ[state, "TDiagonal"], "; alphabet letters ",
  Length[Lookup[state, "DiagonalAlphabets", {}]]];

(* ---- WHOLE-FAMILY DEADLINE: persisted, inherited, never refreshed --
   (2026-08-25, Codex 14:30 "whole-family deadline persistence")
   The epoch lives in the state file.  A first run under a declared
   family budget stamps it; every later run of the same state INHERITS
   it, so the remaining budget is what is left of the original
   allowance.  A declared budget that DIFFERS from the stamped one is a
   deliberate re-budget by the operator and restamps, which is recorded;
   a resume with no budget declared keeps the stamped epoch. *)
(* the POLICY is the package's (familyRowBasisTransformationFamilyDeadlineDecision):
   this driver only applies it and persists what it says to persist *)
familyDeadlineDecision = FeynFacet`Private`familyRowBasisTransformationFamilyDeadlineDecision[
  state, familyBudget, AbsoluteTime[]];
state = familyDeadlineDecision["State"];
familyDeadline = familyDeadlineDecision["Deadline"];
If[TrueQ[familyDeadlineDecision["Persist"]], putAtomic[state, stateFile]];
If[familyDeadline =!= Infinity,
  log["family budget ", familyDeadlineDecision["BudgetSeconds"],
    " s; family deadline ",
    DateString[familyDeadline, {"Hour", ":", "Minute", ":", "Second"}],
    " (", familyDeadlineDecision["Action"], ", ",
    Round[familyDeadline - AbsoluteTime[]], " s remaining)"]];
(* a resume that has already spent the family budget stops BEFORE it
   touches a sector: the state is already consistent on disk *)
If[familyDeadline =!= Infinity && AbsoluteTime[] >= familyDeadline,
  log["!! the family budget was already spent before this run started"];
  state["Stop"] = <|"Status" -> "FamilyBudgetExhausted",
    "Stage" -> "FamilyEntry", "Sector" -> Lookup[state, "Sector", 1],
    "FamilyDeadline" -> familyDeadline,
    "FamilyBudgetSeconds" -> Lookup[state, "FamilyBudgetSeconds", familyBudget],
    "Resumable" -> True|>;
  putAtomic[state, stateFile]; Exit[2]];

(* ---- STALE-STOP MIGRATION (2026-08-25, Codex 14:30) ---------------
   Before 2026-08-25 a successful regulator factorization did NOT clear
   the typed stop that had demanded it: the fix (Codex 0830 P1) records
   a "ResolvedStop" resolution inside the factorization record and drops
   the "Stop" key.  State files written BEFORE that fix can therefore
   carry a resolvable Stop whose factorization is already in
   "RegulatorFactorizations" -- an advertised terminal for work that is
   done.  Resuming such a state is safe only if the stale Stop is
   recognized as resolved, which is what this migration does, ONCE, at
   load:

     - the Stop's status must be one this driver itself resolves;
     - a factorization record for the SAME rows must exist;
     - that record must carry NO "ResolvedStop" field, i.e. it predates
       the fix (a record that already resolved something is not
       migrated a second time).

   Anything else is left exactly as found: a Stop with no matching
   factorization is a REAL terminal and is never cleared here. *)
staleStopMigration = FeynFacet`Private`familyRowBasisTransformationStaleStopMigration[state];
If[Lookup[staleStopMigration, "Status", None] === "Migrated",
  state = staleStopMigration["State"];
  putAtomic[state, stateFile];
  log["migrated a pre-ResolvedStop state: the stale ",
    staleStopMigration["Migration"]["ClearedStatus"], " stop for rows ",
    staleStopMigration["Migration"]["Rows"],
    " is resolved by the factorization already recorded there"]];

offDiagonalBlockResiduesEpsFree[solution_Association] := Which[
  BooleanQ[Lookup[solution, "ResiduesEpsFree", Missing[]]],
    solution["ResiduesEpsFree"],
  AssociationQ[Lookup[solution, "InnerSolution", None]] &&
      BooleanQ[Lookup[solution["InnerSolution"], "ResiduesEpsFree",
        Missing[]]],
    solution["InnerSolution", "ResiduesEpsFree"],
  Lookup[solution, "Method", None] === "ZeroInhomogeneity", True,
  True, Missing["ResidueEpsilonDependenceNotReported"]
];

offDiagonalBlockSolverSummary[solution_Association, sector_Integer,
    lowerSector_Integer, extraLetters_List : {}] := Join[
  <|"Sector" -> sector, "LowerSector" -> lowerSector|>,
  KeyTake[solution, {"Method", "NumeratorDegree", "DenominatorDegree",
    "OffDiagonalBasisTransformationNumeratorDegrees", "OffDiagonalBasisTransformationDenominatorDegrees",
    "Primes", "ModularPrimeCount", "SelectedNumeratorDegreeOffset",
    "BackendRequested", "BackendThreads", "BackendsUsed",
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "PlanDiscoveryBackendThreads",
    "PrimeSamplingSeconds", "PrimeInterpolationSeconds",
    "TotalSamplingSeconds", "TotalInterpolationSeconds",
    "LiftingSeconds", "ExactCheckSeconds",
    "FirstVariable", "MapleSeconds", "ResiduePreparationSeconds",
    "ResidueKernels",
    "LetterDenominatorPower", "NumeratorDegreeOffset",
    "ExactDLog", "ODEEquationZero", "TransformedDLogZero",
    "Alphabet", "RootIndices", "FrameCertificate",
    "SolutionContract", "Certificate", "Provider",
    "OneFormsCertified", "LettersEpsFree", "ResiduesKinematicsFree",
    "InstallationEvidence", "PhaseSeconds"}],
  If[AssociationQ[Lookup[solution, "RegulatorReconstruction", None]],
    With[{reconstruction = solution["RegulatorReconstruction"]},
      <|"RegulatorReconstruction" -> Join[
        KeyTake[reconstruction,
          {"Status", "Method", "SamplePrimes", "GoodPrimes",
           "LearnedRegulatorSampleCount", "PrimeRegulatorImageCounts",
           "RegulatorScheduleGrowths", "LiftAttemptCount",
           "PrimeCountEstimate", "CombinedModulusBitLength",
           "CoefficientHeight", "CoefficientHeightBitLength",
           "RationalReconstructionMinimumPrimeCount",
           "ActualMinimumPrimeCount", "ActualPrimeCount",
           "PrimeCountOvershoot", "ActualMinimumPrimeCountBasis",
           "FreshProviderPointwiseCheckCount", "PhaseSeconds", "Seconds"}],
        <|"LiftAttemptHistory" ->
          (KeyDrop[#1, {"UnresolvedCoefficientLocations"}] & /@
            Lookup[reconstruction, "LiftAttemptHistory", {}])|>]|>],
    <||>],
  <|"ResiduesEpsFree" -> offDiagonalBlockResiduesEpsFree[solution],
    "ExtraLetters" -> extraLetters|>];

(* Regulator factorization of the completed rows 1..m (FiniteFieldFirst
   route, 2026-08-22): a completed block may be a dlog form whose residue
   carries the regulator, including an eps^0 part (recognized as
   "AlreadyDLog"); no rational gauge removes an eps^0 dlog term, and left
   in place it poisons the forcing of later rows through the intermediate
   products (CF265 (17,16) -> every probe of (18,16) inconsistent).  The
   former per-sector CANONICA TransformDlogToEpsForm absorbed it; now one
   constant T(eps) on sectors <= m (FactorFamilyRegulatorDependence on the
   truncated connection; block-triangularity is preserved, the unsampled
   symbolic identity is the acceptance test) does, before the next row is
   constructed. *)
(* the stale strip checkpoint of the sector this factorization runs in
   front of: it was built against the connection BEFORE the constant
   T(eps), so it must not survive a successful transformation (CF265
   sector 18, 2026-08-22).  Deleting it BEFORE the state write is the
   safe order -- a crash in between then loses the factorization and
   recomputes it, never resumes a new connection with an old strip. *)
staleOffDiagonalBlockCheckpointFile[m_] :=
  FileNameJoin[{scratch, family <> "_" <> ToString[m + 1] <> "_off_diagonal_block_state.wl"}];
(* the typed stops this routine itself sets for rows m; a successful
   factorization AT THE SAME ROWS resolves exactly these and nothing
   else (Codex 0830 P1: status AND rows must match) *)
$regulatorResolvableStops = {"NeedsMultiquadraticRegulatorFactorization",
  "RegulatorPropagationRejected"};
staleRegulatorStop[m_] := Module[{stop = Lookup[state, "Stop", Missing["NoStop"]]},
  If[AssociationQ[stop] &&
      MemberQ[$regulatorResolvableStops, Lookup[stop, "Status", None]] &&
      Lookup[stop, "Rows", None] === m,
    stop, Missing["NoMatchingStop"]]];
factorTruncated[m_] := Module[{nm = bounds[[m, 2]], aT, factor, tFull,
  tInv, futureAMode, propagation, staleStop, resolution,
  checkpointFile, rowSolvers, residueFlags, dependentCount, newS,
  newSInverse, propagationSeconds, sSeconds, sInverseSeconds, saveSeconds},
  If[productionQ,
    (* Every accepted strip already computed this structural statement
       from its reconstructed residue matrices.  Consuming it here avoids
       rediscovering the same fact by Together on the assembled prefix. *)
    rowSolvers = Select[Lookup[state, "OffDiagonalBlockSolutions", {}],
      Lookup[#, "Sector", None] === m &];
    residueFlags = Lookup[rowSolvers, "ResiduesEpsFree",
      Missing["ResidueEpsilonDependenceNotReported"]];
    If[AnyTrue[residueFlags, MissingQ],
      log["  !! residue epsilon-dependence metadata is missing for rows ",
        m, "; refusing the redundant whole-connection fallback"];
      state["Stop"] = <|"Status" -> "MissingResidueEpsilonMetadata",
        "Rows" -> m,
        "LowerSectors" -> Lookup[
          Pick[rowSolvers, MissingQ /@ residueFlags], "LowerSector", {}],
        "Resumable" -> True|>;
      putAtomic[state, stateFile]; Exit[2]];
    dependentCount = Count[residueFlags, False];
    If[dependentCount === 0,
      log["  rows 1..", m,
        " need no regulator factorization (all row residues eps-free)"];
      Return[False]],
    aT = {state["A"][[1, 1 ;; nm, 1 ;; nm]],
      state["A"][[2, 1 ;; nm, 1 ;; nm]]};
    If[epsFormQ[aT[[1]]] && epsFormQ[aT[[2]]], Return[False]];
    dependentCount = Missing["DiagnosticExactPrecheck"]];
  If[! ValueQ[aT],
    aT = {state["A"][[1, 1 ;; nm, 1 ;; nm]],
      state["A"][[2, 1 ;; nm, 1 ;; nm]]}];
  log["  rows 1..", m,
    If[IntegerQ[dependentCount], " have " <> ToString[dependentCount] <>
      " strip(s) with", " have"],
    " regulator-dependent residues; FactorFamilyRegulatorDependence",
    If[algebraicFrameQ, "InFrame", ""], " on the ", nm, "x", nm, " truncation"];
  factor = If[algebraicFrameQ,
    FeynFacet`FactorFamilyRegulatorDependenceInFrame[aT, {xx, yy}, ee, workingCoefficientPresentation, "TimeLimit" -> Min[sectorBudget, 600], "Deadline" -> sectorDeadline, "InputResiduesEpsFree" -> False, "ValidationMode" -> If[productionQ, "DeferredToFamilyCertificate", "Exact"], "Verbose" -> True],
    FeynFacet`FactorFamilyRegulatorDependence[aT, {xx, yy}, ee, "TimeLimit" -> Min[sectorBudget, 600], "Deadline" -> sectorDeadline, "InputResiduesEpsFree" -> False, "ValidationMode" -> If[productionQ, "DeferredToFamilyCertificate", "Exact"], "Verbose" -> True]];
  If[AssociationQ[factor] &&
      factor["Status"] === "RegulatorFactorizationDeadlineExpired",
    (* a budget stop, not a mathematical verdict: resumable, and the
       connection was NOT transformed, so no checkpoint is stale *)
    log["  !! regulator factorization of rows 1..", m,
      " ran out of the sector budget at stage ",
      Lookup[factor, "Stage", None]];
    state["Stop"] = <|"Status" -> "RegulatorFactorizationBudgetExhausted",
      "Rows" -> m, "Stage" -> Lookup[factor, "Stage", None],
      "SectorBudget" -> sectorBudget, "Resumable" -> True,
      "Detail" -> KeyDrop[factor,
        {"Transformation", "Inverse", "Connection"}]|>;
    putAtomic[state, stateFile]; Exit[2]];
  If[AssociationQ[factor] && factor["Status"] === "NoRationalChart",
    (* typed stop: the roots of the completed truncation have no joint
       rational chart AND the graded-algebra route
       (FactorFamilyRegulatorDependenceMultiquadratic, 2026-08-25) refused
       as well; continuing would construct the next row from
       regulator-dependent residues (an intrinsically inconsistent strip
       problem, CF300 (8,5)).  The refusal is the honest terminal, and it
       carries the graded route's own diagnostics. *)
    log["  !! rows 1..", m, " need a multiquadratic regulator factorization (roots ", factor["RootIndices"],
      " have no joint rational chart); the graded-algebra route refused with ",
      Lookup[Lookup[factor, "MultiquadraticFactorization", <||>], "Status",
        Missing["NotAttempted"]],
      "; stopping before the next row"];
    state["Stop"] = <|"Status" -> "NeedsMultiquadraticRegulatorFactorization", "Rows" -> m,
      "RootIndices" -> factor["RootIndices"],
      "QuadraticRadicands" -> factor["QuadraticRadicands"],
      "MultiquadraticFactorization" ->
        Lookup[factor, "MultiquadraticFactorization", Missing["NotAttempted"]]|>;
    putAtomic[state, stateFile]; Exit[2]];
  If[! (AssociationQ[factor] && factor["Status"] === "OK"),
    log["  !! regulator factorization of rows 1..", m, " failed: ", If[AssociationQ[factor], factor["Status"], factor]];
    Return[False]];
  (* This is an execution choice, not checkpoint mathematics.  Production
     always keeps exact sums deferred; an old or partial statistics record
     must not reactivate characteristic-zero Together. *)
  futureAMode = If[productionQ, "Deferred", "Together"];
  {propagationSeconds, propagation} = AbsoluteTiming[
    FeynFacet`Private`familyRegulatorPropagateTruncation[
      state["A"], factor["Connection"], factor["Inverse"],
      factor["Transformation"], nm, {xx, yy},
      futureAMode, ! productionQ]];
  If[! AssociationQ[propagation] ||
      Lookup[propagation, "Status", None] =!= "OK",
    log["  !! regulator propagation of rows 1..", m,
      " rejected: ", propagation];
    state["Stop"] = <|"Status" -> "RegulatorPropagationRejected",
      "Rows" -> m, "Detail" -> propagation|>;
    putAtomic[state, stateFile]; Exit[2]];
  tFull = IdentityMatrix[nMasters]; tFull[[1 ;; nm, 1 ;; nm]] = factor["Transformation"];
  tInv = IdentityMatrix[nMasters]; tInv[[1 ;; nm, 1 ;; nm]] = factor["Inverse"];
  (* products with the constant T entry by entry over its nonzero pattern
     (the plain Dot + Together of the full 44x44 triple product took 30 GB
     on CF385 sector 32, 2026-08-22) *)
  (* Codex 0830 P1.  The typed stop that made this factorization
     necessary is RESOLVED the moment the propagation is accepted: it is
     cleared here (only when its status AND its rows match), the
     resolution is recorded in the factorization certificate, and the
     state is persisted BEFORE the next strip begins.  Before 2026-08-25
     the next persisted state still advertised the solved terminal, and
     an interruption anywhere between here and the post-sector write at
     the end of the sector loop lost the accepted factorization and
     repeated the whole grade decomposition on resume. *)
  staleStop = staleRegulatorStop[m];
  resolution = If[MissingQ[staleStop], Missing["NoStaleStop"],
    <|"ClearedStatus" -> staleStop["Status"], "Rows" -> m,
      "ResolvedBy" -> factor["Method"],
      "ResolvedAt" -> DateString[{"ISODateTime"}]|>];
  {sSeconds, newS} = AbsoluteTiming[If[productionQ,
    FeynFacet`Private`familyRegulatorSparseDotDeferred[
      state["S"], tFull, False],
    FeynFacet`Private`familyRegulatorSparseDot[
      state["S"], tFull, False]]];
  {sInverseSeconds, newSInverse} = AbsoluteTiming[If[productionQ,
    FeynFacet`Private`familyRegulatorSparseDotDeferred[
      tInv, state["SInverse"], True],
    FeynFacet`Private`familyRegulatorSparseDot[
      tInv, state["SInverse"], True]]];
  state = Join[state, <|
    "A" -> propagation["Connection"],
    "S" -> newS,
    "SInverse" -> newSInverse,
    "RegulatorFactorizations" -> Append[Lookup[state, "RegulatorFactorizations", {}],
      <|"Rows" -> m, "Method" -> factor["Method"], "Points" -> factor["Points"], "Seconds" -> factor["Seconds"],
        "Chart" -> Lookup[factor, "Chart", None],
        "RootIndices" -> Lookup[factor, "RootIndices", {}],
        "ResolvedStop" -> resolution,
        (* graded-algebra route only (2026-08-25): the evidence the
           recorded eps-factorization rests on *)
        "GradedRank" -> Lookup[factor, "Rank", Missing["NotGraded"]],
        "GradedRootFrame" -> Lookup[factor, "GradedRootFrame",
          Missing["NotGraded"]],
        "ActiveGrades" -> Lookup[factor, "ActiveGrades", Missing["NotGraded"]],
        "ExactEpsFactorization" -> Lookup[factor, "ExactEpsFactorization", Missing["NotGraded"]],
        "CompositionSpotCheck" -> Lookup[factor, "CompositionSpotCheck", Missing["NotGraded"]],
        "ModularCorroboration" -> Lookup[factor, "ModularCorroboration", Missing["NotGraded"]],
        "PropagationStatistics" -> propagation["Statistics"]|>]|>];
  If[! MissingQ[staleStop], state = KeyDrop[state, "Stop"]];
  checkpointFile = staleOffDiagonalBlockCheckpointFile[m];
  If[FileExistsQ[checkpointFile], DeleteFile[checkpointFile];
    log["  off-diagonal-block checkpoint of sector ", m + 1,
      " discarded (connection transformed)"]];
  saveSeconds = First[AbsoluteTiming[putAtomic[state, stateFile]]];
  If[! MissingQ[staleStop],
    log["  stale ", staleStop["Status"], " stop for rows ", m,
      " cleared and the resolution recorded"]];
  log["  regulator factorization of rows 1..", m, ": ", factor["Method"], ", ", factor["Points"], " points, ",
    Round[factor["Seconds"], 0.1], " s",
    If[AssociationQ[Lookup[factor, "ModularCorroboration", None]],
      ", graded rank " <> ToString[Lookup[factor, "Rank", "?"]] <>
        ", sign-sheet corroboration " <>
        ToString[Lookup[Lookup[factor, "ModularCorroboration", <||>], "Status", "?"]],
      ""],
    "; future A mode ", futureAMode,
    "; propagation/S/SInverse/save ",
    Round[#, 0.1] & /@ {propagationSeconds, sSeconds,
      sInverseSeconds, saveSeconds}, " s",
    If[productionQ, "; final acceptance is the family certificate",
      " -> eps-factored " <> ToString[
        epsFormQ[state["A"][[1, 1 ;; nm, 1 ;; nm]]] &&
          epsFormQ[state["A"][[2, 1 ;; nm, 1 ;; nm]]]]]];
  True];

(* synchronous memory trace (stdout is block-buffered when redirected):
   FACET_MEMTRACE=<file> *)
memtrace[tag_] := If[StringQ[Environment["FACET_MEMTRACE"]],
  Module[{str = OpenAppend[Environment["FACET_MEMTRACE"]]},
    WriteString[str, DateString["Time"], " ", tag, " inuse=", Round[MemoryInUse[]/10^6], "MB max=", Round[MaxMemoryUsed[]/10^6], "MB\n"]; Close[str]]];

(* Blockwise off-diagonal bookkeeping (2026-08-22; replaces CANONICA's
   NextEquationD / InsertDIntoIdentity / TransformDE in the finite-field
   route).  The row gauge of sector k is T = 1 + D with D confined to the
   rows of sector k and the columns of the lower sectors, so T^-1 = 1 - D
   and, since D A D = 0 and D dD = 0 for a block-lower-triangular A,
     A' = A + A D - D A - dD .
   Only rows >= start_k and columns < start_k change; the transformation
   accumulates as S' = S + S D, S'^-1 = S^-1 - D S^-1.  The equation of
   block (k, j) with the blocks D_{km}, j < m < k, already installed is
     dD_{kj} = eps (e D_{kj} - D_{kj} c) + inhomogeneity,
     inhomogeneity = A_{kj} - Sum_{j<m<k} D_{km} A_{mj},  e = A_kk/eps,  c = A_jj/eps.
   The former code inverted the full nMasters x nMasters gauge symbolically and
   Together'd nMasters^3 products: 30 GB on CF385 sector 31 (44 masters). *)
blockRows[m_] := ranges[[m]];
(* THE SOURCE of block (k, j).  Two routes, selected by
   FACET_CONSTRUCTION_ROUTE (default Deferred; Symbolic reverts):

   - blockEquationSymbolicInhomogeneity is the route production ran until
     2026-08-24.  It is one dense Dot per feeder and then Map[Together,
     ., {2}] over the whole block, i.e. one polynomial gcd per pair of
     terms per entry.  MEASURED: 536 s of silent wall time on the single
     block CF259 (21,18), and 2+ h between blocks of the 28x28 / 37x37
     truncations (two watchdog confirmations).

   - the DEFERRED route (FeynFacet/Private/EpsForm/Blocks/BlockEquationDeferred.wl,
     Codex Q5 points 1-4, 6 and 8) keeps a sparse tagged term DAG whose
     terms reference the source entries, never forms
     Together[Total[terms]], proves entries nonzero by a modular census,
     and materializes each touched entry over the per-factor maximum of
     already-factored operand denominators -- no gcd is computed to find
     the common denominator.

   A typed refusal from the deferred route (a broken block precondition or
   incompatible mathematical input) falls back to the symbolic route and says so; it
   never silently continues.  $blockConstructionRecord carries the
   census, the timings and the route actually used into this block's
   certificate. *)
$blockConstructionRecord = <||>;
blockEquationSymbolicInhomogeneity[k_, j_, solved_Association] := Module[
  {rk = blockRows[k], rj = blockRows[j], A = state["A"]},
  Table[Map[Together, A[[mu, rk, rj]] -
    Sum[solved[m] . A[[mu, blockRows[m], rj]],
      {m, Select[Keys[solved], j < # < k &]}], {2}], {mu, 2}]];
blockEquation[k_, j_, solved_Association] := Module[
  {rk = blockRows[k], rj = blockRows[j], A = state["A"], e, c, inhomogeneity,
   deferred, route, bundleRoots, zeroPlaceholder},
  e = Table[Map[Together[#/ee] &, A[[mu, rk, rk]], {2}], {mu, 2}];
  c = Table[Map[Together[#/ee] &, A[[mu, rj, rj]], {2}], {mu, 2}];
  route = FeynFacet`Private`blockEquationDeferredRoute[];
  $blockConstructionRecord = <|"Route" -> route|>;
  If[route === "Deferred",
    bundleRoots = If[TrueQ[algebraicFrameQ],
      FeynFacet`Private`coefficientPresentationSquareRootsInVariables[
        workingCoefficientPresentation, invariants], {}];
    deferred = If[TrueQ[algebraicFrameQ] && ListQ[bundleRoots],
      FeynFacet`Private`blockEquationDeferredInhomogeneity[
        A, ranges, k, j, solved, invariants, ee,
        "Output" -> "ChartOrPreparation",
        "BundleRoots" -> bundleRoots],
      FeynFacet`Private`blockEquationDeferredInhomogeneity[
        A, ranges, k, j, solved, invariants, ee]];
    If[AssociationQ[deferred] &&
        Lookup[deferred, "Status", None] === "PreparedChartDeferred",
      zeroPlaceholder = ConstantArray[0, deferred["Dimensions"]];
      $blockConstructionRecord = <|
        "Route" -> "DeferredChartPreparation",
        "DeferredPreparation" -> <|
          "Preparation" -> deferred["DeferredPreparation"],
          "CoefficientPresentation" -> deferred["CoefficientPresentation"],
          "SquareRootGeneratorIndices" ->
            deferred["SquareRootGeneratorIndices"],
          "ProjectionSquareRootGeneratorIndices" ->
            deferred["ProjectionSquareRootGeneratorIndices"]|>,
        "ChartDecision" -> deferred["ChartDecision"],
        "Census" -> deferred["Census"],
        "ZeroInhomogeneityCandidateQ" -> False|>;
      Return[{e, c, zeroPlaceholder}]];
    If[AssociationQ[deferred] &&
        Lookup[deferred, "Status", None] === "PreparedDirectDeferred",
      zeroPlaceholder = ConstantArray[0, deferred["Dimensions"]];
      $blockConstructionRecord = <|
        "Route" -> "DeferredDirectPreparation",
        "DeferredPreparation" -> <|
          "Preparation" -> deferred["DeferredPreparation"],
          "CoefficientPresentation" -> deferred["CoefficientPresentation"],
          "SquareRootGeneratorIndices" ->
            deferred["SquareRootGeneratorIndices"],
          "ProjectionSquareRootGeneratorIndices" ->
            deferred["ProjectionSquareRootGeneratorIndices"]|>,
        "ChartDecision" -> deferred["ChartDecision"],
        "Census" -> deferred["Census"],
        "ZeroInhomogeneityCandidateQ" -> False|>;
      Return[{e, c, zeroPlaceholder}]];
    If[AssociationQ[deferred] &&
        Lookup[deferred, "Status", None] === "PreparedDeferredBundle",
      (* ChartOrBundle returns a bundle only when the roots actually used by
         this strip have no joint rational chart.  Chartable strips bypass
         direct-provider compilation and arrive below already materialized. *)
      zeroPlaceholder = ConstantArray[0, deferred["Dimensions"]];
      $blockConstructionRecord = <|"Route" -> "DeferredBundle",
        "DeferredBundle" -> deferred,
        "Census" -> Lookup[deferred["Statistics"], "Census", <||>],
        "ZeroInhomogeneityCandidateQ" -> False,
        "BundleStatistics" -> KeyDrop[deferred["Statistics"], "Census"]|>;
      Return[{e, c, zeroPlaceholder}]];
    If[AssociationQ[deferred] && Lookup[deferred, "Status", None] === "OK",
      $blockConstructionRecord = Join[$blockConstructionRecord,
        KeyDrop[deferred, {"Inhomogeneity", "Status"}]];
      Return[{e, c, deferred["Inhomogeneity"]}]];
    log["  !! deferred construction refused (",
      If[AssociationQ[deferred],
        KeyTake[deferred, {"Status", "Reason", "BlockPair", "Feeders"}],
        deferred], "); using the symbolic construction"];
    $blockConstructionRecord = Join[$blockConstructionRecord,
      <|"Route" -> "SymbolicFallback",
        "Refusal" -> If[AssociationQ[deferred],
          KeyTake[deferred, {"Status", "Reason", "BlockPair"}],
          deferred]|>]];
  inhomogeneity = blockEquationSymbolicInhomogeneity[k, j, solved];
  {e, c, inhomogeneity}];
(* apply the completed row gauge of sector k to the state *)
applyRowBasisTransformation[k_, solved_Association, installedRow_: Automatic] := Module[
  {rk = blockRows[k], start = First[blockRows[k]], cols, Dk, result,
   futureAMode},
  cols = Range[1, start - 1];
  Dk = ConstantArray[0, {Length[rk], start - 1}];
  Do[Dk[[All, blockRows[m] ]] = solved[m], {m, Keys[solved]}];
  futureAMode = If[productionQ, "Deferred", "Together"];
  result = FeynFacet`Private`familyRowBasisTransformationApply[
    state["A"], state["S"], state["SInverse"], rk, Dk, {xx, yy},
    installedRow, futureAMode];
  If[! AssociationQ[result] || Lookup[result, "Status", None] =!= "OK",
    Return[result]];
  state = Join[state, <|"A" -> result["Connection"],
    "S" -> result["Transformation"], "SInverse" -> result["Inverse"]|>];
  result["Statistics"]];

(* ---- the sector loop ---- *)
Do[
 Module[{nk = bounds[[k, 2]], aTrunc, res, directSolved, dk, res2, rowBasisTransformation = <||>,
   dk2, sfull, sfullInverse, aPrevious, aNew, secs, remaining,
   stageInverse, stageBasisTransformationEquation, newS, newSInverse, sectorCertificate,
   rowBasisTransformationStatistics, installedRow = Automatic,
   offDiagonalBlockCheckpointFile = None, deferredBundle, deferredPreparation,
   directAlphabetOptions},
  log["==== sector ", k, " (rows ", bounds[[k]], ", truncation ", nk, "x", nk, ")"];
  (* recomputed at each sector start: this sector's strip solves must
     finish within sectorBudget seconds of the sector's own start AND
     within what is left of the whole-family budget (2026-08-25).  The
     family deadline is an absolute epoch persisted in the state file,
     so it does not restart with the driver. *)
  If[familyDeadline =!= Infinity && AbsoluteTime[] >= familyDeadline,
    log["  !! the whole-family budget is spent; stopping before sector ", k];
    state["Stop"] = <|"Status" -> "FamilyBudgetExhausted",
      "Stage" -> "SectorEntry", "Sector" -> k,
      "FamilyDeadline" -> familyDeadline,
      "FamilyBudgetSeconds" -> Lookup[state, "FamilyBudgetSeconds",
        familyBudget],
      "Resumable" -> True|>;
    putAtomic[state, stateFile]; Exit[2]];
  sectorDeadline = Min[AbsoluteTime[] + sectorBudget, familyDeadline];
  log["  strip budget ", sectorBudget, " s (deadline ",
    DateString[sectorDeadline, {"Hour", ":", "Minute", ":", "Second"}],
    If[familyDeadline =!= Infinity,
      ", family deadline " <> DateString[familyDeadline,
        {"Hour", ":", "Minute", ":", "Second"}] <> ", " <>
        ToString[Round[familyDeadline - AbsoluteTime[]]] <> " s of family budget left", ""], ")"];
  memtrace["sector " <> ToString[k] <> " start"];
  (* The previous row was factorized (or proved unnecessary from its
     residue metadata) before its sector state was committed.  Repeating
     that work here was a second whole-prefix precheck on every row. *)
  memtrace["sector " <> ToString[k] <> " after regulator-ready resume"];
  aTrunc = {state["A"][[1, 1 ;; nk, 1 ;; nk]],
    state["A"][[2, 1 ;; nk, 1 ;; nk]]};
  (* The production finite-field route works entirely with the V2
     regulator symbol.  Converting this connection to CANONICA`eps and then
     combining it with a Global`eps block transformation created a mixed
     two-regulator connection after the first row.  Only the retired/direct
     CANONICA branch needs its private regulator. *)
  If[! blockwiseRouteQ, aTrunc = toC[aTrunc]];
  memtrace["sector " <> ToString[k] <> " after toC"];
  Which[
   blockwiseRouteQ,
    secs = 0; res = {False, "FiniteFieldFirst"}; directSolved = False;
    log["  sector completion block by block (finite field; no CANONICA in the loop)",
      If[algebraicFrameQ, "; multiquadratic frame: each strip in the rational chart of its own roots", ""]],
   algebraicFrameQ,
    secs = 0; res = {False, "AlgebraicFrame"}; directSolved = False;
    log["  algebraic coefficient field: constructing individual strip equations"],
   offDiagonalBlockRoute === "FiniteFieldFirst",
    (* no CANONICA solver in the loop (user decision 2026-08-22): every
       off-diagonal block goes through the finite field *)
    secs = 0; res = {False, "FiniteFieldFirst"}; directSolved = False;
    log["  sector completion block by block (finite field; no CANONICA in the loop)"],
   True,
    {secs, res} = AbsoluteTiming[Quiet[TimeConstrained[
      CANONICA`TransformOffDiagonalBlock[
        invariants, bounds[[1 ;; k]], IdentityMatrix[nk], aTrunc,
        CANONICA`VerbosityLevel -> 0],
      directSectorBudget, {False, "TimedOut"}]]];
    directSolved = ListQ[res] && Length[res] >= 2 && First[res] =!= False;
    log["  complete-sector CANONICA: ", Round[secs, 0.1], " s",
      If[directSolved, " -> exact transformation found",
        " -> constructing individual strip equations"]]];

  If[! directSolved,
    Module[{aP = aTrunc, sb = bounds[[1 ;; k]],
      subSize = bounds[[k, 2]] - bounds[[k, 1]] + 1,
      prevD, nextEq, e, c, inhomogeneity, nlow, solution,
      offDiagonalBasisTransformationBlock, solvedBlocks,
      checkpointData, solvedForms, solvedForm,
      offDiagonalBlockSolutions = {}, transformation, offDiagonalBlockCheckpoint,
      checkpointValid, offDiagonalBlockInputFile, extraLetters, obstruction,
      zeroInhomogeneityQ,
      modularBranches, modularArtifact, modularSummary,
      constructionStart, constructionTimings, constructionSeconds,
      constructionCheck},
      offDiagonalBlockCheckpointFile = FileNameJoin[{scratch,
        family <> "_" <> ToString[k] <> "_off_diagonal_block_state.wl"}];
      offDiagonalBlockCheckpoint = If[FileExistsQ[offDiagonalBlockCheckpointFile],
        readArtifact[offDiagonalBlockCheckpointFile], Missing["NotFound"]];
      (* a checkpoint is valid only for the connection it was built on
         (the truncated regulator factorization changes it; CF265 sector
         18, 2026-08-22) *)
      checkpointValid = AssociationQ[offDiagonalBlockCheckpoint] &&
        (Lookup[offDiagonalBlockCheckpoint, "Family", Missing["LegacyCheckpoint"]] ===
            family ||
          MissingQ[Lookup[offDiagonalBlockCheckpoint, "Family",
            Missing["LegacyCheckpoint"]]] &&
          AllTrue[Lookup[offDiagonalBlockCheckpoint, "OffDiagonalBlockSolutions", {}],
            Function[summary, With[{inputFile = FileNameJoin[{scratch,
                family <> "_" <> ToString[k] <> "_" <>
                  ToString[Lookup[summary, "LowerSector", -1]] <>
                  "_input.wl"}]},
              FileExistsQ[inputFile] &&
                Lookup[readArtifact[inputFile], "Family", None] ===
                  family]]]) &&
        SameQ[Lookup[offDiagonalBlockCheckpoint, "TruncatedConnectionMatrices",
          Missing["NoConnectionMatrices"]], aP] &&
        Lookup[offDiagonalBlockCheckpoint, "Sector", Missing[]] === k &&
        Lookup[offDiagonalBlockCheckpoint, "SubSize", Missing[]] === subSize &&
        Lookup[offDiagonalBlockCheckpoint, "Truncation", Missing[]] === nk &&
        FeynFacet`Private`familyRowBasisTransformationCheckpointShapeQ[
          Lookup[offDiagonalBlockCheckpoint, "PrevD", None], subSize,
          Length /@ (blockRows /@ Range[k - 1])] &&
        FeynFacet`Private`familyRowBasisTransformationCheckpointOffDiagonalBlockSolutionsQ[
          Lookup[offDiagonalBlockCheckpoint, "OffDiagonalBlockSolutions", None],
          Lookup[offDiagonalBlockCheckpoint, "PrevD", None], k,
          Length /@ (blockRows /@ Range[k - 1])];
      If[AssociationQ[offDiagonalBlockCheckpoint] && ! checkpointValid,
        log["  strip checkpoint of sector ", k, " ignored (built on another connection)"]];
      If[checkpointValid,
        checkpointData = FeynFacet`Private`familyRowBasisTransformationDecodeCheckpoint[
          offDiagonalBlockCheckpoint, ee, CANONICA`eps];
        prevD = checkpointData["PrevD"];
        offDiagonalBlockSolutions = Lookup[offDiagonalBlockCheckpoint, "OffDiagonalBlockSolutions", {}];
        solvedForms = checkpointData["SolvedForms"];
        log["  resuming ", Length[offDiagonalBlockSolutions],
          " checked strips in sector ", k],
        prevD = Table[{}, {subSize}]; solvedForms = <||>];
      (* solved blocks of this row, j -> D_{kj}, recovered from the
         checkpoint's prevD (blocks are prepended: the first solved is
         j = k - 1) *)
      solvedBlocks = Module[{len = Length[prevD[[1]]], assoc = <||>, m = k - 1, col},
        col = len;
        While[col > 0 && m >= 1,
          assoc[m] = fromC[prevD][[All, col - Length[blockRows[m]] + 1 ;; col]];
          col -= Length[blockRows[m]]; m--];
        assoc];
      (* The checkpoint validator above is deliberately mathematical only:
         same family/sector/connection content, a complete block-boundary
         basis-transformation prefix, and one accepted strip record per
         banked block.  How a block was computed cannot invalidate that
         identity. *)
      If[checkpointValid && blockwiseRouteQ && Length[solvedBlocks] > 0,
        If[Sort[Keys[solvedForms]] =!= Sort[Keys[solvedBlocks]] ||
            ! AllTrue[Keys[solvedBlocks],
              Dimensions[Lookup[solvedForms, #, Missing["NoForm"]]] ===
                {2, subSize, Length[blockRows[#]]} &],
          solvedForms = <||>];
        installedRow = Automatic;
        log["  resume accepted ", Length[solvedBlocks],
          " banked strip(s) by mathematical checkpoint identity; " <>
          "execution settings ignored"]];
      (* one cooperative deadline check of the strip-CONSTRUCTION stage;
         it reads the CURRENT constructionStart / nlow /
         constructionTimings of the strip being built, and leaves the
         construction by Throw (Return inside a loop only terminates the
         loop -- documented Wolfram trap) *)
      constructionCheck[substage_String] :=
        If[offDiagonalBlockDeadlineExpiredQ[sectorDeadline],
          Throw[offDiagonalBlockConstructionStop[substage, constructionStart,
            {k, nlow}, constructionTimings], "OffDiagonalBlockConstructionBudget"]];
      While[Length[prevD[[1]]] + subSize =!= nk,
        (* ---- strip CONSTRUCTION stage, deadline-checked ---- *)
        solution = Catch[
        constructionStart = AbsoluteTime[];
        constructionTimings = <||>;
        (* hoisted out of the route branch below so the entry stop can
           name the strip it refused to start; the CANONICA route learns
           its lower sector only from NextEquationD *)
        nlow = k - 1 - Length[solvedBlocks];
        (* BOUNDARY: immediately before this strip's construction begins *)
        constructionCheck["Entry"];
          memtrace["block " <> ToString[{k, nlow}] <> " before equation"];
          (* the blockwise block equation is one Together pass over the
             connection blocks and the installed row products; bracketed
             like the CANONICA call below *)
          {constructionSeconds, {e, c, inhomogeneity}} = AbsoluteTiming[
            blockEquation[k, nlow, solvedBlocks]];
          constructionTimings["BlockEquation"] = constructionSeconds;
          memtrace["block " <> ToString[{k, nlow}] <> " after equation"];
          nextEq = True;
        (* BOUNDARY: after the block equation / NextEquationD *)
        constructionCheck["EquationConstructed"];
        offDiagonalBlockInputFile = FileNameJoin[{scratch,
          family <> "_" <> ToString[k] <> "_" <> ToString[nlow] <>
            "_input.wl"}];
        (* putAtomic returns the renamed path, so only the timing is taken *)
        constructionSeconds = First[AbsoluteTiming[putAtomic[
          Join[<|"Family" -> family, "Sector" -> k,
            "LowerSector" -> nlow, "Variables" -> invariants,
            "Regulator" -> ee,
            "OffDiagonalBlockEquation" -> {e, c, inhomogeneity}|>,
            If[AssociationQ[Lookup[$blockConstructionRecord,
                "DeferredBundle", None]],
              <|"DeferredBundle" ->
                $blockConstructionRecord["DeferredBundle"]|>, <||>],
            If[AssociationQ[Lookup[$blockConstructionRecord,
                "DeferredPreparation", None]],
              <|"DeferredPreparation" ->
                $blockConstructionRecord["DeferredPreparation"]|>, <||>]],
          offDiagonalBlockInputFile]]];
        constructionTimings["OffDiagonalBlockInputWrite"] = constructionSeconds;
        If[Environment["FACET_RECORD_STRIP_ONLY"] === "True",
          log["  recorded strip ", {k, nlow}, " at ", offDiagonalBlockInputFile];
          putAtomic[state, stateFile];
          Exit[75]
        ];
        (* the construction route and what it cost, per block: the 536 s
           this stage spent on CF259 (21,18) was invisible in the log *)
        log["  construction ", Lookup[$blockConstructionRecord, "Route", "Symbolic"],
          ": ", Round[Total[Values[KeyTake[constructionTimings,
            {"BlockEquation", "NextEquationD", "OffDiagonalBlockInputWrite"}]]], 0.1],
          " s", If[KeyExistsQ[$blockConstructionRecord, "Census"],
            StringJoin[", census ",
              ToString[Lookup[$blockConstructionRecord["Census"],
                "Status", None]], " (",
              ToString[Lookup[$blockConstructionRecord["Census"],
                "AcceptedSamples", 0]], " accepted), zero-forcing candidate ",
              ToString[Lookup[$blockConstructionRecord,
                "ZeroInhomogeneityCandidateQ", True]], ", ",
              ToString[Lookup[Lookup[$blockConstructionRecord,
                "Materialization", <||>], "AlgebraicEntries", 0]],
              " algebraic entries"], ""],
          (* WHERE the materialization time goes (2026-08-25): the
             deferred route already measures its own substages, and they
             were the one number the morning cost analysis of the
             algebraic strips did not have.  Measured that night: the
             construction cost on ALGEBRAIC entries spans 2.4 s to
             2919 s and is predicted by neither the entry count (4
             entries cost 2.4 s and 846.9 s on different strips) nor the
             materialized size (1.7 MB cost 2919 s, 7.4 MB cost 1916 s),
             so the substage split is the only usable predictor. *)
          Module[{statistics = Lookup[Lookup[$blockConstructionRecord,
              "Materialization", <||>], "Statistics", <||>]},
            If[statistics === <||>, "",
              StringJoin[", materialization ",
                ToString[Lookup[statistics, "InternedOperands", 0]],
                " interned operands, intern ",
                ToString[Round[Lookup[statistics, "InternSeconds", 0.], 0.1]],
                " s, expand ",
                ToString[Round[Lookup[statistics, "ExpandSeconds", 0.], 0.1]],
                " s, cancel ",
                ToString[Round[Lookup[statistics, "CancelSeconds", 0.], 0.1]],
                " s, algebraic canonicalize ",
                ToString[Round[Lookup[statistics,
                  "AlgebraicCanonicalizeSeconds", 0.], 0.1]],
                " s, total ",
                ToString[Round[Lookup[statistics,
                  "MaterializeSeconds", 0.], 0.1]], " s"]]]];
        log["  strip ", {k, nlow}, ": ", If[algebraicFrameQ,
          "finite field in the rational chart of the strip's roots",
          "finite field"]];
        (* BOUNDARY: after the strip input is on disk (a resume of this
           sector reloads it) *)
        constructionCheck["OffDiagonalBlockInputWritten"];
        None,
        "OffDiagonalBlockConstructionBudget"];
        extraLetters = {};
        finiteFieldSolve[] := FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[
          <|"Family" -> family, "Sector" -> k,
            "LowerSector" -> nlow, "Variables" -> invariants,
            "Regulator" -> ee,
            "OffDiagonalBlockEquation" -> {e, c, inhomogeneity},
            "ExtraLetters" -> extraLetters|>,
          "KernelCount" -> kernelCount,
          "ArtifactDirectory" -> FileNameJoin[{scratch,
            "finite_field_" <> ToString[k] <> "_" <> ToString[nlow]}],
          "ArtifactPrefix" -> family <> "_" <> ToString[k] <> "_" <> ToString[nlow],
          "Backend" -> finiteFieldBackend,
          "BackendThreads" -> finiteFieldBackendThreads,
          "PlanDiscoveryBackend" -> planDiscoveryBackend,
          "FinalCheck" -> If[productionQ, "Numerical", "Exact"],
          "Deadline" -> sectorDeadline,
          "Verbose" -> True];
        solvedQ[s_] := AssociationQ[s] && Lookup[s, "Status", None] === "Solved" &&
          (TrueQ[Lookup[s, "ExactDLog", False]] ||
            (productionQ && MemberQ[{"NumericalResidual", "ModularResidual"}, Lookup[s, "Certificate", None]]));
        (* a construction stop short-circuits both solve routes: it is
           handled by the OffDiagonalBlockBudgetExhausted block below, unchanged *)
        If[blockwiseRouteQ && ! offDiagonalBlockBudgetExhaustedQ[solution],
          solution = Catch[
          (* BOUNDARY: the zero-forcing probe is one Together over every
             entry of the forcing -- on a wide block that is not cheap *)
          constructionCheck["ZeroInhomogeneityProbe"];
          (* no dlog recognition through CANONICA's checker: it hung for
             15 min at full CPU on 2x2 blocks of CF360/CF215 (2026-08-22);
             the finite-field solve finds the trivial gauge in seconds.
             A block whose forcing vanishes identically has the exact
             gauge D = 0 (dD = eps(eD - Dc) + inhomogeneity - eps K dlog with
             inhomogeneity = 0): no sampling (CF408: ~250 of 340 blocks, ~0.7 s
             each through the three-prime machinery, 2026-08-22) *)
          (* The deferred route's modular census has already PROVED
             whether some entry of this forcing is nonzero -- a single
             nonzero image over F_p is an exact proof of non-vanishing --
             so the Together pass over every entry is paid only when no
             image separated the forcing from zero, and on that branch
             the deferred materializer has already reduced the vanishing
             entries to literal 0.  The symbolic route keeps the
             unconditional exact probe. *)
          {constructionSeconds, zeroInhomogeneityQ} = AbsoluteTiming[
            Environment["FACET_ZERO_FORCING"] =!= "False" &&
              TrueQ[Lookup[$blockConstructionRecord,
                "ZeroInhomogeneityCandidateQ", True]] && zeroQ[inhomogeneity]];
          constructionTimings["ZeroInhomogeneityProbe"] = constructionSeconds;
          refreshResourceAllocation[];
          deferredBundle = Lookup[$blockConstructionRecord,
            "DeferredBundle", Missing["NoDeferredBundle"]];
          deferredPreparation = Lookup[$blockConstructionRecord,
            "DeferredPreparation", Automatic];
          (* seam fix (Codex 2026-08-31 notes 02/04): the raw
             chartless preparation gets its OWN conservative alphabet
             payload -- structural pre-cancellation divisor bound from
             the operand DAG, no bundle interning, no Maple -- so the
             native deferred evaluator is selectable with a justified
             nonempty ansatz.  An empty alphabet is not a shortcut. *)
          directAlphabetOptions = Which[
            AssociationQ[deferredBundle],
              FeynFacet`Private`familyRowBasisTransformationDirectAlphabetOptions[
                deferredBundle],
            AssociationQ[deferredPreparation],
              FeynFacet`Private`familyRowBasisTransformationDirectAlphabetOptions[
                deferredPreparation],
            True, Automatic];
          If[(AssociationQ[deferredBundle] ||
                AssociationQ[deferredPreparation]) &&
              directAlphabetOptions === $Failed,
            log["  !! deferred forcing has no valid direct alphabet payload " <>
              "for strip ", {k, nlow}];
            putAtomic[state, stateFile]; Exit[2]];
          (* BOUNDARY: the last driver-side check before any solver runs.
             Past it the deadline is enforced inside the solver, and
             inside SolveOffDiagonalBasisTransformationBlock's own construction stage,
             through the option plumbing below. *)
          constructionCheck["SolverDispatch"];
          Which[
            zeroInhomogeneityQ,
              <|"Status" -> "Solved", "Method" -> "ZeroInhomogeneity",
                "OffDiagonalBasisTransformationBlock" -> ConstantArray[0, Dimensions[First[inhomogeneity]]],
                "ExactDLog" -> True, "ResiduesEpsFree" -> True|>,
            algebraicFrameQ,
              FeynFacet`SolveOffDiagonalBasisTransformationBlock[
                {e, c, inhomogeneity}, invariants, ee,
                workingCoefficientPresentation,
                "FiniteFieldOptions" -> {
                  "KernelCount" -> kernelCount,
                  "FinalCheck" -> If[productionQ, "Numerical", "Exact"],
                  "Backend" -> finiteFieldBackend,
                  "BackendThreads" -> finiteFieldBackendThreads,
                  "PlanDiscoveryBackend" -> planDiscoveryBackend,
                  "Deadline" -> sectorDeadline,
                  "Verbose" -> True},
                (* the chartless dispatch to the direct multiquadratic
                   engine carries the same deadline *)
                "MultiquadraticOptions" -> Join[
                  {"Deadline" -> sectorDeadline,
                   "PlanDiscoveryBackend" -> Automatic,
                   "PlanDiscoveryBackendThreads" -> mqNativeThreads,
                   "RegulatorReconstructionImageKernelCount" ->
                     mqImageKernelCount,
                   "RegulatorReconstructionValues" ->
                     mqRegulatorReconstructionValues,
                   "ReconstructionMaximumTotalDegree" ->
                     mqMaximumRegulatorDegree,
                   "CheckpointDirectory" -> scratch,
                   "CheckpointTag" -> family <> "_" <> ToString[k] <>
                     "_" <> ToString[nlow]},
                  If[AssociationQ[deferredBundle],
                    Join[{"DeferredBundle" -> deferredBundle,
                      "DeferredPreparationFile" -> offDiagonalBlockInputFile},
                     Normal[directAlphabetOptions],
                     {
                     (* the raw strip carries only a shape placeholder for
                        Inhomogeneity on this route; screening and certification use
                        the preserved DAG's modular images instead *)
                     "IntegrabilityScreen" -> False,
                     "ScreenFirst" -> False, "OffDiagonalBasisTransformationBlockScreen" -> False}], {}],
                  (* seam fix (Codex 2026-08-31 notes 02/04): the RAW
                     preparation route gets the same native plumbing --
                     the input file naming the preserved DAG and the
                     conservative alphabet payload -- so direct dispatch
                     selects the native deferred evaluator instead of
                     ignoring a valid preparation; inhomogeneity is the same
                     zero-shape placeholder here, so the symbolic
                     screens are likewise deferred to modular images *)
                  If[AssociationQ[deferredPreparation] &&
                      ! AssociationQ[deferredBundle],
                    Join[{"DeferredPreparationFile" -> offDiagonalBlockInputFile},
                     Normal[directAlphabetOptions],
                     {"IntegrabilityScreen" -> False,
                      "ScreenFirst" -> False, "OffDiagonalBasisTransformationBlockScreen" -> False}],
                    {}]],
                (* and so does the STRIP-CONSTRUCTION stage inside this
                   call -- the chart pullback, the gauge pullback and the
                   source-frame identity check (2026-08-24) *)
                "BasisTransformationReexpressionMode" -> If[productionQ,
                  "FiniteFieldReconstruct", "Exact"],
                "DeferredPreparation" -> deferredPreparation,
                "Deadline" -> sectorDeadline,
                "ScratchDirectory" -> scratch,
                "Tag" -> family <> "_" <> ToString[k] <> "_" <> ToString[nlow],
                "Verbose" -> True],
            True, finiteFieldSolve[]],
          "OffDiagonalBlockConstructionBudget"];
          If[! solvedQ[solution] && ! offDiagonalBlockBudgetExhaustedQ[solution] &&
              algebraicFrameQ,
            log["    finite field found no gauge in frame: ",
              If[AssociationQ[solution], KeyTake[solution,
                {"Status", "RootIndices", "QuadraticRadicands", "Method",
                 "PassingBranchCount", "BranchCount"}], solution]]];
          (* An ALGEBRAIC frame has no rational-gauge obstruction series
             to compute -- AnalyzeOffDiagonalBlockEpsilonFormObstructions expands a rational
             ansatz -- so the guard below has always skipped it, and a
             failed algebraic strip was recorded with no certificate at
             all.  The multiquadratic engine now stops BEFORE prepare and
             compile with a typed AlphabetIntegrabilityObstruction: the
             residue-only integrability system is inconsistent with the
             alphabet it was given, which is a statement about the
             ALPHABET and not about the gauge ansatz.  That typed result
             is the certificate for this frame and is recorded through
             the existing ObstructionCertificate field (2026-08-24). *)
          If[! solvedQ[solution] && algebraicFrameQ && AssociationQ[solution] &&
              Lookup[solution, "Status", None] ===
                "AlphabetIntegrabilityObstruction",
            obstruction = KeyDrop[solution, {"Witness", "AcceptedPoints"}];
            log["    alphabet integrability obstruction: defect ",
              Lookup[solution, "Defect", None], " with ",
              Lookup[solution, "LetterCount", None], " letters, rank ",
              Lookup[solution, "Rank", None], "/",
              Lookup[solution, "AugmentedRank", None], " of ",
              Lookup[solution, "MatrixDimensions", None],
              "; no gauge exists with this alphabet"]];
          (* a budget stop is NOT "no gauge exists": the obstruction
             certificate (up to 900 s) and the repeat with extra letters
             would spend more time than the budget just refused *)
          If[! solvedQ[solution] && ! offDiagonalBlockBudgetExhaustedQ[solution] &&
              ! algebraicFrameQ,
            (* typed failure reason (AnalyzeOffDiagonalBlockEpsilonFormObstructions, 2026-08-22):
               a missing letter is supplied and the solve repeated once;
               a non-constant residue proves that no rational gauge
               exists with the present diagonal forms; no obstruction up
               to the order means an ansatz or budget limitation.  No
               CANONICA/Maple fallback (manual tools, user decision). *)
            obstruction = Quiet[TimeConstrained[FeynFacet`AnalyzeOffDiagonalBlockEpsilonFormObstructions[
              <|"Family" -> family, "Sector" -> k, "LowerSector" -> nlow,
                "Variables" -> invariants, "Regulator" -> ee,
                "OffDiagonalBlockEquation" -> {e, c, inhomogeneity}|>,
              "MaximumOrder" -> 4], 900, $Failed]];
            log["    finite field found no gauge; obstruction certificate: ",
              If[AssociationQ[obstruction], KeyTake[obstruction, {"Status", "Order", "MissingLetters", "Obstructions", "OffDiagonalBasisTransformationNumeratorDegrees"}], obstruction]];
            If[AssociationQ[obstruction] && obstruction["Status"] === "MissingLetters",
              extraLetters = obstruction["MissingLetters"];
              log["    repeating the finite-field solve with the missing letters ", extraLetters];
              solution = finiteFieldSolve[]]]];
        (* F2 (Design/GeneralityFixes2.md, 2026-08-23): SolveOffDiagonalBasisTransformationBlock
           InFrame now dispatches a chartless multiquadratic strip to the
           direct engine, whose terminal success status is
           "ModularConsistent".  That is a RECORDED candidate, never an
           installed epsilon form: the engine returns closed one-forms,
           not a certified dlog potential, so solvedQ is false for it by
           construction (Design/MultiquadraticPromotion.md section 3).
           The run stops typed here -- it must neither continue with an
           uninstalled strip nor claim the family. *)
        (* Cooperative strip budget (2026-08-24): the finite-field and
           multiquadratic engines stop themselves at a unit boundary when
           the sector deadline passes and return this typed result.  The
           run stops here exactly as the NeedsMultiquadraticRegulator
           Factorization stop above does: typed log line, atomic state
           write, exit 2.  Everything the solver completed before the
           stop -- per-prime modular artifacts, the strip checkpoint of
           the blocks already installed -- is on disk and is picked up by
           the next run of this sector.
           SINCE 2026-08-24 (second gap) the STRIP-CONSTRUCTION stage --
           this driver's block equation / NextEquationD / strip-input
           write / zero-forcing probe, and SolveOffDiagonalBasisTransformationBlock's
           chart pullback, gauge pullback and source-frame identity
           check -- produces the SAME typed stop, and is handled here,
           unchanged, by the same branch: there is no second stop path.
           Its "Stage" reads "OffDiagonalBlockConstruction:<substage>" and its
           "ConstructionTimings" name the wall seconds of each substage
           reached, which is what the silent 7200 s overruns lacked. *)
        If[offDiagonalBlockBudgetExhaustedQ[solution],
          log["  !! strip ", {k, nlow}, " budget exhausted at stage ",
            Lookup[solution, "Stage", "Unknown"], " after ",
            Round[Lookup[solution, "Elapsed", 0.], 0.1], " s",
            " (sector budget ", sectorBudget, " s); partial progress ",
            KeyTake[solution, {"Prime", "PrimesCompleted", "SamplesDone",
              "SupportSize", "RegulatorValue", "UnknownCount",
              "ConstructionTimings"}]];
          state["Stop"] = <|"Status" -> "OffDiagonalBlockBudgetExhausted",
            "OffDiagonalBlockPair" -> {k, nlow},
            "Stage" -> Lookup[solution, "Stage", "Unknown"],
            "Elapsed" -> Lookup[solution, "Elapsed", Missing["NotReported"]],
            "SectorBudget" -> sectorBudget,
            "Method" -> Lookup[solution, "Method", None],
            "Resumable" -> TrueQ[Lookup[solution, "Resumable", False]],
            (* KeyTake omits absent keys, so a solver stop is recorded
               exactly as before and a construction stop adds its own *)
            "Progress" -> KeyTake[solution,
              {"Prime", "PrimesCompleted", "PrimesUsed", "PrimesDone",
               "SamplesDone", "SupportSize", "SelectedNumeratorDegreeOffset",
               "SelectedSupportShell", "ProbeCount", "RegulatorValue",
               "UnknownCount", "RootCount", "BrokerActive",
               "Substage", "ConstructionTimings", "RootIndices",
               "QuadraticRadicands", "RationalizingParametrizationName",
               "OffDiagonalBlockDimensions", "InnerStatus"}],
            "OffDiagonalBlockCheckpointFile" -> offDiagonalBlockCheckpointFile|>;
          putAtomic[state, stateFile]; Exit[2]];
        If[AssociationQ[solution] &&
            Lookup[solution, "Status", None] === "ModularConsistent",
          modularBranches = Lookup[solution, "BranchCertificate", {}];
          modularArtifact = FileNameJoin[{scratch,
            family <> "_" <> ToString[k] <> "_" <> ToString[nlow] <>
              "_modular.wl"}];
          modularSummary = Join[
            <|"Sector" -> k, "LowerSector" -> nlow,
              "Method" -> "MultiquadraticModularCandidate",
              "Status" -> "ModularConsistent",
              "SolutionContract" -> Lookup[solution, "SolutionContract",
                "OneFormsNotCertified"],
              "Installed" -> False,
              "RootCount" -> Lookup[solution, "RootCount", None],
              "GradeCount" -> Lookup[solution, "GradeCount", None],
              "ModularRank" -> Lookup[solution, "Rank", None],
              "Nullity" -> Lookup[solution, "Nullity", None],
              "BranchCount" -> Length[modularBranches],
              "BranchResidualZero" -> (TrueQ[Lookup[#, "ResidualZero", False]] & /@
                modularBranches),
              "AllBranchesResidualZero" -> (modularBranches =!= {} &&
                AllTrue[modularBranches,
                  TrueQ[Lookup[#, "ResidualZero", False]] &]),
              "Artifact" -> modularArtifact|>,
            KeyTake[solution, {"RootIndices", "QuadraticRadicands", "Dimensions",
              "UnknownCount", "EquationsPerPoint", "PreparationSchema",
              "SamplePrimes", "RegulatorValues",
              "HeldOutPrime", "HeldOutRegulatorValue", "ExactLift",
              "ExactChannelResidual", "RootFreeFastPathCount", "Seconds"}]];
          putAtomic[
            <|"Family" -> family, "Sector" -> k, "LowerSector" -> nlow,
              "Variables" -> invariants, "Regulator" -> ee,
              "OffDiagonalBlockEquation" -> {e, c, inhomogeneity},
              "OffDiagonalBlockInput" -> <|
                "CoefficientPresentation" -> coefficientPresentationForResume,
                "AlgebraicFrame" -> algebraicFrameQ,
                "Truncation" -> nk, "SubSize" -> subSize,
                "Dimensions" -> Dimensions[First[inhomogeneity]],
                "OffDiagonalBlockCheckpointFile" -> offDiagonalBlockCheckpointFile|>,
              "Summary" -> modularSummary,
              "Result" -> solution|>,
            modularArtifact];
          AppendTo[offDiagonalBlockSolutions, modularSummary];
          state["OffDiagonalBlockSolutions"] = Join[state["OffDiagonalBlockSolutions"], {modularSummary}];
          log["  !! strip ", {k, nlow}, " is a MODULAR CANDIDATE only: ",
            "multiquadratic engine, root rank ",
            Lookup[solution, "RootCount", None], ", ",
            Length[modularBranches], " sign branches (all residual zero: ",
            modularSummary["AllBranchesResidualZero"], "), contract ",
            modularSummary["SolutionContract"]];
          log["     recorded in ", modularArtifact,
            " and NOT installed: no certified dlog potential exists for it"];
          state["Stop"] = <|"Status" -> "ModularCandidateNotInstallable",
            "OffDiagonalBlockPair" -> {k, nlow}|>;
          putAtomic[state, stateFile]; Exit[2]];
        If[! solvedQ[solution],
          log["  !! no exact gauge for strip ", {k, nlow}];
          putAtomic[
            <|"Family" -> family, "Sector" -> k,
              "LowerSector" -> nlow, "Variables" -> invariants,
              "Regulator" -> ee,
              "OffDiagonalBlockEquation" -> {e, c, inhomogeneity},
              "SolverFailure" ->
                FeynFacet`Private`familyRowBasisTransformationSolverFailureSummary[
                  solution],
              "ObstructionCertificate" -> If[ValueQ[obstruction] && AssociationQ[obstruction],
                KeyDrop[obstruction, "OffDiagonalBasisTransformationBlockSeries"], Missing["NotRun"]]|>,
            FileNameJoin[{scratch,
              family <> "_" <> ToString[k] <> "_" <>
                ToString[nlow] <> "_unsolved.wl"}]];
          putAtomic[state, stateFile]; Exit[2]];
        offDiagonalBasisTransformationBlock =
          solution["OffDiagonalBasisTransformationBlock"];
        solvedForm = FeynFacet`Private`familyRowBasisTransformationDLogForm[
          solution, invariants, ee, Dimensions[First[inhomogeneity]]];
        If[ListQ[solvedForm], solvedForms[nlow] = solvedForm,
          log["    materialized dlog row form unavailable; row propagation " <>
            "will use the exact sparse formula"]];
        AppendTo[offDiagonalBlockSolutions,
          offDiagonalBlockSolverSummary[solution, k, nlow, extraLetters]];
        log["    ", solution["Method"],
          If[KeyExistsQ[solution, "NumeratorDegree"],
            " at numerator degree " <> ToString[solution["NumeratorDegree"]],
            ""]];
        prevD = MapIndexed[
          Join[toC[offDiagonalBasisTransformationBlock][[#2[[1]]]], #1] &,
          prevD];
        solvedBlocks[nlow] = offDiagonalBasisTransformationBlock;
        putAtomic[
          <|"Family" -> family, "Sector" -> k, "SubSize" -> subSize,
            "Truncation" -> nk, "PrevD" -> fromC[prevD],
            "TruncatedConnectionMatrices" -> aP,
            "OffDiagonalBlockSolutions" -> offDiagonalBlockSolutions,
            "SolvedForms" -> fromC[solvedForms]|>,
          offDiagonalBlockCheckpointFile];
      ];
      rowBasisTransformation = solvedBlocks;
      installedRow =
        FeynFacet`Private`familyRowBasisTransformationAssembleInstalledRow[
          aP, blockRows[k], fromC[prevD], invariants];
      transformation = None;
      (* CANONICA's TransformDE (the transformed truncated connection,
         fully symbolic) fed only the per-sector TransformDlogToEpsForm,
         which the finite-field-first route no longer runs; on CF385
         sector 31 (41x41) it allocated >36 GB and took the WSL VM down
         (2026-08-22).  The connection is transformed below blockwise. *)
      res = {None, None};
      state["OffDiagonalBlockSolutions"] = Join[state["OffDiagonalBlockSolutions"], offDiagonalBlockSolutions];
      log["  sector ", k, " row completed from ", Length[offDiagonalBlockSolutions],
        " individually checked strips"]];
  ];

  If[blockwiseRouteQ && ! directSolved,
    (* blockwise application of the completed row gauge (no inverse, no
       full-matrix products).  T = 1 + D with D confined to the rows of
       sector k and the columns of the lower sectors, so D.D = 0 and
       T^-1 = 1 - D exactly (structural); the gauge identity is the
       formula itself.  In Development the certificate is exact when
       every strip of the row was exactly checked; in Production the
       exact statement is the family certificate. *)
    Module[{t0 = AbsoluteTime[], exactOffDiagonalBlocks},
      rowBasisTransformationStatistics = applyRowBasisTransformation[k, rowBasisTransformation, installedRow];
      If[! AssociationQ[rowBasisTransformationStatistics] ||
          KeyExistsQ[rowBasisTransformationStatistics, "Status"],
        log["  !! row gauge of sector ", k, " rejected: ",
          rowBasisTransformationStatistics]; putAtomic[state, stateFile]; Exit[2]];
      log["  row gauge of sector ", k, " applied blockwise in ",
        Round[AbsoluteTime[] - t0, 0.1], " s; sparse products/touched A=",
        rowBasisTransformationStatistics["A", "Products"], "/",
        rowBasisTransformationStatistics["A", "Touched"], ", S=",
        rowBasisTransformationStatistics["S", "Products"], "/",
        rowBasisTransformationStatistics["S", "Touched"], ", SInverse=",
        rowBasisTransformationStatistics["SInverse", "Products"], "/",
        rowBasisTransformationStatistics["SInverse", "Touched"], ", normalization ",
        Round[Total[Lookup[#, "NormalizationSeconds", 0.] & /@
          Lookup[rowBasisTransformationStatistics, {"A", "S", "SInverse"}, {}]], 0.1],
        " s, literal single-term fast paths ",
        Total[Lookup[#, "SingleTermFastPath", 0] & /@
          Lookup[rowBasisTransformationStatistics, {"A", "S", "SInverse"}, {}]],
        ", dlog row entries installed ",
        Lookup[rowBasisTransformationStatistics["A"], "InstalledRowEntries", 0],
        ", future A mode ",
        Lookup[rowBasisTransformationStatistics["A"], "FutureAMode", "Together"],
        ", deferred future entries/touched ",
        Lookup[rowBasisTransformationStatistics["A"], "DeferredFutureEntries", 0], "/",
        Lookup[rowBasisTransformationStatistics["A"], "FutureTouched", 0]];
      exactOffDiagonalBlocks = AllTrue[Select[state["OffDiagonalBlockSolutions"], #["Sector"] === k &],
        TrueQ[Lookup[#, "ExactDLog", False]] &];
      stageInverse = If[productionQ, Missing["NotRunProduction"], True];
      stageBasisTransformationEquation = If[productionQ, Missing["NotRunProduction"], exactOffDiagonalBlocks]];
    sectorCertificate = <|"Sector" -> k, "TransformationInverse" -> stageInverse,
      "BasisTransformationEquation" -> stageBasisTransformationEquation, "Exact" -> ! productionQ && TrueQ[stageBasisTransformationEquation],
      "CheckLevel" -> checkLevel, "Route" -> "Blockwise",
      "RowBasisTransformationStatistics" -> rowBasisTransformationStatistics|>;
    state = Join[state, <|"Sector" -> k,
      "SectorCertificates" -> Append[state["SectorCertificates"], sectorCertificate]|>],
  dk = fromC[res[[1]]];
  If[offDiagonalBlockRoute === "FiniteFieldFirst",
    (* the regulator dependence of the residues is removed once for the
       whole family after the sector loop (FactorFamilyRegulatorDependence);
       the per-sector CANONICA TransformDlogToEpsForm burned its full
       1800 s budget on CF265 sector 16 for nothing (2026-08-22) *)
    dk2 = IdentityMatrix[nk],
    {secs, res2} = AbsoluteTiming[Quiet[TimeConstrained[CANONICA`TransformDlogToEpsForm[invariants, bounds[[1 ;; k]], IdentityMatrix[nk], res[[2]], CANONICA`VerbosityLevel -> 0], sectorBudget, {False, "TimedOut"}]]];
    log["  TransformDlogToEpsForm: ", Round[secs, 0.1], " s", If[res2[[1]] === False, " -> returned False (dlog step kept)", ""]];
    dk2 = If[res2[[1]] === False, IdentityMatrix[nk], fromC[res2[[1]]]]];
  sfull = IdentityMatrix[nMasters]; sfull[[1 ;; nk, 1 ;; nk]] = Together[dk . dk2];
  sfullInverse = Together[Inverse[sfull]];
  aPrevious = state["A"];
  aNew = Table[Map[Together,
    sfullInverse . aPrevious[[mu]] . sfull -
      sfullInverse . D[sfull, {xx, yy}[[mu]]], {2}], {mu, 2}];
  (* Development only: the inverse identity of the sector gauge.  (The
     former stageBasisTransformationEquation recomputed the expression that defines aNew and
     subtracted it -- vacuous by construction, two nMasters x nMasters Together passes
     per sector; removed 2026-08-22.) *)
  stageInverse = If[productionQ, Missing["NotRunProduction"],
    zeroQ[
      sfull[[1 ;; nk, 1 ;; nk]] .
        sfullInverse[[1 ;; nk, 1 ;; nk]] - IdentityMatrix[nk]] &&
    zeroQ[sfullInverse[[1 ;; nk, 1 ;; nk]] .
        sfull[[1 ;; nk, 1 ;; nk]] - IdentityMatrix[nk]]];
  stageBasisTransformationEquation = If[productionQ, Missing["NotRunProduction"], True];
  If[! productionQ && ! TrueQ[stageInverse],
    log["!! exact sector transformation identity failed at sector ", k];
    Exit[1]];
  newS = Together[state["S"] . sfull];
  newSInverse = Together[sfullInverse . state["SInverse"]];
  sectorCertificate = <|"Sector" -> k,
    "TransformationInverse" -> stageInverse,
    "BasisTransformationEquation" -> stageBasisTransformationEquation, "Exact" -> ! productionQ,
    "CheckLevel" -> checkLevel|>;
  state = Join[
    KeyTake[state, {"OriginalA", "Ranges", "Blocks", "OriginalAReconstruction",
      "CoefficientPresentation", "TDiagonal", "TDiagonalInverse",
      "RegulatorFactorizations", "RegulatorFactorization"}],
    <|"Sector" -> k, "S" -> newS, "SInverse" -> newSInverse,
      "A" -> aNew, "OffDiagonalBlockSolutions" -> state["OffDiagonalBlockSolutions"],
      "SectorCertificates" ->
        Append[state["SectorCertificates"], sectorCertificate]|>
  ]];
  memtrace["sector " <> ToString[k] <> " before factorTruncated"];
  If[blockwiseRouteQ, factorTruncated[k]];
  memtrace["sector " <> ToString[k] <> " after factorTruncated"];
  putAtomic[state, stateFile];
  memtrace["sector " <> ToString[k] <> " after state write"];
  If[StringQ[offDiagonalBlockCheckpointFile] && FileExistsQ[offDiagonalBlockCheckpointFile],
    DeleteFile[offDiagonalBlockCheckpointFile]];
  If[productionQ && AssociationQ[rowBasisTransformationStatistics] &&
      Lookup[Lookup[rowBasisTransformationStatistics, "A", <||>], "FutureAMode",
        "Together"] === "Deferred",
    remaining = Missing["DeferredProductionCensus"];
    memtrace["sector " <> ToString[k] <> " full badOffDiagonalBlocks census deferred"];
    log["  sector ", k, " done; full non-eps-factored strip census " <>
      "deferred in Production; acceptance remains the whole-family certificate"],
    remaining = Length[badOffDiagonalBlocks[state["A"], nSectors]];
    memtrace["sector " <> ToString[k] <> " after badOffDiagonalBlocks"];
    log["  sector ", k,
      " done; non-eps-factored strips remaining (all sectors): ", remaining]]],
 {k, Max[2, state["Sector"] + 1], nSectors}];

(* ---- family-level exact checks (in chart variables) ---- *)
S = state["S"] /. fromXY;
Sinv = state["SInverse"] /. fromXY;
Ap = {state["A"][[1]] /. fromXY, state["A"][[2]] /. fromXY};
Aorig = {assembly["Apv"], assembly["Apw"]};
allEps = If[productionQ, Missing["DeferredToFamilyCertificate"],
  epsFormQ[Ap[[1]]] && epsFormQ[Ap[[2]]]];
sectorCertificatesExact =
  Length[state["SectorCertificates"]] === Max[0, nSectors - 1] &&
  AllTrue[state["SectorCertificates"],
    TrueQ[Lookup[#, "TransformationInverse", False]] &&
      TrueQ[Lookup[#, "BasisTransformationEquation", False]] &];
If[productionQ,
  (* Production: no exact identities here; ValidateFamilyDLogEpsilonForm is the
     single exact test (driver runs it next).  Only the cheap structural
     statement is made. *)
  finalInverse = Missing["DeferredToFamilyCertificate"];
  basisTransformationEquation = Missing["DeferredToFamilyCertificate"];
  flatness = Missing["DeferredToFamilyCertificate"];
  basisTransformationEquationRoute = "DeferredToFamilyCertificate";
  flatnessRoute = "DeferredToFamilyCertificate",
 If[algebraicFrameQ,
  finalInverse = sectorCertificatesExact;
  basisTransformationEquation = sectorCertificatesExact;
  flatness = basisTransformationEquation && finalInverse &&
    TrueQ[assembly["Certificate"]["FlatnessOriginal"]];
  basisTransformationEquationRoute =
    "CompositionOfExactSectorBasisTransformationEquations";
  flatnessRoute =
    "FlatnessPreservedByVerifiedConnectionBasisTransformation",
  finalInverse = zeroQ[S . Sinv - IdentityMatrix[nMasters]] &&
    zeroQ[Sinv . S - IdentityMatrix[nMasters]];
  basisTransformationEquation = zeroQ[Map[Together,
      Sinv . Aorig[[1]] . S - Sinv . D[S, c1] - Ap[[1]], {2}]] &&
    zeroQ[Map[Together,
      Sinv . Aorig[[2]] . S - Sinv . D[S, c2] - Ap[[2]], {2}]];
  flatness = zeroQ[Map[Together,
    D[Ap[[2]], c1] - D[Ap[[1]], c2] +
      Ap[[1]] . Ap[[2]] - Ap[[2]] . Ap[[1]], {2}]];
  basisTransformationEquationRoute = "DirectFullMatrixIdentity";
  flatnessRoute = "DirectFullMatrixCurvature"
]];
log["FAMILY: A'/eps eps-free ", allEps,
  "; basis-transformation equation ", basisTransformationEquation,
  "; flatness ", flatness, "; individual strip solvers ",
  If[productionQ,
    ToString[Length[state["OffDiagonalBlockSolutions"]]] <> " accepted records",
    state["OffDiagonalBlockSolutions"]]];
verdict = If[productionQ, "DeferredToFamilyCertificate",
  allEps && basisTransformationEquation && flatness && finalInverse];
(* Every off-diagonal block carries the alphabet returned by its accepted
   strip solver.  In Production, scan symbolic denominators only on the
   diagonal blocks; scanning the full deferred connection expands exactly
   the large off-diagonal sums whose alphabets are already recorded.  A
   constant regulator transformation introduces no kinematic letter. *)
letterEntries = If[productionQ,
  DeleteCases[Flatten[Table[
    Ap[[mu, ranges[[sector]], ranges[[sector]]]],
    {mu, 2}, {sector, nSectors}]], 0],
  DeleteCases[Flatten[Ap], 0]];
denominatorLetters = DeleteDuplicates[monic /@ Select[
  DeleteDuplicates[Flatten[
    First /@ FactorList[Denominator[Together[#]]] & /@
      letterEntries]] /. fromXY,
  PolynomialQ[#, {c1, c2}] && ! FreeQ[#, c1 | c2] &]];
offDiagonalBlockLetters = DeleteDuplicates[Flatten[
  Lookup[state["OffDiagonalBlockSolutions"], "Alphabet", {}]]];
diagonalLetters = Lookup[state, "DiagonalAlphabets", {}];
letters = DeleteDuplicates[Join[
  denominatorLetters, diagonalLetters, offDiagonalBlockLetters]];
tdiagChart = Lookup[state, "TDiagonal", Missing[]];
tdiagChartInverse = Lookup[state, "TDiagonalInverse", Missing[]];
If[MatrixQ[tdiagChart] && MatrixQ[tdiagChartInverse],
  tdiagChart = tdiagChart /. fromXY;
  tdiagChartInverse = tdiagChartInverse /. fromXY;
  ttotalAbsolute = Map[Together, tdiagChart . S, {2}];
  ttotalAbsoluteInverse = Map[Together, Sinv . tdiagChartInverse, {2}];
  ttotalBasis = "SourceChartConnection",
  log["!! diagonal-block composition unavailable (old checkpoint); " <>
    "the record's TTotal is relative to the assembled connection"];
  ttotalAbsolute = S; ttotalAbsoluteInverse = Sinv;
  ttotalBasis = "AssembledConnection"];
(* Regulator factorizations were constructed in the working {xx,yy}
   variables. Rebind their graded-root evidence to the final record's
   {c1,c2} variables so the whole-family validator checks the same
   quadratic relations that the sector calculation used. *)
Clear[finalRegulatorFactorizationRecord];
finalRegulatorFactorizationRecord[entry_Association] := Module[
  {mapped = entry /. fromXY, evidence, roots, refreshed},
  evidence = Lookup[mapped, "GradedRootFrame", Missing["NotGraded"]];
  If[! AssociationQ[evidence], Return[mapped]];
  roots = KeyTake[#1,
      {"Generator", "QuadraticRadicand", "SourceRadicand"}] & /@
    Lookup[evidence, "Roots", {}];
  refreshed = FeynFacet`Private`familyRegulatorGradedFrameEvidence[
    roots, {c1, c2}, ee];
  Join[mapped, <|"GradedRootFrame" -> refreshed|>]
];
finalRegulatorFactorizationRecord[value_] := value;
finalRegulatorFactorizations = finalRegulatorFactorizationRecord /@
  Lookup[state, "RegulatorFactorizations", {}];
finalRegulatorFactorization = Replace[
  Lookup[state, "RegulatorFactorization", Missing["Absent"]],
  association_Association :> finalRegulatorFactorizationRecord[association]];
workingResult = <|"Family" -> family,
  "CoefficientPresentation" -> coefficientPresentationForResume,
  "Variables" -> {c1, c2}, "Regulator" -> ee,
  "Ranges" -> ranges, "Blocks" -> assembly["Blocks"],
  "TTotal" -> ttotalAbsolute, "TTotalInverse" -> ttotalAbsoluteInverse,
  "EpsFormX" -> Ap[[1]], "EpsFormY" -> Ap[[2]],
  "Letters" -> letters,
  "RegulatorFactorizations" -> finalRegulatorFactorizations,
  "RegulatorFactorization" -> finalRegulatorFactorization|>;
If[! MemberQ[{True, "DeferredToFamilyCertificate"}, verdict],
  log["!! completed sector result did not satisfy its configured " <>
    "construction conditions"];
  If[ownedKernels =!= {}, Quiet[CloseKernels[ownedKernels]]];
  Exit[1]];
validationMethod = If[productionQ, "Modular", "Symbolic"];
out = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  workingResult, differentialSystem, systemReference,
  "IdentityMethod" -> validationMethod];
If[! AssociationQ[out] ||
    Lookup[out, "Status", None] =!= "FamilyDLogEpsilonFormValidated",
  If[AssociationQ[out],
    putAtomic[out,
      FileNameJoin[{outdir,
        "FamilyDLogEpsilonFormValidationFailure.wl"}]]];
  log["!! whole-family validation failed: ",
    If[AssociationQ[out], Lookup[out, "Status", "Unknown"], Head[out]]];
  If[ownedKernels =!= {}, Quiet[CloseKernels[ownedKernels]]];
  Exit[1]];
putAtomic[out,
  FileNameJoin[{outdir, "FamilyDLogEpsilonForm.wl"}]];
log["written V2 family dlog epsilon form; validation method ",
  out["Validation"]["Method"], "; wall ",
  Round[AbsoluteTime[] - start], " s"];
If[ownedKernels =!= {}, Quiet[CloseKernels[ownedKernels]]];
Exit[0]
