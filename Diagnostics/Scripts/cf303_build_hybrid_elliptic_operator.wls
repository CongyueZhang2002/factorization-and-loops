#!/usr/bin/env wolframscript

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
runtime = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues";
providerFile = FileNameJoin[{runtime,
  "cf303_selected21_precompiled_gpl_provider_cheap_basis.wl"}];
scheduleFile = repo <> "/ppHX_NNLO_DoubleReal/Results/" <>
  "UU_08_10_canonical/FamilyEpsFormsSolving/" <>
  "triple_root_2026-08-28_codex_clean/CF303/Transport/" <>
  "cf303_u3_formal_transport_artifact.wl";
layerFiles = <|
  15 -> FileNameJoin[{runtime, "cf303_block15_lazy_chen_operator.wl"}],
  17 -> FileNameJoin[{runtime, "cf303_block17_pure_elliptic_operator.wl"}],
  21 -> FileNameJoin[{runtime, "cf303_block21_pure_elliptic_operator.wl"}]|>;
requestedText = Environment["CF303_HYBRID_LAYERS"];
requestedLayers = If[StringQ[requestedText] && requestedText =!= "",
  ToExpression /@ StringSplit[requestedText, ","], {15, 17}];
If[! MatchQ[requestedLayers, {15, 17} | {15, 17, 21}],
  Print["REFUSED: layers must be 15,17 or 15,17,21"]; Exit[2]];
outputFile = FileNameJoin[{runtime,
  "cf303_hybrid_elliptic_operator_" <>
    StringRiffle[ToString /@ requestedLayers, "_"] <> ".wl"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
provider = Get[providerFile];
scheduleArtifact = Get[scheduleFile];
layers = AssociationMap[Get[layerFiles[#]] &, requestedLayers];
If[provider["Status"] =!= "AcceptedNativePathDLogProviderV1" ||
    AnyTrue[Values[layers],
      ! StringEndsQ[ToString[# ["Status"]], "AcceptedV1"] &],
  Print["REFUSED: one accepted provider is missing"]; Exit[3]];

scheduleAssociation[value_] := If[AssociationQ[value], value,
  Association[Rule @@@ Partition[value, 2]]];
layerGenerators[layer_] := If[KeyExistsQ[layer, "DiagonalCompressed"],
  layer["DiagonalCompressed", "ConstantGeneratorMatrices"],
  layer["ConstantGeneratorMatrices"]];
layerCompositeKernels[layer_] :=
  If[KeyExistsQ[layer, "DiagonalCompressed"],
    layer["DiagonalCompressed", "ConstantCompositeKernels"],
    layer["ConstantCompositeKernels"]];

selectedBlocks = provider["SelectedBlocks"];
dimensions = provider["Dimensions"];
cuts = FoldList[Plus, 0, dimensions];
ranges = Table[Range[cuts[[i]] + 1, cuts[[i + 1]]],
  {i, Length[dimensions]}];
n = Total[dimensions];
originalRows = provider["OriginalRows"];
masterLocation = <||>;
Do[
  sourceBlock = First@FirstPosition[ranges,
    rows_ /; MemberQ[rows, position]];
  masterLocation[originalRows[[position]]] =
    {sourceBlock, First@FirstPosition[ranges[[sourceBlock]], position],
      position},
  {position, n}];

(* Map the rational tau-poles to the common direct-z path. *)
letters = ({"GPLPole",
      1/2 + (uFinal - 1/2) (# /. uTarget -> uFinal)} &) /@
  provider["Letters"];
compiledCouplings = Association[provider["Couplings"]];
low = scheduleArtifact["Recurrence", "Low"][[selectedBlocks]];
top = scheduleArtifact["Recurrence", "Top"][[selectedBlocks]];
kmin = scheduleArtifact["Recurrence", "KMin"][[selectedBlocks]];
constantTop =
  scheduleArtifact["Recurrence", "ConstantTop"][[selectedBlocks]];
layerSummaries = {};
layerGlobalRanges = <||>;

Do[
  layer = layers[layerNumber];
  layerRows = layer["Rows"];
  layerDimension = Length[layerRows];
  newBlock = Length[dimensions] + 1;
  newRange = Range[n + 1, n + layerDimension];
  ranges = Append[ranges, newRange];
  dimensions = Append[dimensions, layerDimension];
  layerGlobalRanges[layerNumber] = newRange;
  Do[masterLocation[layerRows[[local]]] =
      {newBlock, local, newRange[[local]]},
    {local, layerDimension}];
  n += layerDimension;

  originalLetterOffset = Length[letters];
  layerLetters = layer["Letters"] /. u -> z;
  letters = Join[letters, layerLetters];
  generators = layerGenerators[layer];
  generatorOffset = Length[letters];
  generatorLabels = Table[
    CompositeEllipticLetter[layerNumber, generator],
    {generator, Length[generators]}];
  letters = Join[letters, generatorLabels];

  offDiagonal = Select[layer["ResidueRecords"],
    ! MemberQ[layer["DiagonalColumnPositions"], #[[3]]] &];
  offDiagonalGroups = GroupBy[offDiagonal,
    Function[record, Module[{master, location},
      master = layer["Columns"][[record[[3]]]];
      location = masterLocation[master];
      {location[[1]], record[[1]]}]]];
  KeyValueMap[
    Function[{sourceAndLetter, records},
      Module[{sourceBlock, originalLetter, pair, byOrder, byLetter,
        rules, matrix},
        {sourceBlock, originalLetter} = sourceAndLetter;
        pair = {newBlock, sourceBlock};
        rules = Map[Function[record, Module[{master, location},
            master = layer["Columns"][[record[[3]]]];
            location = masterLocation[master];
            {record[[2]], location[[2]]} -> record[[4]]]], records];
        matrix = SparseArray[rules,
          {layerDimension, dimensions[[sourceBlock]]}];
        byOrder = Lookup[compiledCouplings, Key[pair], <||>];
        byLetter = Lookup[byOrder, 1, <||>];
        byLetter[originalLetterOffset + originalLetter] = matrix;
        byOrder[1] = byLetter;
        compiledCouplings[pair] = byOrder]],
    offDiagonalGroups];
  diagonalByLetter = Association@Table[
    generatorOffset + generator -> SparseArray[generators[[generator]]],
    {generator, Length[generators]}];
  compiledCouplings[{newBlock, newBlock}] = <|1 -> diagonalByLetter|>;

  layerSchedule = scheduleAssociation[layer["Schedule"]];
  low = Append[low, layerSchedule["Low"]];
  top = Append[top, layerSchedule["Top"]];
  kmin = Append[kmin, layerSchedule["KMin"]];
  constantTop = Append[constantTop, layerSchedule["ConstantTop"]];
  originalRows = Join[originalRows, layerRows];
  AppendTo[layerSummaries, <|"Block" -> layerNumber,
    "Rows" -> layerRows, "Letters" -> Length[layerLetters],
    "HomogeneousGenerators" -> Length[generators],
    "CompositeKernelDefinitions" ->
      (layerCompositeKernels[layer] /. u -> z),
    "ProviderFile" -> layerFiles[layerNumber]|>],
  {layerNumber, requestedLayers}];

(* The final block-25 incoming forms have epsilon valuation -2.  Therefore a
   complete target coefficient through order 2 can use a source coefficient,
   including its empty-word boundary datum, through order 2-(-2)=4.  Raising
   these lazy bounds adds selectors only; it does not enumerate words. *)
finalTargetTop = 2;
minimumIncomingOrder = -2;
requiredSourceTop = finalTargetTop - minimumIncomingOrder;
top = Max[#, requiredSourceTop] & /@ top;
constantTop = Max[#, requiredSourceTop] & /@ constantTop;

assembly = <|"Family" -> "CF303HybridElliptic",
  "Blocks" -> ranges, "Ranges" -> ranges, "N" -> n|>;
schedule = <|"Low" -> low, "Top" -> top|>;
{buildSeconds, operator} = AbsoluteTiming[
  FeynFacet`Private`masterTransportCanonicalChenOperator[
    assembly, compiledCouplings, letters, schedule, kmin, constantTop,
    <|"Status" -> "CF303HybridMixedAlphabetV1",
      "RationalProvider" -> providerFile,
      "LayerProviders" -> layerFiles /@ requestedLayers|>]];

(* The empty word at each layer's own boundary order is the only construction
   probe: all differential identities were already certified in the layer
   reductions, so no second symbolic recurrence is built here. *)
boundaryProbes = AssociationMap[Function[layerNumber,
  Module[{blockIndex, order, rows, coefficient},
    blockIndex = First@FirstPosition[requestedLayers, layerNumber] +
      Length[selectedBlocks];
    order = kmin[[blockIndex]];
    rows = layerGlobalRanges[layerNumber];
    coefficient =
      FeynFacet`Private`masterTransportCanonicalChenWordCoefficient[
        operator, {}, order, order, rows];
    <|"Order" -> order, "Dimensions" -> Dimensions[coefficient],
      "Nonzero" ->
        FeynFacet`Private`masterTransportCWNonzeroSparseQ[coefficient]|>]],
  requestedLayers];
artifact = <|
  "Status" -> If[
    operator["Status"] === "CanonicalGPLChenOperatorV1" &&
      AllTrue[Values[boundaryProbes], TrueQ[# ["Nonzero"]] &],
    "CF303HybridEllipticOperatorAcceptedV1",
    "CF303HybridEllipticOperatorFailedV1"],
  "IncludedExtensionBlocks" -> requestedLayers,
  "Operator" -> operator,
  "OriginalRows" -> originalRows,
  "MasterCount" -> n,
  "RationalMasterCount" -> Total[provider["Dimensions"]],
  "ExtensionMasterCount" -> n - Total[provider["Dimensions"]],
  "Curve" -> (layers[15]["Curve"] /. u -> z),
  "RequiredSourceTop" -> requiredSourceTop,
  "RequiredSourceTopDerivation" -> <|
    "FinalTargetTop" -> finalTargetTop,
    "MinimumIncomingOrder" -> minimumIncomingOrder|>,
  "Path" -> <|"Variable" -> z, "Base" -> 1/2,
    "Endpoint" -> uFinal|>,
  "LayerSummaries" -> layerSummaries,
  "BoundaryProbes" -> boundaryProbes,
  "BuildSeconds" -> buildSeconds|>;
Put[artifact, outputFile];
Export[outputFile, StringReplace[ReadString[outputFile],
  RegularExpression["(?m)[ \\t]+$"] -> ""], "Text"];
Print[InputForm[KeyDrop[artifact, {"Operator", "LayerSummaries"}]]];
Print["OUTPUT ", outputFile];
Exit[If[artifact["Status"] ===
  "CF303HybridEllipticOperatorAcceptedV1", 0, 2]];
