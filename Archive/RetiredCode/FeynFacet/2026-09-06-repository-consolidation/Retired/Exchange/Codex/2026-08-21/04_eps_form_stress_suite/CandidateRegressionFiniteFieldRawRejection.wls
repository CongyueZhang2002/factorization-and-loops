#!/usr/bin/env wolframscript

(* Replacement expectation for the legacy CF254 (9,6) RawResidues
   fixture: the modular lift is still reproducible, but it must not be
   certified or installed as an epsilon form. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{root, "External", "CodexExchange",
  "codex_epsform_stress_2026-08-21"}];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{exchange, "CodexFiniteFieldEpsFormCandidate.wl"}]];
Get[FileNameJoin[{exchange, "CodexFiniteFieldStripSolveCandidate.wl"}]];
End[];

Clear[Global`x, Global`y, Global`eps];
artifactDirectory = FileNameJoin[{root, "Codex",
  "TwoRootCF254Sector9Lower"}];
record = Get[
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_6_input.wl"];
modularData = Get /@ Sort[FileNames[
  "CF254_9_6_raw_epsilon_interpolation_mod_*.wl",
  artifactDirectory]];
expected = Get[FileNameJoin[{artifactDirectory,
  "CF254_9_6_raw_lifted_candidate.wl"}]];

affineSample = <|
  "ParticularSolution" -> {3, 4, 5},
  "NullspaceBasis" -> {{1, 2, 0}, {0, 1, 1}}
|>;
normalized = FeynFacet`NormalizeEpsFormAffineSample[
  affineSample, {1, 3}, 1000003];
raw = FeynFacet`ReconstructEpsFormStrip[
  record, modularData, "KernelCount" -> 1, "ExactCheck" -> False];
verification = If[AssociationQ[raw],
  FeynFacet`VerifyEpsFormStrip[record, raw, "KernelCount" -> 1], $Failed];

zeroDifferenceQ[a_, b_, level_] := AllTrue[
  Flatten[MapThread[Together[#1 - #2] &, {a, b}, level]],
  TrueQ[# === 0] &];
checks = <|
  "AffineAssociation" -> AssociationQ[normalized],
  "AffineParticularCoordinates" -> If[AssociationQ[normalized],
    normalized["ParticularSolution"][[{1, 3}]] === {0, 0}, False],
  "AffineBasisCoordinates" -> If[AssociationQ[normalized],
    normalized["NullspaceBasis"][[All, {1, 3}]] === IdentityMatrix[2],
    False],
  "RawLiftReproduced" -> AssociationQ[raw] &&
    raw["Status"] === "LiftedUnverified",
  "GaugeAgreement" -> If[AssociationQ[raw],
    zeroDifferenceQ[raw["Gauge"], expected["Gauge"], 2], False],
  "ResidueAgreement" -> If[AssociationQ[raw],
    zeroDifferenceQ[raw["ResidueMatrices"],
      expected["ResidueMatrices"], 3], False],
  "AllModularImages" -> If[AssociationQ[raw],
    And @@ raw["CoefficientLiftChecks"], False],
  "LegacyRawResiduesDetected" -> AssociationQ[verification] &&
    ! TrueQ[verification["ConstantResidues"]] &&
    verification["StructuralFailureReasons"] === {"ResiduesNotConstant"},
  "LegacyRawLiftNotCertified" -> AssociationQ[verification] &&
    ! TrueQ[verification["CanonicalEpsFormCertified"]] &&
    MissingQ[verification["ExactPfaffianResidualsZero"]] &&
    verification["ExactCheckSeconds"] === 0
|>;

Print[InputForm[<|"Checks" -> checks,
  "Verification" -> If[AssociationQ[verification],
    KeyDrop[verification, "Residuals"], verification]|>]];
Exit[If[And @@ Values[checks], 0, 1]];
