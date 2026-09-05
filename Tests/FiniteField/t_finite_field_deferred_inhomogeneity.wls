#!/usr/bin/env wolframscript
(* Self-contained contract checks for the deferred-inhomogeneity adapter.
   Generated pre-V2 family artifacts are deliberately not unit fixtures. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
prime = 2147483423;

(* The V2 coefficient-presentation schema names the source map and its
   differential explicitly.  A stale Subst/Jacobian lookup disabled this
   route for every rationalizing parametrization. *)
Clear[sourceX, sourceY, chartX, chartY, epsilon];
planFile = CreateTemporary[];
canonicalPlan = mq["finiteFieldDeferredInhomogeneityPlan"][
  <|"Preparation" -> <|"DataType" -> "DeferredBlockEquation",
      "SchemaVersion" -> 2, "Status" -> "Prepared",
      "Variables" -> {sourceX, sourceY}, "Regulator" -> epsilon,
      "Dimensions" -> {2, 1, 1}|>|>, planFile,
  <|"SourceVariableSubstitution" ->
      {sourceX -> chartX, sourceY -> chartY},
    "DifferentialPullbackMatrix" -> IdentityMatrix[2]|>,
  {}, {}, {chartX, chartY}, {sourceX, sourceY}, epsilon, {1, 1}];
FTAssert["the deferred plan consumes the canonical V2 coefficient-presentation fields",
  AssociationQ[canonicalPlan] && canonicalPlan["Status"] === "OK" &&
    canonicalPlan["SourceVariableSubstitution"] ===
      {sourceX -> chartX, sourceY -> chartY} &&
    canonicalPlan["DifferentialPullbackMatrix"] === IdentityMatrix[2]];
canonicalPreflights = mq["finiteFieldDeferredInhomogeneityPreflights"][
  canonicalPlan, prime, {{2, 3, 5}}];
requestFile = CreateTemporary[];
canonicalRequest = mq[
  "multiquadraticOffDiagonalBlockNativeDeferredWriteRequest"][
    requestFile, canonicalPlan["Provider"], canonicalPreflights];
FTAssert["canonical deferred preflights satisfy the native request schema",
  MatchQ[canonicalPreflights, {_Association}] &&
    canonicalPreflights[[1, "QuadraticRadicands"]] === {} &&
    canonicalPreflights[[1, "SquareRootGeneratorValues"]] === {} &&
    canonicalRequest["Status"] ===
      "MultiquadraticNativeDeferredRequestV1"];
helperKey = CreateUUID["deferred-inhomogeneity-helper-test-"];
helperHandle = mq["finiteFieldDeferredInhomogeneityHandle"][canonicalPlan];
rebuiltKey = mq["finiteFieldDeferredInhomogeneityEnsurePlan"][<|
  "Key" -> helperKey, "Handle" -> helperHandle|>];
rebuiltPlan = Lookup[
  FeynFacet`Private`$finiteFieldDeferredInhomogeneityRegistry,
  helperKey, <||>];
FTAssert["a helper rebuild binds both the plan and native provider to the descriptor identifier",
  rebuiltKey === helperKey && rebuiltPlan["Key"] === helperKey &&
    rebuiltPlan["Provider", "ProviderID"] === helperKey];
KeyDropFrom[FeynFacet`Private`$finiteFieldDeferredInhomogeneityRegistry,
  helperKey];
singularTable = mq["finiteFieldDeferredInhomogeneityTable"][
  1/(chartX - 2), {chartX, chartY, epsilon}];
singularPowers = MapThread[
  mq["finiteFieldDeferredInhomogeneityPowers"][#1, #2, prime] &,
  {Transpose[{{2, 3, 5}, {3, 3, 5}}], {1, 0, 0}}];
maskedValues = mq["finiteFieldDeferredInhomogeneityRationalValues"][
  singularTable, singularPowers, prime, 2];
FTAssert["a singular member of a candidate batch is masked without discarding its regular neighbors",
  maskedValues["RegularPointQ"] === {False, True} &&
    maskedValues["Values"][[2]] === 1];
regulatorPolePreparation = <|"Records" -> {
  <|"Terms" -> {<|"Coefficient" ->
      1/((2 epsilon - 1) (3 epsilon - 1) (3 epsilon - 2)),
    "Operands" -> {1}|>}|>}|>;
regulatorPoleFactors = mq[
  "finiteFieldDeferredInhomogeneityRegulatorPoleFactors"][
    regulatorPolePreparation, {sourceX, sourceY}, epsilon];
FTAssert["pure regulator poles are extracted from the deferred DAG without assembling an entry",
  Length[regulatorPoleFactors] === 3 &&
    AllTrue[{1/2, 1/3, 2/3}, Function[value,
      AnyTrue[regulatorPoleFactors,
        TrueQ[Together[# /. epsilon -> value] === 0] &]]]];
If[AssociationQ[canonicalPlan] && StringQ[Lookup[canonicalPlan, "Key", None]],
  KeyDropFrom[FeynFacet`Private`$finiteFieldDeferredInhomogeneityRegistry,
    canonicalPlan["Key"]]];
Quiet[DeleteFile /@ {planFile, requestFile}];

(* A pair parametrization may rationalize only part of the roots visible in
   individual DAG terms.  The remaining grades must cancel after the terms of
   each matrix entry are summed. *)
root1 = <|"Generator" -> Sqrt[(1 + sourceX)^2],
  "QuadraticRadicand" -> (1 + sourceX)^2,
  "SourceRadicand" -> (1 + sourceX)^2|>;
root2 = <|"Generator" -> Sqrt[sourceX^2 + sourceY],
  "QuadraticRadicand" -> sourceX^2 + sourceY,
  "SourceRadicand" -> sourceX^2 + sourceY|>;
root3 = <|"Generator" -> Sqrt[(2 + sourceY)^2],
  "QuadraticRadicand" -> (2 + sourceY)^2,
  "SourceRadicand" -> (2 + sourceY)^2|>;
fullRootPreparation = <|"DataType" -> "DeferredBlockEquation",
  "SchemaVersion" -> 2, "Status" -> "Prepared",
  "Variables" -> {sourceX, sourceY}, "Regulator" -> epsilon,
  "Dimensions" -> {2, 1, 1},
  "Records" -> {
    <|"Target" -> {1, 1, 1}, "Terms" -> {
      <|"Kind" -> "Base", "Coefficient" -> 1,
        "Operands" -> {(root1["Generator"] + root3["Generator"])/
          (1 + root2["Generator"])}|>,
      <|"Kind" -> "Base", "Coefficient" -> 1,
        "Operands" -> {(root1["Generator"] + root3["Generator"])/
          (1 - root2["Generator"])}|>}|>,
    <|"Target" -> {2, 1, 1}, "Terms" -> {}|>}|>;
fullRootFile = CreateTemporary[];
Put[<|"DeferredPreparation" -> <|
    "Preparation" -> fullRootPreparation|>|>, fullRootFile];
fullRootPlan = mq["finiteFieldDeferredInhomogeneityPlan"][
  <|"Preparation" -> fullRootPreparation,
    "CoefficientPresentation" -> <|
      "SquareRootGenerators" -> {root1, root2, root3}|>,
    "SquareRootGeneratorIndices" -> {1, 3},
    "ProjectionSquareRootGeneratorIndices" -> {2}|>, fullRootFile,
  <|"SourceVariableSubstitution" ->
      {sourceX -> chartX, sourceY -> chartY},
    "DifferentialPullbackMatrix" -> IdentityMatrix[2]|>,
  {root1, root3}, {1 + chartX, 2 + chartY},
  {chartX, chartY}, {sourceX, sourceY},
  epsilon, {1, 1}];
splitSelection = mq["finiteFieldDeferredInhomogeneitySelectSplitImages"][
  fullRootPlan["Key"], prime, {{2, 3, 5}, {2, 5, 5}}, 1];
fullRootImage = mq["finiteFieldDeferredInhomogeneityImages"][
  fullRootPlan["Key"], prime, splitSelection["Images"], "Threads" -> 2];
expectedImage = Mod[10 (PowerMod[4, -1, prime] -
    PowerMod[2, -1, prime]), prime];
If[! (AssociationQ[splitSelection] &&
      Lookup[splitSelection, "Status", None] === "OK" &&
      AssociationQ[fullRootImage] &&
      Lookup[fullRootImage, "Status", None] === "OK"),
  Print["DIAGNOSTIC full-root deferred image: ", InputForm[<|
    "Plan" -> If[AssociationQ[fullRootPlan],
      KeyTake[fullRootPlan, {"Status", "RationalizedRootIndices",
        "UnrationalizedRootIndices"}], fullRootPlan],
    "Selection" -> splitSelection, "Image" -> fullRootImage|>]]];
FTAssert["a full-root split image projects a cancelling extra root to the pair-chart subfield",
  fullRootPlan["RationalizedRootIndices"] === {1, 3} &&
    fullRootPlan["UnrationalizedRootIndices"] === {2} &&
    fullRootPlan["ProjectionSquareRootGeneratorIndices"] === {2} &&
    fullRootPlan["Provider", "RootCount"] === 3 &&
    fullRootPlan["Provider", "GradeCount"] === 8 &&
    splitSelection["Indices"] === {2} &&
    fullRootImage["Status"] === "OK" &&
    fullRootImage["Values"] === {{{{expectedImage}}, {{0}}}}];
relativeNorm = mq["finiteFieldDeferredInhomogeneityRelativeNorm"][
  1 + root2["Generator"], fullRootPlan];
candidates = mq["finiteFieldDeferredInhomogeneityCandidateFactors"][
  fullRootPlan];
FTAssert["candidate denominators use the relative norm over the root outside the parametrized subfield",
  TrueQ[Together[relativeNorm - (1 - chartX^2 - chartY)] === 0] &&
    AnyTrue[candidates, TrueQ[
      Together[# - (1 - chartX^2 - chartY)] === 0] || TrueQ[
      Together[# + (1 - chartX^2 - chartY)] === 0] &]];
inverseRootNorm = mq["finiteFieldDeferredInhomogeneityRelativeNorm"][
  1/root2["Generator"], fullRootPlan];
selectedRootNorm = mq["finiteFieldDeferredInhomogeneityRelativeNorm"][
  1 + root1["Generator"] + root2["Generator"], fullRootPlan];
unmatchedRootNorm = mq["finiteFieldDeferredInhomogeneityRelativeNorm"][
  Sqrt[1 + sourceX + sourceY], fullRootPlan];
FTAssert["the relative norm handles inverse roots, keeps selected roots fixed, and refuses undeclared radicals",
  TrueQ[Together[inverseRootNorm + 1/(chartX^2 + chartY)] === 0] &&
    TrueQ[Together[selectedRootNorm - ((2 + chartX)^2 -
      chartX^2 - chartY)] === 0] && unmatchedRootNorm === $Failed];
fullRootCensus = mq["finiteFieldDeferredInhomogeneityCensus"][
  fullRootPlan["Key"], prime, "DegreeBound" -> 4,
  "Seed" -> 20260904, "Threads" -> 2];
FTAssert["the modular line census covers the fitted denominator with relative-norm factors",
  AssociationQ[fullRootCensus] && fullRootCensus["Status"] === "OK" &&
    fullRootCensus["CandidateCount"] > 0];
If[AssociationQ[fullRootPlan] &&
    StringQ[Lookup[fullRootPlan, "Key", None]],
  KeyDropFrom[FeynFacet`Private`$finiteFieldDeferredInhomogeneityRegistry,
    fullRootPlan["Key"]]];
Quiet[DeleteFile[fullRootFile]];

(* Projection is allowed only when the unwanted grades cancel. *)
noncancellingPreparation = ReplacePart[fullRootPreparation, "Records" -> {
  <|"Target" -> {1, 1, 1}, "Terms" -> {
    <|"Kind" -> "Base", "Coefficient" -> 1,
      "Operands" -> {root2["Generator"]}|>}|>,
  <|"Target" -> {2, 1, 1}, "Terms" -> {}|>}];
noncancellingFile = CreateTemporary[];
Put[<|"DeferredPreparation" -> <|
    "Preparation" -> noncancellingPreparation|>|>, noncancellingFile];
noncancellingPlan = mq["finiteFieldDeferredInhomogeneityPlan"][
  <|"Preparation" -> noncancellingPreparation,
    "CoefficientPresentation" -> <|
      "SquareRootGenerators" -> {root1, root2, root3}|>,
    "SquareRootGeneratorIndices" -> {1, 3},
    "ProjectionSquareRootGeneratorIndices" -> {2}|>,
  noncancellingFile,
  <|"SourceVariableSubstitution" ->
      {sourceX -> chartX, sourceY -> chartY},
    "DifferentialPullbackMatrix" -> IdentityMatrix[2]|>,
  {root1, root3}, {1 + chartX, 2 + chartY},
  {chartX, chartY}, {sourceX, sourceY}, epsilon, {1, 1}];
noncancellingImage = mq["finiteFieldDeferredInhomogeneityImages"][
  noncancellingPlan["Key"], prime, {{2, 5, 5}}, "Threads" -> 2];
FTAssert["a surviving root outside the parametrized subfield is refused",
  AssociationQ[noncancellingImage] &&
    noncancellingImage["Status"] ===
      "DeferredInhomogeneityOutsideRationalizedSubfield"];
If[AssociationQ[noncancellingPlan] &&
    StringQ[Lookup[noncancellingPlan, "Key", None]],
  KeyDropFrom[FeynFacet`Private`$finiteFieldDeferredInhomogeneityRegistry,
    noncancellingPlan["Key"]]];
Quiet[DeleteFile[noncancellingFile]];

unknown = mq["finiteFieldDeferredInhomogeneityImages"][
  "NoRegisteredPlan", prime, {{2, 3, 5}}, "Threads" -> 1];
FTAssert["an unregistered deferred-inhomogeneity plan is refused typed",
  AssociationQ[unknown] &&
    unknown["Status"] === "DeferredInhomogeneityPlanUnknown"];

retryable = mq["finiteFieldDeferredInhomogeneityRuntimeFailure"][
  "DeferredInhomogeneityPlanUnknown"];
terminal = mq["finiteFieldDeferredInhomogeneityRuntimeFailure"][
  "DeferredInhomogeneityBatchFailed"];
FTAssert["only a missing live routing plan is eligible for one local rebuild",
  mq["finiteFieldDeferredInhomogeneityLocalRetryQ"][retryable] &&
    ! mq["finiteFieldDeferredInhomogeneityLocalRetryQ"][terminal]];

(* The post-pullback acceptance evaluates the exact lifted coefficients
   directly.  This rank-one example exercises both the rational coefficient
   derivative and the logarithmic derivative of the square root, and compares
   it with the older symbolic-table evaluator at identical modular points. *)
Clear[coefficientP, coefficientQ];
coefficientRoot = <|
  "Generator" -> Sqrt[(1 + sourceY)^2],
  "QuadraticRadicand" -> (1 + sourceY)^2,
  "SourceRadicand" -> (1 + sourceY)^2|>;
coefficientPreparation = <|
  "DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 2,
  "Status" -> "Prepared", "Variables" -> {sourceX, sourceY},
  "Regulator" -> epsilon, "Dimensions" -> {2, 1, 1},
  "Records" -> {
    <|"Target" -> {1, 1, 1}, "Terms" -> {
      <|"Kind" -> "Base", "Coefficient" -> 1,
        "Operands" -> {1}|>}|>,
    <|"Target" -> {2, 1, 1}, "Terms" -> {
      <|"Kind" -> "Base", "Coefficient" -> 1,
        "Operands" -> {epsilon}|>}|>}|>;
coefficientPreparationFile = CreateTemporary[];
Put[<|"DeferredPreparation" -> <|
    "Preparation" -> coefficientPreparation|>|>,
  coefficientPreparationFile];
coefficientPlan = mq["finiteFieldDeferredInhomogeneityPlan"][
  <|"Preparation" -> coefficientPreparation,
    "CoefficientPresentation" -> <|
      "SquareRootGenerators" -> {coefficientRoot}|>,
    "SquareRootGeneratorIndices" -> {1},
    "ProjectionSquareRootGeneratorIndices" -> {}|>,
  coefficientPreparationFile,
  <|"SourceVariableSubstitution" ->
      {sourceX -> chartX, sourceY -> chartY},
    "DifferentialPullbackMatrix" -> IdentityMatrix[2]|>,
  {coefficientRoot}, {1 + chartY}, {chartX, chartY},
  {sourceX, sourceY}, epsilon, {1, 1}];
coefficientReexpression = mq[
  "reexpressBasisTransformationInSourceVariablesFiniteField"][
    {{coefficientP + epsilon coefficientQ}}, 1,
    {coefficientP, coefficientQ},
    {sourceX, coefficientRoot["Generator"]},
    {sourceX, sourceY}, epsilon, {coefficientRoot},
    "Primes" -> {1000003, 2147483423},
    "MinimumPrimeCount" -> 2, "MaximumPrimeCount" -> 2,
    "MaximumKinematicTotalDegree" -> 3,
    "MaximumEpsilonTotalDegree" -> 3,
    "SymbolicPreDispatchSeconds" -> 0,
    "HeldOutPointCount" -> 3];
zeroDiagonalBlocks = {{{{0}}, {{0}}}, {{{0}}, {{0}}}};
symbolicCoefficientResidual = mq[
  "finiteFieldDeferredInhomogeneityResidualQ"][coefficientPlan["Key"],
    zeroDiagonalBlocks, {{chartX + epsilon (1 + chartY)}}, {}, {}, 8,
    "Seed" -> 24680, "Threads" -> 2];
directCoefficientResidual = mq[
  "finiteFieldDeferredInhomogeneityCoefficientResidualQ"][
    coefficientPlan["Key"], zeroDiagonalBlocks,
    coefficientReexpression["CoefficientRepresentation"],
    {1}, {1}, {}, {}, 8, "Seed" -> 24680, "Threads" -> 2];
wrongBranchResidual = mq[
  "finiteFieldDeferredInhomogeneityCoefficientResidualQ"][
    coefficientPlan["Key"], zeroDiagonalBlocks,
    coefficientReexpression["CoefficientRepresentation"],
    {1}, {-1}, {}, {}, 8, "Seed" -> 24680, "Threads" -> 2];
FTAssert["the lifted coefficient residual agrees with direct symbolic evaluation",
  Lookup[symbolicCoefficientResidual, "ResidualZero", False] &&
    Lookup[directCoefficientResidual, "ResidualZero", False] &&
    symbolicCoefficientResidual["Prime"] ===
      directCoefficientResidual["Prime"] &&
    KeyExistsQ[directCoefficientResidual,
      "CoefficientEvaluationSeconds"]];
FTAssert["the lifted coefficient residual distinguishes the square-root branch",
  ! TrueQ[Lookup[wrongBranchResidual, "ResidualZero", False]]];
If[AssociationQ[coefficientPlan] &&
    StringQ[Lookup[coefficientPlan, "Key", None]],
  KeyDropFrom[FeynFacet`Private`$finiteFieldDeferredInhomogeneityRegistry,
    coefficientPlan["Key"]]];
Quiet[DeleteFile[coefficientPreparationFile]];

(* Rationalized square roots are represented by formal independent sign
   changes; this is not asserted to be a Galois orbit. *)
rx = Unique["rx"]; ry = Unique["ry"];
radicalExpression = 1 + Sqrt[(1 + rx)^2] + Sqrt[(1 + ry)^2];
radicalVariants = mq[
  "finiteFieldDeferredInhomogeneityRadicalVariants"][radicalExpression];
expectedVariants = Flatten[Table[1 + sx (1 + rx) + sy (1 + ry),
  {sx, {1, -1}}, {sy, {1, -1}}]];
FTAssert["two rationalized square roots produce all four formal sign-change images",
  Length[radicalVariants] === 4 && AllTrue[expectedVariants,
    Function[expected, AnyTrue[radicalVariants,
      TrueQ[Together[# - expected] === 0] &]]]];
FTAssert["polynomial square-root recognition retains rational scalar content",
  mq["finiteFieldDeferredInhomogeneityPolynomialRoot"][4 (1 + rx)^2] ===
    2 (1 + rx) &&
  mq["finiteFieldDeferredInhomogeneityPolynomialRoot"][2 (1 + rx)^2] ===
    $Failed];

source = Import[FileNameJoin[{root, "FeynFacet", "Private", "EpsForm",
  "FiniteField", "FiniteFieldDeferredInhomogeneity.wl"}], "Text"];
FTAssert["the live adapter uses inhomogeneity vocabulary and no stale fixture schema",
  StringContainsQ[source, "DeferredInhomogeneity"] &&
    StringFreeQ[source, "DeferredForcing" | "StripSolvers" |
      "RootFrame" | "RootSquares"]];

FTSummary[];
