$HistoryLength = 0;
root = "/home/maxzhang/FACET";

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
package = Replace[
  Environment["FACET_BENCHMARK_PACKAGE"],
  $Failed | "" :> FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]
];
package = ExpandFileName[package];
Get[package];
FeynCalc`FCSetDiracGammaScheme["BMHV"];
Global`GlobalBasis = FeynFacet`BuildGlobalBasis[{nb, n, xhat, yhat}];
FeynArts`$FAVerbose = 0;

setup = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
setup["ForwardAmplitudes", "SelectedIndex"] = 1;
setup["ConjugateAmplitudes", "SelectedIndex"] = 2;

{seconds, result} = AbsoluteTiming[
  FeynFacet`CollinearFactorizePreIBP[setup]
];
If[! MatchQ[result, {_, _, _, _, _}], Exit[1]];

Print @ InputForm @ <|
  "Package" -> package,
  "Seconds" -> seconds,
  "IntegrandBytes" -> ByteCount[result[[4]]],
  "GLITerms" -> Length @ DeleteDuplicates @ Cases[
    result[[4]],
    _FeynCalc`GLI,
    Infinity
  ],
  "Topologies" -> Length[result[[5]]]
|>;
Exit[0];
