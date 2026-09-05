#!/usr/bin/env wolframscript
(* Exact lifting and verification of finite-field strip gauges.
   - NormalizeEpsFormAffineSample fixes the normalization columns;
   - the CF254 (9,6) lift (Codex-era modular artifacts in
     Codex/TwoRootCF254Sector9Lower, input record copied there from the
     legacy tree on 2026-08-21) reconstructs exactly and is a DLOG FORM:
     regulator-free letters, residues free of x and y; its residues carry
     1/(1+eps), so it is NOT yet an epsilon form -- that is the contract
     of this rung (the sector driver factorizes the regulator afterwards;
     CF254's certified family record was built from exactly this strip),
     and the verifier now says so explicitly (DLogFormCertified True,
     CanonicalEpsFormCertified False) instead of only "identities zero";
   - a solution with a regulator-dependent letter, or with residues that
     depend on a kinematic variable, is refused before the exact pass
     (Codex audit 2026-08-21) and cannot be installed;
   - the canonical-benchmark (9,6) A4 artifacts lift to the stored gauge. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

artifactDirectory = FileNameJoin[{root, "Codex", "TwoRootCF254Sector9Lower"}];
record = FeynFacet`FamilyArtifactRead[FileNameJoin[{artifactDirectory, "CF254_9_6_input.wl"}]];
modularData = FeynFacet`FamilyArtifactRead /@ Sort[FileNames[
  "CF254_9_6_raw_epsilon_interpolation_mod_*.wl", artifactDirectory]];
expected = FeynFacet`FamilyArtifactRead[FileNameJoin[{artifactDirectory,
  "CF254_9_6_raw_lifted_candidate.wl"}]];

affineSample = <|
  "ParticularSolution" -> {3, 4, 5},
  "NullspaceBasis" -> {{1, 2, 0}, {0, 1, 1}}
|>;
normalized = FeynFacet`NormalizeEpsFormAffineSample[
  affineSample, {1, 3}, 1000003];

(* the (9,6) lift: exact, a dlog form, not yet an epsilon form *)
rawLift = FeynFacet`ReconstructOffDiagonalBasisTransformationBlock[record, modularData, "KernelCount" -> 1, "ExactCheck" -> False];
result = FeynFacet`ReconstructOffDiagonalBasisTransformationBlock[record, modularData, "KernelCount" -> 1];
rawCheckpoint = <|"Sector" -> 9,
  "PrevD" -> ConstantArray[0, {First[Rest[Dimensions[record["OffDiagonalBlockEquation"][[3]]]]], 1}],
  "OffDiagonalBlockSolutions" -> {}|>;
installed = FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock[rawCheckpoint, record, expected, 9, 6];

(* structural refusals: regulator-dependent letter; kinematics-dependent residue *)
{xx, yy} = record["Variables"]; ee = record["Regulator"];
badLetter = Join[expected, <|"Alphabet" -> ReplacePart[expected["Alphabet"], 1 -> expected["Alphabet"][[1]] + ee]|>];
badResidue = Join[expected, <|"ResidueMatrices" -> ReplacePart[expected["ResidueMatrices"], {1, 1, 1} -> xx]|>];
badLetterVerification = FeynFacet`VerifyOffDiagonalBasisTransformationBlock[record, badLetter];
badResidueVerification = FeynFacet`VerifyOffDiagonalBasisTransformationBlock[record, badResidue];
badLetterInstalled = Quiet[Check[FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock[rawCheckpoint, record, badLetter, 9, 6], $Failed],
  FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock::state];
badResidueInstalled = Quiet[Check[FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock[rawCheckpoint, record, badResidue, 9, 6], $Failed],
  FeynFacet`Private`RecordVerifiedOffDiagonalBasisTransformationBlock::state];

(* the canonical-benchmark (9,6) fixture: the A4 acceptance artifacts *)
benchmark = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical", "BenchmarkStripBackends"}];
fixture = FeynFacet`FamilyArtifactRead[FileNameJoin[{benchmark, "fixtures", "fixture_CF254_9_6.wl"}]];
canonicalData = FeynFacet`FamilyArtifactRead /@ FileNames["*_mod_*.wl",
  FileNameJoin[{benchmark, "frozen_M0", "a4_run", "ff_artifacts_A4_CF254_9_6_155035"}]];
stored = FeynFacet`FamilyArtifactRead[FileNameJoin[{benchmark, "frozen_M0", "a4_run",
  "result_A4_CF254_9_6_FiniteField.wl"}]]["BackendResult"];
benchmarkLift = FeynFacet`ReconstructOffDiagonalBasisTransformationBlock[fixture, canonicalData, "KernelCount" -> 1];

checks = <|
  "AffineAssociation" -> AssociationQ[normalized],
  "AffineParticularCoordinates" -> If[AssociationQ[normalized],
    normalized["ParticularSolution"][[{1, 3}]] === {0, 0}, False],
  "AffineBasisCoordinates" -> If[AssociationQ[normalized],
    normalized["NullspaceBasis"][[All, {1, 3}]] === IdentityMatrix[2],
    False],
  "UnverifiedLiftReportsStructure" -> AssociationQ[rawLift] && rawLift["Status"] === "LiftedUnverified" &&
    rawLift["LettersEpsFree"] === True && rawLift["ResiduesKinematicsFree"] === True && rawLift["ResiduesEpsFree"] === False,
  "ReconstructionAssociation" -> AssociationQ[result],
  "OffDiagonalBasisTransformationBlockAgreement" -> If[AssociationQ[result],
    AllTrue[Flatten[MapThread[Together[#1 - #2] &,
      {result["OffDiagonalBasisTransformationBlock"], expected["OffDiagonalBasisTransformationBlock"]}, 2]], TrueQ[# === 0] &],
    False],
  "ResidueAgreement" -> If[AssociationQ[result],
    AllTrue[Flatten[MapThread[Together[#1 - #2] &,
      {result["ResidueMatrices"], expected["ResidueMatrices"]}, 3]],
      TrueQ[# === 0] &],
    False],
  "ExactPfaffianResiduals" -> If[AssociationQ[result],
    TrueQ[result["ExactPfaffianResidualsZero"]], False],
  "DLogFormCertifiedNotCanonical" -> AssociationQ[result] && TrueQ[result["DLogFormCertified"]] &&
    result["CanonicalEpsFormCertified"] === False && result["ResiduesEpsFree"] === False,
  "AllModularImages" -> If[AssociationQ[result],
    And @@ result["CoefficientLiftChecks"], False],
  "DLogFormInstalls" -> AssociationQ[installed] && Lookup[Last[installed["OffDiagonalBlockSolutions"]], "LowerSector"] === 6,
  "RegulatorLetterRefusedBeforeExactPass" -> AssociationQ[badLetterVerification] &&
    badLetterVerification["DLogFormCertified"] === False &&
    badLetterVerification["StructuralFailureReasons"] === {"LettersDependOnRegulator"} &&
    badLetterVerification["ExactCheckSeconds"] === 0 && badLetterInstalled === $Failed,
  "KinematicResidueRefusedBeforeExactPass" -> AssociationQ[badResidueVerification] &&
    badResidueVerification["DLogFormCertified"] === False &&
    badResidueVerification["StructuralFailureReasons"] === {"ResiduesDependOnKinematics"} &&
    badResidueVerification["ExactCheckSeconds"] === 0 && badResidueInstalled === $Failed,
  "BenchmarkLiftReproducesStored" -> AssociationQ[benchmarkLift] && benchmarkLift["Status"] === "Solved" &&
    TrueQ[benchmarkLift["DLogFormCertified"]] && benchmarkLift["OffDiagonalBasisTransformationBlock"] === stored["OffDiagonalBasisTransformationBlock"] &&
    benchmarkLift["ResidueMatrices"] === stored["ResidueMatrices"] && benchmarkLift["Alphabet"] === stored["Alphabet"]
|>;

Print[InputForm[checks]];
Print["failed: ", Keys[Select[checks, ! TrueQ[#] &]]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
