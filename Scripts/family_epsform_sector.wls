#!/usr/bin/env wolframscript
(* Completing the family's eps-form -- STANDARDIZED SECTOR ROUTE.
   Existing families remain on the ordinary CANONICA route.  Only a sector
   that ordinary CANONICA cannot transform is completed strip by strip.

   Per sector k = 2..nSectors, on the truncated connection A[1..nk,1..nk] whose
   diagonal blocks are certified eps-forms:
     A. Try CANONICA`TransformOffDiagonalBlock on the complete sector.
     B. If A does not finish, construct CANONICA's exact NextEquationD for
        each unresolved strip.  SolveEpsFormStrip first recognizes an
        existing dlog strip, then searches numerator degrees 0,1,2,3 for
        120 s each on no more than eight local kernels, and only then invokes Maple's exact
        residue-compatibility construction.  If IntegrableConnections cannot
        solve the rational system, the final Maple route uses a finite
        rational ansatz whose denominator is generated from all singular
        letters of the strip.  Every returned strip gauge is checked in both
        differential variables before it is composed.  Each checked strip is
        written atomically, so an interrupted sector resumes from that gauge.
     C. Apply CANONICA`TransformDlogToEpsForm to the completed sector row.
   Family acceptance (unchanged): exact gauge identity T^-1 A T - T^-1 dT
   == A', flatness of A', A'/eps eps-free entrywise, both variables; then a
   route-2-consumable FamilyEpsForms record.
   Usage: family_epsform_sector.wls <family> <outdir>
          [sectorBudget=1800] [tag] [directSectorBudget=30] [chartFile]
          [familyDataDirectory] [classFormDirectory] *)
$HistoryLength = 0;
(* This driver's own identity.  The package hashes only its own Private
   sources; a driver that participates in a strip solve declares itself
   through the solver configuration's "DriverProvenance" (generality pass
   2026-08-23, B2).  $InputFileName is captured NOW: inside a later
   function body it is no longer the script. *)
driverFile = ExpandFileName[$InputFileName];
driverProvenance = <|FileNameTake[driverFile] -> driverFile|>;
(* the writer's identity for the strip-input seal (2026-08-25): a seal is
   only as good as the knowledge of which code wrote it *)
$sectorDriverSourceSHA256 = If[FileExistsQ[driverFile],
  FileHash[driverFile, "SHA256", "HexString"],
  Missing["SourceFileUnavailable"]];
root = ParentDirectory[DirectoryName[driverFile]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
(* pool subkernels keep state: clear the Global` symbols CANONICA and earlier
   missions leave behind (they broke TransportFamilyInChart on a reused
   subkernel: "assembly failed" on kernel 26, 2026-08-18) *)
Scan[Function[nm, ToExpression["Global`" <> nm, InputForm, Function[sy, Quiet[Unprotect[sy]]; ClearAll[sy], HoldAll]]], {"tau", "s", "u", "p", "x", "y", "eps"}];
(* CANONICA is loaded AFTER assembly (its Global` shadowing of x, y, eps must
   not touch the assembly step); it parallelises internally
   (ParallelizeMap[$ComputeParallel]) -- inside a pool subkernel that would
   launch sub-subkernels on the shared licence AND escape TimeConstrained
   (measured: a 300 s-constrained strip step ran 33 min) -> serial. *)
loadCanonica[] := (
  (* the package loader keeps a kernel-lifetime "already loaded" flag; on a
     reused pool subkernel that flag can be True while the definitions are
     not present (measured 2026-08-18: all five CANONICA symbols undefined on
     kernel 27).  Force a real Get every mission; CANONICA's Get is
     re-entrant (BeginPackage/EndPackage). *)
  FeynFacet`Private`$canonicalBlocksCanonicaLoaded = False;
  FeynFacet`Private`canonicalBlocksLoadCanonica[];
  CANONICA`$ComputeParallel = False; CANONICA`Private`$ComputeParallel = False;
  If[DownValues[CANONICA`Private`FindD] === {} && DownValues[CANONICA`FindD] === {},
    Print["[sector-epsform] !! CANONICA did not load (FindD undefined after Get)"]; Exit[3]]);
(* CANONICA 1.0.3 defines some internals in CANONICA` and some in
   CANONICA`Private` (FindD: Private; CalculateNextSubsectorD: public --
   measured 2026-08-18).  Resolve EACH symbol to the context that carries a
   definition, at call time (after loadCanonica[]). *)
canonicaSym[name_String] := Module[{pub = ToExpression["CANONICA`" <> name], priv = ToExpression["CANONICA`Private`" <> name]},
  (* DownValues is HoldAll: without Evaluate it reads the Module local
     itself (always {}) -- watcher diagnosis 2026-08-18 *)
  Which[DownValues[Evaluate[pub]] =!= {}, pub, DownValues[Evaluate[priv]] =!= {}, priv,
    True, (Print["[sector-epsform] !! CANONICA symbol ", name, " undefined in both contexts"]; pub)]];
resolveCanonica[] := (
  canonicaNextEq = canonicaSym["NextEquationD"];
  canonicaInsertD = canonicaSym["InsertDIntoIdentity"];
  canonicaTransformDE = canonicaSym["TransformDE"];
  Print["[sector-epsform] CANONICA symbol contexts: ",
    Context /@ {canonicaNextEq, canonicaInsertD, canonicaTransformDE}]);
args = Rest[$ScriptCommandLine];
If[Length[args] < 2,
  Print["Usage: family_epsform_sector.wls <family> <outdir> " <>
    "[sectorBudget=1800] [tag] [directSectorBudget=30] [chartFile] " <>
    "[familyDataDirectory] [classFormDirectory]"];
  Exit[64]];
family = args[[1]]; outdir = args[[2]];
sectorBudget = If[Length[args] >= 3, ToExpression[args[[3]]], 1800];
tag = If[Length[args] >= 4, args[[4]], ""];
If[StringLength[tag] > 0 && ! StringStartsQ[tag, "_"],
  tag = "_" <> tag];
directSectorBudget = If[Length[args] >= 5, ToExpression[args[[5]]], 30];
rationalMapleBudget = Module[
  {value = Environment["FACET_RATIONAL_MAPLE_BUDGET"], parsed},
  parsed = If[StringQ[value] && StringLength[value] > 0,
    Quiet[Check[ToExpression[value], $Failed]], $Failed];
  If[IntegerQ[parsed] && parsed > 0, parsed, 300]
];
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
chartFile = If[Length[args] >= 6 && StringLength[args[[6]]] > 0,
  ExpandFileName[args[[6]]], None];
(* Per-strip route (FACET_STRIP_ROUTE): "FiniteFieldFirst" (default since
   2026-08-22: dlog recognition -> finite-field affine solve; NO automatic
   CANONICA/Maple fallback -- those are manual tools (user decision
   2026-08-22); an unsolved block ends the family with exit 2 and the
   block record in <scratch>/<family>_<k>_<j>_unsolved.wl) or "Legacy" (CANONICA
   degrees 0-3 -> Maple -> finite field).  Measured on 20 real CF254 strips
   (BenchmarkStripBackends/StripMethods_2026-08-21): finite field 20/20 in
   872 s total; CANONICA ladder 15/20 in 2790 s; Maple 13/20, never faster. *)
(* Check level (FACET_CHECK_LEVEL): "Development" (default; every block
   checked exactly, per-sector exact identities, the script's own family
   gate) or "Production" (user decision 2026-08-22: checks stay separate
   from the calculation -- blocks are accepted on the modular residual,
   the per-sector exact identities and the script's family gate are
   skipped, and the single exact statement is CertifyFamilyEpsilonForm,
   run afterwards by the driver). *)
checkLevel = Module[{value = Environment["FACET_CHECK_LEVEL"]},
  If[StringQ[value] && value === "Production", "Production", "Development"]];
productionQ = checkLevel === "Production";
stripRoute = Module[{value = Environment["FACET_STRIP_ROUTE"]},
  If[StringQ[value] && value === "Legacy", "Legacy", "FiniteFieldFirst"]];
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
mqNativeThreads = Module[{value = Environment["FACET_MQ_NATIVE_THREADS"],
    parsed},
  If[! StringQ[value] || StringLength[value] === 0, Return[kernelCount]];
  parsed = Quiet[Check[ToExpression[value], $Failed]];
  If[! IntegerQ[parsed] || ! Between[parsed, {1, 8}],
    Print["[sector-epsform] FACET_MQ_NATIVE_THREADS must be an integer " <>
      "from 1 through 8"]; Exit[64]];
  parsed
];
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
(* Fixed-core and plan-discovery backends are intentionally distinct.
   These values are explicit so checkpoints bind the exact request. *)
finiteFieldBackend = Automatic;
finiteFieldBackendThreads = 2;
planDiscoveryBackend = "Wolfram";
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
start = AbsoluteTime[];
log[a___] := Print["[sector-epsform ", family, " +", ToString[Round[AbsoluteTime[] - start]], "s] ", StringJoin[ToString[#, InputForm] & /@ {a}]];
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
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y", "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr, sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] && Context[sy] =!= "Global`", {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]], {i, Length[syms]}]; expr /. rules];
normalizeRegulator[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr, sy_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[sy]], {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> ee, {i, Length[syms]}]; expr /. rules];
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];
toC[e_] := e /. ee -> CANONICA`eps; fromC[e_] := e /. CANONICA`eps -> ee;
discoverFamilyDataDirectory[name_String] := Module[{files, directories},
  files = FileNames[
    "nnlo_de_" <> name <> ".wl", root, Infinity];
  directories = DeleteDuplicates[
    ParentDirectory /@ (DirectoryName /@ files)];
  directories = Select[directories,
    FileExistsQ[FileNameJoin[{#, "BlockClasses",
        "block_class_assign.wl"}]] &&
      DirectoryQ[FileNameJoin[{#, "DifferentialEquations"}]] &];
  Which[
    Length[directories] === 1, First[directories],
    directories === {},
      log["!! no differential-system directory contains family ", name];
      Exit[66],
    True,
      log["!! family ", name,
        " occurs in more than one differential-system directory: ",
        directories];
      Exit[66]
  ]
];
ftData = If[Length[args] >= 7 && StringLength[args[[7]]] > 0,
  ExpandFileName[args[[7]]],
  discoverFamilyDataDirectory[family]];
classFormDirectory = If[Length[args] >= 8 && StringLength[args[[8]]] > 0,
  ExpandFileName[args[[8]]], FileNameJoin[{ftData, "ClassForms"}]];
(* The per-family transport-chart inventory is PROJECT data (generality
   pass 2026-08-23, A1): the package ships an empty registry and the
   campaign's own table travels with its family data.  A family that is
   absent from the file (or a project with no file at all) is
   Missing["FamilyChartNotRegistered", ...] and is admitted below only
   after the assembled connection is verified radical-free. *)
familyChartFile = FileNameJoin[{ftData, "TransportFamilyCharts.wl"}];
If[FileExistsQ[familyChartFile],
  familyChartRegistration = FeynFacet`TransportFamilyChartLoad[familyChartFile];
  If[Lookup[familyChartRegistration, "Status", None] =!= "FamilyChartsRegistered",
    log["!! family chart registration refused: ", familyChartRegistration];
    Exit[2]];
  log["registered ", familyChartRegistration["Registered"],
    " family charts from ", familyChartFile],
  log["no family chart file at ", familyChartFile,
    "; the chart registry stays empty"]];
mapleLib = FileNameJoin[{root, "Addon", "Other_Addon", "Maple", "IntegrableConnections"}];
scratch = FileNameJoin[{outdir, "sector_" <> family <> tag}]; If[! DirectoryQ[scratch], CreateDirectory[scratch]];
stateFile = FileNameJoin[{outdir, "sector_state_" <> family <> tag <> ".wl"}];
cachedState = If[FileExistsQ[stateFile], normalizeSymbols[Get[stateFile]],
  Missing["NotFound"]];

(* ---- assemble in the chart; rename chart variables to (x, y) for CANONICA ---- *)
assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
blocks = Table[{a["Rows"], a["ClassID"]}, {a, Select[assignments, #["Family"] === family &]}];
chart = If[StringQ[chartFile],
  If[! FileExistsQ[chartFile],
    log["!! chart file does not exist: ", chartFile]; Exit[2]];
  readArtifact[chartFile],
  FeynFacet`TransportFamilyChart[family]];
(* None  = registered as root-free (transport in the source variables).
   Missing["FamilyChartNotRegistered", family] = no declaration at all:
   the identity frame is used PROVISIONALLY and the assembled connection
   is checked for radicals below (a rooted family with no registration
   must stop, not transport in a frame that cannot hold its roots). *)
chartNotRegisteredQ = MatchQ[chart, Missing["FamilyChartNotRegistered", _]];
If[chartNotRegisteredQ,
  log["no transport chart registered for ", family,
    "; trying the identity frame -- the assembled connection must be radical-free"]];
If[chart === None || chartNotRegisteredQ,
  chart = <|
    "Name" -> "RationalIdentity",
    "Kind" -> "TwoVariable",
    "CoefficientField" -> "Rational",
    "Variables" -> {xx, yy},
    "Subst" -> {vv -> xx, ww -> yy},
    "Root" -> None,
    "RootSquare" -> None,
    "Roots" -> {},
    "Notes" -> "identity chart for a family whose connection contains no square root"
  |>
];
If[! AssociationQ[chart],
  log["!! no exact rational or multiquadratic frame could be constructed"];
  Exit[2]];
chartCertificate = FeynFacet`TransportChartVerify[chart];
If[! TrueQ[Lookup[chartCertificate, "OK", False]],
  log["!! chart identities or Jacobian failed: ", chartCertificate]; Exit[2]];
algebraicFrameQ = Lookup[chart, "CoefficientField", "Rational"] ===
  "Multiquadratic";
(* The blockwise row composition (blockEquation / applyRowGauge) and the
   per-sector regulator factorization are identities over any
   characteristic-zero coefficient field; gating them on a rational
   frame left multiquadratic families without regulator factorization
   and fed regulator-dependent residues into later rows (Codex package
   bug report 2026-08-22, CF300 (8,5)).  The finite-field-first route is
   therefore frame-independent; in a multiquadratic frame each strip is
   solved in the smallest rational chart of its own roots
   (SolveEpsFormStripInFrame) and the completed truncation is factored
   there as well (FactorFamilyRegulatorDependenceInFrame). *)
blockwiseRouteQ = stripRoute === "FiniteFieldFirst";
stripMapleBudget = If[algebraicFrameQ, sectorBudget,
  Min[sectorBudget, rationalMapleBudget]];
(* Cooperative strip budget (2026-08-24).  Until today sectorBudget bound
   only the Maple/CANONICA routes (stripMapleBudget above); the
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
stripBudgetExhaustedQ[s_] := AssociationQ[s] &&
  Lookup[s, "Status", None] === "BudgetExhausted";
(* STRIP CONSTRUCTION (2026-08-24, the same night, second gap).  The
   deadline above landed only INSIDE the solvers.  MEASURED in
   production: both campaign missions sat more than two hours in the
   work between the "strip {i,j}" announcement and the first solver call
   -- CANONICA NextEquationD (or the blockwise block equation), the
   strip-input write, the zero-forcing probe, the solver-configuration
   seal, and then the chart pullback and identity preparation inside
   SolveEpsFormStripInFrame -- where no deadline was ever checked, so
   the 7200 s sector budget passed silently on both families.
   The construction stage now checks the SAME sectorDeadline at each
   substage boundary and produces the SAME typed shape a solver stop
   has, so the StripBudgetExhausted handling below is reused verbatim
   and there is no second stop path.  The substage wall times are
   carried in the stop so a future log shows WHERE the budget went.
   Never TimeConstrained: NextEquationD is a CANONICA call and a
   TimeConstrained step has escaped its bound in pool subkernels
   (CLAUDE.md); the opaque calls are BRACKETED (check before, check
   after, wall time recorded) instead. *)
stripDeadlineExpiredQ[d_] := NumericQ[d] && AbsoluteTime[] >= d;
(* the driver-side construction stop, in the shape the solvers use *)
stripConstructionStop[substage_String, start_, strip_List,
    stageTimings_Association] := <|
  "Status" -> "BudgetExhausted",
  "Stage" -> "StripConstruction:" <> substage,
  "Substage" -> substage,
  "Elapsed" -> AbsoluteTime[] - start,
  "Deadline" -> sectorDeadline,
  "Method" -> "StripConstructionDriver",
  "Resumable" -> True,
  "Strip" -> strip,
  "ConstructionTimings" -> stageTimings|>;
chartFingerprint = Hash[
  KeyTake[chart, {"Name", "Variables", "Subst", "Roots", "Parents"}],
  "SHA256", "HexString"];
If[AssociationQ[cachedState] &&
    ! MissingQ[Lookup[cachedState, "ChartFingerprint", Missing[]]] &&
    cachedState["ChartFingerprint"] =!= chartFingerprint,
  log["cached sector state belongs to a different chart; " <>
    "starting from the exact input system"];
  cachedState = Missing["ChartMismatch"]];
{c1, c2} = chart["Variables"];
toXY = {c1 -> xx, c2 -> yy}; fromXY = {xx -> c1, yy -> c2};
If[AssociationQ[cachedState] &&
    KeyExistsQ[cachedState, "OriginalA"] &&
    KeyExistsQ[cachedState, "Ranges"] &&
    KeyExistsQ[cachedState, "TDiagonal"],
  A0 = cachedState["OriginalA"];
  ranges = cachedState["Ranges"];
  (* the assembly orders the blocks its own way; the record's "Blocks"
     must be THAT order, not the class-assignment order (a resumed run
     wrote assignment-ordered Blocks against assembly-ordered Ranges and
     OriginalA: CF305/CF265 records uncertifiable, 2026-08-22).  Old
     states without the cached order: recompute the assembly and check
     it reproduces the cached connection at random points. *)
  If[KeyExistsQ[cachedState, "Blocks"],
    assemblyBlocks = cachedState["Blocks"],
    Module[{de0, sys0, rec0, asm0, fresh, pt, zeroAt},
      log["cached state has no block order; recomputing the assembly to recover it"];
      de0 = readArtifact[FileNameJoin[{ftData, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
      sys0 = <|"Family" -> family, "Basis" -> de0["BlockBasis"], "Av" -> de0["Av"], "Aw" -> de0["Aw"]|>;
      rec0 = FeynFacet`TransportFamilyInChart[sys0, chart, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
        "AssemblyOnly" -> True, "Blocks" -> blocks, "FormDirectory" -> classFormDirectory,
        "PhysicalValuation" -> 0, "Orders" -> {0, 1}, "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];
      If[! (AssociationQ[rec0] && KeyExistsQ[rec0, "Assembly"]), log["!! assembly failed"]; Exit[1]];
      asm0 = rec0["Assembly"]; fresh = {asm0["Apv"] /. toXY, asm0["Apw"] /. toXY};
      If[asm0["Ranges"] =!= ranges, log["!! recomputed assembly has different ranges"]; Exit[1]];
      SeedRandom[17]; zeroAt = AllTrue[Table[pt = Thread[{xx, yy, ee} -> RandomInteger[{3, 10^6}, 3]/RandomInteger[{10^6, 10^7}, 3]];
        AllTrue[Flatten[(fresh - A0) /. pt], TrueQ[# == 0] &], {2}], TrueQ];
      If[! zeroAt, log["!! recomputed assembly differs from the cached original connection"]; Exit[1]];
      assemblyBlocks = asm0["Blocks"]; cachedState["Blocks"] = assemblyBlocks;
      log["block order recovered from the recomputed assembly (connection verified at 2 points)"]]];
  assembly = <|"Apv" -> (A0[[1]] /. fromXY),
    "Apw" -> (A0[[2]] /. fromXY), "Ranges" -> ranges,
    "Blocks" -> assemblyBlocks|>;
  log["using cached original connection from exact sector ",
    cachedState["Sector"]],
  de = readArtifact[FileNameJoin[{ftData, "DifferentialEquations",
      "nnlo_de_" <> family <> ".wl"}]];
  system = <|"Family" -> family, "Basis" -> de["BlockBasis"],
    "Av" -> de["Av"], "Aw" -> de["Aw"]|>;
  rec = FeynFacet`TransportFamilyInChart[system, chart,
    "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
    "AssemblyOnly" -> True,
    "Blocks" -> blocks,
    "FormDirectory" -> classFormDirectory,
    "PhysicalValuation" -> 0, "Orders" -> {0, 1},
    "TransportBackend" -> "Libra", "MaxWeight" -> 0,
    "Verbose" -> False];
  If[! (AssociationQ[rec] && KeyExistsQ[rec, "Assembly"]),
    log["!! assembly failed"]; Exit[1]];
  assembly = rec["Assembly"];
  A0 = {assembly["Apv"] /. toXY, assembly["Apw"] /. toXY};
  ranges = assembly["Ranges"]
];
(* The identity frame was taken WITHOUT a declaration (A1): it is licensed
   only if the assembled connection contains no radical at all.  A single
   half-integer power means the family needs a frame nobody declared, and
   continuing would build every later row in a frame that cannot represent
   its own coefficients. *)
If[chartNotRegisteredQ,
  unregisteredRadicals = DeleteDuplicates[Cases[A0,
    Power[base_, _Rational] :> base, {0, Infinity}, Heads -> True]];
  If[unregisteredRadicals =!= {} || ! FreeQ[A0, _Root],
    log["!! no transport chart is registered for ", family,
      " and the assembled connection is not radical-free: ",
      Take[unregisteredRadicals, UpTo[3]],
      If[FreeQ[A0, _Root], "", " (and algebraic Root objects)"]];
    Exit[2]];
  log["no registered chart: the assembled connection is radical-free, ",
    "the identity frame is exact for ", family]];
(* Diagonal-block composition: the record must store the ABSOLUTE
   transformation TTotal = diag(T_class) . S against the chart-pulled-
   back source connection, not the sector gauge S alone (records
   written before 2026-08-20 stored S only, and the family certifier
   necessarily failed their gauge identity). The diagonal layer exists
   only on the fresh-assembly path; it is cached in the state so
   resumed runs keep it. *)
freshDiagonal = Module[{forms = Lookup[assembly, "Forms", Missing[]],
    inverses = Lookup[assembly, "TInverse", Missing[]], dim, td, tdi},
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
    {td, tdi}]
];
If[AssociationQ[cachedState] &&
    MissingQ[Lookup[cachedState, "ChartFingerprint", Missing[]]],
  legacyS = Lookup[cachedState, "S", Missing[]];
  legacyA = Lookup[cachedState, "A", Missing[]];
  If[MatrixQ[legacyS] && MatchQ[legacyA, {_?MatrixQ, _?MatrixQ}],
    legacySInverse = Together[Inverse[legacyS]];
    legacyOriginal = Table[Map[Together,
      legacyS . legacyA[[mu]] . legacySInverse +
        D[legacyS, {xx, yy}[[mu]]] . legacySInverse, {2}], {mu, 2}];
    legacyExact = And @@ (TrueQ[Together[#] === 0] & /@
      Flatten[legacyOriginal - A0]);
    If[legacyExact,
      cachedState["OriginalA"] = A0;
      cachedState["Ranges"] = ranges;
      cachedState["ChartFingerprint"] = chartFingerprint;
      log["adopted an older checkpoint after exact reconstruction of " <>
        "the chart connection"],
      log["older checkpoint does not reconstruct the chart connection; " <>
        "starting from the input system"];
      cachedState = Missing["LegacyCheckpointIdentityFailed"]],
    cachedState = Missing["LegacyCheckpointIncomplete"]]
];
loadCanonica[]; resolveCanonica[];
nSectors = Length[ranges]; nMasters = Length[A0[[1]]];
bounds = Table[{First[ranges[[i]]], Last[ranges[[i]]]}, {i, nSectors}];
invariants = {xx, yy};
log["assembled ", nMasters, "x", nMasters, ", ", nSectors, " sectors, chart ", chart["Name"], " ", {c1, c2}, " -> ", {xx, yy}];
(* rational entries: Together is a canonical form, so Together === 0 is a
   complete zero test.  masterTransportZeroMatQ fell through to Simplify
   on every nonzero entry; on CF385 (44 masters) the per-sector block
   census then allocated 30 GB and took the WSL VM down twice (2026-08-22). *)
zeroQ[m_] := AllTrue[Flatten[{m}], TrueQ[Together[#] === 0] &];
epsFormQ[m_] := AllTrue[Flatten[m], TrueQ[Together[#] === 0] || FreeQ[Together[#/ee], ee] &];
badStrips[a_, upTo_] := Flatten[Table[If[i > j && ! zeroQ[a[[1, ranges[[i]], ranges[[j]]]]] &&
  ! (epsFormQ[a[[1, ranges[[i]], ranges[[j]]]]] && epsFormQ[a[[2, ranges[[i]], ranges[[j]]]]]), {i, j}, Nothing], {i, upTo}, {j, upTo}], 1];
monic[f_] := Module[{variables = Variables[f], variable, leading},
  If[variables === {}, Return[f]];
  variable = First[variables];
  leading = Coefficient[f, variable, Exponent[f, variable]];
  If[NumericQ[leading], Expand[f/leading], f]];
log["initial: ", Length[badStrips[A0, nSectors]], " non-eps-factored strips"];

(* ---- state (resume) ---- *)
If[algebraicFrameQ && AssociationQ[cachedState] &&
    Lookup[cachedState, "Sector", 1] > 1 &&
    ! ListQ[Lookup[cachedState, "SectorCertificates", None]],
  log["algebraic checkpoint predates exact sector certificates; " <>
    "starting from the input connection"];
  cachedState = Missing["UncertifiedAlgebraicCheckpoint"]
];
state = If[AssociationQ[cachedState], (log["resuming"]; cachedState),
  <|"Sector" -> 1, "OriginalA" -> A0, "Ranges" -> ranges,
    "Blocks" -> assembly["Blocks"],
    "ChartFingerprint" -> chartFingerprint,
    "S" -> IdentityMatrix[nMasters], "SInverse" -> IdentityMatrix[nMasters],
    "A" -> A0, "StripSolvers" -> {}, "SectorCertificates" -> {}|>];
If[! KeyExistsQ[state, "TDiagonal"] && ListQ[freshDiagonal],
  state["TDiagonal"] = freshDiagonal[[1]];
  state["TDiagonalInverse"] = freshDiagonal[[2]]];
log["diagonal composition state: fresh ", Head[freshDiagonal],
  " attached ", KeyExistsQ[state, "TDiagonal"]];
If[! KeyExistsQ[state, "StripSolvers"],
  state["StripSolvers"] = Replace[Lookup[state, "Fallbacks", {}],
    {i_Integer, j_Integer} :> <|"Sector" -> i, "LowerSector" -> j,
      "Method" -> "LegacyMapleFallback"|>, {1}]];
If[KeyExistsQ[state, "Fallbacks"], KeyDropFrom[state, "Fallbacks"]];
If[! KeyExistsQ[state, "SInverse"],
  state["SInverse"] = Map[Together, Inverse[state["S"]], {2}]];
If[! KeyExistsQ[state, "SectorCertificates"],
  state["SectorCertificates"] = {}];

(* ---- WHOLE-FAMILY DEADLINE: persisted, inherited, never refreshed --
   (2026-08-25, Codex 14:30 "whole-family deadline persistence")
   The epoch lives in the state file.  A first run under a declared
   family budget stamps it; every later run of the same state INHERITS
   it, so the remaining budget is what is left of the original
   allowance.  A declared budget that DIFFERS from the stamped one is a
   deliberate re-budget by the operator and restamps, which is recorded;
   a resume with no budget declared keeps the stamped epoch. *)
(* the POLICY is the package's (familyRowGaugeFamilyDeadlineDecision):
   this driver only applies it and persists what it says to persist *)
familyDeadlineDecision = FeynFacet`Private`familyRowGaugeFamilyDeadlineDecision[
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
staleStopMigration = FeynFacet`Private`familyRowGaugeStaleStopMigration[state];
If[Lookup[staleStopMigration, "Status", None] === "Migrated",
  state = staleStopMigration["State"];
  putAtomic[state, stateFile];
  log["migrated a pre-ResolvedStop state: the stale ",
    staleStopMigration["Migration"]["ClearedStatus"], " stop for rows ",
    staleStopMigration["Migration"]["Rows"],
    " is resolved by the factorization already recorded there"]];

stripSolverSummary[solution_Association, sector_Integer,
    lowerSector_Integer, extraLetters_List : {},
    solverConfiguration_Association : <||>] := Join[
  <|"Sector" -> sector, "LowerSector" -> lowerSector|>,
  KeyTake[solution, {"Method", "NumeratorDegree", "DenominatorDegree",
    "GaugeNumeratorDegrees", "GaugeDenominatorDegrees",
    "Primes", "ModularPrimeCount", "SelectedNumeratorDegreeOffset",
    "BackendRequested", "BackendThreads", "BackendsUsed",
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "PlanDiscoveryBackendThreads",
    "EliminationPlanFingerprint",
    "PrimeSamplingSeconds", "PrimeInterpolationSeconds",
    "TotalSamplingSeconds", "TotalInterpolationSeconds",
    "LiftingSeconds", "ExactCheckSeconds",
    "FirstVariable", "MapleSeconds", "ResiduePreparationSeconds",
    "ResidueKernels",
    "LetterDenominatorPower", "NumeratorDegreeOffset",
    "ExactDLog", "ODEEquationZero", "TransformedDLogZero",
    "Alphabet", "RootIndices", "FrameCertificate",
    "SolutionContract", "Certificate", "Provider",
    "ProviderFingerprint", "LayoutFingerprint",
    "CoefficientABIFingerprint", "ReconstructedVectorFingerprint",
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
  <|"ExtraLetters" -> extraLetters,
    "SolverConfiguration" -> solverConfiguration|>];
stripSolverConfiguration[route_String,
    directAlphabetOptions_ : Automatic] :=
  FeynFacet`Private`familyRowGaugeSolverConfiguration[
    route, Lookup[chart, "CoefficientField", "Rational"], chart,
    If[route === "ZeroForcing", None,
      If[productionQ, "Numerical", "Exact"]],
    If[route === "ZeroForcing", None, finiteFieldBackend],
    If[route === "ZeroForcing", None, finiteFieldBackendThreads],
    Which[route === "ZeroForcing", None,
      route === "DirectMultiquadraticFiniteField", Automatic,
      True, planDiscoveryBackend],
    "PlanDiscoveryBackendThreads" -> If[
      route === "DirectMultiquadraticFiniteField", mqNativeThreads,
      Automatic],
    "DriverProvenance" -> driverProvenance,
    "DirectAlphabetOptions" -> directAlphabetOptions];

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
staleStripCheckpointFile[m_] :=
  FileNameJoin[{scratch, family <> "_" <> ToString[m + 1] <> "_strip_state.wl"}];
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
  tInv, rowCertificate, futureAMode, propagation, staleStop, resolution,
  checkpointFile},
  aT = {state["A"][[1, 1 ;; nm, 1 ;; nm]], state["A"][[2, 1 ;; nm, 1 ;; nm]]};
  If[epsFormQ[aT[[1]]] && epsFormQ[aT[[2]]], Return[False]];   (* nothing applied *)
  log["  rows 1..", m, " carry regulator-dependent residues; FactorFamilyRegulatorDependence",
    If[algebraicFrameQ, "InFrame", ""], " on the ", nm, "x", nm, " truncation"];
  factor = If[algebraicFrameQ,
    FeynFacet`FactorFamilyRegulatorDependenceInFrame[aT, {xx, yy}, ee, chart, "TimeLimit" -> Min[sectorBudget, 600], "Deadline" -> sectorDeadline, "Verbose" -> False],
    FeynFacet`FactorFamilyRegulatorDependence[aT, {xx, yy}, ee, "TimeLimit" -> Min[sectorBudget, 600], "Deadline" -> sectorDeadline, "Verbose" -> False]];
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
      "RootIndices" -> factor["RootIndices"], "RootSquares" -> factor["RootSquares"],
      "MultiquadraticFactorization" ->
        Lookup[factor, "MultiquadraticFactorization", Missing["NotAttempted"]]|>;
    putAtomic[state, stateFile]; Exit[2]];
  If[! (AssociationQ[factor] && factor["Status"] === "OK"),
    log["  !! regulator factorization of rows 1..", m, " failed: ", If[AssociationQ[factor], factor["Status"], factor]];
    Return[False]];
  rowCertificate = SelectFirst[
    Reverse[Lookup[state, "SectorCertificates", {}]],
    Lookup[#, "Sector", None] === m &, <||>];
  futureAMode = If[productionQ,
    Lookup[Lookup[Lookup[rowCertificate, "RowGaugeStatistics", <||>],
      "A", <||>], "FutureAMode", "Together"], "Together"];
  propagation = FeynFacet`Private`familyRegulatorPropagateTruncation[
    state["A"], factor["Connection"], factor["Inverse"],
    factor["Transformation"], nm, {xx, yy},
    Lookup[factor, "PropagationSeal", <||>], futureAMode];
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
  state = Join[state, <|
    "A" -> propagation["Connection"],
    "S" -> FeynFacet`Private`familyRegulatorSparseDot[
      state["S"], tFull, False],
    "SInverse" -> FeynFacet`Private`familyRegulatorSparseDot[
      tInv, state["SInverse"], True],
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
  checkpointFile = staleStripCheckpointFile[m];
  If[FileExistsQ[checkpointFile], DeleteFile[checkpointFile];
    log["  strip checkpoint of sector ", m + 1,
      " discarded (connection transformed)"]];
  putAtomic[state, stateFile];
  If[! MissingQ[staleStop],
    log["  stale ", staleStop["Status"], " stop for rows ", m,
      " cleared and the resolution recorded"]];
  log["  regulator factorization of rows 1..", m, ": ", factor["Method"], ", ", factor["Points"], " points, ",
    Round[factor["Seconds"], 0.1], " s",
    If[KeyExistsQ[factor, "ModularCorroboration"],
      ", graded rank " <> ToString[Lookup[factor, "Rank", "?"]] <>
        ", sign-sheet corroboration " <>
        ToString[Lookup[Lookup[factor, "ModularCorroboration", <||>], "Status", "?"]],
      ""],
    "; future A mode ", futureAMode,
    " -> eps-factored ", epsFormQ[state["A"][[1, 1 ;; nm, 1 ;; nm]]] && epsFormQ[state["A"][[2, 1 ;; nm, 1 ;; nm]]]];
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
     dD_{kj} = eps (e D_{kj} - D_{kj} c) + bbar,
     bbar = A_{kj} - Sum_{j<m<k} D_{km} A_{mj},  e = A_kk/eps,  c = A_jj/eps.
   The former code inverted the full nMasters x nMasters gauge symbolically and
   Together'd nMasters^3 products: 30 GB on CF385 sector 31 (44 masters). *)
blockRows[m_] := ranges[[m]];
(* THE SOURCE of block (k, j).  Two routes, selected by
   FACET_CONSTRUCTION_ROUTE (default Deferred; Symbolic reverts):

   - blockEquationSymbolicForcing is the route production ran until
     2026-08-24.  It is one dense Dot per feeder and then Map[Together,
     ., {2}] over the whole block, i.e. one polynomial gcd per pair of
     terms per entry.  MEASURED: 536 s of silent wall time on the single
     block CF259 (21,18), and 2+ h between blocks of the 28x28 / 37x37
     truncations (two watchdog confirmations).

   - the DEFERRED route (FeynFacet/Private/BlockEquationDeferred.wl,
     Codex Q5 points 1-4, 6 and 8) keeps a sparse tagged term DAG whose
     terms reference the source entries, never forms
     Together[Total[terms]], proves entries nonzero by a modular census,
     and materializes each touched entry over the per-factor maximum of
     already-factored operand denominators -- no gcd is computed to find
     the common denominator.

   A typed refusal from the deferred route (a broken block precondition,
   a mismatched ABI) falls back to the symbolic route and says so; it
   never silently continues.  $blockConstructionRecord carries the
   census, the timings and the route actually used into this block's
   certificate. *)
$blockConstructionRecord = <||>;
blockEquationSymbolicForcing[k_, j_, solved_Association] := Module[
  {rk = blockRows[k], rj = blockRows[j], A = state["A"]},
  Table[Map[Together, A[[mu, rk, rj]] -
    Sum[solved[m] . A[[mu, blockRows[m], rj]],
      {m, Select[Keys[solved], j < # < k &]}], {2}], {mu, 2}]];
blockEquation[k_, j_, solved_Association] := Module[
  {rk = blockRows[k], rj = blockRows[j], A = state["A"], e, c, bbar,
   deferred, materialized, route, bundleRoots, zeroPlaceholder},
  e = Table[Map[Together[#/ee] &, A[[mu, rk, rk]], {2}], {mu, 2}];
  c = Table[Map[Together[#/ee] &, A[[mu, rj, rj]], {2}], {mu, 2}];
  route = FeynFacet`Private`blockEquationDeferredRoute[];
  $blockConstructionRecord = <|"Route" -> route|>;
  If[route === "Deferred",
    bundleRoots = If[TrueQ[algebraicFrameQ],
      FeynFacet`Private`transportChartCurrentRoots[chart, invariants], {}];
    deferred = If[TrueQ[algebraicFrameQ] && ListQ[bundleRoots],
      FeynFacet`Private`blockEquationDeferredForcing[
        A, ranges, k, j, solved, invariants, ee,
        "Output" -> "Bundle", "BundleRoots" -> bundleRoots],
      FeynFacet`Private`blockEquationDeferredForcing[
        A, ranges, k, j, solved, invariants, ee]];
    If[AssociationQ[deferred] &&
        Lookup[deferred, "Status", None] === "PreparedDeferredBundle",
      (* A nonzero census witness proves this is not a zero-forcing block,
         so the direct provider can consume the immutable DAG immediately.
         Only the inconclusive zero candidate pays materialization for the
         exact zero test. *)
      If[! TrueQ[Lookup[deferred, "ZeroForcingCandidateQ", True]],
        zeroPlaceholder = ConstantArray[0, deferred["Dimensions"]];
        $blockConstructionRecord = <|"Route" -> "DeferredBundle",
          "DeferredBundle" -> deferred,
          "DeferredBundleFingerprint" -> deferred["BundleFingerprint"],
          "Census" -> Lookup[deferred["Statistics"], "Census", <||>],
          "ZeroForcingCandidateQ" -> False,
          "BundleStatistics" -> KeyDrop[deferred["Statistics"], "Census"]|>;
        Return[{e, c, zeroPlaceholder}]];
      materialized = FeynFacet`Private`blockEquationDeferredForcing[
        A, ranges, k, j, solved, invariants, ee,
        "Output" -> "BundleAndMaterialized", "BundleRoots" -> bundleRoots];
      If[AssociationQ[materialized] &&
          Lookup[materialized, "Status", None] === "OK",
        $blockConstructionRecord = Join[$blockConstructionRecord,
          KeyDrop[materialized, {"Forcing", "Status"}]];
        Return[{e, c, materialized["Forcing"]}]]];
    If[AssociationQ[deferred] && Lookup[deferred, "Status", None] === "OK",
      $blockConstructionRecord = Join[$blockConstructionRecord,
        KeyDrop[deferred, {"Forcing", "Status"}]];
      Return[{e, c, deferred["Forcing"]}]];
    log["  !! deferred construction refused (",
      If[AssociationQ[deferred],
        KeyTake[deferred, {"Status", "Reason", "BlockPair", "Feeders"}],
        deferred], "); using the symbolic construction"];
    $blockConstructionRecord = Join[$blockConstructionRecord,
      <|"Route" -> "SymbolicFallback",
        "Refusal" -> If[AssociationQ[deferred],
          KeyTake[deferred, {"Status", "Reason", "BlockPair"}],
          deferred]|>]];
  bbar = blockEquationSymbolicForcing[k, j, solved];
  {e, c, bbar}];
(* apply the completed row gauge of sector k to the state *)
applyRowGauge[k_, solved_Association, installedRow_: Automatic] := Module[
  {rk = blockRows[k], start = First[blockRows[k]], cols, Dk, result,
   futureAMode},
  cols = Range[1, start - 1];
  Dk = ConstantArray[0, {Length[rk], start - 1}];
  Do[Dk[[All, blockRows[m] ]] = solved[m], {m, Keys[solved]}];
  futureAMode = If[productionQ && installedRow =!= Automatic,
    "Deferred", "Together"];
  result = FeynFacet`Private`familyRowGaugeApply[
    state["A"], state["S"], state["SInverse"], rk, Dk, {xx, yy},
    installedRow, futureAMode];
  If[! AssociationQ[result] || Lookup[result, "Status", None] =!= "OK",
    Return[result]];
  state = Join[state, <|"A" -> result["Connection"],
    "S" -> result["Transformation"], "SInverse" -> result["Inverse"]|>];
  result["Statistics"]];

(* ---- the sector loop ---- *)
Do[
 Module[{nk = bounds[[k, 2]], aTrunc, res, directSolved, dk, res2, rowGauge = <||>,
   dk2, sfull, sfullInverse, aPrevious, aNew, secs, remaining,
   stageInverse, stageGauge, newS, newSInverse, sectorCertificate,
   rowGaugeStatistics, installedRow = Automatic,
   stripCheckpointFile = None, deferredBundle, directAlphabetOptions},
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
  (* factorTruncated itself now discards the stale strip checkpoint of
     sector m+1 and persists the transformed state before returning, so
     the resolved terminal never survives into the next strip (Codex
     0830 P1) *)
  If[blockwiseRouteQ && k > 1, factorTruncated[k - 1]];
  memtrace["sector " <> ToString[k] <> " after factorTruncated check"];
  aTrunc = toC[{state["A"][[1, 1 ;; nk, 1 ;; nk]],
    state["A"][[2, 1 ;; nk, 1 ;; nk]]}];
  memtrace["sector " <> ToString[k] <> " after toC"];
  Which[
   blockwiseRouteQ,
    secs = 0; res = {False, "FiniteFieldFirst"}; directSolved = False;
    log["  sector completion block by block (finite field; no CANONICA in the loop)",
      If[algebraicFrameQ, "; multiquadratic frame: each strip in the rational chart of its own roots", ""]],
   algebraicFrameQ,
    secs = 0; res = {False, "AlgebraicFrame"}; directSolved = False;
    log["  algebraic coefficient field: constructing individual strip equations"],
   stripRoute === "FiniteFieldFirst",
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
      prevD, nextEq, e, c, bbar, nlow, solution, gauge, solvedBlocks,
      blockColumns, checkpointData, solvedForms, solvedForm,
      stripSolvers = {}, transformation, stripCheckpoint,
      checkpointValid, stripInputFile, extraLetters, obstruction,
      resumeHydration, resumeReset, zeroForcingQ,
      requestedSolverConfiguration, solverConfiguration,
      modularBranches, modularArtifact, modularSummary,
      constructionStart, constructionTimings, constructionSeconds,
      constructionCheck},
      stripCheckpointFile = FileNameJoin[{scratch,
        family <> "_" <> ToString[k] <> "_strip_state.wl"}];
      stripCheckpoint = If[FileExistsQ[stripCheckpointFile],
        readArtifact[stripCheckpointFile], Missing["NotFound"]];
      (* a checkpoint is valid only for the connection it was built on
         (the truncated regulator factorization changes it; CF265 sector
         18, 2026-08-22) *)
      checkpointValid = AssociationQ[stripCheckpoint] &&
        Lookup[stripCheckpoint, "ConnectionHash", None] === Hash[aP, "SHA256", "HexString"] &&
        Lookup[stripCheckpoint, "Sector", Missing[]] === k &&
        Lookup[stripCheckpoint, "SubSize", Missing[]] === subSize &&
        Lookup[stripCheckpoint, "Truncation", Missing[]] === nk &&
        FeynFacet`Private`familyRowGaugeCheckpointGaugeShapeQ[
          Lookup[stripCheckpoint, "PrevD", None], subSize,
          Length /@ (blockRows /@ Range[k - 1])] &&
        FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
          Lookup[stripCheckpoint, "StripSolvers", None],
          Lookup[stripCheckpoint, "PrevD", None], k,
          Length /@ (blockRows /@ Range[k - 1])];
      If[AssociationQ[stripCheckpoint] && ! checkpointValid,
        log["  strip checkpoint of sector ", k, " ignored (built on another connection)"]];
      If[checkpointValid,
        checkpointData = FeynFacet`Private`familyRowGaugeDecodeCheckpoint[
          stripCheckpoint, ee, CANONICA`eps];
        prevD = checkpointData["PrevD"];
        stripSolvers = Lookup[stripCheckpoint, "StripSolvers", {}];
        solvedForms = checkpointData["SolvedForms"];
        log["  resuming ", Length[stripSolvers],
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
      (* Every blockwise resume replays all recovered blocks from exact-
         matching copied inputs/caches: direct finite-field artifacts in a
         rational frame, per-strip rational charts in a multiquadratic frame.
         Existing SolvedForms are SameQ-verified against the replay; missing
         forms are hydrated.  The helper is read-only with respect to the live
         checkpoint and this driver remains its sole writer.  Any typed
         replay failure invalidates the whole recovered row and re-solves its
         strips.  Explicitly disabling hydration is the opt-out: it trusts the
         saved gauges but ignores saved forms and uses the exact sparse formula
         until the mandatory final family certificate. *)
      If[checkpointValid && blockwiseRouteQ && Length[solvedBlocks] > 0,
        If[Environment["FACET_RESUME_HYDRATION"] === "False",
          solvedForms = <||>; installedRow = Automatic;
          log["  resume hydration explicitly disabled: trusting recovered " <>
            "checkpoint gauges, ignoring SolvedForms, and using sparse row " <>
            "propagation; the final family certificate remains mandatory"],
          (* announced BEFORE the call, not after it (2026-08-25).  The
             hydration re-verifies every banked strip against the current
             connection and printed nothing at all until its first strip
             had already been replayed: CF303 sector 17 was silent for
             more than 40 minutes with five strips to re-check and a
             61 MB state, and a watchdog cannot tell that from a hang. *)
          log["  resume hydration: re-checking ",
            Length[solvedBlocks], " banked strip(s) ",
            Sort[Keys[solvedBlocks]], " of sector ", k,
            " against the current connection (truncation ", nk, ")"];
          resumeHydration = FeynFacet`Private`familyRowGaugeHydrateResume[
            stripCheckpoint, stripCheckpointFile, solvedBlocks, solvedForms,
            family, k, invariants, ee, chart, ranges, scratch, state["A"],
            "KernelCount" -> kernelCount,
            "FinalCheck" -> If[productionQ, "Numerical", "Exact"],
            "FiniteFieldBackend" -> finiteFieldBackend,
            "FiniteFieldBackendThreads" -> finiteFieldBackendThreads,
            "PlanDiscoveryBackend" -> planDiscoveryBackend,
            "PlanDiscoveryBackendThreads" -> mqNativeThreads,
            "MultiquadraticImageKernelCount" -> mqImageKernelCount,
            "DriverProvenance" -> driverProvenance,
            "Verbose" -> True];
          If[AssociationQ[resumeHydration] &&
              MemberQ[{"Hydrated", "HydratedPartial", "Verified",
                "VerifiedPartial"},
                Lookup[resumeHydration, "Status", None]],
            solvedForms = resumeHydration["SolvedForms"];
            If[TrueQ[Lookup[resumeHydration,
                "ActivateInstalledRow", False]],
              installedRow = resumeHydration["InstalledRow"]];
            log["  resume hydration: ", resumeHydration["Status"],
              ", replayed ",
              Length[Lookup[resumeHydration, "ReplayRecords", {}]],
              " forms in ",
              Round[Lookup[resumeHydration, "Seconds", 0.], 0.1], " s",
              (* the per-strip breakdown the campaign had no way to see:
                 which strip cost what, and the whole-state identity
                 phases in front of the first one *)
              If[MatchQ[Lookup[resumeHydration, "PhaseTimings", None],
                  _Association],
                ", phases " <> ToString[Map[Round[#, 0.1] &,
                  resumeHydration["PhaseTimings"]], InputForm], ""],
              If[MatchQ[Lookup[resumeHydration, "ReplayRecords", None],
                  {__Association}],
                ", per strip " <> ToString[
                  Lookup[#, "LowerSector", None] ->
                    Round[Lookup[#, "Seconds", 0.], 0.1] & /@
                  resumeHydration["ReplayRecords"], InputForm], ""]],
            (* A replay failure can mean the recovered gauge itself is
               corrupt, not merely its materialized form.  Discard the whole
               row suffix and recompute every strip; applying recovered
               solvedBlocks through the sparse formula would preserve exactly
               the untrusted payload that replay rejected. *)
            resumeReset =
              FeynFacet`Private`familyRowGaugeResumeInvalidatedState[
                subSize];
            {prevD, solvedBlocks, solvedForms, stripSolvers, installedRow} =
              Lookup[resumeReset, {"PrevD", "SolvedBlocks", "SolvedForms",
                "StripSolvers", "InstalledRow"}];
            log["  resume hydration unavailable: ",
              If[AssociationQ[resumeHydration],
                KeyTake[resumeHydration,
                  {"Status", "LowerSector", "DiskSameQ",
                   "CurrentConnectionHashSameQ"}], resumeHydration],
              "; invalidating the recovered row and resolving every strip"]]]];
      (* one cooperative deadline check of the strip-CONSTRUCTION stage;
         it reads the CURRENT constructionStart / nlow /
         constructionTimings of the strip being built, and leaves the
         construction by Throw (Return inside a loop only terminates the
         loop -- documented Wolfram trap) *)
      constructionCheck[substage_String] :=
        If[stripDeadlineExpiredQ[sectorDeadline],
          Throw[stripConstructionStop[substage, constructionStart,
            {k, nlow}, constructionTimings], "StripConstructionBudget"]];
      While[Length[prevD[[1]]] + subSize =!= nk,
        (* ---- strip CONSTRUCTION stage, deadline-checked ---- *)
        solution = Catch[
        constructionStart = AbsoluteTime[];
        constructionTimings = <||>;
        (* hoisted out of the route branch below so the entry stop can
           name the strip it refused to start; the CANONICA route learns
           its lower sector only from NextEquationD *)
        nlow = If[blockwiseRouteQ, k - 1 - Length[solvedBlocks],
          Missing["NotConstructed"]];
        (* BOUNDARY: immediately before this strip's construction begins *)
        constructionCheck["Entry"];
        If[blockwiseRouteQ,
          memtrace["block " <> ToString[{k, nlow}] <> " before equation"];
          (* the blockwise block equation is one Together pass over the
             connection blocks and the installed row products; bracketed
             like the CANONICA call below *)
          {constructionSeconds, {e, c, bbar}} = AbsoluteTiming[
            blockEquation[k, nlow, solvedBlocks]];
          constructionTimings["BlockEquation"] = constructionSeconds;
          memtrace["block " <> ToString[{k, nlow}] <> " after equation"];
          nextEq = True,
          (* CANONICA's NextEquationD is a SINGLE opaque call with no
             interior unit boundary, and must NOT be TimeConstrained (a
             TimeConstrained step has escaped its bound in pool
             subkernels -- CLAUDE.md).  It is BRACKETED instead: the
             deadline is checked before it (above) and again after it,
             and its measured wall time is recorded in the typed stop so
             a future log shows this substage's cost. *)
          {constructionSeconds, nextEq} = AbsoluteTiming[
            canonicaNextEq[aP, invariants, sb, prevD]];
          constructionTimings["NextEquationD"] = constructionSeconds;
          If[! ListQ[nextEq] || First[nextEq] === False,
            log["  !! NextEquationD could not construct the next strip"];
            putAtomic[state, stateFile]; Exit[2]];
          {e, c, bbar, nlow} = {
            fromC[nextEq[[1]]], fromC[nextEq[[2]]],
            fromC[nextEq[[3]]], nextEq[[5]]}];
        (* BOUNDARY: after the block equation / NextEquationD *)
        constructionCheck["EquationConstructed"];
        stripInputFile = FileNameJoin[{scratch,
          family <> "_" <> ToString[k] <> "_" <> ToString[nlow] <>
            "_input.wl"}];
        (* putAtomic returns the renamed path, so only the timing is taken *)
        constructionSeconds = First[AbsoluteTiming[putAtomic[
          Join[<|"Family" -> family, "Sector" -> k,
            "LowerSector" -> nlow, "Variables" -> invariants,
            "Regulator" -> ee, "Strip" -> {e, c, bbar}|>,
            If[AssociationQ[Lookup[$blockConstructionRecord,
                "DeferredBundle", None]],
              <|"DeferredBundle" ->
                $blockConstructionRecord["DeferredBundle"]|>, <||>]],
          stripInputFile]]];
        (* THE STRIP-INPUT SEAL (2026-08-25, Codex 14:30 integrity layer,
           step 1 of 4).  A resume currently re-derives the whole symbolic
           block equation for every banked strip just to prove the input
           on disk is the one the current connection implies.  That proof
           is a cheap digest comparison IF the digests were recorded when
           the input was written, which is what this does: the connection
           the strip was built on, its position, the solved-block prefix
           it was built from, the writer's schema, and the exact strip.

           It is a SIDECAR, not a new key of the input record: the input
           record's own hash travels in resume replay records and in
           existing banked artifacts, and an extra key would change it
           for every strip already on disk.  An absent sidecar therefore
           means "written before this seal existed" and costs nothing.

           Steps 2-4 landed on 2026-08-25 in FamilyRowGaugeResume.wl:
           the seal carries its own FINGERPRINT (schema V2) and a resume
           recomputes it from the hydrated record; two independent
           held-out modular images of the block-equation relation are
           evaluated; a mismatch at an admissible image is a typed
           ResumeRejected naming that image.  The exact reconstruction
           remains the DEFAULT companion ("ResumeGate" ->
           "ModularThenExact"); "Modular" is the opt-in mode that skips
           it once the seal authenticates and both images agree.

           The record is built by the package
           (familyRowGaugeStripInputSeal), not assembled here, so the
           writer and the reader cannot drift apart in the field order
           the fingerprint is taken over. *)
        First[AbsoluteTiming[putAtomic[
          FeynFacet`Private`familyRowGaugeStripInputSeal[
            family, k, nlow, nk,
            Hash[aP, "SHA256", "HexString"], solvedBlocks,
            Hash[If[AssociationQ[Lookup[$blockConstructionRecord,
                "DeferredBundle", None]],
              {{e, c, bbar}, $blockConstructionRecord[
                "DeferredBundleFingerprint"]}, {e, c, bbar}],
              "SHA256", "HexString"],
            Hash[{invariants, ee}, "SHA256", "HexString"],
            $sectorDriverSourceSHA256],
          StringReplace[stripInputFile,
            "_input.wl" -> "_input_seal.wl"]]]];
        constructionTimings["StripInputWrite"] = constructionSeconds;
        If[Environment["FACET_RECORD_STRIP_ONLY"] === "True",
          log["  recorded strip ", {k, nlow}, " at ", stripInputFile];
          putAtomic[state, stateFile];
          Exit[75]
        ];
        (* the construction route and what it cost, per block: the 536 s
           this stage spent on CF259 (21,18) was invisible in the log *)
        log["  construction ", Lookup[$blockConstructionRecord, "Route", "Symbolic"],
          ": ", Round[Total[Values[KeyTake[constructionTimings,
            {"BlockEquation", "NextEquationD", "StripInputWrite"}]]], 0.1],
          " s", If[KeyExistsQ[$blockConstructionRecord, "Census"],
            StringJoin[", census ",
              ToString[Lookup[$blockConstructionRecord["Census"],
                "Status", None]], " (",
              ToString[Lookup[$blockConstructionRecord["Census"],
                "AcceptedSamples", 0]], " accepted), zero-forcing candidate ",
              ToString[Lookup[$blockConstructionRecord,
                "ZeroForcingCandidateQ", True]], ", ",
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
        log["  strip ", {k, nlow}, ": ", Which[
          blockwiseRouteQ && algebraicFrameQ, "finite field in the rational chart of the strip's roots",
          blockwiseRouteQ, "finite field",
          True, "degrees 0,1,2,3; Maple only if all fail"]];
        (* BOUNDARY: after the strip input is on disk (a resume of this
           sector reloads it) *)
        constructionCheck["StripInputWritten"];
        None,
        "StripConstructionBudget"];
        extraLetters = {};
        finiteFieldSolve[] := FeynFacet`SolveEpsFormStripFiniteField[
          <|"Family" -> family, "Sector" -> k,
            "LowerSector" -> nlow, "Variables" -> invariants,
            "Regulator" -> ee, "Strip" -> {e, c, bbar},
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
            (productionQ && Lookup[s, "Certificate", None] === "NumericalResidual"));
        (* a construction stop short-circuits both solve routes: it is
           handled by the StripBudgetExhausted block below, unchanged *)
        If[blockwiseRouteQ && ! stripBudgetExhaustedQ[solution],
          solution = Catch[
          (* BOUNDARY: the zero-forcing probe is one Together over every
             entry of the forcing -- on a wide block that is not cheap *)
          constructionCheck["ZeroForcingProbe"];
          (* no dlog recognition through CANONICA's checker: it hung for
             15 min at full CPU on 2x2 blocks of CF360/CF215 (2026-08-22);
             the finite-field solve finds the trivial gauge in seconds.
             A block whose forcing vanishes identically has the exact
             gauge D = 0 (dD = eps(eD - Dc) + bbar - eps K dlog with
             bbar = 0): no sampling (CF408: ~250 of 340 blocks, ~0.7 s
             each through the three-prime machinery, 2026-08-22) *)
          (* The deferred route's modular census has already PROVED
             whether some entry of this forcing is nonzero -- a single
             nonzero image over F_p is an exact proof of non-vanishing --
             so the Together pass over every entry is paid only when no
             image separated the forcing from zero, and on that branch
             the deferred materializer has already reduced the vanishing
             entries to literal 0.  The symbolic route keeps the
             unconditional exact probe. *)
          {constructionSeconds, zeroForcingQ} = AbsoluteTiming[
            Environment["FACET_ZERO_FORCING"] =!= "False" &&
              TrueQ[Lookup[$blockConstructionRecord,
                "ZeroForcingCandidateQ", True]] && zeroQ[bbar]];
          constructionTimings["ZeroForcingProbe"] = constructionSeconds;
          deferredBundle = Lookup[$blockConstructionRecord,
            "DeferredBundle", Missing["NoDeferredBundle"]];
          directAlphabetOptions = If[AssociationQ[deferredBundle],
            FeynFacet`Private`familyRowGaugeDirectAlphabetOptions[
              deferredBundle], Automatic];
          If[AssociationQ[deferredBundle] &&
              directAlphabetOptions === $Failed,
            log["  !! deferred bundle has no valid direct alphabet payload " <>
              "for strip ", {k, nlow}];
            putAtomic[state, stateFile]; Exit[2]];
          requestedSolverConfiguration = stripSolverConfiguration[
            Which[zeroForcingQ, "ZeroForcing",
              algebraicFrameQ && AssociationQ[deferredBundle],
                "DirectMultiquadraticFiniteField",
              algebraicFrameQ, "RationalChartFiniteField",
              True, "DirectRationalFiniteField"],
            If[! zeroForcingQ && algebraicFrameQ &&
                AssociationQ[deferredBundle],
              directAlphabetOptions, Automatic]];
          If[! FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
              requestedSolverConfiguration],
            log["  !! solver configuration could not be sealed before strip ",
              {k, nlow}, ": ", requestedSolverConfiguration];
            putAtomic[state, stateFile]; Exit[2]];
          (* BOUNDARY: the last driver-side check before any solver runs.
             Past it the deadline is enforced inside the solver, and
             inside SolveEpsFormStripInFrame's own construction stage,
             through the option plumbing below. *)
          constructionCheck["SolverDispatch"];
          Which[
            zeroForcingQ,
              <|"Status" -> "Solved", "Method" -> "ZeroForcing",
                "Gauge" -> ConstantArray[0, Dimensions[First[bbar]]], "ExactDLog" -> True|>,
            algebraicFrameQ,
              FeynFacet`SolveEpsFormStripInFrame[
                {e, c, bbar}, invariants, ee, chart,
                "FiniteFieldFirst" -> True,
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
                     mqImageKernelCount},
                  If[AssociationQ[deferredBundle],
                    Join[{"DeferredBundle" -> deferredBundle},
                     Normal[directAlphabetOptions],
                     {
                     (* the raw strip carries only a shape placeholder for
                        BBar on this route; screening and certification use
                        the provider's authenticated bundle images instead *)
                     "IntegrabilityScreen" -> False,
                     "ScreenFirst" -> False, "GaugeScreen" -> False}], {}]],
                (* and so does the STRIP-CONSTRUCTION stage inside this
                   call -- the chart pullback, the gauge pullback and the
                   source-frame identity check (2026-08-24) *)
                "Deadline" -> sectorDeadline,
                "ScratchDirectory" -> scratch,
                "Tag" -> family <> "_" <> ToString[k] <> "_" <> ToString[nlow],
                "Verbose" -> True],
            True, finiteFieldSolve[]],
          "StripConstructionBudget"];
          If[! solvedQ[solution] && ! stripBudgetExhaustedQ[solution] &&
              algebraicFrameQ,
            log["    finite field found no gauge in frame: ",
              If[AssociationQ[solution], KeyTake[solution, {"Status", "RootIndices", "RootSquares", "Method"}], solution]]];
          (* An ALGEBRAIC frame has no rational-gauge obstruction series
             to compute -- EpsFormStripObstruction expands a rational
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
          If[! solvedQ[solution] && ! stripBudgetExhaustedQ[solution] &&
              ! algebraicFrameQ,
            (* typed failure reason (EpsFormStripObstruction, 2026-08-22):
               a missing letter is supplied and the solve repeated once;
               a non-constant residue proves that no rational gauge
               exists with the present diagonal forms; no obstruction up
               to the order means an ansatz or budget limitation.  No
               CANONICA/Maple fallback (manual tools, user decision). *)
            obstruction = Quiet[TimeConstrained[FeynFacet`EpsFormStripObstruction[
              <|"Family" -> family, "Sector" -> k, "LowerSector" -> nlow,
                "Variables" -> invariants, "Regulator" -> ee, "Strip" -> {e, c, bbar}|>,
              "MaximumOrder" -> 4], 900, $Failed]];
            log["    finite field found no gauge; obstruction certificate: ",
              If[AssociationQ[obstruction], KeyTake[obstruction, {"Status", "Order", "MissingLetters", "Obstructions", "GaugeNumeratorDegrees"}], obstruction]];
            If[AssociationQ[obstruction] && obstruction["Status"] === "MissingLetters",
              extraLetters = obstruction["MissingLetters"];
              log["    repeating the finite-field solve with the missing letters ", extraLetters];
              solution = finiteFieldSolve[]]]];
        If[! blockwiseRouteQ && ! stripBudgetExhaustedQ[solution],
        solution = Catch[
        (* BOUNDARY: the last driver-side check before the legacy route's
           solver runs *)
        constructionCheck["SolverDispatch"];
        If[algebraicFrameQ,
          FeynFacet`SolveEpsFormStripInFrame[
            {e, c, bbar}, invariants, ee, chart,
            "CANONICANumeratorDegrees" -> {0, 1, 2, 3},
            "CANONICADenominatorDegree" -> 0,
            "CANONICATimeLimit" -> 120,
            "CANONICAKernels" -> kernelCount,
            "MapleLibrary" -> mapleLib,
            "MapleTimeLimit" -> stripMapleBudget,
            "MapleResidueKernels" -> kernelCount,
            "MultiquadraticOptions" -> {"Deadline" -> sectorDeadline},
            (* and the strip-construction stage inside this call *)
            "Deadline" -> sectorDeadline,
            "ScratchDirectory" -> scratch,
            "Tag" -> family <> "_" <> ToString[k] <> "_" <> ToString[nlow],
            "Verbose" -> False],
          FeynFacet`SolveEpsFormStrip[
            {e, c, bbar}, invariants, ee,
            "CANONICANumeratorDegrees" -> {0, 1, 2, 3},
            "CANONICADenominatorDegree" -> 0,
            "CANONICATimeLimit" -> 120,
            "CANONICAKernels" -> kernelCount,
            "MapleLibrary" -> mapleLib,
            "MapleTimeLimit" -> stripMapleBudget,
            "MapleResidueKernels" -> kernelCount,
            "ScratchDirectory" -> scratch,
            "Tag" -> family <> "_" <> ToString[k] <> "_" <> ToString[nlow],
            "Verbose" -> False]],
        "StripConstructionBudget"]];
        If[! solvedQ[solution] && ! stripBudgetExhaustedQ[solution] &&
            ! algebraicFrameQ && stripRoute === "Legacy",
          log["    exact CANONICA/Maple routes found no gauge; " <>
            "starting finite-field reconstruction"];
          solution = finiteFieldSolve[]];
        (* F2 (Design/GeneralityFixes2.md, 2026-08-23): SolveEpsFormStrip
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
           write / zero-forcing probe, and SolveEpsFormStripInFrame's
           chart pullback, gauge pullback and source-frame identity
           check -- produces the SAME typed stop, and is handled here,
           unchanged, by the same branch: there is no second stop path.
           Its "Stage" reads "StripConstruction:<substage>" and its
           "ConstructionTimings" name the wall seconds of each substage
           reached, which is what the silent 7200 s overruns lacked. *)
        If[stripBudgetExhaustedQ[solution],
          log["  !! strip ", {k, nlow}, " budget exhausted at stage ",
            Lookup[solution, "Stage", "Unknown"], " after ",
            Round[Lookup[solution, "Elapsed", 0.], 0.1], " s",
            " (sector budget ", sectorBudget, " s); partial progress ",
            KeyTake[solution, {"Prime", "PrimesCompleted", "SamplesDone",
              "SupportSize", "RegulatorValue", "UnknownCount",
              "ConstructionTimings"}]];
          state["Stop"] = <|"Status" -> "StripBudgetExhausted",
            "Strip" -> {k, nlow},
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
               "RootSquares", "Chart", "StripDimensions", "InnerStatus"}],
            "StripCheckpointFile" -> stripCheckpointFile|>;
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
            KeyTake[solution, {"RootIndices", "RootSquares", "Dimensions",
              "UnknownCount", "EquationsPerPoint", "PreparationSchema",
              "ABIFingerprint", "AlgebraABIFingerprint",
              "AssemblyFingerprint", "SamplePrimes", "RegulatorValues",
              "HeldOutPrime", "HeldOutRegulatorValue", "ExactLift",
              "ExactChannelResidual", "RootFreeFastPathCount", "Seconds"}]];
          putAtomic[
            <|"Family" -> family, "Sector" -> k, "LowerSector" -> nlow,
              "Variables" -> invariants, "Regulator" -> ee,
              "Strip" -> {e, c, bbar},
              "StripInput" -> <|"ChartFingerprint" -> chartFingerprint,
                "AlgebraicFrame" -> algebraicFrameQ,
                "Truncation" -> nk, "SubSize" -> subSize,
                "Dimensions" -> Dimensions[First[bbar]],
                "ConnectionHash" -> Hash[aP, "SHA256", "HexString"],
                "StripCheckpointFile" -> stripCheckpointFile|>,
              "SolverConfiguration" -> If[blockwiseRouteQ,
                requestedSolverConfiguration,
                Missing["LegacySolverRouteNotBound"]],
              "Summary" -> modularSummary,
              "Result" -> solution|>,
            modularArtifact];
          AppendTo[stripSolvers, modularSummary];
          state["StripSolvers"] = Join[state["StripSolvers"], {modularSummary}];
          log["  !! strip ", {k, nlow}, " is a MODULAR CANDIDATE only: ",
            "multiquadratic engine, root rank ",
            Lookup[solution, "RootCount", None], ", ",
            Length[modularBranches], " sign branches (all residual zero: ",
            modularSummary["AllBranchesResidualZero"], "), contract ",
            modularSummary["SolutionContract"]];
          log["     recorded in ", modularArtifact,
            " and NOT installed: no certified dlog potential exists for it"];
          state["Stop"] = <|"Status" -> "ModularCandidateNotInstallable",
            "Strip" -> {k, nlow}|>;
          putAtomic[state, stateFile]; Exit[2]];
        If[! solvedQ[solution],
          log["  !! no exact gauge for strip ", {k, nlow}];
          putAtomic[
            <|"Family" -> family, "Sector" -> k,
              "LowerSector" -> nlow, "Variables" -> invariants,
              "Regulator" -> ee, "Strip" -> {e, c, bbar},
              "SolverConfiguration" -> If[blockwiseRouteQ,
                requestedSolverConfiguration,
                Missing["LegacySolverRouteNotBound"]],
              "SolverFailure" ->
                FeynFacet`Private`familyRowGaugeSolverFailureSummary[
                  solution],
              "ObstructionCertificate" -> If[ValueQ[obstruction] && AssociationQ[obstruction],
                KeyDrop[obstruction, "GaugeSeries"], Missing["NotRun"]]|>,
            FileNameJoin[{scratch,
              family <> "_" <> ToString[k] <> "_" <>
                ToString[nlow] <> "_unsolved.wl"}]];
          putAtomic[state, stateFile]; Exit[2]];
        gauge = solution["Gauge"];
        solverConfiguration = If[blockwiseRouteQ,
          stripSolverConfiguration[
            Which[Lookup[solution, "Method", None] === "ZeroForcing",
              "ZeroForcing",
              Lookup[solution, "Method", None] ===
                "DirectMultiquadraticFiniteField",
              "DirectMultiquadraticFiniteField",
              algebraicFrameQ, "RationalChartFiniteField",
              True, "DirectRationalFiniteField"],
            If[Lookup[solution, "Method", None] ===
                "DirectMultiquadraticFiniteField",
              directAlphabetOptions, Automatic]], <||>];
        If[blockwiseRouteQ &&
            ! FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
              solverConfiguration],
          log["  !! solver configuration could not be sealed for strip ",
            {k, nlow}, ": ", solverConfiguration];
          putAtomic[state, stateFile]; Exit[2]];
        solvedForm = FeynFacet`Private`familyRowGaugeDLogForm[
          solution, invariants, ee, Dimensions[First[bbar]]];
        If[ListQ[solvedForm], solvedForms[nlow] = solvedForm,
          log["    materialized dlog row form unavailable; row propagation " <>
            "will use the exact sparse formula"]];
        AppendTo[stripSolvers,
          stripSolverSummary[solution, k, nlow, extraLetters,
            solverConfiguration]];
        log["    ", solution["Method"],
          If[KeyExistsQ[solution, "NumeratorDegree"],
            " at numerator degree " <> ToString[solution["NumeratorDegree"]],
            ""]];
        prevD = MapIndexed[Join[toC[gauge][[#2[[1]]]], #1] &, prevD];
        solvedBlocks[nlow] = gauge;
        putAtomic[
          <|"Sector" -> k, "SubSize" -> subSize,
            "Truncation" -> nk, "PrevD" -> fromC[prevD],
            "ConnectionHash" -> Hash[aP, "SHA256", "HexString"],
            "StripSolvers" -> stripSolvers,
            "SolvedForms" -> fromC[solvedForms]|>,
          stripCheckpointFile];
      ];
      rowGauge = solvedBlocks;
      blockColumns = Association[Table[
        m -> blockRows[m], {m, Keys[solvedBlocks]}]];
      If[installedRow === Automatic,
        installedRow =
          FeynFacet`Private`familyRowGaugeAssembleInstalledRow[
            solvedForms, solvedBlocks, subSize, First[blockRows[k]] - 1,
            blockColumns]];
      transformation = If[blockwiseRouteQ, None, canonicaInsertD[sb, prevD]];
      (* CANONICA's TransformDE (the transformed truncated connection,
         fully symbolic) fed only the per-sector TransformDlogToEpsForm,
         which the finite-field-first route no longer runs; on CF385
         sector 31 (41x41) it allocated >36 GB and took the WSL VM down
         (2026-08-22).  The connection is transformed below blockwise. *)
      res = {transformation, If[blockwiseRouteQ, None,
        canonicaTransformDE[aP, invariants, transformation]]};
      state["StripSolvers"] = Join[state["StripSolvers"], stripSolvers];
      log["  sector ", k, " row completed from ", Length[stripSolvers],
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
    Module[{t0 = AbsoluteTime[], exactStrips},
      rowGaugeStatistics = applyRowGauge[k, rowGauge, installedRow];
      If[! AssociationQ[rowGaugeStatistics] ||
          KeyExistsQ[rowGaugeStatistics, "Status"],
        log["  !! row gauge of sector ", k, " rejected: ",
          rowGaugeStatistics]; putAtomic[state, stateFile]; Exit[2]];
      log["  row gauge of sector ", k, " applied blockwise in ",
        Round[AbsoluteTime[] - t0, 0.1], " s; sparse products/touched A=",
        rowGaugeStatistics["A", "Products"], "/",
        rowGaugeStatistics["A", "Touched"], ", S=",
        rowGaugeStatistics["S", "Products"], "/",
        rowGaugeStatistics["S", "Touched"], ", SInverse=",
        rowGaugeStatistics["SInverse", "Products"], "/",
        rowGaugeStatistics["SInverse", "Touched"], ", normalization ",
        Round[Total[Lookup[#, "NormalizationSeconds", 0.] & /@
          Lookup[rowGaugeStatistics, {"A", "S", "SInverse"}, {}]], 0.1],
        " s, literal single-term fast paths ",
        Total[Lookup[#, "SingleTermFastPath", 0] & /@
          Lookup[rowGaugeStatistics, {"A", "S", "SInverse"}, {}]],
        ", dlog row entries installed ",
        Lookup[rowGaugeStatistics["A"], "InstalledRowEntries", 0],
        ", future A mode ",
        Lookup[rowGaugeStatistics["A"], "FutureAMode", "Together"],
        ", deferred future entries/touched ",
        Lookup[rowGaugeStatistics["A"], "DeferredFutureEntries", 0], "/",
        Lookup[rowGaugeStatistics["A"], "FutureTouched", 0]];
      exactStrips = AllTrue[Select[state["StripSolvers"], #["Sector"] === k &],
        TrueQ[Lookup[#, "ExactDLog", False]] &];
      stageInverse = If[productionQ, Missing["NotRunProduction"], True];
      stageGauge = If[productionQ, Missing["NotRunProduction"], exactStrips]];
    sectorCertificate = <|"Sector" -> k, "TransformationInverse" -> stageInverse,
      "GaugeIdentity" -> stageGauge, "Exact" -> ! productionQ && TrueQ[stageGauge],
      "CheckLevel" -> checkLevel, "Route" -> "Blockwise",
      "RowGaugeStatistics" -> rowGaugeStatistics|>;
    state = Join[state, <|"Sector" -> k,
      "SectorCertificates" -> Append[state["SectorCertificates"], sectorCertificate]|>],
  dk = fromC[res[[1]]];
  If[stripRoute === "FiniteFieldFirst",
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
     former stageGauge recomputed the expression that defines aNew and
     subtracted it -- vacuous by construction, two nMasters x nMasters Together passes
     per sector; removed 2026-08-22.) *)
  stageInverse = If[productionQ, Missing["NotRunProduction"],
    zeroQ[
      sfull[[1 ;; nk, 1 ;; nk]] .
        sfullInverse[[1 ;; nk, 1 ;; nk]] - IdentityMatrix[nk]] &&
    zeroQ[sfullInverse[[1 ;; nk, 1 ;; nk]] .
        sfull[[1 ;; nk, 1 ;; nk]] - IdentityMatrix[nk]]];
  stageGauge = If[productionQ, Missing["NotRunProduction"], True];
  If[! productionQ && ! TrueQ[stageInverse],
    log["!! exact sector transformation identity failed at sector ", k];
    Exit[1]];
  newS = Together[state["S"] . sfull];
  newSInverse = Together[sfullInverse . state["SInverse"]];
  sectorCertificate = <|"Sector" -> k,
    "TransformationInverse" -> stageInverse,
    "GaugeIdentity" -> stageGauge, "Exact" -> ! productionQ,
    "CheckLevel" -> checkLevel|>;
  state = Join[
    KeyTake[state, {"OriginalA", "Ranges", "Blocks", "OriginalAReconstruction",
      "ChartFingerprint", "TDiagonal", "TDiagonalInverse",
      "RegulatorFactorizations", "RegulatorFactorization"}],
    <|"Sector" -> k, "S" -> newS, "SInverse" -> newSInverse,
      "A" -> aNew, "StripSolvers" -> state["StripSolvers"],
      "SectorCertificates" ->
        Append[state["SectorCertificates"], sectorCertificate]|>
  ]];
  memtrace["sector " <> ToString[k] <> " before factorTruncated"];
  If[blockwiseRouteQ, factorTruncated[k]];
  memtrace["sector " <> ToString[k] <> " after factorTruncated"];
  putAtomic[state, stateFile];
  memtrace["sector " <> ToString[k] <> " after state write"];
  If[StringQ[stripCheckpointFile] && FileExistsQ[stripCheckpointFile],
    DeleteFile[stripCheckpointFile]];
  If[productionQ && AssociationQ[rowGaugeStatistics] &&
      Lookup[Lookup[rowGaugeStatistics, "A", <||>], "FutureAMode",
        "Together"] === "Deferred",
    remaining = Missing["DeferredProductionCensus"];
    memtrace["sector " <> ToString[k] <> " full badStrips census deferred"];
    log["  sector ", k, " done; full non-eps-factored strip census " <>
      "deferred in Production; acceptance remains the whole-family certificate"],
    remaining = Length[badStrips[state["A"], nSectors]];
    memtrace["sector " <> ToString[k] <> " after badStrips"];
    log["  sector ", k,
      " done; non-eps-factored strips remaining (all sectors): ", remaining]]],
 {k, Max[2, state["Sector"] + 1], nSectors}];

(* ---- family-level regulator factorization (FiniteFieldFirst route) ---- *)
If[blockwiseRouteQ &&
    ! (epsFormQ[state["A"][[1]]] && epsFormQ[state["A"][[2]]]),
  Module[{factor, tFull, tInv, familyDeadline = AbsoluteTime[] + sectorBudget},
    log["family connection has regulator-dependent residues; FactorFamilyRegulatorDependence", If[algebraicFrameQ, "InFrame", ""]];
    (* the same absolute budget the in-sector stage gets: "TimeLimit"
       bounds one subcall, "Deadline" bounds the stage (Codex 0830 P2) *)
    log["  family regulator budget ", sectorBudget, " s (deadline ",
      DateString[familyDeadline, {"Hour", ":", "Minute", ":", "Second"}], ")"];
    factor = If[algebraicFrameQ,
      FeynFacet`FactorFamilyRegulatorDependenceInFrame[state["A"], {xx, yy}, ee, chart,
        "TimeLimit" -> sectorBudget, "Deadline" -> familyDeadline, "Verbose" -> True],
      FeynFacet`FactorFamilyRegulatorDependence[state["A"], {xx, yy}, ee,
        "TimeLimit" -> sectorBudget, "Deadline" -> familyDeadline, "Verbose" -> True]];
    If[AssociationQ[factor] && factor["Status"] === "OK",
      tFull = factor["Transformation"]; tInv = factor["Inverse"];
      state = Join[state, <|"A" -> factor["Connection"],
        "S" -> FeynFacet`Private`familyRegulatorSparseDot[state["S"], tFull, False],
        "SInverse" -> FeynFacet`Private`familyRegulatorSparseDot[tInv, state["SInverse"], True],
        "RegulatorFactorization" -> KeyDrop[factor, {"Connection", "Transformation", "Inverse"}]|>];
      putAtomic[state, stateFile];
      log["family regulator factorization: ", factor["Method"], ", ", factor["Points"], " points, ",
        Round[factor["Seconds"], 0.1], " s -> eps-factored ", epsFormQ[state["A"][[1]]] && epsFormQ[state["A"][[2]]]],
      log["!! family regulator factorization failed: ", If[AssociationQ[factor], factor["Status"], factor],
        "; the dlog form with regulator-dependent residues is kept"]]]];

(* ---- family-level exact checks (in chart variables) ---- *)
S = state["S"] /. fromXY;
Sinv = state["SInverse"] /. fromXY;
Ap = {state["A"][[1]] /. fromXY, state["A"][[2]] /. fromXY};
Aorig = {assembly["Apv"], assembly["Apw"]};
allEps = epsFormQ[Ap[[1]]] && epsFormQ[Ap[[2]]];
sectorCertificatesExact =
  Length[state["SectorCertificates"]] === Max[0, nSectors - 1] &&
  AllTrue[state["SectorCertificates"],
    TrueQ[Lookup[#, "TransformationInverse", False]] &&
      TrueQ[Lookup[#, "GaugeIdentity", False]] &];
If[productionQ,
  (* Production: no exact identities here; CertifyFamilyEpsilonForm is the
     single exact test (driver runs it next).  Only the cheap structural
     statement is made. *)
  finalInverse = Missing["DeferredToFamilyCertificate"];
  gauge = Missing["DeferredToFamilyCertificate"];
  flatness = Missing["DeferredToFamilyCertificate"];
  gaugeRoute = "DeferredToFamilyCertificate";
  flatnessRoute = "DeferredToFamilyCertificate",
 If[algebraicFrameQ,
  finalInverse = sectorCertificatesExact;
  gauge = sectorCertificatesExact;
  flatness = gauge && finalInverse &&
    TrueQ[assembly["Certificate"]["FlatnessOriginal"]];
  gaugeRoute = "CompositionOfExactSectorGaugeIdentities";
  flatnessRoute = "GaugeCovarianceFromExactSourceFlatness",
  finalInverse = zeroQ[S . Sinv - IdentityMatrix[nMasters]] &&
    zeroQ[Sinv . S - IdentityMatrix[nMasters]];
  gauge = zeroQ[Map[Together,
      Sinv . Aorig[[1]] . S - Sinv . D[S, c1] - Ap[[1]], {2}]] &&
    zeroQ[Map[Together,
      Sinv . Aorig[[2]] . S - Sinv . D[S, c2] - Ap[[2]], {2}]];
  flatness = zeroQ[Map[Together,
    D[Ap[[2]], c1] - D[Ap[[1]], c2] +
      Ap[[1]] . Ap[[2]] - Ap[[2]] . Ap[[1]], {2}]];
  gaugeRoute = "DirectFullMatrixIdentity";
  flatnessRoute = "DirectFullMatrixCurvature"
]];
log["FAMILY: A'/eps eps-free ", allEps, "; gauge identity ", gauge,
  "; flatness ", flatness, "; individual strip solvers ",
  state["StripSolvers"]];
verdict = If[productionQ, If[allEps, "DeferredToFamilyCertificate", False],
  allEps && gauge && flatness && finalInverse];
denominatorLetters = DeleteDuplicates[monic /@ Select[
  DeleteDuplicates[Flatten[
    First /@ FactorList[Denominator[Together[#]]] & /@
      DeleteCases[Flatten[Ap], 0]]] /. fromXY,
  PolynomialQ[#, {c1, c2}] && ! FreeQ[#, c1 | c2] &]];
stripLetters = DeleteDuplicates[Flatten[
  Lookup[state["StripSolvers"], "Alphabet", {}]]];
letters = DeleteDuplicates[Join[denominatorLetters, stripLetters]];
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
   variables.  Rebind their graded-root evidence to the final record's
   {c1,c2} variables and recompute the canonical fingerprints, so the
   whole-family certifier authenticates exactly what the artifact carries. *)
Clear[finalRegulatorFactorizationRecord];
finalRegulatorFactorizationRecord[entry_Association] := Module[
  {mapped = entry /. fromXY, evidence, roots, refreshed},
  evidence = Lookup[mapped, "GradedRootFrame", Missing["NotGraded"]];
  If[! AssociationQ[evidence], Return[mapped]];
  roots = KeyTake[#1, {"Root", "RootSquare"}] & /@
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
out = <|"Family" -> family,
  "Method" -> "SectorCANONICA+ExactStripSolver",
  "Chart" -> chart["Name"], "ChartRecord" -> chart,
  "ChartCertificate" -> chartCertificate,
  "ChartFingerprint" -> chartFingerprint,
  "Variables" -> {c1, c2}, "Regulator" -> ee,
  "Ranges" -> ranges, "Blocks" -> assembly["Blocks"],
  "TTotal" -> ttotalAbsolute, "TTotalInverse" -> ttotalAbsoluteInverse,
  "TBlockDiagonal" -> tdiagChart, "TTotalBasis" -> ttotalBasis,
  "S" -> S, "EpsFormX" -> Ap[[1]], "EpsFormY" -> Ap[[2]],
  "Letters" -> letters, "GateVerdict" -> verdict,
  "GaugeIdentity" -> gauge, "GaugeIdentityRoute" -> gaugeRoute,
  "Flatness" -> flatness, "FlatnessRoute" -> flatnessRoute,
  "Triangular" -> True, "TTotalInvertible" -> finalInverse,
  "SectorCertificates" -> state["SectorCertificates"],
  "StripSolvers" -> state["StripSolvers"],
  "RegulatorFactorizations" -> finalRegulatorFactorizations,
  "RegulatorFactorization" -> finalRegulatorFactorization,
  "RowGaugePropagationPolicy" -> If[productionQ,
    "DeferredFutureAWithCompleteInstalledRowElseTogether", "Together"],
  "Status" -> Which[verdict === True, "ExactEpsilonForm",
    verdict === "DeferredToFamilyCertificate", "CandidateEpsilonForm",
    True, "Incomplete"],
  "CheckLevel" -> checkLevel,
  "WallSeconds" -> AbsoluteTime[] - start,
  "Provenance" -> "Complete-sector CANONICA first. For an unresolved sector, CANONICA NextEquationD constructs each strip. In Production, a complete materialized current row is installed, future A row-gauge corrections and sealed constant-regulator right-products retain exact deferred sums, and unavailable installed rows fall back to Together; CertifyFamilyEpsilonForm is the sole whole-family acceptance test and records whether its evidence is characteristic-zero exact or high-confidence finite-field. Development retains Together propagation and its exact intermediate checks."|>;
putAtomic[out, FileNameJoin[{outdir, "family_epsform_" <> family <> ".wl"}]];
log["written family_epsform_", family, ".wl; GateVerdict ", verdict, "; wall ", Round[AbsoluteTime[] - start], " s"];
If[ownedKernels =!= {}, Quiet[CloseKernels[ownedKernels]]];
Exit[If[verdict === True || verdict === "DeferredToFamilyCertificate", 0, 1]]
