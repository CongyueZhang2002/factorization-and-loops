#!/usr/bin/env wolframscript

(* A deferred-only square-root generator must reach preparation even when the
   visible off-diagonal inhomogeneity is the deliberate zero placeholder. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{solve, rootCensus, rootOrder, presentationRoots,
  rootExpression, rootRadicand} = mq /@ {
  "solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators",
  "multiquadraticOffDiagonalBlockRootCensusWithBundle",
  "multiquadraticOffDiagonalBlockRootOrder",
  "coefficientPresentationSquareRootsInVariables",
  "squareRootRecordExpression", "squareRootRecordRadicand"};

Clear[x, y, eps, cx, cy];
frame = BuildSquareRootGeneratorsAndQuadraticRelations[
  {x, y}, {x, y}, {cx, cy}];
allRoots = presentationRoots[frame, {x, y}];
deferredPosition = FirstPosition[rootRadicand /@ allRoots,
  candidate_ /; TrueQ[Quiet[Together[candidate - y]] === 0]];
FTAssert["the declared frame contains the deferred radical exactly once",
  MatchQ[deferredPosition, {_Integer}] &&
    Count[rootRadicand /@ allRoots,
      candidate_ /; TrueQ[Quiet[Together[candidate - y]] === 0]] === 1];
If[! MatchQ[deferredPosition, {_Integer}], FTReport[]; Quit[1]];
deferredIndex = First[deferredPosition];
deferredRoot = rootExpression[allRoots[[deferredIndex]]];

zero11 = {{{0}}, {{0}}};
visibleEquation = {zero11, zero11, zero11};
visibleCensus = rootCensus[visibleEquation, allRoots, {x, y}, eps,
  Missing["NoDeferredBundle"]];
FTAssert["the visible zero placeholder has no active radical",
  Lookup[visibleCensus, "RootIndices", Missing["Absent"]] === {} &&
    Lookup[visibleCensus, "UnclassifiedRadicalBases",
      Missing["Absent"]] === {}];

deferredPreparation = <|
  "Preparation" -> <|
    "DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 2,
    "Status" -> "Prepared", "Variables" -> {x, y},
    "Regulator" -> eps, "Dimensions" -> {2, 1, 1},
    "Records" -> {<|"Target" -> {1, 1, 1},
      "Terms" -> {<|"Coefficient" -> 1,
        "Operands" -> {deferredRoot}|>}|>}|>,
  "CoefficientPresentation" -> frame,
  "SquareRootGeneratorIndices" -> {deferredIndex},
  "ProjectionSquareRootGeneratorIndices" -> {deferredIndex}|>;
record = <|"Family" -> "DEFERRED_ROOT_FORWARDING", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {x, y}, "Regulator" -> eps,
  "OffDiagonalBlockEquation" -> visibleEquation,
  "DeferredPreparation" -> deferredPreparation|>;

captured = Block[{FeynFacet`Private`multiquadraticOffDiagonalBlockPrepare},
  FeynFacet`Private`multiquadraticOffDiagonalBlockPrepare[
      _Association, _Association, options___] := Module[
    {optionList = Flatten[{options}], optionAssociation},
    optionAssociation = Association[optionList];
    <|"Status" -> "DeferredRootPreparationOptionsCaptured",
      "ForwardedRootIndices" ->
        Lookup[optionAssociation, "RootIndices", Missing["Absent"]],
      "RootIndicesRuleCount" -> Count[optionList,
        HoldPattern[("RootIndices" -> _) | ("RootIndices" :> _)] ]|>];
  solve[record, frame,
    "DeferredPreparationFile" ->
      "not-opened-before-the-preparation-capture.wl",
    "OneForms" -> {{0, 0}},
    "OffDiagonalBasisTransformationDenominator" -> 1,
    "OffDiagonalBasisTransformationDenominatorFactor" -> 1,
    "Support" -> {{0, 0}}, "CompileCore" -> False,
    "IntegrabilityScreen" -> False, "ScreenFirst" -> False,
    "OffDiagonalBasisTransformationBlockScreen" -> False,
    "DegreeOffsetLadder" -> None, "RegulatorReconstruction" -> False,
    "Verbose" -> False]
];

forwardedOrder = rootOrder[frame, {x, y},
  Lookup[captured, "ForwardedRootIndices", {}], eps];
FTAssert["the driver passes one resolved RootIndices rule to preparation",
  Lookup[captured, "Status", None] ===
      "DeferredRootPreparationOptionsCaptured" &&
    Lookup[captured, "RootIndicesRuleCount", 0] === 1 &&
    Lookup[captured, "ForwardedRootIndices", None] === {deferredIndex}];
FTAssert["the forwarded preparation field is exactly the deferred radical",
  Lookup[forwardedOrder, "Status", None] === "StableRootOrder" &&
    Length[forwardedOrder["Roots"]] === 1 &&
    TrueQ[Quiet[Together[
      rootRadicand[First[forwardedOrder["Roots"]]] - y]] === 0] &&
    ! FreeQ[deferredPreparation["Preparation", "Records"],
      deferredRoot, Infinity]];

FTReport[];
