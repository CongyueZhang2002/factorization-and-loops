(* M1: a pilot-discovered constrained plan must reproduce, on a later
   sample, exactly the normalized affine solution of the full
   four-elimination path (same normalization columns), pass all
   original-row checks, and report the one-factorization path. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

record = FeynFacet`FamilyArtifactRead[FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "BenchmarkStripBackends", "fixtures", "fixture_CF254_9_6.wl"}]];
If[! AssociationQ[record], Print["fixture unreadable"]; Exit[1]];
prep = FeynFacet`PrepareEpsFormStripSampling[record];
prime = 1000003;
common = {"NumeratorDegreeOffset" -> {1, 0}, "Preparation" -> prep,
  "ExpectedFingerprint" -> prep["Fingerprint"]};

pilot = FeynFacet`SampleEpsFormStripAffine[record, 1/21, prime,
  "DiscoverPlan" -> True, Sequence @@ common];
plan = Lookup[pilot, "EliminationPlan", <||>];

full = FeynFacet`SampleEpsFormStripAffine[record, 2/23, prime,
  Sequence @@ common];
constrained = FeynFacet`SampleEpsFormStripAffine[record, 2/23, prime,
  "EliminationPlan" -> plan, Sequence @@ common];
normalizedFull = FeynFacet`NormalizeEpsFormAffineSample[full,
  plan["NormalizationColumns"], prime];

stale = FeynFacet`SampleEpsFormStripAffine[record, 2/23, prime,
  "EliminationPlan" -> Join[plan, <|"GaugeUnknownCount" -> 1|>],
  Sequence @@ common];

tests = <|
  "PlanDiscovered" -> AssociationQ[plan] && plan["Status"] === "OK",
  "PlanShape" -> Length[plan["NormalizationColumns"]] === plan["Nullity"] &&
    Length[plan["IndependentEquationRows"]] === plan["GenericRank"] &&
    plan["GenericRank"] + plan["Nullity"] === plan["UnknownCount"],
  "ConstrainedPath" -> constrained["SolvePath"] ===
    "OneConstrainedMultiRHSFactorization",
  "AllRowChecks" -> TrueQ[constrained["ParticularCheckZero"]] &&
    TrueQ[constrained["NullspaceCheckZero"]] &&
    TrueQ[constrained["NormalizationCheck"]],
  "NormalizedParticularAgrees" ->
    constrained["ParticularSolution"] === normalizedFull["ParticularSolution"],
  "NormalizedNullspaceAgrees" ->
    constrained["NullspaceBasis"] === normalizedFull["NullspaceBasis"],
  "RankMetadataAgrees" -> constrained["Rank"] === full["Rank"] &&
    constrained["Nullity"] === full["Nullity"],
  "NoSeparateEliminations" -> constrained["RankSeconds"] === 0. &&
    constrained["NullspaceSeconds"] === 0.,
  "IncompatiblePlanFallsBack" -> stale["SolvePath"] =!=
    "OneConstrainedMultiRHSFactorization" && TrueQ[stale["Consistent"]]
|>;
Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
