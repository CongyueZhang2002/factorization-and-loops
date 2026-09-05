#!/usr/bin/env wolframscript
(* Round-B B1 acceptance: one provider-independent layout, one exact
   coefficient-data record and one row/sample assembler.  The fixture has a known rank-one
   algebraic gauge G = eps Sqrt[1+x]/(1-y), E=C=0 and Bbar=dG. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, compile, layoutBuilder, layoutValid, compiledProvider,
  directProvider, providerChannels, preflight, assembleSample, affineSolve,
  pointRows, reconstruct} = mq /@ {"multiquadraticOffDiagonalBlockPrepare",
  "multiquadraticOffDiagonalBlockCompile", "multiquadraticOffDiagonalBlockAssemblyLayout",
  "multiquadraticOffDiagonalBlockAssemblyLayoutValidQ",
  "multiquadraticOffDiagonalBlockCompiledProvider",
  "multiquadraticOffDiagonalBlockDirectProvider",
  "multiquadraticOffDiagonalBlockProviderChannels",
  "multiquadraticOffDiagonalBlockProviderPreflight",
  "multiquadraticOffDiagonalBlockAssembleSample", "multiquadraticOffDiagonalBlockAffineSolve",
  "multiquadraticOffDiagonalBlockAssemblePointRows",
  "multiquadraticOffDiagonalBlockReconstructRegulator"};

Clear[px, py, pe, psx, psy, pcx, pcy];
delta = 1 + px;
coefficientPresentation = BuildSquareRootGeneratorsAndQuadraticRelations[
  {1 + psx}, {psx, psy}, {pcx, pcy}];
zero11 = {{{0}}, {{0}}};
knownOffDiagonalBasisTransformationBlock = {{Together[pe Sqrt[delta]/(1 - py)]}};
inhomogeneity = Table[{{Together[D[knownOffDiagonalBasisTransformationBlock[[1, 1]], {px, py}[[mu]]]]}},
  {mu, 2}];
record = <|"Family" -> "PROVIDER_SAMPLER", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {px, py}, "Regulator" -> pe,
  "OffDiagonalBlockEquation" -> {zero11, zero11, inhomogeneity}|>;

prepared = prepare[record, coefficientPresentation, "RootIndices" -> {1}, "OneForms" -> {},
  "OffDiagonalBasisTransformationDenominator" -> 1 - py, "Support" -> {{0, 0}}];
assembly = compile[prepared];
directPrepared = prepare[record, coefficientPresentation, "RootIndices" -> {1},
  "OneForms" -> {}, "OffDiagonalBasisTransformationDenominator" -> 1 - py,
  "Support" -> {{0, 0}}, "CoefficientProvider" -> "SplitBranch"];
layout = layoutBuilder[directPrepared];
compiled = compiledProvider[assembly];
split = directProvider[directPrepared["Record"], directPrepared["Roots"],
  "Kind" -> "SplitBranch", "OneForms" -> directPrepared["OneForms"],
  "OffDiagonalBasisTransformationDenominator" -> directPrepared["OffDiagonalBasisTransformationDenominator"]];
quotient = directProvider[directPrepared["Record"], directPrepared["Roots"],
  "Kind" -> "QuotientGrade", "OneForms" -> directPrepared["OneForms"],
  "OffDiagonalBasisTransformationDenominator" -> directPrepared["OffDiagonalBasisTransformationDenominator"]];

check["B1 preparation, compiled oracle and layout are valid",
  Lookup[prepared, "Status", None] === "PreparedMultiquadraticOffDiagonalBlockV1" &&
  Lookup[directPrepared, "Status", None] ===
      "PreparedMultiquadraticOffDiagonalBlockV1" &&
  Lookup[assembly, "Status", None] === "CompiledMultiquadraticOffDiagonalBlockV1" &&
  TrueQ[layoutValid[layout]]];
check["B1 direct preparation deliberately carries no inhomogeneity channels",
  MissingQ[directPrepared["InhomogeneityChannels"]] &&
    directPrepared["CoefficientProvider"] === "SplitBranch"];
check["B1 all three providers carry the layout's exact coefficient data",
  SameQ @@ Prepend[Lookup[{compiled, split, quotient},
    "CoefficientData"], layout["CoefficientData"]]];

prime = 2147483423;
splitPoints = Take[Select[Tuples[Range[2, 80], 2],
  Function[point, Mod[1 - Last[point], prime] =!= 0 &&
    JacobiSymbol[Mod[1 + First[point], prime], prime] === 1]], UpTo[6]];
nonsplitPoint = SelectFirst[Tuples[Range[2, 80], 2],
  Function[point, Mod[1 - Last[point], prime] =!= 0 &&
    JacobiSymbol[Mod[1 + First[point], prime], prime] === -1],
  Missing["NoNonsplitPoint"]];
check["B1 fixture supplies split and nonsplit points",
  Length[splitPoints] >= 4 && ! MissingQ[nonsplitPoint]];

compiledSample = assembleSample[layout, compiled, 5, prime,
  "PointCount" -> 4, "MaximumAttempts" -> Length[splitPoints],
  "CandidatePoints" -> splitPoints, "SplitPointsOnly" -> True];
splitSample = assembleSample[layout, split, 5, prime,
  "PointCount" -> 4, "MaximumAttempts" -> Length[splitPoints],
  "CandidatePoints" -> splitPoints, "SplitPointsOnly" -> True];
quotientSample = assembleSample[layout, quotient, 5, prime,
  "PointCount" -> 4, "MaximumAttempts" -> Length[splitPoints],
  "CandidatePoints" -> splitPoints, "SplitPointsOnly" -> True];

check["B1 compiled, split and quotient use one sample schema",
  AllTrue[{compiledSample, splitSample, quotientSample},
    Lookup[#1, "Status", None] ===
      "AssembledMultiquadraticSampleV1" &]];
check["B1 complete matrices and right-hand sides agree",
  compiledSample["Matrix"] === splitSample["Matrix"] ===
      quotientSample["Matrix"] &&
    compiledSample["RightHandSide"] === splitSample["RightHandSide"] ===
      quotientSample["RightHandSide"]];
check["B1 row and column orders and training-image sets agree",
  compiledSample["RowOrder"] === splitSample["RowOrder"] ===
      quotientSample["RowOrder"] &&
    compiledSample["ColumnOrder"] === splitSample["ColumnOrder"] ===
      quotientSample["ColumnOrder"] &&
    Length[splitSample["TrainingImageKeys"]] === 4];
check["B1 one provider call is made per accepted point",
  splitSample["ProviderCallCount"] === 4 &&
    splitSample["AttemptCount"] === 4];

compiledSolution = affineSolve[compiledSample["Matrix"],
  compiledSample["RightHandSide"], prime];
splitSolution = affineSolve[splitSample["Matrix"],
  splitSample["RightHandSide"], prime];
check["B1 affine signatures agree and the solved vector has zero residual",
  KeyTake[compiledSolution, {"Rank", "Nullity", "PivotSignature"}] ===
      KeyTake[splitSolution, {"Rank", "Nullity", "PivotSignature"}] &&
    AllTrue[Mod[splitSample["Matrix"] .
      splitSolution["ParticularSolution"] -
      splitSample["RightHandSide"], prime], #1 === 0 &]];

reconstruction = reconstruct[directPrepared, layout, split,
  "ExactVerification" -> True];
check["B1 regulator reconstruction consumes the provider-backed sampler",
  Lookup[reconstruction, "Status", None] ===
      "ReconstructedRegulatorDependenceV1" &&
    reconstruction["Provider"] === "SplitBranch" &&
    reconstruction["CoefficientData"] === layout["CoefficientData"] ===
      split["CoefficientData"]];
check["B1 the generic provider reconstruction is the known gauge",
  TrueQ[Together[reconstruction["OffDiagonalBasisTransformationBlock"][[1, 1]] -
      knownOffDiagonalBasisTransformationBlock[[1, 1]]] === 0] &&
    Lookup[reconstruction["ExactGenericResidual"], "Status", None] ===
      "ExactChannelResidualZero"];
check["B1 reconstruction records its sole training image store",
  Length[reconstruction["TrainingImageKeys"]] > 0 &&
    DuplicateFreeQ[reconstruction["ImageStoreKeys"]]];

nonsplitPreflight = preflight[split, 5, prime, nonsplitPoint];
nonsplitSample = assembleSample[layout, split, 5, prime,
  "PointCount" -> 1, "MaximumAttempts" -> 1,
  "CandidatePoints" -> {nonsplitPoint}];
check["B1 nonsplit split-provider preflight is typed and touches no entry",
  Lookup[nonsplitPreflight, "Status", None] ===
      "PointNotSplitOverPrime" &&
    Lookup[nonsplitPreflight, "LargeEntryEvaluationCount", -1] === 0];
check["B1 the sampler preserves the zero-large-evaluation rejection",
  Lookup[nonsplitSample, "Status", None] ===
      "InsufficientProviderPoints" &&
    Lookup[nonsplitSample, "LargeEntryEvaluationCount", -1] === 0 &&
    Lookup[First[nonsplitSample["RejectedPoints"]], "FailureReason", None] ===
      "PointNotSplitOverPrime"];

otherPrepared = prepare[record, coefficientPresentation, "RootIndices" -> {1},
  "OneForms" -> {}, "OffDiagonalBasisTransformationDenominator" -> 1 + py,
  "Support" -> {{0, 0}}, "CoefficientProvider" -> "SplitBranch"];
otherLayout = layoutBuilder[otherPrepared];
mismatch = assembleSample[otherLayout, split, 5, prime,
  "PointCount" -> 1, "MaximumAttempts" -> 1,
  "CandidatePoints" -> {First[splitPoints]}];
check["B1 a provider/layout mismatch is refused before evaluation",
  Lookup[mismatch, "Status", None] === "ProviderLayoutMismatch" &&
    Lookup[mismatch, "LargeEntryEvaluationCount", -1] === 0];

coefficients = providerChannels[split, 5, prime, First[splitPoints]];
mutant = Join[coefficients, <|"E" -> Drop[coefficients["E"], -1]|>];
check["B1 malformed complete coefficient shapes fail closed",
  Lookup[pointRows[layout, mutant], "Status", None] ===
    "InvalidPointCoefficients"];

Print["t_multiquadratic_provider_sampler: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
