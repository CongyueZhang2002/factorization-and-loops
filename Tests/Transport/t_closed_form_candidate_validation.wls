#!/usr/bin/env wolframscript

(* Finite series and pointwise agreement are evidence for a proposed matrix
   of homogeneous solutions, not a proof of its differential identity. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

v = Symbol["Global`candidateV"];
w = Symbol["Global`candidateW"];
eps = Symbol["Global`eps"];

(* This nonzero polynomial is invisible through the default twelfth-order
   expansion and vanishes at all four default numerical sample points.  It
   is an explicit counterexample to treating finite evidence as an identity. *)
finiteEvidenceResidual =
  v^13 Product[v - 1/(3 + k), {k, 4}];
candidateSystem = <|"Family" -> "FiniteEvidenceCounterexample",
  "Av" -> {{finiteEvidenceResidual}}, "Aw" -> {{0}}|>;
candidateSpec = <|"Type" -> "ClosedFormSector", "Phi" -> {{1}},
  "GaussCertificate" -> False|>;

candidate = FeynFacet`Private`masterTransportClosedFormSector[
  candidateSpec, candidateSystem["Av"], candidateSystem["Aw"], eps,
  {v, w}];
FTAssert["finite evidence remains an incomplete analytic candidate",
  candidate["Status"] === "AnalyticCandidate" &&
    candidate["Exactness"] === "AnalyticCandidate" &&
    candidate["Reason"] === "DifferentialIdentityNotValidated" &&
    TrueQ[candidate["Checks", "SeriesResidualZero"]] &&
    TrueQ[candidate["Checks", "NumericResidualZero"]] &&
    ! KeyExistsQ[candidate, "T"] && ! KeyExistsQ[candidate, "Ev"] &&
    KeyExistsQ[candidate, "Candidate"]];

candidateAssembly = FeynFacet`Private`masterTransportAssemble[
  candidateSystem, eps, {v, w},
  "Blocks" -> {{{1}, candidateSpec}}, "Verbose" -> False];
FTAssert["assembly cannot use a candidate matrix to zero a diagonal block",
  candidateAssembly["Status"] === "FormFailed" &&
    candidateAssembly["Failures"][[1, 2, "Status"]] ===
      "AnalyticCandidate" &&
    ! KeyExistsQ[candidateAssembly, "Apv"] &&
    ! KeyExistsQ[candidateAssembly, "Apw"]];

FTAssert["the assembly boundary rejects legacy OK-labelled candidate evidence",
  ! FeynFacet`Private`masterTransportAcceptedBlockFormQ[
    <|"Status" -> "OK", "Type" -> "ClosedFormSector",
      "Exactness" -> "AnalyticCandidate"|>]];

exactSystem = <|"Family" -> "ValidatedHomogeneousSolution",
  "Av" -> {{1/(1 + v)}}, "Aw" -> {{0}}|>;
exactAssembly = FeynFacet`Private`masterTransportAssemble[
  exactSystem, eps, {v, w},
  "Blocks" -> {{{1}, <|"Type" -> "ClosedFormSector",
      "Phi" -> {{1 + v}}|>}}, "Verbose" -> False];
FTAssert["an exactly validated homogeneous-solution matrix may trivialize its block",
  exactAssembly["Status"] === "OK" &&
    exactAssembly["Forms"][[1, "Exactness"]] === "Exact" &&
    exactAssembly["Apv"] === {{0}} && exactAssembly["Apw"] === {{0}} &&
    TrueQ[exactAssembly["Certificate", "DiagonalEqualsDeclaredForm"]]];

FTReport[];
