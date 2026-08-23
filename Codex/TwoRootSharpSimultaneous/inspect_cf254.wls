recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
   "sector_CF254_standard/CF254_9_8_unsolved.wl";

record = Get[recordPath];

Print["Head: ", Head[record]];
Print["ByteCount: ", ByteCount[record]];
If[AssociationQ[record], Print["Keys: ", Keys[record]]];

Scan[
  Function[key,
    With[{value = record[key]},
      Print[key, ": head=", Head[value], ", dimensions=", Dimensions[value],
        ", bytes=", ByteCount[value]]
    ]
  ],
  If[AssociationQ[record], Keys[record], {}]
];
