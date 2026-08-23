root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
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
actual = FeynFacet`InterpolateEpsFormStripAffine[
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
actualWithSingularSample = FeynFacet`InterpolateEpsFormStripAffine[
  Append[samples, singularSample], prime,
  "ConstructionCount" -> expected["ConstructionCount"],
  "MaximumTotalDegree" -> expected["MaximumTotalDegree"],
  "NormalizationColumns" -> expected["NormalizationColumns"]];

candidate = Get[FileNameJoin[{directory,
  "CF254_9_6_raw_lifted_candidate.wl"}]];
(* the raw input record was copied into the tree from the legacy
   ~/FACET path on 2026-08-21 (tests locate evidence repository-relative) *)
record = FeynFacet`FamilyArtifactRead[FileNameJoin[{directory, "CF254_9_6_input.wl"}]];
checkpoint = <|
  "Sector" -> 9,
  "PrevD" -> ConstantArray[0,
    {First[Rest[Dimensions[record["Strip"][[3]]]]], 1}],
  "StripSolvers" -> {}
|>;
(* the candidate is a dlog-form strip (residues carry 1/(1+eps), letters
   regulator-free, residues free of x and y): it installs; a solution
   with a kinematics-dependent residue or a regulator-dependent letter is
   refused (Codex audit 2026-08-21, scoped to the dlog-form contract) *)
installed = FeynFacet`InstallEpsFormStripSolution[
  checkpoint, record, candidate, 9, 6];
badResidue = Join[candidate, <|"ResidueMatrices" ->
  ReplacePart[candidate["ResidueMatrices"], {1, 1, 1} -> First[record["Variables"]]]|>];
badLetter = Join[candidate, <|"Alphabet" ->
  ReplacePart[candidate["Alphabet"], 1 -> candidate["Alphabet"][[1]] + record["Regulator"]]|>];
rawInstalled = {
  Quiet[Check[FeynFacet`InstallEpsFormStripSolution[checkpoint, record, badResidue, 9, 6], $Failed],
    FeynFacet`InstallEpsFormStripSolution::state],
  Quiet[Check[FeynFacet`InstallEpsFormStripSolution[checkpoint, record, badLetter, 9, 6], $Failed],
    FeynFacet`InstallEpsFormStripSolution::state]};
sampleAgreement = True;
If[Environment["FACET_FULL_FINITE_FIELD_TEST"] === "True",
  expectedSample = First[samples];
  actualSample = FeynFacet`SampleEpsFormStripAffine[
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
    "Strip" -> {
      {{{1}}, {{0}}},
      {{{0}}, {{0}}},
      {{{1 - epsSynthetic xSynthetic}}, {{0}}}
    }
  |>;
  automatedSolution = FeynFacet`SolveEpsFormStripFiniteField[
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
  "InterpolationAssociation" -> AssociationQ[actual],
  "NormalizationColumns" ->
    actual["NormalizationColumns"] === expected["NormalizationColumns"],
  "GaugeNumeratorDegrees" ->
    actual["GaugeNumeratorDegrees"] === expected["GaugeNumeratorDegrees"],
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
      {Dimensions[candidate["Gauge"]][[1]],
        Dimensions[candidate["Gauge"]][[2]] + 1},
  "CheckpointSector" ->
    Lookup[Last[installed["StripSolvers"]], "LowerSector"] === 6,
  "FiniteFieldSampleAgreement" -> sampleAgreement,
  "AutomatedFiniteFieldSolution" -> automatedSolutionQ
|>; 
Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
