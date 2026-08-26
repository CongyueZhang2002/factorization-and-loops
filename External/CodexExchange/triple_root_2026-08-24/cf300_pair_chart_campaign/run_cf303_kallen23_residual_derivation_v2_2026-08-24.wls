#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{p, q, sourceV, sourceW, z, vImage, wImage, lambda2, lambda3,
    bilinear, root2, root3, numerator, denominator, coefficientRules,
    totalDegree, discriminantP, discriminantQ, residualRoot, u, letters,
    dlogs, checks, outdir, summaryFile, summary, tag},
  {p, q, sourceV, sourceW} =
    Symbol /@ {"Global`p", "Global`q", "Global`v", "Global`w"};
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_kallen23_residual_v2";
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Kallen23ResidualV2$"];

  Catch[
    If[! IntegerQ[$KernelID] || $KernelID <= 0 || Length[Kernels[]] =!= 0,
      Print["CF303K23V2 failure=worker-contract"];
      Throw[$Failed, tag]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      Print["CF303K23V2 failure=output-exists"];
      Throw[$Failed, tag]];
    CreateDirectory[outdir];
    Print["CF303K23V2 stage=derive"];

    z = Together[(-3 + q) (1 + q - 2 p)/(-1 + q^2)];
    vImage = Together[-z p];
    wImage = Together[(1 - z) (1 - p)];
    lambda2 = Expand[(1 + vImage - wImage)^2 + 4 vImage wImage];
    lambda3 = Expand[(1 - vImage + wImage)^2 + 4 vImage wImage];
    bilinear = Together[1 - 4 vImage wImage];
    root2 = Together[z - p];
    root3 = Together[(1 + p) + q (z - 1)];
    numerator = Factor[Numerator[bilinear]];
    denominator = Factor[Denominator[bilinear]];
    coefficientRules = CoefficientRules[numerator, {p, q}];
    totalDegree = Max[Cases[coefficientRules,
      Rule[exponents_List, _] :> Total[exponents]]];
    discriminantP = Factor[Discriminant[numerator, p]];
    discriminantQ = Factor[Discriminant[numerator, q]];
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
        TrueQ[Together[(1 - u) (1 + u) - 4 vImage wImage] === 0],
      "DLogClosed" -> (TrueQ[Together[D[#[[2]], p] -
          D[#[[1]], q]] === 0] & /@ dlogs),
      "WrongBranchChangesOddLetters" ->
        TrueQ[Together[(letters[[2]] /. residualRoot -> -residualRoot) -
          letters[[3]]] === 0],
      "ResidualPolynomialIrreducible" -> Length[FactorList[numerator]] === 2,
      "GenericPQuarticSeparable" ->
        Exponent[numerator, p] === 4 && ! TrueQ[discriminantP === 0],
      "GenericQQuarticSeparable" ->
        Exponent[numerator, q] === 4 && ! TrueQ[discriminantQ === 0]|>;
    If[! And @@ Flatten[Values[checks]],
      Print["CF303K23V2 failure=exact-check checks=", checks];
      Throw[$Failed, tag]];

    summary = <|
      "Status" -> "CF303Kallen23ResidualPassedV2",
      "ChartVariables" -> {p, q},
      "Kallen23IntermediateX" -> Factor[z],
      "SourceMap" -> {sourceV -> Factor[vImage], sourceW -> Factor[wImage]},
      "RationalizedRoots" -> {Factor[root2], Factor[root3]},
      "ResidualRootSquare" -> Factor[bilinear],
      "ResidualPolynomial" -> numerator,
      "ResidualDenominator" -> denominator,
      "ResidualPolynomialDegrees" ->
        <|"P" -> Exponent[numerator, p], "Q" -> Exponent[numerator, q],
          "Total" -> totalDegree|>,
      "ResidualPolynomialFactorList" -> FactorList[numerator],
      "DiscriminantInP" -> discriminantP,
      "DiscriminantInQ" -> discriminantQ,
      "GenericFiberGenus" ->
        <|"OverQ(p)AsQuarticInQ" -> 1,
          "OverQ(q)AsQuarticInP" -> 1,
          "Justification" -> "squarefree quartic hyperelliptic fibers"|>,
      "NormalizedResidualRoot" -> u,
      "Class115Letters" -> letters,
      "Class115DLogs" -> dlogs,
      "Checks" -> checks,
      "Interpretation" ->
        "Kallen23 rationalizes lambda2 and lambda3 exactly. The triple " <>
        "cover becomes a two-grade rank-one extension. Its generic " <>
        "one-variable fibers are genus one, so a further rational chart " <>
        "is not expected; the explicit class-115 letters avoid needing one.",
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    Put[summary, summaryFile];
    Print["CF303K23V2 status=PASS degrees=",
      summary["ResidualPolynomialDegrees"], " summary=", summaryFile];
    0,
    tag]
]
