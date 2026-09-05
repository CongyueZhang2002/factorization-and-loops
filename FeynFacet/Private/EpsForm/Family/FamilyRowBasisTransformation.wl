(* Exact sparse propagation of one completed off-diagonal block row.

   For a consecutive row block rk = start ;; stop and a basis-transformation block block

     D = D[[rk, 1 ;; start - 1]],   T = 1 + D,

   block lower triangularity gives D^2 = D dD = D A D = 0, hence

     A' = A + A D - D A - dD,
     S' = S + S D,       S'^-1 = S^-1 - D S^-1.

   The dense implementation in Scripts/family_epsform_sector.wls used
   Dot followed by Together on every entry of large rectangular slices.
   With algebraic entries that normalized hundreds of entries whose
   correction was structurally zero (measured: 1197.4 s).  This
   implementation intersects literal nonzero supports, combines every
   correction to an output entry, and calls Together exactly once only
   when that entry is touched.  Untouched entries are preserved verbatim. *)

ClearAll[familyRowBasisTransformationSupport, familyRowBasisTransformationDLogForm,
  familyRowBasisTransformationDecodeCheckpoint, familyRowBasisTransformationCheckpointShapeQ,
  familyRowBasisTransformationOffDiagonalBlockAcceptanceRecordQ,
  familyRowBasisTransformationCheckpointOffDiagonalBlockSolutionsQ,
  familyRowBasisTransformationAssembleInstalledRow, familyRowBasisTransformationApply];

familyRowBasisTransformationSupport[entries_List] :=
  Flatten[Position[entries, Except[0], {1}, Heads -> False]];

(* Materialize the compact dlog row reported by an accepted off-diagonal block equation solver.
   A framed solution keeps the constant residue matrices in InnerSolution
   while its Alphabet has already been pulled back to the source frame. *)
familyRowBasisTransformationDLogForm[solution_Association,
    variables : {_, _}, epsilon_, dimensions : {_Integer, _Integer}] :=
 Module[{alphabet, residues, inner, dlog, certifiedForms, useCertifiedForms},
  If[Lookup[solution, "Method", None] === "ZeroInhomogeneity",
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
  useCertifiedForms =
    Lookup[solution, "SolutionContract", None] ===
      "InstallableMultiquadraticDLogV1" &&
    TrueQ[Lookup[solution, "OneFormsCertified", False]];
  If[useCertifiedForms,
    certifiedForms = Lookup[solution, "OneForms", Missing["NoOneForms"]];
    If[! ListQ[certifiedForms] ||
        ! AllTrue[certifiedForms, MatchQ[#1, {_, _}] &] ||
        Length[certifiedForms] =!= Length[alphabet] ||
        ! FreeQ[certifiedForms, epsilon],
      Return[Missing["MaterializedDLogUnavailable"]]];
    dlog = certifiedForms,
    dlog = Table[Together[D[Log[alphabet[[a]]], variables[[mu]]]],
      {a, Length[alphabet]}, {mu, 2}]];
  Table[epsilon Total[MapThread[Times,
      {residues, dlog[[All, mu]]}]], {mu, 2}]
];

(* PrevD is maintained in CANONICA's regulator context, while SolvedForms
   is a source-frame one-form installed directly into the family connection.
   Decode the two fields separately so a resumed checkpoint cannot inject
   CANONICA`eps into the source-frame connection. *)
familyRowBasisTransformationDecodeCheckpoint[checkpoint_Association,
    sourceEpsilon_Symbol, canonicaEpsilon_Symbol] := Module[{solvedForms},
  solvedForms = Lookup[checkpoint, "SolvedForms", <||>];
  If[! AssociationQ[solvedForms], solvedForms = <||>];
  <|"PrevD" ->
      (Lookup[checkpoint, "PrevD", Missing["NoPrevD"]] /.
        sourceEpsilon -> canonicaEpsilon),
    "SolvedForms" -> solvedForms|>
];

(* A off-diagonal block equation checkpoint is written after complete lower blocks are prepended
   to PrevD.  Accept only a rectangular row basis-transformation block whose width ends on one of
   those block boundaries; the reconstruction loop must never slice a ragged
   or mid-block checkpoint using the first row's width. *)
familyRowBasisTransformationCheckpointShapeQ[prevD_, rowSize_Integer?Positive,
    lowerBlockSizes : {___Integer?Positive}] := Module[
  {rowWidths, validWidths},
  If[! ListQ[prevD] || Length[prevD] =!= rowSize ||
      ! AllTrue[prevD, ListQ], Return[False]];
  rowWidths = Length /@ prevD;
  If[Length[DeleteDuplicates[rowWidths]] =!= 1, Return[False]];
  validWidths = FoldList[Plus, 0, Reverse[lowerBlockSizes]];
  MemberQ[validWidths, First[rowWidths]]
];
familyRowBasisTransformationCheckpointShapeQ[___] := False;

(* Resume admission is mathematical, not operational.  A saved block is
   reusable when its acceptance record says which identity certified it;
   backend, thread, cache, source and implementation provenance are not part
   of that statement. *)
familyRowBasisTransformationOffDiagonalBlockAcceptanceRecordQ[record_Association] := Module[
  {method = Lookup[record, "Method", None],
   certificate = Lookup[record, "Certificate", None], frame,
   validationMode, installation, branchSigns, numericalBaseQ},
  If[method === "ZeroInhomogeneity",
    Return[TrueQ[Lookup[record, "ExactDLog", False]]]];
  If[method === "DirectMultiquadraticFiniteField",
    installation = Lookup[record, "InstallationEvidence", <||>];
    Return[Lookup[record, "SolutionContract", None] ===
        "InstallableMultiquadraticDLogV1" &&
      TrueQ[Lookup[record, "OneFormsCertified", False]] &&
      TrueQ[Lookup[record, "LettersEpsFree", False]] &&
      TrueQ[Lookup[record, "ResiduesKinematicsFree", False]] &&
      AssociationQ[installation] &&
      Lookup[installation, "Status", None] ===
        "InstallationEvidenceAccepted" &&
      Lookup[installation, "Certificate", None] === certificate &&
      MemberQ[{"ExactResidual", "NumericalResidual", "ModularResidual"}, certificate]]];
  frame = Lookup[record, "FrameCertificate", <||>];
  If[StringQ[method] && StringStartsQ[method, "RationalChart/"],
    If[! AssociationQ[frame], Return[False]];
    validationMode = Lookup[frame, "ValidationMode", None];
    branchSigns = Lookup[frame, "BranchSigns", None];
    numericalBaseQ =
      TrueQ[Lookup[frame, "CoordinateComposition", False]] &&
        TrueQ[Lookup[frame, "BasisTransformationCoordinateReexpressionVerified", False]] &&
        MatchQ[branchSigns, {__Integer}] &&
        AllTrue[branchSigns, MemberQ[{-1, 1}, #] &] &&
        MemberQ[{"NumericalResidual", "ModularResidual"},
          Lookup[frame, "InnerCertificate", None]] &&
        IntegerQ[Lookup[frame, "UnseenPrime", None]] &&
        (TrueQ[Lookup[frame, "NumericalPfaffianResidualsZero", False]] ||
          TrueQ[Lookup[frame, "ModularPfaffianResidualsZero", False]]);
    Return[Switch[validationMode,
      "PostMapleFiniteFieldResidual" | "PostPullBackFiniteFieldResidual",
        numericalBaseQ &&
          TrueQ[Lookup[frame, "TransformedOneFormPullBack", False]],
      (* Before a basis-transformation block-normalization stage existed, the chart basis-transformation block and
         coordinate composition were installed literally.  An accepted
         chart-frame residual therefore pulls back functorially; the exact
         composition proof is the mathematical acceptance record. *)
      "CompositionalNumerical",
        numericalBaseQ && Lookup[frame, "BasisTransformationCoordinateReexpressionProof", None] ===
          "ExactCoordinateComposition",
      _, And @@ (TrueQ[Lookup[frame, #, False]] & /@
        {"CoordinateComposition", "BasisTransformationCoordinateReexpressionVerified",
         "TransformedOneFormPullBack", "SourceDLog", "Exact"})]]];
  If[StringQ[method] && StringStartsQ[method, "RationalFrame/"],
    Return[AssociationQ[frame] &&
      And @@ (TrueQ[Lookup[frame, #, False]] & /@
        {"BasisTransformationCoordinateReexpressionVerified", "TransformedOneFormPullBack", "Exact"})]];
  TrueQ[Lookup[record, "ExactDLog", False]] ||
    MemberQ[{"ExactResidual", "NumericalResidual", "ModularResidual"}, certificate]
];
familyRowBasisTransformationOffDiagonalBlockAcceptanceRecordQ[___] := False;

(* The saved summaries are the check provenance of the complete suffix
   represented by PrevD.  Require one ordered summary per recovered block so
   a missing field cannot turn AllTrue[{}] into a positive sector certificate. *)
familyRowBasisTransformationCheckpointOffDiagonalBlockSolutionsQ[offDiagonalBlockSolutions_, prevD_,
    sector_Integer?Positive,
    lowerBlockSizes : {___Integer?Positive}] := Module[
  {width, validWidths, position, solvedCount, expectedLowerSectors},
  If[sector =!= Length[lowerBlockSizes] + 1 || ! ListQ[offDiagonalBlockSolutions] ||
      ! AllTrue[offDiagonalBlockSolutions, AssociationQ] || ! ListQ[prevD] || prevD === {},
    Return[False]];
  width = Length[First[prevD]];
  validWidths = FoldList[Plus, 0, Reverse[lowerBlockSizes]];
  position = FirstPosition[validWidths, width, Missing["InvalidWidth"]];
  If[MissingQ[position], Return[False]];
  solvedCount = First[position] - 1;
  expectedLowerSectors = Take[Reverse[Range[sector - 1]], solvedCount];
  Length[offDiagonalBlockSolutions] === solvedCount &&
    AllTrue[offDiagonalBlockSolutions, familyRowBasisTransformationOffDiagonalBlockAcceptanceRecordQ] &&
    (Lookup[#, "Sector", Missing["NoSector"]] & /@ offDiagonalBlockSolutions) ===
      ConstantArray[sector, solvedCount] &&
    (Lookup[#, "LowerSector", Missing["NoLowerSector"]] & /@
        offDiagonalBlockSolutions) === expectedLowerSectors
];
familyRowBasisTransformationCheckpointOffDiagonalBlockSolutionsQ[___] := False;

(* Materialize the current row from the accepted basis-transformation block and the current
   connection -- the two mathematical objects that define it.  SolvedForms is
   only a disposable cache and never enters this formula.  The raw exact sum
   is intentional: production installs it once and defers later normalization. *)
familyRowBasisTransformationAssembleInstalledRow[connection : {_List, _List},
    rowIndices : {__Integer}, basisTransformationBlock_List, variables : {_, _}] := Module[
  {lowerColumns, rowSize, lowerSize, validSquare},
  validSquare[m_] := MatrixQ[m] && Length[m] > 0 &&
    Dimensions[m] === {Length[m], Length[m]};
  If[! (validSquare /@ connection === {True, True}) ||
      Dimensions[connection[[1]]] =!= Dimensions[connection[[2]]] ||
      rowIndices =!= Range[First[rowIndices], Last[rowIndices]] ||
      First[rowIndices] <= 1 || Last[rowIndices] > Length[connection[[1]]],
    Return[Automatic]];
  lowerColumns = Range[First[rowIndices] - 1];
  rowSize = Length[rowIndices]; lowerSize = Length[lowerColumns];
  If[Dimensions[basisTransformationBlock] =!= {rowSize, lowerSize} ||
      ! AllTrue[Flatten[connection[[All, lowerColumns, rowIndices]]],
        SameQ[#, 0] &],
    Return[Automatic]];
  Table[
    connection[[mu, rowIndices, lowerColumns]] +
      connection[[mu, rowIndices, rowIndices]] . basisTransformationBlock -
      basisTransformationBlock . connection[[mu, lowerColumns, lowerColumns]] -
      D[basisTransformationBlock, variables[[mu]]],
    {mu, 2}]
];
familyRowBasisTransformationAssembleInstalledRow[___] := Automatic;

(* "Deferred" installs the complete current row while later connection rows
   and both transformation updates retain exact raw sums.  It is the safe
   default.  "Together" is an explicit diagnostic reference path for small
   inputs, not a production fallback. *)
familyRowBasisTransformationApply[
    connection : {_List, _List}, transformation_List,
    inverse_List, rowIndices_List, basisTransformationBlock_List,
    variables : {_, _}, installedRow_: Automatic,
    futureAMode_: "Deferred"] := Module[
  {n, start, stop, lowerColumns, futureRows, rowSize, lowerSize,
   validSquare, upperBlockZeroQ, newConnection, newTransformation,
   newInverse, basisTransformationRowSupport, basisTransformationColumnSupport, statistics,
   aProducts = 0, aTouched = 0, aNormalizationSeconds = 0.,
   aStageSeconds = 0.,
   aSingleTerm = 0, aInstalled = 0, aFutureProducts = 0,
   aFutureTouched = 0, aDeferredFuture = 0, aDeferredCurrent = 0,
   installedRowQ,
   installedRowCompleteQ,
   sProducts = 0, sTouched = 0, sNormalizationSeconds = 0.,
   sStageSeconds = 0.,
   sSingleTerm = 0, sDeferredNormalization = 0,
   siProducts = 0, siTouched = 0, siNormalizationSeconds = 0.,
   siStageSeconds = 0.,
   siSingleTerm = 0, siDeferredNormalization = 0,
   started = AbsoluteTime[], stageStarted, mu, aRight, aLower, derivative,
   aRightRowSupport, aLowerColumnSupport, supportAD, supportDA,
   correction, correctionTerms, correctionBlock, base, normalizedAt, leftS,
   leftSRowSupport, supportS,
   rightInverse, rightInverseColumnSupport, supportSi, futureLocalRows,
   productCount, touchedCount, i, j},

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
  If[! MatrixQ[basisTransformationBlock] || Dimensions[basisTransformationBlock] =!= {rowSize, lowerSize},
    Return[<|"Status" -> "InvalidOffDiagonalBasisTransformationBlockDimensions",
      "Expected" -> {rowSize, lowerSize},
      "Actual" -> Quiet[Check[Dimensions[basisTransformationBlock], Missing["NotAMatrix"]]]|>]];
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
  If[futureAMode === "Deferred" && installedRow =!= Automatic &&
      ! installedRowCompleteQ,
    Return[<|"Status" ->
      "DeferredFutureARequiresCompleteInstalledRow"|>]];

  (* This is the exact structural condition used by the shortened basis-transformation block
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
  basisTransformationRowSupport = familyRowBasisTransformationSupport /@ basisTransformationBlock;
  basisTransformationColumnSupport = familyRowBasisTransformationSupport /@ Transpose[basisTransformationBlock];
  stageStarted = AbsoluteTime[];
  Do[
    aRight = connection[[mu, futureRows, rowIndices]];
    aLower = connection[[mu, lowerColumns, lowerColumns]];
    (* A complete installed row supplies every current-row entry, so its
       derivative would be dead work.  Without that optional acceleration,
       Production retains the exact raw block formula. *)
    derivative = If[installedRowQ, None, D[basisTransformationBlock, variables[[mu]]]];
    aRightRowSupport = familyRowBasisTransformationSupport /@ aRight;
    aLowerColumnSupport = familyRowBasisTransformationSupport /@ Transpose[aLower];
    If[futureAMode === "Deferred",
      If[installedRowCompleteQ,
        (* Every entry in the complete installed row is assigned.  Comparing
           each large old and new expression served only a telemetry count;
           after checkpoint reload that structural walk dominated the whole
           row update despite contributing nothing to the mathematics. *)
        touchedCount = rowSize lowerSize;
        newConnection[[mu, rowIndices, lowerColumns]] = installedRow[[mu]];
        aTouched += touchedCount;
        aInstalled += rowSize lowerSize,
        productCount = Total[Flatten[Table[
          Length[Intersection[aRightRowSupport[[i]],
              basisTransformationColumnSupport[[j]]]] +
            Length[Intersection[basisTransformationRowSupport[[i]],
              aLowerColumnSupport[[j]]]],
          {i, rowSize}, {j, lowerSize}]]];
        correctionBlock = aRight[[Range[rowSize]]] . basisTransformationBlock -
          basisTransformationBlock . aLower - derivative;
        base = connection[[mu, rowIndices, lowerColumns]];
        newConnection[[mu, rowIndices, lowerColumns]] =
          base + correctionBlock;
        touchedCount = Count[Flatten[correctionBlock], Except[0]];
        aProducts += productCount;
        aTouched += touchedCount;
        aDeferredCurrent += touchedCount];
      futureLocalRows = Range[rowSize + 1, Length[futureRows]];
      If[futureLocalRows =!= {},
        productCount = Total[Flatten[Table[Length[Intersection[
            aRightRowSupport[[i]], basisTransformationColumnSupport[[j]]]],
          {i, futureLocalRows}, {j, lowerSize}]]];
        correctionBlock = aRight[[futureLocalRows]] . basisTransformationBlock;
        base = connection[[mu, futureRows[[futureLocalRows]],
          lowerColumns]];
        newConnection[[mu, futureRows[[futureLocalRows]], lowerColumns]] =
          base + correctionBlock;
        touchedCount = Count[Flatten[correctionBlock], Except[0]];
        aProducts += productCount;
        aFutureProducts += productCount;
        aTouched += touchedCount;
        aFutureTouched += touchedCount;
        aDeferredFuture += touchedCount];
      Continue[]];
    Do[
      If[installedRowQ && i <= rowSize,
        base = connection[[mu, futureRows[[i]], lowerColumns[[j]]]];
        newConnection[[mu, futureRows[[i]], lowerColumns[[j]]]] =
          installedRow[[mu, i, j]];
        If[! SameQ[base, installedRow[[mu, i, j]]], aTouched++];
        aInstalled++;
        Continue[]];
      supportAD = Intersection[
        aRightRowSupport[[i]], basisTransformationColumnSupport[[j]]];
      supportDA = If[i <= rowSize,
        Intersection[basisTransformationRowSupport[[i]],
          aLowerColumnSupport[[j]]], {}];
      aProducts += Length[supportAD] + Length[supportDA];
      If[i > rowSize, aFutureProducts += Length[supportAD]];
      correctionTerms = Join[
        (aRight[[i, #]] basisTransformationBlock[[#, j]] &) /@ supportAD,
        If[i <= rowSize,
          Join[(-basisTransformationBlock[[i, #]] aLower[[#, j]] &) /@ supportDA,
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
  leftSRowSupport = familyRowBasisTransformationSupport /@ leftS;
  Do[
    supportS = Intersection[
      leftSRowSupport[[i]], basisTransformationColumnSupport[[j]]];
    sProducts += Length[supportS];
    If[supportS =!= {},
      correctionTerms =
        (leftS[[i, #]] basisTransformationBlock[[#, j]] &) /@ supportS;
      correction = Total[correctionTerms];
      If[! SameQ[correction, 0],
        base = transformation[[i, lowerColumns[[j]]]];
        If[SameQ[base, 0] && Length[correctionTerms] === 1,
          newTransformation[[i, lowerColumns[[j]]]] =
            First[correctionTerms];
          sSingleTerm++,
          If[futureAMode === "Deferred",
            newTransformation[[i, lowerColumns[[j]]]] = base + correction;
            sDeferredNormalization++,
            normalizedAt = AbsoluteTime[];
            newTransformation[[i, lowerColumns[[j]]]] =
              Together[base + correction];
            sNormalizationSeconds += AbsoluteTime[] - normalizedAt]];
        sTouched++]],
    {i, n}, {j, lowerSize}];
  sStageSeconds = AbsoluteTime[] - stageStarted;

  stageStarted = AbsoluteTime[];
  rightInverse = inverse[[lowerColumns, All]];
  rightInverseColumnSupport =
    familyRowBasisTransformationSupport /@ Transpose[rightInverse];
  If[futureAMode === "Deferred",
    productCount = Total[Flatten[Table[Length[Intersection[
        basisTransformationRowSupport[[i]], rightInverseColumnSupport[[j]]]],
      {i, rowSize}, {j, n}]]];
    correctionBlock = -(basisTransformationBlock . rightInverse);
    base = inverse[[rowIndices, All]];
    newInverse[[rowIndices, All]] = base + correctionBlock;
    touchedCount = Count[Flatten[correctionBlock], Except[0]];
    siProducts = productCount;
    siTouched = touchedCount;
    siDeferredNormalization = touchedCount,
    Do[
      supportSi = Intersection[basisTransformationRowSupport[[i]],
        rightInverseColumnSupport[[j]]];
      siProducts += Length[supportSi];
      If[supportSi =!= {},
        correctionTerms =
          (-basisTransformationBlock[[i, #]] rightInverse[[#, j]] &) /@ supportSi;
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
      {i, rowSize}, {j, n}]];
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
      "DeferredCurrentEntries" -> aDeferredCurrent,
      "DeferredFutureEntries" -> aDeferredFuture,
      "FutureAMode" -> futureAMode,
      "StageSeconds" -> N[aStageSeconds],
      "NormalizationSeconds" -> N[aNormalizationSeconds]|>,
    "S" -> <|"CandidateEntries" -> n lowerSize,
      "Products" -> sProducts, "Touched" -> sTouched,
      "SingleTermFastPath" -> sSingleTerm,
      "DeferredNormalizationEntries" -> sDeferredNormalization,
      "StageSeconds" -> N[sStageSeconds],
      "NormalizationSeconds" -> N[sNormalizationSeconds]|>,
    "SInverse" -> <|"CandidateEntries" -> rowSize n,
      "Products" -> siProducts, "Touched" -> siTouched,
      "SingleTermFastPath" -> siSingleTerm,
      "DeferredNormalizationEntries" -> siDeferredNormalization,
      "StageSeconds" -> N[siStageSeconds],
      "NormalizationSeconds" -> N[siNormalizationSeconds]|>,
    "TotalSeconds" -> N[AbsoluteTime[] - started]|>;
  <|"Status" -> "OK", "Connection" -> newConnection,
    "Transformation" -> newTransformation, "Inverse" -> newInverse,
    "Statistics" -> statistics|>
];
