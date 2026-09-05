#!/usr/bin/env wolframscript
(* Alphabet construction and the residue-only integrability screen of
   FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticOffDiagonalBlockSolve.wl (2026-08-24).

   The fixture is the real off-diagonal block CF300 (12,9), read from the
   repository by a repository-relative path
   (Results/UU_08_10_canonical/FamilyEpsFormsSolving/
    FrozenTestFixtures_2026-08-25/cf300_frozen_strip_12_9_input.wl -- an
   immutable copy of a live campaign input, provenance in that
   directory's README), plus two small synthetic blocks built from a
   known gauge and known residues.

   ACCEPTANCE CRITERIA, stated before the run.

   Regulator samples.
   C1  Offered the pool {0, 1, -1, 2, 3, 5} -- the engine's historical
       sample list {0, 1, -1, 2} with two generic values appended -- the
       chooser returns {1, 2, 3, 5} and records 0 and -1 as REJECTED.
       Those two are poles of this block's inhomogeneity (its channel
       denominators carry eps^3 and 1 + eps), and the engine lost 14 of
       32 candidate dlogs on them.

   Polar curves and the norm filter.
   C2  The strip's rational polar curves are exactly the eight factors of
       the measured denominator census: x, y, -1+x, 1+x, -1+x+y, 1+x+y,
       -1+4xy and 1-2x+x^2+2y+2xy+y^2.
   C3  The norm filter ACCEPTS the norms of the four repair letters
         1-x-y-Sqrt[d1], 1-x+y-Sqrt[d1], 1+2y-Sqrt[d2], 1-2xy-Sqrt[d2]
       (norms -4y, -4xy, 4y(1+x+y), 4x^2y^2) and REJECTS six decoy
       letters whose norms carry an irreducible factor outside the
       alphabet.  Applied to that ten-element candidate set the filter
       accepts exactly the four.
   C4  The algebraic letter generator, given only the polar curves
       {x, y, 1+x+y} and the two declared root squares, PRODUCES all four
       repair letters (up to an overall sign, which a dlog does not see)
       with exactly those norms.
   C5  Every norm the generator emits passes the filter, and no emitted
       letter has norm zero.

   The integrability screen on CF300 (12,9).
   C6  On the block's candidate letters WITHOUT the algebraic family the
       screen returns the typed "AlphabetDLogAnsatzInconsistentAtFiniteFieldImage" with
       affine defect 1, and it MEASURED the diagonal connections flat
       (F_e = F_c = 0), which is what makes the residue-only reduction
       valid.
   C7  The obstruction carries a left witness w with A^T w = 0 and
       b . w != 0 modulo the screen prime.
   C8  With the four repair letters added the same screen returns
       "AlphabetIntegrabilityConsistent" with defect 0.
   C9  The screen never compiles or decomposes the block: it returns in
       under 120 s on a 2x2 block whose inhomogeneity has 10^5-leaf entries.

   The screen on synthetic blocks.
   C10 A block built from a known gauge and known residues over a flat
       1x1 diagonal pair is CONSISTENT with its own alphabet and an
       OBSTRUCTION once the letter that carries a nonzero residue is
       removed.
   C11 A block whose diagonal connection is NOT flat (non-commuting
       residue matrices) returns the typed
       "IntegrabilityScreenNotApplicable" with reason
       "DiagonalConnectionsNotFlat": the screen refuses to speak rather
       than dropping the gauge-dependent terms.

   Gauge denominator.
   C12 The norm gauge-denominator factor of the CF300 (12,9) alphabet is
       non-trivial, and merging it into the inhomogeneity gauge denominator
       admits each shared pole ONCE, at the larger order -- the merged
       degree is strictly smaller than the degree of the product. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* Long-route sections run only on request (user decision 2026-09-02): the
   real CF300 (12,9) block takes the compile route (~7900 s in a fresh
   kernel).  FACET_TEST_LONG=1 runs them; by default they are reported as
   skipped and the synthetic sections C10/C11 carry the contract. *)
longTestsQ = Environment["FACET_TEST_LONG"] === "1";

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 6]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{candidateLetters, regulatorSamples, polarCurves, normFilter,
  algebraicLetters, normFactor, mergeDenominator, screen, rootCensus,
  rootOrder, rationalOffDiagonalBasisTransformationDenominator, currentRoots} =
 mq /@ {"multiquadraticOffDiagonalBlockCandidateLetters",
   "multiquadraticOffDiagonalBlockRegulatorSampleValues",
   "multiquadraticOffDiagonalBlockRationalPolarCurves",
   "multiquadraticOffDiagonalBlockNormInAlphabetQ",
   "multiquadraticOffDiagonalBlockAlgebraicLetters",
   "multiquadraticOffDiagonalBlockNormDenominatorFactor",
   "multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominator",
   "multiquadraticOffDiagonalBlockIntegrabilityScreen",
   "multiquadraticOffDiagonalBlockRootCensus", "multiquadraticOffDiagonalBlockRootOrder",
   "multiquadraticRationalOffDiagonalBasisTransformationDenominator",
   "coefficientPresentationSquareRootsInVariables"};

If[longTestsQ,
(* ------------------------------------------------------------------ *)
(* The CF300 (12,9) fixture                                             *)
(* ------------------------------------------------------------------ *)

FeynFacet`LoadFamilyRootData[FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
   "Results", "UU_08_10_canonical", "TransportFamilyCharts.wl"}]];
chart = FeynFacet`FamilyRootData["CF300"];
(* FROZEN INPUT (2026-08-25): the live campaign directory rewrites this
   strip input under a running suite (it was rewritten at 13:41 by
   round 6), so the test reads an immutable copy with recorded
   provenance.  See the README of FrozenTestFixtures_2026-08-25/. *)
stripFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
   "UU_08_10_canonical", "FamilyEpsFormsSolving",
   "FrozenTestFixtures_2026-08-25", "cf300_frozen_strip_12_9_input.wl"}];
check["the CF300 (12,9) fixture is frozen in the repository",
  FileExistsQ[stripFile] && AssociationQ[chart]];
record = FeynFacet`FamilyArtifactRead[stripFile, "Global`"];
check["the fixture record carries a strip and its chart variables",
  AssociationQ[record] && MatchQ[record["Variables"], {_Symbol, _Symbol}] &&
    MatchQ[record["OffDiagonalBlockEquation"], {_List, _List, _List}]];
variables = record["Variables"];
regulator = record["Regulator"];
{vx, vy} = variables;
delta1 = 1 - 2 vx + vx^2 + 2 vy + 2 vx vy + vy^2;
delta2 = 1 - 4 vx vy;
allRoots = currentRoots[chart, variables];
census = rootCensus[record["OffDiagonalBlockEquation"], allRoots];
order = rootOrder[chart, variables, census["RootIndices"], regulator];
check["the fixture is a rank-2 multiquadratic strip over d1 and d2",
  Lookup[order, "Status", None] === "StableRootOrder" &&
    Length[order["Roots"]] === 2 &&
    Sort[Together /@ Lookup[order["Roots"], "QuadraticRadicand", {}]] ===
      Sort[Together /@ {delta1, delta2}]];
roots = order["Roots"];
dlogKernelText = Environment["FACET_MQ_TEST_DLOG_KERNELS"];
dlogKernels = If[StringQ[dlogKernelText] &&
    StringMatchQ[dlogKernelText, DigitCharacter ..],
  FromDigits[dlogKernelText], Automatic];

(* ---- C1: the regulator sample chooser ---- *)
samples = regulatorSamples[record["OffDiagonalBlockEquation"][[3]], variables, regulator, 4,
   {0, 1, -1, 2, 3, 5}];
check["C1 the chooser accepts four generic values and rejects the two poles",
  Lookup[samples, "Status", None] === "RegulatorSamplesChosen" &&
    samples["Values"] === {1, 2, 3, 5} &&
    Sort[samples["RejectedValues"]] === Sort[{0, -1}]];
report["C1 chosen / rejected regulator samples",
  {samples["Values"], samples["RejectedValues"]}];

(* ---- the candidate letter set (two samples, to keep the suite fast) ---- *)
{letterSeconds, letters} = AbsoluteTiming[candidateLetters[record["OffDiagonalBlockEquation"],
   roots, variables, regulator, record, "RegulatorSampleCount" -> 2,
   "DLogKernels" -> dlogKernels]];
check["the candidate letter set is built",
  Lookup[letters, "Status", None] === "MultiquadraticCandidateLettersV1"];
report["candidate letter counts", letters["Counts"]];
report["candidate letter seconds", Round[letterSeconds, 0.01]];

(* ---- C2: the polar curves ---- *)
expected = {vx, vy, -1 + vx, 1 + vx, -1 + vx + vy, 1 + vx + vy,
   -1 + 4 vx vy, delta1};
scaleEqualQ[u_, v_] := Module[{q = Together[u/v]},
  TrueQ[NumericQ[q] && q =!= 0]];
sameSetQ[a_List, b_List] := Length[a] === Length[b] &&
  AllTrue[a, Function[u, AnyTrue[b, scaleEqualQ[u, #1] &]]] &&
  AllTrue[b, Function[v, AnyTrue[a, scaleEqualQ[v, #1] &]]];
check["C2 the polar curves are the eight factors of the denominator census",
  sameSetQ[letters["Alphabet"], expected]];
report["C2 polar curves", letters["Alphabet"]];

(* ---- C3: the norm filter ---- *)
alphabet = letters["Alphabet"];
normOf[a_, delta_] := Expand[a^2 - delta];
repairPairs = {{1 - vx - vy, delta1}, {1 - vx + vy, delta1},
   {1 + 2 vy, delta2}, {1 - 2 vx vy, delta2}};
decoyPairs = {{1 - vx, delta1}, {1 + vx - vy, delta1}, {2 - vx - vy, delta1},
   {vx + vy, delta2}, {1 + vy, delta2}, {vx, delta1}};
check["C3 the filter accepts the four repair norms",
  AllTrue[repairPairs, TrueQ[normFilter[normOf @@ #1, alphabet, variables]] &]];
check["C3 the filter rejects every decoy norm",
  AllTrue[decoyPairs, ! TrueQ[normFilter[normOf @@ #1, alphabet, variables]] &]];
check["C3 out of the ten candidates exactly the four repair letters pass",
  Length[Select[Join[repairPairs, decoyPairs],
    TrueQ[normFilter[normOf @@ #1, alphabet, variables]] &]] === 4];
check["C3 the recorded norms are -4y, -4xy, 4y(1+x+y), 4x^2y^2",
  (Expand[normOf @@ #1] & /@ repairPairs) ===
    (Expand /@ {-4 vy, -4 vx vy, 4 vy (1 + vx + vy), 4 vx^2 vy^2})];
report["C3 decoy norms",
  Factor[normOf @@ #1] & /@ decoyPairs];

(* ---- C4/C5: the generator ---- *)
{generatorSeconds, generated} = AbsoluteTiming[
   algebraicLetters[roots, {vx, vy, 1 + vx + vy}, variables]];
report["C4 generator seconds / letters",
  {Round[generatorSeconds, 0.01], Length[generated]}];
(* a dlog does not see an overall sign: compare the letters up to sign *)
sameLetterQ[u_, v_] := TrueQ[Simplify[Together[u - v]] === 0] ||
  TrueQ[Simplify[Together[u + v]] === 0];
repairLetters = {1 - vx - vy - Sqrt[delta1], 1 - vx + vy - Sqrt[delta1],
   1 + 2 vy - Sqrt[delta2], 1 - 2 vx vy - Sqrt[delta2]};
check["C4 the generator produces all four repair letters",
  AllTrue[repairLetters, Function[target,
    AnyTrue[Lookup[generated, "Letter", {}], sameLetterQ[#1, target] &]]]];
check["C5 every generated norm passes the filter and is non-zero",
  generated =!= {} &&
    AllTrue[generated, ! TrueQ[Together[#1["Norm"]] === 0] &&
      TrueQ[normFilter[#1["Norm"], {vx, vy, 1 + vx + vy}, variables]] &]];
report["C4 generated letters",
  Lookup[generated, "Letter", {}]];

(* ---- C6/C7/C8/C9: the screen on the real block ---- *)
baseRecords = Select[letters["LetterRecords"],
   MemberQ[{"Diagonal", "InhomogeneityDLog", "RationalFactor"}, #1["Kind"]] &];
dlogPair[f_] := {Together[D[f, vx]/f], Together[D[f, vy]/f]};
repairRecords = <|"Kind" -> "Algebraic", "Letter" -> #1,
    "OneForm" -> dlogPair[#1]|> & /@ repairLetters;
sampleValue = First[letters["RegulatorValues"]];
{screenSeconds, obstruction} = AbsoluteTiming[
   screen[record, roots, baseRecords, "PointCount" -> 12,
     "RegulatorValue" -> sampleValue, "ScoreLetters" -> False]];
check["C6 the screen on the non-algebraic letters is a typed obstruction",
  Lookup[obstruction, "Status", None] === "AlphabetDLogAnsatzInconsistentAtFiniteFieldImage"];
check["C6 the affine defect is 1",
  Lookup[obstruction, "Defect", None] === 1 &&
    obstruction["AugmentedRank"] === obstruction["Rank"] + 1];
check["C6 the diagonal connections were MEASURED flat",
  TrueQ[obstruction["FlatDiagonalConnections"]]];
check["C7 the obstruction carries a verified left witness",
  AssociationQ[obstruction["Witness"]] &&
    TrueQ[obstruction["Witness"]["TransposeResidualZero"]] &&
    obstruction["Witness"]["RightHandSidePairing"] =!= 0];
check["C9 the screen returns in under 120 s", screenSeconds < 120];
report["C6 obstruction", KeyTake[obstruction,
  {"Status", "Defect", "Rank", "AugmentedRank", "MatrixDimensions",
   "LetterCount", "PointCount", "Prime", "RegulatorValue"}]];
report["C9 screen seconds", Round[screenSeconds, 0.01]];

{repairedSeconds, repaired} = AbsoluteTiming[
   screen[record, roots, Join[baseRecords, repairRecords], "PointCount" -> 12,
     "RegulatorValue" -> sampleValue, "ScoreLetters" -> False]];
check["C8 the four repair letters make the same system consistent",
  Lookup[repaired, "Status", None] === "AlphabetIntegrabilityConsistent" &&
    repaired["Defect"] === 0 &&
    repaired["Rank"] === repaired["AugmentedRank"]];
check["C8 the repair adds exactly four letters and 16 unknowns",
  repaired["LetterCount"] === obstruction["LetterCount"] + 4 &&
    repaired["UnknownCount"] === obstruction["UnknownCount"] + 16];
report["C8 repaired", KeyTake[repaired,
  {"Status", "Defect", "Rank", "AugmentedRank", "MatrixDimensions",
   "LetterCount"}]];

(* ---- C12: the norm gauge-denominator factor ---- *)
factor = normFactor[letters["LetterRecords"], variables];
check["C12 the norm gauge-denominator factor is a non-constant polynomial",
  PolynomialQ[Together[factor], variables] &&
    ! FreeQ[factor, Alternatives @@ variables]];
check["C12 the merge takes the larger order of a shared factor, not the product",
  TrueQ[Together[mergeDenominator[(1 + vx)^2 vy, (1 + vx) vy^3, variables] /
      ((1 + vx)^2 vy^3)] === 1]];
(* the eps-free part of the gauge denominator this block's inhomogeneity rule
   produces, as MEASURED by the post-mortem denominator census:
   y (-1+x+y) (-1+4xy)^2 times an eps-dependent factor.  Recomputing it
   here would decompose the inhomogeneity into channels, which is the 807 s the
   screen exists to avoid. *)
baseDenominator = vy (-1 + vx + vy) (-1 + 4 vx vy)^2;
merged = mergeDenominator[baseDenominator, factor, variables];
productDegrees = Exponent[Together[baseDenominator factor], #1] & /@ variables;
mergedDegrees = Exponent[Together[merged], #1] & /@ variables;
check["C12 merging admits each shared pole once, at the larger order",
  AllTrue[Range[2], mergedDegrees[[#1]] < productDegrees[[#1]] &] &&
    AllTrue[Range[2],
      mergedDegrees[[#1]] >= Exponent[Together[baseDenominator], variables[[#1]]] &] &&
    AllTrue[Range[2],
      mergedDegrees[[#1]] >= Exponent[Together[factor], variables[[#1]]] &]];
report["C12 base / factor / merged / product degrees",
  {Exponent[Together[baseDenominator], #1] & /@ variables,
   Exponent[Together[factor], #1] & /@ variables, mergedDegrees,
   productDegrees}];


,
  Print["C1-C12 (real CF300 (12,9) block) skipped: set FACET_TEST_LONG=1 to run them"]];
(* ------------------------------------------------------------------ *)
(* C10 / C11: synthetic blocks with a known answer                      *)
(* ------------------------------------------------------------------ *)

Clear[sx, sy, se];
syntheticLetters = {sx, sy, 1 - sx - sy, 1 + sx + sy};
syntheticForms = {Together[D[Log[#1], sx]], Together[D[Log[#1], sy]]} & /@
   syntheticLetters;
syntheticRecords = <|"Kind" -> "Supplied", "Letter" -> #1[[1]],
    "OneForm" -> #1[[2]]|> & /@ Transpose[{syntheticLetters, syntheticForms}];
(* a 1x1 diagonal pair is flat for any residues; the inhomogeneity is BUILT
   from a known gauge and known residues, so the screen must accept it *)
(* e and c are built from letters 1 and 2 ONLY and the residues sit on
   letters 3 and 4: a diagonal pair that already uses a residue-carrying
   letter mixes its column into the others and the removal below would be
   vacuous rather than an obstruction. *)
syntheticE = {{{2 syntheticForms[[1, 1]]}}, {{2 syntheticForms[[1, 2]]}}};
syntheticC = {{{3 syntheticForms[[2, 1]]}}, {{3 syntheticForms[[2, 2]]}}};
syntheticOffDiagonalBasisTransformationBlock = {{(1 + 2 sx - 3 sy + sx sy)/(1 - sx - sy)}};
syntheticResidues = {{{0}}, {{0}}, {{5/2}}, {{-3}}};
syntheticInhomogeneity = Table[
   Map[Together, D[syntheticOffDiagonalBasisTransformationBlock, {sx, sy}[[mu]]] -
     se (syntheticE[[mu]] . syntheticOffDiagonalBasisTransformationBlock -
       syntheticOffDiagonalBasisTransformationBlock . syntheticC[[mu]]) +
     se Sum[syntheticResidues[[a]] syntheticForms[[a, mu]],
       {a, Length[syntheticLetters]}], {2}],
   {mu, 2}];
syntheticRecord = <|"Family" -> "SYNTHETIC_FLAT", "Sector" -> 3,
   "LowerSector" -> 1, "Variables" -> {sx, sy}, "Regulator" -> se,
   "OffDiagonalBlockEquation" -> {syntheticE, syntheticC, syntheticInhomogeneity}|>;
syntheticScreen = screen[syntheticRecord, {}, syntheticRecords,
   "PointCount" -> 8, "RegulatorValue" -> 1/13, "ScoreLetters" -> False];
check["C10 the synthetic block is consistent with its own alphabet",
  Lookup[syntheticScreen, "Status", None] ===
      "AlphabetIntegrabilityConsistent" &&
    syntheticScreen["Defect"] === 0 &&
    TrueQ[syntheticScreen["FlatDiagonalConnections"]]];
report["C10 synthetic (full alphabet)", KeyTake[syntheticScreen,
  {"Status", "Defect", "Rank", "AugmentedRank", "MatrixDimensions"}]];
strippedScreen = screen[syntheticRecord, {}, Drop[syntheticRecords, {3}],
   "PointCount" -> 8, "RegulatorValue" -> 1/13, "ScoreLetters" -> False];
check["C10 removing the letter that carries a residue is an obstruction",
  Lookup[strippedScreen, "Status", None] ===
      "AlphabetDLogAnsatzInconsistentAtFiniteFieldImage" && strippedScreen["Defect"] >= 1 &&
    AssociationQ[strippedScreen["Witness"]] &&
    TrueQ[strippedScreen["Witness"]["TransposeResidualZero"]]];
report["C10 synthetic (letter 1-x-y removed)", KeyTake[strippedScreen,
  {"Status", "Defect", "Rank", "AugmentedRank", "MatrixDimensions"}]];

(* a 2x2 diagonal connection whose residue matrices do not commute has
   F_e != 0; the residue-only reduction is then invalid and the screen
   must say so instead of answering *)
curvedE = Table[
   {{1, 1}, {0, 1}} syntheticForms[[1, mu]] +
     {{0, 0}, {1, 1}} syntheticForms[[2, mu]], {mu, 2}];
curvedRecord = <|"Family" -> "SYNTHETIC_CURVED", "Sector" -> 3,
   "LowerSector" -> 1, "Variables" -> {sx, sy}, "Regulator" -> se,
   "OffDiagonalBlockEquation" -> {curvedE, {{{0}}, {{0}}},
     {{{1/sx}, {1/sy}}, {{1/(1 - sx - sy)}, {1}}}}|>;
curvedScreen = screen[curvedRecord, {}, syntheticRecords, "PointCount" -> 6,
   "RegulatorValue" -> 1/13, "ScoreLetters" -> False];
check["C11 a non-flat diagonal connection makes the screen not applicable",
  Lookup[curvedScreen, "Status", None] === "IntegrabilityScreenNotApplicable" &&
    Lookup[curvedScreen, "Reason", None] === "DiagonalConnectionsNotFlat" &&
    Lookup[curvedScreen, "FlatDiagonalConnections", True] === False];
report["C11 curved", KeyTake[curvedScreen,
  {"Status", "Reason", "FlatDiagonalConnections"}]];

Print["t_multiquadratic_letters: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
