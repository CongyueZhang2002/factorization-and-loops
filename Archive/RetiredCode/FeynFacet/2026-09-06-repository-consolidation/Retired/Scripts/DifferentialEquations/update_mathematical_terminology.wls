#!/usr/bin/env wolframscript
(* Explicit conversion of a saved record to the 2026-09-05 vocabulary.
   This command neither loads the package nor revalidates mathematics.
   It writes a new file and never changes the source. *)
$HistoryLength = 0;
fail[message_] := (Print[message]; Exit[1]);
args = Rest[$ScriptCommandLine];
usage = "Usage: wolframscript -file update_mathematical_terminology.wls --kind KIND --input FILE --output NEWFILE";
If[MemberQ[args, "--help"], Print[usage]; Exit[0]];
If[Length[args] =!= 6, fail[usage]];
pairs = Partition[args, 2];
If[Sort[First /@ pairs] =!= {"--input", "--kind", "--output"}, fail[usage]];
options = Association[Rule @@@ pairs];
kind = options["--kind"];
input = ExpandFileName[options["--input"]];
output = ExpandFileName[options["--output"]];
kinds = {"block-decomposition", "local-frobenius", "kernel-solution",
  "singular-point-matching", "basis-valuations", "root-parity"};
If[! MemberQ[kinds, kind], fail["Unknown record kind: " <> kind]];
If[input === output || FileExistsQ[output],
  fail["Output must be a new file, distinct from the input."]];
If[! FileExistsQ[input], fail["Input does not exist."]];
If[! DirectoryQ[DirectoryName[output]], fail["Output directory does not exist."]];
data = Quiet[Check[Get[input], $Failed]];
If[! AssociationQ[data], fail["Input must contain one Association."]];
(* Renames only. No SchemaVersion or validation-strength field is changed. *)
names = Switch[kind,
  "block-decomposition",
    <|"IrreducibleDiagonalBlocks" -> "DiagonalBlocksInCurrentBasis"|>,
  "local-frobenius",
    <|"Residue" -> "EpsilonNormalizedConnectionResidue"|>,
  "kernel-solution",
    <|"Residues" -> "KernelCoefficientMatrices",
      "KResidues" -> "OffDiagonalKernelCoefficientMatrices",
      "ExactDLogDecomposition" -> "ExactKernelCoefficientDecomposition",
      "ExactDLogDecompositionQ" -> "ExactKernelCoefficientDecompositionQ",
      "ExactDLogResidues" -> "ExactKernelCoefficientMatrices",
      "ResidueComparisons" -> "KernelCoefficientComparisons",
      "ResidueMismatches" -> "KernelCoefficientMismatches",
      "ResidueKeys" -> "KernelCoefficientKeys"|>,
  "singular-point-matching",
    <|"SourceModeMap" -> "SourceModeCoefficientMatrices",
      "TargetGModeMap" -> "TransformedTargetModeCoefficientMatrices",
      "TargetGModeMapComplete" -> "TransformedTargetModeCoefficientMatricesComplete",
      "CombinedModeMap" -> "CombinedModeCoefficientMatrices",
      "TargetGState" -> "TransformedTargetState",
      "RegularizedInverseSelectors" -> "LocalSolutionToBoundaryCoefficientMatrices",
      "RegularizedInverseSelectorIndex" -> "LocalSolutionToBoundaryCoefficientMatrixIndex",
      "TangentialJunctionBindingV1" -> "SingularPointMatchingDataV1",
      "TangentialJunctionIntertwiningJetsAccepted" ->
        "SingularPointMatchingEquationValidatedThroughFirstLocalOrder"|>,
  "basis-valuations",
    <|"TransportEpsilonValuations" -> "BasisTransformationEpsilonValuations",
      "TransportEpsilonValuationsCertified" ->
        "BasisTransformationEpsilonValuationsValidatedAtRationalPoints"|>,
  "root-parity",
    <|"Rank" -> "RootCount", "MaximumRank" -> "MaximumRootCount",
      "GradeCount" -> "ParityComponentCount", "Grades" -> "ParityComponentMatrices",
      "ActiveGrades" -> "ActiveParityComponents",
      "StableRootFrame" -> "SquareRootGeneratorsValidated",
      "SquareRootGradeDecompositionData" -> "SquareRootParityDecompositionData",
      "GradedRankTooLarge" -> "SquareRootGeneratorCountTooLarge"|>
];
(* Kind-specific structural preconditions prevent ambiguous generic renames. *)
validKind = Switch[kind,
  "block-decomposition",
    Lookup[data, "DataType", None] === "FamilyDifferentialSystemBlockDecomposition" &&
      Lookup[data, "SchemaVersion", None] === 2,
  "local-frobenius",
    Lookup[data, "Status", None] === "TruncatedLocalFrobeniusExpansionComputed",
  "kernel-solution",
    StringStartsQ[ToString[Lookup[data, "Status", ""]], "RationalEpsilonDependentBlock"],
  "singular-point-matching",
    MemberQ[{"TangentialJunctionBindingV1", "SingularPointMatchingDataV1"},
      Lookup[data, "Status", None]],
  "basis-valuations",
    KeyExistsQ[data, "TransportEpsilonValuations"] ||
      KeyExistsQ[data, "BasisTransformationEpsilonValuations"],
  "root-parity",
    KeyExistsQ[data, "GradeCount"] || KeyExistsQ[data, "ParityComponentCount"]
];
If[! TrueQ[validKind], fail["Input does not match the declared record kind."]];
rename[value_String] := Lookup[names, value, value];
rename[value_] := value;
convert[value_Association] := Module[{keys = rename /@ Keys[value]},
  If[! DuplicateFreeQ[keys], fail["Old and current names collide; resolve the input explicitly."]];
  AssociationThread[keys -> (convert /@ Values[value])]
];
convert[value_List] := convert /@ value;
convert[value_String] := rename[value];
convert[value_] := value;
converted = convert[data];
If[kind === "local-frobenius",
  converted = Join[converted, <|"ResidueConvention" ->
    "R=Res(connection/eps); LocalSolution=H(rho,eps).rho^(eps R).c"|>]];
temporary = output <> ".tmp-" <> ToString[$ProcessID];
If[FileExistsQ[temporary], fail["Temporary output already exists."]];
Quiet[Check[
  Put[converted, temporary];
  If[Get[temporary] =!= converted, fail["Written copy did not reproduce the converted record."]];
  RenameFile[temporary, output],
  fail["Could not write converted record."]]];
Print[InputForm[<|"Status" -> "TerminologyUpdated",
  "Kind" -> kind, "Output" -> output, "MathematicsRevalidated" -> False|>]];
Exit[0];
