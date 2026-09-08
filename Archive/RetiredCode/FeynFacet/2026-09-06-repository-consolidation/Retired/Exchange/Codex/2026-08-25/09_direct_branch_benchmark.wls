repo = "/home/maxzhang/factorization-and-loops";
fixture = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "FrozenTestFixtures_2026-08-25", "cf300_frozen_strip_12_9_input.wl"}];
channelFixture = FileNameJoin[{DirectoryName[fixture],
  "cf300_frozen_channel_forcing.wl"}];

Get[FileNameJoin[{repo, "FeynFacet", "Private", "MultiquadraticAlgebra.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{repo, "FeynFacet", "Private", "TransportCharts.wl"}]];
End[];
Get[FileNameJoin[{repo, "FeynFacet", "Private", "MultiquadraticStripSolve.wl"}]];
record = Get[fixture];
frozenChannels = Get[channelFixture];
{xvar, yvar} = record["Variables"];
epsvar = record["Regulator"];
bbar = record["Strip"][[3]];

radicalBases = DeleteDuplicates[Cases[bbar,
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :> base,
  Infinity]];
If[Length[radicalBases] =!= 2,
  Print[<|"Status" -> "UnexpectedRootCount", "RadicalBases" -> radicalBases|>];
  Quit[2]];
rootExpressions = Sqrt /@ radicalBases;
roots = <|"Root" -> Sqrt[#], "RootSquare" -> #|> & /@ radicalBases;

prime = 10007;
epsValue = 5;
modNumber[value_] := Module[{q = Together[value], den},
  If[! MatchQ[q, _Integer | _Rational], Return[$Failed]];
  den = Mod[Denominator[q], prime];
  If[den === 0, Return[$Failed]];
  Mod[Mod[Numerator[q], prime] PowerMod[den, -1, prime], prime]
];

point = SelectFirst[Tuples[Range[2, 80], 2], Function[pt,
  Module[{dv = modNumber[# /. Thread[{xvar, yvar} -> pt]] & /@ radicalBases},
    FreeQ[dv, $Failed | 0] && AllTrue[dv, JacobiSymbol[#, prime] === 1 &]
  ]], Missing["NoSplitPoint"]];

If[MissingQ[point], Print[<|"Status" -> "NoSplitPoint"|>]; Quit[2]];
deltaValues = modNumber[# /. Thread[{xvar, yvar} -> point]] & /@ radicalBases;
rootValues = PowerMod[deltaValues, (prime + 1)/4, prime];

signsFor[mask_] := Table[If[BitGet[mask, k] === 0, 1, -1], {k, 0, 1}];
directImage[expression_, mask_] := Module[{branched},
  branched = FeynFacet`Private`transportChartApplyRootBranches[
    expression, roots, Mod[signsFor[mask] rootValues, prime]];
  modNumber[branched /. Thread[{xvar, yvar} -> point] /. epsvar -> epsValue]
];

firstEntry = bbar[[1, 1, 1]];
debugBranched = FeynFacet`Private`transportChartApplyRootBranches[
  firstEntry, roots, rootValues];
debugNumeric = debugBranched /. Thread[{xvar, yvar} -> point] /.
  epsvar -> epsValue;
debugNonIntegerPowers = DeleteDuplicates[Cases[debugNumeric,
  Power[base_, exponent_Rational /; ! IntegerQ[exponent]] :>
    HoldForm[Power[base, exponent]], Infinity]];
{decomposeSeconds, firstChannels} = AbsoluteTiming[
  FeynFacet`Private`multiquadraticFieldDecompose[firstEntry, roots]];

channelImages = modNumber[# /. Thread[{xvar, yvar} -> point] /.
      epsvar -> epsValue] & /@ firstChannels;
maskFactors = Table[Product[
    If[BitGet[grade, k - 1] === 1, rootValues[[k]], 1], {k, 2}],
  {grade, 0, 3}];
channelBranchImages = Table[Mod[Sum[
  channelImages[[grade + 1]] maskFactors[[grade + 1]]
      FeynFacet`Private`multiquadraticStripCharacter[mask, grade, 2],
    {grade, 0, 3}], prime], {mask, 0, 3}];

{firstDirectSeconds, firstDirectImages} = AbsoluteTiming[
  directImage[firstEntry, #] & /@ Range[0, 3]];

allDirect = TimeConstrained[
  AbsoluteTiming[Table[Map[directImage[#, mask] &, bbar, {3}],
    {mask, 0, 3}]],
  60, {60., "TimedOut"}];

frozenChannelImages = Map[modNumber[# /. Thread[{xvar, yvar} -> point] /.
      epsvar -> epsValue] &, frozenChannels, {4}];
frozenBranchImages = Table[Map[Function[channelVector,
    Mod[Sum[channelVector[[grade + 1]] maskFactors[[grade + 1]]
      FeynFacet`Private`multiquadraticStripCharacter[mask, grade, 2],
      {grade, 0, 3}], prime]], frozenChannelImages, {3}], {mask, 0, 3}];

Print[<|
  "Status" -> "DirectBranchBenchmarkV1",
  "Fixture" -> fixture,
  "Prime" -> prime,
  "Point" -> point,
  "DeltaValues" -> deltaValues,
  "RootValues" -> rootValues,
  "EntryCount" -> Times @@ Dimensions[bbar],
  "BranchCount" -> 4,
  "FirstEntryLeafCount" -> LeafCount[firstEntry],
  "DebugResidualSymbols" -> DeleteDuplicates[Cases[debugNumeric, _Symbol, Infinity]],
  "DebugNonIntegerPowers" -> debugNonIntegerPowers,
  "FirstEntryExactDecomposeSeconds" -> decomposeSeconds,
  "FirstEntryFourDirectBranchSeconds" -> firstDirectSeconds,
  "FirstEntryDirectImages" -> firstDirectImages,
  "FirstEntryChannelProjectionImages" -> channelBranchImages,
  "FirstEntryChannelImages" -> channelImages,
  "FirstEntryDirectEqualsChannelProjection" ->
    TrueQ[firstDirectImages === channelBranchImages],
  "AllEightEntriesFourBranchesSeconds" -> First[allDirect],
  "AllEightEntriesFourBranchesCompleted" -> (Last[allDirect] =!= "TimedOut"),
  "AllEightEntriesDirectEqualsFrozenChannels" ->
    TrueQ[Last[allDirect] === frozenBranchImages]
|>];
