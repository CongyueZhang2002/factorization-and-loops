#!/usr/bin/env wolframscript

Get["/home/maxzhang/factorization-and-loops-codex/Addon/Load/LoadFACET.wl"];

record = FeynFacet`FamilyArtifactRead[
  "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsCertified/family_epsform_CF300.wl"];

Print[InputForm[<|
  "Loaded" -> AssociationQ[record],
  "Status" -> Lookup[record, "Status", None],
  "Exact" -> FeynFacet`ExactFamilyEpsilonFormQ[record],
  "Certified" -> FeynFacet`CertifiedFamilyEpsilonFormQ[record],
  "RejectTamper" -> ! FeynFacet`CertifiedFamilyEpsilonFormQ[
    ReplacePart[record, "GateVerdict" -> False]]
|>]];

If[! AssociationQ[record] ||
    FeynFacet`ExactFamilyEpsilonFormQ[record] ||
    ! FeynFacet`CertifiedFamilyEpsilonFormQ[record] ||
    FeynFacet`CertifiedFamilyEpsilonFormQ[
      ReplacePart[record, "GateVerdict" -> False]],
  Exit[1]];

Exit[0];
