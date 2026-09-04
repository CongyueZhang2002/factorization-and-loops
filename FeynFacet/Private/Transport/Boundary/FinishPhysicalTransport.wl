(* FinishPhysicalTransport.wl -- the ONE definition of a finished transport
   (Design/FinishedTransportContract_2026-09-03.md, user ruling 2026-09-03).

   FinishPhysicalTransport[family] reads the four stage inputs (the certified
   epsilon form, the accepted observable transport, the boundary-mode map and
   the graded endpoint record), materializes EVERY demanded (epsilon order,
   physical row) pair as an explicit sum of iterated integrals along the
   four-leg path from the physical boundary point to the target point,
   with coefficients that are explicit rational combinations of a named
   period basis, builds the period table and the relations, and attaches the
   three certificates: (i) the differential equation, (ii) the boundary
   matching, (iii) the binding fingerprints and the purity of the stored
   expressions.  PhysicalTransportFinishedQ re-verifies a record.

   The differential-equation certificate is exact on the canonical vector:
   the automaton's state is the canonical Laurent-slot vector at the target
   (verified on CF97: InitialDemandMap equals the T-Laurent functional and
   every letter lowers the slot order by one), so a unit slot functional
   gives every canonical row's expansion; the x-equation is checked at a
   generic point and the y-equation on the interior-base line x = x0, which
   together with the certified flatness of the connection prove the DE
   everywhere; the physical rows are tied to the canonical ones by the
   Laurent coefficients of T, checked term by term. *)

Clear[FinishPhysicalTransport, PhysicalTransportFinishedQ];
ClearAll[finishFail, finishZeroQ, finishNonzeroMatrixQ, finishResultRoot, finishRepositoryRoot, finishPhysicalPairs, finishDemandFunctionalCertificate,
  finishNumericEnumeration, finishStructuralDifferentialCertificate,
  finishCheapZeroQ, finishProbePoints, finishMemoryGuard, finishResidentBytes,
  finishInputFile, finishReadInputs, finishKernelLetters, finishLegLetters,
  finishEnumerateWords, finishCompose, finishPeriodSymbol,
  finishExpandCompositeWord, finishWord, finishTerms, finishExpression,
  finishPeriodTable, finishRelations, finishDifferentialCertificate,
  finishBoundaryCertificate, finishFingerprint, finishPurityCheck,
  finishAllowedSymbolQ, finishDerivativeTerms, finishCollect,
  finishIdentityValue, finishCanonicalTransport, finishTLaurent,
  finishInertWord, finishSlotIndex];

finishFail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
finishZeroQ[value_] := TrueQ[observableTransportZeroQ[value]];
(* exact: a matrix of rational numbers is nonzero iff its sparse form has
   a nonzero position; only symbolic entries need the radical-aware test *)
finishNonzeroMatrixQ[m_] := With[{normal = Normal[m]},
  If[MatrixQ[normal, NumericQ], Length[SparseArray[normal]["NonzeroPositions"]] > 0,
    AnyTrue[Flatten[normal], ! finishZeroQ[#] &]]];

(* the repository root, captured when this module is loaded:
   FeynFacet/Private/Transport/Boundary/<this file> *)
$finishModuleDirectory = DirectoryName[ExpandFileName[$InputFileName]];
finishRepositoryRoot[] := DirectoryName[$finishModuleDirectory, 4];
(* Round 10 memory rules (coordinator, 2026-09-03): a cheap zero test for
   the large rational-function entries of the demand map and the
   connection -- structural zero, else evaluation at two random rational
   points (nonzero at either proves nonzero), and the radical-aware exact
   test only for an entry that vanishes at both -- and a memory guard that
   refuses typed instead of growing past the allowance *)
$finishProbePoints = None;
finishProbePoints[variables_List] := If[$finishProbePoints =!= None && Length[First[$finishProbePoints][[All, 1]]] === Length[variables] && First[$finishProbePoints][[All, 1]] === variables, $finishProbePoints,
  $finishProbePoints = BlockRandom[SeedRandom[20260903 + 17];
    Table[Thread[variables -> RandomInteger[{3, 10^6}, Length[variables]]/RandomInteger[{1, 997}, Length[variables]]], {2}]]];
finishCheapZeroQ[value_, variables_List] := Which[
  value === 0, True,
  NumericQ[value], TrueQ[PossibleZeroQ[value]],
  True, With[{numeric = Quiet[Check[Table[N[value /. point, 30], {point, finishProbePoints[variables]}], $Failed]]},
    If[numeric === $Failed, finishZeroQ[value],
      If[AnyTrue[numeric, Abs[#] > 10^-20 &], False, finishZeroQ[value]]]]];
$finishMemoryLimit = 12 10^9;
(* the resident size of the kernel process: MemoryInUse[] counts live
   expressions only and lagged the resident size by a factor 5 on CF385
   (15 GB resident at 3 GB in use), so the guard reads VmRSS on Linux *)
finishResidentBytes[] := Module[{status, rss},
  status = Quiet[Check[Import["/proc/self/status", "Text"], $Failed]];
  rss = If[StringQ[status], StringCases[status, "VmRSS:" ~~ Whitespace ~~ (d : DigitCharacter ..) ~~ " kB" :> 1024 ToExpression[d]], {}];
  If[rss === {}, MemoryInUse[], First[rss]]];
finishMemoryGuard[label_, extra_: <||>] := If[Max[finishResidentBytes[], MemoryInUse[]] > $finishMemoryLimit,
  finishFail["WordExpansionMemoryCap", Join[<|"Stage" -> label, "ResidentBytes" -> finishResidentBytes[], "MemoryInUse" -> MemoryInUse[], "MaxMemoryUsed" -> MaxMemoryUsed[], "MemoryLimit" -> $finishMemoryLimit|>, extra]]];

finishResultRoot[] := FileNameJoin[{finishRepositoryRoot[],
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];

(* the first existing candidate wins; every candidate is recorded *)
finishInputFile[candidates_List] := SelectFirst[candidates, FileExistsQ, Missing["NoInputFile", candidates]];

Options[FinishPhysicalTransport] = {
  "Directories" -> Automatic,
  "DifferentialEquationCheck" -> Automatic,   (* "Exact" | "Modular" *)
  "ExactCheckDimensionLimit" -> 24,
  "ModularPoints" -> 3, "ModularPrimeCount" -> 3, "Seed" -> 20260903,
  "MaximumWordPairs" -> 400000,
  "MemoryLimitBytes" -> 12 10^9,
  "EnumerationWallBudgetSeconds" -> 600, "MaximumVisitedNodes" -> 2000000,
  "MaximumTermsPerPair" -> 2000000,
  "OutputDirectory" -> None,
  "Verbose" -> False
};

finishReadInputs[family_String, directories_] := Module[
  {root = finishResultRoot[], d, files, form, transport, modeMap, endpoint},
  d = Join[<|
    "EpsilonForm" -> {FileNameJoin[{root, "FamilyEpsFormsCertified"}]},
    "ObservableTransport" -> {FileNameJoin[{root, "ObservableTransport_2026-09-03_round9"}],
      FileNameJoin[{root, "ObservableTransport_2026-09-01_codex", "families"}]},
    "BoundaryModes" -> {FileNameJoin[{root, "PhysicalBoundaryModes_2026-09-03_round9"}],
      FileNameJoin[{root, "PhysicalBoundaryModes"}]},
    "EndpointTransport" -> {FileNameJoin[{root, "PhysicalEndpointTransport_2026-09-03_round9"}],
      FileNameJoin[{root, "PhysicalEndpointTransport"}]}|>,
    If[AssociationQ[directories], Map[If[StringQ[#], {#}, #] &, directories], <||>]];
  files = <|
    "EpsilonForm" -> finishInputFile[FileNameJoin[{#, "family_epsform_" <> family <> ".wl"}] & /@ d["EpsilonForm"]],
    "ObservableTransport" -> finishInputFile[FileNameJoin[{#, "observable_transport_" <> family <> ".wl"}] & /@ d["ObservableTransport"]],
    "BoundaryModes" -> finishInputFile[FileNameJoin[{#, "boundary_mode_" <> family <> ".wl"}] & /@ d["BoundaryModes"]],
    "EndpointTransport" -> finishInputFile[FileNameJoin[{#, "physical_endpoint_transport_" <> family <> ".wl"}] & /@ d["EndpointTransport"]]|>;
  If[AnyTrue[Values[files], MissingQ], finishFail["FinishInputsMissing", <|"Files" -> files|>]];
  form = Get[files["EpsilonForm"]]; transport = Get[files["ObservableTransport"]];
  modeMap = Get[files["BoundaryModes"]]; endpoint = Get[files["EndpointTransport"]];
  If[! AssociationQ[form] || ! AssociationQ[transport] || ! AssociationQ[modeMap] || ! AssociationQ[endpoint],
    finishFail["FinishInputsUnreadable", <|"Files" -> files|>]];
  <|"Files" -> files, "EpsilonForm" -> form, "ObservableTransport" -> transport,
    "BoundaryModes" -> modeMap, "EndpointTransport" -> endpoint|>
];

(* A dlog kernel k(v) dv as a linear combination of base letters: simple
   poles {"GPLPole", c} (c may depend on the spectator variable) and
   root-free {"GPLFactor", q, k} letters for irreducible factors of higher
   degree; the residue multiplies the letter.  Returns {{coefficient,
   label}, ...} or a typed Missing. *)
finishKernelLetters[kernel_, variable_Symbol] := Module[
  {expression, terms, result = {}, numerator, denominator, degree, factorList,
   partial, numer},
  expression = Together[kernel];
  If[finishZeroQ[expression], Return[{}]];
  If[! FreeQ[expression, Sqrt[_] | Power[_, _Rational]], Return[Missing["AlgebraicKernelNotSupported", kernel]]];
  partial = Apart[expression, variable];
  terms = If[Head[partial] === Plus, List @@ partial, {partial}];
  Do[
    numerator = Numerator[Together[term]]; denominator = Denominator[Together[term]];
    degree = Exponent[denominator, variable];
    If[degree === 0,
      If[! finishZeroQ[term], Return[Missing["PolynomialKernelPart", term], Module], Continue[]]];
    If[Exponent[numerator, variable] >= degree, Return[Missing["ImproperKernelPart", term], Module]];
    factorList = Select[FactorList[denominator, Extension -> None], Exponent[#[[1]], variable] > 0 &];
    If[Length[factorList] =!= 1, Return[Missing["KernelPartNotPrimary", term], Module]];
    If[factorList[[1, 2]] =!= 1, Return[Missing["RepeatedPoleNotDLog", term], Module]];
    With[{q = factorList[[1, 1]], lead = Together[denominator/factorList[[1, 1]]]},
      If[Exponent[q, variable] === 1,
        With[{c = Together[-Coefficient[q, variable, 0]/Coefficient[q, variable, 1]]},
          AppendTo[result, {Together[numerator/(lead Coefficient[q, variable, 1])], {"GPLPole", c}}]],
        numer = Together[numerator/lead];
        Do[With[{b = Coefficient[numer, variable, k]},
            If[! finishZeroQ[b], AppendTo[result, {b, {"GPLFactor", q, k}}]]],
          {k, 0, Exponent[numer, variable]}]]],
    {term, terms}];
  result
];

(* the four legs of the path, outermost first: CurrentFirst (x-leg to the
   target at the target's second coordinate), CurrentSecond (y-leg at the
   first base), EndpointFirst, EndpointSecond (from the physical endpoint) *)
finishLegLetters[transport_, endpoint_] := Module[
  {path, firstVariable, secondVariable, firstBase, secondBase, sample, tangent,
   pathSymbol, firstKernels, secondKernels, segments, legs, tParameter},
  path = transport["Path"]; firstVariable = path["FirstVariable"]; secondVariable = path["SecondVariable"];
  firstBase = path["FirstBase"]; secondBase = path["SecondBase"]; sample = path["FirstTargetSample"];
  tangent = sample - firstBase;
  firstKernels = transport["FirstSegmentKernels"];
  pathSymbol = SelectFirst[Union[Cases[firstKernels, s_Symbol /; ! MemberQ[{firstVariable, secondVariable}, s] && Context[s] =!= "System`", Infinity]], True &, None];
  (* the first-segment kernels are in the path parameter t with
     firstVariable = firstBase + t tangent; k_x dx = k_t(t(x)) dt/dx dx *)
  tParameter = (firstVariable - firstBase)/tangent;
  firstKernels = If[pathSymbol === None, firstKernels,
    Together[(# /. pathSymbol -> tParameter)/tangent] & /@ firstKernels];
  secondKernels = transport["SecondSegmentKernels"];
  segments = endpoint["EndpointPath"]["Segments"];
  legs = <|
    "CurrentFirst" -> <|"Variable" -> firstVariable, "From" -> firstBase, "To" -> firstVariable,
      "FixedRules" -> {}, "Note" -> "the target's second coordinate is symbolic in the letters",
      "AlphabetIndices" -> transport["ExactOperatorAutomaton"]["FirstAlphabetIndices"],
      "Kernels" -> Association@Thread[transport["ExactOperatorAutomaton"]["FirstAlphabetIndices"] -> firstKernels]|>,
    "CurrentSecond" -> <|"Variable" -> secondVariable, "From" -> secondBase, "To" -> secondVariable,
      "FixedRules" -> {firstVariable -> firstBase},
      "AlphabetIndices" -> transport["ExactOperatorAutomaton"]["SecondAlphabetIndices"],
      "Kernels" -> Association@Thread[transport["ExactOperatorAutomaton"]["SecondAlphabetIndices"] -> secondKernels]|>,
    "EndpointFirst" -> With[{s = SelectFirst[segments, #["Role"] === "EndpointFirst" &]},
      <|"Variable" -> s["Variable"], "From" -> s["Base"], "To" -> s["Target"], "FixedRules" -> s["FixedRules"],
        "AlphabetIndices" -> s["AlphabetIndices"], "Kernels" -> s["DLogKernels"]|>],
    "EndpointSecond" -> With[{s = SelectFirst[segments, #["Role"] === "EndpointSecond" &]},
      <|"Variable" -> s["Variable"], "From" -> s["Base"], "To" -> s["Target"], "FixedRules" -> s["FixedRules"],
        "AlphabetIndices" -> s["AlphabetIndices"], "Kernels" -> s["DLogKernels"]|>]|>;
  If[Length[firstKernels] =!= Length[legs["CurrentFirst"]["AlphabetIndices"]] ||
      Length[secondKernels] =!= Length[legs["CurrentSecond"]["AlphabetIndices"]],
    finishFail["FinishLegAlphabetMismatch"]];
  (* every kernel as base letters *)
  legs = Map[Function[leg, Join[leg, <|"Letters" -> Association@KeyValueMap[
      #1 -> finishKernelLetters[#2, leg["Variable"]] &, leg["Kernels"]]|>]], legs];
  If[! FreeQ[Values[Lookup[Values[legs], "Letters"]], _Missing],
    finishFail["FinishKernelNotDLogLetter", <|"Legs" -> Map[Select[#["Letters"], MissingQ] &, legs]|>]];
  legs
];

(* every current word pair with a nonzero map, layer by layer in the total
   weight (breadth first over both legs): a node carries the pre-boundary
   state S1 = Initial . M_w1 and the state S2 = S1 . B . N_w2; the first leg
   is extended only while the second is empty; a zero state has only zero
   extensions (linear), which prunes exactly.  The work is bounded by a
   visited-node cap and a wall budget; on either the set complete through
   the last full layer is returned with CompleteThroughWeight recorded. *)
Options[finishEnumerateWords] = {"MaximumVisitedNodes" -> 2000000, "WallBudgetSeconds" -> Infinity};
finishEnumerateWords[automaton_, initial_, maximumWeight_Integer, cap_Integer, OptionsPattern[]] := Module[
  {firstAlphabet = automaton["FirstAlphabetIndices"], secondAlphabet = automaton["SecondAlphabetIndices"],
   firstMatrices = automaton["FirstOperatorMatrices"], boundary = automaton["FirstBoundaryOperator"],
   secondMatrices = automaton["SecondOperatorMatrices"], embedding = automaton["FinalBoundaryEmbedding"],
   layer, next, pairs = {}, visited = 0, capped = False, stopped = None, complete = -1, started = AbsoluteTime[],
   nodeCap = OptionValue["MaximumVisitedNodes"], budget = OptionValue["WallBudgetSeconds"], s1, s2, final},
  s1 = initial; s2 = s1 . boundary;
  layer = {{{}, {}, s1, s2}};
  Do[
    (* accept the nonzero pairs of this layer *)
    Do[final = node[[4]] . embedding;
      If[finishNonzeroMatrixQ[final], AppendTo[pairs, {node[[1]], node[[2]], final}];
        If[Length[pairs] > cap, capped = True]],
      {node, layer}];
    If[capped, stopped = "PairCap"; Break[]];
    complete = weight;
    If[weight === maximumWeight, Break[]];
    (* the next layer *)
    next = {};
    Do[
      visited++;
      If[Mod[visited, 500] === 0, finishMemoryGuard["word enumeration", <|"VisitedNodes" -> visited, "Weight" -> weight|>]];
      If[visited > nodeCap, stopped = "VisitedNodeCap"; Break[]];
      If[AbsoluteTime[] - started > budget, stopped = "WallBudget"; Break[]];
      If[node[[2]] === {},
        Do[s1 = node[[3]] . firstMatrices[[a]];
          If[finishNonzeroMatrixQ[s1], AppendTo[next, {Append[node[[1]], firstAlphabet[[a]]], {}, s1, s1 . boundary}]],
          {a, Length[firstAlphabet]}]];
      Do[s2 = node[[4]] . secondMatrices[[b]];
        If[finishNonzeroMatrixQ[s2], AppendTo[next, {node[[1]], Append[node[[2]], secondAlphabet[[b]]], node[[3]], s2}]],
        {b, Length[secondAlphabet]}],
      {node, layer}];
    If[stopped =!= None, Break[]];
    layer = next,
    {weight, 0, maximumWeight}];
  <|"Pairs" -> pairs, "Capped" -> stopped =!= None, "Stopped" -> stopped, "Count" -> Length[pairs],
    "CompleteThroughWeight" -> complete, "RequestedWeight" -> maximumWeight, "VisitedNodes" -> visited,
    "Seconds" -> AbsoluteTime[] - started|>
];

(* the graded endpoint composition of the adapter, batched; every term is
   {w1, w2, e1, e2, Map (rows x period coordinates)} *)
finishCompose[binding_, transport_, pairs_List, batch_Integer: 400] := Module[{terms = {}, result},
  Do[
    result = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[binding, transport, chunk];
    If[FailureQ[result] || Lookup[result, "Status", None] =!= "GradedPhysicalEndpointWordsBuilt",
      finishFail["FinishCompositionFailed", <|"Result" -> result, "Chunk" -> Take[chunk, UpTo[3]]|>]];
    terms = Join[terms, result["WordMaps"]],
    {chunk, Partition[pairs, UpTo[batch]]}];
  terms
];

(* the physical word pairs are the canonical ones whose map survives the
   T-Laurent functionals: a numeric prefilter at two random rational points
   (nonzero there proves nonzero) and an exact test only for pairs that
   vanish at both points *)
finishPhysicalPairs[canonicalPairs_List, tLaurent_List, variables_List, seed_Integer] := Module[
  {points, numeric, selected = {}, exact},
  BlockRandom[SeedRandom[seed + 11];
    points = Table[Thread[variables -> RandomInteger[{3, 10^6}, Length[variables]]/RandomInteger[{1, 10^3}, Length[variables]]], {2}]];
  numeric = Table[Together[tLaurent /. point], {point, points}];
  Do[With[{final = Last[pair]},
    If[AnyTrue[numeric, finishNonzeroMatrixQ[# . final] &],
      AppendTo[selected, pair],
      exact = Together[tLaurent . final];
      If[finishNonzeroMatrixQ[exact], AppendTo[selected, pair]]]],
    {pair, canonicalPairs}];
  selected
];

(* large families: the word pairs of the deliverable, enumerated on the
   physical functional specialized at two random rational points (numeric
   demanded-row matrices; a pair vanishing at both points is dropped and the
   points are recorded), never on the canonical identity *)
finishNumericEnumeration[automaton_, tLaurent_, variables_List, seed_Integer, maximumWeight_Integer, cap_Integer, options___] := Module[
  {points, numeric, joint},
  BlockRandom[SeedRandom[seed + 23];
    points = Table[Thread[variables -> RandomInteger[{3, 10^6}, Length[variables]]/RandomInteger[{1, 997}, Length[variables]]], {2}]];
  numeric = Table[Together[tLaurent /. point], {point, points}];
  joint = Join @@ numeric;
  Join[finishEnumerateWords[automaton, joint, maximumWeight, cap, options], <|"PruningPoints" -> points|>]
];

(* the structural differential-equation certificate (large families): every
   letter matrix of the automaton is exactly the residue of its letter
   lifted with the slot-order shift, and the connection equals the sum of
   the leg kernels times the residues at random points modulo fresh primes
   (x-leg at a generic point, y-leg on the line x = x0); with these the
   derivative of every stored word (its outermost letter's kernel times the
   shorter word) reproduces the connection acting on the sum, word by word *)
finishStructuralDifferentialCertificate[transport_, form_, legs_, slots_List, variables_List, points_List, primes_List] := Module[
  {automaton = transport["ExactOperatorAutomaton"], eps = transport["Regulator"], x, y, x0, firstIndices, secondIndices,
   residues, letters, ax, ay, liftChecks = {}, liftFailures = {}, identityChecks = 0, identityMismatches = 0, failures = {},
   slotIndex = finishSlotIndex[slots], compiledAx, compiledAy, compiledKernelsX, compiledKernelsY, residueMod, value, kernelValues, predicted, actual},
  x = legs["CurrentFirst"]["Variable"]; y = legs["CurrentSecond"]["Variable"]; x0 = legs["CurrentFirst"]["From"];
  firstIndices = automaton["FirstAlphabetIndices"]; secondIndices = automaton["SecondAlphabetIndices"];
  residues = Lookup[transport, "DLogResidues", Lookup[transport, "FirstSegmentKernelMatrices", Missing[]]];
  letters = Lookup[transport, "DLogLetters", Missing[]];
  If[! ListQ[residues] || ! ListQ[letters] || Length[residues] =!= Length[letters],
    Return[<|"Status" -> "DifferentialEquationStructuralInputsMissing"|>]];
  (* (a) letter matrices are the lifted residues: M_a[slot (p+1, i), slot (p, j)] = R_a[i, j] *)
  Do[With[{m = Normal[automaton["FirstOperatorMatrices"][[a]]], r = residues[[firstIndices[[a]]]]},
    liftChecks = Append[liftChecks, AllTrue[Flatten[Table[
        With[{row = slots[[i]], column = slots[[j]]},
          m[[i, j]] === If[row[[1]] === column[[1]] + 1, r[[row[[2]], column[[2]]]], 0]],
        {i, Length[slots]}, {j, Length[slots]}]], TrueQ]]],
    {a, Length[firstIndices]}];
  If[! AllTrue[liftChecks, TrueQ], liftFailures = Position[liftChecks, False]];
  (* (b) the dlog identities at random points modulo primes *)
  ax = form["EpsFormX"]/eps; ay = form["EpsFormY"]/eps;
  compiledAx = observableTransportFFCompileMatrix[ax, variables]; compiledAy = observableTransportFFCompileMatrix[ay /. x -> x0, variables];
  compiledKernelsX = observableTransportFFCompileExpressions[Table[D[letters[[i]], x]/letters[[i]], {i, Length[letters]}], variables];
  compiledKernelsY = observableTransportFFCompileExpressions[Table[(D[letters[[i]], y]/letters[[i]]) /. x -> x0, {i, Length[letters]}], variables];
  If[MemberQ[{compiledAx, compiledAy, compiledKernelsX, compiledKernelsY}, $Failed],
    Return[<|"Status" -> "DifferentialEquationStructuralCompilationFailed"|>]];
  Do[
    residueMod = Map[Mod[Numerator[#] PowerMod[Denominator[#], -1, prime], prime] &, residues, {3}];
    Do[
      Do[
        actual = observableTransportFFMatrixValue[If[k === 1, compiledAx, compiledAy], point, prime];
        kernelValues = observableTransportFFEvaluateExpressions[If[k === 1, compiledKernelsX, compiledKernelsY], point, prime];
        If[actual === $Failed || MemberQ[kernelValues, $Failed], Continue[]];
        predicted = Mod[Total[MapThread[#1 #2 &, {kernelValues, residueMod}]], prime];
        identityChecks++;
        If[Mod[predicted - actual, prime] =!= ConstantArray[0, Dimensions[actual]],
          identityMismatches++; AppendTo[failures, <|"Prime" -> prime, "Point" -> point, "Variable" -> If[k === 1, x, y]|>]],
        {k, 2}],
      {point, points}],
    {prime, primes}];
  <|"Status" -> If[liftFailures === {} && identityMismatches === 0 && identityChecks > 0, "DifferentialEquationVerified", "DifferentialEquationFailed"],
    "Method" -> "Structural", "LetterMatricesAreLiftedResidues" -> liftFailures === {}, "LiftFailures" -> liftFailures,
    "DLogIdentityChecks" -> identityChecks, "DLogIdentityMismatches" -> identityMismatches, "Failures" -> Take[failures, UpTo[10]],
    "Variables" -> variables, "Points" -> points, "Primes" -> primes,
    "Flatness" -> Lookup[form, "Flatness", Missing[]],
    "Argument" -> "every stored formal Chen iterated integral I[a,rest] satisfies d I[a,rest] = kernel_a I[rest]; the coefficients are products of the letter residues (lifted letter matrices, checked exactly) and the connection is Sum_a kernel_a R_a (checked at random points modulo fresh primes on the x-leg at a generic point and on the y-leg along x = x0); with the certified flatness the explicit sum satisfies the connection everywhere"|>
];

finishPeriodSymbol[family_String, index_Integer] := Symbol["FeynFacetPeriod`" <> family <> "`P" <> ToString[index]];

(* a composite word (letter indices) over one leg -> {{coefficient, base word}, ...} *)
finishExpandCompositeWord[indices_List, leg_] := Module[{expanded = {{1, {}}}},
  Do[With[{choices = leg["Letters"][index]},
    expanded = Flatten[Table[{left[[1]] right[[1]], Append[left[[2]], right[[2]]]}, {left, expanded}, {right, choices}], 1]],
    {index, indices}];
  expanded
];

SetAttributes[finishInertWord, HoldAll];
finishInertWord[letters_, variable_, from_, to_, prescription_] :=
  FormalChenIteratedIntegral @@
    {letters, {variable, from, to}, None, prescription};

(* one composed term -> list of {coefficient (rational function), period
   index list -> handled by caller, word product}; words with an empty
   letter list are the constant 1 *)
finishWord[legs_, legName_, indices_List, prescription_] := If[indices === {}, {{1, 1}},
  With[{leg = legs[legName]},
    ({#[[1]], finishInertWord @@ {#[[2]], leg["Variable"], leg["From"], leg["To"], prescription}} &) /@
      finishExpandCompositeWord[indices, leg]]];

finishTerms[composedTerms_List, legs_, periodSymbols_List, rowCount_Integer, prescriptions_] := Module[
  {sown, words, rules},
  sown = Reap[Do[
    words = Flatten[Outer[Function[{a, b, c, d}, {a[[1]] b[[1]] c[[1]] d[[1]], a[[2]] b[[2]] c[[2]] d[[2]]}],
      finishWord[legs, "CurrentFirst", term["CurrentFirstWord"], prescriptions["Current"]],
      finishWord[legs, "CurrentSecond", term["CurrentSecondWord"], prescriptions["Current"]],
      finishWord[legs, "EndpointFirst", term["EndpointFirstWord"], prescriptions["Endpoint"]],
      finishWord[legs, "EndpointSecond", term["EndpointSecondWord"], prescriptions["Endpoint"]], 1], 3];
    rules = Most[ArrayRules[SparseArray[term["Map"]]]];
    Do[With[{row = rule[[1, 1]], j = rule[[1, 2]], value = rule[[2]]},
        If[! finishZeroQ[value],
          Do[Sow[{w[[2]], periodSymbols[[j]]} -> value w[[1]], row], {w, words}]]],
      {rule, rules}],
    {term, composedTerms}], Range[rowCount]][[2]];
  (* one merged association per row: {word, period} -> coefficient *)
  Table[If[sown[[row]] === {}, <||>,
    Select[Together /@ Merge[sown[[row, 1]], Total], ! finishZeroQ[#] &]], {row, rowCount}]
];

(* an expression Sum coefficient * P * W from a merged table *)
finishCollect[table_Association] := <|"Table" -> table,
  "Expression" -> Total[KeyValueMap[Function[{key, coefficient}, coefficient key[[2]] key[[1]]], table]]|>;

(* the demanded map equals the T-Laurent functional: for every demanded
   pair (n, r) and ambient slot (p, k), the entry is the coefficient of
   eps^(n-p) in T[[r, k]] -- checked exactly, or at random points where the
   Laurent expansion of the numerically specialized T is cheap *)
finishDemandFunctionalCertificate[tLaurent_, tt_, eps_, slots_List, pairs_List, variables_List, method_, points_List, primes_List] := Module[
  {mismatches = 0, checks = 0, failures = {}, entry, expected, difference, cache = <||>, value, pointRules},
  Which[
    method === "Exact",
      Do[expected = Together[SeriesCoefficient[tt[[pairs[[i, 2]], slots[[s, 2]]]], {eps, 0, pairs[[i, 1]] - slots[[s, 1]]}]];
        checks++;
        If[! finishZeroQ[Together[tLaurent[[i, s]] - expected]], mismatches++; AppendTo[failures, {pairs[[i]], slots[[s]]}]],
        {i, Length[pairs]}, {s, Length[slots]}],
    True,
      Do[pointRules = Thread[variables -> point];
        Do[value = Quiet[Check[SeriesCoefficient[tt[[pairs[[i, 2]], slots[[s, 2]]]] /. pointRules, {eps, 0, pairs[[i, 1]] - slots[[s, 1]]}], $Failed]];
          entry = Quiet[Check[tLaurent[[i, s]] /. pointRules, $Failed]];
          checks++;
          If[value === $Failed || entry === $Failed || ! finishZeroQ[Together[value - entry]], mismatches++; AppendTo[failures, {pairs[[i]], slots[[s]], point}]],
          {i, Length[pairs]}, {s, Length[slots]}],
        {point, points}]];
  <|"Status" -> If[mismatches === 0, "DemandMapIsTLaurentFunctional", "DemandMapNotTLaurentFunctional"],
    "Method" -> method, "Checks" -> checks, "Mismatches" -> mismatches, "Failures" -> Take[failures, UpTo[10]], "Points" -> points|>
];

(* T's Laurent coefficients as functionals over the ambient slots *)
finishTLaurent[form_, eps_, slots_List, pairs_List] := Module[{tt = form["TTotal"], cache = <||>, coefficient},
  coefficient[r_, k_, order_] := Lookup[cache, Key[{r, k, order}],
    cache[{r, k, order}] = Together[SeriesCoefficient[tt[[r, k]], {eps, 0, order}]]];
  Table[Table[coefficient[pair[[2]], slot[[2]], pair[[1]] - slot[[1]]], {slot, slots}], {pair, pairs}]
];

finishSlotIndex[slots_List] := AssociationThread[slots -> Range[Length[slots]]];

(* the transport with the canonical unit functionals as outputs (one row per ambient slot) *)
finishCanonicalTransport[transport_, needed_List] := With[{slots = transport["BoundaryAmbientSlots"], automaton = transport["ExactOperatorAutomaton"]},
  Join[transport, <|"PhysicalDemandPairs" -> needed, "PhysicalRows" -> needed,
    "ExactOperatorAutomaton" -> Join[automaton, <|"InitialDemandMap" ->
      IdentityMatrix[Length[slots]][[Flatten[Position[slots, Alternatives @@ needed]]]]|>]|>]];

(* evaluation of a rational-function identity: exact (Together) or at a point modulo a prime *)
finishIdentityValue[expression_, "Exact", ___] := Together[expression];
finishIdentityValue[expression_, "Modular", variables_List, point_List, prime_Integer] := Module[{compiled},
  compiled = observableTransportFFCompile[Together[expression], variables];
  If[compiled === $Failed, $Failed, observableTransportFFValue[compiled, point, prime]]
];

(* derivative terms of Sum c P W with respect to the variable of the
   OUTERMOST leg present: the leg's outermost letter's kernel times the
   shorter word; the coefficient's own derivative for a coefficient
   depending on the variables. Returns the list {{coefficient, P, word}} *)
finishDerivativeTerms[table_Association, variable_Symbol, legVariablePosition_] := Module[{sown},
  sown = Reap[KeyValueMap[Function[{key, coefficient},
    With[{word = key[[1]], period = key[[2]]},
      If[! finishZeroQ[D[coefficient, variable]], Sow[{word, period} -> D[coefficient, variable]]];
      With[{pieces = If[Head[word] === Times, List @@ word, {word}]},
        Do[If[MatchQ[piece,
            FormalChenIteratedIntegral[_List, {variable, _, variable}, ___]],
            With[{letters = piece[[1]], rest = DeleteCases[pieces, piece, 1, 1]},
              If[letters =!= {},
                Sow[{If[Length[letters] === 1, Times @@ rest,
                    Times @@ Append[rest, finishInertWord @@ {Rest[letters], variable, piece[[2, 2]], variable, piece[[4]]}]], period} ->
                  coefficient IteratedIntegralKernel[First[letters], variable]]]]],
          {piece, pieces}]]]], table]][[2]];
  If[sown === {}, <||>, Merge[sown[[1]], Total]]
];

Options[finishDifferentialCertificate] = {"Method" -> "Exact", "Variables" -> {}, "Points" -> {}, "Primes" -> {}};

(* the DE on the canonical slot expansions: for every slot (p, k) present,
   d_x F_k^(p) = Sum_l A_x[k,l] F_l^(p-1) at the generic point and
   d_y F_k^(p) = Sum_l A_y[k,l] F_l^(p-1) on the line x = x0; absent slots
   below the certified valuation are zero *)
finishDifferentialCertificate[canonicalTables_Association, slots_List, form_, transport_, legs_, OptionsPattern[]] := Module[
  {method = OptionValue["Method"], variables = OptionValue["Variables"], points = OptionValue["Points"], primes = OptionValue["Primes"],
   eps = transport["Regulator"], x = legs["CurrentFirst"]["Variable"], y = legs["CurrentSecond"]["Variable"], x0 = legs["CurrentFirst"]["From"],
   ax, ay, slotIndex = finishSlotIndex[slots], checks = {}, failures = {}, lhs, rhs, keys, difference, values, valuations, lowerQ, entryValue, identities = 0, mismatches = 0},
  ax = form["EpsFormX"]/eps; ay = form["EpsFormY"]/eps;
  If[! FreeQ[Together[ax[[1, 1]]], eps] || ! FreeQ[Together[Last[Flatten[ax]]], eps], finishFail["FinishEpsilonFormNotLinear"]];
  (* a slot below the certified epsilon valuation of its row is exactly zero:
     the valuation certificate carries block lower bounds (BlockLower over the
     form's Ranges) or row lower bounds (RowLower) *)
  valuations = Lookup[transport, "TransportEpsilonValuations", <||>];
  lowerQ[slot_] := Module[{row = Lookup[valuations, "RowLower", None], block = Lookup[valuations, "BlockLower", None],
      ranges = Lookup[form, "Ranges", None], position},
    Which[
      ListQ[row] && slot[[2]] <= Length[row], slot[[1]] < row[[slot[[2]]]],
      ListQ[block] && ListQ[ranges],
        position = FirstPosition[ranges, r_List /; MemberQ[r, slot[[2]]], Missing[], {1}];
        ! MissingQ[position] && slot[[1]] < block[[First[position]]],
      True, False]];
  entryValue[expr_] := Switch[method,
    "Exact", finishIdentityValue[expr, "Exact"],
    "Modular", Table[finishIdentityValue[expr, "Modular", variables, point, prime], {prime, primes}, {point, points}]];
  Do[With[{p = slot[[1]], k = slot[[2]]},
    (* x-equation at the generic point *)
    lhs = finishDerivativeTerms[canonicalTables[slot], x, 1];
    rhs = Merge[Flatten[Table[With[{lower = {p - 1, l}},
        If[KeyExistsQ[canonicalTables, lower],
          If[finishCheapZeroQ[ax[[k, l]], variables], {}, KeyValueMap[#1 -> ax[[k, l]] #2 &, canonicalTables[lower]]],
          If[lowerQ[lower] || finishCheapZeroQ[ax[[k, l]], variables], {}, {"MissingSlot" -> lower}]]],
      {l, Length[ax]}], 1], Total];
    If[KeyExistsQ[rhs, "MissingSlot"], AppendTo[failures, <|"Slot" -> slot, "Reason" -> "SlotMissingNotBelowValuation",
        "Missing" -> Table[If[! KeyExistsQ[canonicalTables, {p - 1, l}] && ! lowerQ[{p - 1, l}] && ! finishCheapZeroQ[ax[[k, l]], variables], {p - 1, l}, Nothing], {l, Length[ax]}]|>]; Continue[]];
    Do[
      difference = Lookup[lhs, Key[key], 0] - Lookup[rhs, Key[key], 0];
      values = entryValue[difference]; identities++;
      If[! (values === 0 || (ListQ[values] && AllTrue[Flatten[values], # === 0 &])),
        mismatches++; AppendTo[failures, <|"Slot" -> slot, "Equation" -> x, "Key" -> key, "Value" -> Short[values]|>]],
      {key, Union[Keys[lhs], Keys[rhs]]}];
    (* y-equation on the line x = x0: only words with an empty x-leg survive *)
    lhs = finishDerivativeTerms[KeySelect[canonicalTables[slot],
        FreeQ[#[[1]], FormalChenIteratedIntegral[_, {x, _, x}, ___]] &], y, 2];
    lhs = Map[Together[# /. x -> x0] &, lhs];
    rhs = Merge[Flatten[Table[With[{lower = {p - 1, l}},
        If[KeyExistsQ[canonicalTables, lower] && ! finishCheapZeroQ[ay[[k, l]] /. x -> x0, {y}],
          KeyValueMap[#1 -> Together[(ay[[k, l]] /. x -> x0) (#2 /. x -> x0)] &,
            KeySelect[canonicalTables[lower],
              FreeQ[#[[1]], FormalChenIteratedIntegral[_, {x, _, x}, ___]] &]],
          {}]],
      {l, Length[ay]}], 1], Total];
    Do[
      difference = Lookup[lhs, Key[key], 0] - Lookup[rhs, Key[key], 0];
      values = entryValue[difference /. x -> x0]; identities++;
      If[! (values === 0 || (ListQ[values] && AllTrue[Flatten[values], # === 0 &])),
        mismatches++; AppendTo[failures, <|"Slot" -> slot, "Equation" -> y, "Line" -> (x -> x0), "Key" -> key, "Value" -> Short[values]|>]],
      {key, Union[Keys[lhs], Keys[rhs]]}]],
    {slot, slots}];
  <|"Status" -> If[failures === {}, "DifferentialEquationVerified", "DifferentialEquationFailed"],
    "Method" -> method, "Identities" -> identities, "Mismatches" -> mismatches,
    "Failures" -> Take[failures, UpTo[20]], "Variables" -> variables, "Points" -> points, "Primes" -> primes,
    "Flatness" -> Lookup[form, "Flatness", Missing[]], "FlatnessRoute" -> Lookup[form, "FlatnessRoute", Missing[]],
    "Argument" -> "x-equation at a generic point, y-equation on the interior-base line x = x0; with the certified flatness this determines the y-equation everywhere"|>
];

(* boundary matching: the empty-word coefficient of every canonical slot
   equals the mode vectors' epsilon coefficients *)
finishBoundaryCertificate[canonicalTables_Association, slots_List, modeMap_, coordinates_List, periodSymbols_List, eps_] := Module[
  {modes = modeMap["Modes"], checks = 0, mismatches = {}, expected, actual, mode},
  Do[With[{p = slot[[1]], k = slot[[2]]},
    Do[With[{coordinate = coordinates[[j]]},
      mode = SelectFirst[modes, Lookup[#, "PeriodID", None] === coordinate["PeriodID"] &, None];
      If[mode === None, AppendTo[mismatches, <|"Coordinate" -> coordinate, "Reason" -> "ModeMissing"|>]; Continue[]];
      expected = Together[SeriesCoefficient[mode["CanonicalMode"][[k]], {eps, 0, p - coordinate["EpsilonOrder"]}]];
      actual = Lookup[canonicalTables[slot], Key[{1, periodSymbols[[j]]}], 0];
      checks++;
      If[! finishZeroQ[Together[expected - actual]],
        AppendTo[mismatches, <|"Slot" -> slot, "Coordinate" -> KeyTake[coordinate, {"PeriodID", "EpsilonOrder"}], "Expected" -> expected, "Actual" -> actual|>]]],
      {j, Length[coordinates]}]],
    {slot, slots}];
  <|"Status" -> If[mismatches === {}, "BoundaryMatchingVerified", "BoundaryMatchingFailed"],
    "Checks" -> checks, "Mismatches" -> Take[mismatches, UpTo[20]],
    "Argument" -> "the empty word carries the boundary value; every nonempty word vanishes when the path collapses to the physical endpoint (tangential prescription on the endpoint legs)"|>
];

finishFingerprint[value_] := Hash[value /. {(k_String -> _) /; StringContainsQ[k, "Seconds" | "Timing" | "Wall"] :> Nothing}, "SHA256"];

finishAllowedSymbolQ[symbol_Symbol, variables_List, periodSymbols_List] :=
  MemberQ[variables, symbol] || MemberQ[periodSymbols, symbol] ||
  MemberQ[{FormalChenIteratedIntegral, AlgebraicMarkedPoint,
      IteratedIntegralKernel, Plus, Times, Power, List, Rational, Integer,
      None, True, False, Association, Rule, Complex}, symbol];

finishPurityCheck[expressions_List, variables_List, periodSymbols_List] := Module[{symbols, offending},
  symbols = DeleteDuplicates[Cases[expressions, s_Symbol :> s, {0, Infinity}, Heads -> True]];
  offending = Select[symbols, ! finishAllowedSymbolQ[#, variables, periodSymbols] &];
  offending = Join[offending, Select[symbols, StringContainsQ[SymbolName[#], "$"] || StringContainsQ[Context[#], "Private`"] &]];
  <|"Status" -> If[offending === {}, "ExpressionsPure", "ExpressionsImpure"], "Offending" -> DeleteDuplicates[offending],
    "AllowedHeads" -> {FormalChenIteratedIntegral, AlgebraicMarkedPoint,
      IteratedIntegralKernel}, "Variables" -> variables|>
];

(* the period table: definition from the mode map, status from the census
   certificates and the transfer results, the ledger id *)
finishPeriodTable[family_String, coordinates_List, periodSymbols_List, modeMap_] := Module[
  {root = finishResultRoot[], certificateDirectory, transfers, modes = modeMap["Modes"], edge = modeMap["PhysicalEdgePoint"],
   certificate, transfer, mode, id, ledgerID, status, value, reference, entries, census, realizedQ},
  certificateDirectory = FileNameJoin[{root, "BoundaryPeriods", "Certificates"}];
  transfers = Quiet[Check[Get[FileNameJoin[{certificateDirectory, "TransferResults.wl"}]], {}]];
  If[! ListQ[transfers], transfers = {}];
  (* a census certificate applies to a family only if the census lists the
     family among the period's realizations; a synthetic family or a
     coincident numeric id never inherits one *)
  census = Quiet[Check[Lookup[Get[FileNameJoin[{certificateDirectory, "NullityPeriods.wl"}]], "Periods", {}], {}]];
  If[! ListQ[census], census = {}];
  realizedQ[ledger_] := AnyTrue[census, AssociationQ[#] && Lookup[#, "PeriodID", None] === ledger &&
    MemberQ[Lookup[#, "Families", {}], family] &];
  entries = Table[
    id = coordinates[[j]]["PeriodID"];
    ledgerID = If[MatchQ[id, {_String, _Integer, ___}], id[[2]], id];
    mode = SelectFirst[modes, Lookup[#, "PeriodID", None] === id &, <||>];
    certificate = If[IntegerQ[ledgerID] && realizedQ[ledgerID],
      With[{file = FileNameJoin[{certificateDirectory, "period_" <> IntegerString[ledgerID, 10, 2] <> ".wl"}]},
        If[FileExistsQ[file], Quiet[Check[Get[file], <||>]], <||>]], <||>];
    transfer = SelectFirst[transfers, AssociationQ[#] && Lookup[#, "PID", None] === ledgerID && Lookup[#, "Family", None] === family &, <||>];
    {status, value, reference} = Which[
      MemberQ[Lookup[modeMap, "KnownZeroLedgerPeriodIDs", {}], ledgerID] ||
        (Lookup[certificate, "Status", None] === "Exact" && Lookup[certificate, "ExactCoefficient", None] === 0),
        {"KnownZero", 0, Lookup[certificate, "ProofRecord", "BoundaryPeriods/Proofs"]},
      Lookup[certificate, "Status", None] === "Exact",
        {"Exact", Lookup[certificate, "ExactCoefficient", Missing[]], Lookup[certificate, "ProofRecord", Missing[]]},
      Lookup[transfer, "Status", None] === "Exact",
        {"Transferred", Missing["TransferValue"], <|"TransferID" -> ledgerID, "Record" -> "BoundaryPeriods/Certificates/TransferResults.wl", "Matches" -> Lookup[transfer, "Matches", {}]|>},
      True, {"Unevaluated", Missing["NotEvaluated"], Missing[]}];
    <|"Symbol" -> periodSymbols[[j]], "PeriodID" -> id, "RealizationKey" -> coordinates[[j]]["RealizationKey"],
      "EpsilonOrder" -> coordinates[[j]]["EpsilonOrder"], "LedgerID" -> ledgerID,
      "Definition" -> <|"Family" -> family, "Stratum" -> Lookup[edge, "Stratum", Missing[]],
        "PhysicalEdgePoint" -> KeyTake[edge, {"Variable", "Endpoint", "LocalDirection", "FixedRules", "LeadingCoefficient"}],
        "Chart" -> Lookup[modeMap, "Chart", Missing[]],
        "FrobeniusMode" -> KeyTake[mode, {"CanonicalRows", "LocalEigenvalue", "GeneralizedLevel", "IntegerValuation", "PeriodClass", "NormalizationPhysicalRow"}],
        "Meaning" -> "the coefficient of epsilon^EpsilonOrder of the boundary datum multiplying this Frobenius mode of the canonical vector at the physical edge point"|>,
      "Status" -> status, "Value" -> value, "Reference" -> reference,
      "DegenerateEigenspace" -> Lookup[coordinates[[j]], "DegenerateEigenspace", None]|>,
    {j, Length[coordinates]}];
  entries
];

finishRelations[table_List] := Module[{relations = {}, groups, unknowns},
  Do[If[MemberQ[{"KnownZero", "Exact"}, entry["Status"]] && ! MissingQ[entry["Value"]],
      AppendTo[relations, <|"Type" -> entry["Status"], "Relation" -> (entry["Symbol"] == entry["Value"]), "Reference" -> entry["Reference"]|>]],
    {entry, table}];
  groups = GroupBy[Select[table, AssociationQ[#["DegenerateEigenspace"]] &],
    ({#["DegenerateEigenspace"]["ParentPeriodID"], #["EpsilonOrder"]} &)];
  KeyValueMap[Function[{key, members},
    AppendTo[relations, <|"Type" -> "DegenerateEigenspace", "ParentPeriodID" -> key[[1]], "EpsilonOrder" -> key[[2]],
      "Symbols" -> Lookup[members, "Symbol"], "EigenspaceDimension" -> members[[1]]["DegenerateEigenspace"]["EigenspaceDimension"],
      "Relation" -> "one undetermined rational relation along the stratum among these symbols (Stage-3 datum); the parent period counts once"|>]], groups];
  unknowns = Lookup[Select[table, #["Status"] === "Unevaluated" &], "Symbol"];
  <|"Relations" -> relations, "UnevaluatedSymbols" -> unknowns,
    "IndependentUnknownCount" -> Length[unknowns] - Total[Cases[relations, r_ /; r["Type"] === "DegenerateEigenspace" :> r["EigenspaceDimension"] - 1]],
    "Note" -> "the count subtracts one unknown per degenerate-eigenspace relation and epsilon order; Transferred periods stay listed until their transfer value is applied"|>
];

FinishPhysicalTransport[family_String, OptionsPattern[]] := Catch@Module[
  {started = AbsoluteTime[], timings = <||>, stage, verbose = TrueQ[OptionValue["Verbose"]],
   inputs, form, transport, modeMap, endpoint, variables, eps, demanded, automaton, legs, edge, prescriptions,
   physicalCoordinates, canonicalCoordinates, coordinateKeys, periodSymbols, symbolOf, physicalSymbols, canonicalSymbols,
   enumeration, physicalTerms, physicalByRow, physicalTables, expressions,
   slots, canonicalTransport, canonicalBinding, canonicalEnumeration, canonicalTerms, canonicalByRow, canonicalTables,
   method, points = {}, primes = {}, deCertificate, boundaryCertificate, tie, tieFailures = {}, tLaurent, difference, values, baseRules,
   coordinatesAll, table, relations, purity, fingerprints, reasons = {}, record, dimension, seed = OptionValue["Seed"], knownZeroData,
   feedingSlots, lowerSlots, neededSlots, weightBound, ax, ay, functionalCertificate,
   maximumPairs = OptionValue["MaximumWordPairs"], cap = OptionValue["MaximumTermsPerPair"], directory = OptionValue["OutputDirectory"]},
  $finishMemoryLimit = OptionValue["MemoryLimitBytes"];
  stage[label_] := (timings[label] = <|"Seconds" -> Round[AbsoluteTime[] - started, 0.01], "ResidentBytes" -> finishResidentBytes[], "MemoryInUse" -> MemoryInUse[], "MaxMemoryUsed" -> MaxMemoryUsed[]|>;
    If[verbose, Print["[finish ", family, " ", timings[label]["Seconds"], " s, ", Round[finishResidentBytes[]/10^9, 0.01], " GB resident, ", Round[MemoryInUse[]/10^9, 0.01], " GB in use, peak ", Round[MaxMemoryUsed[]/10^9, 0.01], " GB] ", label]];
    finishMemoryGuard[label]);
  inputs = finishReadInputs[family, OptionValue["Directories"]];
  form = inputs["EpsilonForm"]; transport = inputs["ObservableTransport"]; modeMap = inputs["BoundaryModes"]; endpoint = inputs["EndpointTransport"];
  stage["inputs read"];
  If[! TrueQ[AcceptedObservableTransportQ[transport]], finishFail["FinishObservableTransportNotAccepted", <|"Status" -> Lookup[transport, "Status", None]|>]];
  If[Lookup[transport, "WordRepresentation", None] =!= "OperatorAutomaton", finishFail["FinishWordRepresentationNotSupported", <|"WordRepresentation" -> Lookup[transport, "WordRepresentation", None]|>]];
  If[Lookup[modeMap, "Status", None] =!= "BoundaryModeMapBuilt", finishFail["FinishBoundaryModeMapIncomplete", <|"Status" -> Lookup[modeMap, "Status", None]|>]];
  If[Lookup[endpoint, "Status", None] =!= "GradedPhysicalEndpointTransportBuilt" || Lookup[endpoint, "Family", None] =!= family,
    finishFail["FinishEndpointRecordInvalid", <|"Status" -> Lookup[endpoint, "Status", None]|>]];
  variables = transport["Variables"]; eps = transport["Regulator"]; demanded = transport["PhysicalDemandPairs"];
  automaton = transport["ExactOperatorAutomaton"]; dimension = Length[form["TTotal"]];
  legs = finishLegLetters[transport, endpoint];
  edge = Lookup[modeMap, "PhysicalEdgePoint", <||>];
  prescriptions = <|
    "Current" -> <|"Type" -> "RegularBase", "BasePoint" -> Thread[variables -> {transport["Path"]["FirstBase"], transport["Path"]["SecondBase"]}]|>,
    "Endpoint" -> <|"Type" -> "TangentialRegularized", "Stratum" -> Lookup[edge, "Stratum", Missing[]],
      "Variable" -> Lookup[edge, "Variable", Missing[]], "Endpoint" -> Lookup[edge, "Endpoint", Missing[]],
      "LocalDirection" -> Lookup[edge, "LocalDirection", Missing[]], "LeadingCoefficient" -> Lookup[edge, "LeadingCoefficient", Missing[]],
      "FixedRules" -> Lookup[edge, "FixedRules", {}], "Chart" -> Lookup[modeMap, "Chart", Missing[]],
      "Prescription" -> Lookup[endpoint["EndpointPath"], "BoundaryPrescription", Missing[]]|>|>;
  stage["legs and letters"];
  slots = transport["BoundaryAmbientSlots"];
  (* known-zero periods are passed as the endpoint mission passes them *)
  knownZeroData = Association@DeleteCases[Map[Function[mode, With[{id = Lookup[mode, "PeriodID", Missing[]]},
      If[MissingQ[id] || ! MemberQ[Lookup[modeMap, "KnownZeroLedgerPeriodIDs", {}],
          If[MatchQ[id, {_String, _Integer}] && First[id] === family, Last[id], id]],
        Nothing, id -> <|"Status" -> "KnownZero"|>]]], modeMap["Modes"]], Nothing];
  (* one named period basis over the union of both bindings' coordinates *)
  physicalCoordinates = endpoint["PeriodCoordinates"];
  symbolOf[coordinate_] := periodSymbols[[First@FirstPosition[coordinateKeys, {coordinate["PeriodID"], coordinate["EpsilonOrder"]}]]];
  (* canonical slots: only those that feed a demanded output (a nonzero
     T-Laurent functional) and their DE-lower slots; a word of weight w
     reaches slot (p, k) only from boundary orders p - w >= the lowest
     ambient order, which bounds the enumeration by the slot orders *)
  (* the automaton's InitialDemandMap IS the T-Laurent functional over the
     ambient slots (slot (p, k) -> coefficient of eps^(n-p) in T[[r, k]]);
     it is taken as is and that identity is certified below (exactly for a
     small family, at random points modulo fresh primes otherwise) instead
     of re-expanding T symbolically, which does not scale *)
  tLaurent = Normal[automaton["InitialDemandMap"]];
  If[Dimensions[tLaurent] =!= {Length[demanded], Length[slots]}, finishFail["FinishDemandMapShapeInvalid", <|"Dimensions" -> Dimensions[tLaurent]|>]];
  feedingSlots = Select[slots, With[{s = First@FirstPosition[slots, #]}, AnyTrue[tLaurent[[All, s]], ! finishCheapZeroQ[#, variables] &]] &];
  ax = form["EpsFormX"]/eps; ay = form["EpsFormY"]/eps;
  lowerSlots = DeleteDuplicates@Flatten[Table[With[{p = slot[[1]], k = slot[[2]]},
      Table[If[MemberQ[slots, {p - 1, l}] && ! (finishCheapZeroQ[ax[[k, l]], variables] && finishCheapZeroQ[ay[[k, l]], variables]), {p - 1, l}, Nothing], {l, Length[ax]}]],
    {slot, feedingSlots}], 1];
  neededSlots = Union[feedingSlots, lowerSlots];
  weightBound = Min[automaton["RequestedMaximumWeight"], Max[neededSlots[[All, 1]]] - Min[slots[[All, 1]]]];
  stage["needed canonical slots: " <> ToString[Length[feedingSlots]] <> " feeding + " <> ToString[Length[lowerSlots]] <> " lower of " <> ToString[Length[slots]] <> "; weight bound " <> ToString[weightBound]];
  canonicalTransport = finishCanonicalTransport[transport, neededSlots];
  canonicalBinding = FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[canonicalTransport, modeMap, knownZeroData];
  If[FailureQ[canonicalBinding] || Lookup[canonicalBinding, "Status", None] =!= "GradedPhysicalEndpointTransportBuilt",
    finishFail["FinishCanonicalEndpointBindingFailed", <|"Result" -> canonicalBinding|>]];
  canonicalCoordinates = canonicalBinding["PeriodCoordinates"];
  coordinatesAll = DeleteDuplicatesBy[Join[physicalCoordinates, canonicalCoordinates], {#["PeriodID"], #["EpsilonOrder"]} &];
  coordinateKeys = ({#["PeriodID"], #["EpsilonOrder"]} &) /@ coordinatesAll;
  periodSymbols = Table[finishPeriodSymbol[family, j], {j, Length[coordinatesAll]}];
  physicalSymbols = symbolOf /@ physicalCoordinates; canonicalSymbols = symbolOf /@ canonicalCoordinates;
  stage["canonical endpoint binding on the needed slots"];
  method = Replace[OptionValue["DifferentialEquationCheck"], Automatic :> If[dimension <= OptionValue["ExactCheckDimensionLimit"], "Exact", "Modular"]];
  If[method === "Modular",
    BlockRandom[SeedRandom[seed];
      primes = Table[RandomPrime[{2^30, 2^31 - 1}], {OptionValue["ModularPrimeCount"]}];
      points = Table[RandomInteger[{2, 2^30}, Length[variables]], {OptionValue["ModularPoints"]}]]];
  (* small families: the full canonical enumeration on the needed slots (exact DE word by word);
     large families: the deliverable's words on the physical functional, the structural DE certificate *)
  canonicalEnumeration = If[method === "Exact",
    finishEnumerateWords[automaton, IdentityMatrix[Length[slots]][[Flatten[Position[slots, Alternatives @@ neededSlots]]]], weightBound, maximumPairs,
      "MaximumVisitedNodes" -> OptionValue["MaximumVisitedNodes"], "WallBudgetSeconds" -> OptionValue["EnumerationWallBudgetSeconds"]],
    finishNumericEnumeration[automaton, tLaurent, variables, seed, automaton["RequestedMaximumWeight"], maximumPairs,
      "MaximumVisitedNodes" -> OptionValue["MaximumVisitedNodes"], "WallBudgetSeconds" -> OptionValue["EnumerationWallBudgetSeconds"]]];
  If[canonicalEnumeration["Capped"], finishFail["FinishWordEnumerationCapped", <|"Stage" -> "word enumeration", "StoppedBy" -> canonicalEnumeration["Stopped"],
      "CompleteThroughWeight" -> canonicalEnumeration["CompleteThroughWeight"], "RequestedWeight" -> canonicalEnumeration["RequestedWeight"],
      "PairsFound" -> canonicalEnumeration["Count"], "VisitedNodes" -> canonicalEnumeration["VisitedNodes"], "Seconds" -> canonicalEnumeration["Seconds"],
      "MaximumWordPairs" -> maximumPairs, "MaximumVisitedNodes" -> OptionValue["MaximumVisitedNodes"], "WallBudgetSeconds" -> OptionValue["EnumerationWallBudgetSeconds"],
      "ResidentBytes" -> finishResidentBytes[]|>]];
  stage["canonical word pairs enumerated: " <> ToString[canonicalEnumeration["Count"]]];
  canonicalTerms = finishCompose[canonicalBinding, canonicalTransport, ({#[[1]], #[[2]]} &) /@ canonicalEnumeration["Pairs"]];
  stage["canonical terms composed: " <> ToString[Length[canonicalTerms]]];
  canonicalByRow = finishTerms[canonicalTerms, legs, canonicalSymbols, Length[neededSlots], prescriptions];
  canonicalTables = Association@Table[neededSlots[[i]] -> canonicalByRow[[i]], {i, Length[neededSlots]}];
  stage["canonical expansions: " <> ToString[Total[Length /@ canonicalTables]] <> " terms"];
  (* physical rows: I_r^(n) = Sum_(p,k) T^(n-p)_(r k) F_k^(p) exactly, with
     the Laurent coefficients of the certified transformation at the target
     point.  (The graded endpoint record cannot supply this: its composer
     specializes every current word map at the interior base, so it carries
     the T prefactor frozen there -- right for the boundary constants at the
     base, not a representation of the target dependence.) *)
  physicalTables = Association@Table[demanded[[i]] -> finishCollect[
      Select[Together /@ Merge[Table[If[finishCheapZeroQ[tLaurent[[i, s]], variables] || ! KeyExistsQ[canonicalTables, slots[[s]]], <||>,
          Map[tLaurent[[i, s]] # &, canonicalTables[slots[[s]]]]], {s, Length[slots]}], Total], ! finishZeroQ[#] &]],
    {i, Length[demanded]}];
  expressions = Map[#["Expression"] &, physicalTables];
  stage["physical expressions: " <> ToString[Total[Length /@ Map[#["Table"] &, physicalTables]]] <> " terms"];
  (* the graded physical endpoint record, composed on the pairs that survive
     the T-Laurent functionals: valid at the interior base, where it must
     agree with the finished expressions coefficient by coefficient *)
  enumeration = If[method === "Exact", <|"Pairs" -> finishPhysicalPairs[canonicalEnumeration["Pairs"], tLaurent, variables, seed]|>,
    <|"Pairs" -> canonicalEnumeration["Pairs"], "PruningPoints" -> canonicalEnumeration["PruningPoints"]|>];
  enumeration["Count"] = Length[enumeration["Pairs"]];
  stage["graded-record word pairs selected: " <> ToString[enumeration["Count"]]];
  physicalTerms = finishCompose[endpoint, transport, ({#[[1]], #[[2]]} &) /@ enumeration["Pairs"]];
  physicalByRow = finishTerms[physicalTerms, legs, physicalSymbols, Length[demanded], prescriptions];
  baseRules = endpoint["CurrentBaseRules"];
  stage["graded record composed: " <> ToString[Total[Length /@ physicalByRow]] <> " terms at the interior base"];
  (* certificate (i) *)
  functionalCertificate = finishDemandFunctionalCertificate[tLaurent, form["TTotal"], eps, slots, demanded, variables, method, points, primes];
  stage["demand-map = T-Laurent functional: " <> functionalCertificate["Status"]];
  deCertificate = If[method === "Exact",
    finishDifferentialCertificate[canonicalTables, feedingSlots, form, transport, legs,
      "Method" -> method, "Variables" -> variables, "Points" -> points, "Primes" -> primes],
    finishStructuralDifferentialCertificate[transport, form, legs, slots, variables, points, primes]];
  stage["differential-equation certificate: " <> deCertificate["Status"]];
  (* certificate (ii) *)
  boundaryCertificate = finishBoundaryCertificate[canonicalTables, neededSlots, modeMap, canonicalCoordinates, canonicalSymbols, eps];
  stage["boundary-matching certificate: " <> boundaryCertificate["Status"]];
  (* the graded record's coefficients equal the finished coefficients at the interior base *)
  Do[
    With[{recordTable = physicalByRow[[i]], finished = physicalTables[demanded[[i]]]["Table"]},
      Do[difference = Together[Lookup[recordTable, Key[key], 0] - (Lookup[finished, Key[key], 0] /. baseRules)];
        If[! finishZeroQ[difference],
          AppendTo[tieFailures, <|"Pair" -> demanded[[i]], "Key" -> key, "GradedRecord" -> Lookup[recordTable, Key[key], 0],
            "FinishedAtBase" -> Together[Lookup[finished, Key[key], 0] /. baseRules]|>]],
        {key, Union[Keys[recordTable], Keys[finished]]}]],
    {i, Length[demanded]}];
  tie = <|"Status" -> If[tieFailures === {}, "GradedRecordAgreesAtInteriorBase", "GradedRecordDisagreesAtInteriorBase"],
    "InteriorBase" -> baseRules, "WordPairs" -> enumeration["Count"], "Comparisons" -> Total[Length /@ physicalByRow],
    "Failures" -> Take[tieFailures, UpTo[20]],
    "Relation" -> "the finished I_r^(n) = Sum_(p,k) T^(n-p)_(r k) F_k^(p) at the target; the graded endpoint record's composer specializes the T prefactor at the interior base, where its coefficients must equal the finished ones"|>;
  stage["graded-record consistency: " <> tie["Status"]];
  (* periods, relations, binding *)
  table = finishPeriodTable[family, coordinatesAll, periodSymbols, modeMap];
  relations = finishRelations[table];
  purity = finishPurityCheck[Join[Values[expressions], Keys /@ Values[canonicalTables] // Flatten, Values /@ Values[canonicalTables] // Flatten], variables, periodSymbols];
  fingerprints = <|"EpsilonForm" -> finishFingerprint[KeyTake[form, {"EpsFormX", "EpsFormY", "TTotal", "Letters", "Variables", "Regulator", "Chart", "Status", "Ranges"}]],
    "ObservableTransport" -> finishFingerprint[KeyDrop[transport, {"Seconds", "TotalSeconds", "SourceFiles"}]],
    "BoundaryModeMap" -> finishFingerprint[KeyDrop[modeMap, {"TimingsSeconds", "SourceFiles"}]],
    "EndpointTransport" -> finishFingerprint[KeyDrop[endpoint, {"TotalSeconds", "SourceFiles", "GradeSummary"}]],
    "Demand" -> finishFingerprint[<|"PhysicalDemandPairs" -> demanded, "Path" -> transport["Path"]|>]|>;
  If[functionalCertificate["Status"] =!= "DemandMapIsTLaurentFunctional", AppendTo[reasons, "DemandMapFunctional"]];
  If[deCertificate["Status"] =!= "DifferentialEquationVerified", AppendTo[reasons, "DifferentialEquation"]];
  If[boundaryCertificate["Status"] =!= "BoundaryMatchingVerified", AppendTo[reasons, "BoundaryMatching"]];
  If[tie["Status"] =!= "GradedRecordAgreesAtInteriorBase", AppendTo[reasons, "GradedRecordConsistency"]];
  If[purity["Status"] =!= "ExpressionsPure", AppendTo[reasons, "Purity"]];
  stage["record assembled"];
  record = <|
    "Status" -> If[reasons === {}, "PhysicalTransportFinished", "PhysicalTransportIncomplete"],
    "Contract" -> "Design/FinishedTransportContract_2026-09-03.md",
    "Family" -> family, "Variables" -> variables, "Regulator" -> eps,
    "Chart" -> <|"Name" -> Lookup[form, "Chart", Missing[]], "Record" -> Lookup[form, "ChartRecord", Missing[]]|>,
    "Path" -> <|"PhysicalEndpoint" -> endpoint["EndpointPath"]["Endpoint"], "InteriorBase" -> endpoint["EndpointPath"]["InteriorBase"],
      "Target" -> Thread[variables -> variables], "LegsOutermostFirst" -> {"CurrentFirst", "CurrentSecond", "EndpointFirst", "EndpointSecond"},
      "Legs" -> Map[KeyTake[#, {"Variable", "From", "To", "FixedRules", "Note"}] &, legs],
      "Prescriptions" -> prescriptions,
      "IteratedIntegralConvention" -> "FormalChenIteratedIntegral[letterSequence (outermost first), {variable, lowerLimit, upperLimit}, None, prescription]. A product of the four segment integrals is retained as a product; it is not identified with one iterated integral on the concatenated path."|>,
    "Letters" -> Map[<|"AlphabetIndices" -> #["AlphabetIndices"], "Kernels" -> #["Kernels"], "BaseLetters" -> #["Letters"],
      "KernelOfLetter" -> "IteratedIntegralKernel[label, variable]"|> &, legs],
    "DemandedPairs" -> demanded,
    "Expressions" -> expressions,
    "Terms" -> Map[#["Table"] &, physicalTables],
    "PeriodBasis" -> table, "PeriodRelations" -> relations,
    "PeriodCoordinatesByBinding" -> <|"Physical" -> ({#["PeriodID"], #["EpsilonOrder"]} & /@ physicalCoordinates),
      "Canonical" -> ({#["PeriodID"], #["EpsilonOrder"]} & /@ canonicalCoordinates)|>,
    "CanonicalExpansions" -> canonicalTables, "CanonicalSlots" -> neededSlots, "FeedingSlots" -> feedingSlots, "AmbientSlots" -> slots,
    "ModeVectors" -> Association@Table[Lookup[m, "PeriodID"] -> Lookup[m, "CanonicalMode"], {m, modeMap["Modes"]}],
    "ConnectionForCheck" -> <|"EpsFormX" -> form["EpsFormX"], "EpsFormY" -> form["EpsFormY"], "Ranges" -> Lookup[form, "Ranges", Missing[]],
      "TLaurentFunctionals" -> tLaurent, "Flatness" -> Lookup[form, "Flatness", Missing[]]|>,
    "TransportEpsilonValuations" -> Lookup[transport, "TransportEpsilonValuations", <||>],
    "StructuralCheckData" -> If[method === "Exact", None, <|"ExactOperatorAutomaton" -> KeyTake[automaton, {"FirstAlphabetIndices", "FirstOperatorMatrices"}],
      "Regulator" -> eps, "DLogResidues" -> Lookup[transport, "DLogResidues", Missing[]], "DLogLetters" -> Lookup[transport, "DLogLetters", Missing[]]|>],
    "Certificates" -> <|"DifferentialEquation" -> deCertificate, "BoundaryMatching" -> boundaryCertificate, "GradedRecordConsistency" -> tie,
      "DemandMapFunctional" -> functionalCertificate,
      "Binding" -> <|"Fingerprints" -> fingerprints, "Purity" -> purity, "InputFiles" -> inputs["Files"]|>|>,
    "IncompleteReasons" -> reasons,
    "IncompletePairs" -> If[reasons === {}, {}, demanded],
    "GradedRecordTermsAtBase" -> Association@Table[demanded[[i]] -> physicalByRow[[i]], {i, Length[demanded]}],
    "EnumerationCompleteness" -> If[method === "Exact", "ExactZeroPruningOnTheCanonicalFunctionals",
      <|"Method" -> "PhysicalFunctionalAtTwoRandomPoints", "PruningPoints" -> Lookup[canonicalEnumeration, "PruningPoints", {}],
        "Meaning" -> "a word pair whose demanded maps vanish at both random rational points is dropped"|>],
    "Counts" -> <|"GradedRecordWordPairs" -> enumeration["Count"], "CanonicalWordPairs" -> canonicalEnumeration["Count"],
      "PhysicalTerms" -> Total[Length /@ Map[#["Table"] &, physicalTables]], "CanonicalTerms" -> Total[Length /@ canonicalTables], "Periods" -> Length[periodSymbols]|>,
    "Timings" -> timings, "Seconds" -> AbsoluteTime[] - started,
    "PeakMemoryBytes" -> MaxMemoryUsed[], "ResidentBytesAtEnd" -> finishResidentBytes[], "MemoryLimitBytes" -> $finishMemoryLimit|>;
  If[StringQ[directory],
    If[! DirectoryQ[directory], CreateDirectory[directory, CreateIntermediateDirectories -> True]];
    Put[record, FileNameJoin[{directory, "finished_transport_" <> family <> ".wl"}]]];
  record
];
FinishPhysicalTransport[___] := <|"Status" -> "FinishPhysicalTransportInputsNotWellFormed"|>;

(* a typed refusal thrown inside the builder becomes an incomplete record naming the reason *)
FinishPhysicalTransport[family_String, options : OptionsPattern[]] /; ! TrueQ[$finishInsideBuilder] := Block[{$finishInsideBuilder = True},
  With[{result = FinishPhysicalTransport[family, options]},
    If[AssociationQ[result] && MemberQ[{"PhysicalTransportFinished", "PhysicalTransportIncomplete"}, Lookup[result, "Status", None]], result,
      <|"Status" -> "PhysicalTransportIncomplete", "Family" -> family, "IncompleteReasons" -> {Lookup[result, "Status", "Unknown"]},
        "IncompletePairs" -> "All", "Refusal" -> result, "PeakMemoryBytes" -> MaxMemoryUsed[]|>]]];

PhysicalTransportFinishedQ[record_Association] := Module[
  {family, variables, eps, symbols, purity, demanded, expressions, certificates, de, boundary, tie, legs, slots, canonicalTables, form, deAgain, boundaryAgain, tieAgain = True, modeMapLike},
  If[Lookup[record, "Status", None] =!= "PhysicalTransportFinished" || Lookup[record, "Contract", None] =!= "Design/FinishedTransportContract_2026-09-03.md", Return[False]];
  family = record["Family"]; variables = record["Variables"]; eps = record["Regulator"];
  demanded = record["DemandedPairs"]; expressions = record["Expressions"];
  If[! AssociationQ[expressions] || ! AllTrue[demanded, KeyExistsQ[expressions, #] &], Return[False]];
  symbols = Lookup[record["PeriodBasis"], "Symbol"];
  If[! AllTrue[symbols, StringStartsQ[Context[#], "FeynFacetPeriod`"] &], Return[False]];
  canonicalTables = record["CanonicalExpansions"]; slots = record["CanonicalSlots"];
  purity = finishPurityCheck[Join[Values[expressions], Flatten[Keys /@ Values[canonicalTables]], Flatten[Values /@ Values[canonicalTables]]], variables, symbols];
  If[purity["Status"] =!= "ExpressionsPure", Return[False]];
  certificates = record["Certificates"];
  de = certificates["DifferentialEquation"]; boundary = certificates["BoundaryMatching"]; tie = certificates["GradedRecordConsistency"];
  If[Lookup[certificates["DemandMapFunctional"], "Status", None] =!= "DemandMapIsTLaurentFunctional" ||
      de["Status"] =!= "DifferentialEquationVerified" || boundary["Status"] =!= "BoundaryMatchingVerified" || tie["Status"] =!= "GradedRecordAgreesAtInteriorBase" ||
      ! TrueQ[record["ConnectionForCheck"]["Flatness"]] || ! AssociationQ[certificates["Binding"]["Fingerprints"]] || Length[certificates["Binding"]["Fingerprints"]] < 5, Return[False]];
  (* re-verification from the record alone *)
  legs = Association@KeyValueMap[#1 -> Join[#2, <|"Letters" -> #2["BaseLetters"]|>] &, record["Letters"]];
  legs = Association@KeyValueMap[#1 -> Join[legs[#1], record["Path"]["Legs"][#1]] &, legs];
  form = KeyTake[record["ConnectionForCheck"], {"EpsFormX", "EpsFormY", "Ranges", "Flatness"}];
  deAgain = If[de["Method"] === "Structural",
    finishStructuralDifferentialCertificate[record["StructuralCheckData"], form, legs, record["AmbientSlots"], variables, de["Points"], de["Primes"]],
    finishDifferentialCertificate[canonicalTables, record["FeedingSlots"], form, <|"Regulator" -> eps, "TransportEpsilonValuations" -> record["TransportEpsilonValuations"]|>, legs,
      "Method" -> de["Method"], "Variables" -> variables, "Points" -> de["Points"], "Primes" -> de["Primes"]]];
  If[deAgain["Status"] =!= "DifferentialEquationVerified", Return[False]];
  modeMapLike = <|"Modes" -> KeyValueMap[<|"PeriodID" -> #1, "CanonicalMode" -> #2|> &, record["ModeVectors"]]|>;
  boundaryAgain = finishBoundaryCertificate[canonicalTables, slots, modeMapLike,
    Table[<|"PeriodID" -> entry["PeriodID"], "EpsilonOrder" -> entry["EpsilonOrder"]|>, {entry, record["PeriodBasis"]}], symbols, eps];
  If[boundaryAgain["Status"] =!= "BoundaryMatchingVerified", Return[False]];
  (* the finished physical rows are T . canonical, and agree with the stored graded-record terms at the base *)
  tieAgain = AllTrue[demanded, Function[pair, With[{finished = record["Terms"][pair], stored = Lookup[record["GradedRecordTermsAtBase"], Key[pair], <||>]},
    AllTrue[Union[Keys[finished], Keys[stored]], finishZeroQ[Together[Lookup[stored, Key[#], 0] - (Lookup[finished, Key[#], 0] /. tie["InteriorBase"])]] &]]]];
  tieAgain
];
PhysicalTransportFinishedQ[___] := False;
