#!/usr/bin/env wolframscript
(* Obstruction promotion: the evidence classifier and the driver's
   negative-contract gate (round-3 A1; Codex detailed instructions
   2026-08-26).

   THE DEFECT (P0).  The round-2 driver could still promote an
   UNCONFIRMED or freshly REFUTED gauge defect to the negative contract:
   the wrapper required only two positive usable results (never that the
   fresh request succeeded), and the driver discarded weakening fresh
   evidence in favour of the earlier two-image result, then hard-coded
   the negative status and strength.

   THE FIX.  One side-effect-free evidence classifier decides every
   screen verdict; the driver returns a negative contract only for the
   exact confirmed status AND a recheck of the confirmation predicate on
   the evidence record itself; failed or contrary fresh evidence is
   never discarded (monotonicity).

   ACCEPTANCE CRITERIA, stated before the run.

   The classifier, on synthetic evidence records.
   E1  {d,0} mixed evidence is SampledConsistent, never an obstruction.
   E2  {d,d,0} likewise.
   E3  All defects positive but zero of the requested fresh images
       generated: Inconclusive, reason FreshEvidenceIncomplete.
   E4  Three generated but only two usable: Inconclusive.
   E5  An unusable fresh image after two configured defects:
       Inconclusive, reason UnusableFreshImage.
   E6  Full evidence, all positive: ConfirmedObstruction.
   E7  FreshRequested 0 with two configured positives: confirmed (the
       documented two-image contract of an explicit zero request).
   E8  One positive configured image: Unconfirmed.
   E9  The driver-side predicate accepts exactly the confirmed record.

   The gauge wrapper, on the synthetic block of the round-2 suite.
   W1  Configured images {d,0} (the second at regulator 0, where the
       residue columns vanish and the gauge alone solves): status
       GaugeScreenInconclusive with reason MixedDefectEvidence -- never
       either obstruction status.  (Pre-fix: ObstructionUnconfirmed.)
   W2  Three configured images {d,d,0}: the same.
   W3  Identical (prime, regulator) pairs count ONCE: two copies of one
       image give ObstructionUnconfirmed, not a two-image obstruction.
       (Pre-fix: the duplicate counted as a second confirmation.)
   W4  A gauge denominator that collapses at EVERY pool regulator value
       generates zero fresh images: with FreshImageCount requested, the
       all-positive configured evidence classifies Inconclusive /
       FreshEvidenceIncomplete, never an obstruction.  (Pre-fix: the
       empty fresh draw left the two-image obstruction standing.)

   The public driver.
   D1  On the W4 block the driver returns Status GaugeScreenInconclusive
       with Confirmed False, NO SolutionContract, NO ContractStrength.
       (Pre-fix: a negative GaugeImageObstruction contract.)
   D2  On a genuine obstruction with a completed fresh draw the driver
       still returns the confirmed negative (round-2 behaviour kept),
       and its record carries the EvidenceRecord the predicate accepted.
   D3  ContractStrength is absent on every nonconfirmed path (checked on
       D1's record).
   D4  The screen-first stop (opt-in) also carries the evidence record
       and only fires confirmed. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 8]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{classify, confirmedQ, gaugeAnsatz, gaugeScreenImages, solve,
  defaultPrimes, defaultValues, defaultFresh, samplePool} =
 {mq["multiquadraticStripScreenEvidenceClassify"],
  mq["multiquadraticStripConfirmedObstructionEvidenceQ"],
  mq["multiquadraticStripGaugeAnsatz"],
  mq["multiquadraticStripGaugeScreenImages"],
  mq["solveEpsFormStripMultiquadratic"],
  mq["$multiquadraticStripDefaultPrimes"],
  mq["$multiquadraticStripDefaultRegulatorValues"],
  mq["$multiquadraticStripDefaultFreshImageCount"],
  mq["$multiquadraticStripRegulatorSamplePool"]};

evidence[defects_, freshReq_, freshGen_, freshUse_, unusable_: {}] := <|
  "ConfiguredRequired" -> 2,
  "ConfiguredUsable" -> Length[defects] - freshUse,
  "FreshRequested" -> freshReq, "FreshGenerated" -> freshGen,
  "FreshUsable" -> freshUse, "Defects" -> defects,
  "UnusableStatuses" -> unusable, "ConfirmationEnabled" -> True|>;
verdictOf[ev_] := Lookup[classify[ev], "Verdict", None];
reasonOf[ev_] := Lookup[classify[ev], "Reason", None];

(* ------------------------------------------------------------------ *)
(* E: the classifier                                                    *)
(* ------------------------------------------------------------------ *)

check["E1 {d,0} is SampledConsistent, never an obstruction",
  verdictOf[evidence[{1, 0}, 0, 0, 0]] === "SampledConsistent" &&
    reasonOf[evidence[{1, 0}, 0, 0, 0]] === "MixedDefectEvidence"];
check["E2 {d,d,0} is SampledConsistent, never an obstruction",
  verdictOf[evidence[{1, 1, 0}, 3, 3, 1]] === "SampledConsistent"];
check["E3 zero of three fresh images generated is Inconclusive / \
FreshEvidenceIncomplete",
  verdictOf[evidence[{1, 1}, 3, 0, 0]] === "Inconclusive" &&
    reasonOf[evidence[{1, 1}, 3, 0, 0]] === "FreshEvidenceIncomplete"];
check["E4 three generated but two usable is Inconclusive",
  verdictOf[evidence[{1, 1, 2, 2}, 3, 3, 2]] === "Inconclusive"];
check["E5 an unusable fresh image is Inconclusive / UnusableFreshImage",
  verdictOf[evidence[{1, 1, 2}, 3, 3, 1, {"BudgetExhausted"}]] ===
      "Inconclusive" &&
    reasonOf[evidence[{1, 1, 2}, 3, 3, 1, {"BudgetExhausted"}]] ===
      "UnusableFreshImage"];
check["E6 full all-positive evidence is ConfirmedObstruction",
  verdictOf[evidence[{1, 1, 2, 3, 1}, 3, 3, 3]] === "ConfirmedObstruction"];
check["E7 FreshRequested 0 with two configured positives is confirmed \
(the explicit two-image contract)",
  verdictOf[evidence[{1, 1}, 0, 0, 0]] === "ConfirmedObstruction"];
check["E8 one positive configured image is Unconfirmed",
  verdictOf[evidence[{1}, 0, 0, 0]] === "Unconfirmed"];
check["E9 the driver-side predicate accepts exactly the confirmed record",
  confirmedQ[<|"EvidenceRecord" -> evidence[{1, 1, 2, 3, 1}, 3, 3, 3]|>] &&
    ! confirmedQ[<|"EvidenceRecord" -> evidence[{1, 1}, 3, 0, 0]|>] &&
    ! confirmedQ[<|"EvidenceRecord" -> evidence[{1, 0}, 0, 0, 0]|>] &&
    ! confirmedQ[<|"Status" -> "GaugeImageObstruction"|>]];

(* ------------------------------------------------------------------ *)
(* the synthetic block of the round-2 obstruction suite                 *)
(* ------------------------------------------------------------------ *)

Clear[ox, oy, oe];
letters = {ox, oy, 1 - ox - oy, 1 + ox + oy};
forms = {Together[D[Log[#1], ox]], Together[D[Log[#1], oy]]} & /@ letters;
zero11 = {{{0}}, {{0}}};
knownGauge = {{(1 + 2 ox - 3 oy + ox oy)/(1 - ox - oy)}};
knownResidues = {{{0}}, {{0}}, {{5/2}}, {{-3}}};
forcing = Table[Map[Together,
    D[knownGauge, {ox, oy}[[mu]]] +
      oe Sum[knownResidues[[a]] forms[[a, mu]], {a, Length[letters]}], {2}],
  {mu, 2}];
record = <|"Family" -> "OBSTRUCTION_DRIVER", "Sector" -> 3,
  "LowerSector" -> 1, "Variables" -> {ox, oy}, "Regulator" -> oe,
  "Strip" -> {zero11, zero11, forcing}|>;
(* letter 3 carries a nonzero residue; removing it is a genuine
   obstruction of the ansatz *)
strippedAnsatz = gaugeAnsatz[record, {}, Drop[forms, {3}], 1 - ox - oy];
check["the synthetic ansatz is built",
  Lookup[strippedAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1"];

{p1, p2} = defaultPrimes;
thirdPrime = NestWhile[NextPrime, NextPrime[10^9],
  Mod[#1, 4] =!= 3 || MemberQ[defaultPrimes, #1] &];

(* ------------------------------------------------------------------ *)
(* W: the gauge wrapper                                                 *)
(* ------------------------------------------------------------------ *)

(* DETERMINISTIC mixed evidence: the dlog(1-x-y) demand of the forcing
   carries the coefficient eps (eps - sv), so at regulator sv it
   vanishes -- the stripped ansatz solves that image exactly (defect 0)
   -- while at every other value it is a genuine unmatched residue
   demand (defect > 0).  sv is chosen outside the configured values. *)
sv = First[Select[{5, 11, 13, 17},
  ! MemberQ[defaultValues, #1] && ! MemberQ[samplePool, #1] &,
  1] ~Join~ {23}];
mixedForcing = Table[Map[Together,
    D[knownGauge, {ox, oy}[[mu]]] +
      oe (oe - sv) (5/2) {{forms[[3, mu]]}} - 3 oe {{forms[[4, mu]]}}, {2}],
  {mu, 2}];
mixedRecord = <|"Family" -> "OBSTRUCTION_DRIVER_MIXED", "Sector" -> 3,
  "LowerSector" -> 1, "Variables" -> {ox, oy}, "Regulator" -> oe,
  "Strip" -> {zero11, zero11, mixedForcing}|>;
mixedAnsatz = gaugeAnsatz[mixedRecord, {}, Drop[forms, {3}], 1 - ox - oy];
check["the mixed-evidence ansatz is built",
  Lookup[mixedAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1"];

mixedTwo = gaugeScreenImages[mixedAnsatz,
  "Images" -> {{p1, defaultValues[[1]]}, {p2, sv}},
  "FreshImageCount" -> 0];
report["W1 mixed {d,0}", KeyTake[mixedTwo,
  {"Status", "Reason", "Defects", "ImageCount"}]];
check["W1 configured {d,0} is GaugeScreenInconclusive / \
MixedDefectEvidence, never an obstruction",
  Lookup[mixedTwo, "Status", None] === "GaugeScreenInconclusive" &&
    Lookup[mixedTwo, "Reason", None] === "MixedDefectEvidence" &&
    MatchQ[mixedTwo["Defects"], {_?Positive, 0}]];

mixedThree = gaugeScreenImages[mixedAnsatz,
  "Images" -> {{p1, defaultValues[[1]]}, {p2, defaultValues[[2]]},
    {thirdPrime, sv}},
  "FreshImageCount" -> 0, "ConfirmObstruction" -> True];
check["W2 configured {d,d,0} is likewise inconclusive, never an obstruction",
  Lookup[mixedThree, "Status", None] === "GaugeScreenInconclusive" &&
    Lookup[mixedThree, "Reason", None] === "MixedDefectEvidence" &&
    MatchQ[mixedThree["Defects"], {_?Positive, _?Positive, 0}]];

duplicated = gaugeScreenImages[strippedAnsatz,
  "Images" -> {{p1, defaultValues[[1]]}, {p1, defaultValues[[1]]}},
  "FreshImageCount" -> 0];
report["W3 duplicated image", KeyTake[duplicated,
  {"Status", "Defects", "ImageCount"}]];
check["W3 identical (prime, regulator) pairs count once: a duplicate is \
not a second confirmation",
  Lookup[duplicated, "Status", None] === "GaugeImageObstructionUnconfirmed" &&
    duplicated["ImageCount"] === 1];

(* a gauge denominator that collapses at EVERY pool regulator value:
   the fresh generator can produce nothing *)
poolKiller = (1 - ox - oy) Product[(oe - v), {v,
  DeleteDuplicates[DeleteCases[samplePool, Alternatives @@ defaultValues]]}];
killedAnsatz = gaugeAnsatz[record, {}, Drop[forms, {3}], poolKiller];
check["the pool-killing ansatz is built",
  Lookup[killedAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1"];
killed = gaugeScreenImages[killedAnsatz, "FreshImageCount" -> 3];
report["W4 zero fresh images generated", KeyTake[killed,
  {"Status", "Reason", "Defects", "ConfiguredImageCount",
   "FreshImageCount", "FreshImageRequest"}]];
check["W4 an empty fresh draw leaves the all-positive configured evidence \
INCONCLUSIVE, never an obstruction",
  Lookup[killed, "Status", None] === "GaugeScreenInconclusive" &&
    Lookup[killed, "Reason", None] === "FreshEvidenceIncomplete" &&
    killed["FreshImageCount"] === 0 &&
    AllTrue[killed["Defects"], IntegerQ[#1] && #1 > 0 &]];
check["W4 the evidence record states the failed draw",
  Lookup[killed["EvidenceRecord"], "FreshRequested", 0] === 3 &&
    Lookup[killed["EvidenceRecord"], "FreshGenerated", -1] === 0];

(* ------------------------------------------------------------------ *)
(* D: the public driver                                                 *)
(* ------------------------------------------------------------------ *)

frame = <|"Name" -> "Round3Rational", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational", "Variables" -> {ox, oy},
  "Subst" -> {ox -> ox, oy -> oy}, "Root" -> None, "RootSquare" -> None,
  "Roots" -> {}|>;
(* the driver's gauge denominator comes from the strip and the letters,
   so the pool-killing denominator must be forced through the ansatz the
   driver builds: the SUPPLIED gauge denominator option *)
drivenInconclusive = solve[record, frame, "OneForms" -> Drop[forms, {3}],
  "GaugeDenominator" -> poolKiller,
  "IntegrabilityScreen" -> False, "DegreeOffsetLadder" -> None,
  "ScreenFirst" -> False,
  "GaugeScreenPointCount" -> 12];
report["D1 driver verdict on the pool-killing block", KeyTake[
  drivenInconclusive, {"Status", "Reason", "Confirmed", "SolutionContract",
    "ContractStrength", "Defects", "FreshImageCount"}]];
check["D1 the driver returns a typed INCONCLUSIVE stop, not a negative \
contract",
  Lookup[drivenInconclusive, "Status", None] === "GaugeScreenInconclusive" &&
    Lookup[drivenInconclusive, "Confirmed", None] === False &&
    Lookup[drivenInconclusive, "SolutionContract", Missing["Absent"]] ===
      Missing["Absent"]];
check["D3 ContractStrength is absent on the nonconfirmed path",
  Lookup[drivenInconclusive, "ContractStrength", Missing["Absent"]] ===
    Missing["Absent"]];
check["D1 the inconclusive record carries the evidence and a resumption \
note",
  AssociationQ[Lookup[drivenInconclusive, "EvidenceRecord", None]] &&
    StringQ[Lookup[drivenInconclusive, "ContractNote", None]] &&
    StringContainsQ[drivenInconclusive["ContractNote"], "NOT completed"]];

drivenConfirmed = solve[record, frame, "OneForms" -> Drop[forms, {3}],
  "IntegrabilityScreen" -> False, "DegreeOffsetLadder" -> None,
  "ScreenFirst" -> False,
  "GaugeScreenPointCount" -> 12];
report["D2 driver verdict on the genuine obstruction", KeyTake[
  drivenConfirmed, {"Status", "Confirmed", "SolutionContract",
    "ContractStrength", "ConfiguredImageCount", "FreshImageCount"}]];
check["D2 a genuine obstruction with a completed fresh draw still returns \
the confirmed negative",
  Lookup[drivenConfirmed, "Status", None] === "GaugeImageObstruction" &&
    Lookup[drivenConfirmed, "Confirmed", None] === True &&
    Lookup[drivenConfirmed, "SolutionContract", None] ===
      "GaugeObstructionWithinAnsatz" &&
    Lookup[drivenConfirmed, "ContractStrength", None] ===
      "HighConfidenceModularObstruction"];
check["D2 the negative carries the evidence record the predicate accepted",
  AssociationQ[Lookup[drivenConfirmed, "EvidenceRecord", None]] &&
    confirmedQ[drivenConfirmed]];

(* D4: the opt-in screen-first stop obeys the same rule -- on the genuine
   obstruction it fires confirmed, with the evidence record attached *)
drivenScreenFirst = solve[record, frame, "OneForms" -> Drop[forms, {3}],
  "IntegrabilityScreen" -> False, "DegreeOffsetLadder" -> None,
  "ScreenFirst" -> True,
  "GaugeScreenPointCount" -> 12];
report["D4 screen-first verdict", KeyTake[drivenScreenFirst,
  {"Status", "Stage", "SolutionContract", "FreshImageCount"}]];
check["D4 the screen-first stop fires only confirmed and carries the \
evidence record",
  Lookup[drivenScreenFirst, "Status", None] === "GaugeImageObstruction" &&
    Lookup[drivenScreenFirst, "Stage", None] === "ScreenFirst" &&
    AssociationQ[Lookup[drivenScreenFirst, "EvidenceRecord", None]] &&
    confirmedQ[drivenScreenFirst]];

Print["t_multiquadratic_obstruction_driver: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
