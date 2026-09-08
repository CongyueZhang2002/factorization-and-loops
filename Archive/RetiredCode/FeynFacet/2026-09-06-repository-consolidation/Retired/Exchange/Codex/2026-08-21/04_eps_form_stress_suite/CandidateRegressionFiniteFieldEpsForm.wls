#!/usr/bin/env wolframscript

(* INTENTIONAL LEGACY-EXPECTATION PROBE.  This is the old regression
   loaded over the candidate gate and is expected to exit 1 because its
   CF254 fixture is explicitly RawResidues -> True.  Use
   CandidateRegressionFiniteFieldRawRejection.wls for the corrected
   passing expectation. *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
exchange = FileNameJoin[{root, "External", "CodexExchange",
  "codex_epsform_stress_2026-08-21"}];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{exchange, "CodexFiniteFieldEpsFormCandidate.wl"}]];
Get[FileNameJoin[{exchange, "CodexFiniteFieldStripSolveCandidate.wl"}]];
Get[FileNameJoin[{exchange, "CodexDiagonalBlockEpsFormCandidate.wl"}]];
End[];

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

result = FeynFacet`ReconstructEpsFormStrip[
  record, modularData, "KernelCount" -> 1];

checks = <|
  "AffineAssociation" -> AssociationQ[normalized],
  "AffineParticularCoordinates" -> If[AssociationQ[normalized],
    normalized["ParticularSolution"][[{1, 3}]] === {0, 0}, False],
  "AffineBasisCoordinates" -> If[AssociationQ[normalized],
    normalized["NullspaceBasis"][[All, {1, 3}]] === IdentityMatrix[2],
    False],
  "ReconstructionAssociation" -> AssociationQ[result],
  "GaugeAgreement" -> If[AssociationQ[result],
    AllTrue[Flatten[MapThread[Together[#1 - #2] &,
      {result["Gauge"], expected["Gauge"]}, 2]], TrueQ[# === 0] &],
    False],
  "ResidueAgreement" -> If[AssociationQ[result],
    AllTrue[Flatten[MapThread[Together[#1 - #2] &,
      {result["ResidueMatrices"], expected["ResidueMatrices"]}, 3]],
      TrueQ[# === 0] &],
    False],
  "ExactPfaffianResiduals" -> If[AssociationQ[result],
    TrueQ[result["ExactPfaffianResidualsZero"]], False],
  "AllModularImages" -> If[AssociationQ[result],
    And @@ result["CoefficientLiftChecks"], False]
|>;

Print[InputForm[checks]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
