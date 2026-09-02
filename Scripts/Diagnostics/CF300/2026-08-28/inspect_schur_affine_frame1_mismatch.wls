#!/usr/bin/env wolframscript

Module[{repo, runtime, affine, schur, prime, images, records, gaugeCount,
    residueCount, bases, particulars, residueColumns, residueBases,
    residueParticulars, fixedColumns, complementColumns, affineFrame,
    schurFrame, reduced, coefficient, right, basisResidual,
    particularResidual, difference, result},
  repo = "/home/maxzhang/factorization-and-loops";
  runtime = "/home/maxzhang/factorization-and-loops-codex/Runtime";
  SetDirectory[repo];
  If[Names["FeynFacet`SolveEpsFormBlockwise"] === {},
    Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]]];
  Block[{$Context = "FeynFacet`Private`",
      $ContextPath = {"System`", "FeynFacet`", "FeynFacet`Private`"}},
    Get[FileNameJoin[{repo, "FeynFacet", "Private", "EpsForm",
      "FiniteFieldStripSolve.wl"}]]];
  affine = Import[FileNameJoin[{runtime,
    "cf300_p31_affine25_capture.wxf"}], "WXF"];
  schur = Import[FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_42_checkpoint.wxf"}], "WXF"];
  prime = affine["Prime"];
  images = affine["Images"];
  records = schur["Records"];
  gaugeCount = affine["GaugeUnknownCount"];
  residueCount = affine["ResidueUnknownCount"];
  bases = Normal /@ Lookup[images, "NullspaceBasis"];
  particulars = Normal /@ Lookup[images, "ParticularSolution"];
  residueColumns = gaugeCount + Range[residueCount];
  residueBases = (#[[All, residueColumns]] &) /@ bases;
  residueParticulars = (#[[residueColumns]] &) /@ particulars;
  fixedColumns = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 129, 130, 131, 132, 133, 134, 135, 136, 138, 140, 141, 145,
    146, 147, 148, 149, 153, 154, 155, 156, 157, 158, 159, 160, 169,
    170, 171, 172, 177, 178, 179, 180, 181, 182, 183, 184};
  complementColumns = Complement[Range[residueCount], fixedColumns];
  affineFrame = Module[{basis = First[residueBases],
      particular = First[residueParticulars], core, inverse, alpha,
      normalized, normalizedBasis},
    core = basis[[All, fixedColumns]];
    inverse = Inverse[core, Modulus -> prime];
    alpha = Mod[-Transpose[inverse] . particular[[fixedColumns]], prime];
    normalized = Mod[particular + Transpose[basis] . alpha, prime];
    normalizedBasis = Mod[inverse . basis, prime];
    Join[Transpose[normalizedBasis[[All, complementColumns]]],
      List /@ normalized[[complementColumns]], 2]];
  reduced = records[[1, "RawReduced"]];
  coefficient = reduced[[All, 1 ;; residueCount]];
  right = reduced[[All, residueCount + 1]];
  schurFrame = Mod[LinearSolve[coefficient[[All, complementColumns]],
      Join[-coefficient[[All, fixedColumns]], List /@ right, 2],
      Modulus -> prime], prime];
  basisResidual = Mod[
    coefficient[[All, complementColumns]] . affineFrame[[All, 1 ;; 52]] +
      coefficient[[All, fixedColumns]], prime];
  particularResidual = Mod[
    coefficient[[All, complementColumns]] . affineFrame[[All, 53]] - right,
    prime];
  difference = Mod[affineFrame - schurFrame, prime];
  result = <|"Status" -> "CF300SchurAffineFrame1Inspected",
    "AffineRegulatorValues" -> Lookup[images, "RegulatorValue"],
    "SchurRegulatorValuesFirst25" -> Take[
      Lookup[records, "RegulatorValue"], 25],
    "BasisResidualSupport" -> Count[Flatten[basisResidual], Except[0]],
    "ParticularResidualSupport" -> Count[particularResidual, Except[0]],
    "DifferenceSupport" -> Count[Flatten[difference], Except[0]],
    "DifferenceColumns" -> Sort[DeleteDuplicates[
      Last /@ Position[difference, Except[0], {2}]]]|>;
  Put[result, FileNameJoin[{runtime,
    "cf300_schur_affine_frame1_mismatch_summary.wl"}]];
  Print[InputForm[result]];
  Null
]
