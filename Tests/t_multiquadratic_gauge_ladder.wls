#!/usr/bin/env wolframscript
(* The SCREEN-VALIDATED DEGREE-OFFSET LADDER of
   FeynFacet/Private/MultiquadraticStripSolve.wl (2026-08-25).

   CF300 (12,9) needs a gauge numerator three degrees above its
   denominator ("DegreeOffset" -> {3,3}); at the default {0,0} the
   full-gauge screen correctly refuses the ansatz.  An unattended
   campaign cannot be told that number per block, so the engine measures
   it: on a CONFIRMED defect it re-runs the SCREEN ONLY at escalating
   offsets and adopts the first one that is consistent at TWO images.

   ACCEPTANCE CRITERIA, stated before the run.

   L1  The environment parse is defensive: "1,1;3,3" (with or without
       spaces) is the ladder {{1,1},{3,3}}; an empty, malformed,
       half-formed or negative value falls back to the built-in ladder
       rather than erroring or half-parsing.
   L2  Automatic reads FACET_MQ_DEGREE_LADDER; the built-in default is
       {{1,1},{2,2},{3,3},{4,4}}; an explicit list overrides both.
   L3  The ladder's own logic, on a synthetic block built from a known
       gauge whose NUMERATOR degree exceeds its denominator degree: the
       adopted offset is the FIRST rung whose screen is consistent at
       two images, every earlier rung carries a defect, and no rung
       after it is measured.  (Which rung passes is a measurement of the
       fixture, not an assertion.)
   L4  A defect that no degree offset can repair -- a residue on a
       letter whose pole is NOT the gauge denominator -- exhausts the
       ladder: the typed "GaugeScreenLadderExhausted" carries a per-rung
       defect record for every rung of the ladder.  The control is run
       with a pinned point count: MEASURED 2026-08-25, at the screen's
       default row margin (minimum rows plus one point) an escalated 1x1
       ansatz INTERPOLATES the sampled points and reports defect 0 with
       no exact gauge behind it, so a small-block negative control is
       only meaningful with rows well above unknowns.
   L5  A rung is the ladder's deadline unit: an already-expired deadline
       returns Status BudgetExhausted with Stage GaugeScreenLadder before
       any rung, and a deadline that expires mid-ladder returns the same
       typed stop with the rungs already measured.
   L6  Driver integration on a synthetic block whose defect no offset
       repairs: the typed GaugeImageObstruction now carries the whole
       ladder's defects, "DegreeOffsetLadder" -> None restores the
       pre-ladder behaviour exactly, and a consistent screen leaves the
       solve on its default path with "AdoptedDegreeOffset" -> {0,0}.
   L7  THE REAL DESCRIPTOR, CF300 (12,9), alphabet and merged
       denominator exactly as the 2026-08-25 evidence records them: the
       ladder walks {1,1} -> {2,2} -> {3,3} and adopts {3,3}.  The
       adoption is a positive result and IS asserted; the per-rung
       defects, ranks and seconds are reported as measured.

   Fixtures: the rank-1 multiquadratic construction of
   Tests/t_solver_budget.wls (a block built from a known gauge), and the
   real CF300 (12,9) descriptor read by repository-relative paths under
   Results/UU_08_10_canonical/FamilyEpsFormsSolving/
   FrozenTestFixtures_2026-08-25/ (immutable copies of live campaign
   inputs; provenance in that directory's README). *)

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 10]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{gaugeAnsatz, gaugeScreen, gaugeScreenImages, ladder, ladderParse,
  ladderFromEnvironment, defaultLadder, solveMultiquadratic, rootOrder,
  candidateLetters, normFactor, mergeDenominator, rationalGaugeDenominator,
  rootCensus, currentRoots} =
 mq /@ {"multiquadraticStripGaugeAnsatz", "multiquadraticStripGaugeScreen",
   "multiquadraticStripGaugeScreenImages",
   "multiquadraticStripGaugeScreenLadder",
   "multiquadraticStripDegreeOffsetLadderParse",
   "multiquadraticStripDegreeOffsetLadder",
   "$multiquadraticStripDefaultDegreeOffsetLadder",
   "solveEpsFormStripMultiquadratic", "multiquadraticStripRootOrder",
   "multiquadraticStripCandidateLetters",
   "multiquadraticStripNormDenominatorFactor",
   "multiquadraticStripMergeGaugeDenominator",
   "multiquadraticRationalGaugeDenominator",
   "multiquadraticStripRootCensus", "transportChartCurrentRoots"};

(* ------------------------------------------------------------------ *)
(* L1-L2: the environment parse                                         *)
(* ------------------------------------------------------------------ *)

builtIn = {{1, 1}, {2, 2}, {3, 3}, {4, 4}};
check["L2 the built-in ladder is the documented one",
  defaultLadder === builtIn];
check["L1 \"1,1;3,3\" parses as that ladder",
  ladderParse["1,1;3,3", builtIn] === {{1, 1}, {3, 3}}];
check["L1 spaces around the separators are accepted",
  ladderParse[" 1 , 1 ; 2,2 ; 3 ,3 ", builtIn] === {{1, 1}, {2, 2}, {3, 3}}];
check["L1 a single rung parses",
  ladderParse["3,3", builtIn] === {{3, 3}}];
check["L1 every malformed value falls back to the default",
  AllTrue[{"", "   ", "1,1;", ";1,1", "1,1;2", "a,b", "1;1", "1,1,1",
      "-1,2", "1.5,2", "1,1 3,3", "{{1,1}}", $Failed, None, 17},
    ladderParse[#1, builtIn] === builtIn &]];
report["L1 parse of a malformed ladder", ladderParse["1,1;", builtIn]];

oldLadderEnvironment = Environment["FACET_MQ_DEGREE_LADDER"];
SetEnvironment["FACET_MQ_DEGREE_LADDER" -> "1,1;3,3"];
check["L2 Automatic reads FACET_MQ_DEGREE_LADDER",
  ladderFromEnvironment[] === {{1, 1}, {3, 3}}];
SetEnvironment["FACET_MQ_DEGREE_LADDER" -> "1,1;oops"];
check["L2 a malformed environment ladder falls back to the default",
  ladderFromEnvironment[] === builtIn];
SetEnvironment["FACET_MQ_DEGREE_LADDER" ->
  If[StringQ[oldLadderEnvironment], oldLadderEnvironment, ""]];

(* ------------------------------------------------------------------ *)
(* L3-L5: the ladder's own logic on synthetic blocks                    *)
(* ------------------------------------------------------------------ *)

Clear[sx, sy, se];
syntheticLetters = {sx, sy, 1 - sx - sy, 1 + sx + sy};
syntheticForms = {Together[D[Log[#1], sx]], Together[D[Log[#1], sy]]} & /@
   syntheticLetters;
syntheticE = {{{2 syntheticForms[[1, 1]]}}, {{2 syntheticForms[[1, 2]]}}};
syntheticC = {{{3 syntheticForms[[2, 1]]}}, {{3 syntheticForms[[2, 2]]}}};
buildSyntheticRecord[gauge_, residues_] := <|
  "Family" -> "SYNTHETIC_LADDER", "Sector" -> 3, "LowerSector" -> 1,
  "Variables" -> {sx, sy}, "Regulator" -> se,
  "Strip" -> {syntheticE, syntheticC, Table[
    Map[Together, D[gauge, {sx, sy}[[mu]]] -
      se (syntheticE[[mu]] . gauge - gauge . syntheticC[[mu]]) +
      se Sum[residues[[a]] syntheticForms[[a, mu]],
        {a, Length[syntheticLetters]}], {2}], {mu, 2}]}|>;

(* L3: a gauge whose numerator has bidegree (3,3) over a denominator of
   bidegree (1,1).  No offset below {2,2} contains it. *)
highGauge = {{(1 + 2 sx - 3 sy + 5 sx^3 sy^3 - 2 sx^2 sy)/(1 - sx - sy)}};
highRecord = buildSyntheticRecord[highGauge, {{{0}}, {{0}}, {{5/2}}, {{-3}}}];
highAnsatz = gaugeAnsatz[highRecord, {}, syntheticForms, 1 - sx - sy];
highBase = gaugeScreenImages[highAnsatz];
check["L3 the high-numerator fixture is a confirmed obstruction at {0,0}",
  Lookup[highBase, "Status", None] === "GaugeImageObstruction" &&
    highBase["ImageCount"] === 2];
{highLadderSeconds, highLadder} = AbsoluteTiming[
   ladder[highAnsatz, "DegreeOffsetLadder" -> builtIn]];
check["L3 the ladder adopts a rung on that fixture",
  Lookup[highLadder, "Status", None] === "GaugeScreenLadderAdopted" &&
    MatchQ[highLadder["AdoptedDegreeOffset"], {_Integer, _Integer}]];
highRungs = Lookup[highLadder, "LadderRungs", {}];
check["L3 the adopted rung is the LAST measured rung and the only consistent one",
  Length[highRungs] >= 1 &&
    Last[highRungs]["DegreeOffset"] === highLadder["AdoptedDegreeOffset"] &&
    Last[highRungs]["Defects"] === {0, 0} &&
    Last[highRungs]["ImageCount"] === 2 &&
    AllTrue[Most[highRungs], AnyTrue[#1["Defects"], #1 > 0 &] &]];
check["L3 the ladder stops at the first passing rung",
  Length[highRungs] === First[Flatten[Position[builtIn,
    highLadder["AdoptedDegreeOffset"]]], 0]];
check["L3 defect 0 is accepted only at two images",
  AllTrue[highRungs, #1["ImageCount"] === 2 &]];
report["L3 ladder walk", {#1["DegreeOffset"], #1["SupportCount"],
  #1["UnknownCount"], #1["Status"], #1["Defects"], #1["Ranks"],
  Round[#1["Seconds"], 0.01]} & /@ highRungs];
report["L3 ladder seconds", Round[highLadderSeconds, 0.01]];

(* L4: the removed letter is 1+sx+sy, whose pole appears NOWHERE else in
   the ansatz -- not in the gauge denominator 1-sx-sy, and not in e or c
   (which carry dlog(sx) and dlog(sy)).  MEASURED 2026-08-25: removing a
   letter that DOES appear in e or c is repairable at a higher numerator
   degree, because eps (e B - B c) reproduces that pole from the gauge
   itself; only a pole no term of the ansatz can produce is a valid
   negative control for this ladder. *)
missingRecord = buildSyntheticRecord[{{(1 + 2 sx - 3 sy)/(1 - sx - sy)}},
   {{{7/3}}, {{0}}, {{5/2}}, {{-3}}}];
missingAnsatz = gaugeAnsatz[missingRecord, {}, Drop[syntheticForms, {4}],
   1 - sx - sy];
(* the point count is pinned well above the default (minimum rows plus
   ONE extra point).  MEASURED here 2026-08-25: at the default margin a
   1x1 block escalated to 25 unknowns and 27 rows is consistent at every
   image -- an enlarged ansatz can INTERPOLATE the sampled points even
   though no exact gauge exists, so a negative control on a small block
   must carry a real row margin.  Real blocks carry it by construction
   (CF300 (12,9) at {2,2}: 2560 rows against 2520 unknowns). *)
{exhaustSeconds, exhausted} = AbsoluteTiming[
   ladder[missingAnsatz, "DegreeOffsetLadder" -> {{1, 1}, {2, 2}, {3, 3}},
     "PointCount" -> 40]];
check["L4 a defect no offset can repair exhausts the ladder",
  Lookup[exhausted, "Status", None] === "GaugeScreenLadderExhausted" &&
    MissingQ[exhausted["AdoptedDegreeOffset"]]];
check["L4 the exhausted ladder carries a defect record for every rung",
  Length[exhausted["LadderRungs"]] === 3 &&
    Lookup[exhausted["LadderRungs"], "DegreeOffset", {}] ===
      {{1, 1}, {2, 2}, {3, 3}} &&
    AllTrue[exhausted["LadderRungs"],
      AllTrue[#1["Defects"], IntegerQ[#1] && #1 > 0 &] &] &&
    Length[exhausted["LadderDefects"]] === 3];
report["L4 ladder defects", exhausted["LadderDefects"]];
report["L4 ladder seconds", Round[exhaustSeconds, 0.01]];

(* L5: the deadline *)
expiredLadder = ladder[missingAnsatz, "DegreeOffsetLadder" -> builtIn,
   "PointCount" -> 40, "Deadline" -> AbsoluteTime[] - 1];
check["L5 an expired deadline stops the ladder before any rung",
  Lookup[expiredLadder, "Status", None] === "BudgetExhausted" &&
    expiredLadder["Stage"] === "GaugeScreenLadder" &&
    expiredLadder["LadderRungs"] === {} &&
    expiredLadder["NextDegreeOffset"] === {1, 1} &&
    TrueQ[expiredLadder["Resumable"]]];
rungSeconds = Max[Lookup[exhausted["LadderRungs"], "Seconds", {1.}]];
midLadder = ladder[missingAnsatz, "DegreeOffsetLadder" -> builtIn,
   "PointCount" -> 40, "Deadline" -> AbsoluteTime[] + 1.4 rungSeconds];
check["L5 a deadline that expires mid-ladder is the same typed stop",
  Lookup[midLadder, "Status", None] === "BudgetExhausted" &&
    midLadder["Stage"] === "GaugeScreenLadder" &&
    Length[midLadder["LadderRungs"]] >= 1 &&
    MatchQ[midLadder["NextDegreeOffset"], {_Integer, _Integer}]];
check["L5 a malformed deadline is a typed refusal",
  Lookup[ladder[missingAnsatz, "Deadline" -> "soon"], "Status", None] ===
    "InvalidDeadline"];
check["L5 a malformed ladder is a typed refusal",
  Lookup[ladder[missingAnsatz, "DegreeOffsetLadder" -> {{1, -1}}], "Status",
    None] === "InvalidDegreeOffsetLadder" &&
    Lookup[ladder[missingAnsatz, "DegreeOffsetLadder" -> "1,1"], "Status",
      None] === "InvalidDegreeOffsetLadder"];
report["L5 mid-ladder stop", KeyTake[midLadder, {"Status", "Stage",
  "NextDegreeOffset", "LadderDefects"}]];

(* ------------------------------------------------------------------ *)
(* L6: driver integration on the rank-1 constructed block               *)
(* ------------------------------------------------------------------ *)

Clear[x, y, eps, v, w, cx, cy];
frame = FeynFacet`BuildAlgebraicTransportFrame[{v, w, 1 + v + w}, {v, w},
   {cx, cy}];
dlog[letter_] := {D[Log[letter], x], D[Log[letter], y]};
(* the fourth letter is the one dropped below: its pole is in NO other
   term of the ansatz, so the obstruction it leaves is one that no
   numerator degree repairs (see L4) *)
letters = {x, y, 1 - x - y, 1 + x + y};
oneForms = dlog /@ letters;
denominator = 1 - x - y;
support = Sort[{{0, 0}, {0, 1}, {1, 0}}];
diagonalForm[residues_List] := Table[
   Sum[residues[[a]] oneForms[[a, mu]], {a, Length[letters]}], {mu, 2}];
mqRoots = Lookup[rootOrder[frame, {x, y}, {1}, eps]["Roots"], "Root", {}];
gradeFactor[grade_, roots_] :=
  Product[If[BitGet[grade, k - 1] === 1, roots[[k]], 1], {k, Length[roots]}];
mqCoefficients = BlockRandom[SeedRandom[202];
   Table[RandomInteger[{-6, 6}] + RandomChoice[{0, 1/2, 1/3, -2/5}],
     {1}, {1}, {2}, {Length[support]}]];
mqResidues = BlockRandom[SeedRandom[203];
   Table[RandomInteger[{-4, 4}] + RandomChoice[{0, 1/4, -1/7}],
     {Length[letters]}, {1}, {1}]];
mqGauge = Table[Sum[mqCoefficients[[i, j, grade + 1, monomial]]
     x^support[[monomial, 1]] y^support[[monomial, 2]]
     gradeFactor[grade, mqRoots]/denominator,
   {grade, 0, 1}, {monomial, Length[support]}], {i, 1}, {j, 1}];
(* e and c carry the first three letters only: the fourth letter's pole
   must be reachable through NOTHING but its own residue column *)
mqE = BlockRandom[SeedRandom[204];
   diagonalForm[Append[Table[RandomInteger[{-2, 2}, {1, 1}], {3}],
     {{0}}]]];
mqC = BlockRandom[SeedRandom[205];
   diagonalForm[Append[Table[RandomInteger[{-2, 2}, {1, 1}], {3}],
     {{0}}]]];
mqRecord = <|"Family" -> "LADDER_RANK1_1x1", "Sector" -> 4,
   "LowerSector" -> 2, "Variables" -> {x, y}, "Regulator" -> eps,
   "Strip" -> {mqE, mqC, Table[Map[Together,
     Sum[mqResidues[[a]] eps oneForms[[a, mu]], {a, Length[letters]}] +
       D[mqGauge, {x, y}[[mu]]] -
       eps (mqE[[mu]] . mqGauge - mqGauge . mqC[[mu]]), {2}], {mu, 2}]}|>;

(* the residue on the letter x is nonzero, so dropping x from the
   alphabet is a real obstruction that no numerator degree repairs *)
check["L6 the driver fixture carries a nonzero residue on the dropped letter",
  mqResidues[[4, 1, 1]] =!= 0];
(* the residue-only integrability screen is switched off here so that the
   FULL-GAUGE screen is the gate under test; with it on, this block's
   missing letter is already refused one stage earlier *)
driverOptions = {"OneForms" -> Drop[oneForms, {4}],
   "GaugeDenominator" -> denominator, "DifferentialCheck" -> False,
   "IntegrabilityScreen" -> False, "GaugeScreenPointCount" -> 40};
{driverLadderSeconds, driverLadder} = AbsoluteTiming[
   solveMultiquadratic[mqRecord, frame, Sequence @@ driverOptions,
     "DegreeOffsetLadder" -> {{1, 1}, {2, 2}}]];
check["L6 the driver returns the typed obstruction carrying the ladder",
  Lookup[driverLadder, "Status", None] === "GaugeImageObstruction" &&
    driverLadder["GaugeScreenLadder"]["Status"] ===
      "GaugeScreenLadderExhausted" &&
    Length[driverLadder["LadderDefects"]] === 2 &&
    AllTrue[Flatten[Last /@ driverLadder["LadderDefects"]],
      IntegerQ[#1] && #1 > 0 &]];
{driverPlainSeconds, driverPlain} = AbsoluteTiming[
   solveMultiquadratic[mqRecord, frame, Sequence @@ driverOptions,
     "DegreeOffsetLadder" -> None]];
check["L6 DegreeOffsetLadder -> None restores the pre-ladder behaviour",
  Lookup[driverPlain, "Status", None] === "GaugeImageObstruction" &&
    driverPlain["GaugeScreenLadder"]["Status"] === "GaugeScreenLadderNotRun" &&
    MissingQ[driverPlain["LadderDefects"]] &&
    driverPlain["Defects"] === driverLadder["Defects"] &&
    driverPlain["Rank"] === driverLadder["Rank"]];
report["L6 driver seconds with / without the ladder",
  Round[{driverLadderSeconds, driverPlainSeconds}, 0.01]];
report["L6 driver ladder defects", driverLadder["LadderDefects"]];

(* the default path: a screen that passes leaves everything as it was *)
{driverGoodSeconds, driverGood} = AbsoluteTiming[
   solveMultiquadratic[mqRecord, frame, "OneForms" -> oneForms,
     "GaugeDenominator" -> denominator, "Support" -> support]];
check["L6 a consistent screen leaves the solve on its default path",
  Lookup[driverGood, "Status", None] === "ModularConsistent" &&
    driverGood["GaugeScreen"]["Status"] === "GaugeImageConsistent" &&
    driverGood["AdoptedDegreeOffset"] === {0, 0} &&
    driverGood["GaugeScreenLadder"]["Status"] === "GaugeScreenLadderNotRun"];
report["L6 default-path seconds", Round[driverGoodSeconds, 0.01]];

(* ------------------------------------------------------------------ *)
(* L7: the real CF300 (12,9) descriptor                                 *)
(* ------------------------------------------------------------------ *)

FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
   "Results", "UU_08_10_canonical", "TransportFamilyCharts.wl"}]];
chart = FeynFacet`TransportFamilyChart["CF300"];
(* FROZEN INPUTS (2026-08-25): the live campaign directory rewrites the
   strip input and the sector state under a running suite, so this test
   reads immutable copies with recorded provenance instead.  See the
   README of FrozenTestFixtures_2026-08-25/. *)
base = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
   "UU_08_10_canonical", "FamilyEpsFormsSolving",
   "FrozenTestFixtures_2026-08-25"}];
stripFile = FileNameJoin[{base, "cf300_frozen_strip_12_9_input.wl"}];
stateFile = FileNameJoin[{base, "cf300_frozen_stripsolvers.wl"}];
channelFile = FileNameJoin[{base, "cf300_frozen_channel_forcing.wl"}];
check["the CF300 (12,9) fixture is frozen in the repository",
  FileExistsQ[stripFile] && FileExistsQ[stateFile] &&
    FileExistsQ[channelFile] && AssociationQ[chart]];

If[FileExistsQ[stripFile] && FileExistsQ[stateFile] &&
    FileExistsQ[channelFile] && AssociationQ[chart],
 realRecord = FeynFacet`FamilyArtifactRead[stripFile, "Global`"];
 sectorState = FeynFacet`FamilyArtifactRead[stateFile, "Global`"];
 realRecord = Join[realRecord,
    <|"StripSolvers" -> Lookup[sectorState, "StripSolvers", {}]|>];
 sectorState =.;
 realVariables = realRecord["Variables"];
 realRegulator = realRecord["Regulator"];
 realRoots = rootOrder[chart, realVariables,
    rootCensus[realRecord["Strip"],
      currentRoots[chart, realVariables]]["RootIndices"],
    realRegulator]["Roots"];
 realLetters = candidateLetters[realRecord["Strip"], realRoots,
    realVariables, realRegulator, realRecord, "RegulatorSampleCount" -> 2];
 realDenominator = mergeDenominator[
    rationalGaugeDenominator[Get[channelFile], realVariables],
    normFactor[realLetters["LetterRecords"], realVariables], realVariables];
 realAnsatz = gaugeAnsatz[realRecord, realRoots, realLetters["OneForms"],
    realDenominator];
 check["L7 the CF300 (12,9) ansatz is the measured one",
   Lookup[realAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1" &&
     realAnsatz["GaugeDenominatorDegrees"] === {9, 9} &&
     Length[realAnsatz["GaugeSupport"]] === 100 &&
     Length[realLetters["OneForms"]] === 54 &&
     realAnsatz["UnknownCount"] === 1816];
 {realLadderSeconds, realLadder} = AbsoluteTiming[
    ladder[realAnsatz, "DegreeOffsetLadder" -> Automatic,
      "LeftNullSpace" -> False]];
 check["L7 the ladder adopts DegreeOffset {3,3} on the real descriptor",
   Lookup[realLadder, "Status", None] === "GaugeScreenLadderAdopted" &&
     realLadder["AdoptedDegreeOffset"] === {3, 3}];
 realRungs = Lookup[realLadder, "LadderRungs", {}];
 check["L7 the walk is {1,1} -> {2,2} -> {3,3} and stops there",
   Lookup[realRungs, "DegreeOffset", {}] === {{1, 1}, {2, 2}, {3, 3}} &&
     Last[realRungs]["Defects"] === {0, 0} &&
     AllTrue[Most[realRungs], AllTrue[#1["Defects"], #1 > 0 &] &]];
 check["L7 the adopted rung is consistent at TWO independent images",
   Last[realRungs]["ImageCount"] === 2 &&
     Last[realRungs]["Status"] === "GaugeImageConsistent" &&
     Last[realRungs]["SupportCount"] === 169 &&
     Last[realRungs]["UnknownCount"] === 2920];
 check["L7 the adopted rung's rank equals its augmented rank at both images",
   Last[realRungs]["Ranks"] === Last[realRungs]["AugmentedRanks"]];
 report["L7 MEASURED ladder walk",
   {#1["DegreeOffset"], "support", #1["SupportCount"], "unknowns",
     #1["UnknownCount"], #1["Status"], "defects", #1["Defects"], "ranks",
     #1["Ranks"], "/", #1["AugmentedRanks"], "nullities", #1["Nullities"],
     "images", #1["ImageCount"], Round[#1["Seconds"], 0.1], "s"} & /@
    realRungs];
 report["L7 MEASURED ladder seconds", Round[realLadderSeconds, 0.1]],
 check["L7 the CF300 (12,9) ladder ran", False]];

Print["t_multiquadratic_gauge_ladder: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
