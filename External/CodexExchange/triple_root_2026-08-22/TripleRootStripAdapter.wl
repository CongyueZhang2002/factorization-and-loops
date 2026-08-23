BeginPackage["CodexTripleRootStrip`", {"CodexTripleRoot`"}];

TRCurrentRoots::usage =
  "TRCurrentRoots[frame, variables] rekeys a multiquadratic frame to the variables of a captured strip.";
TRClassifyStripRecord::usage =
  "TRClassifyStripRecord[record, frame] reports the declared radicals that occur in a captured recursive strip.";
TRApplyRootBranches::usage =
  "TRApplyRootBranches[expr, roots, images] replaces every declared square-root branch by the corresponding image.";
TRFieldInverse::usage =
  "TRFieldInverse[a, deltas] inverts one coefficient vector in a multiquadratic algebra.";
TRFieldDecompose::usage =
  "TRFieldDecompose[expr, roots] writes a rational expression in declared square roots as its 2^r rational channels.";
TRFieldCompose::usage =
  "TRFieldCompose[channels, roots] reconstructs a multiquadratic expression from its rational channels.";
TRDecomposeStripRecord::usage =
  "TRDecomposeStripRecord[record, frame] decomposes every entry of a captured strip into rational root channels.";
TRDiagonalOneFormBasis::usage =
  "TRDiagonalOneFormBasis[strip, roots, variables] returns a deduplicated closed one-form span from the two diagonal blocks.";
TRCandidateOneFormBasis::usage =
  "TRCandidateOneFormBasis[strip, roots, variables, epsilon] augments the diagonal span by dlogs of forcing entries at generic regulator values.";
TRRationalGaugeDenominator::usage =
  "TRRationalGaugeDenominator[channelForcing, variables] gives the rational higher-pole denominator suggested by the forcing channels.";

Begin["`Private`"];

trZeroQ[expr_] := AllTrue[Flatten[{expr}], TrueQ[Together[#] === 0] &];

TRCurrentRoots[frame_Association, variables : {_Symbol, _Symbol}] := Module[
  {frameVariables, substitution, variableRules, roots},
  frameVariables = Lookup[frame, "Variables", $Failed];
  substitution = Lookup[frame, "Subst", $Failed];
  roots = Lookup[frame, "Roots", $Failed];
  If[! MatchQ[frameVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[substitution, {_Rule, _Rule}] || ! ListQ[roots],
    Return[$Failed]];
  variableRules = Thread[frameVariables -> variables];
  Map[
    <|"Root" -> Together[#1["Root"] /. variableRules],
      "RootSquare" -> Together[(#1["RootSquare"] /. substitution) /.
        variableRules]|> &,
    roots]
];

trRadicalBases[expr_] := DeleteDuplicates[Cases[
  Unevaluated[expr],
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
    Together[base], {0, Infinity}, Heads -> True]];

TRClassifyStripRecord[record_Association, frame_Association] := Module[
  {variables, roots, rootBases, radicals, matches, indices, unknown},
  variables = Lookup[record, "Variables", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! ListQ[Lookup[record, "Strip", None]],
    Return[<|"Status" -> "InvalidStripRecord"|>]];
  roots = TRCurrentRoots[frame, variables];
  If[roots === $Failed,
    Return[<|"Status" -> "InvalidMultiquadraticFrame"|>]];
  rootBases = Together /@ (#1["Root"]^2 & /@ roots);
  radicals = trRadicalBases[record["Strip"]];
  matches[base_] := Flatten[Position[rootBases, candidate_ /;
    TrueQ[Together[base - candidate] === 0]]];
  indices = DeleteDuplicates[Flatten[matches /@ radicals]];
  unknown = Select[radicals, matches[#1] === {} &];
  <|"Status" -> If[unknown === {}, "ExactRootClassification",
      "UnclassifiedRadicals"],
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "RootIndices" -> indices,
    "RootCount" -> Length[indices],
    "RootSquares" -> Lookup[roots[[indices]], "RootSquare", {}],
    "RadicalBases" -> radicals,
    "UnclassifiedRadicalBases" -> unknown|>
];

TRApplyRootBranches[expr_, roots_List, images_List] /;
    Length[roots] === Length[images] :=
  Fold[
    Function[{current, index},
      current /. Power[base_, exponent_Rational] :>
        If[Denominator[exponent] === 2 &&
            TrueQ[Together[base - roots[[index, "Root"]]^2] === 0],
          images[[index]]^(2 exponent), Power[base, exponent]]],
    expr, Range[Length[roots]]];

trReplaceRootsWithSymbols[expr_, roots_List, symbols_List] :=
  TRApplyRootBranches[expr, roots, symbols];

TRFieldInverse[a_List, deltas_List] /;
    Length[a] === 2^Length[deltas] := Module[
  {dimension = Length[a], columns, matrix, inverse, check},
  If[trZeroQ[Rest[a]],
    If[TrueQ[Together[First[a]] === 0], Return[$Failed]];
    Return[Prepend[ConstantArray[0, dimension - 1],
      Together[1/First[a]]]]];
  columns = Table[
    CodexTripleRoot`TRMultiply[a, UnitVector[dimension, column], deltas],
    {column, dimension}];
  matrix = Transpose[columns];
  inverse = Quiet[Check[
    LinearSolve[matrix, UnitVector[dimension, 1]], $Failed]];
  If[inverse === $Failed, Return[$Failed]];
  inverse = Together /@ inverse;
  check = CodexTripleRoot`TRMultiply[a, inverse, deltas];
  If[! trZeroQ[check - UnitVector[dimension, 1]], $Failed, inverse]
];

TRFieldDecompose[expr_, roots_List] := Module[
  {rank = Length[roots], deltas, symbols, replaced, rational,
   numerator, denominator, numeratorChannels, denominatorChannels,
   denominatorInverse, result},
  deltas = Together /@ (#1["Root"]^2 & /@ roots);
  symbols = Array[Unique["trRoot"] &, rank];
  replaced = trReplaceRootsWithSymbols[expr, roots, symbols];
  If[! FreeQ[replaced,
      Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[$Failed]];
  rational = Together[replaced];
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[! PolynomialQ[numerator, symbols] ||
      ! PolynomialQ[denominator, symbols], Return[$Failed]];
  numeratorChannels = CodexTripleRoot`TRFromPolynomial[
    numerator, symbols, deltas];
  denominatorChannels = CodexTripleRoot`TRFromPolynomial[
    denominator, symbols, deltas];
  denominatorInverse = TRFieldInverse[denominatorChannels, deltas];
  If[denominatorInverse === $Failed, Return[$Failed]];
  result = CodexTripleRoot`TRMultiply[
    numeratorChannels, denominatorInverse, deltas];
  Together /@ result
];

TRFieldCompose[channels_List, roots_List] /;
    Length[channels] === 2^Length[roots] :=
  CodexTripleRoot`TRToExpression[channels, Lookup[roots, "Root", {}]];

trDecomposePair[pair_List, roots_List] :=
  Map[TRFieldDecompose[#1, roots] &, pair, {3}];

TRDecomposeStripRecord[record_Association, frame_Association] := Module[
  {classification, roots, usedRoots, strip, channelStrip, reconstructed,
   exact},
  classification = TRClassifyStripRecord[record, frame];
  If[Lookup[classification, "Status", None] =!= "ExactRootClassification",
    Return[classification]];
  roots = TRCurrentRoots[frame, record["Variables"]];
  usedRoots = roots[[classification["RootIndices"]]];
  strip = record["Strip"];
  channelStrip = trDecomposePair[#1, usedRoots] & /@ strip;
  If[! FreeQ[channelStrip, $Failed],
    Return[Join[classification,
      <|"Status" -> "ChannelDecompositionFailed"|>]]];
  reconstructed = Map[TRFieldCompose[#1, usedRoots] &,
    channelStrip, {4}];
  exact = trZeroQ[reconstructed - strip];
  Join[classification, <|
    "Status" -> If[exact, "ExactChannelDecomposition",
      "ChannelRoundTripFailed"],
    "Roots" -> usedRoots,
    "ChannelStrip" -> channelStrip,
    "ChannelCount" -> 2^Length[usedRoots],
    "RoundTripExact" -> exact|>]
];

trScalarOneForms[pair : {first_List, second_List}] := Module[
  {dimensions = Dimensions[first]},
  If[Dimensions[second] =!= dimensions || Length[dimensions] =!= 2,
    Return[{}]];
  Flatten[Table[{first[[i, j]], second[[i, j]]},
    {i, dimensions[[1]]}, {j, dimensions[[2]]}], 1]
];

trClosedOneFormQ[form : {_, _}, variables : {x_, y_}] :=
  TrueQ[Together[D[form[[2]], x] - D[form[[1]], y]] === 0];

trOneFormKey[form : {_, _}, roots_List] := Module[{channels},
  channels = TRFieldDecompose[#1, roots] & /@ form;
  If[MemberQ[channels, $Failed], $Failed,
    Hash[Together /@ Flatten[channels], "SHA256", "HexString"]]
];

trDeduplicateOneForms[forms_List, roots_List, variables_List] := Module[
  {valid, tagged},
  valid = Select[forms,
    ! trZeroQ[#1] && FreeQ[#1, _Symbol?(StringStartsQ[SymbolName[#1], "eps"] &)] &&
      trClosedOneFormQ[#1, variables] &];
  tagged = Cases[Map[{trOneFormKey[#1, roots], #1} &, valid],
    {key_ /; key =!= $Failed, form_} :> {key, form}];
  Last /@ DeleteDuplicatesBy[tagged, First]
];

TRDiagonalOneFormBasis[strip : {e_List, c_List, _List}, roots_List,
    variables : {_Symbol, _Symbol}] :=
  trDeduplicateOneForms[
    Join[trScalarOneForms[e], trScalarOneForms[c]], roots, variables];

TRCandidateOneFormBasis[strip : {e_List, c_List, bbar_List}, roots_List,
    variables : {x_, y_}, epsilon_Symbol] := Module[
  {diagonal, samples = {0, 1, -1, 2}, forcingEntries,
   functions, dlogs, combined},
  diagonal = TRDiagonalOneFormBasis[strip, roots, variables];
  forcingEntries = Flatten[bbar];
  functions = DeleteDuplicates[Flatten[Table[
    Together[entry /. epsilon -> value],
    {entry, forcingEntries}, {value, samples}]]];
  functions = Select[functions,
    ! TrueQ[Together[#1] === 0] && ! FreeQ[#1, Alternatives @@ variables] &];
  dlogs = ({Together[D[#1, x]/#1], Together[D[#1, y]/#1]} &) /@
    functions;
  combined = trDeduplicateOneForms[Join[diagonal, dlogs], roots, variables];
  <|"OneForms" -> combined,
    "DiagonalCount" -> Length[diagonal],
    "ForcingDLogCandidates" -> Length[dlogs],
    "DeduplicatedCount" -> Length[combined]|>
];

TRRationalGaugeDenominator[channelForcing_, variables_List] := Module[
  {entries, factorPairs, factors, powers},
  entries = Flatten[channelForcing];
  factorPairs = Flatten[Map[
    Function[entry, Module[{denominator = Denominator[Together[entry]]},
      If[TrueQ[denominator === 1], {},
        Select[Rest[FactorList[denominator]],
          ! TrueQ[NumericQ[First[#1]]] &]]]], entries], 1];
  If[factorPairs === {}, Return[1]];
  factors = DeleteDuplicates[factorPairs[[All, 1]], SameQ];
  powers = Table[{factor, Max[Cases[factorPairs,
      {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
    {factor, factors}];
  Together[Times @@ ((First[#1]^(Max[0, Last[#1] - 1])) & /@
    Select[powers, ! FreeQ[First[#1], Alternatives @@ variables] &])]
];

End[];
EndPackage[];
