#!/usr/bin/env wolframscript
(* The FULL-GAUGE per-image screen and the witness-guided mixed-grade
   letter discovery of FeynFacet/Private/MultiquadraticStripSolve.wl
   (2026-08-25).

   The residue-only integrability screen (Tests/t_multiquadratic_letters.wls)
   projects the gauge OUT and is therefore only NECESSARY: CF300 (12,9)
   passes it with defect 0 and its full affine gauge system still carries
   a defect.  This suite covers the screen that measures that full system
   from point evaluations alone -- no symbolic compile, no channel
   decomposition -- and the mixed-grade letter discovery it drives.

   Fixtures: synthetic blocks built from a KNOWN gauge, known residues
   and a known denominator; and the real off-diagonal block CF300 (12,9)
   with the measured polar-denominator census of its forcing channels,
   both read by repository-relative paths under
   Results/UU_08_10_canonical/FamilyEpsFormsSolving/
   FrozenTestFixtures_2026-08-25/ (immutable copies of live campaign
   inputs; provenance in that directory's README).

   ACCEPTANCE CRITERIA, stated before the run.  Note which are pass
   criteria and which are measurements: the CF300 (12,9) defect is OUR
   OWN UNFINISHED WORK and is REPORTED, never asserted -- a test that
   asserted it would pin the suite to a defect's current symptom.  What
   IS asserted on that block is instrument correctness: the screen's
   measurement is internally consistent and its witness verifies.

   The screen on synthetic blocks with a known answer.
   G1  A block whose forcing is BUILT from a known gauge P/Q, known
       residues and a given alphabet is GaugeImageConsistent (defect 0,
       rank = augmented rank) on the ansatz {that Q, that alphabet}.
   G2  Removing the one letter that carries a nonzero residue turns the
       same ansatz into a typed "GaugeImageObstruction" carrying a left
       witness w with A^T w = 0 and b . w != 0 modulo the screen prime.
   G3  Offered the removed letter and an innocent letter as CANDIDATE
       columns, the screen scores exactly the removed one as piercing the
       witness and as carrying a new column direction, and reports subset
       defect 0 for it and 1 for the other -- all from ONE assembly.
       This is the necessary-condition score plus the sufficiency test
       that drives discovery.
   G4  Shrinking the gauge denominator below the gauge's own pole is also
       an obstruction: the screen measures the ANSATZ, not the alphabet
       alone, which is why its typed obstruction carries an ansatz
       descriptor.
   G5  The two-image driver runs ONE image when the first is consistent,
       runs a SECOND when the first shows a defect, and types the verdict
       "GaugeImageObstruction" only when both images agree.

   The mixed-grade letter generator (exact, symbolic, no kernel arithmetic).
   G6  Every rational polar factor of the CF300 census that is linear in
       one variable is parameterized; the one that is not (the root
       square 1-2x+x^2+2y+2xy+y^2, quadratic in both) is REPORTED as
       unparameterized rather than approximated.
   G7  The splitting analysis is exact and reproduces the decomposition
       data of that cover: x and y split COMPLETELY (every grade square
       is a square on those curves), -1+x+y and 1+x+y split in the
       Sqrt[1-4xy] subfield only, -1+x and 1+x are INERT, and -1+4xy is
       RAMIFIED for the grades carrying that root.
   G8  The Galois norm routine is exact and reproduces the four measured
       repair-letter norms -4y, -4xy, 4y(1+x+y), 4x^2y^2 -- and it takes
       the norm from the field the letter actually generates, so a letter
       lying in a quadratic subfield does not get its norm squared.
   G9  Consistency of the splitting data with those four known repair
       letters: every irreducible factor of every repair norm is a factor
       the analysis marks Split or Ramified, and NO repair norm touches a
       factor marked Inert.
   G10 Every emitted mixed-grade letter carries a norm that the norm
       routine reproduces exactly and that factors into the polar census
       -- the same certificate the single-root algebraic letters carry.

   The screen on the real block CF300 (12,9).
   G11 The ansatz built from the engine's own forcing rule merged with
       the alphabet's norms is the measured one: denominator degrees
       {9,9}, support 100, 54 letters, 1816 unknowns.
   G12 The screen's measurement of that block is internally consistent:
       the matrix is {1856, 1816}, the augmented rank is the rank or the
       rank plus one, and when a defect is present the left witness
       verifies exactly (A^T w = 0, b . w != 0 mod p).
   G13 It costs under 180 s for that image (measured 43-51 s), against a
       compile of the same ansatz measured at ~7900 s.
   G14 THE REPAIR, and it is a positive result rather than a defect
       symptom, so it IS asserted: with the alphabet and the merged
       denominator unchanged and the gauge NUMERATOR degree raised three
       above the denominator degree ("DegreeOffset" -> {3,3}, support
       169, 2920 unknowns), the same system is consistent -- defect 0,
       rank = augmented rank -- and its nullity is unchanged, so the
       added directions add rank one for one. Measured at both default
       images 2026-08-25; one is asserted here to keep the suite under
       ten minutes, and the two-image confirmation together with the
       minimality of {3,3} is recorded in
       Results/.../CF300/letter_discovery_2026-08-25/README.md.
   MEASURED, NOT ASSERTED: the defect, rank, nullity and left nullity of
   CF300 (12,9) at the UNREPAIRED ansatz, and the verdict of the
   witness-guided letter discovery. *)

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
(* the mixed-grade letter generator (G6-G9) has no production caller and
   was moved to Prototypes/ on 2026-08-26 (Codex review 4.2); this suite
   is its only exercise and loads it explicitly, inside the private
   context it is written in *)
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{root, "Prototypes", "MultiquadraticMixedGradeLetters.wl"}]];
End[];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 10]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{gaugeAnsatz, gaugeScreen, gaugeScreenImages, mixedGrade, gradeNorm,
  curveParameterization, candidateLetters, normFactor, mergeDenominator,
  rationalGaugeDenominator, rootCensus, rootOrder, currentRoots,
  letterOneForm, normFilter, polarCurves, formTextKey, fieldMemberQ} =
 mq /@ {"multiquadraticStripGaugeAnsatz", "multiquadraticStripGaugeScreen",
   "multiquadraticStripGaugeScreenImages",
   "multiquadraticStripMixedGradeLetters", "multiquadraticStripGradeNorm",
   "multiquadraticStripCurveParameterization",
   "multiquadraticStripCandidateLetters",
   "multiquadraticStripNormDenominatorFactor",
   "multiquadraticStripMergeGaugeDenominator",
   "multiquadraticRationalGaugeDenominator",
   "multiquadraticStripRootCensus", "multiquadraticStripRootOrder",
   "transportChartCurrentRoots", "multiquadraticStripLetterOneForm",
   "multiquadraticStripNormInAlphabetQ",
   "multiquadraticStripRationalPolarCurves",
   "multiquadraticStripFormTextKey", "multiquadraticStripFieldMemberQ"};

(* ------------------------------------------------------------------ *)
(* G1-G5: synthetic blocks with a known gauge                           *)
(* ------------------------------------------------------------------ *)

Clear[sx, sy, se];
syntheticLetters = {sx, sy, 1 - sx - sy, 1 + sx + sy};
syntheticForms = {Together[D[Log[#1], sx]], Together[D[Log[#1], sy]]} & /@
   syntheticLetters;
(* e and c use letters 1 and 2 only; the residues sit on letters 3 and 4,
   so removing letter 3 is a real obstruction and not a vacuous one *)
syntheticE = {{{2 syntheticForms[[1, 1]]}}, {{2 syntheticForms[[1, 2]]}}};
syntheticC = {{{3 syntheticForms[[2, 1]]}}, {{3 syntheticForms[[2, 2]]}}};
syntheticGauge = {{(1 + 2 sx - 3 sy + sx sy)/(1 - sx - sy)}};
syntheticResidues = {{{0}}, {{0}}, {{5/2}}, {{-3}}};
syntheticForcing = Table[
   Map[Together, D[syntheticGauge, {sx, sy}[[mu]]] -
     se (syntheticE[[mu]] . syntheticGauge -
       syntheticGauge . syntheticC[[mu]]) +
     se Sum[syntheticResidues[[a]] syntheticForms[[a, mu]],
       {a, Length[syntheticLetters]}], {2}],
   {mu, 2}];
syntheticRecord = <|"Family" -> "SYNTHETIC_GAUGE", "Sector" -> 3,
   "LowerSector" -> 1, "Variables" -> {sx, sy}, "Regulator" -> se,
   "Strip" -> {syntheticE, syntheticC, syntheticForcing}|>;

fullAnsatz = gaugeAnsatz[syntheticRecord, {}, syntheticForms, 1 - sx - sy];
check["the synthetic ansatz descriptor is built",
  Lookup[fullAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1" &&
    fullAnsatz["UnknownCount"] === 8];
fullScreen = gaugeScreen[fullAnsatz, "RegulatorValue" -> 1/13];
check["G1 the block built from a known gauge is GaugeImageConsistent",
  Lookup[fullScreen, "Status", None] === "GaugeImageConsistent" &&
    fullScreen["Defect"] === 0 &&
    fullScreen["Rank"] === fullScreen["AugmentedRank"]];
check["G1 the screen reports the ansatz it measured",
  AssociationQ[fullScreen["Ansatz"]] &&
    fullScreen["Ansatz"]["SupportCount"] === 4 &&
    fullScreen["Ansatz"]["GradeCount"] === 1 &&
    fullScreen["Ansatz"]["GaugeDenominatorDegrees"] === {1, 1}];
report["G1 consistent", KeyTake[fullScreen, {"Status", "Defect", "Rank",
  "AugmentedRank", "Nullity", "MatrixDimensions", "PointCount"}]];

strippedAnsatz = gaugeAnsatz[syntheticRecord, {}, Drop[syntheticForms, {3}],
   1 - sx - sy];
strippedScreen = gaugeScreen[strippedAnsatz, "RegulatorValue" -> 1/13];
check["G2 removing the residue-carrying letter is a typed obstruction",
  Lookup[strippedScreen, "Status", None] === "GaugeImageObstruction" &&
    strippedScreen["Defect"] === 1];
check["G2 the obstruction carries a verified left witness",
  AssociationQ[strippedScreen["Witness"]] &&
    TrueQ[strippedScreen["Witness"]["TransposeResidualZero"]] &&
    strippedScreen["Witness"]["RightHandSidePairing"] =!= 0];
report["G2 obstruction", KeyTake[strippedScreen, {"Status", "Defect", "Rank",
  "AugmentedRank", "MatrixDimensions"}]];

candidateScreen = gaugeScreen[strippedAnsatz, "RegulatorValue" -> 1/13,
   "CandidateOneForms" -> {syntheticForms[[3]], syntheticForms[[1]]}];
scores = Lookup[candidateScreen, "CandidateScores", {}];
check["G3 the missing letter pierces the witness, the innocent one does not",
  Length[scores] === 2 && TrueQ[scores[[1]]["PiercesWitness"]] &&
    scores[[1]]["PiercesWitness"] =!= scores[[2]]["PiercesWitness"]];
check["G3 the missing letter's subset defect is 0, the other's stays 1",
  scores[[1]]["Defect"] === 0 && scores[[2]]["Defect"] === 1];
check["G3 the missing letter carries a new column direction",
  scores[[1]]["RankContribution"] > 0];
check["G3 the base defect is unchanged by offering candidates",
  candidateScreen["Defect"] === strippedScreen["Defect"]];
report["G3 candidate scores",
  KeyTake[#1, {"Index", "PiercesWitness", "RankContribution",
    "Defect"}] & /@ scores];

smallAnsatz = gaugeAnsatz[syntheticRecord, {}, syntheticForms, 1];
smallScreen = gaugeScreen[smallAnsatz, "RegulatorValue" -> 1/13];
check["G4 a denominator below the gauge's own pole is also an obstruction",
  Lookup[smallScreen, "Status", None] === "GaugeImageObstruction" &&
    smallScreen["Defect"] >= 1 &&
    smallScreen["Ansatz"]["GaugeDenominatorDegrees"] === {0, 0}];
report["G4 shrunken ansatz", KeyTake[smallScreen, {"Status", "Defect",
  "UnknownCount", "MatrixDimensions"}]];

consistentImages = gaugeScreenImages[fullAnsatz];
(* the CHEAP FIRST PASS, unchanged: "FreshImageCount" -> 0 is exactly the
   pre-2026-08-26 two-image driver, and the ladder rungs use it *)
obstructionImages = gaugeScreenImages[strippedAnsatz, "FreshImageCount" -> 0];
check["G5 a consistent first image is not repeated",
  Lookup[consistentImages, "Status", None] === "GaugeImageConsistent" &&
    consistentImages["ImageCount"] === 1];
check["G5 a defect is confirmed at a second independent image",
  Lookup[obstructionImages, "Status", None] === "GaugeImageObstruction" &&
    obstructionImages["ImageCount"] === 2 &&
    obstructionImages["Defects"] === {1, 1} &&
    obstructionImages["ConfiguredImageCount"] === 2 &&
    obstructionImages["FreshImageCount"] === 0];
report["G5 image verdicts",
  {KeyTake[consistentImages, {"Status", "ImageCount", "Defects"}],
   KeyTake[obstructionImages, {"Status", "ImageCount", "Defects"}]}];

(* ------------------------------------------------------------------ *)
(* G6-G10: the mixed-grade generator on the CF300 (12,9) root data      *)
(* ------------------------------------------------------------------ *)

Clear[gx, gy];
d1 = 1 - 2 gx + gx^2 + 2 gy + 2 gx gy + gy^2;
d2 = 1 - 4 gx gy;
gradeRoots = {<|"Root" -> Sqrt[d1], "RootSquare" -> d1|>,
   <|"Root" -> Sqrt[d2], "RootSquare" -> d2|>};
censusFactors = {gx, gy, -1 + gx, 1 + gx, -1 + gx + gy, 1 + gx + gy,
   -1 + 4 gx gy, d1};

check["G6 every polar factor linear in one variable is parameterized",
  AllTrue[DeleteCases[censusFactors, d1],
    AssociationQ[curveParameterization[#1, {gx, gy}]] &] &&
    curveParameterization[d1, {gx, gy}] === $Failed];
check["G8 the norm routine reproduces the measured repair-letter norms",
  Expand[gradeNorm[{1 - gx - gy, -1, 0, 0}, gradeRoots] - (-4 gy)] === 0 &&
    Expand[gradeNorm[{1 - gx + gy, -1, 0, 0}, gradeRoots] -
      (-4 gx gy)] === 0 &&
    Expand[gradeNorm[{1 + 2 gy, 0, -1, 0}, gradeRoots] -
      4 gy (1 + gx + gy)] === 0 &&
    Expand[gradeNorm[{1 - 2 gx gy, 0, -1, 0}, gradeRoots] -
      4 gx^2 gy^2] === 0];

{generatorSeconds, mixed} = AbsoluteTiming[
   mixedGrade[gradeRoots, censusFactors, {gx, gy}, "MaximumDegree" -> 2,
     "Alphabet" -> censusFactors, "MaximumSolutionsPerPrime" -> 12]];
check["the mixed-grade generator returns its typed record",
  Lookup[mixed, "Status", None] === "MultiquadraticMixedGradeLettersV1"];
splitting = Association[
   ToString[InputForm[#1["Factor"]]] -> #1 & /@ mixed["Diagnostics"]];
splitOf[f_] := Lookup[splitting, ToString[InputForm[Expand[f]]],
   <|"Status" -> Missing["NotAnalyzed"]|>];
check["G6 the factor that is quadratic in both variables is reported, not guessed",
  splitOf[d1]["Status"] === "NotRationallyParameterized"];
check["G7 x and y split COMPLETELY in the rank-2 cover",
  TrueQ[splitOf[gx]["FullSplit"]] && TrueQ[splitOf[gy]["FullSplit"]] &&
    splitOf[gx]["SplitGrades"] === {0, 1, 2, 3} &&
    splitOf[gy]["SplitGrades"] === {0, 1, 2, 3}];
check["G7 -1+x+y and 1+x+y split in the Sqrt[1-4xy] subfield only",
  splitOf[-1 + gx + gy]["Status"] === "Split" &&
    splitOf[-1 + gx + gy]["SplitGrades"] === {0, 2} &&
    splitOf[1 + gx + gy]["Status"] === "Split" &&
    splitOf[1 + gx + gy]["SplitGrades"] === {0, 2}];
check["G7 -1+x and 1+x are inert",
  splitOf[-1 + gx]["Status"] === "Inert" &&
    splitOf[1 + gx]["Status"] === "Inert"];
check["G7 -1+4xy is ramified for the grades carrying that root",
  splitOf[-1 + 4 gx gy]["RamifiedGrades"] === {2, 3}];
report["G7 splitting", KeyTake[#1, {"Factor", "Status", "SplitGrades",
  "RamifiedGrades", "FullSplit"}] & /@ mixed["Diagnostics"]];

inertFactors = Lookup[Select[mixed["Diagnostics"],
   Lookup[#1, "Status", None] === "Inert" &], "Factor", {}];
repairNorms = {-4 gy, -4 gx gy, 4 gy (1 + gx + gy), 4 gx^2 gy^2};
touchesInertQ[value_] := AnyTrue[inertFactors, Function[f,
   PolynomialQ[Quiet[Cancel[Together[value/f]]], {gx, gy}]]];
check["G9 no known repair-letter norm touches a factor marked Inert",
  ! AnyTrue[repairNorms, touchesInertQ]];
check["G9 every known repair-letter norm factors into the census",
  AllTrue[repairNorms, normFilter[#1, censusFactors, {gx, gy}] &]];
report["G9 inert factors", inertFactors];

check["G10 every emitted norm is exact and factors into the polar census",
  mixed["LetterRecords"] =!= {} &&
    AllTrue[mixed["LetterRecords"], Function[entry,
      TrueQ[Expand[gradeNorm[entry["GradeCoefficients"], gradeRoots] -
          entry["Norm"]] === 0] &&
        ! TrueQ[Together[entry["Norm"]] === 0] &&
        TrueQ[normFilter[entry["Norm"], censusFactors, {gx, gy}]]]]];
report["G10 generator seconds / letters / trivial skipped",
  {Round[generatorSeconds, 0.01], mixed["Count"],
   mixed["TrivialSolutionCount"]}];
report["G10 emitted letters",
  {#1["Divisor"], #1["GradeSupport"], Factor[#1["Norm"]]} & /@
    mixed["LetterRecords"]];

(* ------------------------------------------------------------------ *)
(* G11-G13: the screen and the discovery on the real block CF300 (12,9) *)
(* ------------------------------------------------------------------ *)

FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
   "Results", "UU_08_10_canonical", "TransportFamilyCharts.wl"}]];
chart = FeynFacet`TransportFamilyChart["CF300"];
(* FROZEN INPUTS (2026-08-25).  These three files used to be read from
   the LIVE campaign directory triple_root_2026-08-24_fable/CF300/,
   which every campaign mission rewrites: the strip input was rewritten
   at 13:41 by round 6 while this suite was running.  A test never reads
   mutating run state (CLAUDE.md, Verification), so the inputs are now
   immutable copies under FrozenTestFixtures_2026-08-25/ with their
   provenance in that directory's README.  The sector state is frozen as
   its StripSolvers PROJECTION -- the only field this suite uses -- which
   also removes a 33 MB read from every run. *)
base = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
   "UU_08_10_canonical", "FamilyEpsFormsSolving",
   "FrozenTestFixtures_2026-08-25"}];
stripFile = FileNameJoin[{base, "cf300_frozen_strip_12_9_input.wl"}];
(* the MEASURED channel decomposition of this block's forcing, moved into
   the repository as evidence 2026-08-25.  Recomputing it here is the
   ~10^3 s preparation stage the screen exists to run in front of. *)
channelFile = FileNameJoin[{base, "cf300_frozen_channel_forcing.wl"}];
stateFile = FileNameJoin[{base, "cf300_frozen_stripsolvers.wl"}];
check["the CF300 (12,9) fixture and its channel census are frozen in the \
repository",
  FileExistsQ[stripFile] && FileExistsQ[channelFile] &&
    FileExistsQ[stateFile] && AssociationQ[chart]];

(* the sector state carries the row's installed alphabets; without them
   the candidate letter set is 52 rather than the measured 54, and the
   ansatz is not the one the 2026-08-25 evidence records *)
If[FileExistsQ[stripFile] && FileExistsQ[channelFile] &&
    FileExistsQ[stateFile] && AssociationQ[chart],
 record = FeynFacet`FamilyArtifactRead[stripFile, "Global`"];
 sectorState = FeynFacet`FamilyArtifactRead[stateFile, "Global`"];
 record = Join[record,
    <|"StripSolvers" -> Lookup[sectorState, "StripSolvers", {}]|>];
 sectorState =.;
 variables = record["Variables"]; regulator = record["Regulator"];
 allRoots = currentRoots[chart, variables];
 census = rootCensus[record["Strip"], allRoots];
 order = rootOrder[chart, variables, census["RootIndices"], regulator];
 roots = order["Roots"];
 letters = candidateLetters[record["Strip"], roots, variables, regulator,
    record, "RegulatorSampleCount" -> 2];
 channelForcing = Get[channelFile];
 engineDenominator = rationalGaugeDenominator[channelForcing, variables];
 merged = mergeDenominator[engineDenominator,
    normFactor[letters["LetterRecords"], variables], variables];
 realAnsatz = gaugeAnsatz[record, roots, letters["OneForms"], merged];
 check["G11 the CF300 (12,9) ansatz is the measured one",
   Lookup[realAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1" &&
     realAnsatz["GaugeDenominatorDegrees"] === {9, 9} &&
     Length[realAnsatz["GaugeSupport"]] === 100 &&
     Length[letters["OneForms"]] === 54 &&
     realAnsatz["UnknownCount"] === 1816];
 report["G11 CF300 ansatz", KeyTake[realAnsatz, {"GaugeDenominatorDegrees",
   "GaugeUnknownCount", "ResidueUnknownCount", "UnknownCount"}]];

 (* the witness-guided discovery: mixed-grade letters over the polar
    census UNION the strip's own alphabet, scored against the witness in
    the SAME assembly *)
 realCensus = polarCurves[{}, Join[
    polarCurves[Flatten[channelForcing], Lookup[roots, "RootSquare", {}],
      variables], letters["Alphabet"]], variables];
 discovered = mixedGrade[roots, realCensus, variables, "MaximumDegree" -> 3,
    "Alphabet" -> realCensus, "MaximumSolutionsPerPrime" -> 40,
    "CombinationOrder" -> 2, "CombinationBasisLimit" -> 16];
 existingKeys = Association[
    (formTextKey[#1, variables, regulator] -> True) & /@ letters["OneForms"]];
 candidateForms = {}; candidateNorms = {};
 Do[Module[{form, key},
    form = letterOneForm[entry["Letter"], variables];
    If[! MatchQ[form, {_, _}], Continue[]];
    If[! fieldMemberQ[form[[1]], roots] || ! fieldMemberQ[form[[2]], roots],
      Continue[]];
    key = formTextKey[form, variables, regulator];
    If[KeyExistsQ[existingKeys, key], Continue[]];
    AssociateTo[existingKeys, key -> True];
    AppendTo[candidateForms, form];
    AppendTo[candidateNorms, entry["Norm"]]],
   {entry, discovered["LetterRecords"]}];
 report["discovery: census factors / mixed-grade letters / new one-forms",
   {Length[realCensus], discovered["Count"], Length[candidateForms]}];

 {realSeconds, realScreen} = AbsoluteTiming[
    gaugeScreen[realAnsatz, "Prime" -> 2147483423, "RegulatorValue" -> 1/13,
      "RandomSeed" -> 20260825, "CandidateOneForms" -> candidateForms,
      "CandidateSubsets" -> If[Length[candidateForms] >= 2,
        Append[Subsets[Range[Length[candidateForms]], {2}],
          Range[Length[candidateForms]]], {}]]];
 check["G12 the screen's measurement of that block is internally consistent",
   MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent"},
       Lookup[realScreen, "Status", None]] &&
     realScreen["MatrixDimensions"] === {1856, 1816} &&
     realScreen["UnknownCount"] === 1816 &&
     MemberQ[{realScreen["Rank"], realScreen["Rank"] + 1},
       realScreen["AugmentedRank"]]];
 check["G12 a defect, if present, comes with an exactly verified witness",
   realScreen["Defect"] === 0 ||
     (AssociationQ[realScreen["Witness"]] &&
       TrueQ[realScreen["Witness"]["TransposeResidualZero"]] &&
       realScreen["Witness"]["RightHandSidePairing"] =!= 0)];
 check["G13 one image of that block costs under 180 s", realSeconds < 180];
 (* MEASURED, NOT ASSERTED -- our own unfinished work stays visible *)
 report["MEASURED CF300 (12,9) screen", KeyTake[realScreen, {"Status",
   "Defect", "Rank", "AugmentedRank", "Nullity", "LeftNullity",
   "MatrixDimensions", "PointCount", "AttemptCount", "Prime",
   "RegulatorValue"}]];
 report["MEASURED screen seconds", Round[realSeconds, 0.01]];
 report["MEASURED candidates piercing the witness",
   Lookup[Select[realScreen["CandidateScores"],
     TrueQ[#1["PiercesWitness"]] &], "Index", {}]];
 report["MEASURED candidates with a new column direction",
   Lookup[Select[realScreen["CandidateScores"],
     IntegerQ[#1["RankContribution"]] && #1["RankContribution"] > 0 &],
     "Index", {}]];
 report["MEASURED candidate subsets reaching defect 0",
   Length[Select[realScreen["CandidateSubsetResults"],
     #1["Defect"] === 0 &]]];
 (* G14: the measured REPAIR.  This is a positive result, not a defect
    symptom, so it is asserted: with the alphabet and the denominator
    unchanged and the gauge numerator degree raised three above the
    denominator degree, the same system is consistent.  Measured
    2026-08-25 at both default images; one image is asserted here to
    keep the suite under ten minutes, and the two-image confirmation is
    recorded in
    Results/.../CF300/letter_discovery_2026-08-25/README.md. *)
 offsetAnsatz = gaugeAnsatz[record, roots, letters["OneForms"], merged,
    "DegreeOffset" -> {3, 3}];
 {offsetSeconds, offsetScreen} = AbsoluteTiming[
    gaugeScreen[offsetAnsatz, "Prime" -> 2147483423,
      "RegulatorValue" -> 1/13, "RandomSeed" -> 20260825,
      "LeftNullSpace" -> False]];
 check["G14 numerator degree three above the denominator repairs the block",
   Length[offsetAnsatz["GaugeSupport"]] === 169 &&
     offsetAnsatz["UnknownCount"] === 2920 &&
     Lookup[offsetScreen, "Status", None] === "GaugeImageConsistent" &&
     offsetScreen["Defect"] === 0 &&
     offsetScreen["Rank"] === offsetScreen["AugmentedRank"]];
 check["G14 the repair leaves the nullity where the defective ansatz had it",
   offsetScreen["Nullity"] === realScreen["Nullity"]];
 report["G14 DegreeOffset {3,3}", KeyTake[offsetScreen, {"Status", "Defect",
   "Rank", "AugmentedRank", "Nullity", "MatrixDimensions", "UnknownCount"}]];
 report["G14 seconds", Round[offsetSeconds, 0.01]];
 report["MEASURED discovery verdict", If[
   AnyTrue[realScreen["CandidateSubsetResults"], #1["Defect"] === 0 &] ||
     AnyTrue[realScreen["CandidateScores"], #1["Defect"] === 0 &],
   "a mixed-grade letter repairs the defect at this image",
   "NEGATIVE: no mixed-grade letter, pair, or the full set repairs the "
     <> "defect at this image, at degree bound 3 over " <>
     ToString[Length[realCensus]] <> " census factors"]],
 check["G11 the CF300 (12,9) screen ran", False]];

(* ------------------------------------------------------------------ *)
(* S1-S4: THE EXCEPTIONAL-REGULATOR FALSE OBSTRUCTION                   *)
(* (Codex 04:30 P1: a single regulator image is not an exact generic    *)
(*  Q(eps) obstruction)                                                 *)
(* ------------------------------------------------------------------ *)
(* An adversarial 1x1 rank-0 strip whose residue-only integrability
   system is GENERICALLY SOLVABLE and INCONSISTENT AT ONE regulator
   value -- Codex's (eps - a) z = 1 in the shape the screen actually
   sees.  Construction (all of it exact and derived, none of it fitted):

     e = {1, eps},  c = 0,  so chi := e - c has chi_x = 1, chi_y = eps;
     letters as one-forms  w1 = {-y, x},  w2 = {-x, y}.

   The screen's row for letter k on a 1x1 block is
     eps^2 (w_{k,y} chi_x - w_{k,x} chi_y),
   hence the two columns are eps^2 (x + eps y) and eps^2 (y + eps x).
   As functions of the sampled point they are independent unless
   eps^2 = 1, so the system matrix DROPS RANK exactly at eps = +-1.
   The forcing is chosen so that the true residues are R1 = -R2 =
   1/(eps^2 - 1): the right-hand side is then eps^2 (y - x)/(1 + eps),
   finite and in the column span for every other eps, and at eps = 1 the
   span collapses to {x + y} while the right-hand side is (y - x)/2,
   which is not in it.  bbar = {0, (eps (y - x) - 1)/(1 + eps)} realizes
   exactly that forcing curl, and both diagonal connections are closed,
   so the screen's flatness measurement passes. *)

Clear[ax, ay, ae];
exceptionalBeta = (ae (ay - ax) - 1)/(1 + ae);
exceptionalRecord = <|"Family" -> "SyntheticExceptionalRegulator",
  "Sector" -> 2, "LowerSector" -> 1,
  "Variables" -> {ax, ay}, "Regulator" -> ae,
  "Strip" -> {{{{1}}, {{ae}}}, {{{0}}, {{0}}},
    {{{0}}, {{exceptionalBeta}}}}|>;
exceptionalLetters = {
  <|"Kind" -> "Synthetic", "Letter" -> "w1", "OneForm" -> {-ay, ax}|>,
  <|"Kind" -> "Synthetic", "Letter" -> "w2", "OneForm" -> {-ax, ay}|>};
integrabilityScreen = mq["multiquadraticStripIntegrabilityScreen"];
integrabilityScreenImages = mq["multiquadraticStripIntegrabilityScreenImages"];

(* S1: at the exceptional regulator value ONE image says "obstruction" *)
exceptionalOne = integrabilityScreen[exceptionalRecord, {}, exceptionalLetters,
  "Prime" -> 2147483423, "RegulatorValue" -> 1, "PointCount" -> 12];
report["S1 single image at eps = 1", KeyTake[exceptionalOne,
  {"Status", "Defect", "Rank", "AugmentedRank", "MatrixDimensions"}]];
check["S1 the single-image screen calls the exceptional regulator an obstruction",
  Lookup[exceptionalOne, "Status", None] === "AlphabetIntegrabilityObstruction" &&
    Lookup[exceptionalOne, "Defect", 0] === 1 &&
    TrueQ[Lookup[exceptionalOne, "FlatDiagonalConnections", False]]];

(* S2: a generic regulator value is consistent -- the system really is
   solvable over Q(eps), so S1 is a FALSE obstruction *)
exceptionalGeneric = integrabilityScreen[exceptionalRecord, {},
  exceptionalLetters, "Prime" -> 2147483399, "RegulatorValue" -> 3/17,
  "PointCount" -> 12];
report["S2 single image at eps = 3/17", KeyTake[exceptionalGeneric,
  {"Status", "Defect", "Rank", "AugmentedRank"}]];
check["S2 the same system is consistent at a generic regulator value",
  Lookup[exceptionalGeneric, "Status", None] ===
      "AlphabetIntegrabilityConsistent" &&
    Lookup[exceptionalGeneric, "Defect", 1] === 0];

(* S3: the two-image confirmation refuses to call it an obstruction *)
exceptionalConfirmed = integrabilityScreenImages[exceptionalRecord, {},
  exceptionalLetters, "Prime" -> 2147483423, "RegulatorValue" -> 1,
  "PointCount" -> 12];
report["S3 two-image verdict", KeyTake[exceptionalConfirmed,
  {"Status", "Confirmed", "Defects", "ImageCount", "Images",
   "ExceptionalRegulatorImages"}]];
(* the confirmation image is CONSISTENT, and a consistent image exhibits
   a solution of its own specialized system -- so the generic system is
   solvable and the first image's defect was an exceptional regulator
   value.  The verdict is therefore "consistent", NOT "obstruction", and
   certainly not the confirmed obstruction the single image claimed. *)
check["S3 the confirmation image is run and the FALSE obstruction is not \
propagated: the verdict is consistent, unconfirmed as an obstruction",
  Lookup[exceptionalConfirmed, "Status", None] ===
      "AlphabetIntegrabilityConsistent" &&
    Lookup[exceptionalConfirmed, "Confirmed", True] === False &&
    Lookup[exceptionalConfirmed, "ImageCount", 0] === 2 &&
    Lookup[exceptionalConfirmed, "Defects", {}] === {1, 0}];
check["S3b the exceptional regulator image is RECORDED as evidence",
  Lookup[exceptionalConfirmed, "ExceptionalRegulatorImages", {}] ===
    {{2147483423, 1}}];

(* S4: a GENUINE alphabet obstruction still confirms at both images.
   Dropping w2 leaves the single column eps^2 (x + eps y), and the
   right-hand side eps^2 (y - x)/(1 + eps) is proportional to it only at
   eps = -1, so both default images carry a defect. *)
genuine = integrabilityScreenImages[exceptionalRecord, {},
  Take[exceptionalLetters, 1], "PointCount" -> 12];
report["S4 genuine obstruction", KeyTake[genuine,
  {"Status", "Confirmed", "Defects", "ImageCount"}]];
check["S4 a genuine obstruction is confirmed at two independent images",
  Lookup[genuine, "Status", None] === "AlphabetIntegrabilityObstruction" &&
    TrueQ[Lookup[genuine, "Confirmed", False]] &&
    Lookup[genuine, "ImageCount", 0] === 2 &&
    AllTrue[Lookup[genuine, "Defects", {0}], IntegerQ[#1] && #1 > 0 &]];
check["S4 the deciding image's witness travels with the confirmed verdict",
  AssociationQ[Lookup[genuine, "Witness", None]] &&
    TrueQ[genuine["Witness"]["TransposeResidualZero"]] &&
    genuine["Witness"]["RightHandSidePairing"] =!= 0];

(* S5: a consistent first image is still ONE image -- the fast path is
   unchanged and a consistent screen gates nothing *)
exceptionalFastPath = integrabilityScreenImages[exceptionalRecord, {},
  exceptionalLetters, "Prime" -> 2147483399, "RegulatorValue" -> 3/17,
  "PointCount" -> 12];
check["S5 a consistent first image ends the screen (fast path preserved)",
  Lookup[exceptionalFastPath, "Status", None] ===
      "AlphabetIntegrabilityConsistent" &&
    Lookup[exceptionalFastPath, "ImageCount", 0] === 1];

(* S6: the contract language of the top level says what a confirmed
   defect is and what it is not *)
solveSource = Import[FileNameJoin[{root, "FeynFacet", "Private",
  "MultiquadraticStripSolve.wl"}], "Text"];
check["S6 the solution contract calls a confirmed defect a high-confidence \
modular obstruction, not a Q(eps) theorem",
  StringContainsQ[solveSource,
    "\"ContractStrength\" -> \"HighConfidenceModularObstruction\""] &&
    StringContainsQ[solveSource,
      "rank defect at TWO independent (prime, regulator) images"] &&
    StringContainsQ[solveSource,
      "It is not an unconditional theorem over Q(eps)"]];
(* BEHAVIOURAL (2026-08-25): the source-text form of this assertion broke
   on a pure reformatting of the call it greps for, which is exactly the
   brittleness Codex flagged for S12.  The statement that matters is that
   the top level runs the CONFIRMING screen -- the two-image one -- and
   not the single-image one, and that is a property of the result it
   returns: a two-image verdict carries ImageCount and Images. *)
check["S6 the top level acts only on the CONFIRMED status",
  StringContainsQ[solveSource,
    "screen = multiquadraticStripIntegrabilityScreenImages["]];
(* and the same statement made BEHAVIOURALLY (2026-08-25): the source
   form above broke once on a pure reformatting of the call it greps
   for, so the contract is now also established by driving the top level
   and reading the two-image evidence out of its verdict. *)
s6Frame = <|"Name" -> "S6RationalIdentity", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational", "Variables" -> {ax, ay},
  "Subst" -> {ax -> ax, ay -> ay}, "Root" -> None, "RootSquare" -> None,
  "Roots" -> {}|>;
s6Driven = mq["solveEpsFormStripMultiquadratic"][exceptionalRecord, s6Frame,
  "OneForms" -> Lookup[Take[exceptionalLetters, 1], "OneForm"],
  "GaugeScreen" -> False, "IntegrabilityScreenPointCount" -> 12];
report["S6 top-level verdict on the genuine obstruction",
  KeyTake[s6Driven, {"Status", "Confirmed", "ImageCount", "Defects",
    "ContractStrength"}]];
check["S6 the top level's verdict carries the two-image evidence, which \
only the confirming screen produces",
  Lookup[s6Driven, "Status", None] === "AlphabetIntegrabilityObstruction" &&
    Lookup[s6Driven, "ImageCount", 0] === 2 &&
    MatchQ[Lookup[s6Driven, "Images", None], {{_Integer, _}, {_Integer, _}}] &&
    Length[Lookup[s6Driven, "Defects", {}]] === 2 &&
    Lookup[s6Driven, "ContractStrength", None] ===
      "HighConfidenceModularObstruction" &&
    Lookup[s6Driven, "SolutionContract", None] ===
      "AlphabetObstructionWithinAnsatz"];
(* and the SINGLE-image screen on the exceptional fixture would have
   produced a FALSE obstruction, which is what makes the choice of
   screen a behavioural fact and not a formatting one *)
check["S6 the single-image screen would have called the exceptional \
regulator an obstruction, so the two-image evidence is not decorative",
  Lookup[exceptionalOne, "Status", None] ===
      "AlphabetIntegrabilityObstruction" &&
    Lookup[exceptionalConfirmed, "Status", None] ===
      "AlphabetIntegrabilityConsistent"];

(* ------------------------------------------------------------------ *)
(* S7-S12: screen admission ceilings, deadline and phase telemetry      *)
(* (Codex 04:30 P1: the default-on dense screen needs a size/byte gate  *)
(*  and its own deadline)                                               *)
(* ------------------------------------------------------------------ *)
sizeEstimate = mq["multiquadraticStripScreenSizeEstimate"];
compileCacheClear = mq["multiquadraticStripScreenCompileCacheClear"];

check["S7 the size estimate counts rows, columns and packed bytes",
  Module[{estimate = sizeEstimate[1856, 1816, 12]},
    estimate["Rows"] === 1856 && estimate["Columns"] === 1816 &&
      estimate["CandidateColumns"] === 12 &&
      estimate["TotalColumns"] === 1828 &&
      estimate["PackedBytes"] === 8. 1856 (1828 + 1) 2]];

(* the unknown-count ceiling, on the residue-only screen *)
overUnknowns = integrabilityScreen[exceptionalRecord, {}, exceptionalLetters,
  "PointCount" -> 12, "MaximumUnknowns" -> 1];
check["S8 an over-ceiling unknown count is a typed not-applicable, \
BEFORE any allocation",
  Lookup[overUnknowns, "Status", None] === "IntegrabilityScreenNotApplicable" &&
    Lookup[overUnknowns, "Reason", None] === "UnknownCountCeilingExceeded" &&
    AssociationQ[Lookup[overUnknowns, "SizeEstimate", None]] &&
    overUnknowns["MaximumUnknowns"] === 1];
overBytes = integrabilityScreen[exceptionalRecord, {}, exceptionalLetters,
  "PointCount" -> 12, "MaximumBytes" -> 1];
check["S8 an over-ceiling byte estimate is a typed not-applicable",
  Lookup[overBytes, "Status", None] === "IntegrabilityScreenNotApplicable" &&
    Lookup[overBytes, "Reason", None] === "ByteCeilingExceeded"];
(* the gauge screen carries the same gate, and returns ITS typed status *)
overGauge = gaugeScreen[fullAnsatz, "MaximumUnknowns" -> 1];
check["S8 the gauge screen's ceiling returns GaugeScreenNotApplicable",
  Lookup[overGauge, "Status", None] === "GaugeScreenNotApplicable" &&
    Lookup[overGauge, "Reason", None] === "UnknownCountCeilingExceeded" &&
    AssociationQ[Lookup[overGauge, "SizeEstimate", None]]];
check["S8 the default ceilings admit the MEASURED CF300 (12,9) screen size",
  Module[{estimate = sizeEstimate[1856, 1816, 0]},
    estimate["TotalColumns"] <=
        Symbol["FeynFacet`Private`$multiquadraticStripScreenMaximumUnknowns"] &&
      estimate["PackedBytes"] <=
        Symbol["FeynFacet`Private`$multiquadraticStripScreenMaximumBytes"]]];

(* the deadline *)
expiredIntegrability = integrabilityScreen[exceptionalRecord, {},
  exceptionalLetters, "PointCount" -> 12,
  "Deadline" -> AbsoluteTime[] - 1];
check["S9 an expired deadline stops the residue screen, typed and resumable",
  Lookup[expiredIntegrability, "Status", None] === "BudgetExhausted" &&
    StringQ[Lookup[expiredIntegrability, "Stage", None]] &&
    StringStartsQ[expiredIntegrability["Stage"], "IntegrabilityScreen:"] &&
    TrueQ[expiredIntegrability["Resumable"]]];
expiredGauge = gaugeScreen[fullAnsatz, "Deadline" -> AbsoluteTime[] - 1];
check["S9 an expired deadline stops the gauge screen, typed and resumable",
  Lookup[expiredGauge, "Status", None] === "BudgetExhausted" &&
    StringQ[Lookup[expiredGauge, "Stage", None]] &&
    StringStartsQ[expiredGauge["Stage"], "GaugeScreen:"] &&
    TrueQ[expiredGauge["Resumable"]]];
check["S9 a budget stop is NOT reported as GaugeScreenNotApplicable \
by the two-image driver",
  Lookup[gaugeScreenImages[fullAnsatz,
    "Deadline" -> AbsoluteTime[] - 1], "Status", None] === "BudgetExhausted"];
check["S9 an unbounded deadline is the default and changes nothing",
  Lookup[Association[Options[integrabilityScreen]], "Deadline"] === Infinity &&
    Lookup[Association[Options[gaugeScreen]], "Deadline"] === Infinity];

(* phase telemetry *)
timedScreen = gaugeScreen[fullAnsatz, "LeftNullSpace" -> True];
report["S10 gauge-screen phase timings",
  Lookup[timedScreen, "PhaseTimings", None]];
check["S10 the gauge screen reports Compile / PointAssembly / Rank / \
LeftNullSpace seconds",
  AssociationQ[Lookup[timedScreen, "PhaseTimings", None]] &&
    Sort[Keys[timedScreen["PhaseTimings"]]] ===
      Sort[{"Compile", "PointAssembly", "Rank", "LeftNullSpace"}] &&
    AllTrue[Values[timedScreen["PhaseTimings"]], NumericQ] &&
    AssociationQ[Lookup[timedScreen, "SizeEstimate", None]]];
timedIntegrability = integrabilityScreen[exceptionalRecord, {},
  exceptionalLetters, "PointCount" -> 12];
check["S10 the residue screen reports the same four phases",
  AssociationQ[Lookup[timedIntegrability, "PhaseTimings", None]] &&
    Sort[Keys[timedIntegrability["PhaseTimings"]]] ===
      Sort[{"Compile", "PointAssembly", "Rank", "LeftNullSpace"}] &&
    AllTrue[Values[timedIntegrability["PhaseTimings"]], NumericQ]];

(* compiled-form reuse between images and ladder rungs *)
compileCacheClear[];
firstCompile = gaugeScreen[fullAnsatz, "Prime" -> 2147483423,
  "RegulatorValue" -> 1/13];
secondCompile = gaugeScreen[fullAnsatz, "Prime" -> 2147483423,
  "RegulatorValue" -> 1/13];
report["S11 compile cache, first then second call",
  {Lookup[firstCompile, "CompileCache", None],
   Lookup[secondCompile, "CompileCache", None]}];
check["S11 the first screen of an image compiles and the second reuses \
every compiled scalar form",
  AssociationQ[Lookup[firstCompile, "CompileCache", None]] &&
    firstCompile["CompileCache"]["Misses"] > 0 &&
    secondCompile["CompileCache"]["Misses"] === 0 &&
    secondCompile["CompileCache"]["Hits"] ===
      firstCompile["CompileCache"]["Misses"] +
        firstCompile["CompileCache"]["Hits"]];
check["S11 the reuse does not change the measurement",
  Lookup[firstCompile, "Status", None] ===
      Lookup[secondCompile, "Status", 1] &&
    Lookup[firstCompile, "Defect", None] === Lookup[secondCompile, "Defect", 1] &&
    Lookup[firstCompile, "Rank", None] === Lookup[secondCompile, "Rank", 1]];
check["S11 the cache is byte-bounded and reports its own size",
  NumericQ[Symbol["FeynFacet`Private`$multiquadraticStripScreenCompileCacheLimit"]] &&
    NumericQ[secondCompile["CompileCache"]["Bytes"]]];

(* ------------------------------------------------------------------ *)
(* S12: PROVENANCE for a reused forcing-channel decomposition           *)
(* (Codex 04:30 P2: reused forcing channels need provenance, not only   *)
(*  shape)                                                              *)
(* ------------------------------------------------------------------ *)
(* The same-call reuse saves a measured 807 s of the CF300 (12,9)
   compile, and it used to be accepted on ARRAY SHAPE alone: safe for the
   one caller that supplies the array it has just built, unsafe as a
   general cache or artifact boundary.  A shape-compatible array from a
   DIFFERENT strip would have been installed silently and the whole solve
   built on someone else's forcing.  The decomposition now travels as a
   sealed record and every consumer fails closed. *)
channelRecord = mq["multiquadraticStripForcingChannelRecord"];
channelAccept = mq["multiquadraticStripForcingChannelsAccept"];
Clear[fx, fy, fe];
forcingA = {{{fx/(1 - fy)}}, {{fe fy}}};
forcingB = {{{fx/(1 + fy)}}, {{fe fy}}};
sealRoots = {};
sealedA = channelRecord[{{{{fx/(1 - fy)}}}, {{{fe fy}}}}, forcingA,
  sealRoots, {fx, fy}, fe];
check["S12 the seal is a schema-tagged V2 record with a 64-hex fingerprint AND a channel content hash",
  AssociationQ[sealedA] &&
    sealedA["Schema"] === "MultiquadraticForcingChannelsV2" &&
    sealedA["SchemaVersion"] === 2 &&
    StringQ[sealedA["Fingerprint"]] &&
    StringLength[sealedA["Fingerprint"]] === 64 &&
    StringQ[sealedA["ChannelsSHA256"]] &&
    StringLength[sealedA["ChannelsSHA256"]] === 64 &&
    sealedA["GradeCount"] === 1];
(* the V2 seal exists BECAUSE V1 authenticated the forcing and not the
   channels: a same-shape channel mutation under a V1 seal was accepted.
   These two assertions are what make the block fail against any seal
   that does not authenticate the channel content. *)
check["S12 a same-shape CHANNEL-CONTENT mutant under an otherwise valid \
seal is refused, and the refusal names the content",
  Module[{mutant = Append[sealedA, "Channels" ->
      {{{{fx/(1 + fy)}}}, {{{fe fy}}}}], verdict},
    verdict = channelAccept[mutant, forcingA, sealRoots, {fx, fy}, fe];
    Lookup[verdict, "Status", None] === "ForcingChannelContentMismatch" &&
      StringQ[verdict["ExpectedChannelsSHA256"]] &&
      verdict["ExpectedChannelsSHA256"] =!=
        verdict["SuppliedChannelsSHA256"]]];
check["S12 a V1 record is refused-typed and never silently upgraded",
  Module[{legacy = Join[KeyDrop[sealedA, "ChannelsSHA256"],
      <|"Schema" -> "MultiquadraticForcingChannelsV1",
        "SchemaVersion" -> 1|>], verdict},
    verdict = channelAccept[legacy, forcingA, sealRoots, {fx, fy}, fe];
    Lookup[verdict, "Status", None] === "ForcingChannelSealSuperseded" &&
      verdict["ExpectedSchema"] === "MultiquadraticForcingChannelsV2"]];
check["S12 no supplied decomposition is the unchanged default",
  Lookup[channelAccept[Automatic, forcingA, sealRoots, {fx, fy}, fe],
    "Status", None] === "NotSupplied"];
check["S12 its own forcing accepts it",
  Lookup[channelAccept[sealedA, forcingA, sealRoots, {fx, fy}, fe],
    "Status", None] === "Accepted"];
check["S12 a DIFFERENT but shape-compatible forcing is refused on \
provenance, not accepted on shape",
  Module[{verdict = channelAccept[sealedA, forcingB, sealRoots, {fx, fy}, fe]},
    Lookup[verdict, "Status", None] === "ForcingChannelProvenanceMismatch" &&
      StringQ[verdict["ExpectedFingerprint"]] &&
      verdict["ExpectedFingerprint"] =!= verdict["SuppliedFingerprint"]]];
check["S12 a BARE shape-compatible array carries no provenance and is \
refused typed",
  Lookup[channelAccept[{{{{fx/(1 - fy)}}}, {{{fe fy}}}}, forcingA, sealRoots,
    {fx, fy}, fe], "Status", None] === "ForcingChannelsUnsealed"];
check["S12 a sealed record whose channels have the wrong shape is refused",
  Lookup[channelAccept[Join[sealedA, <|"Channels" -> {{{{1, 2}}}, {{{3, 4}}}}|>],
    forcingA, sealRoots, {fx, fy}, fe], "Status", None] ===
    "ForcingChannelShapeMismatch"];
check["S12 the seal does not depend on the CONTEXT the variables arrived in",
  channelRecord[{{{{Symbol["Global`sealX"]}}}, {{{0}}}},
      {{{Symbol["Global`sealX"]}}, {{0}}}, {},
      {Symbol["Global`sealX"], Symbol["Global`sealY"]},
      Symbol["Global`sealE"]]["Fingerprint"] ===
    channelRecord[{{{{Symbol["FeynFacet`Private`sealX"]}}}, {{{0}}}},
      {{{Symbol["FeynFacet`Private`sealX"]}}, {{0}}}, {},
      {Symbol["FeynFacet`Private`sealX"],
       Symbol["FeynFacet`Private`sealY"]},
      Symbol["FeynFacet`Private`sealE"]]["Fingerprint"]];
(* Both consumers must refuse an unsealed decomposition.  The BEHAVIOURAL
   two-consumer assertion lives in Tests/t_multiquadratic_provenance.wls
   (block A4), where prepare and compile are actually called with a bare
   shape-compatible array; what remains here is the negative source
   statement that no shape-only acceptance path was left behind, which
   has no behavioural counterpart because a path that is absent cannot
   be called. *)
check["S12 no shape-only acceptance path is left in the source",
  StringFreeQ[solveSource,
    "Dimensions[suppliedChannels] === Append[Dimensions[strip[[3]]]"]];

Print["t_multiquadratic_gauge_screen: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
