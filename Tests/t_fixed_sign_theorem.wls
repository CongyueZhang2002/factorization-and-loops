(* Brute-force validation of the fixed-sign theorem (FACET notes eq. 3.8)
   and of the masslessSquareBounds / IdentifySafePropagator implementation.

   Acceptance criteria:
   A. On random massless 2 -> n phase-space points (RAMBO), Q^2/s lies in
      [min mu_ij, max mu_ij] for random rational coefficients, n = 2..4.
   B. masslessSquareBounds equals the direct min/max over mu_ij and
      contains all Monte Carlo values of Q^2/s.
   C. IdentifySafePropagator accepts known sign-safe denominators and
      rejects a known mixed-sign one on the NLO UU card. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

SeedRandom[20260810];

mink[p_, q_] := p[[1]] q[[1]] - p[[2 ;; 4]].q[[2 ;; 4]];

(* RAMBO: n massless momenta with total (sqrtS, 0, 0, 0). *)
rambo[n_, sqrtS_] := Module[{q, Q, M, b, gamma, a2, x},
  q = Table[
    Module[{c, phi, e},
      c = RandomReal[{-1, 1}];
      phi = RandomReal[{0, 2 Pi}];
      e = -Log[RandomReal[] RandomReal[]];
      e {1, Sqrt[1 - c^2] Cos[phi], Sqrt[1 - c^2] Sin[phi], c}
    ],
    {n}
  ];
  Q = Total[q];
  M = Sqrt[Q[[1]]^2 - Q[[2 ;; 4]].Q[[2 ;; 4]]];
  b = -Q[[2 ;; 4]]/M;
  gamma = Q[[1]]/M;
  a2 = 1/(1 + gamma);
  x = sqrtS/M;
  Table[
    With[{qi = q[[i]], bq = b.q[[i, 2 ;; 4]]},
      x Prepend[
        qi[[2 ;; 4]] + b (qi[[1]] + a2 bq),
        gamma qi[[1]] + bq
      ]
    ],
    {i, n}
  ]
];

sqrtSN = 2.;
sN = sqrtSN^2;
kaN = sqrtSN/2 {1, 0, 0, 1};
kbN = sqrtSN/2 {1, 0, 0, -1};

muValues[a_, b_, c_List] := Flatten @ Table[
  If[i === j, Nothing, (a + c[[i]]) (b + c[[j]])],
  {i, Length[c]}, {j, Length[c]}
];

(* Part A: containment over random points and coefficients. *)
trialViolations = 0;
momentumClosureError = 0.;
Do[
  Module[{n, p, coefficients, a, b, c, Q, ratio, mus, lo, hi, scale},
    n = RandomInteger[{2, 4}];
    p = rambo[n, sqrtSN];
    momentumClosureError = Max[
      momentumClosureError,
      Max[Abs[Total[p] - (kaN + kbN)]],
      Max[Abs[mink[#, #] & /@ p]]
    ];
    coefficients = RandomInteger[{-6, 6}, n + 2]/2;
    {a, b} = coefficients[[1 ;; 2]];
    c = coefficients[[3 ;;]];
    Q = a kaN + b kbN + c.p;
    ratio = mink[Q, Q]/sN;
    mus = muValues[a, b, c];
    {lo, hi} = {Min[mus], Max[mus]};
    scale = Max[1., Abs[ratio], Max[Abs[mus]]];
    If[ratio < lo - 10^-9 scale || ratio > hi + 10^-9 scale,
      trialViolations++
    ]
  ],
  {6000}
];
FTTest`FTAssert["RAMBO momenta close and massless to 1e-9",
  momentumClosureError < 10^-9];
FTTest`FTAssert["theorem containment: 0 violations in 6000 random trials",
  trialViolations === 0];

(* Load the full stack for the implementation checks. *)
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

card = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];

(* Part B: implementation vs direct mu_ij min/max, and MC containment. *)
implementationMatches = True;
implementationContains = True;
Do[
  Module[{coefficients, bounds, direct, samples},
    coefficients = RandomInteger[{-6, 6}, 5]/2;
    bounds = FeynFacet`Private`masslessSquareBounds[coefficients, 3];
    direct = {
      Min[muValues[coefficients[[1]], coefficients[[2]], coefficients[[3 ;;]]]],
      Max[muValues[coefficients[[1]], coefficients[[2]], coefficients[[3 ;;]]]]
    };
    If[bounds =!= direct, implementationMatches = False];
    samples = Table[
      Module[{p = rambo[3, sqrtSN], Q},
        Q = coefficients[[1]] kaN + coefficients[[2]] kbN +
          coefficients[[3 ;;]].p;
        mink[Q, Q]/sN
      ],
      {200}
    ];
    If[
      Min[samples] < bounds[[1]] - 10^-8 || Max[samples] > bounds[[2]] + 10^-8,
      implementationContains = False
    ]
  ],
  {50}
];
FTTest`FTAssert["masslessSquareBounds equals direct mu min/max (50 draws)",
  implementationMatches];
FTTest`FTAssert["masslessSquareBounds contains MC values (50 x 200 points)",
  implementationContains];

(* Part C: IdentifySafePropagator on the NLO UU card.
   kc + ke: (c_i+a)(c_j+b) >= 0 for all pairs -> safe (timelike side).
   ka - kc: all mu <= 0 -> safe (spacelike side).
   ka - kc + ke: mu of both signs -> must be rejected. *)
FTTest`FTAssert["safe: (kc + ke)^2 accepted",
  FeynFacet`IdentifySafePropagator[card, FeynCalc`SFAD[Global`kc + Global`ke]] === True];
FTTest`FTAssert["safe: (ka - kc)^2 accepted",
  FeynFacet`IdentifySafePropagator[card, FeynCalc`SFAD[Global`ka - Global`kc]] === True];
FTTest`FTAssert["mixed sign: (ka - kc + ke)^2 rejected",
  Quiet[FeynFacet`IdentifySafePropagator[card, FeynCalc`SFAD[Global`ka - Global`kc + Global`ke]]] === $Failed];

FTTest`FTReport[];
