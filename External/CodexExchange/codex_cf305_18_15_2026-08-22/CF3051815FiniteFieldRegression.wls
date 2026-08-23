root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
outDir = FileNameJoin[{root, "External", "CodexExchange",
  "codex_cf305_18_15_2026-08-22"}];
block = FeynFacet`FamilyArtifactRead[FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsSolving", "tworoot_2026-08-22", "CF305",
  "sector_CF305_standard", "CF305_18_15_input.wl"}]];
reference = FeynFacet`FamilyArtifactRead[
  FileNameJoin[{outDir, "CF305_18_15_series_solution.wl"}]];
artifactDir = FileNameJoin[{"/tmp", "codex_cf305_1815_ff_regression"}];
If[! DirectoryQ[artifactDir], CreateDirectory[artifactDir]];

{wall, solution} = AbsoluteTiming[
  FeynFacet`SolveEpsFormStripFiniteField[block,
    "Primes" -> {1000003, 2147483423, 2147483477},
    "MaximumPrimeCount" -> 3,
    "KernelCount" -> 1,
    "ArtifactDirectory" -> artifactDir,
    "ArtifactPrefix" -> "CF305_18_15",
    "FinalCheck" -> "Exact",
    "Verbose" -> True]];

If[! AssociationQ[solution],
  Print["FINITE_FIELD_REGRESSION_FAILED wall=", Round[wall, .01]];
  Exit[2]];
deltaGauge = Map[Together,
  solution["Gauge"] - reference["Gauge"], {2}];
deltaConstant = FreeQ[deltaGauge, Alternatives @@ block["Variables"]];
deltaZero = And @@ (PossibleZeroQ /@ Flatten[deltaGauge]);
plan = Lookup[solution, "EliminationPlan", <||>];
certificate = <|
  "Family" -> "CF305", "Sector" -> 18, "LowerSector" -> 15,
  "Status" -> If[TrueQ[solution["ExactDLog"]] &&
      TrueQ[solution["ExactPfaffianResidualsZero"]],
    "Certified", "Failed"],
  "Method" -> solution["Method"],
  "WallSeconds" -> wall,
  "SelectedNumeratorDegreeOffset" ->
    Lookup[solution, "SelectedNumeratorDegreeOffset", Missing[]],
  "SelectedSupportShell" ->
    Lookup[solution, "SelectedSupportShell", Missing[]],
  "GaugeSupportCount" -> Length[Lookup[plan, "GaugeSupport", {}]],
  "UnknownCount" -> Lookup[plan, "UnknownCount", Missing[]],
  "Rank" -> Lookup[plan, "GenericRank", Missing[]],
  "Nullity" -> Lookup[plan, "Nullity", Missing[]],
  "ModularPrimeCount" -> Lookup[solution, "ModularPrimeCount", Missing[]],
  "ExactDLog" -> Lookup[solution, "ExactDLog", False],
  "ExactPfaffianResidualsZero" ->
    Lookup[solution, "ExactPfaffianResidualsZero", False],
  "DifferenceFromSeriesGaugeZero" -> deltaZero,
  "DifferenceFromSeriesGaugeKinematicsConstant" -> deltaConstant|>;

FeynFacet`FamilyArtifactWrite[solution,
  FileNameJoin[{outDir, "CF305_18_15_finite_field_solution.wl"}]];
FeynFacet`FamilyArtifactWrite[certificate,
  FileNameJoin[{outDir, "CF305_18_15_finite_field_certificate.wl"}]];
Print["FINITE_FIELD_RESULT=", certificate];
Print["CF305_18_15_FINITE_FIELD_REGRESSION_DONE"];
Exit[If[certificate["Status"] === "Certified", 0, 1]];
