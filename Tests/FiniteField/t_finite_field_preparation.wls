(* O1: a precomputed preparation must reproduce the per-call sampler
   exactly (same affine system, same solution), be reused for the same
   defining input, and be recomputed for a different input. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

Clear[xPreparation, yPreparation, epsPreparation];
record = <|"Variables" -> {xPreparation, yPreparation},
  "Regulator" -> epsPreparation,
  "OffDiagonalBlockEquation" -> {
    {{{1}}, {{0}}},
    {{{0}}, {{0}}},
    {{{1 - epsPreparation xPreparation}}, {{0}}}}|>;

prep = FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[record];
plain = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 3/17, 1000003,
  "NumeratorDegreeOffset" -> {1, 0}];
reused = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 3/17, 1000003,
  "NumeratorDegreeOffset" -> {1, 0}, "Preparation" -> prep];
stale = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 3/17, 1000003,
  "NumeratorDegreeOffset" -> {1, 0},
  "Preparation" -> Join[prep, <|"DefiningInput" ->
    Append[prep["DefiningInput"], "ExtraLetters" -> {1 + record["Variables"][[1]]}]|>]];

brokerDirectory = CreateDirectory[];
recordFile = FeynFacet`Private`taskBrokerPutAtomic[record,
  FileNameJoin[{brokerDirectory, "record.wl"}]];
optionsFile = FeynFacet`Private`taskBrokerPutAtomic[
  {"NumeratorDegreeOffset" -> {1, 0}},
  FileNameJoin[{brokerDirectory, "options.wl"}]];
helper = FeynFacet`Private`taskBrokerSampleTask[recordFile, {3/17},
  1000003, optionsFile];

(* The production first support is the exact denominator monomial support
   enlarged by the infinity-degree simplex.  It is only a fast seed: the
   solver retains the complete certified simplex as its terminal fallback. *)
Clear[xSeed, ySeed, epsSeed];
seedRecord = <|"Variables" -> {xSeed, ySeed}, "Regulator" -> epsSeed,
  "OffDiagonalBlockEquation" -> {
    {{{0}}, {{0}}}, {{{0}}, {{0}}},
    {{{ySeed^2/xSeed^2}}, {{0}}}}|>;
seedPreparation = FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[
  seedRecord];
seedCensus = seedPreparation["SupportCensus"];
denominatorSupport = First /@ CoefficientRules[
  Expand[seedPreparation["OffDiagonalBasisTransformationDenominator"]],
  seedPreparation["Variables"]];
supportInflation = seedCensus["NumeratorSupportInflation"];
supportShifts = Flatten[Table[{px, py}, {px, 0, supportInflation},
  {py, 0, supportInflation - px}], 1];
expectedSeed = Sort@DeleteDuplicates@Flatten[
  Outer[Plus, denominatorSupport, supportShifts, 1], 1];
denominatorSeed = FeynFacet`Private`finiteFieldOffDiagonalBlockSupport[
  seedPreparation, seedPreparation["DenominatorDegrees"],
  "DenominatorSupportSeed", 0];
offsetSeed = FeynFacet`Private`finiteFieldOffDiagonalBlockSupport[
  seedPreparation, seedPreparation["DenominatorDegrees"] + {1, 0},
  "DenominatorSupportSeed", 0];

mathematicalKeys = {"EpsilonValue", "Prime", "AcceptedPoints",
  "MatrixDimensions", "OffDiagonalBasisTransformationBlockDimensions", "Alphabet", "OffDiagonalBasisTransformationDenominator",
  "OffDiagonalBasisTransformationDenominatorDegrees", "OffDiagonalBasisTransformationNumeratorDegrees", "OffDiagonalBasisTransformationNumeratorSupport",
  "OffDiagonalBasisTransformationUnknownCount", "FreeResidueCount", "Rank", "AugmentedRank",
  "Nullity", "Consistent", "ParticularSolution", "NullspaceBasis"};
strip[a_] := KeyTake[a, mathematicalKeys];

tests = <|
  "PreparationAssociation" -> AssociationQ[prep] &&
    AssociationQ[prep["DefiningInput"]] && ListQ[prep["Alphabet"]],
  "PlainSampleSolves" -> AssociationQ[plain] && TrueQ[plain["Consistent"]],
  "ReusedFlag" -> TrueQ[reused["PreparationReused"]],
  "StaleRecomputed" -> reused =!= $Failed && ! TrueQ[stale["PreparationReused"]],
  "IdenticalSystemAndSolution" -> strip[plain] === strip[reused] &&
    strip[plain] === strip[stale],
  "BrokerHelperUsesTheSameDefiningInput" -> ListQ[helper] &&
    Length[helper] === 1 && strip[First[helper]] === strip[reused],
  "ReusedSetupCheaper" -> reused["SetupSeconds"] < plain["SetupSeconds"],
  "DenominatorSupportSeedIsMinkowskiSupport" ->
    denominatorSeed === expectedSeed &&
    seedCensus["DenominatorSupportSeedCount"] === Length[denominatorSeed],
  "DenominatorSupportSeedOffsetExpansion" ->
    offsetSeed === Sort@DeleteDuplicates@Join[
      denominatorSeed, (# + {1, 0} & /@ denominatorSeed)],
  "DenominatorSupportFirstIsDefault" ->
    ("SupportStrategy" /. Options[
      FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField]) ===
        "DenominatorSupportFirst"
|>;
Print[InputForm[tests]];
Quiet[DeleteDirectory[brokerDirectory, DeleteContents -> True]];
If[! And @@ Values[tests], Exit[1]];
