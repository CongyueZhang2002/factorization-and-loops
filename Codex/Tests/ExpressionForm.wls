root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
$HistoryLength = 0;
$LoadFeynArts = False;
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

internal = {
  FeynCalc`Pair[
    FeynCalc`Momentum[ka, D],
    FeynCalc`Momentum[n, D]
  ],
  FeynCalc`Pair[
    FeynCalc`Momentum[kb],
    FeynCalc`Momentum[nb]
  ]
};
external = ToFeynFacetForm[internal];

checks = <|
  "DProductUsesSPD" -> SameQ[external[[1]], FeynCalc`SPD[ka, n]],
  "FourProductUsesSP" -> SameQ[external[[2]], FeynCalc`SP[kb, nb]],
  "NoInternalProducts" -> FeynFacet`Private`feynFacetFormQ[external],
  "Idempotent" -> SameQ[ToFeynFacetForm[external], external],
  "ExactInternalRoundTrip" -> SameQ[
    FeynCalc`FCI[external],
    internal
  ]
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
