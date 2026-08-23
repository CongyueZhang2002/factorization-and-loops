#!/usr/bin/env wolframscript
(* Completing the family's eps-form -- STANDARDIZED SECTOR ROUTE.
   Existing families remain on the ordinary CANONICA route.  Only a sector
   that ordinary CANONICA cannot transform is completed strip by strip.

   Per sector k = 2..nb, on the truncated connection A[1..nk,1..nk] whose
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
root = ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]];
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
(* External triple-root pilot only: rank-0/1/2 strips in a multiquadratic
   frame are rational after their targeted chart pullback.  Give the exact
   legacy solvers only the built-in dlog recognition pass (empty CANONICA
   degree list, Maple disabled), then use SolveEpsFormStripInFrame's
   finite-field fallback.  This keeps the
   recursive dependency walk targeted without changing the package. *)
frameFiniteFieldFirstQ =
  Environment["FACET_ALGEBRAIC_FINITE_FIELD_FIRST"] === "True";
kernelCount = Module[{value = Environment["FACET_KERNEL_COUNT"]},
  If[StringQ[value] && StringLength[value] > 0,
    Min[8, Max[1, ToExpression[value]]],
    8
  ]
];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
start = AbsoluteTime[];
log[a___] := Print["[sector-epsform ", family, " +", ToString[Round[AbsoluteTime[] - start]], "s] ", StringJoin[ToString[#, InputForm] & /@ {a}]];
log["worker-kernel limit ", kernelCount];
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
If[chart === None,
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
stripMapleBudget = If[algebraicFrameQ, sectorBudget,
  Min[sectorBudget, rationalMapleBudget]];
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
nb = Length[ranges]; n = Length[A0[[1]]];
bounds = Table[{First[ranges[[i]]], Last[ranges[[i]]]}, {i, nb}];
invariants = {xx, yy};
log["assembled ", n, "x", n, ", ", nb, " sectors, chart ", chart["Name"], " ", {c1, c2}, " -> ", {xx, yy}];
zeroQ[m_] := TrueQ[FeynFacet`Private`masterTransportZeroMatQ[m]];
epsFormQ[m_] := AllTrue[Flatten[m], TrueQ[Together[#] === 0] || FreeQ[Together[#/ee], ee] &];
badStrips[a_, upTo_] := Flatten[Table[If[i > j && ! zeroQ[a[[1, ranges[[i]], ranges[[j]]]]] &&
  ! (epsFormQ[a[[1, ranges[[i]], ranges[[j]]]]] && epsFormQ[a[[2, ranges[[i]], ranges[[j]]]]]), {i, j}, Nothing], {i, upTo}, {j, upTo}], 1];
monic[f_] := Module[{variables = Variables[f], variable, leading},
  If[variables === {}, Return[f]];
  variable = First[variables];
  leading = Coefficient[f, variable, Exponent[f, variable]];
  If[NumericQ[leading], Expand[f/leading], f]];
log["initial: ", Length[badStrips[A0, nb]], " non-eps-factored strips"];

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
    "S" -> IdentityMatrix[n], "SInverse" -> IdentityMatrix[n],
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

stripSolverSummary[solution_Association, sector_Integer,
    lowerSector_Integer] := Join[
  <|"Sector" -> sector, "LowerSector" -> lowerSector|>,
  KeyTake[solution, {"Method", "NumeratorDegree", "DenominatorDegree",
    "GaugeNumeratorDegrees", "GaugeDenominatorDegrees",
    "Primes", "ModularPrimeCount", "SelectedNumeratorDegreeOffset",
    "PrimeSamplingSeconds", "PrimeInterpolationSeconds",
    "TotalSamplingSeconds", "TotalInterpolationSeconds",
    "LiftingSeconds", "ExactCheckSeconds",
    "FirstVariable", "MapleSeconds", "ResiduePreparationSeconds",
    "ResidueKernels",
    "LetterDenominatorPower", "NumeratorDegreeOffset",
    "ExactDLog", "ODEEquationZero", "TransformedDLogZero",
    "Alphabet", "RootIndices", "FrameCertificate"}]];

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
factorTruncated[m_] := Module[{nm = bounds[[m, 2]], aT, factor, tFull, tInv},
  aT = {state["A"][[1, 1 ;; nm, 1 ;; nm]], state["A"][[2, 1 ;; nm, 1 ;; nm]]};
  If[epsFormQ[aT[[1]]] && epsFormQ[aT[[2]]], Return[False]];   (* nothing applied *)
  log["  rows 1..", m, " carry regulator-dependent residues; FactorFamilyRegulatorDependence on the ", nm, "x", nm, " truncation"];
  factor = FeynFacet`FactorFamilyRegulatorDependence[aT, {xx, yy}, ee, "TimeLimit" -> Min[sectorBudget, 600], "Verbose" -> False];
  If[! (AssociationQ[factor] && factor["Status"] === "OK"),
    log["  !! regulator factorization of rows 1..", m, " failed: ", If[AssociationQ[factor], factor["Status"], factor]];
    Return[False]];
  tFull = IdentityMatrix[n]; tFull[[1 ;; nm, 1 ;; nm]] = factor["Transformation"];
  tInv = IdentityMatrix[n]; tInv[[1 ;; nm, 1 ;; nm]] = factor["Inverse"];
  state = Join[state, <|
    "A" -> Table[Map[Together, tInv . state["A"][[mu]] . tFull, {2}], {mu, 2}],
    "S" -> Together[state["S"] . tFull], "SInverse" -> Together[tInv . state["SInverse"]],
    "RegulatorFactorizations" -> Append[Lookup[state, "RegulatorFactorizations", {}],
      <|"Rows" -> m, "Method" -> factor["Method"], "Points" -> factor["Points"], "Seconds" -> factor["Seconds"]|>]|>];
  log["  regulator factorization of rows 1..", m, ": ", factor["Method"], ", ", factor["Points"], " points, ",
    Round[factor["Seconds"], 0.1], " s -> eps-factored ", epsFormQ[state["A"][[1, 1 ;; nm, 1 ;; nm]]] && epsFormQ[state["A"][[2, 1 ;; nm, 1 ;; nm]]]];
  True];

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
   The former code inverted the full n x n gauge symbolically and
   Together'd n^3 products: 30 GB on CF385 sector 31 (44 masters). *)
blockRows[m_] := ranges[[m]];
(* the equation of block (k, j) from the current connection and the
   solved blocks of this row (an association j -> D_{kj}) *)
blockEquation[k_, j_, solved_Association] := Module[{rk = blockRows[k], rj = blockRows[j], A = state["A"], e, c, bbar},
  e = Table[Map[Together[#/ee] &, A[[mu, rk, rk]], {2}], {mu, 2}];
  c = Table[Map[Together[#/ee] &, A[[mu, rj, rj]], {2}], {mu, 2}];
  bbar = Table[Map[Together, A[[mu, rk, rj]] -
    Sum[solved[m] . A[[mu, blockRows[m], rj]], {m, Select[Keys[solved], j < # < k &]}], {2}], {mu, 2}];
  {e, c, bbar}];
(* apply the completed row gauge of sector k to the state *)
applyRowGauge[k_, solved_Association] := Module[{rk = blockRows[k], start = First[blockRows[k]], cols, Dk, A, S, Si, AD, DA, dD, newA, newS, newSi},
  cols = Range[1, start - 1];
  Dk = ConstantArray[0, {Length[rk], start - 1}];
  Do[Dk[[All, blockRows[m] ]] = solved[m], {m, Keys[solved]}];
  A = state["A"]; S = state["S"]; Si = state["SInverse"];
  newA = A;
  Do[
    AD = A[[mu, start ;; n, rk]] . Dk;                       (* rows >= start, cols < start *)
    DA = Dk . A[[mu, cols, cols]];                           (* row k, cols < start *)
    dD = D[Dk, {xx, yy}[[mu]]];
    newA[[mu, start ;; n, cols]] = Map[Together, A[[mu, start ;; n, cols]] + AD, {2}];
    newA[[mu, rk, cols]] = Map[Together, newA[[mu, rk, cols]] - DA - dD, {2}],
    {mu, 2}];
  newS = S; newS[[All, cols]] = Map[Together, S[[All, cols]] + S[[All, rk]] . Dk, {2}];
  newSi = Si; newSi[[rk, All]] = Map[Together, Si[[rk, All]] - Dk . Si[[cols, All]], {2}];
  state = Join[state, <|"A" -> newA, "S" -> newS, "SInverse" -> newSi|>]];

(* ---- the sector loop ---- *)
Do[
 Module[{nk = bounds[[k, 2]], aTrunc, res, directSolved, dk, res2, rowGauge = <||>,
   dk2, sfull, sfullInverse, aPrevious, aNew, secs, remaining,
   stageInverse, stageGauge, newS, newSInverse, sectorCertificate,
   stripCheckpointFile = None},
  log["==== sector ", k, " (rows ", bounds[[k]], ", truncation ", nk, "x", nk, ")"];
  If[stripRoute === "FiniteFieldFirst" && ! algebraicFrameQ && k > 1 && TrueQ[factorTruncated[k - 1]],
    (* the connection changed: a strip checkpoint of this sector computed
       before the transformation is stale (CF265 sector 18, 2026-08-22) *)
    Module[{cp = FileNameJoin[{scratch, family <> "_" <> ToString[k] <> "_strip_state.wl"}]},
      If[FileExistsQ[cp], DeleteFile[cp]; log["  strip checkpoint of sector ", k, " discarded (connection transformed)"]]]];
  aTrunc = toC[{state["A"][[1, 1 ;; nk, 1 ;; nk]],
    state["A"][[2, 1 ;; nk, 1 ;; nk]]}];
  Which[
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
      stripSolvers = {}, transformation, stripCheckpoint,
      checkpointValid, stripInputFile, extraLetters, obstruction},
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
        ListQ[Lookup[stripCheckpoint, "PrevD", None]] &&
        Length[stripCheckpoint["PrevD"]] === subSize &&
        AllTrue[stripCheckpoint["PrevD"], ListQ];
      If[AssociationQ[stripCheckpoint] && ! checkpointValid,
        log["  strip checkpoint of sector ", k, " ignored (built on another connection)"]];
      If[checkpointValid,
        prevD = toC[stripCheckpoint["PrevD"]];
        stripSolvers = Lookup[stripCheckpoint, "StripSolvers", {}];
        log["  resuming ", Length[stripSolvers],
          " exactly checked strips in sector ", k],
        prevD = Table[{}, {subSize}]];
      (* solved blocks of this row, j -> D_{kj}, recovered from the
         checkpoint's prevD (blocks are prepended: the first solved is
         j = k - 1) *)
      solvedBlocks = Module[{len = Length[prevD[[1]]], assoc = <||>, m = k - 1, col},
        col = len;
        While[col > 0 && m >= 1,
          assoc[m] = fromC[prevD][[All, col - Length[blockRows[m]] + 1 ;; col]];
          col -= Length[blockRows[m]]; m--];
        assoc];
      While[Length[prevD[[1]]] + subSize =!= nk,
        If[stripRoute === "FiniteFieldFirst" && ! algebraicFrameQ,
          nlow = k - 1 - Length[solvedBlocks];
          {e, c, bbar} = blockEquation[k, nlow, solvedBlocks];
          nextEq = True,
          nextEq = canonicaNextEq[aP, invariants, sb, prevD];
          If[! ListQ[nextEq] || First[nextEq] === False,
            log["  !! NextEquationD could not construct the next strip"];
            putAtomic[state, stateFile]; Exit[2]];
          {e, c, bbar, nlow} = {
            fromC[nextEq[[1]]], fromC[nextEq[[2]]],
            fromC[nextEq[[3]]], nextEq[[5]]}];
        stripInputFile = FileNameJoin[{scratch,
          family <> "_" <> ToString[k] <> "_" <> ToString[nlow] <>
            "_input.wl"}];
        putAtomic[
          <|"Family" -> family, "Sector" -> k,
            "LowerSector" -> nlow, "Variables" -> invariants,
            "Regulator" -> ee, "Strip" -> {e, c, bbar}|>,
          stripInputFile];
        If[Environment["FACET_RECORD_STRIP_ONLY"] === "True",
          log["  recorded strip ", {k, nlow}, " at ", stripInputFile];
          putAtomic[state, stateFile];
          Exit[75]
        ];
        log["  strip ", {k, nlow}, ": ", Which[
          algebraicFrameQ && frameFiniteFieldFirstQ,
            "targeted chart; dlog recognition then finite field",
          algebraicFrameQ || stripRoute === "Legacy",
            "degrees 0,1,2,3; Maple only if all fail",
          True, "finite field"]];
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
          "FinalCheck" -> If[productionQ, "Numerical", "Exact"],
          "Verbose" -> True];
        solvedQ[s_] := AssociationQ[s] && Lookup[s, "Status", None] === "Solved" &&
          (TrueQ[Lookup[s, "ExactDLog", False]] ||
            (productionQ && Lookup[s, "Certificate", None] === "NumericalResidual"));
        If[! algebraicFrameQ && stripRoute === "FiniteFieldFirst",
          (* no dlog recognition through CANONICA's checker: it hung for
             15 min at full CPU on 2x2 blocks of CF360/CF215 (2026-08-22);
             the finite-field solve finds the trivial gauge in seconds *)
          solution = finiteFieldSolve[];
          If[! solvedQ[solution],
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
        If[algebraicFrameQ || stripRoute === "Legacy",
        solution = If[algebraicFrameQ,
          FeynFacet`SolveEpsFormStripInFrame[
            {e, c, bbar}, invariants, ee, chart,
            "CANONICANumeratorDegrees" ->
              If[frameFiniteFieldFirstQ, {}, {0, 1, 2, 3}],
            "CANONICADenominatorDegree" -> 0,
            "CANONICATimeLimit" -> 120,
            "CANONICAKernels" -> kernelCount,
            "MapleLibrary" -> mapleLib,
            "MapleTimeLimit" -> stripMapleBudget,
            "MapleResidueKernels" -> kernelCount,
            "UseMaple" -> ! frameFiniteFieldFirstQ,
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
            "Verbose" -> False]]];
        If[! solvedQ[solution] && ! algebraicFrameQ && stripRoute === "Legacy",
          log["    exact CANONICA/Maple routes found no gauge; " <>
            "starting finite-field reconstruction"];
          solution = finiteFieldSolve[]];
        If[! solvedQ[solution],
          log["  !! no exact gauge for strip ", {k, nlow}];
          putAtomic[
            <|"Family" -> family, "Sector" -> k,
              "LowerSector" -> nlow, "Variables" -> invariants,
              "Regulator" -> ee, "Strip" -> {e, c, bbar},
              "ObstructionCertificate" -> If[ValueQ[obstruction] && AssociationQ[obstruction],
                KeyDrop[obstruction, "GaugeSeries"], Missing["NotRun"]]|>,
            FileNameJoin[{scratch,
              family <> "_" <> ToString[k] <> "_" <>
                ToString[nlow] <> "_unsolved.wl"}]];
          putAtomic[state, stateFile]; Exit[2]];
        gauge = solution["Gauge"];
        AppendTo[stripSolvers, stripSolverSummary[solution, k, nlow]];
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
            "StripSolvers" -> stripSolvers|>,
          stripCheckpointFile];
      ];
      rowGauge = solvedBlocks;
      transformation = If[stripRoute === "FiniteFieldFirst" && ! algebraicFrameQ, None, canonicaInsertD[sb, prevD]];
      (* CANONICA's TransformDE (the transformed truncated connection,
         fully symbolic) fed only the per-sector TransformDlogToEpsForm,
         which the finite-field-first route no longer runs; on CF385
         sector 31 (41x41) it allocated >36 GB and took the WSL VM down
         (2026-08-22).  The connection is transformed below blockwise. *)
      res = {transformation, If[stripRoute === "FiniteFieldFirst" && ! algebraicFrameQ, None,
        canonicaTransformDE[aP, invariants, transformation]]};
      state["StripSolvers"] = Join[state["StripSolvers"], stripSolvers];
      log["  sector ", k, " row completed from ", Length[stripSolvers],
        " individually checked strips"]];
  ];

  If[stripRoute === "FiniteFieldFirst" && ! algebraicFrameQ && ! directSolved,
    (* blockwise application of the completed row gauge (no inverse, no
       full-matrix products) *)
    Module[{t0 = AbsoluteTime[]},
      applyRowGauge[k, rowGauge];
      log["  row gauge of sector ", k, " applied blockwise in ", Round[AbsoluteTime[] - t0, 0.1], " s"]];
    stageInverse = Missing["NotRunProduction"]; stageGauge = Missing["NotRunProduction"];
    sectorCertificate = <|"Sector" -> k, "TransformationInverse" -> stageInverse,
      "GaugeIdentity" -> stageGauge, "Exact" -> False, "CheckLevel" -> checkLevel, "Route" -> "Blockwise"|>;
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
  sfull = IdentityMatrix[n]; sfull[[1 ;; nk, 1 ;; nk]] = Together[dk . dk2];
  sfullInverse = Together[Inverse[sfull]];
  aPrevious = state["A"];
  aNew = Table[Map[Together,
    sfullInverse . aPrevious[[mu]] . sfull -
      sfullInverse . D[sfull, {xx, yy}[[mu]]], {2}], {mu, 2}];
  (* Development only: the inverse identity of the sector gauge.  (The
     former stageGauge recomputed the expression that defines aNew and
     subtracted it -- vacuous by construction, two n x n Together passes
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
      "ChartFingerprint", "TDiagonal", "TDiagonalInverse"}],
    <|"Sector" -> k, "S" -> newS, "SInverse" -> newSInverse,
      "A" -> aNew, "StripSolvers" -> state["StripSolvers"],
      "SectorCertificates" ->
        Append[state["SectorCertificates"], sectorCertificate]|>
  ]];
  If[stripRoute === "FiniteFieldFirst" && ! algebraicFrameQ, factorTruncated[k]];
  putAtomic[state, stateFile];
  If[StringQ[stripCheckpointFile] && FileExistsQ[stripCheckpointFile],
    DeleteFile[stripCheckpointFile]];
  remaining = Length[badStrips[state["A"], nb]];
  log["  sector ", k,
    " done; non-eps-factored strips remaining (all sectors): ", remaining]],
 {k, Max[2, state["Sector"] + 1], nb}];

(* ---- family-level regulator factorization (FiniteFieldFirst route) ---- *)
If[stripRoute === "FiniteFieldFirst" && ! algebraicFrameQ &&
    ! (epsFormQ[state["A"][[1]]] && epsFormQ[state["A"][[2]]]),
  Module[{factor, tFull, tInv},
    log["family connection has regulator-dependent residues; FactorFamilyRegulatorDependence"];
    factor = FeynFacet`FactorFamilyRegulatorDependence[state["A"], {xx, yy}, ee,
      "TimeLimit" -> sectorBudget, "Verbose" -> True];
    If[AssociationQ[factor] && factor["Status"] === "OK",
      tFull = factor["Transformation"]; tInv = factor["Inverse"];
      state = Join[state, <|"A" -> factor["Connection"],
        "S" -> Together[state["S"] . tFull], "SInverse" -> Together[tInv . state["SInverse"]],
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
  Length[state["SectorCertificates"]] === Max[0, nb - 1] &&
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
  finalInverse = zeroQ[S . Sinv - IdentityMatrix[n]] &&
    zeroQ[Sinv . S - IdentityMatrix[n]];
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
  "Status" -> Which[verdict === True, "ExactEpsilonForm",
    verdict === "DeferredToFamilyCertificate", "CandidateEpsilonForm",
    True, "Incomplete"],
  "CheckLevel" -> checkLevel,
  "WallSeconds" -> AbsoluteTime[] - start,
  "Provenance" -> "Complete-sector CANONICA first. For an unresolved sector, CANONICA NextEquationD constructs each strip; numerator degrees 0,1,2,3 are searched concurrently, followed only when needed by exact Maple rational gauges from IntegrableConnections or a strip-letter denominator ansatz. Mathematica checks every strip in both variables and then checks the complete family gauge identity, flatness, and epsilon factorization."|>;
putAtomic[out, FileNameJoin[{outdir, "family_epsform_" <> family <> ".wl"}]];
log["written family_epsform_", family, ".wl; GateVerdict ", verdict, "; wall ", Round[AbsoluteTime[] - start], " s"];
If[ownedKernels =!= {}, Quiet[CloseKernels[ownedKernels]]];
Exit[If[verdict === True || verdict === "DeferredToFamilyCertificate", 0, 1]]
