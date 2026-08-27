#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{p, q, z, v, w, lambda2, lambda3, bilinear, root2, root3,
    numerator, denominator, residualRoot, u, letters, dlogs, checks,
    outdir, summaryFile, summary, tag},
  {p, q} = Symbol /@ {"Global`p", "Global`q"};
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_kallen23_residual_v1";
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Kallen23ResidualV1$"];

  Catch[
    If[! IntegerQ[$KernelID] || $KernelID <= 0 || Length[Kernels[]] =!= 0,
      Print["CF303K23 failure=worker-contract"];
      Throw[$Failed, tag]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      Print["CF303K23 failure=output-exists"];
      Throw[$Failed, tag]];
    CreateDirectory[outdir];
    Print["CF303K23 stage=derive"];

    z = Together[(-3 + q) (1 + q - 2 p)/(-1 + q^2)];
    v = Together[-z p];
    w = Together[(1 - z) (1 - p)];
    lambda2 = Expand[(1 + v - w)^2 + 4 v w];
    lambda3 = Expand[(1 - v + w)^2 + 4 v w];
    bilinear = Together[1 - 4 v w];
    root2 = Together[z - p];
    root3 = Together[(1 + p) + q (z - 1)];
    numerator = Factor[Numerator[bilinear]];
    denominator = Factor[Denominator[bilinear]];
    residualRoot = Sqrt[numerator];
    u = Together[residualRoot/(q^2 - 1)];
    letters = {u, 1 - u, 1 + u};
    dlogs = Table[{Together[D[letter, p]/letter],
        Together[D[letter, q]/letter]}, {letter, letters}];
    checks = <|
      "Lambda2RootIdentity" -> TrueQ[Together[lambda2 - root2^2] === 0],
      "Lambda3RootIdentity" -> TrueQ[Together[lambda3 - root3^2] === 0],
      "DenominatorSquareIdentity" ->
        TrueQ[Together[denominator - (q^2 - 1)^2] === 0],
      "ResidualRootIdentity" ->
        TrueQ[Together[u^2 - bilinear] === 0],
      "Class115NormIdentity" ->
        TrueQ[Together[(1 - u) (1 + u) - 4 v w] === 0],
      "DLogClosed" -> (TrueQ[Together[D[#[[2]], p] -
          D[#[[1]], q]] === 0] & /@ dlogs),
      "WrongBranchChangesOddLetters" ->
        TrueQ[Together[(letters[[2]] /. residualRoot -> -residualRoot) -
          letters[[3]]] === 0]|>;
    If[! And @@ Flatten[Values[checks]],
      Print["CF303K23 failure=exact-check checks=", checks];
      Throw[$Failed, tag]];

    summary = <|
      "Status" -> "CF303Kallen23ResidualPassedV1",
      "ChartVariables" -> {p, q},
      "Kallen23IntermediateX" -> Factor[z],
      "SourceMap" -> {v -> Factor[v], w -> Factor[w]},
      "RationalizedRoots" -> {Factor[root2], Factor[root3]},
      "ResidualRootSquare" -> Factor[bilinear],
      "ResidualPolynomial" -> numerator,
      "ResidualDenominator" -> denominator,
      "ResidualPolynomialDegrees" ->
        {Exponent[numerator, p], Exponent[numerator, q],
          Max[Total /@ ExponentRules[numerator, {p, q}][[All, 1]]]},
      "ResidualPolynomialFactorList" -> FactorList[numerator],
      "DiscriminantInP" -> Factor[Discriminant[numerator, p]],
      "DiscriminantInQ" -> Factor[Discriminant[numerator, q]],
      "NormalizedResidualRoot" -> u,
      "Class115Letters" -> letters,
      "Class115DLogs" -> dlogs,
      "Checks" -> checks,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    Put[summary, summaryFile];
    Print["CF303K23 status=PASS degrees=",
      summary["ResidualPolynomialDegrees"], " summary=", summaryFile];
    0,
    tag]
]
