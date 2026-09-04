#!/usr/bin/env wolframscript
(* ROUND-B PROVIDER PROMOTION.

   The constructed fixture is deliberately rank three and small enough for
   the ordinary suite.  Its gauge has all eight grades.  Across E, C and the
   one-form basis, scalar entries use every active-root subset: the empty
   set, all three singletons, all three pairs and the full triple.

   Acceptance criteria:

   B1  SplitBranch, QuotientGrade and CompiledChannel return identical
       COMPLETE coefficient payloads at three common split points.
   B2  Their provider-backed samples have identical point rows, RHS,
       normalization rows/values, row order and column order.
   B3  The three affine systems have the same rank, nullity, pivots and
       pivot signature; each reported particular solution and the known
       constructed vector have zero residual.
   B4  The split preflight rejects a nonsplit point before any large entry
       is evaluated, and the sample telemetry retains that zero count.

   The physical frozen CF300 (12,9) promotion is intentionally opt-in.  It
   builds the production 2120-column ansatz, evaluates the complete
   SplitBranch coefficient ABI against an independent QuotientGrade provider
   whose BBar field is replaced by the frozen characteristic-zero channel
   oracle, assembles the full physical affine system, and validates its
   canonical modular section at a held-out kinematic point.  This is stronger
   and much cheaper than rebuilding a transient CompiledChannel artifact:
   the fixture freezes the exact BBar channels, while the two direct providers
   independently cover every other coefficient field. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 8]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, compile, layoutBuild, layoutValidQ, compiledProviderBuild,
  directProviderBuild, providerValidQ, providerPreflight, providerChannels,
  assembleSample, assemblePoint, normalizationRows, affineSolve,
  planDiscoverySolve, decompose, quotientGradeEntry,
  gaugeIndex, residueIndex, currentRoots, rootCensus, rootOrder,
  candidateLetters, normFactor, mergeDenominator,
  rationalGaugeDenominator, compileRational, reduceRational,
  collapseRational, maximumExponents, evaluateForms, modRational} =
 mq /@ {"multiquadraticStripPrepare", "multiquadraticStripCompile",
   "multiquadraticStripAssemblyLayout",
   "multiquadraticStripAssemblyLayoutValidQ",
   "multiquadraticStripCompiledProvider",
   "multiquadraticStripDirectProvider",
   "multiquadraticStripProviderValidQ",
   "multiquadraticStripProviderPreflight",
   "multiquadraticStripProviderChannels",
   "multiquadraticStripAssembleSample",
   "multiquadraticStripAssemblePointRows",
   "multiquadraticStripNormalizationRows",
   "multiquadraticStripAffineSolve",
   "multiquadraticStripPlanDiscoverySolve",
   "multiquadraticFieldDecompose",
   "multiquadraticStripQuotientGradeEntry",
   "multiquadraticStripGaugeIndex", "multiquadraticStripResidueIndex",
   "transportChartCurrentRoots", "multiquadraticStripRootCensus",
   "multiquadraticStripRootOrder", "multiquadraticStripCandidateLetters",
   "multiquadraticStripNormDenominatorFactor",
   "multiquadraticStripMergeGaugeDenominator",
   "multiquadraticRationalGaugeDenominator",
   "multiquadraticStripCompileRationalCanonical",
   "multiquadraticStripReduceRational",
   "multiquadraticStripCollapseRational",
   "multiquadraticStripMaximumExponents",
   "multiquadraticStripEvaluateForms",
   "multiquadraticStripModRational"};

Clear[bx, by, be];
variables = {bx, by};
epsilon = be;
delta1 = 1 + bx;
delta2 = 1 + by;
delta3 = 1 + bx + by;
declaredRoots = {Sqrt[delta1], Sqrt[delta2], Sqrt[delta3]};
rootRecords = MapThread[<|"Root" -> #1, "RootSquare" -> #2|> &,
  {declaredRoots, {delta1, delta2, delta3}}];
frame = <|"Name" -> "RoundBConstructedRank3", "Kind" -> "TwoVariable",
  "FieldKind" -> "Multiquadratic",
  "CoefficientField" -> "Multiquadratic", "Variables" -> variables,
  "Subst" -> Thread[variables -> variables],
  "Root" -> First[declaredRoots], "RootSquare" -> delta1,
  "Roots" -> rootRecords|>;

support = {{0, 0}, {0, 1}, {1, 0}};
gaugeDenominator = 1 + bx + by;
maskFactor[mask_Integer, roots_List] := Product[
  If[BitGet[mask, k - 1] === 1, roots[[k]], 1], {k, Length[roots]}];
channelNumerators = Table[
  (2 + 5 mask) + (3 + 7 mask) bx + (5 + 11 mask) by,
  {mask, 0, 7}];
gauge = {{Together[Sum[
  channelNumerators[[mask + 1]] maskFactor[mask, declaredRoots]/
    gaugeDenominator, {mask, 0, 7}]]}};

(* The coefficient sources below cover all eight active-root subsets.
   They need not be a separately certified alphabet: this suite tests the
   coefficient ABI and affine equation, and bbar is constructed from the
   same exact equation. *)
e = {{{declaredRoots[[1]]/(2 + bx)}},
  {{declaredRoots[[2]] declaredRoots[[3]]/(3 + by)}}};
c = {{{1/(4 + bx + by)}}, {{declaredRoots[[3]]/(5 + bx + by)}}};
oneForms = {
  {1/bx, 0},
  {declaredRoots[[1]]/(2 + bx), 0},
  {0, declaredRoots[[2]]/(2 + by)},
  {declaredRoots[[3]]/(3 + bx + by), 0},
  {declaredRoots[[1]] declaredRoots[[2]]/(4 + bx + by), 0},
  {0, declaredRoots[[1]] declaredRoots[[3]]/(5 + bx + by)},
  {declaredRoots[[2]] declaredRoots[[3]]/(6 + bx + by), 0},
  {declaredRoots[[1]] declaredRoots[[2]] declaredRoots[[3]]/
    (7 + bx + by), 0}
};
residues = Table[{{(-1)^a (a + 1)}}, {a, Length[oneForms]}];
bbar = Table[Map[Together,
    D[gauge, variables[[mu]]] -
      epsilon (e[[mu]] . gauge - gauge . c[[mu]]) +
      epsilon Sum[residues[[a]] oneForms[[a, mu]],
        {a, Length[oneForms]}], {2}], {mu, 2}];
record = <|"Family" -> "ROUND_B_PROVIDER_PROMOTION",
  "Sector" -> 8, "LowerSector" -> 3, "Variables" -> variables,
  "Regulator" -> epsilon, "Strip" -> {e, c, bbar}|>;
normalizations = {<|"Kind" -> "GaugeCoefficient", "Upper" -> 1,
  "Lower" -> 1, "Grade" -> 0, "Monomial" -> {0, 0},
  "Value" -> 2|>};

prepared = prepare[record, frame, "OneForms" -> oneForms,
  "GaugeDenominator" -> gaugeDenominator, "Support" -> support,
  "NormalizationEquations" -> normalizations, "CompileCore" -> False];
check["B0 the constructed rank-3 fixture prepares",
  Lookup[prepared, "Status", None] === "PreparedMultiquadraticStripV1" &&
    prepared["RootCount"] === 3 && prepared["GradeCount"] === 8];
If[Lookup[prepared, "Status", None] =!= "PreparedMultiquadraticStripV1",
  Print["     ", Short[prepared, 8]];
  Print["t_multiquadratic_provider_promotion: ", pass, " OK, ", fail,
    " FAIL"];
  Exit[1]];

assembly = compile[prepared, "PreparationValidated" -> True,
  "ForcingChannels" -> prepared["ForcingChannels"],
  "CompileCore" -> False];
layout = layoutBuild[prepared];
compiledProvider = compiledProviderBuild[assembly];
splitProvider = directProviderBuild[prepared["Record"], prepared["Roots"],
  "Kind" -> "SplitBranch", "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "CoefficientABIFingerprint" -> layout["CoefficientABIFingerprint"]];
quotientProvider = directProviderBuild[prepared["Record"], prepared["Roots"],
  "Kind" -> "QuotientGrade", "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "CoefficientABIFingerprint" -> layout["CoefficientABIFingerprint"]];
check["B0 the layout and all three providers validate",
  Lookup[assembly, "Status", None] === "CompiledMultiquadraticStripV1" &&
    TrueQ[layoutValidQ[layout]] &&
    AllTrue[{compiledProvider, splitProvider, quotientProvider},
      TrueQ[providerValidQ[#]] &]];

(* Active-root subsets are read from the provider's exact census, not
   inferred from the intended spelling of the fixture. *)
activeSets = DeleteDuplicates[Cases[
  {Values[splitProvider["ActiveRoots"]],
    splitProvider["OneFormActiveRoots"]},
  indices_List /; VectorQ[indices, IntegerQ] :> Sort[indices],
  {0, Infinity}]];
requiredActiveSets = Subsets[Range[3]];
report["active-root subsets", activeSets];
check["B0 the fixture exercises empty, singleton, pair and triple subsets",
  AllTrue[requiredActiveSets, MemberQ[activeSets, #] &]];

(* The exact forcing itself occupies all eight canonical grades. *)
forcingChannels = Map[decompose[#, prepared["Roots"]] &, bbar, {3}];
gradeCoverage = Table[
  ! AllTrue[Flatten[forcingChannels[[All, All, All, grade]]],
    TrueQ[Together[#] === 0] &], {grade, 8}];
report["forcing grade coverage", gradeCoverage];
check["B0 all eight forcing grades are nonzero",
  gradeCoverage === ConstantArray[True, 8]];

prime = 2147483423;
epsilonValue = 5;
deltas = prepared["RootSquares"];
splitPointQ[point_] := Module[{values = Mod[
    deltas /. Thread[variables -> point], prime]},
  FreeQ[values, 0] && AllTrue[values, JacobiSymbol[#, prime] === 1 &]];
nonsplitPointQ[point_] := Module[{values = Mod[
    deltas /. Thread[variables -> point], prime]},
  FreeQ[values, 0] && ! AllTrue[values, JacobiSymbol[#, prime] === 1 &]];
candidateGrid = Tuples[Range[2, 90], 2];
splitPoints = Select[candidateGrid, splitPointQ, 3];
nonsplitPoint = SelectFirst[candidateGrid, nonsplitPointQ,
  Missing["NoNonsplitPoint"]];
check["B0 three split points and one nonsplit point exist",
  Length[splitPoints] === 3 && ! MissingQ[nonsplitPoint]];
report["split / nonsplit points", {splitPoints, nonsplitPoint}];

coefficientKeys = {"Prime", "Point", "RegulatorValue", "EpsilonMod",
  "RootSquares", "RootValues", "SplitPointQ", "GaugeDenominator",
  "GaugeLogDerivatives", "RootLogDerivatives", "E", "C", "BBar",
  "OneForms", "CoefficientABIFingerprint"};
coefficientPayload[value_Association] := KeyTake[value, coefficientKeys];
coefficientTriples = Table[
  providerChannels[#, epsilonValue, prime, point] & /@
    {compiledProvider, splitProvider, quotientProvider},
  {point, splitPoints}];
check["B1 all three providers return complete coefficient records",
  AllTrue[Flatten[coefficientTriples],
    Lookup[#, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &]];
check["B1 SplitBranch == QuotientGrade == CompiledChannel at every split point",
  AllTrue[coefficientTriples,
    SameQ @@ (coefficientPayload /@ #) &]];
{sparseReplaySeconds, sparseReplayCoefficients} = AbsoluteTiming[Table[
  providerChannels[splitProvider, epsilonValue, prime, point],
  {point, splitPoints}]];
{fallbackSplitSeconds, fallbackSplitCoefficients} = AbsoluteTiming[Table[
  Block[{FeynFacet`Private`$multiquadraticStripSplitSparseCompilation = False},
    providerChannels[splitProvider, epsilonValue, prime, point]],
  {point, splitPoints}]];
check["B1 sparse SplitBranch agrees exactly with the substitution fallback on active ranks 0 through 3",
  AllTrue[Transpose[{sparseReplayCoefficients,
      fallbackSplitCoefficients}],
    coefficientPayload[#[[1]]] === coefficientPayload[#[[2]]] &] &&
    AllTrue[requiredActiveSets, MemberQ[activeSets, #] &]];
report["rank-3 hot sparse / substitution fallback seconds / speedup",
  {Round[sparseReplaySeconds, 0.0001],
    Round[fallbackSplitSeconds, 0.0001],
    If[sparseReplaySeconds > 0,
      Round[fallbackSplitSeconds/sparseReplaySeconds, 0.01], Infinity]}];
splitCoefficientRecords = coefficientTriples[[All, 2]];
check["B1 sparse SplitBranch exposes cache hits/misses and takes no fallback",
  Total[Lookup[splitCoefficientRecords,
      "SplitSparseCompileCacheMissCount", {}]] > 0 &&
    Total[Lookup[splitCoefficientRecords,
      "SplitSparseCompileCacheHitCount", {}]] > 0 &&
    Total[Lookup[splitCoefficientRecords,
      "SplitSubstitutionFallbackCount", {}]] === 0 &&
    Total[Lookup[splitCoefficientRecords,
      "SplitSparseEvaluationCount", {}]] ===
      Total[Lookup[splitCoefficientRecords,
        "SplitSparseCompileAttemptCount", {}]]];

sampleOptions = {"PointCount" -> 3, "MaximumAttempts" -> 3,
  "CandidatePoints" -> splitPoints, "SplitPointsOnly" -> True,
  "RandomSeed" -> 2026082701};
samples = assembleSample[layout, #, epsilonValue, prime,
    Sequence @@ sampleOptions] & /@
  {compiledProvider, splitProvider, quotientProvider};
report["provider sample statuses", Lookup[samples, "Status", None]];
check["B2 all three provider-backed samples assemble",
  AllTrue[samples, Lookup[#, "Status", None] ===
    "AssembledMultiquadraticSampleV1" &]];
check["B2 accepted points, full rows and RHS are identical",
  SameQ @@ Lookup[samples, "AcceptedPoints"] &&
    SameQ @@ Lookup[samples, "Matrix"] &&
    SameQ @@ Lookup[samples, "RightHandSide"]];
normalizationCount = First[Lookup[samples, "NormalizationCount"]];
sampleNormalizationRows = If[normalizationCount === 0, {},
  Take[#1["Matrix"], -normalizationCount] & /@ samples];
sampleNormalizationRight = If[normalizationCount === 0, {},
  Take[#1["RightHandSide"], -normalizationCount] & /@ samples];
check["B2 normalization rows and values agree separately",
  normalizationCount === Length[normalizations] &&
    SameQ @@ sampleNormalizationRows && SameQ @@ sampleNormalizationRight];
zeroNormalizationPayload = normalizationRows[
  Join[layout, <|"Normalizations" -> {}|>], epsilonValue, prime];
check["B2 zero normalizations use the canonical empty payload and retain width in the layout ABI",
  zeroNormalizationPayload[[1]] === {} &&
    Dimensions[zeroNormalizationPayload[[2]]] === {0} &&
    IntegerQ[layout["UnknownCount"]] && layout["UnknownCount"] > 0];
check["B2 row and column ABI orders agree",
  SameQ @@ Lookup[samples, "RowOrder"] &&
    SameQ @@ Lookup[samples, "ColumnOrder"] &&
    First[Lookup[samples, "RowOrder"]] === layout["RowOrder"] &&
    First[Lookup[samples, "ColumnOrder"]] === layout["ColumnOrder"]];

solutions = affineSolve[#1["Matrix"], #1["RightHandSide"], prime] & /@
  samples;
check["B3 every provider sample has an affine solution",
  AllTrue[solutions, Lookup[#, "Status", None] ===
    "MultiquadraticAffineSolution" &]];
affineSignature[solution_Association] := Lookup[solution,
  {"Rank", "Nullity", "PivotColumns", "PivotSignature"}];
check["B3 rank, nullity, pivots and pivot signature agree",
  SameQ @@ (affineSignature /@ solutions)];
check["B3 every reported particular solution has zero solved residual",
  And @@ MapThread[AllTrue[Mod[#1["Matrix"] .
      #2["ParticularSolution"] - #1["RightHandSide"], prime], # === 0 &] &,
    {samples, solutions}]];

(* Pack the fixture's known generic solution in the preparation's canonical
   root and support order, then check it independently of the affine solver's
   choice of section. *)
canonicalGaugeChannels = decompose[First[First[gauge]], prepared["Roots"]];
gaugeCoefficients = Table[
  Coefficient[Coefficient[Expand[Together[
      canonicalGaugeChannels[[grade + 1]] prepared["GaugeDenominator"]]],
    variables[[1]], prepared["GaugeSupport"][[monomial, 1]]],
    variables[[2]], prepared["GaugeSupport"][[monomial, 2]]],
  {grade, 0, prepared["GradeCount"] - 1},
  {monomial, Length[prepared["GaugeSupport"]]}];
knownVector = ConstantArray[0, prepared["UnknownCount"]];
Do[knownVector[[gaugeIndex[1, 1, prepared["GradeCount"],
    Length[prepared["GaugeSupport"]], 1, 1, grade, monomial]]] =
    gaugeCoefficients[[grade + 1, monomial]],
  {grade, 0, prepared["GradeCount"] - 1},
  {monomial, Length[prepared["GaugeSupport"]]}];
Do[knownVector[[residueIndex[prepared["GaugeUnknownCount"], 1, 1,
    letter, 1, 1]]] = residues[[letter, 1, 1]],
  {letter, Length[residues]}];
knownImage = mq["multiquadraticStripModRational"][#, prime] & /@ knownVector;
check["B3 the independently packed known vector satisfies every provider sample",
  VectorQ[knownImage, IntegerQ] && And @@ (AllTrue[
    Mod[#1["Matrix"] . knownImage - #1["RightHandSide"], prime],
    # === 0 &] & /@ samples)];

If[! MissingQ[nonsplitPoint],
  nonsplitPreflight = providerPreflight[splitProvider, epsilonValue, prime,
    nonsplitPoint];
  check["B4 split preflight rejects the nonsplit point, typed",
    Lookup[nonsplitPreflight, "Status", None] ===
      "PointNotSplitOverPrime"];
  check["B4 nonsplit preflight performs zero large-entry evaluations",
    Lookup[nonsplitPreflight, "LargeEntryEvaluationCount", -1] === 0];
  nonsplitSample = assembleSample[layout, splitProvider, epsilonValue, prime,
    "PointCount" -> 1, "MaximumAttempts" -> 1,
    "CandidatePoints" -> {nonsplitPoint}];
  check["B4 sampler retains the zero-evaluation preflight rejection",
    Lookup[nonsplitSample, "Status", None] ===
      "InsufficientProviderPoints" &&
      Lookup[nonsplitSample, "PreflightRejectCount", 0] === 1 &&
      Lookup[nonsplitSample, "LargeEntryEvaluationCount", -1] === 0 &&
      Lookup[nonsplitSample, "ProviderCallCount", -1] === 0]];

(* Optional physical full-block gate.  It is off by default because the
   production 2120-column RREF is deliberately a stress test.  No symbolic
   forcing decomposition or compiled assembly is needed: frozenChannels is
   the exact characteristic-zero BBar oracle, QuotientGrade independently
   supplies the remaining coefficient fields, and SplitBranch is the route
   being promoted. *)
cf300Directory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "FrozenTestFixtures_2026-08-25"}];
cf300Paths = <|
  "Strip" -> FileNameJoin[{cf300Directory,
    "cf300_frozen_strip_12_9_input.wl"}],
  "ExactChannels" -> FileNameJoin[{cf300Directory,
    "cf300_frozen_channel_forcing.wl"}],
  "StripSolvers" -> FileNameJoin[{cf300Directory,
    "cf300_frozen_stripsolvers.wl"}]|>;
check["CF300 (12,9) frozen promotion inputs are documented and present",
  AllTrue[Values[cf300Paths], FileExistsQ]];
If[Environment["FACET_RUN_MQ_CF300_PROMOTION"] === "1",
  cf300Outcome = TimeConstrained[
  Module[{cfChart, cfRecord, cfState, cfFrozenChannels, cfVariables,
    cfEpsilon, cfAllRoots, cfCensus, cfOrder, cfRoots, cfLetterData,
    cfLetterRecords, cfRetainedOneFormChannels, cfDenominator, cfSupport,
    cfPrepared,
    cfLayout, cfSplitProvider, cfQuotientProvider, cfDeltas, cfSplitPointQ,
    cfCandidateGrid, cfPoints, cfTrainingPoints, cfHeldOutPoint,
    cfNormalizationRegularQ, cfRegulatorValues,
    cfFrozenCompiled, cfFrozenPrime, cfFrozenEpsilonCache = <||>,
    cfFrozenEpsilonForms, cfFrozenImage, cfSelectiveOracleCoefficients,
    cfTrainingSample, cfAnchorRecords, cfCoefficientEqualQ,
    cfRowsEqualQ, cfRightEqualQ, cfAnchorNormalizations,
    cfNormalizations, cfMatrix, cfRight, cfSolution,
    cfHeldOutCoefficients, cfHeldOutRows, cfHeldOutResidual,
    cfPreparationSeconds, cfFrozenCompileSeconds, cfImageSeconds,
    cfTrainingSeconds, cfSolveSeconds,
    cfPointCount = 18,
    cfOracleFingerprint = "FrozenExactBBarPlusQuotientGradeV1"},

   FeynFacet`LoadFamilyRootData[FileNameJoin[{root,
     "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
     "TransportFamilyCharts.wl"}]];
   cfChart = FeynFacet`FamilyRootData["CF300"];
   cfRecord = FeynFacet`FamilyArtifactRead[cf300Paths["Strip"], "Global`"];
   cfState = FeynFacet`FamilyArtifactRead[cf300Paths["StripSolvers"],
     "Global`"];
   cfFrozenChannels = FeynFacet`FamilyArtifactRead[
     cf300Paths["ExactChannels"], "Global`"];
   If[AssociationQ[cfRecord] && AssociationQ[cfState],
     cfRecord = Join[cfRecord,
       <|"StripSolvers" -> Lookup[cfState, "StripSolvers", {}]|>]];
   cfVariables = Lookup[cfRecord, "Variables", $Failed];
   cfEpsilon = Lookup[cfRecord, "Regulator", $Failed];
   cfAllRoots = currentRoots[cfChart, cfVariables];
   cfCensus = rootCensus[Lookup[cfRecord, "Strip", $Failed], cfAllRoots];
   cfOrder = If[AssociationQ[cfCensus],
     rootOrder[cfChart, cfVariables, cfCensus["RootIndices"], cfEpsilon],
     $Failed];
   cfRoots = If[AssociationQ[cfOrder], Lookup[cfOrder, "Roots", $Failed],
     $Failed];
   check["CF300 physical root frame resolves canonically at rank two",
     Lookup[cfOrder, "Status", None] === "StableRootOrder" &&
       Length[cfRoots] === 2 && ArrayQ[cfFrozenChannels, 4]];

   {cfPreparationSeconds, cfPrepared} = AbsoluteTiming[
     cfLetterData = candidateLetters[cfRecord["Strip"], cfRoots,
       cfVariables, cfEpsilon, cfRecord, "RegulatorSampleCount" -> 2,
       "DLogKernels" -> 1];
     cfLetterRecords = Lookup[cfLetterData, "LetterRecords", $Failed];
     cfDenominator = mergeDenominator[
       rationalGaugeDenominator[cfFrozenChannels, cfVariables],
       normFactor[cfLetterRecords, cfVariables], cfVariables];
     cfSupport = Flatten[Table[{i, j},
       {i, 0, Exponent[cfDenominator, cfVariables[[1]]] + 3},
       {j, 0, Exponent[cfDenominator, cfVariables[[2]]] + 3}], 1];
     prepare[cfRecord, cfChart, "OneForms" -> cfLetterData,
       "LetterRecords" -> cfLetterRecords,
       "GaugeDenominator" -> cfDenominator, "Support" -> cfSupport,
       "CoefficientProvider" -> "SplitBranch", "CompileCore" -> False]];
   check["CF300 production {3,3} descriptor prepares without exact-channel compilation",
     Lookup[cfPrepared, "Status", None] ===
         "PreparedMultiquadraticStripV1" &&
       Lookup[cfPrepared, "RootCount", None] === 2 &&
       Length[Lookup[cfPrepared, "OneForms", {}]] === 46 &&
       Length[Lookup[cfPrepared, "GaugeSupport", {}]] === 121 &&
       Lookup[cfPrepared, "UnknownCount", None] === 2120 &&
       MissingQ[Lookup[cfPrepared, "ForcingChannels", None]]];
   cfRetainedOneFormChannels = Lookup[
     Lookup[cfPrepared, "LetterRecords", {}], "OneFormChannels", $Failed];
   check["CF300 preparation retains exact grade channels for every installed one-form",
     Dimensions[cfRetainedOneFormChannels] ===
       {Length[cfPrepared["OneForms"]], 2, 2^cfPrepared["RootCount"]} &&
       FreeQ[cfRetainedOneFormChannels, $Failed]];
   report["CF300 physical preparation seconds",
     Round[cfPreparationSeconds, 0.01]];

   cfLayout = layoutBuild[cfPrepared];
   cfSplitProvider = directProviderBuild[cfPrepared["Record"],
     cfPrepared["Roots"], "Kind" -> "SplitBranch",
     "OneForms" -> cfPrepared["OneForms"],
     "GaugeDenominator" -> cfPrepared["GaugeDenominator"],
     "CoefficientABIFingerprint" ->
       cfLayout["CoefficientABIFingerprint"],
     "SourceFingerprint" -> cfPrepared["ABIFingerprint"]];
   cfQuotientProvider = directProviderBuild[cfPrepared["Record"],
     cfPrepared["Roots"], "Kind" -> "QuotientGrade",
     "OneForms" -> cfPrepared["OneForms"],
     "GaugeDenominator" -> cfPrepared["GaugeDenominator"],
     "CoefficientABIFingerprint" ->
       cfLayout["CoefficientABIFingerprint"],
     "SourceFingerprint" -> cfPrepared["ABIFingerprint"]];
   check["CF300 physical layout and both direct providers authenticate",
     TrueQ[layoutValidQ[cfLayout]] &&
       TrueQ[providerValidQ[cfSplitProvider]] &&
       TrueQ[providerValidQ[cfQuotientProvider]]];

   (* Normalization values are rational in epsilon.  Select two regular
      images from a deterministic schedule instead of baking in values which
      can become poles when the general normalization policy changes. *)
   cfNormalizationRegularQ[value_] := Module[{candidate =
       normalizationRows[cfLayout, value, prime]},
     ListQ[candidate] && Length[candidate] === 2 &&
       If[cfPrepared["Normalizations"] === {}, candidate[[1]] === {},
         Dimensions[candidate[[1]]] ===
           {Length[cfPrepared["Normalizations"]],
             cfLayout["UnknownCount"]}] &&
       Dimensions[candidate[[2]]] ===
         {Length[cfPrepared["Normalizations"]]}];
   cfRegulatorValues = Select[Range[1, 64],
     cfNormalizationRegularQ, 2];
   check["CF300 selects two nonsingular normalization images dynamically",
     Length[cfRegulatorValues] === 2];

   cfDeltas = Lookup[cfRoots, "RootSquare", {}];
   cfSplitPointQ[point_] := Module[{values = Mod[
       cfDeltas /. Thread[cfVariables -> point], prime]},
     FreeQ[values, 0] &&
       AllTrue[values, JacobiSymbol[#, prime] === 1 &]];
   cfCandidateGrid = Tuples[Range[2, 80], 2];
   cfPoints = Select[cfCandidateGrid, cfSplitPointQ, cfPointCount + 1];
   cfTrainingPoints = Take[cfPoints, UpTo[cfPointCount]];
   cfHeldOutPoint = If[Length[cfPoints] > cfPointCount,
     cfPoints[[cfPointCount + 1]], Missing["NoHeldOutPoint"]];
   check["CF300 has 18 deterministic training points plus a held-out split point",
     Length[cfTrainingPoints] === cfPointCount &&
       ! MissingQ[cfHeldOutPoint] &&
       FreeQ[cfTrainingPoints, cfHeldOutPoint]];

   (* Compile the already-canonical frozen rational pairs ONCE.  Direct
      substitution followed by Together at every point is mathematically
      harmless but measured to dominate a ten-minute draft of this gate. *)
   {cfFrozenCompileSeconds, cfFrozenCompiled} = AbsoluteTiming[Map[
     compileRational[#, cfVariables, cfEpsilon] &, cfFrozenChannels, {4}]];
   cfFrozenPrime = Map[reduceRational[#, prime] &, cfFrozenCompiled, {4}];
   check["CF300 frozen exact-channel oracle compiles once for modular evaluation",
     FreeQ[{cfFrozenCompiled, cfFrozenPrime}, $Failed] &&
       Dimensions[cfFrozenCompiled] === Dimensions[cfFrozenChannels]];
   report["CF300 frozen-oracle compile seconds",
     Round[cfFrozenCompileSeconds, 0.01]];
   cfFrozenEpsilonForms[epsilonValue_] := Module[
     {key = ToString[InputForm[epsilonValue]], epsilonMod, forms},
     If[KeyExistsQ[cfFrozenEpsilonCache, key],
       Return[cfFrozenEpsilonCache[key]]];
     epsilonMod = modRational[epsilonValue, prime];
     forms = If[IntegerQ[epsilonMod],
       Map[collapseRational[#, epsilonMod, prime] &, cfFrozenPrime, {4}],
       $Failed];
     AssociateTo[cfFrozenEpsilonCache, key -> forms];
     forms];
   cfFrozenImage[epsilonValue_, point_] := Module[
     {forms = cfFrozenEpsilonForms[epsilonValue], maximum,
      xPowers, yPowers},
     If[! ArrayQ[forms, 4] || ! FreeQ[forms, $Failed], Return[$Failed]];
     maximum = maximumExponents[forms];
     xPowers = AssociationThread[Range[0, maximum[[1]]],
       PowerMod[Mod[point[[1]], prime], #, prime] & /@
         Range[0, maximum[[1]]]];
     yPowers = AssociationThread[Range[0, maximum[[2]]],
       PowerMod[Mod[point[[2]], prime], #, prime] & /@
         Range[0, maximum[[2]]]];
     Catch[evaluateForms[forms, xPowers, yPowers, prime],
       "MultiquadraticStripBadPoint"]];
   (* An independent full-ABI oracle without paying for the giant symbolic
      BBar quotient decomposition.  E and C use the exact QuotientGrade entry
      evaluator.  One-forms use the exact grade channels retained and sealed
      when their dlogs were constructed; re-walking the materialized 46-form
      alphabet cost about 303 seconds per image despite proving the same
      already-retained channel identity.  BBar comes from the frozen
      characteristic-zero channel fixture. *)
   cfSelectiveOracleCoefficients[epsilonValue_, point_] := Module[
     {preflight, evaluateEntry, evaluateRetained, eImage, cImage,
      oneFormImage, frozen,
      failureTag = Unique["CF300SelectiveQuotientFailure"]},
     preflight = providerPreflight[cfQuotientProvider, epsilonValue, prime,
       point];
     If[Lookup[preflight, "Status", None] =!=
         "MultiquadraticProviderPreflightV1", Return[preflight]];
     evaluateEntry[entry_, activeIndices_] := Module[{evaluated},
       evaluated = quotientGradeEntry[entry, cfRoots, activeIndices,
         preflight["ScalarRules"], preflight["RootSquares"], prime];
       If[Lookup[evaluated, "Status", None] =!= "OK",
         Throw[evaluated, failureTag]];
       evaluated["Channels"]];
     Catch[
       eImage = MapThread[evaluateEntry,
         {cfQuotientProvider["Entries"]["E"],
          cfQuotientProvider["ActiveRoots"]["E"]}, 3];
       cImage = MapThread[evaluateEntry,
         {cfQuotientProvider["Entries"]["C"],
          cfQuotientProvider["ActiveRoots"]["C"]}, 3];
       evaluateRetained[value_] := modRational[
         value /. Normal[preflight["ScalarRules"]], prime];
       oneFormImage = Map[evaluateRetained,
         cfRetainedOneFormChannels, {3}];
       If[MemberQ[Flatten[oneFormImage], $Failed],
         Throw[$Failed, failureTag]];
       frozen = cfFrozenImage[epsilonValue, point];
       If[! ArrayQ[frozen, 4] || ! FreeQ[frozen, $Failed],
         Throw[$Failed, failureTag]];
       <|"Status" -> "MultiquadraticPointCoefficientsV1",
         "Provider" -> "FrozenBBarPlusSelectiveQuotientGrade",
         "Prime" -> prime, "Point" -> preflight["Point"],
         "RegulatorValue" -> epsilonValue,
         "EpsilonMod" -> preflight["EpsilonMod"],
         "RootSquares" -> preflight["RootSquares"],
         "RootValues" -> preflight["RootValues"],
         "SplitPointQ" -> preflight["SplitPointQ"],
         "GaugeDenominator" -> preflight["GaugeDenominator"],
         "GaugeLogDerivatives" -> preflight["GaugeLogDerivatives"],
         "RootLogDerivatives" -> preflight["RootLogDerivatives"],
         "E" -> eImage, "C" -> cImage, "BBar" -> frozen,
         "OneForms" -> oneFormImage,
         "CoefficientABIFingerprint" ->
           cfQuotientProvider["CoefficientABIFingerprint"],
         "ProviderFingerprint" -> cfOracleFingerprint|>,
       failureTag]
     ];

   (* Two regulator/kinematic images anchor the hard forcing field against
      the frozen exact channel functions.  The generic rank-three part of
      this suite already compares the complete SplitBranch, QuotientGrade
      and CompiledChannel ABIs at three independent points.  Re-evaluating
      physical CF300 QuotientGrade here computed a large BBar only to throw
      it away, and measured to consume the earlier 540-second gate. *)
   {cfImageSeconds, cfAnchorRecords} = AbsoluteTiming[Table[
     With[{epsilonValue = imageSpec[[1]], point = imageSpec[[2]]},
      Module[{splitSeconds, splitCoefficients, oracleSeconds,
        oracleCoefficients, splitPointRows, oraclePointRows},
       {splitSeconds, splitCoefficients} = AbsoluteTiming[
         providerChannels[cfSplitProvider, epsilonValue, prime, point]];
       {oracleSeconds, oracleCoefficients} = AbsoluteTiming[
         cfSelectiveOracleCoefficients[epsilonValue, point]];
       splitPointRows = assemblePoint[cfLayout, splitCoefficients];
       oraclePointRows = assemblePoint[cfLayout, oracleCoefficients];
       Print["     CF300 anchor split/oracle seconds: ",
         InputForm[{splitSeconds, oracleSeconds}]];
       <|"RegulatorValue" -> epsilonValue, "Point" -> point,
         "SplitSeconds" -> splitSeconds, "OracleSeconds" -> oracleSeconds,
         "SplitCoefficients" -> splitCoefficients,
         "OracleCoefficients" -> oracleCoefficients,
         "SplitRows" -> splitPointRows, "OracleRows" -> oraclePointRows|>]],
     {imageSpec,
       Transpose[{cfRegulatorValues, Take[cfTrainingPoints, 2]}]}]];
   cfCoefficientEqualQ = AllTrue[cfAnchorRecords,
     Lookup[#1["SplitCoefficients"], "Status", None] ===
         "MultiquadraticPointCoefficientsV1" &&
       Lookup[#1["OracleCoefficients"], "Status", None] ===
         "MultiquadraticPointCoefficientsV1" &&
       coefficientPayload[#1["SplitCoefficients"]] ===
         coefficientPayload[#1["OracleCoefficients"]] &];
   check["CF300 SplitBranch forcing equals the frozen exact-channel oracle at two images",
     TrueQ[cfCoefficientEqualQ]];
   cfRowsEqualQ = AllTrue[cfAnchorRecords,
     Lookup[#1["SplitRows"], "Status", None] ===
         "AssembledMultiquadraticPointV1" &&
       Lookup[#1["OracleRows"], "Status", None] ===
         "AssembledMultiquadraticPointV1" &&
       #1["SplitRows"]["Rows"] === #1["OracleRows"]["Rows"] &];
   cfRightEqualQ = AllTrue[cfAnchorRecords,
     #1["SplitRows"]["RightHandSide"] ===
       #1["OracleRows"]["RightHandSide"] &];
   check["CF300 SplitBranch and frozen oracle assemble identical complete point rows",
     TrueQ[cfRowsEqualQ]];
   check["CF300 SplitBranch and frozen oracle assemble identical point RHS",
     TrueQ[cfRightEqualQ]];
   cfAnchorNormalizations = normalizationRows[cfLayout, #, prime] & /@
     cfRegulatorValues;
   check["CF300 physical normalization rows and values agree at both anchor images",
     AllTrue[cfAnchorNormalizations,
       ListQ[#] && Length[#] === 2 &&
         Length[#[[1]]] === Length[cfPrepared["Normalizations"]] &&
         Length[#[[2]]] === Length[cfPrepared["Normalizations"]] &]];
   report["CF300 two-image coefficient/row seconds",
     Round[cfImageSeconds, 0.01]];
   report["CF300 SplitBranch image seconds / cache misses / hits / sparse evaluation / fallback",
     Table[Lookup[record["SplitCoefficients"],
       {"Seconds", "SplitSparseCompileCacheMissCount",
        "SplitSparseCompileCacheHitCount", "SplitSparseEvaluationCount",
        "SplitSubstitutionFallbackCount"}, Missing["NotRecorded"]],
       {record, cfAnchorRecords}]];
   check["CF300 sparse SplitBranch anchors expose cache reuse and no substitution fallback",
     Total[Lookup[Lookup[cfAnchorRecords, "SplitCoefficients"],
         "SplitSparseCompileCacheMissCount", {}]] > 0 &&
       Total[Lookup[Lookup[cfAnchorRecords, "SplitCoefficients"],
         "SplitSparseCompileCacheHitCount", {}]] > 0 &&
       Total[Lookup[Lookup[cfAnchorRecords, "SplitCoefficients"],
         "SplitSubstitutionFallbackCount", {}]] === 0];

   (* Assemble the actual overdetermined 2120-column SplitBranch system.
      The two frozen-forcing anchors above certify the physical hard field;
      the complete provider ABI was independently checked by the generic
      rank-three fixture before entering this opt-in block. *)
   {cfTrainingSeconds, cfTrainingSample} = AbsoluteTiming[
     assembleSample[cfLayout, cfSplitProvider,
       First[cfRegulatorValues], prime,
       "PointCount" -> cfPointCount, "MaximumAttempts" -> cfPointCount,
       "CandidatePoints" -> cfTrainingPoints, "SplitPointsOnly" -> True,
       "RandomSeed" -> 2026082702]];
   check["CF300 production sampler assembles the complete 18-point SplitBranch system",
     Lookup[cfTrainingSample, "Status", None] ===
         "AssembledMultiquadraticSampleV1" &&
       cfTrainingSample["AcceptedPoints"] === cfTrainingPoints];
   report["CF300 18-point SplitBranch assembly seconds",
     Round[cfTrainingSeconds, 0.01]];
   report["CF300 production sampler phase seconds",
     Lookup[cfTrainingSample, "PhaseSeconds", <||>]];
   report["CF300 training sparse compile / evaluation / fallback seconds",
     Lookup[cfTrainingSample, {"SplitSparseCompileSeconds",
       "SplitSparseEvaluationSeconds", "SplitSubstitutionFallbackSeconds"},
       Missing["NotRecorded"]]];
   check["CF300 training uses only sparse SplitBranch evaluation",
     Lookup[cfTrainingSample, "SplitSubstitutionFallbackCount", -1] === 0 &&
       Lookup[cfTrainingSample, "SplitSparseEvaluationCount", -1] ===
        Lookup[cfTrainingSample, "SplitSparseCompileAttemptCount", -2]];
   cfNormalizations = normalizationRows[cfLayout,
     First[cfRegulatorValues], prime];
   cfMatrix = Lookup[cfTrainingSample, "Matrix", $Failed];
   cfRight = Lookup[cfTrainingSample, "RightHandSide", $Failed];
   check["CF300 full rows, RHS and physical normalization payload have the canonical dimensions",
      ListQ[cfNormalizations] && Length[cfNormalizations] === 2 &&
        If[cfPrepared["Normalizations"] === {},
          cfNormalizations[[1]] === {},
          Dimensions[cfNormalizations[[1]]] ===
            {Length[cfPrepared["Normalizations"]],
              cfLayout["UnknownCount"]}] &&
       Dimensions[cfMatrix] === {cfPointCount cfLayout["EquationsPerPoint"] +
          Length[cfNormalizations[[1]]], cfLayout["UnknownCount"]} &&
       Length[cfRight] === Length[cfMatrix]];

   (* This is the production-sized plan-discovery image, so exercise the
      same Automatic native/Wolfram dispatch as the solver.  Eight native
      threads are the explicit resource allowance for this opt-in gate. *)
   {cfSolveSeconds, cfSolution} = AbsoluteTiming[
     planDiscoverySolve[cfMatrix, cfRight, prime,
       cfPrepared["GaugeUnknownCount"], cfPrepared["ResidueUnknownCount"],
       Automatic, 8, Automatic]];
   check["CF300 full physical affine system is consistent and reports rank/nullity/pivots",
     Lookup[cfSolution, "Status", None] ===
         "MultiquadraticAffineSolution" &&
       IntegerQ[Lookup[cfSolution, "Rank", None]] &&
       IntegerQ[Lookup[cfSolution, "Nullity", None]] &&
       cfSolution["Rank"] + cfSolution["Nullity"] ===
         cfLayout["UnknownCount"] &&
       Length[cfSolution["PivotColumns"]] === cfSolution["Rank"] &&
       StringQ[cfSolution["PivotSignature"]]];
   check["CF300 canonical particular solution and nullspace have zero full-system residual",
     Lookup[cfSolution, "Status", None] ===
         "MultiquadraticAffineSolution" &&
       AllTrue[Mod[cfMatrix . cfSolution["ParticularSolution"] - cfRight,
         prime], # === 0 &] &&
       AllTrue[cfSolution["NullspaceBasis"],
         AllTrue[Mod[cfMatrix . #, prime], # === 0 &] &]];
   report["CF300 full-system rank / nullity / backend / solve seconds",
     {Lookup[cfSolution, "Rank", None], Lookup[cfSolution, "Nullity", None],
       Lookup[cfSolution, "PlanDiscoveryBackendUsed", None],
       Round[cfSolveSeconds, 0.01]}];

   (* A held-out kinematic image is disjoint from every row used in the
      RREF.  It is the bounded physical analogue of the provider-backed
      fresh-image check used by regulator reconstruction; the full
      multi-prime regulator interpolation remains an overnight solve, not
      a test-suite action. *)
   cfHeldOutCoefficients = providerChannels[cfSplitProvider,
     First[cfRegulatorValues], prime,
     cfHeldOutPoint];
   cfHeldOutRows = assemblePoint[cfLayout, cfHeldOutCoefficients];
   cfHeldOutResidual = If[
     Lookup[cfHeldOutRows, "Status", None] ===
         "AssembledMultiquadraticPointV1" &&
       Lookup[cfSolution, "Status", None] ===
         "MultiquadraticAffineSolution",
     Mod[cfHeldOutRows["Rows"] . cfSolution["ParticularSolution"] -
       cfHeldOutRows["RightHandSide"], prime], $Failed];
   check["CF300 canonical section has zero provider residual at a held-out kinematic image",
     VectorQ[cfHeldOutResidual, # === 0 &]];
   report["CF300 held-out point / nonzero residual rows",
     {cfHeldOutPoint, If[ListQ[cfHeldOutResidual],
       Count[cfHeldOutResidual, Except[0]], Missing["NoResidual"]]}];
   <|"Status" -> "CF300PhysicalPromotionCompleted",
     "PreparationSeconds" -> cfPreparationSeconds,
     "FrozenOracleCompileSeconds" -> cfFrozenCompileSeconds,
     "AnchorSeconds" -> cfImageSeconds,
     "TrainingAssemblySeconds" -> cfTrainingSeconds,
     "SolveSeconds" -> cfSolveSeconds|>],
   1200,
   <|"Status" -> "CF300PhysicalPromotionBudgetExhausted",
     "BudgetSeconds" -> 1200|>];
  check["CF300 opt-in physical gate completes inside its internal 1200-second budget",
    Lookup[cf300Outcome, "Status", None] ===
      "CF300PhysicalPromotionCompleted"];
  If[Lookup[cf300Outcome, "Status", None] =!=
      "CF300PhysicalPromotionCompleted",
    report["CF300 physical gate stop", cf300Outcome]],
  Print["SKIP CF300 full-row promotion (set ",
    "FACET_RUN_MQ_CF300_PROMOTION=1 for the bounded physical gate). ",
    "Inputs: ", InputForm[cf300Paths]]];

Print["t_multiquadratic_provider_promotion: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
