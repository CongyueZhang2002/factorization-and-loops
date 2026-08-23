(* The direct root-channel off-diagonal strip solver (2026-08-23).

   An off-diagonal block whose entries live in a multiquadratic
   coefficient field Q(sqrt(delta_1),...,sqrt(delta_r)) and whose root
   set has NO joint rational chart cannot go through
   SolveEpsFormStripInFrame (it stops with NoRationalStripChart).  This
   module solves such a block directly in the grade basis of
   MultiquadraticAlgebra.wl: the ansatz

     G_ij = Sum_{grade,monomial} g[i,j,grade,monomial] x^p y^q / Q(x,y) r_grade

   with constant unknowns g and constant residues R, forced by

     d_mu G - eps (E_mu G - G C_mu) + eps Sum_a R_a omega_a,mu = Bbar_mu

   (the package strip convention: dG = eps (e G - G c) + bbar -
   eps Sum_a R_a dlog L_a).  Each grade of that identity is a separate
   rational equation, so one modular point contributes
   2^r * 2 * upper * lower equations and no square root of the field is
   ever taken during assembly.

   Sources: External/CodexExchange/triple_root_2026-08-22/
   direct_root_channel_assembler_xh/DirectRootChannelAssembler.wl
   (compile / prime forms / epsilon collapse / point and sample
   assembly / sign transforms / differential check),
   TripleRootStripAdapter.wl (channel decomposition, one-form basis,
   gauge denominator), TripleRootReconstructionPrototype.wl
   (preparation ABI, canonical affine solve, unpacking, exact channel
   residual), TripleRootAffinePilot.wl (the independent split-sign row
   assembly used as the differential reference).

   Contract, and it is NOT the package solution contract.  Installation
   of a strip requires Alphabet plus constant residue matrices and a
   certified dlog potential (familyRowGaugeDLogForm and the family
   certificate).  This solver produces closed one-forms, not certified
   potentials, so its terminal success status is "ModularConsistent"
   and NEVER "Solved" (package bug handoff 2026-08-23, External gap 2;
   Design/MultiquadraticPromotion.md section 3).  The sector driver
   records a ModularConsistent result, it never installs it.

   Changes required by the handoff and made here:
     - the production sampler has NO "BranchFlipMask" option: direct
       grade rows are branch invariant, and a flip changes no equation
       (External gap 1).  Sign flips exist only in the sign-transform
       and differential-certificate functions below, where they are the
       object under test.  Passing the option to a production entry
       point is a typed error, not a silently ignored rule;
     - fingerprints canonicalize the chart variables and the regulator
       to formal System` symbols before hashing, so no fingerprint
       depends on the reader's $Context (pool defect 3);
     - artifact hydration splits the raw load from validation, takes
       the artifact context explicitly, and uses Quiet[CheckAbort[...]]
       rather than Quiet[Check[Get[...], $Failed]], which discards a
       valid artifact after any suppressed message (pool defect 4).
       FamilyArtifactRead has both defects and is deliberately not used
       here;
     - every failure is a typed Association whose "Status" names the
       failure; no entry point returns a bare $Failed.  The four channel
       primitives (multiquadraticFieldDecompose / FieldInverse /
       FieldCompose / LiftLocalChannels) keep the source's $Failed
       sentinel: the tensor compilers detect a failed leaf structurally
       with FreeQ, which an Association would defeat;
     - an explicitly requested plan-discovery backend fails closed
       rather than falling through to the Wolfram path (handoff
       existing-defect 1).

   Reused instead of ported: the strip adapter's TRCurrentRoots,
   TRClassifyStripRecord and TRApplyRootBranches are the package's
   transportChartCurrentRoots, transportChartRootIndices and
   transportChartApplyRootBranches; only the census matcher is
   tightened here (see multiquadraticStripRootCensus).

   Deliberately NOT ported in this pass:
     - the DRCA serialization cache (DRCAReadCompiledArtifact,
       DRCAWriteCompiledArtifact and their fingerprint rebinding): it
       is a campaign-scale I/O layer for reusing one compiled system
       across pool workers, and the promotion gate is prepare /
       assemble / verify.  The context-explicit reader below is the
       piece that layer needed and the piece the handoff faulted;
     - the CRT + Thiele rational-in-epsilon interpolation batch of
       TripleRootReconstructionPrototype.wl.  The exact lift here is
       per regulator value (CRT over the sampled primes plus rational
       reconstruction of the canonical particular solution), which is
       what a modular-consistency certificate needs; reconstructing the
       regulator dependence of the gauge belongs to the installation
       route that gap 2 blocks;
     - the FLINT affine-RREF backend (native binary, request/response
       protocol, witness certificates).  It is requested through the
       "PlanDiscoveryBackend" option surface and fails closed here;
     - TRDecomposeStripRecord, the whole-strip channel round-trip
       reporter.  Its statement (every entry decomposes and recomposes
       exactly) is made inside the compiler, per scalar, by
       multiquadraticStripDecomposeScalar, and a separate report of it
       would be a second source of truth. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticStripFailure, multiquadraticStripFingerprint,
  multiquadraticStripCanonicalRules, multiquadraticStripCanonicalExpression,
  multiquadraticStripContextFreeQ, multiquadraticStripZeroQ,
  multiquadraticStripModRational,
  multiquadraticFieldInverse, multiquadraticFieldDecompose,
  multiquadraticFieldCompose, multiquadraticLiftLocalChannels,
  multiquadraticClosedOneFormQ, multiquadraticOneFormKey,
  multiquadraticDeduplicateOneForms, multiquadraticScalarOneForms,
  multiquadraticDiagonalOneFormBasis, multiquadraticCandidateOneFormBasis,
  multiquadraticRationalGaugeDenominator,
  multiquadraticStripRootOrder, multiquadraticStripRootCensus,
  multiquadraticStripRationalSquareQ, multiquadraticStripSquareClassSquareQ,
  multiquadraticStripCompileNormalizations,
  multiquadraticStripGaugeIndex, multiquadraticStripResidueIndex,
  multiquadraticStripPointRowIndex, multiquadraticStripColumnOrder,
  multiquadraticStripRowOrder, multiquadraticStripABIPayload,
  multiquadraticStripPrepare, multiquadraticStripPreparationValidQ,
  multiquadraticStripCompilePolynomial, multiquadraticStripCompileRational,
  multiquadraticStripDecomposeScalar, multiquadraticStripCompileTensor,
  multiquadraticStripFormShape, multiquadraticStripSemanticPayload,
  multiquadraticStripCompile, multiquadraticStripCompiledValidQ,
  multiquadraticStripMapRationals, multiquadraticStripReducePolynomial,
  multiquadraticStripReduceRational, multiquadraticStripCacheInsert,
  multiquadraticStripPrimeForms, multiquadraticStripCollapsePolynomial,
  multiquadraticStripCollapseRational, multiquadraticStripCollapseEpsilon,
  multiquadraticStripMaximumExponents, multiquadraticStripEvaluatePolynomial,
  multiquadraticStripEvaluateRational, multiquadraticStripEvaluateForms,
  multiquadraticStripPolynomialImageValidQ,
  multiquadraticStripRationalImageValidQ,
  multiquadraticStripEpsilonFormsValidQ, multiquadraticStripMaskFactorMod,
  multiquadraticStripCharacter, multiquadraticStripAssemblePointInternal,
  multiquadraticStripAssemblePoint, multiquadraticStripNormalizationRows,
  multiquadraticStripAssembleSample, multiquadraticStripSignTransform,
  multiquadraticStripTransformPointToSigns,
  multiquadraticStripTransformSampleToSigns,
  multiquadraticStripSplitPointRows,
  multiquadraticStripDifferentialCheckPoint,
  multiquadraticStripAffineSolve, multiquadraticStripUnpackVector,
  multiquadraticStripChannelMatrixProduct,
  multiquadraticStripExactChannelResidual, multiquadraticStripLiftVector,
  multiquadraticStripArtifactWrite, multiquadraticStripArtifactLoadRaw,
  multiquadraticStripReadPreparedArtifact, multiquadraticStripOptionNames,
  multiquadraticStripProductionOptionGate, multiquadraticStripBackendGate,
  multiquadraticStripClearCaches, solveEpsFormStripMultiquadratic,
  $multiquadraticStripMaximumRootCount, $multiquadraticStripMaximumEpsilonDegree,
  $multiquadraticStripSourceFile, $multiquadraticStripSourceSHA256,
  $multiquadraticStripPrimeCache, $multiquadraticStripEpsilonCache,
  $multiquadraticStripDefaultPrimes, $multiquadraticStripDefaultRegulatorValues
];

$multiquadraticStripMaximumRootCount = 3;
$multiquadraticStripMaximumEpsilonDegree = 256;
$multiquadraticStripPrimeCache = <||>;
$multiquadraticStripEpsilonCache = <||>;

(* The source identity is bound once, at load: DRCA re-hashed its own
   file after every point assembly, which is one file read per modular
   point and buys nothing that a boundary check does not. *)
$multiquadraticStripSourceFile = If[StringQ[$InputFileName],
  ExpandFileName[$InputFileName], ""];
$multiquadraticStripSourceSHA256 = If[$multiquadraticStripSourceFile =!= "" &&
    FileExistsQ[$multiquadraticStripSourceFile],
  FileHash[$multiquadraticStripSourceFile, "SHA256", "HexString"],
  Missing["SourceFileUnavailable"]];

(* Sampling defaults: primes are 3 mod 4 so that every split point has
   an explicit square root (the sign-branch certificate needs one), and
   below 2^31 so that products stay machine integers. *)
$multiquadraticStripDefaultPrimes = {2147483423, 2147483399};
$multiquadraticStripDefaultRegulatorValues = {1/13, 3/17};

multiquadraticStripFailure[status_String, data_: <||>] := Join[
  <|"Status" -> status, "Module" -> "MultiquadraticStripSolve"|>, data];

multiquadraticStripFingerprint[value_] :=
  Hash[ToString[InputForm[value]], "SHA256", "HexString"];

multiquadraticStripZeroQ[value_] :=
  AllTrue[Flatten[{value}], TrueQ[Together[#1] === 0] &];

multiquadraticStripModRational[value_, prime_Integer] := Module[
  {rational = Together[value], denominator},
  If[! (IntegerQ[rational] || Head[rational] === Rational),
    Return[$Failed]];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[rational] PowerMod[denominator, -1, prime], prime]
];

(* Canonicalization for every stored fingerprint: the chart variables
   and the regulator become formal System` symbols, so the InputForm
   text of an ABI payload is the same in Global`, in a dedicated
   artifact context, and after CANONICA has taken over eps/x/y. *)
multiquadraticStripCanonicalRules[variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  Join[Thread[variables -> {\[FormalX], \[FormalY]}], {epsilon -> \[FormalE]}];

multiquadraticStripCanonicalExpression[expression_, rules_List] := Module[
  {rational = Together[expression /. rules]},
  {Expand[Numerator[rational]], Expand[Denominator[rational]]}
];

multiquadraticStripContextFreeQ[value_] := AllTrue[
  DeleteDuplicates[Cases[value, symbol_Symbol :> symbol, {0, Infinity},
    Heads -> True]],
  Context[#1] === "System`" &];

(* Canonical text for a payload field.  The context freedom is decided
   on the EXPRESSION, not on its printed form: a Global` symbol prints
   without its context whenever Global` happens to be on the context
   path, so a textual backtick test would pass exactly when the reader
   is the one that made the text ambiguous. *)
multiquadraticStripCanonicalText[expression_, rules_List] := Module[
  {canonical = multiquadraticStripCanonicalExpression[expression, rules]},
  If[! multiquadraticStripContextFreeQ[canonical], $Failed,
    ToString[InputForm[canonical]]]
];

(* ------------------------------------------------------------------ *)
(* Field arithmetic in the grade basis                                  *)
(* ------------------------------------------------------------------ *)

(* Inversion is a 2^r x 2^r rational linear solve followed by the exact
   product check; the check, not LinearSolve's message channel, decides
   (Check would reject a valid inverse after any suppressed message). *)
multiquadraticFieldInverse[a_List, deltas_List] /;
    Length[a] === 2^Length[deltas] := Module[
  {dimension = Length[a], columns, matrix, inverse, check},
  If[multiquadraticStripZeroQ[Rest[a]],
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
  If[! multiquadraticStripZeroQ[check - UnitVector[dimension, 1]], $Failed, inverse]
];
multiquadraticFieldInverse[___] := $Failed;

(* Root symbols are Module locals, so nothing is interned in a package
   context and nothing survives the call (pool defect 8: a generator
   must not leave thousands of definition-free names behind).  The rank
   ceiling is what makes the fixed triple enough. *)
multiquadraticFieldDecompose[expression_, roots_List] := Module[
  {rank = Length[roots], rootOne, rootTwo, rootThree, deltas, symbols,
   replaced, rational, numerator, denominator, numeratorChannels,
   denominatorChannels, denominatorInverse, result},
  If[rank > $multiquadraticStripMaximumRootCount, Return[$Failed]];
  If[rank === 0,
    rational = Together[expression];
    If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
      Return[$Failed]];
    Return[{rational}]];
  deltas = Together /@ Lookup[roots, "RootSquare", ConstantArray[$Failed, rank]];
  If[! FreeQ[deltas, $Failed], Return[$Failed]];
  symbols = Take[{rootOne, rootTwo, rootThree}, rank];
  replaced = transportChartApplyRootBranches[expression, roots, symbols];
  If[! FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  rational = Together[replaced];
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
  multiquadraticToExpression[channels, Lookup[roots, "Root", {}]];
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
(* One-form span and gauge denominator                                  *)
(* ------------------------------------------------------------------ *)

multiquadraticScalarOneForms[pair : {first_List, second_List}] := Module[
  {dimensions = Dimensions[first]},
  If[Dimensions[second] =!= dimensions || Length[dimensions] =!= 2, Return[{}]];
  Flatten[Table[{first[[i, j]], second[[i, j]]},
    {i, dimensions[[1]]}, {j, dimensions[[2]]}], 1]
];

multiquadraticClosedOneFormQ[form : {_, _}, variables : {x_, y_}] :=
  TrueQ[Together[D[form[[2]], x] - D[form[[1]], y]] === 0];

multiquadraticOneFormKey[form : {_, _}, roots_List] := Module[{channels},
  channels = multiquadraticFieldDecompose[#1, roots] & /@ form;
  If[MemberQ[channels, $Failed], $Failed,
    multiquadraticStripFingerprint[Together /@ Flatten[channels]]]
];

multiquadraticDeduplicateOneForms[forms_List, roots_List, variables_List] := Module[
  {valid, tagged},
  valid = Select[forms,
    ! multiquadraticStripZeroQ[#1] &&
      FreeQ[#1, _Symbol?(StringStartsQ[SymbolName[#1], "eps"] &)] &&
      multiquadraticClosedOneFormQ[#1, variables] &];
  tagged = Cases[Map[{multiquadraticOneFormKey[#1, roots], #1} &, valid],
    {key_ /; key =!= $Failed, form_} :> {key, form}];
  Last /@ DeleteDuplicatesBy[tagged, First]
];

multiquadraticDiagonalOneFormBasis[strip : {e_List, c_List, _List}, roots_List,
    variables : {_Symbol, _Symbol}] :=
  multiquadraticDeduplicateOneForms[
    Join[multiquadraticScalarOneForms[e], multiquadraticScalarOneForms[c]],
    roots, variables];

(* The diagonal span plus dlogs of the forcing entries at a few
   regulator values.  These are CLOSED one-forms, not certified dlog
   letters -- the distinction is the whole of External gap 2. *)
multiquadraticCandidateOneFormBasis[strip : {e_List, c_List, bbar_List},
    roots_List, variables : {x_, y_}, epsilon_Symbol] := Module[
  {diagonal, samples = {0, 1, -1, 2}, forcingEntries, functions, dlogs, combined},
  diagonal = multiquadraticDiagonalOneFormBasis[strip, roots, variables];
  forcingEntries = Flatten[bbar];
  functions = DeleteDuplicates[Flatten[Table[Together[entry /. epsilon -> value],
    {entry, forcingEntries}, {value, samples}]]];
  functions = Select[functions,
    ! TrueQ[Together[#1] === 0] && ! FreeQ[#1, Alternatives @@ variables] &];
  dlogs = ({Together[D[#1, x]/#1], Together[D[#1, y]/#1]} &) /@ functions;
  combined = multiquadraticDeduplicateOneForms[Join[diagonal, dlogs], roots, variables];
  <|"OneForms" -> combined, "DiagonalCount" -> Length[diagonal],
    "ForcingDLogCandidates" -> Length[dlogs],
    "DeduplicatedCount" -> Length[combined]|>
];

(* One power below the worst forcing pole: the gauge may carry the
   repeated part of a channel denominator, never more. *)
multiquadraticRationalGaugeDenominator[channelForcing_, variables_List] := Module[
  {entries, factorPairs, factors, powers},
  entries = Flatten[channelForcing];
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
(* Preparation: root order, index ABI, support, normalizations          *)
(* ------------------------------------------------------------------ *)

(* Frame order alone is not a stable ABI across catalog edits, so the
   selected roots are re-sorted by a canonical fingerprint of their
   root squares.  Two roots with the same square would give one
   generator two sign bits and are rejected. *)
(* 2^r independent sign automorphisms need r independent square
   classes: distinct radicands are not enough, {x, y, x y} has rank two
   and would give one generator two sign bits.  Factorization over Q
   detects exactly the rational-function square relations this
   evaluator admits.  The Codex sources check only for DUPLICATE root
   squares; FamilyRowGaugeFiniteField.wl's canonicalizer has this
   stronger check, and the neutral module must carry it or the
   duplicate cannot be deleted in favour of it (handoff External gap
   3).  Kept algorithmically identical to that copy so the differential
   test can compare verdicts. *)
multiquadraticStripRationalSquareQ[value : (_Integer | _Rational)] :=
  value >= 0 && IntegerQ[Sqrt[Numerator[value]]] &&
    IntegerQ[Sqrt[Denominator[value]]];
multiquadraticStripRationalSquareQ[_] := False;

multiquadraticStripSquareClassSquareQ[expression_] := Module[
  {q, numeratorFactors, denominatorFactors, constant},
  q = Quiet[Together[expression]];
  If[! FreeQ[q, Power[_, exponent_Rational /; Denominator[exponent] =!= 1]],
    Return[False]];
  numeratorFactors = Quiet[FactorList[Numerator[q]]];
  denominatorFactors = Quiet[FactorList[Denominator[q]]];
  If[! ListQ[numeratorFactors] || ! ListQ[denominatorFactors] ||
      numeratorFactors === {} || denominatorFactors === {}, Return[False]];
  constant = First[First[numeratorFactors]]/First[First[denominatorFactors]];
  multiquadraticStripRationalSquareQ[constant] &&
    AllTrue[Rest[numeratorFactors], EvenQ[Last[#1]] &] &&
    AllTrue[Rest[denominatorFactors], EvenQ[Last[#1]] &]
];

multiquadraticStripRootOrder[frame_Association, variables : {_Symbol, _Symbol},
    indices_List, epsilon_Symbol] := Module[
  {current, roots, rules, decorated, duplicates, dependent},
  current = transportChartCurrentRoots[frame, variables];
  If[! ListQ[current], Return[multiquadraticStripFailure["InvalidMultiquadraticFrame"]]];
  If[! AllTrue[indices, IntegerQ[#1] && 1 <= #1 <= Length[current] &],
    Return[multiquadraticStripFailure["InvalidRootIndices"]]];
  roots = current[[indices]];
  If[! AllTrue[roots, AssociationQ[#1] && KeyExistsQ[#1, "Root"] &&
      KeyExistsQ[#1, "RootSquare"] &&
      TrueQ[Together[#1["Root"]^2 - #1["RootSquare"]] === 0] &],
    Return[multiquadraticStripFailure["InvalidRootMetadata"]]];
  duplicates = Select[Subsets[Range[Length[roots]], {2}],
    TrueQ[Together[roots[[#1[[1]], "RootSquare"]] -
      roots[[#1[[2]], "RootSquare"]]] === 0] &];
  If[duplicates =!= {},
    Return[multiquadraticStripFailure["DuplicateRootSquares",
      <|"DuplicatePairs" -> duplicates|>]]];
  dependent = FirstCase[Rest[Subsets[Range[Length[roots]]]],
    subset_ /; multiquadraticStripSquareClassSquareQ[
      Times @@ Lookup[roots[[subset]], "RootSquare", {}]] :> subset, None];
  If[dependent =!= None,
    Return[multiquadraticStripFailure["DependentRootSquares",
      <|"RootIndices" -> indices[[dependent]]|>]]];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  decorated = MapThread[Function[{root, sourceIndex}, Module[{canonical},
      canonical = ToString[InputForm[multiquadraticStripCanonicalExpression[
        root["RootSquare"], rules]]];
      Join[root, <|"SourceIndex" -> sourceIndex,
        "CanonicalRootSquare" -> canonical,
        "RootFingerprint" -> Hash[canonical, "SHA256", "HexString"]|>]]],
    {roots, indices}];
  decorated = SortBy[decorated,
    {Lookup[#1, "CanonicalRootSquare", ""], Lookup[#1, "RootFingerprint", ""]} &];
  <|"Status" -> "StableRootOrder", "Roots" -> decorated,
    "SourceIndices" -> Lookup[decorated, "SourceIndex", {}],
    "RootFingerprints" -> Lookup[decorated, "RootFingerprint", {}],
    "OrderingFingerprint" -> Hash[Lookup[decorated, "CanonicalRootSquare", {}],
      "SHA256", "HexString"]|>
];

(* Root census.  transportChartRootIndices is the package classifier and
   is called here, but its matcher

     Flatten[Position[rootBases, candidate_ /; Together[base - candidate] === 0]]

   (TransportCharts.wl lines 230-231, identical in Codex's
   TRClassifyStripRecord) searches rootBases at every level and then
   flattens position specifications into root indices.  With frame
   squares {x, y, 1 + x + y} a strip containing only Sqrt[x] is reported
   as rank three: x matches at {1} and again inside 1 + x + y at {3,2},
   and the flattened {3,2} contributes indices 3 and 2.  A superset is
   not harmless -- it multiplies the ansatz by 2^(extra roots), demands
   a split point for roots that do not occur, and can push a genuine
   rank-3 block past the rank ceiling -- so the decision is taken on an
   exact level-1 match here, with the package census kept alongside as a
   diagnostic.  Cannot be repaired in TransportCharts.wl in this pass
   (no existing file is edited). *)
multiquadraticStripRootCensus[strip_, allRoots_List] := Module[
  {frameCensus, rootBases, radicals, matches, indices, unknown},
  frameCensus = transportChartRootIndices[strip, allRoots];
  rootBases = Together /@ (#1["Root"]^2 & /@ allRoots);
  radicals = Lookup[frameCensus, "RadicalBases", {}];
  matches[base_] := Flatten[Position[rootBases,
    candidate_ /; TrueQ[Together[base - candidate] === 0], {1},
    Heads -> False]];
  indices = Sort[DeleteDuplicates[Flatten[matches /@ radicals]]];
  unknown = Select[radicals, matches[#1] === {} &];
  <|"Status" -> If[unknown === {}, "ExactRootClassification",
      "UnclassifiedRadicals"],
    "RootIndices" -> indices, "RadicalBases" -> radicals,
    "UnclassifiedRadicalBases" -> unknown,
    "FrameCensusRootIndices" -> Lookup[frameCensus, "RootIndices", {}],
    "FrameCensusUnclassified" ->
      Lookup[frameCensus, "UnclassifiedRadicalBases", {}]|>
];

multiquadraticStripGaugeIndex[upperDimension_Integer, lowerDimension_Integer,
    gradeCount_Integer, supportCount_Integer, i_Integer, j_Integer,
    grade_Integer, monomial_Integer] :=
  ((((i - 1) lowerDimension + (j - 1)) gradeCount + grade) supportCount) + monomial;

multiquadraticStripResidueIndex[gaugeUnknownCount_Integer,
    upperDimension_Integer, lowerDimension_Integer, letter_Integer,
    i_Integer, j_Integer] :=
  gaugeUnknownCount + (((letter - 1) upperDimension + (i - 1)) lowerDimension) + j;

multiquadraticStripPointRowIndex[targetGrade_Integer, mu_Integer, i_Integer,
    j_Integer, upperDimension_Integer, lowerDimension_Integer] :=
  ((targetGrade 2 + (mu - 1)) upperDimension + (i - 1)) lowerDimension + j;

multiquadraticStripColumnOrder[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "Gauge" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "GaugeIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "GaugeSupport" -> support, "OneFormCount" -> oneFormCount|>;

multiquadraticStripRowOrder[dimensions_List, gradeCount_Integer] := <|
  "PointRows" -> "{outputGrade0Based,direction,upperRow,lowerColumn}",
  "RowIndexFormula" -> "(((grade*2+(mu-1)) upper+(i-1)) lower+j)",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount|>;

multiquadraticStripCompileNormalizations[specifications_List, dimensions_List,
    gradeCount_Integer, support_List, oneForms_List,
    gaugeUnknownCount_Integer] := Catch[Module[
  {compiled = {}, kind, column, positions, i, j, grade, monomial, letter, value,
   unknownCount},
  unknownCount = gaugeUnknownCount + Length[oneForms] (Times @@ dimensions);
  Do[
    If[! AssociationQ[specification],
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation"]]];
    kind = Lookup[specification, "Kind", Missing["Kind"]];
    value = Lookup[specification, "Value", Missing["Value"]];
    If[MissingQ[value],
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation"]]];
    column = Switch[kind,
      "Column", Lookup[specification, "Column", $Failed],
      "GaugeCoefficient",
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        grade = Lookup[specification, "Grade", $Failed];
        monomial = Lookup[specification, "Monomial", $Failed];
        positions = Flatten[Position[support, monomial, {1}, Heads -> False]];
        If[! IntegerQ[i] || ! IntegerQ[j] || ! IntegerQ[grade] ||
            Length[positions] =!= 1 || i < 1 || i > dimensions[[1]] ||
            j < 1 || j > dimensions[[2]] || grade < 0 || grade >= gradeCount,
          $Failed,
          multiquadraticStripGaugeIndex[dimensions[[1]], dimensions[[2]],
            gradeCount, Length[support], i, j, grade, First[positions]]],
      "Residue",
        letter = Lookup[specification, "Letter", $Failed];
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        If[! IntegerQ[letter] || ! IntegerQ[i] || ! IntegerQ[j] ||
            letter < 1 || letter > Length[oneForms] || i < 1 ||
            i > dimensions[[1]] || j < 1 || j > dimensions[[2]], $Failed,
          multiquadraticStripResidueIndex[gaugeUnknownCount, dimensions[[1]],
            dimensions[[2]], letter, i, j]],
      _, $Failed];
    If[! IntegerQ[column] || column < 1 || column > unknownCount,
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation",
        <|"ResolvedColumn" -> column, "UnknownCount" -> unknownCount|>]]];
    AppendTo[compiled, <|"Column" -> column, "Value" -> value, "Kind" -> kind|>],
    {specification, specifications}];
  If[! DuplicateFreeQ[Lookup[compiled, "Column", {}]],
    Throw[multiquadraticStripFailure["DuplicateNormalizationColumn"]]];
  compiled
]];

multiquadraticStripABIPayload[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, dimensions_List,
    gaugeDenominator_, support_List, oneForms_List,
    normalizations_List] := Module[
  {rules, canonicalSquares, canonicalRoots, strip, equationCanonical, payload},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  canonicalSquares = multiquadraticStripCanonicalText[
    Lookup[#1, "RootSquare", $Failed], rules] & /@ roots;
  canonicalRoots = multiquadraticStripCanonicalText[
    Lookup[#1, "Root", $Failed], rules] & /@ roots;
  equationCanonical = ToString[InputForm[Map[
    multiquadraticStripCanonicalText[#1, rules] &, strip, {4}]]];
  payload = <|
    "Schema" -> "MultiquadraticStripPreparationV1",
    "EquationCanonical" -> equationCanonical,
    "EquationFingerprint" -> Hash[equationCanonical, "SHA256", "HexString"],
    "RootCanonicalSquares" -> canonicalSquares,
    "RootCanonicalExpressions" -> canonicalRoots,
    (* Lookup on an EMPTY list of associations returns the default, so
       the rank-0 payload must not use $Failed as its default here *)
    "RootSourceIndices" -> If[roots === {}, {},
      Lookup[roots, "SourceIndex", $Failed]],
    "RootFingerprints" -> Hash[#1, "SHA256", "HexString"] & /@ canonicalSquares,
    "RootOrderingFingerprint" -> Hash[canonicalSquares, "SHA256", "HexString"],
    "Dimensions" -> dimensions,
    "GaugeDenominator" -> multiquadraticStripCanonicalText[gaugeDenominator, rules],
    "GaugeSupport" -> support,
    "OneForms" -> Map[multiquadraticStripCanonicalText[#1, rules] &, oneForms, {2}],
    "Normalizations" -> Map[Join[KeyDrop[#1, "Value"],
      <|"Value" -> multiquadraticStripCanonicalText[
        Lookup[#1, "Value", $Failed], rules]|>] &, normalizations]|>;
  (* a payload that still names a context symbol is not an ABI *)
  If[! FreeQ[payload, $Failed] || ! multiquadraticStripContextFreeQ[payload],
    Return[$Failed]];
  payload
];

Options[multiquadraticStripPrepare] = {
  "OneForms" -> Automatic,
  "GaugeDenominator" -> Automatic,
  "DegreeOffset" -> {0, 0},
  "Support" -> Automatic,
  "NormalizationEquations" -> {},
  "RootIndices" -> Automatic
};

multiquadraticStripPrepare[record_Association, frame_Association,
    opts : OptionsPattern[]] := Module[
  {gate, variables, epsilon, strip, allRoots, classification, rootIndices,
   order, roots, channelForcing, oneFormData, oneForms, gaugeDenominator,
   denominatorDegrees, degreeOffset, numeratorDegrees, support, dimensions,
   gradeCount, gaugeUnknownCount, residueUnknownCount, unknownCount,
   equationsPerPoint, normalizations, payload, fingerprint},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripPrepare]]]];
  If[AssociationQ[gate], Return[gate]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}] ||
      SameQ[variables[[1]], variables[[2]]] || MemberQ[variables, epsilon],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  allRoots = transportChartCurrentRoots[frame, variables];
  If[! ListQ[allRoots],
    Return[multiquadraticStripFailure["AlgebraicFrameNotWellFormed"]]];
  classification = multiquadraticStripRootCensus[strip, allRoots];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[multiquadraticStripFailure["StripContainsUndeclaredRadicals",
      <|"RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]]];
  rootIndices = Replace[OptionValue["RootIndices"],
    Automatic :> classification["RootIndices"]];
  If[! VectorQ[rootIndices, IntegerQ] || rootIndices =!= Sort[rootIndices] ||
      ! DuplicateFreeQ[rootIndices] ||
      ! SubsetQ[rootIndices, classification["RootIndices"]],
    Return[multiquadraticStripFailure["InvalidRootIndices"]]];
  If[Length[rootIndices] > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank",
      <|"MaximumRank" -> $multiquadraticStripMaximumRootCount,
        "ActualRank" -> Length[rootIndices]|>]]];
  order = multiquadraticStripRootOrder[frame, variables, rootIndices, epsilon];
  If[Lookup[order, "Status", None] =!= "StableRootOrder", Return[order]];
  roots = order["Roots"];
  channelForcing = Map[multiquadraticFieldDecompose[#1, roots] &, strip[[3]], {3}];
  If[! FreeQ[channelForcing, $Failed],
    Return[multiquadraticStripFailure["ForcingChannelDecompositionFailed"]]];
  oneFormData = OptionValue["OneForms"];
  If[oneFormData === Automatic,
    oneFormData = multiquadraticCandidateOneFormBasis[strip, roots, variables, epsilon]];
  oneForms = If[AssociationQ[oneFormData],
    Lookup[oneFormData, "OneForms", $Failed], oneFormData];
  If[! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["OneFormBasisFailed"]]];
  gaugeDenominator = Replace[OptionValue["GaugeDenominator"],
    Automatic :> multiquadraticRationalGaugeDenominator[channelForcing, variables]];
  If[TrueQ[Together[gaugeDenominator] === 0] ||
      ! FreeQ[gaugeDenominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorNotRational"]]];
  denominatorDegrees = Exponent[gaugeDenominator, #1] & /@ variables;
  degreeOffset = OptionValue["DegreeOffset"];
  If[! MatchQ[degreeOffset, {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[multiquadraticStripFailure["InvalidDegreeOffset"]]];
  numeratorDegrees = denominatorDegrees + degreeOffset;
  support = OptionValue["Support"];
  If[support === Automatic,
    support = Flatten[Table[{i, j}, {i, 0, numeratorDegrees[[1]]},
      {j, 0, numeratorDegrees[[2]]}], 1]];
  If[! ListQ[support] || support === {} ||
      ! AllTrue[support, MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &],
    Return[multiquadraticStripFailure["InvalidSupport"]]];
  support = Sort[DeleteDuplicates[support]];
  dimensions = Dimensions[strip[[3, 1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      Dimensions[strip[[3]]] =!= Prepend[dimensions, 2],
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  If[Dimensions[strip[[1]]] =!= {2, dimensions[[1]], dimensions[[1]]} ||
      Dimensions[strip[[2]]] =!= {2, dimensions[[2]], dimensions[[2]]},
    Return[multiquadraticStripFailure["InvalidDiagonalDimensions"]]];
  gradeCount = 2^Length[roots];
  gaugeUnknownCount = (Times @@ dimensions) gradeCount Length[support];
  residueUnknownCount = Length[oneForms] (Times @@ dimensions);
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = gradeCount 2 (Times @@ dimensions);
  normalizations = multiquadraticStripCompileNormalizations[
    OptionValue["NormalizationEquations"], dimensions, gradeCount, support,
    oneForms, gaugeUnknownCount];
  If[! ListQ[normalizations], Return[normalizations]];
  payload = multiquadraticStripABIPayload[record, roots, variables, epsilon,
    dimensions, gaugeDenominator, support, oneForms, normalizations];
  If[payload === $Failed,
    Return[multiquadraticStripFailure["ContextSensitiveStripABI"]]];
  fingerprint = multiquadraticStripFingerprint[payload];
  <|"Status" -> "PreparedMultiquadraticStripV1",
    "Record" -> record, "Frame" -> frame,
    "Variables" -> variables, "Regulator" -> epsilon,
    "Roots" -> roots, "RootCount" -> Length[roots],
    "RootIndices" -> rootIndices,
    "RootCensus" -> KeyTake[classification, {"RootIndices", "RadicalBases",
      "FrameCensusRootIndices", "FrameCensusUnclassified"}],
    "RootSourceIndices" -> order["SourceIndices"],
    "RootFingerprints" -> order["RootFingerprints"],
    "RootOrderingFingerprint" -> order["OrderingFingerprint"],
    "RootSquares" -> Lookup[roots, "RootSquare", {}],
    "OneForms" -> oneForms, "OneFormMetadata" -> oneFormData,
    "GaugeDenominator" -> Together[gaugeDenominator],
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "GaugeSupport" -> support, "Dimensions" -> dimensions,
    "GradeCount" -> gradeCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "EquationsPerPoint" -> equationsPerPoint,
    "Normalizations" -> normalizations,
    "ColumnOrder" -> multiquadraticStripColumnOrder[dimensions, gradeCount,
      support, Length[oneForms]],
    "RowOrder" -> multiquadraticStripRowOrder[dimensions, gradeCount],
    "AlgebraABIFingerprint" -> multiquadraticAlgebraABIFingerprint[],
    "ABIPayload" -> payload, "ABIFingerprint" -> fingerprint|>
];
multiquadraticStripPrepare[___] :=
  multiquadraticStripFailure["InvalidPrepareArguments"];

multiquadraticStripPreparationValidQ[preparation_Association] := Module[
  {payload, roots, dimensions, gradeCount, gaugeUnknownCount, residueUnknownCount},
  If[Lookup[preparation, "Status", None] =!= "PreparedMultiquadraticStripV1",
    Return[False]];
  roots = Lookup[preparation, "Roots", $Failed];
  dimensions = Lookup[preparation, "Dimensions", $Failed];
  If[! ListQ[roots] || ! MatchQ[dimensions, {_Integer, _Integer}], Return[False]];
  payload = multiquadraticStripABIPayload[preparation["Record"], roots,
    preparation["Variables"], preparation["Regulator"], dimensions,
    preparation["GaugeDenominator"], preparation["GaugeSupport"],
    preparation["OneForms"], preparation["Normalizations"]];
  If[payload === $Failed, Return[False]];
  gradeCount = 2^Length[roots];
  gaugeUnknownCount = (Times @@ dimensions) gradeCount
    Length[preparation["GaugeSupport"]];
  residueUnknownCount = Length[preparation["OneForms"]] (Times @@ dimensions);
  TrueQ[
    payload === Lookup[preparation, "ABIPayload", Missing["Payload"]] &&
    Lookup[preparation, "ABIFingerprint", Missing["Fingerprint"]] ===
      multiquadraticStripFingerprint[payload] &&
    Lookup[preparation, "AlgebraABIFingerprint", Missing["Algebra"]] ===
      multiquadraticAlgebraABIFingerprint[] &&
    Lookup[preparation, "RootOrderingFingerprint", Missing["RootOrder"]] ===
      payload["RootOrderingFingerprint"] &&
    Lookup[preparation, "RootCount", Missing["RootCount"]] === Length[roots] &&
    Lookup[preparation, "GradeCount", Missing["GradeCount"]] === gradeCount &&
    Lookup[preparation, "GaugeUnknownCount", Missing["Gauge"]] ===
      gaugeUnknownCount &&
    Lookup[preparation, "ResidueUnknownCount", Missing["Residue"]] ===
      residueUnknownCount &&
    Lookup[preparation, "UnknownCount", Missing["Unknown"]] ===
      gaugeUnknownCount + residueUnknownCount &&
    Lookup[preparation, "EquationsPerPoint", Missing["Equations"]] ===
      gradeCount 2 (Times @@ dimensions)]
];

(* ------------------------------------------------------------------ *)
(* Exact channel compilation into a sparse x/y polynomial ABI           *)
(* ------------------------------------------------------------------ *)

(* Terms sharing an x/y monomial are grouped; the row keeps the exact
   coefficients of eps^0..eps^K, so one compilation serves every
   regulator value and every prime. *)
multiquadraticStripCompilePolynomial[polynomial_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {vars = Append[variables, epsilon], expanded, rules, groups, xExponents,
   yExponents, maximumEpsilonDegree, coefficientRows},
  expanded = Expand[polynomial];
  If[! PolynomialQ[expanded, vars], Return[$Failed]];
  rules = CoefficientRules[expanded, vars];
  If[rules === {}, Return[<|"Type" -> "MultiquadraticPolynomialExactV1",
    "XExponents" -> {}, "YExponents" -> {}, "EpsilonCoefficientRows" -> {}|>]];
  If[! AllTrue[Last /@ rules, IntegerQ[#1] || Head[#1] === Rational &],
    Return[$Failed]];
  maximumEpsilonDegree = Max[rules[[All, 1, 3]]];
  If[maximumEpsilonDegree > $multiquadraticStripMaximumEpsilonDegree,
    Return[$Failed]];
  groups = GatherBy[rules, First[#1][[1 ;; 2]] &];
  xExponents = groups[[All, 1, 1, 1]];
  yExponents = groups[[All, 1, 1, 2]];
  coefficientRows = Table[
    Module[{row = ConstantArray[0, Max[group[[All, 1, 3]]] + 1]},
      Do[row[[rule[[1, 3]] + 1]] += rule[[2]], {rule, group}]; row],
    {group, groups}];
  <|"Type" -> "MultiquadraticPolynomialExactV1",
    "XExponents" -> Developer`ToPackedArray[xExponents],
    "YExponents" -> Developer`ToPackedArray[yExponents],
    "EpsilonCoefficientRows" -> coefficientRows|>
];

multiquadraticStripCompileRational[expression_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[{rational, numerator, denominator},
  rational = Together[expression];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  numerator = multiquadraticStripCompilePolynomial[Numerator[rational],
    variables, epsilon];
  denominator = multiquadraticStripCompilePolynomial[Denominator[rational],
    variables, epsilon];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["EpsilonCoefficientRows"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalExactV1", "Numerator" -> numerator,
    "Denominator" -> denominator|>
];

multiquadraticStripDecomposeScalar[expression_, roots_List] := Module[
  {channels, reconstructed},
  channels = multiquadraticFieldDecompose[expression, roots];
  If[! ListQ[channels] || Length[channels] =!= 2^Length[roots] ||
      MemberQ[channels, $Failed], Return[$Failed]];
  reconstructed = multiquadraticFieldCompose[channels, roots];
  If[! TrueQ[Together[reconstructed - expression] === 0], Return[$Failed]];
  channels
];

multiquadraticStripCompileTensor[tensor_, scalarLevel_Integer, roots_List,
    variables_List, epsilon_Symbol] := Module[{channels, compiled},
  channels = Map[multiquadraticStripDecomposeScalar[#1, roots] &, tensor,
    {scalarLevel}];
  If[! FreeQ[channels, $Failed], Return[$Failed]];
  compiled = Map[multiquadraticStripCompileRational[#1, variables, epsilon] &,
    channels, {scalarLevel + 1}];
  If[! FreeQ[compiled, $Failed], $Failed,
    <|"Channels" -> channels, "Compiled" -> compiled|>]
];

multiquadraticStripFormShape[expression_] := Which[
  AssociationQ[expression] && MemberQ[{"MultiquadraticRationalExactV1",
      "MultiquadraticRationalPrimeV1", "MultiquadraticRationalImageV1"},
    Lookup[expression, "Type", None]], "MultiquadraticRationalLeaf",
  AssociationQ[expression], Map[multiquadraticStripFormShape, expression],
  ListQ[expression], multiquadraticStripFormShape /@ expression,
  True, "Scalar"
];

multiquadraticStripSemanticPayload[assembly_Association] := KeyTake[assembly, {
  "ABIFingerprint", "AlgebraABIFingerprint", "RootOrderingFingerprint",
  "RootCount", "GradeCount", "Dimensions", "GaugeSupport",
  "GaugeUnknownCount", "ResidueUnknownCount", "UnknownCount",
  "EquationsPerPoint", "ColumnOrder", "RowOrder",
  "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
  "CompiledFormsShapeFingerprint", "SourceSHA256"}];

multiquadraticStripCompile[preparation_Association] := Module[
  {variables, epsilon, record, strip, e, c, bbar, roots, rules, dimensions,
   eData, cData, bData, oneData, rootSquares, rootSquareData, rootLogData,
   denominatorData, denominatorLogData, exactForms, compiledForms,
   canonicalExact, result, payload},
  If[! multiquadraticStripPreparationValidQ[preparation],
    Return[multiquadraticStripFailure["InvalidPreparationABI"]]];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  record = preparation["Record"];
  roots = preparation["Roots"];
  strip = record["Strip"];
  dimensions = preparation["Dimensions"];
  {e, c, bbar} = strip;
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  eData = multiquadraticStripCompileTensor[e, 3, roots, variables, epsilon];
  cData = multiquadraticStripCompileTensor[c, 3, roots, variables, epsilon];
  bData = multiquadraticStripCompileTensor[bbar, 3, roots, variables, epsilon];
  oneData = multiquadraticStripCompileTensor[preparation["OneForms"], 2, roots,
    variables, epsilon];
  If[MemberQ[{eData, cData, bData, oneData}, $Failed],
    Return[multiquadraticStripFailure["ExactChannelDecompositionFailed"]]];
  rootSquares = Lookup[roots, "RootSquare", {}];
  rootSquareData = multiquadraticStripCompileTensor[rootSquares, 1, {},
    variables, epsilon];
  rootLogData = multiquadraticStripCompileTensor[
    Table[D[rootSquares[[a]], variables[[mu]]]/rootSquares[[a]],
      {a, Length[rootSquares]}, {mu, 2}], 2, {}, variables, epsilon];
  denominatorData = multiquadraticStripCompileTensor[
    {preparation["GaugeDenominator"]}, 1, {}, variables, epsilon];
  denominatorLogData = multiquadraticStripCompileTensor[
    {D[preparation["GaugeDenominator"], variables[[1]]]/
       preparation["GaugeDenominator"],
     D[preparation["GaugeDenominator"], variables[[2]]]/
       preparation["GaugeDenominator"]}, 1, {}, variables, epsilon];
  If[MemberQ[{rootSquareData, rootLogData, denominatorData, denominatorLogData},
      $Failed],
    Return[multiquadraticStripFailure["RationalAssemblyFormCompilationFailed"]]];
  exactForms = <|"E" -> eData["Channels"], "C" -> cData["Channels"],
    "BBar" -> bData["Channels"], "OneForms" -> oneData["Channels"],
    "RootSquares" -> (First /@ rootSquareData["Channels"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Channels"], {2}],
    "GaugeDenominator" -> First[First[denominatorData["Channels"]]],
    "GaugeLogDerivatives" -> First /@ denominatorLogData["Channels"]|>;
  compiledForms = <|"E" -> eData["Compiled"], "C" -> cData["Compiled"],
    "BBar" -> bData["Compiled"], "OneForms" -> oneData["Compiled"],
    "RootSquares" -> (First /@ rootSquareData["Compiled"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Compiled"], {2}],
    "GaugeDenominator" -> First[First[denominatorData["Compiled"]]],
    "GaugeLogDerivatives" -> First /@ denominatorLogData["Compiled"]|>;
  If[! FreeQ[compiledForms, $Failed],
    Return[multiquadraticStripFailure["CompiledAssemblyFormsInvalid"]]];
  (* the exact forms carry the chart symbols: canonicalize before
     hashing so the cache key is not the reader's context (pool defect
     3 -- ExactChannelFormsFingerprint changed with the inspecting
     context in the Codex original) *)
  canonicalExact = exactForms /. rules;
  If[! multiquadraticStripContextFreeQ[canonicalExact],
    Return[multiquadraticStripFailure["ContextSensitiveChannelForms"]]];
  result = <|
    "Status" -> "CompiledMultiquadraticStripV1",
    "SourceFile" -> $multiquadraticStripSourceFile,
    "SourceSHA256" -> $multiquadraticStripSourceSHA256,
    "Preparation" -> preparation,
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "AlgebraABIFingerprint" -> preparation["AlgebraABIFingerprint"],
    "RootOrderingFingerprint" -> preparation["RootOrderingFingerprint"],
    "Record" -> record, "Roots" -> roots,
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "GaugeSupport" -> preparation["GaugeSupport"],
    "OneForms" -> preparation["OneForms"],
    "GaugeDenominator" -> preparation["GaugeDenominator"],
    "Normalizations" -> preparation["Normalizations"],
    "GaugeUnknownCount" -> preparation["GaugeUnknownCount"],
    "ResidueUnknownCount" -> preparation["ResidueUnknownCount"],
    "UnknownCount" -> preparation["UnknownCount"],
    "EquationsPerPoint" -> preparation["EquationsPerPoint"],
    "ColumnOrder" -> preparation["ColumnOrder"],
    "RowOrder" -> preparation["RowOrder"],
    "ExactChannelForms" -> exactForms,
    "CompiledForms" -> compiledForms,
    "ExactChannelFormsFingerprint" -> multiquadraticStripFingerprint[canonicalExact],
    "CompiledFormsFingerprint" -> multiquadraticStripFingerprint[compiledForms],
    "CompiledFormsShapeFingerprint" -> multiquadraticStripFingerprint[
      multiquadraticStripFormShape[compiledForms]]|>;
  payload = multiquadraticStripSemanticPayload[result];
  Append[result, "AssemblyFingerprint" -> multiquadraticStripFingerprint[payload]]
];
multiquadraticStripCompile[___] :=
  multiquadraticStripFailure["InvalidCompileArguments"];

multiquadraticStripCompiledValidQ[assembly_Association] := Module[
  {dimensions, rootCount, gradeCount, support, expectedGauge, expectedResidue,
   requiredKeys, rules, canonicalExact},
  If[Lookup[assembly, "Status", None] =!= "CompiledMultiquadraticStripV1",
    Return[False]];
  requiredKeys = {"SourceFile", "SourceSHA256", "ABIFingerprint",
    "AlgebraABIFingerprint", "RootOrderingFingerprint", "Record", "Roots",
    "RootCount", "GradeCount", "Variables", "Regulator", "Dimensions",
    "GaugeSupport", "OneForms", "GaugeDenominator", "Normalizations",
    "GaugeUnknownCount", "ResidueUnknownCount", "UnknownCount",
    "EquationsPerPoint", "ColumnOrder", "RowOrder", "ExactChannelForms",
    "CompiledForms", "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
    "CompiledFormsShapeFingerprint", "AssemblyFingerprint"};
  If[! AllTrue[requiredKeys, KeyExistsQ[assembly, #1] &], Return[False]];
  dimensions = assembly["Dimensions"];
  rootCount = assembly["RootCount"];
  gradeCount = assembly["GradeCount"];
  support = assembly["GaugeSupport"];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || ! IntegerQ[rootCount] ||
      ! (0 <= rootCount <= $multiquadraticStripMaximumRootCount) ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! ListQ[support] || support === {}, Return[False]];
  expectedGauge = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[assembly["OneForms"]] Times @@ dimensions;
  rules = multiquadraticStripCanonicalRules[assembly["Variables"],
    assembly["Regulator"]];
  canonicalExact = assembly["ExactChannelForms"] /. rules;
  TrueQ[
    assembly["SourceSHA256"] === $multiquadraticStripSourceSHA256 &&
    assembly["AlgebraABIFingerprint"] === multiquadraticAlgebraABIFingerprint[] &&
    assembly["GaugeUnknownCount"] === expectedGauge &&
    assembly["ResidueUnknownCount"] === expectedResidue &&
    assembly["UnknownCount"] === expectedGauge + expectedResidue &&
    assembly["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    assembly["ColumnOrder"] === multiquadraticStripColumnOrder[dimensions,
      gradeCount, support, Length[assembly["OneForms"]]] &&
    assembly["RowOrder"] === multiquadraticStripRowOrder[dimensions, gradeCount] &&
    assembly["ExactChannelFormsFingerprint"] ===
      multiquadraticStripFingerprint[canonicalExact] &&
    assembly["CompiledFormsFingerprint"] ===
      multiquadraticStripFingerprint[assembly["CompiledForms"]] &&
    assembly["CompiledFormsShapeFingerprint"] === multiquadraticStripFingerprint[
      multiquadraticStripFormShape[assembly["CompiledForms"]]] &&
    assembly["AssemblyFingerprint"] === multiquadraticStripFingerprint[
      multiquadraticStripSemanticPayload[assembly]]]
];

(* ------------------------------------------------------------------ *)
(* Prime forms and regulator collapse                                   *)
(* ------------------------------------------------------------------ *)

multiquadraticStripMapRationals[expression_, sourceType_String, function_] := Which[
  AssociationQ[expression] && Lookup[expression, "Type", None] === sourceType,
    function[expression],
  AssociationQ[expression],
    Map[multiquadraticStripMapRationals[#1, sourceType, function] &, expression],
  ListQ[expression],
    multiquadraticStripMapRationals[#1, sourceType, function] & /@ expression,
  True, expression
];

multiquadraticStripReducePolynomial[polynomial_Association, prime_Integer] := Module[
  {rows},
  rows = Map[multiquadraticStripModRational[#1, prime] &,
    polynomial["EpsilonCoefficientRows"], {2}];
  If[! FreeQ[rows, $Failed], Return[$Failed]];
  <|"Type" -> "MultiquadraticPolynomialPrimeV1",
    "XExponents" -> polynomial["XExponents"],
    "YExponents" -> polynomial["YExponents"],
    "EpsilonCoefficientRows" -> Developer`ToPackedArray[rows], "Prime" -> prime|>
];

multiquadraticStripReduceRational[rational_Association, prime_Integer] := Module[
  {numerator, denominator},
  numerator = multiquadraticStripReducePolynomial[rational["Numerator"], prime];
  denominator = multiquadraticStripReducePolynomial[rational["Denominator"], prime];
  If[numerator === $Failed || denominator === $Failed, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalPrimeV1", "Numerator" -> numerator,
    "Denominator" -> denominator, "Prime" -> prime|>
];

SetAttributes[multiquadraticStripCacheInsert, HoldFirst];
multiquadraticStripCacheInsert[cacheSymbol_Symbol, key_, value_,
    maximum_Integer] := (
  If[! AssociationQ[cacheSymbol], cacheSymbol = <||>];
  If[Length[cacheSymbol] >= maximum,
    KeyDropFrom[cacheSymbol, First[Keys[cacheSymbol]]]];
  AssociateTo[cacheSymbol, key -> value];
  value);

multiquadraticStripPrimeForms[assembly_Association, prime_Integer] := Module[
  {key, forms},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidPrimeFormsInput"]]];
  key = {assembly["AssemblyFingerprint"], prime};
  If[KeyExistsQ[$multiquadraticStripPrimeCache, key],
    Return[$multiquadraticStripPrimeCache[key]]];
  forms = multiquadraticStripMapRationals[assembly["CompiledForms"],
    "MultiquadraticRationalExactV1",
    multiquadraticStripReduceRational[#1, prime] &];
  If[! FreeQ[forms, $Failed],
    Return[multiquadraticStripFailure["PrimeReductionFailed",
      <|"Prime" -> prime|>]]];
  multiquadraticStripCacheInsert[$multiquadraticStripPrimeCache, key, <|
    "Status" -> "MultiquadraticStripPrimeFormsV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "Prime" -> prime, "Forms" -> forms|>, 8]
];

multiquadraticStripCollapsePolynomial[polynomial_Association, epsilonMod_Integer,
    prime_Integer] := Module[{coefficients, keep},
  If[polynomial["EpsilonCoefficientRows"] === {},
    Return[<|"Type" -> "MultiquadraticPolynomialImageV1", "XExponents" -> {},
      "YExponents" -> {}, "Coefficients" -> {}, "Prime" -> prime|>]];
  coefficients = Fold[Mod[#1 epsilonMod + #2, prime] &, 0, Reverse[#1]] & /@
    polynomial["EpsilonCoefficientRows"];
  keep = Flatten[Position[coefficients, Except[0], {1}, Heads -> False]];
  <|"Type" -> "MultiquadraticPolynomialImageV1",
    "XExponents" -> Developer`ToPackedArray[polynomial["XExponents"][[keep]]],
    "YExponents" -> Developer`ToPackedArray[polynomial["YExponents"][[keep]]],
    "Coefficients" -> Developer`ToPackedArray[coefficients[[keep]]],
    "Prime" -> prime|>
];

multiquadraticStripCollapseRational[rational_Association, epsilonMod_Integer,
    prime_Integer] := Module[{numerator, denominator},
  numerator = multiquadraticStripCollapsePolynomial[rational["Numerator"],
    epsilonMod, prime];
  denominator = multiquadraticStripCollapsePolynomial[rational["Denominator"],
    epsilonMod, prime];
  If[denominator["Coefficients"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalImageV1", "Numerator" -> numerator,
    "Denominator" -> denominator, "Prime" -> prime|>
];

multiquadraticStripMaximumExponents[forms_] := Module[{polynomials, nonzero},
  polynomials = Cases[forms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticPolynomialImageV1" :>
      association, {0, Infinity}];
  nonzero = Select[polynomials, Lookup[#1, "Coefficients", {}] =!= {} &];
  If[nonzero === {}, {0, 0},
    {Max[Max /@ Lookup[nonzero, "XExponents"]],
     Max[Max /@ Lookup[nonzero, "YExponents"]]}]
];

multiquadraticStripCollapseEpsilon[assembly_Association, prime_Integer,
    epsilonValue_] := Module[{key, primeForms, epsilonMod, forms, maximum},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidCollapseInput"]]];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[multiquadraticStripFailure["InvalidRegulatorImage",
      <|"Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  key = {assembly["AssemblyFingerprint"], prime, epsilonMod};
  If[KeyExistsQ[$multiquadraticStripEpsilonCache, key],
    Return[$multiquadraticStripEpsilonCache[key]]];
  primeForms = multiquadraticStripPrimeForms[assembly, prime];
  If[Lookup[primeForms, "Status", None] =!= "MultiquadraticStripPrimeFormsV1",
    Return[primeForms]];
  forms = multiquadraticStripMapRationals[primeForms["Forms"],
    "MultiquadraticRationalPrimeV1",
    multiquadraticStripCollapseRational[#1, epsilonMod, prime] &];
  If[! FreeQ[forms, $Failed],
    Return[multiquadraticStripFailure["RegulatorCollapseFailed",
      <|"Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  maximum = multiquadraticStripMaximumExponents[forms];
  multiquadraticStripCacheInsert[$multiquadraticStripEpsilonCache, key, <|
    "Status" -> "MultiquadraticStripEpsilonFormsV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"], "Prime" -> prime,
    "EpsilonValue" -> epsilonValue, "EpsilonMod" -> epsilonMod,
    "MaximumExponents" -> maximum, "Forms" -> forms,
    "FormsShapeFingerprint" -> multiquadraticStripFingerprint[
      multiquadraticStripFormShape[forms]],
    "FormsFingerprint" -> multiquadraticStripFingerprint[forms]|>, 32]
];

multiquadraticStripPolynomialImageValidQ[polynomial_Association, prime_Integer,
    allowZero_: True] := Module[{xExponents, yExponents, coefficients},
  If[Sort[Keys[polynomial]] =!= Sort[{"Type", "XExponents", "YExponents",
      "Coefficients", "Prime"}] ||
      polynomial["Type"] =!= "MultiquadraticPolynomialImageV1" ||
      polynomial["Prime"] =!= prime, Return[False]];
  xExponents = polynomial["XExponents"];
  yExponents = polynomial["YExponents"];
  coefficients = polynomial["Coefficients"];
  TrueQ[VectorQ[xExponents, IntegerQ[#1] && #1 >= 0 &] &&
    VectorQ[yExponents, IntegerQ[#1] && #1 >= 0 &] &&
    VectorQ[coefficients, IntegerQ[#1] && 0 <= #1 < prime &] &&
    Length[xExponents] === Length[yExponents] === Length[coefficients] &&
    (TrueQ[allowZero] || coefficients =!= {})]
];

multiquadraticStripRationalImageValidQ[rational_Association, prime_Integer] :=
  TrueQ[
    Sort[Keys[rational]] === Sort[{"Type", "Numerator", "Denominator", "Prime"}] &&
    rational["Type"] === "MultiquadraticRationalImageV1" &&
    rational["Prime"] === prime && AssociationQ[rational["Numerator"]] &&
    AssociationQ[rational["Denominator"]] &&
    multiquadraticStripPolynomialImageValidQ[rational["Numerator"], prime, True] &&
    multiquadraticStripPolynomialImageValidQ[rational["Denominator"], prime, False]];

multiquadraticStripEpsilonFormsValidQ[assembly_Association, forms_Association,
    prime_Integer] := Module[
  {imageForms, rationalLeaves, epsilonMod, maximumExponents, expectedKeys},
  expectedKeys = {"Status", "AssemblyFingerprint", "Prime", "EpsilonValue",
    "EpsilonMod", "MaximumExponents", "Forms", "FormsShapeFingerprint",
    "FormsFingerprint"};
  If[Sort[Keys[forms]] =!= Sort[expectedKeys] ||
      Lookup[forms, "Status", None] =!= "MultiquadraticStripEpsilonFormsV1" ||
      Lookup[forms, "AssemblyFingerprint", None] =!=
        assembly["AssemblyFingerprint"] ||
      Lookup[forms, "Prime", None] =!= prime, Return[False]];
  epsilonMod = Lookup[forms, "EpsilonMod", $Failed];
  maximumExponents = Lookup[forms, "MaximumExponents", $Failed];
  imageForms = Lookup[forms, "Forms", $Failed];
  If[! IntegerQ[epsilonMod] || ! (0 <= epsilonMod < prime) ||
      multiquadraticStripModRational[forms["EpsilonValue"], prime] =!= epsilonMod ||
      ! MatchQ[maximumExponents, {a_Integer, b_Integer} /; a >= 0 && b >= 0] ||
      ! AssociationQ[imageForms], Return[False]];
  rationalLeaves = Cases[imageForms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticRationalImageV1" :>
      association, {0, Infinity}];
  TrueQ[rationalLeaves =!= {} &&
    AllTrue[rationalLeaves, multiquadraticStripRationalImageValidQ[#1, prime] &] &&
    multiquadraticStripMaximumExponents[imageForms] === maximumExponents &&
    multiquadraticStripFingerprint[multiquadraticStripFormShape[imageForms]] ===
      assembly["CompiledFormsShapeFingerprint"] === forms["FormsShapeFingerprint"] &&
    multiquadraticStripFingerprint[imageForms] === forms["FormsFingerprint"]]
];

multiquadraticStripEvaluatePolynomial[polynomial_Association,
    xPowers_Association, yPowers_Association, prime_Integer] := Module[
  {monomials, terms},
  If[polynomial["Coefficients"] === {}, Return[0]];
  monomials = Mod[Lookup[xPowers, polynomial["XExponents"]]
    Lookup[yPowers, polynomial["YExponents"]], prime];
  terms = Mod[polynomial["Coefficients"] monomials, prime];
  Mod[Total[terms], prime]
];

multiquadraticStripEvaluateRational[rational_Association, xPowers_Association,
    yPowers_Association, prime_Integer] := Module[{numerator, denominator},
  numerator = multiquadraticStripEvaluatePolynomial[rational["Numerator"],
    xPowers, yPowers, prime];
  denominator = multiquadraticStripEvaluatePolynomial[rational["Denominator"],
    xPowers, yPowers, prime];
  If[denominator === 0, Throw[$Failed, "MultiquadraticStripBadPoint"]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

multiquadraticStripEvaluateForms[forms_, xPowers_Association,
    yPowers_Association, prime_Integer] :=
  multiquadraticStripMapRationals[forms, "MultiquadraticRationalImageV1",
    multiquadraticStripEvaluateRational[#1, xPowers, yPowers, prime] &];

multiquadraticStripMaskFactorMod[mask_Integer, deltaValues_List, prime_Integer] :=
  Fold[Mod[#1 #2, prime] &, 1,
    Pick[deltaValues, BitGet[mask,
      If[deltaValues === {}, {}, Range[0, Length[deltaValues] - 1]]], 1]];

multiquadraticStripCharacter[signMask_Integer, grade_Integer, rank_Integer] :=
  If[Mod[Total[BitGet[BitAnd[signMask, grade],
      If[rank === 0, {}, Range[0, rank - 1]]]], 2] === 0, 1, -1];

(* ------------------------------------------------------------------ *)
(* Point and sample assembly (production: no branch flip)               *)
(* ------------------------------------------------------------------ *)

multiquadraticStripAssemblePointInternal[assembly_Association,
    epsilonForms_Association, prime_Integer, point : {_Integer, _Integer},
    validatedFingerprint_: Automatic] := Catch[Module[
  {startTime = AbsoluteTime[], dimensions = assembly["Dimensions"],
   upperDimension, lowerDimension, gradeCount = assembly["GradeCount"],
   support = assembly["GaugeSupport"], supportCount, unknownCount,
   gaugeUnknownCount, oneFormCount, epsilonMod, forms, imagePolynomials,
   requiredXExponents, requiredYExponents, x, y, xPowers, yPowers, evaluated,
   primitiveEvaluated, primitiveDeltaValues, primitiveDenominatorValue,
   deltaValues, deltaMaskFactors, denominatorValue, denominatorInverse,
   gaugeLogDerivatives, rootLogDerivatives, eValues, cValues, bbarValues,
   oneFormValues, monomialValues, basisValues, basisDerivatives, xInverse,
   yInverse, half, logarithmicDerivative, targetGrade, sourceGrade,
   productGrade, productFactor, mu, i, j, a, b, letter, monomial,
   productWeight, productGrades, productWeights, rowIndex, rowCount, rows,
   right, row, gaugeRow, residueRow, residueRowExpectedWidth, assemblySeconds},
  If[validatedFingerprint =!= assembly["AssemblyFingerprint"] &&
      ! multiquadraticStripEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Throw[multiquadraticStripFailure["InvalidRegulatorForms"],
      "MultiquadraticStripAssemblyFailure"]];
  {upperDimension, lowerDimension} = dimensions;
  supportCount = Length[support];
  unknownCount = assembly["UnknownCount"];
  gaugeUnknownCount = assembly["GaugeUnknownCount"];
  oneFormCount = Length[assembly["OneForms"]];
  residueRowExpectedWidth = assembly["ResidueUnknownCount"];
  epsilonMod = epsilonForms["EpsilonMod"];
  If[epsilonMod === 0,
    Throw[multiquadraticStripFailure["ZeroRegulatorImage"],
      "MultiquadraticStripAssemblyFailure"]];
  {x, y} = Mod[point, prime];
  If[x === 0 || y === 0,
    Throw[multiquadraticStripFailure["ZeroPointCoordinate", <|"Point" -> point|>],
      "MultiquadraticStripAssemblyFailure"]];
  forms = epsilonForms["Forms"];
  imagePolynomials = Cases[forms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticPolynomialImageV1" :>
      association, {0, Infinity}];
  requiredXExponents = Union[support[[All, 1]],
    Flatten[Lookup[imagePolynomials, "XExponents", {}]]];
  requiredYExponents = Union[support[[All, 2]],
    Flatten[Lookup[imagePolynomials, "YExponents", {}]]];
  xPowers = AssociationThread[requiredXExponents,
    PowerMod[x, #1, prime] & /@ requiredXExponents];
  yPowers = AssociationThread[requiredYExponents,
    PowerMod[y, #1, prime] & /@ requiredYExponents];
  evaluated = Catch[multiquadraticStripEvaluateForms[forms, xPowers, yPowers,
    prime], "MultiquadraticStripBadPoint"];
  If[evaluated === $Failed,
    (* separate the two admissible reasons for a bad point: a ramified
       or non-split root image, and a zero of the gauge denominator *)
    primitiveEvaluated = Catch[multiquadraticStripEvaluateForms[
      KeyTake[forms, {"RootSquares", "GaugeDenominator"}], xPowers, yPowers,
      prime], "MultiquadraticStripBadPoint"];
    If[AssociationQ[primitiveEvaluated],
      primitiveDeltaValues = primitiveEvaluated["RootSquares"];
      If[VectorQ[primitiveDeltaValues, IntegerQ] &&
          Length[primitiveDeltaValues] === assembly["RootCount"] &&
          MemberQ[primitiveDeltaValues, 0],
        Throw[multiquadraticStripFailure["DegenerateRootImage",
          <|"Point" -> point, "DeltaValues" -> primitiveDeltaValues|>],
          "MultiquadraticStripAssemblyFailure"]];
      primitiveDenominatorValue = primitiveEvaluated["GaugeDenominator"];
      If[IntegerQ[primitiveDenominatorValue] && primitiveDenominatorValue === 0,
        Throw[multiquadraticStripFailure["ZeroGaugeDenominator",
          <|"Point" -> point|>], "MultiquadraticStripAssemblyFailure"]]];
    Throw[multiquadraticStripFailure["RationalChannelPole", <|"Point" -> point|>],
      "MultiquadraticStripAssemblyFailure"]];
  deltaValues = evaluated["RootSquares"];
  If[! VectorQ[deltaValues, IntegerQ] ||
      Length[deltaValues] =!= assembly["RootCount"] || MemberQ[deltaValues, 0],
    Throw[multiquadraticStripFailure["DegenerateRootImage",
      <|"Point" -> point, "DeltaValues" -> deltaValues|>],
      "MultiquadraticStripAssemblyFailure"]];
  denominatorValue = evaluated["GaugeDenominator"];
  If[! IntegerQ[denominatorValue] || denominatorValue === 0,
    Throw[multiquadraticStripFailure["ZeroGaugeDenominator", <|"Point" -> point|>],
      "MultiquadraticStripAssemblyFailure"]];
  denominatorInverse = PowerMod[denominatorValue, -1, prime];
  deltaMaskFactors = Developer`ToPackedArray[
    multiquadraticStripMaskFactorMod[#1, deltaValues, prime] & /@
      Range[0, gradeCount - 1]];
  gaugeLogDerivatives = evaluated["GaugeLogDerivatives"];
  rootLogDerivatives = evaluated["RootLogDerivatives"];
  eValues = evaluated["E"];
  cValues = evaluated["C"];
  bbarValues = evaluated["BBar"];
  oneFormValues = evaluated["OneForms"];
  xInverse = PowerMod[x, -1, prime];
  yInverse = PowerMod[y, -1, prime];
  half = PowerMod[2, -1, prime];
  monomialValues = Developer`ToPackedArray[Table[
    Mod[xPowers[support[[monomial, 1]]] yPowers[support[[monomial, 2]]], prime],
    {monomial, supportCount}]];
  basisValues = Developer`ToPackedArray[Table[
    Mod[monomialValues[[monomial]] denominatorInverse, prime],
    {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
  (* d_mu (x^p y^q / Q r_grade) / r_grade *)
  basisDerivatives = Developer`ToPackedArray[Table[
    logarithmicDerivative = Mod[
      If[mu === 1, support[[monomial, 1]] xInverse,
        support[[monomial, 2]] yInverse] - gaugeLogDerivatives[[mu]] +
      half Sum[If[BitGet[sourceGrade, a - 1] === 1,
        rootLogDerivatives[[a, mu]], 0], {a, assembly["RootCount"]}], prime];
    Mod[basisValues[[sourceGrade + 1, monomial]] logarithmicDerivative, prime],
    {mu, 2}, {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
  productGrades = Developer`ToPackedArray[Table[BitXor[targetGrade, sourceGrade],
    {targetGrade, 0, gradeCount - 1}, {sourceGrade, 0, gradeCount - 1}]];
  productWeights = Developer`ToPackedArray[Table[
    productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
    productFactor = deltaMaskFactors[[BitAnd[productGrade, sourceGrade] + 1]];
    Mod[Mod[epsilonMod basisValues[[sourceGrade + 1, monomial]], prime]
      productFactor, prime],
    {targetGrade, 0, gradeCount - 1}, {sourceGrade, 0, gradeCount - 1},
    {monomial, supportCount}]];
  rowCount = assembly["EquationsPerPoint"];
  rows = Table[ConstantArray[0, unknownCount], rowCount];
  right = ConstantArray[0, rowCount];
  Do[
    rowIndex = multiquadraticStripPointRowIndex[targetGrade, mu, i, j,
      upperDimension, lowerDimension];
    gaugeRow = Flatten[Table[
      productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
      productWeight = productWeights[[targetGrade + 1, sourceGrade + 1, monomial]];
      Mod[Mod[
          If[targetGrade === sourceGrade && a === i && b === j,
            basisDerivatives[[mu, sourceGrade + 1, monomial]], 0] +
          If[b === j, -productWeight eValues[[mu, i, a, productGrade + 1]], 0],
          prime] +
        If[a === i, productWeight cValues[[mu, b, j, productGrade + 1]], 0],
        prime],
      {a, upperDimension}, {b, lowerDimension},
      {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
    residueRow = Flatten[Table[
      If[a === i && b === j,
        Mod[epsilonMod oneFormValues[[letter, mu, targetGrade + 1]], prime], 0],
      {letter, oneFormCount}, {a, upperDimension}, {b, lowerDimension}]];
    If[Length[residueRow] =!= residueRowExpectedWidth,
      Throw[multiquadraticStripFailure["ResidueRowWidthMismatch",
        <|"Expected" -> residueRowExpectedWidth,
          "Observed" -> Length[residueRow]|>],
        "MultiquadraticStripAssemblyFailure"]];
    row = Join[gaugeRow, residueRow];
    If[Length[row] =!= unknownCount,
      Throw[multiquadraticStripFailure["RowWidthMismatch",
        <|"Expected" -> unknownCount, "Observed" -> Length[row]|>],
        "MultiquadraticStripAssemblyFailure"]];
    rows[[rowIndex]] = Developer`ToPackedArray[row];
    right[[rowIndex]] = Mod[bbarValues[[mu, i, j, targetGrade + 1]], prime],
    {targetGrade, 0, gradeCount - 1}, {mu, 2}, {i, upperDimension},
    {j, lowerDimension}];
  rows = Developer`ToPackedArray[rows];
  right = Developer`ToPackedArray[right];
  assemblySeconds = N[AbsoluteTime[] - startTime];
  <|"Status" -> "AssembledMultiquadraticPointV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"], "Prime" -> prime,
    "EpsilonValue" -> epsilonForms["EpsilonValue"], "EpsilonMod" -> epsilonMod,
    "Point" -> {x, y}, "DeltaValues" -> deltaValues, "Rows" -> rows,
    "RightHandSide" -> right, "MatrixDimensions" -> Dimensions[rows],
    "Dimensions" -> dimensions, "RootCount" -> assembly["RootCount"],
    "GradeCount" -> gradeCount, "EquationsPerGrade" -> 2 Times @@ dimensions,
    "UnknownCount" -> unknownCount, "RowBasis" -> "MultiquadraticGradeBasis",
    "AssemblySeconds" -> assemblySeconds|>
], "MultiquadraticStripAssemblyFailure"];

multiquadraticStripAssemblePoint[assembly_Association,
    epsilonForms_Association, prime_Integer,
    point : {_Integer, _Integer}] := Module[{result},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidPointAssemblyInput"]]];
  result = multiquadraticStripAssemblePointInternal[assembly, epsilonForms,
    prime, point];
  If[AssociationQ[result], result,
    multiquadraticStripFailure["PointAssemblyDidNotReturnAssociation"]]
];
multiquadraticStripAssemblePoint[___] :=
  multiquadraticStripFailure["InvalidPointAssemblyArguments"];

multiquadraticStripNormalizationRows[assembly_Association, epsilonValue_,
    prime_Integer] := Module[
  {unknownCount = assembly["UnknownCount"], epsilon = assembly["Regulator"],
   rows, right},
  rows = Table[Developer`ToPackedArray[ReplacePart[
      ConstantArray[0, unknownCount], normalization["Column"] -> 1]],
    {normalization, assembly["Normalizations"]}];
  right = multiquadraticStripModRational[
      #1["Value"] /. epsilon -> epsilonValue, prime] & /@
    assembly["Normalizations"];
  If[MemberQ[right, $Failed], $Failed,
    {Developer`ToPackedArray[rows], Developer`ToPackedArray[right]}]
];

(* The production sampler.  It has NO branch-flip option: a direct
   grade row is branch invariant, so a flip mask changes no equation
   and recording one would suggest the sample depended on it (package
   bug handoff 2026-08-23, External gap 1).  Passing the option is a
   typed error.
   The grade rows need no split point at all -- that is the point of
   the direct channel basis -- so "SplitPointsOnly" defaults to False.
   A caller that will transform the sample into sign branches (the
   certificate path) asks for split points explicitly. *)
Options[multiquadraticStripAssembleSample] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082307,
  "CandidatePoints" -> Automatic,
  "SplitPointsOnly" -> False
};

multiquadraticStripAssembleSample[assembly_Association, epsilonValue_,
    prime_Integer, opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, epsilonForms, pointCount, maximumAttempts,
   randomSeed, candidatePoints, accepted = {}, rejected = {},
   acceptedPointKeys = <||>, pointKey, attempts = 0, candidateIndex = 0, point,
   pointResult, pointRows, pointRight, normalization, matrix, right,
   pointRanges, equationCount, splitOnly},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripAssembleSample]]]];
  If[AssociationQ[gate], Return[gate]];
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidSampleAssemblyInput"]]];
  epsilonForms = multiquadraticStripCollapseEpsilon[assembly, prime, epsilonValue];
  If[Lookup[epsilonForms, "Status", None] =!=
        "MultiquadraticStripEpsilonFormsV1" ||
      ! multiquadraticStripEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Return[If[AssociationQ[epsilonForms] &&
        Lookup[epsilonForms, "Status", None] =!=
          "MultiquadraticStripEpsilonFormsV1", epsilonForms,
      multiquadraticStripFailure["RegulatorFormsInvalid"]]]];
  pointCount = Replace[OptionValue["PointCount"], Automatic :>
    Max[4, Ceiling[(assembly["UnknownCount"] + assembly["EquationsPerPoint"])/
      assembly["EquationsPerPoint"]]]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount];
  randomSeed = OptionValue["RandomSeed"];
  candidatePoints = OptionValue["CandidatePoints"];
  splitOnly = TrueQ[OptionValue["SplitPointsOnly"]];
  If[! IntegerQ[pointCount] || pointCount < 1 || ! IntegerQ[maximumAttempts] ||
      maximumAttempts < pointCount || ! IntegerQ[randomSeed] ||
      ! (candidatePoints === Automatic ||
        MatchQ[candidatePoints, {{_Integer, _Integer} ..}]),
    Return[multiquadraticStripFailure["InvalidSampleAssemblyOptions"]]];
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    While[Length[accepted] < pointCount && attempts < maximumAttempts,
      attempts++;
      point = If[candidatePoints === Automatic,
        RandomInteger[{2, prime - 2}, 2],
        candidateIndex++;
        If[candidateIndex > Length[candidatePoints], Break[]];
        candidatePoints[[candidateIndex]]];
      pointResult = multiquadraticStripAssemblePointInternal[assembly,
        epsilonForms, prime, point, assembly["AssemblyFingerprint"]];
      If[Lookup[pointResult, "Status", None] === "AssembledMultiquadraticPointV1" &&
          splitOnly && ! AllTrue[pointResult["DeltaValues"],
            JacobiSymbol[#1, prime] === 1 &],
        pointResult = multiquadraticStripFailure["PointNotSplitOverPrime",
          <|"Point" -> point|>]];
      If[Lookup[pointResult, "Status", None] === "AssembledMultiquadraticPointV1",
        pointKey = ToString[InputForm[Mod[point, prime]]];
        If[KeyExistsQ[acceptedPointKeys, pointKey],
          AppendTo[rejected, <|"Point" -> point,
            "FailureReason" -> "DuplicatePointModuloPrime"|>],
          AssociateTo[acceptedPointKeys, pointKey -> True];
          AppendTo[accepted, pointResult]],
        AppendTo[rejected, <|"Point" -> point,
          "FailureReason" -> Lookup[pointResult, "Status", None]|>]]]
  ];
  If[Length[accepted] < pointCount,
    Return[multiquadraticStripFailure["InsufficientDirectChannelPoints",
      <|"AcceptedPointCount" -> Length[accepted], "AttemptCount" -> attempts,
        "RejectedPoints" -> rejected|>]]];
  normalization = multiquadraticStripNormalizationRows[assembly, epsilonValue,
    prime];
  If[normalization === $Failed,
    Return[multiquadraticStripFailure["NormalizationValueSingular"]]];
  pointRows = Join @@ Lookup[accepted, "Rows"];
  pointRight = Join @@ Lookup[accepted, "RightHandSide"];
  matrix = Developer`ToPackedArray[Join[pointRows, normalization[[1]]]];
  right = Developer`ToPackedArray[Mod[Join[pointRight, normalization[[2]]], prime]];
  equationCount = assembly["EquationsPerPoint"];
  pointRanges = Table[{1 + (index - 1) equationCount, index equationCount},
    {index, Length[accepted]}];
  <|"Status" -> "AssembledMultiquadraticSampleV1",
    "ABIFingerprint" -> assembly["ABIFingerprint"],
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "SourceSHA256" -> assembly["SourceSHA256"], "Prime" -> prime,
    "EpsilonValue" -> epsilonValue, "EpsilonMod" -> epsilonForms["EpsilonMod"],
    "Matrix" -> matrix, "RightHandSide" -> right,
    "MatrixDimensions" -> Dimensions[matrix],
    "AcceptedPoints" -> Lookup[accepted, "Point"],
    "PointDeltaValues" -> Lookup[accepted, "DeltaValues"],
    "PointRowRanges" -> pointRanges, "AttemptCount" -> attempts,
    "RejectedPoints" -> rejected, "SplitPointsOnly" -> splitOnly,
    "NormalizationCount" -> Length[normalization[[1]]],
    "RowBasis" -> "MultiquadraticGradeBasis",
    "ColumnOrder" -> assembly["ColumnOrder"], "RowOrder" -> assembly["RowOrder"],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripAssembleSample[___] :=
  multiquadraticStripFailure["InvalidSampleAssemblyArguments"];

(* ------------------------------------------------------------------ *)
(* Sign transforms and the differential certificate                     *)
(* ------------------------------------------------------------------ *)

(* The only place a branch sign exists: the invertible map from grade
   rows to the 2^r split-sign rows at a point.  A flip mask permutes
   the sign blocks and is the object under test, never a production
   parameter. *)
multiquadraticStripSignTransform[rootValues_List, prime_Integer] := Module[
  {rank = Length[rootValues], gradeCount, rootProducts},
  If[! PrimeQ[prime] || rank > $multiquadraticStripMaximumRootCount ||
      ! VectorQ[rootValues, IntegerQ[#1] && 0 < #1 < prime &],
    Return[multiquadraticStripFailure["InvalidSignTransformInput"]]];
  gradeCount = 2^rank;
  rootProducts = multiquadraticStripMaskFactorMod[#1, rootValues, prime] & /@
    Range[0, gradeCount - 1];
  Developer`ToPackedArray[Table[
    Mod[multiquadraticStripCharacter[signMask, grade, rank]
      rootProducts[[grade + 1]], prime],
    {signMask, 0, gradeCount - 1}, {grade, 0, gradeCount - 1}]]
];

multiquadraticStripTransformPointToSigns[pointResult_Association,
    rootValues_List, prime_Integer, flipMask_Integer: 0] := Module[
  {rootCount, gradeCount, equationsPerGrade, unknownCount, deltaValues,
   pointRows, pointRight, transform, rowsByGrade, rightByGrade, rows, right,
   transformedRow, transformedRight, sourceSign, targetGrade},
  If[Lookup[pointResult, "Status", None] =!= "AssembledMultiquadraticPointV1" ||
      Lookup[pointResult, "Prime", None] =!= prime,
    Return[multiquadraticStripFailure["InvalidPointTransformInput"]]];
  rootCount = Lookup[pointResult, "RootCount", $Failed];
  gradeCount = Lookup[pointResult, "GradeCount", $Failed];
  equationsPerGrade = Lookup[pointResult, "EquationsPerGrade", $Failed];
  unknownCount = Lookup[pointResult, "UnknownCount", $Failed];
  deltaValues = Lookup[pointResult, "DeltaValues", $Failed];
  pointRows = Lookup[pointResult, "Rows", $Failed];
  pointRight = Lookup[pointResult, "RightHandSide", $Failed];
  If[! IntegerQ[rootCount] || rootCount < 0 || ! IntegerQ[gradeCount] ||
      gradeCount =!= 2^rootCount || ! IntegerQ[equationsPerGrade] ||
      equationsPerGrade < 1 || ! IntegerQ[unknownCount] || unknownCount < 1 ||
      ! MatrixQ[pointRows, IntegerQ] ||
      Dimensions[pointRows] =!= {gradeCount equationsPerGrade, unknownCount} ||
      ! AllTrue[Flatten[pointRows], 0 <= #1 < prime &] ||
      ! VectorQ[pointRight, IntegerQ[#1] && 0 <= #1 < prime &] ||
      Length[pointRight] =!= gradeCount equationsPerGrade ||
      ! VectorQ[deltaValues, IntegerQ[#1] && 0 < #1 < prime &] ||
      Length[deltaValues] =!= rootCount || Length[rootValues] =!= rootCount ||
      ! VectorQ[rootValues, IntegerQ[#1] && 0 < #1 < prime &] ||
      Mod[rootValues^2 - deltaValues, prime] =!= ConstantArray[0, rootCount] ||
      ! IntegerQ[flipMask] || flipMask < 0 || flipMask >= gradeCount,
    Return[multiquadraticStripFailure["InvalidPointTransformParameters"]]];
  transform = multiquadraticStripSignTransform[rootValues, prime];
  If[! ListQ[transform],
    Return[multiquadraticStripFailure["SignTransformFailed"]]];
  rowsByGrade = ArrayReshape[pointRows,
    {gradeCount, equationsPerGrade, unknownCount}];
  rightByGrade = ArrayReshape[pointRight, {gradeCount, equationsPerGrade}];
  rows = Flatten[Table[
    sourceSign = BitXor[signMask, flipMask];
    Table[
      transformedRow = ConstantArray[0, unknownCount];
      Do[transformedRow = Mod[transformedRow +
          transform[[sourceSign + 1, targetGrade + 1]]
            rowsByGrade[[targetGrade + 1, equation]], prime],
        {targetGrade, 0, gradeCount - 1}];
      Developer`ToPackedArray[transformedRow],
      {equation, equationsPerGrade}],
    {signMask, 0, gradeCount - 1}], 1];
  right = Flatten[Table[
    sourceSign = BitXor[signMask, flipMask];
    Table[
      transformedRight = 0;
      Do[transformedRight = Mod[transformedRight +
          transform[[sourceSign + 1, targetGrade + 1]]
            rightByGrade[[targetGrade + 1, equation]], prime],
        {targetGrade, 0, gradeCount - 1}];
      transformedRight,
      {equation, equationsPerGrade}],
    {signMask, 0, gradeCount - 1}], 1];
  <|"Status" -> "TransformedMultiquadraticPointToSignsV1", "Prime" -> prime,
    "Point" -> pointResult["Point"], "RootValues" -> rootValues,
    "BranchFlipMask" -> flipMask, "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows], "SignTransform" -> transform|>
];
multiquadraticStripTransformPointToSigns[___] :=
  multiquadraticStripFailure["InvalidPointTransformArguments"];

multiquadraticStripTransformSampleToSigns[assembly_Association,
    sample_Association, prime_Integer, flipMask_Integer: 0] := Module[
  {pointCount, equationCount, normalizationCount, pointResults, transformed,
   deltaValues, rootValues, rows, right, normalizationRows, normalizationRight,
   index, range, expectedRanges, totalRows},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      Mod[prime, 4] =!= 3 ||
      Lookup[sample, "Status", None] =!= "AssembledMultiquadraticSampleV1" ||
      Lookup[sample, "AssemblyFingerprint", None] =!=
        assembly["AssemblyFingerprint"] || sample["Prime"] =!= prime,
    Return[multiquadraticStripFailure["InvalidSampleTransformInput"]]];
  pointCount = Length[sample["AcceptedPoints"]];
  equationCount = assembly["EquationsPerPoint"];
  normalizationCount = Lookup[sample, "NormalizationCount", $Failed];
  totalRows = pointCount equationCount + normalizationCount;
  expectedRanges = Table[{1 + (index - 1) equationCount, index equationCount},
    {index, pointCount}];
  If[pointCount < 1 || ! IntegerQ[normalizationCount] || normalizationCount < 0 ||
      ! MatchQ[sample["AcceptedPoints"], {{_Integer, _Integer} ..}] ||
      ! ListQ[Lookup[sample, "PointDeltaValues", None]] ||
      Length[sample["PointDeltaValues"]] =!= pointCount ||
      Lookup[sample, "PointRowRanges", None] =!= expectedRanges ||
      ! MatrixQ[Lookup[sample, "Matrix", None], IntegerQ] ||
      Dimensions[sample["Matrix"]] =!= {totalRows, assembly["UnknownCount"]} ||
      ! VectorQ[Lookup[sample, "RightHandSide", None],
        IntegerQ[#1] && 0 <= #1 < prime &] ||
      Length[sample["RightHandSide"]] =!= totalRows,
    Return[multiquadraticStripFailure["InvalidSampleTransformShape"]]];
  pointResults = Table[
    range = sample["PointRowRanges"][[index]];
    <|"Status" -> "AssembledMultiquadraticPointV1", "Prime" -> prime,
      "Point" -> sample["AcceptedPoints"][[index]],
      "Rows" -> sample["Matrix"][[range[[1]] ;; range[[2]]]],
      "RightHandSide" -> sample["RightHandSide"][[range[[1]] ;; range[[2]]]],
      "DeltaValues" -> sample["PointDeltaValues"][[index]],
      "RootCount" -> assembly["RootCount"], "GradeCount" -> assembly["GradeCount"],
      "EquationsPerGrade" -> 2 Times @@ assembly["Dimensions"],
      "UnknownCount" -> assembly["UnknownCount"]|>,
    {index, pointCount}];
  (* Return inside Table does not leave the enclosing function: the
     Codex original (DirectRootChannelAssembler.wl lines 1088-1099)
     leaves an unevaluated Return in the result list, which then
     degrades into a generic transform failure.  Tag the target. *)
  transformed = Table[
    deltaValues = sample["PointDeltaValues"][[index]];
    If[! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
      Return[multiquadraticStripFailure["PointNotSplitOverPrime",
        <|"PointIndex" -> index, "DeltaValues" -> deltaValues|>], Module]];
    rootValues = multiquadraticSquareRoots[deltaValues, prime];
    If[rootValues === $Failed,
      Return[multiquadraticStripFailure["PointSquareRootFailure",
        <|"PointIndex" -> index|>], Module]];
    multiquadraticStripTransformPointToSigns[pointResults[[index]], rootValues,
      prime, flipMask],
    {index, pointCount}];
  If[! AllTrue[transformed, Lookup[#1, "Status", None] ===
      "TransformedMultiquadraticPointToSignsV1" &],
    Return[multiquadraticStripFailure["SamplePointTransformFailed"]]];
  rows = Join @@ Lookup[transformed, "Rows"];
  right = Join @@ Lookup[transformed, "RightHandSide"];
  If[normalizationCount > 0,
    normalizationRows = Take[sample["Matrix"], -normalizationCount];
    normalizationRight = Take[sample["RightHandSide"], -normalizationCount];
    rows = Join[rows, normalizationRows];
    right = Join[right, normalizationRight]];
  <|"Status" -> "TransformedMultiquadraticSampleToSignsV1", "Prime" -> prime,
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows], "BranchFlipMask" -> flipMask|>
];
multiquadraticStripTransformSampleToSigns[___] :=
  multiquadraticStripFailure["InvalidSampleTransformArguments"];

(* The independent reference: the same equations built one sign branch
   at a time by substituting +-root values into the exact strip, with no
   channel decomposition and no compiled ABI.  It shares nothing with
   the direct assembler except the index formulas, so agreement is a
   real differential statement. *)
multiquadraticStripSplitPointRows[assembly_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    flipMask_Integer: 0] := Catch[Module[
  {variables, epsilon, record, strip, e, c, bbar, roots, oneForms, support,
   gaugeDenominator, dimensions, upperDimension, lowerDimension, rank,
   gradeCount, supportCount, gaugeUnknownCount, unknownCount, epsilonMod,
   deltaValues, rootValues, denominatorValue, denominatorInverse,
   denominatorDerivatives, deltaLogDerivatives, rootProducts, signs,
   branchValue, branchMatrix, branchPair, basisValue, basisDerivative,
   eValues, cValues, bbarValues, oneFormValues, rows, right, row, rowIndex,
   sourceSign, xPower, yPower, monomialValue, monomialLog, value},
  variables = assembly["Variables"];
  epsilon = assembly["Regulator"];
  record = assembly["Record"];
  roots = assembly["Roots"];
  oneForms = assembly["OneForms"];
  support = assembly["GaugeSupport"];
  gaugeDenominator = assembly["GaugeDenominator"];
  strip = record["Strip"];
  {e, c, bbar} = strip;
  dimensions = assembly["Dimensions"];
  {upperDimension, lowerDimension} = dimensions;
  rank = assembly["RootCount"];
  gradeCount = assembly["GradeCount"];
  supportCount = Length[support];
  gaugeUnknownCount = assembly["GaugeUnknownCount"];
  unknownCount = assembly["UnknownCount"];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Throw[multiquadraticStripFailure["InvalidRegulatorImage"],
      "MultiquadraticStripSplitFailure"]];
  deltaValues = multiquadraticStripModRational[
      #1 /. Thread[variables -> point], prime] & /@ Lookup[roots, "RootSquare", {}];
  If[MemberQ[deltaValues, $Failed | 0] ||
      ! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
    Throw[multiquadraticStripFailure["PointNotSplitOverPrime",
      <|"Point" -> point|>], "MultiquadraticStripSplitFailure"]];
  rootValues = multiquadraticSquareRoots[deltaValues, prime];
  If[rootValues === $Failed,
    Throw[multiquadraticStripFailure["PointSquareRootFailure"],
      "MultiquadraticStripSplitFailure"]];
  denominatorValue = multiquadraticStripModRational[
    gaugeDenominator /. Thread[variables -> point] /. epsilon -> epsilonValue,
    prime];
  If[denominatorValue === $Failed || denominatorValue === 0,
    Throw[multiquadraticStripFailure["ZeroGaugeDenominator"],
      "MultiquadraticStripSplitFailure"]];
  denominatorInverse = PowerMod[denominatorValue, -1, prime];
  denominatorDerivatives = multiquadraticStripModRational[
      D[gaugeDenominator, #1] /. Thread[variables -> point] /.
        epsilon -> epsilonValue, prime] & /@ variables;
  If[MemberQ[denominatorDerivatives, $Failed],
    Throw[multiquadraticStripFailure["GaugeDenominatorDerivativeSingular"],
      "MultiquadraticStripSplitFailure"]];
  deltaLogDerivatives = Table[
    value = multiquadraticStripModRational[
      D[roots[[a, "RootSquare"]], variables[[mu]]]/roots[[a, "RootSquare"]] /.
        Thread[variables -> point], prime];
    If[value === $Failed,
      Throw[multiquadraticStripFailure["RootLogDerivativeSingular"],
        "MultiquadraticStripSplitFailure"]];
    value,
    {a, rank}, {mu, 2}];
  rootProducts = multiquadraticStripMaskFactorMod[#1, rootValues, prime] & /@
    Range[0, gradeCount - 1];
  branchValue[expression_, signList_] := Module[{branched, image},
    branched = transportChartApplyRootBranches[expression, roots,
      Mod[signList rootValues, prime]];
    image = multiquadraticStripModRational[
      branched /. Thread[variables -> point] /. epsilon -> epsilonValue, prime];
    If[image === $Failed,
      Throw[multiquadraticStripFailure["BranchValueSingular"],
        "MultiquadraticStripSplitFailure"]];
    image];
  branchMatrix[matrix_, signList_] := Map[branchValue[#1, signList] &, matrix, {2}];
  branchPair[pair_, signList_] := branchMatrix[#1, signList] & /@ pair;
  eValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[e, signs], {signMask, 0, gradeCount - 1}];
  cValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[c, signs], {signMask, 0, gradeCount - 1}];
  bbarValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[bbar, signs], {signMask, 0, gradeCount - 1}];
  oneFormValues = Table[
    signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchValue[oneForms[[letter, mu]], signs],
    {signMask, 0, gradeCount - 1}, {letter, Length[oneForms]}, {mu, 2}];
  rows = Table[ConstantArray[0, unknownCount], gradeCount 2 upperDimension lowerDimension];
  right = ConstantArray[0, gradeCount 2 upperDimension lowerDimension];
  Do[
    sourceSign = BitXor[signMask, flipMask];
    rowIndex = multiquadraticStripPointRowIndex[signMask, mu, i, j,
      upperDimension, lowerDimension];
    row = ConstantArray[0, unknownCount];
    Do[
      {xPower, yPower} = support[[monomial]];
      monomialValue = Mod[PowerMod[Mod[point[[1]], prime], xPower, prime]
        PowerMod[Mod[point[[2]], prime], yPower, prime], prime];
      basisValue = Mod[multiquadraticStripCharacter[sourceSign, grade, rank]
        rootProducts[[grade + 1]] monomialValue denominatorInverse, prime];
      monomialLog = If[mu === 1,
        If[xPower === 0, 0,
          Mod[xPower PowerMod[Mod[point[[1]], prime], -1, prime], prime]],
        If[yPower === 0, 0,
          Mod[yPower PowerMod[Mod[point[[2]], prime], -1, prime], prime]]];
      basisDerivative = Mod[basisValue Mod[monomialLog -
        denominatorDerivatives[[mu]] denominatorInverse +
        PowerMod[2, -1, prime] Sum[If[BitGet[grade, a - 1] === 1,
          deltaLogDerivatives[[a, mu]], 0], {a, rank}], prime], prime];
      row[[multiquadraticStripGaugeIndex[upperDimension, lowerDimension,
        gradeCount, supportCount, i, j, grade, monomial]]] +=
        basisDerivative;
      Do[row[[multiquadraticStripGaugeIndex[upperDimension, lowerDimension,
          gradeCount, supportCount, a, j, grade, monomial]]] +=
          -epsilonMod eValues[[sourceSign + 1, mu, i, a]] basisValue,
        {a, upperDimension}];
      Do[row[[multiquadraticStripGaugeIndex[upperDimension, lowerDimension,
          gradeCount, supportCount, i, b, grade, monomial]]] +=
          epsilonMod cValues[[sourceSign + 1, mu, b, j]] basisValue,
        {b, lowerDimension}],
      {grade, 0, gradeCount - 1}, {monomial, supportCount}];
    Do[row[[multiquadraticStripResidueIndex[gaugeUnknownCount, upperDimension,
        lowerDimension, letter, i, j]]] +=
        epsilonMod oneFormValues[[sourceSign + 1, letter, mu]],
      {letter, Length[oneForms]}];
    rows[[rowIndex]] = Mod[row, prime];
    right[[rowIndex]] = Mod[bbarValues[[sourceSign + 1, mu, i, j]], prime],
    {signMask, 0, gradeCount - 1}, {mu, 2}, {i, upperDimension},
    {j, lowerDimension}];
  <|"Status" -> "MultiquadraticSplitPointRowsV1", "Prime" -> prime,
    "Point" -> Mod[point, prime], "DeltaValues" -> deltaValues,
    "RootValues" -> rootValues, "BranchFlipMask" -> flipMask,
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "UnknownCount" -> unknownCount|>
], "MultiquadraticStripSplitFailure"];

multiquadraticStripDifferentialCheckPoint[assembly_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    flipMask_Integer: 0] := Module[
  {startTime = AbsoluteTime[], epsilonForms, direct, deltaValues, rootValues,
   transformed, reference, matrixEqual, rightEqual, passed},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      Mod[prime, 4] =!= 3,
    Return[multiquadraticStripFailure["InvalidDifferentialAssembly"]]];
  epsilonForms = multiquadraticStripCollapseEpsilon[assembly, prime, epsilonValue];
  If[Lookup[epsilonForms, "Status", None] =!=
        "MultiquadraticStripEpsilonFormsV1" ||
      ! multiquadraticStripEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Return[multiquadraticStripFailure["DifferentialRegulatorCollapseFailed"]]];
  direct = multiquadraticStripAssemblePointInternal[assembly, epsilonForms,
    prime, point, assembly["AssemblyFingerprint"]];
  If[Lookup[direct, "Status", None] =!= "AssembledMultiquadraticPointV1",
    Return[direct]];
  deltaValues = direct["DeltaValues"];
  If[! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
    Return[multiquadraticStripFailure["DifferentialPointNotSplit",
      <|"DeltaValues" -> deltaValues|>]]];
  rootValues = multiquadraticSquareRoots[deltaValues, prime];
  If[rootValues === $Failed,
    Return[multiquadraticStripFailure["DifferentialSquareRootFailure"]]];
  transformed = multiquadraticStripTransformPointToSigns[direct, rootValues,
    prime, flipMask];
  If[Lookup[transformed, "Status", None] =!=
      "TransformedMultiquadraticPointToSignsV1", Return[transformed]];
  reference = multiquadraticStripSplitPointRows[assembly, epsilonValue, prime,
    point, flipMask];
  If[Lookup[reference, "Status", None] =!= "MultiquadraticSplitPointRowsV1",
    Return[reference]];
  matrixEqual = TrueQ[Normal[transformed["Rows"]] === Normal[reference["Rows"]]];
  rightEqual = TrueQ[Normal[transformed["RightHandSide"]] ===
    Normal[reference["RightHandSide"]]];
  passed = TrueQ[matrixEqual && rightEqual];
  <|"Status" -> If[passed, "MultiquadraticPointDifferentialPassed",
      "MultiquadraticPointDifferentialFailed"],
    "Passed" -> passed, "MatrixEqual" -> matrixEqual,
    "RightHandSideEqual" -> rightEqual, "Prime" -> prime,
    "EpsilonValue" -> epsilonValue, "Point" -> point,
    "RootCount" -> assembly["RootCount"], "BranchFlipMask" -> flipMask,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripDifferentialCheckPoint[___] :=
  multiquadraticStripFailure["InvalidDifferentialPointArguments"];

(* ------------------------------------------------------------------ *)
(* Modular solve, unpacking, exact verification                         *)
(* ------------------------------------------------------------------ *)

(* Deterministic RREF: a particular solution with every free column
   zero, plus the nullspace basis, plus the residual check.  The pivot
   columns are the elimination signature that must not move between
   primes or regulator values. *)
multiquadraticStripAffineSolve[matrix_?MatrixQ, right_List, prime_Integer] :=
  Module[
  {dimensions = Dimensions[matrix], unknownCount, augmented, reduced,
   coefficientPart, pivotRows = {}, pivotColumns = {}, position,
   inconsistentRows, freeColumns, particular, nullspace, residual, nullResidual},
  If[! PrimeQ[prime],
    Return[multiquadraticStripFailure["InvalidPrime", <|"Prime" -> prime|>]]];
  If[Length[dimensions] =!= 2 || dimensions[[1]] =!= Length[right],
    Return[multiquadraticStripFailure["AffineDimensionMismatch"]]];
  unknownCount = dimensions[[2]];
  augmented = MapThread[Append, {Mod[Normal[matrix], prime], Mod[right, prime]}];
  reduced = RowReduce[augmented, Modulus -> prime];
  coefficientPart = reduced[[All, 1 ;; unknownCount]];
  Do[
    position = SelectFirst[Range[unknownCount],
      Mod[coefficientPart[[row, #1]], prime] =!= 0 &, Missing["NotFound"]];
    If[! MissingQ[position],
      AppendTo[pivotRows, row]; AppendTo[pivotColumns, position]],
    {row, Length[coefficientPart]}];
  If[! DuplicateFreeQ[pivotColumns] ||
      ! AllTrue[pivotColumns, IntegerQ[#1] && 1 <= #1 <= unknownCount &] ||
      Length[pivotColumns] > Min[dimensions],
    Return[multiquadraticStripFailure["InvalidPivotStructure",
      <|"Prime" -> prime, "MatrixDimensions" -> dimensions,
        "PivotColumns" -> pivotColumns|>]]];
  inconsistentRows = Select[Range[Length[coefficientPart]],
    multiquadraticStripZeroQ[Mod[coefficientPart[[#1]], prime]] &&
      Mod[reduced[[#1, -1]], prime] =!= 0 &];
  If[inconsistentRows =!= {},
    Return[multiquadraticStripFailure["InconsistentModularSystem",
      <|"Prime" -> prime, "MatrixDimensions" -> dimensions,
        "InconsistentRows" -> inconsistentRows|>]]];
  freeColumns = Complement[Range[unknownCount], pivotColumns];
  particular = ConstantArray[0, unknownCount];
  Do[particular[[pivotColumns[[k]]]] = Mod[reduced[[pivotRows[[k]], -1]], prime],
    {k, Length[pivotColumns]}];
  nullspace = Table[Module[{vector = ConstantArray[0, unknownCount]},
    vector[[free]] = 1;
    Do[vector[[pivotColumns[[k]]]] = Mod[-reduced[[pivotRows[[k]], free]], prime],
      {k, Length[pivotColumns]}];
    vector], {free, freeColumns}];
  residual = AllTrue[Mod[matrix . particular - right, prime], #1 === 0 &];
  nullResidual = AllTrue[nullspace,
    Function[vector, AllTrue[Mod[matrix . vector, prime], #1 === 0 &]]];
  If[! (TrueQ[residual] && TrueQ[nullResidual]),
    Return[multiquadraticStripFailure["AffineResidualNonzero",
      <|"Prime" -> prime, "ResidualZero" -> residual,
        "NullspaceResidualZero" -> nullResidual|>]]];
  <|"Status" -> "MultiquadraticAffineSolution", "Prime" -> prime,
    "MatrixDimensions" -> dimensions, "Rank" -> Length[pivotColumns],
    "Nullity" -> Length[freeColumns], "PivotColumns" -> pivotColumns,
    "FreeColumns" -> freeColumns,
    "PivotSignature" -> Hash[pivotColumns, "SHA256", "HexString"],
    "ParticularSolution" -> particular, "NullspaceBasis" -> nullspace|>
];
multiquadraticStripAffineSolve[___] :=
  multiquadraticStripFailure["InvalidAffineSolveArguments"];

multiquadraticStripUnpackVector[preparation_Association, vector_List] := Module[
  {dimensions, gradeCount, support, denominator, variables, gaugeUnknownCount,
   gaugeCoefficients, gaugeChannels, residues},
  If[! multiquadraticStripPreparationValidQ[preparation],
    Return[multiquadraticStripFailure["InvalidPreparationABI"]]];
  If[Length[vector] =!= preparation["UnknownCount"],
    Return[multiquadraticStripFailure["ReconstructedVectorLengthMismatch",
      <|"Expected" -> preparation["UnknownCount"],
        "Observed" -> Length[vector]|>]]];
  dimensions = preparation["Dimensions"];
  gradeCount = preparation["GradeCount"];
  support = preparation["GaugeSupport"];
  denominator = preparation["GaugeDenominator"];
  variables = preparation["Variables"];
  gaugeUnknownCount = preparation["GaugeUnknownCount"];
  gaugeCoefficients = Table[
    vector[[multiquadraticStripGaugeIndex[dimensions[[1]], dimensions[[2]],
      gradeCount, Length[support], i, j, grade, monomial]]],
    {i, dimensions[[1]]}, {j, dimensions[[2]]}, {grade, 0, gradeCount - 1},
    {monomial, Length[support]}];
  gaugeChannels = Table[Together[
      Sum[gaugeCoefficients[[i, j, grade, monomial]]
          variables[[1]]^support[[monomial, 1]]
          variables[[2]]^support[[monomial, 2]],
        {monomial, Length[support]}]/denominator],
    {i, dimensions[[1]]}, {j, dimensions[[2]]}, {grade, gradeCount}];
  residues = If[preparation["ResidueUnknownCount"] === 0, {},
    Table[vector[[multiquadraticStripResidueIndex[gaugeUnknownCount,
      dimensions[[1]], dimensions[[2]], letter, i, j]]],
      {letter, Length[preparation["OneForms"]]}, {i, dimensions[[1]]},
      {j, dimensions[[2]]}]];
  <|"Status" -> "UnpackedMultiquadraticSolution",
    "GaugeCoefficients" -> gaugeCoefficients, "GaugeChannels" -> gaugeChannels,
    "Gauge" -> Table[multiquadraticFieldCompose[gaugeChannels[[i, j]],
        preparation["Roots"]],
      {i, dimensions[[1]]}, {j, dimensions[[2]]}],
    "Residues" -> residues|>
];
multiquadraticStripUnpackVector[___] :=
  multiquadraticStripFailure["InvalidUnpackArguments"];

multiquadraticStripChannelMatrixProduct[left_List, right_List, deltas_List] :=
  Module[{leftDimensions = Dimensions[left], rightDimensions = Dimensions[right],
    inner},
  If[Length[leftDimensions] =!= 3 || Length[rightDimensions] =!= 3 ||
      leftDimensions[[2]] =!= rightDimensions[[1]] ||
      leftDimensions[[3]] =!= rightDimensions[[3]], Return[$Failed]];
  inner = leftDimensions[[2]];
  Table[Together /@ Total[Table[
      multiquadraticMultiply[left[[i, k]], right[[k, j]], deltas], {k, inner}]],
    {i, leftDimensions[[1]]}, {j, rightDimensions[[2]]}]
];

(* The exact statement about a reconstructed vector: every grade of
   d_mu G - eps (E G - G C) + eps R omega - Bbar vanishes identically in
   the chart variables.  With a regulator VALUE the identity is made at
   that value, which is what a per-value lift certifies. *)
multiquadraticStripExactChannelResidual[preparation_Association, vector_List,
    epsilonValue_: Automatic] := Module[
  {unpacked, gauge, residues, record, roots, deltas, variables, epsilon,
   epsilonImage, strip, decompose, eChannels, cChannels, bbarChannels,
   oneFormChannels, derivative, leftProduct, rightProduct, residueTerm, residual},
  unpacked = multiquadraticStripUnpackVector[preparation, vector];
  If[Lookup[unpacked, "Status", None] =!= "UnpackedMultiquadraticSolution",
    Return[unpacked]];
  gauge = unpacked["GaugeChannels"];
  residues = unpacked["Residues"];
  record = preparation["Record"];
  roots = preparation["Roots"];
  deltas = Lookup[roots, "RootSquare", {}];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  epsilonImage = If[epsilonValue === Automatic, epsilon, epsilonValue];
  strip = record["Strip"] /. epsilon -> epsilonImage;
  decompose[matrix_] := Map[multiquadraticFieldDecompose[#1, roots] &, matrix, {2}];
  eChannels = decompose /@ strip[[1]];
  cChannels = decompose /@ strip[[2]];
  bbarChannels = decompose /@ strip[[3]];
  oneFormChannels = Table[
    multiquadraticFieldDecompose[
      preparation["OneForms"][[letter, mu]] /. epsilon -> epsilonImage, roots],
    {letter, Length[preparation["OneForms"]]}, {mu, 2}];
  If[! FreeQ[{eChannels, cChannels, bbarChannels, oneFormChannels}, $Failed],
    Return[multiquadraticStripFailure["ExactChannelDecompositionFailed"]]];
  residual = Table[
    derivative = Map[multiquadraticDerivative[#1, deltas, variables[[mu]]] &,
      gauge, {2}];
    leftProduct = multiquadraticStripChannelMatrixProduct[eChannels[[mu]], gauge,
      deltas];
    rightProduct = multiquadraticStripChannelMatrixProduct[gauge, cChannels[[mu]],
      deltas];
    If[leftProduct === $Failed || rightProduct === $Failed,
      Return[multiquadraticStripFailure["ExactChannelDimensionMismatch"], Module]];
    residueTerm = If[Length[preparation["OneForms"]] === 0,
      ConstantArray[0, Append[preparation["Dimensions"], preparation["GradeCount"]]],
      Table[Together /@ Total[Table[
          residues[[letter, i, j]] oneFormChannels[[letter, mu]],
          {letter, Length[preparation["OneForms"]]}]],
        {i, preparation["Dimensions"][[1]]}, {j, preparation["Dimensions"][[2]]}]];
    Map[Together, derivative - epsilonImage leftProduct +
      epsilonImage rightProduct + epsilonImage residueTerm -
      bbarChannels[[mu]], {3}],
    {mu, 2}];
  <|"Status" -> If[multiquadraticStripZeroQ[residual],
      "ExactChannelResidualZero", "ExactChannelResidualNonzero"],
    "ResidualZero" -> multiquadraticStripZeroQ[residual],
    "EpsilonValue" -> epsilonImage, "ResidualChannels" -> residual|>
];

(* CRT over the sampled primes, then rational reconstruction coordinate
   by coordinate (the package's epsFormFiniteFieldRationalReconstruct).
   A coordinate that does not lift is reported, not guessed. *)
multiquadraticStripLiftVector[images_List, primes_List] := Module[
  {modulus, combined, lifted, failures},
  If[Length[images] =!= Length[primes] || images === {} ||
      ! MatrixQ[images, IntegerQ] || ! VectorQ[primes, PrimeQ],
    Return[multiquadraticStripFailure["InvalidLiftInput"]]];
  If[! AllTrue[images, Length[#1] === Length[First[images]] &],
    Return[multiquadraticStripFailure["InconsistentLiftWidths"]]];
  modulus = Times @@ primes;
  combined = Table[ChineseRemainder[images[[All, index]], primes],
    {index, Length[First[images]]}];
  lifted = epsFormFiniteFieldRationalReconstruct[#1, modulus] & /@ combined;
  failures = Flatten[Position[lifted, $Failed, {1}, Heads -> False]];
  If[failures =!= {},
    Return[multiquadraticStripFailure["RationalReconstructionFailed",
      <|"Coordinates" -> failures, "Modulus" -> modulus|>]]];
  <|"Status" -> "LiftedMultiquadraticVector", "Vector" -> lifted,
    "Modulus" -> modulus, "Primes" -> primes|>
];

(* ------------------------------------------------------------------ *)
(* Artifacts: raw load and validation are separate                      *)
(* ------------------------------------------------------------------ *)

multiquadraticStripArtifactWrite[value_, file_String] := Module[
  {directory, temporary},
  directory = DirectoryName[ExpandFileName[file]];
  If[directory =!= "" && ! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  temporary = file <> ".partial-" <> ToString[$ProcessID];
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True];
  <|"Status" -> "MultiquadraticArtifactWritten", "File" -> file,
    "SHA256" -> FileHash[file, "SHA256", "HexString"]|>
];

(* Raw hydration only.  The artifact context is explicit and its
   namespace is created before the read, so an artifact is never parsed
   into Global` by accident and never into CANONICA`; CheckAbort keeps
   a valid artifact that merely emitted a suppressed message (pool
   defects 3 and 4).  Nothing here decides admissibility -- the
   validator does. *)
multiquadraticStripArtifactLoadRaw[file_String, context_String] := Module[
  {value, messages},
  If[! StringEndsQ[context, "`"],
    Return[multiquadraticStripFailure["InvalidArtifactContext",
      <|"Context" -> context|>]]];
  If[! FileExistsQ[file],
    Return[multiquadraticStripFailure["ArtifactFileMissing", <|"File" -> file|>]]];
  {value, messages} = Block[
    {$Context = context, $ContextPath = {context, "System`"}, $MessageList = {}},
    Quiet[{CheckAbort[Get[file], $Aborted], $MessageList}]];
  If[value === $Aborted,
    Return[multiquadraticStripFailure["ArtifactReadAborted",
      <|"File" -> file, "Messages" -> ToString[messages]|>]]];
  <|"Status" -> "RawMultiquadraticArtifact", "File" -> file,
    "Context" -> context, "Value" -> value,
    "Messages" -> ToString[messages],
    "SHA256" -> FileHash[file, "SHA256", "HexString"]|>
];

multiquadraticStripReadPreparedArtifact[file_String,
    context_String: "FeynFacet`MultiquadraticArtifact`"] := Module[
  {raw, value},
  raw = multiquadraticStripArtifactLoadRaw[file, context];
  If[Lookup[raw, "Status", None] =!= "RawMultiquadraticArtifact", Return[raw]];
  value = raw["Value"];
  If[! AssociationQ[value],
    Return[multiquadraticStripFailure["ArtifactNotAnAssociation",
      <|"File" -> file, "Head" -> ToString[Head[value]]|>]]];
  Which[
    Lookup[value, "Status", None] === "PreparedMultiquadraticStripV1",
      If[multiquadraticStripPreparationValidQ[value],
        <|"Status" -> "HydratedMultiquadraticPreparation", "File" -> file,
          "Context" -> context, "Preparation" -> value,
          "ABIFingerprint" -> value["ABIFingerprint"]|>,
        multiquadraticStripFailure["ArtifactPreparationABIInvalid",
          <|"File" -> file|>]],
    Lookup[value, "Status", None] === "CompiledMultiquadraticStripV1",
      If[multiquadraticStripCompiledValidQ[value],
        <|"Status" -> "HydratedMultiquadraticAssembly", "File" -> file,
          "Context" -> context, "Assembly" -> value,
          "AssemblyFingerprint" -> value["AssemblyFingerprint"]|>,
        multiquadraticStripFailure["ArtifactAssemblyABIInvalid",
          <|"File" -> file|>]],
    True,
      multiquadraticStripFailure["ArtifactSchemaUnknown",
        <|"File" -> file, "ArtifactStatus" -> Lookup[value, "Status", None]|>]]
];
multiquadraticStripReadPreparedArtifact[___] :=
  multiquadraticStripFailure["InvalidArtifactReadArguments"];

(* ------------------------------------------------------------------ *)
(* Option gates                                                         *)
(* ------------------------------------------------------------------ *)

multiquadraticStripOptionNames[opts_List] :=
  Cases[Flatten[opts], (name_ -> _) | (name_ :> _) :> name];

(* A production entry point refuses a branch flip outright and refuses
   an unknown option rather than ignoring it silently. *)
multiquadraticStripProductionOptionGate[opts_List, allowed_List] := Module[
  {names = multiquadraticStripOptionNames[opts], unknown},
  If[MemberQ[names, "BranchFlipMask"],
    Return[multiquadraticStripFailure["BranchFlipMaskNotAvailableInProduction",
      <|"Reason" -> "direct grade rows are branch invariant; sign flips exist only in the sign-transform and differential-certificate functions"|>]]];
  unknown = DeleteDuplicates[Select[names, ! MemberQ[allowed, #1] &]];
  If[unknown =!= {},
    Return[multiquadraticStripFailure["UnknownOption", <|"Options" -> unknown|>]]];
  None
];

(* The requested backend is validated exhaustively: an unavailable one
   fails closed rather than falling through to the Wolfram path
   (package bug handoff 2026-08-23, existing defect 1). *)
multiquadraticStripBackendGate[backend_] := Which[
  backend === Automatic || backend === "Wolfram", None,
  StringQ[backend],
    multiquadraticStripFailure["PlanDiscoveryBackendUnavailable",
      <|"RequestedBackend" -> backend,
        "AvailableBackends" -> {Automatic, "Wolfram"}|>],
  True,
    multiquadraticStripFailure["InvalidPlanDiscoveryBackend",
      <|"RequestedBackend" -> ToString[backend]|>]
];

multiquadraticStripClearCaches[] := (
  $multiquadraticStripPrimeCache = <||>;
  $multiquadraticStripEpsilonCache = <||>;
  <|"Status" -> "MultiquadraticStripCachesCleared"|>);

(* ------------------------------------------------------------------ *)
(* Top-level entry point                                                *)
(* ------------------------------------------------------------------ *)

Options[solveEpsFormStripMultiquadratic] = Join[
  Options[multiquadraticStripPrepare], {
  "SamplePrimes" -> Automatic,
  "RegulatorValues" -> Automatic,
  "HeldOutPrime" -> Automatic,
  "HeldOutRegulatorValue" -> Automatic,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082307,
  "PlanDiscoveryBackend" -> Automatic,
  "DifferentialCheck" -> True,
  "Verbose" -> False
}];

(* The terminal success status is ModularConsistent.  It is NEVER
   "Solved": the package strip contract needs a certified dlog
   potential per letter, and this route returns closed one-forms
   (package bug handoff 2026-08-23, External gap 2).  The sector driver
   records the result; installation stays blocked until an OneForms
   contract exists. *)
solveEpsFormStripMultiquadratic[record_Association, frame_Association,
    opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, backendGate, verbose, log, preparation,
   assembly, primes, regulatorValues, heldOutPrime, heldOutRegulatorValue,
   allPrimes, samples = <||>, solutions = <||>, sample, solution, signature,
   signatures = {}, lifts = <||>, exactChecks = <||>, heldOutSample,
   heldOutSolution, heldOutResidual, branchCertificate, branchMask,
   transformedSample, differential, liftedVector, unpacked, prime,
   regulatorValue, samplerOptions},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[solveEpsFormStripMultiquadratic]]]];
  If[AssociationQ[gate], Return[gate]];
  backendGate = multiquadraticStripBackendGate[OptionValue["PlanDiscoveryBackend"]];
  If[AssociationQ[backendGate], Return[backendGate]];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print["[multiquadratic] ", items]];
  preparation = multiquadraticStripPrepare[record, frame,
    Sequence @@ FilterRules[{opts}, Options[multiquadraticStripPrepare]]];
  If[Lookup[preparation, "Status", None] =!= "PreparedMultiquadraticStripV1",
    Return[preparation]];
  log["prepared: rank ", preparation["RootCount"], ", ",
    preparation["UnknownCount"], " unknowns, ",
    preparation["EquationsPerPoint"], " equations per point"];
  assembly = multiquadraticStripCompile[preparation];
  If[Lookup[assembly, "Status", None] =!= "CompiledMultiquadraticStripV1",
    Return[assembly]];
  primes = Replace[OptionValue["SamplePrimes"],
    Automatic :> $multiquadraticStripDefaultPrimes];
  regulatorValues = Replace[OptionValue["RegulatorValues"],
    Automatic :> $multiquadraticStripDefaultRegulatorValues];
  heldOutPrime = Replace[OptionValue["HeldOutPrime"], Automatic :> 2147483323];
  heldOutRegulatorValue = Replace[OptionValue["HeldOutRegulatorValue"],
    Automatic :> 5/23];
  allPrimes = Append[primes, heldOutPrime];
  If[! VectorQ[primes, IntegerQ] || primes === {} ||
      ! AllTrue[allPrimes, PrimeQ[#1] && Mod[#1, 4] === 3 && 3 < #1 < 2^31 &] ||
      ! DuplicateFreeQ[allPrimes] || ! ListQ[regulatorValues] ||
      regulatorValues === {} ||
      ! AllTrue[Append[regulatorValues, heldOutRegulatorValue],
        MatchQ[#1, _Integer | _Rational] &] ||
      MemberQ[regulatorValues, heldOutRegulatorValue],
    Return[multiquadraticStripFailure["InvalidSamplingSchedule",
      <|"Primes" -> primes, "HeldOutPrime" -> heldOutPrime,
        "RegulatorValues" -> regulatorValues,
        "HeldOutRegulatorValue" -> heldOutRegulatorValue|>]]];
  samplerOptions = {"PointCount" -> OptionValue["PointCount"],
    "MaximumAttempts" -> OptionValue["MaximumAttempts"],
    "RandomSeed" -> OptionValue["RandomSeed"]};
  Do[
    sample = multiquadraticStripAssembleSample[assembly, regulatorValue, prime,
      Sequence @@ samplerOptions];
    If[Lookup[sample, "Status", None] =!= "AssembledMultiquadraticSampleV1",
      Return[sample, Module]];
    solution = multiquadraticStripAffineSolve[sample["Matrix"],
      sample["RightHandSide"], prime];
    If[Lookup[solution, "Status", None] =!= "MultiquadraticAffineSolution",
      Return[solution, Module]];
    samples[{prime, regulatorValue}] = sample;
    solutions[{prime, regulatorValue}] = solution;
    AppendTo[signatures, {solution["Rank"], solution["Nullity"],
      solution["PivotSignature"]}];
    log["prime ", prime, ", eps ", regulatorValue, ": rank ",
      solution["Rank"], ", nullity ", solution["Nullity"]],
    {regulatorValue, regulatorValues}, {prime, primes}];
  If[Length[DeleteDuplicates[signatures]] =!= 1,
    Return[multiquadraticStripFailure["ModularStructureUnstable",
      <|"Signatures" -> DeleteDuplicates[signatures]|>]]];
  signature = First[signatures];
  (* held-out prime AND held-out regulator value: the guard against a
     structure that only exists at the sampled images.  Split points
     are required here and only here, so that the same held-out
     solution also carries the sign-branch certificate. *)
  heldOutSample = multiquadraticStripAssembleSample[assembly,
    heldOutRegulatorValue, heldOutPrime, Sequence @@ samplerOptions,
    "SplitPointsOnly" -> True];
  If[Lookup[heldOutSample, "Status", None] =!= "AssembledMultiquadraticSampleV1",
    Return[heldOutSample]];
  heldOutSolution = multiquadraticStripAffineSolve[heldOutSample["Matrix"],
    heldOutSample["RightHandSide"], heldOutPrime];
  If[Lookup[heldOutSolution, "Status", None] =!= "MultiquadraticAffineSolution",
    Return[heldOutSolution]];
  If[{heldOutSolution["Rank"], heldOutSolution["Nullity"],
      heldOutSolution["PivotSignature"]} =!= signature,
    Return[multiquadraticStripFailure["HeldOutStructureMismatch",
      <|"Signature" -> signature,
        "HeldOutSignature" -> {heldOutSolution["Rank"],
          heldOutSolution["Nullity"], heldOutSolution["PivotSignature"]}|>]]];
  (* every sign branch: the transformed system is the same statement,
     so the grade solution must satisfy all 2^r of them *)
  branchCertificate = Table[
    transformedSample = multiquadraticStripTransformSampleToSigns[assembly,
      heldOutSample, heldOutPrime, branchMask];
    If[Lookup[transformedSample, "Status", None] =!=
        "TransformedMultiquadraticSampleToSignsV1",
      Return[transformedSample, Module]];
    <|"BranchFlipMask" -> branchMask,
      "ResidualZero" -> AllTrue[Mod[transformedSample["Rows"] .
          heldOutSolution["ParticularSolution"] -
          transformedSample["RightHandSide"], heldOutPrime], #1 === 0 &]|>,
    {branchMask, 0, assembly["GradeCount"] - 1}];
  If[! AllTrue[branchCertificate, TrueQ[#1["ResidualZero"]] &],
    Return[multiquadraticStripFailure["BranchCertificateFailed",
      <|"BranchCertificate" -> branchCertificate|>]]];
  differential = If[TrueQ[OptionValue["DifferentialCheck"]],
    multiquadraticStripDifferentialCheckPoint[assembly, heldOutRegulatorValue,
      heldOutPrime, First[heldOutSample["AcceptedPoints"]], 0],
    <|"Status" -> "DifferentialCheckSkipped"|>];
  If[TrueQ[OptionValue["DifferentialCheck"]] &&
      Lookup[differential, "Status", None] =!=
        "MultiquadraticPointDifferentialPassed",
    Return[multiquadraticStripFailure["DifferentialCheckFailed",
      <|"Differential" -> differential|>]]];
  (* best-effort exact lift, one regulator value at a time: CRT over the
     sampled primes and rational reconstruction of the canonical
     particular solution, then the exact channel identity at that value *)
  Do[
    liftedVector = multiquadraticStripLiftVector[
      Table[solutions[{prime, regulatorValue}]["ParticularSolution"],
        {prime, primes}], primes];
    lifts[regulatorValue] = liftedVector;
    If[Lookup[liftedVector, "Status", None] === "LiftedMultiquadraticVector",
      exactChecks[regulatorValue] = multiquadraticStripExactChannelResidual[
        preparation, liftedVector["Vector"], regulatorValue];
      If[Lookup[exactChecks[regulatorValue], "Status", None] ===
          "ExactChannelResidualNonzero",
        Return[multiquadraticStripFailure["ExactChannelResidualNonzero",
          <|"RegulatorValue" -> regulatorValue|>], Module]]],
    {regulatorValue, regulatorValues}];
  unpacked = If[Lookup[lifts[First[regulatorValues]], "Status", None] ===
      "LiftedMultiquadraticVector",
    multiquadraticStripUnpackVector[preparation,
      lifts[First[regulatorValues]]["Vector"]],
    <|"Status" -> "NotLifted"|>];
  <|"Status" -> "ModularConsistent",
    "Method" -> "DirectRootChannel",
    "SolutionContract" -> "OneFormsNotCertified",
    "ContractNote" -> "closed one-forms, no certified dlog potential: this result is recorded, never installed as a solved epsilon form",
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "RootIndices" -> preparation["RootIndices"],
    "RootSquares" -> preparation["RootSquares"],
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Dimensions" -> preparation["Dimensions"],
    "GaugeSupport" -> preparation["GaugeSupport"],
    "GaugeDenominator" -> preparation["GaugeDenominator"],
    "OneForms" -> preparation["OneForms"],
    "UnknownCount" -> preparation["UnknownCount"],
    "EquationsPerPoint" -> preparation["EquationsPerPoint"],
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "AlgebraABIFingerprint" -> preparation["AlgebraABIFingerprint"],
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "Rank" -> signature[[1]], "Nullity" -> signature[[2]],
    "PivotSignature" -> signature[[3]],
    "PivotColumns" -> heldOutSolution["PivotColumns"],
    "SamplePrimes" -> primes, "RegulatorValues" -> regulatorValues,
    "HeldOutPrime" -> heldOutPrime,
    "HeldOutRegulatorValue" -> heldOutRegulatorValue,
    "HeldOutSolution" -> KeyTake[heldOutSolution, {"Rank", "Nullity",
      "PivotColumns", "FreeColumns", "PivotSignature", "ParticularSolution",
      "NullspaceBasis"}],
    "ModularSolutions" -> Association[KeyValueMap[
      #1 -> KeyTake[#2, {"Rank", "Nullity", "PivotSignature",
        "ParticularSolution"}] &, solutions]],
    "ExactLift" -> Association[KeyValueMap[
      #1 -> Lookup[#2, "Status", None] &, lifts]],
    "ExactLiftVectors" -> Association[KeyValueMap[
      #1 -> Lookup[#2, "Vector", Missing["NotLifted"]] &, lifts]],
    "ExactChannelResidual" -> Association[KeyValueMap[
      #1 -> Lookup[#2, "Status", None] &, exactChecks]],
    "GaugeChannels" -> Lookup[unpacked, "GaugeChannels",
      Missing["NotLifted"]],
    "Gauge" -> Lookup[unpacked, "Gauge", Missing["NotLifted"]],
    "Residues" -> Lookup[unpacked, "Residues", Missing["NotLifted"]],
    "BranchCertificate" -> branchCertificate,
    "DifferentialCheck" -> KeyTake[differential,
      {"Status", "Passed", "Point", "BranchFlipMask"}],
    "Seconds" -> AbsoluteTime[] - startTime|>
];
solveEpsFormStripMultiquadratic[___] :=
  multiquadraticStripFailure["InvalidSolveArguments"];

End[];
