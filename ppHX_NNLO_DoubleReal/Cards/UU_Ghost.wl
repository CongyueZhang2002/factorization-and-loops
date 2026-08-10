(* Unpolarized pp -> h X NNLO double-real ghost-antighost cut input card.

   Assembly convention (Slavnov-Taylor completion of the -g polarization
   sums used for the two cut gluons in UU.wl):

     sigma_gg = (1/2!) [UU.wl grid, -g sums] - 1 x [this grid],

   both over the identical unsymmetrized phase-space measure. The 1/2!
   is the identical-gluon symmetry factor of the gg final state; the
   ghost-antighost pair is distinct and carries no symmetry factor. The
   relative minus sign is applied at assembly, not stored in this card. *)

With[
  {diagramIndices = Range[7]},
<|
  "ForwardAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> diagramIndices
  |>,
  "ConjugateAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> diagramIndices
  |>,
  "Partons" -> ({
    F[3, {1}], F[4, {1}]
  } -> {
    F[3, {1}], F[4, {1}], U[5], -U[5]
  }),
  "Model" -> "SMQCD",
  "InsertionLevel" -> {Classes},
  "ExcludeTopologies" -> {Tadpoles, WFCorrections},
  "ExcludeParticles" -> {S[_], V[1], V[2], V[3]},
  "PartonMomentum" -> ({ka, kb} -> {kc, kd, ke, kf}),
  "PhaseSpaceMomentum" -> {kd, ke, kf},
  "PartonIntegrated" -> {kd},
  "MomentumFraction" -> ({xa, xb} -> {zh, NA, NA, NA}),
  "HadronMomentum" -> ({Pa, Pb} -> {Ph, NA, NA, NA}),
  "HadronLongDirection" -> ({n, nb} -> {nh, NA, NA, NA}),
  "HadronDualDirection" -> ({nb, n} -> {nhb, NA, NA, NA}),
  "HadronLongSpin" -> ({\[Lambda]a, 0} -> {\[Lambda]h, NA, NA, NA}),
  "HadronTransSpin" -> ({STvec, 0} -> {SThvec, NA, NA, NA}),
  "HadronicVariables" -> <|
    "Coordinates" -> <|
      Pa -> {0, Sqrt[s/(2 xa xb)], 0, 0},
      Pb -> {Sqrt[s/(2 xa xb)], 0, 0, 0},
      Ph -> {
        -zh t Sqrt[xb/(2 s xa)],
        -zh u Sqrt[xa/(2 s xb)],
        zh Sqrt[t u/s],
        0
      },
      nh -> {
        xb t/(xb t + xa u),
        xa u/(xb t + xa u),
        -Sqrt[2 xa xb t u]/(xb t + xa u),
        0
      },
      nhb -> {
        xa u/(xb t + xa u),
        xb t/(xb t + xa u),
        Sqrt[2 xa xb t u]/(xb t + xa u),
        0
      },
      STvec -> {0, 0, ST Cos[\[Phi]a], ST Sin[\[Phi]a]},
      SThvec -> {
        -STh Sqrt[2 xa xb t u] Cos[\[Phi]h]/(xb t + xa u),
        STh Sqrt[2 xa xb t u] Cos[\[Phi]h]/(xb t + xa u),
        -STh (xb t - xa u) Cos[\[Phi]h]/(xb t + xa u),
        STh Sin[\[Phi]h]
      }
    |>,
    "Assumptions" -> (
      s > 0 && t < 0 && u < 0 && s + t + u > 0 &&
      CA > 0 && CF > 0 && \[Alpha]s > 0 && 0 < Epsilon < 1 &&
      Element[{s, t, u, ST, STh, \[Phi]a, \[Phi]h}, Reals]
    )
  |>,
  "KinematicMassDimensions" -> <|s -> 2, t -> 2, u -> 2|>,
  "CoefficientKinematics" -> <|
    "PositiveFractions" -> Automatic,
    "DistributionFactor" -> f1[xa] f1[xb] D1[zh],
    "LaurentValuation" -> Automatic,
    "Scale" -> s,
    "DimensionlessCoordinates" -> <|x -> -t/s, y -> -u/s|>,
    "ForbiddenVariables" -> Automatic,
    "BranchGrammar" -> "PositiveMonomialRoots",
    "PhysicalRegion" -> (
      x > 0 && y > 0 && x + y < 1 && Element[{x, y}, Reals]
    )
  |>,
  "SetDistributionZero" -> {g1L, h1, G1L, H1},
  "SetMassZero" -> {Pa, Pb, Ph, ka, kb, kc, kd, ke, kf}
|>
]
