#!/usr/bin/env wolframscript
(* WHERE the 2710.9 s of a first-call prepare on the real CF300 (12,9)
   actually goes.

   Measured 15:58 on this descriptor: prepare 2710.9 s, compile 91.3 s.
   That 30:1 split says the duplicated E/C/BBar decomposition the
   early-core change removes CANNOT be the dominant term -- the whole
   compile, which decomposes E and C and compiles every channel, is 91 s.
   So prepare is spending its time somewhere else, and this run attributes
   it stage by stage, in prepare's own order, with the stage log on.

   Nothing here changes anything; every call is the one prepare makes. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
snap = "/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/opt/snap";
out = "/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/opt/cf300_attribute_result.wl";
$t0 = AbsoluteTime[];
say[a___] := WriteString["stdout",
  ToString[Round[AbsoluteTime[] - $t0, 0.01]], "s | ",
  StringJoin[If[StringQ[#], #, ToString[#, InputForm]] & /@ {a}], "\n"];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
mq[n_String] := Symbol["FeynFacet`Private`" <> n];

FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
   "Results", "UU_08_10_canonical", "TransportFamilyCharts.wl"}]];
chart = FeynFacet`TransportFamilyChart["CF300"];
record = FeynFacet`FamilyArtifactRead[
   FileNameJoin[{snap, "CF300", "sector_CF300_standard",
     "CF300_12_9_input.wl"}], "Global`"];
variables = record["Variables"]; regulator = record["Regulator"];
allRoots = mq["transportChartCurrentRoots"][chart, variables];
census = mq["multiquadraticStripRootCensus"][record["Strip"], allRoots];
order = mq["multiquadraticStripRootOrder"][chart, variables,
   census["RootIndices"], regulator];
roots = order["Roots"];
strip = record["Strip"];
bbar = strip[[3]];
say["BBar ", Dimensions[bbar], " leaves ", LeafCount[bbar],
  "; E leaves ", LeafCount[strip[[1]]], "; C leaves ", LeafCount[strip[[2]]],
  "; rank ", Length[roots]];

clear = mq["multiquadraticStripCompileCacheClear"];

(* 1. the forcing channel decomposition, interned -- what BOTH routes do *)
clear[];
{decomposeSeconds, channels} = AbsoluteTiming[
  mq["multiquadraticStripDecomposeForcing"][bbar, roots]];
say["1 forcing channel decomposition (interned): ",
  Round[decomposeSeconds, 0.1], " s"];

(* 2. the same through the sealed compile core: E and C as well *)
clear[];
{coreSeconds, core} = AbsoluteTiming[
  mq["multiquadraticStripCompileCoreRecord"][strip, roots, variables,
    regulator, Missing["NotSupplied"], {"cf300-attribution"}, True]];
say["2 sealed compile core (E + C + BBar, decomposed AND compiled): ",
  Round[coreSeconds, 0.1], " s, ok ", AssociationQ[core]];
sameChannels = AssociationQ[core] &&
  SameQ[channels, Lookup[Lookup[core, "BBar", <||>], "Channels", $Failed]];
say["  core BBar channels SameQ the independent decomposition: ",
  sameChannels];

(* 3. the gauge denominator, built FROM those channels *)
{denominatorSeconds, gaugeDenominator} = AbsoluteTiming[
  mq["multiquadraticRationalGaugeDenominator"][channels, variables]];
say["3 rational gauge denominator from the channels: ",
  Round[denominatorSeconds, 0.1], " s, degrees ",
  Exponent[gaugeDenominator, #] & /@ variables];

(* 4. the ABI payload: the whole-strip canonical InputForm *)
{payloadSeconds, canonical} = AbsoluteTiming[
  mq["multiquadraticStripCoreCanonicalData"][record, roots, variables,
    regulator]];
say["4 ABI canonical data (whole-strip InputForm + root texts): ",
  Round[payloadSeconds, 0.1], " s, equation text ",
  StringLength[canonical["EquationCanonical"]], " chars"];

total = decomposeSeconds + denominatorSeconds + payloadSeconds;
say["ATTRIBUTION of the measured 2710.9 s prepare: decomposition ",
  Round[decomposeSeconds, 0.1], " s + gauge denominator ",
  Round[denominatorSeconds, 0.1], " s + ABI canonical ",
  Round[payloadSeconds, 0.1], " s = ", Round[total, 0.1],
  " s of the three stages measured here"];

Put[<|"Schema" -> "CF300PrepareAttributionV1",
  "Descriptor" -> {record["Family"], record["Sector"], record["LowerSector"]},
  "BBarDimensions" -> Dimensions[bbar],
  "BBarLeafCount" -> LeafCount[bbar],
  "ELeafCount" -> LeafCount[strip[[1]]],
  "CLeafCount" -> LeafCount[strip[[2]]],
  "RootRank" -> Length[roots],
  "ForcingDecompositionSeconds" -> decomposeSeconds,
  "SealedCoreSeconds" -> coreSeconds,
  "CoreChannelsSameQ" -> sameChannels,
  "GaugeDenominatorSeconds" -> denominatorSeconds,
  "ABICanonicalSeconds" -> payloadSeconds,
  "MeasuredStageTotalSeconds" -> total,
  "ReferencePrepareSeconds" -> 2710.9,
  "ReferenceCompileSeconds" -> 91.3|>, out];
say["written ", out];
Exit[0];
