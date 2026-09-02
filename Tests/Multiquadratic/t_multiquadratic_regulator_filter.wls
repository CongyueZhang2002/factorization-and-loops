#!/usr/bin/env wolframscript
(* The regulator-free filter of the multiquadratic candidate alphabet
   (round-2 wave item 1; Codex review 2026-08-25 section 1.6).

   THE DEFECT.  multiquadraticStripCandidateLetters admitted a one-form
   into the "regulator-free" basis by testing the SPELLING of the symbols
   it contains -- FreeQ[form, _Symbol?(StringStartsQ[SymbolName[#], "eps"]&)]
   -- instead of the regulator argument the function already receives.
   That is wrong in BOTH directions, and both are production-reachable:

     (a) a regulator that is not spelled eps* is invisible to the test.
         Every package boundary in this repository normalizes regulator
         names by SymbolName because the regulator IS spelled differently
         per package (eps, ep, Epsilon, CANONICA`eps -- CLAUDE.md's
         Wolfram traps).  A block whose record names its regulator `ee`
         therefore let a form such as dlog(1 + ee x) into a basis whose
         whole contract is that its letters are regulator-free, and the
         residues solved against it are then not the residues of the
         claimed system;

     (b) an ordinary symbol that happens to be spelled eps* is thrown
         away.  A kinematic or mass parameter named epsMass is not the
         regulator, and a letter carrying it belongs to the alphabet.

   ACCEPTANCE CRITERIA, stated before the run.  Each is a two-sided
   statement, so the suite fails on the pre-fix code in both directions.

   R1  With the record's regulator named `ee`, a supplied letter
       1 + ee x -- whose one-form carries `ee` -- is REJECTED from the
       candidate set.  (Pre-fix: admitted.)
   R2  With the same record, a supplied letter 1 + epsMass x, where
       epsMass is an ordinary symbol and NOT the regulator, is ADMITTED.
       (Pre-fix: rejected.)
   R3  With the regulator named `eps` (the historical spelling), the
       same two statements hold: 1 + eps x is rejected, 1 + epsMass x is
       admitted.  This is what shows the fix is not a rename.
   R4  The regulator-carrying letter is rejected by the REGULATOR TEST
       and not incidentally: the identical letter with the regulator
       replaced by an ordinary symbol is admitted, everything else
       unchanged.
   R5  No `eps`-spelled symbol-name test survives anywhere in the loaded
       multiquadratic source: a second copy of the defect would be
       invisible to R1-R4. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 6]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

candidateLetters = mq["multiquadraticStripCandidateLetters"];

Clear[qx, qy, ee, eps, epsMass];

(* A rank-0 strip: no roots, flat diagonal, a forcing that is a plain
   rational function of the two chart variables and the regulator.  The
   alphabet layer under test does not care about the block's size, and a
   1x1 block keeps the criteria readable. *)
stripFor[regulator_] := {{{{0}}, {{0}}}, {{{0}}, {{0}}},
  {{{regulator/(1 + qx)}}, {{regulator/(1 + qy)}}}};
recordFor[regulator_] := <|"Family" -> "REGULATOR_FILTER", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {qx, qy}, "Regulator" -> regulator,
  "Strip" -> stripFor[regulator]|>;

lettersFor[regulator_, supplied_List] := Module[{result},
  result = candidateLetters[stripFor[regulator], {}, {qx, qy}, regulator,
    recordFor[regulator], "RegulatorSampleCount" -> 2,
    "AdditionalLetters" -> supplied];
  If[Lookup[result, "Status", None] =!= "MultiquadraticCandidateLettersV1",
    Return[$Failed]];
  result];

(* letters are compared as expressions, up to the overall sign a dlog
   cannot see *)
containsLetterQ[result_, target_] := AnyTrue[
  Lookup[result["LetterRecords"], "Letter", {}],
  Function[letter, TrueQ[Together[letter - target] === 0] ||
    TrueQ[Together[letter + target] === 0]]];

(* ---- R1 / R2: the regulator is named `ee` ---- *)

eeResult = lettersFor[ee, {1 + ee qx, 1 + epsMass qx, 1 + 2 qy}];
check["the candidate set is built with a regulator named ee",
  AssociationQ[eeResult]];
report["ee candidate letters", Lookup[eeResult["LetterRecords"], "Letter", {}]];
report["ee candidate kinds", Lookup[eeResult["LetterRecords"], "Kind", {}]];

check["R1 a letter carrying the regulator `ee` is REJECTED from the \
regulator-free basis",
  AssociationQ[eeResult] && ! containsLetterQ[eeResult, 1 + ee qx]];
check["R2 a NON-regulator symbol spelled epsMass is ADMITTED",
  AssociationQ[eeResult] && containsLetterQ[eeResult, 1 + epsMass qx]];
check["R2 the control letter (neither regulator nor eps-spelled) is admitted",
  AssociationQ[eeResult] && containsLetterQ[eeResult, 1 + 2 qy]];
check["R1 no admitted one-form carries the regulator `ee` at all",
  AssociationQ[eeResult] &&
    FreeQ[Lookup[eeResult["LetterRecords"], "OneForm", {}], ee]];

(* ---- R3: the historical spelling `eps` is the regulator ---- *)

epsResult = lettersFor[eps, {1 + eps qx, 1 + epsMass qx, 1 + 2 qy}];
check["the candidate set is built with a regulator named eps",
  AssociationQ[epsResult]];
report["eps candidate letters",
  Lookup[epsResult["LetterRecords"], "Letter", {}]];
check["R3 a letter carrying the regulator `eps` is rejected",
  AssociationQ[epsResult] && ! containsLetterQ[epsResult, 1 + eps qx]];
check["R3 epsMass is admitted even when the regulator IS spelled eps",
  AssociationQ[epsResult] && containsLetterQ[epsResult, 1 + epsMass qx]];

(* ---- R4: the rejection is the regulator test, not an accident ---- *)

controlResult = lettersFor[ee, {1 + epsMass qx}];
check["R4 the rejected letter is admitted verbatim once its regulator \
symbol is replaced by an ordinary one",
  AssociationQ[controlResult] && containsLetterQ[controlResult, 1 + epsMass qx] &&
    ! containsLetterQ[eeResult, 1 + ee qx]];

(* ---- R5: no surviving spelling test in the loaded source ---- *)

source = Import[FileNameJoin[{root, "FeynFacet", "Private", "EpsForm",
  "MultiquadraticStripSolve.wl"}], "Text"];
(* comments are stripped so the note ABOUT the defect does not count *)
executable = FTTest`FTStripComments[source];
check["R5 no symbol-NAME regulator test survives in the executable source",
  ! StringContainsQ[executable, "StringStartsQ[SymbolName["]];
report["R5 remaining SymbolName occurrences",
  Length[StringPosition[executable, "SymbolName["]]];

Print["t_multiquadratic_regulator_filter: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
