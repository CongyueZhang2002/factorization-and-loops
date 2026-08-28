#!/usr/bin/env wolframscript
(* THE PRE-CANCELLATION DEFERRED BUNDLE (round 3 A3; Codex
   codex_round3_detailed_fix_instructions_2026-08-26.md section A3).

   THE DEFECTS THIS WAVE CLOSES, demonstrated red on the pre-fix code
   (scratchpad round3/a3_prefix_red_probe.log, 2026-08-26): divisor
   metadata was computed from Together of the MATERIALIZED forcing, so a
   divisor lost to cancellation was unrecoverable; the public result
   carried no bundle at all; "Roots" -> Automatic manufactured an
   independent generator from every observed radical base
   (Sqrt[d1 d2] became its own root); and blockEquationDeferredForcing
   always materialized before anything else.

   ACCEPTANCE CRITERIA, stated before the run (the Codex A3 test list):

   (a) CONTRACT AND VALIDATION.  blockEquationDeferredForcing produces a
       BlockEquationDeferredBundleV2 whose TargetOrder is complete,
       unique and lexicographic, whose Jobs align with it, and which
       passes blockEquationDeferredBundleValidate.  The bundle is plain
       data (no Function, RuleDelayed or held mutable state inside).

   (b) ORACLE EQUALITY.  On a small rational and a small algebraic
       block, evaluating the bundle (each interned operand exactly once,
       jobs assembled from the cached values) equals the old
       materialized oracle entry by entry, symbolically and at an exact
       rational point.

   (c) PROVENANCE SURVIVES CANCELLATION.  An algebraic divisor whose
       visible spelling the exact cancellation removes from the
       materialized entry remains in DivisorOccurrences with full
       target/term/operand provenance.

   (d) COMPLETE CANCELLATION keeps the provenance but claims NO
       certified final pole: EntryPoleOrderUpperBound is recorded, the
       summary is labeled PreCancellationUpperBound, and
       CertifiedEntryPoleOrder is None.

   (e) Sqrt[Delta1 Delta2] is rewritten to the grade {1,2} product of
       the TWO declared generators (shared exact denester, sign fixed);
       no third generator appears anywhere in the bundle.

   (f) A DEPENDENT declared frame is refused with DependentRootSquares
       BEFORE orbit generation; duplicates with DuplicateRootSquares.

   (g) An out-of-frame radical is refused with
       RadicalOutsideDeclaredFrame; algebraic content with no frame at
       all with DeferredRootFrameRequired -- roots are never synthesized.

   (h) ORBIT NORMS: all nonzero grade channels of every recorded norm
       vanish exactly, the grade-zero channel is radical-free, every
       generator sign flip permutes the orbit exactly, and the orbit
       size divides 2^rank.  Recomputed independently here, not read
       back from the certificate alone.

   (i) MUTATION BREAKS VALIDATION: an out-of-bounds operand ID, a
       permuted target order, a reordered root frame and a changed job
       coefficient are each refused with their typed status.

   (j) THE EARLY-BUNDLE PATH NEVER MATERIALIZES: an injected oracle that
       fails if invoked proves "Output" -> "Bundle" does not call the
       materializer.  The adaptive "BundleOrMaterialized" mode likewise
       skips it after a nonzero witness, but invokes it after an
       inconclusive algebraic census; the compat mode invokes it
       unconditionally (negative control).

   (k) The seeded materializer (the compiler's intern pool passed
       through) returns the SAME expressions as the unseeded one. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{forcingOf, compileBundle, compileWithCache, validate, evaluateBundle,
  targetOrderOf, fingerprintOf, zeroQ, materialize, rootFrameOf} =
 mq /@ {"blockEquationDeferredForcing", "blockEquationDeferredCompileBundle",
   "blockEquationDeferredCompileBundleWithCache",
   "blockEquationDeferredBundleValidate",
   "blockEquationDeferredBundleEvaluate",
   "blockEquationDeferredBundleTargetOrder",
   "blockEquationDeferredBundleFingerprint",
   "blockEquationDeferredAlgebraicZeroQ",
   "blockEquationDeferredMaterialize",
   "blockEquationDeferredRootFrame"};

Clear[gx, gy, ge];

(* ---- fixtures: three blocks, one feeder ----------------------------- *)
ranges = {{1}, {2}, {3, 4}};
blockOf[i_] := First[Select[Range[Length[ranges]], MemberQ[ranges[[#]], i] &]];
buildConnection[entryFunction_] := Table[
  Table[If[blockOf[i] < blockOf[j], 0, entryFunction[mu, i, j]],
    {i, 4}, {j, 4}], {mu, 2}];

rationalEntry[mu_, i_, j_] :=
  (ge + mu + i gx + j gy)/((1 + gx)^If[mu === 1, 2, 1] (1 - gy) (i + j));
rationalConnection = buildConnection[rationalEntry];
solved = <|2 -> {{(1 + gx)/(1 - gy)}, {gy/(1 + gx)}}|>;

delta = 1 + gx;
deltaRoot = <|"Root" -> Sqrt[delta], "RootSquare" -> delta|>;
algebraicEntry[mu_, i_, j_] := (ge + mu + i gx + j gy)/
  ((2 + gx + Sqrt[delta])^If[mu === 1, 2, 1] (i + j));
algebraicConnection = buildConnection[algebraicEntry];

allTargets[dims_] := Flatten[
  Table[{mu, i, jj}, {mu, dims[[1]]}, {i, dims[[2]]}, {jj, dims[[3]]}], 2];

(* ---- (a) contract and validation ------------------------------------ *)
result = forcingOf[rationalConnection, ranges, 3, 1, solved, {gx, gy}, ge];
FTAssert["(a) the compat mode returns forcing AND the bundle",
  Lookup[result, "Status", None] === "OK" &&
    AssociationQ[Lookup[result, "DeferredBundle", None]]];
bundle = result["DeferredBundle"];
FTAssert["(a) the bundle carries the V2 schema and status",
  bundle["Schema"] === "BlockEquationDeferredBundleV2" &&
    bundle["Status"] === "PreparedDeferredBundle" &&
    StringQ[bundle["BundleFingerprint"]] &&
    StringQ[bundle["SourceFingerprint"]]];
FTAssert["(a) the bundle passes consumer validation",
  validate[bundle]["Status"] === "BundleValid"];
FTAssert["(a) TargetOrder is complete, unique and lexicographic and Jobs align",
  bundle["TargetOrder"] === targetOrderOf[bundle["Dimensions"]] &&
    DuplicateFreeQ[bundle["TargetOrder"]] &&
    bundle["TargetOrder"] === Sort[bundle["TargetOrder"]] &&
    Length[bundle["Jobs"]] === Length[bundle["TargetOrder"]] &&
    And @@ MapThread[#1["Target"] === #2 &,
      {bundle["Jobs"], bundle["TargetOrder"]}]];
FTAssert["(a) the bundle is plain data: no closures, delayed rules or \
leaked temporary grade symbols",
  FreeQ[bundle, _Function] && FreeQ[bundle, _RuleDelayed] &&
    ! AnyTrue[DeleteDuplicates[Cases[bundle,
        s_Symbol :> SymbolName[Unevaluated[s]], {0, Infinity},
        Heads -> True]],
      StringStartsQ[#, "bedGradeRoot" | "bedOrbitRoot" | "denestRoot"] &]];
FTAssert["(a) every operand record carries numerator, ordered factor pairs, \
root mask and fingerprint",
  AllTrue[bundle["OperandTable"], AssociationQ[#] &&
    KeyExistsQ[#, "Numerator"] && ListQ[#["DenominatorFactors"]] &&
    IntegerQ[#["RootMask"]] && StringQ[#["Fingerprint"]] &]];

(* ---- (b) oracle equality: rational block ---------------------------- *)
evaluation = evaluateBundle[bundle, {}];
FTAssert["(b) symbolic bundle evaluation succeeds and touches each interned \
operand exactly once",
  evaluation["Status"] === "OK" &&
    evaluation["OperandEvaluations"] === Length[bundle["OperandTable"]]];
FTAssert["(b) rational block: bundle evaluation equals the materialized \
oracle entry by entry",
  And @@ Map[Function[target, TrueQ[Together[
      evaluation["Image"][[Sequence @@ target]] -
        result["Forcing"][[Sequence @@ target]]] === 0]],
    allTargets[bundle["Dimensions"]]]];
point = {gx -> 3/7, gy -> 5/11, ge -> 1/13};
pointEvaluation = evaluateBundle[bundle, point];
FTAssert["(b) rational block: bundle evaluation at an exact rational point \
equals the oracle there",
  pointEvaluation["Status"] === "OK" &&
    And @@ Map[Function[target, TrueQ[Together[
        pointEvaluation["Image"][[Sequence @@ target]] -
          (result["Forcing"][[Sequence @@ target]] /. point)] === 0]],
      allTargets[bundle["Dimensions"]]]];

(* ---- (b) oracle equality: algebraic block --------------------------- *)
algebraicResult = forcingOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "DivisorRoots" -> {deltaRoot}];
FTAssert["(b) the algebraic block builds with the declared frame",
  Lookup[algebraicResult, "Status", None] === "OK" &&
    Lookup[algebraicResult["DeferredBundle"], "Status", None] ===
      "PreparedDeferredBundle"];
algebraicBundle = algebraicResult["DeferredBundle"];
algebraicEvaluation = evaluateBundle[algebraicBundle, {}];
FTAssert["(b) algebraic block: bundle evaluation equals the materialized \
oracle over the declared field",
  algebraicEvaluation["Status"] === "OK" &&
    And @@ Map[Function[target, TrueQ[zeroQ[
        algebraicEvaluation["Image"][[Sequence @@ target]] -
          algebraicResult["Forcing"][[Sequence @@ target]],
        {Together[delta]}]]],
      allTargets[algebraicBundle["Dimensions"]]]];
FTAssert["(b) the algebraic bundle's root frame is the declared one",
  Length[algebraicBundle["RootFrame"]["Roots"]] === 1 &&
    TrueQ[Together[algebraicBundle["RootFrame"]["Roots"][[1]][
      "RootSquare"] - delta] === 0]];

(* ---- (c) provenance survives cancellation --------------------------- *)
(* row 1: base 1/(a+r), feed -(1-a-r)/(a+r) -> the assembled numerator
   is (a+r), the exact cancellation divides it out, the entry is 1 and
   the algebraic divisor's visible spelling is GONE from the forcing.
   row 2: base and feed equal -> the entry is exactly 0. *)
aLetter = 2 + gx + Sqrt[delta];
cancelConnection = buildConnection[Function[{mu, i, j}, 0]];
cancelConnection[[1, 3, 1]] = 1/aLetter;
cancelConnection[[1, 4, 1]] = (1 - aLetter)/aLetter;
cancelConnection[[1, 2, 1]] = (1 - aLetter)/aLetter;
cancelConnection[[2, 3, 1]] = (1 + gx)/(1 - gy);
cancelConnection[[2, 4, 1]] = gy/(3 + gx);
cancelConnection[[2, 2, 1]] = 1/(1 - gy);
cancelSolved = <|2 -> {{1}, {1}}|>;
cancelResult = forcingOf[cancelConnection, ranges, 3, 1, cancelSolved,
  {gx, gy}, ge, "DivisorRoots" -> {deltaRoot}];
FTAssert["(c) the cancellation fixture builds",
  Lookup[cancelResult, "Status", None] === "OK" &&
    Lookup[cancelResult["DeferredBundle"], "Status", None] ===
      "PreparedDeferredBundle"];
cancelBundle = cancelResult["DeferredBundle"];
FTAssert["(c) the materialized entry no longer carries the algebraic \
divisor's spelling",
  TrueQ[zeroQ[cancelResult["Forcing"][[1, 1, 1]] - 1, {Together[delta]}]] &&
    FreeQ[cancelResult["Forcing"][[1, 1, 1]], Sqrt[delta]]];
cancelFactors = cancelBundle["DivisorSummary"]["Factors"];
cancelFactor = SelectFirst[cancelFactors,
  TrueQ[#["Algebraic"]] &&
    TrueQ[zeroQ[#["Factor"] - aLetter, {Together[delta]}]] &,
  Missing["NoFactor"]];
FTAssert["(c) the algebraic divisor is still a recorded factor of the bundle",
  ! MissingQ[cancelFactor]];
FTAssert["(c) DivisorOccurrences keep target/term/operand provenance for the \
cancelled entry",
  ! MissingQ[cancelFactor] && Length[Select[
    cancelBundle["DivisorOccurrences"],
    #["FactorIndex"] === cancelFactor["FactorIndex"] &&
      #["Target"] === {1, 1, 1} &]] >= 2];

(* ---- (d) complete cancellation, upper-bound labels only ------------- *)
FTAssert["(d) the completely cancelled entry is exactly zero",
  cancelResult["Forcing"][[1, 2, 1]] === 0];
FTAssert["(d) its divisor provenance is retained",
  ! MissingQ[cancelFactor] && Length[Select[
    cancelBundle["DivisorOccurrences"],
    #["FactorIndex"] === cancelFactor["FactorIndex"] &&
      #["Target"] === {1, 2, 1} &]] >= 2];
FTAssert["(d) the entry pole order is a labeled UPPER BOUND, not a certified \
pole",
  ! MissingQ[cancelFactor] &&
    MemberQ[cancelFactor["EntryPoleOrderUpperBounds"], {{1, 2, 1}, 1}] &&
    cancelFactor["CertifiedEntryPoleOrder"] === None &&
    cancelBundle["DivisorSummary"]["Certification"] ===
      "PreCancellationUpperBound" &&
    cancelBundle["DivisorSummary"]["CertifiedEntryPoleOrders"] === None];

(* ---- (e) Sqrt[Delta1 Delta2] uses the two declared generators ------- *)
d1 = 1 + gx; d2 = 1 + gy;
compositeRoots = {<|"Root" -> Sqrt[d1], "RootSquare" -> d1|>,
  <|"Root" -> Sqrt[d2], "RootSquare" -> d2|>};
compositeEntry[mu_, i_, j_] :=
  (1 + mu gx + Sqrt[d1 d2])/((3 + gx) (1 - gy) (i + j));
compositeConnection = buildConnection[compositeEntry];
compositeResult = forcingOf[compositeConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "DivisorRoots" -> compositeRoots];
FTAssert["(e) the composite-radical block builds with the two declared \
generators",
  Lookup[compositeResult, "Status", None] === "OK" &&
    Lookup[compositeResult["DeferredBundle"], "Status", None] ===
      "PreparedDeferredBundle"];
compositeBundle = compositeResult["DeferredBundle"];
FTAssert["(e) the root frame holds exactly the two declared generators, \
never a third",
  Length[compositeBundle["RootFrame"]["Roots"]] === 2 &&
    Sort[Together /@ Lookup[compositeBundle["RootFrame"]["Roots"],
      "RootSquare"]] === Sort[{Together[d1], Together[d2]}]];
FTAssert["(e) no operand carries the composite radicand: every radical base \
in the bundle is a declared square",
  FreeQ[compositeBundle["OperandTable"], Sqrt[d1 d2]] &&
    AllTrue[Select[DeleteDuplicates[Cases[compositeBundle["OperandTable"],
        Power[b_, e_Rational /; Denominator[e] === 2] :> Together[b],
        {0, Infinity}, Heads -> True]], ! NumericQ[#] &],
      Function[base, TrueQ[Together[base - Together[d1]] === 0] ||
        TrueQ[Together[base - Together[d2]] === 0]]]];
FTAssert["(e) the rewritten operand's active-root mask names both generators",
  AnyTrue[compositeBundle["OperandTable"], #["RootMask"] === 3 &]];
FTAssert["(e) the sign-fixed grade {1,2} rewrite is exact: bundle evaluation \
equals the oracle after the composite rewrite",
  Module[{compositeEvaluation = evaluateBundle[compositeBundle, {}]},
    compositeEvaluation["Status"] === "OK" &&
      And @@ Map[Function[target, TrueQ[zeroQ[
          compositeEvaluation["Image"][[Sequence @@ target]] -
            (compositeResult["Forcing"][[Sequence @@ target]] /.
              {Sqrt[d1 d2] -> Sqrt[d1] Sqrt[d2],
               Sqrt[Expand[d1 d2]] -> Sqrt[d1] Sqrt[d2]}),
          {Together[d1], Together[d2]}]]],
        allTargets[compositeBundle["Dimensions"]]]]];

(* ---- (f) dependent and duplicate frames refused before orbits ------- *)
dependentBundle = forcingOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "Bundle",
  "BundleRoots" -> {<|"Root" -> Sqrt[gx], "RootSquare" -> gx|>,
    <|"Root" -> Sqrt[gy], "RootSquare" -> gy|>,
    <|"Root" -> Sqrt[gx gy], "RootSquare" -> gx gy|>}];
FTAssert["(f) a dependent declared frame is the typed DependentRootSquares, \
with no orbit ever generated",
  Lookup[dependentBundle, "Status", None] === "DependentRootSquares" &&
    ! KeyExistsQ[dependentBundle, "DivisorSummary"] &&
    ! KeyExistsQ[dependentBundle, "GaloisOrbits"]];
duplicateBundle = forcingOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "Bundle",
  "BundleRoots" -> {deltaRoot, <|"Root" -> Sqrt[1 + gx],
    "RootSquare" -> 1 + gx|>}];
FTAssert["(f) a duplicate square is the typed DuplicateRootSquares",
  Lookup[duplicateBundle, "Status", None] === "DuplicateRootSquares"];

(* ---- (g) out-of-frame radical; no synthesis without a frame --------- *)
outsideBundle = forcingOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "Bundle",
  "BundleRoots" -> {<|"Root" -> Sqrt[1 - gy], "RootSquare" -> 1 - gy|>}];
FTAssert["(g) a radical outside the declared square-class span is the typed \
RadicalOutsideDeclaredFrame",
  Lookup[outsideBundle, "Status", None] === "RadicalOutsideDeclaredFrame"];
frameless = forcingOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "Bundle"];
FTAssert["(g) algebraic content with no declared frame is the typed \
DeferredRootFrameRequired, never a synthesized root",
  Lookup[frameless, "Status", None] === "DeferredRootFrameRequired"];

(* ---- (h) orbit norms: channels, sign invariance, orbit size --------- *)
orbits = Join[algebraicBundle["DivisorSummary"]["GaloisOrbits"],
  cancelBundle["DivisorSummary"]["GaloisOrbits"]];
FTAssert["(h) at least one algebraic orbit was recorded",
  Length[orbits] >= 1];
FTAssert["(h) every recorded certificate holds and every norm is radical-free",
  AllTrue[orbits, AllTrue[Values[#["NormCertificate"]], TrueQ] &&
    FreeQ[#["Norm"], Power[_, _Rational]] &]];
FTAssert["(h) recomputed: each norm is exactly the product over the orbit \
members",
  AllTrue[orbits, Function[orbit, TrueQ[zeroQ[
    orbit["Norm"] - Times @@ orbit["Members"], {Together[delta]}]]]]];
FTAssert["(h) recomputed: the generator sign flip permutes each orbit exactly",
  AllTrue[orbits, Function[orbit, AllTrue[orbit["Members"],
    Function[member, AnyTrue[orbit["Members"],
      TrueQ[zeroQ[(member /. Sqrt[delta] -> -Sqrt[delta]) - #,
        {Together[delta]}]] &]]]]]];
FTAssert["(h) each orbit size divides 2^rank",
  AllTrue[orbits, Divisible[2, #["OrbitSize"]] &]];

(* ---- (i) mutation breaks validation --------------------------------- *)
mutatedIDs = ReplacePart[bundle,
  {Key["Jobs"], 1, Key["Terms"], 1, 2, 1} ->
    Length[bundle["OperandTable"]] + 5];
FTAssert["(i) an out-of-bounds operand ID is refused",
  validate[mutatedIDs]["Status"] === "OperandIDOutOfBounds"];
mutatedOrder = Join[bundle, <|"TargetOrder" -> Reverse[bundle["TargetOrder"]],
  "Jobs" -> Reverse[bundle["Jobs"]]|>];
FTAssert["(i) a permuted target order is refused",
  validate[mutatedOrder]["Status"] === "TargetOrderNotLexicographic"];
mutatedRoots = Join[compositeBundle, <|"RootFrame" -> Join[
  compositeBundle["RootFrame"], <|"Roots" -> Reverse[
    compositeBundle["RootFrame"]["Roots"]]|>]|>];
FTAssert["(i) a reordered root frame is refused",
  validate[mutatedRoots]["Status"] === "RootOrderFingerprintMismatch"];
mutatedCoefficient = ReplacePart[bundle,
  {Key["Jobs"], 1, Key["Terms"], 1, 1} -> 2];
FTAssert["(i) a changed job coefficient breaks the recomputed bundle \
fingerprint",
  validate[mutatedCoefficient]["Status"] === "BundleFingerprintMismatch"];
mutatedNumerator = ReplacePart[bundle,
  {Key["OperandTable"], 1, Key["Numerator"]} -> 1 + gx];
FTAssert["(i) a changed operand numerator breaks the recomputed bundle \
fingerprint",
  validate[mutatedNumerator]["Status"] === "BundleFingerprintMismatch"];

(* ---- (j) the early-bundle path never materializes ------------------- *)
oracleInvoked = False;
injectedOracle = Function[{},
  (oracleInvoked = True; <|"Status" -> "InjectedOracleInvoked"|>)];
earlyBundle = forcingOf[rationalConnection, ranges, 3, 1, solved, {gx, gy},
  ge, "Output" -> "Bundle", "MaterializeFunction" -> injectedOracle];
FTAssert["(j) Output -> Bundle returns the bundle and never calls the \
materializer (injected oracle untouched)",
  Lookup[earlyBundle, "Status", None] === "PreparedDeferredBundle" &&
    oracleInvoked === False &&
    validate[earlyBundle]["Status"] === "BundleValid"];
FTAssert["(j) the early bundle carries the census in its statistics",
  AssociationQ[earlyBundle["Statistics"]["Census"]] &&
    KeyExistsQ[earlyBundle["Statistics"], "ZeroForcingCandidateQ"]];
oracleInvoked = False;
adaptiveBundle = forcingOf[rationalConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "BundleOrMaterialized",
  "MaterializeFunction" -> injectedOracle];
FTAssert["(j) BundleOrMaterialized returns a witnessed-nonzero bundle and \
does not invoke the materializer",
  Lookup[adaptiveBundle, "Status", None] === "PreparedDeferredBundle" &&
    TrueQ[! adaptiveBundle["Statistics"]["ZeroForcingCandidateQ"]] &&
    oracleInvoked === False];
framelessInvoked = forcingOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "BundleOrMaterialized",
  "MaterializeFunction" -> injectedOracle];
FTAssert["(j) a typed bundle refusal on the adaptive path also never \
materializes",
  Lookup[framelessInvoked, "Status", None] === "DeferredRootFrameRequired" &&
    oracleInvoked === False];
oracleInvoked = False;
adaptiveMaterialized = forcingOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "BundleOrMaterialized",
  "BundleRoots" -> {deltaRoot}, "MaterializeFunction" -> injectedOracle];
FTAssert["(j) BundleOrMaterialized invokes the exact materializer after an \
inconclusive algebraic census",
  oracleInvoked === True &&
    Lookup[adaptiveMaterialized, "Status", None] ===
      "InjectedOracleInvoked"];
adaptiveAlgebraic = forcingOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "BundleOrMaterialized",
  "BundleRoots" -> {deltaRoot}, "Progress" -> False];
FTAssert["(j) adaptive exact materialization preserves forcing and the \
authenticated bundle fingerprint",
  Lookup[adaptiveAlgebraic, "Status", None] === "OK" &&
    adaptiveAlgebraic["Forcing"] === algebraicResult["Forcing"] &&
    adaptiveAlgebraic["DeferredBundle"]["BundleFingerprint"] ===
      algebraicBundle["BundleFingerprint"]];
oracleInvoked = False;
compatControl = forcingOf[rationalConnection, ranges, 3, 1, solved, {gx, gy},
  ge, "Output" -> "BundleAndMaterialized",
  "MaterializeFunction" -> injectedOracle];
FTAssert["(j) negative control: the compat mode DOES reach the injected \
oracle",
  oracleInvoked === True &&
    Lookup[compatControl, "Status", None] === "InjectedOracleInvoked"];
FTAssert["(j) an unknown output mode is the typed InvalidOutputMode",
  Lookup[forcingOf[rationalConnection, ranges, 3, 1, solved, {gx, gy}, ge,
    "Output" -> "Everything"], "Status", None] === "InvalidOutputMode"];

(* ---- (k) the seeded materializer agrees with the unseeded one ------- *)
preparation = mq["blockEquationDeferredPrepare"][rationalConnection, ranges,
  3, 1, solved, {gx, gy}, ge];
{seedBundle, seedCache} = compileWithCache[preparation, "Roots" -> {}];
materializedSeeded = materialize[preparation, "SeedPool" -> seedCache,
  "Progress" -> False];
materializedPlain = materialize[preparation, "Progress" -> False];
FTAssert["(k) seeding the materializer with the compiler's intern pool \
changes nothing about the values (SameQ)",
  materializedSeeded["Status"] === "OK" &&
    materializedPlain["Status"] === "OK" &&
    materializedSeeded["Values"] === materializedPlain["Values"]];

FTReport[];
