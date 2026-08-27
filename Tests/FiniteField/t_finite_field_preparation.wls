(* O1: a precomputed preparation must reproduce the per-call sampler
   exactly (same affine system, same solution), be reused when its
   fingerprint matches, and be recomputed (not trusted) on a mismatch. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* the production CF254 (9,6) coupling record kept in the repository
   (BenchmarkStripBackends/fixtures); one sample costs ~11 s *)
record = FeynFacet`FamilyArtifactRead[FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "BenchmarkStripBackends", "fixtures", "fixture_CF254_9_6.wl"}]];
If[! AssociationQ[record], Print["fixture unreadable"]; Exit[1]];

prep = FeynFacet`PrepareEpsFormStripSampling[record];
plain = FeynFacet`SampleEpsFormStripAffine[record, 3/17, 1000003,
  "NumeratorDegreeOffset" -> {1, 0}];
reused = FeynFacet`SampleEpsFormStripAffine[record, 3/17, 1000003,
  "NumeratorDegreeOffset" -> {1, 0}, "Preparation" -> prep];
stale = FeynFacet`SampleEpsFormStripAffine[record, 3/17, 1000003,
  "NumeratorDegreeOffset" -> {1, 0},
  "Preparation" -> Join[prep, <|"Fingerprint" -> "wrong"|>]];

timingKeys = {"SetupSeconds", "PreprocessingSeconds", "SamplingSeconds",
  "RankSeconds", "AugmentedRankSeconds", "LinearSolveSeconds",
  "NullspaceSeconds", "PeakMemoryBytes", "PreparationReused"};
strip[a_] := KeyDrop[a, timingKeys];

tests = <|
  "PreparationAssociation" -> AssociationQ[prep] &&
    StringQ[prep["Fingerprint"]] && ListQ[prep["Alphabet"]],
  "PlainSampleSolves" -> AssociationQ[plain] && TrueQ[plain["Consistent"]],
  "ReusedFlag" -> TrueQ[reused["PreparationReused"]],
  "StaleRecomputed" -> reused =!= $Failed && ! TrueQ[stale["PreparationReused"]],
  "IdenticalSystemAndSolution" -> strip[plain] === strip[reused] &&
    strip[plain] === strip[stale],
  "ReusedSetupCheaper" -> reused["SetupSeconds"] < plain["SetupSeconds"]
|>;
Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
