(* FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticOffDiagonalBlockLetters.wl -- part 2 of 8 of the
   multiquadratic off-diagonal block equation solver (split from MultiquadraticOffDiagonalBlockSolve.wl in
   round 4, 2026-09-02, pure moves): field arithmetic in the grade basis, one-form span, alphabet construction,
   regulator samples, field membership and letter keys, certified dlog
   potentials, diagonal spans, the candidate letter set, basis-transformation block denominators.
   Loads after the preceding parts (Private/LoadOrder.wl); the shared data,
   globals and the shared utilities are in MultiquadraticOffDiagonalBlockSolve.wl. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticOffDiagonalBlockChannelTextKey,
  $multiquadraticOffDiagonalBlockPotentialSchema,
  $multiquadraticOffDiagonalBlockPotentialCache,
  $multiquadraticOffDiagonalBlockPotentialCounters,
  $multiquadraticOffDiagonalBlockPotentialCacheEntryLimit,
  multiquadraticOffDiagonalBlockPotentialCacheReset,
  multiquadraticOffDiagonalBlockPotentialStatistics,
  multiquadraticOffDiagonalBlockPotentialPairKey,
  multiquadraticOffDiagonalBlockConstructedDLogEvidence,
  multiquadraticOffDiagonalBlockPotentialRelationZeroQ,
  multiquadraticOffDiagonalBlockVerifyPotential,
  multiquadraticOffDiagonalBlockPotentialsCertifiedQ,
  multiquadraticOffDiagonalBlockLetterKinematicPart,
  multiquadraticOffDiagonalBlockDiagonalSpan,
  multiquadraticOffDiagonalBlockDiagonalSpanBoundedExact,
  multiquadraticOffDiagonalBlockDiagonalSpanSampled,
  multiquadraticOffDiagonalBlockDiagonalSpansSampled,
  multiquadraticOffDiagonalBlockDiagonalSpanBasisImages,
  multiquadraticOffDiagonalBlockRationalAffineParticular,
  multiquadraticOffDiagonalBlockRationalAffineParticularBatch,
  $multiquadraticOffDiagonalBlockDiagonalSpanSamplePoints,
  $multiquadraticOffDiagonalBlockDiagonalSpanExactBasisLimit,
  multiquadraticOffDiagonalBlockActivePotentialCertification,
  multiquadraticOffDiagonalBlockTransferDiagnosticResidues,
  multiquadraticFieldInverse,
  multiquadraticFieldInverseTower,
  multiquadraticFieldInverseLinearSolve,
  $multiquadraticFieldInverseMethod,
  multiquadraticOffDiagonalBlockActiveGradeNorm,
  multiquadraticFieldDecompose,
  multiquadraticFieldCompose,
  multiquadraticLiftLocalChannels,
  multiquadraticClosedOneFormQ,
  multiquadraticScalarOneForms,
  multiquadraticRationalOffDiagonalBasisTransformationDenominator,
  multiquadraticOffDiagonalBlockCanonicalFactor,
  multiquadraticOffDiagonalBlockRationalPolarCurves,
  multiquadraticOffDiagonalBlockNormInAlphabetQ,
  multiquadraticOffDiagonalBlockPolynomialSquareRoot,
  multiquadraticOffDiagonalBlockSquareCompletionConstants,
  multiquadraticOffDiagonalBlockNormMonomials,
  multiquadraticOffDiagonalBlockAlgebraicLetters,
  multiquadraticOffDiagonalBlockRegulatorSampleValues,
  multiquadraticOffDiagonalBlockFieldMemberQ,
  multiquadraticOffDiagonalBlockFormTextKey,
  multiquadraticOffDiagonalBlockLetterOneForm,
  multiquadraticOffDiagonalBlockLetterDLogDataInField,
  multiquadraticOffDiagonalBlockDLogShardTask,
  multiquadraticOffDiagonalBlockConstructDLogBatch,
  multiquadraticOffDiagonalBlockRowAlphabetLetters,
  multiquadraticOffDiagonalBlockCandidateLetters,
  multiquadraticOffDiagonalBlockNormDenominatorFactor,
  multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominator,
  multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominatorSourceData,
  multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominatorSources,
  $multiquadraticOffDiagonalBlockRegulatorSamplePool
];

(* ------------------------------------------------------------------ *)
(* Field arithmetic in the grade basis                                  *)
(* ------------------------------------------------------------------ *)

(* ---- RECURSIVE QUADRATIC-TOWER INVERSION (2026-08-25, Codex 14:30
   "rank-3 inversion strategy") ----------------------------------------

   The historical route below builds the 2^r x 2^r multiplication matrix
   of the element and solves it symbolically.  At rank 3 that is an 8x8
   rational linear solve whose entries are the off-diagonal block equation's own rational
   functions, and it was the measured cost of every rank-3 channel
   decomposition.

   The tower does it with r divisions of DEGREE TWO instead.  Write
   A_k = A_{k-1}[r_k]/(r_k^2 - delta_k) and split the channel vector on
   the top bit, a = u + v r_k with u, v in A_{k-1} (the low and high
   halves of the vector, in exactly the mask order the data-layout contract uses).  Then

       a^-1 = (u - v r_k) N^-1,    N = u^2 - delta_k v^2  in A_{k-1},

   so one rank-k inversion is two squarings and two products in
   A_{k-1} plus ONE rank-(k-1) inversion, and the recursion bottoms out
   at a single rational division.  The result is the same element of the
   same field; it is accepted by the SAME exact product check as before,
   which is the acceptance that decides, not the route.

   The LinearSolve route is kept callable as the reference the
   equivalence test holds the tower to, and as the fallback if the tower
   cannot divide (a zero norm at some level of the tower means the
   element is a zero divisor, and both routes then refuse). *)
multiquadraticFieldInverseTower[a_List, deltas_List] := Module[
  {rank = Length[deltas], half, u, v, subDeltas, uSquare, vSquare, norm,
   normInverse},
  If[Length[a] =!= 2^rank, Return[$Failed]];
  If[rank === 0,
    Return[If[TrueQ[Together[First[a]] === 0], $Failed,
      {Together[1/First[a]]}]]];
  half = 2^(rank - 1);
  u = Take[a, half];
  v = Drop[a, half];
  subDeltas = Most[deltas];
  (* a purely low element is an element of A_{k-1}: no norm is needed *)
  If[multiquadraticOffDiagonalBlockZeroQ[v],
    Return[Module[{inner = multiquadraticFieldInverseTower[u, subDeltas]},
      If[inner === $Failed, $Failed,
        Join[inner, ConstantArray[0, half]]]]]];
  uSquare = multiquadraticMultiply[u, u, subDeltas];
  vSquare = multiquadraticMultiply[v, v, subDeltas];
  norm = Together /@ (uSquare - Last[deltas] vSquare);
  normInverse = multiquadraticFieldInverseTower[norm, subDeltas];
  If[normInverse === $Failed, Return[$Failed]];
  Join[
    Together /@ multiquadraticMultiply[u, normInverse, subDeltas],
    Together /@ (- multiquadraticMultiply[v, normInverse, subDeltas])]
];
multiquadraticFieldInverseTower[___] := $Failed;

(* the pre-2026-08-25 route, kept as the equivalence reference *)
multiquadraticFieldInverseLinearSolve[a_List, deltas_List] /;
    Length[a] === 2^Length[deltas] := Module[
  {dimension = Length[a], columns, matrix, inverse, check},
  If[multiquadraticOffDiagonalBlockZeroQ[Rest[a]],
    If[TrueQ[Together[First[a]] === 0], Return[$Failed]];
    Return[Prepend[ConstantArray[0, dimension - 1], Together[1/First[a]]]]];
  columns = Table[
    multiquadraticMultiply[a, UnitVector[dimension, column], deltas],
    {column, dimension}];
  matrix = Transpose[columns];
  inverse = Quiet[LinearSolve[matrix, UnitVector[dimension, 1]]];
  If[! ListQ[inverse] || Length[inverse] =!= dimension, Return[$Failed]];
  inverse = Together /@ inverse;
  check = multiquadraticMultiply[a, inverse, deltas];
  If[! multiquadraticOffDiagonalBlockZeroQ[check - UnitVector[dimension, 1]], $Failed, inverse]
];
multiquadraticFieldInverseLinearSolve[___] := $Failed;

(* "RecursiveTower" (the default) or "LinearSolve" (the reference).  The
   acceptance is the same exact product check on both routes, so the
   method is a cost decision and never a correctness one. *)
$multiquadraticFieldInverseMethod = "RecursiveTower";

multiquadraticFieldInverse[a_List, deltas_List] /;
    Length[a] === 2^Length[deltas] := Module[
  {dimension = Length[a], inverse, check},
  (* the grade-zero fast path, ahead of both routes: a rational scalar
     inverts in one division and needs no tower and no matrix *)
  If[multiquadraticOffDiagonalBlockZeroQ[Rest[a]],
    If[TrueQ[Together[First[a]] === 0], Return[$Failed]];
    Return[Prepend[ConstantArray[0, dimension - 1], Together[1/First[a]]]]];
  inverse = If[$multiquadraticFieldInverseMethod === "LinearSolve",
    multiquadraticFieldInverseLinearSolve[a, deltas],
    multiquadraticFieldInverseTower[a, deltas]];
  (* a tower that cannot divide has met a zero norm at some level; the
     matrix route is asked once before the element is called singular,
     so no element that the historical route inverted is refused now *)
  If[(! ListQ[inverse] || Length[inverse] =!= dimension) &&
      $multiquadraticFieldInverseMethod =!= "LinearSolve",
    inverse = multiquadraticFieldInverseLinearSolve[a, deltas]];
  If[! ListQ[inverse] || Length[inverse] =!= dimension, Return[$Failed]];
  (* THE acceptance, unchanged and route independent *)
  check = multiquadraticMultiply[a, inverse, deltas];
  If[! ListQ[check] ||
      ! multiquadraticOffDiagonalBlockZeroQ[check - UnitVector[dimension, 1]],
    $Failed, inverse]
];
multiquadraticFieldInverse[___] := $Failed;

(* The minimal Galois-orbit norm of an already decomposed field element.
   Inactive generators are projected out first, so a one-root letter in a
   rank-three family receives its quadratic norm rather than that norm raised
   to the fourth power.  The recursion is the norm half of the established
   inverse tower: u + v r -> u^2 - delta v^2, one generator at a time. *)
multiquadraticOffDiagonalBlockActiveGradeNorm[channels_List, deltas_List] := Module[
  {rank = Length[deltas], activeIndices, localChannels, normTower, result},
  If[Length[channels] =!= 2^rank, Return[$Failed]];
  (* Field decomposition canonicalizes every zero channel to literal 0. *)
  activeIndices = Select[Range[rank], Function[index,
    AnyTrue[Range[0, Length[channels] - 1], Function[mask,
      BitGet[mask, index - 1] === 1 &&
        ! SameQ[channels[[mask + 1]], 0]]]]];
  localChannels = Table[Module[{globalMask = Sum[
        BitGet[localMask, bit - 1] 2^(activeIndices[[bit]] - 1),
        {bit, Length[activeIndices]}]}, channels[[globalMask + 1]]],
    {localMask, 0, 2^Length[activeIndices] - 1}];
  normTower[values_List, squares_List] := Module[
    {localRank = Length[squares], half, low, high, reduced},
    If[Length[values] =!= 2^localRank, Return[$Failed]];
    If[localRank === 0, Return[Together[First[values]]]];
    half = 2^(localRank - 1);
    low = Take[values, half]; high = Drop[values, half];
    reduced = Together /@ (
      multiquadraticMultiply[low, low, Most[squares]] -
        Last[squares] multiquadraticMultiply[high, high, Most[squares]]);
    normTower[reduced, Most[squares]]];
  result = normTower[localChannels, deltas[[activeIndices]]];
  If[result === $Failed ||
      ! FreeQ[result,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    $Failed, Together[result]]
];
multiquadraticOffDiagonalBlockActiveGradeNorm[___] := $Failed;

(* Root symbols are generated from the declared frame.  Rank three is the
   current resource ceiling, not part of the algebraic data-layout contract. *)
multiquadraticFieldDecompose[expression_, roots_List,
    validateRoundTrip_: True, normalizeInput_: True] := Module[
  {rank = Length[roots], deltas, rootImages, symbols,
   replaced, rational, numerator, denominator, numeratorChannels,
   denominatorChannels, denominatorInverse, result, channels, reconstructed},
  If[rank > $multiquadraticOffDiagonalBlockMaximumRootCount ||
      ! MemberQ[{True, False}, normalizeInput], Return[$Failed]];
  deltas = If[rank === 0, {},
    Together /@ (squareRootRecordRadicand /@ roots)];
  If[! FreeQ[deltas, $Failed], Return[$Failed]];
  rootImages = squareRootRecordExpression /@ roots;
  If[! FreeQ[rootImages, $Failed], Return[$Failed]];
  symbols = Table[Unique["multiquadraticRoot$"], {rank}];
  replaced = If[rank === 0, expression,
    (* Deferred assembly represents inactive algebra generators by literal
       symbols.  Replace each declared root expression directly before the
       radical square-class matcher; the latter remains the fallback for
       equivalent radical spellings.  Without this first rule, literal tags
       bypassed the algebraic path as apparently root-free scalars. *)
    transportChartApplyRootBranches[
      expression /. Thread[rootImages -> symbols], roots, symbols]];
  If[replaced === $Failed, Return[$Failed]];
  (* rank 0 decides on the normal form, as it always has: Together may
     rationalize a numeric radical away, and that expression is a
     rational scalar *)
  If[rank > 0 &&
      ! FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  (* Deferred target assembly already returns one exact numerator over one
     exact denominator in inert root tags.  Re-running Together on those
     multi-million-leaf quotients consumed an entire measured 635 s
     projection.  Consumers that own that representation may skip only this
     input normalization; the polynomial guards and exact field arithmetic
     below are unchanged, and an uncombined input is refused. *)
  rational = If[TrueQ[normalizeInput], Together[replaced], replaced];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  (* Scalar-local root-free fast path (2026-08-23, ported from an audited
     prototype).  A
     rank-r bundle contains many entries that use no declared root at
     all; such a scalar is already its own grade-zero channel, so
     polynomial field reduction and the recursive norm inversion below
     compute a known answer.  The full 2^r grade data-layout contract is preserved by
     padding, and the result is accepted ONLY after the same exact
     compose check the algebraic path is held to.  Alternatives[] (rank
     0) matches nothing, so a rank-0 call takes this path and is now
     compose-checked as well. *)
  If[FreeQ[rational, Alternatives @@ symbols],
    channels = PadRight[{rational}, 2^rank, 0];
    If[TrueQ[validateRoundTrip],
      reconstructed = multiquadraticFieldCompose[channels, roots];
      If[reconstructed === $Failed ||
          ! TrueQ[Together[reconstructed - expression] === 0],
        Return[$Failed]];
      $multiquadraticFieldComposeCheckCount++];
    $multiquadraticFieldRootFreeFastPathCount++;
    Return[channels]];
  $multiquadraticFieldAlgebraicPathCount++;
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[! PolynomialQ[numerator, symbols] || ! PolynomialQ[denominator, symbols],
    Return[$Failed]];
  numeratorChannels = multiquadraticFromPolynomial[numerator, symbols, deltas];
  denominatorChannels = multiquadraticFromPolynomial[denominator, symbols, deltas];
  If[numeratorChannels === $Failed || denominatorChannels === $Failed,
    Return[$Failed]];
  denominatorInverse = multiquadraticFieldInverse[denominatorChannels, deltas];
  If[denominatorInverse === $Failed, Return[$Failed]];
  result = multiquadraticMultiply[numeratorChannels, denominatorInverse, deltas];
  Together /@ result
];

multiquadraticFieldCompose[channels_List, roots_List] /;
    Length[channels] === 2^Length[roots] :=
  multiquadraticToExpression[channels,
    squareRootRecordExpression /@ roots];
multiquadraticFieldCompose[___] := $Failed;

(* Embed a local channel vector over a subset of the declared roots
   into the declared global grade width, rank 0 included. *)
multiquadraticLiftLocalChannels[channels_List, indices_List, rank_Integer] := Module[
  {lifted, masks, globalMask},
  If[rank < 0 || indices =!= Sort[indices] || ! VectorQ[indices, IntegerQ] ||
      Length[DeleteDuplicates[indices]] =!= Length[indices] ||
      ! AllTrue[indices, 1 <= #1 <= rank &] ||
      Length[channels] =!= 2^Length[indices], Return[$Failed]];
  lifted = ConstantArray[0, 2^rank];
  If[indices === {}, lifted[[1]] = First[channels]; Return[lifted]];
  masks = Table[Sum[BitGet[localMask, bit - 1] 2^(indices[[bit]] - 1),
      {bit, Length[indices]}],
    {localMask, 0, Length[channels] - 1}];
  If[Length[DeleteDuplicates[masks]] =!= Length[masks] ||
      ! AllTrue[masks, 0 <= #1 < 2^rank &], Return[$Failed]];
  Do[
    globalMask = masks[[localMask + 1]];
    lifted[[globalMask + 1]] = channels[[localMask + 1]],
    {localMask, 0, Length[channels] - 1}];
  lifted
];
multiquadraticLiftLocalChannels[___] := $Failed;

(* ------------------------------------------------------------------ *)
(* One-form span and basis-transformation block denominator                                  *)
(* ------------------------------------------------------------------ *)

multiquadraticScalarOneForms[pair : {first_List, second_List}] := Module[
  {dimensions = Dimensions[first]},
  If[Dimensions[second] =!= dimensions || Length[dimensions] =!= 2, Return[{}]];
  Flatten[Table[{first[[i, j]], second[[i, j]]},
    {i, dimensions[[1]]}, {j, dimensions[[2]]}], 1]
];

multiquadraticClosedOneFormQ[form : {_, _}, variables : {x_, y_}] :=
  TrueQ[Together[D[form[[2]], x] - D[form[[1]], y]] === 0];

(* DELETED 2026-08-26 (round-2 wave, Codex review 4.2): the first
   one-form deduplicator cluster -- multiquadraticOneFormKey,
   multiquadraticDeduplicateOneForms, multiquadraticDiagonalOneFormBasis
   and multiquadraticCandidateOneFormBasis.  A comment-stripped scan of
   FeynFacet/, Scripts/ and Tests/ found no caller outside the cluster
   itself.  multiquadraticOffDiagonalBlockCandidateLetters is the builder that
   replaced it: it keys one-forms by canonical text instead of by a
   channel data record (so it never decomposes to deduplicate), it
   tags every record with its source Kind, and it mints the dlog
   certificate at the one site that pairs a letter with its one-form.
   multiquadraticScalarOneForms and multiquadraticClosedOneFormQ, which
   that builder still uses, are kept above. *)

(* One power below the worst inhomogeneity pole: the basis-transformation block may carry the
   repeated part of a channel denominator, never more. *)
multiquadraticRationalOffDiagonalBasisTransformationDenominator[channelInhomogeneity_, variables_List] := Module[
  {entries, factorPairs, factors, powers},
  entries = Flatten[channelInhomogeneity];
  factorPairs = Flatten[Map[
    Function[entry, Module[{denominator = Denominator[Together[entry]]},
      If[TrueQ[denominator === 1], {},
        Select[Rest[FactorList[denominator]], ! TrueQ[NumericQ[First[#1]]] &]]]],
    entries], 1];
  If[factorPairs === {}, Return[1]];
  factors = DeleteDuplicates[factorPairs[[All, 1]], SameQ];
  powers = Table[{factor, Max[Cases[factorPairs,
      {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
    {factor, factors}];
  Together[Times @@ ((First[#1]^(Max[0, Last[#1] - 1])) & /@
    Select[powers, ! FreeQ[First[#1], Alternatives @@ variables] &])]
];

(* ------------------------------------------------------------------ *)
(* Alphabet construction: polar curves, norms, algebraic letters        *)
(* ------------------------------------------------------------------ *)

(* Three invariants this section exists to enforce.  Each was established
   by measurements on a production block.

   (i) REGULATOR SAMPLE VALUES ARE CHOSEN, NEVER FIXED.  A fixed sample
   list can land on poles of a block's inhomogeneity, and every candidate dlog
   built at such a value is lost.  A generic pool is therefore tested
   entry by entry and a value that makes any entry singular is
   re-sampled.
   (ii) ALGEBRAIC LETTERS ARE GENERATED WITH A CERTIFICATE, NOT GUESSED.
   An integrability condition inconsistent with every rational alphabet
   is repaired by letters A +- Sqrt[delta]: for each root square delta
   and each small product M of polar curves the rational constant c with
   delta + c M a perfect square is solved for, and A is that square root.
   The norm filter below is the certificate that keeps the family small
   -- a letter whose norm A^2 - delta carries an irreducible factor
   outside the alphabet is refused.
   (iii) THE ROW'S INSTALLED ALPHABETS BELONG IN THE BASIS.  The row's
   flatness identity couples the already-installed blocks of the same row
   and column to this one, so their letters are adjoined when the caller
   supplies them (the sector state's OffDiagonalBlockSolutions "Alphabet" entries). *)

(* A canonical representative of a polynomial up to RATIONAL NUMBER
   scale: the numeric part of the lexicographically leading coefficient
   is divided out.  Used for deduplication, for the exact division filter
   and for the basis-transformation block-denominator merge, where a numeric scale is
   irrelevant.  The leading coefficient itself need not be numeric: a
   polar factor of an off-diagonal block equation carries the regulator in
   its coefficients (a measured example is
   -1-2eps-x-2eps x-y-2eps y+xy+eps xy), and an
   earlier version of this function refused such a factor, which silently
   dropped an ADMISSIBLE POLE from the merged basis-transformation block denominator. *)
multiquadraticOffDiagonalBlockCanonicalFactor[polynomial_, variables_List] := Module[
  {expanded, rules, leading, scale, leadingRules},
  expanded = Expand[Together[polynomial]];
  If[! PolynomialQ[expanded, variables], Return[$Failed]];
  rules = CoefficientRules[expanded, variables];
  If[rules === {}, Return[0]];
  leading = Last[First[rules]];
  scale = If[IntegerQ[leading] || Head[leading] === Rational, leading,
    leadingRules = Quiet[CoefficientRules[Expand[leading],
      Variables[Expand[leading]]]];
    If[! ListQ[leadingRules] || leadingRules === {}, $Failed,
      Last[First[leadingRules]]]];
  If[! (IntegerQ[scale] || Head[scale] === Rational) || scale === 0,
    Return[$Failed]];
  Expand[expanded/scale]
];

(* The off-diagonal block equation's rational polar curves: the x/y-dependent irreducible
   factors of the DENOMINATORS of the given expressions, plus the given
   root squares.  Numerators are deliberately not factored -- a inhomogeneity
   numerator is a large dense polynomial whose factorization costs more
   than the whole screen and whose irreducible parts are not poles. *)
multiquadraticOffDiagonalBlockRationalPolarCurves[expressions_, extra_List,
    variables_List] := Module[{entries, collected = {}, rational, list},
  entries = Select[Flatten[{expressions}], ! TrueQ[Quiet[Together[#1]] === 0] &];
  Do[
    rational = Quiet[Together[entry]];
    If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
      Continue[]];
    list = Quiet[Rest[FactorList[Denominator[rational]]]];
    If[! ListQ[list], Continue[]];
    collected = Join[collected,
      Select[First /@ list, ! FreeQ[#1, Alternatives @@ variables] &]],
    {entry, entries}];
  Do[
    list = Quiet[Rest[FactorList[Expand[Together[candidate]]]]];
    If[! ListQ[list], Continue[]];
    collected = Join[collected,
      Select[First /@ list, ! FreeQ[#1, Alternatives @@ variables] &]],
    {candidate, extra}];
  collected = DeleteCases[
    multiquadraticOffDiagonalBlockCanonicalFactor[#1, variables] & /@ collected,
    $Failed | 0];
  (* the alphabet is a set of KINEMATIC polar curves: a factor whose
     coefficients still carry the regulator is a pole of the connection
     in eps, not a letter, and it must not enter the norm filter (where
     it could divide a norm in Q(eps)[x,y]).  Such factors do enter the
     basis-transformation block denominator, through the merge, which reads the inhomogeneity rule's
     own denominator and not this alphabet. *)
  collected = Select[collected, Function[candidate,
    AllTrue[Last /@ CoefficientRules[candidate, variables], NumericQ]]];
  SortBy[DeleteDuplicates[collected, TrueQ[Together[#1 - #2] === 0] &],
    {LeafCount[#1], ToString[InputForm[#1]]} &]
];

(* THE NORM FILTER.  A candidate algebraic letter A +- Sqrt[delta] is
   admissible only if its norm A^2 - delta factors completely into the
   off-diagonal block equation's rational alphabet: every alphabet letter is divided out
   exactly, as many times as it divides, and what remains must be a
   non-zero rational CONSTANT.  An irreducible factor outside the
   alphabet leaves a variable behind and the letter is refused.  This is
   the whole of the "every letter certifiable" requirement -- the
   quadratic extension generated by the letter is then unramified
   outside the alphabet. *)
multiquadraticOffDiagonalBlockNormInAlphabetQ[norm_, alphabet_List, variables_List] :=
  Module[{remainder, quotient, changed, guard = 0},
  remainder = Quiet[Expand[Together[norm]]];
  If[! PolynomialQ[remainder, variables] || TrueQ[remainder === 0],
    Return[False]];
  changed = True;
  While[changed && ! FreeQ[remainder, Alternatives @@ variables] &&
      guard < 64,
    guard++; changed = False;
    Do[
      If[FreeQ[letter, Alternatives @@ variables], Continue[]];
      quotient = Quiet[Cancel[Together[remainder/letter]]];
      If[PolynomialQ[quotient, variables],
        remainder = Expand[quotient]; changed = True],
      {letter, alphabet}]];
  TrueQ[FreeQ[remainder, Alternatives @@ variables] &&
    ! TrueQ[Together[remainder] === 0]]
];

(* An exact polynomial square root, or $Failed.  Factor first so that
   PowerExpand has a squared form to open; the answer is then VERIFIED by
   expansion, so the sign convention PowerExpand picks is irrelevant. *)
multiquadraticOffDiagonalBlockPolynomialSquareRoot[polynomial_, variables_List] := Module[
  {expanded, candidate},
  expanded = Quiet[Expand[Together[polynomial]]];
  If[! PolynomialQ[expanded, variables] || TrueQ[expanded === 0],
    Return[$Failed]];
  candidate = Quiet[PowerExpand[Sqrt[Factor[expanded]]]];
  If[PolynomialQ[candidate, variables] &&
      TrueQ[Expand[candidate^2 - expanded] === 0], Expand[candidate], $Failed]
];

(* The rational constants c for which delta + c M can be a perfect
   square.  One variable is specialized to a small integer, which turns
   the square condition into the vanishing of a discriminant -- a
   polynomial equation in c alone.  The candidates are only candidates:
   every one is verified EXACTLY by taking the polynomial square root of
   delta + c M in both variables. *)
multiquadraticOffDiagonalBlockSquareCompletionConstants[delta_, monomial_,
    variables_List, constantSymbol_Symbol] := Module[
  {candidates = {}, other, specialized, discriminant, solutions, degree},
  Do[
    other = variables[[3 - k]];
    Do[
      specialized = Quiet[Expand[
        (delta + constantSymbol monomial) /. other -> value]];
      If[! PolynomialQ[specialized, {variables[[k]], constantSymbol}],
        Continue[]];
      degree = Exponent[specialized, variables[[k]]];
      If[! IntegerQ[degree] || degree < 2, Continue[]];
      discriminant = Quiet[Discriminant[specialized, variables[[k]]]];
      If[! PolynomialQ[discriminant, constantSymbol] ||
          TrueQ[Expand[discriminant] === 0] ||
          FreeQ[discriminant, constantSymbol], Continue[]];
      solutions = Quiet[Solve[discriminant == 0, constantSymbol]];
      If[ListQ[solutions],
        candidates = Join[candidates,
          Cases[constantSymbol /. solutions, _Integer | _Rational]]],
      {value, {3, 5, 7}}],
    {k, 2}];
  DeleteDuplicates[DeleteCases[candidates, 0]]
];

(* Small products of polar curves: at most maximumFactors distinct
   letters, each to at most maximumExponent. *)
multiquadraticOffDiagonalBlockNormMonomials[alphabet_List, maximumFactors_Integer,
    maximumExponent_Integer] := Module[{subsets},
  subsets = Subsets[Range[Length[alphabet]],
    {0, Min[maximumFactors, Length[alphabet]]}];
  DeleteDuplicates[Flatten[Table[
    Times @@ (alphabet[[subset]]^exponents),
    {subset, subsets},
    {exponents, Tuples[Range[maximumExponent], Length[subset]]}], 2]]
];

Options[multiquadraticOffDiagonalBlockAlgebraicLetters] = {
  "MaximumNormFactors" -> 2,
  "MaximumNormExponent" -> 2
};

(* The algebraic letter family of a multiquadratic off-diagonal block equation.  For every
   declared root and every small product M of polar curves, solve for the
   rational constant c with delta + c M a perfect square A^2; the letters
   are A + Sqrt[delta] and A - Sqrt[delta], with norm A^2 - delta = c M.
   The norm filter is applied to every emitted letter even though the
   construction satisfies it by design: it is the certificate the record
   carries, and it is the same predicate applied to letters that arrive
   from anywhere else (row alphabets, caller-supplied lists). *)
multiquadraticOffDiagonalBlockAlgebraicLetters[roots_List, alphabet_List,
    variables_List, opts : OptionsPattern[]] := Module[
  {constantSymbol, monomials, records = {}, delta, rootExpression, constants,
   square, a, norm, key, seen = {}, canonical},
  monomials = multiquadraticOffDiagonalBlockNormMonomials[alphabet,
    OptionValue["MaximumNormFactors"], OptionValue["MaximumNormExponent"]];
  Module[{c},
    constantSymbol = c;
    Do[
      delta = Together[squareRootRecordRadicand[root]];
      rootExpression = squareRootRecordExpression[root];
      If[delta === $Failed || rootExpression === $Failed, Continue[]];
      (* A = 0: the root itself, admissible when delta factors into the
         alphabet (it always does when delta is a declared polar curve) *)
      If[multiquadraticOffDiagonalBlockNormInAlphabetQ[-delta, alphabet, variables],
        AppendTo[records, <|"Kind" -> "Algebraic", "Letter" -> rootExpression,
          "A" -> 0, "QuadraticRadicand" -> delta, "Norm" -> Expand[-delta],
          "NormInAlphabet" -> True|>]];
      Do[
        constants = multiquadraticOffDiagonalBlockSquareCompletionConstants[delta,
          monomial, variables, constantSymbol];
        Do[
          square = Expand[delta + constant monomial];
          a = multiquadraticOffDiagonalBlockPolynomialSquareRoot[square, variables];
          If[a === $Failed, Continue[]];
          norm = Expand[a^2 - delta];
          If[TrueQ[norm === 0], Continue[]];
          If[! multiquadraticOffDiagonalBlockNormInAlphabetQ[norm, alphabet, variables],
            Continue[]];
          canonical = multiquadraticOffDiagonalBlockCanonicalFactor[a, variables];
          If[canonical === $Failed, Continue[]];
          key = {ToString[InputForm[Together[delta]]],
            ToString[InputForm[canonical]]};
          If[MemberQ[seen, key], Continue[]];
          AppendTo[seen, key];
          AppendTo[records, <|"Kind" -> "Algebraic",
            "Letter" -> Together[a + rootExpression], "A" -> a,
            "QuadraticRadicand" -> delta, "Norm" -> norm, "NormInAlphabet" -> True|>];
          AppendTo[records, <|"Kind" -> "Algebraic",
            "Letter" -> Together[a - rootExpression], "A" -> a,
            "QuadraticRadicand" -> delta, "Norm" -> norm, "NormInAlphabet" -> True|>],
          {constant, constants}],
        {monomial, monomials}],
      {root, roots}]];
  records
];

(* ------------------------------------------------------------------ *)
(* Regulator samples away from the inhomogeneity's poles                      *)
(* ------------------------------------------------------------------ *)

$multiquadraticOffDiagonalBlockRegulatorSamplePool = {1, 2, 3, 5, 7, 11, 13, 4, 6, 8,
  9, 10, 12, 5/3, 7/3, 11/5, 13/7, 7/5, 17, 19};

(* A sample value is ACCEPTED only after every inhomogeneity entry has been
   substituted and survived: a value at which any entry is singular, or
   at which no entry retains any kinematic dependence, is rejected and
   the next pool value is tried.  The substituted entries are returned,
   because the caller needs exactly them for the candidate dlogs. *)
multiquadraticOffDiagonalBlockRegulatorSampleValues[inhomogeneity_, variables_List,
    epsilon_Symbol, count_Integer, pool_List] := Module[
  {entries, accepted = {}, rejected = {}, values, usable},
  entries = Flatten[{inhomogeneity}];
  Do[
    If[Length[accepted] >= count, Break[]];
    values = Quiet[Check[
      Together[#1 /. epsilon -> candidate], $Failed,
      {Power::infy, Infinity::indet, Power::indet}] & /@ entries];
    usable = FreeQ[values, $Failed] &&
      FreeQ[values, DirectedInfinity | Indeterminate | ComplexInfinity] &&
      AnyTrue[values, ! TrueQ[Together[#1] === 0] &&
        ! FreeQ[#1, Alternatives @@ variables] &];
    If[TrueQ[usable],
      AppendTo[accepted, <|"Value" -> candidate, "Entries" -> values|>],
      AppendTo[rejected, candidate]],
    {candidate, pool}];
  <|"Status" -> If[Length[accepted] >= count, "RegulatorSamplesChosen",
      "InsufficientRegulatorSamples"],
    "Values" -> Lookup[accepted, "Value", {}],
    "SubstitutedEntries" -> Lookup[accepted, "Entries", {}],
    "RejectedValues" -> rejected, "Pool" -> pool, "Requested" -> count|>
];

(* ------------------------------------------------------------------ *)
(* Field membership, one-form keys, the candidate letter set            *)
(* ------------------------------------------------------------------ *)

(* Cheap membership test for the off-diagonal block equation's multiquadratic field: replace
   the declared roots by symbols and require no fractional power to
   survive.  This is the early half of multiquadraticFieldDecompose and
   costs no field inversion, which is what makes an adjoined alphabet
   affordable. *)
multiquadraticOffDiagonalBlockFieldMemberQ[expression_, roots_List] := Module[
  {symbols, replaced},
  If[roots === {},
    Return[TrueQ[FreeQ[expression,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]]]]];
  symbols = Table[Unique["multiquadraticRoot$"], {Length[roots]}];
  replaced = Quiet[transportChartApplyRootBranches[expression, roots, symbols]];
  If[replaced === $Failed, Return[False]];
  TrueQ[FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]] &&
    FreeQ[Quiet[Together[replaced]],
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]]]
];

(* Deduplication key.  The basis once keyed one-forms on their
   exact channel decomposition, which is a field inversion per component
   and measured 1539 s of a 2429 s production preparation.  Two
   forms that are equal have the same Together normal form in canonical
   symbols.  Store that mathematical normal form itself as the key. *)
multiquadraticOffDiagonalBlockFormTextKey[form : {_, _}, variables_List,
    epsilon_Symbol] := Module[{rules, canonical},
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  canonical = Quiet[Together /@ (form /. rules)];
  canonical
];

(* When the exact grade channels already exist, they are the canonical
   field representation.  Key that rational data directly instead of
   materialising radicals and asking Together to rediscover the same
   normal form.  Dimensions are part of the payload, so a letter channel
   vector and a two-component one-form cannot collide. *)
multiquadraticOffDiagonalBlockChannelTextKey[channels_List, variables_List,
    epsilon_Symbol] := Module[{rules, depth, canonical},
  depth = ArrayDepth[channels];
  If[depth < 1, Return[$Failed]];
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  canonical = Quiet[Map[Together, channels /. rules, {depth}]];
  If[! ListQ[canonical] || ! FreeQ[canonical, $Failed], Return[$Failed]];
  {Dimensions[canonical], canonical}
];
multiquadraticOffDiagonalBlockChannelTextKey[channels_List,
    variables : {_Symbol, _Symbol}] := Module[{rules, depth, canonical},
  depth = ArrayDepth[channels];
  If[depth < 1, Return[$Failed]];
  rules = Thread[variables -> {\[FormalX], \[FormalY]}];
  canonical = Quiet[Map[Together, channels /. rules, {depth}]];
  If[! ListQ[canonical] || ! FreeQ[canonical, $Failed], Return[$Failed]];
  {Dimensions[canonical], canonical}
];
multiquadraticOffDiagonalBlockChannelTextKey[___] := $Failed;

multiquadraticOffDiagonalBlockLetterOneForm[letter_, variables : {x_, y_}] := Module[
  {value = Quiet[Together[letter]], derivative},
  If[TrueQ[value === 0] || ! FreeQ[value, DirectedInfinity | Indeterminate],
    Return[$Failed]];
  derivative = Quiet[{Together[D[letter, x]/letter],
    Together[D[letter, y]/letter]}];
  If[! FreeQ[derivative, DirectedInfinity | Indeterminate | $Failed],
    Return[$Failed]];
  derivative
];

(* A letter that already belongs to the declared multiquadratic field is
   differentiated IN THAT FIELD.  Building Together[D[L]/L] first makes
   a large radical expression and only decomposes it again in the compile
   stage.  Here L is decomposed once, inverted in the grade algebra, and
   differentiated channel by channel; composing the two channel vectors
   yields the same exact one-form without materialising that intermediate
   expression tree.  multiquadraticOffDiagonalBlockLetterChannelPair certifies the
   decomposition and inverse exactly.  Rank zero and any typed refusal
   retain the conservative historical path. *)
multiquadraticOffDiagonalBlockLetterDLogDataInField[letter_, roots_List,
    variables : {x_, y_}] := Module[
  {channelData, letterChannels = Missing["NotRetained"], channels, form,
   channelZeroQ},
  If[roots =!= {},
    channelData = Quiet[multiquadraticOffDiagonalBlockLetterChannelData[
      letter, roots, variables]];
    channels = If[AssociationQ[channelData],
      Lookup[channelData, "DLogChannels", $Failed], $Failed];
    letterChannels = If[AssociationQ[channelData],
      Lookup[channelData, "LetterChannels", Missing["NotRetained"]],
      Missing["NotRetained"]];
    If[MatchQ[channels, {_List, _List}] && FreeQ[channels, $Failed],
      form = Quiet[multiquadraticFieldCompose[#1, roots] & /@ channels];
      If[MatchQ[form, {_, _}] && FreeQ[form,
          $Failed | DirectedInfinity | Indeterminate],
        (* Both constructors end their channel arithmetic in Together, so an
           exact zero channel is already the integer 0.  Record that verdict
           here instead of normalizing the same channels again on admission. *)
        channelZeroQ = AllTrue[Flatten[channels], SameQ[#1, 0] &];
        Return[<|"OneForm" -> form, "Channels" -> channels,
          "LetterChannels" -> letterChannels,
          "ChannelZeroQ" -> channelZeroQ,
          "Path" -> "GradeAlgebra"|>]]]];
  form = multiquadraticOffDiagonalBlockLetterOneForm[letter, variables];
  If[! MatchQ[form, {_, _}], Return[$Failed]];
  channels = If[roots === {}, List /@ form,
    Quiet[multiquadraticFieldDecompose[#1, roots] & /@ form]];
  letterChannels = If[roots === {}, {letter}, Missing["NotRetained"]];
  channelZeroQ = If[MatchQ[channels, {_List, _List}] &&
      FreeQ[channels, $Failed],
    AllTrue[Flatten[channels], SameQ[#1, 0] &],
    Missing["NotRetained"]];
  <|"OneForm" -> form,
    "Channels" -> If[MatchQ[channels, {_List, _List}] &&
      FreeQ[channels, $Failed], channels, Missing["NotRetained"]],
    "LetterChannels" -> letterChannels,
    "ChannelZeroQ" -> channelZeroQ,
    "Path" -> "MaterializedFallback"|>
];

(* Helper-side shard for the independent whole-inhomogeneity dlogs.  The payload
   is written in formal System` variables, exactly like the compile shard,
   so a helper's $Context cannot rebind chart symbols. *)
multiquadraticOffDiagonalBlockDLogShardTask[payload_Association, indices_List] := Module[
  {entries, roots, results},
  entries = Lookup[payload, "Entries", $Failed];
  roots = Lookup[payload, "Roots", $Failed];
  If[! ListQ[entries] || ! ListQ[roots] ||
      ! VectorQ[indices, IntegerQ] ||
      ! AllTrue[indices, 1 <= #1 <= Length[entries] &], Return[$Failed]];
  results = multiquadraticOffDiagonalBlockLetterDLogDataInField[
      entries[[#1]], roots, {\[FormalX], \[FormalY]}] & /@ indices;
  If[! AllTrue[results, AssociationQ], $Failed,
    <|"Indices" -> indices, "Data" -> results|>]
];
multiquadraticOffDiagonalBlockDLogShardTask[dataFile_String, indices_List] := Module[
  {payload = Quiet[CheckAbort[taskBrokerRead[dataFile], $Failed]]},
  If[AssociationQ[payload],
    multiquadraticOffDiagonalBlockDLogShardTask[payload, indices], $Failed]
];
multiquadraticOffDiagonalBlockDLogShardTask[___] := $Failed;

(* Ordered batch constructor.  kernelCount is a Wolfram-worker count: 1 is the
   conservative serial path.  Under KernelPool the TaskBroker owns helpers;
   outside it, 2..8 launch only the missing subkernels and close only those
   launched here.  A failed/malformed shard is recomputed locally, so parallel
   transport can cost time but cannot change the candidate set. *)
multiquadraticOffDiagonalBlockConstructDLogBatch[letters_List, roots_List,
    variables : {x_, y_}, kernelCount_Integer] :=
  multiquadraticOffDiagonalBlockConstructDLogBatch[letters, roots, variables,
    kernelCount, Infinity];
multiquadraticOffDiagonalBlockConstructDLogBatch[letters_List, roots_List,
    variables : {x_, y_}, kernelCount_Integer, deadline_] := Module[
  {count = Length[letters], requested, launched = {}, loadFile, rules,
   inverseRules, payload, dataFile = None, groups, shardResults, data,
   validShardQ, route = "Serial", seconds = 0., body, workerKernels,
   workerIDs, kernelGroups, chunk, k, brokerFree = 0, helperCount = 0,
   helperGroups, helperResults, localGroup, localResult, codes, handle = None,
   timeout = 7200, startTime = AbsoluteTime[], invalidGroups = {},
   budgetResult = None},
  If[! multiquadraticOffDiagonalBlockDeadlineQ[deadline], Return[$Failed]];
  If[multiquadraticOffDiagonalBlockDeadlineExpiredQ[deadline],
    Return[multiquadraticOffDiagonalBlockBudgetExhausted["CandidateDLogs", 0., deadline,
      <|"LetterCount" -> count, "CompletedShards" -> 0|>]]];
  requested = Min[8, Max[1, kernelCount], Max[1, count]];
  If[count === {}, Return[<|"Data" -> {}, "Route" -> route,
      "Subkernels" -> 0, "BrokerHelperCount" -> 0,
      "Seconds" -> 0.|>]];
  validShardQ[result_, group_] := AssociationQ[result] &&
    Lookup[result, "Indices", None] === group &&
    MatchQ[Lookup[result, "Data", None], {___Association}] &&
    Length[result["Data"]] === Length[group];
  body[] := Which[
   requested < 2,
    {seconds, data} = AbsoluteTiming[
      multiquadraticOffDiagonalBlockLetterDLogDataInField[#1, roots, variables] & /@
        letters],

   TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]] &&
       IntegerQ[brokerFree = Quiet[Check[taskBrokerFreeKernels[], 0]]] &&
       brokerFree >= 1,
    helperCount = Min[requested - 1, count - 1, brokerFree];
    rules = Thread[variables -> {\[FormalX], \[FormalY]}];
    inverseRules = Reverse /@ rules;
    payload = <|"Entries" -> (letters /. rules),
      "Roots" -> (roots /. rules)|>;
    dataFile = taskBrokerDataFile[
      "mqdlog_" <> StringReplace[CreateUUID[], "-" -> ""], payload];
    If[! StringQ[dataFile],
      {seconds, data} = AbsoluteTiming[
        multiquadraticOffDiagonalBlockLetterDLogDataInField[#1, roots, variables] & /@
          letters];
      route = "SerialFallback",
      (* The broker receives every helper shard before the mission kernel
         starts its own share.  Its resource controller may then reassign
         those queued seats when the active-family set changes. *)
      groups = Table[Range[offset, count, helperCount + 1],
        {offset, helperCount + 1}];
      helperGroups = Take[groups, helperCount];
      localGroup = Last[groups];
      codes = Table[
        "FeynFacet`Private`multiquadraticOffDiagonalBlockDLogShardTask[" <>
          ToString[dataFile, InputForm] <> "," <>
          ToString[group, InputForm] <> "]", {group, helperGroups}];
      If[NumericQ[deadline],
        timeout = Max[1, Min[timeout,
          Ceiling[deadline - AbsoluteTime[]]]]];
      {seconds, shardResults} = AbsoluteTiming[
        handle = taskBrokerSubmit[codes, "Label" -> "mqdlog",
          "Timeout" -> timeout];
        localResult = multiquadraticOffDiagonalBlockDLogShardTask[payload, localGroup];
        helperResults = taskBrokerCollect[handle];
        If[! ListQ[helperResults] ||
            Length[helperResults] =!= helperCount,
          helperResults = ConstantArray[$Failed, helperCount]];
        Append[helperResults, localResult]];
      invalidGroups = Pick[groups,
        MapThread[! validShardQ[#1, #2] &, {shardResults, groups}], True];
      If[invalidGroups =!= {} &&
          multiquadraticOffDiagonalBlockDeadlineExpiredQ[deadline],
        budgetResult = multiquadraticOffDiagonalBlockBudgetExhausted[
          "CandidateDLogs", AbsoluteTime[] - startTime, deadline,
          <|"LetterCount" -> count,
            "CompletedShards" -> Length[groups] - Length[invalidGroups],
            "MissingShardIndices" -> Flatten[invalidGroups]|>],
        data = ConstantArray[$Failed, count];
        Do[
          chunk = If[validShardQ[shardResults[[k]], groups[[k]]],
            shardResults[[k, "Data"]] /. inverseRules,
            multiquadraticOffDiagonalBlockLetterDLogDataInField[
                letters[[#1]], roots, variables] & /@ groups[[k]]];
          data[[groups[[k]]]] = chunk,
          {k, Length[groups]}];
        route = "TaskBrokerShards"]],

   ! TrueQ[$KernelID === 0],
    {seconds, data} = AbsoluteTiming[
      multiquadraticOffDiagonalBlockLetterDLogDataInField[#1, roots, variables] & /@
        letters],

   True,
    If[Length[Kernels[]] < requested,
      launched = Quiet[Check[LaunchKernels[requested - Length[Kernels[]]], {}]]];
    If[Length[Kernels[]] < requested,
      {seconds, data} = AbsoluteTiming[
        multiquadraticOffDiagonalBlockLetterDLogDataInField[#1, roots, variables] & /@
          letters],
      (* ParallelMap schedules over every live kernel.  That violates the
         requested cap when a caller owns a larger pre-existing pool.
         Select exactly the requested KernelObjects and give each one a
         balanced, deterministic shard through ParallelEvaluate. *)
      workerKernels = Take[Kernels[], requested];
      workerIDs = Quiet[Check[
        ParallelEvaluate[$KernelID, workerKernels], $Failed]];
      If[! VectorQ[workerIDs, IntegerQ] ||
          Length[workerIDs] =!= Length[workerKernels],
        {seconds, data} = AbsoluteTiming[
          multiquadraticOffDiagonalBlockLetterDLogDataInField[#1, roots, variables] & /@
            letters];
        route = "SerialFallback",
      loadFile = $feynFacetLoader;
      If[! AllTrue[ParallelEvaluate[
          NameQ["FeynFacet`Private`multiquadraticOffDiagonalBlockDLogShardTask"],
          workerKernels],
          TrueQ],
        With[{file = loadFile},
          ParallelEvaluate[Quiet[Get[file], General::shdw], workerKernels]]];
      rules = Thread[variables -> {\[FormalX], \[FormalY]}];
      inverseRules = Reverse /@ rules;
      payload = <|"Entries" -> (letters /. rules),
        "Roots" -> (roots /. rules)|>;
      dataFile = FileNameJoin[{$TemporaryDirectory,
        "facet_mq_dlog_" <> StringReplace[CreateUUID[], "-" -> ""] <>
          ".wl"}];
      Put[payload, dataFile];
      (* Round-robin rather than contiguous shards: conjugate algebraic
         letters and hard inhomogeneity entries tend to be adjacent, so this
         prevents one helper from inheriting an entire expensive family. *)
      groups = Table[Range[offset, count, requested],
        {offset, requested}];
      kernelGroups = AssociationThread[workerIDs -> groups];
      {seconds, shardResults} = AbsoluteTiming[Quiet[Check[
        With[{file = dataFile, assignments = kernelGroups},
          ParallelEvaluate[
            FeynFacet`Private`multiquadraticOffDiagonalBlockDLogShardTask[file,
              Lookup[assignments, $KernelID, {}]], workerKernels]],
        $Failed]]];
      If[! ListQ[shardResults] ||
          Length[shardResults] =!= Length[groups],
        shardResults = ConstantArray[$Failed, Length[groups]]];
      data = ConstantArray[$Failed, count];
      Do[
        chunk = If[validShardQ[shardResults[[k]], groups[[k]]],
          shardResults[[k, "Data"]] /. inverseRules,
          multiquadraticOffDiagonalBlockLetterDLogDataInField[
              letters[[#1]], roots, variables] & /@ groups[[k]]];
        data[[groups[[k]]]] = chunk,
        {k, Length[groups]}];
      route = "ParallelShards"]]];
  CheckAbort[body[],
    If[AssociationQ[handle], Quiet[taskBrokerCancel[handle]]];
    If[StringQ[dataFile] && FileExistsQ[dataFile], Quiet[DeleteFile[dataFile]]];
    If[launched =!= {}, Quiet[CloseKernels[launched]]];
    Abort[]];
  If[StringQ[dataFile] && FileExistsQ[dataFile], Quiet[DeleteFile[dataFile]]];
  If[launched =!= {}, Quiet[CloseKernels[launched]]];
  If[AssociationQ[budgetResult], Return[budgetResult]];
  If[! MatchQ[data, {___Association}] || Length[data] =!= count,
    {seconds, data} = AbsoluteTiming[
      multiquadraticOffDiagonalBlockLetterDLogDataInField[#1, roots, variables] & /@
        letters]; route = "SerialFallback"];
  <|"Data" -> data, "Route" -> route,
    "Subkernels" -> Which[route === "ParallelShards", requested,
      route === "TaskBrokerShards", helperCount, True, 0],
    "BrokerHelperCount" -> If[route === "TaskBrokerShards",
      helperCount, 0],
    "Seconds" -> seconds|>
];
multiquadraticOffDiagonalBlockConstructDLogBatch[___] := $Failed;

(* ------------------------------------------------------------------ *)
(* CERTIFIED dlog POTENTIALS (2026-08-26, round-2 item 7)               *)
(* ------------------------------------------------------------------ *)

(* An epsilon form needs the mathematical statement

       omega_a = dlog L_a,     i.e.   omega_a - dL_a/L_a = 0 exactly,

   for an explicit potential L_a.  A closed one-form is not enough: the
   space of closed forms on a multiquadratic surface is strictly larger
   than the span of dlogs of its S-units, so "closed" leaves the result
   uninstallable and the engine has always said so.  What was missing is
   the positive half -- an actual verification, carried with the form.

   Verify once per unique (omega, L) pair and cache the verdict by the
   canonical mathematical pair itself.
   The relation is two Together calls on objects the alphabet layer has
   already normalized; against the algebraic stage it is free, and the
   cache makes a repeated pair free outright.  The key is the pair of
   canonical texts the provenance certificate already hashes, so two
   algebraically identical pairs written differently share one entry.

   SCOPE.  A record whose letter is Missing (the "Diagonal" kind: the
   scalar entries of e and c are closed forms by construction, not
   dlogs) is NOT verified and NOT installable as a certified letter --
   the absent potential is the refusal, exactly as before. *)

$multiquadraticOffDiagonalBlockPotentialSchema = "MultiquadraticVerifiedPotentialV1";
$multiquadraticOffDiagonalBlockPotentialCacheEntryLimit = 4096;
$multiquadraticOffDiagonalBlockPotentialCache = <||>;
$multiquadraticOffDiagonalBlockPotentialCounters =
  <|"Hits" -> 0, "Misses" -> 0, "Verified" -> 0, "Refused" -> 0,
    "Evictions" -> 0, "Seconds" -> 0.|>;

multiquadraticOffDiagonalBlockPotentialCacheReset[] := (
  $multiquadraticOffDiagonalBlockPotentialCache = <||>;
  $multiquadraticOffDiagonalBlockPotentialCounters =
    <|"Hits" -> 0, "Misses" -> 0, "Verified" -> 0, "Refused" -> 0,
      "Evictions" -> 0, "Seconds" -> 0.|>;);

multiquadraticOffDiagonalBlockPotentialStatistics[] :=
  Join[$multiquadraticOffDiagonalBlockPotentialCounters,
    <|"Entries" -> Length[$multiquadraticOffDiagonalBlockPotentialCache],
      "EntryLimit" -> $multiquadraticOffDiagonalBlockPotentialCacheEntryLimit|>];

(* Canonical mathematical data for a (one-form, letter) pair. *)
multiquadraticOffDiagonalBlockPotentialPairKey[letter_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {rules, canonicalLetter, canonicalForm},
  If[MissingQ[letter] || ! MatchQ[form, {_, _}], Return[$Failed]];
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  canonicalLetter = Quiet[Together[letter /. rules]];
  canonicalForm = Quiet[Together /@ (form /. rules)];
  If[! FreeQ[{canonicalLetter, canonicalForm}, $Failed], Return[$Failed]];
  {canonicalLetter, canonicalForm}
];

(* Evidence for the INTERNAL constructor, which has just produced form as
   dlog(letter).  Re-differentiating the same letter and subtracting the
   just-produced form is a tautological second construction, not an
   independent check; on a representative hard multiquadratic block it
   doubled this phase's wall time.  Bind the raw letter spelling and both
   canonical grade-channel payloads, but record explicitly that exactness
   follows from construction.  Caller-supplied pairs still go through
   multiquadraticOffDiagonalBlockVerifyPotential and can be refused. *)
multiquadraticOffDiagonalBlockConstructedDLogEvidence[letter_, form_] := Module[
  {potential},
  potential = <|"Schema" -> $multiquadraticOffDiagonalBlockPotentialSchema,
    "Status" -> "PotentialVerified", "Verified" -> True,
    "Letter" -> letter, "OneForm" -> form,
    "VerificationMethod" -> "ConstructedExactDLog"|>;
  <|"Potential" -> potential|>
];
multiquadraticOffDiagonalBlockConstructedDLogEvidence[___] := $Failed;

(* THE EXACT STATEMENT, made once.  Together is used only as a zero
   test on the DIFFERENCE -- it is not asked to preserve the algebraic
   word of the letter (the trap this repository records), because
   nothing downstream reads this expression: only its vanishing. *)
multiquadraticOffDiagonalBlockPotentialRelationZeroQ[letter_, form : {_, _},
    variables : {x_Symbol, y_Symbol}] := Module[{value, dlog},
  value = Quiet[Together[letter]];
  If[TrueQ[value === 0] ||
      ! FreeQ[value, DirectedInfinity | Indeterminate], Return[False]];
  dlog = Quiet[{Together[D[value, x]/value], Together[D[value, y]/value]}];
  If[! FreeQ[dlog, DirectedInfinity | Indeterminate], Return[False]];
  TrueQ[Quiet[Together[form[[1]] - dlog[[1]]]] === 0] &&
    TrueQ[Quiet[Together[form[[2]] - dlog[[2]]]] === 0]
];

multiquadraticOffDiagonalBlockVerifyPotential[letter_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {key, cached, zeroQ, seconds, record},
  If[MissingQ[letter],
    Return[<|"Schema" -> $multiquadraticOffDiagonalBlockPotentialSchema,
      "Status" -> "NoPotentialOffered", "Verified" -> False,
      "Letter" -> Missing["NoLetter"], "OneForm" -> form,
      "Cached" -> False|>]];
  If[! MatchQ[form, {_, _}],
    Return[<|"Schema" -> $multiquadraticOffDiagonalBlockPotentialSchema,
      "Status" -> "InvalidOneForm", "Verified" -> False,
      "Letter" -> letter, "OneForm" -> Missing["NoForm"],
      "Cached" -> False|>]];
  key = multiquadraticOffDiagonalBlockPotentialPairKey[letter, form, variables, epsilon];
  If[key === $Failed,
    Return[<|"Schema" -> $multiquadraticOffDiagonalBlockPotentialSchema,
      "Status" -> "PairNotNormalizable", "Verified" -> False,
      "Letter" -> letter, "OneForm" -> form, "Cached" -> False|>]];
  (* key is the single structural pair {canonical letter, canonical form}.
     Lookup treats a list as a list of independent keys, so use the
     association's single-key form here. *)
  cached = If[KeyExistsQ[$multiquadraticOffDiagonalBlockPotentialCache, key],
    $multiquadraticOffDiagonalBlockPotentialCache[key], Missing["NoEntry"]];
  If[! MissingQ[cached],
    $multiquadraticOffDiagonalBlockPotentialCounters["Hits"] += 1;
    Return[Join[cached, <|"Cached" -> True|>]]];
  $multiquadraticOffDiagonalBlockPotentialCounters["Misses"] += 1;
  {seconds, zeroQ} = AbsoluteTiming[
    multiquadraticOffDiagonalBlockPotentialRelationZeroQ[letter, form, variables]];
  $multiquadraticOffDiagonalBlockPotentialCounters["Seconds"] += seconds;
  If[TrueQ[zeroQ], $multiquadraticOffDiagonalBlockPotentialCounters["Verified"] += 1,
    $multiquadraticOffDiagonalBlockPotentialCounters["Refused"] += 1];
  record = <|"Schema" -> $multiquadraticOffDiagonalBlockPotentialSchema,
    "Status" -> If[TrueQ[zeroQ], "PotentialVerified", "PotentialRefused"],
    "Verified" -> TrueQ[zeroQ], "Letter" -> letter, "OneForm" -> form,
    "Cached" -> False|>;
  (* bounded by entry count *)
  If[Length[$multiquadraticOffDiagonalBlockPotentialCache] >=
      $multiquadraticOffDiagonalBlockPotentialCacheEntryLimit,
    $multiquadraticOffDiagonalBlockPotentialCache = <||>;
    $multiquadraticOffDiagonalBlockPotentialCounters["Evictions"] += 1];
  AssociateTo[$multiquadraticOffDiagonalBlockPotentialCache, key -> record];
  record
];

(* The verdict over a whole CANDIDATE alphabet: certified only when
   EVERY record carries a verified potential.  Since round-3 A2 this is
   TELEMETRY about the candidate pool -- it never sets the terminal
   certification bit, which belongs to the ACTIVE-support verdict below
   (an unused candidate with zero reconstructed residue cannot obstruct
   installation). *)
multiquadraticOffDiagonalBlockPotentialsCertifiedQ[letterRecords_] :=
  MatchQ[letterRecords, {___Association}] &&
    letterRecords =!= {} &&
    AllTrue[letterRecords,
      TrueQ[Lookup[Lookup[#1, "Potential", <||>], "Verified", False]] &];

(* The kinematic part of a letter: multiplicative factors free of BOTH
   chart variables (numeric content, powers of the regulator, masses)
   are stripped -- dlog(c(eps) L0) and dlog(L0) have identical (x, y)
   components, so a letter like eps*x is the letter x wearing invisible
   content, and an INSTALLED letter must be the epsilon-independent
   representative.  A letter whose variable-carrying part still contains
   the regulator (x + eps) has genuinely kinematics-dependent regulator
   mixing and is not repairable this way: the caller rejects it. *)
multiquadraticOffDiagonalBlockLetterKinematicPart[letter_, variables_List] :=
  Quiet[Check[Module[{t = Together[letter], keep},
    keep[expr_] := Times @@ (Power[#1[[1]], #1[[2]]] & /@
      Select[FactorList[expr],
        ! FreeQ[#1[[1]], Alternatives @@ variables] &]);
    keep[Numerator[t]]/keep[Denominator[t]]], $Failed]];

(* Is a closed form an exact CONSTANT-coefficient combination of the
   verified basis one-forms?  omega_diag = Sum_a c_a omega_a with c_a
   free of the chart variables and the regulator; free parameters are
   set to zero deterministically and BOTH components are rechecked with
   an exact zero test.  A kinematics-dependent coefficient is refused:
   it would turn constant residue matrices into kinematic functions. *)
multiquadraticOffDiagonalBlockDiagonalSpan[form : {_, _}, basisForms_List,
    variables : {x_, y_}] := Module[
  {cs, difference, equations, solutions, values, exact},
  If[basisForms === {}, Return[Missing["NoBasis"]]];
  cs = Table[Unique["spanC"], {Length[basisForms]}];
  difference[mu_, coefficients_] := Together[form[[mu]] -
    Sum[coefficients[[a]] basisForms[[a, mu]], {a, Length[basisForms]}]];
  equations = And @@ Table[
    Numerator[difference[mu, cs]] == 0, {mu, 2}];
  solutions = Quiet[SolveAlways[equations, variables]];
  If[! MatchQ[solutions, {__List}], Return[Missing["NotSpanned"]]];
  values = cs /. First[solutions] /. Alternatives @@ cs -> 0;
  If[! AllTrue[values, FreeQ[#1, Alternatives @@ variables] &],
    Return[Missing["KinematicCoefficient"]]];
  exact = AllTrue[Table[difference[mu, values] === 0 ||
    Together[difference[mu, values]] === 0, {mu, 2}], TrueQ];
  If[! exact, Return[Missing["NotSpanned"]]];
  <|"Spanned" -> True, "Coefficients" -> values|>
];
multiquadraticOffDiagonalBlockDiagonalSpan[___] := Missing["InvalidSpanArguments"];

(* SolveAlways is useful for a tiny residual basis, but its polynomial
   quantifier expansion grows catastrophically with a large dlog alphabet.
   A failed sampled span is only a compression miss: retaining the diagonal
   form is conservative and leaves the downstream exact installation gate
   unchanged.  Bound the historical exact fallback instead of allowing an
   optional alphabet-reduction step to consume a whole off-diagonal block equation budget. *)
$multiquadraticOffDiagonalBlockDiagonalSpanExactBasisLimit = 8;
multiquadraticOffDiagonalBlockDiagonalSpanBoundedExact[form : {_, _},
    basisForms_List, variables : {_, _}] :=
  If[Length[basisForms] <= $multiquadraticOffDiagonalBlockDiagonalSpanExactBasisLimit,
    multiquadraticOffDiagonalBlockDiagonalSpan[form, basisForms, variables],
    Missing["ExactSpanSkippedLargeBasis"]];
multiquadraticOffDiagonalBlockDiagonalSpanBoundedExact[___] :=
  Missing["InvalidBoundedSpanArguments"];

(* Solve a NUMERIC rational affine system with a deterministic free-zero
   section.  This is deliberately smaller than the modular solver below:
   diagonal-span sampling has no modulus and needs only one particular
   vector, followed by independent held-out rational images. *)
multiquadraticOffDiagonalBlockRationalAffineParticular[matrix_?MatrixQ,
    right_List] := Module[
  {dimensions = Dimensions[matrix], unknownCount, reduced, coefficient,
   pivotRows = {}, pivotColumns = {}, pivot, inconsistent, particular},
  If[Length[dimensions] =!= 2 || dimensions[[1]] =!= Length[right],
    Return[$Failed]];
  unknownCount = dimensions[[2]];
  reduced = Quiet[Check[RowReduce[MapThread[Append, {matrix, right}]],
    $Failed]];
  If[reduced === $Failed, Return[$Failed]];
  coefficient = reduced[[All, 1 ;; unknownCount]];
  Do[
    pivot = SelectFirst[Range[unknownCount],
      ! TrueQ[coefficient[[row, #1]] === 0] &,
      Missing["NotFound"]];
    If[! MissingQ[pivot],
      AppendTo[pivotRows, row]; AppendTo[pivotColumns, pivot]],
    {row, Length[coefficient]}];
  inconsistent = AnyTrue[Range[Length[coefficient]], Function[row,
    AllTrue[coefficient[[row]], TrueQ[#1 === 0] &] &&
      ! TrueQ[reduced[[row, -1]] === 0]]];
  If[TrueQ[inconsistent],
    Return[<|"Consistent" -> False, "Rank" -> Length[pivotColumns]|>]];
  particular = ConstantArray[0, unknownCount];
  Do[particular[[pivotColumns[[k]]]] = reduced[[pivotRows[[k]], -1]],
    {k, Length[pivotColumns]}];
  <|"Consistent" -> True, "Rank" -> Length[pivotColumns],
    "ParticularSolution" -> particular|>
];
multiquadraticOffDiagonalBlockRationalAffineParticular[___] := $Failed;

(* The same coefficient matrix with several right-hand sides.  RowReduce
   is allowed to see the appended columns only when every right-hand side
   is consistent; then no appended column can become a pivot, and the
   coefficient pivots define all free-zero sections at once.  If any
   right-hand side is inconsistent the caller falls back to the scalar
   routine, which identifies the individual verdicts without relying on
   a mixed augmented reduction. *)
multiquadraticOffDiagonalBlockRationalAffineParticularBatch[matrix_?MatrixQ,
    rightMatrix_?MatrixQ] := Module[
  {dimensions = Dimensions[matrix], rightDimensions = Dimensions[rightMatrix],
   unknownCount, targetCount, reduced, coefficient, rightReduced,
   pivotRows = {}, pivotColumns = {}, pivot, zeroRows, particular},
  If[Length[dimensions] =!= 2 || Length[rightDimensions] =!= 2 ||
      dimensions[[1]] =!= rightDimensions[[1]] ||
      rightDimensions[[2]] < 1, Return[$Failed]];
  unknownCount = dimensions[[2]];
  targetCount = rightDimensions[[2]];
  reduced = Quiet[Check[RowReduce[Join[matrix, rightMatrix, 2]], $Failed]];
  If[reduced === $Failed, Return[$Failed]];
  coefficient = reduced[[All, 1 ;; unknownCount]];
  rightReduced = reduced[[All, unknownCount + 1 ;; unknownCount + targetCount]];
  zeroRows = Select[Range[Length[coefficient]],
    AllTrue[coefficient[[#1]], TrueQ[#1 === 0] &] &];
  If[AnyTrue[Flatten[rightReduced[[zeroRows]]], ! TrueQ[#1 === 0] &],
    Return[<|"Consistent" -> False|>]];
  Do[
    pivot = SelectFirst[Range[unknownCount],
      ! TrueQ[coefficient[[row, #1]] === 0] &,
      Missing["NotFound"]];
    If[! MissingQ[pivot],
      AppendTo[pivotRows, row]; AppendTo[pivotColumns, pivot]],
    {row, Length[coefficient]}];
  particular = ConstantArray[0, {targetCount, unknownCount}];
  Do[particular[[All, pivotColumns[[k]]]] =
      rightReduced[[pivotRows[[k]], All]],
    {k, Length[pivotColumns]}];
  <|"Consistent" -> True, "Rank" -> Length[pivotColumns],
    "ParticularSolutions" -> particular|>
];
multiquadraticOffDiagonalBlockRationalAffineParticularBatch[___] := $Failed;

(* A constant-coefficient span is a linear-algebra question, not a
   polynomial-quantifier problem.  Decompose every component into the
   declared 2^r rational grade channels, evaluate those rational functions
   at deterministic exact points, and solve the resulting small rational
   system.  A sampled inconsistency is already an exact counterexample.
   A sampled solution is accepted only after six further exact-rational
   held-out points.  This is deliberately a modular-style probabilistic
   certificate (no floating tolerance); the final differential-equation
   image checks remain an independent downstream guard.

   If an expression carries parameters beyond the two chart variables, or
   the deterministic schedule does not determine a section, return typed
   NotApplicable.  Only a small residual basis may then use the historical
   SolveAlways route; a large basis keeps the diagonal form conservatively.
   The optional channel arguments allow the candidate builder to reuse the
   grade-algebra dlogs it has just constructed instead of decomposing the
   same 44-letter basis once per diagonal record. *)
$multiquadraticOffDiagonalBlockDiagonalSpanSamplePoints = {
  {2, 3}, {3, 5}, {5, 2}, {2, 5}, {-1, 2}, {2, -1}, {-2, 3}, {3, -2},
  {-3, 5}, {5, -3}, {1/2, 2/3}, {2/3, 3/5}, {3/5, 5/7}, {5/7, 7/11},
  {-1/2, 2/3}, {2/3, -1/2}, {-2/3, 3/5}, {3/5, -2/3},
  {7, 11}, {11, 7}, {-5, 7}, {7, -5}, {11, 13}, {13, 11},
  {13, 17}, {17, 13}, {-7, 11}, {11, -7}, {17, 19}, {19, 17},
  {-11, 13}, {13, -11}, {1/3, 2/5}, {2/5, 3/7}, {3/7, 5/11},
  {5/11, 7/13}, {-1/3, 2/5}, {2/5, -1/3}, {-3/7, 5/11},
  {5/11, -3/7}, {19, 23}, {23, 19}, {-13, 17}, {17, -13},
  {23, 29}, {29, 23}, {-17, 19}, {19, -17}
};

multiquadraticOffDiagonalBlockDiagonalSpanBasisImages[basisChannels_List,
    variables : {x_, y_}] := Module[
  {images = {}, rules, values, numericRationalQ},
  If[basisChannels === {}, Return[{}]];
  numericRationalQ[value_] := IntegerQ[value] || Head[value] === Rational;
  Do[
    rules = Thread[variables -> point];
    values = Quiet[Check[
      (Flatten[#1 /. rules] &) /@ basisChannels, $Failed]];
    If[values =!= $Failed &&
        AllTrue[Flatten[values], numericRationalQ],
      AppendTo[images, <|"Point" -> point,
        "Rows" -> Transpose[values]|>]],
    {point, $multiquadraticOffDiagonalBlockDiagonalSpanSamplePoints}];
  images
];
multiquadraticOffDiagonalBlockDiagonalSpanBasisImages[___] := $Failed;

(* Several diagonal forms share the same verified dlog basis, grade frame
   and evaluation points.  Solve their constant-coefficient span in one
   augmented reduction instead of repeating the 48-by-N row reduction for
   every scalar entry.  This fast path returns Missing on a mixed or
   parameterful case; the candidate builder then invokes the scalar
   routine for each form, so batching never weakens a verdict. *)
multiquadraticOffDiagonalBlockDiagonalSpansSampled[forms : {{_, _} ..},
    basisForms_List, roots_List, variables : {x_, y_},
    suppliedFormChannels_ : Automatic,
    suppliedBasisChannels_ : Automatic,
    suppliedBasisImages_ : Automatic] := Module[
  {gradeCount = 2^Length[roots], targetCount = Length[forms], formChannels,
   basisChannels, channelShapeQ, basisImages, imageSchedule,
   suppliedBasisImagesQ, basisValues, matrix = {}, rightMatrix = {}, rules,
   targetColumns, targetRows, rows, solve, solutions = None,
   lastRank = -1, validPoints = 0, heldOutPassed = 0,
   requiredHeldOut = 6, numericRationalQ, decompose, residual, verdict,
   basisImageShapeQ, point},
  If[basisForms === {}, Return[Missing["NoBasis"]]];
  channelShapeQ[value_] := MatchQ[value, {_List, _List}] &&
    Dimensions[value] === {2, gradeCount} && FreeQ[value, $Failed];
  decompose[oneForm_] := If[roots === {}, List /@ oneForm,
    Quiet[multiquadraticFieldDecompose[#1, roots] & /@ oneForm]];
  formChannels = If[ListQ[suppliedFormChannels] &&
      Length[suppliedFormChannels] === targetCount &&
      AllTrue[suppliedFormChannels, channelShapeQ],
    suppliedFormChannels, decompose /@ forms];
  basisChannels = If[ListQ[suppliedBasisChannels] &&
      Length[suppliedBasisChannels] === Length[basisForms] &&
      AllTrue[suppliedBasisChannels, channelShapeQ],
    suppliedBasisChannels, decompose /@ basisForms];
  If[! ListQ[formChannels] || Length[formChannels] =!= targetCount ||
      ! AllTrue[formChannels, channelShapeQ] ||
      ! AllTrue[basisChannels, channelShapeQ],
    Return[Missing["SampledSpanDecompositionFailed"]]];
  basisImageShapeQ[image_] := AssociationQ[image] &&
    MatchQ[Lookup[image, "Point", None], {_, _}] &&
    MatrixQ[Lookup[image, "Rows", None]] &&
    Dimensions[image["Rows"]] === {2 gradeCount, Length[basisForms]};
  suppliedBasisImagesQ = ListQ[suppliedBasisImages] &&
      suppliedBasisImages =!= {} &&
      AllTrue[suppliedBasisImages, basisImageShapeQ];
  basisImages = If[suppliedBasisImagesQ, suppliedBasisImages, {}];
  imageSchedule = If[suppliedBasisImagesQ, basisImages,
    <|"Point" -> #1|> & /@ $multiquadraticOffDiagonalBlockDiagonalSpanSamplePoints];
  numericRationalQ[value_] := IntegerQ[value] || Head[value] === Rational;
  multiquadraticOffDiagonalBlockStageStart["diagonal spans: shared solve",
    <|"targets" -> targetCount, "basis" -> Length[basisForms],
      "images" -> Length[imageSchedule],
      "basisImageRoute" -> If[suppliedBasisImagesQ, "Supplied", "Lazy"]|>];
  verdict = Catch[Do[
    point = image["Point"];
    rules = Thread[variables -> point];
    If[suppliedBasisImagesQ,
      rows = image["Rows"],
      basisValues = Quiet[Check[
        (Flatten[#1 /. rules] &) /@ basisChannels, $Failed]];
      If[basisValues === $Failed ||
          ! AllTrue[Flatten[basisValues], numericRationalQ], Continue[]];
      rows = Transpose[basisValues]];
    targetColumns = Quiet[Check[
      Flatten[#1 /. rules] & /@ formChannels, $Failed]];
    If[targetColumns === $Failed ||
        ! AllTrue[Flatten[targetColumns], numericRationalQ], Continue[]];
    targetRows = Transpose[targetColumns];
    validPoints++;
    If[ListQ[solutions],
      residual = Flatten[rows . Transpose[solutions] - targetRows];
      If[AllTrue[residual, TrueQ[#1 === 0] &],
        heldOutPassed++;
        If[heldOutPassed >= requiredHeldOut,
          Throw[Table[<|"Spanned" -> True,
              "Coefficients" -> solutions[[target]],
              "Method" -> "ExactRationalImagesBatch",
              "ConstructionPoints" -> validPoints - heldOutPassed,
              "HeldOutPoints" -> heldOutPassed, "Rank" -> lastRank,
              "BatchTargets" -> targetCount|>,
            {target, targetCount}], "DiagonalSpansVerdict"]];
        Continue[],
        solutions = None; heldOutPassed = 0]];
    matrix = Join[matrix, rows];
    rightMatrix = Join[rightMatrix, targetRows];
    If[Length[matrix] < Length[basisForms], Continue[]];
    solve = multiquadraticOffDiagonalBlockRationalAffineParticularBatch[
      matrix, rightMatrix];
    If[! AssociationQ[solve] || ! TrueQ[solve["Consistent"]],
      Throw[Missing["BatchSpanMixedOrInconsistent"],
        "DiagonalSpansVerdict"]];
    lastRank = solve["Rank"];
    solutions = solve["ParticularSolutions"];
    heldOutPassed = 0,
    {image, imageSchedule}], "DiagonalSpansVerdict"];
  multiquadraticOffDiagonalBlockStageDone["diagonal spans: shared solve",
    <|"targets" -> targetCount, "validPoints" -> validPoints,
      "status" -> If[ListQ[verdict], "Spanned", "Fallback"]|>];
  If[ListQ[verdict] && Length[verdict] === targetCount, Return[verdict]];
  Missing[If[validPoints === 0, "SampledSpanNotApplicable",
    "SampledSpanBatchFallback"]]
];
multiquadraticOffDiagonalBlockDiagonalSpansSampled[___] :=
  Missing["InvalidSampledSpansArguments"];

multiquadraticOffDiagonalBlockDiagonalSpanSampled[form : {_, _}, basisForms_List,
    roots_List, variables : {x_, y_}, suppliedFormChannels_ : Automatic,
    suppliedBasisChannels_ : Automatic,
    suppliedBasisImages_ : Automatic] := Module[
  {gradeCount = 2^Length[roots], formChannels, basisChannels, channelShapeQ,
   basisImages, matrix = {}, right = {}, rules, targetValues, rows, solve,
   solution = None, lastRank = -1, validPoints = 0, heldOutPassed = 0,
   requiredHeldOut = 6, numericRationalQ, decompose, residual, verdict,
   basisImageShapeQ, point},
  If[basisForms === {}, Return[Missing["NoBasis"]]];
  multiquadraticOffDiagonalBlockStageStart["diagonal span: channel preparation",
    <|"basis" -> Length[basisForms], "rank" -> Length[roots]|>];
  channelShapeQ[value_] := MatchQ[value, {_List, _List}] &&
    Dimensions[value] === {2, gradeCount} && FreeQ[value, $Failed];
  decompose[oneForm_] := If[roots === {}, List /@ oneForm,
    Quiet[multiquadraticFieldDecompose[#1, roots] & /@ oneForm]];
  formChannels = If[channelShapeQ[suppliedFormChannels],
    suppliedFormChannels, decompose[form]];
  basisChannels = If[
    ListQ[suppliedBasisChannels] &&
      Length[suppliedBasisChannels] === Length[basisForms] &&
      AllTrue[suppliedBasisChannels, channelShapeQ],
    suppliedBasisChannels, decompose /@ basisForms];
  If[! channelShapeQ[formChannels] ||
      ! AllTrue[basisChannels, channelShapeQ],
    Return[Missing["SampledSpanDecompositionFailed"]]];
  basisImageShapeQ[image_] := AssociationQ[image] &&
    MatchQ[Lookup[image, "Point", None], {_, _}] &&
    MatrixQ[Lookup[image, "Rows", None]] &&
    Dimensions[image["Rows"]] === {2 gradeCount, Length[basisForms]};
  basisImages = If[ListQ[suppliedBasisImages] &&
      suppliedBasisImages =!= {} &&
      AllTrue[suppliedBasisImages, basisImageShapeQ],
    suppliedBasisImages,
    multiquadraticOffDiagonalBlockDiagonalSpanBasisImages[basisChannels, variables]];
  If[! ListQ[basisImages] || basisImages === {},
    Return[Missing["SampledSpanNoBasisImages"]]];
  multiquadraticOffDiagonalBlockStageDone["diagonal span: channel preparation",
    <|"basis" -> Length[basisChannels], "images" -> Length[basisImages]|>];
  numericRationalQ[value_] := IntegerQ[value] || Head[value] === Rational;
  verdict = Catch[Do[
    point = image["Point"];
    rows = image["Rows"];
    multiquadraticOffDiagonalBlockStageStart["diagonal span: rational image",
      <|"point" -> point, "accepted" -> validPoints|>];
    rules = Thread[variables -> point];
    targetValues = Quiet[Check[Flatten[formChannels /. rules], $Failed]];
    If[targetValues === $Failed ||
        ! AllTrue[targetValues, numericRationalQ],
      multiquadraticOffDiagonalBlockStageDone["diagonal span: rational image",
        <|"point" -> point, "status" -> "Rejected"|>];
      Continue[]];
    validPoints++;
    multiquadraticOffDiagonalBlockStageDone["diagonal span: rational image",
      <|"point" -> point, "rows" -> Length[rows]|>];
    (* Once a construction prefix has proposed constant coefficients,
       the next points are HELD OUT: they neither choose nor modify that
       vector when it passes.  Six independent exact-rational images are
       the same probabilistic certification policy used by the modular
       off-diagonal block equation solver; no floating tolerance enters.  A failure is folded
       into the construction system and a new section is solved. *)
    If[ListQ[solution],
      residual = Together /@ (rows . solution - targetValues);
      If[AllTrue[residual, TrueQ[#1 === 0] &],
        heldOutPassed++;
        If[heldOutPassed >= requiredHeldOut,
          Throw[<|"Spanned" -> True, "Coefficients" -> solution,
            "Method" -> "ExactRationalImages",
            "ConstructionPoints" -> validPoints - heldOutPassed,
            "HeldOutPoints" -> heldOutPassed, "Rank" -> lastRank|>,
            "DiagonalSpanVerdict"]];
        Continue[],
        solution = None; heldOutPassed = 0]];
    matrix = Join[matrix, rows];
    right = Join[right, targetValues];
    If[Length[matrix] < Length[basisForms], Continue[]];
    multiquadraticOffDiagonalBlockStageStart["diagonal span: row reduction",
      <|"rows" -> Length[matrix], "columns" -> Length[basisForms]|>];
    solve = multiquadraticOffDiagonalBlockRationalAffineParticular[matrix, right];
    multiquadraticOffDiagonalBlockStageDone["diagonal span: row reduction",
      <|"status" -> If[AssociationQ[solve],
        Lookup[solve, "Consistent", None], "Failed"]|>];
    If[! AssociationQ[solve],
      Throw[Missing["SampledSpanLinearSolveFailed"],
        "DiagonalSpanVerdict"]];
    If[! TrueQ[solve["Consistent"]],
      Throw[<|"Spanned" -> False, "Method" -> "ExactSampleCounterexample",
        "ValidPoints" -> validPoints, "Rank" -> solve["Rank"]|>,
        "DiagonalSpanVerdict"]];
    lastRank = solve["Rank"];
    solution = solve["ParticularSolution"];
    heldOutPassed = 0,
    {image, basisImages}],
    "DiagonalSpanVerdict"];
  If[verdict =!= Null, Return[verdict]];
  Missing[If[validPoints === 0, "SampledSpanNotApplicable",
    "SampledSpanUnderdetermined"]]
];
multiquadraticOffDiagonalBlockDiagonalSpanSampled[___] :=
  Missing["InvalidSampledSpanArguments"];

(* THE INSTALLATION VERDICT (round-3 A2): computed from the exact
   reconstructed representation, never from the candidate pool.  A
   letter is ACTIVE iff at least one entry of its reconstructed residue
   matrix K_a(eps) is not the zero rational function -- an exact
   one-variable test per scalar, never a sampled or floating one.
   Verified potentials are required exactly for the active support; an
   empty active alphabet is vacuously certified for a basis-transformation block-only
   solution (AllTrue[{}, ...] is the desired mathematical semantics).
   If reconstruction was skipped or failed the verdict is
   PendingReconstruction, not False. *)
multiquadraticOffDiagonalBlockActivePotentialCertification[
    letterRecords : {___Association}, residues_, reconstructedQ_] := Module[
  {zeroEntryQ, activeQ, active, inactive, unverifiedActive},
  If[! TrueQ[reconstructedQ] || ! ListQ[residues] ||
      Length[residues] =!= Length[letterRecords],
    Return[<|"Status" -> "ActivePotentialCertificationV1",
      "Certified" -> False,
      "Pending" -> "PendingReconstruction",
      "ActiveIndices" -> Missing["PendingReconstruction"],
      "EmptyActiveAlphabet" -> Missing["PendingReconstruction"]|>]];
  zeroEntryQ[q_] := Quiet[Check[Numerator[Together[q]] === 0, False]];
  activeQ[matrix_] := ! AllTrue[Flatten[{matrix}], zeroEntryQ];
  active = Select[Range[Length[letterRecords]], activeQ[residues[[#1]]] &];
  inactive = Complement[Range[Length[letterRecords]], active];
  unverifiedActive = Select[active, ! TrueQ[Lookup[
    Lookup[letterRecords[[#1]], "Potential", <||>], "Verified", False]] &];
  <|"Status" -> "ActivePotentialCertificationV1",
    "ActiveIndices" -> active,
    "InactiveIndices" -> inactive,
    "ActiveLetterRecords" -> (KeyTake[letterRecords[[#1]],
      {"Kind", "Letter", "FormKey", "Potential"}] & /@ active),
    "ActiveOneForms" -> (Lookup[letterRecords[[#1]], "OneForm",
      Missing["NoOneForm"]] & /@ active),
    "ActiveResidues" -> residues[[active]],
    "EmptyActiveAlphabet" -> (active === {}),
    "Certified" -> (unverifiedActive === {}),
    "UnverifiedActiveIndices" -> unverifiedActive|>
];
multiquadraticOffDiagonalBlockActivePotentialCertification[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidActiveCertificationArguments"];

(* The exact basis change for a redundant diagnostic column that
   survived into a reconstructed result: with omega_diag =
   Sum_a c_a omega_a, the residues transfer as
       K_a' = K_a + c_a K_diag,   K_diag' = 0,
   and Sum K' omega is EXACTLY Sum K omega -- the caller rechecks the
   differential residual before installation regardless. *)
multiquadraticOffDiagonalBlockTransferDiagnosticResidues[residues_List,
    diagnosticIndex_Integer, coefficients_List, basisIndices_List] := Module[
  {out = residues, diagResidue},
  If[diagnosticIndex < 1 || diagnosticIndex > Length[residues] ||
      Length[coefficients] =!= Length[basisIndices],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidResidueTransfer"]]];
  diagResidue = residues[[diagnosticIndex]];
  Do[out[[basisIndices[[a]]]] = Map[Together,
      out[[basisIndices[[a]]]] + coefficients[[a]] diagResidue, {-1}],
    {a, Length[basisIndices]}];
  out[[diagnosticIndex]] = Map[0 &, diagResidue, {-1}];
  out
];
multiquadraticOffDiagonalBlockTransferDiagnosticResidues[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidResidueTransferArguments"];

(* The row's already-installed alphabets.  A driver hands over the
   sector state's OffDiagonalBlockSolutions records; the blocks that share this
   block's ROW (same upper sector) or its COLUMN (same lower sector) are
   the ones the row flatness identity couples to it. *)
multiquadraticOffDiagonalBlockRowAlphabetLetters[offDiagonalBlockSolutions_List, sector_,
    lowerSector_] := Module[{selected, letters},
  selected = Select[offDiagonalBlockSolutions,
    AssociationQ[#1] && (Lookup[#1, "Sector", None] === sector ||
      Lookup[#1, "LowerSector", None] === lowerSector) &];
  letters = Flatten[Lookup[selected, "Alphabet", {}] /. Missing[___] :> {}];
  DeleteDuplicates[Select[letters, ! TrueQ[Quiet[Together[#1]] === 0] &]]
];

Options[multiquadraticOffDiagonalBlockCandidateLetters] = {
  "RegulatorSampleCount" -> 4,
  "RegulatorSamplePool" -> Automatic,
  "RowAlphabet" -> Automatic,
  "AdditionalLetters" -> {},
  "AlgebraicLetters" -> Automatic,
  "MaximumNormFactors" -> 2,
  "MaximumNormExponent" -> 2,
  (* 1 = serial; 2..8 = requested Wolfram workers.  Automatic uses the
     current TaskBroker helper allocation inside KernelPool, otherwise the
     already-live subkernels (and launches none). *)
  "DLogKernels" -> Automatic,
  "Deadline" -> Infinity
};

(* The candidate one-form basis, rebuilt.  Five sources, each tagged:
     Diagonal      the scalar entries of e and c (closed forms, not dlogs)
     InhomogeneityDLog   dlogs of the inhomogeneity entries at the CHOSEN samples
     RationalFactor dlogs of the off-diagonal block equation's rational polar curves
     Algebraic     A +- Sqrt[delta], norm-filtered
     RowAlphabet   the installed alphabets of the row and column
     Supplied      whatever the caller adds
   Everything is filtered for membership in the off-diagonal block equation's field, for
   regulator freedom, and (for the diagonal forms, which are not dlogs by
   construction) for closedness. *)
multiquadraticOffDiagonalBlockCandidateLetters[offDiagonalBlockEquation : {e_List, c_List, inhomogeneity_List},
    roots_List, variables : {x_, y_}, epsilon_Symbol, record_Association,
    opts : OptionsPattern[]] := Module[
  {samples, pool, sampleCount, alphabet, algebraic, rowLetters, additional,
   additionalLetters, additionalData,
   records = {}, channelByFormKey = <||>, form, rootSquares, entries, diagonal,
   rowSource, add, counts, rawCount, kindRank, priority,
   grouped, verifiedRecords, verifiedForms, verifiedChannelForms,
   verifiedBasisImages, diagnosticRecords, diagonalBatchRecords,
   diagonalBatchChannelForms, diagonalBatchSpans, diagonalSpanIndex = 0,
   regulatorRejected = 0,
   dlogKernelRequest, dlogKernelCount, dlogDeadline, inhomogeneityEntries,
   derivedLetters,
   derivedBatch, derivedData, inhomogeneityData, rationalData, algebraicData,
   algebraicLetters},
  pool = Replace[OptionValue["RegulatorSamplePool"],
    Automatic :> $multiquadraticOffDiagonalBlockRegulatorSamplePool];
  sampleCount = OptionValue["RegulatorSampleCount"];
  dlogDeadline = OptionValue["Deadline"];
  dlogKernelRequest = OptionValue["DLogKernels"];
  dlogKernelCount = Replace[dlogKernelRequest,
    Automatic :> If[TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]],
      With[{free = Quiet[Check[taskBrokerFreeKernels[], 0]]},
        If[IntegerQ[free] && free >= 0, Max[1, Min[8, free + 1]], 1]],
      Max[1, Min[8, Length[Kernels[]]]]]];
  If[! IntegerQ[sampleCount] || sampleCount < 1 || ! ListQ[pool] || pool === {},
    Return[multiquadraticOffDiagonalBlockFailure["InvalidRegulatorSampleRequest",
      <|"RegulatorSampleCount" -> sampleCount|>]]];
  If[! IntegerQ[dlogKernelCount] || ! (1 <= dlogKernelCount <= 8),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDLogKernelCount",
      <|"DLogKernels" -> dlogKernelRequest,
        "Expected" -> "Automatic or an integer from 1 through 8"|>]]];
  If[! multiquadraticOffDiagonalBlockDeadlineQ[dlogDeadline],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDeadline",
      <|"Deadline" -> dlogDeadline|>]]];
  additional = Flatten[{OptionValue["AdditionalLetters"]}];
  If[AnyTrue[additional, AssociationQ[#1] &&
        (! KeyExistsQ[#1, "Letter"] ||
          ! MatchQ[Lookup[#1, "OffDiagonalBasisTransformationDenominatorNormPower", 1],
            _Integer?NonNegative] ||
          ! MatchQ[Lookup[#1, "SourcePoleOrderUpperBound", 1],
            _Integer?Positive]) &],
    Return[multiquadraticOffDiagonalBlockFailure[
      "InvalidAdditionalLetterMetadata"]]];
  additionalLetters = Map[
    If[AssociationQ[#1], #1["Letter"], #1] &, additional];
  multiquadraticOffDiagonalBlockStageStart["candidate letters: regulator samples"];
  samples = multiquadraticOffDiagonalBlockRegulatorSampleValues[inhomogeneity, variables, epsilon,
    sampleCount, pool];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: regulator samples"];
  rootSquares = squareRootRecordRadicand /@ roots;
  entries = Flatten[samples["SubstitutedEntries"]];
  multiquadraticOffDiagonalBlockStageStart["candidate letters: polar census",
    <|"inhomogeneityEntries" -> Length[entries]|>];
  alphabet = multiquadraticOffDiagonalBlockRationalPolarCurves[
    Join[entries, Flatten[e], Flatten[c]], rootSquares, variables];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: polar census",
    <|"curves" -> Length[alphabet]|>];
  multiquadraticOffDiagonalBlockStageStart["candidate letters: algebraic generation",
    <|"rank" -> Length[roots], "curves" -> Length[alphabet]|>];
  algebraic = Replace[OptionValue["AlgebraicLetters"],
    Automatic :> multiquadraticOffDiagonalBlockAlgebraicLetters[roots, alphabet, variables,
      "MaximumNormFactors" -> OptionValue["MaximumNormFactors"],
      "MaximumNormExponent" -> OptionValue["MaximumNormExponent"]]];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: algebraic generation",
    <|"records" -> Length[Flatten[{algebraic}]]|>];
  If[! MatchQ[algebraic, {___Association}],
    algebraic = <|"Kind" -> "Algebraic", "Letter" -> #1,
      "Norm" -> Missing["NotDerived"]|> & /@ Flatten[{algebraic}]];
  rowSource = Replace[OptionValue["RowAlphabet"],
    Automatic :> multiquadraticOffDiagonalBlockRowAlphabetLetters[
      Replace[Lookup[record, "OffDiagonalBlockSolutions", {}], Except[_List] :> {}],
      Lookup[record, "Sector", None], Lookup[record, "LowerSector", None]]];
  rowLetters = Flatten[{rowSource}];
  (* accumulate RAW records, in a fixed order, with a text key per
     one-form.  Since round-3 A2 there is NO first-wins deduplication
     here: every valid record is collected, and a second phase below
     chooses one representative per one-form by a stable priority, so a
     later VERIFIED letter replaces an earlier unverified record with
     the same one-form instead of being discarded by it. *)
  add[kind_String, letterIn_, oneFormIn_, extra_Association] := Module[
    {fkey, letter = letterIn, oneForm = oneFormIn, stripped,
     extraOut = extra,
     derivedNorm = Missing["NotDerived"],
     constructedQ = oneFormIn === Automatic || AssociationQ[oneFormIn],
     evidence, potential, dlogData,
     channels = Missing["NotRetained"],
     letterChannels = Missing["NotRetained"], channelRepresentationQ,
     constructedChannelEvidenceQ,
     constructedChannelZeroQ = Missing["NotRetained"], zeroQ},
    (* AN INSTALLED LETTER MUST BE EPSILON-INDEPENDENT (round-3 A2): a
       letter such as eps*x has the same kinematic dlog as x, so its
       one-form passes the filter above while the letter symbol does
       not.  A proven kinematics-independent multiplicative content is
       stripped and the potential verified against the stripped letter;
       a letter whose variable-carrying part still contains the
       regulator (x + eps) is rejected. *)
    If[! MissingQ[letter] && ! FreeQ[letter, epsilon],
      stripped = multiquadraticOffDiagonalBlockLetterKinematicPart[letter, variables];
      If[stripped === $Failed || ! FreeQ[stripped, epsilon],
        regulatorRejected++; Return[Null]];
      letter = stripped;
      extraOut = Join[extraOut, <|"StrippedContent" -> True|>]];
    (* Every non-diagonal candidate below passes Automatic: derive the
       one-form HERE, after epsilon-only content has been stripped, so
       the stored letter and stored form are one indivisible construction.
       At positive root rank the grade-algebra path avoids the expanded
       D[L]/L tree; its conservative fallback is the historical routine. *)
    If[constructedQ,
      If[MissingQ[letter], Return[Null]];
      dlogData = If[AssociationQ[oneFormIn], oneFormIn,
        multiquadraticOffDiagonalBlockLetterDLogDataInField[
          letter, roots, variables]];
      If[! AssociationQ[dlogData], Return[Null]];
      oneForm = Lookup[dlogData, "OneForm", $Failed];
      channels = Lookup[dlogData, "Channels", Missing["NotRetained"]];
      letterChannels = Lookup[dlogData, "LetterChannels",
        Missing["NotRetained"]];
      constructedChannelZeroQ = Lookup[dlogData, "ChannelZeroQ",
        Missing["NotRetained"]]];
    If[oneForm === $Failed || ! MatchQ[oneForm, {_, _}], Return[Null]];
    channelRepresentationQ = MatchQ[channels, {_List, _List}] &&
      Dimensions[channels] === {2, 2^Length[roots]} &&
      FreeQ[channels, $Failed];
    If[! constructedQ && ! channelRepresentationQ,
      channels = Quiet[multiquadraticFieldDecompose[#1, roots] & /@ oneForm];
      channelRepresentationQ = MatchQ[channels, {_List, _List}] &&
        Dimensions[channels] === {2, 2^Length[roots]} &&
        FreeQ[channels, $Failed]];
    constructedChannelEvidenceQ = constructedQ && channelRepresentationQ &&
      ListQ[letterChannels] &&
      Length[letterChannels] === 2^Length[roots] &&
      FreeQ[letterChannels, $Failed];
    (* Caller-supplied algebraic letters arrive without the Norm metadata that
       the automatic A+-sqrt(delta) constructor carries.  Their exact letter
       channels are already available here from the parallel dlog batch, so
       derive the active-tower norm from those eight coefficients instead of
       launching a second serial symbolic divisor pass. *)
    If[constructedChannelEvidenceQ &&
        MissingQ[Lookup[extraOut, "Norm", Missing["NoNorm"]]] &&
        ! multiquadraticOffDiagonalBlockZeroQ[Rest[letterChannels]],
      derivedNorm = multiquadraticOffDiagonalBlockActiveGradeNorm[letterChannels,
        Together /@ rootSquares];
      If[derivedNorm =!= $Failed,
        extraOut = Join[extraOut, <|"Norm" -> derivedNorm,
          "NormDerivedFromChannels" -> True|>]]];
    zeroQ = If[channelRepresentationQ && constructedQ &&
        MatchQ[constructedChannelZeroQ, True | False],
      constructedChannelZeroQ,
      If[channelRepresentationQ, multiquadraticOffDiagonalBlockZeroQ[channels],
        multiquadraticOffDiagonalBlockZeroQ[oneForm]]];
    If[TrueQ[zeroQ], Return[Null]];
    (* THE regulator, not a symbol whose NAME starts with "eps" (round-2
       item 1, Codex review 1.6).  The spelling test was wrong in both
       directions: a production regulator named `ee` was invisible to it,
       so a form carrying the regulator entered the supposedly
       regulator-free basis; and an ordinary kinematic or mass symbol
       spelled `eps...` was filtered out of an alphabet it belongs to.
       The regulator argument is already in scope here. *)
    If[! FreeQ[oneForm, epsilon], Return[Null]];
    (* The retained channels are exact membership evidence: the internal
       constructor decomposed the letter, inverted and differentiated in
       the grade algebra, then composed this very one-form.  Re-decomposing
       both materialized components here repeats the expensive operation
       the compact route was designed to avoid.  Forms without that
       evidence retain the historical exact membership gate. *)
    If[! channelRepresentationQ &&
        (! multiquadraticOffDiagonalBlockFieldMemberQ[oneForm[[1]], roots] ||
         ! multiquadraticOffDiagonalBlockFieldMemberQ[oneForm[[2]], roots]), Return[Null]];
    fkey = If[channelRepresentationQ,
      multiquadraticOffDiagonalBlockChannelTextKey[channels, variables, epsilon],
      multiquadraticOffDiagonalBlockFormTextKey[oneForm, variables, epsilon]];
    If[fkey === $Failed, Return[Null]];
    If[constructedChannelEvidenceQ,
      evidence = multiquadraticOffDiagonalBlockConstructedDLogEvidence[
        letter, oneForm];
      If[! AssociationQ[evidence], Return[Null]];
      potential = evidence["Potential"],
      potential = KeyDrop[multiquadraticOffDiagonalBlockVerifyPotential[letter,
        oneForm, variables, epsilon], "Cached"]];
    If[constructedQ && channelRepresentationQ &&
        TrueQ[Lookup[potential, "Verified", False]],
      AssociateTo[channelByFormKey, fkey -> channels]];
    (* The potential is exact by construction or has passed the explicit
       dlog equation.  A closed form without a letter remains non-dlog. *)
    AppendTo[records, Join[<|"Kind" -> kind, "Letter" -> letter,
      "OneForm" -> oneForm, "FormKey" -> fkey,
      (* KeyDrop["Cached"]: whether this pair was verified now or read
         from the content cache is PROCESS telemetry, and two otherwise
         identical preparations must be byte-identical (the prepare-core
         suite compares them with SameQ).  The hit/miss counts stay
         available through multiquadraticOffDiagonalBlockPotentialStatistics[]. *)
      "Potential" -> potential|>,
      If[channelRepresentationQ,
        <|"OneFormChannels" -> channels|>, <||>],
      If[constructedQ && channelRepresentationQ &&
          TrueQ[Lookup[potential, "Verified", False]],
        (* The compiler recomposes these exact channels against both raw
           fields before using them. *)
        <|"DLogChannels" -> channels,
          "DLogLetterChannels" -> letterChannels|>, <||>], extraOut]]];
  multiquadraticOffDiagonalBlockStageStart["candidate letters: diagonal records"];
  diagonal = multiquadraticScalarOneForms /@ {e, c};
  Do[
    If[! multiquadraticClosedOneFormQ[form, variables], Continue[]];
    add["Diagonal", Missing["NotADLog"], form, <||>],
    {form, Flatten[diagonal, 1]}];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: diagonal records",
    <|"records" -> Length[records]|>];
  multiquadraticOffDiagonalBlockStageStart["candidate letters: inhomogeneity dlogs",
    <|"entries" -> Length[entries]|>];
  inhomogeneityEntries = Select[entries,
    ! TrueQ[Together[#1] === 0] &&
      ! FreeQ[#1, Alternatives @@ variables] &];
  (* One helper bootstrap covers every package-derived dlog.  Splitting only
     InhomogeneityDLog and then rebuilding rational and algebraic dlogs serially
     leaves most of a large alphabet on the main kernel.  These constructions
     are independent and obey the same exact grade-algebra data-layout contract. *)
  algebraicLetters = Lookup[algebraic, "Letter", {}];
  derivedLetters = Join[inhomogeneityEntries, alphabet, algebraicLetters,
    additionalLetters];
  derivedBatch = multiquadraticOffDiagonalBlockConstructDLogBatch[
    derivedLetters, roots, variables, dlogKernelCount, dlogDeadline];
  If[! AssociationQ[derivedBatch],
    Return[multiquadraticOffDiagonalBlockFailure["DerivedDLogConstructionFailed"]]];
  If[Lookup[derivedBatch, "Status", None] === "BudgetExhausted",
    Return[derivedBatch]];
  derivedData = Lookup[derivedBatch, "Data", {}];
  If[Length[derivedData] =!= Length[derivedLetters],
    Return[multiquadraticOffDiagonalBlockFailure["DerivedDLogConstructionFailed",
      <|"Expected" -> Length[derivedLetters],
        "Received" -> Length[derivedData]|>]]];
  inhomogeneityData = Take[derivedData, Length[inhomogeneityEntries]];
  rationalData = Take[Drop[derivedData, Length[inhomogeneityEntries]],
    Length[alphabet]];
  algebraicData = Take[Drop[derivedData,
      Length[inhomogeneityEntries] + Length[alphabet]],
    Length[algebraicLetters]];
  additionalData = Drop[derivedData,
    Length[inhomogeneityEntries] + Length[alphabet] + Length[algebraicLetters]];
  MapThread[add["InhomogeneityDLog", #1, #2, <||>] &,
    {inhomogeneityEntries, inhomogeneityData}];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: inhomogeneity dlogs",
    <|"records" -> Length[records],
      "batchedDLogs" -> Length[derivedLetters],
      "route" -> Lookup[derivedBatch, "Route", None],
      "subkernels" -> Lookup[derivedBatch, "Subkernels", 0],
      "seconds" -> Lookup[derivedBatch, "Seconds", Missing["NotMeasured"]]|>];
  multiquadraticOffDiagonalBlockStageStart["candidate letters: rational factors",
    <|"curves" -> Length[alphabet]|>];
  MapThread[add["RationalFactor", #1, #2, <||>] &,
    {alphabet, rationalData}];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: rational factors",
    <|"records" -> Length[records]|>];
  multiquadraticOffDiagonalBlockStageStart["candidate letters: algebraic records",
    <|"candidates" -> Length[algebraic]|>];
  MapThread[Function[{recordItem, dlogItem},
      add["Algebraic", recordItem["Letter"], dlogItem,
        KeyTake[recordItem,
          {"A", "Norm", "QuadraticRadicand", "NormInAlphabet"}]]],
    {algebraic, algebraicData}];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: algebraic records",
    <|"records" -> Length[records]|>];
  multiquadraticOffDiagonalBlockStageStart["candidate letters: inherited records",
    <|"row" -> Length[rowLetters], "supplied" -> Length[additional]|>];
  Do[add["RowAlphabet", letter, Automatic, <||>],
    {letter, rowLetters}];
  MapThread[Function[{item, dlogItem},
    If[AssociationQ[item],
      add["Supplied", item["Letter"], dlogItem,
        KeyTake[item,
          {"OffDiagonalBasisTransformationDenominatorNormPower", "SourcePoleOrderUpperBound"}]],
      add["Supplied", item, dlogItem, <||>]]],
    {additional, additionalData}];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: inherited records",
    <|"records" -> Length[records]|>];
  rawCount = Length[records];
  (* ---- phase 2 (round-3 A2): one representative per one-form, by a
     STABLE priority -- verified potential first, then installed
     row-alphabet letters, supplied letters, derived rational/algebraic/
     inhomogeneity letters, and last the bare diagnostic diagonal forms.  The
     representative sits in the slot of the key's FIRST occurrence, and
     the kinds it superseded travel with it as diagnostics. *)
  multiquadraticOffDiagonalBlockStageStart["candidate letters: deduplicate",
    <|"records" -> rawCount|>];
  kindRank = <|"RowAlphabet" -> 2, "Supplied" -> 3, "RationalFactor" -> 4,
    "Algebraic" -> 4, "InhomogeneityDLog" -> 4, "Diagonal" -> 5|>;
  priority[rec_] := {If[TrueQ[Lookup[Lookup[rec, "Potential", <||>],
      "Verified", False]], 0, 1],
    Lookup[kindRank, Lookup[rec, "Kind", None], 4]};
  grouped = GroupBy[records, Lookup[#1, "FormKey", None] &];
  records = Table[Module[{group = grouped[key], best},
      best = First[MinimalBy[group, priority]];
      If[Length[group] > 1,
        best = Join[best, <|"SupersededKinds" -> DeleteCases[
          Lookup[group, "Kind", None], Lookup[best, "Kind", None]]|>]];
      best],
    {key, DeleteDuplicates[Lookup[records, "FormKey", {}]]}];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: deduplicate",
    <|"records" -> Length[records]|>];
  (* ---- phase 3 (round-3 A2): a bare unverified Diagonal form that is
     an exact CONSTANT-coefficient combination of the verified letters is
     DIAGNOSTIC, not a basis vector: its column is omitted before the
     unknown layout is made, and the span certificate travels with it so
     residues on the verified letters carry the same connection. *)
  multiquadraticOffDiagonalBlockStageStart["candidate letters: diagonal span",
    <|"records" -> Length[records]|>];
  verifiedRecords = Select[records,
    TrueQ[Lookup[Lookup[#1, "Potential", <||>], "Verified", False]] &];
  verifiedForms = Lookup[verifiedRecords, "OneForm", {}];
  verifiedChannelForms = Lookup[channelByFormKey,
    Lookup[verifiedRecords, "FormKey", {}], Missing["NotRetained"]];
  verifiedBasisImages = Automatic;
  diagonalBatchRecords = Select[records,
    Lookup[#1, "Kind", None] === "Diagonal" &&
      ! TrueQ[Lookup[Lookup[#1, "Potential", <||>], "Verified", False]] &];
  diagonalBatchChannelForms = Lookup[diagonalBatchRecords,
    "OneFormChannels", Automatic];
  diagonalBatchSpans = If[diagonalBatchRecords === {}, {},
    multiquadraticOffDiagonalBlockDiagonalSpansSampled[
      Lookup[diagonalBatchRecords, "OneForm", {}], verifiedForms, roots,
      variables, diagonalBatchChannelForms, verifiedChannelForms,
      verifiedBasisImages]];
  (* The normal all-spanned route evaluates basis images lazily and stops
     after its construction plus held-out points.  Only a mixed/refused
     batch needs the complete reusable table for the scalar fallbacks. *)
  If[MissingQ[diagonalBatchSpans] && diagonalBatchRecords =!= {} &&
      verifiedChannelForms =!= {} &&
      AllTrue[verifiedChannelForms, MatchQ[#1, {_List, _List}] &],
    verifiedBasisImages = multiquadraticOffDiagonalBlockDiagonalSpanBasisImages[
      verifiedChannelForms, variables]];
  diagnosticRecords = {};
  records = Fold[Function[{kept, rec},
    If[Lookup[rec, "Kind", None] === "Diagonal" &&
        ! TrueQ[Lookup[Lookup[rec, "Potential", <||>], "Verified", False]],
      Module[{diagonalForm = Lookup[rec, "OneForm", $Failed], span},
        diagonalSpanIndex++;
        span = If[ListQ[diagonalBatchSpans] &&
            Length[diagonalBatchSpans] === Length[diagonalBatchRecords],
          diagonalBatchSpans[[diagonalSpanIndex]],
          multiquadraticOffDiagonalBlockDiagonalSpanSampled[diagonalForm,
            verifiedForms, roots, variables,
            Lookup[rec, "OneFormChannels", Automatic],
            verifiedChannelForms, verifiedBasisImages]];
        If[MissingQ[span],
          span = multiquadraticOffDiagonalBlockDiagonalSpanBoundedExact[
            diagonalForm, verifiedForms, variables]];
        If[AssociationQ[span] && TrueQ[span["Spanned"]],
          AppendTo[diagnosticRecords, Join[rec,
            <|"Diagnostic" -> True, "SpannedBy" -> span["Coefficients"],
              "SpanCertificate" -> KeyDrop[span, "Coefficients"]|>]];
          kept,
          Append[kept, rec]]],
      Append[kept, rec]]], {}, records];
  multiquadraticOffDiagonalBlockStageDone["candidate letters: diagonal span",
    <|"installed" -> Length[records],
      "diagnostic" -> Length[diagnosticRecords]|>];
  counts = Association[Table[kind -> Count[records, item_ /;
      Lookup[item, "Kind", None] === kind],
    {kind, {"Diagonal", "InhomogeneityDLog", "RationalFactor", "Algebraic",
      "RowAlphabet", "Supplied"}}]];
  <|"Status" -> "MultiquadraticCandidateLettersV1",
    "OneForms" -> Lookup[records, "OneForm", {}],
    "Letters" -> Lookup[records, "Letter", {}],
    "LetterRecords" -> records,
    (* the spanned diagonal forms, kept OUT of the unknown layout *)
    "DiagnosticRecords" -> diagnosticRecords,
    (* round-2 item 7 + round-3 A2: per-letter verdicts, and a summary
       that is TELEMETRY about the candidate pool -- the installation
       verdict is the ACTIVE-support certification, computed only after
       regulator reconstruction *)
    "PotentialsVerified" -> Count[records,
      item_ /; TrueQ[Lookup[Lookup[item, "Potential", <||>], "Verified",
        False]]],
    "PotentialsRefused" -> Count[records,
      item_ /; ! TrueQ[Lookup[Lookup[item, "Potential", <||>], "Verified",
        False]]],
    "PotentialsCertified" -> multiquadraticOffDiagonalBlockPotentialsCertifiedQ[records],
    "CandidatePotentialSummary" -> <|
      "Considered" -> rawCount,
      "Installed" -> Length[records],
      "Diagnostic" -> Length[diagnosticRecords],
      "RegulatorContentRejected" -> regulatorRejected,
      "Superseded" -> Count[records, item_ /;
        Lookup[item, "SupersededKinds", {}] =!= {}]|>,
    "Alphabet" -> alphabet,
    "AlgebraicLetterRecords" -> Select[records,
      Lookup[#1, "Kind", None] === "Algebraic" &],
    "RegulatorValues" -> samples["Values"],
    "RejectedRegulatorValues" -> samples["RejectedValues"],
    "RegulatorSampleStatus" -> samples["Status"],
    "RowAlphabetLetterCount" -> Length[rowLetters],
    "Counts" -> counts,
    "DeduplicatedCount" -> Length[records]|>
];
multiquadraticOffDiagonalBlockCandidateLetters[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidCandidateLetterArguments"];

(* The basis-transformation block denominator factor contributed by algebraic letters.  A
   multiquadratic basis-transformation block written over a rational denominator acquires the
   NORMS of its algebraic letters, A^2 - B^2 delta, which
   multiquadraticRationalOffDiagonalBasisTransformationDenominator (a Max[0, p-1] rule on the
   inhomogeneity channels, dropping simple poles) can never produce.  Each
   distinct irreducible factor of the norms enters once, to the highest
   power it reaches in any single norm. *)
multiquadraticOffDiagonalBlockNormDenominatorFactor[letterRecords_List,
    variables_List] := Module[
  {normRecords, factorPairs, canonicalPairs, factors},
  normRecords = DeleteCases[Map[Function[record, Module[
      {norm = Lookup[record, "Norm", Missing["NoNorm"]],
       power = Lookup[record, "OffDiagonalBasisTransformationDenominatorNormPower", 1]},
      If[MissingQ[norm] || ! MatchQ[power, _Integer?NonNegative] ||
          power === 0 || TrueQ[Quiet[Together[norm]] === 0], Nothing,
        {norm, power}]]], Select[letterRecords, AssociationQ]], Nothing];
  If[normRecords === {}, Return[1]];
  factorPairs = Flatten[Map[Function[normRecord, Module[{list},
    list = Quiet[FactorList[Expand[Together[First[normRecord]]]]];
    If[! ListQ[list], {},
      ({First[#1], Last[#1] Last[normRecord]} & /@ Select[Rest[list],
        ! FreeQ[First[#1], Alternatives @@ variables] &])]]],
    normRecords], 1];
  If[factorPairs === {}, Return[1]];
  canonicalPairs = DeleteCases[
    {multiquadraticOffDiagonalBlockCanonicalFactor[First[#1], variables], Last[#1]} & /@
      factorPairs, {$Failed | 0, _}];
  If[canonicalPairs === {}, Return[1]];
  factors = DeleteDuplicates[canonicalPairs[[All, 1]],
    TrueQ[Together[#1 - #2] === 0] &];
  Times @@ Table[
    factor^Max[Cases[canonicalPairs,
      {candidate_, power_} /; TrueQ[Together[candidate - factor] === 0] :>
        power]],
    {factor, factors}]
];

(* The basis-transformation block denominator is a set of ADMITTED POLES with orders, not a
   product of two independent denominators: a factor that both the
   inhomogeneity rule and a norm ask for is admitted once, at the larger of the
   two orders.  Multiplying the two would double every shared factor --
   in a measured block that is degree (11,12) instead of (9,9), an ansatz 56%
   wider for no pole the basis-transformation block can reach. *)
multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominator[base_, extra_, variables_List] :=
  Module[{pairs, canonicalPairs, factors, constant, list},
  list[expression_] := Module[{factorList},
    factorList = Quiet[FactorList[Together[expression]]];
    If[! ListQ[factorList], {}, factorList]];
  pairs = Join[list[base], list[extra]];
  constant = Times @@ Cases[pairs,
    {value_ /; FreeQ[value, Alternatives @@ variables], power_} :>
      value^power];
  pairs = Select[pairs, ! FreeQ[First[#1], Alternatives @@ variables] &];
  If[pairs === {}, Return[Together[base]]];
  canonicalPairs = DeleteCases[
    {multiquadraticOffDiagonalBlockCanonicalFactor[First[#1], variables], Last[#1]} & /@
      pairs, {$Failed | 0, _}];
  If[canonicalPairs === {}, Return[Together[base]]];
  factors = DeleteDuplicates[canonicalPairs[[All, 1]],
    TrueQ[Together[#1 - #2] === 0] &];
  Times @@ Table[
    factor^Max[Cases[canonicalPairs,
      {candidate_, power_} /; TrueQ[Together[candidate - factor] === 0] :>
        power]],
    {factor, factors}]
];

(* The deferred divisor census already supplies a product as distinct base /
   exponent sources.  Factoring their complete product makes Together expand a
   large intermediate before FactorList can recover the same factors.  Stream
   the factor pairs instead: exponents ADD within the inhomogeneity product and take
   the MAXIMUM against the independent letter contribution, exactly as
   multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominator does. *)
multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominatorSourceData[sources_List, extra_,
    variables_List] := Module[
  {factorPairs, canonicalize, sameFactorQ, sourceLists, sourcePairs,
   extraPairs, canonicalSources, canonicalExtra, factors, power,
   factorPowers, denominator, degrees},
  If[! AllTrue[sources,
      MatchQ[#1, {_, exponent_Integer /; exponent >= 0}] &], Return[$Failed]];
  factorPairs[expression_, multiplier_Integer] := Module[{list},
    list = Quiet[FactorList[Together[expression]]];
    If[! ListQ[list], Return[$Failed]];
    {First[#1], multiplier Last[#1]} & /@ Rest[list]];
  sourceLists = factorPairs[First[#1], Last[#1]] & /@ sources;
  If[MemberQ[sourceLists, $Failed], Return[$Failed]];
  sourcePairs = Flatten[sourceLists, 1];
  extraPairs = factorPairs[extra, 1];
  If[extraPairs === $Failed, Return[$Failed]];
  sourcePairs = Select[sourcePairs,
    ! FreeQ[First[#1], Alternatives @@ variables] &];
  extraPairs = Select[extraPairs,
    ! FreeQ[First[#1], Alternatives @@ variables] &];
  canonicalize[pairs_List] := DeleteCases[
    {multiquadraticOffDiagonalBlockCanonicalFactor[First[#1], variables], Last[#1]} & /@
      pairs, {$Failed | 0, _}];
  canonicalSources = canonicalize[sourcePairs];
  canonicalExtra = canonicalize[extraPairs];
  sameFactorQ[left_, right_] := SameQ[left, right] ||
    TrueQ[Together[left - right] === 0];
  factors = DeleteDuplicates[
    Join[If[canonicalSources === {}, {}, canonicalSources[[All, 1]]],
      If[canonicalExtra === {}, {}, canonicalExtra[[All, 1]]]],
    sameFactorQ];
  power[pairs_List, factor_] := Total[Last /@ Select[pairs,
    sameFactorQ[First[#1], factor] &]];
  factorPowers = Table[{factor, Max[power[canonicalSources, factor],
      power[canonicalExtra, factor]]}, {factor, factors}];
  denominator = Times @@
    (First[#1]^Last[#1] & /@ factorPowers);
  degrees = Table[Total[(Last[#1] Exponent[First[#1], variable]) & /@
      factorPowers], {variable, variables}];
  <|"Status" -> "OffDiagonalBasisTransformationDenominatorSourceDataV1",
    "OffDiagonalBasisTransformationDenominator" -> denominator,
    "OffDiagonalBasisTransformationDenominatorDegrees" -> degrees,
    "FactorPowers" -> factorPowers|>
];
multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominatorSourceData[___] := $Failed;

multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominatorSources[sources_List, extra_,
    variables_List] := Module[{data =
      multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominatorSourceData[
        sources, extra, variables]},
  If[AssociationQ[data], data["OffDiagonalBasisTransformationDenominator"], $Failed]
];
multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominatorSources[___] := $Failed;

End[];
