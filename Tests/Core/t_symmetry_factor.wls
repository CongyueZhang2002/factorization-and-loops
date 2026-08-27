(* Identical-particle phase-space symmetry factor from the process card.

   Acceptance criteria:
   A. NLO UU (untagged u, g): factor 1.
   B. NNLO UU double-real (untagged d, g, g): factor 1/2.
   C. NNLO ghost card (untagged d, ghost, antighost): factor 1.
   D. Synthetic double pair (untagged q, q, g, g): factor 1/4.
   E. Malformed setups are rejected with $Failed. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

nloCard = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
nnloCard = Get[FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Cards", "UU.wl"
}]];
ghostCard = Get[FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Cards", "UU_Ghost.wl"
}]];

FTTest`FTAssert["NLO UU: factor 1",
  FeynFacet`IdenticalParticleSymmetryFactor[nloCard] === 1];
FTTest`FTAssert["NNLO UU double-real (two identical gluons): factor 1/2",
  FeynFacet`IdenticalParticleSymmetryFactor[nnloCard] === 1/2];
FTTest`FTAssert["NNLO ghost card (distinct ghost-antighost): factor 1",
  FeynFacet`IdenticalParticleSymmetryFactor[ghostCard] === 1];

syntheticCard = <|
  "Partons" -> ({FeynArts`F[3, {1}], FeynArts`F[3, {1}]} -> {
    FeynArts`F[3, {1}],
    FeynArts`F[4, {1}], FeynArts`F[4, {1}],
    FeynArts`V[5], FeynArts`V[5]
  }),
  "HadronMomentum" -> ({Global`Pa, Global`Pb} ->
    {Global`Ph, FeynFacet`NA, FeynFacet`NA, FeynFacet`NA, FeynFacet`NA})
|>;
FTTest`FTAssert["synthetic qq + gg untagged pairs: factor 1/4",
  FeynFacet`IdenticalParticleSymmetryFactor[syntheticCard] === 1/4];

FTTest`FTAssert["tagged identical partner is excluded from the tally",
  FeynFacet`IdenticalParticleSymmetryFactor[<|
    "Partons" -> ({FeynArts`F[3, {1}], FeynArts`F[3, {1}]} ->
      {FeynArts`F[3, {1}], FeynArts`F[3, {1}], FeynArts`V[5]}),
    "HadronMomentum" -> ({Global`Pa, Global`Pb} ->
      {Global`Ph, FeynFacet`NA, FeynFacet`NA})
  |>] === 1];

FTTest`FTAssert["missing keys rejected",
  Quiet[FeynFacet`IdenticalParticleSymmetryFactor[<||>]] === $Failed];
FTTest`FTAssert["length mismatch rejected",
  Quiet[FeynFacet`IdenticalParticleSymmetryFactor[<|
    "Partons" -> ({FeynArts`F[3, {1}]} -> {FeynArts`V[5], FeynArts`V[5]}),
    "HadronMomentum" -> ({Global`Pa} -> {FeynFacet`NA})
  |>]] === $Failed];

FTTest`FTReport[];
