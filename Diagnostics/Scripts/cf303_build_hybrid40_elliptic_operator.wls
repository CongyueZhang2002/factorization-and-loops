#!/usr/bin/env wolframscript

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
providerFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_selected21_precompiled_gpl_provider_cheap_basis.wl";
block15File = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_block15_lazy_chen_operator.wl";
scheduleFile = repo <> "/ppHX_NNLO_DoubleReal/Results/" <>
  "UU_08_10_canonical/FamilyEpsFormsSolving/" <>
  "triple_root_2026-08-28_codex_clean/CF303/Transport/" <>
  "cf303_u3_formal_transport_artifact.wl";
outputFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_hybrid40_elliptic_operator.wl";

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
provider = Get[providerFile];
block15 = Get[block15File];
scheduleArtifact = Get[scheduleFile];
If[provider["Status"] =!= "AcceptedNativePathDLogProviderV1" ||
    block15["Status"] =!= "CF303Block15LazyChenOperatorAcceptedV1",
  Print["REFUSED: one accepted provider is missing"]; Exit[2]];

selectedBlocks = provider["SelectedBlocks"];
dimensions = provider["Dimensions"];
cuts = FoldList[Plus, 0, dimensions];
sourceRanges = Table[Range[cuts[[i]] + 1, cuts[[i + 1]]],
  {i, Length[dimensions]}];
sourceN = Total[dimensions];
newBlock = Length[dimensions] + 1;
ranges = Append[sourceRanges, Range[sourceN + 1, sourceN + 3]];
assembly = <|"Family" -> "CF303Hybrid40Elliptic",
  "Blocks" -> ranges, "Ranges" -> ranges, "N" -> sourceN + 3|>;

(* Put the already solved rational words and the quartic words on the same
   direct-u path.  A pole a in tau, u=1/2+tau (uFinal-1/2), becomes the
   direct-u pole 1/2+(uFinal-1/2)a. *)
sourceLetters = ({"GPLPole",
      1/2 + (uFinal - 1/2) (# /. uTarget -> uFinal)} &) /@
  provider["Letters"];
blockLetters = block15["Letters"] /. u -> z;
generatorCount = block15["DiagonalCompressed",
  "PreferredGeneratorCount"];
generatorLetters = Table[CompositeEllipticLetter[15, index],
  {index, generatorCount}];
letters = Join[sourceLetters, blockLetters, generatorLetters];
sourceLetterCount = Length[sourceLetters];
blockLetterCount = Length[blockLetters];

compiledCouplings = Association[provider["Couplings"]];
originalRows = provider["OriginalRows"];
masterPosition = AssociationThread[originalRows, Range[sourceN]];
blockForPosition[position_] := First@FirstPosition[sourceRanges,
  rows_ /; MemberQ[rows, position]];
localPosition[block_, position_] :=
  First@FirstPosition[sourceRanges[[block]], position];

offDiagonal = Select[block15["ResidueRecords"],
  ! MemberQ[block15["DiagonalColumnPositions"], #[[3]]] &];
offDiagonalGroups = GroupBy[offDiagonal,
  Function[record, Module[{master, position, sourceBlock},
    master = block15["Columns"][[record[[3]]]];
    position = masterPosition[master];
    sourceBlock = blockForPosition[position];
    {sourceBlock, record[[1]]}]]];
KeyValueMap[
  Function[{sourceAndLetter, records},
    Module[{sourceBlock, originalLetter, pair, byOrder, byLetter,
      rules, matrix},
      {sourceBlock, originalLetter} = sourceAndLetter;
      pair = {newBlock, sourceBlock};
      rules = Map[Function[record, Module[{master, position},
          master = block15["Columns"][[record[[3]]]];
          position = masterPosition[master];
          {record[[2]], localPosition[sourceBlock, position]} ->
            record[[4]]]], records];
      matrix = SparseArray[rules, {3, dimensions[[sourceBlock]]}];
      byOrder = Lookup[compiledCouplings, Key[pair], <||>];
      byLetter = Lookup[byOrder, 1, <||>];
      byLetter[sourceLetterCount + originalLetter] = matrix;
      byOrder[1] = byLetter;
      compiledCouplings[pair] = byOrder]],
  offDiagonalGroups];

diagonalByLetter = Association@Table[
  sourceLetterCount + blockLetterCount + generator ->
    SparseArray[block15["DiagonalCompressed",
      "ConstantGeneratorMatrices"][[generator]]],
  {generator, generatorCount}];
compiledCouplings[{newBlock, newBlock}] = <|1 -> diagonalByLetter|>;

schedule = <|
  "Low" -> Append[
    scheduleArtifact["Recurrence", "Low"][[selectedBlocks]], -1],
  "Top" -> Append[
    scheduleArtifact["Recurrence", "Top"][[selectedBlocks]], 4]|>;
kmin = Append[
  scheduleArtifact["Recurrence", "KMin"][[selectedBlocks]], -1];
constantTop = Append[
  scheduleArtifact["Recurrence", "ConstantTop"][[selectedBlocks]], 2];

{buildSeconds, operator} = AbsoluteTiming[
  FeynFacet`Private`masterTransportCanonicalChenOperator[
    assembly, compiledCouplings, letters, schedule, kmin, constantTop,
    <|"Status" -> "CF303Hybrid40MixedAlphabetV1",
      "RationalProvider" -> providerFile,
      "Block15Provider" -> block15File|>]];
probe = If[operator["Status"] === "CanonicalGPLChenOperatorV1",
  FeynFacet`Private`masterTransportCanonicalChenCoefficient[
    operator, -1, "Rows" -> Range[sourceN + 1, sourceN + 3],
    "MaxTerms" -> 1000], None];
artifact = <|
  "Status" -> If[
    operator["Status"] === "CanonicalGPLChenOperatorV1" &&
      AssociationQ[probe] && probe["Status"] === "OK",
    "CF303Hybrid40EllipticOperatorAcceptedV1",
    "CF303Hybrid40EllipticOperatorFailedV1"],
  "Operator" -> operator,
  "OriginalRows" -> Join[originalRows, {23, 24, 25}],
  "RationalMasterCount" -> sourceN,
  "EllipticMasterCount" -> 3,
  "Alphabet" -> <|
    "RationalGPL" -> sourceLetterCount,
    "Block15EntryForms" -> blockLetterCount,
    "Block15HomogeneousCompositeForms" -> generatorCount|>,
  "Curve" -> (block15["Curve"] /. u -> z),
  "Path" -> <|"Variable" -> z, "Base" -> 1/2,
    "Endpoint" -> uFinal|>,
  "CompositeKernelDefinitions" ->
    (block15["DiagonalCompressed", "ConstantCompositeKernels"] /.
      u -> z),
  "Block15ColumnMap" -> block15["Columns"],
  "BuildSeconds" -> buildSeconds,
  "Probe" -> If[AssociationQ[probe], KeyDrop[probe, "Terms"], probe]|>;
Put[artifact, outputFile];
Export[outputFile, StringReplace[ReadString[outputFile],
  RegularExpression["(?m)[ \\t]+$"] -> ""], "Text"];
Print[InputForm[KeyDrop[artifact, {"Operator",
  "CompositeKernelDefinitions"}]]];
Print["OUTPUT ", outputFile];
Exit[If[artifact["Status"] ===
  "CF303Hybrid40EllipticOperatorAcceptedV1", 0, 2]];
