#!/usr/bin/env wolframscript
(* E1 (decision memo 2026-08-17): the CORRECTED Libra retry on an
   assembled family — the cheapest candidate fix for the non-pure
   off-diagonal couplings, endorsed by both Fable Max and Codex.

   All earlier "Libra found nothing" verdicts on this machine are VOID:
   Libra`Projector returns a zero matrix on WL 14.2 unless
   Off[OptionValue::optnf] is set (measured 2026-08-16, recorded in
   CLAUDE.md), and Fuchsify/FactorOut build on it.

   What this script does, per family (one pool mission each):
     1. assemble the family from the certified class forms
        (TransportFamily / TransportFamilyInChart, "MaxWeight" -> 0) in
        the catalog frame — diagonals are then eps-forms, strips are
        exact rational matrices (Fuchsian at finite x; possibly not at
        infinity);
     2. measure the BEFORE state: FuchsianQ in x, per-strip
        eps-factorization (entry/eps eps-free?) and dlog purity;
     3. Fuchsify at infinity in xi = 1/x if needed (finite points are
        already simple poles);
     4. Libra FactorOut[M, x, eps, mu] — Lee's linear eps-factorization
        (the same step that finished class 97) with the OTHER chart
        variable held SYMBOLIC;
     5. if a transformation is returned: apply it to BOTH connection
        components, and gate exactly: every entry/eps eps-free; every
        strip pure dlog with residues constant in x, y AND eps;
        diagonals still eps-forms; the transformation invertible
        (re-multiplied out).
   Every phase is TimeConstrained and every verdict is recorded either
   way — a negative here is a measurement, not a failure of the script.

   Usage: libra_offdiag_retry.wls <family> <outdir> [budgetSeconds]     *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]],
  Get[FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]]];
clearGlobalSymbol[name_String] := ToExpression["Global`" <> name, InputForm,
  Function[symbol, Quiet[Unprotect[symbol]]; ClearAll[symbol], HoldAll]];
Scan[clearGlobalSymbol, {"tau", "s", "u", "p", "x", "y", "xi", "mu"}];

args = Rest[$ScriptCommandLine];
family = args[[1]];
outdir = args[[2]];
budget = If[Length[args] >= 3, ToExpression[args[[3]]], 1500];
(* 4th argument "fermat": route Libra's linear algebra through the Fermat
   CAS (Fermatica, installed 2026-08-17; fer64 in Other_Addon).  Measured
   motivation: plain FactorOut times out at 1500 s on dim >= 18 (CF232)
   and Fuchsify at dim >= 23 -- the two-root wall. *)
useFermat = Length[args] >= 4 && ToLowerCase[args[[4]]] === "fermat";
libraOpts = {};
If[useFermat,
  Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Fermatica", "source", "Fermatica.wl"}]];
  Fermatica`$FermatCMD = FileNameJoin[{root, "Addon", "Other_Addon", "Fermat", "fer64"}];
  (* FUNCTIONAL gate (fsmoke lesson 2026-08-17): a dead Fermat path fails
     SILENTLY -- Libra CheckAborts to Mathematica with only a CPrint line.
     Prove the engine computes before spending the budget.  NOTE: the API
     is Fermatica's F* family; Fer* names belong to FeynHelpers. *)
  If[Fermatica`FTogether[(fchkX^2 - 1)/(fchkX - 1)] =!= 1 + fchkX,
    Print["[libraE1] FATAL: Fermatica functional check failed (FTogether)"];
    Exit[3]];
  libraOpts = {Fermatica`UseFermat -> True};
  Print["[libraE1] Fermat backend ON (functional): ", Fermatica`$FermatCMD]];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];

start = AbsoluteTime[];
log[a___] := Print["[libraE1 ", family, " +", ToString[Round[AbsoluteTime[] - start]],
  "s] ", StringJoin[ToString /@ {a}]];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
xiS = Symbol["Global`xi"]; muS = Symbol["Global`mu"];
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
  "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] && Context[sy] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]], {i, Length[syms]}];
  expr /. rules];
normalizeRegulator[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    sy_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[sy]],
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> ee, {i, Length[syms]}];
  expr /. rules];
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];

(* ---- Libra, with the Projector trap disarmed ----------------------- *)
Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra", "Source", "Libra.m"}]];
Off[OptionValue::optnf];   (* WITHOUT this every balance/projector search is void *)

(* Tripwire (watchdog audit 2026-08-17): Libra latches its Fermat master
   switch at LOAD time (Libra`$LibraUseFermat) and the runtime gate is
   $LibraUseFermat && OptionValue[Fermatica`UseFermat] -- if the switch is
   down, the option is accepted and silently ignored, and the Off above
   would also mask a misspelled option name.  In fermat mode, die in
   seconds rather than burn the full budget proving nothing. *)
If[useFermat,
  If[!TrueQ[Libra`$LibraUseFermat],
    Print["[libraE1] FATAL: fermat requested but Libra`$LibraUseFermat=",
      Libra`$LibraUseFermat, " (Fermatica not on $ContextPath at Libra load)"];
    Exit[3]];
  If[!MemberQ[First /@ Options[Libra`FactorOut], Fermatica`UseFermat],
    Print["[libraE1] FATAL: Fermatica`UseFermat is not an option of Libra`FactorOut"];
    Exit[3]];
  (* End-to-end: the exact branch Libra takes ($LibraUseFermat &&
     OptionValue -> Fermatica`FDet), on a matrix small enough to be free. *)
  Module[{odn = Select[{"Libra`ODet", "Libra`Private`ODet"}, NameQ], dchk},
    If[odn === {},
      Print["[libraE1] FATAL: ODet not found in Libra contexts"]; Exit[3]];
    dchk = ToExpression[First[odn]][{{fchkA, fchkB}, {fchkC, fchkD}},
      Fermatica`UseFermat -> True];
    If[Together[dchk - (fchkA fchkD - fchkB fchkC)] =!= 0,
      Print["[libraE1] FATAL: Libra->Fermat end-to-end check failed"]; Exit[3]]];
  Print["[libraE1] Fermat gate armed: latch True, option verified, engine functional end-to-end"]];

(* ---- assemble ------------------------------------------------------ *)
de = readArtifact[FileNameJoin[{ftData, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
blocks = Table[{a["Rows"], a["ClassID"]}, {a, Select[assignments, #["Family"] === family &]}];
chart = FeynFacet`TransportFamilyChart[family];
system = <|"Family" -> family, "Basis" -> de["BlockBasis"], "Av" -> de["Av"], "Aw" -> de["Aw"]|>;
log["assembling, frame ", If[AssociationQ[chart], chart["Name"], "SourceVW"]];
rec = If[AssociationQ[chart],
  FeynFacet`TransportFamilyInChart[system, chart, "SourceVariables" -> {vv, ww},
    "Regulator" -> ee, "Blocks" -> blocks,
    "FormDirectory" -> FileNameJoin[{ftData, "ClassForms"}],
    "PhysicalValuation" -> 0, "Orders" -> {0, 1},
    "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False],
  FeynFacet`TransportFamily[system, "Variables" -> {vv, ww}, "Regulator" -> ee,
    "Blocks" -> blocks, "FormDirectory" -> FileNameJoin[{ftData, "ClassForms"}],
    "BasePoint" -> {1/4, 1/4}, "PhysicalValuation" -> 0, "Orders" -> {0, 1},
    "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False]];
If[! (AssociationQ[rec] && KeyExistsQ[rec, "Assembly"] && AssociationQ[rec["Assembly"]] &&
      KeyExistsQ[rec["Assembly"], "Ranges"]),
  log["!! assembly failed: ", Lookup[rec, "Status", "?"]];
  putAtomic[<|"Family" -> family, "Status" -> "AssemblyFailed"|>,
    FileNameJoin[{outdir, "libraE1_" <> family <> ".wl"}]];
  Exit[1]];
assembly = rec["Assembly"];
{x1, x2} = If[AssociationQ[chart], chart["Variables"], {vv, ww}];
Ax = assembly["Apv"]; Ay = assembly["Apw"];
ranges = assembly["Ranges"]; nb = Length[ranges]; n = Length[Ax];
log["assembled ", n, "x", n, ", ", nb, " blocks; variables ", {x1, x2}];

(* ---- the BEFORE state ---------------------------------------------- *)
epsFactoredQ[m_] := AllTrue[Flatten[m],
  TrueQ[Together[#] === 0] || FreeQ[Together[#/ee], ee] &];
stripStatus[label_] := Module[{bad = {}},
  Do[
    If[i > j,
      Module[{sub = Ax[[ranges[[i]], ranges[[j]]]]},
        If[! AllTrue[Flatten[sub], TrueQ[Together[#] === 0] &] && ! epsFactoredQ[sub],
          AppendTo[bad, {i, j}]]]],
    {i, nb}, {j, nb}];
  log[label, ": non-eps-factored strips ", bad, " of ",
    Count[Flatten[Table[If[i > j &&
      ! AllTrue[Flatten[Ax[[ranges[[i]], ranges[[j]]]]], TrueQ[Together[#] === 0] &],
      1, Nothing], {i, nb}, {j, nb}]], 1], " nonzero strips"];
  bad];
before = stripStatus["BEFORE"];
fuchsianBefore = Quiet[TimeConstrained[FuchsianQ[Ax, x1], 300, "TimedOut"]];
log["BEFORE: FuchsianQ in ", x1, ": ", fuchsianBefore];

Ttot = IdentityMatrix[n];
applyT[tf_] := (
  Ax = Map[Together, Inverse[tf] . Ax . tf - Inverse[tf] . D[tf, x1], {2}];
  Ay = Map[Together, Inverse[tf] . Ay . tf - Inverse[tf] . D[tf, x2], {2}];
  Ttot = Map[Together, Ttot . tf, {2}]);

(* FactorDependence determines an intertwiner between the residues at
   eps and at the arbitrary reference value mu.  Its C[i] are free
   constants of that intertwiner.  They are basis-normalization freedom,
   not letters of the differential equation.  Leaving them symbolic
   makes every later rational operation much larger.  Distinct nonzero
   integers avoid accidental rank loss; the exact inverse and gauge
   checks below still reject any singular specialization. *)
specializeFactorOut[tf_] := Module[{constants, rules},
  constants = DeleteDuplicates[Cases[tf, _C, Infinity]];
  rules = Thread[constants -> Range[Length[constants]]];
  Map[Together, tf /. rules /. muS -> 1, {2}]
];

(* ---- pole diagnosis: which factors carry rank >= 1 exactly --------- *)
poleTable[] := Module[{factors},
  factors = <||>;
  Do[
    Module[{den = Denominator[Together[e]], fl},
      fl = Select[FactorList[den], ! FreeQ[First[#], x1] &];
      Do[factors[First[f]] = Max[Lookup[factors, Key[First[f]], 0], Last[f]],
        {f, fl}]],
    {e, Flatten[Ax]}];
  factors];
log["pole factors (max multiplicity in any entry): ",
  ToString[InputForm[Normal[poleTable[]]], PageWidth -> 600]];

(* ---- Fuchsify loop: finite points, then infinity, until Fuchsian or
        no progress (measured 2026-08-17: finite higher poles EXIST
        exactly -- the first version skipped the finite pass) ---------- *)
Module[{round = 0, progress = True},
  While[fuchsianBefore =!= True && progress && round < 3,
    round++; progress = False;
    Module[{dnsF, tf, seconds},
      dnsF = Select[Keys[poleTable[]], Exponent[#, x1] >= 1 &];
      {seconds, tf} = AbsoluteTiming[
        Quiet[TimeConstrained[Fuchsify[Ax, x1, dnsF, Sequence @@ libraOpts], budget, "TimedOut"]]];
      log["round ", round, " finite Fuchsify: ",
        If[MatrixQ[tf], "transformation (leaves " <> ToString[LeafCount[tf]] <> ")",
          ToString[tf]], " in ", Round[seconds, 0.1], " s"];
      If[MatrixQ[tf] && ! TrueQ[tf === IdentityMatrix[n]],
        applyT[Map[Together, tf, {2}]]; progress = True]];
    Module[{Axi, tf, seconds},
      Axi = Map[Together, -(Ax /. x1 -> 1/xiS)/xiS^2, {2}];
      {seconds, tf} = AbsoluteTiming[
        Quiet[TimeConstrained[Fuchsify[Axi, xiS, {xiS}, Sequence @@ libraOpts], budget, "TimedOut"]]];
      log["round ", round, " infinity Fuchsify: ",
        If[MatrixQ[tf], "transformation returned", ToString[tf]],
        " in ", Round[seconds, 0.1], " s"];
      If[MatrixQ[tf] && ! TrueQ[tf === IdentityMatrix[n]],
        applyT[Map[Together, tf /. xiS -> 1/x1, {2}]]; progress = True]];
    fuchsianBefore = Quiet[TimeConstrained[FuchsianQ[Ax, x1], 300, "TimedOut"]];
    log["after round ", round, ": FuchsianQ ", fuchsianBefore, "; poles ",
      ToString[InputForm[Normal[poleTable[]]], PageWidth -> 400]]]];

(* ---- Lee's linear eps-factorization: FactorOut --------------------- *)
factorOutResult = "NotAttempted"; factorOutSeconds = 0;
If[fuchsianBefore === True,
  Module[{tf, seconds},
    {seconds, tf} = AbsoluteTiming[
      Quiet[TimeConstrained[FactorOut[Ax, x1, ee, muS, Sequence @@ libraOpts], budget, "TimedOut"]]];
    factorOutSeconds = seconds;
    Which[
      MatrixQ[tf],
        log["FactorOut returned a transformation in ", Round[seconds, 0.1],
          " s (leaves ", LeafCount[tf], ")"];
        tf = specializeFactorOut[tf];
        log["FactorOut normalization fixed: mu -> 1, C[i] -> distinct integers; leaves ",
          LeafCount[tf]];
        applyT[Map[Together, tf, {2}]];
        factorOutResult = "Transformation",
      True,
        log["FactorOut: ", ToString[Short[tf, 2]], " in ", Round[seconds, 0.1], " s"];
        factorOutResult = ToString[Short[tf, 2]]]],
  log["skipping FactorOut: system not Fuchsian in ", x1];
  factorOutResult = "SkippedNotFuchsian"];

(* ---- alternate: the y-side (FactorOut is one-variable) ------------- *)
(* Measured 2026-08-17 (CF124): after the x-side FactorOut every strip is
   eps-factored in Ax but Ay is not -- the transformation was built from
   the x-connection only.  Alternate: Fuchsify + FactorOut in the OTHER
   variable on the transformed pair, up to two rounds. *)
epsFactoredBoth[] := epsFactoredQ[Ax] && epsFactoredQ[Ay];
Module[{round = 0},
  While[factorOutResult === "Transformation" && ! epsFactoredBoth[] && round < 2,
    round++;
    Module[{fy, tf, seconds},
      fy = Quiet[TimeConstrained[FuchsianQ[Ay, x2], 300, "TimedOut"]];
      log["alternate round ", round, ": FuchsianQ in ", x2, ": ", fy];
      If[fy =!= True,
        Module[{dnsF},
          dnsF = DeleteDuplicates[Flatten[Table[
            Select[First /@ FactorList[Denominator[Together[e]]],
              ! FreeQ[#, x2] &], {e, Flatten[Ay]}]]];
          {seconds, tf} = AbsoluteTiming[
            Quiet[TimeConstrained[Fuchsify[Ay, x2, dnsF, Sequence @@ libraOpts], budget, "TimedOut"]]];
          log["  y finite Fuchsify: ", If[MatrixQ[tf], "transformation", ToString[tf]],
            " in ", Round[seconds, 0.1], " s"];
          If[MatrixQ[tf] && ! TrueQ[tf === IdentityMatrix[n]],
            (* applyT differentiates w.r.t. x1/x2 correctly for any tf *)
            applyT[Map[Together, tf, {2}]]];
          Module[{Axi2, tf2},
            Axi2 = Map[Together, -(Ay /. x2 -> 1/xiS)/xiS^2, {2}];
            {seconds, tf2} = AbsoluteTiming[
              Quiet[TimeConstrained[Fuchsify[Axi2, xiS, {xiS}, Sequence @@ libraOpts], budget, "TimedOut"]]];
            log["  y infinity Fuchsify: ", If[MatrixQ[tf2], "transformation",
              ToString[tf2]], " in ", Round[seconds, 0.1], " s"];
            If[MatrixQ[tf2] && ! TrueQ[tf2 === IdentityMatrix[n]],
              applyT[Map[Together, tf2 /. xiS -> 1/x2, {2}]]]]]];
      {seconds, tf} = AbsoluteTiming[
        Quiet[TimeConstrained[FactorOut[Ay, x2, ee, muS, Sequence @@ libraOpts], budget, "TimedOut"]]];
      log["alternate round ", round, " FactorOut in ", x2, ": ",
        If[MatrixQ[tf], "transformation (leaves " <> ToString[LeafCount[tf]] <> ")",
          ToString[Short[tf, 2]]], " in ", Round[seconds, 0.1], " s"];
      If[MatrixQ[tf],
        tf = specializeFactorOut[tf];
        log["  normalization fixed: leaves ", LeafCount[tf]];
        applyT[Map[Together, tf, {2}]]];
      log["alternate round ", round, ": eps-factored x ", epsFactoredQ[Ax],
        ", y ", epsFactoredQ[Ay]]]]];

(* ---- structural gates: triangularity and diagonal eps-forms --------- *)
triangularOK = AllTrue[Flatten[Table[
  If[j > i, Flatten[Ax[[ranges[[i]], ranges[[j]]]]]~Join~
            Flatten[Ay[[ranges[[i]], ranges[[j]]]]], {}],
  {i, nb}, {j, nb}]], TrueQ[Together[#] === 0] &];
log["block-lower-triangularity preserved: ", triangularOK];
diagEpsOK = AllTrue[Flatten[Table[
  {Map[Together[#/ee] &, Ax[[ranges[[i]], ranges[[i]]]], {2}],
   Map[Together[#/ee] &, Ay[[ranges[[i]], ranges[[i]]]], {2}]}, {i, nb}]],
  FreeQ[#, ee] &];
log["diagonal blocks still eps-forms: ", diagEpsOK];

(* ---- the AFTER gate (exact, both variables) ------------------------ *)
after = stripStatus["AFTER"];
allFactored = epsFactoredQ[Ax] && epsFactoredQ[Ay];
log["AFTER: whole connection eps-factored (both components): ", allFactored];
(* dlog purity of the strips where eps-factored: constant residues *)
pureReport = If[allFactored && triangularOK,
  Module[{ok = True, detail = {}},
    Do[
      If[i > j,
        Module[{sx = Map[Together[#/ee] &, Ax[[ranges[[i]], ranges[[j]]]], {2}], letters, rec2},
          If[! AllTrue[Flatten[sx], TrueQ[Together[#] === 0] &],
            letters = DeleteDuplicates[Flatten[
              Select[First /@ Rest[FactorList[Denominator[Together[#]]]],
                 ! FreeQ[#, x1] || ! FreeQ[#, x2] &] & /@ Flatten[sx]]];
            rec2 = AllTrue[Flatten[sx], FreeQ[Together[#], ee] &];
            If[! rec2, ok = False; AppendTo[detail, {i, j}]]]]],
      {i, nb}, {j, nb}];
    <|"AllStripsEpsFree" -> ok, "Residual" -> detail|>],
  <|"AllStripsEpsFree" -> False|>];
log["strip eps-free after division: ", pureReport["AllStripsEpsFree"]];
invOK = If[Ttot === IdentityMatrix[n], True,
  TrueQ[Quiet[TimeConstrained[
    AllTrue[Flatten[Map[Together, Ttot . Inverse[Ttot], {2}] - IdentityMatrix[n]],
      TrueQ[Together[#] === 0] &], 600, False]]]];
log["Ttot invertible (re-multiplied): ", invOK];

(* ---- gauge identity against the ORIGINAL permuted system, and the
        route-2 record when everything holds ------------------------- *)
success = allFactored && TrueQ[pureReport["AllStripsEpsFree"]] && invOK &&
  triangularOK && diagEpsOK;
gaugeOK = False;
If[success,
  Module[{TblkFull, TblkInvFull, TTotal, TTotalInv, A0x, A0y, gx, gy, letters},
    TblkFull = ConstantArray[0, {n, n}]; TblkInvFull = ConstantArray[0, {n, n}];
    Do[
      TblkFull[[ranges[[i]], ranges[[i]]]] = assembly["Forms"][[i]]["T"];
      TblkInvFull[[ranges[[i]], ranges[[i]]]] =
        Lookup[assembly["Forms"][[i]], "TInverse",
          Inverse[assembly["Forms"][[i]]["T"]]],
      {i, nb}];
    TTotal = Map[Together, TblkFull . Ttot, {2}];
    TTotalInv = Map[Together, Inverse[Ttot] . TblkInvFull, {2}];
    A0x = assembly["Av"]; A0y = assembly["Aw"];
    gx = Map[Together, TTotalInv . A0x . TTotal - TTotalInv . D[TTotal, x1] - Ax, {2}];
    gy = Map[Together, TTotalInv . A0y . TTotal - TTotalInv . D[TTotal, x2] - Ay, {2}];
    gaugeOK = AllTrue[Flatten[{gx, gy}], TrueQ[Together[#] === 0] &] &&
      AllTrue[Flatten[Map[Together, TTotal . TTotalInv, {2}] - IdentityMatrix[n]],
        TrueQ[Together[#] === 0] &];
    log["gauge identity vs original permuted system: ", gaugeOK];
    If[gaugeOK,
      letters = DeleteDuplicates[Flatten[Table[
        Select[First /@ Rest[FactorList[Denominator[Together[e]]]],
          (! FreeQ[#, x1] || ! FreeQ[#, x2]) && FreeQ[#, ee] &],
        {e, Flatten[{Ax, Ay}]}]]];
      putAtomic[<|
        "Family" -> family, "Status" -> "CleanedUp", "GateVerdict" -> True,
        "Method" -> "LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)",
        "Frame" -> If[AssociationQ[chart], "Chart", "SourceVW"],
        "Chart" -> If[AssociationQ[chart], chart["Name"], "source (v,w)"],
        "Variables" -> {x1, x2}, "Regulator" -> ee,
        "Dim" -> n, "Ranges" -> ranges, "Blocks" -> assembly["Blocks"],
        "Classes" -> Table[Lookup[assembly["Forms"][[i]], "ClassID", None], {i, nb}],
        "TTotal" -> TTotal, "TTotalInverse" -> TTotalInv, "S" -> Ttot,
        "EpsFormX" -> Ax, "EpsFormY" -> Ay, "Letters" -> letters,
        "Gate" -> <|"EpsFactoredBoth" -> allFactored,
          "Triangular" -> triangularOK, "DiagonalsEpsForm" -> diagEpsOK,
          "TTotalInvertible" -> invOK, "GaugeIdentity" -> gaugeOK|>,
        "WallSeconds" -> AbsoluteTime[] - start, "Date" -> DateString[],
        "Provenance" -> "Scripts/Libra/libra_offdiag_retry.wls; Fuchsify (finite + infinity, both variables) + FactorOut alternating; Off[OptionValue::optnf] set; gauge identity and invertibility verified exactly"|>,
        FileNameJoin[{ftData, "FamilyEpsForms", "family_epsform_" <> family <> ".wl"}]];
      log["FamilyEpsForms record WRITTEN (route-2 consumable)"]]]];

putAtomic[<|
  "Family" -> family, "Frame" -> If[AssociationQ[chart], chart["Name"], "SourceVW"],
  "Status" -> If[success && gaugeOK, "EpsFactored", "NotFactored"],
  "GaugeIdentity" -> gaugeOK,
  "TriangularityPreserved" -> triangularOK, "DiagonalsEpsForm" -> diagEpsOK,
  "Before" -> <|"NonFactoredStrips" -> before, "Fuchsian" -> fuchsianBefore|>,
  "FactorOut" -> <|"Result" -> factorOutResult, "Seconds" -> factorOutSeconds|>,
  "After" -> <|"NonFactoredStrips" -> after, "AllFactored" -> allFactored,
    "Pure" -> pureReport, "TtotInvertible" -> invOK|>,
  "Ttot" -> If[allFactored, Ttot, None],
  "EpsFormX" -> If[allFactored, Ax, None], "EpsFormY" -> If[allFactored, Ay, None],
  "Ranges" -> ranges, "Blocks" -> assembly["Blocks"],
  "WallSeconds" -> AbsoluteTime[] - start, "Date" -> DateString[],
  "Provenance" -> "Scripts/Libra/libra_offdiag_retry.wls (E1, decision memo 2026-08-17); \
Off[OptionValue::optnf] set; verdict is a measurement either way"|>,
  FileNameJoin[{outdir, "libraE1_" <> family <> ".wl"}]];
log["written ", FileNameJoin[{outdir, "libraE1_" <> family <> ".wl"}]];
log["DONE"];
