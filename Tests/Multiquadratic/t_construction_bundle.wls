#!/usr/bin/env wolframscript
(* THE PRE-CANCELLATION DEFERRED BUNDLE (round 3 A3; Codex
   codex_round3_detailed_fix_instructions_2026-08-26.md section A3).

   THE DEFECTS THIS WAVE CLOSES, demonstrated red on the pre-fix code
   (scratchpad round3/a3_prefix_red_probe.log, 2026-08-26): divisor
   metadata was computed from Together of the MATERIALIZED inhomogeneity, so a
   divisor lost to cancellation was unrecoverable; the public result
   carried no bundle at all; "Roots" -> Automatic manufactured an
   independent generator from every observed radical base
   (Sqrt[d1 d2] became its own root); and blockEquationDeferredInhomogeneity
   always materialized before anything else.

   ACCEPTANCE CRITERIA, stated before the run (the Codex A3 test list):

   (a) CONTRACT AND VALIDATION.  blockEquationDeferredInhomogeneity produces a
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

   (f) A DEPENDENT declared frame is refused with DependentQuadraticRadicands
       BEFORE orbit generation; duplicates with DuplicateQuadraticRadicands.

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
       through) returns the SAME expressions as the unseeded one.

   (l) Exact repeated factor spellings are interned before the semantic
       fallback matcher; the four counters are coherent, and statistics do
       not perturb deterministic mathematical data or numbering. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{inhomogeneityOf, compileBundle, compileWithCache, validate, evaluateBundle,
  targetOrderOf, zeroQ, materialize, rootFrameOf,
  presentationRootsInVariables} =
 mq /@ {"blockEquationDeferredInhomogeneity", "blockEquationDeferredCompileBundle",
   "blockEquationDeferredCompileBundleWithCache",
   "blockEquationDeferredBundleValidate",
   "blockEquationDeferredBundleEvaluate",
   "blockEquationDeferredBundleTargetOrder",
   "blockEquationDeferredAlgebraicZeroQ",
   "blockEquationDeferredMaterialize",
   "blockEquationDeferredValidateSquareRootGenerators",
   "coefficientPresentationSquareRootsInVariables"};

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
deltaRoot = <|"Generator" -> Sqrt[delta],
  "QuadraticRadicand" -> delta, "SourceRadicand" -> delta|>;
algebraicEntry[mu_, i_, j_] := (ge + mu + i gx + j gy)/
  ((2 + gx + Sqrt[delta])^If[mu === 1, 2, 1] (i + j));
algebraicConnection = buildConnection[algebraicEntry];

allTargets[dims_] := Flatten[
  Table[{mu, i, jj}, {mu, dims[[1]]}, {i, dims[[2]]}, {jj, dims[[3]]}], 2];

bundleRoots[bundle_Association] := Module[{allRoots},
  allRoots = presentationRootsInVariables[bundle["CoefficientPresentation"],
    bundle["Variables"]];
  allRoots[[bundle["SquareRootGeneratorIndices"]]]
];

(* ---- (a) contract and validation ------------------------------------ *)
result = inhomogeneityOf[rationalConnection, ranges, 3, 1, solved, {gx, gy}, ge];
FTAssert["(a) the compat mode returns inhomogeneity AND the bundle",
  Lookup[result, "Status", None] === "OK" &&
    AssociationQ[Lookup[result, "DeferredBundle", None]]];
bundle = result["DeferredBundle"];
FTAssert["(a) the bundle carries the V3 schema and explicit coefficient presentation",
  bundle["Schema"] === "BlockEquationDeferredBundleV3" &&
    bundle["SchemaVersion"] === 3 &&
    bundle["Status"] === "PreparedDeferredBundle" &&
    AssociationQ[bundle["CoefficientPresentation"]] &&
    VectorQ[bundle["SquareRootGeneratorIndices"], IntegerQ]];
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
FTAssert["(a) every operand record carries explicit numerator, ordered factor pairs and root mask",
  AllTrue[bundle["OperandTable"], AssociationQ[#] &&
    KeyExistsQ[#, "Numerator"] && ListQ[#["DenominatorFactors"]] &&
    IntegerQ[#["RootMask"]] &]];

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
        result["Inhomogeneity"][[Sequence @@ target]]] === 0]],
    allTargets[bundle["Dimensions"]]]];
point = {gx -> 3/7, gy -> 5/11, ge -> 1/13};
pointEvaluation = evaluateBundle[bundle, point];
FTAssert["(b) rational block: bundle evaluation at an exact rational point \
equals the oracle there",
  pointEvaluation["Status"] === "OK" &&
    And @@ Map[Function[target, TrueQ[Together[
        pointEvaluation["Image"][[Sequence @@ target]] -
          (result["Inhomogeneity"][[Sequence @@ target]] /. point)] === 0]],
      allTargets[bundle["Dimensions"]]]];

(* ---- (b) oracle equality: algebraic block --------------------------- *)
algebraicResult = inhomogeneityOf[algebraicConnection, ranges, 3, 1, solved,
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
          algebraicResult["Inhomogeneity"][[Sequence @@ target]],
        {Together[delta]}]]],
      allTargets[algebraicBundle["Dimensions"]]]];
FTAssert["(b) the algebraic bundle's root frame is the declared one",
  Length[bundleRoots[algebraicBundle]] === 1 &&
    TrueQ[Together[First[bundleRoots[algebraicBundle]]["QuadraticRadicand"] -
      delta] === 0]];

(* ---- (c) provenance survives cancellation --------------------------- *)
(* row 1: base 1/(a+r), feed -(1-a-r)/(a+r) -> the assembled numerator
   is (a+r), the exact cancellation divides it out, the entry is 1 and
   the algebraic divisor's visible spelling is GONE from the inhomogeneity.
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
cancelResult = inhomogeneityOf[cancelConnection, ranges, 3, 1, cancelSolved,
  {gx, gy}, ge, "DivisorRoots" -> {deltaRoot}];
FTAssert["(c) the cancellation fixture builds",
  Lookup[cancelResult, "Status", None] === "OK" &&
    Lookup[cancelResult["DeferredBundle"], "Status", None] ===
      "PreparedDeferredBundle"];
cancelBundle = cancelResult["DeferredBundle"];
FTAssert["(c) the materialized entry no longer carries the algebraic \
divisor's spelling",
  TrueQ[zeroQ[cancelResult["Inhomogeneity"][[1, 1, 1]] - 1, {Together[delta]}]] &&
    FreeQ[cancelResult["Inhomogeneity"][[1, 1, 1]], Sqrt[delta]]];
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
  cancelResult["Inhomogeneity"][[1, 2, 1]] === 0];
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
compositeRoots = {<|"Generator" -> Sqrt[d1],
    "QuadraticRadicand" -> d1, "SourceRadicand" -> d1|>,
  <|"Generator" -> Sqrt[d2], "QuadraticRadicand" -> d2,
    "SourceRadicand" -> d2|>};
compositeEntry[mu_, i_, j_] :=
  (1 + mu gx + Sqrt[d1 d2])/((3 + gx) (1 - gy) (i + j));
compositeConnection = buildConnection[compositeEntry];
compositeResult = inhomogeneityOf[compositeConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "DivisorRoots" -> compositeRoots];
FTAssert["(e) the composite-radical block builds with the two declared \
generators",
  Lookup[compositeResult, "Status", None] === "OK" &&
    Lookup[compositeResult["DeferredBundle"], "Status", None] ===
      "PreparedDeferredBundle"];
compositeBundle = compositeResult["DeferredBundle"];
FTAssert["(e) the root frame holds exactly the two declared generators, \
never a third",
  Length[bundleRoots[compositeBundle]] === 2 &&
    Sort[Together /@ Lookup[bundleRoots[compositeBundle],
      "QuadraticRadicand"]] === Sort[{Together[d1], Together[d2]}]];
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
            (compositeResult["Inhomogeneity"][[Sequence @@ target]] /.
              {Sqrt[d1 d2] -> Sqrt[d1] Sqrt[d2],
               Sqrt[Expand[d1 d2]] -> Sqrt[d1] Sqrt[d2]}),
          {Together[d1], Together[d2]}]]],
        allTargets[compositeBundle["Dimensions"]]]]];

(* ---- (f) dependent and duplicate frames refused before orbits ------- *)
dependentBundle = inhomogeneityOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "Bundle",
  "BundleRoots" -> {<|"Generator" -> Sqrt[gx],
      "QuadraticRadicand" -> gx, "SourceRadicand" -> gx|>,
    <|"Generator" -> Sqrt[gy], "QuadraticRadicand" -> gy,
      "SourceRadicand" -> gy|>,
    <|"Generator" -> Sqrt[gx gy], "QuadraticRadicand" -> gx gy,
      "SourceRadicand" -> gx gy|>}];
FTAssert["(f) a dependent declared frame is the typed DependentQuadraticRadicands, \
with no orbit ever generated",
  Lookup[dependentBundle, "Status", None] === "DependentQuadraticRadicands" &&
    ! KeyExistsQ[dependentBundle, "DivisorSummary"] &&
    ! KeyExistsQ[dependentBundle, "GaloisOrbits"]];
duplicateBundle = inhomogeneityOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "Bundle",
  "BundleRoots" -> {deltaRoot, <|"Generator" -> Sqrt[1 + gx],
    "QuadraticRadicand" -> 1 + gx,
    "SourceRadicand" -> 1 + gx|>}];
FTAssert["(f) a duplicate square is the typed DuplicateQuadraticRadicands",
  Lookup[duplicateBundle, "Status", None] === "DuplicateQuadraticRadicands"];

(* ---- (g) out-of-frame radical; no synthesis without a frame --------- *)
outsideBundle = inhomogeneityOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "Bundle",
  "BundleRoots" -> {<|"Generator" -> Sqrt[1 - gy],
    "QuadraticRadicand" -> 1 - gy,
    "SourceRadicand" -> 1 - gy|>}];
FTAssert["(g) a radical outside the declared square-class span is the typed \
RadicalOutsideDeclaredFrame",
  Lookup[outsideBundle, "Status", None] === "RadicalOutsideDeclaredFrame"];
frameless = inhomogeneityOf[algebraicConnection, ranges, 3, 1, solved,
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
mutatedRoots = ReplacePart[compositeBundle,
  "SquareRootGeneratorIndices" ->
    Reverse[compositeBundle["SquareRootGeneratorIndices"]]];
FTAssert["(i) a reordered generator index list is refused structurally",
  validate[mutatedRoots]["Status"] === "SquareRootGeneratorDataInvalid"];
mutatedCoefficient = ReplacePart[bundle,
  {Key["Jobs"], 1, Key["Terms"], 1, 1} ->
    bundle["Jobs"][[1, "Terms", 1, 1]] + 1];
mutatedCoefficientEvaluation = evaluateBundle[mutatedCoefficient, {}];
FTAssert["(i) direct evaluation detects a changed job coefficient",
  validate[mutatedCoefficient]["Status"] === "BundleValid" &&
    mutatedCoefficientEvaluation["Status"] === "OK" &&
    mutatedCoefficientEvaluation["Image"] =!= evaluation["Image"]];
mutatedNumerator = ReplacePart[bundle,
  {Key["OperandTable"], 1, Key["Numerator"]} ->
    bundle["OperandTable"][[1, "Numerator"]] + 1];
mutatedNumeratorEvaluation = evaluateBundle[mutatedNumerator, {}];
FTAssert["(i) direct evaluation detects a changed operand numerator",
  validate[mutatedNumerator]["Status"] === "BundleValid" &&
    mutatedNumeratorEvaluation["Status"] === "OK" &&
    mutatedNumeratorEvaluation["Image"] =!= evaluation["Image"]];

(* ---- (j) the early-bundle path never materializes ------------------- *)
oracleInvoked = False;
injectedOracle = Function[{},
  (oracleInvoked = True; <|"Status" -> "InjectedOracleInvoked"|>)];
earlyBundle = inhomogeneityOf[rationalConnection, ranges, 3, 1, solved, {gx, gy},
  ge, "Output" -> "Bundle", "MaterializeFunction" -> injectedOracle];
FTAssert["(j) Output -> Bundle returns the bundle and never calls the \
materializer (injected oracle untouched)",
  Lookup[earlyBundle, "Status", None] === "PreparedDeferredBundle" &&
    oracleInvoked === False &&
    validate[earlyBundle]["Status"] === "BundleValid"];
FTAssert["(j) the early bundle carries the census in its statistics",
  AssociationQ[earlyBundle["Statistics"]["Census"]] &&
    KeyExistsQ[earlyBundle["Statistics"], "ZeroInhomogeneityCandidateQ"]];
oracleInvoked = False;
adaptiveBundle = inhomogeneityOf[rationalConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "BundleOrMaterialized",
  "MaterializeFunction" -> injectedOracle];
FTAssert["(j) BundleOrMaterialized returns a witnessed-nonzero bundle and \
does not invoke the materializer",
  Lookup[adaptiveBundle, "Status", None] === "PreparedDeferredBundle" &&
    TrueQ[! adaptiveBundle["Statistics"]["ZeroInhomogeneityCandidateQ"]] &&
    oracleInvoked === False];
framelessInvoked = inhomogeneityOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "BundleOrMaterialized",
  "MaterializeFunction" -> injectedOracle];
FTAssert["(j) a typed bundle refusal on the adaptive path also never \
materializes",
  Lookup[framelessInvoked, "Status", None] === "DeferredRootFrameRequired" &&
    oracleInvoked === False];
oracleInvoked = False;
adaptiveMaterialized = inhomogeneityOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "BundleOrMaterialized",
  "BundleRoots" -> {deltaRoot}, "MaterializeFunction" -> injectedOracle];
FTAssert["(j) BundleOrMaterialized invokes the exact materializer after an \
inconclusive algebraic census",
  oracleInvoked === True &&
    Lookup[adaptiveMaterialized, "Status", None] ===
      "InjectedOracleInvoked"];
adaptiveAlgebraic = inhomogeneityOf[algebraicConnection, ranges, 3, 1, solved,
  {gx, gy}, ge, "Output" -> "BundleOrMaterialized",
  "BundleRoots" -> {deltaRoot}, "Progress" -> False];
adaptiveAlgebraicBundle = adaptiveAlgebraic["DeferredBundle"];
adaptiveAlgebraicEvaluation = evaluateBundle[adaptiveAlgebraicBundle, {}];
FTAssert["(j) adaptive exact materialization preserves inhomogeneity and explicit bundle data",
  Lookup[adaptiveAlgebraic, "Status", None] === "OK" &&
    adaptiveAlgebraic["Inhomogeneity"] === algebraicResult["Inhomogeneity"] &&
    validate[adaptiveAlgebraicBundle]["Status"] === "BundleValid" &&
    adaptiveAlgebraicBundle["CoefficientPresentation"] ===
      algebraicBundle["CoefficientPresentation"] &&
    adaptiveAlgebraicBundle["SquareRootGeneratorIndices"] ===
      algebraicBundle["SquareRootGeneratorIndices"] &&
    adaptiveAlgebraicEvaluation["Status"] === "OK" &&
    adaptiveAlgebraicEvaluation["Image"] === algebraicEvaluation["Image"]];
oracleInvoked = False;
compatControl = inhomogeneityOf[rationalConnection, ranges, 3, 1, solved, {gx, gy},
  ge, "Output" -> "BundleAndMaterialized",
  "MaterializeFunction" -> injectedOracle];
FTAssert["(j) negative control: the compat mode DOES reach the injected \
oracle",
  oracleInvoked === True &&
    Lookup[compatControl, "Status", None] === "InjectedOracleInvoked"];
FTAssert["(j) an unknown output mode is the typed InvalidOutputMode",
  Lookup[inhomogeneityOf[rationalConnection, ranges, 3, 1, solved, {gx, gy}, ge,
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

(* The chartless compiler uses the same immutable canonical-operand worker
   as materialization.  Injected dispatchers exercise scheduling and local
   recovery without requiring a pool in this suite. *)
bundleInternDispatcher[data_Association, batchList_List] := Map[
  Function[batch, Map[
    mq["blockEquationDeferredCanonicalOperandValue"][#,
      Lookup[data, "PolynomialSymbols", Automatic]] &,
    data["Expressions"][[batch]]]], batchList];
bundleDeadInternDispatcher[data_Association, batchList_List] :=
  ConstantArray[$Failed, Length[batchList]];
{parallelSeedBundle, parallelSeedCache} = compileWithCache[
  preparation, "Roots" -> {}, "Parallel" -> True, "Helpers" -> 3,
  "InternDispatcher" -> bundleInternDispatcher, "Progress" -> False];
FTAssert["(k) bundle parallel interning preserves deterministic content",
  KeyDrop[parallelSeedBundle, "Statistics"] ===
      KeyDrop[seedBundle, "Statistics"] &&
    parallelSeedBundle["OperandTable"] === seedBundle["OperandTable"] &&
    parallelSeedBundle["Jobs"] === seedBundle["Jobs"] &&
    parallelSeedCache === seedCache &&
    Lookup[parallelSeedBundle["Statistics"], "InternRoute", None] ===
      "Parallel"];
{deadSeedBundle, deadSeedCache} = compileWithCache[
  preparation, "Roots" -> {}, "Parallel" -> True, "Helpers" -> 3,
  "InternDispatcher" -> bundleDeadInternDispatcher,
  "Progress" -> False];
FTAssert["(k) failed bundle intern jobs are recomputed on the controller",
  KeyDrop[deadSeedBundle, "Statistics"] ===
      KeyDrop[seedBundle, "Statistics"] &&
    deadSeedBundle["OperandTable"] === seedBundle["OperandTable"] &&
    deadSeedCache === seedCache];

(* ---- (l) exact factor interning -------------------------------------- *)
internStatistics = seedBundle["Statistics"];
FTAssert["(l) exact factor interning reports all four bounded counters",
  And @@ {
    IntegerQ[internStatistics["FactorRegistrationCallCount"]] &&
      internStatistics["FactorRegistrationCallCount"] >=
        internStatistics["DistinctFactors"],
    IntegerQ[internStatistics["FactorExactInternHitCount"]] &&
      0 < internStatistics["FactorExactInternHitCount"] <
        internStatistics["FactorRegistrationCallCount"],
    IntegerQ[internStatistics["FactorFallbackComparisonCount"]] &&
      internStatistics["FactorFallbackComparisonCount"] >= 0,
    NumericQ[internStatistics["FactorMatchSeconds"]] &&
      internStatistics["FactorMatchSeconds"] >= 0
  }];
FTAssert["(l) repeated exact spellings bypass semantic factor comparisons",
  internStatistics["FactorFallbackComparisonCount"] <
    internStatistics["FactorRegistrationCallCount"]
      internStatistics["DistinctFactors"]];
restattedBundle = Append[seedBundle, "Statistics" -> Join[
    seedBundle["Statistics"],
    <|"FactorRegistrationCallCount" -> -1,
      "FactorExactInternHitCount" -> -1,
      "FactorFallbackComparisonCount" -> -1,
      "FactorMatchSeconds" -> -1.|>]];
FTAssert["(l) factor-intern telemetry is outside the validated mathematical bundle",
  KeyDrop[restattedBundle, "Statistics"] ===
      KeyDrop[seedBundle, "Statistics"] &&
    validate[restattedBundle]["Status"] === "BundleValid"];
FTAssert["(l) interning preserves factor numbering and bundle content",
  seedBundle["CoefficientPresentation"] === bundle["CoefficientPresentation"] &&
    seedBundle["SquareRootGeneratorIndices"] ===
      bundle["SquareRootGeneratorIndices"] &&
    seedBundle["DivisorSummary"]["Factors"] ===
      bundle["DivisorSummary"]["Factors"] &&
    seedBundle["Jobs"] === bundle["Jobs"] &&
    seedBundle["DivisorOccurrences"] === bundle["DivisorOccurrences"]];

(* ---- (m) syntactic occurrences are not pole multiplicities --------- *)
FTAssert["(m) adding Plus branches increases provenance, not pole order",
  mq["blockEquationDeferredCanonicalPoleValuation"][<|
    "CanonicalDenominator" -> {{7, 2}},
    "ExplicitNegativePower" -> ConstantArray[{7, 1}, 30]|>] ===
      <|7 -> 2|>];

FTReport[];
