#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, transportFile, bundleFile,
    row19CertificateFile, outdir, resultFile, summaryFile, expectedHashes,
    dependencyFiles, dependencyHashes, hashHex, putAtomic, exportAtomic,
    fail, tag, result, badHashes, bundle, row19Certificate,
    sourceVariables, chartVariables, sourceRoots, usedRoots, rootSquares,
    nestedRadicand, nestedRootImage, canonicalize,
    chart, rekeyed, data, chartCertificate, identityData, coordinateMap,
    chartGauge, rawSourceGauge, sourceGauge, rootImages, signChoices,
    acceptedSigns,
    branchImages, branchedGauge, zeroMatrixQ, sourceCensus,
    activeSheetChoices, unclassifiedRadicals, constantField, checks,
    summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  transportFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "TransportCharts.wl"}];
  bundleFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  row19CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_certificate_v1/certificate.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_19_18_kallen23_source_pullback_v1";
  resultFile = FileNameJoin[{outdir, "source_gauge_19_18.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3031918Kallen23SourcePullbackV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    transportFile ->
      "2cd6cc63a94762c4546954881d5a16931e4ca1a6e7de716920882bad13d3efc9",
    bundleFile ->
      "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec",
    row19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "TransportCharts" -> transportFile|>;

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  putAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Put[expression, temporary];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  exportAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Export[temporary, expression, "WXF"];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  fail[status_String, data_: <||>] := Module[{failureFile, failure},
    failure = Join[<|"Status" -> status, "Family" -> "CF303",
      "Sector" -> 19, "LowerSector" -> 18,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 19->18 SOURCE PULLBACK FAILURE V1: ", status,
      " data=", data];
    Throw[$Failed, tag]];

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {},
      fail["WrapperTakesNoArguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["PoolWorkerRequired"]];
    If[Length[Kernels[]] =!= 0,
      fail["MissionWorkerAlreadyOwnsNestedKernels"]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 0),
      fail["HelperCeilingMustBeZero"]];
    If[(DirectoryQ[outdir] &&
          (FileExistsQ[resultFile] || FileExistsQ[summaryFile])) ||
        (FileExistsQ[outdir] && ! DirectoryQ[outdir]),
      fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    If[! DirectoryQ[outdir], CreateDirectory[outdir]];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];
    bundle = Get[bundleFile];
    row19Certificate = Import[row19CertificateFile, "WXF"];
    If[! AssociationQ[bundle] || ! AssociationQ[row19Certificate] ||
        Lookup[bundle, "Status", None] =!=
          "CF303PairFactorBundlePassedV3" ||
        Lookup[row19Certificate, "Status", None] =!=
          "CF303Sector19PairChartRowCertificatePassedV1" ||
        ! And @@ Values[row19Certificate["GlobalChecks"]],
      fail["InvalidInputABI"]];
    sourceVariables = bundle["SourceVariables"];
    chartVariables = bundle["ChartVariables"];
    sourceRoots = bundle["SourceRoots"];
    usedRoots = sourceRoots[[{1, 2}]];
    rootSquares = Lookup[usedRoots, "RootSquare", {}];
    nestedRadicand = bundle["NestedRadicand"];
    nestedRootImage = bundle["NestedRootImage"];
    If[! MatchQ[sourceVariables, {_Symbol, _Symbol}] ||
        ! MatchQ[chartVariables, {_Symbol, _Symbol}] ||
        Length[sourceRoots] =!= 3,
      fail["InvalidBundleVariables"]];

    chart = FeynFacet`TransportRootSetChart[rootSquares, sourceVariables];
    If[! AssociationQ[chart] || Lookup[chart, "Name", None] =!= "Kallen23",
      fail["Kallen23ChartNotSelected"]];
    rekeyed = FeynFacet`Private`transportChartRekey[
      chart, sourceVariables, chartVariables];
    data = FeynFacet`Private`masterTransportChartData[
      rekeyed, sourceVariables];
    chartCertificate = FeynFacet`TransportChartVerify[rekeyed];
    If[Lookup[data, "Status", None] =!= "OK" ||
        ! TrueQ[Lookup[chartCertificate, "OK", False]] ||
        ! AllTrue[MapThread[Function[{left, right},
          TrueQ[Together[(Last[left] - Last[right])] === 0]],
          {Lookup[data, "Subst", {}], bundle["SourceSubstitution"]}],
          TrueQ],
      fail["PinnedKallen23ChartMismatch", <|
        "DataStatus" -> Lookup[data, "Status", None],
        "ChartCertificate" -> chartCertificate|>]];

    identityData = <|"Status" -> "OK", "Kind" -> "TwoVariable",
      "CoefficientField" -> "Multiquadratic",
      "Variables" -> sourceVariables,
      "SourceVariables" -> sourceVariables,
      "Subst" -> Thread[sourceVariables -> sourceVariables],
      "Jacobian" -> IdentityMatrix[2], "JacobianDet" -> 1,
      "Root" -> sourceRoots[[1, "Root"]],
      "RootSquare" -> sourceRoots[[1, "RootSquare"]],
      "Roots" -> sourceRoots|>;
    coordinateMap = FeynFacet`Private`masterTransportRecordCoordinateMap[
      <|"Variables" -> chartVariables, "Chart" -> rekeyed|>,
      identityData, Automatic];
    If[Lookup[coordinateMap, "Status", None] =!= "OK" ||
        ! TrueQ[Lookup[coordinateMap, "CompositionExact", False]],
      fail["Kallen23InverseCoordinateMapFailed", <|
        "CoordinateMap" -> coordinateMap|>]];

    chartGauge = row19Certificate["SolvedChartGauges"][18];
    If[Dimensions[chartGauge] =!= {4, 2},
      fail["UnexpectedChartGaugeShape"]];
    Print["CF3031918SOURCEV1 stage=pullback chartLeaves=",
      LeafCount[chartGauge]];
    canonicalize[expression_] := Together[expression /.
      Power[base_, exponent_Rational] :> If[
        Denominator[exponent] === 2 &&
          TrueQ[Together[base - nestedRadicand] === 0],
        nestedRootImage^(2 exponent), Power[base, exponent]]];
    rawSourceGauge = Map[Together,
      chartGauge /. coordinateMap["Map"], {2}];
    sourceGauge = Map[canonicalize, rawSourceGauge, {2}];
    zeroMatrixQ[matrix_] := AllTrue[Flatten[Map[Together, matrix, {2}]],
      TrueQ[# === 0] &];
    rootImages = Lookup[bundle["RootImages"][[{1, 2}]], "Root", {}];
    signChoices = Tuples[{1, -1}, 2];
    acceptedSigns = Select[signChoices, Function[signs,
      branchImages = MapThread[Times, {signs, rootImages}];
      branchedGauge =
        FeynFacet`Private`transportChartApplyRootBranches[
          sourceGauge, usedRoots, branchImages];
      zeroMatrixQ[(branchedGauge /. data["Subst"]) - chartGauge]]];
    sourceCensus = FeynFacet`Private`transportChartRootIndices[
      sourceGauge, sourceRoots];
    unclassifiedRadicals = Lookup[sourceCensus,
      "UnclassifiedRadicalBases", {Missing["Absent"]}];
    constantField = If[AnyTrue[unclassifiedRadicals,
        TrueQ[Together[# - 2] === 0] &], "Q(Sqrt[2])", "Q"];
    activeSheetChoices = If[acceptedSigns === {}, {},
      DeleteDuplicates[acceptedSigns[[All,
        Lookup[sourceCensus, "RootIndices", {}]]]]];
    checks = <|
      "Kallen23ChartExact" -> TrueQ[chartCertificate["OK"]],
      "CoordinateCompositionExact" ->
        TrueQ[coordinateMap["CompositionExact"]],
      "GaugeDimensionsExact" -> Dimensions[sourceGauge] === {4, 2},
      "GaugeRoundTripHasSheet" -> acceptedSigns =!= {},
      "AcceptedGaugeSheetsRecorded" -> activeSheetChoices =!= {},
      "OnlyDeclaredConstantRadicalsUnclassified" -> AllTrue[
        unclassifiedRadicals, TrueQ[Together[# - 2] === 0] &],
      "OnlyKallen23RootsUsed" ->
        SubsetQ[{1, 2}, Lookup[sourceCensus, "RootIndices", {}]],
      "ResidualThirdRootAbsent" ->
        ! MemberQ[Lookup[sourceCensus, "RootIndices", {}], 3]|>;
    If[! And @@ Values[checks],
      fail["SourcePullbackChecksFailed", <|"Checks" -> checks,
        "SourceCensus" -> sourceCensus,
        "AcceptedSigns" -> acceptedSigns|>]];
    exportAtomic[<|
      "Status" -> "CF303Sector1918Kallen23SourcePullbackPassedV1",
      "Family" -> "CF303", "Sector" -> 19, "LowerSector" -> 18,
      "SourceVariables" -> sourceVariables,
      "ChartVariables" -> chartVariables,
      "Chart" -> "Kallen23", "ChartGauge" -> chartGauge,
      "SourceGauge" -> sourceGauge,
      "ConstantField" -> constantField,
      "SourceRootCensus" -> sourceCensus,
      "AcceptedBranchSigns" -> First[acceptedSigns],
      "AllAcceptedBranchSigns" -> acceptedSigns,
      "CoordinateMap" -> coordinateMap,
      "ChartCertificate" -> chartCertificate,
      "Checks" -> checks, "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    summary = <|
      "Status" -> "CF303Sector1918Kallen23SourcePullbackPassedV1",
      "Family" -> "CF303", "Sector" -> 19, "LowerSector" -> 18,
      "Chart" -> "Kallen23",
      "ChartGaugeLeafCount" -> LeafCount[chartGauge],
      "SourceGaugeLeafCount" -> LeafCount[sourceGauge],
      "SourceRootIndices" -> sourceCensus["RootIndices"],
      "ConstantField" -> constantField,
      "AcceptedBranchSigns" -> First[acceptedSigns],
      "AllAcceptedBranchSigns" -> acceptedSigns,
      "Checks" -> checks, "ResultFile" -> resultFile,
      "ResultSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringPullback"]];
    Print["CF3031918SOURCEV1 status=PASS sourceLeaves=",
      LeafCount[sourceGauge], " signs=", First[acceptedSigns]];
    0,
    tag];
  result
]
