#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
candidatePath = FileNameJoin[{root, "Codex",
  "TwoRootCF254Sector9Lower", "CF254_9_6_raw_lifted_candidate.wl"}];
Clear[Global`eps];
candidate = Get[candidatePath];
eps = Global`eps;
residues = candidate["ResidueMatrices"];
entries = Flatten[residues];
nonzero = Select[entries, ! TrueQ[# === 0] &];
dependent = Select[nonzero, ! FreeQ[#, eps] &];

Print[InputForm[<|
  "Path" -> candidatePath,
  "RawResiduesFlag" -> Lookup[candidate, "RawResidues", Missing[]],
  "ResidueDimensions" -> Dimensions[residues],
  "ResidueEntryCount" -> Length[entries],
  "NonzeroResidueEntryCount" -> Length[nonzero],
  "RegulatorDependentNonzeroEntryCount" -> Length[dependent],
  "ConstantResidues" -> FreeQ[residues, eps],
  "LettersEpsFree" -> FreeQ[candidate["Alphabet"], eps],
  "StoredExactPfaffianResidualsZero" ->
    Lookup[candidate, "ExactPfaffianResidualsZero", Missing[]],
  "ExampleDependentResidues" -> Take[dependent, UpTo[3]]
|>]];

Exit[0];
