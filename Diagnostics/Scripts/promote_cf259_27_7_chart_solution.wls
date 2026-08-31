#!/usr/bin/env wolframscript

(* Promote the already solved CF259 (27,7) KallenQ4a chart gauge into the
   source multiquadratic frame.  This deliberately does not rerun the strip
   solve and does not perform an exact symbolic Pfaffian check: acceptance is
   the package's standard per-block random-point finite-field residual. *)

repo = "/home/maxzhang/factorization-and-loops";
codexRepo = "/home/maxzhang/factorization-and-loops-codex";
familyData = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical"}];
inputFile = FileNameJoin[{familyData, "FamilyEpsFormsSolving",
  "triple_root_2026-08-28_codex_clean", "CF259",
  "sector_CF259_standard", "CF259_27_7_input.wl"}];
innerFile = FileNameJoin[{codexRepo, "Runtime",
  "2026-08-30_cf259_27_7_prepared_resume", "cf259_27_7_solution.wl"}];
preparedFile = FileNameJoin[{codexRepo, "Diagnostics", "Artifacts",
  "cf259_27_7_kallenq4a_prepared_sparse_record.wl"}];
outputFile = FileNameJoin[{codexRepo, "Diagnostics", "Artifacts",
  "cf259_27_7_source_solution.wl"}];
failureFile = FileNameJoin[{codexRepo, "Diagnostics", "Artifacts",
  "cf259_27_7_source_solution_failure.wl"}];

putAtomic[value_, path_String] := Module[{temporary = path <> ".tmp"},
  Put[value, temporary]; RenameFile[temporary, path, OverwriteTarget -> True]];
fail[stage_String, detail_] := Module[{record = <|
    "Status" -> "CF259ChartSolutionPromotionFailed",
    "Stage" -> stage, "Detail" -> detail|>},
  putAtomic[record, failureFile]; Print[record]; Quit[2]];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
registration = FeynFacet`TransportFamilyChartLoad[
  FileNameJoin[{familyData, "TransportFamilyCharts.wl"}]];
If[Lookup[registration, "Status", None] =!= "FamilyChartsRegistered",
  fail["ChartRegistration", registration]];

input = Get[inputFile];
inner = Get[innerFile];
prepared = Get[preparedFile];
If[Lookup[inner, "Status", None] =!= "Solved" ||
    ! MatrixQ[Lookup[inner, "Gauge", None]] ||
    MissingQ[Lookup[inner, "GaugeDenominator", Missing[]]],
  fail["InnerSolution", KeyDrop[inner, {"Gauge", "ResidueMatrices"}]]];

variables = input["Variables"];
epsilon = input["Regulator"];
frame = FeynFacet`TransportFamilyChart["CF259"];
If[! AssociationQ[frame], fail["FamilyFrame", frame]];

allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
If[allRoots === $Failed, fail["RootFrame", allRoots]];
deferredPreparation = Lookup[input, "DeferredPreparation", Automatic];
If[! AssociationQ[deferredPreparation],
  fail["DeferredPreparationMissing", Head[deferredPreparation]]];
preparationRootSquares = Lookup[deferredPreparation, "RootSquares", {}];
rootIndices = Map[Function[square,
  SelectFirst[Range[Length[allRoots]], Function[index,
    TrueQ[Together[allRoots[[index]]["RootSquare"] - square] === 0]],
    Missing["NoMatchingRoot", square]]], preparationRootSquares];
If[AnyTrue[rootIndices, MissingQ],
  fail["DeferredPreparationRootFrame", rootIndices]];
rootIndices = Sort[DeleteDuplicates[rootIndices]];

usedRoots = allRoots[[rootIndices]];
rootSquares = Lookup[usedRoots, "RootSquare", {}];
chart = FeynFacet`TransportRootSetChart[rootSquares, variables];
If[MissingQ[chart], fail["JointChart", rootSquares]];
If[Lookup[chart, "Name", None] =!= "KallenQ4a",
  fail["UnexpectedJointChart", Lookup[chart, "Name", None]]];

chartVariables = {Symbol["FeynFacet`Private`stripChartX"],
  Symbol["FeynFacet`Private`stripChartY"]};
rekeyed = FeynFacet`Private`transportChartRekey[
  chart, variables, chartVariables];
data = FeynFacet`Private`masterTransportChartData[rekeyed, variables];
If[Lookup[data, "Status", None] =!= "OK", fail["ChartData", data]];

chartRoots = Lookup[rekeyed, "Roots", {}];
rootImages = Table[Module[{matching = SelectFirst[chartRoots,
      TrueQ[Together[#1["RootSquare"] -
          usedRoots[[index]]["RootSquare"]] === 0] &,
      Missing["RootNotRationalized"]]},
    If[MissingQ[matching], matching, matching["Root"]]],
  {index, Length[usedRoots]}];
If[AnyTrue[rootImages, MissingQ], fail["RootImages", rootImages]];
chartBranchRoots = Map[<|"RootSquare" ->
    Together[#1["RootSquare"] /. data["Subst"]]|> &, usedRoots];

(* The persisted record is exactly the chart strip used by the accepted
   solve.  Rebuilding it here would repeat the old 1,218-second operand
   canonicalization, so promotion consumes the banked mathematical input. *)
If[! AssociationQ[prepared] ||
    ! AssociationQ[Lookup[prepared, "Record", None]],
  fail["PreparedChartRecord", Head[prepared]]];
chartRecord = prepared["Record"];
If[Lookup[chartRecord, "Variables", None] =!= chartVariables ||
    Lookup[chartRecord, "Regulator", None] =!= epsilon,
  fail["PreparedChartRecordFrame", KeyTake[chartRecord,
    {"Variables", "Regulator"}]]];
chartStrip = chartRecord["Strip"];

identityData = <|"Status" -> "OK", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Multiquadratic", "Variables" -> variables,
  "SourceVariables" -> variables,
  "Subst" -> Thread[variables -> variables],
  "Jacobian" -> IdentityMatrix[2], "JacobianDet" -> 1,
  "Root" -> If[allRoots === {}, None, allRoots[[1]]["Root"]],
  "RootSquare" -> If[allRoots === {}, None,
    allRoots[[1]]["RootSquare"]], "Roots" -> allRoots|>;
coordinateMap = FeynFacet`Private`masterTransportRecordCoordinateMap[
  <|"Variables" -> chartVariables, "Chart" -> rekeyed|>,
  identityData, Automatic];
If[Lookup[coordinateMap, "Status", None] =!= "OK",
  fail["CoordinateMap", coordinateMap]];
mapCanonicalization =
  FeynFacet`Private`transportChartCanonicalizeFrameImages[
    Last /@ coordinateMap["Map"], allRoots, variables];
If[Lookup[mapCanonicalization, "Status", None] =!= "OK",
  fail["CoordinateMapCanonicalization", mapCanonicalization]];
coordinateMap = Join[coordinateMap, <|
  "Map" -> MapThread[Rule, {First /@ coordinateMap["Map"],
    mapCanonicalization["Images"]}],
  "Images" -> mapCanonicalization["Images"],
  "DeclaredFieldRewrites" -> KeyTake[mapCanonicalization,
    {"Rewritten", "RewrittenBases", "NumericRadicalClasses"}]|>];

(* 61-bit primes: this pullback evaluator uses arbitrary-precision Wolfram
   modular arithmetic and is not subject to the packed 31-bit strip sampler's
   overflow guard. *)
pullbackPrimes = {2305843009213693951, 2305843009213693907,
  2305843009213693723, 2305843009213693487, 2305843009213693123,
  2305843009213692199, 2305843009213691993};
Print["[CF259 27,7 promotion] reconstructing source gauge with 61-bit primes"];
{pullbackSeconds, finiteFieldGauge} = AbsoluteTiming[
  FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
    inner["Gauge"], inner["GaugeDenominator"], chartVariables,
    coordinateMap["Images"], variables, epsilon, usedRoots,
    "Primes" -> pullbackPrimes, "MinimumPrimeCount" -> 2,
    "MaximumPrimeCount" -> Length[pullbackPrimes],
    "MaximumKinematicTotalDegree" -> 12,
    "MaximumEpsilonTotalDegree" -> 16,
    "SymbolicPreDispatchSeconds" -> 0.,
    "HeldOutPointCount" -> 8, "EpsilonHeldOutCount" -> 3,
    "Verbose" -> True]];
If[Lookup[finiteFieldGauge, "Status", None] =!=
    "FiniteFieldCanonicalGaugePrepared",
  fail["FiniteFieldGaugePullBack", KeyDrop[finiteFieldGauge, "Result"]]];
sourceGauge = finiteFieldGauge["Result"];

sourceAlphabet = DeleteDuplicates[Together /@
  (Lookup[inner, "Alphabet", {}] /. coordinateMap["Map"])];
sourceGaugeRadicalFreeQ = FreeQ[sourceGauge,
  Power[_, exponent_Rational /; Denominator[exponent] > 1]];
signChoices = If[sourceGaugeRadicalFreeQ,
  {ConstantArray[1, Length[usedRoots]]},
  Tuples[{1, -1}, Length[usedRoots]]];
Print["[CF259 27,7 promotion] random-point modular block acceptance over ",
  Length[signChoices], " branch choice(s)"];
postPullBackCandidates = Table[
  branchImages = MapThread[Times, {signs, rootImages}];
  postPullBackGauge =
    FeynFacet`Private`transportChartApplyRootBranches[
      sourceGauge, usedRoots, branchImages] /. data["Subst"];
  verification = FeynFacet`VerifyEpsFormStrip[
    <|"Strip" -> chartStrip, "Variables" -> chartVariables,
      "Regulator" -> epsilon|>,
    Join[KeyTake[inner, {"Alphabet", "ResidueMatrices"}],
      <|"Gauge" -> postPullBackGauge|>],
    "Method" -> "Numerical", "KernelCount" -> 1, "Points" -> 2];
  <|"Signs" -> signs, "Verification" -> verification|>,
  {signs, signChoices}];
accepted = Select[postPullBackCandidates,
  TrueQ[Lookup[Lookup[#1, "Verification", <||>],
    "DLogFormCertified", False]] &];
If[accepted === {}, fail["PostPullBackFiniteFieldResidual",
  KeyDrop[postPullBackCandidates, {"Gauge", "Residuals"}]]];
acceptedSigns = First[accepted]["Signs"];
verification = First[accepted]["Verification"];
acceptedInner = Join[inner,
  KeyTake[verification, {"NumericalPfaffianResidualsZero",
    "LettersEpsFree", "ResiduesKinematicsFree", "ResiduesEpsFree"}],
  <|"Certificate" -> "NumericalResidual",
    "ExactDLog" -> Missing["DeferredToFamilyCertificate"],
    "DLogFormCertified" -> Missing["DeferredToFamilyCertificate"]|>];

solution = <|"Status" -> "Solved",
  "Method" -> "RationalChart/" <> chart["Name"] <> "/" <>
    inner["Method"],
  "Gauge" -> sourceGauge, "RootIndices" -> rootIndices,
  "RootSquares" -> rootSquares, "Chart" -> chart,
  "Alphabet" -> sourceAlphabet,
  "InnerSolution" -> KeyDrop[acceptedInner, "Gauge"],
  "ExactDLog" -> Lookup[acceptedInner, "ExactDLog", False],
  "Certificate" -> Lookup[acceptedInner, "Certificate", "ExactDLog"],
  "FrameCertificate" -> <|
    "CoordinateComposition" -> TrueQ[coordinateMap["CompositionExact"]],
    "BranchSigns" -> acceptedSigns, "GaugeRoundTrip" -> True,
    "TransformedOneFormPullBack" -> True,
    "SourceDLog" -> Missing["DeferredToFamilyCertificate"],
    "Exact" -> False,
    "ValidationMode" -> "PostPullBackFiniteFieldResidual",
    "InnerCertificate" -> Lookup[acceptedInner, "Certificate", None],
    "UnseenPrime" -> Lookup[acceptedInner, "UnseenPrime", None],
    "NumericalPfaffianResidualsZero" -> Lookup[acceptedInner,
      "NumericalPfaffianResidualsZero", Missing["NotRun"]],
    "Normalizer" -> KeyDrop[finiteFieldGauge, "Result"]|>,
  "PromotionRecord" -> <|
    "InputFile" -> inputFile, "InnerSolutionFile" -> innerFile,
    "PullBackSeconds" -> pullbackSeconds,
    "PullBackPrimes" -> Lookup[finiteFieldGauge, "Primes", {}],
    "BranchSigns" -> acceptedSigns,
    "AcceptanceMethod" -> "RandomPointFiniteFieldResidual",
    "AcceptancePoints" -> Lookup[verification, "Points", 2]|>|>;
putAtomic[solution, outputFile];
If[FileExistsQ[failureFile], DeleteFile[failureFile]];
Print["[CF259 27,7 promotion] accepted and saved: ", outputFile];
Print[KeyTake[solution, {"Status", "Method", "Certificate",
  "ExactDLog", "PromotionRecord"}]];
