#!/usr/bin/env wolframscript

record = Get[FileNameJoin[{
  DirectoryName[ExpandFileName[$InputFileName]],
  "CF48FirstStripCANONICASolution.wl"
}]];

{p, s} = record["Variables"];
ee = record["Regulator"];
e = record["TargetDiagonalCoefficient"];
c = record["SourceDiagonalCoefficient"];
b = record["OriginalOffDiagonalBlock"];
gauge = record["Gauge"];
transformed = record["TransformedBlock"];
alphabet = record["Alphabet"];
residues = record["DlogResidues"];

gaugeResidual = Table[
  Map[
    Together,
    transformed[[mu]] -
      (b[[mu]] + ee (e[[mu]].gauge - gauge.c[[mu]]) -
        D[gauge, {p, s}[[mu]]]),
    {2}
  ],
  {mu, 2}
];

dlogResidual = Table[
  Map[
    Together,
    transformed[[mu]] -
      Sum[
        residues[[a]] D[Log[alphabet[[a]]], {p, s}[[mu]]],
        {a, Length[alphabet]}
      ],
    {2}
  ],
  {mu, 2}
];

Print["GaugeEquationResidual = ", gaugeResidual];
Print["DlogReconstructionResidual = ", dlogResidual];

Exit[If[gaugeResidual === {{{0}}, {{0}}} &&
  dlogResidual === {{{0}}, {{0}}}, 0, 1]];
