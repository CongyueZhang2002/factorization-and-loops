#!/usr/bin/env wolframscript
(* CERTIFIED dlog POTENTIALS (round-2 wave item 7; Codex review 1.2 and
   ChatGPT Pro answer 2).

   THE GAP.  An epsilon form needs explicit letters L_a with
   omega_a = dlog L_a.  The engine returned CLOSED one-forms and refused
   to install them, which is honest but only half a contract: the
   provenance certificate it carried proves that a letter and a one-form
   were produced together by this code path from this source -- a hash,
   not a proof.  Both reviews prescribe the same repair: verify the
   relation exactly ONCE per unique (omega, L) pair, unconditionally, and
   cache the verdict by content.

   ACCEPTANCE CRITERIA, stated before the run.

   The relation.
   P1  A genuine pair (L = 1 + x + y, omega = dlog L) is VERIFIED.
   P2  A WRONG pair (that L against dlog of a different letter) is
       REFUSED.  A verifier that accepted everything would pass P1.
   P3  An ALGEBRAIC letter A - Sqrt[delta] with its own dlog is verified:
       the zero test is applied to the DIFFERENCE, so it does not depend
       on Together preserving the algebraic word.
   P4  A one-form with NO letter offered (the Diagonal kind: a closed
       form that is not a dlog) reports "NoPotentialOffered" and is not
       verified.  This is the refusal that must stay.

   The cache.
   P5  Verifying the same pair twice does the work ONCE: the miss count
       rises by one and the hit count by one.
   P6  The cache is keyed by CONTENT, not by expression identity: the
       same pair written differently (an unexpanded vs expanded letter,
       a rearranged one-form) hits the SAME entry.

   The alphabet.
   P7  Every candidate letter record carries a "Potential" verdict, and
       the letter-derived kinds are verified while the Diagonal kind is
       not.
   P8  An unverified diagonal form that is exactly spanned by verified
       dlogs is diagnostic rather than installed; the resulting active
       candidate alphabet is certified.

   The preparation and the terminal contract.
   P9  multiquadraticStripPrepare records the per-letter potentials, the
       certification verdict and its reason.
   P10 A caller that supplies bare one-forms has no letters to verify:
       the verdict is False with reason "OneFormsSuppliedWithoutLetters".
       A closed one-form with no verified potential stays
       non-installable. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 6]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{verify, statistics, reset, pairKey, certifiedQ, candidateLetters, prepare,
  letterOneForm} =
 mq /@ {"multiquadraticStripVerifyPotential",
   "multiquadraticStripPotentialStatistics",
   "multiquadraticStripPotentialCacheReset",
   "multiquadraticStripPotentialPairKey",
   "multiquadraticStripPotentialsCertifiedQ",
   "multiquadraticStripCandidateLetters", "multiquadraticStripPrepare",
   "multiquadraticStripLetterOneForm"};

Clear[px, py, pe];
dlogOf[letter_] := {Together[D[letter, px]/letter],
  Together[D[letter, py]/letter]};

reset[];

(* ---- P1 / P2: the relation ---- *)
good = verify[1 + px + py, dlogOf[1 + px + py], {px, py}, pe];
check["P1 a genuine (one-form, letter) pair is verified",
  Lookup[good, "Status", None] === "PotentialVerified" &&
    TrueQ[good["Verified"]] && StringQ[good["PairKey"]]];
report["P1 verdict", KeyTake[good, {"Status", "Verified", "Cached"}]];

wrong = verify[1 + px + py, dlogOf[1 + px - py], {px, py}, pe];
check["P2 a WRONG pair is refused",
  Lookup[wrong, "Status", None] === "PotentialRefused" &&
    wrong["Verified"] === False];

(* ---- P3: an algebraic letter ---- *)
delta = 1 - 4 px py;
algebraic = 1 + 2 py - Sqrt[delta];
algebraicForm = dlogOf[algebraic];
check["P3 an algebraic letter A - Sqrt[delta] verifies against its own dlog",
  TrueQ[verify[algebraic, algebraicForm, {px, py}, pe]["Verified"]]];
check["P3 and the same algebraic one-form against a DIFFERENT algebraic \
letter is refused",
  ! TrueQ[verify[1 - 2 px py - Sqrt[delta], algebraicForm, {px, py},
    pe]["Verified"]]];

(* ---- P4: a closed form with no letter ---- *)
noLetter = verify[Missing["NotADLog"], {1/px, 1/py}, {px, py}, pe];
check["P4 a one-form with no letter offered is not verified, and says so",
  Lookup[noLetter, "Status", None] === "NoPotentialOffered" &&
    noLetter["Verified"] === False];

(* ---- P5 / P6: the cache ---- *)
reset[];
before = statistics[];
first = verify[1 + px + py, dlogOf[1 + px + py], {px, py}, pe];
middle = statistics[];
second = verify[1 + px + py, dlogOf[1 + px + py], {px, py}, pe];
after = statistics[];
check["P5 the pair is verified once and cached",
  middle["Misses"] === before["Misses"] + 1 &&
    after["Misses"] === middle["Misses"] &&
    after["Hits"] === middle["Hits"] + 1 &&
    TrueQ[second["Cached"]] && ! TrueQ[first["Cached"]]];
report["P5 cache statistics", KeyTake[after,
  {"Hits", "Misses", "Verified", "Refused", "Entries"}]];

(* the SAME pair, written differently: an expanded letter and a one-form
   whose components are algebraically equal but not syntactically so *)
spelledDifferently = Expand[(1 + px + py)];
otherForm = {Together[1/(1 + px + py)], Together[(1 + px + py)^(-1)]};
check["P6 the cache key is CONTENT: the same pair written differently \
hits the same entry",
  pairKey[spelledDifferently, otherForm, {px, py}, pe] ===
    pairKey[1 + px + py, dlogOf[1 + px + py], {px, py}, pe]];
hitsBefore = statistics[]["Hits"];
verify[spelledDifferently, otherForm, {px, py}, pe];
check["P6 and verifying it is a cache HIT, not a second computation",
  statistics[]["Hits"] === hitsBefore + 1];

(* ---- P7 / P8: the alphabet ---- *)
zero11 = {{{0}}, {{0}}};
diagonalE = {{{1/px}}, {{1/py}}};
forcing = {{{pe/(1 + px)}}, {{pe/(1 + py)}}};
record = <|"Family" -> "POTENTIALS", "Sector" -> 2, "LowerSector" -> 1,
  "Variables" -> {px, py}, "Regulator" -> pe,
  "Strip" -> {diagonalE, zero11, forcing}|>;
letters = candidateLetters[record["Strip"], {}, {px, py}, pe, record,
  "RegulatorSampleCount" -> 2];
check["the candidate letter set is built",
  Lookup[letters, "Status", None] === "MultiquadraticCandidateLettersV1"];
records = letters["LetterRecords"];
report["P7 kinds / verified",
  Transpose[{Lookup[records, "Kind", {}],
    Lookup[Lookup[records, "Potential", {}], "Verified", {}]}]];
check["P7 every record carries a Potential verdict",
  AllTrue[records, AssociationQ[Lookup[#1, "Potential", None]] &&
    KeyExistsQ[#1["Potential"], "Verified"] &]];
check["P7 every letter-derived kind is VERIFIED",
  AllTrue[Select[records, Lookup[#1, "Kind", None] =!= "Diagonal" &],
    TrueQ[#1["Potential"]["Verified"]] &]];
check["P7 the Diagonal kind carries no potential and is NOT verified",
  AllTrue[Select[records, Lookup[#1, "Kind", None] === "Diagonal" &],
    ! TrueQ[#1["Potential"]["Verified"]] &]];
diagnostics = Lookup[letters, "DiagnosticRecords", {}];
check["P8 a spanned unverified Diagonal is diagnostic, not installed",
  ! AnyTrue[records, Lookup[#1, "Kind", None] === "Diagonal" &] &&
    AnyTrue[diagnostics,
      Lookup[#1, "Kind", None] === "Diagonal" &&
        TrueQ[Lookup[#1, "Diagnostic", False]] &&
        ListQ[Lookup[#1, "SpannedBy", None]] &]];
check["P8 the installed alphabet is entirely verified and certified",
  certifiedQ[records] === True && letters["PotentialsCertified"] === True];
report["P8 counts", KeyTake[letters,
  {"PotentialsVerified", "PotentialsRefused", "PotentialsCertified"}]];

(* ---- P9 / P10: the preparation ---- *)
frame = <|"Name" -> "Round2Rational", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational", "Variables" -> {px, py},
  "Subst" -> {px -> px, py -> py}, "Root" -> None, "RootSquare" -> None,
  "Roots" -> {}|>;
prepared = prepare[record, frame, "RegulatorSampleCount" -> 2];
check["P9 the preparation records the per-letter potentials and the verdict",
  Lookup[prepared, "Status", None] === "PreparedMultiquadraticStripV1" &&
    MatchQ[Lookup[prepared, "Potentials", None], {___Association}] &&
    BooleanQ[Lookup[prepared, "PotentialsCertified", None]] &&
    StringQ[Lookup[prepared, "PotentialsCertifiedReason", None]]];
report["P9 verdict / reason",
  KeyTake[prepared, {"PotentialsCertified", "PotentialsCertifiedReason",
    "PotentialsUnverifiedKinds"}]];

suppliedForms = letterOneForm[#1, {px, py}] & /@ {1 + px, 1 + py};
preparedBare = prepare[record, frame, "OneForms" -> suppliedForms];
check["P10 bare one-forms have no letters to verify: NOT certified, with \
the reason recorded",
  Lookup[preparedBare, "Status", None] === "PreparedMultiquadraticStripV1" &&
    Lookup[preparedBare, "PotentialsCertified", None] === False &&
    Lookup[preparedBare, "PotentialsCertifiedReason", None] ===
      "OneFormsSuppliedWithoutLetters"];

Print["t_multiquadratic_potentials: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
