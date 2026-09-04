(* O1: a precomputed preparation must reproduce the per-call sampler
   exactly (same affine system, same solution), be reused for the same
   defining input, and be recomputed for a different input. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

Clear[xPreparation, yPreparation, epsPreparation];
record = <|"Variables" -> {xPreparation, yPreparation},
  "Regulator" -> epsPreparation,
  "Strip" -> {
    {{{1}}, {{0}}},
    {{{0}}, {{0}}},
    {{{1 - epsPreparation xPreparation}}, {{0}}}}|>;

prep = FeynFacet`PrepareEpsFormStripSampling[record];
plain = FeynFacet`SampleEpsFormStripAffine[record, 3/17, 1000003,
  "NumeratorDegreeOffset" -> {1, 0}];
reused = FeynFacet`SampleEpsFormStripAffine[record, 3/17, 1000003,
  "NumeratorDegreeOffset" -> {1, 0}, "Preparation" -> prep];
stale = FeynFacet`SampleEpsFormStripAffine[record, 3/17, 1000003,
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

mathematicalKeys = {"EpsilonValue", "Prime", "AcceptedPoints",
  "MatrixDimensions", "GaugeDimensions", "Alphabet", "GaugeDenominator",
  "GaugeDenominatorDegrees", "GaugeNumeratorDegrees", "GaugeSupport",
  "GaugeUnknownCount", "FreeResidueCount", "Rank", "AugmentedRank",
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
  "ReusedSetupCheaper" -> reused["SetupSeconds"] < plain["SetupSeconds"]
|>;
Print[InputForm[tests]];
Quiet[DeleteDirectory[brokerDirectory, DeleteContents -> True]];
If[! And @@ Values[tests], Exit[1]];
