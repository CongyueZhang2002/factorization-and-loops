(* Transport of a final layer whose incoming connection is RATIONAL IN THE
   REGULATOR (round 8, 2026-09-02; user mandate "optimize also the
   transporter for non-eps form, like CF303"; design in
   Design/PrivateOverhaul_2026-09-01_evidence/round8/T_noneps_transport.md).

   System dF = A F, A = [[S, 0], [B, D]] on a one-dimensional path in the
   variable u: the source connection S = eps Sum S_i w_i and the final-
   layer diagonal D = eps Sum D_a w_a are dlog with constant residue
   matrices; the incoming connection B(eps, u) = Sum_n eps^n B_n(u) du is a
   rational function of eps whose orders are rational one-forms that are
   NOT dlog.  The path gauge F_T = G + H F_S with H(base) = 0 removes the
   non-dlog part order by order,

     K_n = B_n + D_1 H_(n-1) - H_(n-1) S_1 - dH_n,   K_n dlog,

   H_n the Hermite primitive of Omega_n = B_n + D_1 H_(n-1) - H_(n-1) S_1
   and K_n its residue part on the declared pole alphabet; G then obeys
   dG = D G + K F_S and a word reaching the final rows has exactly one
   incoming letter, D...D K_r S...S (or D...D on the target boundary).
   Every recurrence step is executed as a SEALED CIRCUIT over F_q[u] at a
   fixed rational path parameter set: leaves specialized first, no
   characteristic-zero H/K ever expanded; only the demanded K residues are
   reconstructed across primes (CRT + rational reconstruction) and
   validated at a fresh prime; H stays at its modular images.  Curve
   letters (Y^2 = P4) are a typed alphabet extension: admitted by the gate
   only with a declared quartic, and their channel is refused typed until
   the elliptic Hermite reduction exists.  No family name appears here. *)

Clear[BuildRationalEpsilonLayerTransport, AcceptedRationalEpsilonLayerTransportQ];
ClearAll[
  rationalLayerLetterFormQ,
  rationalLayerLetterFunction,
  rationalLayerAlphabetGate,
  rationalLayerPoleFactors,
  rationalLayerModularFunction,
  rationalLayerModularPolynomial,
  rationalLayerHermite,
  rationalLayerPartialFractions,
  rationalLayerRecurrenceImage,
  rationalLayerSourceStates,
  rationalLayerWords,
  rationalLayerCertificateShapeQ,
  $rationalLayerCurveLetters,
  $rationalLayerRationalLetters
];

$rationalLayerRationalLetters = {"GPLPole", "GPLFactor"};
$rationalLayerCurveLetters = {"E4Pole", "E4Factor", "E4Omega0", "E4OmegaInf"};

(* ---- alphabet ------------------------------------------------------- *)

(* A letter label: {"GPLPole", c} is du/(u - c); {"GPLFactor", q, k} is
   u^k du/q(u) with q square-free and k < deg q.  Curve letters are
   recognised, and admitted only with a declared quartic curve. *)
(* a pole position must be a RATIONAL number: an algebraic one (CF303 at
   p = 9/8 still has conjugate pairs over Q(Sqrt[1105])) passed NumericQ
   and broke the modular images (2026-09-02 18:50); such a pair is to be
   declared as one GPLFactor letter on its minimal polynomial *)
rationalLayerLetterFormQ[{"GPLPole", c_}, u_] := MatchQ[c, _Integer | _Rational];
rationalLayerLetterFormQ[{"GPLFactor", q_, k_Integer}, u_] :=
  PolynomialQ[q, u] && Exponent[q, u] >= 1 && 0 <= k < Exponent[q, u] &&
  VectorQ[CoefficientList[q, u], MatchQ[#, _Integer | _Rational] &] &&
  Exponent[PolynomialGCD[q, D[q, u]], u] === 0;
rationalLayerLetterFormQ[___] := False;

rationalLayerLetterFunction[{"GPLPole", c_}, u_] := 1/(u - c);
rationalLayerLetterFunction[{"GPLFactor", q_, k_Integer}, u_] := u^k/q;

rationalLayerAlphabetGate[labels_List, u_Symbol, curve_] := Module[
  {verdicts},
  verdicts = Table[Which[
      ! ListQ[label] || label === {},
        <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
          "Reason" -> "not a labelled letter"|>,
      MemberQ[$rationalLayerRationalLetters, First[label]],
        Which[
          rationalLayerLetterFormQ[label, u],
            <|"Label" -> label, "Status" -> "Admitted", "Channel" -> "Rational"|>,
          MatchQ[label, {"GPLPole", c_ /; NumericQ[c] && ! MatchQ[c, _Integer | _Rational]}],
            <|"Label" -> label, "Status" -> "AlgebraicPoleNotAdmitted",
              "Reason" -> "pole position is algebraic; declare the conjugate pair as a GPLFactor letter on its minimal polynomial"|>,
          True,
            <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
              "Reason" -> "malformed rational letter (pole must be a rational number, factor square-free with rational coefficients, power below the degree)"|>],
      MemberQ[$rationalLayerCurveLetters, First[label]],
        If[curve === None,
          <|"Label" -> label, "Status" -> "CurveDeclarationRequired"|>,
          <|"Label" -> label, "Status" -> "Admitted", "Channel" -> "Curve"|>],
      True,
        <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
          "Reason" -> "unknown letter head"|>],
    {label, labels}];
  If[AllTrue[verdicts, #["Status"] === "Admitted" &],
    <|"Status" -> "AlphabetAdmitted", "Verdicts" -> verdicts,
      "Channels" -> DeleteDuplicates[Lookup[verdicts, "Channel"]]|>,
    Join[SelectFirst[verdicts, #["Status"] =!= "Admitted" &],
      <|"Verdicts" -> verdicts|>]]
];

(* The pole alphabet: the square-free factors over Q of the letter
   polynomials and of the denominators of the incoming coefficient
   functions, pairwise coprime, monic. *)
rationalLayerPoleFactors[letters_List, coefficients_List, u_Symbol] := Module[
  {polynomials, factors},
  polynomials = Join[
    Cases[letters, {"GPLPole", c_} :> u - c],
    Cases[letters, {"GPLFactor", q_, _} :> q],
    Denominator[Together[#]] & /@ coefficients];
  factors = DeleteDuplicates[Flatten[Cases[FactorList[Times @@ polynomials],
    {f_, _} /; ! FreeQ[f, u] :> f]]];
  factors = DeleteDuplicates[Expand[#/Coefficient[#, u, Exponent[#, u]]] & /@ factors];
  Select[factors, Exponent[#, u] >= 1 &]
];

(* ---- F_q[u] arithmetic ---------------------------------------------- *)

(* a rational function of u with rational coefficients as {numerator,
   denominator} polynomials over F_q, denominator monic; $Failed when a
   coefficient denominator vanishes at q *)
rationalLayerModularFunction[expression_, u_Symbol, prime_Integer] := Module[
  {together, numerator, denominator, lead},
  together = Quiet[Check[Together[expression, Modulus -> prime], $Failed]];
  If[together === $Failed, Return[$Failed]];
  numerator = Numerator[together]; denominator = Denominator[together];
  If[! PolynomialQ[numerator, u] || ! PolynomialQ[denominator, u] ||
      PolynomialMod[denominator, prime] === 0, Return[$Failed]];
  lead = Coefficient[denominator, u, Exponent[denominator, u]];
  If[Mod[lead, prime] === 0, Return[$Failed]];
  {PolynomialMod[numerator PowerMod[lead, -1, prime], prime],
   PolynomialMod[denominator PowerMod[lead, -1, prime], prime]}
];
(* a polynomial over Q reduced into F_q coefficient by coefficient (the
   built-in Modulus arithmetic does not reduce rational coefficients such
   as the 3/4 of CF303's pole factors at p = 9/8 -- the images across
   primes were inconsistent and no residue reconstructed, 2026-09-02 18:43) *)
rationalLayerModularPolynomial[expression_, u_Symbol, prime_Integer] := Module[
  {coefficients = CoefficientList[Expand[expression], u]},
  If[MemberQ[Mod[Denominator /@ coefficients, prime], 0], Return[$Failed]];
  Expand[Total[MapIndexed[
    Mod[Numerator[#1] PowerMod[Denominator[#1], -1, prime], prime] u^(First[#2] - 1) &,
    coefficients]]]
];

(* Hermite reduction over F_q (Horowitz-Ostrogradsky): f = N/D proper ->
   f = d(Bp/Dstar)/du + C/Dminus with Dminus square-free; the polynomial
   part is integrated separately.  Returns <|"Primitive" -> {Bp, Dstar}
   plus polynomial primitive, "Remainder" -> {C, Dminus}|> or $Failed. *)
rationalLayerHermite[{numerator_, denominator_}, u_Symbol, prime_Integer] := Module[
  {quotient, remainder, dStar, dMinus, m, n, bSym, cSym, unknowns, tSym,
   equation, solution, bPoly, cPoly, polynomialPrimitive, coefficients},
  {quotient, remainder} = PolynomialQuotientRemainder[numerator, denominator, u, Modulus -> prime];
  polynomialPrimitive = If[quotient === 0, 0,
    PolynomialMod[Integrate[quotient, u] /. Rational[a_, b_] :> Mod[a PowerMod[b, -1, prime], prime], prime]];
  If[Exponent[denominator, u] === 0,
    Return[<|"Primitive" -> {polynomialPrimitive, 1}, "Remainder" -> {0, 1}|>]];
  dStar = PolynomialGCD[denominator, D[denominator, u], Modulus -> prime];
  dMinus = PolynomialQuotient[denominator, dStar, u, Modulus -> prime];
  m = Exponent[dStar, u]; n = Exponent[dMinus, u];
  If[m === 0,
    Return[<|"Primitive" -> {polynomialPrimitive, 1}, "Remainder" -> {remainder, dMinus}|>]];
  (* remainder = B' Dminus - B T + C Dstar,  T = Dminus Dstar'/Dstar *)
  tSym = PolynomialQuotient[dMinus D[dStar, u], dStar, u, Modulus -> prime];
  bSym = Array[Unique["rlB"] &, m]; cSym = Array[Unique["rlC"] &, n];
  unknowns = Join[bSym, cSym];
  bPoly = bSym . u^Range[0, m - 1]; cPoly = cSym . u^Range[0, n - 1];
  equation = Expand[D[bPoly, u] dMinus - bPoly tSym + cPoly dStar - remainder];
  coefficients = CoefficientList[equation, u];
  coefficients = PadRight[coefficients, Exponent[denominator, u], 0];
  solution = Quiet[Check[Solve[Table[coefficients[[i]] == 0,
        {i, Exponent[denominator, u]}], unknowns, Modulus -> prime], $Failed]];
  If[solution === $Failed || solution === {}, Return[$Failed]];
  solution = First[solution];
  <|"Primitive" -> {Expand[PolynomialMod[(bPoly /. solution) + polynomialPrimitive dStar, prime]], dStar},
    "Remainder" -> {PolynomialMod[cPoly /. solution, prime], dMinus}|>
];

(* C/Dminus on the declared coprime pole factors: C/Dminus = Sum_j r_j/q_j,
   deg r_j < deg q_j; a factor of Dminus outside the alphabet is $Failed. *)
rationalLayerPartialFractions[{c_, dMinus_}, factors_List, u_Symbol, prime_Integer] := Module[
  {reduced = dMinus, present = {}, result = <||>, cofactor, gcd, inverse, r, modular, image},
  If[c === 0, Return[<||>]];
  (* the declared factors reduced into F_q, keyed by the original factor *)
  modular = Association@Table[factor -> rationalLayerModularPolynomial[factor, u, prime], {factor, factors}];
  If[MemberQ[Values[modular], $Failed], Return[$Failed]];
  Do[
    image = modular[factor];
    If[PolynomialRemainder[reduced, image, u, Modulus -> prime] === 0,
      AppendTo[present, factor];
      reduced = PolynomialQuotient[reduced, image, u, Modulus -> prime]],
    {factor, factors}];
  If[Exponent[reduced, u] > 0, Return[$Failed]];
  Do[
    image = modular[factor];
    cofactor = PolynomialQuotient[dMinus, image, u, Modulus -> prime];
    (* r = C cofactor^-1 mod factor *)
    gcd = PolynomialExtendedGCD[cofactor, image, u, Modulus -> prime];
    If[Exponent[gcd[[1]], u] =!= 0, Return[$Failed, Module]];
    inverse = PolynomialMod[gcd[[2, 1]] PowerMod[gcd[[1]], -1, prime], prime];
    r = PolynomialRemainder[PolynomialMod[c inverse, prime], image, u, Modulus -> prime];
    r = PolynomialMod[r PowerMod[Coefficient[reduced, u, 0], -1, prime], prime];
    result[factor] = PadRight[CoefficientList[r, u], Exponent[factor, u], 0],
    {factor, present}];
  result
];

(* ---- one prime image of the sealed circuit ---------------------------- *)

(* Executes the recurrence over F_q at the specialized leaves.  omegaN is
   built from the Laurent coefficients of the incoming entries (already
   specialized in every parameter but u), the diagonal and source
   residues.  Returns the residue coefficients of every K_n on the pole
   alphabet, and the images of H_n. *)
rationalLayerRecurrenceImage[laurent_Association, diagonal_List, source_Association,
    factors_List, u_Symbol, base_, orders_List, prime_Integer] := Module[
  {d, n, letterFunctions, hPrevious, h, k, omega, entryValue, hermite, fractions,
   value, evaluateAt, hImages = <||>, kResidues = <||>, failure = None,
   diagonalForms, sourceForms, dEntry, sEntry, fixed, hEntry},
  (* rows and columns of the incoming Laurent matrices; the first CF303 run
     (2026-09-02 18:38) read them off the wrong level and looped over
     nothing while the fixture's 2x2 hid it *)
  {d, n} = Dimensions[Lookup[laurent, First[orders]]][[1 ;; 2]];
  If[n =!= source["Dimension"],
    Return[<|"Status" -> "LayerDimensionMismatch", "Prime" -> prime,
      "Columns" -> n, "SourceDimension" -> source["Dimension"]|>]];
  diagonalForms = ({rationalLayerLetterFunction[#[[1]], u], #[[2]]} &) /@ diagonal;
  sourceForms = MapThread[{rationalLayerLetterFunction[#1, u], #2} &,
    {source["Letters"], source["Residues"]}];
  evaluateAt[{num_, den_}] := Module[{image, dv, nv},
    image[r_] := Mod[Numerator[r] PowerMod[Denominator[r], -1, prime], prime];
    dv = image[den /. u -> base]; nv = image[num /. u -> base];
    If[dv === 0, $Failed, Mod[nv PowerMod[dv, -1, prime], prime]]];
  hPrevious = ConstantArray[{0, 1}, {d, n}];
  Do[
    (* Omega_n = B_n + D_1 H_(n-1) - H_(n-1) S_1, entrywise over F_q(u) *)
    omega = Table[
      Module[{terms = {}},
        AppendTo[terms, laurent[order][[i, j]]];
        Do[AppendTo[terms, form[[2]][[i, l]] form[[1]] Together[hPrevious[[l, j, 1]]/hPrevious[[l, j, 2]]]],
          {form, diagonalForms}, {l, d}];
        Do[AppendTo[terms, -Together[hPrevious[[i, l, 1]]/hPrevious[[i, l, 2]]] form[[1]] form[[2]][[l, j]]],
          {form, sourceForms}, {l, n}];
        rationalLayerModularFunction[Total[terms], u, prime]],
      {i, d}, {j, n}];
    If[! FreeQ[omega, $Failed], failure = "CoefficientNotDefinedAtPrime"; Break[]];
    h = ConstantArray[{0, 1}, {d, n}];
    Do[
      hermite = rationalLayerHermite[omega[[i, j]], u, prime];
      If[hermite === $Failed, failure = "HermiteReductionUndecided"; Break[]];
      fractions = rationalLayerPartialFractions[hermite["Remainder"], factors, u, prime];
      If[fractions === $Failed, failure = "ResiduePoleNotInAlphabet"; Break[]];
      KeyValueMap[Function[{factor, list},
        Do[Module[{matrix = Lookup[kResidues, Key[{order, factor, kk - 1}], ConstantArray[0, {d, n}]]},
            matrix[[i, j]] = list[[kk]];
            kResidues[{order, factor, kk - 1}] = matrix], {kk, Length[list]}]],
        fractions];
      (* H_n(base) = 0 *)
      value = evaluateAt[hermite["Primitive"]];
      If[value === $Failed, failure = "BasePointOnPole"; Break[]];
      hEntry = {PolynomialMod[hermite["Primitive"][[1]] - value hermite["Primitive"][[2]], prime],
        hermite["Primitive"][[2]]};
      h[[i, j]] = hEntry,
      {i, d}, {j, n}];
    If[failure =!= None, Break[]];
    hImages[order] = h;
    hPrevious = h,
    {order, orders}];
  If[failure =!= None, Return[<|"Status" -> failure, "Prime" -> prime|>]];
  <|"Status" -> "RecurrenceImageEvaluated", "Prime" -> prime,
    "KResidues" -> kResidues, "HImages" -> hImages|>
];

(* ---- words ------------------------------------------------------------ *)

(* Words D^a K_r S^b and D^a reaching (order, row): the coefficient of a
   word is the row of the matrix product against the boundary selector at
   boundary order q with q + a + r + b = order.  Words GROW from the
   selectors with every zero intermediate product pruned (the sparse word
   growth of observableTransportWordMaps): SparseArray throughout, the
   source-word growth shared across all demanded pairs (sourceStates:
   q -> states by weight), and a K letter applied only where its columns
   meet the state's nonzero rows.  "MaximumWords" caps the enumeration and
   the pair is then reported capped (typed), never truncated silently.
   The first CF303 measurement (2026-09-02 18:22) was killed at the 900 s
   cap in the dense version of this enumeration; everything before it had
   taken 4 s. *)
rationalLayerSourceStates[source_Association, maximumWeight_Integer, weightByOrder_: Automatic] := Module[
  {sLetters, grow, nonzeroQ, needed},
  nonzeroQ[m_] := Length[SparseArray[m]["NonzeroPositions"]] > 0;
  sLetters = Transpose[{source["Letters"], SparseArray /@ source["Residues"]}];
  grow[states_List] := Select[Flatten[Table[
      {Append[state[[1]], letter[[1]]], letter[[2]] . state[[2]]}, {state, states}, {letter, sLetters}], 1],
    nonzeroQ[#[[2]]] &];
  (* grown only as far as a demanded pair can be reached from that boundary
     order (round 8, stage 4: the tail weights of a run are bounded by
     order - q - r; growing every selector to the full weight cost 10 s of
     the 47 s CF303 measurement) *)
  needed[q_] := If[weightByOrder === Automatic, maximumWeight, Lookup[weightByOrder, q, -1]];
  Association@Table[q -> NestList[grow, {{{}, SparseArray[source["BoundarySelectors"][q]]}}, Min[maximumWeight, needed[q]]],
    {q, Select[Keys[source["BoundarySelectors"]], needed[#] >= 0 &]}]
];

rationalLayerWords[order_Integer, row_Integer, diagonal_List, kResidues_Association,
    source_Association, targetSelectors_Association, sourceBoundaryCount_Integer,
    targetBoundaryCount_Integer, maximumWeight_Integer, maximumWords_: Infinity,
    sourceStatesGiven_: Automatic] := Module[
  {words = {}, dLetters, kLetters, embedSource, embedTarget, grow, capped = False,
   nonzeroQ, sourceStates, dStates, kStates, count = 0, rowsOf, columnsOf},
  nonzeroQ[m_] := Length[SparseArray[m]["NonzeroPositions"]] > 0;
  rowsOf[m_] := DeleteDuplicates[SparseArray[m]["NonzeroPositions"][[All, 1]]];
  columnsOf[m_] := DeleteDuplicates[SparseArray[m]["NonzeroPositions"][[All, 2]]];
  dLetters = ({#[[1]], SparseArray[#[[2]]]} &) /@ diagonal;
  kLetters = KeyValueMap[{{#1[[2]], #1[[3]]}, #1[[1]], SparseArray[#2]} &, KeySort[kResidues]];
  kLetters = Select[kLetters, nonzeroQ[#[[3]]] &];
  kLetters = ({#[[1]], #[[2]], #[[3]], columnsOf[#[[3]]]} &) /@ kLetters;
  sourceStates = If[sourceStatesGiven === Automatic,
    rationalLayerSourceStates[source, maximumWeight], sourceStatesGiven];
  embedSource[vector_] := Join[vector, ConstantArray[0, targetBoundaryCount]];
  embedTarget[vector_] := Join[ConstantArray[0, sourceBoundaryCount], vector];
  grow[states_List, letters_List] := Select[Flatten[Table[
      {Append[state[[1]], letter[[1]]], letter[[2]] . state[[2]]}, {state, states}, {letter, letters}], 1],
    nonzeroQ[#[[2]]] &];
  (* target boundary words: D^a Selector[q], a = order - q *)
  Do[
    With[{a = order - q},
      If[0 <= a <= maximumWeight,
        dStates = Nest[grow[#, dLetters] &, {{{}, SparseArray[targetSelectors[q]]}}, a];
        Do[If[nonzeroQ[state[[2]][[row]]],
            AppendTo[words, <|"Word" -> state[[1]], "Kind" -> "TargetBoundary",
              "BoundaryOrder" -> q, "Coefficient" -> embedTarget[Normal[state[[2]][[row]]]]|>];
            count++; If[count > maximumWords, capped = True]],
          {state, dStates}]]],
    {q, Keys[targetSelectors]}];
  (* source boundary words: D^a K_r S^b Selector[q] *)
  Do[
    If[capped, Break[]];
    Do[
      If[capped, Break[]];
      Do[
        With[{a = order - q - kLetter[[2]] - b},
          If[0 <= a <= maximumWeight,
            kStates = Select[Table[
                If[Intersection[kLetter[[4]], rowsOf[state[[2]]]] === {}, Nothing,
                  {Append[state[[1]], {"GPLFactor", kLetter[[1, 1]], kLetter[[1, 2]], "Incoming", kLetter[[2]]}], kLetter[[3]] . state[[2]]}],
                {state, sourceStates[q][[b + 1]]}], nonzeroQ[#[[2]]] &];
            dStates = Nest[grow[#, dLetters] &, kStates, a];
            Do[If[nonzeroQ[state[[2]][[row]]],
                AppendTo[words, <|"Word" -> Reverse[state[[1]]], "Kind" -> "SourceBoundary",
                  "BoundaryOrder" -> q, "IncomingOrder" -> kLetter[[2]],
                  "Coefficient" -> embedSource[Normal[state[[2]][[row]]]]|>];
                count++; If[count > maximumWords, capped = True]],
              {state, dStates}]]],
        {kLetter, kLetters}],
      {b, 0, Min[maximumWeight, Length[sourceStates[q]] - 1]}],
    {q, Keys[sourceStates]}];
  If[capped, <|"Status" -> "WordEnumerationCapped", "MaximumWords" -> maximumWords, "Words" -> words|>, words]
];

(* ---- the route ------------------------------------------------------------ *)

Options[BuildRationalEpsilonLayerTransport] = {
  "Primes" -> Automatic,
  "PrimeCount" -> 3,
  "MaximumPrimeCount" -> 24,
  "Seed" -> 20260902,
  "MaximumWeight" -> 4,
  "MaximumWords" -> Infinity,
  "IncomingRoute" -> Automatic,
  "Verbose" -> False
};

BuildRationalEpsilonLayerTransport[source_Association, layer_Association,
    demand_Association, OptionsPattern[]] := Catch@Module[
  {start = AbsoluteTime[], u, eps, base, rows, d, n, diagonal, incoming, curve,
   labels, gate, coefficients, symbols, factors, valuations, low, high,
   laurent, orders, primes, seed, images, freshPrime, freshImage, keys,
   reconstructed, lifted, comparisons = 0, mismatches = 0, targetSelectors,
   sourceBoundaryCount, targetBoundaryCount, demandPairs, words, maximumWeight,
   verbose, fail, kExact, certificate, laurentCoefficient, hImageCount = 0, sourceStates, directQ,
   weightByOrder, letterDecomposition},
  verbose = TrueQ[OptionValue["Verbose"]];
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  u = Lookup[layer, "PathVariable", Missing[]]; eps = Lookup[layer, "Regulator", Missing[]];
  base = Lookup[layer, "BasePoint", Missing[]]; rows = Lookup[layer, "Rows", Missing[]];
  diagonal = Lookup[layer, "Diagonal", Missing[]]; incoming = Lookup[layer, "Incoming", Missing[]];
  curve = Lookup[layer, "Curve", None];
  If[! MatchQ[u, _Symbol] || ! MatchQ[eps, _Symbol] || ! MatchQ[base, _Integer | _Rational] ||
      ! ListQ[rows] || rows === {} || ! MatchQ[diagonal, {{_List, _?MatrixQ} ..}] ||
      ! MatchQ[incoming, {__Association}],
    fail["LayerInputNotWellFormed"]];
  d = Length[rows];
  If[! AllTrue[diagonal, Dimensions[#[[2]]] === {d, d} &], fail["LayerInputNotWellFormed", <|"Reason" -> "diagonal residue dimensions"|>]];
  n = Lookup[source, "Dimension", Missing[]];
  If[! IntegerQ[n] || ! ListQ[Lookup[source, "Letters", None]] ||
      ! ListQ[Lookup[source, "Residues", None]] ||
      Length[source["Letters"]] =!= Length[source["Residues"]] ||
      ! AllTrue[source["Residues"], Dimensions[#] === {n, n} &] ||
      ! AssociationQ[Lookup[source, "BoundarySelectors", None]],
    fail["SourceLayerNotAccepted"]];
  If[! AllTrue[incoming, IntegerQ[#["Row"]] && 1 <= #["Row"] <= d && IntegerQ[#["Column"]] && 1 <= #["Column"] <= n &],
    fail["LayerInputNotWellFormed", <|"Reason" -> "incoming row/column indices"|>]];
  (* every source column must be present or declared as an exception *)
  With[{missing = Complement[Range[n], Lookup[incoming, "Column"], Lookup[layer, "ZeroColumns", {}]]},
    If[missing =!= {}, fail["LowerBlockExceptionRequired", <|"Columns" -> missing|>]]];
  (* alphabet *)
  labels = DeleteDuplicates[Join[diagonal[[All, 1]], Lookup[incoming, "Letter"], source["Letters"]]];
  gate = rationalLayerAlphabetGate[labels, u, curve];
  If[gate["Status"] =!= "AlphabetAdmitted", fail[gate["Status"], KeyDrop[gate, "Status"]]];
  If[MemberQ[gate["Channels"], "Curve"], fail["CurveChannelNotImplemented",
    <|"Reason" -> "elliptic Hermite reduction not yet in the package", "Verdicts" -> gate["Verdicts"]|>]];
  (* incoming coefficients: rational in eps and u, every other symbol specialized *)
  coefficients = Lookup[incoming, "Coefficient"];
  symbols = DeleteDuplicates[Cases[coefficients, s_Symbol /; s =!= u && s =!= eps, {0, Infinity}]];
  If[symbols =!= {}, fail["PathParameterNotSpecialized", <|"Symbols" -> symbols|>]];
  If[! AllTrue[coefficients, With[{t = Together[#]},
      PolynomialQ[Numerator[t], {eps, u}] && PolynomialQ[Denominator[t], {eps, u}]] &],
    fail["IncomingNotRationalInEpsilon"]];
  (* epsilon window: exact valuation of every coefficient at the base point and at
     two more rational points of u (the round-4 certificate style) *)
  valuations = Table[Module[{vs},
      vs = Table[observableTransportEpsilonOrderAtPoint[c /. u -> pt, eps], {pt, {base, base + 1/3, base + 2/7}}];
      If[! AllTrue[vs, IntegerQ], fail["LayerValuationUncertified", <|"Coefficient" -> c, "Orders" -> vs|>]];
      Min[vs]], {c, coefficients}];
  low = Min[valuations];
  demandPairs = Lookup[demand, "Pairs", Missing[]];
  If[! MatchQ[demandPairs, {{_Integer, _Integer} ..}] || ! AllTrue[demandPairs, 1 <= #[[2]] <= d &],
    fail["InvalidLayerDemand"]];
  high = Max[demandPairs[[All, 1]]];
  If[high < low, fail["DemandBelowValuation", <|"Low" -> low, "High" -> high|>]];
  orders = Range[low, high];
  (* Laurent expansion: one Series per incoming coefficient *)
  laurentCoefficient[c_] := Module[{s = observableTransportLaurentEntrySeries[c, eps, {low, high}]},
    If[s === $Failed, Table[Cancel[Together[SeriesCoefficient[c, {eps, 0, o}]]], {o, orders}], s]];
  laurent = Table[ConstantArray[0, {d, n}], {Length[orders]}];
  Do[With[{series = laurentCoefficient[entry["Coefficient"]], form = rationalLayerLetterFunction[entry["Letter"], u]},
      Do[laurent[[k, entry["Row"], entry["Column"]]] += series[[k]] form, {k, Length[orders]}]],
    {entry, incoming}];
  laurent = AssociationThread[orders -> laurent];
  If[verbose, observableTransportMilestone["Rational layer: Laurent expansion of ", Length[incoming], " incoming entries, orders ", {low, high}, ", ", Round[AbsoluteTime[] - start, 0.1], " s"]];
  With[{mixed = Select[DeleteDuplicates[Flatten[First /@ FactorList[Denominator[Together[#]]] & /@ coefficients]],
      ! FreeQ[#, u] && ! FreeQ[#, eps] &]},
    If[mixed =!= {}, fail["MixedEpsilonPathDenominator", <|"Factors" -> mixed|>]]];
  factors = rationalLayerPoleFactors[labels, coefficients, u];
  (* Round 8, stage 4: when every incoming coefficient is free of the path
     variable, each B_n is a combination of the declared dlog letters with
     NUMERICAL coefficients, Omega_n = B_n (H_(n-1) = 0 inductively) and
     the Hermite gauge vanishes identically: the K residues are the exact
     Laurent coefficients on the letters' own factors -- no modular image,
     no reconstruction, exact by construction ("IncomingDlogDirect"; the
     CF303 transfer is of this kind: 12 prime images cost 36 s of a 47 s
     run).  "IncomingRoute" -> "Modular" forces the sealed circuit (the
     cross-check). *)
  directQ = OptionValue["IncomingRoute"] =!= "Modular" && AllTrue[coefficients, FreeQ[#, u] &];
  If[directQ,
    (* every letter decomposed ONCE over the pole-factor alphabet (the
       irreducible monic factors over Q), so that a reducible GPLFactor
       polynomial -- 9/16 - u^2 = -(u - 3/4)(u + 3/4) on CF303 at p = 9/8 --
       lands on the same letters as in the modular route (run 7 keyed it
       whole and counted different words, 2026-09-02 18:53) *)
    letterDecomposition[letter_] := letterDecomposition[letter] = Module[{a, terms, out = <||>},
      a = Apart[rationalLayerLetterFunction[letter, u], u];
      terms = If[Head[a] === Plus, List @@ a, {a}];
      Do[With[{den = Denominator[Together[term]]},
          With[{factor = SelectFirst[factors, PolynomialRemainder[den, #, u] === 0 &, None]},
            If[factor === None, Throw[<|"Status" -> "ResiduePoleNotInAlphabet", "Letter" -> letter|>]];
            With[{r = PolynomialRemainder[Together[term factor], factor, u]},
              out[factor] = Lookup[out, factor, 0] + r]]],
        {term, terms}];
      Association@KeyValueMap[#1 -> PadRight[CoefficientList[Together[#2], u], Exponent[#1, u], 0] &, out]];
    reconstructed = <||>;
    Do[With[{series = laurentCoefficient[entry["Coefficient"]], decomposition = letterDecomposition[entry["Letter"]]},
        Do[If[series[[k]] =!= 0,
            KeyValueMap[Function[{factor, list},
              Do[If[list[[kk]] =!= 0,
                  Module[{key = {orders[[k]], factor, kk - 1}, matrix},
                    matrix = Lookup[reconstructed, Key[key], ConstantArray[0, {d, n}]];
                    matrix[[entry["Row"], entry["Column"]]] += series[[k]] list[[kk]];
                    reconstructed[key] = matrix]],
                {kk, Length[list]}]], decomposition]],
          {k, Length[orders]}]],
      {entry, incoming}];
    reconstructed = Select[reconstructed, ! AllTrue[Flatten[#], # === 0 &] &];
    keys = Keys[reconstructed];
    If[keys === {}, fail["LayerResiduesVanish", <|"Window" -> {low, high}|>]];
    primes = {}; freshPrime = None; images = {}; comparisons = Length[keys] d n; mismatches = 0;
    If[verbose, observableTransportMilestone["Rational layer: incoming connection is dlog with path-free coefficients: ",
      Length[keys], " exact residue keys, no modular image, ", Round[AbsoluteTime[] - start, 0.1], " s"]]];
  (* primes *)
  seed = OptionValue["Seed"];
  If[! directQ,
  (* the prime schedule: a seeded sequence; images are added until every
     residue reconstructs (lift-and-verify) or the maximum count is reached
     -- the CF303 transfer carries 58-digit numerators over 28-digit
     denominators, which three 31-bit primes cannot reconstruct
     (ReconstructionNotConverged, 2026-09-02 18:41) *)
  primes = Replace[OptionValue["Primes"], Automatic :> BlockRandom[SeedRandom[seed];
    Table[RandomPrime[{2^30, 2^31 - 1}], {OptionValue["MaximumPrimeCount"] + 1}]]];
  If[! MatchQ[primes, {__Integer}] || Length[primes] < 3 || ! DuplicateFreeQ[primes], fail["InvalidPrimeSchedule"]];
  freshPrime = Last[primes]; primes = Most[primes];
  images = {}; reconstructed = <||>; keys = {};
  Module[{needed = Min[OptionValue["PrimeCount"], Length[primes]], converged = False, lifted, usedPrimes,
     failingKey = None, failingEntry = None, failingResidues = None},
    While[! converged,
      Do[With[{p = primes[[k]]},
          AppendTo[images, rationalLayerRecurrenceImage[laurent, diagonal, source, factors, u, base, orders, p]];
          If[Last[images]["Status"] =!= "RecurrenceImageEvaluated",
            fail[Last[images]["Status"], <|"Prime" -> p|>]]],
        {k, Length[images] + 1, needed}];
      usedPrimes = Take[primes, Length[images]];
      keys = Union @@ (Keys[#["KResidues"]] & /@ images);
      If[keys === {}, fail["LayerResiduesVanish", <|"Window" -> {low, high},
        "Reason" -> "no nonzero K residue at any order of the window on any prime"|>]];
      reconstructed = <||>; converged = True;
      Do[
        lifted = Table[Table[
            With[{residues = Table[Lookup[images[[pi]]["KResidues"], Key[key], ConstantArray[0, {d, n}]][[i, j]], {pi, Length[images]}]},
              With[{crt = modularCRT[residues, usedPrimes]},
                If[crt === $Failed, $Failed, modularRationalReconstruct[crt, Times @@ usedPrimes]]]],
            {j, n}], {i, d}];
        If[! FreeQ[lifted, $Failed],
          converged = False;
          failingKey = key; failingEntry = First[Position[lifted, $Failed, {2}, 1]];
          failingResidues = Table[Lookup[images[[pi]]["KResidues"], Key[key], ConstantArray[0, {d, n}]][[failingEntry[[1]], failingEntry[[2]]]], {pi, Length[images]}];
          Break[]];
        reconstructed[key] = lifted,
        {key, keys}];
      If[! converged,
        If[needed >= Length[primes],
          fail["ReconstructionNotConverged", <|"PrimeCount" -> Length[images],
            "MaximumPrimeCount" -> OptionValue["MaximumPrimeCount"],
            "Key" -> failingKey, "Entry" -> failingEntry, "Residues" -> failingResidues,
            "Primes" -> usedPrimes|>]];
        needed = Min[needed + Max[1, Ceiling[needed/2]], Length[primes]]]];
    primes = usedPrimes];
  If[verbose, observableTransportMilestone["Rational layer: ", Length[primes], " prime images of the recurrence, ",
    Length[keys], " residue keys reconstructed, ", Round[AbsoluteTime[] - start, 0.1], " s"]];
  (* fresh-prime validation *)
  freshImage = rationalLayerRecurrenceImage[laurent, diagonal, source, factors, u, base, orders, freshPrime];
  If[freshImage["Status"] =!= "RecurrenceImageEvaluated", fail[freshImage["Status"], <|"Prime" -> freshPrime|>]];
  Do[
    With[{image = Lookup[freshImage["KResidues"], Key[key], ConstantArray[0, {d, n}]], exact = reconstructed[key]},
      Do[comparisons++;
        If[Mod[Numerator[exact[[i, j]]] - image[[i, j]] Denominator[exact[[i, j]]], freshPrime] =!= 0, mismatches++],
        {i, d}, {j, n}]],
    {key, Union[keys, Keys[freshImage["KResidues"]]]}];
  If[mismatches > 0, fail["FreshPrimeValidationFailed", <|"Mismatches" -> mismatches, "Comparisons" -> comparisons|>]];
  ];   (* end of the modular route *)
  hImageCount = If[images === {}, 0, Total[Length /@ Lookup[images, "HImages"]]];
  (* demanded words *)
  maximumWeight = OptionValue["MaximumWeight"];
  sourceBoundaryCount = Length[First[Values[source["BoundarySelectors"]]][[1]]];
  targetSelectors = Lookup[layer, "TargetBoundarySelectors", Association@Table[q -> IdentityMatrix[d], {q, 0, 0}]];
  targetBoundaryCount = Total[Length[First[#]] & /@ Values[targetSelectors]];
  targetSelectors = With[{offsets = Accumulate[Prepend[Length[First[#]] & /@ Values[targetSelectors], 0]]},
    Association@MapIndexed[Function[{q, index},
      q -> (PadRight[PadLeft[#, offsets[[First[index]]] + Length[#]], targetBoundaryCount] & /@ targetSelectors[q])],
      Keys[targetSelectors]]];
  (* maximal tail weight per boundary order: order - q - r over the demanded
     orders and the incoming orders present *)
  weightByOrder = With[{incomingOrders = DeleteDuplicates[First /@ keys]},
    Association@Table[q -> Max[Flatten[Table[pair[[1]] - q - r, {pair, demandPairs}, {r, incomingOrders}]]],
      {q, Keys[source["BoundarySelectors"]]}]];
  sourceStates = rationalLayerSourceStates[source, maximumWeight, weightByOrder];
  If[verbose, observableTransportMilestone["Rational layer: source words grown to weight ", maximumWeight, ": ",
    Total[Length /@ Flatten[Values[sourceStates], 1]], " states, ", Round[AbsoluteTime[] - start, 0.1], " s"]];
  words = Association@Table[pair -> rationalLayerWords[pair[[1]], pair[[2]], diagonal, reconstructed, source,
      targetSelectors, sourceBoundaryCount, targetBoundaryCount, maximumWeight, OptionValue["MaximumWords"], sourceStates], {pair, demandPairs}];
  If[verbose, observableTransportMilestone["Rational layer: demanded words ",
    Total[If[AssociationQ[#], Length[#["Words"]], Length[#]] & /@ Values[words]],
    If[AnyTrue[Values[words], AssociationQ], " (some pairs capped)", ""], ", ", Round[AbsoluteTime[] - start, 0.1], " s"]];
  certificate = <|"Status" -> "RationalEpsilonLayerTransportAccepted",
    "IncomingRoute" -> If[directQ, "IncomingDlogDirect", "SealedModularCircuit"],
    "Probabilistic" -> ! directQ, "Exact" -> directQ,
    "Primes" -> primes, "FreshValidationPrime" -> freshPrime,
    "ResidueComparisons" -> comparisons, "ResidueMismatches" -> mismatches,
    "ReconstructedResidueKeys" -> Length[keys],
    "GaugeImages" -> hImageCount,
    "GaugeReconstructed" -> False,
    "Alphabet" -> gate["Verdicts"],
    "PoleFactors" -> factors,
    "Valuations" -> valuations,
    "Window" -> {low, high},
    "Seed" -> seed|>;
  <|"Status" -> "RationalEpsilonLayerTransportAccepted",
    "Rows" -> rows, "PathVariable" -> u, "Regulator" -> eps, "BasePoint" -> base,
    "Window" -> {low, high},
    "KResidues" -> reconstructed,
    "GaugeImages" -> If[directQ, <||>, Association@Table[primes[[pi]] -> images[[pi]]["HImages"], {pi, Length[primes]}]],
    "GaugeStatus" -> If[directQ, "GaugeVanishes", "GaugeNotReconstructed"],
    "DemandedWords" -> words,
    "BoundaryColumns" -> sourceBoundaryCount + targetBoundaryCount,
    "Certificate" -> certificate,
    "Seconds" -> N[AbsoluteTime[] - start]|>
];

rationalLayerCertificateShapeQ[certificate_] := AssociationQ[certificate] &&
  Lookup[certificate, "Status", None] === "RationalEpsilonLayerTransportAccepted" &&
  MatchQ[Lookup[certificate, "Alphabet", None], {__Association}] &&
  AllTrue[certificate["Alphabet"], #["Status"] === "Admitted" &] &&
  IntegerQ[Lookup[certificate, "ResidueComparisons", None]] &&
  certificate["ResidueComparisons"] > 0 &&
  Lookup[certificate, "ResidueMismatches", -1] === 0 &&
  Which[
    Lookup[certificate, "IncomingRoute", None] === "SealedModularCircuit",
      TrueQ[certificate["Probabilistic"]] && TrueQ[certificate["Exact"] === False] &&
      MatchQ[Lookup[certificate, "Primes", None], {__Integer}] &&
      IntegerQ[Lookup[certificate, "FreshValidationPrime", None]] &&
      ! MemberQ[certificate["Primes"], certificate["FreshValidationPrime"]],
    Lookup[certificate, "IncomingRoute", None] === "IncomingDlogDirect",
      TrueQ[certificate["Exact"]] && certificate["Probabilistic"] === False,
    True, False];

AcceptedRationalEpsilonLayerTransportQ[result_] := AssociationQ[result] &&
  Lookup[result, "Status", None] === "RationalEpsilonLayerTransportAccepted" &&
  rationalLayerCertificateShapeQ[Lookup[result, "Certificate", None]] &&
  AssociationQ[Lookup[result, "KResidues", None]] &&
  AssociationQ[Lookup[result, "DemandedWords", None]] &&
  MemberQ[{"GaugeNotReconstructed", "GaugeVanishes"}, Lookup[result, "GaugeStatus", None]];
AcceptedRationalEpsilonLayerTransportQ[___] := False;
