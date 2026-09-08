(* Unpolarized pp -> h X real-emission input card. *)

With[
  {
    forwardIndices = {1, 2, 3, 9, 10},
    backwardIndices = {1, 2, 3, 9, 10}
  },
<|
  "ForwardAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> forwardIndices
  |>,
  "ConjugateAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> backwardIndices
  |>,
  "Partons" -> ({
    F[3, {1}], F[3, {1}]
  } -> {
    F[3, {1}], F[3, {1}], V[5]
  }),
  "Model" -> "SMQCD",
  "InsertionLevel" -> {Classes},
  "ExcludeTopologies" -> {Tadpoles, WFCorrections},
  "ExcludeParticles" -> {S[_], V[1], V[2], V[3]},
  "PartonMomentum" -> ({ka, kb} -> {kc, kd, ke}),
  "PhaseSpaceMomentum" -> {kd, ke},
  "PartonIntegrated" -> {kd},
  "MomentumFraction" -> ({xa, xb} -> {zh, NA, NA}),
  "HadronMomentum" -> ({Pa, Pb} -> {Ph, NA, NA}),
  "HadronLongDirection" -> ({n, nb} -> {nh, NA, NA}),
  "HadronDualDirection" -> ({nb, n} -> {nhb, NA, NA}),
  "HadronLongSpin" -> ({\[Lambda]a, 0} -> {\[Lambda]h, NA, NA}),
  "HadronTransSpin" -> ({STvec, 0} -> {SThvec, NA, NA}),
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
  "SetDistributionZero" -> {g1L, h1, G1L, H1},
  "SetMassZero" -> {Pa, Pb, Ph, ka, kb, kc, kd, ke}
|>
]
