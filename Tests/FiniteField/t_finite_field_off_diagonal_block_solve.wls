root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

directory = FileNameJoin[{root, "Codex", "TwoRootCF254Sector9Lower"}];
prime = 1000003;
sampleFiles = Sort[FileNames[
  "CF254_9_6_raw_point_sample_rank_*_p" <> ToString[prime] <> ".wl",
  directory]];
samples = Select[Get /@ sampleFiles,
  AssociationQ[#] && Lookup[#, "Prime", Missing[]] === prime &&
    TrueQ[Lookup[#, "Consistent", False]] &&
    KeyExistsQ[#, "ParticularSolution"] &];
expected = Get[FileNameJoin[{directory,
  "CF254_9_6_raw_epsilon_interpolation_mod_1000003.wl"}]];
actual = FeynFacet`Private`InterpolateOffDiagonalBasisTransformationBlockInEpsilon[
  samples, prime,
  "ConstructionCount" -> expected["ConstructionCount"],
  "MaximumTotalDegree" -> expected["MaximumTotalDegree"],
  "NormalizationColumns" -> expected["NormalizationColumns"]];

singularSample = Join[First[samples], <|
  "EpsilonValue" -> 123/457,
  "Rank" -> First[samples]["Rank"] - 1,
  "AugmentedRank" -> First[samples]["AugmentedRank"] - 1,
  "Nullity" -> First[samples]["Nullity"] + 1,
  "NullspaceBasis" -> Append[
    Normal[First[samples]["NullspaceBasis"]],
    UnitVector[Length[First[samples]["ParticularSolution"]], 1]]
|>];
actualWithSingularSample = FeynFacet`Private`InterpolateOffDiagonalBasisTransformationBlockInEpsilon[
  Append[samples, singularSample], prime,
  "ConstructionCount" -> expected["ConstructionCount"],
  "MaximumTotalDegree" -> expected["MaximumTotalDegree"],
  "NormalizationColumns" -> expected["NormalizationColumns"]];

(* Installation is a V2 unit contract and must not depend on archived
   pre-V2 block records. *)
Clear[xInstall, yInstall, epsInstall];
record = <|"Variables" -> {xInstall, yInstall},
  "Regulator" -> epsInstall,
  "OffDiagonalBlockEquation" -> {
    {{{0}}, {{0}}}, {{{0}}, {{0}}}, {{{0}}, {{0}}}}|>;
candidate = <|
  "OffDiagonalBasisTransformationBlock" -> {{0}},
  "Alphabet" -> {xInstall}, "ResidueMatrices" -> {{{0}}},
  "ExactPfaffianResidualsZero" -> True,
  "OffDiagonalBasisTransformationNumeratorDegrees" -> {0, 0},
  "OffDiagonalBasisTransformationDenominatorDegrees" -> {0, 0},
  "Primes" -> {prime}|>;
checkpoint = <|
  "Sector" -> 9,
  "PrevD" -> {{0}},
  "OffDiagonalBlockSolutions" -> {}
|>;
(* the candidate is a dlog-form strip (residues carry 1/(1+eps), letters
   regulator-free, residues free of x and y): it installs; a solution
   with a kinematics-dependent residue or a regulator-dependent letter is
   refused (Codex audit 2026-08-21, scoped to the dlog-form contract) *)
installed = FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock[
  checkpoint, record, candidate, 9, 6];
badResidue = Join[candidate, <|"ResidueMatrices" ->
  ReplacePart[candidate["ResidueMatrices"], {1, 1, 1} -> First[record["Variables"]]]|>];
badLetter = Join[candidate, <|"Alphabet" ->
  ReplacePart[candidate["Alphabet"], 1 -> candidate["Alphabet"][[1]] + record["Regulator"]]|>];
rawInstalled = {
  Quiet[Check[FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock[checkpoint, record, badResidue, 9, 6], $Failed],
    FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock::state],
  Quiet[Check[FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock[checkpoint, record, badLetter, 9, 6], $Failed],
    FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock::state]};
sampleAgreement = True;
If[Environment["FACET_FULL_FINITE_FIELD_TEST"] === "True",
  expectedSample = First[samples];
  actualSample = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[
    record, expectedSample["EpsilonValue"], prime,
    "PointCount" -> Length[expectedSample["AcceptedPoints"]],
    "NumeratorDegreeOffset" -> {1, 0},
    "SolveAffineSystem" -> True,
    "RandomSeed" -> 2540908];
  sampleAgreement = And[
    AssociationQ[actualSample],
    actualSample["Rank"] === expectedSample["Rank"],
    actualSample["AugmentedRank"] === expectedSample["AugmentedRank"],
    actualSample["Nullity"] === expectedSample["Nullity"],
    actualSample["ParticularSolution"] ===
      expectedSample["ParticularSolution"],
    actualSample["NullspaceBasis"] === expectedSample["NullspaceBasis"]
  ];
];

automatedSolutionQ = True;
If[Environment["FACET_AUTOMATED_FINITE_FIELD_TEST"] === "True",
  Clear[xSynthetic, ySynthetic, epsSynthetic];
  syntheticRecord = <|
    "Variables" -> {xSynthetic, ySynthetic},
    "Regulator" -> epsSynthetic,
    "OffDiagonalBlockEquation" -> {
      {{{1}}, {{0}}},
      {{{0}}, {{0}}},
      {{{1 - epsSynthetic xSynthetic}}, {{0}}}
    }
  |>;
  automatedSolution = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[
    syntheticRecord,
    "Primes" -> {1000003},
    "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
    "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}},
    "PointCount" -> 8,
    "KernelCount" -> 2,
    "ConstructionCount" -> 6,
    "MaximumTotalDegree" -> 4,
    "MinimumPrimeCount" -> 1,
    "Verbose" -> False];
  automatedSolutionQ = AssociationQ[automatedSolution] &&
    TrueQ[automatedSolution["ExactPfaffianResidualsZero"]] &&
    TrueQ[automatedSolution["DLogFormCertified"]];
];

tests = <|
  "DefaultDegreeOffsetPrefixAndExtension" ->
    Take[FeynFacet`Private`finiteFieldOffDiagonalBlockDegreeOffsetLadder[4], 9] ===
      {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {2, 0}, {0, 2},
       {2, 1}, {1, 2}, {2, 2}} &&
    Last[FeynFacet`Private`finiteFieldOffDiagonalBlockDegreeOffsetLadder[4]] ===
      {4, 4},
  "InterpolationAssociation" -> AssociationQ[actual],
  "NormalizationColumns" ->
    actual["NormalizationColumns"] === expected["NormalizationColumns"],
  "OffDiagonalBasisTransformationNumeratorDegrees" ->
    actual["OffDiagonalBasisTransformationNumeratorDegrees"] === expected["OffDiagonalBasisTransformationNumeratorDegrees"],
  "UnresolvedCoordinates" -> actual["UnresolvedCoordinates"] === {},
  "Interpolations" -> actual["Interpolations"] === expected["Interpolations"],
  "ExceptionalRegulatorValueDiscarded" -> And[
    AssociationQ[actualWithSingularSample],
    actualWithSingularSample["Interpolations"] ===
      actual["Interpolations"],
    actualWithSingularSample["DiscardedSingularEpsilonValues"] ===
      {123/457}
  ],
  "NonDLogFormInstallationRefused" -> rawInstalled === {$Failed, $Failed},
  "CheckpointAssociation" -> AssociationQ[installed],
  "CheckpointDimensions" ->
    Dimensions[installed["PrevD"]] ===
      {Dimensions[candidate["OffDiagonalBasisTransformationBlock"]][[1]],
        Dimensions[candidate["OffDiagonalBasisTransformationBlock"]][[2]] + 1},
  "CheckpointSector" ->
    Lookup[Last[installed["OffDiagonalBlockSolutions"]], "LowerSector"] === 6,
  "FiniteFieldSampleAgreement" -> sampleAgreement,
  "AutomatedFiniteFieldSolution" -> automatedSolutionQ
|>; 
Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
