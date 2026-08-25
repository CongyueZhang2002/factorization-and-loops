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
   triple_root_2026-08-24_fable/CF300/.

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
obstructionImages = gaugeScreenImages[strippedAnsatz];
check["G5 a consistent first image is not repeated",
  Lookup[consistentImages, "Status", None] === "GaugeImageConsistent" &&
    consistentImages["ImageCount"] === 1];
check["G5 a defect is confirmed at a second independent image",
  Lookup[obstructionImages, "Status", None] === "GaugeImageObstruction" &&
    obstructionImages["ImageCount"] === 2 &&
    obstructionImages["Defects"] === {1, 1}];
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
base = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
   "UU_08_10_canonical", "FamilyEpsFormsSolving",
   "triple_root_2026-08-24_fable", "CF300"}];
stripFile = FileNameJoin[{base, "sector_CF300_standard",
   "CF300_12_9_input.wl"}];
(* the MEASURED channel decomposition of this block's forcing, moved into
   the repository as evidence 2026-08-25.  Recomputing it here is the
   ~10^3 s preparation stage the screen exists to run in front of. *)
channelFile = FileNameJoin[{base, "gauge_screen_2026-08-25",
   "channelForcing.wl"}];
check["the CF300 (12,9) fixture and its channel census are in the repository",
  FileExistsQ[stripFile] && FileExistsQ[channelFile] &&
    FileExistsQ[FileNameJoin[{base, "sector_state_CF300_standard.wl"}]] &&
    AssociationQ[chart]];

(* the sector state carries the row's installed alphabets; without them
   the candidate letter set is 52 rather than the measured 54, and the
   ansatz is not the one the 2026-08-25 evidence records *)
stateFile = FileNameJoin[{base, "sector_state_CF300_standard.wl"}];
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

Print["t_multiquadratic_gauge_screen: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
