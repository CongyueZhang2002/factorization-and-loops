(* Prototypes/MultiquadraticMixedGradeLetters.wl

   MOVED OUT OF PRODUCTION 2026-08-26 (round-2 wave, Codex review 4.2).

   Witness-guided mixed-grade letter discovery.  It has NO production
   caller: `multiquadraticOffDiagonalBlockCandidateLetters` builds single-root
   principal letters only.  Codex 4.2 asked that 200 lines of apparently
   available but unused capability stop living in a loaded file, and
   Codex 3.2 describes the generalization (quotient-ring reduction
   modulo (f, r_i^2 - delta_i), divisor-guided candidate selection) that
   must replace it before it is integrated.  Until then it is a
   prototype: exercised by Tests/Multiquadratic/t_multiquadratic_off_diagonal_basis_transformation_screen.wls,
   which Gets this file explicitly, and by nothing else.

   Load it INSIDE the FeynFacet`Private` context, after FeynFacet:

     Begin["FeynFacet`Private`"];
     Get[".../Prototypes/MultiquadraticMixedGradeLetters.wl"];
     End[];

   It uses multiquadraticOffDiagonalBlockPolynomialSquareRoot,
   multiquadraticOffDiagonalBlockRationalSquareQ,
   multiquadraticOffDiagonalBlockNormInAlphabetQ,
   multiquadraticOffDiagonalBlockProductionOptionGate and
   multiquadraticOffDiagonalBlockFailure
   from the package, which is why it is not standalone. *)

Begin["FeynFacet`Private`"];

ClearAll[multiquadraticOffDiagonalBlockCurveParameterization,
  multiquadraticOffDiagonalBlockRationalFunctionSquareRoot,
  multiquadraticOffDiagonalBlockGradeSquare,
  multiquadraticOffDiagonalBlockGradeNorm,
  multiquadraticOffDiagonalBlockMixedGradeLetters];

(* ------------------------------------------------------------------ *)
(* Witness-guided MIXED-GRADE letter discovery (2026-08-25, Codex Q3)   *)
(* ------------------------------------------------------------------ *)

(* The norm-factor generator above finds SINGLE-ROOT principal letters
   A +- Sqrt[delta] only.  Codex's Q3: the object that can be missing is
   a mixed-grade potential
     P = P0 + P1 r1 + P2 r2 + P12 r1 r2,
   whose FULL Galois norm is supported on the polar divisor D, and whose
   dlog is then the missing letter.  Enumerating such P by templates is
   hopeless; the problem is solved EXACTLY and LINEARLY as follows.

   A letter exists at a polar factor f exactly when the prime divisor f
   SPLITS in the multiquadratic cover -- and then the function whose
   divisor is the split part is the letter.  So:

   (1) parameterize the curve f = 0 (f must be linear in one variable,
       which every rational polar factor of these strips is; anything
       else is reported, not guessed at);
   (2) on that curve, decide for EVERY grade g whether delta_g is a
       square in the residue field.  Those grades form a subgroup S of
       the grade group -- the decomposition data of f;
   (3) the condition "P vanishes on one prime above f" is then LINEAR in
       the coefficients of the P_g: substitute the square roots for the
       split roots, keep the others symbolic, reduce r_a^2 -> delta_a,
       and demand every remaining coefficient vanish identically along
       the curve.  That is a rational-linear system; its null space is
       the space of mixed-grade potentials with a zero at that prime;
   (4) the full Galois norm of each solution is computed exactly and
       filtered by the SAME norm-in-alphabet certificate the single-root
       letters carry, now against the polar CENSUS factor set rather
       than the current alphabet.

   The degree bound is raised one step at a time, so the first solutions
   found are the minimal-degree generators, not generic members of a
   large space.  A measured empty result at a stated bound is a real
   negative: no mixed-grade letter of that degree has its divisor over
   these factors. *)

(* The curve f = 0 as var -> rational function of the other variable.
   Only a factor that is LINEAR in one of the two variables is
   parameterized this way; anything else is reported as unparameterized
   rather than approximated. *)
(* Catch/Throw, NOT Return inside Do: this package has paid for that trap
   (Return inside Do discards the result and the Module falls through). *)
multiquadraticOffDiagonalBlockCurveParameterization[factor_, variables : {x_, y_}] :=
  Catch[Module[{expanded, other, coefficients},
  expanded = Quiet[Expand[Together[factor]]];
  If[! PolynomialQ[expanded, variables],
    Throw[$Failed, "MultiquadraticCurveParameterization"]];
  Do[
    other = variables[[3 - k]];
    If[Exponent[expanded, variables[[k]]] =!= 1, Continue[]];
    coefficients = CoefficientList[expanded, variables[[k]]];
    If[Length[coefficients] =!= 2 || TrueQ[Together[coefficients[[2]]] === 0],
      Continue[]];
    Throw[<|"Variable" -> other,
      "Rule" -> variables[[k]] -> Together[-coefficients[[1]]/coefficients[[2]]],
      "Eliminated" -> variables[[k]], "Factor" -> expanded|>,
      "MultiquadraticCurveParameterization"],
    {k, 2}];
  $Failed], "MultiquadraticCurveParameterization"];

(* An exact square root of a rational function of ONE variable, or
   $Failed.  q = n/d is a square exactly when n d is a square polynomial;
   then Sqrt[q] = Sqrt[n d]/d. *)
multiquadraticOffDiagonalBlockRationalFunctionSquareRoot[value_, variable_Symbol] :=
  Module[{rational, numerator, denominator, product, squareRoot, constant},
  rational = Quiet[Together[value]];
  If[! FreeQ[rational, DirectedInfinity | Indeterminate], Return[$Failed]];
  If[TrueQ[rational === 0], Return[0]];
  numerator = Numerator[rational]; denominator = Denominator[rational];
  If[FreeQ[rational, variable],
    Return[If[multiquadraticOffDiagonalBlockRationalSquareQ[rational], Sqrt[rational],
      $Failed]]];
  product = Quiet[Expand[numerator denominator]];
  If[! PolynomialQ[product, variable], Return[$Failed]];
  constant = Quiet[Cancel[product/Expand[product/Coefficient[product,
    variable, Exponent[product, variable]]]]];
  squareRoot = multiquadraticOffDiagonalBlockPolynomialSquareRoot[product, {variable}];
  If[squareRoot === $Failed, Return[$Failed]];
  Together[squareRoot/denominator]
];

(* grade bitmask -> the product of its root squares *)
multiquadraticOffDiagonalBlockGradeSquare[roots_List, grade_Integer] :=
  Expand[Together[Product[
    If[BitGet[grade, a - 1] === 1,
      squareRootRecordRadicand[roots[[a]]], 1],
    {a, Length[roots]}]]];

(* The product over the DISTINCT formal square-root sign-change images of
   P = Sum_g c_g r_g, reduced by r_a^2 = delta_a.  This prototype does not
   prove square-class independence, so it does not call those images Galois
   conjugates or the product a field norm.  Removing repeated images avoids
   multiplying a proper-subalgebra result to an artificial power. *)
multiquadraticOffDiagonalBlockGradeNorm[coefficients_List, roots_List] := Module[
  {rank = Length[roots], gradeCount, branch, branches = {}, product,
   rootOne, rootTwo, rootThree, symbols, squares, reduce},
  gradeCount = 2^rank;
  If[Length[coefficients] =!= gradeCount, Return[$Failed]];
  symbols = Take[{rootOne, rootTwo, rootThree}, rank];
  squares = Table[Together[squareRootRecordRadicand[roots[[a]]]], {a, rank}];
  (* the reduction r_a^2 -> delta_a, applied to exhaustion; the complete
     sign-change orbit product is invariant, so nothing symbolic may survive *)
  reduce[value_] := Module[{current = Expand[value], guardCount = 0},
    While[guardCount < 32 && ! FreeQ[current,
        Power[Alternatives @@ symbols, p_Integer /; p >= 2]],
      guardCount++;
      current = Expand[current /.
        Power[symbol_ /; MemberQ[symbols, symbol], p_Integer /; p >= 2] :>
          symbol^Mod[p, 2] squares[[First[FirstPosition[symbols, symbol]]]]^
            Quotient[p, 2]]];
    current];
  Do[
    branch = Expand[Sum[
      coefficients[[grade + 1]] Product[
        If[BitGet[grade, a - 1] === 1,
          If[BitGet[signMask, a - 1] === 1, -1, 1] symbols[[a]], 1],
        {a, rank}],
      {grade, 0, gradeCount - 1}]];
    AppendTo[branches, branch],
    {signMask, 0, gradeCount - 1}];
  branches = DeleteDuplicates[branches,
    TrueQ[Expand[Together[#1 - #2]] === 0] &];
  product = 1;
  Do[product = reduce[Expand[product branch]], {branch, branches}];
  If[! FreeQ[product, Alternatives @@ symbols], Return[$Failed]];
  Quiet[Expand[Together[product]]]
];

Options[multiquadraticOffDiagonalBlockMixedGradeLetters] = {
  "MaximumDegree" -> 2,
  "Factors" -> Automatic,
  "Alphabet" -> {},
  "MaximumSolutionsPerPrime" -> 6,
  (* 0 = the solution basis only; 2 = also every +-1 combination of a
     PAIR of basis vectors.  Part of the stated bound of a negative. *)
  "CombinationOrder" -> 2,
  "CombinationBasisLimit" -> 24,
  (* a letter of grade support {0, g} lies in a quadratic subfield and is
     already produced by multiquadraticOffDiagonalBlockAlgebraicLetters; one of
     support {g, h} is r_g times such a letter, so its dlog is spanned by
     the alphabet plus dlog r_g.  True emits only supports of size >= 3,
     which is where the genuinely mixed-grade content is. *)
  "MinimumGradeSupport" -> 1
};

multiquadraticOffDiagonalBlockMixedGradeLetters[roots_List, censusFactors_List,
    variables : {x_, y_}, opts : OptionsPattern[]] := Module[
  {gate, rank, gradeCount, alphabet, factors, maximumDegree, maximumSolutions,
   records = {}, diagnostics = {}, parameterization, freeVariable, rule,
   gradeSquares, curveSquares, splitGrades, squareRoots, rootSymbols,
   rootOne, rootTwo, rootThree, degree, monomials, unknowns, coefficients,
   substituted, reduced, conditions, equations, solutions, basis, candidate,
   norm, letter, canonical, seen = {}, key, symbolValues, remaining,
   numerators, gradeSquareOnCurve, solutionCount, expression,
   ramifiedGrades, trivialCount = 0, combinationOrder, combinationLimit,
   minimumSupport, combinationCount = 0, gradeSupport},
  gate = multiquadraticOffDiagonalBlockProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticOffDiagonalBlockMixedGradeLetters]]]];
  If[AssociationQ[gate], Return[gate]];
  rank = Length[roots];
  If[rank < 1 || rank > $multiquadraticOffDiagonalBlockMaximumRootCount,
    Return[multiquadraticOffDiagonalBlockFailure["UnsupportedRootRank",
      <|"ActualRank" -> rank|>]]];
  gradeCount = 2^rank;
  alphabet = Replace[OptionValue["Alphabet"], Automatic :> censusFactors];
  factors = Replace[OptionValue["Factors"], Automatic :> censusFactors];
  maximumDegree = OptionValue["MaximumDegree"];
  maximumSolutions = OptionValue["MaximumSolutionsPerPrime"];
  combinationOrder = OptionValue["CombinationOrder"];
  combinationLimit = OptionValue["CombinationBasisLimit"];
  minimumSupport = OptionValue["MinimumGradeSupport"];
  If[! IntegerQ[maximumDegree] || maximumDegree < 0 ||
      ! IntegerQ[maximumSolutions] || maximumSolutions < 1 ||
      ! IntegerQ[combinationOrder] || combinationOrder < 0 ||
      ! IntegerQ[combinationLimit] || combinationLimit < 1 ||
      ! IntegerQ[minimumSupport] || minimumSupport < 1,
    Return[multiquadraticOffDiagonalBlockFailure["InvalidMixedGradeRequest",
      <|"MaximumDegree" -> maximumDegree,
        "CombinationOrder" -> combinationOrder,
        "MinimumGradeSupport" -> minimumSupport|>]]];
  rootSymbols = Take[{rootOne, rootTwo, rootThree}, rank];
  gradeSquares = Table[multiquadraticOffDiagonalBlockGradeSquare[roots, grade],
    {grade, 0, gradeCount - 1}];
  Do[
    parameterization = multiquadraticOffDiagonalBlockCurveParameterization[factor,
      variables];
    If[parameterization === $Failed,
      AppendTo[diagnostics, <|"Factor" -> factor,
        "Status" -> "NotRationallyParameterized"|>];
      Continue[]];
    freeVariable = parameterization["Variable"];
    rule = parameterization["Rule"];
    (* (2) the decomposition data: which grades are squares on the curve *)
    curveSquares = Quiet[Together[gradeSquares /. rule]];
    squareRoots = Table[
      multiquadraticOffDiagonalBlockRationalFunctionSquareRoot[curveSquares[[grade + 1]],
        freeVariable], {grade, 0, gradeCount - 1}];
    splitGrades = Select[Range[0, gradeCount - 1],
      squareRoots[[#1 + 1]] =!= $Failed &];
    ramifiedGrades = Select[Range[0, gradeCount - 1],
      TrueQ[Together[curveSquares[[#1 + 1]]] === 0] &];
    If[Length[splitGrades] <= 1,
      AppendTo[diagnostics, <|"Factor" -> factor, "Status" -> "Inert",
        "SplitGrades" -> splitGrades|>];
      Continue[]];
    AppendTo[diagnostics, <|"Factor" -> factor, "Status" -> "Split",
      "SplitGrades" -> splitGrades, "RamifiedGrades" -> ramifiedGrades,
      "FullSplit" -> (Length[splitGrades] === gradeCount &&
        ramifiedGrades === {})|>];
    (* (3) the LINEAR vanishing condition at one prime above the factor.
       Split roots take their square-root value on the curve; the others
       stay symbolic and are reduced by r_a^2 = delta_a, and every
       surviving coefficient must vanish identically along the curve. *)
    symbolValues = Table[
      If[MemberQ[splitGrades, 2^(a - 1)], squareRoots[[2^(a - 1) + 1]],
        rootSymbols[[a]]], {a, rank}];
    gradeSquareOnCurve = curveSquares;
    solutionCount = 0;
    Do[
      If[solutionCount >= maximumSolutions, Break[]];
      monomials = Flatten[Table[x^i y^j, {i, 0, degree}, {j, 0, degree}]];
      unknowns = Table[Unique["mg"], {gradeCount Length[monomials]}];
      coefficients = Table[
        Sum[unknowns[[(grade) Length[monomials] + m]] monomials[[m]],
          {m, Length[monomials]}], {grade, 0, gradeCount - 1}];
      expression = Sum[
        coefficients[[grade + 1]] Product[
          If[BitGet[grade, a - 1] === 1, symbolValues[[a]], 1], {a, rank}],
        {grade, 0, gradeCount - 1}];
      substituted = Quiet[Expand[expression /. rule]];
      (* reduce r_a^2 -> delta_a on the curve *)
      reduced = substituted;
      Do[
        reduced = Quiet[Expand[reduced /.
          Power[rootSymbols[[a]], p_Integer /; p >= 2] :>
            rootSymbols[[a]]^Mod[p, 2] gradeSquareOnCurve[[2^(a - 1) + 1]]^
              Quotient[p, 2]]],
        {a, rank}];
      reduced = Quiet[Together[reduced]];
      remaining = Select[rootSymbols, ! FreeQ[reduced, #1] &];
      conditions = If[remaining === {}, {Numerator[reduced]},
        Numerator[#1] & /@ Flatten[CoefficientList[Numerator[reduced],
          remaining]]];
      numerators = Select[Quiet[Expand[conditions]],
        ! TrueQ[Together[#1] === 0] &];
      equations = DeleteCases[Flatten[
        CoefficientList[#1, freeVariable] & /@ numerators], 0];
      If[equations === {}, Continue[]];
      solutions = Quiet[Solve[Thread[equations == 0], unknowns]];
      If[! MatchQ[solutions, {_List}], Continue[]];
      basis = Table[
        (coefficients /. First[solutions] /. unknown -> 1) /.
          (# -> 0 & /@ unknowns),
        {unknown, unknowns}];
      basis = DeleteDuplicates[
        Select[basis, ! AllTrue[Flatten[{#1}], TrueQ[Together[#1] === 0] &] &]];
      (* A solution that the factor divides outright, or a single-grade
         solution whose coefficient factors into the alphabet, is not a
         NEW letter: its dlog is already spanned by the rational letters
         and the root dlogs (dlog r_a = dlog delta_a / 2, and delta_a is
         itself a census factor).  Such solutions are counted and
         reported, never emitted, and the genuinely mixed-grade ones are
         tried first. *)
      basis = SortBy[basis, Function[entry,
        {-Count[entry, item_ /; ! TrueQ[Together[item] === 0]],
         LeafCount[entry]}]];
      (* A LETTER is a particular point of the solution space, not a
         basis vector of it: the space contains every multiple of the
         factor and every product of smaller letters, and the letter is
         the point whose norm is supported on the census.  The basis is
         therefore extended by the deterministic +-1 combinations of
         PAIRS of basis vectors before the norm certificate selects; the
         combination order is an option, and it is part of the stated
         bound of any negative result. *)
      If[combinationOrder >= 2 && Length[basis] >= 2 &&
          Length[basis] <= combinationLimit,
        basis = Join[basis, Flatten[Table[
          {basis[[i]] + basis[[j]], basis[[i]] - basis[[j]]},
          {i, Length[basis] - 1}, {j, i + 1, Length[basis]}], 2]]];
      combinationCount += Length[basis];
      Do[
        If[solutionCount >= maximumSolutions, Break[]];
        If[AllTrue[candidate, Function[item,
            TrueQ[Together[item] === 0] ||
              PolynomialQ[Quiet[Cancel[Together[item/factor]]], variables]]],
          trivialCount++; Continue[]];
        gradeSupport = Select[Range[0, gradeCount - 1],
          ! TrueQ[Together[candidate[[#1 + 1]]] === 0] &];
        If[Length[gradeSupport] < minimumSupport, trivialCount++; Continue[]];
        If[Length[gradeSupport] === 1 &&
            multiquadraticOffDiagonalBlockNormInAlphabetQ[
              First[Select[candidate, ! TrueQ[Together[#1] === 0] &]],
              alphabet, variables],
          trivialCount++; Continue[]];
        norm = multiquadraticOffDiagonalBlockGradeNorm[candidate, roots];
        If[norm === $Failed || TrueQ[Together[norm] === 0], Continue[]];
        If[! multiquadraticOffDiagonalBlockNormInAlphabetQ[norm, alphabet, variables],
          Continue[]];
        letter = Together[Sum[
          candidate[[grade + 1]] Product[
            If[BitGet[grade, a - 1] === 1,
              squareRootRecordExpression[roots[[a]]], 1], {a, rank}],
          {grade, 0, gradeCount - 1}]];
        If[TrueQ[Together[letter] === 0], Continue[]];
        canonical = ToString[InputForm[Together[
          letter/First[Select[candidate, ! TrueQ[Together[#1] === 0] &]]]]];
        key = {ToString[InputForm[Together[factor]]], canonical};
        If[MemberQ[seen, key], Continue[]];
        AppendTo[seen, key];
        solutionCount++;
        AppendTo[records, <|"Kind" -> "MixedGrade", "Letter" -> letter,
          "GradeCoefficients" -> candidate,
          "GradeSupport" -> gradeSupport,
          "Norm" -> norm, "NormInAlphabet" -> True,
          "Divisor" -> factor, "Degree" -> degree,
          "SplitGrades" -> splitGrades|>],
        {candidate, basis}],
      {degree, 0, maximumDegree}],
    {factor, factors}];
  <|"Status" -> "MultiquadraticMixedGradeLettersV1",
    "LetterRecords" -> records, "Letters" -> Lookup[records, "Letter", {}],
    "Count" -> Length[records], "TrivialSolutionCount" -> trivialCount,
    "CandidatesTested" -> combinationCount,
    "MaximumDegree" -> maximumDegree,
    "CombinationOrder" -> combinationOrder,
    "MinimumGradeSupport" -> minimumSupport,
    "Factors" -> factors, "Diagnostics" -> diagnostics,
    "SplitFactors" -> Select[diagnostics, Lookup[#1, "Status", None] === "Split" &],
    "UnparameterizedFactors" -> Select[diagnostics,
      Lookup[#1, "Status", None] === "NotRationallyParameterized" &]|>
];
multiquadraticOffDiagonalBlockMixedGradeLetters[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidMixedGradeArguments"];

End[];
