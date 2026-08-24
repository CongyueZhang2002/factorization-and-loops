#!/usr/bin/env wolframscript
(* Pinned regression tests for two Wolfram/third-party traps this
   repository has paid for.  Both are SILENT: neither raises an error of
   its own, and both turn a correct calculation into a wrong-but-plausible
   one.  They are recorded in CLAUDE.md; this file is what stops them
   from coming back.

   Acceptance criteria, stated before any of them is run.

   L. Libra's internal Check calls on Wolfram 14.2.
      Projector[u, v] = u^T . (v . u^T)^-1 . v and NewDSystem are
      wrapped in Check.  Libra's option forwarding emits benign
      OptionValue::optnf and OptionValue::nodef messages.  Check reads
      either message as failure: Projector returns ConstantArray[0,...]
      and FuchsifyBlock aborts.  Quiet at the CALL site does not help:
      the Check is inside Libra and sees the message first.  The fix is
      to switch off both messages at the LOAD site.
      L1  the package loads through the module's own load site;
      L2  after that load site the message is OFF -- i.e. the guard is
          in OUR code and no caller has to know about it;
      L3  Projector[{{1,0,0,0}}, {{1,1,0,0}}] is the correct rank-1
          projector: the exact matrix, idempotent, rank 1, trace 1.
      The behaviour with the message ON is MEASURED and logged (it is a
      third-party capability boundary, not our contract), never asserted.

   C. CANONICA's context and a later Get.
      ValidateCanonicalForm loads CANONICA, which puts CANONICA` on
      $ContextPath and owns a symbol named eps.  Every artifact read by a
      bare Get AFTER that point acquires CANONICA`eps (and CANONICA`u,
      x, y, ...) rather than the Global` symbols every consumer uses.
      Substitution rules written with Global` symbols then match
      NOTHING, and the resulting check is self-consistency on the wrong
      expression while reporting success.
      C1  control: before CANONICA is loaded, a bare Get of the artifact
          yields Global`eps -- so the test below is not vacuous;
      C2  ValidateCanonicalForm really does run and really does load
          CANONICA (otherwise C3/C4 prove nothing);
      C3  the contexts a bare Get produces afterwards are MEASURED and
          logged;
      C4  the SymbolName-normalizing reader yields Global`eps -- and
          Global`u for the artifact's variable -- with the SAME
          expression content as the control read. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* Print, not WriteString["stdout"]: a mission running on a kernel-pool
   subkernel has its Print output captured in the mission log, while a
   direct write to the stdout stream of the subkernel is lost. *)
log[a___] := Print["[t] ", StringJoin[ToString /@ {a}]];

ftClassForms = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "ClassForms"}];
(* class115 is the fixture because it is small AND written with BARE
   eps and a bare variable u -- exactly the shape the trap acts on. *)
fixture = FileNameJoin[{ftClassForms, "class115.wl"}];
smallForm = FileNameJoin[{ftClassForms, "class1.wl"}];
Scan[If[! FileExistsQ[#], Print["FAIL  missing repository input: ", #]; Exit[1]] &,
  {fixture, smallForm}];

(* Whether a message is switched off, without printing it: Check sees a
   message that is generated, and $Messages -> {} removes the output
   stream so nothing reaches the log.  HoldFirst is not cosmetic -- the
   argument is a MessageName, which evaluates to its template string, and
   Message["a string", ...] then raises a different message and the probe
   would report every message as "on". *)
SetAttributes[messageOnQ, HoldFirst];
messageOnQ[msg_] := Block[{$Messages = {}},
  TrueQ[Check[(Message[msg, "probe", "probe", "probe"]; False), True]]];

(* The reader every consumer in this repository is supposed to use:
   re-key by SymbolName, never by symbol identity.  It is defined HERE,
   before any third-party package joins $ContextPath.

   The rule list is built EXPLICITLY from the symbols actually present
   (the HCTNormalize pattern of Scripts/HardClassToolkit.wl) rather than
   as one inline
       expr /. (s_Symbol /; ... :> Symbol["Global`" <> SymbolName[s]])
   because the inline form was MEASURED, in this kernel and on this
   artifact, to insert its right-hand side UNEVALUATED -- the read came
   back full of literal Symbol[StringJoin["Global`", SymbolName[eps]]]
   instead of Global`eps.  The failure is silent in exactly the way this
   file exists to catch, so the reader here does not rely on that form.
   T2 below measures the inline form on the same input and records the
   verdict rather than asserting it. *)
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x",
  "y", "u", "t", "tau", "sqrtLambda", "gli"};

normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    s_Symbol /; MemberQ[$normalizeNames, SymbolName[s]] &&
      Context[s] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]],
    {i, Length[syms]}];
  expr /. rules];

normalizeSymbolsInline[expr_] := expr /. (s_Symbol /;
    MemberQ[$normalizeNames, SymbolName[s]] &&
    Context[s] =!= "Global`" :> Symbol["Global`" <> SymbolName[s]]);

readArtifact[file_String] := normalizeSymbols[Get[file]];

symbolContexts[expr_] := System`DeleteDuplicates[
  System`Cases[expr, s_System`Symbol :> {System`SymbolName[s], System`Context[s]},
    {0, System`Infinity}, System`Heads -> True]];

(* ------------------------------------------------------------------ C *)

(* The reference expression.  It is read with the context path BLOCKED
   (the canonicalBlocksGetGlobal pattern), which is the one reader whose
   result does not depend on what is already loaded -- and it must be,
   because this file may run on a kernel-pool subkernel that has CANONICA
   loaded from an earlier mission.  Whether it did is measured below. *)
canonicaAlreadyLoaded = MemberQ[$ContextPath, "CANONICA`"];
controlRead = Block[{$Context = "Global`", $ContextPath = {"Global`", "System`"}},
  Get[fixture]];
controlSymbols = symbolContexts[controlRead];
controlEps = Select[controlSymbols, #[[1]] === "eps" &];
log["C1 context-blocked control read, contexts for eps: ", controlEps,
  ";  CANONICA already loaded in this kernel at file start: ",
  canonicaAlreadyLoaded];

FTAssert["C1 control: the context-blocked read of the fixture yields \
Global`eps and Global`u, so the comparison below is against a reference \
that does not depend on what is already loaded",
  controlEps === {{"eps", "Global`"}} &&
    MemberQ[controlSymbols, {"u", "Global`"}]];

validated = FeynFacet`ValidateCanonicalForm[smallForm];
log["C2 ValidateCanonicalForm[", FileNameTake[smallForm], "] -> ", validated,
  ";  CANONICA on $ContextPath: ", MemberQ[$ContextPath, "CANONICA`"],
  ";  CANONICA`eps exists: ", NameQ["CANONICA`eps"]];

FTAssert["C2 ValidateCanonicalForm runs and CANONICA is loaded",
  TrueQ[validated] && NameQ["CANONICA`eps"]];
(* The package loaders RESTORE $ContextPath since 2026-08-20, so the
   trap no longer arms itself -- that fix is itself pinned here.  The
   bare-Get misread below is a Wolfram behaviour, not a loader behaviour,
   so the trap is armed DELIBERATELY for the measurement and disarmed
   right after (2026-08-23; previously this section asserted the leak
   still existed and went red when the loader fix worked). *)
FTAssert["C2' the loaders no longer leak CANONICA onto $ContextPath",
  ! MemberQ[$ContextPath, "CANONICA`"]];
PrependTo[$ContextPath, "CANONICA`"];
afterRead = Get[fixture];
afterSymbols = symbolContexts[afterRead];
log["C3 MEASURED contexts after CANONICA is loaded, bare Get: ",
  Select[afterSymbols, MemberQ[{"eps", "u", "v", "w", "x", "y"}, #[[1]]] &]];

normalizedRead = readArtifact[fixture];
normalizedSymbols = symbolContexts[normalizedRead];
log["C4 contexts after the normalizing reader: ",
  Select[normalizedSymbols, MemberQ[{"eps", "u", "v", "w", "x", "y"}, #[[1]]] &]];

FTAssert["C4 the SymbolName-normalizing reader yields Global`eps (and \
Global`u) after CANONICA has been loaded",
  MemberQ[normalizedSymbols, {"eps", "Global`"}] &&
    MemberQ[normalizedSymbols, {"u", "Global`"}] &&
    ! MemberQ[normalizedSymbols[[All, 2]], "CANONICA`"]];

FTAssert["C4' the normalizer changes only the CONTEXT: the normalized \
read is identical to the context-blocked reference read",
  TrueQ[normalizedRead === controlRead]];

FTAssert["C3' with CANONICA` deliberately on $ContextPath, the bare Get \
misreads: it does NOT give the reference expression",
  ! TrueQ[afterRead === controlRead] &&
    MemberQ[afterSymbols, {"eps", "CANONICA`"}]];
$ContextPath = DeleteCases[$ContextPath, "CANONICA`"];

(* MEASURED, not asserted: the one-inline-rule spelling of the same
   normalization, which several scripts in this tree use.  If it leaves
   Symbol[StringJoin[...]] behind it is silently a no-op and worse. *)
inlineRead = normalizeSymbolsInline[Get[fixture]];
log["T2 MEASURED inline-rule normalizer: equals control read: ",
  TrueQ[inlineRead === controlRead],
  ";  left unevaluated Symbol[StringJoin[...]]: ",
  ! FreeQ[inlineRead, HoldPattern[Symbol[_StringJoin]]]];

(* ------------------------------------------------------------------ L *)

loaded = FeynFacet`Private`masterTransportLoadLibra[root];
log["L1 masterTransportLoadLibra -> ", loaded,
  ";  Libra`PexpExpansion downvalues: ", Length[DownValues[Libra`PexpExpansion]]];

FTAssert["L1 Libra loads through the module's own load site",
  loaded === True && Length[DownValues[Libra`PexpExpansion]] > 0];

FTAssert["L2 the module's LOAD SITE leaves OptionValue::optnf switched \
off, so no caller has to know about the Projector trap",
  messageOnQ[OptionValue::optnf] === False];

(* OptionValue::nodef cannot be interrogated reliably with the generic
   messageOnQ probe on WL 14.2.  Test the owned physical operation
   instead: this rank-one double pole requires FuchsifyBlock to create a
   temporary DSystem, precisely the path that used to abort in
   NewDSystem/HistoryAppend when the benign message reached Check. *)
zLibra = Unique["zLibra"];
fuchsifyInput = {{0, 1/zLibra^2}, {0, 0}};
fuchsifyTransformation = Libra`FuchsifyBlock[fuchsifyInput, zLibra,
  {{1}, {2}}, All, Monitor -> False];
fuchsifyResult = If[MatrixQ[fuchsifyTransformation], Together[
  Inverse[fuchsifyTransformation] . fuchsifyInput . fuchsifyTransformation -
    Inverse[fuchsifyTransformation] . D[fuchsifyTransformation, zLibra]],
  $Failed];
log["L2b FuchsifyBlock transformation: ", fuchsifyTransformation,
  "; transformed system: ", fuchsifyResult];
FTAssert["L2b FuchsifyBlock removes the double pole exactly through \
Libra's NewDSystem path",
  MatrixQ[fuchsifyTransformation] &&
    fuchsifyResult === ConstantArray[0, {2, 2}]];

expected97 = {{1, 1, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}};
projector = Libra`Projector[{{1, 0, 0, 0}}, {{1, 1, 0, 0}}];
log["L3 Projector[{{1,0,0,0}},{{1,1,0,0}}] = ", projector];

FTAssert["L3 Projector returns the correct rank-1 projector: the exact \
matrix u^T (v.u^T)^-1 v, idempotent, rank 1, trace 1",
  MatrixQ[projector] && Dimensions[projector] === {4, 4} &&
    Expand[projector - expected97] === ConstantArray[0, {4, 4}] &&
    Expand[projector . projector - projector] === ConstantArray[0, {4, 4}] &&
    MatrixRank[projector] === 1 && Tr[projector] === 1];

(* MEASURED, not asserted: the third-party behaviour with the message on.
   Pinning a test to a defect's current symptom is only admissible at an
   external capability boundary, and even there the contract we own is
   the one above (L2/L3), so this is recorded as evidence and no more. *)
On[OptionValue::optnf];
withMessageOn = Block[{$Messages = {}}, Libra`Projector[{{1, 0, 0, 0}}, {{1, 1, 0, 0}}]];
Off[OptionValue::optnf];
log["L4 MEASURED with OptionValue::optnf ON: Projector -> ", withMessageOn,
  "  (zero matrix: ", Union[Flatten[withMessageOn]] === {0},
  ";  equal to the correct projector: ",
  Expand[withMessageOn - expected97] === ConstantArray[0, {4, 4}], ")"];
log["L4 the guard is therefore ", If[Union[Flatten[withMessageOn]] === {0},
  "LOAD-BEARING on this Wolfram/Libra version",
  "not reproducing the 2026-08 symptom on this version -- record and re-check"]];

FTAssert["L5 the guard is restored after the probe, so nothing this file \
does leaves the trap armed for a later test in the same kernel",
  messageOnQ[OptionValue::optnf] === False];

FTReport[];
