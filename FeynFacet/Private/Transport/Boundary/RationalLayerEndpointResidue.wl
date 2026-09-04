(* Connection residue of a block-triangular rational-epsilon-dependent
   subsystem at a local expansion point.

   The source and target diagonal blocks are in epsilon form, while the
   incoming block is supplied as a Laurent deck in epsilon.  Each channel is
   reduced directly from inert letters; no characteristic-zero connection is
   assembled. *)

Clear[ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint];

Options[ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint] =
  Options[BuildCompactEndpointResidue];

ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint[
    source_Association,
    diagonal_Association, incomingByOrder_Association,
    variable_Symbol, localExpansionPoint_, OptionsPattern[]] := Catch@Module[
  {fail, curve, definitions, build, sourceResult, diagonalResult,
   incomingResults, sourceDimension, targetDimension, sourceResidue,
   diagonalResidue, incomingResidues, orders, zeroSource, zeroTarget,
   zeroIncoming, fullResidues},

  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  curve = OptionValue["Curve"];
  definitions = OptionValue["CompositeDefinitions"];
  If[! AssociationQ[definitions] || incomingByOrder === <||> ||
      ! VectorQ[Keys[incomingByOrder], IntegerQ] ||
      ! AllTrue[Join[{source, diagonal}, Values[incomingByOrder]],
        AssociationQ[#] && ListQ[Lookup[#, "Letters", Missing[]]] &&
          ListQ[Lookup[#, "Residues", Missing[]]] &],
    fail["RationalEpsilonDependentBlockConnectionResidueInputInvalid"]];

  build[channel_Association] := BuildCompactEndpointResidue[
    channel["Letters"], channel["Residues"], variable,
    localExpansionPoint,
    "Curve" -> curve, "CompositeDefinitions" -> definitions];
  sourceResult = build[source];
  If[sourceResult["Status"] =!= "CompactEndpointResidueBuilt",
    fail["SourceConnectionResidueComputationFailed",
      <|"Cause" -> sourceResult|>]];
  diagonalResult = build[diagonal];
  If[diagonalResult["Status"] =!= "CompactEndpointResidueBuilt",
    fail["TargetDiagonalBlockConnectionResidueComputationFailed",
      <|"Cause" -> diagonalResult|>]];
  incomingResults = Association@KeyValueMap[#1 -> build[#2] &,
    incomingByOrder];
  If[AnyTrue[Values[incomingResults],
      Lookup[#, "Status", None] =!= "CompactEndpointResidueBuilt" &],
    fail["IncomingBlockConnectionResidueComputationFailed",
      <|"Failures" -> Select[incomingResults,
        Lookup[#, "Status", None] =!= "CompactEndpointResidueBuilt" &]|>]];

  If[! MatchQ[sourceResult["MatrixDimensions"],
        {_Integer?Positive, _Integer?Positive}] ||
      ! SameQ @@ sourceResult["MatrixDimensions"] ||
      ! MatchQ[diagonalResult["MatrixDimensions"],
        {_Integer?Positive, _Integer?Positive}] ||
      ! SameQ @@ diagonalResult["MatrixDimensions"],
    fail["DiagonalBlockConnectionResidueDimensionsInvalid"]];
  sourceDimension = First[sourceResult["MatrixDimensions"]];
  targetDimension = First[diagonalResult["MatrixDimensions"]];
  If[! AllTrue[Values[incomingResults],
      #MatrixDimensions === {targetDimension, sourceDimension} &],
    fail["IncomingBlockConnectionResidueDimensionsInvalid"]];

  sourceResidue = sourceResult["Residue"];
  diagonalResidue = diagonalResult["Residue"];
  incomingResidues = Map[#Residue &, incomingResults];
  orders = Sort@Union[{1}, Keys[incomingResidues]];
  zeroSource = SparseArray[{}, {sourceDimension, sourceDimension}];
  zeroTarget = SparseArray[{}, {targetDimension, targetDimension}];
  zeroIncoming = SparseArray[{}, {targetDimension, sourceDimension}];
  fullResidues = Association@Table[order -> SparseArray@ArrayFlatten[{
      {If[order === 1, sourceResidue, zeroSource],
        SparseArray[{}, {sourceDimension, targetDimension}]},
      {Lookup[incomingResidues, order, zeroIncoming],
        If[order === 1, diagonalResidue, zeroTarget]}
    }], {order, orders}];

  <|
    "Status" ->
      "RationalEpsilonDependentBlockConnectionResidueComputed",
    "Variable" -> variable,
    "LocalExpansionPoint" -> localExpansionPoint,
    "Dimensions" -> <|"Source" -> sourceDimension,
      "Target" -> targetDimension,
      "Total" -> sourceDimension + targetDimension|>,
    "SourceConnectionResidue" -> sourceResidue,
    "TargetDiagonalBlockConnectionResidue" -> diagonalResidue,
    "IncomingConnectionResiduesByEpsilonOrder" -> incomingResidues,
    "BlockConnectionResiduesByEpsilonOrder" -> fullResidues
  |>
];

ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint[___] :=
  <|"Status" ->
    "RationalEpsilonDependentBlockConnectionResidueInputsNotWellFormed"|>;
