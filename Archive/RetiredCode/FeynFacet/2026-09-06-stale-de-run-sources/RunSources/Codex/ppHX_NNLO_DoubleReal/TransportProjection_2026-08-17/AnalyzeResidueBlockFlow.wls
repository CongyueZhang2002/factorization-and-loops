If[Length[$ScriptCommandLine] < 3,
  Print["usage: wolframscript -file AnalyzeResidueBlockFlow.wls <family-record> <frobenius-record>"];
  Exit[2]
];

family = Get[$ScriptCommandLine[[2]]];
frobenius = Get[$ScriptCommandLine[[3]]];
dimension = family["Dim"];
ranges = family["Ranges"];

residue = SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ frobenius["ResidueEntries"],
  {dimension, dimension}
];

NonzeroBlockQ[m_] := AnyTrue[Flatten[Normal[m]], Together[#] =!= 0 &];

edges = Flatten@Table[
  If[target =!= source &&
      NonzeroBlockQ[residue[[ranges[[target]], ranges[[source]]]]],
    {source -> target},
    {}
  ],
  {target, Length[ranges]},
  {source, Length[ranges]}
];

Print[<|
  "Family" -> family["Family"],
  "EdgesSourceToTarget" -> edges,
  "IncreasingBlockIndex" -> Count[edges, Rule[a_, b_] /; a < b],
  "DecreasingBlockIndex" -> Count[edges, Rule[a_, b_] /; a > b]
|>];
