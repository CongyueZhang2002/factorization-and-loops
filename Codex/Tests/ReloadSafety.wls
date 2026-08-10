$LoadFeynArts = True;
root = "/home/maxzhang/FACET";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
package = FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}];
Get[package];

phiExpected = 1/2 (
  FeynFacet`f1[x] FeynCalc`GS[n] +
  lambda FeynFacet`g1L[x] FeynCalc`GA[5] . FeynCalc`GS[n] +
  FeynFacet`h1[x] FeynFacet`Private`iSigmaSlash[n, ST] .
    FeynCalc`GA[5]
);
deltaExpected = 1/2 (
  FeynFacet`D1[z] FeynCalc`GS[n] +
  lambda FeynFacet`G1L[z] FeynCalc`GA[5] . FeynCalc`GS[n] +
  FeynFacet`H1[z] FeynFacet`Private`iSigmaSlash[n, ST] .
    FeynCalc`GA[5]
);
phibExpected = phiExpected -
  lambda FeynFacet`g1L[x] FeynCalc`GA[5] . FeynCalc`GS[n];
deltabExpected = deltaExpected -
  lambda FeynFacet`G1L[z] FeynCalc`GA[5] . FeynCalc`GS[n];

public = {
  FeynFacet`CollinearFactorize,
  FeynFacet`CollinearFactorizePreIBP,
  FeynFacet`PartialFraction,
  FeynFacet`BuildTopologies,
  FeynFacet`TopologyEquivalence,
  FeynFacet`DimensionalShift,
  FeynFacet`KiraReduction,
  FeynFacet`CoefficientSimplification
};
checks = <|
  "PublicDefinitionsRetained" -> AllTrue[public, Length[DownValues[#]] > 0 &],
  "DistributionDefinitionsRetained" -> And[
    Length[DownValues[FeynFacet`\[CapitalPhi]]] > 0,
    Length[DownValues[FeynFacet`\[CapitalDelta]]] > 0,
    FreeQ[
      FeynFacet`\[CapitalPhi][x, P, lambda, ST, n],
      FeynFacet`Private`iSigmaSlash
    ]
  ],
  "DistributionConstructorEquivalent" -> And[
    SameQ[
      Expand[FeynFacet`\[CapitalPhi][x, P, lambda, ST, n]],
      Expand[phiExpected]
    ],
    SameQ[
      Expand[FeynFacet`\[CapitalDelta][z, P, lambda, ST, n]],
      Expand[deltaExpected]
    ],
    SameQ[
      Expand[FeynFacet`\[CapitalPhi]b[x, P, lambda, ST, n]],
      Expand[phibExpected]
    ],
    SameQ[
      Expand[FeynFacet`\[CapitalDelta]b[z, P, lambda, ST, n]],
      Expand[deltabExpected]
    ]
  ],
  "PrivateNormalizerRetained" ->
    Length[DownValues[FeynFacet`Private`exactCoefficientNormalize]] > 0
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
