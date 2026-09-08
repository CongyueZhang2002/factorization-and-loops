#!/usr/bin/env wolframscript
repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
outDir = FileNameJoin[{exchange, "cf300_row8_ff_benchmark_xh"}];
resultFile = FileNameJoin[{outDir,
  "cf300_sector8_deferred_eval_diag_v3.wl"}];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{repo, "FeynFacet", "Private",
  "FamilyRowGaugeFiniteField.wl"}]];
End[];
Get[FileNameJoin[{exchange, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchange, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{outDir, "FamilyRowGaugeDeferredPrototype.wl"}]];
pre = FeynFacet`FamilyArtifactRead[FileNameJoin[{exchange,
  "cf300_sector8_solved_snapshot",
  "sector_state_CF300_codex_triple_root.wl"}]];
checkpoint = FeynFacet`FamilyArtifactRead[FileNameJoin[{exchange,
  "cf300_sector8_solved_snapshot", "sector_CF300_codex_triple_root",
  "CF300_8_strip_state.wl"}]];
post = FeynFacet`FamilyArtifactRead[FileNameJoin[{repo,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsSolving", "triple_root_2026-08-23", "CF300",
  "sector_state_CF300_standard.wl"}]];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilon = First[DeleteDuplicates[Cases[{pre["A"], checkpoint["PrevD"]},
  s_Symbol /; SymbolName[s] === "eps", Infinity]]];
rows = pre["Ranges"][[8]]; stop = Last[rows];
lowerColumns = Range[First[rows] - 1];
installedRow = post["A"][[All, rows, lowerColumns]];
deferred = CodexRowGaugeDeferred`ApplyDeferredFutureRowGauge[
  pre["A"], pre["S"], pre["SInverse"], rows, checkpoint["PrevD"],
  variables, installedRow];
rootsNatural = CodexTripleRootStrip`TRCurrentRoots[
  FeynFacet`TransportFamilyChart["CF300"], variables];
prep = FeynFacet`Private`familyRowGaugeFiniteFieldPrepare[
  pre["A"], pre["S"], pre["SInverse"], rows, checkpoint["PrevD"],
  variables, rootsNatural];
roots = prep["CanonicalRoots"];
rootSquares = Lookup[roots, "RootSquare", {}];
firstRecord = First[Select[prep["Records", "Connection"],
  #1["Target"][[2]] > stop &]];
target = firstRecord["Target"];
expression = Extract[deferred["Connection"], target];
prime = 1000003; point = {550663, 659718}; epsilonValue = 7;
rootSquareValues = FeynFacet`Private`familyRowGaugeFFModEvaluate[
    #, Association[Thread[variables -> point]], {}, prime]["Value"] & /@
  rootSquares;
rootValues = FeynFacet`Private`familyRowGaugeFFSquareRoot[#, prime] & /@
  rootSquareValues;
signedRoots = rootValues;
scalarValues = Association[Join[Thread[variables -> point],
  {epsilon -> epsilonValue}]];

compiledDeferred = FeynFacet`Private`familyRowGaugeFFReplaceRoots[
  expression, rootSquares];
privateDeferred = FeynFacet`Private`familyRowGaugeFFModEvaluate[
  compiledDeferred, scalarValues, signedRoots, prime];
privateTerms = FeynFacet`Private`familyRowGaugeFFModEvaluate[
    #1["Expression"], scalarValues, signedRoots, prime] & /@
  firstRecord["Terms"];
privateRecordValue = Mod[Total[Lookup[privateTerms, "Value"]], prime];

directBranched = CodexTripleRootStrip`TRApplyRootBranches[
  expression, roots, signedRoots];
directAfterRules = directBranched /. Normal[scalarValues];
directTogether = Quiet[Check[Together[directAfterRules], $Failed]];
formalRoots = Table[Symbol["CodexCF300DeferredDiag`r" <>
  ToString[index]], {index, Length[roots]}];
template = CodexTripleRootStrip`TRApplyRootBranches[
  expression, roots, formalRoots];
templateAfterRules = template /. Join[Normal[scalarValues],
  Thread[formalRoots -> signedRoots]];
templateTogether = Quiet[Check[Together[templateAfterRules], $Failed]];

describe[value_] := <|
  "Rational" -> MatchQ[value, _Integer | _Rational],
  "RemainingSymbols" -> DeleteDuplicates[Cases[value, s_Symbol :>
    {Context[s], SymbolName[s]}, Infinity]],
  "RemainingHalfPowers" -> DeleteDuplicates[Cases[value,
    Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
      HoldForm[Power[base, exponent]], Infinity]],
  "LeafCount" -> LeafCount[value]|>;
record = <|"Status" -> "OK", "Target" -> target,
  "Prime" -> prime, "Point" -> point, "EpsilonValue" -> epsilonValue,
  "RootSquareValues" -> rootSquareValues, "RootValues" -> rootValues,
  "PrivateDeferred" -> privateDeferred,
  "PrivateRecordValue" -> privateRecordValue,
  "PrivateExpressionMatchesRecord" ->
    Lookup[privateDeferred, "Value", Missing[]] === privateRecordValue,
  "DirectAfterRules" -> describe[directAfterRules],
  "DirectTogether" -> describe[directTogether],
  "TemplateAfterRules" -> describe[templateAfterRules],
  "TemplateTogether" -> describe[templateTogether],
  "DirectEqualsPrivate" -> MatchQ[directTogether, _Integer | _Rational] &&
    Mod[Numerator[directTogether]
      PowerMod[Mod[Denominator[directTogether], prime], -1, prime], prime] ===
      Lookup[privateDeferred, "Value", Missing[]],
  "TemplateEqualsPrivate" -> MatchQ[templateTogether,
      _Integer | _Rational] &&
    Mod[Numerator[templateTogether]
      PowerMod[Mod[Denominator[templateTogether], prime], -1, prime], prime] ===
      Lookup[privateDeferred, "Value", Missing[]]|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["DEFERRED DIAG ", record];
Clear[pre, checkpoint, post, deferred, prep, expression, compiledDeferred,
  directBranched, directAfterRules, directTogether, template,
  templateAfterRules, templateTogether];
Exit[0];
