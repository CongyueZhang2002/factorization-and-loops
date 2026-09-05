(* Variation-of-constants solution of a block whose incoming connection is rational in the
   regulator.

   System dF = A F, A = [[S, 0], [B, D]] on a one-dimensional path in the
   variable u: the source connection S = eps Sum S_i w_i and the target-block
   diagonal connection D = eps Sum D_a w_a is dlog with constant residue
   matrices; the incoming connection B(eps, u) = Sum_n eps^n B_n(u) du is a
   rational function of eps whose orders are rational one-forms that are
   NOT dlog.  The off-diagonal basis-transformation block in
   F_T = G + H F_S, normalized by H(base) = 0, removes the
   non-dlog part order by order,

     K_n = B_n + D_1 H_(n-1) - H_(n-1) S_1 - dH_n,   K_n dlog,

   H_n the Hermite primitive of Omega_n = B_n + D_1 H_(n-1) - H_(n-1) S_1
   and K_n its residue part on the declared pole alphabet; G then obeys
   dG = D G + K F_S.  The requested coefficients of F_T contain D...D
   K_r S...S, D...D acting on target boundary data, and H_r S...S from
   the final basis transformation F_T=G+H F_S.
   A genuinely u-dependent recurrence is executed as a sealed circuit over
   F_q[u]: leaves are specialized first, K and the endpoint value of H are
   reconstructed across primes and validated at a fresh prime.  If all
   incoming coefficients are independent of u, the exact dlog residues are
   read directly and H vanishes.  Singular endpoints remain a typed refusal
   until tangential regularization data are implemented.  On a declared
   square-free quartic Y^2=P4, the same modular recurrence uses coefficient
   pairs for h0+h1 Y and f0 du+f1 du/Y and reduces the elliptic component to
   square-free pole letters plus the three genus-one cohomology letters.
   No family name appears here. *)

Clear[SolveRationalEpsilonDependentBlockByVariationOfConstants,
  RationalEpsilonDependentBlockSolutionQ,
  VerifyRationalEpsilonDependentBlockSolution];
ClearAll[
  rationalEpsilonDependentBlockLetterFormQ,
  rationalEpsilonDependentBlockCurveLetterFormQ,
  rationalEpsilonDependentBlockLetterFunction,
  rationalEpsilonDependentBlockLetterPair,
  rationalEpsilonDependentBlockCurvePointValue,
  rationalEpsilonDependentBlockResidueKey,
  rationalEpsilonDependentBlockResidueLabel,
  rationalEpsilonDependentBlockAlphabetGate,
  rationalEpsilonDependentBlockPoleFactors,
  rationalEpsilonDependentBlockModularFunction,
  rationalEpsilonDependentBlockModularPolynomial,
  rationalEpsilonDependentBlockReconstructFunction,
  rationalEpsilonDependentBlockOffDiagonalTransformationFunctionCheck,
  rationalEpsilonDependentBlockHermite,
  rationalEpsilonDependentBlockEllipticHermite,
  rationalEpsilonDependentBlockPartialFractions,
  rationalEpsilonDependentBlockRecurrenceImage,
  rationalEpsilonDependentBlockCurveRecurrenceImage,
  rationalEpsilonDependentBlockSourceStates,
  rationalEpsilonDependentBlockTargetSelectors,
  rationalEpsilonDependentBlockIteratedIntegralCoefficientTerms,
  rationalEpsilonDependentBlockCertificateShapeQ,
  $rationalEpsilonDependentBlockCurveLetters,
  $rationalEpsilonDependentBlockRationalLetters
];

$rationalEpsilonDependentBlockRationalLetters = {"GPLPole", "GPLFactor"};
$rationalEpsilonDependentBlockCurveLetters = {"E4Pole", "E4Factor", "E4Omega0", "E4OmegaInf", "E4Eta2"};

(* ---- alphabet ------------------------------------------------------- *)

(* A letter label: {"GPLPole", c} is du/(u - c); {"GPLFactor", q, k} is
   u^k du/q(u) with q square-free and k < deg q.  Curve letters are
   recognised, and admitted only with a declared quartic curve. *)
(* A pole position must be rational.  Algebraic conjugates are represented
   root-free by one GPLFactor letter on their minimal polynomial. *)
rationalEpsilonDependentBlockLetterFormQ[{"GPLPole", c_}, u_] := MatchQ[c, _Integer | _Rational];
rationalEpsilonDependentBlockLetterFormQ[{"GPLFactor", q_, k_Integer}, u_] :=
  PolynomialQ[q, u] && Exponent[q, u] >= 1 && 0 <= k < Exponent[q, u] &&
  VectorQ[CoefficientList[q, u], MatchQ[#, _Integer | _Rational] &] &&
  Exponent[PolynomialGCD[q, D[q, u]], u] === 0;
rationalEpsilonDependentBlockLetterFormQ[___] := False;

rationalEpsilonDependentBlockCurveLetterFormQ[{"E4Pole", c_}, _] :=
  MatchQ[c, _Integer | _Rational];
rationalEpsilonDependentBlockCurveLetterFormQ[{"E4Factor", q_, k_Integer}, u_] :=
  rationalEpsilonDependentBlockLetterFormQ[{"GPLFactor", q, k}, u];
rationalEpsilonDependentBlockCurveLetterFormQ[{"E4Omega0"}, _] := True;
rationalEpsilonDependentBlockCurveLetterFormQ[{"E4OmegaInf"}, _] := True;
rationalEpsilonDependentBlockCurveLetterFormQ[{"E4Eta2"}, _] := True;
rationalEpsilonDependentBlockCurveLetterFormQ[___] := False;

rationalEpsilonDependentBlockLetterFunction[{"GPLPole", c_}, u_] := 1/(u - c);
rationalEpsilonDependentBlockLetterFunction[{"GPLFactor", q_, k_Integer}, u_] := u^k/q;

(* A function is h0+h1 Y and a one-form is f0 du+f1 du/Y.  Pair entries
   below are their rational coefficient functions {base, elliptic}. *)
rationalEpsilonDependentBlockLetterPair[label : {head_, ___}, u_, curve_, pointValues_Association] /;
    MemberQ[$rationalEpsilonDependentBlockRationalLetters, head] :=
  {rationalEpsilonDependentBlockLetterFunction[label, u], 0};
rationalEpsilonDependentBlockLetterPair[{"E4Factor", q_, k_Integer}, u_, _, _] := {0, u^k/q};
rationalEpsilonDependentBlockLetterPair[{"E4Pole", c_}, u_, _, pointValues_Association] :=
  {0, Lookup[pointValues, c, Missing["CurvePointValue", c]]/(u - c)};
rationalEpsilonDependentBlockLetterPair[{"E4Omega0"}, _, _, _] := {0, 1};
rationalEpsilonDependentBlockLetterPair[{"E4OmegaInf"}, u_, _, _] := {0, u};
rationalEpsilonDependentBlockLetterPair[{"E4Eta2"}, u_, curve_, _] :=
  {0, u^2 + Coefficient[curve, u, 3] u/(2 Coefficient[curve, u, 4])};

rationalEpsilonDependentBlockCurvePointValue[point_, curve_, u_, declared_Association] := Module[
  {value = Together[curve /. u -> point], candidate},
  candidate = Lookup[declared, point, Automatic];
  If[candidate === Automatic, candidate = Sqrt[value]];
  If[! MatchQ[candidate, _Integer | _Rational] ||
      Together[candidate^2 - value] =!= 0,
    Missing["CurvePointValue", point], candidate]
];

(* Rational keys use {order,factor,power}. Curve letters are opaque in the
   second slot and use the same three-field representation, so lazy consumers
   can distinguish the channels without expanding polynomial factors into
   marked points. *)
rationalEpsilonDependentBlockResidueKey[order_, {"GPLFactor", factor_, power_Integer}] :=
  {order, factor, power};
rationalEpsilonDependentBlockResidueKey[order_, label_List] := {order, label, 0};
rationalEpsilonDependentBlockResidueLabel[{_, factor_, power_Integer}] /; ! ListQ[factor] :=
  {"GPLFactor", factor, power};
rationalEpsilonDependentBlockResidueLabel[{_, label_List, _Integer}] := label;

rationalEpsilonDependentBlockAlphabetGate[labels_List, u_Symbol, curve_] := Module[
  {verdicts},
  verdicts = Table[Which[
      ! ListQ[label] || label === {},
        <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
          "Reason" -> "not a labelled letter"|>,
      MemberQ[$rationalEpsilonDependentBlockRationalLetters, First[label]],
        Which[
          rationalEpsilonDependentBlockLetterFormQ[label, u],
            <|"Label" -> label, "Status" -> "Admitted", "Channel" -> "Rational"|>,
          MatchQ[label, {"GPLPole", c_ /; NumericQ[c] && ! MatchQ[c, _Integer | _Rational]}],
            <|"Label" -> label, "Status" -> "AlgebraicPoleNotAdmitted",
              "Reason" -> "pole position is algebraic; declare the conjugate pair as a GPLFactor letter on its minimal polynomial"|>,
          True,
            <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
              "Reason" -> "malformed rational letter (pole must be a rational number, factor square-free with rational coefficients, power below the degree)"|>],
      MemberQ[$rationalEpsilonDependentBlockCurveLetters, First[label]],
        Which[
          curve === None,
            <|"Label" -> label, "Status" -> "CurveDeclarationRequired"|>,
          ! PolynomialQ[curve, u] || Exponent[curve, u] =!= 4 ||
            ! VectorQ[CoefficientList[curve, u], MatchQ[#, _Integer | _Rational] &] ||
            Exponent[PolynomialGCD[curve, D[curve, u]], u] =!= 0,
            <|"Label" -> label, "Status" -> "CurveNotQuartic",
              "Reason" -> "the declared curve must be a square-free quartic polynomial in the path variable"|>,
          ! rationalEpsilonDependentBlockCurveLetterFormQ[label, u],
            <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
              "Reason" -> "malformed elliptic letter"|>,
          True,
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
rationalEpsilonDependentBlockPoleFactors[letters_List, coefficients_List, u_Symbol] := Module[
  {polynomials, factors},
  polynomials = Join[
    Cases[letters, {"GPLPole", c_} :> u - c],
    Cases[letters, {"GPLFactor", q_, _} :> q],
    Cases[letters, {"E4Pole", c_} :> u - c],
    Cases[letters, {"E4Factor", q_, _} :> q],
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
rationalEpsilonDependentBlockModularFunction[expression_, u_Symbol, prime_Integer] := Module[
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
(* A polynomial over Q reduced into F_q coefficient by coefficient; built-in
   modulus arithmetic does not consistently normalize rational coefficients. *)
rationalEpsilonDependentBlockModularPolynomial[expression_, u_Symbol, prime_Integer] := Module[
  {coefficients = CoefficientList[Expand[expression], u]},
  If[MemberQ[Mod[Denominator /@ coefficients, prime], 0], Return[$Failed]];
  Expand[Total[MapIndexed[
    Mod[Numerator[#1] PowerMod[Denominator[#1], -1, prime], prime] u^(First[#2] - 1) &,
    coefficients]]]
];

(* Lift one monic rational-function image from several primes.  Hermite
   primitives are stored as {numerator,monic denominator}, so their
   polynomial coefficients have a common, prime-independent normalization.
   This is used only when the path endpoint must remain symbolic. *)
rationalEpsilonDependentBlockReconstructFunction[images : {{_, _} ..}, primes : {__Integer},
    u_Symbol] := Module[
  {numeratorDegree, denominatorDegree, lift, numeratorCoefficients,
   denominatorCoefficients, numerator, denominator},
  If[Length[images] =!= Length[primes], Return[$Failed]];
  If[AllTrue[images, #[[1]] === 0 &], Return[0]];
  numeratorDegree = Max[Exponent[#[[1]], u] & /@ images];
  denominatorDegree = Max[Exponent[#[[2]], u] & /@ images];
  lift[part_, degree_] := Table[
    With[{residues = Table[Coefficient[images[[index, part]], u, power],
        {index, Length[images]}]},
      With[{crt = modularCRT[residues, primes]},
        If[crt === $Failed, $Failed,
          modularRationalReconstruct[crt, Times @@ primes]]]],
    {power, 0, degree}];
  numeratorCoefficients = lift[1, numeratorDegree];
  denominatorCoefficients = lift[2, denominatorDegree];
  If[! FreeQ[{numeratorCoefficients, denominatorCoefficients}, $Failed],
    Return[$Failed]];
  numerator = numeratorCoefficients . u^Range[0, numeratorDegree];
  denominator = denominatorCoefficients . u^Range[0, denominatorDegree];
  If[denominator === 0, $Failed, numerator/denominator]
];
rationalEpsilonDependentBlockReconstructFunction[___] := $Failed;

(* One held-out prime and one regular random point validate the reconstructed
   off-diagonal transformation block.
   This is deliberately pointwise: production does not rematerialize a
   characteristic-zero polynomial identity merely to check the lift. *)
rationalEpsilonDependentBlockOffDiagonalTransformationFunctionCheck[exact_Association, image_Association,
    orders_List, u_Symbol, prime_Integer, seed_Integer] := Module[
  {points, point = None, exactValue, imageValue, comparisons = 0,
   mismatches = 0, regularQ},
  points = BlockRandom[SeedRandom[seed + prime];
    RandomInteger[{2, prime - 2}, 32]];
  regularQ[candidate_] := And @@ Flatten@Table[
    With[{e = exact[order][[i, j]], f = image[order][[i, j]]},
      Mod[Denominator[Together[e]] /. u -> candidate, prime] =!= 0 &&
      Mod[f[[2]] /. u -> candidate, prime] =!= 0],
    {order, orders}, {i, Length[exact[order]]},
    {j, Length[First[exact[order]]]}];
  point = SelectFirst[points, regularQ, None];
  If[point === None,
    Return[<|"Status" -> "OffDiagonalTransformationBlockValidationPointUnavailable"|>]];
  Do[
    exactValue = With[{value = Together[exact[order][[i, j]]] /. u -> point},
      Mod[Numerator[value] PowerMod[Denominator[value], -1, prime], prime]];
    imageValue = With[{f = image[order][[i, j]]},
      Mod[(f[[1]] /. u -> point) PowerMod[f[[2]] /. u -> point, -1, prime],
        prime]];
    comparisons++;
    If[exactValue =!= imageValue, mismatches++],
    {order, orders}, {i, Length[exact[order]]},
    {j, Length[First[exact[order]]]}];
  <|"Status" -> "OffDiagonalTransformationBlockChecked", "Point" -> point,
    "Comparisons" -> comparisons, "Mismatches" -> mismatches|>
];

(* Hermite reduction over F_q (Horowitz-Ostrogradsky): f = N/D proper ->
   f = d(Bp/Dstar)/du + C/Dminus with Dminus square-free; the polynomial
   part is integrated separately.  Returns <|"Primitive" -> {Bp, Dstar}
   plus polynomial primitive, "Remainder" -> {C, Dminus}|> or $Failed. *)
rationalEpsilonDependentBlockHermite[{numerator_, denominator_}, u_Symbol, prime_Integer] := Module[
  {quotient, remainder, dStar, dMinus, m, n, bSym, cSym, unknowns, tSym,
   equation, solution, bPoly, cPoly, polynomialPrimitive, coefficients},
  {quotient, remainder} = PolynomialQuotientRemainder[numerator, denominator, u, Modulus -> prime];
  polynomialPrimitive = If[quotient === 0, 0,
    PolynomialMod[Integrate[quotient, u] /. Rational[a_, b_] :> Mod[a PowerMod[b, -1, prime], prime], prime]];
  If[Exponent[denominator, u] === 0,
    Return[<|"Primitive" -> {polynomialPrimitive, 1}, "Remainder" -> {0, 1}|>]];
  dStar = PolynomialGCD[denominator, D[denominator, u], Modulus -> prime];
  dStar = PolynomialMod[dStar PowerMod[Coefficient[dStar, u, Exponent[dStar, u]], -1, prime], prime];   (* monic, asserted rather than assumed *)
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

(* Elliptic Hermite reduction on Y^2=P(u).  For f du/Y, find g and a
   square-free-pole remainder plus the three genus-one cohomology classes,

     f = P g' + P' g/2 + r/q + c0 + c1 u + c2 u^2  (mod prime),

   so that g Y is the primitive.  The reduction depends only on the quartic
   and rational-function data. *)
rationalEpsilonDependentBlockEllipticHermite[{numeratorInput_, denominatorInput_}, curve_,
    u_Symbol, prime_Integer] := Module[
  {numerator, denominator, common, lead, branchGCD, repeated, squarefree,
   repeatedDegree, squarefreeDegree, quotient, polynomialDegree,
   polynomialPrimitiveCount, commonDenominator, target, inverseTwo,
   bSymbols, rSymbols, pSymbols, cSymbols, unknowns, bPolynomial,
   rPolynomial, pPolynomial, cPolynomial, operator, equation,
   coefficients, solutions, solution, primitiveNumerator, identity},
  numerator = PolynomialMod[numeratorInput, prime];
  denominator = PolynomialMod[denominatorInput, prime];
  If[denominator === 0,
    Return[<|"Status" -> "EllipticHermiteDenominatorZero"|>]];
  If[numerator === 0,
    Return[<|"Status" -> "EllipticHermiteReduced",
      "Primitive" -> {0, 1}, "ProperRemainder" -> {0, 1},
      "Cohomology" -> {0, 0, 0}|>]];
  common = PolynomialGCD[numerator, denominator, Modulus -> prime];
  numerator = PolynomialQuotient[numerator, common, u, Modulus -> prime];
  denominator = PolynomialQuotient[denominator, common, u, Modulus -> prime];
  lead = Coefficient[denominator, u, Exponent[denominator, u]];
  numerator = PolynomialMod[numerator PowerMod[lead, -1, prime], prime];
  denominator = PolynomialMod[denominator PowerMod[lead, -1, prime], prime];
  branchGCD = PolynomialGCD[denominator, curve, Modulus -> prime];
  If[Exponent[branchGCD, u] > 0,
    Return[<|"Status" -> "CurveBranchPoleNotSupported",
      "Factor" -> branchGCD|>]];
  repeated = PolynomialGCD[denominator, D[denominator, u], Modulus -> prime];
  repeated = PolynomialMod[repeated PowerMod[
    Coefficient[repeated, u, Exponent[repeated, u]], -1, prime], prime];
  squarefree = PolynomialQuotient[denominator, repeated, u, Modulus -> prime];
  squarefree = PolynomialMod[squarefree PowerMod[
    Coefficient[squarefree, u, Exponent[squarefree, u]], -1, prime], prime];
  repeatedDegree = Exponent[repeated, u];
  squarefreeDegree = Exponent[squarefree, u];
  quotient = PolynomialQuotient[numerator, denominator, u, Modulus -> prime];
  polynomialDegree = If[quotient === 0, -1, Exponent[quotient, u]];
  polynomialPrimitiveCount = Max[0, polynomialDegree - 2];
  commonDenominator = PolynomialLCM[denominator, repeated^2, Modulus -> prime];
  commonDenominator = PolynomialLCM[commonDenominator, squarefree, Modulus -> prime];
  target = PolynomialMod[numerator PolynomialQuotient[
    commonDenominator, denominator, u, Modulus -> prime], prime];
  inverseTwo = PowerMod[2, -1, prime];
  bSymbols = Array[Unique["e4B"] &, repeatedDegree];
  rSymbols = Array[Unique["e4R"] &, squarefreeDegree];
  pSymbols = Array[Unique["e4P"] &, polynomialPrimitiveCount];
  cSymbols = Array[Unique["e4C"] &, 3];
  unknowns = Join[bSymbols, rSymbols, pSymbols, cSymbols];
  bPolynomial = If[bSymbols === {}, 0, bSymbols . u^Range[0, repeatedDegree - 1]];
  rPolynomial = If[rSymbols === {}, 0, rSymbols . u^Range[0, squarefreeDegree - 1]];
  pPolynomial = If[pSymbols === {}, 0, pSymbols . u^Range[0, polynomialPrimitiveCount - 1]];
  cPolynomial = cSymbols . {1, u, u^2};
  operator[g_] := Expand[curve D[g, u] + inverseTwo D[curve, u] g];
  equation = Expand[
    (curve (D[bPolynomial, u] repeated - bPolynomial D[repeated, u]) +
        inverseTwo D[curve, u] bPolynomial repeated)
        PolynomialQuotient[commonDenominator, repeated^2, u, Modulus -> prime] +
      rPolynomial PolynomialQuotient[commonDenominator, squarefree, u, Modulus -> prime] +
      operator[pPolynomial] commonDenominator + cPolynomial commonDenominator - target];
  coefficients = CoefficientList[equation, u];
  solutions = Quiet[Check[Solve[Thread[coefficients == 0], unknowns,
      Modulus -> prime], $Failed]];
  If[solutions === $Failed || solutions === {},
    Return[<|"Status" -> "EllipticHermiteReductionUndecided"|>]];
  solution = First[solutions];
  If[! FreeQ[unknowns /. solution, Alternatives @@ unknowns],
    Return[<|"Status" -> "EllipticHermiteReductionUnderdetermined"|>]];
  primitiveNumerator = PolynomialMod[(bPolynomial + pPolynomial repeated) /. solution, prime];
  rPolynomial = PolynomialMod[rPolynomial /. solution, prime];
  cSymbols = Mod[cSymbols /. solution, prime];
  identity = PolynomialMod[equation /. solution, prime];
  If[identity =!= 0,
    Return[<|"Status" -> "EllipticHermiteIdentityFailed"|>]];
  <|"Status" -> "EllipticHermiteReduced",
    "Primitive" -> {primitiveNumerator, repeated},
    "ProperRemainder" -> {rPolynomial, squarefree},
    "Cohomology" -> cSymbols|>
];

(* C/Dminus on the declared coprime pole factors: C/Dminus = Sum_j r_j/q_j,
   deg r_j < deg q_j; a factor of Dminus outside the alphabet is $Failed. *)
rationalEpsilonDependentBlockPartialFractions[{c_, dMinus_}, factors_List, u_Symbol, prime_Integer] := Module[
  {reduced = dMinus, present = {}, result = <||>, cofactor, gcd, inverse, r, modular, image},
  If[c === 0, Return[<||>]];
  (* the declared factors reduced into F_q, keyed by the original factor *)
  modular = Association@Table[factor -> rationalEpsilonDependentBlockModularPolynomial[factor, u, prime], {factor, factors}];
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
rationalEpsilonDependentBlockRecurrenceImage[laurent_Association, diagonal_List, source_Association,
    factors_List, u_Symbol, base_, orders_List, prime_Integer, endpoint_: None] := Module[
  {d, n, letterFunctions, hPrevious, h, k, omega, entryValue, hermite, fractions,
   value, evaluateAt, hImages = <||>, kResidues = <||>, failure = None,
   diagonalForms, sourceForms, dEntry, sEntry, fixed, hEntry, hEndpoint = <||>, endpointValues},
  (* Rows and columns are read from the Laurent matrix, not from a scalar
     entry's expression tree. *)
  {d, n} = Dimensions[Lookup[laurent, First[orders]]][[1 ;; 2]];
  If[n =!= source["Dimension"],
    Return[<|"Status" -> "BlockDimensionMismatch", "Prime" -> prime,
      "Columns" -> n, "SourceDimension" -> source["Dimension"]|>]];
  diagonalForms = ({rationalEpsilonDependentBlockLetterFunction[#[[1]], u], #[[2]]} &) /@ diagonal;
  sourceForms = MapThread[{rationalEpsilonDependentBlockLetterFunction[#1, u], #2} &,
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
        rationalEpsilonDependentBlockModularFunction[Total[terms], u, prime]],
      {i, d}, {j, n}];
    If[! FreeQ[omega, $Failed], failure = "CoefficientNotDefinedAtPrime"; Break[]];
    h = ConstantArray[{0, 1}, {d, n}];
    Do[
      hermite = rationalEpsilonDependentBlockHermite[omega[[i, j]], u, prime];
      If[hermite === $Failed, failure = "HermiteReductionUndecided"; Break[]];
      fractions = rationalEpsilonDependentBlockPartialFractions[hermite["Remainder"], factors, u, prime];
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
    (* S3: the off-diagonal block H_n(u1) at the path endpoint modulo the prime; a
       denominator vanishing there makes the prime bad (skipped by the
       caller), not the route wrong *)
    If[endpoint =!= None,
      endpointValues = Map[Module[{image, dv, nv},
          image[r_] := Mod[Numerator[r] PowerMod[Denominator[r], -1, prime], prime];
          dv = image[#[[2]] /. u -> endpoint]; nv = image[#[[1]] /. u -> endpoint];
          If[dv === 0, $Failed, Mod[nv PowerMod[dv, -1, prime], prime]]] &, h, {2}];
      If[! FreeQ[endpointValues, $Failed],
        failure = "PathEndpointOnPoleAtPrime"; Break[]];
      hEndpoint[order] = endpointValues];
    hPrevious = h,
    {order, orders}];
  If[failure =!= None, Return[<|"Status" -> failure, "Prime" -> prime|>]];
  <|"Status" -> "RecurrenceImageEvaluated", "Prime" -> prime,
    "KResidues" -> kResidues, "HImages" -> hImages,
    "OffDiagonalBasisTransformationBlockAtPathEndpointFiniteFieldValuesByEpsilonOrder" ->
      hEndpoint|>
];

(* Quartic-curve recurrence.  Matrix entries of h are coefficient pairs for
   h0+h1 Y; form entries are pairs for f0 du+f1 du/Y.  Their product is

     (h0 f0+h1 f1) du + (h0 f1+P h1 f0) du/Y,

   while d(h1 Y)=(P h1'+P' h1/2)du/Y. *)
rationalEpsilonDependentBlockCurveRecurrenceImage[laurent_Association, diagonal_List,
    source_Association, factors_List, u_Symbol, curve_, pointValues_Association,
    base_, baseY_, orders_List, prime_Integer, endpoint_, endpointY_] := Module[
  {d, n, curveImage, baseImage, endpointImage, baseYImage, endpointYImage, scalarImage, rf, product,
   diagonalForms, sourceForms, hPrevious, h, omega, rationalHermite,
   ellipticHermite, fractions, fixed, hEntry, hImages = <||>,
   hEndpoint = <||>, endpointValues, kResidues = <||>, failure = None,
   store, shift, cohomology, evaluateAt, root, rootValue, rootValueImage},
  {d, n} = Dimensions[Lookup[laurent, First[orders]]][[1 ;; 2]];
  If[n =!= source["Dimension"],
    Return[<|"Status" -> "BlockDimensionMismatch", "Prime" -> prime|>]];
  curveImage = rationalEpsilonDependentBlockModularPolynomial[curve, u, prime];
  If[curveImage === $Failed || Exponent[curveImage, u] =!= 4 ||
      Exponent[PolynomialGCD[curveImage, D[curveImage, u], Modulus -> prime], u] > 0,
    Return[<|"Status" -> "CurveDegeneratesAtPrime", "Prime" -> prime|>]];
  scalarImage[value_] := If[Mod[Denominator[value], prime] === 0, $Failed,
    Mod[Numerator[value] PowerMod[Denominator[value], -1, prime], prime]];
  baseImage = scalarImage[base]; endpointImage = scalarImage[endpoint];
  baseYImage = scalarImage[baseY]; endpointYImage = scalarImage[endpointY];
  If[MemberQ[{baseImage, endpointImage, baseYImage, endpointYImage}, $Failed],
    Return[<|"Status" -> "CurvePointNotDefinedAtPrime", "Prime" -> prime|>]];
  If[Mod[baseYImage^2 - (curveImage /. u -> baseImage), prime] =!= 0 ||
      Mod[endpointYImage^2 - (curveImage /. u -> endpointImage), prime] =!= 0,
    Return[<|"Status" -> "CurveSheetInconsistentAtPrime", "Prime" -> prime|>]];
  rf[{numerator_, denominator_}] := numerator/denominator;
  product[functionPair_, formPair_] := With[
    {h0 = rf[functionPair[[1]]], h1 = rf[functionPair[[2]]],
     f0 = formPair[[1]], f1 = formPair[[2]]},
    {h0 f0 + h1 f1, h0 f1 + curveImage h1 f0}];
  evaluateAt[{numerator_, denominator_}, point_] := Module[{pointImage, dv, nv},
    pointImage = scalarImage[point];
    If[pointImage === $Failed, Return[$Failed, Module]];
    dv = Mod[denominator /. u -> pointImage, prime];
    nv = Mod[numerator /. u -> pointImage, prime];
    If[dv === 0, $Failed, Mod[nv PowerMod[dv, -1, prime], prime]]];
  diagonalForms = ({rationalEpsilonDependentBlockLetterPair[#[[1]], u, curve, pointValues], #[[2]]} &) /@ diagonal;
  sourceForms = MapThread[{rationalEpsilonDependentBlockLetterPair[#1, u, curve, pointValues], #2} &,
    {source["Letters"], source["Residues"]}];
  If[! FreeQ[{diagonalForms, sourceForms}, _Missing],
    Return[<|"Status" -> "CurvePointValueRequired", "Prime" -> prime|>]];
  store[order_, label_, value_, i_, j_] := If[Mod[value, prime] =!= 0,
    Module[{key = rationalEpsilonDependentBlockResidueKey[order, label], matrix},
      matrix = Lookup[kResidues, Key[key], ConstantArray[0, {d, n}]];
      matrix[[i, j]] = Mod[matrix[[i, j]] + value, prime];
      kResidues[key] = matrix]];
  shift = Mod[Coefficient[curveImage, u, 3] PowerMod[
    Mod[2 Coefficient[curveImage, u, 4], prime], -1, prime], prime];
  hPrevious = ConstantArray[{{0, 1}, {0, 1}}, {d, n}];
  Do[
    omega = Table[Module[{terms = {{laurent[order][[i, j, 1]]},
          {laurent[order][[i, j, 2]]}}, term},
        Do[
          term = product[hPrevious[[l, j]], form[[1]]];
          AppendTo[terms[[1]], form[[2, i, l]] term[[1]]];
          AppendTo[terms[[2]], form[[2, i, l]] term[[2]]],
          {form, diagonalForms}, {l, d}];
        Do[
          term = product[hPrevious[[i, l]], form[[1]]];
          AppendTo[terms[[1]], -form[[2, l, j]] term[[1]]];
          AppendTo[terms[[2]], -form[[2, l, j]] term[[2]]],
          {form, sourceForms}, {l, n}];
        rationalEpsilonDependentBlockModularFunction[Total[#], u, prime] & /@ terms],
      {i, d}, {j, n}];
    If[! FreeQ[omega, $Failed], failure = "CoefficientNotDefinedAtPrime"; Break[]];
    h = ConstantArray[{{0, 1}, {0, 1}}, {d, n}];
    Do[
      rationalHermite = rationalEpsilonDependentBlockHermite[omega[[i, j, 1]], u, prime];
      If[rationalHermite === $Failed,
        failure = "HermiteReductionUndecided"; Break[]];
      fractions = rationalEpsilonDependentBlockPartialFractions[rationalHermite["Remainder"],
        factors, u, prime];
      If[fractions === $Failed, failure = "ResiduePoleNotInAlphabet"; Break[]];
      KeyValueMap[Function[{factor, list}, Do[
        store[order, {"GPLFactor", factor, kk - 1}, list[[kk]], i, j],
        {kk, Length[list]}]], fractions];
      ellipticHermite = rationalEpsilonDependentBlockEllipticHermite[omega[[i, j, 2]],
        curveImage, u, prime];
      If[Lookup[ellipticHermite, "Status", None] =!= "EllipticHermiteReduced",
        failure = Lookup[ellipticHermite, "Status", "EllipticHermiteReductionUndecided"];
        Break[]];
      fractions = rationalEpsilonDependentBlockPartialFractions[
        ellipticHermite["ProperRemainder"], factors, u, prime];
      If[fractions === $Failed, failure = "ResiduePoleNotInAlphabet"; Break[]];
      KeyValueMap[Function[{factor, list},
        If[Exponent[factor, u] === 1,
          root = Together[-Coefficient[factor, u, 0]/Coefficient[factor, u, 1]];
          rootValue = rationalEpsilonDependentBlockCurvePointValue[root, curve, u, pointValues];
          rootValueImage = If[MissingQ[rootValue], $Failed, scalarImage[rootValue]],
          rootValueImage = $Failed];
        Do[If[kk === 1 && rootValueImage =!= $Failed && rootValueImage =!= 0,
            store[order, {"E4Pole", root},
              list[[kk]] PowerMod[rootValueImage, -1, prime], i, j],
            store[order, {"E4Factor", factor, kk - 1}, list[[kk]], i, j]],
          {kk, Length[list]}]], fractions];
      cohomology = ellipticHermite["Cohomology"];
      store[order, {"E4Omega0"}, cohomology[[1]], i, j];
      store[order, {"E4OmegaInf"}, cohomology[[2]] - shift cohomology[[3]], i, j];
      store[order, {"E4Eta2"}, cohomology[[3]], i, j];
      fixed = evaluateAt[rationalHermite["Primitive"], base];
      If[fixed =!= $Failed,
        With[{ellipticBase = evaluateAt[ellipticHermite["Primitive"], base]},
          If[ellipticBase === $Failed, fixed = $Failed,
            fixed = Mod[fixed + baseYImage ellipticBase, prime]]]];
      If[fixed === $Failed, failure = "BasePointOnPole"; Break[]];
      hEntry = {
        {PolynomialMod[rationalHermite["Primitive"][[1]] -
            fixed rationalHermite["Primitive"][[2]], prime],
          rationalHermite["Primitive"][[2]]},
        ellipticHermite["Primitive"]};
      h[[i, j]] = hEntry,
      {i, d}, {j, n}];
    If[failure =!= None, Break[]];
    hImages[order] = h;
    endpointValues = Map[Module[{v0 = evaluateAt[#[[1]], endpoint],
          v1 = evaluateAt[#[[2]], endpoint]},
        If[MemberQ[{v0, v1}, $Failed], $Failed,
          Mod[v0 + endpointYImage v1, prime]]] &, h, {2}];
    If[! FreeQ[endpointValues, $Failed],
      failure = "PathEndpointOnPoleAtPrime"; Break[]];
    hEndpoint[order] = endpointValues;
    hPrevious = h,
    {order, orders}];
  If[failure =!= None,
    Return[<|"Status" -> failure, "Prime" -> prime|>]];
  <|"Status" -> "RecurrenceImageEvaluated", "Prime" -> prime,
    "KResidues" -> kResidues, "HImages" -> hImages,
    "OffDiagonalBasisTransformationBlockAtPathEndpointFiniteFieldValuesByEpsilonOrder" ->
      hEndpoint, "CurveChannel" -> True|>
];

(* ---- iterated-integral coefficient terms ------------------------------ *)

(* Letter sequences D^a K_r S^b and D^a reaching (order, row): the
   coefficient is the row of the matrix product against the boundary
   selector at boundary order q with q + a + r + b = order. Sequences grow
   from the selectors with every zero intermediate product pruned:
   SparseArray throughout, the source-sequence growth shared across all
   requested outputs (sourceStates:
   q -> states by weight), and a K letter applied only where its columns
   meet the state's nonzero rows. "MaximumIteratedIntegralCoefficientTerms"
   caps the enumeration and the pair is then reported capped (typed), never
   truncated silently. *)
rationalEpsilonDependentBlockSourceStates[source_Association, maximumWeight_Integer, weightByOrder_: Automatic, maximumStates_: Infinity] := Module[
  {sLetters, grow, nonzeroQ, needed, total = 0},
  nonzeroQ[m_] := Length[SparseArray[m]["NonzeroPositions"]] > 0;
  sLetters = Transpose[{source["Letters"], SparseArray /@ source["Residues"]}];
  grow[states_List] := With[{next = Select[Flatten[Table[
      {Append[state[[1]], letter[[1]]], letter[[2]] . state[[2]]}, {state, states}, {letter, sLetters}], 1],
    nonzeroQ[#[[2]]] &]},
    total += Length[next];
    If[total > maximumStates, Throw[<|"Status" ->
      "SourceIteratedIntegralSequenceGrowthCapped",
      "MaximumStates" -> maximumStates, "States" -> total|>]];
    next];
  (* Grow each boundary order only as far as a demanded pair can reach it:
     the source-tail weight is order-q-r. *)
  needed[q_] := If[weightByOrder === Automatic, maximumWeight, Lookup[weightByOrder, q, -1]];
  Association@Table[q -> NestList[grow, {{{}, SparseArray[source["BoundarySelectors"][q]]}}, Min[maximumWeight, needed[q]]],
    {q, Select[Keys[source["BoundarySelectors"]], needed[#] >= 0 &]}]
];

rationalEpsilonDependentBlockIteratedIntegralCoefficientTerms[order_Integer, row_Integer, diagonal_List, kResidues_Association,
    source_Association, targetSelectors_Association, sourceBoundaryCount_Integer,
    targetBoundaryCount_Integer, maximumWeight_Integer, maximumWords_: Infinity,
    sourceStatesGiven_: Automatic, sharedBoundaryQ_: False,
    offDiagonalBlockAtPathEndpoint_: <||>] := Module[
  {words = {}, dLetters, kLetters, embedSource, embedTarget, grow, capped = False,
   nonzeroQ, sourceStates, dStates, kStates, count = 0, rowsOf,
   columnsOf, dropped = 0, offDiagonalOrders, b},
  nonzeroQ[m_] := Length[SparseArray[m]["NonzeroPositions"]] > 0;
  rowsOf[m_] := DeleteDuplicates[SparseArray[m]["NonzeroPositions"][[All, 1]]];
  columnsOf[m_] := DeleteDuplicates[SparseArray[m]["NonzeroPositions"][[All, 2]]];
  dLetters = ({#[[1]], SparseArray[#[[2]]]} &) /@ diagonal;
  kLetters = KeyValueMap[{rationalEpsilonDependentBlockResidueLabel[#1], #1[[1]], SparseArray[#2]} &,
    KeySort[kResidues]];
  kLetters = Select[kLetters, nonzeroQ[#[[3]]] &];
  kLetters = ({#[[1]], #[[2]], #[[3]], columnsOf[#[[3]]]} &) /@ kLetters;
  sourceStates = If[sourceStatesGiven === Automatic,
    rationalEpsilonDependentBlockSourceStates[source, maximumWeight], sourceStatesGiven];
  embedSource[vector_] := If[TrueQ[sharedBoundaryQ], vector,
    Join[vector, ConstantArray[0, targetBoundaryCount]]];
  embedTarget[vector_] := If[TrueQ[sharedBoundaryQ], vector,
    Join[ConstantArray[0, sourceBoundaryCount], vector]];
  grow[states_List, letters_List] := Select[Flatten[Table[
      {Append[state[[1]], letter[[1]]], letter[[2]] . state[[2]]}, {state, states}, {letter, letters}], 1],
    nonzeroQ[#[[2]]] &];
  (* Letter-sequence convention: the letters are OUTERMOST FIRST, i.e.
     {l1, l2, ..., lk} is Int_base^u l1(t1) Int_base^t1 l2(t2) ... lk(tk),
     for both word kinds; the growth appends the innermost letter first,
     so every stored sequence is the reverse of the growth list.
     "IteratedIntegralCoefficientVector" is the row vector over the boundary
     values: the source values
     first (as in the source's selectors), then the target constants,
     grouped by target boundary order. *)
  (* target-boundary sequences: D^a Selector[q], a = order - q *)
  Do[
    With[{a = order - q},
      If[a > maximumWeight, dropped++];
      If[0 <= a <= maximumWeight,
        dStates = Nest[grow[#, dLetters] &, {{{}, SparseArray[targetSelectors[q]]}}, a];
        Do[If[nonzeroQ[state[[2]][[row]]],
            AppendTo[words, <|"IteratedIntegralLetterSequence" -> Reverse[state[[1]]],
              "ContributionType" -> "TargetBoundary",
              "BoundaryOrder" -> q,
              "IteratedIntegralCoefficientVector" ->
                embedTarget[Normal[state[[2]][[row]]]]|>];
            count++; If[count > maximumWords, capped = True]],
          {state, dStates}]]],
    {q, Keys[targetSelectors]}];
  (* source-boundary sequences: D^a K_r S^b Selector[q] *)
  Do[
    If[capped, Break[]];
    Do[
      If[capped, Break[]];
      Do[
        With[{a = order - q - kLetter[[2]] - b},
          If[a > maximumWeight, dropped++];
          If[0 <= a <= maximumWeight,
            kStates = Select[Table[
                If[Intersection[kLetter[[4]], rowsOf[state[[2]]]] === {}, Nothing,
                  {Append[state[[1]], kLetter[[1]]],
                    kLetter[[3]] . state[[2]]}],
                {state, sourceStates[q][[b + 1]]}], nonzeroQ[#[[2]]] &];
            dStates = Nest[grow[#, dLetters] &, kStates, a];
            Do[If[nonzeroQ[state[[2]][[row]]],
                AppendTo[words, <|"IteratedIntegralLetterSequence" -> Reverse[state[[1]]],
                  "ContributionType" -> "SourceBoundary",
                  "BoundaryOrder" -> q, "IncomingOrder" -> kLetter[[2]],
                  "IteratedIntegralCoefficientVector" ->
                    embedSource[Normal[state[[2]][[row]]]]|>];
                count++; If[count > maximumWords, capped = True]],
              {state, dStates}]]],
        {kLetter, kLetters}],
      {b, 0, Min[maximumWeight, Length[sourceStates[q]] - 1]}],
    {q, Keys[sourceStates]}];
  (* The requested target coefficient is F_T=G+H F_S.  H at the path
     endpoint is a coefficient, not an integration letter, so its
     contribution carries only the source letter sequence. *)
  offDiagonalOrders = Keys[Select[offDiagonalBlockAtPathEndpoint,
    nonzeroQ]];
  Do[
    If[capped, Break[]];
    Do[
      If[capped, Break[]];
      b = order - q - offDiagonalOrder;
      If[b > maximumWeight, dropped++];
      If[0 <= b <= maximumWeight && KeyExistsQ[sourceStates, q] &&
          b + 1 <= Length[sourceStates[q]],
        Do[With[{coefficient =
              offDiagonalBlockAtPathEndpoint[offDiagonalOrder] .
                sourceState[[2]]},
            If[nonzeroQ[coefficient[[row]]],
              AppendTo[words, <|
                "IteratedIntegralLetterSequence" ->
                  Reverse[sourceState[[1]]],
                "ContributionType" ->
                  "OffDiagonalBasisTransformationBlockAtPathEndpointContribution",
                "BoundaryOrder" -> q,
                "OffDiagonalTransformationOrder" -> offDiagonalOrder,
                "IteratedIntegralCoefficientVector" ->
                  embedSource[Normal[coefficient[[row]]]]|>];
              count++; If[count > maximumWords, capped = True]]],
          {sourceState, sourceStates[q][[b + 1]]}]],
      {q, Keys[source["BoundarySelectors"]]}],
    {offDiagonalOrder, offDiagonalOrders}];
  If[capped || dropped > 0,
    <|"Status" -> If[capped,
        "IteratedIntegralCoefficientTermEnumerationCapped",
        "IteratedIntegralWeightCapReached"],
      "MaximumIteratedIntegralCoefficientTerms" -> maximumWords,
      "DroppedCombinations" -> dropped,
      "IteratedIntegralCoefficientTerms" -> words|>, words]
];

(* The target boundary selectors padded into one block of columns, grouped
   by target boundary order (shared by the route and the re-verifying
   predicate so that both build the same coefficient terms). *)
rationalEpsilonDependentBlockTargetSelectors[
    block_Association, d_Integer, sharedQ_: False] := Module[
  {selectors, count, offsets},
  selectors = Lookup[block, "TargetBoundarySelectors",
    <|0 -> IdentityMatrix[d]|>];
  If[TrueQ[sharedQ], Return[{selectors, Dimensions[First[Values[selectors]]][[2]]}]];
  count = Total[Length[First[#]] & /@ Values[selectors]];
  offsets = Accumulate[Prepend[Length[First[#]] & /@ Values[selectors], 0]];
  {Association@MapIndexed[Function[{q, index},
      q -> (PadRight[PadLeft[#, offsets[[First[index]]] + Length[#]], count] & /@ selectors[q])],
      Keys[selectors]], count}
];

(* ---- the route ------------------------------------------------------------ *)

Options[SolveRationalEpsilonDependentBlockByVariationOfConstants] = {
  "Primes" -> Automatic,
  "PrimeCount" -> 3,
  "MaximumPrimeCount" -> 24,
  "Seed" -> 20260902,
  "MaximumWeight" -> Automatic,
  "MaximumIteratedIntegralCoefficientTerms" -> Infinity,
  "MaximumStates" -> 200000,
  "VariationOfConstantsMethod" -> Automatic,
  "OffDiagonalTransformationBlockRepresentation" -> Automatic,
  "IteratedIntegralCoefficientRepresentation" -> Automatic,
  "PrepareOnly" -> False,
  "Verbose" -> False
};

SolveRationalEpsilonDependentBlockByVariationOfConstants[source_Association,
    block_Association,
    demand_Association, OptionsPattern[]] := Catch@Module[
  {start = AbsoluteTime[], u, eps, base, rows, d, n, diagonal, incoming, curve,
   labels, gate, coefficients, symbols, factors, valuations, low, high,
   laurent, orders, primes, seed, images, freshPrime, freshImage, keys,
   reconstructed, lifted, comparisons = 0, mismatches = 0, targetSelectors,
   sourceBoundaryCount, targetBoundaryCount, demandPairs, words, maximumWeight,
   verbose, fail, kExact, certificate, laurentCoefficient, hImageCount = 0, sourceStates, directQ,
   weightByOrder, letterDecomposition, neededWeight, weightCapped, cappedPairs,
   activeOffDiagonalOrders, sourceTransitionOrders,
   endpoint, offDiagonalBlockAtPathEndpoint = <||>, offDiagonalTransformationComparisons = 0, offDiagonalTransformationMismatches = 0, probePoints,
   skippedPrimes = {}, scheduleIndex, regularization, targetSelectorInput,
   primeCount, maximumPrimeCount, primeSchedule, activeIncomingOrders,
   wordRepresentation, sharedBoundaryQ, curveQ, curvePointValues,
   curveBaseValue = None, curveEndpointValue = None, curvePoints,
   recurrenceImage,
   variationOfConstantsMethod, offDiagonalTransformationRepresentation,
   offDiagonalBlockCoefficients = <||>, offDiagonalTransformationCheck = <||>},
  verbose = TrueQ[OptionValue["Verbose"]];
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  seed = OptionValue["Seed"];
  If[! IntegerQ[seed], fail["InvalidSeed"]];
  u = Lookup[block, "PathVariable", Missing[]];
  eps = Lookup[block, "Regulator", Missing[]];
  base = Lookup[block, "BasePoint", Missing[]];
  rows = Lookup[block, "Rows", Missing[]];
  diagonal = Lookup[block, "Diagonal", Missing[]];
  incoming = Lookup[block, "Incoming", Missing[]];
  curve = Lookup[block, "Curve", None];
  If[! MatchQ[u, _Symbol] || ! MatchQ[eps, _Symbol] || ! MatchQ[base, _Integer | _Rational] ||
      ! ListQ[rows] || rows === {} || ! MatchQ[diagonal, {{_List, _?MatrixQ} ..}] ||
      ! MatchQ[incoming, {__Association}],
    fail["RationalEpsilonDependentBlockInputNotWellFormed"]];
  d = Length[rows];
  If[! AllTrue[diagonal, Dimensions[#[[2]]] === {d, d} &],
    fail["RationalEpsilonDependentBlockInputNotWellFormed",
      <|"Reason" -> "diagonal residue dimensions"|>]];
  n = Lookup[source, "Dimension", Missing[]];
  If[! IntegerQ[n] || n < 1 || ! ListQ[Lookup[source, "Letters", None]] ||
      ! ListQ[Lookup[source, "Residues", None]] ||
      Length[source["Letters"]] =!= Length[source["Residues"]] ||
      ! AllTrue[source["Residues"], Dimensions[#] === {n, n} &] ||
      ! AssociationQ[Lookup[source, "BoundarySelectors", None]],
    fail["SourceDifferentialSystemNotAccepted"]];
  targetSelectorInput = Lookup[block, "TargetBoundarySelectors",
    <|0 -> IdentityMatrix[d]|>];
  sharedBoundaryQ = TrueQ[
    Lookup[block, "SharedBoundaryCoordinates", False]];
  (* Source selectors all act on the same boundary-constant vector.  Target
     selectors may have different column counts because they are padded into
     disjoint target-boundary blocks below.  In both cases the Laurent-order
     labels must be integers and every selector must have at least one column. *)
  With[{selectors = source["BoundarySelectors"]},
    If[selectors === <||> || ! VectorQ[Keys[selectors], IntegerQ] ||
        ! AllTrue[Values[selectors], MatrixQ[#] && Length[Dimensions[#]] === 2 &&
          Dimensions[#][[1]] === n && Dimensions[#][[2]] >= 1 &] ||
        ! (SameQ @@ (Dimensions[#][[2]] & /@ Values[selectors])),
      fail["SourceBoundarySelectorsInvalid"]]];
  If[! AssociationQ[targetSelectorInput] || targetSelectorInput === <||> ||
      ! VectorQ[Keys[targetSelectorInput], IntegerQ] ||
      ! AllTrue[Values[targetSelectorInput], MatrixQ[#] && Length[Dimensions[#]] === 2 &&
        Dimensions[#][[1]] === d && Dimensions[#][[2]] >= 1 &],
    fail["TargetBoundarySelectorsInvalid"]];
  If[sharedBoundaryQ &&
      (! (SameQ @@ (Dimensions[#][[2]] & /@ Values[targetSelectorInput])) ||
       Dimensions[First[Values[targetSelectorInput]]][[2]] =!=
         Dimensions[First[Values[source["BoundarySelectors"]]]][[2]]),
    fail["SharedBoundarySelectorsInvalid"]];
  wordRepresentation = Replace[
    OptionValue["IteratedIntegralCoefficientRepresentation"],
    Automatic -> "ExplicitCoefficientTerms"];
  If[! MemberQ[{"ExplicitCoefficientTerms", "LazyCoefficientOperator"},
      wordRepresentation],
    fail["IteratedIntegralCoefficientRepresentationInvalid"]];
  If[! AllTrue[incoming, IntegerQ[#["Row"]] && 1 <= #["Row"] <= d && IntegerQ[#["Column"]] && 1 <= #["Column"] <= n &],
    fail["RationalEpsilonDependentBlockInputNotWellFormed",
      <|"Reason" -> "incoming row/column indices"|>]];
  (* S5: residue matrices and selectors are constant rational matrices *)
  With[{constantQ = MatrixQ[#, MatchQ[#, _Integer | _Rational] &] &},
    With[{bad = Select[Range[Length[diagonal]], ! constantQ[diagonal[[#, 2]]] &]},
      If[bad =!= {}, fail["ResidueMatrixNotConstant", <|"Where" -> "Diagonal", "Letters" -> diagonal[[bad, 1]]|>]]];
    With[{bad = Select[Range[Length[source["Residues"]]], ! constantQ[source["Residues"][[#]]] &]},
      If[bad =!= {}, fail["ResidueMatrixNotConstant", <|"Where" -> "Source", "Letters" -> source["Letters"][[bad]]|>]]];
    If[! AllTrue[Values[source["BoundarySelectors"]], constantQ],
      fail["ResidueMatrixNotConstant", <|"Where" -> "SourceBoundarySelectors"|>]];
    If[! AllTrue[Values[targetSelectorInput], constantQ],
      fail["ResidueMatrixNotConstant", <|"Where" -> "TargetBoundarySelectors"|>]]];
  (* every source column must be present or declared as an exception; the
     check is a COLUMN-PRESENCE proxy (a column with one declared term and a
     missing forcing is not detected), and ZeroColumns must name only absent
     columns (S8) *)
  With[{present = DeleteDuplicates[Lookup[incoming, "Column"]],
      zero = Lookup[block, "ZeroColumns", {}]},
    If[! (ListQ[zero] && AllTrue[zero, IntegerQ[#] && 1 <= # <= n &] && Intersection[zero, present] === {}),
      fail["ZeroColumnsInvalid", <|"ZeroColumns" -> zero, "Present" -> Intersection[Flatten[{zero}], present]|>]];
    With[{missing = Complement[Range[n], present, zero]},
      If[missing =!= {}, fail["LowerBlockExceptionRequired", <|"Columns" -> missing|>]]]];
  (* alphabet *)
  labels = DeleteDuplicates[Join[diagonal[[All, 1]], Lookup[incoming, "Letter"], source["Letters"]]];
  gate = rationalEpsilonDependentBlockAlphabetGate[labels, u, curve];
  If[gate["Status"] =!= "AlphabetAdmitted", fail[gate["Status"], KeyDrop[gate, "Status"]]];
  curveQ = MemberQ[gate["Channels"], "Curve"];
  (* incoming coefficients: rational in eps and u, every other symbol specialized *)
  coefficients = Lookup[incoming, "Coefficient"];
  symbols = DeleteDuplicates[Cases[coefficients, s_Symbol /; s =!= u && s =!= eps, {0, Infinity}]];
  If[symbols =!= {}, fail["PathParameterNotSpecialized", <|"Symbols" -> symbols|>]];
  If[! AllTrue[coefficients, With[{t = Together[#]},
      PolynomialQ[Numerator[t], {eps, u}] && PolynomialQ[Denominator[t], {eps, u}]] &],
    fail["IncomingNotRationalInEpsilon"]];
  variationOfConstantsMethod = OptionValue["VariationOfConstantsMethod"];
  If[! MemberQ[{Automatic, "ExactDLogDecomposition",
        "FiniteFieldHermiteReductionAndReconstruction"},
      variationOfConstantsMethod],
    fail["VariationOfConstantsMethodInvalid"]];
  If[variationOfConstantsMethod === "ExactDLogDecomposition" &&
      ! AllTrue[coefficients, FreeQ[#, u] &],
    fail["ExactDLogDecompositionNotApplicable"]];
  directQ = variationOfConstantsMethod =!=
      "FiniteFieldHermiteReductionAndReconstruction" &&
    AllTrue[coefficients, FreeQ[#, u] &];
  endpoint = Lookup[block, "PathEndpoint",
    Lookup[demand, "PathEndpoint", None]];
  offDiagonalTransformationRepresentation = Replace[OptionValue["OffDiagonalTransformationBlockRepresentation"],
    Automatic -> Which[
      MatchQ[endpoint, _Integer | _Rational], "PathEndpointValue",
      MatchQ[endpoint, _Symbol] && endpoint =!= None && endpoint =!= u,
        "RationalFunction",
      True, "PathEndpointValue"]];
  If[! MemberQ[{"PathEndpointValue", "RationalFunction"}, offDiagonalTransformationRepresentation],
    fail["OffDiagonalTransformationBlockRepresentationInvalid"]];
  If[! directQ && offDiagonalTransformationRepresentation === "PathEndpointValue" &&
      ! MatchQ[endpoint, _Integer | _Rational],
    fail["PathEndpointRequired", <|"Reason" ->
      "reconstructing the off-diagonal transformation block at a path endpoint requires a rational endpoint"|>]];
  If[! directQ && offDiagonalTransformationRepresentation === "RationalFunction" &&
      !(MatchQ[endpoint, _Symbol] && endpoint =!= None && endpoint =!= u),
    fail["SymbolicPathEndpointRequired",
      <|"PathEndpoint" -> endpoint|>]];
  curvePointValues = Lookup[block, "CurvePointValues", <||>];
  If[curveQ && (! AssociationQ[curvePointValues] ||
      ! AllTrue[Keys[curvePointValues], MatchQ[#, _Integer | _Rational] &]),
    fail["CurvePointValuesInvalid"]];
  If[curveQ && offDiagonalTransformationRepresentation === "RationalFunction" && ! directQ,
    fail["CurveOffDiagonalTransformationFunctionNotImplemented", <|"Reason" ->
      "a symbolic elliptic off-diagonal transformation block also requires the curve value at the path endpoint"|>]];
  If[curveQ,
    curvePoints = DeleteDuplicates[Cases[labels, {"E4Pole", point_} :> point]];
    curvePointValues = Join[curvePointValues, Association@Table[point ->
      Replace[Lookup[curvePointValues, point, Automatic],
        Automatic :> Sqrt[Together[curve /. u -> point]]], {point, curvePoints}]];
    If[! directQ,
      If[! MatchQ[endpoint, _Integer | _Rational],
        fail["PathEndpointRequired", <|"Reason" ->
          "a curve-valued off-diagonal transformation block requires a declared path endpoint"|>]];
      curveBaseValue = rationalEpsilonDependentBlockCurvePointValue[base, curve, u,
        Lookup[block, "CurvePointValues", <||>]];
      curveEndpointValue = rationalEpsilonDependentBlockCurvePointValue[endpoint, curve, u,
        Lookup[block, "CurvePointValues", <||>]];
      If[MissingQ[curveBaseValue] || MissingQ[curveEndpointValue] ||
          ! AllTrue[Values[curvePointValues], MatchQ[#, _Integer | _Rational] &],
        fail["CurvePointValueRequired", <|"BasePoint" -> base,
          "PathEndpoint" -> endpoint, "MarkedPoints" -> curvePoints,
          "Reason" -> "the modular curve recurrence needs rational sheet values y with y^2=P(point), supplied through CurvePointValues when not rational squares"|>]];
      If[AnyTrue[Normal[curvePointValues],
          Together[Last[#]^2 - (curve /. u -> First[#])] =!= 0 &],
        fail["CurvePointValuesInvalid"]]]];
  (* epsilon window: exact valuation of every coefficient at the base point and at
     two more rational points of u (the round-4 certificate style) *)
  (* S6: three random rational probe points from the seed (a coefficient
     vanishing at a fixed point evaded the former fixed probes), minimum
     over the points as in round 4; the Series' own valuation is read
     after the expansion and a pole below the window is refused *)
  probePoints = BlockRandom[SeedRandom[seed + 7];
    Table[base + RandomInteger[{1, 199}]/RandomInteger[{200, 397}], {3}]];
  valuations = Table[Module[{vs},
      vs = Table[observableTransportEpsilonOrderAtPoint[c /. u -> pt, eps], {pt, probePoints}];
      If[! AllTrue[vs, IntegerQ],
        fail["IncomingBlockEpsilonValuationUncertified",
          <|"Coefficient" -> c, "Orders" -> vs|>]];
      Min[vs]], {c, coefficients}];
  low = Min[valuations];
  demandPairs = Lookup[demand, "RequestedOutputPairs", Missing[]];
  If[! MatchQ[demandPairs, {{_Integer, _Integer} ..}] || ! DuplicateFreeQ[demandPairs] ||
      ! AllTrue[demandPairs, 1 <= #[[2]] <= d &],
    fail["RequestedOutputPairsInvalid"]];
  (* A sequence D^a K_r S^b Sel[q] contributes at
     q + a + r + b, so a demanded order N needs incoming orders up to
     N - q_min over the SOURCE boundary orders (Codex: "orders -2..4 for
     the target window -4..2" with boundary orders from -2); the former
     window stopped at N and silently lost every sequence on a negative
     boundary order *)
  high = Max[demandPairs[[All, 1]]] - Min[Keys[source["BoundarySelectors"]]];
  If[high < low,
    fail["RequestedOutputBelowIncomingEpsilonValuation",
      <|"Low" -> low, "High" -> high|>]];
  orders = Range[low, high];
  (* Laurent expansion: one Series per incoming coefficient *)
  laurentCoefficient[c_] := Module[{s = observableTransportLaurentEntrySeries[c, eps, {low, high}]},
    If[s === $Failed, Table[Cancel[Together[SeriesCoefficient[c, {eps, 0, o}]]], {o, orders}], s]];
  $observableTransportLaurentDiagnostics = <||>;
  laurent = If[curveQ,
    Table[ConstantArray[{0, 0}, {d, n}], {Length[orders]}],
    Table[ConstantArray[0, {d, n}], {Length[orders]}]];
  Do[With[{series = laurentCoefficient[entry["Coefficient"]],
      form = If[curveQ, rationalEpsilonDependentBlockLetterPair[entry["Letter"], u, curve, curvePointValues],
        rationalEpsilonDependentBlockLetterFunction[entry["Letter"], u]]},
      Do[If[curveQ,
          laurent[[k, entry["Row"], entry["Column"], 1]] += series[[k]] form[[1]];
          laurent[[k, entry["Row"], entry["Column"], 2]] += series[[k]] form[[2]],
          laurent[[k, entry["Row"], entry["Column"]]] += series[[k]] form],
        {k, Length[orders]}]],
    {entry, incoming}];
  laurent = AssociationThread[orders -> laurent];
  If[Lookup[$observableTransportLaurentDiagnostics, "ValuationBelowRange", 0] > 0,
    fail["LaurentValuationBelowWindow", <|"Window" -> {low, high},
      "Entries" -> $observableTransportLaurentDiagnostics["ValuationBelowRange"],
      "Reason" -> "an incoming coefficient has a pole in eps below the certified valuation"|>]];
  If[verbose, observableTransportMilestone[
    "Rational-epsilon-dependent block: Laurent expansion of ",
    Length[incoming], " incoming entries, orders ", {low, high}, ", ",
    Round[AbsoluteTime[] - start, 0.1], " s"]];
  With[{mixed = Select[DeleteDuplicates[Flatten[First /@ FactorList[Denominator[Together[#]]] & /@ coefficients]],
      ! FreeQ[#, u] && ! FreeQ[#, eps] &]},
    If[mixed =!= {}, fail["MixedEpsilonPathDenominator", <|"Factors" -> mixed|>]]];
  factors = rationalEpsilonDependentBlockPoleFactors[labels, coefficients, u];
  regularization = <|"BasePoint" -> Join[
      Select[factors, (# /. u -> base) === 0 &],
      If[curveQ && Together[curve /. u -> base] === 0, {curve}, {}]],
    "PathEndpoint" -> If[MatchQ[endpoint, _Integer | _Rational],
      Join[Select[factors, (# /. u -> endpoint) === 0 &],
        If[curveQ && Together[curve /. u -> endpoint] === 0, {curve}, {}]], {}]|>;
  (* Residues alone do not define the requested solution when the path
     endpoint is singular. Until tangential-base/path-endpoint data are
     accepted and consumed, return a typed refusal. *)
  If[regularization["BasePoint"] =!= {} ||
      regularization["PathEndpoint"] =!= {},
    fail["PathRegularizationRequired", <|"RegularizationRequired" -> regularization,
      "BasePoint" -> base, "PathEndpoint" -> endpoint|>]];
  (* When every incoming coefficient is free of the path
     variable, each B_n is a combination of the declared dlog letters with
     NUMERICAL coefficients, Omega_n = B_n (H_(n-1) = 0 inductively) and
     the Hermite-reduced off-diagonal transformation block vanishes
     identically: the K residues are the exact
     Laurent coefficients on the letters' own factors -- no modular image
     or reconstruction. "VariationOfConstantsMethod" ->
     "FiniteFieldHermiteReductionAndReconstruction" forces the finite-field
     recurrence for a cross-check. *)
  If[directQ,
    (* Decompose each rational letter once over irreducible monic pole
       factors so exact dlog decomposition and finite-field Hermite reduction
       use the same labels. *)
    letterDecomposition[letter_] := letterDecomposition[letter] = Module[{a, terms, out = <||>},
      a = Apart[rationalEpsilonDependentBlockLetterFunction[letter, u], u];
      terms = If[Head[a] === Plus, List @@ a, {a}];
      Do[With[{den = Denominator[Together[term]]},
          With[{factor = SelectFirst[factors, PolynomialRemainder[den, #, u] === 0 &, None]},
            If[factor === None, Throw[<|"Status" -> "ResiduePoleNotInAlphabet", "Letter" -> letter|>]];
            With[{r = PolynomialRemainder[Together[term factor], factor, u]},
              out[factor] = Lookup[out, factor, 0] + r]]],
        {term, terms}];
      Association@KeyValueMap[#1 -> PadRight[CoefficientList[Together[#2], u], Exponent[#1, u], 0] &, out]];
    reconstructed = <||>;
    Do[With[{series = laurentCoefficient[entry["Coefficient"]], label = entry["Letter"]},
        If[MemberQ[$rationalEpsilonDependentBlockCurveLetters, First[label]],
          Do[If[series[[k]] =!= 0,
              Module[{key = rationalEpsilonDependentBlockResidueKey[orders[[k]], label], matrix},
                matrix = Lookup[reconstructed, Key[key], ConstantArray[0, {d, n}]];
                matrix[[entry["Row"], entry["Column"]]] += series[[k]];
                reconstructed[key] = matrix]],
            {k, Length[orders]}],
          With[{decomposition = letterDecomposition[label]},
            Do[If[series[[k]] =!= 0,
                KeyValueMap[Function[{factor, list},
                  Do[If[list[[kk]] =!= 0,
                      Module[{key = {orders[[k]], factor, kk - 1}, matrix},
                        matrix = Lookup[reconstructed, Key[key], ConstantArray[0, {d, n}]];
                        matrix[[entry["Row"], entry["Column"]]] += series[[k]] list[[kk]];
                        reconstructed[key] = matrix]],
                    {kk, Length[list]}]], decomposition]],
              {k, Length[orders]}]]]],
      {entry, incoming}];
    reconstructed = Select[reconstructed, ! AllTrue[Flatten[#], # === 0 &] &];
    keys = Keys[reconstructed];
    primes = {}; freshPrime = None; images = {}; comparisons = Length[keys] d n; mismatches = 0;
    If[verbose, observableTransportMilestone[
      "Rational-epsilon-dependent block: incoming connection is dlog with path-independent coefficients: ",
      Length[keys], " exact residue keys, no modular image, ", Round[AbsoluteTime[] - start, 0.1], " s"]]];
  (* primes *)
  If[TrueQ[OptionValue["PrepareOnly"]],
    Throw[<|"Status" ->
      "RationalEpsilonDependentBlockVariationOfConstantsProblemPrepared",
      "Laurent" -> laurent, "Orders" -> orders,
      "Factors" -> factors, "ExactDLogDecompositionQ" -> directQ, "ExactDLogResidues" -> If[directQ, reconstructed, None],
      "Diagonal" -> diagonal, "Source" -> source, "PathVariable" -> u, "Regulator" -> eps,
      "BasePoint" -> base, "PathEndpoint" -> endpoint,
      "Window" -> {low, high}, "Rows" -> rows,
      "RequestedOutputPairs" -> demandPairs, "Dimensions" -> {d, n},
      "OffDiagonalTransformationBlockRepresentation" -> offDiagonalTransformationRepresentation,
      "IteratedIntegralCoefficientRepresentation" -> wordRepresentation,
      "SharedBoundaryCoordinates" -> sharedBoundaryQ,
      "CurveQ" -> curveQ, "Curve" -> curve,
      "CurvePointValues" -> curvePointValues,
      "CurveBaseValue" -> curveBaseValue,
      "CurveValueAtPathEndpoint" -> curveEndpointValue|>]];
  (* N3: the modular arithmetic reduces rational numbers only; a Gaussian
     rational (I) or any other non-rational number in a coefficient would
     burn the whole prime schedule -- refused typed here (exact dlog decomposition
     works exactly in Q(i) and keeps such coefficients) *)
  If[! directQ && ! AllTrue[coefficients, FreeQ[#, _Complex] && VectorQ[Flatten[CoefficientList[Numerator[Together[#]], {eps, u}]], MatchQ[#, _Integer | _Rational] &] &&
        VectorQ[Flatten[CoefficientList[Denominator[Together[#]], {eps, u}]], MatchQ[#, _Integer | _Rational] &] &],
    fail["CoefficientFieldNotRational", <|"Reason" ->
      "finite-field Hermite reduction currently reduces rational coefficients only; a Gaussian or algebraic coefficient needs exact dlog decomposition or a field extension"|>]];
  recurrenceImage[prime_] := If[curveQ,
    rationalEpsilonDependentBlockCurveRecurrenceImage[laurent, diagonal, source, factors, u,
      curve, curvePointValues, base, curveBaseValue, orders, prime,
      If[offDiagonalTransformationRepresentation === "PathEndpointValue", endpoint, None],
      curveEndpointValue],
    rationalEpsilonDependentBlockRecurrenceImage[laurent, diagonal, source, factors, u, base,
      orders, prime,
      If[offDiagonalTransformationRepresentation === "PathEndpointValue", endpoint, None]]];
  If[! directQ,
  (* Seeded prime schedule: add images until every coordinate reconstructs
     (lift-and-verify) or the declared maximum is reached. *)
  primeCount = OptionValue["PrimeCount"];
  maximumPrimeCount = OptionValue["MaximumPrimeCount"];
  If[! IntegerQ[primeCount] || primeCount < 1 || ! IntegerQ[maximumPrimeCount] ||
      maximumPrimeCount < primeCount,
    fail["InvalidPrimeCount", <|"PrimeCount" -> primeCount,
      "MaximumPrimeCount" -> maximumPrimeCount|>]];
  primeSchedule = Replace[OptionValue["Primes"], Automatic :> BlockRandom[
    SeedRandom[seed]; Module[{schedule = {}, count = maximumPrimeCount + 1},
      While[Length[schedule] < count,
        schedule = DeleteDuplicates[Append[schedule, RandomPrime[{2^30, 2^31 - 1}]]]];
      schedule]]];
  If[! MatchQ[primeSchedule, {__Integer}] || Length[primeSchedule] < primeCount + 1 ||
      ! DuplicateFreeQ[primeSchedule] || ! AllTrue[primeSchedule, # > 2 && PrimeQ[#] &],
    fail["InvalidPrimeSchedule"]];
  images = {}; reconstructed = <||>; keys = {};
  Module[{needed = primeCount, converged = False, lifted, usedPrimes,
     failingKey = None, failingEntry = None, failingResidues = None},
    scheduleIndex = 0; usedPrimes = {};
    While[! converged,
      (* A prime at which a leaf is undefined or a pole/curve factor
         degenerates is skipped and recorded.  Only exhaustion is terminal:
         distinct exceptional primes need not share a mathematical cause. *)
      While[Length[images] < needed,
        scheduleIndex++;
        If[scheduleIndex > Length[primeSchedule], fail["PrimeScheduleExhausted", <|"SkippedPrimes" -> skippedPrimes|>]];
        With[{p = primeSchedule[[scheduleIndex]], image = recurrenceImage[primeSchedule[[scheduleIndex]]]},
          If[image["Status"] === "RecurrenceImageEvaluated",
            AppendTo[images, image]; AppendTo[usedPrimes, p],
            If[image["Status"] === "CurveBranchPoleNotSupported",
              fail[image["Status"], <|"Prime" -> p|>],
              AppendTo[skippedPrimes, <|"Prime" -> p, "Status" -> image["Status"]|>]]]];
        ];
      keys = Union @@ (Keys[#["KResidues"]] & /@ images);
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
      (* The off-diagonal block is either lifted at one rational path
         endpoint, or coefficientwise
         as a rational function when the endpoint is the remaining kinematic
         variable. *)
      offDiagonalBlockAtPathEndpoint = <||>; offDiagonalBlockCoefficients = <||>;
      If[converged,
        If[offDiagonalTransformationRepresentation === "PathEndpointValue",
          Do[
            lifted = Table[Table[
                With[{residues = Table[images[[pi]][
                    "OffDiagonalBasisTransformationBlockAtPathEndpointFiniteFieldValuesByEpsilonOrder"][
                      order][[i, j]],
                    {pi, Length[images]}]},
                  With[{crt = modularCRT[residues, usedPrimes]},
                    If[crt === $Failed, $Failed,
                      modularRationalReconstruct[crt, Times @@ usedPrimes]]]],
                {j, n}], {i, d}];
            If[! FreeQ[lifted, $Failed], converged = False;
              failingKey = {
                "OffDiagonalBasisTransformationBlockAtPathEndpoint",
                order}; Break[]];
            offDiagonalBlockAtPathEndpoint[order] = lifted,
            {order, orders}],
          Do[
            lifted = Table[Table[
                rationalEpsilonDependentBlockReconstructFunction[
                  Table[images[[pi]]["HImages"][order][[i, j]],
                    {pi, Length[images]}], usedPrimes, u],
                {j, n}], {i, d}];
            If[! FreeQ[lifted, $Failed], converged = False;
              failingKey = {
                "OffDiagonalBasisTransformationBlockCoefficient",
                order}; Break[]];
            offDiagonalBlockCoefficients[order] = lifted,
            {order, orders}]]];
      If[! converged,
        If[needed >= maximumPrimeCount,
          fail["ReconstructionNotConverged", <|"PrimeCount" -> Length[images],
            "MaximumPrimeCount" -> maximumPrimeCount,
            "Key" -> failingKey, "Entry" -> failingEntry, "Residues" -> failingResidues,
            "Primes" -> usedPrimes|>]];
        needed = Min[needed + Max[1, Ceiling[needed/2]], maximumPrimeCount]]];
    (* N2: the fresh prime goes through the same skip-and-record loop *)
    freshImage = None;
    While[freshImage === None,
      scheduleIndex++;
      If[scheduleIndex > Length[primeSchedule], fail["PrimeScheduleExhausted", <|"SkippedPrimes" -> skippedPrimes, "Stage" -> "FreshPrime"|>]];
      With[{p = primeSchedule[[scheduleIndex]]},
        If[MemberQ[usedPrimes, p], Continue[]];
        With[{image = recurrenceImage[p]},
          If[image["Status"] === "RecurrenceImageEvaluated",
            freshImage = image; freshPrime = p,
            If[image["Status"] === "CurveBranchPoleNotSupported",
              fail[image["Status"], <|"Prime" -> p|>],
              AppendTo[skippedPrimes, <|"Prime" -> p, "Status" -> image["Status"]|>]]]]];
      ];
    primes = usedPrimes];
  If[verbose, observableTransportMilestone[
    "Rational-epsilon-dependent block: ", Length[primes],
    " prime images of the recurrence, ",
    Length[keys], " residue keys reconstructed, ", Round[AbsoluteTime[] - start, 0.1], " s"]];
  (* fresh-prime validation *)
  offDiagonalTransformationComparisons = 0; offDiagonalTransformationMismatches = 0;
  If[offDiagonalTransformationRepresentation === "PathEndpointValue",
    Do[With[{image = freshImage[
          "OffDiagonalBasisTransformationBlockAtPathEndpointFiniteFieldValuesByEpsilonOrder"][order],
        exact = offDiagonalBlockAtPathEndpoint[order]},
        Do[offDiagonalTransformationComparisons++;
          If[Mod[Numerator[exact[[i, j]]] - image[[i, j]] Denominator[exact[[i, j]]], freshPrime] =!= 0,
            offDiagonalTransformationMismatches++], {i, d}, {j, n}]], {order, orders}],
    offDiagonalTransformationCheck = rationalEpsilonDependentBlockOffDiagonalTransformationFunctionCheck[offDiagonalBlockCoefficients,
      freshImage["HImages"], orders, u, freshPrime, seed];
    If[Lookup[offDiagonalTransformationCheck, "Status", None] =!= "OffDiagonalTransformationBlockChecked",
      fail[Lookup[offDiagonalTransformationCheck, "Status",
        "OffDiagonalTransformationBlockValidationFailed"]]];
    offDiagonalTransformationComparisons = offDiagonalTransformationCheck["Comparisons"];
    offDiagonalTransformationMismatches = offDiagonalTransformationCheck["Mismatches"]];
  If[offDiagonalTransformationMismatches > 0,
    fail["FreshPrimeValidationFailed", <|
      "Quantity" -> "OffDiagonalBasisTransformationBlock",
      "Mismatches" -> offDiagonalTransformationMismatches,
      "Comparisons" -> offDiagonalTransformationComparisons|>]];
  Do[
    With[{image = Lookup[freshImage["KResidues"], Key[key], ConstantArray[0, {d, n}]], exact = reconstructed[key]},
      Do[comparisons++;
        If[Mod[Numerator[exact[[i, j]]] - image[[i, j]] Denominator[exact[[i, j]]], freshPrime] =!= 0, mismatches++],
        {i, d}, {j, n}]],
    {key, Union[keys, Keys[freshImage["KResidues"]]]}];
  If[mismatches > 0, fail["FreshPrimeValidationFailed", <|"Mismatches" -> mismatches, "Comparisons" -> comparisons|>]];
  ];   (* end of finite-field Hermite reduction and reconstruction *)
  If[! directQ && offDiagonalTransformationRepresentation === "RationalFunction",
    offDiagonalBlockAtPathEndpoint = Association@KeyValueMap[
      #1 -> Map[# /. u -> endpoint &, #2, {2}] &, offDiagonalBlockCoefficients]];
  hImageCount = If[images === {}, 0, Total[Length /@ Lookup[images, "HImages"]]];
  sourceBoundaryCount = Length[First[Values[source["BoundarySelectors"]]][[1]]];
  {targetSelectors, targetBoundaryCount} =
    rationalEpsilonDependentBlockTargetSelectors[block, d, sharedBoundaryQ];
  If[wordRepresentation === "LazyCoefficientOperator",
    (* The returned K/source/diagonal data are the operator.  No source state
       and no coefficient term is constructed on this route; MaximumStates
       and MaximumIteratedIntegralCoefficientTerms therefore cannot turn a
       valid lazy solution into an enumeration refusal. *)
    neededWeight = None; maximumWeight = None; sourceStates = <||>; words = None,
    (* Explicit coefficient terms. The weight a+b is derived from the actual nonzero
       K orders; absent K orders must not trigger fictitious source growth. *)
    activeIncomingOrders = DeleteDuplicates[First /@ Keys[
      Select[reconstructed, ! AllTrue[Flatten[#], # === 0 &] &]]];
    activeOffDiagonalOrders = Keys[Select[
      offDiagonalBlockAtPathEndpoint,
      ! AllTrue[Flatten[#], # === 0 &] &]];
    sourceTransitionOrders = Union[activeIncomingOrders,
      activeOffDiagonalOrders];
    neededWeight = Max[Join[
      Select[Flatten[Table[pair[[1]] - q - r, {pair, demandPairs},
        {q, Keys[source["BoundarySelectors"]]},
        {r, sourceTransitionOrders}]], # >= 0 &],
      Select[Flatten[Table[pair[[1]] - q, {pair, demandPairs},
        {q, Keys[targetSelectorInput]}]], # >= 0 &], {0}]];
    maximumWeight = Replace[OptionValue["MaximumWeight"], Automatic -> neededWeight];
    If[! IntegerQ[maximumWeight] || maximumWeight < 0, fail["InvalidMaximumWeight"]];
    weightCapped = maximumWeight < neededWeight;
    weightByOrder = Association@Table[q -> With[{weights = Select[
          Flatten[Table[pair[[1]] - q - r, {pair, demandPairs},
            {r, sourceTransitionOrders}]], # >= 0 &]},
        If[weights === {}, -1, Max[weights]]], {q, Keys[source["BoundarySelectors"]]}];
    sourceStates = rationalEpsilonDependentBlockSourceStates[source, maximumWeight, weightByOrder, OptionValue["MaximumStates"]];
    If[verbose, observableTransportMilestone[
      "Rational-epsilon-dependent block: source sequences grown to weight ",
      maximumWeight, ": ",
      Total[Length /@ Flatten[Values[sourceStates], 1]], " states, ", Round[AbsoluteTime[] - start, 0.1], " s"]];
    words = Association@Table[pair -> rationalEpsilonDependentBlockIteratedIntegralCoefficientTerms[pair[[1]], pair[[2]], diagonal, reconstructed, source,
        targetSelectors, sourceBoundaryCount, targetBoundaryCount, maximumWeight,
        OptionValue["MaximumIteratedIntegralCoefficientTerms"],
        sourceStates, sharedBoundaryQ,
        offDiagonalBlockAtPathEndpoint], {pair, demandPairs}];
    cappedPairs = Keys[Select[words, AssociationQ]];
    If[weightCapped || cappedPairs =!= {},
      Throw[<|"Status" -> If[weightCapped,
          "IteratedIntegralWeightCapReached",
          "IteratedIntegralCoefficientTermEnumerationCapped"],
        "NeededWeight" -> neededWeight, "MaximumWeight" -> maximumWeight,
        "MaximumIteratedIntegralCoefficientTerms" ->
          OptionValue["MaximumIteratedIntegralCoefficientTerms"],
        "CappedRequestedOutputPairs" -> cappedPairs,
        "DroppedCombinations" -> Total[Lookup[#, "DroppedCombinations", 0] & /@ Values[Select[words, AssociationQ]]],
        "IteratedIntegralCoefficientTermsByRequestedOutput" -> words,
        "Window" -> {low, high}|>]];
    If[verbose, observableTransportMilestone[
      "Rational-epsilon-dependent block: requested coefficient terms ",
      Total[If[AssociationQ[#],
        Length[#["IteratedIntegralCoefficientTerms"]], Length[#]] & /@ Values[words]],
      ", ", Round[AbsoluteTime[] - start, 0.1], " s"]]];
  certificate = <|"Status" -> "RationalEpsilonDependentBlockSolutionAccepted",
    "VariationOfConstantsMethod" -> If[directQ, "ExactDLogDecomposition", "FiniteFieldHermiteReductionAndReconstruction"],
    "Probabilistic" -> ! directQ, "Exact" -> directQ,
    "Primes" -> primes, "FreshValidationPrime" -> freshPrime,
    "ResidueComparisons" -> comparisons, "ResidueMismatches" -> mismatches,
    "ReconstructedResidueKeys" -> Length[keys],
    "OffDiagonalTransformationBlockFiniteFieldImages" -> hImageCount,
    "OffDiagonalTransformationBlockReconstructed" -> ! directQ,
    "OffDiagonalTransformationBlockRepresentation" -> If[directQ, "Zero",
      offDiagonalTransformationRepresentation],
    "OffDiagonalTransformationBlockComparisons" -> offDiagonalTransformationComparisons, "OffDiagonalTransformationBlockMismatches" -> offDiagonalTransformationMismatches,
    "OffDiagonalTransformationBlockValidationPoint" -> Lookup[offDiagonalTransformationCheck, "Point", None],
    "PathEndpoint" -> endpoint,
    "Alphabet" -> gate["Verdicts"],
    "PoleFactors" -> factors,
    "Valuations" -> valuations, "ValuationProbePoints" -> probePoints,
    "SkippedPrimes" -> skippedPrimes,
    "RegularizationRequired" -> regularization,
    "IteratedIntegralCoefficientRepresentation" -> wordRepresentation,
    "SharedBoundaryCoordinates" -> sharedBoundaryQ,
    "CurveChannel" -> curveQ,
    "Curve" -> If[curveQ, curve, None],
    "Window" -> {low, high},
    "Seed" -> seed|>;
  <|"Status" -> "RationalEpsilonDependentBlockSolutionAccepted",
    "Rows" -> rows, "PathVariable" -> u, "Regulator" -> eps, "BasePoint" -> base,
    "Window" -> {low, high},
    "RequestedOutputPairs" -> demandPairs,
    "RegularizationRequired" -> regularization,
    "KResidues" -> reconstructed,
    "OffDiagonalTransformationBlockFiniteFieldImages" -> If[directQ, <||>, Association@Table[primes[[pi]] -> images[[pi]]["HImages"], {pi, Length[primes]}]],
    "OffDiagonalBasisTransformationBlockAtPathEndpoint" -> If[directQ, Association@Table[order -> ConstantArray[0, {d, n}], {order, orders}], offDiagonalBlockAtPathEndpoint],
    "OffDiagonalBasisTransformationBlockCoefficients" -> If[! directQ && offDiagonalTransformationRepresentation === "RationalFunction",
      offDiagonalBlockCoefficients, <||>],
    "PathEndpoint" -> endpoint,
    "OffDiagonalTransformationBlockStatus" -> Which[directQ, "OffDiagonalTransformationBlockVanishes",
      offDiagonalTransformationRepresentation === "RationalFunction", "OffDiagonalTransformationBlockRationalFunctionReconstructed",
      True, "OffDiagonalTransformationBlockReconstructedAtPathEndpoint"],
    "IteratedIntegralCoefficientTermsByRequestedOutput" -> words,
    "IteratedIntegralCoefficientRepresentation" -> wordRepresentation,
    "SharedBoundaryCoordinates" -> sharedBoundaryQ,
    "CurveChannel" -> curveQ,
    "Curve" -> If[curveQ, curve, None],
    "BoundaryColumns" -> If[sharedBoundaryQ, sourceBoundaryCount,
      sourceBoundaryCount + targetBoundaryCount],
    "Certificate" -> certificate,
    "Seconds" -> N[AbsoluteTime[] - start]|>
];

rationalEpsilonDependentBlockCertificateShapeQ[certificate_] := AssociationQ[certificate] &&
  Lookup[certificate, "Status", None] ===
    "RationalEpsilonDependentBlockSolutionAccepted" &&
  MatchQ[Lookup[certificate, "Alphabet", None], {__Association}] &&
  AllTrue[certificate["Alphabet"], #["Status"] === "Admitted" &] &&
  IntegerQ[Lookup[certificate, "ResidueComparisons", None]] &&
  certificate["ResidueComparisons"] >= 0 &&
  Lookup[certificate, "ResidueMismatches", -1] === 0 &&
  Lookup[certificate, "RegularizationRequired", None] ===
    <|"BasePoint" -> {}, "PathEndpoint" -> {}|> &&
  Which[
    Lookup[certificate, "VariationOfConstantsMethod", None] === "FiniteFieldHermiteReductionAndReconstruction",
      TrueQ[certificate["Probabilistic"]] && certificate["Exact"] === False &&
      MatchQ[Lookup[certificate, "Primes", None], {__Integer}] &&
      DuplicateFreeQ[certificate["Primes"]] &&
      AllTrue[certificate["Primes"], # > 2 && PrimeQ[#] &] &&
      IntegerQ[Lookup[certificate, "FreshValidationPrime", None]] &&
      PrimeQ[certificate["FreshValidationPrime"]] &&
      ! MemberQ[certificate["Primes"], certificate["FreshValidationPrime"]] &&
      TrueQ[Lookup[certificate, "OffDiagonalTransformationBlockReconstructed", False]] &&
      IntegerQ[Lookup[certificate, "OffDiagonalTransformationBlockComparisons", None]] &&
      certificate["OffDiagonalTransformationBlockComparisons"] > 0 &&
      Lookup[certificate, "OffDiagonalTransformationBlockMismatches", -1] === 0 &&
      MemberQ[{"PathEndpointValue", "RationalFunction"},
        Lookup[certificate, "OffDiagonalTransformationBlockRepresentation", "PathEndpointValue"]],
    Lookup[certificate, "VariationOfConstantsMethod", None] === "ExactDLogDecomposition",
      TrueQ[certificate["Exact"]] && certificate["Probabilistic"] === False &&
      Lookup[certificate, "Primes", None] === {} &&
      Lookup[certificate, "FreshValidationPrime", Missing[]] === None &&
      Lookup[certificate, "OffDiagonalTransformationBlockReconstructed", True] === False &&
      Lookup[certificate, "OffDiagonalTransformationBlockRepresentation", "Zero"] === "Zero",
    True, False];

(* This predicate checks the solution record's schema and internal
   consistency. It deliberately does not pretend that record structure proves
   the mathematics; use VerifyRationalEpsilonDependentBlockSolution for a
   fresh modular evaluation (or exact direct reconstruction) against the
   inputs. *)
RationalEpsilonDependentBlockSolutionQ[result_] := Module[
  {certificate, route, window, orders, rows, offDiagonalBlockAtPathEndpoint, offDiagonalBlockCoefficients,
   offDiagonalTransformationRepresentation, offDiagonalBlockDimensions,
   kResidues, words, demandPairs, regularization, wordRepresentation,
   sharedBoundaryQ, sourceDimension},
  If[! AssociationQ[result] ||
      Lookup[result, "Status", None] =!=
        "RationalEpsilonDependentBlockSolutionAccepted",
    Return[False]];
  certificate = Lookup[result, "Certificate", None];
  If[! rationalEpsilonDependentBlockCertificateShapeQ[certificate], Return[False]];
  window = Lookup[result, "Window", None];
  rows = Lookup[result, "Rows", None];
  demandPairs = Lookup[result, "RequestedOutputPairs", None];
  offDiagonalBlockAtPathEndpoint = Lookup[result, "OffDiagonalBasisTransformationBlockAtPathEndpoint", None];
  offDiagonalBlockCoefficients = Lookup[result, "OffDiagonalBasisTransformationBlockCoefficients", <||>];
  offDiagonalTransformationRepresentation = Lookup[certificate, "OffDiagonalTransformationBlockRepresentation",
    If[Lookup[certificate, "VariationOfConstantsMethod", None] === "ExactDLogDecomposition",
      "Zero", "PathEndpointValue"]];
  kResidues = Lookup[result, "KResidues", None];
  words = Lookup[result,
    "IteratedIntegralCoefficientTermsByRequestedOutput", None];
  regularization = Lookup[result, "RegularizationRequired", None];
  wordRepresentation = Lookup[result,
    "IteratedIntegralCoefficientRepresentation", None];
  sharedBoundaryQ = Lookup[result, "SharedBoundaryCoordinates", None];
  If[! MatchQ[window, {_Integer, _Integer}] || window[[1]] > window[[2]] ||
      ! ListQ[rows] || rows === {} ||
      ! MatchQ[demandPairs, {{_Integer, _Integer} ..}] || ! DuplicateFreeQ[demandPairs] ||
      ! AllTrue[demandPairs, 1 <= #[[2]] <= Length[rows] &] ||
      ! AssociationQ[offDiagonalBlockAtPathEndpoint] || ! AssociationQ[offDiagonalBlockCoefficients] ||
      ! AssociationQ[kResidues] ||
      ! MemberQ[{"ExplicitCoefficientTerms", "LazyCoefficientOperator"},
        wordRepresentation] ||
      ! BooleanQ[sharedBoundaryQ] ||
      ! IntegerQ[Lookup[result, "BoundaryColumns", None]] || result["BoundaryColumns"] < 1 ||
      Lookup[certificate, "IteratedIntegralCoefficientRepresentation", None] =!=
        wordRepresentation ||
      Lookup[certificate, "SharedBoundaryCoordinates", None] =!= sharedBoundaryQ,
    Return[False]];
  If[! BooleanQ[Lookup[result, "CurveChannel", None]] ||
      Lookup[certificate, "CurveChannel", None] =!= result["CurveChannel"] ||
      Lookup[certificate, "Curve", Missing[]] =!= Lookup[result, "Curve", Missing[]],
    Return[False]];
  If[If[wordRepresentation === "ExplicitCoefficientTerms",
      ! AssociationQ[words] || Sort[Keys[words]] =!= Sort[demandPairs] ||
        ! AllTrue[Values[words], ListQ],
      words =!= None], Return[False]];
  orders = Range[window[[1]], window[[2]]];
  If[Sort[Keys[offDiagonalBlockAtPathEndpoint]] =!= orders ||
      ! AllTrue[Values[offDiagonalBlockAtPathEndpoint], MatrixQ[#] && Dimensions[#][[1]] === Length[rows] &&
        Dimensions[#][[2]] >= 1 &], Return[False]];
  offDiagonalBlockDimensions = Dimensions[First[Values[offDiagonalBlockAtPathEndpoint]]];
  sourceDimension = offDiagonalBlockDimensions[[2]];
  If[sourceDimension < 1 ||
      offDiagonalBlockDimensions[[1]] =!= Length[rows] ||
      ! AllTrue[Values[offDiagonalBlockAtPathEndpoint], Dimensions[#] === offDiagonalBlockDimensions &] ||
      ! AllTrue[Values[kResidues], MatrixQ[#] && Dimensions[#] === offDiagonalBlockDimensions &],
    Return[False]];
  If[regularization =!= <|"BasePoint" -> {}, "PathEndpoint" -> {}|> ||
      Lookup[certificate, "RegularizationRequired", None] =!= regularization ||
      Lookup[certificate, "PathEndpoint", Missing[]] =!=
        Lookup[result, "PathEndpoint", Missing[]] ||
      Lookup[certificate, "Window", None] =!= window, Return[False]];
  route = certificate["VariationOfConstantsMethod"];
  Which[
    route === "ExactDLogDecomposition",
      Lookup[result, "OffDiagonalTransformationBlockStatus", None] === "OffDiagonalTransformationBlockVanishes" &&
      Lookup[result, "OffDiagonalTransformationBlockFiniteFieldImages", None] === <||> &&
      offDiagonalBlockCoefficients === <||> && offDiagonalTransformationRepresentation === "Zero" &&
      AllTrue[Values[offDiagonalBlockAtPathEndpoint], AllTrue[Flatten[#], # === 0 &] &],
    route === "FiniteFieldHermiteReductionAndReconstruction",
      AssociationQ[Lookup[result, "OffDiagonalTransformationBlockFiniteFieldImages", None]] &&
      Sort[Keys[result["OffDiagonalTransformationBlockFiniteFieldImages"]]] === Sort[certificate["Primes"]] &&
      AllTrue[Values[result["OffDiagonalTransformationBlockFiniteFieldImages"]], AssociationQ[#] && Sort[Keys[#]] === orders &] &&
      Lookup[certificate, "OffDiagonalTransformationBlockFiniteFieldImages", -1] === Length[orders] Length[certificate["Primes"]] &&
      Which[
        offDiagonalTransformationRepresentation === "PathEndpointValue",
          Lookup[result, "OffDiagonalTransformationBlockStatus", None] === "OffDiagonalTransformationBlockReconstructedAtPathEndpoint" &&
          MatchQ[Lookup[result, "PathEndpoint", None], _Integer | _Rational] &&
          offDiagonalBlockCoefficients === <||>,
        offDiagonalTransformationRepresentation === "RationalFunction",
          Lookup[result, "OffDiagonalTransformationBlockStatus", None] === "OffDiagonalTransformationBlockRationalFunctionReconstructed" &&
          MatchQ[Lookup[result, "PathEndpoint", None], _Symbol] &&
          result["PathEndpoint"] =!= None &&
          result["PathEndpoint"] =!= result["PathVariable"] &&
          Sort[Keys[offDiagonalBlockCoefficients]] === orders &&
          AllTrue[Values[offDiagonalBlockCoefficients], MatrixQ[#] && Dimensions[#] === offDiagonalBlockDimensions &] &&
          offDiagonalBlockAtPathEndpoint === Association@KeyValueMap[
            #1 -> Map[# /. result["PathVariable"] ->
              result["PathEndpoint"] &, #2, {2}] &,
            offDiagonalBlockCoefficients],
        True, False],
    True, False]
];

(* Re-derive the prepared problem from the supplied inputs,
   then re-verify the residues and off-diagonal transformation block: exactly
   under exact dlog decomposition, or at a fresh prime for finite-field
   Hermite reduction and reconstruction. *)
VerifyRationalEpsilonDependentBlockSolution[result_, source_Association,
    block_Association, demand_Association] := Module[
  {certificate, prepared, newPrime = None, image = None, candidate, trial,
   excludedPrimes, d, n, ok, wordsAgreeQ, offDiagonalBlockCheck},
  If[! RationalEpsilonDependentBlockSolutionQ[result], Return[False]];
  certificate = result["Certificate"];
  prepared = SolveRationalEpsilonDependentBlockByVariationOfConstants[
    source, block, demand, "PrepareOnly" -> True,
    "Seed" -> Lookup[certificate, "Seed", 20260902],
    "VariationOfConstantsMethod" -> If[Lookup[certificate, "VariationOfConstantsMethod", None] === "FiniteFieldHermiteReductionAndReconstruction", "FiniteFieldHermiteReductionAndReconstruction", Automatic],
    "OffDiagonalTransformationBlockRepresentation" -> If[
      Lookup[certificate, "VariationOfConstantsMethod", None] === "ExactDLogDecomposition",
      Automatic, Lookup[certificate, "OffDiagonalTransformationBlockRepresentation",
        If[MatchQ[Lookup[result, "PathEndpoint", None],
            _Integer | _Rational],
          "PathEndpointValue", "RationalFunction"]]],
    "IteratedIntegralCoefficientRepresentation" -> Lookup[result,
      "IteratedIntegralCoefficientRepresentation", Automatic]];
  If[Lookup[prepared, "Status", None] =!=
      "RationalEpsilonDependentBlockVariationOfConstantsProblemPrepared" ||
      prepared["Window"] =!= result["Window"], Return[False]];
  (* The result stores the mathematical solution, not a duplicate of the
     source and target inputs. Re-preparation above binds it to the supplied
     connection; the K and H comparisons below complete that check. *)
  If[prepared["PathEndpoint"] =!=
        Lookup[result, "PathEndpoint", None] ||
      prepared["Rows"] =!= Lookup[result, "Rows", None] ||
      prepared["BasePoint"] =!= Lookup[result, "BasePoint", None] ||
      prepared["RequestedOutputPairs"] =!=
        Lookup[result, "RequestedOutputPairs", None] ||
      (! prepared["ExactDLogDecompositionQ"] && prepared["OffDiagonalTransformationBlockRepresentation"] =!=
        Lookup[certificate, "OffDiagonalTransformationBlockRepresentation", "PathEndpointValue"]) ||
      prepared["IteratedIntegralCoefficientRepresentation"] =!=
        Lookup[result, "IteratedIntegralCoefficientRepresentation", None] ||
      prepared["SharedBoundaryCoordinates"] =!= Lookup[result, "SharedBoundaryCoordinates", None] ||
      prepared["CurveQ"] =!= Lookup[result, "CurveChannel", None] ||
      If[prepared["CurveQ"], prepared["Curve"] =!= Lookup[result, "Curve", None],
        Lookup[result, "Curve", Missing[]] =!= None], Return[False]];
  If[prepared["ExactDLogDecompositionQ"] =!= (certificate["VariationOfConstantsMethod"] === "ExactDLogDecomposition"), Return[False]];
  With[{sourceWidth = Dimensions[First[Values[source["BoundarySelectors"]]]][[2]],
        targetWidth = Last[rationalEpsilonDependentBlockTargetSelectors[block,
          prepared["Dimensions"][[1]], prepared["SharedBoundaryCoordinates"]]]},
    If[Lookup[result, "BoundaryColumns", None] =!=
        If[prepared["SharedBoundaryCoordinates"], sourceWidth,
          sourceWidth + targetWidth], Return[False]]];
  (* N1: every demanded word re-enumerated from the (re-verified) residues *)
  wordsAgreeQ[residues_] := Module[{targetSelectors, targetBoundaryCount, sourceBoundaryCount, orders = prepared["Orders"],
      demandPairs = prepared["RequestedOutputPairs"], neededWeight,
      weightByOrder, sourceStates,
      activeIncomingOrders, activeOffDiagonalOrders,
      sourceTransitionOrders},
    {targetSelectors, targetBoundaryCount} =
      rationalEpsilonDependentBlockTargetSelectors[block,
      prepared["Dimensions"][[1]], prepared["SharedBoundaryCoordinates"]];
    sourceBoundaryCount = Length[First[Values[source["BoundarySelectors"]]][[1]]];
    activeIncomingOrders = DeleteDuplicates[First /@ Keys[
      Select[residues, ! AllTrue[Flatten[#], # === 0 &] &]]];
    activeOffDiagonalOrders = Keys[Select[
      result["OffDiagonalBasisTransformationBlockAtPathEndpoint"],
      ! AllTrue[Flatten[#], # === 0 &] &]];
    sourceTransitionOrders = Union[activeIncomingOrders,
      activeOffDiagonalOrders];
    neededWeight = Max[Join[
      Select[Flatten[Table[pair[[1]] - q - r, {pair, demandPairs},
        {q, Keys[source["BoundarySelectors"]]},
        {r, sourceTransitionOrders}]], # >= 0 &],
      Select[Flatten[Table[pair[[1]] - q, {pair, demandPairs},
        {q, Keys[targetSelectors]}]], # >= 0 &], {0}]];
    weightByOrder = Association@Table[q -> With[{weights = Select[
          Flatten[Table[pair[[1]] - q - r, {pair, demandPairs},
            {r, sourceTransitionOrders}]], # >= 0 &]},
        If[weights === {}, -1, Max[weights]]], {q, Keys[source["BoundarySelectors"]]}];
    sourceStates = Catch[rationalEpsilonDependentBlockSourceStates[source, neededWeight, weightByOrder]];
    If[! AssociationQ[sourceStates] || KeyExistsQ[sourceStates, "Status"], Return[False, Module]];
    And @@ Table[rationalEpsilonDependentBlockIteratedIntegralCoefficientTerms[pair[[1]], pair[[2]], prepared["Diagonal"], residues, source, targetSelectors,
        sourceBoundaryCount, targetBoundaryCount, neededWeight, Infinity, sourceStates,
        prepared["SharedBoundaryCoordinates"],
        result["OffDiagonalBasisTransformationBlockAtPathEndpoint"]] ===
          result["IteratedIntegralCoefficientTermsByRequestedOutput"][pair],
      {pair, demandPairs}]];
  If[prepared["ExactDLogDecompositionQ"],
    Return[KeySort[prepared["ExactDLogResidues"]] === KeySort[result["KResidues"]] &&
      (result["IteratedIntegralCoefficientRepresentation"] ===
          "LazyCoefficientOperator" ||
        wordsAgreeQ[prepared["ExactDLogResidues"]])]];
  (* Modular: try bounded fresh primes outside the construction certificate.
     A prime where a denominator or pole factor degenerates is exceptional,
     not evidence against an otherwise valid record. *)
  excludedPrimes = Join[certificate["Primes"], {certificate["FreshValidationPrime"]}];
  BlockRandom[SeedRandom[Lookup[certificate, "Seed", 0] + 104729];
    Do[
      candidate = RandomPrime[{2^30, 2^31 - 1}];
      If[MemberQ[excludedPrimes, candidate], Continue[]];
      trial = If[prepared["CurveQ"],
        rationalEpsilonDependentBlockCurveRecurrenceImage[prepared["Laurent"], prepared["Diagonal"], prepared["Source"],
          prepared["Factors"], prepared["PathVariable"], prepared["Curve"],
          prepared["CurvePointValues"], prepared["BasePoint"], prepared["CurveBaseValue"],
          prepared["Orders"], candidate,
          If[prepared["OffDiagonalTransformationBlockRepresentation"] === "PathEndpointValue",
            prepared["PathEndpoint"], None], prepared["CurveValueAtPathEndpoint"]],
        rationalEpsilonDependentBlockRecurrenceImage[prepared["Laurent"], prepared["Diagonal"], prepared["Source"],
          prepared["Factors"], prepared["PathVariable"], prepared["BasePoint"], prepared["Orders"], candidate,
          If[prepared["OffDiagonalTransformationBlockRepresentation"] === "PathEndpointValue",
            prepared["PathEndpoint"], None]]];
      If[Lookup[trial, "Status", None] === "RecurrenceImageEvaluated",
        newPrime = candidate; image = trial; Break[]],
      {64}]];
  If[newPrime === None, Return[False]];
  {d, n} = prepared["Dimensions"];
  ok = And @@ Flatten[Table[
      With[{exact = Lookup[result["KResidues"], Key[key], ConstantArray[0, {d, n}]], img = Lookup[image["KResidues"], Key[key], ConstantArray[0, {d, n}]]},
        Table[Mod[Numerator[exact[[i, j]]] - img[[i, j]] Denominator[exact[[i, j]]], newPrime] === 0, {i, d}, {j, n}]],
      {key, Union[Keys[result["KResidues"]], Keys[image["KResidues"]]]}]];
  If[prepared["OffDiagonalTransformationBlockRepresentation"] === "PathEndpointValue",
    ok = ok && And @@ Flatten[Table[
        With[{exact =
              result["OffDiagonalBasisTransformationBlockAtPathEndpoint"][order],
            img = image[
              "OffDiagonalBasisTransformationBlockAtPathEndpointFiniteFieldValuesByEpsilonOrder"][order]},
          Table[Mod[Numerator[exact[[i, j]]] - img[[i, j]] Denominator[exact[[i, j]]], newPrime] === 0,
            {i, d}, {j, n}]], {order, prepared["Orders"]}]],
    offDiagonalBlockCheck = rationalEpsilonDependentBlockOffDiagonalTransformationFunctionCheck[result["OffDiagonalBasisTransformationBlockCoefficients"],
      image["HImages"], prepared["Orders"], prepared["PathVariable"],
      newPrime, Lookup[certificate, "Seed", 0] + 104729];
    ok = ok && Lookup[offDiagonalBlockCheck, "Status", None] === "OffDiagonalTransformationBlockChecked" &&
      Lookup[offDiagonalBlockCheck, "Mismatches", -1] === 0];
  ok && (result["IteratedIntegralCoefficientRepresentation"] ===
      "LazyCoefficientOperator" ||
    wordsAgreeQ[result["KResidues"]])
];
RationalEpsilonDependentBlockSolutionQ[___] := False;
VerifyRationalEpsilonDependentBlockSolution[___] := False;
