(* Compact normal residue of a block-triangular rational-in-epsilon layer.

   The source and target diagonal blocks are in epsilon form, while the
   incoming block is supplied as a Laurent deck in epsilon.  Each channel is
   reduced directly from inert letters; no characteristic-zero connection is
   assembled. *)

Clear[BuildRationalEpsilonLayerEndpointResidue];

Options[BuildRationalEpsilonLayerEndpointResidue] =
  Options[BuildCompactEndpointResidue];

BuildRationalEpsilonLayerEndpointResidue[source_Association,
    diagonal_Association, incomingByOrder_Association,
    variable_Symbol, endpoint_, OptionsPattern[]] := Catch@Module[
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
    fail["RationalLayerEndpointResidueInputInvalid"]];

  build[channel_Association] := BuildCompactEndpointResidue[
    channel["Letters"], channel["Residues"], variable, endpoint,
    "Curve" -> curve, "CompositeDefinitions" -> definitions];
  sourceResult = build[source];
  If[sourceResult["Status"] =!= "CompactEndpointResidueBuilt",
    fail["RationalLayerSourceEndpointResidueFailed",
      <|"Cause" -> sourceResult|>]];
  diagonalResult = build[diagonal];
  If[diagonalResult["Status"] =!= "CompactEndpointResidueBuilt",
    fail["RationalLayerDiagonalEndpointResidueFailed",
      <|"Cause" -> diagonalResult|>]];
  incomingResults = Association@KeyValueMap[#1 -> build[#2] &,
    incomingByOrder];
  If[AnyTrue[Values[incomingResults],
      Lookup[#, "Status", None] =!= "CompactEndpointResidueBuilt" &],
    fail["RationalLayerIncomingEndpointResidueFailed",
      <|"Failures" -> Select[incomingResults,
        Lookup[#, "Status", None] =!= "CompactEndpointResidueBuilt" &]|>]];

  If[! MatchQ[sourceResult["MatrixDimensions"],
        {_Integer?Positive, _Integer?Positive}] ||
      ! SameQ @@ sourceResult["MatrixDimensions"] ||
      ! MatchQ[diagonalResult["MatrixDimensions"],
        {_Integer?Positive, _Integer?Positive}] ||
      ! SameQ @@ diagonalResult["MatrixDimensions"],
    fail["RationalLayerEndpointDiagonalDimensionsInvalid"]];
  sourceDimension = First[sourceResult["MatrixDimensions"]];
  targetDimension = First[diagonalResult["MatrixDimensions"]];
  If[! AllTrue[Values[incomingResults],
      #MatrixDimensions === {targetDimension, sourceDimension} &],
    fail["RationalLayerEndpointIncomingDimensionsInvalid"]];

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
    "Status" -> "RationalEpsilonLayerEndpointResidueBuilt",
    "Variable" -> variable,
    "Endpoint" -> endpoint,
    "Dimensions" -> <|"Source" -> sourceDimension,
      "Target" -> targetDimension,
      "Total" -> sourceDimension + targetDimension|>,
    "Source" -> sourceResult,
    "Diagonal" -> diagonalResult,
    "IncomingByOrder" -> incomingResults,
    "SourceResidue" -> sourceResidue,
    "DiagonalResidue" -> diagonalResidue,
    "IncomingResiduesByOrder" -> incomingResidues,
    "FullResiduesByOrder" -> fullResidues
  |>
];

BuildRationalEpsilonLayerEndpointResidue[___] :=
  <|"Status" -> "RationalLayerEndpointResidueInputsNotWellFormed"|>;
