(* Exact sparse propagation of one completed off-diagonal block row.

   For a consecutive row block rk = start ;; stop and a gauge block

     D = D[[rk, 1 ;; start - 1]],   T = 1 + D,

   block lower triangularity gives D^2 = D dD = D A D = 0, hence

     A' = A + A D - D A - dD,
     S' = S + S D,       S'^-1 = S^-1 - D S^-1.

   The dense implementation in Scripts/family_epsform_sector.wls used
   Dot followed by Together on every entry of large rectangular slices.
   With algebraic entries that normalized hundreds of entries whose
   correction was structurally zero (CF300 sector 8: 1197.4 s).  This
   implementation intersects literal nonzero supports, combines every
   correction to an output entry, and calls Together exactly once only
   when that entry is touched.  Untouched entries are preserved verbatim. *)

ClearAll[familyRowGaugeSupport, familyRowGaugeDLogForm,
  familyRowGaugeDecodeCheckpoint, familyRowGaugeCheckpointGaugeShapeQ,
  familyRowGaugeCheckpointStripSolversQ,
  familyRowGaugeAssembleInstalledRow, familyRowGaugeApply];

familyRowGaugeSupport[entries_List] :=
  Flatten[Position[entries, Except[0], {1}, Heads -> False]];

(* Materialize the compact dlog row reported by an accepted strip solver.
   A framed solution keeps the constant residue matrices in InnerSolution
   while its Alphabet has already been pulled back to the source frame. *)
familyRowGaugeDLogForm[solution_Association,
    variables : {_, _}, epsilon_, dimensions : {_Integer, _Integer}] :=
 Module[{alphabet, residues, inner, dlog},
  If[Lookup[solution, "Method", None] === "ZeroForcing",
    Return[ConstantArray[0, Prepend[dimensions, 2]]]];
  alphabet = Lookup[solution, "Alphabet", Missing["NoAlphabet"]];
  inner = Lookup[solution, "InnerSolution", <||>];
  residues = Lookup[solution, "ResidueMatrices",
    If[AssociationQ[inner],
      Lookup[inner, "ResidueMatrices", Missing["NoResidues"]],
      Missing["NoResidues"]]];
  If[! ListQ[alphabet] || ! ListQ[residues] ||
      Length[alphabet] =!= Length[residues] ||
      ! AllTrue[residues, Dimensions[#] === dimensions &],
    Return[Missing["MaterializedDLogUnavailable"]]];
  If[alphabet === {},
    Return[ConstantArray[0, Prepend[dimensions, 2]]]];
  dlog = Table[Together[D[Log[alphabet[[a]]], variables[[mu]]]],
    {a, Length[alphabet]}, {mu, 2}];
  Table[epsilon Total[MapThread[Times,
      {residues, dlog[[All, mu]]}]], {mu, 2}]
];

(* PrevD is maintained in CANONICA's regulator context, while SolvedForms
   is a source-frame one-form installed directly into the family connection.
   Decode the two fields separately so a resumed checkpoint cannot inject
   CANONICA`eps into the source-frame connection. *)
familyRowGaugeDecodeCheckpoint[checkpoint_Association,
    sourceEpsilon_Symbol, canonicaEpsilon_Symbol] := Module[{solvedForms},
  solvedForms = Lookup[checkpoint, "SolvedForms", <||>];
  If[! AssociationQ[solvedForms], solvedForms = <||>];
  <|"PrevD" ->
      (Lookup[checkpoint, "PrevD", Missing["NoPrevD"]] /.
        sourceEpsilon -> canonicaEpsilon),
    "SolvedForms" -> solvedForms|>
];

(* A strip checkpoint is written after complete lower blocks are prepended
   to PrevD.  Accept only a rectangular row gauge whose width ends on one of
   those block boundaries; the reconstruction loop must never slice a ragged
   or mid-block checkpoint using the first row's width. *)
familyRowGaugeCheckpointGaugeShapeQ[prevD_, rowSize_Integer?Positive,
    lowerBlockSizes : {___Integer?Positive}] := Module[
  {rowWidths, validWidths},
  If[! ListQ[prevD] || Length[prevD] =!= rowSize ||
      ! AllTrue[prevD, ListQ], Return[False]];
  rowWidths = Length /@ prevD;
  If[Length[DeleteDuplicates[rowWidths]] =!= 1, Return[False]];
  validWidths = FoldList[Plus, 0, Reverse[lowerBlockSizes]];
  MemberQ[validWidths, First[rowWidths]]
];
familyRowGaugeCheckpointGaugeShapeQ[___] := False;

(* The saved summaries are the check provenance of the complete suffix
   represented by PrevD.  Require one ordered summary per recovered block so
   a missing field cannot turn AllTrue[{}] into a positive sector certificate. *)
familyRowGaugeCheckpointStripSolversQ[stripSolvers_, prevD_,
    sector_Integer?Positive,
    lowerBlockSizes : {___Integer?Positive}] := Module[
  {width, validWidths, position, solvedCount, expectedLowerSectors},
  If[sector =!= Length[lowerBlockSizes] + 1 || ! ListQ[stripSolvers] ||
      ! AllTrue[stripSolvers, AssociationQ] || ! ListQ[prevD] || prevD === {},
    Return[False]];
  width = Length[First[prevD]];
  validWidths = FoldList[Plus, 0, Reverse[lowerBlockSizes]];
  position = FirstPosition[validWidths, width, Missing["InvalidWidth"]];
  If[MissingQ[position], Return[False]];
  solvedCount = First[position] - 1;
  expectedLowerSectors = Take[Reverse[Range[sector - 1]], solvedCount];
  Length[stripSolvers] === solvedCount &&
    (Lookup[#, "Sector", Missing["NoSector"]] & /@ stripSolvers) ===
      ConstantArray[sector, solvedCount] &&
    (Lookup[#, "LowerSector", Missing["NoLowerSector"]] & /@
        stripSolvers) === expectedLowerSectors
];
familyRowGaugeCheckpointStripSolversQ[___] := False;

(* Assemble a complete materialized row only when every solved block has a
   well-formed one-form on an exact partition of the lower columns.  Any
   missing or malformed checkpoint field falls back to the sparse gauge
   formula; never partially install a saved row. *)
familyRowGaugeAssembleInstalledRow[solvedForms_Association,
    solvedBlocks_Association, rowSize_Integer?Positive,
    lowerSize_Integer?NonNegative, blockColumns_Association] := Module[
  {keys, columns, forms, blocks, validColumnsQ, validDimensionsQ, pair},
  keys = Keys[solvedBlocks];
  If[Sort[Keys[solvedForms]] =!= Sort[keys] ||
      Sort[Keys[blockColumns]] =!= Sort[keys], Return[Automatic]];
  columns = Lookup[blockColumns, keys];
  validColumnsQ = AllTrue[columns,
      VectorQ[#, IntegerQ] && Length[DeleteDuplicates[#]] === Length[#] &] &&
    Sort[Flatten[columns]] === Range[lowerSize];
  If[! validColumnsQ, Return[Automatic]];
  forms = Lookup[solvedForms, keys];
  blocks = Lookup[solvedBlocks, keys];
  validDimensionsQ = And @@ MapThread[
    Dimensions[#1] === {2, rowSize, Length[#3]} &&
      Dimensions[#2] === {rowSize, Length[#3]} &,
    {forms, blocks, columns}];
  If[! validDimensionsQ, Return[Automatic]];
  pair = ConstantArray[0, {2, rowSize, lowerSize}];
  Do[pair[[All, All, columns[[i]]]] = forms[[i]], {i, Length[keys]}];
  pair
];
familyRowGaugeAssembleInstalledRow[___] := Automatic;

(* "Deferred" is an explicit preparation mode: a complete materialized
   current row is installed, while only later A rows retain their exact raw
   base + correction sums.  The default keeps the established Together
   semantics; S and SInverse are identical in both modes. *)
familyRowGaugeApply[
    connection : {_List, _List}, transformation_List,
    inverse_List, rowIndices_List, gauge_List,
    variables : {_, _}, installedRow_: Automatic,
    futureAMode_: "Together"] := Module[
  {n, start, stop, lowerColumns, futureRows, rowSize, lowerSize,
   validSquare, upperBlockZeroQ, newConnection, newTransformation,
   newInverse, gaugeRowSupport, gaugeColumnSupport, statistics,
   aProducts = 0, aTouched = 0, aNormalizationSeconds = 0.,
   aStageSeconds = 0.,
   aSingleTerm = 0, aInstalled = 0, aFutureProducts = 0,
   aFutureTouched = 0, aDeferredFuture = 0, installedRowQ,
   installedRowCompleteQ,
   sProducts = 0, sTouched = 0, sNormalizationSeconds = 0.,
   sStageSeconds = 0.,
   sSingleTerm = 0,
   siProducts = 0, siTouched = 0, siNormalizationSeconds = 0.,
   siStageSeconds = 0.,
   siSingleTerm = 0,
   started = AbsoluteTime[], stageStarted, mu, aRight, aLower, derivative,
   aRightRowSupport, aLowerColumnSupport, supportAD, supportDA,
   correction, correctionTerms, base, normalizedAt, leftS,
   leftSRowSupport, supportS,
   rightInverse, rightInverseColumnSupport, supportSi, i, j},

  validSquare[m_] := MatrixQ[m] && Length[m] > 0 &&
    Dimensions[m] === {Length[m], Length[m]};
  If[! (validSquare /@ connection === {True, True}) ||
      Dimensions[connection[[1]]] =!= Dimensions[connection[[2]]] ||
      ! validSquare[transformation] || ! validSquare[inverse] ||
      Dimensions[transformation] =!= Dimensions[connection[[1]]] ||
      Dimensions[inverse] =!= Dimensions[connection[[1]]],
    Return[<|"Status" -> "InvalidDimensions",
      "Reason" -> "connection, transformation, and inverse must have one common square dimension"|>]];

  n = Length[transformation];
  If[rowIndices === {} || ! VectorQ[rowIndices, IntegerQ] ||
      rowIndices =!= Range[First[rowIndices], Last[rowIndices]] ||
      First[rowIndices] <= 1 || Last[rowIndices] > n,
    Return[<|"Status" -> "InvalidRowBlock",
      "Reason" -> "row indices must be a nonempty consecutive block after the first row"|>]];
  {start, stop} = {First[rowIndices], Last[rowIndices]};
  lowerColumns = Range[start - 1];
  futureRows = Range[start, n];
  rowSize = Length[rowIndices]; lowerSize = Length[lowerColumns];
  If[! MatrixQ[gauge] || Dimensions[gauge] =!= {rowSize, lowerSize},
    Return[<|"Status" -> "InvalidGaugeDimensions",
      "Expected" -> {rowSize, lowerSize},
      "Actual" -> Quiet[Check[Dimensions[gauge], Missing["NotAMatrix"]]]|>]];
  installedRowQ = installedRow =!= Automatic &&
    Dimensions[installedRow] === {2, rowSize, lowerSize};
  installedRowCompleteQ = installedRowQ && FreeQ[installedRow,
    Alternatives[_Missing, Automatic, $Failed]];
  If[installedRow =!= Automatic && ! installedRowQ,
    Return[<|"Status" -> "InvalidInstalledRowDimensions",
      "Expected" -> {2, rowSize, lowerSize},
      "Actual" -> Quiet[Check[Dimensions[installedRow],
        Missing["NotAnArray"]]]|>]];
  If[! MemberQ[{"Together", "Deferred"}, futureAMode],
    Return[<|"Status" -> "InvalidFutureAMode",
      "Allowed" -> {"Together", "Deferred"},
      "Actual" -> futureAMode|>]];
  If[futureAMode === "Deferred" && ! installedRowCompleteQ,
    Return[<|"Status" ->
      "DeferredFutureARequiresCompleteInstalledRow"|>]];

  (* This is the exact structural condition used by the shortened gauge
     formula.  Refuse a non-lower-block-triangular input rather than
     silently dropping D A D. *)
  upperBlockZeroQ = AllTrue[
    Flatten[connection[[All, lowerColumns, rowIndices]]], SameQ[#, 0] &];
  If[! upperBlockZeroQ,
    Return[<|"Status" -> "InvalidBlockStructure",
      "Reason" -> "A[[lower columns, row block]] is not structurally zero; D.A.D may be nonzero"|>]];

  newConnection = connection;
  newTransformation = transformation;
  newInverse = inverse;
  gaugeRowSupport = familyRowGaugeSupport /@ gauge;
  gaugeColumnSupport = familyRowGaugeSupport /@ Transpose[gauge];

  stageStarted = AbsoluteTime[];
  Do[
    aRight = connection[[mu, futureRows, rowIndices]];
    aLower = connection[[mu, lowerColumns, lowerColumns]];
    derivative = D[gauge, variables[[mu]]];
    aRightRowSupport = familyRowGaugeSupport /@ aRight;
    aLowerColumnSupport = familyRowGaugeSupport /@ Transpose[aLower];
    Do[
      If[installedRowQ && i <= rowSize,
        base = connection[[mu, futureRows[[i]], lowerColumns[[j]]]];
        newConnection[[mu, futureRows[[i]], lowerColumns[[j]]]] =
          installedRow[[mu, i, j]];
        If[! SameQ[base, installedRow[[mu, i, j]]], aTouched++];
        aInstalled++;
        Continue[]];
      supportAD = Intersection[
        aRightRowSupport[[i]], gaugeColumnSupport[[j]]];
      supportDA = If[i <= rowSize,
        Intersection[gaugeRowSupport[[i]],
          aLowerColumnSupport[[j]]], {}];
      aProducts += Length[supportAD] + Length[supportDA];
      If[i > rowSize, aFutureProducts += Length[supportAD]];
      correctionTerms = Join[
        (aRight[[i, #]] gauge[[#, j]] &) /@ supportAD,
        If[i <= rowSize,
          Join[(-gauge[[i, #]] aLower[[#, j]] &) /@ supportDA,
            {-derivative[[i, j]]}], {}]];
      correctionTerms = DeleteCases[correctionTerms, 0];
      correction = Total[correctionTerms];
      If[! SameQ[correction, 0],
        base = connection[[mu, futureRows[[i]], lowerColumns[[j]]]];
        If[futureAMode === "Deferred" && i > rowSize,
          newConnection[[mu, futureRows[[i]], lowerColumns[[j]]]] =
            base + correction;
          aDeferredFuture++,
        If[SameQ[base, 0] && Length[correctionTerms] === 1,
          newConnection[[mu, futureRows[[i]], lowerColumns[[j]]]] =
            First[correctionTerms];
          aSingleTerm++,
          normalizedAt = AbsoluteTime[];
          newConnection[[mu, futureRows[[i]], lowerColumns[[j]]]] =
            Together[base + correction];
          aNormalizationSeconds += AbsoluteTime[] - normalizedAt]];
        aTouched++;
        If[i > rowSize, aFutureTouched++]],
      {i, Length[futureRows]}, {j, lowerSize}],
    {mu, 2}];
  aStageSeconds = AbsoluteTime[] - stageStarted;

  stageStarted = AbsoluteTime[];
  leftS = transformation[[All, rowIndices]];
  leftSRowSupport = familyRowGaugeSupport /@ leftS;
  Do[
    supportS = Intersection[
      leftSRowSupport[[i]], gaugeColumnSupport[[j]]];
    sProducts += Length[supportS];
    If[supportS =!= {},
      correctionTerms =
        (leftS[[i, #]] gauge[[#, j]] &) /@ supportS;
      correction = Total[correctionTerms];
      If[! SameQ[correction, 0],
        base = transformation[[i, lowerColumns[[j]]]];
        If[SameQ[base, 0] && Length[correctionTerms] === 1,
          newTransformation[[i, lowerColumns[[j]]]] =
            First[correctionTerms];
          sSingleTerm++,
          normalizedAt = AbsoluteTime[];
          newTransformation[[i, lowerColumns[[j]]]] =
            Together[base + correction];
          sNormalizationSeconds += AbsoluteTime[] - normalizedAt];
        sTouched++]],
    {i, n}, {j, lowerSize}];
  sStageSeconds = AbsoluteTime[] - stageStarted;

  stageStarted = AbsoluteTime[];
  rightInverse = inverse[[lowerColumns, All]];
  rightInverseColumnSupport =
    familyRowGaugeSupport /@ Transpose[rightInverse];
  Do[
    supportSi = Intersection[gaugeRowSupport[[i]],
      rightInverseColumnSupport[[j]]];
    siProducts += Length[supportSi];
    If[supportSi =!= {},
      correctionTerms =
        (-gauge[[i, #]] rightInverse[[#, j]] &) /@ supportSi;
      correction = Total[correctionTerms];
      If[! SameQ[correction, 0],
        base = inverse[[rowIndices[[i]], j]];
        If[SameQ[base, 0] && Length[correctionTerms] === 1,
          newInverse[[rowIndices[[i]], j]] = First[correctionTerms];
          siSingleTerm++,
          normalizedAt = AbsoluteTime[];
          newInverse[[rowIndices[[i]], j]] = Together[base + correction];
          siNormalizationSeconds += AbsoluteTime[] - normalizedAt];
        siTouched++]],
    {i, rowSize}, {j, n}];
  siStageSeconds = AbsoluteTime[] - stageStarted;

  statistics = <|
    "A" -> <|"CandidateEntries" ->
        2 Length[futureRows] lowerSize,
      "Products" -> aProducts, "Touched" -> aTouched,
      "SingleTermFastPath" -> aSingleTerm,
      "InstalledRowEntries" -> aInstalled,
      "FutureCandidateEntries" -> 2 (n - stop) lowerSize,
      "FutureProducts" -> aFutureProducts,
      "FutureTouched" -> aFutureTouched,
      "DeferredFutureEntries" -> aDeferredFuture,
      "FutureAMode" -> futureAMode,
      "StageSeconds" -> N[aStageSeconds],
      "NormalizationSeconds" -> N[aNormalizationSeconds]|>,
    "S" -> <|"CandidateEntries" -> n lowerSize,
      "Products" -> sProducts, "Touched" -> sTouched,
      "SingleTermFastPath" -> sSingleTerm,
      "StageSeconds" -> N[sStageSeconds],
      "NormalizationSeconds" -> N[sNormalizationSeconds]|>,
    "SInverse" -> <|"CandidateEntries" -> rowSize n,
      "Products" -> siProducts, "Touched" -> siTouched,
      "SingleTermFastPath" -> siSingleTerm,
      "StageSeconds" -> N[siStageSeconds],
      "NormalizationSeconds" -> N[siNormalizationSeconds]|>,
    "TotalSeconds" -> N[AbsoluteTime[] - started]|>;
  <|"Status" -> "OK", "Connection" -> newConnection,
    "Transformation" -> newTransformation, "Inverse" -> newInverse,
    "Statistics" -> statistics|>
];
