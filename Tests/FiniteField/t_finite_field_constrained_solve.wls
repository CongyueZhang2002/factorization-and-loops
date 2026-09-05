(* M1: a pilot-discovered constrained plan must reproduce, on a later
   sample, exactly the normalized affine solution of the full
   four-elimination path (same normalization columns), pass all
   original-row checks, and report the one-factorization path. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

Clear[xConstrained, yConstrained, epsConstrained];
dlog[letter_] := {D[Log[letter], xConstrained],
  D[Log[letter], yConstrained]};
letters = {xConstrained, yConstrained, 1 - xConstrained - yConstrained};
diagonal = Table[
  Sum[{{{1}}, {{-1}}, {{2}}}[[a]] dlog[letters[[a]]][[mu]],
    {a, Length[letters]}], {mu, 2}];
record = <|"Variables" -> {xConstrained, yConstrained},
  "Regulator" -> epsConstrained,
  "OffDiagonalBlockEquation" -> {diagonal, diagonal, Table[Together[
    epsConstrained Sum[{{{1}}, {{2}}, {{-3}}}[[a]] *
        dlog[letters[[a]]][[mu]], {a, Length[letters]}] +
      D[{{xConstrained + yConstrained}},
        {xConstrained, yConstrained}[[mu]]]], {mu, 2}]}|>;
prep = FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[record];
prime = 1000003;
common = {"PointCount" -> 10, "NumeratorDegreeOffset" -> {0, 0},
  "Preparation" -> prep};

pilot = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 1/21, prime,
  "DiscoverPlan" -> True, Sequence @@ common];
plan = Lookup[pilot, "EliminationPlan", <||>];

full = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 2/23, prime,
  Sequence @@ common];
constrained = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 2/23, prime,
  "EliminationPlan" -> plan, Sequence @@ common];
normalizedFull = FeynFacet`NormalizeEpsFormAffineSample[full,
  plan["NormalizationColumns"], prime];

stale = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 2/23, prime,
  "EliminationPlan" -> Join[plan, <|"OffDiagonalBasisTransformationUnknownCount" -> 1|>],
  Sequence @@ common];

tests = <|
  "PlanDiscovered" -> AssociationQ[plan] && plan["Status"] === "OK",
  "PlanShape" -> Length[plan["NormalizationColumns"]] === plan["Nullity"] &&
    Length[plan["IndependentEquationRows"]] === plan["GenericRank"] &&
    plan["GenericRank"] + plan["Nullity"] === plan["UnknownCount"],
  "ConstrainedPath" -> constrained["SolvePath"] ===
    "OneConstrainedMultiRHSFactorization",
  "AllRowChecks" -> TrueQ[constrained["ParticularCheckZero"]] &&
    TrueQ[constrained["NullspaceCheckZero"]] &&
    TrueQ[constrained["NormalizationCheck"]],
  "NormalizedParticularAgrees" ->
    constrained["ParticularSolution"] === normalizedFull["ParticularSolution"],
  "NormalizedNullspaceAgrees" ->
    constrained["NullspaceBasis"] === normalizedFull["NullspaceBasis"],
  "RankMetadataAgrees" -> constrained["Rank"] === full["Rank"] &&
    constrained["Nullity"] === full["Nullity"],
  "NoSeparateEliminations" -> constrained["RankSeconds"] === 0. &&
    constrained["NullspaceSeconds"] === 0.,
  "IncompatiblePlanFallsBack" -> stale["SolvePath"] =!=
    "OneConstrainedMultiRHSFactorization" && TrueQ[stale["Consistent"]]
|>;
Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
