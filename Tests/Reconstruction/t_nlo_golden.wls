(* Golden regression: the regenerated NLO UU 10x10 pre-IBP artifacts must
   reproduce the 2026-08-05 physics content exactly, and must pass the
   current artifact validation.

   Acceptance criteria:
   A. Both directories contain the same 100 pair files.
   B. Every regenerated artifact passes validPreIBPResultQ (current
      validation, including the analytic-context requirements the old
      artifacts predate).
   C. For every pair, FractionMeasure, PreFactor, PhaseSpace and
      Integrand agree exactly (structurally, or else algebraically to
      zero difference).
   D. For every pair, the topology records agree on the physics subset:
      Topology, BaseGLI, FamilyCoefficient, CutMomenta, CutIndices,
      CutDirections, Propagators. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

oldDirectory = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_05_10x10_1", "Pairs"
}];
newDirectory = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_10_10x10_regen", "Pairs"
}];

oldNames = Sort[FileNameTake /@ FileNames["F*_C*.wl", oldDirectory]];
newNames = Sort[FileNameTake /@ FileNames["F*_C*.wl", newDirectory]];

FTTest`FTAssert["A. same 100 pair files in both directories",
  oldNames === newNames && Length[oldNames] === 100];

expressionKeys = {"FractionMeasure", "PreFactor", "PhaseSpace", "Integrand"};
recordKeys = {
  "Topology", "BaseGLI", "FamilyCoefficient",
  "CutMomenta", "CutIndices", "CutDirections", "Propagators"
};

sameExpressionQ[old_, new_] := TrueQ[
  SameQ[old, new] || FeynFacet`Private`exactZeroQ[old - new]
];

validationFailures = {};
expressionFailures = {};
recordFailures = {};
structuralMatches = 0;
algebraicOnlyMatches = 0;

Do[
  Module[{old, new, oldRecords, newRecords},
    old = Get[FileNameJoin[{oldDirectory, name}]];
    new = Get[FileNameJoin[{newDirectory, name}]];
    If[! FeynFacet`Private`validPreIBPResultQ[new],
      AppendTo[validationFailures, name]
    ];
    Do[
      Which[
        SameQ[old[key], new[key]],
          structuralMatches++,
        sameExpressionQ[old[key], new[key]],
          algebraicOnlyMatches++,
        True,
          AppendTo[expressionFailures, {name, key}]
      ],
      {key, expressionKeys}
    ];
    oldRecords = old["Topologies"];
    newRecords = new["Topologies"];
    If[
      Length[oldRecords] =!= Length[newRecords] ||
        ! And @@ MapThread[
          SameQ[KeyTake[#1, recordKeys], KeyTake[#2, recordKeys]] &,
          {oldRecords, newRecords}
        ],
      AppendTo[recordFailures, name]
    ]
  ],
  {name, oldNames}
];

FTTest`FTAssert["B. all 100 regenerated artifacts pass current validation",
  validationFailures === {}];
FTTest`FTAssert["C. all expression fields agree exactly (400 comparisons)",
  expressionFailures === {}];
FTTest`FTAssert["D. all topology records agree on the physics subset",
  recordFailures === {}];

Print["    structural matches: ", structuralMatches,
  ", algebraic-only: ", algebraicOnlyMatches];
If[expressionFailures =!= {},
  Print["    differing fields: ", Take[expressionFailures, UpTo[10]]]];
If[recordFailures =!= {},
  Print["    differing records: ", Take[recordFailures, UpTo[10]]]];

(* E. The fresh reduction reproduces the 2026-08-05 master set. *)
oldKira = Get[FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_05_10x10_1", "KiraResult.wl"
}]];
newKira = Get[FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_10_10x10_regen", "KiraResult.wl"
}]];
FTTest`FTAssert["E. same master integrals as the 2026-08-05 reduction",
  AssociationQ[oldKira] && AssociationQ[newKira] &&
    Sort[ToString[#, InputForm] & /@ oldKira["Masters"]] ===
      Sort[ToString[#, InputForm] & /@ newKira["Masters"]]];

FTTest`FTReport[];
