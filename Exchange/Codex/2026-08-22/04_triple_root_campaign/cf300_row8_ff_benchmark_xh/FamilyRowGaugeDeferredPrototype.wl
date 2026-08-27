(* Isolated CF-family row-gauge prototype.  This is not loaded by FeynFacet.m.

   The current row is installed from its already-certified dlog form.  Only
   future-row A corrections are kept as exact unnormalized sums.  S and
   SInverse retain the package's existing sparse single-term/Together rules. *)

BeginPackage["CodexRowGaugeDeferred`"];
ApplyDeferredFutureRowGauge::usage =
  "ApplyDeferredFutureRowGauge[A,S,Si,rows,D,{x,y},installed] installs the certified current A row and defers Together only on future-row A corrections.";
Begin["`Private`"];

ClearAll[deferredSupport, ApplyDeferredFutureRowGauge];
deferredSupport[entries_List] :=
  Flatten[Position[entries, Except[0], {1}, Heads -> False]];

ApplyDeferredFutureRowGauge[connection : {_List, _List},
    transformation_List, inverse_List, rowIndices_List, gauge_List,
    variables : {_, _}, installedRow_] := Module[
  {started = AbsoluteTime[], n, start, stop, lowerColumns, futureRows,
   rowSize, lowerSize, newConnection = connection,
   newTransformation = transformation, newInverse = inverse,
   gaugeRowSupport, gaugeColumnSupport, aRight, aRightRowSupport,
   support, terms, base, leftS, leftSRowSupport, rightInverse,
   rightInverseColumnSupport, futureTouched = 0, futureProducts = 0,
   sTouched = 0, sProducts = 0, siTouched = 0, siProducts = 0,
   sTogether = 0, siTogether = 0, normalizedAt, stageStarted,
   aSeconds, sSeconds, siSeconds, mu, i, j},
  If[! MatchQ[connection, {_List, _List}] ||
      Dimensions[connection[[1]]] =!= Dimensions[connection[[2]]] ||
      Dimensions[transformation] =!= Dimensions[inverse] ||
      Dimensions[transformation] =!= Dimensions[connection[[1]]],
    Return[<|"Status" -> "InvalidDimensions"|>]];
  n = Length[transformation];
  If[rowIndices === {} || rowIndices =!=
      Range[First[rowIndices], Last[rowIndices]],
    Return[<|"Status" -> "InvalidRowBlock"|>]];
  {start, stop} = {First[rowIndices], Last[rowIndices]};
  lowerColumns = Range[start - 1];
  futureRows = Range[stop + 1, n];
  rowSize = Length[rowIndices]; lowerSize = Length[lowerColumns];
  If[Dimensions[gauge] =!= {rowSize, lowerSize} ||
      Dimensions[installedRow] =!= {2, rowSize, lowerSize},
    Return[<|"Status" -> "InvalidGaugeDimensions"|>]];
  If[! AllTrue[Flatten[connection[[All, lowerColumns, rowIndices]]],
      SameQ[#, 0] &], Return[<|"Status" -> "InvalidBlockStructure"|>]];

  newConnection[[All, rowIndices, lowerColumns]] = installedRow;
  gaugeRowSupport = deferredSupport /@ gauge;
  gaugeColumnSupport = deferredSupport /@ Transpose[gauge];

  stageStarted = AbsoluteTime[];
  Do[
    aRight = connection[[mu, futureRows, rowIndices]];
    aRightRowSupport = deferredSupport /@ aRight;
    Do[
      support = Intersection[aRightRowSupport[[i]],
        gaugeColumnSupport[[j]]];
      futureProducts += Length[support];
      If[support =!= {},
        terms = (aRight[[i, #]] gauge[[#, j]] &) /@ support;
        If[! SameQ[Total[terms], 0],
          base = connection[[mu, futureRows[[i]], lowerColumns[[j]]]];
          newConnection[[mu, futureRows[[i]], lowerColumns[[j]]]] =
            base + Total[terms];
          futureTouched++]],
      {i, Length[futureRows]}, {j, lowerSize}],
    {mu, 2}];
  aSeconds = AbsoluteTime[] - stageStarted;

  stageStarted = AbsoluteTime[];
  leftS = transformation[[All, rowIndices]];
  leftSRowSupport = deferredSupport /@ leftS;
  Do[
    support = Intersection[leftSRowSupport[[i]],
      gaugeColumnSupport[[j]]];
    sProducts += Length[support];
    If[support =!= {},
      terms = (leftS[[i, #]] gauge[[#, j]] &) /@ support;
      If[! SameQ[Total[terms], 0],
        base = transformation[[i, lowerColumns[[j]]]];
        If[SameQ[base, 0] && Length[terms] === 1,
          newTransformation[[i, lowerColumns[[j]]]] = First[terms],
          normalizedAt = AbsoluteTime[];
          newTransformation[[i, lowerColumns[[j]]]] =
            Together[base + Total[terms]];
          sTogether += AbsoluteTime[] - normalizedAt];
        sTouched++]],
    {i, n}, {j, lowerSize}];
  sSeconds = AbsoluteTime[] - stageStarted;

  stageStarted = AbsoluteTime[];
  rightInverse = inverse[[lowerColumns, All]];
  rightInverseColumnSupport =
    deferredSupport /@ Transpose[rightInverse];
  Do[
    support = Intersection[gaugeRowSupport[[i]],
      rightInverseColumnSupport[[j]]];
    siProducts += Length[support];
    If[support =!= {},
      terms = (-gauge[[i, #]] rightInverse[[#, j]] &) /@ support;
      If[! SameQ[Total[terms], 0],
        base = inverse[[rowIndices[[i]], j]];
        If[SameQ[base, 0] && Length[terms] === 1,
          newInverse[[rowIndices[[i]], j]] = First[terms],
          normalizedAt = AbsoluteTime[];
          newInverse[[rowIndices[[i]], j]] =
            Together[base + Total[terms]];
          siTogether += AbsoluteTime[] - normalizedAt];
        siTouched++]],
    {i, rowSize}, {j, n}];
  siSeconds = AbsoluteTime[] - stageStarted;

  <|"Status" -> "OK", "Connection" -> newConnection,
    "Transformation" -> newTransformation, "Inverse" -> newInverse,
    "Statistics" -> <|"FutureA" -> <|"Touched" -> futureTouched,
        "Products" -> futureProducts, "StageSeconds" -> N[aSeconds]|>,
      "S" -> <|"Touched" -> sTouched, "Products" -> sProducts,
        "TogetherSeconds" -> N[sTogether], "StageSeconds" -> N[sSeconds]|>,
      "SInverse" -> <|"Touched" -> siTouched, "Products" -> siProducts,
        "TogetherSeconds" -> N[siTogether],
        "StageSeconds" -> N[siSeconds]|>,
      "TotalSeconds" -> N[AbsoluteTime[] - started]|>|>
];

ApplyDeferredFutureRowGauge[___] := <|"Status" -> "InvalidInput"|>;
End[];
EndPackage[];
