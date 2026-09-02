#!/usr/bin/env wolframscript
(* Measures the Laurent-extraction stage of the observable transport on a
   family record: the epsilon-jet route on the full transformation matrix,
   and SeriesCoefficient on a random sample of nonzero entries (from which
   the former route's full cost is estimated), plus an exact agreement
   check on that sample.  Usage:
   benchmark_laurent_jet.wls <record.wl> <low> <high> [sampleCount=40] *)
$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
args = Rest[$ScriptCommandLine];
If[Length[args] < 3, Print["usage: benchmark_laurent_jet.wls <record.wl> <low> <high> [sampleCount]"]; Exit[64]];
record = Get[args[[1]]]; low = ToExpression[args[[2]]]; high = ToExpression[args[[3]]];
sampleCount = If[Length[args] >= 4, ToExpression[args[[4]]], 40];
canonicalize = If[Length[args] >= 5, ToExpression[args[[5]]], True];
FeynFacet`Private`$observableTransportLaurentCanonicalize = canonicalize;
Print["jet canonicalize: ", canonicalize];
eps = record["Regulator"]; matrix = Normal[record["TTotal"]];
nonzero = Position[matrix, e_ /; ! TrueQ[e === 0], {2}, Heads -> False];
Print["record ", record["Family"], " dimension ", Length[matrix], " nonzero entries ", Length[nonzero], " orders ", {low, high}];
{jetSeconds, jet} = AbsoluteTiming[Block[{FeynFacet`Private`$observableTransportLaurentMethod = "Jet", FeynFacet`Private`$observableTransportLaurentCanonicalize = canonicalize},
  FeynFacet`Private`observableTransportLaurentRows[matrix, eps, {low, high}, Range[Length[matrix]]]]];
Print["jet route, full matrix: ", Round[jetSeconds, 0.01], " s"];
SeedRandom[2026];
sample = RandomSample[nonzero, Min[sampleCount, Length[nonzero]]];
zeroQ[e_] := TrueQ[RootReduce[Together[e]] === 0];
seriesSeconds = 0.; disagreements = 0;
Do[
  {t, coefficients} = AbsoluteTiming[Table[
    FeynFacet`Private`observableTransportCancel[SeriesCoefficient[matrix[[pos[[1]], pos[[2]]]], {eps, 0, order}]],
    {order, low, high}]];
  seriesSeconds += t;
  If[! And @@ Table[zeroQ[jet[order][[pos[[1]], pos[[2]]]] - coefficients[[order - low + 1]]], {order, low, high}],
    disagreements++; Print["  DISAGREEMENT at entry ", pos]],
  {pos, sample}];
Print["SeriesCoefficient route on ", Length[sample], " sampled entries: ", Round[seriesSeconds, 0.01],
  " s -> estimated full matrix ", Round[seriesSeconds Length[nonzero]/Length[sample], 1], " s"];
Print["agreement on the sample: ", Length[sample] - disagreements, "/", Length[sample]];
Print[InputForm[<|"Family" -> record["Family"], "Orders" -> {low, high}, "NonzeroEntries" -> Length[nonzero],
  "JetSeconds" -> jetSeconds, "SeriesSampleSeconds" -> seriesSeconds, "SampleCount" -> Length[sample],
  "EstimatedSeriesSeconds" -> seriesSeconds Length[nonzero]/Length[sample], "Disagreements" -> disagreements|>]];
Exit[If[disagreements === 0, 0, 1]];
