#!/usr/bin/env wolframscript

(* One-prime discriminator for the fixed-rho CF303 tangential bridge in the
   saved sector-24 basis (G_source,F25).

     B = (B_source, B_G + Q),
     D_parallel = partial_p at fixed rho,  rho = 2 p - z.

   The connection jet is reconstructed independently from the saved A.
   Q is the complete regularized H action on the inherited source modes.
   T25 is absent because the target block is still F25.  Mode 1 is excluded
   only after checking closure of modes 2 through 7 under Omega's right
   action. *)

$AllowInternet = False;
$HistoryLength = 0;
Clear[x, y, p, rho, eps];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 7,
  Print["Usage: build_cf303_pre_final_block_tangential_bridge_pilot.wls " <>
    "<CF303PreFinalBlockBasisConnectionJet.json[.gz]> " <>
    "<InheritedLowerSoftJets.wl> <ExplicitTargetNormalJets.wl> " <>
    "<TangentialJunctionMap.wl> <TangentialEvolution.wl> " <>
    "<CF303RegularizedNormalActionFiniteField.json[.gz]> <output.wl>"];
  Quit[64]];

connectionJetPath = ExpandFileName[arguments[[1]]];
lowerJetsPath = ExpandFileName[arguments[[2]]];
targetNormalJetsPath = ExpandFileName[arguments[[3]]];
junctionPath = ExpandFileName[arguments[[4]]];
evolutionPath = ExpandFileName[arguments[[5]]];
normalActionPath = ExpandFileName[arguments[[6]]];
outputPath = ExpandFileName[arguments[[7]]];

result = Catch@Module[
  {fail, started = AbsoluteTime[], connectionJet, lowerJets,
   targetNormalJets, junction, evolution, normalAction, readJSON,
   prime = 2305843009213641971, tangentialPoint = 3/5,
   targetPhysicalMasterIntegralIDs = {5, 6},
   sourcePhysicalMasterIntegralIDs = {2, 12, 21, 22, 29, 30},
   selectedPhysicalMasterIntegralIDs, targetStateRows,
   sourceStateColumns, selectedStateColumns,
   normalActionTargetMasterIntegralRows = {44, 45},
   inheritedModeIDs, explicitModeIDs, allBoundaryIDs, lazyPosition,
   explicitPositions, outsidePositions, omega, omegaClosure,
   exactZeroQ, ff, ffAtP,
   modeConfigurations, family, sourceJets, sourceDerivativeJets,
   sourceMatrices, sourceDerivativeMatrices,
   selectedModeMatrix, inverseSelectedModeMatrix, zero7,
   coefficientMatrix, values, derivativeValues, key, matrix,
   derivativeMatrix,
   matrixTotal, terms,
   targetGMatrices, targetGDerivativeMatrices, targetGDeck,
   targetGNormalMatrices, targetGLogNormalMatrices, targetJetSeries,
   targetNormalMode, targetNormalModeIndex,
   hModeMatrices, hModeDerivativeMatrices, qMatrices,
   qDerivativeMatrices, qRecord, qValue, qDerivativeValue,
   qExplicitCount = 0,
   collected, hRhoOrder, sourceRhoOrder, hEpsilonOrder,
   sourceEpsilonOrder,
   polynomialValue, polynomialDerivativeValue, pFiniteField,
   logMatrices, logDerivativeMatrices, logDeck, resonantModeIndices,
   resonantExplicitPositions, targetMatrices, targetDerivativeMatrices,
   targetLogMatrices, targetLogDerivativeMatrices,
   selectedOmega, omegaMatrices, omegaEpsilonMinimumByColumn,
   connectionRecord, coefficientRecord, row, column,
   gammaSource, gammaTarget, gammaSourceRhoOrders,
   gammaTargetRhoOrders, rhoValuations, sourceRhoValuations,
   targetRhoValuations, sourceRhoMinimum, targetRhoMinimum,
   gammaSourceEpsilonValuations, gammaTargetEpsilonValuations,
   gammaSourceEpsilonMinimum, gammaTargetEpsilonMinimum,
   epsFloor = -10, gammaSourceEpsHigh = 3,
   gammaTargetEpsHigh = 7, connectionImportSeconds,
   deckGet, productCoefficient, epsilonProductCoefficient,
   sourceEpsilonMaximumByMode = {5, 5, 6, 6, 6, 6},
   targetEpsilonMinimumByMode = {-3, -3, -3, -4, -3, -4},
   targetEpsilonMaximumByMode = {3, 3, 3, 3, 3, 3},
   epsilonWindows, epsilonLowerRequirements, omegaMinimum, lower, upper,
   regularResiduals, regularResidualTerms,
   logarithmicResiduals, logarithmicResidualTerms,
   frobeniusLogResiduals, frobeniusLogResidualTerms,
   frobeniusLogSourceMatrices, frobeniusLogTargetMatrices,
   frobeniusLogTargetDerivativeMatrices, frobeniusLogScale,
   explicitModeEigenvalues = {0, 0, 0, -4, 0, -4},
   maximumFrobeniusLogPower = 6, frobeniusLogPower,
   omegaNormalExponentClosure, frobeniusLogFailures,
   frobeniusLogTermwiseEvidence, frobeniusLogComparisonCount = 0,
   regularTermwiseEvidence, logarithmicTermwiseEvidence,
   regularFailures, logarithmicFailures,
   regularComparisonCount = 0, logarithmicComparisonCount = 0,
   logarithmicModePositions = {1, 2, 3, 5}, residual,
   retainedSourceRhoPairs, retainedTargetRhoPairs, validationConditions,
   status, epsilonAssociation},

  fail[status_String, extra_: <||>] :=
    Throw[Join[<|"DataType" ->
        "CF303PreFinalBlockBasisTangentialBridgePilot",
      "SchemaVersion" -> 2, "Status" -> status, "Family" -> "CF303"|>,
      extra]];

  If[! AllTrue[Most[arguments], FileExistsQ],
    fail["CF303TangentialBridgePilotInputMissing"]];
  readJSON[path_String] := Quiet[Check[
    If[FileExtension[path] === "gz",
      ImportString[Import[path, {"GZIP", "String"}], "RawJSON"],
      Import[path, "RawJSON"]], $Failed]];
  connectionImportSeconds = First@AbsoluteTiming[
    connectionJet = readJSON[connectionJetPath]];
  lowerJets = Quiet[Check[Get[lowerJetsPath], $Failed]];
  targetNormalJets = Quiet[Check[Get[targetNormalJetsPath], $Failed]];
  junction = Quiet[Check[Get[junctionPath], $Failed]];
  evolution = Quiet[Check[Get[evolutionPath], $Failed]];
  normalAction = readJSON[normalActionPath];
  If[! And @@ {
      AssociationQ[connectionJet],
      Lookup[connectionJet, "DataType", None] ===
        "CF303PreFinalBlockBasisConnectionJet",
      Lookup[connectionJet, "Status", None] ===
        "CF303PreFinalBlockBasisConnectionJetFiniteFieldReconstructed",
      Lookup[connectionJet, "Prime", None] === prime,
      Lookup[connectionJet["Basis"], "SavedStateSector", None] === 24,
      Lookup[connectionJet["Basis"],
        "TargetPhysicalMasterIntegralIDs", None] ===
        targetPhysicalMasterIntegralIDs,
      Lookup[connectionJet["Basis"],
        "SourcePhysicalMasterIntegralIDs", None] ===
        sourcePhysicalMasterIntegralIDs,
      Lookup[connectionJet["Basis"],
        "SelectedPhysicalMasterIntegralIDs", None] ===
        Join[sourcePhysicalMasterIntegralIDs,
          targetPhysicalMasterIntegralIDs],
      TrueQ[Lookup[connectionJet["Basis"],
        "RangesBlocksMappingIsBijective", False]],
      TrueQ[Lookup[connectionJet["Basis"],
        "RequestedPhysicalMasterIntegralOrderPreserved", False]],
      Lookup[connectionJet,
        "DemandedEpsilonOrderWindowsByBlock", None] ===
        <|"TargetFromSource" -> {-10, 3},
          "TargetFromTarget" -> {-8, 7}|>,
      AssociationQ[lowerJets],
      Lookup[lowerJets, "Status", None] ===
        "CF303InheritedLowerSoftJetsAcceptedV2",
      AssociationQ[targetNormalJets],
      Lookup[targetNormalJets, "DataType", None] ===
        "CF303ExplicitTargetNormalFrobeniusJets",
      Lookup[targetNormalJets, "Status", None] ===
        "CF303ExplicitTargetNormalFrobeniusJetsFiniteFieldValidated",
      Lookup[targetNormalJets, "Prime", None] === prime,
      Lookup[targetNormalJets, "PPoint", None] === tangentialPoint,
      Lookup[targetNormalJets, "InheritedModeOrder", None] ===
        junction["InheritedModeOrder"],
      Lookup[Lookup[targetNormalJets, "InputReferences", <||>],
        "InheritedLowerSoftJets", None] === lowerJetsPath,
      Lookup[Lookup[targetNormalJets, "InputReferences", <||>],
        "TangentialJunctionMap", None] === junctionPath,
      AssociationQ[junction],
      Lookup[junction, "Status", None] ===
        "CF303TangentialJunctionMapReconstructedV1",
      AssociationQ[evolution],
      Lookup[evolution, "DataType", None] ===
        "TangentialBoundaryEvolutionOperator",
      AssociationQ[normalAction],
      Lookup[normalAction, "DataType", None] ===
        "CF303RegularizedNormalActionFiniteField",
      Lookup[normalAction, "Status", None] ===
        "CF303RegularizedNormalActionFiniteFieldValidated",
      Lookup[normalAction, "Prime", None] === prime},
    fail["CF303TangentialBridgePilotInputInvalid"]];

  If[! PrimeQ[prime] || prime < 2^60,
    fail["CF303TangentialBridgePilotPrimeInvalid"]];
  selectedPhysicalMasterIntegralIDs = Join[
    sourcePhysicalMasterIntegralIDs, targetPhysicalMasterIntegralIDs];
  targetStateRows = connectionJet["Basis", "TargetStateRows"];
  selectedStateColumns =
    connectionJet["Basis", "SelectedStateColumns"];
  sourceStateColumns = Take[selectedStateColumns,
    Length[sourcePhysicalMasterIntegralIDs]];
  If[! And[
      VectorQ[targetStateRows, (IntegerQ[#] && # > 0) &],
      DuplicateFreeQ[targetStateRows],
      VectorQ[selectedStateColumns, (IntegerQ[#] && # > 0) &],
      DuplicateFreeQ[selectedStateColumns],
      Length[targetStateRows] === Length[targetPhysicalMasterIntegralIDs],
      Length[selectedStateColumns] ===
        Length[selectedPhysicalMasterIntegralIDs]],
    fail["CF303TangentialBridgePilotDerivedStateCoordinatesInvalid"]];
  If[Length[connectionJet["Records"]] =!= 16,
    fail["CF303TangentialBridgePilotConnectionJetCoverageInvalid"]];

  exactZeroQ[expression_] := AllTrue[Flatten[{expression}],
    TrueQ[Quiet[Cancel[Together[#]]] === 0] &];
  ff[expression_] := Module[{value, numerator, denominator},
    value = Quiet[Cancel[Together[expression]]];
    If[! RationalQ[value],
      fail["CF303TangentialBridgePilotCoefficientNotRational",
        <|"Coefficient" -> InputForm[value]|>]];
    numerator = Mod[Numerator[value], prime];
    denominator = Mod[Denominator[value], prime];
    If[denominator === 0,
      fail["CF303TangentialBridgePilotPointOnPole"]];
    Mod[numerator PowerMod[denominator, -1, prime], prime]
  ];
  ffAtP[expression_] := ff[expression /. p -> tangentialPoint];

  inheritedModeIDs = junction["InheritedModeOrder"];
  explicitModeIDs = Rest[inheritedModeIDs];
  allBoundaryIDs = evolution["BoundaryFunctionIDs"];
  If[Length[inheritedModeIDs] =!= 7 ||
      junction["CombinedModeOrder"] =!= allBoundaryIDs ||
      Complement[explicitModeIDs, allBoundaryIDs] =!= {},
    fail["CF303TangentialBridgePilotModeOrderInvalid"]];
  lazyPosition = First@FirstPosition[allBoundaryIDs,
    First[inheritedModeIDs]];
  explicitPositions = Flatten[
    FirstPosition[allBoundaryIDs, #] & /@ explicitModeIDs];
  outsidePositions = Complement[Range[Length[allBoundaryIDs]],
    explicitPositions];
  omega = evolution["BoundaryFunctionConnectionMatrix"];
  omegaClosure = exactZeroQ[omega[[outsidePositions, explicitPositions]]];
  If[! omegaClosure,
    fail["CF303TangentialBridgePilotExplicitModesNotClosedUnderOmega",
      <|"LazyModeRightAction" ->
        omega[[{lazyPosition}, explicitPositions]]|>]];

  (* Exact inherited source Frobenius jets in state-row order. *)
  zero7 = ConstantArray[0, {7, 7}];
  sourceJets = Association@Flatten[Table[
    {rhoOrder, epsilonOrder} -> zero7,
    {rhoOrder, 0, 4}, {epsilonOrder, 0, 6}]];
  sourceDerivativeJets = Association@Flatten[Table[
    {rhoOrder, epsilonOrder} -> zero7,
    {rhoOrder, 0, 4}, {epsilonOrder, 0, 6}]];
  family[name_] := SelectFirst[lowerJets["Families"],
    Lookup[#, "Family", None] === name &];
  modeConfigurations = {
    <|"Family" -> "CF1", "SupportPositions" -> {1},
      "Modes" -> {<|"Index" -> 1, "Vector" -> {1}|>}|>,
    <|"Family" -> "CF12", "SupportPositions" -> {2},
      "Modes" -> {<|"Index" -> 2, "Vector" -> {0, 1}|>}|>,
    <|"Family" -> "CF21", "SupportPositions" -> {3},
      "Modes" -> {<|"Index" -> 3, "Vector" -> {0, 1}|>}|>,
    <|"Family" -> "CF199", "SupportPositions" -> {4, 5},
      "Modes" -> {<|"Index" -> 4, "Vector" -> {0, 0, 2, -3}|>,
        <|"Index" -> 5, "Vector" -> {0, 0, 0, 1}|>}|>,
    <|"Family" -> "CF53", "SupportPositions" -> {6, 7},
      "Modes" -> {<|"Index" -> 6, "Vector" -> {0, 0, 2, -3}|>,
        <|"Index" -> 7, "Vector" -> {0, 0, 0, 1}|>}|>
  };
  Do[With[{familyRecord = family[configuration["Family"]]},
    Do[
      coefficientMatrix = Normal@SparseArray[
        ({#["Row"], #["Column"]} -> #["Value"]) & /@
          coefficientRecord["Entries"],
        familyRecord["SelectedFrobeniusPrefactor", "Dimensions"]];
      Do[
        values = coefficientMatrix . mode["Vector"];
        derivativeValues = D[values, p];
        key = {coefficientRecord["RhoOrder"],
          coefficientRecord["EpsilonOrder"]};
        matrix = sourceJets[key];
        derivativeMatrix = sourceDerivativeJets[key];
        Do[
          matrix[[configuration["SupportPositions"][[index]],
            mode["Index"]]] = ffAtP[values[[index]]];
          derivativeMatrix[[
            configuration["SupportPositions"][[index]],
            mode["Index"]]] =
              ffAtP[derivativeValues[[index]]],
          {index, Length[values]}];
        sourceJets[key] = matrix;
        sourceDerivativeJets[key] = derivativeMatrix,
        {mode, configuration["Modes"]}],
      {coefficientRecord,
        familyRecord["SelectedFrobeniusPrefactor",
          "NonzeroCoefficients"]}]],
    {configuration, modeConfigurations}];
  sourceMatrices = Association@Flatten[Table[
    rhoOrder -> Association@Table[epsilonOrder ->
      sourceJets[{rhoOrder, epsilonOrder}][[2 ;; 7, 2 ;; 7]],
      {epsilonOrder, 0, 6}], {rhoOrder, 0, 4}]];
  sourceDerivativeMatrices = Association@Flatten[Table[
    rhoOrder -> Association@Table[epsilonOrder ->
      sourceDerivativeJets[{rhoOrder, epsilonOrder}][[
        2 ;; 7, 2 ;; 7]],
      {epsilonOrder, 0, 6}], {rhoOrder, 0, 4}]];
  selectedModeMatrix = {
    {1, 0, 0, 0, 0, 0},
    {0, 1, 0, 0, 0, 0},
    {0, 0, 2, 0, 0, 0},
    {0, 0, -3, 1, 0, 0},
    {0, 0, 0, 0, 2, 0},
    {0, 0, 0, 0, -3, 1}};
  If[Mod[sourceMatrices[0][0] - selectedModeMatrix, prime] =!=
      ConstantArray[0, {6, 6}],
    fail["CF303TangentialBridgePilotSourceLeadingFrameMismatch"]];
  If[sourceDerivativeMatrices[0][0] =!=
      ConstantArray[0, {6, 6}],
    fail["CF303TangentialBridgePilotSourceLeadingFrameDerivativeMismatch"]];
  inverseSelectedModeMatrix =
    Map[ff, Inverse[selectedModeMatrix], {2}];
  matrixTotal[list_List, dimensions_List] :=
    If[list === {}, ConstantArray[0, dimensions],
      Mod[Total[list], prime]];

  (* The regular G target coefficient, complete regularized H action Q, and
     separate logarithmic Levelt deck.  Their sum is the target embedding in
     the saved sector-24 F25 block. *)
  targetGDeck = junction["TargetGModeMap"];
  targetGMatrices = Association@Table[epsilonOrder ->
    Map[ffAtP,
      Normal[targetGDeck[epsilonOrder]][[All, 8 ;; 13]], {2}],
    {epsilonOrder, -4, 3}];
  targetGDerivativeMatrices = Association@Table[epsilonOrder ->
    Map[ffAtP,
      D[Normal[targetGDeck[epsilonOrder]][[All, 8 ;; 13]], p], {2}],
    {epsilonOrder, -4, 3}];
  targetGNormalMatrices = Association@Table[rhoOrder ->
    Association@Table[epsilonOrder -> Transpose@Table[Module[
        {inheritedIndex = mode + 1, modeRecord, series},
        If[MemberQ[{5, 7}, inheritedIndex],
          modeRecord = targetNormalJets["NonzeroEigenmodes"][
            inheritedIndex];
          series = modeRecord["TargetJet" <> ToString[rhoOrder]],
          modeRecord = targetNormalJets["ResonantZeroModes"][
            inheritedIndex];
          series = Switch[rhoOrder,
            0, modeRecord["CanonicalFiniteTargetJet0"],
            1, modeRecord["RegularJet1"],
            2, modeRecord["RegularJet2"]]];
        Lookup[series, epsilonOrder, ConstantArray[0, 2]]],
      {mode, 6}], {epsilonOrder, -4, 3}], {rhoOrder, 0, 2}];
  targetGLogNormalMatrices = Association@Table[rhoOrder ->
    Association@Table[epsilonOrder -> Transpose@Table[Module[
        {inheritedIndex = mode + 1, modeRecord, series},
        If[MemberQ[{2, 3, 4, 6}, inheritedIndex],
          modeRecord = targetNormalJets["ResonantZeroModes"][
            inheritedIndex];
          series = modeRecord["LogJet" <> ToString[rhoOrder]];
          Lookup[series, epsilonOrder, ConstantArray[0, 2]],
          ConstantArray[0, 2]]], {mode, 6}],
      {epsilonOrder, -4, 3}], {rhoOrder, 0, 2}];
  If[AnyTrue[Range[-4, 3],
      Mod[targetGNormalMatrices[0][#] - targetGMatrices[#], prime] =!=
        ConstantArray[0, {2, 6}] &],
    fail["CF303TangentialBridgePilotTargetJetZeroMismatch"]];
  polynomialValue[coefficients_List, value_Integer] :=
    Fold[Mod[#1 value + #2, prime] &, 0, Reverse[coefficients]];
  polynomialDerivativeValue[coefficients_List, value_Integer] :=
    polynomialValue[
      MapIndexed[(First[#2]) #1 &, Rest[coefficients]], value];
  pFiniteField = ffAtP[p];
  qValue[record_Association] := Module[
    {numerator, denominator},
    numerator = polynomialValue[
      record["NumeratorCoefficientsModuloPrime"], pFiniteField];
    denominator = polynomialValue[
      record["DenominatorCoefficientsModuloPrime"], pFiniteField];
    If[denominator === 0,
      fail["CF303TangentialBridgePilotNormalActionPointOnPole",
        <|"Key" -> record["Key"]|>]];
    Mod[numerator PowerMod[denominator, -1, prime], prime]];
  qDerivativeValue[record_Association] := Module[
    {numerator, denominator, numeratorDerivative,
     denominatorDerivative},
    numerator = polynomialValue[
      record["NumeratorCoefficientsModuloPrime"], pFiniteField];
    denominator = polynomialValue[
      record["DenominatorCoefficientsModuloPrime"], pFiniteField];
    numeratorDerivative = polynomialDerivativeValue[
      record["NumeratorCoefficientsModuloPrime"], pFiniteField];
    denominatorDerivative = polynomialDerivativeValue[
      record["DenominatorCoefficientsModuloPrime"], pFiniteField];
    If[denominator === 0,
      fail["CF303TangentialBridgePilotNormalActionPointOnPole",
        <|"Key" -> record["Key"]|>]];
    Mod[(numeratorDerivative denominator -
        numerator denominatorDerivative) *
      PowerMod[denominator, -2, prime], prime]];
  hModeMatrices = Association@Table[rhoOrder -> Association@Table[
    epsilonOrder -> ConstantArray[0, {2, 6}],
    {epsilonOrder, -3, 4}], {rhoOrder, -2, 0}];
  hModeDerivativeMatrices =
    Association@Table[rhoOrder -> Association@Table[
    epsilonOrder -> ConstantArray[0, {2, 6}],
    {epsilonOrder, -3, 4}], {rhoOrder, -2, 0}];
  Do[
    If[2 <= qRecord["InheritedModeIndex"] <= 7,
      If[qRecord["CoefficientRepresentation"] =!=
          "RationalFunctionModuloPrime",
        fail["CF303TangentialBridgePilotExplicitNormalActionNotRational",
          <|"Key" -> qRecord["Key"]|>]];
      matrix = hModeMatrices[qRecord["NormalCoordinatePower"]][
        qRecord["EpsilonOrder"]];
      matrix[[First@FirstPosition[normalActionTargetMasterIntegralRows,
          qRecord["TargetMasterIntegralRow"]],
        qRecord["InheritedModeIndex"] - 1]] = qValue[qRecord];
      epsilonAssociation =
        hModeMatrices[qRecord["NormalCoordinatePower"]];
      epsilonAssociation[qRecord["EpsilonOrder"]] = matrix;
      hModeMatrices[qRecord["NormalCoordinatePower"]] =
        epsilonAssociation;
      matrix = hModeDerivativeMatrices[
        qRecord["NormalCoordinatePower"]][qRecord["EpsilonOrder"]];
      matrix[[First@FirstPosition[normalActionTargetMasterIntegralRows,
          qRecord["TargetMasterIntegralRow"]],
        qRecord["InheritedModeIndex"] - 1]] =
          qDerivativeValue[qRecord];
      epsilonAssociation =
        hModeDerivativeMatrices[qRecord["NormalCoordinatePower"]];
      epsilonAssociation[qRecord["EpsilonOrder"]] = matrix;
      hModeDerivativeMatrices[qRecord["NormalCoordinatePower"]] =
        epsilonAssociation;
      qExplicitCount++],
    {qRecord, normalAction["Coefficients"]}];
  qMatrices = Association@Table[rhoOrder -> Association@Table[
    epsilonOrder -> (
      collected = Reap[Do[
        If[hRhoOrder + sourceRhoOrder === rhoOrder &&
            hEpsilonOrder + sourceEpsilonOrder === epsilonOrder,
          Sow[Mod[
            hModeMatrices[hRhoOrder][hEpsilonOrder] .
            inverseSelectedModeMatrix .
            sourceMatrices[sourceRhoOrder][sourceEpsilonOrder],
            prime]]],
        {hRhoOrder, Keys[hModeMatrices]},
        {sourceRhoOrder, Keys[sourceMatrices]},
        {hEpsilonOrder, -3, 4},
        {sourceEpsilonOrder, 0, 6}]][[2]];
      matrixTotal[If[collected === {}, {}, First[collected]],
        {2, 6}]),
    {epsilonOrder, -3, 4}], {rhoOrder, -2, 2}];
  qDerivativeMatrices =
    Association@Table[rhoOrder -> Association@Table[
      epsilonOrder -> (
        collected = Reap[Do[
          If[hRhoOrder + sourceRhoOrder === rhoOrder &&
              hEpsilonOrder + sourceEpsilonOrder === epsilonOrder,
            Sow[Mod[
              hModeDerivativeMatrices[hRhoOrder][hEpsilonOrder] .
                inverseSelectedModeMatrix .
                sourceMatrices[sourceRhoOrder][sourceEpsilonOrder] +
              hModeMatrices[hRhoOrder][hEpsilonOrder] .
                inverseSelectedModeMatrix .
                sourceDerivativeMatrices[sourceRhoOrder][
                  sourceEpsilonOrder], prime]]],
          {hRhoOrder, Keys[hModeMatrices]},
          {sourceRhoOrder, Keys[sourceMatrices]},
          {hEpsilonOrder, -3, 4},
          {sourceEpsilonOrder, 0, 6}]][[2]];
        matrixTotal[If[collected === {}, {}, First[collected]],
          {2, 6}]),
      {epsilonOrder, -3, 4}], {rhoOrder, -2, 2}];
  logDeck = junction["ResonantZeroSector",
    "LogarithmicJordanCoefficientC"];
  resonantModeIndices = junction["ResonantZeroSector",
    "InheritedModeOrder"];
  resonantExplicitPositions =
    (First@FirstPosition[Range[2, 7], #]) & /@ resonantModeIndices;
  logMatrices = Association@Table[epsilonOrder -> (
      matrix = ConstantArray[0, {2, 6}];
      matrix[[All, resonantExplicitPositions]] =
        Normal[logDeck[epsilonOrder]];
      Map[ffAtP, matrix, {2}]),
    {epsilonOrder, -3, 4}];
  logDerivativeMatrices = Association@Table[epsilonOrder -> (
      matrix = ConstantArray[0, {2, 6}];
      matrix[[All, resonantExplicitPositions]] =
        D[Normal[logDeck[epsilonOrder]], p];
      Map[ffAtP, matrix, {2}]),
    {epsilonOrder, -3, 4}];
  If[AnyTrue[Range[-3, 3],
      Mod[targetGLogNormalMatrices[0][#] - logMatrices[#], prime] =!=
        ConstantArray[0, {2, 6}] &],
    fail["CF303TangentialBridgePilotResonantLogJetZeroMismatch"]];
  targetMatrices = Association@Table[rhoOrder -> Association@Table[
    epsilonOrder -> Mod[
      Lookup[qMatrices[rhoOrder], epsilonOrder,
        ConstantArray[0, {2, 6}]] +
      Lookup[Lookup[targetGNormalMatrices, rhoOrder, <||>],
        epsilonOrder, ConstantArray[0, {2, 6}]], prime],
    {epsilonOrder, -4, 4}], {rhoOrder, -2, 2}];
  targetDerivativeMatrices =
    Association@Table[rhoOrder -> Association@Table[
      epsilonOrder -> Mod[
        Lookup[qDerivativeMatrices[rhoOrder], epsilonOrder,
          ConstantArray[0, {2, 6}]] +
        If[rhoOrder === 0,
          Lookup[targetGDerivativeMatrices, epsilonOrder,
            ConstantArray[0, {2, 6}]],
          ConstantArray[0, {2, 6}]], prime],
      {epsilonOrder, -4, 4}], {rhoOrder, -2, 0}];
  targetLogMatrices = targetGLogNormalMatrices;
  targetLogDerivativeMatrices = <|0 -> logDerivativeMatrices|>;

  selectedOmega = omega[[explicitPositions, explicitPositions]];
  omegaMatrices = Association@Table[epsilonOrder ->
    Map[ffAtP[SeriesCoefficient[#, {eps, 0, epsilonOrder}]] &,
      selectedOmega, {2}], {epsilonOrder, epsFloor, gammaTargetEpsHigh}];
  omegaEpsilonMinimumByColumn = Table[
    SelectFirst[Range[epsFloor, gammaTargetEpsHigh],
      ! exactZeroQ[omegaMatrices[#][[All, column]]] &, Infinity],
    {column, 6}];
  omegaNormalExponentClosure = exactZeroQ@Table[
    If[explicitModeEigenvalues[[row]] ===
        explicitModeEigenvalues[[column]], 0,
      selectedOmega[[row, column]]], {row, 6}, {column, 6}];
  If[! omegaNormalExponentClosure,
    fail["CF303TangentialBridgePilotOmegaMixesNormalExponentSectors"]];
  frobeniusLogScale = Association@Table[frobeniusLogPower ->
    DiagonalMatrix[Mod[
      explicitModeEigenvalues^frobeniusLogPower *
        PowerMod[Factorial[frobeniusLogPower], -1, prime], prime]],
    {frobeniusLogPower, maximumFrobeniusLogPower}];
  frobeniusLogSourceMatrices = Association@Table[frobeniusLogPower ->
    Association@Table[rhoOrder -> Association@Table[epsilonOrder ->
      Mod[Lookup[sourceMatrices[rhoOrder],
          epsilonOrder - frobeniusLogPower,
          ConstantArray[0, {6, 6}]] .
        frobeniusLogScale[frobeniusLogPower], prime],
      {epsilonOrder, frobeniusLogPower, 6 + frobeniusLogPower}],
    {rhoOrder, Keys[sourceMatrices]}],
    {frobeniusLogPower, maximumFrobeniusLogPower}];
  frobeniusLogTargetMatrices = Association@Table[frobeniusLogPower ->
    Association@Table[rhoOrder -> Association@Table[epsilonOrder ->
      Mod[Lookup[targetMatrices[rhoOrder],
          epsilonOrder - frobeniusLogPower,
          ConstantArray[0, {2, 6}]] .
        frobeniusLogScale[frobeniusLogPower], prime],
      {epsilonOrder, -4 + frobeniusLogPower,
        4 + frobeniusLogPower}], {rhoOrder, Keys[targetMatrices]}],
    {frobeniusLogPower, maximumFrobeniusLogPower}];
  frobeniusLogTargetDerivativeMatrices = Association@Table[
    frobeniusLogPower -> Association@Table[rhoOrder ->
      Association@Table[epsilonOrder ->
        Mod[Lookup[targetDerivativeMatrices[rhoOrder],
            epsilonOrder - frobeniusLogPower,
            ConstantArray[0, {2, 6}]] .
          frobeniusLogScale[frobeniusLogPower], prime],
        {epsilonOrder, -4 + frobeniusLogPower,
          4 + frobeniusLogPower}],
      {rhoOrder, Keys[targetDerivativeMatrices]}],
    {frobeniusLogPower, maximumFrobeniusLogPower}];

  (* Rebuild the two connection decks from the independent finite-field
     rho/regulator coefficient table. *)
  rhoValuations = ConstantArray[Infinity, {2, 8}];
  Do[
    row = First@FirstPosition[targetStateRows,
      connectionRecord["TargetStateRow"]];
    column = First@FirstPosition[selectedStateColumns,
      connectionRecord["StateColumn"]];
    rhoValuations[[row, column]] =
      connectionRecord[
        "RhoValuationOrLowerBoundThroughRequestedOrder"],
    {connectionRecord, connectionJet["Records"]}];
  sourceRhoValuations = rhoValuations[[All, 1 ;; 6]];
  targetRhoValuations = rhoValuations[[All, 7 ;; 8]];
  sourceRhoMinimum = Min[Cases[Flatten[sourceRhoValuations],
    _Integer]];
  targetRhoMinimum = Min[Cases[Flatten[targetRhoValuations],
    _Integer]];
  If[sourceRhoMinimum < -4,
    fail["CF303TangentialBridgePilotSourceJetsTooShallow",
      <|"SourceRhoMinimum" -> sourceRhoMinimum,
        "AvailableSourceJetMaximum" -> 4|>]];
  If[targetRhoMinimum < 0,
    fail["CF303TangentialBridgePilotPositiveTargetJetsRequired",
      <|"TargetRhoMinimum" -> targetRhoMinimum,
        "AvailableTargetJetMaximum" -> 0|>]];

  gammaSourceRhoOrders = Range[sourceRhoMinimum, 0];
  gammaTargetRhoOrders = Range[targetRhoMinimum, 2];
  gammaSource = Association@Table[rhoOrder -> Association@Table[
    epsilonOrder -> ConstantArray[0, {2, 6}],
    {epsilonOrder, epsFloor, gammaSourceEpsHigh}],
    {rhoOrder, gammaSourceRhoOrders}];
  gammaTarget = Association@Table[rhoOrder -> Association@Table[
    epsilonOrder -> ConstantArray[0, {2, 2}],
    {epsilonOrder, -8, gammaTargetEpsHigh}],
    {rhoOrder, gammaTargetRhoOrders}];
  Do[
    row = First@FirstPosition[targetStateRows,
      connectionRecord["TargetStateRow"]];
    column = First@FirstPosition[selectedStateColumns,
      connectionRecord["StateColumn"]];
    Do[
      If[(column <= 6 && coefficientRecord["RhoPower"] <= 0) ||
          (column > 6 && coefficientRecord["RhoPower"] <= 2),
        If[column <= 6,
          matrix = gammaSource[coefficientRecord["RhoPower"]][
            coefficientRecord["EpsilonOrder"]];
          matrix[[row, column]] = coefficientRecord["Value"];
          epsilonAssociation =
            gammaSource[coefficientRecord["RhoPower"]];
          epsilonAssociation[coefficientRecord["EpsilonOrder"]] =
            matrix;
          gammaSource[coefficientRecord["RhoPower"]] =
            epsilonAssociation,
          matrix = gammaTarget[coefficientRecord["RhoPower"]][
            coefficientRecord["EpsilonOrder"]];
          matrix[[row, column - 6]] = coefficientRecord["Value"];
          epsilonAssociation =
            gammaTarget[coefficientRecord["RhoPower"]];
          epsilonAssociation[coefficientRecord["EpsilonOrder"]] =
            matrix;
          gammaTarget[coefficientRecord["RhoPower"]] =
            epsilonAssociation]],
      {coefficientRecord, connectionRecord["Coefficients"]}],
    {connectionRecord, connectionJet["Records"]}];
  gammaSourceEpsilonValuations = Flatten@Cases[
    connectionJet["Records"],
    record_Association /; record["Block"] === "TargetFromSource" :>
      Cases[record["Coefficients"],
        coefficient_Association /; coefficient["Value"] =!= 0 :>
          coefficient["EpsilonOrder"]]];
  gammaTargetEpsilonValuations = Flatten@Cases[
    connectionJet["Records"],
    record_Association /; record["Block"] === "TargetFromTarget" :>
      Cases[record["Coefficients"],
        coefficient_Association /; coefficient["Value"] =!= 0 :>
          coefficient["EpsilonOrder"]]];
  If[gammaSourceEpsilonValuations === {} ||
      gammaTargetEpsilonValuations === {},
    fail["CF303TangentialBridgePilotConnectionJetIsZero"]];
  gammaSourceEpsilonMinimum = Min[gammaSourceEpsilonValuations];
  gammaTargetEpsilonMinimum = Min[gammaTargetEpsilonValuations];

  deckGet[deck_Association, rhoOrder_Integer, epsilonOrder_Integer,
      dimensions_List] := Lookup[Lookup[deck, rhoOrder, <||>],
    epsilonOrder, ConstantArray[0, dimensions]];
  productCoefficient[left_, right_, rhoOrder_, epsilonOrder_,
      leftRhoOrders_, rightRhoOrders_, leftEpsilonOrders_,
      rightEpsilonOrders_, dimensions_] := Module[{collected},
    collected = Reap[Do[
      If[leftRho + rightRho === rhoOrder &&
          leftEpsilon + rightEpsilon === epsilonOrder,
        Sow[Mod[
          deckGet[left, leftRho, leftEpsilon,
            Dimensions[First[Values[First[Values[left]]]]]] .
          deckGet[right, rightRho, rightEpsilon,
            Dimensions[First[Values[First[Values[right]]]]]],
          prime]]],
      {leftRho, leftRhoOrders}, {rightRho, rightRhoOrders},
      {leftEpsilon, leftEpsilonOrders},
      {rightEpsilon, rightEpsilonOrders}]][[2]];
    matrixTotal[If[collected === {}, {}, First[collected]], dimensions]
  ];
  epsilonProductCoefficient[left_, right_, rhoOrder_, epsilonOrder_,
      leftEpsilonOrders_, rightEpsilonOrders_] :=
    matrixTotal[Table[
      Mod[deckGet[left, rhoOrder, leftEpsilon, {2, 6}] .
        Lookup[right, rightEpsilon, ConstantArray[0, {6, 6}]],
        prime],
      {leftEpsilon, leftEpsilonOrders},
      {rightEpsilon,
        Select[rightEpsilonOrders,
          leftEpsilon + # === epsilonOrder &]}] // Flatten[#, 1] &,
      {2, 6}];

  epsilonLowerRequirements = Table[
    omegaMinimum = omegaEpsilonMinimumByColumn[[mode]];
    Min[targetEpsilonMinimumByMode[[mode]],
      gammaSourceEpsilonMinimum,
      targetEpsilonMinimumByMode[[mode]] +
        gammaTargetEpsilonMinimum,
      If[omegaMinimum === Infinity,
        targetEpsilonMinimumByMode[[mode]],
        targetEpsilonMinimumByMode[[mode]] + omegaMinimum]],
    {mode, 6}];
  If[MapThread[Less, {epsilonLowerRequirements,
        targetEpsilonMinimumByMode}] // Or @@ # &,
    fail["CF303TangentialBridgePilotTargetEpsilonValuationInsufficient",
      <|"RequiredLowerOrders" -> epsilonLowerRequirements,
        "AvailableLowerOrders" -> targetEpsilonMinimumByMode|>]];
  epsilonWindows = Table[
    omegaMinimum = omegaEpsilonMinimumByColumn[[mode]];
    lower = targetEpsilonMinimumByMode[[mode]];
    upper = Min[targetEpsilonMaximumByMode[[mode]],
      sourceEpsilonMaximumByMode[[mode]] +
        gammaSourceEpsilonMinimum,
      targetEpsilonMaximumByMode[[mode]] +
        gammaTargetEpsilonMinimum,
      If[omegaMinimum === Infinity,
        targetEpsilonMaximumByMode[[mode]],
        targetEpsilonMaximumByMode[[mode]] + omegaMinimum]];
    {lower, upper},
    {mode, 6}];
  If[AnyTrue[epsilonWindows, Last[#] < First[#] &],
    fail["CF303TangentialBridgePilotNoCompleteEpsilonWindow",
      <|"Windows" -> epsilonWindows|>]];

  regularResiduals = <||>;
  regularResidualTerms = <||>;
  logarithmicResiduals = <||>;
  logarithmicResidualTerms = <||>;
  Do[
    terms = <|
      "TargetFromSourceConnectionTimesSourceEmbedding" ->
        productCoefficient[gammaSource, sourceMatrices,
        rhoOrder, epsilonOrder, Keys[gammaSource],
        Keys[sourceMatrices], Range[epsFloor, gammaSourceEpsHigh],
        Range[0, 6], {2, 6}],
      "TargetFromTargetConnectionTimesTargetEmbedding" ->
        productCoefficient[gammaTarget, targetMatrices,
        rhoOrder, epsilonOrder, Keys[gammaTarget],
        Keys[targetMatrices], Range[epsFloor, gammaTargetEpsHigh],
        Range[-4, 3], {2, 6}],
      "MinusFixedRhoTangentialDerivativeOfTargetEmbedding" ->
        Mod[-deckGet[targetDerivativeMatrices, rhoOrder, epsilonOrder,
          {2, 6}], prime],
      "MinusTargetEmbeddingTimesBoundaryConnection" ->
        Mod[-epsilonProductCoefficient[targetMatrices, omegaMatrices,
          rhoOrder, epsilonOrder, Range[-4, 3],
          Range[epsFloor, gammaTargetEpsHigh]], prime]|>;
    residual = Mod[Total[Values[terms]], prime];
    regularResidualTerms[{rhoOrder, epsilonOrder}] = terms;
    regularResiduals[{rhoOrder, epsilonOrder}] = residual,
    {rhoOrder, sourceRhoMinimum, 0}, {epsilonOrder,
      Min[First /@ epsilonWindows], Max[Last /@ epsilonWindows]}];
  Do[
    terms = <|
      "TargetFromTargetConnectionTimesLogarithmicEmbedding" ->
        productCoefficient[gammaTarget, targetLogMatrices,
        rhoOrder, epsilonOrder, Keys[gammaTarget],
        Keys[targetLogMatrices], Range[epsFloor, gammaTargetEpsHigh],
        Range[-3, 4], {2, 6}],
      "MinusFixedRhoTangentialDerivativeOfLogarithmicEmbedding" ->
        Mod[-deckGet[targetLogDerivativeMatrices, rhoOrder, epsilonOrder,
          {2, 6}], prime],
      "MinusLogarithmicEmbeddingTimesBoundaryConnection" ->
        Mod[-epsilonProductCoefficient[targetLogMatrices, omegaMatrices,
          rhoOrder, epsilonOrder, Range[-3, 4],
          Range[epsFloor, gammaTargetEpsHigh]], prime]|>;
    residual = Mod[Total[Values[terms]], prime];
    logarithmicResidualTerms[{rhoOrder, epsilonOrder}] = terms;
    logarithmicResiduals[{rhoOrder, epsilonOrder}] = residual,
    {rhoOrder, sourceRhoMinimum, 0}, {epsilonOrder,
      Min[First /@ epsilonWindows], Max[Last /@ epsilonWindows]}];
  frobeniusLogResiduals = <||>;
  frobeniusLogResidualTerms = <||>;
  Do[
    terms = <|
      "TargetFromSourceConnectionTimesInheritedSourceFrobeniusLog" ->
        productCoefficient[gammaSource,
          frobeniusLogSourceMatrices[frobeniusLogPower], rhoOrder,
          epsilonOrder, Keys[gammaSource], Keys[sourceMatrices],
          Range[epsFloor, gammaSourceEpsHigh],
          Range[frobeniusLogPower, 6 + frobeniusLogPower], {2, 6}],
      "TargetFromTargetConnectionTimesTargetFrobeniusLog" ->
        productCoefficient[gammaTarget,
          frobeniusLogTargetMatrices[frobeniusLogPower], rhoOrder,
          epsilonOrder, Keys[gammaTarget], Keys[targetMatrices],
          Range[epsFloor, gammaTargetEpsHigh],
          Range[-4 + frobeniusLogPower, 4 + frobeniusLogPower],
          {2, 6}],
      "MinusFixedRhoTangentialDerivativeOfTargetFrobeniusLog" ->
        Mod[-deckGet[
          frobeniusLogTargetDerivativeMatrices[frobeniusLogPower],
          rhoOrder, epsilonOrder, {2, 6}], prime],
      "MinusTargetFrobeniusLogTimesBoundaryConnection" ->
        Mod[-epsilonProductCoefficient[
          frobeniusLogTargetMatrices[frobeniusLogPower], omegaMatrices,
          rhoOrder, epsilonOrder,
          Range[-4 + frobeniusLogPower, 4 + frobeniusLogPower],
          Range[epsFloor, gammaTargetEpsHigh]], prime]|>;
    residual = Mod[Total[Values[terms]], prime];
    frobeniusLogResidualTerms[
      {frobeniusLogPower, rhoOrder, epsilonOrder}] = terms;
    frobeniusLogResiduals[
      {frobeniusLogPower, rhoOrder, epsilonOrder}] = residual,
    {frobeniusLogPower, maximumFrobeniusLogPower},
    {rhoOrder, sourceRhoMinimum, 0},
    {epsilonOrder,
      Min[First /@ epsilonWindows] + frobeniusLogPower,
      Max[Last /@ epsilonWindows] + frobeniusLogPower}];

  regularFailures = Reap[Do[
    If[Between[epsilonOrder, epsilonWindows[[mode]]] &&
        regularResiduals[{rhoOrder, epsilonOrder}][[row, mode]] =!= 0,
      Sow[<|"TargetStateRow" -> targetStateRows[[row]],
        "TargetPhysicalMasterIntegralID" ->
          targetPhysicalMasterIntegralIDs[[row]],
        "InheritedModeIndex" -> mode + 1,
        "RhoPower" -> rhoOrder, "EpsilonOrder" -> epsilonOrder,
        "Residual" ->
          regularResiduals[{rhoOrder, epsilonOrder}][[row, mode]],
        "SignedTermValues" -> Map[
          #[[row, mode]] &,
          regularResidualTerms[{rhoOrder, epsilonOrder}]]|>]];
    If[Between[epsilonOrder, epsilonWindows[[mode]]],
      regularComparisonCount++],
    {rhoOrder, sourceRhoMinimum, 0}, {mode, 6},
    {epsilonOrder, Range @@ epsilonWindows[[mode]]}, {row, 2}]][[2]];
  regularFailures = If[regularFailures === {}, {}, First[regularFailures]];
  logarithmicFailures = Reap[Do[
    If[MemberQ[logarithmicModePositions, mode] &&
        Between[epsilonOrder, epsilonWindows[[mode]]] &&
        logarithmicResiduals[{rhoOrder, epsilonOrder}][[row, mode]] =!= 0,
      Sow[<|"TargetStateRow" -> targetStateRows[[row]],
        "TargetPhysicalMasterIntegralID" ->
          targetPhysicalMasterIntegralIDs[[row]],
        "InheritedModeIndex" -> mode + 1,
        "RhoPower" -> rhoOrder, "EpsilonOrder" -> epsilonOrder,
        "Residual" ->
          logarithmicResiduals[{rhoOrder, epsilonOrder}][[
            row, mode]],
        "SignedTermValues" -> Map[
          #[[row, mode]] &,
          logarithmicResidualTerms[{rhoOrder, epsilonOrder}]]|>]];
    If[MemberQ[logarithmicModePositions, mode] &&
        Between[epsilonOrder, epsilonWindows[[mode]]],
      logarithmicComparisonCount++],
    {rhoOrder, sourceRhoMinimum, 0}, {mode, 6},
    {epsilonOrder, Range @@ epsilonWindows[[mode]]}, {row, 2}]][[2]];
  logarithmicFailures = If[logarithmicFailures === {}, {},
    First[logarithmicFailures]];
  frobeniusLogFailures = Reap[Do[
    If[explicitModeEigenvalues[[mode]] =!= 0 &&
        Between[epsilonOrder,
          epsilonWindows[[mode]] + frobeniusLogPower] &&
        frobeniusLogResiduals[
          {frobeniusLogPower, rhoOrder, epsilonOrder}][[
            row, mode]] =!= 0,
      Sow[<|"TargetStateRow" -> targetStateRows[[row]],
        "TargetPhysicalMasterIntegralID" ->
          targetPhysicalMasterIntegralIDs[[row]],
        "InheritedModeIndex" -> mode + 1,
        "LogarithmPower" -> frobeniusLogPower,
        "RhoPower" -> rhoOrder, "EpsilonOrder" -> epsilonOrder,
        "Residual" -> frobeniusLogResiduals[
          {frobeniusLogPower, rhoOrder, epsilonOrder}][[row, mode]],
        "SignedTermValues" -> Map[#[[row, mode]] &,
          frobeniusLogResidualTerms[
            {frobeniusLogPower, rhoOrder, epsilonOrder}]]|>]];
    If[explicitModeEigenvalues[[mode]] =!= 0 &&
        Between[epsilonOrder,
          epsilonWindows[[mode]] + frobeniusLogPower],
      frobeniusLogComparisonCount++],
    {frobeniusLogPower, maximumFrobeniusLogPower},
    {rhoOrder, sourceRhoMinimum, 0}, {mode, 6},
    {epsilonOrder,
      Range @@ (epsilonWindows[[mode]] + frobeniusLogPower)},
    {row, 2}]][[2]];
  frobeniusLogFailures = If[frobeniusLogFailures === {}, {},
    First[frobeniusLogFailures]];
  regularTermwiseEvidence = Flatten@Table[
    If[Between[epsilonOrder, epsilonWindows[[mode]]],
      {<|"TargetStateRow" -> targetStateRows[[row]],
        "TargetPhysicalMasterIntegralID" ->
          targetPhysicalMasterIntegralIDs[[row]],
        "InheritedModeIndex" -> mode + 1,
        "RhoPower" -> rhoOrder,
        "EpsilonOrder" -> epsilonOrder,
        "SignedTermValues" -> Map[
          #[[row, mode]] &,
          regularResidualTerms[{rhoOrder, epsilonOrder}]],
        "Residual" ->
          regularResiduals[{rhoOrder, epsilonOrder}][[row, mode]]|>},
      {}],
    {rhoOrder, sourceRhoMinimum, 0}, {mode, 6},
    {epsilonOrder, Range @@ epsilonWindows[[mode]]}, {row, 2}];
  logarithmicTermwiseEvidence = Flatten@Table[
    If[MemberQ[logarithmicModePositions, mode] &&
        Between[epsilonOrder, epsilonWindows[[mode]]],
      {<|"TargetStateRow" -> targetStateRows[[row]],
        "TargetPhysicalMasterIntegralID" ->
          targetPhysicalMasterIntegralIDs[[row]],
        "InheritedModeIndex" -> mode + 1,
        "RhoPower" -> rhoOrder,
        "EpsilonOrder" -> epsilonOrder,
        "SignedTermValues" -> Map[
          #[[row, mode]] &,
          logarithmicResidualTerms[{rhoOrder, epsilonOrder}]],
        "Residual" ->
          logarithmicResiduals[{rhoOrder, epsilonOrder}][[
            row, mode]]|>},
      {}],
    {rhoOrder, sourceRhoMinimum, 0}, {mode, 6},
    {epsilonOrder, Range @@ epsilonWindows[[mode]]}, {row, 2}];
  frobeniusLogTermwiseEvidence = Flatten@Table[
    If[explicitModeEigenvalues[[mode]] =!= 0 &&
        Between[epsilonOrder,
          epsilonWindows[[mode]] + frobeniusLogPower],
      {<|"TargetStateRow" -> targetStateRows[[row]],
        "TargetPhysicalMasterIntegralID" ->
          targetPhysicalMasterIntegralIDs[[row]],
        "InheritedModeIndex" -> mode + 1,
        "LogarithmPower" -> frobeniusLogPower,
        "RhoPower" -> rhoOrder,
        "EpsilonOrder" -> epsilonOrder,
        "SignedTermValues" -> Map[#[[row, mode]] &,
          frobeniusLogResidualTerms[
            {frobeniusLogPower, rhoOrder, epsilonOrder}]],
        "Residual" -> frobeniusLogResiduals[
          {frobeniusLogPower, rhoOrder, epsilonOrder}][[row, mode]]|>},
      {}],
    {frobeniusLogPower, maximumFrobeniusLogPower},
    {rhoOrder, sourceRhoMinimum, 0}, {mode, 6},
    {epsilonOrder,
      Range @@ (epsilonWindows[[mode]] + frobeniusLogPower)}, {row, 2}];

  retainedSourceRhoPairs = Select[
    Tuples[{Keys[gammaSource], Keys[sourceMatrices]}],
    sourceRhoMinimum <= Total[#] <= 0 &];
  retainedTargetRhoPairs = Select[
    Tuples[{Keys[gammaTarget], Keys[targetMatrices]}],
    sourceRhoMinimum <= Total[#] <= 0 &];
  validationConditions = <|
    "SavedSectorTwentyFourMixedBasisUsedConsistently" -> True,
    "RangesBlocksMappingIsBijective" ->
      TrueQ[connectionJet["Basis",
        "RangesBlocksMappingIsBijective"]],
    "RequestedPhysicalMasterIntegralOrderPreserved" ->
      TrueQ[connectionJet["Basis",
        "RequestedPhysicalMasterIntegralOrderPreserved"]],
    "StateTargetRowsMapToRequestedPhysicalMasterIntegralIDs" ->
      connectionJet["Basis", "TargetPhysicalMasterIntegralIDs"] ===
        targetPhysicalMasterIntegralIDs,
    "ModesTwoThroughSevenClosedUnderOmegaRightAction" -> omegaClosure,
    "OmegaPreservesFactoredNormalExponentSectors" ->
      omegaNormalExponentClosure,
    "ExplicitTargetGRegularAndResonantLogJetsThroughRhoTwoValidated" ->
      targetNormalJets["NormalCoordinatePowerWindow"] === {0, 2} &&
        And @@ Values[targetNormalJets["Validation", "Conditions"]],
    "ConnectionJetPhysicalSheetDeclaredAndSquaredExactly" ->
      TrueQ[connectionJet["Validation", "Conditions",
        "DeclaredPhysicalRootJetsSquareExactly"]],
    "CompleteRegularizedQActionIncluded" ->
      normalAction["CoefficientCount"] === 336 && qExplicitCount === 288 &&
        normalAction["DemandCoverage"] === "Complete",
    "TargetTargetTangentialConnectionRegularInRho" ->
      targetRhoMinimum >= 0,
    "SourceFrobeniusJetsCoverTargetSourceValuation" ->
      sourceRhoMinimum >= -4,
    "ExplicitRegularResidualZero" -> regularFailures === {},
    "ExplicitLogarithmicResidualZero" ->
      logarithmicFailures === {},
    "InheritedSourceAndHActionFrobeniusLogResidualZero" ->
      frobeniusLogFailures === {}|>;
  status = If[And @@ Values[validationConditions],
    "CF303ExplicitInheritedModeTangentialBridgeFiniteFieldMethodValidatedPendingV2LowerFamilyInputs",
    "CF303ExplicitInheritedModeTangentialBridgeFiniteFieldFailed"];
  <|"DataType" -> "CF303PreFinalBlockBasisTangentialBridgePilot",
    "SchemaVersion" -> 2,
    "Status" -> status, "Family" -> "CF303", "Prime" -> prime,
    "TangentialPoint" -> {3, 5},
    "Basis" -> <|
      "Name" -> "CF303PreFinalBlockBasis",
      "OrderedAmbientBasis" -> "(G_source,F25)",
      "Connection" -> "SavedSector24A",
      "Embedding" -> "B=(B_source,B_G+Q)",
      "IncludedRegularizedAction" ->
        "Q=(H.SourceLeadingModeMap).Inverse[SourceLeadingModeMap].B_source",
      "ExcludedFinalBlockTransformation" -> "T25",
      "TargetStateRows" -> targetStateRows,
      "TargetPhysicalMasterIntegralIDs" ->
        targetPhysicalMasterIntegralIDs,
      "SelectedSourceStateColumns" -> sourceStateColumns,
      "SelectedSourcePhysicalMasterIntegralIDs" ->
        sourcePhysicalMasterIntegralIDs,
      "NormalActionTargetMasterIntegralRows" ->
        normalActionTargetMasterIntegralRows|>,
    "NormalCoordinate" -> "rho=2*p-z",
    "FixedRhoDerivative" -> "partial_p|rho=partial_p|z+2*partial_z",
    "TargetGNormalJetPowerWindow" -> {0, 2},
    "TangentialResidualPowerWindow" -> {sourceRhoMinimum, 0},
    "PositiveTargetJetDerivativeStatus" ->
      "NotRequiredForResidualThroughRhoZero",
    "FrobeniusLogarithmConvention" -> <|
      "Representation" ->
        "rho^(r*eps) factored by normal-exponent sector",
      "ExplicitModeNormalEigenvaluesOverEpsilon" ->
        explicitModeEigenvalues,
      "ExpandedLogarithmPowersChecked" ->
        Range[maximumFrobeniusLogPower],
      "SourceAndRegularizedHActionIncluded" -> True,
      "ResonantTargetLogarithmsStoredSeparately" -> True|>,
    "PhysicalSheetBoundaryRootValues" -> {6/5, 8/5, 7/25},
    "OmegaClosure" -> <|
      "LazyInheritedModeIndex" -> 1,
      "TestedInheritedModeIndices" -> Range[2, 7],
      "LazyModeRightAction" ->
        omega[[{lazyPosition}, explicitPositions]],
      "AllOutsideToTestedEntriesZero" -> omegaClosure|>,
    "TargetRowRhoValuations" -> Flatten[Table[
      <|"TargetStateRow" -> targetStateRows[[row]],
        "TargetPhysicalMasterIntegralID" ->
          targetPhysicalMasterIntegralIDs[[row]],
        "StateColumn" -> selectedStateColumns[[column]],
        "PhysicalMasterIntegralID" ->
          selectedPhysicalMasterIntegralIDs[[column]],
        "Block" -> If[column <= 6, "TargetFromSource",
          "TargetFromTarget"],
        "RhoValuationOrLowerBoundThroughOrderTwo" ->
          rhoValuations[[row, column]]|>,
      {row, 2}, {column, 8}], 1],
    "TargetFromSourceRhoValuation" -> sourceRhoMinimum,
    "TargetFromTargetRhoValuation" -> targetRhoMinimum,
    "RetainedTargetFromSourceRhoPairs" -> retainedSourceRhoPairs,
    "RetainedTargetFromTargetRhoPairs" -> retainedTargetRhoPairs,
    "CompleteEpsilonOrderWindowsByInheritedModeIndex" ->
      Association@Table[mode + 1 -> epsilonWindows[[mode]], {mode, 6}],
    "RegularResidualComparisonCount" -> regularComparisonCount,
    "LogarithmicResidualComparisonCount" -> logarithmicComparisonCount,
    "FrobeniusLogResidualComparisonCount" ->
      frobeniusLogComparisonCount,
    "RegularResidualFailureCount" -> Length[regularFailures],
    "LogarithmicResidualFailureCount" -> Length[logarithmicFailures],
    "FrobeniusLogResidualFailureCount" -> Length[frobeniusLogFailures],
    "RegularTermwiseFiniteFieldResiduals" ->
      regularTermwiseEvidence,
    "LogarithmicTermwiseFiniteFieldResiduals" ->
      logarithmicTermwiseEvidence,
    "FrobeniusLogTermwiseFiniteFieldResiduals" ->
      frobeniusLogTermwiseEvidence,
    "RegularResidualFailures" -> Take[regularFailures, UpTo[12]],
    "LogarithmicResidualFailures" ->
      Take[logarithmicFailures, UpTo[12]],
    "FrobeniusLogResidualFailures" ->
      Take[frobeniusLogFailures, UpTo[12]],
    "LazyModeDifferentiation" -> "NotRunInExplicitModeDiscriminator",
    "ProductionPhysicalTransportStatus" ->
      "BlockedPendingV2LowerFamilyDifferentialSystems",
    "ArchivedLowerFamilyInputProvenance" ->
      lowerJets["ConstructionInputProvenance"],
    "Validation" -> <|"Method" ->
      "ExactFiniteFieldArithmeticAtOneExisting61BitPrime",
      "Conditions" -> validationConditions|>,
    "InputReferences" -> <|
      "CF303PreFinalBlockBasisConnectionJet" -> connectionJetPath,
      "InheritedLowerSoftJets" -> lowerJetsPath,
      "ExplicitTargetNormalFrobeniusJets" -> targetNormalJetsPath,
      "TangentialJunctionMap" -> junctionPath,
      "TangentialBoundaryEvolutionOperator" -> evolutionPath,
      "CF303RegularizedNormalActionFiniteField" -> normalActionPath|>,
    "TimingsSeconds" -> <|
      "ConnectionJetImport" -> N[connectionImportSeconds],
      "ConnectionJetConstruction" ->
        N[connectionJet["TotalSeconds"]],
      "Total" -> N[AbsoluteTime[] - started]|>|>
];

If[! DirectoryQ[DirectoryName[outputPath]],
  CreateDirectory[DirectoryName[outputPath],
    CreateIntermediateDirectories -> True]];
Put[result, outputPath];
Print["CF303 TANGENTIAL BRIDGE status=", result["Status"],
  " sourceRhoValuation=",
  Lookup[result, "TargetFromSourceRhoValuation", Missing[]],
  " targetRhoValuation=",
  Lookup[result, "TargetFromTargetRhoValuation", Missing[]],
  " regular=", Lookup[result, "RegularResidualComparisonCount", 0],
  " logarithmic=", Lookup[result, "LogarithmicResidualComparisonCount", 0],
  " frobeniusLog=",
  Lookup[result, "FrobeniusLogResidualComparisonCount", 0],
  " seconds=", result["TimingsSeconds", "Total"],
  " output=", outputPath];
If[result["Status"] ===
    "CF303ExplicitInheritedModeTangentialBridgeFiniteFieldMethodValidatedPendingV2LowerFamilyInputs",
  Quit[0], Quit[2]];
