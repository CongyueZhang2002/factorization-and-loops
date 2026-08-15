With[
  {
    l1 = 2 - EulerGamma + Log[4/(s v)],
    l2 = Log[4/(s^2 (1 - v) v^4)] - EulerGamma,
    a0 = 2 (1 - CA^2),
    a1 = CA CF,
    b0 = 1 - CA^2,
    b1 = Log[s] + 3 Log[v],
    b2 = Log[s] + 2 Log[1 - v] + 3 Log[v],
    b3 = Log[s] + 2 Log[1 - v] + Log[v]
  },
  With[
    {
      r10 = a0 (1 + v^2),
      r11 = -2 a0 (1 - v + v^2) + a1 (1 + v^2),
      r12 = a0 (1 - v)^2 - 2 a1 (1 - v + v^2),
      p1 = 8/(Pi s v (1 - v)^2),
      k12 = l1^2/2 - Pi^2/4 + 2,
      bFirst = b1 - 2 b2 + (2 - CA^2) b3,
      bSecond = (b1^2 - 2 b2^2 + (2 - CA^2) b3^2)/2,
      p2 = -32/(Pi s v (1 - v)^2),
      k22 = l2^2/2 - Pi^2/12
    },
    With[
      {
        r20 = -(1 + v^2) b0,
        r21 = (1 - v)^2 b0 - (1 + v^2) bFirst,
        r22 = (1 - v)^2 bFirst - (1 + v^2) bSecond
      },
      With[
        {
          exact = <|
            1 -> (
              4 16^Epsilon (Epsilon - 1)
                (2 - 2 CA^2 + CA CF Epsilon)
                (-(1 + v^2) + Epsilon (1 - v)^2)/(
                  Sqrt[Pi] Epsilon s (1 - v)^2 v
                    (s v)^Epsilon Gamma[3/2 - Epsilon]
                )
            ),
            2 -> (
              -2^(5 + 4 Epsilon) Sqrt[Pi] v^(-1 - 3 Epsilon)
                (-(1 + v^2) + Epsilon (1 - v)^2)
                (
                  s^Epsilon v^(3 Epsilon)
                    - 2 (s (1 - v)^2)^Epsilon v^(3 Epsilon)
                    + (2 - CA^2) (s (1 - v)^2 v)^Epsilon
                ) Csc[Pi Epsilon]/(
                  s (1 - v)^2
                    (s^2 (1 - v) v)^Epsilon
                    Gamma[1/2 - Epsilon]
                )
            )
          |>,
          laurent = <|
            1 -> <|
              -1 -> p1 r10,
              0 -> p1 (r11 + l1 r10),
              1 -> p1 (r12 + l1 r11 + k12 r10)
            |>,
            2 -> <|
              -1 -> p2 r20,
              0 -> p2 (r21 + l2 r20),
              1 -> p2 (r22 + l2 r21 + k22 r20)
            |>
          |>
        },
        With[
          {
            distribution = AssociationMap[
              Function[a,
                With[
                  {
                    cm1 = laurent[a][-1],
                    c0 = laurent[a][0],
                    c1 = laurent[a][1]
                  },
                  <|
                    "Delta" -> -cm1/(a Epsilon^2) - c0/(a Epsilon) - c1/a,
                    "Plus0" -> cm1/Epsilon + c0,
                    "Plus1" -> -a cm1,
                    "Plus2" -> 0
                  |>
                ]
              ],
              {1, 2}
            ]
          },
          <|
            "Format" -> "FACET-NLO-EndpointDistribution",
            "FormatVersion" -> 1,
            "Channel" -> "UU",
            "Dimension" -> 4 - 2 Epsilon,
            "FractionMeasure" ->
              dFraction[xa] dFraction[xb] dFraction[zh],
            "CommonPreFactor" ->
              CF Pi^(3 + Epsilon) \[Alpha]s^3
                D1[zh] f1[xa] f1[xb]/(xa xb zh^2),
            "CommonPreFactorLaurentValuation" -> 0,
            "Kinematics" -> <|
              "EndpointVariable" -> rho,
              "Rules" -> {
                t -> -s (1 - v),
                u -> -s v w,
                rho -> 1 - w,
                s + t + u -> s v rho
              },
              "PhysicalRegion" ->
                s > 0 && 0 < v < 1 && 0 < rho < 1
            |>,
            "Normalization" -> <|
              "StoredAnalyticMasters" -> "PhysicalCutPhaseSpace",
              "IBPMasterMeasure" -> HoldForm[dD[k]/(I Pi^(D/2))],
              "PhysicalMasterToGLI" ->
                -I 2^(2 - 2 Epsilon) Pi^(-Epsilon),
              "Cut" -> HoldForm[DiracDeltaPlus[q^2]],
              "CutIncludes2Pi" -> False
            |>,
            "EndpointPowers" -> <|
              1 -> -1 - Epsilon,
              2 -> -1 - 2 Epsilon
            |>,
            "ExactCoefficients" -> exact,
            "LaurentCoefficients" -> laurent,
            "DistributionIdentity" -> HoldForm[
              rho^(-1 - a Epsilon) ->
                -deltaRho/(a Epsilon) +
                  Sum[(-a Epsilon)^n plusRho[n]/n!, {n, 0, Infinity}]
            ],
            "DistributionCoefficientsThroughFiniteOrder" -> distribution,
            "TotalDistributionThroughFiniteOrder" -> AssociationMap[
              Total[Lookup[Values[distribution], #]] &,
              {"Delta", "Plus0", "Plus1", "Plus2"}
            ],
            "CommonPreFactorExpansionDepthForFiniteResult" -> <|
              "Delta" -> 2,
              "Plus0" -> 1,
              "Plus1" -> 0,
              "Plus2" -> 0
            |>
          |>
        ]
      ]
    ]
  ]
]
