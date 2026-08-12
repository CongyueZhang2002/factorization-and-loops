(* Exact all-order-in-eps solution of the NLO masters by a 2F1 ansatz
   against the certified DE system.

     I_i = cc(ep) * (1-v-w)^(-ep) * R_i(v,w) * F(z_i),
     F(z) = 2F1(1,1;1-ep;z),  z(1-z)F' = (z+ep)F - ep.

   Both DE residuals are LINEAR in cc, so candidates (z, R) are
   prefiltered at exact rational (v,w) points with ep symbolic: cc(ep)
   is solved from one point and must agree at others.  Only survivors
   get the full symbolic zero-certificate. *)

scratch = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad";
sys = Get[FileNameJoin[{scratch, "nlo_de_system.wl"}]];
Av = sys["Av"] /. {Global`eps -> ep, Global`v -> v, Global`w -> w, Global`d -> 4 - 2 ep};
Aw = sys["Aw"] /. {Global`eps -> ep, Global`v -> v, Global`w -> w, Global`d -> 4 - 2 ep};
masters = sys["Masters"];

letters = {v, w, 1 - v, 1 - w, v + w, 1 - v - w};
rFactors = Append[letters, 1];

zCandidates = {
  w (1 - v - w)/((1 - w) (v + w)),
  v (1 - v - w)/((1 - v) (v + w)),
  (1 - v - w)/((1 - v) (1 - w)),
  v/((1 - w) (v + w)),
  w/((1 - v) (v + w)),
  v w/((1 - v) (1 - w))
};

volN = 2^(1 - (4 - 2 ep)) 2 Pi^((3 - 2 ep)/2)/Gamma[(3 - 2 ep)/2];
vol = volN (1 - v - w)^(-ep);

contiguous = HoldPattern[Derivative[1][ff][z_]] :>
  ((z + ep) ff[z] - ep)/(z (1 - z));

points = {{3/7, 2/11}, {5/13, 4/9}, {1/6, 3/5}};

fitMaster[i_] := Module[{hits = {}},
  Do[
    Module[{z, R, trial, residuals, alpha, beta, ok, ccStar},
      z = Together[zCandidates[[iz]]];
      R = 1/(rFactors[[l1]] rFactors[[l2]]);
      trial = cc (1 - v - w)^(-ep) R ff[z];
      residuals = Together[
        {
          (D[trial, v] /. contiguous) -
            Av[[i, i]] trial - Av[[i, 1]] vol,
          (D[trial, w] /. contiguous) -
            Aw[[i, i]] trial - Aw[[i, 1]] vol
        } (1 - v - w)^ep / volN
      ];
      (* linear in cc; ff[z] at numeric (v,w) stays inert symbolic:
         demanding the residual vanish identically means BOTH the
         ff[z] coefficient and the rest vanish; at numeric points
         treat ff[z] as an independent symbol. *)
      (* Structure of each residual, with F' eliminated:
           residual = cc * A(v,w;ep) * ff[z] + cc * B(v,w;ep) + C,
         C the volume source.  Identical vanishing (ff transcendental
         over the rationals) requires
           A == 0  (a condition on the pair (z, R) alone), and
           cc = -C/B  (the normalization).
         The numeric prefilter checks A at the sample points and
         solves cc from the ff-free part, demanding consistency. *)
      ccStar = Missing[];
      ok = True;
      Do[
        Module[{r1, fSym, coefF, coefOne, aO, bO, candidates, thisCC},
          r1 = residuals /. {v -> pt[[1]], w -> pt[[2]]};
          fSym = DeleteDuplicates @ Cases[r1, ff[_], Infinity];
          Which[
            Length[fSym] > 1,
              ok = False; Break[],
            Length[fSym] === 1,
              (* explicit ff present: its coefficient must vanish *)
              coefF = Together[
                Coefficient[#, First[fSym]] /. cc -> 1] & /@ r1;
              If[coefF =!= {0, 0}, ok = False; Break[]];
              coefOne = (# /. First[fSym] -> 0) & /@ r1,
            True,
              (* the F-part cancelled symbolically: condition already
                 satisfied; the whole residual is the ff-free part *)
              coefOne = r1
          ];
          aO = Together[Coefficient[#, cc]] & /@ coefOne;
          bO = Together[# /. cc -> 0] & /@ coefOne;
          candidates = DeleteDuplicates @ Flatten @ MapThread[
            Function[{a, b},
              Which[
                a === 0 && b === 0, {},
                a === 0, {$fail},
                True, {Together[-b/a]}
              ]
            ],
            {aO, bO}
          ];
          If[MemberQ[candidates, $fail] || Length[candidates] =!= 1,
            ok = False; Break[]
          ];
          thisCC = First[candidates];
          If[MissingQ[ccStar],
            ccStar = thisCC,
            If[Together[ccStar - thisCC] =!= 0,
              ok = False; Break[]
            ]
          ]
        ],
        {pt, points}
      ];
      If[ok && ! MissingQ[ccStar],
        (* full symbolic certificate *)
        Module[{certificate},
          certificate = Together[residuals /. cc -> ccStar];
          If[Union[certificate] === {0},
            (* the residual equations carry the source divided by
               volN, so SolveAlways returns the TRUE cc directly; a
               volN multiplication here double-counts (caught by the
               kinematics-independent volN(eps) mismatch against the
               independent numerics) *)
            AppendTo[hits, <|
              "z" -> z, "R" -> R, "cc" -> Together[ccStar],
              "ccOverVolN" -> Together[ccStar/volN]
            |>]
          ]
        ]
      ]
    ],
    {iz, Length[zCandidates]}, {l1, Length[rFactors]},
    {l2, l1, Length[rFactors]}
  ];
  hits
];

exact = <||>;
Do[
  Module[{hits = fitMaster[i]},
    Print["master ", i, " (", InputForm[masters[[i]]], "): ",
      Length[hits], " certified hit(s)"];
    If[hits =!= {},
      Print["   ", InputForm[First[hits]]];
      exact[i] = First[hits]
    ]
  ],
  {i, 2, 7}
];

If[Length[exact] === 6,
  Put[
    <|
      "VolExact" -> vol,
      "VolNormalization" -> volN,
      "Form" ->
        "I_i = cc * (1-v-w)^(-ep) * R * 2F1(1,1;1-ep;z); cc includes volN",
      "Solutions" -> exact,
      "Masters" -> masters,
      "Convention" -> sys["Convention"]
    |>,
    FileNameJoin[{scratch, "nlo_masters_exact.wl"}]
  ];
  Print["SAVED: nlo_masters_exact.wl"],
  Print["INCOMPLETE: only ", Length[exact], " of 6 fitted"]
];
