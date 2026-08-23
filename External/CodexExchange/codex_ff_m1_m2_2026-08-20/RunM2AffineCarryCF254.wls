#!/usr/bin/env wolframscript

(* External M2 demonstration on the real dependent pair CF254 (9,7)->(9,6).
   No package or production checkpoint is written. *)

$HistoryLength = 0;

bundleDirectory = DirectoryName[$InputFileName];
repositoryRoot = "/home/maxzhang/factorization-and-loops";
historicalDirectory = FileNameJoin[{repositoryRoot, "Codex",
  "TwoRootCF254Sector9Lower"}];
fixtureDirectory = FileNameJoin[{repositoryRoot,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "BenchmarkStripBackends", "fixtures"}];
record7File = FileNameJoin[{fixtureDirectory, "fixture_CF254_9_7.wl"}];
record6File = FileNameJoin[{fixtureDirectory, "fixture_CF254_9_6.wl"}];
candidate7File = FileNameJoin[{historicalDirectory,
  "CF254_9_7_lifted_candidate.wl"}];
check7File = FileNameJoin[{historicalDirectory,
  "CF254_9_7_lifted_exact_check.wl"}];
residue7File = FileNameJoin[{historicalDirectory,
  "CF254_9_7_residue_data.wl"}];
candidate6File = FileNameJoin[{historicalDirectory,
  "CF254_9_6_raw_lifted_candidate.wl"}];
check6File = FileNameJoin[{historicalDirectory,
  "CF254_9_6_raw_lifted_exact_check.wl"}];
checkpointBefore7File = FileNameJoin[{historicalDirectory,
  "provenance_replay", "sector_CF254_standard",
  "CF254_9_strip_state.wl"}];
stateCandidates = {
  FileNameJoin[{historicalDirectory, "provenance_replay",
    "sector_state_CF254_standard.wl"}],
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_state_CF254_standard.wl"
};
historicalInterpolationFile = FileNameJoin[{historicalDirectory,
  "CF254_9_7_epsilon_interpolation_mod_1000003.wl"}];
outputFile = FileNameJoin[{bundleDirectory,
  "m2_cf254_affine_carry_result.wl"}];

loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
  "LoadFACET.wl"}];
prototypeM1File = FileNameJoin[{bundleDirectory,
  "CodexM1ConstrainedAffinePrototype.wl"}];
prototypeM2File = FileNameJoin[{bundleDirectory,
  "CodexM2AffineCarryPrototype.wl"}];

workerCount = 4;
prime = 1000003;
epsilonValue = 1/21;

Get[loadFile];
Get[prototypeM1File];
Get[prototypeM2File];

record7 = Get[record7File];
record6 = Get[record6File];
candidate7 = Get[candidate7File];
check7 = Get[check7File];
candidate6 = Get[candidate6File];
check6 = Get[check6File];
checkpointBefore7 = Get[checkpointBefore7File];
historicalInterpolation = Get[historicalInterpolationFile];
{x, y} = record7["Variables"];
epsilon = record7["Regulator"];

(* The older CF254 solve used the compatibility-reduced 1953-coordinate
   ansatz.  Its gauge part (1936 coordinates) and affine nullity (16) are
   exactly the same objects needed to measure full p,N interpolation and
   the downstream image. *)
sampleFiles = Sort[FileNames[
  "CF254_9_7_point_sample_rank_*_nx1_ny0_p1000003.wl",
  historicalDirectory]];
historicalSamples = Select[Get /@ sampleFiles,
  AssociationQ[#] && Lookup[#, "Prime", Missing[]] === prime &&
    TrueQ[Lookup[#, "Consistent", False]] &&
    TrueQ[Lookup[#, "ParticularCheckZero", False]] &&
    TrueQ[Lookup[#, "NullspaceCheckZero", False]] &&
    Lookup[#, "Nullity", -1] === 16 &];
historicalSamples = First /@ GatherBy[
  historicalSamples, #EpsilonValue &];
normalizationColumns = historicalInterpolation["NormalizationColumns"];
canonicalSamples = CodexM2CanonicalSampleValues[
    #, normalizationColumns, prime] & /@ historicalSamples;
If[MemberQ[canonicalSamples, $Failed] ||
    Length[canonicalSamples] < 28,
  Print["FAILED: historical affine samples did not normalize."];
  Exit[1]];
canonicalSamples = First /@ GatherBy[canonicalSamples, #EpsilonMod &];

Print["M2 full-state interpolation measurement: ",
  Length[canonicalSamples], " epsilon images, ",
  Length[First[canonicalSamples]["FullAffineValues"]],
  " p,N coordinates."];
memoryBeforeFullInterpolation = MaxMemoryUsed[];
{fullInterpolationSeconds, fullInterpolations} = AbsoluteTiming[
  CodexM2InterpolateCoordinateVectors[
    canonicalSamples, "FullAffineValues", prime, 24, 22]];
memoryAfterFullInterpolation = MaxMemoryUsed[];
If[! ListQ[fullInterpolations],
  Print["FAILED: full affine interpolation did not return a list."];
  Exit[1]];
fullUnresolvedCoordinates = Flatten[
  Position[fullInterpolations, $Failed]];
fullDegreeHistogram = Counts[
  Cases[fullInterpolations,
    interpolation_Association :> interpolation["Degrees"]]];
fullInterpolationByteCount = ByteCount[fullInterpolations];
Print["  full p,N interpolation seconds=", fullInterpolationSeconds,
  "; unresolved=", Length[fullUnresolvedCoordinates],
  "; in-memory bytes=", fullInterpolationByteCount, "."];
Clear[fullInterpolations];

pilotSample = SelectFirst[historicalSamples,
  #EpsilonValue === epsilonValue &];
pilotNormalized = NormalizeEpsFormAffineSample[
  pilotSample, normalizationColumns, prime];
If[! AssociationQ[pilotNormalized],
  Print["FAILED: pilot affine normalization."]; Exit[1]];
directionGauges = CodexM2DecodeGaugeVector[
    #, {4, 4}, pilotSample["GaugeNumeratorDegrees"],
    pilotSample["GaugeDenominator"] /. epsilon -> epsilonValue,
    {x, y}] & /@ pilotNormalized["NullspaceBasis"];
If[MemberQ[directionGauges, $Failed],
  Print["FAILED: could not decode upstream nullspace gauges."];
  Exit[1]];

(* Recreate the pre-(9,6) row state in memory.  This is the exact install
   operation used in production, but no checkpoint is changed here. *)
previousD6 = MapThread[Join,
  {candidate7["Gauge"], checkpointBefore7["PrevD"]}];

FeynFacet`Private`$canonicalBlocksCanonicaLoaded = False;
FeynFacet`Private`canonicalBlocksLoadCanonica[];
CANONICA`$ComputeParallel = False;
CANONICA`Private`$ComputeParallel = False;
canonicaSymbol[name_String] := Module[
  {public = ToExpression["CANONICA`" <> name],
   private = ToExpression["CANONICA`Private`" <> name]},
  Which[
    DownValues[Evaluate[public]] =!= {}, public,
    DownValues[Evaluate[private]] =!= {}, private,
    True, $Failed]
];
nextEquationFunction = canonicaSymbol["NextEquationD"];
If[nextEquationFunction === $Failed,
  Print["FAILED: CANONICA NextEquationD is unavailable."]; Exit[1]];
toCanonica[expression_] :=
  expression /. epsilon -> CANONICA`eps;
fromCanonica[expression_] :=
  expression /. CANONICA`eps -> epsilon;

ClearAll[regenerateFromState];
regenerateFromState[stateFile_String] := Module[
  {state, ranges, bounds, truncation, aTruncated, next},
  If[! FileExistsQ[stateFile], Return[$Failed]];
  state = Get[stateFile];
  If[! AssociationQ[state] ||
      ! MatchQ[Lookup[state, "A", Missing[]], {_?MatrixQ, _?MatrixQ}] ||
      ! ListQ[Lookup[state, "Ranges", Missing[]]], Return[$Failed]];
  ranges = state["Ranges"];
  If[Length[ranges] < 9, Return[$Failed]];
  bounds = ({First[#], Last[#]} &) /@ ranges;
  truncation = bounds[[9, 2]];
  aTruncated = toCanonica[{
    state["A"][[1, 1 ;; truncation, 1 ;; truncation]],
    state["A"][[2, 1 ;; truncation, 1 ;; truncation]]}];
  next = Quiet[nextEquationFunction[
    aTruncated, {x, y}, bounds[[1 ;; 9]],
    toCanonica[previousD6]]];
  If[! ListQ[next] || First[next] === False, Return[$Failed]];
  <|"StateFile" -> stateFile, "State" -> state,
    "Bounds" -> bounds, "ATruncated" -> aTruncated,
    "NextEquation" -> next|>
];

stateReplays = DeleteCases[regenerateFromState /@ stateCandidates,
  $Failed];
stripDifferenceZeroQ[next_] :=
  Dimensions[fromCanonica[next[[1 ;; 3]]]] ===
      Dimensions[record6["Strip"]] &&
    AllTrue[Flatten[
      fromCanonica[next[[1 ;; 3]]] - record6["Strip"]],
      TrueQ[Together[#] === 0] &];
selectedReplay = SelectFirst[stateReplays,
  stripDifferenceZeroQ[#NextEquation] &, Missing["NoExactReplay"]];
If[MissingQ[selectedReplay],
  Print["FAILED: neither read-only sector state regenerates (9,6)."];
  Exit[1]];
Print["Exact NextEquationD replay source: ",
  selectedReplay["StateFile"]];
nextEquation6 = selectedReplay["NextEquation"];
bounds = selectedReplay["Bounds"];
aTruncated = selectedReplay["ATruncated"];
nLowerSector = nextEquation6[[5]];
subsectorSize = 4;
lowerBlockSize = Length[First[aTruncated]] - subsectorSize;
cFull = Table[
  SeriesCoefficient[
    aTruncated[[mu, 1 ;; lowerBlockSize, 1 ;; lowerBlockSize]],
    {CANONICA`eps, 0, 1}],
  {mu, 2}];
cmix = fromCanonica[Table[
  (Take[#, bounds[[nLowerSector]]] &) /@
    Take[cFull[[mu]], {bounds[[nLowerSector + 1, 1]], -1}],
  {mu, 2}]];

Print["M2 downstream base-system capture for CF254 (9,6)."];
{downstreamBuildSeconds, downstreamSystem} = AbsoluteTiming[
  CodexM1BuildSampleSystem[
    record6, epsilonValue, prime,
    "NumeratorDegreeOffset" -> {1, 0},
    "CaptureMinimumDimension" -> 600]];
If[! AssociationQ[downstreamSystem] ||
    KeyExistsQ[downstreamSystem, "Status"],
  Print["FAILED: downstream system capture."]; Exit[1]];

projectionProbePrevious = Join[
  First[directionGauges], ConstantArray[0, {4, 2}], 2];
projectionProbeExpression =
  -epsilonValue (projectionProbePrevious.cmix[[1]])[[1, 1]];
projectionProbeSubstituted = Together[
  projectionProbeExpression /. Thread[{x, y} ->
    First[downstreamSystem["AcceptedPoints"]]]];
Print["  projection shapes: directions=",
  Dimensions[directionGauges], ", cmix=", Dimensions[cmix],
  ", points=", Length[downstreamSystem["AcceptedPoints"]],
  "; probe symbols=",
  DeleteDuplicates[Cases[projectionProbeExpression, _Symbol, Infinity]],
  "; post-substitution symbols=",
  DeleteDuplicates[Cases[projectionProbeSubstituted, _Symbol, Infinity]],
  "; denominator mod p=",
  Mod[Denominator[projectionProbeSubstituted], prime],
  "; numeric head=", Head[projectionProbeSubstituted],
  "; manual image=", Mod[
    Mod[Numerator[projectionProbeSubstituted], prime]
      PowerMod[Mod[Denominator[projectionProbeSubstituted], prime],
        -1, prime], prime],
  "; probe image=", CodexM2ModularValue[
    projectionProbeExpression, {x, y},
    First[downstreamSystem["AcceptedPoints"]], prime], "."];

{forcingProjectionSeconds, forcingDirections} = AbsoluteTiming[
  CodexM2ForcingDirectionMatrix[
    directionGauges, cmix, epsilonValue,
    downstreamSystem["AcceptedPoints"], {x, y}, prime]];
If[! MatrixQ[forcingDirections] ||
    Dimensions[forcingDirections][[1]] =!=
      Length[downstreamSystem["RightHandSide"]],
  Print["FAILED: downstream forcing projection."]; Exit[1]];

(* One symbolic unit-direction replay independently checks the L N formula
   against CANONICA's actual NextEquationD output. *)
deltaPrevious1 = Join[
  First[directionGauges], ConstantArray[0, {4, 2}], 2];
nextVariant1 = Quiet[nextEquationFunction[
  aTruncated, {x, y}, bounds[[1 ;; 9]],
  toCanonica[previousD6 + deltaPrevious1]]];
deltaForcing1 = Table[
  -epsilonValue deltaPrevious1.(cmix[[mu]]), {mu, 2}];
nextEquationDirectionAgreement = ListQ[nextVariant1] &&
  First[nextVariant1] =!= False &&
  AllTrue[Flatten[
    ((fromCanonica[nextVariant1[[3]]] -
       fromCanonica[nextEquation6[[3]]]) /.
        epsilon -> epsilonValue) - deltaForcing1],
    TrueQ[Together[#] === 0] &];

Print["M2 Schur constraint analysis."];
{schurAnalysisSeconds, schurAnalysis} = AbsoluteTiming[
  CodexM2SchurCarryAnalysis[
    downstreamSystem["Matrix"],
    downstreamSystem["RightHandSide"],
    forcingDirections, prime]];
If[! AssociationQ[schurAnalysis],
  Print["FAILED: Schur analysis."]; Exit[1]];

(* Exact two-row certificate.  The (9,7) historical solve used a reduced
   residue basis, so replay that certified forcing directly; (9,6) is a raw
   dlog-residue solution and uses the public verifier. *)
If[Length[Kernels[]] < workerCount,
  launchedKernels = Quiet[
    LaunchKernels[workerCount - Length[Kernels[]]]],
  launchedKernels = {}];
If[Length[Kernels[]] > workerCount,
  Print["FAILED: more than four Wolfram workers in fresh M2 run."];
  Exit[1]];

Print["M2 exact residual replay for CF254 (9,7)."];
residue7 = Get[residue7File];
forcing7 = residue7["Forcing"] /. candidate7["ResidueRules"];
gauge7 = candidate7["Gauge"];
{e7, c7, bbar7} = record7["Strip"];
residualExpressions7 = Flatten[Table[
  D[gauge7, record7["Variables"][[mu]]] -
    epsilon (e7[[mu]].gauge7 - gauge7.c7[[mu]]) - forcing7[[mu]],
  {mu, 2}]];
DistributeDefinitions[residualExpressions7];
{exactCheck7Seconds, checkedResiduals7} = AbsoluteTiming[
  ParallelMap[Together, residualExpressions7,
    Method -> "FinestGrained", DistributedContexts -> Automatic]];
exactResidual7Zero = AllTrue[checkedResiduals7,
  TrueQ[Numerator[#] === 0] &];
Clear[residue7, forcing7, residualExpressions7, checkedResiduals7];

Print["M2 exact residual replay for CF254 (9,6)."];
{exactCheck6WallSeconds, verification6} = AbsoluteTiming[
  VerifyEpsFormStrip[record6,
    <|"Gauge" -> candidate6["Gauge"],
      "Alphabet" -> candidate6["Alphabet"],
      "ResidueMatrices" -> candidate6["ResidueMatrices"]|>,
    "KernelCount" -> workerCount]];
exactResidual6Zero = AssociationQ[verification6] &&
  TrueQ[verification6["ExactPfaffianResidualsZero"]];

exactArtifactAgreement = And[
  TrueQ[candidate7["ExactPfaffianResidualsZero"]],
  TrueQ[check7["AllResidualsZero"]],
  SameQ[candidate7["Gauge"], check7["Gauge"]],
  TrueQ[candidate6["ExactPfaffianResidualsZero"]],
  TrueQ[check6["AllResidualsZero"]],
  SameQ[candidate6["Gauge"], check6["Gauge"]]
];
previousGaugeInstalledSameQ = SameQ[
  previousD6[[All, 1 ;; 4]], candidate7["Gauge"]];

currentFrozenCoordinateCounts = <|
  "ParticularCoordinates" -> 2144,
  "NullspaceCoordinates" -> 16 2144,
  "FullAffineCoordinates" -> 17 2144
|>;
historicalCoordinateCounts = <|
  "ParticularCoordinates" ->
    Length[First[canonicalSamples]["ParticularValues"]],
  "NullspaceCoordinates" ->
    Length[First[canonicalSamples]["NullspaceValues"]],
  "FullAffineCoordinates" ->
    Length[First[canonicalSamples]["FullAffineValues"]]
|>;

result = <|
  "Status" -> "Demonstrated",
  "Scope" -> "ExternalM2PrototypeNoPackageEdits",
  "DependentPair" -> {{"CF254", 9, 7}, {"CF254", 9, 6}},
  "Prime" -> prime,
  "EpsilonValue" -> epsilonValue,
  "RepresentationDecision" -> "ModularSchurComplementCarry",
  "HistoricalCoordinateCounts" -> historicalCoordinateCounts,
  "CurrentFrozenCoordinateCounts" -> currentFrozenCoordinateCounts,
  "ParticularOnlyInterpolationSeconds" ->
    historicalInterpolation["InterpolationSeconds"],
  "FullAffineInterpolationSeconds" -> fullInterpolationSeconds,
  "FullAffineInterpolationSlowdown" ->
    fullInterpolationSeconds /
      historicalInterpolation["InterpolationSeconds"],
  "FullAffineUnresolvedCoordinateCount" ->
    Length[fullUnresolvedCoordinates],
  "FullAffineDegreeHistogram" -> fullDegreeHistogram,
  "FullAffineInterpolationByteCount" -> fullInterpolationByteCount,
  "FullAffinePeakMemoryGrowthBytes" -> Max[0,
    memoryAfterFullInterpolation - memoryBeforeFullInterpolation],
  "NextEquationDReplaySource" -> selectedReplay["StateFile"],
  "NextEquationDStripAgreement" ->
    stripDifferenceZeroQ[nextEquation6],
  "NextEquationDDirectionAgreement" ->
    nextEquationDirectionAgreement,
  "CMixDimensions" -> Dimensions[cmix],
  "UpstreamAffineNullity" ->
    Length[pilotNormalized["NullspaceBasis"]],
  "DownstreamBuildSeconds" -> downstreamBuildSeconds,
  "ForcingProjectionSeconds" -> forcingProjectionSeconds,
  "ForcingDirectionByteCount" -> ByteCount[forcingDirections],
  "SchurAnalysisSeconds" -> schurAnalysisSeconds,
  "SchurAnalysis" -> schurAnalysis,
  "PreviousGaugeInstalledSameQ" -> previousGaugeInstalledSameQ,
  "ExactArtifactAgreement" -> exactArtifactAgreement,
  "ExactResidual7Zero" -> exactResidual7Zero,
  "ExactResidual7Seconds" -> exactCheck7Seconds,
  "ExactResidual6Zero" -> exactResidual6Zero,
  "ExactResidual6WallSeconds" -> exactCheck6WallSeconds,
  "ExactPairResidualZero" ->
    TrueQ[exactResidual7Zero && exactResidual6Zero]
|>;

temporaryOutputFile = outputFile <> ".tmp";
Put[result, temporaryOutputFile];
RenameFile[temporaryOutputFile, outputFile, OverwriteTarget -> True];
Print["M2 result saved: ", outputFile];
Print[InputForm[KeyDrop[result,
  {"FullAffineDegreeHistogram", "SchurAnalysis"}]]];
Print[InputForm[KeyTake[schurAnalysis,
  {"DownstreamMatrixDimensions", "DownstreamRank",
   "DownstreamNullity", "ForcingDirectionDimensions",
   "ForcingDirectionNonzeroEntries", "SchurRank",
   "AllowedUpstreamParameterNullity", "CombinedRank",
   "CombinedNullity", "CarriedDownstreamResidualZero"}]]];

If[! TrueQ[result["NextEquationDStripAgreement"]] ||
    ! TrueQ[result["NextEquationDDirectionAgreement"]] ||
    ! TrueQ[result["PreviousGaugeInstalledSameQ"]] ||
    ! TrueQ[result["ExactArtifactAgreement"]] ||
    ! TrueQ[result["ExactPairResidualZero"]] ||
    ! TrueQ[schurAnalysis["BaseLeftResidualZero"]] ||
    ! TrueQ[schurAnalysis["CarriedDownstreamResidualZero"]],
  Exit[1]];
