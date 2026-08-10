root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
SetDirectory[root];
$HistoryLength = 0;

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

basis = {nb, n, xhat, yhat};
validBasis = FeynFacet`BuildGlobalBasis[basis] === basis;
validVector = FeynFacet`Build4Vec[{a, b, c, d}, basis] ===
  a nb + b n + c xhat + d yhat;

invalidVectorLength = Quiet[
  FeynFacet`Build4Vec[{a}, {n, nb}]
] === $Failed;
invalidVectorType = Quiet[
  FeynFacet`Build4Vec[a, basis]
] === $Failed;
invalidBasisType = Quiet[
  FeynFacet`BuildGlobalBasis[nb]
] === $Failed;
invalidLoopMomenta = Quiet[
  FeynFacet`CommonFactorSafe[2 x + 2 y, k]
] === $Failed;

checks = <|
  "ValidBasisAccepted" -> validBasis,
  "ValidVectorAccepted" -> validVector,
  "MismatchedVectorLengthsRejected" -> invalidVectorLength,
  "NonlistCoordinatesRejected" -> invalidVectorType,
  "NonlistBasisRejected" -> invalidBasisType,
  "NonlistLoopMomentaRejected" -> invalidLoopMomenta
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
